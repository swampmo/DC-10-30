# McDonnell Douglas DC-10
# Nasal door system
#########################

var doors =
 {
 new: func(name, transit_time)
  {
  doors[name] = aircraft.door.new("sim/model/door-positions/" ~ name, transit_time);
  },
 toggle: func(name)
  {
  doors[name].toggle();
  },
 open: func(name)
  {
  doors[name].open();
  },
 close: func(name)
  {
  doors[name].close();
  },
 setpos: func(name, value)
  {
  doors[name].setpos(value);
  }
 };
doors.new("pax-l1", 3);
doors.new("pax-l2", 3);
doors.new("pax-l4", 3);
doors.new("pax-l3", 3);
doors.new("pax-r1", 3);
doors.new("pax-r2", 3);
doors.new("pax-r4", 3);
doors.new("pax-r3", 3);
doors.new("cargo-fwd", 3);
doors.new("cargo-aft", 3);
doors.new("cargo-main", 3);
doors.new("boom", 5);
