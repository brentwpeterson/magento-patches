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


SUPEE-3509 | EE_1.13.1.0 | v1 | 5d1f7ee53e980550af9cb343de35cdd509efaf56 | Wed Jul 9 17:29:37 2014 -0700 | v1.13.1.0..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/CatalogRule/Model/Observer.php app/code/core/Mage/CatalogRule/Model/Observer.php
index 0f033a4..c1588f0 100644
--- app/code/core/Mage/CatalogRule/Model/Observer.php
+++ app/code/core/Mage/CatalogRule/Model/Observer.php
@@ -88,11 +88,9 @@ class Mage_CatalogRule_Model_Observer
         $pId        = $product->getId();
         $storeId    = $product->getStoreId();
 
-        if ($observer->hasDate()) {
-            $date = $observer->getEvent()->getDate();
-        } else {
-            $date = Mage::app()->getLocale()->storeTimeStamp($storeId);
-        }
+        /** @var $coreDate Mage_Core_Model_Date */
+        $coreDate = Mage::getSingleton('core/date');
+        $date = $coreDate->gmtTimestamp('Today');
 
         if ($observer->hasWebsiteId()) {
             $wId = $observer->getEvent()->getWebsiteId();
@@ -131,8 +129,11 @@ class Mage_CatalogRule_Model_Observer
     public function processAdminFinalPrice($observer)
     {
         $product = $observer->getEvent()->getProduct();
-        $storeId = $product->getStoreId();
-        $date = Mage::app()->getLocale()->storeDate($storeId);
+        
+        /** @var $coreDate Mage_Core_Model_Date */
+        $coreDate = Mage::getSingleton('core/date');
+        $date = $coreDate->gmtTimestamp('Today');
+        
         $key = false;
 
         if ($ruleData = Mage::registry('rule_data')) {
@@ -345,11 +346,8 @@ class Mage_CatalogRule_Model_Observer
                 $groupId = Mage_Customer_Model_Group::NOT_LOGGED_IN_ID;
             }
         }
-        if ($observer->getEvent()->hasDate()) {
-            $date = $observer->getEvent()->getDate();
-        } else {
-            $date = Mage::app()->getLocale()->storeTimeStamp($store);
-        }
+        
+        $date = Mage::app()->getLocale()->storeTimeStamp($store);
 
         $productIds = array();
         /* @var $product Mage_Core_Model_Product */
diff --git app/code/core/Mage/CatalogRule/Model/Resource/Rule.php app/code/core/Mage/CatalogRule/Model/Resource/Rule.php
index fcd28df..5942bff 100644
--- app/code/core/Mage/CatalogRule/Model/Resource/Rule.php
+++ app/code/core/Mage/CatalogRule/Model/Resource/Rule.php
@@ -207,9 +207,12 @@ class Mage_CatalogRule_Model_Resource_Rule extends Mage_Rule_Model_Resource_Abst
         /** @var $write Varien_Db_Adapter_Interface */
         $write = $this->_getWriteAdapter();
 
+        /** @var $coreDate Mage_Core_Model_Date */
+        $coreDate  = $this->_factory->getModel('core/date');
+
         $customerGroupIds = $rule->getCustomerGroupIds();
-        $fromTime = (int) strtotime($rule->getFromDate());
-        $toTime = (int) strtotime($rule->getToDate());
+        $fromTime = (int) $coreDate->gmtTimestamp($rule->getFromDate());
+        $toTime = (int) $coreDate->gmtTimestamp($rule->getToDate());
         $toTime = $toTime ? ($toTime + self::SECONDS_IN_DAY - 1) : 0;
         $sortOrder = (int) $rule->getSortOrder();
         $actionOperator = $rule->getSimpleAction();
@@ -662,7 +665,7 @@ class Mage_CatalogRule_Model_Resource_Rule extends Mage_Rule_Model_Resource_Abst
      * Get catalog rules product price for specific date, website and
      * customer group
      *
-     * @param int|string $date
+     * @param int $date Timestamp
      * @param int $wId
      * @param int $gId
      * @param int $pId
@@ -683,7 +686,7 @@ class Mage_CatalogRule_Model_Resource_Rule extends Mage_Rule_Model_Resource_Abst
      * Retrieve product prices by catalog rule for specific date, website and customer group
      * Collect data with  product Id => price pairs
      *
-     * @param int|string $date
+     * @param int $date Timestamp
      * @param int $websiteId
      * @param int $customerGroupId
      * @param array $productIds
@@ -695,7 +698,7 @@ class Mage_CatalogRule_Model_Resource_Rule extends Mage_Rule_Model_Resource_Abst
         $adapter = $this->_getReadAdapter();
         $select  = $adapter->select()
             ->from($this->getTable('catalogrule/rule_product_price'), array('product_id', 'rule_price'))
-            ->where('rule_date = ?', $this->formatDate($date, false))
+            ->where('rule_date = ?', $adapter->fromUnixtime($date))
             ->where('website_id = ?', $websiteId)
             ->where('customer_group_id = ?', $customerGroupId)
             ->where('product_id IN(?)', $productIds);
