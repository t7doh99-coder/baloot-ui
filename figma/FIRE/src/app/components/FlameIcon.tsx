export function FlameIcon({ size = 200 }: { size?: number }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 160 200"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <defs>
        {/* Outer flame gradient */}
        <radialGradient id="flameOuter" cx="50%" cy="80%" r="65%">
          <stop offset="0%" stopColor="#F97316" />
          <stop offset="55%" stopColor="#DC2626" />
          <stop offset="100%" stopColor="#7F1D1D" />
        </radialGradient>

        {/* Mid flame gradient */}
        <radialGradient id="flameMid" cx="50%" cy="75%" r="60%">
          <stop offset="0%" stopColor="#FDE68A" />
          <stop offset="45%" stopColor="#F97316" />
          <stop offset="100%" stopColor="#C2410C" />
        </radialGradient>

        {/* Inner flame gradient */}
        <radialGradient id="flameInner" cx="50%" cy="70%" r="55%">
          <stop offset="0%" stopColor="#FFFBEB" />
          <stop offset="40%" stopColor="#FDE68A" />
          <stop offset="100%" stopColor="#F59E0B" />
        </radialGradient>

        {/* Core tip */}
        <radialGradient id="flameCore" cx="50%" cy="60%" r="50%">
          <stop offset="0%" stopColor="#FFFFFF" />
          <stop offset="100%" stopColor="#FEF3C7" />
        </radialGradient>

        {/* Base glow */}
        <radialGradient id="baseGlow" cx="50%" cy="30%" r="50%">
          <stop offset="0%" stopColor="#FCD34D" stopOpacity="0.9" />
          <stop offset="55%" stopColor="#F97316" stopOpacity="0.45" />
          <stop offset="100%" stopColor="#7F1D1D" stopOpacity="0" />
        </radialGradient>

        {/* Outer shadow/depth */}
        <filter id="flameShadow" x="-30%" y="-20%" width="160%" height="150%">
          <feGaussianBlur stdDeviation="4" result="blur" />
          <feMerge>
            <feMergeNode in="blur" />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>

        <style>{`
          @keyframes flicker {
            0%   { transform: scaleX(1)    scaleY(1)    translateY(0px);  }
            25%  { transform: scaleX(0.93) scaleY(1.04) translateY(-2px); }
            50%  { transform: scaleX(1.05) scaleY(0.97) translateY(1px);  }
            75%  { transform: scaleX(0.96) scaleY(1.03) translateY(-1px); }
            100% { transform: scaleX(1)    scaleY(1)    translateY(0px);  }
          }
          @keyframes flicker2 {
            0%   { transform: scaleX(1)    scaleY(1)    translateY(0px);  }
            30%  { transform: scaleX(1.06) scaleY(0.95) translateY(2px);  }
            60%  { transform: scaleX(0.94) scaleY(1.06) translateY(-3px); }
            100% { transform: scaleX(1)    scaleY(1)    translateY(0px);  }
          }
          @keyframes flicker3 {
            0%   { transform: scaleX(1)    scaleY(1)    translateY(0px);  }
            40%  { transform: scaleX(0.9)  scaleY(1.08) translateY(-4px); }
            70%  { transform: scaleX(1.08) scaleY(0.94) translateY(2px);  }
            100% { transform: scaleX(1)    scaleY(1)    translateY(0px);  }
          }
          @keyframes flicker4 {
            0%   { transform: scaleY(1)   translateY(0px);  opacity: 1; }
            50%  { transform: scaleY(1.1) translateY(-5px); opacity: 0.85; }
            100% { transform: scaleY(1)   translateY(0px);  opacity: 1; }
          }
          @keyframes ember1 {
            0%   { transform: translate(0px,   0px)  scale(1);   opacity: 0.9; }
            60%  { transform: translate(-8px, -55px) scale(0.7); opacity: 0.6; }
            100% { transform: translate(-12px,-90px) scale(0.3); opacity: 0;   }
          }
          @keyframes ember2 {
            0%   { transform: translate(0px,  0px)   scale(1);   opacity: 0.8; }
            60%  { transform: translate(10px,-50px)  scale(0.6); opacity: 0.5; }
            100% { transform: translate(14px,-85px)  scale(0.2); opacity: 0;   }
          }
          @keyframes ember3 {
            0%   { transform: translate(0px,  0px)   scale(0.8); opacity: 0.7; }
            60%  { transform: translate(-5px,-60px)  scale(0.5); opacity: 0.4; }
            100% { transform: translate(-8px,-95px)  scale(0.2); opacity: 0;   }
          }
          @keyframes ember4 {
            0%   { transform: translate(0px,  0px)   scale(0.9); opacity: 0.85; }
            60%  { transform: translate(7px, -48px)  scale(0.5); opacity: 0.4;  }
            100% { transform: translate(10px,-82px)  scale(0.2); opacity: 0;    }
          }
          @keyframes ember5 {
            0%   { transform: translate(0px,  0px)   scale(0.7); opacity: 0.75; }
            60%  { transform: translate(-3px,-52px)  scale(0.4); opacity: 0.35; }
            100% { transform: translate(-6px,-88px)  scale(0.15);opacity: 0;    }
          }
          @keyframes glowPulse {
            0%, 100% { opacity: 0.65; transform: scaleX(1)   scaleY(1);   }
            50%       { opacity: 0.9;  transform: scaleX(1.1) scaleY(1.15); }
          }

          .flame-outer  { transform-origin: 80px 170px; animation: flicker  0.9s ease-in-out infinite; }
          .flame-mid    { transform-origin: 80px 165px; animation: flicker2 0.75s ease-in-out infinite 0.15s; }
          .flame-inner  { transform-origin: 80px 160px; animation: flicker3 0.6s ease-in-out infinite 0.3s; }
          .flame-core   { transform-origin: 80px 155px; animation: flicker4 0.5s ease-in-out infinite 0.1s; }
          .base-glow    { transform-origin: 80px 175px; animation: glowPulse 1.1s ease-in-out infinite; }
          .ember-1 { animation: ember1 1.6s linear infinite 0s;   }
          .ember-2 { animation: ember2 1.6s linear infinite 0.4s; }
          .ember-3 { animation: ember3 1.6s linear infinite 0.8s; }
          .ember-4 { animation: ember4 1.6s linear infinite 1.1s; }
          .ember-5 { animation: ember5 1.6s linear infinite 1.4s; }
        `}</style>
      </defs>

      {/* ── Base glow pool ─────────────────────────── */}
      <ellipse
        className="base-glow"
        cx="80" cy="175" rx="52" ry="18"
        fill="url(#baseGlow)"
      />

      {/* ── Outer flame (largest, darkest red-orange) ── */}
      <path
        className="flame-outer"
        d="
          M80 22
          C80 22  112 55  118 88
          C124 118  116 140  108 155
          C100 168  88  174  80  174
          C72  174  60  168  52  155
          C44  140  36  118  42  88
          C48  55   80  22   80  22 Z
        "
        fill="url(#flameOuter)"
        filter="url(#flameShadow)"
      />

      {/* ── Mid flame ─────────────────────────────── */}
      <path
        className="flame-mid"
        d="
          M80 42
          C80 42  104 70  109 97
          C114 122  108 142  101 154
          C95  164  87  169  80  169
          C73  169  65  164  59  154
          C52  142  46  122  51  97
          C56  70   80  42   80  42 Z
        "
        fill="url(#flameMid)"
      />

      {/* ── Inner flame ───────────────────────────── */}
      <path
        className="flame-inner"
        d="
          M80 62
          C80 62  97  83  101 105
          C105 125  101 143  96  153
          C91  162  85  166  80  166
          C75  166  69  162  64  153
          C59  143  55  125  59  105
          C63  83   80  62   80  62 Z
        "
        fill="url(#flameInner)"
      />

      {/* ── Core tip ──────────────────────────────── */}
      <path
        className="flame-core"
        d="
          M80 78
          C80 78  90  95  92  112
          C94  128  90  144  85  153
          C83  158  81  161  80  162
          C79  161  77  158  75  153
          C70  144  66  128  68  112
          C70  95   80  78   80  78 Z
        "
        fill="url(#flameCore)"
      />

      {/* ── Ember particles ───────────────────────── */}
      <circle className="ember-1" cx="72" cy="155" r="3.5" fill="#FCD34D" />
      <circle className="ember-2" cx="88" cy="148" r="3"   fill="#FCA5A5" />
      <circle className="ember-3" cx="76" cy="152" r="2.5" fill="#FDE68A" />
      <circle className="ember-4" cx="85" cy="158" r="2"   fill="#FCD34D" />
      <circle className="ember-5" cx="80" cy="145" r="2"   fill="#FB923C" />
    </svg>
  );
}
