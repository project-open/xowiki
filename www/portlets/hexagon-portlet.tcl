
if {![info exists scaling_factor]} { set scaling_factor 0.7 }

if {![info exists portlet_width]} { set portlet_width "" }
if {![info exists portlet_height]} { set portlet_height "" }


if {![info exists hexagons]} { 
    set hexagon "<b>Error in hexagon-portlet.tcl:</b><br>You need to specify the variable 'hexagons'"
} else {
    set hexagon [im_hexagon \
		     -scaling_factor $scaling_factor \
		     -portlet_width $portlet_width \
		     -portlet_height $portlet_height \
		     -hexagons $hexagons \
    ]
}


