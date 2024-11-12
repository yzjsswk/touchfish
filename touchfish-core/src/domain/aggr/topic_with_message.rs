use yfunc_rust::{YTime, YUid};

use crate::{Message, Topic, TopicExtraInfo, TopicMessage, TopicType};

pub struct TopicWithMessage {
    pub topic_uid: YUid,
    pub topic_type: TopicType,
    pub subject: String,
    pub title: String,
    pub messages: Vec<TopicMessage>,
    pub extra_info: TopicExtraInfo,
    pub create_time: YTime,
    pub update_time: YTime,
}

impl TopicWithMessage {

    pub fn new(topic: Topic, messages: Vec<Message>) -> TopicWithMessage {
        let messages = messages.into_iter().fold(Vec::new(), |mut acc, it| {
            if it.topic_uid != topic.uid {
                return acc;
            }
            acc.push(
                TopicMessage {
                    uid: it.uid,
                    level: it.level,
                    source: it.source,
                    title: it.title,
                    body: it.body,
                    has_read: it.has_read,
                    extra_info: it.extra_info,
                    create_time: it.create_time,
                    update_time: it.update_time,
                }
            );
            acc
        });
        TopicWithMessage {
            topic_uid: topic.uid,
            topic_type: topic.topic_type,
            subject: topic.subject,
            title: topic.title,
            messages,
            extra_info: topic.extra_info,
            create_time: topic.create_time,
            update_time: topic.update_time,
        }
    }

}
