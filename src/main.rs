fn main() {
    if let Err(e) = rocksdb::DB::open_default("foo") {
        println!("{e}");
    } else {
        println!("success");
    }
}
