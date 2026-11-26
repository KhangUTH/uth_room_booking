import assert from 'node:assert/strict';
import { test, after } from 'node:test';
import React from 'react';
import { renderToString } from 'react-dom/server';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import { createServer } from 'vite';
import { getAdminAccess, loadProfile } from '../src/lib/adminAccess.js';

const admin = { id: 'admin-id', email: 'admin@example.com', role: 'admin', is_active: true };

test('only the matching active admin profile receives access', () => {
  assert.equal(getAdminAccess(admin.id, admin).isAdmin, true);
  for (const profile of [null, { ...admin, id: 'other-user' }, { ...admin, role: 'student' }, { ...admin, role: 'ADMIN' }, { ...admin, is_active: false }, { ...admin, is_active: null }]) {
    assert.equal(getAdminAccess(admin.id, profile).isAdmin, false);
    assert.ok(getAdminAccess(admin.id, profile).accessError);
  }
  assert.equal(getAdminAccess(admin.id, admin, new Error('network')).isAdmin, false);
});

test('profile query filters by auth user id and propagates missing data/errors', async () => {
  const controller = new AbortController();
  const calls = [];
  let response = { data: admin, error: null };
  const query = {
    select(value) { calls.push(['select', value]); return this; },
    eq(column, value) { calls.push(['eq', column, value]); return this; },
    abortSignal(signal) { assert.equal(signal, controller.signal); return this; },
    async maybeSingle() { return response; },
  };
  const client = { from(table) { assert.equal(table, 'profiles'); return query; } };
  assert.equal(await loadProfile(client, admin.id, controller.signal), admin);
  assert.deepEqual(calls, [['select', 'id, email, full_name, role, is_active'], ['eq', 'id', admin.id]]);
  response = { data: null, error: null };
  assert.equal(await loadProfile(client, admin.id, controller.signal), null);
  response = { data: null, error: new Error('RLS denied') };
  await assert.rejects(loadProfile(client, admin.id, controller.signal), /RLS denied/);
});

const server = await createServer({ server: { middlewareMode: true }, appType: 'custom' });
after(() => server.close());
const { AuthContext } = await server.ssrLoadModule('/src/contexts/AuthContext.js');
const { default: ProtectedRoute } = await server.ssrLoadModule('/src/components/ProtectedRoute.jsx');
const { default: AuthPage } = await server.ssrLoadModule('/src/pages/Auth/AuthPage.jsx');
const { default: RecordForm } = await server.ssrLoadModule('/src/components/AdminRecords/RecordForm.jsx');
const { default: AppRouters } = await server.ssrLoadModule('/src/routers/AppRouters.jsx');
const { default: AdminOperations } = await server.ssrLoadModule('/src/pages/Admin/AdminOperations/AdminOperations.jsx');
const { default: DetailModal } = await server.ssrLoadModule('/src/components/DetailModal/DetailModal.jsx');
const e = React.createElement;
const baseContext = { session: { user: admin }, loading: false, profileLoading: false, isAdmin: true };

function renderPage(context, path = '/login') {
  return renderToString(e(MemoryRouter, { initialEntries: [path] }, e(AuthContext.Provider, { value: context }, e(AuthPage))));
}

function renderGuard(context) {
  return renderToString(e(MemoryRouter, null, e(AuthContext.Provider, { value: context }, e(Routes, null,
    e(Route, { element: e(ProtectedRoute) }, e(Route, { path: '/', element: e('p', null, 'ADMIN_CONTENT') }))))));
}

test('management pages stay hidden during profile checks and for denied/absent sessions', () => {
  assert.match(renderGuard(baseContext), /ADMIN_CONTENT/);
  for (const context of [
    { ...baseContext, session: null },
    { ...baseContext, isAdmin: false },
    { ...baseContext, profileLoading: true },
    { ...baseContext, loading: true },
  ]) {
    assert.doesNotMatch(renderGuard(context), /ADMIN_CONTENT/);
  }
});

test('denied login offers retry/account switch without redirect loop or password form', () => {
  const html = renderPage({ ...baseContext, isAdmin: false, accessError: 'Không có quyền quản trị' });
  assert.match(html, /Không có quyền quản trị/);
  assert.match(html, /Kiểm tra lại quyền truy cập/);
  assert.match(html, /Đăng xuất và đổi tài khoản/);
  assert.doesNotMatch(html, /<form/);
  assert.match(renderPage({ ...baseContext, profileLoading: true }), /Đang kiểm tra quyền truy cập/);
});

test('recovery stays available to non-admin sessions while profile check is pending', () => {
  const html = renderPage({ ...baseContext, isAdmin: false, profileLoading: true }, '/reset-password');
  assert.match(html, /confirm-password/);
  assert.doesNotMatch(html, /<fieldset disabled/);
  assert.doesNotMatch(html, /Đang kiểm tra quyền truy cập/);
});

test('admin with password-only session is sent to MFA and cannot open management pages', () => {
  const context = { ...baseContext, isAdmin: false, mfaRequired: true };
  assert.match(renderPage(context), /Xác minh hai bước/);
  assert.doesNotMatch(renderPage(context), /id="password"/);
  assert.doesNotMatch(renderGuard(context), /ADMIN_CONTENT/);
});

test('new management routes render loading states without sample rows', () => {
  for (const path of ['/manageruser', '/facilities/rooms', '/facilities/equipment']) {
    const html = renderToString(e(MemoryRouter, { initialEntries: [path] }, e(AuthContext.Provider, { value: { ...baseContext, user: admin } }, e(AppRouters))));
    assert.match(html, /Đang tải dữ liệu/);
    assert.doesNotMatch(html, /Nguyễn Văn A|Phòng Máy - H003|Máy Tính FPT Elead/);
  }
});

test('overview links to pending proposals across both asset types', () => {
  const overview = renderToString(e(MemoryRouter, null, e(AdminOperations, { screen: 'overview' })));
  assert.match(overview, /\?trang-thai=pending&amp;loai=all/);
  const proposals = renderToString(e(MemoryRouter, {
    initialEntries: ['/equipment-proposals?trang-thai=pending&loai=all'],
  }, e(AdminOperations, { screen: 'equipmentProposals' })));
  assert.match(proposals, /aria-current="page"[^>]*>.*?Tất cả/);
  assert.match(proposals, /loai=equipment&amp;trang-thai=pending/);
});

test('incident detail is a named native dialog with an accessible close button', () => {
  const html = renderToString(e(DetailModal, { name: 'Mất tiếng', title: 'Thông tin sự cố', onClose() {} }));
  assert.match(html, /<dialog[^>]*aria-labelledby="([^"]+)"[\s\S]*<h2 id="\1">Mất tiếng<\/h2>/);
  assert.match(html, /type="button" aria-label="Đóng chi tiết"/);
});

test('user edit does not expose password changes and locks own role/active controls', () => {
  const html = renderToString(e(RecordForm, {
    table: 'profiles', record: { ...admin, full_name: 'Admin' }, currentUserId: admin.id,
    references: { roles: ['admin', 'student'], rooms: [], loading: false, error: '' },
    onSave: () => {}, onClose: () => {},
  }));
  assert.match(html, /id="record-role"[^>]*disabled/);
  assert.match(html, /id="record-email"[^>]*disabled/);
  assert.doesNotMatch(html, /type="password"/);
  assert.match(html, /không thể tự đổi vai trò/);
});

test('profile form shows only the code and faculty fields relevant to its role', () => {
  for (const [role, code, faculty] of [
    ['student', 'student_code', true],
    ['teacher', 'lecturer_code', true],
    ['technician', 'employee_code', false],
    ['admin', null, false],
  ]) {
    const html = renderToString(e(RecordForm, {
      table: 'profiles', record: { ...admin, role },
      references: { roles: ['admin', 'student', 'teacher', 'technician'] },
      onSave: () => {}, onClose: () => {},
    }));
    for (const key of ['student_code', 'lecturer_code', 'employee_code']) {
      assert.equal(html.includes(`id="record-${key}"`), key === code);
    }
    assert.equal(html.includes('id="record-faculty"'), faculty);
  }
});

test('equipment form uses real room options and schema fields without fake image/type controls', () => {
  const props = {
    table: 'equipment',
    references: { roles: [], rooms: [{ id: 'room-db-id', name: 'Database room', is_active: true }], loading: false, error: '' },
    onSave: () => {}, onClose: () => {},
  };
  const shared = renderToString(e(RecordForm, { ...props, record: null }));
  assert.match(shared, /Thiết bị dùng chung/);
  assert.doesNotMatch(shared, /id="record-room_id"/);
  const html = renderToString(e(RecordForm, {
    ...props, record: { name: 'Micro', room_id: 'room-db-id', status: 'in_use' },
  }));
  assert.match(html, /value="room-db-id"/);
  assert.match(html, /Database room/);
  assert.match(html, /record-status/);
  assert.match(html, /value="available"/);
  assert.doesNotMatch(html, /value="in_use"/);
  assert.match(html, /Chọn trạng thái mới/);
  assert.match(html, /value="broken"/);
  assert.match(html, /record-note/);
  assert.doesNotMatch(html, /type="file"|Loại Thiết Bị/);
});
