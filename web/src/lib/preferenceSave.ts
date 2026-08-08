import type { Preferences } from "./preferences"

type IconSizeBounds = {
  readonly min: number
  readonly max: number
}

export function normalizePreferencesForSave(
  preferences: Preferences,
  iconSizeBounds: IconSizeBounds,
): Preferences | null {
  const terminal = preferences.terminal.trim()
  const editor = preferences.editor.trim()
  if (!terminal || !editor) return null

  return {
    ...preferences,
    terminal,
    editor,
    iconSize: Math.min(Math.max(preferences.iconSize, iconSizeBounds.min), iconSizeBounds.max),
  }
}
