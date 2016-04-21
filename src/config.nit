module config

import json::serialization

redef class Sys
	var config_manager = new ConfigManager(program_name.dirname + "/../config/config.json") is lazy
end

redef class Deserializer
	redef fun deserialize_class(name)
	do
		if name == "Array[Config]" then return new Array[Config].from_deserializer(self)
		return super
	end
end

abstract class Config 
end

class DebuggerConfig
	super Config
	serialize

	var nb_bytes_to_disass: Int = 15
	var context_nb_instructions: Int = 5

	# Command line keybindings (0 = vi mode, 1 = emacs mode)
	var cli_mode = 0
	# Panels to open in printing order
	# "r" : register file panel
	# "c" : code panel
	var context_panels: Array[String] = ["r", "c"]
end


class ConfigManager
	var debugger_config: DebuggerConfig is noinit

	init(file_path: String) do
		var fd = new FileReader.open(file_path)
		var config_json = fd.read_all

		debugger_config = new DebuggerConfig

		var deserializer = new JsonDeserializer(config_json)
		var configs = deserializer.deserialize
		assert configs isa Array[Config]

		for config in configs do
			if config isa DebuggerConfig then debugger_config = config
		end
	end

end
