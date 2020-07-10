#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike>
#include <clientprefs>
#include <sdkhooks>
#include <sdktools>

public Plugin myinfo =
{
    name = "[CS] Single Shot",
    author = "c0rp3n",
    description = "A plugin that allows players to choose whether to force weapons to be single shot.",
    version = "1.0.0",
    url = "www.github.com/c0rp3n/cp-sm-misc"
};

Cookie g_ckFireMode = null;

int m_iAmmo, m_hActiveWeapon, m_iClip1, /*m_iPrimaryAmmoType*/, m_iPrimaryReserveAmmoCount;

bool g_bEnabled[MAXPLAYERS + 1] = { false, ... };
bool g_bHasShot[MAXPLAYERS + 1] = { false, ... };

int g_iClip[MAXPLAYERS + 1] = { 0, ... };
int g_iReserve[MAXPLAYERS + 1] = { 0, ... };

public void OnPluginStart()
{
    // Find and store offsets properly, because those will be used a bit often
    m_iAmmo                    = FindSendPropInfo("CBasePlayer",       "m_iAmmo");
    m_hActiveWeapon            = FindSendPropInfo("CBasePlayer",       "m_hActiveWeapon");
    m_iClip1                   = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
    //m_iPrimaryAmmoType         = FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryAmmoType");
    m_iPrimaryReserveAmmoCount = FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryReserveAmmoCount");

    // Cookies
    g_ckFireMode = new Cookie("cp_single_shot_enabled", "Whether single shot is enabled.", CookieAccess_Private);

    RegConsoleCmd("sm_singleshot", Command_SingleShot, "");
    RegAdminCmd("sm_checkammo", Command_CheckAmmo, ADMFLAG_CHEATS, "checks the current weapons ammo.");

    HookEvent("weapon_fire", Event_PlayerWeaponFire, EventHookMode_Post);
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponSwitch, Hook_WeaponSwitch);
    SDKHook(client, SDKHook_WeaponEquipPost, Hook_WeaponEquipPost);
}

public void OnClientCookiesCached(int client)
{
    char buffer[8];
    g_ckFireMode.Get(client, buffer, sizeof(buffer));
    g_bEnabled[client] = view_as<bool>(StringToInt(buffer));
}

public Action OnPlayerRunCmd(int client, int& buttons)
{
    if (g_bEnabled[client])
    {
        if (g_bHasShot[client])
        {
            if (buttons & IN_ATTACK)
            {
                buttons = buttons & ~IN_ATTACK;

                return Plugin_Changed;
            }
            else
            {
                g_bHasShot[client] = false;
                RestoreClientAmmo(client, GetClientActiveWeapon(client));
            }
        }
    }

    return Plugin_Continue;
}

public Action Command_SingleShot(int client, int argc)
{
    Panel panel = new Panel();
    panel.SetTitle("Single Shot");
    if (g_bEnabled[client])
    {
        panel.DrawText("Single Shot is currently Enabled.");
    }
    else
    {
        panel.DrawText("Single Shot is currently Disabled.");
    }
    panel.DrawItem("Enable", ITEMDRAW_CONTROL);
    panel.DrawItem("Disable", ITEMDRAW_CONTROL);
    panel.CurrentKey = 9;
    panel.DrawItem("Exit", ITEMDRAW_CONTROL);

    panel.Send(client, MenuHandler_SingleShot, 60);

    return Plugin_Handled;
}

public Action Command_CheckAmmo(int client, int argc)
{
    int weapon = GetClientActiveWeapon(client);
    int clip = GetWeaponClip(weapon);
    int reserve = GetClientReserve(weapon);
    int reserve2 = GetEntData(weapon, m_iPrimaryReserveAmmoCount);

    ReplyToCommand(client, "[SS] CheckAmmo - weapon: %d, clip: %d, reserve: %d, reserve2: %d", weapon, clip, reserve, reserve2);

    return Plugin_Handled;
}

public Action Hook_WeaponSwitch(int client, int weapon)
{
    if (g_bEnabled[client])
    {
        int cweapon = GetClientActiveWeapon(client);
        if (IsClientWeaponValid(client, cweapon))
        {
            RestoreClientAmmo(client, cweapon);

            return Plugin_Changed;
        }
    }

    return Plugin_Continue;
}

public void Hook_WeaponEquipPost(int client, int weapon)
{
    if (g_bEnabled[client])
    {
        int cweapon = GetClientActiveWeapon(client);
        if (IsClientWeaponValid(client, cweapon))
        {
            StoreClientAmmo(client, cweapon);
        }
    }
}

public void Event_PlayerWeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0)
    {
        if (g_bEnabled[client])
        {
            int weapon = GetClientActiveWeapon(client);
            if (IsClientWeaponValid(client, weapon))
            {
                g_bHasShot[client] = true;
                RequestFrame(Frame_PostPlayerWeaponFire, GetClientUserId(client));
            }
        }
    }
}

public void Frame_PostPlayerWeaponFire(int userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0)
    {
        int weapon = GetClientActiveWeapon(client);
        if (IsClientWeaponValid(client, weapon))
        {
            StoreClientAmmo(client, weapon);
            ClearClientAmmo(client, weapon);
        }
    }
}

public int MenuHandler_SingleShot(Menu menu, MenuAction action, int param1, int param2)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            int enabled = 0;
            if (param2 == 1)
            {
                g_bEnabled[param1] = true;
                PrintToChat(param1, "[SM] You enabled single shot.");
                enabled = 1;

                int weapon = GetClientActiveWeapon(param1);
                if (IsClientWeaponValid(param1, weapon))
                {
                    StoreClientAmmo(param1, weapon);
                }
            }
            else if (param2 == 2)
            {
                g_bEnabled[param1] = false;
                PrintToChat(param1, "[SM] You disabled single shot.");
                enabled = 0;
            }
            else
            {
                return 0;
            }

            char buffer[4];
            IntToString(enabled, buffer, sizeof(buffer));
            g_ckFireMode.Set(param1, buffer);

            return 0;
        }
        case MenuAction_End:
        {
            delete menu;

            return 0;
        }
    }

    return 0;
}

bool IsClientWeaponValid(int client, int weapon)
{
    return weapon > 0 && (weapon == GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) ||
                          weapon == GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY));
}

void StoreClientAmmo(int client, int weapon)
{
    g_iClip[client] = GetWeaponClip(weapon);
    g_iReserve[client] = GetClientReserve(weapon);

    PrintToConsole(client, "[SS] StoreClientAmmo - weapon: %d, clip: %d, reserve: %d", weapon, g_iClip[client], g_iReserve[client]);
}

void ClearClientAmmo(int client, int weapon)
{
    SetWeaponClip(weapon, 0);
    SetClientReserve(weapon, 0);

    PrintToConsole(client, "[SS] ClearClientAmmo - weapon: %d, clip: %d, reserve: %d", weapon, g_iClip[client], g_iReserve[client]);
}

void RestoreClientAmmo(int client, int weapon)
{
    SetWeaponClip(weapon, g_iClip[client]);
    SetClientReserve(weapon, g_iReserve[client]);

    PrintToConsole(client, "[SS] RestoreClientAmmo - weapon: %d, clip: %d, reserve: %d", weapon, g_iClip[client], g_iReserve[client]);
}

/*
int GetWeaponAmmoIndex(int weapon)
{
    return GetEntData(weapon, m_iPrimaryAmmoType) * 4;
}
*/

int GetClientActiveWeapon(int client)
{
    return GetEntDataEnt2(client, m_hActiveWeapon);
}

int GetWeaponClip(int weapon)
{
    return GetEntData(weapon, m_iClip1);
}

int GetClientReserve(int weapon)
{
    return GetEntData(weapon, m_iPrimaryReserveAmmoCount);
}

void SetWeaponClip(int weapon, int ammo)
{
    SetEntData(weapon, m_iClip1, ammo, 4, true);
}

void SetClientReserve(int weapon, int ammo)
{
    SetEntData(weapon, m_iPrimaryReserveAmmoCount, ammo, 4, true);
}
