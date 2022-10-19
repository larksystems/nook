library controller;

import 'package:katikati_ui_lib/components/logger.dart';
import 'package:nook/app/nook/controller.dart';
import 'package:katikati_ui_lib/components/model/model.dart' as model;
import 'view.dart';

Logger log = new Logger('controller.dart');

enum UsersAction {
  addUser,
  deactivateUser,
  updatePermission,
  resetToDefaultPermission,
}

class UserData extends Data {
  String userId;

  UserData(this.userId);
}

class UpdatePermission extends Data {
  String userId;
  String permissionKey;
  dynamic value;

  UpdatePermission(this.userId, this.permissionKey, this.value);
}

class ResetToDefaultPermission extends Data {
  String userId;
  String permissionKey;

  ResetToDefaultPermission(this.userId, this.permissionKey);
}

UsersController controller;
UsersPageView get _view => controller.view;

class UsersController extends Controller {
  model.UserConfiguration defaultConfig;
  Map<String, model.UserConfiguration> userConfigs;

  UsersController(): super();

  @override
  void init() {
    if (urlManager.project == null) routeToPage(Page.homepage);

    view = UsersPageView(this);
    controller = this;
    super.init();
  }

  @override
  void setUpOnLogin() {
    super.setUpOnLogin();

    platform.listenForUserConfigurations((added, modified, removed) {
      if (added.isNotEmpty || removed.isNotEmpty) {
        defaultConfig = added.singleWhere((c) => c.docId == 'default', orElse: () => defaultConfig);

        userConfigs = userConfigs ?? {};
        for (var config in added) {
          if (config.docId == 'default') continue;
          userConfigs[config.docId] = config;
        }
        for (var config in removed) {
          userConfigs.remove(config.docId);
        }

        var currentConfig = userConfigs[signedInUser.userEmail] ?? model.UserConfigurationUtil.emptyUserConfiguration;

        if (currentConfig.role == model.UserRole.superAdmin || currentConfig.role == model.UserRole.projectAdmin) {
          _view.populateTable(defaultConfig, currentConfig, userConfigs);
        } else {
          _view.displayAccessNotAllowed();
        }
      }

      if (modified.isNotEmpty) {
        List<model.UserConfiguration> modifiedUserConfig = new List()
          ..addAll(modified);

        var newDefaultConfig = modifiedUserConfig.singleWhere((c) => c.docId == 'default', orElse: () => null);
        if (newDefaultConfig != null) {
          defaultConfig = newDefaultConfig;
        }

        userConfigs = userConfigs ?? {};
        modifiedUserConfig.where((c) => c.docId != 'default').forEach((c) {
          userConfigs[c.docId] = c.applyDefaults(defaultConfig);
          var userConfigMap = userConfigs[c.docId].toData();
          var defaultConfigMap = defaultConfig.toData();
          for (var key in userConfigMap.keys) {
            _view.updatePermission(c.docId, key, userConfigMap[key], setToDefault: defaultConfigMap[key] == userConfigMap[key]);
          }
        });
      }
    });
  }

  void command(action, [Data data]) {
    if (action is! UsersAction) {
      super.command(action, data);
      return;
    }

    switch (action) {
      case UsersAction.addUser:
        var userData = data as UserData;
        platform.addUser(userData.userId);
        break;
      case UsersAction.updatePermission:
        var updateData = data as UpdatePermission;
        platform.setUserConfigField(updateData.userId, updateData.permissionKey, updateData.value);
        _view.toggleSaved(updateData.userId, updateData.permissionKey, false);
        break;

      case UsersAction.resetToDefaultPermission:
        var resetData = data as ResetToDefaultPermission;
        platform.setUserConfigField(resetData.userId, resetData.permissionKey, defaultConfig.toData()[resetData.permissionKey]);
        _view.toggleSaved(resetData.userId, resetData.permissionKey, false);
        break;
    }
  }

  @override
  void applyConfiguration(model.UserConfiguration newConfig) {
    // TODO: implement applyConfiguration
    super.applyConfiguration(newConfig);
  }
}
