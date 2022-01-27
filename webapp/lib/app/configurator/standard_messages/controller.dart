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
  int indexInGroup;
  String groupId;
  String group;
  int groupIndexInCategory;
  String categoryId;
  String category;
  int categoryIndex;
  StandardMessageData(this.messageId, {this.text, this.translation, this.indexInGroup, this.groupId, this.group, this.groupIndexInCategory, this.categoryId, this.category, this.categoryIndex});

  @override
  String toString() {
    return "StandardMessageData($messageId, '$text', '$translation', $indexInGroup, $groupId, $group, $groupIndexInCategory, $categoryId, $category, $categoryIndex";
  }
}

class StandardMessagesGroupData extends Data {
  String groupId;
  String groupName;
  String newGroupName;
  String categoryId;
  String categoryName;
  int categoryIndex;
  int groupIndexInCategory;
  StandardMessagesGroupData(this.categoryId, this.categoryName, this.categoryIndex, this.groupId, this.groupName, this.groupIndexInCategory, {this.newGroupName});

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
        var category = standardMessagesManager.categories[messageData.categoryId];
        var group = standardMessagesManager.categories[messageData.categoryId].groups[messageData.groupId];

        var message = standardMessagesManager.createMessage(messageData.categoryId, category.categoryName, category.categoryIndex, messageData.groupId, group.groupName, group.groupIndexInCategory);
        var messageCategoryMap = {
          message.categoryId: MessageCategory(messageData.categoryId, category.categoryName, messageData.categoryIndex)
            ..groups = {
              message.groupId: MessageGroup(messageData.groupId, group.groupName, messageData.groupIndexInCategory)
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
        var categoryName = standardMessagesManager.categories[standardMessage.categoryId].categoryName;
        var groupName = standardMessagesManager.categories[standardMessage.categoryId].groups[standardMessage.groupId].groupName;

        // todo: unwanted map since we use only the category Id, group Id
        var messageCategoryMap = {
          standardMessage.categoryId: MessageCategory(standardMessage.categoryId, categoryName, messageData.categoryIndex)
            ..groups = {
              standardMessage.groupId: MessageGroup(messageData.groupId, groupName, messageData.groupIndexInCategory)
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
          standardMessage.categoryId: MessageCategory(standardMessage.categoryId, standardMessage.category, standardMessage.categoryIndex)
            ..groups = {
              standardMessage.groupId: MessageGroup(messageData.groupId, messageData.group, messageData.groupIndexInCategory )
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
          groupData.categoryId: MessageCategory(groupData.categoryId, groupData.categoryName, groupData.categoryIndex)
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
