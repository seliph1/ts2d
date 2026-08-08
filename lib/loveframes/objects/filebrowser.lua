--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]] ------------------------------------------------

return function(loveframes)
	---------- module start ----------

	-- filebrowser object
	local newobject = loveframes.NewObject("filebrowser", "loveframes_object_filebrowser", true)

	--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
	--]] ---------------------------------------------------------
	function newobject:initialize()
		self.type = "filebrowser"
		self.width = 550
		self.height = 380
		self.internal = false
		self.children = {}
		self.internals = {}
		self:SetDrawFunc()

		self.current_dir = ""
		self.mode = "open" -- "open" or "save"
		self.selected_file = ""
		self.on_select = nil
		self.on_cancel = nil

		-- Get skin and load icons
		local skin = loveframes.GetActiveSkin()
		self.folder_icon = skin.images["folder.png"] or "lib/loveframes/skins/moon/images/folder.png"
		self.file_default_icon = skin.images["file_extension_default.png"] or
			"lib/loveframes/skins/moon/images/file_extension_default.png"
		self.file_image_icon = skin.images["file_extension_image.png"] or
			"lib/loveframes/skins/moon/images/file_extension_image.png"
		self.file_sound_icon = skin.images["file_extension_sound.png"] or
			"lib/loveframes/skins/moon/images/file_extension_sound.png"

		-- 1. Address input at the top
		self.address_input = loveframes.objects["textbox"]:new()
		self.address_input.parent = self
		self.address_input:SetText("")
		self.address_input.OnEnter = function(object, text)
			self:SetDirectory(text)
		end
		table.insert(self.internals, self.address_input)

		-- 2. Tree scroll panel on the left
		self.tree_scroll = loveframes.objects["scrollpanel"]:new()
		self.tree_scroll.background = false
		self.tree_scroll.parent = self
		table.insert(self.internals, self.tree_scroll)

		-- Tree list inside the tree scroll panel
		self.dir_tree = loveframes.objects["tree"]:new()
		self.dir_tree.parent = self.tree_scroll
		self.dir_tree:SetRearrangeEnabled(false)
		self.dir_tree.OnSelectNode = function(parent, node)
			if node and node.path then
				self:NavigateTo(node.path)
			end
		end
		self.tree_scroll:AddItem(self.dir_tree)

		-- 3. Scroll panel on the right for file listing
		self.file_scroll = loveframes.objects["scrollpanel"]:new()
		self.file_scroll.parent = self
		self.file_scroll.background = false
		table.insert(self.internals, self.file_scroll)

		-- 4. Droplist inside the scroll panel
		self.file_list = loveframes.objects["droplist"]:new()
		self.file_list.parent = self.file_scroll
		self.file_list:SetZebra(true)
		self.file_list:SetHighlight(true)
		self.file_list.last_click_time = 0
		self.file_list.last_clicked_item = nil
		self.file_list.OnClick = function(list_obj, element, element_id)
			local cur_time = love.timer.getTime()
			if cur_time - list_obj.last_click_time < 0.3 and list_obj.last_clicked_item == element then
				-- DOUBLE CLICK!
				if element.is_dir then
					self:NavigateTo(element.path)
				else
					self.filename_input:SetText(element.text)
					self:ConfirmSelection()
				end
			else
				-- SINGLE CLICK!
				if not element.is_dir then
					self.filename_input:SetText(element.text)
				end
			end
			list_obj.last_click_time = cur_time
			list_obj.last_clicked_item = element
		end
		self.file_scroll:AddItem(self.file_list)

		-- 5. Name input at bottom
		self.name_lbl = loveframes.objects["label"]:new()
		self.name_lbl.parent = self
		self.name_lbl:SetText("Nome:")
		table.insert(self.internals, self.name_lbl)

		self.filename_input = loveframes.objects["textbox"]:new()
		self.filename_input.parent = self
		self.filename_input:SetText("")
		self.filename_input.OnEnter = function(object, text)
			self:ConfirmSelection()
		end
		table.insert(self.internals, self.filename_input)

		-- 6. Filter dropdown (multichoice) at bottom
		self.filter_lbl = loveframes.objects["label"]:new()
		self.filter_lbl.parent = self
		self.filter_lbl:SetText("Tipo:")
		table.insert(self.internals, self.filter_lbl)

		self.filter_choice = loveframes.objects["multichoice"]:new()
		self.filter_choice.parent = self
		self.filter_choice:AddChoice("Todos os Arquivos (*.*)")
		self.filter_choice.OnChoiceSelected = function(object, choice)
			self:RefreshFileList()
		end
		self.filter_choice:SetChoice("Todos os Arquivos (*.*)")
		table.insert(self.internals, self.filter_choice)

		-- 7. Buttons
		self.action_button = loveframes.objects["button"]:new()
		self.action_button.parent = self
		self.action_button:SetText("Abrir")
		self.action_button.OnClick = function()
			self:ConfirmSelection()
		end
		table.insert(self.internals, self.action_button)

		self.cancel_button = loveframes.objects["button"]:new()
		self.cancel_button.parent = self
		self.cancel_button:SetText("Cancelar")
		self.cancel_button.OnClick = function()
			if self.on_cancel then
				self.on_cancel()
			end
		end
		table.insert(self.internals, self.cancel_button)

		-- Set starting directory
		self:SetDirectory("")
	end

	--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the element
	--]] ---------------------------------------------------------
	function newobject:update(dt)
		if not self:OnState() then return end
		if not self:isUpdating() then return end

		local parent = self.parent
		local base = loveframes.base
		local update = self.Update

		if parent ~= base then
			self.x = self.parent.x + self.staticx
			self.y = self.parent.y + self.staticy
		end

		-- Position internals relative to self
		self.address_input:SetPos(5, 5)
		self.address_input:SetSize(self.width - 10, 20)

		local mid_y = 30
		local bottom_h = 65
		local mid_h = self.height - mid_y - bottom_h - 10

		local tree_w = math.floor(self.width * 0.35)
		local list_w = self.width - tree_w - 15

		self.tree_scroll:SetPos(5, mid_y)
		self.tree_scroll:SetSize(tree_w, mid_h)

		-- Ensure dir_tree matches scroll panel width minus vertical scrollbar
		self.dir_tree:SetWidth(tree_w - 16)

		self.file_scroll:SetPos(tree_w + 10, mid_y)
		self.file_scroll:SetSize(list_w, mid_h)

		-- Ensure droplist matches scroll width minus vertical scrollbar
		self.file_list:SetWidth(list_w - 16)

		local label_y = self.height - bottom_h - 5
		self.name_lbl:SetPos(5, label_y + 3)

		self.filename_input:SetPos(50, label_y)
		self.filename_input:SetSize(self.width - 160, 20)

		self.action_button:SetPos(self.width - 100, label_y)
		self.action_button:SetSize(95, 20)

		self.filter_lbl:SetPos(5, label_y + 28)
		self.filter_choice:SetPos(50, label_y + 25)
		self.filter_choice:SetSize(self.width - 160, 20)

		self.cancel_button:SetPos(self.width - 100, label_y + 25)
		self.cancel_button:SetSize(95, 20)

		for k, v in ipairs(self.internals) do
			v:update(dt)
		end
	end

	--[[---------------------------------------------------------
	- func: SetDirectory(path)
	- desc: sets the directory path and recreates the tree
	--]] ---------------------------------------------------------
	function newobject:SetDirectory(path)
		-- Clean path
		path = path:gsub("\\", "/"):gsub("^/+", ""):gsub("/+$", "")
		self.current_dir = path
		self.address_input:SetText(path)

		-- Rebuild folder tree from root
		self.dir_tree.nodes = {}
		self.dir_tree.selectednode = false

		local root = self.dir_tree:AddNode("/")
		root.path = ""
		root.icon = self.folder_icon
		root.OnOpen = function(n)
			self:PopulateNode(n)
		end

		self:PopulateNode(root)
		root:SetOpen(true)
		self.dir_tree:CalculateLayout()

		-- If path is subpath, try to expand to it
		if path ~= "" then
			local current = root
			local parts = {}
			for part in path:gmatch("[^/]+") do
				table.insert(parts, part)
			end

			for _, part in ipairs(parts) do
				-- Ensure current is open and populated
				if not current.open then
					current:SetOpen(true)
					self:PopulateNode(current)
				end
				-- Find child matching part
				local found = false
				for _, child in ipairs(current.children) do
					if child.text == part then
						current = child
						found = true
						break
					end
				end
				if not found then break end
			end
			self.dir_tree.selectednode = current
			current:SetOpen(true)
			self:PopulateNode(current)
		else
			self.dir_tree.selectednode = root
		end

		self.dir_tree:CalculateLayout()
		self:RefreshFileList()
	end

	function newobject:GetDirectory()
		return self.current_dir
	end

	--[[---------------------------------------------------------
	- func: NavigateTo(path)
	- desc: navigates to path without rebuilding entire tree
	--]] ---------------------------------------------------------
	function newobject:NavigateTo(path)
		self.current_dir = path
		self.address_input:SetText(path)
		self:RefreshFileList()
	end

	local function hasSubdirectories(path)
		local items = love.filesystem.getDirectoryItems(path)
		for _, item in ipairs(items) do
			local fullpath = (path == "" and item) or (path .. "/" .. item)
			local info = love.filesystem.getInfo(fullpath)
			if info and info.type == "directory" then
				return true
			end
		end
		return false
	end

	--[[---------------------------------------------------------
	- func: PopulateNode(node)
	- desc: lists subdirs inside node
	--]] ---------------------------------------------------------
	function newobject:PopulateNode(node)
		node.children = {}
		local items = love.filesystem.getDirectoryItems(node.path)
		local subdirs = {}
		for _, item in ipairs(items) do
			local fullpath = (node.path == "" and item) or (node.path .. "/" .. item)
			local info = love.filesystem.getInfo(fullpath)
			if info and info.type == "directory" then
				table.insert(subdirs, item)
			end
		end
		table.sort(subdirs)

		for _, subdir in ipairs(subdirs) do
			local child = node:AddNode(subdir)
			child.path = (node.path == "" and subdir) or (node.path .. "/" .. subdir)
			child.icon = self.folder_icon
			child.OnOpen = function(n)
				self:PopulateNode(n)
			end
			-- Só adiciona o nó dummy se a pasta realmente tiver subdiretórios
			if hasSubdirectories(child.path) then
				child:AddNode("")
			end
		end
	end

	--[[---------------------------------------------------------
	- func: RefreshFileList()
	- desc: lists files and folders of current path to right-hand list
	--]] ---------------------------------------------------------
	function newobject:RefreshFileList()
		self.file_list:Clear()

		local path = self.current_dir
		local items = love.filesystem.getDirectoryItems(path)

		local dirs = {}
		local files = {}

		for _, item in ipairs(items) do
			local fullpath = (path == "" and item) or (path .. "/" .. item)
			local info = love.filesystem.getInfo(fullpath)
			if info then
				if info.type == "directory" then
					table.insert(dirs, item)
				else
					table.insert(files, item)
				end
			end
		end
		table.sort(dirs)
		table.sort(files)

		-- Get active filter
		local filter = self.filter_choice:GetChoice()
		local ext_filter = nil
		if filter and filter ~= "Todos os Arquivos (*.*)" then
			ext_filter = filter:match("%*%.(%w+)")
		end

		-- Load extensions map
		local image_extensions = { png = true, jpg = true, jpeg = true, bmp = true, gif = true }
		local sound_extensions = { ogg = true, wav = true, mp3 = true }

		local files_to_add = {}
		-- Add files matching filter
		for _, file in ipairs(files) do
			local parts = loveframes.SplitString(file, "([.])")
			local ext = #parts > 1 and parts[#parts]:lower() or ""

			if not ext_filter or ext == ext_filter then
				local icon = self.file_default_icon
				if image_extensions[ext] then
					icon = self.file_image_icon
				elseif sound_extensions[ext] then
					icon = self.file_sound_icon
				end

				table.insert(files_to_add, {
					text = file,
					icon = icon,
					is_dir = false
				})
			end
		end
		self.file_list:AddElementsFromTable(files_to_add)
	end

	--[[---------------------------------------------------------
	- func: ConfirmSelection()
	- desc: confirms selecting the current filename input text
	--]] ---------------------------------------------------------
	function newobject:ConfirmSelection()
		local file = self.filename_input:GetText()
		if file == "" then return end

		local fullpath = (self.current_dir == "" and file) or (self.current_dir .. "/" .. file)
		self.selected_file = fullpath

		if self.on_select then
			self.on_select(fullpath)
		end
	end

	function newobject:GetSelectedFile()
		return self.selected_file
	end

	--[[---------------------------------------------------------
	- func: SetMode(mode)
	- desc: sets "open" or "save" mode, updates button text
	--]] ---------------------------------------------------------
	function newobject:SetMode(mode)
		self.mode = mode
		if mode == "save" then
			self.action_button:SetText("Salvar")
		else
			self.action_button:SetText("Abrir")
		end
		return self
	end

	--[[---------------------------------------------------------
	- func: SetFilter(patterns)
	- desc: sets filter dropdown choices, e.g. {"*.lua", "*.png"}
	--]] ---------------------------------------------------------
	function newobject:SetFilter(patterns)
		self.filter_choice:Clear()
		self.filter_choice:AddChoice("Todos os Arquivos (*.*)")
		for _, pat in ipairs(patterns) do
			self.filter_choice:AddChoice(pat)
		end
		self.filter_choice:SetChoice(patterns[1] or "Todos os Arquivos (*.*)")
		self:RefreshFileList()
		return self
	end

	--[[---------------------------------------------------------
	- func: SetOnSelect(func) / SetOnCancel(func)
	- desc: sets select and cancel callbacks
	--]] ---------------------------------------------------------
	function newobject:SetOnSelect(func)
		self.on_select = func
		return self
	end

	function newobject:SetOnCancel(func)
		self.on_cancel = func
		return self
	end

	--[[---------------------------------------------------------
	- static func: loveframes.CreateFileDialog(...)
	- desc: pops up a dialog window containing a filebrowser
	--]] ---------------------------------------------------------
	function loveframes.CreateFileDialog(title, mode, filter, onSelect, onCancel, start_dir)
		local frame = loveframes.Create("frame")
		frame:SetName(title or "Selecionar Arquivo")
		frame:SetSize(570, 420)
		frame:Center()
		frame:SetModal(true)
		frame:SetDraggable(true)
		frame:SetResizable(false)

		local fb = loveframes.Create("filebrowser", frame)
		fb:SetPos(10, 30)
		fb:SetSize(550, 380)
		fb:SetMode(mode or "open")

		if filter then
			fb:SetFilter(filter)
		end

		if start_dir then
			fb:SetDirectory(start_dir)
		end

		fb:SetOnSelect(function(filepath)
			if onSelect then
				onSelect(filepath)
			end
			frame:Remove()
		end)

		fb:SetOnCancel(function()
			if onCancel then
				onCancel()
			end
			frame:Remove()
		end)

		if loveframes.state and loveframes.state ~= "none" then
			frame:SetState(loveframes.state)
		end

		return fb, frame
	end

	---------- module end ----------
end
