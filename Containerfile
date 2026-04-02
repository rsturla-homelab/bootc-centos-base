ARG BASE_IMAGE_REGISTRY=quay.io/centos-bootc/centos-bootc
ARG BASE_IMAGE_TAG=stream10
ARG BASE_IMAGE_DIGEST=sha256:0dd1e99b70dd13e68021b3772243d662275d4ae44d6e6101a240fce8d6f2292b
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
