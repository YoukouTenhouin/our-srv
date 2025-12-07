use clap::Parser;
use reqwest::blocking::Client;
use serde::{Deserialize, Serialize};
use std::env::var;
use std::fs::{create_dir_all, exists, remove_dir_all};
use std::os::unix::process::CommandExt;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio, exit};

#[derive(Parser)]
struct Args {
    #[arg(short, long)]
    user: String,
}

#[derive(Serialize, Deserialize)]
struct Package {
    name: String,
    maintainer: Option<String>,
}

#[derive(Deserialize)]
struct Data {
    data: Package,
}

fn get_original_command() -> Option<Vec<String>> {
    let original_cmd = var("SSH_ORIGINAL_COMMAND").ok()?;
    shlex::split(&original_cmd)
}

fn fetch_package_info<S: AsRef<str>>(pkg: S) -> Option<Package> {
    let baseurl = var("OUR_API_BASEURL").unwrap();
    let res = Client::new()
        .get(format!("{}/api/package/{}", baseurl, pkg.as_ref()))
        .send()
        .unwrap_or_else(|e| {
            eprintln!("failed to make API request: {}", e);
            exit(-1)
        });
    if !res.status().is_success() {
        let code = res.status().as_u16();
        if code == 404 {
            return None;
        } else {
            eprintln!("API server responded with code {code}");
            exit(-1)
        }
    }

    let data: Data = res.json().unwrap_or_else(|e| {
        eprintln!("error parsing API server response: {e}");
        exit(-1)
    });
    Some(data.data)
}

fn create_package_on_server(pkg: Package) {
    let baseurl = var("OUR_API_BASEURL").unwrap();
    let res = Client::new()
        .post(format!("{baseurl}/api/package"))
        .json(&pkg)
        .send()
        .unwrap_or_else(|e| {
            eprintln!("failed to make API request: {}", e);
            exit(-1)
        });
    if !res.status().is_success() {
        eprintln!("API server responded with code {}", res.status().as_u16());
        exit(-1)
    }
}

fn ensure_repo<P: AsRef<Path>>(repo_path: P) -> std::io::Result<()> {
    if exists(repo_path.as_ref())? {
        return Ok(());
    }

    // fetch envs here, so in case something went wrong
    // we will panic before any git call
    let hooks_path = var("OUR_GIT_HOOKS").unwrap();

    create_dir_all(repo_path.as_ref())?;

    // initialize bare repo
    let status = Command::new("git")
        .arg("init")
        .arg("--bare")
        .arg(repo_path.as_ref().as_os_str())
        .stdout(Stdio::null())
        .current_dir(repo_path.as_ref())
        .status()?;

    if !status.success() {
        return Err(std::io::Error::other(format!(
            "git init --bare exited with code {}",
            status.code().unwrap()
        )));
    }

    // set git hooks
    let status = Command::new("git")
        .arg("config")
        .arg("core.hooksPath")
        .arg(hooks_path)
        .stdout(Stdio::null())
        .current_dir(repo_path.as_ref())
        .status()?;
    if !status.success() {
        return Err(std::io::Error::other(format!(
            "git config exited with code {}",
            status.code().unwrap()
        )));
    }

    Ok(())
}

fn allowed_in_pkg_name(c: char) -> bool {
    c.is_ascii_alphanumeric() || c == '-' || c == '.' || c == '+' || c == '_'
}

fn main() {
    let args = Args::parse();

    let Some(original_cmd) = get_original_command() else {
        println!("Git shell for openSUSE User Repository");
        println!("Interactive shell is disabled.");
        exit(1)
    };

    let [cmd, repo] = &original_cmd[..] else {
        eprintln!("Invalid command: {:?}", original_cmd);
        exit(1)
    };

    if cmd != "git-receive-pack" && cmd != "git-upload-pack" && cmd != "git-upload-archive" {
        eprintln!("Invalid command: {:?}", original_cmd);
        exit(1)
    }

    let pkg = repo.strip_suffix(".git").unwrap_or_else(|| {
        eprintln!("Invalid repository name: {}", repo);
        exit(1)
    });

    if !pkg.chars().all(allowed_in_pkg_name) {
        eprintln!("Invalid package name: {}", pkg);
        exit(1)
    }

    let repo_path = PathBuf::from(var("OUR_GIT_REPO_BASE").unwrap()).join(repo);

    if let Some(pkg_data) = fetch_package_info(&pkg) {
        if pkg_data.maintainer != Some(args.user) {
            exit(1)
        }
    } else {
        // Package not exist on API server, delete potential stagnant file
        remove_dir_all(&repo_path).ok();
        create_package_on_server(Package {
            name: pkg.to_string(),
            maintainer: Some(args.user),
        });
    }

    ensure_repo(&repo_path).unwrap_or_else(|e| {
        eprintln!("failed to initialize bare repo: {}", e);
        remove_dir_all(&repo_path).ok();
        exit(1)
    });

    let err = Command::new(cmd).arg(repo_path.as_os_str()).exec();
    eprintln!("failed to execute {}: {}", cmd, err);
    exit(1)
}
