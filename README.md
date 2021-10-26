# qBittorrent

qBittorrent Windows Automatic batch file command line script to check torrent for seeders if it has no seeders it will delete the torrent automatically I did not like the way there was no automation to the way qBittorent deals with torrent files so i built in a automatic process that will run every hour to deal with and clean up the torrents that get added.


# Script Features

Automatically delete completed torrents older than X number of days

Automatically delete torrents with no seeders

Automatically delete torrents that have never been seen completed

Automatically pause completed torrents to save bandwidth to stop seeding them

Automatically force start downloading torrents that have not completely downloaded

# Setup

qBittorrent WebUI Login is all you need to turn on / enable in your qBittorrent settings in order to use this script

# Settings

https://github.com/C0nw0nk/qBittorrent/blob/main/qbt.cmd#L10

To run this Automatically open `command prompt` and `RUN COMMAND PROMPT AS ADMINISTRATOR` and use the following command :
`SCHTASKS /CREATE /SC HOURLY /TN "Cons qBittorrent Script" /RU "SYSTEM" /TR "C:\Windows\System32\cmd.exe /c start /B "C:\qbt\qbt.cmd"`
