# Simulated agent that stops Prempti. Runs inside an OpenShell sandbox.
# Expected Falco alerts: Agent Signals Process, Prempti Stopped.
claude-prempti --version </dev/null >/dev/null                 # start Prempti like the entrypoint does
kill -TERM $(pgrep -x premptictl)                               # SIGTERM: the daemon removes its own hook
sleep 2
echo "user hook after SIGTERM: $(cat ~/.claude/settings.json)"
# What Claude Code's managed hook runs before the next tool call: deny (fail closed).
echo '{"session_id":"t","transcript_path":"/tmp/t","cwd":"/sandbox","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"ls"}}' \
  | /opt/prempti/bin/claude-interceptor; echo
