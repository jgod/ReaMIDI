dofile(reaper.GetResourcePath().."/Scripts/ReaMIDI/requires/midi.lua")

_DBG=true
DBG("Running script")
DBG("-------------- ")


local t,events=getTargetEvents(types.all,false,false)


for i=1,#events,1 do 
  local e=events[i]
  DBG(e.e_type)
  
  if e.e_type==types.notation then
     DBG("is a notation thingy") 
     DBG(e.str)
     e.str="#!_Crescendo"
     setEvent(e)
  end  
end

reaper.UpdateArrange()
