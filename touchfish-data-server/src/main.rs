use actix_web::{get, middleware::Logger, post, web::{Json, Path}, App, HttpServer, Responder};
use once_cell::sync::Lazy;
use req::{AddFishReq, DelectFishReq, ExpireFishReq, LockFishReq, MarkFishReq, ModifyFishReq, PinFishReq, SearchFishReq, UnlockFishReq, UnmarkFishReq};
use resp::ToResp;
use touchfish_core::TouchFishCore;
use touchfish_sqlite_storage::SqliteStorage;
use yfunc_rust::{prelude::*, YBytes};

mod req;
mod resp;

static CORE: Lazy<TouchFishCore<SqliteStorage>> = Lazy::new(|| {
    let args: Vec<String> = std::env::args().collect();
    let db_url = args.get(1)
        .expect("database url is required");
    let storage: SqliteStorage = SqliteStorage::connect(db_url)
        .expect("connect to data base failed");
    let core = TouchFishCore::new(storage)
        .expect("init touchfish core failed");
    core
});

#[post("/fish/search")]
async fn search_fish(req: Json<SearchFishReq>) -> impl Responder {
    CORE.search_fish(
        req.fuzzy.clone(), req.identity.clone(), req.fish_type.clone(), req.desc.clone(),
        req.tags.clone(), req.is_marked, req.is_locked, req.page_num, req.page_size
    ).to_resp()
}

#[post("/fish/delect")]
async fn delect_fish(req: Json<DelectFishReq>) -> impl Responder {
    CORE.detect_fish(
        req.fuzzy.clone(), req.identity.clone(), req.fish_type.clone(), req.desc.clone(),
        req.tags.clone(), req.is_marked, req.is_locked,
    ).to_resp()
}

#[get("/fish/pick/{identity}")]
async fn pick_fish(identity: Path<String>) -> impl Responder {
    CORE.pick_fish(&identity).to_resp()
}

#[get("/fish/count")]
async fn count_fish() -> impl Responder {
    CORE.count_fish().to_resp()
}

#[post("/fish/add")]
async fn add_fish(req: Json<AddFishReq>) -> impl Responder {
    let res = YBytes::from_base64(&req.fish_data);
    if let Ok(fish_data) = res {
        return CORE.add_fish(
            req.fish_type, fish_data, req.desc.clone(), req.tags.clone(),
            req.is_marked, req.is_locked, req.extra_info.clone(),
        ).to_resp()
    }
    return res.trace(ctx!("add fish": "decode fish data failed")).to_resp()
}

#[post("/fish/modify")]
async fn modify_fish(req: Json<ModifyFishReq>) -> impl Responder {
    CORE.modify_fish(
        &req.identity, req.desc.clone(), req.tags.clone(), req.extra_info.clone(),
    ).to_resp()
}

#[post("/fish/expire")]
async fn expire_fish(req: Json<ExpireFishReq>) -> impl Responder {
    CORE.expire_fish(
        req.identitys.iter().map(|x| x.as_str()).collect(), req.skip_if_not_exists, req.skip_if_locked,
    ).to_resp()
}

#[post("/fish/mark")]
async fn mark_fish(req: Json<MarkFishReq>) -> impl Responder {
    CORE.mark_fish(
        req.identitys.iter().map(|x| x.as_str()).collect(), req.skip_if_not_exists, req.skip_if_locked,
    ).to_resp()
}

#[post("/fish/unmark")]
async fn unmark_fish(req: Json<UnmarkFishReq>) -> impl Responder {
    CORE.unmark_fish(
        req.identitys.iter().map(|x| x.as_str()).collect(), req.skip_if_not_exists, req.skip_if_locked,
    ).to_resp()
}

#[post("/fish/lock")]
async fn lock_fish(req: Json<LockFishReq>) -> impl Responder {
    CORE.lock_fish(
        req.identitys.iter().map(|x| x.as_str()).collect(), req.skip_if_not_exists,
    ).to_resp()
}

#[post("/fish/unlock")]
async fn unlock_fish(req: Json<UnlockFishReq>) -> impl Responder {
    CORE.unlock_fish(
        req.identitys.iter().map(|x| x.as_str()).collect(), req.skip_if_not_exists,
    ).to_resp()
}

#[post("/fish/pin")]
async fn pin_fish(req: Json<PinFishReq>) -> impl Responder {
    CORE.pin_fish(
        req.identitys.iter().map(|x| x.as_str()).collect(), req.skip_if_not_exists, req.skip_if_locked,
    ).to_resp()
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    std::env::set_var("RUST_LOG", "debug");
    env_logger::init();
    let _ = &*CORE;
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
    .bind(("127.0.0.1", 8080))?
    .run()
    .await
}