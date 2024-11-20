use mongodb::bson::{oid::ObjectId, DateTime};
use serde::{Serialize, Deserialize};
use touchfish_core::{Message, Topic, TopicExtraInfo, TopicType};
use yfunc_rust::{prelude::*, YTime};

use super::MessageModel;

#[derive(Serialize, Deserialize, Debug)]
pub struct TopicModel {
    #[serde(rename = "_id")]
    pub uid: ObjectId,
    pub topic_type: TopicType,
    pub subject: String,
    pub source: String,
    pub title: String,
    pub messages: Vec<MessageModel>,
    pub extra_info: TopicExtraInfo,
    pub create_time: DateTime,
    pub update_time: DateTime,
    pub expire_time: Option<DateTime>,
}

impl TopicModel {

    pub fn new(topic_type: TopicType, subject: &str, source: &str, title: &str, extra_info: &TopicExtraInfo) -> TopicModel {
        TopicModel {
            uid: ObjectId::new(), topic_type, subject: subject.to_string(), source: source.to_string(),
            title: title.to_string(), messages: Vec::new(), extra_info: extra_info.clone(),
            create_time: DateTime::now(), update_time: DateTime::now(), expire_time: None,
        }
    }

}

impl TryFrom<TopicModel> for Topic {

    type Error = YError;

    fn try_from(model: TopicModel) -> YRes<Self> {
        let messages = model.messages.into_iter().try_fold::<_, _, YRes<_>>(Vec::new(), |mut acc, it| {
            let message_uid = it.uid;
            let message = Message::try_from(it).trace(
                ctx!("parse TopicModel to Topic -> parse messages: Message::try_from failed", message_uid, model.uid)
            )?;
            acc.push(message);
            Ok(acc)
        })?;
        let create_time = YTime::from_str(&model.create_time.try_to_rfc3339_string().map_err(|e| {
            err!("build Topic from TopicModel failed").trace(
                ctx!("parse TopicModel to Topic -> parse create_time: model.create_time.try_to_rfc3339_string() failed", model.create_time, model.uid, e)
            )
        })?).trace(
            ctx!("parse TopicModel to Topic -> parse create_time: YTime::from_str failed", model.create_time, model.uid)
        )?;
        let update_time = YTime::from_str(&model.update_time.try_to_rfc3339_string().map_err(|e| {
            err!("build Topic from TopicModel failed").trace(
                ctx!("parse TopicModel to Topic -> parse update_time: model.update_time.try_to_rfc3339_string() failed", model.update_time, model.uid, e)
            )
        })?).trace(
            ctx!("parse TopicModel to Topic -> parse update_time: YTime::from_str failed", model.update_time, model.uid)
        )?;
        Ok(Topic {
            uid: model.uid.to_hex(), topic_type: model.topic_type, subject: model.subject, source: model.source,
            title: model.title, messages, extra_info: model.extra_info, create_time, update_time,
        })
    }

}
