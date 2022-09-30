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
    super.init();
    view = UsersPageView(this);
    controller = this;
  }

  @override
  void setUpOnLogin() {
    _listenForUserConfig();
  }

  void _listenForUserConfig() {
    platform.listenForUserConfigurations((added, modified, removed) {
      if (added.isNotEmpty) {
        List<model.UserConfiguration> addedUserConfig = new List()
          ..addAll(added);

        defaultConfig = addedUserConfig.singleWhere((c) => c.docId == 'default', orElse: () => null);

        userConfigs = userConfigs ?? {};
        addedUserConfig.where((c) => c.docId != 'default').forEach((c) {
          userConfigs[c.docId] = c;
        });

        _view.populateTable(defaultConfig, userConfigs);
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
          var modifiedObj = c.toData();
          modifiedObj.keys.forEach((permissionKey) {
            var valueToUpdate = modifiedObj[permissionKey];
            _view.updatePermission(c.docId, permissionKey, valueToUpdate);
          });
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
      case UsersAction.updatePermission:
        var updateData = data as UpdatePermission;
        platform.setUserConfigField(updateData.userId, updateData.permissionKey, updateData.value);
        _view.toggleSaved(updateData.userId, updateData.permissionKey, true);
        break;

      case UsersAction.resetToDefaultPermission:
        var resetData = data as ResetToDefaultPermission;
        platform.setUserConfigField(resetData.userId, resetData.permissionKey, defaultConfig.toData()[resetData.permissionKey]);
        _view.toggleSaved(resetData.userId, resetData.permissionKey, true);
        break;
    }
  }

  @override
  void applyConfiguration(model.UserConfiguration newConfig) {
    // TODO: implement applyConfiguration
    super.applyConfiguration(newConfig);
  }
}
