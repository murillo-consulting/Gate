use crate::{cli, preset};
use anyhow::Context;

/// Validates the configuration by testing each model with real API calls.
pub async fn cmd_validate(config: &cli::AppConfig) -> anyhow::Result<()> {
    println!("🔍 Validating configuration...");
    println!();

    let (registry, _token_store) = preset::build_registry(config)
        .context("Failed to initialize providers; fix your configuration and try again")?;

    println!(
        "  Testing {} model(s) with real API calls...",
        config.models.len()
    );
    println!();

    let results = preset::validate_config(config, &registry).await;
    preset::print_validation_results(&results);
    require_healthy_models(&results)
}

fn require_healthy_models(results: &[preset::ModelValidation]) -> anyhow::Result<()> {
    anyhow::ensure!(!results.is_empty(), "No router models were validated");
    let broken: Vec<_> = results
        .iter()
        .filter(|result| !result.any_ok())
        .map(|result| result.model_name.as_str())
        .collect();
    anyhow::ensure!(
        broken.is_empty(),
        "Models with no healthy provider: {}",
        broken.join(", ")
    );
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn model(health: &[bool]) -> preset::ModelValidation {
        preset::ModelValidation {
            model_name: "test-model".into(),
            role: "default".into(),
            mappings: health
                .iter()
                .map(|ok| preset::MappingResult {
                    priority: 1,
                    provider: "test".into(),
                    actual_model: "test".into(),
                    ok: *ok,
                    detail: String::new(),
                })
                .collect(),
        }
    }

    #[test]
    fn validation_fails_for_empty_or_unusable_models() {
        assert!(require_healthy_models(&[]).is_err());
        assert!(require_healthy_models(&[model(&[])]).is_err());
        assert!(require_healthy_models(&[model(&[false])]).is_err());
        assert!(require_healthy_models(&[model(&[true]), model(&[false])]).is_err());
    }

    #[test]
    fn validation_accepts_a_working_fallback() {
        assert!(require_healthy_models(&[model(&[true])]).is_ok());
        assert!(require_healthy_models(&[model(&[false, true])]).is_ok());
    }
}
