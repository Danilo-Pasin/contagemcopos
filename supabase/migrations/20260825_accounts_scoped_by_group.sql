-- Contas nome+senha deixam de ser globais-únicas: o mesmo nome pode existir
-- em grupos diferentes com senhas diferentes. A unicidade passa a valer
-- apenas DENTRO de cada grupo (via ctg_ensure_account).

-- 1) Remove a unicidade global por nome.
drop index if exists public.ctg_accounts_name_key;

-- 2) Garante a conta para um grupo específico:
--    - nome já participante DESTE grupo: valida senha e devolve o id;
--    - mesmo nome+senha já existente em outra conta: reaproveita
--      (mesma pessoa em vários grupos compartilha credenciais);
--    - caso contrário: cria uma conta nova (nomes duplicados entre grupos ok).
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
    return v_id;
  end if;

  insert into public.ctg_accounts(name, password_hash)
  values (v_name, extensions.digest(p_password, 'sha256')::text)
  returning id into v_id;
  return v_id;
end;
$function$;

-- 3) Login por nome+senha agora é ciente do grupo: se houver mais de uma
--    conta com o mesmo nome+senha, prefere a que participa do grupo.
drop function if exists public.ctg_login_account(text, text);

create or replace function public.ctg_login_account(
  p_name text,
  p_password text,
  p_group_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_id uuid;
begin
  select a.id into v_id
    from public.ctg_accounts a
   where lower(a.name) = lower(trim(p_name))
     and a.password_hash = extensions.digest(p_password, 'sha256')::text
   order by exists (
            select 1 from public.ctg_participants p
             where p.account_id = a.id
               and p.group_id = p_group_id
          ) desc,
          a.created_at
   limit 1;

  if v_id is not null then
    -- Re-vincula o anon_id das participações da conta à sessão anônima atual.
    -- O RLS de ctg_drinks/ctg_photos exige anon_id = auth.uid(); sem isso, um
    -- retorno por conta (nome+senha) em outro navegador/sessão cai em 403.
    update public.ctg_participants p
       set anon_id = auth.uid()
     where p.account_id = v_id
       and not exists (
         select 1 from public.ctg_participants o
         where o.group_id = p.group_id
           and o.anon_id = auth.uid()
           and o.id <> p.id
       );
  end if;

  return v_id;
end;
$function$;
