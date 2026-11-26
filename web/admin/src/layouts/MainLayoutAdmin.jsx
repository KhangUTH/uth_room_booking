import Slidebar from "../components/Slidebar/Slidebar.jsx";
import TopBar from "../components/TopBar/TopBar.jsx";
import { useEffect, useState } from "react";
import { Outlet } from "react-router-dom";
import useOpen from "../hooks/useOpen.js";
import { supabase } from "../lib/supabase.js";

const liveTables = new Set(["incident_reports", "profiles", "rooms", "equipment", "support_requests", "maintenance_proposals"]);

function MainLayoutAdmin({ children }) {
    const { isOpen, setIsOpen } = useOpen(() =>
        typeof window === "undefined" || window.matchMedia("(min-width: 768px)").matches
    );
    const [revisions, setRevisions] = useState({});
    const [newBookings, setNewBookings] = useState(0);

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
                .on("broadcast", { event: "booking_changed" }, ({ payload }) => {
                    if (!active) return;
                    refresh("bookings");
                    if (payload?.new_booking === true) setNewBookings((current) => current + 1);
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
    return (
        <div className={`app-container${isOpen ? "" : " sidebar-collapsed"}`}>

            <Slidebar isOpen={isOpen} setIsOpen={setIsOpen} />

            <main className="main-content">

                <TopBar bookingRevision={`${revisions.all ?? 0}:${revisions.bookings ?? 0}`} newBookings={newBookings} onViewBookings={() => setNewBookings(0)} />
                {children ?? <Outlet context={revisions} />}
                
            </main>
        </div>
    );
}

export default MainLayoutAdmin;

