use touchfish_core::FishType;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct SearchFishReq {
    pub fuzzy: Option<String>,
    pub identity: Option<Vec<String>>, 
    pub fish_type: Option<Vec<FishType>>,
    pub desc: Option<String>,
    pub tags: Option<Vec<String>>,
    pub is_marked: Option<bool>,
    pub is_locked: Option<bool>,
    pub page_num: Option<i32>,
    pub page_size: Option<i32>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct DelectFishReq {
    pub fuzzy: Option<String>,
    pub identity: Option<Vec<String>>, 
    pub fish_type: Option<Vec<FishType>>,
    pub desc: Option<String>,
    pub tags: Option<Vec<String>>,
    pub is_marked: Option<bool>,
    pub is_locked: Option<bool>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AddFishReq {
    pub fish_type: FishType,
    pub fish_data: String,
    pub desc: Option<String>,
    pub tags: Option<Vec<String>>,
    pub is_marked: Option<bool>,
    pub is_locked: Option<bool>,
    pub extra_info: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ModifyFishReq {
    pub identity: String,
    pub desc: Option<String>,
    pub tags: Option<Vec<String>>,
    pub extra_info: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ExpireFishReq {
    pub identitys: Vec<String>,
    pub skip_if_not_exists: bool,
    pub skip_if_locked: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct MarkFishReq {
    pub identitys: Vec<String>,
    pub skip_if_not_exists: bool,
    pub skip_if_locked: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UnmarkFishReq {
    pub identitys: Vec<String>,
    pub skip_if_not_exists: bool,
    pub skip_if_locked: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct LockFishReq {
    pub identitys: Vec<String>,
    pub skip_if_not_exists: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UnlockFishReq {
    pub identitys: Vec<String>,
    pub skip_if_not_exists: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PinFishReq {
    pub identitys: Vec<String>,
    pub skip_if_not_exists: bool,
    pub skip_if_locked: bool,
}
