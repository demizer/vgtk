module v2

#pkgconfig gobject-2.0
#flag -Wno-deprecated-declarations

fn C.g_signal_connect(ins voidptr, signal &char, cb voidptr, data voidptr)
fn C.g_application_run(app C.GtkApplication, argc int, argv int) int
