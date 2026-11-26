import { useCallback, useEffect, useRef, useState } from "react";
import { useOutletContext } from "react-router-dom";
import { supabase } from "../lib/supabase.js";
import { dataErrorMessage, listRecords, loadReferences } from "../lib/adminData.js";

export default function useAdminRecords(table, { page, search, filter }) {
  const [result, setResult] = useState({ rows: [], count: 0, loading: true, error: "" });
  const [references, setReferences] = useState({ roles: [], rooms: [], loading: true, error: "" });
  const [revision, setRevision] = useState(0);
  const live = useOutletContext();
  const liveRevision = (live?.all ?? 0) + (live?.[table] ?? 0)
    + (table === "equipment" ? live?.rooms ?? 0 : 0);
  const referenceRevision = (live?.all ?? 0) + (table === "equipment" ? live?.rooms ?? 0 : 0);
  const previousQuery = useRef(null);
  const queryKey = JSON.stringify([table, page, search, filter, revision]);
  const reload = useCallback(() => setRevision((value) => value + 1), []);

  useEffect(() => {
    const background = previousQuery.current === queryKey;
    previousQuery.current = queryKey;
    let active = true;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15000);
    const timer = setTimeout(async () => {
      if (active && !background) setResult({ rows: [], count: 0, loading: true, error: "" });
      try {
        const data = await listRecords(supabase, table, { page, search, filter, signal: controller.signal });
        if (active) setResult({ ...data, loading: false, error: "" });
      } catch (error) {
        if (active) setResult((current) => background && current.rows.length
          ? current
          : { rows: [], count: 0, loading: false, error: dataErrorMessage(error) });
      } finally { clearTimeout(timeout); }
    }, search ? 250 : 0);
    return () => { active = false; clearTimeout(timer); clearTimeout(timeout); controller.abort(); };
  }, [table, page, search, filter, queryKey, liveRevision]);

  useEffect(() => {
    let active = true;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15000);
    loadReferences(supabase, table, controller.signal).then(
      (data) => { if (active) setReferences({ ...data, loading: false, error: "" }); },
      (error) => { if (active) setReferences({ roles: [], rooms: [], loading: false, error: dataErrorMessage(error) }); },
    ).finally(() => clearTimeout(timeout));
    return () => { active = false; clearTimeout(timeout); controller.abort(); };
  }, [table, revision, referenceRevision]);

  return { ...result, references, reload };
}
