/*
	Messagram.v Chat Connection
*/
module messagram

import io
import os
import net

pub struct Messagram {
	pub mut:
		buffer		string
		socket		net.TcpConn
}

const (
	host = "skrillec.ovh"
	port = 30
)

pub fn messagram_connect(mut m Messagram) {
	mut server := net.dial_tcp("${host}:${port}") or {
		println("[x] Error, Unable to connect to messagram server!")
		exit(0)
	}
	m.socket = server
	println("Connected")

	go m.listener(mut server)
}

pub fn (mut m Messagram) listener(mut server net.TcpConn) {
	mut reader := io.new_buffered_reader(reader: server)
	for {
		data := reader.read_line() or { "" }

		if data.len == 0 || data == "" { continue }
		// Validate JSON Response

		mut cmd := ""

		// Checking for 'action' parameters in the JSON string
		if validate_key_in_json(data, "action") {
			cmd = get_key_value(data, "action").replace(",", "")
		}

		if cmd == "msg" {
			msg := get_key_value(data, "content")
			m.buffer = msg
		}

		print(data)
	}
}

pub fn (mut m Messagram) send_msg(t string) int {
	m.socket.write_string("$t") or { 
		println("no")
		return 0 
	}
	return 1
}

pub fn (mut m Messagram) check_new_msg() bool {
	if m.buffer != "" {
		return true
	}
	return false
}

pub fn (mut m Messagram) grab_new_msg() string {
	if m.buffer != "" {
		resp := m.buffer
		m.buffer = ""
		return resp
	}
	return ""
}
 
/*
		Some custom JSON Functions
*/

pub fn validate_key_in_json(j string, key string) bool {
	json_line := j.split("\n")
	for i, line in json_line {
		if line.contains("\"${key}\":") {
			return true
		}
	}
	return false
}

pub fn get_key_value(j string, key string) string {	
	json_line := j.split("\n")
	for i, line in json_line {
		if line.contains("\"${key}\":") {
			mut fixing := line.split(":")[1]
			return fixing.replace("\"", "")
		}
	}
	return ""
}
