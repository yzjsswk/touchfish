#![allow(non_snake_case)]
#![allow(non_upper_case_globals)]

mod facade;
mod domain;
mod infra;
mod service;

use service::{FishService, RecipeService};

pub use facade::{FishApi, RecipeApi};
pub use infra::{FishStorage, TopicStorage};
pub use domain::*;