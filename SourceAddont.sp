#include <sourcemod>
#include <socket>

Database db;
ConVar sv_addonID;

int addonID;

bool checkLevel[64];

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
	} else {
		PrintToServer("[Addon] Connected to mysql server");
	}
	
	new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);
	SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "obelix.justforfun-gaming.com", 53259);
	
	sv_addonID = CreateConVar("sv_addonid", "1", "AddonID");
}

public void OnConfigsExecuted()
{
	addonID = sv_addonID.IntValue;
}


//PlayerListeners
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
	Format(query, sizeof(query), "INSERT INTO `users_online%i` VALUES ('%i', '%s', '%i', '%s', '0', '0', '0', '%i', '%s')", addonID, client, playerName, client, playerIP, team, playerGuid);

	SQL_FastQuery(db, query);
	
	checkLevel[client] = false;
	
	decl String:masterLevel[100];
	Format(masterLevel, sizeof(masterLevel), "110;%s\n", playerIP);
	SocketSend(socket, masterLevel);	
}

public void void OnClientDisconnect(int client)
{
	char query[200];
	Format(query, sizeof(query), "DELETE FROM `users_online%i` WHERE `users_online_id` = '%i';", addonID, client);
	
	SQL_FastQuery(db, query);
}

//SocketListeners
public OnSocketConnected(Handle:socket, any:arg) {
	PrintToServer("[Addon] Connected to master server");
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize) {
	for (new i = 1; i <= 64; i++)
	{
		if(!checkLevel[i]){
			//Update query
			char query[200];
			Format(query, sizeof(query), "UPDATE `users_online%i` SET `users_online_level` = '%s' WHERE `users_online_id` = '%i';", addonID, receiveData, i);
	
			SQL_FastQuery(db, query);
		}
	}
}

public OnSocketDisconnected(Handle:socket) {
	CloseHandle(socket);
	
	PrintToServer("[Addon] Master Server Disconnected");
	
	SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "obelix.justforfun-gaming.com", 53259);
}

public OnSocketError(Handle:socket, const errorType, const errorNum) {
	CloseHandle(socket);
	
	PrintToServer("[Addon] Master Server Disconnected");
	
	SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "obelix.justforfun-gaming.com", 53259);
}