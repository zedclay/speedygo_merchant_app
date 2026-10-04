#!/usr/bin/env python3
"""Places <count> COD orders on the isolated branch through the real checkout.

Runs only against the isolated API (127.0.0.1:3100) as the fixture customer
+213550009111, reading the OTP from the isolated capture file. The customer
session is logged out at the end. Never prints tokens or OTPs.
Usage: fx_create_incoming.py <out.json> <count>
"""
import json
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

BASE = 'http://127.0.0.1:3100/api/v1'
OTP = Path.home() / '.speedygo' / 'parity_fx' / 'otp' / 'otp-last'
PHONE = '+213550009111'
BRANCH = '0d00f0f0-fa00-7000-8000-000000002001'
PRODUCT = '0d00f0f0-fa00-7000-8000-000000007003'
ADDRESS = '0d00f0f0-fa00-7000-8000-000000000113'


def req(method, path, token=None, data=None):
    headers = {}
    if token:
        headers['Authorization'] = f'Bearer {token}'
    body = None
    if data is not None:
        body = json.dumps(data).encode()
        headers['Content-Type'] = 'application/json'
    r = urllib.request.Request(BASE + path, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(r, timeout=60) as res:
            return res.status, json.loads(res.read().decode() or '{}')
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode() or '{}')


def login():
    before = time.time() - 1
    s, body = req('POST', '/auth/otp/request',
                  data={'channel': 'PHONE', 'identifier': PHONE, 'purpose': 'AUTHENTICATE'})
    if s not in (200, 201, 202):
        raise SystemExit(f'otp request refused http={s} code={body.get("code")}')
    otp = None
    for _ in range(80):
        if OTP.exists() and OTP.stat().st_mtime >= before:
            otp = OTP.read_text().strip()
            if otp.isdigit():
                break
        time.sleep(0.25)
    if not otp:
        raise SystemExit('isolated OTP capture not found')
    s, body = req('POST', '/auth/otp/verify', data={
        'channel': 'PHONE', 'identifier': PHONE, 'purpose': 'AUTHENTICATE', 'code': otp,
        'platform': 'ios', 'appVersion': '1.0.0', 'deviceName': 'parity-fx-isolated-customer'})
    if s not in (200, 201):
        raise SystemExit(f'otp verify failed http={s} code={body.get("code")}')
    return body['accessToken']


def clear_cart(token):
    s, cart = req('GET', '/customer/cart', token=token)
    if s != 200:
        return
    c = cart.get('cart') or cart
    for it in (c.get('items') or []) if isinstance(c, dict) else []:
        req('DELETE', f'/customer/cart/items/{it["id"]}', token=token)


def main():
    out, count = Path(sys.argv[1]), int(sys.argv[2])
    result = {'api': BASE, 'branchId': BRANCH, 'productId': PRODUCT, 'addressId': ADDRESS,
              'orders': [], 'errors': []}
    token = login()
    try:
        for _ in range(count):
            clear_cart(token)
            s, body = req('POST', '/customer/cart/items', token=token,
                          data={'productId': PRODUCT, 'quantity': 1})
            if s not in (200, 201):
                result['errors'].append(f'cart_add http={s} code={body.get("code")}')
                break
            s, preview = req('POST', '/customer/checkout/preview', token=token, data={'addressId': ADDRESS})
            if s != 200:
                result['errors'].append(f'preview http={s} code={preview.get("code")}')
                break
            s, order = req('POST', '/customer/orders', token=token, data={
                'addressId': ADDRESS, 'paymentMethod': 'COD',
                'expectedMerchandiseSubtotalMinor': int(preview['merchandiseSubtotalMinor']),
                'expectedDeliveryFeeMinor': int(preview['deliveryFeeMinor']),
                'expectedCustomerTotalMinor': int(preview['customerTotalMinor'])})
            if s not in (200, 201):
                result['errors'].append(f'order http={s} code={order.get("code")}')
                break
            result['orders'].append({'id': order['id'], 'publicReference': order.get('publicReference'),
                                     'customerTotalMinor': int(preview['customerTotalMinor'])})
    finally:
        clear_cart(token)
        s, _ = req('POST', '/auth/logout', token=token)
        result['customerLogoutHttp'] = s
        out.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({'orders': [o['id'] for o in result['orders']], 'errors': result['errors'],
                      'logout': result['customerLogoutHttp']}))
    return 0 if len(result['orders']) == count and not result['errors'] else 1


if __name__ == '__main__':
    sys.exit(main())
