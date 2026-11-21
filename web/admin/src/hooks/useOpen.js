import { useState } from "react";

function useOpen(initialValue = true) {
    const [isOpen, setIsOpen] = useState(initialValue);

    return { isOpen, setIsOpen };
}

export default useOpen;
