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

          if (modifiedUserConfig.docId == DEFAULT_KEY) defaultConfig = modifiedUserConfig;
          else userConfigs[modifiedUserConfig.docId] = modifiedUserConfig;

          for (var key in _view.permissionNameHeaders.keys) {
            if (previousData[key] != modifiedData[key]) {
              _view.updatePermission(defaultConfig, modifiedUserConfig, userConfigs, key);
              if (modifiedUserConfig.docId == DEFAULT_KEY) {
                for (var email in userConfigs.keys) {
                  _view.updatePermission(defaultConfig, userConfigs[email], userConfigs, key);
                }
              }
              if (key == 'status') {
                for (var k in _view.permissionNameHeaders.keys) {
                  _view.updatePermission(defaultConfig, modifiedUserConfig, userConfigs, k);
                }
              }
            }
          }

        }
        currentConfig = userConfigs[signedInUser.userEmail] ?? model.UserConfigurationUtil.emptyUserConfiguration;
        // _view.populatePermissionsTable(defaultConfig, currentConfig, userConfigs);
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
        var previousValue = getValue(updateData.userId, updateData.permissionKey);
        var updatedValue = updateData.value;
        if (previousValue == updatedValue) break;
        if (previousValue is List || updatedValue is List) {
          if (iterableContentsEqual(previousValue ?? [], updatedValue ?? [])) break;
        }
        platform.setUserConfigField(updateData.userId, updateData.permissionKey, updateData.value);
        _view.toggleSaved(updateData.userId, updateData.permissionKey, false);
        var renderElement = _view.permissionToggles[updateData.userId][updateData.permissionKey] ?? _view.permissionTextboxes[updateData.userId][updateData.permissionKey];
        renderElement.classes.toggle(VALUE_FROM_DEFAULT_CSS_CLASS, false);
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

  bool iterableContentsEqual(Iterable a, Iterable b) {
    return
      a.toSet().intersection(b.toSet()).length == a.length &&
      b.toSet().intersection(a.toSet()).length == b.length;
  }

  bool hasHigherAdminRoleThanId(String id) =>
    currentConfig.role == model.UserRole.superAdmin ?
      true :
      (currentConfig.role == model.UserRole.projectAdmin && userConfigs[id]?.role == model.UserRole.superAdmin) ? false : true;

  bool isDerivedFromDefault(String id, String key) => id != DEFAULT_KEY && userConfigs[id].toData()[key] == null;
  bool isResettableToDefault(String id, String key) => id != DEFAULT_KEY && !isDerivedFromDefault(id, key) && key != "role" && key != "status";
  bool isEditable(String id, String key) {
    if (id == DEFAULT_KEY) {
      if (key == "role" || key == "status") return false;
      return true;
    }
    if (userConfigs[id].status == model.UserStatus.deactivated) {
      if (key != "status") return false;
      if (hasHigherAdminRoleThanId(id)) return true;
      return false;
    }
    if (userConfigs[id].status == model.UserStatus.deactivated && key != "status") return false;
    if (!hasHigherAdminRoleThanId(id) && key == "status") return false;
    return true;
  }

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
