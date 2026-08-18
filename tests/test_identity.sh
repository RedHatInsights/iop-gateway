#!/bin/bash

source tests/common.sh

set -e

function test_identity_without_forwarded() {
    echo "Testing identity handling without Forwarded header..."

    identity=$(curl -s -4 --key "$CERT_DIR/client.key" --cert "$CERT_DIR/client.crt" --cacert "$CERT_DIR/ca.crt" "$GATEWAY_URL/_identity" | base64 -d)

    # test that the identity type is User
    if [[ $(jq -e -r '.identity.type' <<< "$identity") != "User" ]]; then
        echo "$identity"
        echo "[${FUNCNAME[0]}][FAIL] Identity type is not User"
        exit 1
    fi

    # test that the identity has the correct org_id
    if [[ $(jq -e -r '.identity.org_id' <<< "$identity") != "1" ]]; then
        echo "$identity"
        echo "[${FUNCNAME[0]}] FAIL: Identity org_id is not 1"
        exit 1
    fi

    echo "[${FUNCNAME[0]}] PASS"
}

function test_identity_with_forwarded() {
    echo "Testing identity handling with Forwarded header..."

    identity=$(curl -s -4 -H "Forwarded: for=\"_00000000-0000-0000-0000-000000000000\"" --key "$CERT_DIR/client.key" --cert "$CERT_DIR/client.crt" --cacert "$CERT_DIR/ca.crt" "$GATEWAY_URL/_identity" | base64 -d)

    # test that the identity type is System
    if [[ $(jq -e -r '.identity.type' <<< "$identity") != "System" ]]; then
        echo "$identity"
        echo "[${FUNCNAME[0]}][FAIL] Identity type is not System"
        exit 1
    fi

    # test that the identity has the correct auth_type
    if [[ $(jq -e -r '.identity.auth_type' <<< "$identity") != "cert-auth" ]]; then
        echo "$identity"
        echo "[${FUNCNAME[0]}] FAIL: Identity auth_type is not cert-auth"
        exit 1
    fi

    # test that the identity has the correct org_id
    if [[ $(jq -e -r '.identity.org_id' <<< "$identity") != "1" ]]; then
        echo "$identity"
        echo "[${FUNCNAME[0]}] FAIL: Identity org_id is not 1"
        exit 1
    fi

    # test that the identity has the correct system cn
    if [[ $(jq -e -r '.identity.system.cn' <<< "$identity") != "00000000-0000-0000-0000-000000000000" ]]; then
        echo "$identity"
        echo "[${FUNCNAME[0]}] FAIL: Identity system cn is not as per Forwarded header (for=_CN)"
        exit 1
    fi

    echo "[${FUNCNAME[0]}] PASS"
}

test_identity_without_forwarded
test_identity_with_forwarded
