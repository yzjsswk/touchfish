#![allow(non_snake_case)]
#![allow(non_upper_case_globals)]

mod model;
mod mongo_storage;

#[cfg(test)]
mod tests {

    use touchfish_core::DataInfo;
    use yfunc_rust::{prelude::*, YBytes};

    use crate::mongo_storage::MongoStorage;

    #[tokio::test]
    async fn it_works() -> YRes<()> {
        let db = MongoStorage::new("mongodb://mongodb:mongodb@localhost:27017").await?;
        let data = "hello world!".as_bytes().to_vec();
        db.add_fish(
            "asdasdsa".to_string(), 1, touchfish_core::FishType::Text, YBytes::new(data), 
            DataInfo {
                byte_count: None,
                char_count: Some(0),
                word_count: Some(1),
                row_count: Some(1),
                width: None,
                height: None,
            }, "test".to_string(), vec!["test".to_string(), "aaa".to_string()], false, true, "asd".to_string(),
        ).await?;
        Ok(())
    }

}
