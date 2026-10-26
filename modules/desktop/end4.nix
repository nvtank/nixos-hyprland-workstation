{
  config,
  workstationInputs,
  lib,
  pkgs,
  ...
}:

let
  inputs = workstationInputs;
  system = pkgs.stdenv.hostPlatform.system;
  desktopPackages = import ../../lib/hyprland-packages.nix { inherit lib pkgs workstationInputs; };
  hyprlandPackage = desktopPackages.hyprland;
  hyprlandPortal = desktopPackages.portal;
  quickshellPackage = inputs.quickshell.packages.${system}.default;
  end4Quickshell = pkgs.stdenv.mkDerivation {
    pname = "end4-quickshell";
    version = "0.2.1";
    dontUnpack = true;

    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.qt6.wrapQtAppsHook
    ];
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
  end4Variables = ../end4-variables.lua;
  end4Execs = ../end4-execs.lua;
  end4Keybinds = ../end4-keybinds.lua;
  end4Rules = ../end4-rules.lua;
  end4LockVisual = ../end4-lock-visual.qml;

  end4Screenshot = pkgs.writeShellApplication {
    name = "end4-screenshot";
    runtimeInputs = with pkgs; [
      coreutils
      hyprshot
      libnotify
      xdg-user-dirs
    ];
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
    runtimeInputs = [
      hyprlandPackage
    ]
    ++ (with pkgs; [
      coreutils
      jq
      libnotify
      procps
      slurp
      util-linux
      wf-recorder
      xdg-user-dirs
      xdg-utils
    ]);
    text = ''
      : "''${XDG_RUNTIME_DIR:?Run recording from a graphical session with XDG_RUNTIME_DIR}"
      umask 077
      state_dir="$XDG_RUNTIME_DIR/end4-screen-record"
      [[ ! -L "$state_dir" ]] || { echo "Unsafe recorder state symlink" >&2; exit 1; }
      pid_file="$state_dir/pid"
      output_file="$state_dir/output"
      mkdir -p "$state_dir"
      exec 9>"$state_dir/lock"
      flock --nonblock 9 || exit 0

      if [[ -s "$pid_file" ]]; then
        recorder_pid="$(<"$pid_file")"
        if [[ "$recorder_pid" =~ ^[0-9]+$ ]] &&
           [[ "$(readlink -f "/proc/$recorder_pid/exe" 2>/dev/null || true)" == "${pkgs.wf-recorder}/bin/wf-recorder" ]] &&
           kill -0 "$recorder_pid" 2>/dev/null; then
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
          wf-recorder --geometry "$geometry" --file "$saved_file" 9>&- >"$state_dir/recorder.log" 2>&1 &
          ;;
        output)
          monitor="$(hyprctl activeworkspace -j | jq -r '.monitor')"
          countdown
          wf-recorder --output "$monitor" --file "$saved_file" 9>&- >"$state_dir/recorder.log" 2>&1 &
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
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      gnused
      gnugrep
      rsync
      gnutar
      gzip
      util-linux
    ];
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

      umask 077
      config_root="''${XDG_CONFIG_HOME:-$HOME/.config}"
      state_root="''${XDG_STATE_HOME:-$HOME/.local/state}/end4-nixos"
      [[ "$config_root" = /* && "$config_root" != / && "$config_root" != "$HOME" ]] || { echo "Unsafe XDG_CONFIG_HOME" >&2; exit 1; }
      mkdir -p "$state_root"
      exec 8>"$state_root/lock"
      flock --nonblock 8 || { echo "Another end4 operation is running" >&2; exit 1; }
      for target in hypr quickshell; do
        [[ ! -L "$config_root/$target" ]] || { echo "Conflict: $config_root/$target is a symlink; manage it explicitly before setup." >&2; exit 1; }
        [[ ! -e "$config_root/$target" || -d "$config_root/$target" ]] || { echo "Conflict: $target is not a directory" >&2; exit 1; }
      done
      stamp="$(date -u +%Y%m%dT%H%M%S)-$$"
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

      staging_root="$(mktemp -d "$config_root/.end4-stage.XXXXXXXX")"
      committing=false
      completed=false
      cleanup() {
        status=$?
        if [[ "$status" != 0 ]]; then
          echo "end4-setup failed (status $status); restoring pre-switch trees if necessary. Backup: $backup_dir" >&2
        fi
        if [[ "$committing" == true && "$completed" != true ]]; then
          for target in hypr quickshell; do
            if [[ -d "$backup_dir/$target.pre-switch" ]]; then
              [[ ! -e "$config_root/$target" ]] || mv "$config_root/$target" "$staging_root/$target.failed"
              mv "$backup_dir/$target.pre-switch" "$config_root/$target"
            elif grep -qx "$target" "$backup_dir/absent" && [[ -e "$config_root/$target" ]]; then
              mv "$config_root/$target" "$staging_root/$target.failed"
            fi
          done
        fi
        rm -rf -- "$staging_root"
        exit "$status"
      }
      trap cleanup EXIT
      mkdir -p "$staging_root/hypr" "$staging_root/quickshell"

      rsync -a --no-owner --no-group ${inputs.illogical-impulse}/dots/.config/hypr/ "$staging_root/hypr/"
      chmod -R u+w "$staging_root/hypr"

      rsync -a --no-owner --no-group ${inputs.illogical-impulse}/dots/.config/quickshell/ "$staging_root/quickshell/"
      chmod -R u+w "$staging_root/quickshell"

      rsync -a --no-owner --no-group --exclude='.git' ${inputs.end4-pc}/ "$staging_root/quickshell/end4-pC/"
      chmod -R u+w "$staging_root/quickshell"

      # A crash/restart must not leave more than one shell instance creating
      # layer surfaces. Keep this patch next to the upstream config import so
      # future end4-setup runs retain the duplicate-instance guard.
      # shellcheck disable=SC2016 # $qsConfig belongs to the generated Lua.
      sed -i 's|hl.exec_cmd("qs -c $qsConfig")|hl.exec_cmd("qs --no-duplicate -c $qsConfig")|' \
        "$staging_root/hypr/hyprland/execs.lua"
      # shellcheck disable=SC2016 # $qsConfig belongs to the generated Lua.
      sed -i 's|killall ydotool qs quickshell; qs -c $qsConfig &|killall ydotool qs quickshell; qs --no-duplicate -c $qsConfig \&|' \
        "$staging_root/hypr/hyprland/keybinds.lua"

      # This pinned upstream ships an initially empty shellOverrides/main.lua.
      # Put defaults in the supported custom hook instead of searching for
      # a layout line generated only after the shell has run.
      cp ${../end4-general.lua} "$staging_root/hypr/custom/general.lua"

      # Keep the desktop widget picker visibly translucent. This submenu uses
      # its own opaque Material layer instead of the global panel background.
      sed -i \
        's|color: Appearance.colors.colUiBackground|color: Qt.rgba(Appearance.colors.colUiBackground.r, Appearance.colors.colUiBackground.g, Appearance.colors.colUiBackground.b, 0.14)|' \
        "$staging_root/quickshell/end4-pC/modules/common/widgets/WidgetsSubmenu.qml"

      # end4 defaults to KDE's Bluetooth KCM, which is not part of this
      # Hyprland installation. Use the installed Blueman manager instead.
      sed -i \
        's|property string bluetooth: "kcmshell6 kcm_bluetooth"|property string bluetooth: "blueman-manager"|' \
        "$staging_root/quickshell/end4-pC/modules/common/Config.qml"

      # Install the custom lock-screen visual layer while leaving the upstream
      # PAM context and password controls untouched.
      cp ${end4LockVisual} \
        "$staging_root/quickshell/end4-pC/modules/ii/lock/LockVisual.qml"
      sed -i '/    \/\/ Main toolbar: password box/i\    LockVisual {\n        anchors.fill: parent\n        z: -0.5\n    }\n' \
        "$staging_root/quickshell/end4-pC/modules/ii/lock/LockSurface.qml"
      sed -i 's/bottomMargin: 20/bottomMargin: 28/' \
        "$staging_root/quickshell/end4-pC/modules/ii/lock/LockSurface.qml"
      cp ${end4Variables} "$staging_root/hypr/custom/variables.lua"
      cp ${end4Execs} "$staging_root/hypr/custom/execs.lua"
      cp ${end4Keybinds} "$staging_root/hypr/custom/keybinds.lua"
      cp ${end4Rules} "$staging_root/hypr/custom/rules.lua"

      test -s "$staging_root/hypr/hyprland.lua"
      test -s "$staging_root/quickshell/end4-pC/shell.qml"
      committing=true
      if [[ -e "$config_root/hypr" ]]; then
        mv "$config_root/hypr" "$backup_dir/hypr.pre-switch"
      fi
      if [[ -e "$config_root/quickshell" ]]; then
        mv "$config_root/quickshell" "$backup_dir/quickshell.pre-switch"
      fi
      mv "$staging_root/hypr" "$config_root/hypr"
      mv "$staging_root/quickshell" "$config_root/quickshell"

      # Keep user-owned settings and documents intact; only create missing dirs.
      mkdir -p "$config_root/illogical-impulse" "''${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated/terminal"
      ln -sfn "$backup_dir" "$state_root/current-backup"
      printf '%s\n' "$backup_dir" > "$state_root/last-install"
      completed=true

      echo "end4 configuration installed."
      echo "Backup: $backup_dir"
      echo "Rollback: end4-rollback"
    '';
  };

  end4Rollback = pkgs.writeShellApplication {
    name = "end4-rollback";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      exec python3 ${../../scripts/end4-rollback.py} "$@"
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
  services.displayManager.defaultSession = lib.mkDefault "hyprland";

  xdg.portal = {
    enable = true;
    extraPortals = lib.mkAfter [
      hyprlandPortal
      pkgs.xdg-desktop-portal-gtk
    ];
    config.hyprland = {
      default = [
        "hyprland"
        "gtk"
      ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    };
  };

  security.pam.services.hyprlock = { };
  security.polkit.enable = true;
  services.upower.enable = lib.mkDefault true;
  services.geoclue2.enable = true;
  services.udev.packages = [ pkgs.ddcutil ];

  # Hyprland does not process XDG autostart entries like GNOME does. Keep the
  # configured Bamboo/Unikey input method alive for every graphical session.
  systemd.user.services.fcitx5-daemon =
    lib.mkIf (config.i18n.inputMethod.enable && config.i18n.inputMethod.type == "fcitx5")
      {
        description = "Fcitx5 input method daemon";
        serviceConfig = {
          ExecStart = "${config.i18n.inputMethod.package}/bin/fcitx5 -D -r";
          Restart = "on-failure";
          RestartSec = 1;
        };
      };

  boot.kernelModules = [ "i2c-dev" ];
  # Device access groups are an explicit host decision.
  # logind provides active-session device access on ordinary desktops.

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

    # Python is a desktop runtime dependency, not only a development tool.
    (lib.hiPrio (
      python3.withPackages (
        ps: with ps; [
          pip
          virtualenv
          pillow
          numpy
          opencv4
          click
          loguru
          tqdm
          pygobject3
        ]
      )
    ))
    bash
    curl
    ffmpeg
    git
    gnugrep
    gnused
    jq
    xdg-user-dirs
    xdg-utils
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
