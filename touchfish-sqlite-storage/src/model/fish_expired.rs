use diesel::prelude::*;
use yfunc_rust::{prelude::*, YTime};

use crate::schema;

use super::FishModel;

#[derive(Queryable, Selectable)]
#[diesel(table_name = schema::fish_expired)]
#[diesel(check_for_backend(diesel::sqlite::Sqlite))]
#[derive(Debug, Clone)]
pub struct FishExpiredModel {
    pub id: i32,
    pub identity: String,
    pub count: i32,
    pub fish_type: String,
    pub fish_data: Vec<u8>,
    pub data_info: String,
    pub desc: String,
    pub tags: String,
    pub is_marked: bool,
    pub is_locked: bool,
    pub extra_info: String,
    pub create_time: String,
    pub update_time: String,
    pub expire_time: String,
}

#[derive(Insertable)]
#[diesel(table_name = schema::fish_expired)]
#[diesel(check_for_backend(diesel::sqlite::Sqlite))]
#[derive(Debug)]
pub struct FishExpiredInserter {
    pub id: i32,
    pub identity: String,
    pub count: i32,
    pub fish_type: String,
    pub fish_data: Vec<u8>,
    pub data_info: String,
    pub desc: String,
    pub tags: String,
    pub is_marked: bool,
    pub is_locked: bool,
    pub extra_info: String,
    pub create_time: String,
    pub update_time: String,
    pub expire_time: String,
}

impl FishExpiredInserter {

    pub fn new(model: FishModel) -> YRes<FishExpiredInserter> {
        let expire_time = YTime::now().to_str();
        Ok(FishExpiredInserter {
            id: model.id, identity: model.identity, count: model.count,
            fish_type: model.fish_type, fish_data: model.fish_data, data_info: model.data_info,
            desc: model.desc, tags: model.tags, is_marked: model.is_marked,
            is_locked: model.is_locked, extra_info: model.extra_info,
            create_time: model.create_time, update_time: model.update_time,
            expire_time,
        })
    }

}

