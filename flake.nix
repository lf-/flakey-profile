# SPDX-FileCopyrightText: 2023 Jade Lovelace
#
# SPDX-License-Identifier: CC0-1.0

{
  description = "Declaratively manage your installed software with flakes";

  outputs = { self }:
      {
        lib = import ./lib;
        templates = import ./lib/mkTemplates.nix [
          ./templates/default
        ];
      };

}
