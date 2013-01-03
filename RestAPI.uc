class RestAPI extends WebApplication;

event Init() {
  Super.Init();
}

// Router
function Query(WebRequest Request, WebResponse Response) {
	switch(Request.URI) {
		case "/server": GetServer(Request, Response); break;
		case "/players": GetPlayers(Request, Response); break;
		default: Response.HTTPError(404, "");
	}
}

function GetServer(WebRequest Request, WebResponse Response) {
	local array<string> output;
	local string json;
	local string callback;
	local GameInfo.ServerResponseLine ServerState;
	
	Level.Game.GetServerInfo(ServerState);
	PushProperty(output, "server_name", Level.Game.GameReplicationInfo.ServerName);
	PushProperty(output, "map_name", ServerState.MapName);
	
	json = "{" $ Join(output, ",") $ "}";
	callback = Request.GetVariable("callback");
	if(callback != "") {
		json = callback $ "(" $ json $ ")";
	}
	
	Response.SendText(json);
	//Response.SendStandardHeaders("image/jpeg", true);
	// can Response.IncludeBinaryFile( Path $ Image ); be used for the overview map?
}

function GetPlayers(WebRequest Request, WebResponse Response) {
	local Controller P;
	local PlayerReplicationInfo PRI;
	local array<string> players;
	local array<string> player;
	local string json;
	local string callback;
	
	for(P = Level.ControllerList; P != None; P = P.NextController) {
		if( !P.bDeleteMe && P.bIsPlayer && P.PlayerReplicationInfo != None) {
			if(P.Pawn != None) {
				PRI = P.PlayerReplicationInfo;
				player.Length = 0;
				PushProperty(player, "id", string(PRI.PlayerID));
				PushProperty(player, "roid", PlayerController(P).GetPlayerIDHash());
				PushProperty(player, "name", PRI.PlayerName);
				PushProperty(player, "team_index", string(PRI.Team.TeamIndex));
				players[players.Length] = "{" $ Join(player, ",") $ "}";
			}
		}
	}
	json = "[" $ Join(players, ",") $ "]";
	callback = Request.GetVariable("callback");
	if(callback != "") {
		json = callback $ "(" $ json $ ")";
	}
	Response.SendText(json);
}

function PushProperty(out array<string> ar, string key, string val) {
	ReplaceText(val, "\\", "\\\\"); // Replace backslash with double backslash
	ReplaceText(val, "\"", "\\\""); // Replace " with \"
	ar[ar.Length] = "\"" $ key $ "\":\"" $ val $ "\"";
}

/* 
 * Array Join function (convert array to string with delimiter, like php's implode() function)
 * Source: http://wiki.beyondunreal.com/Legacy:AutoLoader
 */
static final function string Join(array< string > ar, optional string delim, optional bool bIgnoreEmpty) {
	local string result;
	local int i;
	for (i = 0; i < ar.length; i++) {
		if (bIgnoreEmpty && ar[i] == "") continue;
		if (result != "") result = result$delim;
		result = result$ar[i];
	}
	return result;
}
