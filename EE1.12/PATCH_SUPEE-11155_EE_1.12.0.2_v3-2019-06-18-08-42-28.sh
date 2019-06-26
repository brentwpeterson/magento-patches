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


SUPEE-11155_EE_11202 | EE_1.12.0.2 | v1 | 2613ffbe9474267a3ee8e6205a152e9399fb94d9 | Fri Jun 14 21:16:40 2019 +0000 | b827b4334386ff81cc411f8463ec8a08f9623914..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/Mage.php app/Mage.php
index 973e87e6180..90a28a712ee 100644
--- app/Mage.php
+++ app/Mage.php
@@ -812,9 +812,9 @@ final class Mage
             ',',
             (string) self::getConfig()->getNode('dev/log/allowedFileExtensions', Mage_Core_Model_Store::DEFAULT_CODE)
         );
-        $logValidator = new Zend_Validate_File_Extension($_allowedFileExtensions);
         $logDir = self::getBaseDir('var') . DS . 'log';
-        if (!$logValidator->isValid($logDir . DS . $file)) {
+        $validatedFileExtension = pathinfo($file, PATHINFO_EXTENSION);
+        if (!$validatedFileExtension || !in_array($validatedFileExtension, $_allowedFileExtensions)) {
             return;
         }
 
diff --git app/code/core/Enterprise/Cms/Model/Page/Version.php app/code/core/Enterprise/Cms/Model/Page/Version.php
index ede0ab9a7a6..1a7a76d7a19 100644
--- app/code/core/Enterprise/Cms/Model/Page/Version.php
+++ app/code/core/Enterprise/Cms/Model/Page/Version.php
@@ -166,18 +166,21 @@ class Enterprise_Cms_Model_Page_Version extends Mage_Core_Model_Abstract
     {
         $resource = $this->_getResource();
         /* @var $resource Enterprise_Cms_Model_Mysql4_Page_Version */
+        $label = Mage::helper('core')->escapeHtml($this->getLabel());
         if ($this->isPublic()) {
             if ($resource->isVersionLastPublic($this)) {
-                Mage::throwException(
-                    Mage::helper('enterprise_cms')->__('Version "%s" could not be removed because it is the last public version for its page.', $this->getLabel())
-                );
+                Mage::throwException(Mage::helper('enterprise_cms')->__(
+                    'Version "%s" could not be removed because it is the last public version for its page.',
+                    $label
+                ));
             }
         }
 
         if ($resource->isVersionHasPublishedRevision($this)) {
-            Mage::throwException(
-                Mage::helper('enterprise_cms')->__('Version "%s" could not be removed because its revision has been published.', $this->getLabel())
-            );
+            Mage::throwException(Mage::helper('enterprise_cms')->__(
+                'Version "%s" could not be removed because its revision has been published.',
+                $label
+            ));
         }
 
         return parent::_beforeDelete();
diff --git app/code/core/Enterprise/GiftCardAccount/Model/Pool.php app/code/core/Enterprise/GiftCardAccount/Model/Pool.php
index 95ace239869..f4a007709a8 100644
--- app/code/core/Enterprise/GiftCardAccount/Model/Pool.php
+++ app/code/core/Enterprise/GiftCardAccount/Model/Pool.php
@@ -121,8 +121,9 @@ class Enterprise_GiftCardAccount_Model_Pool extends Enterprise_GiftCardAccount_M
         $charset = str_split((string) Mage::app()->getConfig()->getNode(sprintf(self::XML_CHARSET_NODE, $format)));
 
         $code = '';
+        $charsetSize = count($charset);
         for ($i=0; $i<$length; $i++) {
-            $char = $charset[array_rand($charset)];
+            $char = $charset[random_int(0, $charsetSize - 1)];
             if ($split > 0 && ($i%$split) == 0 && $i != 0) {
                 $char = "{$splitChar}{$char}";
             }
diff --git app/code/core/Enterprise/GiftRegistry/controllers/IndexController.php app/code/core/Enterprise/GiftRegistry/controllers/IndexController.php
index 9fc1027c8af..20ee0a3c7df 100644
--- app/code/core/Enterprise/GiftRegistry/controllers/IndexController.php
+++ app/code/core/Enterprise/GiftRegistry/controllers/IndexController.php
@@ -530,7 +530,7 @@ class Enterprise_GiftRegistry_IndexController extends Mage_Core_Controller_Front
                             $idField = $person->getIdFieldName();
                             if (!empty($registrant[$idField])) {
                                 $person->load($registrant[$idField]);
-                                if (!$person->getId()) {
+                                if (!$person->getId() || $person->getEntityId() != $model->getEntityId()) {
                                     Mage::throwException(Mage::helper('enterprise_giftregistry')->__('Incorrect recipient data.'));
                                 }
                             } else {
diff --git app/code/core/Enterprise/Logging/Model/Config.php app/code/core/Enterprise/Logging/Model/Config.php
index 2de804556a2..9c5a69c57d6 100644
--- app/code/core/Enterprise/Logging/Model/Config.php
+++ app/code/core/Enterprise/Logging/Model/Config.php
@@ -83,7 +83,13 @@ class Enterprise_Logging_Model_Config
                 }
             }
             else {
-                $this->_systemConfigValues = unserialize($this->_systemConfigValues);
+                try {
+                    $this->_systemConfigValues = Mage::helper('core/unserializeArray')
+                        ->unserialize($this->_systemConfigValues);
+                } catch (Exception $e) {
+                    $this->_systemConfigValues = array();
+                    Mage::logException($e);
+                }
             }
         }
         return $this->_systemConfigValues;
diff --git app/code/core/Enterprise/Pbridge/etc/system.xml app/code/core/Enterprise/Pbridge/etc/system.xml
index e787d11ae85..e63539f17a7 100644
--- app/code/core/Enterprise/Pbridge/etc/system.xml
+++ app/code/core/Enterprise/Pbridge/etc/system.xml
@@ -66,6 +66,7 @@
                             <label>Gateway Basic URL</label>
                             <frontend_type>text</frontend_type>
                             <sort_order>40</sort_order>
+                            <backend_model>adminhtml/system_config_backend_gatewayurl</backend_model>
                             <show_in_default>1</show_in_default>
                             <show_in_website>1</show_in_website>
                             <show_in_store>0</show_in_store>
diff --git app/code/core/Enterprise/Reminder/controllers/Adminhtml/ReminderController.php app/code/core/Enterprise/Reminder/controllers/Adminhtml/ReminderController.php
index 9a03c076542..77b173eb48c 100644
--- app/code/core/Enterprise/Reminder/controllers/Adminhtml/ReminderController.php
+++ app/code/core/Enterprise/Reminder/controllers/Adminhtml/ReminderController.php
@@ -180,6 +180,9 @@ class Enterprise_Reminder_Adminhtml_ReminderController extends Mage_Adminhtml_Co
                     $this->_redirect('*/*/edit', array('id' => $model->getId()));
                     return;
                 }
+                if (Mage::helper('adminhtml')->hasTags($data['rule'], array('attribute'), false)) {
+                    Mage::throwException(Mage::helper('catalogrule')->__('Wrong rule specified'));
+                }
 
                 $data['conditions'] = $data['rule']['conditions'];
                 unset($data['rule']);
diff --git app/code/core/Enterprise/Rma/Block/Adminhtml/Rma/Create/Order/Grid.php app/code/core/Enterprise/Rma/Block/Adminhtml/Rma/Create/Order/Grid.php
index 04b8c64bc87..ed22fde0227 100644
--- app/code/core/Enterprise/Rma/Block/Adminhtml/Rma/Create/Order/Grid.php
+++ app/code/core/Enterprise/Rma/Block/Adminhtml/Rma/Create/Order/Grid.php
@@ -67,10 +67,11 @@ class Enterprise_Rma_Block_Adminhtml_Rma_Create_Order_Grid extends Mage_Adminhtm
     protected function _prepareColumns()
     {
         $this->addColumn('real_order_id', array(
-            'header'=> Mage::helper('sales')->__('Order #'),
-            'width' => '80px',
-            'type'  => 'text',
-            'index' => 'increment_id',
+            'header' => Mage::helper('sales')->__('Order #'),
+            'width'  => '80px',
+            'type'   => 'text',
+            'index'  => 'increment_id',
+            'escape' => true,
         ));
 
         if (!Mage::app()->isSingleStoreMode()) {
diff --git app/code/core/Enterprise/Staging/Model/Resource/Staging/Action.php app/code/core/Enterprise/Staging/Model/Resource/Staging/Action.php
old mode 100755
new mode 100644
index 2a7df3d35f5..110a2e9cba2
--- app/code/core/Enterprise/Staging/Model/Resource/Staging/Action.php
+++ app/code/core/Enterprise/Staging/Model/Resource/Staging/Action.php
@@ -76,12 +76,34 @@ class Enterprise_Staging_Model_Resource_Staging_Action extends Mage_Core_Model_R
 
     /**
      * Action after delete
-     * Need to delete all backup tables also
      *
      * @param Mage_Core_Model_Abstract $object
-     * @return Enterprise_Staging_Model_Resource_Staging_Action
+     * @return Mage_Core_Model_Resource_Db_Abstract
      */
     protected function _afterDelete(Mage_Core_Model_Abstract $object)
+    {
+        return parent::_afterDelete($object);
+    }
+
+    /**
+     * Action get backup tables
+     *
+     * @param $stagingTablePrefix
+     * @return Enterprise_Staging_Model_Resource_Helper_Mysql4
+     */
+    public function getBackupTables($stagingTablePrefix)
+    {
+        return Mage::getResourceHelper('enterprise_staging')->getTableNamesByPrefix($stagingTablePrefix);
+    }
+
+    /**
+     * Action delete staging backup
+     * Need to delete all backup tables without transaction
+     *
+     * @param Mage_Core_Model_Abstract $object
+     * @return Enterprise_Staging_Model_Resource_Staging_Action
+     */
+    public function deleteStagingBackup(Mage_Core_Model_Abstract $object)
     {
         if ($object->getIsDeleteTables() === true) {
             $stagingTablePrefix = $object->getStagingTablePrefix();
@@ -96,15 +118,4 @@ class Enterprise_Staging_Model_Resource_Staging_Action extends Mage_Core_Model_R
         }
         return $this;
     }
-
-    /**
-     * Enter description here ...
-     *
-     * @param unknown_type $stagingTablePrefix
-     * @return unknown
-     */
-    public function getBackupTables($stagingTablePrefix)
-    {
-        return Mage::getResourceHelper('enterprise_staging')->getTableNamesByPrefix($stagingTablePrefix);
-    }
 }
diff --git app/code/core/Enterprise/Staging/Model/Staging/Action.php app/code/core/Enterprise/Staging/Model/Staging/Action.php
index 67ddab66aca..e179f0bf380 100644
--- app/code/core/Enterprise/Staging/Model/Staging/Action.php
+++ app/code/core/Enterprise/Staging/Model/Staging/Action.php
@@ -255,4 +255,16 @@ class Enterprise_Staging_Model_Staging_Action extends Mage_Core_Model_Abstract
         }
         return $this;
     }
+
+    /**
+     * Action delete
+     * Need to delete all backup tables also without transaction
+     *
+     * @return Enterprise_Staging_Model_Resource_Staging_Action
+     */
+    public function delete()
+    {
+        parent::delete();
+        return Mage::getResourceModel('enterprise_staging/staging_action')->deleteStagingBackup($this);
+    }
 }
diff --git app/code/core/Mage/Admin/Model/Block.php app/code/core/Mage/Admin/Model/Block.php
index a672f4ef350..61c6134964d 100644
--- app/code/core/Mage/Admin/Model/Block.php
+++ app/code/core/Mage/Admin/Model/Block.php
@@ -57,7 +57,7 @@ class Mage_Admin_Model_Block extends Mage_Core_Model_Abstract
         if (in_array($this->getBlockName(), $disallowedBlockNames)) {
             $errors[] = Mage::helper('adminhtml')->__('Block Name is disallowed.');
         }
-        if (!Zend_Validate::is($this->getBlockName(), 'Regex', array('/^[-_a-zA-Z0-9\/]*$/'))) {
+        if (!Zend_Validate::is($this->getBlockName(), 'Regex', array('/^[-_a-zA-Z0-9]+\/[-_a-zA-Z0-9\/]+$/'))) {
             $errors[] = Mage::helper('adminhtml')->__('Block Name is incorrect.');
         }
 
diff --git app/code/core/Mage/Admin/Model/User.php app/code/core/Mage/Admin/Model/User.php
index 7fb1e07267c..e20d9c0f618 100644
--- app/code/core/Mage/Admin/Model/User.php
+++ app/code/core/Mage/Admin/Model/User.php
@@ -566,7 +566,7 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
         }
 
         if ($this->userExists()) {
-            $errors[] = Mage::helper('adminhtml')->__('A user with the same user name or email aleady exists.');
+            $errors[] = Mage::helper('adminhtml')->__('A user with the same user name or email already exists.');
         }
 
         if (count($errors) === 0) {
diff --git app/code/core/Mage/AdminNotification/etc/system.xml app/code/core/Mage/AdminNotification/etc/system.xml
index 35ca3ab5790..504b4d2b26b 100644
--- app/code/core/Mage/AdminNotification/etc/system.xml
+++ app/code/core/Mage/AdminNotification/etc/system.xml
@@ -64,6 +64,15 @@
                             <show_in_website>0</show_in_website>
                             <show_in_store>0</show_in_store>
                         </last_update>
+                        <feed_url>
+                            <label>Feed Url</label>
+                            <frontend_type>text</frontend_type>
+                            <backend_model>adminhtml/system_config_backend_protected</backend_model>
+                            <sort_order>3</sort_order>
+                            <show_in_default>0</show_in_default>
+                            <show_in_website>0</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </feed_url>
                     </fields>
                 </adminnotification>
             </groups>
diff --git app/code/core/Mage/Adminhtml/Block/Api/Role/Grid/User.php app/code/core/Mage/Adminhtml/Block/Api/Role/Grid/User.php
index 6216210ac8e..7d36c7515ef 100644
--- app/code/core/Mage/Adminhtml/Block/Api/Role/Grid/User.php
+++ app/code/core/Mage/Adminhtml/Block/Api/Role/Grid/User.php
@@ -157,7 +157,7 @@ class Mage_Adminhtml_Block_Api_Role_Grid_User extends Mage_Adminhtml_Block_Widge
     protected function _getUsers($json=false)
     {
         if ( $this->getRequest()->getParam('in_role_user') != "" ) {
-            return $this->getRequest()->getParam('in_role_user');
+            return (int)$this->getRequest()->getParam('in_role_user');
         }
         $roleId = ( $this->getRequest()->getParam('rid') > 0 ) ? $this->getRequest()->getParam('rid') : Mage::registry('RID');
         $users  = Mage::getModel('api/roles')->setId($roleId)->getRoleUsers();
diff --git app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php
index 9351239dd19..03b7a720e98 100644
--- app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php
+++ app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php
@@ -155,6 +155,8 @@ class Mage_Adminhtml_Block_Catalog_Product_Edit_Tab_Super_Config extends Mage_Ad
             // Hide price if needed
             foreach ($attributes as &$attribute) {
                 $attribute['label'] = $this->escapeHtml($attribute['label']);
+                $attribute['frontend_label'] = $this->escapeHtml($attribute['frontend_label']);
+                $attribute['store_label'] = $this->escapeHtml($attribute['store_label']);
                 if (isset($attribute['values']) && is_array($attribute['values'])) {
                     foreach ($attribute['values'] as &$attributeValue) {
                         if (!$this->getCanReadPrice()) {
diff --git app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php
index 2c581a24aec..62ca8a4a38c 100644
--- app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php
+++ app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php
@@ -56,6 +56,12 @@ class Mage_Adminhtml_Block_Newsletter_Queue_Preview extends Mage_Adminhtml_Block
         if(!$storeId) {
             $storeId = Mage::app()->getDefaultStoreView()->getId();
         }
+        $template->setTemplateStyles(
+            $this->maliciousCodeFilter($template->getTemplateStyles())
+        );
+        $template->setTemplateText(
+            $this->maliciousCodeFilter($template->getTemplateText())
+        );
 
         Varien_Profiler::start("newsletter_queue_proccessing");
         $vars = array();
diff --git app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Preview.php app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Preview.php
index 08909d8005c..7f3ffa58a7a 100644
--- app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Preview.php
+++ app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Preview.php
@@ -46,6 +46,12 @@ class Mage_Adminhtml_Block_Newsletter_Template_Preview extends Mage_Adminhtml_Bl
             $template->setTemplateText($this->getRequest()->getParam('text'));
             $template->setTemplateStyles($this->getRequest()->getParam('styles'));
         }
+        $template->setTemplateStyles(
+            $this->maliciousCodeFilter($template->getTemplateStyles())
+        );
+        $template->setTemplateText(
+            $this->maliciousCodeFilter($template->getTemplateText())
+        );
 
         $storeId = (int)$this->getRequest()->getParam('store_id');
         if(!$storeId) {
diff --git app/code/core/Mage/Adminhtml/Block/Permissions/Role/Grid/User.php app/code/core/Mage/Adminhtml/Block/Permissions/Role/Grid/User.php
index f78e90c465d..9709045bead 100644
--- app/code/core/Mage/Adminhtml/Block/Permissions/Role/Grid/User.php
+++ app/code/core/Mage/Adminhtml/Block/Permissions/Role/Grid/User.php
@@ -157,7 +157,7 @@ class Mage_Adminhtml_Block_Permissions_Role_Grid_User extends Mage_Adminhtml_Blo
     protected function _getUsers($json=false)
     {
         if ( $this->getRequest()->getParam('in_role_user') != "" ) {
-            return $this->getRequest()->getParam('in_role_user');
+            return (int)$this->getRequest()->getParam('in_role_user');
         }
         $roleId = ( $this->getRequest()->getParam('rid') > 0 ) ? $this->getRequest()->getParam('rid') : Mage::registry('RID');
         $users  = Mage::getModel('admin/roles')->setId($roleId)->getRoleUsers();
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Creditmemo/Grid.php app/code/core/Mage/Adminhtml/Block/Sales/Creditmemo/Grid.php
index 97e190fa1d8..ec6850940b4 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Creditmemo/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Creditmemo/Grid.php
@@ -76,6 +76,7 @@ class Mage_Adminhtml_Block_Sales_Creditmemo_Grid extends Mage_Adminhtml_Block_Wi
             'header'    => Mage::helper('sales')->__('Order #'),
             'index'     => 'order_increment_id',
             'type'      => 'text',
+            'escape'    => true,
         ));
 
         $this->addColumn('order_created_at', array(
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Invoice/Grid.php app/code/core/Mage/Adminhtml/Block/Sales/Invoice/Grid.php
index a8266b7bb2b..a9df0b1432b 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Invoice/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Invoice/Grid.php
@@ -77,6 +77,7 @@ class Mage_Adminhtml_Block_Sales_Invoice_Grid extends Mage_Adminhtml_Block_Widge
             'header'    => Mage::helper('sales')->__('Order #'),
             'index'     => 'order_increment_id',
             'type'      => 'text',
+            'escape'    => true,
         ));
 
         $this->addColumn('order_created_at', array(
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/Create/Header.php app/code/core/Mage/Adminhtml/Block/Sales/Order/Create/Header.php
index e83bfecf893..c0be5a5fc60 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/Create/Header.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/Create/Header.php
@@ -34,7 +34,10 @@ class Mage_Adminhtml_Block_Sales_Order_Create_Header extends Mage_Adminhtml_Bloc
     protected function _toHtml()
     {
         if ($this->_getSession()->getOrder()->getId()) {
-            return '<h3 class="icon-head head-sales-order">'.Mage::helper('sales')->__('Edit Order #%s', $this->_getSession()->getOrder()->getIncrementId()).'</h3>';
+            return '<h3 class="icon-head head-sales-order">' . Mage::helper('sales')->__(
+                'Edit Order #%s',
+                $this->escapeHtml($this->_getSession()->getOrder()->getIncrementId())
+            ) . '</h3>';
         }
 
         $customerId = $this->getCustomerId();
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/Creditmemo/Create.php app/code/core/Mage/Adminhtml/Block/Sales/Order/Creditmemo/Create.php
index ef5cb9f8c16..b08f5e4bd49 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/Creditmemo/Create.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/Creditmemo/Create.php
@@ -67,10 +67,15 @@ class Mage_Adminhtml_Block_Sales_Order_Creditmemo_Create extends Mage_Adminhtml_
     public function getHeaderText()
     {
         if ($this->getCreditmemo()->getInvoice()) {
-            $header = Mage::helper('sales')->__('New Credit Memo for Invoice #%s', $this->getCreditmemo()->getInvoice()->getIncrementId());
-        }
-        else {
-            $header = Mage::helper('sales')->__('New Credit Memo for Order #%s', $this->getCreditmemo()->getOrder()->getRealOrderId());
+            $header = Mage::helper('sales')->__(
+                'New Credit Memo for Invoice #%s',
+                $this->escapeHtml($this->getCreditmemo()->getInvoice()->getIncrementId())
+            );
+        } else {
+            $header = Mage::helper('sales')->__(
+                'New Credit Memo for Order #%s',
+                $this->escapeHtml($this->getCreditmemo()->getOrder()->getRealOrderId())
+            );
         }
 
         return $header;
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php
index b81b81b169b..8f5464c864f 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php
@@ -65,10 +65,11 @@ class Mage_Adminhtml_Block_Sales_Order_Grid extends Mage_Adminhtml_Block_Widget_
     {
 
         $this->addColumn('real_order_id', array(
-            'header'=> Mage::helper('sales')->__('Order #'),
-            'width' => '80px',
-            'type'  => 'text',
-            'index' => 'increment_id',
+            'header' => Mage::helper('sales')->__('Order #'),
+            'width'  => '80px',
+            'type'   => 'text',
+            'index'  => 'increment_id',
+            'escape' => true,
         ));
 
         if (!Mage::app()->isSingleStoreMode()) {
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/Invoice/Create.php app/code/core/Mage/Adminhtml/Block/Sales/Order/Invoice/Create.php
index c6da4aa0843..9e339c130b4 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/Invoice/Create.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/Invoice/Create.php
@@ -64,8 +64,14 @@ class Mage_Adminhtml_Block_Sales_Order_Invoice_Create extends Mage_Adminhtml_Blo
     public function getHeaderText()
     {
         return ($this->getInvoice()->getOrder()->getForcedDoShipmentWithInvoice())
-            ? Mage::helper('sales')->__('New Invoice and Shipment for Order #%s', $this->getInvoice()->getOrder()->getRealOrderId())
-            : Mage::helper('sales')->__('New Invoice for Order #%s', $this->getInvoice()->getOrder()->getRealOrderId());
+            ? Mage::helper('sales')->__(
+                'New Invoice and Shipment for Order #%s',
+                $this->escapeHtml($this->getInvoice()->getOrder()->getRealOrderId())
+            )
+            : Mage::helper('sales')->__(
+                'New Invoice for Order #%s',
+                $this->escapeHtml($this->getInvoice()->getOrder()->getRealOrderId())
+            );
     }
 
     /**
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/Shipment/Create.php app/code/core/Mage/Adminhtml/Block/Sales/Order/Shipment/Create.php
index 6e98dde2016..162a9550952 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/Shipment/Create.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/Shipment/Create.php
@@ -59,7 +59,10 @@ class Mage_Adminhtml_Block_Sales_Order_Shipment_Create extends Mage_Adminhtml_Bl
 
     public function getHeaderText()
     {
-        $header = Mage::helper('sales')->__('New Shipment for Order #%s', $this->getShipment()->getOrder()->getRealOrderId());
+        $header = Mage::helper('sales')->__(
+            'New Shipment for Order #%s',
+            $this->escapeHtml($this->getShipment()->getOrder()->getRealOrderId())
+        );
         return $header;
     }
 
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php
index 7f6f08fd2f6..1eae8f2ebaa 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php
@@ -295,6 +295,16 @@ class Mage_Adminhtml_Block_Sales_Order_View extends Mage_Adminhtml_Block_Widget_
     {
         return $this->getUrl('*/*/reviewPayment', array('action' => $action));
     }
+
+    /**
+     * Return header for view grid
+     *
+     * @return string
+     */
+    public function getHeaderHtml()
+    {
+        return '<h3 class="' . $this->getHeaderCssClass() . '">' . $this->escapeHtml($this->getHeaderText()) . '</h3>';
+    }
 //
 //    /**
 //     * Return URL for accept payment action
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Shipment/Grid.php app/code/core/Mage/Adminhtml/Block/Sales/Shipment/Grid.php
index 2cd20085ca2..6d7533ebfe6 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Shipment/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Shipment/Grid.php
@@ -88,6 +88,7 @@ class Mage_Adminhtml_Block_Sales_Shipment_Grid extends Mage_Adminhtml_Block_Widg
             'header'    => Mage::helper('sales')->__('Order #'),
             'index'     => 'order_increment_id',
             'type'      => 'text',
+            'escape'    => true,
         ));
 
         $this->addColumn('order_created_at', array(
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Transactions/Grid.php app/code/core/Mage/Adminhtml/Block/Sales/Transactions/Grid.php
index b4b4eb5659b..fab4a4afbc9 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Transactions/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Transactions/Grid.php
@@ -82,7 +82,8 @@ class Mage_Adminhtml_Block_Sales_Transactions_Grid extends Mage_Adminhtml_Block_
         $this->addColumn('increment_id', array(
             'header'    => Mage::helper('sales')->__('Order ID'),
             'index'     => 'increment_id',
-            'type'      => 'text'
+            'type'      => 'text',
+            'escape'    => true,
         ));
 
         $this->addColumn('txn_id', array(
diff --git app/code/core/Mage/Adminhtml/Block/System/Email/Template/Preview.php app/code/core/Mage/Adminhtml/Block/System/Email/Template/Preview.php
index d152bdcc350..98c1beefa07 100644
--- app/code/core/Mage/Adminhtml/Block/System/Email/Template/Preview.php
+++ app/code/core/Mage/Adminhtml/Block/System/Email/Template/Preview.php
@@ -51,11 +51,12 @@ class Mage_Adminhtml_Block_System_Email_Template_Preview extends Mage_Adminhtml_
             $template->setTemplateStyles($this->getRequest()->getParam('styles'));
         }
 
-        /* @var $filter Mage_Core_Model_Input_Filter_MaliciousCode */
-        $filter = Mage::getSingleton('core/input_filter_maliciousCode');
+        $template->setTemplateStyles(
+            $this->maliciousCodeFilter($template->getTemplateStyles())
+        );
 
         $template->setTemplateText(
-            $filter->filter($template->getTemplateText())
+            $this->maliciousCodeFilter($template->getTemplateText())
         );
 
         Varien_Profiler::start("email_template_proccessing");
diff --git app/code/core/Mage/Adminhtml/Block/Template.php app/code/core/Mage/Adminhtml/Block/Template.php
index 3fa8a4c85fc..f8aee007eb6 100644
--- app/code/core/Mage/Adminhtml/Block/Template.php
+++ app/code/core/Mage/Adminhtml/Block/Template.php
@@ -80,4 +80,15 @@ class Mage_Adminhtml_Block_Template extends Mage_Core_Block_Template
         Mage::dispatchEvent('adminhtml_block_html_before', array('block' => $this));
         return parent::_toHtml();
     }
+
+    /**
+     * Deleting script tags from string
+     *
+     * @param string $html
+     * @return string
+     */
+    public function maliciousCodeFilter($html)
+    {
+        return Mage::getSingleton('core/input_filter_maliciousCode')->filter($html);
+    }
 }
diff --git app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Abstract.php app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Abstract.php
index 0e5f04f44a6..a261c2c2e1f 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Abstract.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Abstract.php
@@ -114,9 +114,9 @@ abstract class Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Abstract
             }
             $out = '<a href="#" name="' . $this->getColumn()->getId() . '" title="' . $nDir
                    . '" class="' . $className . '"><span class="sort-title">'
-                   . $this->getColumn()->getHeader().'</span></a>';
+                   . $this->escapeHtml($this->getColumn()->getHeader()) . '</span></a>';
         } else {
-            $out = $this->getColumn()->getHeader();
+            $out = $this->escapeHtml($this->getColumn()->getHeader());
         }
         return $out;
     }
diff --git app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
index f3bb06d8b3d..e383e867e7a 100644
--- app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
+++ app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
@@ -180,8 +180,11 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
     protected function _getXpathBlockValidationExpression() {
         $xpath = "";
         if (count($this->_disallowedBlock)) {
-            $xpath = "//block[@type='";
-            $xpath .= implode("'] | //block[@type='", $this->_disallowedBlock) . "']";
+            foreach ($this->_disallowedBlock as $key => $value) {
+                $xpath .= $key > 0 ? " | " : '';
+                $xpath .= "//block[translate(@type, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') = ";
+                $xpath .= "translate('$value', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')]";
+            }
         }
         return $xpath;
     }
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Baseurl.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Baseurl.php
index 76c5f192357..5078a555620 100644
--- app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Baseurl.php
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Baseurl.php
@@ -35,6 +35,8 @@ class Mage_Adminhtml_Model_System_Config_Backend_Baseurl extends Mage_Core_Model
             $parsedUrl = parse_url($value);
             if (!isset($parsedUrl['scheme']) || !isset($parsedUrl['host'])) {
                 Mage::throwException(Mage::helper('core')->__('The %s you entered is invalid. Please make sure that it follows "http://domain.com/" format.', $this->getFieldConfig()->label));
+            } elseif (('https' != $parsedUrl['scheme']) && ('http' != $parsedUrl['scheme'])) {
+                Mage::throwException(Mage::helper('core')->__('Invalid URL scheme.'));
             }
         }
 
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Locale.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Locale.php
index 792a174a1d9..973b1f23fe2 100644
--- app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Locale.php
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Locale.php
@@ -34,6 +34,27 @@
  */
 class Mage_Adminhtml_Model_System_Config_Backend_Locale extends Mage_Core_Model_Config_Data
 {
+    /**
+     * Validate data before save data
+     *
+     * @return Mage_Core_Model_Abstract
+     * @throws Mage_Core_Exception
+     */
+    protected function _beforeSave()
+    {
+        $allCurrenciesOptions = Mage::getSingleton('adminhtml/system_config_source_locale_currency_all')
+            ->toOptionArray(true);
+
+        $allCurrenciesValues = array_column($allCurrenciesOptions, 'value');
+
+        foreach ($this->getValue() as $currency) {
+            if (!in_array($currency, $allCurrenciesValues)) {
+                Mage::throwException(Mage::helper('adminhtml')->__('Currency doesn\'t exist.'));
+            }
+        }
+
+        return parent::_beforeSave();
+    }
 
     /**
      * Enter description here...
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized/Array.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized/Array.php
index e7ccb054124..f880f34f557 100644
--- app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized/Array.php
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized/Array.php
@@ -31,11 +31,19 @@
 class Mage_Adminhtml_Model_System_Config_Backend_Serialized_Array extends Mage_Adminhtml_Model_System_Config_Backend_Serialized
 {
     /**
-     * Unset array element with '__empty' key
+     * Check object existence in incoming data and unset array element with '__empty' key
      *
+     * @throws Mage_Core_Exception
+     * @return void
      */
     protected function _beforeSave()
     {
+        try {
+            Mage::helper('core/unserializeArray')->unserialize(serialize($this->getValue()));
+        } catch (Exception $e) {
+            Mage::throwException(Mage::helper('adminhtml')->__('Serialized data is incorrect'));
+        }
+
         $value = $this->getValue();
         if (is_array($value)) {
             unset($value['__empty']);
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/Product/AttributeController.php app/code/core/Mage/Adminhtml/controllers/Catalog/Product/AttributeController.php
index 8d174a5b3a3..710fc2e1ac8 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/Product/AttributeController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/Product/AttributeController.php
@@ -157,6 +157,7 @@ class Mage_Adminhtml_Catalog_Product_AttributeController extends Mage_Adminhtml_
             /** @var $helperCatalog Mage_Catalog_Helper_Data */
             $helperCatalog = Mage::helper('catalog');
             //labels
+            $data['frontend_label'] = (array) $data['frontend_label'];
             foreach ($data['frontend_label'] as & $value) {
                 if ($value) {
                     $value = $helperCatalog->stripTags($value);
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/Product/ReviewController.php app/code/core/Mage/Adminhtml/controllers/Catalog/Product/ReviewController.php
index 3de9f6a4217..be37043890c 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/Product/ReviewController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/Product/ReviewController.php
@@ -41,6 +41,17 @@ class Mage_Adminhtml_Catalog_Product_ReviewController extends Mage_Adminhtml_Con
      */
     protected $_publicActions = array('edit');
 
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions(array('delete', 'massDelete'));
+        return parent::preDispatch();
+    }
+
     public function indexAction()
     {
         $this->_title($this->__('Catalog'))
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
index 93627ba5dc6..3471f8e14c3 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
@@ -541,7 +541,7 @@ class Mage_Adminhtml_Catalog_ProductController extends Mage_Adminhtml_Controller
         catch (Mage_Eav_Model_Entity_Attribute_Exception $e) {
             $response->setError(true);
             $response->setAttribute($e->getAttributeCode());
-            $response->setMessage($e->getMessage());
+            $response->setMessage(Mage::helper('core')->escapeHtml($e->getMessage()));
         } catch (Mage_Core_Exception $e) {
             $response->setError(true);
             $response->setMessage($e->getMessage());
diff --git app/code/core/Mage/Adminhtml/controllers/Checkout/AgreementController.php app/code/core/Mage/Adminhtml/controllers/Checkout/AgreementController.php
index ea4f4b572a3..ba8ccabc8c4 100644
--- app/code/core/Mage/Adminhtml/controllers/Checkout/AgreementController.php
+++ app/code/core/Mage/Adminhtml/controllers/Checkout/AgreementController.php
@@ -33,6 +33,17 @@
  */
 class Mage_Adminhtml_Checkout_AgreementController extends Mage_Adminhtml_Controller_Action
 {
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete');
+        return parent::preDispatch();
+    }
+
     public function indexAction()
     {
         $this->_title($this->__('Sales'))->_title($this->__('Terms and Conditions'));
diff --git app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
index a508dfa8e31..dc091d28dbc 100644
--- app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
+++ app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
@@ -167,6 +167,11 @@ class Mage_Adminhtml_Newsletter_TemplateController extends Mage_Adminhtml_Contro
         }
 
         try {
+            $allowedHtmlTags = ['text', 'styles'];
+            if (Mage::helper('adminhtml')->hasTags($request->getParams(), $allowedHtmlTags)) {
+                Mage::throwException(Mage::helper('adminhtml')->__('Invalid template data.'));
+            }
+
             $template->addData($request->getParams())
                 ->setTemplateSubject($request->getParam('subject'))
                 ->setTemplateCode($request->getParam('code'))
diff --git app/code/core/Mage/Adminhtml/controllers/Promo/CatalogController.php app/code/core/Mage/Adminhtml/controllers/Promo/CatalogController.php
index d0ace7ba7ac..b858694b8be 100644
--- app/code/core/Mage/Adminhtml/controllers/Promo/CatalogController.php
+++ app/code/core/Mage/Adminhtml/controllers/Promo/CatalogController.php
@@ -133,6 +133,9 @@ class Mage_Adminhtml_Promo_CatalogController extends Mage_Adminhtml_Controller_A
                     array('request' => $this->getRequest())
                 );
                 $data = $this->getRequest()->getPost();
+                if (Mage::helper('adminhtml')->hasTags($data['rule'], array('attribute'), false)) {
+                    Mage::throwException(Mage::helper('catalogrule')->__('Wrong rule specified'));
+                }
                 $data = $this->_filterDates($data, array('from_date', 'to_date'));
                 if ($id = $this->getRequest()->getParam('rule_id')) {
                     $model->load($id);
diff --git app/code/core/Mage/Adminhtml/controllers/Promo/QuoteController.php app/code/core/Mage/Adminhtml/controllers/Promo/QuoteController.php
index 2283a1690ad..70fb7aec6c4 100644
--- app/code/core/Mage/Adminhtml/controllers/Promo/QuoteController.php
+++ app/code/core/Mage/Adminhtml/controllers/Promo/QuoteController.php
@@ -133,6 +133,9 @@ class Mage_Adminhtml_Promo_QuoteController extends Mage_Adminhtml_Controller_Act
                     'adminhtml_controller_salesrule_prepare_save',
                     array('request' => $this->getRequest()));
                 $data = $this->getRequest()->getPost();
+                if (Mage::helper('adminhtml')->hasTags($data['rule'], array('attribute'), false)) {
+                    Mage::throwException(Mage::helper('catalogrule')->__('Wrong rule specified'));
+                }
                 $data = $this->_filterDates($data, array('from_date', 'to_date'));
                 $id = $this->getRequest()->getParam('rule_id');
                 if ($id) {
diff --git app/code/core/Mage/Adminhtml/controllers/Sales/Order/CreateController.php app/code/core/Mage/Adminhtml/controllers/Sales/Order/CreateController.php
index cfea9f28e31..dcebb1d113f 100644
--- app/code/core/Mage/Adminhtml/controllers/Sales/Order/CreateController.php
+++ app/code/core/Mage/Adminhtml/controllers/Sales/Order/CreateController.php
@@ -146,6 +146,13 @@ class Mage_Adminhtml_Sales_Order_CreateController extends Mage_Adminhtml_Control
          * Saving order data
          */
         if ($data = $this->getRequest()->getPost('order')) {
+            if (
+                array_key_exists('comment', $data)
+                && array_key_exists('reserved_order_id', $data['comment'])
+            ) {
+                unset($data['comment']['reserved_order_id']);
+            }
+
             $this->_getOrderCreateModel()->importPostData($data);
         }
 
@@ -476,10 +483,20 @@ class Mage_Adminhtml_Sales_Order_CreateController extends Mage_Adminhtml_Control
 
     /**
      * Saving quote and create order
+     *
+     * @throws Mage_Core_Exception
      */
     public function saveAction()
     {
         try {
+            $orderData = $this->getRequest()->getPost('order');
+            if (
+                array_key_exists('reserved_order_id', $orderData['comment'])
+                && Mage::helper('adminhtml/sales')->hasTags($orderData['comment']['reserved_order_id'])
+            ) {
+                Mage::throwException($this->__('Invalid order data.'));
+            }
+
             $this->_processActionData('save');
             if ($paymentData = $this->getRequest()->getPost('payment')) {
                 $this->_getOrderCreateModel()->setPaymentData($paymentData);
diff --git app/code/core/Mage/Adminhtml/controllers/SitemapController.php app/code/core/Mage/Adminhtml/controllers/SitemapController.php
index b6346cf06fd..e3178bdb312 100644
--- app/code/core/Mage/Adminhtml/controllers/SitemapController.php
+++ app/code/core/Mage/Adminhtml/controllers/SitemapController.php
@@ -33,6 +33,11 @@
  */
 class Mage_Adminhtml_SitemapController extends  Mage_Adminhtml_Controller_Action
 {
+    /**
+     * Maximum sitemap name length
+     */
+    const MAXIMUM_SITEMAP_NAME_LENGTH = 32;
+
     /**
      * Controller predispatch method
      *
@@ -141,6 +146,19 @@ class Mage_Adminhtml_SitemapController extends  Mage_Adminhtml_Controller_Action
             if (!empty($data['sitemap_filename']) && !empty($data['sitemap_path'])) {
                 $path = rtrim($data['sitemap_path'], '\\/')
                       . DS . $data['sitemap_filename'];
+
+                // check filename length
+                if (strlen($data['sitemap_filename']) > self::MAXIMUM_SITEMAP_NAME_LENGTH) {
+                    Mage::getSingleton('adminhtml/session')->addError(
+                        Mage::helper('sitemap')->__(
+                            'Please enter a sitemap name with at most %s characters.',
+                            self::MAXIMUM_SITEMAP_NAME_LENGTH
+                        ));
+                    $this->_redirect('*/*/edit', array(
+                        'sitemap_id' => $this->getRequest()->getParam('sitemap_id')
+                    ));
+                    return;
+                }
                 /** @var $validator Mage_Core_Model_File_Validator_AvailablePath */
                 $validator = Mage::getModel('core/file_validator_availablePath');
                 /** @var $helper Mage_Adminhtml_Helper_Catalog */
diff --git app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php
index e64cd9fb42e..73efe007da3 100644
--- app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php
+++ app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php
@@ -89,6 +89,11 @@ class Mage_Adminhtml_System_Email_TemplateController extends Mage_Adminhtml_Cont
         $this->renderLayout();
     }
 
+    /**
+     * Save action
+     *
+     * @throws Mage_Core_Exception
+     */
     public function saveAction()
     {
         $request = $this->getRequest();
@@ -102,6 +107,11 @@ class Mage_Adminhtml_System_Email_TemplateController extends Mage_Adminhtml_Cont
         }
 
         try {
+            $allowedHtmlTags = ['template_text', 'styles'];
+            if (Mage::helper('adminhtml')->hasTags($request->getParams(), $allowedHtmlTags)) {
+                Mage::throwException(Mage::helper('adminhtml')->__('Invalid template data.'));
+            }
+
             $template->setTemplateSubject($request->getParam('template_subject'))
                 ->setTemplateCode($request->getParam('template_code'))
 /*
diff --git app/code/core/Mage/Catalog/Helper/Product.php app/code/core/Mage/Catalog/Helper/Product.php
old mode 100755
new mode 100644
index 0627150adef..bc8774c8aa7
--- app/code/core/Mage/Catalog/Helper/Product.php
+++ app/code/core/Mage/Catalog/Helper/Product.php
@@ -468,4 +468,41 @@ class Mage_Catalog_Helper_Product extends Mage_Core_Helper_Url
     {
         return $this->_skipSaleableCheck;
     }
+
+    /**
+     * Get default product value by field name
+     *
+     * @param string $fieldName
+     * @param string $productType
+     * @return int
+     */
+    public function getDefaultProductValue($fieldName, $productType)
+    {
+        $fieldData = $this->getFieldset($fieldName) ? (array) $this->getFieldset($fieldName) : null;
+        if (
+            count($fieldData)
+            && array_key_exists($productType, $fieldData['product_type'])
+            && (bool)$fieldData['use_config']
+        ) {
+            return $fieldData['inventory'];
+        }
+        return self::DEFAULT_QTY;
+    }
+
+    /**
+     * Return array from config by fieldset name and area
+     *
+     * @param null|string $field
+     * @param string $fieldset
+     * @param string $area
+     * @return array|null
+     */
+    public function getFieldset($field = null, $fieldset = 'catalog_product_dataflow', $area = 'admin')
+    {
+        $fieldsetData = Mage::getConfig()->getFieldset($fieldset, $area);
+        if ($fieldsetData) {
+            return $fieldsetData ? $fieldsetData->$field : $fieldsetData;
+        }
+        return $fieldsetData;
+    }
 }
diff --git app/code/core/Mage/Catalog/controllers/Product/CompareController.php app/code/core/Mage/Catalog/controllers/Product/CompareController.php
index 54aea41520a..613d81c2f51 100644
--- app/code/core/Mage/Catalog/controllers/Product/CompareController.php
+++ app/code/core/Mage/Catalog/controllers/Product/CompareController.php
@@ -80,7 +80,7 @@ class Mage_Catalog_Product_CompareController extends Mage_Core_Controller_Front_
         }
 
         $productId = (int) $this->getRequest()->getParam('product');
-        if ($productId
+        if ($this->isProductAvailable($productId)
             && (Mage::getSingleton('log/visitor')->getId() || Mage::getSingleton('customer/session')->isLoggedIn())
         ) {
             $product = Mage::getModel('catalog/product')
@@ -106,7 +106,8 @@ class Mage_Catalog_Product_CompareController extends Mage_Core_Controller_Front_
      */
     public function removeAction()
     {
-        if ($productId = (int) $this->getRequest()->getParam('product')) {
+        $productId = (int) $this->getRequest()->getParam('product');
+        if ($this->isProductAvailable($productId)) {
             $product = Mage::getModel('catalog/product')
                 ->setStoreId(Mage::app()->getStore()->getId())
                 ->load($productId);
@@ -184,4 +185,15 @@ class Mage_Catalog_Product_CompareController extends Mage_Core_Controller_Front_
         $this->_customerId = $id;
         return $this;
     }
+
+    /**
+     * Check if product is available
+     *
+     * @param int $productId
+     * @return bool
+     */
+    public function isProductAvailable($productId)
+    {
+        return Mage::getModel('catalog/product')->load($productId)->isAvailable();
+    }
 }
diff --git app/code/core/Mage/Checkout/Model/Session.php app/code/core/Mage/Checkout/Model/Session.php
index b11304a4c6d..1878491d51b 100644
--- app/code/core/Mage/Checkout/Model/Session.php
+++ app/code/core/Mage/Checkout/Model/Session.php
@@ -113,13 +113,21 @@ class Mage_Checkout_Model_Session extends Mage_Core_Model_Session_Abstract
         if ($this->_quote === null) {
             /** @var $quote Mage_Sales_Model_Quote */
             $quote = Mage::getModel('sales/quote')->setStoreId(Mage::app()->getStore()->getId());
+            $customerSession = Mage::getSingleton('customer/session');
+
             if ($this->getQuoteId()) {
                 if ($this->_loadInactive) {
                     $quote->load($this->getQuoteId());
                 } else {
                     $quote->loadActive($this->getQuoteId());
                 }
-                if ($quote->getId()) {
+                if (
+                    $quote->getId()
+                    && (
+                        ($customerSession->isLoggedIn() && $customerSession->getId() == $quote->getCustomerId())
+                        || (!$customerSession->isLoggedIn() && !$quote->getCustomerId())
+                    )
+                ) {
                     /**
                      * If current currency code of quote is not equal current currency code of store,
                      * need recalculate totals of quote. It is possible if customer use currency switcher or
@@ -136,16 +144,16 @@ class Mage_Checkout_Model_Session extends Mage_Core_Model_Session_Abstract
                         $quote->load($this->getQuoteId());
                     }
                 } else {
+                    $quote->unsetData();
                     $this->setQuoteId(null);
                 }
             }
 
-            $customerSession = Mage::getSingleton('customer/session');
-
             if (!$this->getQuoteId()) {
                 if ($customerSession->isLoggedIn() || $this->_customer) {
                     $customer = ($this->_customer) ? $this->_customer : $customerSession->getCustomer();
                     $quote->loadByCustomer($customer);
+                    $quote->setCustomer($customer);
                     $this->setQuoteId($quote->getId());
                 } else {
                     $quote->setIsCheckoutCart(true);
diff --git app/code/core/Mage/Checkout/controllers/OnepageController.php app/code/core/Mage/Checkout/controllers/OnepageController.php
index dec5455457b..f5c2173e56d 100644
--- app/code/core/Mage/Checkout/controllers/OnepageController.php
+++ app/code/core/Mage/Checkout/controllers/OnepageController.php
@@ -545,7 +545,7 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
      */
     public function saveOrderAction()
     {
-        if (!$this->_validateFormKey()) {
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
             return $this->_redirect('*/*');
         }
 
diff --git app/code/core/Mage/Cms/Helper/Data.php app/code/core/Mage/Cms/Helper/Data.php
index b625ae66dec..36d8575969f 100644
--- app/code/core/Mage/Cms/Helper/Data.php
+++ app/code/core/Mage/Cms/Helper/Data.php
@@ -37,6 +37,7 @@ class Mage_Cms_Helper_Data extends Mage_Core_Helper_Abstract
     const XML_NODE_PAGE_TEMPLATE_FILTER     = 'global/cms/page/tempate_filter';
     const XML_NODE_BLOCK_TEMPLATE_FILTER    = 'global/cms/block/tempate_filter';
     const XML_NODE_ALLOWED_STREAM_WRAPPERS  = 'global/cms/allowed_stream_wrappers';
+    const XML_NODE_ALLOWED_MEDIA_EXT_SWF    = 'adminhtml/cms/browser/extensions/media_allowed/swf';
 
     /**
      * Retrieve Template processor for Page Content
@@ -74,4 +75,19 @@ class Mage_Cms_Helper_Data extends Mage_Core_Helper_Abstract
 
         return is_array($allowedStreamWrappers) ? $allowedStreamWrappers : array();
     }
+
+    /**
+     * Check is swf file extension disabled
+     *
+     * @return bool
+     */
+    public function isSwfDisabled()
+    {
+        $statusSwf = Mage::getConfig()->getNode(self::XML_NODE_ALLOWED_MEDIA_EXT_SWF);
+        if ($statusSwf instanceof Mage_Core_Model_Config_Element) {
+            $statusSwf = $statusSwf->asArray()[0];
+        }
+
+        return $statusSwf ? false : true;
+    }
 }
diff --git app/code/core/Mage/Cms/Model/Wysiwyg/Config.php app/code/core/Mage/Cms/Model/Wysiwyg/Config.php
index 0f245fc905e..b36675ab0f6 100644
--- app/code/core/Mage/Cms/Model/Wysiwyg/Config.php
+++ app/code/core/Mage/Cms/Model/Wysiwyg/Config.php
@@ -76,7 +76,8 @@ class Mage_Cms_Model_Wysiwyg_Config extends Varien_Object
             'content_css'                   =>
                 Mage::getBaseUrl('js').'mage/adminhtml/wysiwyg/tiny_mce/themes/advanced/skins/default/content.css',
             'width'                         => '100%',
-            'plugins'                       => array()
+            'plugins'                       => array(),
+            'media_disable_flash'           => Mage::helper('cms')->isSwfDisabled()
         ));
 
         $config->setData('directives_url_quoted', preg_quote($config->getData('directives_url')));
diff --git app/code/core/Mage/Cms/etc/config.xml app/code/core/Mage/Cms/etc/config.xml
index ea558a6f924..c366b31ca9c 100644
--- app/code/core/Mage/Cms/etc/config.xml
+++ app/code/core/Mage/Cms/etc/config.xml
@@ -122,7 +122,7 @@
                     </image_allowed>
                     <media_allowed>
                         <flv>1</flv>
-                        <swf>1</swf>
+                        <swf>0</swf>
                         <avi>1</avi>
                         <mov>1</mov>
                         <rm>1</rm>
diff --git app/code/core/Mage/Compiler/Model/Process.php app/code/core/Mage/Compiler/Model/Process.php
index c9ffe460e3b..9eb68e49717 100644
--- app/code/core/Mage/Compiler/Model/Process.php
+++ app/code/core/Mage/Compiler/Model/Process.php
@@ -43,6 +43,9 @@ class Mage_Compiler_Model_Process
 
     protected $_controllerFolders = array();
 
+    /** $_collectLibs library list array */
+    protected $_collectLibs = array();
+
     public function __construct($options=array())
     {
         if (isset($options['compile_dir'])) {
@@ -128,6 +131,9 @@ class Mage_Compiler_Model_Process
                 || !in_array(substr($source, strlen($source)-4, 4), array('.php'))) {
                 return $this;
             }
+            if (!$firstIteration && stripos($source, Mage::getBaseDir('lib') . DS) !== false) {
+                $this->_collectLibs[] = $target;
+            }
             copy($source, $target);
         }
         return $this;
@@ -341,6 +347,11 @@ class Mage_Compiler_Model_Process
     {
         $sortedClasses = array();
         foreach ($classes as $className) {
+            /** Skip iteration if this class has already been moved to the includes folder from the lib */
+            if (array_search($this->_includeDir . DS . $className . '.php', $this->_collectLibs)) {
+                continue;
+            }
+
             $implements = array_reverse(class_implements($className));
             foreach ($implements as $class) {
                 if (!in_array($class, $sortedClasses) && !in_array($class, $this->_processedClasses) && strstr($class, '_')) {
diff --git app/code/core/Mage/Core/Helper/Abstract.php app/code/core/Mage/Core/Helper/Abstract.php
index 725ab72d063..63b679dc5d2 100644
--- app/code/core/Mage/Core/Helper/Abstract.php
+++ app/code/core/Mage/Core/Helper/Abstract.php
@@ -422,4 +422,42 @@ abstract class Mage_Core_Helper_Abstract
         }
         return $arr;
     }
+
+    /**
+     * Check for tags in multidimensional arrays
+     *
+     * @param string|array $data
+     * @param array $arrayKeys keys of the array being checked that are excluded and included in the check
+     * @param bool $skipTags skip transferred array keys, if false then check only them
+     * @return bool
+     */
+    public function hasTags($data, array $arrayKeys = array(), $skipTags = true)
+    {
+        if (is_array($data)) {
+            foreach ($data as $key => $item) {
+                if ($skipTags && in_array($key, $arrayKeys)) {
+                    continue;
+                }
+                if (is_array($item)) {
+                    if ($this->hasTags($item, $arrayKeys, $skipTags)) {
+                        return true;
+                    }
+                } elseif (
+                    (bool)strcmp($item, $this->removeTags($item))
+                    || (bool)strcmp($key, $this->removeTags($key))
+                ) {
+                    if (!$skipTags && !in_array($key, $arrayKeys)) {
+                        continue;
+                    }
+                    return true;
+                }
+            }
+            return false;
+        } elseif (is_string($data)) {
+            if ((bool)strcmp($data, $this->removeTags($data))) {
+                return true;
+            }
+        }
+        return false;
+    }
 }
diff --git app/code/core/Mage/Core/Helper/Data.php app/code/core/Mage/Core/Helper/Data.php
index 1a1b09fb0ca..97dfa4fb06b 100644
--- app/code/core/Mage/Core/Helper/Data.php
+++ app/code/core/Mage/Core/Helper/Data.php
@@ -255,7 +255,7 @@ class Mage_Core_Helper_Data extends Mage_Core_Helper_Abstract
         }
         mt_srand(10000000*(double)microtime());
         for ($i = 0, $str = '', $lc = strlen($chars)-1; $i < $len; $i++) {
-            $str .= $chars[mt_rand(0, $lc)];
+            $str .= $chars[random_int(0, $lc)];
         }
         return $str;
     }
diff --git app/code/core/Mage/Core/Model/Design/Package.php app/code/core/Mage/Core/Model/Design/Package.php
index e3e77672ebb..73cf7e6886b 100644
--- app/code/core/Mage/Core/Model/Design/Package.php
+++ app/code/core/Mage/Core/Model/Design/Package.php
@@ -567,7 +567,11 @@ class Mage_Core_Model_Design_Package
             return false;
         }
 
-        $regexps = @unserialize($configValueSerialized);
+        try {
+            $regexps = Mage::helper('core/unserializeArray')->unserialize($configValueSerialized);
+        } catch (Exception $e) {
+            Mage::logException($e);
+        }
 
         if (empty($regexps)) {
             return false;
diff --git app/code/core/Mage/Core/Model/Email/Template/Filter.php app/code/core/Mage/Core/Model/Email/Template/Filter.php
index c75193653b3..138021cb1ca 100644
--- app/code/core/Mage/Core/Model/Email/Template/Filter.php
+++ app/code/core/Mage/Core/Model/Email/Template/Filter.php
@@ -518,4 +518,24 @@ class Mage_Core_Model_Email_Template_Filter extends Varien_Filter_Template
         }
         return $value;
     }
+
+    /**
+     * Return variable value for var construction
+     *
+     * @param string $value raw parameters
+     * @param string $default default value
+     * @return string
+     */
+    protected function _getVariable($value, $default = '{no_value_defined}')
+    {
+        Mage::register('varProcessing', true);
+        try {
+            $result = parent::_getVariable($value, $default);
+        } catch (Exception $e) {
+            $result = '';
+            Mage::logException($e);
+        }
+        Mage::unregister('varProcessing');
+        return $result;
+    }
 }
diff --git app/code/core/Mage/Core/Model/File/Validator/AvailablePath.php app/code/core/Mage/Core/Model/File/Validator/AvailablePath.php
index 202d98e46ba..a01876620d2 100644
--- app/code/core/Mage/Core/Model/File/Validator/AvailablePath.php
+++ app/code/core/Mage/Core/Model/File/Validator/AvailablePath.php
@@ -230,8 +230,16 @@ class Mage_Core_Model_File_Validator_AvailablePath extends Zend_Validate_Abstrac
         }
 
         //validation
+        $protectedExtensions = Mage::helper('core/data')->getProtectedFileExtensions();
         $value = str_replace(array('/', '\\'), DS, $this->_value);
         $valuePathInfo = pathinfo(ltrim($value, '\\/'));
+        $fileNameExtension = pathinfo($valuePathInfo['filename'], PATHINFO_EXTENSION);
+
+        if (in_array($fileNameExtension, $protectedExtensions)) {
+            $this->_error(self::NOT_AVAILABLE_PATH, $this->_value);
+            return false;
+        }
+
         if ($valuePathInfo['dirname'] == '.' || $valuePathInfo['dirname'] == DS) {
             $valuePathInfo['dirname'] = '';
         }
diff --git app/code/core/Mage/Core/Model/Observer.php app/code/core/Mage/Core/Model/Observer.php
index 3710df2072a..9bc1bb693e3 100644
--- app/code/core/Mage/Core/Model/Observer.php
+++ app/code/core/Mage/Core/Model/Observer.php
@@ -105,4 +105,19 @@ class Mage_Core_Model_Observer
         Mage::app()->getCache()->clean(Zend_Cache::CLEANING_MODE_OLD);
         Mage::dispatchEvent('core_clean_cache');
     }
+
+    /**
+     * Checks method availability for processing in variable
+     *
+     * @param Varien_Event_Observer $observer
+     * @throws Exception
+     * @return Mage_Core_Model_Observer
+     */
+    public function secureVarProcessing(Varien_Event_Observer $observer)
+    {
+        if (Mage::registry('varProcessing')) {
+            Mage::throwException(Mage::helper('core')->__('Disallowed template variable method.'));
+        }
+        return $this;
+    }
 }
diff --git app/code/core/Mage/Core/etc/config.xml app/code/core/Mage/Core/etc/config.xml
index 4b28f2765a1..e8ab8986ddc 100644
--- app/code/core/Mage/Core/etc/config.xml
+++ app/code/core/Mage/Core/etc/config.xml
@@ -146,6 +146,24 @@
                 <writer_model>Zend_Log_Writer_Stream</writer_model>
             </core>
         </log>
+        <events>
+            <model_save_before>
+                <observers>
+                    <secure_var_processing>
+                        <class>core/observer</class>
+                        <method>secureVarProcessing</method>
+                    </secure_var_processing>
+                </observers>
+            </model_save_before>
+            <model_delete_before>
+                <observers>
+                    <secure_var_processing>
+                        <class>core/observer</class>
+                        <method>secureVarProcessing</method>
+                    </secure_var_processing>
+                </observers>
+            </model_delete_before>
+        </events>
     </global>
     <frontend>
         <routers>
diff --git app/code/core/Mage/Core/functions.php app/code/core/Mage/Core/functions.php
index b41a4578af1..44c80b44b82 100644
--- app/code/core/Mage/Core/functions.php
+++ app/code/core/Mage/Core/functions.php
@@ -410,3 +410,19 @@ if (!function_exists('hash_equals')) {
         return 0 === $result;
     }
 }
+
+if (version_compare(PHP_VERSION, '7.0.0', '<') && !function_exists('random_int')) {
+    /**
+     * Generates pseudo-random integers
+     *
+     * @param int $min
+     * @param int $max
+     * @return int Returns random integer in the range $min to $max, inclusive.
+     */
+    function random_int($min, $max)
+    {
+        mt_srand();
+
+        return mt_rand($min, $max);
+    }
+}
diff --git app/code/core/Mage/CurrencySymbol/Model/System/Currencysymbol.php app/code/core/Mage/CurrencySymbol/Model/System/Currencysymbol.php
index 3b7e77c821c..efb2e063995 100644
--- app/code/core/Mage/CurrencySymbol/Model/System/Currencysymbol.php
+++ app/code/core/Mage/CurrencySymbol/Model/System/Currencysymbol.php
@@ -274,7 +274,11 @@ class Mage_CurrencySymbol_Model_System_Currencysymbol
         $result = array();
         $configData = (string)Mage::getStoreConfig($configPath, $storeId);
         if ($configData) {
-            $result = unserialize($configData);
+            try {
+                $result = Mage::helper('core/unserializeArray')->unserialize($configData);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
         }
 
         return is_array($result) ? $result : array();
diff --git app/code/core/Mage/Downloadable/controllers/DownloadController.php app/code/core/Mage/Downloadable/controllers/DownloadController.php
index 7941fab76f0..ec245e53a8e 100644
--- app/code/core/Mage/Downloadable/controllers/DownloadController.php
+++ app/code/core/Mage/Downloadable/controllers/DownloadController.php
@@ -96,7 +96,12 @@ class Mage_Downloadable_DownloadController extends Mage_Core_Controller_Front_Ac
     {
         $sampleId = $this->getRequest()->getParam('sample_id', 0);
         $sample = Mage::getModel('downloadable/sample')->load($sampleId);
-        if ($sample->getId()) {
+        if (
+            $sample->getId()
+            && Mage::helper('catalog/product')
+                ->getProduct((int) $sample->getProductId(), Mage::app()->getStore()->getId(), 'id')
+                ->isAvailable()
+        ) {
             $resource = '';
             $resourceType = '';
             if ($sample->getSampleType() == Mage_Downloadable_Helper_Download::LINK_TYPE_URL) {
@@ -126,7 +131,12 @@ class Mage_Downloadable_DownloadController extends Mage_Core_Controller_Front_Ac
     {
         $linkId = $this->getRequest()->getParam('link_id', 0);
         $link = Mage::getModel('downloadable/link')->load($linkId);
-        if ($link->getId()) {
+        if (
+            $link->getId()
+            && Mage::helper('catalog/product')
+                ->getProduct((int) $link->getProductId(), Mage::app()->getStore()->getId(), 'id')
+                ->isAvailable()
+        ) {
             $resource = '';
             $resourceType = '';
             if ($link->getSampleType() == Mage_Downloadable_Helper_Download::LINK_TYPE_URL) {
diff --git app/code/core/Mage/SalesRule/Model/Coupon/Massgenerator.php app/code/core/Mage/SalesRule/Model/Coupon/Massgenerator.php
index 4fb7c31f0ad..8745e37b6c5 100644
--- app/code/core/Mage/SalesRule/Model/Coupon/Massgenerator.php
+++ app/code/core/Mage/SalesRule/Model/Coupon/Massgenerator.php
@@ -79,7 +79,7 @@ class Mage_SalesRule_Model_Coupon_Massgenerator extends Mage_Core_Model_Abstract
         $code = '';
         $charsetSize = count($charset);
         for ($i=0; $i<$length; $i++) {
-            $char = $charset[mt_rand(0, $charsetSize - 1)];
+            $char = $charset[random_int(0, $charsetSize - 1)];
             if ($split > 0 && ($i % $split) == 0 && $i != 0) {
                 $char = $splitChar . $char;
             }
diff --git app/code/core/Mage/SalesRule/Model/Resource/Report/Rule/Createdat.php app/code/core/Mage/SalesRule/Model/Resource/Report/Rule/Createdat.php
index fa6f8037320..449bff7f705 100644
--- app/code/core/Mage/SalesRule/Model/Resource/Report/Rule/Createdat.php
+++ app/code/core/Mage/SalesRule/Model/Resource/Report/Rule/Createdat.php
@@ -118,14 +118,14 @@ class Mage_SalesRule_Model_Resource_Report_Rule_Createdat extends Mage_Reports_M
                         $adapter->getIfNullSql('base_subtotal_refunded', 0). ') * base_to_global_rate)', 0),
 
                 'discount_amount_actual'  =>
-                    $adapter->getIfNullSql('SUM((base_discount_invoiced - ' .
+                    $adapter->getIfNullSql('SUM((ABS(base_discount_invoiced) - ' .
                         $adapter->getIfNullSql('base_discount_refunded', 0) . ')
                         * base_to_global_rate)', 0),
 
                 'total_amount_actual'     =>
                     $adapter->getIfNullSql('SUM((base_subtotal_invoiced - ' .
                         $adapter->getIfNullSql('base_subtotal_refunded', 0) . ' - ' .
-                        $adapter->getIfNullSql('base_discount_invoiced - ' .
+                        $adapter->getIfNullSql('ABS(base_discount_invoiced) - ' .
                         $adapter->getIfNullSql('base_discount_refunded', 0), 0) .
                         ') * base_to_global_rate)', 0),
             );
diff --git app/code/core/Mage/Sendfriend/etc/config.xml app/code/core/Mage/Sendfriend/etc/config.xml
index c8531f992cd..3ec8275535a 100644
--- app/code/core/Mage/Sendfriend/etc/config.xml
+++ app/code/core/Mage/Sendfriend/etc/config.xml
@@ -122,7 +122,7 @@
     <default>
         <sendfriend>
             <email>
-                <enabled>1</enabled>
+                <enabled>0</enabled>
                 <template>sendfriend_email_template</template>
                 <allow_guest>0</allow_guest>
                 <max_recipients>5</max_recipients>
diff --git app/code/core/Mage/Sendfriend/etc/system.xml app/code/core/Mage/Sendfriend/etc/system.xml
index ac12a798bea..6759f125ea0 100644
--- app/code/core/Mage/Sendfriend/etc/system.xml
+++ app/code/core/Mage/Sendfriend/etc/system.xml
@@ -52,6 +52,7 @@
                             <show_in_default>1</show_in_default>
                             <show_in_website>1</show_in_website>
                             <show_in_store>1</show_in_store>
+                            <comment><![CDATA[<strong style="color:red">Warning!</strong> This functionality is vulnerable and can be abused to distribute spam.]]></comment>
                         </enabled>
                         <template translate="label">
                             <label>Select Email Template</label>
diff --git app/design/adminhtml/default/default/template/catalog/product/composite/fieldset/configurable.phtml app/design/adminhtml/default/default/template/catalog/product/composite/fieldset/configurable.phtml
index e65271dbb06..1aa2964305e 100644
--- app/design/adminhtml/default/default/template/catalog/product/composite/fieldset/configurable.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/composite/fieldset/configurable.phtml
@@ -35,7 +35,7 @@
     <div class="product-options">
         <dl>
         <?php foreach($_attributes as $_attribute): ?>
-            <dt><label class="required"><em>*</em><?php echo $_attribute->getLabel() ?></label></dt>
+            <dt><label class="required"><em>*</em><?php echo $this->escapeHtml($_attribute->getLabel()) ?></label></dt>
             <dd<?php if ($_attribute->decoratedIsLast){?> class="last"<?php }?>>
                 <div class="input-box">
                     <select name="super_attribute[<?php echo $_attribute->getAttributeId() ?>]" id="attribute<?php echo $_attribute->getAttributeId() ?>" class="required-entry super-attribute-select">
diff --git app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
index 88f050ed55c..7f0e70fb3ab 100644
--- app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
@@ -59,7 +59,7 @@ $_block = $this;
             <th><?php echo Mage::helper('catalog')->__('Label') ?></th>
             <th><?php echo Mage::helper('catalog')->__('Sort Order') ?></th>
             <?php foreach ($_block->getImageTypes() as $typeId => $type): ?>
-                <th><?php echo $this->escapeHtml($type['label']); ?></th>
+                <th><?php echo $this->escapeHtml($type['label'], array('br')); ?></th>
             <?php endforeach; ?>
             <th><?php echo Mage::helper('catalog')->__('Exclude') ?></th>
             <th class="last"><?php echo Mage::helper('catalog')->__('Remove') ?></th>
diff --git app/design/adminhtml/default/default/template/catalog/product/tab/inventory.phtml app/design/adminhtml/default/default/template/catalog/product/tab/inventory.phtml
index 4d3bcc5a4bd..d327ed07657 100644
--- app/design/adminhtml/default/default/template/catalog/product/tab/inventory.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/tab/inventory.phtml
@@ -77,7 +77,7 @@
 
         <tr>
             <td class="label"><label for="inventory_min_sale_qty"><?php echo Mage::helper('catalog')->__('Minimum Qty Allowed in Shopping Cart') ?></label></td>
-            <td class="value"><input type="text" class="input-text validate-number" id="inventory_min_sale_qty" name="<?php echo $this->getFieldSuffix() ?>[stock_data][min_sale_qty]" value="<?php echo $this->getFieldValue('min_sale_qty')*1 ?>" <?php echo $_readonly;?>/>
+            <td class="value"><input type="text" class="input-text validate-number" id="inventory_min_sale_qty" name="<?php echo $this->getFieldSuffix() ?>[stock_data][min_sale_qty]" value="<?php echo (bool)$this->getProduct()->getId() ? (int)$this->getFieldValue('min_sale_qty') : Mage::helper('catalog/product')->getDefaultProductValue('min_sale_qty', $this->getProduct()->getTypeId()) ?>" <?php echo $_readonly ?>/>
 
             <?php $_checked = ($this->getFieldValue('use_config_min_sale_qty') || $this->IsNew()) ? 'checked="checked"' : '' ?>
             <input type="checkbox" id="inventory_use_config_min_sale_qty" name="<?php echo $this->getFieldSuffix() ?>[stock_data][use_config_min_sale_qty]" value="1" <?php echo $_checked ?> onclick="toggleValueElements(this, this.parentNode);" class="checkbox" <?php echo $_readonly;?> />
diff --git app/design/adminhtml/default/default/template/currencysymbol/grid.phtml app/design/adminhtml/default/default/template/currencysymbol/grid.phtml
index 40ee532e203..b7ecc5edc58 100644
--- app/design/adminhtml/default/default/template/currencysymbol/grid.phtml
+++ app/design/adminhtml/default/default/template/currencysymbol/grid.phtml
@@ -66,12 +66,12 @@
                             <?php foreach($this->getCurrencySymbolsData() as $code => $data): ?>
                             <tr>
                                 <td class="label">
-                                <label for="custom_currency_symbol<?php echo $code; ?>"><?php echo $code; ?> (<?php echo $data['displayName']; ?>)</label>
+                                <label for="custom_currency_symbol<?php echo $this->escapeHtml($code); ?>"><?php echo $this->escapeHtml($code); ?> (<?php echo $this->escapeHtml($data['displayName']); ?>)</label>
                                 </td>
                                 <td class="value">
-                                    <input id="custom_currency_symbol<?php echo $code; ?>" class=" required-entry input-text" type="text" value="<?php echo Mage::helper('core')->quoteEscape($data['displaySymbol']); ?>"<?php echo $data['inherited'] ? ' disabled="disabled"' : '';?> name="custom_currency_symbol[<?php echo $code; ?>]">
-                                    &nbsp; <input id="custom_currency_symbol_inherit<?php echo $code; ?>" class="checkbox config-inherit" type="checkbox" onclick="toggleUseDefault(<?php echo '\'' . $code . '\',\'' . Mage::helper('core')->quoteEscape($data['parentSymbol'], true) . '\''; ?>)"<?php echo $data['inherited'] ? ' checked="checked"' : ''; ?> value="1" name="inherit_custom_currency_symbol[<?php echo $code; ?>]">
-                                    <label class="inherit" title="" for="custom_currency_symbol_inherit<?php echo $code; ?>"><?php echo $this->getInheritText(); ?></label>
+                                    <input id="custom_currency_symbol<?php echo $this->escapeHtml($code); ?>" class=" required-entry input-text" type="text" value="<?php echo Mage::helper('core')->quoteEscape($this->escapeHtml($data['displaySymbol'])); ?>"<?php echo $data['inherited'] ? ' disabled="disabled"' : '';?> name="custom_currency_symbol[<?php echo $this->escapeHtml($code); ?>]">
+                                    &nbsp; <input id="custom_currency_symbol_inherit<?php echo $this->escapeHtml($code); ?>" class="checkbox config-inherit" type="checkbox" onclick="toggleUseDefault(<?php echo '\'' . $this->escapeHtml($code) . '\',\'' . Mage::helper('core')->quoteEscape($data['parentSymbol'], true) . '\''; ?>)"<?php echo $data['inherited'] ? ' checked="checked"' : ''; ?> value="1" name="inherit_custom_currency_symbol[<?php echo $this->escapeHtml($code); ?>]">
+                                    <label class="inherit" title="" for="custom_currency_symbol_inherit<?php echo $this->escapeHtml($code); ?>"><?php echo $this->getInheritText(); ?></label>
                                 </td>
                             </tr>
                             <?php endforeach; ?>
diff --git app/design/adminhtml/default/default/template/customer/tab/addresses.phtml app/design/adminhtml/default/default/template/customer/tab/addresses.phtml
index 1001bacab4c..2756ade49d9 100644
--- app/design/adminhtml/default/default/template/customer/tab/addresses.phtml
+++ app/design/adminhtml/default/default/template/customer/tab/addresses.phtml
@@ -46,7 +46,7 @@
             </a>
             <?php endif;?>
             <address>
-                <?php echo $_address->format('html') ?>
+                <?php echo $this->maliciousCodeFilter($_address->format('html')) ?>
             </address>
             <div class="address-type">
                 <span class="address-type-line">
diff --git app/design/adminhtml/default/default/template/customer/tab/view.phtml app/design/adminhtml/default/default/template/customer/tab/view.phtml
index 062fc36ff23..ddf388d0e1b 100644
--- app/design/adminhtml/default/default/template/customer/tab/view.phtml
+++ app/design/adminhtml/default/default/template/customer/tab/view.phtml
@@ -75,7 +75,7 @@ $createDateStore    = $this->getStoreCreateDate();
         </table>
         <address class="box-right">
             <strong><?php echo $this->__('Default Billing Address') ?></strong><br/>
-            <?php echo $this->getBillingAddressHtml() ?>
+            <?php echo $this->maliciousCodeFilter($this->getBillingAddressHtml()) ?>
         </address>
     </fieldset>
 </div>
diff --git app/design/adminhtml/default/default/template/enterprise/checkout/manage.phtml app/design/adminhtml/default/default/template/enterprise/checkout/manage.phtml
index 1459e854284..94d36084b6a 100644
--- app/design/adminhtml/default/default/template/enterprise/checkout/manage.phtml
+++ app/design/adminhtml/default/default/template/enterprise/checkout/manage.phtml
@@ -39,7 +39,7 @@
 <script type="text/javascript">
     checkoutObj = new AdminCheckout(<?php echo $this->getOrderDataJson() ?>);
     checkoutObj.setLoadBaseUrl('<?php echo $this->getLoadBlockUrl() ?>');
-    checkoutObj.setCurrencySymbol('<?php echo $this->getCurrencySymbol($this->getCurrentCurrencyCode()) ?>');
+    checkoutObj.setCurrencySymbol('<?php echo Mage::helper('core')->jsQuoteEscape($this->getCurrencySymbol($this->getCurrentCurrencyCode())) ?>');
 </script>
 
 <div class="content-header">
diff --git app/design/adminhtml/default/default/template/enterprise/rma/edit/general/details.phtml app/design/adminhtml/default/default/template/enterprise/rma/edit/general/details.phtml
index 0f9c77dda60..6aea2ca063b 100644
--- app/design/adminhtml/default/default/template/enterprise/rma/edit/general/details.phtml
+++ app/design/adminhtml/default/default/template/enterprise/rma/edit/general/details.phtml
@@ -44,7 +44,11 @@ $customerLink = $this->getCustomerLink();
                 </tr>
                 <tr>
                     <td class="label"><label><?php echo Mage::helper('enterprise_rma')->__('Order ID') ?></label></td>
-                    <td class="value"><a href="<?php echo $this->getOrderLink() ?>"><?php echo Mage::helper('enterprise_rma')->__('#') . $this->getOrderIncrementId() ?></a></td>
+                    <td class="value">
+                        <a href="<?php echo $this->getOrderLink() ?>">
+                            <?php echo Mage::helper('enterprise_rma')->__('#') . $this->escapeHtml($this->getOrderIncrementId()) ?>
+                        </a>
+                    </td>
                 </tr>
                 <tr>
                     <td class="label"><label><?php echo Mage::helper('enterprise_rma')->__('Customer Name') ?></label></td>
diff --git app/design/adminhtml/default/default/template/enterprise/rma/edit/general/returnadress.phtml app/design/adminhtml/default/default/template/enterprise/rma/edit/general/returnadress.phtml
index dda074707bc..f3a95a6dc1c 100644
--- app/design/adminhtml/default/default/template/enterprise/rma/edit/general/returnadress.phtml
+++ app/design/adminhtml/default/default/template/enterprise/rma/edit/general/returnadress.phtml
@@ -36,6 +36,6 @@ $customerLink = $this->getCustomerLink();
         <h4 class="icon-head head-shipping-method"><?php echo Mage::helper('enterprise_rma')->__('Return Address') ?></h4>
     </div>
     <fieldset>
-        <address><?php echo $this->getReturnAddress() ?></address>
+        <address><?php echo $this->maliciousCodeFilter($this->getReturnAddress()) ?></address>
     </fieldset>
 </div>
diff --git app/design/adminhtml/default/default/template/enterprise/rma/edit/general/shippingaddress.phtml app/design/adminhtml/default/default/template/enterprise/rma/edit/general/shippingaddress.phtml
index 80bf469f7d4..d247990fb95 100644
--- app/design/adminhtml/default/default/template/enterprise/rma/edit/general/shippingaddress.phtml
+++ app/design/adminhtml/default/default/template/enterprise/rma/edit/general/shippingaddress.phtml
@@ -36,7 +36,7 @@
         </div>
         <fieldset>
             <br />
-            <address><?php echo $this->getOrderShippingAddress() ?></address>
+            <address><?php echo $this->maliciousCodeFilter($this->getOrderShippingAddress()) ?></address>
         </fieldset>
     </div>
 <?php endif ?>
diff --git app/design/adminhtml/default/default/template/enterprise/rma/new/general/details.phtml app/design/adminhtml/default/default/template/enterprise/rma/new/general/details.phtml
index 98f3a77c5cb..3fdfcf1d3c4 100644
--- app/design/adminhtml/default/default/template/enterprise/rma/new/general/details.phtml
+++ app/design/adminhtml/default/default/template/enterprise/rma/new/general/details.phtml
@@ -40,7 +40,11 @@ $customerLink = $this->getCustomerLink();
             <table cellspacing="0" class="form-list">
                 <tr>
                     <td class="label"><label><?php echo Mage::helper('enterprise_rma')->__('Order ID') ?></label></td>
-                    <td class="value"><a href="<?php echo $this->getOrderLink() ?>"><?php echo Mage::helper('enterprise_rma')->__('#') . $this->getOrderIncrementId() ?></a></td>
+                    <td class="value">
+                        <a href="<?php echo $this->getOrderLink() ?>">
+                            <?php echo Mage::helper('enterprise_rma')->__('#') . $this->escapeHtml($this->getOrderIncrementId()) ?>
+                        </a>
+                    </td>
                 </tr>
                 <tr>
                     <td class="label"><label><?php echo Mage::helper('enterprise_rma')->__('Customer Name') ?></label></td>
diff --git app/design/adminhtml/default/default/template/notification/window.phtml app/design/adminhtml/default/default/template/notification/window.phtml
index b7184a64a65..844305cad75 100644
--- app/design/adminhtml/default/default/template/notification/window.phtml
+++ app/design/adminhtml/default/default/template/notification/window.phtml
@@ -68,7 +68,7 @@
     </div>
     <div class="message-popup-content">
         <div class="message">
-            <span class="message-icon message-<?php echo $this->getSeverityText();?>" style="background-image:url(<?php echo $this->getSeverityIconsUrl() ?>);"><?php echo $this->getSeverityText();?></span>
+            <span class="message-icon message-<?php echo $this->getSeverityText(); ?>" style="background-image:url(<?php echo $this->escapeUrl($this->getSeverityIconsUrl()); ?>);"><?php echo $this->getSeverityText(); ?></span>
             <p class="message-text"><?php echo $this->getNoticeMessageText(); ?></p>
         </div>
         <p class="read-more"><a href="<?php echo $this->getNoticeMessageUrl(); ?>" onclick="this.target='_blank';"><?php echo $this->getReadDetailsText(); ?></a></p>
diff --git app/design/adminhtml/default/default/template/sales/order/create/data.phtml app/design/adminhtml/default/default/template/sales/order/create/data.phtml
index 202235412c7..7d084a165f5 100644
--- app/design/adminhtml/default/default/template/sales/order/create/data.phtml
+++ app/design/adminhtml/default/default/template/sales/order/create/data.phtml
@@ -33,7 +33,9 @@
     <?php endforeach; ?>
 </select>
 </p>
-<script type="text/javascript">order.setCurrencySymbol('<?php echo $this->getCurrencySymbol($this->getCurrentCurrencyCode()) ?>')</script>
+    <script type="text/javascript">
+        order.setCurrencySymbol('<?php echo Mage::helper('core')->jsQuoteEscape($this->getCurrencySymbol($this->getCurrentCurrencyCode())) ?>')
+    </script>
 <table cellspacing="0" width="100%">
 <tr>
     <?php if($this->getCustomerId()): ?>
diff --git app/design/adminhtml/default/default/template/sales/order/view/info.phtml app/design/adminhtml/default/default/template/sales/order/view/info.phtml
index 7295dffa0cb..76cf636cb35 100644
--- app/design/adminhtml/default/default/template/sales/order/view/info.phtml
+++ app/design/adminhtml/default/default/template/sales/order/view/info.phtml
@@ -39,9 +39,9 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
         endif; ?>
         <div class="entry-edit-head">
         <?php if ($this->getNoUseOrderLink()): ?>
-            <h4 class="icon-head head-account"><?php echo Mage::helper('sales')->__('Order # %s', $_order->getRealOrderId()) ?> (<?php echo $_email ?>)</h4>
+            <h4 class="icon-head head-account"><?php echo Mage::helper('sales')->__('Order # %s', $this->escapeHtml($_order->getRealOrderId())) ?> (<?php echo $_email ?>)</h4>
         <?php else: ?>
-            <a href="<?php echo $this->getViewUrl($_order->getId()) ?>"><?php echo Mage::helper('sales')->__('Order # %s', $_order->getRealOrderId()) ?></a>
+            <a href="<?php echo $this->getViewUrl($_order->getId()) ?>"><?php echo Mage::helper('sales')->__('Order # %s', $this->escapeHtml($_order->getRealOrderId())) ?></a>
             <strong>(<?php echo $_email ?>)</strong>
         <?php endif; ?>
         </div>
@@ -69,7 +69,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
             <tr>
                 <td class="label"><label><?php echo Mage::helper('sales')->__('Link to the New Order') ?></label></td>
                 <td class="value"><a href="<?php echo $this->getViewUrl($_order->getRelationChildId()) ?>">
-                    <?php echo $_order->getRelationChildRealId() ?>
+                    <?php echo $this->escapeHtml($_order->getRelationChildRealId()) ?>
                 </a></td>
             </tr>
             <?php endif; ?>
@@ -77,7 +77,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
             <tr>
                 <td class="label"><label><?php echo Mage::helper('sales')->__('Link to the Previous Order') ?></label></td>
                 <td class="value"><a href="<?php echo $this->getViewUrl($_order->getRelationParentId()) ?>">
-                    <?php echo $_order->getRelationParentRealId() ?>
+                    <?php echo $this->escapeHtml($_order->getRelationParentRealId()) ?>
                 </a></td>
             </tr>
             <?php endif; ?>
@@ -154,7 +154,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
             <div class="tools"><?php echo $this->getAddressEditLink($_order->getBillingAddress())?></div>
         </div>
         <fieldset>
-            <address><?php echo $_order->getBillingAddress()->getFormated(true) ?></address>
+            <address><?php echo $this->maliciousCodeFilter($_order->getBillingAddress()->getFormated(true)) ?></address>
         </fieldset>
     </div>
 </div>
@@ -167,7 +167,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
             <div class="tools"><?php echo $this->getAddressEditLink($_order->getShippingAddress())?></div>
         </div>
         <fieldset>
-            <address><?php echo $_order->getShippingAddress()->getFormated(true) ?></address>
+            <address><?php echo $this->maliciousCodeFilter($_order->getShippingAddress()->getFormated(true)) ?></address>
         </fieldset>
     </div>
 </div>
diff --git app/design/adminhtml/default/default/template/system/currency/rate/matrix.phtml app/design/adminhtml/default/default/template/system/currency/rate/matrix.phtml
index 4262fd7dd2c..8fd4b50dabd 100644
--- app/design/adminhtml/default/default/template/system/currency/rate/matrix.phtml
+++ app/design/adminhtml/default/default/template/system/currency/rate/matrix.phtml
@@ -38,7 +38,7 @@ $_rates = ( $_newRates ) ? $_newRates : $_oldRates;
             <tr class="headings">
                 <th class="a-right">&nbsp;</th>
                 <?php $_i = 0; foreach( $this->getAllowedCurrencies() as $_currencyCode ): ?>
-                    <th class="<?php echo (( ++$_i == (sizeof($this->getAllowedCurrencies())) ) ? 'last' : '' ) ?> a-right"><strong><?php echo $_currencyCode ?><strong></th>
+                    <th class="<?php echo (( ++$_i == (sizeof($this->getAllowedCurrencies())) ) ? 'last' : '' ) ?> a-right"><strong><?php echo $this->escapeHtml($_currencyCode) ?><strong></th>
                 <?php endforeach; ?>
             </tr>
         </thead>
@@ -47,16 +47,16 @@ $_rates = ( $_newRates ) ? $_newRates : $_oldRates;
             <?php if( isset($_rates[$_currencyCode]) && is_array($_rates[$_currencyCode])): ?>
                 <?php foreach( $_rates[$_currencyCode] as $_rate => $_value ): ?>
                     <?php if( ++$_j == 1 ): ?>
-                        <td class="a-right"><strong><?php echo $_currencyCode ?></strong></td>
+                        <td class="a-right"><strong><?php echo $this->escapeHtml($_currencyCode) ?></strong></td>
                         <td class="a-right">
-                            <input type="text" name="rate[<?php echo $_currencyCode ?>][<?php echo $_rate ?>]" value="<?php echo ( $_currencyCode == $_rate ) ? '1.0000' : ($_value>0 ? $_value : (isset($_oldRates[$_currencyCode][$_rate]) ? $_oldRates[$_currencyCode][$_rate] : '')) ?>" <?php echo ( $_currencyCode == $_rate ) ? 'class="input-text input-text-disabled" readonly="true"' : 'class="input-text"' ?> />
+                            <input type="text" name="rate[<?php echo $this->escapeHtml($_currencyCode) ?>][<?php echo $this->escapeHtml($_rate) ?>]" value="<?php echo ( $_currencyCode == $_rate ) ? '1.0000' : ($_value>0 ? $_value : (isset($_oldRates[$_currencyCode][$_rate]) ? $_oldRates[$_currencyCode][$_rate] : '')) ?>" <?php echo ( $_currencyCode == $_rate ) ? 'class="input-text input-text-disabled" readonly="true"' : 'class="input-text"' ?> />
                             <?php if( isset($_newRates) && $_currencyCode != $_rate && isset($_oldRates[$_currencyCode][$_rate]) ): ?>
                             <br /><span class="old-rate"><?php echo $this->__('Old rate:') ?> <?php echo $_oldRates[$_currencyCode][$_rate] ?></span>
                             <?php endif; ?>
                         </td>
                     <?php else: ?>
                         <td class="a-right">
-                            <input type="text" name="rate[<?php echo $_currencyCode ?>][<?php echo $_rate ?>]" value="<?php echo ( $_currencyCode == $_rate ) ? '1.0000' : ($_value>0 ? $_value : (isset($_oldRates[$_currencyCode][$_rate]) ? $_oldRates[$_currencyCode][$_rate] : '')) ?>" <?php echo ( $_currencyCode == $_rate ) ? 'class="input-text input-text-disabled" readonly="true"' : 'class="input-text"' ?> />
+                            <input type="text" name="rate[<?php echo $this->escapeHtml($_currencyCode) ?>][<?php echo $this->escapeHtml($_rate) ?>]" value="<?php echo ( $_currencyCode == $_rate ) ? '1.0000' : ($_value>0 ? $_value : (isset($_oldRates[$_currencyCode][$_rate]) ? $_oldRates[$_currencyCode][$_rate] : '')) ?>" <?php echo ( $_currencyCode == $_rate ) ? 'class="input-text input-text-disabled" readonly="true"' : 'class="input-text"' ?> />
                             <?php if( isset($_newRates)  && $_currencyCode != $_rate && isset($_oldRates[$_currencyCode][$_rate]) ): ?>
                             <br /><span class="old-rate"><?php echo $this->__('Old rate:') ?> <?php echo $_oldRates[$_currencyCode][$_rate] ?></span>
                             <?php endif; ?>
diff --git app/design/frontend/enterprise/default/template/giftcardaccount/cart/total.phtml app/design/frontend/enterprise/default/template/giftcardaccount/cart/total.phtml
index c3e398ae150..73f754a9407 100644
--- app/design/frontend/enterprise/default/template/giftcardaccount/cart/total.phtml
+++ app/design/frontend/enterprise/default/template/giftcardaccount/cart/total.phtml
@@ -36,9 +36,15 @@ if (!$_cards) {
         <th colspan="<?php echo $this->getColspan(); ?>" style="<?php echo $this->getTotal()->getStyle() ?>" class="a-right">
             <?php if ($this->getRenderingArea() == $this->getTotal()->getArea()): ?><strong><?php endif; ?>
                 <?php $_title = $this->__('Remove'); ?>
-                <?php $_url = Mage::getUrl('enterprise_giftcardaccount/cart/remove', array('code'=>$_c['c'])); ?>
-                <a href="<?php echo $_url; ?>" title="<?php echo $_title; ?>" class="btn-remove"><img src="<?php echo $this->getSkinUrl('images/btn_remove.gif') ?>" alt="<?php echo $this->__('Remove')?>" /></a>
-
+                <a title="<?php echo Mage::helper('core')->quoteEscape($_title); ?>"
+                   href="#"
+                   class="btn-remove"
+                   onclick="customFormSubmit(
+                           '<?php echo (Mage::getUrl('enterprise_giftcardaccount/cart/remove')); ?>',
+                           '<?php echo ($this->escapeHtml(json_encode(array('code' => $_c['c'])))); ?>',
+                           'post')">
+                    <img src="<?php echo $this->getSkinUrl('images/btn_remove.gif') ?>" alt="<?php echo $this->__('Remove')?>" />
+                </a>
                 <?php echo $this->__('Gift Card (%s)', $_c['c']); ?>
             <?php if ($this->getRenderingArea() == $this->getTotal()->getArea()): ?></strong><?php endif; ?>
         </th>
diff --git app/design/frontend/enterprise/default/template/rma/return/create.phtml app/design/frontend/enterprise/default/template/rma/return/create.phtml
index 775d296e31e..8091907a307 100644
--- app/design/frontend/enterprise/default/template/rma/return/create.phtml
+++ app/design/frontend/enterprise/default/template/rma/return/create.phtml
@@ -338,7 +338,17 @@
             <div class="field">
                 <label for="rma_comment"><?php echo $this->__('Comments') ?></label>
                 <div class="input-box">
-                    <textarea id="rma_comment" style="height:6em;" cols="5" rows="3" name="rma_comment" class="input-text"><?php if ($_data): ?><?php echo $_data->getRmaComment(); ?><?php endif; ?></textarea>
+                    <textarea
+                              id="rma_comment"
+                              style="height:6em;"
+                              cols="5"
+                              rows="3"
+                              name="rma_comment"
+                              class="input-text">
+                        <?php if ($_data): ?>
+                            <?php echo Mage::helper('core')->escapeHtml($_data->getRmaComment()); ?>
+                        <?php endif; ?>
+                    </textarea>
                 </div>
             </div>
         </li>
diff --git app/locale/en_US/Mage_Adminhtml.csv app/locale/en_US/Mage_Adminhtml.csv
index 958318648f8..500fa72cf1b 100644
--- app/locale/en_US/Mage_Adminhtml.csv
+++ app/locale/en_US/Mage_Adminhtml.csv
@@ -42,7 +42,7 @@
 "<h1 class=""page-heading"">404 Error</h1><p>Page not found.</p>","<h1 class=""page-heading"">404 Error</h1><p>Page not found.</p>"
 "<strong>%s</strong> requests access to your account","<strong>%s</strong> requests access to your account"
 "<strong>Attention</strong>: Captcha is case sensitive.","<strong>Attention</strong>: Captcha is case sensitive."
-"A user with the same user name or email aleady exists.","A user with the same user name or email aleady exists."
+"A user with the same user name or email already exists.","A user with the same user name or email already exists."
 "API Key","API Key"
 "API Key Confirmation","API Key Confirmation"
 "ASCII","ASCII"
@@ -245,6 +245,7 @@
 "Credit memo\'s total must be positive.","Credit memo\'s total must be positive."
 "Currency","Currency"
 "Currency ""%s"" is used as %s in %s.","Currency ""%s"" is used as %s in %s."
+"Currency doesn\'t exist.","Currency doesn\'t exist."
 "Currency Information","Currency Information"
 "Currency Setup Section","Currency Setup Section"
 "Current Configuration Scope:","Current Configuration Scope:"
@@ -856,6 +857,7 @@
 "Self-assigned roles cannot be deleted.","Self-assigned roles cannot be deleted."
 "Sender","Sender"
 "Separate Email","Separate Email"
+"Serialized data is incorrect","Serialized data is incorrect"
 "Shipment #%s comment added","Shipment #%s comment added"
 "Shipment #%s created","Shipment #%s created"
 "Shipment Comments","Shipment Comments"
@@ -963,6 +965,7 @@
 "The email address is empty.","The email address is empty."
 "The email template has been deleted.","The email template has been deleted."
 "The email template has been saved.","The email template has been saved."
+"Invalid template data.","Invalid template data."
 "The flat catalog category has been rebuilt.","The flat catalog category has been rebuilt."
 "The group node name must be specified with field node name.","The group node name must be specified with field node name."
 "The image cache was cleaned.","The image cache was cleaned."
diff --git app/locale/en_US/Mage_Core.csv app/locale/en_US/Mage_Core.csv
index b3515b826d2..f32be45f342 100644
--- app/locale/en_US/Mage_Core.csv
+++ app/locale/en_US/Mage_Core.csv
@@ -52,6 +52,7 @@
 "Can\'t retrieve entity config: %s","Can\'t retrieve entity config: %s"
 "Cancel","Cancel"
 "Cannot complete this operation from non-admin area.","Cannot complete this operation from non-admin area."
+"Disallowed template variable method.","Disallowed template variable method."
 "Card type does not match credit card number.","Card type does not match credit card number."
 "Code","Code"
 "Controller file was loaded but class does not exist","Controller file was loaded but class does not exist"
diff --git app/locale/en_US/Mage_Sales.csv app/locale/en_US/Mage_Sales.csv
index 7f3a80e75e6..e46f2f291e2 100644
--- app/locale/en_US/Mage_Sales.csv
+++ app/locale/en_US/Mage_Sales.csv
@@ -285,6 +285,7 @@
 "Invalid draw line data. Please define ""lines"" array.","Invalid draw line data. Please define ""lines"" array."
 "Invalid entity model","Invalid entity model"
 "Invalid item option format.","Invalid item option format."
+"Invalid order data.","Invalid order data."
 "Invalid qty to invoice item ""%s""","Invalid qty to invoice item ""%s"""
 "Invalid qty to refund item ""%s""","Invalid qty to refund item ""%s"""
 "Invalid qty to ship for item ""%s""","Invalid qty to ship for item ""%s"""
diff --git app/locale/en_US/Mage_Sitemap.csv app/locale/en_US/Mage_Sitemap.csv
index 8ae5a947caf..df201861844 100644
--- app/locale/en_US/Mage_Sitemap.csv
+++ app/locale/en_US/Mage_Sitemap.csv
@@ -44,3 +44,4 @@
 "Valid values range: from 0.0 to 1.0.","Valid values range: from 0.0 to 1.0."
 "Weekly","Weekly"
 "Yearly","Yearly"
+"Please enter a sitemap name with at most %s characters.","Please enter a sitemap name with at most %s characters."
diff --git js/mage/adminhtml/wysiwyg/tiny_mce/setup.js js/mage/adminhtml/wysiwyg/tiny_mce/setup.js
index cbeca31dd7c..884b2ef45ad 100644
--- js/mage/adminhtml/wysiwyg/tiny_mce/setup.js
+++ js/mage/adminhtml/wysiwyg/tiny_mce/setup.js
@@ -109,6 +109,7 @@ tinyMceWysiwygSetup.prototype =
             theme_advanced_resizing : true,
             convert_urls : false,
             relative_urls : false,
+            media_disable_flash : this.config.media_disable_flash,
             content_css: this.config.content_css,
             custom_popup_css: this.config.popup_css,
             magentowidget_url: this.config.widget_window_url,
diff --git js/tiny_mce/plugins/media/js/media.js js/tiny_mce/plugins/media/js/media.js
index 45d88fe1b4b..0fbc53e88e3 100644
--- js/tiny_mce/plugins/media/js/media.js
+++ js/tiny_mce/plugins/media/js/media.js
@@ -434,7 +434,7 @@
 			html += '<select id="media_type" name="media_type" onchange="Media.formToData(\'type\');">';
 			html += option("video");
 			html += option("audio");
-			html += option("flash");
+			html += editor.getParam("media_disable_flash") ? '' : option("flash");
 			html += option("quicktime");
 			html += option("shockwave");
 			html += option("windowsmedia");
diff --git js/varien/js.js js/varien/js.js
index 262572b6c35..e369560ab8d 100644
--- js/varien/js.js
+++ js/varien/js.js
@@ -702,3 +702,40 @@ if ((typeof Range != "undefined") && !Range.prototype.createContextualFragment)
         return frag;
     };
 }
+
+/**
+ * Create form element. Set parameters into it and send
+ *
+ * @param url
+ * @param parametersArray
+ * @param method
+ */
+Varien.formCreator = Class.create();
+Varien.formCreator.prototype = {
+    initialize : function(url, parametersArray, method) {
+        this.url = url;
+        this.parametersArray = JSON.parse(parametersArray);
+        this.method = method;
+        this.form = '';
+
+        this.createForm();
+        this.setFormData();
+    },
+    createForm : function() {
+        this.form = new Element('form', { 'method': this.method, action: this.url });
+    },
+    setFormData : function () {
+        for (var key in this.parametersArray) {
+            Element.insert(
+                this.form,
+                new Element('input', { name: key, value: this.parametersArray[key], type: 'hidden' })
+            );
+        }
+    }
+};
+
+function customFormSubmit(url, parametersArray, method) {
+    var createdForm = new Varien.formCreator(url, parametersArray, method);
+    Element.insert($$('body')[0], createdForm.form);
+    createdForm.form.submit();
+}
diff --git lib/phpseclib/PHP/Compat/Function/array_fill.php lib/phpseclib/PHP/Compat/Function/array_fill.php
index 79b5312aa2d..7eb231a0962 100644
--- lib/phpseclib/PHP/Compat/Function/array_fill.php
+++ lib/phpseclib/PHP/Compat/Function/array_fill.php
@@ -14,6 +14,7 @@
  * @version     $Revision: 1.1 $
  * @since       PHP 4.2.0
  */
+/*
 function php_compat_array_fill($start_index, $num, $value)
 {
     if ($num <= 0) {
@@ -39,3 +40,4 @@ if (!function_exists('array_fill')) {
         return php_compat_array_fill($start_index, $num, $value);
     }
 }
+*/
diff --git lib/phpseclib/PHP/Compat/Function/bcpowmod.php lib/phpseclib/PHP/Compat/Function/bcpowmod.php
index 4c162b87ef6..0366fef84d4 100644
--- lib/phpseclib/PHP/Compat/Function/bcpowmod.php
+++ lib/phpseclib/PHP/Compat/Function/bcpowmod.php
@@ -15,6 +15,7 @@
  * @since       PHP 5.0.0
  * @require     PHP 4.0.0 (user_error)
  */
+/*
 function php_compat_bcpowmod($x, $y, $modulus, $scale = 0)
 {
     // Sanity check
@@ -64,3 +65,4 @@ if (!function_exists('bcpowmod')) {
         return php_compat_bcpowmod($x, $y, $modulus, $scale);
     }
 }
+*/
diff --git lib/phpseclib/PHP/Compat/Function/str_split.php lib/phpseclib/PHP/Compat/Function/str_split.php
index 8f5179bc988..607e5ca32c4 100644
--- lib/phpseclib/PHP/Compat/Function/str_split.php
+++ lib/phpseclib/PHP/Compat/Function/str_split.php
@@ -12,6 +12,7 @@
  * @since       PHP 5
  * @require     PHP 4.0.0 (user_error)
  */
+/*
 function php_compat_str_split($string, $split_length = 1)
 {
     if (!is_scalar($split_length)) {
@@ -57,3 +58,4 @@ if (!function_exists('str_split')) {
         return php_compat_str_split($string, $split_length);
     }
 }
+*/
