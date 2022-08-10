# This file is only needed if you're running NixOS.
# Most other distributions will have some compiler available globally.

with import <nixpkgs> {};
stdenv.mkDerivation {
  name = "Sysimage";
  # If you need libraries, list them here
  buildInputs = [ gcc ];
}
