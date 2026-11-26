import Title from "../../../../components/Title/Title.jsx";

export default function AssignmentTitle({ search, filter, onSearch, onFilter, loading, onReload }) {
    return <Title icon="fa-solid fa-screwdriver-wrench" title="THEO DÕI SỰ CỐ"
        placeholder="Tìm tiêu đề hoặc mã sự cố" search={search} onSearchChange={onSearch}>
        <div className="filter-box">
            <select aria-label="Trạng thái báo cáo" value={filter} onChange={(event) => onFilter(event.target.value)}>
                <option value="">Tất cả trạng thái</option>
                <option value="open">Chờ nhận</option>
                <option value="in_progress">Đang xử lý</option>
                <option value="resolved">Hoàn tất</option>
                <option value="cancelled">Đã hủy</option>
            </select>
        </div>
        <button className="data-toolbar-button" type="button" disabled={loading} onClick={onReload}>
            <i className="fa-solid fa-rotate-right" aria-hidden="true" />
            {loading ? "Đang tải…" : "Tải lại"}
        </button>
    </Title>;
}
