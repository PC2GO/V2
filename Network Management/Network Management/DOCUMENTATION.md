# Network Management Tool - Directory Structure & File Documentation

## Overview
This document provides a comprehensive overview of the Network Management Tool's directory structure and details the purpose and content of each PowerShell file after the Core directory reorganization.

## Directory Structure

```
Network Management Tool/
├── Main.ps1                                    # Application entry point
├── Network Management/
│   ├── Core/                                   # Core application logic
│   │   ├── IP/                                # IP networking functionality
│   │   │   └── IPNetworkModule.ps1            # IP subnet and VLAN management
│   │   └── Site/                              # Site management functionality  
│   │       ├── DataModels.ps1                 # Data structure definitions
│   │       ├── DeviceManager.ps1              # Device management logic
│   │       ├── EditSiteWindow.ps1             # Site editing interface
│   │       ├── Site.ps1                       # Main site management logic
│   │       └── SiteImportExport.ps1           # Import/Export functionality
│   ├── Data/                                  # Data storage
│   │   ├── ip_data.json                       # IP subnet data storage
│   │   └── site_data.json                     # Site information storage
│   └── UI/                                    # User interface files
│       ├── EditSiteWindow.xaml                # Edit site popup window
│       └── NetworkManagement.xaml             # Main application window
└── DOCUMENTATION.md                           # This documentation file
```

## File Descriptions

### Entry Point

#### `Main.ps1`
**Purpose**: Application launcher and initialization script
**Contents**:
- WPF assembly loading
- Desktop shortcut creation
- Execution policy configuration
- Module loading and path management
- Application startup sequence

**Key Responsibilities**:
- Loads required WPF assemblies (PresentationFramework, PresentationCore, WindowsBase)
- Creates desktop shortcut if missing
- Manages module loading paths after directory restructuring
- Initiates the main application

---

### Core/IP Directory

#### `IPNetworkModule.ps1`
**Purpose**: Complete IP network and subnet management functionality
**Contents**:
- `SubnetEntry` class definition for IP subnet data structure
- Search functionality with debouncing timer
- Subnet validation and management functions
- VLAN ID and naming management
- IP network calculation utilities

**Key Features**:
- IP subnet format validation (CIDR notation)
- Search debouncing for performance optimization
- Integration with site-specific VLAN management
- Comprehensive subnet data grid operations

---

### Core/Site Directory

#### `DataModels.ps1`
**Purpose**: Central data model definitions for all network devices and site information
**Contents**:
- `SwitchInfo` class - Network switch data structure
- `AccessPointInfo` class - Wireless access point data structure  
- `UPSInfo` class - Uninterruptible Power Supply data structure
- `CCTVInfo` class - CCTV camera data structure
- `SiteEntry` class - Complete site information data structure
- Common data validation utilities

**Device Properties Include**:
- Management IP addresses
- Device names and asset tags
- Version and serial number information
- Site-specific device relationships

#### `Site.ps1`
**Purpose**: Main site management logic and user interface integration
**Contents**:
- XAML file path configuration
- Site validation functions (`Validate-SiteBasicInfo`)
- Core site management operations
- Phone number conversion utilities
- Integration with UI components

**Key Functionalities**:
- Site code and subnet validation
- Required field validation with error handling
- Status management integration
- XAML path resolution for UI loading

#### `DeviceManager.ps1`
**Purpose**: Device management classes and functions for network infrastructure
**Contents**:
- `DeviceConfiguration` class for different device types
- Device-specific management logic
- Network device integration utilities
- Safe value handling functions
- Data models integration

**Device Management Features**:
- Type-specific device configuration (switches, APs, UPS, CCTV)
- Device prefix and VLAN subnet management  
- IP address offset and counting management
- Field mapping and labeling systems

#### `EditSiteWindow.ps1`
**Purpose**: Site editing interface and popup window functionality
**Contents**:
- `Show-EditSiteWindow` function for site editing interface
- Edit site XAML loading and management
- Site modification validation
- Data models integration for editing operations

**Edit Window Features**:
- Popup window creation and management
- Site data pre-population for editing
- Validation integration during editing
- Error handling for missing XAML files

#### `SiteImportExport.ps1`
**Purpose**: Import and export functionality for site and network data
**Contents**:
- Excel file import/export operations
- COM object management and cleanup utilities
- Data validation during import/export
- Safe value extraction functions
- Error handling for file operations

**Import/Export Features**:
- Excel file format support
- COM object lifecycle management
- Data integrity validation
- Safe memory management with proper cleanup
- File path validation and error handling

---

### Data Directory

#### `ip_data.json`
**Purpose**: Persistent storage for IP subnet and VLAN information
**Format**: JSON format containing subnet entries with VLAN mappings

#### `site_data.json`
**Purpose**: Persistent storage for site information and device inventories
**Format**: JSON format containing complete site records with associated devices

---

### UI Directory

#### `NetworkManagement.xaml`
**Purpose**: Main application user interface definition
**Contents**: WPF XAML markup for the primary application window including data grids, input controls, and navigation elements

#### `EditSiteWindow.xaml`
**Purpose**: Site editing popup window interface definition
**Contents**: WPF XAML markup for the site editing dialog with form controls and validation displays

---

## Architecture Benefits

### Separation of Concerns
- **IP Directory**: Isolated IP networking and subnet functionality
- **Site Directory**: Centralized site management and device operations
- **UI Directory**: Clean separation of interface definitions
- **Data Directory**: Dedicated data persistence layer

### Maintainability Improvements
- **Logical Organization**: Related functionality grouped together
- **Clear Dependencies**: Explicit module relationships and imports
- **Modular Design**: Easy to locate and modify specific functionality
- **Scalable Structure**: Simple to add new device types or management features

### File Relationships
- `DataModels.ps1` is imported by `DeviceManager.ps1`, `EditSiteWindow.ps1`, and `SiteImportExport.ps1`
- `Site.ps1` serves as the main orchestrator for site operations
- `Main.ps1` coordinates module loading and application initialization
- UI XAML files are referenced by their corresponding PowerShell modules

## Development Guidelines

### Adding New Features
1. **New Device Types**: Add to `DataModels.ps1` and extend `DeviceManager.ps1`
2. **New UI Components**: Create XAML files in UI directory and reference from appropriate modules
3. **New Data Operations**: Extend `SiteImportExport.ps1` for data persistence needs
4. **New IP Features**: Add to `IPNetworkModule.ps1` for network-related functionality

### File Modification Best Practices
- Maintain consistent error handling patterns across modules
- Use the established data model classes for all new functionality
- Ensure proper COM object cleanup in any file operations
- Follow the existing module import patterns for dependencies