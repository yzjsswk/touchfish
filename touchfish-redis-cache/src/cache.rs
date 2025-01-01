use redis::{Client, Connection};

use yfunc_rust::prelude::*;

mod recipe_cache;

pub struct RedisCache {
    client: Client
}

impl RedisCache {

    pub fn new(uri: &str) -> YRes<RedisCache> {
        let client = Client::open(uri).map_err(|e| {
            err!("connect to redis failed").trace(
                ctx!("build redis cache: Client::open failed", uri, e)
            )
        })?;
        Ok(RedisCache { client })
    }

    pub fn get_conn(&self) -> YRes<Connection> {
        self.client.get_connection().map_err(|e| {
            err!("get redis connection failed").trace(
                ctx!("get redis connection: self.client.get_connection failed", e)
            )
        })
    }

}
