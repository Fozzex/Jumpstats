#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <fjs-core>
#include <fjs-zones>
#define REQUIRE_PLUGIN

#pragma semicolon 1
#pragma newdecls required

int g_BeamSprite;
int g_BeamColour[4];

public Plugin myInfo =
{
    name = "Fozz Jump Stats - Zones",
	author = "Fozz",
	description = "The zones module of the Fozz Jump Stats plugin collection.",
	version = "1.0",
	url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Stats_CreateZoneFromCollision", Native_CreateZoneFromCollision);
	CreateNative("Stats_CreateZoneFromClient", Native_CreateZoneFromClient);

	RegPluginLibrary("fjs-zones");
	return APLRes_Success;
}

public void OnMapStart()
{
	g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");

	g_BeamColour = { 54, 191, 245, 255 };
}

public int Native_CreateZoneFromCollision(Handle plugin, int numParams)
{
	float position[3];
	GetNativeArray(1, position, 3);

	float blockBounds[4][3];
	if (!FindBlockBounds(position, blockBounds))
		return 0;

	float blockCorners[4][3];
	GetCornersFromBounds(blockBounds, blockCorners);

	for (int i = 0; i < 4; i++)
	{
		blockCorners[i][2] += 1.0;
	}

	int client = GetNativeCell(2);
	RenderZone(blockCorners, client);

	return 1;
}

public int Native_CreateZoneFromClient(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (!Stats_IsClientAccessible(client))
		return 0;

	float position[3], normal[3];
	if (!TraceEyesToBrush(client, position, normal))
		return 0;

	if (!Stats_IsNormalVertical(normal))
		return 0;

	return Stats_CreateZoneFromCollision(position, client);
}

bool FindBlockBounds(const float position[3], float outBounds[4][3])
{
	if (!IsOnGround(position))
		return false;

	float origin[3];
	origin = position;
	origin[2] += 1.0;

	float directions[4][3];
	directions[0][0] = 	1.0;
	directions[1][0] = -1.0;
	directions[2][1] = 	1.0;
	directions[3][1] = -1.0;

	float height = position[2];
	bool success = true;
	for (int i = 0; i < 4; i++)
	{
		float newHeight, step;
		bool found = false;
		while (!found)
		{
			float displacement[3], newOrigin[3];
			displacement = directions[i];
			step += 10;
			if (step > MAX_ZONE_STEPS * 10)
				break;

			ScaleVector(displacement, step);
			AddVectors(origin, displacement, newOrigin);

			float wallCollision[3], tempNormal[3];
			if (TracePointToPoint(origin, newOrigin, wallCollision, tempNormal))
			{
				wallCollision[2] -= 1.0;
				outBounds[i] = wallCollision;
				found = true;
			}
			else
			{
				float orignalHeight = GetHeight(origin, tempNormal);	
				newHeight = GetHeight(newOrigin, tempNormal);
				if (newHeight != orignalHeight)
				{
					float lowPosition[3];
					lowPosition = position;
					lowPosition[2] -= 1.0;

					newOrigin[2] -= 2.0;
					TracePointToPoint(newOrigin, lowPosition, outBounds[i], tempNormal);
					found = true;
				}
			}
		}

		if (!found)
		{
			success = false;
			break;
		}
	}
	return success;
}

bool TraceEyesToBrush(int client, float outPosition[3], float outNormal[3])
{
	float eyePosition[3], eyeAngle[3];
	GetClientEyePosition(client, eyePosition);
	GetClientEyeAngles(client, eyeAngle);

	return TracePointAngle(eyePosition, eyeAngle, outPosition, outNormal);
}

bool TracePoint(const float start[3], const float end[3], float outPosition[3], float outNormal[3], RayType rayType)
{
	Handle rayHandle = TR_TraceRayFilterEx(start,
						end,
						MASK_SHOT,
						rayType,
						TraceClientFilter);

	bool success = false;
	if (TR_DidHit(rayHandle))
	{
		TR_GetEndPosition(outPosition, rayHandle);
		TR_GetPlaneNormal(rayHandle, outNormal);

		success = true;
	}

	CloseHandle(rayHandle);
	return success;
}

bool TracePointAngle(const float position[3], const float angle[3], float outPosition[3], float outNormal[3])
{
	return TracePoint(position, angle, outPosition, outNormal, RayType_Infinite);
}

bool TracePointToPoint(const float start[3], const float end[3], float outPosition[3], float outNormal[3])
{
	return TracePoint(start, end, outPosition, outNormal, RayType_EndPoint);
}

void RenderZone(const float corners[4][3], int client)
{
	for (int i = 0; i < 4; i++)
	{
		int j = (i > 0) ? i - 1 : 3;
		TE_SetupBeamPoints(corners[i], corners[j], g_BeamSprite, 0, 0, 0, 60.0, 2.0, 2.0, 1, 0.0, g_BeamColour, 15); 
		TE_SendToClient(client);
	}
}

void RenderBeam(const float start[3], const float end[3], int client)
{
	TE_SetupBeamPoints(start, end, g_BeamSprite, 0, 0, 0, 60.0, 2.0, 2.0, 1, 0.0, g_BeamColour, 15); 
	TE_SendToClient(client);
}

bool IsOnGround(const float position[3])
{
	float normal[3];
	float height = GetHeight(position, normal);
	if (Stats_IsNormalVertical(normal))
	{
		return !(height < 0.0) && !(height > 1.0);
	}

	return false;
}

float GetHeight(const float position[3], float outNormal[3])
{
	float downAngle[3];
	downAngle = { 90.0, 0.0, 0.0 };

	float resultPosition[3];
	if (TracePointAngle(position, downAngle, resultPosition, outNormal))
	{
		return (position[2] - resultPosition[2]);
	}

	return -1.0;
}

public void GetCornersFromBounds(const float bounds[4][3], float outCorners[4][3])
{
	float xMax, yMax, xMin, yMin;
	xMax = bounds[0][0];
	xMin = bounds[0][0];
	yMax = bounds[0][1];
	yMin = bounds[0][1];

	for(int i = 1; i < 4; i++)
	{
		xMax = FMax(xMax, bounds[i][0]);
		yMax = FMax(yMax, bounds[i][1]);

		xMin = FMin(xMin, bounds[i][0]);
		yMin = FMin(yMin, bounds[i][1]);
	}

	for (int i = 0; i < 4; i++)
		outCorners[i] = bounds[i];

	outCorners[0][0] = xMin;
	outCorners[0][1] = yMax;

	outCorners[1][0] = xMax;
	outCorners[1][1] = yMax;

	outCorners[2][0] = xMax;
	outCorners[2][1] = yMin;

	outCorners[3][0] = xMin;
	outCorners[3][1] = yMin;
}

public bool TraceClientFilter(int entity, int contentsMask, any data)
{
	return !Stats_IsClientValid(entity);
}
