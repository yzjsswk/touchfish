use std::collections::HashMap;

use yfunc_rust::{Page, YBytes, prelude::*};

use crate::{FishService, Fish, FishStorage, FishType, Statistics};

pub struct FishApi<S> where S: FishStorage {
    fish_service: FishService<S>,
}

impl<S> FishApi<S> where S: FishStorage {

    pub fn new(storage: S) -> YRes<FishApi<S>> {
        Ok(FishApi {
            fish_service: FishService::new(storage),
        })
    }

    pub async fn add_fish(
        &self, fish_type: FishType, fish_data: YBytes, desc: Option<&str>,
        tags: Option<&Vec<&str>>, is_marked: Option<bool>, is_locked: Option<bool>, extra_info: &Option<HashMap<String, String>>,
    ) -> YRes<String> {
        self.fish_service.add_fish(fish_type, fish_data, desc, tags, is_marked, is_locked, extra_info).await.trace(
            ctx!("add fish: self.fish_service.add_fish failed")
        )
    }

    pub async fn expire_fish(&self, uids: &Vec<&str>, skip_if_not_exists: bool, skip_if_locked: bool) -> YRes<()> {
        self.fish_service.expire_fish(uids, skip_if_not_exists, skip_if_locked).await.trace(
            ctx!("expire fish: self.fish_service.expire_fish failed")
        )
    }

    pub async fn modify_fish(
        &self, uid: &str, desc: Option<&str>, tags: Option<&Vec<&str>>, extra_info: &Option<HashMap<String, String>>,
    ) -> YRes<()> {
        self.fish_service.modify_fish(uid, desc, tags, extra_info).await.trace(
            ctx!("modify fish: self.fish_service.modify_fish failed")
        )
    }

    pub async fn mark_fish(&self, uids: &Vec<&str>, skip_if_not_exists: bool, skip_if_locked: bool) -> YRes<()> {
        self.fish_service.mark_fish(uids, skip_if_not_exists, skip_if_locked).await.trace(
            ctx!("mark fish: self.fish_service.mark_fish failed")
        )
    }

    pub async fn unmark_fish(&self, uids: &Vec<&str>, skip_if_not_exists: bool, skip_if_locked: bool) -> YRes<()> {
        self.fish_service.unmark_fish(uids, skip_if_not_exists, skip_if_locked).await.trace(
            ctx!("unmark fish: self.fish_service.unmark_fish failed")
        )
    }

    pub async fn lock_fish(&self, uids: &Vec<&str>, skip_if_not_exists: bool) -> YRes<()> {
        self.fish_service.lock_fish(uids, skip_if_not_exists).await.trace(
            ctx!("lock fish: self.fish_service.lock_fish failed")
        )
    }

    pub async fn unlock_fish(&self, uids: &Vec<&str>, skip_if_not_exists: bool) -> YRes<()> {
        self.fish_service.unlock_fish(uids, skip_if_not_exists).await.trace(
            ctx!("unlock fish: self.fish_service.unlock_fish failed")
        )
    }

    pub async fn pin_fish(&self, uids: &Vec<&str>, skip_if_not_exists: bool, skip_if_locked: bool) -> YRes<()> {
        self.fish_service.pin_fish(uids, skip_if_not_exists, skip_if_locked).await.trace(
            ctx!("pin fish: self.fish_service.pin_fish failed")
        )
    }

    pub async fn pick_fish(&self, uid: &str) -> YRes<Option<Fish>> {
        self.fish_service.pick_fish(uid).await.trace(
            ctx!("pick fish: self.fish_service.pick_fish failed")
        )
    }

    pub async fn pick_fish_by_identity(&self, identity: &str) -> YRes<Option<Fish>> {
        self.fish_service.pick_fish_by_identity(identity).await.trace(
            ctx!("pick fish: self.fish_service.pick_fish_by_identity failed")
        )
    }

    pub async fn search_fish(
        &self, fuzzy: Option<&str>, identitys: Option<&Vec<&str>>, fish_types: Option<&Vec<FishType>>, desc: Option<&str>,
        tags: Option<&Vec<&str>>, is_marked: Option<bool>, is_locked: Option<bool>, 
        create_after: Option<i64>, create_before: Option<i64>, update_after: Option<i64>, update_before: Option<i64>,
        page_num: Option<u64>, page_size: Option<u64>, 
    ) -> YRes<Page<Fish>> {
        self.fish_service.search_fish(
            fuzzy, identitys, fish_types, desc, tags, is_marked, is_locked,
            create_after, create_before, update_after, update_before,
            page_num, page_size,
        ).await.trace(
            ctx!("search fish: self.fish_service.search_fish failed")
        )
    }

    pub async fn detect_fish(
        &self, fuzzy: Option<&str>, identitys: Option<&Vec<&str>>, fish_types: Option<&Vec<FishType>>,
        desc: Option<&str>, tags: Option<&Vec<&str>>, is_marked: Option<bool>, is_locked: Option<bool>,
        create_after: Option<i64>, create_before: Option<i64>, update_after: Option<i64>, update_before: Option<i64>,
    ) -> YRes<Vec<String>> {
        self.fish_service.detect_fish(
            fuzzy, identitys, fish_types, desc, tags, is_marked, is_locked,
            create_after, create_before, update_after, update_before,
        ).await.trace(
            ctx!("detect fish: self.fish_service.detect_fish failed")
        )
    }

    pub async fn count_fish(&self) -> YRes<Statistics> {
        self.fish_service.count_fish().await.trace(
            ctx!("count fish: self.fish_service.count_fish failed")
        )
    }

}