--  
--  Live MIDI Delete
--
--
--  Script that deletes MIDI notes based on differences in content over time
--  
--  It works in the MIDI editor, or if the MIDI editor is not open and active
--  it takes the first selected track that is record armed and has an item
--  with a start position the same as the start loop point.
--
--  So you can loop record anywhere, which is what it's for.
--
--  To use:
--  1) Record some notes
--  2) Trigger this action
--  3) Play notes you want to delete and
--  4) Trigger this action again
--
--  2 and 4 have to be done within 1.5 seconds of each other otherwise the
--  action resets, for safety reasons.
--
--  If you triple trigger the action within 1/3 second it deletes all notes
--  from the current take.


-- vvvv we need this vvvv
-- if anyone wants to use this, remember we can't pickle Lua userdata
-- ie, any of the Reaper specific pointers to Track, Item, Take n stuff

----------------------------------------------
-- Pickle.lua
-- A table serialization utility for lua
-- Steve Dekorte, http://www.dekorte.com, Apr 2000
-- (updated for Lua 5.3 by me)
-- Freeware
----------------------------------------------

function pickle(t)
  return Pickle:clone():pickle_(t)
end

Pickle = {
  clone = function (t) local nt={}; for i, v in pairs(t) do nt[i]=v end return nt end 
}

function Pickle:pickle_(root)
  if type(root) ~= "table" then 
    error("can only pickle tables, not ".. type(root).."s")
  end
  self._tableToRef = {}
  self._refToTable = {}
  local savecount = 0
  self:ref_(root)
  local s = ""
  
  while #self._refToTable > savecount do
    savecount = savecount + 1
    local t = self._refToTable[savecount]
    s = s.."{\n"
    
    for i, v in pairs(t) do
        s = string.format("%s[%s]=%s,\n", s, self:value_(i), self:value_(v))
    end
    s = s.."},\n"
  end

  return string.format("{%s}", s)
end

function Pickle:value_(v)
  local vtype = type(v)
  if     vtype == "string" then return string.format("%q", v)
  elseif vtype == "number" then return v
  elseif vtype == "boolean" then return tostring(v)
  elseif vtype == "table" then return "{"..self:ref_(v).."}"
  else error("pickle a "..type(v).." is not supported")
  end  
end

function Pickle:ref_(t)
  local ref = self._tableToRef[t]
  if not ref then 
    if t == self then error("can't pickle the pickle class") end
    table.insert(self._refToTable, t)
    ref = #self._refToTable
    self._tableToRef[t] = ref
  end
  return ref
end

----------------------------------------------
-- unpickle
----------------------------------------------

function unpickle(s)
  if type(s) ~= "string" then
    error("can't unpickle a "..type(s)..", only strings")
  end
  local gentables = load("return "..s)
  local tables = gentables()
  
  for tnum = 1, #tables do
    local t = tables[tnum]
    local tcopy = {}; for i, v in pairs(t) do tcopy[i] = v end
    for i, v in pairs(tcopy) do
      local ni, nv
      if type(i) == "table" then ni = tables[i[1]] else ni = i end
      if type(v) == "table" then nv = tables[v[1]] else nv = v end
      t[i] = nil
      t[ni] = nv
    end
  end
  return tables[1]
end

local cnt=0

function isSameNote(n1,n2)
  local n1sp=math.floor(n1.startpos*10000)  -- prevent not matching because
  local n2sp=math.floor(n2.startpos*10000)  -- of precision
  return (n1.chan==n2.chan and n1.pitch==n2.pitch and
           n1sp==n2sp)
end

local tk=nil

function deletePitch(pitch, chan)
   notes=getNotes(tk)
   if #notes==0 then return false end
   local found=false
   local i=#notes
   while i>0 do
     if notes[i].pitch==pitch and notes[i].chan==chan then
       reaper.MIDI_DeleteNote(tk,notes[i].idx)
       found=true
     end
     i=i-1
   end
end

function deleteAllNotes(take)
  local ok, sel, mute, startpos, endpos, chan, pitch, vel=reaper.MIDI_GetNote(tk, 0)
  while ok do
    reaper.MIDI_DeleteNote(take,0)
    ok, sel, mute, startpos, endpos, chan, pitch, vel=reaper.MIDI_GetNote(tk, 0)
  end
end
 
 -- this tidy function and any remaining tidy bits of the following
 -- one bushwacked from Schwa - thanks Schwa!   
function midicmp(a,b)
  if a.startpos ~= b.startpos then return a.startpos < b.startpos end
  return a.pitch > b.pitch
end

function getNotes(tk)
  local ni, tr, it
  local midi={}
  cnt=0
  local ok, sel, mute, startpos, endpos, chan, pitch, vel=reaper.MIDI_GetNote(tk, 0)
  while ok do
    startpos=reaper.MIDI_GetProjQNFromPPQPos(tk, startpos)
    endpos=reaper.MIDI_GetProjQNFromPPQPos(tk, endpos)
    local note={ type="note", idx=cnt, -- 6
                 select=sel,mute=mute, ostartpos=startpos, --12
                  startpos=startpos, endpos=endpos, len=endpos-startpos, 
                  pitch=pitch, chan=chan, vel=vel }
    midi[#midi+1]=note
    cnt=cnt+1
    ok, sel, mute, startpos, endpos, chan, pitch, vel=reaper.MIDI_GetNote(tk, cnt)      
  end

  --table.sort(midi, midicmp)  
  return midi
end

function dbg(msg)
  reaper.ShowConsoleMsg(msg)
  reaper.ShowConsoleMsg("\n")
end


function liveMIDIDelete()
  local last_note
  local trigger_time=os.clock()
  local state_name="Laz___Delete_Last_ME_8HEIF77676SDY"
  local key="state_table"
  local notes=nil
  
  local ame=reaper.MIDIEditor_GetActive()
  local mode=reaper.MIDIEditor_GetMode(ame)
  
  if mode > -1 then -- we are in a MIDI editor, -1 if ME not focused
    tk=reaper.MIDIEditor_GetTake(ame)
  else -- get rec armed, selected track
    local tr=reaper.GetSelectedTrack(0,0)
    local _,t_name=reaper.GetSetMediaTrackInfo_String(tr,"P_NAME"," ",false)
    local _, ts=reaper.GetTrackState(tr)
    if ts&64==64 and ts&2==2 then -- is rec armed and selected
      local num_items=reaper.CountTrackMediaItems(tr)
      if num_items>0 then
        local l_start,l_end=reaper.GetSet_LoopTimeRange(false,true,0,0,true)
        local cur=reaper.GetCursorPosition()
        local i=1
        while i<=num_items do
           local it=reaper.GetTrackMediaItem(tr,i-1)
           local i_start=reaper.GetMediaItemInfo_Value(it,"D_POSITION")
           if math.floor(l_start*10)==math.floor(i_start*10) then
             tk=reaper.GetActiveTake(it)
             i=num_items
           end
           i=i+1
        end
      end
    end
  end
  
  if tk~=nil then
    notes=getNotes(tk)
    state={prev_time=0, time=trigger_time, count= cnt, notes=notes}
    
    -- uncomment and run once if we change any saved state stuff
    --reaper.DeleteExtState(state_name,key,false)
    
    if reaper.HasExtState(state_name,key) then
      state=unpickle(reaper.GetExtState(state_name,key))
    else
      reaper.SetExtState(state_name,key,pickle(state),false)
    end
    
    --if a triple click...
    if os.clock()-state.prev_time < 0.33 then
      deleteAllNotes(tk)
      return
    end
    
    -- do this if less than 1.5 seconds has passed since
    -- last run, to avoid accidental deletion n stuff
    et=os.clock()-state.time
    if et < 1.5 and et > 0.2 then
      if notes~=state.notes then
        local diffs={}
        local sn=state.notes
        local csn, cn, is_matched
        for i=1,#notes,1 do
          is_matched=false
          cn=notes[i]
          for ii=1,#sn,1 do
            csn=sn[ii]
            if isSameNote(cn,csn) then
              is_matched=true
            end
          end
          if is_matched==false then 
            diffs[#diffs+1]=cn
          end
        end
       
        if #diffs>0 then
          for i=1,#diffs,1 do
            local d=diffs[i]
            deletePitch(d.pitch,d.chan)
          end
          diffs={}
        end     
      end
    end
    
    state.prev_time=state.time
    state.time=os.clock()
    state.count=cnt
    state.notes=notes
    reaper.SetExtState(state_name,key,pickle(state),false)
  end
end

reaper.Undo_BeginBlock()
liveMIDIDelete()
reaper.UpdateArrange()
reaper.Undo_EndBlock("Live MIDI Delete", -1)

