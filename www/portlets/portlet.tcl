
if {![info exists package_id] && ![info exists plugin_name]} {

    ad_page_contract {
	Returns the value of a portlet for the XoWiki.
	@author Frank Bergmann (frank.bergmann@project-open.com)
	@creation-date 06/05/2013
	@cvs-id $Id$
    } {
	{plugin_id:integer ""}
	{plugin_name ""}
	{package_key ""}
	{parameter_list ""}
    }
}

# -------------------------------------------------------------
# Defaults & Parameters
# -------------------------------------------------------------


if {[info exists portlet]} { set plugin_name $portlet }
if {[info exists portlet_name]} { set plugin_name $portlet_name }

if {![info exists plugin_id]} { set plugin_id "" }
if {![info exists package_key]} { set package_key "" }
if {![info exists plugin_name]} { set plugin_name "" }
if {![info exists return_url]} { set return_url [im_url_with_query] }

# Extract the name of the page
set url [ns_conn url]
set url_pieces [split $url "/"]
set last_url_piece [lindex $url_pieces end]
set user_id [ad_get_user_id]

# Convert the name of the page into project_id, user_id or ticket_id
if {![info exists project_id]} { set project_id [db_string pid "select project_id from im_projects where project_nr = :last_url_piece" -default ""] }
if {"" == $project_id} { set project_id  [db_string pid "select max(project_id) from im_projects where parent_id is null" -default ""] }


# Convert the name of the page into company_id, user_id or ticket_id
if {![info exists company_id]} { set company_id [db_string pid "select company_id from im_companies where company_path = :last_url_piece" -default ""] }
if {"" == $company_id} { set company_id  [db_string pid "select max(company_id) from im_companies" -default ""] }


# Convert the name of the page into conf_item_id, user_id or ticket_id
if {![info exists conf_item_id]} { set conf_item_id [db_string pid "select conf_item_id from im_conf_items where conf_item_nr = :last_url_piece" -default ""] }
if {"" == $conf_item_id} { set conf_item_id  [db_string pid "select max(conf_item_id) from im_conf_items" -default ""] }



# -------------------------------------------------------------
# Get the plugin_id from available data
# -------------------------------------------------------------

# Find out the portlet component if specified
# by name and package
if {"" == $plugin_id} {
    set plugin_id [db_string portlet "
	select	min(plugin_id)
	from	im_component_plugins
	where	plugin_name = :plugin_name and
		package_name = :package_key
    " -default ""]
}

# Try the same, but without the package key
if {"" == $plugin_id} {
    set plugin_id [db_string portlet "
	select	min(plugin_id)
	from	im_component_plugins
	where	plugin_name = :plugin_name
    " -default ""]
}

if {"" == $plugin_id} {
    set result "<pre>
<b>[lang::message::lookup "" intranet-core.Portlet_not_Found "Portlet Not Found"]</b>:
[lang::message::lookup "" intranet-core.Portlet_not_Specified_msg "Either you did not specify 'plugin_id' or we did not find 'plugin_name' or 'package_key'."]<br>
<pre>
plugin_id=$plugin_id
plugin_name=$plugin_name
package_key=$package_key
parameter_list=$parameter_list
</pre>
"
    doc_return 200 "text/html" $result
    ad_script_abort
}

# -------------------------------------------------------------
# Security
# -------------------------------------------------------------

set current_user_id [ad_get_user_id]
set any_perms_set_p [im_component_any_perms_set_p]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set current_url [im_url_with_query]


# Get everything about the portlet
if {![db_0or1row plugin_info "
	select	cp.*,
		im_object_permission_p(cp.plugin_id, :current_user_id, 'read') as perm
	from	im_component_plugins cp
	where	cp.plugin_id = :plugin_id
"]} {
    ad_return_complaint 1 "Didn't find plugin #$plugin_id"
    ad_script_abort
}

# ad_return_complaint 1 "$current_user_id - $any_perms_set_p - $perm - $plugin_name"

if {$any_perms_set_p > 0 && "f" == $perm} {
    set result ""
    ad_return_template
}

# -------------------------------------------------------------
# Determine the list of variables in the component_tcl and
# make sure they are specified in the HTTP session
# -------------------------------------------------------------

set form_vars [ns_conn form]
array set form_hash [ns_set array $form_vars]

foreach elem $component_tcl {
    if {[regexp {^\$(.*)} $elem match varname]} {
	if {![info exists $varname]} {
	    if {![info exists form_hash($varname)]} { 
		doc_return 200 "text/html" "<pre>Error: You have to specify variable '$varname' in the URL."
		ad_script_abort
	    }
	    set $varname $form_hash($varname)
	}
    }
}


set result ""
if {[catch {
    set result [eval $component_tcl]
} err_msg]} {
    set result "Error evaluating portlet:<pre>$err_msg</pre>"
}
