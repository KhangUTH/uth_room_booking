import Table from "../../../../components/Table/Table.jsx";

function statusLabel(row) {
    if (row.status === "open") return row.approved_at ? "Đã duyệt, chờ nhận việc" : "Chờ duyệt";
    return { in_progress: "Đang xử lý", resolved: "Hoàn tất", cancelled: "Đã hủy" }[row.status] || row.status;
}

export default function AssignmentTable({ rows, busy, onView, onApprove }) {
    const columns = [
        { title: "Mã sự cố", key: "report_number", render: (number) => `#SC-${String(number).padStart(4, "0")}` },
        { title: "Người báo cáo", key: "reporter_name" },
        { title: "Tiêu đề", key: "title" },
        { title: "Phòng / thiết bị", key: "asset_name" },
        { title: "Trạng thái", key: "status", render: (_, row) => statusLabel(row) },
        { title: "Người nhận", key: "technician_name", render: (name) => name || "Chưa có người nhận" },
    ];
    return <Table columns={columns} data={rows} busy={busy} emptyMessage="Không có báo cáo phù hợp."
        actions={[
            { label: "Xem", icon: "fa-regular fa-eye", className: "common-view-button", onClick: onView },
            { label: "Duyệt", icon: "fa-solid fa-check", className: "common-view-button",
                onClick: onApprove, disabled: (row) => row.status !== "open" || Boolean(row.approved_at) },
        ]} />;
}
