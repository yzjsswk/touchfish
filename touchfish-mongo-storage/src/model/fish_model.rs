use mongodb::bson::{oid::ObjectId, spec::BinarySubtype, Binary, DateTime};
use serde::{Serialize, Deserialize};
use touchfish_core::{FishType, DataInfo, Fish};
use yfunc_rust::{prelude::*, YBytes, YTime};

#[derive(Serialize, Deserialize, Debug)]
pub struct FishModel {
    #[serde(rename = "_id")]
    pub uid: ObjectId,
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
    pub create_time: DateTime,
    pub update_time: DateTime,
    pub expire_time: Option<DateTime>,
}

impl FishModel {

    pub fn new(
        identity: &str, count: i32, fish_type: FishType, fish_data: YBytes, data_info: &DataInfo,
        desc: &str, tags: &Vec<&str>, is_marked: bool, is_locked: bool, extra_info: &str,
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
        let tags = tags.iter().map(|tag| tag.to_string()).collect();
        Ok(FishModel {
            uid: ObjectId::new(), identity: identity.to_string(), count, 
            fish_type, fish_data, fish_data_for_search, data_info: data_info.clone(),
            desc: desc.to_string(), tags, is_marked, is_locked, extra_info: extra_info.to_string(),
            create_time: DateTime::now(), update_time: DateTime::now(), expire_time: None,
        })
    }

}

impl TryFrom<FishModel> for Fish {

    type Error = YError;

    fn try_from(model: FishModel) -> YRes<Self> {
        let fish_data = YBytes::new(model.fish_data.bytes);
        let create_time = YTime::from_str(&model.create_time.try_to_rfc3339_string().map_err(|e| {
            err!("build Fish from FishModel failed").trace(
                ctx!("parse FishModel to Fish -> parse create_time: model.create_time.try_to_rfc3339_string() failed", model.create_time, model.uid, e)
            )
        })?).trace(
            ctx!("parse FishModel to Fish -> parse create_time: YTime::from_str failed", model.create_time, model.uid)
        )?;
        let update_time = YTime::from_str(&model.update_time.try_to_rfc3339_string().map_err(|e| {
            err!("build Fish from FishModel failed").trace(
                ctx!("parse FishModel to Fish -> parse update_time: model.update_time.try_to_rfc3339_string() failed", model.update_time, model.uid, e)
            )
        })?).trace(
            ctx!("parse FishModel to Fish -> parse update_time: YTime::from_str failed", model.update_time, model.uid)
        )?;
        Ok(Fish {
            uid: model.uid.to_hex(), identity: model.identity, count: model.count, fish_type: model.fish_type, fish_data,
            data_info: model.data_info, desc: model.desc, tags: model.tags, is_marked: model.is_marked,
            is_locked: model.is_locked, extra_info: model.extra_info, create_time, update_time,
        })
    }

}