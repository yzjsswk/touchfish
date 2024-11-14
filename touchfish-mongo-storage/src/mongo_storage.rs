use mongodb::{bson::{self, doc, Binary, Document}, Client, Collection};
use touchfish_core::FishStorage;
use yfunc_rust::prelude::*;

use crate::model::FishModel;

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

    pub async fn add_fish(
        &self, identity: String, count: i32, fish_type: touchfish_core::FishType, fish_data: yfunc_rust::YBytes, data_info: touchfish_core::DataInfo,
        desc: String, tags: Vec<String>, is_marked: bool, is_locked: bool, extra_info: String,
    ) -> YRes<()> {  
        let model = FishModel::new(
            identity, count, fish_type, fish_data, data_info,
            desc, tags, is_marked, is_locked, extra_info,
        )?;
        let x = self.collection__fish().insert_one(model).await.map_err(|e| {
            err!("add fish failed").trace(ctx!("add fish: insert_one() failed", e))
        })?;
        Ok(())
    }

}
