use serde::{Deserialize, Serialize};
use strum_macros::{Display, EnumString};
use yfunc_rust::prelude::*;

#[yfunc]
#[derive(Serialize, Deserialize, Debug)]
pub struct Recipe {
    pub bundle_id: String,
    pub version: i32,
    pub author: String,
    pub recipe_type: RecipeType,
    pub name: String,
    pub description: Option<String>,
    pub icon: Option<String>,
    pub command: Option<String>,
    #[serde(default = "default_parameters")]
    pub parameters: Vec<RecipePara>,
    #[serde(default = "default_actions")]
    pub actions: Vec<RecipeAction>,
    pub color: Option<String>,
}

fn default_parameters() -> Vec<RecipePara> {
    vec![]
}

fn default_actions() -> Vec<RecipeAction> {
    vec![]
}

#[yfunc]
#[derive(Serialize, Deserialize, Debug, EnumString, Display, PartialEq, Eq, Hash, Clone, Copy)]
pub enum RecipeType {
    Task,
    View,
    Commit,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct RecipePara {
    pub name: String,
    pub separator: Option<String>,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct RecipeAction {
    pub action_type: RecipeActionType,
    pub arguments: Vec<RecipeActionArg>,
}

#[yfunc]
#[derive(Serialize, Deserialize, Debug, EnumString, Display, PartialEq, Eq, Hash, Clone, Copy)]
pub enum RecipeActionType {
    Back,
    Hide,
    Copy,
    Open,
    Show,
    Shell,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct RecipeActionArg {
    pub arg_type: RecipeActionArgType,
    pub value: Option<String>,
}

#[yfunc]
#[derive(Serialize, Deserialize, Debug, EnumString, Display, PartialEq, Eq, Hash, Clone, Copy)]
pub enum RecipeActionArgType {
    Plain,
    Para,
    CommandBarText,
    Context,
}
