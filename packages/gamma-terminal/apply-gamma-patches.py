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
