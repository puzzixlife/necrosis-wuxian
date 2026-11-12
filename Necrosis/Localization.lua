--[[
    Necrosis LdC
    Copyright (C) 2005-2008  Lom Enfroy

    This file is part of Necrosis LdC.

    Necrosis LdC is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    Necrosis LdC is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Necrosis LdC; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
--]]

------------------------------------------------------------------------------------------------------
-- Necrosis LdC
-- Par Lomig (Kael'Thas EU/FR) & Tarcalion (Nagrand US/Oceanic) 
-- Contributions deLiadora et Nyx (Kael'Thas et Elune EU/FR)
--
-- Skins et voix Françaises : Eliah, Ner'zhul
--
-- Version Allemande par Geschan
-- Version Espagnole par DosS (Zul’jin)
-- Version Russe par Komsomolka
--
-- Version $LastChangedDate$
------------------------------------------------------------------------------------------------------

-- 无限客户端：GetAddOnMetadata 已迁移到 C_AddOns，且可能返回 nil，全部兑底
local function GetAddonMeta(field)
	if C_AddOns and C_AddOns.GetAddOnMetadata then
		local ok, value = pcall(C_AddOns.GetAddOnMetadata, "Necrosis", field)
		if ok and value then
			return value
		end
	end
	if GetAddOnMetadata then
		local ok, value = pcall(GetAddOnMetadata, "Necrosis", field)
		if ok and value then
			return value
		end
	end
	return nil
end

Necrosis = {}

Necrosis.Data = {
	Version = GetAddonMeta("Version") or "3.1-wuxian",
	AppName = "Necrosis LdC",
	LastConfig = 20101112
}
Necrosis.Data.Label = Necrosis.Data.AppName.." "..tostring(Necrosis.Data.Version)

Necrosis.Speech = {}
Necrosis.Unit = {}
Necrosis.Translation = {}

Necrosis.Config = {}
