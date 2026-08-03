# Gate Licensing

Gate Core is licensed under the **Apache License 2.0**.

The public gateway, CLI, provider adapters, OpenAI/Anthropic compatibility
layers, MCP integration, DLP primitives, signed audit foundations, policy
engine primitives, presets, deployment manifests, and documentation in this
repository are open source and may be used commercially under Apache-2.0.

## Open Source License: Apache-2.0

Apache-2.0 lets you use, copy, modify, distribute, sublicense, and sell Gate
Core, including in commercial and proprietary products, as long as you comply
with the license notice and attribution requirements.

Apache-2.0 also includes an explicit patent license from contributors, which is
important for infrastructure software deployed inside companies.

See the [LICENSE](LICENSE) file for the full legal text and [NOTICE](NOTICE) for
project attribution.

## Commercial Products

The open-source core is the data plane. Advanced packaged products and managed
offerings may be commercial:

| Product | License | Includes |
|---------|---------|----------|
| **Gate Core** | Apache-2.0 | LLM gateway and routing, OpenAI/Anthropic-compatible APIs, providers, DLP primitives, signed audit log foundations, policy engine primitives, HIT approval primitives, CLI, OIDC, JSONL audit export, presets, Helm chart |
| **Gate Admin** | Commercial | Web console: policy builder, audit explorer, compliance evidence dashboard, fleet and tenant management, GitOps manifest generation, license management, multi-instance health |
| **Gate Enterprise** | Commercial | HA / clustering / active-active, multi-region operations, advanced SIEM connectors, turnkey policy packs, advanced RBAC, multi-level approval, air-gap bundle, signed long-term retention |
| **Gate Cloud** | Commercial SaaS | Dedicated hosted instance-per-tenant, Admin included, managed operations |
| **Gate Trace-to-Automation** | Commercial or source-available | Advanced trace replay, workflow synthesis, production evidence packs, and automation templates |

The Core / Enterprise / Admin boundary follows
[ADR-0029](docs/decisions/0029-relicense-core-apache.md): primitives and
interfaces belong in the open-source core; turnkey packaged workflows, managed
operations, advanced UI, and long-term compliance evidence products can be
commercial.

## Commercial Tiers

Commercial Pro / Business / Enterprise / Cloud tiers — with support, procurement
terms, managed operations, and redistribution or OEM rights — are available on
request. Pricing depends on deployment size, support level, and regulatory
requirements.

Open a contact request through the
[maintainer profile](https://github.com/murillo-consulting) for current tiers and quotes.

## Compliance Wording

Gate does not make an organization compliant by itself and is not a substitute
for legal review, certification, or provider due diligence.

The accurate claim is:

> Gate provides compliance controls and audit evidence mapping for EU AI Act,
> GDPR/RGPD, NIS2/DORA, and HDS/PCI-style audit requirements. Gate is not
> certified by default.

Operators still need to enable and configure the relevant controls, choose
providers whose contractual and regional guarantees match their obligations,
and validate the full deployment.

## Contributor License Agreement

Contributions are accepted under the [Gate CLA](CLA.md). The CLA lets Adrien Murillo
distribute contributed code under Apache-2.0 and, when needed, under commercial
or proprietary licenses for paid products. Contributors retain copyright in
their contributions.

The CLA is enforced by the `cla-check` job in CI. The separate
`origin/cla-signatures` branch stores signature evidence and should not be
deleted as routine branch cleanup.

## FAQ

### Can I use Gate internally for free?

Yes. Gate Core is Apache-2.0 and can be used internally or commercially without
a license key.

### Do I need to publish private modifications?

No. Apache-2.0 does not require publishing private modifications or network
service source code.

### Do I need a commercial license to embed Gate?

Not for Gate Core. Apache-2.0 permits commercial embedding. A commercial
agreement may still be useful for support, warranty, indemnity, redistribution
terms, managed deployments, Enterprise modules, or Admin/Cloud products.

### Is the free edition limited by company size or user count?

No. Apache-2.0 places no company-size or user-count limit on Gate Core.

### We need to audit the code under NDA or run air-gapped.

Source review under NDA, an air-gap bundle, and a security package
(SBOM / signatures / offline updates) are available on request through the
[maintainer profile](https://github.com/murillo-consulting).

## Contact

For commercial products, support, or licensing terms, contact the maintainer
through [GitHub](https://github.com/murillo-consulting).
