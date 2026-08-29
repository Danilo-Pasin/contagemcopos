-- Re-vincula o anon_id das participações da conta à sessão anônima atual no
-- login por nome+senha (ctg_ensure_account), replicando o backfill que existia
-- no ctg_login_account (hoje não chamado pelo app).
--
-- Sem isso, quem reentra por conta (nome+senha) num contexto novo (novo
-- navegador/PWA, site-data limpo, aba anônima) mantém o anon_id da sessão
-- original na linha de ctg_participants. O RLS de ctg_participants/
-- ctg_drinks/ctg_photos exige anon_id = auth.uid(); o resultado é atualização
-- de foto de perfil (e +1 bebida/foto) bloqueada em silêncio (0 linhas).
--
-- Guarda NOT EXISTS: evita violar o unique (group_id, anon_id) quando a
-- sessão anônima atual já pertence a outro participante do mesmo grupo.
create or replace function public.ctg_ensure_account(
  p_name text,
  p_password text,
  p_group_id uuid
)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_id uuid;
  v_name text := trim(p_name);
begin
  select a.id into v_id
    from public.ctg_accounts a
    join public.ctg_participants p on p.account_id = a.id
   where p.group_id = p_group_id
     and lower(a.name) = lower(v_name)
   limit 1;

  if v_id is not null then
    if (select a.password_hash
          from public.ctg_accounts a
         where a.id = v_id)
        <> extensions.digest(p_password, 'sha256')::text then
      raise exception 'Já existe alguém como "%" neste grupo com outra senha.', v_name;
    end if;

    -- Re-vincula o anon_id das participações da conta à sessão anônima atual.
    update public.ctg_participants p
       set anon_id = auth.uid()
     where p.account_id = v_id
       and not exists (
         select 1 from public.ctg_participants o
         where o.group_id = p.group_id
           and o.anon_id = auth.uid()
           and o.id <> p.id
       );

    return v_id;
  end if;

  -- Reaproveita conta global com MESMO nome E senha (mesma pessoa).
  select a.id into v_id
    from public.ctg_accounts a
   where lower(a.name) = lower(v_name)
     and a.password_hash = extensions.digest(p_password, 'sha256')::text
   order by a.created_at
   limit 1;
  if v_id is not null then
    -- Re-vincula as participações já existentes da conta (todos os grupos).
    update public.ctg_participants p
       set anon_id = auth.uid()
     where p.account_id = v_id
       and not exists (
         select 1 from public.ctg_participants o
         where o.group_id = p.group_id
           and o.anon_id = auth.uid()
           and o.id <> p.id
       );
    return v_id;
  end if;

  insert into public.ctg_accounts(name, password_hash)
  values (v_name, extensions.digest(p_password, 'sha256')::text)
  returning id into v_id;
  return v_id;
end;
$function$;