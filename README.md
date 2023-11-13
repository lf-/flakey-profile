<!--
SPDX-FileCopyrightText: 2023 Jade Lovelace

SPDX-License-Identifier: CC0-1.0
-->

# flakey-profile

This is a trivial tool to create declarative profiles with Nix flakes. This is
achieved with the same mechanisms as used by home-manager and NixOS: `nix-env
--set`, `nix-env --list-generations`, and `nix-env --rollback`.

The purpose of this tool is that people stop stubbing their toes on `nix
profile` and `nix-env` for non-declarative uses on non-NixOS systems by
providing a declarative alternative using flakes to pin versions of things.

## Non-goals

- Support `nix profile list` as [complained about
  here](https://discourse.nixos.org/t/transitioning-from-imperative-to-declarative-package-management-with-nix-alone/28728#disadvantages-18).
  We are in favour of the removal of `nix profile` from the Nix codebase in
  lieu of stabilization.
- Compatibility with imperative package management: there is no clear way to
  share a profile with an imperative setup.

  We might write a migration script in the future that takes `nix profile list
  --json` and converts it into a flake.
- Do similar things to home-manager for services or other things. This is just
  a replacement for `nix-env` and `nix profile` and nothing more.

## Related work

- [home-mangler](https://github.com/home-mangler/home-mangler), which uses
  a few hundred lines of Rust to wrangle `nix profile` into having exactly the
  expected packages installed. Their approach makes `nix profile list` work. By
  comparison, this project consists of two lines of shell script that bypass
  `nix profile` altogether.
- [nixos-rebuild](https://github.com/nixos/nixpkgs/blob/cc625486c48890c37ced7759727c51dd17d20fd3/pkgs/os-specific/linux/nixos-rebuild/nixos-rebuild.sh#L608),
  which uses the same methods to achieve its goals.
- [home-manager](https://github.com/nix-community/home-manager/blob/8765d4e38aa0be53cdeee26f7386173e6c65618d/modules/files.nix#L272)
  which is implemented via inexplicable cursed crimes for `nix profile` or the
  same method as this otherwise.
- [Flakes as a unified format for profiles](https://discourse.nixos.org/t/flakes-as-a-unified-format-for-profiles/29476)
- [Stop Using nix-env](https://stop-using-nix-env.privatevoid.net/)

## Usage

To use it, see the template in `templates/default`, or included below, or run:

```
nix flake init -t github:lf-/flakey-profile#templates.default
```

Flake example:

```nix
# SPDX-FileCopyrightText: 2023 Jade Lovelace
#
# SPDX-License-Identifier: CC0-1.0

{
  description = "Basic usage of flakey-profile";

  inputs = {
    flakey-profile.url = "github:lf-/flakey-profile";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, flakey-profile }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      {
        # Any extra arguments to mkProfile are forwarded directly to pkgs.buildEnv.
        #
        # Usage:
        # Switch to this flake:
        #   nix run .#profile.switch
        # Revert a profile change (note: does not revert pins):
        #   nix run .#profile.rollback
        # Build, without switching:
        #   nix build .#profile
        # Pin nixpkgs in the flake registry and in NIX_PATH, so that
        # `nix run nixpkgs#hello` and `nix-shell -p hello --run hello` will
        # resolve to the same hello as below:
        #   nix run .#profile.pin
        packages.profile = flakey-profile.lib.mkProfile {
          inherit pkgs;
          # Specifies things to pin in the flake registry and in NIX_PATH.
          pinned = { nixpkgs = toString nixpkgs; };
          paths = with pkgs; [
            hello
          ];
        };
      });
}
```

Then, use the following commands to do things with the new profile:

### Build the profile and switch to it

```
nix run .#profile.switch
```

### Revert a profile change

> **Warning**: This does not rollback the actions of `profile.pin`. To roll
> that back, revert to the previous version of the profile using a version
> control system and run `profile.pin` again.

```
nix run .#profile.rollback
```

### Build, without switching

```
nix build .#profile
```

### Update package versions

```
nix flake lock --update-input nixpkgs
```

or

```
nix flake update
```

then

```
nix run .#profile.switch
```

### Pin nixpkgs in the [flake registry] and in [`NIX_PATH`][nix_path_proc]

This makes `nix run nixpkgs#hello` and `nix-shell -p hello --run hello` give
you the same `hello` as if you listed it in your profile.

We recommend only running this command as root, since by default the only
channels used are on root's profile, and are used for `nix upgrade-nix` among
other things.

> **Warning**: This does not support revert internally; see below for more
> details. To revert pinning, use source control to get the previous version of
> the profile and run the pinning operation again.

```
nix run .#profile.pin
```

#### Context

The [flake registry] is used to resolve unqualified flake names such as
`nixpkgs` in `nix run nixpkgs#hello`, and can be overridden on a per-user or
system-wide basis. `NIX_PATH` is used to resolve `<nixpkgs>` and other
references in angle brackets, and if not present, [this
procedure][nix_path_proc] is used. By running `profile.pin`, both the flake
registry and the channel of the running user will be overridden to point to the
`nixpkgs` you used to build your profile.

[flake registry]: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-registry.html#registry-format
[nix_path_proc]: https://nixos.org/manual/nix/stable/command-ref/env-common.html#env-NIX_PATH

> **Note**: We don't provide an easy way of rolling back a pin, since the Nix
> flake registry is not managed with profiles and the semantics of keeping
> everything in sync when reverting don't really work out. We suggest rolling
> back pins by reverting to the previous version in your preferred version
> control system, then rerunning `pin`.
>
> In a different implementation, we would just use an activation script to
> achieve this the same way as NixOS and home-manager, however, that conflicts
> with the goals of this project.
>
> If it is useful to fixing a system, the things changed are in `~/.config/nix/registry.json`
> (`/etc/nix/registry.json` if run as root), and linked to from
> `~/.nix-defexpr/`. Channels can be rolled back with
> `nix-env --profile $(readlink ~/.nix-defexpr/channels) --rollback`
> or for root, `sudo nix-env --profile $(readlink ~/.nix-defexpr/channels_root) --rollback`.
> The former, not much can be done about, and it's probably easiest to just
> delete the `registry.json` if it's broken.

