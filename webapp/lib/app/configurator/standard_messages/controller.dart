library controller;

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
  // Handling standard messages
  addStandardMessage,
  addStandardMessagesGroup,
  updateStandardMessage,
  updateStandardMessagesGroup,
  removeStandardMessage,
  removeStandardMessagesGroup,
  toggleStandardMessagesGroup,
  expandStandardMessagesGroup,
  changeStandardMessagesCategory,
}

class StandardMessageData extends Data {
  String id;
  String text;
  String translation;
  String groupId;
  StandardMessageData(this.id, {this.text, this.translation, this.groupId});

  @override
  String toString() {
    return "StandardMessageData($id, '$text', '$translation', $groupId)";
  }
}

class StandardMessagesGroupData extends Data {
  String groupId;
  String groupName;
  String newGroupName;
  StandardMessagesGroupData(this.groupId, {this.groupName, this.newGroupName});

  @override
  String toString() {
    return "StandardMessagesGroupData($groupId, '$groupName', '$newGroupName')";
  }
}

class StandardMessagesCategoryData extends Data {
  String category;
  StandardMessagesCategoryData(this.category);

  @override
  String toString() {
    return "StandardMessagesCategoryData($category)";
  }
}

MessagesConfiguratorController _controller;
StdMessagesConfigPageView get _kkView => _controller.view;

class MessagesConfiguratorController extends ConfiguratorController {
  StandardMessagesManager standardMessagesManager = new StandardMessagesManager();
  String selectedStandardMessagesCategory;
  Map<String, model.SuggestedReply> editedStandardMessages = {};
  Map<String, model.SuggestedReply> removedStandardMessages = {};
  Set<String> collapsedMessageGroupIds = {};
  bool formDirty = false;

  MessagesConfiguratorController() : super() {
    _controller = this;
    view = new StdMessagesConfigPageView(this);
    platform = new Platform(this);
  }

  void command(action, [Data data]) {
    if (action is! MessagesConfigAction) {
      super.command(action, data);
      return;
    }
    log.verbose('command => $action : $data');
    switch (action) {
      case MessagesConfigAction.addStandardMessage:
        StandardMessageData messageData = data;
        var newStandardMessage = model.SuggestedReply()
          ..docId = standardMessagesManager.nextStandardMessageId
          ..text = ''
          ..translation = ''
          ..shortcut = ''
          ..seqNumber = standardMessagesManager.lastStandardMessageSeqNo
          ..category = selectedStandardMessagesCategory
          ..groupId = messageData.groupId
          ..groupDescription = standardMessagesManager.groups[messageData.groupId]
          ..indexInGroup = standardMessagesManager.getNextIndexInGroup(messageData.groupId);
        standardMessagesManager.addStandardMessage(newStandardMessage);

        var newStandardMessageView = new StandardMessageView(newStandardMessage.docId, newStandardMessage.text, newStandardMessage.translation);
        // _view.groups[messageData.groupId].addMessage(newStandardMessage.suggestedReplyId, newStandardMessageView);
        editedStandardMessages[newStandardMessage.docId] = newStandardMessage;
        formDirty = true;
        break;

      case MessagesConfigAction.updateStandardMessage:
        StandardMessageData messageData = data;
        var standardMessage = standardMessagesManager.getStandardMessageById(messageData.id);
        if (messageData.text != null) {
          standardMessage.text = messageData.text;
        }
        if (messageData.translation != null) {
          standardMessage.translation = messageData.translation;
        }
        editedStandardMessages[standardMessage.docId] = standardMessage;
        formDirty = true;
        break;

      case MessagesConfigAction.removeStandardMessage:
        StandardMessageData messageData = data;
        var standardMessage = standardMessagesManager.getStandardMessageById(messageData.id);
        standardMessagesManager.removeStandardMessage(standardMessage);
        // _view.groups[standardMessage.groupId].removeMessage(standardMessage.suggestedReplyId);
        editedStandardMessages.remove(standardMessage.suggestedReplyId);
        removedStandardMessages[standardMessage.suggestedReplyId] = standardMessage;
        formDirty = true;
        break;

      case MessagesConfigAction.addStandardMessagesGroup:
        var newGroupId = standardMessagesManager.nextStandardMessagesGroupId;
        standardMessagesManager.emptyGroups[newGroupId] = '';
        var standardMessagesGroupView = new StandardMessagesGroupView(newGroupId, standardMessagesManager.emptyGroups[newGroupId]);
        // _view.addGroup(newGroupId, standardMessagesGroupView);
        formDirty = true;
        break;

      case MessagesConfigAction.updateStandardMessagesGroup:
        StandardMessagesGroupData groupData = data;
        standardMessagesManager.updateStandardMessagesGroupDescription(groupData.groupId, groupData.newGroupName);
        // _view.groups[groupData.groupId].name = groupData.newGroupName;
        formDirty = true;
        break;

      case MessagesConfigAction.removeStandardMessagesGroup:
        StandardMessagesGroupData groupData = data;
        List<model.SuggestedReply> standardMessagesToRemove = standardMessagesManager.standardMessages.where((r) => r.groupId == groupData.groupId).toList();
        standardMessagesManager.removeStandardMessagesGroup(groupData.groupId);
        _kkView.groups.removeItem(groupData.groupId);
        for (var message in standardMessagesToRemove) {
          editedStandardMessages.remove(message.suggestedReplyId);
          removedStandardMessages[message.suggestedReplyId] = message;
        }
        formDirty = true;
        break;

      case MessagesConfigAction.toggleStandardMessagesGroup:
        StandardMessagesGroupData groupData = data;
        var groupId = groupData.groupId;
        var collapsed = collapsedMessageGroupIds.contains(groupId);
        if (collapsed) {
          collapsedMessageGroupIds.remove(groupId);
          _kkView.groups.removeItem(groupId);
        } else {
          collapsedMessageGroupIds.add(groupId);
          _kkView.groups.collapseItem(groupId);
        }
        break;

      case MessagesConfigAction.expandStandardMessagesGroup:
        StandardMessagesGroupData groupData = data;
        var groupId = groupData.groupId;
        var collapsed = collapsedMessageGroupIds.contains(groupId);
        if (collapsed) {
          collapsedMessageGroupIds.remove(groupId);
          _kkView.groups.expandItem(groupId);
        }
        break;

      case MessagesConfigAction.changeStandardMessagesCategory:
        StandardMessagesCategoryData groupData = data;
        selectedStandardMessagesCategory = groupData.category;
        collapsedMessageGroupIds.clear();
        _populateStandardMessagesConfigPage(standardMessagesManager.standardMessagesByCategory[selectedStandardMessagesCategory]);
        break;

      default:
    }

    if (formDirty) {
      _kkView.enableSaveButton();
    } else {
      _kkView.disableSaveButton();
    }
  }

  @override
  void setUpOnLogin() {
    platform.listenForSuggestedReplies((added, modified, removed) {
      standardMessagesManager.addStandardMessages(added);
      standardMessagesManager.updateStandardMessages(modified);
      standardMessagesManager.removeStandardMessages(removed);

      // Replace list of categories in the UI selector
      _kkView.categories = standardMessagesManager.categories;
      // If the categories have changed under us and the selected one no longer exists,
      // default to the first category, whichever it is
      if (!standardMessagesManager.categories.contains(selectedStandardMessagesCategory)) {
        selectedStandardMessagesCategory = standardMessagesManager.categories.first;
      }
      // Select the selected category in the UI and add the standard messages for it
      _kkView.selectedCategory = selectedStandardMessagesCategory;
      _populateStandardMessagesConfigPage(standardMessagesManager.standardMessagesByCategory[selectedStandardMessagesCategory]);
    });
  }

  @override
  void saveConfiguration() {
    _kkView.showSaveStatus('Saving...');
    bool otherPartSaved = false;

    platform.updateSuggestedReplies(editedStandardMessages.values.toList()).then((value) {
      editedStandardMessages.clear();
      if (otherPartSaved) {
        _kkView.showSaveStatus('Saved!');
        formDirty = false;
        _kkView.disableSaveButton();
        return;
      }
      otherPartSaved = true;
    }, onError: (error, stacktrace) {
      _kkView.showSaveStatus('Unable to save. Please check your connection and try again. If the issue persists, please contact your project administrator');
    });

    platform.deleteSuggestedReplies(removedStandardMessages.values.toList()).then((value) {
      removedStandardMessages.clear();
      if (otherPartSaved) {
        _kkView.showSaveStatus('Saved!');
        formDirty = false;
        _kkView.disableSaveButton();
        return;
      }
      otherPartSaved = true;
    }, onError: (error, stacktrace) {
      _kkView.showSaveStatus('Unable to save. Please check your connection and try again. If the issue persists, please contact your project administrator');
    });
  }
}
