#![allow(non_snake_case)]
#![allow(non_upper_case_globals)]

mod facade;
mod domain;
mod infra;
mod service;

use service::{FishService, RecipeService};

pub use facade::{FishFacade, RecipeFacade};
pub use infra::FishStorage;
pub use domain::*;
