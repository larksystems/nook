part of controller;

var navLinks = [
  Link("Dashboard", "/dashboard.html"),
  Link("Conversations", "/converse/index.html"),
  Link("Messages", "/configure/messages.html"),
  Link("Tags", "/configure/tags.html"),
  Link("Explore", "/explore"),
];

List<Link> generateProjectLinks(String project) => navLinks.map((e) => Link(e.label, "${e.url}?project=${project}")).toList();
