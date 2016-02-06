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


SUPEE-3630_1.13.1.0 | EE_1.13.1.0 | v2 | 04d0c8c52e9c098c94e5021223df2e1a666ae4d9 | Tue Feb 17 16:50:24 2015 -0800 | v1.13.1.0..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Enterprise/CatalogSearch/Model/Index/Action/Fulltext/Refresh.php app/code/core/Enterprise/CatalogSearch/Model/Index/Action/Fulltext/Refresh.php
index e684006..c7e05bc 100644
--- app/code/core/Enterprise/CatalogSearch/Model/Index/Action/Fulltext/Refresh.php
+++ app/code/core/Enterprise/CatalogSearch/Model/Index/Action/Fulltext/Refresh.php
@@ -649,10 +649,6 @@ class Enterprise_CatalogSearch_Model_Index_Action_Fulltext_Refresh
      */
     protected function _resetSearchResults()
     {
-        $adapter = $this->_getWriteAdapter();
-        $adapter->update($this->_getTable('catalogsearch/search_query'), array('is_processed' => 0));
-        $adapter->delete($this->_getTable('catalogsearch/result'));
-
         $this->_app->dispatchEvent('enterprise_catalogsearch_reset_search_result', array());
     }
 
diff --git app/code/core/Mage/CatalogSearch/Model/Resource/Fulltext.php app/code/core/Mage/CatalogSearch/Model/Resource/Fulltext.php
index 309181e..351c5e9 100755
--- app/code/core/Mage/CatalogSearch/Model/Resource/Fulltext.php
+++ app/code/core/Mage/CatalogSearch/Model/Resource/Fulltext.php
@@ -77,9 +77,10 @@ class Mage_CatalogSearch_Model_Resource_Fulltext extends Mage_Core_Model_Resourc
      */
     protected $_allowTableChanges       = true;
 
-
-
-
+    /**
+     * @var array
+     */
+    protected $_foundData = array();
 
     /**
      * Init resource model
@@ -274,12 +275,7 @@ class Mage_CatalogSearch_Model_Resource_Fulltext extends Mage_Core_Model_Resourc
      */
     public function resetSearchResults()
     {
-        $adapter = $this->_getWriteAdapter();
-        $adapter->update($this->getTable('catalogsearch/search_query'), array('is_processed' => 0));
-        $adapter->delete($this->getTable('catalogsearch/result'));
-
         Mage::dispatchEvent('catalogsearch_reset_search_result');
-
         return $this;
     }
 
@@ -310,71 +306,74 @@ class Mage_CatalogSearch_Model_Resource_Fulltext extends Mage_Core_Model_Resourc
     public function prepareResult($object, $queryText, $query)
     {
         $adapter = $this->_getWriteAdapter();
-        if (!$query->getIsProcessed()) {
-            $searchType = $object->getSearchType($query->getStoreId());
-
-            $preparedTerms = Mage::getResourceHelper('catalogsearch')
-                ->prepareTerms($queryText, $query->getMaxQueryWords());
-
-            $bind = array();
-            $like = array();
-            $likeCond  = '';
-            if ($searchType == Mage_CatalogSearch_Model_Fulltext::SEARCH_TYPE_LIKE
-                || $searchType == Mage_CatalogSearch_Model_Fulltext::SEARCH_TYPE_COMBINE
-            ) {
-                $helper = Mage::getResourceHelper('core');
-                $words = Mage::helper('core/string')->splitWords($queryText, true, $query->getMaxQueryWords());
-                foreach ($words as $word) {
-                    $like[] = $helper->getCILike('s.data_index', $word, array('position' => 'any'));
-                }
-                if ($like) {
-                    $likeCond = '(' . join(' OR ', $like) . ')';
-                }
-            }
-            $mainTableAlias = 's';
-            $fields = array(
-                'query_id' => new Zend_Db_Expr($query->getId()),
-                'product_id',
-            );
-            $select = $adapter->select()
-                ->from(array($mainTableAlias => $this->getMainTable()), $fields)
-                ->joinInner(array('e' => $this->getTable('catalog/product')),
-                    'e.entity_id = s.product_id',
-                    array())
-                ->where($mainTableAlias.'.store_id = ?', (int)$query->getStoreId());
-
-            if ($searchType == Mage_CatalogSearch_Model_Fulltext::SEARCH_TYPE_FULLTEXT
-                || $searchType == Mage_CatalogSearch_Model_Fulltext::SEARCH_TYPE_COMBINE
-            ) {
-                $bind[':query'] = implode(' ', $preparedTerms[0]);
-                $where = Mage::getResourceHelper('catalogsearch')
-                    ->chooseFulltext($this->getMainTable(), $mainTableAlias, $select);
-            }
 
-            if ($likeCond != '' && $searchType == Mage_CatalogSearch_Model_Fulltext::SEARCH_TYPE_COMBINE) {
-                    $where .= ($where ? ' OR ' : '') . $likeCond;
-            } elseif ($likeCond != '' && $searchType == Mage_CatalogSearch_Model_Fulltext::SEARCH_TYPE_LIKE) {
-                $select->columns(array('relevance'  => new Zend_Db_Expr(0)));
-                $where = $likeCond;
+        $searchType = $object->getSearchType($query->getStoreId());
+
+        $preparedTerms = Mage::getResourceHelper('catalogsearch')
+            ->prepareTerms($queryText, $query->getMaxQueryWords());
+
+        $bind = array();
+        $like = array();
+        $likeCond  = '';
+        if ($searchType == Mage_CatalogSearch_Model_Fulltext::SEARCH_TYPE_LIKE
+            || $searchType == Mage_CatalogSearch_Model_Fulltext::SEARCH_TYPE_COMBINE
+        ) {
+            $helper = Mage::getResourceHelper('core');
+            $words = Mage::helper('core/string')->splitWords($queryText, true, $query->getMaxQueryWords());
+            foreach ($words as $word) {
+                $like[] = $helper->getCILike('s.data_index', $word, array('position' => 'any'));
             }
-
-            if ($where != '') {
-                $select->where($where);
+            if ($like) {
+                $likeCond = '(' . join(' OR ', $like) . ')';
             }
+        }
 
-            $sql = $adapter->insertFromSelect($select,
-                $this->getTable('catalogsearch/result'),
-                array(),
-                Varien_Db_Adapter_Interface::INSERT_ON_DUPLICATE);
-            $adapter->query($sql, $bind);
+        $mainTableAlias = 's';
+        $fields = array('product_id');
+
+        $select = $adapter->select()
+            ->from(array($mainTableAlias => $this->getMainTable()), $fields)
+            ->joinInner(array('e' => $this->getTable('catalog/product')),
+                'e.entity_id = s.product_id',
+                array())
+            ->where($mainTableAlias.'.store_id = ?', (int)$query->getStoreId());
+
+        if ($searchType == Mage_CatalogSearch_Model_Fulltext::SEARCH_TYPE_FULLTEXT
+            || $searchType == Mage_CatalogSearch_Model_Fulltext::SEARCH_TYPE_COMBINE
+        ) {
+            $bind[':query'] = implode(' ', $preparedTerms[0]);
+            $where = Mage::getResourceHelper('catalogsearch')
+                ->chooseFulltext($this->getMainTable(), $mainTableAlias, $select);
+        }
 
-            $query->setIsProcessed(1);
+        if ($likeCond != '' && $searchType == Mage_CatalogSearch_Model_Fulltext::SEARCH_TYPE_COMBINE) {
+                $where .= ($where ? ' OR ' : '') . $likeCond;
+        } elseif ($likeCond != '' && $searchType == Mage_CatalogSearch_Model_Fulltext::SEARCH_TYPE_LIKE) {
+            $select->columns(array('relevance'  => new Zend_Db_Expr(0)));
+            $where = $likeCond;
         }
 
+        if ($where != '') {
+            $select->where($where);
+        }
+
+        $this->_foundData = $adapter->fetchPairs($select, $bind);
+
         return $this;
     }
 
     /**
+     * Retrieve found data
+     *
+     * @return array
+     */
+    public function getFoundData()
+    {
+        return $this->_foundData;
+    }
+
+
+    /**
      * Retrieve EAV Config Singleton
      *
      * @return Mage_Eav_Model_Config
diff --git app/code/core/Mage/CatalogSearch/Model/Resource/Fulltext/Collection.php app/code/core/Mage/CatalogSearch/Model/Resource/Fulltext/Collection.php
index 373a912..cd0f64f 100755
--- app/code/core/Mage/CatalogSearch/Model/Resource/Fulltext/Collection.php
+++ app/code/core/Mage/CatalogSearch/Model/Resource/Fulltext/Collection.php
@@ -35,6 +35,39 @@
 class Mage_CatalogSearch_Model_Resource_Fulltext_Collection extends Mage_Catalog_Model_Resource_Product_Collection
 {
     /**
+     * Name for relevance order
+     */
+    const RELEVANCE_ORDER_NAME = 'relevance';
+
+    /**
+     * Found data
+     *
+     * @var array
+     */
+    protected $_foundData = null;
+
+    /**
+     * Sort order by relevance
+     *
+     * @var null
+     */
+    protected $_relevanceSortOrder = SORT_DESC;
+
+    /**
+     * Sort by relevance flag
+     *
+     * @var bool
+     */
+    protected $_sortByRelevance = false;
+
+    /**
+     * Is search filter applied flag
+     *
+     * @var bool
+     */
+    protected $_isSearchFiltersApplied = false;
+
+    /**
      * Retrieve query model object
      *
      * @return Mage_CatalogSearch_Model_Query
@@ -47,22 +80,101 @@ class Mage_CatalogSearch_Model_Resource_Fulltext_Collection extends Mage_Catalog
     /**
      * Add search query filter
      *
-     * @param string $query
+     * @param $query
      * @return Mage_CatalogSearch_Model_Resource_Fulltext_Collection
      */
     public function addSearchFilter($query)
     {
-        Mage::getSingleton('catalogsearch/fulltext')->prepareResult();
-
-        $this->getSelect()->joinInner(
-            array('search_result' => $this->getTable('catalogsearch/result')),
-            $this->getConnection()->quoteInto(
-                'search_result.product_id=e.entity_id AND search_result.query_id=?',
-                $this->_getQuery()->getId()
-            ),
-            array('relevance' => 'relevance')
-        );
+        return $this;
+    }
 
+    /**
+     * Before load handler
+     *
+     * @return Mage_Catalog_Model_Resource_Product_Collection
+     */
+    protected function _beforeLoad()
+    {
+        if (!$this->_isSearchFiltersApplied) {
+            $this->_applySearchFilters();
+        }
+
+        return parent::_beforeLoad();
+    }
+
+    /**
+     * Get collection size
+     *
+     * @return int
+     */
+    public function getSize()
+    {
+        if (!$this->_isSearchFiltersApplied) {
+            $this->_applySearchFilters();
+        }
+
+        return parent::getSize();
+    }
+
+    /**
+     * Apply collection search filter
+     *
+     * @return Mage_CatalogSearch_Model_Resource_Fulltext_Collection
+     */
+    protected function _applySearchFilters()
+    {
+        $foundIds = $this->getFoundIds();
+        if (!empty($foundIds)) {
+            $this->addIdFilter($foundIds);
+        } else {
+            $this->getSelect()->orWhere('FALSE');
+        }
+        $this->_isSearchFiltersApplied = true;
+
+        return $this;
+    }
+
+    /**
+     * Get found products ids
+     *
+     * @return array
+     */
+    public function getFoundIds()
+    {
+        if (is_null($this->_foundData)) {
+            /** @var Mage_CatalogSearch_Model_Fulltext $preparedResult */
+            $preparedResult = Mage::getSingleton('catalogsearch/fulltext');
+            $preparedResult->prepareResult();
+            $this->_foundData = $preparedResult->getResource()->getFoundData();
+        }
+        if (isset($this->_orders[self::RELEVANCE_ORDER_NAME])) {
+            $this->_resortFoundDataByRelevance();
+        }
+        return array_keys($this->_foundData);
+    }
+
+    /**
+     * Resort found data by relevance
+     *
+     * @return Mage_CatalogSearch_Model_Resource_Fulltext_Collection
+     */
+    protected function _resortFoundDataByRelevance()
+    {
+        if (is_array($this->_foundData)) {
+            $data = array();
+            foreach ($this->_foundData as $id => $relevance) {
+                $this->_foundData[$id] = $relevance . '_' . $id;
+            }
+            natsort($this->_foundData);
+            if ($this->_relevanceSortOrder == SORT_DESC) {
+                $this->_foundData = array_reverse($this->_foundData);
+            }
+            foreach ($this->_foundData as $dataString) {
+                list ($relevance, $id) = explode('_', $dataString);
+                $data[$id] = $relevance;
+            }
+            $this->_foundData = $data;
+        }
         return $this;
     }
 
@@ -76,7 +188,8 @@ class Mage_CatalogSearch_Model_Resource_Fulltext_Collection extends Mage_Catalog
     public function setOrder($attribute, $dir = 'desc')
     {
         if ($attribute == 'relevance') {
-            $this->getSelect()->order("relevance {$dir}");
+            $this->_relevanceSortOrder = ($dir == 'asc') ? SORT_ASC : SORT_DESC;
+            $this->addOrder(self::RELEVANCE_ORDER_NAME);
         } else {
             parent::setOrder($attribute, $dir);
         }
@@ -84,7 +197,34 @@ class Mage_CatalogSearch_Model_Resource_Fulltext_Collection extends Mage_Catalog
     }
 
     /**
-     * Stub method for campatibility with other search engines
+     * Add sorting by relevance to select
+     *
+     * @return Mage_CatalogSearch_Model_Resource_Fulltext_Collection
+     */
+    protected function _addRelevanceSorting()
+    {
+        $foundIds = $this->getFoundIds();
+        if (!$foundIds) {
+            return $this;
+        }
+
+        /** @var Mage_CatalogSearch_Model_Resource_Helper_Mysql4 $resourceHelper */
+        $resourceHelper = Mage::getResourceHelper('catalogsearch');
+        $this->_select->order(
+            new Zend_Db_Expr(
+                $resourceHelper->getFieldOrderExpression(
+                    'e.' . $this->getResource()->getIdFieldName(),
+                    $foundIds
+                )
+                . ' ' . Zend_Db_Select::SQL_ASC
+            )
+        );
+
+        return $this;
+    }
+
+    /**
+     * Stub method for compatibility with other search engines
      *
      * @return Mage_CatalogSearch_Model_Resource_Fulltext_Collection
      */
@@ -92,4 +232,24 @@ class Mage_CatalogSearch_Model_Resource_Fulltext_Collection extends Mage_Catalog
     {
         return $this;
     }
+
+    /**
+     * Render sql select orders
+     *
+     * @return  Varien_Data_Collection_Db
+     */
+    protected function _renderOrders()
+    {
+        if (!$this->_isOrdersRendered) {
+            foreach ($this->_orders as $attribute => $direction) {
+                if ($attribute == self::RELEVANCE_ORDER_NAME) {
+                    $this->_addRelevanceSorting();
+                } else {
+                    $this->addAttributeToSort($attribute, $direction);
+                }
+            }
+            $this->_isOrdersRendered = true;
+        }
+        return $this;
+    }
 }
diff --git app/code/core/Mage/CatalogSearch/Model/Resource/Helper/Mysql4.php app/code/core/Mage/CatalogSearch/Model/Resource/Helper/Mysql4.php
index 8dd4096..1db52d8 100644
--- app/code/core/Mage/CatalogSearch/Model/Resource/Helper/Mysql4.php
+++ app/code/core/Mage/CatalogSearch/Model/Resource/Helper/Mysql4.php
@@ -52,6 +52,7 @@ class Mage_CatalogSearch_Model_Resource_Helper_Mysql4 extends Mage_Eav_Model_Res
      * Prepare Terms
      *
      * @param string $str The source string
+     * @param int $maxWordLength
      * @return array(0=>words, 1=>terms)
      */
     function prepareTerms($str, $maxWordLength = 0)
@@ -112,10 +113,24 @@ class Mage_CatalogSearch_Model_Resource_Helper_Mysql4 extends Mage_Eav_Model_Res
      *
      * @param mixed $table The table to insert data into.
      * @param array $data Column-value pairs or array of column-value pairs.
-     * @param arrat $fields update fields pairs or values
+     * @param array $fields update fields pairs or values
      * @return int The number of affected rows.
      */
     public function insertOnDuplicate($table, array $data, array $fields = array()) {
         return $this->_getWriteAdapter()->insertOnDuplicate($table, $data, $fields);
     }
+
+    /**
+     * Get field expression for order by
+     *
+     * @param string $fieldName
+     * @param array $orderedIds
+     *
+     * @return string
+     */
+    public function getFieldOrderExpression($fieldName, array $orderedIds)
+    {
+        $fieldName = $this->_getWriteAdapter()->quoteIdentifier($fieldName);
+        return "FIELD({$fieldName}, {$this->_getReadAdapter()->quote($orderedIds)})";
+    }
 }
