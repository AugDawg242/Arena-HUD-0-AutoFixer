Arena-HUD-0-AutoFixer

An unofficial, experimental Windows workaround for a League of Legends Arena issue where a panel of zeros covers champion stats.

This is not an official Riot Games fix. It may not work for everyone. Review the scripts before running them.

How it works

The monitor checks these files in the default League installation every 15 seconds:

- C:\Riot Games\League of Legends\Config\game.cfg
- C:\Riot Games\League of Legends\Config\PersistedSettings.json

When it finds ShowPlayerPerks set to 1, it changes the first matching value in that file to 0, checks the result, and logs the correction. It displays a status message approximately every 60 seconds.

The tool changes configuration files on disk only. It does not modify game memory, and the running game may not immediately reload the changed setting.

Get started

1. Download the repository ZIP from the green Code button and extract it into a folder of your choice.
2. Keep Arena-HUD-0-AutoFixer.cmd and Arena-HUD-0-AutoFixer.ps1 together in that folder.
3. Review both scripts and make a manual copy of your League Config folder before first use.
4. If League is installed somewhere other than C:\Riot Games\League of Legends, open the .ps1 file and update the $dir path near the top.
5. Double-click Arena-HUD-0-AutoFixer.cmd to start monitoring. Administrator privileges are not intentionally required; try running normally first.
6. Look for game.cfg=0; PersistedSettings.json=0 in the status output. Keep the window open while playing Arena.
7. Press Q in the monitor window to quit.

If the console title starts with Select, press Esc. Windows console selection mode can pause the monitor.

Backups and cleanup

Backups are saved next to the original configuration files, not next to the scripts.

- The first correction to each file in a monitor session creates one timestamped backup of that file.
- Later corrections to the same file in that session do not create additional backups.
- At startup and after a new backup, the tool keeps the five newest matching backups per file and deletes older matching backups.
- The maximum is normally ten retained backups total: five for game.cfg and five for PersistedSettings.json.
- Backup cleanup can remove older backups created by earlier versions of this monitor if their filenames match. Save copies elsewhere first if you want to keep them.

Example backup filename:

game.cfg.backup-20261025-223528-037

Logs and status

The monitor appends messages to Arena-HUD-0-AutoFixer.log in the folder containing the scripts. It reports checks, detected values, file corrections, and backup activity.

A correction counter measures individual file changes, not the number of backup files or reset events. If both config files are corrected in one cycle, the counter increases by two.

Stopping or reverting

Press Q to stop monitoring. The tool does not automatically restore the original values when you quit.

To revert the configuration change, stop the monitor and either restore an appropriate backup or manually change ShowPlayerPerks back to its previous value. Take care not to overwrite unrelated settings you changed afterward.

Testing so far

During October 25-26, 2026, one player reported:

- Before monitoring, the zero-stats overlay appeared in roughly half of Arena matches.
- Approximately 13 consecutive clean matches across two sessions while using the monitor.
- On October 25, the log recorded two detection times and four individual file corrections.
- The first two matches on October 26 were clean, with no corrections reported at that point.

These observations are not a controlled test and do not prove the monitor caused the improvement. The newer backup-rotation version has not been independently tested in a live League session.

Known limitations

- The script rewrites the entire file when making a correction. It does not use atomic writes or coordinate with League's own file writes; simultaneous updates could conflict.
- It changes only the first matching ShowPlayerPerks value in each file.
- The League installation path is configured manually.
- Do not run multiple copies of the monitor at once.
- The configuration folder must exist and be writable.
- The launcher uses a process-scoped PowerShell execution-policy override. Inspect the source before running it.
- This is an unofficial community experiment, not endorsed by Riot Games. Use at your own risk.

Sharing and privacy

The repository needs only the two scripts and this README. Do not publish your League configuration backups or raw logs without checking them for personal information and local paths.
