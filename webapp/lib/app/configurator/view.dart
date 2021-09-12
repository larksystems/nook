library view;

import 'dart:async';
import 'dart:html';

import 'package:katikati_ui_lib/components/logger.dart';
import 'package:katikati_ui_lib/components/button/button.dart';

import 'package:nook/view.dart';
export 'package:nook/view.dart';

import 'controller.dart';

Logger log = new Logger('view.dart');

/// An empty page to be inherited to create different options for configuring,
/// (e.g. tags or messages), and a save button with an indicator.
class ConfigurationPageView extends PageView {
  DivElement renderElement;
  DivElement headerElement;
  DivElement configurationTitle;
  DivElement configurationContent;

  DivElement configurationActions;
  ButtonElement saveConfigurationButton;
  SpanElement saveStatusElement;

  ConfigurationPageView(ConfiguratorController controller) : super(controller) {
    renderElement = new DivElement()..classes.add('configuration-view');

    headerElement = new DivElement()..classes.add('configuration-header');
    renderElement.append(headerElement);

    configurationTitle = new DivElement()..classes.add('configuration-view__title');
    headerElement.append(configurationTitle);

    configurationActions = new DivElement()..classes.add('configuration-actions');
    renderElement.append(configurationActions);

    saveConfigurationButton = new ButtonElement()
      ..hidden = true
      ..classes.add('configuration-actions__save-action')
      ..text = 'Save Configuration'
      ..onClick.listen((_) => controller.command(ConfigAction.saveConfiguration));
    configurationActions.append(saveConfigurationButton);

    saveStatusElement = new SpanElement()..classes.add('configuration-actions__save-action__status');
    configurationActions.append(saveStatusElement);

    headerElement.append(configurationActions);

    configurationContent = new DivElement()..classes.add('configuration-view__content');
    renderElement.append(configurationContent);
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

  void enableSaveButton() {
    saveConfigurationButton.removeAttribute('hidden');
  }

  void disableSaveButton() {
    saveConfigurationButton.setAttribute('hidden', 'true');
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
