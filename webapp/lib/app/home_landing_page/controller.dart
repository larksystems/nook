library controller;

import 'dart:async';

import 'package:katikati_ui_lib/components/logger.dart';
import 'package:nook/controller.dart';
export 'package:nook/controller.dart';

import 'package:nook/platform/platform.dart';
import 'view.dart';

Logger log = new Logger('controller.dart');

class LandingPageController extends Controller {

  StreamSubscription projectListSubscription;

  LandingPageController() : super() {}

  @override
  void init() {
    view = new LandingPageView(this);
    platform = new Platform(this);
  }

  @override
  void setUpOnLogin() {
    platform.listenForProjects((added, modified, removed) {
      
    });
  }
}
