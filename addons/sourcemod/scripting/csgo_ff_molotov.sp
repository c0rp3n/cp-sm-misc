#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <generics>
#include <colorlib>

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
        LoopValidClients(i)
        {
            OnClientPutInServer(i);
        }
    }
}

public void OnClientPutInServer(int client)
{
    if (g_cEnabled.BoolValue)
    {
        SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    }
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (convar.BoolValue)
    {
        LoopValidClients(i)
        {
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
        }
        CPrintToChatAll("[FFexM] Friendly-Fire is now enabled.");
    }
    else
    {
        LoopValidClients(i)
        {
            SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
        }
        CPrintToChatAll("[FFexM] Friendly-Fire is now disabled.");
    }
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
    if(!IsClientValid(attacker) || !IsClientValid(victim))
        return Plugin_Handled;

    char WeaponCallBack[32];
    GetEdictClassname(inflictor, WeaponCallBack, sizeof(WeaponCallBack));

    if ((!IsValidEntity(victim)) || (!IsValidEntity(attacker)))
        return Plugin_Continue;

    if ((strlen(WeaponCallBack) <= 0) || (attacker == victim) || (GetClientTeam(victim) != GetClientTeam(attacker)) )
        return Plugin_Continue;

    if (StrEqual(WeaponCallBack, "inferno", false))
        return Plugin_Continue;

    if (damagetype & DMG_FALL)
        return Plugin_Continue;

    return Plugin_Handled;
}
