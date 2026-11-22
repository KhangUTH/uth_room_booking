import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createClient } from '@supabase/supabase-js';
import { archiveRecord, dataErrorMessage, deleteRecord, listRecords, loadReferences, recordPayload, saveRecord, searchFilter } from '../src/lib/adminData.js';
import { validateCreateUser } from '../../../supabase/functions/admin-create-user/validation.js';

function fixture(respond) {
  const requests = [];
  const client = createClient('https://test.supabase.co', 'test-publishable-key', {
    auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
    global: { fetch: async (url, init = {}) => {
      const request = { url: new URL(url), method: init.method || 'GET', body: init.body ? JSON.parse(init.body) : null, headers: new Headers(init.headers) };
      requests.push(request);
      const response = await respond(request, requests.length);
      return new Response(JSON.stringify(response.body), { status: response.status || 200, headers: { 'content-type': 'application/json', ...response.headers } });
    } },
  });
  return { client, requests };
}

test('database pagination, exact count, stable sort, search and archive filter use actual SDK requests', async () => {
  const { client, requests } = fixture(() => ({ body: [{ id: 'room-1', name: 'H001' }], headers: { 'content-range': '10-10/21' } }));
  const result = await listRecords(client, 'rooms', { page: 2, search: 'H001', filter: 'active' });
  assert.equal(result.count, 21);
  assert.equal(result.rows[0].id, 'room-1');
  const query = requests[0].url.searchParams;
  assert.equal(query.get('offset'), '10');
  assert.equal(query.get('limit'), '10');
  assert.equal(query.get('is_archived'), 'eq.false');
  assert.equal(query.get('is_active'), 'eq.true');
  assert.equal(query.get('order'), 'created_at.desc,id.asc');
  assert.ok(query.get('or').includes('name.ilike.'));
  assert.match(requests[0].headers.get('prefer'), /count=exact/);
});

test('equipment requests use the real room relation and filter by room id', async () => {
  const { client, requests } = fixture(() => ({ body: [], headers: { 'content-range': '*/0' } }));
  await listRecords(client, 'equipment', { filter: 'room-id' });
  assert.match(requests[0].url.searchParams.get('select'), /room:rooms\(id,name,location\)/);
  assert.equal(requests[0].url.searchParams.get('room_id'), 'eq.room-id');
});

test('search quotes user input and escapes wildcard characters', () => {
  assert.equal(searchFilter(['name'], '  A_%  '), 'name.ilike.' + JSON.stringify('%A\\_\\%%'));
  assert.equal(searchFilter(['name'], '",id.neq.null)'), 'name.ilike.' + JSON.stringify('%",id.neq.null)%'));
});

test('writes whitelist schema columns and validate integer capacity and required text', () => {
  assert.deepEqual(recordPayload('rooms', { name: ' H001 ', location: ' ', capacity: '40', is_active: true, image: 'fake' }), { name: 'H001', location: null, capacity: 40, is_active: true });
  for (const capacity of ['0', '-1', '1.2', '', '2147483648']) {
    assert.throws(() => recordPayload('rooms', { name: 'H001', capacity }));
  }
  assert.throws(() => recordPayload('equipment', { name: ' ', status: 'active' }));
  assert.throws(() => recordPayload('equipment', { name: 'PC', status: ' ' }));
  assert.deepEqual(recordPayload('equipment', { name: 'PC', room_id: '', status: ' available ', note: '', location: '' }), { name: 'PC', room_id: null, status: 'available', note: null, location: null });
  for (const status of ['available', 'in_use', 'broken']) assert.equal(recordPayload('equipment', { name: 'PC', status }).status, status);
  assert.throws(() => recordPayload('equipment', { name: 'PC', status: 'active' }));
});

test('room create sets unarchived; updates target a single row and surface RLS failures', async () => {
  const good = fixture((request) => ({ body: { id: 'r1', ...request.body } }));
  await saveRecord(good.client, 'rooms', { name: 'H001', capacity: '40', is_active: true });
  assert.equal(good.requests[0].method, 'POST');
  assert.equal(good.requests[0].body.is_archived, false);
  const bad = fixture(() => ({ status: 403, body: { code: '42501', message: 'permission denied' } }));
  await assert.rejects(saveRecord(bad.client, 'rooms', { name: 'H001', capacity: '40', is_active: true }, 'r1'), (error) => error.code === '42501');
  assert.equal(bad.requests[0].url.searchParams.get('id'), 'eq.r1');
  assert.match(dataErrorMessage({ code: '42501' }), /RLS/);
});

test('archiving/disabling preserves rows and never sends DELETE', async () => {
  const { client, requests } = fixture(() => ({ body: { id: 'id1' } }));
  await archiveRecord(client, 'profiles', { id: 'id1' });
  await archiveRecord(client, 'rooms', { id: 'id1', is_archived: false });
  await archiveRecord(client, 'rooms', { id: 'id1', is_archived: true });
  assert.deepEqual(requests.map((request) => request.body), [{ is_active: false }, { is_archived: true }, { is_archived: false }]);
  assert.ok(requests.every((request) => request.method === 'PATCH'));
  await assert.rejects(archiveRecord(client, 'equipment', { id: 'id1' }));
});

test('permanent delete targets one specific room/equipment and rejects other tables or missing ids', async () => {
  const { client, requests } = fixture(() => ({ body: { id: 'test-id' } }));
  for (const table of ['rooms', 'equipment']) {
    assert.deepEqual(await deleteRecord(client, table, 'test-id'), { id: 'test-id' });
  }
  assert.equal(requests.length, 2);
  for (const request of requests) {
    assert.equal(request.method, 'DELETE');
    assert.equal(request.url.searchParams.get('id'), 'eq.test-id');
    assert.equal(request.url.searchParams.get('select'), 'id');
  }
  await assert.rejects(deleteRecord(client, 'profiles', 'test-id'));
  await assert.rejects(deleteRecord(client, 'rooms', ''));
  await assert.rejects(deleteRecord(client, 'equipment', undefined));
  assert.equal(requests.length, 2);
});

test('delete surfaces RLS denial and explains foreign-key references without cascade requests', async () => {
  const denied = fixture(() => ({ status: 403, body: { code: '42501', message: 'denied' } }));
  await assert.rejects(deleteRecord(denied.client, 'equipment', 'test-id'), (error) => error.code === '42501');
  const linked = fixture(() => ({ status: 409, body: { code: '23503', message: 'foreign key violation' } }));
  await assert.rejects(deleteRecord(linked.client, 'rooms', 'test-id'), (error) => /tham chiếu/.test(error.userMessage));
  assert.equal(linked.requests.length, 1);
  const missing = fixture(() => ({ status: 406, body: { code: 'PGRST116', message: 'zero rows' } }));
  await assert.rejects(deleteRecord(missing.client, 'equipment', 'test-id'), (error) => /đã bị xóa/.test(error.userMessage));
});

test('room selector loads beyond 1000 rows and user roles come from database RPC', async () => {
  const { client, requests } = fixture((request) => {
    if (request.url.pathname.includes('/rpc/')) return { body: ['admin', 'actual_database_role'] };
    const offset = Number(request.url.searchParams.get('offset'));
    return { body: Array.from({ length: offset < 1000 ? 500 : 1 }, (_, index) => ({ id: `${offset + index}`, name: 'Room' })) };
  });
  assert.equal((await loadReferences(client, 'equipment')).rooms.length, 1001);
  assert.deepEqual((await loadReferences(client, 'profiles')).roles, ['admin', 'actual_database_role']);
  assert.ok(requests[3].url.pathname.endsWith('/rpc/admin_user_roles'));
});

test('new users are sent to server function, never inserted directly from frontend', async () => {
  const { client, requests } = fixture(() => ({ status: 201, body: { id: 'new-id' } }));
  await saveRecord(client, 'profiles', { email: 'test@example.com', password: 'pass123456', full_name: 'Test', role: 'admin', is_active: true });
  assert.equal(requests.length, 1);
  assert.ok(requests[0].url.pathname.endsWith('/functions/v1/admin-create-user'));
  assert.equal(requests[0].body.profile.role, 'admin');
  assert.equal(requests[0].body.profile.password, undefined);
});

test('server validation rejects unknown enum roles, weak input and strips injected fields', () => {
  const body = { email: 'test@example.com', password: 'pass123456', profile: { full_name: ' Test ', role: 'student', is_active: true, id: 'injected', email: 'wrong@example.com', created_at: 'injected' } };
  const validated = validateCreateUser(body, ['admin', 'student']);
  assert.equal(validated.profile.full_name, 'Test');
  assert.equal(validated.profile.id, undefined);
  assert.equal(validated.profile.email, undefined);
  assert.throws(() => validateCreateUser(body, ['admin']), /Vai trò/);
  assert.throws(() => validateCreateUser({ ...body, password: 'short' }, ['student']), /Mật khẩu/);
  assert.throws(() => validateCreateUser({ ...body, email: 'invalid' }, ['student']), /Email/);
});
