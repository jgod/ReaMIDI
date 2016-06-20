dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\midi.lua")

DBG("Running script")
DBG("-------------- ")


local t,events=getTargetEvents(types.all,false,false)


for i=1,#events,1 do 
  local e=events[i]
  DBG(e.e_type)
  if e.e_type==types.cc then 
    DBG("is a CC")    
    e.msg3=e.msg3*.5
    setEvent(e)
  end
  if e.e_type==types.note then
    _DBG=true
    DBG("Note...")
    it=reaper.GetMediaItemTake_Item(e.tk)
    sp=reaper.GetMediaItemInfo_Value(it, "D_POSITION")
    pqnppq=reaper.MIDI_GetProjQNFromPPQPos(e.tk, e.startpos_ppq)
    DBG("PQN from PPQ: "..pqnppq)
    DBG("Item start pos (secs): "..sp)
    so=reaper.GetMediaItemTakeInfo_Value(e.tk, "D_STARTOFFS")
    DBG("Take start offset: "..so)
    
    
    sqn=reaper.TimeMap2_timeToQN(0, sp)
    
    DBG("Item start pos (PQN): "..sqn)

    DBG("startpos_ppq = "..e.startpos_ppq)
    DBG("startpos pqn = "..e.startpos)
    DBG("measure startpos = "..e.meas_startpos)
    DBG("length = "..e.len)
    DBG("vel = "..e.vel)
    
    _DBG=false
    e.vel=e.vel*2
    e.len=e.len/2
    --setEvent(e)
  end
  if e.e_type==types.pitchbend then
    DBG("is a pitchbend") 
    DBG("Value: "..e.amount)
    e.amount=e.amount/2
    DBG("New Value: "..e.amount)
    setEvent(e)
  end
  if e.e_type==types.copyright then 
     DBG("is a copyright") 
     e.str="Hello string world!"
     e.startpos=6
     setEvent(e)
     DBG(e.str)
  end
  if e.e_type==types.lyric then 
     DBG("is a lyric")
     e.str="Oooh yeaah!"
     setEvent(e)
  end
end

reaper.UpdateArrange()
