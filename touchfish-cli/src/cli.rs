use clap::{Parser, Subcommand};
use touchfish_core::{FishPreview, FishType, FishApi};
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

    pub fn handle(self, api: &FishApi<SqliteStorage>) -> YRes<CliOutput> {
        match self.command {
            Commands::Add { 
                fish_type, fish_data, desc, 
                tags, is_marked, is_locked,
                extra_info, use_file, base64_input, original_data,
            } => {
                let fish_type = fish_type.Aabb();
                let fish_type = FishType::from_name(&fish_type).trace(
                    ctx!("handle add command -> parse fish_type argument: FishType::from_name failed", fish_type)
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
                let fish = api.add_fish(
                    fish_type, fish_data, desc, tags, is_marked, is_locked, extra_info,
                )?;
                if original_data {
                    Ok(CliOutput::Text(fish.to_json_str()?))
                } else {
                    Ok(CliOutput::Text(fish.to_preview_json()?))
                }
            },
            Commands::Expire { identity } => {
                api.expire_fish(vec![&identity], false, false)?;
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
                api.modify_fish(&identity, desc, tags, extra_info)?;
                Ok(CliOutput::Ok)
            },
            Commands::Mark { identity } => {
                api.mark_fish(vec![&identity], false, false)?;
                Ok(CliOutput::Ok)
            },
            Commands::Unmark { identity } => {
                api.unmark_fish(vec![&identity], false, false)?;
                Ok(CliOutput::Ok)
            },
            Commands::Lock { identity } => {
                api.lock_fish(vec![&identity], false)?;
                Ok(CliOutput::Ok)
            },
            Commands::Unlock { identity } => {
                api.unlock_fish(vec![&identity], false)?;
                Ok(CliOutput::Ok)
            },
            Commands::Pin { identity } => {
                api.pin_fish(vec![&identity], false, false)?;
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
                    Some(x) => {
                        let fish_types = x.into_iter().try_fold::<_, _, YRes<_>>(Vec::new(), |mut acc, it| {
                            let fish_type = FishType::from_name(&it).trace(
                                ctx!("handle search command -> parse fish_types argument: FishType::from_name failed", it)
                            )?;
                            acc.push(fish_type);
                            Ok(acc)
                        })?;
                        Some(fish_types)
                    }
                };
                let res = api.search_fish(
                    fuzzy, identitys, fish_types, desc, tags, is_marked, is_locked, None, page_num, page_size,
                )?;
                if original_data {
                    Ok(CliOutput::Text(res.to_json_str()?))
                } else {
                    let preview_data = res.data.into_iter().map(|x|FishPreview::from_fish(&x)).collect::<YRes<Vec<_>>>()?;
                    let preview_page = Page {
                        total_count: res.total_count,
                        page_num: res.page_num,
                        page_size: res.page_size,
                        data: preview_data,
                    };
                    Ok(CliOutput::Text(preview_page.to_pretty_json_str()?))
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
                    Some(x) => {
                        let fish_types = x.into_iter().try_fold::<_, _, YRes<_>>(Vec::new(), |mut acc, it| {
                            let fish_type = FishType::from_name(&it).trace(
                                ctx!("handle delect command -> parse fish_types argument: FishType::from_name failed", it)
                            )?;
                            acc.push(fish_type);
                            Ok(acc)
                        })?;
                        Some(fish_types)
                    }
                };
                let res = api.detect_fish(
                    fuzzy, identitys, fish_types, desc, tags, is_marked, is_locked, None,
                )?;
                Ok(CliOutput::Text(res.join(",")))
            }
            Commands::Pick { identity , original_data} => {
                let fish = api.pick_fish(&identity)?;
                match fish {
                    Some(x) => if original_data {
                        Ok(CliOutput::Text(x.to_json_str()?))
                    } else {
                        Ok(CliOutput::Text(x.to_preview_json()?))
                    },
                    None => Ok(CliOutput::None),
                }
            },
            Commands::Count { original_data } => {
                let stats = api.count_fish()?;
                if original_data {
                    Ok(CliOutput::Text(stats.to_json_str()?))
                } else {
                    Ok(CliOutput::Text(stats.to_pretty_json_str()?))
                }
            }
        }
    }

}

