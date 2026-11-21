grant delete on public.app_notifications to authenticated;
create policy app_notifications_delete_own on public.app_notifications for delete to authenticated
using (recipient_id = (select auth.uid()));

create function public.delete_my_app_notifications(notice_ids bigint[])
returns void
language sql set search_path = '' as $$
  delete from public.app_notifications
  where recipient_id = (select auth.uid()) and id = any(notice_ids);
$$;
revoke all on function public.delete_my_app_notifications(bigint[]) from public, anon, authenticated;
grant execute on function public.delete_my_app_notifications(bigint[]) to authenticated;
