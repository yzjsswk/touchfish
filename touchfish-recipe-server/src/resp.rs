use actix_web::HttpResponse;
use serde::{Deserialize, Serialize};
use yfunc_rust::prelude::*;

#[derive(Debug, Serialize, Deserialize)]
pub struct Resp<T> {
    pub code: String,
    pub msg: String,
    pub data: Option<T>,
}

impl<T> Resp<T> {
    pub fn ok(data: T) -> Resp<T> {
        Resp {
            code: String::from("OK"),
            msg: String::from("ok"),
            data: Some(data),
        }
    }

    pub fn err(code: &str, msg: &str) -> Resp<T> {
        Resp {
            code: code.to_string(),
            msg: msg.to_string(),
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
                error!("{:#?}", err);
                HttpResponse::BadRequest().json(Resp::<Vec<String>>::err(&err.code, &err.msg))
            },
        }
    }
}
