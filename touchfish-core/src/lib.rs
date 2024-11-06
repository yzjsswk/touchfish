#![allow(non_snake_case)]
#![allow(non_upper_case_globals)]

mod api;
mod domain;
mod infra;
mod service;

pub use api::{FishApi, RecipeApi};
pub use domain::*;
pub use infra::FishStorage;
pub use service::{FishService, RecipeService};
