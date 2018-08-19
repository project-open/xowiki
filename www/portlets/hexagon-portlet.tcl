
if {![info exists scaling_factor]} { set scaling_factor 0.7 }
if {![info exists hexagons]} { 

    set hexagon "<b>Error in hexagon-portlet.tcl:</b><br>You need to specify the variable 'hexagons'"

    set hexagon [im_hexagon -scaling_factor $scaling_factor -hexagons { 
	{"Collabo-<br>ration" "https://www.project-open.net/en/module-collaboration-knowledge" 1 0 "" "Team collaboration, forums, file-storage, Wiki, chat etc."}
	{"CRM" "https://www.project-open.net/en/module-crm"} 
	{"ITSM" "https://www.project-open.net/en/module-itsm"}
	{"PM" "https://www.project-open.net/en/module-project-management" "" "" "/intranet-sysconfig/images/blue-100.png"}
	{"PPM &amp;<br>Multi-PM" "https://www.project-open.net/en/module-ppm"} 
	{"Agile<br>PM" "https://www.project-open.net/en/project-type-agile"} 
	{"Finance" "https://www.project-open.net/en/module-finance"}
    }]

} else {

    set hexagon [im_hexagon -scaling_factor $scaling_factor -hexagons $hexagons]

}


