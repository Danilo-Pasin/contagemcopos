-- ============================================================
-- Contagem — storage (buckets + políticas)
-- Replica os buckets do projeto original (drinks e avatars).
-- ============================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('drinks', 'drinks', true, null, null),
  ('avatars', 'avatars', true, null, null)
on conflict (id) do nothing;

create policy drinks_public_read on storage.objects
  for select to public using (bucket_id = 'drinks');
create policy drinks_owner_write on storage.objects
  for insert to public with check (
    (bucket_id = 'drinks') and ((storage.foldername(name))[1] = (auth.uid())::text)
  );
create policy drinks_owner_update on storage.objects
  for update to public using (
    (bucket_id = 'drinks') and ((storage.foldername(name))[1] = (auth.uid())::text)
  );

create policy avatars_public_read on storage.objects
  for select to public using (bucket_id = 'avatars');
create policy avatars_owner_write on storage.objects
  for insert to public with check (
    (bucket_id = 'avatars') and ((storage.foldername(name))[1] = (auth.uid())::text)
  );
create policy avatars_owner_update on storage.objects
  for update to public using (
    (bucket_id = 'avatars') and ((storage.foldername(name))[1] = (auth.uid())::text)
  );
