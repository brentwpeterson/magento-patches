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


SUPEE-3819 | EE_1.14.0.1 | v1 | 5b232d75a29e54ff576b58b1a5765cc1a3964839 | Fri Jun 20 12:34:48 2014 +0300 | v1.14.0.1..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Enterprise/TargetRule/Model/Observer.php app/code/core/Enterprise/TargetRule/Model/Observer.php
index 3c209b3..5739810 100644
--- app/code/core/Enterprise/TargetRule/Model/Observer.php
+++ app/code/core/Enterprise/TargetRule/Model/Observer.php
@@ -52,39 +52,27 @@ class Enterprise_TargetRule_Model_Observer
     }
 
     /**
-     * After Catalog Product Save - rebuild product index by rule conditions
-     * and refresh cache index
+     * Process event on 'save_commit_after' event. Rebuild product index by rule conditions
      *
      * @param Varien_Event_Observer $observer
-     * @return Enterprise_TargetRule_Model_Observer
      */
-    public function catalogProductAfterSave(Varien_Event_Observer $observer)
+    public function catalogProductSaveCommitAfter(Varien_Event_Observer $observer)
     {
         /** @var $product Mage_Catalog_Model_Product */
         $product = $observer->getEvent()->getProduct();
 
-        Mage::getSingleton('index/indexer')->logEvent(
-            new Varien_Object(array(
-                'id' => $product->getId(),
-                'store_id' => $product->getStoreId(),
-                'rule' => $product->getData('rule'),
-                'from_date' => $product->getData('from_date'),
-                'to_date' => $product->getData('to_date')
-            )),
-            Enterprise_TargetRule_Model_Index::ENTITY_PRODUCT,
-            Enterprise_TargetRule_Model_Index::EVENT_TYPE_REINDEX_PRODUCTS
-        );
-        return $this;
-    }
-
-    /**
-     * Process event on 'save_commit_after' event
-     *
-     * @param Varien_Event_Observer $observer
-     */
-    public function catalogProductSaveCommitAfter(Varien_Event_Observer $observer)
-    {
-        Mage::getSingleton('index/indexer')->indexEvents(
+        /** @var \Mage_Index_Model_Indexer $indexer */
+        $indexer = Mage::getSingleton('index/indexer');
+        $indexer->processEntityAction(
+            new Varien_Object(
+                array(
+                    'id' => $product->getId(),
+                    'store_id' => $product->getStoreId(),
+                    'rule' => $product->getData('rule'),
+                    'from_date' => $product->getData('from_date'),
+                    'to_date' => $product->getData('to_date')
+                )
+            ),
             Enterprise_TargetRule_Model_Index::ENTITY_PRODUCT,
             Enterprise_TargetRule_Model_Index::EVENT_TYPE_REINDEX_PRODUCTS
         );
diff --git app/code/core/Enterprise/TargetRule/Model/Resource/Rule.php app/code/core/Enterprise/TargetRule/Model/Resource/Rule.php
index fc8e265..bbfbb5e 100755
--- app/code/core/Enterprise/TargetRule/Model/Resource/Rule.php
+++ app/code/core/Enterprise/TargetRule/Model/Resource/Rule.php
@@ -154,16 +154,6 @@ class Enterprise_TargetRule_Model_Resource_Rule extends Mage_Rule_Model_Resource
             $this->bindRuleToEntity($object->getId(), $object->getMatchingProductIds(), 'product');
         }
 
-        $typeId = (!$object->isObjectNew() && $object->getOrigData('apply_to') != $object->getData('apply_to'))
-            ? null
-            : $object->getData('apply_to');
-
-        Mage::getSingleton('index/indexer')->processEntityAction(
-            new Varien_Object(array('type_id' => $typeId)),
-            Enterprise_TargetRule_Model_Index::ENTITY_TARGETRULE,
-            Enterprise_TargetRule_Model_Index::EVENT_TYPE_CLEAN_TARGETRULES
-        );
-
         return $this;
     }
 
@@ -197,25 +187,6 @@ class Enterprise_TargetRule_Model_Resource_Rule extends Mage_Rule_Model_Resource
     }
 
     /**
-     * Clean index
-     *
-     * @param Mage_Core_Model_Abstract|Enterprise_TargetRule_Model_Rule $object
-     *
-     * @return Enterprise_TargetRule_Model_Resource_Rule
-     */
-    protected function _beforeDelete(Mage_Core_Model_Abstract $object)
-    {
-        Mage::getSingleton('index/indexer')->processEntityAction(
-            new Varien_Object(array('type_id' => $object->getData('apply_to'))),
-            Enterprise_TargetRule_Model_Index::ENTITY_TARGETRULE,
-            Enterprise_TargetRule_Model_Index::EVENT_TYPE_CLEAN_TARGETRULES
-        );
-
-        parent::_beforeDelete($object);
-        return $this;
-    }
-
-    /**
      * Prepare and Save Matched products for Rule
      *
      * @deprecated after 1.11.2.0
diff --git app/code/core/Enterprise/TargetRule/Model/Rule.php app/code/core/Enterprise/TargetRule/Model/Rule.php
index 886972c..830ea01 100644
--- app/code/core/Enterprise/TargetRule/Model/Rule.php
+++ app/code/core/Enterprise/TargetRule/Model/Rule.php
@@ -384,4 +384,48 @@ class Enterprise_TargetRule_Model_Rule extends Mage_Rule_Model_Abstract
     {
         return $this;
     }
+
+    /**
+     * Callback function which called after transaction commit in resource model
+     *
+     * @return Enterprise_TargetRule_Model_Rule
+     */
+    public function afterCommitCallback()
+    {
+        parent::afterCommitCallback();
+
+        /** @var \Mage_Index_Model_Indexer $indexer */
+        $indexer = Mage::getSingleton('index/indexer');
+
+        $typeId = (!$this->isObjectNew() && $this->getOrigData('apply_to') != $this->getData('apply_to'))
+            ? null
+            : $this->getData('apply_to');
+
+        $indexer->processEntityAction(
+            new Varien_Object(array('type_id' => $typeId)),
+            Enterprise_TargetRule_Model_Index::ENTITY_TARGETRULE,
+            Enterprise_TargetRule_Model_Index::EVENT_TYPE_CLEAN_TARGETRULES
+        );
+        return $this;
+    }
+
+    /**
+     * Callback function which called after transaction commit in resource model
+     *
+     * @return Enterprise_TargetRule_Model_Rule
+     */
+    public function _afterDeleteCommit()
+    {
+        parent::_afterDeleteCommit();
+
+        /** @var \Mage_Index_Model_Indexer $indexer */
+        $indexer = Mage::getSingleton('index/indexer');
+        $indexer->processEntityAction(
+            new Varien_Object(array('type_id' => $this->getData('apply_to'))),
+            Enterprise_TargetRule_Model_Index::ENTITY_TARGETRULE,
+            Enterprise_TargetRule_Model_Index::EVENT_TYPE_CLEAN_TARGETRULES
+        );
+
+        return $this;
+    }
 }
diff --git app/code/core/Enterprise/TargetRule/etc/config.xml app/code/core/Enterprise/TargetRule/etc/config.xml
index 67716cd..3b6573a 100755
--- app/code/core/Enterprise/TargetRule/etc/config.xml
+++ app/code/core/Enterprise/TargetRule/etc/config.xml
@@ -113,14 +113,6 @@
     </global>
     <adminhtml>
         <events>
-            <catalog_product_save_after>
-                <observers>
-                    <enterprise_targetrule>
-                        <class>enterprise_targetrule/observer</class>
-                        <method>catalogProductAfterSave</method>
-                    </enterprise_targetrule>
-                </observers>
-            </catalog_product_save_after>
             <catalog_product_save_commit_after>
                 <observers>
                     <enterprise_targetrule>
diff --git app/code/core/Mage/Catalog/Model/Category.php app/code/core/Mage/Catalog/Model/Category.php
index e7bb21e..e1e548d 100644
--- app/code/core/Mage/Catalog/Model/Category.php
+++ app/code/core/Mage/Catalog/Model/Category.php
@@ -942,16 +942,18 @@ class Mage_Catalog_Model_Category extends Mage_Catalog_Model_Abstract
     }
 
     /**
-     * Init indexing process after category save
+     * Callback function which called after transaction commit in resource model
      *
      * @return Mage_Catalog_Model_Category
      */
-    protected function _afterSave()
+    public function afterCommitCallback()
     {
-        $result = parent::_afterSave();
-        Mage::getSingleton('index/indexer')->processEntityAction(
-            $this, self::ENTITY, Mage_Index_Model_Event::TYPE_SAVE
-        );
-        return $result;
+        parent::afterCommitCallback();
+
+        /** @var \Mage_Index_Model_Indexer $indexer */
+        $indexer = Mage::getSingleton('index/indexer');
+        $indexer->processEntityAction($this, self::ENTITY, Mage_Index_Model_Event::TYPE_SAVE);
+
+        return $this;
     }
 }
diff --git app/code/core/Mage/Catalog/Model/Product.php app/code/core/Mage/Catalog/Model/Product.php
index 0dc7d2f..19c551e 100644
--- app/code/core/Mage/Catalog/Model/Product.php
+++ app/code/core/Mage/Catalog/Model/Product.php
@@ -546,12 +546,7 @@ class Mage_Catalog_Model_Product extends Mage_Catalog_Model_Abstract
         $this->getOptionInstance()->setProduct($this)
             ->saveOptions();
 
-        $result = parent::_afterSave();
-
-        Mage::getSingleton('index/indexer')->processEntityAction(
-            $this, self::ENTITY, Mage_Index_Model_Event::TYPE_SAVE
-        );
-        return $result;
+        return parent::_afterSave();
     }
 
     /**
@@ -564,9 +559,7 @@ class Mage_Catalog_Model_Product extends Mage_Catalog_Model_Abstract
     {
         $this->_protectFromNonAdmin();
         $this->cleanCache();
-        Mage::getSingleton('index/indexer')->logEvent(
-            $this, self::ENTITY, Mage_Index_Model_Event::TYPE_DELETE
-        );
+
         return parent::_beforeDelete();
     }
 
@@ -578,9 +571,11 @@ class Mage_Catalog_Model_Product extends Mage_Catalog_Model_Abstract
     protected function _afterDeleteCommit()
     {
         parent::_afterDeleteCommit();
-        Mage::getSingleton('index/indexer')->indexEvents(
-            self::ENTITY, Mage_Index_Model_Event::TYPE_DELETE
-        );
+
+        /** @var \Mage_Index_Model_Indexer $indexer */
+        $indexer = Mage::getSingleton('index/indexer');
+
+        $indexer->processEntityAction($this, self::ENTITY, Mage_Index_Model_Event::TYPE_DELETE);
     }
 
     /**
@@ -2066,4 +2061,20 @@ class Mage_Catalog_Model_Product extends Mage_Catalog_Model_Abstract
     {
         return $this->getStatus() == Mage_Catalog_Model_Product_Status::STATUS_DISABLED;
     }
+
+    /**
+     * Callback function which called after transaction commit in resource model
+     *
+     * @return Mage_Catalog_Model_Product
+     */
+    public function afterCommitCallback()
+    {
+        parent::afterCommitCallback();
+
+        /** @var \Mage_Index_Model_Indexer $indexer */
+        $indexer = Mage::getSingleton('index/indexer');
+        $indexer->processEntityAction($this, self::ENTITY, Mage_Index_Model_Event::TYPE_SAVE);
+
+        return $this;
+    }
 }
diff --git app/code/core/Mage/Catalog/Model/Resource/Eav/Attribute.php app/code/core/Mage/Catalog/Model/Resource/Eav/Attribute.php
index e250669..137719d 100644
--- app/code/core/Mage/Catalog/Model/Resource/Eav/Attribute.php
+++ app/code/core/Mage/Catalog/Model/Resource/Eav/Attribute.php
@@ -150,9 +150,6 @@ class Mage_Catalog_Model_Resource_Eav_Attribute extends Mage_Eav_Model_Entity_At
          */
         Mage::getSingleton('eav/config')->clear();
 
-        Mage::getSingleton('index/indexer')->processEntityAction(
-            $this, self::ENTITY, Mage_Index_Model_Event::TYPE_SAVE
-        );
         return parent::_afterSave();
     }
 
@@ -387,4 +384,20 @@ class Mage_Catalog_Model_Resource_Eav_Attribute extends Mage_Eav_Model_Entity_At
 
         return 'source';
     }
+
+    /**
+     * Callback function which called after transaction commit in resource model
+     *
+     * @return Mage_Catalog_Model_Resource_Eav_Attribute
+     */
+    public function afterCommitCallback()
+    {
+        parent::afterCommitCallback();
+
+        /** @var \Mage_Index_Model_Indexer $indexer */
+        $indexer = Mage::getSingleton('index/indexer');
+        $indexer->processEntityAction($this, self::ENTITY, Mage_Index_Model_Event::TYPE_SAVE);
+
+        return $this;
+    }
 }
diff --git app/code/core/Mage/CatalogInventory/Model/Stock/Item.php app/code/core/Mage/CatalogInventory/Model/Stock/Item.php
index a72e5eb..9fb3c28 100644
--- app/code/core/Mage/CatalogInventory/Model/Stock/Item.php
+++ app/code/core/Mage/CatalogInventory/Model/Stock/Item.php
@@ -778,26 +778,6 @@ class Mage_CatalogInventory_Model_Stock_Item extends Mage_Core_Model_Abstract
     }
 
     /**
-     * Reindex CatalogInventory save event
-     *
-     * @return Mage_CatalogInventory_Model_Stock_Item
-     */
-    protected function _afterSave()
-    {
-        parent::_afterSave();
-
-        /** @var $indexer Mage_Index_Model_Indexer */
-        $indexer = Mage::getSingleton('index/indexer');
-        if ($this->_processIndexEvents) {
-            $indexer->processEntityAction($this, self::ENTITY, Mage_Index_Model_Event::TYPE_SAVE);
-        } else {
-            $indexer->logEvent($this, self::ENTITY, Mage_Index_Model_Event::TYPE_SAVE);
-        }
-        return $this;
-    }
-
-
-    /**
      * Retrieve Stock Availability
      *
      * @return bool|int
@@ -902,4 +882,24 @@ class Mage_CatalogInventory_Model_Stock_Item extends Mage_Core_Model_Abstract
         $this->_processIndexEvents = $process;
         return $this;
     }
+
+    /**
+     * Callback function which called after transaction commit in resource model
+     *
+     * @return Mage_CatalogInventory_Model_Stock_Item
+     */
+    public function afterCommitCallback()
+    {
+        parent::afterCommitCallback();
+
+        /** @var \Mage_Index_Model_Indexer $indexer */
+        $indexer = Mage::getSingleton('index/indexer');
+
+        if ($this->_processIndexEvents) {
+            $indexer->processEntityAction($this, self::ENTITY, Mage_Index_Model_Event::TYPE_SAVE);
+        } else {
+            $indexer->logEvent($this, self::ENTITY, Mage_Index_Model_Event::TYPE_SAVE);
+        }
+        return $this;
+    }
 }
diff --git app/code/core/Mage/CatalogRule/Model/Action/Index/Refresh/Row.php app/code/core/Mage/CatalogRule/Model/Action/Index/Refresh/Row.php
index 3b67de8..87d53b1 100644
--- app/code/core/Mage/CatalogRule/Model/Action/Index/Refresh/Row.php
+++ app/code/core/Mage/CatalogRule/Model/Action/Index/Refresh/Row.php
@@ -60,6 +60,13 @@ class Mage_CatalogRule_Model_Action_Index_Refresh_Row extends Mage_CatalogRule_M
     }
 
     /**
+     * Do not recreate rule group website for row refresh
+     */
+    protected function _prepareGroupWebsite($timestamp)
+    {
+    }
+
+    /**
      * Prepare temporary data
      *
      * @param Mage_Core_Model_Website $website
diff --git app/code/core/Mage/CatalogRule/Model/Observer.php app/code/core/Mage/CatalogRule/Model/Observer.php
index 180f2a6..8ea4ae9 100644
--- app/code/core/Mage/CatalogRule/Model/Observer.php
+++ app/code/core/Mage/CatalogRule/Model/Observer.php
@@ -56,6 +56,24 @@ class Mage_CatalogRule_Model_Observer
     }
 
     /**
+     * Load matched catalog price rules for specific product.
+     * Is used for comparison in Mage_CatalogRule_Model_Resource_Rule::applyToProduct method
+     *
+     * @param   Varien_Event_Observer $observer
+     * @return  Mage_CatalogRule_Model_Observer
+     */
+    public function loadProductRules($observer)
+    {
+        /** @var Mage_Catalog_Model_Product $product */
+        $product = $observer->getEvent()->getProduct();
+        if (!$product instanceof Mage_Catalog_Model_Product) {
+            return $this;
+        }
+        Mage::getModel('catalogrule/rule')->loadProductRules($product);
+        return $this;
+    }
+
+    /**
      * Apply all price rules for current date.
      * Handle catalog_product_import_after event
      *
diff --git app/code/core/Mage/CatalogRule/Model/Resource/Rule.php app/code/core/Mage/CatalogRule/Model/Resource/Rule.php
index 5bdf278..529c9bc 100644
--- app/code/core/Mage/CatalogRule/Model/Resource/Rule.php
+++ app/code/core/Mage/CatalogRule/Model/Resource/Rule.php
@@ -771,26 +771,52 @@ class Mage_CatalogRule_Model_Resource_Rule extends Mage_Rule_Model_Resource_Abst
         $write = $this->_getWriteAdapter();
         $write->beginTransaction();
 
-        $this->cleanProductData($ruleId, array($productId));
-
-        if (!$this->validateProduct($rule, $product, $websiteIds)) {
+        if ($this->_isProductMatchedRule($ruleId, $product)) {
+            $this->cleanProductData($ruleId, array($productId));
+        }
+        if ($this->validateProduct($rule, $product, $websiteIds)) {
+            try {
+                $this->insertRuleData($rule, $websiteIds, array(
+                    $productId => array_combine(array_values($websiteIds), array_values($websiteIds)))
+                );
+            } catch (Exception $e) {
+                $write->rollback();
+                throw $e;
+            }
+        } else {
             $write->delete($this->getTable('catalogrule/rule_product_price'), array(
                 $write->quoteInto('product_id = ?', $productId),
             ));
-            $write->commit();
-            return $this;
-        }
-
-        try {
-            $this->insertRuleData($rule, $websiteIds, array(
-                $productId => array_combine(array_values($websiteIds), array_values($websiteIds))));
-        } catch (Exception $e) {
-            $write->rollback();
-            throw $e;
         }
 
         $write->commit();
-
         return $this;
     }
+
+    /**
+     * Get ids of matched rules for specific product
+     *
+     * @param int $productId
+     * @return array
+     */
+    public function getProductRuleIds($productId)
+    {
+        $read = $this->_getReadAdapter();
+        $select = $read->select()->from($this->getTable('catalogrule/rule_product'), 'rule_id');
+        $select->where('product_id = ?', $productId);
+        return array_flip($read->fetchCol($select));
+    }
+
+    /**
+     * Is product has been matched the rule
+     *
+     * @param int $ruleId
+     * @param Mage_Catalog_Model_Product $product
+     * @return bool
+     */
+    protected function _isProductMatchedRule($ruleId, $product)
+    {
+        $rules = $product->getMatchedRules();
+        return isset($rules[$ruleId]);
+    }
 }
diff --git app/code/core/Mage/CatalogRule/Model/Rule.php app/code/core/Mage/CatalogRule/Model/Rule.php
index 81a1d3b..c4a522c 100644
--- app/code/core/Mage/CatalogRule/Model/Rule.php
+++ app/code/core/Mage/CatalogRule/Model/Rule.php
@@ -484,4 +484,18 @@ class Mage_CatalogRule_Model_Rule extends Mage_Rule_Model_Abstract
     {
         return parent::toArray($arrAttributes);
     }
+
+    /**
+     * Load matched product rules to the product
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @return $this
+     */
+    public function loadProductRules(Mage_Catalog_Model_Product $product)
+    {
+        if (!$product->hasData('matched_rules')) {
+            $product->setMatchedRules($this->getResource()->getProductRuleIds($product->getId()));
+        }
+        return $this;
+    }
 }
diff --git app/code/core/Mage/CatalogRule/etc/config.xml app/code/core/Mage/CatalogRule/etc/config.xml
index 586cf14..4034599 100644
--- app/code/core/Mage/CatalogRule/etc/config.xml
+++ app/code/core/Mage/CatalogRule/etc/config.xml
@@ -152,6 +152,14 @@
                     </catalogrule>
                 </observers>
             </catalog_product_get_final_price>
+            <catalog_product_save_before>
+                <observers>
+                    <catalogrule>
+                        <class>catalogrule/observer</class>
+                        <method>loadProductRules</method>
+                    </catalogrule>
+                </observers>
+            </catalog_product_save_before>
             <catalog_product_save_commit_after>
                 <observers>
                     <catalogrule>
diff --git app/code/core/Mage/Core/Model/Abstract.php app/code/core/Mage/Core/Model/Abstract.php
index af07352..8045a3b 100644
--- app/code/core/Mage/Core/Model/Abstract.php
+++ app/code/core/Mage/Core/Model/Abstract.php
@@ -539,7 +539,7 @@ abstract class Mage_Core_Model_Abstract extends Varien_Object
     {
         Mage::dispatchEvent('model_delete_commit_after', array('object'=>$this));
         Mage::dispatchEvent($this->_eventPrefix.'_delete_commit_after', $this->_getEventData());
-         return $this;
+        return $this;
     }
 
     /**
