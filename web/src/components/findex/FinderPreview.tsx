import { useMemo } from "react"

export type Arrangement = "name" | "kind" | "modificationDate" | "none"
export type ViewStyle = "icon" | "list" | "column" | "gallery"

type Item = {
  name: string
  kind: "folder" | "image" | "movie" | "text" | "audio"
  modified: number // epoch days, newest = largest
  date: string
}

// Deliberately unsorted, so "None" looks lived-in.
const ITEMS: Item[] = [
  { name: "tape.mp3", kind: "audio", modified: 9, date: "Jan 9" },
  { name: "art", kind: "folder", modified: 122, date: "May 2" },
  { name: "demo.mov", kind: "movie", modified: 161, date: "Jun 10" },
  { name: "music", kind: "folder", modified: 77, date: "Mar 18" },
  { name: "notes.txt", kind: "text", modified: 162, date: "Jun 11" },
  { name: "icon.svg", kind: "image", modified: 112, date: "Apr 22" },
  { name: "zines", kind: "folder", modified: 152, date: "Jun 1" },
  { name: "scan.png", kind: "image", modified: 45, date: "Feb 14" },
]

const KIND_ORDER: Record<Item["kind"], number> = {
  folder: 0,
  image: 1,
  movie: 2,
  audio: 3,
  text: 4,
}

function FolderGlyph({ px }: { px: number }) {
  return (
    <svg width={px} height={px} viewBox="0 0 18 18" shapeRendering="crispEdges" aria-hidden="true">
      <path d="M2 15.5 V5 H8 L9.8 7 H16 V15.5 Z" fill="#3D3D3D" />
      <rect x="5" y="9" width="2" height="2" fill="#F5E6D8" />
      <rect x="11" y="9" width="2" height="2" fill="#F5E6D8" />
      <rect x="7" y="12.5" width="4" height="1.5" fill="#F5A5B8" />
    </svg>
  )
}

function FileGlyph({ px, kind }: { px: number; kind: Item["kind"] }) {
  const inkBar =
    kind === "image" ? (
      <rect x="6" y="9" width="6" height="4" fill="#F5A5B8" />
    ) : kind === "movie" ? (
      <path d="M7.5 8.5 L11.5 10.75 L7.5 13 Z" fill="#1A1A1A" />
    ) : kind === "audio" ? (
      <>
        <rect x="6" y="9" width="1.5" height="4" fill="#1A1A1A" />
        <rect x="8.5" y="7.5" width="1.5" height="5.5" fill="#1A1A1A" />
        <rect x="11" y="10" width="1.5" height="3" fill="#1A1A1A" />
      </>
    ) : (
      <>
        <rect x="6" y="8.5" width="6" height="1.2" fill="#1A1A1A" />
        <rect x="6" y="10.5" width="6" height="1.2" fill="#1A1A1A" />
        <rect x="6" y="12.5" width="4" height="1.2" fill="#1A1A1A" />
      </>
    )
  return (
    <svg width={px} height={px} viewBox="0 0 18 18" shapeRendering="crispEdges" aria-hidden="true">
      <path d="M4 16.5 V1.5 H11 L14 4.5 V16.5 Z" fill="#FFFDF9" stroke="#1A1A1A" strokeWidth="1.4" />
      <path d="M11 1.5 V4.5 H14" fill="none" stroke="#1A1A1A" strokeWidth="1.4" />
      {inkBar}
    </svg>
  )
}

function Glyph({ item, px }: { item: Item; px: number }) {
  return item.kind === "folder" ? <FolderGlyph px={px} /> : <FileGlyph px={px} kind={item.kind} />
}

function sortItems(arrangement: Arrangement): Item[] {
  const sorted = [...ITEMS]
  switch (arrangement) {
    case "name":
      sorted.sort((a, b) => a.name.localeCompare(b.name))
      break
    case "kind":
      sorted.sort((a, b) => KIND_ORDER[a.kind] - KIND_ORDER[b.kind] || a.name.localeCompare(b.name))
      break
    case "modificationDate":
      sorted.sort((a, b) => b.modified - a.modified)
      break
    case "none":
      break
  }
  return sorted
}

function IconGrid({ items, px }: { items: Item[]; px: number }) {
  return (
    <div className="grid h-full grid-cols-4 content-start gap-x-2 gap-y-4 p-4">
      {items.map((item) => (
        <figure key={item.name} className="flex min-w-0 flex-col items-center gap-1">
          <span
            className="flex items-end justify-center transition-all duration-200 ease-out"
            style={{ width: px, height: px }}
          >
            <Glyph item={item} px={px} />
          </span>
          <figcaption className="max-w-full truncate font-mono text-[9px] text-muted-foreground">
            {item.name}
          </figcaption>
        </figure>
      ))}
    </div>
  )
}

function ListRows({ items }: { items: Item[] }) {
  return (
    <div className="flex h-full flex-col p-2">
      <div className="flex items-center gap-2 border-b-2 border-foreground/20 px-2 pb-1 font-display text-[8px] tracking-widest uppercase text-muted-foreground">
        <span className="flex-1">Name</span>
        <span>Modified</span>
      </div>
      {items.map((item, i) => (
        <div
          key={item.name}
          className={"flex items-center gap-2 px-2 py-1 " + (i % 2 === 1 ? "bg-secondary/40" : "")}
        >
          <Glyph item={item} px={13} />
          <span className="flex-1 truncate font-mono text-[9px]">{item.name}</span>
          <span className="font-mono text-[9px] text-muted-foreground">{item.date}</span>
        </div>
      ))}
    </div>
  )
}

function Columns({ items }: { items: Item[] }) {
  const selected = items.find((i) => i.kind === "folder") ?? items[0]
  const children = items.filter((i) => i.name !== selected.name).slice(0, 4)
  return (
    <div className="grid h-full grid-cols-[1fr_1fr_1.2fr]">
      <div className="flex flex-col gap-0.5 border-r-2 border-foreground/20 p-1.5">
        {items.slice(0, 6).map((item) => (
          <div
            key={item.name}
            className={
              "flex items-center gap-1.5 px-1.5 py-0.5 " +
              (item.name === selected.name ? "bg-accent" : "")
            }
          >
            <Glyph item={item} px={11} />
            <span className="flex-1 truncate font-mono text-[8px]">{item.name}</span>
            {item.kind === "folder" && <span className="font-mono text-[8px]">›</span>}
          </div>
        ))}
      </div>
      <div className="flex flex-col gap-0.5 border-r-2 border-foreground/20 p-1.5">
        {children.map((item) => (
          <div key={item.name} className="flex items-center gap-1.5 px-1.5 py-0.5">
            <Glyph item={item} px={11} />
            <span className="flex-1 truncate font-mono text-[8px]">{item.name}</span>
          </div>
        ))}
      </div>
      <div className="flex flex-col items-center justify-center gap-2 p-2">
        <Glyph item={selected} px={42} />
        <span className="font-mono text-[9px]">{selected.name}</span>
        <span className="font-mono text-[8px] text-muted-foreground">{selected.date}</span>
      </div>
    </div>
  )
}

function Gallery({ items }: { items: Item[] }) {
  const featured = items[0]
  return (
    <div className="flex h-full flex-col">
      <div className="flex flex-1 flex-col items-center justify-center gap-2">
        <Glyph item={featured} px={64} />
        <span className="font-mono text-[10px]">{featured.name}</span>
      </div>
      <div className="flex items-center justify-center gap-2 border-t-2 border-foreground/20 px-2 py-2">
        {items.slice(0, 7).map((item, i) => (
          <span
            key={item.name}
            className={"flex size-7 items-center justify-center " + (i === 0 ? "border-2 border-accent" : "")}
          >
            <Glyph item={item} px={20} />
          </span>
        ))}
      </div>
    </div>
  )
}

export function FinderPreview({
  iconSize,
  arrangement,
  view,
}: {
  iconSize: number
  arrangement: Arrangement
  view: ViewStyle
}) {
  // Map the real 16–256 pt range onto a 14–58 px miniature.
  const px = Math.round(14 + ((iconSize - 16) / 240) * 44)
  const items = useMemo(() => sortItems(arrangement), [arrangement])

  return (
    <div className="rounded-none border-2 border-foreground bg-card pixel-shadow">
      {/* mini title bar */}
      <div className="flex items-center gap-2 border-b-2 border-foreground bg-secondary px-3 py-2">
        <span className="size-2.5 border-2 border-foreground bg-accent" aria-hidden="true" />
        <span className="size-2.5 border-2 border-foreground bg-card" aria-hidden="true" />
        <span className="size-2.5 border-2 border-foreground bg-foreground" aria-hidden="true" />
        <span className="font-display ml-2 text-[10px] tracking-widest uppercase">Downloads</span>
        <svg
          width="14"
          height="14"
          viewBox="0 0 18 18"
          shapeRendering="crispEdges"
          className="ml-auto"
          aria-hidden="true"
        >
          <path d="M2 15.5 V5 H8 L9.8 7 H16 V15.5 Z" fill="#1A1A1A" />
          <rect x="5" y="9" width="2" height="2" fill="#F5E6D8" />
          <rect x="11" y="9" width="2" height="2" fill="#F5E6D8" />
          <rect x="7" y="12.5" width="4" height="1.5" fill="#F5E6D8" />
        </svg>
      </div>

      {/* content area */}
      <div className="h-64 overflow-hidden bg-[#fffdf9]">
        {view === "icon" && <IconGrid items={items} px={px} />}
        {view === "list" && <ListRows items={items} />}
        {view === "column" && <Columns items={items} />}
        {view === "gallery" && <Gallery items={items} />}
      </div>

      <div className="flex items-center justify-between border-t-2 border-foreground bg-secondary px-3 py-1.5">
        <span className="font-display text-[9px] tracking-widest uppercase">8 items</span>
        <span className="font-mono text-[9px] text-muted-foreground">
          {view === "icon" ? `icon ${iconSize}px` : `${view} view`}
        </span>
      </div>
    </div>
  )
}
