export function PlayerStats() {
  return (
    <div className="flex items-center gap-1.5 px-3 pb-2">
      <StatChip icon="⚡" value="20" label="XP" color="#F5C842" />
      <StatChip icon="❤️" value="344" color="#E74C4C" />
      <StatChip icon="⭐" value="25,477" color="#F5A623" />
      <RankBadge />
    </div>
  );
}

function StatChip({
  icon,
  value,
  label,
  color,
}: {
  icon: string;
  value: string;
  label?: string;
  color: string;
}) {
  return (
    <div
      className="flex items-center gap-1 px-2 py-1 rounded-lg"
      style={{
        background: "rgba(10, 28, 72, 0.65)",
        border: "1px solid rgba(74,144,217,0.2)",
      }}
    >
      <span className="text-xs">{icon}</span>
      <span className="text-xs font-semibold" style={{ color }}>
        {value}
      </span>
      {label && (
        <span className="text-xs" style={{ color: "#8DB4E8" }}>
          {label}
        </span>
      )}
    </div>
  );
}

function RankBadge() {
  return (
    <div
      className="flex items-center gap-1 px-2.5 py-1 rounded-lg ml-auto"
      style={{
        background: "linear-gradient(135deg, rgba(245,166,35,0.2), rgba(232,146,14,0.15))",
        border: "1px solid rgba(245,166,35,0.5)",
        boxShadow: "0 0 8px rgba(245,166,35,0.2)",
      }}
    >
      <span className="text-xs">🎖️</span>
      <span className="text-xs font-bold" style={{ color: "#F5C842" }}>
        EXPERT
      </span>
    </div>
  );
}
