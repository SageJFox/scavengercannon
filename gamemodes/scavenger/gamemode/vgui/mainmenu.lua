local func_empty = function()
end

GM.menu = NULL
GM.MenuOpen = false

local function getbottomofpanel(panel)
	return panel.y + panel:GetTall()
end
local function getrightofpanel(panel)
	return panel.x + panel:GetWide()
end

local MENU = {}

function MENU:Init()
	self.menus = {}
	self.sheet = vgui.Create("DPropertySheet", self)
		self.sheet.Paint = func_empty

	self.menulabel = vgui.Create("DLabel", self)
		self.menulabel:SetText("#scav.menu")
		self.menulabel:SetFont("HUDHintTextLarge")

	self:AddSubMenu("sdm_submenu_main", "#scav.menu.main", "icon16/star.png")
	self:AddSubMenu("sdm_submenu_equipment", "#scav.menu.eq", "icon16/bomb.png")
	self:AddSubMenu("sdm_submenu_playermodel", "#scav.menu.player", "icon16/group.png")
	self:AddSubMenu("sdm_submenu_options", "#scav.menu.options", "icon16/key.png")
	self.initialized = true
end

function MENU:Think()
	--[[
	if not input.IsKeyDown(KEY_Q) and self:IsValid() and self.QOpened then
		--self:Remove()
		self:SetVisible(false)
		self.MenuOpen = false
		gui.EnableScreenClicker(false)
	end
	]]
end

function MENU:AddSubMenu(classname, name, icon)
	panel = vgui.Create(classname, self.sheet)
	self.menus[name] = panel
	panel.Menu = self
	self.sheet:AddSheet(name, panel, icon, true, true)
	return self.menus[name]
end

function MENU:AutoSetup()
	self:SetPos(ScrW() * 0.1, ScrH() * 0.1)
	self:SetSize(ScrW() * 0.8, ScrH() * 0.8 - 64)
	self.menulabel:SetPos(12, 10)
	self.menulabel:SizeToContents()
	self.sheet:SetSkin(self:GetSkin())
	for k, v in pairs(self.menus) do
		v:SetSkin(self:GetSkin())
	end
end

function MENU:SetMode(mode)
	self.menus["#scav.menu.main"].ModeLabel:SetText(mode)
	self.menus["#scav.menu.main"].DescLabel:SetText(GAMEMODE.Description)
end

function MENU:Close()
	self:SetVisible(false)
	gui.EnableScreenClicker(false)
	GAMEMODE.MenuOpen = false
end

function MENU:InvalidateLayout()
	if not self.initialized then
		return
	end
	
	--sheet
	self.sheet:SetPos(8, 32)
	self.sheet:SetSize(self:GetWide() - 16, self:GetTall() - self.sheet.y)
	for k, v in pairs(self.menus) do
		v:SetPos(0, 46)
		v:SetSize(self.sheet:GetWide(), self.sheet:GetTall() - v.y)
	end
end

vgui.Register("sdm_mainmenu", MENU, "DPanel")

function GM:OnSpawnMenuOpen()
	self:OpenMenu()
end

function GM:OnSpawnMenuClose()
	if self.menu:IsValid() then
		self.menu:Close()
	end
end



---------------------------------------



	
	
	
-------------------------------------
local PANEL = {}

	local specbuttonpress = function(button)
		RunConsoleCommand("changeteam", TEAM_SPECTATOR)
		button.Menu:Close()
	end
	
	local joinbuttonpress = function(button)
		if team.Joinable(TEAM_UNASSIGNED) then
			RunConsoleCommand("changeteam", TEAM_UNASSIGNED)
		else
			local menu = vgui.Create("sdm_teamjoinmenu")
			menu:SetSkin("sg_menu")
			menu:MakePopup()
			menu:AutoSetup()
		end
		--GAMEMODE:SetPanelAsMenu(menu)
	end
	
	function PANEL:Init()
		self.SpecButton = vgui.Create("DButton", self)
			self.SpecButton:SetText("#scav.menu.spectate")		
		self.JoinButton = vgui.Create("DButton", self)
			self.JoinButton:SetText("#scav.menu.join")
		self.ModeLabel = vgui.Create("sdm_labelbox", self)
			self.ModeLabel:SetText(GAMEMODE:GetModeName())
		self.DescLabel = vgui.Create("sdm_labelbox", self)
			self.DescLabel:SetWrap(true)
			self.DescLabel:SetAutoStretchVertical(true)
			self.DescLabel:SetMargins(16, 8)
		self.Logo = vgui.Create("DImage", self)
			self.Logo:SetImage("vgui/scavlogo1")
		self.initialized = true
	end
	
	function PANEL:InvalidateLayout()
		if not self.initialized then
			return
		end
		self.SpecButton.Menu = self.Menu
		self.SpecButton.DoClick = specbuttonpress
		self.JoinButton.Menu = self.Menu
		self.JoinButton.DoClick = joinbuttonpress
		self.Logo:SetPos(16, 16)
		local wh = math.min(self:GetWide() / 2 - 32, self:GetTall() - 32)
		self.Logo:SetSize(wh, wh)
		self.Logo:SetPos(16, 16)
		
		--WATself.ModeLabel:SetText(GAMEMODE.NiceName)
		self.ModeLabel:SetSize(self:GetWide() - 32 - self.Logo:GetWide() - self.Logo.x, 32)
		self.ModeLabel:SetPos(self.Logo.x + self.Logo:GetWide() + 16, 16)
		
		self.JoinButton:SetSize(self.ModeLabel:GetWide() / 2 - 16, 64)
		self.SpecButton:SetSize(self.ModeLabel:GetWide() / 2 - 16, 64)
		self.SpecButton:SetPos(self.ModeLabel.x + 8, self:GetTall()-self.SpecButton:GetTall() - 16)
		self.JoinButton:SetPos(self.SpecButton.x + self.SpecButton:GetWide() + 16, self:GetTall() - self.JoinButton:GetTall() - 16)
		
		
		--WATself.DescLabel:SetText(GAMEMODE.Description)
		self.DescLabel:SetSize(self.ModeLabel:GetWide(), self.JoinButton.y-self.ModeLabel.y - self.ModeLabel:GetTall() - 32)
		self.DescLabel:SetPos(self.Logo.x + self.Logo:GetWide() + 16, self.ModeLabel.y + self.ModeLabel:GetTall() + 16)
	end

	vgui.Register("sdm_submenu_main", PANEL, "DPanel")

local function nametomodelname(modelname)
	return list.GetForEdit("PlayerOptionsModel")[modelname] or player_manager.TranslatePlayerModel(GetConVarString("cl_playermodel"))
end
	
local PANEL = {}

	local function updateplayercolor(pan)
		pan:GetEntity().GetPlayerColor = function(self)
			if not ispanel(pcol) then return Vector(GetConVar("cl_playercolor"):GetString()) end
			return pcol:GetVector()
		end
		pan:GetEntity():GetPlayerColor()
	end

	--Generate new skin/bodygroup sliders for currently selected model
	local function updateModelSettings(self)
		if not ispanel(self) then return end

		local ent = self.Preview:GetEntity()
		if not IsValid(ent) then return end

		self.ModelSettings:Clear()

		local x = self.ModelSettings:GetWide() / 6
		local y = 16
		local w = math.Round(x * 4)
		x = math.Round(x)
		local h = 50
		local lh = 20
		local sep = 10

		--First skin selection, if we've got any
		local skins = ent:SkinCount() - 1
		if skins > 0 then
			self.ModelSkin = self.ModelSettings:Add("DNumSlider")
				self.ModelSkin:SetPos(x, y)
				self.ModelSkin:SetSize(w, h)
				self.ModelSkin:SetText("#scav.menu.player.skin")
				self.ModelSkin:SetDecimals(0)
				self.ModelSkin:SetMin(0)
				self.ModelSkin:SetDefaultValue(0)
				self.ModelSkin:SetMax(skins)
				self.ModelSkin:SetValue(0)
				self.ModelSkin:SetConVar("cl_playerskin")
				self.ModelSkin.OnValueChanged = function(p, v)
					local v = math.Round(v)
					self.ModelSkin:SetValue(v)
					ent:SetSkin(v)
				end
			y = y + h + sep
		end

		self.ModelBodyGroups = {}

		local function updateBodyGroups()
			local bgroups = {}
			for k, v in pairs(self.ModelBodyGroups) do
				table.insert(bgroups, math.Round(v:GetValue()))
			end
			RunConsoleCommand("cl_playerbodygroups", table.concat(bgroups, " "))
		end

		--tell player what they're looking at
		local label = self.ModelSettings:Add("DLabel")
			label:SetPos(x, y)
			label:SetSize(w, lh)
			label:SetText("#scav.menu.player.bodygroup")
		y = y + lh + sep
		
		local anybodygroup = false

		--adding controls for each bodygroup
		for k = 0, ent:GetNumBodyGroups() - 1 do
			local totalsub = ent:GetBodygroupCount(k) - 1
			local empty = (totalsub <= 0)
			--make a slider for each bodygroup, even if it's useless (makes processing easier)

			local slider = self.ModelSettings:Add("DNumSlider")
				table.insert(self.ModelBodyGroups, k, slider)
				slider:SetPos(x, y)
				slider:SetSize(w, h)
				slider:SetText(ent:GetBodygroupName(k))
				slider:SetDecimals(0)
				slider:SetMin(0)
				slider:SetDefaultValue(0)
				slider:SetMax(totalsub)
				slider:SetValue(0)
			--slider is actually usable
			if not empty then
				slider.OnValueChanged = function(p, v)
					local v = math.Round(v)
					slider:SetValue(v)
					ent:SetBodygroup(k, v)
					updateBodyGroups()
				end
				y = y + h + sep
				anybodygroup = true
			else
				--slider:SetDark(true)
				slider:SetVisible(false)
				slider:SetPos(x, 1000000)
			end
		end

		--Model lacks any setable bodygroups, hide the label
		if not anybodygroup then
			label:SetPos(x, 1000000)
			label:SetVisible(false)
		end

		updateplayercolor(self.Preview)
	end

	preview = 0
	pcol = 0

	function PANEL:Init()
	
		self.PreviewLabel = vgui.Create("sdm_labelbox", self)
			self.PreviewLabel:SetText(GetConVarString("cl_playermodel"))
			self.PreviewLabel:SetMargins(0, 0)
			self.PreviewLabel:SetAlignment(TEXT_ALIGN_CENTER)
		self.PreviewBox = vgui.Create("DPanel", self)
			self.Preview = vgui.Create("DModelPanel", self.PreviewBox)
				self.Preview:SetModel(nametomodelname(GetConVarString("cl_playermodel")))
				updateplayercolor(self.Preview)
			preview = self.Preview
		self.ModelsBox = vgui.Create("DPanel", self)
			self.Models = vgui.Create("DPanelList", self.ModelsBox)
				self.Models:EnableHorizontal(true)
				self.Models:EnableVerticalScrollbar(true)
			self.ModelSettings = vgui.Create("DPanel", self.ModelsBox)
		updateModelSettings(self)

		self:SetupPlayerModels()

		self.initialized = true
	end
	
	local function pmodelbuttonpressed(button)
		RunConsoleCommand("cl_playermodel", button.nicename)
		LocalPlayer():EmitSound("buttons/button14.wav")
		button.Preview:SetModel(button.modelname)
		button.PreviewLabel:SetText(button.nicename)
	end
	
	function PANEL:SetupPlayerModels()
		self.Models:Clear()
		--for k, v in pairs(list.GetForEdit("PlayerOptionsModel")) do
		local playermodels = table.Merge(player_manager.AllValidModels(), list.GetForEdit("PlayerOptionsModel"))
		--table.SortByKey(playermodels)
		local alphabetizedkeys = {}
		for k, v in pairs(playermodels) do
			table.insert(alphabetizedkeys, k)
		end
		table.sort(alphabetizedkeys)
		
		--local i = 0
		for k, name in pairs(alphabetizedkeys) do
			local model = playermodels[name]
			--i = i + 1
			local icon = vgui.Create("SpawnIcon")
			icon:SetModel(model)
			icon:SetVisible(true)
			icon.modelname = model
			icon.nicename = name
			icon:SetMouseInputEnabled(true)
			icon.OnMousePressed = function(button)
				pmodelbuttonpressed(button)
				updateModelSettings(self)
			end
			icon:SetEnabled(true)
			icon.Preview = self.Preview
			icon.PreviewLabel = self.PreviewLabel
			icon:SetToolTip(name)
			self.Models:AddItem(icon)
			--print(k)
		end
		--print(i)
	end
	
	function PANEL:InvalidateLayout()
		if not self.initialized then return end
		
		self.ModelsBox:SetPos(self:GetWide() / 3 + 64, 32)
		self.ModelsBox:SetWide(self:GetWide() / 3 * 2 - 96)
		self.ModelsBox:SetTall(self:GetTall() - 64)
		self.ModelsBox:SetSkin(self:GetSkin())

		self.Models:SetPos(0, 0)
		self.Models:SetWide(self.ModelsBox:GetWide() / 2)
		self.Models:SetTall(self.ModelsBox:GetTall())
		self.Models:SetSkin(self:GetSkin())

		self.ModelSettings:SetPos(self.ModelsBox:GetWide() / 2, 0)
		self.ModelSettings:SetWide(self.ModelsBox:GetWide() / 2)
		self.ModelSettings:SetTall(self.ModelsBox:GetTall())
		self.ModelSettings:SetSkin(self:GetSkin())
		
		
		self.PreviewLabel:SetSkin(self:GetSkin())
		self.PreviewLabel:SetPos(32, 32)
		self.PreviewLabel:SetSize(self:GetWide() / 3 - 32, 32)		
		
		self.PreviewBox:SetPos(32, 72)
		self.PreviewBox:SetWide(self:GetWide() / 3 - 32)
		self.PreviewBox:SetTall(self:GetTall() - 104)
		self.PreviewBox:SetSkin(self:GetSkin())
		local w, h = self.PreviewBox:GetWide(), self.PreviewBox:GetTall()
		local r = w / h
		self.Preview:SetSize(w, h)
		self.Preview:SetPos(0, 0)
		self.Preview:RunAnimation(ACT_WALK)
		self.Preview:SetAnimated(true)
		self.Preview:SetAnimSpeed(1)
		self.Preview:SetFOV(85 * r)

		updateModelSettings(self)
	end

	vgui.Register("sdm_submenu_playermodel", PANEL, "DPanel")
	
	
	
	
	CreateClientConVar("sdm_w2", "weapon_backuppistol", true, true)
	
	local PANEL = {}
	local modelradius = {}
	
	local function LockedPosition(self)
		local ent = self:GetEntity()
		local angpos = ent:GetAttachment(ent:LookupAttachment("muzzle"))
		local bpos, bang = ent:GetBonePosition(ent:LookupBone("ValveBiped.Bip01_R_Hand"))
		local lookat = (angpos.Pos + bpos) / 2
		self:SetLookAt(lookat)
		camvec = Vector(lookat)
		camvec.x = lookat.x + math.cos(CurTime()) * 30
		camvec.y = lookat.y - math.sin(CurTime()) * 30
		camvec.z = 1
		self:SetCamPos(camvec)
	end
	
	function PANEL:Init()
		--weapon
			self.WepLabel = vgui.Create("sdm_labelbox", self)
				self.WepLabel:SetText("#scav.menu.eq.secondary")
			self.WepDescLabel = vgui.Create("sdm_labelbox", self)
				self.WepDescLabel:SetText("#scav.menu.eq.desc.default")
				self.WepDescLabel:SetWrap(true)
			self.WepPreviewLabel = vgui.Create("sdm_labelbox", self)
			self.WepSelectBox = vgui.Create("DPanelList", self)
				self:SetupWeaponSelection()
				self.WepSelectBox:EnableVerticalScrollbar(true)
			self.WepPreviewBox = vgui.Create("DPanel", self)
			self.WepPreview = vgui.Create("DModelPanel", self.WepPreviewBox)
			self.WepPreview.LayoutEntity = LockedPosition
			self:SetWeapon(GetConVarString("sdm_w2"))
		--extra
			self.ExtraLabel = vgui.Create("sdm_labelbox", self)
			self.ExtraLabel:SetText("#scav.menu.eq.gadget")
		self.initialized = true
	end
	
	local function weaponbuttonpressed(button)
		RunConsoleCommand("sdm_w2", button.weaponclassname)
		LocalPlayer():EmitSound("buttons/button14.wav")
		button.submenu:SetWeapon(button.weaponclassname)
	end

	local flavortexts = {
		["weapon_blackholegun"] = "bhg", 
		["weapon_alchemygun"] =   "alc", 
		["capture_device"] = "cd", 
		["weapon_backuppistol"] =  "bup",
	}
	setmetatable(flavortexts, {__index = function() return "default" end})
	
	
	function PANEL:SetupWeaponSelection()
		self.WepSelectBox:Clear()
		local size = self.WepSelectBox:GetWide()
		for k, v in pairs(GAMEMODE:GetValidWeapons()) do
			local icon = vgui.Create("DImageButton", self.WepSelectBox)
			local weptab = weapons.Get(v)
			icon:SetImage("HUD/weapons/" .. weptab.ClassName)
			icon:SetKeepAspect(true)
			icon:SetDrawBorder(true)
			icon:SetSize(size, size)
			--icon:SetModel(weptab.WorldModel)
			icon.submenu = self
			icon.weaponclassname = v
			icon.DoClick = weaponbuttonpressed
			icon:SetMouseInputEnabled(true)
			icon:SetToolTip(false)
			self.WepSelectBox:AddItem(icon)
		end
	end

	function PANEL:SetWeapon(classname)
		local wep = weapons.Get(classname)
		if not wep then
			return
		end
		self.WepPreview:SetModel(wep.WorldModel)
		self.WepPreview:LayoutEntity()
		self.WepPreviewLabel:SetText(wep.PrintName)
		self.WepDescLabel:SetText("#scav.menu.eq.desc." .. flavortexts[classname])
		self.WepDescLabel:InvalidateLayout()
	end
	
	function PANEL:InvalidateLayout()
		if not self.initialized then return end

		self.WepLabel:SetPos(16, 16)
		self.WepLabel:SetSize(self:GetWide() - 64, 32)
		
		self.ExtraLabel:SetPos(16, self:GetTall() / 2)
		self.ExtraLabel:SetSize(self:GetWide() - 64, 32)
		
		self.WepSelectBox:SetPos(32, getbottomofpanel(self.WepLabel) + 8)
		self.WepSelectBox:SetSize(80, self:GetTall() / 2 - 16-self.WepSelectBox.y)
		
		self.WepPreviewBox:SetPos(getrightofpanel(self.WepSelectBox) + 8, getbottomofpanel(self.WepLabel) + 8)
		self.WepPreviewBox:SetWide(self:GetWide() / 3 - 32 - 48)
		self.WepPreviewBox:SetTall(self:GetTall() / 2 - 16 - self.WepPreviewBox.y)
		
		self.WepPreviewLabel:SetPos(getrightofpanel(self.WepPreviewBox) + 8, getbottomofpanel(self.WepLabel) + 8)
		self.WepPreviewLabel:SetSize(self:GetWide() - 64 - self.WepPreviewLabel.x, 32)	
		
		self.WepDescLabel:SetPos(getrightofpanel(self.WepPreviewBox) + 8, getbottomofpanel(self.WepPreviewLabel) + 8)
		self.WepDescLabel:SetSize(self:GetWide() - 64 - self.WepDescLabel.x, self:GetTall() / 2 - 16 - self.WepDescLabel.y)
		
		local w, h = self.WepPreviewBox:GetWide(), self.WepPreviewBox:GetTall()
		local r = w / h
		self.WepPreview:SetSize(w, h)
		self.WepPreview:SetPos(0, 0)
		self.WepPreview:SetAnimated(true)
		self.WepPreview:SetAnimSpeed(1)
		self.WepPreview:SetCamPos(Vector(40 * r, 0, 10))
		self.WepPreview:SetFOV(50 * r)
		self.WepPreview:SetLookAt(vector_origin)
	end

	vgui.Register("sdm_submenu_equipment", PANEL, "DPanel")

	local PANEL = {}

	--convar: cl_scav_high
	--convar: cl_scav_iconalpha
	--convar: scav_hands
	
	
	function PANEL:Init()
		self.ColorMenu = self:Add("DPanel")
			self.ColorMenuPlayerLabel = self.ColorMenu:Add("DLabel")
				self.ColorMenuPlayerLabel:SetText("#smwidget.color_plr")
			self.ColorMenuPlayer = self.ColorMenu:Add("DColorMixer")
				pcol = self.ColorMenuPlayer
				self.ColorMenuPlayer:SetAlphaBar(false)
				self.ColorMenuPlayer:SetPalette(false)
				self.ColorMenuPlayer:SetVector(Vector(GetConVarString("cl_playercolor")))
				--self.ColorMenuPlayer:SetConVar("cl_playercolor")
				self.ColorMenuPlayer.ValueChanged = function(col)
					GetConVar("cl_playercolor"):SetString(tostring(self.ColorMenuPlayer:GetVector()))
					--preview:GetEntity():SetPlayerColor(self.ColorMenuPlayer:GetVector())
					preview:GetEntity():GetPlayerColor()
				end
			self.ColorMenuWeaponLabel = self.ColorMenu:Add("DLabel")
				self.ColorMenuWeaponLabel:SetText("#smwidget.color_wep")
			self.ColorMenuWeapon = self.ColorMenu:Add("DColorMixer")
				self.ColorMenuWeapon:SetAlphaBar(false)
				self.ColorMenuWeapon:SetPalette(false)
				self.ColorMenuWeapon:SetVector(Vector(GetConVarString("cl_weaponcolor")))
				--self.ColorMenuWeapon:SetConVar("cl_weaponcolor")
				self.ColorMenuWeapon.ValueChanged = function(col)
					GetConVar("cl_weaponcolor"):SetString(tostring(self.ColorMenuWeapon:GetVector()))
				end
		self.initialized = true
	end

	function PANEL:InvalidateLayout()
		if not self.initialized then return end

		self.ColorMenu:DockPadding(8, 8, 8, 8)
		self.ColorMenu:SetSize(320, 600)

		self.ColorMenuPlayerLabel:Dock(TOP)

		self.ColorMenuPlayer:Dock(TOP)
		self.ColorMenuPlayer:SetSize(200, math.min(self:GetTall() / 3, 260))

		self.ColorMenuWeaponLabel:DockMargin(0, 32, 0, 0)
		self.ColorMenuWeaponLabel:Dock(TOP)

		self.ColorMenuWeapon:Dock(TOP)
		self.ColorMenuWeapon:SetSize(200, math.min( self:GetTall() / 3, 260))
	end

	vgui.Register("sdm_submenu_options", PANEL, "DPanel")
