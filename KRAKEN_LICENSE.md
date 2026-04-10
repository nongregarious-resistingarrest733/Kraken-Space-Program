# The Kraken License
### Version 1.0

---

## Preamble

Software exists to serve people. It is a tool for human progress, collaboration, and the betterment of society. The Kraken License is built on the belief that software should be:

- **Auditable** — anyone should be able to inspect code for backdoors, hidden telemetry, and vulnerabilities
- **Ethical** — software must not be used as a weapon against human rights
- **Transparent** — the software supply chain should be honest and visible to everyone, including end users
- **Free where possible** — collaboration and open development should be the default
- **Liberating over time** — abandoned software must not rot in legal limbo; it belongs to everyone

This license exists in three intercompatible tiers. All tiers share the same ethical baseline. The choice of tier belongs to the developer.

### A note on copyleft

This license is **not** a copyleft license. Derivatives are not required to be open source. The requirement that Tier 1 derivatives carry the Kraken License exists solely to preserve the ethical baseline — not to force openness. Tier 2 is not a lockdown: source remains publicly auditable, binaries are freely distributable, and personal modifications are permitted. Tier 3 carries zero propagation requirements whatsoever. The freedom to choose between tiers is a feature, not a restriction. What propagates is the **ethical baseline**, not an openness requirement. This is **copymiddle**.

### A note on commercial use

**Commercial use is explicitly permitted under all three tiers.** You may sell software, offer paid services, build businesses, and profit from projects using this license. Your business model is never restricted by this license — only the ethical conditions of Section 4 and the tier-specific rules you have chosen apply. These restrictions govern what you do with the licensed source code specifically — they say nothing about your own original work, your pricing, or how you run your business.

### A note on jurisdiction

This license does not specify a governing jurisdiction. This is an intentional philosophical choice consistent with its international ethical framing. Where disputes arise, the spirit of the United Nations Declaration of Human Rights shall serve as interpretive guidance, alongside general principles of contract law as applicable in the jurisdiction where the alleged violation occurred.

---

## Definitions

- **"Software"** refers to the source code, compiled binaries, documentation, and associated files covered by this license.
- **"You"** refers to the individual or Legal Entity exercising the rights granted by this license.
- **"Legal Entity"** means a legally registered organization and its **permanent, full-time employees** — individuals employed directly by the organization on an ongoing basis. This explicitly excludes contractors, freelancers, consultants, agency staff, and any other individuals engaged on a temporary or project basis, regardless of how closely they operate with the organization. A sole proprietor, single-member LLC, or individual acting in a personal capacity is considered a Legal Entity of one and is fully covered by the personal use rights granted herein.
- **"Personal Modification"** means any modification that remains internal to the Legal Entity making it, and is not distributed, published, or transferred outside of that Legal Entity.
- **"Academic Use"** means use for the purposes of study, research, or instruction, internal to an educational institution, that does not involve redistribution of the Software or its source code to parties outside that institution.
- **"Compiled Binary"** means the Software in a compiled, executable, or otherwise non-human-readable form.
- **"Contribution"** means any commit, pull request, patch, or other meaningful change to the Software's source code accepted into any official repository designated by the current maintainer.
- **"Contributor"** means any individual or Legal Entity that submits a Contribution.
- **"Last Contribution Date"** means the date of the most recent accepted Contribution.
- **"Maintainer Activity"** means any act of project governance including merging contributions, managing issues, making architectural decisions, or directing the project's development in any capacity. Writing code personally is not required. A maintainer who manages, directs, or governs the project without writing code is considered fully active.
- **"Rider"** means the ethical conditions of Section 4 and the patent provisions of Section 5, which attach to and travel with Tier 3 Software regardless of the license of the host project.
- **"Successor Fork"** means a fork of the Software that has, for a continuous period of at least 12 months, demonstrated more active commits and more active issue resolution than the original repository, and has publicly identified itself as the successor or continuation of the original project. All three conditions must be met simultaneously.

---

## Tier 1 — Open License

### Grant of Rights

Subject to the ethical conditions in Section 4, You are granted a perpetual, worldwide, royalty-free license to:

1. Use the Software for any purpose, including commercially
2. Study and modify the source code
3. Distribute the Software in source or binary form
4. Use the Software as a dependency in any project, under any license
5. Build and sell products and services using the Software

### Conditions

1. The Kraken License text must be included in all copies or substantial portions of the Software. No attribution to the original author by name is required.
2. Any project that incorporates or derives from Tier 1 Software must itself be licensed under Tier 1, Tier 2, or Tier 3 of the Kraken License, preserving the ethical baseline. The choice of tier belongs to the developer of the derivative.

### Fork Protection

If a Successor Fork of Tier 1 Software exists, that Successor Fork inherits the same tier as the original. It may not be relicensed to any license outside the Kraken License. The ethical baseline and all conditions of the original tier survive in the Successor Fork.

### Abandonware Clause

If the Software has received no accepted Contributions for a continuous period of **6 (six) years** from the Last Contribution Date, the Software shall automatically and irrevocably transition to **Tier 1** of the Kraken License. From that date forward, all Tier 1 rights apply. The Kraken License text must still be preserved following transition.

### Dead Maintainer Clause

If the maintainer has shown no Maintainer Activity for a continuous period of **2 (two) years**, AND the project has received at least **2 (two)** accepted Contributions from community members during that same period, governance of the project transfers automatically to the active contributor community. The tier and all license conditions remain unchanged. The community may designate a new maintainer by consensus. This clause exists to keep active projects alive, not to penalize slow or hands-off maintainers who remain engaged in any governance capacity.

---

## Tier 2 — Source Available License

### Grant of Rights

Subject to the ethical conditions in Section 4, You are granted a perpetual, worldwide, royalty-free license to:

1. **Read and study** the source code for Academic Use or personal learning
2. **Make Personal Modifications** that remain internal to Your Legal Entity
3. **Use and distribute Compiled Binaries** of the Software as a dependency in any project, under any license, including commercially
4. **Report bugs** and contribute fixes back to the original developers
5. **Build and sell products and services** that incorporate the Compiled Binaries of the Software

### Restrictions

1. You **may not** distribute, publish, or otherwise transfer the source code to any party outside Your Legal Entity.
2. You **may not** include the source code of Tier 2 Software in another project's repository or codebase.
3. You **may not** sublicense or relicense the Software.
4. Personal Modifications **may not** be redistributed in source form outside Your Legal Entity.

### Clarification on Ownership

These restrictions apply solely to the licensed Software itself. They place no restrictions whatsoever on Your own original work, your application's source code, your business model, or how you distribute your own software. A product that incorporates Tier 2 Compiled Binaries as a dependency remains entirely Yours. Only the Tier 2 component's source is restricted — not anything You wrote yourself.

### Transparency Manifest

Any distribution of Compiled Binaries under this tier must be accompanied by a `KRAKEN_MANIFEST.md` file containing at minimum the following information:

```
# Kraken Manifest
## Software Name: [name]
## Version: [version]
## License Tier: Tier 2
## Description: [what this binary does]
## Data Collection: [what data, if any, this binary collects]
## Network Activity: [what external connections, if any, this binary makes]
## Known Dependencies: [list of major dependencies]
```

This manifest exists to preserve the auditable nature of Tier 2 Software even when source code is not directly accessible. It must be kept accurate and updated with each new binary release.

### Abandonware Clause

If the Software has received no accepted Contributions for a continuous period of **6 (six) years** from the Last Contribution Date, the Software shall automatically and irrevocably transition to **Tier 1** of the Kraken License. From that date forward, all Tier 1 rights apply. The Kraken License text must still be preserved following transition.

### Dead Maintainer Clause

If the maintainer has shown no Maintainer Activity for a continuous period of **2 (two) years**, AND the project has received at least **2 (two)** accepted Contributions from community members during that same period, governance of the project transfers automatically to the active contributor community. The tier and all license conditions remain unchanged. The community may designate a new maintainer by consensus.

---

## Tier 3 — Permissive License

Tier 3 is the most permissive tier of the Kraken License. It is designed for maximum compatibility with any existing license, including MIT, Apache 2.0, BSD, and proprietary licenses, while preserving the ethical baseline and patent protections that make the Kraken License distinct.

### Grant of Rights

Subject to the ethical conditions in Section 4, You are granted a perpetual, worldwide, royalty-free license to:

1. Use the Software for any purpose, including commercially
2. Study and modify the source code
3. Distribute the Software in source or binary form
4. **Include the source code directly in any project, under any existing license**
5. Build and sell products and services using the Software
6. Use the Software as a dependency in any project without requiring that project to adopt the Kraken License

### Conditions

1. The Kraken License text must be included alongside the Software or the component derived from it. No attribution to the original author by name is required.
2. **No propagation.** The host project is not required to adopt any tier of the Kraken License. The Tier 3 component coexists with the host project's existing license as an extension.
3. The **Rider** — the ethical conditions of Section 4 and the patent provisions of Section 5 — attaches to the Tier 3 component and travels with it into any host project. These conditions apply specifically to the Tier 3 component's use within the larger project, and extend as additional obligations to the host project solely by virtue of the Tier 3 component's presence.

### Fork Protection

If a Successor Fork of Tier 3 Software exists, that Successor Fork inherits Tier 3. It may not be relicensed to any license outside the Kraken License. The Rider survives in the Successor Fork.

### Abandonware Clause

If the Software has received no accepted Contributions for a continuous period of **6 (six) years** from the Last Contribution Date, the Software shall automatically and irrevocably transition to **Tier 1** of the Kraken License. From that date forward, all Tier 1 rights apply. The Kraken License text must still be preserved following transition.

### Dead Maintainer Clause

If the maintainer has shown no Maintainer Activity for a continuous period of **2 (two) years**, AND the project has received at least **2 (two)** accepted Contributions from community members during that same period, governance of the project transfers automatically to the active contributor community. The tier and all license conditions remain unchanged. The community may designate a new maintainer by consensus.

---

## Section 4 — Ethical Conditions (All Tiers)

The rights granted under all tiers are conditioned on compliance with the following. The **United Nations Declaration of Human Rights (UDHR)** serves as the interpretive ethical guidance of this license. The enumerated prohibitions below are derived directly from it.

You **may not** use the Software:

1. **In autonomous weapons systems** designed to select and engage targets without meaningful human oversight — *UDHR Article 3 (right to life)*
2. **In mass surveillance systems** targeting civilian populations based on race, ethnicity, religion, gender, sexual orientation, political opinion, or national origin — *UDHR Articles 2, 12*
3. **In systems designed to suppress political dissent**, including systems used to identify, track, or persecute individuals for the exercise of rights protected under the UDHR — *UDHR Articles 18, 19, 20*
4. **By any entity** credibly documented by the International Criminal Court, UN Special Rapporteurs, or equivalent internationally recognized human rights bodies as responsible for genocide, war crimes, or crimes against humanity — *UDHR Article 3*
5. **In systems that enforce or perpetuate discrimination** in violation of Articles 1, 2, and 7 of the UDHR
6. **In systems designed to facilitate torture**, cruel, inhuman, or degrading treatment — *UDHR Article 5*
7. **In systems that deny or obstruct access to legal remedy** — *UDHR Article 8*

The UDHR serves as interpretive guidance for edge cases not explicitly enumerated above. It does not carry independent binding legal force under this license but informs the intent and spirit of these conditions.

---

## Section 5 — Patents

### Patent Grant

Each Contributor grants You a perpetual, worldwide, royalty-free, non-exclusive license under any patent claims held by that Contributor that are necessarily infringed by their Contribution alone or in combination with the Software. This grant applies to patents held by the Contributor at the time of the Contribution, **and to any patents subsequently transferred to any entity under the Contributor's control or direction**, regardless of corporate structure or intermediary.

### Patent Retaliation

If You initiate patent litigation — including cross-claims or counterclaims — against any party alleging that the Software or a Contribution infringes a patent, **Your rights under this license terminate automatically and immediately** on the date such litigation is filed. No cure period applies to patent retaliation termination.

---

## Section 6 — Whistleblower Protection

If You discover in good faith that the Software is being used in violation of Section 4, You may publicly disclose that violation without fear of legal retaliation under this license. This protection applies solely to disclosures made in good faith regarding Section 4 violations. It does not protect the disclosure of unrelated private information, proprietary data, or any content not directly relevant to the alleged Section 4 violation. A disclosure is considered made in good faith if the disclosing party reasonably believed the violation to be real and material at the time of disclosure.

---

## Section 7 — Right to Know

If an end user of any software built with Kraken licensed components asks whether that software incorporates Kraken licensed code, the distributor must answer honestly. Deliberate denial or misrepresentation of the presence of Kraken licensed components to an end user constitutes a breach of this license. No end user may be deceived about the software supply chain of a product they are using.

---

## Section 8 — Credits

1. The Kraken License text must be included in all distributions of the Software, in source or binary form.
2. **No attribution to the original author by name is required.** You are not obligated to state that your software uses a specific library or that it was written by a specific person. The presence of the license text is sufficient.

---

## Section 9 — Warranty

By default, the Software is provided **"as is"**, without warranty of any kind, express or implied, including but not limited to warranties of merchantability, fitness for a particular purpose, or non-infringement.

**However**, the developer or distributor may explicitly override this default by providing a separate written warranty agreement. Any such warranty is solely the responsibility of the party offering it and does not bind other contributors or distributors.

---

## Section 10 — Limitation of Liability

In no event shall any contributor be liable for any direct, indirect, incidental, special, or consequential damages arising from the use or inability to use the Software, except where required by applicable law.

---

## Section 11 — Termination

Your rights under this license terminate automatically upon any breach of its conditions.

However, if the breach is cured within **30 (thirty) days** of the date You first became aware of the breach (or reasonably should have become aware), Your rights reinstate automatically. Reinstatement for the same breach is available only once.

Termination does not affect any party who has received the Software from You under this license prior to termination, provided they remain in compliance.

Patent retaliation termination under Section 5 is immediate and not subject to the cure period.

---

## Section 12 — Tier Compatibility

| | Used in T1 project | Used in T2 project | Used in T3 project | Used in any other license |
|---|---|---|---|---|
| **T1 dependency (source)** | ✅ | ✅ | ✅ | ❌ must adopt T1/T2/T3 |
| **T2 dependency (binary only)** | ✅ | ✅ | ✅ | ✅ |
| **T3 dependency (source or binary)** | ✅ | ✅ | ✅ | ✅ Rider attaches |

- **Tier 1** derivatives must adopt Tier 1, Tier 2, or Tier 3.
- **Tier 2** source may not enter any other project's codebase. Compiled Binaries may be used anywhere.
- **Tier 3** source and binaries may be used in any project under any license. The Rider attaches to the component and extends as additional obligations to the host project.
- The ethical conditions of Section 4 and patent provisions of Section 5 propagate to all uses across all tiers.
- Tier 2 and Tier 3 Software automatically become Tier 1 after **6 (six) years** of no Contributions, as described in the Abandonware Clause.

---

## Section 13 — Severability

If any provision of this license is found unenforceable or invalid under applicable law, that provision shall be modified to the minimum extent necessary to make it enforceable, or severed if modification is not possible. The remaining provisions continue in full force and effect.

---

## How to Apply This License

To apply the Kraken License to your project:

1. **Include the full license text** as `KRAKEN_LICENSE.md` in the root of your repository.
2. **Create a `LICENSE` file** in the root of your repository containing your tier declaration:

```
This software is licensed under the Kraken License v1.0 — Tier [1, 2, or 3]
Full license text: see KRAKEN_LICENSE.md
```

3. **Optionally**, include a short header in your source files:

```
// SPDX-License-Identifier: Kraken-T1  (or Kraken-T2 / Kraken-T3)
// Copyright (c) [YEAR] [YOUR NAME]
// Licensed under the Kraken License v1.0. See KRAKEN_LICENSE.md for details.
```

4. **If distributing Tier 2 Compiled Binaries**, include a `KRAKEN_MANIFEST.md` file alongside your binary. See the Transparency Manifest section in Tier 2 for the required template.

5. The full `KRAKEN_LICENSE.md` travels with the project. No external URL dependency. No external lookup required. Anyone reading the repository has everything they need.

Note: `Kraken-T1`, `Kraken-T2`, and `Kraken-T3` are not yet registered SPDX identifiers. Tooling that parses SPDX headers will not recognize them until registration is submitted. This is a known limitation to be addressed if the license gains traction.

---

## Changelog

### v1.0 *(current)*
- Production ready
- Whistleblower protection clause added — good faith Section 4 disclosures cannot be legally retaliated against under this license
- Right to Know clause added — distributors must honestly disclose Kraken licensed components to end users on request
- Fork protection finalized — Successor Fork definition added, T1 and T3 forks inherit original tier
- Transparency Manifest finalized — `KRAKEN_MANIFEST.md` template included in Tier 2
- Dead Maintainer Clause finalized across all tiers — 2 year inactivity + 2 community contributions triggers governance transfer
- How to Apply updated to reference Transparency Manifest
- All section numbers updated to reflect new sections

### v0.9
- Final pre-release review and polish
- Clarifications to Rider definition and Tier 3 host project obligations
- Compatibility table reviewed and confirmed accurate across all three tiers
- Language consistency pass across all sections
- Preamble updated to include Transparent as a core principle

### v0.8
- Fork Protection clause added to Tier 1 and Tier 3
- Successor Fork defined
- Transparency Manifest draft added to Tier 2
- `KRAKEN_MANIFEST.md` template drafted

### v0.7
- Whistleblower Protection draft added
- Right to Know draft added
- Dead Maintainer Clause draft added across all tiers
- Maintainer Activity definition added

### v0.6
- **Tier 3 added** — permissive tier, zero propagation, source includable in any project under any license, Rider attaches to component and extends to host project
- Tier 1 propagation updated — derivatives may now choose Tier 1, Tier 2, or Tier 3
- Compatibility table added to Section 12 for clarity
- Commercial use explicitly celebrated in preamble with clarifying language
- Tier 2 clarification added — restrictions apply solely to the licensed Software, not the licensee's own original work
- Rider definition added for Tier 3 ethical/patent attachment mechanism

### v0.5
- Sole proprietor / single-member LLC / individual acting personally now explicitly covered as "Legal Entity of one"
- UDHR reframed as interpretive guidance rather than binding legal instrument throughout
- Section 4 catchall clarified to be explicitly non-binding, guidance-only
- Copymiddle note in preamble strengthened — ethical baseline propagation explicitly distinguished from openness propagation
- SPDX identifiers clarified as `Kraken-T1` / `Kraken-T2` to avoid version number confusion
- Changelog added

### v0.4
- Termination clause added with **30 (thirty) day** cure period for non-patent breaches
- Patent retaliation termination confirmed as immediate with no cure period
- Severability clause added
- "Official repository designated by current maintainer" replaces "primary repository" throughout

### v0.3
- Patent grant added — Contributors auto-grant royalty-free license to necessarily infringed patents
- Shell company / post-contribution patent transfer clause added — grant follows Contributor's control, not corporate wrapper
- Patent retaliation clause added — self-executing, immediate termination on filing
- How to Apply section added

### v0.2
- Legal Entity tightened to permanent full-time employees only, contractors explicitly excluded
- UDHR article citations added inline to Section 4 prohibitions
- Credits section added — license text required, author namedrop not required
- Copymiddle note added to preamble
- Jurisdiction note added to preamble

### v0.1
- Initial draft

---

## Copyright

Copyright (c) 2026 Seraphina

This software is licensed under the Kraken License v1.0. See above for full terms.

---

*The Kraken License is an independent license not affiliated with OSI, FSF, or any other standards body. Contributions to improve and formalize this license are welcome.*

🦑
