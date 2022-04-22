library controller;

import 'dart:html';
import 'package:katikati_ui_lib/components/accordion/accordion.dart';
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
  resetStandardMessageText,
  resetStandardMessageTranslation,
  removeStandardMessage,
  addStandardMessagesGroup,
  reorderStandardMessagesGroup,
  updateStandardMessagesGroup,
  removeStandardMessagesGroup,
  resetStandardMessagesGroupName,
  addStandardMessagesCategory,
  reorderStandardMessagesCategory,
  updateStandardMessagesCategory,
  removeStandardMessagesCategory,
  resetStandardMessagesCategoryName,
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

class StandardMessagesCategoriesReorderData extends Data {
  String categoryId;
  int newIndex;
  StandardMessagesCategoriesReorderData(this.categoryId, this.newIndex);

  @override
  String toString() {
    return "StandardMessagesCategoriesReorderData(categoryId: ${categoryId}, newIndex: ${newIndex})";
  }
}

class StandardMessagesGroupsReorderData extends Data {
  String categoryId;
  String groupId;
  int newIndex;
  StandardMessagesGroupsReorderData(this.categoryId, this.groupId, this.newIndex);

  @override
  String toString() {
    return "StandardMessagesGroupsReorderData(categoryId: $categoryId, groupIds ${groupId}, newIndex: ${newIndex})";
  }
}

MessagesConfiguratorController _controller;
MessagesConfigurationPageView get _view => _controller.view;

class MessagesConfiguratorController extends ConfiguratorController {
  StandardMessagesManager standardMessagesManager = new StandardMessagesManager();

  MessagesConfiguratorController() : super() {
    _controller = this;
  }

  void _updateDiffUnsavedIndicators() {
    var diffData = standardMessagesManager.diffData;
    _updateUnsavedIndicators(standardMessagesManager.localCategories, diffData.unsavedMessageTextIds, diffData.unsavedMessageTranslationIds, diffData.renamedGroupIds, diffData.unsavedGroupIds, diffData.renamedCategoryIds, diffData.unsavedCategoryIds);
    _view.unsavedChanges = diffData.reorderedMessages.isNotEmpty || diffData.editedMessages.isNotEmpty || diffData.deletedMessages.isNotEmpty;
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
    log.verbose('Before -- ${standardMessagesManager.localCategories}');
    switch (action) {
      case MessagesConfigAction.addStandardMessage:
        StandardMessageData messageData = data;
        var categoryId = messageData.categoryId;
        var groupId = messageData.groupId;

        var category = standardMessagesManager.localCategories[categoryId];
        var group = standardMessagesManager.localCategories[categoryId].groups[groupId];
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
        break;

      case MessagesConfigAction.updateStandardMessage:
        StandardMessageData messageData = data;
        var standardMessage = standardMessagesManager.modifyMessage(messageData.messageId, messageData.text, messageData.translation);
        _modifyMessagesInView([standardMessage]);
        break;

      case MessagesConfigAction.removeStandardMessage:
        StandardMessageData messageData = data;
        var standardMessage = standardMessagesManager.deleteMessage(messageData.messageId);
        _removeMessagesFromView([standardMessage]);
        break;

      case MessagesConfigAction.resetStandardMessageText:
        StandardMessageData messageData = data;
        var message = standardMessagesManager.standardMessagesInStorage.firstWhere((element) => element.docId == messageData.messageId, orElse: () => null);
        if (message == null) {
          var localMessage = standardMessagesManager.standardMessagesInLocal.firstWhere((element) => element.docId == messageData.messageId);
          var translation = localMessage.translation;
          var standardMessage = standardMessagesManager.modifyMessage(messageData.messageId, "", translation);
          _modifyMessagesInView([standardMessage]);
          break;
        }
        var textToReset = standardMessagesManager.storageCategories[message.categoryId].groups[message.groupId].messages[message.docId].text;
        var translation = standardMessagesManager.localCategories[message.categoryId].groups[message.groupId].messages[message.docId].translation;
        var standardMessage = standardMessagesManager.modifyMessage(messageData.messageId, textToReset, translation);
        _modifyMessagesInView([standardMessage]);
        break;

      case MessagesConfigAction.resetStandardMessageTranslation:
        StandardMessageData messageData = data;
        var message = standardMessagesManager.standardMessagesInStorage.firstWhere((element) => element.docId == messageData.messageId, orElse: () => null);
        if (message == null) {
          var localMessage = standardMessagesManager.standardMessagesInLocal.firstWhere((element) => element.docId == messageData.messageId);
          var textToReset = localMessage.text;
          var standardMessage = standardMessagesManager.modifyMessage(messageData.messageId, textToReset, "");
          _modifyMessagesInView([standardMessage]);
          break;
        }
        var textToReset = standardMessagesManager.localCategories[message.categoryId].groups[message.groupId].messages[message.docId].text;
        var translation = standardMessagesManager.storageCategories[message.categoryId].groups[message.groupId].messages[message.docId].translation;
        var standardMessage = standardMessagesManager.modifyMessage(messageData.messageId, textToReset, translation);
        _modifyMessagesInView([standardMessage]);
        break;

      case MessagesConfigAction.addStandardMessagesGroup:
        StandardMessagesGroupData groupData = data;
        var category = standardMessagesManager.localCategories[groupData.categoryId];
        var newGroup = standardMessagesManager.createStandardMessagesGroup(category.categoryId, category.categoryName);
        var messageCategoryMap = {
          category.categoryId: MessageCategory(category.categoryId, category.categoryName, category.categoryIndex)
            ..groups = {
              newGroup.groupId: MessageGroup(newGroup.groupId, newGroup.groupName, newGroup.groupIndexInCategory)
            }
        };
        _addMessagesToView(messageCategoryMap, startEditingName: true);
        break;

      case MessagesConfigAction.updateStandardMessagesGroup:
        StandardMessagesGroupData groupData = data;
        standardMessagesManager.renameStandardMessageGroup(groupData.categoryId, groupData.groupId, groupData.newGroupName);
        _view.categoriesById[groupData.categoryId].renameGroup(groupData.groupId, groupData.newGroupName);
        break;

      case MessagesConfigAction.removeStandardMessagesGroup:
        StandardMessagesGroupData groupData = data;
        standardMessagesManager.deleteStandardMessagesGroup(groupData.categoryId, groupData.groupId);
        _view.categoriesById[groupData.categoryId].removeGroup(groupData.groupId);
        break;

      case MessagesConfigAction.resetStandardMessagesGroupName:
        StandardMessagesGroupData groupData = data;
        var resetGroupName = standardMessagesManager.storageCategories[groupData.categoryId].groups[groupData.groupId].groupName;
        standardMessagesManager.renameStandardMessageGroup(groupData.categoryId, groupData.groupId, resetGroupName);
        _view.categoriesById[groupData.categoryId].renameGroup(groupData.groupId, resetGroupName);
        break;

      case MessagesConfigAction.reorderStandardMessagesGroup:
        StandardMessagesGroupsReorderData groupData = data;
        var currentGroups = standardMessagesManager.localCategories[groupData.categoryId].groups.values.toList()
          ..sort((g1, g2) => g1.groupIndexInCategory.compareTo(g2.groupIndexInCategory));
        var currentGroupIds = currentGroups.map((e) => e.groupId).toList();
        var currentGroupIndex = currentGroupIds.indexOf(groupData.groupId);

        if (currentGroupIndex < groupData.newIndex) {
          --groupData.newIndex;
        }

        currentGroupIds.remove(groupData.groupId);
        currentGroupIds.insert(groupData.newIndex, groupData.groupId);
        standardMessagesManager.reorderMessagesGroup(groupData.categoryId, currentGroupIds);

        var accordionViewToMove = _view.categoriesById[groupData.categoryId].groups.items[currentGroupIndex];
        _view.categoriesById[groupData.categoryId].groups.reorderItem(accordionViewToMove, groupData.newIndex);
        break;

      case MessagesConfigAction.addStandardMessagesCategory:
        var newCategory = standardMessagesManager.createStandardMessagesCategory();
        var messageCategoryMap = {
          newCategory.categoryId: MessageCategory(newCategory.categoryId, newCategory.categoryName, newCategory.categoryIndex)
        };
        _addMessagesToView(messageCategoryMap, startEditingName: true);
        break;

      case MessagesConfigAction.updateStandardMessagesCategory:
        StandardMessagesCategoryData categoryData = data;
        standardMessagesManager.renameStandardMessageCategory(categoryData.categoryId, categoryData.newCategoryName);
        _view.renameCategory(categoryData.categoryId, categoryData.newCategoryName);
        break;

      case MessagesConfigAction.removeStandardMessagesCategory:
        StandardMessagesCategoryData categoryData = data;
        standardMessagesManager.deleteStandardMessagesCategory(categoryData.categoryId);
        _view.categories.removeItem(categoryData.categoryId);
        break;
      
      case MessagesConfigAction.resetStandardMessagesCategoryName:
        StandardMessagesCategoryData categoryData = data;
        var resetCategoryName = standardMessagesManager.storageCategories[categoryData.categoryId].categoryName;
        standardMessagesManager.renameStandardMessageCategory(categoryData.categoryId, resetCategoryName);
        _view.renameCategory(categoryData.categoryId, resetCategoryName);
        break;

      case MessagesConfigAction.reorderStandardMessagesCategory:
        StandardMessagesCategoriesReorderData categoryData = data;
        var currentCategories = standardMessagesManager.localCategories.values.toList()
          ..sort((c1, c2) => c1.categoryIndex.compareTo(c2.categoryIndex));
        var currentCategoryIds = currentCategories.map((e) => e.categoryId).toList();
        var currentCategoryIndex = currentCategoryIds.indexOf(categoryData.categoryId);

        if (currentCategoryIndex < categoryData.newIndex) {
          --categoryData.newIndex;
        }

        currentCategoryIds.remove(categoryData.categoryId);
        currentCategoryIds.insert(categoryData.newIndex, categoryData.categoryId);
        standardMessagesManager.reorderMessagesCategory(currentCategoryIds);

        var accordionViewToMove = _view.categories.items[currentCategoryIndex];
        _view.categories.reorderItem(accordionViewToMove, categoryData.newIndex);
        break;
    }

    log.verbose('After -- ${standardMessagesManager.localCategories}');
    _updateDiffUnsavedIndicators();
  }

  @override
  void setUpOnLogin() {
    platform.listenForSuggestedReplies((added, modified, removed) {
      var messagesAdded = standardMessagesManager.onAddStandardMessagesFromStorage(added);
      var messagesModified = standardMessagesManager.onUpdateStandardMessagesFromStorage(modified);
      var messagesRemoved = standardMessagesManager.onRemoveStandardMessagesFromStorage(removed);

      _addMessagesToView(_groupMessagesIntoCategoriesAndGroups(messagesAdded));
      _modifyMessagesInView(messagesModified);
      _removeMessagesFromView(messagesRemoved);

      _updateDiffUnsavedIndicators();
    });
  }

  @override
  void saveConfiguration() async {
    _view.showSaveStatus('Saving...');
    _view.disableSaveButton();
    var diffData = standardMessagesManager.diffData;
    List<model.SuggestedReply> updatedMessages = List.from(diffData.editedMessages)..addAll(diffData.reorderedMessages);

    try {
      await Future.wait([platform.updateSuggestedReplies(updatedMessages), platform.deleteSuggestedReplies(diffData.deletedMessages)]);
      _view
        ..unsavedChanges = false
        ..showSaveStatus('Saved!', autoHide: true);
    } catch (err) {
      _view
        ..hideSaveStatus()
        ..showSaveStatus('Unable to save. Please check your connection and try again. If the issue persists, please contact your project administrator');
    }
  }
}
