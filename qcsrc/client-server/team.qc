float(float t) team_index {
    switch(t) {
        case COLOR_TEAM1:   return 1; break;
        case COLOR_TEAM2:   return 2; break;
        case COLOR_TEAM3:   return 3; break;
        case COLOR_TEAM4:   return 4; break;
    }
    return 0;
}

string(float teamid) team_color_code {
    if (teamid == COLOR_TEAM1)
        return "^1";
    else if (teamid == COLOR_TEAM2)
        return "^4";
    else if (teamid == COLOR_TEAM3)
        return "^3";
    else if (teamid == COLOR_TEAM4)
        return "^6";
    else
        return "^7";
}

