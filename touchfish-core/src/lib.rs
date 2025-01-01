#![allow(non_snake_case)]
#![allow(non_upper_case_globals)]
#![allow(async_fn_in_trait)]

mod facade;
mod domain;
mod infra;
mod service;

use service::{FishService, RecipeService};

pub use facade::{FishApi, RecipeApi, TopicApi};
pub use infra::{FishStorage, TopicStorage, RecipeCache};
pub use domain::*;