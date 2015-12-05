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


SUPEE-5298 | EE_1.14.0.1 | v3 | 9ed7a417802495435b096059f9c9ddeca46f7434 | Tue Aug 4 14:09:19 2015 -0700 | v1.14.0.1..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Catalog/Model/Product/Attribute/Repository.php app/code/core/Mage/Catalog/Model/Product/Attribute/Repository.php
new file mode 100644
index 0000000..2258281
--- /dev/null
+++ app/code/core/Mage/Catalog/Model/Product/Attribute/Repository.php
@@ -0,0 +1,77 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition License
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magentocommerce.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Eav
+ * @copyright   Copyright (c) 2014 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://www.magentocommerce.com/license/enterprise-edition
+ */
+
+
+/**
+ * EAV Entity Attribute Repository
+ *
+ * @category    Mage
+ * @package     Mage_Eav
+ * @author      Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Catalog_Model_Product_Attribute_Repository
+{
+    /**
+     * Product attributes storage
+     *
+     * @var array
+     */
+    protected $_attributes = array();
+
+    /**
+     * Load product attribute or get it from the repository if it's loaded already
+     *
+     * @param  string $attributeCode
+     *
+     * @return Mage_Catalog_Model_Resource_Eav_Attribute|false
+     */
+    public function getAttribute($attributeCode)
+    {
+        if (!strlen($attributeCode)) {
+            return false;
+        }
+
+        if (isset($this->_attributes[$attributeCode])) {
+            return $this->_attributes[$attributeCode];
+        }
+
+        $attribute = Mage::getSingleton('eav/config')->getAttribute(Mage_Catalog_Model_Product::ENTITY, $attributeCode);
+        $this->_attributes[$attributeCode] = $attribute;
+
+        return $attribute;
+    }
+
+    /**
+     * Clear the repository to free the memory
+     *
+     * @return Mage_Catalog_Model_Product_Attribute_Repository
+     */
+    public function clear()
+    {
+        $this->_attributes = array();
+        return $this;
+    }
+}
diff --git app/code/core/Mage/CatalogRule/Model/Action/Index/Refresh.php app/code/core/Mage/CatalogRule/Model/Action/Index/Refresh.php
index b3d7f17..ca0567e 100644
--- app/code/core/Mage/CatalogRule/Model/Action/Index/Refresh.php
+++ app/code/core/Mage/CatalogRule/Model/Action/Index/Refresh.php
@@ -62,6 +62,13 @@ class Mage_CatalogRule_Model_Action_Index_Refresh
     protected $_app;
 
     /**
+     * Target table for index data filling
+     *
+     * @var string
+     */
+    protected $_indexTargetTable;
+
+    /**
      * Constructor with parameters
      * Array of arguments with keys
      *  - 'connection' Varien_Db_Adapter_Interface
@@ -77,6 +84,8 @@ class Mage_CatalogRule_Model_Action_Index_Refresh
         $this->_setFactory($args['factory']);
         $this->_setResource($args['resource']);
         $this->_app = !empty($args['app']) ? $args['app'] : Mage::app();
+
+        $this->_indexTargetTable = $this->_resource->getTable('catalogrule/rule_product_price');
     }
 
     /**
@@ -110,6 +119,37 @@ class Mage_CatalogRule_Model_Action_Index_Refresh
     }
 
     /**
+     * Get name for new index data set table
+     *
+     * @return string
+     */
+    protected function _getNewIndexTableName()
+    {
+        return $this->_resource->getTable('catalogrule/rule_product_price') . '_index_tmp';
+    }
+
+    /**
+     * Get tmp name for original table
+     *
+     * @return string
+     */
+    protected function _getOldIndexTableName()
+    {
+        return $this->_resource->getTable('catalogrule/rule_product_price') . '_index_old';
+    }
+
+    /**
+     * Get reindex using table swapping availability
+     *
+     * @return bool
+     */
+    protected function _isIndexTableSwapAllowed()
+    {
+        return $this->_connection->getTransactionLevel() == 0
+            && !$this->_connection->isTableExists($this->_getNewIndexTableName());
+    }
+
+    /**
      * Run reindex
      */
     public function execute()
@@ -120,10 +160,44 @@ class Mage_CatalogRule_Model_Action_Index_Refresh
         $coreDate  = $this->_factory->getModel('core/date');
         $timestamp = $coreDate->gmtTimestamp('Today');
 
-        foreach ($this->_app->getWebsites(false) as $website) {
-            /** @var $website Mage_Core_Model_Website */
-            if ($website->getDefaultStore()) {
-                $this->_reindex($website, $timestamp);
+        if ($this->_isIndexTableSwapAllowed()) {
+            $connection = $this->_connection;
+            $currentTableName = $this->_resource->getTable('catalogrule/rule_product_price');
+            $newTableName = $this->_getNewIndexTableName();
+            $oldTableName = $this->_getOldIndexTableName();
+            $this->_indexTargetTable = $newTableName;
+
+            $table = $connection->duplicateTableByDdl($currentTableName, $newTableName, true);
+            $connection->dropAllForeignKeysFromTable($currentTableName);
+            $connection->createTable($table);
+            unset($table);
+
+            foreach ($this->_app->getWebsites(false) as $website) {
+                /** @var $website Mage_Core_Model_Website */
+                if ($website->getDefaultStore()) {
+                    $this->_createTemporaryTable();
+                    $this->_prepareIndexDataPerWebsite($website);
+                    $this->_fillIndexData($website, $timestamp);
+                }
+            }
+
+            $connection->renameTablesBatch(array(
+                array(
+                    'oldName' => $currentTableName,
+                    'newName' => $oldTableName
+                ),
+                array(
+                    'oldName' => $newTableName,
+                    'newName' => $currentTableName
+                )
+            ));
+            $connection->dropTable($oldTableName);
+        } else {
+            foreach ($this->_app->getWebsites(false) as $website) {
+                /** @var $website Mage_Core_Model_Website */
+                if ($website->getDefaultStore()) {
+                    $this->_reindex($website, $timestamp);
+                }
             }
         }
 
@@ -566,26 +640,43 @@ class Mage_CatalogRule_Model_Action_Index_Refresh
         $this->_connection->query(
             $this->_connection->insertFromSelect(
                 $this->_prepareIndexSelect($website, $time),
-                $this->_resource->getTable('catalogrule/rule_product_price')
+                $this->_indexTargetTable
             )
         );
     }
 
     /**
-     * Reindex catalog prices by website for timestamp
+     * Prepare index data and put it to temporary table
      *
      * @param Mage_Core_Model_Website $website
-     * @param int $timestamp
+     *
+     * @return $this
      */
-    protected function _reindex(Mage_Core_Model_Website $website, $timestamp)
+    protected function _prepareIndexDataPerWebsite(Mage_Core_Model_Website $website)
     {
-        $this->_createTemporaryTable();
         $this->_connection->query(
             $this->_connection->insertFromSelect(
                 $this->_prepareTemporarySelect($website),
                 $this->_getTemporaryTable()
             )
         );
+
+        return $this;
+    }
+
+    /**
+     * Reindex catalog prices by website for timestamp
+     *
+     * @deprecated - all logic moved to Mage_CatalogRule_Model_Action_Index_Refresh::execute()
+     *
+     * @param Mage_Core_Model_Website $website
+     * @param int $timestamp
+     */
+    protected function _reindex(Mage_Core_Model_Website $website, $timestamp)
+    {
+        $this->_createTemporaryTable();
+        $this->_prepareIndexDataPerWebsite($website);
+
         $this->_removeOldIndexData($website);
         $this->_fillIndexData($website, $timestamp);
     }
diff --git app/code/core/Mage/CatalogRule/Model/Action/Index/Refresh/Row.php app/code/core/Mage/CatalogRule/Model/Action/Index/Refresh/Row.php
index 3b67de8..e338ff1 100644
--- app/code/core/Mage/CatalogRule/Model/Action/Index/Refresh/Row.php
+++ app/code/core/Mage/CatalogRule/Model/Action/Index/Refresh/Row.php
@@ -98,4 +98,14 @@ class Mage_CatalogRule_Model_Action_Index_Refresh_Row extends Mage_CatalogRule_M
     {
         return $this->_productId;
     }
+
+    /**
+     * For row update index table swap is not an applicable approach
+     *
+     * @return bool
+     */
+    protected function _isIndexTableSwapAllowed()
+    {
+        return false;
+    }
 }
diff --git app/code/core/Mage/CatalogRule/Model/Rule.php app/code/core/Mage/CatalogRule/Model/Rule.php
index 81a1d3b..d60791c 100644
--- app/code/core/Mage/CatalogRule/Model/Rule.php
+++ app/code/core/Mage/CatalogRule/Model/Rule.php
@@ -315,6 +315,10 @@ class Mage_CatalogRule_Model_Rule extends Mage_Rule_Model_Abstract
     public function applyAll()
     {
         $this->getResourceCollection()->walk(array($this->_getResource(), 'updateRuleProductData'));
+        /**
+         * Removing the product attributes data from the memory
+         */
+        Mage::getSingleton('catalog/product_attribute_repository')->clear();
         $this->_getResource()->applyAllRules();
         $this->_invalidateCache();
         $indexProcess = Mage::getSingleton('index/indexer')->getProcessByCode('catalog_product_price');
diff --git app/code/core/Mage/Rule/Model/Condition/Product/Abstract.php app/code/core/Mage/Rule/Model/Condition/Product/Abstract.php
index 8283e04..74b691e 100644
--- app/code/core/Mage/Rule/Model/Condition/Product/Abstract.php
+++ app/code/core/Mage/Rule/Model/Condition/Product/Abstract.php
@@ -153,13 +153,12 @@ abstract class Mage_Rule_Model_Condition_Product_Abstract extends Mage_Rule_Mode
     /**
      * Retrieve attribute object
      *
-     * @return Mage_Catalog_Model_Resource_Eav_Attribute
+     * @return Mage_Catalog_Model_Resource_Eav_Attribute|false
      */
     public function getAttributeObject()
     {
         try {
-            $obj = Mage::getSingleton('eav/config')
-                ->getAttribute(Mage_Catalog_Model_Product::ENTITY, $this->getAttribute());
+            $obj = Mage::getSingleton('catalog/product_attribute_repository')->getAttribute($this->getAttribute());
         }
         catch (Exception $e) {
             $obj = new Varien_Object();
diff --git lib/Varien/Db/Adapter/Pdo/Mysql.php lib/Varien/Db/Adapter/Pdo/Mysql.php
index 13b3ec2..36b8f41 100644
--- lib/Varien/Db/Adapter/Pdo/Mysql.php
+++ lib/Varien/Db/Adapter/Pdo/Mysql.php
@@ -714,6 +714,36 @@ class Varien_Db_Adapter_Pdo_Mysql extends Zend_Db_Adapter_Pdo_Mysql implements V
     }
 
     /**
+     * Drop all the foreign keys from table
+     *
+     * @param string $tableName
+     * @param null|string $schemaName
+     *
+     * @return $this
+     */
+    public function dropAllForeignKeysFromTable($tableName, $schemaName = null)
+    {
+        $foreignKeys = $this->getForeignKeys($tableName, $schemaName);
+
+        if (empty($foreignKeys)) {
+            return $this;
+        }
+
+        $dropKey = array();
+        foreach ($foreignKeys as $key) {
+            $dropKey[] = ' DROP FOREIGN KEY ' . $this->quoteIdentifier($key['FK_NAME']);
+        }
+
+        $sql = 'ALTER TABLE ' . $this->quoteIdentifier($this->_getTableName($tableName, $schemaName))
+            . implode(',', $dropKey);
+
+        $this->resetDdlCache($tableName, $schemaName);
+        $this->raw_query($sql);
+
+        return $this;
+    }
+
+    /**
      * Delete index from a table if it exists
      *
      * @deprecated since 1.4.0.1
@@ -1662,13 +1692,15 @@ class Varien_Db_Adapter_Pdo_Mysql extends Zend_Db_Adapter_Pdo_Mysql implements V
     }
 
     /**
-     * Create Varien_Db_Ddl_Table object by data from describe table
+     * Create Varien_Db_Ddl_Table object by data from describe table with exactly the same key names
+     *
+     * @param string $tableName
+     * @param string $newTableName
+     * @param bool $preserveKeyNames
      *
-     * @param $tableName
-     * @param $newTableName
      * @return Varien_Db_Ddl_Table
      */
-    public function createTableByDdl($tableName, $newTableName)
+    public function duplicateTableByDdl($tableName, $newTableName, $preserveKeyNames = false)
     {
         $describe = $this->describeTable($tableName);
         $table = $this->newTable($newTableName)
@@ -1686,6 +1718,8 @@ class Varien_Db_Adapter_Pdo_Mysql extends Zend_Db_Adapter_Pdo_Mysql implements V
             );
         }
 
+        $targetTableName = ($preserveKeyNames) ? $tableName : $newTableName;
+
         $indexes = $this->getIndexList($tableName);
         foreach ($indexes as $indexData) {
             /**
@@ -1700,13 +1734,13 @@ class Varien_Db_Adapter_Pdo_Mysql extends Zend_Db_Adapter_Pdo_Mysql implements V
 
             $fields = $indexData['COLUMNS_LIST'];
             $options = array('type' => $indexData['INDEX_TYPE']);
-            $table->addIndex($this->getIndexName($newTableName, $fields, $indexData['INDEX_TYPE']), $fields, $options);
+            $table->addIndex($this->getIndexName($targetTableName, $fields, $indexData['INDEX_TYPE']), $fields, $options);
         }
 
         $foreignKeys = $this->getForeignKeys($tableName);
         foreach ($foreignKeys as $keyData) {
             $fkName = $this->getForeignKeyName(
-                $newTableName, $keyData['COLUMN_NAME'], $keyData['REF_TABLE_NAME'], $keyData['REF_COLUMN_NAME']
+                $targetTableName, $keyData['COLUMN_NAME'], $keyData['REF_TABLE_NAME'], $keyData['REF_COLUMN_NAME']
             );
             $onDelete = $this->_getDdlAction($keyData['ON_DELETE']);
             $onUpdate = $this->_getDdlAction($keyData['ON_UPDATE']);
@@ -1725,6 +1759,18 @@ class Varien_Db_Adapter_Pdo_Mysql extends Zend_Db_Adapter_Pdo_Mysql implements V
     }
 
     /**
+     * Create Varien_Db_Ddl_Table object by data from describe table
+     *
+     * @param $tableName
+     * @param $newTableName
+     * @return Varien_Db_Ddl_Table
+     */
+    public function createTableByDdl($tableName, $newTableName)
+    {
+        return $this->duplicateTableByDdl($tableName, $newTableName);
+    }
+
+    /**
      * Modify the column definition by data from describe table
      *
      * @param string $tableName
