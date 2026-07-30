import { ChevronDown } from "lucide-react";
import type { GameMode } from "./HomeScreen";

interface BattleRowProps {
  selectedMode: GameMode;
  onPlayPress: () => void;
  onModePress: () => void;
}

export function BattleRow({ selectedMode, onPlayPress, onModePress }: BattleRowProps) {
  return (
    <>
      <style>{`
        @keyframes play-pulse {
          0%, 100% { box-shadow: 0 4px 0 rgba(100,50,0,0.7), 0 0 22px rgba(245,180,35,0.45); }
          50%       { box-shadow: 0 4px 0 rgba(100,50,0,0.7), 0 0 38px rgba(245,180,35,0.75); }
        }
        .cr-play { animation: play-pulse 2.2s ease-in-out infinite; }
        .cr-play:active  { transform: translateY(3px); box-shadow: 0 1px 0 rgba(100,50,0,0.7) !important; filter: brightness(0.9); }
        .cr-box:active   { transform: translateY(3px); box-shadow: 0 1px 0 rgba(4,12,36,0.8) !important; filter: brightness(0.85); }
      `}</style>

      {/* Dark navy base strip — matches CR's bottom tray */}
      <div
        className="flex items-center gap-2 px-3 py-3 rounded-2xl"
        style={{
          background: "linear-gradient(180deg, #0E2458 0%, #091640 100%)",
          border: "1px solid rgba(74,144,217,0.22)",
          boxShadow: "inset 0 1px 0 rgba(74,144,217,0.15), 0 2px 12px rgba(4,12,36,0.5)",
        }}
      >
        {/* ── LEFT: Selected mode box (large square) ── */}
        <button
          className="cr-box flex flex-col items-center justify-center gap-1.5 rounded-xl flex-shrink-0 relative transition-transform"
          onClick={onModePress}
          style={{
            width: 64,
            height: 64,
            background: "linear-gradient(180deg, #1C4080 0%, #0F2456 100%)",
            borderTop: "2px solid rgba(80,150,230,0.55)",
            borderLeft: "1.5px solid rgba(80,150,230,0.25)",
            borderRight: "1.5px solid rgba(4,12,36,0.5)",
            borderBottom: "2px solid rgba(4,12,36,0.2)",
            boxShadow: "0 4px 0 rgba(4,12,36,0.7)",
          }}
        >
          {/* Mode icon */}
          <div
            className="w-9 h-9 rounded-lg flex items-center justify-center"
            style={{
              background: `${selectedMode.color}22`,
              border: `1px solid ${selectedMode.color}44`,
              fontSize: 20,
            }}
          >
            {selectedMode.icon}
          </div>

          {/* Badge showing mode number / index */}
          <div
            className="absolute bottom-1 left-1 w-4 h-4 rounded-full flex items-center justify-center"
            style={{
              background: "#E8920E",
              border: "1.5px solid rgba(255,255,255,0.5)",
              fontSize: 9,
              color: "#fff",
              fontWeight: 800,
            }}
          >
            ♠
          </div>
        </button>

        {/* ── CENTER: PLAY button (dominant gold pill) ── */}
        <button
          className="cr-play flex flex-col items-center justify-center flex-1 rounded-xl transition-transform relative overflow-hidden"
          onClick={onPlayPress}
          style={{
            height: 64,
            background: "linear-gradient(180deg, #FFE566 0%, #F5A820 55%, #D47808 100%)",
            borderTop: "2px solid rgba(255,255,255,0.55)",
            borderLeft: "1.5px solid rgba(255,220,80,0.5)",
            borderRight: "1.5px solid rgba(140,70,0,0.4)",
            borderBottom: "2px solid rgba(140,70,0,0.2)",
          }}
        >
          {/* Inner shine */}
          <div
            className="absolute top-0 left-0 right-0"
            style={{
              height: "40%",
              background: "linear-gradient(180deg, rgba(255,255,255,0.28) 0%, transparent 100%)",
              borderRadius: "10px 10px 0 0",
            }}
          />
          <span
            className="font-black relative z-10"
            style={{
              color: "#5C2800",
              fontSize: 26,
              letterSpacing: "0.08em",
              textShadow: "0 1px 0 rgba(255,255,255,0.35)",
            }}
          >
            PLAY
          </span>
        </button>

        {/* ── RIGHT: Game mode picker box (smaller square) ── */}
        <button
          className="cr-box flex flex-col items-center justify-center gap-1 rounded-xl flex-shrink-0 relative transition-transform"
          onClick={onModePress}
          style={{
            width: 54,
            height: 54,
            background: "linear-gradient(180deg, #1C4080 0%, #0F2456 100%)",
            borderTop: "2px solid rgba(80,150,230,0.55)",
            borderLeft: "1.5px solid rgba(80,150,230,0.25)",
            borderRight: "1.5px solid rgba(4,12,36,0.5)",
            borderBottom: "2px solid rgba(4,12,36,0.2)",
            boxShadow: "0 4px 0 rgba(4,12,36,0.7)",
          }}
        >
          <ChevronDown size={20} color="#4A90D9" />
          <span style={{ color: "#6AA0D4", fontSize: 8, fontWeight: 700, lineHeight: 1 }}>
            MODE
          </span>
        </button>
      </div>
    </>
  );
}
