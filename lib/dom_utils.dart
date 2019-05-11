import 'dart:html';

List<Element> getAncestors(Element element) {
  List<Element> ancestors = [element];
  while (element != null) {
    ancestors.add(element);
    element = element.parent;
  }
  return ancestors;
}
