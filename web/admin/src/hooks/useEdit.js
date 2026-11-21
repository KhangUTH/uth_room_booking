import { useState } from "react";

function useEdit() {
    const [showEdit, setShowEdit] = useState(false);

    return { showEdit, setShowEdit };
}

export default useEdit;