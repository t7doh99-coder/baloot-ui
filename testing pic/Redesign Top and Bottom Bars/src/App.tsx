import { useState, useEffect, useRef } from "react"

const VIOLATIONS = [
  { id: "cut", label: "Cut", arabic: "قاطعة", icon: "✂" },
  { id: "four-double", label: "Four in Double", arabic: "ربع في الدبل", icon: "♦" },
  { id: "no-overtrump", label: "Didn't Over-Trump", arabic: "ما كبر بحكم", icon: "♠" },
  { id: "no-trump", label: "Didn't Trump", arabic: "ما دق بحكم", icon: "♣" },
]

const INSTRUCTION = {
  1: "Choose the card that was cheated with",
  2: "Now choose the violation type below",
  3: "Ready — Press Challenge to submit",
}

function Divider({ label }: { label: string }) {
  return (
    <div className="flex items-center gap-3 w-full">
      <div className="flex-1 h-px" style={{ background: "linear-gradient(90deg, transparent, #3d2410)" }} />
      <span className="text-[10px] font-semibold tracking-[0.2em] uppercase" style={{ color: "#6b4a2a" }}>
        {label}
      </span>
      <div className="flex-1 h-px" style={{ background: "linear-gradient(90deg, #3d2410, transparent)" }} />
    </div>
  )
}

function TopPanel({
  step,
  selectedViolation,
  cardSelected,
  onViolationClick,
  onToggleCard,
}: {
  step: 1 | 2 | 3
  selectedViolation: string | null
  cardSelected: boolean
  onViolationClick: (id: string) => void
  onToggleCard: () => void
}) {
  const isReady = step === 3

  return (
    <div
      className="w-full flex flex-col gap-4 px-4 pt-4 pb-5"
      style={{
        background: "linear-gradient(180deg, #221509 0%, #160e05 100%)",
        borderBottom: "1px solid #3d2410",
        boxShadow: "0 6px 32px #00000077",
      }}
    >
      {/* Centered "Violation Type" heading */}
      <div className="flex flex-col items-center gap-1 pt-1">
        <div className="flex items-center gap-3">
          <div className="w-10 h-px" style={{ background: "linear-gradient(90deg, transparent, #d4a843aa)" }} />
          <span
            className="text-xs font-bold tracking-[0.25em] uppercase"
            style={{ color: "#d4a84399" }}
          >
            Select
          </span>
          <div className="w-10 h-px" style={{ background: "linear-gradient(90deg, #d4a843aa, transparent)" }} />
        </div>
        <h2
          className="text-xl font-extrabold tracking-wide"
          style={{
            color: "#d4a843",
            textShadow: "0 0 20px #d4a84366, 0 2px 4px #00000099",
          }}
        >
          Violation Type
        </h2>
      </div>

      {/* 4 Violation boxes */}
      <div className="grid grid-cols-4 gap-2.5">
        {VIOLATIONS.map((v) => {
          const selected = selectedViolation === v.id
          return (
            <button
              key={v.id}
              onClick={() => onViolationClick(v.id)}
              className="flex flex-col items-center justify-center gap-1.5 py-4 rounded-2xl transition-all duration-200 active:scale-95"
              style={
                selected
                  ? {
                      background: "linear-gradient(160deg, #3d2800 0%, #2a1c00 50%, #1e1400 100%)",
                      border: "2px solid #d4a843",
                      boxShadow: "0 0 16px 3px #d4a84344, inset 0 1px 0 #f0ca6022, 0 4px 12px #00000055",
                    }
                  : {
                      background: "linear-gradient(160deg, #2a1a08 0%, #1e1108 100%)",
                      border: "2px solid #3d2410",
                      boxShadow: "inset 0 1px 0 #ffffff08, 0 2px 8px #00000044",
                    }
              }
            >
              <span
                className="text-xl leading-none transition-all duration-200"
                style={{ color: selected ? "#f0ca60" : "#6b4a2a" }}
              >
                {v.icon}
              </span>
              <span
                className="text-[11px] font-bold text-center leading-tight px-1 transition-colors duration-200"
                style={{ color: selected ? "#f0ca60" : "#a07850" }}
              >
                {v.label}
              </span>
            </button>
          )
        })}
      </div>

      {/* Information box */}
      <div
        key={step}
        className="fade-in flex items-center gap-3 px-4 py-3 rounded-xl w-full"
        style={{
          background: isReady
            ? "linear-gradient(135deg, #0a2e16 0%, #0d2519 100%)"
            : "linear-gradient(135deg, #2a0d0d 0%, #1e0a0a 100%)",
          border: `1.5px solid ${isReady ? "#4ade8066" : "#e0353566"}`,
          boxShadow: isReady
            ? "0 0 12px #4ade8022, inset 0 1px 0 #4ade8011"
            : "0 0 12px #e0353522, inset 0 1px 0 #e0353511",
        }}
      >
        <div
          className="flex-shrink-0 w-6 h-6 rounded-full flex items-center justify-center text-xs font-black"
          style={{
            background: isReady ? "#4ade8022" : "#e0353522",
            color: isReady ? "#4ade80" : "#e03535",
            border: `1px solid ${isReady ? "#4ade8066" : "#e0353566"}`,
          }}
        >
          {isReady ? "✓" : "!"}
        </div>
        <span
          className="text-sm font-semibold leading-snug transition-colors duration-300"
          style={{ color: isReady ? "#a7f3c0" : "#f5a0a0" }}
        >
          {INSTRUCTION[step]}
        </span>
      </div>

      {/* Demo toggle */}
      <div className="flex justify-center -mt-1">
        <button
          onClick={onToggleCard}
          className="flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium transition-all duration-200"
          style={{
            background: cardSelected ? "#1a3320" : "#1e1108",
            border: `1px solid ${cardSelected ? "#4ade8055" : "#3d2410"}`,
            color: cardSelected ? "#4ade80" : "#6b4a2a",
          }}
        >
          <span
            className="w-3 h-3 rounded-full border flex items-center justify-center text-[8px]"
            style={{
              borderColor: cardSelected ? "#4ade80" : "#6b4a2a",
              background: cardSelected ? "#4ade8033" : "transparent",
            }}
          >
            {cardSelected ? "✓" : ""}
          </span>
          Simulate card selected
        </button>
      </div>
    </div>
  )
}

function CircularTimer({ timeLeft }: { timeLeft: number }) {
  const radius = 22
  const circumference = 2 * Math.PI * radius
  const offset = circumference * (1 - timeLeft / 60)
  const color = timeLeft > 30 ? "#d4a843" : timeLeft > 10 ? "#f59e0b" : "#ef4444"

  return (
    <div className="relative flex items-center justify-center" style={{ width: 56, height: 56 }}>
      <svg width="56" height="56" style={{ transform: "rotate(-90deg)", position: "absolute" }}>
        <circle cx="28" cy="28" r={radius} fill="none" stroke="#2a1a08" strokeWidth="4.5" />
        <circle
          cx="28" cy="28" r={radius}
          fill="none"
          stroke={color}
          strokeWidth="4.5"
          strokeLinecap="round"
          strokeDasharray={circumference}
          strokeDashoffset={offset}
          style={{ transition: "stroke-dashoffset 0.9s linear, stroke 0.5s ease" }}
        />
      </svg>
      <span className="relative text-sm font-bold z-10" style={{ color, transition: "color 0.5s ease" }}>
        {timeLeft}
      </span>
    </div>
  )
}

function BottomBar({
  isReady,
  submitted,
  selectedViolation,
  timeLeft,
  onChallenge,
  onClose,
}: {
  isReady: boolean
  submitted: boolean
  selectedViolation: string | null
  timeLeft: number
  onChallenge: () => void
  onClose: () => void
}) {
  return (
    <div
      className="w-full flex flex-col gap-3 px-4 py-4"
      style={{
        background: "linear-gradient(0deg, #221509 0%, #160e05 100%)",
        borderTop: "1px solid #3d2410",
        boxShadow: "0 -6px 32px #00000077",
      }}
    >
      {/* Centered Challenger info */}
      {!submitted ? (
        <div className="flex items-center justify-center">
          <div
            className="flex items-center gap-2 px-5 py-2 rounded-full"
            style={{
              background: "linear-gradient(135deg, #2a1a08 0%, #1e1108 100%)",
              border: "1.5px solid #3d2410",
              boxShadow: "inset 0 1px 0 #ffffff0a, 0 2px 8px #00000044",
            }}
          >
            <span className="text-sm" style={{ color: "#6b4a2a" }}>⚔</span>
            <span className="text-xs font-medium" style={{ color: "#a07850" }}>Challenger:</span>
            <span className="text-sm font-bold" style={{ color: "#f5e6c8" }}>Player</span>
          </div>
        </div>
      ) : (
        <div className="flex items-center justify-center">
          <div
            className="fade-in flex items-center gap-2 px-5 py-2 rounded-full"
            style={{
              background: "linear-gradient(135deg, #0d2519 0%, #0a2010 100%)",
              border: "1.5px solid #4ade8066",
              boxShadow: "0 0 14px #4ade8033",
            }}
          >
            <span className="text-sm" style={{ color: "#4ade80" }}>✓</span>
            <span className="text-xs font-medium" style={{ color: "#6bb88a" }}>Challenge submitted</span>
          </div>
        </div>
      )}

      {/* Action row: button left, timer right */}
      <div className="grid items-center" style={{ gridTemplateColumns: "1fr auto" }}>
        {/* Action button */}
        <div className="flex">
          {submitted ? (
            <div
              key="result"
              className="fade-in glow-green flex items-center gap-2 px-5 py-3 rounded-xl"
              style={{
                background: "linear-gradient(135deg, #0a2e16 0%, #0d2519 100%)",
                border: "2px solid #4ade80",
              }}
            >
              <span className="text-sm font-bold" style={{ color: "#4ade80" }}>✓ Result: Correct</span>
              {selectedViolation && (
                <span
                  className="ml-1 text-xs font-semibold px-2 py-0.5 rounded-full"
                  style={{ background: "#4ade8022", color: "#a7f3c0", border: "1px solid #4ade8044" }}
                >
                  {VIOLATIONS.find((v) => v.id === selectedViolation)?.label}
                </span>
              )}
            </div>
          ) : isReady ? (
            <button
              key="challenge"
              onClick={onChallenge}
              className="fade-in glow-gold flex items-center gap-2 px-7 py-3 rounded-xl font-bold text-sm tracking-wide transition-all duration-200 active:scale-95"
              style={{
                background: "linear-gradient(135deg, #c9860a 0%, #a86c04 100%)",
                border: "2px solid #f0ca60",
                color: "#1a0f03",
              }}
            >
              <span style={{ fontSize: 15 }}>⚔</span>
              Challenge
            </button>
          ) : (
            <button
              key="close"
              onClick={onClose}
              className="fade-in flex items-center gap-2 px-6 py-3 rounded-xl font-semibold text-sm transition-all duration-150 active:scale-95"
              style={{
                background: "linear-gradient(135deg, #e8d5b0 0%, #cdb88a 100%)",
                border: "2px solid #c9a870",
                color: "#3d2200",
                boxShadow: "0 2px 10px #00000044, inset 0 1px 0 #ffffff55",
              }}
            >
              ✕ Close
            </button>
          )}
        </div>

        {/* Timer */}
        {!submitted && <CircularTimer timeLeft={timeLeft} />}
      </div>
    </div>
  )
}

export default function App() {
  const [cardSelected, setCardSelected] = useState(false)
  const [selectedViolation, setSelectedViolation] = useState<string | null>(null)
  const [timeLeft, setTimeLeft] = useState(60)
  const [submitted, setSubmitted] = useState(false)
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null)

  const isReady = cardSelected && selectedViolation !== null
  const step: 1 | 2 | 3 = !cardSelected ? 1 : !selectedViolation ? 2 : 3

  useEffect(() => {
    if (submitted) {
      if (timerRef.current) clearInterval(timerRef.current)
      return
    }
    timerRef.current = setInterval(() => {
      setTimeLeft((t) => {
        if (t <= 1) {
          clearInterval(timerRef.current!)
          return 0
        }
        return t - 1
      })
    }, 1000)
    return () => {
      if (timerRef.current) clearInterval(timerRef.current)
    }
  }, [submitted])

  const handleViolationClick = (id: string) => {
    setSelectedViolation((prev) => (prev === id ? null : id))
  }

  const handleClose = () => {
    setSelectedViolation(null)
    setCardSelected(false)
    setSubmitted(false)
    setTimeLeft(60)
  }

  return (
    <div className="min-h-screen flex flex-col justify-between" style={{ background: "#120904" }}>
      <TopPanel
        step={step}
        selectedViolation={selectedViolation}
        cardSelected={cardSelected}
        onViolationClick={handleViolationClick}
        onToggleCard={() => setCardSelected((v) => !v)}
      />

      <div className="flex-1 flex items-center justify-center">
        <span
          className="text-xs font-semibold tracking-widest uppercase opacity-15"
          style={{ color: "#a07850" }}
        >
          Card selection area
        </span>
      </div>

      <BottomBar
        isReady={isReady}
        submitted={submitted}
        selectedViolation={selectedViolation}
        timeLeft={timeLeft}
        onChallenge={() => { if (timerRef.current) clearInterval(timerRef.current); setSubmitted(true) }}
        onClose={handleClose}
      />
    </div>
  )
}
