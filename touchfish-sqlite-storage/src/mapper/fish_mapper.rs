use crate::SqliteStorage;

use diesel::dsl::sql;
use diesel::{prelude::*, sql_query};
use diesel::sql_types::{Bool, Text};
use diesel::SqliteConnection;
use yfunc_rust::prelude::*;

use crate::model::{CountByDay, CountByTag, CountByType, FishInserter, FishModel, FishSelecter, FishUpdater};
use crate::schema::fish;

impl SqliteStorage {

    pub fn fish__insert(&self, conn: &mut SqliteConnection, inserter: &FishInserter) -> YRes<FishModel> {
        let inserted = diesel::insert_into(fish::table)
            .values(inserter)
            .returning(FishModel::as_returning())
            .get_result(conn).map_err(|e| e.into()).trace(
                ctx!("fish__insert: diesel execute failed")
            )?;
        Ok(inserted)
    }

    #[allow(unused)]
    pub fn fish__delete(&self, conn: &mut SqliteConnection, id: i32) -> YRes<usize> {
        let cnt = diesel::delete(fish::table.filter(fish::id.eq(id))).execute(conn).map_err(|e| e.into()).trace(
            ctx!("fish__delete: diesel execute failed")
        )?;
        Ok(cnt)
    }

    pub fn fish__delete_batch(&self, conn: &mut SqliteConnection, ids: &Vec<i32>) -> YRes<usize> {
        let cnt = diesel::delete(fish::table.filter(fish::id.eq_any(ids))).execute(conn).map_err(|e| e.into()).trace(
            ctx!("fish__delete_batch: diesel execute failed")
        )?;
        Ok(cnt)
    }

    pub fn fish__update(&self, conn: &mut SqliteConnection, identity: &str, updater: &FishUpdater) -> YRes<usize> {
        diesel::update(fish::table.filter(fish::identity.eq(identity)))
            .set(updater)
            .execute(conn).map_err(|e| e.into()).trace(
                ctx!("fish__update: diesel execute failed")
            )
    }

    pub fn fish__update_batch(&self, conn: &mut SqliteConnection, identitys: &Vec<&str>, updater: &FishUpdater) -> YRes<usize> {
        diesel::update(fish::table.filter(fish::identity.eq_any(identitys)))
            .set(updater)
            .execute(conn).map_err(|e| e.into()).trace(
                ctx!("fish__update_batch: diesel execute failed")
            )
    }

    #[allow(unused)]
    pub fn fish__inc_cnt(&self, conn: &mut SqliteConnection, identity: &str) -> YRes<usize> {
        diesel::update(fish::table.filter(fish::identity.eq(identity)))
        .set(fish::count.eq(fish::count+1))
        .execute(conn).map_err(|e| e.into()).trace(
            ctx!("fish__inc_cnt: diesel execute failed")
        )
    }

    pub fn fish__inc_cnt_batch(&self, conn: &mut SqliteConnection, identitys: &Vec<&str>) -> YRes<usize> {
        diesel::update(fish::table.filter(fish::identity.eq_any(identitys)))
        .set(fish::count.eq(fish::count+1))
        .execute(conn).map_err(|e| e.into()).trace(
            ctx!("fish__inc_cnt_batch: diesel execute failed")
        )
    }

    #[allow(unused)]
    pub fn fish__dec_cnt(&self, conn: &mut SqliteConnection, identity: &str) -> YRes<usize> {
        diesel::update(fish::table.filter(fish::identity.eq(identity)))
        .set(fish::count.eq(fish::count-1))
        .execute(conn).map_err(|e| e.into()).trace(
            ctx!("fish__dec_cnt: diesel execute failed")
        )
    }

    pub fn fish__dec_cnt_batch(&self, conn: &mut SqliteConnection, identitys: &Vec<&str>) -> YRes<usize> {
        diesel::update(fish::table.filter(fish::identity.eq_any(identitys)))
        .set(fish::count.eq(fish::count-1))
        .execute(conn).map_err(|e| e.into()).trace(
            ctx!("fish__dec_cnt_batch: diesel execute failed")
        )
    }

    pub fn fish__pick(&self, conn: &mut SqliteConnection, identity: &str) -> YRes<Vec<FishModel>> {
        let selected: Vec<FishModel> = fish::dsl::fish
            .filter(fish::identity.eq(identity))
            .select(FishModel::as_select())
            .load(conn).map_err(|e| e.into()).trace(
                ctx!("fish__pick: diesel execute failed")
            )?;
        Ok(selected)
    }

    pub fn fish__select(&self, conn: &mut SqliteConnection, selecter: &FishSelecter) -> YRes<Vec<FishModel>> {
        let mut query = fish::dsl::fish.into_boxed();
        if let Some(fuzzy) = &selecter.fuzzy {
            query = query.filter(fish::desc.like(fuzzy).or(sql::<Bool>("fish_data LIKE ").bind::<Text, _>(fuzzy)))
        }
        if let Some(identitys) = &selecter.identitys {
            query = query.filter(fish::identity.eq_any(identitys));
        }
        if let Some(count) = selecter.count {
            query = query.filter(fish::count.eq(count));
        }
        if let Some(fish_types) = &selecter.fish_types {
            query = query.filter(fish::fish_type.eq_any(fish_types));
        }
        if let Some(desc) = &selecter.desc {
            query = query.filter(fish::desc.like(desc));
        }
        if let Some(tags) = &selecter.tags {
            query = query.filter(fish::tags.like(tags));
        }
        if let Some(is_marked) = selecter.is_marked {
            query = query.filter(fish::is_marked.eq(is_marked));
        }
        if let Some(is_locked) = selecter.is_locked {
            query = query.filter(fish::is_locked.eq(is_locked));
        }
        if let Some(update_before) = &selecter.update_before {
            query = query.filter(fish::update_time.le(update_before))
        }
        if let Some(limit) = selecter.limit {
            query = query.limit(limit as i64);
        }
        if let Some(offset) = selecter.offset {
            query = query.offset(offset as i64);
        }
        // println!("{}", diesel::debug_query::<diesel::sqlite::Sqlite, _>(&query));
        let selected: Vec<FishModel> = query
            .select(FishModel::as_select())
            .load(conn).map_err(|e| e.into()).trace(
                ctx!("fish__select: diesel execute failed")
            )?;
        Ok(selected)
    }

    pub fn fish__select_identity(&self, conn: &mut SqliteConnection, selecter: &FishSelecter) -> YRes<Vec<String>> {
        let mut query = fish::dsl::fish.into_boxed();
        if let Some(fuzzy) = &selecter.fuzzy {
            query = query.filter(fish::desc.like(fuzzy).or(sql::<Bool>("fish_data LIKE ").bind::<Text, _>(fuzzy)))
        }
        if let Some(identitys) = &selecter.identitys {
            query = query.filter(fish::identity.eq_any(identitys));
        }
        if let Some(count) = selecter.count {
            query = query.filter(fish::count.eq(count));
        }
        if let Some(fish_types) = &selecter.fish_types {
            query = query.filter(fish::fish_type.eq_any(fish_types));
        }
        if let Some(desc) = &selecter.desc {
            query = query.filter(fish::desc.like(desc));
        }
        if let Some(tags) = &selecter.tags {
            query = query.filter(fish::tags.like(tags));
        }
        if let Some(is_marked) = selecter.is_marked {
            query = query.filter(fish::is_marked.eq(is_marked));
        }
        if let Some(is_locked) = selecter.is_locked {
            query = query.filter(fish::is_locked.eq(is_locked));
        }
        if let Some(update_before) = &selecter.update_before {
            query = query.filter(fish::update_time.le(update_before))
        }
        if let Some(limit) = selecter.limit {
            query = query.limit(limit as i64);
        }
        if let Some(offset) = selecter.offset {
            query = query.offset(offset as i64);
        }
        // println!("{}", diesel::debug_query::<diesel::sqlite::Sqlite, _>(&query));
        let selected: Vec<String> = query
            .select(fish::identity)
            .load(conn).map_err(|e| e.into()).trace(
                ctx!("fish__select_identity: diesel execute failed")
            )?;
        Ok(selected)
    }

    pub fn fish__count(&self, conn: &mut SqliteConnection, selecter: &FishSelecter) -> YRes<i64> {
        let mut query = fish::dsl::fish.into_boxed();
        if let Some(fuzzy) = &selecter.fuzzy {
            query = query.filter(fish::desc.like(fuzzy).or(sql::<Bool>("fish_data LIKE ").bind::<Text, _>(fuzzy)))
        }
        if let Some(identitys) = &selecter.identitys {
            query = query.filter(fish::identity.eq_any(identitys));
        }
        if let Some(count) = selecter.count {
            query = query.filter(fish::count.eq(count));
        }
        if let Some(fish_types) = &selecter.fish_types {
            query = query.filter(fish::fish_type.eq_any(fish_types));
        }
        if let Some(desc) = &selecter.desc {
            query = query.filter(fish::desc.like(desc));
        }
        if let Some(tags) = &selecter.tags {
            query = query.filter(fish::tags.like(tags));
        }
        if let Some(is_marked) = selecter.is_marked {
            query = query.filter(fish::is_marked.eq(is_marked));
        }
        if let Some(is_locked) = selecter.is_locked {
            query = query.filter(fish::is_locked.eq(is_locked));
        }
        if let Some(update_before) = &selecter.update_before {
            query = query.filter(fish::update_time.le(update_before))
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
                ctx!("fish__count: diesel execute failed")
            )?;
        Ok(cnt)
    }

    pub fn fish__count_by_type(&self, conn: &mut SqliteConnection) -> YRes<Vec<CountByType>> {
        let query = sql_query("select fish_type, count(*) as count from fish group by fish_type;");
        query.load::<CountByType>(conn).map_err(|e| e.into()).trace(
            ctx!("fish__count_by_type: diesel execute failed")
        )
    }

    pub fn fish__count_by_tag(&self, conn: &mut SqliteConnection) -> YRes<Vec<CountByTag>> {
        let query = sql_query(r#"
WITH RECURSIVE split(tag, rest) AS (
    SELECT 
        substr(tags, 1, instr(tags || ',', ',') - 1) AS tag,
        substr(tags, instr(tags || ',', ',') + 1) AS rest
    FROM fish
    UNION ALL
    SELECT 
        substr(rest, 1, instr(rest || ',', ',') - 1) AS tag,
        substr(rest, instr(rest || ',', ',') + 1) AS rest
    FROM split
    WHERE rest != ''
)
SELECT tag, COUNT(*) AS count
FROM split
GROUP BY tag
ORDER BY count DESC;
        "#);
        query.load::<CountByTag>(conn).map_err(|e| e.into()).trace(
            ctx!("fish__count_by_tag: diesel execute failed")
        )
    }

    pub fn fish__count_by_day(&self, conn: &mut SqliteConnection) -> YRes<Vec<CountByDay>> {
        let query = sql_query(r#"
SELECT strftime('%Y-%m-%d', create_time) AS day,
       COUNT(*) AS count
FROM fish
GROUP BY strftime('%Y-%m-%d', create_time)
ORDER BY day DESC;
        "#);
        query.load::<CountByDay>(conn).map_err(|e| e.into()).trace(
            ctx!("fish__count_by_day: diesel execute failed")
        )
    }

}
