use diesel::prelude::*;
use touchfish_core::{FishType, DataInfo, Fish};
use yfunc_rust::{ctx, err, Trace, Unique, YBytes, YError, YRes, YTime};

use crate::schema;

#[derive(Queryable, Selectable)]
#[diesel(table_name = schema::fish)]
#[diesel(check_for_backend(diesel::sqlite::Sqlite))]
#[derive(Debug, Clone)]
pub struct FishModel {
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
}

impl TryFrom<FishModel> for Fish {

    type Error = YError;

    fn try_from(model: FishModel) -> YRes<Self> {
        let fish_type = FishType::new(&model.fish_type).trace(
            ctx!("try from FishModel to Fish": "parse fish_type failed", model.fish_type, model.id)
        )?;
        let fish_data = YBytes::new(model.fish_data);
        let tags = if model.tags.len() > 0 {
            model.tags.split(',').map(String::from).collect()
        } else {
            vec![]
        };
        let data_info: DataInfo = serde_json::from_str(&model.data_info).map_err(|err|
            err!(ParseError::"try from FishModel to Fish": "parse data_info failed", model.data_info, model.id, err)
        )?;
        let create_time = YTime::from_str(&model.create_time).trace(
            ctx!("try from FishModel to Fish": "parse create_time failed", model.create_time, model.id)
        )?;
        let update_time = YTime::from_str(&model.update_time).trace(
            ctx!("try from FishModel to Fish": "parse update_time failed", model.update_time, model.id)
        )?;
        Ok(Fish {
            identity: model.identity, count: model.count, fish_type, fish_data, data_info,
            desc: model.desc, tags, is_marked: model.is_marked,
            is_locked: model.is_locked, extra_info: model.extra_info, create_time, update_time,
        })
    }

}

#[derive(Insertable)]
#[diesel(table_name = schema::fish)]
#[diesel(check_for_backend(diesel::sqlite::Sqlite))]
#[derive(Debug)]
pub struct FishInserter {
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
}

impl FishInserter {

    pub fn new(
        identity: String, count: i32, fish_type: FishType, fish_data: YBytes, data_info: DataInfo,
        desc: String, tags: Vec<String>, is_marked: bool, is_locked: bool, extra_info: String,
    ) -> YRes<FishInserter> {
        let fish_type = fish_type.to_string();
        let fish_data = fish_data.into_vec();
        let mut tags = tags.unique();
        tags.sort();
        let tags = tags.join(",");
        let data_info = serde_json::to_string(&data_info).map_err(
            |_| err!(ParseError::"build fish inserter", "parse data_info to string failed"),
        )?;
        let create_time = YTime::now().to_str();
        let update_time = YTime::now().to_str();
        Ok(FishInserter {
            identity, count, fish_type, fish_data, data_info,
            desc, tags, is_marked, is_locked, extra_info,
            create_time, update_time,
        })
    }

}

#[derive(AsChangeset)]
#[diesel(table_name = schema::fish)]
#[diesel(check_for_backend(diesel::sqlite::Sqlite))]
#[derive(Debug)]
pub struct FishUpdater {
    pub identity: Option<String>,
    pub count: Option<i32>,
    pub fish_type: Option<String>,
    pub fish_data: Option<Vec<u8>>,
    pub data_info: Option<String>,
    pub desc: Option<String>,
    pub tags: Option<String>,
    pub is_marked: Option<bool>,
    pub is_locked: Option<bool>,
    pub extra_info: Option<String>,
    pub update_time: String,
}

impl FishUpdater {

    pub fn new(
        identity: Option<String>, count: Option<i32>, fish_type: Option<FishType>, data_info: Option<DataInfo>,
        fish_data: Option<YBytes>, desc: Option<String>, tags: Option<Vec<String>>,
        is_marked: Option<bool>, is_locked: Option<bool>, extra_info: Option<String>,
    ) -> YRes<FishUpdater> {
        let fish_type = match fish_type {
            Some(x) => Some(x.to_string()),
            None => None,
        };
        let fish_data = fish_data.map(|x| x.into_vec());
        let tags = match tags {
            Some(x) => {
                let mut x = x.unique();
                x.sort();
                Some(x.join(","))
            }
            None => None,
        };
        let data_info = match data_info {
            Some(x) => Some(serde_json::to_string(&x).map_err(
                |_| err!(ParseError::"build fish updater", "parse data_info to string failed"),
            )?),
            None => None,
        };
        let update_time = YTime::now().to_str();
        Ok(FishUpdater {
            identity, count, fish_type, fish_data, data_info,
            desc, tags, is_marked, is_locked,
            extra_info, update_time,
        })
    }

    pub fn empty() -> FishUpdater {
        let update_time = YTime::now().to_str();
        FishUpdater { 
            identity: None, count: None, fish_type: None, fish_data: None,
            data_info: None, desc: None, tags: None, is_marked: None,
            is_locked: None, extra_info: None, update_time,
        }
    }

}

pub struct FishSelecter {
    pub fuzzy: Option<String>,
    pub identitys: Option<Vec<String>>,
    pub count: Option<i32>,
    pub fish_types: Option<Vec<String>>,
    pub desc: Option<String>,
    pub tags: Option<String>,
    pub is_marked: Option<bool>,
    pub is_locked: Option<bool>,
    pub limit: Option<i32>,
    pub offset: Option<i32>,
}

impl FishSelecter {
    
    pub fn new(
        fuzzy: Option<String>, identitys: Option<Vec<String>>, count: Option<i32>,
        fish_types: Option<Vec<FishType>>, desc: Option<String>, tags: Option<Vec<String>>, 
        is_marked: Option<bool>, is_locked: Option<bool>, page: Option<(i32, i32)>,
    ) -> YRes<FishSelecter> {
        let fuzzy = match fuzzy {
            Some(x) => Some(format!("%{}%", x)),
            None => None,
        };
        let fish_types = match fish_types {
            Some(x) => Some(x.into_iter().map(|x| x.to_string()).collect()),
            None => None,
        };
        let desc = match desc {
            Some(x) => Some(format!("%{}%", x)),
            None => None,
        };
        let tags = match tags {
            Some(x) => {
                if x.is_empty() {
                    Some("".to_string())
                } else {
                    let mut x = x.unique();
                    x.sort();
                    let keyword = x.join("%");
                    Some(format!("%{}%", keyword))
                }
            }
            None => None,
        };
        let (limit, offset) = if let Some((page_num, page_size)) = page {
            if page_num <= 0 {
                return Err(err!(BusinessError::"build fish selecter": "page num must be a positive number", page_num))
            }
            if page_size <= 0 {
                return Err(err!(BusinessError::"build fish selecter": "page size must be a positive number", page_size))
            }
            (Some(page_size), Some((page_num-1) * page_size))
        } else {
            (None, None)
        };
        Ok(FishSelecter {
            fuzzy, identitys, count, fish_types, desc, tags, is_marked, is_locked, limit, offset,
        })
    }

    pub fn empty() -> FishSelecter {
        FishSelecter {
            fuzzy: None, identitys: None, count: None, fish_types: None,
            desc: None, tags: None, is_marked: None, is_locked: None,
            limit: None, offset: None,
        }
    }

    pub fn set_page(&mut self, page: Option<(i32, i32)>) -> YRes<()> {
        let (limit, offset) = if let Some((page_num, page_size)) = page {
            if page_num <= 0 {
                return Err(err!(BusinessError::"set page of fish selecter": "page num must be a positive number", page_num))
            }
            if page_size <= 0 {
                return Err(err!(BusinessError::"set page of fish selecter": "page size must be a positive number", page_size))
            }
            (Some(page_size), Some((page_num-1) * page_size))
        } else {
            (None, None)
        };
        self.limit = limit;
        self.offset = offset;
        Ok(())
    }

}

#[derive(Queryable, Selectable)]
#[diesel(table_name = schema::fish_expired)]
#[diesel(check_for_backend(diesel::sqlite::Sqlite))]
#[derive(Debug, Clone)]
#[allow(dead_code)]
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

