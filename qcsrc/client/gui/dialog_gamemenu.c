#ifdef INTERFACE
CLASS(NexuizGameMenuDialog) EXTENDS(NexuizRootDialog)
	METHOD(NexuizGameMenuDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	METHOD(NexuizGameMenuDialog, configureDialog, void(entity))
	ATTRIB(NexuizGameMenuDialog, title, string, "Game Menu")
	ATTRIB(NexuizGameMenuDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(NexuizGameMenuDialog, intendedWidth, float, 0.25)
	ATTRIB(NexuizGameMenuDialog, rows, float, 13)
	ATTRIB(NexuizGameMenuDialog, columns, float, 10)
	ATTRIB(NexuizGameMenuDialog, name, string, "GameMenu")
ENDCLASS(NexuizGameMenuDialog)
#endif

#ifdef IMPLEMENTATION

void ShowGameSettings() {
	GUI_Show(GUI_GAMESETTINGS);
}

void ShowVcall() {
	GUI_Show(GUI_VCALL);
}

void ShowQuit() {
	GUI_Show(GUI_QUIT);
}

void configureDialogNexuizGameMenuDialog(entity me) {
	if (teamplay)
		me.rows = me.rows + 1;

	me.rows = me.rows + gamemenu_commands_count;
	configureDialogNexuizDialog(me); //Parent method
}

void fillNexuizGameMenuDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Main menu", '0 0 0', "togglemenu;", COMMANDBUTTON_CLOSE));
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizButton("Game settings", '0 0 0'));
		e.onClick = ShowGameSettings;
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Join", '0 0 0', "cmd join;", COMMANDBUTTON_CLOSE));
	if (teamplay) {
		me.TR(me);
			me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Switch team", '0 0 0', "menu_cmd directmenu TeamSelect;", COMMANDBUTTON_CLOSE));
	}
	float i;
	for (i = 0; i < gamemenu_commands_count; i++) {
		me.TR(me);
			me.TD(me, 1, me.columns, e = makeNexuizCommandButton(gamemenu_items[i], '0 0 0', gamemenu_commands[i], COMMANDBUTTON_CLOSE));
	}
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Spectate", '0 0 0', "cmd spectate;", COMMANDBUTTON_CLOSE));
	if (vote_commands_count) {
		me.TR(me);
			me.TD(me, 1, me.columns, e = makeNexuizButton("Call a vote", '0 0 0'));
			e.onClick = ShowVcall;
	}
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Disconnect", '0 0 0', "disconnect;", COMMANDBUTTON_CLOSE));
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Reconnect", '0 0 0', "disconnect; reconnect;", COMMANDBUTTON_CLOSE));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizButton("Return to game", '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizButton("Quit to desktop", '1 0 0'));
			e.onClick = ShowQuit;
			e.onClickEntity = me;

}
#endif

/* Click. The c-word is here so you can grep for it :-) */
