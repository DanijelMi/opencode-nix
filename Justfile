[doc('List just options')]
default:
    @just --list

[doc('Build opencode-nix')]
build:
    nix build

[doc('Build and run opencode-nix in the given directory')]
run dir=".":
    cd "{{dir}}" && nix run "{{justfile_directory()}}"

[doc('Run opencode-nix with local configs for fast iteration')]
dev dir=".":
    cd "{{dir}}" && OPENCODE_CONFIG="{{justfile_directory()}}/configs/default.json" OPENCODE_CONFIG_DIR="{{justfile_directory()}}/configs" "{{justfile_directory()}}/result/bin/opencode-nix"

[doc('Update the flake lock file')]
update:
    nix flake update

