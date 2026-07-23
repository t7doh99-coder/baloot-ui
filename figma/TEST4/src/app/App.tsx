const HEART = "M 0,24 C -2,18 -22,10 -22,-4 C -22,-16 -12,-22 0,-12 C 12,-22 22,-16 22,-4 C 22,10 2,18 0,24 Z";
const SPADE = "M 0,-24 C 2,-18 22,-10 22,4 C 22,16 12,22 0,12 C -12,22 -22,16 -22,4 C -22,-10 -2,-18 0,-24 Z M -16,26 C -15,18 -10,12 -5,13 C -2,15 2,15 5,13 C 10,12 15,18 16,26 Z";
const DIAMOND = "M 0,-26 L 19,0 L 0,26 L -19,0 Z";
const CLUB = [
  "M 0,-24 C 6,-24 11,-19 11,-13 C 11,-7 6,-2 0,-2 C -6,-2 -11,-7 -11,-13 C -11,-19 -6,-24 0,-24 Z",
  "M -11,-12 C -5,-12 0,-7 0,-1 C 0,5 -5,10 -11,10 C -17,10 -22,5 -22,-1 C -22,-7 -17,-12 -11,-12 Z",
  "M 11,-12 C 17,-12 22,-7 22,-1 C 22,5 17,10 11,10 C 5,10 0,5 0,-1 C 0,-7 5,-12 11,-12 Z",
  "M -15,26 C -13,20 -5,10 0,10 C 5,10 13,20 15,26 Z",
].join(" ");

const SUITS = [
  { id: "spade",   d: SPADE,   cx: 40,  cy: 42  },
  { id: "diamond", d: DIAMOND, cx: 120, cy: 42  },
  { id: "heart",   d: HEART,   cx: 40,  cy: 122 },
  { id: "club",    d: CLUB,    cx: 120, cy: 122 },
];

interface SuitLayersProps {
  d: string;
  cx: number;
  cy: number;
}

function SuitLayers({ d, cx, cy }: SuitLayersProps) {
  return (
    <>
      {/* 1 — drop shadow */}
      <path d={d} transform={`translate(${cx + 2},${cy + 5})`} fill="#062848" opacity="0.55" />
      {/* 2 — dark bevel: bottom-right edge peeks out */}
      <path d={d} transform={`translate(${cx + 2},${cy + 3})`} fill="#1a5490" />
      {/* 3 — light bevel: top-left edge peeks out */}
      <path d={d} transform={`translate(${cx - 2},${cy - 3})`} fill="#90cce8" />
      {/* 4 — face with gradient */}
      <path d={d} transform={`translate(${cx},${cy})`} fill="url(#sFace)" />
      {/* 5 — specular sheen */}
      <path d={d} transform={`translate(${cx},${cy})`} fill="url(#sSheen)" />
    </>
  );
}

export default function App() {
  return (
    <div style={{ width: "100vw", height: "100vh", overflow: "hidden" }}>
      <svg width="100%" height="100%" style={{ display: "block" }}>
        <defs>
          {/* Face gradient — light top-left to deeper blue bottom-right */}
          <linearGradient id="sFace" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%"   stopColor="#c0e8f8" />
            <stop offset="20%"  stopColor="#88c8e8" />
            <stop offset="62%"  stopColor="#54a8d8" />
            <stop offset="100%" stopColor="#3082bc" />
          </linearGradient>

          {/* Specular sheen — white highlight top-left */}
          <linearGradient id="sSheen" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%"   stopColor="#ffffff" stopOpacity="0.55" />
            <stop offset="50%"  stopColor="#ffffff" stopOpacity="0.07" />
            <stop offset="100%" stopColor="#ffffff" stopOpacity="0"    />
          </linearGradient>

          <pattern id="suits" width="160" height="160" patternUnits="userSpaceOnUse">
            {/* gap / background */}
            <rect width="160" height="160" fill="#1868a2" />

            {SUITS.map(({ id, d, cx, cy }) => (
              <SuitLayers key={id} d={d} cx={cx} cy={cy} />
            ))}
          </pattern>
        </defs>

        <rect width="100%" height="100%" fill="url(#suits)" />
      </svg>
    </div>
  );
}
