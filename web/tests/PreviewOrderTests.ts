import type { Arrangement, ViewStyle } from "../src/lib/preferences"
import { orderPreviewItems, type PreviewOrderItem } from "../src/lib/previewOrder"

const items: PreviewOrderItem[] = [
  { name: "tape.mp3", kind: "audio", modified: 9 },
  { name: "art", kind: "folder", modified: 122 },
  { name: "demo.mov", kind: "movie", modified: 161 },
  { name: "music", kind: "folder", modified: 77 },
  { name: "notes.txt", kind: "text", modified: 162 },
  { name: "icon.svg", kind: "image", modified: 112 },
]

assertNames(orderPreviewItems(items, "name", "icon"), [
  "art",
  "demo.mov",
  "icon.svg",
  "music",
  "notes.txt",
  "tape.mp3",
])
assertNames(orderPreviewItems(items, "kind", "icon"), [
  "art",
  "music",
  "icon.svg",
  "demo.mov",
  "tape.mp3",
  "notes.txt",
])
assertNames(orderPreviewItems(items, "modificationDate", "icon"), [
  "notes.txt",
  "demo.mov",
  "art",
  "icon.svg",
  "music",
  "tape.mp3",
])
assertNames(orderPreviewItems(items, "none", "icon"), items.map((item) => item.name))

const arrangements: Arrangement[] = ["name", "kind", "modificationDate", "none"]
const nonGridViews: ViewStyle[] = ["list", "column", "gallery"]
const baseline = items.map((item) => item.name)
for (const view of nonGridViews) {
  for (const arrangement of arrangements) {
    assertNames(orderPreviewItems(items, arrangement, view), baseline)
  }
}

console.log("PreviewOrderTests passed")

function assertNames(actual: PreviewOrderItem[], expected: string[]) {
  const names = actual.map((item) => item.name)
  if (JSON.stringify(names) !== JSON.stringify(expected)) {
    throw new Error(`Expected ${JSON.stringify(expected)}, received ${JSON.stringify(names)}`)
  }
}
