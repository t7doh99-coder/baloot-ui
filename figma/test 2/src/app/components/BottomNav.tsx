interface BottomNavProps {
  activeTab: string;
  onTabChange: (tab: string) => void;
}

const tabs = [
  { id: "store",    icon: "🛍️",  label: "Store"   },
  { id: "friends",  icon: "👥",  label: "Friends" },
  { id: "home",     icon: "🏠",  label: "Home"    },
  { id: "chat",     icon: "💬",  label: "Chat"    },
  { id: "trophy",   icon: "🏆",  label: "Trophy"  },
];

export function BottomNav({ activeTab, onTabChange }: BottomNavProps) {
  return (
    <div
      className="flex items-center"
      style={{
        background: "linear-gradient(180deg, #071540 0%, #050F2E 100%)",
        borderTop: "1px solid rgba(74,144,217,0.25)",
        paddingBottom: "env(safe-area-inset-bottom, 0px)",
      }}
    >
      {tabs.map((tab) => {
        const isActive = tab.id === activeTab;
        return (
          <button
            key={tab.id}
            className="flex-1 flex flex-col items-center gap-0.5 py-2.5 relative transition-all active:scale-95"
            onClick={() => onTabChange(tab.id)}
          >
            {/* Active indicator bar */}
            {isActive && (
              <div
                className="absolute top-0 left-1/2 -translate-x-1/2 rounded-b-full"
                style={{
                  width: 32,
                  height: 3,
                  background: "linear-gradient(90deg, #F5C842, #E8920E)",
                  boxShadow: "0 0 8px rgba(245,166,35,0.6)",
                }}
              />
            )}

            <span
              className="text-xl leading-none"
              style={{
                filter: isActive ? "drop-shadow(0 0 6px rgba(245,166,35,0.6))" : "none",
                opacity: isActive ? 1 : 0.45,
              }}
            >
              {tab.icon}
            </span>

            <span
              className="text-xs font-semibold leading-none"
              style={{
                color: isActive ? "#F5A623" : "#4A6A9A",
                fontSize: 10,
              }}
            >
              {tab.label}
            </span>
          </button>
        );
      })}
    </div>
  );
}
