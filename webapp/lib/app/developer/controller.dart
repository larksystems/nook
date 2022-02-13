library controller;

import 'dart:convert';
import 'dart:html';
import 'package:katikati_ui_lib/components/logger.dart';
import 'package:nook/app/nook/controller.dart';
import 'package:nook/app/developer/utils.dart';

import 'view.dart';

Logger log = new Logger('controller.dart');

enum DeveloperAction {
  toggleDeveloperMode,
}

DeveloperController _controller;
DeveloperPageView get _view => _controller.view;

class DeveloperController extends Controller {

  DeveloperController() {
    _controller = this;
    view = new DeveloperPageView(_controller);
  }

  void init() {
    var encoder = new JsonEncoder.withIndent("  ");
    
    // update developer mode status
    showCurrentDeveloperModeStatus();

    // show project config
    var projectConfig = json.encode(projectConfiguration);
    var formattedProjectConfig = encoder.convert(json.decode(projectConfig));
    _view.updateProjectConfig(formattedProjectConfig);

    // load & show firebase constants
    try {
      HttpRequest.getString('/assets/firebase_constants.json').then((firebaseConfigJson) {
        _view.updateFirebaseConfig(encoder.convert(json.decode(firebaseConfigJson)));
      }, onError: (err) { 
        _view.updateFirebaseConfig("Error loading /assets/firebase_constants.json");
       });
    } catch (e) { 
      _view.updateFirebaseConfig("Error loading & parsing /assets/firebase_constants.json");
    }

    window.onStorage.listen((_) {
      showCurrentDeveloperModeStatus();
    });
  }

  void showCurrentDeveloperModeStatus() {
    var currentDeveloperModeStatus = window.localStorage[localStorageDeveloperModeKey];
    _view.updateDeveloperModeStatus(currentDeveloperModeStatus == localStorageDeveloperModeValue ? "✅ ACTIVE" : "❌ INACTIVE");
  }

  void toggleCurrentDeveloperModeStatus() {
    var currentDeveloperModeStatus = window.localStorage[localStorageDeveloperModeKey];
    if (currentDeveloperModeStatus == null) {
      window.localStorage.addAll({localStorageDeveloperModeKey: localStorageDeveloperModeValue});
    } else {
      window.localStorage.removeWhere((key, _) => key == localStorageDeveloperModeKey);
    }
  }

  void command(action, [Data data]) {
    if (action is! DeveloperAction) {
      super.command(action, data);
      return;
    }

    switch (action) {
      case DeveloperAction.toggleDeveloperMode:
        toggleCurrentDeveloperModeStatus();
        showCurrentDeveloperModeStatus();
        break;
    }
  }
}
