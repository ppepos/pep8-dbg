module readline_ is ldflags "-L/usr/local/lib -I/usr/local/include -lreadline"

in "C" `{
	#include <readline/readline.h>
	#include <readline/history.h>
`}

class Readline
	private fun native_readline(message: CString): CString `{
		char *line_read = readline(message);

		// End of file
		if (line_read == NULL) return NULL;

		return line_read;
	`}

	private fun native_add_history(data: CString) `{
		if (data == NULL) return;
		add_history(data);
	`}

	# Construct the object setting the keybindings mode
	# 0 : Vi mode
	# 1 : Emacs mode
	init with_mode(mode: Int) do
		if mode == 0 then
			set_vi_mode
		else
			set_emacs_mode
		end
	end

	# Set emacs keybindings mode
	fun set_vi_mode `{ rl_editing_mode = 0; `}

	# Set emacs keybindings mode
	fun set_emacs_mode `{ rl_editing_mode = 1; `}

	# Use the GNU Library readline function
	# Returns `null` if EOF is read
	# If `with_history` is true, it will save all commands in the history except
	# empty strings and white characters strings
	fun readline(message: String, with_history: nullable Bool): nullable String do
		var line = native_readline(message.to_cstring)
		if line.address_is_null then return null

		var nit_str = line.to_s

		if with_history != null and with_history then
			if nit_str.trim != "" then native_add_history(line)
		end

		return nit_str
	end

	# Adds the data String to the history no matter what it contains
	fun add_history(data: String) do native_add_history data.to_cstring

end
