/*************** Messagram *************
@title: Messagram.v Chat Module
@author: Erupt
@since: 3/13/22
*************Copyright © 2922**********/
module messagram

import io
import os
import net
import time
import x.json2

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

pub fn (mut m Messagram) login(user string, pass string) int {
	mut reader := io.new_buffered_reader(reader: m.socket)
	m.send_msg('{"status": "true","username": "${user}"}\n')
	time.sleep(1*time.second)
	m.send_msg('{"status": "true","password": "${pass}"}\n')
	login_check := reader.read_line() or { "" }
	parse_json := get_key_value(login_check, "login_status")
	if parse_json == "0" {
		return 0
	}
	return 1
}

pub fn (mut m Messagram) listener(mut server net.TcpConn) {
	mut reader := io.new_buffered_reader(reader: server)
	for {
		data := reader.read_line() or { "" }

		if data.len == 0 || data == "" { continue }
		if validate_json_syntax(data) == false { continue } // Ignoring unaccepted data. or data that isnt JSON syntax which should be never

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

pub fn (mut m Messagram) send_msg(username string, t string) int {
	mut json_data := create_json(["status", "cmd", "content"], ["true", "msg", "${t}"])
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
		I switch languages alot so to avoid using or learning the JSON module in different languages
		that i havent used them in yet
		
		I have created some custom JSON Functions

		- Validate JSON Syntax in String
		- Validate key in JSON String
		- Get the key's value in JSON String
		- Create JSON 
*/

/*
		How to use:
			if validate_key_in_json(json, "key") {
				// valid key in JSON string
			}
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

/*
		How to use:
			mut value := get_key_value(json, "key")
*/
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

/*
		How to use:
			if validate_json_syntax(data) {
				// valid syntax
			}
*/
pub fn validate_json_syntax(j string) bool {
	mut validation := false
	if j.len < 2 { return false }
	if j.starts_with("{") && j.ends_with("}") {
		validation = true
	} else { return false }

	if j,contains("\n") {
		lines := j.split("\n")
		for i, line in lines {
			if line != "{" || line != "}" {
				if line.starts_with("\"") && line.ends_with("\"") { validation = true } else { return false }
				if line.contains(":") { validation = true } else { return false }
			}
		}
	}
	return validation
}

/*
		How to use:
			json := create_json(["status", "username"], ["true", "lulzsec"])

			println(json)
*/
pub fn create_json(keys []string, values []string) string {
	mut json_format := "{"
	for i, key in keys {
		if i == keys.len {
			json_format += '"${key}":"${values[i]}"}'
		} else {
			json_format += '"${key}":"${values[i]}",'
		}
	}
	return json_format
}