import { useMemo } from "react";

const C = {
  cream: "#FAF3E0",
  red: "#E63946",
  darkRed: "#A02020",
  blue: "#2080D0",
  skyBlue: "#30C8D8",
  teal: "#28B0A0",
  yellow: "#F0C820",
  orange: "#D88030",
  brown: "#5C3A1E",
  darkBrown: "#3D2518",
  green: "#28802E",
  darkGreen: "#1A5028",
  navy: "#1E2878",
  black: "#222",
  pink: "#E87080",
};

// Leaf/feather branch
function Branch({ x, y, angle, s = 1 }: { x: number; y: number; angle: number; s?: number }) {
  const leaves = [5, 10, 15, 20, 25];
  return (
    <g transform={`translate(${x},${y}) rotate(${angle}) scale(${s})`}>
      <line x1="0" y1="0" x2="0" y2="-32" stroke={C.darkBrown} strokeWidth="1.2" />
      {leaves.map((dy, i) => (
        <g key={i}>
          <line x1="0" y1={-dy} x2={-(7 - i)} y2={-dy - 4} stroke={C.darkBrown} strokeWidth="0.9" />
          <line x1="0" y1={-dy} x2={7 - i} y2={-dy - 4} stroke={C.darkBrown} strokeWidth="0.9" />
        </g>
      ))}
    </g>
  );
}

// Multicolored diamond ring
function DiamondBand({ cx, cy, r, count, size = 8 }: { cx: number; cy: number; r: number; count: number; size?: number }) {
  const palette = [C.red, C.blue, C.yellow, C.teal, C.orange, C.green, C.brown, C.navy, C.darkRed, C.skyBlue, C.pink, C.darkGreen];
  return (
    <g>
      {Array.from({ length: count }).map((_, i) => {
        const a = (i * 360) / count;
        const rad = (a * Math.PI) / 180;
        const x = cx + Math.cos(rad) * r;
        const y = cy + Math.sin(rad) * r;
        const half = size / 2;
        return (
          <rect
            key={i} x={x - half} y={y - half} width={size} height={size}
            fill={palette[i % palette.length]}
            stroke={C.darkBrown} strokeWidth="0.5"
            transform={`rotate(45,${x},${y})`}
          />
        );
      })}
    </g>
  );
}

export default function App() {
  const W = 800, H = 1100;
  const CX = W / 2, CY = H / 2;

  const fringeData = useMemo(() => Array.from({ length: 100 }), []);

  // Radiating triangle motif
  const outerTriCount = 16;
  const outerTriangles = Array.from({ length: outerTriCount }).map((_, i) => {
    const a = (i * 360) / outerTriCount;
    const rad = (a * Math.PI) / 180;
    const dist = 168;
    const x = CX + Math.cos(rad) * dist;
    const y = CY + Math.sin(rad) * dist;
    const colorSets = [
      [C.darkBrown, C.orange, C.red],
      [C.darkBrown, C.red, C.pink],
      [C.darkBrown, C.skyBlue, C.blue],
      [C.darkBrown, C.blue, C.orange],
    ];
    const cs = colorSets[i % 4];
    return { x, y, a, cs };
  });

  return (
    <div className="size-full flex items-center justify-center bg-[#B8B0A0] overflow-auto p-8">
      <svg
        width="800" height="1100" viewBox="0 0 800 1100"
        xmlns="http://www.w3.org/2000/svg"
        className="max-w-full h-auto"
        style={{ filter: "drop-shadow(0 12px 24px rgba(0,0,0,0.25))" }}
      >
        <defs>
          <pattern id="weave" width="3" height="3" patternUnits="userSpaceOnUse">
            <rect width="3" height="3" fill={C.cream} />
            <line x1="0" y1="1.5" x2="3" y2="1.5" stroke="#EDE5D0" strokeWidth="0.3" opacity="0.4" />
            <line x1="1.5" y1="0" x2="1.5" y2="3" stroke="#EDE5D0" strokeWidth="0.3" opacity="0.3" />
          </pattern>
          <linearGradient id="fg" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#D8C8A0" />
            <stop offset="100%" stopColor="#A08860" />
          </linearGradient>
        </defs>

        {/* ===== TOP FRINGE ===== */}
        {fringeData.map((_, i) => (
          <rect key={`tf${i}`} x={i * 8 + 4} y="0" width="1.6" height="28" fill="url(#fg)" opacity="0.85" />
        ))}

        {/* ===== RUG BODY ===== */}
        <rect x="0" y="28" width={W} height="1044" fill="url(#weave)" />

        {/* ===== OUTER RED BORDER WITH CHEVRON ===== */}
        {/* Top */}
        <polygon points="0,28 800,28 800,75 0,75" fill={C.red} />
        {/* Bottom */}
        <polygon points="0,1025 800,1025 800,1072 0,1072" fill={C.red} />
        {/* Left */}
        <polygon points="0,28 40,28 40,1072 0,1072" fill={C.red} />
        {/* Right */}
        <polygon points="760,28 800,28 800,1072 760,1072" fill={C.red} />

        {/* Yellow inner line on border */}
        <rect x="40" y="75" width="720" height="950" fill="none" stroke={C.yellow} strokeWidth="5" />

        {/* Dark brown chevron/zigzag line */}
        <rect x="48" y="83" width="704" height="934" fill="none" stroke={C.darkBrown} strokeWidth="2" />

        {/* Green triangles in corners of red border */}
        {[
          "0,28 40,28 0,68",
          "800,28 760,28 800,68",
          "0,1072 40,1072 0,1032",
          "800,1072 760,1072 800,1032",
        ].map((pts, i) => (
          <polygon key={`gc${i}`} points={pts} fill={C.darkGreen} />
        ))}

        {/* Blue rectangles in border corners */}
        {[
          { x: 8, y: 38, w: 22, h: 18 },
          { x: 770, y: 38, w: 22, h: 18 },
          { x: 8, y: 1044, w: 22, h: 18 },
          { x: 770, y: 1044, w: 22, h: 18 },
        ].map((r, i) => (
          <rect key={`br${i}`} x={r.x} y={r.y} width={r.w} height={r.h} fill={C.blue} />
        ))}

        {/* ===== INNER FIELD ===== */}
        <rect x="52" y="87" width="696" height="926" fill="url(#weave)" />

        {/* Inner border line */}
        <rect x="52" y="87" width="696" height="926" fill="none" stroke={C.darkBrown} strokeWidth="1" />

        {/* ===== CORNER SPANDRELS ===== */}
        {[
          { ox: 52, oy: 87, sx: 1, sy: 1 },
          { ox: 748, oy: 87, sx: -1, sy: 1 },
          { ox: 52, oy: 1013, sx: 1, sy: -1 },
          { ox: 748, oy: 1013, sx: -1, sy: -1 },
        ].map((c, ci) => (
          <g key={`cs${ci}`} transform={`translate(${c.ox},${c.oy}) scale(${c.sx},${c.sy})`}>
            {/* Red triangle */}
            <polygon points="0,0 120,0 0,120" fill={C.red} opacity="0.85" />
            {/* Yellow inner triangle */}
            <polygon points="5,5 90,5 5,90" fill={C.yellow} opacity="0.7" />
            {/* Dark brown outline triangle */}
            <polygon points="10,10 80,10 10,80" fill="none" stroke={C.darkBrown} strokeWidth="1.5" />
            {/* Red inner triangle */}
            <polygon points="15,15 65,15 15,65" fill={C.red} opacity="0.6" />
            {/* Brown inner */}
            <polygon points="20,20 50,20 20,50" fill={C.darkBrown} opacity="0.5" />

            {/* Blue square */}
            <rect x="70" y="8" width="12" height="12" fill={C.blue} stroke={C.darkBrown} strokeWidth="0.5" />
            <rect x="8" y="70" width="12" height="12" fill={C.blue} stroke={C.darkBrown} strokeWidth="0.5" />

            {/* Chevron pattern along diagonal */}
            {Array.from({ length: 5 }).map((_, j) => {
              const px = 25 + j * 16;
              const py = 25 + j * 16;
              return (
                <g key={j}>
                  <line x1={px + 65 - j * 12} y1={py - 15 + j * 1} x2={px + 70 - j * 12} y2={py - 10 + j * 1} stroke={C.darkBrown} strokeWidth="0.8" />
                </g>
              );
            })}

            {/* Scattered dots */}
            <circle cx="95" cy="25" r="2" fill={C.black} />
            <circle cx="25" cy="95" r="2" fill={C.black} />
            <circle cx="100" cy="35" r="1.5" fill={C.yellow} />
            <circle cx="35" cy="100" r="1.5" fill={C.yellow} />

            {/* Leaf branch along corner */}
            <Branch x={85} y={85} angle={-135} s={0.6} />
          </g>
        ))}

        {/* ===== LEAF BRANCHES RADIATING FROM CENTER ===== */}
        {Array.from({ length: 16 }).map((_, i) => {
          const a = (i * 360) / 16;
          const rad = (a * Math.PI) / 180;
          return (
            <Branch key={`br${i}`} x={CX + Math.cos(rad) * 200} y={CY + Math.sin(rad) * 200} angle={a + 90} s={0.85} />
          );
        })}

        {/* Extra branches between main ones */}
        {Array.from({ length: 16 }).map((_, i) => {
          const a = (i * 360) / 16 + 11.25;
          const rad = (a * Math.PI) / 180;
          return (
            <Branch key={`br2${i}`} x={CX + Math.cos(rad) * 185} y={CY + Math.sin(rad) * 185} angle={a + 90} s={0.55} />
          );
        })}

        {/* ===== OUTER CIRCLE ===== */}
        <circle cx={CX} cy={CY} r="170" fill="none" stroke={C.cream} strokeWidth="5" />
        <circle cx={CX} cy={CY} r="167" fill="none" stroke={C.darkBrown} strokeWidth="1" />

        {/* ===== OUTER DIAMOND BAND ===== */}
        <DiamondBand cx={CX} cy={CY} r={158} count={52} size={9} />

        {/* ===== RADIATING TRIANGLES ===== */}
        {outerTriangles.map((t, i) => (
          <g key={`ot${i}`} transform={`translate(${t.x},${t.y}) rotate(${t.a + 90})`}>
            {/* Outer triangle */}
            <polygon points="0,-32 -16,10 16,10" fill={t.cs[0]} stroke={C.darkBrown} strokeWidth="0.8" />
            {/* Middle triangle */}
            <polygon points="0,-24 -11,6 11,6" fill={t.cs[1]} />
            {/* Inner triangle */}
            <polygon points="0,-16 -7,3 7,3" fill={t.cs[2]} />
            {/* Tiny leaf on top */}
            <Branch x={0} y={-34} angle={0} s={0.35} />
          </g>
        ))}

        {/* ===== INNER CIRCLE ===== */}
        <circle cx={CX} cy={CY} r="138" fill="none" stroke={C.darkBrown} strokeWidth="1" />
        <circle cx={CX} cy={CY} r="134" fill="none" stroke={C.skyBlue} strokeWidth="2" />

        {/* ===== INNER DIAMOND BAND ===== */}
        <DiamondBand cx={CX} cy={CY} r={126} count={40} size={8} />

        <circle cx={CX} cy={CY} r="116" fill="none" stroke={C.darkBrown} strokeWidth="1" />

        {/* ===== INNER WHITE CIRCLE ===== */}
        <circle cx={CX} cy={CY} r="114" fill={C.cream} />
        <circle cx={CX} cy={CY} r="114" fill="none" stroke={C.skyBlue} strokeWidth="1.5" />

        {/* ===== CENTER STAR MOTIF ===== */}
        <g transform={`translate(${CX},${CY})`}>
          {/* Cardinal star points - brown diamond shapes */}
          {[0, 90, 180, 270].map((a) => (
            <g key={`cp${a}`} transform={`rotate(${a})`}>
              {/* Outer brown triangle */}
              <polygon points="0,-75 -20,-28 20,-28" fill={C.darkBrown} stroke={C.darkBrown} strokeWidth="0.5" />
              {/* Orange inner */}
              <polygon points="0,-65 -14,-30 14,-30" fill={C.orange} />
              {/* Brown inner line */}
              <polygon points="0,-55 -9,-32 9,-32" fill={C.darkBrown} opacity="0.6" />
              {/* Leaf from tip */}
              <Branch x={0} y={-78} angle={0} s={0.4} />
            </g>
          ))}

          {/* Diagonal star points */}
          {[45, 135, 225, 315].map((a) => (
            <g key={`dp${a}`} transform={`rotate(${a})`}>
              <polygon points="0,-60 -14,-25 14,-25" fill={C.darkBrown} />
              <polygon points="0,-50 -9,-27 9,-27" fill={C.skyBlue} />
              <Branch x={0} y={-63} angle={0} s={0.3} />
            </g>
          ))}

          {/* Center yellow square */}
          <rect x="-30" y="-30" width="60" height="60" fill={C.yellow} stroke={C.darkBrown} strokeWidth="2" />

          {/* Brown diamond overlay on square */}
          <polygon points="0,-30 -30,0 0,30 30,0" fill="none" stroke={C.darkBrown} strokeWidth="2" />

          {/* Top row triangles inside square */}
          <polygon points="-18,-25 -8,-5 -28,-5" fill={C.pink} opacity="0.8" />
          <polygon points="0,-25 -10,-5 10,-5" fill={C.red} opacity="0.8" />
          <polygon points="18,-25 8,-5 28,-5" fill={C.pink} opacity="0.8" />

          {/* Bottom row triangles inside square (pointing up) */}
          <polygon points="-18,25 -8,5 -28,5" fill={C.red} opacity="0.8" />
          <polygon points="0,25 -10,5 10,5" fill={C.pink} opacity="0.8" />
          <polygon points="18,25 8,5 28,5" fill={C.red} opacity="0.8" />

          {/* Small brown chevron above and below */}
          <polygon points="0,-18 -5,-10 5,-10" fill={C.darkBrown} opacity="0.5" />
          <polygon points="0,18 -5,10 5,10" fill={C.darkBrown} opacity="0.5" />

          {/* Dots around center */}
          {[
            [-35, -35], [35, -35], [-35, 35], [35, 35],
            [-40, 0], [40, 0], [0, -40], [0, 40],
          ].map(([dx, dy], i) => (
            <circle key={`cd${i}`} cx={dx} cy={dy} r="2" fill={C.black} />
          ))}

          {/* Pair dots further out */}
          {[
            [-55, -55], [55, -55], [-55, 55], [55, 55],
          ].map(([dx, dy], i) => (
            <g key={`pd${i}`}>
              <circle cx={dx} cy={dy} r="2" fill={C.black} />
              <circle cx={dx + 8} cy={dy} r="2" fill={C.black} />
            </g>
          ))}
        </g>

        {/* ===== SMALL TEAL SQUARES AROUND MEDALLION ===== */}
        {Array.from({ length: 8 }).map((_, i) => {
          const a = (i * 360) / 8 + 22.5;
          const rad = (a * Math.PI) / 180;
          const d = 145;
          const x = CX + Math.cos(rad) * d;
          const y = CY + Math.sin(rad) * d;
          return (
            <rect key={`ts${i}`} x={x - 4} y={y - 4} width="8" height="8" fill={C.skyBlue} stroke={C.darkBrown} strokeWidth="0.5" />
          );
        })}

        {/* ===== SCATTERED FIELD DOTS ===== */}
        {[
          { x: 120, y: 150 }, { x: 680, y: 150 },
          { x: 120, y: 950 }, { x: 680, y: 950 },
          { x: 200, y: 200 }, { x: 600, y: 200 },
          { x: 200, y: 900 }, { x: 600, y: 900 },
          { x: 150, y: 550 }, { x: 650, y: 550 },
          { x: 400, y: 200 }, { x: 400, y: 900 },
          { x: 300, y: 300 }, { x: 500, y: 300 },
          { x: 300, y: 800 }, { x: 500, y: 800 },
          { x: 250, y: 450 }, { x: 550, y: 450 },
          { x: 250, y: 650 }, { x: 550, y: 650 },
        ].map((d, i) => (
          <g key={`fd${i}`}>
            <circle cx={d.x} cy={d.y} r="2" fill={C.black} />
            <circle cx={d.x + 6} cy={d.y + 3} r="2" fill={C.black} />
          </g>
        ))}

        {/* Small red diamonds scattered */}
        {[
          { x: 170, y: 250 }, { x: 630, y: 250 },
          { x: 170, y: 850 }, { x: 630, y: 850 },
          { x: 130, y: 400 }, { x: 670, y: 400 },
          { x: 130, y: 700 }, { x: 670, y: 700 },
        ].map((d, i) => (
          <rect key={`rd${i}`} x={d.x - 4} y={d.y - 4} width="8" height="8" fill={C.red} transform={`rotate(45,${d.x},${d.y})`} />
        ))}

        {/* Small yellow dots */}
        {[
          { x: 100, y: 180 }, { x: 700, y: 180 },
          { x: 100, y: 920 }, { x: 700, y: 920 },
          { x: 180, y: 130 }, { x: 620, y: 130 },
          { x: 180, y: 970 }, { x: 620, y: 970 },
        ].map((d, i) => (
          <circle key={`yd${i}`} cx={d.x} cy={d.y} r="3" fill={C.yellow} />
        ))}

        {/* ===== LEAF PATTERNS ALONG EDGES ===== */}
        {/* Top edge */}
        {Array.from({ length: 12 }).map((_, i) => (
          <Branch key={`te${i}`} x={100 + i * 52} y={100} angle={180} s={0.5} />
        ))}
        {/* Bottom edge */}
        {Array.from({ length: 12 }).map((_, i) => (
          <Branch key={`be${i}`} x={100 + i * 52} y={1000} angle={0} s={0.5} />
        ))}
        {/* Left edge */}
        {Array.from({ length: 14 }).map((_, i) => (
          <Branch key={`le${i}`} x={70} y={130 + i * 60} angle={90} s={0.45} />
        ))}
        {/* Right edge */}
        {Array.from({ length: 14 }).map((_, i) => (
          <Branch key={`re${i}`} x={730} y={130 + i * 60} angle={-90} s={0.45} />
        ))}

        {/* ===== BORDER DIAMOND DECORATIONS ===== */}
        {Array.from({ length: 18 }).map((_, i) => {
          const cols = [C.red, C.blue, C.yellow, C.green, C.orange, C.teal];
          return (
            <g key={`bdd${i}`}>
              <rect x={80 + i * 37} y="40" width="6" height="6" fill={cols[i % 6]} transform={`rotate(45,${83 + i * 37},43)`} />
              <rect x={80 + i * 37} y="1053" width="6" height="6" fill={cols[i % 6]} transform={`rotate(45,${83 + i * 37},1056)`} />
            </g>
          );
        })}

        {/* ===== BOTTOM FRINGE ===== */}
        {fringeData.map((_, i) => (
          <rect key={`bf${i}`} x={i * 8 + 4} y="1072" width="1.6" height="28" fill="url(#fg)" opacity="0.85" />
        ))}

        {/* Subtle texture */}
        <rect x="0" y="28" width={W} height="1044" fill="black" opacity="0.01" />
      </svg>
    </div>
  );
}
