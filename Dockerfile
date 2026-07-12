# ==========================================
# STAGE 1: Builder (Compiling & Downloading)
# ==========================================
FROM ubuntu:24.04 AS builder
LABEL maintainer="Jens Frey <jens.frey@coffeecrew.org>" Version="2026-07-12"

ENV DEBIAN_FRONTEND=noninteractive

ARG DRAWIO_VER=30.3.6

# Install only the tools needed to build the venv and download assets
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-full python3-venv python3-dev build-essential gcc g++ libffi-dev \
    wget curl unzip git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 1. Build the Python virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 2. Download and extract fonts to a staging directory
WORKDIR /build-fonts
RUN git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git \
    && curl -sSL https://github.com/google/fonts/archive/main.zip -o gfonts.zip \
    && unzip -q gfonts.zip \
    && mkdir -p /staging/fonts \
    && cp -R nerd-fonts/patched-fonts/* /staging/fonts/ 2>/dev/null || true \
    && cp -R fonts-main/ofl/* /staging/fonts/ 2>/dev/null || true \
    && cp -R fonts-main/apache/* /staging/fonts/ 2>/dev/null || true \
    && cp -R fonts-main/ufl/* /staging/fonts/ 2>/dev/null || true

# 3. Download the latest PlantUML
RUN wget "https://sourceforge.net/projects/plantuml/files/plantuml.jar" -O /staging/plantuml.jar --no-check-certificate

# 4. Get latest Draw.io
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        URL="https://github.com/jgraph/drawio-desktop/releases/download/v${DRAWIO_VER}/drawio-amd64-${DRAWIO_VER}.deb"; \
    elif [ "$ARCH" = "arm64" ]; then \
        URL="https://github.com/jgraph/drawio-desktop/releases/download/v${DRAWIO_VER}/drawio-arm64-${DRAWIO_VER}.deb"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    wget -q -O /tmp/drawio.deb "$URL"

# 5. Install d2 binary, as this is used in e.g. the 'terrastruct.d2' vscode extension
RUN curl -fsSL https://d2lang.com/install.sh | sh -s --

