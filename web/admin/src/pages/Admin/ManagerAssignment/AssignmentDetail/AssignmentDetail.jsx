import { useEffect, useState } from "react";
import DetailModal from "../../../../components/DetailModal/DetailModal.jsx";
import { supabase } from "../../../../lib/supabase.js";

export default function AssignmentDetail({ report, onClose }) {
    const [photo, setPhoto] = useState(null);
    const [photoError, setPhotoError] = useState(false);
    useEffect(() => {
        if (!report.has_photo) return;
        let active = true;
        let objectUrl;
        async function load() {
            try {
                const path = await supabase.rpc("incident_evidence_path", { report_id: report.id });
                if (path.error || !path.data) throw new Error("Ảnh không có sẵn");
                const result = await supabase.storage.from("incident-images").download(path.data);
                if (result.error) throw result.error;
                if (active) { objectUrl = URL.createObjectURL(result.data); setPhoto(objectUrl); }
            } catch { if (active) setPhotoError(true); }
        }
        load();
        return () => { active = false; if (objectUrl) URL.revokeObjectURL(objectUrl); };
    }, [report.id, report.has_photo]);
    const status = report.status === "open" ? (report.approved_at ? "Đã duyệt, chờ nhận việc" : "Chờ duyệt")
        : { in_progress: "Đang xử lý", resolved: "Hoàn tất", cancelled: "Đã hủy" }[report.status] || report.status;
    const date = (value) => value ? new Date(value).toLocaleString("vi-VN", { timeZone: "Asia/Ho_Chi_Minh" }) : "—";
    return <DetailModal onClose={onClose} image={photo || undefined} status={status} name={report.title}
        title="Thông tin sự cố" statusClass="assignment-status"
        information={<>
            <p className="code">#SC-{String(report.report_number).padStart(4, "0")}</p>
            <p><b>Phòng / thiết bị:</b> {report.asset_name}</p>
            <p>{report.has_photo ? (photoError ? "Không tải được ảnh. Đóng và mở lại để thử lại." : !photo ? "Đang tải ảnh…" : "Ảnh minh chứng") : "Chưa có ảnh đính kèm"}</p>
        </>}
        registration={<div className="detail-columns">
            <div className="detail-column">
                <p><b>Người báo cáo:</b> {report.reporter_name}</p>
                <p><b>Mã số:</b> {report.reporter_code || "—"}</p>
                <p><b>Thời gian xảy ra:</b> {date(report.occurred_at)}</p>
                <p><b>Gửi lúc:</b> {date(report.created_at)}</p>
                <p><b>Mô tả:</b> {report.description}</p>
            </div>
            <div className="detail-column">
                <p><b>Lớp học phần:</b> {report.course_section || "—"}</p>
                <p><b>Cần hỗ trợ ngay:</b> {report.needs_support ? "Có" : "Không"}</p>
                <p><b>Kỹ thuật viên:</b> {report.technician_name || "Chưa có người nhận"}</p>
                <p><b>Duyệt lúc:</b> {date(report.approved_at)}</p>
                <p><b>Cập nhật lúc:</b> {date(report.status_updated_at)}</p>
            </div>
        </div>} />;
}
