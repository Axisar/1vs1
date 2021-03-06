.void(entity e) drawGUI;
.entity frameGUI;
#define draw drawGUI
#define frame frameGUI
#define conwidth CVAR(vid_conwidth)
#define conheight CVAR(vid_conheight)
#include "../client-menu/item.c"
#include "../client-menu/item/container.c"
#include "../client-menu/item/inputcontainer.c"
#include "../client-menu/item/nexposee.c"
#include "../client-menu/item/modalcontroller.c"
#include "../client-menu/item/image.c"
#include "../client-menu/item/label.c"
#include "../client-menu/item/button.c"
#include "../client-menu/item/checkbox.c"
#include "../client-menu/item/radiobutton.c"
#include "../client-menu/item/borderimage.c"
#include "../client-menu/item/slider.c"
#include "../client-menu/item/dialog.c"
#include "../client-menu/item/tab.c"
#include "../client-menu/item/textslider.c"
#include "../client-menu/item/listbox.c"
#include "../client-menu/item/inputbox.c"
#include "../client-menu/nexuiz/dialog.c"
#include "gui/rootdialog.c"
#include "../client-menu/nexuiz/button.c"
#include "../client-menu/nexuiz/commandbutton.c"
#include "../client-menu/nexuiz/bigcommandbutton.c"
#include "../client-menu/nexuiz/dialog_teamselect.c"
#include "../client-menu/nexuiz/slider.c"
#include "../client-menu/nexuiz/textslider.c"
#include "../client-menu/nexuiz/textlabel.c"
#include "../client-menu/nexuiz/listbox.c"
#include "../client-menu/nexuiz/inputbox.c"
#include "../client-menu/nexuiz/dialog_quit.c"
#include "../client-menu/nexuiz/checkbox.c"
#include "gui/voteargslist.c"
#include "gui/votelist.c"
#include "gui/dialog_gamemenu.c"
#include "gui/dialog_gamesettings.c"
#include "gui/dialog_radio.c"
#include "gui/mainwindow.c"
#include "gui/dialog_vcall.c"
#include "../client-menu/nexuiz/dialog_saveload.c"
#include "gui/dialog_hint.c"
#undef draw
#undef frame
#undef conwidth
#undef conheight
