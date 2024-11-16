use yfunc_rust::prelude::*;

use crate::{infra::TopicStorage, MessageExtraInfo, MessageLevel, Topic, TopicExtraInfo, TopicType};

pub struct TopicService<S> where S: TopicStorage {
    storage: S,
}

impl<S> TopicService<S> where S: TopicStorage {

    pub fn new(storage: S) -> TopicService<S> {
        TopicService { storage }
    }

    pub async fn create_topic(
        &self, topic_type: TopicType, subject: &str, title: &str, extra_info: &TopicExtraInfo,
    ) -> YRes<String> {
        if self.storage.pick_topic_by_subject(subject).await.trace(
            ctx!("create topic -> check subject if exists: self.storage.pick_topic failed", subject)
        )?.is_some() {
            return Err(err!("TOPIC_EXIST: topic {} exists", subject))
        };
        self.storage.add_topic(topic_type, subject, title, extra_info).await.trace(
            ctx!("create topic: self.storage.add_topic failed")
        )
    }

    pub async fn append_message(
        &self, topic_subject: &str, level: MessageLevel, source: &str,
        title: &str, body: &str, has_read: bool, extra_info: &MessageExtraInfo,
    ) -> YRes<()> {
        let Some(topic) = self.storage.pick_topic_by_subject(&topic_subject).await.trace(
            ctx!("append message -> search topic by subject: self.storage.pick_topic_by_subject failed", topic_subject)
        )? else {
            return Err(err!("TOPIC_NOT_EXIST: topic {} not exists", topic_subject))
        };
        self.storage.append_message(
            &topic.uid, level, source, title, body, has_read, extra_info,
        ).await.trace(
            ctx!("append message: self.storage.add_message failed", topic_subject)
        )
    }

    pub async fn remove_topic(&self, subject: &str) -> YRes<()> {
        let Some(topic) = self.storage.pick_topic_by_subject(subject).await.trace(
            ctx!("remove topic -> check topic if exists: self.storage.pick_topic_by_subject failed", subject)
        )? else {
            return Err(err!("TOPIC_NOT_EXIST: topic {} not exists", subject))
        };
        self.storage.remove_topic(&topic.uid).await.trace(
            ctx!("remove topic: self.storage.remove_topic failed", subject)
        )
    }

    pub async fn list_topic(&self) -> YRes<Vec<Topic>> {
        self.storage.list_topic_by_conditions(None, None, None, None).await.trace(
            ctx!("list topic: self.storage.list_topic_by_conditions failed")
        )
    }

}