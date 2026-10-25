{ config, pkgs, ... }:

{
  # ======================
  # Shell packages
  # ======================
  environment.systemPackages = with pkgs; [
    # Core shell tools
    fzf
    zoxide
    eza
    bat
    fd
    ripgrep
    starship # Prompt
    fastfetch # System info

    # File manager với preview
    yazi # Terminal file manager (images, video, text preview)
    ueberzugpp # Image rendering backend cho yazi

    # History search
    atuin # Shell history sync + search (ctrl+r replacement)

    # Process monitor
    btop # Beautiful system monitor (htop replacement)

    # Git enhancements
    delta # Syntax-highlighting pager cho git diff
    lazygit # TUI git client

    # Markdown & docs
    glow # Render markdown đẹp trong terminal

    # Completion engine
    carapace # Multi-shell completion framework

    # Misc interactive tools
    choose # Human-friendly cut
    dust # du replacement, đẹp hơn
    duf # df replacement, đẹp hơn
    procs # ps replacement, đẹp hơn
    tokei # Code statistics
    hyperfine # Benchmarking tool
    tldr # Simplified man pages

    # Zsh plugins
    zsh-autopair
    zsh-fzf-tab
  ];

  # ======================
  # Zsh configuration
  # ======================
  programs.zsh = {
    enable = true;

    # Auto completion
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    # Init extra (chạy khi khởi động shell)
    interactiveShellInit = ''
      # ==========================================
      # CRITICAL: Load nhanh nhất có thể
      # ==========================================

      # Starship prompt - PHẢI load đầu tiên
      eval "$(starship init zsh)"

      # Zoxide - thay thế cd, load sớm
      eval "$(zoxide init zsh --cmd cd)"

      # ==========================================
      # COMPLETION: Async + cache để tăng tốc
      # ==========================================
      autoload -Uz compinit

      # Chỉ rebuild completion cache 1 lần/ngày
      if [[ -n ~/.cache/zcompdump(#qN.mh+24) ]]; then
        compinit -C -d ~/.cache/zcompdump
      else
        compinit -d ~/.cache/zcompdump
      fi

      # Completion styling
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      zstyle ':completion:*:descriptions' format '[%d]'
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}

      # ==========================================
      # ZSH PLUGINS
      # ==========================================
      source ${pkgs.zsh-autopair}/share/zsh/zsh-autopair/autopair.zsh
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

      # Fzf-tab preview
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --color=always $realpath'
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --color=always $realpath'

      # ==========================================
      # LAZY LOAD: Chỉ init khi dùng đến
      # ==========================================

      # Atuin: Lazy load khi nhấn Ctrl+R
      _atuin_init() {
        eval "$(atuin init zsh)"
        zle -N _atuin_search_widget atuin-search
      }

      atuin-search() {
        if ! type atuin-search-widget &>/dev/null; then
          _atuin_init
        fi
        zle atuin-search-widget
      }

      zle -N atuin-search
      bindkey '^r' atuin-search

      # FZF: Lazy load keybindings
      _fzf_init() {
        source ${pkgs.fzf}/share/fzf/key-bindings.zsh
        source ${pkgs.fzf}/share/fzf/completion.zsh
      }

      # Trigger FZF init khi dùng Ctrl+T hoặc Ctrl+F
      fzf-file-widget() {
        if ! type __fzf_select__ &>/dev/null; then
          _fzf_init
        fi
        zle fzf-file-widget
      }

      # Override FZF widgets với lazy version
      zle -N fzf-file-widget
      bindkey '^T' fzf-file-widget

      # Carapace: OPTIONAL - bỏ nếu không cần extra completions
      # export CARAPACE_BRIDGES='zsh,fish'
      # source <(carapace _carapace)

      # Yazi wrapper - cd khi thoát
      function y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }

      # FZF config
      export FZF_DEFAULT_COMMAND='fd --hidden --follow --exclude .git'
      export FZF_DEFAULT_OPTS="
        --height 60%
        --layout=reverse
        --border=rounded
        --padding=1
        --info=inline
        --prompt='  '
        --pointer='▶'
        --marker='✓'
        --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
        --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
        --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
        --bind='ctrl-/:toggle-preview'
        --bind='ctrl-y:execute-silent(echo -n {2..} | xclip -selection clipboard)'
      "
      export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers {}'"
      export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {}'"

      # Bat config
      export BAT_THEME="Catppuccin Mocha"
      export MANPAGER="sh -c 'col -bx | bat -l man -p'"

      # Delta config
      export GIT_PAGER="delta"

      # Fastfetch on login (chỉ 1 lần)
      if [[ -z "$TMUX" && "$TERM_PROGRAM" != "vscode" && -z "$FASTFETCH_RAN" ]]; then
        fastfetch
        export FASTFETCH_RAN=1
      fi
    '';

    # Aliases
    shellAliases = {
      # Replacements
      ls = "eza --icons=auto --group-directories-first";
      ll = "eza -la --icons=auto --group-directories-first --git";
      lt = "eza --tree --icons=auto --level=2";
      lta = "eza --tree --icons=auto --level=2 --all";
      cat = "bat --paging=never";
      grep = "rg";
      find = "fd";
      du = "dust";
      df = "duf";
      ps = "procs";
      top = "btop";
      htop = "btop";

      # Git
      g = "git";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
      gd = "git diff";
      glog = "git log --oneline --graph --all";
      lg = "lazygit";

      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # NixOS
      nrs = "workstation rebuild switch";
      nrt = "workstation rebuild test";
      nrb = "workstation rebuild boot";
      nfu = "workstation update inputs";
      ngc = "sudo nix-collect-garbage -d";
      nconf = "workstation edit";

      # Utils
      ff = "fastfetch";
      mk = "mkdir -p";
      cp = "cp -i";
      mv = "mv -i";
      rm = "rm -I";
      clr = "clear";
      hist = "atuin search";
      ppath = "echo $PATH | tr ':' '\\n'";
    };
  };

  # ======================
  # Atuin config
  # ======================
  environment.etc."atuin/config.toml".text = ''
    [atuin]
    style = "compact"
    filter_mode_shell_up_key_binding = "session"
    search_mode = "fuzzy"
    show_preview = true
    exit_mode = "return-query"
    keymap_mode = "auto"
    enter_accept = true
    sync_frequency = "10m"
  '';

  # ======================
  # Btop config - dùng home.file thay vì /etc
  # ======================
  # Catppuccin Mocha theme cho btop sẽ được đặt vào home trong shell init
  # Btop cần theme file tại ~/.config/btop/themes/catppuccin_mocha.theme
  environment.etc."btop/catppuccin_mocha.theme".text = ''
    # Catppuccin Mocha theme for btop
    # Based on https://github.com/catppuccin/btop

    theme[main_bg]="#1e1e2e"
    theme[main_fg]="#cdd6f4"
    theme[title]="#cdd6f4"
    theme[hi_fg]="#89b4fa"
    theme[selected_bg]="#313244"
    theme[selected_fg]="#cdd6f4"
    theme[inactive_fg]="#6c7086"
    theme[graph_text]="#f5e0dc"
    theme[meter_bg]="#313244"
    theme[proc_misc]="#cba6f7"
    theme[cpu_box]="#89b4fa"
    theme[mem_box]="#a6e3a1"
    theme[net_box]="#f38ba8"
    theme[proc_box]="#cba6f7"
    theme[div_line]="#6c7086"
    theme[temp_start]="#a6e3a1"
    theme[temp_end]="#f38ba8"
    theme[cpu_start]="#89b4fa"
    theme[cpu_end]="#cba6f7"
    theme[cpu_pressure_start]="#89b4fa"
    theme[cpu_pressure_end]="#cba6f7"
    theme[mem_start]="#a6e3a1"
    theme[mem_end]="#94e2d5"
    theme[mem_pressure_start]="#a6e3a1"
    theme[mem_pressure_end]="#94e2d5"
    theme[net_start]="#f9e2af"
    theme[net_end]="#fab387"
    theme[proc_start]="#cba6f7"
    theme[proc_end]="#f38ba8"
  '';

  # ======================
  # Starship prompt - Catppuccin style
  # ======================
  environment.etc."xdg/starship.toml".text = ''
    "$schema" = "https://starship.rs/config-schema.json"

    # ==========================================
    # PERFORMANCE: Tối ưu tốc độ render prompt
    # ==========================================
    command_timeout = 300  # Giảm từ 500ms xuống 300ms
    scan_timeout = 10      # Timeout scan files nhanh hơn

    format = """
    [](color_orange)\
    $os\
    $username\
    [](bg:color_yellow fg:color_orange)\
    $directory\
    [](fg:color_yellow bg:color_aqua)\
    $git_branch\
    $git_status\
    [](fg:color_aqua bg:color_blue)\
    $c\
    $rust\
    $golang\
    $nodejs\
    $php\
    $java\
    $kotlin\
    $haskell\
    $python\
    [](fg:color_blue bg:color_bg3)\
    $docker_context\
    $conda\
    [](fg:color_bg3 bg:color_bg1)\
    $time\
    [ ](fg:color_bg1)\
    $line_break$character"""

    palette = "catppuccin_mocha"

    [palettes.catppuccin_mocha]
    color_fg0     = "#CDD6F4"
    color_bg1     = "#1E1E2E"
    color_bg3     = "#313244"
    color_blue    = "#89B4FA"
    color_aqua    = "#94E2D5"
    color_green   = "#A6E3A1"
    color_orange  = "#FAB387"
    color_purple  = "#CBA6F7"
    color_red     = "#F38BA8"
    color_yellow  = "#F9E2AF"

    [os]
    disabled = false
    style = "bg:color_orange fg:color_bg1"

    [os.symbols]
    NixOS = "󱄅 "
    Linux = " "

    [username]
    show_always = true
    style_user = "bg:color_orange fg:color_bg1"
    style_root = "bg:color_orange fg:color_bg1"
    format = "[ $user ]($style)"

    [directory]
    style = "fg:color_bg1 bg:color_yellow"
    format = "[ $path ]($style)"
    truncation_length = 3
    truncation_symbol = "…/"

    [directory.substitutions]
    "Documents"  = "󰈙 "
    "Downloads"  = " "
    "Music"      = "󰝚 "
    "Pictures"   = " "
    "Developer"  = "󰲋 "

    [git_branch]
    symbol = ""
    style = "bg:color_aqua"
    format = "[[ $symbol $branch ](fg:color_bg1 bg:color_aqua)]($style)"

    [git_status]
    style = "bg:color_aqua"
    format = "[[($all_status$ahead_behind )](fg:color_bg1 bg:color_aqua)]($style)"
    # Tối ưu git status
    ahead = "⇡"
    behind = "⇣"
    diverged = "⇕"
    untracked = "?"
    stashed = "$"
    modified = "!"
    staged = "+"
    renamed = "»"
    deleted = "✘"

    [nodejs]
    symbol = ""
    style = "bg:color_blue"
    format = "[[ $symbol( $version) ](fg:color_bg1 bg:color_blue)]($style)"
    detect_files = ["package.json", "package-lock.json", "pnpm-lock.yaml"]
    detect_folders = []  # Không scan folders

    [c]
    symbol = " "
    style = "bg:color_blue"
    format = "[[ $symbol( $version) ](fg:color_bg1 bg:color_blue)]($style)"
    detect_extensions = ["c", "h"]
    detect_files = []
    detect_folders = []

    [rust]
    symbol = ""
    style = "bg:color_blue"
    format = "[[ $symbol( $version) ](fg:color_bg1 bg:color_blue)]($style)"
    detect_files = ["Cargo.toml"]
    detect_folders = []

    [golang]
    symbol = ""
    style = "bg:color_blue"
    format = "[[ $symbol( $version) ](fg:color_bg1 bg:color_blue)]($style)"
    detect_files = ["go.mod", "go.sum"]
    detect_folders = []

    [php]
    symbol = ""
    style = "bg:color_blue"
    format = "[[ $symbol( $version) ](fg:color_bg1 bg:color_blue)]($style)"
    detect_files = ["composer.json"]
    detect_folders = []

    [java]
    symbol = " "
    style = "bg:color_blue"
    format = "[[ $symbol( $version) ](fg:color_bg1 bg:color_blue)]($style)"
    detect_files = ["pom.xml", "build.gradle", "build.gradle.kts"]
    detect_folders = []

    [python]
    symbol = ""
    style = "bg:color_blue"
    format = "[[ $symbol( $version) ](fg:color_bg1 bg:color_blue)]($style)"
    detect_files = ["requirements.txt", "pyproject.toml", "Pipfile"]
    detect_folders = []

    [docker_context]
    symbol = ""
    style = "bg:color_bg3"
    format = "[[ $symbol( $context) ](fg:#83a598 bg:color_bg3)]($style)"
    only_with_files = true  # Chỉ hiện khi có Dockerfile

    [time]
    disabled = false
    time_format = "%R"
    style = "bg:color_bg1"
    format = "[[  $time ](fg:color_fg0 bg:color_bg1)]($style)"

    [line_break]
    disabled = false

    [character]
    disabled = false
    success_symbol = "[󰘍](bold fg:color_green)"
    error_symbol   = "[󰘍](bold fg:color_red)"
    vimcmd_symbol  = "[](bold fg:color_green)"
    vimcmd_replace_one_symbol = "[](bold fg:color_purple)"
    vimcmd_replace_symbol     = "[](bold fg:color_purple)"
    vimcmd_visual_symbol      = "[](bold fg:color_yellow)"
  '';

  # Đặt STARSHIP_CONFIG env
  environment.variables.STARSHIP_CONFIG = "/etc/xdg/starship.toml";

}
