-- Thin out CCs in active take of MIDI editor
-- or selected items in arrange if MIDI editor closed
dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\class.lua")
dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\target.lua")

local ccs={}

local CC = class(
  function(self,track,take,selected,muted,ppqpos,chanmsg,chan,msg2,msg3)
    self.track=track
    self.take=take
    self.selected=selected
    self.muted=muted
    self.ppqpos=ppqpos
    self.chanmsg=chanmsg
    self.chan=chan
    self.msg2=msg2
    self.msg3=msg3
  end 
)

local target,takes=getTargetTakes() --from target.lua

local prev_cc
for i=1,#takes,1 do
  local tk=takes[i]
  local ok,selected,muted,ppqpos,chanmsg,chan,msg2,msg3=reaper.MIDI_GetCC(tk,0)
  local ccn=1
  while ok do
    prev_cc=CC(tr,tk,selected,muted,ppqpos,chanmsg,chan,msg2,msg3)
    ok,selected,muted,ppqpos,chanmsg,chan,msg2,msg3=reaper.MIDI_GetCC(tk,ccn)
    if (chan==prev_cc.chan and msg2==prev_cc.msg2 and msg3==prev_cc.msg3) then
      reaper.MIDI_DeleteCC(tk,ccn)
    else
      prev_cc=CC(tr,tk,selected,muted,ppqpos,chanmsg,chan,msg2,msg3)
      ccn=ccn+1
    end
  end
end

reaper.UpdateArrange()