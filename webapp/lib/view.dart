import 'dart:html';

import 'package:katikati_ui_lib/components/auth/auth.dart';
import 'package:katikati_ui_lib/components/auth/auth_header.dart';
import 'package:katikati_ui_lib/components/brand_asset/brand_asset.dart';
import 'package:katikati_ui_lib/components/snackbar/snackbar.dart';
import 'package:katikati_ui_lib/components/banner/banner.dart';
import 'package:katikati_ui_lib/components/logger.dart';
import 'package:katikati_ui_lib/components/nav/nav_header.dart';

import 'package:nook/controller.dart';

Logger log = new Logger('view.dart');

Element get headerElement => querySelector('header');
Element get mainElement => querySelector('main');
Element get footerElement => querySelector('footer');

PageView _pageView;

class PageView {
  // header
  BannerView bannerView;
  NavHeaderView navHeaderView;
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

    snackbarView = new SnackbarView();
  }

  initSignedOutView() {
    authHeaderView.signOut();
    headerElement.children.clear();

    mainElement.children.clear();
    loginPage = new LoginPage();
    mainElement.append(loginPage.renderElement);

    footerElement.children.clear();
  }

  initSignedInView(String displayName, String photoUrl) {
    authHeaderView.signIn(displayName, photoUrl);
    headerElement.append(navHeaderView.navViewElement);
    headerElement.insertBefore(bannerView.bannerElement, navHeaderView.navViewElement);

    mainElement.children.clear();

    footerElement.append(snackbarView.snackbarElement);
  }
}

/// The authentication page
class LoginPage {
  AuthMainView authView;

  LoginPage() {
    authView = new AuthMainView(Brand.katikati, '', '',
    [KATIKATI_DOMAIN_INFO, LARK_DOMAIN_INFO],
        (SignInDomainInfo domain) => _pageView.appController.command(BaseAction.signInButtonClicked, new SignInData(domain)));
  }

  DivElement get renderElement => authView.authElement;
}


/// Helper widgets

typedef void OnEventCallback(Event e);

enum ButtonType {
  // Text buttons
  text,
  outlined,
  contained,

  // Icon buttons
  add,
  remove,
  confirm,
  edit,
}

class ButtonAction {
  String buttonText;
  OnEventCallback onClick;

  ButtonAction(this.buttonText, this.onClick);
}

class Button {
  ButtonElement _element;

  Button(ButtonType buttonType, {String buttonText = '', String hoverText = '', OnEventCallback onClick}) {
    _element = new ButtonElement()
      ..classes.add('button')
      ..title = hoverText;

    onClick = onClick ?? (_) {};
    _element.onClick.listen(onClick);

    switch (buttonType) {
      case ButtonType.text:
        _element.classes.add('button--text');
        _element.text = buttonText;
        break;
      case ButtonType.outlined:
        _element.classes.add('button--outlined');
        _element.text = buttonText;
        break;
      case ButtonType.contained:
        _element.classes.add('button--contained');
        _element.text = buttonText;
        break;

      case ButtonType.add:
        _element.classes.add('button--add');
        break;
      case ButtonType.remove:
        _element.classes.add('button--remove');
        break;
      case ButtonType.confirm:
        _element.classes.add('button--confirm');
        break;
      case ButtonType.edit:
        _element.classes.add('button--edit');
        break;
    }
  }

  Element get renderElement => _element;

  void set visible(bool value) {
    _element.classes.toggle('hidden', !value);
  }

  void set parent(Element value) => value.append(_element);
  void remove() => _element.remove();
}
