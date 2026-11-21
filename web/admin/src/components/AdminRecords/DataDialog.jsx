import { useEffect, useId, useRef } from "react";

export default function DataDialog({ title, onClose, busy = false, children }) {
  const dialogRef = useRef(null);
  const titleId = useId();
  useEffect(() => {
    const dialog = dialogRef.current;
    dialog.showModal();
    return () => dialog.close();
  }, []);

  return (
    <dialog className="data-dialog" ref={dialogRef} aria-labelledby={titleId} onCancel={(event) => {
      event.preventDefault();
      if (!busy) onClose();
    }}>
      <header className="data-dialog-header">
        <h2 id={titleId}>{title}</h2>
        <button type="button" onClick={onClose} disabled={busy} aria-label="Đóng">×</button>
      </header>
      {children}
    </dialog>
  );
}
