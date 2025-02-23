# docker build -f tfrs.dockerfile -t touchfish-recipe-server .

FROM rust:1.82.0-bookworm as builder

WORKDIR /app

COPY Cargo.toml.tfrs ./Cargo.toml
COPY Cargo.lock ./Cargo.lock
COPY touchfish-core ./touchfish-core
COPY touchfish-redis-cache ./touchfish-redis-cache
COPY touchfish-recipe-server ./touchfish-recipe-server
RUN cargo build --release

FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

RUN python3 -m pip install --upgrade pip
RUN pip3 install touchfish==1.1.1

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    sdcv && \
    rm -rf /var/lib/apt/lists/*
COPY dockerbuild/recipes/Dictionary/stardict /root/.stardict/dic

COPY --from=builder /app/target/release/touchfish-recipe-server /usr/local/bin/touchfish-recipe-server

CMD ["touchfish-recipe-server"]