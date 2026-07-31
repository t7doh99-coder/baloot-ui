import { useState, useEffect } from "react";

const BENEFITS = [
  { icon: "✂️", ar: "القطع والقيد", en: "Cut & Restrict" },
  { icon: "👑", ar: "ملكية الجلسة", en: "Session Ownership" },
  { icon: "🔒", ar: "الجلسات الخاصة", en: "Private Sessions" },
  { icon: "💬", ar: "الدردشة العامة والخاصة", en: "General & Private Chat" },
  { icon: "➕", ar: "إنشاء الجلسات", en: "Create Sessions" },
  { icon: "🚫", ar: "بدون إعلانات", en: "No Ads" },
  { icon: "🎟️", ar: "تذكرتان يومياً للكأس", en: "2 Daily Cup Tickets" },
  { icon: "✨", ar: "إرسال التعابير", en: "Send Expressions" },
  { icon: "🏆", ar: "دوريات غير محدودة", en: "Unlimited Tournaments" },
  { icon: "🃏", ar: "أوجه بطاقات حصرية", en: "Exclusive Card Backs" },
];

const PLANS = [
  { id: "weekly",  ar: "أسبوعي",  price: "12.99",  unit: "أسبوع",  badge: null,         big: false },
  { id: "monthly", ar: "شهري",    price: "34.99",  unit: "شهر",    badge: "وفر 30%",    big: true  },
  { id: "annual",  ar: "سنوي",    price: "284.99", unit: "سنة",    badge: "وفر 55%",    big: false },
];

export default function App() {
  const [selected, setSelected] = useState("monthly");
  const [pressed, setPressed]   = useState<string | null>(null);
  const [closed, setClosed]     = useState(false);
  const [shine, setShine]       = useState(false);

  useEffect(() => {
    const t = setInterval(() => setShine(s => !s), 2800);
    return () => clearInterval(t);
  }, []);

  if (closed) {
    return (
      <div style={{ minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center", background: "#060401" }}>
        <Btn3D onClick={() => setClosed(false)} style={{ padding: "16px 40px", fontSize: "15px", letterSpacing: "0.12em" }}>
          OPEN PREMIUM
        </Btn3D>
      </div>
    );
  }

  return (
    <div style={{
      minHeight: "100vh",
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      padding: "20px 16px",
      background: `
        radial-gradient(ellipse 80% 60% at 50% 0%, rgba(180,120,10,0.18) 0%, transparent 60%),
        radial-gradient(ellipse 60% 40% at 50% 100%, rgba(100,60,5,0.25) 0%, transparent 70%),
        #080502
      `,
    }}>
      {/* ── MODAL ─────────────────────────────────────────────── */}
      <div style={{
        position: "relative",
        width: "100%",
        maxWidth: "360px",
        borderRadius: "28px",
        overflow: "hidden",
        background: "linear-gradient(175deg, #1E1308 0%, #120C04 50%, #0A0703 100%)",
        boxShadow: `
          0 0 0 1.5px #4A3008,
          0 0 0 3px rgba(212,165,32,0.08),
          0 0 60px rgba(180,120,10,0.2),
          0 40px 100px rgba(0,0,0,0.9),
          inset 0 1px 0 rgba(242,200,64,0.22),
          inset 0 -1px 0 rgba(0,0,0,0.6)
        `,
      }}>

        {/* Quilted texture */}
        <div style={{
          position: "absolute", inset: 0, pointerEvents: "none", borderRadius: "28px",
          backgroundImage: `
            repeating-linear-gradient(45deg, rgba(212,165,32,0.028) 0px, rgba(212,165,32,0.028) 1px, transparent 1px, transparent 28px),
            repeating-linear-gradient(-45deg, rgba(212,165,32,0.028) 0px, rgba(212,165,32,0.028) 1px, transparent 1px, transparent 28px)
          `,
        }} />

        {/* Top edge light */}
        <div style={{
          position: "absolute", top: 0, left: "50%", transform: "translateX(-50%)",
          width: "180px", height: "2px", borderRadius: "999px",
          background: "linear-gradient(90deg, transparent, rgba(242,200,64,0.7), transparent)",
        }} />

        {/* Close */}
        <button
          onClick={() => setClosed(true)}
          style={{
            position: "absolute", top: "14px", right: "14px", zIndex: 20,
            width: "30px", height: "30px", borderRadius: "50%",
            border: "1px solid rgba(92,62,10,0.5)",
            background: "rgba(20,12,3,0.7)",
            color: "#6B5030", cursor: "pointer",
            display: "flex", alignItems: "center", justifyContent: "center",
            fontSize: "14px", fontWeight: 700,
            backdropFilter: "blur(4px)",
            transition: "all 0.2s",
          }}
          onMouseEnter={e => { (e.currentTarget as HTMLButtonElement).style.color = "#D4A520"; (e.currentTarget as HTMLButtonElement).style.borderColor = "#D4A520"; }}
          onMouseLeave={e => { (e.currentTarget as HTMLButtonElement).style.color = "#6B5030"; (e.currentTarget as HTMLButtonElement).style.borderColor = "rgba(92,62,10,0.5)"; }}
          aria-label="Close"
        >✕</button>

        {/* ── HEADER BAND ─────────────────────────────────── */}
        <div style={{
          padding: "32px 24px 24px",
          background: "linear-gradient(180deg, rgba(50,30,5,0.9) 0%, rgba(20,12,3,0) 100%)",
          textAlign: "center",
        }}>
          {/* Crown medallion */}
          <div style={{ position: "relative", display: "inline-block", marginBottom: "14px" }}>
            {/* Outer ring glow */}
            <div style={{
              position: "absolute", inset: "-16px",
              borderRadius: "50%",
              background: "radial-gradient(circle, rgba(212,165,32,0.22) 30%, transparent 70%)",
              animation: "pulse 2.8s ease-in-out infinite",
            }} />
            {/* Ring */}
            <div style={{
              width: "88px", height: "88px", borderRadius: "50%",
              background: "linear-gradient(145deg, #2E1C06, #100A02)",
              border: "2px solid transparent",
              backgroundClip: "padding-box",
              boxShadow: `
                0 0 0 2px #7A5010,
                0 0 0 4px rgba(212,165,32,0.15),
                inset 0 2px 4px rgba(255,255,255,0.08),
                inset 0 -2px 4px rgba(0,0,0,0.6),
                0 8px 24px rgba(0,0,0,0.7)
              `,
              display: "flex", alignItems: "center", justifyContent: "center",
              position: "relative", zIndex: 2,
            }}>
              {/* Crown SVG */}
              <svg viewBox="0 0 56 48" style={{ width: "52px", height: "44px", filter: "drop-shadow(0 2px 8px rgba(212,165,32,0.5))" }}>
                <defs>
                  <linearGradient id="cg" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%"   stopColor="#F8E070"/>
                    <stop offset="40%"  stopColor="#D4A520"/>
                    <stop offset="100%" stopColor="#7A5008"/>
                  </linearGradient>
                  <linearGradient id="cb" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%"   stopColor="#E8C030"/>
                    <stop offset="100%" stopColor="#9A6C10"/>
                  </linearGradient>
                  <filter id="glow">
                    <feGaussianBlur stdDeviation="1.5" result="b"/>
                    <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
                  </filter>
                </defs>
                {/* Crown body */}
                <path d="M6 38 L6 26 L16 10 L28 30 L40 10 L50 26 L50 38 Z"
                  fill="url(#cg)" stroke="rgba(255,220,80,0.6)" strokeWidth="0.8" strokeLinejoin="round"
                  filter="url(#glow)"/>
                {/* Base bar */}
                <rect x="4" y="36" width="48" height="9" rx="4.5" fill="url(#cb)" stroke="rgba(255,220,80,0.4)" strokeWidth="0.6"/>
                {/* Base studs */}
                <circle cx="16" cy="40.5" r="2.2" fill="#F5D878"/>
                <circle cx="28" cy="40.5" r="2.2" fill="#F5D878"/>
                <circle cx="40" cy="40.5" r="2.2" fill="#F5D878"/>
                {/* Peak gems */}
                <circle cx="6"  cy="25" r="3.5" fill="#D0321A" stroke="#F8C060" strokeWidth="0.8"/>
                <circle cx="28" cy="10" r="3.5" fill="#1A5FC8" stroke="#F8C060" strokeWidth="0.8"/>
                <circle cx="50" cy="25" r="3.5" fill="#D0321A" stroke="#F8C060" strokeWidth="0.8"/>
                {/* Crown shine */}
                <path d="M10 36 L16 16 L28 32 L40 16 L46 36" fill="rgba(255,255,255,0.07)" strokeWidth="0"/>
              </svg>
            </div>
          </div>

          {/* Title */}
          <div style={{
            fontFamily: "'Cinzel', serif",
            fontSize: "24px",
            fontWeight: 900,
            letterSpacing: "0.16em",
            background: "linear-gradient(180deg, #FAEAA0 0%, #F0C840 30%, #C49010 70%, #8B6010 100%)",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
            backgroundClip: "text",
            lineHeight: 1,
            marginBottom: "6px",
            textShadow: "none",
            position: "relative",
          }}>
            {/* Shimmer overlay */}
            <span style={{
              position: "absolute", inset: 0,
              background: shine
                ? "linear-gradient(105deg, transparent 30%, rgba(255,255,255,0.35) 50%, transparent 70%)"
                : "transparent",
              WebkitBackgroundClip: "text",
              WebkitTextFillColor: "transparent",
              backgroundClip: "text",
              transition: "background 0.4s",
              pointerEvents: "none",
            }} aria-hidden>VIP PREMIUM</span>
            VIP PREMIUM
          </div>

          <div style={{
            fontFamily: "'Cairo', sans-serif",
            fontSize: "12px",
            color: "#8B7040",
            letterSpacing: "0.02em",
            marginBottom: "18px",
          }}>
            اشترك واحصل على تجربة لعب لا مثيل لها
          </div>

          {/* Gold rule */}
          <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
            <div style={{ flex: 1, height: "1px", background: "linear-gradient(90deg, transparent, #5C3E0A 80%)" }}/>
            <div style={{ display: "flex", gap: "5px" }}>
              {[0,1,2].map(i => (
                <div key={i} style={{
                  width: "5px", height: "5px",
                  borderRadius: i === 1 ? "2px" : "50%",
                  background: i === 1 ? "#D4A520" : "#4A3008",
                  transform: i === 1 ? "rotate(45deg)" : "none",
                }}/>
              ))}
            </div>
            <div style={{ flex: 1, height: "1px", background: "linear-gradient(90deg, #5C3E0A 20%, transparent)" }}/>
          </div>
        </div>

        {/* ── BENEFITS ────────────────────────────────────── */}
        <div style={{ padding: "0 16px 16px" }}>
          <div style={{
            fontFamily: "'Cinzel', serif",
            fontSize: "9px",
            letterSpacing: "0.25em",
            color: "#6B5028",
            textTransform: "uppercase",
            textAlign: "center",
            marginBottom: "10px",
          }}>Premium Features</div>

          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "7px" }}>
            {BENEFITS.map((b) => (
              <div key={b.en} style={{
                display: "flex", alignItems: "center", gap: "8px",
                padding: "8px 10px",
                borderRadius: "12px",
                background: "linear-gradient(135deg, rgba(255,200,50,0.07) 0%, rgba(180,120,10,0.04) 100%)",
                border: "1px solid rgba(212,165,32,0.13)",
                boxShadow: "inset 0 1px 0 rgba(255,255,255,0.04), 0 2px 4px rgba(0,0,0,0.3)",
              }}>
                <span style={{ fontSize: "15px", lineHeight: 1, flexShrink: 0 }}>{b.icon}</span>
                <span style={{
                  fontFamily: "'Cairo', sans-serif",
                  fontSize: "10.5px",
                  fontWeight: 600,
                  color: "#CDB882",
                  lineHeight: 1.3,
                  direction: "rtl",
                }}>{b.ar}</span>
              </div>
            ))}
          </div>
        </div>

        {/* ── GOLD DIVIDER ─────────────────────────────── */}
        <div style={{ padding: "0 16px 16px", display: "flex", alignItems: "center", gap: "10px" }}>
          <div style={{ flex: 1, height: "1px", background: "linear-gradient(90deg, transparent, #3A2606 80%)" }}/>
          <svg viewBox="0 0 24 24" style={{ width: "14px", height: "14px", flexShrink: 0 }} fill="#3A2606">
            <path d="M12 2l2.6 7.4H22l-6.3 4.6 2.4 7.4L12 17.4l-6.1 4L8.3 14 2 9.4h7.4z"/>
          </svg>
          <div style={{ flex: 1, height: "1px", background: "linear-gradient(90deg, #3A2606 20%, transparent)" }}/>
        </div>

        {/* ── PRICING ──────────────────────────────────── */}
        <div style={{ padding: "0 14px 20px" }}>

          {/* Cards row */}
          <div style={{ display: "flex", gap: "8px", marginBottom: "16px" }}>
            {PLANS.map((plan) => {
              const sel = selected === plan.id;
              return (
                <button
                  key={plan.id}
                  onClick={() => setSelected(plan.id)}
                  style={{
                    flex: 1,
                    position: "relative",
                    paddingTop: plan.badge ? "22px" : "14px",
                    paddingBottom: "14px",
                    paddingLeft: "6px",
                    paddingRight: "6px",
                    borderRadius: "16px",
                    cursor: "pointer",
                    textAlign: "center",
                    transition: "all 0.25s cubic-bezier(0.34,1.56,0.64,1)",
                    transform: sel && plan.big ? "translateY(-6px) scale(1.04)" : sel ? "translateY(-2px)" : "none",
                    // 3D card effect
                    background: sel
                      ? "linear-gradient(160deg, #2C1C08 0%, #1A1004 50%, #0F0902 100%)"
                      : "linear-gradient(160deg, #181005 0%, #0E0902 100%)",
                    border: "none",
                    boxShadow: sel
                      ? `
                        0 0 0 1.5px #C49010,
                        0 0 0 3px rgba(196,144,16,0.2),
                        0 0 20px rgba(196,144,16,0.25),
                        0 8px 0 #3A2506,
                        0 12px 20px rgba(0,0,0,0.7),
                        inset 0 1px 0 rgba(242,200,64,0.2),
                        inset 0 -1px 0 rgba(0,0,0,0.5)
                      `
                      : `
                        0 0 0 1px rgba(92,62,10,0.4),
                        0 4px 0 rgba(20,12,3,0.8),
                        0 6px 12px rgba(0,0,0,0.5),
                        inset 0 1px 0 rgba(255,255,255,0.04)
                      `,
                  }}
                >
                  {/* Badge */}
                  {plan.badge && (
                    <div style={{
                      position: "absolute",
                      top: "-11px", left: "50%", transform: "translateX(-50%)",
                      padding: "3px 10px", borderRadius: "999px",
                      fontSize: "8.5px",
                      fontFamily: "'Cairo', sans-serif",
                      fontWeight: 700,
                      whiteSpace: "nowrap",
                      background: plan.big && sel
                        ? "linear-gradient(90deg, #B87E08, #F0C830, #B87E08)"
                        : "rgba(92,62,10,0.7)",
                      border: plan.big && sel ? "none" : "1px solid #5C3E0A",
                      color: plan.big && sel ? "#0A0602" : "#9A7E44",
                      boxShadow: plan.big && sel ? "0 2px 8px rgba(196,144,16,0.4)" : "none",
                    }}>{plan.badge}</div>
                  )}

                  {/* Plan name */}
                  <div style={{
                    fontFamily: "'Cairo', sans-serif",
                    fontSize: "11.5px",
                    fontWeight: 700,
                    color: sel ? "#F0C840" : "#5C4018",
                    marginBottom: "5px",
                    direction: "rtl",
                  }}>{plan.ar}</div>

                  {/* Price */}
                  <div style={{
                    fontFamily: "'Cinzel', serif",
                    fontSize: plan.big ? "20px" : "16px",
                    fontWeight: 900,
                    lineHeight: 1,
                    background: sel
                      ? "linear-gradient(180deg, #F8E060 0%, #D4A520 60%, #9A6C10 100%)"
                      : "linear-gradient(180deg, #6B5028 0%, #3A2810 100%)",
                    WebkitBackgroundClip: "text",
                    WebkitTextFillColor: "transparent",
                    backgroundClip: "text",
                    marginBottom: "3px",
                  }}>{plan.price}</div>

                  <div style={{
                    fontFamily: "'Cairo', sans-serif",
                    fontSize: "9px",
                    color: sel ? "#7A5E28" : "#3A2810",
                    direction: "rtl",
                  }}>AED / {plan.unit}</div>

                  {/* Selection dot */}
                  {sel && (
                    <div style={{
                      width: "6px", height: "6px", borderRadius: "50%",
                      background: "#D4A520",
                      boxShadow: "0 0 8px rgba(212,165,32,0.9)",
                      margin: "7px auto 0",
                    }}/>
                  )}
                </button>
              );
            })}
          </div>

          {/* ── 3D SUBSCRIBE BUTTON ─────────────────── */}
          <div style={{ position: "relative" }}>
            {/* Outer glow */}
            <div style={{
              position: "absolute",
              inset: "-4px",
              borderRadius: "22px",
              background: "radial-gradient(ellipse, rgba(212,165,32,0.3) 0%, transparent 70%)",
              filter: "blur(8px)",
              pointerEvents: "none",
            }}/>

            <Btn3D
              onPress={() => setPressed("sub")}
              onRelease={() => setPressed(null)}
              isPressed={pressed === "sub"}
              onClick={() => {}}
              style={{ width: "100%", fontSize: "15px", letterSpacing: "0.1em", paddingTop: "15px", paddingBottom: "15px" }}
            >
              <span style={{ fontFamily: "'Cinzel', serif", fontWeight: 700, display: "block", letterSpacing: "0.12em" }}>
                SUBSCRIBE NOW
              </span>
              <span style={{ fontFamily: "'Cairo', sans-serif", fontSize: "11px", fontWeight: 600, opacity: 0.75, display: "block", marginTop: "1px" }}>
                اشترك الآن
              </span>
            </Btn3D>
          </div>

          {/* Fine print */}
          <div style={{
            fontFamily: "'Cairo', sans-serif",
            fontSize: "9px",
            color: "#3A2808",
            textAlign: "center",
            marginTop: "12px",
            lineHeight: 1.7,
            direction: "rtl",
          }}>
            يتجدد تلقائياً · يمكن الإلغاء في أي وقت
          </div>
        </div>

        {/* Bottom edge */}
        <div style={{
          position: "absolute", bottom: 0, left: "50%", transform: "translateX(-50%)",
          width: "120px", height: "1px",
          background: "linear-gradient(90deg, transparent, rgba(92,62,10,0.6), transparent)",
        }}/>
      </div>

      {/* Keyframes via style tag */}
      <style>{`
        @keyframes pulse {
          0%, 100% { opacity: 0.6; transform: scale(1); }
          50%       { opacity: 1;   transform: scale(1.08); }
        }
        @keyframes shimmer {
          0%   { background-position: -200% center; }
          100% { background-position:  200% center; }
        }
      `}</style>
    </div>
  );
}

/* ── 3D Button Component ──────────────────────────────────── */
function Btn3D({
  children,
  onClick,
  onPress,
  onRelease,
  isPressed,
  style = {},
}: {
  children: React.ReactNode;
  onClick: () => void;
  onPress?: () => void;
  onRelease?: () => void;
  isPressed?: boolean;
  style?: React.CSSProperties;
}) {
  const down = isPressed ?? false;

  return (
    <button
      onClick={onClick}
      onMouseDown={onPress}
      onMouseUp={onRelease}
      onMouseLeave={onRelease}
      onTouchStart={onPress}
      onTouchEnd={onRelease}
      style={{
        position: "relative",
        display: "block",
        cursor: "pointer",
        border: "none",
        borderRadius: "18px",
        padding: "0",
        background: "transparent",
        transform: down ? "translateY(5px)" : "translateY(0px)",
        transition: "transform 0.09s ease",
        width: style.width,
        fontSize: style.fontSize,
      }}
    >
      {/* Bottom 3D depth slab */}
      <div style={{
        position: "absolute",
        inset: 0,
        borderRadius: "18px",
        background: "#6A4A08",
        transform: down ? "translateY(0)" : "translateY(5px)",
        transition: "transform 0.09s ease",
        zIndex: 0,
      }}/>

      {/* Face */}
      <div style={{
        position: "relative",
        zIndex: 1,
        borderRadius: "18px",
        padding: "15px 24px",
        background: down
          ? "linear-gradient(180deg, #C49010 0%, #E8B820 40%, #C49010 100%)"
          : "linear-gradient(180deg, #F8E060 0%, #E8C030 25%, #D4A520 60%, #B87E08 100%)",
        boxShadow: down
          ? "inset 0 3px 6px rgba(0,0,0,0.3), inset 0 1px 0 rgba(0,0,0,0.2)"
          : "inset 0 1px 0 rgba(255,255,255,0.45), inset 0 -2px 0 rgba(0,0,0,0.25)",
        transition: "background 0.09s ease, box-shadow 0.09s ease",
        textAlign: "center",
        color: "#1A0E02",
        overflow: "hidden",
      }}>
        {/* Face shine */}
        {!down && (
          <div style={{
            position: "absolute",
            top: 0, left: 0, right: 0, height: "50%",
            borderRadius: "18px 18px 0 0",
            background: "linear-gradient(180deg, rgba(255,255,255,0.28) 0%, transparent 100%)",
            pointerEvents: "none",
          }}/>
        )}
        {children}
      </div>
    </button>
  );
}
