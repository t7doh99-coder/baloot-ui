import { useEffect, useRef, useState } from "react";

type Team = "violet" | "blue" | "red";

function Banner({ team, name, side, onClick, active }: { team: Team; name: string; side: "left" | "right"; onClick: () => void; active: boolean }) {
  return (
    <button
      aria-label={`Select ${name}`}
      onClick={onClick}
      className={`matchup-banner ${team} ${side} ${active ? "selected" : ""}`}
    >
      <span className="banner-core" />
      <span className="banner-sheen" />
      <span className="banner-name">{name}</span>
    </button>
  );
}

function Crest() {
  return (
    <div className="card-crest" aria-label="Versus">
      <span className="card-corner top-corner">A<br />♠</span>
      <strong>VS</strong>
      <span className="card-corner bottom-corner">A<br />♥</span>
      <span className="card-suit suit-left">♣</span>
      <span className="card-suit suit-right">♦</span>
      <i className="card-glint" />
    </div>
  );
}

export default function App() {
  const [selected, setSelected] = useState<string | null>(null);
  const [intro, setIntro] = useState<"ready" | "showing" | "done">("ready");
  const introTimer = useRef<number | undefined>(undefined);

  useEffect(() => () => window.clearTimeout(introTimer.current), []);

  function startRound() {
    window.clearTimeout(introTimer.current);
    setIntro("showing");
    introTimer.current = window.setTimeout(() => setIntro("done"), 3200);
  }

  return (
    <main className="arena-shell">
      <div className={`matchup-scene ${intro}`} aria-hidden={intro === "done"}>
        <div className="top-team">
          <span className="top-name">STröwzy</span>
          <Banner team="violet" name="" side="right" active={selected === "STröwzy"} onClick={() => setSelected("STröwzy")} />
        </div>
        <div className="top-team second">
          <span className="top-name">GRIFFIN BIG</span>
          <Banner team="violet" name="" side="right" active={selected === "GRIFFIN BIG"} onClick={() => setSelected("GRIFFIN BIG")} />
        </div>

        <section className="versus-zone">
          <Crest />
        </section>

        <div className="lower-team blue-row">
          <Banner team="blue" name="" side="left" active={selected === "leone"} onClick={() => setSelected("leone")} />
          <span className="lower-name">leone</span>
        </div>
        <div className="lower-team red-row">
          <Banner team="red" name="" side="left" active={selected === "DEADSHOT_JOK"} onClick={() => setSelected("DEADSHOT_JOK")} />
          <span className="lower-name">DEADSHOT_JOK</span>
        </div>
      </div>
      {intro === "ready" && <button className="play-button" onClick={startRound}>PLAY ROUND</button>}
      {intro === "done" && <button className="round-ready" onClick={startRound}>ROUND 01 · PLAY</button>}
    </main>
  );
}
