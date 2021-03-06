// CampaignFileLoad(offset, n)
// - Loads campaign level data (up to n entries starting at offset)
//   into the globals
// - Returns the number of entries successfully read
float campaign_file_load(float offset, float n)
{
	float fh;
	float lineno;
	float entlen;
	float i;
	string l, a;
	string fn;

	if(n > CAMPAIGN_MAX_ENTRIES)
		n = CAMPAIGN_MAX_ENTRIES;

	campaign_offset = offset;
	campaign_entries = 0;
	campaign_title = string_null;

	fn = strcat("maps/campaign", campaign_name, ".txt");
	fh = fopen(fn, FILE_READ);
	if(fh >= 0)
	{
		for(lineno = 0; (l = fgets(fh)); )
		{
			if(strlen(l) == 0)
				continue; // empty line
			if(substring(l, 0, 11) == "//campaign:")
				campaign_title = substring(l, 11, strlen(l) - 11);
			if(substring(l, 0, 2) == "//")
				continue; // comment
			if(substring(l, 0, 12) == "\"//campaign:")
				campaign_title = substring(l, 12, strlen(l) - 13);
			if(substring(l, 0, 3) == "\"//")
				continue; // comment
			if(lineno >= offset)
			{
				entlen = tokenize(l); // using insane tokenizer for CSV

#define CAMPAIGN_GETARG0                  if(i >= entlen)
#define CAMPAIGN_GETARG1 CAMPAIGN_GETARG0     error("syntax error in campaign file: line has not enough fields");
#define CAMPAIGN_GETARG2 CAMPAIGN_GETARG1 a = argv(++i);
#define CAMPAIGN_GETARG3 CAMPAIGN_GETARG2 if(a == ",")
#define CAMPAIGN_GETARG4 CAMPAIGN_GETARG3     a = "";
#define CAMPAIGN_GETARG5 CAMPAIGN_GETARG4 else
#define CAMPAIGN_GETARG  CAMPAIGN_GETARG5     ++i
// What you're seeing here is what people will do when your compiler supports
// C-style macros but no line continuations.

				i = -1; // starts at -1 so I don't need postincrement; that is, i points to BEFORE the current arg!
				CAMPAIGN_GETARG; campaign_gametype[campaign_entries] = strzone(a);
				CAMPAIGN_GETARG; campaign_mapname[campaign_entries] = strzone(a);
				CAMPAIGN_GETARG; campaign_bots[campaign_entries] = stof(a);
				CAMPAIGN_GETARG; campaign_botskill[campaign_entries] = stof(a);
				CAMPAIGN_GETARG; campaign_fraglimit[campaign_entries] = stof(a);
				CAMPAIGN_GETARG; campaign_mutators[campaign_entries] = strzone(a);
				CAMPAIGN_GETARG; campaign_shortdesc[campaign_entries] = strzone(a);
				CAMPAIGN_GETARG; campaign_longdesc[campaign_entries] = strzone(strreplace("\\n", "\n", a));
				campaign_entries = campaign_entries + 1;

				if(campaign_entries >= n)
					break;
			}
			lineno = lineno + 1;
		}
		fclose(fh);
	}

	campaign_title = strzone(campaign_title);

	return campaign_entries;
}

void campaign_file_unload()
{
	float i;
	if(campaign_title)
	{
		strunzone(campaign_title);
		for(i = 0; i < campaign_entries; ++i)
		{
			strunzone(campaign_gametype[i]);
			strunzone(campaign_mapname[i]);
			strunzone(campaign_mutators[i]);
			strunzone(campaign_shortdesc[i]);
			strunzone(campaign_longdesc[i]);
		}
		campaign_entries = 0;
		campaign_title = string_null;
	}
}

void campaign_setup_cvars_only(float n) {
	localcmd("set g_campaign 1\n");
	localcmd("set _campaign_name \""); localcmd(campaign_name); localcmd("\"\n");
	localcmd("set _campaign_index "); localcmd(ftos(campaign_offset + n)); localcmd("\n");
	localcmd(strcat("maxplayers ", ftos(campaign_bots[n] + 1), "\n"));
}

void campaign_setup(float n)
{
	campaign_setup_cvars_only(n);
	localcmd("disconnect\n");
	MapInfo_LoadMap(campaign_mapname[n]);
}
