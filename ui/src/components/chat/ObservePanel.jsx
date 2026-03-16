import AgentLogPanel from "./AgentLogPanel";
import KanbanPanel from "./KanbanPanel";
import LiveDagPanel from "./LiveDagPanel";
import PlanReviewPanel from "./PlanReviewPanel";
import { ChatCanvas } from "./ChatCanvas";

const TABS = [
  { key: "log", label: "Log", icon: "\uD83D\uDCCB" },
  { key: "kanban", label: "Kanban", icon: "\uD83D\uDDC2\uFE0F" },
  { key: "dag", label: "DAG", icon: "\uD83D\uDD00" },
  { key: "plan", label: "Plan", icon: "\uD83D\uDCDD" },
  { key: "canvas", label: "Canvas", icon: "\uD83D\uDDBC\uFE0F" },
];

export default function ObservePanel({
  activeTab,
  onTabChange,
  onClose,
  pipelineState,
  agentLog,
  currentPlan,
  canvasHtml,
  canvasTitle,
  onApprove,
  onReject,
}) {
  const renderContent = () => {
    switch (activeTab) {
      case "log":
        return <AgentLogPanel logEntries={agentLog} />;
      case "kanban":
        return <KanbanPanel pipelineState={pipelineState} />;
      case "dag":
        return <LiveDagPanel pipelineState={pipelineState} currentPlan={currentPlan} />;
      case "plan":
        return (
          <PlanReviewPanel
            currentPlan={currentPlan}
            onApprove={onApprove}
            onReject={onReject}
          />
        );
      case "canvas":
        if (canvasHtml) {
          return <ChatCanvas html={canvasHtml} title={canvasTitle} onClose={() => {}} embedded />;
        }
        return (
          <div style={{ color: "var(--text2)", textAlign: "center", padding: 40, fontStyle: "italic" }}>
            No canvas content...
          </div>
        );
      default:
        return null;
    }
  };

  return (
    <div className="cc-observe-panel">
      <div className="cc-observe-tabs">
        {TABS.map((tab) => (
          <button
            key={tab.key}
            type="button"
            className={`cc-observe-tab ${activeTab === tab.key ? "active" : ""}`}
            onClick={() => onTabChange(tab.key)}
          >
            <span style={{ marginRight: 3 }}>{tab.icon}</span>
            {tab.label}
          </button>
        ))}
        <button
          type="button"
          className="cc-observe-close"
          onClick={onClose}
          title="Close panel"
        >
          &times;
        </button>
      </div>
      <div className="cc-observe-content">
        {renderContent()}
      </div>
    </div>
  );
}
