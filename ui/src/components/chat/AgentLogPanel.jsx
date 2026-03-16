import { useRef, useEffect, useState } from "react";

const PHASE_CLASSES = {
  plan: "cc-log-plan",
  gate: "cc-log-gate",
  execute: "cc-log-execute",
  replan: "cc-log-replan",
};

function formatTime(isoStr) {
  try {
    const d = new Date(isoStr);
    return d.toLocaleTimeString("de-DE", { hour: "2-digit", minute: "2-digit", second: "2-digit" });
  } catch {
    return "--:--:--";
  }
}

export default function AgentLogPanel({ logEntries }) {
  const scrollRef = useRef(null);
  const [paused, setPaused] = useState(false);

  useEffect(() => {
    if (!paused && scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [logEntries, paused]);

  if (!logEntries || logEntries.length === 0) {
    return (
      <div className="cc-log-panel">
        <div className="cc-log-empty">Waiting for agent activity...</div>
      </div>
    );
  }

  return (
    <div
      className="cc-log-panel"
      ref={scrollRef}
      onMouseEnter={() => setPaused(true)}
      onMouseLeave={() => setPaused(false)}
    >
      {logEntries.map((entry) => {
        const phaseClass = PHASE_CLASSES[entry.phase] || "";
        return (
          <div key={entry.id} className="cc-log-entry">
            <span className="cc-log-ts">{formatTime(entry.timestamp)}</span>
            {entry.phase && (
              <span className={`cc-log-phase ${phaseClass}`}>{entry.phase}</span>
            )}
            {entry.tool && <span className="cc-log-tool">{entry.tool}</span>}
            {entry.tool && entry.message && <span className="cc-log-msg">&mdash;</span>}
            {entry.message && <span className="cc-log-msg">{entry.message}</span>}
          </div>
        );
      })}
    </div>
  );
}
