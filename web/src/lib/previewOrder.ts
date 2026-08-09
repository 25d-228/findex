import type { Arrangement, ViewStyle } from "./preferences"

export type PreviewOrderItem = {
  name: string
  kind: "folder" | "image" | "movie" | "text" | "audio"
  modified: number
}

const KIND_ORDER: Record<PreviewOrderItem["kind"], number> = {
  folder: 0,
  image: 1,
  movie: 2,
  audio: 3,
  text: 4,
}

export function orderPreviewItems<T extends PreviewOrderItem>(
  items: readonly T[],
  arrangement: Arrangement,
  view: ViewStyle,
): T[] {
  const ordered = [...items]
  if (view !== "icon") return ordered

  switch (arrangement) {
    case "name":
      ordered.sort((a, b) => a.name.localeCompare(b.name))
      break
    case "kind":
      ordered.sort((a, b) => KIND_ORDER[a.kind] - KIND_ORDER[b.kind] || a.name.localeCompare(b.name))
      break
    case "modificationDate":
      ordered.sort((a, b) => b.modified - a.modified)
      break
    case "none":
      break
  }

  return ordered
}
