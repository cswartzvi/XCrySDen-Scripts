scripting::open --xsf ./config5.xsf
scripting::lighting On
 
scripting::displayMode3D BallStick
foreach item { atomic-labels crystal-cells unicolor-bonds perspective } {
scripting::display on $item
}
 
scripting::zoom     +0.60
scripting::rotate x +60
scripting::rotate y +20
scripting::rotate z +10
 
  
  
  
  
