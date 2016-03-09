import json::serialization

redef class Deserializer

	redef fun serialize_class(name)
	do
	# This is usually generated using `nitserial`,
	# but for a single generic class it is easier to implement manually

		if name == "Array[Post]" then return new Array[Post].from_deserializer(self)
			return super
		end
	end
end
