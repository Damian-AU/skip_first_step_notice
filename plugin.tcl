set plugin_name "skip_first_step_notice"

namespace eval ::plugins::${plugin_name} {
	variable author "Damian"
	variable contact "via Diaspora"
	variable version 1.1
	variable description "monitor for skipping of the profile's first step"

	set ::skipped_first_step_message "---"

	set background_colour #fff
    set foreground_colour #2b6084
    set button_label_colour #fAfBff
    set text_colour #2b6084
    set orange #fe7e00
    set font "notosansuiregular"
    set font_bold "notosansuibold"

	proc main {} {
        if {![info exists ::settings(skipped_first_step_FW_is_current)]} {
            set ::settings(skipped_first_step_FW) 0
            set ::settings(skipped_first_step_profile_settings) {}
            set ::settings(skipped_first_step_FW_is_current) 0
        }

        set ::skipped_first_step_FW 0
        set ::skipped_first_step_profile 0
        set ::step1_registered 0


        proc monitor_for_skip_first_step {} {
            if {[espresso_elapsed_timer] < 2 && [espresso_elapsed_timer] > 0} {
                if {$::de1(current_frame_number) == 0} {
                    set ::step1_registered 1
                    set ::settings(skipped_first_step_FW_is_current) 0
                }
                if {$::de1(current_frame_number) != 0} {
                    if {$::step1_registered != 1} {
                        set ::skipped_first_step_FW 1
                        if {$::settings(skipped_first_step_FW_is_current) == 0} {
                            incr ::settings(skipped_first_step_FW)
                        }
                        set ::settings(skipped_first_step_FW_is_current) 1
                        popup [translate "Skip First Step error detected"]
                    } else {
                        set ::skipped_first_step_profile 1
                        set ::settings(skipped_first_step_profile_settings) $::settings(profile_title)
                        popup [translate "Check Profile first step"]
                    }
                }
            }
        }
        proc reset_variables { args } {
            ### page_show may not be needed, just to be sure
            after 2500 {
                if {$::skipped_first_step_FW == 1} {
                    page_show skipped_step_FW
                }
                if {$::skipped_first_step_profile == 1} {
                    page_show skipped_step_profile
                }
                set ::skipped_first_step_FW 0
                set ::skipped_first_step_profile 0
                set ::step1_registered 0
            }
        }

        ::register_state_change_handler Espresso Idle ::plugins::skip_first_step_notice::reset_variables

        rename ::gui::update::append_live_data_to_espresso_chart ::gui::update::append_live_data_to_espresso_chart_orig
        proc ::gui::update::append_live_data_to_espresso_chart {event_dict args} {
            if { ! [::de1::state::is_flow_state \
                    [dict get $event_dict this_state] \
                    [dict get $event_dict this_substate]] } { return }
            ::gui::update::append_live_data_to_espresso_chart_orig $event_dict {*}$args
            ::plugins::skip_first_step_notice::monitor_for_skip_first_step
        }

        proc settings_page_data {} {
            if {$::settings(skipped_first_step_FW_is_current) == 0} {
                set current [translate "not current"]
            } else {
                set current [translate "current"]
            }
            set l "SFS = "
            set s "  "
            return $l$::settings(skipped_first_step_FW)$s$current
        }
    dui add variable "settings_3" 1220 662 -font Helv_7 -fill "#7f879a" -anchor "ne" -textvariable {[::plugins::skip_first_step_notice::settings_page_data]}



	} ;# main

	dui add dbutton "skipped_step_profile skipped_step_FW" 1180 1240 \
        -bwidth 200 -bheight 120 \
        -shape round -fill $foreground_colour -radius 60\
        -label [translate "OK"] -label_font [dui font get $font_bold 18] -label_fill $button_label_colour -label_pos {0.5 0.5} \
        -command {page_show off}

    dui add variable skipped_step_FW 1280 450 -font [dui font get $font 18] -fill $orange -anchor center -justify center -textvariable {[translate "We detected a FW bug causing the profile to skip the first step"]\r[translate "Please power off the machine at the power outlet or its switch on the back"]\r [translate "wait 60 seconds and then turn the power back on."]\r\r[translate "This rebooting of the machine will fix the issue"]}
    dui add variable skipped_step_profile 1280 450 -font [dui font get $font 18] -fill $orange -anchor center -justify center -textvariable {[translate "We detected the profile's first step to be very short"]\r[translate "please check the profile's first step move on settings"]\r\r[translate "For help, please post in Diaspora with a picture of the graph and profile settings, or attach the history file."]}
}
