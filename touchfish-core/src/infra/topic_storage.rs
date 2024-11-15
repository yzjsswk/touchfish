use crate::{MessageExtraInfo, MessageLevel, Topic, TopicExtraInfo, TopicType};
use yfunc_rust::prelude::*;

pub trait TopicStorage {

    async fn add_topic(
        &self, topic_type: TopicType, subject: &str, title: &str, extra_info: &TopicExtraInfo,
    ) -> YRes<String>;

    async fn remove_topic(&self, uid: &str) -> YRes<()>;

    async fn append_message(
        &self, uid: &str, level: MessageLevel, source: &str,
        title: &str, body: &str, has_read: bool, extra_info: &MessageExtraInfo,
    ) -> YRes<()>;

    async fn set_topic_info(&self, uid: &str, extra_info: &TopicExtraInfo) -> YRes<()>;

    async fn set_message_info(&self, uid: &str, extra_info: &MessageExtraInfo) -> YRes<()>;

    async fn pick_topic(&self, subject: &str) -> YRes<Option<Topic>>;

    async fn list_topic(
        &self, uids: Option<&Vec<&str>>, topic_types: Option<&Vec<TopicType>>, subject: Option<&str>, title: Option<&str>,
    ) -> YRes<Vec<Topic>>;

}
