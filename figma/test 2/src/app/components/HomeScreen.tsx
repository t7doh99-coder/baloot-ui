import { useState } from "react";
import { TopBar } from "./TopBar";
import { PlayerStats } from "./PlayerStats";
import { ArenaDisplay } from "./ArenaDisplay";
import { BattleRow } from "./BattleRow";
import { GameModePanel } from "./GameModePanel";
import { TournamentBanner } from "./TournamentBanner";
import { BottomNav } from "./BottomNav";
import { AchievementBadge } from "./AchievementBadge";

export interface GameMode {
  id: string;
  name: string;
  icon: string;
  desc: string;
  color: string;
}

export const gameModes: GameMode[] = [
  { id: "normal",     name: "Normal Session",  icon: "🃏", desc: "4 players • Classic Baloot",  color: "#4A90D9" },
  { id: "friendly",   name: "Friendly Game",   icon: "🤝", desc: "Play with friends",           color: "#5BB96E" },
  { id: "voice",      name: "Voice Session",   icon: "🎙️", desc: "With voice chat enabled",     color: "#9B59B6" },
  { id: "create",     name: "Create Session",  icon: "➕", desc: "Custom game settings",        color: "#E8920E" },
  { id: "sessions",   name: "Browse Sessions", icon: "📋", desc: "Join existing games",         color: "#E74C3C" },
  { id: "tournament", name: "Tournament",      icon: "🏆", desc: "Compete for prizes",          color: "#F5A623" },
];

export function HomeScreen() {
  const [selectedModeId, setSelectedModeId] = useState("normal");
  const [showModePanel, setShowModePanel] = useState(false);
  const [activeTab, setActiveTab] = useState("home");

  const selectedMode = gameModes.find((m) => m.id === selectedModeId) || gameModes[0];

  function handleModeConfirm(id: string) {
    setSelectedModeId(id);
    setShowModePanel(false);
  }

  return (
    <div
      className="relative w-full h-full overflow-hidden flex flex-col"
      style={{
        background: "linear-gradient(180deg, #091C47 0%, #0D2660 35%, #0E2A68 65%, #0B2055 100%)",
      }}
    >
      {/* Diamond tile overlay */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          backgroundImage: `
            linear-gradient(45deg, rgba(74,144,217,0.06) 25%, transparent 25%),
            linear-gradient(-45deg, rgba(74,144,217,0.06) 25%, transparent 25%),
            linear-gradient(45deg, transparent 75%, rgba(74,144,217,0.06) 75%),
            linear-gradient(-45deg, transparent 75%, rgba(74,144,217,0.06) 75%)
          `,
          backgroundSize: "22px 22px",
          backgroundPosition: "0 0, 0 11px, 11px -11px, -11px 0px",
        }}
      />

      {/* Top glow */}
      <div
        className="absolute top-0 left-1/2 -translate-x-1/2 w-64 h-32 pointer-events-none"
        style={{
          background: "radial-gradient(ellipse, rgba(74,144,217,0.18) 0%, transparent 70%)",
        }}
      />

      <div className="relative z-10 flex flex-col h-full">
        <TopBar />
        <div className="relative">
          <AchievementBadge />
          <PlayerStats />
        </div>
        <div className="flex-1 flex flex-col justify-between px-3 pb-1 min-h-0">
          <ArenaDisplay selectedMode={selectedMode} />
          <div className="space-y-2.5 pb-1">
            <BattleRow
              selectedMode={selectedMode}
              onPlayPress={() => setShowModePanel(true)}
              onModePress={() => setShowModePanel(true)}
            />
            <TournamentBanner />
          </div>
        </div>
        <BottomNav activeTab={activeTab} onTabChange={setActiveTab} />
      </div>

      {showModePanel && (
        <GameModePanel
          selectedModeId={selectedModeId}
          onSelect={setSelectedModeId}
          onConfirm={handleModeConfirm}
          onClose={() => setShowModePanel(false)}
        />
      )}
    </div>
  );
}
