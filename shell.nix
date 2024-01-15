{ pkgs ? import <nixpkgs> {} }:

# COBOLD toolchain: cobc + SDL2 + sqlite.
pkgs.mkShell {
  name = "cobold";

  nativeBuildInputs = [
    pkgs.gnucobol.bin  # cobc / cobcrun - COBOL compiler & runtime
    pkgs.gnucobol.dev  # libcob headers, needed by cobc at compile time
    pkgs.gcc           # compiles csrc/sdlshim.c and links the final binary
    pkgs.pkg-config
    pkgs.gdb
  ];

  buildInputs = [
    pkgs.SDL2
    pkgs.SDL2_image
    pkgs.sqlite      # relational persistence layer for the account ledger
  ];

  shellHook = ''
    export COBOLD_ROOT="$PWD"
    echo "cobold dev shell: $(cobc --version | head -n1)"
    echo "run ./build.sh to compile, then ./jumprun to play"
  '';
}
