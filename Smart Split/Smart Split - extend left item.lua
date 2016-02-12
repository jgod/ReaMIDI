dofile(reaper.GetResourcePath().."/Scripts/ReaMIDI/requires/smart-split-item.lua")

local its={}
local itt
local tpos=reaper.GetCursorPosition()
local s=reaper.CountSelectedMediaItems(0)
if s>0 then
  for i=1,s,1 do
    itt=reaper.GetSelectedMediaItem(0,i-1)
    local pos=reaper.GetMediaItemInfo_Value(itt, "D_POSITION")
    local len=reaper.GetMediaItemInfo_Value(itt, "D_LENGTH")
    if tpos>pos and tpos<(pos+len) then
      its[#its+1]=itt
    end
  end
end


reaper.Undo_BeginBlock()
if #its>0 then
  for i=1,#its,1 do
    uberSplitItem(its[i],tpos, 
      0.0, -- this is the time (in QN) before the split point it will catch early notes and get
           -- them into the right item (ie split earlier than the cursor)
           -- ps, use relative snap in Reaper if you use this
      true, -- true/false:  do you want to extend the left item so that all notes play after split?
      false, -- leave left item selected after split
      true   -- leave right item selected after split
      )
  end
end
reaper.Undo_EndBlock("Smart Split - extend left item", -1)
reaper.UpdateArrange()