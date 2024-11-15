use crate::{infra::TopicStorage, service::TopicService, Message, MessageExtraInfo, MessageLevel, Topic, TopicExtraInfo, TopicType};
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

    // pub fn create_topic(
    //     &self, topic_type: TopicType, subject: String, title: String, extra_info: TopicExtraInfo
    // ) -> YRes<Topic> {
    //     self.topic_service.create_topic(topic_type, subject, title, extra_info)
    // }

    // pub fn append_message(
    //     &self, topic_subject: String, level: MessageLevel, source: String,
    //     title: String, body: String, has_read: bool, extra_info: MessageExtraInfo,
    // ) -> YRes<Message> {
    //     self.topic_service.append_message(topic_subject, level, source, title, body, has_read, extra_info)
    // }

    // pub fn remove_topic(&self, subject: String) -> YRes<()> {
    //     self.topic_service.remove_topic(subject)
    // }

    // pub fn list_topic(&self) -> YRes<Vec<TopicWithMessage>> {
    //     self.topic_service.list_topic()
    // }
    
}