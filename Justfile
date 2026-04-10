[doc('List just options')]
default:
    @just --list

[doc('Build opencode-nix')]
build:
    nix build

[doc('Build and run opencode-nix')]
run:
    nix run

[doc('Update the flake lock file')]
update:
    nix flake update

