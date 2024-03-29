import 'dart:html';

import 'package:katikati_ui_lib/components/auth/auth.dart';
import 'package:katikati_ui_lib/components/auth/auth_header.dart';
import 'package:katikati_ui_lib/components/brand_asset/brand_asset.dart' as brand;
import 'package:katikati_ui_lib/components/nav/button_links.dart';
import 'package:katikati_ui_lib/components/snackbar/snackbar.dart';
import 'package:katikati_ui_lib/components/banner/banner.dart';
import 'package:katikati_ui_lib/components/logger.dart';
import 'package:katikati_ui_lib/components/nav/nav_header.dart';
import 'package:katikati_ui_lib/components/model/model.dart' as model;

import 'package:nook/controller.dart';

Logger log = new Logger('view.dart');

Element get headerElement => querySelector('header');
Element get mainElement => querySelector('main');
Element get bodyElement => querySelector('body');
Element get footerElement => querySelector('footer');

PageView _pageView;

class PageView {
  // header
  BannerView bannerView;
  NavHeaderView navHeaderView;
  SelectElement projectSelector;
  AuthHeaderView authHeaderView;

  // main
  LoginPage loginPage;

  // footer
  SnackbarView snackbarView;

  Controller appController;

  PageView(this.appController) {
    _pageView = this;

    bannerView = new BannerView();
    navHeaderView = new NavHeaderView();
    authHeaderView = new AuthHeaderView(
        () {}, // We don't show the navbar when the user is not logged in, so no need to show this
        () => appController.command(BaseAction.signOutButtonClicked));
    navHeaderView.authHeader = authHeaderView;

    document.title = "${document.title} | Katikati";

    snackbarView = new SnackbarView();
  }

  void initSignedOutView() {
    authHeaderView.signOut();
    headerElement.children.clear();

    mainElement.children.clear();
    loginPage = new LoginPage();
    mainElement.append(loginPage.renderElement);

    footerElement.children.clear();
  }

  void initSignedInView(String displayName, String photoUrl) {
    authHeaderView.signIn(displayName, photoUrl);
    navHeaderView.navContent = ButtonLinksView(generateProjectLinks(appController.urlManager.project), window.location.pathname).renderElement;
    headerElement.append(navHeaderView.navViewElement);
    headerElement.insertBefore(bannerView.bannerElement, navHeaderView.navViewElement);

    mainElement.children.clear();

    footerElement.append(snackbarView.snackbarElement);
  }


  void showProjectTitleOrSelector(String projectId, List<model.Project> projects) {
    if (projectId == null ||  projects == null || projects.length == 0) {
      navHeaderView.projectTitle = null;
      return;
    }

    if (projects.length == 1) {
      var title = SpanElement()..text = projects[0].projectName;
      navHeaderView.projectTitle = title;
      return;
    }

    projectSelector = SelectElement();
    projectSelector.append(OptionElement()
        ..value = ''
        ..text = "See all projects");

    // TODO: This currently only works on MacOS, but it's not a big issue and can work as is until we restyle the selector.
    projectSelector.append(HRElement());

    for (var project in projects) {
      projectSelector.append(OptionElement()
        ..value = project.projectId
        ..text = project.projectName
        ..selected = project.projectId == projectId);
    }
    projectSelector.onChange.listen((event) {
      appController.command(BaseAction.projectSelected, ProjectData(projectSelector.value));
    });
    navHeaderView.projectTitle = projectSelector;
  }
}

/// The authentication page
class LoginPage {
  AuthMainView authView;

  LoginPage() {
    authView = new AuthMainView(
        brand.KATIKATI,
        'Log into Katikati',
        'Use the email address that you use at work.',
        _buildSignInDomainInfos(_pageView.appController.selectedProject?.allowedEmailDomainsMap ?? {null: null}),
        (SignInDomainInfo domainInfo) => _pageView.appController.command(BaseAction.signInButtonClicked, new SignInData(domainInfo)));
  }

  DivElement get renderElement => authView.authElement;

  List<SignInDomainInfo> _buildSignInDomainInfos(Map domains) {
    List<SignInDomainInfo> result = [];
    for (var domainName in domains.keys) {
      print(domainName);
      result.add(SignInDomainInfo(domainName, domains[domainName]));
    }
    return result;
  }
}
