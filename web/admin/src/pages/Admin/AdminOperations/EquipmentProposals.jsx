import { useCallback, useRef, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import DataDialog from "../../../components/AdminRecords/DataDialog.jsx";
import Pagination from "../../../components/Pagination/Pagination.jsx";
import { dataErrorMessage } from "../../../lib/adminData.js";
import { supabase } from "../../../lib/supabase.js";
import { decideMaintenanceProposal, deleteMaintenanceProposal, emptyPage, listMaintenanceProposals, pageSize } from "./operationsData.js";
import { Heading, Icon, QueryError, Status } from "./OperationsUi.jsx";
import useAdminQuery from "./useAdminQuery.js";
import "../../../layouts/FacilitiesLayout.css";

export default function EquipmentProposals() {
  const [params] = useSearchParams();
  const pending = params.get("trang-thai") === "pending";
  const id = params.get("ma");
  const kind = params.get("loai");
  const assetType = kind === "equipment" ? "equipment" : kind === "room" || (!id && !pending) ? "room" : null;
  return <MaintenanceProposalList key={`${pending}:${assetType}:${id}`} pending={pending} id={id} assetType={assetType} />;
}

function MaintenanceProposalList({ pending, id, assetType }) {
  const [page, setPage] = useState(1);
  const [saving, setSaving] = useState(null);
  const [error, setError] = useState(null);
  const [deleteTarget, setDeleteTarget] = useState(null);
  const mutation = useRef(false);
  const load = useCallback((signal) => listMaintenanceProposals(supabase, { page, pending, id, assetType }, signal), [page, pending, id, assetType]);
  const listing = useAdminQuery(load, 0, ["maintenance_proposals", "profiles", "rooms", "equipment"]);
  const { rows, count } = listing.data ?? emptyPage;
  const currentType = assetType ?? (id ? rows[0]?.equipment ? "equipment" : "room" : "all");

  async function updateProposal(id, action) {
    if (mutation.current) return;
    mutation.current = true;
    setSaving(id);
    setError(null);
    try {
      await action();
      setDeleteTarget(null);
      if (rows.length === 1 && page > 1 && (pending || deleteTarget?.id === id)) setPage(page - 1);
    } catch (failure) {
      setError(failure);
    } finally {
      mutation.current = false;
      setSaving(null);
      listing.reload();
    }
  }

  return <>
    <Heading title="Đề xuất bảo trì" description={pending ? "Đề xuất đang chờ duyệt." : "Xem đề xuất bảo trì phòng máy hoặc thiết bị từ nhân viên kỹ thuật."}>
      {(pending || id) && <Link className="pv-text-button" to={currentType === "all" ? "/equipment-proposals" : `/equipment-proposals?loai=${currentType}`}>Xem tất cả đề xuất</Link>}
    </Heading>
    <nav className="facilities-tabs" aria-label="Loại tài sản đề xuất">
      {[
        ...(pending ? [{ type: "all", label: "Tất cả", icon: "list" }] : []),
        { type: "room", label: "Phòng máy", icon: "door-open" },
        { type: "equipment", label: "Thiết bị", icon: "hard-drive" },
      ].map(({ type, label, icon }) => <Link key={type}
        className={`facilities-tab${currentType === type ? " active" : ""}`}
        aria-current={currentType === type ? "page" : undefined}
        to={`/equipment-proposals?loai=${type}${pending ? "&trang-thai=pending" : ""}`}>
        <Icon name={icon} /> {label}
      </Link>)}
    </nav>
    <section className="pv-card" aria-busy={listing.loading}>
      {listing.error && <QueryError error={listing.error} retry={listing.reload} />}
      {error && !deleteTarget && <p className="pv-empty" role="alert">{dataErrorMessage(error)}</p>}
      {listing.loading && <p className="pv-empty" role="status">Đang tải đề xuất…</p>}
      {!listing.loading && !listing.error && rows.length === 0 && <p className="pv-empty">Chưa có đề xuất.</p>}
      {rows.length > 0 && <div className="common-table-container" tabIndex={0} role="region" aria-label="Bảng đề xuất bảo trì"><table className="admin-table">
        <thead><tr><th>{currentType === "room" ? "Phòng máy" : currentType === "equipment" ? "Thiết bị" : "Phòng / thiết bị"}</th><th>Người gửi</th><th>Lý do bảo trì</th><th>Trạng thái</th><th>Thao tác</th></tr></thead>
        <tbody>{rows.map((row) => <tr key={row.id}>
          <td>{row.rooms?.name || row.equipment?.name || "—"}</td>
          <td>{row.profiles?.full_name || "—"}</td>
          <td>{row.reason}</td>
          <td><Status kind={row.status} /></td>
          <td><div className="pv-proposal-actions">
            {row.status === "pending" && <>
            <button type="button" className="admin-status admin-status--red" disabled={saving !== null}
              onClick={() => updateProposal(row.id, () => decideMaintenanceProposal(supabase, row.id, "rejected"))}>Từ chối</button>
            <button type="button" className="admin-status admin-status--green" disabled={saving !== null}
              onClick={() => updateProposal(row.id, () => decideMaintenanceProposal(supabase, row.id, "approved"))}>Duyệt</button>
            </>}
            <button type="button" className="admin-status admin-status--neutral" disabled={saving !== null}
              onClick={() => { setError(null); setDeleteTarget(row); }}>Xoá</button>
          </div></td>
        </tr>)}</tbody>
      </table></div>}
      <Pagination page={page} count={count} pageSize={pageSize} busy={listing.loading} onChange={setPage} label="Phân trang đề xuất" />
    </section>
    {deleteTarget && <DataDialog title="Xoá đề xuất bảo trì" busy={saving !== null}
      onClose={() => { setDeleteTarget(null); setError(null); }}>
      <div className="pv-dialog-body">
        <p>Bạn muốn xoá đề xuất cho <strong>{deleteTarget.rooms?.name || deleteTarget.equipment?.name || "tài sản này"}</strong>?</p>
        {error && <p className="pv-error" role="alert">{dataErrorMessage(error)}</p>}
      </div>
      <div className="pv-dialog-actions">
        <button type="button" className="pv-button" disabled={saving !== null} onClick={() => { setDeleteTarget(null); setError(null); }}>Hủy</button>
        <button type="button" className="pv-button pv-button-danger" disabled={saving !== null}
          onClick={() => updateProposal(deleteTarget.id, () => deleteMaintenanceProposal(supabase, deleteTarget.id))}>Xoá</button>
      </div>
    </DataDialog>}
  </>;
}
