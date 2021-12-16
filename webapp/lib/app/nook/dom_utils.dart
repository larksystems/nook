import 'dart:html';

const IGNORE_ON_ELEMENTS = ["INPUT", "TEXTAREA", "SELECT", "BUTTON", "A"];

List<Element> getAncestors(Element element) {
  List<Element> ancestors = [element];
  while (element != null) {
    ancestors.add(element);
    element = element.parent;
  }
  return ancestors;
}

// https://stackoverflow.com/questions/28062737/javascript-keydown-shortcut-function-but-ignore-if-in-text-box
bool ignoreShortcut(KeyboardEvent event) {
  var target = (event.target as HtmlElement);
  var targetType = target.tagName;
  var isCheckbox = targetType == "INPUT" && target.getAttribute('type') == "checkbox";

  if (isCheckbox) { // allow holding shift key for multiselect
    return false;
  }

  if (IGNORE_ON_ELEMENTS.contains(targetType)) {
    return true;
  }

  if (target.contentEditable == "true") {
    return true;
  }

  return false;
}
