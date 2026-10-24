{ config, lib, pkgs, ... }:

let
  docker = pkgs.docker_29;
in
{
  # Docker already enabled in configuration.nix

  # Create systemd service for 9router
  systemd.services.router9 = {
    description = "9Router - AI Model Router";
    after = [ "docker.service" "network.target" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
      ExecStartPre = [
        # Stop and remove old container if exists
        "-${docker}/bin/docker stop 9router"
        "-${docker}/bin/docker rm 9router"
        # Pull or update the container
        "${docker}/bin/docker pull ghcr.io/decolua/9router:latest"
      ];
      ExecStart = [
        # Start the container
        ''${docker}/bin/docker run -d \
          --name 9router \
          --restart unless-stopped \
          -p 3001:3000 \
          -v /var/lib/9router:/app/.data \
          ghcr.io/decolua/9router:latest''
      ];
      ExecStop = [
        "${docker}/bin/docker stop 9router"
        "${docker}/bin/docker rm 9router"
      ];
    };
  };

  # Create data directory
  systemd.tmpfiles.rules = [
    "d /var/lib/9router 0755 nvtank users -"
  ];

  # Add convenience wrapper script
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "9router" ''
      case "$1" in
        start)
          sudo systemctl start router9
          echo "9Router started at http://localhost:3001"
          ;;
        stop)
          sudo systemctl stop router9
          echo "9Router stopped"
          ;;
        restart)
          sudo systemctl restart router9
          echo "9Router restarted"
          ;;
        status)
          sudo systemctl status router9
          ;;
        logs)
          ${docker}/bin/docker logs -f 9router
          ;;
        *)
          echo "Usage: 9router {start|stop|restart|status|logs}"
          echo ""
          echo "9Router is running at: http://localhost:3001"
          ;;
      esac
    '')
  ];
}
