import { useEffect, useRef, useState } from "react";
import { authErrorMessage } from "../../lib/authErrors.js";

export default function AdminMfaForm({ client, onSignOut, signingOut }) {
  const [factors, setFactors] = useState(null);
  const [factorId, setFactorId] = useState("");
  const [enrollment, setEnrollment] = useState(null);
  const [code, setCode] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [retry, setRetry] = useState(0);
  const inFlight = useRef(false);

  useEffect(() => {
    let active = true;
    client.auth.mfa.listFactors().then(({ data, error: failure }) => {
      if (!active) return;
      if (failure) setError(authErrorMessage(failure));
      else {
        setFactors(data.all);
        setFactorId(data.totp[0]?.id ?? "");
      }
    }).catch((failure) => { if (active) setError(authErrorMessage(failure)); });
    return () => { active = false; };
  }, [client, retry]);

  const verified = factors?.filter((factor) => factor.factor_type === "totp" && factor.status === "verified") ?? [];

  async function run(action) {
    if (inFlight.current || signingOut) return;
    inFlight.current = true;
    setBusy(true);
    setError("");
    try { await action(); }
    catch (failure) { setError(authErrorMessage(failure)); }
    finally { inFlight.current = false; setBusy(false); }
  }

  function startEnrollment() {
    return run(async () => {
      const { data, error: failure } = await client.auth.mfa.enroll({ factorType: "totp" });
      if (failure) throw failure;
      setEnrollment(data.totp);
      setFactorId(data.id);
    });
  }

  function verify(event) {
    event.preventDefault();
    if (!factorId || !/^\d{6}$/.test(code)) return;
    return run(async () => {
      const { error: failure } = await client.auth.mfa.challengeAndVerify({ factorId, code });
      if (failure) throw failure;
      setCode("");
    });
  }

  return <div className="auth-access-denied">
    {error && <p className="auth-message auth-error" role="alert">{error}</p>}
    {!factors && (error
      ? <button className="auth-secondary" onClick={() => { setError(""); setRetry((value) => value + 1); }}>Thử lại</button>
      : <p role="status">Đang tải phương thức xác minh…</p>)}
    {factors && !factorId && <button className="auth-submit" disabled={busy || signingOut} onClick={startEnrollment}>
      {busy ? "Đang thiết lập…" : "Thiết lập ứng dụng xác thực"}
    </button>}
    {enrollment && <div className="auth-field">
      <p>Quét mã QR bằng ứng dụng xác thực, rồi nhập mã 6 chữ số.</p>
      <img src={enrollment.qr_code} alt="Mã QR để thiết lập ứng dụng xác thực" width="180" height="180" />
      <details><summary>Nhập khóa thiết lập thủ công</summary><code>{enrollment.secret}</code></details>
    </div>}
    {factorId && <form onSubmit={verify}>
      <fieldset disabled={busy || signingOut}>
        {verified.length > 1 && <div className="auth-field">
          <label htmlFor="mfa-factor">Ứng dụng xác thực</label>
          <select id="mfa-factor" value={factorId} onChange={(event) => { setFactorId(event.target.value); setCode(""); }}>
            {verified.map((factor, index) => <option key={factor.id} value={factor.id}>{factor.friendly_name || `Thiết bị ${index + 1}`}</option>)}
          </select>
        </div>}
        <div className="auth-field">
          <label htmlFor="mfa-code">Mã xác thực</label>
          <input id="mfa-code" value={code} onChange={(event) => setCode(event.target.value.replace(/\D/g, ""))}
            inputMode="numeric" autoComplete="one-time-code" pattern="[0-9]{6}" maxLength={6} required />
        </div>
        <button className="auth-submit" type="submit" aria-busy={busy}>{busy ? "Đang xác minh…" : "Xác minh"}</button>
      </fieldset>
    </form>}
    <button className="auth-secondary" disabled={busy || signingOut} onClick={onSignOut}>Đăng xuất và đổi tài khoản</button>
  </div>;
}
