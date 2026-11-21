import { useCallback, useEffect, useState } from "react";
import { supabase } from "../lib/supabase.js";
import { dataErrorMessage, listRecords, loadReferences } from "../lib/adminData.js";

export default function useAdminRecords(table, { page, search, filter, archived }) {
  const [result, setResult] = useState({ rows: [], count: 0, loading: true, error: "" });
  const [references, setReferences] = useState({ roles: [], rooms: [], loading: true, error: "" });
  const [revision, setRevision] = useState(0);
  const reload = useCallback(() => setRevision((value) => value + 1), []);

  useEffect(() => {
    let active = true;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15000);
    const timer = setTimeout(async () => {
      if (active) setResult({ rows: [], count: 0, loading: true, error: "" });
      try {
        const data = await listRecords(supabase, table, { page, search, filter, archived, signal: controller.signal });
        if (active) setResult({ ...data, loading: false, error: "" });
      } catch (error) {
        if (active) setResult({ rows: [], count: 0, loading: false, error: dataErrorMessage(error) });
      } finally { clearTimeout(timeout); }
    }, search ? 250 : 0);
    return () => { active = false; clearTimeout(timer); clearTimeout(timeout); controller.abort(); };
  }, [table, page, search, filter, archived, revision]);

  useEffect(() => {
    let active = true;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15000);
    loadReferences(supabase, table, controller.signal).then(
      (data) => { if (active) setReferences({ ...data, loading: false, error: "" }); },
      (error) => { if (active) setReferences({ roles: [], rooms: [], loading: false, error: dataErrorMessage(error) }); },
    ).finally(() => clearTimeout(timeout));
    return () => { active = false; clearTimeout(timeout); controller.abort(); };
  }, [table, revision]);

  return { ...result, references, reload };
}
