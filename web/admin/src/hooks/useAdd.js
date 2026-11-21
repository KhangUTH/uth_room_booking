import { useState } from "react";

function useForm() {
    const [show, setShow] = useState(false);

    return { show, setShow};
}

export default useForm;