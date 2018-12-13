#ifdef INTERFACE
CLASS(NexuizSaveLoadDialog) EXTENDS(NexuizRootDialog)
	METHOD(NexuizSaveLoadDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	METHOD(NexuizSaveLoadDialog, configureDialog, void(entity))
	ATTRIB(NexuizSaveLoadDialog, title, string, "Save/Load")
	ATTRIB(NexuizSaveLoadDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(NexuizSaveLoadDialog, intendedWidth, float, 0.5)
	ATTRIB(NexuizSaveLoadDialog, rows, float, 7)
	ATTRIB(NexuizSaveLoadDialog, columns, float, 6)
	ATTRIB(NexuizSaveLoadDialog, name, string, "Save/Load")
ENDCLASS(NexuizSaveLoadDialog)
#endif

#ifdef IMPLEMENTATION
string slotdescr[10];

float SaveSlotNotEmpty(float n) {
	return fexists(strcat("slot", ftos(n), ".sav"));
}
void configureDialogNexuizSaveLoadDialog(entity me) {
	float i;
	for (i = 0; i < 10; i++) {
		unzone_ifneeded(slotdescr[i]);
		if (SaveSlotNotEmpty(i + 1)) {
			slotdescr[i] = cvar_string_zone_ifneeded(strcat("_slot_description", ftos(i + 1)));
		} else
			slotdescr[i] = zone_ifneeded(strcat("Empty slot", ftos(i + 1)));
	}
	configureDialogNexuizDialog(me); //Parent method
}

.entity saveSlot;

float GetSlotNumber(entity e) {
	float i;
	i = 0;
	for (; e.saveSlot; e = e.saveSlot) {
		i++;
		if (e.saveSlot.forcePressed)
			return i;
	}
	return 0;
}

void LoadGame(entity btn, entity me) {
	float slot = GetSlotNumber(me);
	if (SaveSlotNotEmpty(slot)) {
		localcmd(strcat("\nload slot", ftos(slot), "\n"));
		GUI_Hide();
	}
}

void SaveGame(entity btn, entity me) {
	float slot = GetSlotNumber(me);
	localcmd("\nseta _slot_description");
	localcmd(ftos(slot));
	localcmd(" \"");
	localcmd(strftime(TRUE, "%Y %b %e %H:%M:%S"));
	localcmd(" \"\n");
	localcmd(strcat("\nsave slot", ftos(slot), "\n"));
	GUI_Hide();
}

void SlotSelect(entity btn, entity me) {
	entity e;
	for (e = me.saveSlot; e; e = e.saveSlot) {
		e.forcePressed = 0;
	}
	btn.forcePressed = 1;
}

void fillNexuizSaveLoadDialog(entity me)
{
	entity e;
	float i, j;
	e = me;
	for (i = 0; i < 10; i += 2) {
		me.TR(me);
			for (j = 0; j < 2; j++) {
				me.TD(me, 1, 3, e.saveSlot = makeNexuizButton(slotdescr[i + j], '0 0 0'));
				e = e.saveSlot;
				e.onClick = SlotSelect;
				e.onClickEntity = me;
			}
	}
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeNexuizButton("Load", '0 0 0'));
		e.onClick = LoadGame;
		e.onClickEntity = me;
		me.TD(me, 1, 3, e = makeNexuizButton("Save", '0 0 0'));
		e.onClick = SaveGame;
		e.onClickEntity = me;
}
#endif
