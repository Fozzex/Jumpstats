#include <sourcemod>
#include <sdktools>

#include <fjs-core>
#include <fjs-zones>

#pragma semicolon 1
#pragma newdecls required

bool g_PluginZonesExists;

public void OnPluginStart()
{
    RegConsoleCmd("sm_zone", Command_Zone);
}

public Action Command_Zone(int client, int args)
{
    g_PluginZonesExists = LibraryExists("fjs-zones");

    OpenZoneMenu(client);
    return Plugin_Handled;
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual("fjs-zones", name))
    {
        g_PluginZonesExists = true;
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual("fjs-zones", name))
    {
        g_PluginZonesExists = false;
    }
}

void OpenZoneMenu(int client)
{
    Menu zoneMenu = new Menu(ZoneMenuHandler);

    zoneMenu.SetTitle("Create Zone");
    zoneMenu.AddItem("Set Zone Brush", "Set Zone Brush");
    zoneMenu.ExitButton = true;
    zoneMenu.Display(client, MENU_TIME_FOREVER);
}

public int ZoneMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        if (param2 == 0)
        {
            Stats_CreateZoneFromClient(param1);
            OpenZoneMenu(param1);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}
