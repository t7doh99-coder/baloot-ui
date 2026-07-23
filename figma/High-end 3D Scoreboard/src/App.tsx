import { useState, useEffect, useMemo } from 'react'

// ─── Data ─────────────────────────────────────────────────────────────────────

const GAME = { type: 'Sun', buyer: 'Our Team', outcome: 'Won · Made Threshold' }
const ROWS = [
  { label: 'Tricks',            them: 24,   us: 86  },
  { label: 'Ground',            them: null, us: 10  },
  { label: 'Projects',          them: null, us: null },
  { label: 'Trick pts (cards)', them: 24,   us: 96  },
]
const RESULT = { them: 5, us: 21 }
const MATCH  = { us: 0, them: 0 }

// ─── Count-up hook ────────────────────────────────────────────────────────────

function useCountUp(target: number | null, duration = 1000, delay = 400) {
  const [val, setVal] = useState(0)
  useEffect(() => {
    if (target === null) return
    const id = setTimeout(() => {
      const t0 = performance.now()
      const tick = (now: number) => {
        const p = Math.min((now - t0) / duration, 1)
        const ease = 1 - Math.pow(1 - p, 4)
        setVal(Math.round(ease * target))
        if (p < 1) requestAnimationFrame(tick)
      }
      requestAnimationFrame(tick)
    }, delay)
    return () => clearTimeout(id)
  }, [target, duration, delay])
  return val
}

// ─── Trophy SVG ───────────────────────────────────────────────────────────────

function Trophy({ size = 64 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 64 64" fill="none">
      {/* Cup body */}
      <path
        d="M20 8h24v20c0 8.837-5.373 16-12 16S20 36.837 20 28V8z"
        fill="url(#tg1)"
        stroke="rgba(255,220,100,0.6)"
        strokeWidth="0.8"
      />
      {/* Left handle */}
      <path
        d="M20 14c0 0-8 2-8 10s8 10 8 10"
        stroke="url(#tg2)"
        strokeWidth="3"
        strokeLinecap="round"
        fill="none"
      />
      {/* Right handle */}
      <path
        d="M44 14c0 0 8 2 8 10s-8 10-8 10"
        stroke="url(#tg2)"
        strokeWidth="3"
        strokeLinecap="round"
        fill="none"
      />
      {/* Stem */}
      <rect x="29" y="44" width="6" height="8" fill="url(#tg1)" rx="1" />
      {/* Base */}
      <rect x="22" y="52" width="20" height="4" fill="url(#tg1)" rx="2" />
      {/* Star highlight inside cup */}
      <path
        d="M32 14l1.8 5.5h5.8l-4.7 3.4 1.8 5.5-4.7-3.4-4.7 3.4 1.8-5.5-4.7-3.4h5.8z"
        fill="rgba(255,245,180,0.45)"
      />
      <defs>
        <linearGradient id="tg1" x1="20" y1="8" x2="44" y2="56" gradientUnits="userSpaceOnUse">
          <stop stopColor="#ffe066" />
          <stop offset="0.5" stopColor="#c9a84c" />
          <stop offset="1" stopColor="#7a5200" />
        </linearGradient>
        <linearGradient id="tg2" x1="0" y1="0" x2="0" y2="1" gradientUnits="objectBoundingBox">
          <stop stopColor="#ffe066" />
          <stop offset="1" stopColor="#c9a84c" />
        </linearGradient>
      </defs>
    </svg>
  )
}

// ─── Particles ────────────────────────────────────────────────────────────────

type Particle = { id: number; x: number; y: number; color: string; size: number; delay: number; dur: number; shape: 'circle' | 'star' }

function Particles({ count = 24 }: { count?: number }) {
  const particles = useMemo<Particle[]>(() => {
    const colors = ['#c9a84c','#00e87a','#ff3d3d','#f0d47a','#ffffff','#00e87a','#c9a84c']
    return Array.from({ length: count }, (_, i) => ({
      id: i,
      x: 5 + Math.random() * 90,
      y: 40 + Math.random() * 40,
      color: colors[Math.floor(Math.random() * colors.length)],
      size: 3 + Math.random() * 5,
      delay: Math.random() * 2400,
      dur: 1800 + Math.random() * 1400,
      shape: Math.random() > 0.5 ? 'star' : 'circle',
    }))
  }, [count])

  return (
    <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none', overflow: 'hidden' }}>
      {particles.map(p => (
        <div
          key={p.id}
          style={{
            position: 'absolute',
            left: `${p.x}%`,
            top: `${p.y}%`,
            width: p.size,
            height: p.size,
            borderRadius: p.shape === 'circle' ? '50%' : '1px',
            background: p.color,
            boxShadow: `0 0 ${p.size * 2}px ${p.color}`,
            transform: p.shape === 'star' ? 'rotate(45deg)' : 'none',
            animation: `particleRise ${p.dur}ms ease-out ${p.delay}ms infinite`,
            opacity: 0,
          }}
        />
      ))}
    </div>
  )
}

// ─── HUD corner brackets ─────────────────────────────────────────────────────

function Corner({ pos }: { pos: 'tl' | 'tr' | 'bl' | 'br' }) {
  const size = 18, thick = 2, color = 'rgba(201,168,76,0.55)'
  const h = pos === 'tl' || pos === 'tr'
  const v = pos === 'tl' || pos === 'bl'
  return (
    <div style={{
      position: 'absolute',
      [h ? 'top' : 'bottom']: 0,
      [v ? 'left' : 'right']: 0,
      width: size, height: size,
      borderTop:    (pos === 'tl' || pos === 'tr') ? `${thick}px solid ${color}` : 'none',
      borderBottom: (pos === 'bl' || pos === 'br') ? `${thick}px solid ${color}` : 'none',
      borderLeft:   (pos === 'tl' || pos === 'bl') ? `${thick}px solid ${color}` : 'none',
      borderRight:  (pos === 'tr' || pos === 'br') ? `${thick}px solid ${color}` : 'none',
    }} />
  )
}

// ─── Score Number ─────────────────────────────────────────────────────────────

function HeroScore({ value, side, delay }: { value: number; side: 'them' | 'us'; delay: number }) {
  const animated = useCountUp(value, 1200, delay)
  const color = side === 'us' ? '#00e87a' : '#ff3d3d'
  const glow  = side === 'us' ? 'rgba(0,232,122,0.6)' : 'rgba(255,61,61,0.6)'
  return (
    <div style={{
      fontSize: 'clamp(4rem, 14vw, 6.5rem)',
      fontWeight: 900,
      lineHeight: 1,
      color,
      textShadow: `0 0 30px ${glow}, 0 0 60px ${glow}, 0 4px 0 rgba(0,0,0,0.6)`,
      fontVariantNumeric: 'tabular-nums',
      letterSpacing: '-0.04em',
      animation: `numberPop 0.6s cubic-bezier(0.16,1,0.3,1) ${delay}ms both`,
      animationName: side === 'us' ? 'numberPop, victoryPulse' : 'numberPop, defeatPulse',
      animationDuration: side === 'us' ? `0.6s, 2.6s` : `0.6s, 3.2s`,
      animationDelay: side === 'us' ? `${delay}ms, ${delay + 700}ms` : `${delay}ms, ${delay + 400}ms`,
      animationTimingFunction: 'cubic-bezier(0.16,1,0.3,1), ease-in-out',
      animationFillMode: 'both, none',
      animationIterationCount: '1, infinite',
    }}>
      {animated}
    </div>
  )
}

// ─── Table row ────────────────────────────────────────────────────────────────

function StatRow({ label, them, us, index }: { label: string; them: number | null; us: number | null; index: number }) {
  const tVal = useCountUp(them, 800, 600 + index * 80)
  const uVal = useCountUp(us,   800, 660 + index * 80)

  const cell = (val: number | null, counted: number, color: string, glow: string) => {
    if (val === null) return <span style={{ color: '#3a3428', fontSize: '1.1rem', fontWeight: 700 }}>—</span>
    return (
      <span style={{
        color,
        textShadow: `0 0 10px ${glow}`,
        fontWeight: 800,
        fontSize: '1.1rem',
        fontVariantNumeric: 'tabular-nums',
      }}>
        {counted}
      </span>
    )
  }

  return (
    <div style={{
      display: 'grid',
      gridTemplateColumns: '1fr 80px 80px',
      alignItems: 'center',
      padding: '11px 20px',
      borderBottom: '1px solid rgba(201,168,76,0.07)',
      animation: `rowIn 0.45s ease ${560 + index * 70}ms both`,
      position: 'relative',
    }}>
      {/* row left accent on hover — handled via inline style trick */}
      <span style={{
        color: '#7a6a48',
        fontSize: '0.82rem',
        fontFamily: 'sans-serif',
        fontWeight: 500,
        letterSpacing: '0.03em',
        textTransform: 'uppercase',
      }}>
        {label}
      </span>
      <span style={{ textAlign: 'center' }}>
        {cell(them, tVal, '#ff3d3d', 'rgba(255,61,61,0.55)')}
      </span>
      <span style={{ textAlign: 'center' }}>
        {cell(us, uVal, '#00e87a', 'rgba(0,232,122,0.55)')}
      </span>
    </div>
  )
}

// ─── Main ─────────────────────────────────────────────────────────────────────

export default function App() {
  const [ready, setReady] = useState(false)

  useEffect(() => {
    const t = setTimeout(() => setReady(true), 60)
    return () => clearTimeout(t)
  }, [])

  if (!ready) return <div style={{ background: '#080603', minHeight: '100vh' }} />

  return (
    <div style={{
      minHeight: '100vh',
      background: '#080603',
      backgroundImage: [
        'radial-gradient(ellipse 90% 50% at 50% 0%, rgba(40,28,6,0.9) 0%, transparent 60%)',
        'radial-gradient(ellipse 60% 40% at 20% 100%, rgba(255,61,61,0.06) 0%, transparent 50%)',
        'radial-gradient(ellipse 60% 40% at 80% 100%, rgba(0,232,122,0.06) 0%, transparent 50%)',
      ].join(', '),
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '20px 16px',
      position: 'relative',
      overflow: 'hidden',
    }}>

      {/* Ambient scan line */}
      <div style={{
        position: 'fixed',
        top: 0, left: 0, right: 0,
        height: '2px',
        background: 'linear-gradient(90deg, transparent, rgba(201,168,76,0.15), transparent)',
        animation: 'scanline 6s linear infinite',
        pointerEvents: 'none',
        zIndex: 0,
      }} />

      {/* Main scoreboard container */}
      <div style={{
        position: 'relative',
        zIndex: 1,
        width: '100%',
        maxWidth: '440px',
        animation: 'fadeDown 0.5s ease both',
      }}>

        {/* ── Championship banner strip ── */}
        <div style={{
          textAlign: 'center',
          marginBottom: '10px',
          animation: 'fadeDown 0.4s ease 60ms both',
        }}>
          <div style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '8px',
            padding: '4px 18px',
            borderRadius: '2px',
            background: 'linear-gradient(90deg, transparent, rgba(201,168,76,0.12), rgba(201,168,76,0.18), rgba(201,168,76,0.12), transparent)',
            border: '1px solid rgba(201,168,76,0.2)',
          }}>
            <span style={{ color: 'rgba(201,168,76,0.5)', fontSize: '0.55rem', letterSpacing: '0.35em', fontFamily: 'sans-serif', textTransform: 'uppercase' }}>
              ✦ Game: {GAME.type} &nbsp;·&nbsp; Buyer: {GAME.buyer} ✦
            </span>
          </div>
        </div>

        {/* ── Title ── */}
        <div style={{ textAlign: 'center', marginBottom: '6px' }}>
          <h1 style={{
            margin: 0,
            fontSize: 'clamp(1.6rem, 6vw, 2.4rem)',
            fontWeight: 700,
            background: 'linear-gradient(90deg, #7a5200, #f0d47a, #c9a84c, #ffe066, #c9a84c, #7a5200)',
            backgroundSize: '300% auto',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
            backgroundClip: 'text',
            animation: 'goldShimmer 4s linear infinite',
            letterSpacing: '0.18em',
            textTransform: 'uppercase',
          }}>
            Scoreboard
          </h1>
        </div>

        {/* ── Hero panel — split rivalry ── */}
        <div style={{
          position: 'relative',
          display: 'grid',
          gridTemplateColumns: '1fr auto 1fr',
          alignItems: 'center',
          margin: '8px 0 0',
          borderRadius: '4px 4px 0 0',
          overflow: 'hidden',
          background: 'linear-gradient(180deg, #0e0b05 0%, #080603 100%)',
          border: '1px solid rgba(201,168,76,0.25)',
          borderBottom: 'none',
          padding: '28px 0 24px',
          clipPath: 'polygon(0 0, calc(100% - 14px) 0, 100% 14px, 100% 100%, 14px 100%, 0 calc(100% - 0px))',
        }}>

          <Particles count={28} />

          {/* Top border shimmer */}
          <div style={{
            position: 'absolute', top: 0, left: 0, right: 0, height: '2px',
            background: 'linear-gradient(90deg, transparent 0%, #ff3d3d 25%, #c9a84c 50%, #00e87a 75%, transparent 100%)',
            backgroundSize: '200% auto',
            animation: 'goldShimmer 3s linear infinite',
          }} />

          {/* THEM side */}
          <div style={{
            textAlign: 'center',
            padding: '0 16px',
            animation: 'slideRight 0.5s ease 100ms both',
          }}>
            <div style={{
              color: '#ff3d3d',
              fontSize: '0.62rem',
              fontFamily: 'sans-serif',
              fontWeight: 700,
              letterSpacing: '0.3em',
              textTransform: 'uppercase',
              textShadow: '0 0 10px rgba(255,61,61,0.6)',
              marginBottom: '12px',
            }}>Them</div>
            <HeroScore value={RESULT.them} side="them" delay={300} />
            <div style={{
              marginTop: '10px',
              fontSize: '0.62rem',
              color: 'rgba(255,61,61,0.45)',
              fontFamily: 'sans-serif',
              letterSpacing: '0.12em',
            }}>POINTS</div>
          </div>

          {/* Center trophy */}
          <div style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: '0',
            padding: '0 8px',
          }}>
            {/* Vertical divider lines */}
            <div style={{
              position: 'absolute',
              top: 0, bottom: 0,
              left: '50%',
              width: '1px',
              background: 'linear-gradient(180deg, transparent, rgba(201,168,76,0.35), transparent)',
              transform: 'translateX(-50%)',
              pointerEvents: 'none',
            }} />

            <div style={{
              animation: 'troFloat 3.2s ease-in-out infinite',
              filter: 'drop-shadow(0 0 16px rgba(201,168,76,0.7)) drop-shadow(0 0 32px rgba(201,168,76,0.3))',
            }}>
              <Trophy size={56} />
            </div>
            <div style={{
              marginTop: '6px',
              fontSize: '0.55rem',
              color: 'rgba(201,168,76,0.55)',
              fontFamily: 'sans-serif',
              letterSpacing: '0.2em',
              textAlign: 'center',
              textTransform: 'uppercase',
              whiteSpace: 'nowrap',
            }}>VS</div>
          </div>

          {/* US side */}
          <div style={{
            textAlign: 'center',
            padding: '0 16px',
            animation: 'slideLeft 0.5s ease 100ms both',
          }}>
            <div style={{
              color: '#00e87a',
              fontSize: '0.62rem',
              fontFamily: 'sans-serif',
              fontWeight: 700,
              letterSpacing: '0.3em',
              textTransform: 'uppercase',
              textShadow: '0 0 10px rgba(0,232,122,0.6)',
              marginBottom: '12px',
            }}>Us</div>
            <HeroScore value={RESULT.us} side="us" delay={380} />
            <div style={{
              marginTop: '10px',
              fontSize: '0.62rem',
              color: 'rgba(0,232,122,0.45)',
              fontFamily: 'sans-serif',
              letterSpacing: '0.12em',
            }}>POINTS</div>
          </div>
        </div>

        {/* Victory ribbon */}
        <div style={{
          display: 'flex',
          justifyContent: 'flex-end',
          background: 'linear-gradient(90deg, transparent 0%, rgba(0,232,122,0.08) 30%, rgba(0,232,122,0.14) 100%)',
          borderLeft: '1px solid rgba(201,168,76,0.15)',
          borderRight: '1px solid rgba(201,168,76,0.15)',
          padding: '7px 16px',
          animation: 'rowIn 0.4s ease 480ms both',
        }}>
          <span style={{
            color: '#00e87a',
            fontSize: '0.72rem',
            fontFamily: 'sans-serif',
            fontWeight: 700,
            letterSpacing: '0.08em',
            textShadow: '0 0 12px rgba(0,232,122,0.5)',
          }}>
            ✦ {GAME.outcome}
          </span>
        </div>

        {/* ── Stats table ── */}
        <div style={{
          background: '#0c0a06',
          border: '1px solid rgba(201,168,76,0.18)',
          borderTop: 'none',
          borderBottom: 'none',
          position: 'relative',
        }}>
          {/* Column headers */}
          <div style={{
            display: 'grid',
            gridTemplateColumns: '1fr 80px 80px',
            alignItems: 'center',
            padding: '9px 20px',
            borderBottom: '1px solid rgba(201,168,76,0.18)',
            background: 'rgba(201,168,76,0.04)',
            animation: 'rowIn 0.4s ease 520ms both',
          }}>
            <span style={{
              color: 'rgba(201,168,76,0.35)',
              fontSize: '0.6rem',
              fontFamily: 'sans-serif',
              letterSpacing: '0.25em',
              textTransform: 'uppercase',
            }}>Category</span>
            <span style={{
              textAlign: 'center',
              color: '#ff3d3d',
              fontSize: '0.65rem',
              fontFamily: 'sans-serif',
              fontWeight: 700,
              letterSpacing: '0.2em',
              textTransform: 'uppercase',
              textShadow: '0 0 8px rgba(255,61,61,0.5)',
            }}>Them</span>
            <span style={{
              textAlign: 'center',
              color: '#00e87a',
              fontSize: '0.65rem',
              fontFamily: 'sans-serif',
              fontWeight: 700,
              letterSpacing: '0.2em',
              textTransform: 'uppercase',
              textShadow: '0 0 8px rgba(0,232,122,0.5)',
            }}>Us</span>
          </div>

          {ROWS.map((row, i) => (
            <StatRow key={row.label} label={row.label} them={row.them} us={row.us} index={i} />
          ))}
        </div>

        {/* ── Result row ── */}
        <div style={{
          position: 'relative',
          display: 'grid',
          gridTemplateColumns: '1fr 80px 80px',
          alignItems: 'center',
          padding: '16px 20px',
          background: 'linear-gradient(90deg, #0e0b05, #141008, #0e0b05)',
          border: '1px solid rgba(201,168,76,0.35)',
          borderTop: '1px solid rgba(201,168,76,0.4)',
          animation: 'rowIn 0.5s ease 820ms both',
          clipPath: 'polygon(0 0, 100% 0, 100% calc(100% - 10px), calc(100% - 10px) 100%, 0 100%)',
          overflow: 'hidden',
        }}>
          {/* Left gold accent */}
          <div style={{
            position: 'absolute', left: 0, top: 0, bottom: 0, width: '3px',
            background: 'linear-gradient(180deg, transparent, #c9a84c, transparent)',
          }} />
          {/* Background shimmer */}
          <div style={{
            position: 'absolute', inset: 0,
            background: 'linear-gradient(90deg, transparent, rgba(201,168,76,0.04), transparent)',
            backgroundSize: '200% auto',
            animation: 'goldShimmer 3.5s linear infinite',
          }} />

          <span style={{
            color: '#c9a84c',
            fontWeight: 700,
            fontSize: '0.78rem',
            fontFamily: 'sans-serif',
            textShadow: '0 0 12px rgba(201,168,76,0.5)',
            textTransform: 'uppercase',
            letterSpacing: '0.2em',
            position: 'relative',
          }}>
            Result
          </span>
          <span style={{ textAlign: 'center', position: 'relative' }}>
            <span style={{
              color: '#ff3d3d',
              fontWeight: 900,
              fontSize: '1.8rem',
              textShadow: '0 0 20px rgba(255,61,61,0.7), 0 0 40px rgba(255,61,61,0.3)',
              fontVariantNumeric: 'tabular-nums',
              animation: 'defeatPulse 3.2s ease-in-out 1200ms infinite',
            }}>
              {RESULT.them}
            </span>
          </span>
          <span style={{ textAlign: 'center', position: 'relative' }}>
            <span style={{
              color: '#00e87a',
              fontWeight: 900,
              fontSize: '1.8rem',
              textShadow: '0 0 20px rgba(0,232,122,0.7), 0 0 40px rgba(0,232,122,0.3)',
              fontVariantNumeric: 'tabular-nums',
              animation: 'victoryPulse 2.6s ease-in-out 1300ms infinite',
            }}>
              {RESULT.us}
            </span>
          </span>
        </div>

        {/* ── Match footer ── */}
        <div style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          gap: '6px',
          padding: '10px 20px 8px',
          borderLeft: '1px solid rgba(201,168,76,0.18)',
          borderRight: '1px solid rgba(201,168,76,0.18)',
          borderBottom: '1px solid rgba(201,168,76,0.18)',
          borderRadius: '0 0 4px 4px',
          background: 'rgba(0,0,0,0.3)',
          animation: 'fadeUp 0.4s ease 960ms both',
        }}>
          <span style={{
            color: '#3d3520',
            fontSize: '0.6rem',
            fontFamily: 'sans-serif',
            letterSpacing: '0.2em',
            textTransform: 'uppercase',
          }}>
            Match
          </span>
          <span style={{ color: 'rgba(201,168,76,0.2)', fontSize: '0.5rem' }}>·</span>
          <span style={{ color: '#4a6650', fontSize: '0.62rem', fontFamily: 'sans-serif', letterSpacing: '0.08em' }}>
            Us <strong style={{ color: '#00e87a', fontWeight: 700 }}>{MATCH.us}</strong>
          </span>
          <span style={{ color: 'rgba(201,168,76,0.15)', fontSize: '0.5rem' }}>·</span>
          <span style={{ color: '#5a3630', fontSize: '0.62rem', fontFamily: 'sans-serif', letterSpacing: '0.08em' }}>
            Them <strong style={{ color: '#ff3d3d', fontWeight: 700 }}>{MATCH.them}</strong>
          </span>
        </div>

        {/* HUD corners on outer container */}
        <div style={{ position: 'absolute', inset: '-8px', pointerEvents: 'none' }}>
          <Corner pos="tl" />
          <Corner pos="tr" />
          <Corner pos="bl" />
          <Corner pos="br" />
        </div>

      </div>
    </div>
  )
}
