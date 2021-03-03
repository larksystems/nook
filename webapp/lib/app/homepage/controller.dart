library controller;

import 'package:katikati_ui_lib/components/logger.dart';
import 'package:nook/controller.dart';
export 'package:nook/controller.dart';

import 'package:nook/platform/platform.dart';
import 'view.dart';

Logger log = new Logger('controller.dart');

class HomePageController extends Controller {

  HomePageController() : super() {
    view = new HomePageView(this,
      [pages[Page.converse]],
      [pages[Page.configureMessages], pages[Page.configureTags]],
      [pages[Page.explore]]);
    platform = new Platform(this);
  }
}
