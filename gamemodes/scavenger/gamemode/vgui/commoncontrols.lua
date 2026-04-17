local PANEL = {}
	PANEL.WMargin = 8
	PANEL.HMargin = 4
	PANEL.ASV = false
	PANEL.Wrap = true
	PANEL.Plain = true
	PANEL.Align = TEXT_ALIGN_LEFT

	function PANEL:Init()
		self.Label = vgui.Create("DLabel", self)
		self.Font = "Scav_MenuLarge"
		self.Label:SetFont(self.Font)
		self.Label:SetAutoStretchVertical(self.ASV)
		self.Label:SetWrap(self.Wrap)
		self.initialized = true
	end
	
	function PANEL:InvalidateLayout()
		if not self.initialized then return end
		--self.Label:SizeToContents()
		--self.Label:SetPos(8, self:GetTall() / 2 - self.Label:GetTall() / 2)
		--self.Label:SetWide(self:GetWide() - 16)
		if self.Align == TEXT_ALIGN_LEFT then
			self.Label:SetSize(self:GetWide() - self.WMargin * 2, self:GetTall() - self.HMargin * 2)
			self.Label:SetPos(self.WMargin, self.HMargin)
		else
			self:UpdateAlign()
		end
		--
		--
	end
	
	function PANEL:SizeToContents()
		self.Label:SizeToContents()
		self.Label:InvalidateLayout()
		self:SetSize(self.Label:GetWide() + self.WMargin * 2, self.Label:GetTall() + self.HMargin * 2)
		self:InvalidateLayout()
	end
	
	function PANEL:UpdateAlign()
		self.Label:SizeToContents()
		self.Label:InvalidateLayout()
		local wm = self.WMargin
		local hm = self.HMargin
		local w = self:GetWide() - wm * 2
		local h = self:GetTall() - hm * 2
		local x
		local y
		local lw = self.Label:GetWide()
		local lh = self.Label:GetTall()
		local align = self.Align
		if align == TEXT_ALIGN_LEFT then
			x = 0
			y = (h - lh) / 2
		elseif align == TEXT_ALIGN_CENTER then
			x = (w - lw) / 2
			y = (h - lh) / 2
		elseif align == TEXT_ALIGN_RIGHT then
			x = w - lw
			y = (h - lh) / 2
		elseif align == TEXT_ALIGN_TOP then
			x = (w - lw) / 2
			y = 0
		elseif align == TEXT_ALIGN_BOTTOM then
			x = (w - lw) / 2
			y = h - lh
		end
		x = x+wm
		y = y+hm
		self.Label:SetPos(x, y)
	end
	
	function PANEL:SetWMargin(value)
		self.WMargin = value
		self:InvalidateLayout()
	end
	
	function PANEL:SetHMargin(value)
		self.HMargin = value
		self:InvalidateLayout()
	end
	
	function PANEL:SetMargins(w, h)
		self.WMargin = w
		self.HMargin = h
		self:InvalidateLayout()
	end
	
	function PANEL:SetFont(font)
		self.Font = font
		self.Label:SetFont(font)
		self:InvalidateLayout()
	end

	function PANEL:SetText(text)
		self.Text = text
		self.Label:SetText(text)
		self:InvalidateLayout()
	end
	
	function PANEL:SetAutoStretchVertical(value)
		self.Label:SetAutoStretchVertical(value)
		self.ASV = value
		self:InvalidateLayout()
	end

	function PANEL:SetWrap(value)
		self.Wrap = value
		self.Label:SetWrap(value)
	end	
	
	function PANEL:GetWMargin()
		return self.WMargin
	end
	
	function PANEL:GetHMargin()
		return self.HMargin
	end
	
	function PANEL:GetMargins()
		return self.WMargin, self.HMargin
	end
	
	function PANEL:GetFont()
		return self.Font
	end
	
	function PANEL.GetText()
		return self.Text
	end
	
	function PANEL:GetAutoStretchVertical()
		return self.ASV
	end
	
	function PANEL:GetWrap()
		return self.Wrap
	end
	
	function PANEL:SetAlignment(alignment)
		self.Align = alignment
		if alignment ~= TEXT_ALIGN_LEFT then
			self:SetWrap(false)
		end
		self:UpdateAlign()
	end
	
	vgui.Register("sdm_labelbox", PANEL, "DPanel")


local PANEL = {}
	
	function PANEL:Init()
	end
	
	function PANEL:AutoPos()
		self:SetPos(ScrW() / 2 - self:GetWide() / 2, 64)
	end
	
	vgui.Register("sdm_objective", PANEL, "sdm_labelbox")


local PANEL = {}
	PANEL.Title = "Title"
	PANEL.Text = "Text"
	function PANEL:Init()
		self.initialized = true
		self:SetSize(112, 56)
		self.TitleLabel = vgui.Create("DLabel", self)
			self.TitleLabel:SetText(self.Title)
			self.TitleLabel:SetFont("Scav_MenuLarge")
			self.TitleLabel:SetPos(6, 4)
			self.TitleLabel:SizeToContents()
		self.TextLabel = vgui.Create("DLabel", self)
			self.TextLabel:SetFont("DermaLarge")
			self.TextLabel:SetPos(24, 14)
			self.TextLabel:SetText(self.Text)
	end

	function PANEL:InvalidateLayout()
		if not self.initialized then return end
	end
	
	function PANEL:SetText(text)
		self.TextLabel:SetText(text)
		self.TextLabel:SizeToContents()
		self.TextLabel:SetPos((self:GetWide() - self.TextLabel:GetWide()) / 2, 12 + (self:GetTall() - 12 - self.TextLabel:GetTall()) / 2)
	end
	
	function PANEL:SetTitle(title)
		self.TitleLabel:SetText(title)
		self.TitleLabel:SizeToContents()
	end
	
	vgui.Register("sdm_generichudbox", PANEL, "DPanel")

local color_white_title = Color(255, 255, 255, 150)
local color_black_title = Color(0, 0, 0, 224)

local PANEL = {}
	PANEL.BGColor = Color(50, 50, 50, 255)
	PANEL.Flipped = false

	--the effects of this stick for any child panels, so if you want derived panels unflipped you gotta flip'em again
	function PANEL:Flip()
		self.Flipped = (not self.Flipped)
		self.TitleLabel:SetX(self.TitleLabel:GetX() + (self.Flipped and 8 or -8))
	end

	function PANEL:Paint()
		if not self.Flipped then
			SKIN:PaintFrame(self, self:GetWide(), self:GetTall())
		else
			SKIN:PaintFrameReverse(self, self:GetWide(), self:GetTall())
		end
	end

	function PANEL:PlayerColor()
		local bgcol = Vector(0, 0, 0)
		local pl = LocalPlayer()
		if self.GetPlayer then pl = self:GetPlayer() end

		if IsValid(pl) then
			if team.IsReal(pl:Team()) then
				self.BGColor = team.GetColor(pl:Team())
			else
				bgcol = pl:GetPlayerColor()
				self.BGColor = Color(bgcol.r * 255, bgcol.g * 255, bgcol.b * 255, 255)
			end
		end

		self.TextLight = ((self.BGColor.r + self.BGColor.g + self.BGColor.b) / 3 < 132)

		self:SetBackgroundColor(self.BGColor)
		if IsValid(self.TitleLabel) then
			self.TitleLabel:SetTextColor(self.TextLight and color_white_title or color_black_title)
		end
		if IsValid(self.TextLabel) then
			self.TextLabel:SetTextColor(self.TextLight and color_white or color_black)
		end
	end

	function PANEL:GetSDMColor()
		return self.BGColor, self.TextLight
	end
	
	vgui.Register("sdm_playercolorhudbox", PANEL, "sdm_generichudbox")
	
	
local PANEL = {}
	PANEL.Ent = NULL
	local flagtex = surface.GetTextureID("HUD/sdm/dot")
	local flagtex2 = surface.GetTextureID("HUD/sdm/dot2")
	local flagtex3 = surface.GetTextureID("HUD/sdm/dot3")
	local flagtex4 = surface.GetTextureID("HUD/sdm/dot4")
	local teamicon = {}
	for k, v in pairs(team.GetAllTeams()) do
		if not team.IsReal(k) then continue end

		local t = string.match(team.GetName(k), "scav%.team%.([%a]+)")
		if not t then return end

		teamicon[k] = Material("hud/sdm/" .. t .. "_icon.png", "smooth 0 mips 0")
	end
	
	function PANEL:Init()
		 
		--self.Color = Color(255, 255, 255, 255)
	end
	
	function PANEL:SetEntity(ent)
		self.Ent = ent
		if not IsValid(self.Ent) then return end
		local yaw = EyeAngles().y
		local pos1 = EyePos()
		local pos2 = self.Ent:GetPos()
		
		self.CompassRot = -(math.deg(math.atan2((pos2.y - pos1.y), (pos2.x - pos1.x))) - yaw)
		self.LastRot = self.CompassRot
		self.CompassSpeed = 0
	end
	
	function PANEL:GetEntity()
		return self.Ent
	end
	
	function PANEL:SetColor(col)
		if type(col) == "nil" then
			self.Color = nil
		else
			self.Color = table.Copy(col)
		end
	end

	function PANEL:GetColor()
		return table.Copy(self.Color)
	end
	
	function PANEL:Paint(pw, ph)
		if not IsValid(self.Ent) then return end

		local yaw = EyeAngles().y
		local pos1 = EyePos()
		--circle color
		local r, g, b, a = 255, 255, 255, 255
		--pointer color
		local r2, g2, b2 = 0, 0, 0
		if self.Color then
			r, g, b, a = self.Color.r, self.Color.g, self.Color.b, self.Color.a
		elseif self.Ent.GetTeam then
			local col = team.GetColor(self.Ent:GetTeam())
			r, g, b, a = col.r, col.g, col.b, col.a
		end
		local pl = self.Ent:GetOwner()

		--make sure the flag icon isn't matching the panel color
		local teamcol, light = self:GetParent():GetSDMColor()
		local flaglight = (r + g + b) / 3 < 132
		--if it's basically the same color as the panel and not being carried, flip the colors
		if not IsValid(pl) and math.abs(r + g + b - teamcol.r - teamcol.g - teamcol.b) < 16 then
			r2 = r
			g2 = g
			b2 = b
			r = flaglight and 255 or 0
			g = r
			b = r
		else
			r2 = flaglight and 255 or 0
			b2 = r2
			g2 = r2
		end

		local w, h = self:GetSize()
		local dia = math.min(w, h)

		local pos2 = self.Ent:GetPos()
		surface.SetDrawColor(r, g, b, a)
		--local dist = pos2:Distance(pos1)
		surface.SetTexture(flagtex2)
		surface.DrawTexturedRectRotated(w / 2, h / 4, dia, dia, 0)
		--draw team icon below tracker
		if self.Ent.GetTeam and teamicon[self.Ent:GetTeam()] then
			surface.SetMaterial(teamicon[self.Ent:GetTeam()])
			surface.SetDrawColor(light and color_white or color_black)
			surface.DrawTexturedRect(w / 2 - dia / 4, h * 0.75 - dia / 2 + 1, dia / 2, dia / 2)
		end
		--draw arrow (we're not carrying it)
		if pl ~= GetViewEntity() then
			surface.SetDrawColor(r2, g2, b2, a)
			surface.SetTexture(flagtex)
			surface.DrawTexturedRectRotated(w / 2, h / 4, dia, dia, math.deg(math.atan2((pos2.y - pos1.y), (pos2.x - pos1.x))) - yaw)
		end
		--player is carrying flag, give it a border
		if pl:IsPlayer() then
			surface.SetTexture(flagtex3)
			local t = pl:Team()
			local col = team.GetColor(t)
			--our team, make it a highlight border
			if t == LocalPlayer():Team() then
				col = math.max(col.r + col.g + col.b) / 3 < 132 and color_white or color_black
			end
			--enemy team, give it their color
			if pl ~= LocalPlayer() and not team.IsReal(t) then
				local c = pl:GetPlayerColor()
				col = Color(c.r * 255, c.g * 255, c.b * 255, 255)
			end
			surface.SetDrawColor(col.r, col.g, col.b, col.a)
			surface.DrawTexturedRect(w / 2 - dia / 2, h / 4 - dia / 2, dia, dia)
			--inner ring (in case colors are opposites this inner ring will make sure things pop)
			surface.SetTexture(flagtex4)
			local c = flaglight and color_white or color_black
			surface.SetDrawColor(c, c, c, a)
			surface.DrawTexturedRect(w / 2 - dia / 2, h / 4 - dia / 2, dia, dia)
		end

		surface.SetDrawColor(255, 255, 255, 255)
	end
		
	vgui.Register("sdm_entpointer", PANEL)


local PANEL = {}
	PANEL.DoAutoPos = true
	PANEL.PointerHorizontalSpacing = 32
	PANEL.PointerVerticalSpacing = 16
	PANEL.PointerDiameter = 32
	
	function PANEL:Init()
		self.initialized = true
		self.Items = {}
		self.TitleLabel:Remove()
		self.TextLabel:Remove()
	end
	
	function PANEL:SetPointerDiameter(amt)
		self.PointerDiameter = amt
		self:AutoSize()
	end
	
	function PANEL:SetPointerHorizontalSpacing(amt)
		self.PointerHorizontalSpacing = amt
		self:AutoSize()
	end
	
	function PANEL:SetPointerVerticalSpacing(amt)
		self.PointerVerticalSpacing = amt
		self:AutoSize()
	end
	
	function PANEL:AutoSize()
		local mul = self.PointerHorizontalSpacing + self.PointerDiameter
		for k, v in ipairs(self.Items) do
			v:SetPos(self.PointerHorizontalSpacing + (k - 1) * mul, self.PointerVerticalSpacing / 2)
			v:SetSize(self.PointerDiameter, self.PointerDiameter * 2)
		end
		self:SetSize(self.PointerHorizontalSpacing + #self.Items * mul, self.PointerVerticalSpacing * 2 + self.PointerDiameter)
	end
	
	function PANEL:AutoPos()
		self:SetPos(ScrW() / 2 - self:GetWide() / 2, 12)
	end
	
	function PANEL:InvalidateLayout()
		if not self.initialized then
			return
		end

	end
	
	function PANEL:Clear()
		for k, v in ipairs(self.Items) do
			self.Items[k] = nil
			v:Remove()
		end
	end
	
	function PANEL:AddFlag(ent)
		local panel = vgui.Create("sdm_entpointer", self)
		panel:SetSize(self.PointerDiameter, self.PointerDiameter * 2)
		panel:SetEntity(ent)
		if ent.dt then
			panel:SetColor(team.GetColor(ent.dt.Team))
		end
		table.insert(self.Items, panel)
		self:AutoSize()
	end

	function PANEL:SetupFlags()
		self:Clear()
		for _, v in ipairs(ents.FindByClass("sdm_flag")) do
			self:AddFlag(v)
		end
		if self.DoAutoPos then	
			self:AutoPos()
		end
	end
	
	vgui.Register("sdm_flagtracker", PANEL, "sdm_playercolorhudbox")


local PANEL = {}
	PANEL.EndTime = 0
	PANEL.Title = "#scav.score.time"
	PANEL.Text = "#scav.scavcan.inf"
	PANEL.Wide = 128
	PANEL.Tall = 48

	function PANEL:Init()
		self:SetSize(self.Wide, self.Tall)
		self:SetTitle(self.Title)
		self:SetText(self.Text)
	end
	
	function PANEL:Think()
		local timeleft = (self.EndTime or 0) - CurTime()
		self:SetText(self.EndTime ~= 0 and string.FormattedTime(math.max(timeleft, 0), ScavLocalize("scav.score.time.format")) or "#scav.scavcan.inf")
	end
	
	function PANEL:SetEndTime(when)
		self.EndTime = when
	end
	
	function PANEL:GetEndTime()
		return self.EndTime
	end
	
	vgui.Register("sdm_timer", PANEL, "sdm_playercolorhudbox")
	

local function cap(c)
	return string.upper(c)
end

--default localization strings aren't capitalized, we want'em to be
local function camelCaseLocalize(token)
	local text = language.GetPhrase(token)
		text = string.gsub(text, "^(%a)", cap)
		text = string.gsub(text, "%s(%a)", cap)
		return text
end

local PANEL = {}
	PANEL.Title = "#armor"
	PANEL.Wide = 96
	PANEL.Tall = 48

	function PANEL:Init()
		self:SetSize(self.Wide, self.Tall)
		self:SetTitle(camelCaseLocalize("#armor"))
	end
	
	function PANEL:Think()
		self:SetText(IsValid(self.Player) and math.floor(self.Player:Armor()) or "0")
	end

	function PANEL:SetPlayer(pl)
		self.Player = pl
		self:PlayerColor()
	end
	
	function PANEL:GetPlayer()
		return self.Player
	end
	
	vgui.Register("sdm_armorpanel", PANEL, "sdm_playercolorhudbox")

local PANEL = {}
	PANEL.Player = NULL
	PANEL.Title = "#health"
	PANEL.Wide = 112
	PANEL.Tall = 48
	PANEL.Team = nil
	
	local white_bkg = Color(255, 255, 255, 24)
	local black_bkg = Color(0, 0, 0, 72)

	function PANEL:Init()
		self:SetSize(self.Wide, self.Tall)
		self:SetTitle(camelCaseLocalize("#health"))
		self:Flip()
	end
	
	function PANEL:Think()
		self:SetText(IsValid(self.Player) and self.Player:Health() or "0")
		if not IsValid(self.Player) or self.Player:Team() == self.Team then return end
		self.Team = self.Player:Team()
		--delay a frame so we don't flash another color out of sync with every other panel
		timer.Simple(0, function() if self then self:SetPlayer(self.Player) end end)
	end
	
	function PANEL:SetPlayer(pl)
		self.Player = pl
		self:PlayerColor()
		if not team.IsReal(self.Team) then return end

		if self.TeamIcon then self.TeamIcon:Remove() end
		local t = string.match(team.GetName(self.Team), "scav%.team%.([%a]+)")
		if not t then return end
		local tcol = team.GetColor(self.Team)

		self.TeamIcon = vgui.Create("DImage", self)
		self.TeamIcon:SetImage(t and ("hud/sdm/" .. t .. "_icon.png"))
			self.TeamIcon:SetSize(48, 48)
			self.TeamIcon:SetPos(11, 4 + self:GetTall() / 2 - self.TeamIcon:GetTall() / 2)
			self.TeamIcon:SetImageColor((tcol.r + tcol.g + tcol.b) / 3 < 132 and white_bkg or black_bkg)
			self.TeamIcon:SetVisible(true)
	end
	
	vgui.Register("sdm_healthpanel", PANEL, "sdm_armorpanel")


local PANEL = {}
	PANEL.Title = "#energy"
	PANEL.Wide = 72
	PANEL.Tall = 48

	function PANEL:Init()
		self:SetSize(self.Wide, self.Tall)
		self:SetTitle(camelCaseLocalize("#energy"))
	end
	
	function PANEL:Think()
		self:SetText(IsValid(self.Player) and math.floor(self.Player:GetEnergy()) or "0")
	end
	
	vgui.Register("sdm_energypanel", PANEL, "sdm_armorpanel")
	
local PANEL = {}
	PANEL.Title = "#score"
	PANEL.Wide = 112
	PANEL.Tall = 48

	function PANEL:Init()
		self:SetTitle(ScavLocalize("#scav.score", ""))
	end

	function PANEL:Think()
		local maxpoints = GAMEMODE:GetGNWShort("PointLimit")
		local points =  IsValid(self.Player) and tostring(math.floor(self.Player:Frags())) or "0"
		self:SetText(maxpoints ~= 0 and ScavLocalize("scav.points.format", points, maxpoints) or points)
	end
	
	vgui.Register("sdm_fragpanel", PANEL, "sdm_armorpanel")
	
local PANEL = {}
	PANEL.Title = "#paginate.next"
	PANEL.Wide = 128
	PANEL.Tall = 48

	function PANEL:Init()
		self:SetTitle("#scav.points.next")
		self:Flip()
	end

	function PANEL:Think()
		
		if IsValid(self.Player) and (self.Player:Team() ~= TEAM_SPECTATOR) then
			local sortedplayers = team.GetSortedPlayers(self.Player:Team())
			local place = 1
			for k, v in pairs(sortedplayers) do
				if v == self.Player then
					place = k
					break
				end
			end
			if place == 1 then
				--self:SetText(math.floor(team.GetScoreLimit(self.Player:Team()) - self.Player:Frags()))
				self:SetText("#scav.score.lead")
			else
				local nextpl = sortedplayers[place - 1]
				local text = math.floor(nextpl:Frags() - self.Player:Frags())
				if text == 0 then
					text = "#scav.score.tied"
				end
				self:SetText(text)
			end
		else
			self:SetText("0")
		end
	end
	
	vgui.Register("sdm_dm_fragsbehind", PANEL, "sdm_armorpanel")
	
	team.GetSortedPlayers(teamnum)
	
local PANEL = {}
	PANEL.TitleString = "Title"
	PANEL.TextString = "Text"
	function PANEL:Init()
		self.Title = vgui.Create("DLabel", self)
			self.Title:SetFont("Scav_MenuLarge")
		self.Text = vgui.Create("DLabel", self)
			self.Text:SetFont("DermaLarge")
		self.initialized = true
	end
	
	function PANEL:SetTitle(text)
		self.TitleString = text
		self.Title:SetText(text)
		self.Title:SizeToContents()
		self:InvalidateLayout()
	end

	function PANEL:SetText(text)
		self.TextString = text
		self.Text:SetText(text)
		self.Text:SizeToContents()
		self:InvalidateLayout()
	end
	
	function PANEL:InvalidateLayout()
		if not self.initialized then
			return false
		end
		self.Title:SetPos(self:GetWide() / 2 - self.Title:GetWide() / 2, 8)
		self.Text:SetPos(self:GetWide() / 2 - self.Text:GetWide() / 2, 16)
	end

	function PANEL:AutoPos()
		self:SetPos(ScrW() / 2 - self:GetWide() / 2, 0)
	end
	
vgui.Register("sdm_hudpanel2", PANEL, "DPanel")
