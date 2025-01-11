#![allow(non_snake_case)]
#![allow(non_upper_case_globals)]
#![allow(async_fn_in_trait)]

mod api;
mod service;
mod infra;
mod domain;

pub use api::{FishApi, RecipeApi, TopicApi};
use service::{FishService, RecipeService};
pub use infra::{FishStorage, TopicStorage, RecipeCache};
pub use domain::*;