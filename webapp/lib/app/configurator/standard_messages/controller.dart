library controller;

import 'dart:html';
import 'package:katikati_ui_lib/components/logger.dart';
import 'package:nook/app/configurator/controller.dart';
export 'package:nook/app/configurator/controller.dart';
import 'package:katikati_ui_lib/components/model/model.dart' as model;
import 'package:nook/platform/platform.dart';

import 'view.dart';

part 'controller_view_helper.dart';
part 'controller_messages_helper.dart';


Logger log = new Logger('controller.dart');

enum MessagesConfigAction {
  addStandardMessage,
  updateStandardMessage,
  removeStandardMessage,
  addStandardMessagesGroup,
  updateStandardMessagesGroup,
  removeStandardMessagesGroup,
  addStandardMessagesCategory,
  updateStandardMessagesCategory,
  removeStandardMessagesCategory,
}

class StandardMessageData extends Data {
  String id;
  String text;
  String translation;
  String group;
  String category;
  StandardMessageData(this.id, {this.text, this.translation, this.group, this.category});

  @override
  String toString() {
    return "StandardMessageData($id, '$text', '$translation', $group, $category)";
  }
}

class StandardMessagesGroupData extends Data {
  String group;
  String newGroupName;
  String category;
  StandardMessagesGroupData(this.category, this.group, {this.newGroupName});

  @override
  String toString() {
    return "StandardMessagesGroupData($category, $group, '$newGroupName')";
  }
}

class StandardMessagesCategoryData extends Data {
  String category;
  String newCategoryName;
  StandardMessagesCategoryData(this.category, {this.newCategoryName});

  @override
  String toString() {
    return "StandardMessagesCategoryData($category, '$newCategoryName')";
  }
}

MessagesConfiguratorController _controller;
MessagesConfigurationPageView get _view => _controller.view;

class MessagesConfiguratorController extends ConfiguratorController {
  StandardMessagesManager standardMessagesManager = new StandardMessagesManager();

  MessagesConfiguratorController() : super() {
    _controller = this;
    view = new MessagesConfigurationPageView(this);
    platform = new Platform(this);
  }

  void command(action, [Data data]) {
    if (action is! MessagesConfigAction) {
      super.command(action, data);
      return;
    }
    log.verbose('command => $action : $data');
    log.verbose('Before -- ${standardMessagesManager.categories}');
    switch (action) {
      case MessagesConfigAction.addStandardMessage:
        StandardMessageData messageData = data;
        var message = standardMessagesManager.createMessage(messageData.category, messageData.group);

        _addMessagesToView({
          message.category: {
            message.groupDescription: [message]
          }
        });
        break;

      case MessagesConfigAction.updateStandardMessage:
        StandardMessageData messageData = data;
        var standardMessage = standardMessagesManager.modifyMessage(messageData.id, messageData.text, messageData.translation);
        _modifyMessagesInView({
          standardMessage.category: {
            standardMessage.groupDescription: [standardMessage]
          }
        });
        break;

      case MessagesConfigAction.removeStandardMessage:
        StandardMessageData messageData = data;
        var standardMessage = standardMessagesManager.deleteMessage(messageData.id);
        _removeMessagesFromView({
          standardMessage.category: {
            standardMessage.groupDescription: [standardMessage]
          }
        });
        break;

      case MessagesConfigAction.addStandardMessagesGroup:
        StandardMessagesGroupData groupData = data;
        var newGroup = standardMessagesManager.createStandardMessagesGroup(groupData.category);
        _addMessagesToView({groupData.category: {newGroup.groupDescription: []}}, startEditingName: true);
        break;

      case MessagesConfigAction.updateStandardMessagesGroup:
        StandardMessagesGroupData groupData = data;
        standardMessagesManager.renameStandardMessageGroup(groupData.category, groupData.group, groupData.newGroupName);
        _view.categoriesByName[groupData.category].renameGroup(groupData.group, groupData.newGroupName);
        break;

      case MessagesConfigAction.removeStandardMessagesGroup:
        StandardMessagesGroupData groupData = data;
        standardMessagesManager.deleteStandardMessagesGroup(groupData.category, groupData.group);
        _view.categoriesByName[groupData.category].removeGroup(groupData.group);
        break;

      case MessagesConfigAction.addStandardMessagesCategory:
        var newCategory = standardMessagesManager.createStandardMessagesCategory();
        _addMessagesToView({newCategory: {}}, startEditingName: true);
        break;

      case MessagesConfigAction.updateStandardMessagesCategory:
        StandardMessagesCategoryData categoryData = data;
        standardMessagesManager.renameStandardMessageCategory(categoryData.category, categoryData.newCategoryName);
        _view.renameCategory(categoryData.category, categoryData.newCategoryName);
        break;

      case MessagesConfigAction.removeStandardMessagesCategory:
        StandardMessagesCategoryData categoryData = data;
        standardMessagesManager.deleteStandardMessagesCategory(categoryData.category);
        _view.categories.removeItem(categoryData.category);
        break;
    }

    log.verbose('After -- ${standardMessagesManager.categories}');

    _view.unsavedChanges = standardMessagesManager.hasUnsavedMessages;
  }

  @override
  void setUpOnLogin() {
    platform.listenForSuggestedReplies((added, modified, removed) {
      var messagesAdded = standardMessagesManager.addStandardMessages(added);
      var messagesModified = standardMessagesManager.updateStandardMessages(modified);
      var messagesRemoved = standardMessagesManager.removeStandardMessages(removed);

      _addMessagesToView(_groupMessagesIntoCategoriesAndGroups(messagesAdded));
      _modifyMessagesInView(_groupMessagesIntoCategoriesAndGroups(messagesModified));
      _removeMessagesFromView(_groupMessagesIntoCategoriesAndGroups(messagesRemoved));
    });
  }

  @override
  void saveConfiguration() {
    _view.showSaveStatus('Saving...');
    bool otherPartSaved = false;

    platform.updateSuggestedReplies(standardMessagesManager.editedMessages.values.toList()).then((value) {
      standardMessagesManager.editedMessages.clear();
      if (otherPartSaved) {
        _view.showSaveStatus('Saved!');
        _view.unsavedChanges = false;
        return;
      }
      otherPartSaved = true;
    }, onError: (error, stacktrace) {
      _view.showSaveStatus('Unable to save. Please check your connection and try again. If the issue persists, please contact your project administrator');
    });

    platform.deleteSuggestedReplies(standardMessagesManager.deletedMessages.values.toList()).then((value) {
      standardMessagesManager.deletedMessages.clear();
      if (otherPartSaved) {
        _view.showSaveStatus('Saved!');
        _view.unsavedChanges = false;
        return;
      }
      otherPartSaved = true;
    }, onError: (error, stacktrace) {
      _view.showSaveStatus('Unable to save. Please check your connection and try again. If the issue persists, please contact your project administrator');
    });
  }
}
