use std::collections::HashMap;

use mongodb::bson::{doc, oid::ObjectId, Bson, DateTime};
use touchfish_core::{DataInfo, Fish, FishStorage, FishType, Statistics};
use yfunc_rust::{prelude::*, Page, YBytes, YTime};

use crate::model::{FishModel, StatsModel, UidModel};

use super::MongoStorage;

impl FishStorage for MongoStorage {

    async fn add_fish(
        &self, identity: &str, count: i32, fish_type: FishType, fish_data: YBytes, data_info: &DataInfo,
        desc: &str, tags: &Vec<&str>, is_marked: bool, is_locked: bool, extra_info: &str,
    ) -> YRes<String> {
        let model = FishModel::new(
            identity, count, fish_type, fish_data, data_info, desc, tags, is_marked, is_locked, extra_info,
        )?;
        let result = self.collection__fish().insert_one(model).await.map_err(|e| {
            err!("add fish failed").trace(ctx!("add fish: self.collection__fish().insert_one() failed", e))
        })?;
        let Some(inserted_uid) = result.inserted_id.as_object_id() else {
            return Err(err!("add fish may success but failed to get insert_uid").trace(
                ctx!("add fish -> parse inserted_uid to ObjectId: result.inserted_id.as_object_id failed", result.inserted_id)
            ))
        };
        Ok(inserted_uid.to_hex())
    }

    async fn expire_fish(&self, uids: &Vec<&str>) -> YRes<()> {
        let uids = uids.iter().fold(Vec::new(), |mut acc, it| {
            match ObjectId::parse_str(it) {
                Ok(uid) => acc.push(uid),
                Err(e) => warn!("expire fish by uids - skip a uid: parse to ObjectId failed, uid={it}, err={e}")
            };
            acc
        });
        let filter = doc! {
            "_id": { "$in":  &uids}
        };
        let updater = doc! {
            "$set": {
                "expire_time": DateTime::now(),
            }
        };
        let _ = self.collection__fish().update_many(filter, updater).await.map_err(|e| {
            err!("expire fish failed").trace(ctx!("expire fish: self.collection__fish().update_many failed", uids, e))
        })?;
        Ok(())
    }

    async fn modify_fish(
        &self, uid: &str, desc: Option<&str>, tags: Option<&Vec<&str>>, extra_info: Option<&str>,
    ) -> YRes<()> {
        let uid = ObjectId::parse_str(uid).map_err(|e| {
            err!("modify fish failed").trace(ctx!("modify fish -> parse uid to ObjectId: ObjectId::parse_str failed", uid, e))
        })?;
        let filter = doc! {
            "_id": uid,
        };
        let mut setter = doc! {
            "update_time": DateTime::now(),
        };
        if let Some(desc) = desc {
            setter.insert("desc", desc);
        }
        if let Some(tags) = tags {
            setter.insert("tags", tags);
        }
        if let Some(extra_info) = extra_info {
            setter.insert("extra_info", extra_info);
        }
        let updater = doc! { "$set": setter };
        let _ = self.collection__fish().update_one(filter, updater).await.map_err(|e| {
            err!("modify fish failed").trace(ctx!("modify fish: self.collection__fish().update_one failed", uid, e))
        })?;
        Ok(())
    }

    async fn mark_fish(&self, uids: &Vec<&str>) -> YRes<()> {
        let uids = uids.iter().fold(Vec::new(), |mut acc, it| {
            match ObjectId::parse_str(it) {
                Ok(uid) => acc.push(uid),
                Err(e) => warn!("mark fish by uids - skip a uid: parse to ObjectId failed, uid={it}, err={e}")
            };
            acc
        });
        let filter = doc! {
            "_id": { "$in":  &uids}
        };
        let updater = doc! {
            "$set": {
                "is_marked": true,
                "update_time": DateTime::now(),
            }
        };
        let _ = self.collection__fish().update_many(filter, updater).await.map_err(|e| {
            err!("mark fish failed").trace(ctx!("mark fish: self.collection__fish().update_many failed", uids, e))
        })?;
        Ok(())
    }

    async fn unmark_fish(&self, uids: &Vec<&str>) -> YRes<()> {
        let uids = uids.iter().fold(Vec::new(), |mut acc, it| {
            match ObjectId::parse_str(it) {
                Ok(uid) => acc.push(uid),
                Err(e) => warn!("unmark fish by uids - skip a uid: parse to ObjectId failed, uid={it}, err={e}")
            };
            acc
        });
        let filter = doc! {
            "_id": { "$in":  &uids}
        };
        let updater = doc! {
            "$set": {
                "is_marked": false,
                "update_time": DateTime::now(),
            }
        };
        let _ = self.collection__fish().update_many(filter, updater).await.map_err(|e| {
            err!("unmark fish failed").trace(ctx!("unmark fish: self.collection__fish().update_many failed", uids, e))
        })?;
        Ok(())
    }

    async fn lock_fish(&self, uids: &Vec<&str>) -> YRes<()> {
        let uids = uids.iter().fold(Vec::new(), |mut acc, it| {
            match ObjectId::parse_str(it) {
                Ok(uid) => acc.push(uid),
                Err(e) => warn!("lock fish by uids - skip a uid: parse to ObjectId failed, uid={it}, err={e}")
            };
            acc
        });
        let filter = doc! {
            "_id": { "$in":  &uids}
        };
        let updater = doc! {
            "$set": {
                "is_locked": true,
                "update_time": DateTime::now(),
            }
        };
        let _ = self.collection__fish().update_many(filter, updater).await.map_err(|e| {
            err!("lock fish failed").trace(ctx!("lock fish: self.collection__fish().update_many failed", uids, e))
        })?;
        Ok(())
    }

    async fn unlock_fish(&self, uids: &Vec<&str>) -> YRes<()> {
        let uids = uids.iter().fold(Vec::new(), |mut acc, it| {
            match ObjectId::parse_str(it) {
                Ok(uid) => acc.push(uid),
                Err(e) => warn!("unlock fish by uids - skip a uid: parse to ObjectId failed, uid={it}, err={e}")
            };
            acc
        });
        let filter = doc! {
            "_id": { "$in":  &uids}
        };
        let updater = doc! {
            "$set": {
                "is_locked": false,
                "update_time": DateTime::now(),
            }
        };
        let _ = self.collection__fish().update_many(filter, updater).await.map_err(|e| {
            err!("unlock fish failed").trace(ctx!("unlock fish: self.collection__fish().update_many failed", uids, e))
        })?;
        Ok(())
    }

    async fn pin_fish(&self, uids: &Vec<&str>) -> YRes<()> {
        let uids = uids.iter().fold(Vec::new(), |mut acc, it| {
            match ObjectId::parse_str(it) {
                Ok(uid) => acc.push(uid),
                Err(e) => warn!("pin fish by uids - skip a uid: parse to ObjectId failed, uid={it}, err={e}")
            };
            acc
        });
        let filter = doc! {
            "_id": { "$in":  &uids}
        };
        let updater = doc! {
            "$set": {
                "update_time": DateTime::now(),
            }
        };
        let _ = self.collection__fish().update_many(filter, updater).await.map_err(|e| {
            err!("pin fish failed").trace(ctx!("pin fish: self.collection__fish().update_many failed", uids, e))
        })?;
        Ok(())
    }

    async fn increase_count(&self, uids: &Vec<&str>) -> YRes<()> {
        let uids = uids.iter().fold(Vec::new(), |mut acc, it| {
            match ObjectId::parse_str(it) {
                Ok(uid) => acc.push(uid),
                Err(e) => warn!("increase fish count by uids - skip a uid: parse to ObjectId failed, uid={it}, err={e}")
            };
            acc
        });
        let filter = doc! {
            "_id": { "$in":  &uids}
        };
        let updater = doc! {
            "$inc": { "count": 1 },
            "$set": {
                "update_time": DateTime::now(),
            }
        };
        let _ = self.collection__fish().update_many(filter, updater).await.map_err(|e| {
            err!("increase fish count failed").trace(ctx!("increase fish count: self.collection__fish().update_many failed", uids, e))
        })?;
        Ok(())
    }

    async fn pick_fish(&self, uid: &str) -> YRes<Option<Fish>> {
        let uid = ObjectId::parse_str(uid).map_err(|e| {
            err!("pick fish failed").trace(ctx!("pick fish -> parse uid to ObjectId: ObjectId::parse_str failed", uid, e))
        })?;
        let filter = doc! {
            "_id": uid,
            "expire_time": Bson::Null,
        };
        let fish_model = self.collection__fish().find_one(filter).await.map_err(|e| {
            err!("pick fish failed").trace(ctx!("pick fish: self.collection__fish().find_one failed", uid, e))
        })?;
        let fish = match fish_model {
            Some(fish_model) => Some(Fish::try_from(fish_model).trace(
                ctx!("pick fish -> parse FishModel to Fish: Fish::try_from failed")
            )?),
            None => None,
        };
        Ok(fish)
    }

    async fn pick_fish_by_identity(&self, identity: &str) -> YRes<Option<touchfish_core::Fish>> {
        let filter = doc! {
            "identity": identity,
            "expire_time": Bson::Null,
        };
        let fish_model = self.collection__fish().find_one(filter).await.map_err(|e| {
            err!("pick fish by identity failed").trace(ctx!("pick fish by identity: self.collection__fish().find_one failed", identity, e))
        })?;
        let fish = match fish_model {
            Some(fish_model) => Some(Fish::try_from(fish_model).trace(
                ctx!("pick fish by identity -> parse FishModel to Fish: Fish::try_from failed")
            )?),
            None => None,
        };
        Ok(fish)
    }

    async fn page_fish_by_conditions(
        &self, fuzzy: Option<&str>, identitys: Option<&Vec<&str>>, count: Option<i32>,
        fish_types: Option<&Vec<FishType>>, desc: Option<&str>, tags: Option<&Vec<&str>>, 
        is_marked: Option<bool>, is_locked: Option<bool>, passed_hours: Option<i32>, 
        page_num: u64, page_size: u64,
    ) -> YRes<Page<Fish>> {
        let mut filter = doc! { "expire_time": Bson::Null };
        if let Some(fuzzy) = fuzzy {
            filter.insert("fish_data_for_search", doc! { "$regex": fuzzy, "$options": "i" });
        }
        if let Some(identitys) = identitys {
            filter.insert("identity", doc! { "$in": identitys });
        }
        if let Some(count) = count {
            filter.insert("count", count);
        }
        if let Some(fish_types) = fish_types {
            let fish_types: Vec<String> = fish_types.into_iter().map(|x| x.to_string()).collect();
            filter.insert("fish_type", doc! { "$in": fish_types });
        }
        if let Some(desc) = desc {
            filter.insert("desc", doc! { "$regex": desc, "$options": "i" });
        }
        if let Some(tags) = tags {
            filter.insert("tags", doc! { "$all": tags });
        }
        if let Some(is_marked) = is_marked {
            filter.insert("is_marked", is_marked);
        }
        if let Some(is_locked) = is_locked {
            filter.insert("is_locked", is_locked);
        }
        if let Some(passed_hours) = passed_hours {
            let bound_time_ts = YTime::now().duration((passed_hours as i64) * -3600).timestamp();
            let bound_time = DateTime::from_millis(bound_time_ts);
            filter.insert("update_time", doc! { "$lt": bound_time });
        }
        let total_count = self.collection__fish().count_documents(filter.clone()).await.map_err(|e| {
            err!("page fish failed").trace(ctx!("page fish -> count total_count: self.collection__fish().count_documents failed", e))
        })?;
        let fish_list = if total_count <= 0 {
            Vec::new()
        } else {
            let sort = doc! { "_id": 1 };
            let mut cursor = self.collection__fish()
                .find(filter).sort(sort).skip(page_size*page_num).limit(page_size as i64).await.map_err(|e| {
                err!("page fish failed").trace(ctx!("page fish: self.collection__fish().find failed", e))
            })?;
            let mut fish_list: Vec<Fish> = Vec::new();
            while cursor.advance().await.map_err(|e| {
                err!("page fish failed").trace(ctx!("page fish -> get data in cursor: cursor.advance failed", e))
            })? {
                let fish_model = cursor.deserialize_current().map_err(|e| {
                    err!("page fish failed").trace(ctx!("page fish -> get data in cursor: cursor.deserialize_current failed", e))
                })?;
                let fish_model_uid = fish_model.uid;
                let fish = Fish::try_from(fish_model).trace(
                    ctx!("page fish -> get data in cursor: Fish::try_from failed", fish_model_uid)
                )?;
                fish_list.push(fish);
            }
            fish_list
        };
        Ok(Page {
            total_count,
            page_num,
            page_size,
            data: fish_list,
        })
    }

    async fn detect_fish_by_conditions(
        &self, fuzzy: Option<&str>, identitys: Option<&Vec<&str>>, count: Option<i32>,
        fish_types: Option<&Vec<FishType>>, desc: Option<&str>, tags: Option<&Vec<&str>>, 
        is_marked: Option<bool>, is_locked: Option<bool>, passed_hours: Option<i32>, 
    ) -> YRes<Vec<String>> {
        let mut filter = doc! { "expire_time": Bson::Null };
        if let Some(fuzzy) = fuzzy {
            filter.insert("fish_data_for_search", doc! { "$regex": fuzzy, "$options": "i" });
        }
        if let Some(identitys) = identitys {
            filter.insert("identity", doc! { "$in": identitys });
        }
        if let Some(count) = count {
            filter.insert("count", count);
        }
        if let Some(fish_types) = fish_types {
            let fish_types: Vec<String> = fish_types.into_iter().map(|x| x.to_string()).collect();
            filter.insert("fish_type", doc! { "$in": fish_types });
        }
        if let Some(desc) = desc {
            filter.insert("desc", doc! { "$regex": desc, "$options": "i" });
        }
        if let Some(tags) = tags {
            filter.insert("tags", doc! { "$all": tags });
        }
        if let Some(is_marked) = is_marked {
            filter.insert("is_marked", is_marked);
        }
        if let Some(is_locked) = is_locked {
            filter.insert("is_locked", is_locked);
        }
        if let Some(passed_hours) = passed_hours {
            let bound_time_ts = YTime::now().duration((passed_hours as i64) * -3600).timestamp();
            let bound_time = DateTime::from_millis(bound_time_ts);
            filter.insert("update_time", doc! { "$lt": bound_time });
        }
        let projection = doc! { "_id": 1 };
        let mut cursor = self.collection__fish().find(filter).projection(projection).await.map_err(|e| {
            err!("delect fish failed").trace(ctx!("delect fish: self.collection__fish().find failed", e))
        })?.with_type::<UidModel>();
        let mut uids: Vec<String> = Vec::new();
        while cursor.advance().await.map_err(|e| {
            err!("detect fish failed").trace(ctx!("detect fish -> get data in cursor: cursor.advance failed", e))
        })? {
            let uid = cursor.deserialize_current().map_err(|e| {
                err!("detect fish failed").trace(ctx!("detect fish -> get data in cursor: cursor.deserialize_current failed", e))
            })?.uid;
            uids.push(uid.to_hex());
        }
        Ok(uids)
    }

    async fn count_fish(&self) -> YRes<Statistics> {
        let count__active = self.count_active_fish().await.trace(
            ctx!("count fish -> count active fish: self.count_active_fish failed")
        )?;
        let count__expired = self.count_expired_fish().await.trace(
            ctx!("count fish -> count expired fish: self.count_expired_fish failed")
        )?;
        let count__by_type = self.count_fish_by_type().await.trace(
            ctx!("count fish -> count fish by type: self.count_fish_by_type failed")
        )?;
        let count__by_tag = self.count_fish_by_tag().await.trace(
            ctx!("count fish -> count fish by tag: self.count_fish_by_tag failed")
        )?;
        let count__marked = self.count_marked_fish().await.trace(
            ctx!("count fish -> count marked fish: self.count_marked_fish failed")
        )?;
        let count__unmarked = self.count_unmarked_fish().await.trace(
            ctx!("count fish -> count unmarked fish: self.count_unmarked_fish failed")
        )?;
        let count__locked = self.count_locked_fish().await.trace(
            ctx!("count fish -> count locked fish: self.count_locked_fish failed")
        )?;
        let count__unlocked = self.count_unlocked_fish().await.trace(
            ctx!("count fish -> count unlocked fish: self.count_unlocked_fish failed")
        )?;
        let count__by_day = self.count_fish_by_day().await.trace(
            ctx!("count fish -> count fish by day: self.count_fish_by_day failed")
        )?;
        Ok(Statistics {
            count__active,
            count__expired,
            count__by_type,
            count__by_tag,
            count__marked,
            count__unmarked,
            count__locked,
            count__unlocked,
            count__by_day,
        })
    }

}

impl MongoStorage {

    async fn count_active_fish(&self) -> YRes<u64> {
        let filter = doc! {
            "expire_time": Bson::Null,
        };
        let count = self.collection__fish().count_documents(filter).await.map_err(|e| {
            err!("count active fish failed").trace(
                ctx!("count active fish: self.collection__fish().count_documents failed", e)
            )
        })?;
        Ok(count)
    }

    async fn count_expired_fish(&self) -> YRes<u64> {
        let filter = doc! {
            "expire_time": { "$ne": Bson::Null },
        };
        let count = self.collection__fish().count_documents(filter).await.map_err(|e| {
            err!("count expired fish failed").trace(
                ctx!("count expired fish: self.collection__fish().count_documents failed", e)
            )
        })?;
        Ok(count)
    }

    async fn count_marked_fish(&self) -> YRes<u64> {
        let filter = doc! {
            "expired_time": Bson::Null,
            "is_marked": true,
        };
        let count = self.collection__fish().count_documents(filter).await.map_err(|e| {
            err!("count marked fish failed").trace(
                ctx!("count marked fish: self.collection__fish().count_documents failed", e)
            )
        })?;
        Ok(count)
    }

    async fn count_unmarked_fish(&self) -> YRes<u64> {
        let filter = doc! {
            "expired_time": Bson::Null,
            "is_marked": false,
        };
        let count = self.collection__fish().count_documents(filter).await.map_err(|e| {
            err!("count unmarked fish failed").trace(
                ctx!("count unmarked fish: self.collection__fish().count_documents failed", e)
            )
        })?;
        Ok(count)
    }

    async fn count_locked_fish(&self) -> YRes<u64> {
        let filter = doc! {
            "expired_time": Bson::Null,
            "is_locked": true,
        };
        let count = self.collection__fish().count_documents(filter).await.map_err(|e| {
            err!("count locked fish failed").trace(
                ctx!("count locked fish: self.collection__fish().count_documents failed", e)
            )
        })?;
        Ok(count)
    }

    async fn count_unlocked_fish(&self) -> YRes<u64> {
        let filter = doc! {
            "expired_time": Bson::Null,
            "is_locked": false,
        };
        let count = self.collection__fish().count_documents(filter).await.map_err(|e| {
            err!("count unlocked fish failed").trace(
                ctx!("count unlocked fish: self.collection__fish().count_documents failed", e)
            )
        })?;
        Ok(count)
    }

    async fn count_fish_by_type(&self) -> YRes<HashMap<FishType, u64>> {
        let pipeline = vec![
            doc! {
                "$match": { "expired_time": Bson::Null },
            },
            doc! {
                "$group": {
                    "_id": "$fish_type",
                    "count": { "$sum": 1 }
                }
            },
        ];
        let mut cursor = self.collection__fish().aggregate(pipeline).await.map_err(|e| {
            err!("count fish by type failed").trace(ctx!("count fish by type: self.collection__fish().aggregate failed", e))
        })?.with_type::<StatsModel>();
        let mut result = HashMap::new();
        while cursor.advance().await.map_err(|e| {
            err!("count fish by type failed").trace(ctx!("count fish by type -> get data in cursor: cursor.advance failed", e))
        })? {
            let stats_model = cursor.deserialize_current().map_err(|e| {
                err!("count fish by type failed").trace(ctx!("count fish by type -> get data in cursor: cursor.deserialize_current failed", e))
            })?;
            let fish_type = FishType::from_name(&stats_model.name).trace(
                ctx!("count fish by type -> parse stats.name to FishType: FishType::from_name failed", stats_model.name)
            )?;
            result.insert(fish_type, stats_model.count);
        }
        Ok(result)
    }

    async fn count_fish_by_tag(&self) -> YRes<HashMap<String, u64>> {
        let pipeline = vec![
            doc! {
                "$match": { "expired_time": Bson::Null },
            },
            doc! {
                "$unwind": "$tags",
            },
            doc! {
                "$group": {
                    "_id": "$tags",
                    "count": { "$sum": 1 },
                }
            },
        ];
        let mut cursor = self.collection__fish().aggregate(pipeline).await.map_err(|e| {
            err!("count fish by tag failed").trace(ctx!("count fish by tag: self.collection__fish().aggregate failed", e))
        })?.with_type::<StatsModel>();
        let mut result = HashMap::new();
        while cursor.advance().await.map_err(|e| {
            err!("count fish by tag failed").trace(ctx!("count fish by tag -> get data in cursor: cursor.advance failed", e))
        })? {
            let stats_model = cursor.deserialize_current().map_err(|e| {
                err!("count fish by tag failed").trace(ctx!("count fish by tag -> get data in cursor: cursor.deserialize_current failed", e))
            })?;
            result.insert(stats_model.name, stats_model.count);
        }
        let filter = doc! {
            "expired_time": Bson::Null,
            "tags": { "$size": 0 }, 
        };
        let no_tag_count = self.collection__fish().count_documents(filter).await.map_err(|e| {
            err!("count fish by tag failed").trace(
                ctx!("count fish by tag -> count no tag fish count: self.collection__fish().count_documents failed", e)
            )
        })?;
        result.insert("".to_string(), no_tag_count);
        Ok(result)
    }

    async fn count_fish_by_day(&self) -> YRes<HashMap<String, u64>> {
        let pipeline = vec![
            doc! {
                "$match": { "expired_time": Bson::Null },
            },
            doc! {
                "$project": {
                    "date": { 
                        "$dateToString": {
                            "format": "%Y-%m-%d",
                            "date": "$create_time",
                        }
                    }
                }
            },
            doc! {
                "$group": {
                    "_id": "$date",
                    "count": { "$sum": 1 },
                }
            },
        ];
        let mut cursor = self.collection__fish().aggregate(pipeline).await.map_err(|e| {
            err!("count fish by day failed").trace(ctx!("count fish by day: self.collection__fish().aggregate failed", e))
        })?.with_type::<StatsModel>();
        let mut result = HashMap::new();
        while cursor.advance().await.map_err(|e| {
            err!("count fish by day failed").trace(ctx!("count fish by day -> get data in cursor: cursor.advance failed", e))
        })? {
            let stats_model = cursor.deserialize_current().map_err(|e| {
                err!("count fish by day failed").trace(ctx!("count fish by day -> get data in cursor: cursor.deserialize_current failed", e))
            })?;
            result.insert(stats_model.name, stats_model.count);
        }
        Ok(result)
    }

}