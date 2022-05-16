library controller;

import 'dart:html';

import 'package:katikati_ui_lib/components/logger.dart';
import 'package:katikati_ui_lib/components/model/model.dart';
import 'package:katikati_ui_lib/components/url_manager/url_manager.dart';
import 'package:nook/controller.dart';
export 'package:nook/controller.dart';

import 'package:nook/platform/platform.dart';
import 'view.dart';

Logger log = new Logger('controller.dart');

enum UIState {
  landing,
  project,
}

enum UIAction {
  projectListUpdated,
  projectSelected,
}

class ProjectData extends Data {
  String projectId;
  ProjectData(this.projectId);

  @override
  String toString() => 'ProjectData: {projectId: $projectId}';
}

class HomePageController extends Controller {
  UrlManager urlManager;
  UIState state;
  List<Project> projects;
  Project selectedProject;

  HomePageController() : super() {
    projects = [];
  }


  @override
  void init() {
    urlManager = UrlManager();
    view = new HomePageView(this);
    platform = new Platform(this);
  }

  @override
  void setUpOnLogin() {
    super.setUpOnLogin();
    state = urlManager.project != null ? UIState.project : UIState.landing;

    platform.listenForProjects((added, modified, removed) {
      for (var project in added) {
        projects.add(project);
      }
      for (var project in modified) {
        var projectIndex = projects.indexWhere((element) => element.projectId == project.projectId);
        if (projectIndex == -1) {
          log.warning("Modified project with ID ${project.projectId} wasn't found - adding it");
          projects.add(project);
          continue;
        }
        projects[projectIndex] = project;
      }
      for (var project in removed) {
        projects.removeWhere((p1) => p1.projectId == project.projectId);
      }

      command(UIAction.projectListUpdated);
    });
  }

  void command(action, [Data data]) {
    if (action is! UIAction) {
      super.command(action, data);
      return;
    }

    switch (action) {
      case UIAction.projectListUpdated:
        switch (state) {
          case UIState.landing:
            setUpLandingPage();
            break;

          case UIState.project:
            setUpProjectPage(urlManager.project);
            break;

          default:
            break;
        }
        break;
      case UIAction.projectSelected:
        ProjectData projectData = data;
        if (projectData.projectId == null || projectData.projectId == '') {
          urlManager.project = null;
          window.location.reload();
          break;
        }
        if (projectData.projectId != selectedProject.projectId) {
          urlManager.project = projectData.projectId;
          window.location.reload();
          break;
        }
        break;
      default:
        break;
    }
  }

  void setUpLandingPage() {
    (view as HomePageView).showProjectTitleOrSelector(null);
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
    (view as HomePageView).showProjectTitleOrSelector(projects);
    (view as HomePageView).selectProject(projectId);
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
