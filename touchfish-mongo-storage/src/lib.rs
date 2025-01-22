#![allow(non_snake_case)]
#![allow(non_upper_case_globals)]

mod model;
mod storage;

pub use storage::MongoStorage;

#[cfg(test)]
mod tests {

    use std::collections::HashMap;

    use touchfish_core::{DataInfo, FishStorage};
    use yfunc_rust::{prelude::*, YBytes};

    use crate::storage::MongoStorage;

    #[tokio::test]
    async fn add_fish_works() -> YRes<()> {
        let db = MongoStorage::new("mongodb://mongodb:mongodb@localhost:27017").await?;
        let data = "hello world!".as_bytes().to_vec();
        let uid = db.add_fish(
            "asdsads", touchfish_core::FishType::Text, YBytes::new(data), 
            &DataInfo {
                byte_count: Some(10),
                char_count: Some(1),
                word_count: Some(1),
                row_count: Some(1),
                width: None,
                height: None,
            }, "test", &vec![], true, false, &HashMap::new(),
        ).await?;
        dbg!(uid);
        Ok(())
    }

    #[tokio::test]
    async fn expire_fish_works() -> YRes<()> {
        let db = MongoStorage::new("mongodb://mongodb:mongodb@localhost:27017").await?;
        db.expire_fish(&vec!["6735fc93f614343f295f395a", "6736e67398be4e87fd656236", "xxas"]).await?;
        Ok(())
    }

    #[tokio::test]
    async fn modify_fish_works() -> YRes<()> {
        let db = MongoStorage::new("mongodb://mongodb:mongodb@localhost:27017").await?;
        let mut extra_info = HashMap::new();
        extra_info.insert("a".to_string(), "b".to_string());
        db.modify_fish("6790b897fe51cd65c6ae65e2", None, Some(&vec!["modified", "test"]), &Some(extra_info)).await?;
        Ok(())
    }

    #[tokio::test]
    async fn pick_fish_works() -> YRes<()> {
        let db = MongoStorage::new("mongodb://mongodb:mongodb@localhost:27017").await?;
        let fish = db.pick_fish("6736e18de390dc1cf4e0e011").await?;
        dbg!(fish);
        Ok(())
    }

    #[tokio::test]
    async fn detect_fish_works() -> YRes<()> {
        let db = MongoStorage::new("mongodb://mongodb:mongodb@localhost:27017").await?;
        let uids = db.detect_fish_by_conditions(
            Some("lo"), None, None, None, None, Some(&vec!["aaa"]), None, None, None, None, None, None,
        ).await?;
        dbg!(uids);
        Ok(())
    }

    #[tokio::test]
    async fn count_fish_works() -> YRes<()> {
        let db = MongoStorage::new("mongodb://mongodb:mongodb@localhost:27017").await?;
        let stats = db.count_fish().await?;
        dbg!(stats);
        Ok(())
    }

}
