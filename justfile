win_main:
    nim c -d:mingw --opt:speed -d:fontaa --app:gui --deepcopy:on -d:nimPreviewHashRef main

linux_main:
    nim c -f --opt:speed -d:fontaa --app:gui --deepcopy:on -d:nimPreviewHashRef main

run_main: linux_main
    ./main
