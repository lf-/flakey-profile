# SPDX-FileCopyrightText: 2023 Jade Lovelace
#
# SPDX-License-Identifier: CC0-1.0

# Creates a profile. Arguments are forwarded to pkgs.buildEnv.
#
# The following attributes are available:
# - .switch: switches to the profile
# - .rollback: rolls back to the previous version of the profile
args @ { pkgs, name ? "flake-profile", ... }:
let
  args' = builtins.removeAttrs args [ "pkgs" ];
  env = pkgs.buildEnv (args' // {
    inherit name;
  });
in
env // {
  switch = pkgs.writeShellScriptBin "switch" ''
    nix-env --set ${env} "$@"
  '';
  rollback = pkgs.writeShellScriptBin "rollback" ''
    nix-env --rollback "$@"
  '';
}
