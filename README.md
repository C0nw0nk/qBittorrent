# qBittorrent

qBittorrent Windows Automatic batch file command line script with many features

DONATE! The same as buying me a beer or a cup of tea/coffee :D <3

PayPal : https://paypal.me/wimbledonfc

https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=ZH9PFY62YSD7U&source=url

Crypto Currency wallets :

BTC BITCOIN : `3A7dMi552o3UBzwzdzqFQ9cTU1tcYazaA1`

ETH ETHEREUM : `0xeD82e64437D0b706a55c3CeA7d116407E43d7257`

SHIB SHIBA INU : `0x39443a61368D4208775Fd67913358c031eA86D59`

# Script Features

Automatically delete completed torrents older than X number of days

Automatically delete torrents with no seeders

Automatically delete torrents that have never been seen completed

Automatically pause completed torrents to save bandwidth to stop seeding them

Automatically force start downloading torrents that have not completely downloaded

Automatically Fix for qBittorrent for torrents stuck infinitely at 99.X% when a torrent hits greater than >99% and it has infinite time remaining we need to force rechecking of the torrent to fix it

Automatically check torrents for blacklisted file types inside them like `.exe .txt .text .nfo .jpg .bmp .ico .png .gif .torrent .url .lnk .link .diz .ini .xml .sql .cmd .bat .dll .py .vbs .reg .html .htm .db .thumb .readme Sample sample. padding_file` files etc

# Optional

If you download compressed archives zip rar 7z gzip etc i did built a script to decompress those to so check it out.

https://github.com/C0nw0nk/ExtractNow

# Setup

qBittorrent WebUI Login is all you need to turn on / enable in your qBittorrent settings in order to use this script

# Settings

https://github.com/C0nw0nk/qBittorrent/blob/main/qbt.cmd#L10

To run this Automatically open `command prompt` and `RUN COMMAND PROMPT AS ADMINISTRATOR` and use the following command :
`SCHTASKS /CREATE /SC HOURLY /TN "Cons qBittorrent Script" /RU "SYSTEM" /TR "C:\Windows\System32\cmd.exe /c start /B "C:\qbt\qbt.cmd"`
