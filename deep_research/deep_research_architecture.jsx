import { useState, useEffect } from "react";

const phases = [
  {
    id: "classify",
    label: "Task Classifier",
    desc: "ROUTINE → MODERATE → RESEARCH_HEAVY → FRONTIER",
    icon: "🔍",
    color: "#f59e0b",
    detail: "Erkennt ob 3 Suchen reichen oder 30 nötig sind"
  },
  {
    id: "decompose",
    label: "Query Decomposer",
    desc: "1 Frage → 7-12 gezielte Sub-Queries",
    icon: "🧩",
    color: "#8b5cf6",
    detail: "Official Docs → GitHub → Community → Lateral"
  },
  {
    id: "search",
    label: "Relentless Search Loop",
    desc: "Sucht bis Confidence-Gate erreicht ist",
    icon: "⚡",
    color: "#ef4444",
    detail: "Nie aufgeben. Neue Queries generieren wenn nötig.",
    isCore: true
  },
  {
    id: "evaluate",
    label: "Result Evaluator",
    desc: "LLM bewertet jedes Ergebnis: Relevanz × Verification",
    icon: "⚖️",
    color: "#06b6d4",
    detail: "Score = 30% Relevanz + 30% Actionability + 40% Verification"
  },
  {
    id: "expand",
    label: "Adaptive Query Expander",
    desc: "Erkennt Lücken → generiert neue Suchstrategien",
    icon: "🔄",
    color: "#f97316",
    detail: "Analysiert was fehlt und sucht gezielt danach"
  },
  {
    id: "verify",
    label: "Cross-Verification",
    desc: "2+ unabhängige Quellen müssen übereinstimmen",
    icon: "✅",
    color: "#10b981",
    detail: "Confidence boost: +15% bei Cross-Domain-Bestätigung"
  },
  {
    id: "synthesize",
    label: "Solution Synthesizer",
    desc: "Finales Ergebnis mit Steps + Quellen + Caveats",
    icon: "📋",
    color: "#3b82f6",
    detail: "Ehrlich: CONFIRMED vs. EXPERIMENTAL klar markiert"
  }
];

const sourceTiers = [
  { tier: "T5", label: "Official Docs", color: "#10b981", example: "vLLM docs, ROCm compatibility matrix" },
  { tier: "T4", label: "GitHub Issues", color: "#3b82f6", example: "vllm-project/vllm #issues, PRs" },
  { tier: "T3", label: "Verified Community", color: "#8b5cf6", example: "Reddit post with 'it works!' confirmation" },
  { tier: "T2", label: "Blog / Tutorial", color: "#f59e0b", example: "Medium article, dev blog walkthrough" },
  { tier: "T1", label: "Unverified", color: "#6b7280", example: "Forum post, no confirmation" },
];

const comparison = {
  hermes: { searches: 3, confidence: "~20%", result: "Gave up", icon: "❌" },
  deep: { searches: "8-30", confidence: "75%+", result: "Verified answer", icon: "✅" }
};

export default function DeepResearchArchitecture() {
  const [activePhase, setActivePhase] = useState(null);
  const [animStep, setAnimStep] = useState(0);
  const [showLoop, setShowLoop] = useState(false);

  useEffect(() => {
    const timer = setInterval(() => {
      setAnimStep(prev => (prev + 1) % 7);
    }, 2200);
    return () => clearInterval(timer);
  }, []);

  useEffect(() => {
    const t = setTimeout(() => setShowLoop(true), 800);
    return () => clearTimeout(t);
  }, []);

  return (
    <div style={{
      minHeight: "100vh",
      background: "#0a0a0f",
      color: "#e2e8f0",
      fontFamily: "'JetBrains Mono', 'Fira Code', 'SF Mono', monospace",
      padding: "32px 24px",
      overflow: "hidden"
    }}>
      {/* Subtle grid background */}
      <div style={{
        position: "fixed", inset: 0, opacity: 0.03,
        backgroundImage: "linear-gradient(#fff 1px, transparent 1px), linear-gradient(90deg, #fff 1px, transparent 1px)",
        backgroundSize: "40px 40px", pointerEvents: "none", zIndex: 0
      }} />

      <div style={{ position: "relative", zIndex: 1, maxWidth: 900, margin: "0 auto" }}>
        {/* Header */}
        <div style={{ marginBottom: 40, textAlign: "center" }}>
          <div style={{
            fontSize: 11, letterSpacing: 4, textTransform: "uppercase",
            color: "#64748b", marginBottom: 8
          }}>
            cognithor v0.35 · agent architecture
          </div>
          <h1 style={{
            fontSize: 28, fontWeight: 700, margin: 0,
            background: "linear-gradient(135deg, #ef4444, #f59e0b, #8b5cf6)",
            WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent",
            letterSpacing: -0.5
          }}>
            DeepResearch Agent
          </h1>
          <p style={{ color: "#94a3b8", fontSize: 13, marginTop: 6, fontFamily: "system-ui, sans-serif" }}>
            Perplexity-style relentless search — never stops until a verified answer is found
          </p>
        </div>

        {/* Before/After comparison */}
        <div style={{
          display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16,
          marginBottom: 40
        }}>
          <div style={{
            background: "linear-gradient(135deg, rgba(239,68,68,0.08), rgba(239,68,68,0.02))",
            border: "1px solid rgba(239,68,68,0.2)",
            borderRadius: 12, padding: "20px 24px"
          }}>
            <div style={{ fontSize: 11, letterSpacing: 2, color: "#ef4444", marginBottom: 10, textTransform: "uppercase" }}>
              ❌ vorher · standard agent
            </div>
            <div style={{ fontFamily: "system-ui", fontSize: 13, color: "#94a3b8", lineHeight: 1.7 }}>
              <div>Suchen: <span style={{ color: "#ef4444", fontWeight: 700, fontFamily: "monospace" }}>3</span></div>
              <div>Confidence: <span style={{ color: "#ef4444", fontWeight: 700, fontFamily: "monospace" }}>~20%</span></div>
              <div>Ergebnis: <span style={{ color: "#ef4444" }}>Aufgegeben, falscher Befehl ausgeführt</span></div>
            </div>
          </div>
          <div style={{
            background: "linear-gradient(135deg, rgba(16,185,129,0.08), rgba(16,185,129,0.02))",
            border: "1px solid rgba(16,185,129,0.2)",
            borderRadius: 12, padding: "20px 24px"
          }}>
            <div style={{ fontSize: 11, letterSpacing: 2, color: "#10b981", marginBottom: 10, textTransform: "uppercase" }}>
              ✅ nachher · deep research agent
            </div>
            <div style={{ fontFamily: "system-ui", fontSize: 13, color: "#94a3b8", lineHeight: 1.7 }}>
              <div>Suchen: <span style={{ color: "#10b981", fontWeight: 700, fontFamily: "monospace" }}>8–30</span> (adaptiv)</div>
              <div>Confidence: <span style={{ color: "#10b981", fontWeight: 700, fontFamily: "monospace" }}>≥75%</span> oder ehrliches "unklar"</div>
              <div>Ergebnis: <span style={{ color: "#10b981" }}>Cross-verifizierte Lösung mit Quellen</span></div>
            </div>
          </div>
        </div>

        {/* Main pipeline */}
        <div style={{ marginBottom: 40 }}>
          <div style={{
            fontSize: 11, letterSpacing: 2, color: "#64748b",
            textTransform: "uppercase", marginBottom: 16
          }}>
            Pipeline Flow
          </div>

          {phases.map((phase, i) => {
            const isActive = animStep === i;
            const isHovered = activePhase === phase.id;
            const isLoopBack = phase.id === "expand";

            return (
              <div key={phase.id} style={{ position: "relative" }}>
                {/* Connector line */}
                {i > 0 && (
                  <div style={{
                    width: 2, height: 20, margin: "0 auto",
                    background: isActive
                      ? `linear-gradient(${phase.color}, transparent)`
                      : "rgba(100,116,139,0.2)",
                    transition: "background 0.5s"
                  }} />
                )}

                {/* Phase card */}
                <div
                  onMouseEnter={() => setActivePhase(phase.id)}
                  onMouseLeave={() => setActivePhase(null)}
                  style={{
                    display: "flex", alignItems: "center", gap: 16,
                    padding: "16px 20px",
                    background: isActive
                      ? `linear-gradient(135deg, ${phase.color}12, ${phase.color}06)`
                      : isHovered
                        ? "rgba(255,255,255,0.02)"
                        : "transparent",
                    border: `1px solid ${isActive ? phase.color + "40" : isHovered ? "rgba(255,255,255,0.06)" : "transparent"}`,
                    borderRadius: 12,
                    cursor: "pointer",
                    transition: "all 0.4s ease",
                    position: "relative"
                  }}
                >
                  {/* Step number */}
                  <div style={{
                    width: 36, height: 36, borderRadius: "50%",
                    display: "flex", alignItems: "center", justifyContent: "center",
                    background: isActive ? phase.color + "20" : "rgba(100,116,139,0.1)",
                    border: `2px solid ${isActive ? phase.color : "rgba(100,116,139,0.2)"}`,
                    fontSize: 16, flexShrink: 0,
                    transition: "all 0.4s",
                    boxShadow: isActive ? `0 0 20px ${phase.color}30` : "none"
                  }}>
                    {phase.icon}
                  </div>

                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{
                      display: "flex", alignItems: "center", gap: 8,
                      marginBottom: 2
                    }}>
                      <span style={{
                        fontSize: 14, fontWeight: 600,
                        color: isActive ? phase.color : "#e2e8f0"
                      }}>
                        {phase.label}
                      </span>
                      {phase.isCore && (
                        <span style={{
                          fontSize: 9, letterSpacing: 1.5,
                          padding: "2px 8px", borderRadius: 4,
                          background: "rgba(239,68,68,0.15)",
                          color: "#ef4444", textTransform: "uppercase",
                          fontWeight: 700
                        }}>
                          CORE
                        </span>
                      )}
                    </div>
                    <div style={{
                      fontSize: 12, color: "#64748b",
                      fontFamily: "system-ui, sans-serif"
                    }}>
                      {phase.desc}
                    </div>
                    {(isHovered || isActive) && (
                      <div style={{
                        fontSize: 11, color: phase.color, marginTop: 6,
                        fontFamily: "system-ui, sans-serif",
                        opacity: 0.9,
                        animation: "fadeIn 0.3s ease"
                      }}>
                        → {phase.detail}
                      </div>
                    )}
                  </div>

                  {/* Loop-back indicator for Expander */}
                  {isLoopBack && showLoop && (
                    <div style={{
                      position: "absolute", right: -60, top: "50%",
                      transform: "translateY(-50%)",
                      display: "flex", alignItems: "center", gap: 4,
                      color: "#f97316", fontSize: 11, opacity: 0.7,
                      whiteSpace: "nowrap"
                    }}>
                      <span style={{ fontSize: 18 }}>↩</span>
                      <span style={{ fontFamily: "system-ui" }}>loop back</span>
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>

        {/* Source tier hierarchy */}
        <div style={{ marginBottom: 40 }}>
          <div style={{
            fontSize: 11, letterSpacing: 2, color: "#64748b",
            textTransform: "uppercase", marginBottom: 16
          }}>
            Source Priority Hierarchy
          </div>
          <div style={{
            background: "rgba(255,255,255,0.02)",
            borderRadius: 12, overflow: "hidden",
            border: "1px solid rgba(255,255,255,0.04)"
          }}>
            {sourceTiers.map((st, i) => (
              <div key={st.tier} style={{
                display: "flex", alignItems: "center", gap: 12,
                padding: "12px 20px",
                borderBottom: i < sourceTiers.length - 1 ? "1px solid rgba(255,255,255,0.04)" : "none"
              }}>
                <div style={{
                  width: 28, height: 28, borderRadius: 6,
                  background: st.color + "18",
                  border: `1px solid ${st.color}30`,
                  display: "flex", alignItems: "center", justifyContent: "center",
                  fontSize: 10, fontWeight: 700, color: st.color,
                  flexShrink: 0
                }}>
                  {st.tier}
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: 600, color: st.color }}>
                    {st.label}
                  </div>
                  <div style={{ fontSize: 11, color: "#64748b", fontFamily: "system-ui" }}>
                    {st.example}
                  </div>
                </div>
                <div style={{
                  width: `${(5 - i) * 20}%`, maxWidth: 120,
                  height: 4, borderRadius: 2,
                  background: `linear-gradient(90deg, ${st.color}60, ${st.color}20)`
                }} />
              </div>
            ))}
          </div>
        </div>

        {/* Confidence formula */}
        <div style={{
          background: "rgba(139,92,246,0.05)",
          border: "1px solid rgba(139,92,246,0.15)",
          borderRadius: 12, padding: "20px 24px",
          marginBottom: 40
        }}>
          <div style={{
            fontSize: 11, letterSpacing: 2, color: "#8b5cf6",
            textTransform: "uppercase", marginBottom: 12
          }}>
            Confidence Gate Formula
          </div>
          <div style={{
            fontFamily: "'JetBrains Mono', monospace",
            fontSize: 12, color: "#c4b5fd",
            lineHeight: 2.2,
            background: "rgba(0,0,0,0.3)",
            padding: "16px 20px",
            borderRadius: 8,
            overflowX: "auto"
          }}>
            <div><span style={{ color: "#64748b" }}>// Base score from LLM evaluation</span></div>
            <div>
              <span style={{ color: "#f59e0b" }}>base</span>
              {" = "}
              <span style={{ color: "#94a3b8" }}>relevance</span>
              ×0.3 + <span style={{ color: "#94a3b8" }}>actionability</span>
              ×0.3 + <span style={{ color: "#10b981" }}>verification</span>
              ×<span style={{ color: "#ef4444", fontWeight: 700 }}>0.4</span>
            </div>
            <div style={{ marginTop: 4 }}><span style={{ color: "#64748b" }}>// Boosts and penalties</span></div>
            <div>
              <span style={{ color: "#10b981" }}>+0.10</span> per additional independent source <span style={{ color: "#64748b" }}>(max +0.30)</span>
            </div>
            <div>
              <span style={{ color: "#10b981" }}>+0.15</span> if cross-verified <span style={{ color: "#64748b" }}>(2+ domains agree)</span>
            </div>
            <div>
              <span style={{ color: "#10b981" }}>+0.10</span> if official docs confirm
            </div>
            <div>
              <span style={{ color: "#ef4444" }}>−0.10</span> per contradicting source
            </div>
            <div style={{ marginTop: 8, borderTop: "1px solid rgba(255,255,255,0.06)", paddingTop: 8 }}>
              <span style={{ color: "#64748b" }}>// Gate: Executor only runs if</span>
            </div>
            <div>
              <span style={{ color: "#f59e0b" }}>confidence</span> ≥{" "}
              <span style={{ color: "#10b981", fontWeight: 700, fontSize: 14 }}>0.75</span>
              {" "}<span style={{ color: "#64748b" }}>AND</span>{" "}
              <span style={{ color: "#f59e0b" }}>sources</span> ≥{" "}
              <span style={{ color: "#10b981", fontWeight: 700, fontSize: 14 }}>2</span>
            </div>
          </div>
        </div>

        {/* Key insight */}
        <div style={{
          background: "linear-gradient(135deg, rgba(239,68,68,0.06), rgba(245,158,11,0.04))",
          border: "1px solid rgba(239,68,68,0.15)",
          borderRadius: 12, padding: "20px 24px",
          fontFamily: "system-ui, sans-serif"
        }}>
          <div style={{
            fontSize: 11, letterSpacing: 2, color: "#ef4444",
            textTransform: "uppercase", marginBottom: 8
          }}>
            Core Principle
          </div>
          <div style={{ fontSize: 14, color: "#e2e8f0", lineHeight: 1.7 }}>
            Der Agent <strong style={{ color: "#f59e0b" }}>gibt niemals auf</strong>.
            Wenn 3 Suchen nicht reichen, macht er 10. Wenn 10 nicht reichen, macht er 25.
            Und wenn auch nach 25 Suchen keine verifizierte Lösung existiert, sagt er{" "}
            <strong style={{ color: "#ef4444" }}>ehrlich</strong>: "Hier ist was ich gefunden habe,
            hier sind die offenen Fragen, hier sind die nächsten Schritte."
          </div>
        </div>

        {/* Footer */}
        <div style={{
          textAlign: "center", marginTop: 40,
          fontSize: 10, color: "#475569", letterSpacing: 1
        }}>
          COGNITHOR DEEP RESEARCH AGENT · APACHE 2.0
        </div>
      </div>

      <style>{`
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(-4px); }
          to { opacity: 0.9; transform: translateY(0); }
        }
      `}</style>
    </div>
  );
}
