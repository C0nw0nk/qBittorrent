@ECHO OFF & setLocal EnableDelayedExpansion
color 0A
%*
TITLE C0nw0nk - Automatic qBittorrent Script

set username=admin
set password=pass
set webUI=http://localhost:8080


SET root_path=%~dp0
set torrent_file=torrent.txt
set cookie_jar=\cookies.txt

rem Remove existing cookie jar
del /F %temp%%cookie_jar% 2>nul
rem Remove existing torrent list
del /F %root_path%%torrent_file%

rem Login to qBittorrent
curl -s -b %temp%\cookies.txt -c %temp%\cookies.txt --header "Referer: %webUI%" --data "username=%username%&password=%password%" %webUI%/api/v2/auth/login >nul

curl -s -b "%temp%\cookies.txt" -c "%temp%\cookies.txt" --header "Referer: %webUI%" "%webUI%/api/v2/torrents/info" | jq -r | findstr """hash""" > %root_path%%torrent_file%

set "File=%root_path%%torrent_file%"
set /a count=0

for /F "tokens=* delims=" %%a in ('Type "%File%"') do (
         Set /a count+=1
         Set "output[!count!]=%%a"     
)

For /L %%i in (1,1,%Count%) Do (
	Call :Action "!output[%%i]!"
	rem pause
)

Exit

::*******************************************************
:Action
rem echo We treat this line : %1
rem echo (%1) | jq | findstr """hash"""
set torrent_=%1
set "torrent_=!torrent_:hash=!"
set "torrent_=!torrent_:"=!"
set "torrent_=!torrent_:,=!"
set "torrent_=!torrent_::=!"
set "torrent_=!torrent_: =!"
rem echo %torrent_%

rem last time torrent seen completed
for /f "tokens=*" %%a in ('
curl -s -b "%temp%\cookies.txt" -c "%temp%\cookies.txt" --header "Referer: %webUI%" "%webUI%/api/v2/torrents/info?hashes=%torrent_%" ^| jq -r ^| findstr """seen_complete"""
') do set torrent_last_complete=%%a
set "torrent_last_complete=!torrent_last_complete:seen_complete=!"
set "torrent_last_complete=!torrent_last_complete:"=!"
set "torrent_last_complete=!torrent_last_complete:,=!"
set "torrent_last_complete=!torrent_last_complete::=!"
set "torrent_last_complete=!torrent_last_complete: =!"
echo %torrent_last_complete%
echo("%torrent_last_complete%"|findstr "^[\"][-][1-9][0-9]*[\"]$ ^[\"][1-9][0-9]*[\"]$ ^[\"]0[\"]$">nul&&echo numeric||echo not numeric && EXIT /b
IF %torrent_last_complete% LEQ 0 (
echo it is 0
curl -s -b "%temp%\cookies.txt" -c "%temp%\cookies.txt" --header "Referer: %webUI%" "%webUI%/api/v2/torrents/delete?hashes=%torrent_%&deleteFiles=true"
)

rem number of seeds in swarm
for /f "tokens=*" %%a in ('
curl -s -b "%temp%\cookies.txt" -c "%temp%\cookies.txt" --header "Referer: %webUI%" "%webUI%/api/v2/torrents/info?hashes=%torrent_%" ^| jq -r ^| findstr """num_complete"""
') do set torrent_seeds=%%a
set "torrent_seeds=!torrent_seeds:num_complete=!"
set "torrent_seeds=!torrent_seeds:"=!"
set "torrent_seeds=!torrent_seeds:,=!"
set "torrent_seeds=!torrent_seeds::=!"
set "torrent_seeds=!torrent_seeds: =!"
echo %torrent_seeds%
echo("%torrent_seeds%"|findstr "^[\"][-][1-9][0-9]*[\"]$ ^[\"][1-9][0-9]*[\"]$ ^[\"]0[\"]$">nul&&echo numeric||echo not numeric && EXIT /b
IF %torrent_seeds% LEQ 0 (
echo it is 0
curl -s -b "%temp%\cookies.txt" -c "%temp%\cookies.txt" --header "Referer: %webUI%" "%webUI%/api/v2/torrents/delete?hashes=%torrent_%&deleteFiles=true"
)

exit /b
::*******************************************************

rem Remove used cookie jar
del /F %temp%%cookie_jar% 2>nul
rem Remove existing torrent list
del /F %root_path%%torrent_file%

rem pause

