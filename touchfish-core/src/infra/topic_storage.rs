use std::future::Future;

use crate::{MessageExtraInfo, MessageLevel, Topic, TopicExtraInfo, TopicType};
use yfunc_rust::prelude::*;

pub trait TopicStorage {

    fn add_topic(
        &self, topic_type: TopicType, subject: &str, title: &str, extra_info: &TopicExtraInfo,
    ) -> impl Future<Output = YRes<String>> + Send;

    fn remove_topic(&self, uid: &str) -> impl Future<Output = YRes<()>> + Send;

    fn append_message(
        &self, uid: &str, level: MessageLevel, source: &str,
        title: &str, body: &str, has_read: bool, extra_info: &MessageExtraInfo,
    ) -> impl Future<Output = YRes<()>> + Send;

    fn read_message(&self, topic_uid: &str, message_uid: &str) -> impl Future<Output = YRes<()>> + Send;

    fn set_topic_info(&self, uid: &str, extra_info: &TopicExtraInfo) -> impl Future<Output = YRes<()>> + Send;

    fn pick_topic(&self, uid: &str) -> impl Future<Output = YRes<Option<Topic>>> + Send;
    
    fn pick_topic_by_subject(&self, subject: &str) -> impl Future<Output = YRes<Option<Topic>>> + Send;

    fn list_topic_by_conditions(
        &self, uids: Option<&Vec<&str>>, topic_types: Option<&Vec<TopicType>>, subject: Option<&str>, title: Option<&str>,
    ) -> impl Future<Output = YRes<Vec<Topic>>> + Send;

}
