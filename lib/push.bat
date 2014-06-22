cd %meshr%
set PATH=%meshr:/=\%\bin;%meshr:/=\%\usr\bin;%PATH%
set DEV="c:\cygroot\home\Yus\release\"
git add .
git status | grep -e "modified:\|new file:" | cut -c 14- | tar cf tmp/push.tar -v -T - --exclude=etc/* --exclude=proc/* --exclude=www/*.exe --exclude=bin/DualServer.* --exclude=bin/BluetoothView.cfg --ignore-failed-read  --ignore-command-error
tar --list --file=tmp\push.tar
if "%1"=="" pause
rem tar xf tmp/push.tar  -C %DEV:\=/% --keep-newer-files -v
tar xf tmp/push.tar  -C %DEV:\=/% --overwrite -v
cd c:\cygroot\home\Yus\host\
make-release.cmd