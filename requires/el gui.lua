dofile(reaper.GetResourcePath().."/Scripts/ReaMIDI/requires/class.lua")
dofile(reaper.GetResourcePath().."/Scripts/ReaMIDI/requires/pickle.lua")
dofile(reaper.GetResourcePath().."/Scripts/ReaMIDI/requires/strings.lua")


function DBG(str)
  ---[[
  if str==nil then str="--nil value/string--" end
  if type(str)=="boolean" then
    if str==true then str="true" else str="false" end
  end
  if type(str)=="table" then
    DBG("Table Contents:")
    for k,v in pairs(str) do
      DBG("Key:"..k)
      DBG(v)
    end
  else
    reaper.ShowConsoleMsg(str.."\n")
  end
  --]]
end

LGUI={}

LGUI.position={
  top=1,
  bottom,
  inside,
  left,
  right
}


-- 'static' stuff so '.' not ':'
LGUI.controlled_idx=nil 
LGUI.controls={}
LGUI.state_name=""
LGUI.idx=1
LGUI.clipboard=""
LGUI.edit_mode=false
LGUI.states={}
LGUI.timer=8 --number of periods to wait before doing non time-critical stuff
LGUI.countdown=LGUI.timer
LGUI.current_project=reaper.EnumProjects(-1,"")
LGUI.exit_script=false
LGUI.mainFunction=nil


function LGUI.setMainFunction(func)
  LGUI.mainFunction=func
end


function LGUI.init(name,w,h,dock_state,main_init)
   --LGUI.deleteStates()                      -- uncomment to reset ext states!!!!
   LGUI.main_init=main_init
   LGUI.init=true
   LGUI.w,LGUI.h=w,h
   LGUI.script_name=name
   LGUI.state_name="I8bE"..string.gsub(name,"%s","")
   reaper.SetProjExtState(0,LGUI.state_name, "init","init")
   gfx.init(name,w,h,dock_state,300,300)
end


function LGUI.drawGrid()
  gfx.r,gfx.g,gfx.b,gfx.a=1,1,1,.3
  local spacing=10
  for i=1,LGUI.h/spacing,1 do
    gfx.x,gfx.y=0,i*spacing
    gfx.lineto(LGUI.w,i*spacing,1)
  end
  for i=1,LGUI.w/spacing,1 do
    gfx.x,gfx.y=i*spacing,0
    gfx.lineto(i*spacing,LGUI.h,1)
  end
end


function LGUI.addControl(control)
  control.idx=LGUI.idx
  LGUI.controls[LGUI.idx]=control
  LGUI.idx=LGUI.idx+1
end


function LGUI.saveStates()
  local controls=LGUI.controls
  for i=1,#controls,1 do
    controls[i]:storeState(LGUI.state_name)
  end
end


function LGUI.recallStates()
  local controls=LGUI.controls
  for i=1,#controls,1 do
    controls[i]:recallState(LGUI.state_name)
  end
  return true
end


function LGUI.deleteStates()
  local controls=LGUI.controls
  for i=1,#controls,1 do
    controls[i]:deleteState(LGUI.state_name)
  end
end


function LGUI.cycleControlledIdx(inc_not_dec)
  local controls=LGUI.controls
  local cidx=LGUI.controlled_idx
  local nc=#controls
  if cidx==nil then
    for i=1,nc,1 do
      if controls[i].can_focus==true then
        controls[i].has_focus=true
        LGUI.controlled_idx=i
        return
      end
      return -- still nil
    end
  end
  local adj=inc_not_dec and 1 or -1
  local pidx=cidx
  for i=1,nc,1 do
    pidx=pidx+adj
    if pidx>nc then pidx=1 end
    if pidx<1 then pidx=nc end
    if controls[pidx].can_focus then
      controls[pidx].has_focus=true
      controls[LGUI.controlled_idx].has_focus=false
      LGUI.controlled_idx=pidx
      return
    end
  end -- not changed
end


function LGUI.process()
  local c=gfx.getchar()
  gfx.x, gfx.y=0,0
  gfx.r=0xBB/255  gfx.g=0xBF/255   gfx.b=0xBF/255
  gfx.rect(0,0,LGUI.w,LGUI.h,true)
  if LGUI.edit_mode then LGUI.drawGrid() end
  local controls=LGUI.controls
  --tab
  ---[[
  if c==9 then
    --if shift is pressed?
    local shift=(gfx.mouse_cap&8==8)
    LGUI.cycleControlledIdx(not shift)
  elseif LGUI.controlled_idx~=nil then
    if c>0 then
      if c==13 and controls[LGUI.controlled_idx].type~="edit_box" then 
        controls[LGUI.controlled_idx]:onEnter()
      else
        controls[LGUI.controlled_idx]:onChar(c)
      end
    end
  else 
    if c==32 then
     reaper.Main_OnCommand(40044,-1) --toggle play (spacebar)
    end
  end
  for i=1,#controls,1 do
    controls[i]:update(gfx.mouse_x,gfx.mouse_y,gfx.mouse_cap)
  end
  gfx.update()
  if LGUI.countdown<=0 then 
    LGUI.slowProcess()
  else
    LGUI.countdown=LGUI.countdown-1
  end
  if LGUI.mainFunction~=nil then LGUI.mainFunction() end
  if c>=0 and c~=27 and not LGUI.exit_script then 
    reaper.defer(LGUI.process)
  else
    LGUI.atExit()
  end
end


function LGUI.slowProcess()
  --LGUI.deleteStates()
  --check if project has changed (switching project tabs etc)
  local p_name=""
  local cp,p_name=reaper.EnumProjects(-1,"")
  if cp~=LGUI.current_project or p_name~=LGUI.current_project_name or LGUI.init then
    LGUI.current_project=cp
    LGUI.current_project_name=p_name
    DBG("Different project:  "..p_name)
    local s=reaper.GetProjExtState(0,LGUI.state_name,"init")
    DBG("init state: -"..s.."-")
    if s+0==0 then
      DBG("initting script")
      reaper.SetProjExtState(0,LGUI.state_name,"init","init")
      LGUI.controls={}
      LGUI.idx=1
      LGUI.main_init()
    else
      LGUI.recallStates()
    end
    LGUI.init=false
  else 
    --DBG("Same project")
    LGUI.saveStates()
  end
  LGUI.countdown=LGUI.timer
end


function LGUI.atExit()
 --
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- base class for controls to inherit from
LControl = class(
      function (contr,x,y,w,h)
        --common member defaults
        contr.idx=LGUI.idx
        contr.x,contr.y=x,y
        contr.w,contr.h=w,h
        contr.alpha=0.8
        contr.state={}
        contr.__mouse_up_time=1
        contr.__double_clicked=false
        contr.__is_mouse_in=false
        contr.__is_mouse_down=false
        contr.colour_edit={0,1,1} --colour for edit highlight
        contr.can_edit=true
        contr.edit_mode=false
        --keyboard focus
        contr.can_focus=true
        contr.has_focus=false
        contr.colour_fg={0,0,0}
        contr.colour_bg={0,0,1}
        contr.colour_txt={0,0,0}
        contr.orig_x, contr.orig_y=-1, -1
        contr.last_x, contr.last_y=-1, -1
        --contr.font="Consolas"
        contr.font_sz=16
      end  
)


function LControl:setGfxColour(colour)
  gfx.r,gfx.g,gfx.b=colour[1],colour[2],colour[3]
end


function LControl:setColour(colour, r,g,b)
  colour[1]=r
  colour[2]=g
  colour[3]=b
end


function LControl:getColour(colour)
  return colour[1],colour[2],colour[3]
end


function LControl:takeFocusControl()
  if self.can_focus then
    if LGUI.controlled_idx~=nil then
        LGUI.controls[LGUI.controlled_idx].has_focus=false
    end
    LGUI.controlled_idx=self.idx
    LGUI.controls[LGUI.controlled_idx].has_focus=true
  end
end


function LControl:update(mx, my, m_mod)
   --local mx=gfx.mouse_x   local my=gfx.mouse_y   local m_mod=gfx.mouse_cap
   --if LGUI.controlled_idx~=nil and LGUI.controlled_idx~=self.idx then
   --  self:prepDraw(mx,my) return
   --end
   if self.last_x<0 and self.last_y<0 then
      self.last_x, self.last_y = mx, my
   end
   local in_rect=self:isInRect(mx, my)
   if m_mod&1 > 0 then
     if self.__is_mouse_down then
       if self.last_x ~= mx or self.last_y ~= my then
         if self.edit_mode==true then
           self.x=mx-self.orig_x
           self.y=my-self.orig_y
         else
           self:onMouseMove(mx, my, m_mod)
         end
       end
     else
       if in_rect then --self.__is_mouse_in then
         self.orig_x, self.orig_y = mx-self.x, my-self.y
         
         if self.edit_mode==false then
           if os.time()-self.__mouse_up_time<0.2 then
             self:onDoubleClick(mx,my,m_mod)
             self.__mouse_up_time=1
             self.__double_clicked=true
           else
             if self.__is_mouse_in==true then
               DBG("onMouseDown idx:"..self.idx)
               self:takeFocusControl()
               self:onMouseDown(mx, my, m_mod)
             end
           end
         end
         self.__is_mouse_down=true
         self.__is_mouse_in=true
       end
     end
   else
     if self.__is_mouse_down then
       self.__is_mouse_down=false
       DBG("onMouseUp idx:"..self.idx)
       self:onMouseUp(mx, my, m_mod)
       self.__mouse_up_time=os.time()
       if self.__is_mouse_in then 
         if not self.__double_clicked then
           DBG("onClick idx:"..self.idx)
           self:onClick(mx, my, m_mod) 
         else
           self.__double_clicked=false
         end
       end
     end
   end
  
   -- handle mouseover
   if in_rect then
     if not self.__is_mouse_in then      
        -- if mouse buttons down on entry, not for this control
       if (m_mod&1) > 0 then 
         self:prepDraw(mx,my)
         return 
       end
       self.__is_mouse_in=true
       DBG("onMouseOver idx:"..self.idx)
       self:onMouseOver(mx, my, m_mod)
     end
   else
     
     if self.__is_mouse_in and not self.__is_mouse_down then
       DBG("onMouseOut idx:"..self.idx)   
       self:onMouseOut(mx, my, m_mod)
     end
     self.__is_mouse_in=false
   end
   self:prepDraw(mx,my)
end


function LControl:drawBorder(r,g,b,a,offset)
  offset=offset==nil and 0 or offset
  gfx.x, gfx.y=self.x, self.y
  --self.setGfxColour(self.colour_fg)
  gfx.r,gfx.g,gfx.b,gfx.a=r,g,b,a
  gfx.rect(self.x-offset,self.y-offset,
      self.w+offset*2,self.h+offset*2,false)
  gfx.a=1 --reset for later
end


function LControl:prepDraw(mx,my)
  self.last_x, self.last_y = mx, my
  self:draw()
  if self.edit_mode==true or LGUI.controlled_idx==self.idx then 
    self:drawBorder(0.1,0.1,1,0.24,2)
    self:drawBorder(0.1,0.1,1,0.24,1)
  end
end


function LControl:isInRect(x,y)
   return (x>=self.x and x<=(self.x+self.w) and y>=self.y and y<=(self.y+self.h))
end


--pickle only pickles tables so...
function LControl:getPickleableState()
  if type(self.state)~="table" then 
    return {self.state}
  else
    return self.state
  end
end


function LControl:deleteState(state_name)
  reaper.SetProjExtState(0,state_name,tostring(self.idx),"",true)
end


function LControl:storeState(state_name)
  reaper.SetProjExtState(0,state_name,tostring(self.idx),pickle(self:getPickleableState()),true)
end


function LControl:recallState(state_name)
  local ok,found,cnt=true,false,0
  local key,state
  while not found and ok do
    ok,key,state=reaper.EnumProjExtState(0,state_name,cnt)
    --end
    if tostring(key)==tostring(self.idx) then 
      found=true ok=false
    end 
    cnt=cnt+1 
  end
  if found then
    self.state=unpickle(state)
    --if #self.state==1 then self.state=self.state[1] end
  else
    reaper.SetProjExtState(0,state_name,tostring(self.idx),pickle(self:getPickleableState()),true)
  end
end


function LControl:getIdx()
  return self.idx
end


-- override these in derived controls
function LControl:onEnter() self:onClick(nil,nil,nil) end

function LControl:onChar(c) end

function LControl:setState(state) end

function LControl:onMouseUp(x, y, m_mod) end

function LControl:onClick(x, y, m_mod) end

function LControl:onDoubleClick(x, y, m_mod) end

function LControl:onMouseDown(x, y, m_mod) end

function LControl:onMouseOver(x, y, m_mod) end

function LControl:onMouseOut(x, y, m_mod) end

function LControl:onMouseMove(x, y, m_mod) end

function LControl:draw() end
---------------------------------------------------------------------------------------------------



---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
LListControl=class(LControl,
          function (self,x,y,w,h,margin,font,colour_fg,colour_bg,state)
            LControl.init(self,x,y,w,h)
            --self.idx=idx
            self.x, self.y, self.w, self.h, self.margin=x,y,w,h,margin
            self.margin=margin
            self.font=font
            self.colour_fg=colour_fg
            self.colour_bg=colour_bg
            self.state=state
            self.num_rows=10
            self.state.first_vis_row=1
            self.row_height=19
            self.selected_rows={}
            self.enabled=true
            self.last_clicked_row=-1
            --LControl.addControl(self)
            self:recallState(LGUI.state_name)
            self.state.first_vis_row=self.state.first_vis_row==nil
                 and 1 or self.state.first_vis_row
            --DBG(self.state)
          end
)


function LListControl:addEntry(str)
  local tab={str,false}
  self.state[#self.state+1]=tab
  if #self.state>self.num_rows then
    self.state.first_vis_row=#self.state-self.num_rows+1
  else
    self.state.first_vis_row=1
  end
  self:setOnlySelected(#self.state,false)
end


function LListControl:onMouseDown(x, y, m_mod)
  y=y-self.y
  self.orig_row=math.floor((y-self.margin)/self.row_height)+self.state.first_vis_row
end


function LListControl:setOnlySelected(row,toggle)
  for i=1,#self.state,1 do
    self.state[i][2]=false
  end
  self.state[row][2]=
   toggle and not self.state[row][2] or true
end


function LListControl:onClick(x,y,m_mod)
  -- if x==nil then enter pressed and onEnter not
  -- overridden so do nothing
  if x~=nil then
    if self.enabled and self:isInRect(x,y) then
        y=y-self.y
        local row=math.floor((y-self.margin)/self.row_height)+self.state.first_vis_row
        if self.orig_row~=row then return end
        if row<=#self.state and row>=1 then
        if m_mod==0 then
            self:setOnlySelected(row,true)
        end
        if m_mod==4 then
            self.state[row][2]=not self.state[row][2]
        end
        if m_mod==8 then
            local step
            if self.last_clicked_row<row then step=1 else step=-1 end
            for i=self.last_clicked_row,row,step do
            self.state[i][2]=true
            end
        end
        self.last_clicked_row=row
        end
    end
  end
end


function LListControl:draw()
  if self.state.first_vis_row==nil then self.state.first_vis_row=1 end
  self:drawBorder(0,0,0,1)
  gfx.r, gfx.g, gfx.b = self:getColour(self.colour_bg)
  gfx.a = 1
  --gfx.setfont(1,self.font, self.font_sz)--, "ub")
  --gfx.r, gfx.g, gfx.b = self:getColour(self.colour_fg)
  gfx.x, gfx.y = self.x+self.margin, self.y+self.margin
  
  local inc=1
  local fvr=self.state.first_vis_row~=nil and self.state.first_vis_row or 1
  for i=fvr,fvr+self.num_rows-1,1 do
    local x, y=self.x+self.margin, (self.y+(self.row_height*(inc-1)))+self.margin
    gfx.x, gfx.y = x,y
    if self.state[i] and self.state[i][2]==true then
      gfx.r, gfx.g, gfx.b = self:getColour(self.colour_fg)
      gfx.rect(gfx.x,gfx.y-1,self.w-(self.margin*2),self.row_height-1)
      gfx.x,gfx.y=x,y
      gfx.r, gfx.g, gfx.b = 0,0,0
      gfx.r, gfx.g, gfx.b = self:getColour(self.colour_bg)
    else
      gfx.r, gfx.g, gfx.b = self:getColour(self.colour_fg)
    end
    if self.state[i] then gfx.printf(self.state[i][1]) end
    inc=inc+1
  end
end


function LListControl:selectPrevOrNext(prev)
  for i=1,#self.state,1 do
    if self.state[i][2]==true then
      entry=i
      break
    end
  end
  if not entry then self.state[1][2]=true return end
  if entry>1 and prev then
    self:setOnlySelected(entry-1,false)
    if entry-1 < self.state.first_vis_row then
      self.state.first_vis_row=self.state.first_vis_row-1
    end
    return
  end
  if entry<#self.state and not prev then
    self:setOnlySelected(entry+1,false)
    if entry+1 > self.state.first_vis_row+self.num_rows-1 then
      self.state.first_vis_row=self.state.first_vis_row+1
    end
  end
end


function LListControl:onChar(c)
  if c==0x7570 then  self:selectPrevOrNext(true)-- up arrow
  elseif c==0x646F776e then self:selectPrevOrNext(false) end
end


function LListControl:onEnter()
  self:addEntry("entry "..#self.state+1)
end



---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
LButton=class(LControl,
      function (self, x,y, w, h, label, action, args, is_toggle, colour_bg,
                colour_fg,ex_group)
        LControl.init(self,x,y,w,h)
        --self.idx,self.x,self.y,self.w,self.h=idx,x,y,w,h
        self.action=action
        self.is_toggle=is_toggle
        self.label=label
        self.colour_bg={0.5,0.5,0.5}
        self.colour_bg_active=colour_bg==nil and {0,0,0} or colour_bg
        self.colour_fg=colour_fg==nil and {1,1,1} or colour_fg
        self.ex_group=ex_group
        self.state.label=label
        self.args=args
        gfx.setfont(1,self.font, 14)
        self.lw,self.lh=gfx.measurestr(self.label)
        --LGUI.addControl(self)
        self:recallState(LGUI.state_name)
      end
)


function LButton:draw()
   gfx.setfont(1,self.font, 14)
   local lw,lh=self.lw,self.lh
   self.label_ypos=(self.h/2)-(gfx.texth/2)
   self.label_xpos=(self.w/2)-(lw/2)
   local colour_txt={}
   if self.state==0 then
     gfx.r, gfx.g, gfx.b = self:getColour(self.colour_bg)
     colour_txt=self.colour_fg
   else
     gfx.r, gfx.g, gfx.b = self:getColour(self.colour_bg_active)
     colour_txt={0.9,0.9,0.9}
   end
   gfx.a = self.alpha
   gfx.rect(self.x, self.y, self.w, self.h, true)
   gfx.x, gfx.y = self.x+self.label_xpos, self.y+self.label_ypos
   --gfx.x=self.x-lw-10
   gfx.r, gfx.g, gfx.b = self:getColour(colour_txt)
   gfx.a=1.0
   gfx.printf(self.label)
   --gfx.blit(self.img,1,0)
end


-- set state of two state/toggle button
function LButton:setState(state)
  if self.ex_group~=nil then
    if self.state==0 and state==1 then
      for i=1,#self.ex_group,1 do
        self.ex_group[i].state=0
        self.state=1
      end
    end
  else
    self.state=state
  end
end


function LButton:getState()
  return self.state
end


function LButton:onMouseOver(x, y, m_mod)  
   self.alpha=0.9
end


function LButton:onMouseDown(x, y, m_mod)
  if self.state==0 then  
    self.alpha=.7
  else
    self.alpha=0.7
  end
end


function LButton:onMouseOut(x, y, m_mod)
  self.alpha=.8
end


function LButton:doAction()
  if self.action~=nil then
    if self.args~=nil then
      self.action(self.args)
    else
      self.action()
    end
  end
end


function LButton:onClick(x,y,m_mod)
  self.alpha=1
  if self.is_toggle then
    if self.state==0 then
      self:setState(1)
      self:doAction()
    else
      self:setState(0)
      if self.ex_group==nil then
        self:doAction()
      end
    end
  else
    self:doAction()
  end
end




---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
LLabel=class(LControl,
          function(self,x,y,w,h,label,font,font_sz,colour_txt)
            LControl.init(self,x,y,w,h)
            self.font=font==nil and "Arial" or font
            self.font_sz=font_sz==nil and 14 or font_sz
            self:setText(label)
            self.colour_txt=colour_txt==nil and {0,0,0} or colour_txt
            self.can_focus=false
            self:recallState(LGUI.state_name)
          end
)


function LLabel:setText(txt)
  gfx.setfont(1,self.font,self.font_sz)
  self.w=gfx.measurestr(txt)
  self.label=txt
end

    
function LLabel:draw()
  gfx.r, gfx.g, gfx.b = self:getColour(self.colour_txt)
  gfx.a=1.0
  gfx.x,gfx.y=self.x,self.y
  gfx.setfont(1,self.font, self.font_sz)--, "ub")
  gfx.printf(self.label)
end



---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
LCheckBox=class(LControl,
            function(self,x,y,w,h,label)
              LControl.init(self,x,y,w,h)
              self.label=label
              self.lw,self.lh=gfx.measurestr(self.label)
              self.colour_txt={0,0,0}--0xFFFFFF
              self.fgcol=0x000000
              self.state={}
              self.state.check=false
              self:recallState(LGUI.state_name)
            end
)


function LCheckBox:draw()
  gfx.r, gfx.g, gfx.b = self:getColour(self.colour_bg)
  gfx.a=1
  if self.state.check then
    gfx.rect(self.x,self.y,self.h,self.h,false)
    gfx.line(self.x+1,self.y+1,self.x+self.h-1,self.y+self.h-1)
    gfx.line(self.x+1,self.y+self.h-1,self.x+self.h-1,self.y+1)
  else
    gfx.rect(self.x,self.y,self.h,self.h,false)
  end
  gfx.r, gfx.g, gfx.b = self:getColour(self.colour_txt)
  gfx.x,gfx.y=self.x+self.h+10,self.y+(self.h-self.lh)/2
  gfx.a=1.0
  gfx.printf(self.label)
end


function LCheckBox:onMouseDown(x, y, m_mod)  
   self.state.check=not self.state.check
end


function LCheckBox:onEnter()
  self.state.check=not self.state.check
end



---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
LComboBox=class(LControl,
            function(self,x,y,w,h,options)
              LControl.init(self,x,y,w,h)
              self.title=nil
              self.state.choice=1
              self.options=options
              self:setOptions()
              self:recallState(LGUI.state_name)
            end
)


function LComboBox:setOptions()
  self.menu_string=""
  for i=1,#self.options,1 do
    self.menu_string=self.menu_string.."|"..self.options[i]
  end
    
end

function LComboBox:onClick(x,y,m_mod)
  gfx.x,gfx.y=self.x,self.y
  local choice=gfx.showmenu(self.menu_string)
  if choice>0 then self.state.choice=choice end
end


function LComboBox:draw()
  self:drawBorder(0,0,0,1)
  gfx.x,gfx.y=self.x+4,self.y+2
  gfx.setfont(1,"Arial", 14)--, "ub")
  gfx.printf(self.options[self.state.choice])
end



---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
LSlider=class(LControl,
            function(self,x,y,w,h,label)
              LControl.init(self,x,y,w,h)
              self.type="slider"
              self.state={}
              self.state.label=label
              self.state.fc_pos=w/2 --inital fader cap pos
              self.state.val=0.5
              self.state.font_sz=18
              self.hcw=15 --half 'fader' cap width
              self.fhxo=0 --fader head x offset
              self:recallState(LGUI.state_name)
            end
)


function LSlider:draw()
  local fc_pos=self.state.fc_pos
  gfx.r, gfx.g, gfx.b = self:getColour(self.colour_bg)
  local font,font_sz=self.state.font,self.state.font_sz
  gfx.rect(self.x,self.y,self.w,self.h-font_sz,false)
  
  gfx.rect(self.x+(fc_pos-self.hcw),self.y,30,self.h-font_sz,true)
  
  self:setGfxColour(self.colour_txt)
  gfx.x,gfx.y=self.x,self.y+(self.h-font_sz)
  gfx.a=1.0
  gfx.setfont(1,  font,font_sz)
  gfx.printf(self.state.label)
end


function LSlider:onMouseDown(mx,my,m_mod)
  local pos=mx-self.x
  local fc_pos=self.state.fc_pos
  if pos>fc_pos-self.hcw and pos<fc_pos+self.hcw then
    self.fhxo=pos-fc_pos
  else
    self.fhxo=0
    if pos<self.hcw then pos=self.hcw end
    if pos>self.w-self.hcw then pos=self.w-self.hcw end
    self.state.fc_pos=pos
    self.state.val=(self.state.fc_pos-self.hcw)/(self.w-(self.hcw*2))
  end
  reaper.ShowConsoleMsg("new val:"..self.state.val.."\n")
end


function LSlider:onMouseMove(mx,my,m_mod)
  local pos=mx-self.x-self.fhxo
  if pos<self.hcw then pos=self.hcw end
  if pos>self.w-self.hcw then pos=self.w-self.hcw end
  self.state.fc_pos=pos
  self.state.val=(self.state.fc_pos-self.hcw)/(self.w-(self.hcw*2))
  reaper.ShowConsoleMsg("new val:"..self.state.val.."\n")
end



---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
LEditBox=class(LControl,
            function (self,x,y,w,h,l,maxlen,has_focus)
              LControl.init(self,x,y,w,h)
              self.type="edit_box"
              self.l,self.maxlen=l,maxlen
              self.caret, self.sel, self.cursstate=0,0,0
              self.state={}
              self.state.text=""
              self.has_focus=has_focus
              self.font,self.font_sz=1,h-4
              self.fgcol=0x0000FF   self.fgfcol=0x00FF00
              self.bgcol=0xFFFFFF
              self.txtcol=0x000001
              self.curscol=0x000000
              self:recallState(LGUI.state_name)
              if self.state.text==nil then self.state.text="" end
              if self.has_focus then 
                self:selectAll() 
                LGUI.controlled_idx=self.idx
              end
            end
)

function LEditBox:setText(txt)
  self.state.text=txt
  self.selectAll()
end


function LEditBox:endFocus()
  self.has_focus=false
  LGUI.controlled_idx=nil
end


function LEditBox:setColor(i)
  gfx.set(((i>>16)&0xFF)/0xFF, ((i>>8)&0xFF)/0xFF, (i&0xFF)/0xFF)
end


function LEditBox:draw()
  self:setColor(self.bgcol)
  gfx.rect(self.x,self.y,self.w,self.h,true)
  --self:setColor(self.hasfocus and self.fgfcol or self.fgcol)
  gfx.rect(self.x,self.y,self.w,self.h,false)
  gfx.setfont(1,self.font,self.font_sz) 
  self:setColor(self.txtcol)
  local w,h=gfx.measurestr(self.state.text)
  local ox,oy=self.x+self.l,self.y+(self.h-h)/2
  gfx.x,gfx.y=ox,oy
  gfx.drawstr(self.state.text)
  if self.sel ~= 0 then
    local sc,ec=self.caret,self.caret+self.sel
    if sc > ec then sc,ec=ec,sc end
    local sx=gfx.measurestr(string.sub(self.state.text, 0, sc))
    local ex=gfx.measurestr(string.sub(self.state.text, 0, ec))
    self:setColor(self.txtcol)
    gfx.rect(ox+sx, oy, ex-sx, h, true)
    self:setColor(self.bgcol)
    gfx.x,gfx.y=ox+sx,oy
    gfx.drawstr(string.sub(self.state.text, sc+1, ec))
  end 
  if self.has_focus then
    if self.cursstate < 8 then   
      w=gfx.measurestr(string.sub(self.state.text, 0, self.caret))    
      self:setColor(self.curscol)
      gfx.line(self.x+self.l+w, self.y+2, self.x+self.l+w, self.y+self.h-4)
    end
    self.cursstate=(self.cursstate+1)%16
  end
end


function LEditBox:getCaret(x,y)
  local len=string.len(self.state.text)
  for i=1,len do
    gfx.setfont(1,self.font,self.font_sz)
    w=gfx.measurestr(string.sub(self.state.text,1,i))
    if x < self.x+self.l+w then return i-1 end
  end
  return len
end


function LEditBox:onMouseDown(x,y,m_mod)
  self.has_focus=
    gfx.mouse_x >= self.x and gfx.mouse_x < self.x+self.w and
    gfx.mouse_y >= self.y and gfx.mouse_y < self.y+self.h    
  if self.has_focus then
    --self:takeFocusControl()
    self.caret=self:getCaret(x,y) 
    self.cursstate=0
  end
  self.sel=0 
end


function LEditBox:onDoubleClick(x,y,m_mod)
  self:selectAll()
end


function LEditBox:selectAll()
  local len=string.len(self.state.text)
  self.caret=len ; self.sel=-len
end


function LEditBox:onMouseMove(x,y,m_mod)
  self.sel=self:getCaret(x,y)-self.caret
end


function DEC_HEX(IN)
    local B,K,OUT,I,D=16,"0123456789ABCDEF","",0
    while IN>0 do
        I=I+1
        IN,D=math.floor(IN/B),(IN%B)+1
        OUT=string.sub(K,D,D)..OUT
    end
    return OUT
end


function LEditBox:onChar(c)
  --reaper.ShowConsoleMsg(DEC_HEX(c).."\n")
  if c==13 then self:endFocus()  self:onEnter()  return end --enter
  local just_cleared=nil
  if self.sel ~= 0 then
    local sc,ec=self.caret,self.caret+self.sel
    if sc > ec then sc,ec=ec,sc end
    if c == 0x6C656674 then -- left arrow
      self.sel=0
      self.caret=sc
    elseif c == 0x72676874 then -- right arrow
      self.caret=ec
      self.sel=0
    else
      self.state.text=string.sub(self.state.text,1,sc)..string.sub(self.state.text,ec+1)
      self.sel, self.caret=0,sc
      if c >= 32 and c <= 125 and string.len(self.state.text) < self.maxlen then
        self:addChar(c)
      end
    end
  else
    if c == 0x6C656674 then -- left arrow
      if self.caret > 0 then self.caret=self.caret-1 end
    elseif c == 0x72676874 then -- right arrow
      if self.caret < string.len(self.state.text) then self.caret=self.caret+1 end
    elseif c == 8 and just_cleared==nil then -- backspace
      if self.caret > 0 then 
        self.state.text=string.sub(self.state.text,1,self.caret-1)..string.sub(self.state.text,self.caret+1)
        self.caret=self.caret-1
      end
    elseif c == 0x64656C and just_cleared==nil then -- delete
      if self.caret < string.len(self.state.text) then
        self.state.text=string.sub(self.state.text,1,self.caret)..string.sub(self.state.text,self.caret+2)
      end
    elseif c >= 32 and c <= 125 and string.len(self.state.text) < self.maxlen then
      self:addChar(c)
    end
  end
end


function LEditBox:addChar(c)
  self.state.text=string.format("%s%c%s", 
            string.sub(self.state.text,1,self.caret), c, string.sub(self.state.text,self.caret+1))
  self.caret=self.caret+1
end

