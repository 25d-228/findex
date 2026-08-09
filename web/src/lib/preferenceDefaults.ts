import type { Preferences } from "./preferences"

export function resolvePreferenceDefaults(
  injectedDefaults: Preferences | undefined,
  browserFallback: Preferences,
): Preferences {
  return injectedDefaults ?? browserFallback
}
