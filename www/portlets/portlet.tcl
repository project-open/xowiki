
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
set current_user_id $user_id
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set current_url [im_url_with_query]
set any_perms_set_p [im_component_any_perms_set_p]


# -------------------------------------------------------------
# Object, Object Type and Object Security
# -------------------------------------------------------------

# Check if we can identify objects based on the path
if {![info exists project_id]} { set project_id [db_string pid "select project_id from im_projects where project_nr = :last_url_piece" -default ""] }
if {![info exists company_id]} { set company_id [db_string pid "select company_id from im_companies where company_path = :last_url_piece" -default ""] }
if {![info exists conf_item_id]} { set conf_item_id [db_string pid "select conf_item_id from im_conf_items where conf_item_nr = :last_url_piece" -default ""] }

set object_id 0
set object_type ""
set object_type_pretty ""
set object_owner_ids {0}
if {"" != $conf_item_id} {
    set object_id $conf_item_id
    set object_type "im_conf_item"
    set object_type_pretty [lang::message::lookup "" intranet-core.Configuration_Item "Configuration Item"]
    lappend object_owner_ids [db_string object_owners "select conf_item_owner_id from im_conf_items where conf_item_id = :object_id" -default 0]
    im_conf_item_permissions $current_user_id $conf_item_id view_p read_p write_p admin_p
}
if {"" != $project_id} {
    set object_id $project_id
    set object_type "im_project"
    set object_type_pretty [lang::message::lookup "" intranet-core.Project "Project"]
    lappend object_owner_ids [db_string object_owners "select project_lead_id from im_projects where project_id = :object_id" -default 0]
    im_project_permissions $current_user_id $project_id view_p read_p write_p admin_p
}
if {"" != $company_id} {
    set object_id $company_id
    set object_type "im_company"
    set object_type_pretty [lang::message::lookup "" intranet-core.Company "Company"]
    im_company_permissions $current_user_id $company_id view_p read_p write_p admin_p
}

lappend object_owner_ids [db_string object_creator "select creation_user from acs_objects where object_id = :object_id" -default 0]

set object_owner_ul ""
set owner_sql "
	select	*
	from (
		select	acs_object__name(pa.party_id) as user_name,
			pa.email as user_email,
			pa.party_id as user_id
		from	parties pa,
			acs_rels r,
			im_biz_object_members bom
		where	r.rel_id = bom.rel_id and
			r.object_id_one = :object_id and
			r.object_id_two = pa.party_id and
			bom.object_role_id in (1301,1302,1303)
		UNION
		select	acs_object__name(pa.party_id) as user_name,
			pa.email as user_email,
			pa.party_id as user_id
		from	parties pa
		where	pa.party_id in ([join $object_owner_ids ","])
		) t
	where
		t.user_id > 0 and			-- Exclude the anonymous user
		t.user_id in (select member_id from group_distinct_member_map where group_id = [im_employee_group_id])
	order by user_name
"
db_foreach owners $owner_sql {
    append object_owner_ul "<li><a href=\"mailto:$user_email\">$user_name (mailto:$user_email)</a></li>\n"
}

if {!$read_p} {
    set permission_msg [lang::message::lookup "" intranet-wiki.You_are_not_a_member "You are not a member of this %object_type_pretty%"]
    set contact_msg [lang::message::lookup "" intranet-wiki.Please_contact_owner "Please contact one the object owners in order to obtain permissions:"]
    ad_return_complaint 1 "<b>$permission_msg</b>:<br>$contact_msg<br>&nbsp;<ul>$object_owner_ul</ul><br>"
    ad_script_abort
}


# Use the latest created object as defaults
if {"" == $project_id} { set project_id  [db_string pid "select max(project_id) from im_projects where parent_id is null" -default ""] }
if {"" == $company_id} { set company_id  [db_string pid "select max(company_id) from im_companies" -default ""] }
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
    set portlet_not_found_msg [lang::message::lookup "" intranet-core.Portlet_not_Found "Portlet Not Found"]
    set portlet_not_found_blurb [lang::message::lookup "" intranet-core.Portlet_not_Specified_msg "Either you did not specify 'plugin_id' or we did not find 'plugin_name' or 'package_key'."]
    set result "<b>$portlet_not_found_msg</b>:\n$portlet_not_found_blurb<br>"
    append result "<pre>plugin_id=$plugin_id<br>plugin_name=$plugin_name<br>package_key=$package_key<br>parameter_list=$parameter_list</pre>"
    doc_return 200 "text/html" $result
    ad_script_abort
}


# -------------------------------------------------------------
# Portlet Security
# -------------------------------------------------------------

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
