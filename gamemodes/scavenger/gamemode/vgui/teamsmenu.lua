local PANEL = {}

	function PANEL:Init()
	end

	function PANEL:SetTeam(teamid)
		self.team = teamid
	end

	-- ??
	--[[local teamstostrings = {}
		teamstostrings[TEAM_UNASSIGNED] = "unassigned"
		teamstostrings[TEAM_SPECTATOR] = "spectators"
		teamstostrings[TEAM_RED] = "red"
		teamstostrings[TEAM_BLUE] = "blue"
		teamstostrings[TEAM_GREEN] = "green"
		teamstostrings[TEAM_YELLOW] = "yellow"
		teamstostrings[TEAM_ORANGE] = "orange"
		teamstostrings[TEAM_PURPLE] = "purple"
		teamstostrings[TEAM_BROWN] = "brown"
		teamstostrings[TEAM_TEAL] = "teal"]]
		
	function PANEL:DoClick()
		RunConsoleCommand("changeteam", self.team)
		self.Menu:Remove()
		gui.EnableScreenClicker(false)
	end

	vgui.Register("sdm_teamjoinbutton", PANEL, "DButton")

local PANEL = {}
	PANEL.m_bgColor = Color(50, 50, 50, 255)
	
	function PANEL:Init()
		self.teams = {}
		self.Form = vgui.Create("DForm", self)
		self:SetTitle("#scav.team.select")
		self.Form:SetName("")
		self.initialized = true
		--todo: should have some way of sorting teams in the config files
		for k, v in pairs(GAMEMODE.Teams) do
			if not v then continue end
			self:AddTeam(k)
		end
	end
	
	function PANEL:AutoSetup()
		self:SetSize(300, 300)
		self:SetPos(ScrW() / 2 - self:GetWide() / 2, ScrH() / 2 - self:GetTall() / 2)
	end

	function PANEL:AddTeam(teamid)
		if self.teams[teamid] then return end

		local button = vgui.Create("sdm_teamjoinbutton", self.Form)
		self.Form:AddItem(button)
		self.teams[teamid] = button
		button.ColorSquare = vgui.Create("DImage", button)
		local tcol = team.GetColor(teamid)
		button.ColorSquare:SetImage("vgui/white")
			button.ColorSquare:SetSize(16, 16)
			button.ColorSquare:SetPos(3, button:GetTall() / 2 - button.ColorSquare:GetTall() / 2)
			button.ColorSquare:SetImageColor(tcol)
			button.ColorSquare:SetVisible(true)
		--team icon
		local t = string.match(team.GetName(teamid), "scav%.team%.([%a]+)")
		if t then
			button.TeamIcon = vgui.Create("DImage", button)
			button.TeamIcon:SetImage(t and ("hud/sdm/" .. t .. "_icon.png"))
				button.TeamIcon:SetSize(16, 16)
				button.TeamIcon:SetPos(3, button:GetTall() / 2 - button.TeamIcon:GetTall() / 2)
				button.TeamIcon:SetImageColor((tcol.r + tcol.g + tcol.b) / 3 < 132 and color_white or color_black)
				button.TeamIcon:SetVisible(true)
		end
		button.Menu = self
		button:SetTeam(teamid)
		button:SetText(team.GetName(teamid))
	end
	
	function PANEL:InvalidateLayout()
		if not self.initialized then return end

		self.Form:SetPos(4, 21)
		self.Form:SetSize(self:GetWide() - 8, self:GetTall() - 21)
	end
	
	vgui.Register("sdm_teamjoinmenu", PANEL, "DFrame")
