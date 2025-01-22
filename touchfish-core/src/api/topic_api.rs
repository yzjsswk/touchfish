use std::collections::HashMap;

use crate::{infra::TopicStorage, service::TopicService, MessageLevel, Topic};
use yfunc_rust::prelude::*;

pub struct TopicApi<S> where S: TopicStorage {
    topic_service: TopicService<S>,
}

impl<S> TopicApi<S> where S: TopicStorage {

    pub fn new(storage: S) -> YRes<TopicApi<S>> {
        Ok(TopicApi {
            topic_service: TopicService::new(storage),
        })
    }

    pub async fn create_topic(
        &self, subject: &str, source: &str, title: &str, extra_info: &Option<HashMap<String, String>>,
    ) -> YRes<String> {
        self.topic_service.create_topic(subject, source, title, extra_info).await.trace(
            ctx!("create topic: self.topic_service.create_topic failed")
        )
    }

    pub async fn send_message(
        &self, subject: &str, level: MessageLevel, title: &str, body: &str,
        has_read: bool, extra_info: &Option<HashMap<String, String>>,
    ) -> YRes<()> {
        self.topic_service.append_message(subject, level, title, body, has_read, extra_info).await.trace(
            ctx!("append message: self.topic_service.append_message failed")
        )
    }

    pub async fn read_message(&self, topic_uid: &str, message_uid: &str) -> YRes<()> {
        self.topic_service.read_message(topic_uid, message_uid).await.trace(
            ctx!("read message: self.topic_service.read_message failed")
        )
    }

    pub async fn remove_topic(&self, subject: &str) -> YRes<()> {
        self.topic_service.remove_topic(subject).await.trace(
            ctx!("remove topic: self.topic_service.remove_topic failed")
        )
    }

    pub async fn modify_topic(&self, subject: &str, extra_info: &HashMap<String, String>) -> YRes<()> {
        self.topic_service.modify_topic(subject, extra_info).await.trace(
            ctx!("modify topic: self.topic_service.modify_topic failed")
        )
    }

    pub async fn list_topic(&self) -> YRes<Vec<Topic>> {
        self.topic_service.list_topic().await.trace(
            ctx!("list topic: self.topic_service.list_topic failed")
        )
    }
    
}