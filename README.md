# Dashboard

[![Main Build](https://github.com/fission-suite/dashboard/actions/workflows/main.yml/badge.svg)](https://fission-dashboard.fission.app)
[![Built by FISSION](https://img.shields.io/badge/⌘-Built_by_FISSION-purple.svg)](https://fission.codes)
[![Discord](https://img.shields.io/discord/478735028319158273.svg)](https://discord.gg/zAQBDEq)
[![Discourse](https://img.shields.io/discourse/https/talk.fission.codes/topics)](https://talk.fission.codes)

This is the dashboard that allows users and developers to manage their accounts and related platform components for Fission.

It goes alongside the rest of the Fission platform components, including:
* [fission](https://github.com/fission-suite/fission) - the server and CLI
* [auth-lobby](https://github.com/fission-suite/auth-lobby) - the authentication lobby that is used for users to give permission to apps

# QuickStart

# Table of Contents

# How To

## Build with [nix](https://github.com/NixOS/nix)

```sh
$ nix-shell
```

This will set you up with a shell that has all executable tools needed for development.

We recommend using [`lorri`](https://github.com/target/lorri) for something a better developer experience.

## Run

```sh
$ just install-deps
$ just config=staging
# Or, running a hot-reloading server
$ just config=staging hot
# Or, run against production
$ just config=production
```

Now there is a development server running on http://localhost:8004. Open that link in your browser to see the running app.

# Tailwind UI

Note: we are using **Tailwind UI**, which has commercial licensing requirements. If you intend to use this project for your own public, production purposes, you must [buy a Tailwind UI license](https://tailwindui.com/pricing).
