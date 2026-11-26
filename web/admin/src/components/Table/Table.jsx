import "./Table.css";

export function StatusBadge({ tone = "neutral", children }) {
    return <span className={`admin-status admin-status--${tone}`}>{children}</span>;
}

function Table({ columns, data, actions = [], emptyMessage = "Chưa có dữ liệu.", busy = false }) {
    return (
        <>
            <div className="common-table-container">
                <table className="admin-table">
                    <thead>
                        <tr>
                            {columns.map((column, index) => (
                                <th key={index}>{column.title}</th>
                            ))}

                            {actions.length > 0 ? (
                                <th>Thao Tác</th>
                            ) : ""}
                        </tr>
                    </thead>

                    <tbody>
                        {data.length === 0 && <tr><td colSpan={columns.length + (actions.length ? 1 : 0)}>{emptyMessage}</td></tr>}
                        {data.map((item, index) => (
                            <tr key={item.id ?? index}>
                                {columns.map((column, i) => (
                                    <td key={i}>
                                        {column.render
                                            ? column.render(item[column.key], item)
                                            : item[column.key]}
                                    </td>
                                ))}

                                {actions.length > 0 ? (
                                    <td>
                                        <div className="common-table-actions">
                                            {actions.map((action, i) => (
                                                <button
                                                    key={i}
                                                    className={action.className}
                                                    type="button"
                                                    disabled={busy || action.disabled?.(item)}
                                                    onClick={() => action.onClick?.(item)}
                                                >
                                                    <i className={action.icon}></i>
                                                    {action.label}
                                                </button>
                                            ))}
                                        </div>
                                    </td>
                                ) : ""}
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </>
    )
}

export default Table;
