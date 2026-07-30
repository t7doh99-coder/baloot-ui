export function TournamentBanner() {
  return (
    <div
      className="rounded-2xl overflow-hidden flex items-center gap-3 px-4 py-3"
      style={{
        background: "linear-gradient(135deg, #1A4A8C 0%, #0D2A60 50%, #1A3A7C 100%)",
        border: "1px solid rgba(245,166,35,0.4)",
        boxShadow: "0 0 16px rgba(245,166,35,0.12)",
      }}
    >
      {/* Trophy icon */}
      <div
        className="w-11 h-11 rounded-xl flex items-center justify-center text-2xl flex-shrink-0"
        style={{
          background: "linear-gradient(135deg, rgba(245,166,35,0.25), rgba(232,146,14,0.15))",
          border: "1px solid rgba(245,166,35,0.4)",
        }}
      >
        🏆
      </div>

      {/* Text */}
      <div className="flex-1 min-w-0">
        <div className="font-bold text-white" style={{ fontSize: 13 }}>
          Baloot Cup Championship
        </div>
        <div className="flex items-center gap-1.5 mt-0.5">
          <div
            className="w-1.5 h-1.5 rounded-full"
            style={{ background: "#5BB95B", boxShadow: "0 0 4px #5BB95B" }}
          />
          <span style={{ color: "#8DB4E8", fontSize: 11 }}>Live now · 342 players competing</span>
        </div>
      </div>

      {/* Join button */}
      <button
        className="px-3 py-1.5 rounded-xl font-bold flex-shrink-0 active:opacity-80"
        style={{
          background: "linear-gradient(135deg, #F5C842, #E8920E)",
          color: "#1A0A00",
          fontSize: 12,
          boxShadow: "0 2px 8px rgba(245,166,35,0.35)",
        }}
      >
        Join
      </button>
    </div>
  );
}
