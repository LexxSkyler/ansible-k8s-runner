#!/usr/bin/env bash

# In OpenShift, containers are run as a random high number uid
# that doesn't exist in /etc/passwd, but Ansible module utils
# require a named user. So if we're in OpenShift, we need to make
# one before Ansible runs.
if [[ (`id -u` -ge 500 || -z "${CURRENT_UID}") ]]; then

    # Only needed for RHEL 8. Try deleting this conditional (not the code)
    # sometime in the future. Seems to be fixed on Fedora 32
    # If we are running in rootless podman, this file cannot be overwritten
    ROOTLESS_MODE=$(cat /proc/self/uid_map | head -n1 | awk '{ print $2; }')
    if [[ "$ROOTLESS_MODE" -eq "0" ]]; then
cat << EOF > /etc/passwd
root:x:0:0:root:/root:/bin/bash
runner:x:`id -u`:`id -g`:,,,:/home/runner:/bin/bash
EOF
    fi

cat <<EOF > /etc/group
root:x:0:runner
runner:x:`id -g`:
EOF

fi

test -n ${ENV} && ANSIBLE_ENV="-e \"${ENV}\"" || true

test -n ${TAGS} && ANSIBLE_TAGS="--tags \"${TAGS}\"" || true

test -n ${SKIP_TAGS} && ANSIBLE_SKIP_TAGS="--skip-tags \"${SKIP_TAGS}\"" || true



ansible-playbook /runner/project/main.yml -i /runner/inventory ${ANSIBLE_ENV} ${ANSIBLE_TAGS} ${ANSIBLE_SKIP_TAGS}
