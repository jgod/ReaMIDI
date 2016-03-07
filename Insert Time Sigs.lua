dofile(reaper.GetResourcePath().."/Scripts/ReaMIDI/requires/tempo-time-sigs.lua")

-- inserts time signatures at current cursor position (measure)

-- v1.1 - 22 July 2015 - added ':' sections

-- example inputs:

-- 3/4
-- will enter 3/4 time sig at current tempo at current cursor position (nearest measure)

-- 3/4,6/8
-- puts 3/4 at current cursor position (nearest measure) and 6/8 at next measure

-- 3/4>3,6/8
-- 3/4 at current position, 6/8 three measures later.

-- 3/4>3,6/8*200
-- same as before, but pattern repeated 200 times

-- 3/4>3,6/8*100 : 4/4>3,3/4 : 3/4>3,6/8*100
-- add different sections by separating with a colon


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
  --set original time sig if different and there isn't a time sig change
  local fts=#tempo_time_markers>0 and tempo_time_markers[#tempo_time_markers] or nil
  if (n~=s_timesig_num or d~=s_timesig_denom) and fts~=nil then
    DBG("fts.measurepos-"..fts.measurepos)
    if fts.measurepos>start_measure then
      --boolean reaper.SetTempoTimeSigMarker(ReaProject proj, integer ptidx, number timepos, integer measurepos, number beatpos,
                   -- number bpm, integer timesig_num, integer timesig_denom, boolean lineartempo)

      reaper.SetTempoTimeSigMarker(0,-1,-1,measure-1,0,s_tempo,s_timesig_num,s_timesig_denom,false)
    end
  end
  
  restoreTimeSigsFromCurrentPos(measure-start_measure)
  
  reaper.UpdateTimeline()
  return true
end


reaper.Undo_BeginBlock()
insertTimeSigs()
reaper.Undo_EndBlock("Insert Time Sigs", -1)