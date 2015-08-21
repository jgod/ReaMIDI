dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\smart-split-item.lua")

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

if #its>0 then
  for i=1,#its,1 do
    uberSplitItem(its[i],tpos,true, false, true)
  end
end
reaper.UpdateArrange()