import 'dart:html';
import 'package:katikati_ui_lib/components/button/button.dart';
import 'package:katikati_ui_lib/components/logger.dart';
import 'package:katikati_ui_lib/datatypes/user.dart';
import 'package:nook/view.dart';

import 'controller.dart';

Logger log = new Logger('view.dart');

class Permission {
  String key;
  String type;
  String explanation;

  Permission(this.key, this.type, {this.explanation});
}

Map<String, List<Permission>> permissionGroups = {
  "Standard messages": [
    Permission("edit_standard_messages_enabled", "bool"),
  ],
  "Tags": [
    Permission("edit_tags_enabled", "bool"),
  ],
  "Conversations": [
    Permission("send_messages_enabled", "bool"),
    Permission("send_custom_messages_enabled", "bool"),
    Permission("send_multi_message_enabled", "bool"),
    Permission("tag_messages_enabled", "bool"),
    Permission("tag_conversations_enabled", "bool"),
    Permission("conversational_turns_enabled", "bool"),
    Permission("tags_panel_visibility", "bool"),
    Permission("replies_panel_visibility", "bool"),
    Permission("turnline_panel_visibility", "bool"),
    Permission("suggested_replies_groups_enabled", "bool"),
    Permission("tags_keyboard_shortcuts_enabled", "bool"),
    Permission("replies_keyboard_shortcuts_enabled", "bool"),
    Permission("edit_translations_enabled", "bool"),
    Permission("edit_notes_enabled", "bool"),
    Permission("mandatory_include_tag_ids", "Set<String>"),
    Permission("mandatory_exclude_tag_ids", "Set<String>"),
    Permission("multi_select_exclude_tag_ids", "Set<String>"),
  ],
  "Explore": [
    Permission("sample_messages_enabled", "bool"),
  ],
  "Miscellaneous": [
    Permission("console_logging_level", "String"),
    Permission("role", "String"),
    Permission("status", "String"),
  ]
};

const DEFAULT_KEY = "default";
const VALUE_FROM_DEFAULT_CSS_CLASS = "from-default";
bool isDefaultPermission(key) => key == DEFAULT_KEY;

class UsersPageView extends PageView {
  HeadingElement headerElement;
  ParagraphElement helperElement;
  DivElement tableWrapper;

  // email > permission key > header/checkbox/textbox
  Map<String, Element> permissionEmailHeaders;
  Map<String, Map<String, CheckboxInputElement>> permissionToggles;
  Map<String, Map<String, TextInputElement>> permissionTextboxes;
  Map<String, Map<String, SpanElement>> resetToDefaultPermissionsButtons;

  UsersPageView(UsersController controller) : super(controller) {
    permissionEmailHeaders = {};
    permissionToggles = {};
    permissionTextboxes = {};
    resetToDefaultPermissionsButtons = {};

    headerElement = HeadingElement.h1()
      ..innerText = "User permissions"
      ..className = "user-permissions__heading";
    helperElement = ParagraphElement()..innerText = "Default permissions apply to all user accounts unless overridden individually. Muted controls are derived from the default.";
    tableWrapper = DivElement()
      ..className = "user-permissions__table-wrapper";
    tableWrapper.append(ImageElement(src: '/packages/katikati_ui_lib/components/brand_asset/logos/loading.svg')..className = "load-spinner");
  }

  void updatePermission(String email, String permissionKey, dynamic value, {bool setToDefault = false}) {
    if (!permissionToggles[email].containsKey(permissionKey) && !permissionTextboxes[email].containsKey(permissionKey)) return;
    switch (value.runtimeType.toString()) {
      case 'bool':
        permissionToggles[email][permissionKey].checked = value;
        permissionToggles[email][permissionKey].classes.toggle(VALUE_FROM_DEFAULT_CSS_CLASS, setToDefault);
        break;

      case 'String':
        permissionTextboxes[email][permissionKey].value = value;
        permissionTextboxes[email][permissionKey].classes.toggle(VALUE_FROM_DEFAULT_CSS_CLASS, setToDefault);
        break;

      case 'List<String>':
        permissionTextboxes[email][permissionKey].value = value?.join(", ");
        permissionTextboxes[email][permissionKey].classes.toggle(VALUE_FROM_DEFAULT_CSS_CLASS, setToDefault);
        break;
    }
  }

  void toggleSaved(String email, String key, bool saved) {
    permissionEmailHeaders[email].classes.toggle("unsaved", !saved);
  }

  void populateTable(UserConfiguration defaultConfig, Map<String, UserConfiguration> usersConfig) {
    tableWrapper.children.clear();
    var table = TableElement();
    // thead, tbody
    var tableHeader = table.createTHead();
    var tableBody = table.createTBody();
    table
      ..append(tableHeader)
      ..append(tableBody);

    var allEmails = [defaultConfig.docId]..addAll(usersConfig.keys);

    // email headers
    var headerRow = TableRowElement()..append(Element.th());
    allEmails.forEach((email) {
      var emailHeader = Element.th()..innerText = email;
      permissionEmailHeaders[email] = emailHeader;
      headerRow.append(emailHeader);
    });
    tableHeader.append(headerRow);

    var defaultConfigMap = defaultConfig.toData();

    for (var group in permissionGroups.keys) {
      var groupTitle = TableRowElement()
        ..append(Element.td()..className = "group-row"..innerText = group)
        ..append(Element.td()..className = "group-row--empty"..attributes["colspan"] = allEmails.length.toString());
      tableBody.append(groupTitle);
      for (var permission in permissionGroups[group]) {
        var permissionRow = TableRowElement();
        var permissionText = DivElement()..innerText = permission.key;
        var permissionExplanation = SpanElement()..className = "permission-explanation"..innerText = permission.explanation;
        permissionRow.append(Element.th()..append(permissionText)..append(permissionExplanation));

        allEmails.forEach((email) {
          var permissionMap = isDefaultPermission(email) ? defaultConfigMap : usersConfig[email].toData();
          var permissionValue = permissionMap[permission.key];
          SpanElement resetToDefault;
          bool derivedFromDefault = !isDefaultPermission(email) && permissionValue == null;
          if (derivedFromDefault) {
            permissionValue = defaultConfigMap[permission.key];
          } else {
            if (!isDefaultPermission(email)) {
              var resetButton = Button(ButtonType.reset, hoverText: 'Reset to default', onClick: (_) {
                appController.command(UsersAction.resetToDefaultPermission, ResetToDefaultPermission(email, permission.key));
              });
              resetToDefault = resetButton.renderElement;
              resetToDefaultPermissionsButtons[email] = resetToDefaultPermissionsButtons[email] ?? {};
              resetToDefaultPermissionsButtons[email][permission.key] = resetToDefault;
            }
          }

          Element renderElement;
          switch (permission.type) {
            case 'bool':
              renderElement = CheckboxInputElement()
                ..checked = permissionValue
                ..onChange.listen((event) {
                  renderElement.classes.remove(VALUE_FROM_DEFAULT_CSS_CLASS);
                  appController.command(UsersAction.updatePermission, UpdatePermission(email, permission.key, (event.target as CheckboxInputElement).checked));
                });
              if (derivedFromDefault) {
                renderElement.classes.add(VALUE_FROM_DEFAULT_CSS_CLASS);
              }
              permissionToggles[email] = permissionToggles[email] ?? {};
              permissionToggles[email][permission.key] = renderElement;
              break;
            case 'String':
              renderElement = TextInputElement()
                ..value = permissionValue
                ..onInput.listen((event) {
                  renderElement.classes.remove(VALUE_FROM_DEFAULT_CSS_CLASS);
                  appController.command(UsersAction.updatePermission, UpdatePermission(email, permission.key, (event.target as TextInputElement).value));
                });
              if (derivedFromDefault) {
                renderElement.classes.add(VALUE_FROM_DEFAULT_CSS_CLASS);
              }
              permissionTextboxes[email] = permissionTextboxes[email] ?? {};
              permissionTextboxes[email][permission.key] = renderElement;
              break;
            case 'Set<String>':
              renderElement = TextInputElement()
                ..value = (permissionValue as List<String>)?.join(",")
                ..onInput.listen((event) {
                  renderElement.classes.remove(VALUE_FROM_DEFAULT_CSS_CLASS);
                  var value = (event.target as TextInputElement).value.split(',');
                  appController.command(UsersAction.updatePermission, UpdatePermission(email, permission.key, value));
                });
              if (derivedFromDefault) {
                renderElement.classes.add(VALUE_FROM_DEFAULT_CSS_CLASS);
              }
              permissionTextboxes[email] = permissionTextboxes[email] ?? {};
              permissionTextboxes[email][permission.key] = renderElement;
              break;
            default:
              renderElement = SpanElement()..innerText = "Unknown data type";
              break;
          }
          var cell = TableCellElement()
            ..append(renderElement)
            ..onMouseEnter.listen((event) {
              permissionEmailHeaders[email].classes.toggle('highlight', true);
            })
            ..onMouseLeave.listen((event) {
              permissionEmailHeaders[email].classes.toggle('highlight', false);
            });
          if (resetToDefault != null) {
            cell.append(resetToDefault);
          }
          permissionRow.append(cell);
        });
        tableBody.append(permissionRow);
      }
    }

    tableWrapper.children.clear();
    tableWrapper.append(table);
  }

  @override
  initSignedInView(String displayName, String photoUrl) {
    super.initSignedInView(displayName, photoUrl);
    mainElement
      ..append(headerElement)
      ..append(helperElement)
      ..append(tableWrapper);
  }
}
