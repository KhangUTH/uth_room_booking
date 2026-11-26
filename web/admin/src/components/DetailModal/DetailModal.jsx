import { useEffect, useId, useRef } from "react";
import "./DetailModal.css";

function DetailModal({ onClose, image, onImageClick, status, name, title, information, registration, showButtons = false, statusClass = "", statusTone }) {
    const dialogRef = useRef(null);
    const titleId = useId();
    useEffect(() => {
        const dialog = dialogRef.current;
        dialog.showModal();
        return () => dialog.close();
    }, []);
    return (
            <dialog className="detail-overlay" ref={dialogRef} aria-labelledby={titleId}
                onCancel={(event) => { event.preventDefault(); onClose(); }}>
                <div className="detail-modal">

                    <button className="detail-close" type="button" onClick={onClose} aria-label="Đóng chi tiết">
                        <i className="fa-solid fa-circle-xmark" aria-hidden="true"></i>
                    </button>

                    <div className="detail-content">

                        <div className="detail-product">

                            <div className="detail-image">
                                {image && (onImageClick
                                    ? <button className="detail-image-preview" type="button" onClick={onImageClick} aria-label="Xem ảnh minh chứng lớn">
                                        <img src={image} alt="" />
                                    </button>
                                    : <img src={image} alt="Ảnh đính kèm" />)}
                            </div>

                            <div className="detail-info">

                                <span className={`detail-status ${statusClass}${statusTone ? ` admin-status admin-status--${statusTone}` : ""}`}>
                                    <i className="fa-regular fa-clock"></i>
                                    {status}
                                </span>

                                <h2 id={titleId}>{name}</h2>

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
            </dialog>
    );
}

export default DetailModal;
