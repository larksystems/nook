library controller;

import 'package:katikati_ui_lib/components/logger.dart';
import 'package:nook/controller.dart';
export 'package:nook/controller.dart';

import 'view.dart';

Logger log = new Logger('controller.dart');

class HomePageController extends Controller {
  HomePageController() : super();

  @override
  void init() {
    super.init();
    view = new HomePageView(this);
  }

  @override
  void setUpOnLogin() {
    super.setUpOnLogin();
  }

  void command(action, [Data data]) {
    switch (action) {
      case BaseAction.projectListUpdated:
        setUpLandingPage();
        break;
      default:
        break;
    }

    super.command(action, data);
  }

  void setUpLandingPage() {
    (view as HomePageView).showLandingPage(projects);
  }
}
