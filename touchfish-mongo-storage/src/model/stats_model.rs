use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
pub struct StatsModel {
    #[serde(rename = "_id")]
    pub name: String,
    pub count: u64,
}
