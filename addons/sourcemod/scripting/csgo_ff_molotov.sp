#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

ConVar g_cEnabled = null;

public Plugin myinfo =
{
    name = "[CS:GO] FF ex Molotov",
    author = "c0rp3n",
    description = "Protects players from Friendly-Fire (FF) but allows for Molotov damage",
    version = "1.0.0",
    url = "www.github.com/c0rp3n"
};

public void OnPluginStart()
{
    // Cvars
    g_cEnabled = CreateConVar("sm_ff_molotov_enabled", "1", "Whether the plugin is enabled");

    AutoExecConfig();
}

public void OnConfigsExecuted()
{
    HookConVarChange(g_cEnabled, OnConVarChanged);

    // Late load clients
    if (g_cEnabled.BoolValue)
    {
        for (int i = 1; i < MaxClients; ++i)
        {
            if (IsClientConnected(i) && IsClientInGame(i))
            {
                OnClientPutInServer(i);
            }
        }
    }
}

public void OnClientPutInServer(int client)
{
    if (g_cEnabled.BoolValue)
    {
        SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeAliveDamage);
    }
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (convar.BoolValue)
    {
        for (int i = 1; i < MaxClients; ++i)
        {
            if (IsClientConnected(i) && IsClientInGame(i))
            {
                SDKHook(i, SDKHook_OnTakeDamageAlive, Hook_OnTakeAliveDamage);
            }
        }
        PrintToChatAll("[FFexM] Friendly-Fire is now enabled.");
    }
    else
    {
        for (int i = 1; i < MaxClients; ++i)
        {
            if (IsClientConnected(i) && IsClientInGame(i))
            {
                SDKUnhook(i, SDKHook_OnTakeDamageAlive, Hook_OnTakeAliveDamage);
            }
        }
        PrintToChatAll("[FFexM] Friendly-Fire is now disabled.");
    }
}

public Action Hook_OnTakeAliveDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
    if(!attacker && !IsClientConnected(attacker) && !IsClientInGame(attacker))
    {
        return Plugin_Continue;
    }

    char WeaponCallBack[32];
    GetEdictClassname(inflictor, WeaponCallBack, sizeof(WeaponCallBack));

    if ((strlen(WeaponCallBack) <= 0) || (attacker == victim) || (GetClientTeam(victim) != GetClientTeam(attacker)) )
    {
        return Plugin_Continue;
    }

    if (StrEqual(WeaponCallBack, "inferno", false))
    {
        return Plugin_Stop;
    }

    return Plugin_Continue;
}
