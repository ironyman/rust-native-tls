extern crate native_tls;

use native_tls::{Identity, TlsAcceptor, TlsStream};
use std::fs::File;
use std::io::Read;
use std::net::{TcpListener, TcpStream};
use std::sync::Arc;
use std::thread;
use std::io::Write;

fn main() {
    let mut file = File::open("identity.pfx").unwrap();
    let mut pkcs12 = vec![];
    file.read_to_end(&mut pkcs12).unwrap();
    let pkcs12 = Identity::from_pkcs12(&pkcs12, "hunter2").unwrap();

    let acceptor = TlsAcceptor::new(pkcs12).unwrap();
    let acceptor = Arc::new(acceptor);

    let listener = TcpListener::bind("0.0.0.0:8443").unwrap();

    fn handle_client(mut stream: TlsStream<TcpStream>) {
        let mut buf = [0; 1024];
        let read = stream.read(&mut buf).unwrap();
        let received = std::str::from_utf8(&buf[0..read]).unwrap();
        stream
            .write_all(format!("received '{}'", received).as_bytes())
            .unwrap();
        println!("received '{}'", received);
    }

    for stream in listener.incoming() {
        match stream {
            Ok(stream) => {
                let acceptor = acceptor.clone();
                thread::spawn(move || {
                    let stream = acceptor.accept(stream).unwrap();
                    handle_client(stream);
                });
            }
            Err(_e) => { /* connection failed */ }
        }
    }
}
