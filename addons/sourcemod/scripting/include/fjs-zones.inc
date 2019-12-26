#if defined _fjs_zones_included
    #endinput
#endif
#define _fjs_zones_included

#define MAX_ZONE_STEPS 50

/**
* Creates zone at a point of collison on an upwards facing brush
*
* @param position   Point of collision
* @param client     Client to render zone to
*/
native bool Stats_CreateZoneFromCollision(const float position[3], int client);

/**
* Creates zone on brush client is looking at
*
* @param client     Client to retrieve eye angles from and render zone to
*/
native bool Stats_CreateZoneFromClient(int client);

public SharedPlugin __pl_fjs =
{
    name = "fjs-zones",
    file = "fjs-zones.smx",
#if defined REQUIRE_PLUGIN
    required = 1
#else
    required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_fjs_SetNTVOptional()
{
    MarkNativeAsOptional("Stats_CreateZoneFromCollision");
    MarkNativeAsOptional("Stats_CreateZoneFromClient");
}
#endif
