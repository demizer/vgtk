module v4

import gio.v2 as gio2
import gobject.v2 as gobject

#pkgconfig gtk4
#flag -I /usr/lib/graphene-1.0/include
#flag -Wno-deprecated-declarations
#include "gtk/gtk.h"

fn C.gtk_application_new(id &char, flags int) &C.GtkApplication
fn C.gtk_application_window_new(app C.GtkApplication) &C.GtkWindow
fn C.gtk_window_set_default_size(win C.GtkWindow, w int, h int)
fn C.gtk_window_set_title(win C.GtkWindow, title &char)
fn C.gtk_widget_show(win C.GtkWindow)

pub struct GtkApplication {
	c &C.GtkApplication
}

pub fn (g &GtkApplication) connect_activate(f fn ()) {
	C.g_signal_connect(g.c, &char('activate'.str), f, unsafe { nil })
}

pub fn (g &GtkApplication) run() {
	C.g_application_run(g.c, 0, 0)
}

pub fn (g &GtkApplication) new_window(title string, size_width u16, size_height u16) &GtkWindow {
	win := C.gtk_application_window_new(g.c)
	C.gtk_window_set_default_size(win, size_width, size_height)
	C.gtk_window_set_title(win, &char(title.str))
	return &GtkWindow{win}
}

pub fn application_new(application_id string, flags gio2.GApplicationFlags) GtkApplication {
	app := C.gtk_application_new(&char(application_id.str), int(flags))
	return GtkApplication{app}
}
