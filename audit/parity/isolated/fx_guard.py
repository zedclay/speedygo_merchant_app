#!/usr/bin/env python3
"""Target guards for the disposable Merchant write-test environment.

The environment may only touch:
  - PostgreSQL database `speedygo_parity_fx` on 127.0.0.1/localhost:5433;
  - Redis database index 9 on 127.0.0.1/localhost:6381;
  - the API on port 3100.

Subcommands (exit 0 = allowed, exit 3 = refused, message on stderr):
  check-db <url>          the isolated database URL
  check-admin-db <url>    the maintenance URL used only for CREATE/DROP of
                          speedygo_parity_fx (database `postgres`, same host/port)
  check-redis <url>       the isolated Redis URL (index 9 only)
  check-name <name>       exact database name before CREATE/DROP
  derive-db               read DATABASE_URL (dev, from the approved .env) and
                          print the isolated URL; the source must itself be local
  derive-admin-db         same, for the maintenance database
  derive-redis            read REDIS_URL and print redis://<host>:6381/9

Derived URLs carry credentials: callers capture them, never print them.
"""
import os
import re
import sys
from urllib.parse import parse_qsl, urlsplit, urlunsplit

FX_DB = 'speedygo_parity_fx'
ADMIN_DB = 'postgres'
ALLOWED_HOSTS = {'127.0.0.1', 'localhost'}
PG_PORT = 5433
REDIS_PORT = 6381
FX_REDIS_DB = 9
RESERVED_REDIS_DBS = {0: 'shared speedygo_dev API', 15: 'backend e2e suite'}
SHARED_DBS = {'speedygo_dev', 'speedygo_test', 'postgres', 'template0', 'template1'}
PRODUCTION_LIKE = re.compile(
    r'(prod|production|live|staging|stage|preprod|release|main|master|primary|replica|backup)',
    re.IGNORECASE,
)
ALLOWED_QUERY = {'schema': {'public'}}


class Refused(Exception):
    pass


def _parse(url: str, schemes: set[str]):
    try:
        parts = urlsplit(url)
        port = parts.port
    except ValueError as exc:
        raise Refused(f'malformed URL ({exc})') from None
    if parts.scheme not in schemes:
        raise Refused(f'scheme {parts.scheme or "<none>"} not allowed')
    if parts.hostname not in ALLOWED_HOSTS:
        raise Refused(f'host {parts.hostname or "<none>"} is not 127.0.0.1/localhost')
    if port is None:
        raise Refused('explicit port required')
    return parts, port


def _query(parts) -> dict[str, str]:
    pairs = parse_qsl(parts.query, keep_blank_values=True)
    out: dict[str, str] = {}
    for key, value in pairs:
        if key not in ALLOWED_QUERY or value not in ALLOWED_QUERY[key]:
            raise Refused(f'query parameter {key!r} not allowed (host/port/dbname overrides refused)')
        out[key] = value
    return out


def check_name(name: str) -> None:
    if name in SHARED_DBS:
        raise Refused(f'database {name!r} is shared; refused')
    if PRODUCTION_LIKE.search(name):
        raise Refused(f'database {name!r} looks production-like; refused')
    if name != FX_DB:
        raise Refused(f'database {name!r} is not exactly {FX_DB!r}')


def check_db(url: str) -> None:
    parts, port = _parse(url, {'postgres', 'postgresql'})
    if port != PG_PORT:
        raise Refused(f'port {port} is not the native Postgres port {PG_PORT}')
    _query(parts)
    name = parts.path.lstrip('/')
    if '/' in name or not name:
        raise Refused('database path must be a single name')
    check_name(name)


def check_admin_db(url: str) -> None:
    parts, port = _parse(url, {'postgres', 'postgresql'})
    if port != PG_PORT:
        raise Refused(f'port {port} is not the native Postgres port {PG_PORT}')
    _query(parts)
    if parts.path != f'/{ADMIN_DB}':
        raise Refused(f'maintenance URL must target {ADMIN_DB!r}')


def check_redis(url: str) -> None:
    parts, port = _parse(url, {'redis'})
    if port != REDIS_PORT:
        raise Refused(f'port {port} is not the SpeedyGo Redis port {REDIS_PORT}')
    if parts.query:
        raise Refused('Redis query parameters not allowed')
    index = parts.path.lstrip('/')
    if index == '':
        raise Refused('Redis index missing (index 0 is the shared speedygo_dev API)')
    if not index.isdigit():
        raise Refused(f'Redis index {index!r} is not numeric')
    if int(index) in RESERVED_REDIS_DBS:
        raise Refused(f'Redis index {index} is reserved for the {RESERVED_REDIS_DBS[int(index)]}')
    if int(index) != FX_REDIS_DB:
        raise Refused(f'Redis index {index} is not the dedicated index {FX_REDIS_DB}')


def _derive_pg(db: str) -> str:
    source = os.environ.get('DATABASE_URL', '')
    if not source:
        raise Refused('DATABASE_URL not set (load apps/backend/.env first)')
    parts, port = _parse(source, {'postgres', 'postgresql'})
    if port != PG_PORT:
        raise Refused(f'source DATABASE_URL port {port} is not {PG_PORT}')
    query = 'schema=public'
    return urlunsplit((parts.scheme, parts.netloc, f'/{db}', query, ''))


def _derive_redis() -> str:
    source = os.environ.get('REDIS_URL', '')
    if not source:
        raise Refused('REDIS_URL not set (load apps/backend/.env first)')
    parts, port = _parse(source, {'redis'})
    if port != REDIS_PORT:
        raise Refused(f'source REDIS_URL port {port} is not {REDIS_PORT}')
    if parts.username or parts.password:
        raise Refused('authenticated Redis is not expected on the local dev port')
    return f'redis://{parts.hostname}:{REDIS_PORT}/{FX_REDIS_DB}'


def main(argv: list[str]) -> int:
    if not argv:
        print(__doc__, file=sys.stderr)
        return 2
    cmd, args = argv[0], argv[1:]
    try:
        if cmd == 'check-db' and len(args) == 1:
            check_db(args[0])
        elif cmd == 'check-admin-db' and len(args) == 1:
            check_admin_db(args[0])
        elif cmd == 'check-redis' and len(args) == 1:
            check_redis(args[0])
        elif cmd == 'check-name' and len(args) == 1:
            check_name(args[0])
        elif cmd == 'derive-db' and not args:
            url = _derive_pg(FX_DB)
            check_db(url)
            print(url)
        elif cmd == 'derive-admin-db' and not args:
            url = _derive_pg(ADMIN_DB)
            check_admin_db(url)
            print(url)
        elif cmd == 'derive-redis' and not args:
            url = _derive_redis()
            check_redis(url)
            print(url)
        else:
            print(f'FX_GUARD usage error: {cmd} {len(args)} args', file=sys.stderr)
            return 2
    except Refused as exc:
        print(f'FX_GUARD_REFUSED {cmd}: {exc}', file=sys.stderr)
        return 3
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
