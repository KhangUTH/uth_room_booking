import "./Form.css";

function Form({ title, icon, onClose, buttonText, buttonIcon, width = "900px", children }) {
    return (
        <>
            <div className="common-form-overlay">
                <div className="common-form-modal" style={{ width }}>

                    <div className="common-form-header">
                        <h2>
                            <i className={icon}></i> {title}
                        </h2>

                        <button
                            type="button"
                            className="common-form-close"
                            onClick={onClose}
                        >
                            <i className="fa-solid fa-xmark"></i>
                        </button>
                    </div>

                    <div className="common-form-body">
                        {children}
                    </div>

                    <div className="common-form-footer">
                        <button
                            type="button"
                            className="common-form-submit"
                        >
                            <i className={buttonIcon}></i> {buttonText}
                        </button>
                    </div>

                </div>
            </div>
        </>
    )
}

export default Form;