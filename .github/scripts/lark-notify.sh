#!/usr/bin/env bash
# Post an interactive card to a Lark custom-bot webhook (with signature).
#
# No-op (exit 0) when LARK_WEBHOOK_URL is empty, so the calling workflow stays
# green even before the webhook secret is configured.
#
# Env:
#   LARK_WEBHOOK_URL     required to actually send; empty => skip
#   LARK_WEBHOOK_SECRET  optional; when set, signs the request (bot must have
#                        "signature verification" enabled)
#
# Flags:
#   --status   success|failure|warning|info   (header color)
#   --title    <text>
#   --text     <lark markdown>   (use \n for line breaks; supports <at id=ou_x></at>)
#   --at       <ou_x[,ou_y...]>  (prepended @mentions)
#   --button   <label>
#   --url      <link for the button>
set -euo pipefail

status=info title="" text="" at="" button="" url=""
while [ $# -gt 0 ]; do
  case "$1" in
    --status) status="$2"; shift 2;;
    --title)  title="$2";  shift 2;;
    --text)   text="$2";   shift 2;;
    --at)     at="$2";     shift 2;;
    --button) button="$2"; shift 2;;
    --url)    url="$2";    shift 2;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done

if [ -z "${LARK_WEBHOOK_URL:-}" ]; then
  echo "LARK_WEBHOOK_URL not set — skipping Lark notification"
  exit 0
fi

STATUS="$status" TITLE="$title" TEXT="$text" AT="$at" BUTTON="$button" URL="$url" \
python3 - "$LARK_WEBHOOK_URL" "${LARK_WEBHOOK_SECRET:-}" <<'PY'
import base64, hashlib, hmac, json, os, sys, time, urllib.request

webhook, secret = sys.argv[1], sys.argv[2]
status = os.environ.get("STATUS", "info")
color = {"success": "green", "failure": "red", "warning": "orange", "info": "blue"}.get(status, "blue")

content = ""
at = os.environ.get("AT", "").strip()
if at:
    content += " ".join(f'<at id={x.strip()}></at>' for x in at.split(",") if x.strip()) + "\n"
content += os.environ.get("TEXT", "").replace("\\n", "\n")

elements = [{"tag": "div", "text": {"tag": "lark_md", "content": content}}]
button, url = os.environ.get("BUTTON", ""), os.environ.get("URL", "")
if button and url:
    elements.append({
        "tag": "action",
        "actions": [{"tag": "button",
                     "text": {"tag": "plain_text", "content": button},
                     "url": url, "type": "primary"}],
    })

body = {
    "msg_type": "interactive",
    "card": {
        "config": {"wide_screen_mode": True},
        "header": {"template": color,
                   "title": {"tag": "plain_text",
                             "content": os.environ.get("TITLE", "") or "Notification"}},
        "elements": elements,
    },
}

if secret:
    ts = str(int(time.time()))
    sign = base64.b64encode(
        hmac.new(f"{ts}\n{secret}".encode("utf-8"), b"", hashlib.sha256).digest()
    ).decode("utf-8")
    body["timestamp"] = ts
    body["sign"] = sign

req = urllib.request.Request(
    webhook, data=json.dumps(body).encode("utf-8"),
    headers={"Content-Type": "application/json"}, method="POST")
with urllib.request.urlopen(req, timeout=15) as resp:
    out = resp.read().decode("utf-8")
print(out)
r = json.loads(out)
# Lark returns {"code":0,...} or {"StatusCode":0,...} on success.
if r.get("code", r.get("StatusCode", 0)) not in (0, None):
    sys.exit(f"Lark webhook error: {out}")
PY
