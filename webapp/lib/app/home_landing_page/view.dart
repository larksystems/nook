import 'dart:html';

import 'package:katikati_ui_lib/components/logger.dart';
import 'package:katikati_ui_lib/components/button/button.dart';

import 'package:nook/view.dart';

import 'controller.dart';

Logger log = new Logger('view.dart');

class LandingPageView extends PageView {
  DivElement homePageContents;

  LandingPageView(LandingPageController controller) : super(controller) {
    homePageContents = new DivElement()..classes.add('configuration-view');
  }

  @override
  initSignedInView(String displayName, String photoUrl) {
    super.initSignedInView(displayName, photoUrl);
    mainElement.append(homePageContents);
  }
}
