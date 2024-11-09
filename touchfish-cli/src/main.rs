#![allow(non_snake_case)]
#![allow(non_upper_case_globals)]

use std::env;

use clap::Parser;
use cli::Cli;
use touchfish_core::FishApi;
use touchfish_sqlite_storage::SqliteStorage;
use yfunc_rust::{prelude::*, write_str_to_stdout};

mod cli;

fn main() -> YRes<()> {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        println!("database url is required");
        return Ok(());
    }
    let storage = SqliteStorage::connect(&args[1], false)?;
    let api = FishApi::new(storage)?;
    loop {
        write_str_to_stdout("> ")?;
        let mut input = String::new();
        std::io::stdin()
            .read_line(&mut input)
            .map_err(|e|
                err!("read input failed").trace(
                    ctx!("read input: std::io::stdin().read_line failed", e)
                )
            )?;
        let input = input.trim();
        if input.is_empty() {
            continue;
        }
        if input == "exit" || input == "quit" {
            break Ok(());
        }
        let args = input.split_ascii_whitespace();
        match Cli::try_parse_from(args) {
            Ok(cli) => {
                match cli.handle(&api) {
                    Ok(output) => output.write_to_stdout()?,
                    Err(err) => write_str_to_stdout(&format!("{:?}\n", err))?,
                }
            },
            Err(err) => write_str_to_stdout(&format!("{}\n", err))?,
        }
    }
}
