use actix_web::{get, middleware::Logger, post, web::{Json, Path}, App, HttpServer, Responder};
use once_cell::sync::Lazy;
use resp::ToResp;
use touchfish_core::RecipeFacade;
use yfunc_rust::prelude::*;

mod req;
mod resp;

static FACADE: Lazy<RecipeFacade> = Lazy::new(|| {
    let folder_path = std::env::var("TFRS_RECIPE_FOLDER")
        .expect("recipe folder path is required");
    let facade = RecipeFacade::new(&folder_path);
    facade
});

#[get("/recipe/list")]
async fn list_recipe() -> impl Responder {
    FACADE.get_recipe_list().to_resp()
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init();
    let port = match std::env::var("TFRS_PORT") {
        Ok(v) => v.parse().expect(&format!("env var TFRS_PORT parse failed, TFRS_PORT={}", v)),
        Err(_) => 56189,
    };
    let _ = &*FACADE;
    HttpServer::new(|| {
        App::new()
            .wrap(Logger::default())
            .service(list_recipe)
    })
    .bind(("0.0.0.0", port))?
    .run()
    .await
}