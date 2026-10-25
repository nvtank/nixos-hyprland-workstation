# Contributing

Open an issue describing the concrete behavior you want to improve, target
hardware and affected profile. For small fixes, a focused pull request is fine.
Discuss large interface, dependency or desktop changes before implementation.

Keep hardware/accounts in hosts, reusable features opt-in, and profile defaults
coherent. Add typed options with descriptions/assertions. Do not bake personal
names, disks or home paths into exported modules. Do not change existing
passwords, sudo rules, login routes or shell membership implicitly. Preserve
upstream license notices and explain any new downloads/services.

Use small reviewable commits without unrelated formatting or lock updates.
The pinned desktop stack is sensitive to Lua/QML API changes; upgrades need a
separate compatibility explanation. Do not claim hardware testing you did not
perform. Include the exact commands/results and remaining limitations in the PR.

Run formatting, flake evaluation/checks, ShellCheck and the isolated script tests
from [development](docs/development.md). Test the affected profile, the personal
compatibility output and the example. Never activate a contributor's hardware
configuration on your machine. Test installer mutations with temporary paths and
mocks; tests must not require sudo or modify `/etc/nixos`.

A PR should explain the original problem, changed behavior, validation and
recovery implications. Screenshots help with UI changes, but remove personal
information. New source contributions use the project's GPL-3.0-only license;
third-party components retain their original terms. Follow the
[Code of Conduct](CODE_OF_CONDUCT.md) and report sensitive issues privately as
specified in [SECURITY.md](SECURITY.md).
