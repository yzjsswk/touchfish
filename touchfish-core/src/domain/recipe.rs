use std::str::FromStr;

use serde::{Deserialize, Serialize};
use strum_macros::{Display, EnumString};
use yfunc_rust::prelude::*;

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
    pub order: Option<i32>,
    #[serde(default = "default_enabled")]
    pub enabled: bool,
}

fn default_parameters() -> Vec<RecipePara> {
    vec![]
}

fn default_actions() -> Vec<RecipeAction> {
    vec![]
}

fn default_enabled() -> bool {
    true
}

#[derive(Serialize, Deserialize, Debug, EnumString, Display, PartialEq, Eq, Hash, Clone, Copy)]
pub enum RecipeType {
    Task,
    View,
    Commit,
}

impl RecipeType {

    pub fn new(s: &str) -> YRes<RecipeType> {
        RecipeType::from_str(s).map_err(|e|
            err!(ParseError::"build RecipeType from str", s, e)
        )
    }

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

#[derive(Serialize, Deserialize, Debug, EnumString, Display, PartialEq, Eq, Hash, Clone, Copy)]
pub enum RecipeActionType {
    Back,
    Hide,
    Copy,
    Open,
    Shell,
}

impl RecipeActionType {

    pub fn new(s: &str) -> YRes<RecipeActionType> {
        RecipeActionType::from_str(s).map_err(|e|
            err!(ParseError::"build RecipeActionType from str", s, e)
        )
    }

}

#[derive(Serialize, Deserialize, Debug)]
pub struct RecipeActionArg {
    pub arg_type: RecipeActionArgType,
    pub value: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, EnumString, Display, PartialEq, Eq, Hash, Clone, Copy)]
pub enum RecipeActionArgType {
    Plain,
    Para,
    CommandBarText,
    File,
    Context,
}

impl RecipeActionArgType {

    pub fn new(s: &str) -> YRes<RecipeActionArgType> {
        RecipeActionArgType::from_str(s).map_err(|e|
            err!(ParseError::"build RecipeActionArgType from str", s, e)
        )
    }

}

