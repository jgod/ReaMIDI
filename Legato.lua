dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\legato.lua")

reaper.Undo_BeginBlock()
local target, notes=getTargetNotes(false, false)
legato(notes,false,false)
reaper.Undo_EndBlock("Legato", -1)
reaper.UpdateArrange()
