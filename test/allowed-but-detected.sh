# Actions the OpenShell policy allows but Falco flags. Runs inside a sandbox.
# 1. Filesystem: the policy gives read/write to the whole home (/sandbox), secrets included.
mkdir -p ~/.aws && echo "aws_secret_access_key=FAKE" > ~/.aws/credentials
python3 -c 'import os; print("read", len(open(os.path.expanduser("~/.aws/credentials")).read()), "bytes")'
# 2. Network: the policy allows `node` (needed by Claude Code) to reach api.anthropic.com,
#    so any node script gets the same egress.
node -e 'fetch("https://api.anthropic.com/v1/models").then(r => console.log("node egress status", r.status))'
