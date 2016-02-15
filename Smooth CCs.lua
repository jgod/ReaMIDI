-- Smooth CCs in active take of MIDI editor
-- or selected items in arrange if MIDI editor closed
dofile(reaper.GetResourcePath().."/Scripts/ReaMIDI/requires/class.lua")
dofile(reaper.GetResourcePath().."/Scripts/ReaMIDI/requires/target.lua")

function DBG(dbg_msg)
  if _DBG==true then
    if dbg_msg==nil then dbg_msg="nil" end
    reaper.ShowConsoleMsg(dbg_msg.."\n")
  end
end

_DBG=false


local ccs={}

local CC = class(
  function(self,track,ccn,take,selected,muted,ppqpos,chanmsg,chan,msg2,msg3)
    self.track=track
    self.ccn=ccn
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



boxFIR = class(
    function(self, numCoeffs)
      self.numCoeffs=numCoeffs -- must be >0
      self.b={} --Filter coefficients
      self.m={} --Filter memories
      if self.numCoeffs<1 then self.numCoeffs=1 end
      local val=1/self.numCoeffs
      for i=1,self.numCoeffs,1 do
        self.b[i]=val
        self.m[i]=0
      end
    end 
)

function boxFIR:filter(a)
  local output
  DBG(#a)
  for nn=1,#a,1 do
    --apply smoothing filter to signals
    output=0
    self.m[1]=a[nn]
    for ii=1,self.numCoeffs,1 do
      output=output+(self.b[ii]*self.m[ii])
    end
    
    -- reshuffle memories
    for ii=self.numCoeffs-1,1,-1 do
      self.m[ii+1]=self.m[ii]
    end
    a[nn]=output
  end
  return a
end



local target,takes=getTargetTakes() --from target.lua

local bF=boxFIR(3)
for i=1,#takes,1 do
  local tk=takes[i]
  ccs={}
  local ok,selected,muted,ppqpos,chanmsg,chan,msg2,msg3=reaper.MIDI_GetCC(tk,0)
  
  local ccn=0
  if selected then
    ccs[#ccs+1]=CC(tr,ccn,tk,selected,muted,ppqpos,chanmsg,chan,msg2,msg3)
  end
  
  while ok do
    ccn=ccn+1
    ok,selected,muted,ppqpos,chanmsg,chan,msg2,msg3=reaper.MIDI_GetCC(tk,ccn)
    if selected then
      ccs[#ccs+1]=CC(tr,ccn,tk,selected,muted,ppqpos,chanmsg,chan,msg2,msg3)
    end
    
  end
  DBG(#ccs)
  a={}
  for i=1,#ccs,1 do
    a[i]=ccs[i].msg3
  end
  DBG(#a)
  a=bF:filter(a)
  for i=1,#ccs,1 do
    cc=ccs[i]
    DBG("Orig CC: "..cc.msg3)
    DBG("New CC: "..a[i])
    reaper.MIDI_SetCC(tk, cc.ccn-1, nil, nil, nil, nil, nil, nil, math.floor(a[i]), nil)
  end   
end

reaper.UpdateArrange()