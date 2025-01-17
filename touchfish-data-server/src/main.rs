use actix_web::{get, middleware::Logger, post, web::{Data, Json, Path}, App, HttpServer, Responder};
use req::{AddFishReq, CreateTopicReq, DelectFishReq, ExpireFishReq, LockFishReq, MarkFishReq, ModifyFishReq, PinFishReq, ReadMessageReq, SearchFishReq, SendMessageReq, UnlockFishReq, UnmarkFishReq};
use resp::ToResp;
use touchfish_core::{FishApi, TopicApi};
use touchfish_mongo_storage::MongoStorage;
use yfunc_rust::{prelude::*, YBytes};

mod req;
mod resp;

#[get("/heartbeat")]
async fn heart_beat() -> impl Responder {
    YRes::Ok(()).to_resp()
}

#[post("/fish/search")]
async fn search_fish(fish_api: Data<FishApi<MongoStorage>>, req: Json<SearchFishReq>) -> impl Responder {
    let fuzzy = req.fuzzy.as_ref().map(|x| x.as_str());
    let identitys = req.identitys.as_ref().map(|x| x.into_iter().map(|y| y.as_str()).collect::<Vec<&str>>());
    let desc = req.desc.as_ref().map(|x| x.as_str());
    let tags = req.tags.as_ref().map(|x| x.into_iter().map(|y| y.as_str()).collect::<Vec<&str>>());
    fish_api.search_fish(
        fuzzy, identitys.as_ref(), req.fish_types.as_ref(), desc,
        tags.as_ref(), req.is_marked, req.is_locked, 
        req.create_after, req.create_before, req.update_after, req.update_before,
        req.page_num, req.page_size,
    ).await.to_resp()
}

#[post("/fish/delect")]
async fn delect_fish(fish_api: Data<FishApi<MongoStorage>>, req: Json<DelectFishReq>) -> impl Responder {
    let fuzzy = req.fuzzy.as_ref().map(|x| x.as_str());
    let identitys = req.identitys.as_ref().map(|x| x.into_iter().map(|y| y.as_str()).collect::<Vec<&str>>());
    let desc = req.desc.as_ref().map(|x| x.as_str());
    let tags = req.tags.as_ref().map(|x| x.into_iter().map(|y| y.as_str()).collect::<Vec<&str>>());
    fish_api.detect_fish(
        fuzzy, identitys.as_ref(), req.fish_types.as_ref(), desc,
        tags.as_ref(), req.is_marked, req.is_locked,
        req.create_after, req.create_before, req.update_after, req.update_before,
    ).await.to_resp()
}

#[get("/fish/pick/{uid}")]
async fn pick_fish(fish_api: Data<FishApi<MongoStorage>>, uid: Path<String>) -> impl Responder {
    fish_api.pick_fish(&uid).await.to_resp()
}

#[get("/fish/pick_by_identity/{identity}")]
async fn pick_fish_by_identity(fish_api: Data<FishApi<MongoStorage>>, identity: Path<String>) -> impl Responder {
    fish_api.pick_fish_by_identity(&identity).await.to_resp()
}

#[get("/fish/count")]
async fn count_fish(fish_api: Data<FishApi<MongoStorage>>) -> impl Responder {
    fish_api.count_fish().await.to_resp()
}

#[post("/fish/add")]
async fn add_fish(fish_api: Data<FishApi<MongoStorage>>, req: Json<AddFishReq>) -> impl Responder {
    let res = YBytes::from_base64(&req.fish_data);
    if let Ok(fish_data) = res {
        let desc = req.desc.as_ref().map(|x| x.as_str());
        let tags = req.tags.as_ref().map(|x| x.into_iter().map(|y| y.as_str()).collect::<Vec<&str>>());
        let extra_info = req.extra_info.as_ref().map(|x| x.as_str());
        return fish_api.add_fish(
            req.fish_type, fish_data, desc, tags.as_ref(),
            req.is_marked, req.is_locked, extra_info,
        ).await.to_resp()
    }
    return res.upgrade(
        err!("DATA_INVALID": "decode fish data failed, fish data should be a base64 encoded text")
    ).trace(
        ctx!("add fish -> decode fish data as base64 encoded string: YBytes::from_base64 failed")
    ).to_resp()
}

#[post("/fish/modify")]
async fn modify_fish(fish_api: Data<FishApi<MongoStorage>>, req: Json<ModifyFishReq>) -> impl Responder {
    let desc = req.desc.as_ref().map(|x| x.as_str());
    let tags = req.tags.as_ref().map(|x| x.into_iter().map(|y| y.as_str()).collect::<Vec<&str>>());
    let extra_info = req.extra_info.as_ref().map(|x| x.as_str());
    fish_api.modify_fish(&req.uid, desc, tags.as_ref(), extra_info).await.to_resp()
}

#[post("/fish/expire")]
async fn expire_fish(fish_api: Data<FishApi<MongoStorage>>, req: Json<ExpireFishReq>) -> impl Responder {
    let uids: Vec<&str> = req.uids.iter().map(|uid| uid.as_str()).collect();
    fish_api.expire_fish(&uids, req.skip_if_not_exists, req.skip_if_locked).await.to_resp()
}

#[post("/fish/mark")]
async fn mark_fish(fish_api: Data<FishApi<MongoStorage>>, req: Json<MarkFishReq>) -> impl Responder {
    let uids: Vec<&str> = req.uids.iter().map(|uid| uid.as_str()).collect();
    fish_api.mark_fish(&uids, req.skip_if_not_exists, req.skip_if_locked).await.to_resp()
}

#[post("/fish/unmark")]
async fn unmark_fish(fish_api: Data<FishApi<MongoStorage>>, req: Json<UnmarkFishReq>) -> impl Responder {
    let uids: Vec<&str> = req.uids.iter().map(|uid| uid.as_str()).collect();
    fish_api.unmark_fish(&uids, req.skip_if_not_exists, req.skip_if_locked).await.to_resp()
}

#[post("/fish/lock")]
async fn lock_fish(fish_api: Data<FishApi<MongoStorage>>, req: Json<LockFishReq>) -> impl Responder {
    let uids: Vec<&str> = req.uids.iter().map(|uid| uid.as_str()).collect();
    fish_api.lock_fish(&uids, req.skip_if_not_exists).await.to_resp()
}

#[post("/fish/unlock")]
async fn unlock_fish(fish_api: Data<FishApi<MongoStorage>>, req: Json<UnlockFishReq>) -> impl Responder {
    let uids: Vec<&str> = req.uids.iter().map(|uid| uid.as_str()).collect();
    fish_api.unlock_fish(&uids, req.skip_if_not_exists).await.to_resp()
}

#[post("/fish/pin")]
async fn pin_fish(fish_api: Data<FishApi<MongoStorage>>, req: Json<PinFishReq>) -> impl Responder {
    let uids: Vec<&str> = req.uids.iter().map(|uid| uid.as_str()).collect();
    fish_api.pin_fish(&uids, req.skip_if_not_exists, req.skip_if_locked).await.to_resp()
}

#[post("/topic/create")]
async fn create_topic(topic_api: Data<TopicApi<MongoStorage>>, req: Json<CreateTopicReq>) -> impl Responder {
    topic_api.create_topic(req.topic_type, &req.subject, &req.source, &req.title, &req.extra_info).await.to_resp()
}

#[post("/topic/remove/{subject}")]
async fn remove_topic(topic_api: Data<TopicApi<MongoStorage>>, subject: Path<String>) -> impl Responder {
    topic_api.remove_topic(&subject).await.to_resp()
}

#[get("/topic/list")]
async fn list_topic(topic_api: Data<TopicApi<MongoStorage>>) -> impl Responder {
    topic_api.list_topic().await.to_resp()
}

#[post("/message/send")]
async fn send_message(topic_api: Data<TopicApi<MongoStorage>>, req: Json<SendMessageReq>) -> impl Responder {
    topic_api.append_message(
        &req.topic_subject, req.level, &req.title, &req.body, req.has_read, &req.extra_info,
    ).await.to_resp()
}

#[post("/message/read")]
async fn read_message(topic_api: Data<TopicApi<MongoStorage>>, req: Json<ReadMessageReq>) -> impl Responder {
    topic_api.read_message(&req.topic_uid, &req.message_uid).await.to_resp()
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init();
    let port = match std::env::var("TFDS_PORT") {
        Ok(v) => v.parse().expect(&format!("environment variable TFDS_PORT={} parse failed", v)),
        Err(_) => 56173,
    };
    let db_uri = std::env::var("TFDS_DB_URI").expect("environment variable TFDS_DB_URI is required");
    let storage = MongoStorage::new(&db_uri).await.expect("connect to database failed");
    let fish_api = Data::new(
        FishApi::new(storage.clone()).expect("init fish api failed")
    );
    let topic_api = Data::new(
        TopicApi::new(storage).expect("init topic api failed")
    );
    HttpServer::new(move || {
        App::new()
            .wrap(Logger::default())
            .app_data(fish_api.clone())
            .app_data(topic_api.clone())
            .service(heart_beat)
            .service(search_fish)
            .service(delect_fish)
            .service(pick_fish)
            .service(pick_fish_by_identity)
            .service(count_fish)
            .service(add_fish)
            .service(modify_fish)
            .service(expire_fish)
            .service(mark_fish)
            .service(unmark_fish)
            .service(lock_fish)
            .service(unlock_fish)
            .service(pin_fish)
            .service(create_topic)
            .service(remove_topic)
            .service(list_topic)
            .service(send_message)
            .service(read_message)
    })
    .bind(("0.0.0.0", port))?
    .run()
    .await
}
