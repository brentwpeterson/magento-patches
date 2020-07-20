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


SUPEE-11155_CE_1501 | CE_1.5.0.1 | v1 | 8392cefa8df0ce1eadc9514c0a8aa5bfaba29d68 | Mon Jul 29 22:14:07 2019 +0000 | 758ec650b2b55c08916234655e5f4daf52bc2bd3..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/Mage.php app/Mage.php
index e0e4690213f..4b6108d9615 100644
--- app/Mage.php
+++ app/Mage.php
@@ -722,9 +722,9 @@ final class Mage
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
 
diff --git app/code/core/Mage/Admin/Model/Block.php app/code/core/Mage/Admin/Model/Block.php
index c581dbfdc70..f4b13c8f144 100644
--- app/code/core/Mage/Admin/Model/Block.php
+++ app/code/core/Mage/Admin/Model/Block.php
@@ -64,7 +64,7 @@ class Mage_Admin_Model_Block extends Mage_Core_Model_Abstract
         if (in_array($this->getBlockName(), $disallowedBlockNames)) {
             $errors[] = Mage::helper('adminhtml')->__('Block Name is disallowed.');
         }
-        if (!Zend_Validate::is($this->getBlockName(), 'Regex', array('/^[-_a-zA-Z0-9\/]*$/'))) {
+        if (!Zend_Validate::is($this->getBlockName(), 'Regex', array('/^[-_a-zA-Z0-9]+\/[-_a-zA-Z0-9\/]+$/'))) {
             $errors[] = Mage::helper('admin')->__('Block Name is incorrect.');
         }
 
diff --git app/code/core/Mage/Admin/Model/User.php app/code/core/Mage/Admin/Model/User.php
index b1b7c32f2af..85e4d91cd5d 100644
--- app/code/core/Mage/Admin/Model/User.php
+++ app/code/core/Mage/Admin/Model/User.php
@@ -438,7 +438,7 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
         }
 
         if ($this->userExists()) {
-            $errors[] = Mage::helper('adminhtml')->__('A user with the same user name or email aleady exists.');
+            $errors[] = Mage::helper('adminhtml')->__('A user with the same user name or email already exists.');
         }
 
         if (count($errors) === 0) {
diff --git app/code/core/Mage/AdminNotification/etc/system.xml app/code/core/Mage/AdminNotification/etc/system.xml
index 0d63ce4e509..deb8e3cfdfc 100644
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
index 0cdc3aa6863..88e5c1a6c24 100644
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
index 8195f51db7f..2ff9feaf3de 100644
--- app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php
+++ app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php
@@ -125,6 +125,23 @@ class Mage_Adminhtml_Block_Catalog_Product_Edit_Tab_Super_Config extends Mage_Ad
             ->getConfigurableAttributesAsArray($this->_getProduct());
         if(!$attributes) {
             return '[]';
+        } else {
+            // Hide price if needed
+            foreach ($attributes as &$attribute) {
+                $attribute['label'] = $this->escapeHtml($attribute['label']);
+                $attribute['frontend_label'] = $this->escapeHtml($attribute['frontend_label']);
+                $attribute['store_label'] = $this->escapeHtml($attribute['store_label']);
+                if (isset($attribute['values']) && is_array($attribute['values'])) {
+                    foreach ($attribute['values'] as &$attributeValue) {
+                        if (!$this->getCanReadPrice()) {
+                            $attributeValue['pricing_value'] = '';
+                            $attributeValue['is_percent'] = 0;
+                        }
+                        $attributeValue['can_edit_price'] = $this->getCanEditPrice();
+                        $attributeValue['can_read_price'] = $this->getCanReadPrice();
+                    }
+                }
+            }
         }
         return Mage::helper('core')->jsonEncode($attributes);
     }
diff --git app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php
index 94d74baec93..eee0ac7360b 100644
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
index f58ddf2cd92..55031b2b53e 100644
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
index e763e883c7e..7cde96f43d9 100644
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
index 1ff183fbf86..e4992d1d265 100644
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
index 3995f672832..b4ad0a322ec 100644
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
index dd700ff6dbd..b4a3cf8f4cb 100644
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
index 5fe056d2609..2515de8c1ad 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/Creditmemo/Create.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/Creditmemo/Create.php
@@ -67,20 +67,17 @@ class Mage_Adminhtml_Block_Sales_Order_Creditmemo_Create extends Mage_Adminhtml_
     public function getHeaderText()
     {
         if ($this->getCreditmemo()->getInvoice()) {
-            $header = Mage::helper('sales')->__('New Credit Memo for Invoice #%s',
-                $this->getCreditmemo()->getInvoice()->getIncrementId()
+            $header = Mage::helper('sales')->__(
+                'New Credit Memo for Invoice #%s',
+                $this->escapeHtml($this->getCreditmemo()->getInvoice()->getIncrementId())
             );
-        }
-        else {
-            $header = Mage::helper('sales')->__('New Credit Memo for Order #%s',
-                $this->getCreditmemo()->getOrder()->getRealOrderId()
+        } else {
+            $header = Mage::helper('sales')->__(
+                'New Credit Memo for Order #%s',
+                $this->escapeHtml($this->getCreditmemo()->getOrder()->getRealOrderId())
             );
         }
-        /*$header = Mage::helper('sales')->__('New Credit Memo for Order #%s | Order Date: %s | Customer Name: %s',
-            $this->getCreditmemo()->getOrder()->getRealOrderId(),
-            $this->formatDate($this->getCreditmemo()->getOrder()->getCreatedAt(), 'medium', true),
-            $this->getCreditmemo()->getOrder()->getCustomerName()
-        );*/
+
         return $header;
     }
 
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php
index bcdcea662dc..e623ef3c6c1 100644
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
index 32b85a37744..2c31e263b57 100644
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
index b57e65d0dd7..8256245b6f4 100644
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
index 51e10a53b02..5ee8f9da4af 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php
@@ -287,6 +287,16 @@ class Mage_Adminhtml_Block_Sales_Order_View extends Mage_Adminhtml_Block_Widget_
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
index 524eb724dc9..06aa4686d0a 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Shipment/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Shipment/Grid.php
@@ -75,6 +75,7 @@ class Mage_Adminhtml_Block_Sales_Shipment_Grid extends Mage_Adminhtml_Block_Widg
             'header'    => Mage::helper('sales')->__('Order #'),
             'index'     => 'order_increment_id',
             'type'      => 'text',
+            'escape'    => true,
         ));
 
         $this->addColumn('order_created_at', array(
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Transactions/Grid.php app/code/core/Mage/Adminhtml/Block/Sales/Transactions/Grid.php
index 0408b200876..9a7a0a5cc2a 100644
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
index ae78b96e366..4671cea6293 100644
--- app/code/core/Mage/Adminhtml/Block/System/Email/Template/Preview.php
+++ app/code/core/Mage/Adminhtml/Block/System/Email/Template/Preview.php
@@ -45,10 +45,12 @@ class Mage_Adminhtml_Block_System_Email_Template_Preview extends Mage_Adminhtml_
             $template->setTemplateStyles($this->getRequest()->getParam('styles'));
         }
 
-        /* @var $filter Mage_Core_Model_Input_Filter_MaliciousCode */
-        $filter = Mage::getSingleton('core/input_filter_maliciousCode');
+        $template->setTemplateStyles(
+            $this->maliciousCodeFilter($template->getTemplateStyles())
+        );
+
         $template->setTemplateText(
-            $filter->filter($template->getTemplateText())
+            $this->maliciousCodeFilter($template->getTemplateText())
         );
 
         Varien_Profiler::start("email_template_proccessing");
diff --git app/code/core/Mage/Adminhtml/Block/Template.php app/code/core/Mage/Adminhtml/Block/Template.php
index 27a9e09af81..79852a1bd11 100644
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
index c5bfdc0c1fa..1ee7dd7ac95 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Abstract.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Abstract.php
@@ -110,11 +110,12 @@ abstract class Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Abstract extends
             if ($this->getColumn()->getDir()) {
                 $className = 'sort-arrow-' . $dir;
             }
-            $out = '<a href="#" name="'.$this->getColumn()->getId().'" title="'.$nDir
-                   .'" class="' . $className . '"><span class="sort-title">'.$this->getColumn()->getHeader().'</span></a>';
+            $out = '<a href="#" name="' . $this->getColumn()->getId() . '" title="' . $nDir
+                   . '" class="' . $className . '"><span class="sort-title">'
+                   . $this->escapeHtml($this->getColumn()->getHeader()) . '</span></a>';
         }
         else {
-            $out = $this->getColumn()->getHeader();
+            $out = $this->escapeHtml($this->getColumn()->getHeader());
         }
         return $out;
     }
diff --git app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
index 8f377b33c74..826eec42658 100644
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
index 5f3bb8d1a96..6c8e9bc2e82 100644
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
index 6bb22e5bcaf..63c995411d5 100644
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
index 2fae4abf3ec..18259b1ccfc 100644
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
diff --git app/code/core/Mage/Adminhtml/controllers/AjaxController.php.orig app/code/core/Mage/Adminhtml/controllers/AjaxController.php.orig
deleted file mode 100644
index 28314f8d1e8..00000000000
--- app/code/core/Mage/Adminhtml/controllers/AjaxController.php.orig
+++ /dev/null
@@ -1,47 +0,0 @@
-<?php
-/**
- * Magento
- *
- * NOTICE OF LICENSE
- *
- * This source file is subject to the Open Software License (OSL 3.0)
- * that is bundled with this package in the file LICENSE.txt.
- * It is also available through the world-wide-web at this URL:
- * http://opensource.org/licenses/osl-3.0.php
- * If you did not receive a copy of the license and are unable to
- * obtain it through the world-wide-web, please send an email
- * to license@magentocommerce.com so we can send you a copy immediately.
- *
- * DISCLAIMER
- *
- * Do not edit or add to this file if you wish to upgrade Magento to newer
- * versions in the future. If you wish to customize Magento for your
- * needs please refer to http://www.magentocommerce.com for more information.
- *
- * @category    Mage
- * @package     Mage_Adminhtml
- * @copyright   Copyright (c) 2010 Magento Inc. (http://www.magentocommerce.com)
- * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
- */
-
-/**
- * Backend ajax controller
- *
- * @category    Mage
- * @package     Mage_Adminhtml
- * @author      Magento Core Team <core@magentocommerce.com>
- */
-class Mage_Adminhtml_AjaxController extends Mage_Adminhtml_Controller_Action
-{
-    /**
-     * Ajax action for inline translation
-     *
-     */
-    public function translateAction ()
-    {
-        $translation = $this->getRequest()->getPost('translate');
-        $area = $this->getRequest()->getPost('area');
-        echo Mage::helper('core/translate')->apply($translation, $area);
-        exit();
-    }
-}
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/Product/ReviewController.php app/code/core/Mage/Adminhtml/controllers/Catalog/Product/ReviewController.php
index daad4757944..8e64cdc547e 100644
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
index 741a041d53d..948e336e704 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
@@ -533,7 +533,7 @@ class Mage_Adminhtml_Catalog_ProductController extends Mage_Adminhtml_Controller
         catch (Mage_Eav_Model_Entity_Attribute_Exception $e) {
             $response->setError(true);
             $response->setAttribute($e->getAttributeCode());
-            $response->setMessage($e->getMessage());
+            $response->setMessage(Mage::helper('core')->escapeHtml($e->getMessage()));
         }
         catch (Mage_Core_Exception $e) {
             $response->setError(true);
diff --git app/code/core/Mage/Adminhtml/controllers/Checkout/AgreementController.php app/code/core/Mage/Adminhtml/controllers/Checkout/AgreementController.php
index 3b2a442ba74..5a2c8f18985 100644
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
diff --git app/code/core/Mage/Adminhtml/controllers/Cms/PageController.php.orig app/code/core/Mage/Adminhtml/controllers/Cms/PageController.php.orig
deleted file mode 100644
index 2481a262b94..00000000000
--- app/code/core/Mage/Adminhtml/controllers/Cms/PageController.php.orig
+++ /dev/null
@@ -1,236 +0,0 @@
-<?php
-/**
- * Magento
- *
- * NOTICE OF LICENSE
- *
- * This source file is subject to the Open Software License (OSL 3.0)
- * that is bundled with this package in the file LICENSE.txt.
- * It is also available through the world-wide-web at this URL:
- * http://opensource.org/licenses/osl-3.0.php
- * If you did not receive a copy of the license and are unable to
- * obtain it through the world-wide-web, please send an email
- * to license@magentocommerce.com so we can send you a copy immediately.
- *
- * DISCLAIMER
- *
- * Do not edit or add to this file if you wish to upgrade Magento to newer
- * versions in the future. If you wish to customize Magento for your
- * needs please refer to http://www.magentocommerce.com for more information.
- *
- * @category    Mage
- * @package     Mage_Adminhtml
- * @copyright   Copyright (c) 2010 Magento Inc. (http://www.magentocommerce.com)
- * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
- */
-
-
-/**
- * Cms manage pages controller
- *
- * @category   Mage
- * @package    Mage_Cms
- * @author      Magento Core Team <core@magentocommerce.com>
- */
-class Mage_Adminhtml_Cms_PageController extends Mage_Adminhtml_Controller_Action
-{
-
-    /**
-     * Init actions
-     *
-     * @return Mage_Adminhtml_Cms_PageController
-     */
-    protected function _initAction()
-    {
-        // load layout, set active menu and breadcrumbs
-        $this->loadLayout()
-            ->_setActiveMenu('cms/page')
-            ->_addBreadcrumb(Mage::helper('cms')->__('CMS'), Mage::helper('cms')->__('CMS'))
-            ->_addBreadcrumb(Mage::helper('cms')->__('Manage Pages'), Mage::helper('cms')->__('Manage Pages'))
-        ;
-        return $this;
-    }
-
-    /**
-     * Index action
-     */
-    public function indexAction()
-    {
-        $this->_title($this->__('CMS'))
-             ->_title($this->__('Pages'))
-             ->_title($this->__('Manage Content'));
-
-        $this->_initAction();
-        $this->renderLayout();
-    }
-
-    /**
-     * Create new CMS page
-     */
-    public function newAction()
-    {
-        // the same form is used to create and edit
-        $this->_forward('edit');
-    }
-
-    /**
-     * Edit CMS page
-     */
-    public function editAction()
-    {
-        $this->_title($this->__('CMS'))
-             ->_title($this->__('Pages'))
-             ->_title($this->__('Manage Content'));
-
-        // 1. Get ID and create model
-        $id = $this->getRequest()->getParam('page_id');
-        $model = Mage::getModel('cms/page');
-
-        // 2. Initial checking
-        if ($id) {
-            $model->load($id);
-            if (! $model->getId()) {
-                Mage::getSingleton('adminhtml/session')->addError(Mage::helper('cms')->__('This page no longer exists.'));
-                $this->_redirect('*/*/');
-                return;
-            }
-        }
-
-        $this->_title($model->getId() ? $model->getTitle() : $this->__('New Page'));
-
-        // 3. Set entered data if was error when we do save
-        $data = Mage::getSingleton('adminhtml/session')->getFormData(true);
-        if (! empty($data)) {
-            $model->setData($data);
-        }
-
-        // 4. Register model to use later in blocks
-        Mage::register('cms_page', $model);
-
-        // 5. Build edit form
-        $this->_initAction()
-            ->_addBreadcrumb($id ? Mage::helper('cms')->__('Edit Page') : Mage::helper('cms')->__('New Page'), $id ? Mage::helper('cms')->__('Edit Page') : Mage::helper('cms')->__('New Page'));
-
-        $this->renderLayout();
-    }
-
-    /**
-     * Save action
-     */
-    public function saveAction()
-    {
-        // check if data sent
-        if ($data = $this->getRequest()->getPost()) {
-            $data = $this->_filterPostData($data);
-            //init model and set data
-            $model = Mage::getModel('cms/page');
-
-            if ($id = $this->getRequest()->getParam('page_id')) {
-                $model->load($id);
-            }
-
-            $model->setData($data);
-
-            Mage::dispatchEvent('cms_page_prepare_save', array('page' => $model, 'request' => $this->getRequest()));
-
-            // try to save it
-            try {
-                // save the data
-                $model->save();
-
-                // display success message
-                Mage::getSingleton('adminhtml/session')->addSuccess(Mage::helper('cms')->__('The page has been saved.'));
-                // clear previously saved data from session
-                Mage::getSingleton('adminhtml/session')->setFormData(false);
-                // check if 'Save and Continue'
-                if ($this->getRequest()->getParam('back')) {
-                    $this->_redirect('*/*/edit', array('page_id' => $model->getId(), '_current'=>true));
-                    return;
-                }
-                // go to grid
-                $this->_redirect('*/*/');
-                return;
-
-            } catch (Mage_Core_Exception $e) {
-                $this->_getSession()->addError($e->getMessage());
-            }
-            catch (Exception $e) {
-                $this->_getSession()->addException($e, Mage::helper('cms')->__('An error occurred while saving the page.'));
-            }
-
-            $this->_getSession()->setFormData($data);
-            $this->_redirect('*/*/edit', array('page_id' => $this->getRequest()->getParam('page_id')));
-            return;
-        }
-        $this->_redirect('*/*/');
-    }
-
-    /**
-     * Delete action
-     */
-    public function deleteAction()
-    {
-        // check if we know what should be deleted
-        if ($id = $this->getRequest()->getParam('page_id')) {
-            $title = "";
-            try {
-                // init model and delete
-                $model = Mage::getModel('cms/page');
-                $model->load($id);
-                $title = $model->getTitle();
-                $model->delete();
-                // display success message
-                Mage::getSingleton('adminhtml/session')->addSuccess(Mage::helper('cms')->__('The page has been deleted.'));
-                // go to grid
-                Mage::dispatchEvent('adminhtml_cmspage_on_delete', array('title' => $title, 'status' => 'success'));
-                $this->_redirect('*/*/');
-                return;
-
-            } catch (Exception $e) {
-                Mage::dispatchEvent('adminhtml_cmspage_on_delete', array('title' => $title, 'status' => 'fail'));
-                // display error message
-                Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
-                // go back to edit form
-                $this->_redirect('*/*/edit', array('page_id' => $id));
-                return;
-            }
-        }
-        // display error message
-        Mage::getSingleton('adminhtml/session')->addError(Mage::helper('cms')->__('Unable to find a page to delete.'));
-        // go to grid
-        $this->_redirect('*/*/');
-    }
-
-    /**
-     * Check the permission to run it
-     *
-     * @return boolean
-     */
-    protected function _isAllowed()
-    {
-        switch ($this->getRequest()->getActionName()) {
-            case 'new':
-            case 'save':
-                return Mage::getSingleton('admin/session')->isAllowed('cms/page/save');
-                break;
-            case 'delete':
-                return Mage::getSingleton('admin/session')->isAllowed('cms/page/delete');
-                break;
-            default:
-                return Mage::getSingleton('admin/session')->isAllowed('cms/page');
-                break;
-        }
-    }
-
-    /**
-     * Filtering posted data. Converting localized data if needed
-     *
-     * @param array
-     * @return array
-     */
-    protected function _filterPostData($data)
-    {
-        $data = $this->_filterDates($data, array('custom_theme_from', 'custom_theme_to'));
-        return $data;
-    }
-}
diff --git app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
index 40abed6ba26..e6a86f92250 100644
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
index 1b5acf7970d..8e366ca2da0 100644
--- app/code/core/Mage/Adminhtml/controllers/Promo/CatalogController.php
+++ app/code/core/Mage/Adminhtml/controllers/Promo/CatalogController.php
@@ -107,6 +107,9 @@ class Mage_Adminhtml_Promo_CatalogController extends Mage_Adminhtml_Controller_A
                 $model = Mage::getModel('catalogrule/rule');
                 Mage::dispatchEvent('adminhtml_controller_catalogrule_prepare_save', array('request' => $this->getRequest()));
                 $data = $this->getRequest()->getPost();
+                if (Mage::helper('adminhtml')->hasTags($data['rule'], array('attribute'), false)) {
+                    Mage::throwException(Mage::helper('catalogrule')->__('Wrong rule specified'));
+                }
                 $data = $this->_filterDates($data, array('from_date', 'to_date'));
                 if ($id = $this->getRequest()->getParam('rule_id')) {
                     $model->load($id);
diff --git app/code/core/Mage/Adminhtml/controllers/Promo/QuoteController.php app/code/core/Mage/Adminhtml/controllers/Promo/QuoteController.php
index ac3945161c3..bd2fb90139e 100644
--- app/code/core/Mage/Adminhtml/controllers/Promo/QuoteController.php
+++ app/code/core/Mage/Adminhtml/controllers/Promo/QuoteController.php
@@ -120,7 +120,9 @@ class Mage_Adminhtml_Promo_QuoteController extends Mage_Adminhtml_Controller_Act
                 $model = Mage::getModel('salesrule/rule');
                 Mage::dispatchEvent('adminhtml_controller_salesrule_prepare_save', array('request' => $this->getRequest()));
                 $data = $this->getRequest()->getPost();
-
+                if (Mage::helper('adminhtml')->hasTags($data['rule'], array('attribute'), false)) {
+                    Mage::throwException(Mage::helper('catalogrule')->__('Wrong rule specified'));
+                }
                 $data = $this->_filterDates($data, array('from_date', 'to_date'));
                 $id = $this->getRequest()->getParam('rule_id');
                 if ($id) {
diff --git app/code/core/Mage/Adminhtml/controllers/Report/SalesController.php.orig app/code/core/Mage/Adminhtml/controllers/Report/SalesController.php.orig
deleted file mode 100644
index 2a0e432f868..00000000000
--- app/code/core/Mage/Adminhtml/controllers/Report/SalesController.php.orig
+++ /dev/null
@@ -1,486 +0,0 @@
-<?php
-/**
- * Magento
- *
- * NOTICE OF LICENSE
- *
- * This source file is subject to the Open Software License (OSL 3.0)
- * that is bundled with this package in the file LICENSE.txt.
- * It is also available through the world-wide-web at this URL:
- * http://opensource.org/licenses/osl-3.0.php
- * If you did not receive a copy of the license and are unable to
- * obtain it through the world-wide-web, please send an email
- * to license@magentocommerce.com so we can send you a copy immediately.
- *
- * DISCLAIMER
- *
- * Do not edit or add to this file if you wish to upgrade Magento to newer
- * versions in the future. If you wish to customize Magento for your
- * needs please refer to http://www.magentocommerce.com for more information.
- *
- * @category    Mage
- * @package     Mage_Adminhtml
- * @copyright   Copyright (c) 2010 Magento Inc. (http://www.magentocommerce.com)
- * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
- */
-
-/**
- * Sales report admin controller
- *
- * @category   Mage
- * @package    Mage_Adminhtml
- * @author      Magento Core Team <core@magentocommerce.com>
- */
-class Mage_Adminhtml_Report_SalesController extends Mage_Adminhtml_Controller_Action
-{
-    /**
-     * Admin session model
-     *
-     * @var null|Mage_Admin_Model_Session
-     */
-    protected $_adminSession = null;
-
-    public function _initAction()
-    {
-        $act = $this->getRequest()->getActionName();
-        if(!$act) {
-            $act = 'default';
-        }
-
-        $this->loadLayout()
-            ->_addBreadcrumb(Mage::helper('reports')->__('Reports'), Mage::helper('reports')->__('Reports'))
-            ->_addBreadcrumb(Mage::helper('reports')->__('Sales'), Mage::helper('reports')->__('Sales'));
-        return $this;
-    }
-
-    public function _initReportAction($blocks)
-    {
-        if (!is_array($blocks)) {
-            $blocks = array($blocks);
-        }
-
-        $requestData = Mage::helper('adminhtml')->prepareFilterString($this->getRequest()->getParam('filter'));
-        $requestData = $this->_filterDates($requestData, array('from', 'to'));
-        $requestData['store_ids'] = $this->getRequest()->getParam('store_ids');
-        $params = new Varien_Object();
-
-        foreach ($requestData as $key => $value) {
-            if (!empty($value)) {
-                $params->setData($key, $value);
-            }
-        }
-
-        foreach ($blocks as $block) {
-            if ($block) {
-                $block->setPeriodType($params->getData('period_type'));
-                $block->setFilterData($params);
-            }
-        }
-
-        return $this;
-    }
-
-    public function salesAction()
-    {
-        $this->_title($this->__('Reports'))->_title($this->__('Sales'))->_title($this->__('Sales'));
-
-        $this->_showLastExecutionTime(Mage_Reports_Model_Flag::REPORT_ORDER_FLAG_CODE, 'sales');
-
-        $this->_initAction()
-            ->_setActiveMenu('report/sales/sales')
-            ->_addBreadcrumb(Mage::helper('adminhtml')->__('Sales Report'), Mage::helper('adminhtml')->__('Sales Report'));
-
-        $gridBlock = $this->getLayout()->getBlock('report_sales_sales.grid');
-        $filterFormBlock = $this->getLayout()->getBlock('grid.filter.form');
-
-        $this->_initReportAction(array(
-            $gridBlock,
-            $filterFormBlock
-        ));
-
-        $this->renderLayout();
-    }
-
-    public function bestsellersAction()
-    {
-        $this->_title($this->__('Reports'))->_title($this->__('Products'))->_title($this->__('Bestsellers'));
-
-        $this->_showLastExecutionTime(Mage_Reports_Model_Flag::REPORT_BESTSELLERS_FLAG_CODE, 'bestsellers');
-
-        $this->_initAction()
-            ->_setActiveMenu('report/sales/bestsellers')
-            ->_addBreadcrumb(Mage::helper('adminhtml')->__('Products Bestsellers Report'), Mage::helper('adminhtml')->__('Products Bestsellers Report'));
-
-        $gridBlock = $this->getLayout()->getBlock('report_sales_bestsellers.grid');
-        $filterFormBlock = $this->getLayout()->getBlock('grid.filter.form');
-
-        $this->_initReportAction(array(
-            $gridBlock,
-            $filterFormBlock
-        ));
-
-        $this->renderLayout();
-    }
-
-    /**
-     * Export bestsellers report grid to CSV format
-     */
-    public function exportBestsellersCsvAction()
-    {
-        $fileName   = 'bestsellers.csv';
-        $grid       = $this->getLayout()->createBlock('adminhtml/report_sales_bestsellers_grid');
-        $this->_initReportAction($grid);
-        $this->_prepareDownloadResponse($fileName, $grid->getCsvFile());
-    }
-
-    /**
-     * Export bestsellers report grid to Excel XML format
-     */
-    public function exportBestsellersExcelAction()
-    {
-        $fileName   = 'bestsellers.xml';
-        $grid       = $this->getLayout()->createBlock('adminhtml/report_sales_bestsellers_grid');
-        $this->_initReportAction($grid);
-        $this->_prepareDownloadResponse($fileName, $grid->getExcelFile($fileName));
-    }
-
-    /**
-     * Retrieve array of collection names by code specified in request
-     *
-     * @deprecated after 1.4.0.1
-     * @return array
-     */
-    protected function _getCollectionNames()
-    {
-        return array();
-    }
-
-    protected function _showLastExecutionTime($flagCode, $refreshCode)
-    {
-        $flag = Mage::getModel('reports/flag')->setReportFlagCode($flagCode)->loadSelf();
-        $updatedAt = ($flag->hasData())
-            ? Mage::app()->getLocale()->storeDate(
-                0, new Zend_Date($flag->getLastUpdate(), Varien_Date::DATETIME_INTERNAL_FORMAT), true
-            )
-            : 'undefined';
-
-        $refreshStatsLink = $this->getUrl('*/*/refreshstatistics');
-        $directRefreshLink = $this->getUrl('*/*/refreshRecent', array('code' => $refreshCode));
-
-        Mage::getSingleton('adminhtml/session')->addNotice(Mage::helper('adminhtml')->__('Last updated: %s. To refresh last day\'s <a href="%s">statistics</a>, click <a href="%s">here</a>.', $updatedAt, $refreshStatsLink, $directRefreshLink));
-        return $this;
-    }
-
-    /**
-     * Refresh statistics for last 25 hours
-     *
-     * @deprecated after 1.4.0.1
-     * @return Mage_Adminhtml_Report_SalesController
-     */
-    public function refreshRecentAction()
-    {
-        return $this->_forward('refreshRecent', 'report_statistics');
-    }
-
-    /**
-     * Refresh statistics for all period
-     *
-     * @deprecated after 1.4.0.1
-     * @return Mage_Adminhtml_Report_SalesController
-     */
-    public function refreshLifetimeAction()
-    {
-        return $this->_forward('refreshLifetime', 'report_statistics');
-    }
-
-    /**
-     * Export sales report grid to CSV format
-     */
-    public function exportSalesCsvAction()
-    {
-        $fileName   = 'sales.csv';
-        $grid       = $this->getLayout()->createBlock('adminhtml/report_sales_sales_grid');
-        $this->_initReportAction($grid);
-        $this->_prepareDownloadResponse($fileName, $grid->getCsvFile());
-    }
-
-    /**
-     * Export sales report grid to Excel XML format
-     */
-    public function exportSalesExcelAction()
-    {
-        $fileName   = 'sales.xml';
-        $grid       = $this->getLayout()->createBlock('adminhtml/report_sales_sales_grid');
-        $this->_initReportAction($grid);
-        $this->_prepareDownloadResponse($fileName, $grid->getExcelFile($fileName));
-    }
-
-    public function taxAction()
-    {
-        $this->_title($this->__('Reports'))->_title($this->__('Sales'))->_title($this->__('Tax'));
-
-        $this->_showLastExecutionTime(Mage_Reports_Model_Flag::REPORT_TAX_FLAG_CODE, 'tax');
-
-        $this->_initAction()
-            ->_setActiveMenu('report/sales/tax')
-            ->_addBreadcrumb(Mage::helper('adminhtml')->__('Tax'), Mage::helper('adminhtml')->__('Tax'));
-
-        $gridBlock = $this->getLayout()->getBlock('report_sales_tax.grid');
-        $filterFormBlock = $this->getLayout()->getBlock('grid.filter.form');
-
-        $this->_initReportAction(array(
-            $gridBlock,
-            $filterFormBlock
-        ));
-
-        $this->renderLayout();
-    }
-
-    /**
-     * Export tax report grid to CSV format
-     */
-    public function exportTaxCsvAction()
-    {
-        $fileName   = 'tax.csv';
-        $grid       = $this->getLayout()->createBlock('adminhtml/report_sales_tax_grid');
-        $this->_initReportAction($grid);
-        $this->_prepareDownloadResponse($fileName, $grid->getCsvFile());
-    }
-
-    /**
-     * Export tax report grid to Excel XML format
-     */
-    public function exportTaxExcelAction()
-    {
-        $fileName   = 'tax.xml';
-        $grid       = $this->getLayout()->createBlock('adminhtml/report_sales_tax_grid');
-        $this->_initReportAction($grid);
-        $this->_prepareDownloadResponse($fileName, $grid->getExcelFile($fileName));
-    }
-
-    public function shippingAction()
-    {
-        $this->_title($this->__('Reports'))->_title($this->__('Sales'))->_title($this->__('Shipping'));
-
-        $this->_showLastExecutionTime(Mage_Reports_Model_Flag::REPORT_SHIPPING_FLAG_CODE, 'shipping');
-
-        $this->_initAction()
-            ->_setActiveMenu('report/sales/shipping')
-            ->_addBreadcrumb(Mage::helper('adminhtml')->__('Shipping'), Mage::helper('adminhtml')->__('Shipping'));
-
-        $gridBlock = $this->getLayout()->getBlock('report_sales_shipping.grid');
-        $filterFormBlock = $this->getLayout()->getBlock('grid.filter.form');
-
-        $this->_initReportAction(array(
-            $gridBlock,
-            $filterFormBlock
-        ));
-
-        $this->renderLayout();
-    }
-
-    /**
-     * Export shipping report grid to CSV format
-     */
-    public function exportShippingCsvAction()
-    {
-        $fileName   = 'shipping.csv';
-        $grid       = $this->getLayout()->createBlock('adminhtml/report_sales_shipping_grid');
-        $this->_initReportAction($grid);
-        $this->_prepareDownloadResponse($fileName, $grid->getCsvFile());
-    }
-
-    /**
-     * Export shipping report grid to Excel XML format
-     */
-    public function exportShippingExcelAction()
-    {
-        $fileName   = 'shipping.xml';
-        $grid       = $this->getLayout()->createBlock('adminhtml/report_sales_shipping_grid');
-        $this->_initReportAction($grid);
-        $this->_prepareDownloadResponse($fileName, $grid->getExcelFile($fileName));
-    }
-
-    public function invoicedAction()
-    {
-        $this->_title($this->__('Reports'))->_title($this->__('Sales'))->_title($this->__('Total Invoiced'));
-
-        $this->_showLastExecutionTime(Mage_Reports_Model_Flag::REPORT_INVOICE_FLAG_CODE, 'invoiced');
-
-        $this->_initAction()
-            ->_setActiveMenu('report/sales/invoiced')
-            ->_addBreadcrumb(Mage::helper('adminhtml')->__('Total Invoiced'), Mage::helper('adminhtml')->__('Total Invoiced'));
-
-        $gridBlock = $this->getLayout()->getBlock('report_sales_invoiced.grid');
-        $filterFormBlock = $this->getLayout()->getBlock('grid.filter.form');
-
-        $this->_initReportAction(array(
-            $gridBlock,
-            $filterFormBlock
-        ));
-
-        $this->renderLayout();
-    }
-
-    /**
-     * Export invoiced report grid to CSV format
-     */
-    public function exportInvoicedCsvAction()
-    {
-        $fileName   = 'invoiced.csv';
-        $grid       = $this->getLayout()->createBlock('adminhtml/report_sales_invoiced_grid');
-        $this->_initReportAction($grid);
-        $this->_prepareDownloadResponse($fileName, $grid->getCsvFile());
-    }
-
-    /**
-     * Export invoiced report grid to Excel XML format
-     */
-    public function exportInvoicedExcelAction()
-    {
-        $fileName   = 'invoiced.xml';
-        $grid       = $this->getLayout()->createBlock('adminhtml/report_sales_invoiced_grid');
-        $this->_initReportAction($grid);
-        $this->_prepareDownloadResponse($fileName, $grid->getExcelFile($fileName));
-    }
-
-    public function refundedAction()
-    {
-        $this->_title($this->__('Reports'))->_title($this->__('Sales'))->_title($this->__('Total Refunded'));
-
-        $this->_showLastExecutionTime(Mage_Reports_Model_Flag::REPORT_REFUNDED_FLAG_CODE, 'refunded');
-
-        $this->_initAction()
-            ->_setActiveMenu('report/sales/refunded')
-            ->_addBreadcrumb(Mage::helper('adminhtml')->__('Total Refunded'), Mage::helper('adminhtml')->__('Total Refunded'));
-
-        $gridBlock = $this->getLayout()->getBlock('report_sales_refunded.grid');
-        $filterFormBlock = $this->getLayout()->getBlock('grid.filter.form');
-
-        $this->_initReportAction(array(
-            $gridBlock,
-            $filterFormBlock
-        ));
-
-        $this->renderLayout();
-    }
-
-    /**
-     * Export refunded report grid to CSV format
-     */
-    public function exportRefundedCsvAction()
-    {
-        $fileName   = 'refunded.csv';
-        $grid       = $this->getLayout()->createBlock('adminhtml/report_sales_refunded_grid');
-        $this->_initReportAction($grid);
-        $this->_prepareDownloadResponse($fileName, $grid->getCsvFile());
-    }
-
-    /**
-     * Export refunded report grid to Excel XML format
-     */
-    public function exportRefundedExcelAction()
-    {
-        $fileName   = 'refunded.xml';
-        $grid       = $this->getLayout()->createBlock('adminhtml/report_sales_refunded_grid');
-        $this->_initReportAction($grid);
-        $this->_prepareDownloadResponse($fileName, $grid->getExcelFile($fileName));
-    }
-
-    public function couponsAction()
-    {
-        $this->_title($this->__('Reports'))->_title($this->__('Sales'))->_title($this->__('Coupons'));
-
-        $this->_showLastExecutionTime(Mage_Reports_Model_Flag::REPORT_COUPONS_FLAG_CODE, 'coupons');
-
-        $this->_initAction()
-            ->_setActiveMenu('report/sales/coupons')
-            ->_addBreadcrumb(Mage::helper('adminhtml')->__('Coupons'), Mage::helper('adminhtml')->__('Coupons'));
-
-        $gridBlock = $this->getLayout()->getBlock('report_sales_coupons.grid');
-        $filterFormBlock = $this->getLayout()->getBlock('grid.filter.form');
-
-        $this->_initReportAction(array(
-            $gridBlock,
-            $filterFormBlock
-        ));
-
-        $this->renderLayout();
-    }
-
-    /**
-     * Export coupons report grid to CSV format
-     */
-    public function exportCouponsCsvAction()
-    {
-        $fileName   = 'coupons.csv';
-        $grid       = $this->getLayout()->createBlock('adminhtml/report_sales_coupons_grid');
-        $this->_initReportAction($grid);
-        $this->_prepareDownloadResponse($fileName, $grid->getCsvFile());
-    }
-
-    /**
-     * Export coupons report grid to Excel XML format
-     */
-    public function exportCouponsExcelAction()
-    {
-        $fileName   = 'coupons.xml';
-        $grid       = $this->getLayout()->createBlock('adminhtml/report_sales_coupons_grid');
-        $this->_initReportAction($grid);
-        $this->_prepareDownloadResponse($fileName, $grid->getExcelFile($fileName));
-    }
-
-    /**
-     * @deprecated after 1.4.0.1
-     */
-    public function refreshStatisticsAction()
-    {
-        return $this->_forward('index', 'report_statistics');
-    }
-
-    protected function _isAllowed()
-    {
-        switch ($this->getRequest()->getActionName()) {
-            case 'sales':
-                return $this->_getSession()->isAllowed('report/salesroot/sales');
-                break;
-            case 'tax':
-                return $this->_getSession()->isAllowed('report/salesroot/tax');
-                break;
-            case 'shipping':
-                return $this->_getSession()->isAllowed('report/salesroot/shipping');
-                break;
-            case 'invoiced':
-                return $this->_getSession()->isAllowed('report/salesroot/invoiced');
-                break;
-            case 'refunded':
-                return $this->_getSession()->isAllowed('report/salesroot/refunded');
-                break;
-            case 'coupons':
-                return $this->_getSession()->isAllowed('report/salesroot/coupons');
-                break;
-            case 'shipping':
-                return $this->_getSession()->isAllowed('report/salesroot/shipping');
-                break;
-            case 'bestsellers':
-                return $this->_getSession()->isAllowed('report/products/ordered');
-                break;
-            default:
-                return $this->_getSession()->isAllowed('report/salesroot');
-                break;
-        }
-    }
-
-    /**
-     * Retrieve admin session model
-     *
-     * @return Mage_Admin_Model_Session
-     */
-    protected function _getSession()
-    {
-        if (is_null($this->_adminSession)) {
-            $this->_adminSession = Mage::getSingleton('admin/session');
-        }
-        return $this->_adminSession;
-    }
-}
diff --git app/code/core/Mage/Adminhtml/controllers/Sales/Order/CreateController.php app/code/core/Mage/Adminhtml/controllers/Sales/Order/CreateController.php
index 1d16d144298..7458db701e9 100644
--- app/code/core/Mage/Adminhtml/controllers/Sales/Order/CreateController.php
+++ app/code/core/Mage/Adminhtml/controllers/Sales/Order/CreateController.php
@@ -126,6 +126,13 @@ class Mage_Adminhtml_Sales_Order_CreateController extends Mage_Adminhtml_Control
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
 
@@ -439,10 +446,20 @@ class Mage_Adminhtml_Sales_Order_CreateController extends Mage_Adminhtml_Control
 
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
             $this->_processData('save');
             if ($paymentData = $this->getRequest()->getPost('payment')) {
                 $this->_getOrderCreateModel()->setPaymentData($paymentData);
diff --git app/code/core/Mage/Adminhtml/controllers/SitemapController.php app/code/core/Mage/Adminhtml/controllers/SitemapController.php
index af208202dfa..9b4fea5b6d7 100644
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
@@ -130,6 +135,21 @@ class Mage_Adminhtml_SitemapController extends  Mage_Adminhtml_Controller_Action
             // init model and set data
             $model = Mage::getModel('sitemap/sitemap');
 
+            if (!empty($data['sitemap_filename']) && !empty($data['sitemap_path'])) {
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
+            }
+
             if ($this->getRequest()->getParam('sitemap_id')) {
                 $model ->load($this->getRequest()->getParam('sitemap_id'));
 
diff --git app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php
index eaae2e75c70..299bb73bdfa 100644
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
diff --git app/code/core/Mage/Adminhtml/controllers/Tax/RateController.php.orig app/code/core/Mage/Adminhtml/controllers/Tax/RateController.php.orig
deleted file mode 100644
index e983039b0fa..00000000000
--- app/code/core/Mage/Adminhtml/controllers/Tax/RateController.php.orig
+++ /dev/null
@@ -1,462 +0,0 @@
-<?php
-/**
- * Magento
- *
- * NOTICE OF LICENSE
- *
- * This source file is subject to the Open Software License (OSL 3.0)
- * that is bundled with this package in the file LICENSE.txt.
- * It is also available through the world-wide-web at this URL:
- * http://opensource.org/licenses/osl-3.0.php
- * If you did not receive a copy of the license and are unable to
- * obtain it through the world-wide-web, please send an email
- * to license@magentocommerce.com so we can send you a copy immediately.
- *
- * DISCLAIMER
- *
- * Do not edit or add to this file if you wish to upgrade Magento to newer
- * versions in the future. If you wish to customize Magento for your
- * needs please refer to http://www.magentocommerce.com for more information.
- *
- * @category    Mage
- * @package     Mage_Adminhtml
- * @copyright   Copyright (c) 2010 Magento Inc. (http://www.magentocommerce.com)
- * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
- */
-
-/**
- * Adminhtml tax rate controller
- *
- * @category   Mage
- * @package    Mage_Adminhtml
- * @author      Magento Core Team <core@magentocommerce.com>
- */
-
-class Mage_Adminhtml_Tax_RateController extends Mage_Adminhtml_Controller_Action
-{
-    /**
-     * Show Main Grid
-     *
-     */
-    public function indexAction()
-    {
-        $this->_title($this->__('Sales'))
-             ->_title($this->__('Tax'))
-             ->_title($this->__('Manage Tax Zones and Rates'));
-
-        $this->_initAction()
-            ->_addBreadcrumb(Mage::helper('tax')->__('Manage Tax Rates'), Mage::helper('tax')->__('Manage Tax Rates'))
-            ->_addContent(
-                $this->getLayout()->createBlock('adminhtml/tax_rate_toolbar_add', 'tax_rate_toolbar')
-                    ->assign('createUrl', $this->getUrl('*/tax_rate/add'))
-                    ->assign('header', Mage::helper('tax')->__('Manage Tax Rates'))
-            )
-            ->_addContent($this->getLayout()->createBlock('adminhtml/tax_rate_grid', 'tax_rate_grid'))
-            ->renderLayout();
-    }
-
-    /**
-     * Show Add Form
-     *
-     */
-    public function addAction()
-    {
-        $rateModel = Mage::getSingleton('tax/calculation_rate')
-            ->load(null);
-
-        $this->_title($this->__('Sales'))
-             ->_title($this->__('Tax'))
-             ->_title($this->__('Manage Tax Zones and Rates'));
-
-        $this->_title($this->__('New Rate'));
-
-        //This line substitutes in the form the previously entered by the user values, if any of them were wrong.
-        $rateModel->setData(Mage::getSingleton('adminhtml/session')->getFormData(true));
-
-        $this->_initAction()
-            ->_addBreadcrumb(Mage::helper('tax')->__('Manage Tax Rates'), Mage::helper('tax')->__('Manage Tax Rates'), $this->getUrl('*/tax_rate'))
-            ->_addBreadcrumb(Mage::helper('tax')->__('New Tax Rate'), Mage::helper('tax')->__('New Tax Rate'))
-            ->_addContent(
-                $this->getLayout()->createBlock('adminhtml/tax_rate_toolbar_save')
-                ->assign('header', Mage::helper('tax')->__('Add New Tax Rate'))
-                ->assign('form', $this->getLayout()->createBlock('adminhtml/tax_rate_form'))
-            )
-            ->renderLayout();
-    }
-
-    /**
-     * Save Rate and Data
-     *
-     * @return bool
-     */
-    public function saveAction()
-    {
-        $ratePost = $this->getRequest()->getPost();
-        if ($ratePost) {
-
-            $rateId = $this->getRequest()->getParam('tax_calculation_rate_id');
-            if ($rateId) {
-                $rateModel = Mage::getSingleton('tax/calculation_rate')->load($rateId);
-                if (!$rateModel->getId()) {
-                    unset($ratePost['tax_calculation_rate_id']);
-                }
-            }
-
-            $rateModel = Mage::getModel('tax/calculation_rate')->setData($ratePost);
-
-            try {
-                $rateModel->save();
-
-                Mage::getSingleton('adminhtml/session')->addSuccess(Mage::helper('tax')->__('The tax rate has been saved.'));
-                $this->getResponse()->setRedirect($this->getUrl("*/*/"));
-                return true;
-            }
-            catch (Mage_Core_Exception $e) {
-                //save entered by the user values in session, for re-rendering of form.
-                Mage::getSingleton('adminhtml/session')->setFormData($ratePost);
-                Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
-            }
-            catch (Exception $e) {
-                //Mage::getSingleton('adminhtml/session')->addError(Mage::helper('tax')->__('An error occurred while saving this rate.'));
-                Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
-            }
-
-            $this->_redirectReferer();
-            return;
-        }
-        $this->getResponse()->setRedirect($this->getUrl('*/tax_rate'));
-    }
-
-    /**
-     * Show Edit Form
-     *
-     */
-    public function editAction()
-    {
-        $this->_title($this->__('Sales'))
-             ->_title($this->__('Tax'))
-             ->_title($this->__('Manage Tax Zones and Rates'));
-
-        $rateId = (int)$this->getRequest()->getParam('rate');
-        $rateModel = Mage::getSingleton('tax/calculation_rate')->load($rateId);
-        if (!$rateModel->getId()) {
-            $this->getResponse()->setRedirect($this->getUrl("*/*/"));
-            return ;
-        }
-
-        $this->_title(sprintf("%s", $rateModel->getCode()));
-
-        $this->_initAction()
-            ->_addBreadcrumb(Mage::helper('tax')->__('Manage Tax Rates'), Mage::helper('tax')->__('Manage Tax Rates'), $this->getUrl('*/tax_rate'))
-            ->_addBreadcrumb(Mage::helper('tax')->__('Edit Tax Rate'), Mage::helper('tax')->__('Edit Tax Rate'))
-            ->_addContent(
-                $this->getLayout()->createBlock('adminhtml/tax_rate_toolbar_save')
-                ->assign('header', Mage::helper('tax')->__('Edit Tax Rate'))
-                ->assign('form', $this->getLayout()->createBlock('adminhtml/tax_rate_form'))
-            )
-            ->renderLayout();
-    }
-
-    /**
-     * Delete Rate and Data
-     *
-     * @return bool
-     */
-    public function deleteAction()
-    {
-        if ($rateId = $this->getRequest()->getParam('rate')) {
-            $rateModel = Mage::getModel('tax/calculation_rate')->load($rateId);
-            if ($rateModel->getId()) {
-                try {
-                    $rateModel->delete();
-
-                    Mage::getSingleton('adminhtml/session')->addSuccess(Mage::helper('tax')->__('The tax rate has been deleted.'));
-                    $this->getResponse()->setRedirect($this->getUrl("*/*/"));
-                    return true;
-                }
-                catch (Mage_Core_Exception $e) {
-                    Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
-                }
-                catch (Exception $e) {
-                    Mage::getSingleton('adminhtml/session')->addError(Mage::helper('tax')->__('An error occurred while deleting this rate.'));
-                }
-                if ($referer = $this->getRequest()->getServer('HTTP_REFERER')) {
-                    $this->getResponse()->setRedirect($referer);
-                }
-                else {
-                    $this->getResponse()->setRedirect($this->getUrl("*/*/"));
-                }
-            } else {
-                Mage::getSingleton('adminhtml/session')->addError(Mage::helper('tax')->__('An error occurred while deleting this rate. Incorrect rate ID.'));
-                $this->getResponse()->setRedirect($this->getUrl('*/*/'));
-            }
-        }
-    }
-
-    /**
-     * Export rates grid to CSV format
-     *
-     */
-    public function exportCsvAction()
-    {
-        $fileName   = 'rates.csv';
-        $content    = $this->getLayout()->createBlock('adminhtml/tax_rate_grid')
-            ->getCsvFile();
-
-        $this->_prepareDownloadResponse($fileName, $content);
-    }
-
-    /**
-     * Export rates grid to XML format
-     */
-    public function exportXmlAction()
-    {
-        $fileName   = 'rates.xml';
-        $content    = $this->getLayout()->createBlock('adminhtml/tax_rate_grid')
-            ->getExcelFile();
-
-        $this->_prepareDownloadResponse($fileName, $content);
-    }
-
-    /**
-     * Initialize action
-     *
-     * @return Mage_Adminhtml_Controller_Action
-     */
-    protected function _initAction()
-    {
-        $this->loadLayout()
-            ->_setActiveMenu('sales/tax_rates')
-            ->_addBreadcrumb(Mage::helper('tax')->__('Sales'), Mage::helper('tax')->__('Sales'))
-            ->_addBreadcrumb(Mage::helper('tax')->__('Tax'), Mage::helper('tax')->__('Tax'));
-        return $this;
-    }
-
-    /**
-     * Import and export Page
-     *
-     */
-    public function importExportAction()
-    {
-        $this->_title($this->__('Sales'))
-             ->_title($this->__('Tax'))
-             ->_title($this->__('Manage Tax Zones and Rates'));
-
-        $this->_title($this->__('Import and Export Tax Rates'));
-
-        $this->loadLayout()
-            ->_setActiveMenu('sales/tax_importExport')
-            ->_addContent($this->getLayout()->createBlock('adminhtml/tax_rate_importExport'))
-            ->renderLayout();
-    }
-
-    /**
-     * import action from import/export tax
-     *
-     */
-    public function importPostAction()
-    {
-        if ($this->getRequest()->isPost() && !empty($_FILES['import_rates_file']['tmp_name'])) {
-            try {
-                $this->_importRates();
-
-                Mage::getSingleton('adminhtml/session')->addSuccess(Mage::helper('tax')->__('The tax rate has been imported.'));
-            }
-            catch (Mage_Core_Exception $e) {
-                Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
-            }
-            catch (Exception $e) {
-                Mage::getSingleton('adminhtml/session')->addError(Mage::helper('tax')->__('Invalid file upload attempt'));
-            }
-        }
-        else {
-            Mage::getSingleton('adminhtml/session')->addError(Mage::helper('tax')->__('Invalid file upload attempt'));
-        }
-        $this->_redirect('*/*/importExport');
-    }
-
-    protected function _importRates()
-    {
-        $fileName   = $_FILES['import_rates_file']['tmp_name'];
-        $csvObject  = new Varien_File_Csv();
-        $csvData = $csvObject->getData($fileName);
-
-        /** checks columns */
-        $csvFields  = array(
-            0   => Mage::helper('tax')->__('Code'),
-            1   => Mage::helper('tax')->__('Country'),
-            2   => Mage::helper('tax')->__('State'),
-            3   => Mage::helper('tax')->__('Zip/Post Code'),
-            4   => Mage::helper('tax')->__('Rate')
-        );
-
-
-        $stores = array();
-        $unset = array();
-        $storeCollection = Mage::getModel('core/store')->getCollection()->setLoadDefault(false);
-        for ($i=5; $i<count($csvData[0]); $i++) {
-            $header = $csvData[0][$i];
-            $found = false;
-            foreach ($storeCollection as $store) {
-                if ($header == $store->getCode()) {
-                    $csvFields[$i] = $store->getCode();
-                    $stores[$i] = $store->getId();
-                    $found = true;
-                }
-            }
-            if (!$found) {
-                $unset[] = $i;
-            }
-
-        }
-
-        $regions = array();
-
-        if ($unset) {
-            foreach ($unset as $u) {
-                unset($csvData[0][$u]);
-            }
-        }
-        if ($csvData[0] == $csvFields) {
-            foreach ($csvData as $k => $v) {
-                if ($k == 0) {
-                    continue;
-                }
-
-                //end of file has more then one empty lines
-                if (count($v) <= 1 && !strlen($v[0])) {
-                    continue;
-                }
-                if ($unset) {
-                    foreach ($unset as $u) {
-                        unset($v[$u]);
-                    }
-                }
-
-                if (count($csvFields) != count($v)) {
-                    Mage::getSingleton('adminhtml/session')->addError(Mage::helper('tax')->__('Invalid file upload attempt'));
-                }
-
-                $country = Mage::getModel('directory/country')->loadByCode($v[1], 'iso2_code');
-                if (!$country->getId()) {
-                    Mage::getSingleton('adminhtml/session')->addError(Mage::helper('tax')->__('One of the country has invalid code.'));
-                    continue;
-                }
-
-                if (!isset($regions[$v[1]])) {
-                    $regions[$v[1]]['*'] = '*';
-                    $regionCollection = Mage::getModel('directory/region')->getCollection()
-                        ->addCountryFilter($v[1]);
-                    if ($regionCollection->getSize()) {
-                        foreach ($regionCollection as $region) {
-                            $regions[$v[1]][$region->getCode()] = $region->getRegionId();
-                        }
-                    }
-                }
-
-                if (!empty($regions[$v[1]][$v[2]])) {
-                    $rateData  = array(
-                        'code'=>$v[0],
-                        'tax_country_id' => $v[1],
-                        'tax_region_id' => ($regions[$v[1]][$v[2]] == '*') ? 0 : $regions[$v[1]][$v[2]],
-                        'tax_postcode'  => (empty($v[3]) || $v[3]=='*') ? null : $v[3],
-                        'rate'=>$v[4],
-                    );
-
-                    $rateModel = Mage::getModel('tax/calculation_rate')->loadByCode($rateData['code']);
-                    foreach($rateData as $dataName => $dataValue) {
-                        $rateModel->setData($dataName, $dataValue);
-                    }
-
-                    $titles = array();
-                    foreach ($stores as $field=>$id) {
-                        $titles[$id]=$v[$field];
-                    }
-                    $rateModel->setTitle($titles);
-                    $rateModel->save();
-                }
-            }
-        }
-        else {
-            Mage::throwException(Mage::helper('tax')->__('Invalid file format upload attempt'));
-        }
-    }
-
-    /**
-     * export action from import/export tax
-     *
-     */
-    public function exportPostAction()
-    {
-        /** start csv content and set template */
-        $headers = new Varien_Object(array(
-            'code'         => Mage::helper('tax')->__('Code'),
-            'country_name' => Mage::helper('tax')->__('Country'),
-            'region_name'  => Mage::helper('tax')->__('State'),
-            'tax_postcode' => Mage::helper('tax')->__('Zip/Post Code'),
-            'rate'         => Mage::helper('tax')->__('Rate')
-        ));
-        $template = '"{{code}}","{{country_name}}","{{region_name}}","{{tax_postcode}}","{{rate}}"';
-        $content = $headers->toString($template);
-
-        $storeTaxTitleTemplate       = array();
-        $taxCalculationRateTitleDict = array();
-
-        foreach (Mage::getModel('core/store')->getCollection()->setLoadDefault(false) as $store) {
-            $storeTitle = 'title_' . $store->getId();
-            $content   .= ',"' . $store->getCode() . '"';
-            $template  .= ',"{{' . $storeTitle . '}}"';
-            $storeTaxTitleTemplate[$storeTitle] = null;
-        }
-        unset($store);
-
-        $content .= "\n";
-
-        foreach (Mage::getModel('tax/calculation_rate_title')->getCollection() as $title) {
-            $rateId = $title->getTaxCalculationRateId();
-
-            if (! array_key_exists($rateId, $taxCalculationRateTitleDict)) {
-                $taxCalculationRateTitleDict[$rateId] = $storeTaxTitleTemplate;
-            }
-
-            $taxCalculationRateTitleDict[$rateId]['title_' . $title->getStoreId()] = $title->getValue();
-        }
-        unset($title);
-
-        $collection = Mage::getResourceModel('tax/calculation_rate_collection')
-            ->joinCountryTable()
-            ->joinRegionTable();
-
-        while ($rate = $collection->fetchItem()) {
-            if ($rate->getTaxRegionId() == 0) {
-                $rate->setRegionName('*');
-            }
-
-            if (array_key_exists($rate->getId(), $taxCalculationRateTitleDict)) {
-                $rate->addData($taxCalculationRateTitleDict[$rate->getId()]);
-            } else {
-                $rate->addData($storeTaxTitleTemplate);
-            }
-
-            $content .= $rate->toString($template) . "\n";
-        }
-
-        $this->_prepareDownloadResponse('tax_rates.csv', $content);
-    }
-
-    protected function _isAllowed()
-    {
-
-        switch ($this->getRequest()->getActionName()) {
-            case 'importExport':
-                return Mage::getSingleton('admin/session')->isAllowed('sales/tax/import_export');
-                break;
-            case 'index':
-                return Mage::getSingleton('admin/session')->isAllowed('sales/tax/rates');
-                break;
-            default:
-                return Mage::getSingleton('admin/session')->isAllowed('sales/tax/rates');
-                break;
-        }
-    }
-}
diff --git app/code/core/Mage/Catalog/Helper/Product.php app/code/core/Mage/Catalog/Helper/Product.php
index db8a4a7a7e3..696b1c486d7 100644
--- app/code/core/Mage/Catalog/Helper/Product.php
+++ app/code/core/Mage/Catalog/Helper/Product.php
@@ -35,6 +35,8 @@ class Mage_Catalog_Helper_Product extends Mage_Core_Helper_Url
     const XML_PATH_PRODUCT_URL_USE_CATEGORY     = 'catalog/seo/product_use_categories';
     const XML_PATH_USE_PRODUCT_CANONICAL_TAG    = 'catalog/seo/product_canonical_tag';
 
+    const DEFAULT_QTY                           = 1;
+
     /**
      * Cache for product rewrite suffix
      *
@@ -391,4 +393,41 @@ class Mage_Catalog_Helper_Product extends Mage_Core_Helper_Url
 
         return $buyRequest;
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
index 22c1c48c781..aa5c0299f4a 100644
--- app/code/core/Mage/Catalog/controllers/Product/CompareController.php
+++ app/code/core/Mage/Catalog/controllers/Product/CompareController.php
@@ -71,7 +71,11 @@ class Mage_Catalog_Product_CompareController extends Mage_Core_Controller_Front_
             $this->_redirectReferer();
             return;
         }
-        if ($productId = (int) $this->getRequest()->getParam('product')) {
+
+        $productId = (int) $this->getRequest()->getParam('product');
+        if ($this->isProductAvailable($productId)
+            && (Mage::getSingleton('log/visitor')->getId() || Mage::getSingleton('customer/session')->isLoggedIn())
+        ) {
             $product = Mage::getModel('catalog/product')
                 ->setStoreId(Mage::app()->getStore()->getId())
                 ->load($productId);
@@ -95,7 +99,8 @@ class Mage_Catalog_Product_CompareController extends Mage_Core_Controller_Front_
      */
     public function removeAction()
     {
-        if ($productId = (int) $this->getRequest()->getParam('product')) {
+        $productId = (int) $this->getRequest()->getParam('product');
+        if ($this->isProductAvailable($productId)) {
             $product = Mage::getModel('catalog/product')
                 ->setStoreId(Mage::app()->getStore()->getId())
                 ->load($productId);
@@ -157,4 +162,15 @@ class Mage_Catalog_Product_CompareController extends Mage_Core_Controller_Front_
 
         $this->_redirectReferer();
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
index f68c5b97f5c..3a275a34056 100644
--- app/code/core/Mage/Checkout/Model/Session.php
+++ app/code/core/Mage/Checkout/Model/Session.php
@@ -57,11 +57,18 @@ class Mage_Checkout_Model_Session extends Mage_Core_Model_Session_Abstract
         if ($this->_quote === null) {
             $quote = Mage::getModel('sales/quote')
                 ->setStoreId(Mage::app()->getStore()->getId());
+            $customerSession = Mage::getSingleton('customer/session');
 
             /* @var $quote Mage_Sales_Model_Quote */
             if ($this->getQuoteId()) {
                 $quote->loadActive($this->getQuoteId());
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
@@ -78,15 +85,15 @@ class Mage_Checkout_Model_Session extends Mage_Core_Model_Session_Abstract
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
                 if ($customerSession->isLoggedIn()) {
                     $quote->loadByCustomer($customerSession->getCustomer());
+                    $quote->setCustomer($customerSession->getCustomer());
                     $this->setQuoteId($quote->getId());
                 } else {
                     $quote->setIsCheckoutCart(true);
diff --git app/code/core/Mage/Checkout/controllers/OnepageController.php app/code/core/Mage/Checkout/controllers/OnepageController.php
index 3ca5cb7c10d..48b2d180313 100644
--- app/code/core/Mage/Checkout/controllers/OnepageController.php
+++ app/code/core/Mage/Checkout/controllers/OnepageController.php
@@ -488,7 +488,7 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
      */
     public function saveOrderAction()
     {
-        if (!$this->_validateFormKey()) {
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
             return $this->_redirect('*/*');
         }
 
diff --git app/code/core/Mage/Cms/Helper/Data.php app/code/core/Mage/Cms/Helper/Data.php
index c6fe4163a39..ec1011d8678 100644
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
index 2ea30dae903..62043dfb0bc 100644
--- app/code/core/Mage/Cms/Model/Wysiwyg/Config.php
+++ app/code/core/Mage/Cms/Model/Wysiwyg/Config.php
@@ -76,7 +76,8 @@ class Mage_Cms_Model_Wysiwyg_Config extends Varien_Object
             'popup_css'                     => Mage::getBaseUrl('js').'mage/adminhtml/wysiwyg/tiny_mce/themes/advanced/skins/default/dialog.css',
             'content_css'                   => Mage::getBaseUrl('js').'mage/adminhtml/wysiwyg/tiny_mce/themes/advanced/skins/default/content.css',
             'width'                         => '100%',
-            'plugins'                       => array()
+            'plugins'                       => array(),
+            'media_disable_flash'           => Mage::helper('cms')->isSwfDisabled()
         ));
 
         $config->setData('directives_url_quoted', preg_quote($config->getData('directives_url')));
diff --git app/code/core/Mage/Cms/etc/config.xml app/code/core/Mage/Cms/etc/config.xml
index 607babc0e06..f12407bc6be 100644
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
index 691cd4d7866..c699802313a 100644
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
index ce5ebd776fa..d9855585985 100644
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
index 7cacc1157e9..1b869916363 100644
--- app/code/core/Mage/Core/Helper/Data.php
+++ app/code/core/Mage/Core/Helper/Data.php
@@ -231,7 +231,7 @@ class Mage_Core_Helper_Data extends Mage_Core_Helper_Abstract
         }
         mt_srand(10000000*(double)microtime());
         for ($i = 0, $str = '', $lc = strlen($chars)-1; $i < $len; $i++) {
-            $str .= $chars[mt_rand(0, $lc)];
+            $str .= $chars[random_int(0, $lc)];
         }
         return $str;
     }
diff --git app/code/core/Mage/Core/Model/Design/Package.php app/code/core/Mage/Core/Model/Design/Package.php
index 34476259f01..5b3100a40c2 100644
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
index 04534cb4bb4..207059490dc 100644
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
diff --git app/code/core/Mage/Core/Model/Observer.php app/code/core/Mage/Core/Model/Observer.php
index a35deb5bcca..07fdad50c8a 100644
--- app/code/core/Mage/Core/Model/Observer.php
+++ app/code/core/Mage/Core/Model/Observer.php
@@ -94,4 +94,19 @@ class Mage_Core_Model_Observer
 
         return $this;
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
index 33996c608c8..8e817646448 100644
--- app/code/core/Mage/Core/etc/config.xml
+++ app/code/core/Mage/Core/etc/config.xml
@@ -119,6 +119,24 @@
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
index 7741f695728..014c7ade7c9 100644
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
diff --git app/code/core/Mage/Downloadable/controllers/DownloadController.php app/code/core/Mage/Downloadable/controllers/DownloadController.php
index cbb040fc21b..052ad8ab7f8 100644
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
diff --git app/code/core/Mage/Sendfriend/etc/config.xml app/code/core/Mage/Sendfriend/etc/config.xml
index d205730f974..0fc0476f6b6 100644
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
index 8bc6e2d43ac..4aae92827fd 100644
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
index 46173ed39cb..afb0956d992 100644
--- app/design/adminhtml/default/default/template/catalog/product/composite/fieldset/configurable.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/composite/fieldset/configurable.phtml
@@ -34,7 +34,7 @@
     <div class="product-options">
         <dl>
         <?php foreach($_attributes as $_attribute): ?>
-            <dt><label class="required"><em>*</em><?php echo $_attribute->getLabel() ?></label></dt>
+            <dt><label class="required"><em>*</em><?php echo $this->escapeHtml($_attribute->getLabel()) ?></label></dt>
             <dd<?php if ($_attribute->decoratedIsLast){?> class="last"<?php }?>>
                 <div class="input-box">
                     <select name="super_attribute[<?php echo $_attribute->getAttributeId() ?>]" id="attribute<?php echo $_attribute->getAttributeId() ?>" class="required-entry super-attribute-select">
diff --git app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
index 3e165b26a00..a214987036d 100644
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
index 59b423172a6..9053abf9bf3 100644
--- app/design/adminhtml/default/default/template/catalog/product/tab/inventory.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/tab/inventory.phtml
@@ -77,7 +77,7 @@
 
         <tr>
             <td class="label"><label for="inventory_min_sale_qty"><?php echo Mage::helper('catalog')->__('Minimum Qty Allowed in Shopping Cart') ?></label></td>
-            <td class="value"><input type="text" class="input-text validate-number" id="inventory_min_sale_qty" name="<?php echo $this->getFieldSuffix() ?>[stock_data][min_sale_qty]" value="<?php echo $this->getFieldValue('min_sale_qty')*1 ?>" <?php echo $_readonly;?>/>
+            <td class="value"><input type="text" class="input-text validate-number" id="inventory_min_sale_qty" name="<?php echo $this->getFieldSuffix() ?>[stock_data][min_sale_qty]" value="<?php echo (bool)$this->getProduct()->getId() ? (int)$this->getFieldValue('min_sale_qty') : Mage::helper('catalog/product')->getDefaultProductValue('min_sale_qty', $this->getProduct()->getTypeId()) ?>" <?php echo $_readonly ?>/>
 
             <?php $_checked = ($this->getFieldValue('use_config_min_sale_qty') || $this->IsNew()) ? 'checked="checked"' : '' ?>
             <input type="checkbox" id="inventory_use_config_min_sale_qty" name="<?php echo $this->getFieldSuffix() ?>[stock_data][use_config_min_sale_qty]" value="1" <?php echo $_checked ?> onclick="toggleValueElements(this, this.parentNode);" class="checkbox" <?php echo $_readonly;?> />
diff --git app/design/adminhtml/default/default/template/customer/tab/addresses.phtml app/design/adminhtml/default/default/template/customer/tab/addresses.phtml
index 87b17d8f5f7..19777c41920 100644
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
index 3e30f71617d..5e9ee630e64 100644
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
diff --git app/design/adminhtml/default/default/template/notification/window.phtml app/design/adminhtml/default/default/template/notification/window.phtml
index f0014521ade..2d56de122cb 100644
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
index d2c09269996..fedb3c8dd18 100644
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
index db2f4eda817..60b38af2822 100644
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
index b0351a6e161..88f3f0ad4ab 100644
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
                         </th>
                     <?php else: ?>
                         <td class="a-right">
-                            <input type="text" name="rate[<?php echo $_currencyCode ?>][<?php echo $_rate ?>]" value="<?php echo ( $_currencyCode == $_rate ) ? '1.0000' : ($_value>0 ? $_value : (isset($_oldRates[$_currencyCode][$_rate]) ? $_oldRates[$_currencyCode][$_rate] : '')) ?>" <?php echo ( $_currencyCode == $_rate ) ? 'class="input-text input-text-disabled" readonly="true"' : 'class="input-text"' ?> />
+                            <input type="text" name="rate[<?php echo $this->escapeHtml($_currencyCode) ?>][<?php echo $this->escapeHtml($_rate) ?>]" value="<?php echo ( $_currencyCode == $_rate ) ? '1.0000' : ($_value>0 ? $_value : (isset($_oldRates[$_currencyCode][$_rate]) ? $_oldRates[$_currencyCode][$_rate] : '')) ?>" <?php echo ( $_currencyCode == $_rate ) ? 'class="input-text input-text-disabled" readonly="true"' : 'class="input-text"' ?> />
                             <?php if( isset($_newRates)  && $_currencyCode != $_rate && isset($_oldRates[$_currencyCode][$_rate]) ): ?>
                             <br /><span class="old-rate"><?php echo $this->__('Old rate:') ?> <?php echo $_oldRates[$_currencyCode][$_rate] ?></span>
                             <?php endif; ?>
diff --git app/locale/en_US/Mage_Adminhtml.csv app/locale/en_US/Mage_Adminhtml.csv
index 7d96c90d86d..4793fd16d05 100644
--- app/locale/en_US/Mage_Adminhtml.csv
+++ app/locale/en_US/Mage_Adminhtml.csv
@@ -43,7 +43,7 @@
 "80x80 px","80x80 px"
 "<h1 class=""page-heading"">404 Error</h1><p>Page not found.</p>","<h1 class=""page-heading"">404 Error</h1><p>Page not found.</p>"
 "A new password was sent to your email address. Please check your email and click Back to Login.","A new password was sent to your email address. Please check your email and click Back to Login."
-"A user with the same user name or email aleady exists.","A user with the same user name or email aleady exists."
+"A user with the same user name or email already exists.","A user with the same user name or email already exists."
 "API Key","API Key"
 "API Key Confirmation","API Key Confirmation"
 "Abandoned Carts","Abandoned Carts"
@@ -251,6 +251,7 @@
 "Credit memo #%s created","Credit memo #%s created"
 "Credit memo\'s total must be positive.","Credit memo\'s total must be positive."
 "Currency","Currency"
+"Currency doesn\'t exist.","Currency doesn\'t exist."
 "Currency Information","Currency Information"
 "Currency Setup Section","Currency Setup Section"
 "Current Configuration Scope:","Current Configuration Scope:"
@@ -873,6 +874,7 @@
 "Self-assigned roles cannot be deleted.","Self-assigned roles cannot be deleted."
 "Sender","Sender"
 "Separate Email","Separate Email"
+"Serialized data is incorrect","Serialized data is incorrect"
 "Shipment #%s comment added","Shipment #%s comment added"
 "Shipment #%s created","Shipment #%s created"
 "Shipment Comments","Shipment Comments"
@@ -993,6 +995,7 @@
 "The email address is empty.","The email address is empty."
 "The email template has been deleted.","The email template has been deleted."
 "The email template has been saved.","The email template has been saved."
+"Invalid template data.","Invalid template data."
 "The flat catalog category has been rebuilt.","The flat catalog category has been rebuilt."
 "The group node name must be specified with field node name.","The group node name must be specified with field node name."
 "The image cache was cleaned.","The image cache was cleaned."
diff --git app/locale/en_US/Mage_Core.csv app/locale/en_US/Mage_Core.csv
index 6ec6984bb90..87c138e7621 100644
--- app/locale/en_US/Mage_Core.csv
+++ app/locale/en_US/Mage_Core.csv
@@ -41,6 +41,7 @@
 "Can't retrieve request object","Can't retrieve request object"
 "Cancel","Cancel"
 "Cannot complete this operation from non-admin area.","Cannot complete this operation from non-admin area."
+"Disallowed template variable method.","Disallowed template variable method."
 "Cannot retrieve entity config: %s","Cannot retrieve entity config: %s"
 "Card type does not match credit card number.","Card type does not match credit card number."
 "Code","Code"
diff --git app/locale/en_US/Mage_Sales.csv app/locale/en_US/Mage_Sales.csv
index 761b445bf8c..2fcb1c90344 100644
--- app/locale/en_US/Mage_Sales.csv
+++ app/locale/en_US/Mage_Sales.csv
@@ -251,6 +251,7 @@
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
index d50b2e324ff..dc5c38dae7e 100644
--- js/mage/adminhtml/wysiwyg/tiny_mce/setup.js
+++ js/mage/adminhtml/wysiwyg/tiny_mce/setup.js
@@ -108,6 +108,7 @@ tinyMceWysiwygSetup.prototype =
             theme_advanced_resizing : true,
             convert_urls : false,
             relative_urls : false,
+            media_disable_flash : this.config.media_disable_flash,
             content_css: this.config.content_css,
             custom_popup_css: this.config.popup_css,
             magentowidget_url: this.config.widget_window_url,
diff --git js/varien/js.js js/varien/js.js
index 43f3980c2c4..b8b48f3fd9a 100644
--- js/varien/js.js
+++ js/varien/js.js
@@ -585,3 +585,40 @@ function fireEvent(element, event){
         return !element.dispatchEvent(evt);
     }
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
