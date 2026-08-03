use clap::CommandFactory;
use clap_complete::{generate, Shell};

/// Prints shell completion script for the specified shell to stdout.
pub fn cmd_completions<C: CommandFactory>(shell: Shell) {
    let mut cmd = C::command();
    generate(shell, &mut cmd, "gate", &mut std::io::stdout());
    match shell {
        Shell::Zsh => eprintln!("\n# Add to ~/.zshrc:\n# eval \"$(gate completions zsh)\""),
        Shell::Bash => {
            eprintln!("\n# Add to ~/.bashrc:\n# eval \"$(gate completions bash)\"")
        }
        Shell::Fish => eprintln!("\n# Run: gate completions fish | source"),
        _ => {}
    }
}
