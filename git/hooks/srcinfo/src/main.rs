use reqwest::blocking::Client;
use serde::{Deserialize, Serialize};
use std::io::{self, BufRead};
use std::process::{Command, exit};

struct CommitInfo {
    new_oid: String,
    ref_name: String,
}

#[derive(Deserialize, Serialize)]
struct SRCInfo {
    name: String,
    version: Option<String>,
    release: Option<String>,
    description: Option<String>,
    license: Option<String>,
    requires: Option<Vec<String>>,
}

fn read_commit_info() -> io::Result<Option<CommitInfo>> {
    if let Some(line) = io::stdin().lock().lines().next() {
        let line = line?;
        let split: Vec<&str> = line.split(" ").collect();
        let new_oid = split[1].to_string();
        let ref_name = split[2].to_string();
        Ok(Some(CommitInfo { new_oid, ref_name }))
    } else {
        Ok(None)
    }
}

fn read_srcinfo_from_commit(commit: &str) -> Vec<u8> {
    let output = Command::new("git")
        .arg("show")
        .arg(format!("{commit}:.srcinfo.json"))
        .output()
        .unwrap_or_else(|e| {
            eprintln!("failed to execute git command: {e}");
            exit(-1)
        });
    if !output.status.success() {
        eprintln!("[!] REJECTED `.srcinfo.json` not found in commit {commit}");
        exit(1)
    }
    output.stdout
}

fn update_srcinfo(srcinfo: &SRCInfo) {
    let baseurl = std::env::var("OUR_API_BASEURL").unwrap();
    let res = Client::new()
        .put(format!("{}/api/package/{}", baseurl, srcinfo.name))
        .json(srcinfo)
        .send()
        .unwrap_or_else(|e| {
            eprintln!("failed to request API server: {e}");
            exit(-1)
        });
    if !res.status().is_success() {
        let code = res.status().as_u16();
        eprintln!("API server responded with code {code}");
        exit(-1)
    }
}

fn main() {
    while let Some(info) = read_commit_info().unwrap() {
        if info.ref_name != "refs/heads/master" {
            eprintln!("[!] REJECTED only submission to master branch is allowed");
            exit(1)
        }

        let srcinfo_bytes = read_srcinfo_from_commit(&info.new_oid);
        let srcinfo: SRCInfo = serde_json::from_slice(&srcinfo_bytes)
            .inspect_err(|e| {
                eprintln!("error parsing .srcinfo.json: {}", e);
                exit(1)
            })
            .unwrap();

        update_srcinfo(&srcinfo)
    }
}
