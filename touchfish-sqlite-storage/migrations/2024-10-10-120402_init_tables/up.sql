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

create index idx__fish__identity on fish (identity);
create index idx__fish__update_time on fish (update_time);

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

create table topic (
    id integer PRIMARY KEY AUTOINCREMENT NOT NULL,
    topic_type varchar(16) NOT NULL,
    subject varchar(64) NOT NULL,
    title text NOT NULL,
    extra_info text NOT NULL,
    create_time varchar(64) NOT NULL,
    update_time varchar(64) NOT NULL,
    CONSTRAINT unique_subject UNIQUE (subject)
);

create index idx__topic__identity on topic (subject);
create index idx__topic__update_time on topic (update_time);

create table message (
    id integer PRIMARY KEY AUTOINCREMENT NOT NULL,
    topic_id integer NOT NULL,
    level varchar(16) NOT NULL,
    source varchar(64) NOT NULL,
    title text NOT NULL,
    body text NOT NULL,
    has_read boolean NOT NULL,
    extra_info text NOT NULL,
    create_time varchar(64) NOT NULL,
    update_time varchar(64) NOT NULL
);

create index idx__message__update_time on message (update_time);
