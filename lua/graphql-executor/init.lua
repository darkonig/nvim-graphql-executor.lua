local M = {
	conf = {
		split_cmd = "vsplit",
		default_mappings = true, -- Bind default mappings
		use_colors = true, -- print output in colors
	},
}

local global_options = {
	cache = { -- used to store the information about the last run
		last_used_term_buf = nil,
	},
}

local function get_buffer()
	-- return last_buf
	local api = vim.api
	if
		global_options.cache.last_used_term_buf ~= nil
		and api.nvim_buf_is_valid(global_options.cache.last_used_term_buf)
	then
		local term_buf_win = false
		-- for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if api.nvim_win_get_buf(win) == global_options.cache.last_used_term_buf then
				term_buf_win = true
				api.nvim_set_current_win(win)
			end
		end

		if not term_buf_win then
			-- api.nvim_buf_delete(global_options.cache.last_used_term_buf, { force = true })
			api.nvim_command(M.conf.split_cmd)

			vim.api.nvim_set_current_buf(global_options.cache.last_used_term_buf)

			-- global_options.cache.last_used_term_buf = vim.api.nvim_create_buf(false, true)

			-- global_options.cache.last_used_term_buf = vim.api.nvim_get_current_buf()
		end
	else
		api.nvim_command(M.conf.split_cmd)

		global_options.cache.last_used_term_buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_set_current_buf(global_options.cache.last_used_term_buf)

		-- global_options.cache.last_used_term_buf = vim.api.nvim_get_current_buf()
		-- Set the buffer not savable
		vim.api.nvim_buf_set_option(global_options.cache.last_used_term_buf, "bufhidden", "wipe")
		vim.api.nvim_buf_set_option(global_options.cache.last_used_term_buf, "buftype", "nofile")
		vim.api.nvim_buf_set_option(global_options.cache.last_used_term_buf, "filetype", "terminal")
	end
	if M.conf.use_colors then
		vim.api.nvim_command("setl filetype=terminal")
		vim.api.nvim_command("setl concealcursor=nc")
	end

	return global_options.cache.last_used_term_buf
end

local function print_command_result(output)
	-- Replace newline characters with a special separator
	output = output:gsub("\n", "\\n")

	-- Split the output string into a table of lines
	local lines = vim.split(output, "\\n")

	local buffer = get_buffer()

	-- vim.api.nvim_buf_set_option(buffer, 'modifiable', true)

	-- for _, line in ipairs(lines) do
	--   vim.api.nvim_call_function("append", { -1, line })
	-- end
	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
	-- vim.api.nvim_buf_set_option(buffer, 'modifiable', false)
end

local function append_to_result(output)
	local buffer = get_buffer()

	local current_lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)

	for _, line in ipairs(output) do
		current_lines[#current_lines + 1] = string.gsub(line, "\r", "")
	end
	-- current_lines[#current_lines + 1] = buf_windows[1]

	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, current_lines)

	--- move cursor to the last line
	-- local last_line = vim.api.nvim_buf_line_count(buffer)
	local last_line = #current_lines
	vim.api.nvim_win_set_cursor(0, { last_line, 0 })
end

local function on_job_finish(job_id, data, event)
	-- vim.fn.append(vim.fn.line('$'), data)
	-- vim.fn.append(vim.fn.line('$'), '---')
	-- local output = ''
	-- for _, ln in pairs(data) do
	--   -- print('getting data ' .. _ .. ln)
	--   output = output .. ln .. '\\n'
	-- end
	-- print('getting data2 ' .. output)
	-- vim.fn.append(vim.fn.line('$'), output)
	append_to_result(data)
end

local function execute_graphql(params)
	params = params or {}
	options = {
		verbose = false,
	}

	for k, v in pairs(params) do
		options[k] = v
	end

	verbose = options.verbose
	-- local file = vim.fn.expand("%:p")
	-- local file_path = vim.api.nvim_buf_get_name(0)
	-- local workspace_path = vim.lsp.buf.list_workspace_folders()[1]
	-- print(workspace_path)
	-- local file_path = vim.fn.expand('%:' .. workspace_path .. ':.')
	local file_path = vim.fn.expand("%:p:.")
	file_path = string.gsub(file_path, "src/", "")
	-- print_command_result('Running file ' .. file_path)
	-- print('My current file is ' .. file_path)
	-- vim.cmd('vsplit | terminal')
	-- local command = ":call jobsend(b:terminal_job_id, 'echo nice temrinal\\n')"
	-- local command = "npm start -- " .. file_path .. " --color=always"
	local command = { "npm", "start", "--", file_path, verbose and "--verbose" or "" }
	-- local command = "echo 'nice \e[31mterminal\e[0m" .. string.char(math.random(65, 65 + 25)) .. "'"
	local pwd = vim.api.nvim_call_function("getcwd", {})
	local command_options = {
		on_stdout = on_job_finish,
		on_stderr = on_job_finish,
		pty = (M.conf.use_colors and 1 or 0),
		pwd = pwd,
	}
	-- local job_id = vim.api.nvim_call_function("jobstart", { command, command_options })
	local job = vim.fn.jobstart(command, command_options)
	-- local _, output = vim.api.nvim_call_function("jobwait", { job_id, -1 })
	-- print_command_result(output)
	-- vim.api.nvim_command("new")
	-- vim.api.nvim_buf_set_lines(0, 0, -1, false, { output })
end

-- vim.api.nvim_command("command! -nargs=0 ExecuteGraphQL :call get_current_file()")
-- vim.api.nvim_command("command! ExecGraphql lua execute_graphql()")

-- return {
--   get_current_file = get_current_file
-- }

M.execute_graphql = execute_graphql

M.apply_default_mappings = function()
	if M.conf.default_mappings then
		vim.keymap.set("n", "gr", require("graphql-executor").execute_graphql)
	end
end

M.setup = function(conf)
	conf = conf or {}
	M.conf = vim.tbl_deep_extend("force", M.conf, conf)

	if M.conf.default_mappings then
		M.apply_default_mappings()
	end
end

return M
