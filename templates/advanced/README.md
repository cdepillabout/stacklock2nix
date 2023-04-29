# Stacklock2Nix Advanced Template

Welcome to the advanced Stacklock2nix template!

# About

This provides an empty Haskell project (the skeleton coming from the
`simple-hpack` stack template) and the associated stacklock2nix
files to allow for mixed cabal/stack building.

# Usage

To build:

> nix build

or

> nix develop
> cabal build

or

> nix develop
> stack build --nix

# Customisation

The default app is called 'some-app'. A search-and-replace in the
`flake.nix` and `./nix` for `some-app` to `your-app-name` should be
the bulk of the work (supposing you're building an executable).

# Todo

- [ ] Write about the difference between a library and an exe
- [ ] Explain cabal hash updates.
