import { useState } from "react";

function useDetail() {
    const [showDetail, setShowDetail] = useState(false);

    return { showDetail, setShowDetail };
}

export default useDetail;