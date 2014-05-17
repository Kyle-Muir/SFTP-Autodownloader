SFTP-Autodownloader
===================

Downloads large binary files over SFTP using powershell.

To Setup
========
Edit autodownload.ps1 to match your environment
Edit filters.xml to match the filters you wish to download on
Set up the scheduled task

Setting up the scheduled task
=============================

- Open task scheduler
- Create basic task (Name, description etc)
- Under action -> start a program it should be as follows:
    - Program/script: powershell
    - add arguments (optional): -file "Path\to\autodownload.ps1" -ExecutionPolicy Bypass
- Ensure tasks runs when user is not logged in (otherwise a window will pop in the foreground, not ideal.)
- Under trigger -> advanced settings
    - Repeat task every (4 hours) for a duration of (indefinitely)