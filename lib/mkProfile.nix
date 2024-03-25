# SPDX-FileCopyrightText: 2023 Jade Lovelace
#
# SPDX-License-Identifier: CC0-1.0

# Creates a profile. Arguments are forwarded to pkgs.buildEnv.
#
# The following attributes are available:
# - .switch: switches to the profile
# - .rollback: rolls back to the previous version of the profile
args @ {
  # nixpkgs to use
  pkgs
, # Name of the profile, which appears in the Nix store path of the result
  name ? "flake-profile"
, # Items to pin in the flake registry and NIX_PATH, such that they're seen by
  # `nix run nixpkgs#hello` and `nix-shell -p hello --run hello`.
  pinned ? { }
, # Extra arguments given when switching profiles (n.b. not shell escaped).
  extraSwitchArgs ? [ ]
, ...
}:
let
  args' = builtins.removeAttrs args [ "pkgs" "pinned" "extraSwitchArgs" ];
  pins = import ./pin.nix { inherit pkgs pinned; };

  env = pkgs.buildEnv (args' // {
    inherit name;
  });
in
env // {
  switch = pkgs.writeShellScriptBin "switch" ''
    nix-env --set ${env} ${toString extraSwitchArgs} "$@"
  '';
  rollback = pkgs.writeShellScriptBin "rollback" ''
    nix-env --rollback ${toString extraSwitchArgs} "$@"
  '';

  # pass through pins, so you can e.g. nix build .#profile.pins.channels
  inherit pins;
  # This script pins any of the items in "pinned" in both the flake registry
  # and the nix channels, such that `nix run nixpkgs#hello` and
  # `nix-shell -p hello --run hello` will hit the same nixpkgs as is used in
  # the declarative profile.
  #
  # It is not really possible to cleanly roll this back in terms of the flake
  # registry, so we suggest just reverting with git in that case.
  pin = pkgs.writeShellScriptBin "pin" ''
    if [[ $UID == 0 ]]; then
      ${pins.pinFlakes { isRoot = true; }}
    else
      ${pins.pinFlakes { isRoot = false; }}
    fi
    nix-env --profile /nix/var/nix/profiles/per-user/$USER/channels --set ${pins.channels}
  '';
}
