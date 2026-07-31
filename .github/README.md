A personal fork of [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)
(*illogical-impulse*, Quickshell config `ii`). Everything upstream still applies:
same installer, same keybinds, same [wiki](https://ii.clsty.link/en/ii-qs/01setup/).
For upstream's own feature list and screenshots, see
[its README](https://github.com/end-4/dots-hyprland/blob/main/.github/README.md).

What the fork tries to add is an extension system for these dots: each widget lives
in its own folder, gets discovered automatically, and is picked per machine on a
settings page. Work in progress, expect rough edges.

## Branches

| Branch | What it is |
| --- | --- |
| `extensions` | Default. Upstream plus the widget catalog. |
| `main` | Untouched mirror of `end-4/main`, kept only to merge from. |

## Widgets

All widgets ship disabled. The settings app has a Widgets page that lists them with
their options; widgets with missing dependencies say so instead of turning into dead
buttons. Picks are saved to `~/.config/illogical-impulse/widgets.json`, which nothing
else touches.

The same page can point widget failures at an ntfy topic, a webhook or a command. It
sends the error plus the last 100 log lines, so nothing goes out until you fill in a
target, and it asks first.

<details open>
  <summary>In the catalog</summary>

  - **GPU monitor**: usage circle next to CPU/RAM, popup columns for load, VRAM and
    temperature.
  - **Peripheral battery**: mice, keyboards, headsets and other bluetooth things, in
    the bar and a right-sidebar tab.
  - **Android webcam**: indicator for a phone attached as a USB webcam.
  - **Presence**: a room of friends - who's online, what they're playing, shared
    photos. Client for statusphere; hidden without the cli.
</details>

<details>
  <summary>Not widgets, just patches</summary>

  - Lock screen: opaque surface with its own blurred wallpaper, no window flash on
    resume; fingerprint re-arms after an unrecognized read.
  - Even spacing around the bar media and clock modules.
  - Screenshot annotation defaults to `satty`.
</details>

A widget is one folder under `dots/.config/quickshell/ii/modules/widgets/<id>/` with
a `Manifest.qml`; no shared files to edit. The contract is written down in
`modules/widgets/WidgetManifest.qml`.

## Install

```sh
git clone -b extensions https://github.com/Berupor/dots-hyprland.git
cd dots-hyprland
```

From scratch, upstream's installer takes it from here (packages, services, every
config - it's a long one):

```sh
./setup install
```

Already running *illogical-impulse*? Only the shell config differs, so keep the old
one around and swap the tree:

```sh
cp -a ~/.config/quickshell/ii ~/.config/quickshell/ii.upstream
rsync -a --delete dots/.config/quickshell/ii/ ~/.config/quickshell/ii/
```

`Ctrl+Super+R` restarts the shell, then pick widgets in the settings app. `--delete`
leaves exactly the fork's tree behind, local edits under `ii/` included - hence the
copy. Nothing outside `ii/` changes and no extra packages are needed: widgets ship
disabled, and `satty` is the only new default (screenshot annotation, switch it off in
settings if you don't have it).

`./setup install-files` sits in between: all the config files, no packages. Take that
one instead of the rsync if your dots predate this branch's merge base, 2026-07-27,
since the shell alone would end up newer than everything around it:

```sh
git -C /path/to/your/dots-hyprland log -1 --date=short --format='%ad %s'
```

Clashing files go to `~/ii-original-dots-backup`.

## The way back

```sh
rm -rf ~/.config/quickshell/ii
mv ~/.config/quickshell/ii.upstream ~/.config/quickshell/ii
```

Kept no copy? The same clone carries the untouched upstream shell:

```sh
git checkout main
rsync -a --delete dots/.config/quickshell/ii/ ~/.config/quickshell/ii/
```

Either way, `rm ~/.config/illogical-impulse/widgets.json` forgets the widget picks.
Your `config.json` survives both directions - upstream skips the keys it doesn't know.

## Pulling upstream

```sh
git fetch upstream
git merge upstream/main
```

Merge, not rebase: pushes stay fast-forward so clones on other machines never break.

## Thanks

All of the above sits on [@end-4](https://github.com/end-4)'s work, and on everyone
credited in the upstream README. Licensed the same way, see [LICENSE](../LICENSE).
