-- ctg_create_account foi substituído por ctg_ensure_account (escopo por grupo).
-- Nada mais o usa; revoga o acesso público para reduzir superfície.
revoke execute on function public.ctg_create_account(text, text) from anon, authenticated, public;
