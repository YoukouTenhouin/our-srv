use base64::prelude::*;
use blake2b_simd::Params;
use clap::Parser;
use reqwest::blocking::Client;
use serde::Deserialize;
use std::env::var;

#[derive(Parser)]
struct Args {
    #[arg(short, long)]
    key: String,
}

#[derive(Deserialize)]
struct Key {
    #[serde(rename = "type")]
    key_type: String,
    owner: String,
    content: String,
}

#[derive(Deserialize)]
struct Response {
    data: Key,
}

fn get_fingerprint(content: &[u8]) -> String {
    Params::new()
        .hash_length(16)
        .to_state()
        .update(content)
        .finalize()
        .to_hex()
        .as_str()
        .to_string()
}

fn main() {
    let args = Args::parse();
    let baseurl = var("OUR_API_BASEURL").unwrap();

    let content = BASE64_STANDARD.decode(args.key).unwrap();
    let fp = get_fingerprint(content.as_slice());

    let url = format!("{}/api/key/{}", baseurl, fp);
    let res: Response = Client::new().get(url).send().unwrap().json().unwrap();

    let key = format!("ssh-{} {}", res.data.key_type, res.data.content);
    let opt = [
        format!(
            "command=\"/usr/local/bin/our-git-shell-wrapper -u {}\"",
            res.data.owner
        )
        .as_str(),
        "no-port-forwarding",
        "no-X11-forwarding",
        "no-agent-forwarding",
        "no-pty",
    ]
    .join(",");
    println!("{opt} {key}")
}
