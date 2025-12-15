# Version history for searchfs

## 0.4 - 15/12/2025
    * Now requires macOS 11+

## 0.3
    * New -l flag makes searchfs list all mounted volumes that support catalog search
    * Volume to search can now be specified via device name (e.g. "/dev/disk1s1") as well as mount path
    * Regex modifiers ^ and $ can now be used to match only at the start or end of a filenames, respectively.

## 0.2 - 26/04/2019
    * Fixed issue which prevented searchfs from working on older versions of macOS
    * Now fails silently when path lookup fails for a file system object ID
    * Now runs on macOS 10.7 or later

## 0.1 - 14/07/2018
    * Initial release
