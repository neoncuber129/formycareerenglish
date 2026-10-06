import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib" / "l10n"
PY = Path(__file__).resolve().parent / "generate_locale_arbs.py"
en = json.loads((ROOT / "app_en.arb").read_text(encoding="utf-8"))
keys = {k for k in en if not k.startswith("@") and k != "@@locale"}
text = PY.read_text(encoding="utf-8")
blob = text.split("PATCH_TABLE = r")[1].split('"""', 2)[1]
patch_keys = set()
for line in blob.splitlines():
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    patch_keys.add(line.split("|", 1)[0].strip())
print("missing", sorted(keys - patch_keys))
print("extra", sorted(patch_keys - keys))
