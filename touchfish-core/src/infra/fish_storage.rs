use yfunc_rust::{Page, YBytes, prelude::*};

use crate::{DataInfo, Fish, FishType, Statistics};

pub trait FishStorage {

    async fn add_fish(
        &self, identity: &str, count: i32, fish_type: FishType, fish_data: YBytes, data_info: &DataInfo,
        desc: &str, tags: &Vec<&str>, is_marked: bool, is_locked: bool, extra_info: &str,
    ) -> YRes<String>;

    async fn expire_fish(&self, uids: &Vec<&str>) -> YRes<()>;

    async fn modify_fish(&self, uid: &str, desc: Option<&str>, tags: Option<&Vec<&str>>, extra_info: Option<&str>) -> YRes<()>;

    async fn mark_fish(&self, uids: &Vec<&str>) -> YRes<()>;

    async fn unmark_fish(&self, uids: &Vec<&str>) -> YRes<()>;

    async fn lock_fish(&self, uids: &Vec<&str>) -> YRes<()>;

    async fn unlock_fish(&self, uids: &Vec<&str>) -> YRes<()>;

    async fn pin_fish(&self, uids: &Vec<&str>) -> YRes<()>;

    async fn increase_count(&self, uids: &Vec<&str>) -> YRes<()>;

    async fn pick_fish(&self, uid: &str) -> YRes<Option<Fish>>;

    async fn pick_fish_by_identity(&self, identity: &str) -> YRes<Option<Fish>>;

    async fn page_fish_by_conditions(
        &self, fuzzy: Option<&str>, identitys: Option<&Vec<&str>>, count: Option<i32>,
        fish_types: Option<&Vec<FishType>>, desc: Option<&str>, tags: Option<&Vec<&str>>, 
        is_marked: Option<bool>, is_locked: Option<bool>, passed_hours: Option<i32>, 
        page_num: u64, page_size: u64,
    ) -> YRes<Page<Fish>>;

    async fn detect_fish_by_conditions(
        &self, fuzzy: Option<&str>, identitys: Option<&Vec<&str>>, count: Option<i32>,
        fish_types: Option<&Vec<FishType>>, desc: Option<&str>, tags: Option<&Vec<&str>>, 
        is_marked: Option<bool>, is_locked: Option<bool>, passed_hours: Option<i32>, 
    ) -> YRes<Vec<String>>;

    async fn count_fish(&self) -> YRes<Statistics>;

}