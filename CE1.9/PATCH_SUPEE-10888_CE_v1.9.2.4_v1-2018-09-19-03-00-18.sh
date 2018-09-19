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


SUPEE-10888_CE_v1.9.2.4 | CE_1.9.2.4 | v1 | 145cee001262628c9fe50c99816f0a54ee37a5ea | Fri Aug 31 10:50:32 2018 +0300 | ce-1.9.2.4-dev

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Admin/Model/User.php app/code/core/Mage/Admin/Model/User.php
index eea1509b035..c1bf0b14246 100644
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
index ccc27b9a661..a71cf93549d 100644
--- app/code/core/Mage/Admin/etc/config.xml
+++ app/code/core/Mage/Admin/etc/config.xml
@@ -84,6 +84,7 @@
         <admin>
             <emails>
                 <forgot_email_template>admin_emails_forgot_email_template</forgot_email_template>
+                <admin_notification_email_template>admin_emails_admin_notification_email_template</admin_notification_email_template>
                 <forgot_email_identity>general</forgot_email_identity>
                 <password_reset_link_expiration_period>1</password_reset_link_expiration_period>
             </emails>
diff --git app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php
index 1ccfc4a719b..d1ef0d97333 100644
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
index b06911a5434..a23ad09a172 100644
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
index 165a94e8a8a..5554169a681 100644
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
index 2f9f1b2970b..9a4238be061 100644
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
index 0228a4ddfda..c1d0f0b3208 100644
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
index a088550e5d0..700dd01b2eb 100644
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
index a2a9f0fd69c..45919c91016 100644
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
index a13218e1fef..e3b82fbfa92 100644
--- app/code/core/Mage/Checkout/Model/Type/Onepage.php
+++ app/code/core/Mage/Checkout/Model/Type/Onepage.php
@@ -731,6 +731,7 @@ class Mage_Checkout_Model_Type_Onepage
         $customer->setPasswordCreatedAt($passwordCreatedTime);
         $quote->setCustomer($customer)
             ->setCustomerId(true);
+        $quote->setPasswordHash('');
     }
 
     /**
diff --git app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
index 5034f8550d7..cee4581b81f 100644
--- app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
+++ app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
@@ -282,11 +282,13 @@ class Mage_Cms_Model_Wysiwyg_Images_Storage extends Varien_Object
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
@@ -294,8 +296,9 @@ class Mage_Cms_Model_Wysiwyg_Images_Storage extends Varien_Object
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
index 96bfa08b749..54d14e804bb 100644
--- app/code/core/Mage/Core/etc/config.xml
+++ app/code/core/Mage/Core/etc/config.xml
@@ -463,6 +463,11 @@
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
index e2f40b732c7..5c18259df03 100644
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
index b42ae48f4ea..bf9419fb19d 100644
--- app/code/core/Mage/Customer/Helper/Data.php
+++ app/code/core/Mage/Customer/Helper/Data.php
@@ -452,6 +452,17 @@ class Mage_Customer_Helper_Data extends Mage_Core_Helper_Abstract
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
index 797f95e373f..3cff579080e 100644
--- app/code/core/Mage/Customer/Model/Customer.php
+++ app/code/core/Mage/Customer/Model/Customer.php
@@ -60,6 +60,7 @@ class Mage_Customer_Model_Customer extends Mage_Core_Model_Abstract
     const EXCEPTION_INVALID_EMAIL_OR_PASSWORD = 2;
     const EXCEPTION_EMAIL_EXISTS              = 3;
     const EXCEPTION_INVALID_RESET_PASSWORD_LINK_TOKEN = 4;
+    const EXCEPTION_INVALID_RESET_PASSWORD_LINK_CUSTOMER_ID = 5;
     /**#@-*/
 
     /**#@+
@@ -1325,6 +1326,28 @@ class Mage_Customer_Model_Customer extends Mage_Core_Model_Abstract
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
index 45887b586b5..00c7e01d1af 100644
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
index e4a8d76df5a..651566f4293 100644
--- app/code/core/Mage/Customer/controllers/AccountController.php
+++ app/code/core/Mage/Customer/controllers/AccountController.php
@@ -735,9 +735,13 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
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
@@ -786,7 +790,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
     public function resetPasswordAction()
     {
         try {
-            $customerId = (int)$this->getRequest()->getQuery("id");
+            $customerId = (int)$this->getCustomerId();
             $resetPasswordLinkToken = (string)$this->getRequest()->getQuery('token');
 
             $this->_validateResetPasswordLinkToken($customerId, $resetPasswordLinkToken);
@@ -846,6 +850,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             $customer->setRpTokenCreatedAt(null);
             $customer->cleanPasswordsValidationData();
             $customer->setPasswordCreatedAt(time());
+            $customer->setRpCustomerId(null);
             $customer->save();
 
             $this->_getSession()->unsetData(self::TOKEN_SESSION_NAME);
@@ -860,6 +865,25 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
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
index d3d6333833c..a6f3a0cf608 100644
--- app/code/core/Mage/Customer/etc/config.xml
+++ app/code/core/Mage/Customer/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Mage_Customer>
-            <version>1.6.2.0.4.1.2</version>
+            <version>1.6.2.0.4.1.3</version>
         </Mage_Customer>
     </modules>
     <admin>
diff --git app/code/core/Mage/Customer/sql/customer_setup/upgrade-1.6.2.0.4.1.2-1.6.2.0.4.1.3.php app/code/core/Mage/Customer/sql/customer_setup/upgrade-1.6.2.0.4.1.2-1.6.2.0.4.1.3.php
new file mode 100644
index 00000000000..867227ea4bb
--- /dev/null
+++ app/code/core/Mage/Customer/sql/customer_setup/upgrade-1.6.2.0.4.1.2-1.6.2.0.4.1.3.php
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
index d1297ee8e11..5a73e19903f 100644
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
index d511d24fc37..e4b4e8d67e7 100644
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
index 054f72c9c8e..8e39d09968f 100644
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
index 2bf48ff8cfa..8575424d2af 100644
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
index 1793a35d29c..d83d79639e5 100644
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
index 83d9b5ab6ab..0d35eaa1cc8 100644
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
index ad460eb7207..ecc97357383 100644
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
index ae85af96e74..db832044b86 100644
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
index 2a9150634fe..7cbe1bf00d9 100644
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
index 707785dc182..b32a98460c0 100644
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
index 22aa85b5242..386ede15cd6 100644
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
index f3d0e462582..af7978de8c2 100644
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
index e1a81248339..27b8f6f5988 100644
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
index 5cce39ec704..5659fcb0365 100644
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
index 4fefd0e86d1..842032f5aac 100644
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
index 6891b4072ae..c2749fc1d97 100644
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
index 4aea5f5efa9..3a2526f6cea 100644
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
index 2333cec80e7..b713968d6d3 100644
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
index 2d8d0b66d83..25033b8bd85 100644
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
index 482d8ff2ab6..9b4479de182 100644
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
index b2ea33d0d7a..08990145693 100644
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
index cfc1b34dc56..515f3773cc9 100644
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
index e2df97fba69..f37d16c6b6c 100644
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
index ed048e14861..3fcd789276f 100644
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
index e77e89e0c1f..67137c0ca22 100644
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
index 33fc14ecf00..93392bb9ff7 100644
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
index fb21ab46207..06c2a9a7c0d 100644
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
index d00e7f9b44c..052632e66f1 100644
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
index 08a659b4d29..9759e97da0b 100644
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
index a8bb1a61622..e02bf5b888a 100644
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
index 830cb6dcaa8..1580c05c420 100644
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
index dcae03b6205..43be4af0bc1 100644
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
index c5e71558c36..0d21b8d96db 100644
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
index 91591e3272f..4f5f6809361 100644
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
index bd646c1b5e2..6f934829b70 100644
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
index fdaeea1e421..ecce603e69d 100644
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
index 4b9aa19e114..479b03476df 100644
--- app/locale/en_US/Mage_Adminhtml.csv
+++ app/locale/en_US/Mage_Adminhtml.csv
@@ -1249,6 +1249,7 @@
 "Yes (302 Found)","Yes (302 Found)"
 "Yes (only price with tax)","Yes (only price with tax)"
 "You cannot delete your own account.","You cannot delete your own account."
+"Disallowed block name for frontend.","Disallowed block name for frontend."
 "You have %s unread message(s).","You have %s unread message(s)."
 "You have %s unread message(s). <a href=""%s"">Go to messages inbox</a>.","You have %s unread message(s). <a href=""%s"">Go to messages inbox</a>."
 "You have %s, %s and %s unread messages. <a href=""%s"">Go to messages inbox</a>.","You have %s, %s and %s unread messages. <a href=""%s"">Go to messages inbox</a>."
diff --git app/locale/en_US/Mage_Customer.csv app/locale/en_US/Mage_Customer.csv
index 3f92ea4c600..fa95adbe248 100644
--- app/locale/en_US/Mage_Customer.csv
+++ app/locale/en_US/Mage_Customer.csv
@@ -185,6 +185,7 @@
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
index 0f88142dba9..2670a63ae36 100644
--- downloader/Maged/Controller.php
+++ downloader/Maged/Controller.php
@@ -809,6 +809,18 @@ final class Maged_Controller
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
index 00000000000..4537aa80b31
--- /dev/null
+++ skin/adminhtml/default/enterprise/images/placeholder/thumbnail.jpg
@@ -0,0 +1,11 @@
+ˇÿˇ‡ JFIF  H H  ˇ€ C 
+
+
+ˇ€ C		ˇ¿  K d" ˇƒ           	
+ˇƒ µ   } !1AQa"q2Åë°#B±¡R—$3brÇ	
+%&'()*456789:CDEFGHIJSTUVWXYZcdefghijstuvwxyzÉÑÖÜáàâäíìîïñóòôö¢£§•¶ß®©™≤≥¥µ∂∑∏π∫¬√ƒ≈∆«»… “”‘’÷◊ÿŸ⁄·‚„‰ÂÊÁËÈÍÒÚÛÙıˆ˜¯˘˙ˇƒ        	
+ˇƒ µ  w !1AQaq"2ÅBë°±¡	#3Rbr—
+$4·%Ò&'()*56789:CDEFGHIJSTUVWXYZcdefghijstuvwxyzÇÉÑÖÜáàâäíìîïñóòôö¢£§•¶ß®©™≤≥¥µ∂∑∏π∫¬√ƒ≈∆«»… “”‘’÷◊ÿŸ⁄‚„‰ÂÊÁËÈÍÚÛÙıˆ˜¯˘˙ˇ⁄   ? ˝@¢ä( ¢ä( †êO°öÈ!„Ô7†™RŒÛztPÇJígkä}ehà<°ÏjÃ7Ωü˜–†îRdäZ (¢ä (¢ä (¢ä 	¿ÕPöÒ§·>UıÔWõÓü•f¬°•@FFh Üò0øﬁ5zdá†ÀzöYdGí8Ë ™±‹<◊	ìÖœA@Yå0»™sY…èëÈﬁ•ºbë©SÉ∫íﬁÔÃ!|ﬁ¢Ä*G+¿x8ıØ€Œ'RqÇ:ää˘F≈lsúfìO˚Ø¯P∫(¢Ä
+(¢Ä
+(¢ÄæÈ˙Vuø˙Ë˛µ¢ﬂt˝+:ﬂ˝tZ µ{˛ßÒVﬂ˝z}j’Ô˙üƒU[ıÈı†7ﬂÍó˝ÍØm˛Ω>ø“¨_™_˜™Ω∑˙Ù˙ˇ J ±}˛©ﬁ¶ÿ}◊¸)◊ﬂÍó˝Ímá›¬Ä-—E QE QE ÑdTV›·ù22πÍ*˝^˜˝O‚*≠ø˙Ù˙’€àå—Ì9Ê®–JAŒ [æˇ TøÔU{oıÈı˛îÎõë2Ä†Äri÷∂ÔΩ\¸†sÉ@ﬁ+:(PI›⁄ñ÷
+ù«ìÿTÙPEPEPEPEPMx÷E√äuV©œﬁ>ßµME QE QE QEˇŸ
\ No newline at end of file
