.vector warpzone_oldorigin, warpzone_oldvelocity, warpzone_oldangles;
.float warpzone_teleport_time;
.float warpzone_teleport_finishtime;
.entity warpzone_teleport_zone;
void WarpZone_FirstFrame();

float               trace_allsolid_saved;
float               trace_startsolid_saved;
float               trace_fraction_saved;
vector              trace_endpos_saved;
vector              trace_plane_normal_saved;
float               trace_plane_dist_saved;
entity              trace_ent_saved;
float               trace_dpstartcontents_saved;
float               trace_dphitcontents_saved;
float               trace_dphitq3surfaceflags_saved;
//string              trace_dphittexturename_saved;
vector              v_forward_saved;
vector              v_up_saved;
vector              v_right_saved;

void save_trace_globals(void) {
    trace_allsolid_saved = trace_allsolid;
    trace_startsolid_saved = trace_startsolid;
    trace_fraction_saved = trace_fraction;
    trace_endpos_saved = trace_endpos;
    trace_plane_normal_saved = trace_plane_normal;
    trace_plane_dist_saved = trace_plane_dist;
    trace_ent_saved = trace_ent;
    trace_dpstartcontents_saved = trace_dpstartcontents;
    trace_dphitcontents_saved = trace_dphitcontents;
    trace_dphitq3surfaceflags_saved = trace_dphitq3surfaceflags;
    //trace_dphittexturename_saved = trace_dphittexturename;
    v_forward_saved = v_forward;
    v_up_saved = v_up;
    v_right_saved = v_right;
}

void restore_trace_globals(void) {
    trace_allsolid = trace_allsolid_saved;
    trace_startsolid = trace_startsolid_saved;
    trace_fraction = trace_fraction_saved;
    trace_endpos = trace_endpos_saved;
    trace_plane_normal = trace_plane_normal_saved;
    trace_plane_dist = trace_plane_dist_saved;
    trace_ent = trace_ent_saved;
    trace_dpstartcontents = trace_dpstartcontents_saved;
    trace_dphitcontents = trace_dphitcontents_saved;
    trace_dphitq3surfaceflags = trace_dphitq3surfaceflags_saved;
    //trace_dphittexturename = trace_dphittexturename_saved;
    v_forward = v_forward_saved;
    v_up = v_up_saved;
    v_right = v_right_saved;
}

void WarpZone_PostTeleportPlayer_Callback(entity player, entity teleporter) {
	physics_mark_as_teleported(player);
	antilag_teleported(player);
}

void WarpZone_StoreProjectileData(entity e)
{
	e.warpzone_oldorigin = e.origin;
	e.warpzone_oldvelocity = e.velocity;
	e.warpzone_oldangles = e.angles;
}

void WarpZone_TeleportPlayer(entity teleporter, entity player, vector to, vector to_angles, vector to_velocity)
{
	vector from;

	makevectors (to_angles);

	from = player.origin;
	setorigin (player, to);
	player.oldorigin = to; // for DP's unsticking
	player.angles = to_angles;
	player.v_angle = to_angles;
#ifdef WARPZONE_USE_FIXANGLE
	player.fixangle = TRUE;
#endif
	player.velocity = to_velocity;

	if(player.effects & EF_TELEPORT_BIT)
		player.effects &~= EF_TELEPORT_BIT;
	else
		player.effects |= EF_TELEPORT_BIT;

	if(player.classname == "player")
		player.flags &~= FL_ONGROUND;

	projectile_update_after_teleport(player);
	WarpZone_PostTeleportPlayer_Callback(player, teleporter);
}

float WarpZone_Teleported_Send(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_WARPZONE_TELEPORTED);
	WriteCoord(MSG_ENTITY, self.angles_x);
	WriteCoord(MSG_ENTITY, self.angles_y);
	WriteCoord(MSG_ENTITY, self.angles_z);
	return TRUE;
}

float WarpZone_Teleport(entity wz, entity player, float f0, float f1)
{
	vector o0, a0, v0, o1, a1, v1, o10;

	o0 = player.origin + player.view_ofs;
	v0 = player.velocity;
	a0 = player.angles;

	o10 = o1 = WarpZone_TransformOrigin(wz, o0);
	v1 = WarpZone_TransformVelocity(wz, v0);
	if not(clienttype(player) == CLIENTTYPE_NOTACLIENT)
		a1 = WarpZone_TransformVAngles(wz, player.v_angle);
	else
		a1 = WarpZone_TransformAngles(wz, a0);

	if(f0 != 0 || f1 != 0)
	{
		// retry last move but behind the warpzone!
		// we must first go back as far as we can, then forward again, to not cause double touch events!

		tracebox(o1 - player.view_ofs + v1 * frametime * f1, player.mins, player.maxs, o1 - player.view_ofs + v1 * frametime * f0, MOVE_WORLDONLY, player);
		{
			entity own;
			own = player.owner;
			player.owner = world;
			tracebox(trace_endpos, player.mins, player.maxs, o1 - player.view_ofs + v1 * frametime * f1, MOVE_NORMAL, player); // this should get us through the warpzone
			player.owner = own;
		}
		o1 = trace_endpos + player.view_ofs;

		float d, dv, md;
		md = max(vlen(player.mins), vlen(player.maxs));
		d = WarpZone_TargetPlaneDist(wz, o1);
		dv = WarpZone_TargetPlaneDist(wz, v1);
		if(d < 0)
			o1 = o1 - v1 * (d / dv);
	}

	// put him out of solid
    if(player.movetype != MOVETYPE_NOCLIP) {
        tracebox(o1 - player.view_ofs, player.mins, player.maxs, o1 - player.view_ofs, MOVE_NOMONSTERS, player);
        if(trace_startsolid)
        {
            setorigin(player, o1 - player.view_ofs);
            if(WarpZone_MoveOutOfSolid(player))
            {
                o1 = player.origin + player.view_ofs;
                setorigin(player, o0 - player.view_ofs);
            }
            else
            {
                print("would have to put player in solid, won't do that\n");
                setorigin(player, o0 - player.view_ofs);
                return 0;
            }
        }
    }

	// do the teleport
	WarpZone_RefSys_Add(player, wz);
	WarpZone_TeleportPlayer(wz, player, o1 - player.view_ofs, a1, v1);
	WarpZone_StoreProjectileData(player);
	player.warpzone_teleport_time = time;
	player.warpzone_teleport_finishtime = time;
	player.warpzone_teleport_zone = wz;

	// prevent further teleports back
	float dt = (o1 - o10) * v1 * (1 / (v1 * v1));
	if(dt < frametime)
		player.warpzone_teleport_finishtime += frametime - dt;

#ifndef WARPZONE_USE_FIXANGLE
	if(player.classname == "player")
	{
		// instead of fixangle, send the transform to the client for smoother operation
		player.fixangle = FALSE;

		entity ts = spawn();
		setmodel(ts, "null");
		ts.SendEntity = WarpZone_Teleported_Send;
		ts.SendFlags = 0xFFFFFF;
		ts.think = stdproc_remove;
		ts.nextthink = time + 1;
		ts.owner = player;
		ts.enemy = wz;
		ts.effects = EF_NODEPTHTEST;
		ts.classname = "warpzone_teleported";
		ts.angles = wz.warpzone_transform;
        ts.customizeentityforclient = inline float(void) {
            if(other == self.owner)
                return TRUE;

            if(other.enemy == self.owner && other.classname == "spectator")
                return TRUE;

            return FALSE;
        };
	}
#endif

	return 1;
}

float WarpZone_Shadow_CustomizeEntity() {
	if (other == self.owner)
		return FALSE;

	entity o = self.owner;
	if (o.customizeentityforclient) {
		entity e = self;
		self = o;
		float f = self.customizeentityforclient();
		self = e;
		if not(f)
			return FALSE;
	}
	self.alpha = o.alpha;
	self.effects = o.effects;
	return TRUE;
}

.entity wz_shadow;
void WarpZone_Shadow_Think() {
	float remove_needed;
	remove_needed = FALSE;
	if (self.owner.wz_shadow != self) {
		remove_needed = TRUE;
	}
	entity o = self.owner;
	if (WarpZone_Find(o.origin + o.mins, o.origin + o.maxs) != self.enemy) {
		self.owner.wz_shadow = world;
		remove_needed = TRUE;
	}
	if (remove_needed) {
		if (self.takedamage)
			antilag_remove(self);

		remove(self);
		return;
	}
	self.nextthink = time;
	if (self.modelindex != o.modelindex)
		setmodel(self, o.model);

	setsize(self, o.mins, o.maxs);
	self.frame = o.frame;
	self.colormap = o.colormap;
	self.color = o.color;
	self.angles = WarpZone_TransformAngles(self.enemy, o.angles);
	self.skin = o.skin;
	self.solid = o.solid;
	setorigin(self, WarpZone_TransformOrigin(self.enemy, o.origin));
}

void WarpZone_Shadow_EventDamage(entity inflictor, entity attacker, float _damage, float deathtype, vector hitloc, vector force) {
	if (damage_radius_running) //No need proxy splash damage
		return;

	damage(self.owner, inflictor, attacker, _damage, deathtype, WarpZone_UnTransformOrigin(self.enemy, hitloc), WarpZone_UnTransformVelocity(self.enemy, force));
	self.velocity = '0 0 0';
}

void WarpZone_Touch (void)
{
	entity oldself;

	if(other.classname == "trigger_warpzone")
		return;

	if(time <= other.warpzone_teleport_finishtime) // already teleported this frame
		return;

	if(WarpZone_ExactTrigger_Touch())
		return;

	if(other.movetype == MOVETYPE_FOLLOW || other.tag_entity)
		return;

	if(WarpZone_PlaneDist(self, other.origin + other.view_ofs) >= 0) {// wrong side of the trigger_warpzone (don't teleport yet)
		if (other.modelindex)
		{
			entity e = other.wz_shadow;
			if (!e || e.enemy != self) {
				e = other.wz_shadow = spawn();
				e.classname = "wzshadow";
				e.enemy = self;
				e.customizeentityforclient = WarpZone_Shadow_CustomizeEntity;
				e.nextthink = time;
				e.think = WarpZone_Shadow_Think;
				e.owner = other;
				e.solid = other.solid;
				if (other.takedamage) {
					e.takedamage = other.takedamage;
					e.event_damage = WarpZone_Shadow_EventDamage;
				}
				if (antilag_have(e))
					antilag_add(e);
			}
		}
		return;
	}
	// FIXME needs a better check to know what is safe to teleport and what not
	if(other.movetype == MOVETYPE_NONE)
		return;

	float f;
	// number of frames we need to go back:
	//   dist = 16*sqrt(2) qu
	//   dist ~ 24 qu
	//   24 qu = v*t
	//   24 qu = v*frametime*n
	//       n = 24 qu/(v*frametime)
	// for clients go only one frame though, may be too irritating otherwise
	// but max 0.25 sec = 0.25/frametime frames
	//       24/(0.25/frametime)
	//       96*frametime
	float d;
	d = 24 + max(vlen(other.mins), vlen(other.maxs));
	if(clienttype(other) == CLIENTTYPE_NOTACLIENT)
		f = -d / bound(frametime * d * 1, frametime * vlen(other.velocity), d);
	else
		f = -1;

    if(other.classname == "observer") {
        WarpZone_Teleport(self, other, f, 0);
        return;
    }

	if(WarpZone_Teleport(self, other, f, 0))
	{
		string save1, save2;
		activator = other;

		save1 = self.target; self.target = NULL;
		save2 = self.target3; self.target3 = NULL;
		trigger_use_targets();
		if not(self.target) self.target = save1;
		if not(self.target3) self.target3 = save2;

		oldself = self;
		self = self.enemy;
		save1 = self.target; self.target = NULL;
		save2 = self.target2; self.target2 = NULL;
		trigger_use_targets();
		if not(self.target) self.target = save1;
		if not(self.target2) self.target2 = save2;
		self = oldself;
	}
}

float WarpZone_Send(entity to, float sendflags)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_WARPZONE);

	// we need THESE to render the warpzone (and cull properly)...
	WriteCoord(MSG_ENTITY, self.origin_x);
	WriteCoord(MSG_ENTITY, self.origin_y);
	WriteCoord(MSG_ENTITY, self.origin_z);

	WriteShort(MSG_ENTITY, self.modelindex);
	WriteCoord(MSG_ENTITY, self.mins_x);
	WriteCoord(MSG_ENTITY, self.mins_y);
	WriteCoord(MSG_ENTITY, self.mins_z);
	WriteCoord(MSG_ENTITY, self.maxs_x);
	WriteCoord(MSG_ENTITY, self.maxs_y);
	WriteCoord(MSG_ENTITY, self.maxs_z);
	WriteByte(MSG_ENTITY, bound(1, self.scale * 16, 255));

	// we need THESE to calculate the proper transform
	WriteCoord(MSG_ENTITY, self.warpzone_origin_x);
	WriteCoord(MSG_ENTITY, self.warpzone_origin_y);
	WriteCoord(MSG_ENTITY, self.warpzone_origin_z);
	WriteCoord(MSG_ENTITY, self.warpzone_angles_x);
	WriteCoord(MSG_ENTITY, self.warpzone_angles_y);
	WriteCoord(MSG_ENTITY, self.warpzone_angles_z);
	WriteCoord(MSG_ENTITY, self.warpzone_targetorigin_x);
	WriteCoord(MSG_ENTITY, self.warpzone_targetorigin_y);
	WriteCoord(MSG_ENTITY, self.warpzone_targetorigin_z);
	WriteCoord(MSG_ENTITY, self.warpzone_targetangles_x);
	WriteCoord(MSG_ENTITY, self.warpzone_targetangles_y);
	WriteCoord(MSG_ENTITY, self.warpzone_targetangles_z);

	return TRUE;
}

float WarpZone_CheckProjectileImpact()
{
	// if self hit a warpzone, abort
	vector o0, v0, a0;
	float mpd, pd, dpd;
	entity wz;

    save_trace_globals();
	wz = WarpZone_Find(self.origin + self.mins, self.origin + self.maxs);
    restore_trace_globals();

	if(!wz)
		return FALSE;

	o0 = self.origin;
	v0 = self.velocity;
	a0 = self.angles;

	// this approach transports the projectile at its full speed, but does
	// not properly retain the projectile trail (but we can't retain it
	// easily anyway without delaying the projectile by two frames, so who
	// cares)
	WarpZone_TraceBox_ThroughZone(self.warpzone_oldorigin, self.mins, self.maxs, self.warpzone_oldorigin + self.warpzone_oldvelocity * frametime, MOVE_NORMAL, self, wz, NULL); // this will get us through the warpzone
	setorigin(self, trace_endpos);
	self.angles = WarpZone_TransformAngles(WarpZone_trace_transform, self.angles);
	self.velocity = WarpZone_TransformVelocity(WarpZone_trace_transform, self.velocity);
	if (trace_fraction < 1) //We hit something right behind warp
		return FALSE;
	
	// in case we are in our warp zone post-teleport, shift the projectile forward a bit
	mpd = max(vlen(self.mins), vlen(self.maxs));
	pd = WarpZone_TargetPlaneDist(wz, self.origin);
	if(pd < mpd)
	{
		dpd = normalize(self.velocity) * self.warpzone_targetforward;
		setorigin(self, self.origin + normalize(self.velocity) * ((mpd - pd) / dpd));
		if(!WarpZone_MoveOutOfSolid(self))
		{
			setorigin(self, o0);
			self.angles = a0;
			self.velocity = v0;
			return FALSE;
		}
	}
	WarpZone_RefSys_Add(self, wz);
	WarpZone_StoreProjectileData(self);
	self.warpzone_teleport_time = time;

	return TRUE;
}

var float() WarpZone_ProjectileTouchHandle_NextLink;
float() WarpZone_ProjectileTouchHandle {
	if(other.classname == "trigger_warpzone")
		goto return_true;

	if(WarpZone_CheckProjectileImpact())
		goto return_true;

	if(self.warpzone_teleport_time == time) // already got teleported this frame? no collision then please
	{
		setorigin(self, self.warpzone_oldorigin);
		self.velocity = self.warpzone_oldvelocity;
		self.angles = self.warpzone_oldangles;
		goto return_true;
	}
	return WarpZone_ProjectileTouchHandle_NextLink();
:return_true
	projectile_update_after_teleport(self);
	return TRUE;
}

void WarpZone_InitStep_FindTarget()
{
	entity e;

	if(self.killtarget != "")
	{
		self.aiment = find(world, targetname, self.killtarget);
		if(self.aiment == world)
		{
			error("Warp zone with nonexisting killtarget");
			return;
		}
	}

	// this way only one of the two ents needs to target
	if(self.target != "")
	{
		e = find(world, targetname, self.target);
		if(e)
		{
			self.enemy = e;
			self.enemy.enemy = self;
		}
	}
}

void WarpZonePosition_InitStep_FindTarget()
{
	if(self.target == "")
	{
		error("Warp zone position with no target");
		return;
	}
	self.enemy = find(world, targetname, self.target);
	if(self.enemy == world)
	{
		error("Warp zone position with nonexisting target");
		return;
	}
	if(self.enemy.aiment)
	{
		// already is positioned
		error("Warp zone position targeting already oriented warpzone");
		return;
	}
	self.enemy.aiment = self;
}

void WarpZone_InitStep_UpdateTransform()
{
	vector org, ang, norm, point;
	float area;
	vector tri, a, b, c, p, q, n;
	float i_s, i_t, n_t;
	string tex;

	if(!self.enemy || self.enemy.enemy != self)
	{
		error("Invalid warp zone detected. Killed.");
		return;
	}

	org = self.origin;
	if(org == '0 0 0')
		org = 0.5 * (self.mins + self.maxs);

	norm = point = '0 0 0';
	area = 0;
	for(i_s = 0; ; ++i_s)
	{
		tex = getsurfacetexture(self, i_s);
		if not(tex)
			break; // this is beyond the last one
		if(tex == "texture/common/trigger")
			continue;
		n_t = getsurfacenumtriangles(self, i_s);
		for(i_t = 0; i_t < n_t; ++i_t)
		{
			tri = getsurfacetriangle(self, i_s, i_t);
			a = getsurfacepoint(self, i_s, tri_x);
			b = getsurfacepoint(self, i_s, tri_y);
			c = getsurfacepoint(self, i_s, tri_z);
			p = b - a;
			q = c - a;
			n =     '1 0 0' * (q_y * p_z - q_z * p_y)
			+       '0 1 0' * (q_z * p_x - q_x * p_z)
			+       '0 0 1' * (q_x * p_y - q_y * p_x);
			area = area + vlen(n);
			norm = norm + n;
			point = point + vlen(n) * (a + b + c);
		}
	}
	if(area > 0)
	{
		norm = norm * (1 / area);
		point = point * (1 / (3 * area));
		if(vlen(norm) < 0.99)
		{
			print("trigger_warpzone near ", vtos(self.aiment.origin), " is nonplanar. BEWARE.\n");
			area = 0; // no autofixing in this case
		}
		norm = normalize(norm);
	}

	if(self.aiment)
	{
		org = self.aiment.origin;
		ang = self.aiment.angles;
		if(area > 0)
		{
			org = org - ((org - point) * norm) * norm; // project to plane
			makevectors(ang);
			if(norm * v_forward < 0)
			{
				print("Position target of trigger_warpzone near ", vtos(self.aiment.origin), " points into trigger_warpzone. BEWARE.\n");
				norm = -1 * norm;
			}
			ang = vectoangles(norm, v_up); // keep rotation, but turn exactly against plane
			ang_x = -ang_x;
			if(norm * v_forward < 0.99)
				print("trigger_warpzone near ", vtos(self.aiment.origin), " has been turned to match plane orientation (", vtos(self.aiment.angles), " -> ", vtos(ang), "\n");
			if(vlen(org - self.aiment.origin) > 0.5)
				print("trigger_warpzone near ", vtos(self.aiment.origin), " has been moved to match the plane (", vtos(self.aiment.origin), " -> ", vtos(org), ").\n");
		}
	}
	else if(area > 0)
	{
		org = point;
		ang = vectoangles(norm);
		ang_x = -ang_x;
	}
	else
		error("cannot infer origin/angles for this warpzone, please use a killtarget or a trigger_warpzone_position");

	self.warpzone_origin = org;
	self.warpzone_angles = ang;
}
void WarpZone_InitStep_FinalizeTransform()
{
	WarpZone_SetUp(self, self.warpzone_origin, self.warpzone_angles, self.enemy.warpzone_origin, self.enemy.warpzone_angles);
	self.touch = WarpZone_Touch;
	entity w = waypoint_spawn(self.warpzone_origin, self.warpzone_origin, WAYPOINTFLAG_GENERATED | WAYPOINTFLAG_TELEPORT | WAYPOINTFLAG_NORELINK);
	entity dw = waypoint_spawn(self.enemy.warpzone_origin, self.enemy.warpzone_origin, WAYPOINTFLAG_GENERATED);
	w.wp00 = dw;
	w.wp00mincost = 0; // this is just for jump pads
	self.nearestwaypoint = w;
	self.nearestwaypointtimeout = time + 1000000000;
}

entity warpzone_position_first;
entity warpzone_first;
.entity warpzone_next;

void WarpZone_FirstFrame() {
	entity e;
	for(self = warpzone_first; self; self = self.warpzone_next)
		WarpZone_InitStep_FindTarget();
	for(self = warpzone_position_first; self; self = self.warpzone_next)
		WarpZonePosition_InitStep_FindTarget();
	for(self = warpzone_first; self; self = self.warpzone_next)
		WarpZone_InitStep_UpdateTransform();
	for(self = warpzone_first; self; self = self.warpzone_next)
		WarpZone_InitStep_FinalizeTransform();
	self = e;
}

void WarpZone_StartFrame()
{
	entity e;
	for(e = world; (e = nextent(e)); )
		WarpZone_StoreProjectileData(e);
}

void WarpZone_HandleObserver() {
    if(!warpzone_chain_begin)
        return;

    var vf = v_forward, vr = v_right, vu = v_up;
    var wz = WarpZone_Find(self.absmin, self.absmax);

    if(!wz)
        return;

    using(other = self) using(self = wz)
        WarpZone_Touch();

    v_forward = vf;
    v_right = vr;
    v_right = vu;
}

void WarpZone_TraceToss_ThroughZone_real(entity e, entity forent, float toss_frametime, float toss_count, entity zone, WarpZone_trace_callback_t cb)
{
	float g, dt;
	vector vf, vr, vu, v0, o0;
	entity wz;

	vf = v_forward;
	vr = v_right;
	vu = v_up;
	o0 = e.origin;
	v0 = e.velocity;
	WarpZone_trace_warpcount = 0;
	WarpZone_Trace_InitTransform();
	// if starting in warpzone, first transform
	wz = WarpZone_Find(e.origin + e.mins, e.origin + e.maxs);
	if(wz)
	{
		if(zone && wz != zone)
		{
			// we are in ANOTHER warpzone. This is bad. Make a zero length trace and return.

			WarpZone_tracetoss_time = 0;
			trace_endpos = o0;
			goto fail;
		}
		WarpZone_Trace_AddTransform(wz);
		setorigin(e, WarpZone_TransformOrigin(wz, e.origin));
		e.velocity = WarpZone_TransformVelocity(wz, e.velocity);
	}
	WarpZone_MakeAllSolid();
	g = sv_gravity * e.gravity;
	WarpZone_tracetoss_time = 0;
	for(;;)
	{
		tracetoss(e, forent, toss_frametime, toss_count);
		if(cb)
			cb(e.origin, trace_endpos, trace_endpos);
		e.origin = trace_endpos;
		e.velocity_z -= WarpZone_tracetoss_time * g;
		dt = vlen(e.origin - o0) / vlen(e.velocity);
		WarpZone_tracetoss_time += dt;
		if(trace_fraction >= 1)
			break;
		if(trace_ent.classname != "trigger_warpzone")
			break;
		if(trace_ent == wz)
		{
			//print("I transformed into the same zone again, wtf, aborting the trace\n");
			break;
		}
		wz = trace_ent;
		if(zone && wz != zone)
			break;
		WarpZone_Trace_AddTransform(wz);
		// we hit a warpzone... so, let's perform the trace after the warp again
		e.origin = WarpZone_TransformOrigin(wz, e.origin);
		e.velocity = WarpZone_TransformVelocity(wz, e.velocity);
		++WarpZone_trace_warpcount;
	}
	WarpZone_MakeAllOther();
:fail
	WarpZone_tracetoss_velocity = e.velocity;
	v_forward = vf;
	v_right = vr;
	v_up = vu;
	// restore old entity data (caller just uses trace_endpos, WarpZone_tracetoss_velocity and the transform)
	e.velocity = v0;
	e.origin = o0;
}

void WarpZone_TraceToss_real(entity e, entity forent, float toss_frametime, float toss_count)
{
	WarpZone_TraceToss_ThroughZone_real(e, forent, toss_frametime, toss_count, world, NULL);
}

void WarpZone_TraceToss_ThroughZone_stub(entity e, entity forent, float toss_frametime, float toss_count, entity zone, WarpZone_trace_callback_t cb) {
	tracetoss(e, forent, toss_frametime, toss_count);
	if(cb)
		cb(e.origin, trace_endpos, trace_endpos);

	WarpZone_tracetoss_velocity = e.velocity;
	WarpZone_tracetoss_velocity_z -= sv_gravity * (vlen(trace_endpos - self.origin) / vlen(self.velocity));
}

void WarpZone_TraceToss_stub(entity e, entity forent, float toss_frametime, float toss_count) {
	tracetoss(e, forent, toss_frametime, toss_count);
	WarpZone_tracetoss_velocity = e.velocity;
	WarpZone_tracetoss_velocity_z -= sv_gravity * (vlen(trace_endpos - self.origin) / vlen(self.velocity));
}

var void(entity targ, entity attacker, float deathtype) WarpZone_DamageForceModsSet_NextLink;
void WarpZone_DamageForceModsSet(entity targ, entity attacker, float deathtype) {
	if (targ.classname == "wzshadow") {
		GameHook_DamageMod = GameHook_ForceMod = GameHook_MirrorDamageMod = GameHook_MirrorForceMod = 1;
		return;
	}
	WarpZone_DamageForceModsSet_NextLink(targ, attacker, deathtype);
}

void WarpZone_EnableHook() {
	WarpZone_TraceToss = WarpZone_TraceToss_real;
	WarpZone_TraceToss_ThroughZone = WarpZone_TraceToss_ThroughZone_real;
	WarpZone_DamageForceModsSet_NextLink = GameHookChain_DamageForceModsSet;
	GameHookChain_DamageForceModsSet = WarpZone_DamageForceModsSet;
	WarpZone_ProjectileTouchHandle_NextLink = GameHookChain_ProjectileTouchHandle;
	GameHookChain_ProjectileTouchHandle = WarpZone_ProjectileTouchHandle;
}

void WarpZone_InitHook() {
	WarpZone_TraceToss = WarpZone_TraceToss_stub;
	WarpZone_TraceToss_ThroughZone = WarpZone_TraceToss_ThroughZone_stub;
	warpzone_sound_transition = 0;
}

void WarpZone_ShutdownHook() {
}

void WarpZone_MoveOutOfSolid_Expand(entity e, vector by)
{
	float eps = 0.0625;
	tracebox(e.origin, e.mins - '1 1 1' * eps, e.maxs + '1 1 1' * eps, e.origin + by, MOVE_WORLDONLY, e);
	if (trace_startsolid)
		return;
	if (trace_fraction < 1)
	{
		// hit something
		// adjust origin in the other direction...
		setorigin(e,e.origin - by * (1 - trace_fraction));
	}
}

float WarpZone_MoveOutOfSolid(entity e)
{
	vector o, m0, m1;

	o = e.origin;
	traceline(o, o, MOVE_WORLDONLY, e);
	if (trace_startsolid)
		return FALSE;

	tracebox(o, e.mins, e.maxs, o, MOVE_WORLDONLY, e);
	if (!trace_startsolid)
		return TRUE;

	m0 = e.mins;
	m1 = e.maxs;
	e.mins = '0 0 0';
	e.maxs = '0 0 0';
	WarpZone_MoveOutOfSolid_Expand(e, '1 0 0' * m0_x);
	e.mins_x = m0_x;
	WarpZone_MoveOutOfSolid_Expand(e, '1 0 0' * m1_x);
	e.maxs_x = m1_x;
	WarpZone_MoveOutOfSolid_Expand(e, '0 1 0' * m0_y);
	e.mins_y = m0_y;
	WarpZone_MoveOutOfSolid_Expand(e, '0 1 0' * m1_y);
	e.maxs_y = m1_y;
	WarpZone_MoveOutOfSolid_Expand(e, '0 0 1' * m0_z);
	e.mins_z = m0_z;
	WarpZone_MoveOutOfSolid_Expand(e, '0 0 1' * m1_z);
	e.maxs_z = m1_z;
	setorigin(e, e.origin);

	tracebox(e.origin, e.mins, e.maxs, e.origin, MOVE_WORLDONLY, e);
	if (trace_startsolid)
	{
		setorigin(e, o);
		return FALSE;
	}

	return TRUE;
}

float WarpZone_ExactTrigger_Touch()
{
	return !WarpZone_BoxTouchesBrush(other.absmin, other.absmax, self, other);
}

void WarpZone_ExactTrigger_Init()
{
	if (self.movedir == '0 0 0')
	if (self.angles != '0 0 0')
	{
		makevectors (self.angles);
		self.movedir = v_forward;
	}
 	if(self.model != "")
 	{
 		precache_model(self.model);
 		setmodel(self, self.model);
 	}
	setorigin(self, self.origin);
	if(self.scale)
		setsize(self, self.mins * self.scale, self.maxs * self.scale);
	else
		setsize(self, self.mins, self.maxs);
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_TRIGGER;
	self.model = "";
}

void(void) warpzone_spawn {
	// warp zone entities must have:
	// "killtarget" pointing to a target_position with a direction arrow
	//              that points AWAY from the warp zone, and that is inside
	//              the warp zone trigger
	// "target"     pointing to an identical warp zone at another place in
	//              the map, with another killtarget to designate its
	//              orientation

	if(!self.scale)
		self.scale = self.modelscale;
	if(!self.scale)
		self.scale = 1;
	string m;
	m = self.model;
	WarpZone_ExactTrigger_Init();
 	if(m != "")
 	{
 		precache_model(m);
 		setmodel(self, m); // no precision needed
	}
	setorigin(self, self.origin);
	if(self.scale)
		setsize(self, self.mins * self.scale, self.maxs * self.scale);
	else
		setsize(self, self.mins, self.maxs);
	self.SendEntity = WarpZone_Send;
	self.SendFlags = 0xFFFFFF;
	self.effects |= EF_NODEPTHTEST;
	self.warpzone_next = warpzone_first;
	if not(warpzone_first) {
		WarpZone_Enable();
		entity e = spawn();
		e.think = WarpZone_FirstFrame;
		e.nextthink = time;
	}
	warpzone_first = self;
	WarpZone_ChainAdd(self);
}

void(void) warpzone_position_spawn {
	// "target", "angles", "origin"
	self.warpzone_next = warpzone_position_first;
	warpzone_position_first = self;
}
