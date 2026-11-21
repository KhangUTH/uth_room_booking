import "./DetailModal.css";

function DetailModal({ onClose, image, status, name, title, information, registration, showButtons = false, statusClass = "" }) {
    return (
        <>
            <div className="detail-overlay">
                <div className="detail-modal">

                    <button className="detail-close" onClick={onClose}>
                        <i className="fa-solid fa-circle-xmark"></i>
                    </button>

                    <div className="detail-content">

                        <div className="detail-product">

                            <div className="detail-image">
                                <img src={image} alt="Ảnh thiết bị" />
                            </div>

                            <div className="detail-info">

                                <span className={`detail-status ${statusClass}`}>
                                    <i className="fa-regular fa-clock"></i>
                                    {status}
                                </span>

                                <h2>{name}</h2>

                                {information}

                            </div>
                        </div>

                        <div className="detail-registration">

                            <div className="detail-registration-inner">

                                <h3>{title}</h3>

                                {registration}

                            </div>
                        </div>

                        {showButtons ? (
                            <div className="detail-buttons">

                                <button>
                                    <i className="fa-solid fa-check"></i>
                                    Duyệt
                                </button>

                                <button>
                                    <i className="fa-solid fa-xmark"></i>
                                    Từ Chối
                                </button>

                            </div>
                        ) : ""}

                    </div>
                </div>
            </div>
        </>
    );
}

export default DetailModal;
