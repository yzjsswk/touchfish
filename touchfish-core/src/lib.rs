#![allow(non_snake_case)]
#![allow(non_upper_case_globals)]

mod facade;
mod domain;
mod infra;
mod service;

pub use facade::{FishFacade, RecipeFacade};
pub use domain::*;
pub use infra::FishStorage;
pub use service::{FishService, RecipeService};
