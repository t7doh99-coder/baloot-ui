export function ChestIcon({ size = 300 }: { size?: number }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 280 270"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <defs>
        {/* Purple body panel */}
        <radialGradient id="bodyPurple" cx="50%" cy="35%" r="65%">
          <stop offset="0%" stopColor="#A855F7" />
          <stop offset="55%" stopColor="#6D28D9" />
          <stop offset="100%" stopColor="#2E1065" />
        </radialGradient>

        {/* Purple lid panel */}
        <radialGradient id="lidPurple" cx="50%" cy="30%" r="60%">
          <stop offset="0%" stopColor="#C084FC" />
          <stop offset="55%" stopColor="#7C3AED" />
          <stop offset="100%" stopColor="#3B0764" />
        </radialGradient>

        {/* Panel inner shadow (recessed effect) */}
        <linearGradient id="panelShadowL" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stopColor="#1E0338" stopOpacity="0.7" />
          <stop offset="100%" stopColor="#1E0338" stopOpacity="0" />
        </linearGradient>
        <linearGradient id="panelShadowR" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stopColor="#1E0338" stopOpacity="0" />
          <stop offset="100%" stopColor="#1E0338" stopOpacity="0.7" />
        </linearGradient>
        <linearGradient id="panelShadowT" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#1E0338" stopOpacity="0.5" />
          <stop offset="100%" stopColor="#1E0338" stopOpacity="0" />
        </linearGradient>
        <linearGradient id="panelShadowB" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#1E0338" stopOpacity="0" />
          <stop offset="100%" stopColor="#1E0338" stopOpacity="0.5" />
        </linearGradient>

        {/* Gold bar - lit from top */}
        <linearGradient id="goldBarH" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#FEF9C3" />
          <stop offset="20%" stopColor="#FCD34D" />
          <stop offset="55%" stopColor="#D97706" />
          <stop offset="100%" stopColor="#78350F" />
        </linearGradient>

        {/* Gold bar - lit from side (vertical bar) */}
        <linearGradient id="goldBarV" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stopColor="#92400E" />
          <stop offset="20%" stopColor="#FCD34D" />
          <stop offset="50%" stopColor="#F59E0B" />
          <stop offset="80%" stopColor="#FDE68A" />
          <stop offset="100%" stopColor="#92400E" />
        </linearGradient>

        {/* Gold corner piece */}
        <radialGradient id="cornerG" cx="30%" cy="25%" r="70%">
          <stop offset="0%" stopColor="#FFFBEB" />
          <stop offset="40%" stopColor="#FCD34D" />
          <stop offset="100%" stopColor="#78350F" />
        </radialGradient>

        {/* Rivet */}
        <radialGradient id="rivet" cx="30%" cy="25%" r="70%">
          <stop offset="0%" stopColor="#FEFCE8" />
          <stop offset="55%" stopColor="#F59E0B" />
          <stop offset="100%" stopColor="#451A03" />
        </radialGradient>

        {/* 3D right side - body */}
        <linearGradient id="rightBody" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stopColor="#4C1D95" />
          <stop offset="100%" stopColor="#1E0338" />
        </linearGradient>

        {/* 3D right side - lid */}
        <linearGradient id="rightLid" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stopColor="#5B21B6" />
          <stop offset="100%" stopColor="#2E1065" />
        </linearGradient>

        {/* Lid top face */}
        <linearGradient id="topFace" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#FEF3C7" />
          <stop offset="40%" stopColor="#F59E0B" />
          <stop offset="100%" stopColor="#78350F" />
        </linearGradient>

        {/* Diamond facets */}
        <linearGradient id="dTop" x1="0.5" y1="0" x2="0.5" y2="1">
          <stop offset="0%" stopColor="#F0F9FF" />
          <stop offset="100%" stopColor="#93C5FD" />
        </linearGradient>
        <linearGradient id="dLeft" x1="0" y1="0.5" x2="1" y2="0.5">
          <stop offset="0%" stopColor="#BFDBFE" />
          <stop offset="100%" stopColor="#1D4ED8" />
        </linearGradient>
        <linearGradient id="dRight" x1="0" y1="0.5" x2="1" y2="0.5">
          <stop offset="0%" stopColor="#3B82F6" />
          <stop offset="100%" stopColor="#1E3A8A" />
        </linearGradient>
        <linearGradient id="dBot" x1="0.5" y1="0" x2="0.5" y2="1">
          <stop offset="0%" stopColor="#2563EB" />
          <stop offset="100%" stopColor="#172554" />
        </linearGradient>

        {/* Diamond inner crown facets */}
        <linearGradient id="dInner" x1="0.5" y1="0" x2="0.5" y2="1">
          <stop offset="0%" stopColor="#DBEAFE" stopOpacity="0.9" />
          <stop offset="100%" stopColor="#1D4ED8" stopOpacity="0.5" />
        </linearGradient>

        {/* Diamond aura */}
        <radialGradient id="dAura" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor="#BAE6FD" stopOpacity="0.8" />
          <stop offset="50%" stopColor="#7C3AED" stopOpacity="0.3" />
          <stop offset="100%" stopColor="#3B0764" stopOpacity="0" />
        </radialGradient>

        {/* Glow filter */}
        <filter id="glow" x="-40%" y="-40%" width="180%" height="180%">
          <feGaussianBlur stdDeviation="4" result="blur" />
          <feMerge>
            <feMergeNode in="blur" />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>
      </defs>

      {/* ── Ground shadow ───────────────────────────── */}
      <ellipse cx="142" cy="252" rx="88" ry="11" fill="#000" opacity="0.45" />

      {/* ═══════════════════════════════════════════════
          3-D DEPTH  (right side + top visible faces)
          Body front: x 36-242, y 148-224
          Lid  front: x 30-248, y 76-156
          Right-side depth offset: +18px, -10px
      ═══════════════════════════════════════════════ */}

      {/* Lid top face */}
      <path d="M30 76 L248 76 L266 66 L48 66 Z" fill="url(#topFace)" />
      <path d="M30 76 L248 76 L266 66 L48 66 Z"
        fill="none" stroke="#78350F" strokeWidth="2" />

      {/* Lid right side */}
      <path d="M248 76 L266 66 L266 162 L248 155 Z" fill="url(#rightLid)" />
      <path d="M248 76 L266 66 L266 162 L248 155 Z"
        fill="none" stroke="#78350F" strokeWidth="2" />

      {/* Body right side */}
      <path d="M242 148 L260 158 L260 230 L242 224 Z" fill="url(#rightBody)" />
      <path d="M242 148 L260 158 L260 230 L242 224 Z"
        fill="none" stroke="#78350F" strokeWidth="2" />

      {/* Right-side gold seam band */}
      <path d="M248 152 L266 162 L260 158 L242 148 Z" fill="url(#goldBarH)" opacity="0.9" />

      {/* ═══════════════════════════════════════════════
          MAIN BODY FRONT
      ═══════════════════════════════════════════════ */}
      <rect x="36" y="148" width="206" height="76" rx="4" fill="url(#bodyPurple)" />

      {/* Panel depth shadows */}
      <rect x="36" y="148" width="40" height="76" fill="url(#panelShadowL)" />
      <rect x="202" y="148" width="40" height="76" fill="url(#panelShadowR)" />
      <rect x="36" y="148" width="206" height="26" fill="url(#panelShadowT)" />
      <rect x="36" y="198" width="206" height="26" fill="url(#panelShadowB)" />

      {/* Inner panel bevel lines */}
      <rect x="62" y="164" width="74" height="46" rx="3"
        fill="none" stroke="#9333EA" strokeWidth="1.5" opacity="0.5" />
      <rect x="64" y="166" width="70" height="42" rx="2"
        fill="#2E1065" opacity="0.25" />
      <rect x="142" y="164" width="74" height="46" rx="3"
        fill="none" stroke="#9333EA" strokeWidth="1.5" opacity="0.5" />
      <rect x="144" y="166" width="70" height="42" rx="2"
        fill="#2E1065" opacity="0.25" />

      {/* ═══════════════════════════════════════════════
          MAIN LID FRONT
      ═══════════════════════════════════════════════ */}
      <rect x="30" y="76" width="218" height="79" rx="4" fill="url(#lidPurple)" />

      {/* Panel depth shadows */}
      <rect x="30" y="76" width="40" height="79" fill="url(#panelShadowL)" />
      <rect x="208" y="76" width="40" height="79" fill="url(#panelShadowR)" />
      <rect x="30" y="76" width="218" height="26" fill="url(#panelShadowT)" />

      {/* Inner panel bevel lines */}
      <rect x="56" y="90" width="74" height="52" rx="3"
        fill="none" stroke="#A78BFA" strokeWidth="1.5" opacity="0.45" />
      <rect x="58" y="92" width="70" height="48" rx="2"
        fill="#1E0338" opacity="0.2" />
      <rect x="148" y="90" width="74" height="52" rx="3"
        fill="none" stroke="#A78BFA" strokeWidth="1.5" opacity="0.45" />
      <rect x="150" y="92" width="70" height="48" rx="2"
        fill="#1E0338" opacity="0.2" />

      {/* ═══════════════════════════════════════════════
          GOLD FRAMEWORK BARS  (drawn ON TOP of panels)
      ═══════════════════════════════════════════════ */}

      {/* —— Lid bars —— */}
      {/* Top bar */}
      <rect x="30" y="72" width="218" height="20" fill="url(#goldBarH)" />
      <rect x="30" y="72" width="218" height="20" fill="none" stroke="#78350F" strokeWidth="2" />
      {/* Left bar lid */}
      <rect x="30" y="72" width="24" height="87" fill="url(#goldBarV)" />
      <rect x="30" y="72" width="24" height="87" fill="none" stroke="#78350F" strokeWidth="1.5" />
      {/* Right bar lid */}
      <rect x="224" y="72" width="24" height="87" fill="url(#goldBarV)" />
      <rect x="224" y="72" width="24" height="87" fill="none" stroke="#78350F" strokeWidth="1.5" />
      {/* Centre bar lid */}
      <rect x="130" y="72" width="18" height="87" fill="url(#goldBarV)" />
      <rect x="130" y="72" width="18" height="87" fill="none" stroke="#78350F" strokeWidth="1.2" />

      {/* —— Body bars —— */}
      {/* Left bar body */}
      <rect x="36" y="148" width="24" height="80" fill="url(#goldBarV)" />
      <rect x="36" y="148" width="24" height="80" fill="none" stroke="#78350F" strokeWidth="1.5" />
      {/* Right bar body */}
      <rect x="218" y="148" width="24" height="80" fill="url(#goldBarV)" />
      <rect x="218" y="148" width="24" height="80" fill="none" stroke="#78350F" strokeWidth="1.5" />
      {/* Bottom bar */}
      <rect x="36" y="214" width="206" height="14" fill="url(#goldBarH)" />
      <rect x="36" y="214" width="206" height="14" fill="none" stroke="#78350F" strokeWidth="2" />
      {/* Centre bar body */}
      <rect x="130" y="148" width="18" height="80" fill="url(#goldBarV)" />
      <rect x="130" y="148" width="18" height="80" fill="none" stroke="#78350F" strokeWidth="1.2" />

      {/* —— Seam / Hinge bar —— */}
      <rect x="30" y="144" width="218" height="16" fill="url(#goldBarH)" />
      <rect x="30" y="144" width="218" height="16" fill="none" stroke="#78350F" strokeWidth="2" />

      {/* ═══════════════════════════════════════════════
          CORNER PIECES  (ornate chunky gold blocks)
      ═══════════════════════════════════════════════ */}

      {/* Lid top-left */}
      <rect x="27" y="69" width="32" height="32" rx="4" fill="url(#cornerG)" stroke="#78350F" strokeWidth="2.5" />
      <circle cx="43" cy="85" r="8" fill="url(#rivet)" stroke="#78350F" strokeWidth="2" />
      <circle cx="43" cy="85" r="3.5" fill="#FEF9C3" opacity="0.6" />

      {/* Lid top-right */}
      <rect x="220" y="69" width="32" height="32" rx="4" fill="url(#cornerG)" stroke="#78350F" strokeWidth="2.5" />
      <circle cx="236" cy="85" r="8" fill="url(#rivet)" stroke="#78350F" strokeWidth="2" />
      <circle cx="236" cy="85" r="3.5" fill="#FEF9C3" opacity="0.6" />

      {/* Seam left */}
      <rect x="27" y="140" width="32" height="26" rx="4" fill="url(#cornerG)" stroke="#78350F" strokeWidth="2.5" />
      <circle cx="43" cy="153" r="7" fill="url(#rivet)" stroke="#78350F" strokeWidth="2" />
      <circle cx="43" cy="153" r="3" fill="#FEF9C3" opacity="0.6" />

      {/* Seam right */}
      <rect x="220" y="140" width="32" height="26" rx="4" fill="url(#cornerG)" stroke="#78350F" strokeWidth="2.5" />
      <circle cx="236" cy="153" r="7" fill="url(#rivet)" stroke="#78350F" strokeWidth="2" />
      <circle cx="236" cy="153" r="3" fill="#FEF9C3" opacity="0.6" />

      {/* Body bottom-left */}
      <rect x="32" y="210" width="32" height="22" rx="4" fill="url(#cornerG)" stroke="#78350F" strokeWidth="2.5" />
      <circle cx="48" cy="221" r="7" fill="url(#rivet)" stroke="#78350F" strokeWidth="2" />
      <circle cx="48" cy="221" r="3" fill="#FEF9C3" opacity="0.6" />

      {/* Body bottom-right */}
      <rect x="214" y="210" width="32" height="22" rx="4" fill="url(#cornerG)" stroke="#78350F" strokeWidth="2.5" />
      <circle cx="230" cy="221" r="7" fill="url(#rivet)" stroke="#78350F" strokeWidth="2" />
      <circle cx="230" cy="221" r="3" fill="#FEF9C3" opacity="0.6" />

      {/* Seam-line small rivets */}
      <circle cx="100" cy="152" r="5.5" fill="url(#rivet)" stroke="#78350F" strokeWidth="1.5" />
      <circle cx="139" cy="152" r="5.5" fill="url(#rivet)" stroke="#78350F" strokeWidth="1.5" />
      <circle cx="178" cy="152" r="5.5" fill="url(#rivet)" stroke="#78350F" strokeWidth="1.5" />

      {/* Top bar small rivets */}
      <circle cx="100" cy="82" r="5" fill="url(#rivet)" stroke="#78350F" strokeWidth="1.5" />
      <circle cx="178" cy="82" r="5" fill="url(#rivet)" stroke="#78350F" strokeWidth="1.5" />

      {/* ═══════════════════════════════════════════════
          DIAMOND LOCK  (centered on lid)
          Center: 139, 116   Size: ±30 (60px diagonal)
      ═══════════════════════════════════════════════ */}

      {/* Soft aura behind gem */}
      <ellipse cx="139" cy="116" rx="34" ry="34" fill="url(#dAura)" />

      {/* Gold outer setting ring */}
      <path d="M139 83 L172 116 L139 149 L106 116 Z"
        fill="#D97706" stroke="#451A03" strokeWidth="3" />
      {/* Gold bevel ring */}
      <path d="M139 88 L167 116 L139 144 L111 116 Z"
        fill="#FDE68A" stroke="#92400E" strokeWidth="2" />

      {/* Diamond main facets */}
      {/* Top */}
      <path d="M139 93 L163 116 L139 116 Z" fill="url(#dTop)" />
      {/* Top-left */}
      <path d="M139 93 L115 116 L139 116 Z" fill="url(#dLeft)" />
      {/* Bottom-right */}
      <path d="M163 116 L139 139 L139 116 Z" fill="url(#dRight)" />
      {/* Bottom-left */}
      <path d="M115 116 L139 139 L139 116 Z" fill="url(#dBot)" />

      {/* Inner crown facets (smaller inner diamond lines) */}
      <path d="M139 100 L156 116 L139 132 L122 116 Z"
        fill="none" stroke="white" strokeWidth="1" opacity="0.45" />
      <path d="M139 107 L150 116 L139 125 L128 116 Z"
        fill="url(#dInner)" opacity="0.6" />

      {/* Diamond sparkle highlights */}
      <path d="M139 96 L142 109 L139 106 L136 109 Z" fill="white" opacity="0.95" />
      <circle cx="150" cy="106" r="3" fill="white" opacity="0.7" />
      <circle cx="127" cy="126" r="1.8" fill="white" opacity="0.4" />

      {/* Light rays from gem */}
      <line x1="139" y1="83" x2="139" y2="72"
        stroke="#BAE6FD" strokeWidth="2" opacity="0.55" />
      <line x1="172" y1="116" x2="184" y2="116"
        stroke="#BAE6FD" strokeWidth="2" opacity="0.4" />
      <line x1="106" y1="116" x2="94" y2="116"
        stroke="#BAE6FD" strokeWidth="2" opacity="0.3" />

      {/* ═══════════════════════════════════════════════
          SPARKLE  STARS
      ═══════════════════════════════════════════════ */}
      <g transform="translate(54, 68)">
        <path d="M0,-8 L1.4,-1.4 L8,0 L1.4,1.4 L0,8 L-1.4,1.4 L-8,0 L-1.4,-1.4 Z"
          fill="#FDE68A" opacity="0.95" />
      </g>
      <g transform="translate(224, 70)">
        <path d="M0,-8 L1.4,-1.4 L8,0 L1.4,1.4 L0,8 L-1.4,1.4 L-8,0 L-1.4,-1.4 Z"
          fill="#FDE68A" opacity="0.95" />
      </g>
      <g transform="translate(139, 56)">
        <path d="M0,-6 L1,-1 L6,0 L1,1 L0,6 L-1,1 L-6,0 L-1,-1 Z"
          fill="#E9D5FF" opacity="0.8" />
      </g>
      <g transform="translate(262, 102)">
        <path d="M0,-5 L0.9,-0.9 L5,0 L0.9,0.9 L0,5 L-0.9,0.9 L-5,0 L-0.9,-0.9 Z"
          fill="#FDE68A" opacity="0.7" />
      </g>
      <g transform="translate(24, 130)">
        <path d="M0,-5 L0.9,-0.9 L5,0 L0.9,0.9 L0,5 L-0.9,0.9 L-5,0 L-0.9,-0.9 Z"
          fill="#FDE68A" opacity="0.6" />
      </g>
    </svg>
  );
}
