use std::fs;
use std::io::{self, ErrorKind};
use std::path::PathBuf;

/// Returns the path to the PID file.
pub fn pid_file_path() -> PathBuf {
    crate::gate_home()
        .unwrap_or_else(|| PathBuf::from(".gate"))
        .join("gate.pid")
}

/// Writes the current process PID to the PID file.
///
/// # Errors
///
/// Returns an [`io::Error`] if the parent directory cannot be created or the
/// PID file cannot be written.
pub fn write_pid() -> io::Result<()> {
    let pid_file = pid_file_path();

    // Create parent directory if it doesn't exist
    if let Some(parent) = pid_file.parent() {
        fs::create_dir_all(parent)?;
    }

    let pid = std::process::id();
    fs::write(&pid_file, pid.to_string())?;
    tracing::info!("PID {} written to {:?}", pid, pid_file);
    Ok(())
}

/// Reads the PID from the PID file.
///
/// # Errors
///
/// Returns an [`io::Error`] if the PID file cannot be read, or
/// [`ErrorKind::InvalidData`] if its contents do not parse as a `u32`.
pub fn read_pid() -> io::Result<u32> {
    let pid_file = pid_file_path();
    let pid_str = fs::read_to_string(&pid_file)?;
    pid_str
        .trim()
        .parse::<u32>()
        .map_err(|e| io::Error::new(ErrorKind::InvalidData, e))
}

/// Removes the PID file.
///
/// # Errors
///
/// Returns an [`io::Error`] if the PID file exists but cannot be removed.
pub fn cleanup_pid() -> io::Result<()> {
    let pid_file = pid_file_path();
    if pid_file.exists() {
        fs::remove_file(&pid_file)?;
        tracing::info!("PID file removed: {:?}", pid_file);
    }
    Ok(())
}

/// Removes the PID file only if it still belongs to the current process.
///
/// Hot upgrades briefly run two Gate processes on the same port. The new process
/// writes its PID before the old process finishes draining, so shutdown cleanup
/// must not blindly delete a PID file that has already been claimed by the new
/// instance.
pub fn cleanup_pid_if_current() -> io::Result<()> {
    let pid_file = pid_file_path();
    let current_pid = std::process::id();

    match read_pid() {
        Ok(pid) if pid == current_pid => {
            fs::remove_file(&pid_file)?;
            tracing::info!("PID file removed: {:?}", pid_file);
        }
        Ok(pid) => {
            tracing::debug!(
                "PID file {:?} belongs to {}, not {}; leaving it in place",
                pid_file,
                pid,
                current_pid
            );
        }
        Err(e) if e.kind() == ErrorKind::NotFound => {}
        Err(e) => return Err(e),
    }

    Ok(())
}

/// Check if a Gate process is running at the given PID.
/// On Unix platforms, additionally verifies the command identity where the OS
/// exposes it (guards against stale PID files after PID reuse).
#[cfg(all(unix, feature = "unix-signals"))]
pub fn is_process_running(pid: u32) -> bool {
    use nix::sys::signal::kill;
    use nix::unistd::Pid;

    // Signal 0 (None) checks process existence without side effects
    if kill(Pid::from_raw(pid as i32), None).is_err() {
        return false;
    }

    #[cfg(target_os = "linux")]
    {
        let cmdline_path = format!("/proc/{}/cmdline", pid);
        if let Ok(cmdline) = fs::read(&cmdline_path) {
            let cmdline_str = String::from_utf8_lossy(&cmdline);
            if !command_invokes_gate(&cmdline_str) {
                return false;
            }
        } else {
            return false;
        }
    }

    #[cfg(target_os = "macos")]
    {
        let output = std::process::Command::new("ps")
            .args(["-p", &pid.to_string(), "-o", "command="])
            .output();
        match output {
            Ok(output) if output.status.success() => {
                let command = String::from_utf8_lossy(&output.stdout);
                if !command_invokes_gate(&command) {
                    return false;
                }
            }
            _ => return false,
        }
    }

    true
}

#[cfg(all(unix, feature = "unix-signals"))]
fn command_invokes_gate(command: &str) -> bool {
    // The command string arrives in two shapes: Linux `/proc/<pid>/cmdline` is
    // NUL-separated (`gate\0start\0`), while macOS `ps -o command=` is
    // space-separated (`/opt/homebrew/bin/gate start`). Splitting only on `\0`
    // left the macOS form intact, so `Path::file_name` on
    // `"…/gate start"` returned `"gate start"` (≠ `"gate"`) and `gate stop`
    // refused to stop its own daemon. Pick the separator by which one is present.
    let first_arg = if command.contains('\0') {
        command.split('\0').next()
    } else {
        command.split_whitespace().next()
    }
    .unwrap_or_default()
    .trim();
    let executable = std::path::Path::new(first_arg)
        .file_name()
        .and_then(|name| name.to_str())
        .unwrap_or(first_arg);

    if executable == "gate" {
        return true;
    }

    std::env::current_exe()
        .ok()
        .and_then(|path| path.file_name().map(|name| name.to_owned()))
        .and_then(|name| name.to_str().map(str::to_owned))
        .is_some_and(|current| executable == current)
}

/// Fallback when nix is unavailable: only our own PID is considered valid.
#[cfg(all(unix, not(feature = "unix-signals")))]
pub fn is_process_running(pid: u32) -> bool {
    pid == std::process::id()
}

/// Checks if a process with the given PID exists via tasklist.
#[cfg(windows)]
pub fn is_process_running(pid: u32) -> bool {
    match std::process::Command::new("tasklist")
        .args(["/FI", &format!("PID eq {}", pid), "/NH"])
        .output()
    {
        Ok(output) => {
            let stdout = String::from_utf8_lossy(&output.stdout);
            !stdout.contains("No tasks")
        }
        Err(_) => false,
    }
}

#[cfg(test)]
mod tests {
    #[cfg(all(unix, feature = "unix-signals"))]
    use super::command_invokes_gate;

    #[cfg(all(unix, feature = "unix-signals"))]
    #[test]
    fn command_identity_accepts_only_gate_executable() {
        assert!(command_invokes_gate("/Users/me/bin/gate\0start\0"));
        assert!(!command_invokes_gate("/tmp/gate-upgrade --config x"));
        assert!(!command_invokes_gate("/usr/bin/python /tmp/gate.py"));
        assert!(!command_invokes_gate("/usr/bin/agate-helper"));
    }

    /// macOS `ps -o command=` is space-separated; the executable and its args
    /// must not be read as one path component. This is the exact string that
    /// made `gate stop` refuse to stop a live daemon.
    #[cfg(all(unix, feature = "unix-signals"))]
    #[test]
    fn command_identity_accepts_space_separated_macos_form() {
        assert!(command_invokes_gate("/opt/homebrew/bin/gate start"));
        assert!(command_invokes_gate("/opt/homebrew/bin/gate start\n"));
        assert!(command_invokes_gate("gate start -d"));
        // A non-gate program with a gate-ish argument still must not match.
        assert!(!command_invokes_gate("/usr/bin/python gate start"));
    }
}
