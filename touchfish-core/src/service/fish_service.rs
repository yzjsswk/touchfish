use std::collections::HashMap;

use image::GenericImageView;
use yfunc_rust::{prelude::*, Page, Unique, YBytes};

use crate::{DataInfo, Fish, FishStorage, FishType, Statistics};

pub struct FishService<S> where S: FishStorage {
    storage: S,
}

impl<S> FishService<S> where S: FishStorage {

    pub fn new(storage: S) -> FishService<S> {
        FishService { storage }
    }

    pub async fn add_fish(
        &self, fish_type: FishType, fish_data: YBytes, desc: Option<&str>, tags: Option<&Vec<&str>>,
        is_marked: Option<bool>, is_locked: Option<bool>, extra_info: &Option<HashMap<String, String>>,
    ) -> YRes<String> {
        let identity = fish_data.md5();
        let existed_fish = self.storage.pick_fish_by_identity(&identity).await.trace(
            ctx!("add fish -> check data exists: self.storage.pick_fish_by_identity failed", identity)
        )?;
        if let Some(existed_fish) = existed_fish {
            return Err(err!("DATA_EXIST": "data conflicts with the fish with uid {}", existed_fish.uid))
        }
        let desc = desc.unwrap_or("");
        let tags = match tags {
            Some(tags) => tags.unique().into_iter()
                .map(|tag| tag.trim())
                .filter(|tag| tag.len() > 0)
                .collect(),
            None => vec![],
        };
        let is_marked = is_marked.unwrap_or(false);
        let is_locked = is_locked.unwrap_or(false);
        let mut data_info = DataInfo::new();
        data_info.byte_count = Some(fish_data.length());
        let extra_info = extra_info.clone().unwrap_or_default();
        match fish_type {
            FishType::Text => {
                let data_length_limit = 1048576;
                if fish_data.length() > data_length_limit {
                    return Err(err!("DATA_TOO_LONG": "data length is {}, which exceeds the limit of text fish: {}", fish_data.length(), data_length_limit))
                }
                let s = fish_data.to_str().upgrade(
                    err!("DATA_INVALID": "fish type is text, but fish data can not parse to text")
                ).trace(
                    ctx!("add fish -> type=text -> parse fish data to text: fish_data.to_str() failed")
                )?;
                data_info.char_count = Some(s.len());
                data_info.word_count = Some(s.split_whitespace().collect::<Vec<_>>().len());
                data_info.row_count = Some(s.split('\n').collect::<Vec<_>>().len());
            },
            FishType::Image => {
                let data_length_limit = 1048576 * 16;
                if fish_data.length() > data_length_limit {
                    return Err(err!("DATA_TOO_LONG": "data length is {}, which exceeds the limit of image fish: {}", fish_data.length(), data_length_limit))
                }
                let m = image::load_from_memory(&fish_data.clone().into_vec()).map_err(|e|
                    err!("DATA_INVALID": "fish type is image, but fish data can not parse to image").trace(
                        ctx!("add fish -> type=image -> parse fish data to image: image::load_from_memory failed", e)
                    )
                )?;
                let (w, h) = m.dimensions();
                data_info.width = Some(w as usize);
                data_info.height = Some(h as usize);
            },
            _ => {},
        };
        self.storage.add_fish(
            &identity, fish_type, fish_data, &data_info, desc, &tags, is_marked, is_locked, &extra_info,
        ).await.trace(
            ctx!("add fish: self.storage.add_fish failed", fish_type, identity)
        )
    }

    pub async fn expire_fish(&self, uids: &Vec<&str>, skip_if_not_exists: bool, skip_if_locked: bool) -> YRes<()> {
        let mut expire_uids: Vec<&str> = Vec::new();
        for uid in uids {
            let fish = self.storage.pick_fish(uid).await.trace(
                ctx!("expire fish -> check fish if exists & if locked -> get fish by uid: self.storage.pick_fish failed", uid)
            )?;
            match fish {
                None => {
                    if !skip_if_not_exists {
                        return Err(err!("FISH_NOT_EXIST": "fish {} not exist", uid))
                    }
                },
                Some(x) => {
                    if !skip_if_locked && x.is_locked {
                        return Err(err!("FISH_IS_LOCKED": "fish {} is locked", uid))
                    }
                    expire_uids.push(uid);
                }
            }
        }
        self.storage.expire_fish(&expire_uids).await.trace(
            ctx!("expire fish: self.storage.expire_fish failed", expire_uids)
        )
    }

    pub async fn modify_fish(
        &self, uid: &str, desc: Option<&str>, tags: Option<&Vec<&str>>, extra_info: &Option<HashMap<String, String>>,
    ) -> YRes<()>  {
        let fish = self.storage.pick_fish(uid).await.trace(
            ctx!("modify fish -> check fish if exists & if locked -> get fish by uid: self.storage.pick_fish failed", uid)
        )?;
        match fish {
            None => {
                return Err(err!("FISH_NOT_EXIST": "fish {} not exist", uid))
            },
            Some(x) => {
                if x.is_locked {
                    return Err(err!("FISH_IS_LOCKED": "fish {} is locked", uid))
                } else {
                    self.storage.modify_fish(uid, desc, tags, extra_info).await.trace(
                        ctx!("modify fish: self.storage.modify_fish failed", uid)
                    )
                }
            }
        }
    }

    pub async fn mark_fish(&self, uids: &Vec<&str>, skip_if_not_exists: bool, skip_if_locked: bool) -> YRes<()> {
        let mut mark_uids: Vec<&str> = Vec::new();
        for uid in uids {
            let fish = self.storage.pick_fish(uid).await.trace(
                ctx!("mark fish -> check fish if exists & if locked -> get fish by uid: self.storage.pick_fish failed", uid)
            )?;
            match fish {
                None => {
                    if !skip_if_not_exists {
                        return Err(err!("FISH_NOT_EXIST": "fish {} not exist", uid))
                    }
                },
                Some(x) => {
                    if !skip_if_locked && x.is_locked {
                        return Err(err!("FISH_IS_LOCKED": "fish {} is locked", uid))
                    }
                    mark_uids.push(uid);
                }
            }
        }
        self.storage.mark_fish(&mark_uids).await.trace(
            ctx!("mark fish: self.storage.mark_fish failed", mark_uids)
        )
    }

    pub async fn unmark_fish(&self, uids: &Vec<&str>, skip_if_not_exists: bool, skip_if_locked: bool) -> YRes<()> {
        let mut unmark_uids: Vec<&str> = Vec::new();
        for uid in uids {
            let fish = self.storage.pick_fish(uid).await.trace(
                ctx!("unmark fish -> check fish if exists & if locked -> get fish by uid: self.storage.pick_fish failed", uid)
            )?;
            match fish {
                None => {
                    if !skip_if_not_exists {
                        return Err(err!("FISH_NOT_EXIST": "fish {} not exist", uid))
                    }
                },
                Some(x) => {
                    if !skip_if_locked && x.is_locked {
                        return Err(err!("FISH_IS_LOCKED": "fish {} is locked", uid))
                    }
                    unmark_uids.push(uid);
                }
            }
        }
        self.storage.unmark_fish(&unmark_uids).await.trace(
            ctx!("unmark fish: self.storage.unmark_fish failed", unmark_uids)
        )
    }

    pub async fn lock_fish(&self, uids: &Vec<&str>, skip_if_not_exists: bool) -> YRes<()> {
        let mut lock_uids: Vec<&str> = Vec::new();
        for uid in uids {
            let fish = self.storage.pick_fish(uid).await.trace(
                ctx!("lock fish -> check fish if exists & if locked -> get fish by uid: self.storage.pick_fish failed", uid)
            )?;
            match fish {
                None => {
                    if !skip_if_not_exists {
                        return Err(err!("FISH_NOT_EXIST": "fish {} not exist", uid))
                    }
                },
                Some(_) => {
                    lock_uids.push(uid);
                }
            }
        }
        self.storage.lock_fish(&lock_uids).await.trace(
            ctx!("lock fish: self.storage.lock_fish failed", lock_uids)
        )
    }

    pub async fn unlock_fish(&self, uids: &Vec<&str>, skip_if_not_exists: bool) -> YRes<()> {
        let mut unlock_uids: Vec<&str> = Vec::new();
        for uid in uids {
            let fish = self.storage.pick_fish(uid).await.trace(
                ctx!("unlock fish -> check fish if exists & if locked -> get fish by uid: self.storage.pick_fish failed", uid)
            )?;
            match fish {
                None => {
                    if !skip_if_not_exists {
                        return Err(err!("FISH_NOT_EXIST": "fish {} not exist", uid))
                    }
                },
                Some(_) => {
                    unlock_uids.push(uid);
                }
            }
        }
        self.storage.unlock_fish(&unlock_uids).await.trace(
            ctx!("unlock fish: self.storage.unlock_fish failed", unlock_uids)
        )
    }

    pub async fn pin_fish(&self, uids: &Vec<&str>, skip_if_not_exists: bool, skip_if_locked: bool) -> YRes<()> {
        let mut pin_uids: Vec<&str> = Vec::new();
        for uid in uids {
            let fish = self.storage.pick_fish(uid).await.trace(
                ctx!("pin fish -> check fish if exists & if locked -> get fish by uid: self.storage.pick_fish failed", uid)
            )?;
            match fish {
                None => {
                    if !skip_if_not_exists {
                        return Err(err!("FISH_NOT_EXIST": "fish {} not exist", uid))
                    }
                },
                Some(x) => {
                    if !skip_if_locked && x.is_locked {
                        return Err(err!("FISH_IS_LOCKED": "fish {} is locked", uid))
                    }
                    pin_uids.push(uid);
                }
            }
        }
        self.storage.pin_fish(&pin_uids).await.trace(
            ctx!("pin fish: self.storage.pin_fish failed", pin_uids)
        )
    }

    pub async fn pick_fish(&self, uid: &str) -> YRes<Option<Fish>> {
        self.storage.pick_fish(uid).await.upgrade_if("UID_INVALID", err!("FISH_NOT_EXIST": "fish {} not exist", uid)).trace(
            ctx!("pick fish: self.storage.pick_fish failed")
        )
    }

    pub async fn pick_fish_by_identity(&self, identity: &str) -> YRes<Option<Fish>> {
        self.storage.pick_fish_by_identity(identity).await.trace(
            ctx!("pick fish: self.storage.pick_fish_by_identity failed")
        )
    }

    pub async fn search_fish(
        &self, fuzzy: Option<&str>, identitys: Option<&Vec<&str>>, fish_types: Option<&Vec<FishType>>, desc: Option<&str>,
        tags: Option<&Vec<&str>>, is_marked: Option<bool>, is_locked: Option<bool>, 
        create_after: Option<i64>, create_before: Option<i64>, update_after: Option<i64>, update_before: Option<i64>,
        page_num: Option<u64>, page_size: Option<u64>, 
    ) -> YRes<Page<Fish>> {
        self.storage.page_fish_by_conditions(
            fuzzy, identitys, None, fish_types, desc, tags, is_marked, is_locked,
            create_after, create_before, update_after, update_before,
            page_num.unwrap_or(0), page_size.unwrap_or(10),
        ).await.trace(
            ctx!("search fish: self.storage.page_fish failed")
        )
    }

    pub async fn detect_fish(
        &self, fuzzy: Option<&str>, identitys: Option<&Vec<&str>>, fish_types: Option<&Vec<FishType>>,
        desc: Option<&str>, tags: Option<&Vec<&str>>, is_marked: Option<bool>, is_locked: Option<bool>,
        create_after: Option<i64>, create_before: Option<i64>, update_after: Option<i64>, update_before: Option<i64>,
    ) -> YRes<Vec<String>> {
        self.storage.detect_fish_by_conditions(
            fuzzy, identitys, None, fish_types, desc, tags, is_marked, is_locked,
            create_after, create_before, update_after, update_before,
        ).await.trace(
            ctx!("detect fish: self.storage.detect_fish failed")
        )
    }

    pub async fn count_fish(&self) -> YRes<Statistics> {
        self.storage.count_fish().await.trace(
            ctx!("count fish: self.storage.count_fish failed")
        )
    }

}

