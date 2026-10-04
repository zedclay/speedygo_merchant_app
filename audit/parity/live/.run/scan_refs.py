"""Lists every (table, column, count) whose value references a fixture ID or phone.

Usage: python3 scan_refs.py <id-or-phone> [...]  (DATABASE via env DB)
Read-only.
"""
import os
import subprocess
import sys

db = os.environ["DB"]
needles = sys.argv[1:]


def psql(sql):
    return subprocess.run(
        ["psql", db, "-X", "-A", "-t", "-F", "|", "-c", sql],
        check=True, capture_output=True, text=True,
    ).stdout.strip()


cols = psql(
    "select table_name, column_name, data_type from information_schema.columns "
    "where table_schema='public' and data_type in ('uuid','text','character varying','jsonb','json') "
    "order by 1,2"
).splitlines()
quoted = ",".join("'" + n.replace("'", "''") + "'" for n in needles)
for line in cols:
    table, column, dtype = line.split("|")
    if dtype in ("json", "jsonb"):
        cond = " or ".join(f"\"{column}\"::text like '%{n}%'" for n in needles)
    else:
        cond = f"\"{column}\"::text in ({quoted})"
    count = psql(f'select count(*) from "{table}" where {cond}')
    if count != "0":
        print(f"{table}.{column} = {count}")
