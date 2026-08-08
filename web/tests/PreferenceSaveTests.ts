import type { Preferences } from "../src/lib/preferences"
import { normalizePreferencesForSave } from "../src/lib/preferenceSave"

const bounds = { min: 16, max: 256 }
const candidate: Preferences = {
  terminal: "  com.apple.Terminal  ",
  editor: "\tnvim\n",
  iconSize: 512,
  arrangement: "kind",
  view: "list",
}

assertEqual(
  normalizePreferencesForSave(candidate, bounds),
  {
    terminal: "com.apple.Terminal",
    editor: "nvim",
    iconSize: 256,
    arrangement: "kind",
    view: "list",
  },
  "normalizes a complete preference value",
)
assertEqual(candidate.terminal, "  com.apple.Terminal  ", "does not mutate its input")
assertEqual(
  normalizePreferencesForSave({ ...candidate, iconSize: 0 }, bounds)?.iconSize,
  16,
  "clamps icon size to the lower bound",
)
assertEqual(
  normalizePreferencesForSave({ ...candidate, terminal: " \n " }, bounds),
  null,
  "rejects a blank terminal identifier",
)
assertEqual(
  normalizePreferencesForSave({ ...candidate, editor: "\t" }, bounds),
  null,
  "rejects a blank editor identifier",
)

console.log("PreferenceSaveTests passed")

function assertEqual(actual: unknown, expected: unknown, message: string) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`${message}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`)
  }
}
