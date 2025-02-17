use std::{collections::HashMap, path::PathBuf};

use redis::Commands;
use touchfish_core::{RecipeCache, RecipeExecuteResult};
use yfunc_rust::prelude::*;

use super::RedisCache;

const RECIPE_PATH_KEY: &str = "recipe_pathes";
const RECIPE_EXECUTE_RESULT_KEY_PREFIX: &str = "recipe_execute_result";

impl RecipeCache for RedisCache {

    async fn set_recipe_pathes(&self, recipe_pathes: &HashMap<String, PathBuf>, expire_seconds: Option<u64>) -> YRes<()> {
        let mut conn = self.get_conn().trace(
            ctx!("set recipe pathes: self.get_conn() failed")
        )?;
        // todo: transaction?
        conn.del(RECIPE_PATH_KEY).map_err(|e| {
            err!("set recipe pathes failed").trace(
                ctx!("set recipe pathes -> remove old key: conn.del() failed", e)
            )
        })?;
        for (bundle_id, path) in recipe_pathes {
            conn.hset(RECIPE_PATH_KEY, bundle_id, path.to_string_lossy()).map_err(|e| {
                err!("set recipe pathes failed").trace(
                    ctx!("set recipe pathes: conn.hset() failed", bundle_id, path, e)
                )
            })?;
        }
        if let Some(sec) = expire_seconds {
            conn.expire(RECIPE_PATH_KEY, sec as i64).map_err(|e| {
                err!("set recipe pathes failed").trace(
                    ctx!("set recipe pathes -> set expire time: conn.expire() failed", sec, expire_seconds, e)
                )
            })?;
        }
        Ok(())
    }

    async fn get_recipe_path(&self, bundle_id: &str) -> YRes<Option<PathBuf>> {
        let mut conn = self.get_conn().trace(
            ctx!("get recipe path: self.get_conn() failed")
        )?;
        let path: Option<String> = conn.hget(RECIPE_PATH_KEY, bundle_id).map_err(|e| {
            err!("get recipe path failed").trace(
                ctx!("get recipe path: conn.hget() failed", bundle_id, e)
            )
        })?;
        Ok(path.map(|x| PathBuf::from(x)))
    }

    async fn set_recipe_execute_result(&self, execute_uid: &str, result: &RecipeExecuteResult, expire_seconds: Option<u64>) -> YRes<()> {
        let mut conn = self.get_conn().trace(
            ctx!("set_recipe_execute_result: self.get_conn() failed")
        )?;
        let key = format!("{}_{}", RECIPE_EXECUTE_RESULT_KEY_PREFIX, execute_uid);
        let value = result.to_json_str().trace(
            ctx!("set recipe execute result: result.to_json_str() failed", key)
        )?;
        conn.set(&key, &value).map_err(|e| {
            err!("set recipe execute result failed").trace(
                ctx!("set recipe execute result: conn.set() failed", key, e)
            )
        })?;
        if let Some(sec) = expire_seconds {
            conn.expire(&key, sec as i64).map_err(|e| {
                err!("set recipe execute result failed").trace(
                    ctx!("set recipe execute result -> set expire time: conn.expire() failed", sec, expire_seconds, e)
                )
            })?;
        }
        Ok(())
    }

    async fn get_recipe_execute_result(&self, execute_uid: &str) -> YRes<Option<RecipeExecuteResult>> {
        let mut conn = self.get_conn().trace(
            ctx!("get_recipe_execute_result: self.get_conn() failed")
        )?;
        let key = format!("{}_{}", RECIPE_EXECUTE_RESULT_KEY_PREFIX, execute_uid);
        let value: Option<String> = conn.get(&key).map_err(|e| {
            err!("get_recipe_execute_result failed").trace(
                ctx!("get_recipe_execute_result: conn.get() failed", key, e)
            )
        })?;
        let Some(value) = value else {
            return Ok(None)
        };
        Ok(Some(RecipeExecuteResult::from_json_str(&value).trace(
            ctx!("get_recipe_execute_result -> deserialize value failed", value)
        )?))
    }

}
