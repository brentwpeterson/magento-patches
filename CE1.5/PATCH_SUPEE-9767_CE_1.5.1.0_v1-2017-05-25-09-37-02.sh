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


PATCH_SUPEE-9767_CE_1.5.1.0_v1.sh | CE_1.5.1.0 | v1 | 226caf7 | Mon Feb 20 17:33:39 2017 +0200 | 2321b14

__PATCHFILE_FOLLOWS__
diff --git app/Mage.php app/Mage.php
index 7fb3721..e8683d8 100644
--- app/Mage.php
+++ app/Mage.php
@@ -343,6 +343,7 @@ public static function getStoreConfigFlag($path, $store = null)
      * Get base URL path by type
      *
      * @param string $type
+     * @param null|bool $secure
      * @return string
      */
     public static function getBaseUrl($type = Mage_Core_Model_Store::URL_TYPE_LINK, $secure = null)
diff --git app/code/core/Mage/Admin/Model/Session.php app/code/core/Mage/Admin/Model/Session.php
index d3b70ee..470211f 100644
--- app/code/core/Mage/Admin/Model/Session.php
+++ app/code/core/Mage/Admin/Model/Session.php
@@ -139,7 +139,11 @@ public function login($username, $password, $request = null)
             }
         }
         catch (Mage_Core_Exception $e) {
-            Mage::dispatchEvent('admin_session_user_login_failed', array('user_name'=>$username, 'exception' => $e));
+            $e->setMessage(
+                Mage::helper('adminhtml')->__('You did not sign in correctly or your account is temporarily disabled.')
+            );
+            Mage::dispatchEvent('admin_session_user_login_failed',
+                    array('user_name' => $username, 'exception' => $e));
             if ($request && !$request->getParam('messageSent')) {
                 Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
                 $request->setParam('messageSent', true);
@@ -155,7 +159,7 @@ public function login($username, $password, $request = null)
      * @param  Mage_Admin_Model_User $user
      * @return Mage_Admin_Model_Session
      */
-    public function refreshAcl($user=null)
+    public function refreshAcl($user = null)
     {
         if (is_null($user)) {
             $user = $this->getUser();
@@ -183,14 +187,14 @@ public function refreshAcl($user=null)
      * @param   string $privilege
      * @return  boolean
      */
-    public function isAllowed($resource, $privilege=null)
+    public function isAllowed($resource, $privilege = null)
     {
         $user = $this->getUser();
         $acl = $this->getAcl();
 
         if ($user && $acl) {
             if (!preg_match('/^admin/', $resource)) {
-                $resource = 'admin/'.$resource;
+                $resource = 'admin/' . $resource;
             }
 
             try {
diff --git app/code/core/Mage/Adminhtml/Block/Checkout/Formkey.php app/code/core/Mage/Adminhtml/Block/Checkout/Formkey.php
new file mode 100644
index 0000000..7f76286
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Block/Checkout/Formkey.php
@@ -0,0 +1,52 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @copyright   Copyright (c) 2010 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Class Mage_Adminhtml_Block_Checkout_Formkey
+ */
+class Mage_Adminhtml_Block_Checkout_Formkey extends Mage_Adminhtml_Block_Template
+{
+    /**
+     * Check form key validation on checkout.
+     * If disabled, show notice.
+     *
+     * @return boolean
+     */
+    public function canShow()
+    {
+        return !Mage::getStoreConfigFlag('admin/security/validate_formkey_checkout');
+    }
+
+    /**
+     * Get url for edit Advanced -> Admin section
+     *
+     * @return string
+     */
+    public function getSecurityAdminUrl()
+    {
+        return Mage::helper("adminhtml")->getUrl('adminhtml/system_config/edit/section/admin');
+    }
+}
diff --git app/code/core/Mage/Adminhtml/Block/Notification/Symlink.php app/code/core/Mage/Adminhtml/Block/Notification/Symlink.php
new file mode 100644
index 0000000..edc6329
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Block/Notification/Symlink.php
@@ -0,0 +1,36 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @copyright   Copyright (c) 2010 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+class Mage_Adminhtml_Block_Notification_Symlink extends Mage_Adminhtml_Block_Template
+{
+    /**
+     * @return bool
+     */
+    public function isSymlinkEnabled()
+    {
+        return Mage::getStoreConfigFlag(self::XML_PATH_TEMPLATE_ALLOW_SYMLINK);
+    }
+}
diff --git app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Date.php app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Date.php
index 6a5c262..bc46d5c 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Date.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Date.php
@@ -137,11 +137,11 @@ public function setValue($value)
         if (isset($value['locale'])) {
             if (!empty($value['from'])) {
                 $value['orig_from'] = $value['from'];
-                $value['from'] = $this->_convertDate($value['from'], $value['locale']);
+                $value['from'] = $this->_convertDate($this->stripTags($value['from']), $value['locale']);
             }
             if (!empty($value['to'])) {
                 $value['orig_to'] = $value['to'];
-                $value['to'] = $this->_convertDate($value['to'], $value['locale']);
+                $value['to'] = $this->_convertDate($this->stripTags($value['to']), $value['locale']);
             }
         }
         if (empty($value['from']) && empty($value['to'])) {
diff --git app/code/core/Mage/Adminhtml/Helper/Data.php app/code/core/Mage/Adminhtml/Helper/Data.php
index 43d64fa..840e475 100644
--- app/code/core/Mage/Adminhtml/Helper/Data.php
+++ app/code/core/Mage/Adminhtml/Helper/Data.php
@@ -33,6 +33,10 @@
  */
 class Mage_Adminhtml_Helper_Data extends Mage_Core_Helper_Abstract
 {
+    const XML_PATH_ADMINHTML_ROUTER_FRONTNAME   = 'admin/routers/adminhtml/args/frontName';
+    const XML_PATH_USE_CUSTOM_ADMIN_URL         = 'default/admin/url/use_custom';
+    const XML_PATH_USE_CUSTOM_ADMIN_PATH        = 'default/admin/url/use_custom_path';
+    const XML_PATH_CUSTOM_ADMIN_PATH            = 'default/admin/url/custom_path';
 
     protected $_pageHelpUrl;
 
diff --git app/code/core/Mage/Adminhtml/Model/Config/Data.php app/code/core/Mage/Adminhtml/Model/Config/Data.php
index da7aa83..dc7d8aa 100644
--- app/code/core/Mage/Adminhtml/Model/Config/Data.php
+++ app/code/core/Mage/Adminhtml/Model/Config/Data.php
@@ -153,6 +153,9 @@ public function save()
                 if (is_object($fieldConfig)) {
                     $configPath = (string)$fieldConfig->config_path;
                     if (!empty($configPath) && strrpos($configPath, '/') > 0) {
+                        if (!Mage::getSingleton('admin/session')->isAllowed($configPath)) {
+                            Mage::throwException('Access denied.');
+                        }
                         // Extend old data with specified section group
                         $groupPath = substr($configPath, 0, strrpos($configPath, '/'));
                         if (!isset($oldConfigAdditionalGroups[$groupPath])) {
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/Product/GalleryController.php app/code/core/Mage/Adminhtml/controllers/Catalog/Product/GalleryController.php
index 94dc953..da489de 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/Product/GalleryController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/Product/GalleryController.php
@@ -42,6 +42,11 @@ public function uploadAction()
                 Mage::helper('catalog/image'), 'validateUploadFile');
             $uploader->setAllowRenameFiles(true);
             $uploader->setFilesDispersion(true);
+            $uploader->addValidateCallback(
+                Mage_Core_Model_File_Validator_Image::NAME,
+                Mage::getModel('core/file_validator_image'),
+                'validate'
+            );
             $result = $uploader->save(
                 Mage::getSingleton('catalog/product_media_config')->getBaseTmpMediaPath()
             );
diff --git app/code/core/Mage/Checkout/controllers/MultishippingController.php app/code/core/Mage/Checkout/controllers/MultishippingController.php
index e6afbbc..dee64af 100644
--- app/code/core/Mage/Checkout/controllers/MultishippingController.php
+++ app/code/core/Mage/Checkout/controllers/MultishippingController.php
@@ -227,6 +227,12 @@ public function addressesPostAction()
             $this->_redirect('*/multishipping_address/newShipping');
             return;
         }
+
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            $this->_redirect('*/*/addresses');
+            return;
+        }
+
         try {
             if ($this->getRequest()->getParam('continue', false)) {
                 $this->_getCheckout()->setCollectRatesFlag(true);
@@ -333,6 +339,11 @@ public function backToShippingAction()
 
     public function shippingPostAction()
     {
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            $this->_redirect('*/*/shipping');
+            return;
+        }
+
         $shippingMethods = $this->getRequest()->getPost('shipping_method');
         try {
             Mage::dispatchEvent(
@@ -436,6 +447,11 @@ public function overviewAction()
             return $this;
         }
 
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            $this->_redirect('*/*/billing');
+            return;
+        }
+
         $this->_getState()->setActiveStep(Mage_Checkout_Model_Type_Multishipping_State::STEP_OVERVIEW);
 
         try {
diff --git app/code/core/Mage/Checkout/controllers/OnepageController.php app/code/core/Mage/Checkout/controllers/OnepageController.php
index 43f131e..ae95ec4 100644
--- app/code/core/Mage/Checkout/controllers/OnepageController.php
+++ app/code/core/Mage/Checkout/controllers/OnepageController.php
@@ -310,6 +310,11 @@ public function saveMethodAction()
         if ($this->_expireAjax()) {
             return;
         }
+
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            return;
+        }
+
         if ($this->getRequest()->isPost()) {
             $method = $this->getRequest()->getPost('method');
             $result = $this->getOnepage()->saveCheckoutMethod($method);
@@ -325,6 +330,11 @@ public function saveBillingAction()
         if ($this->_expireAjax()) {
             return;
         }
+
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            return;
+        }
+
         if ($this->getRequest()->isPost()) {
 //            $postData = $this->getRequest()->getPost('billing', array());
 //            $data = $this->_filterPostData($postData);
@@ -370,6 +380,11 @@ public function saveShippingAction()
         if ($this->_expireAjax()) {
             return;
         }
+
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            return;
+        }
+
         if ($this->getRequest()->isPost()) {
             $data = $this->getRequest()->getPost('shipping', array());
             $customerAddressId = $this->getRequest()->getPost('shipping_address_id', false);
@@ -394,6 +409,11 @@ public function saveShippingMethodAction()
         if ($this->_expireAjax()) {
             return;
         }
+
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            return;
+        }
+
         if ($this->getRequest()->isPost()) {
             $data = $this->getRequest()->getPost('shipping_method', '');
             $result = $this->getOnepage()->saveShippingMethod($data);
@@ -426,6 +446,11 @@ public function savePaymentAction()
         if ($this->_expireAjax()) {
             return;
         }
+
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            return;
+        }
+
         try {
             if (!$this->getRequest()->isPost()) {
                 $this->_ajaxRedirectResponse();
diff --git app/code/core/Mage/Checkout/etc/system.xml app/code/core/Mage/Checkout/etc/system.xml
index 73fb00b..9902a97 100644
--- app/code/core/Mage/Checkout/etc/system.xml
+++ app/code/core/Mage/Checkout/etc/system.xml
@@ -222,5 +222,23 @@
                 </payment_failed>
             </groups>
         </checkout>
+        <admin>
+            <groups>
+                <security>
+                    <fields>
+                        <validate_formkey_checkout translate="label">
+                            <label>Enable Form Key Validation On Checkout</label>
+                            <frontend_type>select</frontend_type>
+                            <source_model>adminhtml/system_config_source_yesno</source_model>
+                            <sort_order>4</sort_order>
+                            <comment><![CDATA[<strong style="color:red">Important!</strong> Enabling this option means
+                            that your custom templates used in checkout process contain form_key output.
+                            Otherwise checkout may not work.]]></comment>
+                            <show_in_default>1</show_in_default>
+                        </validate_formkey_checkout>
+                    </fields>
+                </security>
+            </groups>
+        </admin>
     </sections>
 </config>
diff --git app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
index ae46446..471179e 100644
--- app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
+++ app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
@@ -279,6 +279,11 @@ public function uploadFile($targetPath, $type = null)
         }
         $uploader->setAllowRenameFiles(true);
         $uploader->setFilesDispersion(false);
+        $uploader->addValidateCallback(
+            Mage_Core_Model_File_Validator_Image::NAME,
+            Mage::getModel('core/file_validator_image'),
+            'validate'
+        );
         $result = $uploader->save($targetPath);
 
         if (!$result) {
diff --git app/code/core/Mage/Core/Controller/Front/Action.php app/code/core/Mage/Core/Controller/Front/Action.php
index 90d182f..fcf628b 100644
--- app/code/core/Mage/Core/Controller/Front/Action.php
+++ app/code/core/Mage/Core/Controller/Front/Action.php
@@ -34,6 +34,16 @@
 class Mage_Core_Controller_Front_Action extends Mage_Core_Controller_Varien_Action
 {
     /**
+     * Session namespace to refer in other places
+     */
+    const SESSION_NAMESPACE = 'frontend';
+
+    /**
+     * Add secret key to url config path
+     */
+    const XML_CSRF_USE_FLAG_CONFIG_PATH   = 'system/csrf/use_form_key';
+
+    /**
      * Currently used area
      *
      * @var string
@@ -45,10 +55,10 @@ class Mage_Core_Controller_Front_Action extends Mage_Core_Controller_Varien_Acti
      *
      * @var string
      */
-    protected $_sessionNamespace = 'frontend';
+    protected $_sessionNamespace = self::SESSION_NAMESPACE;
 
     /**
-     * Predispatch: shoud set layout area
+     * Predispatch: should set layout area
      *
      * @return Mage_Core_Controller_Front_Action
      */
@@ -86,4 +96,96 @@ public function __()
         array_unshift($args, $expr);
         return Mage::app()->getTranslator()->translate($args);
     }
+
+    /**
+     * Declare headers and content file in response for file download
+     *
+     * @param string $fileName
+     * @param string|array $content set to null to avoid starting output, $contentLength should be set explicitly in
+     *                              that case
+     * @param string $contentType
+     * @param int $contentLength    explicit content length, if strlen($content) isn't applicable
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    protected function _prepareDownloadResponse($fileName, $content, $contentType = 'application/octet-stream',
+        $contentLength = null
+    ) {
+        $session = Mage::getSingleton('admin/session');
+        if ($session->isFirstPageAfterLogin()) {
+            $this->_redirect($session->getUser()->getStartupPageUrl());
+            return $this;
+        }
+
+        $isFile = false;
+        $file   = null;
+        if (is_array($content)) {
+            if (!isset($content['type']) || !isset($content['value'])) {
+                return $this;
+            }
+            if ($content['type'] == 'filename') {
+                $isFile         = true;
+                $file           = $content['value'];
+                $contentLength  = filesize($file);
+            }
+        }
+
+        $this->getResponse()
+            ->setHttpResponseCode(200)
+            ->setHeader('Pragma', 'public', true)
+            ->setHeader('Cache-Control', 'must-revalidate, post-check=0, pre-check=0', true)
+            ->setHeader('Content-type', $contentType, true)
+            ->setHeader('Content-Length', is_null($contentLength) ? strlen($content) : $contentLength)
+            ->setHeader('Content-Disposition', 'attachment; filename="'.$fileName.'"')
+            ->setHeader('Last-Modified', date('r'));
+
+        if (!is_null($content)) {
+            if ($isFile) {
+                $this->getResponse()->clearBody();
+                $this->getResponse()->sendHeaders();
+
+                $ioAdapter = new Varien_Io_File();
+                if (!$ioAdapter->fileExists($file)) {
+                    Mage::throwException(Mage::helper('core')->__('File not found'));
+                }
+                $ioAdapter->open(array('path' => $ioAdapter->dirname($file)));
+                $ioAdapter->streamOpen($file, 'r');
+                while ($buffer = $ioAdapter->streamRead()) {
+                    print $buffer;
+                }
+                $ioAdapter->streamClose();
+                if (!empty($content['rm'])) {
+                    $ioAdapter->rm($file);
+                }
+
+                exit(0);
+            } else {
+                $this->getResponse()->setBody($content);
+            }
+        }
+        return $this;
+    }
+
+    /**
+     * Check if form_key validation enabled on checkout process
+     *
+     * @return bool
+     */
+    protected function isFormkeyValidationOnCheckoutEnabled()
+    {
+        return Mage::getStoreConfigFlag('admin/security/validate_formkey_checkout');
+    }
+
+    /**
+     * Validate Form Key
+     *
+     * @return bool
+     */
+    protected function _validateFormKey()
+    {
+        $validated = true;
+        if (Mage::getStoreConfigFlag(self::XML_CSRF_USE_FLAG_CONFIG_PATH)) {
+            $validated = parent::_validateFormKey();
+        }
+        return $validated;
+    }
 }
diff --git app/code/core/Mage/Core/Controller/Request/Http.php app/code/core/Mage/Core/Controller/Request/Http.php
index c563df0..18733b1 100644
--- app/code/core/Mage/Core/Controller/Request/Http.php
+++ app/code/core/Mage/Core/Controller/Request/Http.php
@@ -147,7 +147,10 @@ public function setPathInfo($pathInfo = null)
             $baseUrl = $this->getBaseUrl();
             $pathInfo = substr($requestUri, strlen($baseUrl));
 
-            if ((null !== $baseUrl) && (false === $pathInfo)) {
+            if ($baseUrl && $pathInfo && (0 !== stripos($pathInfo, '/'))) {
+                $pathInfo = '';
+                $this->setActionName('noRoute');
+            } elseif ((null !== $baseUrl) && (false === $pathInfo)) {
                 $pathInfo = '';
             } elseif (null === $baseUrl) {
                 $pathInfo = $requestUri;
diff --git app/code/core/Mage/Core/Controller/Varien/Action.php app/code/core/Mage/Core/Controller/Varien/Action.php
index 8333176..2f236c9 100644
--- app/code/core/Mage/Core/Controller/Varien/Action.php
+++ app/code/core/Mage/Core/Controller/Varien/Action.php
@@ -147,7 +147,6 @@ public function __construct(Zend_Controller_Request_Abstract $request, Zend_Cont
 
     protected function _construct()
     {
-
     }
 
     public function hasAction($action)
@@ -243,8 +242,8 @@ public function getLayout()
      * Load layout by handles(s)
      *
      * @param   string $handles
-     * @param   string $cacheId
-     * @param   boolean $generateBlocks
+     * @param   bool $generateBlocks
+     * @param   bool $generateXml
      * @return  Mage_Core_Controller_Varien_Action
      */
     public function loadLayout($handles=null, $generateBlocks=true, $generateXml=true)
@@ -452,14 +451,21 @@ public function dispatch($action)
         }
     }
 
+    /**
+     * Retrieve action method name
+     *
+     * @param string $action
+     * @return string
+     */
     public function getActionMethodName($action)
     {
-        $method = $action.'Action';
-        return $method;
+        return $action . 'Action';
     }
 
     /**
-     * Dispatches event before action
+     * Dispatch event before action
+     *
+     * @return null
      */
     public function preDispatch()
     {
@@ -487,13 +493,32 @@ public function preDispatch()
             if ($checkCookie && empty($cookies)) {
                 $this->setFlag('', self::FLAG_NO_COOKIES_REDIRECT, true);
             }
-            Mage::getSingleton('core/session', array('name' => $this->_sessionNamespace))->start();
+
+            /** @var $session Mage_Core_Model_Session */
+            $session = Mage::getSingleton('core/session', array('name' => $this->_sessionNamespace))->start();
+
+            if (empty($cookies)) {
+                if ($session->getCookieShouldBeReceived()) {
+                    $this->setFlag('', self::FLAG_NO_COOKIES_REDIRECT, true);
+                    $session->unsCookieShouldBeReceived();
+                    $session->setSkipSessionIdFlag(true);
+                } elseif ($checkCookie) {
+                    if (isset($_GET[$session->getSessionIdQueryParam()]) && Mage::app()->getUseSessionInUrl()
+                        && !Mage::app()->getStore()->isAdmin()
+                    ) {
+                        $session->setCookieShouldBeReceived(true);
+                    } else {
+                        $this->setFlag('', self::FLAG_NO_COOKIES_REDIRECT, true);
+                    }
+                }
+            }
         }
 
         Mage::app()->loadArea($this->getLayout()->getArea());
 
         if ($this->getFlag('', self::FLAG_NO_COOKIES_REDIRECT)
-            && Mage::getStoreConfig('web/browser_capabilities/cookies')) {
+            && Mage::getStoreConfig('web/browser_capabilities/cookies')
+        ) {
             $this->_forward('noCookies', 'index', 'core');
             return;
         }
@@ -502,6 +527,8 @@ public function preDispatch()
             return;
         }
 
+        Varien_Autoload::registerScope($this->getRequest()->getRouteName());
+
         Mage::dispatchEvent('controller_action_predispatch', array('controller_action'=>$this));
         Mage::dispatchEvent(
             'controller_action_predispatch_'.$this->getRequest()->getRouteName(),
@@ -548,7 +575,6 @@ public function norouteAction($coreRoute = null)
             $this->renderLayout();
         } else {
             $status->setForwarded(true);
-            #$this->_forward('cmsNoRoute', 'index', 'cms');
             $this->_forward(
                 $status->getForwardAction(),
                 $status->getForwardController(),
@@ -611,7 +637,7 @@ protected function _forward($action, $controller = null, $module = null, array $
     }
 
     /**
-     * Inits layout messages by message storage(s), loading and adding messages to layout messages block
+     * Initializing layout messages by message storage(s), loading and adding messages to layout messages block
      *
      * @param string|array $messagesStorage
      * @return Mage_Core_Controller_Varien_Action
@@ -638,7 +664,7 @@ protected function _initLayoutMessages($messagesStorage)
     }
 
     /**
-     * Inits layout messages by message storage(s), loading and adding messages to layout messages block
+     * Initializing layout messages by message storage(s), loading and adding messages to layout messages block
      *
      * @param string|array $messagesStorage
      * @return Mage_Core_Controller_Varien_Action
@@ -666,8 +692,30 @@ protected function _redirectUrl($url)
      * @param   string $path
      * @param   array $arguments
      */
-    protected function _redirect($path, $arguments=array())
+    protected function _redirect($path, $arguments = array())
     {
+        return $this->setRedirectWithCookieCheck($path, $arguments);
+    }
+
+    /**
+     * Set redirect into response with session id in URL if it is enabled.
+     * It allows to distinguish primordial request from browser with cookies disabled.
+     *
+     * @param   string $path
+     * @param   array $arguments
+     * @return  Mage_Core_Controller_Varien_Action
+     */
+    public function setRedirectWithCookieCheck($path, array $arguments = array())
+    {
+        /** @var $session Mage_Core_Model_Session */
+        $session = Mage::getSingleton('core/session', array('name' => $this->_sessionNamespace));
+        if ($session->getCookieShouldBeReceived() && Mage::app()->getUseSessionInUrl()
+            && !Mage::app()->getStore()->isAdmin()
+        ) {
+            $arguments += array('_query' => array(
+                $session->getSessionIdQueryParam() => $session->getSessionId()
+            ));
+        }
         $this->getResponse()->setRedirect(Mage::getUrl($path, $arguments));
         return $this;
     }
diff --git app/code/core/Mage/Core/Controller/Varien/Front.php app/code/core/Mage/Core/Controller/Varien/Front.php
index 628f1d9..697861f 100644
--- app/code/core/Mage/Core/Controller/Varien/Front.php
+++ app/code/core/Mage/Core/Controller/Varien/Front.php
@@ -296,7 +296,17 @@ protected function _checkBaseUrl($request)
         if (!Mage::isInstalled() || $request->getPost()) {
             return;
         }
-        if (!Mage::getStoreConfig('web/url/redirect_to_base')) {
+
+        $redirectCode = Mage::getStoreConfig('web/url/redirect_to_base');
+        if (!$redirectCode) {
+            return;
+        } elseif ($redirectCode != 301) {
+            $redirectCode = 302;
+        }
+
+        if ($this->_isAdminFrontNameMatched($request)
+            && (string)Mage::getConfig()->getNode(Mage_Adminhtml_Helper_Data::XML_PATH_USE_CUSTOM_ADMIN_URL)
+        ) {
             return;
         }
 
@@ -306,22 +316,58 @@ protected function _checkBaseUrl($request)
             return;
         }
 
-        $redirectCode = 302;
-        if (Mage::getStoreConfig('web/url/redirect_to_base')==301) {
-            $redirectCode = 301;
-        }
-
         $uri = @parse_url($baseUrl);
         $host = isset($uri['host']) ? $uri['host'] : '';
         $path = isset($uri['path']) ? $uri['path'] : '';
 
         $requestUri = $request->getRequestUri() ? $request->getRequestUri() : '/';
-        if ($host && $host != $request->getHttpHost() || $path && strpos($requestUri, $path) === false)
-        {
+        if (
+            $host && $host != $request->getHttpHost()
+            || $path && strpos($requestUri, $path) === false
+        ) {
             Mage::app()->getFrontController()->getResponse()
                 ->setRedirect($baseUrl, $redirectCode)
                 ->sendResponse();
             exit;
         }
     }
+
+    /**
+     * Check if requested path starts with one of the admin front names
+     *
+     * @param Zend_Controller_Request_Http $request
+     * @return boolean
+     */
+    protected function _isAdminFrontNameMatched($request)
+    {
+        $useCustomAdminPath = (bool)(string)Mage::getConfig()
+            ->getNode(Mage_Adminhtml_Helper_Data::XML_PATH_USE_CUSTOM_ADMIN_PATH);
+        $customAdminPath = (string)Mage::getConfig()->getNode(Mage_Adminhtml_Helper_Data::XML_PATH_CUSTOM_ADMIN_PATH);
+        $adminPath = ($useCustomAdminPath) ? $customAdminPath : null;
+
+        if (!$adminPath) {
+            $adminPath = (string)Mage::getConfig()
+                ->getNode(Mage_Adminhtml_Helper_Data::XML_PATH_ADMINHTML_ROUTER_FRONTNAME);
+        }
+        $adminFrontNames = array($adminPath);
+
+        // Check for other modules that can use admin router (a lot of Magento extensions do that)
+        $adminFrontNameNodes = Mage::getConfig()->getNode('admin/routers')
+            ->xpath('*[not(self::adminhtml) and use = "admin"]/args/frontName');
+
+        if (is_array($adminFrontNameNodes)) {
+            foreach ($adminFrontNameNodes as $frontNameNode) {
+                /** @var $frontNameNode SimpleXMLElement */
+                array_push($adminFrontNames, (string)$frontNameNode);
+            }
+        }
+
+        $pathPrefix = ltrim($request->getPathInfo(), '/');
+        $urlDelimiterPos = strpos($pathPrefix, '/');
+        if ($urlDelimiterPos) {
+            $pathPrefix = substr($pathPrefix, 0, $urlDelimiterPos);
+        }
+
+        return in_array($pathPrefix, $adminFrontNames);
+    }
 }
diff --git app/code/core/Mage/Core/Controller/Varien/Router/Standard.php app/code/core/Mage/Core/Controller/Varien/Router/Standard.php
index c0d84d7..2fdf0be 100644
--- app/code/core/Mage/Core/Controller/Varien/Router/Standard.php
+++ app/code/core/Mage/Core/Controller/Varien/Router/Standard.php
@@ -429,7 +429,7 @@ public function rewrite(array $p)
                 $p[2] = trim((string)$action);
             }
         }
-#echo "<pre>".print_r($p,1)."</pre>";
+
         return $p;
     }
 
diff --git app/code/core/Mage/Core/Helper/Url.php app/code/core/Mage/Core/Helper/Url.php
index e9c3089..9eae241 100644
--- app/code/core/Mage/Core/Helper/Url.php
+++ app/code/core/Mage/Core/Helper/Url.php
@@ -105,6 +105,28 @@ protected function _prepareString($string)
     }
 
     /**
+     * Remove request parameter from url
+     *
+     * @param string $url
+     * @param string $paramKey
+     * @param boolean $caseSensitive
+     * @return string
+     */
+    public function removeRequestParam($url, $paramKey, $caseSensitive = false)
+    {
+        $regExpression = '/\\?[^#]*?(' . preg_quote($paramKey, '/') . '\\=[^#&]*&?)/' . ($caseSensitive ? '' : 'i');
+        while (preg_match($regExpression, $url, $mathes) != 0) {
+            $paramString = $mathes[1];
+            if (preg_match('/&$/', $paramString) == 0) {
+                $url = preg_replace('/(&|\\?)?' . preg_quote($paramString, '/') . '/', '', $url);
+            } else {
+                $url = str_replace($paramString, '', $url);
+            }
+        }
+        return $url;
+    }
+
+    /**
      * Return singleton model instance
      *
      * @param string $name
diff --git app/code/core/Mage/Core/Model/File/Validator/Image.php app/code/core/Mage/Core/Model/File/Validator/Image.php
index 136760b..32125c2 100644
--- app/code/core/Mage/Core/Model/File/Validator/Image.php
+++ app/code/core/Mage/Core/Model/File/Validator/Image.php
@@ -87,10 +87,33 @@ public function setAllowedImageTypes(array $imageFileExtensions = array())
      */
     public function validate($filePath)
     {
-        $fileInfo = getimagesize($filePath);
-        if (is_array($fileInfo) and isset($fileInfo[2])) {
-            if ($this->isImageType($fileInfo[2])) {
-                return null;
+        list($imageWidth, $imageHeight, $fileType) = getimagesize($filePath);
+        if ($fileType) {
+            if ($this->isImageType($fileType)) {
+                //replace tmp image with re-sampled copy to exclude images with malicious data
+                $image = imagecreatefromstring(file_get_contents($filePath));
+                if ($image !== false) {
+                    $img = imagecreatetruecolor($imageWidth, $imageHeight);
+                    imagecopyresampled($img, $image, 0, 0, 0, 0, $imageWidth, $imageHeight, $imageWidth, $imageHeight);
+                    switch ($fileType) {
+                        case IMAGETYPE_GIF:
+                            imagegif($img, $filePath);
+                            break;
+                        case IMAGETYPE_JPEG:
+                            imagejpeg($img, $filePath, 100);
+                            break;
+                        case IMAGETYPE_PNG:
+                            imagepng($img, $filePath);
+                            break;
+                        default:
+                            return;
+                    }
+                    imagedestroy($img);
+                    imagedestroy($image);
+                    return null;
+                } else {
+                    throw Mage::exception('Mage_Core', Mage::helper('core')->__('Invalid image.'));
+                }
             }
         }
         throw Mage::exception('Mage_Core', Mage::helper('core')->__('Invalid MIME type.'));
@@ -105,5 +128,4 @@ protected function isImageType($nImageType)
     {
         return in_array($nImageType, $this->_allowedImageTypes);
     }
-
 }
diff --git app/code/core/Mage/Core/Model/Url.php app/code/core/Mage/Core/Model/Url.php
index 2eaf5b6..09fe636 100644
--- app/code/core/Mage/Core/Model/Url.php
+++ app/code/core/Mage/Core/Model/Url.php
@@ -911,6 +911,38 @@ protected function _prepareSessionUrl($url)
     }
 
     /**
+     * Rebuild URL to handle the case when session ID was changed
+     *
+     * @param string $url
+     * @return string
+     */
+    public function getRebuiltUrl($url)
+    {
+        $this->parseUrl($url);
+        $port = $this->getPort();
+        if ($port) {
+            $port = ':' . $port;
+        } else {
+            $port = '';
+        }
+        $url = $this->getScheme() . '://' . $this->getHost() . $port . $this->getPath();
+
+        $this->_prepareSessionUrl($url);
+
+        $query = $this->getQuery();
+        if ($query) {
+            $url .= '?' . $query;
+        }
+
+        $fragment = $this->getFragment();
+        if ($fragment) {
+            $url .= '#' . $fragment;
+        }
+
+        return $this->escape($url);
+    }
+
+    /**
      * Escape (enclosure) URL string
      *
      * @param string $value
diff --git app/code/core/Mage/Core/etc/config.xml app/code/core/Mage/Core/etc/config.xml
index 20687bb..8c2ff2c 100644
--- app/code/core/Mage/Core/etc/config.xml
+++ app/code/core/Mage/Core/etc/config.xml
@@ -237,6 +237,9 @@
         </dev>
 
         <system>
+            <csrf>
+                <use_form_key>1</use_form_key>
+            </csrf>
             <smtp>
                 <disable>0</disable>
                 <host>localhost</host>
diff --git app/code/core/Mage/Core/etc/system.xml app/code/core/Mage/Core/etc/system.xml
index 22387e2..fbfde05 100644
--- app/code/core/Mage/Core/etc/system.xml
+++ app/code/core/Mage/Core/etc/system.xml
@@ -41,6 +41,29 @@
         </advanced>
     </tabs>
     <sections>
+        <system>
+            <groups>
+                <csrf translate="label" module="core">
+                    <label>CSRF protection</label>
+                    <frontend_type>text</frontend_type>
+                    <sort_order>0</sort_order>
+                    <show_in_default>1</show_in_default>
+                    <show_in_website>1</show_in_website>
+                    <show_in_store>1</show_in_store>
+                    <fields>
+                        <use_form_key translate="label">
+                            <label>Add Secret Key To Url</label>
+                            <frontend_type>select</frontend_type>
+                            <source_model>adminhtml/system_config_source_yesno</source_model>
+                            <sort_order>10</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>1</show_in_website>
+                            <show_in_store>1</show_in_store>
+                        </use_form_key>
+                    </fields>
+                </csrf>
+            </groups>
+        </system>
         <!--<web_track translate="label" module="core">
             <label>Web Tracking</label>
             <frontend_type>text</frontend_type>
@@ -500,26 +523,6 @@
                         </template_hints_blocks>
                     </fields>
                 </debug>
-                <template translate="label">
-                    <label>Template Settings</label>
-                    <frontend_type>text</frontend_type>
-                    <sort_order>25</sort_order>
-                    <show_in_default>1</show_in_default>
-                    <show_in_website>1</show_in_website>
-                    <show_in_store>1</show_in_store>
-                    <fields>
-                        <allow_symlink translate="label comment">
-                            <label>Allow Symlinks</label>
-                            <frontend_type>select</frontend_type>
-                            <source_model>adminhtml/system_config_source_yesno</source_model>
-                            <sort_order>10</sort_order>
-                            <show_in_default>1</show_in_default>
-                            <show_in_website>1</show_in_website>
-                            <show_in_store>1</show_in_store>
-                            <comment>Warning! Enabling this feature is not recommended on production environments because it represents a potential security risk.</comment>
-                        </allow_symlink>
-                    </fields>
-                </template>
                 <translate_inline translate="label">
                     <label>Translate Inline</label>
                     <frontend_type>text</frontend_type>
@@ -769,6 +772,25 @@
             <show_in_website>1</show_in_website>
             <show_in_store>1</show_in_store>
             <groups>
+                <csrf translate="label" module="core">
+                    <label>CSRF protection</label>
+                    <frontend_type>text</frontend_type>
+                    <sort_order>0</sort_order>
+                    <show_in_default>1</show_in_default>
+                    <show_in_website>1</show_in_website>
+                    <show_in_store>1</show_in_store>
+                    <fields>
+                        <use_form_key translate="label">
+                            <label>Add Secret Key To Url</label>
+                            <frontend_type>select</frontend_type>
+                            <source_model>adminhtml/system_config_source_yesno</source_model>
+                            <sort_order>10</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>1</show_in_website>
+                            <show_in_store>1</show_in_store>
+                        </use_form_key>
+                    </fields>
+                </csrf>
                 <smtp translate="label">
                     <label>Mail Sending Settings</label>
                     <frontend_type>text</frontend_type>
diff --git app/code/core/Mage/Customer/Helper/Data.php app/code/core/Mage/Customer/Helper/Data.php
index a0dc924..7f6bf07 100644
--- app/code/core/Mage/Customer/Helper/Data.php
+++ app/code/core/Mage/Customer/Helper/Data.php
@@ -40,6 +40,16 @@ class Mage_Customer_Helper_Data extends Mage_Core_Helper_Abstract
     const REFERER_QUERY_PARAM_NAME = 'referer';
 
     /**
+     * Route for customer account login page
+     */
+    const ROUTE_ACCOUNT_LOGIN = 'customer/account/login';
+
+    /**
+     * Config name for Redirect Customer to Account Dashboard after Logging in setting
+     */
+    const XML_PATH_CUSTOMER_STARTUP_REDIRECT_TO_DASHBOARD = 'customer/startup/redirect_dashboard';
+
+    /**
      * Customer groups collection
      *
      * @var Mage_Customer_Model_Entity_Group_Collection
@@ -125,21 +135,30 @@ public function customerHasAddresses()
      */
     public function getLoginUrl()
     {
+        return $this->_getUrl(self::ROUTE_ACCOUNT_LOGIN, $this->getLoginUrlParams());
+    }
+    /**
+     * Retrieve parameters of customer login url
+     *
+     * @return array
+     */
+    public function getLoginUrlParams()
+    {
         $params = array();
 
         $referer = $this->_getRequest()->getParam(self::REFERER_QUERY_PARAM_NAME);
 
-        if (!$referer && !Mage::getStoreConfigFlag('customer/startup/redirect_dashboard')) {
-            if (!Mage::getSingleton('customer/session')->getNoReferer()) {
-                $referer = Mage::getUrl('*/*/*', array('_current' => true, '_use_rewrite' => true));
-                $referer = Mage::helper('core')->urlEncode($referer);
-            }
+        if (!$referer && !Mage::getStoreConfigFlag(self::XML_PATH_CUSTOMER_STARTUP_REDIRECT_TO_DASHBOARD)
+            && !Mage::getSingleton('customer/session')->getNoReferer()
+        ) {
+            $referer = Mage::getUrl('*/*/*', array('_current' => true, '_use_rewrite' => true));
+            $referer = Mage::helper('core')->urlEncode($referer);
         }
         if ($referer) {
             $params = array(self::REFERER_QUERY_PARAM_NAME => $referer);
         }
 
-        return $this->_getUrl('customer/account/login', $params);
+        return $params;
     }
 
     /**
diff --git app/code/core/Mage/Customer/Model/Session.php app/code/core/Mage/Customer/Model/Session.php
index d71c7a3..0d80197 100644
--- app/code/core/Mage/Customer/Model/Session.php
+++ app/code/core/Mage/Customer/Model/Session.php
@@ -48,6 +48,13 @@ class Mage_Customer_Model_Session extends Mage_Core_Model_Session_Abstract
     protected $_isCustomerIdChecked = null;
 
     /**
+     * Persistent customer group id
+     *
+     * @var null|int
+     */
+    protected $_persistentCustomerGroupId = null;
+
+    /**
      * Retrieve customer sharing configuration model
      *
      * @return Mage_Customer_Model_Config_Share
@@ -79,9 +86,7 @@ public function setCustomer(Mage_Customer_Model_Customer $customer)
         // check if customer is not confirmed
         if ($customer->isConfirmationRequired()) {
             if ($customer->getConfirmation()) {
-                throw new Exception('This customer is not confirmed and cannot log in.',
-                    Mage_Customer_Model_Customer::EXCEPTION_EMAIL_NOT_CONFIRMED
-                );
+                return $this->_logout();
             }
         }
         $this->_customer = $customer;
@@ -116,12 +121,27 @@ public function getCustomer()
     }
 
     /**
+     * Set customer id
+     *
+     * @param int|null $id
+     * @return Mage_Customer_Model_Session
+     */
+    public function setCustomerId($id)
+    {
+        $this->setData('customer_id', $id);
+        return $this;
+    }
+
+    /**
      * Retrieve customer id from current session
      *
-     * @return int || null
+     * @return int|null
      */
     public function getCustomerId()
     {
+        if ($this->getData('customer_id')) {
+            return $this->getData('customer_id');
+        }
         if ($this->isLoggedIn()) {
             return $this->getId();
         }
@@ -129,18 +149,32 @@ public function getCustomerId()
     }
 
     /**
+     * Set customer group id
+     *
+     * @param int|null $id
+     * @return Mage_Customer_Model_Session
+     */
+    public function setCustomerGroupId($id)
+    {
+        $this->setData('customer_group_id', $id);
+        return $this;
+    }
+
+    /**
      * Get customer group id
-     * If customer is not logged in system not logged in group id will be returned
+     * If customer is not logged in system, 'not logged in' group id will be returned
      *
      * @return int
      */
     public function getCustomerGroupId()
     {
-        if ($this->isLoggedIn()) {
+        if ($this->getData('customer_group_id')) {
+            return $this->getData('customer_group_id');
+        }
+        if ($this->isLoggedIn() && $this->getCustomer()) {
             return $this->getCustomer()->getGroupId();
-        } else {
-            return Mage_Customer_Model_Group::NOT_LOGGED_IN_ID;
         }
+        return Mage_Customer_Model_Group::NOT_LOGGED_IN_ID;
     }
 
     /**
@@ -191,6 +225,8 @@ public function login($username, $password)
     public function setCustomerAsLoggedIn($customer)
     {
         $this->setCustomer($customer);
+        $this->renewSession();
+        Mage::getSingleton('core/session')->renewFormKey();
         Mage::dispatchEvent('customer_login', array('customer'=>$customer));
         return $this;
     }
@@ -220,8 +256,7 @@ public function logout()
     {
         if ($this->isLoggedIn()) {
             Mage::dispatchEvent('customer_logout', array('customer' => $this->getCustomer()) );
-            $this->setId(null);
-            $this->getCookie()->delete($this->getSessionName());
+            $this->_logout();
         }
         return $this;
     }
@@ -230,18 +265,93 @@ public function logout()
      * Authenticate controller action by login customer
      *
      * @param   Mage_Core_Controller_Varien_Action $action
+     * @param   bool $loginUrl
      * @return  bool
      */
     public function authenticate(Mage_Core_Controller_Varien_Action $action, $loginUrl = null)
     {
-        if (!$this->isLoggedIn()) {
-            $this->setBeforeAuthUrl(Mage::getUrl('*/*/*', array('_current'=>true)));
-            if (is_null($loginUrl)) {
-                $loginUrl = Mage::helper('customer')->getLoginUrl();
-            }
+        if ($this->isLoggedIn()) {
+            return true;
+        }
+
+        if ($this->isLoggedIn()) {
+            return true;
+        }
+
+        $this->setBeforeAuthUrl(Mage::getUrl('*/*/*', array('_current' => true)));
+        if (isset($loginUrl)) {
             $action->getResponse()->setRedirect($loginUrl);
-            return false;
+        } else {
+            $action->setRedirectWithCookieCheck(Mage_Customer_Helper_Data::ROUTE_ACCOUNT_LOGIN,
+                Mage::helper('customer')->getLoginUrlParams()
+            );
         }
-        return true;
+
+        return false;
+    }
+
+    /**
+     * Set auth url
+     *
+     * @param string $key
+     * @param string $url
+     * @return Mage_Customer_Model_Session
+     */
+    protected function _setAuthUrl($key, $url)
+    {
+        $url = Mage::helper('core/url')
+            ->removeRequestParam($url, Mage::getSingleton('core/session')->getSessionIdQueryParam());
+        // Add correct session ID to URL if needed
+        $url = Mage::getModel('core/url')->getRebuiltUrl($url);
+        return $this->setData($key, $url);
+    }
+
+    /**
+     * Logout without dispatching event
+     *
+     * @return Mage_Customer_Model_Session
+     */
+    protected function _logout()
+    {
+        $this->setId(null);
+        $this->setCustomerGroupId(Mage_Customer_Model_Group::NOT_LOGGED_IN_ID);
+        $this->getCookie()->delete($this->getSessionName());
+        Mage::getSingleton('core/session')->renewFormKey();
+        return $this;
+    }
+
+    /**
+     * Set Before auth url
+     *
+     * @param string $url
+     * @return Mage_Customer_Model_Session
+     */
+    public function setBeforeAuthUrl($url)
+    {
+        return $this->_setAuthUrl('before_auth_url', $url);
+    }
+
+    /**
+     * Set After auth url
+     *
+     * @param string $url
+     * @return Mage_Customer_Model_Session
+     */
+    public function setAfterAuthUrl($url)
+    {
+        return $this->_setAuthUrl('after_auth_url', $url);
+    }
+
+    /**
+     * Reset core session hosts after reseting session ID
+     *
+     * @return Mage_Customer_Model_Session
+     */
+    public function renewSession()
+    {
+        parent::renewSession();
+        Mage::getSingleton('core/session')->unsSessionHosts();
+
+        return $this;
     }
 }
diff --git app/code/core/Mage/Dataflow/Model/Convert/Adapter/Zend/Cache.php app/code/core/Mage/Dataflow/Model/Convert/Adapter/Zend/Cache.php
index 7bdc41c..89601d8 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Adapter/Zend/Cache.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Adapter/Zend/Cache.php
@@ -40,6 +40,9 @@ public function getResource()
         if (!$this->_resource) {
             $this->_resource = Zend_Cache::factory($this->getVar('frontend', 'Core'), $this->getVar('backend', 'File'));
         }
+        if ($this->_resource->getBackend() instanceof Zend_Cache_Backend_Static) {
+            throw new Exception(Mage::helper('dataflow')->__('Backend name "Static" not supported.'));
+        }
         return $this->_resource;
     }
 
diff --git app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
index a3af1ef..9dfd9b9 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
@@ -47,6 +47,18 @@
 
     protected $_position;
 
+    /**
+     * Detect serialization of data
+     *
+     * @param mixed $data
+     * @return bool
+     */
+    protected function isSerialized($data)
+    {
+        $pattern = '/^a:\d+:\{(i:\d+;|s:\d+:\".+\";|N;|O:\d+:\"\w+\":\d+:\{\w:\d+:)+|^O:\d+:\"\w+\":\d+:\{s:\d+:\"/';
+        return (is_string($data) && preg_match($pattern, $data));
+    }
+
     public function getVar($key, $default=null)
     {
         if (!isset($this->_vars[$key]) || (!is_array($this->_vars[$key]) && strlen($this->_vars[$key]) == 0)) {
@@ -102,13 +114,45 @@ public function getData()
 
     public function setData($data)
     {
-        if ($this->getProfile()) {
-            $this->getProfile()->getContainer()->setData($data);
+        if ($this->validateDataSerialized($data)) {
+            if ($this->getProfile()) {
+                $this->getProfile()->getContainer()->setData($data);
+            }
+
+            $this->_data = $data;
         }
-        $this->_data = $data;
+
         return $this;
     }
 
+    /**
+     * Validate serialized data
+     *
+     * @param mixed $data
+     * @return bool
+     */
+    public function validateDataSerialized($data = null)
+    {
+        if (is_null($data)) {
+            $data = $this->getData();
+        }
+
+        $result = true;
+        if ($this->isSerialized($data)) {
+            try {
+                $dataArray = Mage::helper('core/unserializeArray')->unserialize($data);
+            } catch (Exception $e) {
+                $result = false;
+                $this->addException(
+                    "Invalid data, expecting serialized array.",
+                    Mage_Dataflow_Model_Convert_Exception::FATAL
+                );
+            }
+        }
+
+        return $result;
+    }
+
     public function validateDataString($data=null)
     {
         if (is_null($data)) {
@@ -140,7 +184,10 @@ public function validateDataGrid($data=null)
             if (count($data)==0) {
                 return true;
             }
-            $this->addException("Invalid data type, expecting 2D grid array.", Mage_Dataflow_Model_Convert_Exception::FATAL);
+            $this->addException(
+                "Invalid data type, expecting 2D grid array.",
+                Mage_Dataflow_Model_Convert_Exception::FATAL
+            );
         }
         return true;
     }
diff --git app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
index 83d30a6..af631ff 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
@@ -62,13 +62,15 @@ public function parse()
             $adapter = Mage::getModel($adapterName);
         }
         catch (Exception $e) {
-            $message = Mage::helper('dataflow')->__('Declared adapter %s was not found.', $adapterName);
+            $message = Mage::helper('dataflow')
+                ->__('Declared adapter %s was not found.', $adapterName);
             $this->addException($message, Mage_Dataflow_Model_Convert_Exception::FATAL);
             return $this;
         }
 
         if (!is_callable(array($adapter, $adapterMethod))) {
-            $message = Mage::helper('dataflow')->__('Method "%s" not defined in adapter %s.', $adapterMethod, $adapterName);
+            $message = Mage::helper('dataflow')
+                ->__('Method "%s" not defined in adapter %s.', $adapterMethod, $adapterName);
             $this->addException($message, Mage_Dataflow_Model_Convert_Exception::FATAL);
             return $this;
         }
diff --git app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php
index f9c96b3..a60a72c 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php
@@ -69,7 +69,8 @@ public function parse()
         }
 
         if (!is_callable(array($adapter, $adapterMethod))) {
-            $message = Mage::helper('dataflow')->__('Method "%s" was not defined in adapter %s.', $adapterMethod, $adapterName);
+            $message = Mage::helper('dataflow')
+                ->__('Method "%s" was not defined in adapter %s.', $adapterMethod, $adapterName);
             $this->addException($message, Mage_Dataflow_Model_Convert_Exception::FATAL);
             return $this;
         }
@@ -78,8 +79,8 @@ public function parse()
         $batchIoAdapter = $this->getBatchModel()->getIoAdapter();
 
         if (Mage::app()->getRequest()->getParam('files')) {
-            $file = Mage::app()->getConfig()->getTempVarDir().'/import/'
-                . urldecode(Mage::app()->getRequest()->getParam('files'));
+            $file = Mage::app()->getConfig()->getTempVarDir() . '/import/'
+                . str_replace('../', '', urldecode(Mage::app()->getRequest()->getParam('files')));
             $this->_copy($file);
         }
 
diff --git app/code/core/Mage/Sales/Model/Quote/Item.php app/code/core/Mage/Sales/Model/Quote/Item.php
index ee91abc..971c30b 100644
--- app/code/core/Mage/Sales/Model/Quote/Item.php
+++ app/code/core/Mage/Sales/Model/Quote/Item.php
@@ -381,8 +381,9 @@ public function compare($item)
                         /** @var Unserialize_Parser $parser */
                         $parser = Mage::helper('core/unserializeArray');
 
-                        $_itemOptionValue = $parser->unserialize($itemOptionValue);
-                        $_optionValue = $parser->unserialize($optionValue);
+                        $_itemOptionValue =
+                            is_numeric($itemOptionValue) ? $itemOptionValue : $parser->unserialize($itemOptionValue);
+                        $_optionValue = is_numeric($optionValue) ? $optionValue : $parser->unserialize($optionValue);
 
                         if (is_array($_itemOptionValue) && is_array($_optionValue)) {
                             $itemOptionValue = $_itemOptionValue;
diff --git app/code/core/Mage/Widget/Model/Widget/Instance.php app/code/core/Mage/Widget/Model/Widget/Instance.php
index 32b8058..283979c 100644
--- app/code/core/Mage/Widget/Model/Widget/Instance.php
+++ app/code/core/Mage/Widget/Model/Widget/Instance.php
@@ -319,7 +319,11 @@ public function getStoreIds()
     public function getWidgetParameters()
     {
         if (is_string($this->getData('widget_parameters'))) {
-            return unserialize($this->getData('widget_parameters'));
+            try {
+                return Mage::helper('core/unserializeArray')->unserialize($this->getData('widget_parameters'));
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
         }
         return $this->getData('widget_parameters');
     }
diff --git app/code/core/Mage/XmlConnect/Helper/Image.php app/code/core/Mage/XmlConnect/Helper/Image.php
index 7ed69bf..2e32396 100644
--- app/code/core/Mage/XmlConnect/Helper/Image.php
+++ app/code/core/Mage/XmlConnect/Helper/Image.php
@@ -82,6 +82,11 @@ public function handleUpload($field, &$target)
             $uploader = Mage::getModel('core/file_uploader', $field);
             $uploader->setAllowedExtensions(array('jpg', 'jpeg', 'gif', 'png'));
             $uploader->setAllowRenameFiles(true);
+            $uploader->addValidateCallback(
+                Mage_Core_Model_File_Validator_Image::NAME,
+                Mage::getModel('core/file_validator_image'),
+                'validate'
+            );
             $uploader->save($uploadDir);
             $uploadedFilename = $uploader->getUploadedFileName();
             $uploadedFilename = $this->_getResizedFilename($field, $uploadedFilename, true);
diff --git app/design/adminhtml/default/default/layout/main.xml app/design/adminhtml/default/default/layout/main.xml
index afc1207..a1a92b1 100644
--- app/design/adminhtml/default/default/layout/main.xml
+++ app/design/adminhtml/default/default/layout/main.xml
@@ -118,7 +118,8 @@ Default layout, loads most of the pages
                 <block type="adminhtml/cache_notifications" name="cache_notifications" template="system/cache/notifications.phtml"></block>
                 <block type="adminhtml/notification_survey" name="notification_survey" template="notification/survey.phtml"/>
                 <block type="adminhtml/notification_security" name="notification_security" as="notification_security" template="notification/security.phtml"></block>
-            </block>
+                <block type="adminhtml/checkout_formkey" name="checkout_formkey" as="checkout_formkey" template="notification/formkey.phtml"/></block>
+                <block type="adminhtml/notification_symlink" name="notification_symlink" template="notification/symlink.phtml"/>
             <block type="adminhtml/widget_breadcrumbs" name="breadcrumbs" as="breadcrumbs"></block>
 
             <!--<update handle="formkey"/> this won't work, see the try/catch and a jammed exception in Mage_Core_Model_Layout::createBlock() -->
diff --git app/design/adminhtml/default/default/template/notification/formkey.phtml app/design/adminhtml/default/default/template/notification/formkey.phtml
new file mode 100644
index 0000000..3a90c03
--- /dev/null
+++ app/design/adminhtml/default/default/template/notification/formkey.phtml
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @copyright   Copyright (c) 2010 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+/**
+ * @see Mage_Adminhtml_Block_Checkout_Formkey
+ */
+?>
+<?php if ($this->canShow()): ?>
+    <div class="notification-global notification-global-warning">
+        <strong style="color:red">Important: </strong>
+        <span>Formkey validation on checkout disabled. This may expose security risks.
+        We strongly recommend to Enable Form Key Validation On Checkout in
+        <a href="<?php echo $this->getSecurityAdminUrl(); ?>">Admin / Security Section</a>,
+        for protect your own checkout process. </span>
+    </div>
+<?php endif; ?>
diff --git app/design/adminhtml/default/default/template/notification/symlink.phtml app/design/adminhtml/default/default/template/notification/symlink.phtml
new file mode 100644
index 0000000..d63dff6
--- /dev/null
+++ app/design/adminhtml/default/default/template/notification/symlink.phtml
@@ -0,0 +1,34 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @copyright   Copyright (c) 2010 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+/**
+ * @see Mage_Adminhtml_Block_Notification_Symlink
+ */
+?>
+<?php if ($this->isSymlinkEnabled()): ?>
+    <div class="notification-global notification-global-warning">
+        <?php echo $this->helper('adminhtml')->__('Symlinks are enabled. This may expose security risks. We strongly recommend to disable them.')?>
+    </div>
+<?php endif; ?>
diff --git app/design/adminhtml/default/default/template/page/head.phtml app/design/adminhtml/default/default/template/page/head.phtml
index c190c09..0074e2e 100644
--- app/design/adminhtml/default/default/template/page/head.phtml
+++ app/design/adminhtml/default/default/template/page/head.phtml
@@ -8,7 +8,7 @@
     var BLANK_URL = '<?php echo $this->getJsUrl() ?>blank.html';
     var BLANK_IMG = '<?php echo $this->getJsUrl() ?>spacer.gif';
     var BASE_URL = '<?php echo $this->getUrl('*') ?>';
-    var SKIN_URL = '<?php echo $this->getSkinUrl() ?>';
+    var SKIN_URL = '<?php echo $this->jsQuoteEscape($this->getSkinUrl()) ?>';
     var FORM_KEY = '<?php echo $this->getFormKey() ?>';
 </script>
 
diff --git app/design/frontend/base/default/template/checkout/cart/shipping.phtml app/design/frontend/base/default/template/checkout/cart/shipping.phtml
index 72921f8..b5be3dc 100644
--- app/design/frontend/base/default/template/checkout/cart/shipping.phtml
+++ app/design/frontend/base/default/template/checkout/cart/shipping.phtml
@@ -113,6 +113,7 @@
             <div class="buttons-set">
                 <button type="submit" title="<?php echo $this->__('Update Total') ?>" class="button" name="do" value="<?php echo $this->__('Update Total') ?>"><span><span><?php echo $this->__('Update Total') ?></span></span></button>
             </div>
+            <?php echo $this->getBlockHtml('formkey') ?>
         </form>
         <?php endif; ?>
         <script type="text/javascript">
diff --git app/design/frontend/base/default/template/checkout/multishipping/billing.phtml app/design/frontend/base/default/template/checkout/multishipping/billing.phtml
index 56acbb4..c173ff6 100644
--- app/design/frontend/base/default/template/checkout/multishipping/billing.phtml
+++ app/design/frontend/base/default/template/checkout/multishipping/billing.phtml
@@ -91,6 +91,7 @@
             <p class="back-link"><a href="<?php echo $this->getBackUrl() ?>"><small>&laquo; </small><?php echo $this->__('Back to Shipping Information') ?></a></p>
             <button type="submit" title="<?php echo $this->__('Continue to Review Your Order') ?>" class="button"><span><span><?php echo $this->__('Continue to Review Your Order') ?></span></span></button>
         </div>
+        <?php echo $this->getBlockHtml('formkey') ?>
     </form>
     <script type="text/javascript">
     //<![CDATA[
diff --git app/design/frontend/base/default/template/checkout/multishipping/shipping.phtml app/design/frontend/base/default/template/checkout/multishipping/shipping.phtml
index 091e92c..217470b 100644
--- app/design/frontend/base/default/template/checkout/multishipping/shipping.phtml
+++ app/design/frontend/base/default/template/checkout/multishipping/shipping.phtml
@@ -125,5 +125,6 @@
             <p class="back-link"><a href="<?php echo $this->getBackUrl() ?>"><small>&laquo; </small><?php echo $this->__('Back to Select Addresses') ?></a></p>
             <button type="submit" title="<?php echo $this->__('Continue to Billing Information') ?>" class="button"><span><span><?php echo $this->__('Continue to Billing Information') ?></span></span></button>
         </div>
+        <?php echo $this->getBlockHtml('formkey') ?>
     </form>
 </div>
diff --git app/design/frontend/base/default/template/checkout/onepage/billing.phtml app/design/frontend/base/default/template/checkout/onepage/billing.phtml
index c889ae6..854351a 100644
--- app/design/frontend/base/default/template/checkout/onepage/billing.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/billing.phtml
@@ -188,6 +188,7 @@
             <img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="<?php echo $this->__('Loading next step...') ?>" title="<?php echo $this->__('Loading next step...') ?>" class="v-middle" /> <?php echo $this->__('Loading next step...') ?>
         </span>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </fieldset>
 </form>
 <script type="text/javascript">
diff --git app/design/frontend/base/default/template/checkout/onepage/payment.phtml app/design/frontend/base/default/template/checkout/onepage/payment.phtml
index 44a5cdd..1f12544 100644
--- app/design/frontend/base/default/template/checkout/onepage/payment.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/payment.phtml
@@ -32,6 +32,7 @@
 <form action="" id="co-payment-form">
     <fieldset>
         <?php echo $this->getChildHtml('methods') ?>
+        <?php echo $this->getBlockHtml('formkey') ?>
     </fieldset>
 </form>
 <div class="tool-tip" id="payment-tool-tip" style="display:none;">
diff --git app/design/frontend/base/default/template/checkout/onepage/shipping.phtml app/design/frontend/base/default/template/checkout/onepage/shipping.phtml
index 1cbab5a..125988f 100644
--- app/design/frontend/base/default/template/checkout/onepage/shipping.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/shipping.phtml
@@ -139,6 +139,7 @@
             <img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="<?php echo $this->__('Loading next step...') ?>" title="<?php echo $this->__('Loading next step...') ?>" class="v-middle" /> <?php echo $this->__('Loading next step...') ?>
         </span>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </form>
 <script type="text/javascript">
 //<![CDATA[
diff --git app/design/frontend/base/default/template/checkout/onepage/shipping_method.phtml app/design/frontend/base/default/template/checkout/onepage/shipping_method.phtml
index fc82fa8..82d19a9 100644
--- app/design/frontend/base/default/template/checkout/onepage/shipping_method.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/shipping_method.phtml
@@ -43,4 +43,5 @@
             <img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="<?php echo $this->__('Loading next step...') ?>" title="<?php echo $this->__('Loading next step...') ?>" class="v-middle" /> <?php echo $this->__('Loading next step...') ?>
         </span>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </form>
diff --git app/etc/config.xml app/etc/config.xml
index a833fa3..c6f7e09 100644
--- app/etc/config.xml
+++ app/etc/config.xml
@@ -124,6 +124,11 @@
                 <export>{{var_dir}}/export</export>
             </filesystem>
         </system>
+        <dev>
+            <template>
+                <allow_symlink>0</allow_symlink>
+            </template>
+        </dev>
         <general>
             <locale>
                 <code>en_US</code>
diff --git app/locale/en_US/Mage_Adminhtml.csv app/locale/en_US/Mage_Adminhtml.csv
index 173c7f8..af4fab3 100644
--- app/locale/en_US/Mage_Adminhtml.csv
+++ app/locale/en_US/Mage_Adminhtml.csv
@@ -1223,3 +1223,5 @@
 "to","to"
 "website(%s) scope","website(%s) scope"
 "{{base_url}} is not recommended to use in a production environment to declare the Base Unsecure URL / Base Secure URL. It is highly recommended to change this value in your Magento <a href=""%s"">configuration</a>.","{{base_url}} is not recommended to use in a production environment to declare the Base Unsecure URL / Base Secure URL. It is highly recommended to change this value in your Magento <a href=""%s"">configuration</a>."
+"Symlinks are enabled. This may expose security risks. We strongly recommend to disable them.","Symlinks are enabled. This may expose security risks. We strongly recommend to disable them."
+"You did not sign in correctly or your account is temporarily disabled.","You did not sign in correctly or your account is temporarily disabled."
diff --git app/locale/en_US/Mage_Core.csv app/locale/en_US/Mage_Core.csv
index 9532849..76d7d7a 100644
--- app/locale/en_US/Mage_Core.csv
+++ app/locale/en_US/Mage_Core.csv
@@ -362,3 +362,4 @@
 "Your order cannot be completed at this time as there is no shipping methods available for it. Please make necessary changes in your shipping address.","Your order cannot be completed at this time as there is no shipping methods available for it. Please make necessary changes in your shipping address."
 "Your session has been expired, you will be relogged in now.","Your session has been expired, you will be relogged in now."
 "database ""%s""","database ""%s"""
+"Invalid image.","Invalid image."
diff --git app/locale/en_US/Mage_Dataflow.csv app/locale/en_US/Mage_Dataflow.csv
index 60bb9f8..79b33f5 100644
--- app/locale/en_US/Mage_Dataflow.csv
+++ app/locale/en_US/Mage_Dataflow.csv
@@ -28,3 +28,4 @@
 "hours","hours"
 "minute","minute"
 "minutes","minutes"
+"Backend name "Static" not supported.","Backend name "Static" not supported."
diff --git downloader/Maged/Connect.php downloader/Maged/Connect.php
index f2de9f6..5902375 100644
--- downloader/Maged/Connect.php
+++ downloader/Maged/Connect.php
@@ -143,7 +143,11 @@ public function getConfig()
     public function getSingleConfig($reload = false)
     {
         if(!$this->_sconfig || $reload) {
-            $this->_sconfig = new Mage_Connect_Singleconfig($this->getConfig()->magento_root . DIRECTORY_SEPARATOR . $this->getConfig()->downloader_path . DIRECTORY_SEPARATOR . Mage_Connect_Singleconfig::DEFAULT_SCONFIG_FILENAME);
+            $this->_sconfig = new Mage_Connect_Singleconfig(
+                $this->getConfig()->magento_root . DIRECTORY_SEPARATOR
+                . $this->getConfig()->downloader_path . DIRECTORY_SEPARATOR
+                . Mage_Connect_Singleconfig::DEFAULT_SCONFIG_FILENAME
+            );
         }
         Mage_Connect_Command::setSconfig($this->_sconfig);
         return $this->_sconfig;
@@ -217,13 +221,13 @@ public function delTree($path) {
     }
 
     /**
-    * Run commands from Mage_Connect_Command
-    *
-    * @param string $command
-    * @param array $options
-    * @param array $params
-    * @return
-    */
+     * Run commands from Mage_Connect_Command
+     *
+     * @param string $command
+     * @param array $options
+     * @param array $params
+     * @return boolean|Mage_Connect_Error
+     */
     public function run($command, $options=array(), $params=array())
     {
         @set_time_limit(0);
@@ -257,7 +261,13 @@ public function run($command, $options=array(), $params=array())
         }
     }
 
-    public function setRemoteConfig($uri) #$host, $user, $password, $path='', $port=null)
+    /**
+     * Set remote Config by URI
+     *
+     * @param $uri
+     * @return Maged_Connect
+     */
+    public function setRemoteConfig($uri)
     {
         #$uri = 'ftp://' . $user . ':' . $password . '@' . $host . (is_numeric($port) ? ':' . $port : '') . '/' . trim($path, '/') . '/';
         //$this->run('config-set', array(), array('remote_config', $uri));
@@ -267,6 +277,7 @@ public function setRemoteConfig($uri) #$host, $user, $password, $path='', $port=
     }
 
     /**
+     * Show Errors
      *
      * @param array $errors Error messages
      * @return Maged_Connect
@@ -277,7 +288,7 @@ public function showConnectErrors($errors)
         $run = new Maged_Model_Connect_Request();
         if ($callback = $run->get('failure_callback')) {
             if (is_array($callback)) {
-                call_user_func_array($callback, array($result));
+                call_user_func_array($callback, array($errors));
             } else {
                 echo $callback;
             }
@@ -290,8 +301,9 @@ public function showConnectErrors($errors)
     /**
      * Run Mage_COnnect_Command with html output console style
      *
-     * @param array|Maged_Model $runParams command, options, params,
-     *        comment, success_callback, failure_callback
+     * @throws Maged_Exception
+     * @param array|string|Maged_Model $runParams command, options, params, comment, success_callback, failure_callback
+     * @return bool|Mage_Connect_Error
      */
     public function runHtmlConsole($runParams)
     {
diff --git downloader/Maged/Controller.php downloader/Maged/Controller.php
index fc19adb..bd086d8 100755
--- downloader/Maged/Controller.php
+++ downloader/Maged/Controller.php
@@ -32,7 +32,6 @@
 * @copyright  Copyright (c) 2009 Irubin Consulting Inc. DBA Varien (http://www.varien.com)
 * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
 */
-
 final class Maged_Controller
 {
     /**
@@ -90,9 +89,9 @@
     private $_view;
 
     /**
-     * Config instance
+     * Connect config instance
      *
-     * @var Maged_Model_Config
+     * @var Mage_Connect_Config
      */
     private $_config;
 
@@ -155,7 +154,7 @@ private function getFtpPost($post){
         $ftp = 'ftp://';
         $post['ftp_proto'] = 'ftp://';
 
-        if (!empty($post['ftp_path']) && strlen(trim($post['ftp_path'], '\\/'))>0) {
+        if (!empty($post['ftp_path']) && strlen(trim($post['ftp_path'], '\\/')) > 0) {
             $post['ftp_path'] = '/' . trim($post['ftp_path'], '\\/') . '/';
         } else {
             $post['ftp_path'] = '/';
@@ -164,30 +163,32 @@ private function getFtpPost($post){
         $start = stripos($post['ftp_host'],'ftp://');
         if ($start !== false){
             $post['ftp_proto'] = 'ftp://';
-            $post['ftp_host'] = substr($post['ftp_host'], $start+6-1);
+            $post['ftp_host']  = substr($post['ftp_host'], $start + 6 - 1);
         }
         $start = stripos($post['ftp_host'],'ftps://');
-        if ($start !== false){
+        if ($start !== false) {
             $post['ftp_proto'] = 'ftps://';
-            $post['ftp_host'] = substr($post['ftp_host'], $start+7-1);
+            $post['ftp_host']  = substr($post['ftp_host'], $start + 7 - 1);
         }
 
         $post['ftp_host'] = trim($post['ftp_host'], '\\/');
-        
-        if (!empty($post['ftp_login']) && !empty($post['ftp_password'])){
 
-            $ftp = sprintf("%s%s:%s@%s%s", 
+        if (!empty($post['ftp_login']) && !empty($post['ftp_password'])){
+            $ftp = sprintf("%s%s:%s@%s%s",
                     $post['ftp_proto'],
                     $post['ftp_login'],
                     $post['ftp_password'],
                     $post['ftp_host'],
                     $post['ftp_path']
             );
-
         } elseif (!empty($post['ftp_login'])) {
-
-            $ftp = sprintf("%s%s@%s%s", $post['ftp_proto'], $post['ftp_login'],$post['ftp_host'],$post['ftp_path']);
-
+            $ftp = sprintf(
+                "%s%s@%s%s",
+                $post['ftp_proto'],
+                $post['ftp_login'],
+                $post['ftp_host'],
+                $post['ftp_path']
+            );
         } else {
             $ftp = $post['ftp_proto'] . $post['ftp_host'] . $post['ftp_path'];
         }
@@ -198,7 +199,6 @@ private function getFtpPost($post){
 
     /**
      * NoRoute
-     *
      */
     public function norouteAction()
     {
@@ -208,7 +208,6 @@ public function norouteAction()
 
     /**
      * Login
-     *
      */
     public function loginAction()
     {
@@ -218,7 +217,6 @@ public function loginAction()
 
     /**
      * Logout
-     *
      */
     public function logoutAction()
     {
@@ -228,14 +226,18 @@ public function logoutAction()
 
     /**
      * Index
-     *
      */
     public function indexAction()
     {
         $config = $this->config();
         if (!$this->isInstalled()) {
             $this->view()->set('mage_url', dirname(dirname($_SERVER['SCRIPT_NAME'])));
-            $this->view()->set('use_custom_permissions_mode', $config->__get('use_custom_permissions_mode')?$config->__get('use_custom_permissions_mode'):'0');
+            $this->view()->set(
+                'use_custom_permissions_mode',
+                $config->__get('use_custom_permissions_mode')
+                    ? $config->__get('use_custom_permissions_mode')
+                    : '0'
+            );
             $this->view()->set('mkdir_mode', decoct($config->__get('global_dir_mode')));
             $this->view()->set('chmod_file_mode', decoct($config->__get('global_file_mode')));
             $this->view()->set('protocol', $config->__get('protocol'));
@@ -252,21 +254,21 @@ public function indexAction()
 
     /**
      * Empty Action
-     *
      */
     public function emptyAction()
     {
-        $this->model('connect', true)->connect()->runHtmlConsole('Please wait, preparing for updates...');
+        $this->model('connect', true)
+            ->connect()
+            ->runHtmlConsole('Please wait, preparing for updates...');
     }
 
     /**
      * Install all magento
-     *
      */
     public function connectInstallAllAction()
     {
         $p = &$_POST;
-        $ftp = $this->getFtpPost($p);
+        $this->getFtpPost($p);
         $errors = $this->model('connect', true)->validateConfigPost($p);
         /* todo show errors */
         if ($errors) {
@@ -294,7 +296,6 @@ public function connectInstallAllAction()
 
     /**
      * Connect packages
-     *
      */
     public function connectPackagesAction()
     {
@@ -310,24 +311,26 @@ public function connectPackagesAction()
         if (!$this->isWritable() && empty($remoteConfig)) {
             $this->view()->set('writable_warning', true);
         }
-        
+
         echo $this->view()->template('connect/packages.phtml');
     }
 
     /**
      * Connect packages POST
-     *
      */
     public function connectPackagesPostAction()
     {
         $actions = isset($_POST['actions']) ? $_POST['actions'] : array();
-        $ignoreLocalModification = isset($_POST['ignore_local_modification'])?$_POST['ignore_local_modification']:'';
+        if (isset($_POST['ignore_local_modification'])) {
+            $ignoreLocalModification = $_POST['ignore_local_modification'];
+        } else {
+            $ignoreLocalModification = '';
+        }
         $this->model('connect', true)->applyPackagesActions($actions, $ignoreLocalModification);
     }
 
     /**
      * Prepare package to install, get dependency info.
-     *
      */
     public function connectPreparePackagePostAction()
     {
@@ -337,8 +340,8 @@ public function connectPreparePackagePostAction()
         }
         $prepareResult = $this->model('connect', true)->prepareToInstall($_POST['install_package_id']);
 
-        $packages = isset($prepareResult['data'])? $prepareResult['data']:array();
-        $errors = isset($prepareResult['errors'])? $prepareResult['errors']:array();
+        $packages   = isset($prepareResult['data']) ? $prepareResult['data'] : array();
+        $errors     = isset($prepareResult['errors']) ? $prepareResult['errors'] : array();
 
         $this->view()->set('packages', $packages);
         $this->view()->set('errors', $errors);
@@ -349,7 +352,6 @@ public function connectPreparePackagePostAction()
 
     /**
      * Install package
-     *
      */
     public function connectInstallPackagePostAction()
     {
@@ -362,7 +364,6 @@ public function connectInstallPackagePostAction()
 
     /**
      * Install uploaded package
-     *
      */
     public function connectInstallPackageUploadAction()
     {
@@ -388,7 +389,7 @@ public function connectInstallPackageUploadAction()
             return;
         }
 
-        $target = $this->_mageDir . DS . "var/".uniqid().$info['name'];
+        $target = $this->_mageDir . DS . "var/" . uniqid() . $info['name'];
         $res = move_uploaded_file($info['tmp_name'], $target);
         if(false === $res) {
             echo "Error moving uploaded file";
@@ -400,8 +401,16 @@ public function connectInstallPackageUploadAction()
     }
 
     /**
+     * Clean cache on ajax request
+     */
+    public function cleanCacheAction()
+    {
+        $result = $this->cleanCache(true);
+        echo json_encode($result);
+    }
+
+    /**
      * Settings
-     *
      */
     public function settingsAction()
     {
@@ -415,14 +424,14 @@ public function settingsAction()
 
         $this->channelConfig()->setSettingsView($this->session(), $this->view());
 
-        $fs_disabled=!$this->isWritable();
-        $ftpParams=$config->__get('remote_config')?@parse_url($config->__get('remote_config')):'';
+        $fs_disabled =! $this->isWritable();
+        $ftpParams = $config->__get('remote_config') ? @parse_url($config->__get('remote_config')) : '';
 
         $this->view()->set('fs_disabled', $fs_disabled);
-        $this->view()->set('deployment_type', ($fs_disabled||!empty($ftpParams)?'ftp':'fs'));
+        $this->view()->set('deployment_type', ($fs_disabled || !empty($ftpParams) ? 'ftp' : 'fs'));
 
-        if(!empty($ftpParams)){
-            $this->view()->set('ftp_host', sprintf("%s://%s",$ftpParams['scheme'],$ftpParams['host']));
+        if (!empty($ftpParams)) {
+            $this->view()->set('ftp_host', sprintf("%s://%s", $ftpParams['scheme'], $ftpParams['host']));
             $this->view()->set('ftp_login', $ftpParams['user']);
             $this->view()->set('ftp_password', $ftpParams['pass']);
             $this->view()->set('ftp_path', $ftpParams['path']);
@@ -432,12 +441,16 @@ public function settingsAction()
 
     /**
      * Settings post
-     *
      */
     public function settingsPostAction()
     {
         if ($_POST) {
-            $ftp=$this->getFtpPost($_POST);
+            $ftp = $this->getFtpPost($_POST);
+
+            /* clear startup messages */
+            $this->config();
+            $this->session()->getMessages();
+
             $errors = $this->model('connect', true)->validateConfigPost($_POST);
             if ($errors) {
                 foreach ($errors as $err) {
@@ -447,9 +460,9 @@ public function settingsPostAction()
                 return;
             }
             try {
-                if( 'ftp' == $_POST['deployment_type']&&!empty($_POST['ftp_host'])){
+                if ('ftp' == $_POST['deployment_type'] && !empty($_POST['ftp_host'])) {
                     $this->model('connect', true)->connect()->setRemoteConfig($ftp);
-                }else{
+                } else {
                     $this->model('connect', true)->connect()->setRemoteConfig('');
                     $_POST['ftp'] = '';
                 }
@@ -457,9 +470,8 @@ public function settingsPostAction()
                 $this->model('connect', true)->saveConfigPost($_POST);
                 $this->channelConfig()->setSettingsSession($_POST, $this->session());
                 $this->model('connect', true)->connect()->run('sync');
-
             } catch (Exception $e) {
-                $this->session()->addMessage('error', "Unable to save settings: ".$e->getMessage());
+                $this->session()->addMessage('error', "Unable to save settings: " . $e->getMessage());
             }
         }
         $this->redirect($this->url('settings'));
@@ -469,7 +481,6 @@ public function settingsPostAction()
 
     /**
      * Constructor
-     *
      */
     public function __construct()
     {
@@ -479,7 +490,6 @@ public function __construct()
 
     /**
      * Run
-     *
      */
     public static function run()
     {
@@ -502,7 +512,7 @@ public static function singleton()
             self::$_instance = new self;
 
             if (self::$_instance->isDownloaded() && self::$_instance->isInstalled()) {
-                Mage::app();
+                Mage::app('', 'store', array('global_ban_use_cache'=>true));
                 Mage::getSingleton('adminhtml/url')->turnOffSecretKey();
             }
         }
@@ -704,10 +714,10 @@ public function processRedirect()
     {
         if ($this->_redirectUrl) {
             if (headers_sent()) {
-                echo '<script type="text/javascript">location.href="'.$this->_redirectUrl.'"</script>';
+                echo '<script type="text/javascript">location.href="' . $this->_redirectUrl . '"</script>';
                 exit;
             } else {
-                header("Location: ".$this->_redirectUrl);
+                header("Location: " . $this->_redirectUrl);
                 exit;
             }
         }
@@ -735,7 +745,7 @@ public function forward($action)
      */
     public function getActionMethod($action = null)
     {
-        $method = (!is_null($action) ? $action : $this->_action).'Action';
+        $method = (!is_null($action) ? $action : $this->_action) . 'Action';
         return $method;
     }
 
@@ -758,7 +768,6 @@ public function url($action = '', $params = array())
 
     /**
      * Dispatch process
-     *
      */
     public function dispatch()
     {
@@ -767,7 +776,7 @@ public function dispatch()
         $this->setAction();
 
         if (!$this->isInstalled()) {
-            if (!in_array($this->getAction(), array('index', 'connectInstallAll', 'empty'))) {
+            if (!in_array($this->getAction(), array('index', 'connectInstallAll', 'empty', 'cleanCache'))) {
                 $this->setAction('index');
             }
         } else {
@@ -778,7 +787,6 @@ public function dispatch()
             $this->_isDispatched = true;
 
             $method = $this->getActionMethod();
-            //echo($method);exit();
             $this->$method();
         }
 
@@ -796,7 +804,6 @@ public function isWritable()
             $this->_writable = is_writable($this->getMageDir() . DIRECTORY_SEPARATOR)
                 && is_writable($this->filepath())
                 && (!file_exists($this->filepath('config.ini') || is_writable($this->filepath('config.ini'))));
-
         }
         return $this->_writable;
     }
@@ -860,21 +867,20 @@ protected function _getMaintenanceFilePath()
 
     /**
      * Begin install package(s)
-     *
      */
     public function startInstall()
     {
         if ($this->_getMaintenanceFlag()) {
             $maintenance_filename='maintenance.flag';
             $config = $this->config();
-            if(!$this->isWritable()||strlen($config->__get('remote_config'))>0){
+            if (!$this->isWritable() || strlen($config->__get('remote_config')) > 0) {
                 $ftpObj = new Mage_Connect_Ftp();
                 $ftpObj->connect($config->__get('remote_config'));
                 $tempFile = tempnam(sys_get_temp_dir(),'maintenance');
                 @file_put_contents($tempFile, 'maintenance');
-                $ret=$ftpObj->upload($maintenance_filename, $tempFile);
+                $ftpObj->upload($maintenance_filename, $tempFile);
                 $ftpObj->close();
-            }else{
+            } else {
                 @file_put_contents($this->_getMaintenanceFilePath(), 'maintenance');
             }
         }
@@ -882,38 +888,67 @@ public function startInstall()
 
     /**
      * End install package(s)
-     *
      */
     public function endInstall()
     {
-        if ($this->isInstalled()) {
-            try {
-                if (!empty($_GET['clean_sessions'])) {
-                    Mage::app()->cleanAllSessions();
+        //$connect
+        /** @var $connect Maged_Model_Connect */
+        $frontend = $this->model('connect', true)->connect()->getFrontend();
+        if (!($frontend instanceof Maged_Connect_Frontend)) {
+            $this->cleanCache();
+        }
+    }
+
+    /**
+     * Clean cache
+     *
+     * @param bool $validate
+     * @return array
+     */
+    protected function cleanCache($validate = false)
+    {
+        $result = true;
+        $message = '';
+        try {
+            if ($this->isInstalled()) {
+                if ($validate) {
+                    $result = $this->session()->validateCleanCacheKey();
+                }
+                if ($result) {
+                    if (!empty($_REQUEST['clean_sessions'])) {
+                        Mage::app()->cleanAllSessions();
+                        $message .= 'Session cleaned successfully. ';
+                    }
+                    Mage::app()->cleanCache();
+
+                    // reinit config and apply all updates
+                    Mage::app()->getConfig()->reinit();
+                    Mage_Core_Model_Resource_Setup::applyAllUpdates();
+                    Mage_Core_Model_Resource_Setup::applyAllDataUpdates();
+                    $message .= 'Cache cleaned successfully';
+                } else {
+                    $message .= 'Validation failed';
                 }
-                Mage::app()->cleanCache();
-            } catch (Exception $e) {
-                $this->session()->addMessage('error', "Exception during cache and session cleaning: ".$e->getMessage());
             }
-
-            // reinit config and apply all updates
-            Mage::app()->getConfig()->reinit();
-            Mage_Core_Model_Resource_Setup::applyAllUpdates();
-            Mage_Core_Model_Resource_Setup::applyAllDataUpdates();
+        } catch (Exception $e) {
+            $result = false;
+            $message = "Exception during cache and session cleaning: ".$e->getMessage();
+            $this->session()->addMessage('error', $message);
         }
 
-        if ($this->_getMaintenanceFlag()) {
+        if ($result && $this->_getMaintenanceFlag()) {
             $maintenance_filename='maintenance.flag';
             $config = $this->config();
-            if(!$this->isWritable()&&strlen($config->__get('remote_config'))>0){
+            if (!$this->isWritable() && strlen($config->__get('remote_config')) > 0) {
                 $ftpObj = new Mage_Connect_Ftp();
                 $ftpObj->connect($config->__get('remote_config'));
                 $ftpObj->delete($maintenance_filename);
                 $ftpObj->close();
-            }else{
+            } else {
                 @unlink($this->_getMaintenanceFilePath());
             }
         }
+        return array('result' => $result, 'message' => $message);
     }
 
     /**
@@ -925,7 +960,12 @@ public function endInstall()
     public static function getVersion()
     {
         $i = self::getVersionInfo();
-        return trim("{$i['major']}.{$i['minor']}.{$i['revision']}" . ($i['patch'] != '' ? ".{$i['patch']}" : "") . "-{$i['stability']}{$i['number']}", '.-');
+        return trim(
+            "{$i['major']}.{$i['minor']}.{$i['revision']}"
+                . ($i['patch'] != '' ? ".{$i['patch']}" : "")
+                . "-{$i['stability']}{$i['number']}",
+            '.-'
+        );
     }
 
     /**
diff --git downloader/Maged/Model/Session.php downloader/Maged/Model/Session.php
index b9168de..482abe2 100644
--- downloader/Maged/Model/Session.php
+++ downloader/Maged/Model/Session.php
@@ -34,19 +34,18 @@
 */
 class Maged_Model_Session extends Maged_Model
 {
-
     /**
-    * Session
-    *
-    * @var Mage_Admin_Model_Session
-    */
+     * Session
+     *
+     * @var Mage_Admin_Model_Session
+     */
     protected $_session;
 
     /**
-    * Init session
-    *
-    * @return Maged_Model_Session
-    */
+     * Init session
+     *
+     * @return Maged_Model_Session
+     */
     public function start()
     {
         if (class_exists('Mage') && Mage::isInstalled()) {
@@ -60,22 +59,22 @@ public function start()
     }
 
     /**
-    * Get value by key
-    *
-    * @param string $key
-    * @return mixed
-    */
+     * Get value by key
+     *
+     * @param string $key
+     * @return mixed
+     */
     public function get($key)
     {
         return isset($_SESSION[$key]) ? $_SESSION[$key] : null;
     }
 
     /**
-    * Set value for key
-    *
-    * @param string $key
-    * @param mixed $value
-    */
+     * Set value for key
+     *
+     * @param string $key
+     * @param mixed $value
+     */
     public function set($key, $value)
     {
         $_SESSION[$key] = $value;
@@ -83,8 +82,22 @@ public function set($key, $value)
     }
 
     /**
-    * Authentication to downloader
-    */
+     * Unset value by key
+     *
+     * @param string $key
+     * @return $this
+     */
+    public function delete($key)
+    {
+        if (isset($_SESSION[$key])) {
+            unset($_SESSION[$key]);
+        }
+        return $this;
+    }
+
+    /**
+     * Authentication to downloader
+     */
     public function authenticate()
     {
         if (!$this->_session) {
@@ -95,7 +108,7 @@ public function authenticate()
             $this->set('return_url', $_GET['return']);
         }
 
-        if ($this->getUserId()) {
+        if ($this->_checkUserAccess()) {
             return $this;
         }
 
@@ -104,40 +117,58 @@ public function authenticate()
         }
 
         try {
-            if ( (isset($_POST['username']) && empty($_POST['username'])) ||
-                 (isset($_POST['password']) && empty($_POST['password'])))
-            {
+            if ( (isset($_POST['username']) && empty($_POST['username']))
+                || (isset($_POST['password']) && empty($_POST['password']))) {
                 $this->addMessage('error', 'Invalid user name or password');
             }
             if (empty($_POST['username']) || empty($_POST['password'])) {
                 $this->controller()->setAction('login');
                 return $this;
             }
-
             $user = $this->_session->login($_POST['username'], $_POST['password']);
             $this->_session->refreshAcl();
-
-            if (!$user->getId() || !$this->_session->isAllowed('all')) {
-                $this->addMessage('error', 'Invalid user name or password');
-                $this->controller()->setAction('login');
+            if ($this->_checkUserAccess($user)) {
                 return $this;
             }
-
         } catch (Exception $e) {
-
             $this->addMessage('error', $e->getMessage());
-
         }
 
         $this->controller()
-            ->redirect($this->controller()->url($this->controller()->getAction()).'&loggedin', true);
+            ->redirect(
+                $this->controller()->url('loggedin'),
+                true
+        );
     }
 
     /**
-    * Log Out
-    *
-    * @return Maged_Model_Session
-    */
+     * Check is user logged in and permissions
+     *
+     * @param Mage_Admin_Model_User|null $user
+     * @return bool
+     */
+    protected function _checkUserAccess($user = null)
+    {
+        if ($user && !$user->getId()) {
+            $this->addMessage('error', 'Invalid user name or password');
+            $this->controller()->setAction('login');
+        } elseif ($this->getUserId() || ($user && $user->getId())) {
+            if ($this->_session->isAllowed('all')) {
+                return true;
+            } else {
+                $this->logout();
+                $this->addMessage('error', 'Access Denied', true);
+                $this->controller()->setAction('login');
+            }
+        }
+        return false;
+    }
+
+    /**
+     * Log Out
+     *
+     * @return Maged_Model_Session
+     */
     public function logout()
     {
         if (!$this->_session) {
@@ -148,36 +179,40 @@ public function logout()
     }
 
     /**
-    * Retrieve user
-    *
-    * @return mixed
-    */
+     * Retrieve user
+     *
+     * @return mixed
+     */
     public function getUserId()
     {
-        return ($session = $this->_session) && ($user = $session->getUser()) ? $user->getId() : false;
+        if (($session = $this->_session) && ($user = $session->getUser())) {
+            return $user->getId();
+        }
+        return false;
     }
 
     /**
-    * Add Message
-    *
-    * @param string $type
-    * @param string $msg
-    * @return Maged_Model_Session
-    */
-    public function addMessage($type, $msg)
+     * Add Message
+     *
+     * @param string $type
+     * @param string $msg
+     * @param string $clear
+     * @return Maged_Model_Session
+     */
+    public function addMessage($type, $msg, $clear = false)
     {
-        $msgs = $this->getMessages(false);
+        $msgs = $this->getMessages($clear);
         $msgs[$type][] = $msg;
         $this->set('messages', $msgs);
         return $this;
     }
 
     /**
-    * Retrieve messages from cache
-    *
-    * @param boolean $clear
-    * @return mixed
-    */
+     * Retrieve messages from cache
+     *
+     * @param boolean $clear
+     * @return mixed
+     */
     public function getMessages($clear = true)
     {
         $msgs = $this->get('messages');
@@ -189,10 +224,10 @@ public function getMessages($clear = true)
     }
 
     /**
-    * Retrieve url to adminhtml
-    *
-    * @return string
-    */
+     * Retrieve url to adminhtml
+     *
+     * @return string
+     */
     public function getReturnUrl()
     {
         if (!$this->_session || !$this->_session->isLoggedIn()) {
@@ -213,4 +248,24 @@ public function getFormKey()
         }
         return $this->get('_form_key');
     }
+
+    /**
+     * Validate key for cache cleaning
+     *
+     * @return bool
+     */
+    public function validateCleanCacheKey()
+    {
+        $result = false;
+        $validateKey = $this->get('validate_cache_key');
+        if ($validateKey
+            && !empty($_REQUEST['validate_cache_key'])
+            && $validateKey == $_REQUEST['validate_cache_key']
+        ) {
+            $result = true;
+        }
+        $this->delete('validate_cache_key');
+
+        return $result;
+    }
 }
diff --git js/varien/payment.js js/varien/payment.js
index 18de720..7dfa7ae 100644
--- js/varien/payment.js
+++ js/varien/payment.js
@@ -31,7 +31,7 @@ paymentForm.prototype = {
 
         var method = null;
         for (var i=0; i<elements.length; i++) {
-            if (elements[i].name=='payment[method]') {
+            if (elements[i].name=='payment[method]' || elements[i].name=='form_key') {
                 if (elements[i].checked) {
                     method = elements[i].value;
                 }
diff --git skin/frontend/base/default/js/opcheckout.js skin/frontend/base/default/js/opcheckout.js
index 146a7ed..fe94e9b 100644
--- skin/frontend/base/default/js/opcheckout.js
+++ skin/frontend/base/default/js/opcheckout.js
@@ -634,7 +634,7 @@ Payment.prototype = {
         }
         var method = null;
         for (var i=0; i<elements.length; i++) {
-            if (elements[i].name=='payment[method]') {
+            if (elements[i].name=='payment[method]' || elements[i].name == 'form_key') {
                 if (elements[i].checked) {
                     method = elements[i].value;
                 }
