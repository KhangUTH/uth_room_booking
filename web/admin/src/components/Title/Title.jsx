import "./Title.css";

function Title({ icon, title, placeholder, buttonText, onAdd, children, search, onSearchChange }) {
    return (
        <>
            <div className="page-title">
                <i className={icon}></i>
                <h1>{title}</h1>
            </div>

            <div className="toolbar">
                <div className="search-box">
                    <input type="search" aria-label={placeholder || "Tìm kiếm"} placeholder={placeholder} value={search} onChange={onSearchChange ? (event) => onSearchChange(event.target.value) : undefined} />
                    <i className="fa-solid fa-magnifying-glass"></i>
                </div>

                {children}

                {buttonText ? (
                    <button className="title-add-button" onClick={onAdd}>
                        <i className="fa-solid fa-plus"></i>
                        {buttonText}
                    </button>
                ) : ""}
            </div>
        </>
    );
}

export default Title;
