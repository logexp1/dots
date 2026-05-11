#!/bin/bash
set -e
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/common.sh"

KEY_ID="360913AC5912FEB8"
FINGERPRINT="D56378D8CBE9852BACAE1E37360913AC5912FEB8"
KEYSERVER="hkps://keyserver.ubuntu.com"
PRIVKEY_PATH="$HOME/OneDrive/privkey.asc"
PASS_REPO="https://github.com/logexp1/password-store.git"
PASS_DIR="$HOME/.password-store"

# Returns true only if real secret key material is present (not a stub)
has_real_secret_key() {
    # Check that primary key has secret material
    gpg --list-secret-keys --with-colons "$KEY_ID" 2>/dev/null | grep -q '^sec:'
}

# Check that all subkeys also have secret material
has_complete_secret_keys() {
    local stub_count
    stub_count=$(gpg --list-secret-keys --with-colons "$KEY_ID" 2>/dev/null | grep -c '^ssb#:' || true)
    [[ $stub_count -eq 0 ]]
}

fetch_public_key() {
    log_step "gpg" "Fetching public key from $KEYSERVER..."
    if gpg --keyserver "$KEYSERVER" --recv-keys "$FINGERPRINT" 2>&1 | grep -q "imported\|unchanged"; then
        return 0
    else
        log_error "gpg" "Failed to fetch public key from keyserver"
        return 1
    fi
}

refresh_public_key() {
    log_step "gpg" "Refreshing public key from keyserver..."
    gpg --keyserver "$KEYSERVER" --refresh-keys "$FINGERPRINT" 2>&1 || \
        log_step "gpg" "Refresh failed (keyserver unreachable?), continuing with local key."
}

run() {
    if [[ $EUID -eq 0 ]]; then
        log_error "gpg" "Do not run as root — this corrupts GPG keyring ownership."
        return 1
    fi

    log_step "gpg" "Setting up GnuPG and password store..."
    require_cmd pass
    require_cmd gpg

    # Fix ownership/permissions if a previous root run corrupted the keyring
    if [[ -d "$HOME/.gnupg" ]]; then
        # Check for root-owned files (sign of previous corruption)
        if find "$HOME/.gnupg" -not -user "$USER" 2>/dev/null | grep -q .; then
            log_step "gpg" "Found non-user-owned files in ~/.gnupg, fixing..."
            sudo chown -R "$USER:$USER" "$HOME/.gnupg"
        fi
        find "$HOME/.gnupg" -type d -exec chmod 700 {} \;
        find "$HOME/.gnupg" -type f -exec chmod 600 {} \;
    fi

    # Remove use-keyboxd if present
    if grep -q 'use-keyboxd' "$HOME/.gnupg/common.conf" 2>/dev/null; then
        sed -i '/use-keyboxd/d' "$HOME/.gnupg/common.conf"
        [[ ! -s "$HOME/.gnupg/common.conf" ]] && rm -f "$HOME/.gnupg/common.conf"
        gpgconf --kill keyboxd 2>/dev/null || true
        gpgconf --kill gpg-agent 2>/dev/null || true
    fi

    gpgconf --launch gpg-agent

    # Step 1: Fetch public key from keyserver (always - source of truth for public info)
    if gpg --list-keys "$KEY_ID" &>/dev/null; then
        refresh_public_key
    else
        fetch_public_key || {
            log_error "gpg" "Public key not in keyring and keyserver unreachable."
            log_error "gpg" "Manually import public key, then re-run."
            return 1
        }
    fi

    # Step 2: Import secret key if not present (or only stubs present)
    if has_real_secret_key && has_complete_secret_keys; then
        log_step "gpg" "Complete secret keys already in keyring, skipping import."
    else
        if [[ ! -f "$PRIVKEY_PATH" ]]; then
            # OneDrive sync logic (kept for backwards compatibility, but consider USB)
            log_step "gpg" "Private key not found at $PRIVKEY_PATH, attempting OneDrive sync..."
            log_step "gpg" "⚠️  Consider migrating away from cloud storage for secret keys."

            require_cmd onedrive
            if [[ ! -f "$HOME/.config/onedrive/refresh_token" ]]; then
                log_step "gpg" "OneDrive not authenticated. Starting interactive authentication..."
                onedrive
            fi
            log_step "gpg" "Syncing OneDrive in background..."
            onedrive --sync &
            local onedrive_pid=$!
            local timeout=1800
            local elapsed=0
            while [[ ! -f "$PRIVKEY_PATH" ]]; do
                if [[ $elapsed -ge $timeout ]]; then
                    kill "$onedrive_pid" 2>/dev/null || true
                    log_error "gpg" "Timed out waiting for privkey.asc after ${timeout}s."
                    return 1
                fi
                if ! kill -0 "$onedrive_pid" 2>/dev/null; then
                    log_error "gpg" "onedrive exited before privkey.asc was found."
                    return 1
                fi
                sleep 2
                elapsed=$((elapsed + 2))
            done
            log_step "gpg" "Found privkey.asc after ${elapsed}s."
        fi

        log_step "gpg" "Importing secret key from $PRIVKEY_PATH..."
        gpg --import "$PRIVKEY_PATH"

        if ! has_real_secret_key; then
            log_error "gpg" "Import succeeded but secret key material is missing."
            log_error "gpg" "$PRIVKEY_PATH may not contain the real private key."
            return 1
        fi

        # Warn if subkeys are missing
        if ! has_complete_secret_keys; then
            log_step "gpg" "⚠️  Some subkeys still missing secret material (ssb# stubs detected)."
            log_step "gpg" "    privkey.asc may be outdated. Re-export from source machine."
        fi
    fi

    # Resolve full fingerprint (sanity check)
    local actual_fp
    actual_fp="$(gpg --list-keys --with-colons "$KEY_ID" | awk -F: '/^fpr:/ { print $10; exit }')"
    if [[ "$actual_fp" != "$FINGERPRINT" ]]; then
        log_error "gpg" "Fingerprint mismatch: expected $FINGERPRINT, got $actual_fp"
        return 1
    fi

    # Set trust to ultimate (idempotent)
    log_step "gpg" "Setting key trust to ultimate..."
    echo "${FINGERPRINT}:5:" | gpg --import-ownertrust
    gpg --check-trustdb

    # Remove expiration (idempotent) - consider whether you really want this
    log_step "gpg" "Removing key expiration..."
    gpg --quick-set-expire "$FINGERPRINT" 0 '*'

    # Clone password store and initialise (only on first setup)
    if [[ -d "$PASS_DIR" ]]; then
        log_step "gpg" "Password store already exists at $PASS_DIR, skipping clone."

        # Sanity check: .gpg-id should match KEY_ID
        if [[ -f "$PASS_DIR/.gpg-id" ]]; then
            local current_gpg_id
            current_gpg_id="$(cat "$PASS_DIR/.gpg-id")"
            if [[ "$current_gpg_id" != "$KEY_ID" && "$current_gpg_id" != "$FINGERPRINT" ]]; then
                log_step "gpg" "⚠️  .gpg-id mismatch: '$current_gpg_id' vs expected '$KEY_ID'"
                log_step "gpg" "    You may want to run: pass init $KEY_ID"
            fi
        fi
    else
        log_step "gpg" "Cloning password store..."
        git clone "$PASS_REPO" "$PASS_DIR"
        log_step "gpg" "Initializing password store with key $KEY_ID..."
        pass init "$KEY_ID"
    fi

    log_step "gpg" "Done."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
