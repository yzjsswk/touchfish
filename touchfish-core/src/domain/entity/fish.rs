use serde::{Deserialize, Serialize};
use serde_with::skip_serializing_none;
use strum_macros::{Display, EnumString};
use yfunc_rust::{prelude::*, YBytes, YTime};

use crate::FishPreview;

#[yfunc]
#[derive(Serialize, Debug)]
pub struct Fish {
    pub id: i32,
    pub identity: String,
    pub count: i32,
    pub fish_type: FishType,
    pub fish_data: YBytes,
    pub data_info: DataInfo,
    pub desc: String,
    pub tags: Vec<String>,
    pub is_marked: bool,
    pub is_locked: bool,
    pub extra_info: String,
    pub create_time: YTime,
    pub update_time: YTime,
}

impl Fish {

    pub fn to_preview_json(&self) -> YRes<String> {
        FishPreview::from_fish(self).trace(
            ctx!("serialize Fish to preview style json string -> build FishPreview from Fish: FishPreview::from_fish failed", self.identity)
        )?.to_pretty_json_str().trace(
            ctx!("serialize Fish to preview style json string -> serialize FishPreview to json: FishPreview::to_pretty_json_str failed", self.identity)
        )
    }

}

#[yfunc]
#[derive(Serialize, Deserialize, Debug, EnumString, Display, PartialEq, Eq, Hash, Clone, Copy)]
pub enum FishType {
    Text,
    Image,
    Other,
}

#[yfunc]
#[skip_serializing_none]
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct DataInfo {
    pub byte_count: Option<usize>,
    // Text
    pub char_count: Option<usize>,
    pub word_count: Option<usize>,
    pub row_count: Option<usize>,
    // Image
    pub width: Option<usize>,
    pub height: Option<usize>,
}

impl DataInfo {

    pub fn new() -> DataInfo {
        DataInfo { 
            byte_count: None, 
            char_count: None, word_count: None, row_count: None,
            width: None, height: None,
        }
    }

}
