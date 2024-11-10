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
        self.recipe_service.list()
    }

    pub fn execute(&self, bundle_id: &str, command: &str, args: &Vec<String>) -> YRes<String> {
        self.recipe_service.execute(bundle_id, command, args)
    }

}