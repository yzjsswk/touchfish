use std::{collections::HashMap, sync::Arc};

use crate::{Recipe, RecipeCache, RecipeExecuteResult, RecipeService};
use yfunc_rust::prelude::*;

pub struct RecipeApi<C> where C: RecipeCache+Sync+Send+'static {
    recipe_service: Arc<RecipeService<C>>,
}

impl<C> RecipeApi<C> where C: RecipeCache+Sync+Send+'static {

    pub fn new(folder_path: &str, cache: C) -> RecipeApi<C> {
        RecipeApi {  
            recipe_service: Arc::new(RecipeService::new(folder_path, cache)),
        }
    }

    pub fn get_recipe_list(&self) -> YRes<Vec<Recipe>> {
        self.recipe_service.list().trace(
            ctx!("get recipe list: self.recipe_service.list() failed")
        )
    }

    pub async fn execute(&self, bundle_id: &str, command: &str, args: &Vec<String>, context: &HashMap<String, String>) -> YRes<String> {
        Arc::clone(&self.recipe_service).execute(bundle_id, command, args, context).await.trace(
            ctx!("execute recipe: self.recipe_service.execute failed")
        )
    }

    pub async fn fetch_execute_result(&self, execute_uid: &str) -> YRes<Option<RecipeExecuteResult>> {
        self.recipe_service.fetch_execute_result(execute_uid).await.trace(
            ctx!("fetch execute result: self.recipe_service.fetch_execute_result failed")
        )
    }

}
