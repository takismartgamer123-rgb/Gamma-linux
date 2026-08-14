# Contributing to Gamma Linux

Thank you for your interest in contributing to Gamma Linux. Gamma is a lightweight, free, open-source project focused on reviving older PCs — and contributions from people like you keep it alive. This document explains how to contribute in a productive, professional way.

## Contents
- Welcome
- Ways to contribute
- Reporting bugs (required fields)
- Feature requests
- How to open an issue
- Pull request workflow
- Branching & commit message guidelines
- Development and testing recommendations
- PR checklist
- Communication channels and contact
- License and acknowledgments

## Welcome
Gamma aims to be small, auditable, and practical. We welcome:
- Bug reports with clear reproduction steps and system details.
- Patches and improvements to build scripts, installer flows, and hardware detection.
- Documentation fixes and translations.
- Testing on real legacy hardware and VMs.

## Ways to contribute
- File reproducible bug reports
- Open feature requests or discuss design in issues
- Submit pull requests with small, focused changes
- Test ISOs on real devices and VMs, report results
- Improve documentation and examples

## Reporting bugs (please include)
When filing a bug report, include as much of the following as you can — these details help us reproduce and fix problems faster:

- PC model (manufacturer and model)
- CPU model
- RAM amount
- Storage type and size (HDD or SSD and capacity)
- Gamma edition and exact version (for example: Gamma Pro-MaxMini v2.7 Warden)
- Steps to reproduce the issue
- A photo or clear description of the problem (screenshots are highly recommended)
- Relevant logs if available (dmesg, installer logs, Xorg/Wayland logs, system journal entries)
- Any partitioning or disk layout details involved in the problem

If the issue involves installation or disk access, avoid sending sensitive data. Only provide the minimum system details required to reproduce the problem.

## Feature requests
Open a new issue describing:
- The problem or use-case
- Proposed solution or design sketch
- Backwards compatibility and migration notes (if applicable)
- Any known alternatives or related issues

## How to open an issue
- Choose a clear, descriptive title
- Use the template below (we will include a template in the issue tracker; try to fill the fields)
- Add screenshots/logs as attachments when helpful

### Issue template (suggested)
- Title: Short, descriptive
- Description: What happened and when
- Steps to reproduce: numbered steps
- Expected behavior
- System details (PC model, CPU, RAM, storage, edition/version)
- Attachments: screenshots, photos, logs

## Branching & commit messages
- Branch from the default branch (usually `main`).
- Use descriptive topic branches:
  - `feature/<short-description>`
  - `fix/<short-description>`
  - `docs/<short-description>`
- Keep commits small and focused. Each commit should do one thing.
- Commit message style:
  - Short summary line (50 characters or less)
  - Optional body explaining the reasoning and any important details
  - Example: `fix(installer): avoid mbr overwrite on some BIOSes`

## Pull request workflow
- Open a PR against the default branch.
- Link the related issue (if any) and explain the change, testing steps, and expected impact.
- If the PR affects user-visible behavior, update README or release notes accordingly.
- Keep PRs small to speed review and testing.

## Development & testing recommendations
- Test changes in a VM (QEMU/VirtualBox) and, when safe, on one non-critical physical device before wider testing.
- For ISO builds: run the ISO in a VM and perform an installer run. Document the environment used for testing in the PR description.
- When testing installer/disk changes, test on expendable hardware or in a VM using drive images — never test destructive operations on primary machines.

## PR checklist for contributors
- [ ] Branch and commit names follow guidelines
- [ ] PR description explains what, why, and how to test
- [ ] Relevant logs, screenshots, or test results attached
- [ ] Documentation (README/CHANGELOG) updated if needed
- [ ] No sensitive data included in the PR
- [ ] Built artifacts (if any) reproducible with the repository instructions

## Code style & languages
- Primary repository languages: Shell, C, CMake.
- Follow existing formatting in repository scripts and sources.
- Keep changes minimal and well-documented in changelogs or PR descriptions.

## Security & sensitive issues
If you discover a security vulnerability, please do not open a public issue. Contact the maintainers privately:

- Email: takismartgamer123@gmail.com

Provide clear, reproducible steps and relevant logs; we will respond and coordinate disclosure or fixes.

## Communication & support
- Email: takismartgamer123@gmail.com (general contact)
- Telegram: https://t.me/GammaLinuxDZ
- Messenger: https://m.me/j/AbahTOn_gqLy8R3k/?send_source=gc%3Acopy_invite_link_t

## Roadmap and coordination
Check issues and pinned discussions for current roadmap items. If your contribution aligns with a planned area, mention the related issue/roadmap item in your PR to speed acceptance.

## DistroWatch
Support Gamma by voting on DistroWatch:

https://distrowatch.com/dwres-mobile.php?waitingdistro=1101&resource=links#new

## License
Contributions are accepted under the repository’s license. By submitting a PR you agree to license your contribution under the project license. See LICENSE in the repository for details.

## Thank you
Thank you for helping revive older PCs and keeping Gamma small, fast, and community-driven. We appreciate careful, tested contributions.
