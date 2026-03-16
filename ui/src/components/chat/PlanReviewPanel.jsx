import { useState } from "react";

const RISK_CLASSES = {
  green: "cc-plan-risk-green",
  GREEN: "cc-plan-risk-green",
  yellow: "cc-plan-risk-yellow",
  YELLOW: "cc-plan-risk-yellow",
  orange: "cc-plan-risk-orange",
  ORANGE: "cc-plan-risk-orange",
  red: "cc-plan-risk-red",
  RED: "cc-plan-risk-red",
};

export default function PlanReviewPanel({ currentPlan, onApprove, onReject }) {
  const [expandedParams, setExpandedParams] = useState({});

  if (!currentPlan || !currentPlan.steps || currentPlan.steps.length === 0) {
    return (
      <div className="cc-plan-panel">
        <div className="cc-plan-empty">Waiting for next plan...</div>
      </div>
    );
  }

  const toggleParams = (idx) => {
    setExpandedParams((prev) => ({ ...prev, [idx]: !prev[idx] }));
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", height: "100%", overflow: "hidden" }}>
      <div className="cc-plan-panel">
        {currentPlan.goal && (
          <div style={{ marginBottom: 12, fontSize: 13, color: "var(--text)" }}>
            <strong>Goal:</strong> {currentPlan.goal}
          </div>
        )}
        {currentPlan.reasoning && (
          <div style={{ marginBottom: 12, fontSize: 12, color: "var(--text2)", fontStyle: "italic" }}>
            {currentPlan.reasoning}
          </div>
        )}
        {currentPlan.confidence != null && (
          <div style={{ marginBottom: 12, fontSize: 11, color: "var(--text2)" }}>
            Confidence: {(currentPlan.confidence * 100).toFixed(0)}%
          </div>
        )}

        {currentPlan.steps.map((step, idx) => {
          const riskClass = RISK_CLASSES[step.risk_estimate] || "cc-plan-risk-green";
          const hasParams = step.params && Object.keys(step.params).length > 0;
          return (
            <div key={idx} className="cc-plan-step">
              <div className="cc-plan-step-header">
                <span className="cc-plan-step-num">{idx + 1}</span>
                <span className="cc-plan-step-tool">{step.tool}</span>
                {step.risk_estimate && (
                  <span className={`cc-plan-step-risk ${riskClass}`}>
                    {String(step.risk_estimate).toLowerCase()}
                  </span>
                )}
              </div>
              {step.rationale && (
                <div className="cc-plan-rationale">{step.rationale}</div>
              )}
              {hasParams && (
                <>
                  <button
                    type="button"
                    onClick={() => toggleParams(idx)}
                    style={{
                      background: "none",
                      border: "none",
                      color: "var(--accent)",
                      cursor: "pointer",
                      fontSize: 11,
                      padding: "2px 0",
                      fontFamily: "inherit",
                    }}
                  >
                    {expandedParams[idx] ? "Hide params" : "Show params"}
                  </button>
                  {expandedParams[idx] && (
                    <div className="cc-plan-params">
                      {JSON.stringify(step.params, null, 2)}
                    </div>
                  )}
                </>
              )}
            </div>
          );
        })}
      </div>

      {onApprove && onReject && (
        <div className="cc-plan-actions">
          <button
            type="button"
            className="cc-plan-btn cc-plan-btn-approve"
            onClick={onApprove}
          >
            Approve All
          </button>
          <button
            type="button"
            className="cc-plan-btn cc-plan-btn-reject"
            onClick={onReject}
          >
            Reject
          </button>
        </div>
      )}
    </div>
  );
}
