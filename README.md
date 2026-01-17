# CleanMode

A simple macOS CLI tool that locks your keyboard and mouse so you can clean them without triggering random inputs.

## Usage

```bash
git clone https://github.com/mihnearad/CleanMode.git
cd CleanMode
swift clean.swift
```

The tool will ask how long you want the lock to last, then give you a 5-second countdown before locking.

## Requirements

- macOS
- Swift (included with Xcode or Xcode Command Line Tools)
- Accessibility permissions for your terminal app

## Permissions

On first run, you'll need to grant Accessibility permissions:

**System Settings → Privacy & Security → Accessibility** → Enable your terminal app

## Emergency Exit

If you need to abort during the lock, use **Ctrl+C** in the terminal.
