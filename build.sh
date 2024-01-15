#!/usr/bin/env bash
# Compiles the SDLSHIM presentation layer and links it against the COBOL
# game logic into a single native binary: ./jumprun
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

CFLAGS="$(pkg-config --cflags sdl2 SDL2_image sqlite3)"
LIBS="$(pkg-config --libs sdl2 SDL2_image sqlite3)"

echo "== compiling presentation layer (csrc/sdlshim.c) =="
gcc -c $CFLAGS -O2 -Wall csrc/sdlshim.c -o csrc/sdlshim.o

echo "== compiling persistence layer (csrc/dbshim.c) =="
gcc -c $CFLAGS -O2 -Wall csrc/dbshim.c -o csrc/dbshim.o

echo "== compiling & linking JUMPRUN =="
cobc -x -I copybooks \
    src/jumprun.cob csrc/sdlshim.o csrc/dbshim.o \
    $LIBS \
    -o jumprun

echo "== build complete: ./jumprun =="
