use std::collections::HashMap;

use serde::{Deserialize, Serialize};
use serde_json::Value;
use yfunc_rust::prelude::*;

use super::{Recipe, RecipeParaType};

#[yfunc]
#[derive(Serialize, Deserialize, Debug)]
pub struct RecipeExecuteContext {
    pub query: String,
    pub parameters: HashMap<String, String>,
    pub settings: HashMap<String, String>,
}

#[yfunc]
#[derive(Serialize, Deserialize, Debug)]
pub struct ParsedRecipeExecuteContext {
    pub query: String,
    pub parameters: HashMap<String, Value>,
    pub settings: HashMap<String, Value>,
}

impl ParsedRecipeExecuteContext {

    pub fn parse_str_paras(str_values: &HashMap<String, String>, recipe: &Recipe) -> YRes<HashMap<String, Value>> {
        let parsed_values = str_values.into_iter().try_fold::<_, _, YRes<_>>(HashMap::new(), |mut acc, (name, value)| {
            for para in &recipe.parameters {
                if para.name == *name {
                    match &para.separator {
                        Some(sep) => {
                            let origin_values: Vec<&str> = value.split(sep).collect();
                            let parsed_values = origin_values.into_iter().try_fold::<_, _, YRes<_>>(Vec::new(), |mut acc, it| {
                                let parsed_value = ParsedRecipeExecuteContext::parse_str_para(it, para.para_type).trace(
                                    ctx!("parse str paras: ParsedRecipeExecuteContext::parse_str_para failed", para.name, it, para.para_type, recipe.bundle_id)
                                )?;
                                acc.push(parsed_value);
                                Ok(acc)
                            })?;
                            acc.insert(name.clone(), Value::Array(parsed_values));
                        },
                        None => {
                            let parsed_value = ParsedRecipeExecuteContext::parse_str_para(&value, para.para_type).trace(
                                ctx!("parse str paras: ParsedRecipeExecuteContext::parse_str_para failed", para.name, value, para.para_type, recipe.bundle_id)
                            )?;
                            acc.insert(name.clone(), parsed_value);
                        },
                    };
                    break;
                }
            }
            Ok(acc)
        })?;
        Ok(parsed_values)
    }

    pub fn parse_str_para(str_value: &str, para_type: RecipeParaType) -> YRes<Value> {
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
