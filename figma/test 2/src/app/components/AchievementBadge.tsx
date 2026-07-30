export function AchievementBadge() {
  return (
    <div className="absolute left-3 top-1 z-20">
      <button
        className="w-11 h-11 rounded-full flex flex-col items-center justify-center"
        style={{
          background: "linear-gradient(135deg, #1A3A7C, #0D2050)",
          border: "2px solid #F5A623",
          boxShadow: "0 0 14px rgba(245,166,35,0.5), inset 0 1px 0 rgba(255,255,255,0.1)",
        }}
      >
        <span className="text-base leading-none">🎁</span>
        <span className="text-white leading-none" style={{ fontSize: "7px", marginTop: "1px" }}>
          DAILY
        </span>
      </button>
    </div>
  );
}
