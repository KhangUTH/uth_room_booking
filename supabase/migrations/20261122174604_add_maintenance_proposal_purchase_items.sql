alter table public.maintenance_proposals
  add column item_name text check (length(trim(item_name)) between 1 and 160),
  add column quantity integer check (quantity between 1 and 10000),
  add constraint maintenance_proposal_item_pair
    check ((item_name is null) = (quantity is null));

grant insert (item_name, quantity) on public.maintenance_proposals to authenticated;

notify pgrst, 'reload schema';
