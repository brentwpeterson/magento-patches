#!/bin/bash
# Patch apllying tool template
# v0.1.2
# (c) Copyright 2013. Magento Inc.
#
# DO NOT CHANGE ANY LINE IN THIS FILE.

# 1. Check required system tools
_check_installed_tools() {
    local missed=""

    until [ -z "$1" ]; do
        type -t $1 >/dev/null 2>/dev/null
        if (( $? != 0 )); then
            missed="$missed $1"
        fi
        shift
    done

    echo $missed
}

REQUIRED_UTILS='sed patch'
MISSED_REQUIRED_TOOLS=`_check_installed_tools $REQUIRED_UTILS`
if (( `echo $MISSED_REQUIRED_TOOLS | wc -w` > 0 ));
then
    echo -e "Error! Some required system tools, that are utilized in this sh script, are not installed:\nTool(s) \"$MISSED_REQUIRED_TOOLS\" is(are) missed, please install it(them)."
    exit 1
fi

# 2. Determine bin path for system tools
CAT_BIN=`which cat`
PATCH_BIN=`which patch`
SED_BIN=`which sed`
PWD_BIN=`which pwd`
BASENAME_BIN=`which basename`

BASE_NAME=`$BASENAME_BIN "$0"`

# 3. Help menu
if [ "$1" = "-?" -o "$1" = "-h" -o "$1" = "--help" ]
then
    $CAT_BIN << EOFH
Usage: sh $BASE_NAME [--help] [-R|--revert] [--list]
Apply embedded patch.

-R, --revert    Revert previously applied embedded patch
--list          Show list of applied patches
--help          Show this help message
EOFH
    exit 0
fi

# 4. Get "revert" flag and "list applied patches" flag
REVERT_FLAG=
SHOW_APPLIED_LIST=0
if [ "$1" = "-R" -o "$1" = "--revert" ]
then
    REVERT_FLAG=-R
fi
if [ "$1" = "--list" ]
then
    SHOW_APPLIED_LIST=1
fi

# 5. File pathes
CURRENT_DIR=`$PWD_BIN`/
APP_ETC_DIR=`echo "$CURRENT_DIR""app/etc/"`
APPLIED_PATCHES_LIST_FILE=`echo "$APP_ETC_DIR""applied.patches.list"`

# 6. Show applied patches list if requested
if [ "$SHOW_APPLIED_LIST" -eq 1 ] ; then
    echo -e "Applied/reverted patches list:"
    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -r "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be readable so applied patches list can be shown."
            exit 1
        else
            $SED_BIN -n "/SUP-\|SUPEE-/p" $APPLIED_PATCHES_LIST_FILE
        fi
    else
        echo "<empty>"
    fi
    exit 0
fi

# 7. Check applied patches track file and its directory
_check_files() {
    if [ ! -e "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must exist for proper tool work."
        exit 1
    fi

    if [ ! -w "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must be writeable for proper tool work."
        exit 1
    fi

    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -w "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be writeable for proper tool work."
            exit 1
        fi
    fi
}

_check_files

# 8. Apply/revert patch
# Note: there is no need to check files permissions for files to be patched.
# "patch" tool will not modify any file if there is not enough permissions for all files to be modified.
# Get start points for additional information and patch data
SKIP_LINES=$((`$SED_BIN -n "/^__PATCHFILE_FOLLOWS__$/=" "$CURRENT_DIR""$BASE_NAME"` + 1))
ADDITIONAL_INFO_LINE=$(($SKIP_LINES - 3))p

_apply_revert_patch() {
    DRY_RUN_FLAG=
    if [ "$1" = "dry-run" ]
    then
        DRY_RUN_FLAG=" --dry-run"
        echo "Checking if patch can be applied/reverted successfully..."
    fi
    PATCH_APPLY_REVERT_RESULT=`$SED_BIN -e '1,/^__PATCHFILE_FOLLOWS__$/d' "$CURRENT_DIR""$BASE_NAME" | $PATCH_BIN $DRY_RUN_FLAG $REVERT_FLAG -p0`
    PATCH_APPLY_REVERT_STATUS=$?
    if [ $PATCH_APPLY_REVERT_STATUS -eq 1 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully.\n\n$PATCH_APPLY_REVERT_RESULT"
        exit 1
    fi
    if [ $PATCH_APPLY_REVERT_STATUS -eq 2 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully."
        exit 2
    fi
}

REVERTED_PATCH_MARK=
if [ -n "$REVERT_FLAG" ]
then
    REVERTED_PATCH_MARK=" | REVERTED"
fi

_apply_revert_patch dry-run
_apply_revert_patch

# 9. Track patch applying result
echo "Patch was applied/reverted successfully."
ADDITIONAL_INFO=`$SED_BIN -n ""$ADDITIONAL_INFO_LINE"" "$CURRENT_DIR""$BASE_NAME"`
APPLIED_REVERTED_ON_DATE=`date -u +"%F %T UTC"`
APPLIED_REVERTED_PATCH_INFO=`echo -n "$APPLIED_REVERTED_ON_DATE"" | ""$ADDITIONAL_INFO""$REVERTED_PATCH_MARK"`
echo -e "$APPLIED_REVERTED_PATCH_INFO\n$PATCH_APPLY_REVERT_RESULT\n\n" >> "$APPLIED_PATCHES_LIST_FILE"

exit 0


SUPEE-4334-v1.11.1.0 | EE_1.11.1.0 | v1 | 40f5a2e4db9ca53dc6a8e62eb0c728fd63b1157e | Wed Sep 10 10:42:31 2014 -0700 | ef80f7bff749c941b4d1736cc2b502888e7540c9

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps.php
index 7426efa..00b6023 100644
--- app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps.php
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps.php
@@ -340,6 +340,10 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
             if ($r->getService() == 'FIRST CLASS' || $r->getService() == 'FIRST CLASS HFP COMMERCIAL') {
                 $package->addChild('FirstClassMailType', 'PARCEL');
             }
+            if ($r->getService() == 'FIRST CLASS COMMERCIAL') {
+                $package->addChild('FirstClassMailType', 'PACKAGE SERVICE');
+            }
+            
             $package->addChild('ZipOrigination', $r->getOrigPostal());
             //only 5 chars available
             $package->addChild('ZipDestination', substr($r->getDestPostal(), 0, 5));
@@ -533,13 +537,15 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                 '0_FCLE' => Mage::helper('usa')->__('First-Class Mail Large Envelope'),
                 '0_FCL'  => Mage::helper('usa')->__('First-Class Mail Letter'),
                 '0_FCP'  => Mage::helper('usa')->__('First-Class Mail Parcel'),
+                '0_FCPC' => Mage::helper('usa')->__('First-Class Mail Postcards'),
                 '1'      => Mage::helper('usa')->__('Priority Mail'),
                 '2'      => Mage::helper('usa')->__('Priority Mail Express Hold For Pickup'),
                 '3'      => Mage::helper('usa')->__('Priority Mail Express'),
                 '4'      => Mage::helper('usa')->__('Standard Post'),
-                '6'      => Mage::helper('usa')->__('Media Mail'),
-                '7'      => Mage::helper('usa')->__('Library Mail'),
+                '6'      => Mage::helper('usa')->__('Media Mail Parcel'),
+                '7'      => Mage::helper('usa')->__('Library Mail Parcel'),
                 '13'     => Mage::helper('usa')->__('Priority Mail Express Flat Rate Envelope'),
+                '15'     => Mage::helper('usa')->__('First-Class Mail Large Postcards'),
                 '16'     => Mage::helper('usa')->__('Priority Mail Flat Rate Envelope'),
                 '17'     => Mage::helper('usa')->__('Priority Mail Medium Flat Rate Box'),
                 '22'     => Mage::helper('usa')->__('Priority Mail Large Flat Rate Box'),
@@ -547,21 +553,42 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                 '25'     => Mage::helper('usa')->__('Priority Mail Express Sunday/Holiday Delivery Flat Rate Envelope'),
                 '27'     => Mage::helper('usa')->__('Priority Mail Express Flat Rate Envelope Hold For Pickup'),
                 '28'     => Mage::helper('usa')->__('Priority Mail Small Flat Rate Box'),
+                '29'     => Mage::helper('usa')->__('Priority Mail Padded Flat Rate Envelope'),
+                '30'     => Mage::helper('usa')->__('Priority Mail Express Legal Flat Rate Envelope'),
+                '31'     => Mage::helper('usa')->__('Priority Mail Express Legal Flat Rate Envelope Hold For Pickup'),
+                '32'     => Mage::helper('usa')->__('Priority Mail Express Sunday/Holiday Delivery Legal Flat Rate Envelope'),
                 '33'     => Mage::helper('usa')->__('Priority Mail Hold For Pickup'),
                 '34'     => Mage::helper('usa')->__('Priority Mail Large Flat Rate Box Hold For Pickup'),
                 '35'     => Mage::helper('usa')->__('Priority Mail Medium Flat Rate Box Hold For Pickup'),
                 '36'     => Mage::helper('usa')->__('Priority Mail Small Flat Rate Box Hold For Pickup'),
                 '37'     => Mage::helper('usa')->__('Priority Mail Flat Rate Envelope Hold For Pickup'),
+                '38'     => Mage::helper('usa')->__('Priority Mail Gift Card Flat Rate Envelope'),
+                '39'     => Mage::helper('usa')->__('Priority Mail Gift Card Flat Rate Envelope Hold For Pickup'),
+                '40'     => Mage::helper('usa')->__('Priority Mail Window Flat Rate Envelope'),
+                '41'     => Mage::helper('usa')->__('Priority Mail Window Flat Rate Envelope Hold For Pickup'),
                 '42'     => Mage::helper('usa')->__('Priority Mail Small Flat Rate Envelope'),
                 '43'     => Mage::helper('usa')->__('Priority Mail Small Flat Rate Envelope Hold For Pickup'),
+                '44'     => Mage::helper('usa')->__('Priority Mail Legal Flat Rate Envelope'),
+                '45'     => Mage::helper('usa')->__('Priority Mail Legal Flat Rate Envelope Hold For Pickup'),
+                '46'     => Mage::helper('usa')->__('Priority Mail Padded Flat Rate Envelope Hold For Pickup'),
+                '47'     => Mage::helper('usa')->__('Priority Mail Regional Rate Box A'),
+                '48'     => Mage::helper('usa')->__('Priority Mail Regional Rate Box A Hold For Pickup'),
+                '49'     => Mage::helper('usa')->__('Priority Mail Regional Rate Box B'),
+                '50'     => Mage::helper('usa')->__('Priority Mail Regional Rate Box B Hold For Pickup'),
                 '53'     => Mage::helper('usa')->__('First-Class Package Service Hold For Pickup'),
                 '55'     => Mage::helper('usa')->__('Priority Mail Express Flat Rate Boxes'),
                 '56'     => Mage::helper('usa')->__('Priority Mail Express Flat Rate Boxes Hold For Pickup'),
                 '57'     => Mage::helper('usa')->__('Priority Mail Express Sunday/Holiday Delivery Flat Rate Boxes'),
+                '58'     => Mage::helper('usa')->__('Priority Mail Regional Rate Box C'),
+                '59'     => Mage::helper('usa')->__('Priority Mail Regional Rate Box C Hold For Pickup'),
                 '61'     => Mage::helper('usa')->__('First-Class Package Service'),
+                '62'     => Mage::helper('usa')->__('Priority Mail Express Padded Flat Rate Envelope'),
+                '63'     => Mage::helper('usa')->__('Priority Mail Express Padded Flat Rate Envelope Hold For Pickup'),
+                '64'     => Mage::helper('usa')->__('Priority Mail Express Sunday/Holiday Delivery Padded Flat Rate Envelope'),
                 'INT_1'  => Mage::helper('usa')->__('Priority Mail Express International'),
                 'INT_2'  => Mage::helper('usa')->__('Priority Mail International'),
                 'INT_4'  => Mage::helper('usa')->__('Global Express Guaranteed (GXG)'),
+                'INT_5'  => Mage::helper('usa')->__('Global Express Guaranteed Document'),
                 'INT_6'  => Mage::helper('usa')->__('Global Express Guaranteed Non-Document Rectangular'),
                 'INT_7'  => Mage::helper('usa')->__('Global Express Guaranteed Non-Document Non-Rectangular'),
                 'INT_8'  => Mage::helper('usa')->__('Priority Mail International Flat Rate Envelope'),
@@ -573,14 +600,24 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                 'INT_14' => Mage::helper('usa')->__('First-Class Mail International Large Envelope'),
                 'INT_15' => Mage::helper('usa')->__('First-Class Package International Service'),
                 'INT_16' => Mage::helper('usa')->__('Priority Mail International Small Flat Rate Box'),
+                'INT_17' => Mage::helper('usa')->__('Priority Mail Express International Legal Flat Rate Envelope'),
+                'INT_18' => Mage::helper('usa')->__('Priority Mail International Gift Card Flat Rate Envelope'),
+                'INT_19' => Mage::helper('usa')->__('Priority Mail International Window Flat Rate Envelope'),
                 'INT_20' => Mage::helper('usa')->__('Priority Mail International Small Flat Rate Envelope'),
+                'INT_21' => Mage::helper('usa')->__('First-Class Mail International Postcard'),
+                'INT_22' => Mage::helper('usa')->__('Priority Mail International Legal Flat Rate Envelope'),
+                'INT_23' => Mage::helper('usa')->__('Priority Mail International Padded Flat Rate Envelope'),
+                'INT_24' => Mage::helper('usa')->__('Priority Mail International DVD Flat Rate priced box'),
+                'INT_25' => Mage::helper('usa')->__('Priority Mail International Large Video Flat Rate priced box'),
                 'INT_26' => Mage::helper('usa')->__('Priority Mail Express International Flat Rate Boxes'),
+                'INT_27' => Mage::helper('usa')->__('Priority Mail Express International Padded Flat Rate Envelope'),
             ),
 
             'service_to_code' => array(
                 '0_FCLE' => 'First Class',
                 '0_FCL'  => 'First Class',
                 '0_FCP'  => 'First Class',
+                '0_FCPC' => 'First Class',
                 '1'      => 'Priority',
                 '2'      => 'Priority Express',
                 '3'      => 'Priority Express',
@@ -588,6 +625,7 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                 '6'      => 'Media',
                 '7'      => 'Library',
                 '13'     => 'Priority Express',
+                '15'     => 'First Class',
                 '16'     => 'Priority',
                 '17'     => 'Priority',
                 '22'     => 'Priority',
@@ -595,21 +633,42 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                 '25'     => 'Priority Express',
                 '27'     => 'Priority Express',
                 '28'     => 'Priority',
+                '29'     => 'Priority',
+                '30'     => 'Priority Express',
+                '31'     => 'Priority Express',
+                '32'     => 'Priority Express',
                 '33'     => 'Priority',
                 '34'     => 'Priority',
                 '35'     => 'Priority',
                 '36'     => 'Priority',
                 '37'     => 'Priority',
+                '38'     => 'Priority',
+                '39'     => 'Priority',
+                '40'     => 'Priority',
+                '41'     => 'Priority',
                 '42'     => 'Priority',
                 '43'     => 'Priority',
+                '44'     => 'Priority',
+                '45'     => 'Priority',
+                '46'     => 'Priority',
+                '47'     => 'Priority',
+                '48'     => 'Priority',
+                '49'     => 'Priority',
+                '50'     => 'Priority',
                 '53'     => 'First Class',
                 '55'     => 'Priority Express',
                 '56'     => 'Priority Express',
                 '57'     => 'Priority Express',
+                '58'     => 'Priority',
+                '59'     => 'Priority',
                 '61'     => 'First Class',
+                '62'     => 'Priority Express',
+                '63'     => 'Priority Express',
+                '64'     => 'Priority Express',
                 'INT_1'  => 'Priority Express',
                 'INT_2'  => 'Priority',
                 'INT_4'  => 'Priority Express',
+                'INT_5'  => 'Priority Express',
                 'INT_6'  => 'Priority Express',
                 'INT_7'  => 'Priority Express',
                 'INT_8'  => 'Priority',
@@ -621,8 +680,17 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                 'INT_14' => 'First Class',
                 'INT_15' => 'First Class',
                 'INT_16' => 'Priority',
+                'INT_17' => 'Priority',
+                'INT_18' => 'Priority',
+                'INT_19' => 'Priority',
                 'INT_20' => 'Priority',
+                'INT_21' => 'First Class',
+                'INT_22' => 'Priority',
+                'INT_23' => 'Priority',
+                'INT_24' => 'Priority',
+                'INT_25' => 'Priority',
                 'INT_26' => 'Priority Express',
+                'INT_27' => 'Priority Express',
             ),
 
             // Added because USPS has different services but with same CLASSID value, which is "0"
@@ -718,6 +786,8 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                                 'Priority Mail International Large Flat Rate Box',
                                 'Priority Mail International Medium Flat Rate Box',
                                 'Priority Mail International Small Flat Rate Box',
+                                'Priority Mail International DVD Flat Rate priced box',
+                                'Priority Mail International Large Video Flat Rate priced box',
                             )
                         )
                     )
@@ -735,6 +805,7 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                                 'Priority Mail Small Flat Rate Envelope',
                                 'Priority Mail Small Flat Rate Envelope Hold For Pickup',
                                 'Priority Mail Express Sunday/Holiday Delivery Flat Rate Envelope',
+                                'Priority Mail Express Padded Flat Rate Envelope',
                             )
                         ),
                         'from_us' => array(
@@ -743,6 +814,11 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                                 'Priority Mail International Flat Rate Envelope',
                                 'First-Class Mail International Large Envelope',
                                 'Priority Mail International Small Flat Rate Envelope',
+                                'Priority Mail Express International Legal Flat Rate Envelope',
+                                'Priority Mail International Gift Card Flat Rate Envelope',
+                                'Priority Mail International Window Flat Rate Envelope',
+                                'Priority Mail International Legal Flat Rate Envelope',
+                                'Priority Mail Express International Padded Flat Rate Envelope',
                             )
                         )
                     )
