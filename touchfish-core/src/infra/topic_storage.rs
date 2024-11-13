use crate::{Message, MessageExtraInfo, MessageLevel, Topic, TopicExtraInfo, TopicType};
use yfunc_rust::prelude::*;

pub trait TopicStorage {

    // insert new topic
    fn add_topic(
        &self, topic_type: TopicType, subject: String, title: String, extra_info: TopicExtraInfo,
    ) -> YRes<Topic>;

    // insert new message
    fn add_message(
        &self, topic_id: i64, level: MessageLevel, source: String,
        title: String, body: String, has_read: bool, extra_info: MessageExtraInfo,
    ) -> YRes<Message>;

    // remove topic by id and messages by topic_id
    fn remove_topic(&self, id: i64) -> YRes<()>;

    // set extra_info of topic by id
    fn set_topic_info(&self, id: i64, extra_info: TopicExtraInfo) -> YRes<()>;

    // set extra_info of message by id
    fn set_message_info(&self, id: i64, extra_info: MessageExtraInfo) -> YRes<()>;

    // select topic by subject
    fn pick_topic(&self, subject: &str) -> YRes<Option<Topic>>;

    // select topic by condition
    fn list_topic(
        &self, ids: Option<Vec<i64>>, topic_types: Option<Vec<TopicType>>, subject: Option<String>, title: Option<String>,
    ) -> YRes<Vec<Topic>>;

    // select message by condition
    fn list_message(
        &self, ids: Option<Vec<i64>>, topic_ids: Option<Vec<i64>>, level: Option<Vec<MessageLevel>>,
        source: Option<Vec<String>>, title: Option<String>, has_read: Option<bool>,
    ) -> YRes<Vec<Message>>;

}