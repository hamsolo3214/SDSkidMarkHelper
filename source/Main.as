string userFolderRaw = IO::FromUserGameFolder("");
auto modWorkFolderPath = userFolderRaw.SubStr(0, userFolderRaw.Length - 1) + "\\Skins\\Stadium\\ModWork";

auto dirtTarget = "\\DirtMarks.dds";
auto asphaltTarget = "\\CarFxImage\\CarAsphaltMarks.dds";
auto grassTarget = "\\CarFxImage\\CarGrassMarks.dds";

auto badSkids = modWorkFolderPath + "\\CustomSkids\\BadSkids";
auto goodSkids = modWorkFolderPath + "\\CustomSkids\\GoodSkids";
auto defaultSkids = modWorkFolderPath + "\\CustomSkids\\DefaultSkids";
auto warningSkids = modWorkFolderPath + "\\CustomSkids\\WarningSkids";

array<int> noSkidSurfaces = {
	EPlugSurfaceMaterialId::Ice,
	EPlugSurfaceMaterialId::RoadIce,
	EPlugSurfaceMaterialId::Plastic,
	EPlugSurfaceMaterialId::Water,
	EPlugSurfaceMaterialId::Snow
};

void Main() {
	if (IO::FolderExists(modWorkFolderPath + "\\CarFxImage") == false) {
		IO::CreateFolder(modWorkFolderPath + "\\CarFxImage");
	}

	auto app = GetApp();
	string previousSkids = "";

	while (true) {
		yield();

		if (!Setting_Enabled) {
			continue;
		}

		auto vis = VehicleState::ViewingPlayerState();
		if (vis is null) {
			continue;
		}

		auto hasGroundContact = vis.IsGroundContact;
		auto currentGround = vis.FLGroundContactMaterial;
		float sideSpeed = Math::Abs(VehicleState::GetSideSpeed(vis) * 3.6f);
		float frontSpeed = vis.FrontSpeed * 3.6f;

		if (!hasGroundContact || noSkidSurfaces.Find(currentGround) > -1) {
			continue;
		}

		bool isGrassDirt = currentGround == EPlugSurfaceMaterialId::Green || currentGround == EPlugSurfaceMaterialId::Dirt;

		string skidColor = GetSkidsForSpeed(frontSpeed, sideSpeed, isGrassDirt);

		if (skidColor == previousSkids) {
			continue;
		}

		previousSkids = skidColor;

		if (IO::FileExists(modWorkFolderPath + dirtTarget)) {
			int mowed = MoveCurrentSkidsToCustomFolder(goodSkids);
			mowed += MoveCurrentSkidsToCustomFolder(defaultSkids);
			mowed += MoveCurrentSkidsToCustomFolder(badSkids);
			mowed += MoveCurrentSkidsToCustomFolder(warningSkids);

			if (mowed == 0) {
				//previous skids exists, but all skids are in OG folders
				DeleteOldCustomSkids();
			}
		}
		
		MoveCustomSkidsToModWorkFolder(skidColor);
	}
}

string GetSkidsForSpeed(float speed, float sideSpeed, bool isDirtGrass) {
	if (speed < 200 || (speed < 420 && !isDirtGrass) || sideSpeed < 2) {
		return defaultSkids;
	}

	if (isDirtGrass) {
		return GetSkidsForSideSpeed(sideSpeed, 12, 6);
	}
	else
	{
		return GetSkidsForSideSpeed(sideSpeed, 24, 18);
	}
}

string GetSkidsForSideSpeed(float sideSpeed, float upper, float lower) {
	if (upper >= sideSpeed && lower <= sideSpeed) {
		return goodSkids;
	}

	if (upper + 4 >= sideSpeed && lower - 3 <= sideSpeed) {
		return warningSkids;
	}

	if (upper + 8 >= sideSpeed && lower - 6 <= sideSpeed) {
		return badSkids;
	}

	return defaultSkids;
}

void DeleteOldCustomSkids() {
	IO::Delete(modWorkFolderPath + dirtTarget);
	IO::Delete(modWorkFolderPath + asphaltTarget);
	IO::Delete(modWorkFolderPath + grassTarget);
}

void MoveCustomSkidsToModWorkFolder(string skidColor) {
		IO::Move(skidColor + dirtTarget, modWorkFolderPath + dirtTarget);
		IO::Move(skidColor + asphaltTarget, modWorkFolderPath + asphaltTarget);
		IO::Move(skidColor + grassTarget, modWorkFolderPath + grassTarget);
}

int MoveCurrentSkidsToCustomFolder(string skidColor) {
	if (IO::FileExists(skidColor + dirtTarget) == false) {
		IO::Move(modWorkFolderPath + dirtTarget, skidColor + dirtTarget);
		IO::Move(modWorkFolderPath + asphaltTarget, skidColor + asphaltTarget);
		IO::Move(modWorkFolderPath + grassTarget, skidColor + grassTarget);

		return 1;
	}

	return 0;
}