dofile(reaper.GetResourcePath().."/Scripts/ReaMIDI/requires/el gui.lua")





function goToEditMode()
  LGUI.edit_mode=not LGUI.edit_mode
  for i=1,#LGUI.controls,1 do
    if LGUI.controls[i].can_edit then 
      LGUI.controls[i].edit_mode=not LGUI.controls[i].edit_mode
    end
  end
end
  

local editbox

function init()
  DBG("in init")
  LGUI.addControl(LButton(100,20,60,25,
                  "Hello", 
                  nil,nil,
                  false,
                  
                  {0.2,0.2,0.2},
                  {0.8,0.8,0.8},
                  nil
               ))
  
  b1=LButton(    100,60,60,25,
                 "Edit",
                  goToEditMode,nil,
                  true,
                  {0.2,0.2,0.2},
                  {0.8,0.8,0.8},
                  nil
               )
  b1.can_edit=false
  LGUI.addControl(b1)
 
  cb=LCheckBox(250,20,150,10,"Checkbox 1")
  LGUI.addControl(cb)
  cb:setColour(cb.colour_bg, 0,0,0)
 
  cb1=LCheckBox(250,50,150,10,"Checkbox 2")
  LGUI.addControl(cb1)
  cb1:setColour(cb1.colour_bg, 0,0,0)
 
  llc=LListControl(20,100,200,200,10,
                      "Verdana",
                      {0.2,0.2,0.2},
                      {0.9,0.9,0.9},
                      {{"Mary",false},{"had",false},{"a",false},
                      {"little",false},{"lamb",false}}
                )
  function llc:onDoubleClick(x,y,m_mod)
    local ok, str=reaper.GetUserInputs("Rename",1,"Name: ","")
    y=y-self.y
    local row=math.floor((y-self.margin)/self.row_height)+self.state.first_vis_row
    if ok then self.state[row][1]=str end
  end
  
  --[[
  function llc:onEnter()
    local ok, str=reaper.GetUserInputs("Rename",1,"Name: ","")
    if ok then self.state[self.last_clicked_row][1]=str end
  end
  --]]

  LGUI.addControl(llc)
  
  llc:setColour(llc.colour_fg, 0,0,0)
  
  editbox=LEditBox(20,400,300,20,50,50,true)
  LGUI.addControl(editbox)
  
  slider=LSlider(300,300,130,50,"Slider 1")
  LGUI.addControl(slider)
  
  label=LLabel(250,100,100,30,"El GUI Testbed","Arial",30,{.2,0.5,0.5})
  LGUI.addControl(label)
  
  combo=LComboBox(250,150,100,20,{"one","two","three"})
  LGUI.addControl(combo)
  LGUI.process(init)
end


function onExit()
  LGUI.saveStates()
end

reaper.atexit(onExit)

LGUI.init("El GUI Test", 1000, 520, false,init)
init()

