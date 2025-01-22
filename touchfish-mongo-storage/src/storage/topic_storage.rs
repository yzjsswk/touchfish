use std::collections::HashMap;

use mongodb::bson::{to_bson, doc, oid::ObjectId, Bson, DateTime};
use touchfish_core::{MessageLevel, Topic, TopicStorage};
use yfunc_rust::prelude::*;

use crate::model::{MessageModel, TopicModel};

use super::MongoStorage;

impl TopicStorage for MongoStorage {

    async fn add_topic(
        &self, subject: &str, source: &str, title: &str, extra_info: &HashMap<String, String>,
    ) -> YRes<String> {
        let model = TopicModel::new(subject, source, title, extra_info);
        let result = self.collection__topic().insert_one(model).await.map_err(|e| {
            err!("add topic failed").trace(ctx!("add topic: self.collection__topic().insert_one() failed", e))
        })?;
        let Some(inserted_uid) = result.inserted_id.as_object_id() else {
            return Err(err!("add topic may success but failed to get insert_uid").trace(
                ctx!("add topic -> parse inserted_uid to ObjectId: result.inserted_id.as_object_id failed", result.inserted_id)
            ))
        };
        Ok(inserted_uid.to_hex())
    }

    async fn remove_topic(&self, uid: &str) -> YRes<()> {
        let uid = ObjectId::parse_str(uid).map_err(|e| {
            err!("remove topic failed").trace(ctx!("remove topic -> parse uid to ObjectId: ObjectId::parse_str failed", uid, e))
        })?;
        let filter = doc! {
            "_id": uid,
        };
        let updater = doc! {
            "$set": {
                "expire_time": DateTime::now(),
            }
        };
        let _ = self.collection__topic().update_one(filter, updater).await.map_err(|e| {
            err!("remove topic failed").trace(ctx!("remove topic: self.collection__topic().update_one failed", uid, e))
        })?;
        Ok(())
    }

    async fn append_message(
        &self, uid: &str, level: MessageLevel, title: &str, body: &str, has_read: bool, extra_info: &HashMap<String, String>,
    ) -> YRes<()> {
        let uid = ObjectId::parse_str(uid).map_err(|e| {
            err!("append message failed").trace(ctx!("append message -> parse uid to ObjectId: ObjectId::parse_str failed", uid, e))
        })?;
        let message = to_bson(&MessageModel::new(level, title, body, has_read, extra_info)).map_err(|e| {
            err!("append message failed").trace(ctx!("append message -> parse message to bson: bson::to_bson failed", uid, e))
        })?;
        let filter = doc! {
            "_id": uid,
        };
        let updater = doc! {
            "$push": {
                "messages": message,
            },
            "$set": {
                "update_time": DateTime::now(),
            }
        };
        let _ = self.collection__topic().update_one(filter, updater).await.map_err(|e| {
            err!("append message failed").trace(ctx!("append message: self.collection__topic().update_one failed", uid, e))
        })?;
        Ok(())
    }

    async fn read_message(&self, topic_uid: &str, message_uid: &str) -> YRes<()> {
        let topic_uid = ObjectId::parse_str(topic_uid).map_err(|e| {
            err!("read message failed").trace(ctx!("read message -> parse topic uid to ObjectId: ObjectId::parse_str failed", topic_uid, message_uid, e))
        })?;
        let message_uid = ObjectId::parse_str(message_uid).map_err(|e| {
            err!("read message failed").trace(ctx!("read message -> parse message uid to ObjectId: ObjectId::parse_str failed", topic_uid, message_uid, e))
        })?;
        let filter = doc! {
            "_id": topic_uid,
            "messages._id": message_uid,
        };
        let updater = doc! {
            "$set": {
                "messages.$.has_read": true,
                "update_time": DateTime::now(),
            }
        };
        let _ = self.collection__topic().update_one(filter, updater).await.map_err(|e| {
            err!("read message failed").trace(ctx!("read meesage: self.collection__topic().update_one failed", topic_uid, message_uid, e))
        })?;
        Ok(())
    }

    async fn set_topic_info(&self, uid: &str, extra_info: &HashMap<String, String>) -> YRes<()> {
        let uid = ObjectId::parse_str(uid).map_err(|e| {
            err!("set topic info failed").trace(ctx!("set topic info -> parse uid to ObjectId: ObjectId::parse_str failed", uid, e))
        })?;
        let extra_info = to_bson(&extra_info).map_err(|e| {
            err!("set topic info failed").trace(ctx!("set topic info -> parse extra_info to bson: bson::to_bson failed", uid, extra_info, e))
        })?;
        let filter = doc! {
            "_id": uid,
        };
        let updater = doc! {
            "$set": {
                "extra_info": extra_info,
                "update_time": DateTime::now(),
            }
        };
        let _ = self.collection__topic().update_one(filter, updater).await.map_err(|e| {
            err!("set topic info failed").trace(ctx!("set topic info: self.collection__topic().update_one failed", uid, e))
        })?;
        Ok(())
    }

    async fn pick_topic(&self, uid: &str) -> YRes<Option<Topic>> {
        let uid = ObjectId::parse_str(uid).map_err(|e| {
            err!("pick topic failed").trace(ctx!("pick topic -> parse uid to ObjectId: ObjectId::parse_str failed", uid, e))
        })?;
        let filter = doc! {
            "_id": uid,
            "expire_time": Bson::Null,
        };
        let topic_model = self.collection__topic().find_one(filter).await.map_err(|e| {
            err!("pick topic failed").trace(ctx!("pick topic: self.collection__topic().find_one failed", uid, e))
        })?;
        let topic = match topic_model {
            Some(topic_model) => Some(Topic::try_from(topic_model).trace(
                ctx!("pick topic -> parse TopicModel to Topic: Topic::try_from failed")
            )?),
            None => None,
        };
        Ok(topic)
    }

    async fn pick_topic_by_subject(&self, subject: &str) -> YRes<Option<Topic>> {
        let filter = doc! {
            "subject": subject,
            "expire_time": Bson::Null,
        };
        let topic_model = self.collection__topic().find_one(filter).await.map_err(|e| {
            err!("pick topic by subject failed").trace(ctx!("pick topic by subject: self.collection__topic().find_one failed", subject, e))
        })?;
        let topic = match topic_model {
            Some(topic_model) => Some(Topic::try_from(topic_model).trace(
                ctx!("pick topic by subject -> parse TopicModel to Topic: Topic::try_from failed")
            )?),
            None => None,
        };
        Ok(topic)
    }

    async fn list_topic_by_conditions(&self, uids: Option<&Vec<&str>>, subject: Option<&str>, title: Option<&str>) -> YRes<Vec<Topic>> {
        let mut filter = doc! { "expire_time": Bson::Null };
        if let Some(uids) = uids {
            let uids = uids.iter().fold(Vec::new(), |mut acc, it| {
                match ObjectId::parse_str(it) {
                    Ok(uid) => acc.push(uid),
                    Err(e) => warn!("list topic by conditions - skip a uid: parse to ObjectId failed, uid={it}, err={e}")
                };
                acc
            });
            filter.insert("uid", doc! { "$in": uids });
        }
        if let Some(subject) = subject {
            filter.insert("subject", doc! { "subject": subject });
        }
        if let Some(title) = title {
            filter.insert("title", doc! { "$regex": title, "$options": "i" });
        }
        let sort = doc! { "update_time": -1 , "_id": -1 };
        let mut cursor = self.collection__topic().find(filter).sort(sort).await.map_err(|e| {
            err!("list topic by conditions failed").trace(ctx!("list topic by conditions: self.collection__topic().find failed", e))
        })?.with_type::<TopicModel>();
        let mut result: Vec<Topic> = Vec::new();
        while cursor.advance().await.map_err(|e| {
            err!("list topic by conditions failed").trace(ctx!("list topic by conditions -> get data in cursor: cursor.advance failed", e))
        })? {
            let topic_model = cursor.deserialize_current().map_err(|e| {
                err!("list topic by conditions failed").trace(ctx!("list topic by conditions -> get data in cursor: cursor.deserialize_current failed", e))
            })?;
            let topic_model_uid = topic_model.uid;
            let topic = Topic::try_from(topic_model).trace(
                ctx!("list topic by conditions -> get data in cursor -> parse TopicModel to Topic: Topic::try_from failed", topic_model_uid)
            )?;
            result.push(topic);
        }
        Ok(result)
    }
    
}