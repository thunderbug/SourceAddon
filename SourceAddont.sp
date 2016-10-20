#include <sourcemod>

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
	PrintToServer("Hello world!");
	
	char error[255];
	Database db = SQL_DefConnect(error, sizeof(error));
	
	 
	if (db == null)
	{
		PrintToServer("Could not connect: %s", error);
	} 
	else 
	{
		delete db;
	}
}