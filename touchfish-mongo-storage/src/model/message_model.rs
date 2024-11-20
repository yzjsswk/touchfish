use mongodb::bson::{oid::ObjectId, DateTime};
use serde::{Serialize, Deserialize};
use touchfish_core::{Message, MessageExtraInfo, MessageLevel};
use yfunc_rust::{prelude::*, YTime};

#[derive(Serialize, Deserialize, Debug)]
pub struct MessageModel {
    #[serde(rename = "_id")]
    pub uid: ObjectId,
    pub level: MessageLevel,
    pub title: String,
    pub body: String,
    pub has_read: bool,
    pub extra_info: MessageExtraInfo,
    pub create_time: DateTime,
    pub update_time: DateTime,
}

impl MessageModel {

    pub fn new(
        level: MessageLevel, title: &str, body: &str, has_read: bool, extra_info: &MessageExtraInfo,
    ) -> MessageModel {
        MessageModel { 
            uid: ObjectId::new(), level, title: title.to_string(), body: body.to_string(),
            has_read, extra_info: extra_info.clone(), create_time: DateTime::now(), update_time: DateTime::now(),
        }
    }

}

impl TryFrom<MessageModel> for Message {

    type Error = YError;

    fn try_from(model: MessageModel) -> YRes<Self> {
        let create_time = YTime::from_str(&model.create_time.try_to_rfc3339_string().map_err(|e| {
            err!("build Message from MessageModel failed").trace(
                ctx!("parse MessageModel to Message -> parse create_time: model.create_time.try_to_rfc3339_string() failed", model.create_time, model.uid, e)
            )
        })?).trace(
            ctx!("parse MessageModel to Message -> parse create_time: YTime::from_str failed", model.create_time, model.uid)
        )?;
        let update_time = YTime::from_str(&model.update_time.try_to_rfc3339_string().map_err(|e| {
            err!("build Message from MessageModel failed").trace(
                ctx!("parse MessageModel to Message -> parse update_time: model.update_time.try_to_rfc3339_string() failed", model.update_time, model.uid, e)
            )
        })?).trace(
            ctx!("parse MessageModel to Message -> parse update_time: YTime::from_str failed", model.update_time, model.uid)
        )?;
        Ok(Message {
            uid: model.uid.to_hex(), level: model.level, title: model.title,
            body: model.body, has_read: model.has_read, extra_info: model.extra_info,
            create_time, update_time,
        })
    }

}
