const COLUMNS = [
  { key: "todo", label: "To Do" },
  { key: "inprogress", label: "In Progress" },
  { key: "verifying", label: "Verifying" },
  { key: "done", label: "Done" },
];

function classifyCard(tool) {
  if (tool.status === "done") return "done";
  if (tool.status === "running") return "inprogress";
  if (tool.status === "error") return "done"; // error cards go to done column
  return "todo";
}

function columnForCard(tool) {
  if (tool.status === "done") return "done";
  if (tool.status === "error") return "done";
  if (tool.status === "running") return "inprogress";
  return "todo";
}

function formatDuration(ms) {
  if (!ms && ms !== 0) return "";
  if (ms < 1000) return `${ms}ms`;
  return `${(ms / 1000).toFixed(1)}s`;
}

export default function KanbanPanel({ pipelineState }) {
  if (!pipelineState || !pipelineState.iterations || pipelineState.iterations.length === 0) {
    return (
      <div className="cc-kanban" style={{ display: "flex", alignItems: "center", justifyContent: "center" }}>
        <div style={{ color: "var(--text2)", fontStyle: "italic", padding: 40 }}>
          No pipeline data yet...
        </div>
      </div>
    );
  }

  // Collect cards from all iterations
  const cards = [];
  const lastIter = pipelineState.iterations[pipelineState.iterations.length - 1];

  // Add phase cards
  if (lastIter && lastIter.phases) {
    for (const [phaseName, phaseData] of Object.entries(lastIter.phases)) {
      if (phaseData.status === "skipped") continue;
      cards.push({
        id: `phase-${phaseName}`,
        name: phaseName.charAt(0).toUpperCase() + phaseName.slice(1),
        status: phaseData.status,
        durationMs: phaseData.durationMs,
        isPhase: true,
      });
    }
  }

  // Add tool cards
  if (lastIter && lastIter.tools) {
    for (const tool of lastIter.tools) {
      cards.push({
        id: `tool-${tool.name}-${tool.startMs || Math.random()}`,
        name: tool.name,
        status: tool.status,
        durationMs: tool.durationMs,
        isPhase: false,
      });
    }
  }

  // Sort cards into columns
  const columns = {
    todo: [],
    inprogress: [],
    verifying: [],
    done: [],
  };

  for (const card of cards) {
    const col = columnForCard(card);
    columns[col].push(card);
  }

  // Move phases in "gate" that are running to verifying
  const gateCards = columns.inprogress.filter(c => c.isPhase && c.name.toLowerCase() === "gate");
  if (gateCards.length > 0) {
    columns.inprogress = columns.inprogress.filter(c => !(c.isPhase && c.name.toLowerCase() === "gate"));
    columns.verifying.push(...gateCards);
  }

  return (
    <div className="cc-kanban">
      {COLUMNS.map((col) => (
        <div key={col.key} className="cc-kanban-col">
          <div className="cc-kanban-header">
            <span>{col.label}</span>
            <span className="cc-kanban-count">{columns[col.key].length}</span>
          </div>
          {columns[col.key].map((card) => (
            <div
              key={card.id}
              className={`cc-kanban-card ${card.status === "running" ? "running" : ""} ${card.status === "done" ? "done" : ""} ${card.status === "error" ? "error" : ""}`}
            >
              <div className="cc-kanban-tool">{card.name}</div>
              <div className="cc-kanban-meta">
                <span style={{
                  display: "inline-block",
                  width: 6,
                  height: 6,
                  borderRadius: "50%",
                  marginRight: 4,
                  background: card.status === "done" ? "#00e676" : card.status === "running" ? "#00d4ff" : card.status === "error" ? "#ff5252" : "#666",
                }} />
                {card.status}
                {card.durationMs != null && ` \u00B7 ${formatDuration(card.durationMs)}`}
              </div>
            </div>
          ))}
        </div>
      ))}
    </div>
  );
}
