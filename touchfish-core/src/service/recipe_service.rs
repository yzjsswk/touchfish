use std::sync::Arc;
use std::time::Duration;
use std::{collections::HashMap, path::Path, process::Stdio};
use serde_json::Value;
use tokio::process::Command;
use tokio::io::{AsyncBufReadExt, AsyncReadExt, BufReader};
use tokio::time::{timeout, Instant};
use yfunc_rust::{prelude::*, YUid};

use crate::{Recipe, RecipeCache, RecipeExecuteResult, RecipeExecuteStatus, RecipeParaType};

const RECIPE_EXECUTE_RESULT_FRAME_FLAG: &str = "<RECIPE_OUTPUT_FRAME_END>";

pub struct RecipeService<C> where C: RecipeCache+Sync+Send+'static {
    pub folder_path: String,
    cache: C,
}

impl<C> RecipeService<C> where C: RecipeCache+Sync+Send+'static {

    pub fn new(folder_path: &str, cache: C) -> RecipeService<C> {
        RecipeService { 
            folder_path: folder_path.to_string(),
            cache,
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
                warn!("list recipe - ignore a `Recipe.toml` file: self.load_recipe_from_file returned Err, path={:?}, err={:#?}", dir.path(), e)
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

    pub async fn execute(self: Arc<Self>, bundle_id: &str, command: &str, args: &Vec<String>, context: &HashMap<String, String>) -> YRes<String> {
        let bundle_id = bundle_id.to_string();
        let command = command.to_string();
        let args = args.clone();
        let recipe_path = match self.cache.get_recipe_path(&bundle_id).await.trace(
            ctx!("excute recipe -> get recipe path from cache: self.cache.get_recipe_path() failed", bundle_id, command, args)
        )? {
            Some(x) => x,
            None => {
                let recipe_pathes = walkdir::WalkDir::new(&self.folder_path).into_iter().try_fold::<_, _, YRes<_>>(HashMap::new(), |mut acc, it| {
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
                        warn!("execute recipe -> bundle_id not exists in recipe cache -> rebuild recipe cache -> deserialize a `Recipe.toml` file - ignore the `Recipe.toml` file: self.load_recipe_from_file returned Err, path={:?}, err={:#?}", dir.path(), e);
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
                self.cache.set_recipe_pathes(&recipe_pathes, Some(300)).await.map_err(|e| {
                    err!("execute recipe failed").trace(
                        ctx!("execute recipe -> bundle_id not exists in recipe cache -> rebuild recipe cache: self.cache.set_recipe_pathes() failed", e)
                    )
                })?;
                let Some(path) = recipe_pathes.get(&bundle_id) else {
                    return Err(err!("execute recipe failed").trace(
                        ctx!("execute recipe: recipe not found", bundle_id)
                    ))
                };
                path.clone()
            },
        };
        let recipe = self.load_recipe_from_file(&recipe_path.join("Recipe.toml")).trace(
            ctx!("execute recipe -> load recipe from recipe path: self.load_recipe_from_file failed", recipe_path, bundle_id)
        )?;
        let recipe_context = context.into_iter().try_fold::<_, _, YRes<_>>(HashMap::new(), |mut acc, (name, value)| {
            if name == "command_bar_text" {
                acc.insert("command_bar_text", Value::String(value.to_string()));
                return Ok(acc);
            }
            for para in &recipe.parameters {
                if para.name == *name {
                    match &para.separator {
                        Some(sep) => {
                            let origin_values: Vec<&str> = value.split(sep).collect();
                            let parsed_values = origin_values.into_iter().try_fold::<_, _, YRes<_>>(Vec::new(), |mut acc, it| {
                                let parsed_value = self.parse_str_para(it, para.para_type).trace(
                                    ctx!("execute recipe -> parse str para: self.parse_str_para failed", para.name, it, para.para_type, bundle_id, recipe_path)
                                )?;
                                acc.push(parsed_value);
                                Ok(acc)
                            })?;
                            acc.insert(name, Value::Array(parsed_values));
                        },
                        None => {
                            let parsed_value = self.parse_str_para(&value, para.para_type).trace(
                                ctx!("execute recipe -> parse str para: self.parse_str_para failed", para.name, value, para.para_type, bundle_id, recipe_path)
                            )?;
                            acc.insert(name, parsed_value);
                        },
                    };
                    break;
                }
            }
            Ok(acc)
        })?;
        let recipe_context = serde_json::to_string(&recipe_context).map_err(|e| {
            err!("execute recipe failed").trace(
                ctx!("execute recipe -> parse recipe context: serde_json::to_string(&context) failed", bundle_id, recipe_path, context, e)
            )
        })?;
        let execute_uid = YUid::new().to_str();
        let ret = execute_uid.clone();
        let start_time = Instant::now();
        let mut child = Command::new(&command)
            .args(&args)
            .env("RECIPE_CONTEXT", recipe_context)
            .current_dir(&recipe_path)
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn().map_err(|e| {
                err!("execute recipe failed").trace(
                    ctx!("execute recipe -> execute command: Command::spawn failed", command, args, recipe_path, e)
                )
            })?;
        let stdout = child.stdout.take().ok_or(
            err!("execute recipe failed").trace(
                ctx!("execute recipe -> take stdout of child process: child.stdout.take() is None")
            )
        )?;
        let mut stderr = child.stderr.take().ok_or(
            err!("execute recipe failed").trace(
                ctx!("execute recipe -> take stderr of child process: child.stderr.take() is None")
            )
        )?;
        let mut reader = BufReader::new(stdout).lines();
        let mut buffer = String::new();
        let mut last_frame = String::new();
        let task = async move {
            let task = async {
                while let Some(line) = reader.next_line().await.map_err(|e| {
                    err!("execute recipe failed").trace(
                        ctx!("execute recipe -> async read next line from stdout: reader.next_line() failed", e)
                    )
                })? {
                    if line.trim() != RECIPE_EXECUTE_RESULT_FRAME_FLAG {
                        buffer.push_str(&line);
                        continue;
                    }
                    last_frame = buffer.clone();
                    buffer.clear();
                    self.cache.set_recipe_execute_result(&execute_uid, &RecipeExecuteResult {
                        bundle_id: bundle_id.to_string(),
                        command: command.to_string(),
                        args: args.clone(),
                        stdout: last_frame.clone(),
                        stderr: "".to_string(),
                        status: RecipeExecuteStatus::Running,
                        time_cost: start_time.elapsed().as_millis() as u64,
                    }, Some(3*24*3600)).await.trace(
                        ctx!("execute recipe -> got a frame when running -> set frame: self.cache.set_recipe_execute_result failed")
                    )?;
                }
                let exit_status = child.wait().await.map_err(|e| {
                    err!("execute recipe failed").trace(
                        ctx!("execute recipe -> wait child done: child.wait() failed", e)
                    )
                })?;
                // debug!("execute recipe finished: recipe_path={:?}, bundle_id={bundle_id}, command={command}, args={:?}, status={:?}", recipe_path, args, exit_status);
                if exit_status.success() {
                    self.cache.set_recipe_execute_result(&execute_uid, &RecipeExecuteResult {
                        bundle_id: bundle_id.to_string(),
                        command: command.to_string(),
                        args: args.clone(),
                        stdout: last_frame.clone(),
                        stderr: "".to_string(),
                        status: RecipeExecuteStatus::Success,
                        time_cost: start_time.elapsed().as_millis() as u64,
                    }, Some(3*24*3600)).await.trace(
                        ctx!("execute recipe -> execute finished and success -> update result: self.cache.set_recipe_execute_result failed")
                    )?;
                } else {
                    let mut stderr_buffer = Vec::new();
                    let res = stderr.read_to_end(&mut stderr_buffer).await;
                    let err_msg = match res {
                        Ok(_) => String::from_utf8_lossy(&stderr_buffer).to_string(),
                        Err(e) => {
                            warn!("execute recipe -> execute finished and fail -> fetch stderr - ignore stderr: stderr.read_to_end failed, err={e}");
                            "".to_string()
                        },
                    };
                    self.cache.set_recipe_execute_result(&execute_uid, &RecipeExecuteResult {
                        bundle_id: bundle_id.to_string(),
                        command: command.to_string(),
                        args: args.clone(),
                        stdout: last_frame.clone(),
                        stderr: err_msg,
                        status: RecipeExecuteStatus::Fail,
                        time_cost: start_time.elapsed().as_millis() as u64,
                    }, Some(3*24*3600)).await.trace(
                        ctx!("execute recipe -> execute finished and fail -> update result: self.cache.set_recipe_execute_result failed")
                    )?;
                }
                YRes::Ok(())
            };
            match timeout(Duration::from_secs(300), task).await {
                Ok(Ok(_)) => {}
                Ok(Err(e)) => {
                    error!("execute recipe failed: recipe_path={:?}, bundle_id={bundle_id}, command={command}, args={:?}, err={:#?}", recipe_path, args, e);
                }
                Err(_) => {
                    if let Err(e) = child.kill().await {
                        error!("execute recipe timeout and kill process failed: recipe_path={:?}, bundle_id={bundle_id}, command={command}, args={:?}, err={:?}", recipe_path, args, e);
                    }
                }
            }
            YRes::Ok(())
        };
        tokio::spawn(task);
        Ok(ret)
    }

    pub async fn fetch_execute_result(&self, execute_uid: &str) -> YRes<Option<RecipeExecuteResult>> {
        self.cache.get_recipe_execute_result(execute_uid).await.trace(
            ctx!("fetch execute result: self.cache.get_recipe_execute_result failed", execute_uid)
        )
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

    fn parse_str_para(&self, str_value: &str, para_type: RecipeParaType) -> YRes<Value> {
        let parsed_value = match para_type {
            RecipeParaType::Text => Value::String(str_value.to_string()),
            RecipeParaType::Number => {
                let number = str_value.parse::<i64>().map_err(|e| {
                    err!("parse str para failed").trace(
                        ctx!("parse number parameter: it.parse::<i64>() failed", str_value, para_type, e)
                    )
                })?;
                Value::Number(number.into())
            },
            RecipeParaType::Bool => {
                let bool =  match str_value.to_lowercase().as_str() {
                    "true" | "1" | "yes" => Ok(true),
                    "false" | "0" | "no" => Ok(false),
                    _ => Err(err!("para str para failed").trace(
                            ctx!("parse bool parameter: invalid value", str_value, para_type)
                         )),
                }?;
                Value::Bool(bool)
            },
        };
        Ok(parsed_value)
    }

}
