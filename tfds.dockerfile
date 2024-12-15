# docker build -f tfds.dockerfile -t touchfish-data-server . 

FROM rust:1.82.0-bookworm as builder

WORKDIR /app

COPY Cargo.toml.tfds ./Cargo.toml
COPY Cargo.lock ./Cargo.lock
COPY touchfish-core ./touchfish-core
COPY touchfish-mongo-storage ./touchfish-mongo-storage
COPY touchfish-data-server ./touchfish-data-server

RUN cargo build --release

FROM debian:bookworm-slim

COPY --from=builder /app/target/release/touchfish-data-server /usr/local/bin/touchfish-data-server

CMD ["touchfish-data-server"]