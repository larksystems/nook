import 'dart:html';
import 'package:katikati_ui_lib/components/button/button.dart';
import 'package:katikati_ui_lib/components/editable/editable_text.dart';
import 'package:katikati_ui_lib/components/logger.dart';
import 'package:katikati_ui_lib/components/snackbar/snackbar.dart';
import 'package:katikati_ui_lib/datatypes/project.dart';
import 'package:katikati_ui_lib/datatypes/user.dart';
import 'package:nook/app/nook/controller.dart' show BaseAction, SnackbarData;
import 'package:nook/view.dart';

import 'controller.dart';

Logger log = new Logger('view.dart');

class Permission {
  String key;
  String text;
  String type;
  String explanation;

  Permission(this.key, this.text, this.type, {this.explanation});
}

Map<String, List<Permission>> projectAdminPermissionGroups = {
  "Configuring standard messages": [
    Permission("edit_standard_messages_enabled", "Can edit standard messages", "bool"),
  ],
  "Configuring tags": [
    Permission("edit_tags_enabled", "Can edit tags", "bool"),
  ],
  "Messaging": [
    Permission("send_messages_enabled", "Can send messages", "bool"),
    Permission("send_custom_messages_enabled", "Can send custom messages", "bool"),
    Permission("send_multi_message_enabled", "Can select multiple conversations", "bool"),
    Permission("multi_select_exclude_tag_ids", "Tags excluding conversations from multiple selection", "Set<String>"),
  ],
  "Conversations": [
    Permission("tag_messages_enabled", "Can tag messages", "bool"),
    Permission("tag_conversations_enabled", "Can tag conversations", "bool"),
    Permission("suggested_replies_groups_enabled", "Can send groups of standard messages", "bool"),
    Permission("tags_panel_visibility", "Standard messages panel is visible", "bool"),
    Permission("replies_panel_visibility", "Tags panel is visible", "bool"),
    Permission("turnline_panel_visibility", "Turnline panel is visible", "bool"),
    // Permission("tags_keyboard_shortcuts_enabled", "Can use keyboard shortcuts for tagging", "bool"),
    // Permission("replies_keyboard_shortcuts_enabled", "Can use keyboard shortcuts for replying with standard messages", "bool"),

    Permission("edit_translations_enabled", "Can edit messages translation", "bool"),
    Permission("edit_notes_enabled", "Can add conversation notes", "bool"),
    Permission("conversational_turns_enabled", "Can filter conversations by the last turn and exclusion", "bool"),
  ],
  "Access restrictions": [
    Permission("mandatory_include_tag_ids", "Tags of the only conversations the user can access", "Set<String>"),
    Permission("mandatory_exclude_tag_ids", "Tags of the conversations the user can't access", "Set<String>"),
    Permission("sample_messages_enabled", "Can show sample messages associated with tags", "bool"),
  ],
  "User management": [
    Permission("status", "User status", "String"),
  ],
};

Map<String, List<Permission>> superAdminPermissionGroups = {
  ...projectAdminPermissionGroups,
  "Role management": [
    Permission("role", "User role", "String"),
  ],
  "Other": [
    Permission("console_logging_level", "Console logging level", "String"),
  ]
};

List<Permission> permissions = superAdminPermissionGroups.values.fold([], (previousValue, element) => [...previousValue, ...element]);

const VALUE_FROM_DEFAULT_CSS_CLASS = "from-default";

const PROJECT_CONFIG_TITLE_TEXT = "Project configuration";

const USER_CONFIG_TITLE_TEXT = "User configuration";
const USER_CONFIG_HELPER_TEXT = "Default permissions apply to all user accounts unless overridden individually. Faded values are derived from the default.";

class UsersPageView extends PageView {
  DivElement renderElement;
  DivElement wrapperElement;
  DivElement projectConfigWrapper;
  DivElement userConfigTableWrapper;

  // email > permission key > header/checkbox/textbox
  Map<String, Element> permissionEmailHeaders;
  Map<String, Element> permissionNameHeaders;
  Map<String, Map<String, CheckboxInputElement>> permissionToggles;
  Map<String, Map<String, TextInputElement>> permissionTextboxes;
  Map<String, Map<String, SpanElement>> resetToDefaultPermissionsButtons;

  UsersPageView(UsersController controller) : super(controller) {
    permissionEmailHeaders = {};
    permissionNameHeaders = {};
    permissionToggles = {};
    permissionTextboxes = {};
    resetToDefaultPermissionsButtons = {};

    renderElement = DivElement()
      ..className = "project-configuration";

    wrapperElement = DivElement()
      ..className = "project-configuration__inner-wrapper";
    renderElement.append(wrapperElement);
  }

  void displayAccessNotAllowed() {
    wrapperElement.children.clear();

    var headerElement = HeadingElement.h1()
      ..className = "project-configuration__heading"
      ..innerText = "You don't have permissions to access this page";
    wrapperElement.append(headerElement);

    var helperElement = ParagraphElement()
      ..className = "project-configuration__help-text"
      ..innerText = "Please contact your administrator if you have any questions";
    wrapperElement.append(helperElement);
  }

  var pageInited = false;

  void setupAccessAllowed() {
    if (pageInited) return;
    wrapperElement.children.clear();

    var projSectionHeaderElement = HeadingElement.h1()
      ..className = "project-configuration__heading"
      ..innerText = PROJECT_CONFIG_TITLE_TEXT;
    wrapperElement.append(projSectionHeaderElement);

    projectConfigWrapper = DivElement()
      ..className = "project-configuration__grid-wrapper";
    projectConfigWrapper.append(ImageElement(src: '/packages/katikati_ui_lib/components/brand_asset/logos/loading.svg')..className = "load-spinner");
    wrapperElement.append(projectConfigWrapper);

    var userSectionHeaderElement = HeadingElement.h1()
      ..className = "project-configuration__heading"
      ..innerText = USER_CONFIG_TITLE_TEXT;
    wrapperElement.append(userSectionHeaderElement);

    var helperElement = ParagraphElement()
      ..className = "project-configuration__help-text"
      ..innerText = USER_CONFIG_HELPER_TEXT;
    wrapperElement.append(helperElement);

    var showDeactivatedUsersButton = Button(ButtonType.text, buttonText: "Show/hide deactivated users", onClick: (_) {
      controller.command(UsersAction.showOrHideDeactivatedUsers, null);
    });
    wrapperElement.append(showDeactivatedUsersButton.renderElement);

    userConfigTableWrapper = DivElement()
      ..className = "project-configuration__table-wrapper";
    userConfigTableWrapper.append(ImageElement(src: '/packages/katikati_ui_lib/components/brand_asset/logos/loading.svg')..className = "load-spinner");
    wrapperElement.append(userConfigTableWrapper);

    pageInited = true;
  }

  void populatePermissionsTable(UserConfiguration defaultConfig, UserConfiguration currentConfig, Map<String, UserConfiguration> usersConfig) {
    userConfigTableWrapper.children.clear();
    permissionEmailHeaders = {};
    permissionNameHeaders = {};
    permissionToggles = {};
    permissionTextboxes = {};
    resetToDefaultPermissionsButtons = {};

    var allEmails = [defaultConfig.docId, ...usersConfig.keys];

    var table = TableElement();
    // thead, tbody
    var tableHeader = table.createTHead();
    var tableBody = table.createTBody();
    table
      ..append(tableHeader)
      ..append(tableBody);

    // email headers
    var cornerElement = Element.th();

    var wrapper = DivElement()
      ..style.textAlign = 'right';
    cornerElement.append(wrapper);

    SpanElement addNewUserText = SpanElement()..text = 'Add new user';
    Button addNewUserButton;
    TextEdit newUserEmail;
    newUserEmail = TextEdit("", placeholder: "name@email.org")
      ..onEdit = (value) {
        appController.command(UsersAction.addUser, UserData(value.trim()));
        newUserEmail.renderElement.remove();
        wrapper.append(addNewUserText);
        wrapper.append(addNewUserButton.renderElement);
      }
      ..onCancel = () {
        newUserEmail.renderElement.remove();
        wrapper.append(addNewUserText);
        wrapper.append(addNewUserButton.renderElement);
      };
    addNewUserButton = Button(ButtonType.add, onClick: (e) {
      addNewUserText.remove();
      addNewUserButton.remove();
      wrapper.append(newUserEmail.renderElement);
      newUserEmail.beginEdit();
    });
    wrapper.append(addNewUserText);
    wrapper.append(addNewUserButton.renderElement);

    var headerRow = TableRowElement()..append(cornerElement);

    allEmails.forEach((email) {
      var emailHeader = Element.th()..innerText = email;
      emailHeader.classes.toggle('hidden', controller.getValue(email, 'status') == 'UserStatus.deactivated' && !controller.showDeactivatedUsers);
      permissionEmailHeaders[email] = emailHeader;
      headerRow.append(emailHeader);
    });
    tableHeader.append(headerRow);

    var permissionGroups;
    if (currentConfig.role == UserRole.superAdmin) {
      permissionGroups = superAdminPermissionGroups;
    } else if (currentConfig.role == UserRole.projectAdmin) {
      permissionGroups = projectAdminPermissionGroups;
    } else {
      displayAccessNotAllowed();
      throw "User does not have permissions to see the permissions";
    }

    for (var group in permissionGroups.keys) {
      var groupTitle = TableRowElement()
        ..append(Element.td()..className = "group-row"..innerText = group)
        ..append(Element.td()..className = "group-row--empty"..attributes["colspan"] = allEmails.length.toString());
      tableBody.append(groupTitle);
      for (var permission in permissionGroups[group]) {
        var permissionRow = TableRowElement();
        var permissionText = DivElement()..innerText = permission.text;
        var permissionExplanation = SpanElement()..className = "permission-explanation"..innerText = permission.explanation;
        var permissionHeader = Element.th()..append(permissionText)..append(permissionExplanation);
        permissionNameHeaders[permission.key] = permissionHeader;
        permissionRow.append(permissionHeader);

        for (var email in allEmails) {
          var resetButton = Button(ButtonType.reset, hoverText: 'Reset to default', onClick: (_) {
            appController.command(UsersAction.resetToDefaultPermission, ResetToDefaultPermission(email, permission.key));
          });
          SpanElement resetToDefault = resetButton.renderElement;
          resetToDefaultPermissionsButtons[email] = resetToDefaultPermissionsButtons[email] ?? {};
          resetToDefaultPermissionsButtons[email][permission.key] = resetToDefault;
          resetToDefaultPermissionsButtons[email][permission.key].classes.toggle('hidden', !controller.isResettableToDefault(email, permission.key));

          Element renderElement;
          switch (permission.type) {
            case 'bool':
              renderElement = CheckboxInputElement()
                ..checked = (controller.getValue(email, permission.key) ?? false)
                ..onChange.listen((event) {
                  appController.command(UsersAction.updatePermission, UpdatePermission(email, permission.key, (event.target as CheckboxInputElement).checked));
                });
              permissionToggles[email] = permissionToggles[email] ?? {};
              permissionToggles[email][permission.key] = renderElement;
              break;
            case 'String':
              renderElement = TextInputElement()
                ..value = (controller.getValue(email, permission.key) ?? "")
                ..onChange.listen((event) {
                  var value = (event.target as TextInputElement).value.trim();
                  appController.command(UsersAction.updatePermission, UpdatePermission(email, permission.key, value));
                });
              permissionTextboxes[email] = permissionTextboxes[email] ?? {};
              permissionTextboxes[email][permission.key] = renderElement;
              break;
            case 'Set<String>':
              renderElement = TextInputElement()
                ..value = (controller.getValue(email, permission.key) ?? []).toList().join(", ")
                ..onChange.listen((event) {
                  var value = (event.target as TextInputElement).value;
                  var listValue = value.isEmpty ? <String>[] : value.split(',').map((e) => e.trim()).toList();
                  listValue.removeWhere((element) => element == null || element.isEmpty);
                  appController.command(UsersAction.updatePermission, UpdatePermission(email, permission.key, listValue));
                });
              permissionTextboxes[email] = permissionTextboxes[email] ?? {};
              permissionTextboxes[email][permission.key] = renderElement;
              break;
            default:
              renderElement = SpanElement()..innerText = "Unknown data type";
              break;
          }
          renderElement.classes.toggle(VALUE_FROM_DEFAULT_CSS_CLASS, controller.isDerivedFromDefault(email, permission.key));
          controller.isEditable(email, permission.key) ? renderElement.attributes.remove("disabled") : renderElement.attributes["disabled"] = "true";

          var cell = TableCellElement()
            ..append(renderElement)
            ..onMouseEnter.listen((event) {
              permissionEmailHeaders[email].classes.toggle('highlight', true);
            })
            ..onMouseLeave.listen((event) {
              permissionEmailHeaders[email].classes.toggle('highlight', false);
            });
          cell.append(resetToDefault);
          cell.classes.toggle('hidden', controller.getValue(email, 'status') == 'UserStatus.deactivated' && !controller.showDeactivatedUsers);
          permissionRow.append(cell);
        }
        tableBody.append(permissionRow);
      }
    }

    userConfigTableWrapper.children.clear();
    userConfigTableWrapper.append(table);
  }

  void updatePermission(UserConfiguration defaultConfig, UserConfiguration currentConfig, Map<String, UserConfiguration> usersConfig, permissionKey) {
    var email = currentConfig.docId;
    var value = controller.getValue(email, permissionKey);

    if (!permissionToggles[email].containsKey(permissionKey) && !permissionTextboxes[email].containsKey(permissionKey)) return;

    var permission = permissions.singleWhere((element) => element.key == permissionKey, orElse: null);
    if (permission == null) return;

    var renderElement;
    switch (permission.type) {
      case 'bool':
        renderElement = permissionToggles[email][permissionKey];
        renderElement.checked = value ?? false;
        break;

      case 'String':
        renderElement = permissionTextboxes[email][permissionKey];
        renderElement.value = value ?? "";
        break;

      case 'Set<String>':
        renderElement = permissionTextboxes[email][permissionKey];
        renderElement.value = (value ?? []).toList().join(", ");
        break;
    }

    renderElement.classes.toggle(VALUE_FROM_DEFAULT_CSS_CLASS, controller.isDerivedFromDefault(email, permissionKey));
    controller.isEditable(email, permissionKey) ? renderElement.attributes.remove("disabled") : renderElement.attributes["disabled"] = "true";
    resetToDefaultPermissionsButtons[email][permissionKey].classes.toggle('hidden', !controller.isResettableToDefault(email, permissionKey));
    toggleSaved(email, permissionKey, true);
  }

  void toggleSaved(String email, String key, bool saved) {
    permissionEmailHeaders[email].classes.toggle("unsaved", !saved);
    permissionNameHeaders[key]?.classes?.toggle("unsaved", !saved);
  }

  void updateProjectInfo(Project project) {
    projectConfigWrapper.children.clear();

    for (var fieldInfo in projectConfigurationInfo) {
      projectConfigWrapper.append(DivElement()
        ..classes.add('project-config__label')
        ..text = "${fieldInfo.name}:"
        ..title = fieldInfo.description);

      projectConfigWrapper.append(InputElement()
        ..classes.add('project-config__input')
        ..value = fieldInfo.getter(project)
        ..onChange.listen((event) {
          var inputElement = event.target as InputElement;
          try {
            fieldInfo.setter(project, inputElement.value);
          } catch (e) {
            controller.command(BaseAction.showSnackbar, SnackbarData(e.toString(), SnackbarNotificationType.error));
            return;
          }
          inputElement.previousElementSibling.classes.toggle("unsaved", true);
          controller.command(UsersAction.updateProjectInfo, ProjectInfo(project));
        }));
    }
  }

  @override
  initSignedInView(String displayName, String photoUrl) {
    super.initSignedInView(displayName, photoUrl);
    mainElement
      ..append(renderElement);
  }
}
