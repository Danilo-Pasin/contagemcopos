#!/usr/bin/env python3
"""Gera o dump de dados ctg_* do projeto compartilhado e baixa o storage.

Usa o REST (anon key) — todas as tabelas ctg_* têm SELECT público e os
buckets são públicos, então basta a chave anon do app.
"""
import json
import os
import urllib.request
import urllib.error

OLD_URL = "https://cxuurozyyfcqxywhsiyt.supabase.co"
ANON = ("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN4dXVyb3p5eWZjcXh5d2hzaXl0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE4MDYwOTYsImV4cCI6MjA5NzM4MjA5Nn0.hdZuvQDsVb3Pet-FE7T3RKXjsd8NOx8lrAfoXCg2UWE")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "supabase", "migrations", "20260810000002_contagem_data.sql")
BLOB_DIR = os.path.join(ROOT, "migration_to_new_project", "storage_files")

TABLES = [
    "ctg_accounts",
    "ctg_groups",
    "ctg_achievements",
    "ctg_participants",
    "ctg_drinks",
    "ctg_photos",
    "ctg_activity_log",
    "ctg_participant_achievements",
    "ctg_title_history",
    "ctg_hall_of_fame",
]


def fetch_rows(table):
    url = f"{OLD_URL}/rest/v1/{table}?select=*"
    req = urllib.request.Request(url, headers={
        "apikey": ANON,
        "Authorization": f"Bearer {ANON}",
        "Accept": "application/json",
    })
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode("utf-8"))


def sql_literal(v):
    if v is None:
        return "NULL"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return str(v)
    if isinstance(v, (dict, list)):
        return "'" + json.dumps(v, ensure_ascii=False).replace("'", "''") + "'::jsonb"
    if isinstance(v, str):
        return "'" + v.replace("'", "''") + "'"
    raise TypeError(f"tipo inesperado: {type(v)}")


def dump_data():
    os.makedirs(BLOB_DIR, exist_ok=True)
    lines = [
        "-- ============================================================",
        "-- Contagem — dump de dados (gerado por migration_to_new_project/dump_data.py)",
        "-- Projeto original: cxuurozyyfcqxywhsiyt · 2026-08-10",
        "-- ============================================================",
        "",
        "set session_replication_role = replica;",
        "",
    ]

    for table in TABLES:
        rows = fetch_rows(table)
        print(f"[{table}] {len(rows)} linhas")
        if not rows:
            continue
        cols = list(rows[0].keys())
        col_sql = ", ".join(f'"{c}"' for c in cols)
        values = []
        for row in rows:
            vals = ", ".join(sql_literal(row[c]) for c in cols)
            values.append(f"  ({vals})")
        lines.append(f"insert into public.{table} ({col_sql}) values")
        lines.append(",\n".join(values))
        lines.append(";")
        lines.append("")

    lines += [
        "set session_replication_role = origin;",
        "",
    ]

    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"\nDump escrito em {OUT}")


def list_dir(bucket, prefix=""):
    req = urllib.request.Request(
        f"{OLD_URL}/storage/v1/object/list/{bucket}",
        data=json.dumps({"prefix": prefix, "limit": 1000}).encode(),
        headers={
            "apikey": ANON,
            "Authorization": f"Bearer {ANON}",
            "Content-Type": "application/json",
        },
    )
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode("utf-8"))


def dump_storage():
    manifest = {}
    for bucket in ("drinks", "avatars"):
        top = list_dir(bucket)
        paths = []
        for entry in top:
            if entry.get("metadata") is None:
                folder = entry["name"]
                for f in list_dir(bucket, folder + "/"):
                    paths.append(folder + "/" + f["name"])
            else:
                paths.append(entry["name"])
        bdir = os.path.join(BLOB_DIR, bucket)
        os.makedirs(bdir, exist_ok=True)
        for path in paths:
            dest = os.path.join(bdir, path.replace("/", "__"))
            url = f"{OLD_URL}/storage/v1/object/{bucket}/{path}"
            try:
                urllib.request.urlretrieve(url, dest)
                print(f"[storage] {bucket}/{path} OK")
            except urllib.error.HTTPError as e:
                print(f"[storage] FALHA {bucket}/{path}: {e.code}")
        manifest[bucket] = paths

    with open(os.path.join(BLOB_DIR, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    print("\nManifesto do storage salvo.")


if __name__ == "__main__":
    dump_data()
    dump_storage()
    print("Concluído.")
