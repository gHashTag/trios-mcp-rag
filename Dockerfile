FROM rust:1.90-bookworm AS builder
WORKDIR /usr/src/trios-mcp-rag
COPY . .
RUN cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates libssl3 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /usr/src/trios-mcp-rag/target/release/trios-mcp-rag /usr/local/bin/trios-mcp-rag
ENTRYPOINT ["trios-mcp-rag"]
