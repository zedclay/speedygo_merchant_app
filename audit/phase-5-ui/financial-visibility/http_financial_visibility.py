#!/usr/bin/env python3
"""HTTP verification of Merchant financial visibility against the local dev
backend (http://127.0.0.1:3000) and the isolated sgo_finvis_* fixture.

Phases: OTP login (owner, manager, staff) -> seed fixture (psql) -> checks ->
session logout. Tokens stay in memory; OTP codes and DB URLs are never printed.
Response bodies are written to ./http/ as evidence.

Usage: python3 http_financial_visibility.py [--skip-seed]
"""
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / "http"
BACKEND = Path("/Users/mac/Downloads/speedygo_project/apps/backend")
BASE = "http://127.0.0.1:3000/api/v1"
OTP_FILE = Path("/Users/mac/.speedygo/dev/otp-last")

MERCHANT = "0d00c071-d000-7000-8000-000000010001"
BRANCH = "0d00c071-d000-7000-8000-000000011001"
FOREIGN_MERCHANT = "0d00c071-d000-7000-8000-000000010002"
FOREIGN_BRANCH = "0d00c071-d000-7000-8000-000000011002"
PHONES = {"OWNER": "0550000071", "MANAGER": "0550000082", "STAFF": "0550000081"}

RESTRICTED_KEYS = [
    "merchantDiscountMinor",
    "merchantCommissionRateBps",
    "merchantCommissionAmountMinor",
    "merchantNetAmountMinor",
]
STAFF_KEYS = ["currency", "deliveryFeeMinor", "grossMerchandiseSubtotalMinor"]
RESTRICTED_TERMS = re.compile(r"commission|merchantNet|discount|settlement|refund", re.I)

results = []


def check(cid, ok, detail=""):
    results.append({"id": cid, "status": "PASS" if ok else "FAIL", "detail": detail})
    print(f"{'PASS' if ok else 'FAIL'} {cid} {detail}")


def call(method, path, token=None, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(BASE + path, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            raw = resp.read().decode()
            return resp.status, (json.loads(raw) if raw else None)
    except urllib.error.HTTPError as err:
        raw = err.read().decode()
        return err.code, (json.loads(raw) if raw else None)


def save(name, status, body):
    (OUT / f"{name}.json").write_text(
        json.dumps({"status": status, "body": body}, indent=2, ensure_ascii=False)
    )


def login(phone):
    before = time.time() - 1
    status, _ = call(
        "POST",
        "/auth/otp/request",
        body={"channel": "PHONE", "identifier": phone, "purpose": "AUTHENTICATE"},
    )
    if status not in (200, 201, 202):
        raise SystemExit(f"otp request failed for fixture phone ({status})")
    for _ in range(80):
        if OTP_FILE.exists() and OTP_FILE.stat().st_mtime >= before:
            code = OTP_FILE.read_text().strip()
            if re.fullmatch(r"\d{4,8}", code):
                break
        time.sleep(0.25)
    else:
        raise SystemExit("dev OTP capture not found")
    status, body = call(
        "POST",
        "/auth/otp/verify",
        body={
            "channel": "PHONE", "identifier": phone, "purpose": "AUTHENTICATE", "code": code,
            "platform": "web", "appVersion": "finvis-http-check",
        },
    )
    if status not in (200, 201):
        raise SystemExit(f"otp verify failed ({status})")
    return body["accessToken"]


def seed():
    env = dict(os.environ)
    for line in (BACKEND / ".env").read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            env[k.strip()] = v.strip().strip('"').strip("'")
    db = env["DATABASE_URL"].split("?", 1)[0]
    proc = subprocess.run(
        [
            "psql", db, "-v", "staff_phone=+213550000081", "-v", "manager_phone=+213550000082",
            "-f", str(HERE / "seed_financial_visibility_fixture.sql"),
        ],
        capture_output=True, text=True,
    )
    (HERE / "seed_output.txt").write_text(proc.stdout + proc.stderr)
    if proc.returncode != 0:
        raise SystemExit("seed failed; see seed_output.txt")


def order_by_ref(items, ref):
    return next((i for i in items if i.get("publicReference") == ref), None)


def main():
    OUT.mkdir(exist_ok=True)
    tokens = {role: login(phone) for role, phone in PHONES.items()}
    print("logged in: OWNER, MANAGER, STAFF (tokens kept in memory)")
    if "--skip-seed" not in sys.argv:
        seed()
        print("fixture seeded (seed_output.txt)")

    listing = {}
    for role in ("OWNER", "MANAGER", "STAFF"):
        status, body = call("GET", f"/merchant/{MERCHANT}/orders?branchId={BRANCH}", tokens[role])
        save(f"{role.lower()}_orders_list", status, body)
        listing[role] = body
        check(f"{role}.list.status", status == 200, str(status))

    ids = {}
    for ref in ("sgo_finvis_1", "sgo_finvis_2"):
        item = order_by_ref(listing["OWNER"]["items"], ref)
        ids[ref] = item["id"] if item else None
    check("fixture.orders.visible", all(ids.values()), json.dumps(ids))
    order_a = ids["sgo_finvis_1"]

    details = {}
    for role in ("OWNER", "MANAGER", "STAFF"):
        status, body = call("GET", f"/merchant/{MERCHANT}/orders/{order_a}", tokens[role])
        save(f"{role.lower()}_order_detail", status, body)
        details[role] = body
        check(f"{role}.detail.status", status == 200, str(status))

    for role in ("OWNER", "MANAGER"):
        d = details[role]
        fin = d["financial"]
        check(
            f"{role}.detail.granted",
            d["financialAccess"] == "GRANTED" and all(k in fin for k in RESTRICTED_KEYS),
            json.dumps(fin),
        )
        check(
            f"{role}.detail.values",
            fin["merchantDiscountMinor"] == "5000"
            and fin["merchantCommissionAmountMinor"] == "17500"
            and fin["merchantNetAmountMinor"] == "232500"
            and fin["merchantCommissionRateBps"] == 700,
        )
        item = order_by_ref(listing[role]["items"], "sgo_finvis_1")
        check(f"{role}.list.granted", item["financialAccess"] == "GRANTED"
              and all(k in item["financial"] for k in RESTRICTED_KEYS))

    staff = details["STAFF"]
    check("STAFF.detail.restricted", staff["financialAccess"] == "ROLE_RESTRICTED",
          staff["financialAccess"])
    check("STAFF.detail.keys", sorted(staff["financial"].keys()) == STAFF_KEYS,
          json.dumps(staff["financial"]))
    check("STAFF.detail.no_terms", not RESTRICTED_TERMS.search(json.dumps(staff)))
    check("STAFF.detail.gross_matches_owner",
          staff["financial"]["grossMerchandiseSubtotalMinor"]
          == details["OWNER"]["financial"]["grossMerchandiseSubtotalMinor"] == "255000")
    check("STAFF.detail.items_match_owner", staff["items"] == details["OWNER"]["items"])
    for item in listing["STAFF"]["items"]:
        if not item["publicReference"].startswith("sgo_finvis_"):
            continue
        check(f"STAFF.list.{item['publicReference']}",
              item["financialAccess"] == "ROLE_RESTRICTED"
              and sorted(item["financial"].keys()) == STAFF_KEYS)
    check("STAFF.list.no_terms", not RESTRICTED_TERMS.search(json.dumps(listing["STAFF"])))

    for action, body in (
        ("accept", {}),
        ("reject", {"reason": "Fixture check"}),
        ("start-preparation", {}),
        ("mark-ready", {}),
        ("preparation-estimate", {"addMinutes": 5, "expectedEstimateVersion": 1}),
    ):
        status, resp = call("POST", f"/merchant/{MERCHANT}/orders/{order_a}/{action}",
                            tokens["STAFF"], body)
        save(f"staff_{action}", status, resp)
        check(f"STAFF.mutation.{action}",
              status == 403 and resp["error"]["code"] == "MERCHANT_ROLE_FORBIDDEN"
              and not RESTRICTED_TERMS.search(json.dumps(resp)), str(status))
    status, after = call("GET", f"/merchant/{MERCHANT}/orders/{order_a}", tokens["OWNER"])
    check("STAFF.mutation.no_state_change",
          after["status"] == "CREATED" and after["fulfillmentStatus"] == "PENDING_ACCEPTANCE")

    status, resp = call("GET", f"/merchant/{MERCHANT}/orders?branchId={FOREIGN_BRANCH}", tokens["STAFF"])
    save("staff_foreign_branch", status, resp)
    check("STAFF.foreign_branch", status == 404
          and resp["error"]["code"] == "MERCHANT_BRANCH_NOT_FOUND", str(status))
    status, resp = call("GET", f"/merchant/{FOREIGN_MERCHANT}/orders", tokens["STAFF"])
    save("staff_foreign_merchant", status, resp)
    check("STAFF.foreign_merchant", status == 404
          and resp["error"]["code"] == "MERCHANT_NOT_FOUND", str(status))
    status, resp = call("GET", f"/merchant/{FOREIGN_MERCHANT}/orders/{order_a}", tokens["STAFF"])
    check("STAFF.foreign_merchant_order", status == 404, str(status))

    status, resp = call("GET", f"/merchant/{MERCHANT}/commission", tokens["STAFF"])
    save("staff_commission", status, resp)
    check("STAFF.commission_forbidden", status == 403, str(status))
    status, resp = call("GET", f"/merchant/{MERCHANT}/settlements", tokens["STAFF"])
    save("staff_settlements", status, resp)
    check("STAFF.settlements_forbidden", status == 403, str(status))

    sales = {}
    for role in ("OWNER", "STAFF"):
        status, body = call("GET", f"/merchant/{MERCHANT}/reports/sales?period=TODAY&branchId={BRANCH}",
                            tokens[role])
        save(f"{role.lower()}_reports_sales_today", status, body)
        sales[role] = body
        check(f"{role}.reports.status", status == 200, str(status))
    check("OWNER.reports.granted", sales["OWNER"]["financeAccess"] == "GRANTED"
          and sales["OWNER"]["finance"] is not None, json.dumps(sales["OWNER"].get("finance")))
    check("STAFF.reports.restricted", sales["STAFF"]["financeAccess"] == "ROLE_RESTRICTED"
          and sales["STAFF"]["finance"] is None)
    check("STAFF.reports.sales_match_owner",
          sales["STAFF"]["grossMerchandiseMinor"] == sales["OWNER"]["grossMerchandiseMinor"]
          and sales["STAFF"]["completedOrderCount"] == sales["OWNER"]["completedOrderCount"],
          f"gross={sales['STAFF']['grossMerchandiseMinor']} count={sales['STAFF']['completedOrderCount']}")
    status, top = call("GET", f"/merchant/{MERCHANT}/reports/top-products?period=TODAY&sort=REVENUE"
                       f"&branchId={BRANCH}", tokens["STAFF"])
    save("staff_reports_top_revenue", status, top)
    check("STAFF.reports.top_revenue", status == 200 and bool(top["items"])
          and all("revenueMinor" in i for i in top["items"]), str(status))

    for role, token in tokens.items():
        call("POST", "/auth/logout", token)
    print("sessions revoked")

    summary = {
        "layer": "http",
        "backend": BASE,
        "fixture": "Dar El Bahja synthetic + sgo_finvis_* (speedygo_dev)",
        "at": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        "passed": sum(r["status"] == "PASS" for r in results),
        "failed": sum(r["status"] == "FAIL" for r in results),
        "results": results,
    }
    (HERE / "HTTP_RESULTS.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False))
    print(f"HTTP_RESULTS passed={summary['passed']} failed={summary['failed']}")
    return 0 if summary["failed"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
