let
  sources = {
    # If you want to update these manually, update the commit ID then set sha256
    # to an empty string and then update the hash to whatever the error gives
    # you.
    #
    # I generated these from what a program I wrote which amounts to a
    # wrapper around `git ls-remote` plus `nix-prefetch-url`.
    flakey-profile = builtins.fetchTarball {
      # https://github.com/lf-/flakey-profile/tree/main
      url = "https://github.com/lf-/flakey-profile/archive/cb9c69766c032a791dd008fad59f3e8908ee4179.tar.gz";
      sha256 = "sha256-vPhr78oH3mguXRfcQXWWEoJjfGAK8DrdZnDelTtY7hA=";
      name = "source";
    };

    nixpkgs = builtins.fetchTarball {
      # https://github.com/nixos/nixpkgs/tree/nixos-unstable
      url = "https://github.com/nixos/nixpkgs/archive/85f1ba3e51676fa8cc604a3d863d729026a6b8eb.tar.gz";
      sha256 = "sha256-X09iKJ27mGsGambGfkKzqvw5esP1L/Rf8H3u3fCqIiU=";
      name = "source";
    };
  };

  # If updating hashes and git commits manually is bothersome, you could use
  # niv or my tool gridlock (which amounts to a wrapper around `git ls-remote`
  # and a from-scratch implementation of nix-prefetch-url).
  # Both niv and gridlock are available in nixpkgs as their respective names.
  #
  # Below is an example of using gridlock. To use it, comment out or delete
  # `sources` above in this file. It was created by the following commands:
  # gridlock --lockfile gridlock.json init
  # gridlock --lockfile gridlock.json add lf-/flakey-profile
  # gridlock --lockfile gridlock.json add --branch nixos-unstable nixos/nixpkgs
  #
  # You can update versions of things with:
  # gridlock --lockfile gridlock.json update
  #
  # You can look at how new/old your stuff is with:
  # gridlock --lockfile gridlock.json show
  /*
  sourcesRaw = builtins.fromJSON (builtins.readFile ./gridlock.json);
  # For every attribute in `.packages` in gridlock.json, map it to a fetched
  # tarball.

  sources = builtins.mapAttrs
    (name: value: builtins.fetchTarball {
      url = value.url;
      sha256 = value.sha256;
      name = "source";
    })
    sourcesRaw.packages;
  */


  # simplest way of getting nixpkgs: use nix-channel to manage versions
  /*
  pkgs = import <nixpkgs> { };
  */

  # mildly less convenient, but pinned:
  pkgs = import sources.nixpkgs { };

  flakey-profile = import (sources.flakey-profile + "/lib");
in
{
  profile = flakey-profile.mkProfile {
    # Usage:
    # Switch to this profile:
    #   nix run -f . profile.switch
    # Revert a profile change:
    #   nix run -f . profile.rollback
    # Build, without switching:
    #   nix build -f . profile
    inherit pkgs;
    paths = with pkgs; [
      hello
    ];
  };
}
