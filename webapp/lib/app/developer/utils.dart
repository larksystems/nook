import 'dart:html';
import 'package:katikati_ui_lib/components/logger.dart';

Logger logger = Logger('script.dart');

const localStorageDeveloperModeKey = "DEVELOPER_MODE";
const localStorageDeveloperModeValue = "true";

Function(Event) _onClick = (Event event) {
  var dataset = (event.target as HtmlElement).dataset;
  if (dataset.isNotEmpty) {
    logger.verbose("\u001b[33mDev log: ${dataset.toString()}\u001b[0m");
  }
};

void _updateDeveloperMode() {
  var developerMode = window.localStorage[localStorageDeveloperModeKey] == localStorageDeveloperModeValue;
  if (developerMode) {
    document.addEventListener("click", _onClick, true);
  } else {
    document.removeEventListener("click", _onClick, true);
  }
}

void initDeveloperMode() {
  _updateDeveloperMode();

  window.onStorage.listen((event) {
    _updateDeveloperMode();
  });
}
