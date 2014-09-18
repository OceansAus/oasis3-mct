#  This program is under CECILL_B licence. See footer for details.


# create the frame in wich an exclusive selection of model wil be done
# create the menubutton used for selection
proc modelxor_create { args } {

    set mandatory_arguments {path_father address}

    # Initializes the widget
    initWidget
    
    smartpacker_setup_modelframe $win $address
    
    # the  menubutton seclector
    ttk::menubutton $win.mb -menu $win.mb.xor -textvariable widgetInfo($address-variable_title) 
    menu $win.mb.xor -tearoff 0 
    pack $win.mb

    # this frame is where all xor choices will be used
    switchform_create $win.xor
    
    if  {[dTree_attrExists $XMLtree $full_address_XML "groups"]==1} {
            set widgetInfo($address-groups) 1            
    } else {
            set widgetInfo($address-groups) 0
    }    
    
    set widgetInfo($address-full_address_XML_clean) $full_address_XML_clean
    set widgetInfo($address-children) [dTree_getChildren_fast $XMLtree $full_address_XML_clean ]
    
    
    set main_menu_reduced ""
    # find the redondant childs in the menu and gather , if groups are enabled
    if {$widgetInfo($address-groups)} {
        set main_menu ""
        foreach child $widgetInfo($address-children) {
            lappend main_menu [lindex [split $child "_"] 0]
        }
        foreach category  $main_menu {
            set items [llength [lsearch -all $main_menu $category] ]
            if {$items > 1} {
                lappend main_menu_reduced $category
            }
        }
        set main_menu_reduced [lsort -unique $main_menu_reduced]
    }    
    
    set widgetInfo($address-categories) $main_menu_reduced
    
    
    
    # add the groups (if any)
    set widgetInfo($address-catindex-none) 0
    foreach category  $main_menu_reduced {
        menu $win.mb.xor.$category -tearoff 0 
        $win.mb.xor add cascade -menu $win.mb.xor.$category  -label "[string totitle $category]"
        set widgetInfo($address-catindex-$category) 0
        set widgetInfo($address-catchildren-$category) ""
    }
    
    
    
    foreach child $widgetInfo($address-children) {
        set title [dTree_getAttribute_fast $XMLtree "$full_address_XML_clean $child" "title"]
        set child_nodeType [dTree_getAttribute_fast $XMLtree "$full_address_XML_clean $child" "nodeType"]
        switchform_add  $win.xor $child
        gui_addpart -address $address.$child  -path_father $win.xor.$child -class $child_nodeType -style "flat"
        
        
        # add the command either at the root or in the groups
        set category [lindex [split $child "_"] 0]
        if {[lsearch $widgetInfo($address-categories) $category] ==-1 } {
            $win.mb.xor add command -label "$title" -command [subst {modelxor_mb_action $win $address $child }]
            set widgetInfo($address-childindex-$child) $widgetInfo($address-catindex-none)
            set widgetInfo($address-childmenu-$child) $win.mb.xor
            set widgetInfo($address-childcategory-$child) "none"
            lappend widgetInfo($address-catchildren-none) $child
            incr widgetInfo($address-catindex-none) 1
        } else {
            $win.mb.xor.$category add command -label "$title" -command [subst {modelxor_mb_action $win $address $child }]
            set widgetInfo($address-childindex-$child) $widgetInfo($address-catindex-$category)
            set widgetInfo($address-childmenu-$child) $win.mb.xor.$category
            set widgetInfo($address-childcategory-$child) "$category"
            lappend widgetInfo($address-catchildren-$category) $child
            incr widgetInfo($address-catindex-$category) 1
        }
    }
    
    # Finishes the widget
    # append widgetInfo($address-check) [ subst {modelxor_check $win $address}]
    append widgetInfo($address-refreshStatus) [ subst {modelxor_refreshStatus $win $address}]
    
    finishWidget
    
    help_add_desc_docu_to_widget
    
    # initialize the layout by the default 
    modelxor_mb_action $win $address $widgetInfo($address-variable)
    
    
   # clean the widget callBack on dstruction
    bind $win <Destroy> [ subst {widget_destroy $win $address}]    
    
    return $win 
}


proc modelxor_mb_action { win address child } {
    global widgetInfo XMLtree tmpTree 

    # if this model is not available, switch to the previous.
    # set child_address "$address.$widgetInfo($address-variable)"

    # update the value
    if { $widgetInfo($address-variable) != $child} {        
        set widgetInfo($address-variable) $child
        eval $widgetInfo($address-check)
    }
}

proc modelxor_refreshStatus {win address} {
    global widgetInfo XMLtree
    
     if {$widgetInfo($address-variable)!=""} {
        #puts "$widgetInfo($address-variable)  and $widgetInfo($address-children)"
        # check if this child exist , if not move to the first availble
        if {$widgetInfo($address-variable) in $widgetInfo($address-children)} {
                # nothin to do, all okk
        } else {
                warning "found $widgetInfo($address-variable) , which is not one of $widgetInfo($address-children). Please check your setup "
                set widgetInfo($address-variable) [lindex $widgetInfo($address-children) 0]
        }
        
        switchform_raise $win.xor $widgetInfo($address-variable)
        set widgetInfo($address-variable_title) [dTree_getAttribute_fast $XMLtree "$widgetInfo($address-full_address_XML_clean) $widgetInfo($address-variable)" "title"]
     }
     
     
     # update the drop-down list
     foreach child $widgetInfo($address-children) {
         if {$widgetInfo($address.$child-visible)==0} {
             $widgetInfo($address-childmenu-$child) entryconfigure $widgetInfo($address-childindex-$child) -state disabled
         } else {
             $widgetInfo($address-childmenu-$child) entryconfigure $widgetInfo($address-childindex-$child) -state normal
         }
     }
     
     # move to the first visible children if needed 
     set child_address "$address.$widgetInfo($address-variable)"
     
     # must be initialized in case of a change in the XML (new xor)
     if {[info exists widgetInfo($child_address-visible)] == 0} {
        set widgetInfo($child_address-visible) 0
        puts ">>> modelxor_refreshstatus initialisation of visibility"
     }
     
     if {$widgetInfo($child_address-visible)==0} {
         set index 0
         set found 0
         foreach child $widgetInfo($address-catchildren-$widgetInfo($address-childcategory-$child)) {
             if {$widgetInfo($address.$child-visible)==1} {
                 set found 1
                 $widgetInfo($address-childmenu-$child) invoke $index
             }
             if {$found} {
                 break
             }
             incr index
         }
         if {$found == 0} {
             warning "Error in the XML library for the model:\n $address \n existif declarations allowed a dead end. "
         }
     }
     smartpacker_update_visibility $win $address
}





#  Copyright CERFACS 2014
#   
#  antoine.dauptain@cerfacs.fr
#   
#  This software is a computer program whose purpose is to ensure technology
#  transfer between academia and industry.
#   
#  This software is governed by the CeCILL-B license under French law and
#  abiding by the rules of distribution of free software.  You can  use, 
#  modify and/ or redistribute the software under the terms of the CeCILL-B
#  license as circulated by CEA, CNRS and INRIA at the following URL
#  "http://www.cecill.info". 
#   
#  As a counterpart to the access to the source code and  rights to copy,
#  modify and redistribute granted by the license, users are provided only
#  with a limited warranty  and the software's author,  the holder of the
#  economic rights,  and the successive licensors  have only  limited
#  liability. 
#   
#  In this respect, the user's attention is drawn to the risks associated
#  with loading,  using,  modifying and/or developing or reproducing the
#  software by the user in light of its specific status of free software,
#  that may mean  that it is complicated to manipulate,  and  that  also
#  therefore means  that it is reserved for developers  and  experienced
#  professionals having in-depth computer knowledge. Users are therefore
#  encouraged to load and test the software's suitability as regards their
#  requirements in conditions enabling the security of their systems and/or 
#  data to be ensured and,  more generally, to use and operate it in the 
#  same conditions as regards security. 
#   
#  The fact that you are presently reading this means that you have had
#  knowledge of the CeCILL-B license and that you accept its terms.