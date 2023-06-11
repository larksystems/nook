part of controller;

var navLinks = [
  Link("Dashboard", "/dashboard.html?"),
  Link("Conversations", "/converse/index.html?include-filter=tag-8f057277&exclude-filter=tag-4420fbea+tag-373762c3"),
  Link("Messages", "/configure/messages.html?"),
  Link("Tags", "/configure/tags.html?"),
  Link("Explore", "/explore?"),
];

List<Link> generateProjectLinks(String project) => navLinks.map((e) => Link(e.label, "${e.url}&project=${project}")).toList();
