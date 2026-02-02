# Kyuri

Kyuri (Keyboard Utility Remap Integrated) is a high-performance keyboard remapping framework built with AutoHotkey v2. It optimizes your workflow by turning thumb keys into powerful modifiers with zero-latency response.

## Project Structure

```text
kyuri/
├── setup/
├── source/
│   ├── App.ahk
│   ├── config.json
│   ├── lib/
│   │   ├── core/
│   │   ├── adapter/
│   │   ├── infrastructure/
│   │   ├── ui/
│   │   └── vendor/
│   └── tests/
└── tools/
```

| Directory / File | Layer | Description |
| :--- | :--- | :--- |
| **setup/** | (Utilities) | Installation scripts (e.g., Task Scheduler registration). |
| **source/App.ahk** | (Infrastructure) | Orchestrator. Initializes the base infra and starts the app. |
| **source/lib/core/** | **Core Layer** | Pure business logic and remapping rules. No dependencies on OS/Infra. |
| **source/lib/adapter/** | **Adapter Layer** | Implements interfaces for OS Hooks, IME, and File I/O. |
| **source/lib/infrastructure/** | **Infra Layer** | Cross-cutting tools: ServiceLocator, Logger, Assert, GlobalErrorHandler. |
| **source/lib/ui/** | **UI Layer** | Dynamic Menu generation and Setting GUIs. |
| **source/lib/vendor/** | **Vendor (Ext)** | Third-party libraries isolated from internal logic. |
| **source/tests/** | (Test Infra) | Unit tests following the source directory structure. |
| **tools/** | (Utilities) | Debugging and development helper scripts. |

## Prerequisites

- **Windows 10/11**
- **AutoHotkey v2.0+**: Recommended to install via [Scoop](<https://scoop.sh/>).

    ```powershell
    scoop bucket add extras
    scoop install extras/autohotkey
    ```

- **PowerShell 5.1+** (Administrator privileges required for setup)

## Installation & Setup

Both scripts will automatically request Administrator privileges via a UAC prompt if necessary.

### Install

1. **Clone the repository**:

    ```bash
    git clone https://github.com/your-username/kyuri.git
    cd kyuri
    ```

1. **Run the installation script**: Right-click `setup/install.ps1` and select "Run with PowerShell", or run it from an elevated PowerShell terminal:

    ```powershell
    .\setup\install.ps1
    ```

1. **Verify the installation**: Open **Task Scheduler** and ensure the task `Kyuri_AutoStart` is registered. You can manually start the task to verify that `App.ahk` launches correctly.

### Uninstall

To remove the automatic startup task from your system:

1. **Run the uninstallation script**:
    Right-click `setup/uninstall.ps1` and select "Run with PowerShell", or run it from a terminal:

    ```powershell
    cd setup
    .\uninstall.ps1
    ```

## Development

- **Configuration**: Edit `source/config.json` to customize your key mappings and menus.
- **Reloading**: After updating the code or configuration, restart the application (or run the task again) via Task Scheduler to apply changes.

## Credits & Development Team

**Kyuri** is a collaborative project between human and AI.

- **Lead Architect & Visionary**: Daiki IWAMOTO
  - Responsible for project concept design, user requirements definition, and overall direction.
- **Development Partner**: Gemini 3 Flash Web (Google AI)
  - Engineering partner for architectural design, technical specification formulation, and implementation.

We are developing this tool through continuous dialogue, driven by a shared goal: "Creating the ultimate ergonomic input experience."

## License

This project is licensed under the Apache License 2.0. See the LICENSE file for details.
