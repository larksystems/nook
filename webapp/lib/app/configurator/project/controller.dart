library controller;

import 'package:katikati_ui_lib/components/logger.dart';
import 'package:nook/app/nook/controller.dart';
import 'package:katikati_ui_lib/components/model/model.dart' as model;
import 'view.dart';

Logger log = new Logger('controller.dart');

const DEFAULT_KEY = "default";

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

    userConfigs = userConfigs ?? {};
    currentConfig = userConfigs[signedInUser.userEmail] ?? model.UserConfigurationUtil.emptyUserConfiguration;

    platform.listenForUserConfigurations((added, modified, removed) {
      defaultConfig = added.singleWhere((c) => c.docId == DEFAULT_KEY, orElse: () => defaultConfig);

      for (var config in added) {
        if (config.docId == DEFAULT_KEY) continue;
        userConfigs[config.docId] = config;
      }
      for (var config in removed) {
        userConfigs.remove(config.docId);
      }

      currentConfig = userConfigs[signedInUser.userEmail] ?? model.UserConfigurationUtil.emptyUserConfiguration;
      if (currentConfig.role != model.UserRole.superAdmin && currentConfig.role != model.UserRole.projectAdmin) {
        _view.displayAccessNotAllowed();
        return;
      }

      _view.setupAccessAllowed();

      if (added.isNotEmpty || removed.isNotEmpty) {
        _view.populatePermissionsTable(defaultConfig, currentConfig, userConfigs);
      }

      if (modified.isNotEmpty) {
        userConfigs = userConfigs ?? {};
        for (var modifiedUserConfig in modified) {
          var previousConfig = modifiedUserConfig.docId == DEFAULT_KEY ? defaultConfig : userConfigs[modifiedUserConfig.docId];
          var modifiedData = modifiedUserConfig.toData();
          var previousData = previousConfig.toData();

          for (var key in _view.permissionNameHeaders.keys) {
            if (previousData[key] != modifiedData[key]) {
              _view.updatePermission(defaultConfig, modifiedUserConfig, userConfigs, key);
              if (modifiedUserConfig.docId == DEFAULT_KEY) {
                for (var email in userConfigs.keys) {
                  _view.updatePermission(defaultConfig, userConfigs[email], userConfigs, key);
                }
              }
            }
          }

          if (modifiedUserConfig.docId == DEFAULT_KEY) defaultConfig = modifiedUserConfig;
          else userConfigs[modifiedUserConfig.docId] = modifiedUserConfig;

        }
        currentConfig = userConfigs[signedInUser.userEmail] ?? model.UserConfigurationUtil.emptyUserConfiguration;
        _view.populatePermissionsTable(defaultConfig, currentConfig, userConfigs);
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
        var userConfig = updateData.userId == DEFAULT_KEY ? defaultConfig : userConfigs[updateData.userId];
        var previousValue = userConfig.toData()[updateData.permissionKey];
        var updatedData = updateData.value;
        if (previousValue == updatedData) break;
        if (previousValue is List || updatedData is List) {
          if ((previousValue ?? []).toSet().intersection((updatedData ?? []).toSet()).length == previousValue?.length) break;
        }
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

  bool hasHigherAdminRoleThanId(String id) =>
    currentConfig.role == model.UserRole.superAdmin ?
      true :
      (currentConfig.role == model.UserRole.projectAdmin && userConfigs[id]?.role == model.UserRole.superAdmin) ? false : true;

  bool isDerivedFromDefault(String id, String key) => id != DEFAULT_KEY && userConfigs[id].toData()[key] == null;
  bool isResettableToDefault(String id, String key) => id != DEFAULT_KEY && !isDerivedFromDefault(id, key) && key != "role" && key != "status";
  bool isEditable(String id, String key) => !((!hasHigherAdminRoleThanId(id) || id == DEFAULT_KEY) && (key == "role" || key == "status"));

  dynamic getValue(String id, String key) {
    var configMap = (id == DEFAULT_KEY || isDerivedFromDefault(id, key)) ? defaultConfig.toData() : userConfigs[id].toData();
    return configMap[key];
  }

  @override
  void applyConfiguration(model.UserConfiguration newConfig) {
    // TODO: implement applyConfiguration
    super.applyConfiguration(newConfig);
  }
}
