{ lib, fireFlakeConfig ? null, ... }:

let
  user = builtins.getEnv "USER";
  # Sanitize email-style usernames: first.last@company.com -> first.last
  sanitizedUser = builtins.head (lib.splitString "@" user);

  # Try sanitized name first, then fall back to full username with @ replaced
  localVarsPath = ./../vars + "/${sanitizedUser}.nix";
  privateVarsPath = if fireFlakeConfig != null then fireFlakeConfig.paths.vars + "/${sanitizedUser}.nix" else null;
in

if builtins.pathExists localVarsPath then
  (builtins.trace "🔍 Loading local vars/${sanitizedUser}.nix" (import localVarsPath))

else if fireFlakeConfig != null && builtins.pathExists privateVarsPath then
  (builtins.trace "🔐 Loading private fire-flake-config vars/${sanitizedUser}.nix" (import privateVarsPath))

else
  throw ''
    ❌ ERROR: No vars file found for user "${user}" (tried "${sanitizedUser}.nix").
    📄 Please either:
      - Copy vars/template.nix to vars/${sanitizedUser}.nix and fill it manually
      - OR make sure your fire-flake-config repo is accessible and has vars/${sanitizedUser}.nix
  ''
