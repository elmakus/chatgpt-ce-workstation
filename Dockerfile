# syntax=docker/dockerfile:1

ARG UBUNTU_BASE=ubuntu:24.04
FROM ${UBUNTU_BASE}

ARG UBUNTU_BASE
ARG UBUNTU_APT_IDENTITY
ARG CE_REPOSITORY=https://github.com/ilysenko/codex-desktop-linux.git
ARG CE_REF=main
ARG CE_COMMIT
ARG OPENAI_PACKAGE_VERSION
ARG OPENAI_PACKAGE_SHA256
ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_NOARCH_SHA256
ARG S6_OVERLAY_X86_64_SHA256
ARG CODEX_CHATGPT_WEB_VERSION
ARG CODEX_CHATGPT_WEB_SHA256
ARG AGENT_WORKSPACE_VERSION
ARG AGENT_WORKSPACE_INTEGRITY
ARG MUSE_INSTALLER_URL=https://dev.meta.ai/install.sh
ARG MUSE_INSTALLER_SHA256
ARG MUSE_EXPECTED_VERSION
ARG CHROME_VERSION
ARG CHROME_PACKAGE_SHA256
ARG GOOGLE_LINUX_PUB_MATERIAL_SHA256
ARG RUST_VERSION
ARG RUST_STABLE_MANIFEST_SHA256
ARG RUSTUP_INSTALLER_SHA256
ARG UPSTREAM_RESOLUTION_SHA256
ARG CODEX_UID=99
ARG CODEX_GID=100

ENV TZ=Europe/Zurich \
    DISPLAY=:1 \
    HOME=/home/codex \
    USER=codex \
    LOGNAME=codex \
    RUSTUP_HOME=/opt/rustup \
    BROWSER_BIN=/usr/bin/google-chrome \
    CHROME_BIN=/usr/bin/google-chrome \
    PATH=/opt/cargo/bin:/home/codex/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin \
    CODEX_LINUX_DISABLE_USAGE_REPORTING=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY scripts/build/assert-ubuntu-apt-identity.sh /usr/local/lib/workstation/assert-ubuntu-apt-identity.sh

# Runtime + developer workstation tools. The signed Ubuntu repository state is
# frozen before build and every successful apt phase must still match it.
RUN set -eux; \
    [[ "${UBUNTU_BASE}" =~ ^ubuntu:24\\.04@sha256:[0-9a-f]{64}$ ]]; \
    test -n "${UBUNTU_APT_IDENTITY}"; \
    chmod 0755 /usr/local/lib/workstation/assert-ubuntu-apt-identity.sh; \
    apt-get update; \
    /usr/local/lib/workstation/assert-ubuntu-apt-identity.sh "${UBUNTU_APT_IDENTITY}"; \
    apt-get install -y --no-install-recommends \
      bash \
      ca-certificates \
      curl \
      wget \
      gnupg \
      xz-utils \
      sudo \
      git \
      git-lfs \
      gh \
      openssh-client \
      rsync \
      jq \
      yq \
      ripgrep \
      fd-find \
      tree \
      zip \
      unzip \
      p7zip-full \
      zstd \
      make \
      gcc \
      g++ \
      clang \
      cmake \
      ninja-build \
      pkg-config \
      python3 \
      python3-pip \
      python3-venv \
      pipx \
      golang-go \
      openjdk-21-jdk-headless \
      sqlite3 \
      postgresql-client \
      mariadb-client \
      redis-tools \
      ffmpeg \
      imagemagick \
      poppler-utils \
      qpdf \
      procps \
      htop \
      lsof \
      strace \
      socat \
      netcat-openbsd \
      dnsutils \
      iproute2 \
      iputils-ping \
      less \
      nano \
      vim \
      tmux \
      dbus \
      dbus-x11 \
      dbus-user-session \
      libsecret-1-0 \
      libsecret-tools \
      gnome-keyring \
      at-spi2-core \
      xdg-utils \
      xdg-user-dirs \
      xvfb \
      openbox \
      tint2 \
      xterm \
      xauth \
      xclip \
      bubblewrap \
      libxkbcommon-x11-dev \
      x11vnc \
      novnc \
      websockify \
      xdotool \
      wmctrl \
      x11-utils; \
    rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/bin/fdfind /usr/local/bin/fd

# s6-overlay is latest-stable at resolution time, but the build consumes exact
# release assets and verifies both frozen SHA-256 identities.
RUN set -eux; \
    test -n "${S6_OVERLAY_VERSION}"; \
    test "${S6_OVERLAY_NOARCH_SHA256}" != ""; \
    test "${S6_OVERLAY_X86_64_SHA256}" != ""; \
    base="https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}"; \
    curl -fsSL --retry 3 --retry-all-errors "${base}/s6-overlay-noarch.tar.xz" -o /tmp/s6-overlay-noarch.tar.xz; \
    curl -fsSL --retry 3 --retry-all-errors "${base}/s6-overlay-x86_64.tar.xz" -o /tmp/s6-overlay-x86_64.tar.xz; \
    echo "${S6_OVERLAY_NOARCH_SHA256}  /tmp/s6-overlay-noarch.tar.xz" | sha256sum -c -; \
    echo "${S6_OVERLAY_X86_64_SHA256}  /tmp/s6-overlay-x86_64.tar.xz" | sha256sum -c -; \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz; \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz; \
    rm -f /tmp/s6-overlay-*.tar.xz

# Match the usual Unraid nobody:users numeric ownership by default.
RUN set -eux; \
    if getent passwd "${CODEX_UID}" >/dev/null; then \
      echo "Requested CODEX_UID=${CODEX_UID} already exists in base image" >&2; exit 1; \
    fi; \
    if ! getent group "${CODEX_GID}" >/dev/null; then \
      groupadd --gid "${CODEX_GID}" codex-host; \
    fi; \
    useradd --uid "${CODEX_UID}" --gid "${CODEX_GID}" --create-home --shell /bin/bash codex; \
    mkdir -p /home/codex/Documents/ChatGPT /opt/workstation; \
    chown -R codex:"${CODEX_GID}" /home/codex; \
    printf 'codex ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/90-codex-workstation; \
    chmod 0440 /etc/sudoers.d/90-codex-workstation; \
    visudo -cf /etc/sudoers.d/90-codex-workstation

# Passwordless sudo is intentionally scoped to the dedicated workstation container.
# Do not pair it with /var/run/docker.sock, a host-root mount, or another broad
# Unraid control surface without an explicit architecture change.

# Install the exact Rust stable toolchain frozen by the resolver. The stable
# channel-manifest digest remains a cache/provenance input; rustup itself is also
# bound to the exact installer bytes observed during resolution.
RUN set -eux; \
    test "${RUST_STABLE_MANIFEST_SHA256}" != ""; \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/rustup-init.sh; \
    echo "${RUSTUP_INSTALLER_SHA256}  /tmp/rustup-init.sh" | sha256sum -c -; \
    export CARGO_HOME=/opt/cargo; \
    sh /tmp/rustup-init.sh -y --profile minimal --default-toolchain "${RUST_VERSION}"; \
    rm -f /tmp/rustup-init.sh; \
    rustc --version | grep -F "rustc ${RUST_VERSION} "; \
    cargo --version

# Build ChatGPT Community from the exact CE commit and exact official OpenAI
# package. CE's own pinned signing key + signed InRelease + Packages SHA-256 +
# package SHA-256 chain remains the source of trust.
WORKDIR /tmp/ce-build
RUN set -eux; \
    test -n "${CE_COMMIT}"; \
    git init /tmp/ce-build/src; \
    git -C /tmp/ce-build/src remote add origin "${CE_REPOSITORY}"; \
    git -C /tmp/ce-build/src fetch --depth=1 origin "${CE_COMMIT}"; \
    test "$(git -C /tmp/ce-build/src rev-parse FETCH_HEAD)" = "${CE_COMMIT}"; \
    git -C /tmp/ce-build/src checkout --detach FETCH_HEAD; \
    test "$(git -C /tmp/ce-build/src rev-parse HEAD)" = "${CE_COMMIT}"
COPY config/ce-features.json /tmp/ce-build/src/linux-features/features.json
RUN set -eux; \
    cd /tmp/ce-build/src; \
    export CARGO_HOME=/opt/cargo; \
    bash scripts/install-deps.sh; \
    /usr/local/lib/workstation/assert-ubuntu-apt-identity.sh "${UBUNTU_APT_IDENTITY}"; \
    mkdir -p /tmp/openai-package; \
    upstream_deb="$(node scripts/lib/upstream-linux-package.js \
      --output-dir /tmp/openai-package \
      --metadata /tmp/openai-package/metadata.json \
      --key-base64 assets/openai-codex-linux-repository-key.gpg.base64 \
      --arch amd64)"; \
    node -e 'const m=require(process.argv[1]); if(m.version!==process.argv[2] || m.sha256!==process.argv[3]) process.exit(1)' \
      /tmp/openai-package/metadata.json "${OPENAI_PACKAGE_VERSION}" "${OPENAI_PACKAGE_SHA256}"; \
    test -f "${upstream_deb}"; \
    echo "${OPENAI_PACKAGE_SHA256}  ${upstream_deb}" | sha256sum -c -; \
    PACKAGE_WITH_UPDATER=0 make build-native-feature-helpers; \
    PACKAGE_WITH_UPDATER=0 UPSTREAM_DEB="${upstream_deb}" make build-app; \
    PACKAGE_WITH_UPDATER=0 make deb; \
    deb="$(scripts/select-latest-package.sh "$PWD/dist/codex-desktop_*.deb")"; \
    test -n "$deb"; \
    dpkg -i "$deb" || { \
      apt-get update; \
      /usr/local/lib/workstation/assert-ubuntu-apt-identity.sh "${UBUNTU_APT_IDENTITY}"; \
      apt-get -f install -y; \
      dpkg -i "$deb"; \
    }; \
    command -v codex-desktop; \
    rm -rf /tmp/ce-build /tmp/openai-package /var/lib/apt/lists/*

# Reconcile the full desktop/keyring substrate after CE and verify that any new
# Ubuntu APT metadata still matches the frozen candidate.
RUN set -eux; \
    apt-get update; \
    /usr/local/lib/workstation/assert-ubuntu-apt-identity.sh "${UBUNTU_APT_IDENTITY}"; \
    apt-get install -y --no-install-recommends \
      dbus dbus-x11 libsecret-1-0 gnome-keyring at-spi2-core \
      xvfb openbox tint2 xterm xauth xclip x11vnc novnc websockify \
      xdotool wmctrl x11-utils python3-xdg; \
    test -f /usr/share/novnc/vnc.html; \
    for cmd in Xvfb openbox tint2 xterm x11vnc websockify xdotool wmctrl xdpyinfo gnome-keyring-daemon; do \
      command -v "$cmd"; \
    done; \
    python3 -c 'import xdg'; \
    rm -rf /var/lib/apt/lists/*

# Install exact Chrome stable from Google's signed APT repository. The key bytes,
# package version and package SHA-256 must still match the frozen resolver result.
RUN set -eux; \
    install -d -m 0755 /etc/apt/keyrings; \
    curl -fsSL --retry 3 --retry-all-errors https://dl.google.com/linux/linux_signing_key.pub -o /tmp/google-linux-signing-key.pub; \
    echo "${GOOGLE_LINUX_PUB_MATERIAL_SHA256}  /tmp/google-linux-signing-key.pub" | sha256sum -c -; \
    gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg /tmp/google-linux-signing-key.pub; \
    rm -f /tmp/google-linux-signing-key.pub; \
    chmod 0644 /etc/apt/keyrings/google-chrome.gpg; \
    printf '%s\n' 'deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main' \
      > /etc/apt/sources.list.d/google-chrome.list; \
    apt-get update; \
    /usr/local/lib/workstation/assert-ubuntu-apt-identity.sh "${UBUNTU_APT_IDENTITY}"; \
    record="$(apt-cache show "google-chrome-stable=${CHROME_VERSION}")"; \
    test "$(printf '%s\n' "$record" | awk -F': ' '$1=="SHA256"{print $2; exit}')" = "${CHROME_PACKAGE_SHA256}"; \
    apt-get install -y --no-install-recommends "google-chrome-stable=${CHROME_VERSION}"; \
    test "$(dpkg-query -W -f='${Version}' google-chrome-stable)" = "${CHROME_VERSION}"; \
    google-chrome --version; \
    rm -rf /var/lib/apt/lists/*

# Agent Workspace follows npm latest at resolution time, then installs the exact
# frozen version only after its registry integrity is rechecked.
RUN set -eux; \
    actual_integrity="$(npm view "@agent-sh/agent-workspace-linux@${AGENT_WORKSPACE_VERSION}" dist.integrity)"; \
    test "$actual_integrity" = "${AGENT_WORKSPACE_INTEGRITY}"; \
    npm install -g "@agent-sh/agent-workspace-linux@${AGENT_WORKSPACE_VERSION}"; \
    command -v agent-workspace-linux; \
    test "$(node -p "require('/usr/local/lib/node_modules/@agent-sh/agent-workspace-linux/package.json').version")" = "${AGENT_WORKSPACE_VERSION}"

COPY scripts/build/install-muse-code.sh /tmp/install-muse-code.sh
RUN set -eux; \
    chmod 0755 /tmp/install-muse-code.sh; \
    MUSE_INSTALLER_URL="${MUSE_INSTALLER_URL}" \
    MUSE_INSTALLER_SHA256="${MUSE_INSTALLER_SHA256}" \
    MUSE_EXPECTED_VERSION="${MUSE_EXPECTED_VERSION}" \
      /tmp/install-muse-code.sh; \
    test -x /opt/muse-code/bin/muse; \
    rm -f /tmp/install-muse-code.sh

COPY scripts/build/install-codex-web-gpt.sh /tmp/install-codex-web-gpt.sh
RUN set -eux; \
    chmod 0755 /tmp/install-codex-web-gpt.sh; \
    CODEX_CHATGPT_WEB_VERSION="${CODEX_CHATGPT_WEB_VERSION}" \
    CODEX_CHATGPT_WEB_SHA256="${CODEX_CHATGPT_WEB_SHA256}" \
      /tmp/install-codex-web-gpt.sh; \
    command -v codex-web-gpt; \
    rm -f /tmp/install-codex-web-gpt.sh

COPY rootfs/ /
COPY scripts/container/ /opt/workstation/bin/
COPY defaults/ /opt/workstation/defaults/
COPY .workstation-build/upstream-resolution.json /opt/workstation/upstream-resolution.json

LABEL io.chatgpt-ce-workstation.upstream-resolution-sha256="${UPSTREAM_RESOLUTION_SHA256}"

RUN chmod 0755 /opt/workstation/bin/*.sh \
    /usr/local/bin/chatgpt-ce \
    /usr/local/bin/muse \
    /usr/local/bin/workstation-healthcheck \
    /etc/cont-init.d/10-workstation-init \
    /etc/s6-overlay/s6-rc.d/desktop/run \
    && test -s /etc/xdg/openbox/menu.xml \
    && test -s /etc/xdg/tint2/tint2rc \
    && test -s /usr/local/share/applications/chatgpt-ce.desktop \
    && test -s /usr/local/share/applications/codex-web-gpt.desktop \
    && test -s /opt/workstation/upstream-resolution.json \
    && mkdir -p /home/codex/.local/share/applications /home/codex/Documents/ChatGPT \
    && chown -R codex:"${CODEX_GID}" /home/codex

WORKDIR /home/codex/Documents/ChatGPT
EXPOSE 6080

# Avoid Chromium/Electron's tiny default Docker /dev/shm at runtime through
# compose.yaml's shm_size. CE itself is launched with --no-sandbox by the desktop
# session because its Electron sandbox is unusable under the current Unraid Docker
# boundary; keep the container unprivileged and do not add SYS_ADMIN/privileged.
ENTRYPOINT ["/init"]
