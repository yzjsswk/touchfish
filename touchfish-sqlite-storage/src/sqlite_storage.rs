use std::collections::HashMap;
use std::time::Duration;

use diesel::connection::SimpleConnection;
use diesel::dsl::sql;
use diesel::{prelude::*, sql_query};
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

    pub fn connect(db_url: &str, init_db_if_not_exits: bool) -> YRes<Self> {
        let init_table = if std::path::Path::new(db_url).exists() {
            false
        } else {
            if !init_db_if_not_exits {
                return Err(err!("connect to sqlite failed").trace(
                    ctx!("connect to sqlite -> db_url not exists && init_db=false", db_url, init_db_if_not_exits)
                ));
            }
            true
        };
        let manager = ConnectionManager::<SqliteConnection>::new(db_url);
        let pool = r2d2::Pool::builder()
            .max_size(8)
            .connection_timeout(Duration::new(5, 0))
            .build(manager)
            .map_err(|e| err!("connect to sqlite failed").trace(
                ctx!("connect to sqlite -> build connection pool: r2d2::Pool::build() failed", db_url, init_db_if_not_exits, e)
            ))?;
        let storage = SqliteStorage { pool };
        if init_table {
            storage.init_table().trace(
                ctx!("connect to sqlite -> db_url not exists && init_db=true -> init tables: storage.init_table() failed", db_url, init_db_if_not_exits)
            )?;
        }
        Ok(storage)
    }

    pub fn get_conn(&self) -> YRes<PooledConnection<ConnectionManager<SqliteConnection>>> {
        let mut conn = self.pool.get().map_err(|e|
            err!("get connection from pool failed").trace(
                ctx!("get connection from pool: pool.get() failed", e)
            )
        )?;
        conn.batch_execute("PRAGMA busy_timeout = 5000;").map_err(|e|
            err!("get connection from pool failed").trace(
                ctx!("get connection from pool -> set connection timeout: conn.batch_execute() failed", e)
            )
        )?;
        Ok(conn)
    }

    pub fn init_table(&self) -> YRes<()> {
        let sqls = [r#"
create table fish (
    id integer PRIMARY KEY AUTOINCREMENT NOT NULL,
    identity varchar(64) NOT NULL,
    count integer NOT NULL DEFAULT 1,
    fish_type varchar(16) NOT NULL,
    fish_data blob NOT NULL,
    data_info text NOT NULL,
    desc text NOT NULL DEFAULT '',
    tags text NOT NULL DEFAULT '',
    is_marked tinyint NOT NUll DEFAULT 0,
    is_locked tinyint NOT NUll DEFAULT 0,
    extra_info text NOT NULL DEFAULT '',
    create_time varchar(64) NOT NULL,
    update_time varchar(64) NOT NULL,
    CONSTRAINT unique_data UNIQUE (identity)
);
            "#, r#"
create index idx__identity on fish (identity);
            "#, r#"
create index idx__update_time on fish (update_time);
            "#, r#"
create table fish_expired (
    id integer PRIMARY KEY NOT NULL,
    identity varchar(64) NOT NULL,
    count integer NOT NULL,
    fish_type varchar(16) NOT NULL,
    fish_data blob NOT NULL,
    data_info text NOT NULL,
    desc text NOT NULL,
    tags text NOT NULL,
    is_marked tinyint NOT NUll,
    is_locked tinyint NOT NUll,
    extra_info text NOT NULL,
    create_time varchar(64) NOT NULL,
    update_time varchar(64) NOT NULL,
    expire_time varchar(64) NOT NULL
);
            "#,
        ];
        let mut conn = self.get_conn().trace(
            ctx!("init table -> get connection: self.get_conn() failed")
        )?;
        conn.transaction::<_, YError, _>(|conn| {
            for sql in sqls {
                diesel::sql_query(sql).execute(conn).map_err(|e| e.into()).trace(
                    ctx!("init table -> execute sql in transaction: diesel execute failed", sql)
                )?;
            }
            Ok(())
        })?;
        Ok(())
    }

    fn fish__insert(&self, conn: &mut SqliteConnection, inserter: &FishInserter) -> YRes<FishModel> {
        let inserted = diesel::insert_into(fish::table)
            .values(inserter)
            .returning(FishModel::as_returning())
            .get_result(conn).map_err(|e| e.into()).trace(
                ctx!("fish__insert: diesel execute failed")
            )?;
        Ok(inserted)
    }

    #[allow(unused)]
    fn fish__delete(&self, conn: &mut SqliteConnection, id: i32) -> YRes<usize> {
        let cnt = diesel::delete(fish::table.filter(fish::id.eq(id))).execute(conn).map_err(|e| e.into()).trace(
            ctx!("fish__delete: diesel execute failed")
        )?;
        Ok(cnt)
    }

    fn fish__delete_batch(&self, conn: &mut SqliteConnection, ids: &Vec<i32>) -> YRes<usize> {
        let cnt = diesel::delete(fish::table.filter(fish::id.eq_any(ids))).execute(conn).map_err(|e| e.into()).trace(
            ctx!("fish__delete_batch: diesel execute failed")
        )?;
        Ok(cnt)
    }

    fn fish__update(&self, conn: &mut SqliteConnection, identity: &str, updater: &FishUpdater) -> YRes<usize> {
        diesel::update(fish::table.filter(fish::identity.eq(identity)))
            .set(updater)
            .execute(conn).map_err(|e| e.into()).trace(
                ctx!("fish__update: diesel execute failed")
            )
    }

    fn fish__update_batch(&self, conn: &mut SqliteConnection, identitys: &Vec<&str>, updater: &FishUpdater) -> YRes<usize> {
        diesel::update(fish::table.filter(fish::identity.eq_any(identitys)))
            .set(updater)
            .execute(conn).map_err(|e| e.into()).trace(
                ctx!("fish__update_batch: diesel execute failed")
            )
    }

    #[allow(unused)]
    fn fish__inc_cnt(&self, conn: &mut SqliteConnection, identity: &str) -> YRes<usize> {
        diesel::update(fish::table.filter(fish::identity.eq(identity)))
        .set(fish::count.eq(fish::count+1))
        .execute(conn).map_err(|e| e.into()).trace(
            ctx!("fish__inc_cnt: diesel execute failed")
        )
    }

    fn fish__inc_cnt_batch(&self, conn: &mut SqliteConnection, identitys: &Vec<&str>) -> YRes<usize> {
        diesel::update(fish::table.filter(fish::identity.eq_any(identitys)))
        .set(fish::count.eq(fish::count+1))
        .execute(conn).map_err(|e| e.into()).trace(
            ctx!("fish__inc_cnt_batch: diesel execute failed")
        )
    }

    #[allow(unused)]
    fn fish__dec_cnt(&self, conn: &mut SqliteConnection, identity: &str) -> YRes<usize> {
        diesel::update(fish::table.filter(fish::identity.eq(identity)))
        .set(fish::count.eq(fish::count-1))
        .execute(conn).map_err(|e| e.into()).trace(
            ctx!("fish__dec_cnt: diesel execute failed")
        )
    }

    fn fish__dec_cnt_batch(&self, conn: &mut SqliteConnection, identitys: &Vec<&str>) -> YRes<usize> {
        diesel::update(fish::table.filter(fish::identity.eq_any(identitys)))
        .set(fish::count.eq(fish::count-1))
        .execute(conn).map_err(|e| e.into()).trace(
            ctx!("fish__dec_cnt_batch: diesel execute failed")
        )
    }

    fn fish__pick(&self, conn: &mut SqliteConnection, identity: &str) -> YRes<Vec<FishModel>> {
        let selected: Vec<FishModel> = fish::dsl::fish
            .filter(fish::identity.eq(identity))
            .select(FishModel::as_select())
            .load(conn).map_err(|e| e.into()).trace(
                ctx!("fish__pick: diesel execute failed")
            )?;
        Ok(selected)
    }

    fn fish__select(&self, conn: &mut SqliteConnection, selecter: &FishSelecter) -> YRes<Vec<FishModel>> {
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

    fn fish__select_identity(&self, conn: &mut SqliteConnection, selecter: &FishSelecter) -> YRes<Vec<String>> {
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

    fn fish__count(&self, conn: &mut SqliteConnection, selecter: &FishSelecter) -> YRes<i64> {
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

    fn expired_fish__count(&self, conn: &mut SqliteConnection, selecter: &FishSelecter) -> YRes<i64> {
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

    fn fish_expired__insert(&self, conn: &mut SqliteConnection, inserter: &FishExpiredInserter) -> YRes<FishExpiredModel> {
        let inserted = diesel::insert_into(fish_expired::table)
            .values(inserter)
            .returning(FishExpiredModel::as_returning())
            .get_result(conn).map_err(|e| e.into()).trace(
                ctx!("fish_expired__insert: diesel execute failed")
            )?;
        Ok(inserted)
    }

    fn fish__count_by_type(&self, conn: &mut SqliteConnection) -> YRes<Vec<CountByType>> {
        let query = sql_query("select fish_type, count(*) as count from fish group by fish_type;");
        query.load::<CountByType>(conn).map_err(|e| e.into()).trace(
            ctx!("fish__count_by_type: diesel execute failed")
        )
    }

    fn fish__count_by_tag(&self, conn: &mut SqliteConnection) -> YRes<Vec<CountByTag>> {
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

    fn fish__count_by_day(&self, conn: &mut SqliteConnection) -> YRes<Vec<CountByDay>> {
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

    fn fish_expired__count_by_day(&self, conn: &mut SqliteConnection) -> YRes<Vec<CountByDay>> {
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

