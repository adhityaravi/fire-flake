<h1 align="center">
  <img src="https://github.com/user-attachments/assets/23ba47e9-0709-4445-8b2a-1665ac098d33" width="400">
</h1><br>

fire-flake is a personal [Nix flake](https://nixos.wiki/wiki/Flakes) for setting up a PC/server.

---

## Table of Contents

- [About](#about)
- [Features](#features)
- [Folder Structure](#folder-structure)
- [Installation](#installation)
- [Usage](#usage)
- [Requirements](#requirements)
- [Roadmap](#roadmap)
- [Contributing](#contributing)

---

## About

**fire-flake** is a modular system for setting up and managing personal Linux machines using **Nix Flakes** and **Home Manager**.

It aims to:

- Provide an opinionated, repeatable, and well-featured SDE environment recipe out-of-the-box
- Allow the setup to be easily versioned, shared and reproduced across different machines for multiple users
- Be less manual, invasive and flaky (lol, the irony) compared to traditional dotfiles and shell scripts
- Allow system level configuration (for NixOS based systems) under the same framework

## Installation

### Option 1: Personal Machine Setup

#### 1. Clone this repository

```bash
git clone https://github.com/adhityaravi/fire-flake.git
cd fire-flake
```

#### 2. Run the installer

```bash
./install-nix.sh
```

This will:

- Install the **Nix package manager**
- Enable **Flakes** and **experimental features**
- Install **Home Manager** at the user profile level

### Option 2: Fresh VM / GitHub Runner Setup

For bootstrapping a fresh VM (e.g., Hetzner) as a GitHub Actions self-hosted runner:

```bash
curl -sL https://raw.githubusercontent.com/adhityaravi/fire-flake/main/fire-flake/scripts/runner-vm-init.sh | sudo bash
```

Or with custom parameters:

```bash
curl -sL https://raw.githubusercontent.com/adhityaravi/fire-flake/main/fire-flake/scripts/runner-vm-init.sh | sudo bash -s -- <username> <machine> <git-name> <git-email>
```

Parameters (all optional, with defaults):
- `username`: Linux user to create (default: `ivdi`)
- `machine`: Home-manager configuration to apply (default: `oishiioushi`)
- `git-name`: Git user name (default: username)
- `git-email`: Git email (default: `<username>@users.noreply.github.com`)

After initialization, follow the on-screen instructions to configure the GitHub runner

---

## Usage

After installation, apply a machine configuration:

```bash
cd fire-flake/fire-flake
home-manager switch --impure --flake .#<machine>
```

Available machines:
- `kawaiikuma` - Full development environment (neovim, lazygit, starship, claude-code, etc.)
- `oishiioushi` - Minimal CI/runner environment (git, fish, GitHub runner)

Example:
```bash
home-manager switch --impure --flake .#kawaiikuma
```

**Note:** The `--impure` flag is required because the configuration uses the `$USER` environment variable to dynamically locate your vars file.

### User Configuration

Users must provide their user-specific information in the `vars/` folder:

1. Copy `vars/template.nix` to `vars/<your-linux-username>.nix`
2. Edit with your details (username, email, etc.)

Alternatively, use a private configuration repository like [fire-flake-config](https://github.com/adhityaravi/fire-flake-config).

### Updating

To update dependencies and re-apply:

```bash
nix flake update
home-manager switch --impure --flake .#<machine>
```

---

## Requirements

- Modern **Linux OS** (Ubuntu, Fedora, Arch, etc.)
- **Nix** package manager (installed via `install-nix.sh`)
- Basic **Git** setup
- SSH keys added to GitHub if configuring via a private repo

---

## Contributing

Currently intended as a personal project for distro hopping and learning Nix. However, if you find it useful or want to contribute, feel free to open an issue or PR.
I will write a proper contributing guide when I have time.

