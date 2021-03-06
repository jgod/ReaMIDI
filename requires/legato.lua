dofile(reaper.GetResourcePath().."/Scripts/ReaMIDI/requires/midi.lua")


local prev_note, cur_note
local flex=0.25 -- amount of difference to allow between note start positions
                 -- without legato shortening (in QN)
local overlap=0

local notes_to_stretch={}

function setNotesEdges(nts,position,start_not_finish)
  DBG("setNotesEdges")
  for i=1,#nts,1 do
    local n=nts[i]
    if start_not_finish~=true then
      n.endpos=position
    else
      n.startpos=position
    end
    setNotes(nts)
  end
  DBG("\n")
end

function stretchNotes(nts,position,l_note_end)
  local diff=position-l_note_end
  for i=1,#nts,1 do
    local n=nts[i]
    n.endpos=n.endpos+diff
    --reaper.MIDI_SetNote(n.tk, n.idx,nil,nil,nil,
    --        reaper.MIDI_GetPPQPosFromProjQN(n.tk, n.endpos+diff),nil,nil,nil,true)
    setNotes(nts)
  end
end

function notesToNoteItemEdge(nts,note,stretch_to_start,stretch_to_end)
  local it=reaper.GetMediaItemTake_Item(note.tk)
  local pos=reaper.GetMediaItemInfo_Value(it, "D_POSITION")
  local s_pos=reaper.TimeMap2_timeToQN(0, pos)
  if stretch_to_end==true then 
    pos=s_pos+reaper.TimeMap2_timeToQN(0,reaper.GetMediaItemInfo_Value(it, "D_LENGTH"))
    setNotesEdges(nts, pos,false)
  end
  if stretch_to_start==true then
    DBG("Stretching to start: "..s_pos)
    setNotesEdges(nts,s_pos,true)
  end
end

function reset_list()
  notes_to_stretch={}
  notes_to_stretch[1]=cur_note
  prev_note=cur_note
end


function legato(notes, stretch_to_start,stretch_to_end)
  DBG("#notes: "..#notes)
  local l_note_end=0 --longest note, use to preserve relative lengths
  if #notes==1 then notesToNoteItemEdge({notes[1]},notes[1],stretch_to_start,stretch_to_end) return end
  
  if #notes>1 then
    notes_to_stretch[1]=notes[1]
    first_notes=true --keep track of first batch of notes per take, to stretch to start if required
    prev_note=notes[1]
    l_note_end=prev_note.endpos
    for i=2,#notes,1 do
      cur_note=notes[i]
      if cur_note.startpos>=prev_note.startpos+flex and prev_note.tk==cur_note.tk then
        stretchNotes(notes_to_stretch,cur_note.startpos+overlap,l_note_end)
        l_note_end=cur_note.endpos
        if first_notes==true and stretch_to_start==true then
          notesToNoteItemEdge(notes_to_stretch,cur_note,true,false)
          
          first_notes=false
        end
        reset_list()
      else
        if prev_note.tk~=cur_note.tk then
          notesToNoteItemEdge(notes_to_stretch,prev_note,(first_notes and stretch_to_start),stretch_to_end)
          reaper.MIDI_Sort(prev_note.tk)
          first_notes=true --reset on new take
          reset_list()
        else
          notes_to_stretch[#notes_to_stretch+1]=cur_note
          if cur_note.endpos>l_note_end then l_note_end=cur_note.endpos end
          prev_note=cur_note
        end
      end
    end
    --process notes_to_stretch at end of list
    DBG("#notes_to_stretch: "..#notes_to_stretch)
    notesToNoteItemEdge(notes_to_stretch,notes_to_stretch[1],(first_notes and stretch_to_start),stretch_to_end)
    reaper.MIDI_Sort(notes_to_stretch[1].tk)
  end
end
