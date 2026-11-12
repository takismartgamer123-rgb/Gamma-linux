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
               "static void     sakura_init_popup ();\nstatic void     gamma_controls_build (GtkWidget *panel);\n"
               "static void     gamma_split_v_cb (GtkWidget *, void *);\n"
               "static void     gamma_split_h_cb (GtkWidget *, void *);\n"
               "static void     gamma_miniview_cb (GtkWidget *, void *);\n"
               "static void     gamma_grouped_input_toggled (GtkToggleButton *, gpointer);",
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


# Functional two-pane workspace, using only the existing GTK3 + VTE stack.
source = read("src/sakura.c")

source = once(
    source,
    "\tgulong exit_handler_id;\n};",
    "\tgulong exit_handler_id;\n"
    "\tGtkWidget *pane_root;\n"
    "\tGtkWidget *vte2;\n"
    "\tGtkWidget *scrollbar2;\n"
    "\tGPid pid2;\n"
    "\tgulong exit_handler_id2;\n"
    "\tGtkWidget *active_vte;\n"
    "\tbool grouped_input;\n};\n\n"
    "struct gamma_exited_pane {\n"
    "\tstruct sakura_tab *tab;\n"
    "\tGtkWidget *terminal;\n"
    "};",
    "two-pane state in sakura_tab"
)

source = once(
    source,
    "static GQuark term_data_id = 0;",
    "static GQuark term_data_id = 0;\n"
    "static GtkWidget *gamma_grouped_input_widget = NULL;\n"
    "static GtkWidget *gamma_split_v_widget = NULL;\n"
    "static GtkWidget *gamma_split_h_widget = NULL;",
    "Gamma Controls widget state"
)

source = once(
    source,
    "static void     sakura_show_scrollbar (void);",
    "static void     sakura_show_scrollbar (void);\n"
    "static void     gamma_controls_update (struct sakura_tab *);\n"
    "static gboolean gamma_child_exit_cleanup (gpointer);",
    "Gamma pane helper declarations"
)

# Use the focused VTE when resolving terminal tab ownership.
source = once(
    source,
    "if ((VteTerminal *)sk_tab->vte == vte_term) {",
    "if ((VteTerminal *)sk_tab->vte == vte_term || (VteTerminal *)sk_tab->vte2 == vte_term) {",
    "find either terminal pane"
)

# Apply fonts and colour schemes to both panes.
source = once(
    source,
    "vte_terminal_set_font(VTE_TERMINAL(sk_tab->vte), sakura.font);",
    "vte_terminal_set_font(VTE_TERMINAL(sk_tab->vte), sakura.font);\n"
    "\t\tif (sk_tab->vte2)\n"
    "\t\t\tvte_terminal_set_font(VTE_TERMINAL(sk_tab->vte2), sakura.font);",
    "font update for split pane"
)
source = once(
    source,
    "vte_terminal_set_bold_is_bright(VTE_TERMINAL(sk_tab->vte), sakura.bold_is_bright);",
    "vte_terminal_set_bold_is_bright(VTE_TERMINAL(sk_tab->vte), sakura.bold_is_bright);\n"
    "\t\tif (sk_tab->vte2) {\n"
    "\t\t\tvte_terminal_set_colors(VTE_TERMINAL(sk_tab->vte2), &sakura.forecolors[sk_tab->colorset], &sakura.backcolors[sk_tab->colorset], sakura.palette, PALETTE_SIZE);\n"
    "\t\t\tvte_terminal_set_color_cursor(VTE_TERMINAL(sk_tab->vte2), &sakura.curscolors[sk_tab->colorset]);\n"
    "\t\t\tvte_terminal_set_color_cursor_foreground(VTE_TERMINAL(sk_tab->vte2), &sakura.backcolors[sk_tab->colorset]);\n"
    "\t\t\tvte_terminal_set_bold_is_bright(VTE_TERMINAL(sk_tab->vte2), sakura.bold_is_bright);\n"
    "\t\t}",
    "colour update for split pane"
)

# Copy, paste and search act on the focused pane. Grouped paste writes to both.
source = once(
    source,
    "if (vte_terminal_get_has_selection(VTE_TERMINAL(sk_tab->vte))) {\n"
    "\t\tvte_terminal_copy_clipboard_format(VTE_TERMINAL(sk_tab->vte), VTE_FORMAT_TEXT);\n"
    "\t}",
    "VteTerminal *target = VTE_TERMINAL(sk_tab->active_vte ? sk_tab->active_vte : sk_tab->vte);\n"
    "\tif (vte_terminal_get_has_selection(target)) {\n"
    "\t\tvte_terminal_copy_clipboard_format(target, VTE_FORMAT_TEXT);\n"
    "\t}",
    "copy from focused pane"
)
source = once(
    source,
    "vte_terminal_paste_clipboard(VTE_TERMINAL(sk_tab->vte));",
    "VteTerminal *target = VTE_TERMINAL(sk_tab->active_vte ? sk_tab->active_vte : sk_tab->vte);\n"
    "\tvte_terminal_paste_clipboard(target);\n"
    "\tif (sk_tab->grouped_input && sk_tab->vte2)\n"
    "\t\tvte_terminal_paste_clipboard(VTE_TERMINAL(target == VTE_TERMINAL(sk_tab->vte) ? sk_tab->vte2 : sk_tab->vte));",
    "paste to focused and peer pane"
)
source = once(
    source,
    "vte_terminal_search_set_wrap_around(VTE_TERMINAL(sk_tab->vte), TRUE);",
    "VteTerminal *target = VTE_TERMINAL(sk_tab->active_vte ? sk_tab->active_vte : sk_tab->vte);\n"
    "\tvte_terminal_search_set_wrap_around(target, TRUE);",
    "search focused pane"
)
source = once(
    source,
    "vte_terminal_search_set_regex(VTE_TERMINAL(sk_tab->vte), regex, 0);",
    "vte_terminal_search_set_regex(target, regex, 0);",
    "search regex in focused pane"
)
source = once(
    source,
    "if (!vte_terminal_search_find_next(VTE_TERMINAL(sk_tab->vte))) {\n"
    "\t\t\tvte_terminal_unselect_all(VTE_TERMINAL(sk_tab->vte));\n"
    "\t\t\tvte_terminal_search_find_next(VTE_TERMINAL(sk_tab->vte));",
    "if (!vte_terminal_search_find_next(target)) {\n"
    "\t\t\tvte_terminal_unselect_all(target);\n"
    "\t\t\tvte_terminal_search_find_next(target);",
    "search next in focused pane"
)

# Preserve scrollbar preferences in the secondary terminal.
source = once(
    source,
    "if (!sakura.show_scrollbar)\n"
    "\t\t\tgtk_widget_hide(sk_tab->scrollbar);\n"
    "\t\telse\n"
    "\t\t\tgtk_widget_show(sk_tab->scrollbar);",
    "if (!sakura.show_scrollbar)\n"
    "\t\t\tgtk_widget_hide(sk_tab->scrollbar);\n"
    "\t\telse\n"
    "\t\t\tgtk_widget_show(sk_tab->scrollbar);\n"
    "\t\tif (sk_tab->scrollbar2) {\n"
    "\t\t\tif (!sakura.show_scrollbar) gtk_widget_hide(sk_tab->scrollbar2);\n"
    "\t\t\telse gtk_widget_show(sk_tab->scrollbar2);\n"
    "\t\t}",
    "scrollbar preference for secondary pane"
)

# Window/tab title follows the pane that emitted the title change.
source = once(
    source,
    "tabtitle = vte_terminal_get_window_title(VTE_TERMINAL(sk_tab->vte));",
    "tabtitle = vte_terminal_get_window_title(VTE_TERMINAL(widget));",
    "title from emitting pane"
)

# Track active pane whenever notebook tabs change.
source = once(
    source,
    "if (!sakura.main_title) {\n"
    "\t\tif (g_strcmp0(gtk_label_get_text(GTK_LABEL(sk_tab->label)),\"\")!=0) {",
    "gamma_controls_update(sk_tab);\n"
    "\tif (!sakura.main_title) {\n"
    "\t\tif (g_strcmp0(gtk_label_get_text(GTK_LABEL(sk_tab->label)),\"\")!=0) {",
    "refresh Controls on tab switch"
)

# CWD inheritance follows the focused pane's shell process.
source = once(
    source,
    "if (sk_tab->pid >= 0) {\n"
    "\t\tchar *file, *buf;",
    "GPid cwd_pid = (sk_tab->active_vte == sk_tab->vte2 && sk_tab->pid2 > 0) ? sk_tab->pid2 : sk_tab->pid;\n"
    "\tif (cwd_pid > 0) {\n"
    "\t\tchar *file, *buf;",
    "cwd from active pane"
)
source = once(
    source,
    'file = g_strdup_printf ("/proc/%d/cwd", sk_tab->pid);',
    'file = g_strdup_printf ("/proc/%d/cwd", cwd_pid);',
    "active pane cwd PID"
)

# The main process-exit handler now finds the owning notebook page by VTE,
# then schedules pane collapse after the VTE signal has returned.
source = once(
    source,
    """static void
sakura_child_exited_cb (GtkWidget *widget, void *data)
{
\tgint page, npages;
\tstruct sakura_tab *sk_tab;

\tpage = gtk_notebook_page_num(GTK_NOTEBOOK(sakura.notebook),
\t\t\t\tgtk_widget_get_parent(widget));
\tnpages = gtk_notebook_get_n_pages(GTK_NOTEBOOK(sakura.notebook));
\tsk_tab = sakura_get_sktab(sakura, page);

\t/* Only write configuration to disk if it's the last tab */
\tif (npages==1) {
\t\tsakura_config_done();
\t}

\tif (option_hold==TRUE) {
\t\tSAY("hold option has been activated");
\t\treturn;
\t}

\t/* Child should be automatically reaped because we don't use G_SPAWN_DO_NOT_REAP_CHILD flag */
\tg_spawn_close_pid(sk_tab->pid);

\tsakura_del_tab(page);

\tnpages = gtk_notebook_get_n_pages(GTK_NOTEBOOK(sakura.notebook));
\tif (npages == 0)
\t\tsakura_destroy();
}""",
    """static void
sakura_child_exited_cb (GtkWidget *widget, void *data)
{
\tgint page, npages;
\tstruct sakura_tab *sk_tab;

\tpage = sakura_find_tab(VTE_TERMINAL(widget));
\tif (page < 0) return;
\tnpages = gtk_notebook_get_n_pages(GTK_NOTEBOOK(sakura.notebook));
\tsk_tab = sakura_get_sktab(sakura, page);

\tif (npages == 1) sakura_config_done();
\tif (option_hold == TRUE) {
\t\tSAY("hold option has been activated");
\t\treturn;
\t}

\tif (sk_tab->pane_root && (widget == sk_tab->vte || widget == sk_tab->vte2)) {
\t\tstruct gamma_exited_pane *pending = g_new0(struct gamma_exited_pane, 1);
\t\tpending->tab = sk_tab;
\t\tpending->terminal = widget;
\t\tg_idle_add(gamma_child_exit_cleanup, pending);
\t\treturn;
\t}

\tg_spawn_close_pid(sk_tab->pid);
\tsakura_del_tab(page);
\tnpages = gtk_notebook_get_n_pages(GTK_NOTEBOOK(sakura.notebook));
\tif (npages == 0) sakura_destroy();
}""",
    "two-pane child-exit lifecycle"
)

# Ask before closing if either pane is running a foreground process.
source = once(
    source,
    "if ( (pgid != -1) && (pgid != sk_tab->pid) && (!sakura.less_questions) ) {",
    "pid_t pgid2 = -1;\n"
    "\tif (sk_tab->vte2)\n"
    "\t\tpgid2 = tcgetpgrp(vte_pty_get_fd(vte_terminal_get_pty(VTE_TERMINAL(sk_tab->vte2))));\n"
    "\tif ((((pgid != -1) && (pgid != sk_tab->pid)) || ((pgid2 != -1) && (pgid2 != sk_tab->pid2))) && (!sakura.less_questions)) {",
    "close-tab foreground process check"
)
source = once(
    source,
    "\t\tif (response==GTK_RESPONSE_YES)\n"
    "\t\t\tsakura_del_tab(page);\n"
    "\n"
    "\t} else /* No processes */\n"
    "\t\tsakura_del_tab(page);",
    "\t\tif (response==GTK_RESPONSE_YES)\n"
    "\t\t\tsakura_del_tab(page);\n"
    "\t} else /* No foreground processes or confirmations disabled */\n"
    "\t\tsakura_del_tab(page);",
    "close-tab confirmation for both panes"
)

# Disconnect and release the second pane with the notebook tab.
source = once(
    source,
    "\tg_signal_handler_disconnect (sk_tab->vte, sk_tab->exit_handler_id);\n"
    "\tgtk_notebook_remove_page(GTK_NOTEBOOK(sakura.notebook), page);",
    "\tg_signal_handler_disconnect (sk_tab->vte, sk_tab->exit_handler_id);\n"
    "\tif (sk_tab->vte2) {\n"
    "\t\tif (sk_tab->exit_handler_id2)\n"
    "\t\t\tg_signal_handler_disconnect(sk_tab->vte2, sk_tab->exit_handler_id2);\n"
    "\t\tif (sk_tab->pid2 > 0) g_spawn_close_pid(sk_tab->pid2);\n"
    "\t}\n"
    "\tgtk_notebook_remove_page(GTK_NOTEBOOK(sakura.notebook), page);",
    "cleanup second pane on tab removal"
)

# Primary pane setup remembers focus and exposes grouped-input hooks.
source = once(
    source,
    "sk_tab->vte = vte_terminal_new();\n"
    "\tsk_tab->scrollbar = gtk_scrollbar_new",
    "sk_tab->vte = vte_terminal_new();\n"
    "\tsk_tab->active_vte = sk_tab->vte;\n"
    "\tsk_tab->scrollbar = gtk_scrollbar_new",
    "initial active VTE"
)
source = once(
    source,
    'g_signal_connect(G_OBJECT(sk_tab->vte), "window-title-changed", G_CALLBACK(sakura_title_changed_cb), NULL);',
    'g_signal_connect(G_OBJECT(sk_tab->vte), "window-title-changed", G_CALLBACK(sakura_title_changed_cb), NULL);\n'
    '\tg_signal_connect(G_OBJECT(sk_tab->vte), "focus-in-event", G_CALLBACK(gamma_pane_focus_cb), sk_tab);\n'
    '\tg_signal_connect(G_OBJECT(sk_tab->vte), "commit", G_CALLBACK(gamma_grouped_commit_cb), sk_tab);\n'
    '\tg_signal_connect(G_OBJECT(sk_tab->vte), "key-press-event", G_CALLBACK(gamma_grouped_key_cb), sk_tab);',
    "primary pane focus and grouped input signals"
)

# Add the new pane implementation and callback bodies before Sakura's popup menu builder.
gamma_pane_code = r"""
static void
gamma_controls_update (struct sakura_tab *sk_tab)
{
    gboolean split = (sk_tab != NULL && sk_tab->vte2 != NULL);

    if (gamma_split_v_widget)
        gtk_widget_set_sensitive(gamma_split_v_widget, !split);
    if (gamma_split_h_widget)
        gtk_widget_set_sensitive(gamma_split_h_widget, !split);
    if (gamma_grouped_input_widget) {
        gtk_widget_set_sensitive(gamma_grouped_input_widget, split);
        if (sk_tab && split)
            gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(gamma_grouped_input_widget),
                                         sk_tab->grouped_input);
        else
            gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(gamma_grouped_input_widget), FALSE);
    }
}

static void
gamma_grouped_input_toggled (GtkToggleButton *button, gpointer data)
{
    gint page = gtk_notebook_get_current_page(GTK_NOTEBOOK(sakura.notebook));
    struct sakura_tab *sk_tab;

    if (page < 0) return;
    sk_tab = sakura_get_sktab(sakura, page);
    if (!sk_tab || !sk_tab->vte2) {
        gtk_toggle_button_set_active(button, FALSE);
        return;
    }
    sk_tab->grouped_input = gtk_toggle_button_get_active(button);
}

static gboolean
gamma_pane_focus_cb (GtkWidget *widget, GdkEventFocus *event, gpointer data)
{
    struct sakura_tab *sk_tab = (struct sakura_tab *)data;
    sk_tab->active_vte = widget;
    return FALSE;
}

static void
gamma_grouped_commit_cb (VteTerminal *terminal, const gchar *text,
                         guint size, gpointer data)
{
    struct sakura_tab *sk_tab = (struct sakura_tab *)data;
    GtkWidget *peer;

    if (!sk_tab->grouped_input || !sk_tab->vte2) return;
    peer = (GTK_WIDGET(terminal) == sk_tab->vte) ? sk_tab->vte2 : sk_tab->vte;
    vte_terminal_feed_child(VTE_TERMINAL(peer), text, size);
}

static gboolean
gamma_grouped_key_cb (GtkWidget *widget, GdkEventKey *event, gpointer data)
{
    struct sakura_tab *sk_tab = (struct sakura_tab *)data;
    GtkWidget *peer;
    const gchar *sequence = NULL;
    gchar control_char;
    gunichar unicode;

    if (!sk_tab->grouped_input || !sk_tab->vte2 || event->type != GDK_KEY_PRESS)
        return FALSE;

    peer = (widget == sk_tab->vte) ? sk_tab->vte2 : sk_tab->vte;

    if (event->state & GDK_CONTROL_MASK) {
        unicode = gdk_keyval_to_unicode(event->keyval);
        unicode = g_unichar_tolower(unicode);
        if (unicode >= 'a' && unicode <= 'z') {
            control_char = (gchar)(unicode - 'a' + 1);
            vte_terminal_feed_child(VTE_TERMINAL(peer), &control_char, 1);
            return FALSE;
        }
    }

    switch (event->keyval) {
        case GDK_KEY_Return:
        case GDK_KEY_KP_Enter: sequence = "\r"; break;
        case GDK_KEY_BackSpace: sequence = "\177"; break;
        case GDK_KEY_Tab: sequence = "\t"; break;
        case GDK_KEY_ISO_Left_Tab: sequence = "\033[Z"; break;
        case GDK_KEY_Escape: sequence = "\033"; break;
        case GDK_KEY_Up: sequence = "\033[A"; break;
        case GDK_KEY_Down: sequence = "\033[B"; break;
        case GDK_KEY_Right: sequence = "\033[C"; break;
        case GDK_KEY_Left: sequence = "\033[D"; break;
        case GDK_KEY_Home: sequence = "\033[H"; break;
        case GDK_KEY_End: sequence = "\033[F"; break;
        case GDK_KEY_Insert: sequence = "\033[2~"; break;
        case GDK_KEY_Delete: sequence = "\033[3~"; break;
        case GDK_KEY_Page_Up: sequence = "\033[5~"; break;
        case GDK_KEY_Page_Down: sequence = "\033[6~"; break;
        case GDK_KEY_F1: sequence = "\033OP"; break;
        case GDK_KEY_F2: sequence = "\033OQ"; break;
        case GDK_KEY_F3: sequence = "\033OR"; break;
        case GDK_KEY_F4: sequence = "\033OS"; break;
        case GDK_KEY_F5: sequence = "\033[15~"; break;
        case GDK_KEY_F6: sequence = "\033[17~"; break;
        case GDK_KEY_F7: sequence = "\033[18~"; break;
        case GDK_KEY_F8: sequence = "\033[19~"; break;
        case GDK_KEY_F9: sequence = "\033[20~"; break;
        case GDK_KEY_F10: sequence = "\033[21~"; break;
        case GDK_KEY_F11: sequence = "\033[23~"; break;
        case GDK_KEY_F12: sequence = "\033[24~"; break;
        default: break;
    }

    if (sequence)
        vte_terminal_feed_child(VTE_TERMINAL(peer), sequence, strlen(sequence));
    return FALSE;
}

static void
gamma_spawn_second_cb (VteTerminal *terminal, GPid pid, GError *error, gpointer data)
{
    struct sakura_tab *sk_tab = (struct sakura_tab *)data;
    if (pid == -1) {
        if (error) sakura_error("Cannot start split terminal: %s", error->message);
        return;
    }
    sk_tab->pid2 = pid;
}

static void
gamma_split_active_tab (GtkOrientation orientation)
{
    gint page = gtk_notebook_get_current_page(GTK_NOTEBOOK(sakura.notebook));
    struct sakura_tab *sk_tab;
    GtkWidget *primary_box, *second_box, *paned;
    GtkWidget *vte2, *scrollbar2;
    gchar *cwd;
    char *command_env[2] = {"TERM=xterm-256color", NULL};

    if (page < 0) return;
    sk_tab = sakura_get_sktab(sakura, page);
    if (sk_tab->vte2) {
        sakura_error("This Gamma Terminal release supports two panes per tab.");
        return;
    }

    /* Move the existing terminal widgets into the first pane without
       destroying their VTE process or PTY. */
    g_object_ref(sk_tab->vte);
    g_object_ref(sk_tab->scrollbar);
    gtk_container_remove(GTK_CONTAINER(sk_tab->hbox), sk_tab->vte);
    gtk_container_remove(GTK_CONTAINER(sk_tab->hbox), sk_tab->scrollbar);

    primary_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
    gtk_box_pack_start(GTK_BOX(primary_box), sk_tab->vte, TRUE, TRUE, 0);
    gtk_box_pack_start(GTK_BOX(primary_box), sk_tab->scrollbar, FALSE, FALSE, 0);
    g_object_unref(sk_tab->vte);
    g_object_unref(sk_tab->scrollbar);

    vte2 = vte_terminal_new();
    scrollbar2 = gtk_scrollbar_new(GTK_ORIENTATION_VERTICAL,
        gtk_scrollable_get_vadjustment(GTK_SCROLLABLE(vte2)));
    second_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
    gtk_box_pack_start(GTK_BOX(second_box), vte2, TRUE, TRUE, 0);
    gtk_box_pack_start(GTK_BOX(second_box), scrollbar2, FALSE, FALSE, 0);

    paned = gtk_paned_new(orientation);
    gtk_paned_set_wide_handle(GTK_PANED(paned), TRUE);
    gtk_paned_pack1(GTK_PANED(paned), primary_box, TRUE, FALSE);
    gtk_paned_pack2(GTK_PANED(paned), second_box, TRUE, FALSE);
    gtk_box_pack_start(GTK_BOX(sk_tab->hbox), paned, TRUE, TRUE, 0);

    sk_tab->pane_root = paned;
    sk_tab->vte2 = vte2;
    sk_tab->scrollbar2 = scrollbar2;
    sk_tab->grouped_input = FALSE;

    vte_terminal_set_scrollback_lines(VTE_TERMINAL(vte2), sakura.scroll_lines);
    vte_terminal_match_add_regex(VTE_TERMINAL(vte2), sakura.http_vteregexp, PCRE2_CASELESS);
    vte_terminal_match_add_regex(VTE_TERMINAL(vte2), sakura.mail_vteregexp, PCRE2_CASELESS);
    vte_terminal_set_mouse_autohide(VTE_TERMINAL(vte2), TRUE);
    vte_terminal_set_backspace_binding(VTE_TERMINAL(vte2), VTE_ERASE_ASCII_DELETE);
    vte_terminal_set_word_char_exceptions(VTE_TERMINAL(vte2), sakura.word_chars);
    vte_terminal_set_audible_bell(VTE_TERMINAL(vte2), sakura.audible_bell ? TRUE : FALSE);
    vte_terminal_set_cursor_blink_mode(VTE_TERMINAL(vte2),
        sakura.blinking_cursor ? VTE_CURSOR_BLINK_ON : VTE_CURSOR_BLINK_OFF);
    vte_terminal_set_cursor_shape(VTE_TERMINAL(vte2), sakura.cursor_type);

    g_signal_connect(G_OBJECT(vte2), "bell", G_CALLBACK(sakura_beep_cb), NULL);
    g_signal_connect(G_OBJECT(vte2), "increase-font-size", G_CALLBACK(sakura_increase_font_cb), NULL);
    g_signal_connect(G_OBJECT(vte2), "decrease-font-size", G_CALLBACK(sakura_decrease_font_cb), NULL);
    sk_tab->exit_handler_id2 = g_signal_connect(G_OBJECT(vte2), "child-exited",
                                                 G_CALLBACK(sakura_child_exited_cb), NULL);
    g_signal_connect(G_OBJECT(vte2), "eof", G_CALLBACK(sakura_eof_cb), NULL);
    g_signal_connect(G_OBJECT(vte2), "window-title-changed", G_CALLBACK(sakura_title_changed_cb), NULL);
    g_signal_connect(G_OBJECT(vte2), "focus-in-event", G_CALLBACK(gamma_pane_focus_cb), sk_tab);
    g_signal_connect(G_OBJECT(vte2), "commit", G_CALLBACK(gamma_grouped_commit_cb), sk_tab);
    g_signal_connect(G_OBJECT(vte2), "key-press-event", G_CALLBACK(gamma_grouped_key_cb), sk_tab);
    g_signal_connect_swapped(G_OBJECT(vte2), "button-press-event",
                              G_CALLBACK(sakura_term_buttonpressed_cb), sakura.menu);
    g_signal_connect_swapped(G_OBJECT(vte2), "button-release-event",
                              G_CALLBACK(sakura_term_buttonreleased_cb), sakura.menu);

    sakura_set_font();
    sakura_set_colors();
    if (!sakura.show_scrollbar) {
        gtk_widget_hide(sk_tab->scrollbar);
        gtk_widget_hide(scrollbar2);
    }

    cwd = sakura_get_term_cwd(sk_tab);
    if (!cwd) cwd = g_get_current_dir();
    vte_terminal_spawn_async(VTE_TERMINAL(vte2), VTE_PTY_NO_HELPER, cwd,
        sakura.argv, command_env, G_SPAWN_SEARCH_PATH | G_SPAWN_FILE_AND_ARGV_ZERO,
        NULL, NULL, NULL, -1, NULL, gamma_spawn_second_cb, sk_tab);
    g_free(cwd);

    gtk_widget_show_all(sk_tab->hbox);
    if (!sakura.show_scrollbar) gtk_widget_hide(scrollbar2);
    sk_tab->active_vte = vte2;
    gtk_widget_grab_focus(vte2);
    gamma_controls_update(sk_tab);
    sakura_set_size();
}

static void
gamma_split_v_cb (GtkWidget *widget, void *data)
{
    /* A vertical divider creates left/right terminal panes. */
    gamma_split_active_tab(GTK_ORIENTATION_HORIZONTAL);
}

static void
gamma_split_h_cb (GtkWidget *widget, void *data)
{
    /* A horizontal divider creates top/bottom terminal panes. */
    gamma_split_active_tab(GTK_ORIENTATION_VERTICAL);
}

static void
gamma_miniview_cb (GtkWidget *widget, void *data)
{
    gint page = gtk_notebook_get_current_page(GTK_NOTEBOOK(sakura.notebook));
    struct sakura_tab *sk_tab;
    GtkWidget *dialog, *scroll, *view;
    GtkTextBuffer *buffer;
    VteTerminal *target;
    gchar *snapshot;

    if (page < 0) return;
    sk_tab = sakura_get_sktab(sakura, page);
    target = VTE_TERMINAL(sk_tab->active_vte ? sk_tab->active_vte : sk_tab->vte);
    snapshot = vte_terminal_get_text(target, NULL, NULL, NULL);

    dialog = gtk_dialog_new_with_buttons("Terminal Miniview",
        GTK_WINDOW(sakura.main_window), GTK_DIALOG_DESTROY_WITH_PARENT,
        "_Close", GTK_RESPONSE_CLOSE, NULL);
    gtk_window_set_default_size(GTK_WINDOW(dialog), 640, 360);
    scroll = gtk_scrolled_window_new(NULL, NULL);
    gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(scroll),
                                   GTK_POLICY_AUTOMATIC, GTK_POLICY_AUTOMATIC);
    view = gtk_text_view_new();
    gtk_text_view_set_editable(GTK_TEXT_VIEW(view), FALSE);
    gtk_text_view_set_cursor_visible(GTK_TEXT_VIEW(view), FALSE);
    gtk_text_view_set_monospace(GTK_TEXT_VIEW(view), TRUE);
    buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(view));
    gtk_text_buffer_set_text(buffer, snapshot ? snapshot : "", -1);
    gtk_container_add(GTK_CONTAINER(scroll), view);
    gtk_box_pack_start(GTK_BOX(gtk_dialog_get_content_area(GTK_DIALOG(dialog))),
                       scroll, TRUE, TRUE, 6);
    gtk_widget_show_all(dialog);
    gtk_dialog_run(GTK_DIALOG(dialog));
    gtk_widget_destroy(dialog);
    g_free(snapshot);
}

static gboolean
gamma_child_exit_cleanup (gpointer data)
{
    struct gamma_exited_pane *pending = (struct gamma_exited_pane *)data;
    struct sakura_tab *sk_tab = pending->tab;
    GtkWidget *terminal = pending->terminal;

    if (sk_tab->pane_root && terminal == sk_tab->vte2) {
        GtkWidget *keep_vte = sk_tab->vte;
        GtkWidget *keep_scroll = sk_tab->scrollbar;

        if (sk_tab->pid2 > 0) g_spawn_close_pid(sk_tab->pid2);
        g_object_ref(keep_vte);
        g_object_ref(keep_scroll);
        gtk_container_remove(GTK_CONTAINER(sk_tab->hbox), sk_tab->pane_root);
        gtk_box_pack_start(GTK_BOX(sk_tab->hbox), keep_vte, TRUE, TRUE, 0);
        gtk_box_pack_start(GTK_BOX(sk_tab->hbox), keep_scroll, FALSE, FALSE, 0);
        g_object_unref(keep_vte);
        g_object_unref(keep_scroll);

        sk_tab->pane_root = NULL;
        sk_tab->vte2 = NULL;
        sk_tab->scrollbar2 = NULL;
        sk_tab->pid2 = 0;
        sk_tab->exit_handler_id2 = 0;
        sk_tab->grouped_input = FALSE;
        sk_tab->active_vte = sk_tab->vte;
    } else if (sk_tab->pane_root && terminal == sk_tab->vte && sk_tab->vte2) {
        GtkWidget *keep_vte = sk_tab->vte2;
        GtkWidget *keep_scroll = sk_tab->scrollbar2;

        if (sk_tab->pid > 0) g_spawn_close_pid(sk_tab->pid);
        g_object_ref(keep_vte);
        g_object_ref(keep_scroll);
        gtk_container_remove(GTK_CONTAINER(sk_tab->hbox), sk_tab->pane_root);
        gtk_box_pack_start(GTK_BOX(sk_tab->hbox), keep_vte, TRUE, TRUE, 0);
        gtk_box_pack_start(GTK_BOX(sk_tab->hbox), keep_scroll, FALSE, FALSE, 0);
        g_object_unref(keep_vte);
        g_object_unref(keep_scroll);

        sk_tab->vte = sk_tab->vte2;
        sk_tab->scrollbar = sk_tab->scrollbar2;
        sk_tab->pid = sk_tab->pid2;
        sk_tab->exit_handler_id = sk_tab->exit_handler_id2;
        sk_tab->vte2 = NULL;
        sk_tab->scrollbar2 = NULL;
        sk_tab->pid2 = 0;
        sk_tab->exit_handler_id2 = 0;
        sk_tab->pane_root = NULL;
        sk_tab->grouped_input = FALSE;
        sk_tab->active_vte = sk_tab->vte;
    }

    gtk_widget_show_all(sk_tab->hbox);
    if (!sakura.show_scrollbar) gtk_widget_hide(sk_tab->scrollbar);
    gamma_controls_update(sk_tab);
    if (sk_tab->active_vte) gtk_widget_grab_focus(sk_tab->active_vte);
    sakura_set_size();
    g_free(pending);
    return G_SOURCE_REMOVE;
}
"""

source = once(
    source,
    "static void\nsakura_init_popup()\n{",
    gamma_pane_code + "\nstatic void\nsakura_init_popup()\n{",
    "Gamma Terminal pane implementation"
)

# Replace inert controls with real callbacks.
source = once(
    source,
    """    /* Split actions become active when the multi-PTY pane model is integrated.
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
    gtk_widget_set_tooltip_text(miniview, "Terminal miniview is not implemented yet.");""",
    """    gamma_split_v_widget = gamma_controls_add_button(panel, "Split V",
        "view-grid-symbolic", G_CALLBACK(gamma_split_v_cb));
    gamma_split_h_widget = gamma_controls_add_button(panel, "Split H",
        "view-dual-symbolic", G_CALLBACK(gamma_split_h_cb));

    gamma_controls_add_button(panel, "Miniview", "zoom-fit-best-symbolic",
                              G_CALLBACK(gamma_miniview_cb));""",
    "activate Split and Miniview controls"
)

source = once(
    source,
    """    grouped_input = gtk_check_button_new_with_label("Grouped input");
    gtk_widget_set_halign(grouped_input, GTK_ALIGN_START);
    gtk_widget_set_sensitive(grouped_input, FALSE);
    gtk_widget_set_tooltip_text(grouped_input,
        "Broadcast input will be added with multi-pane support.");
    gtk_box_pack_start(GTK_BOX(panel), grouped_input, FALSE, FALSE, 4);""",
    """    gamma_grouped_input_widget = gtk_check_button_new_with_label("Grouped input");
    gtk_widget_set_halign(gamma_grouped_input_widget, GTK_ALIGN_START);
    gtk_widget_set_sensitive(gamma_grouped_input_widget, FALSE);
    gtk_widget_set_tooltip_text(gamma_grouped_input_widget,
        "Send typed input to both terminal panes.");
    g_signal_connect(gamma_grouped_input_widget, "toggled",
                     G_CALLBACK(gamma_grouped_input_toggled), NULL);
    gtk_box_pack_start(GTK_BOX(panel), gamma_grouped_input_widget, FALSE, FALSE, 4);""",
    "enable Grouped input control"
)

# Ensure the secondary pane is included in the app-wide close confirmation.
source = once(
    source,
    "if ( (pgid != -1) && (pgid != sk_tab->pid)) {",
    "pid_t pgid2 = -1;\n"
    "\t\t\tif (sk_tab->vte2)\n"
    "\t\t\t\tpgid2 = tcgetpgrp(vte_pty_get_fd(vte_terminal_get_pty(VTE_TERMINAL(sk_tab->vte2))));\n"
    "\t\t\tif (((pgid != -1) && (pgid != sk_tab->pid)) || ((pgid2 != -1) && (pgid2 != sk_tab->pid2))) {",
    "window close checks both panes"
)

# Keep the UI state correct when a notebook page is removed and another becomes active.
source = once(
    source,
    "\t/* When clicking several times in the label, terminal loses its focus.\n"
    "\t * So, when the notebook got the focus, make sure the terminal HAS te focus */\n"
    "\tgtk_widget_grab_focus(sk_tab->vte);",
    "/* When clicking several times in the label, terminal loses its focus.\n"
    "\t * So, when the notebook got the focus, make sure the terminal HAS te focus */\n"
    "\tgtk_widget_grab_focus(sk_tab->active_vte ? sk_tab->active_vte : sk_tab->vte);",
    "focus active pane after page change"
)

write("src/sakura.c", source)

print("Gamma Terminal two-pane controls integrated with existing GTK3/VTE dependencies.")
print("Split V/H, independent pane PTYs, pane-aware exit handling, grouped input and terminal snapshot miniview are enabled.")
