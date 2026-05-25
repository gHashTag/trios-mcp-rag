FROM rust:1.90-bookworm AS builder
WORKDIR /usr/src/trios-mcp-rag
COPY . .
RUN cargo build --release

FROM debian:bookworm-slim

# Install runtime deps: ca-certificates for TLS, libssl3 for postgres,
# curl to fetch pandoc/tectonic, and fontconfig for OTF fonts.
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    curl \
    fontconfig \
    && rm -rf /var/lib/apt/lists/*

# --- Pandoc (static binary, no Haskell runtime needed) ---
ARG PANDOC_VERSION=3.9
RUN curl -fsSL -o /tmp/pandoc.tar.gz \
    "https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-linux-amd64.tar.gz" \
    && tar -xzf /tmp/pandoc.tar.gz -C /tmp \
    && cp /tmp/pandoc-*/bin/pandoc /usr/local/bin/pandoc \
    && rm -rf /tmp/pandoc*

# --- Tectonic (TeX engine) ---
ARG TECTONIC_VERSION=0.16.9
RUN curl -fsSL -o /tmp/tectonic.tar.gz \
    "https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%40${TECTONIC_VERSION}/tectonic-${TECTONIC_VERSION}-x86_64-unknown-linux-gnu.tar.gz" \
    && tar -xzf /tmp/tectonic.tar.gz -C /usr/local/bin \
    && rm /tmp/tectonic.tar.gz

# --- Latin Modern Math OTF (used by chapter.template.tex) ---
RUN mkdir -p /usr/share/fonts/opentype/lm \
    && curl -fsSL -o /usr/share/fonts/opentype/lm/latinmodern-math.otf \
       "https://github.com/alerque/libertinus/releases/download/v7.040/Latinmodernmath-Regular.otf" \
    || curl -fsSL -o /usr/share/fonts/opentype/lm/latinmodern-math.otf \
       "https://raw.githubusercontent.com/alerque/libertinus/master/Latinmodernmath-Regular.otf" \
    && fc-cache -fv

COPY --from=builder /usr/src/trios-mcp-rag/target/release/trios-mcp-rag /usr/local/bin/trios-mcp-rag

ENTRYPOINT ["trios-mcp-rag"]
