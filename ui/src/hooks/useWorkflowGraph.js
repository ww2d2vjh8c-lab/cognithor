/**
 * Hook for workflow execution graph data.
 *
 * Polls the backend REST API for workflow templates, instances, and DAG runs.
 * Provides combined state for the WorkflowGraphPage.
 */
import { useState, useEffect, useCallback, useRef } from "react";
import { api } from "../utils/api";

const POLL_INTERVAL = 5000;

export function useWorkflowGraph() {
  const [templates, setTemplates] = useState([]);
  const [instances, setInstances] = useState([]);
  const [stats, setStats] = useState({});
  const [dagRuns, setDagRuns] = useState([]);
  const [selectedRun, setSelectedRun] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const timerRef = useRef(null);

  const fetchAll = useCallback(async () => {
    try {
      const [tRes, iRes, sRes, dRes] = await Promise.all([
        api("GET", "/workflows/templates"),
        api("GET", "/workflows/instances"),
        api("GET", "/workflows/stats"),
        api("GET", "/workflows/dag/runs"),
      ]);
      if (tRes.templates) setTemplates(tRes.templates);
      if (iRes.instances) setInstances(iRes.instances);
      if (sRes.templates !== undefined) setStats(sRes);
      if (dRes.runs) setDagRuns(dRes.runs);
      setError(null);
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchDagRun = useCallback(async (runId) => {
    const res = await api("GET", `/workflows/dag/runs/${runId}`);
    if (res.error) {
      setError(res.error);
      return;
    }
    setSelectedRun(res);
  }, []);

  const startWorkflow = useCallback(async (templateId) => {
    const res = await api("POST", "/workflows/instances", {
      template_id: templateId,
      created_by: "ui",
    });
    if (res.status === "ok") {
      await fetchAll();
    }
    return res;
  }, [fetchAll]);

  useEffect(() => {
    fetchAll();
    timerRef.current = setInterval(fetchAll, POLL_INTERVAL);
    return () => clearInterval(timerRef.current);
  }, [fetchAll]);

  return {
    templates,
    instances,
    stats,
    dagRuns,
    selectedRun,
    loading,
    error,
    fetchAll,
    fetchDagRun,
    startWorkflow,
    setSelectedRun,
  };
}
