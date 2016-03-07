dofile(reaper.GetResourcePath().."/Scripts/ReaMIDI/requires/tempo-time-sigs.lua")

function insertTimeSigs()
  ok,retvals=""
  ok, retvals=reaper.GetUserInputs("Insert time signatures",1,"Enter time sig(s): ","")
 
  retvals=trimWs(retvals)
  
  local cur_time,cur_qn,measure=getCurrentPositions()

  
  storeAndRemoveTimeSigsFromCurrentPos(cur_time)
  
  sections=retvals:split(":")
  for i=1,#sections,1 do
    retvals=sections[i]
    ret_reps=retvals:split("*")
    local reps
    if #ret_reps>1 then reps=ret_reps[2] end
    if not(tonumber(reps)~=nil and reps%1==0) then
      reps=nil
    end
    retvals=ret_reps[1]
    ret_tab=retvals:split(",")
    
    if reps~=nil then 
      reps=tonumber(reps)
      if reps>500 or reps<1 then reps=1 end --some sensible limits
    else
      reps=1
    end
    
    start_measure=measure
    _, _, _, s_timesig_num, s_timesig_denom, s_tempo=reaper.TimeMap_GetMeasureInfo(0, start_measure)
    
    for i=1,reps,1 do
      for k, v in pairs(ret_tab) do
      local temp={}
      temp=v:split(">")
      if #temp>1 then measure_skip=math.min(tonumber(temp[2]),500) else measure_skip=1 end
        local timesig=temp[1]
        timesig=timesig:split("/")
        n=timesig[1]  
        d=timesig[2]
        if (tonumber(n)~=nil and n%1==0 and tonumber(d)~=nil and d%1==0) then
          cur_time=reaper.TimeMap_GetMeasureInfo(0,measure-1)
          reaper.SetTempoTimeSigMarker(0,-1,cur_time,-1,-1,0,n,d,false)
          measure=measure+measure_skip
        end
      end
    end
  end
  
  
 --reaper.TimeMap_GetMeasureInfo(0,measure-1)
  --set original time sig if different
  local fts=#tempo_time_markers>0 and tempo_time_markers[#tempo_time_markers] or nil
  if (n~=timesig_num or d~=timesig_denom) and fts~=nil then
    DBG("fts.measurepos-"..fts.measurepos)
    if fts.measurepos>measure-1 then
      cur_time=reaper.TimeMap_GetMeasureInfo(0,measure-1)
      
      --boolean reaper.SetTempoTimeSigMarker(ReaProject proj, integer ptidx, number timepos, integer measurepos, number beatpos,
                   -- number bpm, integer timesig_num, integer timesig_denom, boolean lineartempo)

      reaper.SetTempoTimeSigMarker(0,-1,-1,start_measure,0,s_tempo,s_timesig_num,s_timesig_denom,false)
    end
  end
  
  restoreTimeSigsFromCurrentPos(measure-start_measure)
  
  reaper.UpdateTimeline()
  return true
end


reaper.Undo_BeginBlock()
insertTimeSigs()
reaper.Undo_EndBlock("Insert Time Sigs", -1)