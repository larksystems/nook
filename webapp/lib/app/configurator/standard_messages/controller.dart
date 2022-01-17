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
  String messageId;
  String text;
  String translation;
  String groupId;
  String group;
  String categoryId;
  String category;
  StandardMessageData(this.messageId, {this.text, this.translation, this.groupId, this.group, this.categoryId, this.category});

  @override
  String toString() {
    return "StandardMessageData($messageId, '$text', '$translation', $groupId, $group, $categoryId, $category)";
  }
}

class StandardMessagesGroupData extends Data {
  String groupId;
  String groupName;
  String newGroupName;
  String categoryId;
  String categoryName;
  StandardMessagesGroupData(this.categoryId, this.categoryName, this.groupId, this.groupName, {this.newGroupName});

  @override
  String toString() {
    return "StandardMessagesGroupData($categoryId, $categoryName, $groupId, $groupName, '$newGroupName')";
  }
}

class StandardMessagesCategoryData extends Data {
  String categoryId;
  String categoryName;
  String newCategoryName;
  StandardMessagesCategoryData(this.categoryId, category, {this.newCategoryName});

  @override
  String toString() {
    return "StandardMessagesCategoryData($categoryId, $categoryName, '$newCategoryName')";
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
        var categoryName = standardMessagesManager.categories[messageData.categoryId].categoryName;
        var groupName = standardMessagesManager.categories[messageData.categoryId].groups[messageData.groupId].groupName;

        var message = standardMessagesManager.createMessage(messageData.categoryId, categoryName, messageData.groupId, groupName);
        // todo: unwanted map since we use only the category Id, group Id
        var messageCategoryMap = {
          message.categoryId: MessageCategory(messageData.categoryId, categoryName)
            ..groups = {
              message.groupId: MessageGroup(messageData.groupId, groupName)
                ..messages = {
                  message.docId: message
                }
            }
        };
        _addMessagesToView(messageCategoryMap);
        _updateUnsavedIndicators(standardMessagesManager.categories, standardMessagesManager.unsavedMessageIds, standardMessagesManager.unsavedGroupIds, standardMessagesManager.unsavedCategoryIds);
        break;

      case MessagesConfigAction.updateStandardMessage:
        StandardMessageData messageData = data;
        var standardMessage = standardMessagesManager.modifyMessage(messageData.messageId, messageData.text, messageData.translation);
        String categoryName;
        String groupName;
        for(var category in standardMessagesManager.categories.values) {
          for(var group in category.groups.values) {
            var messageIds = group.messages.keys;
            if (messageIds.contains(messageData.messageId)) {
              categoryName = category.categoryName;
              groupName = group.groupName;
              break;
            }
          }
        }

        // todo: unwanted map since we use only the category Id, group Id
        var messageCategoryMap = {
          standardMessage.categoryId: MessageCategory(standardMessage.categoryId, categoryName)
            ..groups = {
              standardMessage.groupId: MessageGroup(messageData.groupId, groupName)
                ..messages = {
                  standardMessage.docId: standardMessage
                }
            }
        };
        _modifyMessagesInView(messageCategoryMap);
        _updateUnsavedIndicators(standardMessagesManager.categories, standardMessagesManager.unsavedMessageIds, standardMessagesManager.unsavedGroupIds, standardMessagesManager.unsavedCategoryIds);
        break;

      case MessagesConfigAction.removeStandardMessage:
        StandardMessageData messageData = data;
        var standardMessage = standardMessagesManager.deleteMessage(messageData.messageId);
        var messageCategoryMap = {
          standardMessage.categoryId: MessageCategory(standardMessage.categoryId, standardMessage.category)
            ..groups = {
              standardMessage.groupId: MessageGroup(messageData.groupId, messageData.group)
                ..messages = {
                  standardMessage.docId: standardMessage
                }
            }
        };
        // todo: unwanted map since we use only the category Id, group Id
        _removeMessagesFromView(messageCategoryMap);
        _updateUnsavedIndicators(standardMessagesManager.categories, standardMessagesManager.unsavedMessageIds, standardMessagesManager.unsavedGroupIds, standardMessagesManager.unsavedCategoryIds);
        break;

      case MessagesConfigAction.addStandardMessagesGroup:
        StandardMessagesGroupData groupData = data;
        var newGroup = standardMessagesManager.createStandardMessagesGroup(groupData.categoryId, groupData.categoryName);
        var messageCategoryMap = {
          groupData.categoryId: MessageCategory(groupData.categoryId, groupData.categoryName)
            ..groups = {
              newGroup.groupId: MessageGroup(newGroup.groupId ?? model.generateStandardMessageGroupId(), newGroup.groupName)
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
        standardMessagesManager.deleteStandardMessagesGroup(groupData.categoryId, groupData.categoryName, groupData.groupId, groupData.groupName);
        _view.categoriesById[groupData.categoryId].removeGroup(groupData.groupId);
        _updateUnsavedIndicators(standardMessagesManager.categories, standardMessagesManager.unsavedMessageIds, standardMessagesManager.unsavedGroupIds, standardMessagesManager.unsavedCategoryIds);
        break;

      case MessagesConfigAction.addStandardMessagesCategory:
        var newCategory = standardMessagesManager.createStandardMessagesCategory();
        var messageCategoryMap = {
          newCategory.categoryId: MessageCategory(newCategory.categoryId, newCategory.categoryName)
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
        standardMessagesManager.deleteStandardMessagesCategory(categoryData.categoryId, categoryData.categoryName);
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
