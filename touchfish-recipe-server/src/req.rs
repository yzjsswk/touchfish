use serde::{Deserialize, Serialize};
use touchfish_core::RecipeExecuteContext;

#[derive(Debug, Serialize, Deserialize)]
pub struct ExecuteRecipeReq {
    pub bundle_id: String,
    pub command: String,
    pub args: Vec<String>,
    pub context: RecipeExecuteContext,
}