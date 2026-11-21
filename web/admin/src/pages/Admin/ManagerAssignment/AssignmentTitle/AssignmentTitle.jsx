import Title from "../../../../components/Title/Title.jsx";

export default function AssignmentTitle({ search, filter, onSearch, onFilter }) {
    return <Title icon="fa-solid fa-screwdriver-wrench" title="PHÂN CÔNG SỰ CỐ"
        placeholder="Tìm tiêu đề hoặc mã sự cố" search={search} onSearchChange={onSearch}>
        <div className="filter-box">
            <select aria-label="Trạng thái báo cáo" value={filter} onChange={(event) => onFilter(event.target.value)}>
                <option value="">Tất cả trạng thái</option>
                <option value="pending">Chờ duyệt</option>
                <option value="approved">Đã duyệt, chờ nhận việc</option>
                <option value="in_progress">Đang xử lý</option>
                <option value="resolved">Hoàn tất</option>
                <option value="cancelled">Đã hủy</option>
            </select>
        </div>
    </Title>;
}
