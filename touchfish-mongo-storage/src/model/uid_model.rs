use mongodb::bson::oid::ObjectId;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
pub struct UidModel {
    #[serde(rename = "_id")]
    pub uid: ObjectId,
}
