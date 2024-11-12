use std::collections::HashMap;

use diesel::prelude::*;
use touchfish_core::{DataInfo, Fish, FishStorage, FishType, Statistics};
use yfunc_rust::{prelude::*, Page, YBytes};

use crate::model::{FishExpiredInserter, FishInserter, FishSelecter, FishUpdater};
use crate::SqliteStorage;

impl FishStorage for SqliteStorage {

    fn add_fish(
        &self, identity: String, count: i32, fish_type: FishType, fish_data: YBytes, data_info: DataInfo,
        desc: String, tags: Vec<String>, is_marked: bool, is_locked: bool, extra_info: String,
    ) -> YRes<Fish> {
        let mut conn = self.get_conn().trace(
            ctx!("add fish -> get connection: self.get_conn() failed")
        )?;
        let inserter = FishInserter::new(
            identity, count, fish_type, fish_data, data_info, desc, tags, is_marked, is_locked, extra_info
        ).trace(
            ctx!("add fish -> build fish inserter: FishInserter::new failed")
        )?;
        let fish = self.fish__insert(&mut conn, &inserter).trace(
            ctx!("add fish: self.fish__insert failed")
        )?;
        let fish = Fish::try_from(fish).trace(
            ctx!("add fish -> parse FishModel to Fish to return: Fish::try_from failed")
        )?;
        Ok(fish)
    }

    fn expire_fish(&self, identitys: Vec<&str>) -> YRes<()> {
        let mut conn = self.get_conn().trace(
            ctx!("expire fish -> get connection: self.get_conn() failed")
        )?;
        let selecter = FishSelecter::new(
            None, Some(identitys.iter().map(|x| x.to_string()).collect()),
            None, None, None, None, None, None, None, None,
        ).trace(
            ctx!("expire fish -> query fish need to be expired -> build fish selecter: FishSelecter::new failed", identitys)
        )?;
        let to_expire_fish = self.fish__select(&mut conn, &selecter).trace(
            ctx!("expire fish -> query fish need to be expired: self.fish__select failed", identitys)
        )?;
        if to_expire_fish.is_empty() {
            return Ok(())
        }
        let to_expire_fish_ids = to_expire_fish.iter().map(|x| x.id).collect::<Vec<i32>>();
        let expired_fish_inserters = to_expire_fish.into_iter().try_fold::<_, _, YRes<Vec<_>>>(Vec::new(), |mut acc, it| {
            let fish_identity = it.identity.clone();
            let inserter = FishExpiredInserter::new(it).trace(
                ctx!("expire fish -> build fish_expired inserter: FishExpiredInserter::new failed", fish_identity)
            )?;
            acc.push(inserter);
            Ok(acc)
        })?;
        conn.transaction::<_, YError, _>(|conn| {
            let cnt = self.fish__delete_batch(conn, &to_expire_fish_ids).trace(
                ctx!("expire fish -> batch delete fish in transaction: self.fish__delete_batch failed")
            )?;
            if cnt != to_expire_fish_ids.len() {
                return Err(err!("expire fish -> batch delete fish in transaction: return of self.fish__delete_batch != to_expire_fish_ids.len()"))
            }
            for inserter in expired_fish_inserters {
                self.fish_expired__insert(conn, &inserter).trace(
                    ctx!("expire fish -> insert expired fish into table fish_expired: self.fish_expired__insert failed", inserter.id)
                )?;
            }
            Ok(())
        })
    }

    fn modify_fish(
        &self, identity: &str, desc: Option<String>, tags: Option<Vec<String>>, extra_info: Option<String>,
    ) -> YRes<()> {
        let mut conn = self.get_conn().trace(
            ctx!("modify fish -> get connection: self.get_conn() failed")
        )?;
        let updater = FishUpdater::new(
            None, None, None, None, None,
            desc, tags, None, None, extra_info,
        ).trace(
            ctx!("modify fish -> build fish updater: FishUpdater::new failed")
        )?;
        self.fish__update(&mut conn, identity, &updater).trace(
            ctx!("modify fish: self.fish__update failed", identity)
        )?;
        Ok(())
    }

    fn mark_fish(&self, identitys: Vec<&str>) -> YRes<()> {
        let mut conn = self.get_conn().trace(
            ctx!("mark fish -> get connection: self.get_conn() failed")
        )?;
        let updater = FishUpdater::new(
            None, None, None, None, None,
            None, None, Some(true), None, None,
        ).trace(
            ctx!("mark fish -> build fish updater: FishUpdater::new failed")
        )?;
        self.fish__update_batch(&mut conn, &identitys, &updater).trace(
            ctx!("mark fish: self.fish__update_batch failed", identitys)
        )?;
        Ok(())
    }
    
    fn unmark_fish(&self, identitys: Vec<&str>) -> YRes<()> {
        let mut conn = self.get_conn().trace(
            ctx!("unmark fish -> get connection: self.get_conn() failed")
        )?;
        let updater = FishUpdater::new(
            None, None, None, None, None,
            None, None, Some(false), None, None,
        ).trace(
            ctx!("unmark fish -> build fish updater: FishUpdater::new failed")
        )?;
        self.fish__update_batch(&mut conn, &identitys, &updater).trace(
            ctx!("unmark fish: self.fish__update_batch failed", identitys)
        )?;
        Ok(())
    }
    
    fn lock_fish(&self, identitys: Vec<&str>) -> YRes<()> {
        let mut conn = self.get_conn().trace(
            ctx!("lock fish -> get connection: self.get_conn() failed")
        )?;
        let updater = FishUpdater::new(
            None, None, None, None, None,
            None, None, None, Some(true), None,
        ).trace(
            ctx!("lock fish -> build fish updater: FishUpdater::new failed")
        )?;
        self.fish__update_batch(&mut conn, &identitys, &updater).trace(
            ctx!("lock fish: self.fish__update_batch failed", identitys)
        )?;
        Ok(())
    }
    
    fn unlock_fish(&self, identitys: Vec<&str>) -> YRes<()> {
        let mut conn = self.get_conn().trace(
            ctx!("unlock fish -> get connection: self.get_conn() failed")
        )?;
        let updater = FishUpdater::new(
            None, None, None, None, None,
            None, None, None, Some(false), None,
        ).trace(
            ctx!("unlock fish -> build fish updater: FishUpdater::new failed")
        )?;
        self.fish__update_batch(&mut conn, &identitys, &updater).trace(
            ctx!("unlock fish: self.fish__update_batch failed", identitys)
        )?;
        Ok(())
    }
    
    fn pin_fish(&self, identitys: Vec<&str>) -> YRes<()> {
        let mut conn = self.get_conn().trace(
            ctx!("pin fish -> get connection: self.get_conn() failed")
        )?;
        self.fish__update_batch(&mut conn, &identitys, &FishUpdater::empty()).trace(
            ctx!("pin fish: self.fish__update_batch failed", identitys)
        )?;
        Ok(())
    }

    fn increase_count(&self, identitys: Vec<&str>) -> YRes<()> {
        let mut conn = self.get_conn().trace(
            ctx!("increase fish count -> get connection: self.get_conn() failed")
        )?;
        conn.transaction::<_, YError, _>(|conn| {
            self.fish__inc_cnt_batch(conn, &identitys).trace(
                ctx!("increase fish count -> batch increase fish count in transaction: self.fish__inc_cnt_batch failed", identitys)
            )?;
            self.fish__update_batch(conn, &identitys, &FishUpdater::empty()).trace(
                ctx!("increase fish count -> batch update update_time in transaction: self.fish__update_batch failed", identitys)
            )?;
            Ok(())
        })
    }

    fn decrease_count(&self, identitys: Vec<&str>) -> YRes<()> {
        let mut conn = self.get_conn().trace(
            ctx!("decrease fish count -> get connection: self.get_conn() failed")
        )?;
        conn.transaction::<_, YError, _>(|conn| {
            self.fish__dec_cnt_batch(conn, &identitys).trace(
                ctx!("decrease fish count -> batch decrease fish count in transaction: self.fish__dec_cnt_batch failed", identitys)
            )?;
            self.fish__update_batch(conn, &identitys, &FishUpdater::empty()).trace(
                ctx!("decrease fish count -> batch update update_time in transaction: self.fish__update_batch failed", identitys)
            )?;
            Ok(())
        })
    }
    
    fn pick_fish(&self, identity: &str) -> YRes<Option<Fish>> {
        let mut conn = self.get_conn().trace(
            ctx!("pick fish -> get connection: self.get_conn() failed")
        )?;
        let fish_list = self.fish__pick(&mut conn, identity).trace(
            ctx!("pick fish: self.fish__pick failed", identity)
        )?;
        if fish_list.is_empty() {
            return Ok(None);
        }
        if fish_list.len() > 1 {
            return Err(err!("found more than one fish with identity {}", identity).trace(
                ctx!("pick fish -> query by identity: got more than one fish", identity)
            ));
        }
        let fish = fish_list.into_iter().next().unwrap();
        let fish = Fish::try_from(fish).trace(
            ctx!("pick fish -> parse FishModel to Fish to return: Fish::try_from failed", identity)
        )?;
        Ok(Some(fish))
    }

    fn page_fish(
        &self, fuzzy: Option<String>, identitys: Option<Vec<String>>, count: Option<i32>,
        fish_types: Option<Vec<touchfish_core::FishType>>, desc: Option<String>,
        tags: Option<Vec<String>>, is_marked: Option<bool>, is_locked: Option<bool>,
        passed_hours: Option<i32>, page_num: i32, page_size: i32,
    ) -> YRes<Page<Fish>> {
        let mut conn = self.get_conn().trace(
            ctx!("page fish -> get connection: self.get_conn() failed")
        )?;
        let mut selecter = FishSelecter::new(
            fuzzy, identitys, count, fish_types, desc, tags, is_marked, is_locked, passed_hours, Some((page_num, page_size),)
        ).trace(
            ctx!("page fish -> build fish selecter: FishSelecter::new failed")
        )?;
        let fish_list = self.fish__select(&mut conn, &selecter).trace(
            ctx!("page fish -> select fish page: self.fish__select failed")
        )?;
        selecter.set_page(None).trace(
            ctx!("page fish -> set selecter.page = None to get total_count by condition: selecter.set_page failed")
        )?;
        let total_count = self.fish__count(&mut conn, &selecter).trace(
            ctx!("page fish -> get total_count by condition: self.fish__count failed")
        )?;
        let fish_list = fish_list.into_iter().try_fold::<_, _, YRes<_>>(Vec::new(), |mut acc, it| {
            let fish_identity = it.identity.clone();
            let fish = Fish::try_from(it).trace(
                ctx!("page fish -> parse FishModel to Fish to return: Fish::try_from failed", fish_identity)
            )?;
            acc.push(fish);
            Ok(acc)
        })?;
        Ok(Page { total_count, page_num, page_size, data: fish_list })
    }
    
    fn detect_fish(
        &self, fuzzy: Option<String>, identitys: Option<Vec<String>>, count: Option<i32>,
        fish_types: Option<Vec<FishType>>, desc: Option<String>, tags: Option<Vec<String>>, 
        is_marked: Option<bool>, is_locked: Option<bool>, passed_hours: Option<i32>, 
    ) -> YRes<Vec<String>> {
        let mut conn = self.get_conn().trace(
            ctx!("detect fish -> get connection: self.get_conn() failed")
        )?;
        let selecter = FishSelecter::new(
            fuzzy, identitys, count, fish_types, desc, tags, is_marked, is_locked, passed_hours, None,
        ).trace(
            ctx!("detect fish -> build fish selecter: FishSelecter::new failed")
        )?;
        self.fish__select_identity(&mut conn, &selecter).trace(
            ctx!("detect fish: self.fish__select_identity failed")
        )
    }
    
    fn count_fish(&self) -> YRes<Statistics> {
        let mut conn = self.get_conn().trace(
            ctx!("count fish -> get connection: self.get_conn() failed")
        )?;
        let mut selecter = FishSelecter::empty();
        let count__active = self.fish__count(& mut conn, &selecter).trace(
            ctx!("count fish -> count active fish: self.fish__count failed")
        )? as i32;
        let count__expired = self.expired_fish__count(& mut conn, &selecter).trace(
            ctx!("count fish -> count expired fish: self.expired_fish__count failed")
        )? as i32;
        let count__by_type = self.fish__count_by_type(&mut conn).trace(
            ctx!("count fish -> count fish by type: self.fish__count_by_type failed")
        )?;
        let count__by_type = count__by_type.into_iter().fold(HashMap::new(), |mut acc, it| {
            let Ok(fish_type) = FishType::from_name(&it.fish_type) else {
                warn!("count fish -> count fish by type - skip a type: not a valid fish type, CountByType={:?}", it);
                return acc
            };
            acc.insert(fish_type, it.count);
            acc
        });
        let count__by_tag = self.fish__count_by_tag(&mut conn).trace(
            ctx!("count fish -> count fish by tag: self.fish__count_by_tag failed")
        )?;
        let count__by_tag: HashMap<String, i32> = count__by_tag.into_iter().map(|x| (x.tag, x.count)).collect();
        selecter.is_marked = Some(true);
        let count__marked = self.fish__count(& mut conn, &selecter).trace(
            ctx!("count fish -> count marked fish: self.fish__count failed")
        )? as i32;
        selecter.is_marked = Some(false);
        let count__unmarked = self.fish__count(& mut conn, &selecter).trace(
            ctx!("count fish -> count unmarked fish: self.fish__count failed")
        )? as i32;
        selecter.is_marked = None;
        selecter.is_locked = Some(true);
        let count__locked = self.fish__count(& mut conn, &selecter).trace(
            ctx!("count fish -> count locked fish: self.fish__count failed")
        )? as i32;
        selecter.is_locked = Some(false);
        let count__unlocked = self.fish__count(& mut conn, &selecter).trace(
            ctx!("count fish -> count unlocked fish: self.fish__count failed")
        )? as i32;
        let count_fish_by_day = self.fish__count_by_day(&mut conn).trace(
            ctx!("count fish -> count fish by day: self.fish__count_by_day failed")
        )?;
        let count_expired_fish_by_day = self.fish_expired__count_by_day(&mut conn).trace(
            ctx!("count fish -> count expired fish by day: self.fish_expired__count_by_day failed")
        )?;
        let mut count__by_day: HashMap<String, i32> = HashMap::new();
        for cnt in count_fish_by_day {
            *count__by_day.entry(cnt.day).or_insert(0) += cnt.count;
        }
        for cnt in count_expired_fish_by_day {
            *count__by_day.entry(cnt.day).or_insert(0) += cnt.count;
        }
        Ok(Statistics {
            count__active, count__expired, count__by_type, count__by_tag,
            count__marked, count__unmarked, count__locked, count__unlocked,
            count__by_day,
        })
    }

}

