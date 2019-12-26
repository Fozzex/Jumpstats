#if defined _fjs_core_included
    #endinput
#endif
#define _fjs_core_included

stock bool Stats_IsClientValid(int client)
{
    return (client > 0 && client < MaxClients) && IsClientInGame(client);
}

stock bool Stats_IsClientAccessible(int client)
{
    return Stats_IsClientValid(client) && IsPlayerAlive(client);
}

stock bool Stats_IsNormalVertical(float normal[3])
{
    return normal[2] == 1.0;
}

stock float FMax(float first, float second)
{
    return (first > second) ? first : second;
}

stock float FMin(float first, float second)
{
    return (first > second) ? second : first;
}
