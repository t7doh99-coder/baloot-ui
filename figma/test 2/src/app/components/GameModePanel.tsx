import { Check } from "lucide-react";
import { gameModes } from "./HomeScreen";
import type { GameMode } from "./HomeScreen";

interface GameModePanelProps {
  selectedModeId: string;
  onSelect: (id: string) => void;
  onConfirm: (id: string) => void;
  onClose: () => void;
}

const sections = [
  { label: null,                 ids: ["normal", "friendly", "voice"] },
  { label: "Competitive Modes", ids: ["tournament"] },
  { label: "Classic Modes",     ids: ["create", "sessions"] },
];

const cardColors: Record<string, { left: string; right: string }> = {
  normal:     { left: "#0D3E82", right: "#1558A8" },
  friendly:   { left: "#0D3E82", right: "#1E6B2C" },
  voice:      { left: "#0D3E82", right: "#3A2080" },
  tournament: { left: "#3A1E7A", right: "#6028A0" },
  create:     { left: "#0D3E82", right: "#1558A8" },
  sessions:   { left: "#0D3E82", right: "#1E4A8C" },
};

export function GameModePanel({ selectedModeId, onSelect, onConfirm, onClose }: GameModePanelProps) {
  return (
    <>
      <style>{`
        @keyframes cr-slide-up {
          from { transform: translateY(100%); }
          to   { transform: translateY(0); }
        }
        .cr-drawer  { animation: cr-slide-up 0.28s cubic-bezier(0.32, 0.72, 0, 1); }
        .cr-ticket:active { filter: brightness(0.88); transform: scale(0.985); }
        .cr-close:active  { transform: translateY(2px); box-shadow: 0 1px 0 rgba(0,0,0,0.4) !important; }
      `}</style>

      {/* Backdrop — full screen, tap to close */}
      <div
        className="absolute inset-0 z-30"
        style={{ background: "rgba(0,0,0,0.58)" }}
        onClick={onClose}
      />

      {/* Half-screen drawer — slides up from bottom, flat top (tab handles the cap) */}
      <div
        className="cr-drawer absolute bottom-0 left-0 right-0 z-40 flex flex-col"
        style={{
          height: "60%",
          background: "linear-gradient(180deg, #1258B0 0%, #0E4898 100%)",
          boxShadow: "0 -8px 40px rgba(0,0,100,0.6)",
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* ══ CR-style header: tab + title bar ══ */}
        <div className="flex-shrink-0">

          {/* Tab — centered, rounded top only, sits at very top of drawer */}
          <div className="flex justify-center">
            <button
              className="cr-close flex items-center justify-center transition-transform"
              onClick={onClose}
              style={{
                width: 86,
                paddingTop: 9,
                paddingBottom: 8,
                background: "linear-gradient(180deg, #3AB2FF 0%, #1A82E8 100%)",
                borderRadius: "13px 13px 0 0",
                borderTop: "2.5px solid rgba(160,230,255,0.8)",
                borderLeft: "2.5px solid rgba(160,230,255,0.6)",
                borderRight: "2.5px solid rgba(160,230,255,0.6)",
                borderBottom: "none",
              }}
            >
              {/* Inner chevron box — like CR's inset button */}
              <div
                style={{
                  width: 44,
                  height: 28,
                  borderRadius: 8,
                  background: "linear-gradient(180deg, #1A6AD4 0%, #1050B8 100%)",
                  border: "1.5px solid rgba(100,190,255,0.55)",
                  boxShadow: "inset 0 1px 0 rgba(255,255,255,0.15)",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                }}
              >
                <svg width="18" height="11" viewBox="0 0 18 11" fill="none">
                  <path d="M2 2L9 9L16 2" stroke="white" strokeWidth="2.8" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </div>
            </button>
          </div>

          {/* Game Modes title bar — full width, flush below tab */}
          <div
            style={{
              background: "linear-gradient(180deg, #2290FF 0%, #1468D0 100%)",
              borderTop: "2.5px solid rgba(140,220,255,0.75)",
              borderBottom: "2.5px solid rgba(20,80,180,0.8)",
              paddingTop: 10,
              paddingBottom: 10,
              textAlign: "center",
              position: "relative",
              overflow: "hidden",
            }}
          >
            {/* Top shine */}
            <div style={{
              position: "absolute", top: 0, left: 0, right: 0, height: "45%",
              background: "linear-gradient(180deg, rgba(255,255,255,0.12) 0%, transparent 100%)",
            }} />
            <span
              style={{
                color: "#fff",
                fontSize: 22,
                fontWeight: 900,
                letterSpacing: "0.04em",
                textShadow: "0 1px 0 rgba(0,60,160,0.6), 0 2px 6px rgba(0,0,0,0.4)",
                position: "relative",
              }}
            >
              Game Modes
            </span>
          </div>
        </div>

        {/* ── Scrollable mode list ── */}
        <div className="flex-1 overflow-y-auto px-4 py-2.5 space-y-2 min-h-0">
          {sections.map((section, si) => (
            <div key={si} className="space-y-1.5">
              {section.label && (
                <div className="flex items-center gap-3 py-0.5">
                  <div style={{ flex: 1, height: 1, background: "rgba(255,255,255,0.2)" }} />
                  <span style={{ color: "rgba(255,255,255,0.6)", fontSize: 10, fontWeight: 700, letterSpacing: "0.07em", textTransform: "uppercase" }}>
                    {section.label}
                  </span>
                  <div style={{ flex: 1, height: 1, background: "rgba(255,255,255,0.2)" }} />
                </div>
              )}
              {section.ids.map((id) => {
                const mode = gameModes.find((m) => m.id === id)!;
                return (
                  <TicketCard
                    key={id}
                    mode={mode}
                    colors={cardColors[id]}
                    isSelected={id === selectedModeId}
                    onSelect={() => onSelect(id)}
                  />
                );
              })}
            </div>
          ))}
        </div>

        {/* ── PLAY NOW pinned at bottom ── */}
        <div className="flex-shrink-0 px-4 pt-2 pb-4">
          <button
            className="w-full py-3 rounded-2xl font-black tracking-widest transition-opacity active:opacity-80"
            onClick={() => onConfirm(selectedModeId)}
            style={{
              background: "linear-gradient(135deg, #F5C842 0%, #E8920E 60%, #C4720A 100%)",
              boxShadow: "0 4px 0 rgba(100,50,0,0.6), 0 0 18px rgba(245,166,35,0.35)",
              borderTop: "2px solid rgba(255,255,255,0.4)",
              color: "#3A1400",
              fontSize: 17,
              letterSpacing: "0.1em",
            }}
          >
            ♠ &nbsp; PLAY NOW
          </button>
        </div>
      </div>
    </>
  );
}

function TicketCard({
  mode,
  colors,
  isSelected,
  onSelect,
}: {
  mode: GameMode;
  colors: { left: string; right: string };
  isSelected: boolean;
  onSelect: () => void;
}) {
  return (
    <button
      className="cr-ticket w-full flex items-stretch rounded-xl overflow-hidden transition-all text-left"
      onClick={onSelect}
      style={{
        border: isSelected ? "2px solid rgba(245,196,50,0.9)" : "2px solid rgba(255,255,255,0.1)",
        boxShadow: isSelected
          ? "0 0 12px rgba(245,196,50,0.4), 0 3px 0 rgba(0,20,80,0.55)"
          : "0 3px 0 rgba(0,20,80,0.45)",
        minHeight: 60,
      }}
    >
      {/* Left content */}
      <div
        className="flex-1 flex flex-col justify-center px-3 py-2.5 relative overflow-hidden"
        style={{ background: colors.left }}
      >
        <div
          className="absolute top-0 left-0 right-0"
          style={{ height: "45%", background: "linear-gradient(180deg, rgba(255,255,255,0.07) 0%, transparent 100%)" }}
        />
        <span className="relative font-black text-white" style={{ fontSize: 15, textShadow: "0 1px 3px rgba(0,0,0,0.4)" }}>
          {mode.name}
        </span>
        <span className="relative mt-0.5" style={{ color: "rgba(255,255,255,0.6)", fontSize: 11 }}>
          {mode.desc}
        </span>
      </div>

      {/* Divider notch */}
      <div style={{ width: 2, background: "rgba(0,0,0,0.25)" }} />

      {/* Right box */}
      <div
        className="flex items-center justify-center flex-shrink-0 relative overflow-hidden"
        style={{ width: 64, background: colors.right }}
      >
        <div
          className="absolute top-0 left-0 right-0"
          style={{ height: "45%", background: "linear-gradient(180deg, rgba(255,255,255,0.1) 0%, transparent 100%)" }}
        />
        {isSelected && (
          <div
            className="relative w-8 h-8 rounded-full flex items-center justify-center"
            style={{
              background: "linear-gradient(135deg, #F5C842, #E8920E)",
              boxShadow: "0 2px 8px rgba(245,166,35,0.5)",
              border: "2px solid rgba(255,255,255,0.35)",
            }}
          >
            <Check size={15} color="#fff" strokeWidth={3} />
          </div>
        )}
      </div>
    </button>
  );
}
