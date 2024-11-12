use touchfish_core::TopicStorage;

use crate::SqliteStorage;

impl TopicStorage for SqliteStorage {

    fn add_topic(
        &self, uid: yfunc_rust::YUid, topic_type: touchfish_core::TopicType, subject: String, title: String, extra_info: touchfish_core::TopicExtraInfo,
    ) -> yfunc_rust::YRes<touchfish_core::Topic> {
        todo!()
    }

    fn add_message(
        &self, uid: yfunc_rust::YUid, topic_uid: yfunc_rust::YUid, level: touchfish_core::MessageLevel, source: String,
        title: String, body: String, has_read: bool, extra_info: touchfish_core::MessageExtraInfo,
    ) -> yfunc_rust::YRes<touchfish_core::Message> {
        todo!()
    }

    fn remove_topic(&self, uid: yfunc_rust::YUid) -> yfunc_rust::YRes<()> {
        todo!()
    }

    fn set_topic_info(&self, uid: yfunc_rust::YUid, extra_info: touchfish_core::TopicExtraInfo) -> yfunc_rust::YRes<()> {
        todo!()
    }

    fn set_message_info(&self, uid: yfunc_rust::YUid, extra_info: touchfish_core::MessageExtraInfo) -> yfunc_rust::YRes<()> {
        todo!()
    }

    fn pick_topic(&self, subject: &str) -> yfunc_rust::YRes<Option<touchfish_core::Topic>> {
        todo!()
    }

    fn list_topic(
        &self, uids: Option<Vec<yfunc_rust::YUid>>, topic_types: Option<Vec<touchfish_core::TopicType>>, subject: Option<String>, title: Option<String>,
    ) -> yfunc_rust::YRes<Vec<touchfish_core::Topic>> {
        todo!()
    }

    fn list_message(
        &self, uids: Option<Vec<yfunc_rust::YUid>>, topic_uids: Option<Vec<yfunc_rust::YUid>>, level: Option<Vec<touchfish_core::MessageLevel>>,
        source: Option<Vec<String>>, title: Option<String>, has_read: Option<bool>,
    ) -> yfunc_rust::YRes<Vec<touchfish_core::Message>> {
        todo!()
    }
    
}