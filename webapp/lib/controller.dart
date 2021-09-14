library controller;

import 'dart:html';

import 'package:katikati_ui_lib/components/auth/auth.dart';
import 'package:katikati_ui_lib/components/logger.dart';

import 'package:katikati_ui_lib/components/model/model.dart' as model;
import 'package:nook/platform/platform.dart';
import 'view.dart';

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
  explore
}

final pages = {
  Page.homepage: PageInfo('', '', ''),
  Page.configureTags: PageInfo('How do you want to label messages and conversations?', 'Configure tags', 'configure/tags.html'),
  Page.configureMessages: PageInfo('What standard messages do you want to send?', 'Configure messages', 'configure/messages.html'),
  Page.converse: PageInfo('View conversations and send messages', 'Conversations', '/converse/index.html'),
  Page.explore: PageInfo('Explore trends and analyse themes', 'Explore', '/explore'),
};


enum BaseAction {
  userSignedIn,
  userSignedOut,
  updateSystemMessages, // TODO: rename to systemMessagesUpdated

  signInButtonClicked,
  signOutButtonClicked,
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

class SystemMessagesData extends Data {
  List<model.SystemMessage> messages;
  SystemMessagesData(this.messages);

  @override
  String toString() => 'SystemMessagesData: {messages: ${messages.map((m) => m.toData().toString())}}';
}

class Controller {
  model.User signedInUser;
  List<model.SystemMessage> systemMessages;
  DateTime lastUserActivity = new DateTime.now();

  PageView view;
  Platform platform;

  Controller() {
    systemMessages = [];
  }

  void command(action, [Data data]) {
    switch (action) {
      case BaseAction.userSignedOut:
        signedInUser = null;
        // tearDownOnLogout();
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

      case BaseAction.updateSystemMessages:
        SystemMessagesData msgData = data;
        if (msgData.messages.isNotEmpty) {
          var lines = msgData.messages.map((m) => m.text);
          view.bannerView.showBanner(lines.join(', '));
        } else {
          view.bannerView.hideBanner();
        }
        break;
      default:
    }
  }

  void setUpOnLogin() {}
  // void tearDownOnLogout();

  /// Sets the route and reloads the page if the URL has changed, otherwise calls its corresponding handler.
  /// To be used for pages processing data, and so where loading the page multiple times can cause an issue.
  void routeToPath(String path) {
    var currentUri = Uri.parse(window.location.href);
    var pathUri = Uri.parse(path);
    var newUri = currentUri.replace(path: pathUri.path, fragment: pathUri.fragment, query: pathUri.query);

    window.location.assign(newUri.toString());
  }

  void routeToPage(Page page) => routeToPath(pages[page].urlPath);
}
