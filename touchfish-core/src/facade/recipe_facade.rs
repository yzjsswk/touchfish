use crate::{RecipeService, Recipe};
use yfunc_rust::prelude::*;

pub struct RecipeFacade {
    recipe_service: RecipeService,
}

impl RecipeFacade {

    pub fn new(folder_path: &str) -> RecipeFacade {
        RecipeFacade {  
            recipe_service: RecipeService::new(folder_path),
        }
    }

    pub fn get_recipe_list(&self) -> YRes<Vec<Recipe>> {
        Ok(self.recipe_service.list())
    }

}