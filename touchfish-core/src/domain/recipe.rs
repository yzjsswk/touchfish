use serde::{Deserialize, Serialize};
use strum_macros::{Display, EnumString};
use yfunc_rust::prelude::*;

#[yfunc]
#[derive(Serialize, Deserialize, Debug)]
pub struct Recipe {
    pub bundle_id: String,
    pub version: i32,
    pub author: String,
    pub name: String,
    pub description: Option<String>,
    pub icon: Option<String>,
    pub command: Option<String>,
    #[serde(default = "default_auto_execute")]
    pub auto_execute: bool,
    #[serde(default = "default_parameters")]
    pub settings: Vec<RecipePara>,
    #[serde(default = "default_parameters")]
    pub parameters: Vec<RecipePara>,
    #[serde(default = "default_actions")]
    pub actions: Vec<RecipeAction>,
    pub color: Option<String>,
}

fn default_auto_execute() -> bool {
    true
}

fn default_parameters() -> Vec<RecipePara> {
    vec![]
}

fn default_actions() -> Vec<RecipeAction> {
    vec![]
}

#[derive(Serialize, Deserialize, Debug)]
pub struct RecipePara {
    pub name: String,
    pub para_type: RecipeParaType,
    pub desc: Option<String>,
    pub inputer: RecipeParaInputer,
    pub separator: Option<String>,
    #[serde(default = "default_options")]
    pub options: Vec<String>,
}

fn default_options() -> Vec<String> {
    vec![]
}

#[derive(Serialize, Deserialize, Debug)]
#[serde(tag="type")]
pub enum RecipeAction {
    #[serde(rename = "run")]
    RunShellCommand { 
        cmd: String,
        args: Vec<String>,
        #[serde(default = "default_refresh_view")]
        refresh_view: bool,
    },
    #[serde(rename = "copy")]
    CopyToClipboard { content: String },
    #[serde(rename = "back")]
    BackToMenu,
    #[serde(rename = "hide")]
    HideTouchFish,
    #[serde(rename = "open_url")]
    OpenUrl { url: String },
    #[serde(rename = "active_app")]
    ActiveExternalApp { bundle_id: String },
    #[serde(rename = "set_para")]
    SetParameter { name: String, value: String },
}

fn default_refresh_view() -> bool {
    true
}

#[yfunc]
#[derive(Serialize, Deserialize, Debug, EnumString, Display, PartialEq, Eq, Hash, Clone, Copy)]
pub enum RecipeParaType {
    Text, Number, Bool,
}

#[yfunc]
#[derive(Serialize, Deserialize, Debug, EnumString, Display, PartialEq, Eq, Hash, Clone, Copy)]
pub enum RecipeParaInputer {
    SingleLineEdit,
    MultLineEdit,
    Choice,
    Check,
    Slide,
}
