-- more direct way to enter time signatures

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



function trimWs(s)
  return s:match "^%s*(.-)%s*$"
end


function string:split( inSplitPattern, outResults )
  if not outResults then
    outResults = { }
  end
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  while theSplitStart do
    table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( self, theStart ) )
  return outResults
end


function insertTimeSigs()
  ok,retvals=""
  ok, retvals=reaper.GetUserInputs("Insert time signatures",1,"Enter time sig(s): ","")
 
  retvals=trimWs(retvals)
  
  cur_time=reaper.GetCursorPosition()
  cur_qn=reaper.TimeMap_timeToQN(cur_time)
  measure=reaper.TimeMap_QNToMeasures(0,cur_qn)
  
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
  
  reaper.UpdateTimeline()
  return true
end



reaper.Undo_BeginBlock()
insertTimeSigs()
reaper.Undo_EndBlock("Insert Time Sigs", -1)

