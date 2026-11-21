import "./Detail.css";

function Detail({ image, title, status, statusIcon, statusColor, onClose, children }) {
    return (
        <>
            <div className="common-detail-overlay">
                <div className="common-detail-modal">

                    <button
                        className="common-detail-close"
                        onClick={onClose}
                    >
                        <i className="fa-solid fa-circle-xmark"></i>
                    </button>

                    <div className="common-detail-content">

                        <div className="common-detail-image">
                            <img src={image} alt="Ảnh" />
                        </div>

                        <div className="common-detail-info">

                            <div
                                className="common-detail-status"
                                style={{ background: statusColor }}
                            >
                                <i className={statusIcon}></i>
                                {status}
                            </div>

                            <h2>{title}</h2>

                            {children}

                        </div>

                    </div>
                </div>
            </div>
        </>
    )
}

export default Detail;