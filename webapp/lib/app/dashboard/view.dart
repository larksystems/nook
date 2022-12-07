import 'dart:html';

import 'package:katikati_ui_lib/components/logger.dart';
import 'package:katikati_ui_lib/components/button/button.dart';
import 'package:katikati_ui_lib/components/nav/button_links.dart';

import 'package:nook/view.dart';

import 'controller.dart';

Logger log = new Logger('view.dart');

class DashboardView extends PageView {
  DivElement dashboardContents;


  DashboardView(DashboardController controller) : super(controller) {
    dashboardContents = new DivElement()..classes.add('configuration-view');
  }

  @override
  initSignedInView(String displayName, String photoUrl) {
    super.initSignedInView(displayName, photoUrl);
    mainElement.append(dashboardContents);
  }

  void selectProject(String projectId) {
    projectSelector.value = projectId;
  }

  void showProjectPage(String projectId, Map<String, List<PageInfo>> pageStructure) {
    navHeaderView.navContent = ButtonLinksView(generateProjectLinks(appController.urlManager.project), window.location.pathname).renderElement;

    DivElement pageContents = DivElement();

    for (var heading in pageStructure.keys) {
      var title = new DivElement()
        ..classes.add('configuration-view__title')
        ..text = heading;
      pageContents.append(title);

      DivElement pageContent = new DivElement()
        ..classes.add('configuration-view__content')
        ..classes.add('config-page-options');
      pageContents.append(pageContent);

      for (var page in pageStructure[heading]) {
        var button  = Button(ButtonType.contained, buttonText: page.goToButtonText, onClick: (_) {
          this.appController.routeToPath('${page.urlPath}?project=${projectId}');
        });
        button.renderElement.classes.add('config-page-option__action');
        button.parent = pageContent;

        var description = new SpanElement()
          ..classes.add('config-page-option__description')
          ..text = page.shortDescription;
        pageContent..append(description);
      }
    }
    dashboardContents.children.clear();
    dashboardContents.append(pageContents);
  }
}

class ProjectTileView {
  AnchorElement tileElement;

  ProjectTileView(String title, String subtitle, String url) {
    tileElement = new AnchorElement()
      ..classes.add('tile')
      ..href = url;

    tileElement.append(new DivElement()
      ..classes.add('tile__title')
      ..text = title
    );

    tileElement.append(new DivElement()
      ..classes.add('tile__subtitle')
      ..text = subtitle
    );
  }
}
