library controller;

import 'package:katikati_ui_lib/components/logger.dart';
import 'package:katikati_ui_lib/datatypes/user.dart';
import 'package:nook/controller.dart';
export 'package:nook/controller.dart';

import 'view.dart';

Logger log = new Logger('controller.dart');

class DashboardController extends Controller {
  DashboardController() : super();

  @override
  void init() {
    super.init();
    view = new DashboardView(this);
  }

  @override
  void setUpOnLogin() {
    super.setUpOnLogin();
  }

  void command(action, [Data data]) {
    switch (action) {
      case BaseAction.projectListUpdated:
        setUpProjectPage(urlManager.project);
        break;
      default:
        break;
    }

    super.command(action, data);
  }

  @override
  void applyConfiguration(UserConfiguration newConfig) {
    super.applyConfiguration(newConfig);

    if (projects.isNotEmpty && urlManager.project != null) {
      setUpProjectPage(urlManager.project);
    }
  }

  void setUpProjectPage(String projectId) {
    selectedProject = projects.singleWhere((element) => element.projectId == projectId, orElse: () => null);
    if (selectedProject == null) {
      command(BaseAction.showBanner, BannerData("Project '$projectId' doesn't exist, or you don't have access to it. Please contact your administrator if you think this is a mistake."));
      routeToPath('/');
      return;
    }
    (view as DashboardView).showProjectPage(
      projectId,
      {
        'Converse': [pages[Page.converse]],
        'Configure': [pages[Page.configureMessages], pages[Page.configureTags]],
        'Explore': [pages[Page.explore]],
        if (currentUserConfig.role == UserRole.projectAdmin || currentUserConfig.role == UserRole.superAdmin) 'Admin': [pages[Page.configureExplorer], pages[Page.configureProjectAndUsers]],
        // 'Tag': [pages[Page.coda]],
      });
  }
}
