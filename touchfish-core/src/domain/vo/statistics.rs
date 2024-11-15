use std::collections::HashMap;

use serde::{Deserialize, Serialize};
use yfunc_rust::prelude::*;

use crate::FishType;

#[yfunc]
#[derive(Serialize, Deserialize, Debug)]
pub struct Statistics {
    pub count__active: u64,
    pub count__expired: u64,
    pub count__by_type: HashMap<FishType, u64>,
    pub count__by_tag: HashMap<String, u64>,
    pub count__marked: u64,
    pub count__unmarked: u64,
    pub count__locked: u64,
    pub count__unlocked: u64,
    pub count__by_day: HashMap<String, u64>,
}
