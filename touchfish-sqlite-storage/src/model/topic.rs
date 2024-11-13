use diesel::prelude::*;
use touchfish_core::{Topic, TopicExtraInfo, TopicType};
use yfunc_rust::{prelude::*, YTime};

use crate::schema;

#[derive(Queryable, Selectable)]
#[diesel(table_name = schema::topic)]
#[diesel(check_for_backend(diesel::sqlite::Sqlite))]
#[derive(Debug, Clone)]
pub struct TopicModel {
    pub id: i32,
    pub topic_type: String,
    pub subject: String,
    pub title: String,
    pub extra_info: String,
    pub create_time: String,
    pub update_time: String,
}

impl TryFrom<TopicModel> for Topic {

    type Error = YError;

    fn try_from(model: TopicModel) -> YRes<Self> {
        let topic_type = TopicType::from_name(&model.topic_type).trace(
            ctx!("try from TopicModel to Topic -> parse topic_type: TopicType::from_name failed", model.topic_type, model.id)
        )?;
        let extra_info = TopicExtraInfo::from_json_str(&model.extra_info).trace(
            ctx!("try from TopicModel to Topic -> parse data_info: TopicExtraInfo::from_json_str failed", model.extra_info, model.id)
        )?;
        let create_time = YTime::from_str(&model.create_time).trace(
            ctx!("try from TopicModel to Topic -> parse create_time: YTime::from_str failed", model.create_time, model.id)
        )?;
        let update_time = YTime::from_str(&model.update_time).trace(
            ctx!("try from TopicModel to Topic -> parse update_time: YTime::from_str failed", model.update_time, model.id)
        )?;
        Ok(Topic {
            id: model.id as i64, topic_type, subject: model.subject, title: model.title,
            extra_info, create_time, update_time,
        })
    }

}

#[derive(Insertable)]
#[diesel(table_name = schema::topic)]
#[diesel(check_for_backend(diesel::sqlite::Sqlite))]
#[derive(Debug)]
pub struct TopicInserter {
    pub topic_type: String,
    pub subject: String,
    pub title: String,
    pub extra_info: String,
    pub create_time: String,
    pub update_time: String,
}

impl TopicInserter {

    pub fn new(
        topic_type: TopicType, subject: String, title: String, extra_info: TopicExtraInfo,
    ) -> YRes<TopicInserter> {
        let topic_type = topic_type.to_string();
        let extra_info = extra_info.to_json_str().trace(
            ctx!("build topic inserter -> parse extra_info to json string: extra_info.to_json_str() failed")
        )?;
        let create_time = YTime::now().to_str();
        let update_time = YTime::now().to_str();
        Ok(TopicInserter {
            topic_type, subject, title, extra_info, create_time, update_time,
        })
    }

}

#[derive(AsChangeset)]
#[diesel(table_name = schema::topic)]
#[diesel(check_for_backend(diesel::sqlite::Sqlite))]
#[derive(Debug)]
pub struct TopicUpdater {
    pub topic_type: Option<String>,
    pub subject: Option<String>,
    pub title: Option<String>,
    pub extra_info: Option<String>,
    pub update_time: String,
}

impl TopicUpdater {

    pub fn new(
        topic_type: Option<TopicType>, subject: Option<String>, title: Option<String>, extra_info: Option<TopicExtraInfo>,
    ) -> YRes<TopicUpdater> {
        let topic_type = match topic_type {
            Some(x) => Some(x.to_string()),
            None => None,
        };
        let extra_info = match extra_info {
            Some(x) => Some(x.to_json_str().trace(
                ctx!("build topic updater -> parse extra_info to json string: extra_info.to_json_str() failed")
            )?),
            None => None,
        };
        let update_time = YTime::now().to_str();
        Ok(TopicUpdater {
            topic_type, subject, title, extra_info, update_time,
        })
    }

    pub fn empty() -> TopicUpdater {
        let update_time = YTime::now().to_str();
        TopicUpdater { 
            topic_type: None, subject: None, title: None, extra_info: None, update_time,
        }
    }

}
