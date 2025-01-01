use serde::{Deserialize, Serialize};
use yfunc_rust::prelude::*;

#[yfunc]
#[derive(Serialize, Deserialize, Debug)]
pub struct RecipeExecuteResult {
    pub bundle_id: String,
    pub command: String,
    pub args: Vec<String>,
    pub stdout: String,
    pub stderr: String,
    pub status: RecipeExecuteStatus,
    pub time_cost: u64,
}

#[yfunc]
#[derive(Serialize, Deserialize, Debug)]
pub enum RecipeExecuteStatus {
    Success, Fail, Running,
}
