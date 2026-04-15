
--[[---------------------------------------------------------
	PlayerColor Material Proxy
		Sets the clothing colour of custom made models to
		ent.GetPlayerColor, a normalized vector colour.
-----------------------------------------------------------]]

matproxy.Add( {
	name = "PlayerColor",

	init = function( self, mat, values )
		-- Store the name of the variable we want to set
		self.ResultTo = values.resultvar
	end,

	bind = function( self, mat, ent )
		if ( !IsValid( ent ) ) then return end

		-- If entity is a ragdoll try to convert it into the player
		-- ( this applies to their corpses )
		if ( ent:IsRagdoll() ) then
			local owner = ent:GetRagdollOwner()
			if ( IsValid( owner ) ) then ent = owner end
		end
		-- handles the world model
		if ( ent:IsWeapon() ) then
			local owner = ent:GetOwner()
			if ( IsValid( owner ) ) then ent = owner end
		end
		-- handles the view model
		if ( LocalPlayer():GetActiveWeapon() != NULL ) then
			local wep = LocalPlayer():GetActiveWeapon():EntIndex()
			if ( Entity(wep):GetWeaponViewModel() == ent:GetModel() ) then --this also gets spawned viewmodel props, not a huge issue though.
				local owner = LocalPlayer()
				if ( IsValid( owner ) ) then ent = owner end
			end
		end
		-- If the target ent has a function called GetPlayerColor then use that
		-- The function SHOULD return a Vector with the chosen player's colour.
		if ( ent.GetPlayerColor ) then
			local col = ent:GetPlayerColor()
			if ( isvector( col ) ) then
				mat:SetVector( self.ResultTo, col )
			end
		else
			mat:SetVector( self.ResultTo, Vector( 62 / 255, 88 / 255, 106 / 255 ) )
		end
	end
} )
