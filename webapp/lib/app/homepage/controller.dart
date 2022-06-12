library controller;

import 'package:katikati_ui_lib/components/logger.dart';
import 'package:nook/controller.dart';
export 'package:nook/controller.dart';

import 'view.dart';

Logger log = new Logger('controller.dart');

enum UIState {
  landing,
  project,
}

class HomePageController extends Controller {
  UIState state;

  HomePageController() : super();


  @override
  void init() {
    super.init();
    view = new HomePageView(this);
  }

  @override
  void setUpOnLogin() {
    super.setUpOnLogin();
    state = urlManager.project != null ? UIState.project : UIState.landing;
  }

  void command(action, [Data data]) {
    switch (action) {
      case BaseAction.projectListUpdated:
        switch (state) {
          case UIState.landing:
            setUpLandingPage();
            break;

          case UIState.project:
            setUpProjectPage(urlManager.project);
            break;
        }
        break;
      default:
        break;
    }

    super.command(action, data);
  }

  void setUpLandingPage() {
    (view as HomePageView).showLandingPage(projects);
  }

  void setUpProjectPage(String projectId) {
    var previousProjectId = selectedProject?.projectId;
    if (previousProjectId == projectId) return;

    selectedProject = projects.singleWhere((element) => element.projectId == projectId, orElse: () => null);
    if (selectedProject == null) {
      setUpLandingPage();
      command(BaseAction.showBanner, BannerData("Project '$projectId' doesn't exist, or you don't have access to it. Please contact your administrator if you think this is a mistake."));
      return;
    }
    (view as HomePageView).showProjectPage(
      projectId,
      {
        'Converse': [pages[Page.converse]],
        'Configure': [pages[Page.configureMessages], pages[Page.configureTags]],
        'Explore': [pages[Page.explore]],
        // 'Tag': [pages[Page.coda]],
      });
  }
}
