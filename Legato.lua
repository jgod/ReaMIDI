dofile(reaper.GetResourcePath().."/Scripts/ReaMIDI/requires/midi-process.lua")


reaper.Undo_BeginBlock()
midiProcess("all","leg()","",true)
reaper.Undo_EndBlock("Legato", -1)
reaper.UpdateArrange()
