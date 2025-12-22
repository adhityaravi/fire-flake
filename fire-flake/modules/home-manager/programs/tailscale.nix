{ config, lib, pkgs, ... }:
let
  cfg = config.custom.tailscale;
in
{
  options.custom.tailscale = {
    enable = lib.mkEnableOption "Enable Tailscale.";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.tailscale;
      description = "Tailscale package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # Write the systemd service file to config dir for just recipe to install
    xdg.configFile."tailscale/tailscaled.service".text = ''
      [Unit]
      Description=Tailscale node agent (managed by home-manager)
      Documentation=https://tailscale.com/kb/
      Wants=network-pre.target
      After=network-pre.target NetworkManager.service systemd-resolved.service

      [Service]
      ExecStartPre=${cfg.package}/bin/tailscaled --cleanup
      ExecStart=${cfg.package}/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=${"$"}{PORT}
      ExecStopPost=${cfg.package}/bin/tailscaled --cleanup
      Restart=on-failure
      RuntimeDirectory=tailscale
      RuntimeDirectoryMode=0755
      StateDirectory=tailscale
      StateDirectoryMode=0700
      CacheDirectory=tailscale
      CacheDirectoryMode=0750
      Environment=PORT=41641

      [Install]
      WantedBy=multi-user.target
    '';
  };
}
