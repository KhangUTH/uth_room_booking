import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createAdminUserHandler } from '../../supabase/functions/admin-create-user/handler.js';

const payload = { email: 'new@example.com', password: 'pass123456', profile: { full_name: 'New user', role: 'student', is_active: true } };
function fixture(options = {}) {
  const calls = [];
  const admin = {
    auth: {
      getUser: async (token) => { calls.push(['verify', token]); return options.invalidToken ? { data: { user: null }, error: {} } : { data: { user: { id: 'caller' } }, error: null }; },
      admin: {
        createUser: async (input) => { calls.push(['create', input]); return options.duplicate ? { data: {}, error: { code: 'email_exists' } } : { data: { user: { id: 'new-id', email: payload.email } }, error: null }; },
        deleteUser: async (id) => { calls.push(['rollback', id]); return { error: options.cleanupError ? {} : null }; },
      },
    },
    from(table) {
      assert.equal(table, 'profiles');
      return {
        select() { return this; },
        eq() { return this; },
        async maybeSingle() { return { data: { role: options.role || 'admin', is_active: !options.inactive }, error: null }; },
        async upsert(profile, config) { calls.push(['profile', profile, config]); return { error: options.profileError ? {} : null }; },
      };
    },
    async rpc(name) { assert.equal(name, 'admin_user_roles'); return { data: ['admin', 'student'], error: null }; },
  };
  const handler = createAdminUserHandler((_url, _key, config) => {
    calls.push(['client', config]);
    return admin;
  }, (name) => name === 'SUPABASE_URL' ? 'https://test.supabase.co' : 'server-only-key');
  return { handler, calls };
}
const request = (body = payload, token = 'valid-jwt') => new Request('https://test/endpoint', { method: 'POST', headers: token ? { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' } : {}, body: JSON.stringify(body) });

test('missing/invalid JWT cannot create Auth users', async () => {
  const missing = fixture();
  assert.equal((await missing.handler(request(payload, ''))).status, 401);
  assert.equal(missing.calls.length, 0);
  const invalid = fixture({ invalidToken: true });
  assert.equal((await invalid.handler(request())).status, 401);
  assert.equal(invalid.calls.some(([call]) => call === 'create'), false);
});

test('current database admin role and active flag are required server-side', async () => {
  for (const options of [{ role: 'student' }, { inactive: true }]) {
    const { handler, calls } = fixture(options);
    assert.equal((await handler(request())).status, 403);
    assert.equal(calls.some(([call]) => call === 'create'), false);
  }
});

test('valid admin creates Auth user plus profile and never returns password or secret', async () => {
  const { handler, calls } = fixture();
  const response = await handler(request());
  assert.equal(response.status, 201);
  assert.deepEqual(await response.json(), { id: 'new-id' });
  const created = calls.find(([call]) => call === 'create')[1];
  assert.equal(created.email_confirm, true);
  assert.equal(created.user_metadata.role, undefined);
  const profile = calls.find(([call]) => call === 'profile')[1];
  assert.equal(profile.id, 'new-id');
  assert.equal(profile.email, payload.email);
  assert.equal(profile.role, 'student');
  assert.equal(profile.password, undefined);
  assert.ok(calls.some(([call, config]) => call === 'client' && config.global?.headers.Authorization === 'Bearer valid-jwt'));
});

test('profile failure rolls back only the newly created Auth account', async () => {
  const { handler, calls } = fixture({ profileError: true });
  const response = await handler(request());
  assert.equal(response.status, 500);
  assert.deepEqual(calls.find(([call]) => call === 'rollback'), ['rollback', 'new-id']);
  assert.match((await response.json()).message, /thu hồi/);
});

test('cleanup failure tells admin to inspect account before retrying', async () => {
  const { handler } = fixture({ profileError: true, cleanupError: true });
  assert.match((await (await handler(request())).json()).message, /kiểm tra trước khi tạo lại/);
});

test('duplicate email or invalid role never upserts another profile', async () => {
  const duplicate = fixture({ duplicate: true });
  assert.equal((await duplicate.handler(request())).status, 409);
  assert.equal(duplicate.calls.some(([call]) => call === 'profile'), false);
  const invalid = fixture();
  assert.equal((await invalid.handler(request({ ...payload, profile: { ...payload.profile, role: 'invented-role' } }))).status, 400);
  assert.equal(invalid.calls.some(([call]) => call === 'create'), false);
});
