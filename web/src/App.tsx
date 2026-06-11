import { useEffect, useState, type ReactNode } from "react"
import { toast } from "sonner"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardFooter } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Separator } from "@/components/ui/separator"
import { Slider } from "@/components/ui/slider"
import { Toaster } from "@/components/ui/sonner"

import { Creature } from "@/components/findex/Creature"
import { FinderPreview, type Arrangement, type ViewStyle } from "@/components/findex/FinderPreview"

const ARRANGEMENTS: { value: Arrangement; label: string }[] = [
  { value: "name", label: "Name" },
  { value: "kind", label: "Kind" },
  { value: "modificationDate", label: "Modification date" },
  { value: "none", label: "None" },
]

const TERMINAL_PRESETS = [
  { label: "kitty", id: "net.kovidgoyal.kitty" },
  { label: "iTerm2", id: "com.googlecode.iterm2" },
]

const EDITOR_PRESETS = [
  // "nvim" is not a bundle ID: the app launches nvim inside the terminal.
  { label: "Neovim", id: "nvim" },
  { label: "Zed", id: "dev.zed.Zed" },
]

const VIEWS: { value: ViewStyle; label: string; glyph: ReactNode }[] = [
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

const DEFAULTS = {
  terminal: "net.kovidgoyal.kitty",
  editor: "nvim",
  iconSize: 64,
  arrangement: "name" as Arrangement,
  view: "icon" as ViewStyle,
}

const STORAGE_KEY = "findex-preferences"

type Prefs = typeof DEFAULTS

declare global {
  interface Window {
    __FINDEX_PREFS__?: Partial<Prefs>
    webkit?: {
      messageHandlers?: {
        findex?: { postMessage: (message: unknown) => void }
      }
    }
  }
}

// When embedded in Findex.app, a WKScriptMessageHandler named "findex" is the
// real persistence layer (UserDefaults). In a plain browser, localStorage is.
const bridge = window.webkit?.messageHandlers?.findex
const embedded = Boolean(bridge)

function loadPreferences(): Prefs {
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

function persistPreferences(prefs: Prefs) {
  if (bridge) {
    bridge.postMessage({ type: "save", ...prefs })
    window.__FINDEX_PREFS__ = prefs
  } else {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(prefs))
  }
}

function PresetChips({
  presets,
  current,
  onPick,
}: {
  presets: { label: string; id: string }[]
  current: string
  onPick: (id: string) => void
}) {
  return (
    <div className="flex flex-wrap gap-1.5">
      {presets.map((preset) => {
        const active = preset.id === current
        return (
          <button key={preset.id} type="button" onClick={() => onPick(preset.id)} className="group">
            <Badge
              variant={active ? "default" : "outline"}
              className={
                "rounded-none border-2 border-foreground font-display text-[9px] tracking-wider uppercase transition-none " +
                (active
                  ? "bg-foreground text-card"
                  : "bg-transparent text-foreground group-hover:bg-accent")
              }
            >
              {preset.label}
            </Badge>
          </button>
        )
      })}
    </div>
  )
}

export default function App() {
  const [prefs] = useState(loadPreferences)
  const [terminal, setTerminal] = useState(prefs.terminal)
  const [editor, setEditor] = useState(prefs.editor)
  const [iconSize, setIconSize] = useState(prefs.iconSize)
  const [arrangement, setArrangement] = useState<Arrangement>(prefs.arrangement)
  const [view, setView] = useState<ViewStyle>(prefs.view)
  const [dirty, setDirty] = useState(false)

  useEffect(() => {
    const saved = JSON.stringify(loadPreferences())
    const now = JSON.stringify({ terminal, editor, iconSize, arrangement, view })
    setDirty(saved !== now)
  }, [terminal, editor, iconSize, arrangement, view])

  const save = () => {
    const clamped = Math.min(Math.max(iconSize, 16), 256)
    setIconSize(clamped)
    persistPreferences({ terminal: terminal.trim(), editor: editor.trim(), iconSize: clamped, arrangement, view })
    setDirty(false)
    const viewLabel = VIEWS.find((v) => v.value === view)?.label ?? view
    toast.success("Preferences saved", {
      description: `${viewLabel} view · icon size ${clamped}px`,
    })
  }

  const reset = () => {
    setTerminal(DEFAULTS.terminal)
    setEditor(DEFAULTS.editor)
    setIconSize(DEFAULTS.iconSize)
    setArrangement(DEFAULTS.arrangement)
    setView(DEFAULTS.view)
    toast("Defaults restored", { description: "Nothing is saved until you press Save." })
  }

  const iconOnly = view === "icon"

  const formColumn = (
    <div className="flex flex-col gap-7">
      <header className="reveal" style={{ animationDelay: "60ms" }}>
        <h2 className="font-display text-sm font-bold tracking-wider uppercase">
          Finder toolbar actions
        </h2>
        <p className="mt-1 text-sm text-muted-foreground">
          Where the toolbar button sends folders, and how “Apply View Preset” lays them out.
        </p>
      </header>

      <div className="reveal flex flex-col gap-2.5" style={{ animationDelay: "120ms" }}>
        <Label htmlFor="terminal" className="font-display text-[10px] tracking-widest uppercase">
          Terminal bundle ID
        </Label>
        <Input
          id="terminal"
          value={terminal}
          onChange={(e) => setTerminal(e.target.value)}
          spellCheck={false}
          className="font-mono text-sm"
          placeholder="com.apple.Terminal"
        />
        <PresetChips presets={TERMINAL_PRESETS} current={terminal} onPick={setTerminal} />
      </div>

      <div className="reveal flex flex-col gap-2.5" style={{ animationDelay: "180ms" }}>
        <Label htmlFor="editor" className="font-display text-[10px] tracking-widest uppercase">
          Editor bundle ID
        </Label>
        <Input
          id="editor"
          value={editor}
          onChange={(e) => setEditor(e.target.value)}
          spellCheck={false}
          className="font-mono text-sm"
          placeholder="com.microsoft.VSCode"
        />
        <PresetChips presets={EDITOR_PRESETS} current={editor} onPick={setEditor} />
      </div>

      <Separator className="bg-foreground/20" />

      <div className="reveal flex flex-col gap-2.5" style={{ animationDelay: "220ms" }}>
        <Label className="font-display text-[10px] tracking-widest uppercase">Default view</Label>
        <div className="flex gap-2" role="radiogroup" aria-label="Default view">
          {VIEWS.map((v) => {
            const active = v.value === view
            return (
              <button
                key={v.value}
                type="button"
                role="radio"
                aria-checked={active}
                onClick={() => setView(v.value)}
                className={
                  "flex w-20 flex-col items-center gap-1 border-2 border-foreground py-2.5 font-display text-[9px] tracking-wider uppercase transition-none " +
                  (active
                    ? "bg-foreground text-card pixel-shadow-sm"
                    : "bg-transparent text-foreground hover:bg-accent")
                }
              >
                {v.glyph}
                {v.label}
              </button>
            )
          })}
        </div>
      </div>

      <div
        className={"reveal flex flex-col gap-3 transition-opacity " + (iconOnly ? "" : "pointer-events-none opacity-40")}
        style={{ animationDelay: "240ms" }}
      >
        <div className="flex items-baseline justify-between">
          <Label htmlFor="icon-size" className="font-display text-[10px] tracking-widest uppercase">
            Icon size
          </Label>
          <output className="font-mono text-sm">
            {iconSize}<span className="text-muted-foreground"> px</span>
          </output>
        </div>
        <Slider
          id="icon-size"
          className="pixel-slider"
          min={16}
          max={256}
          step={2}
          value={[iconSize]}
          onValueChange={([v]) => setIconSize(v)}
          disabled={!iconOnly}
          aria-label="Icon size"
        />
        <div className="flex justify-between font-mono text-[10px] text-muted-foreground">
          <span>16</span>
          <span>256</span>
        </div>
      </div>

      <div
        className={"reveal flex flex-col gap-2.5 transition-opacity " + (iconOnly ? "" : "pointer-events-none opacity-40")}
        style={{ animationDelay: "300ms" }}
      >
        <Label htmlFor="arrangement" className="font-display text-[10px] tracking-widest uppercase">
          Arrange by
        </Label>
        <Select value={arrangement} onValueChange={(v) => setArrangement(v as Arrangement)} disabled={!iconOnly}>
          <SelectTrigger id="arrangement" className="w-56">
            <SelectValue />
          </SelectTrigger>
          <SelectContent className="rounded-none">
            {ARRANGEMENTS.map((a) => (
              <SelectItem key={a.value} value={a.value} className="rounded-none">
                {a.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        {!iconOnly && (
          <p className="font-mono text-[10px] text-muted-foreground">
            Icon size and arrangement apply to grid view only.
          </p>
        )}
      </div>
    </div>
  )

  const previewColumn = (
    <aside className="reveal flex flex-col gap-3 self-start" style={{ animationDelay: "200ms" }}>
      <h3 className="font-display text-[10px] tracking-widest uppercase text-muted-foreground">
        View preset preview
      </h3>
      <FinderPreview iconSize={iconSize} arrangement={arrangement} view={view} />
    </aside>
  )

  const resetButton = (
    <Button
      variant="ghost"
      onClick={reset}
      className="rounded-none font-display text-[10px] tracking-widest uppercase hover:bg-accent hover:text-foreground"
    >
      Reset defaults
    </Button>
  )

  const saveButton = (
    <Button
      onClick={save}
      disabled={!dirty}
      className="rounded-none border-2 border-foreground px-7 font-display text-[11px] font-bold tracking-widest uppercase pixel-shadow-sm transition-none hover:bg-foreground hover:translate-x-[-1px] hover:translate-y-[-1px] hover:shadow-[4px_4px_0_0_var(--pink)] active:translate-x-[2px] active:translate-y-[2px] active:shadow-none disabled:opacity-40 disabled:shadow-none"
    >
      Save
    </Button>
  )

  if (embedded) {
    // Inside Findex.app the native window provides the chrome; render the
    // content directly on the paper background.
    return (
      <main className="flex min-h-svh justify-center px-8 py-10">
        <Toaster position="bottom-center" />
        <div className="relative w-full max-w-4xl">
          <Creature size={48} className="drift absolute -top-3 right-0" />
          <div className="grid gap-10 md:grid-cols-[1fr_280px]">
            {formColumn}
            {previewColumn}
          </div>
          <Separator className="mt-9 mb-4 bg-foreground/20" />
          <div className="flex items-center justify-between pb-2">
            {resetButton}
            {saveButton}
          </div>
        </div>
      </main>
    )
  }

  return (
    <main className="flex min-h-svh items-center justify-center px-4 py-12">
      <Toaster position="bottom-center" />

      <div className="relative w-full max-w-4xl">
        {/* mascot peeking from behind the window */}
        <Creature size={60} className="drift absolute -top-[40px] right-12 z-0" />

        {/* window */}
        <Card className="reveal relative z-10 gap-0 rounded-none border-2 border-foreground p-0 pixel-shadow">
          {/* title bar */}
          <div className="flex items-center gap-2.5 border-b-2 border-foreground bg-secondary px-4 py-3">
            <span className="size-3.5 rounded-none border-2 border-foreground bg-accent" aria-hidden="true" />
            <span className="size-3.5 rounded-none border-2 border-foreground bg-card" aria-hidden="true" />
            <span className="size-3.5 rounded-none border-2 border-foreground bg-foreground" aria-hidden="true" />
            <h1 className="font-display mx-auto pr-16 text-xs font-bold tracking-[0.2em] uppercase">
              Findex Preferences
            </h1>
          </div>

          <CardContent className="grid gap-10 p-7 md:grid-cols-[1fr_280px]">
            {formColumn}
            {previewColumn}
          </CardContent>

          <CardFooter className="flex items-center justify-between border-t-2 border-foreground bg-secondary px-7 py-4">
            {resetButton}
            {saveButton}
          </CardFooter>
        </Card>

        <p className="reveal mt-5 text-center font-display text-[9px] tracking-[0.3em] uppercase text-muted-foreground" style={{ animationDelay: "380ms" }}>
          Findex · Finder companion · v0.1.0
        </p>
      </div>
    </main>
  )
}
