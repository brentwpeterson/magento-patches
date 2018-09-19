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


SUPEE-10888_CE_v1.9.3.7 | CE_1.9.3.7 | v1 | b6fe7d138ba3593a70bc74d851dd107936f3ff97 | Wed Aug 29 17:56:33 2018 +0300 | ce-1.9.3.7-dev

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Admin/Model/User.php app/code/core/Mage/Admin/Model/User.php
index 04641fd9f1e..51f7d304fed 100644
--- app/code/core/Mage/Admin/Model/User.php
+++ app/code/core/Mage/Admin/Model/User.php
@@ -66,6 +66,10 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
     const XML_PATH_FORGOT_EMAIL_TEMPLATE    = 'admin/emails/forgot_email_template';
     const XML_PATH_FORGOT_EMAIL_IDENTITY    = 'admin/emails/forgot_email_identity';
     const XML_PATH_STARTUP_PAGE             = 'admin/startup/page';
+
+    /** Configuration paths for notifications */
+    const XML_PATH_ADDITIONAL_EMAILS             = 'general/additional_notification_emails/admin_user_create';
+    const XML_PATH_NOTIFICATION_EMAILS_TEMPLATE  = 'admin/emails/admin_notification_email_template';
     /**#@-*/
 
     /**
@@ -692,4 +696,53 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
     {
         return now($dayOnly);
     }
+
+    /**
+     * Send notification to general Contact and additional emails when new admin user created.
+     * You can declare additional emails in Mage_Core general/additional_notification_emails/admin_user_create node.
+     *
+     * @param $user
+     * @return $this
+     */
+    public function sendAdminNotification($user)
+    {
+        // define general contact Name and Email
+        $generalContactName = Mage::getStoreConfig('trans_email/ident_general/name');
+        $generalContactEmail = Mage::getStoreConfig('trans_email/ident_general/email');
+
+        // collect general and additional emails
+        $emails = $this->getUserCreateAdditionalEmail();
+        $emails[] = $generalContactEmail;
+
+        /** @var $mailer Mage_Core_Model_Email_Template_Mailer */
+        $mailer    = Mage::getModel('core/email_template_mailer');
+        $emailInfo = Mage::getModel('core/email_info');
+        $emailInfo->addTo(array_filter($emails), $generalContactName);
+        $mailer->addEmailInfo($emailInfo);
+
+        // Set all required params and send emails
+        $mailer->setSender(array(
+            'name'  => $generalContactName,
+            'email' => $generalContactEmail,
+        ));
+        $mailer->setStoreId(0);
+        $mailer->setTemplateId(Mage::getStoreConfig(self::XML_PATH_NOTIFICATION_EMAILS_TEMPLATE));
+        $mailer->setTemplateParams(array(
+            'user' => $user,
+        ));
+        $mailer->send();
+
+        return $this;
+    }
+
+    /**
+     * Get additional emails for notification from config.
+     *
+     * @return array
+     */
+    public function getUserCreateAdditionalEmail()
+    {
+        $emails = str_replace(' ', '', Mage::getStoreConfig(self::XML_PATH_ADDITIONAL_EMAILS));
+        return explode(',', $emails);
+    }
 }
diff --git app/code/core/Mage/Admin/etc/config.xml app/code/core/Mage/Admin/etc/config.xml
index fb868e61bf7..7681dc21ed6 100644
--- app/code/core/Mage/Admin/etc/config.xml
+++ app/code/core/Mage/Admin/etc/config.xml
@@ -84,6 +84,7 @@
         <admin>
             <emails>
                 <forgot_email_template>admin_emails_forgot_email_template</forgot_email_template>
+                <admin_notification_email_template>admin_emails_admin_notification_email_template</admin_notification_email_template>
                 <forgot_email_identity>general</forgot_email_identity>
                 <password_reset_link_expiration_period>2</password_reset_link_expiration_period>
             </emails>
diff --git app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php
index b7d69bfecf9..adcd2706676 100644
--- app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php
+++ app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php
@@ -154,6 +154,7 @@ class Mage_Adminhtml_Block_Catalog_Product_Edit_Tab_Super_Config extends Mage_Ad
         } else {
             // Hide price if needed
             foreach ($attributes as &$attribute) {
+                $attribute['label'] = $this->escapeHtml($attribute['label']);
                 if (isset($attribute['values']) && is_array($attribute['values'])) {
                     foreach ($attribute['values'] as &$attributeValue) {
                         if (!$this->getCanReadPrice()) {
diff --git app/code/core/Mage/Adminhtml/Block/Widget/Grid/Massaction/Abstract.php app/code/core/Mage/Adminhtml/Block/Widget/Grid/Massaction/Abstract.php
index fe36c3d090a..330869d7c32 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Grid/Massaction/Abstract.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Grid/Massaction/Abstract.php
@@ -190,7 +190,7 @@ abstract class Mage_Adminhtml_Block_Widget_Grid_Massaction_Abstract extends Mage
     public function getSelectedJson()
     {
         if($selected = $this->getRequest()->getParam($this->getFormFieldNameInternal())) {
-            $selected = explode(',', $selected);
+            $selected = explode(',', $this->quoteEscape($selected));
             return join(',', $selected);
         } else {
             return '';
@@ -205,7 +205,7 @@ abstract class Mage_Adminhtml_Block_Widget_Grid_Massaction_Abstract extends Mage
     public function getSelected()
     {
         if($selected = $this->getRequest()->getParam($this->getFormFieldNameInternal())) {
-            $selected = explode(',', $selected);
+            $selected = explode(',', $this->quoteEscape($selected));
             return $selected;
         } else {
             return array();
diff --git app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
index 6a9921ac065..a0e413f84d6 100644
--- app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
+++ app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
@@ -38,6 +38,7 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
 {
     const XML_INVALID                             = 'invalidXml';
     const INVALID_TEMPLATE_PATH                   = 'invalidTemplatePath';
+    const INVALID_BLOCK_NAME                      = 'invalidBlockName';
     const PROTECTED_ATTR_HELPER_IN_TAG_ACTION_VAR = 'protectedAttrHelperInActionVar';
 
     /**
@@ -56,7 +57,18 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
         '*//template',
         '*//@template',
         '//*[@method=\'setTemplate\']',
-        '//*[@method=\'setDataUsingMethod\']//*[text() = \'template\']/../*'
+        '//*[@method=\'setDataUsingMethod\']//*[contains(translate(text(),
+        \'ABCDEFGHIJKLMNOPQRSTUVWXYZ\', \'abcdefghijklmnopqrstuvwxyz\'), \'template\')]/../*',
+    );
+
+    /**
+     * Disallowed template name
+     *
+     * @var array
+     */
+    protected $_disallowedBlock = array(
+        'Mage_Install_Block_End',
+        'Mage_Rss_Block_Order_New',
     );
 
     /**
@@ -91,6 +103,7 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
                 self::INVALID_TEMPLATE_PATH => Mage::helper('adminhtml')->__(
                     'Invalid template path used in layout update.'
                 ),
+                self::INVALID_BLOCK_NAME => Mage::helper('adminhtml')->__('Disallowed block name for frontend.'),
             );
         }
         return $this;
@@ -125,6 +138,10 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
                 Mage::helper('adminhtml')->__('XML object is not instance of "Varien_Simplexml_Element".'));
         }
 
+        if ($value->xpath($this->_getXpathBlockValidationExpression())) {
+            $this->_error(self::INVALID_BLOCK_NAME);
+            return false;
+        }
         // if layout update declare custom templates then validate their paths
         if ($templatePaths = $value->xpath($this->_getXpathValidationExpression())) {
             try {
@@ -154,6 +171,20 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
         return implode(" | ", $this->_disallowedXPathExpressions);
     }
 
+    /**
+     * Returns xPath for validate incorrect block name
+     *
+     * @return string xPath for validate incorrect block name
+     */
+    protected function _getXpathBlockValidationExpression() {
+        $xpath = "";
+        if (count($this->_disallowedBlock)) {
+            $xpath = "//block[@type='";
+            $xpath .= implode("'] | //block[@type='", $this->_disallowedBlock) . "']";
+        }
+        return $xpath;
+    }
+
     /**
      * Validate template path for preventing access to the directory above
      * If template path value has "../" @throws Exception
@@ -162,7 +193,11 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
      */
     protected function _validateTemplatePath(array $templatePaths)
     {
+        /**@var $path Varien_Simplexml_Element */
         foreach ($templatePaths as $path) {
+            if ($path->hasChildren()) {
+                $path = stripcslashes(trim((string) $path->children(), '"'));
+            }
             if (strpos($path, '..' . DS) !== false) {
                 throw new Exception();
             }
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
index cce6f64aabe..5e662c839a9 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
@@ -1031,6 +1031,16 @@ class Mage_Adminhtml_Catalog_ProductController extends Mage_Adminhtml_Controller
         }
 
         $product->addData($this->getRequest()->getParam('simple_product', array()));
+
+        $productSku = $product->getSku();
+        if ($productSku && $productSku != Mage::helper('core')->stripTags($productSku)) {
+            $result['error'] = array(
+                'message' => $this->__('HTML tags are not allowed in SKU attribute.')
+            );
+            $this->getResponse()->setBody(Mage::helper('core')->jsonEncode($result));
+            return;
+        }
+
         $product->setWebsiteIds($configurableProduct->getWebsiteIds());
 
         $autogenerateOptions = array();
diff --git app/code/core/Mage/Adminhtml/controllers/Permissions/UserController.php app/code/core/Mage/Adminhtml/controllers/Permissions/UserController.php
index 1d6eddff4f1..b63f68331e2 100644
--- app/code/core/Mage/Adminhtml/controllers/Permissions/UserController.php
+++ app/code/core/Mage/Adminhtml/controllers/Permissions/UserController.php
@@ -101,6 +101,8 @@ class Mage_Adminhtml_Permissions_UserController extends Mage_Adminhtml_Controlle
 
             $id = $this->getRequest()->getParam('user_id');
             $model = Mage::getModel('admin/user')->load($id);
+            // @var $isNew flag for detecting new admin user creation.
+            $isNew = !$model->getId() ? true : false;
             if (!$model->getId() && $id) {
                 Mage::getSingleton('adminhtml/session')->addError($this->__('This user no longer exists.'));
                 $this->_redirect('*/*/');
@@ -139,6 +141,10 @@ class Mage_Adminhtml_Permissions_UserController extends Mage_Adminhtml_Controlle
 
             try {
                 $model->save();
+                // Send notification to General and additional contacts (if declared) that a new admin user was created.
+                if (Mage::getStoreConfigFlag('admin/security/crate_admin_user_notification') && $isNew) {
+                    Mage::getModel('admin/user')->sendAdminNotification($model);
+                }
                 if ( $uRoles = $this->getRequest()->getParam('roles', false) ) {
                     /*parse_str($uRoles, $uRoles);
                     $uRoles = array_keys($uRoles);*/
diff --git app/code/core/Mage/Adminhtml/etc/config.xml app/code/core/Mage/Adminhtml/etc/config.xml
index c33b6e027e9..cefa6869fde 100644
--- app/code/core/Mage/Adminhtml/etc/config.xml
+++ app/code/core/Mage/Adminhtml/etc/config.xml
@@ -54,6 +54,11 @@
                     <file>admin_password_reset_confirmation.html</file>
                     <type>html</type>
                 </admin_emails_forgot_email_template>
+                <admin_emails_admin_notification_email_template>
+                    <label>New Admin User Create Notification</label>
+                    <file>admin_new_user_notification.html</file>
+                    <type>html</type>
+                </admin_emails_admin_notification_email_template>
             </email>
         </template>
         <events>
diff --git app/code/core/Mage/Checkout/Model/Api/Resource/Customer.php app/code/core/Mage/Checkout/Model/Api/Resource/Customer.php
index 42e517f4c86..52fbe1deda2 100644
--- app/code/core/Mage/Checkout/Model/Api/Resource/Customer.php
+++ app/code/core/Mage/Checkout/Model/Api/Resource/Customer.php
@@ -152,7 +152,7 @@ class Mage_Checkout_Model_Api_Resource_Customer extends Mage_Checkout_Model_Api_
         $customer->setPasswordCreatedAt(time());
         $quote->setCustomer($customer)
             ->setCustomerId(true);
-
+        $quote->setPasswordHash('');
         return $this;
     }
 
diff --git app/code/core/Mage/Checkout/Model/Type/Onepage.php app/code/core/Mage/Checkout/Model/Type/Onepage.php
index b837ae7bdb0..84c8799c103 100644
--- app/code/core/Mage/Checkout/Model/Type/Onepage.php
+++ app/code/core/Mage/Checkout/Model/Type/Onepage.php
@@ -734,6 +734,7 @@ class Mage_Checkout_Model_Type_Onepage
         $customer->setPasswordCreatedAt($passwordCreatedTime);
         $quote->setCustomer($customer)
             ->setCustomerId(true);
+        $quote->setPasswordHash('');
     }
 
     /**
diff --git app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
index 9a4133afb1d..e12db7cf133 100644
--- app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
+++ app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
@@ -283,11 +283,13 @@ class Mage_Cms_Model_Wysiwyg_Images_Storage extends Varien_Object
         }
         $uploader->setAllowRenameFiles(true);
         $uploader->setFilesDispersion(false);
-        $uploader->addValidateCallback(
-            Mage_Core_Model_File_Validator_Image::NAME,
-            Mage::getModel('core/file_validator_image'),
-            'validate'
-        );
+        if ($type == 'image') {
+            $uploader->addValidateCallback(
+                Mage_Core_Model_File_Validator_Image::NAME,
+                Mage::getModel('core/file_validator_image'),
+                'validate'
+            );
+        }
         $result = $uploader->save($targetPath);
 
         if (!$result) {
@@ -295,8 +297,9 @@ class Mage_Cms_Model_Wysiwyg_Images_Storage extends Varien_Object
         }
 
         // create thumbnail
-        $this->resizeFile($targetPath . DS . $uploader->getUploadedFileName(), true);
-
+        if ($type == 'image') {
+            $this->resizeFile($targetPath . DS . $uploader->getUploadedFileName(), true);
+        }
         $result['cookie'] = array(
             'name'     => session_name(),
             'value'    => $this->getSession()->getSessionId(),
diff --git app/code/core/Mage/Core/etc/config.xml app/code/core/Mage/Core/etc/config.xml
index 4b61da7a454..816eaec8849 100644
--- app/code/core/Mage/Core/etc/config.xml
+++ app/code/core/Mage/Core/etc/config.xml
@@ -471,6 +471,11 @@
             <reprocess_images>
                 <active>1</active>
             </reprocess_images>
+            <!-- Additional email for notifications -->
+            <additional_notification_emails>
+                <!-- On creating a new admin user. You can specify several emails separated by commas. -->
+                <admin_user_create></admin_user_create>
+            </additional_notification_emails>
         </general>
     </default>
     <stores>
diff --git app/code/core/Mage/Core/etc/system.xml app/code/core/Mage/Core/etc/system.xml
index 7228fdb52c3..b03da6bac55 100644
--- app/code/core/Mage/Core/etc/system.xml
+++ app/code/core/Mage/Core/etc/system.xml
@@ -1219,6 +1219,16 @@
                             <show_in_website>0</show_in_website>
                             <show_in_store>0</show_in_store>
                         </extensions_compatibility_mode>
+                        <crate_admin_user_notification translate="label comment">
+                            <label>New Admin User Create Notification</label>
+                            <comment>This setting enable notification when new admin user created.</comment>
+                            <frontend_type>select</frontend_type>
+                            <sort_order>10</sort_order>
+                            <source_model>adminhtml/system_config_source_enabledisable</source_model>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>0</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </crate_admin_user_notification>
                     </fields>
                 </security>
                 <dashboard translate="label">
diff --git app/code/core/Mage/Customer/Helper/Data.php app/code/core/Mage/Customer/Helper/Data.php
index 3d93d16fe8c..c75a3978cb5 100644
--- app/code/core/Mage/Customer/Helper/Data.php
+++ app/code/core/Mage/Customer/Helper/Data.php
@@ -459,6 +459,17 @@ class Mage_Customer_Helper_Data extends Mage_Core_Helper_Abstract
         return Mage::helper('core')->uniqHash();
     }
 
+    /**
+     * Generate unique token based on customer Id for reset password confirmation link
+     *
+     * @param $customerId
+     * @return string
+     */
+    public function generateResetPasswordLinkCustomerId($customerId)
+    {
+        return md5(uniqid($customerId . microtime() . mt_rand(), true));
+    }
+
     /**
      * Retrieve customer reset password link expiration period in days
      *
diff --git app/code/core/Mage/Customer/Model/Customer.php app/code/core/Mage/Customer/Model/Customer.php
index 26eb04ff350..d23e8f18a10 100644
--- app/code/core/Mage/Customer/Model/Customer.php
+++ app/code/core/Mage/Customer/Model/Customer.php
@@ -57,6 +57,7 @@ class Mage_Customer_Model_Customer extends Mage_Core_Model_Abstract
     const EXCEPTION_INVALID_EMAIL_OR_PASSWORD = 2;
     const EXCEPTION_EMAIL_EXISTS              = 3;
     const EXCEPTION_INVALID_RESET_PASSWORD_LINK_TOKEN = 4;
+    const EXCEPTION_INVALID_RESET_PASSWORD_LINK_CUSTOMER_ID = 5;
     /**#@-*/
 
     /**#@+
@@ -1390,6 +1391,28 @@ class Mage_Customer_Model_Customer extends Mage_Core_Model_Abstract
         return $this;
     }
 
+    /**
+     * Change reset password link customer Id
+     *
+     * Stores new reset password link customer Id
+     *
+     * @param string $newResetPasswordLinkCustomerId
+     * @return Mage_Customer_Model_Customer
+     * @throws Mage_Core_Exception
+     */
+    public function changeResetPasswordLinkCustomerId($newResetPasswordLinkCustomerId)
+    {
+        if (!is_string($newResetPasswordLinkCustomerId) || empty($newResetPasswordLinkCustomerId)) {
+            throw Mage::exception(
+                'Mage_Core',
+                Mage::helper('customer')->__('Invalid password reset customer Id.'),
+                self::EXCEPTION_INVALID_RESET_PASSWORD_LINK_CUSTOMER_ID
+            );
+        }
+        $this->_getResource()->changeResetPasswordLinkCustomerId($this, $newResetPasswordLinkCustomerId);
+        return $this;
+    }
+
     /**
      * Check if current reset password link token is expired
      *
diff --git app/code/core/Mage/Customer/Model/Resource/Customer.php app/code/core/Mage/Customer/Model/Resource/Customer.php
index 2a9abf9f8b2..6257c519dba 100644
--- app/code/core/Mage/Customer/Model/Resource/Customer.php
+++ app/code/core/Mage/Customer/Model/Resource/Customer.php
@@ -333,4 +333,25 @@ class Mage_Customer_Model_Resource_Customer extends Mage_Eav_Model_Entity_Abstra
         }
         return $this;
     }
+
+    /**
+     * Change reset password link customer Id
+     *
+     * Stores new reset password link customer Id
+     *
+     * @param Mage_Customer_Model_Customer $customer
+     * @param string $newResetPasswordLinkCustomerId
+     * @return Mage_Customer_Model_Resource_Customer
+     * @throws Exception
+     */
+    public function changeResetPasswordLinkCustomerId(
+        Mage_Customer_Model_Customer $customer,
+        $newResetPasswordLinkCustomerId
+    ) {
+        if (is_string($newResetPasswordLinkCustomerId) && !empty($newResetPasswordLinkCustomerId)) {
+            $customer->setRpCustomerId($newResetPasswordLinkCustomerId);
+            $this->saveAttribute($customer, 'rp_customer_id');
+        }
+        return $this;
+    }
 }
diff --git app/code/core/Mage/Customer/controllers/AccountController.php app/code/core/Mage/Customer/controllers/AccountController.php
index 2ec2a7ee3df..a2594421a33 100644
--- app/code/core/Mage/Customer/controllers/AccountController.php
+++ app/code/core/Mage/Customer/controllers/AccountController.php
@@ -756,9 +756,13 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                 ->setWebsiteId(Mage::app()->getStore()->getWebsiteId())
                 ->loadByEmail($email);
 
-            if ($customer->getId()) {
+            $customerId = $customer->getId();
+            if ($customerId) {
                 try {
                     $newResetPasswordLinkToken =  $this->_getHelper('customer')->generateResetPasswordLinkToken();
+                    $newResetPasswordLinkCustomerId = $this->_getHelper('customer')
+                        ->generateResetPasswordLinkCustomerId($customerId);
+                    $customer->changeResetPasswordLinkCustomerId($newResetPasswordLinkCustomerId);
                     $customer->changeResetPasswordLinkToken($newResetPasswordLinkToken);
                     $customer->sendPasswordResetConfirmationEmail();
                 } catch (Exception $exception) {
@@ -807,7 +811,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
     public function resetPasswordAction()
     {
         try {
-            $customerId = (int)$this->getRequest()->getQuery("id");
+            $customerId = (int)$this->getCustomerId();
             $resetPasswordLinkToken = (string)$this->getRequest()->getQuery('token');
 
             $this->_validateResetPasswordLinkToken($customerId, $resetPasswordLinkToken);
@@ -867,6 +871,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             $customer->setRpTokenCreatedAt(null);
             $customer->cleanPasswordsValidationData();
             $customer->setPasswordCreatedAt(time());
+            $customer->setRpCustomerId(null);
             $customer->save();
 
             $this->_getSession()->unsetData(self::TOKEN_SESSION_NAME);
@@ -881,6 +886,25 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
         }
     }
 
+    /**
+     * @return mixed
+     */
+    protected function getCustomerId()
+    {
+        $customerId = $this->getRequest()->getQuery("id");
+        if (strlen($customerId) > 12) {
+            $customerCollection = $this->_getModel('customer/customer')
+                ->getCollection()
+                ->addAttributeToSelect(array('rp_customer_id'))
+                ->addFieldToFilter('rp_customer_id', $customerId);
+            $customerId = count($customerCollection) === 1
+                ? $customerId = $customerCollection->getFirstItem()->getId()
+                : false;
+        }
+
+        return $customerId;
+    }
+
     /**
      * Check if password reset token is valid
      *
diff --git app/code/core/Mage/Customer/etc/config.xml app/code/core/Mage/Customer/etc/config.xml
index 54aaba14c31..bbf408ec786 100644
--- app/code/core/Mage/Customer/etc/config.xml
+++ app/code/core/Mage/Customer/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Mage_Customer>
-            <version>1.6.2.0.5.1.2</version>
+            <version>1.6.2.0.5.1.3</version>
         </Mage_Customer>
     </modules>
     <admin>
diff --git app/code/core/Mage/Customer/sql/customer_setup/upgrade-1.6.2.0.5.1.2-1.6.2.0.5.1.3.php app/code/core/Mage/Customer/sql/customer_setup/upgrade-1.6.2.0.5.1.2-1.6.2.0.5.1.3.php
new file mode 100644
index 00000000000..867227ea4bb
--- /dev/null
+++ app/code/core/Mage/Customer/sql/customer_setup/upgrade-1.6.2.0.5.1.2-1.6.2.0.5.1.3.php
@@ -0,0 +1,39 @@
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
+ * @copyright  Copyright (c) 2006-2018 Magento, Inc. (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/* @var $installer Mage_Customer_Model_Entity_Setup */
+$installer = $this;
+$installer->startSetup();
+
+// Add reset password link customer Id attribute
+$installer->addAttribute('customer', 'rp_customer_id', array(
+    'type'     => 'varchar',
+    'input'    => 'hidden',
+    'visible'  => false,
+    'required' => false
+));
+
+$installer->endSetup();
diff --git app/code/core/Mage/Paypal/Model/Express/Checkout.php app/code/core/Mage/Paypal/Model/Express/Checkout.php
index 96fd886beea..1f14d6267f1 100644
--- app/code/core/Mage/Paypal/Model/Express/Checkout.php
+++ app/code/core/Mage/Paypal/Model/Express/Checkout.php
@@ -992,6 +992,7 @@ class Mage_Paypal_Model_Express_Checkout
         $customer->setPasswordHash($customer->hashPassword($customer->getPassword()));
         $customer->save();
         $quote->setCustomer($customer);
+        $quote->setPasswordHash('');
 
         return $this;
     }
diff --git app/code/core/Mage/XmlConnect/controllers/ReviewController.php app/code/core/Mage/XmlConnect/controllers/ReviewController.php
index 3b99ac4b825..73a4932025c 100644
--- app/code/core/Mage/XmlConnect/controllers/ReviewController.php
+++ app/code/core/Mage/XmlConnect/controllers/ReviewController.php
@@ -144,7 +144,7 @@ class Mage_XmlConnect_ReviewController extends Mage_XmlConnect_Controller_Action
         if ($product && !empty($data)) {
             /** @var $review Mage_Review_Model_Review */
             $review     = Mage::getModel('review/review')->setData($data);
-            $validate   = $review->validate();
+            $validate = array_key_exists('review_id', $data) ? false : $review->validate();
 
             if ($validate === true) {
                 try {
diff --git app/code/core/Zend/Filter/PregReplace.php app/code/core/Zend/Filter/PregReplace.php
index 586c0fe20a0..d6fa2dac0ec 100644
--- app/code/core/Zend/Filter/PregReplace.php
+++ app/code/core/Zend/Filter/PregReplace.php
@@ -21,7 +21,8 @@
 
 /**
  * This class replaces default Zend_Filter_PregReplace because of problem described in MPERF-10057
- * The only difference between current class and original one is overwritten implementation of filter method
+ * The only difference between current class and original one is overwritten implementation of filter method and add new
+ * method _isValidMatchPattern
  *
  * @see Zend_Filter_Interface
  */
@@ -170,14 +171,31 @@ class Zend_Filter_PregReplace implements Zend_Filter_Interface
             #require_once 'Zend/Filter/Exception.php';
             throw new Zend_Filter_Exception(get_class($this) . ' does not have a valid MatchPattern set.');
         }
-        $firstDilimeter = substr($this->_matchPattern, 0, 1);
-        $partsOfRegex = explode($firstDilimeter, $this->_matchPattern);
-        $modifiers = array_pop($partsOfRegex);
-        if ($modifiers != str_replace('e', '', $modifiers)) {
+        if (!$this->_isValidMatchPattern()) {
             throw new Zend_Filter_Exception(get_class($this) . ' uses deprecated modifier "/e".');
         }
 
         return preg_replace($this->_matchPattern, $this->_replacement, $value);
     }
 
+    /**
+     * Method for checking correctness of match pattern
+     *
+     * @return bool
+     */
+    public function _isValidMatchPattern()
+    {
+        $result = true;
+        foreach ((array) $this->_matchPattern as $pattern) {
+            $firstDilimeter = substr($pattern, 0, 1);
+            $partsOfRegex = explode($firstDilimeter, $pattern);
+            $modifiers = array_pop($partsOfRegex);
+            if ($modifiers != str_replace('e', '', $modifiers)) {
+                $result = false;
+                break;
+            }
+        }
+
+        return $result;
+    }
 }
diff --git app/design/adminhtml/default/default/template/bundle/product/edit/bundle/option.phtml app/design/adminhtml/default/default/template/bundle/product/edit/bundle/option.phtml
index 9eb4e051ffb..375080250b5 100644
--- app/design/adminhtml/default/default/template/bundle/product/edit/bundle/option.phtml
+++ app/design/adminhtml/default/default/template/bundle/product/edit/bundle/option.phtml
@@ -209,14 +209,16 @@ var optionIndex = 0;
 bOption = new Bundle.Option(optionTemplate);
 //adding data to templates
 <?php foreach ($this->getOptions() as $_option): ?>
-optionIndex = bOption.add(<?php echo $_option->toJson() ?>);
-<?php if ($_option->getSelections()):?>
-    <?php foreach ($_option->getSelections() as $_selection): ?>
-    <?php $_selection->setName($this->escapeHtml($_selection->getName())); ?>
-    <?php $_selection->setSku($this->escapeHtml($_selection->getSku())); ?>
-bSelection.addRow(optionIndex, <?php echo $_selection->toJson() ?>);
-    <?php endforeach; ?>
-<?php endif; ?>
+    <?php $_option->setDefaultTitle($this->escapeHtml($_option->getDefaultTitle())); ?>
+    <?php $_option->setTitle($this->escapeHtml($_option->getTitle())); ?>
+    optionIndex = bOption.add(<?php echo $_option->toJson() ?>);
+    <?php if ($_option->getSelections()):?>
+        <?php foreach ($_option->getSelections() as $_selection): ?>
+        <?php $_selection->setName($this->escapeHtml($_selection->getName())); ?>
+        <?php $_selection->setSku($this->escapeHtml($_selection->getSku())); ?>
+        bSelection.addRow(optionIndex, <?php echo $_selection->toJson() ?>);
+        <?php endforeach; ?>
+    <?php endif; ?>
 <?php endforeach; ?>
 /**
  * Adding event on price type select box of product to hide or show prices for selections
diff --git app/design/adminhtml/default/default/template/bundle/sales/creditmemo/create/items/renderer.phtml app/design/adminhtml/default/default/template/bundle/sales/creditmemo/create/items/renderer.phtml
index 0dd0a11c76c..f04204d2e86 100644
--- app/design/adminhtml/default/default/template/bundle/sales/creditmemo/create/items/renderer.phtml
+++ app/design/adminhtml/default/default/template/bundle/sales/creditmemo/create/items/renderer.phtml
@@ -49,7 +49,7 @@
     <?php if ($_item->getOrderItem()->getParentItem()): ?>
         <?php if ($_prevOptionId != $attributes['option_id']): ?>
         <tr>
-            <td><div class="option-label"><?php echo $attributes['option_label'] ?></div></td>
+            <td><div class="option-label"><?php echo $this->escapeHtml($attributes['option_label']); ?></div></td>
             <td>&nbsp;</td>
             <td>&nbsp;</td>
             <td>&nbsp;</td>
diff --git app/design/adminhtml/default/default/template/bundle/sales/creditmemo/view/items/renderer.phtml app/design/adminhtml/default/default/template/bundle/sales/creditmemo/view/items/renderer.phtml
index 4f6ceaffe95..cb8403f7acb 100644
--- app/design/adminhtml/default/default/template/bundle/sales/creditmemo/view/items/renderer.phtml
+++ app/design/adminhtml/default/default/template/bundle/sales/creditmemo/view/items/renderer.phtml
@@ -49,7 +49,7 @@
     <?php if ($_item->getOrderItem()->getParentItem()): ?>
         <?php if ($_prevOptionId != $attributes['option_id']): ?>
         <tr>
-            <td><div class="option-label"><?php echo $attributes['option_label'] ?></div></td>
+            <td><div class="option-label"><?php echo $this->escapeHtml($attributes['option_label']); ?></div></td>
             <td>&nbsp;</td>
             <td>&nbsp;</td>
             <td>&nbsp;</td>
diff --git app/design/adminhtml/default/default/template/bundle/sales/invoice/create/items/renderer.phtml app/design/adminhtml/default/default/template/bundle/sales/invoice/create/items/renderer.phtml
index e4b9315c6f4..76658722111 100644
--- app/design/adminhtml/default/default/template/bundle/sales/invoice/create/items/renderer.phtml
+++ app/design/adminhtml/default/default/template/bundle/sales/invoice/create/items/renderer.phtml
@@ -49,7 +49,7 @@
         <?php $attributes = $this->getSelectionAttributes($_item) ?>
         <?php if ($_prevOptionId != $attributes['option_id']): ?>
         <tr>
-            <td><div class="option-label"><?php echo $attributes['option_label'] ?></div></td>
+            <td><div class="option-label"><?php echo $this->escapeHtml($attributes['option_label']); ?></div></td>
             <td>&nbsp;</td>
             <td>&nbsp;</td>
             <td>&nbsp;</td>
diff --git app/design/adminhtml/default/default/template/bundle/sales/invoice/view/items/renderer.phtml app/design/adminhtml/default/default/template/bundle/sales/invoice/view/items/renderer.phtml
index 1ad5eb1ed73..fe7efb7031f 100644
--- app/design/adminhtml/default/default/template/bundle/sales/invoice/view/items/renderer.phtml
+++ app/design/adminhtml/default/default/template/bundle/sales/invoice/view/items/renderer.phtml
@@ -49,7 +49,7 @@
         <?php $attributes = $this->getSelectionAttributes($_item) ?>
         <?php if ($_prevOptionId != $attributes['option_id']): ?>
         <tr>
-            <td><div class="option-label"><?php echo $attributes['option_label'] ?></div></td>
+            <td><div class="option-label"><?php echo $this->escapeHtml($attributes['option_label']); ?></div></td>
             <td>&nbsp;</td>
             <td>&nbsp;</td>
             <td>&nbsp;</td>
diff --git app/design/adminhtml/default/default/template/bundle/sales/order/view/items/renderer.phtml app/design/adminhtml/default/default/template/bundle/sales/order/view/items/renderer.phtml
index b394906834a..ed998bb7780 100644
--- app/design/adminhtml/default/default/template/bundle/sales/order/view/items/renderer.phtml
+++ app/design/adminhtml/default/default/template/bundle/sales/order/view/items/renderer.phtml
@@ -49,7 +49,7 @@
     <?php if ($_item->getParentItem()): ?>
         <?php if ($_prevOptionId != $attributes['option_id']): ?>
         <tr>
-            <td><div class="option-label"><?php echo $attributes['option_label'] ?></div></td>
+            <td><div class="option-label"><?php echo $this->escapeHtml($attributes['option_label']); ?></div></td>
             <td>&nbsp;</td>
             <td>&nbsp;</td>
             <td>&nbsp;</td>
diff --git app/design/adminhtml/default/default/template/bundle/sales/shipment/create/items/renderer.phtml app/design/adminhtml/default/default/template/bundle/sales/shipment/create/items/renderer.phtml
index 3b5b5f59691..0fd4f916108 100644
--- app/design/adminhtml/default/default/template/bundle/sales/shipment/create/items/renderer.phtml
+++ app/design/adminhtml/default/default/template/bundle/sales/shipment/create/items/renderer.phtml
@@ -49,7 +49,7 @@
         <?php $attributes = $this->getSelectionAttributes($_item) ?>
         <?php if ($_prevOptionId != $attributes['option_id']): ?>
         <tr>
-            <td><div class="option-label"><?php echo $attributes['option_label'] ?></div></td>
+            <td><div class="option-label"><?php echo $this->escapeHtml($attributes['option_label']); ?></div></td>
             <td>&nbsp;</td>
             <td class="last">&nbsp;</td>
         </tr>
diff --git app/design/adminhtml/default/default/template/bundle/sales/shipment/view/items/renderer.phtml app/design/adminhtml/default/default/template/bundle/sales/shipment/view/items/renderer.phtml
index 1878a2b66ba..8b3e5160a76 100644
--- app/design/adminhtml/default/default/template/bundle/sales/shipment/view/items/renderer.phtml
+++ app/design/adminhtml/default/default/template/bundle/sales/shipment/view/items/renderer.phtml
@@ -50,7 +50,7 @@
         <?php $attributes = $this->getSelectionAttributes($_item) ?>
         <?php if ($_prevOptionId != $attributes['option_id']): ?>
         <tr>
-            <td><div class="option-label"><?php echo $attributes['option_label'] ?></div></td>
+            <td><div class="option-label"><?php echo $this->escapeHtml($attributes['option_label']); ?></div></td>
             <td class="last">&nbsp;</td>
         </tr>
         <?php $_prevOptionId = $attributes['option_id'] ?>
diff --git app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
index 892c5032fab..576988757ae 100644
--- app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
@@ -58,8 +58,8 @@ $_block = $this;
             <th><?php echo Mage::helper('catalog')->__('Image') ?></th>
             <th><?php echo Mage::helper('catalog')->__('Label') ?></th>
             <th><?php echo Mage::helper('catalog')->__('Sort Order') ?></th>
-            <?php foreach ($_block->getImageTypes() as $typeId=>$type): ?>
-            <th><?php echo $type['label'] ?></th>
+            <?php foreach ($_block->getImageTypes() as $typeId => $type): ?>
+                <th><?php echo $this->escapeHtml($type['label']); ?></th>
             <?php endforeach; ?>
             <th><?php echo Mage::helper('catalog')->__('Exclude') ?></th>
             <th class="last"><?php echo Mage::helper('catalog')->__('Remove') ?></th>
diff --git app/design/frontend/base/default/template/bundle/email/order/items/creditmemo/default.phtml app/design/frontend/base/default/template/bundle/email/order/items/creditmemo/default.phtml
index 51e0ad5e6ad..a22def9566a 100644
--- app/design/frontend/base/default/template/bundle/email/order/items/creditmemo/default.phtml
+++ app/design/frontend/base/default/template/bundle/email/order/items/creditmemo/default.phtml
@@ -43,7 +43,7 @@
     <?php $attributes = $this->getSelectionAttributes($_item) ?>
     <?php if ($_prevOptionId != $attributes['option_id']): ?>
     <tr>
-        <td align="left" valign="top" style="padding:3px 9px"><strong><?php echo $attributes['option_label'] ?></strong></td>
+        <td align="left" valign="top" style="padding:3px 9px"><strong><?php echo $this->escapeHtml($attributes['option_label']); ?></strong></td>
         <td>&nbsp;</td>
         <td>&nbsp;</td>
         <td>&nbsp;</td>
diff --git app/design/frontend/base/default/template/bundle/email/order/items/invoice/default.phtml app/design/frontend/base/default/template/bundle/email/order/items/invoice/default.phtml
index 0df4e6ee365..a296568789f 100644
--- app/design/frontend/base/default/template/bundle/email/order/items/invoice/default.phtml
+++ app/design/frontend/base/default/template/bundle/email/order/items/invoice/default.phtml
@@ -44,7 +44,7 @@
     <?php $attributes = $this->getSelectionAttributes($_item) ?>
     <?php if ($_prevOptionId != $attributes['option_id']): ?>
     <tr>
-        <td align="left" valign="top" style="padding:3px 9px"><strong><em><?php echo $attributes['option_label'] ?></em></strong></td>
+        <td align="left" valign="top" style="padding:3px 9px"><strong><em><?php echo $this->escapeHtml($attributes['option_label']); ?></em></strong></td>
         <td>&nbsp;</td>
         <td>&nbsp;</td>
         <td>&nbsp;</td>
diff --git app/design/frontend/base/default/template/bundle/email/order/items/order/default.phtml app/design/frontend/base/default/template/bundle/email/order/items/order/default.phtml
index 31e263de164..3902d73b433 100644
--- app/design/frontend/base/default/template/bundle/email/order/items/order/default.phtml
+++ app/design/frontend/base/default/template/bundle/email/order/items/order/default.phtml
@@ -44,7 +44,7 @@
     <?php $attributes = $this->getSelectionAttributes($_item) ?>
     <?php if ($_prevOptionId != $attributes['option_id']): ?>
     <tr>
-        <td align="left" valign="top" style="padding:3px 9px"><strong><em><?php echo $attributes['option_label'] ?></em></strong></td>
+        <td align="left" valign="top" style="padding:3px 9px"><strong><em><?php echo $this->escapeHtml($attributes['option_label']); ?></em></strong></td>
         <td>&nbsp;</td>
         <td>&nbsp;</td>
         <td>&nbsp;</td>
diff --git app/design/frontend/base/default/template/bundle/email/order/items/shipment/default.phtml app/design/frontend/base/default/template/bundle/email/order/items/shipment/default.phtml
index c347a90f640..684bcbafc04 100644
--- app/design/frontend/base/default/template/bundle/email/order/items/shipment/default.phtml
+++ app/design/frontend/base/default/template/bundle/email/order/items/shipment/default.phtml
@@ -43,7 +43,7 @@
     <?php $attributes = $this->getSelectionAttributes($_item) ?>
     <?php if ($_prevOptionId != $attributes['option_id']): ?>
     <tr>
-        <td align="left" valign="top" style="padding:3px 9px"><strong><em><?php echo $attributes['option_label'] ?></em></strong></td>
+        <td align="left" valign="top" style="padding:3px 9px"><strong><em><?php echo $this->escapeHtml($attributes['option_label']); ?></em></strong></td>
         <td>&nbsp;</td>
         <td>&nbsp;</td>
     </tr>
diff --git app/design/frontend/base/default/template/bundle/sales/order/creditmemo/items/renderer.phtml app/design/frontend/base/default/template/bundle/sales/order/creditmemo/items/renderer.phtml
index d13040e775b..fd050741c8a 100644
--- app/design/frontend/base/default/template/bundle/sales/order/creditmemo/items/renderer.phtml
+++ app/design/frontend/base/default/template/bundle/sales/order/creditmemo/items/renderer.phtml
@@ -46,7 +46,7 @@
         <?php if ($_prevOptionId != $attributes['option_id']): ?>
             <tr>
                 <td>
-                    <div class="option-label"><?php echo $attributes['option_label'] ?></div>
+                    <div class="option-label"><?php echo $this->escapeHtml($attributes['option_label']); ?></div>
                 </td>
                 <td>&nbsp;</td>
                 <td>&nbsp;</td>
diff --git app/design/frontend/base/default/template/bundle/sales/order/invoice/items/renderer.phtml app/design/frontend/base/default/template/bundle/sales/order/invoice/items/renderer.phtml
index bb3ba810b82..49736ba4202 100644
--- app/design/frontend/base/default/template/bundle/sales/order/invoice/items/renderer.phtml
+++ app/design/frontend/base/default/template/bundle/sales/order/invoice/items/renderer.phtml
@@ -46,7 +46,7 @@
         <?php if ($_prevOptionId != $attributes['option_id']): ?>
             <tr>
                 <td>
-                    <div class="option-label"><?php echo $attributes['option_label'] ?></div>
+                    <div class="option-label"><?php echo $this->escapeHtml($attributes['option_label']); ?></div>
                 </td>
                 <td>&nbsp;</td>
                 <td>&nbsp;</td>
diff --git app/design/frontend/base/default/template/bundle/sales/order/items/renderer.phtml app/design/frontend/base/default/template/bundle/sales/order/items/renderer.phtml
index 01dadca502e..034f7463d35 100644
--- app/design/frontend/base/default/template/bundle/sales/order/items/renderer.phtml
+++ app/design/frontend/base/default/template/bundle/sales/order/items/renderer.phtml
@@ -43,7 +43,7 @@
     <?php $attributes = $this->getSelectionAttributes($_item) ?>
     <?php if ($_prevOptionId != $attributes['option_id']): ?>
     <tr<?php if ($_item->getLastRow()) echo 'class="last"'; ?>>
-        <td><div class="option-label"><?php echo $attributes['option_label'] ?></div></td>
+        <td><div class="option-label"><?php echo $this->escapeHtml($attributes['option_label']); ?></div></td>
         <td>&nbsp;</td>
         <td>&nbsp;</td>
         <td>&nbsp;</td>
diff --git app/design/frontend/base/default/template/bundle/sales/order/shipment/items/renderer.phtml app/design/frontend/base/default/template/bundle/sales/order/shipment/items/renderer.phtml
index 057e7567503..68163cfd71a 100644
--- app/design/frontend/base/default/template/bundle/sales/order/shipment/items/renderer.phtml
+++ app/design/frontend/base/default/template/bundle/sales/order/shipment/items/renderer.phtml
@@ -44,7 +44,7 @@
     <?php $attributes = $this->getSelectionAttributes($_item) ?>
     <?php if ($_prevOptionId != $attributes['option_id']): ?>
     <tr>
-        <td><div class="option-label"><?php echo $attributes['option_label'] ?></div></td>
+        <td><div class="option-label"><?php echo $this->escapeHtml($attributes['option_label']); ?></div></td>
         <td>&nbsp;</td>
         <td>&nbsp;</td>
     </tr>
diff --git app/design/frontend/base/default/template/downloadable/checkout/multishipping/item/downloadable.phtml app/design/frontend/base/default/template/downloadable/checkout/multishipping/item/downloadable.phtml
index 8ae0d244e4a..24f053d99d8 100644
--- app/design/frontend/base/default/template/downloadable/checkout/multishipping/item/downloadable.phtml
+++ app/design/frontend/base/default/template/downloadable/checkout/multishipping/item/downloadable.phtml
@@ -48,7 +48,7 @@
     <!-- downloadable -->
     <?php if ($links = $this->getLinks()): ?>
     <dl class="item-options">
-        <dt><?php echo $this->getLinksTitle() ?></dt>
+        <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
         <?php foreach ($links as $link): ?>
             <dd><?php echo $this->escapeHtml($link->getTitle()); ?></dd>
         <?php endforeach; ?>
diff --git app/design/frontend/base/default/template/downloadable/email/order/items/creditmemo/downloadable.phtml app/design/frontend/base/default/template/downloadable/email/order/items/creditmemo/downloadable.phtml
index 2bc93626784..e84a8d92c01 100644
--- app/design/frontend/base/default/template/downloadable/email/order/items/creditmemo/downloadable.phtml
+++ app/design/frontend/base/default/template/downloadable/email/order/items/creditmemo/downloadable.phtml
@@ -39,7 +39,7 @@
         <?php endif; ?>
         <?php if ($links = $this->getLinks()->getPurchasedItems()): ?>
             <dl style="margin:0; padding:0;">
-                <dt><strong><em><?php echo $this->getLinksTitle() ?></em></strong></dt>
+                <dt><strong><em><?php echo $this->escapeHtml($this->getLinksTitle()); ?></em></strong></dt>
                 <?php foreach ($links as $link): ?>
                     <dd style="margin:0; padding:0 0 0 9px;"><?php echo $this->escapeHtml($link->getLinkTitle()); ?></dd>
                 <?php endforeach; ?>
diff --git app/design/frontend/base/default/template/downloadable/email/order/items/invoice/downloadable.phtml app/design/frontend/base/default/template/downloadable/email/order/items/invoice/downloadable.phtml
index c1610a9379f..a8b4ae591a0 100644
--- app/design/frontend/base/default/template/downloadable/email/order/items/invoice/downloadable.phtml
+++ app/design/frontend/base/default/template/downloadable/email/order/items/invoice/downloadable.phtml
@@ -42,7 +42,7 @@
         <?php endif; ?>
         <?php if ($links = $this->getLinks()->getPurchasedItems()): ?>
             <dl style="margin:0; padding:0;">
-                <dt><strong><em><?php echo $this->getLinksTitle() ?></em></strong></dt>
+                <dt><strong><em><?php echo $this->escapeHtml($this->getLinksTitle()); ?></em></strong></dt>
                 <?php foreach ($links as $link): ?>
                     <dd style="margin:0; padding:0 0 0 9px;">
                         <?php echo $this->escapeHtml($link->getLinkTitle()); ?>&nbsp;
diff --git app/design/frontend/base/default/template/downloadable/email/order/items/order/downloadable.phtml app/design/frontend/base/default/template/downloadable/email/order/items/order/downloadable.phtml
index 0440941a716..fbd0ba137f7 100644
--- app/design/frontend/base/default/template/downloadable/email/order/items/order/downloadable.phtml
+++ app/design/frontend/base/default/template/downloadable/email/order/items/order/downloadable.phtml
@@ -39,7 +39,7 @@
         <?php endif; ?>
         <?php if ($links = $this->getLinks()->getPurchasedItems()): ?>
             <dl style="margin:0; padding:0;">
-                <dt><strong><em><?php echo $this->getLinksTitle() ?></em></strong></dt>
+                <dt><strong><em><?php echo $this->escapeHtml($this->getLinksTitle()); ?></em></strong></dt>
                 <?php foreach ($links as $link): ?>
                     <dd style="margin:0; padding:0 0 0 9px;">
                         <?php echo $this->escapeHtml($link->getLinkTitle()); ?>&nbsp;
diff --git app/design/frontend/base/default/template/downloadable/sales/order/creditmemo/items/renderer/downloadable.phtml app/design/frontend/base/default/template/downloadable/sales/order/creditmemo/items/renderer/downloadable.phtml
index 49ff4ade2cc..ce66f830d1a 100644
--- app/design/frontend/base/default/template/downloadable/sales/order/creditmemo/items/renderer/downloadable.phtml
+++ app/design/frontend/base/default/template/downloadable/sales/order/creditmemo/items/renderer/downloadable.phtml
@@ -54,7 +54,7 @@
     <!-- downloadable -->
     <?php if ($links = $this->getLinks()): ?>
         <dl class="item-options">
-            <dt><?php echo $this->getLinksTitle() ?></dt>
+            <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
             <?php foreach ($links->getPurchasedItems() as $link): ?>
                 <dd><?php echo $this->escapeHtml($link->getLinkTitle()); ?></dd>
             <?php endforeach; ?>
diff --git app/design/frontend/base/default/template/downloadable/sales/order/invoice/items/renderer/downloadable.phtml app/design/frontend/base/default/template/downloadable/sales/order/invoice/items/renderer/downloadable.phtml
index d6615234845..54e44776cb2 100644
--- app/design/frontend/base/default/template/downloadable/sales/order/invoice/items/renderer/downloadable.phtml
+++ app/design/frontend/base/default/template/downloadable/sales/order/invoice/items/renderer/downloadable.phtml
@@ -55,7 +55,7 @@
     <!-- downloadable -->
     <?php if ($links = $this->getLinks()): ?>
         <dl class="item-options">
-            <dt><?php echo $this->getLinksTitle() ?></dt>
+            <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
             <?php foreach ($links->getPurchasedItems() as $link): ?>
                 <dd><?php echo $this->escapeHtml($link->getLinkTitle()); ?></dd>
             <?php endforeach; ?>
diff --git app/design/frontend/default/iphone/template/downloadable/sales/order/creditmemo/items/renderer/downloadable.phtml app/design/frontend/default/iphone/template/downloadable/sales/order/creditmemo/items/renderer/downloadable.phtml
index 37639169c1b..60d0bcc90c9 100644
--- app/design/frontend/default/iphone/template/downloadable/sales/order/creditmemo/items/renderer/downloadable.phtml
+++ app/design/frontend/default/iphone/template/downloadable/sales/order/creditmemo/items/renderer/downloadable.phtml
@@ -55,7 +55,7 @@
         <!-- downloadable -->
         <?php if ($links = $this->getLinks()): ?>
             <dl class="item-options">
-                <dt><?php echo $this->getLinksTitle() ?></dt>
+                <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
                 <?php foreach ($links->getPurchasedItems() as $link): ?>
                     <dd><?php echo $this->escapeHtml($link->getLinkTitle()); ?></dd>
                 <?php endforeach; ?>
diff --git app/design/frontend/default/iphone/template/downloadable/sales/order/invoice/items/renderer/downloadable.phtml app/design/frontend/default/iphone/template/downloadable/sales/order/invoice/items/renderer/downloadable.phtml
index 90a078f1b1f..c5e246ae327 100644
--- app/design/frontend/default/iphone/template/downloadable/sales/order/invoice/items/renderer/downloadable.phtml
+++ app/design/frontend/default/iphone/template/downloadable/sales/order/invoice/items/renderer/downloadable.phtml
@@ -56,7 +56,7 @@
         <!-- downloadable -->
         <?php if ($links = $this->getLinks()): ?>
             <dl class="item-options">
-                <dt><?php echo $this->getLinksTitle() ?></dt>
+                <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
                 <?php foreach ($links->getPurchasedItems() as $link): ?>
                     <dd><?php echo $this->escapeHtml($link->getLinkTitle()); ?></dd>
                 <?php endforeach; ?>
diff --git app/design/frontend/default/iphone/template/downloadable/sales/order/items/renderer/downloadable.phtml app/design/frontend/default/iphone/template/downloadable/sales/order/items/renderer/downloadable.phtml
index 59d8f101fcf..c0ac8b69fce 100644
--- app/design/frontend/default/iphone/template/downloadable/sales/order/items/renderer/downloadable.phtml
+++ app/design/frontend/default/iphone/template/downloadable/sales/order/items/renderer/downloadable.phtml
@@ -59,7 +59,7 @@ $links = $this->getLinks();
         <!-- downloadable -->
         <?php if ($links): ?>
             <dl class="item-options">
-                <dt><?php echo $this->getLinksTitle() ?></dt>
+                <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
                 <?php foreach ($links->getPurchasedItems() as $link): ?>
                     <dd><?php echo $this->escapeHtml($link->getLinkTitle()); ?></dd>
                 <?php endforeach; ?>
diff --git app/design/frontend/rwd/default/template/bundle/email/order/items/creditmemo/default.phtml app/design/frontend/rwd/default/template/bundle/email/order/items/creditmemo/default.phtml
index 3953e39a00a..3151c06691f 100644
--- app/design/frontend/rwd/default/template/bundle/email/order/items/creditmemo/default.phtml
+++ app/design/frontend/rwd/default/template/bundle/email/order/items/creditmemo/default.phtml
@@ -43,7 +43,7 @@
     <?php $attributes = $this->getSelectionAttributes($_item) ?>
     <?php if ($_prevOptionId != $attributes['option_id']): ?>
     <tr>
-        <td class="bundle-item"><strong><em><?php echo $attributes['option_label'] ?></em></strong></td>
+        <td class="bundle-item"><strong><em><?php echo $this->escapeHtml($attributes['option_label']); ?></em></strong></td>
         <td class="bundle-item">&nbsp;</td>
         <td class="bundle-item">&nbsp;</td>
     </tr>
diff --git app/design/frontend/rwd/default/template/bundle/email/order/items/invoice/default.phtml app/design/frontend/rwd/default/template/bundle/email/order/items/invoice/default.phtml
index 94a4c19d555..3f2def3a3c6 100644
--- app/design/frontend/rwd/default/template/bundle/email/order/items/invoice/default.phtml
+++ app/design/frontend/rwd/default/template/bundle/email/order/items/invoice/default.phtml
@@ -44,7 +44,7 @@
     <?php $attributes = $this->getSelectionAttributes($_item) ?>
     <?php if ($_prevOptionId != $attributes['option_id']): ?>
     <tr>
-        <td class="bundle-item"><strong><em><?php echo $attributes['option_label'] ?></em></strong></td>
+        <td class="bundle-item"><strong><em><?php echo $this->escapeHtml($attributes['option_label']); ?></em></strong></td>
         <td class="bundle-item">&nbsp;</td>
         <td class="bundle-item">&nbsp;</td>
     </tr>
diff --git app/design/frontend/rwd/default/template/bundle/email/order/items/order/default.phtml app/design/frontend/rwd/default/template/bundle/email/order/items/order/default.phtml
index 32d7cd5f135..71c3093169d 100644
--- app/design/frontend/rwd/default/template/bundle/email/order/items/order/default.phtml
+++ app/design/frontend/rwd/default/template/bundle/email/order/items/order/default.phtml
@@ -44,7 +44,7 @@
     <?php $attributes = $this->getSelectionAttributes($_item) ?>
     <?php if ($_prevOptionId != $attributes['option_id']): ?>
     <tr>
-        <td class="bundle-item"><strong><em><?php echo $attributes['option_label'] ?></em></strong></td>
+        <td class="bundle-item"><strong><em><?php echo $this->escapeHtml($attributes['option_label']); ?></em></strong></td>
         <td class="bundle-item">&nbsp;</td>
         <td class="bundle-item">&nbsp;</td>
     </tr>
diff --git app/design/frontend/rwd/default/template/bundle/email/order/items/shipment/default.phtml app/design/frontend/rwd/default/template/bundle/email/order/items/shipment/default.phtml
index 6b0e520ddb3..e8284867a27 100644
--- app/design/frontend/rwd/default/template/bundle/email/order/items/shipment/default.phtml
+++ app/design/frontend/rwd/default/template/bundle/email/order/items/shipment/default.phtml
@@ -43,7 +43,7 @@
     <?php $attributes = $this->getSelectionAttributes($_item) ?>
     <?php if ($_prevOptionId != $attributes['option_id']): ?>
     <tr>
-        <td class="bundle-item"><strong><em><?php echo $attributes['option_label'] ?></em></strong></td>
+        <td class="bundle-item"><strong><em><?php echo $this->escapeHtml($attributes['option_label']); ?></em></strong></td>
         <td class="bundle-item">&nbsp;</td>
         <td class="bundle-item">&nbsp;</td>
     </tr>
diff --git app/design/frontend/rwd/default/template/bundle/sales/order/items/renderer.phtml app/design/frontend/rwd/default/template/bundle/sales/order/items/renderer.phtml
index 0498bca7562..9aa46b17c83 100644
--- app/design/frontend/rwd/default/template/bundle/sales/order/items/renderer.phtml
+++ app/design/frontend/rwd/default/template/bundle/sales/order/items/renderer.phtml
@@ -43,7 +43,7 @@
     <?php $attributes = $this->getSelectionAttributes($_item) ?>
     <?php if ($_prevOptionId != $attributes['option_id']): ?>
     <tr class="bundle label<?php if($_item->getLastRow()): ?> last<?php endif; ?>">
-        <td><div class="option-label"><?php echo $attributes['option_label'] ?></div></td>
+        <td><div class="option-label"><?php echo $this->escapeHtml($attributes['option_label']); ?></div></td>
         <td data-rwd-label="SKU" class="lin-hide">&nbsp;</td>
         <td data-rwd-label="Price" class="lin-hide">&nbsp;</td>
         <td data-rwd-label="Qty" class="lin-hide">&nbsp;</td>
diff --git app/design/frontend/rwd/default/template/downloadable/email/order/items/creditmemo/downloadable.phtml app/design/frontend/rwd/default/template/downloadable/email/order/items/creditmemo/downloadable.phtml
index 8787b7dfac2..498dd9b6e90 100644
--- app/design/frontend/rwd/default/template/downloadable/email/order/items/creditmemo/downloadable.phtml
+++ app/design/frontend/rwd/default/template/downloadable/email/order/items/creditmemo/downloadable.phtml
@@ -40,7 +40,7 @@
         <?php endif; ?>
         <?php if ($links = $this->getLinks()->getPurchasedItems()): ?>
             <dl style="margin:0; padding:0;">
-                <dt><strong><em><?php echo $this->getLinksTitle() ?></em></strong></dt>
+                <dt><strong><em><?php echo $this->escapeHtml($this->getLinksTitle()); ?></em></strong></dt>
                 <?php foreach ($links as $link): ?>
                     <dd style="margin:0; padding:0 0 0 9px;"><?php echo $this->escapeHtml($link->getLinkTitle()); ?></dd>
                 <?php endforeach; ?>
diff --git app/design/frontend/rwd/default/template/downloadable/email/order/items/invoice/downloadable.phtml app/design/frontend/rwd/default/template/downloadable/email/order/items/invoice/downloadable.phtml
index 8b7c2d2cb88..ffe955dc368 100644
--- app/design/frontend/rwd/default/template/downloadable/email/order/items/invoice/downloadable.phtml
+++ app/design/frontend/rwd/default/template/downloadable/email/order/items/invoice/downloadable.phtml
@@ -43,7 +43,7 @@
         <?php endif; ?>
         <?php if ($links = $this->getLinks()->getPurchasedItems()): ?>
             <dl style="margin:0; padding:0;">
-                <dt><strong><em><?php echo $this->getLinksTitle() ?></em></strong></dt>
+                <dt><strong><em><?php echo $this->escapeHtml($this->getLinksTitle()); ?></em></strong></dt>
                 <?php foreach ($links as $link): ?>
                     <dd style="margin:0; padding:0 0 0 9px;">
                         <?php echo $this->escapeHtml($link->getLinkTitle()); ?>&nbsp;
diff --git app/design/frontend/rwd/default/template/downloadable/email/order/items/order/downloadable.phtml app/design/frontend/rwd/default/template/downloadable/email/order/items/order/downloadable.phtml
index 361fb37192f..c3976e81632 100644
--- app/design/frontend/rwd/default/template/downloadable/email/order/items/order/downloadable.phtml
+++ app/design/frontend/rwd/default/template/downloadable/email/order/items/order/downloadable.phtml
@@ -40,7 +40,7 @@
         <?php endif; ?>
         <?php if ($links = $this->getLinks()->getPurchasedItems()): ?>
             <dl style="margin:0; padding:0;">
-                <dt><strong><em><?php echo $this->getLinksTitle() ?></em></strong></dt>
+                <dt><strong><em><?php echo $this->escapeHtml($this->getLinksTitle()); ?></em></strong></dt>
                 <?php foreach ($links as $link): ?>
                     <dd style="margin:0; padding:0 0 0 9px;">
                         <?php echo $this->escapeHtml($link->getLinkTitle()); ?>&nbsp;
diff --git app/locale/en_US/Mage_Adminhtml.csv app/locale/en_US/Mage_Adminhtml.csv
index 982db986b37..9df75327823 100644
--- app/locale/en_US/Mage_Adminhtml.csv
+++ app/locale/en_US/Mage_Adminhtml.csv
@@ -1255,6 +1255,7 @@
 "Yes (only price with tax)","Yes (only price with tax)"
 "You cannot delete your own account.","You cannot delete your own account."
 "You did not sign in correctly or your account is temporarily disabled.","You did not sign in correctly or your account is temporarily disabled."
+"Disallowed block name for frontend.","Disallowed block name for frontend."
 "You have %s unread message(s).","You have %s unread message(s)."
 "You have %s unread message(s). <a href=""%s"">Go to messages inbox</a>.","You have %s unread message(s). <a href=""%s"">Go to messages inbox</a>."
 "You have %s, %s and %s unread messages. <a href=""%s"">Go to messages inbox</a>.","You have %s, %s and %s unread messages. <a href=""%s"">Go to messages inbox</a>."
diff --git app/locale/en_US/Mage_Customer.csv app/locale/en_US/Mage_Customer.csv
index c9eabc84638..ca0ed18db27 100644
--- app/locale/en_US/Mage_Customer.csv
+++ app/locale/en_US/Mage_Customer.csv
@@ -193,6 +193,7 @@
 "Invalid email address.","Invalid email address."
 "Invalid login or password.","Invalid login or password."
 "Invalid password reset token.","Invalid password reset token."
+"Invalid password reset customer Id.","Invalid password reset customer Id."
 "Invalid shipping address for (%s)","Invalid shipping address for (%s)"
 "Invalid store specified, skipping the record.","Invalid store specified, skipping the record."
 "Invalid website, skipping the record, line: %s","Invalid website, skipping the record, line: %s"
diff --git app/locale/en_US/template/email/account_password_reset_confirmation.html app/locale/en_US/template/email/account_password_reset_confirmation.html
index 6ff64ea2fa5..2f5b446700a 100644
--- app/locale/en_US/template/email/account_password_reset_confirmation.html
+++ app/locale/en_US/template/email/account_password_reset_confirmation.html
@@ -22,7 +22,7 @@
             <table cellspacing="0" cellpadding="0" class="action-button" >
                 <tr>
                     <td>
-                        <a href="{{store url="customer/account/resetpassword/" _query_id=$customer.id _query_token=$customer.rp_token}}"><span>Reset Password</span></a>
+                        <a href="{{store url="customer/account/resetpassword/" _query_id=$customer.rp_customer_id _query_token=$customer.rp_token}}"><span>Reset Password</span></a>
                     </td>
                 </tr>
             </table>
diff --git app/locale/en_US/template/email/admin_new_user_notification.html app/locale/en_US/template/email/admin_new_user_notification.html
new file mode 100644
index 00000000000..87c722e68e5
--- /dev/null
+++ app/locale/en_US/template/email/admin_new_user_notification.html
@@ -0,0 +1,25 @@
+<!--@subject New Admin Account {{var user.name}} Created. @-->
+<!--@vars
+{"store url=\"\"":"Store Url",
+"var logo_url":"Email Logo Image Url",
+"var logo_alt":"Email Logo Image Alt",
+"htmlescape var=$user.name":"New Admin Name",
+@-->
+
+<!--@styles
+@-->
+
+{{template config_path="design/email/header"}}
+{{inlinecss file="email-inline.css"}}
+
+<table cellpadding="0" cellspacing="0" border="0">
+    <tr>
+        <td class="action-content">
+            <h1>New admin account notification.</h1>
+            <p>A new admin account was created for <b>{{htmlescape var=$user.name}}</b> using email: {{htmlescape var=$user.email}}.</p>
+            <p>If you have not requested this action, please review the list of administrator accounts in <a href="{{store url=""}}">your store</a>.</p>
+        </td>
+    </tr>
+</table>
+
+{{template config_path="design/email/footer"}}
diff --git downloader/Maged/Controller.php downloader/Maged/Controller.php
index cd2b94b66e3..0d6d645a8ba 100644
--- downloader/Maged/Controller.php
+++ downloader/Maged/Controller.php
@@ -813,6 +813,18 @@ final class Maged_Controller
      */
     public function dispatch()
     {
+        $baseUrl = Mage::getBaseUrl(
+            Mage_Core_Model_Store::URL_TYPE_LINK, Mage::getSingleton('adminhtml/url')->getSecure()
+        );
+        if (strpos($baseUrl, 'https') === 0) {
+            $request = Mage::app()->getRequest();
+            if (!$request->isSecure()) {
+                Mage::app()->getFrontController()->getResponse()
+                    ->setRedirect(rtrim($baseUrl, '/') . $request->getRequestUri(), 301)->sendResponse();
+                exit;
+            }
+        }
+
         header('Content-type: text/html; charset=UTF-8');
 
         $this->_addDomainPolicyHeader();
diff --git skin/adminhtml/default/enterprise/images/placeholder/thumbnail.jpg skin/adminhtml/default/enterprise/images/placeholder/thumbnail.jpg
new file mode 100644
index 0000000000000000000000000000000000000000..4537aa80b31904bd348d03240a3aad0fc1e531b6
GIT binary patch
literal 1110
zcmex=<NpH&0WUXCHwH#VMg|WcWcYuZ!I^=Xi3x;&fCY$HIapa)SXjB(+1WUFxOjND
zxwyG``Gf>``2_j6xdp@o1cgOJMMZh|#U;c<B!omnML>oyG6VInuyV4pa*FVB^NNrR
z{vTiv<Y4e-NMUAFVqg+vWEN!ne}qAvfq{_~=vt72p@5MI=teen4o)s^pn|Oe3`~s7
z%uFoIAXfub*8=4kSOi&x6b&8OgaZ@Vl?p|S8YeE~P<GmQP&DY`2NmO_q9#r*F>wh=
zDOELf4NWZ*Q!{f5ODks=S2uSLPp{yR(6I1`$f)F$)U@=B%&g*)(z5c3%Btp;*0%PJ
z&aO$5r%atTea6gLixw|gx@`H1m8&*w-m-Pu_8mKS9XfpE=&|D`PM*4S`O4L6*Kgds
z_3+W-Cr_U}fAR9w$4{TXeEs(Q$Io9Ne=#yJL%ap|8JfQYf&OA*VPR%r2l<PUsT_!z
z1zA`X4cUYo1KAS`g_VpNIYgW$F5GyKQ`tD^gJ@FGMJ_QFlZUDwL0$v<j5v=qk>xYE
z#}NLy#lXYN2#h>tK?Zw<zYdGKG#Eg5!2~vcriHU!Dn5R1zF<|*xzBP{^(6spO<t4I
zvzfbUQ$;g6Y!<%BI%B?<W&ZaI3%I8QF-fGzbVV^}Eb4+|&I4xyW_?`p&@S}r`|#QC
z<}Xb<v~a0|n_C7$8~cn82K(=sR!OI{FF0K_D>6mEeUilshE*Hy*j(qF+<M;8K|GSV
z$Kb@O;z-ex{S#l_Te>G{;>zIWU6by;Kcgs7b8k_Dmb><W3X897>u;Y^4=QZ3>gxLG
zb~LAWPTFMu-|K$_u<p`W)W8MBg8N?n3M<|J>&3sVi|&{F)wa6-x1>IbVQclj<sU`E
z?*FZ-&AR&j*Zd=)(e+<neqF$Ae*e|<zpvKk{@ZJ}|I(WH`c?7YSMA;Y>&vhI3|<Ty
zYyYjRzqjm0?e#yJ*TD*N+wayNYS6vtD#8#5#Vsj<Az^nP&NVXH`AX}r2xHv$zy6Q3
z*6s(IarJgb&&9Xw?3T|~@LurZ=5sv9%MiWqKSRj=_o3DKK>Pnqc|CigQNw};zM{-)
z+urYu`Lm$7*+J-@wv|SJ=iOV=t}%1XJwEwH$d>>{R}oa~TXD_xFi%&h2qRC}O2PB@
R?3Qo!MRFC;b&UUS0s!NOuyz0d

literal 0
HcmV?d00001

