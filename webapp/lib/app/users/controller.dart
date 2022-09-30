library controller;

import 'dart:html';
import 'package:katikati_ui_lib/components/logger.dart';
import 'package:nook/app/nook/controller.dart';
import 'package:nook/platform/platform.dart';
import 'package:katikati_ui_lib/components/model/model.dart' as model;
import 'view.dart';
import 'dart:async';

Logger log = new Logger('controller.dart');

enum UsersAction {
  updateBoolPermission,
  updateStringPermission,
  updateStringSetPermission,
  savePermissions,
  resetToDefaultPermission
}

class UpdateBoolPermission extends Data {
  String email;
  String permissionKey;
  bool value;

  UpdateBoolPermission(this.email, this.permissionKey, this.value);
}

class UpdateStringPermission extends Data {
  String email;
  String permissionKey;
  String value;

  UpdateStringPermission(this.email, this.permissionKey, this.value);
}

class ResetToDefaultPermission extends Data {
  String email;
  String permissionKey;

  ResetToDefaultPermission(this.email, this.permissionKey);
}

UsersController controller;
UsersPageView get _view => controller.view;

class UsersController extends Controller {

  model.UserConfiguration defaultConfig;
  Map<String, model.UserConfiguration> userConfigs;
  Map<String, Map<String, dynamic>> editedConfig;

  UsersController(): super() {}

  @override
  void init() {
    view = UsersPageView(this);
    platform = new Platform(this);
    controller = this;
    editedConfig = {};
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

            if (editedConfig.containsKey(c.docId)) {
              if (editedConfig[c.docId].containsKey(permissionKey)) {
                editedConfig[c.docId].remove(permissionKey);
              }
              if (editedConfig[c.docId].isEmpty) {
                editedConfig.remove(c.docId);
              }
            }
            
            var valueToUpdate = modifiedObj[permissionKey];
            var valueType = valueToUpdate.runtimeType.toString();
            if (valueType == 'bool') {
              _view.updateBoolPermission(c.docId, permissionKey, valueToUpdate);
            } else if (valueType == 'String') {
              _view.updateStringPermission(c.docId, permissionKey, valueToUpdate);
            } else if (valueType == 'List<String>') {
              _view.updateListStringPermission(c.docId, permissionKey, valueToUpdate);
            } else {
              log.error("Unknown data type for ${c.docId}, ${permissionKey}, ${valueToUpdate}");
            }
          });
        });
      }

      // todo: handle removal of user
      _view.enableSaveButton(editedConfig.isNotEmpty);
    });
  }

  void command(action, [Data data]) {
    if (action is! UsersAction) {
      super.command(action, data);
      return;
    }

    switch (action) {
      case UsersAction.savePermissions:
        _view.setSaveText("Updating…");
        _view.enableSaveButton(false);
        platform.updateUserConfiguration(editedConfig).then((_) {
          editedConfig.keys.forEach((email) {
            _view.markAsUnsaved(email, true);
          });
          editedConfig = {};
          _view.setSaveText("Updated!");
          new Timer(new Duration(seconds: 2), () => _view.setSaveText("Update permissions"));
        });
        break;

      case UsersAction.updateBoolPermission:
        var updateData = data as UpdateBoolPermission;
        if (isDefaultPermission(updateData.email)) {
          var userDataObj = defaultConfig.toData();
          userDataObj[updateData.permissionKey] = updateData.value;
          defaultConfig = model.UserConfiguration.fromData(userDataObj);
          for (var email in userConfigs.keys) {
            if (email != 'default') {
              var valueToUpdate = userConfigs[email].toData()[updateData.permissionKey] ?? updateData.value;
              _view.updateBoolPermission(email, updateData.permissionKey, valueToUpdate);
            }
          }
        } else {
          var userDataObj = userConfigs[updateData.email].toData();
          userDataObj[updateData.permissionKey] = updateData.value;
          userConfigs[updateData.email] = model.UserConfiguration.fromData(userDataObj);
        }
        editedConfig[updateData.email] = editedConfig[updateData.email] ?? {};
        editedConfig[updateData.email][updateData.permissionKey] = updateData.value;
        _view.markAsUnsaved(updateData.email, false);
        _view.enableSaveButton(editedConfig.isNotEmpty);
        break;

      case UsersAction.updateStringPermission:
        var updateData = data as UpdateStringPermission;
        if (isDefaultPermission(updateData.email)) {
          var userDataObj = defaultConfig.toData();
          userDataObj[updateData.permissionKey] = updateData.value;
          defaultConfig = model.UserConfiguration.fromData(userDataObj);
          for (var email in userConfigs.keys) {
            if (email != 'default') {
              var valueToUpdate = userConfigs[email].toData()[updateData.permissionKey] ?? updateData.value;
              _view.updateStringPermission(email, updateData.permissionKey, valueToUpdate);
            }
          }
        } else {
          var userDataObj = userConfigs[updateData.email].toData();
          userDataObj[updateData.permissionKey] = updateData.value;
          userConfigs[updateData.email] = model.UserConfiguration.fromData(userDataObj);
        }
        editedConfig[updateData.email] = editedConfig[updateData.email] ?? {};
        editedConfig[updateData.email][updateData.permissionKey] = updateData.value;
        _view.markAsUnsaved(updateData.email, false);
        _view.enableSaveButton(editedConfig.isNotEmpty);
        break;

      case UsersAction.updateStringSetPermission:
        var updateData = data as UpdateStringPermission;
        var values = updateData.value.split(",").map((e) => e.trim()).toList();
        if (isDefaultPermission(updateData.email)) {
          var userDataObj = defaultConfig.toData();
          userDataObj[updateData.permissionKey] = values;
          defaultConfig = model.UserConfiguration.fromData(userDataObj);
          for (var email in userConfigs.keys) {
            if (email != 'default') {
              var valueToUpdate = userConfigs[email].toData()[updateData.permissionKey] ?? updateData.value.split(",");
              _view.updateListStringPermission(email, updateData.permissionKey, valueToUpdate);
            }
          }
        } else {
          var userDataObj = userConfigs[updateData.email].toData();
          userDataObj[updateData.permissionKey] = values;
          userConfigs[updateData.email] = model.UserConfiguration.fromData(userDataObj);
        }
        editedConfig[updateData.email] = editedConfig[updateData.email] ?? {};
        editedConfig[updateData.email][updateData.permissionKey] = values;
        _view.markAsUnsaved(updateData.email, false);
        _view.enableSaveButton(editedConfig.isNotEmpty);
        break;
      
      case UsersAction.resetToDefaultPermission:
        var resetData = data as ResetToDefaultPermission;
        var userDataObj = userConfigs[resetData.email].toData();

        var valueType = userDataObj[resetData.permissionKey].runtimeType.toString();

        userDataObj[resetData.permissionKey] = null;
        userConfigs[resetData.email] = model.UserConfiguration.fromData(userDataObj);
        editedConfig[resetData.email] = editedConfig[resetData.email] ?? {};
        editedConfig[resetData.email][resetData.permissionKey] = null;

        _view.markAsUnsaved(resetData.email, false);
        _view.enableSaveButton(editedConfig.isNotEmpty);

        if (valueType == 'bool') {
          _view.updateBoolPermission(resetData.email, resetData.permissionKey, defaultConfig.toData()[resetData.permissionKey], setToDefault: true);
        } else if (valueType == 'String') {
          _view.updateStringPermission(resetData.email, resetData.permissionKey, defaultConfig.toData()[resetData.permissionKey] ?? "", setToDefault: true);
        } else if (valueType == 'List<String>') {
          _view.updateListStringPermission(resetData.email, resetData.permissionKey, defaultConfig.toData()[resetData.permissionKey] ?? [], setToDefault: true);
        }
        break;
    }
  }
}
