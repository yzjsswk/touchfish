use std::collections::HashMap;

use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct ExecuteRecipeReq {
    pub bundle_id: String,
    pub command: String,
    pub args: Vec<String>,
    pub context: HashMap<String, String>,
}