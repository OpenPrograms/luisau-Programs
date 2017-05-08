--------------------------------------------------------------------------------
-- lscomp v0.1 A program to monitor a Draconic Evolution Energy Core.
-- Copyright (C) 2017 by Luisau  -  luisau.mc@gmail.com
-- 
--    This program is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--    
--    This program is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with this program.  If not, see <http://www.gnu.org/licenses/>
--
-- For Documentation and License see
--  /usr/share/doc/lscomp/README.md
--  
-- Repo URL:
-- https://github.com/OpenPrograms/luisau-Programs/tree/master/src/lscomp
--------------------------------------------------------------------------------

local component = require ("component")
function printComponentList ()
  for k, v in component.list() do
    print ("  ".. v, k)
  end
  print()
end

printComponentList ()