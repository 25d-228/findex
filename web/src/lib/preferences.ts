import { resolvePreferenceDefaults } from "./preferenceDefaults"

export type Arrangement = "name" | "kind" | "modificationDate" | "none"
export type ViewStyle = "icon" | "list" | "column" | "gallery"

/** Finder icon-view size range, in points — mirrors FindexPreferences.swift. */
export const ICON_SIZE = { min: 16, max: 256, default: 64 } as const

export type Preferences = {
  terminal: string
  editor: string
  iconSize: number
  arrangement: Arrangement
  view: ViewStyle
}

const BROWSER_DEFAULTS: Preferences = {
  terminal: "net.kovidgoyal.kitty",
  editor: "nvim",
  iconSize: ICON_SIZE.default,
  arrangement: "name",
  view: "icon",
}

const STORAGE_KEY = "findex-preferences"

declare global {
  interface Window {
    __FINDEX_PREFS__?: Partial<Preferences>
    __FINDEX_DEFAULTS__?: Preferences
    webkit?: {
      messageHandlers?: {
        findex?: { postMessage: (message: unknown) => void }
      }
    }
  }
}

export const DEFAULTS = resolvePreferenceDefaults(window.__FINDEX_DEFAULTS__, BROWSER_DEFAULTS)

// When embedded in Findex.app, a WKScriptMessageHandler named "findex" is the
// real persistence layer (UserDefaults). In a plain browser, localStorage is.
const bridge = window.webkit?.messageHandlers?.findex
export const isEmbedded = Boolean(bridge)

export function loadPreferences(): Preferences {
  if (window.__FINDEX_PREFS__) {
    return { ...DEFAULTS, ...window.__FINDEX_PREFS__ }
  }
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return DEFAULTS
    return { ...DEFAULTS, ...JSON.parse(raw) }
  } catch {
    return DEFAULTS
  }
}

export function persistPreferences(preferences: Preferences) {
  if (bridge) {
    bridge.postMessage({ type: "save", ...preferences })
    window.__FINDEX_PREFS__ = preferences
  } else {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(preferences))
  }
}
