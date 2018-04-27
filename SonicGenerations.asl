state("SonicGenerations", "latest")
{
  // This only ticks if you have control of Sonic.
  float stage_time : 0x01A0BE5C, 0x08, 0x184;

  // This ticks from the start of the stage all the way to after the goal is hit
  float total_stage_time : 0x01A0BE5C, 0x08, 0x188;

  // When a loading screen is up, this will be true
  bool stage_loading : 0x01A0BE5C, 0x08, 0x1a8;

  // When you touch the goal, this section of 8 bytes are modified. 
  // We however can not use this reliabily as it is changed when you die, or talk to some NPCs.
  // I believe this has to do with either GUIs appering on the screen or your animation state.
  ulong goal_hit : 0x01A0BE5C, 0x08, 0xa0;

  // If the game is paused, this is true
  byte is_paused : 0x01A0BE5C, 0x08,0xD0;

  // Name of the stage we are currently on
  string6 stage_name : 0x01A0BE5C, 0x08, 0x88, 0x00;

  // This is not zero when in a cutscene (Needs more testing).
  byte stage_state : 0x01A0BE5C, 0x08, 0x88, 0x07;

  // When you hit a combo bumper or ring, this becomes true. (Just here because it may be useful later)
  bool in_combo_seq : 0x01A0BE5C, 0x08, 0x19c;
}

startup
{
  // We are currently loading this script. Set up shit here
  settings.Add("Real_time", true, "Track Real Time");
  settings.Add("Game_time", false, "Use Game time");
  settings.Add("loading_time", true, "Include loading time in runtime");

  settings.Add("catagory", true, "Run Catagory");
  settings.CurrentDefaultParent = "catagory";
  settings.Add("any_percent", true);
  settings.Add("act1_only", false);
  settings.Add("act2_only", false);

  settings.CurrentDefaultParent = null;
}
 
init
{
  // We are connected to the process now  
  if (modules.First().ModuleMemorySize == 0x1CAB000)
    version = "latest";

  // stage_id
  vars.stage_table = new Dictionary<string, byte>();
  vars.stage_table.Add("pam", 01); // pam = Overworld
  vars.stage_table.Add("ghz", 02); // ghz = Green Hill
  vars.stage_table.Add("cpz", 03); // cpz = Chemical Plant
  vars.stage_table.Add("ssz", 04); // ssz = Sky Sanctuary
  vars.stage_table.Add("sph", 05); // sph = Speed Highway
  vars.stage_table.Add("cte", 06); // cte = City Escape
  vars.stage_table.Add("ssh", 07); // ssh = Seaside Hill
  vars.stage_table.Add("csc", 08); // csc = Crisis City
  vars.stage_table.Add("euc", 09); // euc = Rooftop Run
  vars.stage_table.Add("pla", 10); // pla = Planet Wisp
  
  vars.stage_table.Add("cnz", 11); // cnz = Casino Night Zone
  vars.stage_table.Add("fig", 12); // fig = Figurine Room

  // Bosses
  vars.stage_table.Add("bde", 21); // bde = Death Egg Robo Boss Fight 
  vars.stage_table.Add("bms", 22); // bms = Metal Sonic Rival Fight
  
  vars.stage_table.Add("bpc", 23); // bpc = Perfect Chaos Boss Fight
  vars.stage_table.Add("bsd", 24); // bsd = Shadow Rival Fight
  vars.stage_table.Add("bsl", 25); // bsl = Silver Rival Fight
  
  vars.stage_table.Add("bne", 26); // bne = Egg Dragoon Boss Fight
  vars.stage_table.Add("blb", 27); // blb = Time Eater Boss Fight

  vars.act = 0;
  vars.stage_id = 0;
  vars.stage_code = "";
  vars.in_boss = false;
  vars.in_final_boss = false;
  vars.prev_stage_state = false;
  vars.current_stage_state = false;

  Action<string> DebugOutput = (text) => {
    print("[SonicGenerations Autosplitter] "+text);
  };
  vars.DebugOutput = DebugOutput;
  vars.DebugOutput("test");
}
 
exit
{
  // Connected game closed. Do stuff if needed here
  vars.act = 0;
  vars.stage_id = 0;
  vars.stage_code = "";
  vars.in_boss = false;
  vars.in_final_boss = false;
  vars.prev_stage_state = false;
  vars.current_stage_state = false;
}

start
{
  if(current.stage_name != null && current.stage_name.Length > 3)
  {
    vars.act = Convert.ToByte(current.stage_name[3].ToString());
  }

  if (settings["any_percent"] == true && current.stage_loading == true && vars.stage_id == 1) {
    vars.DebugOutput("Any percent timer started");
    return true;
  }
  else if (settings["act1_only"] == true && vars.act == 1 && current.stage_loading == true) {
    vars.DebugOutput("Act1 Timer started");
    return true;
  }
  else if (settings["act2_only"] == true && vars.act == 2 && current.stage_loading == true) {
    vars.DebugOutput("Act2 Timer started");
    return true;
  }
  return false;
}

update
{
  // Reset some of the varibles that we are about to set
  vars.in_boss = false;
  vars.in_final_boss = false;

  // if the new if statement in the split function works, we won't need this here
  if(current.stage_name != old.stage_name)
  {
    vars.prev_stage_state = vars.current_stage_state = false;
  }

  if( current.stage_state == 0x00 && 
      current.stage_name != null) // This is always 0 unless a cutscene is running
  {
    if(current.stage_name.Length > 3)
    {
      vars.act = Convert.ToByte(current.stage_name[3].ToString());
      vars.stage_code = "" + current.stage_name[0] + current.stage_name[1] + current.stage_name[2];
      byte tempId = 0;
      if(vars.stage_table.TryGetValue(vars.stage_code.ToString(), out tempId))
      {
        vars.stage_id = tempId;
      }
    }
    else if (current.stage_name.Length == 3)
    {
      vars.in_boss = true;
      if(current.stage_name == "blb")
      {
        vars.in_final_boss = true;
        vars.DebugOutput("In final boss");
      }
      
    }
  }
  else
  {
    vars.DebugOutput("In cutscene");
  }

  // if the new if statement in the split function works, we won't need this here
  if(current.goal_hit != old.goal_hit)
  {
    vars.current_stage_state = true;
  }

  //vars.DebugOutput("name: "+current.stage_name.ToString()+" id:"+vars.stage_id.ToString()+" act:"+vars.act.ToString()+" isloading:"+current.stage_loading.ToString());
}

split
{
  //TODO See if I can update different splits here?
//  if(vars.stage_id > 1 && vars.current_stage_state != vars.prev_stage_state)
  if( (vars.stage_id > 1) && 
      (current.is_paused == false) &&
      (current.stage_time - old.stage_time < 0.5f) &&
      (current.total_stage_time != old.total_stage_time) &&
      (current.stage_name == old.stage_name) )
  {
    vars.prev_stage_state = vars.current_stage_state;
    if(settings["any_percent"] == true)
    {
      //TODO Maybe I should add an option to only split if both acts were completed for any%
      return true;
    }
    else if(settings["act1_only"] == true && vars.act == 1)
    {
      return true;
    }
    else if(settings["act2_only"] == true && vars.act == 2)
    {
      return true;
    }
  }
  return false;
}
 
isLoading
{
  if(settings["act1_only"] == true && vars.act == 2)
    return true;
  else if(settings["act2_only"] == true && vars.act == 1)
    return true;

  // Only count loading if we set it up like that
  return (!settings["loading_time"] && ((vars.stage_id == 1) || current.stage_loading));
}

gameTime
{
  //TODO create a buffer for the time here as the total_stage_time resets when changing stages
  return TimeSpan.FromSeconds( Convert.ToDouble(current.total_stage_time) );
}
