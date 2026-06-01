<p align="center">
  <a href="https://github.com/EasyDevv/set-sunshine-moonlight">
    <img src="./static/logo.webp" alt="Set Sunshine Moonlight logo" width="240">
  </a>
</p>

<h1 align="center">Set Sunshine Moonlight</h1>

<p align="center">A Windows setup script that installs and configures <a href="https://app.lizardbyte.dev/Sunshine">Sunshine</a>, <a href="https://moonlight-stream.org">Moonlight</a>, and <a href="https://tailscale.com">Tailscale</a> for game streaming over a Tailscale network.</p>

<p align="center">
  <a href="README.md">English</a> |
  <a href="README.ko.md">한국어</a>
</p>

## Features

- Installs Sunshine, Moonlight, and Tailscale via **Chocolatey**
- Interactive role selection for Server, Client, or Server and Client
- Supports automated install selection with `-Role`
- Guides client setup through entering the Sunshine server's Tailscale IP address
- Opens the local or remote Sunshine Web UI as needed
- Launches Moonlight when client setup is included
- Supports full uninstall for all managed packages

## Requirements

- Windows 10/11
- For Client mode, a server computer running [Sunshine](https://app.lizardbyte.dev/Sunshine) on the same Tailscale network
- Administrator PowerShell

## Quick Start (Direct Execution)

Run the latest version directly from GitHub without downloading:

**CMD**
```cmd
powershell -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/EasyDevv/set-sunshine-moonlight/main/scripts/windows/set-windows.ps1')))"
```

**PowerShell**
```powershell
& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/EasyDevv/set-sunshine-moonlight/main/scripts/windows/set-windows.ps1')))
```

> Messages are displayed in Korean when the Windows display language is set to Korean; otherwise English.

## Usage

### Package Manager

The script uses **Chocolatey** to install packages. Chocolatey is preferred over winget because winget's configuration varies by system, while Chocolatey installs reliably on most Windows machines.

### Interactive Mode

Run the script without arguments to use the interactive menu:

```powershell
.\set-windows.ps1
```

1. Select **Install** or **Uninstall** using arrow keys
2. If you choose **Install**, select **Server**, **Client**, or **Server and Client**

### Command-Line Mode

Install:

```powershell
.\set-windows.ps1 -Install -Role Server
```

Install a client with a pre-known Sunshine server address:

```powershell
.\set-windows.ps1 -Install -Role Client -Url "100.x.x.x"
```

Install both server and client:

```powershell
.\set-windows.ps1 -Install -Role ServerAndClient
```

Uninstall:

```powershell
.\set-windows.ps1 -Uninstall
```

## What It Does

1. Installs Chocolatey if not already installed
2. For install, lets you choose `Server`, `Client`, or `ServerAndClient`
3. Installs the matching Chocolatey packages: `sunshine`, `moonlight-qt.install`, `tailscale`
4. Opens the local Sunshine Web UI for server setup, or `https://<server-address>:47990/pin` for client pairing
5. Launches Moonlight when client setup is included
6. Removes all three managed packages on uninstall
