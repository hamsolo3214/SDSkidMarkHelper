string userFolderRaw = IO::FromUserGameFolder("");
auto modWorkFolderPath = userFolderRaw.SubStr(0, userFolderRaw.Length - 1) + "\\Skins\\Stadium\\ModWork";

auto dirtTarget = "\\DirtMarks.dds";
auto asphaltTarget = "\\CarFxImage\\CarAsphaltMarks.dds";
auto grassTarget = "\\CarFxImage\\CarGrassMarks.dds";

auto badSkids = modWorkFolderPath + "\\CustomSkids\\BadSkids";
auto goodSkids = modWorkFolderPath + "\\CustomSkids\\GoodSkids";
auto defaultSkids = modWorkFolderPath + "\\CustomSkids\\DefaultSkids";
auto warningSkids = modWorkFolderPath + "\\CustomSkids\\WarningSkids";

void Main() {
	if (IO::FolderExists(modWorkFolderPath + "\\CarFxImage") == false) {
		IO::CreateFolder(modWorkFolderPath + "\\CarFxImage");
	}

	auto app = GetApp();

	string previousSkids = "";

	while (true) {
		auto vis = VehicleState::ViewingPlayerState();
		if (vis is null) {
			yield();
			continue;
		}

		auto ground = vis.FLGroundContactMaterial;

		if (ground == EPlugSurfaceMaterialId::XXX_Null) {
			yield();
			continue;
		}

		float sideSpeed = Math::Abs(VehicleState::GetSideSpeed(vis) * 3.6f);
		float frontSpeed = vis.FrontSpeed * 3.6f;
		string skidColor = defaultSkids;

		if (ground == EPlugSurfaceMaterialId::Green || ground == EPlugSurfaceMaterialId::Dirt) {
			skidColor = GetSkidsForSpeedGrassDirt(frontSpeed, sideSpeed);
		} else {
			skidColor = GetSkidsForSpeed(frontSpeed, sideSpeed);
		}

		if (skidColor == previousSkids) {
			yield();
			continue;
		}

		previousSkids = skidColor;

		if (IO::FileExists(modWorkFolderPath + dirtTarget)) {
			int mowed = MoveOldSkids(goodSkids);
			mowed += MoveOldSkids(defaultSkids);
			mowed += MoveOldSkids(badSkids);
			mowed += MoveOldSkids(warningSkids);

			if (mowed == 0) {
				//previous skids exists, but all skids are in OG folders
				IO::Delete(modWorkFolderPath + dirtTarget);
				IO::Delete(modWorkFolderPath + asphaltTarget);
				IO::Delete(modWorkFolderPath + grassTarget);
			}
		}
		
		IO::Move(skidColor + dirtTarget, modWorkFolderPath + dirtTarget);
		IO::Move(skidColor + asphaltTarget, modWorkFolderPath + asphaltTarget);
		IO::Move(skidColor + grassTarget, modWorkFolderPath + grassTarget);

		yield();
	}
}

string GetSkidsForSpeedGrassDirt(float speed, float sideSpeed) {
	if (speed < 200 || sideSpeed > 50) {
			return defaultSkids;
	}

	float lower = 50 - (50 * 0.78) - 5;
	float upper = lower + 12;

	return GetSkidsForSideSpeed(sideSpeed, upper, lower);
}

string GetSkidsForSpeed(float speed, float sideSpeed) {
	if (speed < 420 || sideSpeed > 50) {
		return defaultSkids;
	}

	float multiplier = 0.8; 
	
	if (speed < 500) {
		multiplier = 0.5;
	} else if (speed < 600) {
		multiplier = 0.6;
	} else if (speed < 700) {
		multiplier = 0.67;
	} else if (speed < 800) {
		multiplier = 0.72;
	} else if (speed < 900) {
		multiplier = 0.75;
	} else if (speed < 995) {
		multiplier = 0.78;
	}
	
	float lower = 50 - (50 * multiplier) - 5;
	float upper = lower + 12;

	return GetSkidsForSideSpeed(sideSpeed, upper, lower);
}

string GetSkidsForSideSpeed(float sideSpeed, float upper, float lower) {
	if (upper > sideSpeed && lower < sideSpeed) {
		return goodSkids;
	}

	if (upper + 7.5 > sideSpeed && lower - 7.5 < sideSpeed) {
		return warningSkids;
	}

	return badSkids;
}

int MoveOldSkids(string skidColor) {
	if (IO::FileExists(skidColor + dirtTarget) == false) {
		IO::Move(modWorkFolderPath + dirtTarget, skidColor + dirtTarget);
		IO::Move(modWorkFolderPath + asphaltTarget, skidColor + asphaltTarget);
		IO::Move(modWorkFolderPath + grassTarget, skidColor + grassTarget);

		return 1;
	}

	return 0;
}