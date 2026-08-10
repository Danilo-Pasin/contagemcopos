#!/usr/bin/env python3
"""Faz upload dos arquivos de storage baixados para o novo projeto (service_role)."""
import json
import os
import mimetypes
import urllib.request

NEW_URL = "https://qzfqkldzvoqvxytvaoaa.supabase.co"
SERVICE_ROLE = ("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF6ZnFrbGR6dm9xdnh5dHZhb2FhIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NjQwMDY1NywiZXhwIjoyMTAxOTc2NjU3fQ.TwTaafotI4Uj9NaNG2_ZiUop6S7g5y89ZbVeuolrKBg")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BLOB_DIR = os.path.join(ROOT, "migration_to_new_project", "storage_files")


def main():
    with open(os.path.join(BLOB_DIR, "manifest.json"), encoding="utf-8") as f:
        manifest = json.load(f)

    for bucket, paths in manifest.items():
        for path in paths:
            local = os.path.join(BLOB_DIR, bucket, path.replace("/", "__"))
            ctype = mimetypes.guess_type(path)[0] or "application/octet-stream"
            with open(local, "rb") as fh:
                data = fh.read()
            req = urllib.request.Request(
                f"{NEW_URL}/storage/v1/object/{bucket}/{path}",
                data=data,
                method="POST",
                headers={
                    "Authorization": f"Bearer {SERVICE_ROLE}",
                    "Content-Type": ctype,
                    "x-upsert": "true",
                },
            )
            try:
                with urllib.request.urlopen(req, timeout=120) as r:
                    print(f"[upload] {bucket}/{path} {r.status} ({len(data)}B)")
            except urllib.error.HTTPError as e:
                print(f"[upload] FALHA {bucket}/{path}: {e.code} {e.read().decode()[:200]}")


if __name__ == "__main__":
    main()