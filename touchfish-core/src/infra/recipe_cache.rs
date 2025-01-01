use std::{collections::HashMap, future::Future, path::PathBuf};

use yfunc_rust::prelude::*;

use crate::RecipeExecuteResult;

pub trait RecipeCache {

    async fn set_recipe_pathes(&self, recipe_pathes: &HashMap<String, PathBuf>, expire_seconds: Option<u64>) -> YRes<()>;
    
    async fn get_recipe_path(&self, bundle_id: &str) -> YRes<Option<PathBuf>>;

    fn set_recipe_execute_result(
        &self, execute_uid: &str, result: &RecipeExecuteResult, expire_seconds: Option<u64>,
    ) -> impl Future<Output = YRes<()>> + Send;

    async fn get_recipe_execute_result(&self, execute_uid: &str) -> YRes<Option<RecipeExecuteResult>>;

}