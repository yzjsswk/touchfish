use mongodb::{bson::doc, options::IndexOptions, Client, Collection, IndexModel};
use yfunc_rust::prelude::*;

use crate::model::{FishModel, TopicModel};

mod fish_storage;
mod topic_storage;

#[derive(Clone)]
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
        let storage = MongoStorage {client};
        storage.create_index_if_not_exists().await.trace(
            ctx!("build mongo storage: storage.create_index_if_not_exists() failed")
        )?;
        Ok(storage)
    }

    async fn create_index_if_not_exists(&self) -> YRes<()> {
        let index_on_fish= self.collection__fish().list_index_names().await.map_err(|e| {
            err!("check index failed").trace(
                ctx!("check index -> get index on fish: self.collection__fish().list_index_names() failed", e)
            )
        })?;
        let index_on_topic= self.collection__topic().list_index_names().await.map_err(|e| {
            err!("check index failed").trace(
                ctx!("check index -> get index on topic: self.collection__topic().list_index_names() failed", e)
            )
        })?;
        if !index_on_fish.contains(&"idx_unique_data".to_string()) {
            let index = IndexModel::builder()
                .keys(doc! { "identity": 1, "expire_time": 1 })
                .options(
                    IndexOptions::builder()
                        .unique(true)
                        .name("idx_unique_data".to_string())
                        .build()
                )
                .build();
            info!("check index: create index idx_unique_data on fish...");
            self.collection__fish().create_index(index).await.map_err(|e| {
                err!("check index failed").trace(
                    ctx!("check index -> create idx_unique_data on fish: self.collection__fish().create_index failed", e)
                )
            })?;
        }
        if !index_on_fish.contains(&"idx_update_time".to_string()) {
            let index = IndexModel::builder()
                .keys(doc! { "update_time": -1 })
                .options(
                    IndexOptions::builder()
                        .unique(true)
                        .name("idx_update_time".to_string())
                        .build()
                )
                .build();
            info!("check index: create index idx_update_time on fish...");
            self.collection__fish().create_index(index).await.map_err(|e| {
                err!("check index failed").trace(
                    ctx!("check index -> create idx_update_time on fish: self.collection__fish().create_index failed", e)
                )
            })?;
        }
        if !index_on_topic.contains(&"idx_unique_subject".to_string()) {
            let index = IndexModel::builder()
                .keys(doc! { "subject": 1, "expire_time": 1 })
                .options(
                    IndexOptions::builder()
                        .unique(true)
                        .name("idx_unique_subject".to_string())
                        .build()
                )
                .build();
            info!("check index: create index idx_unique_subject on topic...");
            self.collection__topic().create_index(index).await.map_err(|e| {
                err!("check index failed").trace(
                    ctx!("check index -> create idx_unique_subject on topic: self.collection__topic().create_index failed", e)
                )
            })?;
        }
        Ok(())
    }

    fn collection__fish(&self) -> Collection<FishModel> {
        self.client.database("touchfish").collection::<FishModel>("fish")
    }

    fn collection__topic(&self) -> Collection<TopicModel> {
        self.client.database("touchfish").collection::<TopicModel>("topic")
    }

}
