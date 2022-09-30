library controller;

import 'dart:convert';
import 'dart:html';

import 'package:katikati_ui_lib/components/auth/auth.dart';
import 'package:katikati_ui_lib/components/logger.dart';

import 'package:katikati_ui_lib/components/model/model.dart' as model;
import 'package:katikati_ui_lib/components/snackbar/snackbar.dart';
import 'package:katikati_ui_lib/components/url_manager/url_manager.dart';
import 'package:katikati_ui_lib/components/nav/button_links.dart';
import 'package:katikati_ui_lib/components/platform/pubsub.dart';
import 'package:firebase/firebase.dart' show FirebaseError;

import 'package:nook/platform/platform.dart';
import 'view.dart';

part 'utils.dart';

Logger log = new Logger('controller.dart');

class PageInfo {
  String shortDescription;
  String goToButtonText;
  String urlPath;
  PageInfo(this.shortDescription, this.goToButtonText, this.urlPath);
}

enum Page {
  homepage,
  configureMessages,
  configureTags,
  converse,
  explore,
  coda,
}

final pages = {
  Page.homepage: PageInfo('', '', ''),
  Page.configureTags: PageInfo('How do you want to label messages and conversations?', 'Configure tags', 'configure/tags.html'),
  Page.configureMessages: PageInfo('What standard messages do you want to send?', 'Configure messages', 'configure/messages.html'),
  Page.converse: PageInfo('View conversations and send messages', 'Conversations', '/converse/index.html'),
  Page.explore: PageInfo('Explore trends and analyse themes', 'Explore', '/explore'),
  Page.coda: PageInfo('Efficiently tag large sets of messages', 'Survey tagging', '/coda'),
};


enum BaseAction {
  userSignedIn,
  userSignedOut,
  updateSystemMessages, // TODO: rename to systemMessagesUpdated

  signInButtonClicked,
  signOutButtonClicked,

  projectListUpdated,
  projectSelected,

  showSnackbar,
  showBanner,
}

class Data {}

class UserData extends Data {
  String displayName;
  String email;
  String photoUrl;
  UserData(this.displayName, this.email, this.photoUrl);

  @override
  String toString() => 'UserData: {displayName: $displayName, email: $email, photoUrl: $photoUrl}';
}

class SignInData extends Data {
  SignInDomainInfo info;
  SignInData(this.info);

  @override
  String toString() => 'SignInData: {domain: ${info.domain}}';
}

class ProjectData extends Data {
  String projectId;
  ProjectData(this.projectId);

  @override
  String toString() => 'ProjectData: {projectId: $projectId}';
}

class SystemMessagesData extends Data {
  List<model.SystemMessage> messages;
  SystemMessagesData(this.messages);

  @override
  String toString() => 'SystemMessagesData: {messages: ${messages.map((m) => m.toData().toString())}}';
}

class SnackbarData extends Data {
  String text;
  SnackbarNotificationType type;
  SnackbarData(this.text, this.type);

  @override
  String toString() => 'SnackbarData: {text: $text, type: $type}';
}

class BannerData extends Data {
  String text;
  BannerData(this.text);

  @override
  String toString() => 'BannerData: {text: $text}';
}


class Controller {
  model.User signedInUser;
  DateTime lastUserActivity = new DateTime.now();

  List<model.Project> projects;
  model.Project selectedProject;

  List<model.SystemMessage> systemMessages;

  UrlManager urlManager;

  model.UserConfiguration defaultUserConfig;
  model.UserConfiguration currentUserConfig;
  /// This represents the current configuration of the UI.
  /// It's computed by merging the [defaultUserConfig] and [currentUserConfig] (if set).
  model.UserConfiguration currentConfig;

  PageView view;
  Platform platform;

  Controller() {
    systemMessages = [];
    urlManager = UrlManager();
    projects = [];

    defaultUserConfig = model.UserConfigurationUtil.baseUserConfiguration;
    currentUserConfig = currentConfig = model.UserConfigurationUtil.emptyUserConfiguration;

    init();
  }

  /// Method to be implemented by extending classes to initialise the view after the project configuration has been loaded
  void init() {
    platform = new Platform(this);
  }

  /// Method to be implemented by extending classes to respond to their own UI command datatype.
  /// Any commands they don't recognise, they should pass them to super.command().
  void command(action, [Data data]) {
    switch (action) {
      case BaseAction.userSignedOut:
        signedInUser = null;
        tearDownOnLogout();
        view.initSignedOutView();
        break;

      case BaseAction.userSignedIn:
        UserData userData = data;
        signedInUser = new model.User()
          ..userName = userData.displayName
          ..userEmail = userData.email;
        view.initSignedInView(userData.displayName, userData.photoUrl);
        setUpOnLogin();
        break;

      case BaseAction.signInButtonClicked:
        SignInData signInData = data;
        platform.signIn(domain: signInData.info.domain);
        break;

      case BaseAction.signOutButtonClicked:
        platform.signOut();
        break;

      case BaseAction.projectListUpdated:
        print(selectedProject);
        print(projects);
        if (selectedProject == null) {
          if (urlManager.project != null) {
            selectedProject = projects.singleWhere((project) => project.projectId == urlManager.project, orElse: () => null);
          }
        }
        view.showProjectTitleOrSelector(selectedProject?.projectId, projects);
        break;
      case BaseAction.projectSelected:
        ProjectData projectData = data;
        if (projectData.projectId == null || projectData.projectId == '') {
          selectedProject = null;
          urlManager.clearProjectSpecificQueryParameters();
          urlManager.project = null;
          break;
        }
        if (projectData.projectId != selectedProject?.projectId) {
          selectedProject = projects.singleWhere((project) => project.projectId == projectData.projectId, orElse: () => null);
          urlManager.clearProjectSpecificQueryParameters();
          urlManager.project = projectData.projectId;
          break;
        }
        break;

      case BaseAction.updateSystemMessages:
        SystemMessagesData msgData = data;
        if (msgData.messages.isNotEmpty) {
          var lines = msgData.messages.map((m) => m.text);
          view.bannerView.showBanner(lines.join(', '));
        } else {
          view.bannerView.hideBanner();
        }
        break;

      case BaseAction.showSnackbar:
        SnackbarData snackbarData = data;
        view.snackbarView.showSnackbar(snackbarData.text, snackbarData.type);
        break;

      case BaseAction.showBanner:
        BannerData bannerData = data;
        view.bannerView.showBanner(bannerData.text);
        break;
      default:
    }
  }

  /// Method to be implemented by extending classes to set up any UI/listeners on user logging in
  void setUpOnLogin() {
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

      command(BaseAction.projectListUpdated);
    });

    if (urlManager.project != null) {
      platform.listenForUserConfigurations(
        (added, modified, removed) {
          List<model.UserConfiguration> changedUserConfigurations = new List()
            ..addAll(added)
            ..addAll(modified);
          var defaultConfig = changedUserConfigurations.singleWhere((c) => c.docId == 'default', orElse: () => null);
          defaultConfig = removed.where((c) => c.docId == 'default').length > 0 ? model.UserConfigurationUtil.baseUserConfiguration : defaultConfig;
          var userConfig = changedUserConfigurations.singleWhere((c) => c.docId == signedInUser.userEmail, orElse: () => null);
          userConfig = removed.where((c) => c.docId == signedInUser.userEmail).length > 0 ? model.UserConfigurationUtil.emptyUserConfiguration : userConfig;
          if (defaultConfig == null && userConfig == null) {
            // Neither of the relevant configurations has been changed, nothing to do here
            return;
          }
          defaultUserConfig = defaultConfig ?? defaultUserConfig;
          currentUserConfig = userConfig ?? currentUserConfig;
          var newConfig = currentUserConfig.applyDefaults(defaultUserConfig);
          applyConfiguration(newConfig);
        }, showAndLogError);
    }
    // Apply the default configuration before loading any new configs.
    applyConfiguration(defaultUserConfig);
  }

  /// Sets user customization flags from the data map
  /// If a flag is not set in the data map, it defaults to the existing values
  void applyConfiguration(model.UserConfiguration newConfig) {
    if (currentConfig?.consoleLoggingLevel != newConfig.consoleLoggingLevel) {
      currentConfig ??= model.UserConfigurationUtil.emptyUserConfiguration;
      currentConfig.consoleLoggingLevel = newConfig.consoleLoggingLevel;
      if (newConfig.consoleLoggingLevel.toLowerCase().contains('verbose')) {
          Logger.logLevel = LogLevel.VERBOSE;
      }
      if (newConfig.consoleLoggingLevel.toLowerCase().contains('debug')) {
          Logger.logLevel = LogLevel.DEBUG;
      }
      if (newConfig.consoleLoggingLevel.toLowerCase().contains('warning')) {
          Logger.logLevel = LogLevel.WARNING;
      }
      if (newConfig.consoleLoggingLevel.toLowerCase().contains('error')) {
          Logger.logLevel = LogLevel.ERROR;
      }
    }

    log.verbose('Updated user configuration: $currentConfig');
  }

  /// Method to be implemented by extending classes to tear down any UI/listeners on user logging out
  void tearDownOnLogout() {}

  /// Sets the route and reloads the page if the URL has changed, otherwise calls its corresponding handler.
  /// To be used for pages processing data, and so where loading the page multiple times can cause an issue.
  void routeToPath(String path) {
    var currentUri = Uri.parse(window.location.href);
    var pathUri = Uri.parse(path);
    var newUri = currentUri.replace(path: pathUri.path, fragment: pathUri.fragment, query: pathUri.query);

    window.location.assign(newUri.toString());
  }

  void routeToPage(Page page) => routeToPath(pages[page].urlPath);

  /// Set of configuration options common across UIs
  int get MESSAGE_MAX_LENGTH => selectedProject?.messageCharacterLimit ?? 160;

  void showAndLogError(error, trace) {
    log.error("$error${trace != null ? "\n$trace" : ""}");
    String errMsg;
    if (error is PubSubException) {
      errMsg = "A network problem occurred: ${error.message}";
    } else if (error is FirebaseError) {
      errMsg = "An firestore error occured: ${error.code} [${error.message}]";
      this.command(BaseAction.showBanner, new BannerData("You don't have access to this dataset. Please contact your project administrator"));
    } else if (error is Exception) {
      errMsg = "An internal error occurred: ${error.runtimeType}";
    }  else {
      errMsg = "$error";
    }
    this.command(BaseAction.showSnackbar, new SnackbarData(errMsg, SnackbarNotificationType.error));
  }
}
