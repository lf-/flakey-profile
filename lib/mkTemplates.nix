# SPDX-FileCopyrightText: 2023 Jade Lovelace
#
# SPDX-License-Identifier: CC0-1.0

templates:
builtins.listToAttrs (
  builtins.map
    (template:
    let flake = import (template + "/flake.nix");
    in
    {
      name = builtins.baseNameOf template;
      value =
        {
          path = template;
          inherit (flake) description;
        };
    })
    templates)
