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


SUPEE-10570_CE_v1.9.1.1 | CE_1.9.1.1 | v1 | 7c59b058454d756e1c16a29bd3b46b5308c60d81 | Fri Mar 16 13:17:16 2018 +0200 | ce-1.9.1.1-dev

__PATCHFILE_FOLLOWS__
diff --git app/Mage.php app/Mage.php
index 8b496a6..694a8b1 100644
--- app/Mage.php
+++ app/Mage.php
@@ -844,6 +844,7 @@ final class Mage
                 $message = print_r($message, true);
             }
 
+            $message = addcslashes($message, '<?');
             $loggers[$file]->log($message, $level);
         }
         catch (Exception $e) {
diff --git app/code/core/Mage/Admin/Helper/Data.php app/code/core/Mage/Admin/Helper/Data.php
index 0cc2f6b..babcab6 100644
--- app/code/core/Mage/Admin/Helper/Data.php
+++ app/code/core/Mage/Admin/Helper/Data.php
@@ -58,4 +58,14 @@ class Mage_Admin_Helper_Data extends Mage_Core_Helper_Abstract
     {
         return (int) Mage::getConfig()->getNode(self::XML_PATH_ADMIN_RESET_PASSWORD_LINK_EXPIRATION_PERIOD);
     }
+
+    /**
+     *  Get disallowed names for block
+     *
+     * @return bool
+     */
+    public function getDisallowedBlockNames()
+    {
+        return Mage::getResourceModel('admin/block')->getDisallowedBlockNames();
+    }
 }
diff --git app/code/core/Mage/Admin/Model/Block.php app/code/core/Mage/Admin/Model/Block.php
index b33db1b..a672f4e 100644
--- app/code/core/Mage/Admin/Model/Block.php
+++ app/code/core/Mage/Admin/Model/Block.php
@@ -53,6 +53,10 @@ class Mage_Admin_Model_Block extends Mage_Core_Model_Abstract
         if (!Zend_Validate::is($this->getBlockName(), 'NotEmpty')) {
             $errors[] = Mage::helper('adminhtml')->__('Block Name is required field.');
         }
+        $disallowedBlockNames = Mage::helper('admin')->getDisallowedBlockNames();
+        if (in_array($this->getBlockName(), $disallowedBlockNames)) {
+            $errors[] = Mage::helper('adminhtml')->__('Block Name is disallowed.');
+        }
         if (!Zend_Validate::is($this->getBlockName(), 'Regex', array('/^[-_a-zA-Z0-9\/]*$/'))) {
             $errors[] = Mage::helper('adminhtml')->__('Block Name is incorrect.');
         }
diff --git app/code/core/Mage/Admin/Model/Resource/Block.php app/code/core/Mage/Admin/Model/Resource/Block.php
index 99b1c33..2e3e699 100644
--- app/code/core/Mage/Admin/Model/Resource/Block.php
+++ app/code/core/Mage/Admin/Model/Resource/Block.php
@@ -33,6 +33,14 @@
  */
 class Mage_Admin_Model_Resource_Block extends Mage_Core_Model_Resource_Db_Abstract
 {
+
+    /**
+     * Disallowed names for block
+     *
+     * @var array
+     */
+    protected $disallowedBlockNames = array('install/end');
+
     /**
      * Define main table
      *
@@ -41,4 +49,14 @@ class Mage_Admin_Model_Resource_Block extends Mage_Core_Model_Resource_Db_Abstra
     {
         $this->_init('admin/permission_block', 'block_id');
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
index b88fdf8..dd9c2bb 100644
--- app/code/core/Mage/Admin/Model/User.php
+++ app/code/core/Mage/Admin/Model/User.php
@@ -374,7 +374,7 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
     /**
      * Login user
      *
-     * @param   string $login
+     * @param   string $username
      * @param   string $password
      * @return  Mage_Admin_Model_User
      */
@@ -382,6 +382,7 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
     {
         if ($this->authenticate($username, $password)) {
             $this->getResource()->recordLogin($this);
+            Mage::getSingleton('core/session')->renewFormKey();
         }
         return $this;
     }
diff --git app/code/core/Mage/Adminhtml/Block/Catalog/Product/Grid.php app/code/core/Mage/Adminhtml/Block/Catalog/Product/Grid.php
index 18b6c83..9322db9 100644
--- app/code/core/Mage/Adminhtml/Block/Catalog/Product/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Catalog/Product/Grid.php
@@ -161,7 +161,7 @@ class Mage_Adminhtml_Block_Catalog_Product_Grid extends Mage_Adminhtml_Block_Wid
         if ($store->getId()) {
             $this->addColumn('custom_name',
                 array(
-                    'header'=> Mage::helper('catalog')->__('Name in %s', $store->getName()),
+                    'header'=> Mage::helper('catalog')->__('Name in %s', $this->escapeHtml($store->getName())),
                     'index' => 'custom_name',
             ));
         }
diff --git app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Grid/Renderer/Sender.php app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Grid/Renderer/Sender.php
index e6b5f6d..10cb9da 100644
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
index d1244b3..e861ddc 100644
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
index b32c7bb..1172435 100644
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
index 35e6e05..582d333 100644
--- app/code/core/Mage/Adminhtml/Block/System/Store/Edit/Form.php
+++ app/code/core/Mage/Adminhtml/Block/System/Store/Edit/Form.php
@@ -245,7 +245,7 @@ class Mage_Adminhtml_Block_System_Store_Edit_Form extends Mage_Adminhtml_Block_W
                             $values[] = array('label'=>$group->getName(),'value'=>$group->getId());
                         }
                     }
-                    $groups[] = array('label'=>$website->getName(),'value'=>$values);
+                    $groups[] = array('label' => $this->escapeHtml($website->getName()), 'value' => $values);
                 }
                 $fieldset->addField('store_group_id', 'select', array(
                     'name'      => 'store[group_id]',
diff --git app/code/core/Mage/Adminhtml/Block/Tag/Assigned/Grid.php app/code/core/Mage/Adminhtml/Block/Tag/Assigned/Grid.php
index 74b0409..9f53950 100644
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
index 7c93343..3031e59e 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Store.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Store.php
@@ -111,11 +111,11 @@ class Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Store
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
index 69df892..38af454 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Tabs.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Tabs.php
@@ -289,9 +289,9 @@ class Mage_Adminhtml_Block_Widget_Tabs extends Mage_Adminhtml_Block_Widget
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
index d173241..831d3c7 100644
--- app/code/core/Mage/Adminhtml/Model/Config/Data.php
+++ app/code/core/Mage/Adminhtml/Model/Config/Data.php
@@ -117,6 +117,7 @@ class Mage_Adminhtml_Model_Config_Data extends Varien_Object
             }
 
             foreach ($groupData['fields'] as $field => $fieldData) {
+                $field = ltrim($field, '/');
                 $fieldConfig = $sections->descend($section . '/groups/' . $group . '/fields/' . $field);
                 if (!$fieldConfig && $clonedFields && isset($mappedFields[$field])) {
                     $fieldConfig = $sections->descend($section . '/groups/' . $group . '/fields/'
diff --git app/code/core/Mage/Adminhtml/Model/System/Store.php app/code/core/Mage/Adminhtml/Model/System/Store.php
index ee0b517..a4dc14f 100644
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
index 08bae80..5512e7a 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
@@ -723,6 +723,16 @@ class Mage_Adminhtml_Catalog_ProductController extends Mage_Adminhtml_Controller
             $this->_filterStockData($data['product']['stock_data']);
 
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
index d089c85..52c8ccc 100644
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
index c5832ab..6772eb0 100644
--- app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
+++ app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
@@ -32,6 +32,7 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
     const VALIDATOR_HTTP_X_FORVARDED_FOR_KEY    = 'http_x_forwarded_for';
     const VALIDATOR_HTTP_VIA_KEY                = 'http_via';
     const VALIDATOR_REMOTE_ADDR_KEY             = 'remote_addr';
+    const VALIDATOR_SESSION_EXPIRE_TIMESTAMP    = 'session_expire_timestamp';
     const SECURE_COOKIE_CHECK_KEY               = '_secure_cookie_check';
 
     /**
@@ -383,6 +384,16 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
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
@@ -451,6 +462,15 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
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
 
@@ -484,6 +504,8 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
             $parts[self::VALIDATOR_HTTP_USER_AGENT_KEY] = (string)$_SERVER['HTTP_USER_AGENT'];
         }
 
+        $parts[self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP] = time() + $this->getCookie()->getLifetime();
+
         return $parts;
     }
 
diff --git app/code/core/Mage/Core/Model/Variable.php app/code/core/Mage/Core/Model/Variable.php
index d86edcd..65e8593 100644
--- app/code/core/Mage/Core/Model/Variable.php
+++ app/code/core/Mage/Core/Model/Variable.php
@@ -141,7 +141,10 @@ class Mage_Core_Model_Variable extends Mage_Core_Model_Abstract
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
index 88757a4..1df3e99 100644
--- app/code/core/Mage/Customer/etc/config.xml
+++ app/code/core/Mage/Customer/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Mage_Customer>
-            <version>1.6.2.0.3</version>
+            <version>1.6.2.0.3.1.2</version>
         </Mage_Customer>
     </modules>
     <admin>
diff --git app/code/core/Mage/Customer/sql/customer_setup/upgrade-1.6.2.0.3.1.1-1.6.2.0.3.1.2.php app/code/core/Mage/Customer/sql/customer_setup/upgrade-1.6.2.0.3.1.1-1.6.2.0.3.1.2.php
new file mode 100644
index 0000000..543bc81
--- /dev/null
+++ app/code/core/Mage/Customer/sql/customer_setup/upgrade-1.6.2.0.3.1.1-1.6.2.0.3.1.2.php
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
index 69e17bb..99fc53a 100644
--- app/code/core/Mage/Downloadable/etc/config.xml
+++ app/code/core/Mage/Downloadable/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Mage_Downloadable>
-            <version>1.6.0.0.2</version>
+            <version>1.6.0.0.2.1.2</version>
         </Mage_Downloadable>
     </modules>
     <global>
@@ -389,7 +389,7 @@
                 <samples_title>Samples</samples_title>
                 <links_title>Links</links_title>
                 <links_target_new_window>1</links_target_new_window>
-                <content_disposition>inline</content_disposition>
+                <content_disposition>attachment</content_disposition>
                 <disable_guest_checkout>1</disable_guest_checkout>
             </downloadable>
         </catalog>
diff --git app/code/core/Mage/Downloadable/etc/system.xml app/code/core/Mage/Downloadable/etc/system.xml
index 210c4ca..8b0674f 100644
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
diff --git app/code/core/Mage/Downloadable/sql/downloadable_setup/upgrade-1.6.0.0.2.1.1-1.6.0.0.2.1.2.php app/code/core/Mage/Downloadable/sql/downloadable_setup/upgrade-1.6.0.0.2.1.1-1.6.0.0.2.1.2.php
new file mode 100644
index 0000000..b2ac9a6
--- /dev/null
+++ app/code/core/Mage/Downloadable/sql/downloadable_setup/upgrade-1.6.0.0.2.1.1-1.6.0.0.2.1.2.php
@@ -0,0 +1,37 @@
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
+    $this->getTable('core_config_data'),
+    $connection->prepareSqlCondition('path', array(
+        'like' => 'catalog/downloadable/content_disposition'
+    ))
+);
+$installer->endSetup();
diff --git app/code/core/Mage/ImportExport/Model/Import.php app/code/core/Mage/ImportExport/Model/Import.php
index d802238..543c570 100644
--- app/code/core/Mage/ImportExport/Model/Import.php
+++ app/code/core/Mage/ImportExport/Model/Import.php
@@ -398,6 +398,10 @@ class Mage_ImportExport_Model_Import extends Mage_ImportExport_Model_Abstract
     public function uploadSource()
     {
         $entity    = $this->getEntity();
+        $validTypes = array_keys(Mage_ImportExport_Model_Config::getModels(self::CONFIG_KEY_ENTITIES));
+        if (!in_array($entity, $validTypes)) {
+            Mage::throwException(Mage::helper('importexport')->__('Incorrect entity type'));
+        }
         $uploader  = Mage::getModel('core/file_uploader', self::FIELD_NAME_SOURCE_FILE);
         $uploader->skipDbProcessing(true);
         $result    = $uploader->save(self::getWorkingDir());
diff --git app/code/core/Mage/ImportExport/Model/Import/Entity/Product.php app/code/core/Mage/ImportExport/Model/Import/Entity/Product.php
index 8ab3ad1..e336aa0 100644
--- app/code/core/Mage/ImportExport/Model/Import/Entity/Product.php
+++ app/code/core/Mage/ImportExport/Model/Import/Entity/Product.php
@@ -227,6 +227,11 @@ class Mage_ImportExport_Model_Import_Entity_Product extends Mage_ImportExport_Mo
      * Error - super products sku not found
      */
     const ERROR_SUPER_PRODUCTS_SKU_NOT_FOUND = 'superProductsSkuNotFound';
+
+    /**
+     * Error - invalid product sku
+     */
+    const ERROR_INVALID_PRODUCT_SKU          = 'invalidSku';
     /**#@-*/
 
     /**
@@ -315,7 +320,8 @@ class Mage_ImportExport_Model_Import_Entity_Product extends Mage_ImportExport_Mo
         self::ERROR_INVALID_TIER_PRICE_GROUP     => 'Tier Price customer group ID is invalid',
         self::ERROR_TIER_DATA_INCOMPLETE         => 'Tier Price data is incomplete',
         self::ERROR_SKU_NOT_FOUND_FOR_DELETE     => 'Product with specified SKU not found',
-        self::ERROR_SUPER_PRODUCTS_SKU_NOT_FOUND => 'Product with specified super products SKU not found'
+        self::ERROR_SUPER_PRODUCTS_SKU_NOT_FOUND => 'Product with specified super products SKU not found',
+        self::ERROR_INVALID_PRODUCT_SKU          => 'Invalid value in SKU column. HTML tags are not allowed'
     );
 
     /**
@@ -790,6 +796,22 @@ class Mage_ImportExport_Model_Import_Entity_Product extends Mage_ImportExport_Mo
     }
 
     /**
+     * Check product sku data.
+     *
+     * @param array $rowData
+     * @param int $rowNum
+     * @return bool
+     */
+    protected function _isProductSkuValid(array $rowData, $rowNum)
+    {
+        if (isset($rowData['sku']) && $rowData['sku'] != Mage::helper('core')->stripTags($rowData['sku'])) {
+            $this->addRowError(self::ERROR_INVALID_PRODUCT_SKU, $rowNum);
+            return false;
+        }
+        return true;
+    }
+
+    /**
      * Custom options save.
      *
      * @return Mage_ImportExport_Model_Import_Entity_Product
@@ -2100,6 +2122,7 @@ class Mage_ImportExport_Model_Import_Entity_Product extends Mage_ImportExport_Mo
         $this->_isTierPriceValid($rowData, $rowNum);
         $this->_isGroupPriceValid($rowData, $rowNum);
         $this->_isSuperProductsSkuValid($rowData, $rowNum);
+        $this->_isProductSkuValid($rowData, $rowNum);
     }
 
     /**
diff --git app/code/core/Mage/Shipping/Model/Info.php app/code/core/Mage/Shipping/Model/Info.php
index 442a765..2ed493f 100644
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
 
@@ -161,7 +161,7 @@ class Mage_Shipping_Model_Info extends Varien_Object
     public function getTrackingInfoByTrackId()
     {
         $track = Mage::getModel('sales/order_shipment_track')->load($this->getTrackId());
-        if ($track->getId() && $this->getProtectCode() == $track->getProtectCode()) {
+        if ($track->getId() && $this->getProtectCode() === $track->getProtectCode()) {
             $this->_trackingInfo = array(array($track->getNumberDetail()));
         }
         return $this->_trackingInfo;
diff --git app/code/core/Mage/Widget/controllers/Adminhtml/Widget/InstanceController.php app/code/core/Mage/Widget/controllers/Adminhtml/Widget/InstanceController.php
index c18dee5..deafc59 100644
--- app/code/core/Mage/Widget/controllers/Adminhtml/Widget/InstanceController.php
+++ app/code/core/Mage/Widget/controllers/Adminhtml/Widget/InstanceController.php
@@ -175,7 +175,7 @@ class Mage_Widget_Adminhtml_Widget_InstanceController extends Mage_Adminhtml_Con
             ->setStoreIds($this->getRequest()->getPost('store_ids', array(0)))
             ->setSortOrder($this->getRequest()->getPost('sort_order', 0))
             ->setPageGroups($this->getRequest()->getPost('widget_instance'))
-            ->setWidgetParameters($this->getRequest()->getPost('parameters'));
+            ->setWidgetParameters($this->_prepareParameters());
         try {
             $widgetInstance->save();
             $this->_getSession()->addSuccess(
@@ -304,4 +304,20 @@ class Mage_Widget_Adminhtml_Widget_InstanceController extends Mage_Adminhtml_Con
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
diff --git app/code/core/Mage/XmlConnect/Block/Adminhtml/Connect/Dashboard/StoreSwitcher.php app/code/core/Mage/XmlConnect/Block/Adminhtml/Connect/Dashboard/StoreSwitcher.php
index ca42326..3742f7c 100644
--- app/code/core/Mage/XmlConnect/Block/Adminhtml/Connect/Dashboard/StoreSwitcher.php
+++ app/code/core/Mage/XmlConnect/Block/Adminhtml/Connect/Dashboard/StoreSwitcher.php
@@ -74,7 +74,7 @@ class Mage_XmlConnect_Block_Adminhtml_Connect_Dashboard_StoreSwitcher extends Ma
 
         if ($this->hasDefaultOption()) {
             $this->_addSwitcherItem($switcherItemsXmlObj, Mage_XmlConnect_Helper_AdminApplication::ALL_STORE_VIEWS,
-                array('label' => $this->getDefaultStoreName(), 'level' => 1));
+                array('label' => $this->escapeHtml($this->getDefaultStoreName()), 'level' => 1));
         }
 
         foreach ($websites as $website) {
@@ -101,14 +101,14 @@ class Mage_XmlConnect_Block_Adminhtml_Connect_Dashboard_StoreSwitcher extends Ma
             if ($showWebsite == false) {
                 $showWebsite = true;
                 $this->_addSwitcherItem($switcherItemsXmlObj, null, array(
-                    'label' => $website->getName(), 'level' => 1
+                    'label' => $this->escapeHtml($website->getName()), 'level' => 1
                 ), true);
             }
 
             if ($showGroup == false) {
                 $showGroup = true;
                 $this->_addSwitcherItem($switcherItemsXmlObj, null, array(
-                    'label' => $group->getName(), 'level' => 2
+                    'label' => $this->escapeHtml($group->getName()), 'level' => 2
                 ), true);
             }
 
@@ -117,7 +117,7 @@ class Mage_XmlConnect_Block_Adminhtml_Connect_Dashboard_StoreSwitcher extends Ma
             }
 
             $this->_addSwitcherItem($switcherItemsXmlObj, $store->getId(), array(
-                'label' => $store->getName(), 'level' => 3
+                'label' => $this->escapeHtml($store->getName()), 'level' => 3
             ));
         }
         return $this;
diff --git app/design/adminhtml/default/default/template/catalog/product/attribute/options.phtml app/design/adminhtml/default/default/template/catalog/product/attribute/options.phtml
index 88f1fa2..47b0288 100644
--- app/design/adminhtml/default/default/template/catalog/product/attribute/options.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/attribute/options.phtml
@@ -51,7 +51,7 @@
             <table class="dynamic-grid" cellspacing="0" id="attribute-labels-table">
                 <tr>
                 <?php foreach ($this->getStores() as $_store): ?>
-                    <th><?php echo $_store->getName() ?></th>
+                    <th><?php echo $this->escapeHtml($_store->getName()); ?></th>
                 <?php endforeach; ?>
                 </tr>
                 <tr>
@@ -76,7 +76,7 @@
             <table class="dynamic-grid" cellspacing="0"  cellpadding="0">
                 <tr id="attribute-options-table">
                     <?php foreach ($this->getStores() as $_store): ?>
-                        <th><?php echo $_store->getName() ?></th>
+                        <th><?php echo $this->escapeHtml($_store->getName()); ?></th>
                     <?php endforeach; ?>
                         <th><?php echo Mage::helper('catalog')->__('Position') ?></th>
                         <th class="nobr a-center"><?php echo Mage::helper('catalog')->__('Is Default') ?></th>
diff --git app/design/adminhtml/default/default/template/catalog/product/attribute/set/main.phtml app/design/adminhtml/default/default/template/catalog/product/attribute/set/main.phtml
index c5ef93d..fd3a1cd 100644
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
index 7febfef..5a75882 100644
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
index 95152a5..2e45e6d 100644
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
index 1a32eb8..de47949 100644
--- app/design/adminhtml/default/default/template/dashboard/store/switcher.phtml
+++ app/design/adminhtml/default/default/template/dashboard/store/switcher.phtml
@@ -35,14 +35,14 @@
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
diff --git app/design/adminhtml/default/default/template/downloadable/product/composite/fieldset/downloadable.phtml app/design/adminhtml/default/default/template/downloadable/product/composite/fieldset/downloadable.phtml
index a04bc7f..a35a398 100644
--- app/design/adminhtml/default/default/template/downloadable/product/composite/fieldset/downloadable.phtml
+++ app/design/adminhtml/default/default/template/downloadable/product/composite/fieldset/downloadable.phtml
@@ -35,7 +35,7 @@
         <dl>
         <?php $_links = $this->getLinks(); ?>
         <?php $_isRequired = $this->getLinkSelectionRequired(); ?>
-            <dt><label<?php if ($_isRequired) echo ' class="required"' ?>><?php if ($_isRequired) echo '<em>*</em>' ?><?php echo $this->getLinksTitle() ?></label></dt>
+            <dt><label<?php if ($_isRequired) echo ' class="required"' ?>><?php if ($_isRequired) echo '<em>*</em>' ?><?php echo $this->escapeHtml($this->getLinksTitle()); ?></label></dt>
             <dd class="last">
                 <ul id="downloadable-links-list" class="options-list">
                 <?php foreach ($_links as $_link): ?>
diff --git app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/links.phtml app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/links.phtml
index 8aa6d39..e524a9c 100644
--- app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/links.phtml
+++ app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/links.phtml
@@ -39,7 +39,7 @@
             <td class="label"><label for="name"><?php echo Mage::helper('downloadable')->__('Title')?></label>
             </td>
             <td class="value">
-                <input type="text" class="input-text" id="downloadable_links_title" name="product[links_title]" value="<?php echo $_product->getId()?$_product->getLinksTitle():$this->getLinksTitle() ?>" <?php echo ($_product->getStoreId() && $this->getUsedDefault())?'disabled="disabled"':'' ?> />
+                <input type="text" class="input-text" id="downloadable_links_title" name="product[links_title]" value="<?php echo $_product->getId() ? $this->escapeHtml($_product->getLinksTitle()) : $this->escapeHtml($this->getLinksTitle()); ?>" <?php echo ($_product->getStoreId() && $this->getUsedDefault())?'disabled="disabled"':'' ?> />
             </td>
             <td class="scope-label"><?php echo !Mage::app()->isSingleStoreMode() ? Mage::helper('adminhtml')->__('[STORE VIEW]') : ''; ?></td>
             <td class="value use-default">
diff --git app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/creditmemo/name.phtml app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/creditmemo/name.phtml
index 42cfa47..76deda0 100644
--- app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/creditmemo/name.phtml
+++ app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/creditmemo/name.phtml
@@ -52,7 +52,7 @@
     <?php endif; ?>
     <?php if ($this->getLinks()): ?>
         <dl class="item-options">
-            <dt><?php echo $this->getLinksTitle(); ?></dt>
+            <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
             <?php foreach ($this->getLinks()->getPurchasedItems() as $_link): ?>
                 <dd><?php echo $this->escapeHtml($_link->getLinkTitle()); ?></dd>
             <?php endforeach; ?>
diff --git app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/invoice/name.phtml app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/invoice/name.phtml
index a286768..06b17c9 100644
--- app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/invoice/name.phtml
+++ app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/invoice/name.phtml
@@ -52,7 +52,7 @@
     <?php endif; ?>
     <?php if ($this->getLinks()): ?>
         <dl class="item-options">
-            <dt><?php echo $this->getLinksTitle(); ?></dt>
+            <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
             <?php foreach ($this->getLinks()->getPurchasedItems() as $_link): ?>
                 <dd><?php echo $this->escapeHtml($_link->getLinkTitle()); ?> (<?php echo $_link->getNumberOfDownloadsBought()?$_link->getNumberOfDownloadsBought():Mage::helper('downloadable')->__('Unlimited') ?>)</dd>
             <?php endforeach; ?>
diff --git app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/name.phtml app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/name.phtml
index aeef6e9..12e5dce 100644
--- app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/name.phtml
+++ app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/name.phtml
@@ -52,7 +52,7 @@
     <?php endif; ?>
     <?php if ($this->getLinks()): ?>
         <dl class="item-options">
-            <dt><?php echo $this->getLinksTitle(); ?></dt>
+            <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
             <?php foreach ($this->getLinks()->getPurchasedItems() as $_link): ?>
                 <dd><?php echo $this->escapeHtml($_link->getLinkTitle()) ?> (<?php echo $_link->getNumberOfDownloadsUsed() . ' / ' . ($_link->getNumberOfDownloadsBought()?$_link->getNumberOfDownloadsBought():Mage::helper('downloadable')->__('U')) ?>)</dd>
             <?php endforeach; ?>
diff --git app/design/adminhtml/default/default/template/eav/attribute/options.phtml app/design/adminhtml/default/default/template/eav/attribute/options.phtml
index 0a607e5..b290d0a 100644
--- app/design/adminhtml/default/default/template/eav/attribute/options.phtml
+++ app/design/adminhtml/default/default/template/eav/attribute/options.phtml
@@ -51,14 +51,14 @@
             <table class="dynamic-grid" cellspacing="0" id="attribute-labels-table">
                 <tr>
                 <?php foreach ($this->getStores() as $_store): ?>
-                    <th><?php echo $_store->getName() ?></th>
+                    <th><?php echo $this->escapeHtml($_store->getName()); ?></th>
                 <?php endforeach; ?>
                 </tr>
                 <tr>
                     <?php $_labels = $this->getLabelValues() ?>
                     <?php foreach ($this->getStores() as $_store): ?>
                     <td>
-                        <input class="input-text<?php if($_store->getId()==0): ?> required-option<?php endif; ?>" type="text" name="frontend_label[<?php echo $_store->getId() ?>]" value="<?php echo $this->htmlEscape($_labels[$_store->getId()]) ?>"<?php if ($this->getReadOnly()):?> disabled="disabled"<?php endif;?>/>
+                        <input class="input-text<?php if($_store->getId()==0): ?> required-option<?php endif; ?>" type="text" name="frontend_label[<?php echo $_store->getId() ?>]" value="<?php echo $this->escapeHtml($_labels[$_store->getId()]); ?>"<?php if ($this->getReadOnly()):?> disabled="disabled"<?php endif;?>/>
                     </td>
                     <?php endforeach; ?>
                 </tr>
@@ -76,7 +76,7 @@
             <table class="dynamic-grid" cellspacing="0"  cellpadding="0">
                 <tr id="attribute-options-table">
                     <?php foreach ($this->getStores() as $_store): ?>
-                        <th><?php echo $_store->getName() ?></th>
+                        <th><?php echo $this->escapeHtml($_store->getName()); ?></th>
                     <?php endforeach; ?>
                         <th><?php echo $this->__('Position') ?></th>
                         <th class="nobr a-center"><?php echo $this->__('Is Default') ?></th>
diff --git app/design/adminhtml/default/default/template/newsletter/preview/store.phtml app/design/adminhtml/default/default/template/newsletter/preview/store.phtml
index 39f7a5c..4ada797 100644
--- app/design/adminhtml/default/default/template/newsletter/preview/store.phtml
+++ app/design/adminhtml/default/default/template/newsletter/preview/store.phtml
@@ -35,13 +35,13 @@
             <?php foreach ($this->getStores($group) as $store): ?>
                 <?php if ($showWebsite == false): ?>
                     <?php $showWebsite = true; ?>
-                    <optgroup label="<?php echo $website->getName() ?>"></optgroup>
+                    <optgroup label="<?php echo $this->escapeHtml($website->getName()); ?>"></optgroup>
                 <?php endif; ?>
                 <?php if ($showGroup == false): ?>
                     <?php $showGroup = true; ?>
-                    <optgroup label="&nbsp;&nbsp;&nbsp;<?php echo $group->getName() ?>">
+                    <optgroup label="&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($group->getName()); ?>">
                 <?php endif; ?>
-                <option value="<?php echo $store->getId() ?>"<?php if($this->getStoreId() == $store->getId()): ?> selected="selected"<?php endif; ?>>&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $store->getName() ?></option>
+                <option value="<?php echo $store->getId() ?>"<?php if($this->getStoreId() == $store->getId()): ?> selected="selected"<?php endif; ?>>&nbsp;&nbsp;&nbsp;&nbsp;<?php echo $this->escapeHtml($store->getName()); ?></option>
             <?php endforeach; ?>
             <?php if ($showGroup): ?>
                 </optgroup>
diff --git app/design/adminhtml/default/default/template/report/store/switcher.phtml app/design/adminhtml/default/default/template/report/store/switcher.phtml
index c8fb4db..242872e 100644
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
index 91880ce..9e37cd7 100644
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
index a3f263c..40043d1 100644
--- app/design/adminhtml/default/default/template/store/switcher.phtml
+++ app/design/adminhtml/default/default/template/store/switcher.phtml
@@ -29,7 +29,7 @@
 <p class="switcher"><label for="store_switcher"><?php echo $this->__('Choose Store View:') ?></label>
 <select name="store_switcher" id="store_switcher" onchange="return switchStore(this);">
 <?php if ($this->hasDefaultOption()): ?>
-    <option value=""><?php echo $this->getDefaultStoreName() ?></option>
+    <option value=""><?php echo $this->escapeHtml($this->getDefaultStoreName()); ?></option>
 <?php endif; ?>
     <?php foreach ($websites as $website): ?>
         <?php $showWebsite = false; ?>
diff --git app/design/adminhtml/default/default/template/store/switcher/enhanced.phtml app/design/adminhtml/default/default/template/store/switcher/enhanced.phtml
index ceeb5f2..38397fe 100644
--- app/design/adminhtml/default/default/template/store/switcher/enhanced.phtml
+++ app/design/adminhtml/default/default/template/store/switcher/enhanced.phtml
@@ -29,7 +29,7 @@
 <div id="store_switcher_container">
 <p class="switcher"><label for="store_switcher"><?php echo $this->__('Choose Store View:') ?></label>
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
index fefc966..4514404 100644
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
index a72b0ab..5e32244 100644
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
index 29d6feb..a3c6423 100644
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
index 7001a4d..8cce35a 100644
--- app/locale/en_US/Mage_Catalog.csv
+++ app/locale/en_US/Mage_Catalog.csv
@@ -705,6 +705,7 @@
 "The product has been deleted.","The product has been deleted."
 "The product has been duplicated.","The product has been duplicated."
 "The product has been saved.","The product has been saved."
+"HTML tags are not allowed in SKU attribute.","HTML tags are not allowed in SKU attribute."
 "The product has required options","The product has required options"
 "The review has been deleted","The review has been deleted"
 "The review has been saved.","The review has been saved."
diff --git app/locale/en_US/Mage_ImportExport.csv app/locale/en_US/Mage_ImportExport.csv
index fc3aa7f..cd8e9ec 100644
--- app/locale/en_US/Mage_ImportExport.csv
+++ app/locale/en_US/Mage_ImportExport.csv
@@ -19,6 +19,7 @@
 "Column names have duplicates","Column names have duplicates"
 "Column names is empty or is not an array","Column names is empty or is not an array"
 "Column names: ""%s"" are invalid","Column names: ""%s"" are invalid"
+"Invalid value in SKU column. HTML tags are not allowed","Invalid value in SKU column. HTML tags are not allowed"
 "Customers","Customers"
 "Data is invalid or file is not uploaded","Data is invalid or file is not uploaded"
 "Delete Entities","Delete Entities"
@@ -88,6 +89,7 @@
 "Total size of uploadable files must not exceed %s","Total size of uploadable files must not exceed %s"
 "Unknown attribute filter type","Unknown attribute filter type"
 "Uploaded file has no extension","Uploaded file has no extension"
+"Incorrect entity type","Incorrect entity type"
 "Validation finished successfully","Validation finished successfully"
 "in rows","in rows"
 "in rows:","in rows:"
diff --git lib/Zend/Mail/Transport/Sendmail.php lib/Zend/Mail/Transport/Sendmail.php
index 62ea66e..22008f3 100644
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
