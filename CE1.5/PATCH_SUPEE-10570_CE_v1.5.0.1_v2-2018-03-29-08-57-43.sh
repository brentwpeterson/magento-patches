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


SUPEE-10570_CE_v1.5.0.1 | CE_1.5.0.1 | v1 | 21a7c21de91dc15594c1b0494bcf908acb5a93f9 | Fri Mar 16 14:22:03 2018 +0200 | ce-1.5.0.1-dev

__PATCHFILE_FOLLOWS__
diff --git app/Mage.php app/Mage.php
index 4ec3930..e7bf375 100644
--- app/Mage.php
+++ app/Mage.php
@@ -753,6 +753,7 @@ final class Mage
                 $message = print_r($message, true);
             }
 
+            $message = addcslashes($message, '<?');
             $loggers[$file]->log($message, $level);
         }
         catch (Exception $e) {
diff --git app/code/core/Mage/Admin/Model/Block.php app/code/core/Mage/Admin/Model/Block.php
index db89d7b..c581dbf 100644
--- app/code/core/Mage/Admin/Model/Block.php
+++ app/code/core/Mage/Admin/Model/Block.php
@@ -34,6 +34,13 @@
 class Mage_Admin_Model_Block extends Mage_Core_Model_Abstract
 {
     /**
+     * Disallowed names for block
+     *
+     * @var array
+     */
+    protected $disallowedBlockNames = array('install/end');
+
+    /**
      * Initialize variable model
      */
     protected function _construct()
@@ -53,6 +60,10 @@ class Mage_Admin_Model_Block extends Mage_Core_Model_Abstract
         if (!Zend_Validate::is($this->getBlockName(), 'NotEmpty')) {
             $errors[] = Mage::helper('admin')->__('Block Name is required field.');
         }
+        $disallowedBlockNames = $this->getDisallowedBlockNames();
+        if (in_array($this->getBlockName(), $disallowedBlockNames)) {
+            $errors[] = Mage::helper('adminhtml')->__('Block Name is disallowed.');
+        }
         if (!Zend_Validate::is($this->getBlockName(), 'Regex', array('/^[-_a-zA-Z0-9\/]*$/'))) {
             $errors[] = Mage::helper('admin')->__('Block Name is incorrect.');
         }
@@ -81,4 +92,14 @@ class Mage_Admin_Model_Block extends Mage_Core_Model_Abstract
             ->addFieldToFilter('is_allowed', array('eq' => 1));
         return $collection->load()->count();
     }
+
+    /**
+     *  Get disallowed names for block
+     *
+     * @return array
+     */
+    public function getDisallowedBlockNames()
+    {
+        return $this->disallowedBlockNames;
+    }
 }
diff --git app/code/core/Mage/Admin/Model/User.php app/code/core/Mage/Admin/Model/User.php
index e46d955..571dee2 100644
--- app/code/core/Mage/Admin/Model/User.php
+++ app/code/core/Mage/Admin/Model/User.php
@@ -262,7 +262,7 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
     /**
      * Login user
      *
-     * @param   string $login
+     * @param   string $username
      * @param   string $password
      * @return  Mage_Admin_Model_User
      */
@@ -270,6 +270,7 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
     {
         if ($this->authenticate($username, $password)) {
             $this->getResource()->recordLogin($this);
+            Mage::getSingleton('core/session')->renewFormKey();
         }
         return $this;
     }
diff --git app/code/core/Mage/Adminhtml/Block/Catalog/Category/Edit/Form.php app/code/core/Mage/Adminhtml/Block/Catalog/Category/Edit/Form.php
index effbdf7..3a15712 100644
--- app/code/core/Mage/Adminhtml/Block/Catalog/Category/Edit/Form.php
+++ app/code/core/Mage/Adminhtml/Block/Catalog/Category/Edit/Form.php
@@ -185,7 +185,7 @@ class Mage_Adminhtml_Block_Catalog_Category_Edit_Form extends Mage_Adminhtml_Blo
     {
         if ($this->hasStoreRootCategory()) {
             if ($this->getCategoryId()) {
-                return $this->getCategoryName();
+                return $this->escapeHtml($this->getCategoryName());
             } else {
                 $parentId = (int) $this->getRequest()->getParam('parent');
                 if ($parentId && ($parentId != Mage_Catalog_Model_Category::TREE_ROOT_ID)) {
diff --git app/code/core/Mage/Adminhtml/Block/Catalog/Product/Grid.php app/code/core/Mage/Adminhtml/Block/Catalog/Product/Grid.php
index d4e3faf..ea8dfa4 100644
--- app/code/core/Mage/Adminhtml/Block/Catalog/Product/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Catalog/Product/Grid.php
@@ -124,7 +124,7 @@ class Mage_Adminhtml_Block_Catalog_Product_Grid extends Mage_Adminhtml_Block_Wid
         if ($store->getId()) {
             $this->addColumn('custom_name',
                 array(
-                    'header'=> Mage::helper('catalog')->__('Name in %s', $store->getName()),
+                    'header'=> Mage::helper('catalog')->__('Name in %s', $this->escapeHtml($store->getName())),
                     'index' => 'custom_name',
             ));
         }
diff --git app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Grid/Renderer/Sender.php app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Grid/Renderer/Sender.php
index 80c6032..d30ebe8 100644
--- app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Grid/Renderer/Sender.php
+++ app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Grid/Renderer/Sender.php
@@ -38,10 +38,10 @@ class Mage_Adminhtml_Block_Newsletter_Template_Grid_Renderer_Sender extends Mage
     {
         $str = '';
         if($row->getTemplateSenderName()) {
-            $str .= htmlspecialchars($row->getTemplateSenderName()) . ' ';
+            $str .= $this->escapeHtml($row->getTemplateSenderName()) . ' ';
         }        
         if($row->getTemplateSenderEmail()) {
-            $str .= '[' . $row->getTemplateSenderEmail() . ']';
+            $str .= '[' .$this->escapeHtml($row->getTemplateSenderEmail()) . ']';
         }        
         if($str == '') {
             $str .= '---';
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php
index 4128401..bcdcea6 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php
@@ -78,6 +78,7 @@ class Mage_Adminhtml_Block_Sales_Order_Grid extends Mage_Adminhtml_Block_Widget_
                 'type'      => 'store',
                 'store_view'=> true,
                 'display_deleted' => true,
+                'escape'  => true,
             ));
         }
 
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/View/Info.php app/code/core/Mage/Adminhtml/Block/Sales/Order/View/Info.php
index 6b8236a..949f855 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/View/Info.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/View/Info.php
@@ -64,7 +64,7 @@ class Mage_Adminhtml_Block_Sales_Order_View_Info extends Mage_Adminhtml_Block_Sa
                 $store->getGroup()->getName(),
                 $store->getName()
             );
-            return implode('<br/>', $name);
+            return implode('<br/>', array_map(array($this, 'escapeHtml'), $name));
         }
         return null;
     }
diff --git app/code/core/Mage/Adminhtml/Block/System/Store/Edit/Form.php app/code/core/Mage/Adminhtml/Block/System/Store/Edit/Form.php
index c613896..5fa084d 100644
--- app/code/core/Mage/Adminhtml/Block/System/Store/Edit/Form.php
+++ app/code/core/Mage/Adminhtml/Block/System/Store/Edit/Form.php
@@ -241,7 +241,7 @@ class Mage_Adminhtml_Block_System_Store_Edit_Form extends Mage_Adminhtml_Block_W
                             $values[] = array('label'=>$group->getName(),'value'=>$group->getId());
                         }
                     }
-                    $groups[] = array('label'=>$website->getName(),'value'=>$values);
+                    $groups[] = array('label' => $this->escapeHtml($website->getName()), 'value' => $values);
                 }
                 $fieldset->addField('store_group_id', 'select', array(
                     'name'      => 'store[group_id]',
diff --git app/code/core/Mage/Adminhtml/Block/Tag/Assigned/Grid.php app/code/core/Mage/Adminhtml/Block/Tag/Assigned/Grid.php
index dd3e4ba..be20301 100644
--- app/code/core/Mage/Adminhtml/Block/Tag/Assigned/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Tag/Assigned/Grid.php
@@ -174,7 +174,7 @@ class Mage_Adminhtml_Block_Tag_Assigned_Grid extends Mage_Adminhtml_Block_Widget
         if ($store->getId()) {
             $this->addColumn('custom_name',
                 array(
-                    'header'=> Mage::helper('catalog')->__('Name in %s', $store->getName()),
+                    'header'=> Mage::helper('catalog')->__('Name in %s', $this->escapeHtml($store->getName())),
                     'index' => 'custom_name',
             ));
         }
diff --git app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Store.php app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Store.php
index df006f1..b6b94a6 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Store.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Store.php
@@ -110,11 +110,11 @@ class Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Store extends Mage_Adminh
         $data = $this->_getStoreModel()->getStoresStructure(false, $origStores);
 
         foreach ($data as $website) {
-            $out .= $website['label'] . '<br/>';
+            $out .= Mage::helper('core')->escapeHtml($website['label']) . '<br/>';
             foreach ($website['children'] as $group) {
-                $out .= str_repeat('&nbsp;', 3) . $group['label'] . '<br/>';
+                $out .= str_repeat('&nbsp;', 3) . Mage::helper('core')->escapeHtml($group['label']) . '<br/>';
                 foreach ($group['children'] as $store) {
-                    $out .= str_repeat('&nbsp;', 6) . $store['label'] . '<br/>';
+                    $out .= str_repeat('&nbsp;', 6) . Mage::helper('core')->escapeHtml($store['label']) . '<br/>';
                 }
             }
         }
diff --git app/code/core/Mage/Adminhtml/Block/Widget/Tabs.php app/code/core/Mage/Adminhtml/Block/Widget/Tabs.php
index c319dd4..9454661 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Tabs.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Tabs.php
@@ -275,9 +275,9 @@ class Mage_Adminhtml_Block_Widget_Tabs extends Mage_Adminhtml_Block_Widget
     public function getTabLabel($tab)
     {
         if ($tab instanceof Mage_Adminhtml_Block_Widget_Tab_Interface) {
-            return $tab->getTabLabel();
+            return $this->escapeHtml($tab->getTabLabel());
         }
-        return $tab->getLabel();
+        return $this->escapeHtml($tab->getLabel());
     }
 
     public function getTabContent($tab)
diff --git app/code/core/Mage/Adminhtml/Model/Config/Data.php app/code/core/Mage/Adminhtml/Model/Config/Data.php
index dc7d8aa..1250741 100644
--- app/code/core/Mage/Adminhtml/Model/Config/Data.php
+++ app/code/core/Mage/Adminhtml/Model/Config/Data.php
@@ -97,11 +97,9 @@ class Mage_Adminhtml_Model_Config_Data extends Varien_Object
             // use extra memory
             $fieldsetData = array();
             foreach ($groupData['fields'] as $field => $fieldData) {
+                $field = ltrim($field, '/');
                 $fieldsetData[$field] = (is_array($fieldData) && isset($fieldData['value']))
                     ? $fieldData['value'] : null;
-            }
-
-            foreach ($groupData['fields'] as $field => $fieldData) {
 
                 /**
                  * Get field backend model
diff --git app/code/core/Mage/Adminhtml/Model/System/Store.php app/code/core/Mage/Adminhtml/Model/System/Store.php
index c64782a..bb662b5 100644
--- app/code/core/Mage/Adminhtml/Model/System/Store.php
+++ app/code/core/Mage/Adminhtml/Model/System/Store.php
@@ -151,7 +151,7 @@ class Mage_Adminhtml_Model_System_Store extends Varien_Object
                     }
                     if (!$websiteShow) {
                         $options[] = array(
-                            'label' => $website->getName(),
+                            'label' => Mage::helper('core')->escapeHtml($website->getName()),
                             'value' => array()
                         );
                         $websiteShow = true;
@@ -161,13 +161,15 @@ class Mage_Adminhtml_Model_System_Store extends Varien_Object
                         $values    = array();
                     }
                     $values[] = array(
-                        'label' => str_repeat($nonEscapableNbspChar, 4) . $store->getName(),
+                        'label' => str_repeat($nonEscapableNbspChar, 4) .
+                            Mage::helper('core')->escapeHtml($store->getName()),
                         'value' => $store->getId()
                     );
                 }
                 if ($groupShow) {
                     $options[] = array(
-                        'label' => str_repeat($nonEscapableNbspChar, 4) . $group->getName(),
+                        'label' => str_repeat($nonEscapableNbspChar, 4) .
+                            Mage::helper('core')->escapeHtml($group->getName()),
                         'value' => $values
                     );
                 }
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
index 40e0598..0b174ae 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
@@ -670,6 +670,16 @@ class Mage_Adminhtml_Catalog_ProductController extends Mage_Adminhtml_Controller
                 $data['product']['stock_data']['use_config_manage_stock'] = 0;
             }
             $product = $this->_initProductSave();
+            // check sku attribute
+            $productSku = $product->getSku();
+            if ($productSku && $productSku != Mage::helper('core')->stripTags($productSku)) {
+                $this->_getSession()->addError($this->__('HTML tags are not allowed in SKU attribute.'));
+                $this->_redirect('*/*/edit', array(
+                    'id' => $productId,
+                    '_current' => true
+                ));
+                return;
+            }
 
             try {
                 $product->save();
diff --git app/code/core/Mage/Adminhtml/controllers/System/BackupController.php app/code/core/Mage/Adminhtml/controllers/System/BackupController.php
index 551c45c..92d8222 100644
--- app/code/core/Mage/Adminhtml/controllers/System/BackupController.php
+++ app/code/core/Mage/Adminhtml/controllers/System/BackupController.php
@@ -34,6 +34,17 @@
 class Mage_Adminhtml_System_BackupController extends Mage_Adminhtml_Controller_Action
 {
     /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('create');
+        return parent::preDispatch();
+    }
+
+    /**
      * Backup list action
      */
     public function indexAction()
diff --git app/code/core/Mage/Core/Model/Session/Abstract/Varien.php app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
index 18220d9..505a99f 100644
--- app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
+++ app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
@@ -32,6 +32,7 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
     const VALIDATOR_HTTP_X_FORVARDED_FOR_KEY    = 'http_x_forwarded_for';
     const VALIDATOR_HTTP_VIA_KEY                = 'http_via';
     const VALIDATOR_REMOTE_ADDR_KEY             = 'remote_addr';
+    const VALIDATOR_SESSION_EXPIRE_TIMESTAMP    = 'session_expire_timestamp';
 
     /**
      * Conigure and start session
@@ -314,6 +315,16 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
     }
 
     /**
+     * Use session expire timestamp in validator key
+     *
+     * @return bool
+     */
+    public function useValidateSessionExpire()
+    {
+        return $this->getCookie()->getLifetime() > 0;
+    }
+
+    /**
      * Retrieve skip User Agent validation strings (Flash etc)
      *
      * @return array
@@ -376,6 +387,15 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
             return false;
         }
 
+        if ($this->useValidateSessionExpire()
+            && isset($sessionData[self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP])
+            && $sessionData[self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP] < time() ) {
+            return false;
+        } else {
+            $this->_data[self::VALIDATOR_KEY][self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP]
+                = $validatorData[self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP];
+        }
+
         return true;
     }
 
@@ -409,6 +429,8 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
             $parts[self::VALIDATOR_HTTP_USER_AGENT_KEY] = (string)$_SERVER['HTTP_USER_AGENT'];
         }
 
+        $parts[self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP] = time() + $this->getCookie()->getLifetime();
+
         return $parts;
     }
 
diff --git app/code/core/Mage/Core/Model/Variable.php app/code/core/Mage/Core/Model/Variable.php
index 1c9587b..c4104c5 100644
--- app/code/core/Mage/Core/Model/Variable.php
+++ app/code/core/Mage/Core/Model/Variable.php
@@ -134,7 +134,10 @@ class Mage_Core_Model_Variable extends Mage_Core_Model_Abstract
         foreach ($collection->toOptionArray() as $variable) {
             $variables[] = array(
                 'value' => '{{customVar code=' . $variable['value'] . '}}',
-                'label' => Mage::helper('core')->__('%s', $variable['label'])
+                'label' => Mage::helper('core')->__(
+                    '%s',
+                    Mage::helper('core')->escapeHtml($variable['label']
+                    ))
             );
         }
         if ($withGroup && $variables) {
diff --git app/code/core/Mage/Customer/etc/config.xml app/code/core/Mage/Customer/etc/config.xml
index 6e44997..8caeaf6 100644
--- app/code/core/Mage/Customer/etc/config.xml
+++ app/code/core/Mage/Customer/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Mage_Customer>
-            <version>1.4.0.0.13</version>
+            <version>1.4.0.0.13.1.2</version>
         </Mage_Customer>
     </modules>
 
diff --git app/code/core/Mage/Customer/sql/customer_setup/mysql4-upgrade-1.4.0.0.13.1.1-1.4.0.0.13.1.2.php app/code/core/Mage/Customer/sql/customer_setup/mysql4-upgrade-1.4.0.0.13.1.1-1.4.0.0.13.1.2.php
new file mode 100644
index 0000000..543bc81
--- /dev/null
+++ app/code/core/Mage/Customer/sql/customer_setup/mysql4-upgrade-1.4.0.0.13.1.1-1.4.0.0.13.1.2.php
@@ -0,0 +1,38 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Customer
+ * @copyright  Copyright (c) 2006-2017 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/** @var $installer Mage_Customer_Model_Entity_Setup */
+$installer = $this;
+$installer->startSetup();
+
+$installer->addAttribute('customer', 'password_created_at', array(
+    'label'    => 'Password created at',
+    'visible'  => false,
+    'required' => false,
+    'type'     => 'int'
+));
+
+$installer->endSetup();
diff --git app/code/core/Mage/Downloadable/etc/config.xml app/code/core/Mage/Downloadable/etc/config.xml
index ae685e8..5904169 100644
--- app/code/core/Mage/Downloadable/etc/config.xml
+++ app/code/core/Mage/Downloadable/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Mage_Downloadable>
-            <version>1.4.0.2</version>
+            <version>1.4.0.2.1.2</version>
         </Mage_Downloadable>
     </modules>
     <global>
@@ -349,7 +349,7 @@
                 <samples_title>Samples</samples_title>
                 <links_title>Links</links_title>
                 <links_target_new_window>1</links_target_new_window>
-                <content_disposition>inline</content_disposition>
+                <content_disposition>attachment</content_disposition>
                 <disable_guest_checkout>1</disable_guest_checkout>
             </downloadable>
         </catalog>
diff --git app/code/core/Mage/Downloadable/etc/system.xml app/code/core/Mage/Downloadable/etc/system.xml
index 19d42d6..c01d637 100644
--- app/code/core/Mage/Downloadable/etc/system.xml
+++ app/code/core/Mage/Downloadable/etc/system.xml
@@ -96,6 +96,7 @@
                             <show_in_default>1</show_in_default>
                             <show_in_website>1</show_in_website>
                             <show_in_store>1</show_in_store>
+                            <comment>Using inline option could potentially lead to security issues.</comment>
                         </content_disposition>
                         <disable_guest_checkout translate="label comment">
                             <label>Disable Guest Checkout if Cart Contains Downloadable Items</label>
diff --git app/code/core/Mage/Downloadable/sql/downloadable_setup/mysql4-upgrade-1.4.0.2.1.1-1.4.0.2.1.2.php app/code/core/Mage/Downloadable/sql/downloadable_setup/mysql4-upgrade-1.4.0.2.1.1-1.4.0.2.1.2.php
new file mode 100644
index 0000000..1965116
--- /dev/null
+++ app/code/core/Mage/Downloadable/sql/downloadable_setup/mysql4-upgrade-1.4.0.2.1.1-1.4.0.2.1.2.php
@@ -0,0 +1,35 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Downloadable
+ * @copyright  Copyright (c) 2006-2017 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/** @var $installer Mage_Core_Model_Resource_Setup */
+$installer = $this;
+$installer->startSetup();
+$connection = $installer->getConnection();
+$connection->delete(
+    $installer->getTable('core_config_data'),
+    $installer->getConnection()->quoteInto('path LIKE ?', 'catalog/downloadable/content_disposition')
+);
+$installer->endSetup();
diff --git app/code/core/Mage/Shipping/Model/Info.php app/code/core/Mage/Shipping/Model/Info.php
index 9501012..cb4ab55 100644
--- app/code/core/Mage/Shipping/Model/Info.php
+++ app/code/core/Mage/Shipping/Model/Info.php
@@ -79,7 +79,7 @@ class Mage_Shipping_Model_Info extends Varien_Object
     {
         $order = Mage::getModel('sales/order')->load($this->getOrderId());
 
-        if (!$order->getId() || $this->getProtectCode() != $order->getProtectCode()) {
+        if (!$order->getId() || $this->getProtectCode() !== $order->getProtectCode()) {
             return false;
         }
 
@@ -96,7 +96,7 @@ class Mage_Shipping_Model_Info extends Varien_Object
         /* @var $model Mage_Sales_Model_Order_Shipment */
         $model = Mage::getModel('sales/order_shipment');
         $ship = $model->load($this->getShipId());
-        if (!$ship->getEntityId() || $this->getProtectCode() != $ship->getProtectCode()) {
+        if (!$ship->getEntityId() || $this->getProtectCode() !== $ship->getProtectCode()) {
             return false;
         }
 
@@ -159,7 +159,7 @@ class Mage_Shipping_Model_Info extends Varien_Object
     public function getTrackingInfoByTrackId()
     {
         $track = Mage::getModel('sales/order_shipment_track')->load($this->getTrackId());
-        if ($track->getId() && $this->getProtectCode() == $track->getProtectCode()) {
+        if ($track->getId() && $this->getProtectCode() === $track->getProtectCode()) {
             $this->_trackingInfo = array(array($track->getNumberDetail()));
         }
         return $this->_trackingInfo;
diff --git app/code/core/Mage/Widget/controllers/Adminhtml/Widget/InstanceController.php app/code/core/Mage/Widget/controllers/Adminhtml/Widget/InstanceController.php
index 1a9a8c2..b719dd1 100644
--- app/code/core/Mage/Widget/controllers/Adminhtml/Widget/InstanceController.php
+++ app/code/core/Mage/Widget/controllers/Adminhtml/Widget/InstanceController.php
@@ -161,7 +161,7 @@ class Mage_Widget_Adminhtml_Widget_InstanceController extends Mage_Adminhtml_Con
             ->setStoreIds($this->getRequest()->getPost('store_ids', array(0)))
             ->setSortOrder($this->getRequest()->getPost('sort_order', 0))
             ->setPageGroups($this->getRequest()->getPost('widget_instance'))
-            ->setWidgetParameters($this->getRequest()->getPost('parameters'));
+            ->setWidgetParameters($this->_prepareParameters());
         try {
             $widgetInstance->save();
             $this->_getSession()->addSuccess(
@@ -290,4 +290,20 @@ class Mage_Widget_Adminhtml_Widget_InstanceController extends Mage_Adminhtml_Con
     {
         return Mage::getSingleton('admin/session')->isAllowed('cms/widget_instance');
     }
+
+    /**
+     * Prepare widget parameters
+     *
+     * @return array
+     */
+    protected function _prepareParameters() {
+        $result = array();
+        $parameters = $this->getRequest()->getPost('parameters');
+        if(is_array($parameters) && count($parameters)) {
+            foreach ($parameters as $key => $value) {
+                $result[Mage::helper('core')->stripTags($key)] = $value;
+            }
+        }
+        return $result;
+    }
 }
diff --git app/design/adminhtml/default/default/template/catalog/product/attribute/set/main.phtml app/design/adminhtml/default/default/template/catalog/product/attribute/set/main.phtml
index b654eaf..5f1060a 100644
--- app/design/adminhtml/default/default/template/catalog/product/attribute/set/main.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/attribute/set/main.phtml
@@ -115,6 +115,23 @@
                             cls:'folder'
                         });
 
+                        this.ge.completeEdit = function(remainVisible) {
+                            if (!this.editing) {
+                                return;
+                            }
+                            this.editNode.attributes.input = this.getValue();
+                            this.setValue(this.getValue().escapeHTML());
+                            return Ext.tree.TreeEditor.prototype.completeEdit.call(this, remainVisible);
+                        };
+
+                        this.ge.triggerEdit = function(node) {
+                            this.completeEdit();
+                            node.text = node.attributes.input;
+                            node.attributes.text = node.attributes.input;
+                            this.editNode = node;
+                            this.startEdit(node.ui.textNode, node.text);
+                        };
+
                         this.root.addListener('beforeinsert', editSet.leftBeforeInsert);
                         this.root.addListener('beforeappend', editSet.leftBeforeInsert);
 
@@ -161,7 +178,7 @@
                         for( i in rootNode.childNodes ) {
                             if(rootNode.childNodes[i].id) {
                                 var group = rootNode.childNodes[i];
-                                editSet.req.groups[gIterator] = new Array(group.id, group.attributes.text.strip(), (gIterator+1));
+                                editSet.req.groups[gIterator] = new Array(group.id, group.attributes.input.strip(), (gIterator+1));
                                 var iterator = 0
                                 for( j in group.childNodes ) {
                                     iterator ++;
@@ -194,6 +211,8 @@
                 if (!config) return null;
                 if (parent && config && config.length){
                     for (var i = 0; i < config.length; i++) {
+                        config[i].input = config[i].text;
+                        config[i].text = config[i].text.escapeHTML();
                         var node = new Ext.tree.TreeNode(config[i]);
                         parent.appendChild(node);
                         node.addListener('click', editSet.register);
@@ -295,6 +314,7 @@
 
                             var newNode = new Ext.tree.TreeNode({
                                     text : group_name.escapeHTML(),
+                                    input: group_name,
                                     cls : 'folder',
                                     allowDrop : true,
                                     allowDrag : true
diff --git app/design/adminhtml/default/default/template/customer/tab/view.phtml app/design/adminhtml/default/default/template/customer/tab/view.phtml
index b405e39..3e30f71 100644
--- app/design/adminhtml/default/default/template/customer/tab/view.phtml
+++ app/design/adminhtml/default/default/template/customer/tab/view.phtml
@@ -66,7 +66,7 @@ $createDateStore    = $this->getStoreCreateDate();
             <?php endif; ?>
             <tr>
                 <td><strong><?php echo $this->__('Account Created in:') ?></strong></td>
-                <td><?php echo $this->getCreatedInStore() ?></td>
+                <td><?php echo $this->escapeHtml($this->getCreatedInStore()); ?></td>
             </tr>
             <tr>
                 <td><strong><?php echo $this->__('Customer Group:') ?></strong></td>
diff --git app/design/adminhtml/default/default/template/customer/tab/view/sales.phtml app/design/adminhtml/default/default/template/customer/tab/view/sales.phtml
index fb7c559..498911e 100644
--- app/design/adminhtml/default/default/template/customer/tab/view/sales.phtml
+++ app/design/adminhtml/default/default/template/customer/tab/view/sales.phtml
@@ -53,18 +53,18 @@
                         <?php $_groupRow = false; ?>
                         <?php foreach ($_stores as $_row): ?>
                         <?php if ($_row->getStoreId() == 0): ?>
-                        <td colspan="3" class="label"><?php echo $_row->getStoreName() ?></td>
+                        <td colspan="3" class="label"><?php echo $this->escapeHtml($_row->getStoreName()); ?></td>
                         <?php else: ?>
                 <tr<?php echo ($_i++ % 2 ? ' class="even"' : '') ?>>
                         <?php if (!$_websiteRow): ?>
-                    <td rowspan="<?php echo $this->getWebsiteCount($_websiteId) ?>"><?php echo $_row->getWebsiteName() ?></td>
+                    <td rowspan="<?php echo $this->getWebsiteCount($_websiteId) ?>"><?php echo $this->escapeHtml($_row->getWebsiteName()); ?></td>
                             <?php $_websiteRow = true; ?>
                         <?php endif; ?>
                         <?php if (!$_groupRow): ?>
-                    <td rowspan="<?php echo count($_stores) ?>"><?php echo $_row->getGroupName() ?></td>
+                    <td rowspan="<?php echo count($_stores) ?>"><?php echo $this->escapeHtml($_row->getGroupName()); ?></td>
                             <?php $_groupRow = true; ?>
                         <?php endif; ?>
-                    <td class="label"><?php echo $_row->getStoreName() ?></td>
+                    <td class="label"><?php echo $this->escapeHtml($_row->getStoreName()); ?></td>
                         <?php endif; ?>
                     <td><?php echo $this->formatCurrency($_row->getLifetime(), $_row->getWebsiteId()) ?></td>
                     <td><?php echo $this->formatCurrency($_row->getAvgsale(), $_row->getWebsiteId()) ?></td>
diff --git app/design/adminhtml/default/default/template/dashboard/store/switcher.phtml app/design/adminhtml/default/default/template/dashboard/store/switcher.phtml
index 427cf19..30318a4 100644
--- app/design/adminhtml/default/default/template/dashboard/store/switcher.phtml
+++ app/design/adminhtml/default/default/template/dashboard/store/switcher.phtml
@@ -34,14 +34,14 @@
             <?php foreach ($this->getStoreCollection($_group) as $_store): ?>
                 <?php if ($showWebsite == false): ?>
                     <?php $showWebsite = true; ?>
-                    <option website="true" value="<?php echo $_website->getId() ?>"<?php if($this->getRequest()->getParam('website') == $_website->getId()): ?> selected="selected"<?php endif; ?>><?php echo $_website->getName() ?></option>
+                    <option website="true" value="<?php echo $_website->getId() ?>"<?php if($this->getRequest()->getParam('website') == $_website->getId()): ?> selected="selected"<?php endif; ?>><?php echo $this->escapeHtml($_website->getName()); ?></option>
                 <?php endif; ?>
                 <?php if ($showGroup == false): ?>
                     <?php $showGroup = true; ?>
-                    <!--optgroup label="&nbsp;&nbsp;&nbsp;<?php echo $_group->getName() ?>"-->
-                    <option group="true" value="<?php echo $_group->getId() ?>"<?php if($this->getRequest()->getParam('group') == $_group->getId()): ?> selected="selected"<?php endif; ?>>&nbsp;&nbsp;&nbsp;<?php echo $_group->getName() ?></option>
+                    <!--optgroup label="&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_group->getName()); ?>"-->
+                    <option group="true" value="<?php echo $_group->getId() ?>"<?php if($this->getRequest()->getParam('group') == $_group->getId()): ?> selected="selected"<?php endif; ?>>&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_group->getName()); ?></option>
                 <?php endif; ?>
-                <option value="<?php echo $_store->getId() ?>"<?php if($this->getStoreId() == $_store->getId()): ?> selected="selected"<?php endif; ?>>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $_store->getName() ?></option>
+                <option value="<?php echo $_store->getId() ?>"<?php if($this->getStoreId() == $_store->getId()): ?> selected="selected"<?php endif; ?>>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_store->getName()); ?></option>
             <?php endforeach; ?>
             <?php if ($showGroup): ?>
                 <!--</optgroup>-->
diff --git app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/links.phtml app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/links.phtml
index 5ce50cc..e94dadd 100644
--- app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/links.phtml
+++ app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/links.phtml
@@ -38,7 +38,7 @@
             <td class="label"><label for="name"><?php echo Mage::helper('downloadable')->__('Title')?></label>
             </td>
             <td class="value">
-                <input type="text" class="input-text" id="downloadable_links_title" name="product[links_title]" value="<?php echo $_product->getId()?$_product->getLinksTitle():$this->getLinksTitle() ?>" <?php echo ($_product->getStoreId() && $this->getUsedDefault())?'disabled="disabled"':'' ?> />
+                <input type="text" class="input-text" id="downloadable_links_title" name="product[links_title]" value="<?php echo $_product->getId() ? $this->escapeHtml($_product->getLinksTitle()) : $this->escapeHtml($this->getLinksTitle()); ?>" <?php echo ($_product->getStoreId() && $this->getUsedDefault())?'disabled="disabled"':'' ?> />
             </td>
             <td class="scope-label"><?php if (!Mage::app()->isSingleStoreMode()): ?>[STORE VIEW]<?php endif; ?></td>
             <td class="value use-default">
diff --git app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/creditmemo/name.phtml app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/creditmemo/name.phtml
index f1924d8..940da37 100644
--- app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/creditmemo/name.phtml
+++ app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/creditmemo/name.phtml
@@ -52,7 +52,7 @@
     <?php endif; ?>
     <?php if ($this->getLinks()): ?>
         <dl class="item-options">
-            <dt><?php echo $this->getLinksTitle(); ?></dt>
+            <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
             <?php foreach ($this->getLinks()->getPurchasedItems() as $_link): ?>
                 <dd><?php echo $_link->getLinkTitle() ?></dd>
             <?php endforeach; ?>
diff --git app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/invoice/name.phtml app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/invoice/name.phtml
index b83ca27..41bb930 100644
--- app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/invoice/name.phtml
+++ app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/invoice/name.phtml
@@ -52,7 +52,7 @@
     <?php endif; ?>
     <?php if ($this->getLinks()): ?>
         <dl class="item-options">
-            <dt><?php echo $this->getLinksTitle(); ?></dt>
+            <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
             <?php foreach ($this->getLinks()->getPurchasedItems() as $_link): ?>
                 <dd><?php echo $_link->getLinkTitle() ?> (<?php echo $_link->getNumberOfDownloadsBought()?$_link->getNumberOfDownloadsBought():Mage::helper('downloadable')->__('Unlimited') ?>)</dd>
             <?php endforeach; ?>
diff --git app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/name.phtml app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/name.phtml
index b494aff..d0514fa 100644
--- app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/name.phtml
+++ app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/name.phtml
@@ -52,7 +52,7 @@
     <?php endif; ?>
     <?php if ($this->getLinks()): ?>
         <dl class="item-options">
-            <dt><?php echo $this->getLinksTitle(); ?></dt>
+            <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
             <?php foreach ($this->getLinks()->getPurchasedItems() as $_link): ?>
                 <dd><?php echo $_link->getLinkTitle() ?> (<?php echo $_link->getNumberOfDownloadsUsed() . ' / ' . ($_link->getNumberOfDownloadsBought()?$_link->getNumberOfDownloadsBought():Mage::helper('downloadable')->__('U')) ?>)</dd>
             <?php endforeach; ?>
diff --git app/design/adminhtml/default/default/template/report/store/switcher.phtml app/design/adminhtml/default/default/template/report/store/switcher.phtml
index bf74dae..4a40d8d 100644
--- app/design/adminhtml/default/default/template/report/store/switcher.phtml
+++ app/design/adminhtml/default/default/template/report/store/switcher.phtml
@@ -40,14 +40,14 @@
             <?php foreach ($this->getStoreCollection($_group) as $_store): ?>
                 <?php if ($showWebsite == false): ?>
                     <?php $showWebsite = true; ?>
-                    <option website="true" value="<?php echo $_website->getId() ?>"<?php if($this->getRequest()->getParam('website') == $_website->getId()): ?> selected<?php endif; ?>><?php echo $_website->getName() ?></option>
+                    <option website="true" value="<?php echo $_website->getId() ?>"<?php if($this->getRequest()->getParam('website') == $_website->getId()): ?> selected<?php endif; ?>><?php echo $this->escapeHtml($_website->getName()); ?></option>
                 <?php endif; ?>
                 <?php if ($showGroup == false): ?>
                     <?php $showGroup = true; ?>
-                    <!--optgroup label="&nbsp;&nbsp;&nbsp;<?php echo $_group->getName() ?>"-->
-                    <option group="true" value="<?php echo $_group->getId() ?>"<?php if($this->getRequest()->getParam('group') == $_group->getId()): ?> selected<?php endif; ?>>&nbsp;&nbsp;&nbsp;<?php echo $_group->getName() ?></option>
+                    <!--optgroup label="&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_group->getName()); ?>"-->
+                    <option group="true" value="<?php echo $_group->getId() ?>"<?php if($this->getRequest()->getParam('group') == $_group->getId()): ?> selected<?php endif; ?>>&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_group->getName()); ?></option>
                 <?php endif; ?>
-                <option value="<?php echo $_store->getId() ?>"<?php if($this->getStoreId() == $_store->getId()): ?> selected<?php endif; ?>>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $_store->getName() ?></option>
+                <option value="<?php echo $_store->getId() ?>"<?php if($this->getStoreId() == $_store->getId()): ?> selected<?php endif; ?>>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_store->getName()); ?></option>
             <?php endforeach; ?>
             <?php if ($showGroup): ?>
                 </optgroup>
diff --git app/design/adminhtml/default/default/template/sales/order/view/info.phtml app/design/adminhtml/default/default/template/sales/order/view/info.phtml
index 16ca210..db2f4ed 100644
--- app/design/adminhtml/default/default/template/sales/order/view/info.phtml
+++ app/design/adminhtml/default/default/template/sales/order/view/info.phtml
@@ -63,7 +63,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
             </tr>
             <tr>
                 <td class="label"><label><?php echo Mage::helper('sales')->__('Purchased From') ?></label></td>
-                <td class="value"><strong><?php echo $this->getOrderStoreName() ?></strong></td>
+                <td class="value"><strong><?php echo $this->getOrderStoreName(); ?></strong></td>
             </tr>
             <?php if($_order->getRelationChildId()): ?>
             <tr>
diff --git app/design/adminhtml/default/default/template/store/switcher.phtml app/design/adminhtml/default/default/template/store/switcher.phtml
index cc54991..1a82f2c 100644
--- app/design/adminhtml/default/default/template/store/switcher.phtml
+++ app/design/adminhtml/default/default/template/store/switcher.phtml
@@ -28,7 +28,7 @@
 <p class="switcher"><label for="store_switcher"><?php echo $this->__('Choose Store View') ?>:</label>
 <select name="store_switcher" id="store_switcher" onchange="return switchStore(this);">
 <?php if ($this->hasDefaultOption()): ?>
-    <option value=""><?php echo $this->getDefaultStoreName() ?></option>
+    <option value=""><?php echo $this->escapeHtml($this->getDefaultStoreName()); ?></option>
 <?php endif; ?>
     <?php foreach ($websites as $website): ?>
         <?php $showWebsite=false; ?>
diff --git app/design/adminhtml/default/default/template/store/switcher/enhanced.phtml app/design/adminhtml/default/default/template/store/switcher/enhanced.phtml
index 2a0400d..3a712b8 100644
--- app/design/adminhtml/default/default/template/store/switcher/enhanced.phtml
+++ app/design/adminhtml/default/default/template/store/switcher/enhanced.phtml
@@ -29,7 +29,7 @@
 <div id="store_switcher_container">
 <p class="switcher"><label for="store_switcher"><?php echo $this->__('Choose Store View') ?>:</label>
 <select name="store_switcher" id="store_switcher" class="left-col-block">
-    <option value=""><?php echo $this->getDefaultStoreName() ?></option>
+    <option value=""><?php echo $this->escapeHtml($this->getDefaultStoreName()); ?></option>
     <?php foreach ($_websiteCollection as $_website): ?>
         <?php $showWebsite=false; ?>
         <?php foreach ($this->getGroupCollection($_website) as $_group): ?>
@@ -37,13 +37,13 @@
             <?php foreach ($this->getStoreCollection($_group) as $_store): ?>
                 <?php if ($showWebsite == false): ?>
                     <?php $showWebsite = true; ?>
-                    <optgroup label="<?php echo $_website->getName() ?>"></optgroup>
+                    <optgroup label="<?php echo $this->escapeHtml($_website->getName()); ?>"></optgroup>
                 <?php endif; ?>
                 <?php if ($showGroup == false): ?>
                     <?php $showGroup = true; ?>
-                    <optgroup label="&nbsp;&nbsp;&nbsp;<?php echo $_group->getName() ?>">
+                    <optgroup label="&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_group->getName()); ?>">
                 <?php endif; ?>
-                <option group="<?php echo $_group->getId() ?>" value="<?php echo $_store->getId() ?>"<?php if($this->getStoreId() == $_store->getId()): ?> selected="selected"<?php endif; ?>>&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $_store->getName() ?></option>
+                <option group="<?php echo $_group->getId() ?>" value="<?php echo $_store->getId(); ?>"<?php if($this->getStoreId() == $_store->getId()): ?> selected="selected"<?php endif; ?>>&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_store->getName()); ?></option>
             <?php endforeach; ?>
             <?php if ($showGroup): ?>
                 </optgroup>
diff --git app/design/adminhtml/default/default/template/system/convert/profile/wizard.phtml app/design/adminhtml/default/default/template/system/convert/profile/wizard.phtml
index f825296..54dc24b 100644
--- app/design/adminhtml/default/default/template/system/convert/profile/wizard.phtml
+++ app/design/adminhtml/default/default/template/system/convert/profile/wizard.phtml
@@ -203,9 +203,9 @@ Event.observe(window, 'load', function(){
                                 <?php endif; ?>
                                 <?php if (!$_groupShow): ?>
                                     <?php $_groupShow=true; ?>
-                                    <optgroup label="&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $_group->getName() ?>">
+                                    <optgroup label="&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_group->getName()); ?>">
                                 <?php endif; ?>
-                                <option value="<?php echo $_store->getId() ?>" <?php echo $this->getSelected('store_id', $_store->getId()) ?>>&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $_store->getName() ?></option>
+                                <option value="<?php echo $_store->getId() ?>" <?php echo $this->getSelected('store_id', $_store->getId()) ?>>&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($_store->getName()); ?></option>
                             <?php endforeach; ?>
                             <?php if ($_groupShow): ?>
                                 </optgroup>
diff --git app/design/adminhtml/default/default/template/tax/rate/title.phtml app/design/adminhtml/default/default/template/tax/rate/title.phtml
index 377e810..8a2771a 100644
--- app/design/adminhtml/default/default/template/tax/rate/title.phtml
+++ app/design/adminhtml/default/default/template/tax/rate/title.phtml
@@ -27,7 +27,7 @@
 <?php /* <table class="dynamic-grid" cellspacing="0" id="tax-rate-titles-table"> */ ?>
     <tr class="dynamic-grid">
     <?php foreach ($this->getStores() as $_store): ?>
-        <th><?php echo $_store->getName() ?></th>
+        <th><?php echo $this->escapeHtml($_store->getName()); ?></th>
     <?php endforeach; ?>
     </tr>
     <tr class="dynamic-grid">
diff --git app/design/adminhtml/default/default/template/widget/form/renderer/fieldset.phtml app/design/adminhtml/default/default/template/widget/form/renderer/fieldset.phtml
index 43db749..01908d9 100644
--- app/design/adminhtml/default/default/template/widget/form/renderer/fieldset.phtml
+++ app/design/adminhtml/default/default/template/widget/form/renderer/fieldset.phtml
@@ -30,7 +30,7 @@
 <?php endif; ?>
 <?php if ($_element->getLegend()): ?>
 <div class="entry-edit-head">
-    <h4 class="icon-head head-edit-form fieldset-legend"><?php echo $_element->getLegend() ?></h4>
+    <h4 class="icon-head head-edit-form fieldset-legend"><?php echo $this->escapeHtml($_element->getLegend()) ?></h4>
     <div class="form-buttons"><?php echo $_element->getHeaderBar() ?></div>
 </div>
 <?php endif; ?>
diff --git app/locale/en_US/Mage_Catalog.csv app/locale/en_US/Mage_Catalog.csv
index 7a6e4e5..646cb24 100644
--- app/locale/en_US/Mage_Catalog.csv
+++ app/locale/en_US/Mage_Catalog.csv
@@ -617,6 +617,7 @@
 "The product has been deleted.","The product has been deleted."
 "The product has been duplicated.","The product has been duplicated."
 "The product has been saved.","The product has been saved."
+"HTML tags are not allowed in SKU attribute.","HTML tags are not allowed in SKU attribute."
 "The product has required options","The product has required options"
 "The review has been deleted","The review has been deleted"
 "The review has been saved.","The review has been saved."
diff --git lib/Zend/Mail/Transport/Sendmail.php lib/Zend/Mail/Transport/Sendmail.php
index b27f81d..c495e08 100644
--- lib/Zend/Mail/Transport/Sendmail.php
+++ lib/Zend/Mail/Transport/Sendmail.php
@@ -119,8 +119,9 @@ class Zend_Mail_Transport_Sendmail extends Zend_Mail_Transport_Abstract
                 );
             }
 
+            $fromEmailHeader = str_replace(' ', '', $this->parameters);
             // Sanitize the From header
-            if (!Zend_Validate::is(str_replace(' ', '', $this->parameters), 'EmailAddress')) {
+            if (!Zend_Validate::is($fromEmailHeader, 'EmailAddress')) {
                 throw new Zend_Mail_Transport_Exception('Potential code injection in From header');
             } else {
                 set_error_handler(array($this, '_handleMailErrors'));
@@ -129,7 +130,7 @@ class Zend_Mail_Transport_Sendmail extends Zend_Mail_Transport_Abstract
                     $this->_mail->getSubject(),
                     $this->body,
                     $this->header,
-                    $this->parameters);
+                    $fromEmailHeader);
                 restore_error_handler();
             }
         }
