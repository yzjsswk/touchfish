create table fish (
    id integer PRIMARY KEY AUTOINCREMENT NOT NULL,
    identity varchar(64) NOT NULL,
    count integer NOT NULL,
    fish_type varchar(16) NOT NULL,
    fish_data blob NOT NULL,
    data_info text NOT NULL,
    desc text NOT NULL,
    tags text NOT NULL,
    is_marked boolean NOT NUll,
    is_locked boolean NOT NUll,
    extra_info text NOT NULL,
    create_time varchar(64) NOT NULL,
    update_time varchar(64) NOT NULL,
    CONSTRAINT unique_data UNIQUE (identity)
);

create index idx__identity on fish (identity);
create index idx__update_time on fish (update_time);

create table fish_expired (
    id integer PRIMARY KEY NOT NULL,
    identity varchar(64) NOT NULL,
    count integer NOT NULL,
    fish_type varchar(16) NOT NULL,
    fish_data blob NOT NULL,
    data_info text NOT NULL,
    desc text NOT NULL,
    tags text NOT NULL,
    is_marked boolean NOT NUll,
    is_locked boolean NOT NUll,
    extra_info text NOT NULL,
    create_time varchar(64) NOT NULL,
    update_time varchar(64) NOT NULL,
    expire_time varchar(64) NOT NULL
);
