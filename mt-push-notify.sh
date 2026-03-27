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

# Gather remote server context for session matching
REMOTE_HOST=$(hostname -f 2>/dev/null || hostname)
REMOTE_USER=$(whoami)
# Collect local IP addresses for profile matching (hostname may differ from profile)
if command -v hostname >/dev/null 2>&1 && hostname -I >/dev/null 2>&1; then
  REMOTE_IPS=$(hostname -I 2>/dev/null | xargs | tr ' ' ',')
else
  # macOS: enumerate all non-loopback IPv4 addresses
  REMOTE_IPS=$(ifconfig 2>/dev/null | grep 'inet ' | grep -v 127.0.0.1 | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')
fi
HAS_TMUX=false
TMUX_SESSION=""
if [ -n "$TMUX" ]; then
  HAS_TMUX=true
  TMUX_SESSION=$(tmux display-message -p '#S' 2>/dev/null || echo "")
fi

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
        const o={token:process.argv[3],event:process.argv[4],message:msg,host:process.argv[5],user:process.argv[6],has_tmux:process.argv[7]==='true'};
        if(process.argv[8])o.tmux_session=process.argv[8];
        const ips=process.argv[9];if(ips)o.ips=ips.split(',').filter(Boolean);
        process.stdout.write(JSON.stringify(o));
      }catch(e){
        const o={token:process.argv[3],event:process.argv[4],message:process.argv[2],host:process.argv[5],user:process.argv[6],has_tmux:process.argv[7]==='true'};
        if(process.argv[8])o.tmux_session=process.argv[8];
        const ips=process.argv[9];if(ips)o.ips=ips.split(',').filter(Boolean);
        process.stdout.write(JSON.stringify(o));
      }
    })" "$FIELD" "$FALLBACK" "$DEVICE_SECRET" "$EVENT" "$REMOTE_HOST" "$REMOTE_USER" "$HAS_TMUX" "$TMUX_SESSION" "$REMOTE_IPS" 2>/dev/null)
elif command -v python3 >/dev/null 2>&1; then
  BODY=$(printf '%s' "$INPUT" | python3 -c "
import sys,json
field,fallback,secret,event,host,user,has_tmux=sys.argv[1:8]
tmux_session=sys.argv[8] if len(sys.argv)>8 else ''
ips_str=sys.argv[9] if len(sys.argv)>9 else ''
try:
  d=json.load(sys.stdin);msg=str(d.get(field,fallback))[:200]
except:msg=fallback
o={'token':secret,'event':event,'message':msg,'host':host,'user':user,'has_tmux':has_tmux=='true'}
if tmux_session:o['tmux_session']=tmux_session
if ips_str:o['ips']=[x for x in ips_str.split(',') if x]
print(json.dumps(o),end='')" "$FIELD" "$FALLBACK" "$DEVICE_SECRET" "$EVENT" "$REMOTE_HOST" "$REMOTE_USER" "$HAS_TMUX" "$TMUX_SESSION" "$REMOTE_IPS" 2>/dev/null)
fi

if [ -z "$BODY" ]; then
  TMUX_FIELD=""
  if [ -n "$TMUX_SESSION" ]; then
    TMUX_FIELD=",\"tmux_session\":\"$TMUX_SESSION\""
  fi
  IPS_FIELD=""
  if [ -n "$REMOTE_IPS" ]; then
    IPS_JSON=$(printf '%s' "$REMOTE_IPS" | tr ',' '\n' | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')
    IPS_FIELD=",\"ips\":[$IPS_JSON]"
  fi
  BODY="{\"token\":\"$DEVICE_SECRET\",\"event\":\"$EVENT\",\"message\":\"$FALLBACK\",\"host\":\"$REMOTE_HOST\",\"user\":\"$REMOTE_USER\",\"has_tmux\":$HAS_TMUX$TMUX_FIELD$IPS_FIELD}"
fi

curl -s -X POST "$RELAY_URL" \
  -H "Content-Type: application/json" \
  -d "$BODY" > /dev/null 2>&1 &
