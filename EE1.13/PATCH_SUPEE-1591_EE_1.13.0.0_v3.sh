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
    PATCH_APPLY_REVERT_RESULT=`"$SED_BIN" -e '1,/^__PATCHFILE_FOLLOWS__$/d' "$CURRENT_DIR""$BASE_NAME" | "$PATCH_BIN" $DRY_RUN_FLAG $REVERT_FLAG -p0`
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


SUPEE-1591 | EE_1.13.0.0 | v3 | e7d7ab265eb4a33cd1d08b4ac1157fc8347e4b66 | Thu Dec 19 17:58:09 2013 -0800 | v1.13.0.0..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Enterprise/Index/Block/Adminhtml/Process/Grid.php app/code/core/Enterprise/Index/Block/Adminhtml/Process/Grid.php
index caba3b7..d69b98e 100755
--- app/code/core/Enterprise/Index/Block/Adminhtml/Process/Grid.php
+++ app/code/core/Enterprise/Index/Block/Adminhtml/Process/Grid.php
@@ -68,7 +68,6 @@ class Enterprise_Index_Block_Adminhtml_Process_Grid extends Mage_Adminhtml_Block
     {
         /** @var $collection  Enterprise_Index_Model_Resource_Process_Collection */
         $collection = Mage::getResourceModel('enterprise_index/process_collection');
-        Mage::dispatchEvent('enterprise_index_exclude_process_before', array('collection' => $collection));
         $collection->initializeSelect();
         $this->setCollection($collection);
         parent::_prepareCollection();
diff --git app/code/core/Enterprise/Index/Model/Indexer.php app/code/core/Enterprise/Index/Model/Indexer.php
index c9fc630..19317ff 100644
--- app/code/core/Enterprise/Index/Model/Indexer.php
+++ app/code/core/Enterprise/Index/Model/Indexer.php
@@ -84,9 +84,6 @@ class Enterprise_Index_Model_Indexer extends Mage_Index_Model_Indexer
     {
         if (is_null($this->_processesCollection)) {
             $this->_processesCollection = $this->_factory->getResourceModel('enterprise_index/process_collection');
-            $this->_app->dispatchEvent('enterprise_index_exclude_process_before',
-                array('collection' => $this->_processesCollection)
-            );
             $this->_processesCollection->initializeSelect();
 
             $processes = array();
diff --git app/code/core/Enterprise/Index/Model/Resource/Process/Collection.php app/code/core/Enterprise/Index/Model/Resource/Process/Collection.php
index 0353f32..91ca938 100755
--- app/code/core/Enterprise/Index/Model/Resource/Process/Collection.php
+++ app/code/core/Enterprise/Index/Model/Resource/Process/Collection.php
@@ -67,6 +67,8 @@ class Enterprise_Index_Model_Resource_Process_Collection extends Mage_Core_Model
      */
     public function initializeSelect()
     {
+        Mage::dispatchEvent('enterprise_index_exclude_process_before', array('collection' => $this));
+
         $this->_select->reset();
 
         $countsSelect = $this->getConnection()
diff --git app/code/core/Enterprise/Search/Helper/Data.php app/code/core/Enterprise/Search/Helper/Data.php
index 665e6b1..cb46ce4 100644
--- app/code/core/Enterprise/Search/Helper/Data.php
+++ app/code/core/Enterprise/Search/Helper/Data.php
@@ -398,7 +398,18 @@ class Enterprise_Search_Helper_Data extends Mage_Core_Helper_Abstract
         return $this->_isEngineAvailableForNavigation;
     }
 
+    /**
+     * Invalidate catalog search index
+     *
+     * @return Enterprise_Search_Helper_Data
+     */
+    public function invalidateCatalogSearchIndex()
+    {
+        Mage::getSingleton('index/indexer')->getProcessByCode('catalogsearch_fulltext')
+            ->changeStatus(Mage_Index_Model_Process::STATUS_REQUIRE_REINDEX);
 
+        return $this;
+    }
 
 
 
diff --git app/code/core/Enterprise/Search/Model/Adapter/Abstract.php app/code/core/Enterprise/Search/Model/Adapter/Abstract.php
index d20fe24..868d29e 100644
--- app/code/core/Enterprise/Search/Model/Adapter/Abstract.php
+++ app/code/core/Enterprise/Search/Model/Adapter/Abstract.php
@@ -89,7 +89,7 @@ abstract class Enterprise_Search_Model_Adapter_Abstract
      */
     protected $_defaultQueryParams = array(
         'offset' => 0,
-        'limit' => 100,
+        'limit' => Enterprise_Search_Model_Adapter_Solr_Abstract::DEFAULT_ROWS_LIMIT,
         'sort_by' => array(array('score' => 'desc')),
         'store_id' => null,
         'locale_code' => null,
@@ -397,10 +397,11 @@ abstract class Enterprise_Search_Model_Adapter_Abstract
             }
 
             $attribute->setStoreId($storeId);
-
+            $preparedValue = '';
             // Preparing data for solr fields
             if ($attribute->getIsSearchable() || $attribute->getIsVisibleInAdvancedSearch()
                 || $attribute->getIsFilterable() || $attribute->getIsFilterableInSearch()
+                || $attribute->getUsedForSortBy()
             ) {
                 $backendType = $attribute->getBackendType();
                 $frontendInput = $attribute->getFrontendInput();
@@ -409,7 +410,7 @@ abstract class Enterprise_Search_Model_Adapter_Abstract
                     if ($frontendInput == 'multiselect') {
                         $preparedValue = array();
                         foreach ($value as $val) {
-                            $preparedValue = array_merge($preparedValue, explode(',', $val));
+                            $preparedValue = array_merge($preparedValue, array_filter(explode(',', $val)));
                         }
                         $preparedNavValue = $preparedValue;
                     } else {
@@ -439,16 +440,16 @@ abstract class Enterprise_Search_Model_Adapter_Abstract
                     if ($backendType == 'datetime') {
                         if (is_array($value)) {
                             $preparedValue = array();
-                            foreach ($value as &$val) {
+                            foreach ($value as $id => &$val) {
                                 $val = $this->_getSolrDate($storeId, $val);
                                 if (!empty($val)) {
-                                    $preparedValue[] = $val;
+                                    $preparedValue[$id] = $val;
                                 }
                             }
                             unset($val); //clear link to value
                             $preparedValue = array_unique($preparedValue);
                         } else {
-                            $preparedValue = $this->_getSolrDate($storeId, $value);
+                            $preparedValue[$productId] = $this->_getSolrDate($storeId, $value);
                         }
                     }
                 }
@@ -456,6 +457,7 @@ abstract class Enterprise_Search_Model_Adapter_Abstract
 
             // Preparing data for sorting field
             if ($attribute->getUsedForSortBy()) {
+                $sortValue = null;
                 if (is_array($preparedValue)) {
                     if (isset($preparedValue[$productId])) {
                         $sortValue = $preparedValue[$productId];
diff --git app/code/core/Enterprise/Search/Model/Adapter/Solr/Abstract.php app/code/core/Enterprise/Search/Model/Adapter/Solr/Abstract.php
index d028ba0..28cb238 100644
--- app/code/core/Enterprise/Search/Model/Adapter/Solr/Abstract.php
+++ app/code/core/Enterprise/Search/Model/Adapter/Solr/Abstract.php
@@ -373,8 +373,12 @@ abstract class Enterprise_Search_Model_Adapter_Solr_Abstract extends Enterprise_
 
         // Field type defining
         $attributeCode = $attribute->getAttributeCode();
-        if (in_array($attributeCode, array('sku'))) {
-            return $attributeCode;
+        if ($attributeCode == 'sku') {
+            if ($target == 'sort') {
+                return 'attr_sort_sku';
+            } else {
+                return 'sku';
+            }
         }
 
         if ($attributeCode == 'price') {
diff --git app/code/core/Enterprise/Search/Model/Adminhtml/System/Config/Backend/Engine.php app/code/core/Enterprise/Search/Model/Adminhtml/System/Config/Backend/Engine.php
index 8811e87..3b99f51 100644
--- app/code/core/Enterprise/Search/Model/Adminhtml/System/Config/Backend/Engine.php
+++ app/code/core/Enterprise/Search/Model/Adminhtml/System/Config/Backend/Engine.php
@@ -45,8 +45,7 @@ class Enterprise_Search_Model_Adminhtml_System_Config_Backend_Engine extends Mag
         parent::_afterSave();
 
         if ($this->isValueChanged()) {
-            Mage::getSingleton('index/indexer')->getProcessByCode('catalogsearch_fulltext')
-                ->changeStatus(Mage_Index_Model_Process::STATUS_REQUIRE_REINDEX);
+            Mage::helper('enterprise_search')->invalidateCatalogSearchIndex();
         }
 
         return $this;
diff --git app/code/core/Enterprise/Search/Model/Adminhtml/System/Config/Backend/Locale/Code.php app/code/core/Enterprise/Search/Model/Adminhtml/System/Config/Backend/Locale/Code.php
new file mode 100644
index 0000000..c4220b7
--- /dev/null
+++ app/code/core/Enterprise/Search/Model/Adminhtml/System/Config/Backend/Locale/Code.php
@@ -0,0 +1,64 @@
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
+ * @category    Enterprise
+ * @package     Enterprise_Search
+ * @copyright   Copyright (c) 2013 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://www.magentocommerce.com/license/enterprise-edition
+ */
+
+
+/**
+ * Locale code backend model
+ *
+ * @category    Enterprise
+ * @package     Enterprise_Search
+ * @author      Magento Core Team <core@magentocommerce.com>
+ */
+class Enterprise_Search_Model_Adminhtml_System_Config_Backend_Locale_Code extends Mage_Core_Model_Config_Data
+{
+    /**
+     * After save call
+     *
+     * @return Enterprise_Search_Model_Adminhtml_System_Config_Backend_Locale_Code
+     */
+    protected function _afterSave()
+    {
+        parent::_afterSave();
+        if ($this->isValueChanged()) {
+            Mage::helper('enterprise_search')->invalidateCatalogSearchIndex();
+        }
+
+        return $this;
+    }
+
+    /**
+     * After delete call, in case "Use Default" flag was set
+     *
+     * @return Enterprise_Search_Model_Adminhtml_System_Config_Backend_Locale_Code
+     */
+    protected function _afterDelete()
+    {
+        parent::_afterDelete();
+        Mage::helper('enterprise_search')->invalidateCatalogSearchIndex();
+
+        return $this;
+    }
+}
diff --git app/code/core/Enterprise/Search/Model/Catalog/Layer/Filter/Price.php app/code/core/Enterprise/Search/Model/Catalog/Layer/Filter/Price.php
index 5c5f9db..42592e8 100644
--- app/code/core/Enterprise/Search/Model/Catalog/Layer/Filter/Price.php
+++ app/code/core/Enterprise/Search/Model/Catalog/Layer/Filter/Price.php
@@ -187,15 +187,37 @@ class Enterprise_Search_Model_Catalog_Layer_Filter_Price extends Mage_Catalog_Mo
     }
 
     /**
+     * Prepare unique cache key
+     *
+     * @param string $cachePrefix
+     * @param array  $additionalParams
+     *
+     * @return string
+     */
+    protected function _getUniqueCacheKey($cachePrefix, array $additionalParams = array())
+    {
+        $uniqueParams = $this->getLayer()->getProductCollection()->getExtendedSearchParams();
+        $uniqueParams['currency_rate'] = $this->getCurrencyRate();
+        if (!empty($additionalParams)) {
+            $additionalParams = array_filter($additionalParams, 'strlen');
+            sort($additionalParams);
+            $uniqueParams = array_merge($uniqueParams, $additionalParams);
+        }
+        $uniqueParams = strtoupper(md5(serialize($uniqueParams)));
+
+        $cacheKey = $cachePrefix . '_' . $this->getLayer()->getStateKey() . '_' . $uniqueParams;
+
+        return $cacheKey;
+    }
+
+    /**
      * Get maximum price from layer products set using cache
      *
      * @return float
      */
     public function getMaxPriceInt()
     {
-        $searchParams = $this->getLayer()->getProductCollection()->getExtendedSearchParams();
-        $uniquePart = strtoupper(md5(serialize($searchParams . '_' . $this->getCurrencyRate())));
-        $cacheKey = 'MAXPRICE_' . $this->getLayer()->getStateKey() . '_' . $uniquePart;
+        $cacheKey = $this->_getUniqueCacheKey('MAXPRICE');
 
         $cachedData = Mage::app()->loadCache($cacheKey);
         if (!$cachedData) {
@@ -224,12 +246,9 @@ class Enterprise_Search_Model_Catalog_Layer_Filter_Price extends Mage_Catalog_Mo
      */
     protected function _getSeparators()
     {
-        $searchParams = $this->getLayer()->getProductCollection()->getExtendedSearchParams();
         $intervalParams = $this->getInterval();
-        $intervalParams = $intervalParams ? ($intervalParams[0] . '-' . $intervalParams[1]) : '';
-        $uniquePart = strtoupper(md5(serialize($searchParams . '_'
-            . $this->getCurrencyRate() . '_' . $intervalParams)));
-        $cacheKey = 'PRICE_SEPARATORS_' . $this->getLayer()->getStateKey() . '_' . $uniquePart;
+        $additionalParams = ($intervalParams) ? array($intervalParams[0] . '-' . $intervalParams[1]) : array();
+        $cacheKey = $this->_getUniqueCacheKey('PRICE_SEPARATORS', $additionalParams);
 
         $cachedData = Mage::app()->loadCache($cacheKey);
         if (!$cachedData) {
@@ -239,11 +258,11 @@ class Enterprise_Search_Model_Catalog_Layer_Filter_Price extends Mage_Catalog_Mo
             $statistics = $statistics[$this->_getFilterField()];
 
             $appliedInterval = $this->getInterval();
-            if (
-                $appliedInterval
+            if ($appliedInterval
                 && ($statistics['count'] <= $this->getIntervalDivisionLimit()
-                || $appliedInterval[0] == $appliedInterval[1]
-                || $appliedInterval[1] === '0')
+                    || $appliedInterval[0] == $appliedInterval[1]
+                    || $appliedInterval[1] === '0'
+                )
             ) {
                 $algorithmModel->setPricesModel($this)->setStatistics(0, 0, 0, 0);
                 $this->_divisible = false;
diff --git app/code/core/Enterprise/Search/Model/Observer.php app/code/core/Enterprise/Search/Model/Observer.php
index f6fe806..7194c69 100644
--- app/code/core/Enterprise/Search/Model/Observer.php
+++ app/code/core/Enterprise/Search/Model/Observer.php
@@ -100,8 +100,7 @@ class Enterprise_Search_Model_Observer
 
         $object = $observer->getEvent()->getDataObject();
         if ($object->isObjectNew() || $object->getTaxClassId() != $object->getOrigData('tax_class_id')) {
-            Mage::getSingleton('index/indexer')->getProcessByCode('catalogsearch_fulltext')
-                ->changeStatus(Mage_Index_Model_Process::STATUS_REQUIRE_REINDEX);
+            Mage::helper('enterprise_search')->invalidateCatalogSearchIndex();
         }
     }
 
@@ -303,6 +302,15 @@ class Enterprise_Search_Model_Observer
      */
     public function rebuiltIndex(Varien_Event_Observer $observer)
     {
-        $this->_getIndexer()->rebuildIndex(null, $observer->getEvent()->getProductIds())->resetSearchResults();
+        $affectedProductIds = $observer->getEvent()->getProductIds();
+        if (empty($affectedProductIds)) {
+            return;
+        }
+
+        if (!Mage::helper('enterprise_search')->isThirdPartyEngineAvailable()) {
+            return;
+        }
+
+        $this->_getIndexer()->rebuildIndex(null, $affectedProductIds)->resetSearchResults();
     }
 }
diff --git app/code/core/Enterprise/Search/etc/config.xml app/code/core/Enterprise/Search/etc/config.xml
index d53a837..cec6f60 100644
--- app/code/core/Enterprise/Search/etc/config.xml
+++ app/code/core/Enterprise/Search/etc/config.xml
@@ -102,6 +102,7 @@
                     </enterprise_search>
                 </observers>
             </catelogsearch_searchable_attributes_load_after>
+
             <catalog_category_product_partial_reindex>
                 <observers>
                     <enterprise_search>
@@ -110,6 +111,14 @@
                     </enterprise_search>
                 </observers>
             </catalog_category_product_partial_reindex>
+            <cataloginventory_stock_partial_reindex>
+                <observers>
+                    <enterprise_search>
+                        <class>enterprise_search/observer</class>
+                        <method>rebuiltIndex</method>
+                    </enterprise_search>
+                </observers>
+            </cataloginventory_stock_partial_reindex>
         </events>
     </global>
 
diff --git app/code/core/Enterprise/Search/etc/system.xml app/code/core/Enterprise/Search/etc/system.xml
index 4b8718c..b7b5005 100644
--- app/code/core/Enterprise/Search/etc/system.xml
+++ app/code/core/Enterprise/Search/etc/system.xml
@@ -26,7 +26,18 @@
  */
 -->
 <config>
-   <sections>
+    <sections>
+        <general>
+            <groups>
+                <locale>
+                    <fields>
+                        <code>
+                            <backend_model>enterprise_search/adminhtml_system_config_backend_locale_code</backend_model>
+                        </code>
+                    </fields>
+                </locale>
+            </groups>
+        </general>
         <catalog>
             <groups>
                 <search>
diff --git app/code/core/Mage/CatalogInventory/Model/Resource/Indexer/Stock/Default.php app/code/core/Mage/CatalogInventory/Model/Resource/Indexer/Stock/Default.php
index 097ed73..73fad6c 100755
--- app/code/core/Mage/CatalogInventory/Model/Resource/Indexer/Stock/Default.php
+++ app/code/core/Mage/CatalogInventory/Model/Resource/Indexer/Stock/Default.php
@@ -178,8 +178,8 @@ class Mage_CatalogInventory_Model_Resource_Indexer_Stock_Default
             ->where('e.type_id = ?', $this->getTypeId());
 
         // add limitation of status
-        $condition = $adapter->quoteInto('=?', Mage_Catalog_Model_Product_Status::STATUS_ENABLED);
-        $this->_addAttributeToSelect($select, 'status', 'e.entity_id', 'cs.store_id', $condition);
+        $psExpr = $this->_addAttributeToSelect($select, 'status', 'e.entity_id', 'cs.store_id');
+        $psCondition = $adapter->quoteInto($psExpr . '=?', Mage_Catalog_Model_Product_Status::STATUS_ENABLED);
 
         if ($this->_isManageStock()) {
             $statusExpr = $adapter->getCheckSql('cisi.use_config_manage_stock = 0 AND cisi.manage_stock = 0',
@@ -189,7 +189,10 @@ class Mage_CatalogInventory_Model_Resource_Indexer_Stock_Default
                 'cisi.is_in_stock', 1);
         }
 
-        $select->columns(array('status' => $statusExpr));
+        $optExpr = $adapter->getCheckSql($psCondition, 1, 0);
+        $stockStatusExpr = $adapter->getLeastSql(array($optExpr, $statusExpr));
+
+        $select->columns(array('status' => $stockStatusExpr));
 
         if (!is_null($entityIds)) {
             $select->where('e.entity_id IN(?)', $entityIds);
diff --git app/code/core/Mage/CatalogInventory/etc/config.xml app/code/core/Mage/CatalogInventory/etc/config.xml
index 381f58b..2cb62d2 100644
--- app/code/core/Mage/CatalogInventory/etc/config.xml
+++ app/code/core/Mage/CatalogInventory/etc/config.xml
@@ -230,6 +230,14 @@
                     </cataloginventory>
                 </observers>
             </end_process_event_cataloginventory_stock_item_save>
+            <prepare_product_children_id_list_select>
+                <observers>
+                    <cataloginventory>
+                        <class>cataloginventory/observer</class>
+                        <method>prepareCatalogProductIndexSelect</method>
+                    </cataloginventory>
+                </observers>
+            </prepare_product_children_id_list_select>
         </events>
         <catalog>
             <product>
diff --git app/code/core/Mage/CatalogSearch/Model/Advanced.php app/code/core/Mage/CatalogSearch/Model/Advanced.php
index f1c9715..f784e6c 100644
--- app/code/core/Mage/CatalogSearch/Model/Advanced.php
+++ app/code/core/Mage/CatalogSearch/Model/Advanced.php
@@ -163,6 +163,9 @@ class Mage_CatalogSearch_Model_Advanced extends Mage_Core_Model_Abstract
                 continue;
             }
             $value = $values[$attribute->getAttributeCode()];
+            if (!is_array($value)) {
+                $value = trim($value);
+            }
 
             if ($attribute->getAttributeCode() == 'price') {
                 $value['from'] = isset($value['from']) ? trim($value['from']) : '';
diff --git app/code/core/Mage/CatalogSearch/Model/Resource/Fulltext.php app/code/core/Mage/CatalogSearch/Model/Resource/Fulltext.php
index 309181e..abee25c 100755
--- app/code/core/Mage/CatalogSearch/Model/Resource/Fulltext.php
+++ app/code/core/Mage/CatalogSearch/Model/Resource/Fulltext.php
@@ -152,6 +152,7 @@ class Mage_CatalogSearch_Model_Resource_Fulltext extends Mage_Core_Model_Resourc
         $statusVals     = Mage::getSingleton('catalog/product_status')->getVisibleStatusIds();
         $allowedVisibilityValues = $this->_engine->getAllowedVisibility();
 
+        $websiteId = Mage::app()->getStore($storeId)->getWebsite()->getId();
         $lastProductId = 0;
         while (true) {
             $products = $this->_getSearchableProducts($storeId, $staticFields, $productIds, $lastProductId);
@@ -164,7 +165,8 @@ class Mage_CatalogSearch_Model_Resource_Fulltext extends Mage_Core_Model_Resourc
             foreach ($products as $productData) {
                 $lastProductId = $productData['entity_id'];
                 $productAttributes[$productData['entity_id']] = $productData['entity_id'];
-                $productChildren = $this->_getProductChildIds($productData['entity_id'], $productData['type_id']);
+                $productChildren = $this->_getProductChildrenIds($productData['entity_id'], $productData['type_id'],
+                    $websiteId);
                 $productRelations[$productData['entity_id']] = $productChildren;
                 if ($productChildren) {
                     foreach ($productChildren as $productChildId) {
@@ -540,14 +542,15 @@ class Mage_CatalogSearch_Model_Resource_Fulltext extends Mage_Core_Model_Resourc
         return $this->_productTypes[$typeId];
     }
 
-    /**
+/**
      * Return all product children ids
      *
-     * @param int $productId Product Entity Id
-     * @param string $typeId Super Product Link Type
-     * @return array
+     * @param $productId
+     * @param $typeId
+     * @param null|int $websiteId
+     * @return array|null
      */
-    protected function _getProductChildIds($productId, $typeId)
+    protected function _getProductChildrenIds($productId, $typeId, $websiteId = null)
     {
         $typeInstance = $this->_getProductTypeInstance($typeId);
         $relation = $typeInstance->isComposite()
@@ -559,10 +562,17 @@ class Mage_CatalogSearch_Model_Resource_Fulltext extends Mage_Core_Model_Resourc
                 ->from(
                     array('main' => $this->getTable($relation->getTable())),
                     array($relation->getChildFieldName()))
-                ->where("{$relation->getParentFieldName()}=?", $productId);
+                ->where("main.{$relation->getParentFieldName()} = ?", $productId);
             if (!is_null($relation->getWhere())) {
                 $select->where($relation->getWhere());
             }
+
+            Mage::dispatchEvent('prepare_product_children_id_list_select', array(
+                'select'        => $select,
+                'entity_field'  => 'main.product_id',
+                'website_field' => $websiteId
+            ));
+
             return $this->_getReadAdapter()->fetchCol($select);
         }
 
@@ -570,6 +580,18 @@ class Mage_CatalogSearch_Model_Resource_Fulltext extends Mage_Core_Model_Resourc
     }
 
     /**
+     * Return all product children ids
+     *
+     * @param int $productId Product Entity Id
+     * @param string $typeId Super Product Link Type
+     * @return array|null
+     */
+    protected function _getProductChildIds($productId, $typeId)
+    {
+        return $this->_getProductChildrenIds($productId, $typeId);
+    }
+
+    /**
      * Retrieve Product Emulator (Varien Object)
      *
      * @return Varien_Object
diff --git lib/Apache/Solr/conf/schema.xml lib/Apache/Solr/conf/schema.xml
index d5377ff..ab3cc24 100644
--- lib/Apache/Solr/conf/schema.xml
+++ lib/Apache/Solr/conf/schema.xml
@@ -347,7 +347,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_en.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0" splitOnCaseChange="1"/>
+                        catenateWords="1" catenateNumbers="1" catenateAll="1"
+                        splitOnCaseChange="1" splitOnNumerics="0" preserveOriginal="1" stemEnglishPossessive="1"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="English" protected="protwords_en.txt"/>
             </analyzer>
@@ -358,7 +359,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_en.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="0" catenateNumbers="0" catenateAll="0" splitOnCaseChange="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"
+                        splitOnCaseChange="1" splitOnNumerics="0" stemEnglishPossessive="1"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="English" protected="protwords_en.txt"/>
             </analyzer>
@@ -366,6 +368,21 @@
 
 
         <!--
+            Less flexible matching, but less false matches.  Probably not ideal for product names,
+            but may be good for SKUs.  Can insert dashes and dots in the wrong place and still match.
+        -->
+        <fieldType name="textTight" class="solr.TextField" positionIncrementGap="100">
+            <analyzer>
+                <tokenizer class="solr.WhitespaceTokenizerFactory"/>
+                <charFilter class="solr.MappingCharFilterFactory" mapping="mapping-ISOLatin1Accent.txt"/>
+                <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
+                        catenateWords="1" catenateNumbers="1" catenateAll="1" preserveOriginal="1"/>
+                <filter class="solr.LowerCaseFilterFactory"/>
+                <filter class="solr.RemoveDuplicatesTokenFilterFactory"/>
+            </analyzer>
+        </fieldType>
+
+        <!--
             Less flexible matching, but less false matches.
             Probably not ideal for product names, but may be good for SKUs.
             Can insert dashes in the wrong place and still match.
@@ -415,7 +432,7 @@
                 <filter class="solr.SynonymFilterFactory" synonyms="synonyms_en.txt" ignoreCase="true" expand="false"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_en.txt"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="0" generateNumberParts="0"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0" stemEnglishPossessive="1" />
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <!--
                     This filter can remove any duplicate tokens that appear at the same position - sometimes possible
@@ -435,7 +452,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_fr.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0" splitOnCaseChange="1"/>
+                        catenateWords="1" catenateNumbers="1" catenateAll="1"
+                        splitOnCaseChange="1" splitOnNumerics="0" preserveOriginal="1"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="French" protected="protwords_fr.txt"/>
             </analyzer>
@@ -446,7 +464,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_fr.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="0" catenateNumbers="0" catenateAll="0" splitOnCaseChange="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"
+                        splitOnCaseChange="1" splitOnNumerics="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="French" protected="protwords_fr.txt"/>
             </analyzer>
@@ -479,7 +498,7 @@
                 <filter class="solr.SynonymFilterFactory" synonyms="synonyms_fr.txt" ignoreCase="true" expand="false"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_fr.txt"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="0" generateNumberParts="0"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.RemoveDuplicatesTokenFilterFactory"/>
             </analyzer>
@@ -495,7 +514,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_de.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0" splitOnCaseChange="1"/>
+                        catenateWords="1" catenateNumbers="1" catenateAll="1"
+                        splitOnCaseChange="1" splitOnNumerics="0" preserveOriginal="1"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="German" protected="protwords_de.txt"/>
             </analyzer>
@@ -506,7 +526,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_de.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="0" catenateNumbers="0" catenateAll="0" splitOnCaseChange="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"
+                        splitOnCaseChange="1" splitOnNumerics="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="German" protected="protwords_de.txt"/>
             </analyzer>
@@ -539,7 +560,7 @@
                 <filter class="solr.SynonymFilterFactory" synonyms="synonyms_de.txt" ignoreCase="true" expand="false"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_de.txt"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="0" generateNumberParts="0"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.RemoveDuplicatesTokenFilterFactory"/>
             </analyzer>
@@ -555,7 +576,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_da.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0" splitOnCaseChange="1"/>
+                        catenateWords="1" catenateNumbers="1" catenateAll="1"
+                        splitOnCaseChange="1" splitOnNumerics="0" preserveOriginal="1"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="Danish" protected="protwords_da.txt"/>
             </analyzer>
@@ -566,7 +588,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_da.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="0" catenateNumbers="0" catenateAll="0" splitOnCaseChange="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"
+                        splitOnCaseChange="1" splitOnNumerics="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="Danish" protected="protwords_de.txt"/>
             </analyzer>
@@ -599,7 +622,7 @@
                 <filter class="solr.SynonymFilterFactory" synonyms="synonyms_da.txt" ignoreCase="true" expand="false"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_da.txt"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="0" generateNumberParts="0"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.RemoveDuplicatesTokenFilterFactory"/>
             </analyzer>
@@ -615,7 +638,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_nl.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0" splitOnCaseChange="1"/>
+                        catenateWords="1" catenateNumbers="1" catenateAll="1"
+                        splitOnCaseChange="1" splitOnNumerics="0" preserveOriginal="1"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="Dutch" protected="protwords_nl.txt"/>
             </analyzer>
@@ -626,7 +650,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_nl.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="0" catenateNumbers="0" catenateAll="0" splitOnCaseChange="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"
+                        splitOnCaseChange="1" splitOnNumerics="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="Dutch" protected="protwords_nl.txt"/>
             </analyzer>
@@ -659,7 +684,7 @@
                 <filter class="solr.SynonymFilterFactory" synonyms="synonyms_nl.txt" ignoreCase="true" expand="false"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_nl.txt"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="0" generateNumberParts="0"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.RemoveDuplicatesTokenFilterFactory"/>
             </analyzer>
@@ -675,7 +700,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_fi.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0" splitOnCaseChange="1"/>
+                        catenateWords="1" catenateNumbers="1" catenateAll="1"
+                        splitOnCaseChange="1" splitOnNumerics="0" preserveOriginal="1"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="Finnish" protected="protwords_fi.txt"/>
             </analyzer>
@@ -686,7 +712,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_fi.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="0" catenateNumbers="0" catenateAll="0" splitOnCaseChange="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"
+                        splitOnCaseChange="1" splitOnNumerics="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="Finnish" protected="protwords_fi.txt"/>
             </analyzer>
@@ -719,7 +746,7 @@
                 <filter class="solr.SynonymFilterFactory" synonyms="synonyms_fi.txt" ignoreCase="true" expand="false"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_fi.txt"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="0" generateNumberParts="0"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.RemoveDuplicatesTokenFilterFactory"/>
             </analyzer>
@@ -735,7 +762,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_it.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0" splitOnCaseChange="1"/>
+                        catenateWords="1" catenateNumbers="1" catenateAll="1"
+                        splitOnCaseChange="1" splitOnNumerics="0" preserveOriginal="1"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="Italian" protected="protwords_it.txt"/>
             </analyzer>
@@ -746,7 +774,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_it.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="0" catenateNumbers="0" catenateAll="0" splitOnCaseChange="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"
+                        splitOnCaseChange="1" splitOnNumerics="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="Italian" protected="protwords_it.txt"/>
             </analyzer>
@@ -779,7 +808,7 @@
                 <filter class="solr.SynonymFilterFactory" synonyms="synonyms_it.txt" ignoreCase="true" expand="false"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_it.txt"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="0" generateNumberParts="0"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.RemoveDuplicatesTokenFilterFactory"/>
             </analyzer>
@@ -795,7 +824,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_nb.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0" splitOnCaseChange="1"/>
+                        catenateWords="1" catenateNumbers="1" catenateAll="1"
+                        splitOnCaseChange="1" splitOnNumerics="0" preserveOriginal="1"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="Norwegian" protected="protwords_nb.txt"/>
             </analyzer>
@@ -806,7 +836,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_nb.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="0" catenateNumbers="0" catenateAll="0" splitOnCaseChange="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"
+                        splitOnCaseChange="1" splitOnNumerics="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="Norwegian" protected="protwords_nb.txt"/>
             </analyzer>
@@ -839,7 +870,7 @@
                 <filter class="solr.SynonymFilterFactory" synonyms="synonyms_nb.txt" ignoreCase="true" expand="false"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_nb.txt"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="0" generateNumberParts="0"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.RemoveDuplicatesTokenFilterFactory"/>
             </analyzer>
@@ -855,7 +886,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_pt.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0" splitOnCaseChange="1"/>
+                        catenateWords="1" catenateNumbers="1" catenateAll="1"
+                        splitOnCaseChange="1" splitOnNumerics="0" preserveOriginal="1"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="Portuguese" protected="protwords_pt.txt"/>
             </analyzer>
@@ -866,7 +898,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_pt.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="0" catenateNumbers="0" catenateAll="0" splitOnCaseChange="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"
+                        splitOnCaseChange="1" splitOnNumerics="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="Portuguese" protected="protwords_pt.txt"/>
             </analyzer>
@@ -899,7 +932,7 @@
                 <filter class="solr.SynonymFilterFactory" synonyms="synonyms_pt.txt" ignoreCase="true" expand="false"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_pt.txt"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="0" generateNumberParts="0"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.RemoveDuplicatesTokenFilterFactory"/>
             </analyzer>
@@ -915,7 +948,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_ro.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0" splitOnCaseChange="1"/>
+                        catenateWords="1" catenateNumbers="1" catenateAll="1"
+                        splitOnCaseChange="1" splitOnNumerics="0" preserveOriginal="1"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="Romanian" protected="protwords_ro.txt"/>
             </analyzer>
@@ -926,7 +960,7 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_ro.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="0" catenateNumbers="0" catenateAll="0" splitOnCaseChange="0"/>
+                        catenateAll="1" splitOnCaseChange="0" splitOnNumerics="0" preserveOriginal="1" />
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="Romanian" protected="protwords_ro.txt"/>
             </analyzer>
@@ -937,8 +971,9 @@
                 <tokenizer class="solr.WhitespaceTokenizerFactory"/>
                 <filter class="solr.SynonymFilterFactory" synonyms="synonyms_ro.txt" ignoreCase="true" expand="false"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_ro.txt"/>
-                <filter class="solr.WordDelimiterFilterFactory" generateWordParts="0" generateNumberParts="0"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0"/>
+                <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"
+                        splitOnCaseChange="1" splitOnNumerics="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="Romanian" protected="protwords_ro.txt"/>
                 <filter class="solr.RemoveDuplicatesTokenFilterFactory"/>
@@ -959,7 +994,7 @@
                 <filter class="solr.SynonymFilterFactory" synonyms="synonyms_ro.txt" ignoreCase="true" expand="false"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_ro.txt"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="0" generateNumberParts="0"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.RemoveDuplicatesTokenFilterFactory"/>
             </analyzer>
@@ -975,7 +1010,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_ru.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0" splitOnCaseChange="1"/>
+                        catenateWords="1" catenateNumbers="1" catenateAll="1"
+                        splitOnCaseChange="1" splitOnNumerics="0" preserveOriginal="1"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="Russian" protected="protwords_ru.txt"/>
             </analyzer>
@@ -986,7 +1022,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_ru.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="0" catenateNumbers="0" catenateAll="0" splitOnCaseChange="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"
+                        splitOnCaseChange="1" splitOnNumerics="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="Russian" protected="protwords_ru.txt"/>
             </analyzer>
@@ -1019,7 +1056,7 @@
                 <filter class="solr.SynonymFilterFactory" synonyms="synonyms_ru.txt" ignoreCase="true" expand="false"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_ru.txt"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="0" generateNumberParts="0"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.RemoveDuplicatesTokenFilterFactory"/>
             </analyzer>
@@ -1035,7 +1072,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_es.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0" splitOnCaseChange="1"/>
+                        catenateWords="1" catenateNumbers="1" catenateAll="1"
+                        splitOnCaseChange="1" splitOnNumerics="0" preserveOriginal="1"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="Spanish" protected="protwords_es.txt"/>
             </analyzer>
@@ -1046,7 +1084,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_es.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="0" catenateNumbers="0" catenateAll="0" splitOnCaseChange="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"
+                        splitOnCaseChange="1" splitOnNumerics="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="Spanish" protected="protwords_es.txt"/>
             </analyzer>
@@ -1079,7 +1118,7 @@
                 <filter class="solr.SynonymFilterFactory" synonyms="synonyms_es.txt" ignoreCase="true" expand="false"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_es.txt"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="0" generateNumberParts="0"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.RemoveDuplicatesTokenFilterFactory"/>
             </analyzer>
@@ -1095,7 +1134,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_sv.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0" splitOnCaseChange="1"/>
+                        catenateWords="1" catenateNumbers="1" catenateAll="1"
+                        splitOnCaseChange="1" splitOnNumerics="0" preserveOriginal="1"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="Swedish" protected="protwords_sv.txt"/>
             </analyzer>
@@ -1106,7 +1146,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_sv.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="0" catenateNumbers="0" catenateAll="0" splitOnCaseChange="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"
+                        splitOnCaseChange="1" splitOnNumerics="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="Swedish" protected="protwords_sv.txt"/>
             </analyzer>
@@ -1139,7 +1180,7 @@
                 <filter class="solr.SynonymFilterFactory" synonyms="synonyms_sv.txt" ignoreCase="true" expand="false"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_sv.txt"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="0" generateNumberParts="0"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.RemoveDuplicatesTokenFilterFactory"/>
             </analyzer>
@@ -1155,7 +1196,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_tr.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0" splitOnCaseChange="1"/>
+                        catenateWords="1" catenateNumbers="1" catenateAll="1"
+                        splitOnCaseChange="1" splitOnNumerics="0" preserveOriginal="1"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="Turkish" protected="protwords_tr.txt"/>
             </analyzer>
@@ -1166,7 +1208,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_tr.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="0" catenateNumbers="0" catenateAll="0" splitOnCaseChange="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"
+                        splitOnCaseChange="1" splitOnNumerics="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.SnowballPorterFilterFactory" language="Turkish" protected="protwords_tr.txt"/>
             </analyzer>
@@ -1199,7 +1242,7 @@
                 <filter class="solr.SynonymFilterFactory" synonyms="synonyms_tr.txt" ignoreCase="true" expand="false"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_tr.txt"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="0" generateNumberParts="0"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.RemoveDuplicatesTokenFilterFactory"/>
             </analyzer>
@@ -1215,7 +1258,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_cs.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0" splitOnCaseChange="1"/>
+                        catenateWords="1" catenateNumbers="1" catenateAll="1"
+                        splitOnCaseChange="1" splitOnNumerics="0" preserveOriginal="1"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
             </analyzer>
             <analyzer type="query" class="org.apache.lucene.analysis.cz.CzechAnalyzer">
@@ -1225,7 +1269,7 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_cs.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="0" catenateNumbers="0" catenateAll="0" splitOnCaseChange="0"/>
+                        catenateAll="1" splitOnCaseChange="0" splitOnNumerics="0" preserveOriginal="1" />
                 <filter class="solr.LowerCaseFilterFactory"/>
             </analyzer>
         </fieldType>
@@ -1235,8 +1279,9 @@
                 <tokenizer class="solr.WhitespaceTokenizerFactory"/>
                 <filter class="solr.SynonymFilterFactory" synonyms="synonyms_cs.txt" ignoreCase="true" expand="false"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_cs.txt"/>
-                <filter class="solr.WordDelimiterFilterFactory" generateWordParts="0" generateNumberParts="0"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0"/>
+                <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"
+                        splitOnCaseChange="1" splitOnNumerics="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.RemoveDuplicatesTokenFilterFactory"/>
             </analyzer>
@@ -1256,7 +1301,7 @@
                 <filter class="solr.SynonymFilterFactory" synonyms="synonyms_cs.txt" ignoreCase="true" expand="false"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_cs.txt"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="0" generateNumberParts="0"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.RemoveDuplicatesTokenFilterFactory"/>
             </analyzer>
@@ -1272,7 +1317,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_el.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0" splitOnCaseChange="1"/>
+                        catenateWords="1" catenateNumbers="1" catenateAll="1"
+                        splitOnCaseChange="1" splitOnNumerics="0" preserveOriginal="1"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
             </analyzer>
             <analyzer type="query" class="org.apache.lucene.analysis.el.GreekAnalyzer">
@@ -1282,7 +1328,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_el.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="0" catenateNumbers="0" catenateAll="0" splitOnCaseChange="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"
+                        splitOnCaseChange="1" splitOnNumerics="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
             </analyzer>
         </fieldType>
@@ -1313,7 +1360,7 @@
                 <filter class="solr.SynonymFilterFactory" synonyms="synonyms_el.txt" ignoreCase="true" expand="false"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_el.txt"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="0" generateNumberParts="0"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.RemoveDuplicatesTokenFilterFactory"/>
             </analyzer>
@@ -1329,7 +1376,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_th.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0" splitOnCaseChange="1"/>
+                        catenateWords="1" catenateNumbers="1" catenateAll="1"
+                        splitOnCaseChange="1" splitOnNumerics="0" preserveOriginal="1"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
             </analyzer>
             <analyzer type="query" class="org.apache.lucene.analysis.th.ThaiAnalyzer">
@@ -1339,7 +1387,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_th.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="0" catenateNumbers="0" catenateAll="0" splitOnCaseChange="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"
+                        splitOnCaseChange="1" splitOnNumerics="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
             </analyzer>
         </fieldType>
@@ -1370,7 +1419,7 @@
                 <filter class="solr.SynonymFilterFactory" synonyms="synonyms_th.txt" ignoreCase="true" expand="false"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_th.txt"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="0" generateNumberParts="0"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.RemoveDuplicatesTokenFilterFactory"/>
             </analyzer>
@@ -1380,29 +1429,31 @@
         CHINESE LANGUAGE
         -->
         <fieldType name="text_zh" class="solr.TextField">
-            <analyzer type="index" class="org.apache.lucene.analysis.cn.ChineseAnalyzer">
+            <analyzer type="index" class="org.apache.lucene.analysis.cjk.CJKAnalyzer">
                 <tokenizer class="solr.WhitespaceTokenizerFactory"/>
                 <charFilter class="solr.MappingCharFilterFactory" mapping="mapping-ISOLatin1Accent.txt"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_zh.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0" splitOnCaseChange="1"/>
+                        catenateWords="1" catenateNumbers="1" catenateAll="1"
+                        splitOnCaseChange="1" splitOnNumerics="0" preserveOriginal="1"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
             </analyzer>
-            <analyzer type="query" class="org.apache.lucene.analysis.cn.ChineseAnalyzer">
+            <analyzer type="query" class="org.apache.lucene.analysis.cjk.CJKAnalyzer">
                 <tokenizer class="solr.WhitespaceTokenizerFactory"/>
                 <charFilter class="solr.MappingCharFilterFactory" mapping="mapping-ISOLatin1Accent.txt"/>
                 <filter class="solr.SynonymFilterFactory" synonyms="synonyms_zh.txt" ignoreCase="true" expand="true"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_zh.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="0" catenateNumbers="0" catenateAll="0" splitOnCaseChange="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"
+                        splitOnCaseChange="1" splitOnNumerics="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
             </analyzer>
         </fieldType>
 
         <fieldType name="textTight_zh" class="solr.TextField">
-            <analyzer class="org.apache.lucene.analysis.cn.ChineseAnalyzer">
+            <analyzer class="org.apache.lucene.analysis.cjk.CJKAnalyzer">
                 <tokenizer class="solr.WhitespaceTokenizerFactory"/>
                 <filter class="solr.SynonymFilterFactory" synonyms="synonyms_zh.txt" ignoreCase="true" expand="false"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_zh.txt"/>
@@ -1414,7 +1465,7 @@
         </fieldType>
 
         <fieldType name="alphaOnlySort_zh" class="solr.TextField" sortMissingLast="true" omitNorms="true">
-            <analyzer class="org.apache.lucene.analysis.cn.ChineseAnalyzer">
+            <analyzer class="org.apache.lucene.analysis.cjk.CJKAnalyzer">
                 <tokenizer class="solr.KeywordTokenizerFactory"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.TrimFilterFactory"/>
@@ -1422,12 +1473,12 @@
         </fieldType>
 
         <fieldType name="textSpell_zh" class="solr.TextField">
-            <analyzer class="org.apache.lucene.analysis.cn.ChineseAnalyzer">
+            <analyzer class="org.apache.lucene.analysis.cjk.CJKAnalyzer">
                 <tokenizer class="solr.WhitespaceTokenizerFactory"/>
                 <filter class="solr.SynonymFilterFactory" synonyms="synonyms_zh.txt" ignoreCase="true" expand="false"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_zh.txt"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="0" generateNumberParts="0"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.RemoveDuplicatesTokenFilterFactory"/>
             </analyzer>
@@ -1443,7 +1494,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_ja.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0" splitOnCaseChange="1"/>
+                        catenateWords="1" catenateNumbers="1" catenateAll="1"
+                        splitOnCaseChange="1" splitOnNumerics="0" preserveOriginal="1"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
             </analyzer>
             <analyzer type="query">
@@ -1453,7 +1505,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_ja.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="0" catenateNumbers="0" catenateAll="0" splitOnCaseChange="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"
+                        splitOnCaseChange="1" splitOnNumerics="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
             </analyzer>
         </fieldType>
@@ -1484,7 +1537,7 @@
                 <filter class="solr.SynonymFilterFactory" synonyms="synonyms_ja.txt" ignoreCase="true" expand="false"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_ja.txt"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="0" generateNumberParts="0"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.RemoveDuplicatesTokenFilterFactory"/>
             </analyzer>
@@ -1500,7 +1553,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_ko.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0" splitOnCaseChange="1"/>
+                        catenateWords="1" catenateNumbers="1" catenateAll="1"
+                        splitOnCaseChange="1" splitOnNumerics="0" preserveOriginal="1"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
             </analyzer>
             <analyzer type="query">
@@ -1510,7 +1564,8 @@
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_ko.txt"
                         enablePositionIncrements="true"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="1" generateNumberParts="1"
-                        catenateWords="0" catenateNumbers="0" catenateAll="0" splitOnCaseChange="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"
+                        splitOnCaseChange="1" splitOnNumerics="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
             </analyzer>
         </fieldType>
@@ -1541,7 +1596,7 @@
                 <filter class="solr.SynonymFilterFactory" synonyms="synonyms_ko.txt" ignoreCase="true" expand="false"/>
                 <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords_ko.txt"/>
                 <filter class="solr.WordDelimiterFilterFactory" generateWordParts="0" generateNumberParts="0"
-                        catenateWords="1" catenateNumbers="1" catenateAll="0"/>
+                        catenateWords="0" catenateNumbers="0" catenateAll="0"/>
                 <filter class="solr.LowerCaseFilterFactory"/>
                 <filter class="solr.RemoveDuplicatesTokenFilterFactory"/>
             </analyzer>
@@ -1603,7 +1658,11 @@
         <field name="timestamp"     type="date" indexed="true" multiValued="false" default="NOW"/>
 
         <!-- Static type attribute fields. -->
-        <field name="sku"   type="textTight_en" indexed="true" omitNorms="true"/>
+        <field name="sku"           type="textTight" indexed="true" omitNorms="true"/>
+
+        <!-- Field to sort by SKU -->
+        <field name="attr_sort_sku" type="string"   indexed="true" stored="false"/>
+        <copyField source="sku" dest="attr_sort_sku"/>
 
         <!--
             Dynamic fields definitions. If a field name is not found, dynamicFields will be used if the name matches any
