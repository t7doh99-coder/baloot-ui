import { Menu } from "lucide-react";

export function TopBar() {
  return (
    <div className="flex items-center gap-2 px-3 pt-3 pb-2">
      {/* Player profile */}
      <div
        className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl flex-shrink-0"
        style={{
          background: "rgba(10, 28, 72, 0.7)",
          border: "1px solid rgba(74,144,217,0.3)",
        }}
      >
        <div
          className="w-9 h-9 rounded-full flex items-center justify-center text-sm font-bold flex-shrink-0"
          style={{
            background: "linear-gradient(135deg, #2456A4, #1A3A7C)",
            border: "2px solid #F5A623",
            color: "#F5A623",
          }}
        >
          MK
        </div>
        <div className="min-w-0">
          <div className="text-white text-xs font-semibold leading-tight">elpatron</div>
          <div className="flex items-center gap-1 mt-0.5">
            <span style={{ color: "#F5A623" }} className="text-xs">⭐</span>
            <span className="text-xs" style={{ color: "#8DB4E8" }}>Lv. 42</span>
          </div>
        </div>
      </div>

      {/* Currency pills */}
      <div className="flex items-center gap-1.5 flex-1 justify-center">
        <CurrencyPill icon="🪙" value="1.1M" color="#F5A623" bg="rgba(245,166,35,0.12)" border="rgba(245,166,35,0.35)" />
        <CurrencyPill icon="💎" value="662" color="#5BB9F5" bg="rgba(91,185,245,0.12)" border="rgba(91,185,245,0.35)" />
      </div>

      {/* Menu button */}
      <button
        className="w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0"
        style={{
          background: "rgba(10, 28, 72, 0.7)",
          border: "1px solid rgba(74,144,217,0.3)",
        }}
      >
        <Menu size={18} color="#8DB4E8" />
      </button>
    </div>
  );
}

function CurrencyPill({
  icon,
  value,
  color,
  bg,
  border,
}: {
  icon: string;
  value: string;
  color: string;
  bg: string;
  border: string;
}) {
  return (
    <div
      className="flex items-center gap-1 px-2.5 py-1 rounded-lg"
      style={{ background: bg, border: `1px solid ${border}` }}
    >
      <span className="text-xs font-bold" style={{ color }}>
        +
      </span>
      <span className="text-sm">{icon}</span>
      <span className="text-xs font-bold" style={{ color }}>
        {value}
      </span>
    </div>
  );
}
