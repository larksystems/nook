library view;

import 'dart:async';
import 'dart:html';

import 'package:katikati_ui_lib/components/logger.dart';

import 'package:nook/view.dart';
export 'package:nook/view.dart';

import 'controller.dart';

Logger log = new Logger('view.dart');

/// An empty page to be inherited to create different options for configuring,
/// (e.g. tags or messages), and a save button with an indicator.
class ConfigurationPageView extends PageView {
  DivElement renderElement;
  DivElement configurationTitle;
  DivElement configurationContent;

  DivElement configurationActions;
  ButtonElement saveConfigurationButton;
  SpanElement saveStatusElement;

  ConfigurationPageView(ConfiguratorController controller) : super(controller) {
    renderElement = new DivElement()..classes.add('configuration-view');

    var backPageLink = new Element.a()
      ..classes.add('configuration-view__back-link')
      ..text = 'Back to the main configuration page'
      ..onClick.listen((event) => controller.routeToPage(Page.homepage));
    renderElement.append(backPageLink);

    configurationTitle = new DivElement()..classes.add('configuration-view__title');
    renderElement.append(configurationTitle);

    configurationContent = new DivElement()..classes.add('configuration-view__content');
    renderElement.append(configurationContent);

    configurationActions = new DivElement()..classes.add('configuration-actions');
    renderElement.append(configurationActions);

    saveConfigurationButton = new ButtonElement()
      ..classes.add('configuration-actions__save-action')
      ..text = 'Save Configuration'
      ..onClick.listen((_) => controller.command(ConfigAction.saveConfiguration));
    configurationActions.append(saveConfigurationButton);

    saveStatusElement = new SpanElement()..classes.add('configuration-actions__save-action__status');
    configurationActions.append(saveStatusElement);
  }

  void initSignedInView(String displayName, String photoUrl) {
    super.initSignedInView(displayName, photoUrl);
    mainElement.append(renderElement);
  }

  /// How many seconds the save status will be displayed on screen before disappearing.
  static const _SECONDS_ON_SCREEN = 5;

  /// The length of the animation in milliseconds.
  /// This must match the animation length set in snackbar.css
  static const _ANIMATION_LENGTH_MS = 200;

  void showSaveStatus(String status) {
    saveStatusElement.text = status;
    saveStatusElement.classes.remove('hidden');
    new Timer(new Duration(seconds: _SECONDS_ON_SCREEN), () => hideSaveStatus());
  }

  hideSaveStatus() {
    saveStatusElement.classes.toggle('hidden', true);
    // Remove the contents after the animation ends
    new Timer(new Duration(milliseconds: _ANIMATION_LENGTH_MS), () => saveStatusElement.text = '');
  }
}

/// Helper widgets

class InlineOverlayModal {
  DivElement inlineOverlayModal;

  InlineOverlayModal(String message, List<Button> buttons) {
    inlineOverlayModal = new DivElement()..classes.add('inline-overlay-modal');

    inlineOverlayModal.append(new ParagraphElement()
      ..classes.add('inline-overlay-modal__message')
      ..text = message);

    var actions = new DivElement()..classes.add('inline-overlay-modal__actions');
    inlineOverlayModal.append(actions);
    for (var button in buttons) {
      button.parent = actions;
    }
  }

  void set parent(Element value) => value.append(inlineOverlayModal);
  void remove() => inlineOverlayModal.remove();
}

class PopupModal {
  DivElement popupModal;

  PopupModal(String message, List<Button> buttons) {
    popupModal = new DivElement()..classes.add('popup-modal');

    popupModal.append(new ParagraphElement()
      ..classes.add('popup-modal__message')
      ..text = message);

    var actions = new DivElement()..classes.add('popup-modal__actions');
    popupModal.append(actions);
    for (var button in buttons) {
      button.parent = actions;
    }
  }

  void set parent(Element value) => value.append(popupModal);
  void remove() => popupModal.remove();
}

class EditableText {
  DivElement editableWrapper;

  Button _editButton;
  Button _removeButton;
  Button _saveButton;
  Button _cancelButton;

  String _textBeforeEdit;
  bool _duringEdit;

  EditableText(Element textElementToEdit, {bool alwaysShowButtons: false, OnEventCallback onEditStart, OnEventCallback onEditEnd, OnEventCallback onSave, OnEventCallback onRemove}) {
    editableWrapper = new DivElement()..classes.add('editable-widget');
    if (alwaysShowButtons)
      editableWrapper..classes.add('editable-widget--always-show-buttons');
    editableWrapper.append(textElementToEdit);

    onEditStart = onEditStart ?? (_) {};
    onEditEnd = onEditEnd ?? (_) {};
    onSave = onSave ?? (_) {};
    onRemove = onRemove ?? (_) {};

    _duringEdit = false;
    var saveEdits = (e) {
      if (!_duringEdit) return;
      _duringEdit = false;

      _editButton.parent = editableWrapper;
      _removeButton.parent = editableWrapper;
      _saveButton.remove();
      _cancelButton.remove();

      textElementToEdit.contentEditable = 'false';
      onEditEnd(e);
      onSave(e);
    };

    var cancelEdits = (e) {
      if (!_duringEdit) return;
      _duringEdit = false;

      _editButton.parent = editableWrapper;
      _removeButton.parent = editableWrapper;
      _saveButton.remove();
      _cancelButton.remove();

      textElementToEdit.contentEditable = 'false';
      textElementToEdit.text = _textBeforeEdit;
      onEditEnd(e);
    };

    var startEditing = (e) {
      _duringEdit = true;

      _editButton.remove();
      _removeButton.remove();
      _saveButton.parent = editableWrapper;
      _cancelButton.parent = editableWrapper;

      _textBeforeEdit = textElementToEdit.text;
      _makeEditable(textElementToEdit, onEsc: cancelEdits, onEnter: (e) {
        e.stopPropagation();
        e.preventDefault();
        saveEdits(e);
      });
      onEditStart(e);
      textElementToEdit.focus();
    };

    _editButton = new Button(ButtonType.edit, onClick: startEditing);
    _editButton.parent = editableWrapper;

    _removeButton = new Button(ButtonType.remove, onClick: onRemove);
    _removeButton.renderElement.classes.add('button--on-hover-red');
    _removeButton.parent = editableWrapper;

    _saveButton = new Button(ButtonType.confirm, onClick: saveEdits);
    _saveButton.renderElement.classes.add('button--green');
    _cancelButton = new Button(ButtonType.remove, onClick: cancelEdits);
  }

  void set parent(Element value) => value.append(editableWrapper);
  void remove() => editableWrapper.remove();

  String get textBeforeEdit => _textBeforeEdit;
}

void _makeEditable(Element element, {OnEventCallback onBlur, OnEventCallback onEnter, OnEventCallback onEsc}) {
  element
    ..contentEditable = 'true'
    ..onBlur.listen((e) {
      e.stopPropagation();
      if (onBlur != null) onBlur(e);
    })
    ..onKeyPress.listen((e) => e.stopPropagation())
    ..onKeyUp.listen((e) => e.stopPropagation())
    ..onKeyDown.listen((e) {
      e.stopPropagation();
      if (onEnter != null && e.keyCode == KeyCode.ENTER) {
        onEnter(e);
        return;
      }
      if (onEsc != null && e.keyCode == KeyCode.ESC) {
        onEsc(e);
        return;
      }
    });
}
