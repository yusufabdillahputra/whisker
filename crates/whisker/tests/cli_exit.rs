use assert_cmd::Command;

#[test]
fn serve_with_missing_env_exits_non_zero_and_names_variable() {
    let out = Command::cargo_bin("whisker")
        .unwrap()
        .env_clear()
        .arg("serve")
        .assert()
        .failure()
        .get_output()
        .clone();
    let stderr = String::from_utf8_lossy(&out.stderr);
    assert!(stderr.contains("DATABASE_URL"), "stderr: {stderr}");
}
