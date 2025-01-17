use actix_web::{get, middleware::Logger, post, web::{Data, Json, Path}, App, HttpServer, Responder};
use req::ExecuteRecipeReq;
use resp::ToResp;
use touchfish_core::RecipeApi;
use touchfish_redis_cache::RedisCache;
use yfunc_rust::prelude::*;

mod req;
mod resp;

#[get("/heartbeat")]
async fn heart_beat() -> impl Responder {
    YRes::Ok(()).to_resp()
}

#[get("/recipe/list")]
async fn list_recipe(recipe_api: Data<RecipeApi<RedisCache>>) -> impl Responder {
    recipe_api.get_recipe_list().to_resp()
}

#[post("/recipe/execute")]
async fn execute_recipe(recipe_api: Data<RecipeApi<RedisCache>>, req: Json<ExecuteRecipeReq>) -> impl Responder {
    recipe_api.execute(&req.bundle_id, &req.command, &req.args, &req.context).await.to_resp()
}

#[get("/recipe/fetch_result/{execute_uid}")]
async fn fetch_execute_result(recipe_api: Data<RecipeApi<RedisCache>>, execute_uid: Path<String>) -> impl Responder {
    recipe_api.fetch_execute_result(&execute_uid).await.to_resp()
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init();
    let port = match std::env::var("TFRS_PORT") {
        Ok(v) => v.parse().expect(&format!("env var TFRS_PORT parse failed, TFRS_PORT={}", v)),
        Err(_) => 56189,
    };
    let folder_path = std::env::var("TFRS_RECIPE_FOLDER").expect("recipe folder path is required");
    let redis_uri = std::env::var("TFRS_REDIS_URI").expect("environment variable TFRS_REDIS_URI is required");
    let redis_cache = RedisCache::new(&redis_uri).expect("connect to redis failed");
    let recipe_api = Data::new(RecipeApi::new(&folder_path, redis_cache));
    HttpServer::new(move || {
        App::new()
            .wrap(Logger::default())
            .app_data(recipe_api.clone())
            .service(heart_beat)
            .service(list_recipe)
            .service(execute_recipe)
            .service(fetch_execute_result)
    })
    .bind(("0.0.0.0", port))?
    .run()
    .await
}
