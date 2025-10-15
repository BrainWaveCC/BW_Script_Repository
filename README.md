# BrainWave Script Repository

The BrainWave Admin Script Repository is a comprehensive collection of Windows shell scripts, configuration files, and utilities designed to simplify the configuration, monitoring, backup, and administration of Windows-based network environments of all sizes.

## Overview

This collection of enterprise-grade administrative scripts has been assembled and refined over many years for portability, reliability, and utility. The scripts are designed to work across different divisions, departments, or even organizations, making them ideal for system administrators, IT consultants, and Managed Service Providers (MSPs).

Key advantages:
- **Centralized Configuration**: Configuration abstracted from script logic for easy customization
- **Distributed Deployment**: Deploy only the scripts you need to remote systems
- **Portable**: Works across different environments with minimal modification
- **Extensible**: Easy to add custom scripts and configurations

## Features

### System Backup & Recovery
- **BackupAllGPOs.wsf**: Comprehensive Group Policy Object backup
- **BackupCert.BAT**: Certificate authority backup
- **BackupDHCP.BAT**: DHCP server configuration backup
- **BackupDNS.BAT**: DNS server configuration backup  
- **BackupGPO.BAT**: Individual GPO backup with versioning
- **BackupSched.BAT**: Scheduled tasks backup
- **BackupSS.BAT**: System State backup automation
- **RetainBackups.BAT**: Backup retention policy enforcement

### Archive & File Management
- **CreateArchive.BAT**: Create and manage file archives with compression
- **MoveArchives.BAT**: Automated archive relocation and cleanup
- **ZipFiles.BAT**: Compress files with customizable retention policies
- **ZipLogs.BAT**: Log file compression and archival
- **DoubleCopy.BAT**: Redundant copy operations for critical data
- **Replicate-Files.BAT**: File replication with synchronization

### Remote Execution & Batch Operations
- **Do.BAT**: Execute commands across multiple systems simultaneously
- **DoList.BAT**: Process commands from a list file
- **DoPS.BAT**: Execute PowerShell scripts remotely
- **DoSome.BAT**: Selective script execution
- **Repeat.BAT**: Repeated command execution with intervals
- **RunUntil.BAT**: Execute until condition met
- **WaitUntil.BAT**: Wait for specific conditions before proceeding

### System Maintenance
- **CleanTemp.BAT**: Automated temporary file cleanup
- **CheckIntegrity.BAT**: File integrity verification using checksums
- **BulkServices.BAT**: Bulk Windows service management
- **GetInfo.BAT**: System information collection and reporting

### Network Configuration
- **ConfigureNetwork.BAT**: Network adapter configuration automation
- **IPDebug.BAT**: Network connectivity troubleshooting

### Utilities
- **SetDrive.BAT**: Global variable initialization and environment setup
- **Debug.BAT**: Debug mode configuration for troubleshooting
- **FindCommand.BAT**: Locate commands and scripts in the repository

## System Requirements

### Operating System
- Windows Server 2016 or later (recommended)
- Windows 10/11 Professional or Enterprise
- Windows Server 2012 R2 or later (limited support)

### Required Software
- Windows PowerShell 5.1 or later
- .NET Framework 4.7.2 or later
- Windows Management Framework 5.1 or later

### Optional Dependencies
- **BrainWave Utilities** (strongly recommended): https://www.BrainWaveCC.com/brainwave-utilities
  - DateInfo.exe - Date/time calculations
  - FileHash.exe - File integrity verification
  - ReadConfig.exe - Configuration file parsing
  - SyslogGen.exe - Syslog message generation
  - CheckParams.exe - Parameter validation
  - And more...

- **SysInternals Suite** (recommended):
  - PsExec - Remote execution
  - PsInfo - System information
  - PsLoggedOn - User session information

- **PAExec** (alternative to PsExec): https://www.poweradmin.com/paexec/

- **ADFind** (for Active Directory queries): http://www.joeware.net/freetools/tools/adfind/

### Permissions
- Local Administrator rights for most operations
- Domain Administrator rights for AD-related operations
- Appropriate backup privileges for backup operations

## Installation

### Understanding Runtime vs Staging Locations

The repository uses **two key locations**:

#### 1. Runtime Location (Default: `C:\Scripts`)
- Where scripts actively execute on each system
- Installs to `%SystemDrive%` (usually C:)
- Contains the operational scripts and utilities
- Created on every managed system

#### 2. Staging Location (Example: `D:\Storage\Source\YourCompany`)
- Central repository for distributing scripts across the network
- Contains pristine copies of scripts ready for deployment
- Must be shared on the network for remote access
- Typically contains a **subset** of your local scripts (excludes sensitive/licensed tools)
- Only needed on 1-2 systems in your environment

### Basic Setup - Runtime Location

1. **Clone or download the repository:**
   ```cmd
   git clone https://github.com/BrainWaveCC/BW_Script_Repository.git
   ```
   Or download and extract the ZIP archive.

2. **Copy to runtime location** (`C:\Scripts` is standard):
   ```cmd
   # Copy all files to C:\Scripts
   xcopy /E /I /Y BW_Script_Repository C:\Scripts
   ```

3. **Install BrainWave Utilities** (download from https://www.BrainWaveCC.com/brainwave-utilities):
   
   Extract these essential utilities:
   - To `C:\Scripts\Utils\` (32-bit versions)
   - To `C:\Scripts\Utils\x64\` (64-bit versions)
   
   **Core utilities needed:**
   - `DateInfo.exe` / `DateInfo64.exe` - Date/time calculations (REQUIRED)
   - `FileHash.exe` / `FileHash64.exe` - File integrity verification
   - `ReadConfig.exe` - Configuration file parsing (REQUIRED)
   - `CheckParams.exe` - Parameter validation (REQUIRED)
   - `FindFiles.exe` - File location utility (REQUIRED)
   - `Now.exe` - Timestamp display
   - `SyslogGen.exe` - Syslog message generation
   - `ChangeCase.exe` - String case manipulation
   - `MakeString.exe` - String generation
   - `RandomPass.exe` - Random password generation
   - Additional utilities as needed

4. **Run initial setup script** (MUST run in elevated Command Prompt):
   ```cmd
   C:\Scripts\BAT\$NewSetup.BAT
   ```
   
   **This automated script creates:**
   - Required folder structure:
     - `%SystemDrive%\Storage\Drivers`
     - `%SystemDrive%\Storage\Docs`
     - `%SystemDrive%\Storage\i386`
     - `D:\Storage\Installs` (or drive specified in `FolderDefaults.TXT`)
     - `D:\Storage\Downloads`
     - `D:\Storage\Logs` (with Zips subdirectory)
     - `D:\Storage\Backups` (with DHCP, DNS, GPO subdirectories)
   - Network shares:
     - `Scripts$` → `C:\Scripts`
     - `Drivers$` → `C:\Storage\Drivers`
     - `SysDocs$` → `C:\Storage\Docs`
     - `Storage$` → `D:\Storage`
     - `Logs$` → `D:\Storage\Logs`
     - `Backups$` → `D:\Storage\Backups`
     - `Installs$` → `D:\Storage\Installs`
     - `Downloads$` → `D:\Storage\Downloads`
   - Scheduled jobs in the `BrainWave\` Task Scheduler folder
   - Registry settings for SysInternals EULA acceptance
   - System PATH modifications
   
   **Note:** You can run `$NewSetup.BAT` multiple times safely. Re-run if you change the drive letter for `\Storage` folders.

5. **Configure scheduled job credentials** (for jobs requiring user context):
   ```cmd
   C:\Scripts\BAT\TaskConfig.BAT
   ```
   
   This ensures jobs like `OpsLogs.BAT` and `BackupDNS.BAT` run with appropriate privileges instead of just interactively. Required for jobs needing domain admin or specific service account credentials.

### Setting Up the Staging Location (For Distributed Environments)

If managing multiple systems, create a central staging location:

1. **Create staging repository** (on your primary admin workstation):
   ```cmd
   # Use the automated script
   C:\Scripts\BAT\MakeRepository.BAT
   
   # Or manually:
   mkdir D:\Storage\Source\YourCompany\Scripts
   ```

2. **Copy scripts to staging** (selective deployment):
   ```cmd
   # Copy only the scripts you want to deploy
   xcopy /E /I C:\Scripts\BAT D:\Storage\Source\YourCompany\Scripts\BAT
   xcopy /E /I C:\Scripts\Utils D:\Storage\Source\YourCompany\Scripts\Utils
   xcopy /E /I C:\Scripts\PowerShell D:\Storage\Source\YourCompany\Scripts\PowerShell
   
   # Do NOT copy licensed/proprietary tools or sensitive scripts
   ```

3. **Share the staging location:**
   ```cmd
   net share Scripts_Source$=D:\Storage\Source\YourCompany /GRANT:Administrators,READ
   ```

4. **Configure `ScriptSource.TXT`** (in `C:\Scripts\BAT\Input\`):
   ```
   UNC PATH of Valid Script Repository, Physical Drive Path of Repository
   ----------------------------------------------------------------------------
   "\\ADMIN-PC\Scripts_Source$\Scripts", "D:\Storage\Source\YourCompany\Scripts"
   "\\FILESVR\Scripts_Source$\Scripts", "E:\Storage\Source\YourCompany\Scripts"
   ```
   
   **Important:** Don't remove the first two header lines! Scripts skip them during parsing.

5. **Deploy to remote systems:**
   
   **PUSH method** (from staging system):
   ```cmd
   # Update all systems in FolderDefaults.TXT
   # IMPORTANT: Must use FULL PATH and "." parameter (safety feature)
   C:\Scripts\BAT\ReSyncScripts.BAT .
   ```
   
   **Safety Notes for ReSyncScripts.BAT:**
   - **ONLY script requiring full path with mandatory parameter**
   - Must be case-sensitive filename: `ReSyncScripts.BAT` (not `resyncscripts.bat`)
   - Must include the `.` parameter to execute
   - This prevents accidental mass-deployment
   - Can only be run from systems listed in `ScriptSource.TXT`
   
   **PULL method** (from any remote system):
   ```cmd
   # Pull scripts from staging repository (first-time deployment)
   \\ADMIN-PC\Scripts_Source$\Install.BAT
   
   # Or use GetScripts.BAT if scripts already deployed
   C:\Scripts\BAT\GetScripts.BAT
   
   # Can specify source explicitly
   C:\Scripts\BAT\GetScripts.BAT \\ADMIN-PC\Scripts_Source$
   ```
   
   **GetScripts.BAT** will automatically:
   - Check `ScriptSource.TXT` for repository locations
   - Try each source until successful
   - Update local scripts from remote staging
   - Useful for systems not in `FolderDefaults.TXT`

### Network Shares (Created by $NewSetup.BAT)

Create network shares for distributed deployment:
```cmd
net share Scripts$=D:\Storage\Scripts /GRANT:Administrators,FULL
net share Logs$=D:\Storage\Logs /GRANT:Administrators,FULL
net share Storage$=D:\Storage /GRANT:Administrators,FULL
net share Backups$=D:\Storage\Backups /GRANT:Administrators,FULL
```

### PATH Configuration (Optional)

Add the scripts directory to your PATH for easier access:
```cmd
setx PATH "%PATH%;D:\Scripts\BAT" /M
```

## Configuration

### Core Configuration Files

The repository uses centralized configuration files located in the `Input` folder:

#### 1. `CustomVariables.TXT`
The primary configuration file containing organization-specific settings:
- Email addresses and mail server settings
- Network configuration (domain names, IP ranges, gateways)
- File server locations and shares
- Archive locations and retention policies
- Script-specific parameters

**Key variables to customize:**
```
@ORGNAME           - Your organization name
@INTFQDN           - Internal domain name (e.g., company.local)
@ORGFQDN           - External domain name (e.g., company.com)
@NETBIOS           - NetBIOS domain name
@MAILSERVER        - SMTP server address
@OPS-ADMIN         - Operations team email
@FILESERVER1       - Primary file server UNC path
@REMOTE_ARCHIVE1   - Primary archive location
```

**Create a computer-specific override:**
```cmd
copy CustomVariables.TXT CustomVariables.%COMPUTERNAME%.TXT
# Edit CustomVariables.%COMPUTERNAME%.TXT with local settings
```

#### 2. `FolderDefaults.TXT`
Defines storage locations for each computer:
```
;SERVER_NAME    LOGS    ROOT    BACKUPS    MACHINE_CLASS    MACHINE_TYPE    OPERATING_SYSTEM    DESCRIPTION
 MYSERVER       D:      C$      -          Server:          Physical:       Windows 2022 x64    Production Server
```

#### 3. `ArchiveInfo.TXT`
Configuration for archive creation jobs (used by `CreateArchive.BAT`):
- Source and destination paths
- File exclusions and retention policies
- Compression settings
- Schedule configuration

#### 4. `ReplicationInfo.TXT`
Configuration for file replication jobs (used by `Replicate-Files.BAT`):
- Source and destination mappings
- Replication options (mirror, bidirectional, etc.)
- Exclusion patterns
- Schedule settings

#### 5. `IPConfig.TXT`
Network configuration templates for automated network setup.

### Input File Naming Conventions

**Bracketed Files `[filename].TXT`:**
- Files in brackets are **global configuration files**
- Less likely to require customization at each location
- Typically replicated across all systems unchanged
- Examples:
  - `[BrainWaveUtils].TXT` - List of BrainWave utilities
  - `[KnownServices].TXT` - Accepted/known Windows services
  - `[LongProcesses].TXT` - Processes allowed to run long
  - `[CopyExemption].TXT` - Files to skip during replication
  - `[SysInternals].TXT` - SysInternals EULA registry settings
  - `[ScriptInput].TXT` - Master list of input files

**Note:** In Feb 2015 (v8.0), core input files were renamed from `xxx.TXT` to `[xxx].TXT` to make them easier to identify during system updates.

### Creating Computer-Specific Configurations

Many configuration files support computer-specific overrides using the naming pattern:
```
<filename>.%COMPUTERNAME%.TXT
<filename>.MINI.%COMPUTERNAME%.TXT  (for minor deviations)
```

**Precedence:**
1. `filename.%COMPUTERNAME%.TXT` - Computer-specific (highest priority)
2. `filename.%@CUSTOM_CONFIG%.TXT` - Common name group override
3. `filename.TXT` - Default for all systems

**Examples:**
- `CustomVariables.FILESERVER1.TXT` - Settings specific to FILESERVER1
- `CustomVariables.MINI.FILESERVER1.TXT` - Minor tweaks for FILESERVER1
- `ArchiveInfo.FILESERVER1.TXT` - Archive jobs only for FILESERVER1
- `ArchiveInfo.MINI.FILESERVER1.TXT` - Additional/override archive jobs
- `ServerList.ADMINPC.TXT` - Custom server list for ADMINPC only

**MINI Files:**
- Processed **after** the main configuration file
- Allows minor deviations without duplicating entire config
- Useful for adding extra settings per system
- Introduced in Nov 2014 (v7.2) to simplify customization

### Managing System Lists with Excel

Manually maintaining multiple system list files can be tedious. The repository includes tools to streamline this:

#### SystemList.xlsm & MakeSystemLists.BAT

**Excel Spreadsheet** (`SystemList.xlsm`):
- Central management of all server/workstation lists
- Conditional formatting to highlight missing data
- Macro to simplify bulk updates
- Can also be maintained as CSV (`SystemList.CSV`)

**Column Definitions:**
- `SERVER_NAME` - Hostname
- `IP_ADDRESS` - Primary IP (optional)
- `ENV` - Environment (PRODUCTION, DEV, QA, etc.)
- `LOGS` - Drive letter for Storage$ share
- `ROOT` - Root share of %SystemRoot%
- `BACKUPS` - Drive for Backups$ share (if different from LOGS)
- `CLASS` - Device type (Server, Workstation, Storage, etc.)
- `TYPE` - Hardware type (Physical or Virtual)
- `OS_VERSION` - OS version (e.g., Windows 2022 x64)
- `DEVICE_PURPOSE` - Role/function description
- `FOLDER_DEF` - Include in FolderDefaults.TXT (Y/N/C)
- `DC_LIST` - Include in AD-DCs.TXT (Y/N/C)
- `MGMT_LIST` - Include in MyServers.TXT (Y/N/C)
- `SERVER_LIST` - Include in ServerList.TXT (Y/N/C)
- `UPTIME_LIST` - Include in UptimeList.TXT (Y/N/C)
- `SEC_LIST` - Include in SecurityList.TXT (Y/N/C)
- `SMALL_LIST` - Include in SmallList.TXT (Y/N/C)
- `EXCH_LIST` - Include in ExchangeList.TXT (Y/N/C)
- `EXCH_TEST` - Include in ExchangeTest.TXT (Y/N/C)
- `LOW_DISK` - Include in LowDisk.TXT (Y/N/C)
- `SUS_SERVERS` - Include in SUS_Servers.TXT (Y/N/C)
- `SUS_CLIENTS` - Include in SUS_Clients.TXT (Y/N/C)
- `IN_DEFAULT` - Include in default lists (Y/N/C)
- `CUSTOM_LISTS` - Custom list names

**Entry Values:**
- `Y` - Include system in list
- `C` - Include but commented out (prefixed with semicolon)
- `-` or other - Exclude from list

**Usage:**
```cmd
# After updating SystemList.CSV or SystemList.xlsm
C:\Scripts\BAT\MakeSystemLists.BAT

# This generates/updates all list files in Input folder
```

**Benefits:**
- Maintain one master list instead of dozens of text files
- Bulk updates and reorganization
- Consistent formatting
- Reduced errors
- Visual management with Excel

### Configuration Best Practices

1. **Start with defaults**: Copy the provided template files and modify gradually
2. **Use version control**: Track changes to configuration files
3. **Test thoroughly**: Use test mode flags before production deployment
4. **Document customizations**: Add comments to configuration files
5. **Backup configurations**: Include config files in your backup routines
6. **Use consistent naming**: Follow the established variable naming conventions
7. **Use SystemList.xlsm**: Simplify list management with the Excel tool

## Key Scripts Documentation

### Do.BAT - Remote Command Execution

Execute commands across multiple systems from a central location.

**Syntax:**
```cmd
Do.BAT <option|list_file> <command_with_tokens>
```

**Options:**
- `.` - Use default server list (ServerList.TXT)
- `@` - All domain controllers (via ADFind)
- `#` - All servers except domain controllers
- `$` - All servers including domain controllers
- `+` - All non-server systems
- `*` - All computers except domain controllers
- `**` - All computers in Active Directory
- `***` - All computers via NET VIEW

**Token Substitutions:**
- `$$` - Current system's UNC name (\\SERVERNAME)
- `##` - Current system's hostname (SERVERNAME)
- `[[` and `]]` - Parentheses ( and )
- ``` `` ``` - Ampersand (&)
- `//` - Pipe (|)
- `__` - Space
- `''` - Double quote (")
- `::` - Percent sign (%)

**Examples:**
```cmd
# Check free disk space on all servers
Do.BAT $ DIR $$\C$\

# Get Windows version from domain controllers
Do.BAT @ VER

# Restart a service on all servers
Do.BAT $ SC \\## stop "Service Name" ``  SC \\## start "Service Name"

# Execute a script on servers from a custom list
Do.BAT MyServers.TXT CALL E:\Scripts\MyScript.BAT

# Ping all systems in network list
Do.BAT NetworkList PING ## -n 2
```

### SetDrive.BAT - Environment Initialization

This is the core initialization script that must be called at the beginning of most other scripts. It:
- Loads variables from `CustomVariables.TXT`
- Detects OS version and architecture
- Configures paths to utilities
- Sets up logging locations
- Initializes date/time variables

**Usage in scripts:**
```cmd
@ECHO OFF
CALL SetDrive %~n0
# Your script logic here
```

### BackupDHCP.BAT

Backs up DHCP server configuration including scopes, reservations, and options.

**Features:**
- Automatic backup rotation
- Configurable retention (default: 10 historical versions)
- Includes scope and server options
- Can be scheduled via Task Scheduler

**Usage:**
```cmd
BackupDHCP.BAT [/test]
```

### BackupGPO.BAT

Backs up Group Policy Objects with versioning and retention management.

**Features:**
- Individual or all GPO backup
- HTML report generation
- Historical version retention
- Configurable backup location

**Usage:**
```cmd
# Backup all GPOs
BackupGPO.BAT

# Backup specific GPO
BackupGPO.BAT "GPO Name"
```

### CreateArchive.BAT

Create compressed archives of specified folders with configurable retention policies.

**Features:**
- Multiple compression formats (ZIP, 7z)
- File integrity verification via checksums
- Retention policies (daily, monthly, yearly)
- Automatic scheduling
- Email notifications

**Configuration:**
Edit `ArchiveInfo.TXT` to define archive jobs.

**Usage:**
```cmd
# Run specific archive job
CreateArchive.BAT JobName

# Test mode (no changes)
CreateArchive.BAT JobName /test
```

### Replicate-Files.BAT

Synchronize files between locations with mirroring or incremental options.

**Features:**
- Robocopy-based with retry logic
- Multiple source/destination pairs
- File exclusion patterns
- Verification and reporting
- Scheduled execution

**Configuration:**
Edit `ReplicationInfo.TXT` to define replication jobs.

**Usage:**
```cmd
# Run replication job
Replicate-Files.BAT JobName

# Test mode
Replicate-Files.BAT JobName /test
```

### CheckIntegrity.BAT

Verify file integrity using cryptographic hashes (MD5, SHA-256, XXHASH64, etc.).

**Features:**
- Multiple hash algorithms
- Recursive folder scanning
- Change detection
- Email alerts for changes
- Baseline creation and comparison

**Usage:**
```cmd
# Create baseline
CheckIntegrity.BAT /baseline

# Check against baseline
CheckIntegrity.BAT /check

# Verify specific folder
CheckIntegrity.BAT C:\ImportantData
```

### CleanTemp.BAT

Automated cleanup of temporary files and folders.

**Features:**
- Configurable temp folder locations
- Age-based file deletion
- Recycle bin cleanup
- Safe mode (skip protected folders)
- Detailed logging

**Usage:**
```cmd
# Clean all temp locations
CleanTemp.BAT

# Clean specific location
CleanTemp.BAT C:\Temp

# Dry run mode
CleanTemp.BAT /whatif
```

### Additional Key Scripts

#### Repository Management
- **MakeRepository.BAT** - Create a staging repository share on the local machine for distribution
- **ReSyncScripts.BAT** - PUSH scripts to all systems in `FolderDefaults.TXT` from authorized repository
- **SyncScripts.BAT** - Refresh local staging area from central repository on same system
- **UpdateScripts.BAT** - Refresh scripts on individual remote server from source repository
- **GetScripts.BAT** - PULL scripts to current system from any repository source
- **$NewSetup.BAT** - Initial system configuration (folders, shares, scheduled jobs)
- **TaskConfig.BAT** - View/update credentials for scheduled jobs

#### System Information & Diagnostics
- **Debug.BAT** - Obtain comprehensive system diagnostics of local system
- **IPDebug.BAT** - Obtain IP configuration and network diagnostics
- **GetInfo.BAT** - Remote system forensics for incident response and malware detection
- **DNSCheck.BAT** - Verify AD DNS servers are in sync with working replication
- **GetComputerIPs.BAT** - Obtain list of systems from Active Directory with IP addresses
- **SpaceInfo.BAT** - Quickly display StorageInfo.BAT logs for local or remote server
- **JobHistoryUpdate.BAT** - Obtain summary of most recent scheduled job execution history

#### Utility Scripts
- **FindCommand.BAT** - Search for scripts or executables in the local script repository
- **FindInBatch.BAT** - Search for content within script files in the local repository
- **ConfigureNetwork.BAT** - Set IP, DNS, WINS, and TimeZone info for each server
- **Connect.BAT** - Quick RDP connection utility
- **OpenCMD.BAT** - Run commands under alternate user credentials
- **ManageUtil.BAT** - Remote management utility launcher
- **BulkRename.BAT** - Bulk file renaming operations

#### Scheduled Maintenance Jobs
- **SaveLogs.BAT** - Save Event Logs nightly (default: 1:30 AM)
- **StorageInfo.BAT** - Capture local storage consumption nightly (default: 2:30 AM)
- **OpsLogs.BAT** - Gather operational system stats from key systems (default: 5:00 AM)
- **KillLongProcess.BAT** - Kill processes exceeding predetermined duration limits

## Usage Examples

### Scenario 1: Daily System State Backup

1. Configure `ArchiveInfo.TXT` for SystemState job
2. Run manually to test:
   ```cmd
   CreateArchive.BAT SystemState /test
   ```
3. Enable scheduling:
   ```cmd
   CreateArchive.BAT SystemState /schedule
   ```

### Scenario 2: Execute Maintenance Across Servers

```cmd
# Stop a service on all servers
Do.BAT $ NET STOP "ServiceName"

# Clear temp files on all servers
Do.BAT $ DEL $$\C$\Temp\*.tmp /Q

# Check disk space
Do.BAT $ DIR $$\C$\ // FIND "bytes free"
```

### Scenario 3: Backup All Domain Controllers

```cmd
# Backup GPOs on all DCs
Do.BAT @ CALL %SystemDrive%\Scripts\BAT\BackupGPO.BAT

# Backup DHCP on DHCP servers
Do.BAT DHCPServers.TXT CALL %SystemDrive%\Scripts\BAT\BackupDHCP.BAT
```

### Scenario 4: File Replication with Verification

1. Configure replication in `ReplicationInfo.TXT`
2. Test the configuration:
   ```cmd
   Replicate-Files.BAT MyDocs /test
   ```
3. Run in production:
   ```cmd
   Replicate-Files.BAT MyDocs
   ```
4. Schedule for automatic execution

## Advanced Features

### Debug Mode

Enable debug mode for troubleshooting by setting the `Debug` environment variable:

**Debug Mode Options:**
```cmd
# Standard debug mode with pauses
SET Debug=TRUE

# Debug with detailed logging (no pauses)
SET Debug=LOG

# Step-by-step debug mode
SET Debug=STEP

# Verbose mode (ECHO ON)
SET Debug=VERBOSE
```

**What Debug Mode Shows:**
- All variable values (`SET @`)
- Script execution flow
- Command-line parameters
- Configuration file contents
- Command execution details
- Error conditions and diagnostics
- Current working directory
- Code page information

**Example Usage:**
```cmd
# Enable debug mode globally
SET Debug=LOG

# Run script with debug output
C:\Scripts\BAT\CreateArchive.BAT SystemState > C:\Temp\Debug.log 2>&1

# Review the debug log
notepad C:\Temp\Debug.log

# Clear debug mode
SET Debug=
```

**Debug Mode Features:**
- `TRUE` - Interactive with timeouts between steps
- `LOG` - Continuous output without pauses (best for log files)
- `STEP` - Shows pause points explicitly
- `VERBOSE` - Enables `ECHO ON` for maximum detail

**Additional Diagnostic Variables:**
- `@DIAGMODE` - Automatically set when `Debug` is active
- `@DEBUG_MODE` - Displays "[DEBUG MODE ON]" in output
- Many scripts check for `Debug` or `@DIAGMODE` to provide extra output

**Best Practices:**
- Use `Debug=LOG` when redirecting to files
- Use `Debug=TRUE` for interactive troubleshooting
- Always clear `Debug` after troubleshooting to avoid performance impact
- Combine with output redirection to capture full diagnostic data

### Custom Input Lists

Create custom server lists in the `Input` folder:

**Example - `Input\WebServers.TXT`:**
```
WEBSERVER01
WEBSERVER02
WEBSERVER03
```

**Usage:**
```cmd
Do.BAT WebServers IISRESET $$
```

### Email Notifications

Configure email settings in `CustomVariables.TXT`:
```
@MAIL=TRUE
@MAILSERVER=mail.company.com
@MAILPORT=25
@MAILSENDER=ScriptAdmin@company.com
@OPS-ADMIN=ITOps@company.com
```

Scripts will automatically send completion reports and error notifications.

### Syslog Integration

Enable centralized logging:
```
@USE_SYSLOGS=TRUE
@SYSLOG=syslog.company.local
@SYSLOG_PORT=514
```

Scripts can send status messages to syslog servers for centralized monitoring.

### Task Scheduling

Many scripts support automatic scheduling:
```cmd
# Create scheduled task
BackupSched.BAT /schedule

# Update existing schedule
CreateArchive.BAT JobName /updatesched

# Remove schedule
BackupSched.BAT /unschedule
```

**Task Scheduler Organization:**
- Starting with Windows Vista/Server 2008, scheduled jobs are organized
- Default location: `Task Scheduler Library\BrainWave\`
- Makes jobs easier to identify and manage
- Customize folder name via `@TaskFolder` in `CustomVariables.TXT`

**Important Notes:**
- **Always run setup scripts in elevated Command Prompt** (Run as Administrator)
- Required for creating folders, shares, scheduled jobs, and registry settings
- Use `TaskConfig.BAT` to set credentials for jobs requiring domain/service accounts
- Jobs like `OpsLogs.BAT` and `BackupDNS.BAT` require specific user context
- Re-run `$NewSetup.BAT` safely if you need to change drive letters or refresh configuration

### BrainWave Utilities Reference

The repository is powered by these custom utilities (available in x86 and x64):

**Essential Utilities** (Required):
- **DateInfo.exe** - Advanced date/time calculations and script variable generation
- **ReadConfig.exe** - Parse configuration files and extract variables
- **CheckParams.exe** - Validate command-line parameters
- **FindFiles.exe** - Locate files and utilities efficiently
- **Now.exe** - Display formatted timestamps

**File Operations:**
- **FileHash.exe** - Calculate file checksums (MD5, SHA-256, XXHASH64, etc.)
- **PrintFileInfo.exe** - Display detailed file information
- **Readable.exe** - Convert file sizes to human-readable format

**String Manipulation:**
- **ChangeCase.exe** - Convert string case (upper/lower/title)
- **MakeString.exe** - Generate repeated character strings
- **SubString.exe** - Extract substrings from text

**Security:**
- **RandomPass.exe** - Generate secure random passwords

**Logging:**
- **SyslogGen.exe** - Send syslog messages to remote servers

**Mathematics:**
- **CCalc.exe** - Command-line calculator
- **PrimePlus.exe** (GetPrimeNumbers.exe) - Prime number generation

All utilities support `/?` or `/help` for syntax information.

## Troubleshooting

### Common Issues

#### Issue: "DATEINFO not found" or similar utility errors
**Solution:** Install BrainWave Utilities to `<Drive>\Scripts\Utils\`

#### Issue: Scripts can't find configuration files
**Solution:** 
- Verify `Input` folder exists at `<Drive>\Scripts\BAT\Input\`
- Check that `CustomVariables.TXT` exists
- Ensure `SetDrive.BAT` is called at script start

#### Issue: Remote execution fails
**Solution:**
- Verify network connectivity
- Check administrative credentials
- Ensure Windows Firewall allows remote administration
- Install PAExec or PsExec in Utils folder
- Verify Remote Registry service is running

#### Issue: Backup jobs fail with "Access Denied"
**Solution:**
- Run with administrative privileges
- Check NTFS permissions on source and destination
- Verify network share permissions
- Ensure backup account has appropriate rights

#### Issue: Email notifications not working
**Solution:**
- Verify `@MAILSERVER` setting in `CustomVariables.TXT`
- Check SMTP relay permissions
- Test with telnet: `telnet mailserver 25`
- Verify firewall allows outbound SMTP

### Debug Logging

Enable detailed logging:
```cmd
SET Debug=LOG
Your_Script.BAT > C:\Temp\ScriptLog.txt 2>&1
```

Review the log file for detailed execution information.

### Getting Help

1. Check script header comments for usage syntax
2. Run scripts with `/?` or `/help` parameter:
   ```cmd
   Do.BAT /?
   ```
3. Review the configuration PDF: `Configuring the Script Repository.pdf`
4. Visit: https://www.BrainWaveCC.com/brainwave-utilities

## File Organization

### Runtime Location (Deployed on Every System)

```
C:\Scripts\
├── BAT\                      # Windows Batch/Shell scripts
│   ├── Input\               # Configuration files
│   │   ├── CustomVariables.TXT
│   │   ├── CustomVariables.%COMPUTERNAME%.TXT
│   │   ├── CustomVariables.MINI.%COMPUTERNAME%.TXT
│   │   ├── FolderDefaults.TXT
│   │   ├── ArchiveInfo.TXT
│   │   ├── ReplicationInfo.TXT
│   │   ├── ScriptSource.TXT
│   │   ├── ServerList.TXT
│   │   ├── [BrainWaveUtils].TXT
│   │   ├── [KnownServices].TXT
│   │   ├── [LongProcesses].TXT
│   │   ├── [CopyExemption].TXT
│   │   └── [Additional list files]
│   ├── LogonScripts\        # Logon script subdirectory
│   │   └── Scripts\
│   │       ├── Bat\
│   │       └── Utils\
│   ├── Services\            # Windows service scripts
│   │   └── EvtSys\
│   ├── Do.BAT
│   ├── SetDrive.BAT
│   ├── $NewSetup.BAT
│   ├── TaskConfig.BAT
│   └── [Many other scripts]
├── Perl\                    # Perl scripts (optional)
├── PowerShell\              # PowerShell scripts
├── VBS\                     # VBScript files
├── Utils\                   # 32-bit utilities
│   ├── Misc\               # Optional/infrequently used utilities
│   └── x64\                # 64-bit utilities
└── Zips\                    # Monthly zip archives of scripts

C:\Storage\                   # System Drive Storage
├── Drivers\                 # System drivers
├── Docs\                    # System documentation  
└── i386\                    # Windows source files (optional)

D:\Storage\                   # Primary Storage (customizable drive)
├── Installs\                # Software installation files
├── Downloads\               # Downloaded files
├── Logs\                    # Log files
│   └── Zips\               # Compressed log archives
├── Backups\                 # System backups
│   ├── DHCP\               # DHCP configuration backups
│   ├── DNS\                # DNS zone backups
│   ├── GPO\                # Group Policy Object backups
│   └── SystemState\        # System State backups
└── Work\                    # Working directory (optional)
```

### Staging Location (Central Repository - 1-2 Systems Only)

```
D:\Storage\Source\YourCompany\
├── Scripts\
│   ├── BAT\
│   │   ├── Input\           # Centralized configuration files
│   │   ├── LogonScripts\
│   │   └── Services\
│   ├── PowerShell\
│   ├── VBS\
│   └── Utils\
│       ├── Misc\
│       └── x64\
├── Zips\
│   └── Archives\
├── DateInfo.exe             # BrainWave utilities (root level)
├── Now.exe
├── FindFiles.exe
└── Install.BAT              # Remote installation bootstrap
```

**Shared as:** `\\SERVERNAME\Scripts_Source$`

## Best Practices

### 1. Testing
- Always test scripts in a non-production environment first
- Use `/test` or `/whatif` flags when available
- Review logs after execution
- Start with small batches before full deployment

### 2. Backup
- Keep backups of configuration files
- Version control your customizations
- Test restoration procedures regularly
- Maintain offsite copies of critical backups

### 3. Security
- Use dedicated service accounts with minimal required privileges
- Secure configuration files (they may contain sensitive info)
- Encrypt backups containing sensitive data
- Audit script execution and access
- Keep utilities and scripts updated

### 4. Monitoring
- Review logs regularly
- Set up email notifications for failures
- Use syslog integration for centralized monitoring
- Monitor disk space for backup locations
- Track backup retention compliance

### 5. Documentation
- Document custom modifications
- Maintain current server lists
- Note dependencies and prerequisites
- Keep runbooks for common procedures
- Document recovery procedures

## Contributing

This repository is designed to be customized for your environment. When making improvements:

1. Keep core scripts generic
2. Use configuration files for environment-specific settings
3. Add comments explaining complex logic
4. Follow existing naming conventions
5. Test thoroughly before deployment
6. Document new features

## Migration Guide

### From Older Repository Versions

1. **Backup current installation**
2. **Review new CustomVariables.TXT** for new settings
3. **Merge custom settings** into new configuration files
4. **Test core scripts** (Do.BAT, SetDrive.BAT) before full deployment
5. **Update scheduled tasks** if syntax changed
6. **Verify utility paths** are correct

### From Manual Administration

1. **Identify repetitive tasks** suitable for scripting
2. **Start with simpler scripts** (Do.BAT, GetInfo.BAT)
3. **Configure CustomVariables.TXT** for your environment
4. **Create server lists** in Input folder
5. **Test on non-critical systems first**
6. **Gradually expand automation**

## Support and Resources

- **Documentation**: See `Configuring the Script Repository.pdf`
- **BrainWave Utilities**: https://www.BrainWaveCC.com/brainwave-utilities
- **SysInternals Suite**: https://docs.microsoft.com/en-us/sysinternals/
- **PAExec**: https://www.poweradmin.com/paexec/
- **ADFind**: http://www.joeware.net/freetools/

## License

MIT License - See [LICENSE](LICENSE) file for details.

Copyright (c) 2024 ASB

## Acknowledgments

- BrainWave Computing Consulting for the core utilities
- Microsoft SysInternals team
- PowerAdmin for PAExec
- The Windows systems administration community

## Version History

- **v19.x** (2025): Unicode support, expanded Windows 11/Server 2022+ support
- **v18.x** (2022-2023): Enhanced AD integration, emergency job execution
- **v17.x** (2020-2022): Syslog metrics, script tracking, improved debug mode
- **v16.x** (2019-2020): ReadConfig utility integration, ROBOCOPY enhancements
- **v15.x** (2019): DateInfo v4.0+ integration, x64 utility support
- **v12.x-14.x** (2018): Performance improvements, CheckParams utility
- **Earlier versions**: Progressive feature additions and refinements

---

**Note**: This is an enterprise-grade script repository designed for Windows system administrators. Always test scripts in a safe environment before production deployment. Modify configuration files to match your environment rather than hardcoding values in scripts.

For detailed configuration instructions, see the included `Configuring the Script Repository.pdf` document.
