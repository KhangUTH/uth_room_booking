import "./Pagination.css";

function Pagination() {
    return (
        <>
            <div className="pagination">
                <button>
                    <i className="fa-solid fa-chevron-left"></i>
                </button>

                <button className="current">1</button>
                <button>2</button>
                <button>3</button>

                <button>
                    <i className="fa-solid fa-chevron-right"></i>
                </button>
            </div>
        </>
    )
}

export default Pagination;