nim c -d:mingw -d:release -d:ginAppName:"KOMPEAR" --opt:speed -d:fontaa --app:gui -d:nimPreviewHashRef -o:win/main.exe main

mkdir win
mkdir lin

cp content.bin win
cp lib/* win
pushd win
zip win.zip * -r
popd

nim c -d:release --opt:speed -d:fontaa -d:ginAppName:"KOMPEAR" --app:gui -d:nimPreviewHashRef -o:lin/main main
cp content.bin lin
pushd lin
zip linux.zip * -r
popd

butler push win/win.zip prestosilver/kompear:windows
butler push lin/linux.zip prestosilver/kompear:linux

./pushexample.sh
