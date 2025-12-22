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

### 1. Clone this repository

```bash
git clone https://github.com/adhityaravi/fire-flake.git
cd fire-flake
```

### 2. Run the installer

```bash
./install-nix.sh
```

This will:

- Install the **Nix package manager**
- Enable **Flakes** and **experimental features**
- Install **Home Manager** at the user profile level

---

## Usage

> ℹ️ **Info**
>
> Currently flake can be used only after cloning the repository locally. `nix` or `home-manager` commands cant be used because of a design flaw. I plan to fix it. 


After installation:

```bash
home-manager --impure switch --flake .#default
```

This will:

- Set up user programs
- Configure dotfiles
- Apply system-wide user preferences

**Note:** The `--impure` flag is required because the configuration uses the `$USER` environment variable to dynamically locate your specific vars file. See the [Home Manager documentation for --impure](https://nix-community.github.io/home-manager/index.html#sec-flakes-impure) for more details.

Users are expected to provide their user-specific information (such as `username`, `email`, etc.) inside the `vars/` folder. This can be done by:

- Copying `vars/template.nix` to `vars/<your-linux-username>.nix` and editing it with your details.
- Alternatively, by using a private configuration repository like [fire-flake-config](https://github.com/adhityaravi/fire-flake-config) which contains a predefined structure.

To update configuration if you change your private repo:

```bash
nix flake update fire-flake-config
home-manager --impure switch --flake .#default
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

