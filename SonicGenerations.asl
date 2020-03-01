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
  //ulong goal_hit : 0x01A0BE5C, 0x08, 0xa0, 0x00; // Depercated
  
  // Gui active gives a much better result as it only ever is set to 1 when you have a gui like the goal screen is active
  //short gui_active : 0x01A66B34, 0x04, 0x34, 0x58, 0x1c, 0xb5; // Depercated
  //SonicGenerations.exe+902AC1 = the address to the code that changes this

  // If the game is paused, this is true
  bool is_paused : 0x01A0BE5C, 0x08,0xD0;
  
  // 1 = sliding/crouched state
  // 2 = boosting
  // 7 = dead? (classic sonic seems to love setting this to 7 even though he isn't dead)
  byte character_state : 0x01A5E2F0, 0x118c;
  
  // 0 = in control
  // 1 = bumpers?
  // 2 = not in control
  //byte character_control_state : 0x01A5E2F0, 0x760; // Depercated

  // Name of the stage we are currently on
  string6 stage_name : 0x01A0BE5C, 0x08, 0x88, 0x00;

  // This is not zero when in a cutscene (Needs more testing).
  byte stage_state : 0x01A0BE5C, 0x08, 0x88, 0x07;

  // When you hit a combo bumper or ring, this becomes true. (Just here because it may be useful later)
  //bool in_combo_seq : 0x01A0BE5C, 0x08, 0x19c;
  //byte num_of_combos : 0x01A5E2F0, 0x1210;
  
  // Current game frame counter (only ticks if the game is rendering, aka has focus)
  int frame_counter : 0x01A66B34, 0x04, 0xd4;
  
  // The number of lives you have
  byte num_of_lives : 0x01A66B34, 0x04, 0x1b4, 0x7c, 0x9fdc;  
  
  // 0x01 = no goal hit
  // 0x02 = goal hit
  // After you hit the goal, this doesn't reset until you go back to the overworld.
  // Meaning hitting "Play Again" will not allow you to split again
  byte stage_progress : 0x01A66B34, 0x04, 0x168, 0x94, 0x88;
  
  // 0x17 == Death Egg
  // 0x1B == Overworld
  // 0x20 == Start screen
  // even numbers is classic, odd is modern
  byte map_id : 0x01A66B34, 0x04, 0x168, 0x94, 0x8C;
  
  // Will be 0 if not in a challenge, otherwise this will be the challenge id
  byte challenge_id : 0x01A66B34, 0x04, 0x168, 0x94, 0x8D;
  //SonicGenerations.exe+959A67 - 89 81 DC9F0000        - mov [ecx+00009FDC],eax
  
  // Speed Address
  //SonicGenerations.exe+DA26D8 - F3 0F11 80 AC000000   - movss [eax+000000AC],xmm0
  float move_speed : 0x01A66B34, 0x04, 0x210, 0x0C, 0xA4, 0x6C, 0x04, 0xAC, 0xAC;
}

startup
{
  // We are currently loading this script. Set up shit here
  settings.Add("loading_time", true, "Remove load times from gametime");
  settings.Add("pause_game_timer", false, "Pause gametime when game is paused");
  settings.Add("stage_split", false, "Split only when both acts of a stage is completed (does not include challanges)");
  settings.Add("always_total_gt", true, "Show total game time during stages instead of total time on current stage (overworld always shows total sum of stages)");

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
  vars.lives = 0;
  vars.stage_id = 0;
  vars.stage_code = "";
  vars.in_boss = false;
  vars.in_final_boss = false;
  vars.prev_stage_state = false;
  vars.current_stage_state = false;
  vars.final_stage_state = false;
  
  vars.currentCalcGameTime = 0;
  vars.gameTimeBuffer = 0;
  vars.totalGameTime = 0;
  vars.totalStageTime = 0;
  vars.totalStageDelta = 0;
  vars.stage_time_dt = 0;

  Action<string> DebugOutput = (text) => {
    print("[SonicGenerations Autosplitter] "+text);
  };
  vars.DebugOutput = DebugOutput;
}
 
exit
{
  // Connected game closed. Do stuff if needed here
  vars.act = 0;
  vars.lives = 0;
  vars.stage_id = 0;
  vars.stage_code = "";
  vars.in_boss = false;
  vars.in_final_boss = false;
  vars.prev_stage_state = false;
  vars.current_stage_state = false;
  vars.final_stage_state = false;
  vars.currentCalcGameTime = 0;
  vars.gameTimeBuffer = 0;
  vars.totalGameTime = 0;
  vars.totalStageTime = 0;
  vars.totalStageDelta = 0;
  vars.stage_time_dt = 0;
}

start
{
  if(current.stage_name != "" && current.stage_name.Length > 3)
  {
    vars.stage_code = "" + current.stage_name[0] + current.stage_name[1] + current.stage_name[2];
    vars.act = Convert.ToByte(current.stage_name[3].ToString());
    vars.lives = current.num_of_lives;
  }
  else
  {
    vars.stage_code = "";
    vars.act = 0;
  }
  
//  if(timer.Run.CategoryName == "Any%")
//    print("[SonicGenerations Autosplitter] "+"Category is Any%");
//  else if(timer.Run.CategoryName == "100%")
//    print("[SonicGenerations Autosplitter] "+"Category is 100%");
//  else if(timer.Run.CategoryName == "All Classic Stages")
//    print("[SonicGenerations Autosplitter] "+"Category is All Classic Stages");
//  else if(timer.Run.CategoryName == "All Modern Stages")
//    print("[SonicGenerations Autosplitter] "+"Category is All Modern Stages");

  if (timer.Run.CategoryName == "All Classic Stages" && vars.act == 1 && current.stage_loading == true) {
    vars.DebugOutput("Act1 Timer started");
    return true;
  }
  else if (timer.Run.CategoryName == "All Modern Stages" && vars.act == 2 && current.stage_loading == true) {
    vars.DebugOutput("Act2 Timer started");
    return true;
  }
  else if (timer.Run.CategoryName == "Any%" && current.stage_loading == true && old.stage_state == 0xFF && vars.stage_code == "ghz") {
    vars.DebugOutput("Any% timer started");
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
    vars.final_stage_state = vars.prev_stage_state = vars.current_stage_state = false;
  }
  
  if( current.stage_time == 0 && 
    current.total_stage_time > 0 && 
    current.total_stage_time != old.total_stage_time)
    vars.totalStageDelta = current.total_stage_time;

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
  if(current.stage_progress == 0x02 && vars.in_final_boss == false)
  {
    vars.current_stage_state = true;
  }
  
  vars.stage_time_dt = Math.Round(current.total_stage_time - current.stage_time - vars.totalStageDelta, 3);
  
  if(current.is_paused == false && 
    current.stage_time > 0 &&
    Convert.ToDouble(current.stage_time) == Convert.ToDouble(old.stage_time) && 
    Convert.ToDouble(current.total_stage_time) != Convert.ToDouble(old.total_stage_time) && 
    vars.stage_time_dt > 0.1f &&
    current.map_id == 26)
  {
    //vars.DebugOutput("BLB Split condition triggered");
    vars.final_stage_state = vars.current_stage_state = true;
  }
  
  
  if(current.num_of_lives != old.num_of_lives)
  {
    vars.lives = current.num_of_lives;
    
    if(current.num_of_lives < old.num_of_lives)
    {
      vars.gameTimeBuffer = current.stage_time;
    }
  }
}

split
{
  bool rtnValue = false;
  
  //TODO Make sure these conditions work correctly with when doing challange stages.
  if( (current.map_id != 0x1b) &&
      (current.stage_time > 0.5f) &&
      (current.total_stage_time > 0.5f) &&
      (current.is_paused == false) &&
      (current.total_stage_time != old.total_stage_time) &&
      (current.stage_name == old.stage_name) &&
      (vars.current_stage_state != vars.prev_stage_state) )
  {
    vars.DebugOutput("Split condition triggered"); 
    vars.prev_stage_state = vars.current_stage_state;
    rtnValue = true;
    
    vars.totalGameTime += vars.totalStageTime + current.stage_time;
    vars.totalStageTime = vars.gameTimeBuffer = 0;
    
    Tuple<int,bool,bool> stage_item;
    if(vars.stage_table.TryGetValue(vars.stage_code.ToString(), out stage_item))
    {
      if(vars.act == 1)
        vars.stage_table[vars.stage_code.ToString()] = new Tuple<int,bool,bool>(stage_item.Item1, true, stage_item.Item3);
      else if(vars.act == 2)
        vars.stage_table[vars.stage_code.ToString()] = new Tuple<int,bool,bool>(stage_item.Item1, stage_item.Item2, true);
      else if(vars.in_boss == true)
        vars.stage_table[vars.stage_code.ToString()] = new Tuple<int,bool,bool>(stage_item.Item1, true, true);
      
      if(settings["stage_split"] == true && current.challenge_id == 0x00)
      {
        if((vars.stage_table[vars.stage_code.ToString()].Item2 == false ||
           vars.stage_table[vars.stage_code.ToString()].Item3 == false) )
        {
          rtnValue = false;
        }
        
        // Maybe we want to do other things here?
      }
    }
    
    if(timer.Run.CategoryName == "All Classic Stages" && vars.act == 2)
    {
      return false;
    }
    else if(timer.Run.CategoryName == "All Modern Stages" && vars.act == 1)
    {
      return false;
    }
  }
  return rtnValue;
}
 
isLoading
{
  if(timer.Run.CategoryName == "All Classic Stages" && vars.act == 2)
    return true;
  else if(timer.Run.CategoryName == "All Modern Stages" && vars.act == 1)
    return true;

  // Not sure if we should count overworld as part of gametime or not
  if((settings["loading_time"] && (((timer.Run.CategoryName != "Any%") && current.map_id == 27) || current.stage_loading)) || 
     (settings["pause_game_timer"] && (current.is_paused == true)))
    return true;
  // We do not meet the conditions, not loading
  return false;
}

gameTime
{
  if(current.stage_loading || (((timer.Run.CategoryName != "Any%") && current.map_id == 27))) {
    vars.currentCalcGameTime = vars.totalStageTime = vars.gameTimeBuffer = 0;
    return TimeSpan.FromSeconds( vars.totalStageTime );
  }
  
  if( vars.gameTimeBuffer > 0 && (current.stage_time < 1) && (current.stage_time < vars.gameTimeBuffer) )
  {
    vars.totalStageTime += vars.gameTimeBuffer;
    vars.gameTimeBuffer = 0;
  }
  
  if(settings["always_total_gt"])
    vars.currentCalcGameTime = Convert.ToDouble(vars.totalGameTime + vars.totalStageTime + current.stage_time);
  else
    vars.currentCalcGameTime = Convert.ToDouble(vars.totalStageTime + current.stage_time);

  return TimeSpan.FromSeconds( vars.currentCalcGameTime );
}
