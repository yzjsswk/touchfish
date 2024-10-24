use std::str::FromStr;

use clap::{Parser, Subcommand};
use touchfish_core::{FishPreview, FishType, TouchFishCore};
use touchfish_sqlite_storage::SqliteStorage;
use yfunc_rust::{prelude::*, write_str_to_stdout, Page, VariableFormat, YBytes};

#[derive(Debug, Subcommand)]
pub enum Commands {
    Add {
        fish_type: String,
        fish_data: String,
        #[arg(long = "desc")]
        desc: Option<String>,
        #[arg(long = "tags", use_value_delimiter = true)]
        tags: Option<Vec<String>>,
        #[arg(long = "mark")]
        is_marked: Option<bool>,
        #[arg(long = "lock")]
        is_locked: Option<bool>,
        #[arg(long = "extra")]
        extra_info: Option<String>,
        #[arg(short = 'f', action = clap::ArgAction::SetTrue)]
        use_file: bool,
        #[arg(short = 'b', action = clap::ArgAction::SetTrue)]
        base64_input: bool,
        #[arg(short = 'o', action = clap::ArgAction::SetTrue)]
        original_data: bool,
    },
    Expire {
        identity: String,
    },
    Modify {
        identity: String,
        #[arg(long = "desc")]
        desc: Option<String>,
        #[arg(long = "tags", use_value_delimiter = true)]
        tags: Option<Vec<String>>,
        #[arg(long = "extra")]
        extra_info: Option<String>,
        #[arg(short = 'b', action = clap::ArgAction::SetTrue)]
        base64_input: bool,
    },
    Mark {
        identity: String,
    },
    Unmark {
        identity: String,
    },
    Lock {
        identity: String,
    },
    Unlock {
        identity: String,
    },
    Pin {
        identity: String,
    },
    Search {
        #[arg(long = "fuzzy")]
        fuzzy: Option<String>,
        #[arg(long = "identitys", use_value_delimiter = true)]
        identitys: Option<Vec<String>>,
        #[arg(long = "types", use_value_delimiter = true)]
        fish_types: Option<Vec<String>>,
        #[arg(long = "desc")]
        desc: Option<String>,
        #[arg(long = "tags", use_value_delimiter = true)]
        tags: Option<Vec<String>>,
        #[arg(long = "mark")]
        is_marked: Option<bool>,
        #[arg(long = "lock")]
        is_locked: Option<bool>,
        #[arg(long = "page")]
        page_num: Option<i32>,
        #[arg(long = "size")]
        page_size: Option<i32>,
        #[arg(short = 'b', action = clap::ArgAction::SetTrue)]
        base64_input: bool,
        #[arg(short = 'o', action = clap::ArgAction::SetTrue)]
        original_data: bool,
    },
    Delect {
        #[arg(long = "fuzzy")]
        fuzzy: Option<String>,
        #[arg(long = "identitys", use_value_delimiter = true)]
        identitys: Option<Vec<String>>,
        #[arg(long = "types", use_value_delimiter = true)]
        fish_types: Option<Vec<String>>,
        #[arg(long = "desc")]
        desc: Option<String>,
        #[arg(long = "tags", use_value_delimiter = true)]
        tags: Option<Vec<String>>,
        #[arg(long = "mark")]
        is_marked: Option<bool>,
        #[arg(long = "lock")]
        is_locked: Option<bool>,
        #[arg(short = 'b', action = clap::ArgAction::SetTrue)]
        base64_input: bool,
    },
    Pick {
        identity: String,
        #[arg(short = 'o', action = clap::ArgAction::SetTrue)]
        original_data: bool,
    },
    Count {
        #[arg(short = 'o', action = clap::ArgAction::SetTrue)]
        original_data: bool,
    },
}

pub enum CliOutput {
    Ok,
    None,
    Text(String),
}

impl CliOutput {

    pub fn write_to_stdout(&self) -> YRes<()> {
        match self {
            CliOutput::Ok => write_str_to_stdout("Ok\n"),
            CliOutput::None => write_str_to_stdout("None\n"),
            CliOutput::Text(s) => write_str_to_stdout(&format!("{}\n", s)),
        }
    }

}

#[derive(Debug, Parser)]
#[command(multicall = true)]
pub struct Cli {
    #[command(subcommand)]
    command: Commands,
}

impl Cli {

    pub fn handle(self, core: &TouchFishCore<SqliteStorage>) -> YRes<CliOutput> {
        match self.command {
            Commands::Add { 
                fish_type, fish_data, desc, 
                tags, is_marked, is_locked,
                extra_info, use_file, base64_input, original_data,
            } => {
                let fish_type = fish_type.Aabb();
                let fish_type = FishType::from_str(&fish_type).map_err(|e|
                    err!(ParseError::"handle add command": "parse fish_type failed", fish_type, e)
                )?;
                let fish_data: YBytes = if use_file {
                    YBytes::open_file(&fish_data)?
                } else {  
                    if base64_input {
                        YBytes::from_base64(&fish_data)?
                    } else {
                        YBytes::new(fish_data.into_bytes())
                    }
                };
                let desc = match desc {
                    None => None,
                    Some(x) => {
                        if base64_input {
                            Some(YBytes::from_base64(&x)?.to_str()?)
                        } else {
                            Some(x)
                        }
                    }
                };
                let extra_info = match extra_info {
                    None => None,
                    Some(x) => {
                        if base64_input {
                            Some(YBytes::from_base64(&x)?.to_str()?)
                        } else {
                            Some(x)
                        }
                    }
                };
                let fish = core.add_fish(
                    fish_type, fish_data, desc, tags, is_marked, is_locked, extra_info,
                )?;
                if original_data {
                    Ok(CliOutput::Text(fish.json_with_data()?))
                } else {
                    Ok(CliOutput::Text(fish.json_with_preview()?))
                }
            },
            Commands::Expire { identity } => {
                core.expire_fish(vec![&identity], false, false)?;
                Ok(CliOutput::Ok)
            },
            Commands::Modify { 
                identity, desc, tags, extra_info, base64_input,
            } => {
                let desc = match desc {
                    None => None,
                    Some(x) => {
                        if base64_input {
                            Some(YBytes::from_base64(&x)?.to_str()?)
                        } else {
                            Some(x)
                        }
                    }
                };
                let extra_info = match extra_info {
                    None => None,
                    Some(x) => {
                        if base64_input {
                            Some(YBytes::from_base64(&x)?.to_str()?)
                        } else {
                            Some(x)
                        }
                    }
                };
                core.modify_fish(&identity, desc, tags, extra_info)?;
                Ok(CliOutput::Ok)
            },
            Commands::Mark { identity } => {
                core.mark_fish(vec![&identity], false, false)?;
                Ok(CliOutput::Ok)
            },
            Commands::Unmark { identity } => {
                core.unmark_fish(vec![&identity], false, false)?;
                Ok(CliOutput::Ok)
            },
            Commands::Lock { identity } => {
                core.lock_fish(vec![&identity], false)?;
                Ok(CliOutput::Ok)
            },
            Commands::Unlock { identity } => {
                core.unlock_fish(vec![&identity], false)?;
                Ok(CliOutput::Ok)
            },
            Commands::Pin { identity } => {
                core.pin_fish(vec![&identity], false, false)?;
                Ok(CliOutput::Ok)
            },
            Commands::Search {
                fuzzy, identitys, fish_types, 
                desc, tags, is_marked, is_locked,
                page_num, page_size, base64_input, original_data,
            } => {
                let fuzzy = match fuzzy {
                    None => None,
                    Some(x) => {
                        if base64_input {
                            Some(YBytes::from_base64(&x)?.to_str()?)
                        } else {
                            Some(x)
                        }
                    }
                };
                let desc = match desc {
                    None => None,
                    Some(x) => {
                        if base64_input {
                            Some(YBytes::from_base64(&x)?.to_str()?)
                        } else {
                            Some(x)
                        }
                    }
                };
                let fish_types = match fish_types {
                    None => None,
                    Some(x) => Some(x.into_iter().map(|y| FishType::from_str(&y.Aabb()).map_err(|e|
                            err!(ParseError::"handle search command": "parse fish_type failed", y, e)
                    )).collect::<YRes<Vec<_>>>()?),
                };
                let res = core.search_fish(
                    fuzzy, identitys, fish_types, desc, tags,
                    is_marked, is_locked, page_num, page_size,
                )?;
                if original_data {
                    Ok(CliOutput::Text(res.to_json(false)?))
                } else {
                    let preview_data = res.data.into_iter().map(|x|FishPreview::from_fish(&x)).collect::<YRes<Vec<_>>>()?;
                    let preview_page = Page {
                        total_count: res.total_count,
                        page_num: res.page_num,
                        page_size: res.page_size,
                        data: preview_data,
                    };
                    Ok(CliOutput::Text(preview_page.to_json(true)?))
                }
            },
            Commands::Delect { 
                fuzzy, identitys, fish_types, 
                desc, tags, is_marked, is_locked,
                base64_input,
            } => {
                let fuzzy = match fuzzy {
                    None => None,
                    Some(x) => {
                        if base64_input {
                            Some(YBytes::from_base64(&x)?.to_str()?)
                        } else {
                            Some(x)
                        }
                    }
                };
                let desc = match desc {
                    None => None,
                    Some(x) => {
                        if base64_input {
                            Some(YBytes::from_base64(&x)?.to_str()?)
                        } else {
                            Some(x)
                        }
                    }
                };
                let fish_types = match fish_types {
                    None => None,
                    Some(x) => Some(x.into_iter().map(|y| FishType::from_str(&y.Aabb()).map_err(|e|
                            err!(ParseError::"handle delect command": "parse fish_type failed", y, e)
                    )).collect::<YRes<Vec<_>>>()?),
                };
                let res = core.detect_fish(
                    fuzzy, identitys, fish_types, desc, tags, is_marked, is_locked, 
                )?;
                Ok(CliOutput::Text(res.join(",")))
            }
            Commands::Pick { identity , original_data} => {
                let fish = core.pick_fish(&identity)?;
                match fish {
                    Some(x) => if original_data {
                        Ok(CliOutput::Text(x.json_with_data()?))
                    } else {
                        Ok(CliOutput::Text(x.json_with_preview()?))
                    },
                    None => Ok(CliOutput::None),
                }
            },
            Commands::Count { original_data } => {
                let stats = core.count_fish()?;
                Ok(CliOutput::Text(stats.to_json(!original_data)?))
            }
        }
    }

}

