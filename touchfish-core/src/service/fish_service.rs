use image::GenericImageView;
use yfunc_rust::{prelude::*, Page, Unique, YBytes};

use crate::{DataInfo, Fish, FishStorage, FishType, Statistics};

const FISH_DATA_LEN_LIMIT: usize = 10485760;

pub struct FishService<S> where S: FishStorage {
    storage: S,
}

impl<S> FishService<S> where S: FishStorage {

    pub fn new(storage: S) -> FishService<S> {
        FishService { storage }
    }

    pub fn add_fish(
        &self, fish_type: FishType, fish_data: YBytes, desc: Option<String>, tags: Option<Vec<String>>,
        is_marked: Option<bool>, is_locked: Option<bool>, extra_info: Option<String>,
    ) -> YRes<Fish> {
        if fish_data.length() > FISH_DATA_LEN_LIMIT {
            return Err(err!(BusinessError::"add fish -> check data length": "fish data too long", fish_data.length(), FISH_DATA_LEN_LIMIT))
        }
        let identity = fish_data.md5();
        if let Some(existed_fish) = self.storage.pick_fish(&identity)? {
            if fish_type != existed_fish.fish_type {
                return Err(err!(BusinessError::"add fish -> fish data exists -> check data consistent": "fish type not consistent", identity))
            }
            if let Some(desc) = &desc {
                if *desc != existed_fish.desc {
                    return Err(err!(BusinessError::"add fish -> fish data exists -> check data consistent": "desc not consistent", identity))
                }
            }
            if let Some(tags) = &tags {
                let mut tags = tags.unique();
                tags.sort();
                if tags != existed_fish.tags {
                    return Err(err!(BusinessError::"add fish -> fish data exists -> check data consistent": "tags not consistent", identity))
                }
            }
            if let Some(is_marked) = is_marked {
                if is_marked != existed_fish.is_marked {
                    return Err(err!(BusinessError::"add fish -> fish data exists -> check data consistent": "is_marked not consistent", identity))
                }
            }
            if let Some(is_locked) = is_locked {
                if is_locked != existed_fish.is_locked {
                    return Err(err!(BusinessError::"add fis -> fish data exists -> check data consistenth": "is_locked not consistent", identity))
                }
            }
            if let Some(extra_info) = &extra_info {
                if *extra_info != existed_fish.extra_info {
                    return Err(err!(BusinessError::"add fish -> fish data exists -> check data consistent": "extra_info not consistent", identity))
                }
            }
            self.storage.increase_count(vec![&identity])?;
            let new_fish = self.storage.pick_fish(&identity)?.ok_or(
                err!(ConsistentError::"add fish -> consistent data exists -> increase count -> query new fish to return": "new fish not found", identity)
            )?;
            return Ok(new_fish)
        }
        let desc = desc.unwrap_or("".to_string());
        let extra_info = extra_info.unwrap_or("".to_string());
        let tags = match tags {
            Some(x) => {
                let mut t = x.unique();
                t.sort();
                t
            },
            None => vec![],
        };
        let is_marked = is_marked.unwrap_or(false);
        let is_locked = is_locked.unwrap_or(false);
        let mut data_info = DataInfo::new();
        data_info.byte_count = Some(fish_data.length());
        match fish_type {
            FishType::Text => {
                let s= fish_data.to_str().trace(
                    ctx!("add text fish -> parse fish data to string": "parse failed")
                )?;
                data_info.char_count = Some(s.len());
                data_info.word_count = Some(s.split_whitespace().collect::<Vec<_>>().len());
                data_info.row_count = Some(s.split('\n').collect::<Vec<_>>().len());
            },
            FishType::Image => {
                let m = image::load_from_memory(&fish_data.clone().into_vec()).map_err(|e|
                    err!(ParseError::"add image fish -> parse fish data to image": "parse failed", e)
                )?;
                let (w, h) = m.dimensions();
                data_info.width = Some(w as usize);
                data_info.height = Some(h as usize);
            },
            _ => {},
        };
        self.storage.add_fish(
            identity, 1, fish_type, fish_data, data_info, desc, tags, is_marked, is_locked, extra_info,
        )
    }

    pub fn expire_fish(&self, identitys: Vec<&str>, skip_if_not_exists: bool, skip_if_locked: bool) -> YRes<()> {
        let mut expire_identitys: Vec<&str> = Vec::new();
        for identity in identitys {
            let fish = self.storage.pick_fish(identity)?;
            match fish {
                None => {
                    if !skip_if_not_exists {
                        return Err(err!(BusinessError::"expire fish -> check fish exists": "fish not exist", identity))
                    }
                },
                Some(x) => {
                    if !skip_if_locked && x.is_locked {
                        return Err(err!(BusinessError::"expire fish -> check fish is not locked": "fish is locked", identity))
                    }
                    expire_identitys.push(identity);
                }
            }
        }
        self.storage.expire_fish(expire_identitys)
    }

    pub fn modify_fish(
        &self, identity: &str, desc: Option<String>, tags: Option<Vec<String>>, extra_info: Option<String>,
    ) -> YRes<()>  {
        let fish = self.storage.pick_fish(identity)?;
        match fish {
            None => {
                return Err(err!(BusinessError::"modify fish -> check fish exists": "fish not exist", identity))
            },
            Some(x) => {
                if x.is_locked {
                    return Err(err!(BusinessError::"modify fish -> check fish is not locked": "fish is locked", identity))
                } else {
                    self.storage.modify_fish(identity, desc, tags, extra_info)
                }
            }
        }
    }

    pub fn mark_fish(&self, identitys: Vec<&str>, skip_if_not_exists: bool, skip_if_locked: bool) -> YRes<()> {
        let mut mark_identitys: Vec<&str> = Vec::new();
        for identity in identitys {
            let fish = self.storage.pick_fish(identity)?;
            match fish {
                None => {
                    if !skip_if_not_exists {
                        return Err(err!(BusinessError::"mark fish -> check fish exists": "fish not exist", identity))
                    }
                },
                Some(x) => {
                    if !skip_if_locked && x.is_locked {
                        return Err(err!(BusinessError::"mark fish -> check fish is not locked": "fish is locked", identity))
                    }
                    mark_identitys.push(identity);
                }
            }
        }
        self.storage.mark_fish(mark_identitys)
    }

    pub fn unmark_fish(&self, identitys: Vec<&str>, skip_if_not_exists: bool, skip_if_locked: bool) -> YRes<()> {
        let mut unmark_identitys: Vec<&str> = Vec::new();
        for identity in identitys {
            let fish = self.storage.pick_fish(identity)?;
            match fish {
                None => {
                    if !skip_if_not_exists {
                        return Err(err!(BusinessError::"unmark fish -> check fish exists": "fish not exist", identity))
                    }
                },
                Some(x) => {
                    if !skip_if_locked && x.is_locked {
                        return Err(err!(BusinessError::"unmark fish -> check fish is not locked": "fish is locked", identity))
                    }
                    unmark_identitys.push(identity);
                }
            }
        }
        self.storage.unmark_fish(unmark_identitys)
    }

    pub fn lock_fish(&self, identitys: Vec<&str>, skip_if_not_exists: bool) -> YRes<()> {
        let mut lock_identitys: Vec<&str> = Vec::new();
        for identity in identitys {
            let fish = self.storage.pick_fish(identity)?;
            match fish {
                None => {
                    if !skip_if_not_exists {
                        return Err(err!(BusinessError::"lock fish -> check fish exists": "fish not exist", identity))
                    }
                },
                Some(_) => {
                    lock_identitys.push(identity);
                }
            }
        }
        self.storage.lock_fish(lock_identitys)
    }

    pub fn unlock_fish(&self, identitys: Vec<&str>, skip_if_not_exists: bool) -> YRes<()> {
        let mut unlock_identitys: Vec<&str> = Vec::new();
        for identity in identitys {
            let fish = self.storage.pick_fish(identity)?;
            match fish {
                None => {
                    if !skip_if_not_exists {
                        return Err(err!(BusinessError::"unlock fish -> check fish exists": "fish not exist", identity))
                    }
                },
                Some(_) => {
                    unlock_identitys.push(identity);
                }
            }
        }
        self.storage.unlock_fish(unlock_identitys)
    }

    pub fn pin_fish(&self, identitys: Vec<&str>, skip_if_not_exists: bool, skip_if_locked: bool) -> YRes<()> {
        let mut pin_identitys: Vec<&str> = Vec::new();
        for identity in identitys {
            let fish = self.storage.pick_fish(identity)?;
            match fish {
                None => {
                    if !skip_if_not_exists {
                        return Err(err!(BusinessError::"pin fish -> check fish exists": "fish not exist", identity))
                    }
                },
                Some(x) => {
                    if !skip_if_locked && x.is_locked {
                        return Err(err!(BusinessError::"pin fish -> check fish is not locked": "fish is locked", identity))
                    }
                    pin_identitys.push(identity);
                }
            }
        }
        self.storage.pin_fish(pin_identitys)
    }

    pub fn pick_fish(&self, identity: &str) -> YRes<Option<Fish>> {
        self.storage.pick_fish(identity)
    }

    pub fn search_fish(
        &self, fuzzy: Option<String>, identitys: Option<Vec<String>>, 
        fish_types: Option<Vec<FishType>>, desc: Option<String>,
        tags: Option<Vec<String>>, is_marked: Option<bool>, is_locked: Option<bool>, 
        passed_hours: Option<i32>, page_num: Option<i32>, page_size: Option<i32>, 
    ) -> YRes<Page<Fish>> {
        self.storage.page_fish(
            fuzzy, identitys, None, fish_types, desc, tags, is_marked, is_locked, passed_hours,
            page_num.unwrap_or(1), page_size.unwrap_or(10),
        )
    }

    pub fn detect_fish(
        &self, fuzzy: Option<String>, identitys: Option<Vec<String>>, 
        fish_types: Option<Vec<FishType>>, desc: Option<String>,
        tags: Option<Vec<String>>, is_marked: Option<bool>, is_locked: Option<bool>,
        passed_hours: Option<i32>, 
    ) -> YRes<Vec<String>> {
        self.storage.detect_fish(
            fuzzy, identitys, None, fish_types, desc, tags, is_marked, is_locked, passed_hours,
        )
    }

    pub fn count_fish(&self) -> YRes<Statistics> {
        self.storage.count_fish()
    }

}

