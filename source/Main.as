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

	return GetSkidsForSideSpeed(sideSpeed, 14, 11);
}

string GetSkidsForSpeed(float speed, float sideSpeed) {
	if (speed < 420 || sideSpeed > 50) {
		return defaultSkids;
	}

	return GetSkidsForSideSpeed(sideSpeed, 22, 19);
}

string GetSkidsForSideSpeed(float sideSpeed, float upper, float lower) {
	if (upper >= sideSpeed && lower <= sideSpeed) {
		return goodSkids;
	}

	if (upper + 5 >= sideSpeed && lower - 5 <= sideSpeed) {
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