use crate::{RecipeService, Recipe};
use yfunc_rust::prelude::*;

pub struct RecipeApi {
    recipe_service: RecipeService,
}

impl RecipeApi {

    pub fn new(folder_path: &str) -> RecipeApi {
        RecipeApi {  
            recipe_service: RecipeService::new(folder_path),
        }
    }

    pub fn get_recipe_list(&self) -> YRes<Vec<Recipe>> {
        Ok(self.recipe_service.list())
    }

}