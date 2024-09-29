# TODO:
# - any way to make the yarnOfflineCache bit notice when package.json
#   changes and we need to change the hash? otherwise it just doesn't
#   seem to update but doesn't raise any errors.
# - setup javascript language server, linting, conform
# - merge into poetry2nix poc project
{
  description = "non-yarn2nix poc";
  inputs = {
    # NOTE: this only works on bleeding-edge unstable
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
  };
  outputs =
    { self, nixpkgs }:
    let
      pname = "non-yarn2nix-poc";
      version = "0.0.1";
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      yarnLock = ./yarn.lock;
      yarnOfflineCache = pkgs.fetchYarnDeps {
        inherit yarnLock;
        # NOTE: you have to delete this whenever yarn.lock is changed
        hash = "sha256-wzMw3Xd9ZSfR8hb2n8ZBUbh+s/et6LeemlQQy9gR1qU=";
      };
      yarnApp = pkgs.stdenv.mkDerivation {
        src = self;
        inherit pname version;
        nativeBuildInputs = with pkgs; [
          yarnConfigHook
          # NOTE: package.json has to define a 'build' script.
          # FUN FACT: the 'build' script has to actually do _something_.
          # an empty string will produce a vague error message.
          yarnBuildHook
          # NOTE: package.json must have name and version
          yarnInstallHook
          nodejs
        ];
        # yarnConfigHook, etc. aren't functions.
        # they are more like 'mix-ins' and you customize them by overriding
        # additional attributes they look for on the derivation.
        yarnOfflineCache = yarnOfflineCache;
      };
    in
    {
      packages.x86_64-linux = {
        offlineCache = yarnOfflineCache;
        testDrv = yarnApp;
      };
      devShells.x86_64-linux = {
        # NOTE: with poetry2nix, we used two devshells:
        # 1. the 'poetry' shell, with build env you can use to install/modify
        #    poetry deps
        # 2. the 'dev' shell which activates an env with python and the poetry
        #    dependencies.
        # with yarn, i think we just need one shell to do both.
        # you can make a shell application and symlink yarnApp node_modules
        # into your working dir, but that would be linking a read-only FS from
        # the store, meaning you can't `yarn add` anything normally.
        # i think the better option is just to have the one shell environment
        # with yarn installed, and packaging the yarnApp package will use it's
        # own source, in the store, but should be able to leverage the offline
        # cache.
        yarnShell = pkgs.mkShell {
          packages = with pkgs; [
            yarn
          ];
        };
      };
    };
}
