import { useEffect, useRef, useState } from "react";

let scriptRequest;

function loadTurnstile() {
  if (window.turnstile) return Promise.resolve(window.turnstile);
  scriptRequest ??= new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = "https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit";
    script.async = true;
    script.onload = () => resolve(window.turnstile);
    script.onerror = () => { script.remove(); reject(new Error("Turnstile unavailable")); };
    document.head.append(script);
  }).catch((error) => { scriptRequest = undefined; throw error; });
  return scriptRequest;
}

export default function AuthCaptcha({ siteKey, onToken }) {
  const container = useRef(null);
  const [failed, setFailed] = useState(false);
  const [retry, setRetry] = useState(0);

  useEffect(() => {
    let active = true;
    let widget;
    let api;
    const invalidate = () => { if (active) onToken(""); };
    const fail = () => { if (active) { invalidate(); setFailed(true); } };
    loadTurnstile().then((turnstile) => {
      if (!active) return;
      api = turnstile;
      widget = api.render(container.current, {
        sitekey: siteKey,
        language: "vi",
        callback: (token) => { if (active) { setFailed(false); onToken(token); } },
        "expired-callback": invalidate,
        "error-callback": fail,
      });
    }).catch(fail);
    return () => {
      active = false;
      if (widget !== undefined) api.remove(widget);
    };
  }, [siteKey, onToken, retry]);

  return <div className="auth-field">
    <div ref={container} />
    {failed && <button className="auth-secondary" type="button" onClick={() => { setFailed(false); setRetry((value) => value + 1); }}>
      Tải lại xác minh chống bot
    </button>}
  </div>;
}
