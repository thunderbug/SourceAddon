#include <sourcemod>
#include <socket>

Database db;
ConVar sv_addonID;
Handle Socket;
Handle Socket2;

int addonID;

int checkLevel[65];
int userID[65];
int playtime[65];

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
	
	Socket = SocketCreate(SOCKET_TCP, OnSocketError);
	SocketConnect(Socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "obelix.justforfun-gaming.com", 53259);
	Socket2 = SocketCreate(SOCKET_TCP, OnSocketError);
	SocketConnect(Socket2, OnSocketConnected, OnSocketReceive2, OnSocketDisconnected, "obelix.justforfun-gaming.com", 53259);
	
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
	
	//Get Level
	checkLevel[client] = 1;
	decl String:masterLevel[100];
	Format(masterLevel, sizeof(masterLevel), "110;%s\n", playerIP);
	SocketSend(Socket, masterLevel);
	
	//Get Playtime + userID
	userID[client] = -1;
	
	decl String:masterUserID[100];
	Format(masterUserID, sizeof(masterUserID), "111;%s\n", playerIP);
	SocketSend(Socket2, masterUserID);
	
	int getTime = GetTime();
	playtime[client] = getTime;
}

public void OnClientDisconnect(int client)
{
	char query[200];
	Format(query, sizeof(query), "DELETE FROM `users_online%i` WHERE `users_online_id` = '%i';", addonID, client);
	
	SQL_FastQuery(db, query);
	
	if(userID[client] > 0){	
		int getTime = GetTime();
		int t = getTime - playtime[client];
		
		if(t != getTime)
		{
			Format(query, sizeof(query), "INSERT INTO `log_playtime` (`userID`, `addonID`, `time`) VALUES ('%i', '%i', '%i')", userID[client], addonID, t);
			PrintToServer(query);
			SQL_FastQuery(db, query);
		}	
	}
}

//SocketListeners
public OnSocketConnected(Handle:socket, any:arg) {
	PrintToServer("[Addon] Connected to master server");
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:hFile) {
	for (new i = 1; i <= 64; i++)
	{
		if(checkLevel[i]  == 1){
			//Update query
			char query[200];
			Format(query, sizeof(query), "UPDATE `users_online%i` SET `users_online_level` = '%s' WHERE `users_online_id` = '%i';", addonID, receiveData, i);
			PrintToServer(query);
			SQL_FastQuery(db, query);
				
			checkLevel[i] = 2;
				
			break;
		}
	}
}

public OnSocketReceive2(Handle:socket, String:receiveData[], const dataSize, any:hFile) {
	for (new i = 1; i <= 64; i++)
	{		
		if(userID[i] == -1)
		{
			userID[i] = StringToInt(receiveData);
			
			break;
		}
	}
}

public OnSocketDisconnected(Handle:socket, any:hFile) {
	CloseHandle(Socket);
	CloseHandle(Socket2);
	
	PrintToServer("[Addon] Master Server Disconnected");
	
	SocketConnect(Socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "obelix.justforfun-gaming.com", 53259);
	SocketConnect(Socket2, OnSocketConnected, OnSocketReceive2, OnSocketDisconnected, "obelix.justforfun-gaming.com", 53259);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:hFile) {
	CloseHandle(Socket);
	CloseHandle(Socket2);
	
	PrintToServer("[Addon] Master Server Disconnected");
	
	SocketConnect(Socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "obelix.justforfun-gaming.com", 53259);
	SocketConnect(Socket2, OnSocketConnected, OnSocketReceive2, OnSocketDisconnected, "obelix.justforfun-gaming.com", 53259);
}