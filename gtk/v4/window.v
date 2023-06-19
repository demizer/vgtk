module v4

pub struct GtkWindow {
	c &C.GtkWindow
}

pub fn (g &GtkWindow) show() {
	C.gtk_widget_show(g.c)
}
