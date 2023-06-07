module main

// Arch Linx Paths
#pkgconfig gtk4
#flag -I /usr/lib/graphene-1.0/include
// gobject-introspection-1.0

// import walkingdevel.vxml { parse_file }

#include "gtk/gtk.h"

// #include <gtk/gtk.h>
//
// static void
// activate (GtkApplication* app,
//           gpointer        user_data)
// {
//   GtkWidget *window;
//
//   window = gtk_application_window_new (app);
//   gtk_window_set_title (GTK_WINDOW (window), "Window");
//   gtk_window_set_default_size (GTK_WINDOW (window), 200, 200);
//   gtk_widget_show (window);
// }
//
// int
// main (int    argc,
//       char **argv)
// {
//   GtkApplication *app;
//   int status;
//
//   app = gtk_application_new ("org.gtk.example", G_APPLICATION_DEFAULT_FLAGS);
//   g_signal_connect (app, "activate", G_CALLBACK (activate), NULL);
//   status = g_application_run (G_APPLICATION (app), argc, argv);
//   g_object_unref (app);
//
//   return status;
// }

// struct C.GtkWidget {
// }

// struct C.GtkWindow {
// }


fn C.gtk_application_new(id &char, flags int) &C.GtkApplication

// fn C.gtk_init()

fn C.gtk_application_window_new(app C.GtkApplication) &C.GtkWindow

fn C.gtk_window_set_default_size(win C.GtkWindow, w int, h int)

fn C.gtk_window_set_title(win C.GtkWindow, title &char)

fn C.gtk_container_add(container voidptr, widget voidptr)

fn C.gtk_widget_show(win C.GtkWindow)

// fn C.gtk_main()

fn C.g_signal_connect(ins voidptr, signal &char, cb voidptr, data voidptr)

fn C.gtk_widget_destroy(widget voidptr)

fn C.gtk_widget_grab_focus(widget voidptr)

fn C.g_application_run(app C.GtkApplication, argc int, argv int) int


// fn create_linux_web_view(url string, title string) {
// }
//

fn activate_cb(app &C.GtkApplication, data voidptr ) {
	win := C.gtk_application_window_new(app)
	C.gtk_window_set_default_size(win, 1000, 600)
	C.gtk_window_set_title(win, &char("hello".str))
	// C.gtk_container_add(win, webview)
	// C.g_signal_connect(win, &char("destroy".str), destroy_window_cb, unsafe { nil })
	// C.g_signal_connect(webview, 'close', destroy_window_cb, win)
	// C.webkit_web_view_load_uri(webview, &char(url.str))
	// C.gtk_widget_grab_focus(webview)
	C.gtk_widget_show(win)
}

fn main() {
  // news := parse_file('./news.xml') or { panic(err) }
  //
  // posts := news.get_elements_by_tag_name('post')
  //
  // println(posts.first().get_text())
	app := C.gtk_application_new(&char("org.gtk.example".str), C.G_APPLICATION_DEFAULT_FLAGS)
	C.g_signal_connect (app, &char("activate".str), activate_cb, unsafe { nil})

	status := C.g_application_run(app, 0, 0)
	// C.gtk_main()
  // println("hello, world!")
}
