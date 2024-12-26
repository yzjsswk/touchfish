use std::{collections::HashMap, path::{Path, PathBuf}, sync::Mutex};

use yfunc_rust::prelude::*;

use crate::Recipe;

pub struct RecipeService {
    pub folder_path: String,
    pub recipes_cache: Mutex<HashMap<String, PathBuf>>,
}

impl RecipeService {

    pub fn new(folder_path: &str) -> RecipeService {
        RecipeService { 
            folder_path: folder_path.to_string(),
            recipes_cache: Mutex::new(HashMap::new()),
        }
    }

    pub fn list(&self) -> YRes<Vec<Recipe>> {
        let recipes = walkdir::WalkDir::new(&self.folder_path).into_iter().try_fold::<_, _, YRes<_>>(HashMap::new(), |mut acc, it| {
            let Ok(dir) = it.inspect_err(|e| 
                warn!("list recipe - skip checking a file: walkdir::WalkDir::new returned Err, folder={:?}, err={:?}", self.folder_path, e)
            ) else {    
                return Ok(acc);
            };
            if dir.file_type().is_dir() || dir.file_name() != "Recipe.toml" {
                return Ok(acc);
            };
            let Ok(recipe) = self.load_recipe_from_file(dir.path()).inspect_err(|e|
                warn!("list recipe - ignore a `Recipe.toml` file: self.load_recipe_from_file returned Err, path={:?}, err={:?}", dir.path(), e)
            ) else {
                return Ok(acc);
            };
            if acc.contains_key(&recipe.bundle_id) {
                return Err(err!("list recipe failed").trace(
                    ctx!("list recipe: got same bundle id", self.folder_path, recipe.bundle_id)
                ))
            }
            acc.insert(recipe.bundle_id.clone(), recipe);
            return Ok(acc);
        })?;
        Ok(recipes.into_values().collect())
    }

    pub fn execute(&self, bundle_id: &str, command: &str, args: &Vec<String>) -> YRes<String> {
        let mut recipe_cache = self.recipes_cache.lock().map_err(|e|
            err!("execute recipe failed").trace(
                ctx!("execute recipe -> get recipe cache lock: self.recipes_cache.lock() failed", e)
            )
        )?;
        let recipe_path = if let Some(path) = recipe_cache.get(bundle_id) {
            path.clone()
        } else {
            *recipe_cache = walkdir::WalkDir::new(&self.folder_path).into_iter().try_fold::<_, _, YRes<_>>(HashMap::new(), |mut acc, it| {
                let Ok(dir) = it.inspect_err(|e| 
                    warn!("execute recipe -> bundle_id not exists in recipe cache -> rebuild recipe cache - skip checking a file: walkdir::WalkDir::new returned Err, folder={:?}, err={:?}", self.folder_path, e)
                ) else { 
                    return Ok(acc);
                };
                if dir.file_type().is_dir() || dir.file_name() != "Recipe.toml" {
                    return Ok(acc);
                };
                let Some(parent_path) = dir.path().parent() else {
                    warn!("execute recipe -> bundle_id not exists in recipe cache -> rebuild recipe cache -> get folder of a `Recipe.toml` file - ignore the `Recipe.toml` file: dir.path().parent() returned None, path={:?}", dir.path());
                    return Ok(acc);
                };
                let Ok(recipe) = self.load_recipe_from_file(dir.path()).inspect_err(|e| {
                    warn!("execute recipe -> bundle_id not exists in recipe cache -> rebuild recipe cache -> deserialize a `Recipe.toml` file - ignore the `Recipe.toml` file: self.load_recipe_from_file returned Err, path={:?}, err={:?}", dir.path(), e);
                }) else {
                    return Ok(acc);
                };
                if acc.contains_key(&recipe.bundle_id) {
                    return Err(err!("execute recipe failed").trace(
                        ctx!("execute recipe -> bundle_id not exists in recipe cache -> rebuild recipe cache -> got same bundle id", self.folder_path, recipe.bundle_id)
                    ))
                }
                acc.insert(recipe.bundle_id, parent_path.to_path_buf());
                return Ok(acc);
            })?;
            let Some(path) = recipe_cache.get(bundle_id) else {
                return Err(err!("execute recipe failed").trace(
                    ctx!("execute recipe: recipe not found", bundle_id, command, args)
                ))
            };
            path.clone()
        };
        drop(recipe_cache);
        let recipe_path = &recipe_path;
        // TODO: add execute timeout
        let output = std::process::Command::new(command)
            .args(args).current_dir(recipe_path).output().map_err(|e| {
                err!("execute recipe failed").trace(
                    ctx!("execute recipe -> execute command: std::process::Command::output failed", command, args, recipe_path, e)
                )
            })?;
        if !output.stderr.is_empty() {
            let stderr = String::from_utf8_lossy(&output.stderr).to_string();
            return Err(err!("execute recipe failed").trace(
                ctx!("execute recipe: output.stderr is not empty", stderr, recipe_path, bundle_id, command, args)
            ))
        }
        let stdout = String::from_utf8_lossy(&output.stdout).to_string();
        Ok(stdout)
    }

    fn load_recipe_from_file(&self, file_path: &Path) -> YRes<Recipe> {
        let content = std::fs::read_to_string(file_path).map_err(|e| {
            err!("load recipe from file failed").trace(
                ctx!("load recipe from file -> read file content: std::fs::read_to_string failed", file_path, e)
            )
        })?;
        let recipe: Recipe = toml::from_str(&content).map_err(|e| {
            err!("load recipe from file failed").trace(
                ctx!("load recipe from file -> deserialize file content to Recipe: toml::from_str failed", file_path, e)
            )
        })?;
        Ok(recipe)
    }

}
