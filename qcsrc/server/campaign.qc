// campaign cvars:
//   _campaign_index: index of CURRENT map
//   _campaign_name: name of the current campaign
//   g_campaign(name)_index: index of current LAST map (saved)
//   g_campaign_skill: bot skill offset

float campaign_level;
float campaign_won;
string campaign_index_var;
float checkrules_equality;
float g_campaign_skill;

float campaign_bailout(string s)
{
	cvar = cvar_builtin;
	cvar_string = cvar_string_builtin;
	cvar_set = cvar_set_builtin;
	cvar_set("g_campaign", "0");
	g_campaign = 0;
	print("campaign initialization failed: ", s, "\n");
	return 1;
}

string campaign_cvar_list; // string of format ; var value; var value; var value; 
string(string theCvar) campaign_cvar_string {
	float p, q;
	p = strstrofs(campaign_cvar_list, strcat("; ", theCvar, " "), 0);
	if(p < 0)
		return cvar_defstring(theCvar);
	p += strlen(theCvar) + 3;
	q = strstrofs(campaign_cvar_list, ";", p);
	if(q < 0)
		return cvar_defstring(theCvar);
	return substring(campaign_cvar_list, p, q - p);
}

float(string theCvar) campaign_cvar {
	return stof(campaign_cvar_string(theCvar));
}

void(string theCvar, string theValue) campaign_cvar_set {
	if(campaign_cvar_string(theCvar) == theValue)
		return;

	string s;
	s = campaign_cvar_list;
	campaign_cvar_list = strzone(strcat("; ", theCvar, " ", theValue, s));
	strunzone(s);
	//print(campaign_cvar_list, "\n");
}

float(void) campaign_invalid {
	//string thismapname = GetMapname();
	string s = campaign_gametype[0];
	if(MapInfo_CurrentGametype() != MapInfo_Type_FromString(s))
		return campaign_bailout("wrong game type!");

	//wantedmapname = campaign_mapname[0];
	//if(wantedmapname != thismapname)
	//	return campaign_bailout(strcat("wrong map: ", wantedmapname, " != ", thismapname));
	return 0;
}

void(void) campaign_preinit {
	CACHE_CVAR(g_campaign);
	if not(g_campaign)
		return;

	float baseskill;
	string title;
	campaign_level = cvar("_campaign_index");
	campaign_name = strzone(cvar_string("_campaign_name"));
	campaign_index_var = strzone(strcat("g_campaign", campaign_name, "_index"));
	campaign_file_load(campaign_level, 2);
	if (campaign_entries < 1) {
		campaign_bailout("unknown map");
		return;
	}
	CACHE_CVAR(g_campaign_skill);
	baseskill = bound(1, g_campaign_skill + 1, 4);
	float minskill = baseskill * 5 - 4;
	float maxskill = baseskill * 10;
	baseskill = bound(minskill, campaign_botskill[0] * baseskill * 0.5, maxskill);

	cvar_set("sv_public", "0");
	cvar_set("pausable", "1");

	campaign_cvar_list = strzone(strcat("; ", campaign_mutators[0], "; "));

	cvar = campaign_cvar;
	cvar_string = campaign_cvar_string;
	cvar_set = campaign_cvar_set;

	cvar_set("g_campaign", "1");
	cvar_set("g_dm", "0");
	cvar_set("skill", ftos(baseskill));
	cvar_set("bot_number", ftos(campaign_bots[0]));
	MapInfo_SwitchGameType(MapInfo_Type_FromString(campaign_gametype[0]));

	// copy sv_gravity cvar, as the engine needs it too (sorry, this will mess
	// with the menu a little still...)
	cvar_set_builtin("sv_gravity", cvar_string("sv_gravity"));

	if(campaign_invalid())
		return;

	title = campaign_shortdesc[0];
	title = strzone(strcat("Level ", ftos(campaign_level + 1), ": ", title));
	campaign_message = strzone(campaign_longdesc[0]);
	strunzone(title);
}

void(void) campaign_postinit {
	if not(g_campaign)
		return;

	// now some sanity checks
	if (campaign_invalid())
		return;

	cvar_set("fraglimit", ftos(campaign_fraglimit[0]));
	cvar_set("timelimit", "0");
	cvar_set_builtin("fraglimit", ftos(campaign_fraglimit[0]));
	cvar_set_builtin("timelimit", "0");
}

void(string cvarname, float value) campaign_save_cvar {
	float fh;
	float len;
	string contents;
	string l;

	registercvar(cvarname, ftos(value));
	cvar_set_builtin(cvarname, ftos(value));
	// note: cvarname must be remembered

	fh = fopen("campaign.cfg", FILE_READ);
	contents = "";
	if(fh >= 0)
	{
		while((l = fgets(fh)))
		{
			len = tokenize_console(l);
			if(len != 3)
				continue;
			if(argv(0) != "set")
				continue;
			if(argv(1) == cvarname)
				continue;
			contents = strcat(contents, "set ", argv(1), " ", argv(2), "\n");
		}
		fclose(fh);
	}
	contents = strcat(contents, "set ", cvarname,  " ", ftos(value), "\n");
	fh = fopen("campaign.cfg", FILE_WRITE);
	if(fh >= 0)
	{
		fputs(fh, contents);
	}
	else
	{
		error("Cannot write to campaign file");
	}
}

void(void) campaign_preintermission {
	entity head;
	float won;
	float lost;
	local string savevar;

	won = 0;

	head = findchain(classname, "player");
	while(head)
	{
		if(clienttype(head) == CLIENTTYPE_REAL)
		{
			if(head.winning)
				won = won + 1;
			else
				lost = lost + 1;
		}
		head = head.chain;
	}

	if(won == 1 && lost == 0 && checkrules_equality == 0)
	{
		campaign_won = 1;
		bprint("The current level has been WON.\n");
		// sound!
	}
	else
	{
		campaign_won = 0;
		bprint("The current level has been LOST.\n");
		// sound!
	}

	if(campaign_won && !campaign_map_transition)
	{
		if(campaign_entries < 2)
		{
			// I have won
			savevar = strcat("g_campaign", campaign_name, "_won");
			campaign_save_cvar(savevar, 1);
			// advance level (for menu to show it right)
			campaign_save_cvar(campaign_index_var, campaign_level + 1);
		}
		else if(campaign_level == cvar_builtin(campaign_index_var))
		{
			// advance level
			campaign_save_cvar(campaign_index_var, campaign_level + 1);
		}
	}
}

void(void) campaign_postintermission {
	// NOTE: campaign_won is 0 or 1, that is, points to the next level

	if(!campaign_map_transition && campaign_won && campaign_entries < 2)
	{
		// last map won!
		localcmd("togglemenu 1\n");
		campaign_file_unload();
		return;
	}
	cvar_set_builtin("g_campaign_skill", ftos(g_campaign_skill));
	if (campaign_map_transition)
		campaign_setup_cvars_only(0);
	else
		campaign_setup(campaign_won);

	campaign_file_unload();
	strunzone(campaign_message);
	strunzone(campaign_index_var);
	strunzone(campaign_name);
	campaign_name = "";
}
