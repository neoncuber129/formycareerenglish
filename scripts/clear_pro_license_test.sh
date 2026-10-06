#!/usr/bin/env bash
# Xoa nhanh trang thai Pro / license trong SharedPreferences (ban test desktop).
# Dong bo voi apps/desktop/lib/core/monetization/app_state.dart (AppStateController).
# Key trong file co tien to mac dinh "flutter.".

set -euo pipefail

COMPANY="${COMPANY:-com.example}"
PRODUCT="${PRODUCT:-desktop}"
KEYS=(
  "flutter.isPro"
  "flutter.lemonLastLicenseKey"
  "flutter.lemonLicenseInstanceId"
  "flutter.lemonSqueezyInstanceFingerprint"
)

if [[ -n "${PREFS_PATH:-}" ]]; then
  prefs="$PREFS_PATH"
elif [[ "$(uname -s)" == "Darwin" ]]; then
  prefs="$HOME/Library/Application Support/$COMPANY/$PRODUCT/shared_preferences.json"
else
  prefs="${XDG_CONFIG_HOME:-$HOME/.config}/$COMPANY/$PRODUCT/shared_preferences.json"
fi

if [[ ! -f "$prefs" ]]; then
  echo "Khong tim thay: $prefs" >&2
  echo "Tuy chon: PREFS_PATH=/path/to/shared_preferences.json $0" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "Can python3 de chinh JSON." >&2
  exit 1
fi

python3 - "$prefs" "${KEYS[@]}" <<'PY'
import json, sys
path = sys.argv[1]
keys = set(sys.argv[2:])
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)
removed = [k for k in keys if k in data]
for k in removed:
    del data[k]
if not removed:
    print("Khong co key Pro/license nao can xoa.")
    sys.exit(0)
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
print(f"Da xoa {len(removed)} key khoi {path}:")
for k in removed:
    print(f"  - {k}")
PY
