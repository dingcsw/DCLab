set_global_assignment -entity "jfjplayer" -library "lib_jfjplayer" -name IP_TOOL_NAME "Qsys"
set_global_assignment -entity "jfjplayer" -library "lib_jfjplayer" -name IP_TOOL_VERSION "16.0"
set_global_assignment -entity "jfjplayer" -library "lib_jfjplayer" -name IP_TOOL_ENV "Qsys"
set_global_assignment -library "lib_jfjplayer" -name SPD_FILE [file join $::quartus(sip_path) "../jfjplayer.spd"]
set_global_assignment -library "lib_jfjplayer" -name MISC_FILE [file join $::quartus(sip_path) "../../jfjplayer.qsys"]

set_global_assignment -library "lib_jfjplayer" -name MISC_FILE [file join $::quartus(sip_path) "jfjplayer.v"]
