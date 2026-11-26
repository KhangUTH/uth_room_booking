import Overview from "./Overview.jsx";
import Bookings from "./Bookings.jsx";
import Support from "./Support.jsx";
import EquipmentProposals from "./EquipmentProposals.jsx";
import "./AdminOperations.css";

const screens = { overview: Overview, bookings: Bookings, support: Support, equipmentProposals: EquipmentProposals };

export default function AdminOperations({ screen }) {
  const Screen = screens[screen];
  return <div className={screen === "equipmentProposals" ? "pv-page pv-proposals-page" : "pv-page"}><div className="pv-container"><Screen /></div></div>;
}
