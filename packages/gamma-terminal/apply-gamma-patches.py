#!/usr/bin/env python3
"""Brand the pinned Sakura 3.8.6 source as Gamma Terminal without replacing its core."""
from pathlib import Path
import shutil
import sys

if len(sys.argv) != 2:
    raise SystemExit("Usage: apply-gamma-patches.py /path/to/sakura-source")

root = Path(sys.argv[1]).resolve()
if not (root / "src/sakura.c").is_file():
    raise SystemExit(f"Not a Sakura source tree: {root}")

def read(rel):
    return (root / rel).read_text(encoding="utf-8")

def write(rel, data):
    (root / rel).write_text(data, encoding="utf-8")

def once(data, old, new, label):
    count = data.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected one exact match, found {count}")
    return data.replace(old, new, 1)

def many(data, old, new, expected, label):
    count = data.count(old)
    if count != expected:
        raise SystemExit(f"{label}: expected {expected} matches, found {count}")
    return data.replace(old, new)

# Refuse to patch a different upstream version or changed source layout.
cmake = read("CMakeLists.txt")
if 'SET (VERSION "3.8.6")' not in cmake or "ADD_EXECUTABLE (sakura src/sakura.c)" not in cmake:
    raise SystemExit("Unexpected Sakura source version/build layout; refusing to patch.")

cmake = once(cmake, "PROJECT (sakura)", "PROJECT (gamma-terminal)", "CMake project")
cmake = once(cmake, 'SET (VERSION "3.8.6")', 'SET (VERSION "1.0.0")', "CMake version")
cmake = once(
    cmake,
    "ADD_EXECUTABLE (sakura src/sakura.c)",
    'ADD_EXECUTABLE (sakura src/sakura.c)\nSET_TARGET_PROPERTIES (sakura PROPERTIES OUTPUT_NAME "gamma-terminal")',
    "binary output name",
)
cmake = once(cmake, "INSTALL (FILES sakura.desktop DESTINATION share/applications)",
             "INSTALL (FILES gamma-terminal.desktop DESTINATION share/applications)", "desktop install")
cmake = once(cmake, "INSTALL (FILES terminal-tango.svg DESTINATION share/pixmaps)",
             "INSTALL (FILES gamma-terminal.svg DESTINATION share/pixmaps)", "icon install")
cmake = once(cmake, "INSTALL (FILES README.md DESTINATION share/doc/sakura)",
             "INSTALL (FILES README.md DESTINATION share/doc/gamma-terminal)", "README install")
cmake = once(cmake, "INSTALL (FILES " + "$" + "{sakura_BINARY_DIR}/sakura.1 DESTINATION share/man/man1)",
             "INSTALL (FILES " + "$" + "{PROJECT_BINARY_DIR}/gamma-terminal.1 DESTINATION share/man/man1)",
             "manual install")
cmake = cmake.replace("$" + "{sakura_SOURCE_DIR}", "$" + "{PROJECT_SOURCE_DIR}")
cmake = cmake.replace("$" + "{sakura_BINARY_DIR}", "$" + "{PROJECT_BINARY_DIR}")
cmake = many(cmake, "sakura.1", "gamma-terminal.1", 2, "manual output names")
cmake = many(cmake, "sakura.pod", "gamma-terminal.pod", 1, "manual source name")
cmake = many(cmake, "po/sakura.pot", "po/gamma-terminal.pot", 2, "gettext template cleanup references")
write("CMakeLists.txt", cmake)

po = read("po/CMakeLists.txt")
po = once(po, "SET(catalogname sakura)", "SET(catalogname gamma-terminal)", "gettext catalog")
po = once(po, "-o sakura.pot", "-o gamma-terminal.pot", "gettext template output")
po = once(po, "--backup=none sakura.pot", "--backup=none gamma-terminal.pot", "gettext merge input")
write("po/CMakeLists.txt", po)

source = read("src/sakura.c")
source = once(source, '#define GETTEXT_PACKAGE "sakura"',
               '#define GETTEXT_PACKAGE "gamma-terminal"', "gettext domain")
source = once(source, '#define SAKURA_CSS ""', r'''#define SAKURA_CSS \
"window#gamma-terminal { background-color: #0b0614; color: #f5f3ff; }" \
"window#gamma-terminal headerbar { background-color: #141020; color: #f5f3ff; border-bottom: 1px solid #34224f; box-shadow: none; min-height: 42px; }" \
"window#gamma-terminal headerbar .title { color: #f5f3ff; font-weight: 700; }" \
"window#gamma-terminal headerbar .subtitle { color: #c4b5fd; font-size: 10px; }" \
"window#gamma-terminal headerbar button { background-color: #211832; color: #f5f3ff; border: 1px solid #34224f; border-radius: 6px; padding: 4px 8px; }" \
"window#gamma-terminal headerbar button:hover { background-color: #392354; border-color: #8b5cf6; }" \
"window#gamma-terminal notebook { background-color: #0b0614; border: 0; }" \
"window#gamma-terminal notebook > header { background-color: #141020; border: 0; border-bottom: 1px solid #34224f; padding: 4px 5px 0; }" \
"window#gamma-terminal notebook tab { background-color: #141020; color: #c4b5fd; border: 1px solid #34224f; border-bottom: 0; border-radius: 7px 7px 0 0; padding: 5px 8px; margin-right: 4px; }" \
"window#gamma-terminal notebook tab:checked { background-color: #2a223c; color: #f5f3ff; border-color: #69418a; border-bottom: 2px solid #8b5cf6; }" \
"window#gamma-terminal notebook tab button { color: #c4b5fd; background-color: transparent; border: 0; }" \
"window#gamma-terminal notebook tab button:hover { color: #ffffff; background-color: #57336f; }" \
"menu#gamma-terminal-menu { background-color: #141020; color: #f5f3ff; border: 1px solid #4a355c; }" \
"menu#gamma-terminal-menu menuitem:hover { background-color: #5b3281; color: #ffffff; }" \
"window#gamma-terminal scrollbar slider { background-color: #71459a; min-width: 7px; min-height: 7px; }" \
"window#gamma-terminal vte-terminal { padding: 8px; }"''', "Gamma Aurora CSS")

palette_anchor = 'const char *palettes_names[]= {"Solarized", "Tango", "Gruvbox","Nord","Xterm","Linux", "Rxvt", NULL};'
palette_defs = """const GdkRGBA gamma_aurora_palette[PALETTE_SIZE] = {
    {0.043137, 0.023529, 0.078431, 1}, /* deep black */
    {0.937255, 0.400000, 0.466667, 1}, /* red */
    {0.556863, 0.811765, 0.541176, 1}, /* green */
    {0.901961, 0.756863, 0.478431, 1}, /* amber */
    {0.513725, 0.662745, 0.929412, 1}, /* blue */
    {0.764706, 0.607843, 0.909804, 1}, /* purple */
    {0.490196, 0.839216, 0.815686, 1}, /* cyan */
    {0.960784, 0.952941, 1.000000, 1}, /* light text */
    {0.164706, 0.133333, 0.235294, 1}, /* raised black */
    {1.000000, 0.509804, 0.572549, 1},
    {0.658824, 0.901961, 0.627451, 1},
    {0.956863, 0.819608, 0.552941, 1},
    {0.607843, 0.737255, 1.000000, 1},
    {0.850980, 0.694118, 1.000000, 1},
    {0.568627, 0.898039, 0.874510, 1},
    {1.000000, 1.000000, 1.000000, 1}
};

"""
source = once(source, palette_anchor, palette_defs + palette_anchor, "Gamma Aurora palette definition")
source = once(
    source,
    palette_anchor,
    'const char *palettes_names[]= {"Solarized", "Tango", "Gruvbox","Nord","Xterm","Linux", "Rxvt", "Gamma Aurora", NULL};',
    "Gamma Aurora palette label",
)
source = once(
    source,
    'const GdkRGBA *palettes[] = {solarized_palette, tango_palette, gruvbox_palette, nord_palette, xterm_palette, linux_palette, rxvt_palette, NULL};',
    'const GdkRGBA *palettes[] = {solarized_palette, tango_palette, gruvbox_palette, nord_palette, xterm_palette, linux_palette, rxvt_palette, gamma_aurora_palette, NULL};',
    "palette registration",
)
source = once(source, '#define DEFAULT_PALETTE 1 /* Tango palette */',
               '#define DEFAULT_PALETTE 7 /* Gamma Aurora palette */', "default palette")
source = once(source, '{"White on black", {0, 0, 0, 1}, {1, 1, 1, 1}},',
               '{"Gamma Aurora", {0.043137, 0.023529, 0.078431, 1}, {0.960784, 0.952941, 1, 1}},',
               "default colour scheme")
source = once(source, '#define ICON_FILE "terminal-tango.svg"',
               '#define ICON_FILE "gamma-terminal.svg"', "icon file")
source = once(source, '#define DEFAULT_CONFIGFILE "sakura.conf"',
               '#define DEFAULT_CONFIGFILE "gamma-terminal.conf"', "config filename")
source = once(source, '#define DEFAULT_FONT "Ubuntu Mono,monospace 13"',
               '#define DEFAULT_FONT "Monospace 10"', "default font")
source = once(source, 'const char cfg_group[] = "sakura";',
               'const char cfg_group[] = "gamma-terminal";', "config group")
source = once(source, 'configdir = g_build_filename( g_get_user_config_dir(), "sakura", NULL );',
               'configdir = g_build_filename( g_get_user_config_dir(), "gamma-terminal", NULL );',
               "config directory")
source = once(source, '"rgb(192,192,192)"', '"#f5f3ff"', "default foreground")
source = once(source, '"rgba(0,0,0,1)"', '"#0b0614"', "default background")
source = once(source, '"rgb(255,255,255)"', '"#a78bfa"', "default cursor")
source = once(source, 'g_quark_from_static_string("sakura_term")',
               'g_quark_from_static_string("gamma_terminal_term")', "terminal data key")

search_cb = """static void
gamma_header_search_cb (GtkWidget *widget, void *data)
{
    (void)widget;
    (void)data;
    sakura_search_dialog();
}


static void
sakura_init()
{"""
source = once(source, "static void\nsakura_init()\n{", search_cb, "header search callback")
source = once(source, "char* configdir = NULL;\n\tint i;",
               "char* configdir = NULL;\n\tint i;\n\tGtkWidget *gamma_menu_button = NULL;",
               "header menu button variable")
old_window = """sakura.main_window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
	gtk_window_set_title(GTK_WINDOW(sakura.main_window), "sakura");"""
new_window = """sakura.main_window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
	gtk_widget_set_name(sakura.main_window, "gamma-terminal");
	gtk_window_set_title(GTK_WINDOW(sakura.main_window), "Gamma Terminal");

	/* Gamma header bar: actions reuse Sakura's existing callbacks and menu. */
	GtkWidget *gamma_header = gtk_header_bar_new();
	gtk_header_bar_set_show_close_button(GTK_HEADER_BAR(gamma_header), TRUE);
	gtk_header_bar_set_title(GTK_HEADER_BAR(gamma_header), "Gamma Terminal");
	gtk_header_bar_set_subtitle(GTK_HEADER_BAR(gamma_header), "Gamma Aurora · GTK/VTE");

	GtkWidget *gamma_new_tab_button = gtk_button_new_from_icon_name("tab-new-symbolic", GTK_ICON_SIZE_BUTTON);
	gtk_button_set_relief(GTK_BUTTON(gamma_new_tab_button), GTK_RELIEF_NONE);
	gtk_widget_set_tooltip_text(gamma_new_tab_button, "New tab");
	g_signal_connect(G_OBJECT(gamma_new_tab_button), "clicked", G_CALLBACK(sakura_new_tab_cb), NULL);
	gtk_header_bar_pack_start(GTK_HEADER_BAR(gamma_header), gamma_new_tab_button);

	GtkWidget *gamma_search_button = gtk_button_new_from_icon_name("edit-find-symbolic", GTK_ICON_SIZE_BUTTON);
	gtk_button_set_relief(GTK_BUTTON(gamma_search_button), GTK_RELIEF_NONE);
	gtk_widget_set_tooltip_text(gamma_search_button, "Search");
	g_signal_connect(G_OBJECT(gamma_search_button), "clicked", G_CALLBACK(gamma_header_search_cb), NULL);
	gtk_header_bar_pack_end(GTK_HEADER_BAR(gamma_header), gamma_search_button);

	GtkWidget *gamma_fullscreen_button = gtk_button_new_from_icon_name("view-fullscreen-symbolic", GTK_ICON_SIZE_BUTTON);
	gtk_button_set_relief(GTK_BUTTON(gamma_fullscreen_button), GTK_RELIEF_NONE);
	gtk_widget_set_tooltip_text(gamma_fullscreen_button, "Fullscreen");
	g_signal_connect(G_OBJECT(gamma_fullscreen_button), "clicked", G_CALLBACK(sakura_fullscreen_cb), NULL);
	gtk_header_bar_pack_end(GTK_HEADER_BAR(gamma_header), gamma_fullscreen_button);

	gamma_menu_button = gtk_menu_button_new();
	gtk_button_set_relief(GTK_BUTTON(gamma_menu_button), GTK_RELIEF_NONE);
	gtk_button_set_image(GTK_BUTTON(gamma_menu_button), gtk_image_new_from_icon_name("open-menu-symbolic", GTK_ICON_SIZE_BUTTON));
	gtk_widget_set_tooltip_text(gamma_menu_button, "Terminal menu");
	gtk_header_bar_pack_end(GTK_HEADER_BAR(gamma_header), gamma_menu_button);
	gtk_window_set_titlebar(GTK_WINDOW(sakura.main_window), gamma_header);"""
source = once(source, old_window, new_window, "Gamma header bar")
source = once(source, 'sakura.menu = gtk_menu_new();',
               'sakura.menu = gtk_menu_new();\n\tgtk_widget_set_name(sakura.menu, "gamma-terminal-menu");',
               "Gamma context menu CSS name")
source = once(source, "sakura_init_popup();",
               "sakura_init_popup();\n\tgtk_menu_button_set_popup(GTK_MENU_BUTTON(gamma_menu_button), sakura.menu);",
               "existing popup menu integration")
source = once(source, 'g_option_context_new (_("- vte-based terminal emulator"))',
               'g_option_context_new (_("- Gamma Terminal, a lightweight GTK/VTE terminal emulator"))',
               "CLI application description")
write("src/sakura.c", source)

desktop = read("sakura.desktop")
desktop = once(desktop, "Name=Sakura", "Name=Gamma Terminal", "desktop name")
desktop = once(desktop, "GenericName=Terminal", "GenericName=Terminal Emulator", "desktop generic name")
desktop = once(desktop, "TryExec=sakura", "TryExec=gamma-terminal", "desktop TryExec")
desktop = once(desktop, "Exec=sakura", "Exec=gamma-terminal", "desktop Exec")
desktop = once(desktop, "Icon=terminal-tango", "Icon=gamma-terminal", "desktop icon")
desktop = once(desktop, "X-Ubuntu-Gettext-Domain=sakura",
               "X-Ubuntu-Gettext-Domain=gamma-terminal", "desktop gettext domain")
desktop = once(desktop, "Comment=Use the command line",
               "Comment=Lightweight GTK/VTE terminal for Gamma Linux", "desktop comment")
desktop += "\nStartupWMClass=gamma-terminal\n"
write("gamma-terminal.desktop", desktop)
(root / "sakura.desktop").unlink()

pod = read("sakura.pod")
pod = once(pod, "sakura - A simple but powerful libvte-based terminal emulator.",
           "gamma-terminal - A lightweight GTK/VTE terminal for Gamma Linux.", "manual title")
pod = once(pod, "sakura [options...]", "gamma-terminal [options...]", "manual synopsis")
pod = once(pod, "sakura is a terminal emulator based on GTK+ and VTE.",
           "Gamma Terminal is a terminal emulator based on GTK+ and VTE, forked from Sakura 3.8.6.",
           "manual description")
pod = once(pod, "relative to the sakura config dir.",
           "relative to the Gamma Terminal config directory.", "manual config description")
pod = once(pod, "~/.config/sakura/FILENAME",
           "~/.config/gamma-terminal/FILENAME", "manual config path")
write("gamma-terminal.pod", pod)
(root / "sakura.pod").unlink()

(root / "terminal-tango.svg").unlink(missing_ok=True)
assets = Path(__file__).resolve().parent / "assets"
shutil.copy2(assets / "gamma-terminal.svg", root / "gamma-terminal.svg")
shutil.copy2(Path(__file__).resolve().parent / "README.md", root / "README.md")

print("Gamma Terminal branding patches applied to pinned Sakura 3.8.6.")
print("Sakura GTK/VTE core, PTY lifecycle, tabs, search, URL matching and CLI remain the engine.")




# Gamma Terminal Controls panel.
# This is GTK3-only and deliberately reuses Sakura's existing callbacks.
source = read("src/sakura.c")

gamma_controls_code = r"""
static GtkWidget *
gamma_controls_add_button (GtkWidget *panel, const gchar *label,
                           const gchar *icon_name, GCallback callback)
{
    GtkWidget *button = gtk_button_new();
    GtkWidget *row = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 8);
    GtkWidget *image = gtk_image_new_from_icon_name(icon_name, GTK_ICON_SIZE_BUTTON);
    GtkWidget *text = gtk_label_new(label);

    gtk_widget_set_halign(text, GTK_ALIGN_START);
    gtk_widget_set_hexpand(text, TRUE);
    gtk_box_pack_start(GTK_BOX(row), image, FALSE, FALSE, 0);
    gtk_box_pack_start(GTK_BOX(row), text, TRUE, TRUE, 0);
    gtk_container_add(GTK_CONTAINER(button), row);
    gtk_widget_set_name(button, "gamma-control-button");
    gtk_widget_set_size_request(button, -1, 34);
    if (callback != NULL)
        g_signal_connect(button, "clicked", callback, NULL);
    gtk_box_pack_start(GTK_BOX(panel), button, FALSE, FALSE, 0);
    return button;
}

static void
gamma_controls_settings_cb (GtkWidget *widget, gpointer data)
{
    gtk_menu_popup_at_widget(GTK_MENU(sakura.menu), widget,
                             GDK_GRAVITY_SOUTH_WEST,
                             GDK_GRAVITY_NORTH_WEST, NULL);
}

static void
gamma_controls_about_cb (GtkWidget *widget, gpointer data)
{
    gtk_show_about_dialog(GTK_WINDOW(sakura.main_window),
                          "program-name", "Gamma Terminal",
                          "version", VERSION,
                          "comments", "Sakura-powered GTK/VTE terminal for Gamma Linux.",
                          "website", "https://gamma-linux.is-local.org/",
                          "logo-icon-name", "utilities-terminal",
                          NULL);
}

static void
gamma_controls_build (GtkWidget *panel)
{
    GtkWidget *heading = gtk_label_new(NULL);
    GtkWidget *grouped_input;
    GtkCssProvider *provider = gtk_css_provider_new();
    GdkScreen *screen = gtk_widget_get_screen(panel);

    gtk_css_provider_load_from_data(provider,
        "#gamma-controls { background-color: #151020; border-left: 1px solid #34224f; padding: 8px; }"
        "button#gamma-control-button { background-image: none; background-color: #211832; color: #f5f3ff; border: 1px solid #34224f; border-radius: 6px; padding: 3px 7px; }"
        "button#gamma-control-button:hover { background-color: #392354; border-color: #8b5cf6; }"
        "button#gamma-control-button:disabled { color: #71667e; background-color: #191421; border-color: #292033; }",
        -1, NULL);
    gtk_style_context_add_provider_for_screen(screen,
        GTK_STYLE_PROVIDER(provider), GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    g_object_unref(provider);

    gtk_label_set_markup(GTK_LABEL(heading), "<b>Controls</b>");
    gtk_widget_set_halign(heading, GTK_ALIGN_START);
    gtk_box_pack_start(GTK_BOX(panel), heading, FALSE, FALSE, 4);

    gamma_controls_add_button(panel, "New", "tab-new-symbolic",
                              G_CALLBACK(sakura_new_tab_cb));

    /* Split actions become active when the multi-PTY pane model is integrated.
       Keep them visible but disabled rather than pretending they work. */
    GtkWidget *split_v = gamma_controls_add_button(panel, "Split V",
        "view-grid-symbolic", NULL);
    GtkWidget *split_h = gamma_controls_add_button(panel, "Split H",
        "view-dual-symbolic", NULL);
    gtk_widget_set_sensitive(split_v, FALSE);
    gtk_widget_set_sensitive(split_h, FALSE);
    gtk_widget_set_tooltip_text(split_v, "Split panes are not implemented yet.");
    gtk_widget_set_tooltip_text(split_h, "Split panes are not implemented yet.");

    GtkWidget *miniview = gamma_controls_add_button(panel, "Miniview",
        "zoom-fit-best-symbolic", NULL);
    gtk_widget_set_sensitive(miniview, FALSE);
    gtk_widget_set_tooltip_text(miniview, "Terminal miniview is not implemented yet.");

    gamma_controls_add_button(panel, "Set title", "document-edit-symbolic",
                              G_CALLBACK(sakura_set_name_dialog_cb));

    grouped_input = gtk_check_button_new_with_label("Grouped input");
    gtk_widget_set_halign(grouped_input, GTK_ALIGN_START);
    gtk_widget_set_sensitive(grouped_input, FALSE);
    gtk_widget_set_tooltip_text(grouped_input,
        "Broadcast input will be added with multi-pane support.");
    gtk_box_pack_start(GTK_BOX(panel), grouped_input, FALSE, FALSE, 4);

    GtkWidget *separator = gtk_separator_new(GTK_ORIENTATION_HORIZONTAL);
    gtk_box_pack_start(GTK_BOX(panel), separator, FALSE, FALSE, 5);

    gamma_controls_add_button(panel, "Copy", "edit-copy-symbolic",
                              G_CALLBACK(sakura_copy_cb));
    gamma_controls_add_button(panel, "Paste", "edit-paste-symbolic",
                              G_CALLBACK(sakura_paste_cb));
    gamma_controls_add_button(panel, "Settings", "preferences-system-symbolic",
                              G_CALLBACK(gamma_controls_settings_cb));
    gamma_controls_add_button(panel, "About", "help-about-symbolic",
                              G_CALLBACK(gamma_controls_about_cb));

    separator = gtk_separator_new(GTK_ORIENTATION_HORIZONTAL);
    gtk_box_pack_start(GTK_BOX(panel), separator, FALSE, FALSE, 5);

    gamma_controls_add_button(panel, "Close Terminal", "window-close-symbolic",
                              G_CALLBACK(sakura_close_tab_cb));
}
"""

source = once(source, "static void     sakura_init_popup ();",
               "static void     sakura_init_popup ();\nstatic void     gamma_controls_build (GtkWidget *panel);",
               "Gamma Controls forward declaration")

source = once(source, """static void
sakura_init_popup()
{""", gamma_controls_code + """
static void
sakura_init_popup()
{""", "Gamma Controls callbacks and panel builder")

source = once(
    source,
    "\tgtk_container_add(GTK_CONTAINER(sakura.main_window), sakura.notebook);",
    """\tGtkWidget *gamma_root = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
\tGtkWidget *gamma_controls = gtk_box_new(GTK_ORIENTATION_VERTICAL, 6);
\tgtk_widget_set_name(gamma_controls, "gamma-controls");
\tgtk_widget_set_size_request(gamma_controls, 164, -1);
\tgtk_widget_set_margin_start(gamma_controls, 8);
\tgtk_widget_set_margin_end(gamma_controls, 8);
\tgtk_widget_set_margin_top(gamma_controls, 8);
\tgtk_widget_set_margin_bottom(gamma_controls, 8);
\tgtk_widget_set_hexpand(sakura.notebook, TRUE);
\tgtk_widget_set_vexpand(sakura.notebook, TRUE);
\tgtk_box_pack_start(GTK_BOX(gamma_root), sakura.notebook, TRUE, TRUE, 0);
\tgtk_box_pack_end(GTK_BOX(gamma_root), gamma_controls, FALSE, FALSE, 0);
\tgtk_container_add(GTK_CONTAINER(sakura.main_window), gamma_root);""",
    "Gamma root layout and right controls panel"
)

source = once(source, "\tsakura_init_popup();",
               "\tsakura_init_popup();\n\tgamma_controls_build(gamma_controls);",
               "Build Gamma Controls after Sakura menu initialization")

source = once(
    source,
    "gtk_window_resize(GTK_WINDOW(sakura.main_window), sakura.width, sakura.height);",
    "/* Keep the terminal's configured column count after adding the 180px controls rail. */\n\t sakura.width += 180;\n\t gtk_window_resize(GTK_WINDOW(sakura.main_window), sakura.width, sakura.height);",
    "Reserve width for the Gamma Controls rail"
)
write("src/sakura.c", source)

print("Gamma Controls panel integrated using existing GTK3/VTE dependencies.")
print("Split panes, miniview and grouped input remain visibly disabled until their engine is implemented.")
