<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta content="text/html; charset=utf-8" http-equiv="Content-Type" />
<title>Page not found</title>

<style>
div.background {
    background: url(/klematis.jpg) repeat;
    /* border: 2px solid black; */
}

div.transbox {
    margin: 30px;
    background-color: #ffffff;
    opacity: 0.8;
    filter: alpha(opacity=80); /* For IE8 and earlier */
    position: absolute;
    left: 0px;
}

.ll {
    font-size: 500%;
    font-family: 'Arial Bold';
    font-weight: 500;
    line-height: 72px;
}

.ls {
    font-size: 130%;
    font-family: 'Arial Bold';
    font-weight: 300;
    line-height: 36px;
}


div.transbox p {
    margin: 5%;
    font-weight: bold;
    color: #000000;
}
</style>


</head>


<body>

<div class="background">
  <div class="transbox">
<table cellpadding="0" cellspacing="0" border="0" width="972px">
<tr>
<td colspan='2'><img src="http://www.project-open.net/img/project-open/logo.default.gif" alt="pologo" /></td>
</tr>
         <tr>
                <td>
                    <p class='ll'>
                    404<br>PAGE<br>NOT FOUND
                    </p>
                    </td>
                <td>
                   <p class='ls'>
		     @error_msg;noquote@<br/><br/>
		     Search www.project-open.com:<br>
                     <gcse:search></gcse:search>
                     
                     or <a href="mailto:info@project-open.com">get in touch with us.</a>  
                     
                   </p>
                </td>
         </tr>
  </table>
  </div>
</div>

<% 
# Patch to monitor 404's
if {[catch {

} err_msg]} {
  ns_log Error "Error tracking xowiki404s: $err_msg"
}
    if { [string first "is not available" [string tolower $error_msg]] != -1 } {
	# This is quite likely a XOWIKI 404 page 

	# Old way to extract the error message
	# set page_name "[string range $error_msg [string first "'" $error_msg] [string last "'" $error_msg]]"
	# set page_name [string trim $page_name ']

	# fraber 161115: New way to extract the page name
	set error_msg [regsub -all {<[/a-zA-Z]+>} $error_msg ""]
	regexp {'([^']+)'} $error_msg match page_name
	if {![info exists page_name]} { set page_name "undefined" }
	# ad_return_complaint 1 "<pre>$page_name<br>[ns_quotehtml $error_msg]</pre>"

	# --------------------------------------------------------------
	# Check if a content item exists with that name replaced with dashes
	# This corresponds to the names before Klaus renamed stuff
	#
	set page_name_dashes "en:[string map {"_" "-"} $page_name]"
	set exists_p [db_string ex "select count(*) from cr_items where name = :page_name_dashes"]
	if {$exists_p} {
	    set foo [db_string sql "SELECT acs_log__error('xowiki404-tcl-redirected', :page_name)" -default 0]
	    ad_returnredirect -message "Page moved" -allow_complete_url "http://www.project-open.net/en/$page_name_dashes"
	    ad_script_abort
	} else {
	    if { "contact" == $page_name } {
	    	set foo [db_string sql "SELECT acs_log__error('xowiki404-js-redirected', :page_name)" -default 0]	       
	    } else {
	        set foo [db_string sql "SELECT acs_log__error('xowiki404-not-found', :page_name)" -default 0]
	    }
	}

	# --------------------------------------------------------------
	# Tell Frank about the wrong installer page
	set header_vars [ns_conn headers]
	set url [ns_conn url]
	set client_ip [ns_set get $header_vars "Client-ip"]
	set referer_url [ns_set get $header_vars "Referer"]
	set peer_ip [ns_conn peeraddr]
	set system_id [im_system_id]
	set subject "XoWiki 404: $page_name"
	set body "$subject
error_msg: $error_msg
url: $url
client_ip: $client_ip
referer_url: $referer_url
peer_ip: $peer_ip
"
	append body "\nHTTP Header Vars:\n"
	foreach var [ad_ns_set_keys $header_vars] {
	    set value [ns_set get $header_vars $var]
	    append body "$var: $value\n"
	}
	if {"install" eq [string range $page_name 0 6]} { 	}
	ns_sendmail "frank.bergmann@project-open.com" "xowiki@project-open.com" $subject $body
    }

%>

<!-- Hard coded 404's --> 

<script type="application/javascript">

  function redirect(url) {  
      document.getElementById('xowiki-content').style.display = 'none';
      document.write("<span style='font-size: 130%;'>Page has moved. You will be redirected to the new page in 5 seconds, otherwise please click <a href='" + url + "'>here</a>.</span>"); 
      window.setTimeout(function() {
          window.location.href = url;
      }, 5000);
  } 

  if (window.location.pathname == "/en/contact" ) {
      redirect("http://www.project-open.com/en/company/project-open-contact.html")
  } 

/* 
  // Covered by tcl code above

  function UrlExists(url, cb){
    jQuery.ajax({
        url:      url,
        dataType: 'text',
        type:     'GET',
        complete:  function(xhr){
            if(typeof cb === 'function')
               cb.apply(this, [xhr.status]);
        }
    });
  }

  if (console.log(window.location.pathname.indexOf('_') !== -1) ) {
      console.log('Found underscore')
      var path_name = window.location.pathname;
      UrlExists('http://www.project-open.com' + path_name.replace(/_/g, "-"), function(status){
    	  if(status == 200){
	      console.log('Found page, now redirecting')
	      redirect(path_name.replace(/_/g, "-"))
          }
      });
  }

*/


</script>
    <script type="text/javascript">
      // Google search
      (function() {
        var cx = '016534653354615637429:ixh7ho0hlfe';
        var gcse = document.createElement('script');
        gcse.type = 'text/javascript';
        gcse.async = true;
        gcse.src = (document.location.protocol == 'https:' ? 'https:' : 'http:') +
            '//www.google.com/cse/cse.js?cx=' + cx;
        var s = document.getElementsByTagName('script')[0];
        s.parentNode.insertBefore(gcse, s);
      })();

    </script>
</body>
</html>



