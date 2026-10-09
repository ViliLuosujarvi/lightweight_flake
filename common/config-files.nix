{ lib }:

# Turn every regular file under a directory into an xdg.configFile entry,
# keyed by its path relative to that directory - so ./.config/waybar/style.css
# becomes the xdg.configFile key "waybar/style.css", symlinked from the nix
# store at ~/.config/waybar/style.css.
#
# Each file gets its own symlink (rather than symlinking whole directories
# wholesale) so that apps which write runtime state next to their config
# (btop's log, etc.) still get a normal,
# writable directory to do that in. Per-file keys are also what lets an
# account's own file replace the shared one of the same name (see
# common/home.nix).
dir:
lib.listToAttrs (map
  (path: lib.nameValuePair
    (lib.removePrefix "${toString dir}/" (toString path))
    { source = path; })
  (lib.filesystem.listFilesRecursive dir))
