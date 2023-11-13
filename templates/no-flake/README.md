<!--
SPDX-FileCopyrightText: 2023 Jade Lovelace

SPDX-License-Identifier: CC0-1.0
-->

# flakey-profile, without flakes?!

Who needs flakes anyway! You just need a nixpkgs and a way of running stuff
with `nix run`, both of which work fine without flakes.

The point of flakes is to provide a mechanism of pinning inputs, a standardized
schema for tooling to work with outputs, evaluating in a pure mode by
default, caching *some* evaluation, and, to avoid random junk messing up
evaluation caching, copying files listed in the git index into the Nix store
before evaluating.

Most of this doesn't matter for profiles, and we could pin inputs just fine
before flakes, so let's demonstrate simply doing that.

## Usage

For some fitting irony, copy this template into your directory with
`nix flake init -t github:lf-/flakey-profile#no-flake`.


### To switch to this profile:

```
nix run -f . profile.switch
```
### To revert a profile change:

> **Warning**: This does not rollback the actions of `profile.pin`. To roll
> that back, revert to the previous version of the profile using a version
> control system and run `profile.pin` again.

```
nix run -f . profile.rollback
```

### To build, without switching:

```
nix build -f . profile
```

### To pin nixpkgs in `NIX_PATH` and the flake registry:

This makes `nix run nixpkgs#hello` and `nix-shell -p hello --run hello` give
you the same `hello` as if you listed it in your profile.

We recommend only running this command as root, since by default the only
channels used are on root's profile, and are used for `nix upgrade-nix` among
other things.

> **Warning**: This does not support revert internally; see the main README for
> more details. To revert pinning, use source control to get the previous
> version of the profile and run the pinning operation again.

```
nix run -f . profile.pin
```

### To manage your version of nixpkgs

Read `default.nix` and pick how you want to manage your dependencies. Three
examples are given:

- Simply `fetchTarball` some pinned commit ID.
- Simply `fetchTarball` some commit ID, but the commit ID and hash are in a
  JSON file that can be updated for you with [`gridlock`][gridlock].
- Use `<nixpkgs>` such that `nix-channel` manages your version of nixpkgs.

[gridlock]: https://github.com/lf-/gridlock

We support pinning `nixpkgs` system-wide on the basis of the version specified
here using `sudo nix run -f . profile.pin`.

## Note: the old CLI

We use the experimental CLI here because it is simply nicer. The old CLI is
legitimately pretty terrible, but if you have to use it, consider passing
`--log-format bar-with-logs` to get the new build progress display. More to the
point, there is no `nix run` equivalent for the old CLI.

Where `nix run -f . some.attrpath` is written, replace it in your head with:

```
"$(nix-build --no-out-link --log-format bar-with-logs . -A some.attrpath)"/bin/attrpath
```

if that is helpful or illustrative. For example:

```
"$(nix-build --no-out-link --log-format bar-with-logs . -A profile.switch)"/bin/switch
```
