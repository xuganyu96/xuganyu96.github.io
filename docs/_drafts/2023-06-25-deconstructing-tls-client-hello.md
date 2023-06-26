```rust
use std::error::Error;
use hex;
use tokio::net::TcpStream;
use tokio::io::{AsyncReadExt, AsyncWriteExt};

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let x = concat!(
        "010000e80303952ed69c139b4c14bb2e1676a035529b008adcaa441695451be7ed68",
        "d27e9bfd206aa89bcbe27a320fc2f91f1895f6c77d4d572d7a83c42a7fd9a31b8dfb",
        "ce757c0014130213011303c02cc02bcca9c030c02fcca800ff0100008b002b000504",
        "03040303000b00020100000a00080006001d00170018000d00140012050304030807",
        "080608050804060105010401001700000005000501000000000000000f000d00000a",
        "676f6f676c652e636f6d00120000003300260024001d00201be822beeb101835fef4",
        "9f69d8ffe1f0523f7c5c3a858f8691d1a89a9f0ef72e002d0002010100230000",
    );
    let bytes = hex::decode(x).unwrap();
    // println!("{:?}", bytes);

    let mut conn = TcpStream::connect("google.com:443").await.unwrap();
    
    conn.writable().await.unwrap();
    println!("{conn:?} is writable");
    let n = conn.write(&bytes).await.unwrap();
    println!("{n} bytes written");

    conn.readable().await.unwrap();
    println!("{conn:?} is readable");
    let mut bytes = vec![];
    let n = conn.read(&mut bytes).await.unwrap();
    println!("{n} bytes read");

    dbg!();

    return Ok(());
}
```

Doesn't quite work...