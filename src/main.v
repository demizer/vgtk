module main

import walkingdevel.vxml
import os

struct XMLWrap {
	nodes []&vxml.Node
mut:
	current_idx int = -1
}

fn (n XMLWrap) filter_by_predicate(name string) ?XMLWrap {
	mut pnodes := []&vxml.Node{}
	for nnode in n.nodes {
		pnodes << nnode.get_elements_by_predicate(fn [name] (node &vxml.Node) bool {
			return node.name == name
		})
	}
	return XMLWrap{
		nodes: pnodes
	}
}

fn (n XMLWrap) get_attribute(name string) !string {
	return n.nodes.first().attributes[name]
}

fn (n XMLWrap) get_params() ?XMLWrap {
	for nnode in n.nodes {
		pnodes := nnode.get_elements_by_predicate(fn (node &vxml.Node) bool {
			return node.name == 'parameter'
		})

		return XMLWrap{
			nodes: pnodes
		}
	}
	return none
}

fn (mut n XMLWrap) next() ?&vxml.Node {
	n.current_idx++
	if n.current_idx >= n.nodes.len {
		return none
	}
	return n.nodes[n.current_idx]
}

struct GtkIRNamespace {
	name         string
	package_name string
	path         string
	includes     []string
	version      string
	parsed       vxml.Node
}

fn (g GtkIRNamespace) filter_by_class_name(name string) ?XMLWrap {
	classes := g.parsed.get_elements_by_predicate(fn (node &vxml.Node) bool {
		return node.name == 'class'
	})
	for cls in classes {
		if cls.attributes['name'].to_lower() == name.to_lower() {
			return XMLWrap{
				nodes: [cls]
			}
		}
	}
	if name == '' {
		return XMLWrap{
			nodes: classes
		}
	}
	return none
}

type Imports = []GtkIRNamespace

fn (i Imports) has_import(path string) bool {
	for v in i {
		if path in v.includes {
			return true
		}
	}
	return false
}

struct Parser {
	root    GtkIRNamespace
	imports Imports
}

fn (p Parser) unique_imports() []string {
	mut imps := []string{}
	for i in p.imports {
		for j in i.includes {
			if j in imps {
				continue
			}
			imps << j
		}
	}
	return imps
}

fn recurse_imports(mut imports Imports, start GtkIRNamespace) !Imports {
	imports << start
	for v in start.includes {
		// TODO: only read first 10kb of the file to make it faster
		if !os.exists(v) {
			eprintln('import: ${v} does not exist! Skipping')
			continue
		}
		tmp := new_gir_namespace(v)!
		for i in tmp.includes {
			if imports.has_import(i) {
				continue
			}
			recurse_imports(mut imports, tmp)!
		}
	}
	return imports
}

fn new_parser() !&Parser {
	gir := new_gir_namespace('/usr/share/gir-1.0/Gtk-4.0.gir')!
	// println(gir)
	// mut imps := Imports([]GtkIRNamespace{})
	// imps = recurse_imports(mut imps, gir)!
	return &Parser{
		root: gir
		// imports: imps
	}
}

fn new_gir_namespace(path string) !&GtkIRNamespace {
	parsed := vxml.parse_file(path)!
	pincludes := parsed.get_elements_by_predicate(fn (node &vxml.Node) bool {
		return node.name == 'include'
	})
	mut includes := []string{}
	for i in pincludes {
		name := i.attributes['name']
		version := i.attributes['version']
		includes << '/usr/share/gir-1.0/${name}-${version}.gir'
	}
	pname := parsed.get_elements_by_predicate(fn (node &vxml.Node) bool {
		return node.name == 'namespace'
	})
	ppackage := parsed.get_elements_by_predicate(fn (node &vxml.Node) bool {
		return node.name == 'package'
	})
	return &GtkIRNamespace{
		name: pname.first().attributes['name']
		version: pname.first().attributes['version']
		package_name: ppackage.first().attributes['name']
		path: path
		parsed: parsed
		includes: includes
	}
}

fn translate_ctype_to_v(typ string) string {
	return match typ {
		'const char*' { '&char' }
		else { typ }
	}
}

fn dump_constructors(p Parser) ! {
	activated := ['gtk_application_', 'gtk_window_']

	// last work: I had just figured out that I should implement class down
	//
	// "Application" class
	// -> contructor (gtk_application_new)
	// -> methods (???)

	// "Window" class
	// -> contructor (gtk_window_new)
	// -> methods (gtk_window_set_default_size)

	classes := p.root.filter_by_class_name('') or { return }
	cons := classes.filter_by_predicate('constructor') or { return }
	for con in cons {
		typ := con.get_attribute('c:identifier')!
		mut found := false
		for active in activated {
			if typ.contains(active) {
				found = true
				// println(active)
				// continue outer
			}
		}
		if !found {
			continue
		}
		ret_val := cons.filter_by_predicate('return-value') or { return }
		ret_typp := ret_val.filter_by_predicate('type') or { return }
		ret_typ := ret_typp.get_attribute('c:type')!
		ret_type := '&C.${ret_typ.replace('*', '')}'
		mut param_str := ''
		params := cons.get_params() or { return }
		for i, param in params {
			param_str += param.get_attribute('name')! + ' '
			typ2 := param.get_element_by_tag_name('type')!
			param_str += translate_ctype_to_v(typ2.attributes['c:type']).replace('*',
				'')
			if i < params.nodes.len - 1 {
				param_str += ', '
			}
		}
		println('fn C.${typ}(${param_str}) ${ret_type}')
	}
}

// fn render_class_constructor()

// fn render_c_decl() {
// 	classes := p.root.filter_by_class_name('application') or { return }
// 	cons := classes.filter_by_predicate('constructor') or { return }
// 	for con in cons {
// 		typ := con.get_attribute('c:identifier')!
// 		mut found := false
// 		for active in activated {
// 			if typ.contains(active) {
// 				found = true
// 				// println(active)
// 				// continue outer
// 			}
// 		}
// 		if !found {
// 			continue
// 		}
// 		ret_val := cons.filter_by_predicate('return-value') or { return }
// 		ret_typp := ret_val.filter_by_predicate('type') or { return }
// 		ret_typ := ret_typp.get_attribute('c:type')!
// 		ret_type := '&C.${ret_typ.replace('*', '')}'
// 		mut param_str := ''
// 		params := cons.get_params() or { return }
// 		for i, param in params {
// 			param_str += param.get_attribute('name')! + ' '
// 			typ2 := param.get_element_by_tag_name('type')!
// 			param_str += translate_ctype_to_v(typ2.attributes['c:type']).replace('*',
// 				'')
// 			if i < params.nodes.len - 1 {
// 				param_str += ', '
// 			}
// 		}
// 		println('fn C.${typ}(${param_str}) ${ret_type}')
// 	}
// }

fn dump_class(doc string, cls &vxml.Node) {
	name := cls.attributes['name']
	c_name := cls.attributes['c:type']
	// FIXME: Doc comment must match def for vdoc: https://docs.vosca.dev/concepts/writing-documentation.html
	for l in doc.split_into_lines() {
		println('// ${l}')
	}
	println('
	pub struct ${name} {
		c &C.${c_name}
	}')
}

fn render_application_class(p Parser) ! {
	acls := p.root.filter_by_class_name('application') or { return error('class not found') }
	for con in acls {
		for c in con.children {
			match c.name {
				'doc' {
					dump_class(c.get_text(), acls.nodes.first())
				}
				'source-position', 'implements' {}
				else {
					println('not implemented: ${c.name}')
					continue
				}
			}
		}
		break
	}
	// cons := classes.filter_by_predicate('constructor') or { return }
	// for con in cons {
	// 	typ := con.get_attribute('c:identifier')!
	// 	mut found := false
	// 	for active in activated {
	// 		if typ.contains(active) {
	// 			found = true
	// 			// println(active)
	// 			// continue outer
	// 		}
	// 	}
	// 	if !found {
	// 		continue
	// 	}
	// 	ret_val := cons.filter_by_predicate('return-value') or { return }
	// 	ret_typp := ret_val.filter_by_predicate('type') or { return }
	// 	ret_typ := ret_typp.get_attribute('c:type')!
	// 	ret_type := '&C.${ret_typ.replace('*', '')}'
	// 	mut param_str := ''
	// 	params := cons.get_params() or { return }
	// 	for i, param in params {
	// 		param_str += param.get_attribute('name')! + ' '
	// 		typ2 := param.get_element_by_tag_name('type')!
	// 		param_str += translate_ctype_to_v(typ2.attributes['c:type']).replace('*',
	// 			'')
	// 		if i < params.nodes.len - 1 {
	// 			param_str += ', '
	// 		}
	// 	}
	// 	println('fn C.${typ}(${param_str}) ${ret_type}')
	// }
}

fn main() {
	gir_p := new_parser() or { panic(err) }
	// println(gir_p)
	// dump_constructors(gir_p)!
	render_application_class(gir_p)!
}
