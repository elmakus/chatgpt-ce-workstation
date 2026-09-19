# syntax=docker/dockerfile:1
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG S6_OVERLAY_VERSION=3.2.3.2
ARG CE_REPOSITORY=https://github.com/ilysenko/codex-desktop-linux.git
ARG CE_REF=main
ARG CODEX_CHATGPT_WEB_VERSION=
ARG AGENT_WORKSPACE_VERSION=0.3.2
ARG MUSE_INSTALLER_URL=https://dev.meta.ai/install.sh
ARG MUSE_INSTALLER_SHA256=
ARG CODEX_UID=99
ARG CODEX_GID=100
ARG UPSTREAM_REFRESH=bootstrap

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

# Runtime + developer workstation tools.
# Keep durable additions here instead of installing them manually in a live container.
RUN apt-get update && apt-get install -y --no-install-recommends \
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
    x11-utils \
    && rm -rf /var/lib/apt/lists/*

# Debian/Ubuntu call fd "fdfind". Expose the common "fd" spelling too.
RUN ln -sf /usr/bin/fdfind /usr/local/bin/fd

# Install official Google Chrome Stable rather than Ubuntu's Chromium snap
# transition package. This gives CE Browser Use and Agent Workspace a real
# browser inside the immutable workstation image without depending on snapd.
# UPSTREAM_REFRESH is referenced so scripts/update.sh can refresh Chrome too.
RUN set -eux; \
    echo "Google Chrome upstream refresh token: ${UPSTREAM_REFRESH}"; \
    install -d -m 0755 /etc/apt/keyrings; \
    curl -fsSL --retry 3 --retry-all-errors https://dl.google.com/linux/linux_signing_key.pub \
      | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg; \
    chmod 0644 /etc/apt/keyrings/google-chrome.gpg; \
    printf '%s\n' 'deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main' \
      > /etc/apt/sources.list.d/google-chrome.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends google-chrome-stable; \
    google-chrome --version; \
    rm -rf /var/lib/apt/lists/*

# s6-overlay: container-native PID 1 / service supervision.
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp/s6-overlay-x86_64.tar.xz
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz \
    && tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz \
    && rm -f /tmp/s6-overlay-*.tar.xz

# Match the usual Unraid nobody:users numeric ownership by default.
# Fail loudly if the base image unexpectedly consumes UID 99.
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

# Install a current Rust toolchain system-wide enough for CE native feature helper builds,
# while leaving the user's normal Cargo cache under the persistent home at runtime.
RUN set -eux; \
    export CARGO_HOME=/opt/cargo; \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/rustup-init.sh; \
    sh /tmp/rustup-init.sh -y --profile minimal --default-toolchain stable; \
    rm -f /tmp/rustup-init.sh; \
    rustc --version; cargo --version

# Build ChatGPT Community from the verified official OpenAI Linux package.
# UPSTREAM_REFRESH is deliberately referenced here so scripts/update.sh can
# invalidate this remote-source layer without disabling Docker cache globally.
WORKDIR /tmp/ce-build
RUN set -eux; \
    echo "CE upstream refresh token: ${UPSTREAM_REFRESH}"; \
    git clone --depth 1 --branch "${CE_REF}" "${CE_REPOSITORY}" /tmp/ce-build/src; \
    git -C /tmp/ce-build/src rev-parse HEAD
COPY config/ce-features.json /tmp/ce-build/src/linux-features/features.json
RUN set -eux; \
    cd /tmp/ce-build/src; \
    export CARGO_HOME=/opt/cargo; \
    bash scripts/install-deps.sh; \
    PACKAGE_WITH_UPDATER=0 make build-native-feature-helpers; \
    PACKAGE_WITH_UPDATER=0 make build-app; \
    PACKAGE_WITH_UPDATER=0 make deb; \
    deb="$(scripts/select-latest-package.sh "$PWD/dist/codex-desktop_*.deb")"; \
    test -n "$deb"; \
    dpkg -i "$deb" || { apt-get update; apt-get -f install -y; dpkg -i "$deb"; }; \
    command -v codex-desktop; \
    rm -rf /tmp/ce-build /var/lib/apt/lists/*

# CE's dependency/install stage can change packages that the workstation desktop
# itself needs. Reconcile the full desktop/keyring substrate after CE is installed
# and assert it here so a broken noVNC recovery surface fails during image build.
RUN set -eux; \
    apt-get update; \
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

# Agent Workspace backend. Pin the known-good published version so ordinary
# rebuilds cannot silently change this runtime beneath an unchanged repo.
RUN npm install -g "@agent-sh/agent-workspace-linux@${AGENT_WORKSPACE_VERSION}" \
    && command -v agent-workspace-linux

# Install Muse Code into the immutable application layer while keeping build-time
# installer state out of /home/codex. The helper records the installer checksum,
# optionally verifies a configured pin, resolves the current stable binary and
# leaves runtime auth/settings to the persistent user home.
COPY scripts/build/install-muse-code.sh /tmp/install-muse-code.sh
RUN set -eux; \
    echo "Muse Code upstream refresh token: ${UPSTREAM_REFRESH}"; \
    chmod 0755 /tmp/install-muse-code.sh; \
    MUSE_INSTALLER_URL="${MUSE_INSTALLER_URL}" \
    MUSE_INSTALLER_SHA256="${MUSE_INSTALLER_SHA256}" \
      /tmp/install-muse-code.sh; \
    test -x /opt/muse-code/bin/muse; \
    rm -f /tmp/install-muse-code.sh

# Install Codex Web GPT into the immutable application layer. The helper follows
# the upstream release/checksum contract but intentionally does NOT launch its
# Electron GUI during docker build; the GUI is started later inside Xvfb/noVNC.
COPY scripts/build/install-codex-web-gpt.sh /tmp/install-codex-web-gpt.sh
RUN set -eux; \
    echo "codex-chatgpt-web upstream refresh token: ${UPSTREAM_REFRESH}"; \
    chmod 0755 /tmp/install-codex-web-gpt.sh; \
    CODEX_CHATGPT_WEB_VERSION="${CODEX_CHATGPT_WEB_VERSION}" /tmp/install-codex-web-gpt.sh; \
    command -v codex-web-gpt; \
    rm -f /tmp/install-codex-web-gpt.sh

COPY rootfs/ /
COPY scripts/container/ /opt/workstation/bin/
COPY defaults/ /opt/workstation/defaults/

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
    && mkdir -p /home/codex/.local/share/applications /home/codex/Documents/ChatGPT \
    && chown -R codex:"${CODEX_GID}" /home/codex

WORKDIR /home/codex/Documents/ChatGPT
EXPOSE 6080

# Avoid Chromium/Electron's tiny default Docker /dev/shm at runtime through
# compose.yaml's shm_size. CE itself is launched with --no-sandbox by the desktop
# session because its Electron sandbox is unusable under the current Unraid Docker
# boundary; keep the container unprivileged and do not add SYS_ADMIN/privileged.
ENTRYPOINT ["/init"]
