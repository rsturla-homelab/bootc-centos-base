ARG BASE_IMAGE_REGISTRY=quay.io/centos-bootc/centos-bootc
ARG BASE_IMAGE_TAG=stream10
ARG BASE_IMAGE_DIGEST=sha256:c2dba5fede2a0e5f89363ec84f576fe709a82f06deb6774d00344e3ccf503d5d
FROM ${BASE_IMAGE_REGISTRY}:${BASE_IMAGE_TAG}@${BASE_IMAGE_DIGEST} AS base

COPY files/base/ /

# Manage default packages
RUN --mount=type=cache,target=/var/cache/dnf \
  dnf -y install 'dnf-command(versionlock)' && \
  dnf versionlock add $(rpm -qa --queryformat '%{NAME}-%{VERSION}-%{RELEASE}\n' kernel*) \
  && \
  dnf -y remove subscription-manager* \
  && \
  dnf -y install cloud-init nftables epel-release \
  && \
  systemctl enable cloud-init.service && \
  systemctl enable nftables.service

# Harden image
RUN --mount=type=cache,target=/var/cache/dnf \
  authselect select local with-faillock --force \
  && \
  echo "umask 027" >> /etc/profile \
  && \
  dnf install -y audit && \
  systemctl enable auditd.service


FROM base AS qemu

# Virtualization tools
RUN --mount=type=cache,target=/var/cache/dnf \
  dnf install -y qemu-guest-agent && \
  systemctl enable qemu-guest-agent.service
