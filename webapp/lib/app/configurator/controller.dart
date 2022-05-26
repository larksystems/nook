library controller;

import 'package:katikati_ui_lib/components/logger.dart';
import 'package:nook/controller.dart';
export 'package:nook/controller.dart';


Logger log = new Logger('controller.dart');

enum ConfigAction {
  saveConfiguration,
}

class ConfiguratorController extends Controller {
  ConfiguratorController() : super();

  @override
  void setUpOnLogin() {
    super.setUpOnLogin();
  }

  void command(action, [Data data]) {
    if (action is! ConfigAction) {
      super.command(action, data);
      return;
    }
    log.verbose('command => $action : $data');
    switch (action) {
      case ConfigAction.saveConfiguration:
        saveConfiguration();
        break;
    }
  }

  void saveConfiguration() {}
}
