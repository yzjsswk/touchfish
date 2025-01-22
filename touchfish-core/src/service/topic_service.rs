use std::collections::HashMap;

use yfunc_rust::prelude::*;

use crate::{infra::TopicStorage, MessageLevel, Topic};

pub struct TopicService<S> where S: TopicStorage {
    storage: S,
}

impl<S> TopicService<S> where S: TopicStorage {

    pub fn new(storage: S) -> TopicService<S> {
        TopicService { storage }
    }

    pub async fn create_topic(
        &self, subject: &str, source: &str, title: &str, extra_info: &Option<HashMap<String, String>>,
    ) -> YRes<String> {
        if self.storage.pick_topic_by_subject(subject).await.trace(
            ctx!("create topic -> check subject if exists: self.storage.pick_topic failed", subject)
        )?.is_some() {
            return Err(err!("TOPIC_EXIST": "topic {} exists", subject))
        };
        let extra_info = extra_info.clone().unwrap_or_default();
        self.storage.add_topic(subject, source, title, &extra_info).await.trace(
            ctx!("create topic: self.storage.add_topic failed")
        )
    }

    pub async fn append_message(
        &self, subject: &str, level: MessageLevel, title: &str, body: &str, has_read: bool, extra_info: &Option<HashMap<String, String>>,
    ) -> YRes<()> {
        let Some(topic) = self.storage.pick_topic_by_subject(&subject).await.trace(
            ctx!("append message -> search topic by subject: self.storage.pick_topic_by_subject failed", subject)
        )? else {
            return Err(err!("TOPIC_NOT_EXIST": "topic {} not exists", subject))
        };
        let extra_info = extra_info.clone().unwrap_or_default();
        self.storage.append_message(
            &topic.uid, level, title, body, has_read, &extra_info,
        ).await.trace(
            ctx!("append message: self.storage.add_message failed", subject)
        )
    }

    pub async fn read_message(&self, topic_uid: &str, message_uid: &str) -> YRes<()> {
        let Some(topic) = self.storage.pick_topic(&topic_uid).await.trace(
            ctx!("read message -> search topic by uid: self.storage.pick_topic failed", topic_uid, message_uid)
        )? else {
            return Err(err!("TOPIC_NOT_EXIST": "topic {} not exists", topic_uid))
        };
        for message in topic.messages {
            if message.uid == message_uid {
                self.storage.read_message(topic_uid, message_uid).await.trace(
                    ctx!("read message: self.storage.read_message failed", topic_uid, message_uid)
                )?;
                return Ok(())
            }
        }
        return Err(err!("MESSAGE_NOT_EXIST": "message {} not exists", message_uid))
    }

    pub async fn remove_topic(&self, subject: &str) -> YRes<()> {
        let Some(topic) = self.storage.pick_topic_by_subject(subject).await.trace(
            ctx!("remove topic -> check topic if exists: self.storage.pick_topic_by_subject failed", subject)
        )? else {
            return Err(err!("TOPIC_NOT_EXIST": "topic {} not exists", subject))
        };
        self.storage.remove_topic(&topic.uid).await.trace(
            ctx!("remove topic: self.storage.remove_topic failed", subject)
        )
    }

    pub async fn modify_topic(&self, subject: &str, extra_info: &HashMap<String, String>) -> YRes<()> {
        let Some(topic) = self.storage.pick_topic_by_subject(subject).await.trace(
            ctx!("modify topic -> check topic if exists: self.storage.pick_topic_by_subject failed", subject)
        )? else {
            return Err(err!("TOPIC_NOT_EXIST": "topic {} not exists", subject))
        };
        self.storage.set_topic_info(&topic.uid, extra_info).await.trace(
            ctx!("modify topic: self.storage.set_topic_info failed", subject)
        )
    }

    pub async fn list_topic(&self) -> YRes<Vec<Topic>> {
        self.storage.list_topic_by_conditions(None, None, None).await.trace(
            ctx!("list topic: self.storage.list_topic_by_conditions failed")
        )
    }

}