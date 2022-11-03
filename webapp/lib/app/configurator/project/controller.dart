library controller;

import 'package:katikati_ui_lib/components/logger.dart';
import 'package:nook/app/nook/controller.dart';
import 'package:katikati_ui_lib/components/model/model.dart' as model;
import 'view.dart';

Logger log = new Logger('controller.dart');

enum UsersAction {
  addUser,
  deactivateUser,
  updateProjectInfo,
  updatePermission,
  resetToDefaultPermission,
}

class UserData extends Data {
  String userId;

  UserData(this.userId);
}

class ProjectInfo extends Data {
  model.Project project;

  ProjectInfo(this.project);
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
      if (currentConfig.role != model.UserRole.superAdmin && currentConfig.role != model.UserRole.projectAdmin) {
        _view.displayAccessNotAllowed();
        return;
      }

      _view.setupAccessAllowed();

      if (added.isNotEmpty || removed.isNotEmpty) {
        _view.populateTable(defaultConfig, currentConfig, userConfigs);
      }

      if (modified.isNotEmpty) {
        userConfigs = userConfigs ?? {};
        for (var modifiedUserConfig in modified) {
          if (modifiedUserConfig.docId == 'default') {
            var modifiedData = modifiedUserConfig.toData();
            var previousData = defaultConfig.toData();
            for (var key in _view.permissionNameHeaders.keys) {
              if (previousData[key] != modifiedData[key]) {
                _view.updatePermission(modifiedUserConfig.docId, key, modifiedData[key]);
                for (var email in userConfigs.keys) {
                  _view.updatePermission(email, key, userConfigs[email].toData()[key]);
                }
              }
            }
            defaultConfig = modifiedUserConfig;
          }
          else userConfigs[modifiedUserConfig.docId] = modifiedUserConfig;

        }
        var currentConfig = userConfigs[signedInUser.userEmail] ?? model.UserConfigurationUtil.emptyUserConfiguration;
        _view.populateTable(defaultConfig, currentConfig, userConfigs);
      }
    });
  }

  void command(action, [Data data]) {
    switch (action) {
      case UsersAction.addUser:
        var userData = data as UserData;
        platform.addUser(userData.userId);
        break;

      case UsersAction.updateProjectInfo:
        var updateData = data as ProjectInfo;
        platform.setProjectInfo(updateData.project);
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

    switch (action) {
      case BaseAction.projectListUpdated:
        selectedProject = projects.singleWhere((project) => project.projectId == urlManager.project, orElse: () => null);
        _view.setupAccessAllowed();
        _view.updateProjectInfo(selectedProject);
        return;
    }

    super.command(action, data);
  }

  @override
  void applyConfiguration(model.UserConfiguration newConfig) {
    // TODO: implement applyConfiguration
    super.applyConfiguration(newConfig);
  }
}
