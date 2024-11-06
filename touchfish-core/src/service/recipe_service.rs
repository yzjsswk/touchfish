use yfunc_rust::prelude::*;

use crate::Recipe;

pub struct RecipeService {
    pub folder_path: String,
}

impl RecipeService {

    pub fn new(folder_path: &str) -> RecipeService {
        RecipeService { folder_path: folder_path.to_string() }
    }

    pub fn list(&self) -> Vec<Recipe> {
        walkdir::WalkDir::new(&self.folder_path).into_iter().fold(vec![], |mut acc, it| {
            let Ok(dir) = it else { 
                // todo: log
                return acc;
            };
            if dir.file_type().is_dir() || dir.file_name() != "Recipe.toml" {
                // todo: log
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

}
