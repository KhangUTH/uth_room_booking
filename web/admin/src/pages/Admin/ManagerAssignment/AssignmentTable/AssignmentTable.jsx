import Table, { StatusBadge } from "../../../../components/Table/Table.jsx";

import { incidentStatuses } from "../incidentStatuses.js";

export default function AssignmentTable({ rows, busy, assetType, onView }) {
    const columns = [
        { title: "Mã sự cố", key: "report_number", render: (number) => `#SC-${String(number).padStart(4, "0")}` },
        { title: "Người báo cáo", key: "reporter_name" },
        { title: "Tiêu đề", key: "title" },
        { title: assetType === "room" ? "Phòng máy" : assetType === "equipment" ? "Thiết bị" : "Phòng / thiết bị", key: "asset_name" },
        { title: "Trạng thái", key: "status", render: (value) =>
            <StatusBadge tone={incidentStatuses[value]?.tone}>{incidentStatuses[value]?.label ?? value}</StatusBadge> },
        { title: "Người nhận", key: "technician_name", render: (name) => name || "Chưa có người nhận" },
    ];
    return <Table columns={columns} data={rows} busy={busy} emptyMessage="Không có báo cáo phù hợp."
        actions={[
            { label: "Xem", icon: "fa-regular fa-eye", className: "common-view-button", onClick: onView },
        ]} />;
}
