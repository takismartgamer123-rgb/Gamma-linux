# Contributing to Gamma Linux

Thank you for considering a contribution to Gamma Linux.

Gamma is a lightweight Linux distribution project focused on extending the useful life of older computers. Contributions are welcome when they are practical, reproducible and respectful of the project's compatibility goals.

- Repository: https://github.com/takismartgamer123-rgb/Gamma-linux
- Issues: https://github.com/takismartgamer123-rgb/Gamma-linux/issues
- Releases: https://github.com/takismartgamer123-rgb/Gamma-linux/releases

## Ways to contribute

You can help by:

- Reporting reproducible bugs.
- Testing release ISOs on real hardware and virtual machines.
- Improving build scripts, installer behavior or hardware compatibility.
- Fixing documentation and translations.
- Proposing focused improvements through GitHub Issues and Pull Requests.

## Before opening an issue

Search existing issues first. If the problem has not already been reported, create a new issue with a descriptive title and include as much relevant information as possible.

### Bug report details

- PC manufacturer and model
- CPU model and architecture (32-bit or 64-bit)
- RAM amount
- Storage type and capacity
- Gamma edition and exact version/build
- Boot mode (Legacy BIOS or UEFI)
- Steps to reproduce the issue
- Expected behavior and actual behavior
- Relevant logs, screenshots or error messages

For installation problems, include the relevant partitioning context, but remove personal information. Never attach passwords, private keys, personal documents or unrelated disk contents.

## Feature requests

A useful feature request explains:

1. The problem or use case.
2. Why the current behavior is insufficient.
3. The proposed change.
4. Possible compatibility, resource-use or maintenance impact.

Discuss large architectural changes in an issue before investing time in implementation.

## Development workflow

1. Fork the repository.
2. Create a focused branch from the default branch (`main`).
3. Make one logical change at a time.
4. Test the change and document the test environment.
5. Push your branch to your fork.
6. Open a Pull Request against `main`.

Suggested branch names:

- `feature/<short-description>`
- `fix/<short-description>`
- `docs/<short-description>`

Suggested commit message format:

```text
type(scope): short description
```

Examples:

- `fix(installer): handle legacy BIOS partitioning`
- `docs(readme): clarify ISO build workflow`
- `feat(theme): add Gamma desktop defaults`

Keep commit subjects concise and explain non-obvious reasoning in the commit body.

## Build and test safety

The build workflow is implemented in the numbered scripts under `scripts/`. Read the relevant scripts before running them.

**Important:** `scripts/01-prepare.sh` removes the existing `chroot/`, `iso/` and `output/` directories before preparing a new build. Back up any files you need from those directories first.

For ISO-related changes:

- Build the edition affected by your change.
- Run the ISO validation and QEMU test scripts where possible.
- Test BIOS/UEFI modes that the edition is intended to support.
- Test the live environment and installer separately.
- Record hardware or VM details and any skipped tests.

A QEMU boot check alone does not prove that installation, networking, graphics, sound or all physical hardware work correctly.

Never test destructive partitioning or disk operations on your primary machine. Use a VM with disposable disk images or expendable test hardware.

## Code and documentation guidelines

- Follow the style already used in the affected files.
- Keep shell scripts compatible with the Bash version and tools expected by the build environment.
- Use clear error messages and fail safely when required files or dependencies are missing.
- Avoid adding unnecessary packages or background services.
- Do not claim performance figures, hardware support or completed features without reproducible evidence.
- Update the README or release notes when a change affects users.

The repository currently contains Shell, C and CMake code, alongside build and automation files. Keep changes focused on the relevant component.

## Pull Request checklist

Before requesting review, confirm:

- [ ] The change has a clear purpose and scope.
- [ ] The relevant scripts or components have been tested.
- [ ] Test results and limitations are described.
- [ ] Documentation is updated where needed.
- [ ] No credentials, personal data or unrelated generated files are included.
- [ ] Destructive build steps and disk operations have been handled safely.

## Security issues

Do not publish details of an exploitable security vulnerability in a public issue. Contact the project maintainer privately at:

**takismartgamer123@gmail.com**

Include reproducible technical details while avoiding disclosure of user data or secrets.

## Communication

- General contact: takismartgamer123@gmail.com
- Telegram: https://t.me/GammaLinuxDZ
- Messenger: https://m.me/j/AbahTOn_gqLy8R3k/?send_source=gc%3Acopy_invite_link

## License

The repository's `LICENSE.md` identifies the project-specific Gamma components as MIT-licensed. Contributions are expected to be submitted under terms compatible with the repository's stated project license. Third-party components retain their own upstream licenses.

By submitting a contribution, you confirm that you have the right to submit it under those terms. If you are unsure about licensing or ownership, clarify that before submitting the contribution.

## Thank you

Every careful bug report, test and improvement helps make Gamma Linux more reliable.

**No PC deserves to die.**  
**Made in Algeria 🇩🇿**
