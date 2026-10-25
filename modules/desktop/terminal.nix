{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    kitty
    kitty-themes
  ];

  # Kitty terminal config - translucent Catppuccin glass for Hyprland.
  environment.etc."xdg/kitty/kitty.conf".text = ''
    # ======================
    # Font
    # ======================
    font_family      JetBrainsMono Nerd Font
    bold_font        JetBrainsMono Nerd Font Bold
    italic_font      JetBrainsMono Nerd Font Italic
    bold_italic_font JetBrainsMono Nerd Font Bold Italic
    font_size        13.5
    font_features    JetBrainsMonoNF-Regular +liga +calt

    # ======================
    # Cursor
    # ======================
    cursor_shape               beam
    cursor_beam_thickness      1.8
    cursor_blink_interval      0.5
    cursor_stop_blinking_after 15.0

    # ======================
    # Scrollback
    # ======================
    scrollback_lines           10000
    scrollback_pager           less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER

    # ======================
    # Mouse
    # ======================
    mouse_hide_wait     3.0
    url_style           curly
    open_url_with       default
    url_prefixes        file ftp ftps http https mailto

    # ======================
    # Window
    # ======================
    window_padding_width        14
    window_margin_width         0
    single_window_margin_width  0
    placement_strategy          center
    confirm_os_window_close     0
    hide_window_decorations     yes
    resize_debounce_time        0.1

    # Background blur & transparency
    background_opacity          0.78
    background_blur             32
    dynamic_background_opacity  yes

    # ======================
    # Tab Bar
    # ======================
    tab_bar_style               powerline
    tab_powerline_style         slanted
    tab_bar_min_tabs            1
    tab_bar_edge                top
    tab_bar_margin_width        8.0
    tab_bar_margin_height       8.0 0.0
    tab_title_template          "  {fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{index}: {title}  "
    active_tab_font_style       bold
    inactive_tab_font_style     normal

    # ======================
    # Colors - Catppuccin Mocha
    # ======================
    foreground              #CDD6F4
    background              #11111B
    selection_foreground    #1E1E2E
    selection_background    #F5E0DC

    # Cursor
    cursor                  #F5E0DC
    cursor_text_color       #1E1E2E

    # URL underline color
    url_color               #F5E0DC

    # Border colors
    active_border_color     #B4BEFE
    inactive_border_color   #6C7086
    bell_border_color       #F9E2AF

    # Tab bar colors
    active_tab_foreground   #11111B
    active_tab_background   #CBA6F7
    inactive_tab_foreground #CDD6F4
    inactive_tab_background #313244
    tab_bar_background      #181825

    # Normal colors
    color0  #45475A
    color1  #F38BA8
    color2  #A6E3A1
    color3  #F9E2AF
    color4  #89B4FA
    color5  #F5C2E7
    color6  #94E2D5
    color7  #BAC2DE

    # Bright colors
    color8  #585B70
    color9  #F38BA8
    color10 #A6E3A1
    color11 #F9E2AF
    color12 #89B4FA
    color13 #F5C2E7
    color14 #94E2D5
    color15 #A6ADC8

    # ======================
    # Bell
    # ======================
    enable_audio_bell           no
    visual_bell_duration        0.0
    window_alert_on_bell        yes

    # ======================
    # Advanced
    # ======================
    shell_integration           enabled
    allow_hyperlinks            yes
    term                        xterm-kitty
    close_on_child_death        no

    # ======================
    # Keyboard shortcuts
    # ======================
    # Tabs
    map ctrl+t         new_tab_with_cwd
    map ctrl+w         close_tab
    map ctrl+tab       next_tab
    map ctrl+shift+tab previous_tab
    map ctrl+1         goto_tab 1
    map ctrl+2         goto_tab 2
    map ctrl+3         goto_tab 3
    map ctrl+4         goto_tab 4

    # Splits / Windows
    map ctrl+shift+enter new_window_with_cwd
    map ctrl+shift+w     close_window
    map ctrl+shift+]     next_window
    map ctrl+shift+[     previous_window

    # Font size
    map ctrl+equal  change_font_size all +1.0
    map ctrl+minus  change_font_size all -1.0
    map ctrl+0      change_font_size all 0

    # Misc
    map ctrl+shift+r  load_config_file
    map ctrl+shift+u  kitten unicode_input
  '';
}
