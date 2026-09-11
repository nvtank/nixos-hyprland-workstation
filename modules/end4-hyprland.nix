{ config, inputs, lib, pkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
  hyprlandPackage = inputs.hyprland.packages.${system}.hyprland;
  hyprlandPortal = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
  quickshellPackage = inputs.quickshell.packages.${system}.default;
  end4Quickshell = pkgs.stdenv.mkDerivation {
    pname = "end4-quickshell";
    version = "0.2.1";
    dontUnpack = true;

    nativeBuildInputs = [ pkgs.makeWrapper pkgs.qt6.wrapQtAppsHook ];
    buildInputs = with pkgs; [
      quickshellPackage
      gsettings-desktop-schemas
      kdePackages.kirigami
      kdePackages.qtlocation
      kdePackages.qtpositioning
      kdePackages.qtwayland
      kdePackages.syntax-highlighting
      qt6.qt5compat
      qt6.qtbase
      qt6.qtdeclarative
      qt6.qtimageformats
      qt6.qtmultimedia
      qt6.qtpositioning
      qt6.qtquicktimeline
      qt6.qtsensors
      qt6.qtsvg
      qt6.qttools
      qt6.qttranslations
      qt6.qtvirtualkeyboard
      qt6.qtwayland
    ];

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/bin"
      makeWrapper ${quickshellPackage}/bin/qs "$out/bin/qs" \
        --prefix XDG_DATA_DIRS : ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}
      runHook postInstall
    '';
  };
  end4Variables = ./end4-variables.lua;
  end4Execs = ./end4-execs.lua;
  end4Keybinds = ./end4-keybinds.lua;
  end4Rules = ./end4-rules.lua;
  end4LockVisual = ./end4-lock-visual.qml;

  end4Screenshot = pkgs.writeShellApplication {
    name = "end4-screenshot";
    runtimeInputs = with pkgs; [ coreutils hyprshot libnotify xdg-user-dirs ];
    text = ''
      mode="''${1:-region}"
      output_dir="$(xdg-user-dir PICTURES)/Screenshots"
      mkdir -p "$output_dir"

      case "$mode" in
        region) hyprshot --freeze --mode region --output-folder "$output_dir" ;;
        output) hyprshot --mode output --mode active --output-folder "$output_dir" ;;
        *) echo "Usage: end4-screenshot [region|output]" >&2; exit 2 ;;
      esac
    '';
  };

  end4ScreenRecord = pkgs.writeShellApplication {
    name = "end4-screen-record";
    runtimeInputs = [ hyprlandPackage ] ++ (with pkgs; [ coreutils jq libnotify procps slurp util-linux wf-recorder xdg-user-dirs xdg-utils ]);
    text = ''
      state_dir="''${XDG_RUNTIME_DIR:-/tmp}/end4-screen-record"
      pid_file="$state_dir/pid"
      output_file="$state_dir/output"
      mkdir -p "$state_dir"
      exec 9>"$state_dir/lock"
      flock --nonblock 9 || exit 0

      if [[ -s "$pid_file" ]]; then
        recorder_pid="$(<"$pid_file")"
        if kill -0 "$recorder_pid" 2>/dev/null; then
          kill -INT "$recorder_pid"
          saved_file="$(<"$output_file")"
          for _ in $(seq 1 50); do
            kill -0 "$recorder_pid" 2>/dev/null || break
            sleep 0.1
          done
          rm -f "$pid_file" "$output_file"
          notify-send "Screen recording saved" "$saved_file"
          xdg-open "$(dirname "$saved_file")" >/dev/null 2>&1 &
          exit 0
        fi
        rm -f "$pid_file" "$output_file"
      fi

      videos_dir="$(xdg-user-dir VIDEOS)/Recordings"
      mkdir -p "$videos_dir"
      saved_file="$videos_dir/Recording_$(date '+%Y-%m-%d_%H.%M.%S').mp4"

      countdown() {
        for seconds in 3 2 1; do
          notify-send --replace-id=7391 --expire-time=900 \
            "Screen recording" "Starting in $seconds…"
          sleep 1
        done
        notify-send --replace-id=7391 --expire-time=1200 \
          "● Recording" "Press the same shortcut again to stop"
      }

      case "''${1:-region}" in
        region)
          geometry="$(slurp)" || exit 0
          countdown
          wf-recorder --geometry "$geometry" --file "$saved_file" 9>&- >/tmp/end4-wf-recorder.log 2>&1 &
          ;;
        output)
          monitor="$(hyprctl activeworkspace -j | jq -r '.monitor')"
          countdown
          wf-recorder --output "$monitor" --file "$saved_file" 9>&- >/tmp/end4-wf-recorder.log 2>&1 &
          ;;
        *) echo "Usage: end4-screen-record [region|output]" >&2; exit 2 ;;
      esac

      recorder_pid=$!
      printf '%s\n' "$recorder_pid" > "$pid_file"
      printf '%s\n' "$saved_file" > "$output_file"
      notify-send "Screen recording started" "Press the same shortcut again to stop"
    '';
  };

  end4Setup = pkgs.writeShellApplication {
    name = "end4-setup";
    runtimeInputs = with pkgs; [ coreutils findutils gnused rsync gnutar gzip ];
    text = ''
      set -euo pipefail

      case "''${1:-}" in
        --check)
          echo "illogical-impulse: ${inputs.illogical-impulse}"
          echo "end4-pC: ${inputs.end4-pc}"
          exit 0
          ;;
        --help|-h)
          echo "Usage: end4-setup [--check]"
          echo "Installs mutable Hyprland and Quickshell configs after creating a backup."
          exit 0
          ;;
        "") ;;
        *) echo "Unknown argument: $1" >&2; exit 2 ;;
      esac

      if [[ "$(id -u)" -eq 0 ]]; then
        echo "Run end4-setup as the desktop user, not as root." >&2
        exit 1
      fi

      config_root="''${XDG_CONFIG_HOME:-$HOME/.config}"
      state_root="''${XDG_STATE_HOME:-$HOME/.local/state}/end4-nixos"
      stamp="$(date -u +%Y%m%dT%H%M%SZ)"
      backup_dir="$state_root/backups/$stamp"

      mkdir -p "$backup_dir" "$config_root"
      : > "$backup_dir/absent"

      for target in hypr quickshell; do
        if [[ -e "$config_root/$target" ]]; then
          tar -C "$config_root" -czf "$backup_dir/$target.tar.gz" "$target"
        else
          printf '%s\n' "$target" >> "$backup_dir/absent"
        fi
      done

      for staging_dir in "$config_root/hypr.end4-new" "$config_root/quickshell.end4-new"; do
        if [[ -e "$staging_dir" ]]; then
          chmod -R u+w "$staging_dir" 2>/dev/null || true
          rm -rf "''${staging_dir:?}" || {
            # If rm fails, try harder with find
            find "$staging_dir" -type d -exec chmod u+w {} + 2>/dev/null || true
            find "$staging_dir" -type f -exec chmod u+w {} + 2>/dev/null || true
            rm -rf "''${staging_dir:?}"
          }
        fi
      done
      mkdir -p "$config_root/hypr.end4-new" "$config_root/quickshell.end4-new"

      rsync -a --no-owner --no-group ${inputs.illogical-impulse}/dots/.config/hypr/ "$config_root/hypr.end4-new/"
      chmod -R u+w "$config_root/hypr.end4-new"
      
      rsync -a --no-owner --no-group ${inputs.illogical-impulse}/dots/.config/quickshell/ "$config_root/quickshell.end4-new/"
      chmod -R u+w "$config_root/quickshell.end4-new"
      
      rsync -a --no-owner --no-group --exclude='.git' ${inputs.end4-pc}/ "$config_root/quickshell.end4-new/end4-pC/"
      chmod -R u+w "$config_root/quickshell.end4-new"

      # A crash/restart must not leave more than one shell instance creating
      # layer surfaces. Keep this patch next to the upstream config import so
      # future end4-setup runs retain the duplicate-instance guard.
      # shellcheck disable=SC2016 # $qsConfig belongs to the generated Lua.
      sed -i 's|hl.exec_cmd("qs -c $qsConfig")|hl.exec_cmd("qs --no-duplicate -c $qsConfig")|' \
        "$config_root/hypr.end4-new/hyprland/execs.lua"
      # shellcheck disable=SC2016 # $qsConfig belongs to the generated Lua.
      sed -i 's|killall ydotool qs quickshell; qs -c $qsConfig &|killall ydotool qs quickshell; qs --no-duplicate -c $qsConfig \&|' \
        "$config_root/hypr.end4-new/hyprland/keybinds.lua"

      # This laptop's touchpad feels reversed with the end4 shell override.
      # Apply the user's preferred physical scroll direction after staging and
      # keep compositor animations enabled for smooth workspace transitions.
      sed -i 's/natural_scroll = false/natural_scroll = true/' \
        "$config_root/hypr.end4-new/hyprland/shellOverrides/main.lua"
      
      # Replace the disabled animations with a full animation config for smooth
      # workspace switching and window movement transitions. Inject directly into
      # main.lua instead of using source to avoid syntax issues.
      
      # First, delete the line that disables animations
      sed -i '/hl\.config({ animations = { enabled = false } })/d' \
        "$config_root/hypr.end4-new/hyprland/shellOverrides/main.lua"
      
      # Create a temporary file with the animations config
      cat > "$config_root/hypr.end4-new/hyprland/shellOverrides/animations.tmp" << 'ANIM_EOF'
hl.config({ 
    animations = { 
        enabled = true,
        bezier = {
            "wind, 0.05, 0.9, 0.1, 1.05",
            "winIn, 0.1, 1.1, 0.1, 1.1",
            "winOut, 0.3, -0.3, 0, 1",
            "liner, 1, 1, 1, 1"
        },
        animation = {
            "windows, 1, 6, wind, slide",
            "windowsIn, 1, 6, winIn, slide",
            "windowsOut, 1, 5, winOut, slide",
            "windowsMove, 1, 5, wind, slide",
            "border, 1, 1, liner",
            "borderangle, 1, 180, liner, loop",
            "fade, 1, 10, default",
            "workspaces, 1, 5, wind",
            "layers, 1, 5, default, fade"
        }
    } 
})
ANIM_EOF
      
      # Insert the animations config after the "layout = dwindle" line using awk
      awk '/hl\.config\({ general = { layout = "dwindle" } }\)/ {print; system("cat \"$config_root/hypr.end4-new/hyprland/shellOverrides/animations.tmp\""); next} 1' \
        "$config_root/hypr.end4-new/hyprland/shellOverrides/main.lua" > "$config_root/hypr.end4-new/hyprland/shellOverrides/main.lua.new"
      mv "$config_root/hypr.end4-new/hyprland/shellOverrides/main.lua.new" \
        "$config_root/hypr.end4-new/hyprland/shellOverrides/main.lua"
      rm -f "$config_root/hypr.end4-new/hyprland/shellOverrides/animations.tmp"

      # Keep the desktop widget picker visibly translucent. This submenu uses
      # its own opaque Material layer instead of the global panel background.
      sed -i \
        's|color: Appearance.colors.colLayer0|color: Qt.rgba(Appearance.colors.colLayer0.r, Appearance.colors.colLayer0.g, Appearance.colors.colLayer0.b, 0.14)|' \
        "$config_root/quickshell.end4-new/end4-pC/modules/common/widgets/WidgetsSubmenu.qml"

      # end4 defaults to KDE's Bluetooth KCM, which is not part of this
      # Hyprland installation. Use the installed Blueman manager instead.
      sed -i \
        's|property string bluetooth: "kcmshell6 kcm_bluetooth"|property string bluetooth: "blueman-manager"|' \
        "$config_root/quickshell.end4-new/end4-pC/modules/common/Config.qml"

      # Install the custom lock-screen visual layer while leaving the upstream
      # PAM context and password controls untouched.
      cp ${end4LockVisual} \
        "$config_root/quickshell.end4-new/end4-pC/modules/ii/lock/LockVisual.qml"
      sed -i '/    \/\/ Main toolbar: password box/i\    LockVisual {\n        anchors.fill: parent\n        z: -0.5\n    }\n' \
        "$config_root/quickshell.end4-new/end4-pC/modules/ii/lock/LockSurface.qml"
      sed -i 's/bottomMargin: 20/bottomMargin: 28/' \
        "$config_root/quickshell.end4-new/end4-pC/modules/ii/lock/LockSurface.qml"
      cp ${end4Variables} "$config_root/hypr.end4-new/custom/variables.lua"
      cp ${end4Execs} "$config_root/hypr.end4-new/custom/execs.lua"
      cp ${end4Keybinds} "$config_root/hypr.end4-new/custom/keybinds.lua"
      cp ${end4Rules} "$config_root/hypr.end4-new/custom/rules.lua"

      if [[ -e "$config_root/hypr" ]]; then
        mv "$config_root/hypr" "$backup_dir/hypr.pre-switch"
      fi
      if [[ -e "$config_root/quickshell" ]]; then
        mv "$config_root/quickshell" "$backup_dir/quickshell.pre-switch"
      fi
      mv "$config_root/hypr.end4-new" "$config_root/hypr"
      mv "$config_root/quickshell.end4-new" "$config_root/quickshell"

      ln -sfn "$backup_dir" "$state_root/current-backup"
      printf '%s\n' "$backup_dir" > "$state_root/last-install"

      echo "end4 configuration installed."
      echo "Backup: $backup_dir"
      echo "Rollback: end4-rollback"
    '';
  };

  end4Rollback = pkgs.writeShellApplication {
    name = "end4-rollback";
    runtimeInputs = with pkgs; [ coreutils gnutar gzip procps ];
    text = ''
      set -euo pipefail

      if [[ "$(id -u)" -eq 0 ]]; then
        echo "Run end4-rollback as the desktop user, not as root." >&2
        exit 1
      fi

      config_root="''${XDG_CONFIG_HOME:-$HOME/.config}"
      state_root="''${XDG_STATE_HOME:-$HOME/.local/state}/end4-nixos"
      backup_dir="$(readlink -f "$state_root/current-backup" 2>/dev/null || true)"

      if [[ -z "$backup_dir" || ! -d "$backup_dir" ]]; then
        echo "No end4 backup was found; refusing to change your config." >&2
        exit 1
      fi

      pkill -x qs 2>/dev/null || true
      pkill -x quickshell 2>/dev/null || true

      for target in hypr quickshell; do
        if [[ -e "$config_root/$target" ]]; then
          chmod -R u+w "$config_root/$target"
        fi
        rm -rf "''${config_root:?}/$target"
        if [[ -f "$backup_dir/$target.tar.gz" ]]; then
          tar -C "$config_root" -xzf "$backup_dir/$target.tar.gz"
        fi
      done

      rm -f "$state_root/current-backup"
      echo "Restored configuration from $backup_dir"
      echo "Select GNOME at GDM, then roll back the NixOS generation if needed."
    '';
  };
in
{
  # Hyprland is an additional login session. GNOME and GDM intentionally stay
  # enabled, providing a known-good fallback from the login screen.
  programs.hyprland = {
    enable = true;
    package = hyprlandPackage;
    portalPackage = hyprlandPortal;
    withUWSM = false;
    xwayland.enable = true;
  };

  # Keep password authentication, but make Hyprland the preselected GDM
  # session. GNOME remains installed and selectable as the fallback.
  services.displayManager.defaultSession = "hyprland";

  xdg.portal = {
    enable = true;
    extraPortals = lib.mkAfter [ hyprlandPortal pkgs.xdg-desktop-portal-gtk ];
    config.hyprland = {
      default = [ "hyprland" "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    };
  };

  security.pam.services.hyprlock = { };
  security.polkit.enable = true;
  services.upower.enable = true;
  services.geoclue2.enable = true;
  services.udev.packages = [ pkgs.ddcutil ];

  # Hyprland does not process XDG autostart entries like GNOME does. Keep the
  # configured Bamboo/Unikey input method alive for every graphical session.
  systemd.user.services.fcitx5-daemon = {
    description = "Fcitx5 input method daemon";
    serviceConfig = {
      ExecStart = "${config.i18n.inputMethod.package}/bin/fcitx5 -D -r";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };

  boot.kernelModules = [ "i2c-dev" ];
  users.users.nvtank.extraGroups = [ "video" "input" "i2c" ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  environment.systemPackages = with pkgs; [
    hyprlandPackage
    hyprlandPortal
    end4Quickshell
    end4Setup
    end4Rollback
    end4Screenshot
    end4ScreenRecord

    bc
    brightnessctl
    cliphist
    ddcutil
    foot
    fuzzel
    gnome-keyring
    hypridle
    hyprlock
    hyprpicker
    hyprshot
    hyprsunset
    imagemagick
    libnotify
    libqalculate
    material-symbols
    matugen
    networkmanagerapplet
    nwg-displays
    pavucontrol
    playerctl
    procps
    slurp
    swappy
    tesseract
    upower
    wf-recorder
    wl-clipboard
    wlogout
    wtype
    ydotool
  ];

  fonts.packages = with pkgs; [
    material-symbols
    rubik
    twemoji-color-font
  ];
}
