use yfunc_rust::{Page, YBytes, YRes};

use crate::{DataInfo, Fish, FishType, Statistics};

pub trait FishStorage {

    // insert new fish record
    fn add_fish(
        &self, identity: String, count: i32, fish_type: FishType, fish_data: YBytes, data_info: DataInfo,
        desc: String, tags: Vec<String>, is_marked: bool, is_locked: bool, extra_info: String,
    ) -> YRes<Fish>;

    // delete fish and copy to fish_expired
    // skip if identity not exists
    fn expire_fish(&self, identitys: Vec<&str>) -> YRes<()>;

    // modify fish record by identity
    // skip if identity not exists
    fn modify_fish(
        &self, identity: &str, desc: Option<String>, tags: Option<Vec<String>>, extra_info: Option<String>,
    ) -> YRes<()>;

    // set is_marked = true
    // skip if identity not exists
    fn mark_fish(&self, identitys: Vec<&str>) -> YRes<()>;

    // set is_marked = false
    // skip if identity not exists
    fn unmark_fish(&self, identitys: Vec<&str>) -> YRes<()>;

    // set is_locked = true
    // skip if identity not exists
    fn lock_fish(&self, identitys: Vec<&str>) -> YRes<()>;

    // set is_locked = false
    // skip if identity not exists
    fn unlock_fish(&self, identitys: Vec<&str>) -> YRes<()>;

    // set update_time to now
    // skip if identity not exists
    fn pin_fish(&self, identitys: Vec<&str>) -> YRes<()>;

    // set count = count + 1
    // skip if identity not exists
    fn increase_count(&self, identity: Vec<&str>) -> YRes<()>;

    // set count = count - 1
    // skip if identity not exists
    fn decrease_count(&self, identity: Vec<&str>) -> YRes<()>;

    // select fish by identity
    fn pick_fish(&self, identity: &str) -> YRes<Option<Fish>>;

    // select fish by condition with page
    fn page_fish(
        &self, fuzzy: Option<String>, identitys: Option<Vec<String>>, count: Option<i32>,
        fish_types: Option<Vec<FishType>>, desc: Option<String>, tags: Option<Vec<String>>, 
        is_marked: Option<bool>, is_locked: Option<bool>, passed_hours: Option<i32>, 
        page_num: i32, page_size: i32,
    ) -> YRes<Page<Fish>>;

    // select all fish.identity by condition
    fn detect_fish(
        &self, fuzzy: Option<String>, identitys: Option<Vec<String>>, count: Option<i32>,
        fish_types: Option<Vec<FishType>>, desc: Option<String>, tags: Option<Vec<String>>, 
        is_marked: Option<bool>, is_locked: Option<bool>, passed_hours: Option<i32>, 
    ) -> YRes<Vec<String>>;

    // select some fish statistics
    fn count_fish(&self) -> YRes<Statistics>;

}