#!/usr/bin/env python3
"""Smoke test end-to-end no NOVO projeto, simulando o app (anon)."""
import json
import urllib.request
import urllib.error

NEW = "https://qzfqkldzvoqvxytvaoaa.supabase.co"
ANON = ("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF6ZnFrbGR6dm9xdnh5dHZhb2FhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY0MDA2NTcsImV4cCI6MjEwMTk3NjY1N30.rmllcXSONo5KXPRrL-jphYdM2xd1Y6MnRnoWoFPf0zs")
GID = "103827fc-3c1c-4f1c-9f88-2e20bb0c6a59"

def call(method, path, token=None, body=None):
    url = f"{NEW}{path}"
    data = json.dumps(body).encode() if body is not None else None
    headers = {"apikey": ANON, "Authorization": f"Bearer {token or ANON}"}
    if body is not None:
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            raw = r.read().decode()
            return r.status, json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()[:400]


code = 0

# 1) anon signin
st, body = call("POST", "/auth/v1/signup", body={})
token = body["access_token"]
anon_uid = body["user"]["id"]
print(f"[1] signInAnonymous OK uid={anon_uid}")

# 2) ler grupos
st, body = call("GET", "/rest/v1/ctg_groups?select=code,name", token=token)
codes = [g["code"] for g in body]
print(f"[2] grupos: {codes}")

# 3) membro por anon (deve vir vazio p/ sessão nova)
st, body = call("GET", f"/rest/v1/ctg_participants?group_id=eq.{GID}&anon_id=eq.{anon_uid}&select=id", token=token)
print(f"[3] findMember(anon nova): {len(body)}")

# 4) INSERT participante (RLS ctg_part_insert, grupo ativo)
st, body = call("POST", "/rest/v1/ctg_participants", token=token,
                body={"group_id": GID, "anon_id": anon_uid, "name": "ZZ MigraçãoTeste", "role": "member"})
print(f"[4] INSERT participant -> {st}")
if st != 201:
    code = 1

st, body = call("GET", f"/rest/v1/ctg_participants?group_id=eq.{GID}&select=id,name", token=token)
pid = next(p["id"] for p in body if "MigraçãoTeste" in p["name"])
print(f"    pid={pid}")

# 5) INSERT drink (RLS ctg_drinks_insert + trigger realtime)
st, body = call("POST", "/rest/v1/ctg_drinks", token=token,
                body={"group_id": GID, "participant_id": pid, "drink_type": "cerveja", "note": "teste-migracao"})
print(f"[5] INSERT drink -> {st}")
if st != 201:
    code = 1

# 6) ranking view deve incluir o teste
st, body = call("GET", f"/rest/v1/ctg_ranking_view?group_id=eq.{GID}&select=name,total_drinks&name=ilike.*MigraçãoTeste*", token=token)
print(f"[6] ranking view teste: {body}")

# 7) activity log gerada por trigger (drink_added)
st, body = call("GET", f"/rest/v1/ctg_activity_log?participant_id=eq.{pid}&select=id,type", token=token)
print(f"[7] activity (trigger): {body}")

print(f"\nRESULTADO: {'OK' if code == 0 else 'FALHA'}")