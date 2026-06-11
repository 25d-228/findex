/**
 * The Findex pixel creature, lifted rect-for-rect from Resources/App/FindexIcon.svg.
 * Eyes carry the `creature-eye` class so CSS can blink them.
 */
export function Creature({ size = 56, className }: { size?: number; className?: string }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 120 120"
      shapeRendering="crispEdges"
      aria-hidden="true"
      className={className}
    >
      <rect x="0" y="0" width="30" height="30" fill="#1A1A1A" />
      <rect x="90" y="0" width="30" height="30" fill="#1A1A1A" />
      <rect x="15" y="15" width="15" height="15" fill="#F5A5B8" />
      <rect x="90" y="15" width="15" height="15" fill="#F5A5B8" />
      <rect x="0" y="30" width="120" height="30" fill="#1A1A1A" />
      <rect className="creature-eye" x="30" y="45" width="15" height="15" fill="#FFFFFF" />
      <rect className="creature-eye" x="75" y="45" width="15" height="15" fill="#FFFFFF" />
      <rect x="0" y="60" width="120" height="30" fill="#FFFFFF" />
      <rect x="0" y="60" width="15" height="15" fill="#1A1A1A" />
      <rect x="105" y="60" width="15" height="15" fill="#1A1A1A" />
      <rect x="30" y="60" width="15" height="15" fill="#0A0A0A" />
      <rect x="75" y="60" width="15" height="15" fill="#0A0A0A" />
      <rect x="30" y="90" width="60" height="30" fill="#FFFFFF" />
      <rect x="15" y="90" width="15" height="15" fill="#1A1A1A" />
      <rect x="90" y="90" width="15" height="15" fill="#1A1A1A" />
      <rect x="52" y="96" width="16" height="10" fill="#0A0A0A" />
    </svg>
  )
}
