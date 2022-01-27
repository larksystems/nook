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
  String categoryId;
  String groupId;
  String messageId;
  String text;
  String translation;
  StandardMessageData(this.messageId, {this.text, this.translation, this.groupId, this.categoryId});

  @override
  String toString() {
    return "StandardMessageData(messageId: $messageId, groupId: $groupId, categoryId: $categoryId, '$text', '$translation'";
  }
}

class StandardMessagesGroupData extends Data {
  String categoryId;
  String groupId;
  String newGroupName;
  StandardMessagesGroupData(this.categoryId, this.groupId, {this.newGroupName});

  @override
  String toString() {
    return "StandardMessagesGroupData(groupId: $groupId, categoryId: $categoryId, '$newGroupName')";
  }
}

class StandardMessagesCategoryData extends Data {
  String categoryId;
  String newCategoryName;
  StandardMessagesCategoryData(this.categoryId, {this.newCategoryName});

  @override
  String toString() {
    return "StandardMessagesCategoryData($categoryId, '$newCategoryName')";
  }
}

MessagesConfiguratorController _controller;
MessagesConfigurationPageView get _view => _controller.view;

class MessagesConfiguratorController extends ConfiguratorController {
  StandardMessagesManager standardMessagesManager = new StandardMessagesManager();

  MessagesConfiguratorController() : super() {
    _controller = this;
  }

  @override
  void init() {
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
        var categoryId = messageData.categoryId;
        var groupId = messageData.groupId;

        var category = standardMessagesManager.categories[categoryId];
        var group = standardMessagesManager.categories[categoryId].groups[groupId];
        var standardMessage = standardMessagesManager.createMessage(category.categoryId, category.categoryName, category.categoryIndex, group.groupId, group.groupName, group.groupIndexInCategory);

        var messageCategoryMap = {
          category.categoryId: MessageCategory(category.categoryId, category.categoryName, category.categoryIndex)
            ..groups = {
              group.groupId: MessageGroup(group.groupId, group.groupName, group.groupIndexInCategory)
                ..messages = {
                  standardMessage.docId: standardMessage
                }
            }
        };
        _addMessagesToView(messageCategoryMap);
        _updateUnsavedIndicators(standardMessagesManager.categories, standardMessagesManager.unsavedMessageIds, standardMessagesManager.unsavedGroupIds, standardMessagesManager.unsavedCategoryIds);
        break;

      case MessagesConfigAction.updateStandardMessage:
        StandardMessageData messageData = data;
        var standardMessage = standardMessagesManager.modifyMessage(messageData.messageId, messageData.text, messageData.translation);
        _modifyMessagesInView([standardMessage]);
        _updateUnsavedIndicators(standardMessagesManager.categories, standardMessagesManager.unsavedMessageIds, standardMessagesManager.unsavedGroupIds, standardMessagesManager.unsavedCategoryIds);
        break;

      case MessagesConfigAction.removeStandardMessage:
        StandardMessageData messageData = data;
        var standardMessage = standardMessagesManager.deleteMessage(messageData.messageId);
        _removeMessagesFromView([standardMessage]);
        _updateUnsavedIndicators(standardMessagesManager.categories, standardMessagesManager.unsavedMessageIds, standardMessagesManager.unsavedGroupIds, standardMessagesManager.unsavedCategoryIds);
        break;

      case MessagesConfigAction.addStandardMessagesGroup:
        StandardMessagesGroupData groupData = data;
        var category = standardMessagesManager.categories[groupData.categoryId];
        var newGroup = standardMessagesManager.createStandardMessagesGroup(category.categoryId, category.categoryName);
        var messageCategoryMap = {
          category.categoryId: MessageCategory(category.categoryId, category.categoryName, category.categoryIndex)
            ..groups = {
              newGroup.groupId: MessageGroup(newGroup.groupId, newGroup.groupName, newGroup.groupIndexInCategory)
            }
        };
        _addMessagesToView(messageCategoryMap, startEditingName: true);
        _updateUnsavedIndicators(standardMessagesManager.categories, standardMessagesManager.unsavedMessageIds, standardMessagesManager.unsavedGroupIds, standardMessagesManager.unsavedCategoryIds);
        break;

      case MessagesConfigAction.updateStandardMessagesGroup:
        StandardMessagesGroupData groupData = data;
        standardMessagesManager.renameStandardMessageGroup(groupData.categoryId, groupData.groupId, groupData.newGroupName);
        _view.categoriesById[groupData.categoryId].renameGroup(groupData.groupId, groupData.newGroupName);
        _updateUnsavedIndicators(standardMessagesManager.categories, standardMessagesManager.unsavedMessageIds, standardMessagesManager.unsavedGroupIds, standardMessagesManager.unsavedCategoryIds);
        break;

      case MessagesConfigAction.removeStandardMessagesGroup:
        StandardMessagesGroupData groupData = data;
        standardMessagesManager.deleteStandardMessagesGroup(groupData.categoryId, groupData.groupId);
        _view.categoriesById[groupData.categoryId].removeGroup(groupData.groupId);
        _updateUnsavedIndicators(standardMessagesManager.categories, standardMessagesManager.unsavedMessageIds, standardMessagesManager.unsavedGroupIds, standardMessagesManager.unsavedCategoryIds);
        break;

      case MessagesConfigAction.addStandardMessagesCategory:
        var newCategory = standardMessagesManager.createStandardMessagesCategory();
        var messageCategoryMap = {
          newCategory.categoryId: MessageCategory(newCategory.categoryId, newCategory.categoryName, newCategory.categoryIndex)
        };
        _addMessagesToView(messageCategoryMap, startEditingName: true);
        _updateUnsavedIndicators(standardMessagesManager.categories, standardMessagesManager.unsavedMessageIds, standardMessagesManager.unsavedGroupIds, standardMessagesManager.unsavedCategoryIds);
        break;

      case MessagesConfigAction.updateStandardMessagesCategory:
        StandardMessagesCategoryData categoryData = data;
        standardMessagesManager.renameStandardMessageCategory(categoryData.categoryId, categoryData.newCategoryName);
        _view.renameCategory(categoryData.categoryId, categoryData.newCategoryName);
        _updateUnsavedIndicators(standardMessagesManager.categories, standardMessagesManager.unsavedMessageIds, standardMessagesManager.unsavedGroupIds, standardMessagesManager.unsavedCategoryIds);
        break;

      case MessagesConfigAction.removeStandardMessagesCategory:
        StandardMessagesCategoryData categoryData = data;
        standardMessagesManager.deleteStandardMessagesCategory(categoryData.categoryId);
        _view.categories.removeItem(categoryData.categoryId);
        _updateUnsavedIndicators(standardMessagesManager.categories, standardMessagesManager.unsavedMessageIds, standardMessagesManager.unsavedGroupIds, standardMessagesManager.unsavedCategoryIds);
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
      _modifyMessagesInView(messagesModified);
      _removeMessagesFromView(messagesRemoved);
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
        _view.clearUnsavedIndicators();
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
        _view.clearUnsavedIndicators();
        return;
      }
      otherPartSaved = true;
    }, onError: (error, stacktrace) {
      _view.showSaveStatus('Unable to save. Please check your connection and try again. If the issue persists, please contact your project administrator');
    });
  }
}
