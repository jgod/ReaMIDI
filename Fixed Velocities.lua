dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\midi.lua")

local target, notes=getTargetNotes(false, false)


function fixedVelocities()
  DBG("#notes: "..#notes)
  local n --faster than doing it inside the loop
  for i=1,#notes,1 do 
    n=notes[i]
    n.vel=100
  end
  setNotes(notes)
end


reaper.Undo_BeginBlock()
fixedVelocities()
reaper.Undo_EndBlock("Fixed Velocities", -1)
reaper.UpdateArrange()
  