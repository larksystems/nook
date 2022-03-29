import 'dart:html';

import 'package:katikati_ui_lib/components/logger.dart';
import 'package:katikati_ui_lib/components/button/button.dart';
import 'package:katikati_ui_lib/components/model/model.dart';
import 'package:katikati_ui_lib/components/nav/button_links.dart';

import 'package:nook/view.dart';

import 'controller.dart';

Logger log = new Logger('view.dart');

class HomePageView extends PageView {
  DivElement homePageContents;
  SelectElement projectSelector;


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
      projectList.append(new ProjectTileView(project.projectName, project.projectId, './?project=${project.projectId}').tileElement);
    }
    homePageContents.append(projectList);
  }

  void showProjectPage(String projectId, Map<String, List<PageInfo>> pageStructure) {
    navHeaderView.navContent = ButtonLinksView(navLinks, window.location.pathname).renderElement;

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
    homePageContents.children.clear();
    homePageContents.append(pageContents);
  }

  void showProjectTitleOrSelector(List<Project> projects) {
    if (projects == null || projects.length == 0) {
      navHeaderView.projectTitle = null;
      return;
    }

    if (projects.length == 1) {
      var title = SpanElement()..text = projects[0].projectName;
      navHeaderView.projectTitle = title;
      return;
    }


    // String selectedProjectId = null;
    // if (projectSelector != null) {
    //   selectedProject = projectSelector.options[projectSelector.selectedIndex].value;
    // }
    projectSelector = SelectElement();
    projectSelector.append(OptionElement()
        ..value = ''
        ..text = "-- See all projects");

    for (var project in projects) {
      projectSelector.append(OptionElement()
        ..value = project.projectId
        ..text = project.projectName);
    }
    projectSelector.onChange.listen((event) {
      appController.command(UIAction.projectSelected, ProjectData(projectSelector.value));
    });
    navHeaderView.projectTitle = projectSelector;
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
