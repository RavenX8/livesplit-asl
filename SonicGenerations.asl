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
  bool is_paused : 0x01A0BE5C, 0x08,0xD0;

  // Name of the stage we are currently on
  string6 stage_name : 0x01A0BE5C, 0x08, 0x88, 0x00;

  // This is not zero when in a cutscene (Needs more testing).
  byte stage_state : 0x01A0BE5C, 0x08, 0x88, 0x07;

  // When you hit a combo bumper or ring, this becomes true. (Just here because it may be useful later)
  bool in_combo_seq : 0x01A0BE5C, 0x08, 0x19c;
  
  // Current game frame counter (only ticks if the game is rendering, aka has focus, and a game has been started or continued)
  int frame_counter : 0x01A66B34, 0x04, 0x34, 0x58, 0x1c, 0xd8;
  
  byte num_of_lives : 0x01A66B34, 0x04, 0x1b4, 0x7c, 0x9fdc;
  //SonicGenerations.exe+959A67 - 89 81 DC9F0000        - mov [ecx+00009FDC],eax
  
  //int looks_like_a_manager_class_of_some_kind : 0x00D724CC, 0x668, 0x1c, 0x80, 0xa8;
  //int selected_item_in_pause_menu : 0x00D724CC, 0x668, 0x1c, 0x80, 0xa8, 0x0c;
}

startup
{
  // We are currently loading this script. Set up shit here
  settings.Add("loading_time", true, "Include loading time in gametime");
  settings.Add("pause_game_timer", false, "Pause gametime when game is paused");
  settings.Add("stage_split", false, "Split only when both acts of a stage is completed");

  //settings.Add("catagory", false, "Run Catagory");
  //settings.CurrentDefaultParent = "catagory";
  
  //TODO Do some work to be able to track for 100% catagory
  //settings.Add("100%", false);
  settings.Add("act1_only", false);
  settings.Add("act2_only", false);

  settings.CurrentDefaultParent = null;
}
 
init
{
  if (modules.First().ModuleMemorySize == 0x1CAB000)
    version = "latest";

  // stage_id
  vars.stage_table = new Dictionary<string, Tuple<int, bool, bool>>();
  vars.stage_table.Add("pam", new Tuple<int,bool,bool>(01, false, false)); // pam = Overworld
  
  vars.stage_table.Add("ghz", new Tuple<int,bool,bool>(02, false, false)); // ghz = Green Hill
  vars.stage_table.Add("cpz", new Tuple<int,bool,bool>(03, false, false)); // cpz = Chemical Plant
  vars.stage_table.Add("ssz", new Tuple<int,bool,bool>(04, false, false)); // ssz = Sky Sanctuary

  // Bosses
  vars.stage_table.Add("bde", new Tuple<int,bool,bool>(05, false, false)); // bde = Death Egg Robo Boss Fight 
  vars.stage_table.Add("bms", new Tuple<int,bool,bool>(06, false, false)); // bms = Metal Sonic Rival Fight

  vars.stage_table.Add("sph", new Tuple<int,bool,bool>(07, false, false)); // sph = Speed Highway
  vars.stage_table.Add("cte", new Tuple<int,bool,bool>(08, false, false)); // cte = City Escape
  vars.stage_table.Add("ssh", new Tuple<int,bool,bool>(09, false, false)); // ssh = Seaside Hill

  // Bosses
  vars.stage_table.Add("bsd", new Tuple<int,bool,bool>(10, false, false)); // bsd = Shadow Rival Fight
  vars.stage_table.Add("bpc", new Tuple<int,bool,bool>(11, false, false)); // bpc = Perfect Chaos Boss Fight

  vars.stage_table.Add("csc", new Tuple<int,bool,bool>(12, false, false)); // csc = Crisis City
  vars.stage_table.Add("euc", new Tuple<int,bool,bool>(13, false, false)); // euc = Rooftop Run
  vars.stage_table.Add("pla", new Tuple<int,bool,bool>(14, false, false)); // pla = Planet Wisp

  // Bosses
  vars.stage_table.Add("bsl", new Tuple<int,bool,bool>(15, false, false)); // bsl = Silver Rival Fight
  vars.stage_table.Add("bne", new Tuple<int,bool,bool>(16, false, false)); // bne = Egg Dragoon Boss Fight
  
  vars.stage_table.Add("blb", new Tuple<int,bool,bool>(17, false, false)); // blb = Time Eater Boss Fight

  // Extra stages
  vars.stage_table.Add("cnz", new Tuple<int,bool,bool>(18, false, false)); // cnz = Casino Night Zone
  vars.stage_table.Add("fig", new Tuple<int,bool,bool>(19, false, false)); // fig = Figurine Room

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
  if(current.stage_name != "" && current.stage_name.Length > 3)
  {
    vars.stage_code = "" + current.stage_name[0] + current.stage_name[1] + current.stage_name[2];
    vars.act = Convert.ToByte(current.stage_name[3].ToString());
  }
  else
  {
    vars.stage_code = "";
    vars.act = 0;
  }

  if (settings["act1_only"] == true && vars.act == 1 && current.stage_loading == true) {
    vars.DebugOutput("Act1 Timer started");
    return true;
  }
  else if (settings["act2_only"] == true && vars.act == 2 && current.stage_loading == true) {
    vars.DebugOutput("Act2 Timer started");
    return true;
  }
  else if (current.stage_loading == true && old.stage_state == 0xFF && vars.stage_code == "ghz") {
    vars.DebugOutput("Any percent timer started");
    return true;
  }

  return false;
}

update
{
  // Reset some of the varibles that we are about to set
  vars.in_boss = false;

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
    }
    else if (current.stage_name.Length == 3)
    {
      vars.stage_code = current.stage_name;
      vars.in_boss = true;
      if(current.stage_name == "blb")
      {
        vars.in_final_boss = true;
      }
    }
    
    Tuple<int,bool,bool> stage_item;
    if(vars.stage_table.TryGetValue(vars.stage_code.ToString(), out stage_item))
    {
      vars.stage_id = stage_item.Item1;
    }
  }
  else
  {
    //vars.DebugOutput("In cutscene");
  }

  // if the new if statement in the split function works, we won't need this here
  if(current.gui_active != old.gui_active)
  {
    vars.current_stage_state = (current.gui_active == 1);
  }
  
  //vars.DebugOutput("stage_id:"+vars.stage_table[vars.stage_code.ToString()].Item1+"\nact1:"+vars.stage_table[vars.stage_code.ToString()].Item2+"\nact2:"+vars.stage_table[vars.stage_code.ToString()].Item3);

  //vars.DebugOutput("name: "+current.stage_name.ToString()+
  //                 "\nid:"+vars.stage_id.ToString()+
  //                 "\nact:"+vars.act.ToString()+
  //                 "\nisloading:"+current.stage_loading.ToString()+
  //                 "\nin_cutscene:"+current.stage_state.ToString()+
  //                 "\nin_boss:"+vars.in_boss.ToString()+
  //                 "\nin_final_boss:"+vars.in_final_boss.ToString());
}

split
{
  bool rtnValue = false;
  
  //TODO Make sure these conditions work correctly with when doing challange stages.
  if( (vars.stage_id > 1) &&
      (current.num_of_lives == old.num_of_lives) &&
      (current.stage_time > 0.5f) &&
      (current.total_stage_time > 0.5f) &&
      (current.is_paused == false) &&
      (current.total_stage_time != old.total_stage_time) &&
      (current.stage_name == old.stage_name) &&
      (current.gui_active != old.gui_active) &&
      (vars.current_stage_state != vars.prev_stage_state) )
  {
//    vars.DebugOutput("name: "+current.stage_name.ToString()+
//                   "\nid:"+current.is_paused.ToString()+
//                   "\nact:"+vars.act.ToString()+
//                   "\nisloading:"+current.stage_loading.ToString()+
//                   "\nin_cutscene:"+current.stage_state.ToString()+
//                   "\nin_boss:"+vars.in_boss.ToString()+
//                   "\nin_final_boss:"+vars.in_final_boss.ToString());

    vars.DebugOutput("Split condition triggered"); 
    vars.prev_stage_state = vars.current_stage_state;
    rtnValue = true;
    
    Tuple<int,bool,bool> stage_item;
    if(vars.stage_table.TryGetValue(vars.stage_code.ToString(), out stage_item))
    {
      if(vars.act == 1)
        vars.stage_table[vars.stage_code.ToString()] = new Tuple<int,bool,bool>(stage_item.Item1, true, stage_item.Item3);
      else if(vars.act == 2)
        vars.stage_table[vars.stage_code.ToString()] = new Tuple<int,bool,bool>(stage_item.Item1, stage_item.Item2, true);
      else if(vars.in_boss == true)
        vars.stage_table[vars.stage_code.ToString()] = new Tuple<int,bool,bool>(stage_item.Item1, true, true);
      
      if(settings["stage_split"] == true)
      {
        if((vars.stage_table[vars.stage_code.ToString()].Item2 == false ||
           vars.stage_table[vars.stage_code.ToString()].Item3 == false) )
        {
          rtnValue = false;
        }
        
        // Maybe we want to do other things here?
      }
    }
    
    if(settings["act1_only"] == true && vars.act == 1)
    {
      return true;
    }
    else if(settings["act2_only"] == true && vars.act == 2)
    {
      return true;
    }
  }
  return rtnValue;
}
 
isLoading
{
  if(settings["act1_only"] == true && vars.act == 2)
    return true;
  else if(settings["act2_only"] == true && vars.act == 1)
    return true;

  // Only count loading if we set it up like that
  return (!settings["loading_time"] && ((vars.stage_id == 1) || current.stage_loading)) || 
         (settings["pause_game_timer"] && (current.is_paused == true));
}

gameTime
{
  if(vars.stage_id == 1)
    return TimeSpan.FromSeconds( 0 );
  
  //TODO Find out if you died that way we keep ticking the counter
  //TODO create a buffer for the time here as the total_stage_time resets when changing stages
  return TimeSpan.FromSeconds( Convert.ToDouble(current.stage_time) );
}
