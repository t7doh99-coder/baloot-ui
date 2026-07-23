import type { GameMode } from "./HomeScreen";

export function ArenaDisplay({ selectedMode }: { selectedMode: GameMode }) {
  return (
    <div className="flex-1 flex items-center justify-center min-h-0 py-2">
      <div className="relative flex items-center justify-center" style={{ width: 220, height: 180 }}>
        {/* Outer glow ring */}
        <div
          className="absolute rounded-full"
          style={{
            width: 200,
            height: 160,
            background: "radial-gradient(ellipse, rgba(74,144,217,0.12) 0%, transparent 70%)",
            boxShadow: "0 0 40px rgba(74,144,217,0.15)",
          }}
        />

        {/* Card table surface */}
        <div
          className="relative rounded-[50%] flex items-center justify-center"
          style={{
            width: 190,
            height: 148,
            background: "linear-gradient(135deg, #0F3A1A 0%, #144D22 40%, #0F3A1A 100%)",
            border: "3px solid rgba(245,166,35,0.6)",
            boxShadow: "0 0 20px rgba(245,166,35,0.25), inset 0 2px 8px rgba(0,0,0,0.4)",
          }}
        >
          {/* Inner felt ring */}
          <div
            className="absolute rounded-[50%]"
            style={{
              inset: 8,
              border: "1px solid rgba(245,166,35,0.25)",
            }}
          />

          {/* Corner cards */}
          <Card pos="top-3 left-6" suit="♠" rotate="-12deg" />
          <Card pos="top-3 right-6" suit="♥" rotate="12deg" color="#E74C4C" />
          <Card pos="bottom-3 left-6" suit="♣" rotate="8deg" />
          <Card pos="bottom-3 right-6" suit="♦" rotate="-8deg" color="#E74C4C" />

          {/* Center: large suit icon from selected mode or default spade */}
          <div className="absolute inset-0 flex flex-col items-center justify-center">
            <div
              className="text-4xl leading-none select-none"
              style={{ filter: "drop-shadow(0 2px 6px rgba(0,0,0,0.5))" }}
            >
              {selectedMode.id === "normal" ? "♠" : selectedMode.icon}
            </div>
            {selectedMode.id !== "normal" && (
              <div
                className="text-xs font-semibold mt-1 px-2 py-0.5 rounded-full"
                style={{
                  background: "rgba(0,0,0,0.45)",
                  color: selectedMode.color,
                  border: `1px solid ${selectedMode.color}40`,
                }}
              >
                {selectedMode.name}
              </div>
            )}
          </div>
        </div>

        {/* Live players badge */}
        <div
          className="absolute top-0 right-0 flex items-center gap-1 px-2 py-0.5 rounded-full"
          style={{
            background: "rgba(10, 28, 72, 0.9)",
            border: "1px solid rgba(91,185,91,0.6)",
          }}
        >
          <div
            className="w-1.5 h-1.5 rounded-full"
            style={{ background: "#5BB95B", boxShadow: "0 0 4px #5BB95B" }}
          />
          <span className="text-white" style={{ fontSize: 10 }}>
            1,247 online
          </span>
        </div>

        {/* Fire badge */}
        <div
          className="absolute top-0 left-2 px-2 py-0.5 rounded-full flex items-center gap-1"
          style={{
            background: "rgba(10, 28, 72, 0.9)",
            border: "1px solid rgba(232,146,14,0.5)",
          }}
        >
          <span style={{ fontSize: 11 }}>🔥</span>
          <span className="text-xs font-bold" style={{ color: "#F5C842" }}>
            HOT
          </span>
        </div>
      </div>
    </div>
  );
}

function Card({
  pos,
  suit,
  rotate,
  color = "#E8E8F0",
}: {
  pos: string;
  suit: string;
  rotate: string;
  color?: string;
}) {
  return (
    <div
      className={`absolute ${pos} w-7 h-9 rounded flex items-center justify-center`}
      style={{
        background: "linear-gradient(135deg, #F0EEE8, #E4E0D8)",
        border: "1px solid rgba(255,255,255,0.6)",
        transform: `rotate(${rotate})`,
        boxShadow: "0 2px 6px rgba(0,0,0,0.4)",
      }}
    >
      <span className="text-sm font-bold leading-none" style={{ color }}>
        {suit}
      </span>
    </div>
  );
}
