library view;

import 'dart:html';
import 'package:nook/app/configurator/standard_messages/view.dart';

import 'controller.dart';
import 'package:katikati_ui_lib/components/logger.dart';

Logger log = new Logger('view.dart');

DeveloperPageView _view;

class DeveloperPageView extends PageView {
  DivElement _developerModeStatus;
  ButtonElement _modeToggleButton;
  TextAreaElement _projectConfigElement;
  TextAreaElement _firebaseConfigElement;

  DeveloperPageView(DeveloperController controller) : super(controller) {
    _view = this;

    _developerModeStatus = DivElement();
    _modeToggleButton = ButtonElement()
      ..innerText = "Toggle mode"
      ..onClick.listen((_) {
        _view.appController.command(DeveloperAction.toggleDeveloperMode, null);
      });
    _projectConfigElement = TextAreaElement()..disabled = true;
    _firebaseConfigElement = TextAreaElement()..disabled = true;

    var wrapper = DivElement()..className = "developer-view";
    mainElement.append(wrapper);
    wrapper
      ..append(
        DivElement()
          ..append(HeadingElement.h1()..innerText = "Developer mode")
          ..append(_developerModeStatus)
          ..append(_modeToggleButton)
      )
      ..append(
        DivElement()
          ..append(HeadingElement.h1()..innerText = "Project configuration")
          ..append(_projectConfigElement)
      )
      ..append(
        DivElement()
          ..append(HeadingElement.h1()..innerText = "Firebase constants")
          ..append(_firebaseConfigElement)
      );
  }

  void updateProjectConfig(String text) {
    _projectConfigElement.value = text;
  }

  void updateFirebaseConfig(String text) {
    _firebaseConfigElement.value = text;
  }

  void updateDeveloperModeStatus(String text) {
    _developerModeStatus.innerText = text;
  }
}
