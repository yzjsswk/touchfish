use actix_web::HttpResponse;
use serde::{Deserialize, Serialize};
use yfunc_rust::YRes;

#[derive(Debug, Serialize, Deserialize)]
pub struct Resp<T> {
    pub status: String,
    pub data: Option<T>,
}

impl<T> Resp<T> {
    pub fn ok(data: T) -> Resp<T> {
        Resp {
            status: String::from("Ok"),
            data: Some(data),
        }
    }

    pub fn err(msg: &str) -> Resp<T> {
        Resp {
            status: msg.to_string(),
            data: None,
        }
    }
}

pub trait ToResp {
    fn to_resp(&self) -> HttpResponse;
}

impl<T> ToResp for YRes<T> where T: Serialize {
    fn to_resp(&self) -> HttpResponse {
        match self {
            Ok(data) => HttpResponse::Ok().json(Resp::ok(data)),
            Err(err) => {
                log::error!("{:?}", err);
                HttpResponse::BadRequest().json(Resp::<Vec<String>>::err(&err.to_string()))
            },
        }
    }
}
