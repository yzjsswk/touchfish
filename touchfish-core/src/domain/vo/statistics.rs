use std::collections::HashMap;

use serde::{Deserialize, Serialize};
use yfunc_rust::prelude::*;

use crate::FishType;

#[yfunc]
#[derive(Serialize, Deserialize, Debug)]
pub struct Statistics {
    pub count__active: i32,
    pub count__expired: i32,
    pub count__by_type: HashMap<FishType, i32>,
    pub count__by_tag: HashMap<String, i32>,
    pub count__marked: i32,
    pub count__unmarked: i32,
    pub count__locked: i32,
    pub count__unlocked: i32,
    pub count__by_day: HashMap<String, i32>,
}
