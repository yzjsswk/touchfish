use serde::Serialize;
use yfunc_rust::prelude::*;

use crate::{DataInfo, Fish, FishType};

#[yfunc]
#[derive(Serialize, Debug)]
pub struct FishPreview {
    pub identity: String,
    pub count: i32,
    pub fish_type: FishType,
    pub data_preview: Option<String>,
    pub data_info: DataInfo,
    pub desc: String,
    pub tags: Vec<String>,
    pub is_marked: bool,
    pub is_locked: bool,
    pub extra_info: String,
    pub create_time: String,
    pub update_time: String,
}

impl FishPreview {

    pub fn from_fish(fish: &Fish) -> YRes<FishPreview> {
        let data_preview = match fish.fish_type {
            FishType::Text => {
                let preview = fish.fish_data.to_str().trace(
                    ctx!("build FishPreview by Fish -> parse fish_data to text for text type fish: fish.fish_data.to_str() failed", fish.identity)
                )?;
                Some(preview.chars().take(80).collect())
            },
            _ => None,
        };
        let create_time = fish.create_time.east8().trace(
            ctx!("build FishPreview by Fish -> get east8 time string of create_time: fish.create_time.east8() failed", fish.identity)
        )?;
        let update_time = fish.update_time.east8().trace(
            ctx!("build FishPreview by Fish -> get east8 time string of update_time: fish.update_time.east8() failed", fish.identity)
        )?;
        Ok(FishPreview { 
            identity: fish.identity.clone(), count: fish.count, fish_type: fish.fish_type,
            data_preview, data_info: fish.data_info.clone(), desc: fish.desc.clone(), tags: fish.tags.clone(),
            is_marked: fish.is_marked, is_locked: fish.is_locked, extra_info: fish.extra_info.clone(),
            create_time, update_time,
        })
    }

}
