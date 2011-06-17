# McDonnell Douglas DC-10
# Aircraft systems
#########################

var is_tanker = getprop("sim/aircraft") == "KC-10A" ? 1 : 0;

# NOTE: This file contains a loop for running all update functions, so it should be loaded last

## Main systems update loop
var systems =
 {
 loopid: -1,
 init: func
  {
  print("DC-10 aircraft systems ... initialized");
  systems.loopid += 1;
  settimer(func systems.update(systems.loopid), 0);
  },
 stop: func
  {
  systems.loopid -= 1;
  },
 reinit: func
  {
  print("DC-10 aircraft systems ... reinitialized");
  setprop("sim/model/start-idling", 0);
  systems.stop();
  settimer(func systems.update(systems.loopid), 0);
  },
 update: func(id)
  {
  # check if our loop id matches the current loop id
  if (id != systems.loopid)
   {
   return;
   }
  engine1.update();
  engine2.update();
  engine3.update();
  update_electrical();
  update_gear();
  if (is_tanker)
   {
   update_tanker();
   }
  # stop calling our systems code if the aircraft crashes
  if (!props.globals.getNode("sim/crashed").getBoolValue())
   {
   settimer(func systems.update(id), 0);
   }
  }
 };

# call init() 2 seconds after the FDM is ready
setlistener("sim/signals/fdm-initialized", func
 {
 settimer(systems.init, 2);
 }, 0, 0);
# call init() if the simulator resets
setlistener("sim/signals/reinit", func(reinit)
 {
 if (reinit.getBoolValue())
  {
  systems.reinit();
  }
 }, 0, 0);

## Startup/shutdown functions
var startid = -1;
var startup = func
 {
 startid += 1;
 var id = startid;
 setprop("controls/engines/engine[0]/cutoff", 1);
 setprop("controls/engines/engine[1]/cutoff", 1);
 setprop("controls/engines/engine[2]/cutoff", 1);
 setprop("controls/engines/engine[0]/starter", 1);
 setprop("controls/engines/engine[1]/starter", 1);
 setprop("controls/engines/engine[2]/starter", 1);
 settimer(func
  {
  if (id == startid)
   {
   setprop("controls/engines/engine[0]/cutoff", 0);
   setprop("controls/engines/engine[1]/cutoff", 0);
   setprop("controls/engines/engine[2]/cutoff", 0);
   }
  }, 2);
 };
var shutdown = func
 {
 setprop("controls/engines/engine[0]/cutoff", 1);
 setprop("controls/engines/engine[1]/cutoff", 1);
 setprop("controls/engines/engine[2]/cutoff", 1);
 };
setlistener("sim/model/start-idling", func(idle)
 {
 var run = idle.getBoolValue();
 if (run)
  {
  startup();
  }
 else
  {
  shutdown();
  }
 }, 0, 0);

## Tanker update function
var update_tanker = func
 {
 # Turn tanker on/off based on boom position and fuel level
 # TODO: Consume fuel when aircraft is refueling
 var boom_pos = props.globals.getNode("sim/model/door-positions/boom/position-norm");
 var fuel = props.globals.getNode("sim/weight[1]/weight-lb");
 var on_off = props.globals.getNode("tanker", 1);
 if (boom_pos != nil and fuel.getValue() > 0 and boom_pos.getValue() == 1)
  {
  on_off.setBoolValue(1);
  }
 else
  {
  on_off.setBoolValue(0);
  }

 # Raise the boom when any of the gears are compressed
 if ((props.globals.getNode("gear/gear[0]/wow").getBoolValue() or props.globals.getNode("gear/gear[2]/wow").getBoolValue() or props.globals.getNode("gear/gear[4]/wow").getBoolValue()) and boom_pos.getValue() > 0)
  {
  doors.setpos("boom", 0);
  }
 };

## Flaps and slats levers are coupled to each other. *Technically*, the flaps lever can separate itself from the slats lever in the retracted position, but this is difficult to simulate on a computer, so we will just keep them coupled
setlistener("controls/flight/flaps", func(flaps)
 {
 var slats = props.globals.getNode("controls/flight/slats");
 slats.setValue(flaps.getValue());
 }, 1, 1);

## Prevent landing gear retraction if any of the gears are compressed
setlistener("controls/gear/gear-down", func(gear_down)
 {
 var down = gear_down.getBoolValue();
 if (!down and (props.globals.getNode("gear/gear[0]/wow").getBoolValue() or props.globals.getNode("gear/gear[2]/wow").getBoolValue() or props.globals.getNode("gear/gear[4]/wow").getBoolValue()))
  {
  gear_down.setBoolValue(1);
  }
 }, 0, 0);

## Instrumentation
# Spool up the attitude indicators every 5 seconds
var ai_spin0 = props.globals.getNode("instrumentation/attitude-indicator[0]/spin");
var ai_spin1 = props.globals.getNode("instrumentation/attitude-indicator[1]/spin");
var update_ai = func
 {
 ai_spin0.setValue(1);
 ai_spin1.setValue(1);
 settimer(update_ai, 5);
 };
settimer(update_ai, 5);
# Chronometers
var chronometer1 = aircraft.timer.new("instrumentation/clock[0]/elapsed-sec", 1, 0);
var chronometer2 = aircraft.timer.new("instrumentation/clock[1]/elapsed-sec", 1, 0);

## Landing gear updater
var update_gear = func
 {
 var has_ctr_gear = props.globals.getNode("sim/model/livery/has-center-gear").getBoolValue();
 var ctr_gear_down = props.globals.getNode("controls/gear/center-gear-down");
 if (has_ctr_gear)
  {
  var ctr_gear_independent = props.globals.getNode("controls/gear/isolate-center-gear").getBoolValue();
  var gear_down = props.globals.getNode("controls/gear/gear-down");
  if (gear_down.getBoolValue())
   {
   if (!ctr_gear_independent)
    {
    ctr_gear_down.setBoolValue(1);
    }
   }
  else
   {
   ctr_gear_down.setBoolValue(0);
   }
  }
 else
  {
  ctr_gear_down.setBoolValue(0);
  setprop("gear/gear[5]/position-norm", 0);
  }
 };

## Aircraft-specific dialogs
var dialogs =
 {
 lights: gui.Dialog.new("sim/gui/lights/dialog", "Aircraft/DC-10-30/Systems/lights-dlg.xml"),
 doors: gui.Dialog.new("sim/gui/doors/dialog", "Aircraft/DC-10-30/Systems/doors-dlg.xml"),
 failures: gui.Dialog.new("sim/gui/failures/dialog", "Aircraft/DC-10-30/Systems/failures-dlg.xml"),
 tiller: gui.Dialog.new("sim/gui/tiller/dialog", "Aircraft/DC-10-30/Systems/tiller-dlg.xml")
 };
