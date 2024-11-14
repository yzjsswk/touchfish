use diesel::prelude::*;
use touchfish_core::{FishType, DataInfo, Fish};
use yfunc_rust::{prelude::*, Unique, YBytes, YTime};

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
        let fish_type = FishType::from_name(&model.fish_type).trace(
            ctx!("try from FishModel to Fish -> parse fish_type: FishType::from_name failed", model.fish_type, model.id)
        )?;
        let fish_data = YBytes::new(model.fish_data);
        let tags = if model.tags.len() > 0 {
            model.tags.split(',').map(String::from).collect()
        } else {
            vec![]
        };
        let data_info = DataInfo::from_json_str(&model.data_info).trace(
            ctx!("try from FishModel to Fish -> parse data_info: DataInfo::from_json_str failed", model.data_info, model.id)
        )?;
        let create_time = YTime::from_str(&model.create_time).trace(
            ctx!("try from FishModel to Fish -> parse create_time: YTime::from_str failed", model.create_time, model.id)
        )?;
        let update_time = YTime::from_str(&model.update_time).trace(
            ctx!("try from FishModel to Fish -> parse update_time: YTime::from_str failed", model.update_time, model.id)
        )?;
        Ok(Fish {
            id: model.id.to_string(), identity: model.identity, count: model.count, fish_type, fish_data, data_info,
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
        let data_info = data_info.to_json_str().trace(
            ctx!("build fish inserter -> parse data_info to json string: data_info.to_json_str() failed")
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
            Some(x) => Some(x.to_json_str().trace(
                ctx!("build fish updater -> parse data_info to json string: data_info.to_json_str() failed")
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
    pub update_before: Option<String>,
    pub limit: Option<i32>,
    pub offset: Option<i32>,
}

impl FishSelecter {
    
    pub fn new(
        fuzzy: Option<String>, identitys: Option<Vec<String>>, count: Option<i32>,
        fish_types: Option<Vec<FishType>>, desc: Option<String>, tags: Option<Vec<String>>, 
        is_marked: Option<bool>, is_locked: Option<bool>, passed_hours: Option<i32>,
        page: Option<(i32, i32)>,
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
        let update_before = match passed_hours {
            Some(x) => Some(YTime::now().duration((x as i64) * -3600).to_str()),
            None => None,
        };
        let (limit, offset) = if let Some((page_num, page_size)) = page {
            if page_num <= 0 {
                return Err(err!("build fish selecter failed").trace(
                    ctx!("build fish selecter -> check page num: page num <= 0", page_num)
                ));
            }
            if page_size <= 0 {
                return Err(err!("build fish selecter failed").trace(
                    ctx!("build fish selecter -> check page size: page size <= 0", page_size)
                ));
            }
            (Some(page_size), Some((page_num-1) * page_size))
        } else {
            (None, None)
        };
        Ok(FishSelecter {
            fuzzy, identitys, count, fish_types, desc, tags, is_marked, is_locked, update_before, limit, offset,
        })
    }

    pub fn empty() -> FishSelecter {
        FishSelecter {
            fuzzy: None, identitys: None, count: None, fish_types: None,
            desc: None, tags: None, is_marked: None, is_locked: None,
            update_before: None, limit: None, offset: None,
        }
    }

    pub fn set_page(&mut self, page: Option<(i32, i32)>) -> YRes<()> {
        let (limit, offset) = if let Some((page_num, page_size)) = page {
            if page_num <= 0 {
                return Err(err!("set page of fish selecter failed").trace(
                    ctx!("set page of fish selecter -> check page num: page num <= 0", page_num)
                ));
            }
            if page_size <= 0 {
                return Err(err!("set page of fish selecter failed").trace(
                    ctx!("set page of fish selecter -> check page size: page size <= 0", page_size)
                ));
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
