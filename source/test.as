string userFolderRaw = IO::FromUserGameFolder("");
auto modWorkFolderPath = userFolderRaw.SubStr(0, userFolderRaw.Length - 1) + "\\Skins\\Stadium\\ModWork";

auto dirtTarget = "\\DirtMarks.dds";
auto asphaltTarget = "\\CarFxImage\\CarAsphaltMarks.dds";
auto grassTarget = "\\CarFxImage\\CarGrassMarks.dds";

array<int> noSkidSurfaces = {
	EPlugSurfaceMaterialId::Ice,
	EPlugSurfaceMaterialId::RoadIce,
	EPlugSurfaceMaterialId::Plastic,
	EPlugSurfaceMaterialId::Water,
	EPlugSurfaceMaterialId::Snow,
	EPlugSurfaceMaterialId::Green,
	EPlugSurfaceMaterialId::Dirt
};

array<string> skidmarks = {
	modWorkFolderPath + "\\CustomSkids\\Rainbow\\Red",
	modWorkFolderPath + "\\CustomSkids\\Rainbow\\Orange",
	modWorkFolderPath + "\\CustomSkids\\Rainbow\\Yellow",
	modWorkFolderPath + "\\CustomSkids\\Rainbow\\Green",
	modWorkFolderPath + "\\CustomSkids\\Rainbow\\Turqoise",
	modWorkFolderPath + "\\CustomSkids\\Rainbow\\Light Blue",
	modWorkFolderPath + "\\CustomSkids\\Rainbow\\Blue",
	modWorkFolderPath + "\\CustomSkids\\Rainbow\\Purple",
	modWorkFolderPath + "\\CustomSkids\\Rainbow\\Light Purple",
	modWorkFolderPath + "\\CustomSkids\\Rainbow\\Pink",
	modWorkFolderPath + "\\CustomSkids\\Rainbow\\Light Purple",
	modWorkFolderPath + "\\CustomSkids\\Rainbow\\Purple",
	modWorkFolderPath + "\\CustomSkids\\Rainbow\\Blue",
	modWorkFolderPath + "\\CustomSkids\\Rainbow\\Light Blue",
	modWorkFolderPath + "\\CustomSkids\\Rainbow\\Turqoise",
	modWorkFolderPath + "\\CustomSkids\\Rainbow\\Green",
	modWorkFolderPath + "\\CustomSkids\\Rainbow\\Yellow",
	modWorkFolderPath + "\\CustomSkids\\Rainbow\\Orange"
};

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

		for (int i = 0; i < skidmarks.Length; i++) {
			if (previousSkids != "") {
				MoveCurrentSkidToCustomFolder(previousSkids, asphaltTarget);
			}

			previousSkids = skidmarks[i];

			MoveCustomSkidToModWorkFolder(previousSkids, asphaltTarget);
			sleep(20);
		}
	}
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