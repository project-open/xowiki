::xo::library doc {
  XoWiki - adp generator procs: remove redundancy in adp files by generating it

  @creation-date 2007-03-13
  @author Gustaf Neumann
  @cvs-id $Id$
}


namespace eval ::xowiki {

  Class create ADP_Generator -parameter {
    {master 1}
    {wikicmds 1}
    {footer 1}
    {recreate 0}
    {extra_header_stuff ""}
  }

  ADP_Generator instproc before_render {obj} {
    # just a hook, might be removed later
  }

  ADP_Generator instproc master_part {} {
    return [subst -novariables -nobackslashes \
                {<master>
                  <property name="doc(title)">@title;literal@</property>
                  <property name="context">@context;literal@</property>
                  <if @item_id@ not nil><property name="displayed_object_id">@item_id;literal@</property></if>
                  <property name="&body">property_body</property>
                  <property name="&doc">property_doc</property>
                  <property name="head">
                  [my extra_header_stuff]@header_stuff;literal@
                  </property>}]\n
  }

  ADP_Generator instproc wikicmds_part {} {
    if {![my wikicmds]} {return ""}
    return {<div id='wikicmds'>
      <if @view_link@ not nil><a href="@view_link@" accesskey='v' title='#xowiki.view_title#'>#xowiki.view#</a> &middot; </if>
      <if @edit_link@ not nil><a href="@edit_link@" accesskey='e' title='#xowiki.edit_title#'>#xowiki.edit#</a> &middot; </if>
      <if @rev_link@ not nil><a href="@rev_link@" accesskey='r' title='#xowiki.revisions_title#'>#xotcl-core.revisions#</a> &middot; </if>
      <if @new_link@ not nil><a href="@new_link@" accesskey='n' title='#xowiki.new_title#'>#xowiki.new_page#</a> &middot; </if>
      <if @delete_link@ not nil><a href="@delete_link@" accesskey='d' title='#xowiki.delete_title#'>#xowiki.delete#</a> &middot; </if>
      <if @admin_link@ not nil><a href="@admin_link@" accesskey='a' title='#xowiki.admin_title#'>#xowiki.admin#</a> &middot; </if>
      <if @notification_subscribe_link@ not nil><a href='/notifications/manage' title='#xowiki.notifications_title#'>#xowiki.notifications#</a>
      <a href="@notification_subscribe_link@" class="notification-image-button">&nbsp;</a> &middot; </if>
      <a href='#' onclick='document.getElementById("do_search").style.display="inline";document.getElementById("do_search_q").focus(); return false;'  title='#xowiki.search_title#'>#xowiki.search#</a> &middot;
      <if @index_link@ not nil><a href="@index_link@" accesskey='i' title='#xowiki.index_title#'>#xowiki.index#</a></if>
      <div id='do_search' style='display: none'>
      <form action='/search/search'><div><label for='do_search_q'>#xowiki.search#</label><input id='do_search_q' name='q' type='text'><input type="hidden" name="search_package_id" value="@package_id@" ></div></form>
      </div>
      </div>}
  }

  ADP_Generator instproc footer_part {} {
    if {![my footer]} {return ""}
    return "@footer;noquote@"
  }

  ADP_Generator instproc content_part {} {
    return "@top_includelets;noquote@\n\
     <if @page_context@ not nil><h1>@title@ (@page_context@)</h1></if>\n\
     <else><h1>@title@</h1></else>\n\
     <if @folderhtml@ not nil> \n\
       <div class='folders' style=''>@folderhtml;noquote@</div> \n\
       <div class='content-with-folders'>@content;noquote@</div> \n\
     </if>
    <else>@content;noquote@</else>"
  }

  ADP_Generator instproc generate {} {
    my instvar master wikicmds footer
    set _ "<!-- Generated by [self class] on [clock format [clock seconds]] -->\n"

    # if we include the master, we include the primitive js function
    if {$master} {
      append _ [my master_part]
    }

    append _ \
        {<!-- The following DIV is needed for overlib to function! -->
          <div id="overDiv" style="position:absolute; visibility:hidden; z-index:1000;"></div>    
          <div class='xowiki-content'>} \n

    append _ [my wikicmds_part] \n
    append _ [my content_part] \n
    append _ [my footer_part] \n
    append _ "</div> <!-- class='xowiki-content' -->\n"
  }

  ADP_Generator instproc init {} {
    set name [namespace tail [self]]
    set filename [file dirname [info script]]/../www/$name.adp
    # generate the adp file, if it does not exist
    if {[catch {set f [open $filename w]} errorMsg]} {
      my log "Warning: cannot overwrite ADP $filename, ignoring possible changes"
    } else {
      ::puts -nonewline $f [my generate]
      close $f
      my log "Notice: create ADP $filename"
    }
  }
  ####################################################################################
  # Definition of Templates
  ####################################################################################
  #
  # view-plain
  #
  ADP_Generator create view-plain -master 0 -wikicmds 0 -footer 0

  ####################################################################################
  #
  # view-links
  #
  ADP_Generator create view-links -master 0 -footer 0

  #####################################################################################
  #
  # view-default
  #
  ADP_Generator create view-default -master 1 -footer 1

  ####################################################################################
  #
  # oacs-view
  #
  ADP_Generator create oacs-view -master 1 -footer 1 \
      -extra_header_stuff {
        <link rel='stylesheet' href='/resources/xowiki/cattree.css' media='all' >
        <script language='javascript' src='/resources/acs-templating/mktree.js' type='text/javascript'></script>
      } \
      -proc content_part {} {
        set open_page {-open_page [list @name@]}
        return [subst -novariables -nobackslashes \
                    {<div style="float:left; width: 25%; font-size: 85%;
     background: url(/resources/xowiki/bw-shadow.png) no-repeat bottom right;
     margin-left: 6px; margin-top: 6px; padding: 0px;            
">
                      <div style="position:relative; right:6px; bottom:6px;  border: 1px solid #a9a9a9; padding: 5px 5px; background: #f8f8f8;">
                      <include src="/packages/xowiki/www/portlets/include" &__including_page=page
                      portlet="categories [set open_page] -decoration plain">
                      </div></div>
                      <div style="float:right; width: 70%;">
                      [next]
                      </div>
                    }]
      }

  ####################################################################################
  #
  # oacs-view2
  #
  # similar to oacs view (categories left), but having as well a right bar
  #
  ADP_Generator create oacs-view2 -master 1 -footer 1 \
      -extra_header_stuff {
        <link rel='stylesheet' href='/resources/xowiki/cattree.css' media='all' >
        <link rel='stylesheet' href='/resources/calendar/calendar.css' media='all' >
        <script language='javascript' src='/resources/acs-templating/mktree.js' type='text/javascript'></script>
      } \
      -proc before_render {page} {
        ::xo::cc set_parameter weblog_page weblog-portlet
      } \
      -proc content_part {} {
        set open_page {-open_page [list @name@]}
        return [subst -novariables -nobackslashes \
                    {<div style="float:left; width: 25%; font-size: 85%;
     background: url(/resources/xowiki/bw-shadow.png) no-repeat bottom right;
     margin-left: 6px; margin-top: 6px; padding: 0px;
">
                      <div style="position:relative; right:6px; bottom:6px;  border: 1px solid #a9a9a9; padding: 5px 5px; background: #f8f8f8">
                      <include src="/packages/xowiki/www/portlets/include" &__including_page=page
                      portlet="categories [set open_page] -decoration plain">
                      </div></div>
                      <div style="float:right; width: 70%;">
                      <style type='text/css'>
                      table.mini-calendar {width: 200px ! important;}
                      #sidebar {min-width: 220px ! important; top: 0px; overflow: visible;}
                      </style>
                      <div style='float: left; width: 62%'>
                      [next]
                      </div>  <!-- float left -->
                      <div id='sidebar' class='column'>
                      <div style="background: url(/resources/xowiki/bw-shadow.png) no-repeat bottom right;
     margin-left: 6px; margin-top: 6px; padding: 0px;
">
                      <div style="position:relative; right:6px; bottom:6px;  border: 1px solid #a9a9a9; padding: 5px 5px; background: #f8f8f8">
                      <include src="/packages/xowiki/www/portlets/weblog-mini-calendar" &__including_page=page
                      summary="0" noparens="0">
                      <include src="/packages/xowiki/www/portlets/include" &__including_page=page
                      portlet="tags -decoration plain">
                      <include src="/packages/xowiki/www/portlets/include" &__including_page=page
                      portlet="tags -popular 1 -limit 30 -decoration plain">
                      <hr>
                      <include src="/packages/xowiki/www/portlets/include" &__including_page=page
                      portlet="presence -interval {30 minutes} -decoration plain">
                      <hr>
                      <a href="contributors" title="Show People contributing to this XoWiki Instance">Contributors</a>
                      </div>
                      </div>
                      </div> <!-- sidebar -->

                      </div> <!-- right 70% -->
                    }]
      }

  ####################################################################################
  #
  # oacs-view3
  #
  # similar to oacs view2 (categories left), but everything left
  #
  ADP_Generator create oacs-view3 -master 1 -footer 1 \
      -extra_header_stuff {
        <style type='text/css'>
        table.mini-calendar {width: 227px ! important;font-size: 80%;}
        div.tags h3 {font-size: 80%;}
        div.tags blockquote {font-size: 80%; margin-left: 20px; margin-right: 20px;}
        </style>
        <link rel='stylesheet' href='/resources/xowiki/cattree.css' media='all' >
        <link rel='stylesheet' href='/resources/calendar/calendar.css' media='all' >
        <script language='javascript' src='/resources/acs-templating/mktree.js' type='text/javascript'></script>
      } \
      -proc before_render {page} {
        ::xo::cc set_parameter weblog_page weblog-portlet
      } \
      -proc content_part {} {
        set open_page {-open_page [list @name@]}
        return [subst -novariables -nobackslashes {\

          <div style="width: 100%"> <!-- contentwrap -->

          <div style="float:left; width: 245px; font-size: 85%;">
          <div style="background: url(/resources/xowiki/bw-shadow.png) no-repeat bottom right;
     margin-left: 6px; margin-top: 6px; padding: 0px;
">
          <div style="position:relative; right:6px; bottom:6px;  border: 1px solid #a9a9a9; padding: 5px 5px; background: #f8f8f8">
          <include src="/packages/xowiki/www/portlets/weblog-mini-calendar" &__including_page=page
          summary="0" noparens="0">
          <include src="/packages/xowiki/www/portlets/include" &__including_page=page
          portlet="tags -decoration plain">
          <include src="/packages/xowiki/www/portlets/include" &__including_page=page
          portlet="tags -popular 1 -limit 30 -decoration plain">
          <hr>
          <include src="/packages/xowiki/www/portlets/include" &__including_page=page
          portlet="presence -interval {30 minutes} -decoration plain">
          <hr>
          <a href="contributors" title="Show People contributing to this XoWiki Instance">Contributors</a>
          </div>
          </div> <!-- background -->

          <div style="background: url(/resources/xowiki/bw-shadow.png) no-repeat bottom right;
     margin-left: 6px; margin-top: 6px; padding: 0px;
">
          <div style="position:relative; right:6px; bottom:6px;  border: 1px solid #a9a9a9; padding: 5px 5px; background: #f8f8f8">
          <include src="/packages/xowiki/www/portlets/include" &__including_page=page
          portlet="categories [set open_page] -decoration plain">
          </div></div>  <!-- background -->
          </div>

          <div style="margin-left: 260px;"> <!-- content -->
          [next]
          </div> <!-- content -->
          </div> <!-- contentwrap -->

        }]
      }

  ####################################################################################
  #
  # view-book
  #
  # wiki cmds in rhs
  #
  ADP_Generator create view-book -master 1 -footer 1  -wikicmds 0 \
      -extra_header_stuff {
      } \
      -proc before_render {page} {
        #::xo::cc set_parameter weblog_page weblog-portlet
      } \
      -proc content_part {} {
        return [subst -novariables -nobackslashes \
                    {<div style="float:left; width: 25%; font-size: .8em;
     background: url(/resources/xowiki/bw-shadow.png) no-repeat bottom right;
     margin-left: 6px; margin-top: 6px; padding: 0px;
">
                      <div style="position:relative; right:6px; bottom:6px; border: 1px solid #a9a9a9; padding: 5px 5px; background: #f8f8f8">
                      @toc;noquote@
                      </div></div>
                      <div style="float:right; width: 70%;">
                      <if @book_prev_link@ not nil or @book_relpos@ not nil or @book_next_link@ not nil>
                      <div class="book-navigation" style="background: #fff; border: 1px dotted #000; padding-top:3px; margin-bottom:0.5em;">
                      <table width='100%'
                      summary='This table provides a progress bar and buttons for next and previous pages'>
                      <colgroup><col width='20'><col><col width='20'>
                      </colgroup>
                      <tr>
                      <td>
                      <if @book_prev_link@ not nil>
                      <a href="@book_prev_link@" accesskey='p' ID="bookNavPrev.a" onclick='return TocTree.getPage("@book_prev_link@");'>
                      <img alt='Previous' src='/resources/xowiki/previous.png' width='15' ID="bookNavPrev.img"></a>
                      </if>
                      <else>
                      <a href="" accesskey='p' ID="bookNavPrev.a" onclick="">
                      <img alt='No Previous' src='/resources/xowiki/previous-end.png' width='15' ID="bookNavPrev.img"></a>
                      </else>
                      </td>

                      <td>
                      <if @book_relpos@ not nil>
                      <table width='100%'>
                      <colgroup><col></colgroup>
                      <tr><td style='font-size: 75%'><div style='width: @book_relpos@;' ID='bookNavBar'></div></td></tr>
                      <tr><td style='font-size: 75%; text-align:center;'><span ID='bookNavRelPosText'>@book_relpos@</span></td></tr>
                      </table>
                      </if>
                      </td>

                      <td ID="bookNavNext">
                      <if @book_next_link@ not nil>
                      <a href="@book_next_link@" accesskey='n' ID="bookNavNext.a" onclick='return TocTree.getPage("@book_next_link@");'>
                      <img alt='Next' src='/resources/xowiki/next.png' width='15' ID="bookNavNext.img"></a>
                      </if>
                      <else>
                      <a href="" accesskey='n' ID="bookNavNext.a" onclick="">
                      <img alt='No Next' src='/resources/xowiki/next-end.png' width='15' ID="bookNavNext.img"></a>
                      </else>
                      </td>
                      </tr>
                      </table>
                      </div>
                      </if>

                      <div id='book-page'>
                      <include src="view-page" &="package_id"
                      &="references" &="name" &="title" &="item_id" &="page" &="context" &="header_stuff" &="return_url"
                      &="content" &="references" &="lang_links" &="package_id"
                      &="rev_link" &="edit_link" &="delete_link" &="new_link" &="admin_link" &="index_link"
                      &="tags" &="no_tags" &="tags_with_links" &="save_tag_link" &="popular_tags_link"
                      &="per_object_categories_with_links"
                      &="digg_link" &="delicious_link" &="my_yahoo_link"
                      &="gc_link" &="gc_comments" &="notification_subscribe_link" &="notification_image"
                      &="top_includelets" &="folderhtml" &="page">
                      </div>
                      </div>
                    }]}

  ####################################################################################
  #
  # view-book-no-ajax
  #
  # adp identical to view-book.
  #
  ADP_Generator create view-book-no-ajax -master 1 -footer 1 -wikicmds 0 \
      -extra_header_stuff {
      } \
      -proc before_render {page} {
        #::xo::cc set_parameter weblog_page weblog-portlet
      } \
      -proc content_part {} {
        return [view-book content_part]
      }

}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 2
#    indent-tabs-mode: nil
# End:
