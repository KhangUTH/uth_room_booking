import { useEffect, useState } from "react";
import DetailModal from "../../../../components/DetailModal/DetailModal.jsx";
import DataDialog from "../../../../components/AdminRecords/DataDialog.jsx";
import { supabase } from "../../../../lib/supabase.js";
import { incidentStatuses } from "../incidentStatuses.js";

const maxCachedPhotos = 8;

async function downloadEvidence(reportId, reporterId, signal) {
    const images = supabase.storage.from("incident-images");
    const download = (path) => images.download(path, {}, { signal });
    if (reporterId) {
        const jpeg = await download(`${reporterId}/${reportId.replaceAll("-", "")}.jpg`);
        if (!jpeg.error) return jpeg.data;
        if (String(jpeg.error.statusCode ?? jpeg.error.status) !== "404" &&
            !/object not found/i.test(jpeg.error.message)) throw jpeg.error;
    }

    // Older reports may use PNG.
    const path = await supabase.rpc("incident_evidence_path", { report_id: reportId }).abortSignal(signal);
    if (path.error || !path.data) throw path.error ?? new Error("Ảnh không có sẵn");
    const result = await download(path.data);
    if (result.error) throw result.error;
    return result.data;
}

export default function AssignmentDetail({ report, photoCache, onClose }) {
    const [photo, setPhoto] = useState(null);
    const [showPhoto, setShowPhoto] = useState(false);
    const [photoError, setPhotoError] = useState(false);
    const [retry, setRetry] = useState(0);
    const { id, reporter_id: reporterId, has_photo: hasPhoto } = report;
    useEffect(() => {
        if (!hasPhoto) return;
        let active = true;
        let objectUrl;
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 12000);
        const cache = photoCache.current;
        async function load() {
            try {
                const blob = cache.get(id) ?? await downloadEvidence(id, reporterId, controller.signal);
                if (!active) return;
                cache.delete(id);
                cache.set(id, blob);
                if (cache.size > maxCachedPhotos) cache.delete(cache.keys().next().value);
                objectUrl = URL.createObjectURL(blob);
                setPhoto(objectUrl);
            } catch {
                if (active) setPhotoError(true);
            } finally {
                clearTimeout(timeout);
            }
        }
        load();
        return () => {
            active = false;
            controller.abort();
            clearTimeout(timeout);
            if (objectUrl) URL.revokeObjectURL(objectUrl);
        };
    }, [id, reporterId, hasPhoto, photoCache, retry]);
    const status = incidentStatuses[report.status];
    const date = (value) => value ? new Date(value).toLocaleString("vi-VN", { timeZone: "Asia/Ho_Chi_Minh" }) : "—";
    const sentAt = date(report.created_at);
    const occurredAt = date(report.occurred_at);
    return <><DetailModal onClose={onClose} image={photo || undefined} onImageClick={() => setShowPhoto(true)}
        status={status?.label ?? report.status} name={report.title}
        title="Thông tin sự cố" statusClass="assignment-status" statusTone={status?.tone ?? "neutral"}
        information={<>
            <p className="code">#SC-{String(report.report_number).padStart(4, "0")}</p>
            <p><b>Phòng / thiết bị:</b> {report.asset_name}</p>
            {photoError
                ? <p role="status">Không tải được ảnh. <button type="button" onClick={() => { setPhotoError(false); setRetry((value) => value + 1); }}>Thử lại</button></p>
                : <p role="status">{hasPhoto ? (photo ? "Ảnh minh chứng" : "Đang tải ảnh…") : "Chưa có ảnh đính kèm"}</p>}
        </>}
        registration={<dl className="assignment-details">
            <div><dt>Người báo cáo</dt><dd>{report.reporter_name || "—"}</dd></div>
            <div><dt>Mã số</dt><dd>{report.reporter_code || "—"}</dd></div>
            <div><dt>Kỹ thuật viên</dt><dd>{report.technician_name || "Chưa có người nhận"}</dd></div>
            <div><dt>Lớp học phần</dt><dd>{report.course_section || "—"}</dd></div>
            <div><dt>Gửi lúc</dt><dd>{sentAt}</dd></div>
            <div><dt>Cập nhật lúc</dt><dd>{date(report.status_updated_at)}</dd></div>
            {report.occurred_at && occurredAt !== sentAt && <div><dt>Thời gian xảy ra</dt><dd>{occurredAt}</dd></div>}
            <div><dt>Cần hỗ trợ ngay</dt><dd>{report.needs_support ? "Có" : "Không"}</dd></div>
            <div className="assignment-description"><dt>Mô tả</dt><dd>{report.description || "—"}</dd></div>
        </dl>} />
        {showPhoto && photo && <DataDialog title="Ảnh minh chứng" onClose={() => setShowPhoto(false)}>
            <img className="assignment-photo-full" src={photo} alt="Ảnh minh chứng sự cố" />
        </DataDialog>}
    </>;
}
