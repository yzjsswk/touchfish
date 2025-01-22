use std::collections::HashMap;

use touchfish_core::{FishType, MessageExtraInfo, MessageLevel, TopicExtraInfo, TopicType};
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct SearchFishReq {
    pub fuzzy: Option<String>,
    pub identitys: Option<Vec<String>>, 
    pub fish_types: Option<Vec<FishType>>,
    pub desc: Option<String>,
    pub tags: Option<Vec<String>>,
    pub is_marked: Option<bool>,
    pub is_locked: Option<bool>,
    pub create_after: Option<i64>,
    pub create_before: Option<i64>,
    pub update_after: Option<i64>,
    pub update_before: Option<i64>,
    pub page_num: Option<u64>,
    pub page_size: Option<u64>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct DelectFishReq {
    pub fuzzy: Option<String>,
    pub identitys: Option<Vec<String>>, 
    pub fish_types: Option<Vec<FishType>>,
    pub desc: Option<String>,
    pub tags: Option<Vec<String>>,
    pub is_marked: Option<bool>,
    pub is_locked: Option<bool>,
    pub create_after: Option<i64>,
    pub create_before: Option<i64>,
    pub update_after: Option<i64>,
    pub update_before: Option<i64>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AddFishReq {
    pub fish_type: FishType,
    pub fish_data: String,
    pub desc: Option<String>,
    pub tags: Option<Vec<String>>,
    pub is_marked: Option<bool>,
    pub is_locked: Option<bool>,
    pub extra_info: HashMap<String, String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ModifyFishReq {
    pub uid: String,
    pub desc: Option<String>,
    pub tags: Option<Vec<String>>,
    pub extra_info: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ExpireFishReq {
    pub uids: Vec<String>,
    pub skip_if_not_exists: bool,
    pub skip_if_locked: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct MarkFishReq {
    pub uids: Vec<String>,
    pub skip_if_not_exists: bool,
    pub skip_if_locked: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UnmarkFishReq {
    pub uids: Vec<String>,
    pub skip_if_not_exists: bool,
    pub skip_if_locked: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct LockFishReq {
    pub uids: Vec<String>,
    pub skip_if_not_exists: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UnlockFishReq {
    pub uids: Vec<String>,
    pub skip_if_not_exists: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PinFishReq {
    pub uids: Vec<String>,
    pub skip_if_not_exists: bool,
    pub skip_if_locked: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreateTopicReq {
    pub topic_type: TopicType,
    pub subject: String,
    pub source: String,
    pub title: String,
    pub extra_info: TopicExtraInfo,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SendMessageReq {
    pub topic_subject: String,
    pub level: MessageLevel,
    pub title: String,
    pub body: String,
    pub has_read: bool,
    pub extra_info: MessageExtraInfo,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ReadMessageReq {
    pub topic_uid: String,
    pub message_uid: String,
}
