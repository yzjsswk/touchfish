use crate::{infra::TopicStorage, service::TopicService, MessageExtraInfo, MessageLevel, Topic, TopicExtraInfo, TopicType};
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
        &self, topic_type: TopicType, subject: &str, source: &str, title: &str, extra_info: &TopicExtraInfo
    ) -> YRes<String> {
        self.topic_service.create_topic(topic_type, subject, source, title, extra_info).await.trace(
            ctx!("create topic: self.topic_service.create_topic failed")
        )
    }

    pub async fn append_message(
        &self, topic_subject: &str, level: MessageLevel, title: &str, body: &str,
        has_read: bool, extra_info: &MessageExtraInfo,
    ) -> YRes<()> {
        self.topic_service.append_message(topic_subject, level, title, body, has_read, extra_info).await.trace(
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

    pub async fn list_topic(&self) -> YRes<Vec<Topic>> {
        self.topic_service.list_topic().await.trace(
            ctx!("list topic: self.topic_service.list_topic failed")
        )
    }
    
}