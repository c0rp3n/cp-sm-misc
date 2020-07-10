#if defined _generics_included
#endinput
#endif
#define _generics_included

/**
* This function will check if we have a valid player
**/
stock bool IsClientValid(int client, bool allowconsole=false)
{
    if(client == 0 && allowconsole)
    {
        return true;
    }
    if(client <= 0)
    {
        return false;
    }
    if(client > MaxClients)
    {
        return false;
    }
    if (!IsClientConnected(client))
    {
        return false;
    }
    if(!IsClientInGame(client))
    {
        return false;
    }
    if(IsFakeClient(client))
    {
        return false;
    }
    return true;
}

/**
* This function will check if we have a valid player (alive)
**/
stock bool IsClientAlive(int client) // ingame and not bot and alive
{
    if(!IsClientValid(client))
    {
        return false;
    }

    if(!IsPlayerAlive(client))
    {
        return false;
    }

    if(GetClientTeam(client) == CS_TEAM_SPECTATOR)
    {
        return false;
    }

    if(GetClientTeam(client) == CS_TEAM_NONE)
    {
        return false;
    }

    return true;
}

#define LoopValidClients(%1) for(int %1 = 1; %1 <= MaxClients; ++%1) if(IsClientValid(%1))
#define LoopAliveClients(%1) for(int %1 = 1; %1 <= MaxClients; ++%1) if(IsClientAlive(%1))
#define LoopDeadClients(%1)  for(int %1 = 1; %1 <= MaxClients; ++%1) if(IsClientValid(%1) && !IsPlayerAlive(%1))
#define LoopClients(%1)      for(int %1 = 1; %1 <= MaxClients; ++%1)

stock void CallTimer(Handle& timer)
{
    if (timer != INVALID_HANDLE)
    {
        TriggerTimer(timer);
        ClearTimer(timer);
    }
}

stock void ClearTimer(Handle& timer)
{
    if (timer != INVALID_HANDLE)
    {
        KillTimer(timer);
        timer = INVALID_HANDLE;
    }
}

stock int GetClientCookieInt(int client, Handle cookie, int defaultValue)
{
    char cookieValue[64];
    GetClientCookie(that, cookie, cookieValue, sizeof(cookieValue));
    if (cookieValue[0] == '\0') return defaultValue;
    return StringToInt(cookieValue);
}

stock void SetClientCookieInt(int client, Handle cookie, int value)
{
    char cookieValue[64];
    IntToString(value, cookieValue, sizeof(cookieValue));
    SetClientCookie(that, cookie, cookieValue);
}

stock void IntToChar4(int value, char[] array,  int index = 0)
{
    array[index] = (value >> 24) & 0xFF;
    array[index + 1] = (value >> 16) & 0xFF;
    array[index + 2] = (value >> 8) & 0xFF;
    array[index + 3] = value & 0xFF;
}

stock int Char4ToInt(const char[] array, int index = 0)
{
    int value = 0;
    value += array[index] << 24;
    value += array[index + 1] << 16;
    value += array[index + 2] << 8;
    value += array[index + 3];

    return value;
}

stock int GetClientOfAccountID(int accountID)
{
    LoopValidClients(i)
    {
        if (accountID == GetSteamAccountID(i))
        {
            return i;
        }
    }

    return -1;
}
