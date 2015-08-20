_DEF_MIDI_=true

-- places to hoover midi from
-- midi editor - active item, active track
-- arrange - current track
--           selected items, active take, selected track, current track
--           selected items
--           all

if _DEF_CLASS_==nil then dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\class.lua") end
if _DEF_TARGET_==nil then dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\target.lua") end


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
  sysex=0xF0,
  note=-1
}


function DBG(msg)
  --reaper.ShowConsoleMsg(msg.."\n")
end

function midicmp(a,b)
  if a.startpos ~= b.startpos then return a.startpos < b.startpos end
  return a.pitch > b.pitch
end  

function getEvents(takes)
  local ni, tr, it, tk
  local midi={}
  local e_cnt,n_cnt,c_cnt=0
  for i=1,#takes,1 do
    tk=takes[i]
    local msg_sz=""
    local msg=""
    local ok, sel, mute, startpos, msg, msg_sz=reaper.MIDI_GetEvt(tk, e_cnt, true, true,1, msg)
    while ok do
      local t=string.byte(msg:sub(1,1))
      local t1=string.byte(msg:sub(2,2))
      
      if t1~=nil then
        --
      end
     
      t=t&0xF0
      if t~=0xF0 then chan=t&0x0F end

      local event={ type=t, track=tr, take=tk, idx=e_cnt, select=sel, mute=mute, startpos=startpos,
                    msg=msg, msg_sz=msg_sz}
      midi[#midi+1]=event
      e_cnt=e_cnt+1
      ok, sel, mute, startpos, msg, msg_sz=reaper.MIDI_GetEvt(tk, e_cnt, true, true,1, msg)
    end
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
      local startpos_secs, _,_,num,denom,tempo=reaper.TimeMap_GetMeasureInfo(0, meas)
      local qnpm=num/(denom/4)
      endpos=reaper.MIDI_GetProjQNFromPPQPos(tk, endpos)
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
    DBG("#midi_tk: "..#midi_tk[i].."\n")
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
function getTargetNotes()
  local target, takes=getTargetTakes() --from target.lua
  local notes=getNotes(takes, false, (target==targets.MIDIEditor))
  if target==targets.MIDIEditor and #notes==0 then 
    notes=getNotes(takes, false, false)
  end
  return target, notes
end


function setNotes(notes)
  local n
  for i=1,#notes,1 do 
    n=notes[i]
    reaper.MIDI_SetNote(n.tk, n.idx,n.sel,n.mute,
      reaper.MIDI_GetPPQPosFromProjQN(n.tk, n.startpos),
      reaper.MIDI_GetPPQPosFromProjQN(n.tk, n.endpos),n.chan,
      n.pitch,n.vel,nil,true)
  end
end


function getCursorPositionQN()
  local tpos=reaper.GetCursorPosition()
  local cpqn=reaper.TimeMap2_timeToQN(0,tpos)
  return cpqn
end


function selectEvent(e,select)
  e.select=select
  if e.type==types.note then
    reaper.MIDI_SetNote(e.tk, e.idx,e.select,e.mute,
      reaper.MIDI_GetPPQPosFromProjQN(e.tk, e.startpos),
      reaper.MIDI_GetPPQPosFromProjQN(e.tk, e.endpos),e.chan,
      e.pitch,e.vel,nil)
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
      DBG("Type=note")
      reaper.MIDI_InsertNote(tk,false,false,
              reaper.MIDI_GetPPQPosFromProjQN(e.tk, e.startpos),
              reaper.MIDI_GetPPQPosFromProjQN(e.tk, e.endpos),e.chan,
              e.pitch,e.vel,false)
    end
    --TODO: CCs n stuff.
  end
  --reaper.MIDI_Sort(tk)
end