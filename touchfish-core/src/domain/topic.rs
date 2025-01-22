use std::collections::HashMap;

use yfunc_rust::{YTime, prelude::*};
use serde::{Deserialize, Serialize};

#[yfunc]
#[derive(Serialize, Debug)]
pub struct Topic {
    pub uid: String,
    pub subject: String,
    pub source: String,
    pub title: String,
    pub messages: Vec<Message>,
    pub extra_info: HashMap<String, String>,
    pub create_time: YTime,
    pub update_time: YTime,
}

#[yfunc]
#[derive(Serialize, Debug)]
pub struct Message {
    pub uid: String,
    pub level: MessageLevel,
    pub title: String,
    pub body: String,
    pub has_read: bool,
    pub extra_info: HashMap<String, String>,
    pub create_time: YTime,
    pub update_time: YTime,
}

#[yfunc]
#[derive(Serialize, Deserialize, Debug, Clone, Copy)]
pub enum MessageLevel {
    Info, Warning, Error,
}
