use std::collections::HashMap;

use yfunc_rust::prelude::*;

use crate::{infra::TopicStorage, Message, MessageExtraInfo, MessageLevel, Topic, TopicExtraInfo, TopicType, TopicWithMessage};

pub struct TopicService<S> where S: TopicStorage {
    storage: S,
}

impl<S> TopicService<S> where S: TopicStorage {

    pub fn new(storage: S) -> TopicService<S> {
        TopicService { storage }
    }

    pub fn create_topic(
        &self, topic_type: TopicType, subject: String, title: String, extra_info: TopicExtraInfo
    ) -> YRes<Topic> {
        if self.storage.pick_topic(&subject).trace(
            ctx!("create topic -> check subject if exists: self.storage.pick_topic failed", subject)
        )?.is_some() {
            return Err(err!("TOPIC_EXIST: topic {} exists", subject))
        };
        self.storage.add_topic(topic_type, subject, title, extra_info)
    }

    pub fn append_message(
        &self, topic_subject: String, level: MessageLevel, source: String,
        title: String, body: String, has_read: bool, extra_info: MessageExtraInfo,
    ) -> YRes<Message> {
        let Some(topic) = self.storage.pick_topic(&topic_subject).trace(
            ctx!("append message -> search topic by subject: self.storage.pick_topic failed", topic_subject)
        )? else {
            return Err(err!("TOPIC_NOT_EXIST: topic {} not exists", topic_subject))
        };
        self.storage.add_message(
            topic.id, level, source, title, body, has_read, extra_info,
        ).trace(
            ctx!("append message: self.storage.add_message failed", topic_subject)
        )
    }

    pub fn remove_topic(&self, subject: String) -> YRes<()> {
        let Some(topic) = self.storage.pick_topic(&subject).trace(
            ctx!("remove topic -> check topic if exists: self.storage.pick_topic failed", subject)
        )? else {
            return Err(err!("TOPIC_NOT_EXIST: topic {} not exists", subject))
        };
        self.storage.remove_topic(topic.id).trace(
            ctx!("remove topic: self.storage.remove_topic failed", subject)
        )
    }

    pub fn list_topic(&self) -> YRes<Vec<TopicWithMessage>> {
        let topics = self.storage.list_topic(None, None, None, None).trace(
            ctx!("list topic -> query all topics: self.storage.list_topic failed")
        )?;
        let messages = self.storage.list_message(None, None, None, None, None, None).trace(
            ctx!("list topic -> query all messages: self.storage.list_message failed")
        )?;
        let mut message_group_by_topic = messages.into_iter().fold(HashMap::new(), |mut acc, it| {
            acc.entry(it.topic_id).or_insert(Vec::new()).push(it);
            acc
        });
        let ret = topics.into_iter().fold::<Vec<_>, _>(Vec::new(), |mut acc, it| {
            let messages = message_group_by_topic.remove(&it.id).unwrap_or(Vec::new());
            acc.push(TopicWithMessage::new(it, messages));
            acc
        });
        Ok(ret)
    }

}