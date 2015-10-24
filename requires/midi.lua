if _DEF_MIDI_~=true then
_DEF_MIDI_=true

-- places to hoover midi from
-- midi editor - active item, active track
-- arrange - current track
--           selected items, active take, selected track, current track
--           selected items
--           all

dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\class.lua")
dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\target.lua")

-- TODO:  14 bit support
-- 0-31 MSB  32-63 LSB 


-- 8 = Note Off
-- 9 = Note On
-- A = AfterTouch (ie, key pressure)
-- B = Control Change
-- C = Program (patch) change
-- D = Channel Pressure
-- E = Pitch Wheel
-- F = System common (0xF0 - 0xF7) / System realtime (0xF8- 0xFF)

types = {
  --text event types (these would normally have to have 0xFF in front of them, but don't need that here)
  text=0x01,
  copyright=0x02,
  sequence_track_name=0x03,
  instrument_name=0x04,
  lyric=0x05,
  marker=0x06,
  cue_point=0x07,
  
  --
  noteoff=0x80,
  noteon=0x90,
  aftertouch=0xA0,
  cc=0xB0,
  programchange=0xC0,
  chanpressure=0xD0,
  pitchbend=0xE0,
  sysex=-1, --message is 0xF0, but this is what MIDI_SetTextSysexEvt needs
  note=-2,
  all=-100
}


function DBG(dbg_msg)
  if _DBG==true then
    if dbg_msg==nil then dbg_msg="nil" end
    reaper.ShowConsoleMsg(dbg_msg.."\n")
  end
end


function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


function midicmp(a,b)
  if a.startpos ~= b.startpos then return a.startpos < b.startpos end
  return a.pitch > b.pitch
end

function midicmptype(a,b)
  if a.startpos ~= b.startpos then return a.startpos < b.startpos end
  return a.e_type > b.e_type
end


function bit_7to14(msb,lsb)
  local val=((msb<<7)+lsb)-0x1FFF
  return val
end


function bit_14to7(val)
  val=tonumber(val)+0x1FFF
  local msb=(val&0x3F80)>>7 
  local lsb=val&0x7F
  return msb, lsb
end


function bytesToString(bytes)
  local buf=string.rep(' ', #bytes)
  local i=0
  return (string.gsub(buf, '(.)', 
      function(c)
        i=i+1
        return string.char(bytes[i])
      end))
end


function setEvent(evt)
  local m=math
  if evt.e_type==types.cc then
    reaper.MIDI_SetCC(evt.tk, evt.idx, evt.sel, evt.mute,
                       reaper.MIDI_GetPPQPosFromProjQN(evt.tk, evt.startpos),
                       nil, evt.chan, m.floor(evt.msg2), m.floor(evt.msg3), true)
    return
  end
  if evt.e_type==types.note then 
    if evt.msg2~=nil then 
      evt.pitch=evt.msg2
    elseif evt.msg3~=nil then 
      evt.vel=evt.msg3 
   end
    reaper.MIDI_SetNote(evt.tk, evt.idx,evt.sel,evt.mute,
      reaper.MIDI_GetPPQPosFromProjQN(evt.tk, evt.startpos),
      reaper.MIDI_GetPPQPosFromProjQN(evt.tk, evt.startpos+evt.len),evt.chan,
      m.floor(evt.pitch),m.floor(evt.vel),nil)
    return
   end
   if evt.e_type==types.sysex or evt.e_type>0 and evt.e_type<=7 then
     reaper.MIDI_SetTextSysexEvt(evt.tk,evt.idx,evt.sel,evt.mute,
        reaper.MIDI_GetPPQPosFromProjQN(evt.tk, evt.startpos),
        nil, evt.str, true)
     return
   end
   if evt.e_type==types.pitchbend then
     local msg3, msg2=bit_14to7(math.floor(evt.amount))
     local msg=bytesToString({evt.e_type+evt.chan,msg2,msg3})
     reaper.MIDI_SetEvt(evt.tk,evt.idx,evt.sel,evt.mute,
               reaper.MIDI_GetPPQPosFromProjQN(evt.tk, evt.startpos),
               msg, true)
     return
   end
   if evt.e_type==types.aftertouch or evt.e_type==types.programchange or
        evt.e_type==types.chanpressure then
     local msg=bytesToString({evt.e_type+evt.chan,msg2,msg3})
     reaper.MIDI_SetEvt(evt.tk,evt.idx,evt.sel,evt.mute,
               reaper.MIDI_GetPPQPosFromProjQN(evt.tk, evt.startpos),
               msg, true)
     return
   end
end


function setEvents(evts)
  if evts~=nil then
    for i=#evts,1,-1 do
      setEvent(evts[i])
    end 
  end
end


--_DBG=true
function getEvents(types_tab, takes,sort,selected)
  local ni, tr, tr_num, it, tk
  local midi={}
  local midi_tk={}
  
  for i=1,#takes,1 do
    local cnt_e,cnt_n,cnt_cc,cnt_tsx=0,0,0,0
    tk=takes[i]
    local msg_sz=""
    local msg=""
    --CCs
    
    --notes
    local endpos,pitch,vel
    local ok, sel, mute, startpos, msg, msg_sz=reaper.MIDI_GetEvt(tk, cnt_e, true, true,1, msg)
    while ok do
      local chanmsg,chan,msg2,msg3,idx=nil,nil,nil,nil,nil
      idx=cnt_e
      DBG("Length of msg: "..string.len(msg))
      DBG(msg)
      local t=string.byte(msg:sub(1,1))
      DBG(t)
      local t2=string.byte(msg:sub(2,2))
      DBG(t2)
      local t3=string.byte(msg:sub(3,3))
      DBG(t3)
      chan=t&0x0F 
      if t&0xF0>=0x80 then
        DBG("Checking events")
        e_type=t&0xF0 
        if e_type==types.cc then
          DBG("isCC")
          ---[[ check for 14 bit here
          if cnt_cc>0 and lastcc==thiscc and 1~=1 then --.msg2-22 then
            --lastcc.is14bit=true
            --change last value to 14bit
            ok=false
          else
            ok,sel,mute,startpos,chanmsg,chan,msg2,msg3=reaper.MIDI_GetCC(tk,cnt_cc)
            idx=cnt_cc
            cnt_cc=cnt_cc+1
          end
        
        elseif e_type==types.pitchbend then
          DBG("isPB")
          DBG("Pitchbend  msg2: "..tonumber(t2).."  msg3: "..tonumber(t3))
          amount=bit_7to14(tonumber(t3),tonumber(t2))
          DBG("14 bit: ".. amount)
          
        elseif e_type==types.noteon then
          DBG("isNoteOn")
          e_type=types.note
          ok, sel, mute, startpos, endpos, chan, pitch, vel=reaper.MIDI_GetNote(tk, cnt_n)
          idx=cnt_n
          cnt_n=cnt_n+1
          endpos=reaper.MIDI_GetProjQNFromPPQPos(tk, endpos)
        end
      
      --text and sysex events here
      elseif e_type==0xF0 or (t>0 and t<=7) then
        DBG("isTextorSYSex")
        if t>0 and t<=7 then e_type=t end
        if t==0xF0 then e_type=types.sysex end
        --startpos returning 0 here
        ok, sel, mute, startpos, m_type, str=reaper.MIDI_GetTextSysexEvt(tk, cnt_tsx,
                                nil, nil, 0, nil, "")
        idx=cnt_tsx
        cnt_tsx=cnt_tsx+1 
      end
      
      startpos=reaper.MIDI_GetProjQNFromPPQPos(tk, startpos)
      local len
      if endpos~=nil then len=endpos-startpos end
      local meas, meas_startpos, meas_end=reaper.TimeMap_QNToMeasures(0,startpos)
      
      -- need to take -1 away from measure here for some reason
      local startpos_secs, _,_,num,denom,tempo=reaper.TimeMap_GetMeasureInfo(0, meas-1)
      local qnpm=num/(denom/4)
      
      --
      if meas_tolerance~=nil then
        if meas_end-startpos<meas_tolerance then
          local _,_,_,n,d,_=reaper.TimeMap_GetMeasureInfo(0, meas-1+1)  -- ^^ reminder in case of bug ^^
          num,denom=n,d
        end
      end
      
      tr=reaper.GetMediaItemTake_Track(tk)
      tr_num=reaper.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER")
      
      if ok and selected==false or (selected==true and sel==true) then 
        DBG("Adding event to list")
        
        local event={}
        event={       --all
                      e_type=e_type, track=tr, tk=tk, idx=idx, sel=sel, 
                      mute=mute, startpos=startpos, chan=chan,
                      meas_startpos=meas_startpos,
                      --mostly ccs
                      is14bit=is14bit, chanmsg=chanmsg, msg=msg, msg2=msg2, msg3=msg3, msg_sz=msg_sz,
                      --note specific
                      endpos=endpos, pitch=pitch, vel=vel,ts_num=num,ts_denom=denom,
                      len=len,qn_in_meas=qnpm,
                      --text/sysex
                      m_type=m_type, str=str,
                      --pitchbend
                      amount=amount}
                      
        midi[#midi+1]=event
        --event={}
      end
      cnt_e=cnt_e+1
      ok, sel, mute, startpos, msg, msg_sz=reaper.MIDI_GetEvt(tk, cnt_e, true, true,1, msg)
    end
    midi_tk[i]=deepcopy(midi)
    DBG("size of midi_tk (#events): "..#midi_tk[i])
    table.sort(midi_tk[i], midicmptype)
    DBG("size of midi_tk (#events): "..#midi_tk[i])
    midi={}
  end
  local nn=1
  for i=1,#midi_tk,1 do
    for ii=1,#midi_tk[i],1 do
      midi[nn]=midi_tk[i][ii]
      nn=nn+1
    end
  end
  if sort==true then table.sort(midi, midicmptype) end --this now sorts notes by pos/pitch irrespective of what take they are in
  return midi
end


local meas_tolerance=nil
function setMeasureTolerance(m)
  meas_tolerance=m
end


function getNotes(takes,sort,selected)
  local ni, tr, tr_num, it, tk
  local midi={}
  local midi_tk={}
  
  for i=1,#takes,1 do
    local cnt=0
    tk=takes[i]
    local ok, sel, mute, startpos, endpos, chan, pitch, vel=reaper.MIDI_GetNote(tk, 0)
    while ok do
      startpos=reaper.MIDI_GetProjQNFromPPQPos(tk, startpos)
      local meas, meas_startpos, meas_end=reaper.TimeMap_QNToMeasures(0,startpos)
      
      -- BUG?  Should we have to take 1 away to get correct time sig?
      local startpos_secs, _,_,num,denom,tempo=reaper.TimeMap_GetMeasureInfo(0, meas-1)
      
      local qnpm=num/(denom/4)
      endpos=reaper.MIDI_GetProjQNFromPPQPos(tk, endpos)
      
      -- *Probably don't do this*: change time-sig to next measure if note starts really close to it
      -- TODO:  have a bigger think about actual placement and intended, musical placement
      if meas_tolerance~=nil then
        if meas_end-startpos<meas_tolerance then
          local _,_,_,n,d,_=reaper.TimeMap_GetMeasureInfo(0, meas-1+1)  -- ^^ reminder in case of bug ^^
          num,denom=n,d
        end
      end
        
      tr=reaper.GetMediaItemTake_Track(tk)
      tr_num=reaper.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER")  
      --DBG("tr_num: "..tr_num.."\n") 
      if selected==false or (selected==true and sel==true) then 
        local note={ type=types.note, tr=tr, tr_num=tr_num, tk=tk, idx=cnt, meas=measure, meas_startpos=meas_startpos,beat=beat, 
                      ts_num=num,ts_denom=denom, qn_in_meas=qnpm, select=sel, mute=mute, ostartpos=startpos, startpos=startpos, endpos=endpos, len=endpos-startpos, 
                      pitch=pitch, select=sel, chan=chan, vel=vel }
        midi[#midi+1]=note
      end
      cnt=cnt+1
      ok, sel, mute, startpos, endpos, chan, pitch, vel=reaper.MIDI_GetNote(tk, cnt)      
    end
    midi_tk[i]=deepcopy(midi)
    table.sort(midi_tk[i], midicmp)
    midi={}
  end
  local nn=1
  for i=1,#midi_tk,1 do
    for ii=1,#midi_tk[i],1 do
      midi[nn]=midi_tk[i][ii]
      nn=nn+1
    end
  end
  if sort==true then table.sort(midi, midicmp) end --this now sorts notes by pos/pitch irrespective of what take they are in
  return midi
end


-- returns table of notes, from selected items if in the arrange view with 
-- notes sorted by take, position and pitch.
-- If MIDI Editor is active/focused it uses the active take and gets either
-- selected notes or all if none are selected
function getTargetNotes(sel_notes_in_arrange, sel_only_in_ME)
  local target, takes=getTargetTakes() --from target.lua
  local notes=getNotes(takes, false, (target==targets.MIDIEditor) or sel_notes_in_arrange)
  if target==targets.MIDIEditor and #notes==0 and not sel_only_in_ME then 
    notes=getNotes(takes, false, false)
  end
  return target, notes
end


function getTargetEvents(types_tab,sel_events_in_arrange, sel_only_in_ME)
  DBG("in getTargetEvents")
  local target, takes=getTargetTakes() --from target.lua
  local events=getEvents(types_tab, takes, false, (target==targets.MIDIEditor) or sel_events_in_arrange)
  if target==targets.MIDIEditor and #events==0 and not sel_only_in_ME then 
    events=getEvents(types_tab, takes, false, false)
  end
  DBG("about to exit getTargetEvents: "..#events)
  return target, events
end


function setNotes(notes)
  local n
  for i=1,#notes,1 do 
    n=notes[i]
    reaper.MIDI_SetNote(n.tk, n.idx,n.sel,n.mute,
      reaper.MIDI_GetPPQPosFromProjQN(n.tk, n.startpos),
      reaper.MIDI_GetPPQPosFromProjQN(n.tk, n.endpos),n.chan,
      n.pitch,n.vel,nil)
  end
end


-- get bunch of handy stuff, all in QN
function getProjectInfo()
  local startTS, endTS=reaper.GetSet_LoopTimeRange(nil, nil, nil, nil, nil)
  startTS, endTS=reaper.TimeMap2_timeToQN(0, startTS),
                 reaper.TimeMap2_timeToQN(0, endTS)
  return getCursorPositionQN(),startTS,endTS
end


function getCursorPositionQN()
  local tpos=reaper.GetCursorPosition()
  local cpqn=reaper.TimeMap2_timeToQN(0,tpos)
  return cpqn
end


function selectEvent(e,select)
  e.sel=select
  setEvent(e)
end


function deleteNotes(notes)
  local n
  for i=#notes,1,-1 do
    n=notes[i]
    reaper.MIDI_DeleteNote(n.tk, n.idx)
  end
end


function createItem(current_take, new_track, events)
  if #events==0 then DBG("No notes") return end
  local it=reaper.GetMediaItemTake_Item(current_take)
  local pos=reaper.GetMediaItemInfo_Value(it, "D_POSITION")
  local end_pos=pos+reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
  local cur_tr=reaper.GetMediaItemTrack(it)
  local ctr_num=reaper.GetMediaTrackInfo_Value(cur_tr, "IP_TRACKNUMBER")
  local dest_tr
  if reaper.CountTracks()>ctr_num then
    dest_tr=reaper.GetTrack(0,ctr_num)
  else
    reaper.InsertTrackAtIndex(ctr_num, false)
    dest_tr=reaper.GetTrack(0,ctr_num)
  end
  it=reaper.CreateNewMIDIItemInProj(dest_tr,pos,end_pos,false)
  tk=reaper.GetActiveTake(it)
  local e
  for i=1,#events,1 do
    e=events[i]
    if e.type==types.note then
      reaper.MIDI_InsertNote(tk,false,false,
              reaper.MIDI_GetPPQPosFromProjQN(e.tk, e.startpos),
              reaper.MIDI_GetPPQPosFromProjQN(e.tk, e.endpos),e.chan,
              e.pitch,e.vel,false)
    end
    --TODO: CCs n stuff.
  end
  --reaper.MIDI_Sort(tk)
end


--ifdef
end