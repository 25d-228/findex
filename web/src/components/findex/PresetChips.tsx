import { Badge } from "@/components/ui/badge"

type Preset = { label: string; id: string }

export function PresetChips({
  presets,
  current,
  onPick,
}: {
  presets: Preset[]
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
