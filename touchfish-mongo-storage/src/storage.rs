use mongodb::{Client, Collection};
use yfunc_rust::prelude::*;

use crate::model::FishModel;

mod fish_storage;

pub struct MongoStorage {
    client: Client
}

impl MongoStorage {

    pub async fn new(uri: &str) -> YRes<MongoStorage> {
        let client = Client::with_uri_str(uri).await.map_err(|e|
            err!("connect to mongodb failed").trace(
                ctx!("build mongo storage: Client::with_uri_str failed", uri, e)
            )
        )?;
        Ok(MongoStorage {client})
    }

    fn collection__fish(&self) -> Collection<FishModel> {
        self.client.database("touchfish").collection::<FishModel>("fish")
    }

}
