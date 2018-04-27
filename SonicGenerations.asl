state("SonicGenerations", "v2")
{
  float StageTime : 0x01A0BE5C, 0x08, 0x184;
  float TotalStageTime : 0x01A0BE5C, 0x08, 0x188;
  bool stageLoading : 0x01A0BE5C, 0x08, 0x1a8;

  // This address (hitGoal) does the job most of the time (if you die it messes this address up).
  ulong hitGoal : 0x01A0BE5C, 0x08, 0xa0;
  
  byte paused : 0x01A0BE5C, 0x08,0xD0;
  string6 stageName : 0x01A0BE5C, 0x08, 0x88, 0x00;
  byte stageType : 0x01A0BE5C, 0x08, 0x88, 0x07;
  byte inComboSeq : 0x01A0BE5C, 0x08, 0x19c;
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
    version = "v2";

  //StageID 
  // pam = Overworld
  // ghz = Green Hill
  // cpz = Chemical Plant
  // ssz = Sky Sanctuary
  // sph = Speed Highway
  // cte = City Escape
  // ssh = Seaside Hill
  // csc = Crisis City
  // euc = Rooftop Run
  // pla = Planet Wisp
  
  //Bosses
  // bde = DeathEgg Robot
  // bpc = Perfect Chaos
  // bne = Egg Dragoon
  // blb = Time Eater
  vars.stageDict = new Dictionary<string, byte>();
  vars.stageDict.Add("pam", 1);
  vars.stageDict.Add("ghz", 2);
  vars.stageDict.Add("cpz", 3);
  vars.stageDict.Add("ssz", 4);
  vars.stageDict.Add("sph", 5);
  vars.stageDict.Add("cte", 6);
  vars.stageDict.Add("ssh", 7);
  vars.stageDict.Add("csc", 8);
  vars.stageDict.Add("euc", 9);
  vars.stageDict.Add("pla", 10);
  
  vars.stageDict.Add("bde", 11);
  vars.stageDict.Add("bpc", 12);
  vars.stageDict.Add("bne", 13);
  vars.stageDict.Add("blb", 14);

  vars.act = 0;
  vars.stageID = 0;
  vars.stageCode = "";
  vars.inBoss = false;
  vars.finalBoss = false;
  vars.prevStageEnd = false;
  vars.currentStageEnd = false;
  
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
  vars.stageID = 0;
  vars.stageCode = "";
  vars.inBoss = false;
  vars.finalBoss = false;
  vars.prevStageEnd = false;
  vars.currentStageEnd = false;
}

start
{
  if(current.stageName != null && current.stageName.Length > 3)
  {
    vars.act = Convert.ToByte(current.stageName[3].ToString());
  }

	if (settings["any_percent"] == true && current.stageLoading == true && vars.stageID == 1) {
		vars.DebugOutput("Any percent timer started");
		return true;
	}
  else if (settings["act1_only"] == true && vars.act == 1 && current.stageLoading == true) {
    vars.DebugOutput("Act1 Timer started");
		return true;
	}
  else if (settings["act2_only"] == true && vars.act == 2 && current.stageLoading == true) {
    vars.DebugOutput("Act2 Timer started");
		return true;
	}
  return false;
}

update
{
  // Reset some of the varibles that we are about to set
  vars.inBoss = false;
  vars.finalBoss = false;
  
  if(current.stageName != old.stageName)
  {
    vars.prevStageEnd = vars.currentStageEnd = false;
  }
  
  if(current.stageType == 0x00 && current.stageName != null) // This is always 0 unless a cutscene is running
  {  
    if(current.stageName.Length > 3)
    {
      vars.act = Convert.ToByte(current.stageName[3].ToString());
      vars.stageCode = "" + current.stageName[0] + current.stageName[1] + current.stageName[2];
      byte tempId = 0;
      if(vars.stageDict.TryGetValue(vars.stageCode.ToString(), out tempId))
      {
        vars.stageID = tempId;
      }
    }
    else if (current.stageName.Length == 3)
    {
      vars.inBoss = true;
      if(current.stageName == "blb")
      {
        vars.finalBoss = true;
        vars.DebugOutput("In final boss");
      }
      
    }
  }
  else
  {
    vars.DebugOutput("In cutscene");
  }
  
  //vars.DebugOutput("name: "+current.stageName.ToString()+" id:"+vars.stageID.ToString()+" act:"+vars.act.ToString()+" isloading:"+current.stageLoading.ToString());
  
  if(current.hitGoal != old.hitGoal)
  {
    vars.currentStageEnd = true;
  }
}

split
{
  //TODO See if I can update different segments
  //TODO Need to find out how to tell if the stage ended
  if(vars.stageID > 1 && vars.currentStageEnd != vars.prevStageEnd)
  {
    vars.prevStageEnd = vars.currentStageEnd;
    if(settings["any_percent"] == true)
    {
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
  return (!settings["loading_time"] && ((vars.stageID == 1) ||current.stageLoading));
}