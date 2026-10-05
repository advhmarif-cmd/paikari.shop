-- The Flutter trade-license upload repository uses this bucket and returns public URLs.
-- Keep this migration idempotent so it is safe to apply to an existing project.
insert into storage.buckets (id, name, public)
values ('paikari-files', 'paikari-files', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists paikari_files_authenticated_select on storage.objects;
create policy paikari_files_authenticated_select
on storage.objects
for select
to authenticated
using (bucket_id = 'paikari-files');

drop policy if exists paikari_files_authenticated_insert on storage.objects;
create policy paikari_files_authenticated_insert
on storage.objects
for insert
to authenticated
with check (bucket_id = 'paikari-files');

drop policy if exists paikari_files_authenticated_update on storage.objects;
create policy paikari_files_authenticated_update
on storage.objects
for update
to authenticated
using (bucket_id = 'paikari-files')
with check (bucket_id = 'paikari-files');
