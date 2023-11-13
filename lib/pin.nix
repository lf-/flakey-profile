# SPDX-FileCopyrightText: 2023 Jade Lovelace
#
# SPDX-License-Identifier: CC0-1.0

{ pkgs, pinned ? { } }:
let
  inherit (pkgs) lib;
  pathOk = item: builtins.match ".*-source$" (toString item) != null;
  pathChecked = name: item: pkgs.lib.assertMsg (pathOk item) ''
    Flake registry pin item path must end with -source, due to https://github.com/NixOS/nix/issues/7075.
    Name: ${name}
    Path: ${toString item}

    Consider pinning nixpkgs with `builtins.fetchTarball` with `name` set to "source".
  '';

  pins = builtins.mapAttrs (name: value: assert pathChecked name value; value) pinned;
in
{
  inherit pins;
  channels = pkgs.linkFarm "user-environment" pins;
  pinFlakes = { isRoot }:
    lib.concatMapStringsSep "\n"
    (name: "nix registry pin ${lib.optionalString isRoot "--registry /etc/nix/registry.json"} --override-flake ${name} ${pins.${name}} ${name}")
    (builtins.attrNames pins);
}
