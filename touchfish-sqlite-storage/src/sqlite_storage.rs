use std::collections::HashMap;
use std::time::Duration;

use diesel::connection::SimpleConnection;
use diesel::dsl::sql;
use diesel::{prelude::*, sql_query};
use diesel::result::Error;
use diesel::sql_types::{Bool, Text};
use diesel::{r2d2::ConnectionManager, SqliteConnection};
use r2d2::{Pool, PooledConnection};
use touchfish_core::{DataInfo, Fish, FishStorage, FishType, Statistics};
use yfunc_rust::{prelude::*, Page, YBytes};

use crate::model::{CountByDay, CountByTag, CountByType, FishExpiredInserter, FishExpiredModel, FishInserter, FishModel, FishSelecter, FishUpdater};
use crate::schema::{fish, fish_expired};

pub struct SqliteStorage {
    pool: Pool<ConnectionManager<SqliteConnection>>,
}

impl SqliteStorage {

    pub fn connect(db_url: &str) -> YRes<Self> {
        if !std::path::Path::new(db_url).exists() {
            return Err(err!(DataBaseError::"connect to sqlite": "db url is not exists", db_url))
        }
        let manager = ConnectionManager::<SqliteConnection>::new(db_url);
        let pool = r2d2::Pool::builder()
            .max_size(8)
            .connection_timeout(Duration::new(5, 0))
            .build(manager)
            .map_err(|err| err!(DataBaseError::"connect to sqlite": "build connection pool failed", db_url, err))?;
        Ok(SqliteStorage { pool })
    }

    pub fn get_conn(&self) -> YRes<PooledConnection<ConnectionManager<SqliteConnection>>> {
        let mut conn = self.pool.get().map_err(|e|
            err!(DataBaseError::"get connection from pool", e)
        )?;
        conn.batch_execute("PRAGMA busy_timeout = 5000;").map_err(|e|
            err!(DataBaseError::"get connection from pool": "set timeout failed", e)
        )?;
        Ok(conn)

    }

    fn fish__insert(&self, conn: &mut SqliteConnection, inserter: &FishInserter) -> Result<FishModel, Error> {
        let inserted = diesel::insert_into(fish::table)
            .values(inserter)
            .returning(FishModel::as_returning())
            .get_result(conn)?;
        Ok(inserted)
    }

    #[allow(unused)]
    fn fish__delete(&self, conn: &mut SqliteConnection, id: i32) -> Result<usize, Error> {
        let cnt = diesel::delete(fish::table.filter(fish::id.eq(id))).execute(conn)?;
        Ok(cnt)
    }

    fn fish__delete_batch(&self, conn: &mut SqliteConnection, ids: &Vec<i32>) -> Result<usize, Error> {
        let cnt = diesel::delete(fish::table.filter(fish::id.eq_any(ids))).execute(conn)?;
        Ok(cnt)
    }

    fn fish__update(&self, conn: &mut SqliteConnection, identity: &str, updater: &FishUpdater) -> Result<usize, Error> {
        diesel::update(fish::table.filter(fish::identity.eq(identity)))
            .set(updater)
            .execute(conn)
    }

    fn fish__update_batch(&self, conn: &mut SqliteConnection, identitys: &Vec<&str>, updater: &FishUpdater) -> Result<usize, Error> {
        diesel::update(fish::table.filter(fish::identity.eq_any(identitys)))
            .set(updater)
            .execute(conn)
    }

    #[allow(unused)]
    fn fish__inc_cnt(&self, conn: &mut SqliteConnection, identity: &str) -> Result<usize, Error> {
        diesel::update(fish::table.filter(fish::identity.eq(identity)))
        .set(fish::count.eq(fish::count+1))
        .execute(conn)
    }

    fn fish__inc_cnt_batch(&self, conn: &mut SqliteConnection, identitys: &Vec<&str>) -> Result<usize, Error> {
        diesel::update(fish::table.filter(fish::identity.eq_any(identitys)))
        .set(fish::count.eq(fish::count+1))
        .execute(conn)
    }

    #[allow(unused)]
    fn fish__dec_cnt(&self, conn: &mut SqliteConnection, identity: &str) -> Result<usize, Error> {
        diesel::update(fish::table.filter(fish::identity.eq(identity)))
        .set(fish::count.eq(fish::count-1))
        .execute(conn)
    }

    fn fish__dec_cnt_batch(&self, conn: &mut SqliteConnection, identitys: &Vec<&str>) -> Result<usize, Error> {
        diesel::update(fish::table.filter(fish::identity.eq_any(identitys)))
        .set(fish::count.eq(fish::count-1))
        .execute(conn)
    }

    fn fish__pick(&self, conn: &mut SqliteConnection, identity: &str) -> Result<Vec<FishModel>, Error> {
        let selected: Vec<FishModel> = fish::dsl::fish
            .filter(fish::identity.eq(identity))
            .select(FishModel::as_select())
            .load(conn)?;
        Ok(selected)
    }

    fn fish__select(&self, conn: &mut SqliteConnection, selecter: &FishSelecter) -> Result<Vec<FishModel>, Error> {
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
            .load(conn)?;
        Ok(selected)
    }

    fn fish__select_identity(&self, conn: &mut SqliteConnection, selecter: &FishSelecter) -> Result<Vec<String>, Error> {
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
            .load(conn)?;
        Ok(selected)
    }

    fn fish__count(&self, conn: &mut SqliteConnection, selecter: &FishSelecter) -> Result<i64, Error> {
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
            .get_result(conn)?;
        Ok(cnt)
    }

    fn expired_fish__count(&self, conn: &mut SqliteConnection, selecter: &FishSelecter) -> Result<i64, Error> {
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
            .get_result(conn)?;
        Ok(cnt)
    }

    fn fish_expired__insert(&self, conn: &mut SqliteConnection, inserter: &FishExpiredInserter) -> Result<FishExpiredModel, Error> {
        let inserted = diesel::insert_into(fish_expired::table)
            .values(inserter)
            .returning(FishExpiredModel::as_returning())
            .get_result(conn)?;
        Ok(inserted)
    }

    fn fish__count_by_type(&self, conn: &mut SqliteConnection) -> Result<Vec<CountByType>, Error> {
        let query = sql_query("select fish_type, count(*) as count from fish group by fish_type;");
        query.load::<CountByType>(conn)
    }

    fn fish__count_by_tag(&self, conn: &mut SqliteConnection) -> Result<Vec<CountByTag>, Error> {
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
        query.load::<CountByTag>(conn)
    }

    fn fish__count_by_day(&self, conn: &mut SqliteConnection) -> Result<Vec<CountByDay>, Error> {
        let query = sql_query(r#"
SELECT strftime('%Y-%m-%d', create_time) AS day,
       COUNT(*) AS count
FROM fish
GROUP BY strftime('%Y-%m-%d', create_time)
ORDER BY day DESC;
        "#);
        query.load::<CountByDay>(conn)
    }

    fn fish_expired__count_by_day(&self, conn: &mut SqliteConnection) -> Result<Vec<CountByDay>, Error> {
        let query = sql_query(r#"
SELECT strftime('%Y-%m-%d', create_time) AS day,
       COUNT(*) AS count
FROM fish_expired
GROUP BY strftime('%Y-%m-%d', create_time)
ORDER BY day DESC;
        "#);
        query.load::<CountByDay>(conn)
    }

}

impl FishStorage for SqliteStorage {

    fn add_fish(
        &self, identity: String, count: i32, fish_type: FishType, fish_data: YBytes, data_info: DataInfo,
        desc: String, tags: Vec<String>, is_marked: bool, is_locked: bool, extra_info: String,
    ) -> YRes<Fish> {
        let mut conn = self.get_conn()?;
        let fish = self.fish__insert(&mut conn, &FishInserter::new(
            identity, count, fish_type, fish_data, data_info, desc, tags, is_marked, is_locked, extra_info
        )?).map_err(|e| err!(DataBaseError::"add fish", e))?;
        Ok(Fish::try_from(fish)?)
    }

    fn expire_fish(&self, identitys: Vec<&str>) -> YRes<()> {
        let mut conn = self.get_conn()?;
        let selecter = FishSelecter::new(
            None, Some(identitys.iter().map(|x| x.to_string()).collect()),
            None, None, None, None, None, None, None, None,
        )?;
        let to_expire_fish = self.fish__select(&mut conn, &selecter).map_err(|e| 
            err!(DataBaseError::"expire fish": "query to delete fish failed", identitys, e)
        )?;
        if to_expire_fish.is_empty() {
            return Ok(())
        }
        let to_expire_fish_ids = to_expire_fish.iter().map(|x| x.id).collect::<Vec<i32>>();
        let mut expired_fish_inserters: Vec<FishExpiredInserter> = Vec::new();
        for fish in to_expire_fish {
            let fish_id = fish.id;
            expired_fish_inserters.push(FishExpiredInserter::new(fish).trace(
                ctx!("expire fish -> build fish expired inserter from to expired fish model": "build failed", fish_id)
            )?)
        }
        conn.transaction::<_, Error, _>(|conn| {
            let cnt = self.fish__delete_batch(conn, &to_expire_fish_ids)?;
            if cnt != to_expire_fish_ids.len() {
                return Err(Error::RollbackTransaction)
            }
            for inserter in expired_fish_inserters {
                self.fish_expired__insert(conn, &inserter)?;
            }
            Ok(())
        }).map_err(|e| err!(DataBaseError::"expire fish": "execute transaction failed", e))
    }

    fn modify_fish(
        &self, identity: &str, desc: Option<String>, tags: Option<Vec<String>>, extra_info: Option<String>,
    ) -> YRes<()> {
        let mut conn = self.get_conn()?;
        self.fish__update(&mut conn, identity, &FishUpdater::new(
            None, None, None, None, None,
            desc, tags, None, None, extra_info,
        )?).map_err(|e| err!(DataBaseError::"modify fish", identity, e))?;
        Ok(())
    }

    fn mark_fish(&self, identitys: Vec<&str>) -> YRes<()> {
        let mut conn = self.get_conn()?;
        self.fish__update_batch(&mut conn, &identitys, &FishUpdater::new(
            None, None, None, None, None,
            None, None, Some(true), None, None,
        )?).map_err(|e| err!(DataBaseError::"mark fish", identitys, e))?;
        Ok(())
    }
    
    fn unmark_fish(&self, identitys: Vec<&str>) -> YRes<()> {
        let mut conn = self.get_conn()?;
        self.fish__update_batch(&mut conn, &identitys, &FishUpdater::new(
            None, None, None, None, None,
            None, None, Some(false), None, None,
        )?).map_err(|e| err!(DataBaseError::"unmark fish", identitys, e))?;
        Ok(())
    }
    
    fn lock_fish(&self, identitys: Vec<&str>) -> YRes<()> {
        let mut conn = self.get_conn()?;
        self.fish__update_batch(&mut conn, &identitys, &FishUpdater::new(
            None, None, None, None, None,
            None, None, None, Some(true), None,
        )?).map_err(|e| err!(DataBaseError::"lock fish", identitys, e))?;
        Ok(())
    }
    
    fn unlock_fish(&self, identitys: Vec<&str>) -> YRes<()> {
        let mut conn = self.get_conn()?;
        self.fish__update_batch(&mut conn, &identitys, &FishUpdater::new(
            None, None, None, None, None,
            None, None, None, Some(false), None,
        )?).map_err(|e| err!(DataBaseError::"unlock fish", identitys, e))?;
        Ok(())
    }
    
    fn pin_fish(&self, identitys: Vec<&str>) -> YRes<()> {
        let mut conn = self.get_conn()?;
        self.fish__update_batch(&mut conn, &identitys, &FishUpdater::empty())
            .map_err(|e| err!(DataBaseError::"pin fish", identitys, e))?;
        Ok(())
    }

    fn increase_count(&self, identitys: Vec<&str>) -> YRes<()> {
        let mut conn = self.get_conn()?;
        conn.transaction::<_, Error, _>(|conn| {
            self.fish__inc_cnt_batch(conn, &identitys)?;
            self.fish__update_batch(conn, &identitys, &FishUpdater::empty())?;
            Ok(())
        }).map_err(|e| err!(DataBaseError::"increase fish count": "execute transaction failed", e))?;
        Ok(())
    }

    fn decrease_count(&self, identitys: Vec<&str>) -> YRes<()> {
        let mut conn = self.get_conn()?;
        conn.transaction::<_, Error, _>(|conn| {
            self.fish__dec_cnt_batch(conn, &identitys)?;
            self.fish__update_batch(conn, &identitys, &FishUpdater::empty())?;
            Ok(())
        }).map_err(|e| err!(DataBaseError::"decrease fish count": "execute transaction failed", e))?;
        Ok(())
    }
    
    fn pick_fish(&self, identity: &str) -> YRes<Option<Fish>> {
        let mut conn = self.get_conn()?;
        let fish_list = self.fish__pick(&mut conn, identity).map_err(|e| 
            err!(DataBaseError::"pick fish", identity, e)
        )?;
        if fish_list.is_empty() {
            return Ok(None);
        }
        if fish_list.len() > 1 {
            return Err(err!(DataBaseError::"pick fish": "found more than one fish", identity));
        }
        let fish = fish_list.into_iter().next().unwrap();
        Ok(Some(Fish::try_from(fish)?))
    }

    fn page_fish(
        &self, fuzzy: Option<String>, identitys: Option<Vec<String>>, count: Option<i32>,
        fish_types: Option<Vec<touchfish_core::FishType>>, desc: Option<String>,
        tags: Option<Vec<String>>, is_marked: Option<bool>, is_locked: Option<bool>,
        passed_hours: Option<i32>, page_num: i32, page_size: i32,
    ) -> YRes<Page<Fish>> {
        let mut conn = self.get_conn()?;
        let mut selecter = FishSelecter::new(
            fuzzy, identitys, count, fish_types, desc, tags, is_marked, is_locked, passed_hours, Some((page_num, page_size),)
        )?;
        let fish_list = self.fish__select(&mut conn, &selecter)
            .map_err(|e| err!(DataBaseError::"page fish", e))?;
        selecter.set_page(None)?;
        let total_count = self.fish__count(&mut conn, &selecter)
            .map_err(|e| err!(DataBaseError::"page fish", e))?;
        let data = fish_list
            .into_iter()
            .map(|x| Fish::try_from(x))
            .collect::<YRes<Vec<_>>>()?;
        Ok(Page { total_count, page_num, page_size, data })
    }
    
    fn detect_fish(
        &self, fuzzy: Option<String>, identitys: Option<Vec<String>>, count: Option<i32>,
        fish_types: Option<Vec<FishType>>, desc: Option<String>, tags: Option<Vec<String>>, 
        is_marked: Option<bool>, is_locked: Option<bool>, passed_hours: Option<i32>, 
    ) -> YRes<Vec<String>> {
        let mut conn = self.get_conn()?;
        let selecter = FishSelecter::new(
            fuzzy, identitys, count, fish_types, desc, tags, is_marked, is_locked, passed_hours, None,
        )?;
        self.fish__select_identity(&mut conn, &selecter).map_err(|e| err!(DataBaseError::"detect fish", e))
    }
    
    fn count_fish(&self) -> YRes<Statistics> {
        let mut conn = self.get_conn()?;
        let mut selecter = FishSelecter::empty();
        let count__active = self.fish__count(& mut conn, &selecter).map_err(|e| 
            err!(DataBaseError::"count fish": "count active fish failed", e)
        )? as i32;
        let count__expired = self.expired_fish__count(& mut conn, &selecter).map_err(|e| 
            err!(DataBaseError::"count fish": "count expired fish failed", e)
        )? as i32;
        let count__by_type = self.fish__count_by_type(&mut conn).map_err(|e|
            err!(DataBaseError::"count fish": "count by type failed", e)
        )?;
        let count__by_type = count__by_type.into_iter()
            .map(|x| FishType::new(&x.fish_type).map(|y|(y, x.count)))
            .collect::<YRes<HashMap<FishType, i32>>>()?;
        let count__by_tag = self.fish__count_by_tag(&mut conn).map_err(|e| 
            err!(DataBaseError::"count fish": "count by tag failed", e)
        )?;
        let count__by_tag: HashMap<String, i32> = count__by_tag.into_iter()
            .map(|x| (x.tag, x.count)).collect();
        selecter.is_marked = Some(true);
        let count__marked = self.fish__count(& mut conn, &selecter).map_err(|e| 
            err!(DataBaseError::"count fish": "count marked failed", e)
        )? as i32;
        selecter.is_marked = Some(false);
        let count__unmarked = self.fish__count(& mut conn, &selecter).map_err(|e| 
            err!(DataBaseError::"count fish": "count unmarked failed", e)
        )? as i32;
        selecter.is_marked = None;
        selecter.is_locked = Some(true);
        let count__locked = self.fish__count(& mut conn, &selecter).map_err(|e| 
            err!(DataBaseError::"count fish": "count locked failed", e)
        )? as i32;
        selecter.is_locked = Some(false);
        let count__unlocked = self.fish__count(& mut conn, &selecter).map_err(|e| 
            err!(DataBaseError::"count fish": "count unlocked failed", e)
        )? as i32;
        let count_fish_by_day = self.fish__count_by_day(&mut conn).map_err(|e| 
            err!(DataBaseError::"count fish": "count fish by day failed", e)
        )?;
        let count_expired_fish_by_day = self.fish_expired__count_by_day(&mut conn).map_err(|e| 
            err!(DataBaseError::"count fish": "count expired fish by day failed", e)
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

