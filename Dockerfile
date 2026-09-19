# ==========================================
# STAGE 1: Builder (Compiling & Downloading)
# ==========================================
# Fonts are no longer built here; they live in a dedicated fonts image
# (see Dockerfile.fonts) and are imported directly by the runtime image.
FROM ubuntu:26.04 AS builder
LABEL maintainer="Jens Frey <jens.frey@coffeecrew.org>" Version="2026-09-19"

ENV DEBIAN_FRONTEND=noninteractive

# Check for releases at https://github.com/jgraph/drawio-desktop/releases
ARG DRAWIO_VER=31.4.5

# Check for releases at https://github.com/plantuml/plantuml/releases
ARG PLANTUML_VER=1.2026.8

# Install only the tools needed to build the venv and download assets
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-full python3-venv python3-dev build-essential gcc g++ libffi-dev \
    wget curl aria2 unzip git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 1. Build the Python virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

WORKDIR /staging

# 2. Download the latest PlantUML
RUN curl -L "https://github.com/plantuml/plantuml/releases/download/v${PLANTUML_VER}/plantuml-${PLANTUML_VER}.jar" -o plantuml.jar

# 3. Get latest Draw.io
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        URL="https://github.com/jgraph/drawio-desktop/releases/download/v${DRAWIO_VER}/drawio-amd64-${DRAWIO_VER}.deb"; \
    elif [ "$ARCH" = "arm64" ]; then \
        URL="https://github.com/jgraph/drawio-desktop/releases/download/v${DRAWIO_VER}/drawio-arm64-${DRAWIO_VER}.deb"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    curl -L "$URL" -o drawio.deb

# 4. Install d2 binary, as this is used in e.g. the 'terrastruct.d2' vscode extension
RUN curl -fsSL https://d2lang.com/install.sh | sh -s --

# 5. Pre-download the pinned bge-m3 ONNX weights (~2.3 GB) for doxtr-rag.
#    Pinned commit -> reproducible model revision matching the 1024-dim parity
#    contract. Staged here (slow, rarely changes); copied into the reactor image.
ARG BGE_M3_SHA=5617a9f61b028005a4858fdac845db406aefb181
RUN mkdir -p /staging/models/bge-m3 && \
    for f in model.onnx model.onnx_data config.json tokenizer.json \
             tokenizer_config.json special_tokens_map.json \
             sentencepiece.bpe.model Constant_7_attr__value; do \
      aria2c --dir=/staging/models/bge-m3 --out="$f" \
             --allow-overwrite=true --auto-file-renaming=false \
             --max-connection-per-server=8 --split=8 --min-split-size=20M \
             "https://huggingface.co/BAAI/bge-m3/resolve/${BGE_M3_SHA}/onnx/$f"; \
    done