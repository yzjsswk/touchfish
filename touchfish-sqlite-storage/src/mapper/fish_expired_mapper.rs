use crate::SqliteStorage;

use diesel::dsl::sql;
use diesel::{prelude::*, sql_query};
use diesel::sql_types::{Bool, Text};
use diesel::SqliteConnection;
use yfunc_rust::prelude::*;

use crate::model::{CountByDay, FishExpiredInserter, FishExpiredModel, FishSelecter};
use crate::schema::{fish, fish_expired};

impl SqliteStorage {

    pub fn fish_expired__count(&self, conn: &mut SqliteConnection, selecter: &FishSelecter) -> YRes<i64> {
        let mut query = fish_expired::dsl::fish_expired.into_boxed();
        if let Some(fuzzy) = &selecter.fuzzy {
            query = query.filter(fish_expired::desc.like(fuzzy).or(sql::<Bool>("fish_data LIKE ").bind::<Text, _>(fuzzy)))
        }
        if let Some(identitys) = &selecter.identitys {
            query = query.filter(fish_expired::identity.eq_any(identitys));
        }
        if let Some(count) = selecter.count {
            query = query.filter(fish_expired::count.eq(count));
        }
        if let Some(fish_types) = &selecter.fish_types {
            query = query.filter(fish_expired::fish_type.eq_any(fish_types));
        }
        if let Some(desc) = &selecter.desc {
            query = query.filter(fish_expired::desc.like(desc));
        }
        if let Some(tags) = &selecter.tags {
            query = query.filter(fish_expired::tags.like(tags));
        }
        if let Some(is_marked) = selecter.is_marked {
            query = query.filter(fish_expired::is_marked.eq(is_marked));
        }
        if let Some(is_locked) = selecter.is_locked {
            query = query.filter(fish_expired::is_locked.eq(is_locked));
        }
        if let Some(update_before) = &selecter.update_before {
            query = query.filter(fish_expired::update_time.le(update_before))
        }
        if let Some(limit) = selecter.limit {
            query = query.limit(limit as i64);
        }
        if let Some(offset) = selecter.offset {
            query = query.offset(offset as i64);
        }
        let cnt: i64 = query
            .count()
            .get_result(conn).map_err(|e| e.into()).trace(
                ctx!("expired_fish__count: diesel execute failed")
            )?;
        Ok(cnt)
    }

    pub fn fish_expired__insert(&self, conn: &mut SqliteConnection, inserter: &FishExpiredInserter) -> YRes<FishExpiredModel> {
        let inserted = diesel::insert_into(fish_expired::table)
            .values(inserter)
            .returning(FishExpiredModel::as_returning())
            .get_result(conn).map_err(|e| e.into()).trace(
                ctx!("fish_expired__insert: diesel execute failed")
            )?;
        Ok(inserted)
    }

    pub fn fish_expired__count_by_day(&self, conn: &mut SqliteConnection) -> YRes<Vec<CountByDay>> {
        let query = sql_query(r#"
SELECT strftime('%Y-%m-%d', create_time) AS day,
       COUNT(*) AS count
FROM fish_expired
GROUP BY strftime('%Y-%m-%d', create_time)
ORDER BY day DESC;
        "#);
        query.load::<CountByDay>(conn).map_err(|e| e.into()).trace(
            ctx!("fish_expired__count_by_day: diesel execute failed")
        )
    }

}
