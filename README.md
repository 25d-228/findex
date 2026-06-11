# Findex

A small macOS Finder companion with a pixel heart.

Findex adds a **toolbar button** and **right-click menu** to Finder:

- Copy file / folder paths
- Open the current folder in your terminal (kitty, iTerm2, …)
- Open the current folder in your editor (Zed, or `nvim` inside kitty)
- Apply a view preset: grid, list, columns, or gallery

A menu bar item mirrors the same actions. Preferences live in a small
embedded web app (React + shadcn/ui, pixel-styled).

## Build & install

Requirements: macOS 13+, Xcode command line tools, Node 20+.

```sh
cd web && npm install && npm run build && cd ..
scripts/install-local.sh
```

If the toolbar button does not appear: enable **Findex Finder Extension**
in System Settings → General → Login Items & Extensions → File Providers,
then relaunch Finder (`killall Finder`).

## Development

- `Sources/` — Swift app + Finder Sync extension, built directly with
  `swiftc` (no Xcode project): `scripts/build-local.sh`
- `web/` — preferences UI: `npm run dev` for the browser version
- `scripts/package-release.sh <version>` — unsigned release zip
