# Fixtures

Widget directories installed into a probe's config dir with `widget-probe.sh -x`,
the way `~/.config/illogical-impulse/widgets/<id>/` holds a real external widget.

`hello` doubles as the reference external widget. It covers every part of the
contract that only works outside the shell tree:

- `qs.modules.widgets`, `qs.modules.common(.widgets)` and `qs.services` imports
  from an absolute `file://` url;
- a sibling type (`HelloBadge`), which resolves with no import at all;
- a singleton (`HelloState`), which needs the `qmldir` entry next to it - without
  one it still compiles and its properties silently read as empty;
- an option from the manifest schema, read back through `WidgetCatalog.option`.

An external widget cannot import its own directory as a module: nothing in the
shell tree imports it, so `qs.modules.widgets.<id>` is not installed.

Asserted by `tests/cases/external-widget.qml`.
