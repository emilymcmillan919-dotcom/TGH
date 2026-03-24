#!/usr/bin/env pwsh
# Claude Code installer for Windows (PowerShell)
# Usage: irm https://claude.ai/install.ps1 | iex

<#
.SYNOPSIS
    Installs Claude Code CLI on Windows.
.DESCRIPTION
    Downloads and installs the Claude Code CLI tool. Requires Node.js >= 18.
    Installs via npm globally.
#>

$ErrorActionPreference = 'Stop'

# --- Configuration ---
$MIN_NODE_VERSION = 18
$PACKAGE_NAME = "@anthropic-ai/claude-code"

# --- Helper functions ---

function Write-Status {
    param([string]$Message)
    Write-Host "  $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "  $Message" -ForegroundColor Green
}

function Write-Err {
    param([string]$Message)
    Write-Host "  $Message" -ForegroundColor Red
}

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Get-NodeMajorVersion {
    $versionOutput = & node --version 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $versionOutput) {
        return $null
    }
    # version string is like "v20.11.0"
    $versionOutput -replace '^v', '' -split '\.' | Select-Object -First 1 | ForEach-Object { [int]$_ }
}

# --- Banner ---

Write-Host ""
Write-Host "  Claude Code Installer" -ForegroundColor White
Write-Host "  =====================" -ForegroundColor DarkGray
Write-Host ""

# --- Pre-flight checks ---

# Check OS
if ($env:OS -ne "Windows_NT" -and -not $IsWindows) {
    # On non-Windows, suggest the shell installer instead
    Write-Err "This installer is for Windows. On macOS/Linux, run:"
    Write-Host '  curl -fsSL https://claude.ai/install.sh | sh' -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Check Node.js
Write-Status "Checking for Node.js..."

if (-not (Test-CommandExists "node")) {
    Write-Err "Node.js is not installed."
    Write-Host ""
    Write-Host "  Install Node.js (>= $MIN_NODE_VERSION) from:" -ForegroundColor Yellow
    Write-Host "    https://nodejs.org" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Or install via winget:" -ForegroundColor DarkGray
    Write-Host "    winget install OpenJS.NodeJS.LTS" -ForegroundColor DarkGray
    Write-Host ""
    exit 1
}

$nodeMajor = Get-NodeMajorVersion
if ($null -eq $nodeMajor) {
    Write-Err "Could not determine Node.js version."
    exit 1
}

if ($nodeMajor -lt $MIN_NODE_VERSION) {
    Write-Err "Node.js v$nodeMajor is too old. Claude Code requires Node.js >= $MIN_NODE_VERSION."
    Write-Host ""
    Write-Host "  Update Node.js from https://nodejs.org" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

$nodeVersion = & node --version
Write-Success "Node.js $nodeVersion found."

# Check npm
Write-Status "Checking for npm..."

if (-not (Test-CommandExists "npm")) {
    Write-Err "npm is not installed. It should come with Node.js."
    Write-Host "  Reinstall Node.js from https://nodejs.org" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

$npmVersion = & npm --version
Write-Success "npm v$npmVersion found."

# --- Install ---

Write-Host ""
Write-Status "Installing Claude Code..."
Write-Host ""

try {
    & npm install -g $PACKAGE_NAME 2>&1 | ForEach-Object {
        Write-Host "  $_" -ForegroundColor DarkGray
    }

    if ($LASTEXITCODE -ne 0) {
        throw "npm install exited with code $LASTEXITCODE"
    }
}
catch {
    Write-Host ""
    Write-Err "Installation failed: $_"
    Write-Host ""
    Write-Host "  Try running PowerShell as Administrator, or use:" -ForegroundColor Yellow
    Write-Host "    npm install -g $PACKAGE_NAME" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# --- Verify installation ---

Write-Host ""
Write-Status "Verifying installation..."

# Refresh PATH for the current session
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

if (-not (Test-CommandExists "claude")) {
    Write-Err "Installation completed but 'claude' command was not found in PATH."
    Write-Host ""
    Write-Host "  You may need to restart your terminal, or add the npm global bin" -ForegroundColor Yellow
    Write-Host "  directory to your PATH:" -ForegroundColor Yellow
    $npmPrefix = & npm prefix -g
    Write-Host "    $npmPrefix" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

$claudeVersion = & claude --version 2>$null
Write-Success "Claude Code $claudeVersion installed successfully!"

# --- Done ---

Write-Host ""
Write-Host "  Get started by running:" -ForegroundColor White
Write-Host "    claude" -ForegroundColor Green
Write-Host ""
