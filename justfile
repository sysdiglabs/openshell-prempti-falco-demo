image := "openshell-claude-prempti"
falco_name := "openshell-falco"

# On macOS sandboxes run in colima's VM; elsewhere use the local daemon.
export DOCKER_HOST := env("DOCKER_HOST", if os() == "macos" { "unix://" + home_directory() + "/.colima/default/docker.sock" } else { "unix:///var/run/docker.sock" })

default:
    @just --list

# Run Falco with the OpenShell rules and show sandbox alerts
falco:
    FALCO_NAME={{ falco_name }} ./falco/run.sh 2>/dev/null | grep --line-buffered "sandbox="

# Start a local OpenShell gateway unless one is already running
gateway:
    ./gateway/run.sh

# Build the sandbox image (Prempti + policy on top of the community base)
image:
    docker build -q -t {{ image }} sandbox

# Start Claude Code (guarded by Prempti) in an OpenShell sandbox
openshell name="claude": image
    openshell sandbox create --name {{ name }} --from {{ image }} -- claude-prempti

# Follow Prempti's verdicts from the sandbox (no extra shell inside it)
prempti-logs name="claude":
    openshell sandbox exec --name {{ name }} -- /sandbox/.prempti/bin/premptictl logs -f

# Delete the sandbox, stop Falco and remove the sandbox image
clean name="claude":
    -openshell sandbox delete --all
    -docker rm -f {{ falco_name }}
    -docker image rm -f {{ image }}
