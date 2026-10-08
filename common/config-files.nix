{ lib }:

# Recursively walk a directory and turn every regular file it contains
# into an xdg.configFile entry, keyed by its path relative to that
# directory - so ./.config/hypr/UserConfigs/Keybinds.conf becomes the
# xdg.configFile key "hypr/UserConfigs/Keybinds.conf", symlinked from the
# nix store at ~/.config/hypr/UserConfigs/Keybinds.conf.
#
# Each file gets its own symlink (rather than symlinking whole directories
# wholesale) so that apps which write runtime state next to their config
# (btop's log, emacs' eln-cache/auto-save-list, etc.) still get a normal,
# writable directory to do that in.
#
# Each user passes their own ./.config, which is what keeps the two
# accounts' themes and app settings fully independent.
let
  configFilesOf = dir:
    lib.concatMapAttrs
      (name: type:
        let path = dir + "/${name}"; in
        if type == "directory" then
          lib.mapAttrs' (k: v: lib.nameValuePair "${name}/${k}" v) (configFilesOf path)
        else
          { ${name} = { source = lib.mkForce path; }; }
      )
      (builtins.readDir dir);
in
configFilesOf
