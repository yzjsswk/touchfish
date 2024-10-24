use yfunc_rust::{Page, YBytes, YRes};

use crate::{Fish, FishService, FishStorage, FishType, Statistics};

pub struct TouchFishCore<S> where S: FishStorage {
    fish_service: FishService<S>,
}

impl<S> TouchFishCore<S> where S: FishStorage {

    pub fn new(storage: S) -> YRes<TouchFishCore<S>> {
        Ok(TouchFishCore {
            fish_service: FishService::new(storage),
        })
    }

    pub fn add_fish(
        &self, fish_type: FishType, fish_data: YBytes, desc: Option<String>,
        tags: Option<Vec<String>>, is_marked: Option<bool>, is_locked: Option<bool>, extra_info: Option<String>,
    ) -> YRes<Fish> {
        self.fish_service.add_fish(fish_type, fish_data, desc, tags, is_marked, is_locked, extra_info)
    }

    pub fn expire_fish(&self, identitys: Vec<&str>, skip_if_not_exists: bool, skip_if_locked: bool) -> YRes<()> {
        self.fish_service.expire_fish(identitys, skip_if_not_exists, skip_if_locked)
    }

    pub fn modify_fish(
        &self, identity: &str, desc: Option<String>, tags: Option<Vec<String>>, extra_info: Option<String>,
    ) -> YRes<()> {
        self.fish_service.modify_fish(identity, desc, tags, extra_info)
    }

    pub fn mark_fish(&self, identitys: Vec<&str>, skip_if_not_exists: bool, skip_if_locked: bool) -> YRes<()> {
        self.fish_service.mark_fish(identitys, skip_if_not_exists, skip_if_locked)
    }

    pub fn unmark_fish(&self, identitys: Vec<&str>, skip_if_not_exists: bool, skip_if_locked: bool) -> YRes<()> {
        self.fish_service.unmark_fish(identitys, skip_if_not_exists, skip_if_locked)
    }

    pub fn lock_fish(&self, identitys: Vec<&str>, skip_if_not_exists: bool) -> YRes<()> {
        self.fish_service.lock_fish(identitys, skip_if_not_exists)
    }

    pub fn unlock_fish(&self, identitys: Vec<&str>, skip_if_not_exists: bool) -> YRes<()> {
        self.fish_service.unlock_fish(identitys, skip_if_not_exists)
    }

    pub fn pin_fish(&self, identitys: Vec<&str>, skip_if_not_exists: bool, skip_if_locked: bool) -> YRes<()> {
        self.fish_service.pin_fish(identitys, skip_if_not_exists, skip_if_locked)
    }

    pub fn pick_fish(&self, identity: &str) -> YRes<Option<Fish>> {
        self.fish_service.pick_fish(identity)
    }

    pub fn search_fish(
        &self, fuzzy: Option<String>, identitys: Option<Vec<String>>, 
        fish_types: Option<Vec<FishType>>, desc: Option<String>,
        tags: Option<Vec<String>>, is_marked: Option<bool>, is_locked: Option<bool>, 
        page_num: Option<i32>, page_size: Option<i32>,
    ) -> YRes<Page<Fish>> {
        self.fish_service.search_fish(fuzzy, identitys, fish_types, desc, tags, is_marked, is_locked, page_num, page_size)
    }

    pub fn detect_fish(
        &self, fuzzy: Option<String>, identitys: Option<Vec<String>>, 
        fish_types: Option<Vec<FishType>>, desc: Option<String>,
        tags: Option<Vec<String>>, is_marked: Option<bool>, is_locked: Option<bool>,
    ) -> YRes<Vec<String>> {
        self.fish_service.detect_fish(fuzzy, identitys, fish_types, desc, tags, is_marked, is_locked)
    }

    pub fn count_fish(&self) -> YRes<Statistics> {
        self.fish_service.count_fish()
    }

}