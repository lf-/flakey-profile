# SPDX-FileCopyrightText: 2023 Jade Lovelace
#
# SPDX-License-Identifier: CC0-1.0

templates:
builtins.listToAttrs (
  builtins.map
    (template:
    let flakePath = template + "/flake.nix";
    in
    {
      name = builtins.baseNameOf template;
      value =
        {
          path = template;
          description = if builtins.pathExists flakePath then (import flakePath).description else "(no flake file)";
        };
    })
    templates)
