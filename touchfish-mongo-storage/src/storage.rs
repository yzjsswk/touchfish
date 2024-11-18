use mongodb::{bson::doc, options::IndexOptions, Client, Collection, Database, IndexModel};
use yfunc_rust::prelude::*;

use crate::model::{FishModel, TopicModel};

mod fish_storage;
mod topic_storage;

const DATABASE_NAME: &str = "touchfish";
const COLLECTION_NAME__FISH: &str = "fish";
const COLLECTION_NAME__TOPIC: &str = "topic";

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
        storage.create_collection_if_not_exists().await.trace(
            ctx!("build monogo storage: storage.create_collection_if_not_exists failed")
        )?;
        storage.create_index_if_not_exists().await.trace(
            ctx!("build mongo storage: storage.create_index_if_not_exists failed")
        )?;
        Ok(storage)
    }

    async fn create_collection_if_not_exists(&self) -> YRes<()> {
        let collections = self.database().list_collection_names().await.map_err(|e| {
            err!("create_collection_if_not_exists failed").trace(
                ctx!("create_collection_if_not_exists -> get all collections: self.database().list_collection_names() failed", e)
            )
        })?;
        if !collections.contains(&COLLECTION_NAME__FISH.to_string()) {
            info!("create collection fish...");
            self.database().create_collection(COLLECTION_NAME__FISH).await.map_err(|e| {
                err!("create_collection_if_not_exists failed").trace(
                    ctx!("create_collection_if_not_exists -> create collection fish: self.database().create_collection failed", e)
                )
            })?;
        }
        if !collections.contains(&COLLECTION_NAME__TOPIC.to_string()) {
            info!("create collection topic...");
            self.database().create_collection(COLLECTION_NAME__TOPIC).await.map_err(|e| {
                err!("create_collection_if_not_exists failed").trace(
                    ctx!("create_collection_if_not_exists -> create collection topic: self.database().create_collection failed", e)
                )
            })?;
        }
        Ok(())
    }

    async fn create_index_if_not_exists(&self) -> YRes<()> {
        let index_on_fish= self.collection__fish().list_index_names().await.map_err(|e| {
            err!("create_index_if_not_exists failed").trace(
                ctx!("create_index_if_not_exists -> get index on fish: self.collection__fish().list_index_names() failed", e)
            )
        })?;
        let index_on_topic= self.collection__topic().list_index_names().await.map_err(|e| {
            err!("create_index_if_not_exists failed").trace(
                ctx!("create_index_if_not_exists -> get index on topic: self.collection__topic().list_index_names() failed", e)
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
            info!("create index idx_unique_data on fish...");
            self.collection__fish().create_index(index).await.map_err(|e| {
                err!("create_index_if_not_exists failed").trace(
                    ctx!("create_index_if_not_exists -> create idx_unique_data on fish: self.collection__fish().create_index failed", e)
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
            info!("create index idx_update_time on fish...");
            self.collection__fish().create_index(index).await.map_err(|e| {
                err!("create_index_if_not_exists failed").trace(
                    ctx!("create_index_if_not_exists -> create idx_update_time on fish: self.collection__fish().create_index failed", e)
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
            info!("create index idx_unique_subject on topic...");
            self.collection__topic().create_index(index).await.map_err(|e| {
                err!("create_index_if_not_exists failed").trace(
                    ctx!("create_index_if_not_exists -> create idx_unique_subject on topic: self.collection__topic().create_index failed", e)
                )
            })?;
        }
        Ok(())
    }

    fn database(&self) -> Database {
        self.client.database(DATABASE_NAME)
    }

    fn collection__fish(&self) -> Collection<FishModel> {
        self.database().collection::<FishModel>(COLLECTION_NAME__FISH)
    }

    fn collection__topic(&self) -> Collection<TopicModel> {
        self.database().collection::<TopicModel>(COLLECTION_NAME__TOPIC)
    }

}
