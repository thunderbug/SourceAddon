#include <sourcemod>

Database db;

public Plugin:myinfo = 
{
	name = "Source Addon",
	author = "=[JFF]=Thunder",
	description = "JustForFun Addon",
	version = "1.0.0",
	url = "http://justforfun-gaming.com"
}


public void OnPluginStart()
{
	PrintToServer("Started Addon Server for sourcemod");
	
	char error[255];
	db = SQL_DefConnect(error, sizeof(error));
	
	 
	if (db == null)
	{
		PrintToServer("Could not connect: %s", error);
	}
}

public void OnClientPostAdminCheck(int client)
{		
	decl String:playerName[64];
	GetClientName(client, playerName, sizeof(playerName));
	
	decl String:playerIP[16]
	GetClientIP(client, playerIP, sizeof(playerIP), true);
	
	int team = GetClientTeam(client);
		
	decl String:playerGuid[32];
	GetClientAuthId(client, AuthId_Steam3, playerGuid, sizeof(playerGuid));
	
	char query[200];
	Format(query, sizeof(query), "INSERT INTO `users_online1` VALUES ('%i', '%s', '%i', '%s', '0', '0', '0', '%i', '%s')", client, playerName, client, playerIP, team, playerGuid);

	SQL_FastQuery(db, query);
}