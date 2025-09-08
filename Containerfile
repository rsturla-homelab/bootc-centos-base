ARG BASE_IMAGE_REGISTRY=quay.io/centos-bootc/centos-bootc
ARG BASE_IMAGE_TAG=stream10
ARG BASE_IMAGE_DIGEST=sha256:4e2ad757c2030128665f878a7a64a5f0755706023b25628c76b3d5c5e57b90cd
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
