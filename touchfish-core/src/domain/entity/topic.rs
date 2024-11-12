use yfunc_rust::{YTime, YUid};

pub struct Topic {
    pub uid: YUid,
    pub topic_type: TopicType,
    pub subject: String,
    pub title: String,
    pub extra_info: TopicExtraInfo,
    pub create_time: YTime,
    pub update_time: YTime,
}

pub enum TopicType {
    Info, Warning, Error,
}

pub struct TopicExtraInfo {

}

pub struct Message {
    pub uid: YUid,
    pub topic_uid: YUid,
    pub level: MessageLevel,
    pub source: String,
    pub title: String,
    pub body: String,
    pub has_read: bool,
    pub extra_info: MessageExtraInfo,
    pub create_time: YTime,
    pub update_time: YTime,
}

pub enum MessageLevel {
    Info, Warning, Error,
}

pub struct MessageExtraInfo {

}


pub struct TopicMessage {
    pub uid: YUid,
    pub level: MessageLevel,
    pub source: String,
    pub title: String,
    pub body: String,
    pub has_read: bool,
    pub extra_info: MessageExtraInfo,
    pub create_time: YTime,
    pub update_time: YTime,
}
