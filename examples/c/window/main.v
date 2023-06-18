module main

// Arch Linx Paths
#pkgconfig gtk4
#flag -I /usr/lib/graphene-1.0/include
#include "gtk/gtk.h"

fn C.gtk_application_new(id &char, flags int) &C.GtkApplication

fn C.gtk_application_window_new(app C.GtkApplication) &C.GtkWindow

fn C.gtk_window_set_default_size(win C.GtkWindow, w int, h int)

fn C.gtk_window_set_title(win C.GtkWindow, title &char)

fn C.gtk_container_add(container voidptr, widget voidptr)

fn C.gtk_widget_show(win C.GtkWindow)

fn C.g_signal_connect(ins voidptr, signal &char, cb voidptr, data voidptr)

fn C.gtk_widget_destroy(widget voidptr)

fn C.gtk_widget_grab_focus(widget voidptr)

fn C.g_application_run(app C.GtkApplication, argc int, argv int) int

fn activate_cb(app &C.GtkApplication, data voidptr) {
	win := C.gtk_application_window_new(app)
	C.gtk_window_set_default_size(win, 1000, 600)
	C.gtk_window_set_title(win, &char('hello'.str))
	C.gtk_widget_show(win)
}

fn main() {
	app := C.gtk_application_new(&char('org.gtk.example'.str), C.G_APPLICATION_DEFAULT_FLAGS)
	C.g_signal_connect(app, &char('activate'.str), activate_cb, unsafe { nil })
	status := C.g_application_run(app, 0, 0)
}
