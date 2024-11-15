use strum_macros::{Display, EnumString};
use yfunc_rust::{YTime, prelude::*};
use serde::{Deserialize, Serialize};

#[yfunc]
#[derive(Serialize, Debug)]
pub struct Topic {
    pub uid: String,
    pub topic_type: TopicType,
    pub subject: String,
    pub title: String,
    pub messages: Vec<Message>,
    pub extra_info: TopicExtraInfo,
    pub create_time: YTime,
    pub update_time: YTime,
}

#[yfunc]
#[derive(Serialize, Deserialize, Debug, EnumString, Display)]
pub enum TopicType {
    Info, Warning, Error,
}

#[yfunc]
#[derive(Serialize, Deserialize, Debug)]
pub struct TopicExtraInfo {

}

#[yfunc]
#[derive(Serialize, Debug)]
pub struct Message {
    pub uid: String,
    pub level: MessageLevel,
    pub source: String,
    pub title: String,
    pub body: String,
    pub has_read: bool,
    pub extra_info: MessageExtraInfo,
    pub create_time: YTime,
    pub update_time: YTime,
}

#[yfunc]
#[derive(Serialize, Debug)]
pub enum MessageLevel {
    Info, Warning, Error,
}

#[yfunc]
#[derive(Serialize, Debug)]
pub struct MessageExtraInfo {

}
