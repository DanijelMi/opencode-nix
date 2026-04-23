[doc('List just options')]
default:
    @just --list

[doc('Build opencode-nix')]
build:
    nix build

[doc('Build and run opencode-nix in the given directory')]
run dir=".":
    cd "{{dir}}" && nix run "{{justfile_directory()}}"

[doc('Run opencode-nix with local configs for fast iteration without having to build')]
dev dir=".":
    cd "{{dir}}" && OPENCODE_CONFIG="{{justfile_directory()}}/config/config.jsonc" OPENCODE_CONFIG_DIR="{{justfile_directory()}}/config" "{{justfile_directory()}}/result/bin/opencode-nix"

[doc('Update the flake lock file')]
update:
    nix flake update

