use std::time::Duration;

use diesel::connection::SimpleConnection;
use diesel::prelude::*;
use diesel::{r2d2::ConnectionManager, SqliteConnection};
use r2d2::{Pool, PooledConnection};
use yfunc_rust::prelude::*;

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

}
