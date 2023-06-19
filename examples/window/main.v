module main

import gtk.v4 as gtk4
import gio.v2 as gio2

fn main() {
	app := gtk4.application_new('com.github.demizer.vgtk.window_example', gio2.GApplicationFlags.default)
	app.connect_activate(fn [app] () {
		app.new_window('hello, world!', 600, 600).show()
	})
	app.run()
}
