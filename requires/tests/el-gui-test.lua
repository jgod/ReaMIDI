dofile(reaper.GetResourcePath().."\\Scripts\\ReaMIDI\\requires\\el gui.lua")

-- override this function to do something unique
function LListControl:onDoubleClick(x,y,m_mod)
  local ok, str=reaper.GetUserInputs("Rename",1,"Name: ","")
  y=y-self.y
  local row=math.floor((y-self.margin)/self.row_height)+self.first_vis_row
  if ok then self.state[row][1]=str end
end


LGUI.init("El GUI Test", 1000, 520, true)


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
  b=LButton(nil,nil,
                  false,
                  "Hello", 100,20,60,25,
                  {0.2,0.2,0.2},
                  {0.8,0.8,0.8},
                  nil
               )
  LGUI.addControl(b)
  
  b1=LButton(goToEditMode,nil,
                  true,
                  "Edit", 100,60,60,25,
                  {0.2,0.2,0.2},
                  {0.8,0.8,0.8},
                  nil
               )
  b1.can_edit=false
  LGUI.addControl(b1)
 
  cb=LCheckBox(250,20,150,10,"Label 1")
  LGUI.addControl(cb)
  cb:setColour(cb.colour_bg, 0,0,0)
 
  cb1=LCheckBox(250,50,150,10,"Label 2")
  LGUI.addControl(cb1)
  cb1:setColour(cb1.colour_bg, 0,0,0)
 
  llc=LListControl(20,100,200,200,10,
                      "Verdana",
                      {0.2,0.2,0.2},
                      {0.9,0.9,0.9},
                      {{"Mary",false},{"had",false},{"a",false},
                      {"little",false},{"lamb",false}} 
                )
  LGUI.addControl(llc)
  
  llc:setColour(llc.colour_fg, 0,0,0)
  
  editbox=LEditBox(20,400,500,20,50,50)
  
  LGUI.addControl(editbox)
  
  slider=LSlider(300,300,130,50,"Slider 1")
  LGUI.addControl(slider)
  
  label=LLabel(250,100,100,30,"El GUI Testbed","Arial",30,{.2,0.5,0.5})
  LGUI.addControl(label)
  
  
end



function main() 
   gfx.x, gfx.y=0,0
   gfx.r=0xBB/255  gfx.g=0xBF/255   gfx.b=0xBF/255
   gfx.rect(0,0,780,520,true)
   LGUI.process(gfx.getchar(),main)
end

function onExit()
  LGUI.saveStates()
end

reaper.atexit(onExit)
init()
main()
