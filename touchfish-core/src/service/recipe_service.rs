use std::{collections::HashMap, path::Path};

use yfunc_rust::prelude::*;

use crate::Recipe;

pub struct RecipeService {
    pub folder_path: String,
    pub recipes_cache: HashMap<String, String>,
}

impl RecipeService {

    pub fn new(folder_path: &str) -> RecipeService {
        RecipeService { 
            folder_path: folder_path.to_string(),
            recipes_cache: HashMap::new(),
        }
    }

    pub fn list(&self) -> Vec<Recipe> {
        walkdir::WalkDir::new(&self.folder_path).into_iter().fold(vec![], |mut acc, it| {
            let Ok(dir) = it else { 
                // todo: log
                return acc;
            };
            if dir.file_type().is_dir() || dir.file_name() != "Recipe.toml" {
                return acc;
            };
            let Ok(content) = std::fs::read_to_string(dir.path()) else {
                // todo: log
                return acc;
            };
            let Ok(recipe) = toml::from_str(&content) else {
                // todo: log
                return acc;
            };
            acc.push(recipe);
            return acc;
        })
    }

    pub fn execute(&mut self, bundle_id: &str) -> YRes<()> {
        if self.recipes_cache.contains_key(bundle_id) {

        }
        Ok(())
    }

    // fn load_recipe_from_file(&self, file_path: &Path) -> YRes<Recipe> {
    //     let content = std::fs::read_to_string(file_path).map_err(|e| {
    //         err!(IOError::"load recipe from file -> read file content": e)
    //     })?;
    //     let Ok(recipe) = toml::from_str(&content) else {
    //         // todo: log
    //         return acc;
    //     };
    // }

}
