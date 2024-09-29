Example PoC for packaging and developing with node/yarn based projects.

I started with `mkYarnModules` and `mkYarnPackages` and I got it to install and build out some files, but found out that it's deprecated.

If you are on current/unstable branch, you can use [`yarnConfigHook`](https://github.com/NixOS/nixpkgs/blob/c1897bcea75da90675dc3ed13b25c9cb9954e04e/pkgs/build-support/node/fetch-yarn-deps/default.nix), etc.

With this toolkit, you start by declaring an 'offline cache' where nix will store the unprocessed packages, downloaded directly from yarn.

The `yarnApp` derivation uses `yarnConfigHook` to install the dependencies from the cache.

You can test this by running:

`$> nix build .#yarnApp | find ./result/`

And it should show the `node_modules` directory and the tgz files for the dependencies in your `yarn.lock` file.

Add a package:
```
$> nix develop .#yarnShell

$> yarn install
$> yarn add react
```

If you update `yarn.lock`, you have to update the hash of the `yarnOfflineCache` or it will fail to install the newly added dependencies.

The way I've been doing it so far:

- comment out the 'hash' property (or change to null)
- rerun/build the `yarnApp`
- it should spit out the new hash to use
- add back the 'hash' property, with the new value
- run/build `yarnApp` again

This is all basically to build/install `node_modules/` for a project. The next step is a derivation to run a shell script or a webserver, or merge it with another dev shell environment.

So if you have a python app in another derivation, you can merge these together by linking directly into the `text`/`shellHook` entry point to your derivation: `ln -s "${yarnApp}/lib/node_modules/" $out/node_modules` and the resulting derivation will have a read-only `node_modules` to use.
