library controller;

import 'package:katikati_ui_lib/components/logger.dart';
import 'package:nook/controller.dart';
export 'package:nook/controller.dart';

import 'package:nook/platform/platform.dart';
import 'view.dart';

Logger log = new Logger('controller.dart');

class HomePageController extends Controller {

  HomePageController() : super() {}

  @override
  void init() {
    view = new HomePageView(
      this,
      {
        'Converse': [pages[Page.converse]],
        'Configure': [pages[Page.configureMessages], pages[Page.configureTags]],
        'Explore': [pages[Page.explore]],
        // 'Tag': [pages[Page.coda]],
      });
    platform = new Platform(this);
  }
}
