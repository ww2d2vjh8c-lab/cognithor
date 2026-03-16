const NODE_W = 140;
const NODE_H = 44;
const LAYER_GAP_X = 180;
const NODE_GAP_Y = 60;

const STATUS_COLORS = {
  pending: { bg: "#23232a", border: "#555", text: "#999" },
  running: { bg: "#0a2a3a", border: "#00d4ff", text: "#00d4ff" },
  done:    { bg: "#0a2a1a", border: "#00e676", text: "#00e676" },
  error:   { bg: "#2a0a0a", border: "#ff5252", text: "#ff5252" },
  skipped: { bg: "#1a1a1f", border: "#444", text: "#666" },
};

/**
 * Kahn's topological sort to arrange steps into layers.
 * If no depends_on data, renders as linear chain.
 */
function layoutDag(steps) {
  if (!steps || steps.length === 0) return { positioned: [], edges: [] };

  // Build adjacency and in-degree
  const nodes = steps.map((s, i) => ({
    id: i,
    tool: s.tool || `Step ${i + 1}`,
    status: s.status || "pending",
    dependsOn: s.depends_on || [],
  }));

  const inDeg = {};
  const adj = {};
  nodes.forEach((n) => {
    inDeg[n.id] = 0;
    adj[n.id] = [];
  });

  let hasDeps = false;
  nodes.forEach((n) => {
    if (n.dependsOn && n.dependsOn.length > 0) {
      hasDeps = true;
      n.dependsOn.forEach((depIdx) => {
        if (adj[depIdx] !== undefined) {
          adj[depIdx].push(n.id);
          inDeg[n.id] = (inDeg[n.id] || 0) + 1;
        }
      });
    }
  });

  // If no dependencies, arrange as linear chain
  if (!hasDeps) {
    const positioned = nodes.map((n, i) => ({
      ...n,
      x: 30 + i * LAYER_GAP_X,
      y: 30,
    }));
    const edges = [];
    for (let i = 0; i < positioned.length - 1; i++) {
      edges.push({ from: positioned[i], to: positioned[i + 1] });
    }
    return { positioned, edges };
  }

  // Kahn's algorithm - group by layers
  const layers = [];
  let queue = nodes.filter((n) => inDeg[n.id] === 0).map((n) => n.id);

  while (queue.length > 0) {
    layers.push([...queue]);
    const next = [];
    for (const id of queue) {
      for (const child of adj[id] || []) {
        inDeg[child]--;
        if (inDeg[child] === 0) next.push(child);
      }
    }
    queue = next;
  }

  // Position nodes
  const nodeMap = {};
  nodes.forEach((n) => { nodeMap[n.id] = n; });
  const positioned = [];

  layers.forEach((layer, li) => {
    const x = 30 + li * LAYER_GAP_X;
    const totalH = layer.length * NODE_H + (layer.length - 1) * (NODE_GAP_Y - NODE_H);
    const startY = Math.max(20, 120 - totalH / 2);
    layer.forEach((id, ni) => {
      const n = nodeMap[id];
      positioned.push({
        ...n,
        x,
        y: startY + ni * NODE_GAP_Y,
      });
    });
  });

  // Build edges
  const posMap = {};
  positioned.forEach((p) => { posMap[p.id] = p; });
  const edges = [];
  nodes.forEach((n) => {
    (n.dependsOn || []).forEach((depId) => {
      if (posMap[depId] && posMap[n.id]) {
        edges.push({ from: posMap[depId], to: posMap[n.id] });
      }
    });
  });

  return { positioned, edges };
}

export default function LiveDagPanel({ pipelineState, currentPlan }) {
  // Build steps from currentPlan or pipelineState
  let steps = [];

  if (currentPlan && currentPlan.steps && currentPlan.steps.length > 0) {
    steps = currentPlan.steps.map((s, i) => {
      // Try to find status from pipelineState tools
      let status = "pending";
      if (pipelineState && pipelineState.iterations) {
        const lastIter = pipelineState.iterations[pipelineState.iterations.length - 1];
        if (lastIter && lastIter.tools) {
          const matchingTool = lastIter.tools.find((t) => t.name === s.tool);
          if (matchingTool) status = matchingTool.status || "pending";
        }
      }
      return {
        tool: s.tool,
        status,
        depends_on: s.depends_on || [],
      };
    });
  } else if (pipelineState && pipelineState.iterations) {
    // Fallback: use tools from pipeline state as linear chain
    const lastIter = pipelineState.iterations[pipelineState.iterations.length - 1];
    if (lastIter && lastIter.tools && lastIter.tools.length > 0) {
      steps = lastIter.tools.map((t) => ({
        tool: t.name,
        status: t.status || "pending",
        depends_on: [],
      }));
    }
  }

  if (steps.length === 0) {
    return (
      <div className="cc-dag-panel">
        <div className="cc-dag-empty">No plan steps to visualize...</div>
      </div>
    );
  }

  const { positioned, edges } = layoutDag(steps);
  if (positioned.length === 0) {
    return (
      <div className="cc-dag-panel">
        <div className="cc-dag-empty">No plan steps to visualize...</div>
      </div>
    );
  }

  const maxX = Math.max(...positioned.map((n) => n.x)) + NODE_W + 40;
  const maxY = Math.max(...positioned.map((n) => n.y)) + NODE_H + 40;

  return (
    <div className="cc-dag-panel">
      <svg width={maxX} height={maxY} style={{ minWidth: maxX, minHeight: maxY }}>
        <defs>
          <marker id="dag-arrow" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
            <path d="M0,0 L8,3 L0,6" fill="#555" />
          </marker>
        </defs>

        {/* Edges */}
        {edges.map((e, i) => {
          const x1 = e.from.x + NODE_W;
          const y1 = e.from.y + NODE_H / 2;
          const x2 = e.to.x;
          const y2 = e.to.y + NODE_H / 2;
          const mx = (x1 + x2) / 2;
          return (
            <path
              key={`edge-${i}`}
              d={`M${x1},${y1} C${mx},${y1} ${mx},${y2} ${x2},${y2}`}
              fill="none"
              stroke="#555"
              strokeWidth={1.5}
              markerEnd="url(#dag-arrow)"
            />
          );
        })}

        {/* Nodes */}
        {positioned.map((n) => {
          const c = STATUS_COLORS[n.status] || STATUS_COLORS.pending;
          return (
            <g key={n.id}>
              <rect
                x={n.x}
                y={n.y}
                width={NODE_W}
                height={NODE_H}
                rx={6}
                fill={c.bg}
                stroke={c.border}
                strokeWidth={n.status === "running" ? 2 : 1.5}
              />
              {n.status === "running" && (
                <rect
                  x={n.x}
                  y={n.y}
                  width={NODE_W}
                  height={NODE_H}
                  rx={6}
                  fill="none"
                  stroke={c.border}
                  strokeWidth={2}
                  strokeDasharray="6 3"
                  opacity={0.5}
                >
                  <animate
                    attributeName="stroke-dashoffset"
                    from="0"
                    to="18"
                    dur="1s"
                    repeatCount="indefinite"
                  />
                </rect>
              )}
              <text
                x={n.x + NODE_W / 2}
                y={n.y + NODE_H / 2 + 1}
                textAnchor="middle"
                dominantBaseline="central"
                fill={c.text}
                fontSize={11}
                fontWeight={600}
                fontFamily="'DM Sans', sans-serif"
              >
                {n.tool.length > 16 ? n.tool.slice(0, 14) + ".." : n.tool}
              </text>
              {/* Status dot */}
              <circle
                cx={n.x + NODE_W - 12}
                cy={n.y + 12}
                r={4}
                fill={c.border}
                opacity={0.9}
              />
            </g>
          );
        })}
      </svg>
    </div>
  );
}
