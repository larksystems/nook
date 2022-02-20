import 'dart:html';

import 'package:katikati_ui_lib/components/logger.dart';
import 'package:katikati_ui_lib/components/button/button.dart';

import 'package:nook/view.dart';

import 'controller.dart';

Logger log = new Logger('view.dart');

class HomePageView extends PageView {
  DivElement homePageContents;

  HomePageView(HomePageController controller, Map<String, List<PageInfo>> pageStructure) : super(controller) {
    homePageContents = new DivElement()..classes.add('configuration-view');

    for (var heading in pageStructure.keys) {
      var title = new DivElement()
        ..classes.add('configuration-view__title')
        ..text = heading;
      homePageContents.append(title);

      DivElement pageContent = new DivElement()
        ..classes.add('configuration-view__content')
        ..classes.add('config-page-options');
      homePageContents.append(pageContent);

      for (var page in pageStructure[heading]) {
        var button  = Button(ButtonType.contained, buttonText: page.goToButtonText, onClick: (_) {
          this.appController.routeToPath(page.urlPath);
        });
        button.renderElement.classes.add('config-page-option__action');
        button.parent = pageContent;

        var description = new SpanElement()
          ..classes.add('config-page-option__description')
          ..text = page.shortDescription;
        pageContent..append(description);
      }
    }
  }

  @override
  initSignedInView(String displayName, String photoUrl) {
    super.initSignedInView(displayName, photoUrl);
    mainElement.append(homePageContents);
  }
}
