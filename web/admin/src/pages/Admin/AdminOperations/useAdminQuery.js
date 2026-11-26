import { useEffect, useState } from "react";
import { useOutletContext } from "react-router-dom";

export default function useAdminQuery(load, delay = 0, sources = ["bookings"]) {
  const revisions = useOutletContext();
  const revision = [revisions?.all ?? 0, ...sources.map((source) => revisions?.[source] ?? 0)].join(":");
  const [version, setVersion] = useState(0);
  const [result, setResult] = useState(null);
  useEffect(() => {
    const controller = new AbortController();
    let active = true;
    const timer = setTimeout(async () => {
      const timeout = setTimeout(() => controller.abort(), 15000);
      try {
        const data = await load(controller.signal);
        if (active) setResult({ load, version, data });
      } catch (error) {
        if (active) setResult({ load, version, error });
      } finally {
        clearTimeout(timeout);
      }
    }, delay);
    return () => {
      active = false;
      clearTimeout(timer);
      controller.abort();
    };
  }, [load, version, delay, revision]);
  const current = result?.load === load && result.version === version ? result : null;
  return { data: current?.data, error: current?.error, loading: !current, reload: () => setVersion((value) => value + 1) };
}
