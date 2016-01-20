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


SUPEE-7616 | CE_1.9.2.2-CE_1.8.0.0 | v1 | 1609c0d0be86473d357346fa51f93c12b365d7a1 | Tue Dec 8 12:53:31 2015 +0200 | e1fc3c59c9587427b8a9c88655715f27afbfe970..1609c0d0be86473d357346fa51f93c12b365d7a1

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps.php
index 8091b36..582452d 100644
--- app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps.php
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps.php
@@ -544,7 +544,7 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                  '1'      => Mage::helper('usa')->__('Priority Mail'),
                  '2'      => Mage::helper('usa')->__('Priority Mail Express Hold For Pickup'),
                  '3'      => Mage::helper('usa')->__('Priority Mail Express'),
-                 '4'      => Mage::helper('usa')->__('Standard Post'),
+                 '4'      => Mage::helper('usa')->__('Retail Ground'),
                  '6'      => Mage::helper('usa')->__('Media Mail Parcel'),
                  '7'      => Mage::helper('usa')->__('Library Mail Parcel'),
                  '13'     => Mage::helper('usa')->__('Priority Mail Express Flat Rate Envelope'),
@@ -579,8 +579,6 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                  '49'     => Mage::helper('usa')->__('Priority Mail Regional Rate Box B'),
                  '50'     => Mage::helper('usa')->__('Priority Mail Regional Rate Box B Hold For Pickup'),
                  '53'     => Mage::helper('usa')->__('First-Class Package Service Hold For Pickup'),
-                 '55'     => Mage::helper('usa')->__('Priority Mail Express Flat Rate Boxes'),
-                 '56'     => Mage::helper('usa')->__('Priority Mail Express Flat Rate Boxes Hold For Pickup'),
                  '57'     => Mage::helper('usa')->__('Priority Mail Express Sunday/Holiday Delivery Flat Rate Boxes'),
                  '58'     => Mage::helper('usa')->__('Priority Mail Regional Rate Box C'),
                  '59'     => Mage::helper('usa')->__('Priority Mail Regional Rate Box C Hold For Pickup'),
@@ -612,7 +610,6 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                  'INT_23' => Mage::helper('usa')->__('Priority Mail International Padded Flat Rate Envelope'),
                  'INT_24' => Mage::helper('usa')->__('Priority Mail International DVD Flat Rate priced box'),
                  'INT_25' => Mage::helper('usa')->__('Priority Mail International Large Video Flat Rate priced box'),
-                 'INT_26' => Mage::helper('usa')->__('Priority Mail Express International Flat Rate Boxes'),
                  'INT_27' => Mage::helper('usa')->__('Priority Mail Express International Padded Flat Rate Envelope'),
              ),
 
@@ -624,7 +621,7 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                  '1'      => 'Priority',
                  '2'      => 'Priority Express',
                  '3'      => 'Priority Express',
-                 '4'      => 'Standard Post',
+                 '4'      => 'Retail Ground',
                  '6'      => 'Media',
                  '7'      => 'Library',
                  '13'     => 'Priority Express',
@@ -659,8 +656,6 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                  '49'     => 'Priority',
                  '50'     => 'Priority',
                  '53'     => 'First Class',
-                 '55'     => 'Priority Express',
-                 '56'     => 'Priority Express',
                  '57'     => 'Priority Express',
                  '58'     => 'Priority',
                  '59'     => 'Priority',
@@ -692,7 +687,6 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                  'INT_23' => 'Priority',
                  'INT_24' => 'Priority',
                  'INT_25' => 'Priority',
-                 'INT_26' => 'Priority Express',
                  'INT_27' => 'Priority Express',
              ),
 
@@ -742,7 +736,7 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                                 'First-Class Package Service Hold For Pickup',
                                 'Priority Mail Express Flat Rate Boxes',
                                 'Priority Mail Express Flat Rate Boxes Hold For Pickup',
-                                'Standard Post',
+                                'Retail Ground',
                                 'Media Mail',
                                 'First-Class Mail Large Envelope',
                                 'Priority Mail Express Sunday/Holiday Delivery',
@@ -781,8 +775,6 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                                 'Priority Mail International Large Flat Rate Box',
                                 'Priority Mail International Medium Flat Rate Box',
                                 'Priority Mail International Small Flat Rate Box',
-                                'Priority Mail Express Sunday/Holiday Delivery Flat Rate Boxes',
-
                             )
                         ),
                         'from_us' => array(
@@ -834,7 +826,7 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                             'method' => array(
                                 'Priority Mail Express',
                                 'Priority Mail',
-                                'Standard Post',
+                                'Retail Ground',
                                 'Media Mail',
                                 'Library Mail',
                                 'First-Class Package Service'
@@ -857,7 +849,7 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                             'method' => array(
                                 'Priority Mail Express',
                                 'Priority Mail',
-                                'Standard Post',
+                                'Retail Ground',
                                 'Media Mail',
                                 'Library Mail',
                                 'First-Class Package Service'
@@ -1423,7 +1415,8 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                 break;
             case 'STANDARD':
             case 'Standard Post':
-                $serviceType = 'Standard Post';
+            case 'Retail Ground':
+                $serviceType = 'Retail Ground';
                 break;
             case 'MEDIA':
             case 'Media':
