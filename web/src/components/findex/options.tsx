import type { ReactNode } from "react"

import type { Arrangement, ViewStyle } from "@/lib/preferences"

export const ARRANGEMENTS: { value: Arrangement; label: string }[] = [
  { value: "name", label: "Name" },
  { value: "kind", label: "Kind" },
  { value: "modificationDate", label: "Modification date" },
  { value: "none", label: "None" },
]

export const TERMINAL_PRESETS = [
  { label: "kitty", id: "net.kovidgoyal.kitty" },
  { label: "iTerm2", id: "com.googlecode.iterm2" },
]

export const EDITOR_PRESETS = [
  // "nvim" is not a bundle ID: the app launches nvim inside the terminal.
  { label: "Neovim", id: "nvim" },
  { label: "Zed", id: "dev.zed.Zed" },
]

export const VIEWS: { value: ViewStyle; label: string; glyph: ReactNode }[] = [
  {
    value: "icon",
    label: "Grid",
    glyph: (
      <svg width="16" height="16" viewBox="0 0 16 16" shapeRendering="crispEdges" aria-hidden="true">
        <rect x="2.5" y="2.5" width="4.5" height="4.5" fill="currentColor" />
        <rect x="9" y="2.5" width="4.5" height="4.5" fill="currentColor" />
        <rect x="2.5" y="9" width="4.5" height="4.5" fill="currentColor" />
        <rect x="9" y="9" width="4.5" height="4.5" fill="currentColor" />
      </svg>
    ),
  },
  {
    value: "list",
    label: "List",
    glyph: (
      <svg width="16" height="16" viewBox="0 0 16 16" shapeRendering="crispEdges" aria-hidden="true">
        <rect x="2.5" y="3" width="2" height="2" fill="currentColor" />
        <rect x="6" y="3" width="7.5" height="2" fill="currentColor" />
        <rect x="2.5" y="7" width="2" height="2" fill="currentColor" />
        <rect x="6" y="7" width="7.5" height="2" fill="currentColor" />
        <rect x="2.5" y="11" width="2" height="2" fill="currentColor" />
        <rect x="6" y="11" width="7.5" height="2" fill="currentColor" />
      </svg>
    ),
  },
  {
    value: "column",
    label: "Columns",
    glyph: (
      <svg width="16" height="16" viewBox="0 0 16 16" shapeRendering="crispEdges" aria-hidden="true">
        <rect x="2" y="3" width="3.2" height="10" fill="currentColor" />
        <rect x="6.4" y="3" width="3.2" height="10" fill="currentColor" />
        <rect x="10.8" y="3" width="3.2" height="10" fill="currentColor" />
      </svg>
    ),
  },
  {
    value: "gallery",
    label: "Gallery",
    glyph: (
      <svg width="16" height="16" viewBox="0 0 16 16" shapeRendering="crispEdges" aria-hidden="true">
        <rect x="3" y="2.5" width="10" height="7" fill="currentColor" />
        <rect x="3" y="11.5" width="2.5" height="2.5" fill="currentColor" />
        <rect x="6.75" y="11.5" width="2.5" height="2.5" fill="currentColor" />
        <rect x="10.5" y="11.5" width="2.5" height="2.5" fill="currentColor" />
      </svg>
    ),
  },
]
