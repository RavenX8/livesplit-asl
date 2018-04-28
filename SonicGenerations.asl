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
  //ulong goal_hit : 0x01A0BE5C, 0x08, 0xa0, 0x00;
  
  // Gui active gives a much better result as it only ever is set to 1 when you have a gui like the goal screen is active
  short gui_active : 0x01A66B34, 0x04, 0x34, 0x58, 0x1c, 0xb5;
  //SonicGenerations.exe+902AC1 = the address to the code that changes this

  // If the game is paused, this is true
  byte is_paused : 0x01A0BE5C, 0x08,0xD0;

  // Name of the stage we are currently on
  string6 stage_name : 0x01A0BE5C, 0x08, 0x88, 0x00;

  // This is not zero when in a cutscene (Needs more testing).
  byte stage_state : 0x01A0BE5C, 0x08, 0x88, 0x07;

  // When you hit a combo bumper or ring, this becomes true. (Just here because it may be useful later)
  bool in_combo_seq : 0x01A0BE5C, 0x08, 0x19c;
  
  // Current game frame counter (only ticks if the game is rendering, aka has focus, and a game has been started or continued)
  int frame_counter : 0x01A66B34, 0x04, 0x34, 0x58, 0x1c, 0xd8;
  
  //int looks_like_a_manager_class_of_some_kind : 0x00D724CC, 0x668, 0x1c, 0x80, 0xa8;
  //int selected_item_in_pause_menu : 0x00D724CC, 0x668, 0x1c, 0x80, 0xa8, 0x0c;
}

startup
{
  // We are currently loading this script. Set up shit here
  settings.Add("pause_game_timer", false, "Pause game time when game is paused");
  settings.Add("loading_time", true, "Include loading time in runtime");

  settings.Add("catagory", true, "Run Catagory");
  settings.CurrentDefaultParent = "catagory";
  
  //TODO Do some work to be able to track for 100% catagory  
  settings.Add("any_percent", true);
  settings.Add("act1_only", false);
  settings.Add("act2_only", false);

  settings.CurrentDefaultParent = null;
}
 
init
{
  if (modules.First().ModuleMemorySize == 0x1CAB000)
    version = "latest";

  // stage_id
  vars.stage_table = new Dictionary<string, byte>();
  vars.stage_table.Add("pam", 01); // pam = Overworld
  
  vars.stage_table.Add("ghz", 02); // ghz = Green Hill
  vars.stage_table.Add("cpz", 03); // cpz = Chemical Plant
  vars.stage_table.Add("ssz", 04); // ssz = Sky Sanctuary
  
  // Bosses
  vars.stage_table.Add("bde", 05); // bde = Death Egg Robo Boss Fight 
  vars.stage_table.Add("bms", 06); // bms = Metal Sonic Rival Fight
  
  vars.stage_table.Add("sph", 07); // sph = Speed Highway
  vars.stage_table.Add("cte", 08); // cte = City Escape
  vars.stage_table.Add("ssh", 09); // ssh = Seaside Hill
  
  // Bosses
  vars.stage_table.Add("bsd", 10); // bsd = Shadow Rival Fight
  vars.stage_table.Add("bpc", 11); // bpc = Perfect Chaos Boss Fight
  
  vars.stage_table.Add("csc", 12); // csc = Crisis City
  vars.stage_table.Add("euc", 13); // euc = Rooftop Run
  vars.stage_table.Add("pla", 14); // pla = Planet Wisp
  
  // Bosses
  vars.stage_table.Add("bsl", 15); // bsl = Silver Rival Fight
  vars.stage_table.Add("bne", 16); // bne = Egg Dragoon Boss Fight
  
  vars.stage_table.Add("blb", 17); // blb = Time Eater Boss Fight
  
  // Extra stages
  vars.stage_table.Add("cnz", 18); // cnz = Casino Night Zone
  vars.stage_table.Add("fig", 19); // fig = Figurine Room

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
      }
    }
  }
  else
  {
    //vars.DebugOutput("In cutscene");
  }

  // if the new if statement in the split function works, we won't need this here
  if(current.gui_active != old.gui_active)
  {
    vars.current_stage_state = true;
  }

  //vars.DebugOutput("name: "+current.stage_name.ToString()+" id:"+vars.stage_id.ToString()+" act:"+vars.act.ToString()+" isloading:"+current.stage_loading.ToString());
}

split
{
  //TODO Make sure these conditions work correctly with when doing challange stages.
  if( (current.stage_time != 0) &&
      (current.is_paused == 0x00) &&
      (current.stage_time - old.stage_time < 0.5f) &&
      (current.total_stage_time != old.total_stage_time) &&
      (current.stage_name == old.stage_name || vars.in_final_boss) &&
      (vars.current_stage_state != vars.prev_stage_state) )
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
  return (!settings["loading_time"] && ((vars.stage_id == 1) || current.stage_loading)) || 
         (settings["pause_game_timer"] && (current.is_paused == 0x01));
}

gameTime
{
  if(vars.stage_id == 1)
    return TimeSpan.FromSeconds( 0 );
  
  //TODO Find out if you died that way we keep ticking the counter
  //TODO create a buffer for the time here as the total_stage_time resets when changing stages
  return TimeSpan.FromSeconds( Convert.ToDouble(current.stage_time) );
}
