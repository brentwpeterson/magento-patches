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


SUPEE-5984 | EE_1.14.2.0 | v1 | 71bf44fbec983cd9758bf725c1aa1a57ca303e1b | Wed May 13 15:11:40 2015 +0300 | v1.14.2.0..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/community/OnTap/Merchandiser/Model/Adminhtml/Observer.php app/code/community/OnTap/Merchandiser/Model/Adminhtml/Observer.php
index 847ab86..19562d4 100644
--- app/code/community/OnTap/Merchandiser/Model/Adminhtml/Observer.php
+++ app/code/community/OnTap/Merchandiser/Model/Adminhtml/Observer.php
@@ -94,9 +94,6 @@ class OnTap_Merchandiser_Model_Adminhtml_Observer
         $positionsArray = $productPositions;
         asort($productPositions);
         $productPositions = array_keys($productPositions);
-        if ($post['merchandiser']['ruled_only'] == 1) {
-            $productPositions = array();
-        }
 
         $insertValues = array();
         $attributeCodes = array();
diff --git app/code/community/OnTap/Merchandiser/Model/Resource/Merchandiser.php app/code/community/OnTap/Merchandiser/Model/Resource/Merchandiser.php
index 5c337df..006d197 100644
--- app/code/community/OnTap/Merchandiser/Model/Resource/Merchandiser.php
+++ app/code/community/OnTap/Merchandiser/Model/Resource/Merchandiser.php
@@ -76,19 +76,33 @@ class OnTap_Merchandiser_Model_Resource_Merchandiser extends Mage_Catalog_Model_
     }
 
     /**
-     * insertMultipleProductsToCategory
+     * Assign products to categories at specified positions, skipping non-existing products/categories
      *
-     * @param mixed $insertData
+     * @param array $insertData
      * @return void
      */
     public function insertMultipleProductsToCategory($insertData)
     {
         $write = $this->_getWriteAdapter();
+
+        // Attempt to insert all rows at once, assuming that referential integrity is maintained
         try {
             $write->insertMultiple($this->catalogCategoryProduct, $insertData);
+            return;
         } catch (Exception $e) {
-            Mage::log($e->getMessage());
+            // Fall back to per-row insertion, because even one erroneous row fails entire batch
+        }
+
+        // Insert rows one by one, skipping erroneous ones and logging encountered errors
+        $write->beginTransaction();
+        foreach ($insertData as $insertRow) {
+            try {
+                $write->insert($this->catalogCategoryProduct, $insertRow);
+            } catch (Exception $e) {
+                Mage::log($e->getMessage());
+            }
         }
+        $write->commit();
     }
 
     /**
diff --git app/code/core/Enterprise/Catalog/Model/Index/Action/Product/Flat/Refresh.php app/code/core/Enterprise/Catalog/Model/Index/Action/Product/Flat/Refresh.php
index a98a5ee..5b7e2d3 100644
--- app/code/core/Enterprise/Catalog/Model/Index/Action/Product/Flat/Refresh.php
+++ app/code/core/Enterprise/Catalog/Model/Index/Action/Product/Flat/Refresh.php
@@ -81,13 +81,6 @@ class Enterprise_Catalog_Model_Index_Action_Product_Flat_Refresh extends Enterpr
     protected $_storeId = 0;
 
     /**
-     * Calls amount during current session
-     *
-     * @var int
-     */
-    protected static $_calls = 0;
-
-    /**
      * Product helper, contains some useful functions for operations with attributes
      *
      * @var Enterprise_Catalog_Helper_Product
@@ -745,12 +738,11 @@ class Enterprise_Catalog_Model_Index_Action_Product_Flat_Refresh extends Enterpr
      *
      * @param int $storeId
      * @param array $changedIds
-     * @param bool $resetFlag
      *
      * @return Enterprise_Catalog_Model_Index_Action_Product_Flat_Refresh
      * @throws Exception
      */
-    protected function _reindex($storeId, array $changedIds = array(), $resetFlag = false)
+    protected function _reindex($storeId, array $changedIds = array())
     {
         $this->_storeId     = $storeId;
         $entityTableName    = $this->_productHelper->getTable('catalog/product');
@@ -761,39 +753,37 @@ class Enterprise_Catalog_Model_Index_Action_Product_Flat_Refresh extends Enterpr
 
         try {
             //We should prepare temp. tables only for first call of reindex all
-            if (!self::$_calls && !$resetFlag) {
-                $temporaryEavAttributes = $eavAttributes;
-
-                //add status global value to the base table
-                /* @var $status Mage_Eav_Model_Entity_Attribute */
-                $status = $this->_productHelper->getAttribute('status');
-                $temporaryEavAttributes[$status->getBackendTable()]['status'] = $status;
-                //Create list of temporary tables based on available attributes attributes
-                foreach ($temporaryEavAttributes as $tableName => $columns) {
-                    $this->_createTemporaryTable($this->_getTemporaryTableName($tableName), $columns);
-                }
+            $temporaryEavAttributes = $eavAttributes;
+
+            //add status global value to the base table
+            /* @var $status Mage_Eav_Model_Entity_Attribute */
+            $status = $this->_productHelper->getAttribute('status');
+            $temporaryEavAttributes[$status->getBackendTable()]['status'] = $status;
+            //Create list of temporary tables based on available attributes attributes
+            foreach ($temporaryEavAttributes as $tableName => $columns) {
+                $this->_createTemporaryTable($this->_getTemporaryTableName($tableName), $columns);
+            }
 
-                //Fill "base" table which contains all available products
-                $this->_fillTemporaryEntityTable($entityTableName, $entityTableColumns, $changedIds);
+            //Fill "base" table which contains all available products
+            $this->_fillTemporaryEntityTable($entityTableName, $entityTableColumns, $changedIds);
 
-                //Add primary key to "base" temporary table for increase speed of joins in future
-                $this->_addPrimaryKeyToTable($this->_getTemporaryTableName($entityTableName));
-                unset($temporaryEavAttributes[$entityTableName]);
+            //Add primary key to "base" temporary table for increase speed of joins in future
+            $this->_addPrimaryKeyToTable($this->_getTemporaryTableName($entityTableName));
+            unset($temporaryEavAttributes[$entityTableName]);
 
-                foreach ($temporaryEavAttributes as $tableName => $columns) {
-                    $temporaryTableName = $this->_getTemporaryTableName($tableName);
+            foreach ($temporaryEavAttributes as $tableName => $columns) {
+                $temporaryTableName = $this->_getTemporaryTableName($tableName);
 
-                    //Add primary key to temporary table for increase speed of joins in future
-                    $this->_addPrimaryKeyToTable($temporaryTableName);
+                //Add primary key to temporary table for increase speed of joins in future
+                $this->_addPrimaryKeyToTable($temporaryTableName);
 
-                    //Create temporary table for composite attributes
-                    if (isset($this->_valueTables[$temporaryTableName . $this->_valueFieldSuffix])) {
-                        $this->_addPrimaryKeyToTable($temporaryTableName . $this->_valueFieldSuffix);
-                    }
-
-                    //Fill temporary tables with attributes grouped by it type
-                    $this->_fillTemporaryTable($tableName, $columns, $changedIds);
+                //Create temporary table for composite attributes
+                if (isset($this->_valueTables[$temporaryTableName . $this->_valueFieldSuffix])) {
+                    $this->_addPrimaryKeyToTable($temporaryTableName . $this->_valueFieldSuffix);
                 }
+
+                //Fill temporary tables with attributes grouped by it type
+                $this->_fillTemporaryTable($tableName, $columns, $changedIds);
             }
             //Create and fill flat temporary table
             $this->_createTemporaryFlatTable();
@@ -806,7 +796,6 @@ class Enterprise_Catalog_Model_Index_Action_Product_Flat_Refresh extends Enterpr
             $this->_updateEventAttributes($this->_storeId);
             $this->_updateRelationProducts($this->_storeId, $changedIds);
             $this->_cleanRelationProducts($this->_storeId);
-            self::$_calls++;
             $flag->setIsBuilt(true)->setStoreBuilt($this->_storeId, true)->save();
         } catch (Exception $e) {
             $flag->setIsBuilt(false)->setStoreBuilt($this->_storeId, false)->save();
diff --git app/code/core/Enterprise/Catalog/Model/Index/Action/Product/Flat/Refresh/Changelog.php app/code/core/Enterprise/Catalog/Model/Index/Action/Product/Flat/Refresh/Changelog.php
index 0813ed9..2d1bdd5 100644
--- app/code/core/Enterprise/Catalog/Model/Index/Action/Product/Flat/Refresh/Changelog.php
+++ app/code/core/Enterprise/Catalog/Model/Index/Action/Product/Flat/Refresh/Changelog.php
@@ -86,13 +86,11 @@ class Enterprise_Catalog_Model_Index_Action_Product_Flat_Refresh_Changelog
         $changedIds = $this->_selectChangedIds();
         if (!empty($changedIds)) {
             $stores = Mage::app()->getStores();
-            $resetFlag = true;
             foreach ($stores as $store) {
                 $idsBatches = array_chunk($changedIds, Mage::helper('enterprise_index')->getBatchSize());
                 foreach ($idsBatches as $ids) {
-                    $this->_reindex($store->getId(), $ids, $resetFlag);
+                    $this->_reindex($store->getId(), $ids);
                 }
-                $resetFlag = false;
             }
             $this->_setChangelogValid();
             Mage::dispatchEvent('catalog_product_flat_partial_reindex', array('product_ids' => $changedIds));
