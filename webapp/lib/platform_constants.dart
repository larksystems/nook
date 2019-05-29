library platform.constants;

import 'dart:convert';
import 'dart:html';

String _constantsFilePath = 'assets/firebase_constants.json';
Map<String, String> _constants;

void init() async {
  if (_constants != null) return;

  var constantsJson = await HttpRequest.getString(_constantsFilePath);
  _constants = (json.decode(constantsJson) as Map).map<String, String>((key, value) => new MapEntry(key.toString(), value.toString()));
}

String get apiKey => _constants['apiKey'];
String get authDomain => _constants['authDomain'];
String get databaseURL => _constants['databaseURL'];
String get projectId => _constants['projectId'];
String get storageBucket => _constants['storageBucket'];
String get messagingSenderId => _constants['messagingSenderId'];
String get logUrl => _constants['logUrl'];
String get publishUrl => _constants['publishUrl'];
String get smsTopic => projectId + '-sms-channel-topic';
