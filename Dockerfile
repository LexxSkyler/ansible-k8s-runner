FROM registry.access.redhat.com/ubi8:8.5

ENV PYTHON_VERSION=3.8 \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=UTF-8 \
    PIP_NO_CACHE_DIR=off \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    HOME=/runner

LABEL com.redhat.component="container with ansible for executing playbooks with k8s module. Put ansible.cfg in "
LABEL name="quay.io/lexxskyler/runner"
LABEL version="1.6"
LABEL maintainer="Oleg Sadykov orsadykov@vtb.ru"
LABEL usage="podman RUN --rm -v /local/playbook:/runner/project -v /local/inventory:/runner/inventory -v /local/artifacts:/runner/artifacts quay.io/lexxskyler/runner"

LABEL run="podman RUN --rm -v /local/playbook:/runner/project -v /local/inventory:/runner/inventory -v /local/artifacts:/runner/artifacts quay.io/lexxskyler/runner"

#labels for container catalog
LABEL summary="enviroment for runnig ansible k8s playbooks"
LABEL description="enviroment for runnig ansible k8s playbooks"
LABEL io.k8s.description="enviroment for runnig ansible k8s playbooks"
LABEL io.k8s.display-name="enviroment for runnig ansible k8s playbooks"
LABEL io.openshift.tags="ansible-base, kubernetes-core"
LABEL io.openshift.expose-services=""

RUN curl -o /usr/bin/kubectl https://dl.k8s.io/release/v1.20.12/bin/linux/amd64/kubectl && chmod 0755 /usr/bin/kubectl

RUN cd /usr/bin/ && curl https://get.helm.sh/helm-v3.7.1-linux-amd64.tar.gz | tar -xz  linux-amd64/helm --strip-components 1 && chmod 0755 /usr/bin/helm

#RUN curl -o https://github.com/openshift/okd/releases/download/4.8.0-0.okd-2021-11-14-052418/openshift-client-linux-4.8.0-0.okd-2021-11-14-052418.tar.gz | tar -xz  -C /usr/bin/ && chmod 0755 /usr/bin/oc /usr/bin/kubectl

RUN dnf install -y \
    https://rpmfind.net/linux/epel/8/Everything/x86_64/Packages/s/sshpass-1.06-9.el8.x86_64.rpm \
    python38 \
    python38-pip \
    wget \
    rsync \
    openssh-clients \
    glibc-langpack-en \
    git  && \
	alternatives --set python /usr/bin/python3 && \
    yum -y module enable python38:3.8 && \
    rm -rf /var/cache/dnf
# In OpenShift, container will run as a random uid number and gid 0. Make sure things
# are writeable by the root group.    
RUN for dir in \
      /home/runner \
      /home/runner/.ansible \
      /home/runner/.ansible/tmp \
      /runner \
      /home/runner \
      /runner/env \
      /runner/inventory \
      /runner/project \
      /runner/artifacts ; \
    do mkdir -m 0775 -p $dir ; chmod -R g+rwx $dir ; chgrp -R root $dir ; done && \
    for file in \
      /home/runner/.ansible/galaxy_token \
      /etc/passwd \
      /etc/group ; \
    do touch $file ; chmod g+rw $file ; chgrp root $file ; done

RUN python3 -m pip install --upgrade pip && \
	python3 -m pip install setuptools  && \
    python3 -m pip install PyYAML  && python3 -m pip install  openshift  && \
	python3 -m pip install ansible-base && \
	ansible-galaxy collection install kubernetes.core

VOLUME /runner/inventory
VOLUME /runner/project
VOLUME /runner/artifacts

WORKDIR /runner

ADD utils/entrypoint.sh /bin/entrypoint
RUN chmod +x /bin/entrypoint

ENTRYPOINT ["entrypoint.sh"]

WORKDIR /runner/project