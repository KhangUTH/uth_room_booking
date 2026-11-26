import "./Pagination.css";

function Pagination({ page = 1, count = 0, pageSize = 10, onChange, label = "Phân trang", busy = false }) {
    const pages = Math.max(1, Math.ceil(count / pageSize));
    return <nav className="pagination" aria-label={label}>
        <button type="button" disabled={busy || page <= 1 || !onChange} onClick={() => onChange(page - 1)}>
            <i className="fa-solid fa-chevron-left" aria-hidden="true" /> Trước
        </button>
        <span>Trang {page}/{pages}</span>
        <button type="button" disabled={busy || page >= pages || !onChange} onClick={() => onChange(page + 1)}>
            Sau <i className="fa-solid fa-chevron-right" aria-hidden="true" />
        </button>
    </nav>;
}

export default Pagination;
