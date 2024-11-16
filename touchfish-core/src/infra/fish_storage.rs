use std::future::Future;

use yfunc_rust::{Page, YBytes, prelude::*};

use crate::{DataInfo, Fish, FishType, Statistics};

pub trait FishStorage {

    fn add_fish(
        &self, identity: &str, count: i32, fish_type: FishType, fish_data: YBytes, data_info: &DataInfo,
        desc: &str, tags: &Vec<&str>, is_marked: bool, is_locked: bool, extra_info: &str,
    ) -> impl Future<Output = YRes<String>> + Send;

    fn expire_fish(&self, uids: &Vec<&str>) -> impl Future<Output = YRes<()>> + Send;

    fn modify_fish(
        &self, uid: &str, desc: Option<&str>, tags: Option<&Vec<&str>>, extra_info: Option<&str>,
    ) -> impl Future<Output = YRes<()>> + Send;

    fn mark_fish(&self, uids: &Vec<&str>) -> impl Future<Output = YRes<()>> + Send;

    fn unmark_fish(&self, uids: &Vec<&str>) -> impl Future<Output = YRes<()>> + Send;

    fn lock_fish(&self, uids: &Vec<&str>) -> impl Future<Output = YRes<()>> + Send;

    fn unlock_fish(&self, uids: &Vec<&str>) -> impl Future<Output = YRes<()>> + Send;

    fn pin_fish(&self, uids: &Vec<&str>) -> impl Future<Output = YRes<()>> + Send;

    fn increase_count(&self, uids: &Vec<&str>) -> impl Future<Output = YRes<()>> + Send;

    fn pick_fish(&self, uid: &str) -> impl Future<Output = YRes<Option<Fish>>> + Send;

    fn pick_fish_by_identity(&self, identity: &str) -> impl Future<Output = YRes<Option<Fish>>> + Send;

    fn page_fish_by_conditions(
        &self, fuzzy: Option<&str>, identitys: Option<&Vec<&str>>, count: Option<i32>,
        fish_types: Option<&Vec<FishType>>, desc: Option<&str>, tags: Option<&Vec<&str>>, 
        is_marked: Option<bool>, is_locked: Option<bool>, passed_hours: Option<i32>, 
        page_num: u64, page_size: u64,
    ) -> impl Future<Output = YRes<Page<Fish>>> + Send;

    fn detect_fish_by_conditions(
        &self, fuzzy: Option<&str>, identitys: Option<&Vec<&str>>, count: Option<i32>,
        fish_types: Option<&Vec<FishType>>, desc: Option<&str>, tags: Option<&Vec<&str>>, 
        is_marked: Option<bool>, is_locked: Option<bool>, passed_hours: Option<i32>, 
    ) -> impl Future<Output = YRes<Vec<String>>> + Send;

    fn count_fish(&self) -> impl Future<Output = YRes<Statistics>> + Send;

}