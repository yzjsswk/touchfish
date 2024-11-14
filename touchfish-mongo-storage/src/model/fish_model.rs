use mongodb::bson::{oid::ObjectId, spec::BinarySubtype, Binary};
use serde::{Deserialize, Serialize};
use touchfish_core::{FishType, DataInfo, Fish};
use yfunc_rust::{prelude::*, YBytes, YTime};

#[derive(Serialize, Deserialize, Debug)]
pub struct FishModel {
    #[serde(rename = "_id")]
    pub id: ObjectId,
    pub identity: String,
    pub count: i32,
    pub fish_type: FishType,
    pub fish_data: Binary,
    pub fish_data_for_search: Option<String>,
    pub data_info: DataInfo,
    pub desc: String,
    pub tags: Vec<String>,
    pub is_marked: bool,
    pub is_locked: bool,
    pub extra_info: String,
    pub create_time: String,
    pub update_time: String,
    pub expire_time: Option<String>,
}

impl FishModel {

    pub fn new(
        identity: String, count: i32, fish_type: FishType, fish_data: YBytes, data_info: DataInfo,
        desc: String, tags: Vec<String>, is_marked: bool, is_locked: bool, extra_info: String,
    ) -> YRes<FishModel> {
        let fish_data_for_search = if fish_type == FishType::Text {
            Some(fish_data.to_str().map_err(|e| {
                err!("build fish model failed").trace(
                    ctx!("build fish model -> convert fish data for search for text type fish: fish_data.to_str() failed", identity, e)
                )
            })?)
        } else {
            None
        };
        let fish_data = Binary {
            subtype: BinarySubtype::Generic,
            bytes: fish_data.into_vec()
        };
        let create_time = YTime::now().to_str();
        let update_time = YTime::now().to_str();
        Ok(FishModel {
            id: ObjectId::new(), identity, count, fish_type, fish_data, fish_data_for_search,
            data_info, desc, tags, is_marked, is_locked, extra_info,
            create_time, update_time, expire_time: None,
        })
    }

}

impl TryFrom<FishModel> for Fish {

    type Error = YError;

    fn try_from(model: FishModel) -> YRes<Self> {
        let fish_data = YBytes::new(model.fish_data.bytes);
        let create_time = YTime::from_str(&model.create_time).trace(
            ctx!("try from FishModel to Fish -> parse create_time: YTime::from_str failed", model.create_time, model.id)
        )?;
        let update_time = YTime::from_str(&model.update_time).trace(
            ctx!("try from FishModel to Fish -> parse update_time: YTime::from_str failed", model.update_time, model.id)
        )?;
        Ok(Fish {
            id: model.id.to_hex(), identity: model.identity, count: model.count, fish_type: model.fish_type, fish_data,
            data_info: model.data_info, desc: model.desc, tags: model.tags, is_marked: model.is_marked,
            is_locked: model.is_locked, extra_info: model.extra_info, create_time, update_time,
        })
    }

}