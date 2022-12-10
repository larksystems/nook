import 'dart:html';

import 'package:katikati_ui_lib/components/logger.dart';
import 'package:katikati_ui_lib/components/model/model.dart';

import 'package:nook/view.dart';

import 'controller.dart';

Logger log = new Logger('view.dart');

class HomePageView extends PageView {
  DivElement homePageContents;

  HomePageView(HomePageController controller) : super(controller) {
    homePageContents = new DivElement()..classes.add('configuration-view');
  }

  @override
  initSignedInView(String displayName, String photoUrl) {
    super.initSignedInView(displayName, photoUrl);
    mainElement.append(homePageContents);
  }

  void selectProject(String projectId) {
    projectSelector.value = projectId;
  }

  void showLandingPage(List<Project> projects) {
    navHeaderView.navContent = DivElement();

    homePageContents.children.clear();

    var welcomeMessage = DivElement()
      ..classes.add('project-title')
      ..append(new HeadingElement.h1()
        ..text = 'Welcome ${appController.signedInUser.userName}! Here are your projects:');
    homePageContents.append(welcomeMessage);

    DivElement projectList = DivElement()
      ..classes.add('project-list')
      ..classes.add('tile-container');

    for (var project in projects) {
      projectList.append(new ProjectTileView(project.projectName, project.projectId, './dashboard.html?project=${project.projectId}').tileElement);
    }
    homePageContents.append(projectList);
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
