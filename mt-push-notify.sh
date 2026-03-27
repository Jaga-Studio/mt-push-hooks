#!/bin/sh
# MT Push Notify — Claude Code Hook Script
# Installed by: setup-hooks.sh
# Reads stdin JSON from Claude Code, extracts activity content,
# and sends as push notification via MT relay.
#
# Usage (called automatically by Claude Code hooks):
#   mt-push-notify.sh stop          — on task completion
#   mt-push-notify.sh notification  — on permission request

RELAY_URL="https://mt-push.jaga-farm.com/v1/notify"
DEVICE_SECRET="__MT_DEVICE_SECRET__"
HOOK_TYPE="${1:-stop}"

INPUT=$(cat)

if [ "$HOOK_TYPE" = "stop" ]; then
  EVENT="agent-done"
  FIELD="last_assistant_message"
  FALLBACK="Task complete"
else
  EVENT="agent-input"
  FIELD="message"
  FALLBACK="Permission needed"
fi

# Extract message and build JSON body using node (preferred) or python3 (fallback)
BODY=""
if command -v node >/dev/null 2>&1; then
  BODY=$(printf '%s' "$INPUT" | node -e "
    let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{
      try{
        const j=JSON.parse(d);
        const msg=String(j[process.argv[1]]||process.argv[2]).substring(0,200);
        process.stdout.write(JSON.stringify({token:process.argv[3],event:process.argv[4],message:msg}));
      }catch(e){
        process.stdout.write(JSON.stringify({token:process.argv[3],event:process.argv[4],message:process.argv[2]}));
      }
    })" "$FIELD" "$FALLBACK" "$DEVICE_SECRET" "$EVENT" 2>/dev/null)
elif command -v python3 >/dev/null 2>&1; then
  BODY=$(printf '%s' "$INPUT" | python3 -c "
import sys,json
field,fallback,secret,event=sys.argv[1:]
try:
  d=json.load(sys.stdin);msg=str(d.get(field,fallback))[:200]
except:msg=fallback
print(json.dumps({'token':secret,'event':event,'message':msg}),end='')" "$FIELD" "$FALLBACK" "$DEVICE_SECRET" "$EVENT" 2>/dev/null)
fi

if [ -z "$BODY" ]; then
  BODY="{\"token\":\"$DEVICE_SECRET\",\"event\":\"$EVENT\",\"message\":\"$FALLBACK\"}"
fi

curl -s -X POST "$RELAY_URL" \
  -H "Content-Type: application/json" \
  -d "$BODY" > /dev/null 2>&1 &
