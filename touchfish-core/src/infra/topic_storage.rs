use crate::{Message, MessageExtraInfo, MessageLevel, Topic, TopicExtraInfo, TopicType};
use yfunc_rust::{prelude::*, YUid};

pub trait TopicStorage {

    // insert new topic
    fn add_topic(
        &self, uid: YUid, topic_type: TopicType, subject: String, title: String, extra_info: TopicExtraInfo,
    ) -> YRes<Topic>;

    // insert new message
    fn add_message(
        &self, uid: YUid, topic_uid: YUid, level: MessageLevel, source: String,
        title: String, body: String, has_read: bool, extra_info: MessageExtraInfo,
    ) -> YRes<Message>;

    // remove topic by uid and messages by topic_uid
    fn remove_topic(&self, uid: YUid) -> YRes<()>;

    // set extra_info of topic by uid
    fn set_topic_info(&self, uid: YUid, extra_info: TopicExtraInfo) -> YRes<()>;

    // set extra_info of message by uid
    fn set_message_info(&self, uid: YUid, extra_info: MessageExtraInfo) -> YRes<()>;

    // select topic by subject
    fn pick_topic(&self, subject: &str) -> YRes<Option<Topic>>;

    // select topic by condition
    fn list_topic(
        &self, uids: Option<Vec<YUid>>, topic_types: Option<Vec<TopicType>>, subject: Option<String>, title: Option<String>,
    ) -> YRes<Vec<Topic>>;

    // select message by condition
    fn list_message(
        &self, uids: Option<Vec<YUid>>, topic_uids: Option<Vec<YUid>>, level: Option<Vec<MessageLevel>>,
        source: Option<Vec<String>>, title: Option<String>, has_read: Option<bool>,
    ) -> YRes<Vec<Message>>;

}