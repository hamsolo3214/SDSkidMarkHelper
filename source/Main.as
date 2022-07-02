string userFolderRaw = IO::FromUserGameFolder("");
auto modWorkFolderPath = userFolderRaw.SubStr(0, userFolderRaw.Length - 1) + "\\Skins\\Stadium\\ModWork";

auto dirtTarget = "\\DirtMarks.dds";
auto asphaltTarget = "\\CarFxImage\\CarAsphaltMarks.dds";
auto grassTarget = "\\CarFxImage\\CarGrassMarks.dds";

string badSkids = modWorkFolderPath + "\\CustomSkids\\" + Setting_BadSkidsFolder;
string goodSkids = modWorkFolderPath + "\\CustomSkids\\" + Setting_GoodSkidsFolder;
string defaultSkids = modWorkFolderPath + "\\CustomSkids\\" + Setting_DefaultSkidsFolder;
string warningSkids = modWorkFolderPath + "\\CustomSkids\\" + Setting_WarningSkidsFolder;

array<int> noSkidSurfaces = {
	EPlugSurfaceMaterialId::Ice,
	EPlugSurfaceMaterialId::RoadIce,
	EPlugSurfaceMaterialId::Plastic,
	EPlugSurfaceMaterialId::Water,
	EPlugSurfaceMaterialId::Snow
};

void OnSettingsChanged() {
	badSkids = modWorkFolderPath + "\\CustomSkids\\" + Setting_BadSkidsFolder;
	goodSkids = modWorkFolderPath + "\\CustomSkids\\" + Setting_GoodSkidsFolder;
	defaultSkids = modWorkFolderPath + "\\CustomSkids\\" + Setting_DefaultSkidsFolder;
	warningSkids = modWorkFolderPath + "\\CustomSkids\\" + Setting_WarningSkidsFolder;
}

void Main() {
	if (IO::FolderExists(modWorkFolderPath) == false) {
		IO::CreateFolder(modWorkFolderPath);
		UI::ShowNotification(Icons::Check + " " + Meta::ExecutingPlugin().Name, "ModWork folder created, Game needs a restart.");
	}
	if (IO::FolderExists(modWorkFolderPath + "\\CarFxImage") == false) {
		IO::CreateFolder(modWorkFolderPath + "\\CarFxImage");
		UI::ShowNotification(Icons::Check + " " + Meta::ExecutingPlugin().Name, "CarFxImage folder created, Game needs a restart.");
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

		bool isDrivingOnGrass = currentGround == EPlugSurfaceMaterialId::Green;
		bool isDrivingOnDirt = currentGround == EPlugSurfaceMaterialId::Dirt;

		string currentSkids = GetSkidsForSpeed(frontSpeed, sideSpeed, isDrivingOnDirt || isDrivingOnGrass);

		if (currentSkids == previousSkids) {
			continue;
		}

		string target = asphaltTarget;
		if (isDrivingOnGrass) {
			target = grassTarget;
		} 
		else if (isDrivingOnDirt) {
			target = dirtTarget;
		}

		if (IO::FileExists(modWorkFolderPath + target)) {
			auto folders = IO::IndexFolder(modWorkFolderPath + "\\CustomSkids", false);

			int mowed = 0;
			for (int i = 0; i < folders.Length; i++) 
			{
				mowed += MoveCurrentSkidToCustomFolder(folders[i], target);
			}

			if (mowed == 0) {
				DeleteCustomSkidFromWorkFolder(target);
			}
		}
		
		previousSkids = currentSkids;
		MoveCustomSkidToModWorkFolder(currentSkids, target);
	}
}

string GetSkidsForSpeed(float speed, float sideSpeed, bool isDirtGrass) {
	if (speed < 200 || (speed < 420 && !isDirtGrass) || sideSpeed < 2) {
		return defaultSkids;
	}

	if (isDirtGrass) {
		return GetSkidsForSideSpeed(sideSpeed, Setting_Upper_DG, Setting_Lower_DG);
	}
	else
	{
		return GetSkidsForSideSpeed(sideSpeed, Setting_Upper, Setting_Lower);
	}
}

string GetSkidsForSideSpeed(float sideSpeed, float upper, float lower) {
	if (upper >= sideSpeed && lower <= sideSpeed) {
		return goodSkids;
	}

	if (upper + Setting_Upper_Leeway >= sideSpeed && 
		lower - Setting_Lower_Leeway <= sideSpeed) {
		return warningSkids;
	}

	if (upper + Setting_Upper_Leeway * 2 >= sideSpeed && 
		lower - Setting_Lower_Leeway * 2 <= sideSpeed) {
		return badSkids;
	}

	return defaultSkids;
}

void DeleteCustomSkidFromWorkFolder(string target) {
	IO::Delete(modWorkFolderPath + target);
}

void MoveCustomSkidToModWorkFolder(string skidsFolderPath, string target) {
		IO::Move(skidsFolderPath + target, modWorkFolderPath + target);
}

int MoveCurrentSkidToCustomFolder(string skidsFolderPath, string target) {
	if (IO::FileExists(skidsFolderPath + target) == false) {
		IO::Move(modWorkFolderPath + target, skidsFolderPath + target);

		return 1;
	}

	return 0;
}