-- Delete CCs in active take of MIDI editor
-- or selected items in arrange if MIDI editor closed
dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\target.lua")


function deleteCCs()
  local target,takes=getTargetTakes() --from target.lua
  
  for i=1,#takes,1 do
    local tk=takes[i]
    local ok=reaper.MIDI_GetCC(tk,0)
    if ok then reaper.MIDI_DeleteCC(tk,0) end
    while ok do
      ok=reaper.MIDI_GetCC(tk,0)
      reaper.MIDI_DeleteCC(tk,0)
    end
  end
end

reaper.Undo_BeginBlock()
deleteCCs()
reaper.Undo_EndBlock("Delete CCs",-1)
reaper.UpdateArrange()