# w10-offline-parental-control

Simplistic user account time slots and powershell script to use in task scheduler


**Usage:**
- Setup a login task with the command:
`C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`
and parameters `-WindowStyle Hidden  -executionpolicy bypass  -command "& .\health.ps1" -creditMinutes 90 -maxDate "20:00" -shutSeconds 600 -start 1` in some folder

- Setup a delayed  recurring task (after 5 minutes and every 20 minutes for instance) with the command:
`C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`
with parameters `-WindowStyle Hidden  -executionpolicy bypass  -command "& .\health.ps1" -creditMinutes 90 -maxDate "20:00" -shutSeconds 600` (only start changed to `0`) in the same folder

In this example command, computer will shutdown after 90 minutes of daily use (at once or not), never going after 20:00 , and with a grace duration of 600 seconds (10 minutes) before shutting down.

Some files with the date will be produced in the selected task command folder with the daily use in minutes. (Beware, the current day file modification time is used to increment the elapsed time)


**Bonus**

The batch file shows a sample command (to run in cmd started as admin) to lock login time slots as well (in this example, L is the login name, replace it with your target user name)
