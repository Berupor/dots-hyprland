A personal fork of [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)
(*illogical-impulse*, Quickshell config `ii`). Everything upstream still applies:
same installer, same keybinds, same [wiki](https://ii.clsty.link/en/ii-qs/01setup/).
For upstream's own feature list and screenshots, see
[its README](https://github.com/end-4/dots-hyprland/blob/main/.github/README.md).

## Branches

| Branch | What it is |
| --- | --- |
| `berupor` | Default. Upstream plus the changes below. |
| `main` | Untouched mirror of `end-4/main`, kept only to merge from. |

## On top of upstream

<details open>
  <summary>Bar</summary>

  - **Resources**: GPU circle next to CPU/RAM, popup columns for GPU and for CPU
    iowait/temperature. Per-indicator toggles and thresholds in settings.
  - Even spacing around the media and clock modules; center-side modules grow when
    the content doesn't fit.
</details>

<details open>
  <summary>Peripheral battery</summary>

  - Mice, keyboards, headsets, other Bluetooth things, in a right-sidebar panel.
</details>

<details open>
  <summary>Lock screen</summary>

  - Opaque surface with its own blurred wallpaper, no window flash on resume.
  - Fingerprint re-arms after an unrecognized read.
</details>

<details open>
  <summary>Misc</summary>

  - Screenshot annotation defaults to `satty`.
</details>

Every widget is a flag in `modules/common/Config.qml` with a switch in the settings
app, like the upstream ones. Widgets with external dependencies stay hidden when the
dependency is missing, so nothing turns into a dead button.

## Install

A clone lands on `berupor`:

```sh
git clone https://github.com/Berupor/dots-hyprland.git
cd dots-hyprland
```

From scratch, upstream's installer takes it from here (packages, services, every
config - it's a long one):

```sh
./setup install
```

Already running *illogical-impulse* and only after the shell config:

```sh
cp -r dots/.config/quickshell/ii ~/.config/quickshell/
```

`./setup install-files` sits in between: all the config files, no packages.

## Pulling upstream

```sh
git fetch upstream
git merge upstream/main
```

Merge, not rebase: pushes stay fast-forward so clones on other machines never break.

## Thanks

All of the above sits on [@end-4](https://github.com/end-4)'s work, and on everyone
credited in the upstream README. Licensed the same way, see [LICENSE](../LICENSE).
