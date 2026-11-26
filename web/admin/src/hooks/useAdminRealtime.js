import { useEffect, useState } from "react";
import { supabase } from "../lib/supabase.js";

const liveTables = new Set(["incident_reports", "profiles", "rooms", "equipment", "support_requests", "maintenance_proposals"]);

export default function useAdminRealtime() {
    const [revisions, setRevisions] = useState({});

    useEffect(() => {
        if (!supabase) return;
        let active = true;
        let connected = false;
        const refresh = (source) => setRevisions((current) => ({
            ...current,
            [source]: (current[source] ?? 0) + 1,
        }));
        let channel;
        const subscribeTimer = setTimeout(() => {
            channel = supabase.channel("uth-admin-bookings", { config: { private: true } })
                .on("broadcast", { event: "booking_changed" }, () => {
                    if (!active) return;
                    refresh("bookings");
                })
                .on("broadcast", { event: "admin_data_changed" }, ({ payload }) => {
                    if (active && liveTables.has(payload?.source)) refresh(payload.source);
                })
                .subscribe((status) => {
                    if (!active) return;
                    connected = status === "SUBSCRIBED";
                    if (connected) refresh("all");
                });
        }, 0);
        const fallback = setInterval(() => {
            if (!connected && document.visibilityState === "visible") refresh("all");
        }, 15000);
        return () => {
            active = false;
            clearTimeout(subscribeTimer);
            clearInterval(fallback);
            if (channel) void supabase.removeChannel(channel);
        };
    }, []);

    return revisions;
}
