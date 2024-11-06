use actix_web::{get, middleware::Logger, post, web::{Json, Path}, App, HttpServer, Responder};
use once_cell::sync::Lazy;
use req::{AddFishReq, DelectFishReq, ExpireFishReq, LockFishReq, MarkFishReq, ModifyFishReq, PinFishReq, SearchFishReq, UnlockFishReq, UnmarkFishReq};
use resp::ToResp;
use touchfish_core::FishApi;
use touchfish_sqlite_storage::SqliteStorage;
use yfunc_rust::{prelude::*, YBytes};

mod req;
mod resp;

static API: Lazy<FishApi<SqliteStorage>> = Lazy::new(|| {
    let db_url = std::env::var("TFDS_DB_URL")
        .expect("database url is required");
    let do_init = match std::env::var("TFDS_INIT") {
        Ok(x) => x.parse().expect(&format!("parse env var TFDS_INIT failed, TFDS_INIT={x}")),
        Err(_) => false,   
    };
    let storage: SqliteStorage = SqliteStorage::connect(&db_url, do_init)
        .expect("connect to data base failed");
    let api = FishApi::new(storage)
        .expect("init fish api failed");
    api
});

#[post("/fish/search")]
async fn search_fish(req: Json<SearchFishReq>) -> impl Responder {
    API.search_fish(
        req.fuzzy.clone(), req.identity.clone(), req.fish_type.clone(), req.desc.clone(),
        req.tags.clone(), req.is_marked, req.is_locked, req.passed_hours, req.page_num, req.page_size,
    ).to_resp()
}

#[post("/fish/delect")]
async fn delect_fish(req: Json<DelectFishReq>) -> impl Responder {
    API.detect_fish(
        req.fuzzy.clone(), req.identity.clone(), req.fish_type.clone(), req.desc.clone(),
        req.tags.clone(), req.is_marked, req.is_locked, req.passed_hours,
    ).to_resp()
}

#[get("/fish/pick/{identity}")]
async fn pick_fish(identity: Path<String>) -> impl Responder {
    API.pick_fish(&identity).to_resp()
}

#[get("/fish/count")]
async fn count_fish() -> impl Responder {
    API.count_fish().to_resp()
}

#[post("/fish/add")]
async fn add_fish(req: Json<AddFishReq>) -> impl Responder {
    let res = YBytes::from_base64(&req.fish_data);
    if let Ok(fish_data) = res {
        return API.add_fish(
            req.fish_type, fish_data, req.desc.clone(), req.tags.clone(),
            req.is_marked, req.is_locked, req.extra_info.clone(),
        ).to_resp()
    }
    return res.trace(ctx!("add fish": "decode fish data failed")).to_resp()
}

#[post("/fish/modify")]
async fn modify_fish(req: Json<ModifyFishReq>) -> impl Responder {
    API.modify_fish(
        &req.identity, req.desc.clone(), req.tags.clone(), req.extra_info.clone(),
    ).to_resp()
}

#[post("/fish/expire")]
async fn expire_fish(req: Json<ExpireFishReq>) -> impl Responder {
    API.expire_fish(
        req.identitys.iter().map(|x| x.as_str()).collect(), req.skip_if_not_exists, req.skip_if_locked,
    ).to_resp()
}

#[post("/fish/mark")]
async fn mark_fish(req: Json<MarkFishReq>) -> impl Responder {
    API.mark_fish(
        req.identitys.iter().map(|x| x.as_str()).collect(), req.skip_if_not_exists, req.skip_if_locked,
    ).to_resp()
}

#[post("/fish/unmark")]
async fn unmark_fish(req: Json<UnmarkFishReq>) -> impl Responder {
    API.unmark_fish(
        req.identitys.iter().map(|x| x.as_str()).collect(), req.skip_if_not_exists, req.skip_if_locked,
    ).to_resp()
}

#[post("/fish/lock")]
async fn lock_fish(req: Json<LockFishReq>) -> impl Responder {
    API.lock_fish(
        req.identitys.iter().map(|x| x.as_str()).collect(), req.skip_if_not_exists,
    ).to_resp()
}

#[post("/fish/unlock")]
async fn unlock_fish(req: Json<UnlockFishReq>) -> impl Responder {
    API.unlock_fish(
        req.identitys.iter().map(|x| x.as_str()).collect(), req.skip_if_not_exists,
    ).to_resp()
}

#[post("/fish/pin")]
async fn pin_fish(req: Json<PinFishReq>) -> impl Responder {
    API.pin_fish(
        req.identitys.iter().map(|x| x.as_str()).collect(), req.skip_if_not_exists, req.skip_if_locked,
    ).to_resp()
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init();
    let port = match std::env::var("TFDS_PORT") {
        Ok(v) => v.parse().expect(&format!("env var TFDS_PORT parse failed, TFDS_PORT={}", v)),
        Err(_) => 56173,
    };
    let _ = &*API;
    HttpServer::new(|| {
        App::new()
            .wrap(Logger::default())
            .service(search_fish)
            .service(delect_fish)
            .service(pick_fish)
            .service(count_fish)
            .service(add_fish)
            .service(modify_fish)
            .service(expire_fish)
            .service(mark_fish)
            .service(unmark_fish)
            .service(lock_fish)
            .service(unlock_fish)
            .service(pin_fish)
    })
    .bind(("0.0.0.0", port))?
    .run()
    .await
}