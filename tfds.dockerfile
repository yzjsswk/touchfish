FROM rust:1.82.0-bookworm as builder
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
COPY touchfish-core ./touchfish-core
COPY touchfish-sqlite-storage ./touchfish-sqlite-storage
COPY touchfish-data-server ./touchfish-data-server
COPY touchfish-cli ./touchfish-cli
RUN cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && \
apt-get install -y --no-install-recommends apt-transport-https ca-certificates && \
apt-get update && \
apt-get install -y libsqlite3-0 && \
rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/touchfish-data-server /usr/local/bin/touchfish-data-server

CMD ["touchfish-data-server"]