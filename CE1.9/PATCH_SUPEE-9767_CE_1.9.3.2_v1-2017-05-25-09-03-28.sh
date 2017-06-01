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


PATCH_SUPEE-9767_CE_1.9.3.2_v1.sh | CE_1.9.3.2 | v1 | 226caf7 | Mon Feb 20 17:33:39 2017 +0200 | 2321b14

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Admin/Model/Session.php app/code/core/Mage/Admin/Model/Session.php
index c5169a9..494acdd 100644
--- app/code/core/Mage/Admin/Model/Session.php
+++ app/code/core/Mage/Admin/Model/Session.php
@@ -138,6 +138,9 @@ class Mage_Admin_Model_Session extends Mage_Core_Model_Session_Abstract
                 Mage::throwException(Mage::helper('adminhtml')->__('Invalid User Name or Password.'));
             }
         } catch (Mage_Core_Exception $e) {
+            $e->setMessage(
+                Mage::helper('adminhtml')->__('You did not sign in correctly or your account is temporarily disabled.')
+            );
             Mage::dispatchEvent('admin_session_user_login_failed',
                 array('user_name' => $username, 'exception' => $e));
             if ($request && !$request->getParam('messageSent')) {
diff --git app/code/core/Mage/Adminhtml/Block/Checkout/Formkey.php app/code/core/Mage/Adminhtml/Block/Checkout/Formkey.php
new file mode 100644
index 0000000..bd57adb
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Block/Checkout/Formkey.php
@@ -0,0 +1,52 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
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
+ * @package     Mage_Admin
+ * @copyright Copyright (c) 2006-2017 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
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
index 0000000..0d66846
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Block/Notification/Symlink.php
@@ -0,0 +1,36 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
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
+ * @package     Mage_Admin
+ * @copyright Copyright (c) 2006-2017 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
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
index c24e468..daecfdd 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Date.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Date.php
@@ -146,11 +146,11 @@ class Mage_Adminhtml_Block_Widget_Grid_Column_Filter_Date
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
diff --git app/code/core/Mage/Adminhtml/Model/Config/Data.php app/code/core/Mage/Adminhtml/Model/Config/Data.php
index 892a29b..3b6a30d 100644
--- app/code/core/Mage/Adminhtml/Model/Config/Data.php
+++ app/code/core/Mage/Adminhtml/Model/Config/Data.php
@@ -167,6 +167,9 @@ class Mage_Adminhtml_Model_Config_Data extends Varien_Object
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
index 5492779..eaf9174 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/Product/GalleryController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/Product/GalleryController.php
@@ -42,6 +42,11 @@ class Mage_Adminhtml_Catalog_Product_GalleryController extends Mage_Adminhtml_Co
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
index 5ffa17a..7eec9f8 100644
--- app/code/core/Mage/Checkout/controllers/MultishippingController.php
+++ app/code/core/Mage/Checkout/controllers/MultishippingController.php
@@ -233,6 +233,12 @@ class Mage_Checkout_MultishippingController extends Mage_Checkout_Controller_Act
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
@@ -353,6 +359,11 @@ class Mage_Checkout_MultishippingController extends Mage_Checkout_Controller_Act
      */
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
@@ -462,6 +473,11 @@ class Mage_Checkout_MultishippingController extends Mage_Checkout_Controller_Act
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
index d927dcd..a321607 100644
--- app/code/core/Mage/Checkout/controllers/OnepageController.php
+++ app/code/core/Mage/Checkout/controllers/OnepageController.php
@@ -349,6 +349,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
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
@@ -364,6 +369,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         if ($this->_expireAjax()) {
             return;
         }
+
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
+            return;
+        }
+
         if ($this->getRequest()->isPost()) {
             $data = $this->getRequest()->getPost('billing', array());
             $customerAddressId = $this->getRequest()->getPost('billing_address_id', false);
@@ -406,6 +416,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
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
@@ -430,6 +445,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
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
@@ -464,6 +484,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
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
index 674a424..d2c05ac 100644
--- app/code/core/Mage/Checkout/etc/system.xml
+++ app/code/core/Mage/Checkout/etc/system.xml
@@ -232,5 +232,23 @@
                 </payment_failed>
             </groups>
         </checkout>
+        <admin>
+            <groups>
+                <security>
+                    <fields>
+                        <validate_formkey_checkout translate="label comment">
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
index 3ab7d82..bbcdff2 100644
--- app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
+++ app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
@@ -283,6 +283,11 @@ class Mage_Cms_Model_Wysiwyg_Images_Storage extends Varien_Object
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
index 4777658..f0bcaa3 100644
--- app/code/core/Mage/Core/Controller/Front/Action.php
+++ app/code/core/Mage/Core/Controller/Front/Action.php
@@ -188,4 +188,14 @@ class Mage_Core_Controller_Front_Action extends Mage_Core_Controller_Varien_Acti
     {
         return Mage::getStoreConfigFlag(self::XML_CSRF_USE_FLAG_CONFIG_PATH);
     }
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
 }
diff --git app/code/core/Mage/Core/Controller/Request/Http.php app/code/core/Mage/Core/Controller/Request/Http.php
index 754f579..cfd26df 100644
--- app/code/core/Mage/Core/Controller/Request/Http.php
+++ app/code/core/Mage/Core/Controller/Request/Http.php
@@ -148,7 +148,10 @@ class Mage_Core_Controller_Request_Http extends Zend_Controller_Request_Http
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
diff --git app/code/core/Mage/Core/Model/File/Validator/Image.php app/code/core/Mage/Core/Model/File/Validator/Image.php
index 06fa6b1..717fd4d 100644
--- app/code/core/Mage/Core/Model/File/Validator/Image.php
+++ app/code/core/Mage/Core/Model/File/Validator/Image.php
@@ -88,10 +88,33 @@ class Mage_Core_Model_File_Validator_Image
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
@@ -106,5 +129,4 @@ class Mage_Core_Model_File_Validator_Image
     {
         return in_array($nImageType, $this->_allowedImageTypes);
     }
-
 }
diff --git app/code/core/Mage/Core/etc/system.xml app/code/core/Mage/Core/etc/system.xml
index fade9c6..8deab15 100644
--- app/code/core/Mage/Core/etc/system.xml
+++ app/code/core/Mage/Core/etc/system.xml
@@ -597,26 +597,6 @@
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
diff --git app/code/core/Mage/Dataflow/Model/Convert/Adapter/Zend/Cache.php app/code/core/Mage/Dataflow/Model/Convert/Adapter/Zend/Cache.php
index 74e63e0..759b1bb 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Adapter/Zend/Cache.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Adapter/Zend/Cache.php
@@ -40,6 +40,9 @@ class Mage_Dataflow_Model_Convert_Adapter_Zend_Cache extends Mage_Dataflow_Model
         if (!$this->_resource) {
             $this->_resource = Zend_Cache::factory($this->getVar('frontend', 'Core'), $this->getVar('backend', 'File'));
         }
+        if ($this->_resource->getBackend() instanceof Zend_Cache_Backend_Static) {
+            throw new Exception(Mage::helper('dataflow')->__('Backend name "Static" not supported.'));
+        }
         return $this->_resource;
     }
 
diff --git app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
index 227dba6..cc0cad8 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
@@ -47,6 +47,18 @@ abstract class Mage_Dataflow_Model_Convert_Container_Abstract
 
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
@@ -102,13 +114,45 @@ abstract class Mage_Dataflow_Model_Convert_Container_Abstract
 
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
@@ -140,7 +184,10 @@ abstract class Mage_Dataflow_Model_Convert_Container_Abstract
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
index ce847f3..1f0aef4 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
@@ -62,13 +62,15 @@ class Mage_Dataflow_Model_Convert_Parser_Csv extends Mage_Dataflow_Model_Convert
             $adapter = Mage::getModel($adapterName);
         }
         catch (Exception $e) {
-            $message = Mage::helper('dataflow')->__('Declared adapter %s was not found.', $adapterName);
+            $message = Mage::helper('dataflow')
+                ->__('Declared adapter %s was not found.', $adapterName);
             $this->addException($message, Mage_Dataflow_Model_Convert_Exception::FATAL);
             return $this;
         }
 
         if (!method_exists($adapter, $adapterMethod)) {
-            $message = Mage::helper('dataflow')->__('Method "%s" not defined in adapter %s.', $adapterMethod, $adapterName);
+            $message = Mage::helper('dataflow')
+                ->__('Method "%s" not defined in adapter %s.', $adapterMethod, $adapterName);
             $this->addException($message, Mage_Dataflow_Model_Convert_Exception::FATAL);
             return $this;
         }
@@ -77,8 +79,8 @@ class Mage_Dataflow_Model_Convert_Parser_Csv extends Mage_Dataflow_Model_Convert
         $batchIoAdapter = $this->getBatchModel()->getIoAdapter();
 
         if (Mage::app()->getRequest()->getParam('files')) {
-            $file = Mage::app()->getConfig()->getTempVarDir().'/import/'
-                . urldecode(Mage::app()->getRequest()->getParam('files'));
+            $file = Mage::app()->getConfig()->getTempVarDir() . '/import/'
+                . str_replace('../', '', urldecode(Mage::app()->getRequest()->getParam('files')));
             $this->_copy($file);
         }
 
diff --git app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php
index 007eeb3..5a958b4 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php
@@ -69,7 +69,8 @@ class Mage_Dataflow_Model_Convert_Parser_Xml_Excel extends Mage_Dataflow_Model_C
         }
 
         if (!method_exists($adapter, $adapterMethod)) {
-            $message = Mage::helper('dataflow')->__('Method "%s" was not defined in adapter %s.', $adapterMethod, $adapterName);
+            $message = Mage::helper('dataflow')
+                ->__('Method "%s" was not defined in adapter %s.', $adapterMethod, $adapterName);
             $this->addException($message, Mage_Dataflow_Model_Convert_Exception::FATAL);
             return $this;
         }
@@ -78,8 +79,8 @@ class Mage_Dataflow_Model_Convert_Parser_Xml_Excel extends Mage_Dataflow_Model_C
         $batchIoAdapter = $this->getBatchModel()->getIoAdapter();
 
         if (Mage::app()->getRequest()->getParam('files')) {
-            $file = Mage::app()->getConfig()->getTempVarDir().'/import/'
-                . urldecode(Mage::app()->getRequest()->getParam('files'));
+            $file = Mage::app()->getConfig()->getTempVarDir() . '/import/'
+                . str_replace('../', '', urldecode(Mage::app()->getRequest()->getParam('files')));
             $this->_copy($file);
         }
 
diff --git app/code/core/Mage/ImportExport/Model/Import/Uploader.php app/code/core/Mage/ImportExport/Model/Import/Uploader.php
index 134885f..ca8155a 100644
--- app/code/core/Mage/ImportExport/Model/Import/Uploader.php
+++ app/code/core/Mage/ImportExport/Model/Import/Uploader.php
@@ -61,6 +61,11 @@ class Mage_ImportExport_Model_Import_Uploader extends Mage_Core_Model_File_Uploa
         $this->setAllowedExtensions(array_keys($this->_allowedMimeTypes));
         $this->addValidateCallback('catalog_product_image',
                 Mage::helper('catalog/image'), 'validateUploadFile');
+        $this->addValidateCallback(
+            Mage_Core_Model_File_Validator_Image::NAME,
+            Mage::getModel('core/file_validator_image'),
+            'validate'
+        );
         $this->_uploadType = self::SINGLE_STYLE;
     }
 
diff --git app/code/core/Mage/Sales/Model/Quote/Item.php app/code/core/Mage/Sales/Model/Quote/Item.php
index 63e24f3..2fb21db 100644
--- app/code/core/Mage/Sales/Model/Quote/Item.php
+++ app/code/core/Mage/Sales/Model/Quote/Item.php
@@ -500,8 +500,9 @@ class Mage_Sales_Model_Quote_Item extends Mage_Sales_Model_Quote_Item_Abstract
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
index eb145c9..1afd451 100644
--- app/code/core/Mage/Widget/Model/Widget/Instance.php
+++ app/code/core/Mage/Widget/Model/Widget/Instance.php
@@ -347,7 +347,11 @@ class Mage_Widget_Model_Widget_Instance extends Mage_Core_Model_Abstract
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
         return (is_array($this->getData('widget_parameters'))) ? $this->getData('widget_parameters') : array();
     }
diff --git app/code/core/Mage/XmlConnect/Helper/Image.php app/code/core/Mage/XmlConnect/Helper/Image.php
index 6a5f6e2..8a8388b 100644
--- app/code/core/Mage/XmlConnect/Helper/Image.php
+++ app/code/core/Mage/XmlConnect/Helper/Image.php
@@ -100,6 +100,11 @@ class Mage_XmlConnect_Helper_Image extends Mage_Core_Helper_Abstract
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
diff --git app/code/core/Mage/XmlConnect/controllers/Adminhtml/MobileController.php app/code/core/Mage/XmlConnect/controllers/Adminhtml/MobileController.php
index 851d317..f3eb6d8 100644
--- app/code/core/Mage/XmlConnect/controllers/Adminhtml/MobileController.php
+++ app/code/core/Mage/XmlConnect/controllers/Adminhtml/MobileController.php
@@ -567,7 +567,7 @@ class Mage_XmlConnect_Adminhtml_MobileController extends Mage_Adminhtml_Controll
                 $result = $themesHelper->deleteTheme($themeId);
                 if ($result) {
                     $response = array(
-                        'message'   => $this->__('Theme has been delete.'),
+                        'message'   => $this->__('Theme has been deleted.'),
                         'themes'    => $themesHelper->getAllThemesArray(true),
                         'themeSelector' => $themesHelper->getThemesSelector(),
                         'selectedTheme' => $themesHelper->getDefaultThemeName()
@@ -1393,6 +1393,11 @@ class Mage_XmlConnect_Adminhtml_MobileController extends Mage_Adminhtml_Controll
             /** @var $uploader Mage_Core_Model_File_Uploader */
             $uploader = Mage::getModel('core/file_uploader', $imageModel->getImageType());
             $uploader->setAllowRenameFiles(true)->setAllowedExtensions(array('jpg', 'jpeg', 'gif', 'png'));
+            $uploader->addValidateCallback(
+                Mage_Core_Model_File_Validator_Image::NAME,
+                Mage::getModel('core/file_validator_image'),
+                'validate'
+            );
             $result = $uploader->save(Mage_XmlConnect_Model_Images::getBasePath(), $newFileName);
             $result['thumbnail'] = Mage::getModel('xmlconnect/images')->getCustomSizeImageUrl(
                 $result['file'],
diff --git app/design/adminhtml/default/default/layout/main.xml app/design/adminhtml/default/default/layout/main.xml
index f638943..48ae4f0 100644
--- app/design/adminhtml/default/default/layout/main.xml
+++ app/design/adminhtml/default/default/layout/main.xml
@@ -119,7 +119,8 @@ Default layout, loads most of the pages
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
index 0000000..3798465
--- /dev/null
+++ app/design/adminhtml/default/default/template/notification/formkey.phtml
@@ -0,0 +1,38 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
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
+ * @package     Mage_Admin
+ * @copyright Copyright (c) 2006-2017 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
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
index 0000000..a3b7df2
--- /dev/null
+++ app/design/adminhtml/default/default/template/notification/symlink.phtml
@@ -0,0 +1,34 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
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
+ * @package     Mage_Admin
+ * @copyright Copyright (c) 2006-2017 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
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
index 2002a11..e195b25 100644
--- app/design/adminhtml/default/default/template/page/head.phtml
+++ app/design/adminhtml/default/default/template/page/head.phtml
@@ -33,7 +33,7 @@
     var BLANK_URL = '<?php echo $this->getJsUrl() ?>blank.html';
     var BLANK_IMG = '<?php echo $this->getJsUrl() ?>spacer.gif';
     var BASE_URL = '<?php echo $this->getUrl('*') ?>';
-    var SKIN_URL = '<?php echo $this->getSkinUrl() ?>';
+    var SKIN_URL = '<?php echo $this->jsQuoteEscape($this->getSkinUrl()) ?>';
     var FORM_KEY = '<?php echo $this->getFormKey() ?>';
 </script>
 
diff --git app/design/frontend/base/default/template/checkout/cart/shipping.phtml app/design/frontend/base/default/template/checkout/cart/shipping.phtml
index 5e6404f..1510c22 100644
--- app/design/frontend/base/default/template/checkout/cart/shipping.phtml
+++ app/design/frontend/base/default/template/checkout/cart/shipping.phtml
@@ -109,6 +109,7 @@
             <div class="buttons-set">
                 <button type="submit" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Update Total')) ?>" class="button" name="do" value="<?php echo Mage::helper('core')->quoteEscape($this->__('Update Total')) ?>"><span><span><?php echo $this->__('Update Total') ?></span></span></button>
             </div>
+            <?php echo $this->getBlockHtml('formkey') ?>
         </form>
         <?php endif; ?>
         <script type="text/javascript">
diff --git app/design/frontend/base/default/template/checkout/multishipping/billing.phtml app/design/frontend/base/default/template/checkout/multishipping/billing.phtml
index f5b4d2a..3b7635a 100644
--- app/design/frontend/base/default/template/checkout/multishipping/billing.phtml
+++ app/design/frontend/base/default/template/checkout/multishipping/billing.phtml
@@ -91,6 +91,7 @@
             <p class="back-link"><a href="<?php echo $this->getBackUrl() ?>"><small>&laquo; </small><?php echo $this->__('Back to Shipping Information') ?></a></p>
             <button id="payment-continue" type="submit" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Continue to Review Your Order')) ?>" class="button"><span><span><?php echo $this->__('Continue to Review Your Order') ?></span></span></button>
         </div>
+        <?php echo $this->getBlockHtml('formkey') ?>
     </form>
     <script type="text/javascript">
     //<![CDATA[
diff --git app/design/frontend/base/default/template/checkout/multishipping/shipping.phtml app/design/frontend/base/default/template/checkout/multishipping/shipping.phtml
index f8a26b0..c3dd185 100644
--- app/design/frontend/base/default/template/checkout/multishipping/shipping.phtml
+++ app/design/frontend/base/default/template/checkout/multishipping/shipping.phtml
@@ -126,5 +126,6 @@
             <p class="back-link"><a href="<?php echo $this->getBackUrl() ?>"><small>&laquo; </small><?php echo $this->__('Back to Select Addresses') ?></a></p>
             <button data-action="checkout-continue-billing" type="submit" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Continue to Billing Information')) ?>" class="button"><span><span><?php echo $this->__('Continue to Billing Information') ?></span></span></button>
         </div>
+        <?php echo $this->getBlockHtml('formkey') ?>
     </form>
 </div>
diff --git app/design/frontend/base/default/template/checkout/onepage/billing.phtml app/design/frontend/base/default/template/checkout/onepage/billing.phtml
index 7243151..143b02d 100644
--- app/design/frontend/base/default/template/checkout/onepage/billing.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/billing.phtml
@@ -201,6 +201,7 @@
             <img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="<?php echo Mage::helper('core')->quoteEscape($this->__('Loading next step...')) ?>" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Loading next step...')) ?>" class="v-middle" /> <?php echo $this->__('Loading next step...') ?>
         </span>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </fieldset>
 </form>
 <script type="text/javascript">
diff --git app/design/frontend/base/default/template/checkout/onepage/payment.phtml app/design/frontend/base/default/template/checkout/onepage/payment.phtml
index 93b63d8..cfe2910 100644
--- app/design/frontend/base/default/template/checkout/onepage/payment.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/payment.phtml
@@ -36,6 +36,7 @@
 <form action="" id="co-payment-form">
     <fieldset>
         <?php echo $this->getChildHtml('methods') ?>
+        <?php echo $this->getBlockHtml('formkey') ?>
     </fieldset>
 </form>
 <div class="tool-tip" id="payment-tool-tip" style="display:none;">
diff --git app/design/frontend/base/default/template/checkout/onepage/shipping.phtml app/design/frontend/base/default/template/checkout/onepage/shipping.phtml
index 78d2be3..65ca74d 100644
--- app/design/frontend/base/default/template/checkout/onepage/shipping.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/shipping.phtml
@@ -141,6 +141,7 @@
             <img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="<?php echo Mage::helper('core')->quoteEscape($this->__('Loading next step...')) ?>" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Loading next step...')) ?>" class="v-middle" /> <?php echo $this->__('Loading next step...') ?>
         </span>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </form>
 <script type="text/javascript">
 //<![CDATA[
diff --git app/design/frontend/base/default/template/checkout/onepage/shipping_method.phtml app/design/frontend/base/default/template/checkout/onepage/shipping_method.phtml
index b5d6d0b..3283884 100644
--- app/design/frontend/base/default/template/checkout/onepage/shipping_method.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/shipping_method.phtml
@@ -43,4 +43,5 @@
             <img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="<?php echo Mage::helper('core')->quoteEscape($this->__('Loading next step...')) ?>" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Loading next step...')) ?>" class="v-middle" /> <?php echo $this->__('Loading next step...') ?>
         </span>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </form>
diff --git app/design/frontend/base/default/template/persistent/checkout/onepage/billing.phtml app/design/frontend/base/default/template/persistent/checkout/onepage/billing.phtml
index 420fbc8..09af46f 100644
--- app/design/frontend/base/default/template/persistent/checkout/onepage/billing.phtml
+++ app/design/frontend/base/default/template/persistent/checkout/onepage/billing.phtml
@@ -199,6 +199,7 @@
             <img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="<?php echo Mage::helper('core')->quoteEscape($this->__('Loading next step...')) ?>" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Loading next step...')) ?>" class="v-middle" /> <?php echo $this->__('Loading next step...') ?>
         </span>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </fieldset>
 </form>
 <script type="text/javascript">
diff --git app/design/frontend/rwd/default/layout/page.xml app/design/frontend/rwd/default/layout/page.xml
index 0a60a3b..0c9811e 100644
--- app/design/frontend/rwd/default/layout/page.xml
+++ app/design/frontend/rwd/default/layout/page.xml
@@ -36,7 +36,7 @@
 
             <block type="page/html_head" name="head" as="head">
                 <action method="addJs"><script>prototype/prototype.js</script></action>
-                <action method="addJs"><script>lib/jquery/jquery-1.10.2.min.js</script></action>
+                <action method="addJs"><script>lib/jquery/jquery-1.12.0.min.js</script></action>
                 <action method="addJs"><script>lib/jquery/noconflict.js</script></action>
                 <action method="addJs"><script>lib/ccard.js</script></action>
                 <action method="addJs"><script>prototype/validation.js</script></action>
diff --git app/design/frontend/rwd/default/template/checkout/cart/shipping.phtml app/design/frontend/rwd/default/template/checkout/cart/shipping.phtml
index d47c680..7efe6bc 100644
--- app/design/frontend/rwd/default/template/checkout/cart/shipping.phtml
+++ app/design/frontend/rwd/default/template/checkout/cart/shipping.phtml
@@ -120,6 +120,7 @@
                     <span><span><?php echo $this->__('Update Total') ?></span></span>
                 </button>
             </div>
+            <?php echo $this->getBlockHtml('formkey') ?>
         </form>
         <?php endif; ?>
         <script type="text/javascript">
diff --git app/design/frontend/rwd/default/template/checkout/multishipping/addresses.phtml app/design/frontend/rwd/default/template/checkout/multishipping/addresses.phtml
index 60e4edf..c4084cd 100644
--- app/design/frontend/rwd/default/template/checkout/multishipping/addresses.phtml
+++ app/design/frontend/rwd/default/template/checkout/multishipping/addresses.phtml
@@ -84,4 +84,5 @@
             <button type="submit" data-action="checkout-continue-shipping" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Continue to Shipping Information')) ?>" class="button<?php if ($this->isContinueDisabled()):?> disabled<?php endif; ?>" onclick="$('can_continue_flag').value=1"<?php if ($this->isContinueDisabled()):?> disabled="disabled"<?php endif; ?>><span><span><?php echo $this->__('Continue to Shipping Information') ?></span></span></button>
         </div>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </form>
diff --git app/design/frontend/rwd/default/template/checkout/multishipping/billing.phtml app/design/frontend/rwd/default/template/checkout/multishipping/billing.phtml
index 1a73687..307ff50 100644
--- app/design/frontend/rwd/default/template/checkout/multishipping/billing.phtml
+++ app/design/frontend/rwd/default/template/checkout/multishipping/billing.phtml
@@ -93,6 +93,7 @@
             <p class="back-link"><a href="<?php echo $this->getBackUrl() ?>"><small>&laquo; </small><?php echo $this->__('Back to Shipping Information') ?></a></p>
             <button id="payment-continue" type="submit" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Continue to Review Your Order')) ?>" class="button"><span><span><?php echo $this->__('Continue to Review Your Order') ?></span></span></button>
         </div>
+        <?php echo $this->getBlockHtml('formkey') ?>
     </form>
     <script type="text/javascript">
     //<![CDATA[
diff --git app/design/frontend/rwd/default/template/checkout/onepage/payment.phtml app/design/frontend/rwd/default/template/checkout/onepage/payment.phtml
index 75480bc..35e0211 100644
--- app/design/frontend/rwd/default/template/checkout/onepage/payment.phtml
+++ app/design/frontend/rwd/default/template/checkout/onepage/payment.phtml
@@ -37,6 +37,7 @@
     <div class="fieldset">
         <?php echo $this->getChildChildHtml('methods_additional', '', true, true) ?>
         <?php echo $this->getChildHtml('methods') ?>
+        <?php echo $this->getBlockHtml('formkey') ?>
     </div>
 </form>
 <div class="tool-tip" id="payment-tool-tip" style="display:none;">
diff --git app/design/frontend/rwd/default/template/checkout/onepage/shipping.phtml app/design/frontend/rwd/default/template/checkout/onepage/shipping.phtml
index 007fcca..c8dc3ac 100644
--- app/design/frontend/rwd/default/template/checkout/onepage/shipping.phtml
+++ app/design/frontend/rwd/default/template/checkout/onepage/shipping.phtml
@@ -142,6 +142,7 @@
             <img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="<?php echo Mage::helper('core')->quoteEscape($this->__('Loading next step...')) ?>" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Loading next step...')) ?>" class="v-middle" /> <?php echo $this->__('Loading next step...') ?>
         </span>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </form>
 <script type="text/javascript">
 //<![CDATA[
diff --git app/design/frontend/rwd/default/template/persistent/checkout/onepage/billing.phtml app/design/frontend/rwd/default/template/persistent/checkout/onepage/billing.phtml
index 6681c65..1b85197 100644
--- app/design/frontend/rwd/default/template/persistent/checkout/onepage/billing.phtml
+++ app/design/frontend/rwd/default/template/persistent/checkout/onepage/billing.phtml
@@ -201,6 +201,7 @@
             <img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="<?php echo $this->quoteEscape($this->__('Loading next step...')) ?>" title="<?php echo $this->quoteEscape($this->__('Loading next step...')) ?>" class="v-middle" /> <?php echo $this->__('Loading next step...') ?>
         </span>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </div>
 </form>
 <script type="text/javascript">
diff --git app/etc/config.xml app/etc/config.xml
index 47d78f7..590f7a3 100644
--- app/etc/config.xml
+++ app/etc/config.xml
@@ -141,6 +141,11 @@
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
index 271b417..8b183b1 100644
--- app/locale/en_US/Mage_Adminhtml.csv
+++ app/locale/en_US/Mage_Adminhtml.csv
@@ -1287,3 +1287,5 @@
 "to","to"
 "website(%s) scope","website(%s) scope"
 "{{base_url}} is not recommended to use in a production environment to declare the Base Unsecure URL / Base Secure URL. It is highly recommended to change this value in your Magento <a href=""%s"">configuration</a>.","{{base_url}} is not recommended to use in a production environment to declare the Base Unsecure URL / Base Secure URL. It is highly recommended to change this value in your Magento <a href=""%s"">configuration</a>."
+"You did not sign in correctly or your account is temporarily disabled.","You did not sign in correctly or your account is temporarily disabled."
+"Symlinks are enabled. This may expose security risks. We strongly recommend to disable them.","Symlinks are enabled. This may expose security risks. We strongly recommend to disable them."
diff --git app/locale/en_US/Mage_Core.csv app/locale/en_US/Mage_Core.csv
index bab35ae..d634008 100644
--- app/locale/en_US/Mage_Core.csv
+++ app/locale/en_US/Mage_Core.csv
@@ -407,3 +407,4 @@
 "You will have to log in after you save your custom admin path.","You will have to log in after you save your custom admin path."
 "Your design change for the specified store intersects with another one, please specify another date range.","Your design change for the specified store intersects with another one, please specify another date range."
 "database ""%s""","database ""%s"""
+"Invalid image.","Invalid image."
diff --git app/locale/en_US/Mage_Dataflow.csv app/locale/en_US/Mage_Dataflow.csv
index 7169fae..50bac5f 100644
--- app/locale/en_US/Mage_Dataflow.csv
+++ app/locale/en_US/Mage_Dataflow.csv
@@ -30,3 +30,4 @@
 "hours","hours"
 "minute","minute"
 "minutes","minutes"
+"Backend name "Static" not supported.","Backend name "Static" not supported."
diff --git app/locale/en_US/Mage_XmlConnect.csv app/locale/en_US/Mage_XmlConnect.csv
index 92851c0..6b515d7 100644
--- app/locale/en_US/Mage_XmlConnect.csv
+++ app/locale/en_US/Mage_XmlConnect.csv
@@ -984,7 +984,7 @@
 "The value should not be less than %.2f!","The value should not be less than %.2f!"
 "Theme configurations are successfully reset.","Theme configurations are successfully reset."
 "Theme has been created.","Theme has been created."
-"Theme has been delete.","Theme has been delete."
+"Theme has been deleted.","Theme has been deleted."
 "Theme label can\'t be empty","Theme label can\'t be empty"
 "Theme label:","Theme label:"
 "Theme name is not set.","Theme name is not set."
diff --git downloader/Maged/Connect.php downloader/Maged/Connect.php
index 5c4faf6..1535a4a 100644
--- downloader/Maged/Connect.php
+++ downloader/Maged/Connect.php
@@ -396,7 +396,9 @@ class Maged_Connect
      */
     protected function _consoleHeader() {
         if (!$this->_consoleStarted) {
-?>
+            $validateKey = md5(time());
+            $sessionModel = new Maged_Model_Session();
+            $sessionModel->set('validate_cache_key', $validateKey); ?>
 <html><head><style type="text/css">
 body { margin:0px;
     padding:3px;
@@ -442,6 +444,7 @@ function clear_cache(callbacks)
     var intervalID = setInterval(function() {show_message('.', false); }, 500);
     var clean = 0;
     var maintenance = 0;
+    var validate_cache_key = '<?php echo $validateKey; ?>';
     if (window.location.href.indexOf('clean_sessions') >= 0) {
         clean = 1;
     }
@@ -451,7 +454,7 @@ function clear_cache(callbacks)
 
     new top.Ajax.Request(url, {
         method: 'post',
-        parameters: {clean_sessions:clean, maintenance:maintenance},
+        parameters: {clean_sessions:clean, maintenance:maintenance, validate_cache_key:validate_cache_key},
         onCreate: function() {
             show_message('Cleaning cache');
             show_message('');
diff --git downloader/Maged/Controller.php downloader/Maged/Controller.php
index 84a0184..bef60c0 100644
--- downloader/Maged/Controller.php
+++ downloader/Maged/Controller.php
@@ -421,7 +421,7 @@ final class Maged_Controller
      */
     public function cleanCacheAction()
     {
-        $result = $this->cleanCache();
+        $result = $this->cleanCache(true);
         echo json_encode($result);
     }
 
@@ -979,25 +979,36 @@ final class Maged_Controller
         }
     }
 
-    protected function cleanCache()
+    /**
+     * Clean cache
+     *
+     * @param bool $validate
+     * @return array
+     */
+    protected function cleanCache($validate = false)
     {
         $result = true;
         $message = '';
         try {
             if ($this->isInstalled()) {
-                if (!empty($_REQUEST['clean_sessions'])) {
-                    Mage::app()->cleanAllSessions();
-                    $message .= 'Session cleaned successfully. ';
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
-
-                // reinit config and apply all updates
-                Mage::app()->getConfig()->reinit();
-                Mage_Core_Model_Resource_Setup::applyAllUpdates();
-                Mage_Core_Model_Resource_Setup::applyAllDataUpdates();
-                $message .= 'Cache cleaned successfully';
-            } else {
-                $result = true;
             }
         } catch (Exception $e) {
             $result = false;
diff --git downloader/Maged/Model/Session.php downloader/Maged/Model/Session.php
index 8fb1a03..1cc5e56 100644
--- downloader/Maged/Model/Session.php
+++ downloader/Maged/Model/Session.php
@@ -82,6 +82,20 @@ class Maged_Model_Session extends Maged_Model
     }
 
     /**
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
      * Authentication to downloader
      * @param Maged_BruteForce_Validator $bruteForceValidator
      * @return $this
@@ -259,4 +273,24 @@ class Maged_Model_Session extends Maged_Model
         }
         return true;
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
diff --git js/lib/jquery/jquery-1.12.0.js js/lib/jquery/jquery-1.12.0.js
new file mode 100644
index 0000000..4855adc
--- /dev/null
+++ js/lib/jquery/jquery-1.12.0.js
@@ -0,0 +1,11027 @@
+/*!
+ * jQuery JavaScript Library v1.12.0
+ * http://jquery.com/
+ *
+ * Includes Sizzle.js
+ * http://sizzlejs.com/
+ *
+ * Copyright jQuery Foundation and other contributors
+ * Released under the MIT license
+ * http://jquery.org/license
+ *
+ * Date: 2016-01-08T19:56Z
+ */
+
+(function( global, factory ) {
+
+	if ( typeof module === "object" && typeof module.exports === "object" ) {
+		// For CommonJS and CommonJS-like environments where a proper `window`
+		// is present, execute the factory and get jQuery.
+		// For environments that do not have a `window` with a `document`
+		// (such as Node.js), expose a factory as module.exports.
+		// This accentuates the need for the creation of a real `window`.
+		// e.g. var jQuery = require("jquery")(window);
+		// See ticket #14549 for more info.
+		module.exports = global.document ?
+			factory( global, true ) :
+			function( w ) {
+				if ( !w.document ) {
+					throw new Error( "jQuery requires a window with a document" );
+				}
+				return factory( w );
+			};
+	} else {
+		factory( global );
+	}
+
+// Pass this if window is not defined yet
+}(typeof window !== "undefined" ? window : this, function( window, noGlobal ) {
+
+// Support: Firefox 18+
+// Can't be in strict mode, several libs including ASP.NET trace
+// the stack via arguments.caller.callee and Firefox dies if
+// you try to trace through "use strict" call chains. (#13335)
+//"use strict";
+var deletedIds = [];
+
+var document = window.document;
+
+var slice = deletedIds.slice;
+
+var concat = deletedIds.concat;
+
+var push = deletedIds.push;
+
+var indexOf = deletedIds.indexOf;
+
+var class2type = {};
+
+var toString = class2type.toString;
+
+var hasOwn = class2type.hasOwnProperty;
+
+var support = {};
+
+
+
+var
+	version = "1.12.0",
+
+	// Define a local copy of jQuery
+	jQuery = function( selector, context ) {
+
+		// The jQuery object is actually just the init constructor 'enhanced'
+		// Need init if jQuery is called (just allow error to be thrown if not included)
+		return new jQuery.fn.init( selector, context );
+	},
+
+	// Support: Android<4.1, IE<9
+	// Make sure we trim BOM and NBSP
+	rtrim = /^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g,
+
+	// Matches dashed string for camelizing
+	rmsPrefix = /^-ms-/,
+	rdashAlpha = /-([\da-z])/gi,
+
+	// Used by jQuery.camelCase as callback to replace()
+	fcamelCase = function( all, letter ) {
+		return letter.toUpperCase();
+	};
+
+jQuery.fn = jQuery.prototype = {
+
+	// The current version of jQuery being used
+	jquery: version,
+
+	constructor: jQuery,
+
+	// Start with an empty selector
+	selector: "",
+
+	// The default length of a jQuery object is 0
+	length: 0,
+
+	toArray: function() {
+		return slice.call( this );
+	},
+
+	// Get the Nth element in the matched element set OR
+	// Get the whole matched element set as a clean array
+	get: function( num ) {
+		return num != null ?
+
+			// Return just the one element from the set
+			( num < 0 ? this[ num + this.length ] : this[ num ] ) :
+
+			// Return all the elements in a clean array
+			slice.call( this );
+	},
+
+	// Take an array of elements and push it onto the stack
+	// (returning the new matched element set)
+	pushStack: function( elems ) {
+
+		// Build a new jQuery matched element set
+		var ret = jQuery.merge( this.constructor(), elems );
+
+		// Add the old object onto the stack (as a reference)
+		ret.prevObject = this;
+		ret.context = this.context;
+
+		// Return the newly-formed element set
+		return ret;
+	},
+
+	// Execute a callback for every element in the matched set.
+	each: function( callback ) {
+		return jQuery.each( this, callback );
+	},
+
+	map: function( callback ) {
+		return this.pushStack( jQuery.map( this, function( elem, i ) {
+			return callback.call( elem, i, elem );
+		} ) );
+	},
+
+	slice: function() {
+		return this.pushStack( slice.apply( this, arguments ) );
+	},
+
+	first: function() {
+		return this.eq( 0 );
+	},
+
+	last: function() {
+		return this.eq( -1 );
+	},
+
+	eq: function( i ) {
+		var len = this.length,
+			j = +i + ( i < 0 ? len : 0 );
+		return this.pushStack( j >= 0 && j < len ? [ this[ j ] ] : [] );
+	},
+
+	end: function() {
+		return this.prevObject || this.constructor();
+	},
+
+	// For internal use only.
+	// Behaves like an Array's method, not like a jQuery method.
+	push: push,
+	sort: deletedIds.sort,
+	splice: deletedIds.splice
+};
+
+jQuery.extend = jQuery.fn.extend = function() {
+	var src, copyIsArray, copy, name, options, clone,
+		target = arguments[ 0 ] || {},
+		i = 1,
+		length = arguments.length,
+		deep = false;
+
+	// Handle a deep copy situation
+	if ( typeof target === "boolean" ) {
+		deep = target;
+
+		// skip the boolean and the target
+		target = arguments[ i ] || {};
+		i++;
+	}
+
+	// Handle case when target is a string or something (possible in deep copy)
+	if ( typeof target !== "object" && !jQuery.isFunction( target ) ) {
+		target = {};
+	}
+
+	// extend jQuery itself if only one argument is passed
+	if ( i === length ) {
+		target = this;
+		i--;
+	}
+
+	for ( ; i < length; i++ ) {
+
+		// Only deal with non-null/undefined values
+		if ( ( options = arguments[ i ] ) != null ) {
+
+			// Extend the base object
+			for ( name in options ) {
+				src = target[ name ];
+				copy = options[ name ];
+
+				// Prevent never-ending loop
+				if ( target === copy ) {
+					continue;
+				}
+
+				// Recurse if we're merging plain objects or arrays
+				if ( deep && copy && ( jQuery.isPlainObject( copy ) ||
+					( copyIsArray = jQuery.isArray( copy ) ) ) ) {
+
+					if ( copyIsArray ) {
+						copyIsArray = false;
+						clone = src && jQuery.isArray( src ) ? src : [];
+
+					} else {
+						clone = src && jQuery.isPlainObject( src ) ? src : {};
+					}
+
+					// Never move original objects, clone them
+					target[ name ] = jQuery.extend( deep, clone, copy );
+
+				// Don't bring in undefined values
+				} else if ( copy !== undefined ) {
+					target[ name ] = copy;
+				}
+			}
+		}
+	}
+
+	// Return the modified object
+	return target;
+};
+
+jQuery.extend( {
+
+	// Unique for each copy of jQuery on the page
+	expando: "jQuery" + ( version + Math.random() ).replace( /\D/g, "" ),
+
+	// Assume jQuery is ready without the ready module
+	isReady: true,
+
+	error: function( msg ) {
+		throw new Error( msg );
+	},
+
+	noop: function() {},
+
+	// See test/unit/core.js for details concerning isFunction.
+	// Since version 1.3, DOM methods and functions like alert
+	// aren't supported. They return false on IE (#2968).
+	isFunction: function( obj ) {
+		return jQuery.type( obj ) === "function";
+	},
+
+	isArray: Array.isArray || function( obj ) {
+		return jQuery.type( obj ) === "array";
+	},
+
+	isWindow: function( obj ) {
+		/* jshint eqeqeq: false */
+		return obj != null && obj == obj.window;
+	},
+
+	isNumeric: function( obj ) {
+
+		// parseFloat NaNs numeric-cast false positives (null|true|false|"")
+		// ...but misinterprets leading-number strings, particularly hex literals ("0x...")
+		// subtraction forces infinities to NaN
+		// adding 1 corrects loss of precision from parseFloat (#15100)
+		var realStringObj = obj && obj.toString();
+		return !jQuery.isArray( obj ) && ( realStringObj - parseFloat( realStringObj ) + 1 ) >= 0;
+	},
+
+	isEmptyObject: function( obj ) {
+		var name;
+		for ( name in obj ) {
+			return false;
+		}
+		return true;
+	},
+
+	isPlainObject: function( obj ) {
+		var key;
+
+		// Must be an Object.
+		// Because of IE, we also have to check the presence of the constructor property.
+		// Make sure that DOM nodes and window objects don't pass through, as well
+		if ( !obj || jQuery.type( obj ) !== "object" || obj.nodeType || jQuery.isWindow( obj ) ) {
+			return false;
+		}
+
+		try {
+
+			// Not own constructor property must be Object
+			if ( obj.constructor &&
+				!hasOwn.call( obj, "constructor" ) &&
+				!hasOwn.call( obj.constructor.prototype, "isPrototypeOf" ) ) {
+				return false;
+			}
+		} catch ( e ) {
+
+			// IE8,9 Will throw exceptions on certain host objects #9897
+			return false;
+		}
+
+		// Support: IE<9
+		// Handle iteration over inherited properties before own properties.
+		if ( !support.ownFirst ) {
+			for ( key in obj ) {
+				return hasOwn.call( obj, key );
+			}
+		}
+
+		// Own properties are enumerated firstly, so to speed up,
+		// if last one is own, then all properties are own.
+		for ( key in obj ) {}
+
+		return key === undefined || hasOwn.call( obj, key );
+	},
+
+	type: function( obj ) {
+		if ( obj == null ) {
+			return obj + "";
+		}
+		return typeof obj === "object" || typeof obj === "function" ?
+			class2type[ toString.call( obj ) ] || "object" :
+			typeof obj;
+	},
+
+	// Workarounds based on findings by Jim Driscoll
+	// http://weblogs.java.net/blog/driscoll/archive/2009/09/08/eval-javascript-global-context
+	globalEval: function( data ) {
+		if ( data && jQuery.trim( data ) ) {
+
+			// We use execScript on Internet Explorer
+			// We use an anonymous function so that context is window
+			// rather than jQuery in Firefox
+			( window.execScript || function( data ) {
+				window[ "eval" ].call( window, data ); // jscs:ignore requireDotNotation
+			} )( data );
+		}
+	},
+
+	// Convert dashed to camelCase; used by the css and data modules
+	// Microsoft forgot to hump their vendor prefix (#9572)
+	camelCase: function( string ) {
+		return string.replace( rmsPrefix, "ms-" ).replace( rdashAlpha, fcamelCase );
+	},
+
+	nodeName: function( elem, name ) {
+		return elem.nodeName && elem.nodeName.toLowerCase() === name.toLowerCase();
+	},
+
+	each: function( obj, callback ) {
+		var length, i = 0;
+
+		if ( isArrayLike( obj ) ) {
+			length = obj.length;
+			for ( ; i < length; i++ ) {
+				if ( callback.call( obj[ i ], i, obj[ i ] ) === false ) {
+					break;
+				}
+			}
+		} else {
+			for ( i in obj ) {
+				if ( callback.call( obj[ i ], i, obj[ i ] ) === false ) {
+					break;
+				}
+			}
+		}
+
+		return obj;
+	},
+
+	// Support: Android<4.1, IE<9
+	trim: function( text ) {
+		return text == null ?
+			"" :
+			( text + "" ).replace( rtrim, "" );
+	},
+
+	// results is for internal usage only
+	makeArray: function( arr, results ) {
+		var ret = results || [];
+
+		if ( arr != null ) {
+			if ( isArrayLike( Object( arr ) ) ) {
+				jQuery.merge( ret,
+					typeof arr === "string" ?
+					[ arr ] : arr
+				);
+			} else {
+				push.call( ret, arr );
+			}
+		}
+
+		return ret;
+	},
+
+	inArray: function( elem, arr, i ) {
+		var len;
+
+		if ( arr ) {
+			if ( indexOf ) {
+				return indexOf.call( arr, elem, i );
+			}
+
+			len = arr.length;
+			i = i ? i < 0 ? Math.max( 0, len + i ) : i : 0;
+
+			for ( ; i < len; i++ ) {
+
+				// Skip accessing in sparse arrays
+				if ( i in arr && arr[ i ] === elem ) {
+					return i;
+				}
+			}
+		}
+
+		return -1;
+	},
+
+	merge: function( first, second ) {
+		var len = +second.length,
+			j = 0,
+			i = first.length;
+
+		while ( j < len ) {
+			first[ i++ ] = second[ j++ ];
+		}
+
+		// Support: IE<9
+		// Workaround casting of .length to NaN on otherwise arraylike objects (e.g., NodeLists)
+		if ( len !== len ) {
+			while ( second[ j ] !== undefined ) {
+				first[ i++ ] = second[ j++ ];
+			}
+		}
+
+		first.length = i;
+
+		return first;
+	},
+
+	grep: function( elems, callback, invert ) {
+		var callbackInverse,
+			matches = [],
+			i = 0,
+			length = elems.length,
+			callbackExpect = !invert;
+
+		// Go through the array, only saving the items
+		// that pass the validator function
+		for ( ; i < length; i++ ) {
+			callbackInverse = !callback( elems[ i ], i );
+			if ( callbackInverse !== callbackExpect ) {
+				matches.push( elems[ i ] );
+			}
+		}
+
+		return matches;
+	},
+
+	// arg is for internal usage only
+	map: function( elems, callback, arg ) {
+		var length, value,
+			i = 0,
+			ret = [];
+
+		// Go through the array, translating each of the items to their new values
+		if ( isArrayLike( elems ) ) {
+			length = elems.length;
+			for ( ; i < length; i++ ) {
+				value = callback( elems[ i ], i, arg );
+
+				if ( value != null ) {
+					ret.push( value );
+				}
+			}
+
+		// Go through every key on the object,
+		} else {
+			for ( i in elems ) {
+				value = callback( elems[ i ], i, arg );
+
+				if ( value != null ) {
+					ret.push( value );
+				}
+			}
+		}
+
+		// Flatten any nested arrays
+		return concat.apply( [], ret );
+	},
+
+	// A global GUID counter for objects
+	guid: 1,
+
+	// Bind a function to a context, optionally partially applying any
+	// arguments.
+	proxy: function( fn, context ) {
+		var args, proxy, tmp;
+
+		if ( typeof context === "string" ) {
+			tmp = fn[ context ];
+			context = fn;
+			fn = tmp;
+		}
+
+		// Quick check to determine if target is callable, in the spec
+		// this throws a TypeError, but we will just return undefined.
+		if ( !jQuery.isFunction( fn ) ) {
+			return undefined;
+		}
+
+		// Simulated bind
+		args = slice.call( arguments, 2 );
+		proxy = function() {
+			return fn.apply( context || this, args.concat( slice.call( arguments ) ) );
+		};
+
+		// Set the guid of unique handler to the same of original handler, so it can be removed
+		proxy.guid = fn.guid = fn.guid || jQuery.guid++;
+
+		return proxy;
+	},
+
+	now: function() {
+		return +( new Date() );
+	},
+
+	// jQuery.support is not used in Core but other projects attach their
+	// properties to it so it needs to exist.
+	support: support
+} );
+
+// JSHint would error on this code due to the Symbol not being defined in ES5.
+// Defining this global in .jshintrc would create a danger of using the global
+// unguarded in another place, it seems safer to just disable JSHint for these
+// three lines.
+/* jshint ignore: start */
+if ( typeof Symbol === "function" ) {
+	jQuery.fn[ Symbol.iterator ] = deletedIds[ Symbol.iterator ];
+}
+/* jshint ignore: end */
+
+// Populate the class2type map
+jQuery.each( "Boolean Number String Function Array Date RegExp Object Error Symbol".split( " " ),
+function( i, name ) {
+	class2type[ "[object " + name + "]" ] = name.toLowerCase();
+} );
+
+function isArrayLike( obj ) {
+
+	// Support: iOS 8.2 (not reproducible in simulator)
+	// `in` check used to prevent JIT error (gh-2145)
+	// hasOwn isn't used here due to false negatives
+	// regarding Nodelist length in IE
+	var length = !!obj && "length" in obj && obj.length,
+		type = jQuery.type( obj );
+
+	if ( type === "function" || jQuery.isWindow( obj ) ) {
+		return false;
+	}
+
+	return type === "array" || length === 0 ||
+		typeof length === "number" && length > 0 && ( length - 1 ) in obj;
+}
+var Sizzle =
+/*!
+ * Sizzle CSS Selector Engine v2.2.1
+ * http://sizzlejs.com/
+ *
+ * Copyright jQuery Foundation and other contributors
+ * Released under the MIT license
+ * http://jquery.org/license
+ *
+ * Date: 2015-10-17
+ */
+(function( window ) {
+
+var i,
+	support,
+	Expr,
+	getText,
+	isXML,
+	tokenize,
+	compile,
+	select,
+	outermostContext,
+	sortInput,
+	hasDuplicate,
+
+	// Local document vars
+	setDocument,
+	document,
+	docElem,
+	documentIsHTML,
+	rbuggyQSA,
+	rbuggyMatches,
+	matches,
+	contains,
+
+	// Instance-specific data
+	expando = "sizzle" + 1 * new Date(),
+	preferredDoc = window.document,
+	dirruns = 0,
+	done = 0,
+	classCache = createCache(),
+	tokenCache = createCache(),
+	compilerCache = createCache(),
+	sortOrder = function( a, b ) {
+		if ( a === b ) {
+			hasDuplicate = true;
+		}
+		return 0;
+	},
+
+	// General-purpose constants
+	MAX_NEGATIVE = 1 << 31,
+
+	// Instance methods
+	hasOwn = ({}).hasOwnProperty,
+	arr = [],
+	pop = arr.pop,
+	push_native = arr.push,
+	push = arr.push,
+	slice = arr.slice,
+	// Use a stripped-down indexOf as it's faster than native
+	// http://jsperf.com/thor-indexof-vs-for/5
+	indexOf = function( list, elem ) {
+		var i = 0,
+			len = list.length;
+		for ( ; i < len; i++ ) {
+			if ( list[i] === elem ) {
+				return i;
+			}
+		}
+		return -1;
+	},
+
+	booleans = "checked|selected|async|autofocus|autoplay|controls|defer|disabled|hidden|ismap|loop|multiple|open|readonly|required|scoped",
+
+	// Regular expressions
+
+	// http://www.w3.org/TR/css3-selectors/#whitespace
+	whitespace = "[\\x20\\t\\r\\n\\f]",
+
+	// http://www.w3.org/TR/CSS21/syndata.html#value-def-identifier
+	identifier = "(?:\\\\.|[\\w-]|[^\\x00-\\xa0])+",
+
+	// Attribute selectors: http://www.w3.org/TR/selectors/#attribute-selectors
+	attributes = "\\[" + whitespace + "*(" + identifier + ")(?:" + whitespace +
+		// Operator (capture 2)
+		"*([*^$|!~]?=)" + whitespace +
+		// "Attribute values must be CSS identifiers [capture 5] or strings [capture 3 or capture 4]"
+		"*(?:'((?:\\\\.|[^\\\\'])*)'|\"((?:\\\\.|[^\\\\\"])*)\"|(" + identifier + "))|)" + whitespace +
+		"*\\]",
+
+	pseudos = ":(" + identifier + ")(?:\\((" +
+		// To reduce the number of selectors needing tokenize in the preFilter, prefer arguments:
+		// 1. quoted (capture 3; capture 4 or capture 5)
+		"('((?:\\\\.|[^\\\\'])*)'|\"((?:\\\\.|[^\\\\\"])*)\")|" +
+		// 2. simple (capture 6)
+		"((?:\\\\.|[^\\\\()[\\]]|" + attributes + ")*)|" +
+		// 3. anything else (capture 2)
+		".*" +
+		")\\)|)",
+
+	// Leading and non-escaped trailing whitespace, capturing some non-whitespace characters preceding the latter
+	rwhitespace = new RegExp( whitespace + "+", "g" ),
+	rtrim = new RegExp( "^" + whitespace + "+|((?:^|[^\\\\])(?:\\\\.)*)" + whitespace + "+$", "g" ),
+
+	rcomma = new RegExp( "^" + whitespace + "*," + whitespace + "*" ),
+	rcombinators = new RegExp( "^" + whitespace + "*([>+~]|" + whitespace + ")" + whitespace + "*" ),
+
+	rattributeQuotes = new RegExp( "=" + whitespace + "*([^\\]'\"]*?)" + whitespace + "*\\]", "g" ),
+
+	rpseudo = new RegExp( pseudos ),
+	ridentifier = new RegExp( "^" + identifier + "$" ),
+
+	matchExpr = {
+		"ID": new RegExp( "^#(" + identifier + ")" ),
+		"CLASS": new RegExp( "^\\.(" + identifier + ")" ),
+		"TAG": new RegExp( "^(" + identifier + "|[*])" ),
+		"ATTR": new RegExp( "^" + attributes ),
+		"PSEUDO": new RegExp( "^" + pseudos ),
+		"CHILD": new RegExp( "^:(only|first|last|nth|nth-last)-(child|of-type)(?:\\(" + whitespace +
+			"*(even|odd|(([+-]|)(\\d*)n|)" + whitespace + "*(?:([+-]|)" + whitespace +
+			"*(\\d+)|))" + whitespace + "*\\)|)", "i" ),
+		"bool": new RegExp( "^(?:" + booleans + ")$", "i" ),
+		// For use in libraries implementing .is()
+		// We use this for POS matching in `select`
+		"needsContext": new RegExp( "^" + whitespace + "*[>+~]|:(even|odd|eq|gt|lt|nth|first|last)(?:\\(" +
+			whitespace + "*((?:-\\d)?\\d*)" + whitespace + "*\\)|)(?=[^-]|$)", "i" )
+	},
+
+	rinputs = /^(?:input|select|textarea|button)$/i,
+	rheader = /^h\d$/i,
+
+	rnative = /^[^{]+\{\s*\[native \w/,
+
+	// Easily-parseable/retrievable ID or TAG or CLASS selectors
+	rquickExpr = /^(?:#([\w-]+)|(\w+)|\.([\w-]+))$/,
+
+	rsibling = /[+~]/,
+	rescape = /'|\\/g,
+
+	// CSS escapes http://www.w3.org/TR/CSS21/syndata.html#escaped-characters
+	runescape = new RegExp( "\\\\([\\da-f]{1,6}" + whitespace + "?|(" + whitespace + ")|.)", "ig" ),
+	funescape = function( _, escaped, escapedWhitespace ) {
+		var high = "0x" + escaped - 0x10000;
+		// NaN means non-codepoint
+		// Support: Firefox<24
+		// Workaround erroneous numeric interpretation of +"0x"
+		return high !== high || escapedWhitespace ?
+			escaped :
+			high < 0 ?
+				// BMP codepoint
+				String.fromCharCode( high + 0x10000 ) :
+				// Supplemental Plane codepoint (surrogate pair)
+				String.fromCharCode( high >> 10 | 0xD800, high & 0x3FF | 0xDC00 );
+	},
+
+	// Used for iframes
+	// See setDocument()
+	// Removing the function wrapper causes a "Permission Denied"
+	// error in IE
+	unloadHandler = function() {
+		setDocument();
+	};
+
+// Optimize for push.apply( _, NodeList )
+try {
+	push.apply(
+		(arr = slice.call( preferredDoc.childNodes )),
+		preferredDoc.childNodes
+	);
+	// Support: Android<4.0
+	// Detect silently failing push.apply
+	arr[ preferredDoc.childNodes.length ].nodeType;
+} catch ( e ) {
+	push = { apply: arr.length ?
+
+		// Leverage slice if possible
+		function( target, els ) {
+			push_native.apply( target, slice.call(els) );
+		} :
+
+		// Support: IE<9
+		// Otherwise append directly
+		function( target, els ) {
+			var j = target.length,
+				i = 0;
+			// Can't trust NodeList.length
+			while ( (target[j++] = els[i++]) ) {}
+			target.length = j - 1;
+		}
+	};
+}
+
+function Sizzle( selector, context, results, seed ) {
+	var m, i, elem, nid, nidselect, match, groups, newSelector,
+		newContext = context && context.ownerDocument,
+
+		// nodeType defaults to 9, since context defaults to document
+		nodeType = context ? context.nodeType : 9;
+
+	results = results || [];
+
+	// Return early from calls with invalid selector or context
+	if ( typeof selector !== "string" || !selector ||
+		nodeType !== 1 && nodeType !== 9 && nodeType !== 11 ) {
+
+		return results;
+	}
+
+	// Try to shortcut find operations (as opposed to filters) in HTML documents
+	if ( !seed ) {
+
+		if ( ( context ? context.ownerDocument || context : preferredDoc ) !== document ) {
+			setDocument( context );
+		}
+		context = context || document;
+
+		if ( documentIsHTML ) {
+
+			// If the selector is sufficiently simple, try using a "get*By*" DOM method
+			// (excepting DocumentFragment context, where the methods don't exist)
+			if ( nodeType !== 11 && (match = rquickExpr.exec( selector )) ) {
+
+				// ID selector
+				if ( (m = match[1]) ) {
+
+					// Document context
+					if ( nodeType === 9 ) {
+						if ( (elem = context.getElementById( m )) ) {
+
+							// Support: IE, Opera, Webkit
+							// TODO: identify versions
+							// getElementById can match elements by name instead of ID
+							if ( elem.id === m ) {
+								results.push( elem );
+								return results;
+							}
+						} else {
+							return results;
+						}
+
+					// Element context
+					} else {
+
+						// Support: IE, Opera, Webkit
+						// TODO: identify versions
+						// getElementById can match elements by name instead of ID
+						if ( newContext && (elem = newContext.getElementById( m )) &&
+							contains( context, elem ) &&
+							elem.id === m ) {
+
+							results.push( elem );
+							return results;
+						}
+					}
+
+				// Type selector
+				} else if ( match[2] ) {
+					push.apply( results, context.getElementsByTagName( selector ) );
+					return results;
+
+				// Class selector
+				} else if ( (m = match[3]) && support.getElementsByClassName &&
+					context.getElementsByClassName ) {
+
+					push.apply( results, context.getElementsByClassName( m ) );
+					return results;
+				}
+			}
+
+			// Take advantage of querySelectorAll
+			if ( support.qsa &&
+				!compilerCache[ selector + " " ] &&
+				(!rbuggyQSA || !rbuggyQSA.test( selector )) ) {
+
+				if ( nodeType !== 1 ) {
+					newContext = context;
+					newSelector = selector;
+
+				// qSA looks outside Element context, which is not what we want
+				// Thanks to Andrew Dupont for this workaround technique
+				// Support: IE <=8
+				// Exclude object elements
+				} else if ( context.nodeName.toLowerCase() !== "object" ) {
+
+					// Capture the context ID, setting it first if necessary
+					if ( (nid = context.getAttribute( "id" )) ) {
+						nid = nid.replace( rescape, "\\$&" );
+					} else {
+						context.setAttribute( "id", (nid = expando) );
+					}
+
+					// Prefix every selector in the list
+					groups = tokenize( selector );
+					i = groups.length;
+					nidselect = ridentifier.test( nid ) ? "#" + nid : "[id='" + nid + "']";
+					while ( i-- ) {
+						groups[i] = nidselect + " " + toSelector( groups[i] );
+					}
+					newSelector = groups.join( "," );
+
+					// Expand context for sibling selectors
+					newContext = rsibling.test( selector ) && testContext( context.parentNode ) ||
+						context;
+				}
+
+				if ( newSelector ) {
+					try {
+						push.apply( results,
+							newContext.querySelectorAll( newSelector )
+						);
+						return results;
+					} catch ( qsaError ) {
+					} finally {
+						if ( nid === expando ) {
+							context.removeAttribute( "id" );
+						}
+					}
+				}
+			}
+		}
+	}
+
+	// All others
+	return select( selector.replace( rtrim, "$1" ), context, results, seed );
+}
+
+/**
+ * Create key-value caches of limited size
+ * @returns {function(string, object)} Returns the Object data after storing it on itself with
+ *	property name the (space-suffixed) string and (if the cache is larger than Expr.cacheLength)
+ *	deleting the oldest entry
+ */
+function createCache() {
+	var keys = [];
+
+	function cache( key, value ) {
+		// Use (key + " ") to avoid collision with native prototype properties (see Issue #157)
+		if ( keys.push( key + " " ) > Expr.cacheLength ) {
+			// Only keep the most recent entries
+			delete cache[ keys.shift() ];
+		}
+		return (cache[ key + " " ] = value);
+	}
+	return cache;
+}
+
+/**
+ * Mark a function for special use by Sizzle
+ * @param {Function} fn The function to mark
+ */
+function markFunction( fn ) {
+	fn[ expando ] = true;
+	return fn;
+}
+
+/**
+ * Support testing using an element
+ * @param {Function} fn Passed the created div and expects a boolean result
+ */
+function assert( fn ) {
+	var div = document.createElement("div");
+
+	try {
+		return !!fn( div );
+	} catch (e) {
+		return false;
+	} finally {
+		// Remove from its parent by default
+		if ( div.parentNode ) {
+			div.parentNode.removeChild( div );
+		}
+		// release memory in IE
+		div = null;
+	}
+}
+
+/**
+ * Adds the same handler for all of the specified attrs
+ * @param {String} attrs Pipe-separated list of attributes
+ * @param {Function} handler The method that will be applied
+ */
+function addHandle( attrs, handler ) {
+	var arr = attrs.split("|"),
+		i = arr.length;
+
+	while ( i-- ) {
+		Expr.attrHandle[ arr[i] ] = handler;
+	}
+}
+
+/**
+ * Checks document order of two siblings
+ * @param {Element} a
+ * @param {Element} b
+ * @returns {Number} Returns less than 0 if a precedes b, greater than 0 if a follows b
+ */
+function siblingCheck( a, b ) {
+	var cur = b && a,
+		diff = cur && a.nodeType === 1 && b.nodeType === 1 &&
+			( ~b.sourceIndex || MAX_NEGATIVE ) -
+			( ~a.sourceIndex || MAX_NEGATIVE );
+
+	// Use IE sourceIndex if available on both nodes
+	if ( diff ) {
+		return diff;
+	}
+
+	// Check if b follows a
+	if ( cur ) {
+		while ( (cur = cur.nextSibling) ) {
+			if ( cur === b ) {
+				return -1;
+			}
+		}
+	}
+
+	return a ? 1 : -1;
+}
+
+/**
+ * Returns a function to use in pseudos for input types
+ * @param {String} type
+ */
+function createInputPseudo( type ) {
+	return function( elem ) {
+		var name = elem.nodeName.toLowerCase();
+		return name === "input" && elem.type === type;
+	};
+}
+
+/**
+ * Returns a function to use in pseudos for buttons
+ * @param {String} type
+ */
+function createButtonPseudo( type ) {
+	return function( elem ) {
+		var name = elem.nodeName.toLowerCase();
+		return (name === "input" || name === "button") && elem.type === type;
+	};
+}
+
+/**
+ * Returns a function to use in pseudos for positionals
+ * @param {Function} fn
+ */
+function createPositionalPseudo( fn ) {
+	return markFunction(function( argument ) {
+		argument = +argument;
+		return markFunction(function( seed, matches ) {
+			var j,
+				matchIndexes = fn( [], seed.length, argument ),
+				i = matchIndexes.length;
+
+			// Match elements found at the specified indexes
+			while ( i-- ) {
+				if ( seed[ (j = matchIndexes[i]) ] ) {
+					seed[j] = !(matches[j] = seed[j]);
+				}
+			}
+		});
+	});
+}
+
+/**
+ * Checks a node for validity as a Sizzle context
+ * @param {Element|Object=} context
+ * @returns {Element|Object|Boolean} The input node if acceptable, otherwise a falsy value
+ */
+function testContext( context ) {
+	return context && typeof context.getElementsByTagName !== "undefined" && context;
+}
+
+// Expose support vars for convenience
+support = Sizzle.support = {};
+
+/**
+ * Detects XML nodes
+ * @param {Element|Object} elem An element or a document
+ * @returns {Boolean} True iff elem is a non-HTML XML node
+ */
+isXML = Sizzle.isXML = function( elem ) {
+	// documentElement is verified for cases where it doesn't yet exist
+	// (such as loading iframes in IE - #4833)
+	var documentElement = elem && (elem.ownerDocument || elem).documentElement;
+	return documentElement ? documentElement.nodeName !== "HTML" : false;
+};
+
+/**
+ * Sets document-related variables once based on the current document
+ * @param {Element|Object} [doc] An element or document object to use to set the document
+ * @returns {Object} Returns the current document
+ */
+setDocument = Sizzle.setDocument = function( node ) {
+	var hasCompare, parent,
+		doc = node ? node.ownerDocument || node : preferredDoc;
+
+	// Return early if doc is invalid or already selected
+	if ( doc === document || doc.nodeType !== 9 || !doc.documentElement ) {
+		return document;
+	}
+
+	// Update global variables
+	document = doc;
+	docElem = document.documentElement;
+	documentIsHTML = !isXML( document );
+
+	// Support: IE 9-11, Edge
+	// Accessing iframe documents after unload throws "permission denied" errors (jQuery #13936)
+	if ( (parent = document.defaultView) && parent.top !== parent ) {
+		// Support: IE 11
+		if ( parent.addEventListener ) {
+			parent.addEventListener( "unload", unloadHandler, false );
+
+		// Support: IE 9 - 10 only
+		} else if ( parent.attachEvent ) {
+			parent.attachEvent( "onunload", unloadHandler );
+		}
+	}
+
+	/* Attributes
+	---------------------------------------------------------------------- */
+
+	// Support: IE<8
+	// Verify that getAttribute really returns attributes and not properties
+	// (excepting IE8 booleans)
+	support.attributes = assert(function( div ) {
+		div.className = "i";
+		return !div.getAttribute("className");
+	});
+
+	/* getElement(s)By*
+	---------------------------------------------------------------------- */
+
+	// Check if getElementsByTagName("*") returns only elements
+	support.getElementsByTagName = assert(function( div ) {
+		div.appendChild( document.createComment("") );
+		return !div.getElementsByTagName("*").length;
+	});
+
+	// Support: IE<9
+	support.getElementsByClassName = rnative.test( document.getElementsByClassName );
+
+	// Support: IE<10
+	// Check if getElementById returns elements by name
+	// The broken getElementById methods don't pick up programatically-set names,
+	// so use a roundabout getElementsByName test
+	support.getById = assert(function( div ) {
+		docElem.appendChild( div ).id = expando;
+		return !document.getElementsByName || !document.getElementsByName( expando ).length;
+	});
+
+	// ID find and filter
+	if ( support.getById ) {
+		Expr.find["ID"] = function( id, context ) {
+			if ( typeof context.getElementById !== "undefined" && documentIsHTML ) {
+				var m = context.getElementById( id );
+				return m ? [ m ] : [];
+			}
+		};
+		Expr.filter["ID"] = function( id ) {
+			var attrId = id.replace( runescape, funescape );
+			return function( elem ) {
+				return elem.getAttribute("id") === attrId;
+			};
+		};
+	} else {
+		// Support: IE6/7
+		// getElementById is not reliable as a find shortcut
+		delete Expr.find["ID"];
+
+		Expr.filter["ID"] =  function( id ) {
+			var attrId = id.replace( runescape, funescape );
+			return function( elem ) {
+				var node = typeof elem.getAttributeNode !== "undefined" &&
+					elem.getAttributeNode("id");
+				return node && node.value === attrId;
+			};
+		};
+	}
+
+	// Tag
+	Expr.find["TAG"] = support.getElementsByTagName ?
+		function( tag, context ) {
+			if ( typeof context.getElementsByTagName !== "undefined" ) {
+				return context.getElementsByTagName( tag );
+
+			// DocumentFragment nodes don't have gEBTN
+			} else if ( support.qsa ) {
+				return context.querySelectorAll( tag );
+			}
+		} :
+
+		function( tag, context ) {
+			var elem,
+				tmp = [],
+				i = 0,
+				// By happy coincidence, a (broken) gEBTN appears on DocumentFragment nodes too
+				results = context.getElementsByTagName( tag );
+
+			// Filter out possible comments
+			if ( tag === "*" ) {
+				while ( (elem = results[i++]) ) {
+					if ( elem.nodeType === 1 ) {
+						tmp.push( elem );
+					}
+				}
+
+				return tmp;
+			}
+			return results;
+		};
+
+	// Class
+	Expr.find["CLASS"] = support.getElementsByClassName && function( className, context ) {
+		if ( typeof context.getElementsByClassName !== "undefined" && documentIsHTML ) {
+			return context.getElementsByClassName( className );
+		}
+	};
+
+	/* QSA/matchesSelector
+	---------------------------------------------------------------------- */
+
+	// QSA and matchesSelector support
+
+	// matchesSelector(:active) reports false when true (IE9/Opera 11.5)
+	rbuggyMatches = [];
+
+	// qSa(:focus) reports false when true (Chrome 21)
+	// We allow this because of a bug in IE8/9 that throws an error
+	// whenever `document.activeElement` is accessed on an iframe
+	// So, we allow :focus to pass through QSA all the time to avoid the IE error
+	// See http://bugs.jquery.com/ticket/13378
+	rbuggyQSA = [];
+
+	if ( (support.qsa = rnative.test( document.querySelectorAll )) ) {
+		// Build QSA regex
+		// Regex strategy adopted from Diego Perini
+		assert(function( div ) {
+			// Select is set to empty string on purpose
+			// This is to test IE's treatment of not explicitly
+			// setting a boolean content attribute,
+			// since its presence should be enough
+			// http://bugs.jquery.com/ticket/12359
+			docElem.appendChild( div ).innerHTML = "<a id='" + expando + "'></a>" +
+				"<select id='" + expando + "-\r\\' msallowcapture=''>" +
+				"<option selected=''></option></select>";
+
+			// Support: IE8, Opera 11-12.16
+			// Nothing should be selected when empty strings follow ^= or $= or *=
+			// The test attribute must be unknown in Opera but "safe" for WinRT
+			// http://msdn.microsoft.com/en-us/library/ie/hh465388.aspx#attribute_section
+			if ( div.querySelectorAll("[msallowcapture^='']").length ) {
+				rbuggyQSA.push( "[*^$]=" + whitespace + "*(?:''|\"\")" );
+			}
+
+			// Support: IE8
+			// Boolean attributes and "value" are not treated correctly
+			if ( !div.querySelectorAll("[selected]").length ) {
+				rbuggyQSA.push( "\\[" + whitespace + "*(?:value|" + booleans + ")" );
+			}
+
+			// Support: Chrome<29, Android<4.4, Safari<7.0+, iOS<7.0+, PhantomJS<1.9.8+
+			if ( !div.querySelectorAll( "[id~=" + expando + "-]" ).length ) {
+				rbuggyQSA.push("~=");
+			}
+
+			// Webkit/Opera - :checked should return selected option elements
+			// http://www.w3.org/TR/2011/REC-css3-selectors-20110929/#checked
+			// IE8 throws error here and will not see later tests
+			if ( !div.querySelectorAll(":checked").length ) {
+				rbuggyQSA.push(":checked");
+			}
+
+			// Support: Safari 8+, iOS 8+
+			// https://bugs.webkit.org/show_bug.cgi?id=136851
+			// In-page `selector#id sibing-combinator selector` fails
+			if ( !div.querySelectorAll( "a#" + expando + "+*" ).length ) {
+				rbuggyQSA.push(".#.+[+~]");
+			}
+		});
+
+		assert(function( div ) {
+			// Support: Windows 8 Native Apps
+			// The type and name attributes are restricted during .innerHTML assignment
+			var input = document.createElement("input");
+			input.setAttribute( "type", "hidden" );
+			div.appendChild( input ).setAttribute( "name", "D" );
+
+			// Support: IE8
+			// Enforce case-sensitivity of name attribute
+			if ( div.querySelectorAll("[name=d]").length ) {
+				rbuggyQSA.push( "name" + whitespace + "*[*^$|!~]?=" );
+			}
+
+			// FF 3.5 - :enabled/:disabled and hidden elements (hidden elements are still enabled)
+			// IE8 throws error here and will not see later tests
+			if ( !div.querySelectorAll(":enabled").length ) {
+				rbuggyQSA.push( ":enabled", ":disabled" );
+			}
+
+			// Opera 10-11 does not throw on post-comma invalid pseudos
+			div.querySelectorAll("*,:x");
+			rbuggyQSA.push(",.*:");
+		});
+	}
+
+	if ( (support.matchesSelector = rnative.test( (matches = docElem.matches ||
+		docElem.webkitMatchesSelector ||
+		docElem.mozMatchesSelector ||
+		docElem.oMatchesSelector ||
+		docElem.msMatchesSelector) )) ) {
+
+		assert(function( div ) {
+			// Check to see if it's possible to do matchesSelector
+			// on a disconnected node (IE 9)
+			support.disconnectedMatch = matches.call( div, "div" );
+
+			// This should fail with an exception
+			// Gecko does not error, returns false instead
+			matches.call( div, "[s!='']:x" );
+			rbuggyMatches.push( "!=", pseudos );
+		});
+	}
+
+	rbuggyQSA = rbuggyQSA.length && new RegExp( rbuggyQSA.join("|") );
+	rbuggyMatches = rbuggyMatches.length && new RegExp( rbuggyMatches.join("|") );
+
+	/* Contains
+	---------------------------------------------------------------------- */
+	hasCompare = rnative.test( docElem.compareDocumentPosition );
+
+	// Element contains another
+	// Purposefully self-exclusive
+	// As in, an element does not contain itself
+	contains = hasCompare || rnative.test( docElem.contains ) ?
+		function( a, b ) {
+			var adown = a.nodeType === 9 ? a.documentElement : a,
+				bup = b && b.parentNode;
+			return a === bup || !!( bup && bup.nodeType === 1 && (
+				adown.contains ?
+					adown.contains( bup ) :
+					a.compareDocumentPosition && a.compareDocumentPosition( bup ) & 16
+			));
+		} :
+		function( a, b ) {
+			if ( b ) {
+				while ( (b = b.parentNode) ) {
+					if ( b === a ) {
+						return true;
+					}
+				}
+			}
+			return false;
+		};
+
+	/* Sorting
+	---------------------------------------------------------------------- */
+
+	// Document order sorting
+	sortOrder = hasCompare ?
+	function( a, b ) {
+
+		// Flag for duplicate removal
+		if ( a === b ) {
+			hasDuplicate = true;
+			return 0;
+		}
+
+		// Sort on method existence if only one input has compareDocumentPosition
+		var compare = !a.compareDocumentPosition - !b.compareDocumentPosition;
+		if ( compare ) {
+			return compare;
+		}
+
+		// Calculate position if both inputs belong to the same document
+		compare = ( a.ownerDocument || a ) === ( b.ownerDocument || b ) ?
+			a.compareDocumentPosition( b ) :
+
+			// Otherwise we know they are disconnected
+			1;
+
+		// Disconnected nodes
+		if ( compare & 1 ||
+			(!support.sortDetached && b.compareDocumentPosition( a ) === compare) ) {
+
+			// Choose the first element that is related to our preferred document
+			if ( a === document || a.ownerDocument === preferredDoc && contains(preferredDoc, a) ) {
+				return -1;
+			}
+			if ( b === document || b.ownerDocument === preferredDoc && contains(preferredDoc, b) ) {
+				return 1;
+			}
+
+			// Maintain original order
+			return sortInput ?
+				( indexOf( sortInput, a ) - indexOf( sortInput, b ) ) :
+				0;
+		}
+
+		return compare & 4 ? -1 : 1;
+	} :
+	function( a, b ) {
+		// Exit early if the nodes are identical
+		if ( a === b ) {
+			hasDuplicate = true;
+			return 0;
+		}
+
+		var cur,
+			i = 0,
+			aup = a.parentNode,
+			bup = b.parentNode,
+			ap = [ a ],
+			bp = [ b ];
+
+		// Parentless nodes are either documents or disconnected
+		if ( !aup || !bup ) {
+			return a === document ? -1 :
+				b === document ? 1 :
+				aup ? -1 :
+				bup ? 1 :
+				sortInput ?
+				( indexOf( sortInput, a ) - indexOf( sortInput, b ) ) :
+				0;
+
+		// If the nodes are siblings, we can do a quick check
+		} else if ( aup === bup ) {
+			return siblingCheck( a, b );
+		}
+
+		// Otherwise we need full lists of their ancestors for comparison
+		cur = a;
+		while ( (cur = cur.parentNode) ) {
+			ap.unshift( cur );
+		}
+		cur = b;
+		while ( (cur = cur.parentNode) ) {
+			bp.unshift( cur );
+		}
+
+		// Walk down the tree looking for a discrepancy
+		while ( ap[i] === bp[i] ) {
+			i++;
+		}
+
+		return i ?
+			// Do a sibling check if the nodes have a common ancestor
+			siblingCheck( ap[i], bp[i] ) :
+
+			// Otherwise nodes in our document sort first
+			ap[i] === preferredDoc ? -1 :
+			bp[i] === preferredDoc ? 1 :
+			0;
+	};
+
+	return document;
+};
+
+Sizzle.matches = function( expr, elements ) {
+	return Sizzle( expr, null, null, elements );
+};
+
+Sizzle.matchesSelector = function( elem, expr ) {
+	// Set document vars if needed
+	if ( ( elem.ownerDocument || elem ) !== document ) {
+		setDocument( elem );
+	}
+
+	// Make sure that attribute selectors are quoted
+	expr = expr.replace( rattributeQuotes, "='$1']" );
+
+	if ( support.matchesSelector && documentIsHTML &&
+		!compilerCache[ expr + " " ] &&
+		( !rbuggyMatches || !rbuggyMatches.test( expr ) ) &&
+		( !rbuggyQSA     || !rbuggyQSA.test( expr ) ) ) {
+
+		try {
+			var ret = matches.call( elem, expr );
+
+			// IE 9's matchesSelector returns false on disconnected nodes
+			if ( ret || support.disconnectedMatch ||
+					// As well, disconnected nodes are said to be in a document
+					// fragment in IE 9
+					elem.document && elem.document.nodeType !== 11 ) {
+				return ret;
+			}
+		} catch (e) {}
+	}
+
+	return Sizzle( expr, document, null, [ elem ] ).length > 0;
+};
+
+Sizzle.contains = function( context, elem ) {
+	// Set document vars if needed
+	if ( ( context.ownerDocument || context ) !== document ) {
+		setDocument( context );
+	}
+	return contains( context, elem );
+};
+
+Sizzle.attr = function( elem, name ) {
+	// Set document vars if needed
+	if ( ( elem.ownerDocument || elem ) !== document ) {
+		setDocument( elem );
+	}
+
+	var fn = Expr.attrHandle[ name.toLowerCase() ],
+		// Don't get fooled by Object.prototype properties (jQuery #13807)
+		val = fn && hasOwn.call( Expr.attrHandle, name.toLowerCase() ) ?
+			fn( elem, name, !documentIsHTML ) :
+			undefined;
+
+	return val !== undefined ?
+		val :
+		support.attributes || !documentIsHTML ?
+			elem.getAttribute( name ) :
+			(val = elem.getAttributeNode(name)) && val.specified ?
+				val.value :
+				null;
+};
+
+Sizzle.error = function( msg ) {
+	throw new Error( "Syntax error, unrecognized expression: " + msg );
+};
+
+/**
+ * Document sorting and removing duplicates
+ * @param {ArrayLike} results
+ */
+Sizzle.uniqueSort = function( results ) {
+	var elem,
+		duplicates = [],
+		j = 0,
+		i = 0;
+
+	// Unless we *know* we can detect duplicates, assume their presence
+	hasDuplicate = !support.detectDuplicates;
+	sortInput = !support.sortStable && results.slice( 0 );
+	results.sort( sortOrder );
+
+	if ( hasDuplicate ) {
+		while ( (elem = results[i++]) ) {
+			if ( elem === results[ i ] ) {
+				j = duplicates.push( i );
+			}
+		}
+		while ( j-- ) {
+			results.splice( duplicates[ j ], 1 );
+		}
+	}
+
+	// Clear input after sorting to release objects
+	// See https://github.com/jquery/sizzle/pull/225
+	sortInput = null;
+
+	return results;
+};
+
+/**
+ * Utility function for retrieving the text value of an array of DOM nodes
+ * @param {Array|Element} elem
+ */
+getText = Sizzle.getText = function( elem ) {
+	var node,
+		ret = "",
+		i = 0,
+		nodeType = elem.nodeType;
+
+	if ( !nodeType ) {
+		// If no nodeType, this is expected to be an array
+		while ( (node = elem[i++]) ) {
+			// Do not traverse comment nodes
+			ret += getText( node );
+		}
+	} else if ( nodeType === 1 || nodeType === 9 || nodeType === 11 ) {
+		// Use textContent for elements
+		// innerText usage removed for consistency of new lines (jQuery #11153)
+		if ( typeof elem.textContent === "string" ) {
+			return elem.textContent;
+		} else {
+			// Traverse its children
+			for ( elem = elem.firstChild; elem; elem = elem.nextSibling ) {
+				ret += getText( elem );
+			}
+		}
+	} else if ( nodeType === 3 || nodeType === 4 ) {
+		return elem.nodeValue;
+	}
+	// Do not include comment or processing instruction nodes
+
+	return ret;
+};
+
+Expr = Sizzle.selectors = {
+
+	// Can be adjusted by the user
+	cacheLength: 50,
+
+	createPseudo: markFunction,
+
+	match: matchExpr,
+
+	attrHandle: {},
+
+	find: {},
+
+	relative: {
+		">": { dir: "parentNode", first: true },
+		" ": { dir: "parentNode" },
+		"+": { dir: "previousSibling", first: true },
+		"~": { dir: "previousSibling" }
+	},
+
+	preFilter: {
+		"ATTR": function( match ) {
+			match[1] = match[1].replace( runescape, funescape );
+
+			// Move the given value to match[3] whether quoted or unquoted
+			match[3] = ( match[3] || match[4] || match[5] || "" ).replace( runescape, funescape );
+
+			if ( match[2] === "~=" ) {
+				match[3] = " " + match[3] + " ";
+			}
+
+			return match.slice( 0, 4 );
+		},
+
+		"CHILD": function( match ) {
+			/* matches from matchExpr["CHILD"]
+				1 type (only|nth|...)
+				2 what (child|of-type)
+				3 argument (even|odd|\d*|\d*n([+-]\d+)?|...)
+				4 xn-component of xn+y argument ([+-]?\d*n|)
+				5 sign of xn-component
+				6 x of xn-component
+				7 sign of y-component
+				8 y of y-component
+			*/
+			match[1] = match[1].toLowerCase();
+
+			if ( match[1].slice( 0, 3 ) === "nth" ) {
+				// nth-* requires argument
+				if ( !match[3] ) {
+					Sizzle.error( match[0] );
+				}
+
+				// numeric x and y parameters for Expr.filter.CHILD
+				// remember that false/true cast respectively to 0/1
+				match[4] = +( match[4] ? match[5] + (match[6] || 1) : 2 * ( match[3] === "even" || match[3] === "odd" ) );
+				match[5] = +( ( match[7] + match[8] ) || match[3] === "odd" );
+
+			// other types prohibit arguments
+			} else if ( match[3] ) {
+				Sizzle.error( match[0] );
+			}
+
+			return match;
+		},
+
+		"PSEUDO": function( match ) {
+			var excess,
+				unquoted = !match[6] && match[2];
+
+			if ( matchExpr["CHILD"].test( match[0] ) ) {
+				return null;
+			}
+
+			// Accept quoted arguments as-is
+			if ( match[3] ) {
+				match[2] = match[4] || match[5] || "";
+
+			// Strip excess characters from unquoted arguments
+			} else if ( unquoted && rpseudo.test( unquoted ) &&
+				// Get excess from tokenize (recursively)
+				(excess = tokenize( unquoted, true )) &&
+				// advance to the next closing parenthesis
+				(excess = unquoted.indexOf( ")", unquoted.length - excess ) - unquoted.length) ) {
+
+				// excess is a negative index
+				match[0] = match[0].slice( 0, excess );
+				match[2] = unquoted.slice( 0, excess );
+			}
+
+			// Return only captures needed by the pseudo filter method (type and argument)
+			return match.slice( 0, 3 );
+		}
+	},
+
+	filter: {
+
+		"TAG": function( nodeNameSelector ) {
+			var nodeName = nodeNameSelector.replace( runescape, funescape ).toLowerCase();
+			return nodeNameSelector === "*" ?
+				function() { return true; } :
+				function( elem ) {
+					return elem.nodeName && elem.nodeName.toLowerCase() === nodeName;
+				};
+		},
+
+		"CLASS": function( className ) {
+			var pattern = classCache[ className + " " ];
+
+			return pattern ||
+				(pattern = new RegExp( "(^|" + whitespace + ")" + className + "(" + whitespace + "|$)" )) &&
+				classCache( className, function( elem ) {
+					return pattern.test( typeof elem.className === "string" && elem.className || typeof elem.getAttribute !== "undefined" && elem.getAttribute("class") || "" );
+				});
+		},
+
+		"ATTR": function( name, operator, check ) {
+			return function( elem ) {
+				var result = Sizzle.attr( elem, name );
+
+				if ( result == null ) {
+					return operator === "!=";
+				}
+				if ( !operator ) {
+					return true;
+				}
+
+				result += "";
+
+				return operator === "=" ? result === check :
+					operator === "!=" ? result !== check :
+					operator === "^=" ? check && result.indexOf( check ) === 0 :
+					operator === "*=" ? check && result.indexOf( check ) > -1 :
+					operator === "$=" ? check && result.slice( -check.length ) === check :
+					operator === "~=" ? ( " " + result.replace( rwhitespace, " " ) + " " ).indexOf( check ) > -1 :
+					operator === "|=" ? result === check || result.slice( 0, check.length + 1 ) === check + "-" :
+					false;
+			};
+		},
+
+		"CHILD": function( type, what, argument, first, last ) {
+			var simple = type.slice( 0, 3 ) !== "nth",
+				forward = type.slice( -4 ) !== "last",
+				ofType = what === "of-type";
+
+			return first === 1 && last === 0 ?
+
+				// Shortcut for :nth-*(n)
+				function( elem ) {
+					return !!elem.parentNode;
+				} :
+
+				function( elem, context, xml ) {
+					var cache, uniqueCache, outerCache, node, nodeIndex, start,
+						dir = simple !== forward ? "nextSibling" : "previousSibling",
+						parent = elem.parentNode,
+						name = ofType && elem.nodeName.toLowerCase(),
+						useCache = !xml && !ofType,
+						diff = false;
+
+					if ( parent ) {
+
+						// :(first|last|only)-(child|of-type)
+						if ( simple ) {
+							while ( dir ) {
+								node = elem;
+								while ( (node = node[ dir ]) ) {
+									if ( ofType ?
+										node.nodeName.toLowerCase() === name :
+										node.nodeType === 1 ) {
+
+										return false;
+									}
+								}
+								// Reverse direction for :only-* (if we haven't yet done so)
+								start = dir = type === "only" && !start && "nextSibling";
+							}
+							return true;
+						}
+
+						start = [ forward ? parent.firstChild : parent.lastChild ];
+
+						// non-xml :nth-child(...) stores cache data on `parent`
+						if ( forward && useCache ) {
+
+							// Seek `elem` from a previously-cached index
+
+							// ...in a gzip-friendly way
+							node = parent;
+							outerCache = node[ expando ] || (node[ expando ] = {});
+
+							// Support: IE <9 only
+							// Defend against cloned attroperties (jQuery gh-1709)
+							uniqueCache = outerCache[ node.uniqueID ] ||
+								(outerCache[ node.uniqueID ] = {});
+
+							cache = uniqueCache[ type ] || [];
+							nodeIndex = cache[ 0 ] === dirruns && cache[ 1 ];
+							diff = nodeIndex && cache[ 2 ];
+							node = nodeIndex && parent.childNodes[ nodeIndex ];
+
+							while ( (node = ++nodeIndex && node && node[ dir ] ||
+
+								// Fallback to seeking `elem` from the start
+								(diff = nodeIndex = 0) || start.pop()) ) {
+
+								// When found, cache indexes on `parent` and break
+								if ( node.nodeType === 1 && ++diff && node === elem ) {
+									uniqueCache[ type ] = [ dirruns, nodeIndex, diff ];
+									break;
+								}
+							}
+
+						} else {
+							// Use previously-cached element index if available
+							if ( useCache ) {
+								// ...in a gzip-friendly way
+								node = elem;
+								outerCache = node[ expando ] || (node[ expando ] = {});
+
+								// Support: IE <9 only
+								// Defend against cloned attroperties (jQuery gh-1709)
+								uniqueCache = outerCache[ node.uniqueID ] ||
+									(outerCache[ node.uniqueID ] = {});
+
+								cache = uniqueCache[ type ] || [];
+								nodeIndex = cache[ 0 ] === dirruns && cache[ 1 ];
+								diff = nodeIndex;
+							}
+
+							// xml :nth-child(...)
+							// or :nth-last-child(...) or :nth(-last)?-of-type(...)
+							if ( diff === false ) {
+								// Use the same loop as above to seek `elem` from the start
+								while ( (node = ++nodeIndex && node && node[ dir ] ||
+									(diff = nodeIndex = 0) || start.pop()) ) {
+
+									if ( ( ofType ?
+										node.nodeName.toLowerCase() === name :
+										node.nodeType === 1 ) &&
+										++diff ) {
+
+										// Cache the index of each encountered element
+										if ( useCache ) {
+											outerCache = node[ expando ] || (node[ expando ] = {});
+
+											// Support: IE <9 only
+											// Defend against cloned attroperties (jQuery gh-1709)
+											uniqueCache = outerCache[ node.uniqueID ] ||
+												(outerCache[ node.uniqueID ] = {});
+
+											uniqueCache[ type ] = [ dirruns, diff ];
+										}
+
+										if ( node === elem ) {
+											break;
+										}
+									}
+								}
+							}
+						}
+
+						// Incorporate the offset, then check against cycle size
+						diff -= last;
+						return diff === first || ( diff % first === 0 && diff / first >= 0 );
+					}
+				};
+		},
+
+		"PSEUDO": function( pseudo, argument ) {
+			// pseudo-class names are case-insensitive
+			// http://www.w3.org/TR/selectors/#pseudo-classes
+			// Prioritize by case sensitivity in case custom pseudos are added with uppercase letters
+			// Remember that setFilters inherits from pseudos
+			var args,
+				fn = Expr.pseudos[ pseudo ] || Expr.setFilters[ pseudo.toLowerCase() ] ||
+					Sizzle.error( "unsupported pseudo: " + pseudo );
+
+			// The user may use createPseudo to indicate that
+			// arguments are needed to create the filter function
+			// just as Sizzle does
+			if ( fn[ expando ] ) {
+				return fn( argument );
+			}
+
+			// But maintain support for old signatures
+			if ( fn.length > 1 ) {
+				args = [ pseudo, pseudo, "", argument ];
+				return Expr.setFilters.hasOwnProperty( pseudo.toLowerCase() ) ?
+					markFunction(function( seed, matches ) {
+						var idx,
+							matched = fn( seed, argument ),
+							i = matched.length;
+						while ( i-- ) {
+							idx = indexOf( seed, matched[i] );
+							seed[ idx ] = !( matches[ idx ] = matched[i] );
+						}
+					}) :
+					function( elem ) {
+						return fn( elem, 0, args );
+					};
+			}
+
+			return fn;
+		}
+	},
+
+	pseudos: {
+		// Potentially complex pseudos
+		"not": markFunction(function( selector ) {
+			// Trim the selector passed to compile
+			// to avoid treating leading and trailing
+			// spaces as combinators
+			var input = [],
+				results = [],
+				matcher = compile( selector.replace( rtrim, "$1" ) );
+
+			return matcher[ expando ] ?
+				markFunction(function( seed, matches, context, xml ) {
+					var elem,
+						unmatched = matcher( seed, null, xml, [] ),
+						i = seed.length;
+
+					// Match elements unmatched by `matcher`
+					while ( i-- ) {
+						if ( (elem = unmatched[i]) ) {
+							seed[i] = !(matches[i] = elem);
+						}
+					}
+				}) :
+				function( elem, context, xml ) {
+					input[0] = elem;
+					matcher( input, null, xml, results );
+					// Don't keep the element (issue #299)
+					input[0] = null;
+					return !results.pop();
+				};
+		}),
+
+		"has": markFunction(function( selector ) {
+			return function( elem ) {
+				return Sizzle( selector, elem ).length > 0;
+			};
+		}),
+
+		"contains": markFunction(function( text ) {
+			text = text.replace( runescape, funescape );
+			return function( elem ) {
+				return ( elem.textContent || elem.innerText || getText( elem ) ).indexOf( text ) > -1;
+			};
+		}),
+
+		// "Whether an element is represented by a :lang() selector
+		// is based solely on the element's language value
+		// being equal to the identifier C,
+		// or beginning with the identifier C immediately followed by "-".
+		// The matching of C against the element's language value is performed case-insensitively.
+		// The identifier C does not have to be a valid language name."
+		// http://www.w3.org/TR/selectors/#lang-pseudo
+		"lang": markFunction( function( lang ) {
+			// lang value must be a valid identifier
+			if ( !ridentifier.test(lang || "") ) {
+				Sizzle.error( "unsupported lang: " + lang );
+			}
+			lang = lang.replace( runescape, funescape ).toLowerCase();
+			return function( elem ) {
+				var elemLang;
+				do {
+					if ( (elemLang = documentIsHTML ?
+						elem.lang :
+						elem.getAttribute("xml:lang") || elem.getAttribute("lang")) ) {
+
+						elemLang = elemLang.toLowerCase();
+						return elemLang === lang || elemLang.indexOf( lang + "-" ) === 0;
+					}
+				} while ( (elem = elem.parentNode) && elem.nodeType === 1 );
+				return false;
+			};
+		}),
+
+		// Miscellaneous
+		"target": function( elem ) {
+			var hash = window.location && window.location.hash;
+			return hash && hash.slice( 1 ) === elem.id;
+		},
+
+		"root": function( elem ) {
+			return elem === docElem;
+		},
+
+		"focus": function( elem ) {
+			return elem === document.activeElement && (!document.hasFocus || document.hasFocus()) && !!(elem.type || elem.href || ~elem.tabIndex);
+		},
+
+		// Boolean properties
+		"enabled": function( elem ) {
+			return elem.disabled === false;
+		},
+
+		"disabled": function( elem ) {
+			return elem.disabled === true;
+		},
+
+		"checked": function( elem ) {
+			// In CSS3, :checked should return both checked and selected elements
+			// http://www.w3.org/TR/2011/REC-css3-selectors-20110929/#checked
+			var nodeName = elem.nodeName.toLowerCase();
+			return (nodeName === "input" && !!elem.checked) || (nodeName === "option" && !!elem.selected);
+		},
+
+		"selected": function( elem ) {
+			// Accessing this property makes selected-by-default
+			// options in Safari work properly
+			if ( elem.parentNode ) {
+				elem.parentNode.selectedIndex;
+			}
+
+			return elem.selected === true;
+		},
+
+		// Contents
+		"empty": function( elem ) {
+			// http://www.w3.org/TR/selectors/#empty-pseudo
+			// :empty is negated by element (1) or content nodes (text: 3; cdata: 4; entity ref: 5),
+			//   but not by others (comment: 8; processing instruction: 7; etc.)
+			// nodeType < 6 works because attributes (2) do not appear as children
+			for ( elem = elem.firstChild; elem; elem = elem.nextSibling ) {
+				if ( elem.nodeType < 6 ) {
+					return false;
+				}
+			}
+			return true;
+		},
+
+		"parent": function( elem ) {
+			return !Expr.pseudos["empty"]( elem );
+		},
+
+		// Element/input types
+		"header": function( elem ) {
+			return rheader.test( elem.nodeName );
+		},
+
+		"input": function( elem ) {
+			return rinputs.test( elem.nodeName );
+		},
+
+		"button": function( elem ) {
+			var name = elem.nodeName.toLowerCase();
+			return name === "input" && elem.type === "button" || name === "button";
+		},
+
+		"text": function( elem ) {
+			var attr;
+			return elem.nodeName.toLowerCase() === "input" &&
+				elem.type === "text" &&
+
+				// Support: IE<8
+				// New HTML5 attribute values (e.g., "search") appear with elem.type === "text"
+				( (attr = elem.getAttribute("type")) == null || attr.toLowerCase() === "text" );
+		},
+
+		// Position-in-collection
+		"first": createPositionalPseudo(function() {
+			return [ 0 ];
+		}),
+
+		"last": createPositionalPseudo(function( matchIndexes, length ) {
+			return [ length - 1 ];
+		}),
+
+		"eq": createPositionalPseudo(function( matchIndexes, length, argument ) {
+			return [ argument < 0 ? argument + length : argument ];
+		}),
+
+		"even": createPositionalPseudo(function( matchIndexes, length ) {
+			var i = 0;
+			for ( ; i < length; i += 2 ) {
+				matchIndexes.push( i );
+			}
+			return matchIndexes;
+		}),
+
+		"odd": createPositionalPseudo(function( matchIndexes, length ) {
+			var i = 1;
+			for ( ; i < length; i += 2 ) {
+				matchIndexes.push( i );
+			}
+			return matchIndexes;
+		}),
+
+		"lt": createPositionalPseudo(function( matchIndexes, length, argument ) {
+			var i = argument < 0 ? argument + length : argument;
+			for ( ; --i >= 0; ) {
+				matchIndexes.push( i );
+			}
+			return matchIndexes;
+		}),
+
+		"gt": createPositionalPseudo(function( matchIndexes, length, argument ) {
+			var i = argument < 0 ? argument + length : argument;
+			for ( ; ++i < length; ) {
+				matchIndexes.push( i );
+			}
+			return matchIndexes;
+		})
+	}
+};
+
+Expr.pseudos["nth"] = Expr.pseudos["eq"];
+
+// Add button/input type pseudos
+for ( i in { radio: true, checkbox: true, file: true, password: true, image: true } ) {
+	Expr.pseudos[ i ] = createInputPseudo( i );
+}
+for ( i in { submit: true, reset: true } ) {
+	Expr.pseudos[ i ] = createButtonPseudo( i );
+}
+
+// Easy API for creating new setFilters
+function setFilters() {}
+setFilters.prototype = Expr.filters = Expr.pseudos;
+Expr.setFilters = new setFilters();
+
+tokenize = Sizzle.tokenize = function( selector, parseOnly ) {
+	var matched, match, tokens, type,
+		soFar, groups, preFilters,
+		cached = tokenCache[ selector + " " ];
+
+	if ( cached ) {
+		return parseOnly ? 0 : cached.slice( 0 );
+	}
+
+	soFar = selector;
+	groups = [];
+	preFilters = Expr.preFilter;
+
+	while ( soFar ) {
+
+		// Comma and first run
+		if ( !matched || (match = rcomma.exec( soFar )) ) {
+			if ( match ) {
+				// Don't consume trailing commas as valid
+				soFar = soFar.slice( match[0].length ) || soFar;
+			}
+			groups.push( (tokens = []) );
+		}
+
+		matched = false;
+
+		// Combinators
+		if ( (match = rcombinators.exec( soFar )) ) {
+			matched = match.shift();
+			tokens.push({
+				value: matched,
+				// Cast descendant combinators to space
+				type: match[0].replace( rtrim, " " )
+			});
+			soFar = soFar.slice( matched.length );
+		}
+
+		// Filters
+		for ( type in Expr.filter ) {
+			if ( (match = matchExpr[ type ].exec( soFar )) && (!preFilters[ type ] ||
+				(match = preFilters[ type ]( match ))) ) {
+				matched = match.shift();
+				tokens.push({
+					value: matched,
+					type: type,
+					matches: match
+				});
+				soFar = soFar.slice( matched.length );
+			}
+		}
+
+		if ( !matched ) {
+			break;
+		}
+	}
+
+	// Return the length of the invalid excess
+	// if we're just parsing
+	// Otherwise, throw an error or return tokens
+	return parseOnly ?
+		soFar.length :
+		soFar ?
+			Sizzle.error( selector ) :
+			// Cache the tokens
+			tokenCache( selector, groups ).slice( 0 );
+};
+
+function toSelector( tokens ) {
+	var i = 0,
+		len = tokens.length,
+		selector = "";
+	for ( ; i < len; i++ ) {
+		selector += tokens[i].value;
+	}
+	return selector;
+}
+
+function addCombinator( matcher, combinator, base ) {
+	var dir = combinator.dir,
+		checkNonElements = base && dir === "parentNode",
+		doneName = done++;
+
+	return combinator.first ?
+		// Check against closest ancestor/preceding element
+		function( elem, context, xml ) {
+			while ( (elem = elem[ dir ]) ) {
+				if ( elem.nodeType === 1 || checkNonElements ) {
+					return matcher( elem, context, xml );
+				}
+			}
+		} :
+
+		// Check against all ancestor/preceding elements
+		function( elem, context, xml ) {
+			var oldCache, uniqueCache, outerCache,
+				newCache = [ dirruns, doneName ];
+
+			// We can't set arbitrary data on XML nodes, so they don't benefit from combinator caching
+			if ( xml ) {
+				while ( (elem = elem[ dir ]) ) {
+					if ( elem.nodeType === 1 || checkNonElements ) {
+						if ( matcher( elem, context, xml ) ) {
+							return true;
+						}
+					}
+				}
+			} else {
+				while ( (elem = elem[ dir ]) ) {
+					if ( elem.nodeType === 1 || checkNonElements ) {
+						outerCache = elem[ expando ] || (elem[ expando ] = {});
+
+						// Support: IE <9 only
+						// Defend against cloned attroperties (jQuery gh-1709)
+						uniqueCache = outerCache[ elem.uniqueID ] || (outerCache[ elem.uniqueID ] = {});
+
+						if ( (oldCache = uniqueCache[ dir ]) &&
+							oldCache[ 0 ] === dirruns && oldCache[ 1 ] === doneName ) {
+
+							// Assign to newCache so results back-propagate to previous elements
+							return (newCache[ 2 ] = oldCache[ 2 ]);
+						} else {
+							// Reuse newcache so results back-propagate to previous elements
+							uniqueCache[ dir ] = newCache;
+
+							// A match means we're done; a fail means we have to keep checking
+							if ( (newCache[ 2 ] = matcher( elem, context, xml )) ) {
+								return true;
+							}
+						}
+					}
+				}
+			}
+		};
+}
+
+function elementMatcher( matchers ) {
+	return matchers.length > 1 ?
+		function( elem, context, xml ) {
+			var i = matchers.length;
+			while ( i-- ) {
+				if ( !matchers[i]( elem, context, xml ) ) {
+					return false;
+				}
+			}
+			return true;
+		} :
+		matchers[0];
+}
+
+function multipleContexts( selector, contexts, results ) {
+	var i = 0,
+		len = contexts.length;
+	for ( ; i < len; i++ ) {
+		Sizzle( selector, contexts[i], results );
+	}
+	return results;
+}
+
+function condense( unmatched, map, filter, context, xml ) {
+	var elem,
+		newUnmatched = [],
+		i = 0,
+		len = unmatched.length,
+		mapped = map != null;
+
+	for ( ; i < len; i++ ) {
+		if ( (elem = unmatched[i]) ) {
+			if ( !filter || filter( elem, context, xml ) ) {
+				newUnmatched.push( elem );
+				if ( mapped ) {
+					map.push( i );
+				}
+			}
+		}
+	}
+
+	return newUnmatched;
+}
+
+function setMatcher( preFilter, selector, matcher, postFilter, postFinder, postSelector ) {
+	if ( postFilter && !postFilter[ expando ] ) {
+		postFilter = setMatcher( postFilter );
+	}
+	if ( postFinder && !postFinder[ expando ] ) {
+		postFinder = setMatcher( postFinder, postSelector );
+	}
+	return markFunction(function( seed, results, context, xml ) {
+		var temp, i, elem,
+			preMap = [],
+			postMap = [],
+			preexisting = results.length,
+
+			// Get initial elements from seed or context
+			elems = seed || multipleContexts( selector || "*", context.nodeType ? [ context ] : context, [] ),
+
+			// Prefilter to get matcher input, preserving a map for seed-results synchronization
+			matcherIn = preFilter && ( seed || !selector ) ?
+				condense( elems, preMap, preFilter, context, xml ) :
+				elems,
+
+			matcherOut = matcher ?
+				// If we have a postFinder, or filtered seed, or non-seed postFilter or preexisting results,
+				postFinder || ( seed ? preFilter : preexisting || postFilter ) ?
+
+					// ...intermediate processing is necessary
+					[] :
+
+					// ...otherwise use results directly
+					results :
+				matcherIn;
+
+		// Find primary matches
+		if ( matcher ) {
+			matcher( matcherIn, matcherOut, context, xml );
+		}
+
+		// Apply postFilter
+		if ( postFilter ) {
+			temp = condense( matcherOut, postMap );
+			postFilter( temp, [], context, xml );
+
+			// Un-match failing elements by moving them back to matcherIn
+			i = temp.length;
+			while ( i-- ) {
+				if ( (elem = temp[i]) ) {
+					matcherOut[ postMap[i] ] = !(matcherIn[ postMap[i] ] = elem);
+				}
+			}
+		}
+
+		if ( seed ) {
+			if ( postFinder || preFilter ) {
+				if ( postFinder ) {
+					// Get the final matcherOut by condensing this intermediate into postFinder contexts
+					temp = [];
+					i = matcherOut.length;
+					while ( i-- ) {
+						if ( (elem = matcherOut[i]) ) {
+							// Restore matcherIn since elem is not yet a final match
+							temp.push( (matcherIn[i] = elem) );
+						}
+					}
+					postFinder( null, (matcherOut = []), temp, xml );
+				}
+
+				// Move matched elements from seed to results to keep them synchronized
+				i = matcherOut.length;
+				while ( i-- ) {
+					if ( (elem = matcherOut[i]) &&
+						(temp = postFinder ? indexOf( seed, elem ) : preMap[i]) > -1 ) {
+
+						seed[temp] = !(results[temp] = elem);
+					}
+				}
+			}
+
+		// Add elements to results, through postFinder if defined
+		} else {
+			matcherOut = condense(
+				matcherOut === results ?
+					matcherOut.splice( preexisting, matcherOut.length ) :
+					matcherOut
+			);
+			if ( postFinder ) {
+				postFinder( null, results, matcherOut, xml );
+			} else {
+				push.apply( results, matcherOut );
+			}
+		}
+	});
+}
+
+function matcherFromTokens( tokens ) {
+	var checkContext, matcher, j,
+		len = tokens.length,
+		leadingRelative = Expr.relative[ tokens[0].type ],
+		implicitRelative = leadingRelative || Expr.relative[" "],
+		i = leadingRelative ? 1 : 0,
+
+		// The foundational matcher ensures that elements are reachable from top-level context(s)
+		matchContext = addCombinator( function( elem ) {
+			return elem === checkContext;
+		}, implicitRelative, true ),
+		matchAnyContext = addCombinator( function( elem ) {
+			return indexOf( checkContext, elem ) > -1;
+		}, implicitRelative, true ),
+		matchers = [ function( elem, context, xml ) {
+			var ret = ( !leadingRelative && ( xml || context !== outermostContext ) ) || (
+				(checkContext = context).nodeType ?
+					matchContext( elem, context, xml ) :
+					matchAnyContext( elem, context, xml ) );
+			// Avoid hanging onto element (issue #299)
+			checkContext = null;
+			return ret;
+		} ];
+
+	for ( ; i < len; i++ ) {
+		if ( (matcher = Expr.relative[ tokens[i].type ]) ) {
+			matchers = [ addCombinator(elementMatcher( matchers ), matcher) ];
+		} else {
+			matcher = Expr.filter[ tokens[i].type ].apply( null, tokens[i].matches );
+
+			// Return special upon seeing a positional matcher
+			if ( matcher[ expando ] ) {
+				// Find the next relative operator (if any) for proper handling
+				j = ++i;
+				for ( ; j < len; j++ ) {
+					if ( Expr.relative[ tokens[j].type ] ) {
+						break;
+					}
+				}
+				return setMatcher(
+					i > 1 && elementMatcher( matchers ),
+					i > 1 && toSelector(
+						// If the preceding token was a descendant combinator, insert an implicit any-element `*`
+						tokens.slice( 0, i - 1 ).concat({ value: tokens[ i - 2 ].type === " " ? "*" : "" })
+					).replace( rtrim, "$1" ),
+					matcher,
+					i < j && matcherFromTokens( tokens.slice( i, j ) ),
+					j < len && matcherFromTokens( (tokens = tokens.slice( j )) ),
+					j < len && toSelector( tokens )
+				);
+			}
+			matchers.push( matcher );
+		}
+	}
+
+	return elementMatcher( matchers );
+}
+
+function matcherFromGroupMatchers( elementMatchers, setMatchers ) {
+	var bySet = setMatchers.length > 0,
+		byElement = elementMatchers.length > 0,
+		superMatcher = function( seed, context, xml, results, outermost ) {
+			var elem, j, matcher,
+				matchedCount = 0,
+				i = "0",
+				unmatched = seed && [],
+				setMatched = [],
+				contextBackup = outermostContext,
+				// We must always have either seed elements or outermost context
+				elems = seed || byElement && Expr.find["TAG"]( "*", outermost ),
+				// Use integer dirruns iff this is the outermost matcher
+				dirrunsUnique = (dirruns += contextBackup == null ? 1 : Math.random() || 0.1),
+				len = elems.length;
+
+			if ( outermost ) {
+				outermostContext = context === document || context || outermost;
+			}
+
+			// Add elements passing elementMatchers directly to results
+			// Support: IE<9, Safari
+			// Tolerate NodeList properties (IE: "length"; Safari: <number>) matching elements by id
+			for ( ; i !== len && (elem = elems[i]) != null; i++ ) {
+				if ( byElement && elem ) {
+					j = 0;
+					if ( !context && elem.ownerDocument !== document ) {
+						setDocument( elem );
+						xml = !documentIsHTML;
+					}
+					while ( (matcher = elementMatchers[j++]) ) {
+						if ( matcher( elem, context || document, xml) ) {
+							results.push( elem );
+							break;
+						}
+					}
+					if ( outermost ) {
+						dirruns = dirrunsUnique;
+					}
+				}
+
+				// Track unmatched elements for set filters
+				if ( bySet ) {
+					// They will have gone through all possible matchers
+					if ( (elem = !matcher && elem) ) {
+						matchedCount--;
+					}
+
+					// Lengthen the array for every element, matched or not
+					if ( seed ) {
+						unmatched.push( elem );
+					}
+				}
+			}
+
+			// `i` is now the count of elements visited above, and adding it to `matchedCount`
+			// makes the latter nonnegative.
+			matchedCount += i;
+
+			// Apply set filters to unmatched elements
+			// NOTE: This can be skipped if there are no unmatched elements (i.e., `matchedCount`
+			// equals `i`), unless we didn't visit _any_ elements in the above loop because we have
+			// no element matchers and no seed.
+			// Incrementing an initially-string "0" `i` allows `i` to remain a string only in that
+			// case, which will result in a "00" `matchedCount` that differs from `i` but is also
+			// numerically zero.
+			if ( bySet && i !== matchedCount ) {
+				j = 0;
+				while ( (matcher = setMatchers[j++]) ) {
+					matcher( unmatched, setMatched, context, xml );
+				}
+
+				if ( seed ) {
+					// Reintegrate element matches to eliminate the need for sorting
+					if ( matchedCount > 0 ) {
+						while ( i-- ) {
+							if ( !(unmatched[i] || setMatched[i]) ) {
+								setMatched[i] = pop.call( results );
+							}
+						}
+					}
+
+					// Discard index placeholder values to get only actual matches
+					setMatched = condense( setMatched );
+				}
+
+				// Add matches to results
+				push.apply( results, setMatched );
+
+				// Seedless set matches succeeding multiple successful matchers stipulate sorting
+				if ( outermost && !seed && setMatched.length > 0 &&
+					( matchedCount + setMatchers.length ) > 1 ) {
+
+					Sizzle.uniqueSort( results );
+				}
+			}
+
+			// Override manipulation of globals by nested matchers
+			if ( outermost ) {
+				dirruns = dirrunsUnique;
+				outermostContext = contextBackup;
+			}
+
+			return unmatched;
+		};
+
+	return bySet ?
+		markFunction( superMatcher ) :
+		superMatcher;
+}
+
+compile = Sizzle.compile = function( selector, match /* Internal Use Only */ ) {
+	var i,
+		setMatchers = [],
+		elementMatchers = [],
+		cached = compilerCache[ selector + " " ];
+
+	if ( !cached ) {
+		// Generate a function of recursive functions that can be used to check each element
+		if ( !match ) {
+			match = tokenize( selector );
+		}
+		i = match.length;
+		while ( i-- ) {
+			cached = matcherFromTokens( match[i] );
+			if ( cached[ expando ] ) {
+				setMatchers.push( cached );
+			} else {
+				elementMatchers.push( cached );
+			}
+		}
+
+		// Cache the compiled function
+		cached = compilerCache( selector, matcherFromGroupMatchers( elementMatchers, setMatchers ) );
+
+		// Save selector and tokenization
+		cached.selector = selector;
+	}
+	return cached;
+};
+
+/**
+ * A low-level selection function that works with Sizzle's compiled
+ *  selector functions
+ * @param {String|Function} selector A selector or a pre-compiled
+ *  selector function built with Sizzle.compile
+ * @param {Element} context
+ * @param {Array} [results]
+ * @param {Array} [seed] A set of elements to match against
+ */
+select = Sizzle.select = function( selector, context, results, seed ) {
+	var i, tokens, token, type, find,
+		compiled = typeof selector === "function" && selector,
+		match = !seed && tokenize( (selector = compiled.selector || selector) );
+
+	results = results || [];
+
+	// Try to minimize operations if there is only one selector in the list and no seed
+	// (the latter of which guarantees us context)
+	if ( match.length === 1 ) {
+
+		// Reduce context if the leading compound selector is an ID
+		tokens = match[0] = match[0].slice( 0 );
+		if ( tokens.length > 2 && (token = tokens[0]).type === "ID" &&
+				support.getById && context.nodeType === 9 && documentIsHTML &&
+				Expr.relative[ tokens[1].type ] ) {
+
+			context = ( Expr.find["ID"]( token.matches[0].replace(runescape, funescape), context ) || [] )[0];
+			if ( !context ) {
+				return results;
+
+			// Precompiled matchers will still verify ancestry, so step up a level
+			} else if ( compiled ) {
+				context = context.parentNode;
+			}
+
+			selector = selector.slice( tokens.shift().value.length );
+		}
+
+		// Fetch a seed set for right-to-left matching
+		i = matchExpr["needsContext"].test( selector ) ? 0 : tokens.length;
+		while ( i-- ) {
+			token = tokens[i];
+
+			// Abort if we hit a combinator
+			if ( Expr.relative[ (type = token.type) ] ) {
+				break;
+			}
+			if ( (find = Expr.find[ type ]) ) {
+				// Search, expanding context for leading sibling combinators
+				if ( (seed = find(
+					token.matches[0].replace( runescape, funescape ),
+					rsibling.test( tokens[0].type ) && testContext( context.parentNode ) || context
+				)) ) {
+
+					// If seed is empty or no tokens remain, we can return early
+					tokens.splice( i, 1 );
+					selector = seed.length && toSelector( tokens );
+					if ( !selector ) {
+						push.apply( results, seed );
+						return results;
+					}
+
+					break;
+				}
+			}
+		}
+	}
+
+	// Compile and execute a filtering function if one is not provided
+	// Provide `match` to avoid retokenization if we modified the selector above
+	( compiled || compile( selector, match ) )(
+		seed,
+		context,
+		!documentIsHTML,
+		results,
+		!context || rsibling.test( selector ) && testContext( context.parentNode ) || context
+	);
+	return results;
+};
+
+// One-time assignments
+
+// Sort stability
+support.sortStable = expando.split("").sort( sortOrder ).join("") === expando;
+
+// Support: Chrome 14-35+
+// Always assume duplicates if they aren't passed to the comparison function
+support.detectDuplicates = !!hasDuplicate;
+
+// Initialize against the default document
+setDocument();
+
+// Support: Webkit<537.32 - Safari 6.0.3/Chrome 25 (fixed in Chrome 27)
+// Detached nodes confoundingly follow *each other*
+support.sortDetached = assert(function( div1 ) {
+	// Should return 1, but returns 4 (following)
+	return div1.compareDocumentPosition( document.createElement("div") ) & 1;
+});
+
+// Support: IE<8
+// Prevent attribute/property "interpolation"
+// http://msdn.microsoft.com/en-us/library/ms536429%28VS.85%29.aspx
+if ( !assert(function( div ) {
+	div.innerHTML = "<a href='#'></a>";
+	return div.firstChild.getAttribute("href") === "#" ;
+}) ) {
+	addHandle( "type|href|height|width", function( elem, name, isXML ) {
+		if ( !isXML ) {
+			return elem.getAttribute( name, name.toLowerCase() === "type" ? 1 : 2 );
+		}
+	});
+}
+
+// Support: IE<9
+// Use defaultValue in place of getAttribute("value")
+if ( !support.attributes || !assert(function( div ) {
+	div.innerHTML = "<input/>";
+	div.firstChild.setAttribute( "value", "" );
+	return div.firstChild.getAttribute( "value" ) === "";
+}) ) {
+	addHandle( "value", function( elem, name, isXML ) {
+		if ( !isXML && elem.nodeName.toLowerCase() === "input" ) {
+			return elem.defaultValue;
+		}
+	});
+}
+
+// Support: IE<9
+// Use getAttributeNode to fetch booleans when getAttribute lies
+if ( !assert(function( div ) {
+	return div.getAttribute("disabled") == null;
+}) ) {
+	addHandle( booleans, function( elem, name, isXML ) {
+		var val;
+		if ( !isXML ) {
+			return elem[ name ] === true ? name.toLowerCase() :
+					(val = elem.getAttributeNode( name )) && val.specified ?
+					val.value :
+				null;
+		}
+	});
+}
+
+return Sizzle;
+
+})( window );
+
+
+
+jQuery.find = Sizzle;
+jQuery.expr = Sizzle.selectors;
+jQuery.expr[ ":" ] = jQuery.expr.pseudos;
+jQuery.uniqueSort = jQuery.unique = Sizzle.uniqueSort;
+jQuery.text = Sizzle.getText;
+jQuery.isXMLDoc = Sizzle.isXML;
+jQuery.contains = Sizzle.contains;
+
+
+
+var dir = function( elem, dir, until ) {
+	var matched = [],
+		truncate = until !== undefined;
+
+	while ( ( elem = elem[ dir ] ) && elem.nodeType !== 9 ) {
+		if ( elem.nodeType === 1 ) {
+			if ( truncate && jQuery( elem ).is( until ) ) {
+				break;
+			}
+			matched.push( elem );
+		}
+	}
+	return matched;
+};
+
+
+var siblings = function( n, elem ) {
+	var matched = [];
+
+	for ( ; n; n = n.nextSibling ) {
+		if ( n.nodeType === 1 && n !== elem ) {
+			matched.push( n );
+		}
+	}
+
+	return matched;
+};
+
+
+var rneedsContext = jQuery.expr.match.needsContext;
+
+var rsingleTag = ( /^<([\w-]+)\s*\/?>(?:<\/\1>|)$/ );
+
+
+
+var risSimple = /^.[^:#\[\.,]*$/;
+
+// Implement the identical functionality for filter and not
+function winnow( elements, qualifier, not ) {
+	if ( jQuery.isFunction( qualifier ) ) {
+		return jQuery.grep( elements, function( elem, i ) {
+			/* jshint -W018 */
+			return !!qualifier.call( elem, i, elem ) !== not;
+		} );
+
+	}
+
+	if ( qualifier.nodeType ) {
+		return jQuery.grep( elements, function( elem ) {
+			return ( elem === qualifier ) !== not;
+		} );
+
+	}
+
+	if ( typeof qualifier === "string" ) {
+		if ( risSimple.test( qualifier ) ) {
+			return jQuery.filter( qualifier, elements, not );
+		}
+
+		qualifier = jQuery.filter( qualifier, elements );
+	}
+
+	return jQuery.grep( elements, function( elem ) {
+		return ( jQuery.inArray( elem, qualifier ) > -1 ) !== not;
+	} );
+}
+
+jQuery.filter = function( expr, elems, not ) {
+	var elem = elems[ 0 ];
+
+	if ( not ) {
+		expr = ":not(" + expr + ")";
+	}
+
+	return elems.length === 1 && elem.nodeType === 1 ?
+		jQuery.find.matchesSelector( elem, expr ) ? [ elem ] : [] :
+		jQuery.find.matches( expr, jQuery.grep( elems, function( elem ) {
+			return elem.nodeType === 1;
+		} ) );
+};
+
+jQuery.fn.extend( {
+	find: function( selector ) {
+		var i,
+			ret = [],
+			self = this,
+			len = self.length;
+
+		if ( typeof selector !== "string" ) {
+			return this.pushStack( jQuery( selector ).filter( function() {
+				for ( i = 0; i < len; i++ ) {
+					if ( jQuery.contains( self[ i ], this ) ) {
+						return true;
+					}
+				}
+			} ) );
+		}
+
+		for ( i = 0; i < len; i++ ) {
+			jQuery.find( selector, self[ i ], ret );
+		}
+
+		// Needed because $( selector, context ) becomes $( context ).find( selector )
+		ret = this.pushStack( len > 1 ? jQuery.unique( ret ) : ret );
+		ret.selector = this.selector ? this.selector + " " + selector : selector;
+		return ret;
+	},
+	filter: function( selector ) {
+		return this.pushStack( winnow( this, selector || [], false ) );
+	},
+	not: function( selector ) {
+		return this.pushStack( winnow( this, selector || [], true ) );
+	},
+	is: function( selector ) {
+		return !!winnow(
+			this,
+
+			// If this is a positional/relative selector, check membership in the returned set
+			// so $("p:first").is("p:last") won't return true for a doc with two "p".
+			typeof selector === "string" && rneedsContext.test( selector ) ?
+				jQuery( selector ) :
+				selector || [],
+			false
+		).length;
+	}
+} );
+
+
+// Initialize a jQuery object
+
+
+// A central reference to the root jQuery(document)
+var rootjQuery,
+
+	// A simple way to check for HTML strings
+	// Prioritize #id over <tag> to avoid XSS via location.hash (#9521)
+	// Strict HTML recognition (#11290: must start with <)
+	rquickExpr = /^(?:\s*(<[\w\W]+>)[^>]*|#([\w-]*))$/,
+
+	init = jQuery.fn.init = function( selector, context, root ) {
+		var match, elem;
+
+		// HANDLE: $(""), $(null), $(undefined), $(false)
+		if ( !selector ) {
+			return this;
+		}
+
+		// init accepts an alternate rootjQuery
+		// so migrate can support jQuery.sub (gh-2101)
+		root = root || rootjQuery;
+
+		// Handle HTML strings
+		if ( typeof selector === "string" ) {
+			if ( selector.charAt( 0 ) === "<" &&
+				selector.charAt( selector.length - 1 ) === ">" &&
+				selector.length >= 3 ) {
+
+				// Assume that strings that start and end with <> are HTML and skip the regex check
+				match = [ null, selector, null ];
+
+			} else {
+				match = rquickExpr.exec( selector );
+			}
+
+			// Match html or make sure no context is specified for #id
+			if ( match && ( match[ 1 ] || !context ) ) {
+
+				// HANDLE: $(html) -> $(array)
+				if ( match[ 1 ] ) {
+					context = context instanceof jQuery ? context[ 0 ] : context;
+
+					// scripts is true for back-compat
+					// Intentionally let the error be thrown if parseHTML is not present
+					jQuery.merge( this, jQuery.parseHTML(
+						match[ 1 ],
+						context && context.nodeType ? context.ownerDocument || context : document,
+						true
+					) );
+
+					// HANDLE: $(html, props)
+					if ( rsingleTag.test( match[ 1 ] ) && jQuery.isPlainObject( context ) ) {
+						for ( match in context ) {
+
+							// Properties of context are called as methods if possible
+							if ( jQuery.isFunction( this[ match ] ) ) {
+								this[ match ]( context[ match ] );
+
+							// ...and otherwise set as attributes
+							} else {
+								this.attr( match, context[ match ] );
+							}
+						}
+					}
+
+					return this;
+
+				// HANDLE: $(#id)
+				} else {
+					elem = document.getElementById( match[ 2 ] );
+
+					// Check parentNode to catch when Blackberry 4.6 returns
+					// nodes that are no longer in the document #6963
+					if ( elem && elem.parentNode ) {
+
+						// Handle the case where IE and Opera return items
+						// by name instead of ID
+						if ( elem.id !== match[ 2 ] ) {
+							return rootjQuery.find( selector );
+						}
+
+						// Otherwise, we inject the element directly into the jQuery object
+						this.length = 1;
+						this[ 0 ] = elem;
+					}
+
+					this.context = document;
+					this.selector = selector;
+					return this;
+				}
+
+			// HANDLE: $(expr, $(...))
+			} else if ( !context || context.jquery ) {
+				return ( context || root ).find( selector );
+
+			// HANDLE: $(expr, context)
+			// (which is just equivalent to: $(context).find(expr)
+			} else {
+				return this.constructor( context ).find( selector );
+			}
+
+		// HANDLE: $(DOMElement)
+		} else if ( selector.nodeType ) {
+			this.context = this[ 0 ] = selector;
+			this.length = 1;
+			return this;
+
+		// HANDLE: $(function)
+		// Shortcut for document ready
+		} else if ( jQuery.isFunction( selector ) ) {
+			return typeof root.ready !== "undefined" ?
+				root.ready( selector ) :
+
+				// Execute immediately if ready is not present
+				selector( jQuery );
+		}
+
+		if ( selector.selector !== undefined ) {
+			this.selector = selector.selector;
+			this.context = selector.context;
+		}
+
+		return jQuery.makeArray( selector, this );
+	};
+
+// Give the init function the jQuery prototype for later instantiation
+init.prototype = jQuery.fn;
+
+// Initialize central reference
+rootjQuery = jQuery( document );
+
+
+var rparentsprev = /^(?:parents|prev(?:Until|All))/,
+
+	// methods guaranteed to produce a unique set when starting from a unique set
+	guaranteedUnique = {
+		children: true,
+		contents: true,
+		next: true,
+		prev: true
+	};
+
+jQuery.fn.extend( {
+	has: function( target ) {
+		var i,
+			targets = jQuery( target, this ),
+			len = targets.length;
+
+		return this.filter( function() {
+			for ( i = 0; i < len; i++ ) {
+				if ( jQuery.contains( this, targets[ i ] ) ) {
+					return true;
+				}
+			}
+		} );
+	},
+
+	closest: function( selectors, context ) {
+		var cur,
+			i = 0,
+			l = this.length,
+			matched = [],
+			pos = rneedsContext.test( selectors ) || typeof selectors !== "string" ?
+				jQuery( selectors, context || this.context ) :
+				0;
+
+		for ( ; i < l; i++ ) {
+			for ( cur = this[ i ]; cur && cur !== context; cur = cur.parentNode ) {
+
+				// Always skip document fragments
+				if ( cur.nodeType < 11 && ( pos ?
+					pos.index( cur ) > -1 :
+
+					// Don't pass non-elements to Sizzle
+					cur.nodeType === 1 &&
+						jQuery.find.matchesSelector( cur, selectors ) ) ) {
+
+					matched.push( cur );
+					break;
+				}
+			}
+		}
+
+		return this.pushStack( matched.length > 1 ? jQuery.uniqueSort( matched ) : matched );
+	},
+
+	// Determine the position of an element within
+	// the matched set of elements
+	index: function( elem ) {
+
+		// No argument, return index in parent
+		if ( !elem ) {
+			return ( this[ 0 ] && this[ 0 ].parentNode ) ? this.first().prevAll().length : -1;
+		}
+
+		// index in selector
+		if ( typeof elem === "string" ) {
+			return jQuery.inArray( this[ 0 ], jQuery( elem ) );
+		}
+
+		// Locate the position of the desired element
+		return jQuery.inArray(
+
+			// If it receives a jQuery object, the first element is used
+			elem.jquery ? elem[ 0 ] : elem, this );
+	},
+
+	add: function( selector, context ) {
+		return this.pushStack(
+			jQuery.uniqueSort(
+				jQuery.merge( this.get(), jQuery( selector, context ) )
+			)
+		);
+	},
+
+	addBack: function( selector ) {
+		return this.add( selector == null ?
+			this.prevObject : this.prevObject.filter( selector )
+		);
+	}
+} );
+
+function sibling( cur, dir ) {
+	do {
+		cur = cur[ dir ];
+	} while ( cur && cur.nodeType !== 1 );
+
+	return cur;
+}
+
+jQuery.each( {
+	parent: function( elem ) {
+		var parent = elem.parentNode;
+		return parent && parent.nodeType !== 11 ? parent : null;
+	},
+	parents: function( elem ) {
+		return dir( elem, "parentNode" );
+	},
+	parentsUntil: function( elem, i, until ) {
+		return dir( elem, "parentNode", until );
+	},
+	next: function( elem ) {
+		return sibling( elem, "nextSibling" );
+	},
+	prev: function( elem ) {
+		return sibling( elem, "previousSibling" );
+	},
+	nextAll: function( elem ) {
+		return dir( elem, "nextSibling" );
+	},
+	prevAll: function( elem ) {
+		return dir( elem, "previousSibling" );
+	},
+	nextUntil: function( elem, i, until ) {
+		return dir( elem, "nextSibling", until );
+	},
+	prevUntil: function( elem, i, until ) {
+		return dir( elem, "previousSibling", until );
+	},
+	siblings: function( elem ) {
+		return siblings( ( elem.parentNode || {} ).firstChild, elem );
+	},
+	children: function( elem ) {
+		return siblings( elem.firstChild );
+	},
+	contents: function( elem ) {
+		return jQuery.nodeName( elem, "iframe" ) ?
+			elem.contentDocument || elem.contentWindow.document :
+			jQuery.merge( [], elem.childNodes );
+	}
+}, function( name, fn ) {
+	jQuery.fn[ name ] = function( until, selector ) {
+		var ret = jQuery.map( this, fn, until );
+
+		if ( name.slice( -5 ) !== "Until" ) {
+			selector = until;
+		}
+
+		if ( selector && typeof selector === "string" ) {
+			ret = jQuery.filter( selector, ret );
+		}
+
+		if ( this.length > 1 ) {
+
+			// Remove duplicates
+			if ( !guaranteedUnique[ name ] ) {
+				ret = jQuery.uniqueSort( ret );
+			}
+
+			// Reverse order for parents* and prev-derivatives
+			if ( rparentsprev.test( name ) ) {
+				ret = ret.reverse();
+			}
+		}
+
+		return this.pushStack( ret );
+	};
+} );
+var rnotwhite = ( /\S+/g );
+
+
+
+// Convert String-formatted options into Object-formatted ones
+function createOptions( options ) {
+	var object = {};
+	jQuery.each( options.match( rnotwhite ) || [], function( _, flag ) {
+		object[ flag ] = true;
+	} );
+	return object;
+}
+
+/*
+ * Create a callback list using the following parameters:
+ *
+ *	options: an optional list of space-separated options that will change how
+ *			the callback list behaves or a more traditional option object
+ *
+ * By default a callback list will act like an event callback list and can be
+ * "fired" multiple times.
+ *
+ * Possible options:
+ *
+ *	once:			will ensure the callback list can only be fired once (like a Deferred)
+ *
+ *	memory:			will keep track of previous values and will call any callback added
+ *					after the list has been fired right away with the latest "memorized"
+ *					values (like a Deferred)
+ *
+ *	unique:			will ensure a callback can only be added once (no duplicate in the list)
+ *
+ *	stopOnFalse:	interrupt callings when a callback returns false
+ *
+ */
+jQuery.Callbacks = function( options ) {
+
+	// Convert options from String-formatted to Object-formatted if needed
+	// (we check in cache first)
+	options = typeof options === "string" ?
+		createOptions( options ) :
+		jQuery.extend( {}, options );
+
+	var // Flag to know if list is currently firing
+		firing,
+
+		// Last fire value for non-forgettable lists
+		memory,
+
+		// Flag to know if list was already fired
+		fired,
+
+		// Flag to prevent firing
+		locked,
+
+		// Actual callback list
+		list = [],
+
+		// Queue of execution data for repeatable lists
+		queue = [],
+
+		// Index of currently firing callback (modified by add/remove as needed)
+		firingIndex = -1,
+
+		// Fire callbacks
+		fire = function() {
+
+			// Enforce single-firing
+			locked = options.once;
+
+			// Execute callbacks for all pending executions,
+			// respecting firingIndex overrides and runtime changes
+			fired = firing = true;
+			for ( ; queue.length; firingIndex = -1 ) {
+				memory = queue.shift();
+				while ( ++firingIndex < list.length ) {
+
+					// Run callback and check for early termination
+					if ( list[ firingIndex ].apply( memory[ 0 ], memory[ 1 ] ) === false &&
+						options.stopOnFalse ) {
+
+						// Jump to end and forget the data so .add doesn't re-fire
+						firingIndex = list.length;
+						memory = false;
+					}
+				}
+			}
+
+			// Forget the data if we're done with it
+			if ( !options.memory ) {
+				memory = false;
+			}
+
+			firing = false;
+
+			// Clean up if we're done firing for good
+			if ( locked ) {
+
+				// Keep an empty list if we have data for future add calls
+				if ( memory ) {
+					list = [];
+
+				// Otherwise, this object is spent
+				} else {
+					list = "";
+				}
+			}
+		},
+
+		// Actual Callbacks object
+		self = {
+
+			// Add a callback or a collection of callbacks to the list
+			add: function() {
+				if ( list ) {
+
+					// If we have memory from a past run, we should fire after adding
+					if ( memory && !firing ) {
+						firingIndex = list.length - 1;
+						queue.push( memory );
+					}
+
+					( function add( args ) {
+						jQuery.each( args, function( _, arg ) {
+							if ( jQuery.isFunction( arg ) ) {
+								if ( !options.unique || !self.has( arg ) ) {
+									list.push( arg );
+								}
+							} else if ( arg && arg.length && jQuery.type( arg ) !== "string" ) {
+
+								// Inspect recursively
+								add( arg );
+							}
+						} );
+					} )( arguments );
+
+					if ( memory && !firing ) {
+						fire();
+					}
+				}
+				return this;
+			},
+
+			// Remove a callback from the list
+			remove: function() {
+				jQuery.each( arguments, function( _, arg ) {
+					var index;
+					while ( ( index = jQuery.inArray( arg, list, index ) ) > -1 ) {
+						list.splice( index, 1 );
+
+						// Handle firing indexes
+						if ( index <= firingIndex ) {
+							firingIndex--;
+						}
+					}
+				} );
+				return this;
+			},
+
+			// Check if a given callback is in the list.
+			// If no argument is given, return whether or not list has callbacks attached.
+			has: function( fn ) {
+				return fn ?
+					jQuery.inArray( fn, list ) > -1 :
+					list.length > 0;
+			},
+
+			// Remove all callbacks from the list
+			empty: function() {
+				if ( list ) {
+					list = [];
+				}
+				return this;
+			},
+
+			// Disable .fire and .add
+			// Abort any current/pending executions
+			// Clear all callbacks and values
+			disable: function() {
+				locked = queue = [];
+				list = memory = "";
+				return this;
+			},
+			disabled: function() {
+				return !list;
+			},
+
+			// Disable .fire
+			// Also disable .add unless we have memory (since it would have no effect)
+			// Abort any pending executions
+			lock: function() {
+				locked = true;
+				if ( !memory ) {
+					self.disable();
+				}
+				return this;
+			},
+			locked: function() {
+				return !!locked;
+			},
+
+			// Call all callbacks with the given context and arguments
+			fireWith: function( context, args ) {
+				if ( !locked ) {
+					args = args || [];
+					args = [ context, args.slice ? args.slice() : args ];
+					queue.push( args );
+					if ( !firing ) {
+						fire();
+					}
+				}
+				return this;
+			},
+
+			// Call all the callbacks with the given arguments
+			fire: function() {
+				self.fireWith( this, arguments );
+				return this;
+			},
+
+			// To know if the callbacks have already been called at least once
+			fired: function() {
+				return !!fired;
+			}
+		};
+
+	return self;
+};
+
+
+jQuery.extend( {
+
+	Deferred: function( func ) {
+		var tuples = [
+
+				// action, add listener, listener list, final state
+				[ "resolve", "done", jQuery.Callbacks( "once memory" ), "resolved" ],
+				[ "reject", "fail", jQuery.Callbacks( "once memory" ), "rejected" ],
+				[ "notify", "progress", jQuery.Callbacks( "memory" ) ]
+			],
+			state = "pending",
+			promise = {
+				state: function() {
+					return state;
+				},
+				always: function() {
+					deferred.done( arguments ).fail( arguments );
+					return this;
+				},
+				then: function( /* fnDone, fnFail, fnProgress */ ) {
+					var fns = arguments;
+					return jQuery.Deferred( function( newDefer ) {
+						jQuery.each( tuples, function( i, tuple ) {
+							var fn = jQuery.isFunction( fns[ i ] ) && fns[ i ];
+
+							// deferred[ done | fail | progress ] for forwarding actions to newDefer
+							deferred[ tuple[ 1 ] ]( function() {
+								var returned = fn && fn.apply( this, arguments );
+								if ( returned && jQuery.isFunction( returned.promise ) ) {
+									returned.promise()
+										.progress( newDefer.notify )
+										.done( newDefer.resolve )
+										.fail( newDefer.reject );
+								} else {
+									newDefer[ tuple[ 0 ] + "With" ](
+										this === promise ? newDefer.promise() : this,
+										fn ? [ returned ] : arguments
+									);
+								}
+							} );
+						} );
+						fns = null;
+					} ).promise();
+				},
+
+				// Get a promise for this deferred
+				// If obj is provided, the promise aspect is added to the object
+				promise: function( obj ) {
+					return obj != null ? jQuery.extend( obj, promise ) : promise;
+				}
+			},
+			deferred = {};
+
+		// Keep pipe for back-compat
+		promise.pipe = promise.then;
+
+		// Add list-specific methods
+		jQuery.each( tuples, function( i, tuple ) {
+			var list = tuple[ 2 ],
+				stateString = tuple[ 3 ];
+
+			// promise[ done | fail | progress ] = list.add
+			promise[ tuple[ 1 ] ] = list.add;
+
+			// Handle state
+			if ( stateString ) {
+				list.add( function() {
+
+					// state = [ resolved | rejected ]
+					state = stateString;
+
+				// [ reject_list | resolve_list ].disable; progress_list.lock
+				}, tuples[ i ^ 1 ][ 2 ].disable, tuples[ 2 ][ 2 ].lock );
+			}
+
+			// deferred[ resolve | reject | notify ]
+			deferred[ tuple[ 0 ] ] = function() {
+				deferred[ tuple[ 0 ] + "With" ]( this === deferred ? promise : this, arguments );
+				return this;
+			};
+			deferred[ tuple[ 0 ] + "With" ] = list.fireWith;
+		} );
+
+		// Make the deferred a promise
+		promise.promise( deferred );
+
+		// Call given func if any
+		if ( func ) {
+			func.call( deferred, deferred );
+		}
+
+		// All done!
+		return deferred;
+	},
+
+	// Deferred helper
+	when: function( subordinate /* , ..., subordinateN */ ) {
+		var i = 0,
+			resolveValues = slice.call( arguments ),
+			length = resolveValues.length,
+
+			// the count of uncompleted subordinates
+			remaining = length !== 1 ||
+				( subordinate && jQuery.isFunction( subordinate.promise ) ) ? length : 0,
+
+			// the master Deferred.
+			// If resolveValues consist of only a single Deferred, just use that.
+			deferred = remaining === 1 ? subordinate : jQuery.Deferred(),
+
+			// Update function for both resolve and progress values
+			updateFunc = function( i, contexts, values ) {
+				return function( value ) {
+					contexts[ i ] = this;
+					values[ i ] = arguments.length > 1 ? slice.call( arguments ) : value;
+					if ( values === progressValues ) {
+						deferred.notifyWith( contexts, values );
+
+					} else if ( !( --remaining ) ) {
+						deferred.resolveWith( contexts, values );
+					}
+				};
+			},
+
+			progressValues, progressContexts, resolveContexts;
+
+		// add listeners to Deferred subordinates; treat others as resolved
+		if ( length > 1 ) {
+			progressValues = new Array( length );
+			progressContexts = new Array( length );
+			resolveContexts = new Array( length );
+			for ( ; i < length; i++ ) {
+				if ( resolveValues[ i ] && jQuery.isFunction( resolveValues[ i ].promise ) ) {
+					resolveValues[ i ].promise()
+						.progress( updateFunc( i, progressContexts, progressValues ) )
+						.done( updateFunc( i, resolveContexts, resolveValues ) )
+						.fail( deferred.reject );
+				} else {
+					--remaining;
+				}
+			}
+		}
+
+		// if we're not waiting on anything, resolve the master
+		if ( !remaining ) {
+			deferred.resolveWith( resolveContexts, resolveValues );
+		}
+
+		return deferred.promise();
+	}
+} );
+
+
+// The deferred used on DOM ready
+var readyList;
+
+jQuery.fn.ready = function( fn ) {
+
+	// Add the callback
+	jQuery.ready.promise().done( fn );
+
+	return this;
+};
+
+jQuery.extend( {
+
+	// Is the DOM ready to be used? Set to true once it occurs.
+	isReady: false,
+
+	// A counter to track how many items to wait for before
+	// the ready event fires. See #6781
+	readyWait: 1,
+
+	// Hold (or release) the ready event
+	holdReady: function( hold ) {
+		if ( hold ) {
+			jQuery.readyWait++;
+		} else {
+			jQuery.ready( true );
+		}
+	},
+
+	// Handle when the DOM is ready
+	ready: function( wait ) {
+
+		// Abort if there are pending holds or we're already ready
+		if ( wait === true ? --jQuery.readyWait : jQuery.isReady ) {
+			return;
+		}
+
+		// Remember that the DOM is ready
+		jQuery.isReady = true;
+
+		// If a normal DOM Ready event fired, decrement, and wait if need be
+		if ( wait !== true && --jQuery.readyWait > 0 ) {
+			return;
+		}
+
+		// If there are functions bound, to execute
+		readyList.resolveWith( document, [ jQuery ] );
+
+		// Trigger any bound ready events
+		if ( jQuery.fn.triggerHandler ) {
+			jQuery( document ).triggerHandler( "ready" );
+			jQuery( document ).off( "ready" );
+		}
+	}
+} );
+
+/**
+ * Clean-up method for dom ready events
+ */
+function detach() {
+	if ( document.addEventListener ) {
+		document.removeEventListener( "DOMContentLoaded", completed );
+		window.removeEventListener( "load", completed );
+
+	} else {
+		document.detachEvent( "onreadystatechange", completed );
+		window.detachEvent( "onload", completed );
+	}
+}
+
+/**
+ * The ready event handler and self cleanup method
+ */
+function completed() {
+
+	// readyState === "complete" is good enough for us to call the dom ready in oldIE
+	if ( document.addEventListener ||
+		window.event.type === "load" ||
+		document.readyState === "complete" ) {
+
+		detach();
+		jQuery.ready();
+	}
+}
+
+jQuery.ready.promise = function( obj ) {
+	if ( !readyList ) {
+
+		readyList = jQuery.Deferred();
+
+		// Catch cases where $(document).ready() is called
+		// after the browser event has already occurred.
+		// we once tried to use readyState "interactive" here,
+		// but it caused issues like the one
+		// discovered by ChrisS here:
+		// http://bugs.jquery.com/ticket/12282#comment:15
+		if ( document.readyState === "complete" ) {
+
+			// Handle it asynchronously to allow scripts the opportunity to delay ready
+			window.setTimeout( jQuery.ready );
+
+		// Standards-based browsers support DOMContentLoaded
+		} else if ( document.addEventListener ) {
+
+			// Use the handy event callback
+			document.addEventListener( "DOMContentLoaded", completed );
+
+			// A fallback to window.onload, that will always work
+			window.addEventListener( "load", completed );
+
+		// If IE event model is used
+		} else {
+
+			// Ensure firing before onload, maybe late but safe also for iframes
+			document.attachEvent( "onreadystatechange", completed );
+
+			// A fallback to window.onload, that will always work
+			window.attachEvent( "onload", completed );
+
+			// If IE and not a frame
+			// continually check to see if the document is ready
+			var top = false;
+
+			try {
+				top = window.frameElement == null && document.documentElement;
+			} catch ( e ) {}
+
+			if ( top && top.doScroll ) {
+				( function doScrollCheck() {
+					if ( !jQuery.isReady ) {
+
+						try {
+
+							// Use the trick by Diego Perini
+							// http://javascript.nwbox.com/IEContentLoaded/
+							top.doScroll( "left" );
+						} catch ( e ) {
+							return window.setTimeout( doScrollCheck, 50 );
+						}
+
+						// detach all dom ready events
+						detach();
+
+						// and execute any waiting functions
+						jQuery.ready();
+					}
+				} )();
+			}
+		}
+	}
+	return readyList.promise( obj );
+};
+
+// Kick off the DOM ready check even if the user does not
+jQuery.ready.promise();
+
+
+
+
+// Support: IE<9
+// Iteration over object's inherited properties before its own
+var i;
+for ( i in jQuery( support ) ) {
+	break;
+}
+support.ownFirst = i === "0";
+
+// Note: most support tests are defined in their respective modules.
+// false until the test is run
+support.inlineBlockNeedsLayout = false;
+
+// Execute ASAP in case we need to set body.style.zoom
+jQuery( function() {
+
+	// Minified: var a,b,c,d
+	var val, div, body, container;
+
+	body = document.getElementsByTagName( "body" )[ 0 ];
+	if ( !body || !body.style ) {
+
+		// Return for frameset docs that don't have a body
+		return;
+	}
+
+	// Setup
+	div = document.createElement( "div" );
+	container = document.createElement( "div" );
+	container.style.cssText = "position:absolute;border:0;width:0;height:0;top:0;left:-9999px";
+	body.appendChild( container ).appendChild( div );
+
+	if ( typeof div.style.zoom !== "undefined" ) {
+
+		// Support: IE<8
+		// Check if natively block-level elements act like inline-block
+		// elements when setting their display to 'inline' and giving
+		// them layout
+		div.style.cssText = "display:inline;margin:0;border:0;padding:1px;width:1px;zoom:1";
+
+		support.inlineBlockNeedsLayout = val = div.offsetWidth === 3;
+		if ( val ) {
+
+			// Prevent IE 6 from affecting layout for positioned elements #11048
+			// Prevent IE from shrinking the body in IE 7 mode #12869
+			// Support: IE<8
+			body.style.zoom = 1;
+		}
+	}
+
+	body.removeChild( container );
+} );
+
+
+( function() {
+	var div = document.createElement( "div" );
+
+	// Support: IE<9
+	support.deleteExpando = true;
+	try {
+		delete div.test;
+	} catch ( e ) {
+		support.deleteExpando = false;
+	}
+
+	// Null elements to avoid leaks in IE.
+	div = null;
+} )();
+var acceptData = function( elem ) {
+	var noData = jQuery.noData[ ( elem.nodeName + " " ).toLowerCase() ],
+		nodeType = +elem.nodeType || 1;
+
+	// Do not set data on non-element DOM nodes because it will not be cleared (#8335).
+	return nodeType !== 1 && nodeType !== 9 ?
+		false :
+
+		// Nodes accept data unless otherwise specified; rejection can be conditional
+		!noData || noData !== true && elem.getAttribute( "classid" ) === noData;
+};
+
+
+
+
+var rbrace = /^(?:\{[\w\W]*\}|\[[\w\W]*\])$/,
+	rmultiDash = /([A-Z])/g;
+
+function dataAttr( elem, key, data ) {
+
+	// If nothing was found internally, try to fetch any
+	// data from the HTML5 data-* attribute
+	if ( data === undefined && elem.nodeType === 1 ) {
+
+		var name = "data-" + key.replace( rmultiDash, "-$1" ).toLowerCase();
+
+		data = elem.getAttribute( name );
+
+		if ( typeof data === "string" ) {
+			try {
+				data = data === "true" ? true :
+					data === "false" ? false :
+					data === "null" ? null :
+
+					// Only convert to a number if it doesn't change the string
+					+data + "" === data ? +data :
+					rbrace.test( data ) ? jQuery.parseJSON( data ) :
+					data;
+			} catch ( e ) {}
+
+			// Make sure we set the data so it isn't changed later
+			jQuery.data( elem, key, data );
+
+		} else {
+			data = undefined;
+		}
+	}
+
+	return data;
+}
+
+// checks a cache object for emptiness
+function isEmptyDataObject( obj ) {
+	var name;
+	for ( name in obj ) {
+
+		// if the public data object is empty, the private is still empty
+		if ( name === "data" && jQuery.isEmptyObject( obj[ name ] ) ) {
+			continue;
+		}
+		if ( name !== "toJSON" ) {
+			return false;
+		}
+	}
+
+	return true;
+}
+
+function internalData( elem, name, data, pvt /* Internal Use Only */ ) {
+	if ( !acceptData( elem ) ) {
+		return;
+	}
+
+	var ret, thisCache,
+		internalKey = jQuery.expando,
+
+		// We have to handle DOM nodes and JS objects differently because IE6-7
+		// can't GC object references properly across the DOM-JS boundary
+		isNode = elem.nodeType,
+
+		// Only DOM nodes need the global jQuery cache; JS object data is
+		// attached directly to the object so GC can occur automatically
+		cache = isNode ? jQuery.cache : elem,
+
+		// Only defining an ID for JS objects if its cache already exists allows
+		// the code to shortcut on the same path as a DOM node with no cache
+		id = isNode ? elem[ internalKey ] : elem[ internalKey ] && internalKey;
+
+	// Avoid doing any more work than we need to when trying to get data on an
+	// object that has no data at all
+	if ( ( !id || !cache[ id ] || ( !pvt && !cache[ id ].data ) ) &&
+		data === undefined && typeof name === "string" ) {
+		return;
+	}
+
+	if ( !id ) {
+
+		// Only DOM nodes need a new unique ID for each element since their data
+		// ends up in the global cache
+		if ( isNode ) {
+			id = elem[ internalKey ] = deletedIds.pop() || jQuery.guid++;
+		} else {
+			id = internalKey;
+		}
+	}
+
+	if ( !cache[ id ] ) {
+
+		// Avoid exposing jQuery metadata on plain JS objects when the object
+		// is serialized using JSON.stringify
+		cache[ id ] = isNode ? {} : { toJSON: jQuery.noop };
+	}
+
+	// An object can be passed to jQuery.data instead of a key/value pair; this gets
+	// shallow copied over onto the existing cache
+	if ( typeof name === "object" || typeof name === "function" ) {
+		if ( pvt ) {
+			cache[ id ] = jQuery.extend( cache[ id ], name );
+		} else {
+			cache[ id ].data = jQuery.extend( cache[ id ].data, name );
+		}
+	}
+
+	thisCache = cache[ id ];
+
+	// jQuery data() is stored in a separate object inside the object's internal data
+	// cache in order to avoid key collisions between internal data and user-defined
+	// data.
+	if ( !pvt ) {
+		if ( !thisCache.data ) {
+			thisCache.data = {};
+		}
+
+		thisCache = thisCache.data;
+	}
+
+	if ( data !== undefined ) {
+		thisCache[ jQuery.camelCase( name ) ] = data;
+	}
+
+	// Check for both converted-to-camel and non-converted data property names
+	// If a data property was specified
+	if ( typeof name === "string" ) {
+
+		// First Try to find as-is property data
+		ret = thisCache[ name ];
+
+		// Test for null|undefined property data
+		if ( ret == null ) {
+
+			// Try to find the camelCased property
+			ret = thisCache[ jQuery.camelCase( name ) ];
+		}
+	} else {
+		ret = thisCache;
+	}
+
+	return ret;
+}
+
+function internalRemoveData( elem, name, pvt ) {
+	if ( !acceptData( elem ) ) {
+		return;
+	}
+
+	var thisCache, i,
+		isNode = elem.nodeType,
+
+		// See jQuery.data for more information
+		cache = isNode ? jQuery.cache : elem,
+		id = isNode ? elem[ jQuery.expando ] : jQuery.expando;
+
+	// If there is already no cache entry for this object, there is no
+	// purpose in continuing
+	if ( !cache[ id ] ) {
+		return;
+	}
+
+	if ( name ) {
+
+		thisCache = pvt ? cache[ id ] : cache[ id ].data;
+
+		if ( thisCache ) {
+
+			// Support array or space separated string names for data keys
+			if ( !jQuery.isArray( name ) ) {
+
+				// try the string as a key before any manipulation
+				if ( name in thisCache ) {
+					name = [ name ];
+				} else {
+
+					// split the camel cased version by spaces unless a key with the spaces exists
+					name = jQuery.camelCase( name );
+					if ( name in thisCache ) {
+						name = [ name ];
+					} else {
+						name = name.split( " " );
+					}
+				}
+			} else {
+
+				// If "name" is an array of keys...
+				// When data is initially created, via ("key", "val") signature,
+				// keys will be converted to camelCase.
+				// Since there is no way to tell _how_ a key was added, remove
+				// both plain key and camelCase key. #12786
+				// This will only penalize the array argument path.
+				name = name.concat( jQuery.map( name, jQuery.camelCase ) );
+			}
+
+			i = name.length;
+			while ( i-- ) {
+				delete thisCache[ name[ i ] ];
+			}
+
+			// If there is no data left in the cache, we want to continue
+			// and let the cache object itself get destroyed
+			if ( pvt ? !isEmptyDataObject( thisCache ) : !jQuery.isEmptyObject( thisCache ) ) {
+				return;
+			}
+		}
+	}
+
+	// See jQuery.data for more information
+	if ( !pvt ) {
+		delete cache[ id ].data;
+
+		// Don't destroy the parent cache unless the internal data object
+		// had been the only thing left in it
+		if ( !isEmptyDataObject( cache[ id ] ) ) {
+			return;
+		}
+	}
+
+	// Destroy the cache
+	if ( isNode ) {
+		jQuery.cleanData( [ elem ], true );
+
+	// Use delete when supported for expandos or `cache` is not a window per isWindow (#10080)
+	/* jshint eqeqeq: false */
+	} else if ( support.deleteExpando || cache != cache.window ) {
+		/* jshint eqeqeq: true */
+		delete cache[ id ];
+
+	// When all else fails, undefined
+	} else {
+		cache[ id ] = undefined;
+	}
+}
+
+jQuery.extend( {
+	cache: {},
+
+	// The following elements (space-suffixed to avoid Object.prototype collisions)
+	// throw uncatchable exceptions if you attempt to set expando properties
+	noData: {
+		"applet ": true,
+		"embed ": true,
+
+		// ...but Flash objects (which have this classid) *can* handle expandos
+		"object ": "clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"
+	},
+
+	hasData: function( elem ) {
+		elem = elem.nodeType ? jQuery.cache[ elem[ jQuery.expando ] ] : elem[ jQuery.expando ];
+		return !!elem && !isEmptyDataObject( elem );
+	},
+
+	data: function( elem, name, data ) {
+		return internalData( elem, name, data );
+	},
+
+	removeData: function( elem, name ) {
+		return internalRemoveData( elem, name );
+	},
+
+	// For internal use only.
+	_data: function( elem, name, data ) {
+		return internalData( elem, name, data, true );
+	},
+
+	_removeData: function( elem, name ) {
+		return internalRemoveData( elem, name, true );
+	}
+} );
+
+jQuery.fn.extend( {
+	data: function( key, value ) {
+		var i, name, data,
+			elem = this[ 0 ],
+			attrs = elem && elem.attributes;
+
+		// Special expections of .data basically thwart jQuery.access,
+		// so implement the relevant behavior ourselves
+
+		// Gets all values
+		if ( key === undefined ) {
+			if ( this.length ) {
+				data = jQuery.data( elem );
+
+				if ( elem.nodeType === 1 && !jQuery._data( elem, "parsedAttrs" ) ) {
+					i = attrs.length;
+					while ( i-- ) {
+
+						// Support: IE11+
+						// The attrs elements can be null (#14894)
+						if ( attrs[ i ] ) {
+							name = attrs[ i ].name;
+							if ( name.indexOf( "data-" ) === 0 ) {
+								name = jQuery.camelCase( name.slice( 5 ) );
+								dataAttr( elem, name, data[ name ] );
+							}
+						}
+					}
+					jQuery._data( elem, "parsedAttrs", true );
+				}
+			}
+
+			return data;
+		}
+
+		// Sets multiple values
+		if ( typeof key === "object" ) {
+			return this.each( function() {
+				jQuery.data( this, key );
+			} );
+		}
+
+		return arguments.length > 1 ?
+
+			// Sets one value
+			this.each( function() {
+				jQuery.data( this, key, value );
+			} ) :
+
+			// Gets one value
+			// Try to fetch any internally stored data first
+			elem ? dataAttr( elem, key, jQuery.data( elem, key ) ) : undefined;
+	},
+
+	removeData: function( key ) {
+		return this.each( function() {
+			jQuery.removeData( this, key );
+		} );
+	}
+} );
+
+
+jQuery.extend( {
+	queue: function( elem, type, data ) {
+		var queue;
+
+		if ( elem ) {
+			type = ( type || "fx" ) + "queue";
+			queue = jQuery._data( elem, type );
+
+			// Speed up dequeue by getting out quickly if this is just a lookup
+			if ( data ) {
+				if ( !queue || jQuery.isArray( data ) ) {
+					queue = jQuery._data( elem, type, jQuery.makeArray( data ) );
+				} else {
+					queue.push( data );
+				}
+			}
+			return queue || [];
+		}
+	},
+
+	dequeue: function( elem, type ) {
+		type = type || "fx";
+
+		var queue = jQuery.queue( elem, type ),
+			startLength = queue.length,
+			fn = queue.shift(),
+			hooks = jQuery._queueHooks( elem, type ),
+			next = function() {
+				jQuery.dequeue( elem, type );
+			};
+
+		// If the fx queue is dequeued, always remove the progress sentinel
+		if ( fn === "inprogress" ) {
+			fn = queue.shift();
+			startLength--;
+		}
+
+		if ( fn ) {
+
+			// Add a progress sentinel to prevent the fx queue from being
+			// automatically dequeued
+			if ( type === "fx" ) {
+				queue.unshift( "inprogress" );
+			}
+
+			// clear up the last queue stop function
+			delete hooks.stop;
+			fn.call( elem, next, hooks );
+		}
+
+		if ( !startLength && hooks ) {
+			hooks.empty.fire();
+		}
+	},
+
+	// not intended for public consumption - generates a queueHooks object,
+	// or returns the current one
+	_queueHooks: function( elem, type ) {
+		var key = type + "queueHooks";
+		return jQuery._data( elem, key ) || jQuery._data( elem, key, {
+			empty: jQuery.Callbacks( "once memory" ).add( function() {
+				jQuery._removeData( elem, type + "queue" );
+				jQuery._removeData( elem, key );
+			} )
+		} );
+	}
+} );
+
+jQuery.fn.extend( {
+	queue: function( type, data ) {
+		var setter = 2;
+
+		if ( typeof type !== "string" ) {
+			data = type;
+			type = "fx";
+			setter--;
+		}
+
+		if ( arguments.length < setter ) {
+			return jQuery.queue( this[ 0 ], type );
+		}
+
+		return data === undefined ?
+			this :
+			this.each( function() {
+				var queue = jQuery.queue( this, type, data );
+
+				// ensure a hooks for this queue
+				jQuery._queueHooks( this, type );
+
+				if ( type === "fx" && queue[ 0 ] !== "inprogress" ) {
+					jQuery.dequeue( this, type );
+				}
+			} );
+	},
+	dequeue: function( type ) {
+		return this.each( function() {
+			jQuery.dequeue( this, type );
+		} );
+	},
+	clearQueue: function( type ) {
+		return this.queue( type || "fx", [] );
+	},
+
+	// Get a promise resolved when queues of a certain type
+	// are emptied (fx is the type by default)
+	promise: function( type, obj ) {
+		var tmp,
+			count = 1,
+			defer = jQuery.Deferred(),
+			elements = this,
+			i = this.length,
+			resolve = function() {
+				if ( !( --count ) ) {
+					defer.resolveWith( elements, [ elements ] );
+				}
+			};
+
+		if ( typeof type !== "string" ) {
+			obj = type;
+			type = undefined;
+		}
+		type = type || "fx";
+
+		while ( i-- ) {
+			tmp = jQuery._data( elements[ i ], type + "queueHooks" );
+			if ( tmp && tmp.empty ) {
+				count++;
+				tmp.empty.add( resolve );
+			}
+		}
+		resolve();
+		return defer.promise( obj );
+	}
+} );
+
+
+( function() {
+	var shrinkWrapBlocksVal;
+
+	support.shrinkWrapBlocks = function() {
+		if ( shrinkWrapBlocksVal != null ) {
+			return shrinkWrapBlocksVal;
+		}
+
+		// Will be changed later if needed.
+		shrinkWrapBlocksVal = false;
+
+		// Minified: var b,c,d
+		var div, body, container;
+
+		body = document.getElementsByTagName( "body" )[ 0 ];
+		if ( !body || !body.style ) {
+
+			// Test fired too early or in an unsupported environment, exit.
+			return;
+		}
+
+		// Setup
+		div = document.createElement( "div" );
+		container = document.createElement( "div" );
+		container.style.cssText = "position:absolute;border:0;width:0;height:0;top:0;left:-9999px";
+		body.appendChild( container ).appendChild( div );
+
+		// Support: IE6
+		// Check if elements with layout shrink-wrap their children
+		if ( typeof div.style.zoom !== "undefined" ) {
+
+			// Reset CSS: box-sizing; display; margin; border
+			div.style.cssText =
+
+				// Support: Firefox<29, Android 2.3
+				// Vendor-prefix box-sizing
+				"-webkit-box-sizing:content-box;-moz-box-sizing:content-box;" +
+				"box-sizing:content-box;display:block;margin:0;border:0;" +
+				"padding:1px;width:1px;zoom:1";
+			div.appendChild( document.createElement( "div" ) ).style.width = "5px";
+			shrinkWrapBlocksVal = div.offsetWidth !== 3;
+		}
+
+		body.removeChild( container );
+
+		return shrinkWrapBlocksVal;
+	};
+
+} )();
+var pnum = ( /[+-]?(?:\d*\.|)\d+(?:[eE][+-]?\d+|)/ ).source;
+
+var rcssNum = new RegExp( "^(?:([+-])=|)(" + pnum + ")([a-z%]*)$", "i" );
+
+
+var cssExpand = [ "Top", "Right", "Bottom", "Left" ];
+
+var isHidden = function( elem, el ) {
+
+		// isHidden might be called from jQuery#filter function;
+		// in that case, element will be second argument
+		elem = el || elem;
+		return jQuery.css( elem, "display" ) === "none" ||
+			!jQuery.contains( elem.ownerDocument, elem );
+	};
+
+
+
+function adjustCSS( elem, prop, valueParts, tween ) {
+	var adjusted,
+		scale = 1,
+		maxIterations = 20,
+		currentValue = tween ?
+			function() { return tween.cur(); } :
+			function() { return jQuery.css( elem, prop, "" ); },
+		initial = currentValue(),
+		unit = valueParts && valueParts[ 3 ] || ( jQuery.cssNumber[ prop ] ? "" : "px" ),
+
+		// Starting value computation is required for potential unit mismatches
+		initialInUnit = ( jQuery.cssNumber[ prop ] || unit !== "px" && +initial ) &&
+			rcssNum.exec( jQuery.css( elem, prop ) );
+
+	if ( initialInUnit && initialInUnit[ 3 ] !== unit ) {
+
+		// Trust units reported by jQuery.css
+		unit = unit || initialInUnit[ 3 ];
+
+		// Make sure we update the tween properties later on
+		valueParts = valueParts || [];
+
+		// Iteratively approximate from a nonzero starting point
+		initialInUnit = +initial || 1;
+
+		do {
+
+			// If previous iteration zeroed out, double until we get *something*.
+			// Use string for doubling so we don't accidentally see scale as unchanged below
+			scale = scale || ".5";
+
+			// Adjust and apply
+			initialInUnit = initialInUnit / scale;
+			jQuery.style( elem, prop, initialInUnit + unit );
+
+		// Update scale, tolerating zero or NaN from tween.cur()
+		// Break the loop if scale is unchanged or perfect, or if we've just had enough.
+		} while (
+			scale !== ( scale = currentValue() / initial ) && scale !== 1 && --maxIterations
+		);
+	}
+
+	if ( valueParts ) {
+		initialInUnit = +initialInUnit || +initial || 0;
+
+		// Apply relative offset (+=/-=) if specified
+		adjusted = valueParts[ 1 ] ?
+			initialInUnit + ( valueParts[ 1 ] + 1 ) * valueParts[ 2 ] :
+			+valueParts[ 2 ];
+		if ( tween ) {
+			tween.unit = unit;
+			tween.start = initialInUnit;
+			tween.end = adjusted;
+		}
+	}
+	return adjusted;
+}
+
+
+// Multifunctional method to get and set values of a collection
+// The value/s can optionally be executed if it's a function
+var access = function( elems, fn, key, value, chainable, emptyGet, raw ) {
+	var i = 0,
+		length = elems.length,
+		bulk = key == null;
+
+	// Sets many values
+	if ( jQuery.type( key ) === "object" ) {
+		chainable = true;
+		for ( i in key ) {
+			access( elems, fn, i, key[ i ], true, emptyGet, raw );
+		}
+
+	// Sets one value
+	} else if ( value !== undefined ) {
+		chainable = true;
+
+		if ( !jQuery.isFunction( value ) ) {
+			raw = true;
+		}
+
+		if ( bulk ) {
+
+			// Bulk operations run against the entire set
+			if ( raw ) {
+				fn.call( elems, value );
+				fn = null;
+
+			// ...except when executing function values
+			} else {
+				bulk = fn;
+				fn = function( elem, key, value ) {
+					return bulk.call( jQuery( elem ), value );
+				};
+			}
+		}
+
+		if ( fn ) {
+			for ( ; i < length; i++ ) {
+				fn(
+					elems[ i ],
+					key,
+					raw ? value : value.call( elems[ i ], i, fn( elems[ i ], key ) )
+				);
+			}
+		}
+	}
+
+	return chainable ?
+		elems :
+
+		// Gets
+		bulk ?
+			fn.call( elems ) :
+			length ? fn( elems[ 0 ], key ) : emptyGet;
+};
+var rcheckableType = ( /^(?:checkbox|radio)$/i );
+
+var rtagName = ( /<([\w:-]+)/ );
+
+var rscriptType = ( /^$|\/(?:java|ecma)script/i );
+
+var rleadingWhitespace = ( /^\s+/ );
+
+var nodeNames = "abbr|article|aside|audio|bdi|canvas|data|datalist|" +
+		"details|dialog|figcaption|figure|footer|header|hgroup|main|" +
+		"mark|meter|nav|output|picture|progress|section|summary|template|time|video";
+
+
+
+function createSafeFragment( document ) {
+	var list = nodeNames.split( "|" ),
+		safeFrag = document.createDocumentFragment();
+
+	if ( safeFrag.createElement ) {
+		while ( list.length ) {
+			safeFrag.createElement(
+				list.pop()
+			);
+		}
+	}
+	return safeFrag;
+}
+
+
+( function() {
+	var div = document.createElement( "div" ),
+		fragment = document.createDocumentFragment(),
+		input = document.createElement( "input" );
+
+	// Setup
+	div.innerHTML = "  <link/><table></table><a href='/a'>a</a><input type='checkbox'/>";
+
+	// IE strips leading whitespace when .innerHTML is used
+	support.leadingWhitespace = div.firstChild.nodeType === 3;
+
+	// Make sure that tbody elements aren't automatically inserted
+	// IE will insert them into empty tables
+	support.tbody = !div.getElementsByTagName( "tbody" ).length;
+
+	// Make sure that link elements get serialized correctly by innerHTML
+	// This requires a wrapper element in IE
+	support.htmlSerialize = !!div.getElementsByTagName( "link" ).length;
+
+	// Makes sure cloning an html5 element does not cause problems
+	// Where outerHTML is undefined, this still works
+	support.html5Clone =
+		document.createElement( "nav" ).cloneNode( true ).outerHTML !== "<:nav></:nav>";
+
+	// Check if a disconnected checkbox will retain its checked
+	// value of true after appended to the DOM (IE6/7)
+	input.type = "checkbox";
+	input.checked = true;
+	fragment.appendChild( input );
+	support.appendChecked = input.checked;
+
+	// Make sure textarea (and checkbox) defaultValue is properly cloned
+	// Support: IE6-IE11+
+	div.innerHTML = "<textarea>x</textarea>";
+	support.noCloneChecked = !!div.cloneNode( true ).lastChild.defaultValue;
+
+	// #11217 - WebKit loses check when the name is after the checked attribute
+	fragment.appendChild( div );
+
+	// Support: Windows Web Apps (WWA)
+	// `name` and `type` must use .setAttribute for WWA (#14901)
+	input = document.createElement( "input" );
+	input.setAttribute( "type", "radio" );
+	input.setAttribute( "checked", "checked" );
+	input.setAttribute( "name", "t" );
+
+	div.appendChild( input );
+
+	// Support: Safari 5.1, iOS 5.1, Android 4.x, Android 2.3
+	// old WebKit doesn't clone checked state correctly in fragments
+	support.checkClone = div.cloneNode( true ).cloneNode( true ).lastChild.checked;
+
+	// Support: IE<9
+	// Cloned elements keep attachEvent handlers, we use addEventListener on IE9+
+	support.noCloneEvent = !!div.addEventListener;
+
+	// Support: IE<9
+	// Since attributes and properties are the same in IE,
+	// cleanData must set properties to undefined rather than use removeAttribute
+	div[ jQuery.expando ] = 1;
+	support.attributes = !div.getAttribute( jQuery.expando );
+} )();
+
+
+// We have to close these tags to support XHTML (#13200)
+var wrapMap = {
+	option: [ 1, "<select multiple='multiple'>", "</select>" ],
+	legend: [ 1, "<fieldset>", "</fieldset>" ],
+	area: [ 1, "<map>", "</map>" ],
+
+	// Support: IE8
+	param: [ 1, "<object>", "</object>" ],
+	thead: [ 1, "<table>", "</table>" ],
+	tr: [ 2, "<table><tbody>", "</tbody></table>" ],
+	col: [ 2, "<table><tbody></tbody><colgroup>", "</colgroup></table>" ],
+	td: [ 3, "<table><tbody><tr>", "</tr></tbody></table>" ],
+
+	// IE6-8 can't serialize link, script, style, or any html5 (NoScope) tags,
+	// unless wrapped in a div with non-breaking characters in front of it.
+	_default: support.htmlSerialize ? [ 0, "", "" ] : [ 1, "X<div>", "</div>" ]
+};
+
+// Support: IE8-IE9
+wrapMap.optgroup = wrapMap.option;
+
+wrapMap.tbody = wrapMap.tfoot = wrapMap.colgroup = wrapMap.caption = wrapMap.thead;
+wrapMap.th = wrapMap.td;
+
+
+function getAll( context, tag ) {
+	var elems, elem,
+		i = 0,
+		found = typeof context.getElementsByTagName !== "undefined" ?
+			context.getElementsByTagName( tag || "*" ) :
+			typeof context.querySelectorAll !== "undefined" ?
+				context.querySelectorAll( tag || "*" ) :
+				undefined;
+
+	if ( !found ) {
+		for ( found = [], elems = context.childNodes || context;
+			( elem = elems[ i ] ) != null;
+			i++
+		) {
+			if ( !tag || jQuery.nodeName( elem, tag ) ) {
+				found.push( elem );
+			} else {
+				jQuery.merge( found, getAll( elem, tag ) );
+			}
+		}
+	}
+
+	return tag === undefined || tag && jQuery.nodeName( context, tag ) ?
+		jQuery.merge( [ context ], found ) :
+		found;
+}
+
+
+// Mark scripts as having already been evaluated
+function setGlobalEval( elems, refElements ) {
+	var elem,
+		i = 0;
+	for ( ; ( elem = elems[ i ] ) != null; i++ ) {
+		jQuery._data(
+			elem,
+			"globalEval",
+			!refElements || jQuery._data( refElements[ i ], "globalEval" )
+		);
+	}
+}
+
+
+var rhtml = /<|&#?\w+;/,
+	rtbody = /<tbody/i;
+
+function fixDefaultChecked( elem ) {
+	if ( rcheckableType.test( elem.type ) ) {
+		elem.defaultChecked = elem.checked;
+	}
+}
+
+function buildFragment( elems, context, scripts, selection, ignored ) {
+	var j, elem, contains,
+		tmp, tag, tbody, wrap,
+		l = elems.length,
+
+		// Ensure a safe fragment
+		safe = createSafeFragment( context ),
+
+		nodes = [],
+		i = 0;
+
+	for ( ; i < l; i++ ) {
+		elem = elems[ i ];
+
+		if ( elem || elem === 0 ) {
+
+			// Add nodes directly
+			if ( jQuery.type( elem ) === "object" ) {
+				jQuery.merge( nodes, elem.nodeType ? [ elem ] : elem );
+
+			// Convert non-html into a text node
+			} else if ( !rhtml.test( elem ) ) {
+				nodes.push( context.createTextNode( elem ) );
+
+			// Convert html into DOM nodes
+			} else {
+				tmp = tmp || safe.appendChild( context.createElement( "div" ) );
+
+				// Deserialize a standard representation
+				tag = ( rtagName.exec( elem ) || [ "", "" ] )[ 1 ].toLowerCase();
+				wrap = wrapMap[ tag ] || wrapMap._default;
+
+				tmp.innerHTML = wrap[ 1 ] + jQuery.htmlPrefilter( elem ) + wrap[ 2 ];
+
+				// Descend through wrappers to the right content
+				j = wrap[ 0 ];
+				while ( j-- ) {
+					tmp = tmp.lastChild;
+				}
+
+				// Manually add leading whitespace removed by IE
+				if ( !support.leadingWhitespace && rleadingWhitespace.test( elem ) ) {
+					nodes.push( context.createTextNode( rleadingWhitespace.exec( elem )[ 0 ] ) );
+				}
+
+				// Remove IE's autoinserted <tbody> from table fragments
+				if ( !support.tbody ) {
+
+					// String was a <table>, *may* have spurious <tbody>
+					elem = tag === "table" && !rtbody.test( elem ) ?
+						tmp.firstChild :
+
+						// String was a bare <thead> or <tfoot>
+						wrap[ 1 ] === "<table>" && !rtbody.test( elem ) ?
+							tmp :
+							0;
+
+					j = elem && elem.childNodes.length;
+					while ( j-- ) {
+						if ( jQuery.nodeName( ( tbody = elem.childNodes[ j ] ), "tbody" ) &&
+							!tbody.childNodes.length ) {
+
+							elem.removeChild( tbody );
+						}
+					}
+				}
+
+				jQuery.merge( nodes, tmp.childNodes );
+
+				// Fix #12392 for WebKit and IE > 9
+				tmp.textContent = "";
+
+				// Fix #12392 for oldIE
+				while ( tmp.firstChild ) {
+					tmp.removeChild( tmp.firstChild );
+				}
+
+				// Remember the top-level container for proper cleanup
+				tmp = safe.lastChild;
+			}
+		}
+	}
+
+	// Fix #11356: Clear elements from fragment
+	if ( tmp ) {
+		safe.removeChild( tmp );
+	}
+
+	// Reset defaultChecked for any radios and checkboxes
+	// about to be appended to the DOM in IE 6/7 (#8060)
+	if ( !support.appendChecked ) {
+		jQuery.grep( getAll( nodes, "input" ), fixDefaultChecked );
+	}
+
+	i = 0;
+	while ( ( elem = nodes[ i++ ] ) ) {
+
+		// Skip elements already in the context collection (trac-4087)
+		if ( selection && jQuery.inArray( elem, selection ) > -1 ) {
+			if ( ignored ) {
+				ignored.push( elem );
+			}
+
+			continue;
+		}
+
+		contains = jQuery.contains( elem.ownerDocument, elem );
+
+		// Append to fragment
+		tmp = getAll( safe.appendChild( elem ), "script" );
+
+		// Preserve script evaluation history
+		if ( contains ) {
+			setGlobalEval( tmp );
+		}
+
+		// Capture executables
+		if ( scripts ) {
+			j = 0;
+			while ( ( elem = tmp[ j++ ] ) ) {
+				if ( rscriptType.test( elem.type || "" ) ) {
+					scripts.push( elem );
+				}
+			}
+		}
+	}
+
+	tmp = null;
+
+	return safe;
+}
+
+
+( function() {
+	var i, eventName,
+		div = document.createElement( "div" );
+
+	// Support: IE<9 (lack submit/change bubble), Firefox (lack focus(in | out) events)
+	for ( i in { submit: true, change: true, focusin: true } ) {
+		eventName = "on" + i;
+
+		if ( !( support[ i ] = eventName in window ) ) {
+
+			// Beware of CSP restrictions (https://developer.mozilla.org/en/Security/CSP)
+			div.setAttribute( eventName, "t" );
+			support[ i ] = div.attributes[ eventName ].expando === false;
+		}
+	}
+
+	// Null elements to avoid leaks in IE.
+	div = null;
+} )();
+
+
+var rformElems = /^(?:input|select|textarea)$/i,
+	rkeyEvent = /^key/,
+	rmouseEvent = /^(?:mouse|pointer|contextmenu|drag|drop)|click/,
+	rfocusMorph = /^(?:focusinfocus|focusoutblur)$/,
+	rtypenamespace = /^([^.]*)(?:\.(.+)|)/;
+
+function returnTrue() {
+	return true;
+}
+
+function returnFalse() {
+	return false;
+}
+
+// Support: IE9
+// See #13393 for more info
+function safeActiveElement() {
+	try {
+		return document.activeElement;
+	} catch ( err ) { }
+}
+
+function on( elem, types, selector, data, fn, one ) {
+	var origFn, type;
+
+	// Types can be a map of types/handlers
+	if ( typeof types === "object" ) {
+
+		// ( types-Object, selector, data )
+		if ( typeof selector !== "string" ) {
+
+			// ( types-Object, data )
+			data = data || selector;
+			selector = undefined;
+		}
+		for ( type in types ) {
+			on( elem, type, selector, data, types[ type ], one );
+		}
+		return elem;
+	}
+
+	if ( data == null && fn == null ) {
+
+		// ( types, fn )
+		fn = selector;
+		data = selector = undefined;
+	} else if ( fn == null ) {
+		if ( typeof selector === "string" ) {
+
+			// ( types, selector, fn )
+			fn = data;
+			data = undefined;
+		} else {
+
+			// ( types, data, fn )
+			fn = data;
+			data = selector;
+			selector = undefined;
+		}
+	}
+	if ( fn === false ) {
+		fn = returnFalse;
+	} else if ( !fn ) {
+		return elem;
+	}
+
+	if ( one === 1 ) {
+		origFn = fn;
+		fn = function( event ) {
+
+			// Can use an empty set, since event contains the info
+			jQuery().off( event );
+			return origFn.apply( this, arguments );
+		};
+
+		// Use same guid so caller can remove using origFn
+		fn.guid = origFn.guid || ( origFn.guid = jQuery.guid++ );
+	}
+	return elem.each( function() {
+		jQuery.event.add( this, types, fn, data, selector );
+	} );
+}
+
+/*
+ * Helper functions for managing events -- not part of the public interface.
+ * Props to Dean Edwards' addEvent library for many of the ideas.
+ */
+jQuery.event = {
+
+	global: {},
+
+	add: function( elem, types, handler, data, selector ) {
+		var tmp, events, t, handleObjIn,
+			special, eventHandle, handleObj,
+			handlers, type, namespaces, origType,
+			elemData = jQuery._data( elem );
+
+		// Don't attach events to noData or text/comment nodes (but allow plain objects)
+		if ( !elemData ) {
+			return;
+		}
+
+		// Caller can pass in an object of custom data in lieu of the handler
+		if ( handler.handler ) {
+			handleObjIn = handler;
+			handler = handleObjIn.handler;
+			selector = handleObjIn.selector;
+		}
+
+		// Make sure that the handler has a unique ID, used to find/remove it later
+		if ( !handler.guid ) {
+			handler.guid = jQuery.guid++;
+		}
+
+		// Init the element's event structure and main handler, if this is the first
+		if ( !( events = elemData.events ) ) {
+			events = elemData.events = {};
+		}
+		if ( !( eventHandle = elemData.handle ) ) {
+			eventHandle = elemData.handle = function( e ) {
+
+				// Discard the second event of a jQuery.event.trigger() and
+				// when an event is called after a page has unloaded
+				return typeof jQuery !== "undefined" &&
+					( !e || jQuery.event.triggered !== e.type ) ?
+					jQuery.event.dispatch.apply( eventHandle.elem, arguments ) :
+					undefined;
+			};
+
+			// Add elem as a property of the handle fn to prevent a memory leak
+			// with IE non-native events
+			eventHandle.elem = elem;
+		}
+
+		// Handle multiple events separated by a space
+		types = ( types || "" ).match( rnotwhite ) || [ "" ];
+		t = types.length;
+		while ( t-- ) {
+			tmp = rtypenamespace.exec( types[ t ] ) || [];
+			type = origType = tmp[ 1 ];
+			namespaces = ( tmp[ 2 ] || "" ).split( "." ).sort();
+
+			// There *must* be a type, no attaching namespace-only handlers
+			if ( !type ) {
+				continue;
+			}
+
+			// If event changes its type, use the special event handlers for the changed type
+			special = jQuery.event.special[ type ] || {};
+
+			// If selector defined, determine special event api type, otherwise given type
+			type = ( selector ? special.delegateType : special.bindType ) || type;
+
+			// Update special based on newly reset type
+			special = jQuery.event.special[ type ] || {};
+
+			// handleObj is passed to all event handlers
+			handleObj = jQuery.extend( {
+				type: type,
+				origType: origType,
+				data: data,
+				handler: handler,
+				guid: handler.guid,
+				selector: selector,
+				needsContext: selector && jQuery.expr.match.needsContext.test( selector ),
+				namespace: namespaces.join( "." )
+			}, handleObjIn );
+
+			// Init the event handler queue if we're the first
+			if ( !( handlers = events[ type ] ) ) {
+				handlers = events[ type ] = [];
+				handlers.delegateCount = 0;
+
+				// Only use addEventListener/attachEvent if the special events handler returns false
+				if ( !special.setup ||
+					special.setup.call( elem, data, namespaces, eventHandle ) === false ) {
+
+					// Bind the global event handler to the element
+					if ( elem.addEventListener ) {
+						elem.addEventListener( type, eventHandle, false );
+
+					} else if ( elem.attachEvent ) {
+						elem.attachEvent( "on" + type, eventHandle );
+					}
+				}
+			}
+
+			if ( special.add ) {
+				special.add.call( elem, handleObj );
+
+				if ( !handleObj.handler.guid ) {
+					handleObj.handler.guid = handler.guid;
+				}
+			}
+
+			// Add to the element's handler list, delegates in front
+			if ( selector ) {
+				handlers.splice( handlers.delegateCount++, 0, handleObj );
+			} else {
+				handlers.push( handleObj );
+			}
+
+			// Keep track of which events have ever been used, for event optimization
+			jQuery.event.global[ type ] = true;
+		}
+
+		// Nullify elem to prevent memory leaks in IE
+		elem = null;
+	},
+
+	// Detach an event or set of events from an element
+	remove: function( elem, types, handler, selector, mappedTypes ) {
+		var j, handleObj, tmp,
+			origCount, t, events,
+			special, handlers, type,
+			namespaces, origType,
+			elemData = jQuery.hasData( elem ) && jQuery._data( elem );
+
+		if ( !elemData || !( events = elemData.events ) ) {
+			return;
+		}
+
+		// Once for each type.namespace in types; type may be omitted
+		types = ( types || "" ).match( rnotwhite ) || [ "" ];
+		t = types.length;
+		while ( t-- ) {
+			tmp = rtypenamespace.exec( types[ t ] ) || [];
+			type = origType = tmp[ 1 ];
+			namespaces = ( tmp[ 2 ] || "" ).split( "." ).sort();
+
+			// Unbind all events (on this namespace, if provided) for the element
+			if ( !type ) {
+				for ( type in events ) {
+					jQuery.event.remove( elem, type + types[ t ], handler, selector, true );
+				}
+				continue;
+			}
+
+			special = jQuery.event.special[ type ] || {};
+			type = ( selector ? special.delegateType : special.bindType ) || type;
+			handlers = events[ type ] || [];
+			tmp = tmp[ 2 ] &&
+				new RegExp( "(^|\\.)" + namespaces.join( "\\.(?:.*\\.|)" ) + "(\\.|$)" );
+
+			// Remove matching events
+			origCount = j = handlers.length;
+			while ( j-- ) {
+				handleObj = handlers[ j ];
+
+				if ( ( mappedTypes || origType === handleObj.origType ) &&
+					( !handler || handler.guid === handleObj.guid ) &&
+					( !tmp || tmp.test( handleObj.namespace ) ) &&
+					( !selector || selector === handleObj.selector ||
+						selector === "**" && handleObj.selector ) ) {
+					handlers.splice( j, 1 );
+
+					if ( handleObj.selector ) {
+						handlers.delegateCount--;
+					}
+					if ( special.remove ) {
+						special.remove.call( elem, handleObj );
+					}
+				}
+			}
+
+			// Remove generic event handler if we removed something and no more handlers exist
+			// (avoids potential for endless recursion during removal of special event handlers)
+			if ( origCount && !handlers.length ) {
+				if ( !special.teardown ||
+					special.teardown.call( elem, namespaces, elemData.handle ) === false ) {
+
+					jQuery.removeEvent( elem, type, elemData.handle );
+				}
+
+				delete events[ type ];
+			}
+		}
+
+		// Remove the expando if it's no longer used
+		if ( jQuery.isEmptyObject( events ) ) {
+			delete elemData.handle;
+
+			// removeData also checks for emptiness and clears the expando if empty
+			// so use it instead of delete
+			jQuery._removeData( elem, "events" );
+		}
+	},
+
+	trigger: function( event, data, elem, onlyHandlers ) {
+		var handle, ontype, cur,
+			bubbleType, special, tmp, i,
+			eventPath = [ elem || document ],
+			type = hasOwn.call( event, "type" ) ? event.type : event,
+			namespaces = hasOwn.call( event, "namespace" ) ? event.namespace.split( "." ) : [];
+
+		cur = tmp = elem = elem || document;
+
+		// Don't do events on text and comment nodes
+		if ( elem.nodeType === 3 || elem.nodeType === 8 ) {
+			return;
+		}
+
+		// focus/blur morphs to focusin/out; ensure we're not firing them right now
+		if ( rfocusMorph.test( type + jQuery.event.triggered ) ) {
+			return;
+		}
+
+		if ( type.indexOf( "." ) > -1 ) {
+
+			// Namespaced trigger; create a regexp to match event type in handle()
+			namespaces = type.split( "." );
+			type = namespaces.shift();
+			namespaces.sort();
+		}
+		ontype = type.indexOf( ":" ) < 0 && "on" + type;
+
+		// Caller can pass in a jQuery.Event object, Object, or just an event type string
+		event = event[ jQuery.expando ] ?
+			event :
+			new jQuery.Event( type, typeof event === "object" && event );
+
+		// Trigger bitmask: & 1 for native handlers; & 2 for jQuery (always true)
+		event.isTrigger = onlyHandlers ? 2 : 3;
+		event.namespace = namespaces.join( "." );
+		event.rnamespace = event.namespace ?
+			new RegExp( "(^|\\.)" + namespaces.join( "\\.(?:.*\\.|)" ) + "(\\.|$)" ) :
+			null;
+
+		// Clean up the event in case it is being reused
+		event.result = undefined;
+		if ( !event.target ) {
+			event.target = elem;
+		}
+
+		// Clone any incoming data and prepend the event, creating the handler arg list
+		data = data == null ?
+			[ event ] :
+			jQuery.makeArray( data, [ event ] );
+
+		// Allow special events to draw outside the lines
+		special = jQuery.event.special[ type ] || {};
+		if ( !onlyHandlers && special.trigger && special.trigger.apply( elem, data ) === false ) {
+			return;
+		}
+
+		// Determine event propagation path in advance, per W3C events spec (#9951)
+		// Bubble up to document, then to window; watch for a global ownerDocument var (#9724)
+		if ( !onlyHandlers && !special.noBubble && !jQuery.isWindow( elem ) ) {
+
+			bubbleType = special.delegateType || type;
+			if ( !rfocusMorph.test( bubbleType + type ) ) {
+				cur = cur.parentNode;
+			}
+			for ( ; cur; cur = cur.parentNode ) {
+				eventPath.push( cur );
+				tmp = cur;
+			}
+
+			// Only add window if we got to document (e.g., not plain obj or detached DOM)
+			if ( tmp === ( elem.ownerDocument || document ) ) {
+				eventPath.push( tmp.defaultView || tmp.parentWindow || window );
+			}
+		}
+
+		// Fire handlers on the event path
+		i = 0;
+		while ( ( cur = eventPath[ i++ ] ) && !event.isPropagationStopped() ) {
+
+			event.type = i > 1 ?
+				bubbleType :
+				special.bindType || type;
+
+			// jQuery handler
+			handle = ( jQuery._data( cur, "events" ) || {} )[ event.type ] &&
+				jQuery._data( cur, "handle" );
+
+			if ( handle ) {
+				handle.apply( cur, data );
+			}
+
+			// Native handler
+			handle = ontype && cur[ ontype ];
+			if ( handle && handle.apply && acceptData( cur ) ) {
+				event.result = handle.apply( cur, data );
+				if ( event.result === false ) {
+					event.preventDefault();
+				}
+			}
+		}
+		event.type = type;
+
+		// If nobody prevented the default action, do it now
+		if ( !onlyHandlers && !event.isDefaultPrevented() ) {
+
+			if (
+				( !special._default ||
+				 special._default.apply( eventPath.pop(), data ) === false
+				) && acceptData( elem )
+			) {
+
+				// Call a native DOM method on the target with the same name name as the event.
+				// Can't use an .isFunction() check here because IE6/7 fails that test.
+				// Don't do default actions on window, that's where global variables be (#6170)
+				if ( ontype && elem[ type ] && !jQuery.isWindow( elem ) ) {
+
+					// Don't re-trigger an onFOO event when we call its FOO() method
+					tmp = elem[ ontype ];
+
+					if ( tmp ) {
+						elem[ ontype ] = null;
+					}
+
+					// Prevent re-triggering of the same event, since we already bubbled it above
+					jQuery.event.triggered = type;
+					try {
+						elem[ type ]();
+					} catch ( e ) {
+
+						// IE<9 dies on focus/blur to hidden element (#1486,#12518)
+						// only reproducible on winXP IE8 native, not IE9 in IE8 mode
+					}
+					jQuery.event.triggered = undefined;
+
+					if ( tmp ) {
+						elem[ ontype ] = tmp;
+					}
+				}
+			}
+		}
+
+		return event.result;
+	},
+
+	dispatch: function( event ) {
+
+		// Make a writable jQuery.Event from the native event object
+		event = jQuery.event.fix( event );
+
+		var i, j, ret, matched, handleObj,
+			handlerQueue = [],
+			args = slice.call( arguments ),
+			handlers = ( jQuery._data( this, "events" ) || {} )[ event.type ] || [],
+			special = jQuery.event.special[ event.type ] || {};
+
+		// Use the fix-ed jQuery.Event rather than the (read-only) native event
+		args[ 0 ] = event;
+		event.delegateTarget = this;
+
+		// Call the preDispatch hook for the mapped type, and let it bail if desired
+		if ( special.preDispatch && special.preDispatch.call( this, event ) === false ) {
+			return;
+		}
+
+		// Determine handlers
+		handlerQueue = jQuery.event.handlers.call( this, event, handlers );
+
+		// Run delegates first; they may want to stop propagation beneath us
+		i = 0;
+		while ( ( matched = handlerQueue[ i++ ] ) && !event.isPropagationStopped() ) {
+			event.currentTarget = matched.elem;
+
+			j = 0;
+			while ( ( handleObj = matched.handlers[ j++ ] ) &&
+				!event.isImmediatePropagationStopped() ) {
+
+				// Triggered event must either 1) have no namespace, or 2) have namespace(s)
+				// a subset or equal to those in the bound event (both can have no namespace).
+				if ( !event.rnamespace || event.rnamespace.test( handleObj.namespace ) ) {
+
+					event.handleObj = handleObj;
+					event.data = handleObj.data;
+
+					ret = ( ( jQuery.event.special[ handleObj.origType ] || {} ).handle ||
+						handleObj.handler ).apply( matched.elem, args );
+
+					if ( ret !== undefined ) {
+						if ( ( event.result = ret ) === false ) {
+							event.preventDefault();
+							event.stopPropagation();
+						}
+					}
+				}
+			}
+		}
+
+		// Call the postDispatch hook for the mapped type
+		if ( special.postDispatch ) {
+			special.postDispatch.call( this, event );
+		}
+
+		return event.result;
+	},
+
+	handlers: function( event, handlers ) {
+		var i, matches, sel, handleObj,
+			handlerQueue = [],
+			delegateCount = handlers.delegateCount,
+			cur = event.target;
+
+		// Support (at least): Chrome, IE9
+		// Find delegate handlers
+		// Black-hole SVG <use> instance trees (#13180)
+		//
+		// Support: Firefox<=42+
+		// Avoid non-left-click in FF but don't block IE radio events (#3861, gh-2343)
+		if ( delegateCount && cur.nodeType &&
+			( event.type !== "click" || isNaN( event.button ) || event.button < 1 ) ) {
+
+			/* jshint eqeqeq: false */
+			for ( ; cur != this; cur = cur.parentNode || this ) {
+				/* jshint eqeqeq: true */
+
+				// Don't check non-elements (#13208)
+				// Don't process clicks on disabled elements (#6911, #8165, #11382, #11764)
+				if ( cur.nodeType === 1 && ( cur.disabled !== true || event.type !== "click" ) ) {
+					matches = [];
+					for ( i = 0; i < delegateCount; i++ ) {
+						handleObj = handlers[ i ];
+
+						// Don't conflict with Object.prototype properties (#13203)
+						sel = handleObj.selector + " ";
+
+						if ( matches[ sel ] === undefined ) {
+							matches[ sel ] = handleObj.needsContext ?
+								jQuery( sel, this ).index( cur ) > -1 :
+								jQuery.find( sel, this, null, [ cur ] ).length;
+						}
+						if ( matches[ sel ] ) {
+							matches.push( handleObj );
+						}
+					}
+					if ( matches.length ) {
+						handlerQueue.push( { elem: cur, handlers: matches } );
+					}
+				}
+			}
+		}
+
+		// Add the remaining (directly-bound) handlers
+		if ( delegateCount < handlers.length ) {
+			handlerQueue.push( { elem: this, handlers: handlers.slice( delegateCount ) } );
+		}
+
+		return handlerQueue;
+	},
+
+	fix: function( event ) {
+		if ( event[ jQuery.expando ] ) {
+			return event;
+		}
+
+		// Create a writable copy of the event object and normalize some properties
+		var i, prop, copy,
+			type = event.type,
+			originalEvent = event,
+			fixHook = this.fixHooks[ type ];
+
+		if ( !fixHook ) {
+			this.fixHooks[ type ] = fixHook =
+				rmouseEvent.test( type ) ? this.mouseHooks :
+				rkeyEvent.test( type ) ? this.keyHooks :
+				{};
+		}
+		copy = fixHook.props ? this.props.concat( fixHook.props ) : this.props;
+
+		event = new jQuery.Event( originalEvent );
+
+		i = copy.length;
+		while ( i-- ) {
+			prop = copy[ i ];
+			event[ prop ] = originalEvent[ prop ];
+		}
+
+		// Support: IE<9
+		// Fix target property (#1925)
+		if ( !event.target ) {
+			event.target = originalEvent.srcElement || document;
+		}
+
+		// Support: Safari 6-8+
+		// Target should not be a text node (#504, #13143)
+		if ( event.target.nodeType === 3 ) {
+			event.target = event.target.parentNode;
+		}
+
+		// Support: IE<9
+		// For mouse/key events, metaKey==false if it's undefined (#3368, #11328)
+		event.metaKey = !!event.metaKey;
+
+		return fixHook.filter ? fixHook.filter( event, originalEvent ) : event;
+	},
+
+	// Includes some event props shared by KeyEvent and MouseEvent
+	props: ( "altKey bubbles cancelable ctrlKey currentTarget detail eventPhase " +
+		"metaKey relatedTarget shiftKey target timeStamp view which" ).split( " " ),
+
+	fixHooks: {},
+
+	keyHooks: {
+		props: "char charCode key keyCode".split( " " ),
+		filter: function( event, original ) {
+
+			// Add which for key events
+			if ( event.which == null ) {
+				event.which = original.charCode != null ? original.charCode : original.keyCode;
+			}
+
+			return event;
+		}
+	},
+
+	mouseHooks: {
+		props: ( "button buttons clientX clientY fromElement offsetX offsetY " +
+			"pageX pageY screenX screenY toElement" ).split( " " ),
+		filter: function( event, original ) {
+			var body, eventDoc, doc,
+				button = original.button,
+				fromElement = original.fromElement;
+
+			// Calculate pageX/Y if missing and clientX/Y available
+			if ( event.pageX == null && original.clientX != null ) {
+				eventDoc = event.target.ownerDocument || document;
+				doc = eventDoc.documentElement;
+				body = eventDoc.body;
+
+				event.pageX = original.clientX +
+					( doc && doc.scrollLeft || body && body.scrollLeft || 0 ) -
+					( doc && doc.clientLeft || body && body.clientLeft || 0 );
+				event.pageY = original.clientY +
+					( doc && doc.scrollTop  || body && body.scrollTop  || 0 ) -
+					( doc && doc.clientTop  || body && body.clientTop  || 0 );
+			}
+
+			// Add relatedTarget, if necessary
+			if ( !event.relatedTarget && fromElement ) {
+				event.relatedTarget = fromElement === event.target ?
+					original.toElement :
+					fromElement;
+			}
+
+			// Add which for click: 1 === left; 2 === middle; 3 === right
+			// Note: button is not normalized, so don't use it
+			if ( !event.which && button !== undefined ) {
+				event.which = ( button & 1 ? 1 : ( button & 2 ? 3 : ( button & 4 ? 2 : 0 ) ) );
+			}
+
+			return event;
+		}
+	},
+
+	special: {
+		load: {
+
+			// Prevent triggered image.load events from bubbling to window.load
+			noBubble: true
+		},
+		focus: {
+
+			// Fire native event if possible so blur/focus sequence is correct
+			trigger: function() {
+				if ( this !== safeActiveElement() && this.focus ) {
+					try {
+						this.focus();
+						return false;
+					} catch ( e ) {
+
+						// Support: IE<9
+						// If we error on focus to hidden element (#1486, #12518),
+						// let .trigger() run the handlers
+					}
+				}
+			},
+			delegateType: "focusin"
+		},
+		blur: {
+			trigger: function() {
+				if ( this === safeActiveElement() && this.blur ) {
+					this.blur();
+					return false;
+				}
+			},
+			delegateType: "focusout"
+		},
+		click: {
+
+			// For checkbox, fire native event so checked state will be right
+			trigger: function() {
+				if ( jQuery.nodeName( this, "input" ) && this.type === "checkbox" && this.click ) {
+					this.click();
+					return false;
+				}
+			},
+
+			// For cross-browser consistency, don't fire native .click() on links
+			_default: function( event ) {
+				return jQuery.nodeName( event.target, "a" );
+			}
+		},
+
+		beforeunload: {
+			postDispatch: function( event ) {
+
+				// Support: Firefox 20+
+				// Firefox doesn't alert if the returnValue field is not set.
+				if ( event.result !== undefined && event.originalEvent ) {
+					event.originalEvent.returnValue = event.result;
+				}
+			}
+		}
+	},
+
+	// Piggyback on a donor event to simulate a different one
+	simulate: function( type, elem, event ) {
+		var e = jQuery.extend(
+			new jQuery.Event(),
+			event,
+			{
+				type: type,
+				isSimulated: true
+
+				// Previously, `originalEvent: {}` was set here, so stopPropagation call
+				// would not be triggered on donor event, since in our own
+				// jQuery.event.stopPropagation function we had a check for existence of
+				// originalEvent.stopPropagation method, so, consequently it would be a noop.
+				//
+				// Guard for simulated events was moved to jQuery.event.stopPropagation function
+				// since `originalEvent` should point to the original event for the
+				// constancy with other events and for more focused logic
+			}
+		);
+
+		jQuery.event.trigger( e, null, elem );
+
+		if ( e.isDefaultPrevented() ) {
+			event.preventDefault();
+		}
+	}
+};
+
+jQuery.removeEvent = document.removeEventListener ?
+	function( elem, type, handle ) {
+
+		// This "if" is needed for plain objects
+		if ( elem.removeEventListener ) {
+			elem.removeEventListener( type, handle );
+		}
+	} :
+	function( elem, type, handle ) {
+		var name = "on" + type;
+
+		if ( elem.detachEvent ) {
+
+			// #8545, #7054, preventing memory leaks for custom events in IE6-8
+			// detachEvent needed property on element, by name of that event,
+			// to properly expose it to GC
+			if ( typeof elem[ name ] === "undefined" ) {
+				elem[ name ] = null;
+			}
+
+			elem.detachEvent( name, handle );
+		}
+	};
+
+jQuery.Event = function( src, props ) {
+
+	// Allow instantiation without the 'new' keyword
+	if ( !( this instanceof jQuery.Event ) ) {
+		return new jQuery.Event( src, props );
+	}
+
+	// Event object
+	if ( src && src.type ) {
+		this.originalEvent = src;
+		this.type = src.type;
+
+		// Events bubbling up the document may have been marked as prevented
+		// by a handler lower down the tree; reflect the correct value.
+		this.isDefaultPrevented = src.defaultPrevented ||
+				src.defaultPrevented === undefined &&
+
+				// Support: IE < 9, Android < 4.0
+				src.returnValue === false ?
+			returnTrue :
+			returnFalse;
+
+	// Event type
+	} else {
+		this.type = src;
+	}
+
+	// Put explicitly provided properties onto the event object
+	if ( props ) {
+		jQuery.extend( this, props );
+	}
+
+	// Create a timestamp if incoming event doesn't have one
+	this.timeStamp = src && src.timeStamp || jQuery.now();
+
+	// Mark it as fixed
+	this[ jQuery.expando ] = true;
+};
+
+// jQuery.Event is based on DOM3 Events as specified by the ECMAScript Language Binding
+// http://www.w3.org/TR/2003/WD-DOM-Level-3-Events-20030331/ecma-script-binding.html
+jQuery.Event.prototype = {
+	constructor: jQuery.Event,
+	isDefaultPrevented: returnFalse,
+	isPropagationStopped: returnFalse,
+	isImmediatePropagationStopped: returnFalse,
+
+	preventDefault: function() {
+		var e = this.originalEvent;
+
+		this.isDefaultPrevented = returnTrue;
+		if ( !e ) {
+			return;
+		}
+
+		// If preventDefault exists, run it on the original event
+		if ( e.preventDefault ) {
+			e.preventDefault();
+
+		// Support: IE
+		// Otherwise set the returnValue property of the original event to false
+		} else {
+			e.returnValue = false;
+		}
+	},
+	stopPropagation: function() {
+		var e = this.originalEvent;
+
+		this.isPropagationStopped = returnTrue;
+
+		if ( !e || this.isSimulated ) {
+			return;
+		}
+
+		// If stopPropagation exists, run it on the original event
+		if ( e.stopPropagation ) {
+			e.stopPropagation();
+		}
+
+		// Support: IE
+		// Set the cancelBubble property of the original event to true
+		e.cancelBubble = true;
+	},
+	stopImmediatePropagation: function() {
+		var e = this.originalEvent;
+
+		this.isImmediatePropagationStopped = returnTrue;
+
+		if ( e && e.stopImmediatePropagation ) {
+			e.stopImmediatePropagation();
+		}
+
+		this.stopPropagation();
+	}
+};
+
+// Create mouseenter/leave events using mouseover/out and event-time checks
+// so that event delegation works in jQuery.
+// Do the same for pointerenter/pointerleave and pointerover/pointerout
+//
+// Support: Safari 7 only
+// Safari sends mouseenter too often; see:
+// https://code.google.com/p/chromium/issues/detail?id=470258
+// for the description of the bug (it existed in older Chrome versions as well).
+jQuery.each( {
+	mouseenter: "mouseover",
+	mouseleave: "mouseout",
+	pointerenter: "pointerover",
+	pointerleave: "pointerout"
+}, function( orig, fix ) {
+	jQuery.event.special[ orig ] = {
+		delegateType: fix,
+		bindType: fix,
+
+		handle: function( event ) {
+			var ret,
+				target = this,
+				related = event.relatedTarget,
+				handleObj = event.handleObj;
+
+			// For mouseenter/leave call the handler if related is outside the target.
+			// NB: No relatedTarget if the mouse left/entered the browser window
+			if ( !related || ( related !== target && !jQuery.contains( target, related ) ) ) {
+				event.type = handleObj.origType;
+				ret = handleObj.handler.apply( this, arguments );
+				event.type = fix;
+			}
+			return ret;
+		}
+	};
+} );
+
+// IE submit delegation
+if ( !support.submit ) {
+
+	jQuery.event.special.submit = {
+		setup: function() {
+
+			// Only need this for delegated form submit events
+			if ( jQuery.nodeName( this, "form" ) ) {
+				return false;
+			}
+
+			// Lazy-add a submit handler when a descendant form may potentially be submitted
+			jQuery.event.add( this, "click._submit keypress._submit", function( e ) {
+
+				// Node name check avoids a VML-related crash in IE (#9807)
+				var elem = e.target,
+					form = jQuery.nodeName( elem, "input" ) || jQuery.nodeName( elem, "button" ) ?
+
+						// Support: IE <=8
+						// We use jQuery.prop instead of elem.form
+						// to allow fixing the IE8 delegated submit issue (gh-2332)
+						// by 3rd party polyfills/workarounds.
+						jQuery.prop( elem, "form" ) :
+						undefined;
+
+				if ( form && !jQuery._data( form, "submit" ) ) {
+					jQuery.event.add( form, "submit._submit", function( event ) {
+						event._submitBubble = true;
+					} );
+					jQuery._data( form, "submit", true );
+				}
+			} );
+
+			// return undefined since we don't need an event listener
+		},
+
+		postDispatch: function( event ) {
+
+			// If form was submitted by the user, bubble the event up the tree
+			if ( event._submitBubble ) {
+				delete event._submitBubble;
+				if ( this.parentNode && !event.isTrigger ) {
+					jQuery.event.simulate( "submit", this.parentNode, event );
+				}
+			}
+		},
+
+		teardown: function() {
+
+			// Only need this for delegated form submit events
+			if ( jQuery.nodeName( this, "form" ) ) {
+				return false;
+			}
+
+			// Remove delegated handlers; cleanData eventually reaps submit handlers attached above
+			jQuery.event.remove( this, "._submit" );
+		}
+	};
+}
+
+// IE change delegation and checkbox/radio fix
+if ( !support.change ) {
+
+	jQuery.event.special.change = {
+
+		setup: function() {
+
+			if ( rformElems.test( this.nodeName ) ) {
+
+				// IE doesn't fire change on a check/radio until blur; trigger it on click
+				// after a propertychange. Eat the blur-change in special.change.handle.
+				// This still fires onchange a second time for check/radio after blur.
+				if ( this.type === "checkbox" || this.type === "radio" ) {
+					jQuery.event.add( this, "propertychange._change", function( event ) {
+						if ( event.originalEvent.propertyName === "checked" ) {
+							this._justChanged = true;
+						}
+					} );
+					jQuery.event.add( this, "click._change", function( event ) {
+						if ( this._justChanged && !event.isTrigger ) {
+							this._justChanged = false;
+						}
+
+						// Allow triggered, simulated change events (#11500)
+						jQuery.event.simulate( "change", this, event );
+					} );
+				}
+				return false;
+			}
+
+			// Delegated event; lazy-add a change handler on descendant inputs
+			jQuery.event.add( this, "beforeactivate._change", function( e ) {
+				var elem = e.target;
+
+				if ( rformElems.test( elem.nodeName ) && !jQuery._data( elem, "change" ) ) {
+					jQuery.event.add( elem, "change._change", function( event ) {
+						if ( this.parentNode && !event.isSimulated && !event.isTrigger ) {
+							jQuery.event.simulate( "change", this.parentNode, event );
+						}
+					} );
+					jQuery._data( elem, "change", true );
+				}
+			} );
+		},
+
+		handle: function( event ) {
+			var elem = event.target;
+
+			// Swallow native change events from checkbox/radio, we already triggered them above
+			if ( this !== elem || event.isSimulated || event.isTrigger ||
+				( elem.type !== "radio" && elem.type !== "checkbox" ) ) {
+
+				return event.handleObj.handler.apply( this, arguments );
+			}
+		},
+
+		teardown: function() {
+			jQuery.event.remove( this, "._change" );
+
+			return !rformElems.test( this.nodeName );
+		}
+	};
+}
+
+// Support: Firefox
+// Firefox doesn't have focus(in | out) events
+// Related ticket - https://bugzilla.mozilla.org/show_bug.cgi?id=687787
+//
+// Support: Chrome, Safari
+// focus(in | out) events fire after focus & blur events,
+// which is spec violation - http://www.w3.org/TR/DOM-Level-3-Events/#events-focusevent-event-order
+// Related ticket - https://code.google.com/p/chromium/issues/detail?id=449857
+if ( !support.focusin ) {
+	jQuery.each( { focus: "focusin", blur: "focusout" }, function( orig, fix ) {
+
+		// Attach a single capturing handler on the document while someone wants focusin/focusout
+		var handler = function( event ) {
+			jQuery.event.simulate( fix, event.target, jQuery.event.fix( event ) );
+		};
+
+		jQuery.event.special[ fix ] = {
+			setup: function() {
+				var doc = this.ownerDocument || this,
+					attaches = jQuery._data( doc, fix );
+
+				if ( !attaches ) {
+					doc.addEventListener( orig, handler, true );
+				}
+				jQuery._data( doc, fix, ( attaches || 0 ) + 1 );
+			},
+			teardown: function() {
+				var doc = this.ownerDocument || this,
+					attaches = jQuery._data( doc, fix ) - 1;
+
+				if ( !attaches ) {
+					doc.removeEventListener( orig, handler, true );
+					jQuery._removeData( doc, fix );
+				} else {
+					jQuery._data( doc, fix, attaches );
+				}
+			}
+		};
+	} );
+}
+
+jQuery.fn.extend( {
+
+	on: function( types, selector, data, fn ) {
+		return on( this, types, selector, data, fn );
+	},
+	one: function( types, selector, data, fn ) {
+		return on( this, types, selector, data, fn, 1 );
+	},
+	off: function( types, selector, fn ) {
+		var handleObj, type;
+		if ( types && types.preventDefault && types.handleObj ) {
+
+			// ( event )  dispatched jQuery.Event
+			handleObj = types.handleObj;
+			jQuery( types.delegateTarget ).off(
+				handleObj.namespace ?
+					handleObj.origType + "." + handleObj.namespace :
+					handleObj.origType,
+				handleObj.selector,
+				handleObj.handler
+			);
+			return this;
+		}
+		if ( typeof types === "object" ) {
+
+			// ( types-object [, selector] )
+			for ( type in types ) {
+				this.off( type, selector, types[ type ] );
+			}
+			return this;
+		}
+		if ( selector === false || typeof selector === "function" ) {
+
+			// ( types [, fn] )
+			fn = selector;
+			selector = undefined;
+		}
+		if ( fn === false ) {
+			fn = returnFalse;
+		}
+		return this.each( function() {
+			jQuery.event.remove( this, types, fn, selector );
+		} );
+	},
+
+	trigger: function( type, data ) {
+		return this.each( function() {
+			jQuery.event.trigger( type, data, this );
+		} );
+	},
+	triggerHandler: function( type, data ) {
+		var elem = this[ 0 ];
+		if ( elem ) {
+			return jQuery.event.trigger( type, data, elem, true );
+		}
+	}
+} );
+
+
+var rinlinejQuery = / jQuery\d+="(?:null|\d+)"/g,
+	rnoshimcache = new RegExp( "<(?:" + nodeNames + ")[\\s/>]", "i" ),
+	rxhtmlTag = /<(?!area|br|col|embed|hr|img|input|link|meta|param)(([\w:-]+)[^>]*)\/>/gi,
+
+	// Support: IE 10-11, Edge 10240+
+	// In IE/Edge using regex groups here causes severe slowdowns.
+	// See https://connect.microsoft.com/IE/feedback/details/1736512/
+	rnoInnerhtml = /<script|<style|<link/i,
+
+	// checked="checked" or checked
+	rchecked = /checked\s*(?:[^=]|=\s*.checked.)/i,
+	rscriptTypeMasked = /^true\/(.*)/,
+	rcleanScript = /^\s*<!(?:\[CDATA\[|--)|(?:\]\]|--)>\s*$/g,
+	safeFragment = createSafeFragment( document ),
+	fragmentDiv = safeFragment.appendChild( document.createElement( "div" ) );
+
+// Support: IE<8
+// Manipulating tables requires a tbody
+function manipulationTarget( elem, content ) {
+	return jQuery.nodeName( elem, "table" ) &&
+		jQuery.nodeName( content.nodeType !== 11 ? content : content.firstChild, "tr" ) ?
+
+		elem.getElementsByTagName( "tbody" )[ 0 ] ||
+			elem.appendChild( elem.ownerDocument.createElement( "tbody" ) ) :
+		elem;
+}
+
+// Replace/restore the type attribute of script elements for safe DOM manipulation
+function disableScript( elem ) {
+	elem.type = ( jQuery.find.attr( elem, "type" ) !== null ) + "/" + elem.type;
+	return elem;
+}
+function restoreScript( elem ) {
+	var match = rscriptTypeMasked.exec( elem.type );
+	if ( match ) {
+		elem.type = match[ 1 ];
+	} else {
+		elem.removeAttribute( "type" );
+	}
+	return elem;
+}
+
+function cloneCopyEvent( src, dest ) {
+	if ( dest.nodeType !== 1 || !jQuery.hasData( src ) ) {
+		return;
+	}
+
+	var type, i, l,
+		oldData = jQuery._data( src ),
+		curData = jQuery._data( dest, oldData ),
+		events = oldData.events;
+
+	if ( events ) {
+		delete curData.handle;
+		curData.events = {};
+
+		for ( type in events ) {
+			for ( i = 0, l = events[ type ].length; i < l; i++ ) {
+				jQuery.event.add( dest, type, events[ type ][ i ] );
+			}
+		}
+	}
+
+	// make the cloned public data object a copy from the original
+	if ( curData.data ) {
+		curData.data = jQuery.extend( {}, curData.data );
+	}
+}
+
+function fixCloneNodeIssues( src, dest ) {
+	var nodeName, e, data;
+
+	// We do not need to do anything for non-Elements
+	if ( dest.nodeType !== 1 ) {
+		return;
+	}
+
+	nodeName = dest.nodeName.toLowerCase();
+
+	// IE6-8 copies events bound via attachEvent when using cloneNode.
+	if ( !support.noCloneEvent && dest[ jQuery.expando ] ) {
+		data = jQuery._data( dest );
+
+		for ( e in data.events ) {
+			jQuery.removeEvent( dest, e, data.handle );
+		}
+
+		// Event data gets referenced instead of copied if the expando gets copied too
+		dest.removeAttribute( jQuery.expando );
+	}
+
+	// IE blanks contents when cloning scripts, and tries to evaluate newly-set text
+	if ( nodeName === "script" && dest.text !== src.text ) {
+		disableScript( dest ).text = src.text;
+		restoreScript( dest );
+
+	// IE6-10 improperly clones children of object elements using classid.
+	// IE10 throws NoModificationAllowedError if parent is null, #12132.
+	} else if ( nodeName === "object" ) {
+		if ( dest.parentNode ) {
+			dest.outerHTML = src.outerHTML;
+		}
+
+		// This path appears unavoidable for IE9. When cloning an object
+		// element in IE9, the outerHTML strategy above is not sufficient.
+		// If the src has innerHTML and the destination does not,
+		// copy the src.innerHTML into the dest.innerHTML. #10324
+		if ( support.html5Clone && ( src.innerHTML && !jQuery.trim( dest.innerHTML ) ) ) {
+			dest.innerHTML = src.innerHTML;
+		}
+
+	} else if ( nodeName === "input" && rcheckableType.test( src.type ) ) {
+
+		// IE6-8 fails to persist the checked state of a cloned checkbox
+		// or radio button. Worse, IE6-7 fail to give the cloned element
+		// a checked appearance if the defaultChecked value isn't also set
+
+		dest.defaultChecked = dest.checked = src.checked;
+
+		// IE6-7 get confused and end up setting the value of a cloned
+		// checkbox/radio button to an empty string instead of "on"
+		if ( dest.value !== src.value ) {
+			dest.value = src.value;
+		}
+
+	// IE6-8 fails to return the selected option to the default selected
+	// state when cloning options
+	} else if ( nodeName === "option" ) {
+		dest.defaultSelected = dest.selected = src.defaultSelected;
+
+	// IE6-8 fails to set the defaultValue to the correct value when
+	// cloning other types of input fields
+	} else if ( nodeName === "input" || nodeName === "textarea" ) {
+		dest.defaultValue = src.defaultValue;
+	}
+}
+
+function domManip( collection, args, callback, ignored ) {
+
+	// Flatten any nested arrays
+	args = concat.apply( [], args );
+
+	var first, node, hasScripts,
+		scripts, doc, fragment,
+		i = 0,
+		l = collection.length,
+		iNoClone = l - 1,
+		value = args[ 0 ],
+		isFunction = jQuery.isFunction( value );
+
+	// We can't cloneNode fragments that contain checked, in WebKit
+	if ( isFunction ||
+			( l > 1 && typeof value === "string" &&
+				!support.checkClone && rchecked.test( value ) ) ) {
+		return collection.each( function( index ) {
+			var self = collection.eq( index );
+			if ( isFunction ) {
+				args[ 0 ] = value.call( this, index, self.html() );
+			}
+			domManip( self, args, callback, ignored );
+		} );
+	}
+
+	if ( l ) {
+		fragment = buildFragment( args, collection[ 0 ].ownerDocument, false, collection, ignored );
+		first = fragment.firstChild;
+
+		if ( fragment.childNodes.length === 1 ) {
+			fragment = first;
+		}
+
+		// Require either new content or an interest in ignored elements to invoke the callback
+		if ( first || ignored ) {
+			scripts = jQuery.map( getAll( fragment, "script" ), disableScript );
+			hasScripts = scripts.length;
+
+			// Use the original fragment for the last item
+			// instead of the first because it can end up
+			// being emptied incorrectly in certain situations (#8070).
+			for ( ; i < l; i++ ) {
+				node = fragment;
+
+				if ( i !== iNoClone ) {
+					node = jQuery.clone( node, true, true );
+
+					// Keep references to cloned scripts for later restoration
+					if ( hasScripts ) {
+
+						// Support: Android<4.1, PhantomJS<2
+						// push.apply(_, arraylike) throws on ancient WebKit
+						jQuery.merge( scripts, getAll( node, "script" ) );
+					}
+				}
+
+				callback.call( collection[ i ], node, i );
+			}
+
+			if ( hasScripts ) {
+				doc = scripts[ scripts.length - 1 ].ownerDocument;
+
+				// Reenable scripts
+				jQuery.map( scripts, restoreScript );
+
+				// Evaluate executable scripts on first document insertion
+				for ( i = 0; i < hasScripts; i++ ) {
+					node = scripts[ i ];
+					if ( rscriptType.test( node.type || "" ) &&
+						!jQuery._data( node, "globalEval" ) &&
+						jQuery.contains( doc, node ) ) {
+
+						if ( node.src ) {
+
+							// Optional AJAX dependency, but won't run scripts if not present
+							if ( jQuery._evalUrl ) {
+								jQuery._evalUrl( node.src );
+							}
+						} else {
+							jQuery.globalEval(
+								( node.text || node.textContent || node.innerHTML || "" )
+									.replace( rcleanScript, "" )
+							);
+						}
+					}
+				}
+			}
+
+			// Fix #11809: Avoid leaking memory
+			fragment = first = null;
+		}
+	}
+
+	return collection;
+}
+
+function remove( elem, selector, keepData ) {
+	var node,
+		elems = selector ? jQuery.filter( selector, elem ) : elem,
+		i = 0;
+
+	for ( ; ( node = elems[ i ] ) != null; i++ ) {
+
+		if ( !keepData && node.nodeType === 1 ) {
+			jQuery.cleanData( getAll( node ) );
+		}
+
+		if ( node.parentNode ) {
+			if ( keepData && jQuery.contains( node.ownerDocument, node ) ) {
+				setGlobalEval( getAll( node, "script" ) );
+			}
+			node.parentNode.removeChild( node );
+		}
+	}
+
+	return elem;
+}
+
+jQuery.extend( {
+	htmlPrefilter: function( html ) {
+		return html.replace( rxhtmlTag, "<$1></$2>" );
+	},
+
+	clone: function( elem, dataAndEvents, deepDataAndEvents ) {
+		var destElements, node, clone, i, srcElements,
+			inPage = jQuery.contains( elem.ownerDocument, elem );
+
+		if ( support.html5Clone || jQuery.isXMLDoc( elem ) ||
+			!rnoshimcache.test( "<" + elem.nodeName + ">" ) ) {
+
+			clone = elem.cloneNode( true );
+
+		// IE<=8 does not properly clone detached, unknown element nodes
+		} else {
+			fragmentDiv.innerHTML = elem.outerHTML;
+			fragmentDiv.removeChild( clone = fragmentDiv.firstChild );
+		}
+
+		if ( ( !support.noCloneEvent || !support.noCloneChecked ) &&
+				( elem.nodeType === 1 || elem.nodeType === 11 ) && !jQuery.isXMLDoc( elem ) ) {
+
+			// We eschew Sizzle here for performance reasons: http://jsperf.com/getall-vs-sizzle/2
+			destElements = getAll( clone );
+			srcElements = getAll( elem );
+
+			// Fix all IE cloning issues
+			for ( i = 0; ( node = srcElements[ i ] ) != null; ++i ) {
+
+				// Ensure that the destination node is not null; Fixes #9587
+				if ( destElements[ i ] ) {
+					fixCloneNodeIssues( node, destElements[ i ] );
+				}
+			}
+		}
+
+		// Copy the events from the original to the clone
+		if ( dataAndEvents ) {
+			if ( deepDataAndEvents ) {
+				srcElements = srcElements || getAll( elem );
+				destElements = destElements || getAll( clone );
+
+				for ( i = 0; ( node = srcElements[ i ] ) != null; i++ ) {
+					cloneCopyEvent( node, destElements[ i ] );
+				}
+			} else {
+				cloneCopyEvent( elem, clone );
+			}
+		}
+
+		// Preserve script evaluation history
+		destElements = getAll( clone, "script" );
+		if ( destElements.length > 0 ) {
+			setGlobalEval( destElements, !inPage && getAll( elem, "script" ) );
+		}
+
+		destElements = srcElements = node = null;
+
+		// Return the cloned set
+		return clone;
+	},
+
+	cleanData: function( elems, /* internal */ forceAcceptData ) {
+		var elem, type, id, data,
+			i = 0,
+			internalKey = jQuery.expando,
+			cache = jQuery.cache,
+			attributes = support.attributes,
+			special = jQuery.event.special;
+
+		for ( ; ( elem = elems[ i ] ) != null; i++ ) {
+			if ( forceAcceptData || acceptData( elem ) ) {
+
+				id = elem[ internalKey ];
+				data = id && cache[ id ];
+
+				if ( data ) {
+					if ( data.events ) {
+						for ( type in data.events ) {
+							if ( special[ type ] ) {
+								jQuery.event.remove( elem, type );
+
+							// This is a shortcut to avoid jQuery.event.remove's overhead
+							} else {
+								jQuery.removeEvent( elem, type, data.handle );
+							}
+						}
+					}
+
+					// Remove cache only if it was not already removed by jQuery.event.remove
+					if ( cache[ id ] ) {
+
+						delete cache[ id ];
+
+						// Support: IE<9
+						// IE does not allow us to delete expando properties from nodes
+						// IE creates expando attributes along with the property
+						// IE does not have a removeAttribute function on Document nodes
+						if ( !attributes && typeof elem.removeAttribute !== "undefined" ) {
+							elem.removeAttribute( internalKey );
+
+						// Webkit & Blink performance suffers when deleting properties
+						// from DOM nodes, so set to undefined instead
+						// https://code.google.com/p/chromium/issues/detail?id=378607
+						} else {
+							elem[ internalKey ] = undefined;
+						}
+
+						deletedIds.push( id );
+					}
+				}
+			}
+		}
+	}
+} );
+
+jQuery.fn.extend( {
+
+	// Keep domManip exposed until 3.0 (gh-2225)
+	domManip: domManip,
+
+	detach: function( selector ) {
+		return remove( this, selector, true );
+	},
+
+	remove: function( selector ) {
+		return remove( this, selector );
+	},
+
+	text: function( value ) {
+		return access( this, function( value ) {
+			return value === undefined ?
+				jQuery.text( this ) :
+				this.empty().append(
+					( this[ 0 ] && this[ 0 ].ownerDocument || document ).createTextNode( value )
+				);
+		}, null, value, arguments.length );
+	},
+
+	append: function() {
+		return domManip( this, arguments, function( elem ) {
+			if ( this.nodeType === 1 || this.nodeType === 11 || this.nodeType === 9 ) {
+				var target = manipulationTarget( this, elem );
+				target.appendChild( elem );
+			}
+		} );
+	},
+
+	prepend: function() {
+		return domManip( this, arguments, function( elem ) {
+			if ( this.nodeType === 1 || this.nodeType === 11 || this.nodeType === 9 ) {
+				var target = manipulationTarget( this, elem );
+				target.insertBefore( elem, target.firstChild );
+			}
+		} );
+	},
+
+	before: function() {
+		return domManip( this, arguments, function( elem ) {
+			if ( this.parentNode ) {
+				this.parentNode.insertBefore( elem, this );
+			}
+		} );
+	},
+
+	after: function() {
+		return domManip( this, arguments, function( elem ) {
+			if ( this.parentNode ) {
+				this.parentNode.insertBefore( elem, this.nextSibling );
+			}
+		} );
+	},
+
+	empty: function() {
+		var elem,
+			i = 0;
+
+		for ( ; ( elem = this[ i ] ) != null; i++ ) {
+
+			// Remove element nodes and prevent memory leaks
+			if ( elem.nodeType === 1 ) {
+				jQuery.cleanData( getAll( elem, false ) );
+			}
+
+			// Remove any remaining nodes
+			while ( elem.firstChild ) {
+				elem.removeChild( elem.firstChild );
+			}
+
+			// If this is a select, ensure that it displays empty (#12336)
+			// Support: IE<9
+			if ( elem.options && jQuery.nodeName( elem, "select" ) ) {
+				elem.options.length = 0;
+			}
+		}
+
+		return this;
+	},
+
+	clone: function( dataAndEvents, deepDataAndEvents ) {
+		dataAndEvents = dataAndEvents == null ? false : dataAndEvents;
+		deepDataAndEvents = deepDataAndEvents == null ? dataAndEvents : deepDataAndEvents;
+
+		return this.map( function() {
+			return jQuery.clone( this, dataAndEvents, deepDataAndEvents );
+		} );
+	},
+
+	html: function( value ) {
+		return access( this, function( value ) {
+			var elem = this[ 0 ] || {},
+				i = 0,
+				l = this.length;
+
+			if ( value === undefined ) {
+				return elem.nodeType === 1 ?
+					elem.innerHTML.replace( rinlinejQuery, "" ) :
+					undefined;
+			}
+
+			// See if we can take a shortcut and just use innerHTML
+			if ( typeof value === "string" && !rnoInnerhtml.test( value ) &&
+				( support.htmlSerialize || !rnoshimcache.test( value )  ) &&
+				( support.leadingWhitespace || !rleadingWhitespace.test( value ) ) &&
+				!wrapMap[ ( rtagName.exec( value ) || [ "", "" ] )[ 1 ].toLowerCase() ] ) {
+
+				value = jQuery.htmlPrefilter( value );
+
+				try {
+					for ( ; i < l; i++ ) {
+
+						// Remove element nodes and prevent memory leaks
+						elem = this[ i ] || {};
+						if ( elem.nodeType === 1 ) {
+							jQuery.cleanData( getAll( elem, false ) );
+							elem.innerHTML = value;
+						}
+					}
+
+					elem = 0;
+
+				// If using innerHTML throws an exception, use the fallback method
+				} catch ( e ) {}
+			}
+
+			if ( elem ) {
+				this.empty().append( value );
+			}
+		}, null, value, arguments.length );
+	},
+
+	replaceWith: function() {
+		var ignored = [];
+
+		// Make the changes, replacing each non-ignored context element with the new content
+		return domManip( this, arguments, function( elem ) {
+			var parent = this.parentNode;
+
+			if ( jQuery.inArray( this, ignored ) < 0 ) {
+				jQuery.cleanData( getAll( this ) );
+				if ( parent ) {
+					parent.replaceChild( elem, this );
+				}
+			}
+
+		// Force callback invocation
+		}, ignored );
+	}
+} );
+
+jQuery.each( {
+	appendTo: "append",
+	prependTo: "prepend",
+	insertBefore: "before",
+	insertAfter: "after",
+	replaceAll: "replaceWith"
+}, function( name, original ) {
+	jQuery.fn[ name ] = function( selector ) {
+		var elems,
+			i = 0,
+			ret = [],
+			insert = jQuery( selector ),
+			last = insert.length - 1;
+
+		for ( ; i <= last; i++ ) {
+			elems = i === last ? this : this.clone( true );
+			jQuery( insert[ i ] )[ original ]( elems );
+
+			// Modern browsers can apply jQuery collections as arrays, but oldIE needs a .get()
+			push.apply( ret, elems.get() );
+		}
+
+		return this.pushStack( ret );
+	};
+} );
+
+
+var iframe,
+	elemdisplay = {
+
+		// Support: Firefox
+		// We have to pre-define these values for FF (#10227)
+		HTML: "block",
+		BODY: "block"
+	};
+
+/**
+ * Retrieve the actual display of a element
+ * @param {String} name nodeName of the element
+ * @param {Object} doc Document object
+ */
+
+// Called only from within defaultDisplay
+function actualDisplay( name, doc ) {
+	var elem = jQuery( doc.createElement( name ) ).appendTo( doc.body ),
+
+		display = jQuery.css( elem[ 0 ], "display" );
+
+	// We don't have any data stored on the element,
+	// so use "detach" method as fast way to get rid of the element
+	elem.detach();
+
+	return display;
+}
+
+/**
+ * Try to determine the default display value of an element
+ * @param {String} nodeName
+ */
+function defaultDisplay( nodeName ) {
+	var doc = document,
+		display = elemdisplay[ nodeName ];
+
+	if ( !display ) {
+		display = actualDisplay( nodeName, doc );
+
+		// If the simple way fails, read from inside an iframe
+		if ( display === "none" || !display ) {
+
+			// Use the already-created iframe if possible
+			iframe = ( iframe || jQuery( "<iframe frameborder='0' width='0' height='0'/>" ) )
+				.appendTo( doc.documentElement );
+
+			// Always write a new HTML skeleton so Webkit and Firefox don't choke on reuse
+			doc = ( iframe[ 0 ].contentWindow || iframe[ 0 ].contentDocument ).document;
+
+			// Support: IE
+			doc.write();
+			doc.close();
+
+			display = actualDisplay( nodeName, doc );
+			iframe.detach();
+		}
+
+		// Store the correct default display
+		elemdisplay[ nodeName ] = display;
+	}
+
+	return display;
+}
+var rmargin = ( /^margin/ );
+
+var rnumnonpx = new RegExp( "^(" + pnum + ")(?!px)[a-z%]+$", "i" );
+
+var swap = function( elem, options, callback, args ) {
+	var ret, name,
+		old = {};
+
+	// Remember the old values, and insert the new ones
+	for ( name in options ) {
+		old[ name ] = elem.style[ name ];
+		elem.style[ name ] = options[ name ];
+	}
+
+	ret = callback.apply( elem, args || [] );
+
+	// Revert the old values
+	for ( name in options ) {
+		elem.style[ name ] = old[ name ];
+	}
+
+	return ret;
+};
+
+
+var documentElement = document.documentElement;
+
+
+
+( function() {
+	var pixelPositionVal, pixelMarginRightVal, boxSizingReliableVal,
+		reliableHiddenOffsetsVal, reliableMarginRightVal, reliableMarginLeftVal,
+		container = document.createElement( "div" ),
+		div = document.createElement( "div" );
+
+	// Finish early in limited (non-browser) environments
+	if ( !div.style ) {
+		return;
+	}
+
+	div.style.cssText = "float:left;opacity:.5";
+
+	// Support: IE<9
+	// Make sure that element opacity exists (as opposed to filter)
+	support.opacity = div.style.opacity === "0.5";
+
+	// Verify style float existence
+	// (IE uses styleFloat instead of cssFloat)
+	support.cssFloat = !!div.style.cssFloat;
+
+	div.style.backgroundClip = "content-box";
+	div.cloneNode( true ).style.backgroundClip = "";
+	support.clearCloneStyle = div.style.backgroundClip === "content-box";
+
+	container = document.createElement( "div" );
+	container.style.cssText = "border:0;width:8px;height:0;top:0;left:-9999px;" +
+		"padding:0;margin-top:1px;position:absolute";
+	div.innerHTML = "";
+	container.appendChild( div );
+
+	// Support: Firefox<29, Android 2.3
+	// Vendor-prefix box-sizing
+	support.boxSizing = div.style.boxSizing === "" || div.style.MozBoxSizing === "" ||
+		div.style.WebkitBoxSizing === "";
+
+	jQuery.extend( support, {
+		reliableHiddenOffsets: function() {
+			if ( pixelPositionVal == null ) {
+				computeStyleTests();
+			}
+			return reliableHiddenOffsetsVal;
+		},
+
+		boxSizingReliable: function() {
+
+			// We're checking for pixelPositionVal here instead of boxSizingReliableVal
+			// since that compresses better and they're computed together anyway.
+			if ( pixelPositionVal == null ) {
+				computeStyleTests();
+			}
+			return boxSizingReliableVal;
+		},
+
+		pixelMarginRight: function() {
+
+			// Support: Android 4.0-4.3
+			if ( pixelPositionVal == null ) {
+				computeStyleTests();
+			}
+			return pixelMarginRightVal;
+		},
+
+		pixelPosition: function() {
+			if ( pixelPositionVal == null ) {
+				computeStyleTests();
+			}
+			return pixelPositionVal;
+		},
+
+		reliableMarginRight: function() {
+
+			// Support: Android 2.3
+			if ( pixelPositionVal == null ) {
+				computeStyleTests();
+			}
+			return reliableMarginRightVal;
+		},
+
+		reliableMarginLeft: function() {
+
+			// Support: IE <=8 only, Android 4.0 - 4.3 only, Firefox <=3 - 37
+			if ( pixelPositionVal == null ) {
+				computeStyleTests();
+			}
+			return reliableMarginLeftVal;
+		}
+	} );
+
+	function computeStyleTests() {
+		var contents, divStyle,
+			documentElement = document.documentElement;
+
+		// Setup
+		documentElement.appendChild( container );
+
+		div.style.cssText =
+
+			// Support: Android 2.3
+			// Vendor-prefix box-sizing
+			"-webkit-box-sizing:border-box;box-sizing:border-box;" +
+			"position:relative;display:block;" +
+			"margin:auto;border:1px;padding:1px;" +
+			"top:1%;width:50%";
+
+		// Support: IE<9
+		// Assume reasonable values in the absence of getComputedStyle
+		pixelPositionVal = boxSizingReliableVal = reliableMarginLeftVal = false;
+		pixelMarginRightVal = reliableMarginRightVal = true;
+
+		// Check for getComputedStyle so that this code is not run in IE<9.
+		if ( window.getComputedStyle ) {
+			divStyle = window.getComputedStyle( div );
+			pixelPositionVal = ( divStyle || {} ).top !== "1%";
+			reliableMarginLeftVal = ( divStyle || {} ).marginLeft === "2px";
+			boxSizingReliableVal = ( divStyle || { width: "4px" } ).width === "4px";
+
+			// Support: Android 4.0 - 4.3 only
+			// Some styles come back with percentage values, even though they shouldn't
+			div.style.marginRight = "50%";
+			pixelMarginRightVal = ( divStyle || { marginRight: "4px" } ).marginRight === "4px";
+
+			// Support: Android 2.3 only
+			// Div with explicit width and no margin-right incorrectly
+			// gets computed margin-right based on width of container (#3333)
+			// WebKit Bug 13343 - getComputedStyle returns wrong value for margin-right
+			contents = div.appendChild( document.createElement( "div" ) );
+
+			// Reset CSS: box-sizing; display; margin; border; padding
+			contents.style.cssText = div.style.cssText =
+
+				// Support: Android 2.3
+				// Vendor-prefix box-sizing
+				"-webkit-box-sizing:content-box;-moz-box-sizing:content-box;" +
+				"box-sizing:content-box;display:block;margin:0;border:0;padding:0";
+			contents.style.marginRight = contents.style.width = "0";
+			div.style.width = "1px";
+
+			reliableMarginRightVal =
+				!parseFloat( ( window.getComputedStyle( contents ) || {} ).marginRight );
+
+			div.removeChild( contents );
+		}
+
+		// Support: IE6-8
+		// First check that getClientRects works as expected
+		// Check if table cells still have offsetWidth/Height when they are set
+		// to display:none and there are still other visible table cells in a
+		// table row; if so, offsetWidth/Height are not reliable for use when
+		// determining if an element has been hidden directly using
+		// display:none (it is still safe to use offsets if a parent element is
+		// hidden; don safety goggles and see bug #4512 for more information).
+		div.style.display = "none";
+		reliableHiddenOffsetsVal = div.getClientRects().length === 0;
+		if ( reliableHiddenOffsetsVal ) {
+			div.style.display = "";
+			div.innerHTML = "<table><tr><td></td><td>t</td></tr></table>";
+			contents = div.getElementsByTagName( "td" );
+			contents[ 0 ].style.cssText = "margin:0;border:0;padding:0;display:none";
+			reliableHiddenOffsetsVal = contents[ 0 ].offsetHeight === 0;
+			if ( reliableHiddenOffsetsVal ) {
+				contents[ 0 ].style.display = "";
+				contents[ 1 ].style.display = "none";
+				reliableHiddenOffsetsVal = contents[ 0 ].offsetHeight === 0;
+			}
+		}
+
+		// Teardown
+		documentElement.removeChild( container );
+	}
+
+} )();
+
+
+var getStyles, curCSS,
+	rposition = /^(top|right|bottom|left)$/;
+
+if ( window.getComputedStyle ) {
+	getStyles = function( elem ) {
+
+		// Support: IE<=11+, Firefox<=30+ (#15098, #14150)
+		// IE throws on elements created in popups
+		// FF meanwhile throws on frame elements through "defaultView.getComputedStyle"
+		var view = elem.ownerDocument.defaultView;
+
+		if ( !view.opener ) {
+			view = window;
+		}
+
+		return view.getComputedStyle( elem );
+	};
+
+	curCSS = function( elem, name, computed ) {
+		var width, minWidth, maxWidth, ret,
+			style = elem.style;
+
+		computed = computed || getStyles( elem );
+
+		// getPropertyValue is only needed for .css('filter') in IE9, see #12537
+		ret = computed ? computed.getPropertyValue( name ) || computed[ name ] : undefined;
+
+		if ( computed ) {
+
+			if ( ret === "" && !jQuery.contains( elem.ownerDocument, elem ) ) {
+				ret = jQuery.style( elem, name );
+			}
+
+			// A tribute to the "awesome hack by Dean Edwards"
+			// Chrome < 17 and Safari 5.0 uses "computed value"
+			// instead of "used value" for margin-right
+			// Safari 5.1.7 (at least) returns percentage for a larger set of values,
+			// but width seems to be reliably pixels
+			// this is against the CSSOM draft spec:
+			// http://dev.w3.org/csswg/cssom/#resolved-values
+			if ( !support.pixelMarginRight() && rnumnonpx.test( ret ) && rmargin.test( name ) ) {
+
+				// Remember the original values
+				width = style.width;
+				minWidth = style.minWidth;
+				maxWidth = style.maxWidth;
+
+				// Put in the new values to get a computed value out
+				style.minWidth = style.maxWidth = style.width = ret;
+				ret = computed.width;
+
+				// Revert the changed values
+				style.width = width;
+				style.minWidth = minWidth;
+				style.maxWidth = maxWidth;
+			}
+		}
+
+		// Support: IE
+		// IE returns zIndex value as an integer.
+		return ret === undefined ?
+			ret :
+			ret + "";
+	};
+} else if ( documentElement.currentStyle ) {
+	getStyles = function( elem ) {
+		return elem.currentStyle;
+	};
+
+	curCSS = function( elem, name, computed ) {
+		var left, rs, rsLeft, ret,
+			style = elem.style;
+
+		computed = computed || getStyles( elem );
+		ret = computed ? computed[ name ] : undefined;
+
+		// Avoid setting ret to empty string here
+		// so we don't default to auto
+		if ( ret == null && style && style[ name ] ) {
+			ret = style[ name ];
+		}
+
+		// From the awesome hack by Dean Edwards
+		// http://erik.eae.net/archives/2007/07/27/18.54.15/#comment-102291
+
+		// If we're not dealing with a regular pixel number
+		// but a number that has a weird ending, we need to convert it to pixels
+		// but not position css attributes, as those are
+		// proportional to the parent element instead
+		// and we can't measure the parent instead because it
+		// might trigger a "stacking dolls" problem
+		if ( rnumnonpx.test( ret ) && !rposition.test( name ) ) {
+
+			// Remember the original values
+			left = style.left;
+			rs = elem.runtimeStyle;
+			rsLeft = rs && rs.left;
+
+			// Put in the new values to get a computed value out
+			if ( rsLeft ) {
+				rs.left = elem.currentStyle.left;
+			}
+			style.left = name === "fontSize" ? "1em" : ret;
+			ret = style.pixelLeft + "px";
+
+			// Revert the changed values
+			style.left = left;
+			if ( rsLeft ) {
+				rs.left = rsLeft;
+			}
+		}
+
+		// Support: IE
+		// IE returns zIndex value as an integer.
+		return ret === undefined ?
+			ret :
+			ret + "" || "auto";
+	};
+}
+
+
+
+
+function addGetHookIf( conditionFn, hookFn ) {
+
+	// Define the hook, we'll check on the first run if it's really needed.
+	return {
+		get: function() {
+			if ( conditionFn() ) {
+
+				// Hook not needed (or it's not possible to use it due
+				// to missing dependency), remove it.
+				delete this.get;
+				return;
+			}
+
+			// Hook needed; redefine it so that the support test is not executed again.
+			return ( this.get = hookFn ).apply( this, arguments );
+		}
+	};
+}
+
+
+var
+
+		ralpha = /alpha\([^)]*\)/i,
+	ropacity = /opacity\s*=\s*([^)]*)/i,
+
+	// swappable if display is none or starts with table except
+	// "table", "table-cell", or "table-caption"
+	// see here for display values:
+	// https://developer.mozilla.org/en-US/docs/CSS/display
+	rdisplayswap = /^(none|table(?!-c[ea]).+)/,
+	rnumsplit = new RegExp( "^(" + pnum + ")(.*)$", "i" ),
+
+	cssShow = { position: "absolute", visibility: "hidden", display: "block" },
+	cssNormalTransform = {
+		letterSpacing: "0",
+		fontWeight: "400"
+	},
+
+	cssPrefixes = [ "Webkit", "O", "Moz", "ms" ],
+	emptyStyle = document.createElement( "div" ).style;
+
+
+// return a css property mapped to a potentially vendor prefixed property
+function vendorPropName( name ) {
+
+	// shortcut for names that are not vendor prefixed
+	if ( name in emptyStyle ) {
+		return name;
+	}
+
+	// check for vendor prefixed names
+	var capName = name.charAt( 0 ).toUpperCase() + name.slice( 1 ),
+		i = cssPrefixes.length;
+
+	while ( i-- ) {
+		name = cssPrefixes[ i ] + capName;
+		if ( name in emptyStyle ) {
+			return name;
+		}
+	}
+}
+
+function showHide( elements, show ) {
+	var display, elem, hidden,
+		values = [],
+		index = 0,
+		length = elements.length;
+
+	for ( ; index < length; index++ ) {
+		elem = elements[ index ];
+		if ( !elem.style ) {
+			continue;
+		}
+
+		values[ index ] = jQuery._data( elem, "olddisplay" );
+		display = elem.style.display;
+		if ( show ) {
+
+			// Reset the inline display of this element to learn if it is
+			// being hidden by cascaded rules or not
+			if ( !values[ index ] && display === "none" ) {
+				elem.style.display = "";
+			}
+
+			// Set elements which have been overridden with display: none
+			// in a stylesheet to whatever the default browser style is
+			// for such an element
+			if ( elem.style.display === "" && isHidden( elem ) ) {
+				values[ index ] =
+					jQuery._data( elem, "olddisplay", defaultDisplay( elem.nodeName ) );
+			}
+		} else {
+			hidden = isHidden( elem );
+
+			if ( display && display !== "none" || !hidden ) {
+				jQuery._data(
+					elem,
+					"olddisplay",
+					hidden ? display : jQuery.css( elem, "display" )
+				);
+			}
+		}
+	}
+
+	// Set the display of most of the elements in a second loop
+	// to avoid the constant reflow
+	for ( index = 0; index < length; index++ ) {
+		elem = elements[ index ];
+		if ( !elem.style ) {
+			continue;
+		}
+		if ( !show || elem.style.display === "none" || elem.style.display === "" ) {
+			elem.style.display = show ? values[ index ] || "" : "none";
+		}
+	}
+
+	return elements;
+}
+
+function setPositiveNumber( elem, value, subtract ) {
+	var matches = rnumsplit.exec( value );
+	return matches ?
+
+		// Guard against undefined "subtract", e.g., when used as in cssHooks
+		Math.max( 0, matches[ 1 ] - ( subtract || 0 ) ) + ( matches[ 2 ] || "px" ) :
+		value;
+}
+
+function augmentWidthOrHeight( elem, name, extra, isBorderBox, styles ) {
+	var i = extra === ( isBorderBox ? "border" : "content" ) ?
+
+		// If we already have the right measurement, avoid augmentation
+		4 :
+
+		// Otherwise initialize for horizontal or vertical properties
+		name === "width" ? 1 : 0,
+
+		val = 0;
+
+	for ( ; i < 4; i += 2 ) {
+
+		// both box models exclude margin, so add it if we want it
+		if ( extra === "margin" ) {
+			val += jQuery.css( elem, extra + cssExpand[ i ], true, styles );
+		}
+
+		if ( isBorderBox ) {
+
+			// border-box includes padding, so remove it if we want content
+			if ( extra === "content" ) {
+				val -= jQuery.css( elem, "padding" + cssExpand[ i ], true, styles );
+			}
+
+			// at this point, extra isn't border nor margin, so remove border
+			if ( extra !== "margin" ) {
+				val -= jQuery.css( elem, "border" + cssExpand[ i ] + "Width", true, styles );
+			}
+		} else {
+
+			// at this point, extra isn't content, so add padding
+			val += jQuery.css( elem, "padding" + cssExpand[ i ], true, styles );
+
+			// at this point, extra isn't content nor padding, so add border
+			if ( extra !== "padding" ) {
+				val += jQuery.css( elem, "border" + cssExpand[ i ] + "Width", true, styles );
+			}
+		}
+	}
+
+	return val;
+}
+
+function getWidthOrHeight( elem, name, extra ) {
+
+	// Start with offset property, which is equivalent to the border-box value
+	var valueIsBorderBox = true,
+		val = name === "width" ? elem.offsetWidth : elem.offsetHeight,
+		styles = getStyles( elem ),
+		isBorderBox = support.boxSizing &&
+			jQuery.css( elem, "boxSizing", false, styles ) === "border-box";
+
+	// Support: IE11 only
+	// In IE 11 fullscreen elements inside of an iframe have
+	// 100x too small dimensions (gh-1764).
+	if ( document.msFullscreenElement && window.top !== window ) {
+
+		// Support: IE11 only
+		// Running getBoundingClientRect on a disconnected node
+		// in IE throws an error.
+		if ( elem.getClientRects().length ) {
+			val = Math.round( elem.getBoundingClientRect()[ name ] * 100 );
+		}
+	}
+
+	// some non-html elements return undefined for offsetWidth, so check for null/undefined
+	// svg - https://bugzilla.mozilla.org/show_bug.cgi?id=649285
+	// MathML - https://bugzilla.mozilla.org/show_bug.cgi?id=491668
+	if ( val <= 0 || val == null ) {
+
+		// Fall back to computed then uncomputed css if necessary
+		val = curCSS( elem, name, styles );
+		if ( val < 0 || val == null ) {
+			val = elem.style[ name ];
+		}
+
+		// Computed unit is not pixels. Stop here and return.
+		if ( rnumnonpx.test( val ) ) {
+			return val;
+		}
+
+		// we need the check for style in case a browser which returns unreliable values
+		// for getComputedStyle silently falls back to the reliable elem.style
+		valueIsBorderBox = isBorderBox &&
+			( support.boxSizingReliable() || val === elem.style[ name ] );
+
+		// Normalize "", auto, and prepare for extra
+		val = parseFloat( val ) || 0;
+	}
+
+	// use the active box-sizing model to add/subtract irrelevant styles
+	return ( val +
+		augmentWidthOrHeight(
+			elem,
+			name,
+			extra || ( isBorderBox ? "border" : "content" ),
+			valueIsBorderBox,
+			styles
+		)
+	) + "px";
+}
+
+jQuery.extend( {
+
+	// Add in style property hooks for overriding the default
+	// behavior of getting and setting a style property
+	cssHooks: {
+		opacity: {
+			get: function( elem, computed ) {
+				if ( computed ) {
+
+					// We should always get a number back from opacity
+					var ret = curCSS( elem, "opacity" );
+					return ret === "" ? "1" : ret;
+				}
+			}
+		}
+	},
+
+	// Don't automatically add "px" to these possibly-unitless properties
+	cssNumber: {
+		"animationIterationCount": true,
+		"columnCount": true,
+		"fillOpacity": true,
+		"flexGrow": true,
+		"flexShrink": true,
+		"fontWeight": true,
+		"lineHeight": true,
+		"opacity": true,
+		"order": true,
+		"orphans": true,
+		"widows": true,
+		"zIndex": true,
+		"zoom": true
+	},
+
+	// Add in properties whose names you wish to fix before
+	// setting or getting the value
+	cssProps: {
+
+		// normalize float css property
+		"float": support.cssFloat ? "cssFloat" : "styleFloat"
+	},
+
+	// Get and set the style property on a DOM Node
+	style: function( elem, name, value, extra ) {
+
+		// Don't set styles on text and comment nodes
+		if ( !elem || elem.nodeType === 3 || elem.nodeType === 8 || !elem.style ) {
+			return;
+		}
+
+		// Make sure that we're working with the right name
+		var ret, type, hooks,
+			origName = jQuery.camelCase( name ),
+			style = elem.style;
+
+		name = jQuery.cssProps[ origName ] ||
+			( jQuery.cssProps[ origName ] = vendorPropName( origName ) || origName );
+
+		// gets hook for the prefixed version
+		// followed by the unprefixed version
+		hooks = jQuery.cssHooks[ name ] || jQuery.cssHooks[ origName ];
+
+		// Check if we're setting a value
+		if ( value !== undefined ) {
+			type = typeof value;
+
+			// Convert "+=" or "-=" to relative numbers (#7345)
+			if ( type === "string" && ( ret = rcssNum.exec( value ) ) && ret[ 1 ] ) {
+				value = adjustCSS( elem, name, ret );
+
+				// Fixes bug #9237
+				type = "number";
+			}
+
+			// Make sure that null and NaN values aren't set. See: #7116
+			if ( value == null || value !== value ) {
+				return;
+			}
+
+			// If a number was passed in, add the unit (except for certain CSS properties)
+			if ( type === "number" ) {
+				value += ret && ret[ 3 ] || ( jQuery.cssNumber[ origName ] ? "" : "px" );
+			}
+
+			// Fixes #8908, it can be done more correctly by specifing setters in cssHooks,
+			// but it would mean to define eight
+			// (for every problematic property) identical functions
+			if ( !support.clearCloneStyle && value === "" && name.indexOf( "background" ) === 0 ) {
+				style[ name ] = "inherit";
+			}
+
+			// If a hook was provided, use that value, otherwise just set the specified value
+			if ( !hooks || !( "set" in hooks ) ||
+				( value = hooks.set( elem, value, extra ) ) !== undefined ) {
+
+				// Support: IE
+				// Swallow errors from 'invalid' CSS values (#5509)
+				try {
+					style[ name ] = value;
+				} catch ( e ) {}
+			}
+
+		} else {
+
+			// If a hook was provided get the non-computed value from there
+			if ( hooks && "get" in hooks &&
+				( ret = hooks.get( elem, false, extra ) ) !== undefined ) {
+
+				return ret;
+			}
+
+			// Otherwise just get the value from the style object
+			return style[ name ];
+		}
+	},
+
+	css: function( elem, name, extra, styles ) {
+		var num, val, hooks,
+			origName = jQuery.camelCase( name );
+
+		// Make sure that we're working with the right name
+		name = jQuery.cssProps[ origName ] ||
+			( jQuery.cssProps[ origName ] = vendorPropName( origName ) || origName );
+
+		// gets hook for the prefixed version
+		// followed by the unprefixed version
+		hooks = jQuery.cssHooks[ name ] || jQuery.cssHooks[ origName ];
+
+		// If a hook was provided get the computed value from there
+		if ( hooks && "get" in hooks ) {
+			val = hooks.get( elem, true, extra );
+		}
+
+		// Otherwise, if a way to get the computed value exists, use that
+		if ( val === undefined ) {
+			val = curCSS( elem, name, styles );
+		}
+
+		//convert "normal" to computed value
+		if ( val === "normal" && name in cssNormalTransform ) {
+			val = cssNormalTransform[ name ];
+		}
+
+		// Return, converting to number if forced or a qualifier was provided and val looks numeric
+		if ( extra === "" || extra ) {
+			num = parseFloat( val );
+			return extra === true || isFinite( num ) ? num || 0 : val;
+		}
+		return val;
+	}
+} );
+
+jQuery.each( [ "height", "width" ], function( i, name ) {
+	jQuery.cssHooks[ name ] = {
+		get: function( elem, computed, extra ) {
+			if ( computed ) {
+
+				// certain elements can have dimension info if we invisibly show them
+				// however, it must have a current display style that would benefit from this
+				return rdisplayswap.test( jQuery.css( elem, "display" ) ) &&
+					elem.offsetWidth === 0 ?
+						swap( elem, cssShow, function() {
+							return getWidthOrHeight( elem, name, extra );
+						} ) :
+						getWidthOrHeight( elem, name, extra );
+			}
+		},
+
+		set: function( elem, value, extra ) {
+			var styles = extra && getStyles( elem );
+			return setPositiveNumber( elem, value, extra ?
+				augmentWidthOrHeight(
+					elem,
+					name,
+					extra,
+					support.boxSizing &&
+						jQuery.css( elem, "boxSizing", false, styles ) === "border-box",
+					styles
+				) : 0
+			);
+		}
+	};
+} );
+
+if ( !support.opacity ) {
+	jQuery.cssHooks.opacity = {
+		get: function( elem, computed ) {
+
+			// IE uses filters for opacity
+			return ropacity.test( ( computed && elem.currentStyle ?
+				elem.currentStyle.filter :
+				elem.style.filter ) || "" ) ?
+					( 0.01 * parseFloat( RegExp.$1 ) ) + "" :
+					computed ? "1" : "";
+		},
+
+		set: function( elem, value ) {
+			var style = elem.style,
+				currentStyle = elem.currentStyle,
+				opacity = jQuery.isNumeric( value ) ? "alpha(opacity=" + value * 100 + ")" : "",
+				filter = currentStyle && currentStyle.filter || style.filter || "";
+
+			// IE has trouble with opacity if it does not have layout
+			// Force it by setting the zoom level
+			style.zoom = 1;
+
+			// if setting opacity to 1, and no other filters exist -
+			// attempt to remove filter attribute #6652
+			// if value === "", then remove inline opacity #12685
+			if ( ( value >= 1 || value === "" ) &&
+					jQuery.trim( filter.replace( ralpha, "" ) ) === "" &&
+					style.removeAttribute ) {
+
+				// Setting style.filter to null, "" & " " still leave "filter:" in the cssText
+				// if "filter:" is present at all, clearType is disabled, we want to avoid this
+				// style.removeAttribute is IE Only, but so apparently is this code path...
+				style.removeAttribute( "filter" );
+
+				// if there is no filter style applied in a css rule
+				// or unset inline opacity, we are done
+				if ( value === "" || currentStyle && !currentStyle.filter ) {
+					return;
+				}
+			}
+
+			// otherwise, set new filter values
+			style.filter = ralpha.test( filter ) ?
+				filter.replace( ralpha, opacity ) :
+				filter + " " + opacity;
+		}
+	};
+}
+
+jQuery.cssHooks.marginRight = addGetHookIf( support.reliableMarginRight,
+	function( elem, computed ) {
+		if ( computed ) {
+			return swap( elem, { "display": "inline-block" },
+				curCSS, [ elem, "marginRight" ] );
+		}
+	}
+);
+
+jQuery.cssHooks.marginLeft = addGetHookIf( support.reliableMarginLeft,
+	function( elem, computed ) {
+		if ( computed ) {
+			return (
+				parseFloat( curCSS( elem, "marginLeft" ) ) ||
+
+				// Support: IE<=11+
+				// Running getBoundingClientRect on a disconnected node in IE throws an error
+				// Support: IE8 only
+				// getClientRects() errors on disconnected elems
+				( jQuery.contains( elem.ownerDocument, elem ) ?
+					elem.getBoundingClientRect().left -
+						swap( elem, { marginLeft: 0 }, function() {
+							return elem.getBoundingClientRect().left;
+						} ) :
+					0
+				)
+			) + "px";
+		}
+	}
+);
+
+// These hooks are used by animate to expand properties
+jQuery.each( {
+	margin: "",
+	padding: "",
+	border: "Width"
+}, function( prefix, suffix ) {
+	jQuery.cssHooks[ prefix + suffix ] = {
+		expand: function( value ) {
+			var i = 0,
+				expanded = {},
+
+				// assumes a single number if not a string
+				parts = typeof value === "string" ? value.split( " " ) : [ value ];
+
+			for ( ; i < 4; i++ ) {
+				expanded[ prefix + cssExpand[ i ] + suffix ] =
+					parts[ i ] || parts[ i - 2 ] || parts[ 0 ];
+			}
+
+			return expanded;
+		}
+	};
+
+	if ( !rmargin.test( prefix ) ) {
+		jQuery.cssHooks[ prefix + suffix ].set = setPositiveNumber;
+	}
+} );
+
+jQuery.fn.extend( {
+	css: function( name, value ) {
+		return access( this, function( elem, name, value ) {
+			var styles, len,
+				map = {},
+				i = 0;
+
+			if ( jQuery.isArray( name ) ) {
+				styles = getStyles( elem );
+				len = name.length;
+
+				for ( ; i < len; i++ ) {
+					map[ name[ i ] ] = jQuery.css( elem, name[ i ], false, styles );
+				}
+
+				return map;
+			}
+
+			return value !== undefined ?
+				jQuery.style( elem, name, value ) :
+				jQuery.css( elem, name );
+		}, name, value, arguments.length > 1 );
+	},
+	show: function() {
+		return showHide( this, true );
+	},
+	hide: function() {
+		return showHide( this );
+	},
+	toggle: function( state ) {
+		if ( typeof state === "boolean" ) {
+			return state ? this.show() : this.hide();
+		}
+
+		return this.each( function() {
+			if ( isHidden( this ) ) {
+				jQuery( this ).show();
+			} else {
+				jQuery( this ).hide();
+			}
+		} );
+	}
+} );
+
+
+function Tween( elem, options, prop, end, easing ) {
+	return new Tween.prototype.init( elem, options, prop, end, easing );
+}
+jQuery.Tween = Tween;
+
+Tween.prototype = {
+	constructor: Tween,
+	init: function( elem, options, prop, end, easing, unit ) {
+		this.elem = elem;
+		this.prop = prop;
+		this.easing = easing || jQuery.easing._default;
+		this.options = options;
+		this.start = this.now = this.cur();
+		this.end = end;
+		this.unit = unit || ( jQuery.cssNumber[ prop ] ? "" : "px" );
+	},
+	cur: function() {
+		var hooks = Tween.propHooks[ this.prop ];
+
+		return hooks && hooks.get ?
+			hooks.get( this ) :
+			Tween.propHooks._default.get( this );
+	},
+	run: function( percent ) {
+		var eased,
+			hooks = Tween.propHooks[ this.prop ];
+
+		if ( this.options.duration ) {
+			this.pos = eased = jQuery.easing[ this.easing ](
+				percent, this.options.duration * percent, 0, 1, this.options.duration
+			);
+		} else {
+			this.pos = eased = percent;
+		}
+		this.now = ( this.end - this.start ) * eased + this.start;
+
+		if ( this.options.step ) {
+			this.options.step.call( this.elem, this.now, this );
+		}
+
+		if ( hooks && hooks.set ) {
+			hooks.set( this );
+		} else {
+			Tween.propHooks._default.set( this );
+		}
+		return this;
+	}
+};
+
+Tween.prototype.init.prototype = Tween.prototype;
+
+Tween.propHooks = {
+	_default: {
+		get: function( tween ) {
+			var result;
+
+			// Use a property on the element directly when it is not a DOM element,
+			// or when there is no matching style property that exists.
+			if ( tween.elem.nodeType !== 1 ||
+				tween.elem[ tween.prop ] != null && tween.elem.style[ tween.prop ] == null ) {
+				return tween.elem[ tween.prop ];
+			}
+
+			// passing an empty string as a 3rd parameter to .css will automatically
+			// attempt a parseFloat and fallback to a string if the parse fails
+			// so, simple values such as "10px" are parsed to Float.
+			// complex values such as "rotate(1rad)" are returned as is.
+			result = jQuery.css( tween.elem, tween.prop, "" );
+
+			// Empty strings, null, undefined and "auto" are converted to 0.
+			return !result || result === "auto" ? 0 : result;
+		},
+		set: function( tween ) {
+
+			// use step hook for back compat - use cssHook if its there - use .style if its
+			// available and use plain properties where available
+			if ( jQuery.fx.step[ tween.prop ] ) {
+				jQuery.fx.step[ tween.prop ]( tween );
+			} else if ( tween.elem.nodeType === 1 &&
+				( tween.elem.style[ jQuery.cssProps[ tween.prop ] ] != null ||
+					jQuery.cssHooks[ tween.prop ] ) ) {
+				jQuery.style( tween.elem, tween.prop, tween.now + tween.unit );
+			} else {
+				tween.elem[ tween.prop ] = tween.now;
+			}
+		}
+	}
+};
+
+// Support: IE <=9
+// Panic based approach to setting things on disconnected nodes
+
+Tween.propHooks.scrollTop = Tween.propHooks.scrollLeft = {
+	set: function( tween ) {
+		if ( tween.elem.nodeType && tween.elem.parentNode ) {
+			tween.elem[ tween.prop ] = tween.now;
+		}
+	}
+};
+
+jQuery.easing = {
+	linear: function( p ) {
+		return p;
+	},
+	swing: function( p ) {
+		return 0.5 - Math.cos( p * Math.PI ) / 2;
+	},
+	_default: "swing"
+};
+
+jQuery.fx = Tween.prototype.init;
+
+// Back Compat <1.8 extension point
+jQuery.fx.step = {};
+
+
+
+
+var
+	fxNow, timerId,
+	rfxtypes = /^(?:toggle|show|hide)$/,
+	rrun = /queueHooks$/;
+
+// Animations created synchronously will run synchronously
+function createFxNow() {
+	window.setTimeout( function() {
+		fxNow = undefined;
+	} );
+	return ( fxNow = jQuery.now() );
+}
+
+// Generate parameters to create a standard animation
+function genFx( type, includeWidth ) {
+	var which,
+		attrs = { height: type },
+		i = 0;
+
+	// if we include width, step value is 1 to do all cssExpand values,
+	// if we don't include width, step value is 2 to skip over Left and Right
+	includeWidth = includeWidth ? 1 : 0;
+	for ( ; i < 4 ; i += 2 - includeWidth ) {
+		which = cssExpand[ i ];
+		attrs[ "margin" + which ] = attrs[ "padding" + which ] = type;
+	}
+
+	if ( includeWidth ) {
+		attrs.opacity = attrs.width = type;
+	}
+
+	return attrs;
+}
+
+function createTween( value, prop, animation ) {
+	var tween,
+		collection = ( Animation.tweeners[ prop ] || [] ).concat( Animation.tweeners[ "*" ] ),
+		index = 0,
+		length = collection.length;
+	for ( ; index < length; index++ ) {
+		if ( ( tween = collection[ index ].call( animation, prop, value ) ) ) {
+
+			// we're done with this property
+			return tween;
+		}
+	}
+}
+
+function defaultPrefilter( elem, props, opts ) {
+	/* jshint validthis: true */
+	var prop, value, toggle, tween, hooks, oldfire, display, checkDisplay,
+		anim = this,
+		orig = {},
+		style = elem.style,
+		hidden = elem.nodeType && isHidden( elem ),
+		dataShow = jQuery._data( elem, "fxshow" );
+
+	// handle queue: false promises
+	if ( !opts.queue ) {
+		hooks = jQuery._queueHooks( elem, "fx" );
+		if ( hooks.unqueued == null ) {
+			hooks.unqueued = 0;
+			oldfire = hooks.empty.fire;
+			hooks.empty.fire = function() {
+				if ( !hooks.unqueued ) {
+					oldfire();
+				}
+			};
+		}
+		hooks.unqueued++;
+
+		anim.always( function() {
+
+			// doing this makes sure that the complete handler will be called
+			// before this completes
+			anim.always( function() {
+				hooks.unqueued--;
+				if ( !jQuery.queue( elem, "fx" ).length ) {
+					hooks.empty.fire();
+				}
+			} );
+		} );
+	}
+
+	// height/width overflow pass
+	if ( elem.nodeType === 1 && ( "height" in props || "width" in props ) ) {
+
+		// Make sure that nothing sneaks out
+		// Record all 3 overflow attributes because IE does not
+		// change the overflow attribute when overflowX and
+		// overflowY are set to the same value
+		opts.overflow = [ style.overflow, style.overflowX, style.overflowY ];
+
+		// Set display property to inline-block for height/width
+		// animations on inline elements that are having width/height animated
+		display = jQuery.css( elem, "display" );
+
+		// Test default display if display is currently "none"
+		checkDisplay = display === "none" ?
+			jQuery._data( elem, "olddisplay" ) || defaultDisplay( elem.nodeName ) : display;
+
+		if ( checkDisplay === "inline" && jQuery.css( elem, "float" ) === "none" ) {
+
+			// inline-level elements accept inline-block;
+			// block-level elements need to be inline with layout
+			if ( !support.inlineBlockNeedsLayout || defaultDisplay( elem.nodeName ) === "inline" ) {
+				style.display = "inline-block";
+			} else {
+				style.zoom = 1;
+			}
+		}
+	}
+
+	if ( opts.overflow ) {
+		style.overflow = "hidden";
+		if ( !support.shrinkWrapBlocks() ) {
+			anim.always( function() {
+				style.overflow = opts.overflow[ 0 ];
+				style.overflowX = opts.overflow[ 1 ];
+				style.overflowY = opts.overflow[ 2 ];
+			} );
+		}
+	}
+
+	// show/hide pass
+	for ( prop in props ) {
+		value = props[ prop ];
+		if ( rfxtypes.exec( value ) ) {
+			delete props[ prop ];
+			toggle = toggle || value === "toggle";
+			if ( value === ( hidden ? "hide" : "show" ) ) {
+
+				// If there is dataShow left over from a stopped hide or show
+				// and we are going to proceed with show, we should pretend to be hidden
+				if ( value === "show" && dataShow && dataShow[ prop ] !== undefined ) {
+					hidden = true;
+				} else {
+					continue;
+				}
+			}
+			orig[ prop ] = dataShow && dataShow[ prop ] || jQuery.style( elem, prop );
+
+		// Any non-fx value stops us from restoring the original display value
+		} else {
+			display = undefined;
+		}
+	}
+
+	if ( !jQuery.isEmptyObject( orig ) ) {
+		if ( dataShow ) {
+			if ( "hidden" in dataShow ) {
+				hidden = dataShow.hidden;
+			}
+		} else {
+			dataShow = jQuery._data( elem, "fxshow", {} );
+		}
+
+		// store state if its toggle - enables .stop().toggle() to "reverse"
+		if ( toggle ) {
+			dataShow.hidden = !hidden;
+		}
+		if ( hidden ) {
+			jQuery( elem ).show();
+		} else {
+			anim.done( function() {
+				jQuery( elem ).hide();
+			} );
+		}
+		anim.done( function() {
+			var prop;
+			jQuery._removeData( elem, "fxshow" );
+			for ( prop in orig ) {
+				jQuery.style( elem, prop, orig[ prop ] );
+			}
+		} );
+		for ( prop in orig ) {
+			tween = createTween( hidden ? dataShow[ prop ] : 0, prop, anim );
+
+			if ( !( prop in dataShow ) ) {
+				dataShow[ prop ] = tween.start;
+				if ( hidden ) {
+					tween.end = tween.start;
+					tween.start = prop === "width" || prop === "height" ? 1 : 0;
+				}
+			}
+		}
+
+	// If this is a noop like .hide().hide(), restore an overwritten display value
+	} else if ( ( display === "none" ? defaultDisplay( elem.nodeName ) : display ) === "inline" ) {
+		style.display = display;
+	}
+}
+
+function propFilter( props, specialEasing ) {
+	var index, name, easing, value, hooks;
+
+	// camelCase, specialEasing and expand cssHook pass
+	for ( index in props ) {
+		name = jQuery.camelCase( index );
+		easing = specialEasing[ name ];
+		value = props[ index ];
+		if ( jQuery.isArray( value ) ) {
+			easing = value[ 1 ];
+			value = props[ index ] = value[ 0 ];
+		}
+
+		if ( index !== name ) {
+			props[ name ] = value;
+			delete props[ index ];
+		}
+
+		hooks = jQuery.cssHooks[ name ];
+		if ( hooks && "expand" in hooks ) {
+			value = hooks.expand( value );
+			delete props[ name ];
+
+			// not quite $.extend, this wont overwrite keys already present.
+			// also - reusing 'index' from above because we have the correct "name"
+			for ( index in value ) {
+				if ( !( index in props ) ) {
+					props[ index ] = value[ index ];
+					specialEasing[ index ] = easing;
+				}
+			}
+		} else {
+			specialEasing[ name ] = easing;
+		}
+	}
+}
+
+function Animation( elem, properties, options ) {
+	var result,
+		stopped,
+		index = 0,
+		length = Animation.prefilters.length,
+		deferred = jQuery.Deferred().always( function() {
+
+			// don't match elem in the :animated selector
+			delete tick.elem;
+		} ),
+		tick = function() {
+			if ( stopped ) {
+				return false;
+			}
+			var currentTime = fxNow || createFxNow(),
+				remaining = Math.max( 0, animation.startTime + animation.duration - currentTime ),
+
+				// Support: Android 2.3
+				// Archaic crash bug won't allow us to use `1 - ( 0.5 || 0 )` (#12497)
+				temp = remaining / animation.duration || 0,
+				percent = 1 - temp,
+				index = 0,
+				length = animation.tweens.length;
+
+			for ( ; index < length ; index++ ) {
+				animation.tweens[ index ].run( percent );
+			}
+
+			deferred.notifyWith( elem, [ animation, percent, remaining ] );
+
+			if ( percent < 1 && length ) {
+				return remaining;
+			} else {
+				deferred.resolveWith( elem, [ animation ] );
+				return false;
+			}
+		},
+		animation = deferred.promise( {
+			elem: elem,
+			props: jQuery.extend( {}, properties ),
+			opts: jQuery.extend( true, {
+				specialEasing: {},
+				easing: jQuery.easing._default
+			}, options ),
+			originalProperties: properties,
+			originalOptions: options,
+			startTime: fxNow || createFxNow(),
+			duration: options.duration,
+			tweens: [],
+			createTween: function( prop, end ) {
+				var tween = jQuery.Tween( elem, animation.opts, prop, end,
+						animation.opts.specialEasing[ prop ] || animation.opts.easing );
+				animation.tweens.push( tween );
+				return tween;
+			},
+			stop: function( gotoEnd ) {
+				var index = 0,
+
+					// if we are going to the end, we want to run all the tweens
+					// otherwise we skip this part
+					length = gotoEnd ? animation.tweens.length : 0;
+				if ( stopped ) {
+					return this;
+				}
+				stopped = true;
+				for ( ; index < length ; index++ ) {
+					animation.tweens[ index ].run( 1 );
+				}
+
+				// resolve when we played the last frame
+				// otherwise, reject
+				if ( gotoEnd ) {
+					deferred.notifyWith( elem, [ animation, 1, 0 ] );
+					deferred.resolveWith( elem, [ animation, gotoEnd ] );
+				} else {
+					deferred.rejectWith( elem, [ animation, gotoEnd ] );
+				}
+				return this;
+			}
+		} ),
+		props = animation.props;
+
+	propFilter( props, animation.opts.specialEasing );
+
+	for ( ; index < length ; index++ ) {
+		result = Animation.prefilters[ index ].call( animation, elem, props, animation.opts );
+		if ( result ) {
+			if ( jQuery.isFunction( result.stop ) ) {
+				jQuery._queueHooks( animation.elem, animation.opts.queue ).stop =
+					jQuery.proxy( result.stop, result );
+			}
+			return result;
+		}
+	}
+
+	jQuery.map( props, createTween, animation );
+
+	if ( jQuery.isFunction( animation.opts.start ) ) {
+		animation.opts.start.call( elem, animation );
+	}
+
+	jQuery.fx.timer(
+		jQuery.extend( tick, {
+			elem: elem,
+			anim: animation,
+			queue: animation.opts.queue
+		} )
+	);
+
+	// attach callbacks from options
+	return animation.progress( animation.opts.progress )
+		.done( animation.opts.done, animation.opts.complete )
+		.fail( animation.opts.fail )
+		.always( animation.opts.always );
+}
+
+jQuery.Animation = jQuery.extend( Animation, {
+
+	tweeners: {
+		"*": [ function( prop, value ) {
+			var tween = this.createTween( prop, value );
+			adjustCSS( tween.elem, prop, rcssNum.exec( value ), tween );
+			return tween;
+		} ]
+	},
+
+	tweener: function( props, callback ) {
+		if ( jQuery.isFunction( props ) ) {
+			callback = props;
+			props = [ "*" ];
+		} else {
+			props = props.match( rnotwhite );
+		}
+
+		var prop,
+			index = 0,
+			length = props.length;
+
+		for ( ; index < length ; index++ ) {
+			prop = props[ index ];
+			Animation.tweeners[ prop ] = Animation.tweeners[ prop ] || [];
+			Animation.tweeners[ prop ].unshift( callback );
+		}
+	},
+
+	prefilters: [ defaultPrefilter ],
+
+	prefilter: function( callback, prepend ) {
+		if ( prepend ) {
+			Animation.prefilters.unshift( callback );
+		} else {
+			Animation.prefilters.push( callback );
+		}
+	}
+} );
+
+jQuery.speed = function( speed, easing, fn ) {
+	var opt = speed && typeof speed === "object" ? jQuery.extend( {}, speed ) : {
+		complete: fn || !fn && easing ||
+			jQuery.isFunction( speed ) && speed,
+		duration: speed,
+		easing: fn && easing || easing && !jQuery.isFunction( easing ) && easing
+	};
+
+	opt.duration = jQuery.fx.off ? 0 : typeof opt.duration === "number" ? opt.duration :
+		opt.duration in jQuery.fx.speeds ?
+			jQuery.fx.speeds[ opt.duration ] : jQuery.fx.speeds._default;
+
+	// normalize opt.queue - true/undefined/null -> "fx"
+	if ( opt.queue == null || opt.queue === true ) {
+		opt.queue = "fx";
+	}
+
+	// Queueing
+	opt.old = opt.complete;
+
+	opt.complete = function() {
+		if ( jQuery.isFunction( opt.old ) ) {
+			opt.old.call( this );
+		}
+
+		if ( opt.queue ) {
+			jQuery.dequeue( this, opt.queue );
+		}
+	};
+
+	return opt;
+};
+
+jQuery.fn.extend( {
+	fadeTo: function( speed, to, easing, callback ) {
+
+		// show any hidden elements after setting opacity to 0
+		return this.filter( isHidden ).css( "opacity", 0 ).show()
+
+			// animate to the value specified
+			.end().animate( { opacity: to }, speed, easing, callback );
+	},
+	animate: function( prop, speed, easing, callback ) {
+		var empty = jQuery.isEmptyObject( prop ),
+			optall = jQuery.speed( speed, easing, callback ),
+			doAnimation = function() {
+
+				// Operate on a copy of prop so per-property easing won't be lost
+				var anim = Animation( this, jQuery.extend( {}, prop ), optall );
+
+				// Empty animations, or finishing resolves immediately
+				if ( empty || jQuery._data( this, "finish" ) ) {
+					anim.stop( true );
+				}
+			};
+			doAnimation.finish = doAnimation;
+
+		return empty || optall.queue === false ?
+			this.each( doAnimation ) :
+			this.queue( optall.queue, doAnimation );
+	},
+	stop: function( type, clearQueue, gotoEnd ) {
+		var stopQueue = function( hooks ) {
+			var stop = hooks.stop;
+			delete hooks.stop;
+			stop( gotoEnd );
+		};
+
+		if ( typeof type !== "string" ) {
+			gotoEnd = clearQueue;
+			clearQueue = type;
+			type = undefined;
+		}
+		if ( clearQueue && type !== false ) {
+			this.queue( type || "fx", [] );
+		}
+
+		return this.each( function() {
+			var dequeue = true,
+				index = type != null && type + "queueHooks",
+				timers = jQuery.timers,
+				data = jQuery._data( this );
+
+			if ( index ) {
+				if ( data[ index ] && data[ index ].stop ) {
+					stopQueue( data[ index ] );
+				}
+			} else {
+				for ( index in data ) {
+					if ( data[ index ] && data[ index ].stop && rrun.test( index ) ) {
+						stopQueue( data[ index ] );
+					}
+				}
+			}
+
+			for ( index = timers.length; index--; ) {
+				if ( timers[ index ].elem === this &&
+					( type == null || timers[ index ].queue === type ) ) {
+
+					timers[ index ].anim.stop( gotoEnd );
+					dequeue = false;
+					timers.splice( index, 1 );
+				}
+			}
+
+			// start the next in the queue if the last step wasn't forced
+			// timers currently will call their complete callbacks, which will dequeue
+			// but only if they were gotoEnd
+			if ( dequeue || !gotoEnd ) {
+				jQuery.dequeue( this, type );
+			}
+		} );
+	},
+	finish: function( type ) {
+		if ( type !== false ) {
+			type = type || "fx";
+		}
+		return this.each( function() {
+			var index,
+				data = jQuery._data( this ),
+				queue = data[ type + "queue" ],
+				hooks = data[ type + "queueHooks" ],
+				timers = jQuery.timers,
+				length = queue ? queue.length : 0;
+
+			// enable finishing flag on private data
+			data.finish = true;
+
+			// empty the queue first
+			jQuery.queue( this, type, [] );
+
+			if ( hooks && hooks.stop ) {
+				hooks.stop.call( this, true );
+			}
+
+			// look for any active animations, and finish them
+			for ( index = timers.length; index--; ) {
+				if ( timers[ index ].elem === this && timers[ index ].queue === type ) {
+					timers[ index ].anim.stop( true );
+					timers.splice( index, 1 );
+				}
+			}
+
+			// look for any animations in the old queue and finish them
+			for ( index = 0; index < length; index++ ) {
+				if ( queue[ index ] && queue[ index ].finish ) {
+					queue[ index ].finish.call( this );
+				}
+			}
+
+			// turn off finishing flag
+			delete data.finish;
+		} );
+	}
+} );
+
+jQuery.each( [ "toggle", "show", "hide" ], function( i, name ) {
+	var cssFn = jQuery.fn[ name ];
+	jQuery.fn[ name ] = function( speed, easing, callback ) {
+		return speed == null || typeof speed === "boolean" ?
+			cssFn.apply( this, arguments ) :
+			this.animate( genFx( name, true ), speed, easing, callback );
+	};
+} );
+
+// Generate shortcuts for custom animations
+jQuery.each( {
+	slideDown: genFx( "show" ),
+	slideUp: genFx( "hide" ),
+	slideToggle: genFx( "toggle" ),
+	fadeIn: { opacity: "show" },
+	fadeOut: { opacity: "hide" },
+	fadeToggle: { opacity: "toggle" }
+}, function( name, props ) {
+	jQuery.fn[ name ] = function( speed, easing, callback ) {
+		return this.animate( props, speed, easing, callback );
+	};
+} );
+
+jQuery.timers = [];
+jQuery.fx.tick = function() {
+	var timer,
+		timers = jQuery.timers,
+		i = 0;
+
+	fxNow = jQuery.now();
+
+	for ( ; i < timers.length; i++ ) {
+		timer = timers[ i ];
+
+		// Checks the timer has not already been removed
+		if ( !timer() && timers[ i ] === timer ) {
+			timers.splice( i--, 1 );
+		}
+	}
+
+	if ( !timers.length ) {
+		jQuery.fx.stop();
+	}
+	fxNow = undefined;
+};
+
+jQuery.fx.timer = function( timer ) {
+	jQuery.timers.push( timer );
+	if ( timer() ) {
+		jQuery.fx.start();
+	} else {
+		jQuery.timers.pop();
+	}
+};
+
+jQuery.fx.interval = 13;
+
+jQuery.fx.start = function() {
+	if ( !timerId ) {
+		timerId = window.setInterval( jQuery.fx.tick, jQuery.fx.interval );
+	}
+};
+
+jQuery.fx.stop = function() {
+	window.clearInterval( timerId );
+	timerId = null;
+};
+
+jQuery.fx.speeds = {
+	slow: 600,
+	fast: 200,
+
+	// Default speed
+	_default: 400
+};
+
+
+// Based off of the plugin by Clint Helfers, with permission.
+// http://web.archive.org/web/20100324014747/http://blindsignals.com/index.php/2009/07/jquery-delay/
+jQuery.fn.delay = function( time, type ) {
+	time = jQuery.fx ? jQuery.fx.speeds[ time ] || time : time;
+	type = type || "fx";
+
+	return this.queue( type, function( next, hooks ) {
+		var timeout = window.setTimeout( next, time );
+		hooks.stop = function() {
+			window.clearTimeout( timeout );
+		};
+	} );
+};
+
+
+( function() {
+	var a,
+		input = document.createElement( "input" ),
+		div = document.createElement( "div" ),
+		select = document.createElement( "select" ),
+		opt = select.appendChild( document.createElement( "option" ) );
+
+	// Setup
+	div = document.createElement( "div" );
+	div.setAttribute( "className", "t" );
+	div.innerHTML = "  <link/><table></table><a href='/a'>a</a><input type='checkbox'/>";
+	a = div.getElementsByTagName( "a" )[ 0 ];
+
+	// Support: Windows Web Apps (WWA)
+	// `type` must use .setAttribute for WWA (#14901)
+	input.setAttribute( "type", "checkbox" );
+	div.appendChild( input );
+
+	a = div.getElementsByTagName( "a" )[ 0 ];
+
+	// First batch of tests.
+	a.style.cssText = "top:1px";
+
+	// Test setAttribute on camelCase class.
+	// If it works, we need attrFixes when doing get/setAttribute (ie6/7)
+	support.getSetAttribute = div.className !== "t";
+
+	// Get the style information from getAttribute
+	// (IE uses .cssText instead)
+	support.style = /top/.test( a.getAttribute( "style" ) );
+
+	// Make sure that URLs aren't manipulated
+	// (IE normalizes it by default)
+	support.hrefNormalized = a.getAttribute( "href" ) === "/a";
+
+	// Check the default checkbox/radio value ("" on WebKit; "on" elsewhere)
+	support.checkOn = !!input.value;
+
+	// Make sure that a selected-by-default option has a working selected property.
+	// (WebKit defaults to false instead of true, IE too, if it's in an optgroup)
+	support.optSelected = opt.selected;
+
+	// Tests for enctype support on a form (#6743)
+	support.enctype = !!document.createElement( "form" ).enctype;
+
+	// Make sure that the options inside disabled selects aren't marked as disabled
+	// (WebKit marks them as disabled)
+	select.disabled = true;
+	support.optDisabled = !opt.disabled;
+
+	// Support: IE8 only
+	// Check if we can trust getAttribute("value")
+	input = document.createElement( "input" );
+	input.setAttribute( "value", "" );
+	support.input = input.getAttribute( "value" ) === "";
+
+	// Check if an input maintains its value after becoming a radio
+	input.value = "t";
+	input.setAttribute( "type", "radio" );
+	support.radioValue = input.value === "t";
+} )();
+
+
+var rreturn = /\r/g;
+
+jQuery.fn.extend( {
+	val: function( value ) {
+		var hooks, ret, isFunction,
+			elem = this[ 0 ];
+
+		if ( !arguments.length ) {
+			if ( elem ) {
+				hooks = jQuery.valHooks[ elem.type ] ||
+					jQuery.valHooks[ elem.nodeName.toLowerCase() ];
+
+				if (
+					hooks &&
+					"get" in hooks &&
+					( ret = hooks.get( elem, "value" ) ) !== undefined
+				) {
+					return ret;
+				}
+
+				ret = elem.value;
+
+				return typeof ret === "string" ?
+
+					// handle most common string cases
+					ret.replace( rreturn, "" ) :
+
+					// handle cases where value is null/undef or number
+					ret == null ? "" : ret;
+			}
+
+			return;
+		}
+
+		isFunction = jQuery.isFunction( value );
+
+		return this.each( function( i ) {
+			var val;
+
+			if ( this.nodeType !== 1 ) {
+				return;
+			}
+
+			if ( isFunction ) {
+				val = value.call( this, i, jQuery( this ).val() );
+			} else {
+				val = value;
+			}
+
+			// Treat null/undefined as ""; convert numbers to string
+			if ( val == null ) {
+				val = "";
+			} else if ( typeof val === "number" ) {
+				val += "";
+			} else if ( jQuery.isArray( val ) ) {
+				val = jQuery.map( val, function( value ) {
+					return value == null ? "" : value + "";
+				} );
+			}
+
+			hooks = jQuery.valHooks[ this.type ] || jQuery.valHooks[ this.nodeName.toLowerCase() ];
+
+			// If set returns undefined, fall back to normal setting
+			if ( !hooks || !( "set" in hooks ) || hooks.set( this, val, "value" ) === undefined ) {
+				this.value = val;
+			}
+		} );
+	}
+} );
+
+jQuery.extend( {
+	valHooks: {
+		option: {
+			get: function( elem ) {
+				var val = jQuery.find.attr( elem, "value" );
+				return val != null ?
+					val :
+
+					// Support: IE10-11+
+					// option.text throws exceptions (#14686, #14858)
+					jQuery.trim( jQuery.text( elem ) );
+			}
+		},
+		select: {
+			get: function( elem ) {
+				var value, option,
+					options = elem.options,
+					index = elem.selectedIndex,
+					one = elem.type === "select-one" || index < 0,
+					values = one ? null : [],
+					max = one ? index + 1 : options.length,
+					i = index < 0 ?
+						max :
+						one ? index : 0;
+
+				// Loop through all the selected options
+				for ( ; i < max; i++ ) {
+					option = options[ i ];
+
+					// oldIE doesn't update selected after form reset (#2551)
+					if ( ( option.selected || i === index ) &&
+
+							// Don't return options that are disabled or in a disabled optgroup
+							( support.optDisabled ?
+								!option.disabled :
+								option.getAttribute( "disabled" ) === null ) &&
+							( !option.parentNode.disabled ||
+								!jQuery.nodeName( option.parentNode, "optgroup" ) ) ) {
+
+						// Get the specific value for the option
+						value = jQuery( option ).val();
+
+						// We don't need an array for one selects
+						if ( one ) {
+							return value;
+						}
+
+						// Multi-Selects return an array
+						values.push( value );
+					}
+				}
+
+				return values;
+			},
+
+			set: function( elem, value ) {
+				var optionSet, option,
+					options = elem.options,
+					values = jQuery.makeArray( value ),
+					i = options.length;
+
+				while ( i-- ) {
+					option = options[ i ];
+
+					if ( jQuery.inArray( jQuery.valHooks.option.get( option ), values ) >= 0 ) {
+
+						// Support: IE6
+						// When new option element is added to select box we need to
+						// force reflow of newly added node in order to workaround delay
+						// of initialization properties
+						try {
+							option.selected = optionSet = true;
+
+						} catch ( _ ) {
+
+							// Will be executed only in IE6
+							option.scrollHeight;
+						}
+
+					} else {
+						option.selected = false;
+					}
+				}
+
+				// Force browsers to behave consistently when non-matching value is set
+				if ( !optionSet ) {
+					elem.selectedIndex = -1;
+				}
+
+				return options;
+			}
+		}
+	}
+} );
+
+// Radios and checkboxes getter/setter
+jQuery.each( [ "radio", "checkbox" ], function() {
+	jQuery.valHooks[ this ] = {
+		set: function( elem, value ) {
+			if ( jQuery.isArray( value ) ) {
+				return ( elem.checked = jQuery.inArray( jQuery( elem ).val(), value ) > -1 );
+			}
+		}
+	};
+	if ( !support.checkOn ) {
+		jQuery.valHooks[ this ].get = function( elem ) {
+			return elem.getAttribute( "value" ) === null ? "on" : elem.value;
+		};
+	}
+} );
+
+
+
+
+var nodeHook, boolHook,
+	attrHandle = jQuery.expr.attrHandle,
+	ruseDefault = /^(?:checked|selected)$/i,
+	getSetAttribute = support.getSetAttribute,
+	getSetInput = support.input;
+
+jQuery.fn.extend( {
+	attr: function( name, value ) {
+		return access( this, jQuery.attr, name, value, arguments.length > 1 );
+	},
+
+	removeAttr: function( name ) {
+		return this.each( function() {
+			jQuery.removeAttr( this, name );
+		} );
+	}
+} );
+
+jQuery.extend( {
+	attr: function( elem, name, value ) {
+		var ret, hooks,
+			nType = elem.nodeType;
+
+		// Don't get/set attributes on text, comment and attribute nodes
+		if ( nType === 3 || nType === 8 || nType === 2 ) {
+			return;
+		}
+
+		// Fallback to prop when attributes are not supported
+		if ( typeof elem.getAttribute === "undefined" ) {
+			return jQuery.prop( elem, name, value );
+		}
+
+		// All attributes are lowercase
+		// Grab necessary hook if one is defined
+		if ( nType !== 1 || !jQuery.isXMLDoc( elem ) ) {
+			name = name.toLowerCase();
+			hooks = jQuery.attrHooks[ name ] ||
+				( jQuery.expr.match.bool.test( name ) ? boolHook : nodeHook );
+		}
+
+		if ( value !== undefined ) {
+			if ( value === null ) {
+				jQuery.removeAttr( elem, name );
+				return;
+			}
+
+			if ( hooks && "set" in hooks &&
+				( ret = hooks.set( elem, value, name ) ) !== undefined ) {
+				return ret;
+			}
+
+			elem.setAttribute( name, value + "" );
+			return value;
+		}
+
+		if ( hooks && "get" in hooks && ( ret = hooks.get( elem, name ) ) !== null ) {
+			return ret;
+		}
+
+		ret = jQuery.find.attr( elem, name );
+
+		// Non-existent attributes return null, we normalize to undefined
+		return ret == null ? undefined : ret;
+	},
+
+	attrHooks: {
+		type: {
+			set: function( elem, value ) {
+				if ( !support.radioValue && value === "radio" &&
+					jQuery.nodeName( elem, "input" ) ) {
+
+					// Setting the type on a radio button after the value resets the value in IE8-9
+					// Reset value to default in case type is set after value during creation
+					var val = elem.value;
+					elem.setAttribute( "type", value );
+					if ( val ) {
+						elem.value = val;
+					}
+					return value;
+				}
+			}
+		}
+	},
+
+	removeAttr: function( elem, value ) {
+		var name, propName,
+			i = 0,
+			attrNames = value && value.match( rnotwhite );
+
+		if ( attrNames && elem.nodeType === 1 ) {
+			while ( ( name = attrNames[ i++ ] ) ) {
+				propName = jQuery.propFix[ name ] || name;
+
+				// Boolean attributes get special treatment (#10870)
+				if ( jQuery.expr.match.bool.test( name ) ) {
+
+					// Set corresponding property to false
+					if ( getSetInput && getSetAttribute || !ruseDefault.test( name ) ) {
+						elem[ propName ] = false;
+
+					// Support: IE<9
+					// Also clear defaultChecked/defaultSelected (if appropriate)
+					} else {
+						elem[ jQuery.camelCase( "default-" + name ) ] =
+							elem[ propName ] = false;
+					}
+
+				// See #9699 for explanation of this approach (setting first, then removal)
+				} else {
+					jQuery.attr( elem, name, "" );
+				}
+
+				elem.removeAttribute( getSetAttribute ? name : propName );
+			}
+		}
+	}
+} );
+
+// Hooks for boolean attributes
+boolHook = {
+	set: function( elem, value, name ) {
+		if ( value === false ) {
+
+			// Remove boolean attributes when set to false
+			jQuery.removeAttr( elem, name );
+		} else if ( getSetInput && getSetAttribute || !ruseDefault.test( name ) ) {
+
+			// IE<8 needs the *property* name
+			elem.setAttribute( !getSetAttribute && jQuery.propFix[ name ] || name, name );
+
+		} else {
+
+			// Support: IE<9
+			// Use defaultChecked and defaultSelected for oldIE
+			elem[ jQuery.camelCase( "default-" + name ) ] = elem[ name ] = true;
+		}
+		return name;
+	}
+};
+
+jQuery.each( jQuery.expr.match.bool.source.match( /\w+/g ), function( i, name ) {
+	var getter = attrHandle[ name ] || jQuery.find.attr;
+
+	if ( getSetInput && getSetAttribute || !ruseDefault.test( name ) ) {
+		attrHandle[ name ] = function( elem, name, isXML ) {
+			var ret, handle;
+			if ( !isXML ) {
+
+				// Avoid an infinite loop by temporarily removing this function from the getter
+				handle = attrHandle[ name ];
+				attrHandle[ name ] = ret;
+				ret = getter( elem, name, isXML ) != null ?
+					name.toLowerCase() :
+					null;
+				attrHandle[ name ] = handle;
+			}
+			return ret;
+		};
+	} else {
+		attrHandle[ name ] = function( elem, name, isXML ) {
+			if ( !isXML ) {
+				return elem[ jQuery.camelCase( "default-" + name ) ] ?
+					name.toLowerCase() :
+					null;
+			}
+		};
+	}
+} );
+
+// fix oldIE attroperties
+if ( !getSetInput || !getSetAttribute ) {
+	jQuery.attrHooks.value = {
+		set: function( elem, value, name ) {
+			if ( jQuery.nodeName( elem, "input" ) ) {
+
+				// Does not return so that setAttribute is also used
+				elem.defaultValue = value;
+			} else {
+
+				// Use nodeHook if defined (#1954); otherwise setAttribute is fine
+				return nodeHook && nodeHook.set( elem, value, name );
+			}
+		}
+	};
+}
+
+// IE6/7 do not support getting/setting some attributes with get/setAttribute
+if ( !getSetAttribute ) {
+
+	// Use this for any attribute in IE6/7
+	// This fixes almost every IE6/7 issue
+	nodeHook = {
+		set: function( elem, value, name ) {
+
+			// Set the existing or create a new attribute node
+			var ret = elem.getAttributeNode( name );
+			if ( !ret ) {
+				elem.setAttributeNode(
+					( ret = elem.ownerDocument.createAttribute( name ) )
+				);
+			}
+
+			ret.value = value += "";
+
+			// Break association with cloned elements by also using setAttribute (#9646)
+			if ( name === "value" || value === elem.getAttribute( name ) ) {
+				return value;
+			}
+		}
+	};
+
+	// Some attributes are constructed with empty-string values when not defined
+	attrHandle.id = attrHandle.name = attrHandle.coords =
+		function( elem, name, isXML ) {
+			var ret;
+			if ( !isXML ) {
+				return ( ret = elem.getAttributeNode( name ) ) && ret.value !== "" ?
+					ret.value :
+					null;
+			}
+		};
+
+	// Fixing value retrieval on a button requires this module
+	jQuery.valHooks.button = {
+		get: function( elem, name ) {
+			var ret = elem.getAttributeNode( name );
+			if ( ret && ret.specified ) {
+				return ret.value;
+			}
+		},
+		set: nodeHook.set
+	};
+
+	// Set contenteditable to false on removals(#10429)
+	// Setting to empty string throws an error as an invalid value
+	jQuery.attrHooks.contenteditable = {
+		set: function( elem, value, name ) {
+			nodeHook.set( elem, value === "" ? false : value, name );
+		}
+	};
+
+	// Set width and height to auto instead of 0 on empty string( Bug #8150 )
+	// This is for removals
+	jQuery.each( [ "width", "height" ], function( i, name ) {
+		jQuery.attrHooks[ name ] = {
+			set: function( elem, value ) {
+				if ( value === "" ) {
+					elem.setAttribute( name, "auto" );
+					return value;
+				}
+			}
+		};
+	} );
+}
+
+if ( !support.style ) {
+	jQuery.attrHooks.style = {
+		get: function( elem ) {
+
+			// Return undefined in the case of empty string
+			// Note: IE uppercases css property names, but if we were to .toLowerCase()
+			// .cssText, that would destroy case sensitivity in URL's, like in "background"
+			return elem.style.cssText || undefined;
+		},
+		set: function( elem, value ) {
+			return ( elem.style.cssText = value + "" );
+		}
+	};
+}
+
+
+
+
+var rfocusable = /^(?:input|select|textarea|button|object)$/i,
+	rclickable = /^(?:a|area)$/i;
+
+jQuery.fn.extend( {
+	prop: function( name, value ) {
+		return access( this, jQuery.prop, name, value, arguments.length > 1 );
+	},
+
+	removeProp: function( name ) {
+		name = jQuery.propFix[ name ] || name;
+		return this.each( function() {
+
+			// try/catch handles cases where IE balks (such as removing a property on window)
+			try {
+				this[ name ] = undefined;
+				delete this[ name ];
+			} catch ( e ) {}
+		} );
+	}
+} );
+
+jQuery.extend( {
+	prop: function( elem, name, value ) {
+		var ret, hooks,
+			nType = elem.nodeType;
+
+		// Don't get/set properties on text, comment and attribute nodes
+		if ( nType === 3 || nType === 8 || nType === 2 ) {
+			return;
+		}
+
+		if ( nType !== 1 || !jQuery.isXMLDoc( elem ) ) {
+
+			// Fix name and attach hooks
+			name = jQuery.propFix[ name ] || name;
+			hooks = jQuery.propHooks[ name ];
+		}
+
+		if ( value !== undefined ) {
+			if ( hooks && "set" in hooks &&
+				( ret = hooks.set( elem, value, name ) ) !== undefined ) {
+				return ret;
+			}
+
+			return ( elem[ name ] = value );
+		}
+
+		if ( hooks && "get" in hooks && ( ret = hooks.get( elem, name ) ) !== null ) {
+			return ret;
+		}
+
+		return elem[ name ];
+	},
+
+	propHooks: {
+		tabIndex: {
+			get: function( elem ) {
+
+				// elem.tabIndex doesn't always return the
+				// correct value when it hasn't been explicitly set
+				// http://fluidproject.org/blog/2008/01/09/getting-setting-and-removing-tabindex-values-with-javascript/
+				// Use proper attribute retrieval(#12072)
+				var tabindex = jQuery.find.attr( elem, "tabindex" );
+
+				return tabindex ?
+					parseInt( tabindex, 10 ) :
+					rfocusable.test( elem.nodeName ) ||
+						rclickable.test( elem.nodeName ) && elem.href ?
+							0 :
+							-1;
+			}
+		}
+	},
+
+	propFix: {
+		"for": "htmlFor",
+		"class": "className"
+	}
+} );
+
+// Some attributes require a special call on IE
+// http://msdn.microsoft.com/en-us/library/ms536429%28VS.85%29.aspx
+if ( !support.hrefNormalized ) {
+
+	// href/src property should get the full normalized URL (#10299/#12915)
+	jQuery.each( [ "href", "src" ], function( i, name ) {
+		jQuery.propHooks[ name ] = {
+			get: function( elem ) {
+				return elem.getAttribute( name, 4 );
+			}
+		};
+	} );
+}
+
+// Support: Safari, IE9+
+// mis-reports the default selected property of an option
+// Accessing the parent's selectedIndex property fixes it
+if ( !support.optSelected ) {
+	jQuery.propHooks.selected = {
+		get: function( elem ) {
+			var parent = elem.parentNode;
+
+			if ( parent ) {
+				parent.selectedIndex;
+
+				// Make sure that it also works with optgroups, see #5701
+				if ( parent.parentNode ) {
+					parent.parentNode.selectedIndex;
+				}
+			}
+			return null;
+		}
+	};
+}
+
+jQuery.each( [
+	"tabIndex",
+	"readOnly",
+	"maxLength",
+	"cellSpacing",
+	"cellPadding",
+	"rowSpan",
+	"colSpan",
+	"useMap",
+	"frameBorder",
+	"contentEditable"
+], function() {
+	jQuery.propFix[ this.toLowerCase() ] = this;
+} );
+
+// IE6/7 call enctype encoding
+if ( !support.enctype ) {
+	jQuery.propFix.enctype = "encoding";
+}
+
+
+
+
+var rclass = /[\t\r\n\f]/g;
+
+function getClass( elem ) {
+	return jQuery.attr( elem, "class" ) || "";
+}
+
+jQuery.fn.extend( {
+	addClass: function( value ) {
+		var classes, elem, cur, curValue, clazz, j, finalValue,
+			i = 0;
+
+		if ( jQuery.isFunction( value ) ) {
+			return this.each( function( j ) {
+				jQuery( this ).addClass( value.call( this, j, getClass( this ) ) );
+			} );
+		}
+
+		if ( typeof value === "string" && value ) {
+			classes = value.match( rnotwhite ) || [];
+
+			while ( ( elem = this[ i++ ] ) ) {
+				curValue = getClass( elem );
+				cur = elem.nodeType === 1 &&
+					( " " + curValue + " " ).replace( rclass, " " );
+
+				if ( cur ) {
+					j = 0;
+					while ( ( clazz = classes[ j++ ] ) ) {
+						if ( cur.indexOf( " " + clazz + " " ) < 0 ) {
+							cur += clazz + " ";
+						}
+					}
+
+					// only assign if different to avoid unneeded rendering.
+					finalValue = jQuery.trim( cur );
+					if ( curValue !== finalValue ) {
+						jQuery.attr( elem, "class", finalValue );
+					}
+				}
+			}
+		}
+
+		return this;
+	},
+
+	removeClass: function( value ) {
+		var classes, elem, cur, curValue, clazz, j, finalValue,
+			i = 0;
+
+		if ( jQuery.isFunction( value ) ) {
+			return this.each( function( j ) {
+				jQuery( this ).removeClass( value.call( this, j, getClass( this ) ) );
+			} );
+		}
+
+		if ( !arguments.length ) {
+			return this.attr( "class", "" );
+		}
+
+		if ( typeof value === "string" && value ) {
+			classes = value.match( rnotwhite ) || [];
+
+			while ( ( elem = this[ i++ ] ) ) {
+				curValue = getClass( elem );
+
+				// This expression is here for better compressibility (see addClass)
+				cur = elem.nodeType === 1 &&
+					( " " + curValue + " " ).replace( rclass, " " );
+
+				if ( cur ) {
+					j = 0;
+					while ( ( clazz = classes[ j++ ] ) ) {
+
+						// Remove *all* instances
+						while ( cur.indexOf( " " + clazz + " " ) > -1 ) {
+							cur = cur.replace( " " + clazz + " ", " " );
+						}
+					}
+
+					// Only assign if different to avoid unneeded rendering.
+					finalValue = jQuery.trim( cur );
+					if ( curValue !== finalValue ) {
+						jQuery.attr( elem, "class", finalValue );
+					}
+				}
+			}
+		}
+
+		return this;
+	},
+
+	toggleClass: function( value, stateVal ) {
+		var type = typeof value;
+
+		if ( typeof stateVal === "boolean" && type === "string" ) {
+			return stateVal ? this.addClass( value ) : this.removeClass( value );
+		}
+
+		if ( jQuery.isFunction( value ) ) {
+			return this.each( function( i ) {
+				jQuery( this ).toggleClass(
+					value.call( this, i, getClass( this ), stateVal ),
+					stateVal
+				);
+			} );
+		}
+
+		return this.each( function() {
+			var className, i, self, classNames;
+
+			if ( type === "string" ) {
+
+				// Toggle individual class names
+				i = 0;
+				self = jQuery( this );
+				classNames = value.match( rnotwhite ) || [];
+
+				while ( ( className = classNames[ i++ ] ) ) {
+
+					// Check each className given, space separated list
+					if ( self.hasClass( className ) ) {
+						self.removeClass( className );
+					} else {
+						self.addClass( className );
+					}
+				}
+
+			// Toggle whole class name
+			} else if ( value === undefined || type === "boolean" ) {
+				className = getClass( this );
+				if ( className ) {
+
+					// store className if set
+					jQuery._data( this, "__className__", className );
+				}
+
+				// If the element has a class name or if we're passed "false",
+				// then remove the whole classname (if there was one, the above saved it).
+				// Otherwise bring back whatever was previously saved (if anything),
+				// falling back to the empty string if nothing was stored.
+				jQuery.attr( this, "class",
+					className || value === false ?
+					"" :
+					jQuery._data( this, "__className__" ) || ""
+				);
+			}
+		} );
+	},
+
+	hasClass: function( selector ) {
+		var className, elem,
+			i = 0;
+
+		className = " " + selector + " ";
+		while ( ( elem = this[ i++ ] ) ) {
+			if ( elem.nodeType === 1 &&
+				( " " + getClass( elem ) + " " ).replace( rclass, " " )
+					.indexOf( className ) > -1
+			) {
+				return true;
+			}
+		}
+
+		return false;
+	}
+} );
+
+
+
+
+// Return jQuery for attributes-only inclusion
+
+
+jQuery.each( ( "blur focus focusin focusout load resize scroll unload click dblclick " +
+	"mousedown mouseup mousemove mouseover mouseout mouseenter mouseleave " +
+	"change select submit keydown keypress keyup error contextmenu" ).split( " " ),
+	function( i, name ) {
+
+	// Handle event binding
+	jQuery.fn[ name ] = function( data, fn ) {
+		return arguments.length > 0 ?
+			this.on( name, null, data, fn ) :
+			this.trigger( name );
+	};
+} );
+
+jQuery.fn.extend( {
+	hover: function( fnOver, fnOut ) {
+		return this.mouseenter( fnOver ).mouseleave( fnOut || fnOver );
+	}
+} );
+
+
+var location = window.location;
+
+var nonce = jQuery.now();
+
+var rquery = ( /\?/ );
+
+
+
+var rvalidtokens = /(,)|(\[|{)|(}|])|"(?:[^"\\\r\n]|\\["\\\/bfnrt]|\\u[\da-fA-F]{4})*"\s*:?|true|false|null|-?(?!0\d)\d+(?:\.\d+|)(?:[eE][+-]?\d+|)/g;
+
+jQuery.parseJSON = function( data ) {
+
+	// Attempt to parse using the native JSON parser first
+	if ( window.JSON && window.JSON.parse ) {
+
+		// Support: Android 2.3
+		// Workaround failure to string-cast null input
+		return window.JSON.parse( data + "" );
+	}
+
+	var requireNonComma,
+		depth = null,
+		str = jQuery.trim( data + "" );
+
+	// Guard against invalid (and possibly dangerous) input by ensuring that nothing remains
+	// after removing valid tokens
+	return str && !jQuery.trim( str.replace( rvalidtokens, function( token, comma, open, close ) {
+
+		// Force termination if we see a misplaced comma
+		if ( requireNonComma && comma ) {
+			depth = 0;
+		}
+
+		// Perform no more replacements after returning to outermost depth
+		if ( depth === 0 ) {
+			return token;
+		}
+
+		// Commas must not follow "[", "{", or ","
+		requireNonComma = open || comma;
+
+		// Determine new depth
+		// array/object open ("[" or "{"): depth += true - false (increment)
+		// array/object close ("]" or "}"): depth += false - true (decrement)
+		// other cases ("," or primitive): depth += true - true (numeric cast)
+		depth += !close - !open;
+
+		// Remove this token
+		return "";
+	} ) ) ?
+		( Function( "return " + str ) )() :
+		jQuery.error( "Invalid JSON: " + data );
+};
+
+
+// Cross-browser xml parsing
+jQuery.parseXML = function( data ) {
+	var xml, tmp;
+	if ( !data || typeof data !== "string" ) {
+		return null;
+	}
+	try {
+		if ( window.DOMParser ) { // Standard
+			tmp = new window.DOMParser();
+			xml = tmp.parseFromString( data, "text/xml" );
+		} else { // IE
+			xml = new window.ActiveXObject( "Microsoft.XMLDOM" );
+			xml.async = "false";
+			xml.loadXML( data );
+		}
+	} catch ( e ) {
+		xml = undefined;
+	}
+	if ( !xml || !xml.documentElement || xml.getElementsByTagName( "parsererror" ).length ) {
+		jQuery.error( "Invalid XML: " + data );
+	}
+	return xml;
+};
+
+
+var
+	rhash = /#.*$/,
+	rts = /([?&])_=[^&]*/,
+
+	// IE leaves an \r character at EOL
+	rheaders = /^(.*?):[ \t]*([^\r\n]*)\r?$/mg,
+
+	// #7653, #8125, #8152: local protocol detection
+	rlocalProtocol = /^(?:about|app|app-storage|.+-extension|file|res|widget):$/,
+	rnoContent = /^(?:GET|HEAD)$/,
+	rprotocol = /^\/\//,
+	rurl = /^([\w.+-]+:)(?:\/\/(?:[^\/?#]*@|)([^\/?#:]*)(?::(\d+)|)|)/,
+
+	/* Prefilters
+	 * 1) They are useful to introduce custom dataTypes (see ajax/jsonp.js for an example)
+	 * 2) These are called:
+	 *    - BEFORE asking for a transport
+	 *    - AFTER param serialization (s.data is a string if s.processData is true)
+	 * 3) key is the dataType
+	 * 4) the catchall symbol "*" can be used
+	 * 5) execution will start with transport dataType and THEN continue down to "*" if needed
+	 */
+	prefilters = {},
+
+	/* Transports bindings
+	 * 1) key is the dataType
+	 * 2) the catchall symbol "*" can be used
+	 * 3) selection will start with transport dataType and THEN go to "*" if needed
+	 */
+	transports = {},
+
+	// Avoid comment-prolog char sequence (#10098); must appease lint and evade compression
+	allTypes = "*/".concat( "*" ),
+
+	// Document location
+	ajaxLocation = location.href,
+
+	// Segment location into parts
+	ajaxLocParts = rurl.exec( ajaxLocation.toLowerCase() ) || [];
+
+// Base "constructor" for jQuery.ajaxPrefilter and jQuery.ajaxTransport
+function addToPrefiltersOrTransports( structure ) {
+
+	// dataTypeExpression is optional and defaults to "*"
+	return function( dataTypeExpression, func ) {
+
+		if ( typeof dataTypeExpression !== "string" ) {
+			func = dataTypeExpression;
+			dataTypeExpression = "*";
+		}
+
+		var dataType,
+			i = 0,
+			dataTypes = dataTypeExpression.toLowerCase().match( rnotwhite ) || [];
+
+		if ( jQuery.isFunction( func ) ) {
+
+			// For each dataType in the dataTypeExpression
+			while ( ( dataType = dataTypes[ i++ ] ) ) {
+
+				// Prepend if requested
+				if ( dataType.charAt( 0 ) === "+" ) {
+					dataType = dataType.slice( 1 ) || "*";
+					( structure[ dataType ] = structure[ dataType ] || [] ).unshift( func );
+
+				// Otherwise append
+				} else {
+					( structure[ dataType ] = structure[ dataType ] || [] ).push( func );
+				}
+			}
+		}
+	};
+}
+
+// Base inspection function for prefilters and transports
+function inspectPrefiltersOrTransports( structure, options, originalOptions, jqXHR ) {
+
+	var inspected = {},
+		seekingTransport = ( structure === transports );
+
+	function inspect( dataType ) {
+		var selected;
+		inspected[ dataType ] = true;
+		jQuery.each( structure[ dataType ] || [], function( _, prefilterOrFactory ) {
+			var dataTypeOrTransport = prefilterOrFactory( options, originalOptions, jqXHR );
+			if ( typeof dataTypeOrTransport === "string" &&
+				!seekingTransport && !inspected[ dataTypeOrTransport ] ) {
+
+				options.dataTypes.unshift( dataTypeOrTransport );
+				inspect( dataTypeOrTransport );
+				return false;
+			} else if ( seekingTransport ) {
+				return !( selected = dataTypeOrTransport );
+			}
+		} );
+		return selected;
+	}
+
+	return inspect( options.dataTypes[ 0 ] ) || !inspected[ "*" ] && inspect( "*" );
+}
+
+// A special extend for ajax options
+// that takes "flat" options (not to be deep extended)
+// Fixes #9887
+function ajaxExtend( target, src ) {
+	var deep, key,
+		flatOptions = jQuery.ajaxSettings.flatOptions || {};
+
+	for ( key in src ) {
+		if ( src[ key ] !== undefined ) {
+			( flatOptions[ key ] ? target : ( deep || ( deep = {} ) ) )[ key ] = src[ key ];
+		}
+	}
+	if ( deep ) {
+		jQuery.extend( true, target, deep );
+	}
+
+	return target;
+}
+
+/* Handles responses to an ajax request:
+ * - finds the right dataType (mediates between content-type and expected dataType)
+ * - returns the corresponding response
+ */
+function ajaxHandleResponses( s, jqXHR, responses ) {
+	var firstDataType, ct, finalDataType, type,
+		contents = s.contents,
+		dataTypes = s.dataTypes;
+
+	// Remove auto dataType and get content-type in the process
+	while ( dataTypes[ 0 ] === "*" ) {
+		dataTypes.shift();
+		if ( ct === undefined ) {
+			ct = s.mimeType || jqXHR.getResponseHeader( "Content-Type" );
+		}
+	}
+
+	// Check if we're dealing with a known content-type
+	if ( ct ) {
+		for ( type in contents ) {
+			if ( contents[ type ] && contents[ type ].test( ct ) ) {
+				dataTypes.unshift( type );
+				break;
+			}
+		}
+	}
+
+	// Check to see if we have a response for the expected dataType
+	if ( dataTypes[ 0 ] in responses ) {
+		finalDataType = dataTypes[ 0 ];
+	} else {
+
+		// Try convertible dataTypes
+		for ( type in responses ) {
+			if ( !dataTypes[ 0 ] || s.converters[ type + " " + dataTypes[ 0 ] ] ) {
+				finalDataType = type;
+				break;
+			}
+			if ( !firstDataType ) {
+				firstDataType = type;
+			}
+		}
+
+		// Or just use first one
+		finalDataType = finalDataType || firstDataType;
+	}
+
+	// If we found a dataType
+	// We add the dataType to the list if needed
+	// and return the corresponding response
+	if ( finalDataType ) {
+		if ( finalDataType !== dataTypes[ 0 ] ) {
+			dataTypes.unshift( finalDataType );
+		}
+		return responses[ finalDataType ];
+	}
+}
+
+/* Chain conversions given the request and the original response
+ * Also sets the responseXXX fields on the jqXHR instance
+ */
+function ajaxConvert( s, response, jqXHR, isSuccess ) {
+	var conv2, current, conv, tmp, prev,
+		converters = {},
+
+		// Work with a copy of dataTypes in case we need to modify it for conversion
+		dataTypes = s.dataTypes.slice();
+
+	// Create converters map with lowercased keys
+	if ( dataTypes[ 1 ] ) {
+		for ( conv in s.converters ) {
+			converters[ conv.toLowerCase() ] = s.converters[ conv ];
+		}
+	}
+
+	current = dataTypes.shift();
+
+	// Convert to each sequential dataType
+	while ( current ) {
+
+		if ( s.responseFields[ current ] ) {
+			jqXHR[ s.responseFields[ current ] ] = response;
+		}
+
+		// Apply the dataFilter if provided
+		if ( !prev && isSuccess && s.dataFilter ) {
+			response = s.dataFilter( response, s.dataType );
+		}
+
+		prev = current;
+		current = dataTypes.shift();
+
+		if ( current ) {
+
+			// There's only work to do if current dataType is non-auto
+			if ( current === "*" ) {
+
+				current = prev;
+
+			// Convert response if prev dataType is non-auto and differs from current
+			} else if ( prev !== "*" && prev !== current ) {
+
+				// Seek a direct converter
+				conv = converters[ prev + " " + current ] || converters[ "* " + current ];
+
+				// If none found, seek a pair
+				if ( !conv ) {
+					for ( conv2 in converters ) {
+
+						// If conv2 outputs current
+						tmp = conv2.split( " " );
+						if ( tmp[ 1 ] === current ) {
+
+							// If prev can be converted to accepted input
+							conv = converters[ prev + " " + tmp[ 0 ] ] ||
+								converters[ "* " + tmp[ 0 ] ];
+							if ( conv ) {
+
+								// Condense equivalence converters
+								if ( conv === true ) {
+									conv = converters[ conv2 ];
+
+								// Otherwise, insert the intermediate dataType
+								} else if ( converters[ conv2 ] !== true ) {
+									current = tmp[ 0 ];
+									dataTypes.unshift( tmp[ 1 ] );
+								}
+								break;
+							}
+						}
+					}
+				}
+
+				// Apply converter (if not an equivalence)
+				if ( conv !== true ) {
+
+					// Unless errors are allowed to bubble, catch and return them
+					if ( conv && s[ "throws" ] ) { // jscs:ignore requireDotNotation
+						response = conv( response );
+					} else {
+						try {
+							response = conv( response );
+						} catch ( e ) {
+							return {
+								state: "parsererror",
+								error: conv ? e : "No conversion from " + prev + " to " + current
+							};
+						}
+					}
+				}
+			}
+		}
+	}
+
+	return { state: "success", data: response };
+}
+
+jQuery.extend( {
+
+	// Counter for holding the number of active queries
+	active: 0,
+
+	// Last-Modified header cache for next request
+	lastModified: {},
+	etag: {},
+
+	ajaxSettings: {
+		url: ajaxLocation,
+		type: "GET",
+		isLocal: rlocalProtocol.test( ajaxLocParts[ 1 ] ),
+		global: true,
+		processData: true,
+		async: true,
+		contentType: "application/x-www-form-urlencoded; charset=UTF-8",
+		/*
+		timeout: 0,
+		data: null,
+		dataType: null,
+		username: null,
+		password: null,
+		cache: null,
+		throws: false,
+		traditional: false,
+		headers: {},
+		*/
+
+		accepts: {
+			"*": allTypes,
+			text: "text/plain",
+			html: "text/html",
+			xml: "application/xml, text/xml",
+			json: "application/json, text/javascript"
+		},
+
+		contents: {
+			xml: /\bxml\b/,
+			html: /\bhtml/,
+			json: /\bjson\b/
+		},
+
+		responseFields: {
+			xml: "responseXML",
+			text: "responseText",
+			json: "responseJSON"
+		},
+
+		// Data converters
+		// Keys separate source (or catchall "*") and destination types with a single space
+		converters: {
+
+			// Convert anything to text
+			"* text": String,
+
+			// Text to html (true = no transformation)
+			"text html": true,
+
+			// Evaluate text as a json expression
+			"text json": jQuery.parseJSON,
+
+			// Parse text as xml
+			"text xml": jQuery.parseXML
+		},
+
+		// For options that shouldn't be deep extended:
+		// you can add your own custom options here if
+		// and when you create one that shouldn't be
+		// deep extended (see ajaxExtend)
+		flatOptions: {
+			url: true,
+			context: true
+		}
+	},
+
+	// Creates a full fledged settings object into target
+	// with both ajaxSettings and settings fields.
+	// If target is omitted, writes into ajaxSettings.
+	ajaxSetup: function( target, settings ) {
+		return settings ?
+
+			// Building a settings object
+			ajaxExtend( ajaxExtend( target, jQuery.ajaxSettings ), settings ) :
+
+			// Extending ajaxSettings
+			ajaxExtend( jQuery.ajaxSettings, target );
+	},
+
+	ajaxPrefilter: addToPrefiltersOrTransports( prefilters ),
+	ajaxTransport: addToPrefiltersOrTransports( transports ),
+
+	// Main method
+	ajax: function( url, options ) {
+
+		// If url is an object, simulate pre-1.5 signature
+		if ( typeof url === "object" ) {
+			options = url;
+			url = undefined;
+		}
+
+		// Force options to be an object
+		options = options || {};
+
+		var
+
+			// Cross-domain detection vars
+			parts,
+
+			// Loop variable
+			i,
+
+			// URL without anti-cache param
+			cacheURL,
+
+			// Response headers as string
+			responseHeadersString,
+
+			// timeout handle
+			timeoutTimer,
+
+			// To know if global events are to be dispatched
+			fireGlobals,
+
+			transport,
+
+			// Response headers
+			responseHeaders,
+
+			// Create the final options object
+			s = jQuery.ajaxSetup( {}, options ),
+
+			// Callbacks context
+			callbackContext = s.context || s,
+
+			// Context for global events is callbackContext if it is a DOM node or jQuery collection
+			globalEventContext = s.context &&
+				( callbackContext.nodeType || callbackContext.jquery ) ?
+					jQuery( callbackContext ) :
+					jQuery.event,
+
+			// Deferreds
+			deferred = jQuery.Deferred(),
+			completeDeferred = jQuery.Callbacks( "once memory" ),
+
+			// Status-dependent callbacks
+			statusCode = s.statusCode || {},
+
+			// Headers (they are sent all at once)
+			requestHeaders = {},
+			requestHeadersNames = {},
+
+			// The jqXHR state
+			state = 0,
+
+			// Default abort message
+			strAbort = "canceled",
+
+			// Fake xhr
+			jqXHR = {
+				readyState: 0,
+
+				// Builds headers hashtable if needed
+				getResponseHeader: function( key ) {
+					var match;
+					if ( state === 2 ) {
+						if ( !responseHeaders ) {
+							responseHeaders = {};
+							while ( ( match = rheaders.exec( responseHeadersString ) ) ) {
+								responseHeaders[ match[ 1 ].toLowerCase() ] = match[ 2 ];
+							}
+						}
+						match = responseHeaders[ key.toLowerCase() ];
+					}
+					return match == null ? null : match;
+				},
+
+				// Raw string
+				getAllResponseHeaders: function() {
+					return state === 2 ? responseHeadersString : null;
+				},
+
+				// Caches the header
+				setRequestHeader: function( name, value ) {
+					var lname = name.toLowerCase();
+					if ( !state ) {
+						name = requestHeadersNames[ lname ] = requestHeadersNames[ lname ] || name;
+						requestHeaders[ name ] = value;
+					}
+					return this;
+				},
+
+				// Overrides response content-type header
+				overrideMimeType: function( type ) {
+					if ( !state ) {
+						s.mimeType = type;
+					}
+					return this;
+				},
+
+				// Status-dependent callbacks
+				statusCode: function( map ) {
+					var code;
+					if ( map ) {
+						if ( state < 2 ) {
+							for ( code in map ) {
+
+								// Lazy-add the new callback in a way that preserves old ones
+								statusCode[ code ] = [ statusCode[ code ], map[ code ] ];
+							}
+						} else {
+
+							// Execute the appropriate callbacks
+							jqXHR.always( map[ jqXHR.status ] );
+						}
+					}
+					return this;
+				},
+
+				// Cancel the request
+				abort: function( statusText ) {
+					var finalText = statusText || strAbort;
+					if ( transport ) {
+						transport.abort( finalText );
+					}
+					done( 0, finalText );
+					return this;
+				}
+			};
+
+		// Attach deferreds
+		deferred.promise( jqXHR ).complete = completeDeferred.add;
+		jqXHR.success = jqXHR.done;
+		jqXHR.error = jqXHR.fail;
+
+		// Remove hash character (#7531: and string promotion)
+		// Add protocol if not provided (#5866: IE7 issue with protocol-less urls)
+		// Handle falsy url in the settings object (#10093: consistency with old signature)
+		// We also use the url parameter if available
+		s.url = ( ( url || s.url || ajaxLocation ) + "" )
+			.replace( rhash, "" )
+			.replace( rprotocol, ajaxLocParts[ 1 ] + "//" );
+
+		// Alias method option to type as per ticket #12004
+		s.type = options.method || options.type || s.method || s.type;
+
+		// Extract dataTypes list
+		s.dataTypes = jQuery.trim( s.dataType || "*" ).toLowerCase().match( rnotwhite ) || [ "" ];
+
+		// A cross-domain request is in order when we have a protocol:host:port mismatch
+		if ( s.crossDomain == null ) {
+			parts = rurl.exec( s.url.toLowerCase() );
+			s.crossDomain = !!( parts &&
+				( parts[ 1 ] !== ajaxLocParts[ 1 ] || parts[ 2 ] !== ajaxLocParts[ 2 ] ||
+					( parts[ 3 ] || ( parts[ 1 ] === "http:" ? "80" : "443" ) ) !==
+						( ajaxLocParts[ 3 ] || ( ajaxLocParts[ 1 ] === "http:" ? "80" : "443" ) ) )
+			);
+		}
+
+		// Convert data if not already a string
+		if ( s.data && s.processData && typeof s.data !== "string" ) {
+			s.data = jQuery.param( s.data, s.traditional );
+		}
+
+		// Apply prefilters
+		inspectPrefiltersOrTransports( prefilters, s, options, jqXHR );
+
+		// If request was aborted inside a prefilter, stop there
+		if ( state === 2 ) {
+			return jqXHR;
+		}
+
+		// We can fire global events as of now if asked to
+		// Don't fire events if jQuery.event is undefined in an AMD-usage scenario (#15118)
+		fireGlobals = jQuery.event && s.global;
+
+		// Watch for a new set of requests
+		if ( fireGlobals && jQuery.active++ === 0 ) {
+			jQuery.event.trigger( "ajaxStart" );
+		}
+
+		// Uppercase the type
+		s.type = s.type.toUpperCase();
+
+		// Determine if request has content
+		s.hasContent = !rnoContent.test( s.type );
+
+		// Save the URL in case we're toying with the If-Modified-Since
+		// and/or If-None-Match header later on
+		cacheURL = s.url;
+
+		// More options handling for requests with no content
+		if ( !s.hasContent ) {
+
+			// If data is available, append data to url
+			if ( s.data ) {
+				cacheURL = ( s.url += ( rquery.test( cacheURL ) ? "&" : "?" ) + s.data );
+
+				// #9682: remove data so that it's not used in an eventual retry
+				delete s.data;
+			}
+
+			// Add anti-cache in url if needed
+			if ( s.cache === false ) {
+				s.url = rts.test( cacheURL ) ?
+
+					// If there is already a '_' parameter, set its value
+					cacheURL.replace( rts, "$1_=" + nonce++ ) :
+
+					// Otherwise add one to the end
+					cacheURL + ( rquery.test( cacheURL ) ? "&" : "?" ) + "_=" + nonce++;
+			}
+		}
+
+		// Set the If-Modified-Since and/or If-None-Match header, if in ifModified mode.
+		if ( s.ifModified ) {
+			if ( jQuery.lastModified[ cacheURL ] ) {
+				jqXHR.setRequestHeader( "If-Modified-Since", jQuery.lastModified[ cacheURL ] );
+			}
+			if ( jQuery.etag[ cacheURL ] ) {
+				jqXHR.setRequestHeader( "If-None-Match", jQuery.etag[ cacheURL ] );
+			}
+		}
+
+		// Set the correct header, if data is being sent
+		if ( s.data && s.hasContent && s.contentType !== false || options.contentType ) {
+			jqXHR.setRequestHeader( "Content-Type", s.contentType );
+		}
+
+		// Set the Accepts header for the server, depending on the dataType
+		jqXHR.setRequestHeader(
+			"Accept",
+			s.dataTypes[ 0 ] && s.accepts[ s.dataTypes[ 0 ] ] ?
+				s.accepts[ s.dataTypes[ 0 ] ] +
+					( s.dataTypes[ 0 ] !== "*" ? ", " + allTypes + "; q=0.01" : "" ) :
+				s.accepts[ "*" ]
+		);
+
+		// Check for headers option
+		for ( i in s.headers ) {
+			jqXHR.setRequestHeader( i, s.headers[ i ] );
+		}
+
+		// Allow custom headers/mimetypes and early abort
+		if ( s.beforeSend &&
+			( s.beforeSend.call( callbackContext, jqXHR, s ) === false || state === 2 ) ) {
+
+			// Abort if not done already and return
+			return jqXHR.abort();
+		}
+
+		// aborting is no longer a cancellation
+		strAbort = "abort";
+
+		// Install callbacks on deferreds
+		for ( i in { success: 1, error: 1, complete: 1 } ) {
+			jqXHR[ i ]( s[ i ] );
+		}
+
+		// Get transport
+		transport = inspectPrefiltersOrTransports( transports, s, options, jqXHR );
+
+		// If no transport, we auto-abort
+		if ( !transport ) {
+			done( -1, "No Transport" );
+		} else {
+			jqXHR.readyState = 1;
+
+			// Send global event
+			if ( fireGlobals ) {
+				globalEventContext.trigger( "ajaxSend", [ jqXHR, s ] );
+			}
+
+			// If request was aborted inside ajaxSend, stop there
+			if ( state === 2 ) {
+				return jqXHR;
+			}
+
+			// Timeout
+			if ( s.async && s.timeout > 0 ) {
+				timeoutTimer = window.setTimeout( function() {
+					jqXHR.abort( "timeout" );
+				}, s.timeout );
+			}
+
+			try {
+				state = 1;
+				transport.send( requestHeaders, done );
+			} catch ( e ) {
+
+				// Propagate exception as error if not done
+				if ( state < 2 ) {
+					done( -1, e );
+
+				// Simply rethrow otherwise
+				} else {
+					throw e;
+				}
+			}
+		}
+
+		// Callback for when everything is done
+		function done( status, nativeStatusText, responses, headers ) {
+			var isSuccess, success, error, response, modified,
+				statusText = nativeStatusText;
+
+			// Called once
+			if ( state === 2 ) {
+				return;
+			}
+
+			// State is "done" now
+			state = 2;
+
+			// Clear timeout if it exists
+			if ( timeoutTimer ) {
+				window.clearTimeout( timeoutTimer );
+			}
+
+			// Dereference transport for early garbage collection
+			// (no matter how long the jqXHR object will be used)
+			transport = undefined;
+
+			// Cache response headers
+			responseHeadersString = headers || "";
+
+			// Set readyState
+			jqXHR.readyState = status > 0 ? 4 : 0;
+
+			// Determine if successful
+			isSuccess = status >= 200 && status < 300 || status === 304;
+
+			// Get response data
+			if ( responses ) {
+				response = ajaxHandleResponses( s, jqXHR, responses );
+			}
+
+			// Convert no matter what (that way responseXXX fields are always set)
+			response = ajaxConvert( s, response, jqXHR, isSuccess );
+
+			// If successful, handle type chaining
+			if ( isSuccess ) {
+
+				// Set the If-Modified-Since and/or If-None-Match header, if in ifModified mode.
+				if ( s.ifModified ) {
+					modified = jqXHR.getResponseHeader( "Last-Modified" );
+					if ( modified ) {
+						jQuery.lastModified[ cacheURL ] = modified;
+					}
+					modified = jqXHR.getResponseHeader( "etag" );
+					if ( modified ) {
+						jQuery.etag[ cacheURL ] = modified;
+					}
+				}
+
+				// if no content
+				if ( status === 204 || s.type === "HEAD" ) {
+					statusText = "nocontent";
+
+				// if not modified
+				} else if ( status === 304 ) {
+					statusText = "notmodified";
+
+				// If we have data, let's convert it
+				} else {
+					statusText = response.state;
+					success = response.data;
+					error = response.error;
+					isSuccess = !error;
+				}
+			} else {
+
+				// We extract error from statusText
+				// then normalize statusText and status for non-aborts
+				error = statusText;
+				if ( status || !statusText ) {
+					statusText = "error";
+					if ( status < 0 ) {
+						status = 0;
+					}
+				}
+			}
+
+			// Set data for the fake xhr object
+			jqXHR.status = status;
+			jqXHR.statusText = ( nativeStatusText || statusText ) + "";
+
+			// Success/Error
+			if ( isSuccess ) {
+				deferred.resolveWith( callbackContext, [ success, statusText, jqXHR ] );
+			} else {
+				deferred.rejectWith( callbackContext, [ jqXHR, statusText, error ] );
+			}
+
+			// Status-dependent callbacks
+			jqXHR.statusCode( statusCode );
+			statusCode = undefined;
+
+			if ( fireGlobals ) {
+				globalEventContext.trigger( isSuccess ? "ajaxSuccess" : "ajaxError",
+					[ jqXHR, s, isSuccess ? success : error ] );
+			}
+
+			// Complete
+			completeDeferred.fireWith( callbackContext, [ jqXHR, statusText ] );
+
+			if ( fireGlobals ) {
+				globalEventContext.trigger( "ajaxComplete", [ jqXHR, s ] );
+
+				// Handle the global AJAX counter
+				if ( !( --jQuery.active ) ) {
+					jQuery.event.trigger( "ajaxStop" );
+				}
+			}
+		}
+
+		return jqXHR;
+	},
+
+	getJSON: function( url, data, callback ) {
+		return jQuery.get( url, data, callback, "json" );
+	},
+
+	getScript: function( url, callback ) {
+		return jQuery.get( url, undefined, callback, "script" );
+	}
+} );
+
+jQuery.each( [ "get", "post" ], function( i, method ) {
+	jQuery[ method ] = function( url, data, callback, type ) {
+
+		// shift arguments if data argument was omitted
+		if ( jQuery.isFunction( data ) ) {
+			type = type || callback;
+			callback = data;
+			data = undefined;
+		}
+
+		// The url can be an options object (which then must have .url)
+		return jQuery.ajax( jQuery.extend( {
+			url: url,
+			type: method,
+			dataType: type,
+			data: data,
+			success: callback
+		}, jQuery.isPlainObject( url ) && url ) );
+	};
+} );
+
+
+jQuery._evalUrl = function( url ) {
+	return jQuery.ajax( {
+		url: url,
+
+		// Make this explicit, since user can override this through ajaxSetup (#11264)
+		type: "GET",
+		dataType: "script",
+		cache: true,
+		async: false,
+		global: false,
+		"throws": true
+	} );
+};
+
+
+jQuery.fn.extend( {
+	wrapAll: function( html ) {
+		if ( jQuery.isFunction( html ) ) {
+			return this.each( function( i ) {
+				jQuery( this ).wrapAll( html.call( this, i ) );
+			} );
+		}
+
+		if ( this[ 0 ] ) {
+
+			// The elements to wrap the target around
+			var wrap = jQuery( html, this[ 0 ].ownerDocument ).eq( 0 ).clone( true );
+
+			if ( this[ 0 ].parentNode ) {
+				wrap.insertBefore( this[ 0 ] );
+			}
+
+			wrap.map( function() {
+				var elem = this;
+
+				while ( elem.firstChild && elem.firstChild.nodeType === 1 ) {
+					elem = elem.firstChild;
+				}
+
+				return elem;
+			} ).append( this );
+		}
+
+		return this;
+	},
+
+	wrapInner: function( html ) {
+		if ( jQuery.isFunction( html ) ) {
+			return this.each( function( i ) {
+				jQuery( this ).wrapInner( html.call( this, i ) );
+			} );
+		}
+
+		return this.each( function() {
+			var self = jQuery( this ),
+				contents = self.contents();
+
+			if ( contents.length ) {
+				contents.wrapAll( html );
+
+			} else {
+				self.append( html );
+			}
+		} );
+	},
+
+	wrap: function( html ) {
+		var isFunction = jQuery.isFunction( html );
+
+		return this.each( function( i ) {
+			jQuery( this ).wrapAll( isFunction ? html.call( this, i ) : html );
+		} );
+	},
+
+	unwrap: function() {
+		return this.parent().each( function() {
+			if ( !jQuery.nodeName( this, "body" ) ) {
+				jQuery( this ).replaceWith( this.childNodes );
+			}
+		} ).end();
+	}
+} );
+
+
+function getDisplay( elem ) {
+	return elem.style && elem.style.display || jQuery.css( elem, "display" );
+}
+
+function filterHidden( elem ) {
+	while ( elem && elem.nodeType === 1 ) {
+		if ( getDisplay( elem ) === "none" || elem.type === "hidden" ) {
+			return true;
+		}
+		elem = elem.parentNode;
+	}
+	return false;
+}
+
+jQuery.expr.filters.hidden = function( elem ) {
+
+	// Support: Opera <= 12.12
+	// Opera reports offsetWidths and offsetHeights less than zero on some elements
+	return support.reliableHiddenOffsets() ?
+		( elem.offsetWidth <= 0 && elem.offsetHeight <= 0 &&
+			!elem.getClientRects().length ) :
+			filterHidden( elem );
+};
+
+jQuery.expr.filters.visible = function( elem ) {
+	return !jQuery.expr.filters.hidden( elem );
+};
+
+
+
+
+var r20 = /%20/g,
+	rbracket = /\[\]$/,
+	rCRLF = /\r?\n/g,
+	rsubmitterTypes = /^(?:submit|button|image|reset|file)$/i,
+	rsubmittable = /^(?:input|select|textarea|keygen)/i;
+
+function buildParams( prefix, obj, traditional, add ) {
+	var name;
+
+	if ( jQuery.isArray( obj ) ) {
+
+		// Serialize array item.
+		jQuery.each( obj, function( i, v ) {
+			if ( traditional || rbracket.test( prefix ) ) {
+
+				// Treat each array item as a scalar.
+				add( prefix, v );
+
+			} else {
+
+				// Item is non-scalar (array or object), encode its numeric index.
+				buildParams(
+					prefix + "[" + ( typeof v === "object" && v != null ? i : "" ) + "]",
+					v,
+					traditional,
+					add
+				);
+			}
+		} );
+
+	} else if ( !traditional && jQuery.type( obj ) === "object" ) {
+
+		// Serialize object item.
+		for ( name in obj ) {
+			buildParams( prefix + "[" + name + "]", obj[ name ], traditional, add );
+		}
+
+	} else {
+
+		// Serialize scalar item.
+		add( prefix, obj );
+	}
+}
+
+// Serialize an array of form elements or a set of
+// key/values into a query string
+jQuery.param = function( a, traditional ) {
+	var prefix,
+		s = [],
+		add = function( key, value ) {
+
+			// If value is a function, invoke it and return its value
+			value = jQuery.isFunction( value ) ? value() : ( value == null ? "" : value );
+			s[ s.length ] = encodeURIComponent( key ) + "=" + encodeURIComponent( value );
+		};
+
+	// Set traditional to true for jQuery <= 1.3.2 behavior.
+	if ( traditional === undefined ) {
+		traditional = jQuery.ajaxSettings && jQuery.ajaxSettings.traditional;
+	}
+
+	// If an array was passed in, assume that it is an array of form elements.
+	if ( jQuery.isArray( a ) || ( a.jquery && !jQuery.isPlainObject( a ) ) ) {
+
+		// Serialize the form elements
+		jQuery.each( a, function() {
+			add( this.name, this.value );
+		} );
+
+	} else {
+
+		// If traditional, encode the "old" way (the way 1.3.2 or older
+		// did it), otherwise encode params recursively.
+		for ( prefix in a ) {
+			buildParams( prefix, a[ prefix ], traditional, add );
+		}
+	}
+
+	// Return the resulting serialization
+	return s.join( "&" ).replace( r20, "+" );
+};
+
+jQuery.fn.extend( {
+	serialize: function() {
+		return jQuery.param( this.serializeArray() );
+	},
+	serializeArray: function() {
+		return this.map( function() {
+
+			// Can add propHook for "elements" to filter or add form elements
+			var elements = jQuery.prop( this, "elements" );
+			return elements ? jQuery.makeArray( elements ) : this;
+		} )
+		.filter( function() {
+			var type = this.type;
+
+			// Use .is(":disabled") so that fieldset[disabled] works
+			return this.name && !jQuery( this ).is( ":disabled" ) &&
+				rsubmittable.test( this.nodeName ) && !rsubmitterTypes.test( type ) &&
+				( this.checked || !rcheckableType.test( type ) );
+		} )
+		.map( function( i, elem ) {
+			var val = jQuery( this ).val();
+
+			return val == null ?
+				null :
+				jQuery.isArray( val ) ?
+					jQuery.map( val, function( val ) {
+						return { name: elem.name, value: val.replace( rCRLF, "\r\n" ) };
+					} ) :
+					{ name: elem.name, value: val.replace( rCRLF, "\r\n" ) };
+		} ).get();
+	}
+} );
+
+
+// Create the request object
+// (This is still attached to ajaxSettings for backward compatibility)
+jQuery.ajaxSettings.xhr = window.ActiveXObject !== undefined ?
+
+	// Support: IE6-IE8
+	function() {
+
+		// XHR cannot access local files, always use ActiveX for that case
+		if ( this.isLocal ) {
+			return createActiveXHR();
+		}
+
+		// Support: IE 9-11
+		// IE seems to error on cross-domain PATCH requests when ActiveX XHR
+		// is used. In IE 9+ always use the native XHR.
+		// Note: this condition won't catch Edge as it doesn't define
+		// document.documentMode but it also doesn't support ActiveX so it won't
+		// reach this code.
+		if ( document.documentMode > 8 ) {
+			return createStandardXHR();
+		}
+
+		// Support: IE<9
+		// oldIE XHR does not support non-RFC2616 methods (#13240)
+		// See http://msdn.microsoft.com/en-us/library/ie/ms536648(v=vs.85).aspx
+		// and http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9
+		// Although this check for six methods instead of eight
+		// since IE also does not support "trace" and "connect"
+		return /^(get|post|head|put|delete|options)$/i.test( this.type ) &&
+			createStandardXHR() || createActiveXHR();
+	} :
+
+	// For all other browsers, use the standard XMLHttpRequest object
+	createStandardXHR;
+
+var xhrId = 0,
+	xhrCallbacks = {},
+	xhrSupported = jQuery.ajaxSettings.xhr();
+
+// Support: IE<10
+// Open requests must be manually aborted on unload (#5280)
+// See https://support.microsoft.com/kb/2856746 for more info
+if ( window.attachEvent ) {
+	window.attachEvent( "onunload", function() {
+		for ( var key in xhrCallbacks ) {
+			xhrCallbacks[ key ]( undefined, true );
+		}
+	} );
+}
+
+// Determine support properties
+support.cors = !!xhrSupported && ( "withCredentials" in xhrSupported );
+xhrSupported = support.ajax = !!xhrSupported;
+
+// Create transport if the browser can provide an xhr
+if ( xhrSupported ) {
+
+	jQuery.ajaxTransport( function( options ) {
+
+		// Cross domain only allowed if supported through XMLHttpRequest
+		if ( !options.crossDomain || support.cors ) {
+
+			var callback;
+
+			return {
+				send: function( headers, complete ) {
+					var i,
+						xhr = options.xhr(),
+						id = ++xhrId;
+
+					// Open the socket
+					xhr.open(
+						options.type,
+						options.url,
+						options.async,
+						options.username,
+						options.password
+					);
+
+					// Apply custom fields if provided
+					if ( options.xhrFields ) {
+						for ( i in options.xhrFields ) {
+							xhr[ i ] = options.xhrFields[ i ];
+						}
+					}
+
+					// Override mime type if needed
+					if ( options.mimeType && xhr.overrideMimeType ) {
+						xhr.overrideMimeType( options.mimeType );
+					}
+
+					// X-Requested-With header
+					// For cross-domain requests, seeing as conditions for a preflight are
+					// akin to a jigsaw puzzle, we simply never set it to be sure.
+					// (it can always be set on a per-request basis or even using ajaxSetup)
+					// For same-domain requests, won't change header if already provided.
+					if ( !options.crossDomain && !headers[ "X-Requested-With" ] ) {
+						headers[ "X-Requested-With" ] = "XMLHttpRequest";
+					}
+
+					// Set headers
+					for ( i in headers ) {
+
+						// Support: IE<9
+						// IE's ActiveXObject throws a 'Type Mismatch' exception when setting
+						// request header to a null-value.
+						//
+						// To keep consistent with other XHR implementations, cast the value
+						// to string and ignore `undefined`.
+						if ( headers[ i ] !== undefined ) {
+							xhr.setRequestHeader( i, headers[ i ] + "" );
+						}
+					}
+
+					// Do send the request
+					// This may raise an exception which is actually
+					// handled in jQuery.ajax (so no try/catch here)
+					xhr.send( ( options.hasContent && options.data ) || null );
+
+					// Listener
+					callback = function( _, isAbort ) {
+						var status, statusText, responses;
+
+						// Was never called and is aborted or complete
+						if ( callback && ( isAbort || xhr.readyState === 4 ) ) {
+
+							// Clean up
+							delete xhrCallbacks[ id ];
+							callback = undefined;
+							xhr.onreadystatechange = jQuery.noop;
+
+							// Abort manually if needed
+							if ( isAbort ) {
+								if ( xhr.readyState !== 4 ) {
+									xhr.abort();
+								}
+							} else {
+								responses = {};
+								status = xhr.status;
+
+								// Support: IE<10
+								// Accessing binary-data responseText throws an exception
+								// (#11426)
+								if ( typeof xhr.responseText === "string" ) {
+									responses.text = xhr.responseText;
+								}
+
+								// Firefox throws an exception when accessing
+								// statusText for faulty cross-domain requests
+								try {
+									statusText = xhr.statusText;
+								} catch ( e ) {
+
+									// We normalize with Webkit giving an empty statusText
+									statusText = "";
+								}
+
+								// Filter status for non standard behaviors
+
+								// If the request is local and we have data: assume a success
+								// (success with no data won't get notified, that's the best we
+								// can do given current implementations)
+								if ( !status && options.isLocal && !options.crossDomain ) {
+									status = responses.text ? 200 : 404;
+
+								// IE - #1450: sometimes returns 1223 when it should be 204
+								} else if ( status === 1223 ) {
+									status = 204;
+								}
+							}
+						}
+
+						// Call complete if needed
+						if ( responses ) {
+							complete( status, statusText, responses, xhr.getAllResponseHeaders() );
+						}
+					};
+
+					// Do send the request
+					// `xhr.send` may raise an exception, but it will be
+					// handled in jQuery.ajax (so no try/catch here)
+					if ( !options.async ) {
+
+						// If we're in sync mode we fire the callback
+						callback();
+					} else if ( xhr.readyState === 4 ) {
+
+						// (IE6 & IE7) if it's in cache and has been
+						// retrieved directly we need to fire the callback
+						window.setTimeout( callback );
+					} else {
+
+						// Register the callback, but delay it in case `xhr.send` throws
+						// Add to the list of active xhr callbacks
+						xhr.onreadystatechange = xhrCallbacks[ id ] = callback;
+					}
+				},
+
+				abort: function() {
+					if ( callback ) {
+						callback( undefined, true );
+					}
+				}
+			};
+		}
+	} );
+}
+
+// Functions to create xhrs
+function createStandardXHR() {
+	try {
+		return new window.XMLHttpRequest();
+	} catch ( e ) {}
+}
+
+function createActiveXHR() {
+	try {
+		return new window.ActiveXObject( "Microsoft.XMLHTTP" );
+	} catch ( e ) {}
+}
+
+
+
+
+// Prevent auto-execution of scripts when no explicit dataType was provided (See gh-2432)
+jQuery.ajaxPrefilter( function( s ) {
+	if ( s.crossDomain ) {
+		s.contents.script = false;
+	}
+} );
+
+// Install script dataType
+jQuery.ajaxSetup( {
+	accepts: {
+		script: "text/javascript, application/javascript, " +
+			"application/ecmascript, application/x-ecmascript"
+	},
+	contents: {
+		script: /\b(?:java|ecma)script\b/
+	},
+	converters: {
+		"text script": function( text ) {
+			jQuery.globalEval( text );
+			return text;
+		}
+	}
+} );
+
+// Handle cache's special case and global
+jQuery.ajaxPrefilter( "script", function( s ) {
+	if ( s.cache === undefined ) {
+		s.cache = false;
+	}
+	if ( s.crossDomain ) {
+		s.type = "GET";
+		s.global = false;
+	}
+} );
+
+// Bind script tag hack transport
+jQuery.ajaxTransport( "script", function( s ) {
+
+	// This transport only deals with cross domain requests
+	if ( s.crossDomain ) {
+
+		var script,
+			head = document.head || jQuery( "head" )[ 0 ] || document.documentElement;
+
+		return {
+
+			send: function( _, callback ) {
+
+				script = document.createElement( "script" );
+
+				script.async = true;
+
+				if ( s.scriptCharset ) {
+					script.charset = s.scriptCharset;
+				}
+
+				script.src = s.url;
+
+				// Attach handlers for all browsers
+				script.onload = script.onreadystatechange = function( _, isAbort ) {
+
+					if ( isAbort || !script.readyState || /loaded|complete/.test( script.readyState ) ) {
+
+						// Handle memory leak in IE
+						script.onload = script.onreadystatechange = null;
+
+						// Remove the script
+						if ( script.parentNode ) {
+							script.parentNode.removeChild( script );
+						}
+
+						// Dereference the script
+						script = null;
+
+						// Callback if not abort
+						if ( !isAbort ) {
+							callback( 200, "success" );
+						}
+					}
+				};
+
+				// Circumvent IE6 bugs with base elements (#2709 and #4378) by prepending
+				// Use native DOM manipulation to avoid our domManip AJAX trickery
+				head.insertBefore( script, head.firstChild );
+			},
+
+			abort: function() {
+				if ( script ) {
+					script.onload( undefined, true );
+				}
+			}
+		};
+	}
+} );
+
+
+
+
+var oldCallbacks = [],
+	rjsonp = /(=)\?(?=&|$)|\?\?/;
+
+// Default jsonp settings
+jQuery.ajaxSetup( {
+	jsonp: "callback",
+	jsonpCallback: function() {
+		var callback = oldCallbacks.pop() || ( jQuery.expando + "_" + ( nonce++ ) );
+		this[ callback ] = true;
+		return callback;
+	}
+} );
+
+// Detect, normalize options and install callbacks for jsonp requests
+jQuery.ajaxPrefilter( "json jsonp", function( s, originalSettings, jqXHR ) {
+
+	var callbackName, overwritten, responseContainer,
+		jsonProp = s.jsonp !== false && ( rjsonp.test( s.url ) ?
+			"url" :
+			typeof s.data === "string" &&
+				( s.contentType || "" )
+					.indexOf( "application/x-www-form-urlencoded" ) === 0 &&
+				rjsonp.test( s.data ) && "data"
+		);
+
+	// Handle iff the expected data type is "jsonp" or we have a parameter to set
+	if ( jsonProp || s.dataTypes[ 0 ] === "jsonp" ) {
+
+		// Get callback name, remembering preexisting value associated with it
+		callbackName = s.jsonpCallback = jQuery.isFunction( s.jsonpCallback ) ?
+			s.jsonpCallback() :
+			s.jsonpCallback;
+
+		// Insert callback into url or form data
+		if ( jsonProp ) {
+			s[ jsonProp ] = s[ jsonProp ].replace( rjsonp, "$1" + callbackName );
+		} else if ( s.jsonp !== false ) {
+			s.url += ( rquery.test( s.url ) ? "&" : "?" ) + s.jsonp + "=" + callbackName;
+		}
+
+		// Use data converter to retrieve json after script execution
+		s.converters[ "script json" ] = function() {
+			if ( !responseContainer ) {
+				jQuery.error( callbackName + " was not called" );
+			}
+			return responseContainer[ 0 ];
+		};
+
+		// force json dataType
+		s.dataTypes[ 0 ] = "json";
+
+		// Install callback
+		overwritten = window[ callbackName ];
+		window[ callbackName ] = function() {
+			responseContainer = arguments;
+		};
+
+		// Clean-up function (fires after converters)
+		jqXHR.always( function() {
+
+			// If previous value didn't exist - remove it
+			if ( overwritten === undefined ) {
+				jQuery( window ).removeProp( callbackName );
+
+			// Otherwise restore preexisting value
+			} else {
+				window[ callbackName ] = overwritten;
+			}
+
+			// Save back as free
+			if ( s[ callbackName ] ) {
+
+				// make sure that re-using the options doesn't screw things around
+				s.jsonpCallback = originalSettings.jsonpCallback;
+
+				// save the callback name for future use
+				oldCallbacks.push( callbackName );
+			}
+
+			// Call if it was a function and we have a response
+			if ( responseContainer && jQuery.isFunction( overwritten ) ) {
+				overwritten( responseContainer[ 0 ] );
+			}
+
+			responseContainer = overwritten = undefined;
+		} );
+
+		// Delegate to script
+		return "script";
+	}
+} );
+
+
+
+
+// Support: Safari 8+
+// In Safari 8 documents created via document.implementation.createHTMLDocument
+// collapse sibling forms: the second one becomes a child of the first one.
+// Because of that, this security measure has to be disabled in Safari 8.
+// https://bugs.webkit.org/show_bug.cgi?id=137337
+support.createHTMLDocument = ( function() {
+	if ( !document.implementation.createHTMLDocument ) {
+		return false;
+	}
+	var doc = document.implementation.createHTMLDocument( "" );
+	doc.body.innerHTML = "<form></form><form></form>";
+	return doc.body.childNodes.length === 2;
+} )();
+
+
+// data: string of html
+// context (optional): If specified, the fragment will be created in this context,
+// defaults to document
+// keepScripts (optional): If true, will include scripts passed in the html string
+jQuery.parseHTML = function( data, context, keepScripts ) {
+	if ( !data || typeof data !== "string" ) {
+		return null;
+	}
+	if ( typeof context === "boolean" ) {
+		keepScripts = context;
+		context = false;
+	}
+
+	// document.implementation stops scripts or inline event handlers from
+	// being executed immediately
+	context = context || ( support.createHTMLDocument ?
+		document.implementation.createHTMLDocument( "" ) :
+		document );
+
+	var parsed = rsingleTag.exec( data ),
+		scripts = !keepScripts && [];
+
+	// Single tag
+	if ( parsed ) {
+		return [ context.createElement( parsed[ 1 ] ) ];
+	}
+
+	parsed = buildFragment( [ data ], context, scripts );
+
+	if ( scripts && scripts.length ) {
+		jQuery( scripts ).remove();
+	}
+
+	return jQuery.merge( [], parsed.childNodes );
+};
+
+
+// Keep a copy of the old load method
+var _load = jQuery.fn.load;
+
+/**
+ * Load a url into a page
+ */
+jQuery.fn.load = function( url, params, callback ) {
+	if ( typeof url !== "string" && _load ) {
+		return _load.apply( this, arguments );
+	}
+
+	var selector, type, response,
+		self = this,
+		off = url.indexOf( " " );
+
+	if ( off > -1 ) {
+		selector = jQuery.trim( url.slice( off, url.length ) );
+		url = url.slice( 0, off );
+	}
+
+	// If it's a function
+	if ( jQuery.isFunction( params ) ) {
+
+		// We assume that it's the callback
+		callback = params;
+		params = undefined;
+
+	// Otherwise, build a param string
+	} else if ( params && typeof params === "object" ) {
+		type = "POST";
+	}
+
+	// If we have elements to modify, make the request
+	if ( self.length > 0 ) {
+		jQuery.ajax( {
+			url: url,
+
+			// If "type" variable is undefined, then "GET" method will be used.
+			// Make value of this field explicit since
+			// user can override it through ajaxSetup method
+			type: type || "GET",
+			dataType: "html",
+			data: params
+		} ).done( function( responseText ) {
+
+			// Save response for use in complete callback
+			response = arguments;
+
+			self.html( selector ?
+
+				// If a selector was specified, locate the right elements in a dummy div
+				// Exclude scripts to avoid IE 'Permission Denied' errors
+				jQuery( "<div>" ).append( jQuery.parseHTML( responseText ) ).find( selector ) :
+
+				// Otherwise use the full result
+				responseText );
+
+		// If the request succeeds, this function gets "data", "status", "jqXHR"
+		// but they are ignored because response was set above.
+		// If it fails, this function gets "jqXHR", "status", "error"
+		} ).always( callback && function( jqXHR, status ) {
+			self.each( function() {
+				callback.apply( self, response || [ jqXHR.responseText, status, jqXHR ] );
+			} );
+		} );
+	}
+
+	return this;
+};
+
+
+
+
+// Attach a bunch of functions for handling common AJAX events
+jQuery.each( [
+	"ajaxStart",
+	"ajaxStop",
+	"ajaxComplete",
+	"ajaxError",
+	"ajaxSuccess",
+	"ajaxSend"
+], function( i, type ) {
+	jQuery.fn[ type ] = function( fn ) {
+		return this.on( type, fn );
+	};
+} );
+
+
+
+
+jQuery.expr.filters.animated = function( elem ) {
+	return jQuery.grep( jQuery.timers, function( fn ) {
+		return elem === fn.elem;
+	} ).length;
+};
+
+
+
+
+
+/**
+ * Gets a window from an element
+ */
+function getWindow( elem ) {
+	return jQuery.isWindow( elem ) ?
+		elem :
+		elem.nodeType === 9 ?
+			elem.defaultView || elem.parentWindow :
+			false;
+}
+
+jQuery.offset = {
+	setOffset: function( elem, options, i ) {
+		var curPosition, curLeft, curCSSTop, curTop, curOffset, curCSSLeft, calculatePosition,
+			position = jQuery.css( elem, "position" ),
+			curElem = jQuery( elem ),
+			props = {};
+
+		// set position first, in-case top/left are set even on static elem
+		if ( position === "static" ) {
+			elem.style.position = "relative";
+		}
+
+		curOffset = curElem.offset();
+		curCSSTop = jQuery.css( elem, "top" );
+		curCSSLeft = jQuery.css( elem, "left" );
+		calculatePosition = ( position === "absolute" || position === "fixed" ) &&
+			jQuery.inArray( "auto", [ curCSSTop, curCSSLeft ] ) > -1;
+
+		// need to be able to calculate position if either top or left
+		// is auto and position is either absolute or fixed
+		if ( calculatePosition ) {
+			curPosition = curElem.position();
+			curTop = curPosition.top;
+			curLeft = curPosition.left;
+		} else {
+			curTop = parseFloat( curCSSTop ) || 0;
+			curLeft = parseFloat( curCSSLeft ) || 0;
+		}
+
+		if ( jQuery.isFunction( options ) ) {
+
+			// Use jQuery.extend here to allow modification of coordinates argument (gh-1848)
+			options = options.call( elem, i, jQuery.extend( {}, curOffset ) );
+		}
+
+		if ( options.top != null ) {
+			props.top = ( options.top - curOffset.top ) + curTop;
+		}
+		if ( options.left != null ) {
+			props.left = ( options.left - curOffset.left ) + curLeft;
+		}
+
+		if ( "using" in options ) {
+			options.using.call( elem, props );
+		} else {
+			curElem.css( props );
+		}
+	}
+};
+
+jQuery.fn.extend( {
+	offset: function( options ) {
+		if ( arguments.length ) {
+			return options === undefined ?
+				this :
+				this.each( function( i ) {
+					jQuery.offset.setOffset( this, options, i );
+				} );
+		}
+
+		var docElem, win,
+			box = { top: 0, left: 0 },
+			elem = this[ 0 ],
+			doc = elem && elem.ownerDocument;
+
+		if ( !doc ) {
+			return;
+		}
+
+		docElem = doc.documentElement;
+
+		// Make sure it's not a disconnected DOM node
+		if ( !jQuery.contains( docElem, elem ) ) {
+			return box;
+		}
+
+		// If we don't have gBCR, just use 0,0 rather than error
+		// BlackBerry 5, iOS 3 (original iPhone)
+		if ( typeof elem.getBoundingClientRect !== "undefined" ) {
+			box = elem.getBoundingClientRect();
+		}
+		win = getWindow( doc );
+		return {
+			top: box.top  + ( win.pageYOffset || docElem.scrollTop )  - ( docElem.clientTop  || 0 ),
+			left: box.left + ( win.pageXOffset || docElem.scrollLeft ) - ( docElem.clientLeft || 0 )
+		};
+	},
+
+	position: function() {
+		if ( !this[ 0 ] ) {
+			return;
+		}
+
+		var offsetParent, offset,
+			parentOffset = { top: 0, left: 0 },
+			elem = this[ 0 ];
+
+		// Fixed elements are offset from window (parentOffset = {top:0, left: 0},
+		// because it is its only offset parent
+		if ( jQuery.css( elem, "position" ) === "fixed" ) {
+
+			// we assume that getBoundingClientRect is available when computed position is fixed
+			offset = elem.getBoundingClientRect();
+		} else {
+
+			// Get *real* offsetParent
+			offsetParent = this.offsetParent();
+
+			// Get correct offsets
+			offset = this.offset();
+			if ( !jQuery.nodeName( offsetParent[ 0 ], "html" ) ) {
+				parentOffset = offsetParent.offset();
+			}
+
+			// Add offsetParent borders
+			// Subtract offsetParent scroll positions
+			parentOffset.top += jQuery.css( offsetParent[ 0 ], "borderTopWidth", true ) -
+				offsetParent.scrollTop();
+			parentOffset.left += jQuery.css( offsetParent[ 0 ], "borderLeftWidth", true ) -
+				offsetParent.scrollLeft();
+		}
+
+		// Subtract parent offsets and element margins
+		// note: when an element has margin: auto the offsetLeft and marginLeft
+		// are the same in Safari causing offset.left to incorrectly be 0
+		return {
+			top:  offset.top  - parentOffset.top - jQuery.css( elem, "marginTop", true ),
+			left: offset.left - parentOffset.left - jQuery.css( elem, "marginLeft", true )
+		};
+	},
+
+	offsetParent: function() {
+		return this.map( function() {
+			var offsetParent = this.offsetParent;
+
+			while ( offsetParent && ( !jQuery.nodeName( offsetParent, "html" ) &&
+				jQuery.css( offsetParent, "position" ) === "static" ) ) {
+				offsetParent = offsetParent.offsetParent;
+			}
+			return offsetParent || documentElement;
+		} );
+	}
+} );
+
+// Create scrollLeft and scrollTop methods
+jQuery.each( { scrollLeft: "pageXOffset", scrollTop: "pageYOffset" }, function( method, prop ) {
+	var top = /Y/.test( prop );
+
+	jQuery.fn[ method ] = function( val ) {
+		return access( this, function( elem, method, val ) {
+			var win = getWindow( elem );
+
+			if ( val === undefined ) {
+				return win ? ( prop in win ) ? win[ prop ] :
+					win.document.documentElement[ method ] :
+					elem[ method ];
+			}
+
+			if ( win ) {
+				win.scrollTo(
+					!top ? val : jQuery( win ).scrollLeft(),
+					top ? val : jQuery( win ).scrollTop()
+				);
+
+			} else {
+				elem[ method ] = val;
+			}
+		}, method, val, arguments.length, null );
+	};
+} );
+
+// Support: Safari<7-8+, Chrome<37-44+
+// Add the top/left cssHooks using jQuery.fn.position
+// Webkit bug: https://bugs.webkit.org/show_bug.cgi?id=29084
+// getComputedStyle returns percent when specified for top/left/bottom/right
+// rather than make the css module depend on the offset module, we just check for it here
+jQuery.each( [ "top", "left" ], function( i, prop ) {
+	jQuery.cssHooks[ prop ] = addGetHookIf( support.pixelPosition,
+		function( elem, computed ) {
+			if ( computed ) {
+				computed = curCSS( elem, prop );
+
+				// if curCSS returns percentage, fallback to offset
+				return rnumnonpx.test( computed ) ?
+					jQuery( elem ).position()[ prop ] + "px" :
+					computed;
+			}
+		}
+	);
+} );
+
+
+// Create innerHeight, innerWidth, height, width, outerHeight and outerWidth methods
+jQuery.each( { Height: "height", Width: "width" }, function( name, type ) {
+	jQuery.each( { padding: "inner" + name, content: type, "": "outer" + name },
+	function( defaultExtra, funcName ) {
+
+		// margin is only for outerHeight, outerWidth
+		jQuery.fn[ funcName ] = function( margin, value ) {
+			var chainable = arguments.length && ( defaultExtra || typeof margin !== "boolean" ),
+				extra = defaultExtra || ( margin === true || value === true ? "margin" : "border" );
+
+			return access( this, function( elem, type, value ) {
+				var doc;
+
+				if ( jQuery.isWindow( elem ) ) {
+
+					// As of 5/8/2012 this will yield incorrect results for Mobile Safari, but there
+					// isn't a whole lot we can do. See pull request at this URL for discussion:
+					// https://github.com/jquery/jquery/pull/764
+					return elem.document.documentElement[ "client" + name ];
+				}
+
+				// Get document width or height
+				if ( elem.nodeType === 9 ) {
+					doc = elem.documentElement;
+
+					// Either scroll[Width/Height] or offset[Width/Height] or client[Width/Height],
+					// whichever is greatest
+					// unfortunately, this causes bug #3838 in IE6/8 only,
+					// but there is currently no good, small way to fix it.
+					return Math.max(
+						elem.body[ "scroll" + name ], doc[ "scroll" + name ],
+						elem.body[ "offset" + name ], doc[ "offset" + name ],
+						doc[ "client" + name ]
+					);
+				}
+
+				return value === undefined ?
+
+					// Get width or height on the element, requesting but not forcing parseFloat
+					jQuery.css( elem, type, extra ) :
+
+					// Set width or height on the element
+					jQuery.style( elem, type, value, extra );
+			}, type, chainable ? margin : undefined, chainable, null );
+		};
+	} );
+} );
+
+
+jQuery.fn.extend( {
+
+	bind: function( types, data, fn ) {
+		return this.on( types, null, data, fn );
+	},
+	unbind: function( types, fn ) {
+		return this.off( types, null, fn );
+	},
+
+	delegate: function( selector, types, data, fn ) {
+		return this.on( types, selector, data, fn );
+	},
+	undelegate: function( selector, types, fn ) {
+
+		// ( namespace ) or ( selector, types [, fn] )
+		return arguments.length === 1 ?
+			this.off( selector, "**" ) :
+			this.off( types, selector || "**", fn );
+	}
+} );
+
+// The number of elements contained in the matched element set
+jQuery.fn.size = function() {
+	return this.length;
+};
+
+jQuery.fn.andSelf = jQuery.fn.addBack;
+
+
+
+
+// Register as a named AMD module, since jQuery can be concatenated with other
+// files that may use define, but not via a proper concatenation script that
+// understands anonymous AMD modules. A named AMD is safest and most robust
+// way to register. Lowercase jquery is used because AMD module names are
+// derived from file names, and jQuery is normally delivered in a lowercase
+// file name. Do this after creating the global so that if an AMD module wants
+// to call noConflict to hide this version of jQuery, it will work.
+
+// Note that for maximum portability, libraries that are not jQuery should
+// declare themselves as anonymous modules, and avoid setting a global if an
+// AMD loader is present. jQuery is a special case. For more information, see
+// https://github.com/jrburke/requirejs/wiki/Updating-existing-libraries#wiki-anon
+
+if ( typeof define === "function" && define.amd ) {
+	define( "jquery", [], function() {
+		return jQuery;
+	} );
+}
+
+
+
+var
+
+	// Map over jQuery in case of overwrite
+	_jQuery = window.jQuery,
+
+	// Map over the $ in case of overwrite
+	_$ = window.$;
+
+jQuery.noConflict = function( deep ) {
+	if ( window.$ === jQuery ) {
+		window.$ = _$;
+	}
+
+	if ( deep && window.jQuery === jQuery ) {
+		window.jQuery = _jQuery;
+	}
+
+	return jQuery;
+};
+
+// Expose jQuery and $ identifiers, even in
+// AMD (#7102#comment:10, https://github.com/jquery/jquery/pull/557)
+// and CommonJS for browser emulators (#13566)
+if ( !noGlobal ) {
+	window.jQuery = window.$ = jQuery;
+}
+
+return jQuery;
+}));
diff --git js/lib/jquery/jquery-1.12.0.min.js js/lib/jquery/jquery-1.12.0.min.js
new file mode 100644
index 0000000..6c60672
--- /dev/null
+++ js/lib/jquery/jquery-1.12.0.min.js
@@ -0,0 +1,5 @@
+/*! jQuery v1.12.0 | (c) jQuery Foundation | jquery.org/license */
+!function(a,b){"object"==typeof module&&"object"==typeof module.exports?module.exports=a.document?b(a,!0):function(a){if(!a.document)throw new Error("jQuery requires a window with a document");return b(a)}:b(a)}("undefined"!=typeof window?window:this,function(a,b){var c=[],d=a.document,e=c.slice,f=c.concat,g=c.push,h=c.indexOf,i={},j=i.toString,k=i.hasOwnProperty,l={},m="1.12.0",n=function(a,b){return new n.fn.init(a,b)},o=/^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g,p=/^-ms-/,q=/-([\da-z])/gi,r=function(a,b){return b.toUpperCase()};n.fn=n.prototype={jquery:m,constructor:n,selector:"",length:0,toArray:function(){return e.call(this)},get:function(a){return null!=a?0>a?this[a+this.length]:this[a]:e.call(this)},pushStack:function(a){var b=n.merge(this.constructor(),a);return b.prevObject=this,b.context=this.context,b},each:function(a){return n.each(this,a)},map:function(a){return this.pushStack(n.map(this,function(b,c){return a.call(b,c,b)}))},slice:function(){return this.pushStack(e.apply(this,arguments))},first:function(){return this.eq(0)},last:function(){return this.eq(-1)},eq:function(a){var b=this.length,c=+a+(0>a?b:0);return this.pushStack(c>=0&&b>c?[this[c]]:[])},end:function(){return this.prevObject||this.constructor()},push:g,sort:c.sort,splice:c.splice},n.extend=n.fn.extend=function(){var a,b,c,d,e,f,g=arguments[0]||{},h=1,i=arguments.length,j=!1;for("boolean"==typeof g&&(j=g,g=arguments[h]||{},h++),"object"==typeof g||n.isFunction(g)||(g={}),h===i&&(g=this,h--);i>h;h++)if(null!=(e=arguments[h]))for(d in e)a=g[d],c=e[d],g!==c&&(j&&c&&(n.isPlainObject(c)||(b=n.isArray(c)))?(b?(b=!1,f=a&&n.isArray(a)?a:[]):f=a&&n.isPlainObject(a)?a:{},g[d]=n.extend(j,f,c)):void 0!==c&&(g[d]=c));return g},n.extend({expando:"jQuery"+(m+Math.random()).replace(/\D/g,""),isReady:!0,error:function(a){throw new Error(a)},noop:function(){},isFunction:function(a){return"function"===n.type(a)},isArray:Array.isArray||function(a){return"array"===n.type(a)},isWindow:function(a){return null!=a&&a==a.window},isNumeric:function(a){var b=a&&a.toString();return!n.isArray(a)&&b-parseFloat(b)+1>=0},isEmptyObject:function(a){var b;for(b in a)return!1;return!0},isPlainObject:function(a){var b;if(!a||"object"!==n.type(a)||a.nodeType||n.isWindow(a))return!1;try{if(a.constructor&&!k.call(a,"constructor")&&!k.call(a.constructor.prototype,"isPrototypeOf"))return!1}catch(c){return!1}if(!l.ownFirst)for(b in a)return k.call(a,b);for(b in a);return void 0===b||k.call(a,b)},type:function(a){return null==a?a+"":"object"==typeof a||"function"==typeof a?i[j.call(a)]||"object":typeof a},globalEval:function(b){b&&n.trim(b)&&(a.execScript||function(b){a.eval.call(a,b)})(b)},camelCase:function(a){return a.replace(p,"ms-").replace(q,r)},nodeName:function(a,b){return a.nodeName&&a.nodeName.toLowerCase()===b.toLowerCase()},each:function(a,b){var c,d=0;if(s(a)){for(c=a.length;c>d;d++)if(b.call(a[d],d,a[d])===!1)break}else for(d in a)if(b.call(a[d],d,a[d])===!1)break;return a},trim:function(a){return null==a?"":(a+"").replace(o,"")},makeArray:function(a,b){var c=b||[];return null!=a&&(s(Object(a))?n.merge(c,"string"==typeof a?[a]:a):g.call(c,a)),c},inArray:function(a,b,c){var d;if(b){if(h)return h.call(b,a,c);for(d=b.length,c=c?0>c?Math.max(0,d+c):c:0;d>c;c++)if(c in b&&b[c]===a)return c}return-1},merge:function(a,b){var c=+b.length,d=0,e=a.length;while(c>d)a[e++]=b[d++];if(c!==c)while(void 0!==b[d])a[e++]=b[d++];return a.length=e,a},grep:function(a,b,c){for(var d,e=[],f=0,g=a.length,h=!c;g>f;f++)d=!b(a[f],f),d!==h&&e.push(a[f]);return e},map:function(a,b,c){var d,e,g=0,h=[];if(s(a))for(d=a.length;d>g;g++)e=b(a[g],g,c),null!=e&&h.push(e);else for(g in a)e=b(a[g],g,c),null!=e&&h.push(e);return f.apply([],h)},guid:1,proxy:function(a,b){var c,d,f;return"string"==typeof b&&(f=a[b],b=a,a=f),n.isFunction(a)?(c=e.call(arguments,2),d=function(){return a.apply(b||this,c.concat(e.call(arguments)))},d.guid=a.guid=a.guid||n.guid++,d):void 0},now:function(){return+new Date},support:l}),"function"==typeof Symbol&&(n.fn[Symbol.iterator]=c[Symbol.iterator]),n.each("Boolean Number String Function Array Date RegExp Object Error Symbol".split(" "),function(a,b){i["[object "+b+"]"]=b.toLowerCase()});function s(a){var b=!!a&&"length"in a&&a.length,c=n.type(a);return"function"===c||n.isWindow(a)?!1:"array"===c||0===b||"number"==typeof b&&b>0&&b-1 in a}var t=function(a){var b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u="sizzle"+1*new Date,v=a.document,w=0,x=0,y=ga(),z=ga(),A=ga(),B=function(a,b){return a===b&&(l=!0),0},C=1<<31,D={}.hasOwnProperty,E=[],F=E.pop,G=E.push,H=E.push,I=E.slice,J=function(a,b){for(var c=0,d=a.length;d>c;c++)if(a[c]===b)return c;return-1},K="checked|selected|async|autofocus|autoplay|controls|defer|disabled|hidden|ismap|loop|multiple|open|readonly|required|scoped",L="[\\x20\\t\\r\\n\\f]",M="(?:\\\\.|[\\w-]|[^\\x00-\\xa0])+",N="\\["+L+"*("+M+")(?:"+L+"*([*^$|!~]?=)"+L+"*(?:'((?:\\\\.|[^\\\\'])*)'|\"((?:\\\\.|[^\\\\\"])*)\"|("+M+"))|)"+L+"*\\]",O=":("+M+")(?:\\((('((?:\\\\.|[^\\\\'])*)'|\"((?:\\\\.|[^\\\\\"])*)\")|((?:\\\\.|[^\\\\()[\\]]|"+N+")*)|.*)\\)|)",P=new RegExp(L+"+","g"),Q=new RegExp("^"+L+"+|((?:^|[^\\\\])(?:\\\\.)*)"+L+"+$","g"),R=new RegExp("^"+L+"*,"+L+"*"),S=new RegExp("^"+L+"*([>+~]|"+L+")"+L+"*"),T=new RegExp("="+L+"*([^\\]'\"]*?)"+L+"*\\]","g"),U=new RegExp(O),V=new RegExp("^"+M+"$"),W={ID:new RegExp("^#("+M+")"),CLASS:new RegExp("^\\.("+M+")"),TAG:new RegExp("^("+M+"|[*])"),ATTR:new RegExp("^"+N),PSEUDO:new RegExp("^"+O),CHILD:new RegExp("^:(only|first|last|nth|nth-last)-(child|of-type)(?:\\("+L+"*(even|odd|(([+-]|)(\\d*)n|)"+L+"*(?:([+-]|)"+L+"*(\\d+)|))"+L+"*\\)|)","i"),bool:new RegExp("^(?:"+K+")$","i"),needsContext:new RegExp("^"+L+"*[>+~]|:(even|odd|eq|gt|lt|nth|first|last)(?:\\("+L+"*((?:-\\d)?\\d*)"+L+"*\\)|)(?=[^-]|$)","i")},X=/^(?:input|select|textarea|button)$/i,Y=/^h\d$/i,Z=/^[^{]+\{\s*\[native \w/,$=/^(?:#([\w-]+)|(\w+)|\.([\w-]+))$/,_=/[+~]/,aa=/'|\\/g,ba=new RegExp("\\\\([\\da-f]{1,6}"+L+"?|("+L+")|.)","ig"),ca=function(a,b,c){var d="0x"+b-65536;return d!==d||c?b:0>d?String.fromCharCode(d+65536):String.fromCharCode(d>>10|55296,1023&d|56320)},da=function(){m()};try{H.apply(E=I.call(v.childNodes),v.childNodes),E[v.childNodes.length].nodeType}catch(ea){H={apply:E.length?function(a,b){G.apply(a,I.call(b))}:function(a,b){var c=a.length,d=0;while(a[c++]=b[d++]);a.length=c-1}}}function fa(a,b,d,e){var f,h,j,k,l,o,r,s,w=b&&b.ownerDocument,x=b?b.nodeType:9;if(d=d||[],"string"!=typeof a||!a||1!==x&&9!==x&&11!==x)return d;if(!e&&((b?b.ownerDocument||b:v)!==n&&m(b),b=b||n,p)){if(11!==x&&(o=$.exec(a)))if(f=o[1]){if(9===x){if(!(j=b.getElementById(f)))return d;if(j.id===f)return d.push(j),d}else if(w&&(j=w.getElementById(f))&&t(b,j)&&j.id===f)return d.push(j),d}else{if(o[2])return H.apply(d,b.getElementsByTagName(a)),d;if((f=o[3])&&c.getElementsByClassName&&b.getElementsByClassName)return H.apply(d,b.getElementsByClassName(f)),d}if(c.qsa&&!A[a+" "]&&(!q||!q.test(a))){if(1!==x)w=b,s=a;else if("object"!==b.nodeName.toLowerCase()){(k=b.getAttribute("id"))?k=k.replace(aa,"\\$&"):b.setAttribute("id",k=u),r=g(a),h=r.length,l=V.test(k)?"#"+k:"[id='"+k+"']";while(h--)r[h]=l+" "+qa(r[h]);s=r.join(","),w=_.test(a)&&oa(b.parentNode)||b}if(s)try{return H.apply(d,w.querySelectorAll(s)),d}catch(y){}finally{k===u&&b.removeAttribute("id")}}}return i(a.replace(Q,"$1"),b,d,e)}function ga(){var a=[];function b(c,e){return a.push(c+" ")>d.cacheLength&&delete b[a.shift()],b[c+" "]=e}return b}function ha(a){return a[u]=!0,a}function ia(a){var b=n.createElement("div");try{return!!a(b)}catch(c){return!1}finally{b.parentNode&&b.parentNode.removeChild(b),b=null}}function ja(a,b){var c=a.split("|"),e=c.length;while(e--)d.attrHandle[c[e]]=b}function ka(a,b){var c=b&&a,d=c&&1===a.nodeType&&1===b.nodeType&&(~b.sourceIndex||C)-(~a.sourceIndex||C);if(d)return d;if(c)while(c=c.nextSibling)if(c===b)return-1;return a?1:-1}function la(a){return function(b){var c=b.nodeName.toLowerCase();return"input"===c&&b.type===a}}function ma(a){return function(b){var c=b.nodeName.toLowerCase();return("input"===c||"button"===c)&&b.type===a}}function na(a){return ha(function(b){return b=+b,ha(function(c,d){var e,f=a([],c.length,b),g=f.length;while(g--)c[e=f[g]]&&(c[e]=!(d[e]=c[e]))})})}function oa(a){return a&&"undefined"!=typeof a.getElementsByTagName&&a}c=fa.support={},f=fa.isXML=function(a){var b=a&&(a.ownerDocument||a).documentElement;return b?"HTML"!==b.nodeName:!1},m=fa.setDocument=function(a){var b,e,g=a?a.ownerDocument||a:v;return g!==n&&9===g.nodeType&&g.documentElement?(n=g,o=n.documentElement,p=!f(n),(e=n.defaultView)&&e.top!==e&&(e.addEventListener?e.addEventListener("unload",da,!1):e.attachEvent&&e.attachEvent("onunload",da)),c.attributes=ia(function(a){return a.className="i",!a.getAttribute("className")}),c.getElementsByTagName=ia(function(a){return a.appendChild(n.createComment("")),!a.getElementsByTagName("*").length}),c.getElementsByClassName=Z.test(n.getElementsByClassName),c.getById=ia(function(a){return o.appendChild(a).id=u,!n.getElementsByName||!n.getElementsByName(u).length}),c.getById?(d.find.ID=function(a,b){if("undefined"!=typeof b.getElementById&&p){var c=b.getElementById(a);return c?[c]:[]}},d.filter.ID=function(a){var b=a.replace(ba,ca);return function(a){return a.getAttribute("id")===b}}):(delete d.find.ID,d.filter.ID=function(a){var b=a.replace(ba,ca);return function(a){var c="undefined"!=typeof a.getAttributeNode&&a.getAttributeNode("id");return c&&c.value===b}}),d.find.TAG=c.getElementsByTagName?function(a,b){return"undefined"!=typeof b.getElementsByTagName?b.getElementsByTagName(a):c.qsa?b.querySelectorAll(a):void 0}:function(a,b){var c,d=[],e=0,f=b.getElementsByTagName(a);if("*"===a){while(c=f[e++])1===c.nodeType&&d.push(c);return d}return f},d.find.CLASS=c.getElementsByClassName&&function(a,b){return"undefined"!=typeof b.getElementsByClassName&&p?b.getElementsByClassName(a):void 0},r=[],q=[],(c.qsa=Z.test(n.querySelectorAll))&&(ia(function(a){o.appendChild(a).innerHTML="<a id='"+u+"'></a><select id='"+u+"-\r\\' msallowcapture=''><option selected=''></option></select>",a.querySelectorAll("[msallowcapture^='']").length&&q.push("[*^$]="+L+"*(?:''|\"\")"),a.querySelectorAll("[selected]").length||q.push("\\["+L+"*(?:value|"+K+")"),a.querySelectorAll("[id~="+u+"-]").length||q.push("~="),a.querySelectorAll(":checked").length||q.push(":checked"),a.querySelectorAll("a#"+u+"+*").length||q.push(".#.+[+~]")}),ia(function(a){var b=n.createElement("input");b.setAttribute("type","hidden"),a.appendChild(b).setAttribute("name","D"),a.querySelectorAll("[name=d]").length&&q.push("name"+L+"*[*^$|!~]?="),a.querySelectorAll(":enabled").length||q.push(":enabled",":disabled"),a.querySelectorAll("*,:x"),q.push(",.*:")})),(c.matchesSelector=Z.test(s=o.matches||o.webkitMatchesSelector||o.mozMatchesSelector||o.oMatchesSelector||o.msMatchesSelector))&&ia(function(a){c.disconnectedMatch=s.call(a,"div"),s.call(a,"[s!='']:x"),r.push("!=",O)}),q=q.length&&new RegExp(q.join("|")),r=r.length&&new RegExp(r.join("|")),b=Z.test(o.compareDocumentPosition),t=b||Z.test(o.contains)?function(a,b){var c=9===a.nodeType?a.documentElement:a,d=b&&b.parentNode;return a===d||!(!d||1!==d.nodeType||!(c.contains?c.contains(d):a.compareDocumentPosition&&16&a.compareDocumentPosition(d)))}:function(a,b){if(b)while(b=b.parentNode)if(b===a)return!0;return!1},B=b?function(a,b){if(a===b)return l=!0,0;var d=!a.compareDocumentPosition-!b.compareDocumentPosition;return d?d:(d=(a.ownerDocument||a)===(b.ownerDocument||b)?a.compareDocumentPosition(b):1,1&d||!c.sortDetached&&b.compareDocumentPosition(a)===d?a===n||a.ownerDocument===v&&t(v,a)?-1:b===n||b.ownerDocument===v&&t(v,b)?1:k?J(k,a)-J(k,b):0:4&d?-1:1)}:function(a,b){if(a===b)return l=!0,0;var c,d=0,e=a.parentNode,f=b.parentNode,g=[a],h=[b];if(!e||!f)return a===n?-1:b===n?1:e?-1:f?1:k?J(k,a)-J(k,b):0;if(e===f)return ka(a,b);c=a;while(c=c.parentNode)g.unshift(c);c=b;while(c=c.parentNode)h.unshift(c);while(g[d]===h[d])d++;return d?ka(g[d],h[d]):g[d]===v?-1:h[d]===v?1:0},n):n},fa.matches=function(a,b){return fa(a,null,null,b)},fa.matchesSelector=function(a,b){if((a.ownerDocument||a)!==n&&m(a),b=b.replace(T,"='$1']"),c.matchesSelector&&p&&!A[b+" "]&&(!r||!r.test(b))&&(!q||!q.test(b)))try{var d=s.call(a,b);if(d||c.disconnectedMatch||a.document&&11!==a.document.nodeType)return d}catch(e){}return fa(b,n,null,[a]).length>0},fa.contains=function(a,b){return(a.ownerDocument||a)!==n&&m(a),t(a,b)},fa.attr=function(a,b){(a.ownerDocument||a)!==n&&m(a);var e=d.attrHandle[b.toLowerCase()],f=e&&D.call(d.attrHandle,b.toLowerCase())?e(a,b,!p):void 0;return void 0!==f?f:c.attributes||!p?a.getAttribute(b):(f=a.getAttributeNode(b))&&f.specified?f.value:null},fa.error=function(a){throw new Error("Syntax error, unrecognized expression: "+a)},fa.uniqueSort=function(a){var b,d=[],e=0,f=0;if(l=!c.detectDuplicates,k=!c.sortStable&&a.slice(0),a.sort(B),l){while(b=a[f++])b===a[f]&&(e=d.push(f));while(e--)a.splice(d[e],1)}return k=null,a},e=fa.getText=function(a){var b,c="",d=0,f=a.nodeType;if(f){if(1===f||9===f||11===f){if("string"==typeof a.textContent)return a.textContent;for(a=a.firstChild;a;a=a.nextSibling)c+=e(a)}else if(3===f||4===f)return a.nodeValue}else while(b=a[d++])c+=e(b);return c},d=fa.selectors={cacheLength:50,createPseudo:ha,match:W,attrHandle:{},find:{},relative:{">":{dir:"parentNode",first:!0}," ":{dir:"parentNode"},"+":{dir:"previousSibling",first:!0},"~":{dir:"previousSibling"}},preFilter:{ATTR:function(a){return a[1]=a[1].replace(ba,ca),a[3]=(a[3]||a[4]||a[5]||"").replace(ba,ca),"~="===a[2]&&(a[3]=" "+a[3]+" "),a.slice(0,4)},CHILD:function(a){return a[1]=a[1].toLowerCase(),"nth"===a[1].slice(0,3)?(a[3]||fa.error(a[0]),a[4]=+(a[4]?a[5]+(a[6]||1):2*("even"===a[3]||"odd"===a[3])),a[5]=+(a[7]+a[8]||"odd"===a[3])):a[3]&&fa.error(a[0]),a},PSEUDO:function(a){var b,c=!a[6]&&a[2];return W.CHILD.test(a[0])?null:(a[3]?a[2]=a[4]||a[5]||"":c&&U.test(c)&&(b=g(c,!0))&&(b=c.indexOf(")",c.length-b)-c.length)&&(a[0]=a[0].slice(0,b),a[2]=c.slice(0,b)),a.slice(0,3))}},filter:{TAG:function(a){var b=a.replace(ba,ca).toLowerCase();return"*"===a?function(){return!0}:function(a){return a.nodeName&&a.nodeName.toLowerCase()===b}},CLASS:function(a){var b=y[a+" "];return b||(b=new RegExp("(^|"+L+")"+a+"("+L+"|$)"))&&y(a,function(a){return b.test("string"==typeof a.className&&a.className||"undefined"!=typeof a.getAttribute&&a.getAttribute("class")||"")})},ATTR:function(a,b,c){return function(d){var e=fa.attr(d,a);return null==e?"!="===b:b?(e+="","="===b?e===c:"!="===b?e!==c:"^="===b?c&&0===e.indexOf(c):"*="===b?c&&e.indexOf(c)>-1:"$="===b?c&&e.slice(-c.length)===c:"~="===b?(" "+e.replace(P," ")+" ").indexOf(c)>-1:"|="===b?e===c||e.slice(0,c.length+1)===c+"-":!1):!0}},CHILD:function(a,b,c,d,e){var f="nth"!==a.slice(0,3),g="last"!==a.slice(-4),h="of-type"===b;return 1===d&&0===e?function(a){return!!a.parentNode}:function(b,c,i){var j,k,l,m,n,o,p=f!==g?"nextSibling":"previousSibling",q=b.parentNode,r=h&&b.nodeName.toLowerCase(),s=!i&&!h,t=!1;if(q){if(f){while(p){m=b;while(m=m[p])if(h?m.nodeName.toLowerCase()===r:1===m.nodeType)return!1;o=p="only"===a&&!o&&"nextSibling"}return!0}if(o=[g?q.firstChild:q.lastChild],g&&s){m=q,l=m[u]||(m[u]={}),k=l[m.uniqueID]||(l[m.uniqueID]={}),j=k[a]||[],n=j[0]===w&&j[1],t=n&&j[2],m=n&&q.childNodes[n];while(m=++n&&m&&m[p]||(t=n=0)||o.pop())if(1===m.nodeType&&++t&&m===b){k[a]=[w,n,t];break}}else if(s&&(m=b,l=m[u]||(m[u]={}),k=l[m.uniqueID]||(l[m.uniqueID]={}),j=k[a]||[],n=j[0]===w&&j[1],t=n),t===!1)while(m=++n&&m&&m[p]||(t=n=0)||o.pop())if((h?m.nodeName.toLowerCase()===r:1===m.nodeType)&&++t&&(s&&(l=m[u]||(m[u]={}),k=l[m.uniqueID]||(l[m.uniqueID]={}),k[a]=[w,t]),m===b))break;return t-=e,t===d||t%d===0&&t/d>=0}}},PSEUDO:function(a,b){var c,e=d.pseudos[a]||d.setFilters[a.toLowerCase()]||fa.error("unsupported pseudo: "+a);return e[u]?e(b):e.length>1?(c=[a,a,"",b],d.setFilters.hasOwnProperty(a.toLowerCase())?ha(function(a,c){var d,f=e(a,b),g=f.length;while(g--)d=J(a,f[g]),a[d]=!(c[d]=f[g])}):function(a){return e(a,0,c)}):e}},pseudos:{not:ha(function(a){var b=[],c=[],d=h(a.replace(Q,"$1"));return d[u]?ha(function(a,b,c,e){var f,g=d(a,null,e,[]),h=a.length;while(h--)(f=g[h])&&(a[h]=!(b[h]=f))}):function(a,e,f){return b[0]=a,d(b,null,f,c),b[0]=null,!c.pop()}}),has:ha(function(a){return function(b){return fa(a,b).length>0}}),contains:ha(function(a){return a=a.replace(ba,ca),function(b){return(b.textContent||b.innerText||e(b)).indexOf(a)>-1}}),lang:ha(function(a){return V.test(a||"")||fa.error("unsupported lang: "+a),a=a.replace(ba,ca).toLowerCase(),function(b){var c;do if(c=p?b.lang:b.getAttribute("xml:lang")||b.getAttribute("lang"))return c=c.toLowerCase(),c===a||0===c.indexOf(a+"-");while((b=b.parentNode)&&1===b.nodeType);return!1}}),target:function(b){var c=a.location&&a.location.hash;return c&&c.slice(1)===b.id},root:function(a){return a===o},focus:function(a){return a===n.activeElement&&(!n.hasFocus||n.hasFocus())&&!!(a.type||a.href||~a.tabIndex)},enabled:function(a){return a.disabled===!1},disabled:function(a){return a.disabled===!0},checked:function(a){var b=a.nodeName.toLowerCase();return"input"===b&&!!a.checked||"option"===b&&!!a.selected},selected:function(a){return a.parentNode&&a.parentNode.selectedIndex,a.selected===!0},empty:function(a){for(a=a.firstChild;a;a=a.nextSibling)if(a.nodeType<6)return!1;return!0},parent:function(a){return!d.pseudos.empty(a)},header:function(a){return Y.test(a.nodeName)},input:function(a){return X.test(a.nodeName)},button:function(a){var b=a.nodeName.toLowerCase();return"input"===b&&"button"===a.type||"button"===b},text:function(a){var b;return"input"===a.nodeName.toLowerCase()&&"text"===a.type&&(null==(b=a.getAttribute("type"))||"text"===b.toLowerCase())},first:na(function(){return[0]}),last:na(function(a,b){return[b-1]}),eq:na(function(a,b,c){return[0>c?c+b:c]}),even:na(function(a,b){for(var c=0;b>c;c+=2)a.push(c);return a}),odd:na(function(a,b){for(var c=1;b>c;c+=2)a.push(c);return a}),lt:na(function(a,b,c){for(var d=0>c?c+b:c;--d>=0;)a.push(d);return a}),gt:na(function(a,b,c){for(var d=0>c?c+b:c;++d<b;)a.push(d);return a})}},d.pseudos.nth=d.pseudos.eq;for(b in{radio:!0,checkbox:!0,file:!0,password:!0,image:!0})d.pseudos[b]=la(b);for(b in{submit:!0,reset:!0})d.pseudos[b]=ma(b);function pa(){}pa.prototype=d.filters=d.pseudos,d.setFilters=new pa,g=fa.tokenize=function(a,b){var c,e,f,g,h,i,j,k=z[a+" "];if(k)return b?0:k.slice(0);h=a,i=[],j=d.preFilter;while(h){(!c||(e=R.exec(h)))&&(e&&(h=h.slice(e[0].length)||h),i.push(f=[])),c=!1,(e=S.exec(h))&&(c=e.shift(),f.push({value:c,type:e[0].replace(Q," ")}),h=h.slice(c.length));for(g in d.filter)!(e=W[g].exec(h))||j[g]&&!(e=j[g](e))||(c=e.shift(),f.push({value:c,type:g,matches:e}),h=h.slice(c.length));if(!c)break}return b?h.length:h?fa.error(a):z(a,i).slice(0)};function qa(a){for(var b=0,c=a.length,d="";c>b;b++)d+=a[b].value;return d}function ra(a,b,c){var d=b.dir,e=c&&"parentNode"===d,f=x++;return b.first?function(b,c,f){while(b=b[d])if(1===b.nodeType||e)return a(b,c,f)}:function(b,c,g){var h,i,j,k=[w,f];if(g){while(b=b[d])if((1===b.nodeType||e)&&a(b,c,g))return!0}else while(b=b[d])if(1===b.nodeType||e){if(j=b[u]||(b[u]={}),i=j[b.uniqueID]||(j[b.uniqueID]={}),(h=i[d])&&h[0]===w&&h[1]===f)return k[2]=h[2];if(i[d]=k,k[2]=a(b,c,g))return!0}}}function sa(a){return a.length>1?function(b,c,d){var e=a.length;while(e--)if(!a[e](b,c,d))return!1;return!0}:a[0]}function ta(a,b,c){for(var d=0,e=b.length;e>d;d++)fa(a,b[d],c);return c}function ua(a,b,c,d,e){for(var f,g=[],h=0,i=a.length,j=null!=b;i>h;h++)(f=a[h])&&(!c||c(f,d,e))&&(g.push(f),j&&b.push(h));return g}function va(a,b,c,d,e,f){return d&&!d[u]&&(d=va(d)),e&&!e[u]&&(e=va(e,f)),ha(function(f,g,h,i){var j,k,l,m=[],n=[],o=g.length,p=f||ta(b||"*",h.nodeType?[h]:h,[]),q=!a||!f&&b?p:ua(p,m,a,h,i),r=c?e||(f?a:o||d)?[]:g:q;if(c&&c(q,r,h,i),d){j=ua(r,n),d(j,[],h,i),k=j.length;while(k--)(l=j[k])&&(r[n[k]]=!(q[n[k]]=l))}if(f){if(e||a){if(e){j=[],k=r.length;while(k--)(l=r[k])&&j.push(q[k]=l);e(null,r=[],j,i)}k=r.length;while(k--)(l=r[k])&&(j=e?J(f,l):m[k])>-1&&(f[j]=!(g[j]=l))}}else r=ua(r===g?r.splice(o,r.length):r),e?e(null,g,r,i):H.apply(g,r)})}function wa(a){for(var b,c,e,f=a.length,g=d.relative[a[0].type],h=g||d.relative[" "],i=g?1:0,k=ra(function(a){return a===b},h,!0),l=ra(function(a){return J(b,a)>-1},h,!0),m=[function(a,c,d){var e=!g&&(d||c!==j)||((b=c).nodeType?k(a,c,d):l(a,c,d));return b=null,e}];f>i;i++)if(c=d.relative[a[i].type])m=[ra(sa(m),c)];else{if(c=d.filter[a[i].type].apply(null,a[i].matches),c[u]){for(e=++i;f>e;e++)if(d.relative[a[e].type])break;return va(i>1&&sa(m),i>1&&qa(a.slice(0,i-1).concat({value:" "===a[i-2].type?"*":""})).replace(Q,"$1"),c,e>i&&wa(a.slice(i,e)),f>e&&wa(a=a.slice(e)),f>e&&qa(a))}m.push(c)}return sa(m)}function xa(a,b){var c=b.length>0,e=a.length>0,f=function(f,g,h,i,k){var l,o,q,r=0,s="0",t=f&&[],u=[],v=j,x=f||e&&d.find.TAG("*",k),y=w+=null==v?1:Math.random()||.1,z=x.length;for(k&&(j=g===n||g||k);s!==z&&null!=(l=x[s]);s++){if(e&&l){o=0,g||l.ownerDocument===n||(m(l),h=!p);while(q=a[o++])if(q(l,g||n,h)){i.push(l);break}k&&(w=y)}c&&((l=!q&&l)&&r--,f&&t.push(l))}if(r+=s,c&&s!==r){o=0;while(q=b[o++])q(t,u,g,h);if(f){if(r>0)while(s--)t[s]||u[s]||(u[s]=F.call(i));u=ua(u)}H.apply(i,u),k&&!f&&u.length>0&&r+b.length>1&&fa.uniqueSort(i)}return k&&(w=y,j=v),t};return c?ha(f):f}return h=fa.compile=function(a,b){var c,d=[],e=[],f=A[a+" "];if(!f){b||(b=g(a)),c=b.length;while(c--)f=wa(b[c]),f[u]?d.push(f):e.push(f);f=A(a,xa(e,d)),f.selector=a}return f},i=fa.select=function(a,b,e,f){var i,j,k,l,m,n="function"==typeof a&&a,o=!f&&g(a=n.selector||a);if(e=e||[],1===o.length){if(j=o[0]=o[0].slice(0),j.length>2&&"ID"===(k=j[0]).type&&c.getById&&9===b.nodeType&&p&&d.relative[j[1].type]){if(b=(d.find.ID(k.matches[0].replace(ba,ca),b)||[])[0],!b)return e;n&&(b=b.parentNode),a=a.slice(j.shift().value.length)}i=W.needsContext.test(a)?0:j.length;while(i--){if(k=j[i],d.relative[l=k.type])break;if((m=d.find[l])&&(f=m(k.matches[0].replace(ba,ca),_.test(j[0].type)&&oa(b.parentNode)||b))){if(j.splice(i,1),a=f.length&&qa(j),!a)return H.apply(e,f),e;break}}}return(n||h(a,o))(f,b,!p,e,!b||_.test(a)&&oa(b.parentNode)||b),e},c.sortStable=u.split("").sort(B).join("")===u,c.detectDuplicates=!!l,m(),c.sortDetached=ia(function(a){return 1&a.compareDocumentPosition(n.createElement("div"))}),ia(function(a){return a.innerHTML="<a href='#'></a>","#"===a.firstChild.getAttribute("href")})||ja("type|href|height|width",function(a,b,c){return c?void 0:a.getAttribute(b,"type"===b.toLowerCase()?1:2)}),c.attributes&&ia(function(a){return a.innerHTML="<input/>",a.firstChild.setAttribute("value",""),""===a.firstChild.getAttribute("value")})||ja("value",function(a,b,c){return c||"input"!==a.nodeName.toLowerCase()?void 0:a.defaultValue}),ia(function(a){return null==a.getAttribute("disabled")})||ja(K,function(a,b,c){var d;return c?void 0:a[b]===!0?b.toLowerCase():(d=a.getAttributeNode(b))&&d.specified?d.value:null}),fa}(a);n.find=t,n.expr=t.selectors,n.expr[":"]=n.expr.pseudos,n.uniqueSort=n.unique=t.uniqueSort,n.text=t.getText,n.isXMLDoc=t.isXML,n.contains=t.contains;var u=function(a,b,c){var d=[],e=void 0!==c;while((a=a[b])&&9!==a.nodeType)if(1===a.nodeType){if(e&&n(a).is(c))break;d.push(a)}return d},v=function(a,b){for(var c=[];a;a=a.nextSibling)1===a.nodeType&&a!==b&&c.push(a);return c},w=n.expr.match.needsContext,x=/^<([\w-]+)\s*\/?>(?:<\/\1>|)$/,y=/^.[^:#\[\.,]*$/;function z(a,b,c){if(n.isFunction(b))return n.grep(a,function(a,d){return!!b.call(a,d,a)!==c});if(b.nodeType)return n.grep(a,function(a){return a===b!==c});if("string"==typeof b){if(y.test(b))return n.filter(b,a,c);b=n.filter(b,a)}return n.grep(a,function(a){return n.inArray(a,b)>-1!==c})}n.filter=function(a,b,c){var d=b[0];return c&&(a=":not("+a+")"),1===b.length&&1===d.nodeType?n.find.matchesSelector(d,a)?[d]:[]:n.find.matches(a,n.grep(b,function(a){return 1===a.nodeType}))},n.fn.extend({find:function(a){var b,c=[],d=this,e=d.length;if("string"!=typeof a)return this.pushStack(n(a).filter(function(){for(b=0;e>b;b++)if(n.contains(d[b],this))return!0}));for(b=0;e>b;b++)n.find(a,d[b],c);return c=this.pushStack(e>1?n.unique(c):c),c.selector=this.selector?this.selector+" "+a:a,c},filter:function(a){return this.pushStack(z(this,a||[],!1))},not:function(a){return this.pushStack(z(this,a||[],!0))},is:function(a){return!!z(this,"string"==typeof a&&w.test(a)?n(a):a||[],!1).length}});var A,B=/^(?:\s*(<[\w\W]+>)[^>]*|#([\w-]*))$/,C=n.fn.init=function(a,b,c){var e,f;if(!a)return this;if(c=c||A,"string"==typeof a){if(e="<"===a.charAt(0)&&">"===a.charAt(a.length-1)&&a.length>=3?[null,a,null]:B.exec(a),!e||!e[1]&&b)return!b||b.jquery?(b||c).find(a):this.constructor(b).find(a);if(e[1]){if(b=b instanceof n?b[0]:b,n.merge(this,n.parseHTML(e[1],b&&b.nodeType?b.ownerDocument||b:d,!0)),x.test(e[1])&&n.isPlainObject(b))for(e in b)n.isFunction(this[e])?this[e](b[e]):this.attr(e,b[e]);return this}if(f=d.getElementById(e[2]),f&&f.parentNode){if(f.id!==e[2])return A.find(a);this.length=1,this[0]=f}return this.context=d,this.selector=a,this}return a.nodeType?(this.context=this[0]=a,this.length=1,this):n.isFunction(a)?"undefined"!=typeof c.ready?c.ready(a):a(n):(void 0!==a.selector&&(this.selector=a.selector,this.context=a.context),n.makeArray(a,this))};C.prototype=n.fn,A=n(d);var D=/^(?:parents|prev(?:Until|All))/,E={children:!0,contents:!0,next:!0,prev:!0};n.fn.extend({has:function(a){var b,c=n(a,this),d=c.length;return this.filter(function(){for(b=0;d>b;b++)if(n.contains(this,c[b]))return!0})},closest:function(a,b){for(var c,d=0,e=this.length,f=[],g=w.test(a)||"string"!=typeof a?n(a,b||this.context):0;e>d;d++)for(c=this[d];c&&c!==b;c=c.parentNode)if(c.nodeType<11&&(g?g.index(c)>-1:1===c.nodeType&&n.find.matchesSelector(c,a))){f.push(c);break}return this.pushStack(f.length>1?n.uniqueSort(f):f)},index:function(a){return a?"string"==typeof a?n.inArray(this[0],n(a)):n.inArray(a.jquery?a[0]:a,this):this[0]&&this[0].parentNode?this.first().prevAll().length:-1},add:function(a,b){return this.pushStack(n.uniqueSort(n.merge(this.get(),n(a,b))))},addBack:function(a){return this.add(null==a?this.prevObject:this.prevObject.filter(a))}});function F(a,b){do a=a[b];while(a&&1!==a.nodeType);return a}n.each({parent:function(a){var b=a.parentNode;return b&&11!==b.nodeType?b:null},parents:function(a){return u(a,"parentNode")},parentsUntil:function(a,b,c){return u(a,"parentNode",c)},next:function(a){return F(a,"nextSibling")},prev:function(a){return F(a,"previousSibling")},nextAll:function(a){return u(a,"nextSibling")},prevAll:function(a){return u(a,"previousSibling")},nextUntil:function(a,b,c){return u(a,"nextSibling",c)},prevUntil:function(a,b,c){return u(a,"previousSibling",c)},siblings:function(a){return v((a.parentNode||{}).firstChild,a)},children:function(a){return v(a.firstChild)},contents:function(a){return n.nodeName(a,"iframe")?a.contentDocument||a.contentWindow.document:n.merge([],a.childNodes)}},function(a,b){n.fn[a]=function(c,d){var e=n.map(this,b,c);return"Until"!==a.slice(-5)&&(d=c),d&&"string"==typeof d&&(e=n.filter(d,e)),this.length>1&&(E[a]||(e=n.uniqueSort(e)),D.test(a)&&(e=e.reverse())),this.pushStack(e)}});var G=/\S+/g;function H(a){var b={};return n.each(a.match(G)||[],function(a,c){b[c]=!0}),b}n.Callbacks=function(a){a="string"==typeof a?H(a):n.extend({},a);var b,c,d,e,f=[],g=[],h=-1,i=function(){for(e=a.once,d=b=!0;g.length;h=-1){c=g.shift();while(++h<f.length)f[h].apply(c[0],c[1])===!1&&a.stopOnFalse&&(h=f.length,c=!1)}a.memory||(c=!1),b=!1,e&&(f=c?[]:"")},j={add:function(){return f&&(c&&!b&&(h=f.length-1,g.push(c)),function d(b){n.each(b,function(b,c){n.isFunction(c)?a.unique&&j.has(c)||f.push(c):c&&c.length&&"string"!==n.type(c)&&d(c)})}(arguments),c&&!b&&i()),this},remove:function(){return n.each(arguments,function(a,b){var c;while((c=n.inArray(b,f,c))>-1)f.splice(c,1),h>=c&&h--}),this},has:function(a){return a?n.inArray(a,f)>-1:f.length>0},empty:function(){return f&&(f=[]),this},disable:function(){return e=g=[],f=c="",this},disabled:function(){return!f},lock:function(){return e=!0,c||j.disable(),this},locked:function(){return!!e},fireWith:function(a,c){return e||(c=c||[],c=[a,c.slice?c.slice():c],g.push(c),b||i()),this},fire:function(){return j.fireWith(this,arguments),this},fired:function(){return!!d}};return j},n.extend({Deferred:function(a){var b=[["resolve","done",n.Callbacks("once memory"),"resolved"],["reject","fail",n.Callbacks("once memory"),"rejected"],["notify","progress",n.Callbacks("memory")]],c="pending",d={state:function(){return c},always:function(){return e.done(arguments).fail(arguments),this},then:function(){var a=arguments;return n.Deferred(function(c){n.each(b,function(b,f){var g=n.isFunction(a[b])&&a[b];e[f[1]](function(){var a=g&&g.apply(this,arguments);a&&n.isFunction(a.promise)?a.promise().progress(c.notify).done(c.resolve).fail(c.reject):c[f[0]+"With"](this===d?c.promise():this,g?[a]:arguments)})}),a=null}).promise()},promise:function(a){return null!=a?n.extend(a,d):d}},e={};return d.pipe=d.then,n.each(b,function(a,f){var g=f[2],h=f[3];d[f[1]]=g.add,h&&g.add(function(){c=h},b[1^a][2].disable,b[2][2].lock),e[f[0]]=function(){return e[f[0]+"With"](this===e?d:this,arguments),this},e[f[0]+"With"]=g.fireWith}),d.promise(e),a&&a.call(e,e),e},when:function(a){var b=0,c=e.call(arguments),d=c.length,f=1!==d||a&&n.isFunction(a.promise)?d:0,g=1===f?a:n.Deferred(),h=function(a,b,c){return function(d){b[a]=this,c[a]=arguments.length>1?e.call(arguments):d,c===i?g.notifyWith(b,c):--f||g.resolveWith(b,c)}},i,j,k;if(d>1)for(i=new Array(d),j=new Array(d),k=new Array(d);d>b;b++)c[b]&&n.isFunction(c[b].promise)?c[b].promise().progress(h(b,j,i)).done(h(b,k,c)).fail(g.reject):--f;return f||g.resolveWith(k,c),g.promise()}});var I;n.fn.ready=function(a){return n.ready.promise().done(a),this},n.extend({isReady:!1,readyWait:1,holdReady:function(a){a?n.readyWait++:n.ready(!0)},ready:function(a){(a===!0?--n.readyWait:n.isReady)||(n.isReady=!0,a!==!0&&--n.readyWait>0||(I.resolveWith(d,[n]),n.fn.triggerHandler&&(n(d).triggerHandler("ready"),n(d).off("ready"))))}});function J(){d.addEventListener?(d.removeEventListener("DOMContentLoaded",K),a.removeEventListener("load",K)):(d.detachEvent("onreadystatechange",K),a.detachEvent("onload",K))}function K(){(d.addEventListener||"load"===a.event.type||"complete"===d.readyState)&&(J(),n.ready())}n.ready.promise=function(b){if(!I)if(I=n.Deferred(),"complete"===d.readyState)a.setTimeout(n.ready);else if(d.addEventListener)d.addEventListener("DOMContentLoaded",K),a.addEventListener("load",K);else{d.attachEvent("onreadystatechange",K),a.attachEvent("onload",K);var c=!1;try{c=null==a.frameElement&&d.documentElement}catch(e){}c&&c.doScroll&&!function f(){if(!n.isReady){try{c.doScroll("left")}catch(b){return a.setTimeout(f,50)}J(),n.ready()}}()}return I.promise(b)},n.ready.promise();var L;for(L in n(l))break;l.ownFirst="0"===L,l.inlineBlockNeedsLayout=!1,n(function(){var a,b,c,e;c=d.getElementsByTagName("body")[0],c&&c.style&&(b=d.createElement("div"),e=d.createElement("div"),e.style.cssText="position:absolute;border:0;width:0;height:0;top:0;left:-9999px",c.appendChild(e).appendChild(b),"undefined"!=typeof b.style.zoom&&(b.style.cssText="display:inline;margin:0;border:0;padding:1px;width:1px;zoom:1",l.inlineBlockNeedsLayout=a=3===b.offsetWidth,a&&(c.style.zoom=1)),c.removeChild(e))}),function(){var a=d.createElement("div");l.deleteExpando=!0;try{delete a.test}catch(b){l.deleteExpando=!1}a=null}();var M=function(a){var b=n.noData[(a.nodeName+" ").toLowerCase()],c=+a.nodeType||1;return 1!==c&&9!==c?!1:!b||b!==!0&&a.getAttribute("classid")===b},N=/^(?:\{[\w\W]*\}|\[[\w\W]*\])$/,O=/([A-Z])/g;function P(a,b,c){if(void 0===c&&1===a.nodeType){var d="data-"+b.replace(O,"-$1").toLowerCase();if(c=a.getAttribute(d),"string"==typeof c){try{c="true"===c?!0:"false"===c?!1:"null"===c?null:+c+""===c?+c:N.test(c)?n.parseJSON(c):c}catch(e){}n.data(a,b,c)}else c=void 0}return c}function Q(a){var b;for(b in a)if(("data"!==b||!n.isEmptyObject(a[b]))&&"toJSON"!==b)return!1;
+return!0}function R(a,b,d,e){if(M(a)){var f,g,h=n.expando,i=a.nodeType,j=i?n.cache:a,k=i?a[h]:a[h]&&h;if(k&&j[k]&&(e||j[k].data)||void 0!==d||"string"!=typeof b)return k||(k=i?a[h]=c.pop()||n.guid++:h),j[k]||(j[k]=i?{}:{toJSON:n.noop}),("object"==typeof b||"function"==typeof b)&&(e?j[k]=n.extend(j[k],b):j[k].data=n.extend(j[k].data,b)),g=j[k],e||(g.data||(g.data={}),g=g.data),void 0!==d&&(g[n.camelCase(b)]=d),"string"==typeof b?(f=g[b],null==f&&(f=g[n.camelCase(b)])):f=g,f}}function S(a,b,c){if(M(a)){var d,e,f=a.nodeType,g=f?n.cache:a,h=f?a[n.expando]:n.expando;if(g[h]){if(b&&(d=c?g[h]:g[h].data)){n.isArray(b)?b=b.concat(n.map(b,n.camelCase)):b in d?b=[b]:(b=n.camelCase(b),b=b in d?[b]:b.split(" ")),e=b.length;while(e--)delete d[b[e]];if(c?!Q(d):!n.isEmptyObject(d))return}(c||(delete g[h].data,Q(g[h])))&&(f?n.cleanData([a],!0):l.deleteExpando||g!=g.window?delete g[h]:g[h]=void 0)}}}n.extend({cache:{},noData:{"applet ":!0,"embed ":!0,"object ":"clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"},hasData:function(a){return a=a.nodeType?n.cache[a[n.expando]]:a[n.expando],!!a&&!Q(a)},data:function(a,b,c){return R(a,b,c)},removeData:function(a,b){return S(a,b)},_data:function(a,b,c){return R(a,b,c,!0)},_removeData:function(a,b){return S(a,b,!0)}}),n.fn.extend({data:function(a,b){var c,d,e,f=this[0],g=f&&f.attributes;if(void 0===a){if(this.length&&(e=n.data(f),1===f.nodeType&&!n._data(f,"parsedAttrs"))){c=g.length;while(c--)g[c]&&(d=g[c].name,0===d.indexOf("data-")&&(d=n.camelCase(d.slice(5)),P(f,d,e[d])));n._data(f,"parsedAttrs",!0)}return e}return"object"==typeof a?this.each(function(){n.data(this,a)}):arguments.length>1?this.each(function(){n.data(this,a,b)}):f?P(f,a,n.data(f,a)):void 0},removeData:function(a){return this.each(function(){n.removeData(this,a)})}}),n.extend({queue:function(a,b,c){var d;return a?(b=(b||"fx")+"queue",d=n._data(a,b),c&&(!d||n.isArray(c)?d=n._data(a,b,n.makeArray(c)):d.push(c)),d||[]):void 0},dequeue:function(a,b){b=b||"fx";var c=n.queue(a,b),d=c.length,e=c.shift(),f=n._queueHooks(a,b),g=function(){n.dequeue(a,b)};"inprogress"===e&&(e=c.shift(),d--),e&&("fx"===b&&c.unshift("inprogress"),delete f.stop,e.call(a,g,f)),!d&&f&&f.empty.fire()},_queueHooks:function(a,b){var c=b+"queueHooks";return n._data(a,c)||n._data(a,c,{empty:n.Callbacks("once memory").add(function(){n._removeData(a,b+"queue"),n._removeData(a,c)})})}}),n.fn.extend({queue:function(a,b){var c=2;return"string"!=typeof a&&(b=a,a="fx",c--),arguments.length<c?n.queue(this[0],a):void 0===b?this:this.each(function(){var c=n.queue(this,a,b);n._queueHooks(this,a),"fx"===a&&"inprogress"!==c[0]&&n.dequeue(this,a)})},dequeue:function(a){return this.each(function(){n.dequeue(this,a)})},clearQueue:function(a){return this.queue(a||"fx",[])},promise:function(a,b){var c,d=1,e=n.Deferred(),f=this,g=this.length,h=function(){--d||e.resolveWith(f,[f])};"string"!=typeof a&&(b=a,a=void 0),a=a||"fx";while(g--)c=n._data(f[g],a+"queueHooks"),c&&c.empty&&(d++,c.empty.add(h));return h(),e.promise(b)}}),function(){var a;l.shrinkWrapBlocks=function(){if(null!=a)return a;a=!1;var b,c,e;return c=d.getElementsByTagName("body")[0],c&&c.style?(b=d.createElement("div"),e=d.createElement("div"),e.style.cssText="position:absolute;border:0;width:0;height:0;top:0;left:-9999px",c.appendChild(e).appendChild(b),"undefined"!=typeof b.style.zoom&&(b.style.cssText="-webkit-box-sizing:content-box;-moz-box-sizing:content-box;box-sizing:content-box;display:block;margin:0;border:0;padding:1px;width:1px;zoom:1",b.appendChild(d.createElement("div")).style.width="5px",a=3!==b.offsetWidth),c.removeChild(e),a):void 0}}();var T=/[+-]?(?:\d*\.|)\d+(?:[eE][+-]?\d+|)/.source,U=new RegExp("^(?:([+-])=|)("+T+")([a-z%]*)$","i"),V=["Top","Right","Bottom","Left"],W=function(a,b){return a=b||a,"none"===n.css(a,"display")||!n.contains(a.ownerDocument,a)};function X(a,b,c,d){var e,f=1,g=20,h=d?function(){return d.cur()}:function(){return n.css(a,b,"")},i=h(),j=c&&c[3]||(n.cssNumber[b]?"":"px"),k=(n.cssNumber[b]||"px"!==j&&+i)&&U.exec(n.css(a,b));if(k&&k[3]!==j){j=j||k[3],c=c||[],k=+i||1;do f=f||".5",k/=f,n.style(a,b,k+j);while(f!==(f=h()/i)&&1!==f&&--g)}return c&&(k=+k||+i||0,e=c[1]?k+(c[1]+1)*c[2]:+c[2],d&&(d.unit=j,d.start=k,d.end=e)),e}var Y=function(a,b,c,d,e,f,g){var h=0,i=a.length,j=null==c;if("object"===n.type(c)){e=!0;for(h in c)Y(a,b,h,c[h],!0,f,g)}else if(void 0!==d&&(e=!0,n.isFunction(d)||(g=!0),j&&(g?(b.call(a,d),b=null):(j=b,b=function(a,b,c){return j.call(n(a),c)})),b))for(;i>h;h++)b(a[h],c,g?d:d.call(a[h],h,b(a[h],c)));return e?a:j?b.call(a):i?b(a[0],c):f},Z=/^(?:checkbox|radio)$/i,$=/<([\w:-]+)/,_=/^$|\/(?:java|ecma)script/i,aa=/^\s+/,ba="abbr|article|aside|audio|bdi|canvas|data|datalist|details|dialog|figcaption|figure|footer|header|hgroup|main|mark|meter|nav|output|picture|progress|section|summary|template|time|video";function ca(a){var b=ba.split("|"),c=a.createDocumentFragment();if(c.createElement)while(b.length)c.createElement(b.pop());return c}!function(){var a=d.createElement("div"),b=d.createDocumentFragment(),c=d.createElement("input");a.innerHTML="  <link/><table></table><a href='/a'>a</a><input type='checkbox'/>",l.leadingWhitespace=3===a.firstChild.nodeType,l.tbody=!a.getElementsByTagName("tbody").length,l.htmlSerialize=!!a.getElementsByTagName("link").length,l.html5Clone="<:nav></:nav>"!==d.createElement("nav").cloneNode(!0).outerHTML,c.type="checkbox",c.checked=!0,b.appendChild(c),l.appendChecked=c.checked,a.innerHTML="<textarea>x</textarea>",l.noCloneChecked=!!a.cloneNode(!0).lastChild.defaultValue,b.appendChild(a),c=d.createElement("input"),c.setAttribute("type","radio"),c.setAttribute("checked","checked"),c.setAttribute("name","t"),a.appendChild(c),l.checkClone=a.cloneNode(!0).cloneNode(!0).lastChild.checked,l.noCloneEvent=!!a.addEventListener,a[n.expando]=1,l.attributes=!a.getAttribute(n.expando)}();var da={option:[1,"<select multiple='multiple'>","</select>"],legend:[1,"<fieldset>","</fieldset>"],area:[1,"<map>","</map>"],param:[1,"<object>","</object>"],thead:[1,"<table>","</table>"],tr:[2,"<table><tbody>","</tbody></table>"],col:[2,"<table><tbody></tbody><colgroup>","</colgroup></table>"],td:[3,"<table><tbody><tr>","</tr></tbody></table>"],_default:l.htmlSerialize?[0,"",""]:[1,"X<div>","</div>"]};da.optgroup=da.option,da.tbody=da.tfoot=da.colgroup=da.caption=da.thead,da.th=da.td;function ea(a,b){var c,d,e=0,f="undefined"!=typeof a.getElementsByTagName?a.getElementsByTagName(b||"*"):"undefined"!=typeof a.querySelectorAll?a.querySelectorAll(b||"*"):void 0;if(!f)for(f=[],c=a.childNodes||a;null!=(d=c[e]);e++)!b||n.nodeName(d,b)?f.push(d):n.merge(f,ea(d,b));return void 0===b||b&&n.nodeName(a,b)?n.merge([a],f):f}function fa(a,b){for(var c,d=0;null!=(c=a[d]);d++)n._data(c,"globalEval",!b||n._data(b[d],"globalEval"))}var ga=/<|&#?\w+;/,ha=/<tbody/i;function ia(a){Z.test(a.type)&&(a.defaultChecked=a.checked)}function ja(a,b,c,d,e){for(var f,g,h,i,j,k,m,o=a.length,p=ca(b),q=[],r=0;o>r;r++)if(g=a[r],g||0===g)if("object"===n.type(g))n.merge(q,g.nodeType?[g]:g);else if(ga.test(g)){i=i||p.appendChild(b.createElement("div")),j=($.exec(g)||["",""])[1].toLowerCase(),m=da[j]||da._default,i.innerHTML=m[1]+n.htmlPrefilter(g)+m[2],f=m[0];while(f--)i=i.lastChild;if(!l.leadingWhitespace&&aa.test(g)&&q.push(b.createTextNode(aa.exec(g)[0])),!l.tbody){g="table"!==j||ha.test(g)?"<table>"!==m[1]||ha.test(g)?0:i:i.firstChild,f=g&&g.childNodes.length;while(f--)n.nodeName(k=g.childNodes[f],"tbody")&&!k.childNodes.length&&g.removeChild(k)}n.merge(q,i.childNodes),i.textContent="";while(i.firstChild)i.removeChild(i.firstChild);i=p.lastChild}else q.push(b.createTextNode(g));i&&p.removeChild(i),l.appendChecked||n.grep(ea(q,"input"),ia),r=0;while(g=q[r++])if(d&&n.inArray(g,d)>-1)e&&e.push(g);else if(h=n.contains(g.ownerDocument,g),i=ea(p.appendChild(g),"script"),h&&fa(i),c){f=0;while(g=i[f++])_.test(g.type||"")&&c.push(g)}return i=null,p}!function(){var b,c,e=d.createElement("div");for(b in{submit:!0,change:!0,focusin:!0})c="on"+b,(l[b]=c in a)||(e.setAttribute(c,"t"),l[b]=e.attributes[c].expando===!1);e=null}();var ka=/^(?:input|select|textarea)$/i,la=/^key/,ma=/^(?:mouse|pointer|contextmenu|drag|drop)|click/,na=/^(?:focusinfocus|focusoutblur)$/,oa=/^([^.]*)(?:\.(.+)|)/;function pa(){return!0}function qa(){return!1}function ra(){try{return d.activeElement}catch(a){}}function sa(a,b,c,d,e,f){var g,h;if("object"==typeof b){"string"!=typeof c&&(d=d||c,c=void 0);for(h in b)sa(a,h,c,d,b[h],f);return a}if(null==d&&null==e?(e=c,d=c=void 0):null==e&&("string"==typeof c?(e=d,d=void 0):(e=d,d=c,c=void 0)),e===!1)e=qa;else if(!e)return a;return 1===f&&(g=e,e=function(a){return n().off(a),g.apply(this,arguments)},e.guid=g.guid||(g.guid=n.guid++)),a.each(function(){n.event.add(this,b,e,d,c)})}n.event={global:{},add:function(a,b,c,d,e){var f,g,h,i,j,k,l,m,o,p,q,r=n._data(a);if(r){c.handler&&(i=c,c=i.handler,e=i.selector),c.guid||(c.guid=n.guid++),(g=r.events)||(g=r.events={}),(k=r.handle)||(k=r.handle=function(a){return"undefined"==typeof n||a&&n.event.triggered===a.type?void 0:n.event.dispatch.apply(k.elem,arguments)},k.elem=a),b=(b||"").match(G)||[""],h=b.length;while(h--)f=oa.exec(b[h])||[],o=q=f[1],p=(f[2]||"").split(".").sort(),o&&(j=n.event.special[o]||{},o=(e?j.delegateType:j.bindType)||o,j=n.event.special[o]||{},l=n.extend({type:o,origType:q,data:d,handler:c,guid:c.guid,selector:e,needsContext:e&&n.expr.match.needsContext.test(e),namespace:p.join(".")},i),(m=g[o])||(m=g[o]=[],m.delegateCount=0,j.setup&&j.setup.call(a,d,p,k)!==!1||(a.addEventListener?a.addEventListener(o,k,!1):a.attachEvent&&a.attachEvent("on"+o,k))),j.add&&(j.add.call(a,l),l.handler.guid||(l.handler.guid=c.guid)),e?m.splice(m.delegateCount++,0,l):m.push(l),n.event.global[o]=!0);a=null}},remove:function(a,b,c,d,e){var f,g,h,i,j,k,l,m,o,p,q,r=n.hasData(a)&&n._data(a);if(r&&(k=r.events)){b=(b||"").match(G)||[""],j=b.length;while(j--)if(h=oa.exec(b[j])||[],o=q=h[1],p=(h[2]||"").split(".").sort(),o){l=n.event.special[o]||{},o=(d?l.delegateType:l.bindType)||o,m=k[o]||[],h=h[2]&&new RegExp("(^|\\.)"+p.join("\\.(?:.*\\.|)")+"(\\.|$)"),i=f=m.length;while(f--)g=m[f],!e&&q!==g.origType||c&&c.guid!==g.guid||h&&!h.test(g.namespace)||d&&d!==g.selector&&("**"!==d||!g.selector)||(m.splice(f,1),g.selector&&m.delegateCount--,l.remove&&l.remove.call(a,g));i&&!m.length&&(l.teardown&&l.teardown.call(a,p,r.handle)!==!1||n.removeEvent(a,o,r.handle),delete k[o])}else for(o in k)n.event.remove(a,o+b[j],c,d,!0);n.isEmptyObject(k)&&(delete r.handle,n._removeData(a,"events"))}},trigger:function(b,c,e,f){var g,h,i,j,l,m,o,p=[e||d],q=k.call(b,"type")?b.type:b,r=k.call(b,"namespace")?b.namespace.split("."):[];if(i=m=e=e||d,3!==e.nodeType&&8!==e.nodeType&&!na.test(q+n.event.triggered)&&(q.indexOf(".")>-1&&(r=q.split("."),q=r.shift(),r.sort()),h=q.indexOf(":")<0&&"on"+q,b=b[n.expando]?b:new n.Event(q,"object"==typeof b&&b),b.isTrigger=f?2:3,b.namespace=r.join("."),b.rnamespace=b.namespace?new RegExp("(^|\\.)"+r.join("\\.(?:.*\\.|)")+"(\\.|$)"):null,b.result=void 0,b.target||(b.target=e),c=null==c?[b]:n.makeArray(c,[b]),l=n.event.special[q]||{},f||!l.trigger||l.trigger.apply(e,c)!==!1)){if(!f&&!l.noBubble&&!n.isWindow(e)){for(j=l.delegateType||q,na.test(j+q)||(i=i.parentNode);i;i=i.parentNode)p.push(i),m=i;m===(e.ownerDocument||d)&&p.push(m.defaultView||m.parentWindow||a)}o=0;while((i=p[o++])&&!b.isPropagationStopped())b.type=o>1?j:l.bindType||q,g=(n._data(i,"events")||{})[b.type]&&n._data(i,"handle"),g&&g.apply(i,c),g=h&&i[h],g&&g.apply&&M(i)&&(b.result=g.apply(i,c),b.result===!1&&b.preventDefault());if(b.type=q,!f&&!b.isDefaultPrevented()&&(!l._default||l._default.apply(p.pop(),c)===!1)&&M(e)&&h&&e[q]&&!n.isWindow(e)){m=e[h],m&&(e[h]=null),n.event.triggered=q;try{e[q]()}catch(s){}n.event.triggered=void 0,m&&(e[h]=m)}return b.result}},dispatch:function(a){a=n.event.fix(a);var b,c,d,f,g,h=[],i=e.call(arguments),j=(n._data(this,"events")||{})[a.type]||[],k=n.event.special[a.type]||{};if(i[0]=a,a.delegateTarget=this,!k.preDispatch||k.preDispatch.call(this,a)!==!1){h=n.event.handlers.call(this,a,j),b=0;while((f=h[b++])&&!a.isPropagationStopped()){a.currentTarget=f.elem,c=0;while((g=f.handlers[c++])&&!a.isImmediatePropagationStopped())(!a.rnamespace||a.rnamespace.test(g.namespace))&&(a.handleObj=g,a.data=g.data,d=((n.event.special[g.origType]||{}).handle||g.handler).apply(f.elem,i),void 0!==d&&(a.result=d)===!1&&(a.preventDefault(),a.stopPropagation()))}return k.postDispatch&&k.postDispatch.call(this,a),a.result}},handlers:function(a,b){var c,d,e,f,g=[],h=b.delegateCount,i=a.target;if(h&&i.nodeType&&("click"!==a.type||isNaN(a.button)||a.button<1))for(;i!=this;i=i.parentNode||this)if(1===i.nodeType&&(i.disabled!==!0||"click"!==a.type)){for(d=[],c=0;h>c;c++)f=b[c],e=f.selector+" ",void 0===d[e]&&(d[e]=f.needsContext?n(e,this).index(i)>-1:n.find(e,this,null,[i]).length),d[e]&&d.push(f);d.length&&g.push({elem:i,handlers:d})}return h<b.length&&g.push({elem:this,handlers:b.slice(h)}),g},fix:function(a){if(a[n.expando])return a;var b,c,e,f=a.type,g=a,h=this.fixHooks[f];h||(this.fixHooks[f]=h=ma.test(f)?this.mouseHooks:la.test(f)?this.keyHooks:{}),e=h.props?this.props.concat(h.props):this.props,a=new n.Event(g),b=e.length;while(b--)c=e[b],a[c]=g[c];return a.target||(a.target=g.srcElement||d),3===a.target.nodeType&&(a.target=a.target.parentNode),a.metaKey=!!a.metaKey,h.filter?h.filter(a,g):a},props:"altKey bubbles cancelable ctrlKey currentTarget detail eventPhase metaKey relatedTarget shiftKey target timeStamp view which".split(" "),fixHooks:{},keyHooks:{props:"char charCode key keyCode".split(" "),filter:function(a,b){return null==a.which&&(a.which=null!=b.charCode?b.charCode:b.keyCode),a}},mouseHooks:{props:"button buttons clientX clientY fromElement offsetX offsetY pageX pageY screenX screenY toElement".split(" "),filter:function(a,b){var c,e,f,g=b.button,h=b.fromElement;return null==a.pageX&&null!=b.clientX&&(e=a.target.ownerDocument||d,f=e.documentElement,c=e.body,a.pageX=b.clientX+(f&&f.scrollLeft||c&&c.scrollLeft||0)-(f&&f.clientLeft||c&&c.clientLeft||0),a.pageY=b.clientY+(f&&f.scrollTop||c&&c.scrollTop||0)-(f&&f.clientTop||c&&c.clientTop||0)),!a.relatedTarget&&h&&(a.relatedTarget=h===a.target?b.toElement:h),a.which||void 0===g||(a.which=1&g?1:2&g?3:4&g?2:0),a}},special:{load:{noBubble:!0},focus:{trigger:function(){if(this!==ra()&&this.focus)try{return this.focus(),!1}catch(a){}},delegateType:"focusin"},blur:{trigger:function(){return this===ra()&&this.blur?(this.blur(),!1):void 0},delegateType:"focusout"},click:{trigger:function(){return n.nodeName(this,"input")&&"checkbox"===this.type&&this.click?(this.click(),!1):void 0},_default:function(a){return n.nodeName(a.target,"a")}},beforeunload:{postDispatch:function(a){void 0!==a.result&&a.originalEvent&&(a.originalEvent.returnValue=a.result)}}},simulate:function(a,b,c){var d=n.extend(new n.Event,c,{type:a,isSimulated:!0});n.event.trigger(d,null,b),d.isDefaultPrevented()&&c.preventDefault()}},n.removeEvent=d.removeEventListener?function(a,b,c){a.removeEventListener&&a.removeEventListener(b,c)}:function(a,b,c){var d="on"+b;a.detachEvent&&("undefined"==typeof a[d]&&(a[d]=null),a.detachEvent(d,c))},n.Event=function(a,b){return this instanceof n.Event?(a&&a.type?(this.originalEvent=a,this.type=a.type,this.isDefaultPrevented=a.defaultPrevented||void 0===a.defaultPrevented&&a.returnValue===!1?pa:qa):this.type=a,b&&n.extend(this,b),this.timeStamp=a&&a.timeStamp||n.now(),void(this[n.expando]=!0)):new n.Event(a,b)},n.Event.prototype={constructor:n.Event,isDefaultPrevented:qa,isPropagationStopped:qa,isImmediatePropagationStopped:qa,preventDefault:function(){var a=this.originalEvent;this.isDefaultPrevented=pa,a&&(a.preventDefault?a.preventDefault():a.returnValue=!1)},stopPropagation:function(){var a=this.originalEvent;this.isPropagationStopped=pa,a&&!this.isSimulated&&(a.stopPropagation&&a.stopPropagation(),a.cancelBubble=!0)},stopImmediatePropagation:function(){var a=this.originalEvent;this.isImmediatePropagationStopped=pa,a&&a.stopImmediatePropagation&&a.stopImmediatePropagation(),this.stopPropagation()}},n.each({mouseenter:"mouseover",mouseleave:"mouseout",pointerenter:"pointerover",pointerleave:"pointerout"},function(a,b){n.event.special[a]={delegateType:b,bindType:b,handle:function(a){var c,d=this,e=a.relatedTarget,f=a.handleObj;return(!e||e!==d&&!n.contains(d,e))&&(a.type=f.origType,c=f.handler.apply(this,arguments),a.type=b),c}}}),l.submit||(n.event.special.submit={setup:function(){return n.nodeName(this,"form")?!1:void n.event.add(this,"click._submit keypress._submit",function(a){var b=a.target,c=n.nodeName(b,"input")||n.nodeName(b,"button")?n.prop(b,"form"):void 0;c&&!n._data(c,"submit")&&(n.event.add(c,"submit._submit",function(a){a._submitBubble=!0}),n._data(c,"submit",!0))})},postDispatch:function(a){a._submitBubble&&(delete a._submitBubble,this.parentNode&&!a.isTrigger&&n.event.simulate("submit",this.parentNode,a))},teardown:function(){return n.nodeName(this,"form")?!1:void n.event.remove(this,"._submit")}}),l.change||(n.event.special.change={setup:function(){return ka.test(this.nodeName)?(("checkbox"===this.type||"radio"===this.type)&&(n.event.add(this,"propertychange._change",function(a){"checked"===a.originalEvent.propertyName&&(this._justChanged=!0)}),n.event.add(this,"click._change",function(a){this._justChanged&&!a.isTrigger&&(this._justChanged=!1),n.event.simulate("change",this,a)})),!1):void n.event.add(this,"beforeactivate._change",function(a){var b=a.target;ka.test(b.nodeName)&&!n._data(b,"change")&&(n.event.add(b,"change._change",function(a){!this.parentNode||a.isSimulated||a.isTrigger||n.event.simulate("change",this.parentNode,a)}),n._data(b,"change",!0))})},handle:function(a){var b=a.target;return this!==b||a.isSimulated||a.isTrigger||"radio"!==b.type&&"checkbox"!==b.type?a.handleObj.handler.apply(this,arguments):void 0},teardown:function(){return n.event.remove(this,"._change"),!ka.test(this.nodeName)}}),l.focusin||n.each({focus:"focusin",blur:"focusout"},function(a,b){var c=function(a){n.event.simulate(b,a.target,n.event.fix(a))};n.event.special[b]={setup:function(){var d=this.ownerDocument||this,e=n._data(d,b);e||d.addEventListener(a,c,!0),n._data(d,b,(e||0)+1)},teardown:function(){var d=this.ownerDocument||this,e=n._data(d,b)-1;e?n._data(d,b,e):(d.removeEventListener(a,c,!0),n._removeData(d,b))}}}),n.fn.extend({on:function(a,b,c,d){return sa(this,a,b,c,d)},one:function(a,b,c,d){return sa(this,a,b,c,d,1)},off:function(a,b,c){var d,e;if(a&&a.preventDefault&&a.handleObj)return d=a.handleObj,n(a.delegateTarget).off(d.namespace?d.origType+"."+d.namespace:d.origType,d.selector,d.handler),this;if("object"==typeof a){for(e in a)this.off(e,b,a[e]);return this}return(b===!1||"function"==typeof b)&&(c=b,b=void 0),c===!1&&(c=qa),this.each(function(){n.event.remove(this,a,c,b)})},trigger:function(a,b){return this.each(function(){n.event.trigger(a,b,this)})},triggerHandler:function(a,b){var c=this[0];return c?n.event.trigger(a,b,c,!0):void 0}});var ta=/ jQuery\d+="(?:null|\d+)"/g,ua=new RegExp("<(?:"+ba+")[\\s/>]","i"),va=/<(?!area|br|col|embed|hr|img|input|link|meta|param)(([\w:-]+)[^>]*)\/>/gi,wa=/<script|<style|<link/i,xa=/checked\s*(?:[^=]|=\s*.checked.)/i,ya=/^true\/(.*)/,za=/^\s*<!(?:\[CDATA\[|--)|(?:\]\]|--)>\s*$/g,Aa=ca(d),Ba=Aa.appendChild(d.createElement("div"));function Ca(a,b){return n.nodeName(a,"table")&&n.nodeName(11!==b.nodeType?b:b.firstChild,"tr")?a.getElementsByTagName("tbody")[0]||a.appendChild(a.ownerDocument.createElement("tbody")):a}function Da(a){return a.type=(null!==n.find.attr(a,"type"))+"/"+a.type,a}function Ea(a){var b=ya.exec(a.type);return b?a.type=b[1]:a.removeAttribute("type"),a}function Fa(a,b){if(1===b.nodeType&&n.hasData(a)){var c,d,e,f=n._data(a),g=n._data(b,f),h=f.events;if(h){delete g.handle,g.events={};for(c in h)for(d=0,e=h[c].length;e>d;d++)n.event.add(b,c,h[c][d])}g.data&&(g.data=n.extend({},g.data))}}function Ga(a,b){var c,d,e;if(1===b.nodeType){if(c=b.nodeName.toLowerCase(),!l.noCloneEvent&&b[n.expando]){e=n._data(b);for(d in e.events)n.removeEvent(b,d,e.handle);b.removeAttribute(n.expando)}"script"===c&&b.text!==a.text?(Da(b).text=a.text,Ea(b)):"object"===c?(b.parentNode&&(b.outerHTML=a.outerHTML),l.html5Clone&&a.innerHTML&&!n.trim(b.innerHTML)&&(b.innerHTML=a.innerHTML)):"input"===c&&Z.test(a.type)?(b.defaultChecked=b.checked=a.checked,b.value!==a.value&&(b.value=a.value)):"option"===c?b.defaultSelected=b.selected=a.defaultSelected:("input"===c||"textarea"===c)&&(b.defaultValue=a.defaultValue)}}function Ha(a,b,c,d){b=f.apply([],b);var e,g,h,i,j,k,m=0,o=a.length,p=o-1,q=b[0],r=n.isFunction(q);if(r||o>1&&"string"==typeof q&&!l.checkClone&&xa.test(q))return a.each(function(e){var f=a.eq(e);r&&(b[0]=q.call(this,e,f.html())),Ha(f,b,c,d)});if(o&&(k=ja(b,a[0].ownerDocument,!1,a,d),e=k.firstChild,1===k.childNodes.length&&(k=e),e||d)){for(i=n.map(ea(k,"script"),Da),h=i.length;o>m;m++)g=k,m!==p&&(g=n.clone(g,!0,!0),h&&n.merge(i,ea(g,"script"))),c.call(a[m],g,m);if(h)for(j=i[i.length-1].ownerDocument,n.map(i,Ea),m=0;h>m;m++)g=i[m],_.test(g.type||"")&&!n._data(g,"globalEval")&&n.contains(j,g)&&(g.src?n._evalUrl&&n._evalUrl(g.src):n.globalEval((g.text||g.textContent||g.innerHTML||"").replace(za,"")));k=e=null}return a}function Ia(a,b,c){for(var d,e=b?n.filter(b,a):a,f=0;null!=(d=e[f]);f++)c||1!==d.nodeType||n.cleanData(ea(d)),d.parentNode&&(c&&n.contains(d.ownerDocument,d)&&fa(ea(d,"script")),d.parentNode.removeChild(d));return a}n.extend({htmlPrefilter:function(a){return a.replace(va,"<$1></$2>")},clone:function(a,b,c){var d,e,f,g,h,i=n.contains(a.ownerDocument,a);if(l.html5Clone||n.isXMLDoc(a)||!ua.test("<"+a.nodeName+">")?f=a.cloneNode(!0):(Ba.innerHTML=a.outerHTML,Ba.removeChild(f=Ba.firstChild)),!(l.noCloneEvent&&l.noCloneChecked||1!==a.nodeType&&11!==a.nodeType||n.isXMLDoc(a)))for(d=ea(f),h=ea(a),g=0;null!=(e=h[g]);++g)d[g]&&Ga(e,d[g]);if(b)if(c)for(h=h||ea(a),d=d||ea(f),g=0;null!=(e=h[g]);g++)Fa(e,d[g]);else Fa(a,f);return d=ea(f,"script"),d.length>0&&fa(d,!i&&ea(a,"script")),d=h=e=null,f},cleanData:function(a,b){for(var d,e,f,g,h=0,i=n.expando,j=n.cache,k=l.attributes,m=n.event.special;null!=(d=a[h]);h++)if((b||M(d))&&(f=d[i],g=f&&j[f])){if(g.events)for(e in g.events)m[e]?n.event.remove(d,e):n.removeEvent(d,e,g.handle);j[f]&&(delete j[f],k||"undefined"==typeof d.removeAttribute?d[i]=void 0:d.removeAttribute(i),c.push(f))}}}),n.fn.extend({domManip:Ha,detach:function(a){return Ia(this,a,!0)},remove:function(a){return Ia(this,a)},text:function(a){return Y(this,function(a){return void 0===a?n.text(this):this.empty().append((this[0]&&this[0].ownerDocument||d).createTextNode(a))},null,a,arguments.length)},append:function(){return Ha(this,arguments,function(a){if(1===this.nodeType||11===this.nodeType||9===this.nodeType){var b=Ca(this,a);b.appendChild(a)}})},prepend:function(){return Ha(this,arguments,function(a){if(1===this.nodeType||11===this.nodeType||9===this.nodeType){var b=Ca(this,a);b.insertBefore(a,b.firstChild)}})},before:function(){return Ha(this,arguments,function(a){this.parentNode&&this.parentNode.insertBefore(a,this)})},after:function(){return Ha(this,arguments,function(a){this.parentNode&&this.parentNode.insertBefore(a,this.nextSibling)})},empty:function(){for(var a,b=0;null!=(a=this[b]);b++){1===a.nodeType&&n.cleanData(ea(a,!1));while(a.firstChild)a.removeChild(a.firstChild);a.options&&n.nodeName(a,"select")&&(a.options.length=0)}return this},clone:function(a,b){return a=null==a?!1:a,b=null==b?a:b,this.map(function(){return n.clone(this,a,b)})},html:function(a){return Y(this,function(a){var b=this[0]||{},c=0,d=this.length;if(void 0===a)return 1===b.nodeType?b.innerHTML.replace(ta,""):void 0;if("string"==typeof a&&!wa.test(a)&&(l.htmlSerialize||!ua.test(a))&&(l.leadingWhitespace||!aa.test(a))&&!da[($.exec(a)||["",""])[1].toLowerCase()]){a=n.htmlPrefilter(a);try{for(;d>c;c++)b=this[c]||{},1===b.nodeType&&(n.cleanData(ea(b,!1)),b.innerHTML=a);b=0}catch(e){}}b&&this.empty().append(a)},null,a,arguments.length)},replaceWith:function(){var a=[];return Ha(this,arguments,function(b){var c=this.parentNode;n.inArray(this,a)<0&&(n.cleanData(ea(this)),c&&c.replaceChild(b,this))},a)}}),n.each({appendTo:"append",prependTo:"prepend",insertBefore:"before",insertAfter:"after",replaceAll:"replaceWith"},function(a,b){n.fn[a]=function(a){for(var c,d=0,e=[],f=n(a),h=f.length-1;h>=d;d++)c=d===h?this:this.clone(!0),n(f[d])[b](c),g.apply(e,c.get());return this.pushStack(e)}});var Ja,Ka={HTML:"block",BODY:"block"};function La(a,b){var c=n(b.createElement(a)).appendTo(b.body),d=n.css(c[0],"display");return c.detach(),d}function Ma(a){var b=d,c=Ka[a];return c||(c=La(a,b),"none"!==c&&c||(Ja=(Ja||n("<iframe frameborder='0' width='0' height='0'/>")).appendTo(b.documentElement),b=(Ja[0].contentWindow||Ja[0].contentDocument).document,b.write(),b.close(),c=La(a,b),Ja.detach()),Ka[a]=c),c}var Na=/^margin/,Oa=new RegExp("^("+T+")(?!px)[a-z%]+$","i"),Pa=function(a,b,c,d){var e,f,g={};for(f in b)g[f]=a.style[f],a.style[f]=b[f];e=c.apply(a,d||[]);for(f in b)a.style[f]=g[f];return e},Qa=d.documentElement;!function(){var b,c,e,f,g,h,i=d.createElement("div"),j=d.createElement("div");if(j.style){j.style.cssText="float:left;opacity:.5",l.opacity="0.5"===j.style.opacity,l.cssFloat=!!j.style.cssFloat,j.style.backgroundClip="content-box",j.cloneNode(!0).style.backgroundClip="",l.clearCloneStyle="content-box"===j.style.backgroundClip,i=d.createElement("div"),i.style.cssText="border:0;width:8px;height:0;top:0;left:-9999px;padding:0;margin-top:1px;position:absolute",j.innerHTML="",i.appendChild(j),l.boxSizing=""===j.style.boxSizing||""===j.style.MozBoxSizing||""===j.style.WebkitBoxSizing,n.extend(l,{reliableHiddenOffsets:function(){return null==b&&k(),f},boxSizingReliable:function(){return null==b&&k(),e},pixelMarginRight:function(){return null==b&&k(),c},pixelPosition:function(){return null==b&&k(),b},reliableMarginRight:function(){return null==b&&k(),g},reliableMarginLeft:function(){return null==b&&k(),h}});function k(){var k,l,m=d.documentElement;m.appendChild(i),j.style.cssText="-webkit-box-sizing:border-box;box-sizing:border-box;position:relative;display:block;margin:auto;border:1px;padding:1px;top:1%;width:50%",b=e=h=!1,c=g=!0,a.getComputedStyle&&(l=a.getComputedStyle(j),b="1%"!==(l||{}).top,h="2px"===(l||{}).marginLeft,e="4px"===(l||{width:"4px"}).width,j.style.marginRight="50%",c="4px"===(l||{marginRight:"4px"}).marginRight,k=j.appendChild(d.createElement("div")),k.style.cssText=j.style.cssText="-webkit-box-sizing:content-box;-moz-box-sizing:content-box;box-sizing:content-box;display:block;margin:0;border:0;padding:0",k.style.marginRight=k.style.width="0",j.style.width="1px",g=!parseFloat((a.getComputedStyle(k)||{}).marginRight),j.removeChild(k)),j.style.display="none",f=0===j.getClientRects().length,f&&(j.style.display="",j.innerHTML="<table><tr><td></td><td>t</td></tr></table>",k=j.getElementsByTagName("td"),k[0].style.cssText="margin:0;border:0;padding:0;display:none",f=0===k[0].offsetHeight,f&&(k[0].style.display="",k[1].style.display="none",f=0===k[0].offsetHeight)),m.removeChild(i)}}}();var Ra,Sa,Ta=/^(top|right|bottom|left)$/;a.getComputedStyle?(Ra=function(b){var c=b.ownerDocument.defaultView;return c.opener||(c=a),c.getComputedStyle(b)},Sa=function(a,b,c){var d,e,f,g,h=a.style;return c=c||Ra(a),g=c?c.getPropertyValue(b)||c[b]:void 0,c&&(""!==g||n.contains(a.ownerDocument,a)||(g=n.style(a,b)),!l.pixelMarginRight()&&Oa.test(g)&&Na.test(b)&&(d=h.width,e=h.minWidth,f=h.maxWidth,h.minWidth=h.maxWidth=h.width=g,g=c.width,h.width=d,h.minWidth=e,h.maxWidth=f)),void 0===g?g:g+""}):Qa.currentStyle&&(Ra=function(a){return a.currentStyle},Sa=function(a,b,c){var d,e,f,g,h=a.style;return c=c||Ra(a),g=c?c[b]:void 0,null==g&&h&&h[b]&&(g=h[b]),Oa.test(g)&&!Ta.test(b)&&(d=h.left,e=a.runtimeStyle,f=e&&e.left,f&&(e.left=a.currentStyle.left),h.left="fontSize"===b?"1em":g,g=h.pixelLeft+"px",h.left=d,f&&(e.left=f)),void 0===g?g:g+""||"auto"});function Ua(a,b){return{get:function(){return a()?void delete this.get:(this.get=b).apply(this,arguments)}}}var Va=/alpha\([^)]*\)/i,Wa=/opacity\s*=\s*([^)]*)/i,Xa=/^(none|table(?!-c[ea]).+)/,Ya=new RegExp("^("+T+")(.*)$","i"),Za={position:"absolute",visibility:"hidden",display:"block"},$a={letterSpacing:"0",fontWeight:"400"},_a=["Webkit","O","Moz","ms"],ab=d.createElement("div").style;function bb(a){if(a in ab)return a;var b=a.charAt(0).toUpperCase()+a.slice(1),c=_a.length;while(c--)if(a=_a[c]+b,a in ab)return a}function cb(a,b){for(var c,d,e,f=[],g=0,h=a.length;h>g;g++)d=a[g],d.style&&(f[g]=n._data(d,"olddisplay"),c=d.style.display,b?(f[g]||"none"!==c||(d.style.display=""),""===d.style.display&&W(d)&&(f[g]=n._data(d,"olddisplay",Ma(d.nodeName)))):(e=W(d),(c&&"none"!==c||!e)&&n._data(d,"olddisplay",e?c:n.css(d,"display"))));for(g=0;h>g;g++)d=a[g],d.style&&(b&&"none"!==d.style.display&&""!==d.style.display||(d.style.display=b?f[g]||"":"none"));return a}function db(a,b,c){var d=Ya.exec(b);return d?Math.max(0,d[1]-(c||0))+(d[2]||"px"):b}function eb(a,b,c,d,e){for(var f=c===(d?"border":"content")?4:"width"===b?1:0,g=0;4>f;f+=2)"margin"===c&&(g+=n.css(a,c+V[f],!0,e)),d?("content"===c&&(g-=n.css(a,"padding"+V[f],!0,e)),"margin"!==c&&(g-=n.css(a,"border"+V[f]+"Width",!0,e))):(g+=n.css(a,"padding"+V[f],!0,e),"padding"!==c&&(g+=n.css(a,"border"+V[f]+"Width",!0,e)));return g}function fb(b,c,e){var f=!0,g="width"===c?b.offsetWidth:b.offsetHeight,h=Ra(b),i=l.boxSizing&&"border-box"===n.css(b,"boxSizing",!1,h);if(d.msFullscreenElement&&a.top!==a&&b.getClientRects().length&&(g=Math.round(100*b.getBoundingClientRect()[c])),0>=g||null==g){if(g=Sa(b,c,h),(0>g||null==g)&&(g=b.style[c]),Oa.test(g))return g;f=i&&(l.boxSizingReliable()||g===b.style[c]),g=parseFloat(g)||0}return g+eb(b,c,e||(i?"border":"content"),f,h)+"px"}n.extend({cssHooks:{opacity:{get:function(a,b){if(b){var c=Sa(a,"opacity");return""===c?"1":c}}}},cssNumber:{animationIterationCount:!0,columnCount:!0,fillOpacity:!0,flexGrow:!0,flexShrink:!0,fontWeight:!0,lineHeight:!0,opacity:!0,order:!0,orphans:!0,widows:!0,zIndex:!0,zoom:!0},cssProps:{"float":l.cssFloat?"cssFloat":"styleFloat"},style:function(a,b,c,d){if(a&&3!==a.nodeType&&8!==a.nodeType&&a.style){var e,f,g,h=n.camelCase(b),i=a.style;if(b=n.cssProps[h]||(n.cssProps[h]=bb(h)||h),g=n.cssHooks[b]||n.cssHooks[h],void 0===c)return g&&"get"in g&&void 0!==(e=g.get(a,!1,d))?e:i[b];if(f=typeof c,"string"===f&&(e=U.exec(c))&&e[1]&&(c=X(a,b,e),f="number"),null!=c&&c===c&&("number"===f&&(c+=e&&e[3]||(n.cssNumber[h]?"":"px")),l.clearCloneStyle||""!==c||0!==b.indexOf("background")||(i[b]="inherit"),!(g&&"set"in g&&void 0===(c=g.set(a,c,d)))))try{i[b]=c}catch(j){}}},css:function(a,b,c,d){var e,f,g,h=n.camelCase(b);return b=n.cssProps[h]||(n.cssProps[h]=bb(h)||h),g=n.cssHooks[b]||n.cssHooks[h],g&&"get"in g&&(f=g.get(a,!0,c)),void 0===f&&(f=Sa(a,b,d)),"normal"===f&&b in $a&&(f=$a[b]),""===c||c?(e=parseFloat(f),c===!0||isFinite(e)?e||0:f):f}}),n.each(["height","width"],function(a,b){n.cssHooks[b]={get:function(a,c,d){return c?Xa.test(n.css(a,"display"))&&0===a.offsetWidth?Pa(a,Za,function(){return fb(a,b,d)}):fb(a,b,d):void 0},set:function(a,c,d){var e=d&&Ra(a);return db(a,c,d?eb(a,b,d,l.boxSizing&&"border-box"===n.css(a,"boxSizing",!1,e),e):0)}}}),l.opacity||(n.cssHooks.opacity={get:function(a,b){return Wa.test((b&&a.currentStyle?a.currentStyle.filter:a.style.filter)||"")?.01*parseFloat(RegExp.$1)+"":b?"1":""},set:function(a,b){var c=a.style,d=a.currentStyle,e=n.isNumeric(b)?"alpha(opacity="+100*b+")":"",f=d&&d.filter||c.filter||"";c.zoom=1,(b>=1||""===b)&&""===n.trim(f.replace(Va,""))&&c.removeAttribute&&(c.removeAttribute("filter"),""===b||d&&!d.filter)||(c.filter=Va.test(f)?f.replace(Va,e):f+" "+e)}}),n.cssHooks.marginRight=Ua(l.reliableMarginRight,function(a,b){return b?Pa(a,{display:"inline-block"},Sa,[a,"marginRight"]):void 0}),n.cssHooks.marginLeft=Ua(l.reliableMarginLeft,function(a,b){return b?(parseFloat(Sa(a,"marginLeft"))||(n.contains(a.ownerDocument,a)?a.getBoundingClientRect().left-Pa(a,{
+marginLeft:0},function(){return a.getBoundingClientRect().left}):0))+"px":void 0}),n.each({margin:"",padding:"",border:"Width"},function(a,b){n.cssHooks[a+b]={expand:function(c){for(var d=0,e={},f="string"==typeof c?c.split(" "):[c];4>d;d++)e[a+V[d]+b]=f[d]||f[d-2]||f[0];return e}},Na.test(a)||(n.cssHooks[a+b].set=db)}),n.fn.extend({css:function(a,b){return Y(this,function(a,b,c){var d,e,f={},g=0;if(n.isArray(b)){for(d=Ra(a),e=b.length;e>g;g++)f[b[g]]=n.css(a,b[g],!1,d);return f}return void 0!==c?n.style(a,b,c):n.css(a,b)},a,b,arguments.length>1)},show:function(){return cb(this,!0)},hide:function(){return cb(this)},toggle:function(a){return"boolean"==typeof a?a?this.show():this.hide():this.each(function(){W(this)?n(this).show():n(this).hide()})}});function gb(a,b,c,d,e){return new gb.prototype.init(a,b,c,d,e)}n.Tween=gb,gb.prototype={constructor:gb,init:function(a,b,c,d,e,f){this.elem=a,this.prop=c,this.easing=e||n.easing._default,this.options=b,this.start=this.now=this.cur(),this.end=d,this.unit=f||(n.cssNumber[c]?"":"px")},cur:function(){var a=gb.propHooks[this.prop];return a&&a.get?a.get(this):gb.propHooks._default.get(this)},run:function(a){var b,c=gb.propHooks[this.prop];return this.options.duration?this.pos=b=n.easing[this.easing](a,this.options.duration*a,0,1,this.options.duration):this.pos=b=a,this.now=(this.end-this.start)*b+this.start,this.options.step&&this.options.step.call(this.elem,this.now,this),c&&c.set?c.set(this):gb.propHooks._default.set(this),this}},gb.prototype.init.prototype=gb.prototype,gb.propHooks={_default:{get:function(a){var b;return 1!==a.elem.nodeType||null!=a.elem[a.prop]&&null==a.elem.style[a.prop]?a.elem[a.prop]:(b=n.css(a.elem,a.prop,""),b&&"auto"!==b?b:0)},set:function(a){n.fx.step[a.prop]?n.fx.step[a.prop](a):1!==a.elem.nodeType||null==a.elem.style[n.cssProps[a.prop]]&&!n.cssHooks[a.prop]?a.elem[a.prop]=a.now:n.style(a.elem,a.prop,a.now+a.unit)}}},gb.propHooks.scrollTop=gb.propHooks.scrollLeft={set:function(a){a.elem.nodeType&&a.elem.parentNode&&(a.elem[a.prop]=a.now)}},n.easing={linear:function(a){return a},swing:function(a){return.5-Math.cos(a*Math.PI)/2},_default:"swing"},n.fx=gb.prototype.init,n.fx.step={};var hb,ib,jb=/^(?:toggle|show|hide)$/,kb=/queueHooks$/;function lb(){return a.setTimeout(function(){hb=void 0}),hb=n.now()}function mb(a,b){var c,d={height:a},e=0;for(b=b?1:0;4>e;e+=2-b)c=V[e],d["margin"+c]=d["padding"+c]=a;return b&&(d.opacity=d.width=a),d}function nb(a,b,c){for(var d,e=(qb.tweeners[b]||[]).concat(qb.tweeners["*"]),f=0,g=e.length;g>f;f++)if(d=e[f].call(c,b,a))return d}function ob(a,b,c){var d,e,f,g,h,i,j,k,m=this,o={},p=a.style,q=a.nodeType&&W(a),r=n._data(a,"fxshow");c.queue||(h=n._queueHooks(a,"fx"),null==h.unqueued&&(h.unqueued=0,i=h.empty.fire,h.empty.fire=function(){h.unqueued||i()}),h.unqueued++,m.always(function(){m.always(function(){h.unqueued--,n.queue(a,"fx").length||h.empty.fire()})})),1===a.nodeType&&("height"in b||"width"in b)&&(c.overflow=[p.overflow,p.overflowX,p.overflowY],j=n.css(a,"display"),k="none"===j?n._data(a,"olddisplay")||Ma(a.nodeName):j,"inline"===k&&"none"===n.css(a,"float")&&(l.inlineBlockNeedsLayout&&"inline"!==Ma(a.nodeName)?p.zoom=1:p.display="inline-block")),c.overflow&&(p.overflow="hidden",l.shrinkWrapBlocks()||m.always(function(){p.overflow=c.overflow[0],p.overflowX=c.overflow[1],p.overflowY=c.overflow[2]}));for(d in b)if(e=b[d],jb.exec(e)){if(delete b[d],f=f||"toggle"===e,e===(q?"hide":"show")){if("show"!==e||!r||void 0===r[d])continue;q=!0}o[d]=r&&r[d]||n.style(a,d)}else j=void 0;if(n.isEmptyObject(o))"inline"===("none"===j?Ma(a.nodeName):j)&&(p.display=j);else{r?"hidden"in r&&(q=r.hidden):r=n._data(a,"fxshow",{}),f&&(r.hidden=!q),q?n(a).show():m.done(function(){n(a).hide()}),m.done(function(){var b;n._removeData(a,"fxshow");for(b in o)n.style(a,b,o[b])});for(d in o)g=nb(q?r[d]:0,d,m),d in r||(r[d]=g.start,q&&(g.end=g.start,g.start="width"===d||"height"===d?1:0))}}function pb(a,b){var c,d,e,f,g;for(c in a)if(d=n.camelCase(c),e=b[d],f=a[c],n.isArray(f)&&(e=f[1],f=a[c]=f[0]),c!==d&&(a[d]=f,delete a[c]),g=n.cssHooks[d],g&&"expand"in g){f=g.expand(f),delete a[d];for(c in f)c in a||(a[c]=f[c],b[c]=e)}else b[d]=e}function qb(a,b,c){var d,e,f=0,g=qb.prefilters.length,h=n.Deferred().always(function(){delete i.elem}),i=function(){if(e)return!1;for(var b=hb||lb(),c=Math.max(0,j.startTime+j.duration-b),d=c/j.duration||0,f=1-d,g=0,i=j.tweens.length;i>g;g++)j.tweens[g].run(f);return h.notifyWith(a,[j,f,c]),1>f&&i?c:(h.resolveWith(a,[j]),!1)},j=h.promise({elem:a,props:n.extend({},b),opts:n.extend(!0,{specialEasing:{},easing:n.easing._default},c),originalProperties:b,originalOptions:c,startTime:hb||lb(),duration:c.duration,tweens:[],createTween:function(b,c){var d=n.Tween(a,j.opts,b,c,j.opts.specialEasing[b]||j.opts.easing);return j.tweens.push(d),d},stop:function(b){var c=0,d=b?j.tweens.length:0;if(e)return this;for(e=!0;d>c;c++)j.tweens[c].run(1);return b?(h.notifyWith(a,[j,1,0]),h.resolveWith(a,[j,b])):h.rejectWith(a,[j,b]),this}}),k=j.props;for(pb(k,j.opts.specialEasing);g>f;f++)if(d=qb.prefilters[f].call(j,a,k,j.opts))return n.isFunction(d.stop)&&(n._queueHooks(j.elem,j.opts.queue).stop=n.proxy(d.stop,d)),d;return n.map(k,nb,j),n.isFunction(j.opts.start)&&j.opts.start.call(a,j),n.fx.timer(n.extend(i,{elem:a,anim:j,queue:j.opts.queue})),j.progress(j.opts.progress).done(j.opts.done,j.opts.complete).fail(j.opts.fail).always(j.opts.always)}n.Animation=n.extend(qb,{tweeners:{"*":[function(a,b){var c=this.createTween(a,b);return X(c.elem,a,U.exec(b),c),c}]},tweener:function(a,b){n.isFunction(a)?(b=a,a=["*"]):a=a.match(G);for(var c,d=0,e=a.length;e>d;d++)c=a[d],qb.tweeners[c]=qb.tweeners[c]||[],qb.tweeners[c].unshift(b)},prefilters:[ob],prefilter:function(a,b){b?qb.prefilters.unshift(a):qb.prefilters.push(a)}}),n.speed=function(a,b,c){var d=a&&"object"==typeof a?n.extend({},a):{complete:c||!c&&b||n.isFunction(a)&&a,duration:a,easing:c&&b||b&&!n.isFunction(b)&&b};return d.duration=n.fx.off?0:"number"==typeof d.duration?d.duration:d.duration in n.fx.speeds?n.fx.speeds[d.duration]:n.fx.speeds._default,(null==d.queue||d.queue===!0)&&(d.queue="fx"),d.old=d.complete,d.complete=function(){n.isFunction(d.old)&&d.old.call(this),d.queue&&n.dequeue(this,d.queue)},d},n.fn.extend({fadeTo:function(a,b,c,d){return this.filter(W).css("opacity",0).show().end().animate({opacity:b},a,c,d)},animate:function(a,b,c,d){var e=n.isEmptyObject(a),f=n.speed(b,c,d),g=function(){var b=qb(this,n.extend({},a),f);(e||n._data(this,"finish"))&&b.stop(!0)};return g.finish=g,e||f.queue===!1?this.each(g):this.queue(f.queue,g)},stop:function(a,b,c){var d=function(a){var b=a.stop;delete a.stop,b(c)};return"string"!=typeof a&&(c=b,b=a,a=void 0),b&&a!==!1&&this.queue(a||"fx",[]),this.each(function(){var b=!0,e=null!=a&&a+"queueHooks",f=n.timers,g=n._data(this);if(e)g[e]&&g[e].stop&&d(g[e]);else for(e in g)g[e]&&g[e].stop&&kb.test(e)&&d(g[e]);for(e=f.length;e--;)f[e].elem!==this||null!=a&&f[e].queue!==a||(f[e].anim.stop(c),b=!1,f.splice(e,1));(b||!c)&&n.dequeue(this,a)})},finish:function(a){return a!==!1&&(a=a||"fx"),this.each(function(){var b,c=n._data(this),d=c[a+"queue"],e=c[a+"queueHooks"],f=n.timers,g=d?d.length:0;for(c.finish=!0,n.queue(this,a,[]),e&&e.stop&&e.stop.call(this,!0),b=f.length;b--;)f[b].elem===this&&f[b].queue===a&&(f[b].anim.stop(!0),f.splice(b,1));for(b=0;g>b;b++)d[b]&&d[b].finish&&d[b].finish.call(this);delete c.finish})}}),n.each(["toggle","show","hide"],function(a,b){var c=n.fn[b];n.fn[b]=function(a,d,e){return null==a||"boolean"==typeof a?c.apply(this,arguments):this.animate(mb(b,!0),a,d,e)}}),n.each({slideDown:mb("show"),slideUp:mb("hide"),slideToggle:mb("toggle"),fadeIn:{opacity:"show"},fadeOut:{opacity:"hide"},fadeToggle:{opacity:"toggle"}},function(a,b){n.fn[a]=function(a,c,d){return this.animate(b,a,c,d)}}),n.timers=[],n.fx.tick=function(){var a,b=n.timers,c=0;for(hb=n.now();c<b.length;c++)a=b[c],a()||b[c]!==a||b.splice(c--,1);b.length||n.fx.stop(),hb=void 0},n.fx.timer=function(a){n.timers.push(a),a()?n.fx.start():n.timers.pop()},n.fx.interval=13,n.fx.start=function(){ib||(ib=a.setInterval(n.fx.tick,n.fx.interval))},n.fx.stop=function(){a.clearInterval(ib),ib=null},n.fx.speeds={slow:600,fast:200,_default:400},n.fn.delay=function(b,c){return b=n.fx?n.fx.speeds[b]||b:b,c=c||"fx",this.queue(c,function(c,d){var e=a.setTimeout(c,b);d.stop=function(){a.clearTimeout(e)}})},function(){var a,b=d.createElement("input"),c=d.createElement("div"),e=d.createElement("select"),f=e.appendChild(d.createElement("option"));c=d.createElement("div"),c.setAttribute("className","t"),c.innerHTML="  <link/><table></table><a href='/a'>a</a><input type='checkbox'/>",a=c.getElementsByTagName("a")[0],b.setAttribute("type","checkbox"),c.appendChild(b),a=c.getElementsByTagName("a")[0],a.style.cssText="top:1px",l.getSetAttribute="t"!==c.className,l.style=/top/.test(a.getAttribute("style")),l.hrefNormalized="/a"===a.getAttribute("href"),l.checkOn=!!b.value,l.optSelected=f.selected,l.enctype=!!d.createElement("form").enctype,e.disabled=!0,l.optDisabled=!f.disabled,b=d.createElement("input"),b.setAttribute("value",""),l.input=""===b.getAttribute("value"),b.value="t",b.setAttribute("type","radio"),l.radioValue="t"===b.value}();var rb=/\r/g;n.fn.extend({val:function(a){var b,c,d,e=this[0];{if(arguments.length)return d=n.isFunction(a),this.each(function(c){var e;1===this.nodeType&&(e=d?a.call(this,c,n(this).val()):a,null==e?e="":"number"==typeof e?e+="":n.isArray(e)&&(e=n.map(e,function(a){return null==a?"":a+""})),b=n.valHooks[this.type]||n.valHooks[this.nodeName.toLowerCase()],b&&"set"in b&&void 0!==b.set(this,e,"value")||(this.value=e))});if(e)return b=n.valHooks[e.type]||n.valHooks[e.nodeName.toLowerCase()],b&&"get"in b&&void 0!==(c=b.get(e,"value"))?c:(c=e.value,"string"==typeof c?c.replace(rb,""):null==c?"":c)}}}),n.extend({valHooks:{option:{get:function(a){var b=n.find.attr(a,"value");return null!=b?b:n.trim(n.text(a))}},select:{get:function(a){for(var b,c,d=a.options,e=a.selectedIndex,f="select-one"===a.type||0>e,g=f?null:[],h=f?e+1:d.length,i=0>e?h:f?e:0;h>i;i++)if(c=d[i],(c.selected||i===e)&&(l.optDisabled?!c.disabled:null===c.getAttribute("disabled"))&&(!c.parentNode.disabled||!n.nodeName(c.parentNode,"optgroup"))){if(b=n(c).val(),f)return b;g.push(b)}return g},set:function(a,b){var c,d,e=a.options,f=n.makeArray(b),g=e.length;while(g--)if(d=e[g],n.inArray(n.valHooks.option.get(d),f)>=0)try{d.selected=c=!0}catch(h){d.scrollHeight}else d.selected=!1;return c||(a.selectedIndex=-1),e}}}}),n.each(["radio","checkbox"],function(){n.valHooks[this]={set:function(a,b){return n.isArray(b)?a.checked=n.inArray(n(a).val(),b)>-1:void 0}},l.checkOn||(n.valHooks[this].get=function(a){return null===a.getAttribute("value")?"on":a.value})});var sb,tb,ub=n.expr.attrHandle,vb=/^(?:checked|selected)$/i,wb=l.getSetAttribute,xb=l.input;n.fn.extend({attr:function(a,b){return Y(this,n.attr,a,b,arguments.length>1)},removeAttr:function(a){return this.each(function(){n.removeAttr(this,a)})}}),n.extend({attr:function(a,b,c){var d,e,f=a.nodeType;if(3!==f&&8!==f&&2!==f)return"undefined"==typeof a.getAttribute?n.prop(a,b,c):(1===f&&n.isXMLDoc(a)||(b=b.toLowerCase(),e=n.attrHooks[b]||(n.expr.match.bool.test(b)?tb:sb)),void 0!==c?null===c?void n.removeAttr(a,b):e&&"set"in e&&void 0!==(d=e.set(a,c,b))?d:(a.setAttribute(b,c+""),c):e&&"get"in e&&null!==(d=e.get(a,b))?d:(d=n.find.attr(a,b),null==d?void 0:d))},attrHooks:{type:{set:function(a,b){if(!l.radioValue&&"radio"===b&&n.nodeName(a,"input")){var c=a.value;return a.setAttribute("type",b),c&&(a.value=c),b}}}},removeAttr:function(a,b){var c,d,e=0,f=b&&b.match(G);if(f&&1===a.nodeType)while(c=f[e++])d=n.propFix[c]||c,n.expr.match.bool.test(c)?xb&&wb||!vb.test(c)?a[d]=!1:a[n.camelCase("default-"+c)]=a[d]=!1:n.attr(a,c,""),a.removeAttribute(wb?c:d)}}),tb={set:function(a,b,c){return b===!1?n.removeAttr(a,c):xb&&wb||!vb.test(c)?a.setAttribute(!wb&&n.propFix[c]||c,c):a[n.camelCase("default-"+c)]=a[c]=!0,c}},n.each(n.expr.match.bool.source.match(/\w+/g),function(a,b){var c=ub[b]||n.find.attr;xb&&wb||!vb.test(b)?ub[b]=function(a,b,d){var e,f;return d||(f=ub[b],ub[b]=e,e=null!=c(a,b,d)?b.toLowerCase():null,ub[b]=f),e}:ub[b]=function(a,b,c){return c?void 0:a[n.camelCase("default-"+b)]?b.toLowerCase():null}}),xb&&wb||(n.attrHooks.value={set:function(a,b,c){return n.nodeName(a,"input")?void(a.defaultValue=b):sb&&sb.set(a,b,c)}}),wb||(sb={set:function(a,b,c){var d=a.getAttributeNode(c);return d||a.setAttributeNode(d=a.ownerDocument.createAttribute(c)),d.value=b+="","value"===c||b===a.getAttribute(c)?b:void 0}},ub.id=ub.name=ub.coords=function(a,b,c){var d;return c?void 0:(d=a.getAttributeNode(b))&&""!==d.value?d.value:null},n.valHooks.button={get:function(a,b){var c=a.getAttributeNode(b);return c&&c.specified?c.value:void 0},set:sb.set},n.attrHooks.contenteditable={set:function(a,b,c){sb.set(a,""===b?!1:b,c)}},n.each(["width","height"],function(a,b){n.attrHooks[b]={set:function(a,c){return""===c?(a.setAttribute(b,"auto"),c):void 0}}})),l.style||(n.attrHooks.style={get:function(a){return a.style.cssText||void 0},set:function(a,b){return a.style.cssText=b+""}});var yb=/^(?:input|select|textarea|button|object)$/i,zb=/^(?:a|area)$/i;n.fn.extend({prop:function(a,b){return Y(this,n.prop,a,b,arguments.length>1)},removeProp:function(a){return a=n.propFix[a]||a,this.each(function(){try{this[a]=void 0,delete this[a]}catch(b){}})}}),n.extend({prop:function(a,b,c){var d,e,f=a.nodeType;if(3!==f&&8!==f&&2!==f)return 1===f&&n.isXMLDoc(a)||(b=n.propFix[b]||b,e=n.propHooks[b]),void 0!==c?e&&"set"in e&&void 0!==(d=e.set(a,c,b))?d:a[b]=c:e&&"get"in e&&null!==(d=e.get(a,b))?d:a[b]},propHooks:{tabIndex:{get:function(a){var b=n.find.attr(a,"tabindex");return b?parseInt(b,10):yb.test(a.nodeName)||zb.test(a.nodeName)&&a.href?0:-1}}},propFix:{"for":"htmlFor","class":"className"}}),l.hrefNormalized||n.each(["href","src"],function(a,b){n.propHooks[b]={get:function(a){return a.getAttribute(b,4)}}}),l.optSelected||(n.propHooks.selected={get:function(a){var b=a.parentNode;return b&&(b.selectedIndex,b.parentNode&&b.parentNode.selectedIndex),null}}),n.each(["tabIndex","readOnly","maxLength","cellSpacing","cellPadding","rowSpan","colSpan","useMap","frameBorder","contentEditable"],function(){n.propFix[this.toLowerCase()]=this}),l.enctype||(n.propFix.enctype="encoding");var Ab=/[\t\r\n\f]/g;function Bb(a){return n.attr(a,"class")||""}n.fn.extend({addClass:function(a){var b,c,d,e,f,g,h,i=0;if(n.isFunction(a))return this.each(function(b){n(this).addClass(a.call(this,b,Bb(this)))});if("string"==typeof a&&a){b=a.match(G)||[];while(c=this[i++])if(e=Bb(c),d=1===c.nodeType&&(" "+e+" ").replace(Ab," ")){g=0;while(f=b[g++])d.indexOf(" "+f+" ")<0&&(d+=f+" ");h=n.trim(d),e!==h&&n.attr(c,"class",h)}}return this},removeClass:function(a){var b,c,d,e,f,g,h,i=0;if(n.isFunction(a))return this.each(function(b){n(this).removeClass(a.call(this,b,Bb(this)))});if(!arguments.length)return this.attr("class","");if("string"==typeof a&&a){b=a.match(G)||[];while(c=this[i++])if(e=Bb(c),d=1===c.nodeType&&(" "+e+" ").replace(Ab," ")){g=0;while(f=b[g++])while(d.indexOf(" "+f+" ")>-1)d=d.replace(" "+f+" "," ");h=n.trim(d),e!==h&&n.attr(c,"class",h)}}return this},toggleClass:function(a,b){var c=typeof a;return"boolean"==typeof b&&"string"===c?b?this.addClass(a):this.removeClass(a):n.isFunction(a)?this.each(function(c){n(this).toggleClass(a.call(this,c,Bb(this),b),b)}):this.each(function(){var b,d,e,f;if("string"===c){d=0,e=n(this),f=a.match(G)||[];while(b=f[d++])e.hasClass(b)?e.removeClass(b):e.addClass(b)}else(void 0===a||"boolean"===c)&&(b=Bb(this),b&&n._data(this,"__className__",b),n.attr(this,"class",b||a===!1?"":n._data(this,"__className__")||""))})},hasClass:function(a){var b,c,d=0;b=" "+a+" ";while(c=this[d++])if(1===c.nodeType&&(" "+Bb(c)+" ").replace(Ab," ").indexOf(b)>-1)return!0;return!1}}),n.each("blur focus focusin focusout load resize scroll unload click dblclick mousedown mouseup mousemove mouseover mouseout mouseenter mouseleave change select submit keydown keypress keyup error contextmenu".split(" "),function(a,b){n.fn[b]=function(a,c){return arguments.length>0?this.on(b,null,a,c):this.trigger(b)}}),n.fn.extend({hover:function(a,b){return this.mouseenter(a).mouseleave(b||a)}});var Cb=a.location,Db=n.now(),Eb=/\?/,Fb=/(,)|(\[|{)|(}|])|"(?:[^"\\\r\n]|\\["\\\/bfnrt]|\\u[\da-fA-F]{4})*"\s*:?|true|false|null|-?(?!0\d)\d+(?:\.\d+|)(?:[eE][+-]?\d+|)/g;n.parseJSON=function(b){if(a.JSON&&a.JSON.parse)return a.JSON.parse(b+"");var c,d=null,e=n.trim(b+"");return e&&!n.trim(e.replace(Fb,function(a,b,e,f){return c&&b&&(d=0),0===d?a:(c=e||b,d+=!f-!e,"")}))?Function("return "+e)():n.error("Invalid JSON: "+b)},n.parseXML=function(b){var c,d;if(!b||"string"!=typeof b)return null;try{a.DOMParser?(d=new a.DOMParser,c=d.parseFromString(b,"text/xml")):(c=new a.ActiveXObject("Microsoft.XMLDOM"),c.async="false",c.loadXML(b))}catch(e){c=void 0}return c&&c.documentElement&&!c.getElementsByTagName("parsererror").length||n.error("Invalid XML: "+b),c};var Gb=/#.*$/,Hb=/([?&])_=[^&]*/,Ib=/^(.*?):[ \t]*([^\r\n]*)\r?$/gm,Jb=/^(?:about|app|app-storage|.+-extension|file|res|widget):$/,Kb=/^(?:GET|HEAD)$/,Lb=/^\/\//,Mb=/^([\w.+-]+:)(?:\/\/(?:[^\/?#]*@|)([^\/?#:]*)(?::(\d+)|)|)/,Nb={},Ob={},Pb="*/".concat("*"),Qb=Cb.href,Rb=Mb.exec(Qb.toLowerCase())||[];function Sb(a){return function(b,c){"string"!=typeof b&&(c=b,b="*");var d,e=0,f=b.toLowerCase().match(G)||[];if(n.isFunction(c))while(d=f[e++])"+"===d.charAt(0)?(d=d.slice(1)||"*",(a[d]=a[d]||[]).unshift(c)):(a[d]=a[d]||[]).push(c)}}function Tb(a,b,c,d){var e={},f=a===Ob;function g(h){var i;return e[h]=!0,n.each(a[h]||[],function(a,h){var j=h(b,c,d);return"string"!=typeof j||f||e[j]?f?!(i=j):void 0:(b.dataTypes.unshift(j),g(j),!1)}),i}return g(b.dataTypes[0])||!e["*"]&&g("*")}function Ub(a,b){var c,d,e=n.ajaxSettings.flatOptions||{};for(d in b)void 0!==b[d]&&((e[d]?a:c||(c={}))[d]=b[d]);return c&&n.extend(!0,a,c),a}function Vb(a,b,c){var d,e,f,g,h=a.contents,i=a.dataTypes;while("*"===i[0])i.shift(),void 0===e&&(e=a.mimeType||b.getResponseHeader("Content-Type"));if(e)for(g in h)if(h[g]&&h[g].test(e)){i.unshift(g);break}if(i[0]in c)f=i[0];else{for(g in c){if(!i[0]||a.converters[g+" "+i[0]]){f=g;break}d||(d=g)}f=f||d}return f?(f!==i[0]&&i.unshift(f),c[f]):void 0}function Wb(a,b,c,d){var e,f,g,h,i,j={},k=a.dataTypes.slice();if(k[1])for(g in a.converters)j[g.toLowerCase()]=a.converters[g];f=k.shift();while(f)if(a.responseFields[f]&&(c[a.responseFields[f]]=b),!i&&d&&a.dataFilter&&(b=a.dataFilter(b,a.dataType)),i=f,f=k.shift())if("*"===f)f=i;else if("*"!==i&&i!==f){if(g=j[i+" "+f]||j["* "+f],!g)for(e in j)if(h=e.split(" "),h[1]===f&&(g=j[i+" "+h[0]]||j["* "+h[0]])){g===!0?g=j[e]:j[e]!==!0&&(f=h[0],k.unshift(h[1]));break}if(g!==!0)if(g&&a["throws"])b=g(b);else try{b=g(b)}catch(l){return{state:"parsererror",error:g?l:"No conversion from "+i+" to "+f}}}return{state:"success",data:b}}n.extend({active:0,lastModified:{},etag:{},ajaxSettings:{url:Qb,type:"GET",isLocal:Jb.test(Rb[1]),global:!0,processData:!0,async:!0,contentType:"application/x-www-form-urlencoded; charset=UTF-8",accepts:{"*":Pb,text:"text/plain",html:"text/html",xml:"application/xml, text/xml",json:"application/json, text/javascript"},contents:{xml:/\bxml\b/,html:/\bhtml/,json:/\bjson\b/},responseFields:{xml:"responseXML",text:"responseText",json:"responseJSON"},converters:{"* text":String,"text html":!0,"text json":n.parseJSON,"text xml":n.parseXML},flatOptions:{url:!0,context:!0}},ajaxSetup:function(a,b){return b?Ub(Ub(a,n.ajaxSettings),b):Ub(n.ajaxSettings,a)},ajaxPrefilter:Sb(Nb),ajaxTransport:Sb(Ob),ajax:function(b,c){"object"==typeof b&&(c=b,b=void 0),c=c||{};var d,e,f,g,h,i,j,k,l=n.ajaxSetup({},c),m=l.context||l,o=l.context&&(m.nodeType||m.jquery)?n(m):n.event,p=n.Deferred(),q=n.Callbacks("once memory"),r=l.statusCode||{},s={},t={},u=0,v="canceled",w={readyState:0,getResponseHeader:function(a){var b;if(2===u){if(!k){k={};while(b=Ib.exec(g))k[b[1].toLowerCase()]=b[2]}b=k[a.toLowerCase()]}return null==b?null:b},getAllResponseHeaders:function(){return 2===u?g:null},setRequestHeader:function(a,b){var c=a.toLowerCase();return u||(a=t[c]=t[c]||a,s[a]=b),this},overrideMimeType:function(a){return u||(l.mimeType=a),this},statusCode:function(a){var b;if(a)if(2>u)for(b in a)r[b]=[r[b],a[b]];else w.always(a[w.status]);return this},abort:function(a){var b=a||v;return j&&j.abort(b),y(0,b),this}};if(p.promise(w).complete=q.add,w.success=w.done,w.error=w.fail,l.url=((b||l.url||Qb)+"").replace(Gb,"").replace(Lb,Rb[1]+"//"),l.type=c.method||c.type||l.method||l.type,l.dataTypes=n.trim(l.dataType||"*").toLowerCase().match(G)||[""],null==l.crossDomain&&(d=Mb.exec(l.url.toLowerCase()),l.crossDomain=!(!d||d[1]===Rb[1]&&d[2]===Rb[2]&&(d[3]||("http:"===d[1]?"80":"443"))===(Rb[3]||("http:"===Rb[1]?"80":"443")))),l.data&&l.processData&&"string"!=typeof l.data&&(l.data=n.param(l.data,l.traditional)),Tb(Nb,l,c,w),2===u)return w;i=n.event&&l.global,i&&0===n.active++&&n.event.trigger("ajaxStart"),l.type=l.type.toUpperCase(),l.hasContent=!Kb.test(l.type),f=l.url,l.hasContent||(l.data&&(f=l.url+=(Eb.test(f)?"&":"?")+l.data,delete l.data),l.cache===!1&&(l.url=Hb.test(f)?f.replace(Hb,"$1_="+Db++):f+(Eb.test(f)?"&":"?")+"_="+Db++)),l.ifModified&&(n.lastModified[f]&&w.setRequestHeader("If-Modified-Since",n.lastModified[f]),n.etag[f]&&w.setRequestHeader("If-None-Match",n.etag[f])),(l.data&&l.hasContent&&l.contentType!==!1||c.contentType)&&w.setRequestHeader("Content-Type",l.contentType),w.setRequestHeader("Accept",l.dataTypes[0]&&l.accepts[l.dataTypes[0]]?l.accepts[l.dataTypes[0]]+("*"!==l.dataTypes[0]?", "+Pb+"; q=0.01":""):l.accepts["*"]);for(e in l.headers)w.setRequestHeader(e,l.headers[e]);if(l.beforeSend&&(l.beforeSend.call(m,w,l)===!1||2===u))return w.abort();v="abort";for(e in{success:1,error:1,complete:1})w[e](l[e]);if(j=Tb(Ob,l,c,w)){if(w.readyState=1,i&&o.trigger("ajaxSend",[w,l]),2===u)return w;l.async&&l.timeout>0&&(h=a.setTimeout(function(){w.abort("timeout")},l.timeout));try{u=1,j.send(s,y)}catch(x){if(!(2>u))throw x;y(-1,x)}}else y(-1,"No Transport");function y(b,c,d,e){var k,s,t,v,x,y=c;2!==u&&(u=2,h&&a.clearTimeout(h),j=void 0,g=e||"",w.readyState=b>0?4:0,k=b>=200&&300>b||304===b,d&&(v=Vb(l,w,d)),v=Wb(l,v,w,k),k?(l.ifModified&&(x=w.getResponseHeader("Last-Modified"),x&&(n.lastModified[f]=x),x=w.getResponseHeader("etag"),x&&(n.etag[f]=x)),204===b||"HEAD"===l.type?y="nocontent":304===b?y="notmodified":(y=v.state,s=v.data,t=v.error,k=!t)):(t=y,(b||!y)&&(y="error",0>b&&(b=0))),w.status=b,w.statusText=(c||y)+"",k?p.resolveWith(m,[s,y,w]):p.rejectWith(m,[w,y,t]),w.statusCode(r),r=void 0,i&&o.trigger(k?"ajaxSuccess":"ajaxError",[w,l,k?s:t]),q.fireWith(m,[w,y]),i&&(o.trigger("ajaxComplete",[w,l]),--n.active||n.event.trigger("ajaxStop")))}return w},getJSON:function(a,b,c){return n.get(a,b,c,"json")},getScript:function(a,b){return n.get(a,void 0,b,"script")}}),n.each(["get","post"],function(a,b){n[b]=function(a,c,d,e){return n.isFunction(c)&&(e=e||d,d=c,c=void 0),n.ajax(n.extend({url:a,type:b,dataType:e,data:c,success:d},n.isPlainObject(a)&&a))}}),n._evalUrl=function(a){return n.ajax({url:a,type:"GET",dataType:"script",cache:!0,async:!1,global:!1,"throws":!0})},n.fn.extend({wrapAll:function(a){if(n.isFunction(a))return this.each(function(b){n(this).wrapAll(a.call(this,b))});if(this[0]){var b=n(a,this[0].ownerDocument).eq(0).clone(!0);this[0].parentNode&&b.insertBefore(this[0]),b.map(function(){var a=this;while(a.firstChild&&1===a.firstChild.nodeType)a=a.firstChild;return a}).append(this)}return this},wrapInner:function(a){return n.isFunction(a)?this.each(function(b){n(this).wrapInner(a.call(this,b))}):this.each(function(){var b=n(this),c=b.contents();c.length?c.wrapAll(a):b.append(a)})},wrap:function(a){var b=n.isFunction(a);return this.each(function(c){n(this).wrapAll(b?a.call(this,c):a)})},unwrap:function(){return this.parent().each(function(){n.nodeName(this,"body")||n(this).replaceWith(this.childNodes)}).end()}});function Xb(a){return a.style&&a.style.display||n.css(a,"display")}function Yb(a){while(a&&1===a.nodeType){if("none"===Xb(a)||"hidden"===a.type)return!0;a=a.parentNode}return!1}n.expr.filters.hidden=function(a){return l.reliableHiddenOffsets()?a.offsetWidth<=0&&a.offsetHeight<=0&&!a.getClientRects().length:Yb(a)},n.expr.filters.visible=function(a){return!n.expr.filters.hidden(a)};var Zb=/%20/g,$b=/\[\]$/,_b=/\r?\n/g,ac=/^(?:submit|button|image|reset|file)$/i,bc=/^(?:input|select|textarea|keygen)/i;function cc(a,b,c,d){var e;if(n.isArray(b))n.each(b,function(b,e){c||$b.test(a)?d(a,e):cc(a+"["+("object"==typeof e&&null!=e?b:"")+"]",e,c,d)});else if(c||"object"!==n.type(b))d(a,b);else for(e in b)cc(a+"["+e+"]",b[e],c,d)}n.param=function(a,b){var c,d=[],e=function(a,b){b=n.isFunction(b)?b():null==b?"":b,d[d.length]=encodeURIComponent(a)+"="+encodeURIComponent(b)};if(void 0===b&&(b=n.ajaxSettings&&n.ajaxSettings.traditional),n.isArray(a)||a.jquery&&!n.isPlainObject(a))n.each(a,function(){e(this.name,this.value)});else for(c in a)cc(c,a[c],b,e);return d.join("&").replace(Zb,"+")},n.fn.extend({serialize:function(){return n.param(this.serializeArray())},serializeArray:function(){return this.map(function(){var a=n.prop(this,"elements");return a?n.makeArray(a):this}).filter(function(){var a=this.type;return this.name&&!n(this).is(":disabled")&&bc.test(this.nodeName)&&!ac.test(a)&&(this.checked||!Z.test(a))}).map(function(a,b){var c=n(this).val();return null==c?null:n.isArray(c)?n.map(c,function(a){return{name:b.name,value:a.replace(_b,"\r\n")}}):{name:b.name,value:c.replace(_b,"\r\n")}}).get()}}),n.ajaxSettings.xhr=void 0!==a.ActiveXObject?function(){return this.isLocal?hc():d.documentMode>8?gc():/^(get|post|head|put|delete|options)$/i.test(this.type)&&gc()||hc()}:gc;var dc=0,ec={},fc=n.ajaxSettings.xhr();a.attachEvent&&a.attachEvent("onunload",function(){for(var a in ec)ec[a](void 0,!0)}),l.cors=!!fc&&"withCredentials"in fc,fc=l.ajax=!!fc,fc&&n.ajaxTransport(function(b){if(!b.crossDomain||l.cors){var c;return{send:function(d,e){var f,g=b.xhr(),h=++dc;if(g.open(b.type,b.url,b.async,b.username,b.password),b.xhrFields)for(f in b.xhrFields)g[f]=b.xhrFields[f];b.mimeType&&g.overrideMimeType&&g.overrideMimeType(b.mimeType),b.crossDomain||d["X-Requested-With"]||(d["X-Requested-With"]="XMLHttpRequest");for(f in d)void 0!==d[f]&&g.setRequestHeader(f,d[f]+"");g.send(b.hasContent&&b.data||null),c=function(a,d){var f,i,j;if(c&&(d||4===g.readyState))if(delete ec[h],c=void 0,g.onreadystatechange=n.noop,d)4!==g.readyState&&g.abort();else{j={},f=g.status,"string"==typeof g.responseText&&(j.text=g.responseText);try{i=g.statusText}catch(k){i=""}f||!b.isLocal||b.crossDomain?1223===f&&(f=204):f=j.text?200:404}j&&e(f,i,j,g.getAllResponseHeaders())},b.async?4===g.readyState?a.setTimeout(c):g.onreadystatechange=ec[h]=c:c()},abort:function(){c&&c(void 0,!0)}}}});function gc(){try{return new a.XMLHttpRequest}catch(b){}}function hc(){try{return new a.ActiveXObject("Microsoft.XMLHTTP")}catch(b){}}n.ajaxPrefilter(function(a){a.crossDomain&&(a.contents.script=!1)}),n.ajaxSetup({accepts:{script:"text/javascript, application/javascript, application/ecmascript, application/x-ecmascript"},contents:{script:/\b(?:java|ecma)script\b/},converters:{"text script":function(a){return n.globalEval(a),a}}}),n.ajaxPrefilter("script",function(a){void 0===a.cache&&(a.cache=!1),a.crossDomain&&(a.type="GET",a.global=!1)}),n.ajaxTransport("script",function(a){if(a.crossDomain){var b,c=d.head||n("head")[0]||d.documentElement;return{send:function(e,f){b=d.createElement("script"),b.async=!0,a.scriptCharset&&(b.charset=a.scriptCharset),b.src=a.url,b.onload=b.onreadystatechange=function(a,c){(c||!b.readyState||/loaded|complete/.test(b.readyState))&&(b.onload=b.onreadystatechange=null,b.parentNode&&b.parentNode.removeChild(b),b=null,c||f(200,"success"))},c.insertBefore(b,c.firstChild)},abort:function(){b&&b.onload(void 0,!0)}}}});var ic=[],jc=/(=)\?(?=&|$)|\?\?/;n.ajaxSetup({jsonp:"callback",jsonpCallback:function(){var a=ic.pop()||n.expando+"_"+Db++;return this[a]=!0,a}}),n.ajaxPrefilter("json jsonp",function(b,c,d){var e,f,g,h=b.jsonp!==!1&&(jc.test(b.url)?"url":"string"==typeof b.data&&0===(b.contentType||"").indexOf("application/x-www-form-urlencoded")&&jc.test(b.data)&&"data");return h||"jsonp"===b.dataTypes[0]?(e=b.jsonpCallback=n.isFunction(b.jsonpCallback)?b.jsonpCallback():b.jsonpCallback,h?b[h]=b[h].replace(jc,"$1"+e):b.jsonp!==!1&&(b.url+=(Eb.test(b.url)?"&":"?")+b.jsonp+"="+e),b.converters["script json"]=function(){return g||n.error(e+" was not called"),g[0]},b.dataTypes[0]="json",f=a[e],a[e]=function(){g=arguments},d.always(function(){void 0===f?n(a).removeProp(e):a[e]=f,b[e]&&(b.jsonpCallback=c.jsonpCallback,ic.push(e)),g&&n.isFunction(f)&&f(g[0]),g=f=void 0}),"script"):void 0}),l.createHTMLDocument=function(){if(!d.implementation.createHTMLDocument)return!1;var a=d.implementation.createHTMLDocument("");return a.body.innerHTML="<form></form><form></form>",2===a.body.childNodes.length}(),n.parseHTML=function(a,b,c){if(!a||"string"!=typeof a)return null;"boolean"==typeof b&&(c=b,b=!1),b=b||(l.createHTMLDocument?d.implementation.createHTMLDocument(""):d);var e=x.exec(a),f=!c&&[];return e?[b.createElement(e[1])]:(e=ja([a],b,f),f&&f.length&&n(f).remove(),n.merge([],e.childNodes))};var kc=n.fn.load;n.fn.load=function(a,b,c){if("string"!=typeof a&&kc)return kc.apply(this,arguments);var d,e,f,g=this,h=a.indexOf(" ");return h>-1&&(d=n.trim(a.slice(h,a.length)),a=a.slice(0,h)),n.isFunction(b)?(c=b,b=void 0):b&&"object"==typeof b&&(e="POST"),g.length>0&&n.ajax({url:a,type:e||"GET",dataType:"html",data:b}).done(function(a){f=arguments,g.html(d?n("<div>").append(n.parseHTML(a)).find(d):a)}).always(c&&function(a,b){g.each(function(){c.apply(g,f||[a.responseText,b,a])})}),this},n.each(["ajaxStart","ajaxStop","ajaxComplete","ajaxError","ajaxSuccess","ajaxSend"],function(a,b){n.fn[b]=function(a){return this.on(b,a)}}),n.expr.filters.animated=function(a){return n.grep(n.timers,function(b){return a===b.elem}).length};function lc(a){return n.isWindow(a)?a:9===a.nodeType?a.defaultView||a.parentWindow:!1}n.offset={setOffset:function(a,b,c){var d,e,f,g,h,i,j,k=n.css(a,"position"),l=n(a),m={};"static"===k&&(a.style.position="relative"),h=l.offset(),f=n.css(a,"top"),i=n.css(a,"left"),j=("absolute"===k||"fixed"===k)&&n.inArray("auto",[f,i])>-1,j?(d=l.position(),g=d.top,e=d.left):(g=parseFloat(f)||0,e=parseFloat(i)||0),n.isFunction(b)&&(b=b.call(a,c,n.extend({},h))),null!=b.top&&(m.top=b.top-h.top+g),null!=b.left&&(m.left=b.left-h.left+e),"using"in b?b.using.call(a,m):l.css(m)}},n.fn.extend({offset:function(a){if(arguments.length)return void 0===a?this:this.each(function(b){n.offset.setOffset(this,a,b)});var b,c,d={top:0,left:0},e=this[0],f=e&&e.ownerDocument;if(f)return b=f.documentElement,n.contains(b,e)?("undefined"!=typeof e.getBoundingClientRect&&(d=e.getBoundingClientRect()),c=lc(f),{top:d.top+(c.pageYOffset||b.scrollTop)-(b.clientTop||0),left:d.left+(c.pageXOffset||b.scrollLeft)-(b.clientLeft||0)}):d},position:function(){if(this[0]){var a,b,c={top:0,left:0},d=this[0];return"fixed"===n.css(d,"position")?b=d.getBoundingClientRect():(a=this.offsetParent(),b=this.offset(),n.nodeName(a[0],"html")||(c=a.offset()),c.top+=n.css(a[0],"borderTopWidth",!0)-a.scrollTop(),c.left+=n.css(a[0],"borderLeftWidth",!0)-a.scrollLeft()),{top:b.top-c.top-n.css(d,"marginTop",!0),left:b.left-c.left-n.css(d,"marginLeft",!0)}}},offsetParent:function(){return this.map(function(){var a=this.offsetParent;while(a&&!n.nodeName(a,"html")&&"static"===n.css(a,"position"))a=a.offsetParent;return a||Qa})}}),n.each({scrollLeft:"pageXOffset",scrollTop:"pageYOffset"},function(a,b){var c=/Y/.test(b);n.fn[a]=function(d){return Y(this,function(a,d,e){var f=lc(a);return void 0===e?f?b in f?f[b]:f.document.documentElement[d]:a[d]:void(f?f.scrollTo(c?n(f).scrollLeft():e,c?e:n(f).scrollTop()):a[d]=e)},a,d,arguments.length,null)}}),n.each(["top","left"],function(a,b){
+n.cssHooks[b]=Ua(l.pixelPosition,function(a,c){return c?(c=Sa(a,b),Oa.test(c)?n(a).position()[b]+"px":c):void 0})}),n.each({Height:"height",Width:"width"},function(a,b){n.each({padding:"inner"+a,content:b,"":"outer"+a},function(c,d){n.fn[d]=function(d,e){var f=arguments.length&&(c||"boolean"!=typeof d),g=c||(d===!0||e===!0?"margin":"border");return Y(this,function(b,c,d){var e;return n.isWindow(b)?b.document.documentElement["client"+a]:9===b.nodeType?(e=b.documentElement,Math.max(b.body["scroll"+a],e["scroll"+a],b.body["offset"+a],e["offset"+a],e["client"+a])):void 0===d?n.css(b,c,g):n.style(b,c,d,g)},b,f?d:void 0,f,null)}})}),n.fn.extend({bind:function(a,b,c){return this.on(a,null,b,c)},unbind:function(a,b){return this.off(a,null,b)},delegate:function(a,b,c,d){return this.on(b,a,c,d)},undelegate:function(a,b,c){return 1===arguments.length?this.off(a,"**"):this.off(b,a||"**",c)}}),n.fn.size=function(){return this.length},n.fn.andSelf=n.fn.addBack,"function"==typeof define&&define.amd&&define("jquery",[],function(){return n});var mc=a.jQuery,nc=a.$;return n.noConflict=function(b){return a.$===n&&(a.$=nc),b&&a.jQuery===n&&(a.jQuery=mc),n},b||(a.jQuery=a.$=n),n});
diff --git js/lib/jquery/jquery-1.12.0.min.map js/lib/jquery/jquery-1.12.0.min.map
new file mode 100644
index 0000000..be41d37
--- /dev/null
+++ js/lib/jquery/jquery-1.12.0.min.map
@@ -0,0 +1 @@
+{"version":3,"sources":["jquery.js"],"names":["global","factory","module","exports","document","w","Error","window","this","noGlobal","deletedIds","slice","concat","push","indexOf","class2type","toString","hasOwn","hasOwnProperty","support","version","jQuery","selector","context","fn","init","rtrim","rmsPrefix","rdashAlpha","fcamelCase","all","letter","toUpperCase","prototype","jquery","constructor","length","toArray","call","get","num","pushStack","elems","ret","merge","prevObject","each","callback","map","elem","i","apply","arguments","first","eq","last","len","j","end","sort","splice","extend","src","copyIsArray","copy","name","options","clone","target","deep","isFunction","isPlainObject","isArray","undefined","expando","Math","random","replace","isReady","error","msg","noop","obj","type","Array","isWindow","isNumeric","realStringObj","parseFloat","isEmptyObject","key","nodeType","e","ownFirst","globalEval","data","trim","execScript","camelCase","string","nodeName","toLowerCase","isArrayLike","text","makeArray","arr","results","Object","inArray","max","second","grep","invert","callbackInverse","matches","callbackExpect","arg","value","guid","proxy","args","tmp","now","Date","Symbol","iterator","split","Sizzle","Expr","getText","isXML","tokenize","compile","select","outermostContext","sortInput","hasDuplicate","setDocument","docElem","documentIsHTML","rbuggyQSA","rbuggyMatches","contains","preferredDoc","dirruns","done","classCache","createCache","tokenCache","compilerCache","sortOrder","a","b","MAX_NEGATIVE","pop","push_native","list","booleans","whitespace","identifier","attributes","pseudos","rwhitespace","RegExp","rcomma","rcombinators","rattributeQuotes","rpseudo","ridentifier","matchExpr","ID","CLASS","TAG","ATTR","PSEUDO","CHILD","bool","needsContext","rinputs","rheader","rnative","rquickExpr","rsibling","rescape","runescape","funescape","_","escaped","escapedWhitespace","high","String","fromCharCode","unloadHandler","childNodes","els","seed","m","nid","nidselect","match","groups","newSelector","newContext","ownerDocument","exec","getElementById","id","getElementsByTagName","getElementsByClassName","qsa","test","getAttribute","setAttribute","toSelector","join","testContext","parentNode","querySelectorAll","qsaError","removeAttribute","keys","cache","cacheLength","shift","markFunction","assert","div","createElement","removeChild","addHandle","attrs","handler","attrHandle","siblingCheck","cur","diff","sourceIndex","nextSibling","createInputPseudo","createButtonPseudo","createPositionalPseudo","argument","matchIndexes","documentElement","node","hasCompare","parent","doc","defaultView","top","addEventListener","attachEvent","className","appendChild","createComment","getById","getElementsByName","find","filter","attrId","getAttributeNode","tag","innerHTML","input","matchesSelector","webkitMatchesSelector","mozMatchesSelector","oMatchesSelector","msMatchesSelector","disconnectedMatch","compareDocumentPosition","adown","bup","compare","sortDetached","aup","ap","bp","unshift","expr","elements","attr","val","specified","uniqueSort","duplicates","detectDuplicates","sortStable","textContent","firstChild","nodeValue","selectors","createPseudo","relative",">","dir"," ","+","~","preFilter","excess","unquoted","nodeNameSelector","pattern","operator","check","result","what","simple","forward","ofType","xml","uniqueCache","outerCache","nodeIndex","start","useCache","lastChild","uniqueID","pseudo","setFilters","idx","matched","not","matcher","unmatched","has","innerText","lang","elemLang","hash","location","root","focus","activeElement","hasFocus","href","tabIndex","enabled","disabled","checked","selected","selectedIndex","empty","header","button","even","odd","lt","gt","radio","checkbox","file","password","image","submit","reset","filters","parseOnly","tokens","soFar","preFilters","cached","addCombinator","combinator","base","checkNonElements","doneName","oldCache","newCache","elementMatcher","matchers","multipleContexts","contexts","condense","newUnmatched","mapped","setMatcher","postFilter","postFinder","postSelector","temp","preMap","postMap","preexisting","matcherIn","matcherOut","matcherFromTokens","checkContext","leadingRelative","implicitRelative","matchContext","matchAnyContext","matcherFromGroupMatchers","elementMatchers","setMatchers","bySet","byElement","superMatcher","outermost","matchedCount","setMatched","contextBackup","dirrunsUnique","token","compiled","div1","defaultValue","unique","isXMLDoc","until","truncate","is","siblings","n","rneedsContext","rsingleTag","risSimple","winnow","qualifier","self","rootjQuery","charAt","parseHTML","ready","rparentsprev","guaranteedUnique","children","contents","next","prev","targets","closest","l","pos","index","prevAll","add","addBack","sibling","parents","parentsUntil","nextAll","nextUntil","prevUntil","contentDocument","contentWindow","reverse","rnotwhite","createOptions","object","flag","Callbacks","firing","memory","fired","locked","queue","firingIndex","fire","once","stopOnFalse","remove","disable","lock","fireWith","Deferred","func","tuples","state","promise","always","deferred","fail","then","fns","newDefer","tuple","returned","progress","notify","resolve","reject","pipe","stateString","when","subordinate","resolveValues","remaining","updateFunc","values","progressValues","notifyWith","resolveWith","progressContexts","resolveContexts","readyList","readyWait","holdReady","hold","wait","triggerHandler","off","detach","removeEventListener","completed","detachEvent","event","readyState","setTimeout","frameElement","doScroll","doScrollCheck","inlineBlockNeedsLayout","body","container","style","cssText","zoom","offsetWidth","deleteExpando","acceptData","noData","rbrace","rmultiDash","dataAttr","parseJSON","isEmptyDataObject","internalData","pvt","thisCache","internalKey","isNode","toJSON","internalRemoveData","cleanData","applet ","embed ","object ","hasData","removeData","_data","_removeData","dequeue","startLength","hooks","_queueHooks","stop","setter","clearQueue","count","defer","shrinkWrapBlocksVal","shrinkWrapBlocks","width","pnum","source","rcssNum","cssExpand","isHidden","el","css","adjustCSS","prop","valueParts","tween","adjusted","scale","maxIterations","currentValue","initial","unit","cssNumber","initialInUnit","access","chainable","emptyGet","raw","bulk","rcheckableType","rtagName","rscriptType","rleadingWhitespace","nodeNames","createSafeFragment","safeFrag","createDocumentFragment","fragment","leadingWhitespace","tbody","htmlSerialize","html5Clone","cloneNode","outerHTML","appendChecked","noCloneChecked","checkClone","noCloneEvent","wrapMap","option","legend","area","param","thead","tr","col","td","_default","optgroup","tfoot","colgroup","caption","th","getAll","found","setGlobalEval","refElements","rhtml","rtbody","fixDefaultChecked","defaultChecked","buildFragment","scripts","selection","ignored","wrap","safe","nodes","htmlPrefilter","createTextNode","eventName","change","focusin","rformElems","rkeyEvent","rmouseEvent","rfocusMorph","rtypenamespace","returnTrue","returnFalse","safeActiveElement","err","on","types","one","origFn","events","t","handleObjIn","special","eventHandle","handleObj","handlers","namespaces","origType","elemData","handle","triggered","dispatch","delegateType","bindType","namespace","delegateCount","setup","mappedTypes","origCount","teardown","removeEvent","trigger","onlyHandlers","ontype","bubbleType","eventPath","Event","isTrigger","rnamespace","noBubble","parentWindow","isPropagationStopped","preventDefault","isDefaultPrevented","fix","handlerQueue","delegateTarget","preDispatch","currentTarget","isImmediatePropagationStopped","stopPropagation","postDispatch","sel","isNaN","originalEvent","fixHook","fixHooks","mouseHooks","keyHooks","props","srcElement","metaKey","original","which","charCode","keyCode","eventDoc","fromElement","pageX","clientX","scrollLeft","clientLeft","pageY","clientY","scrollTop","clientTop","relatedTarget","toElement","load","blur","click","beforeunload","returnValue","simulate","isSimulated","defaultPrevented","timeStamp","cancelBubble","stopImmediatePropagation","mouseenter","mouseleave","pointerenter","pointerleave","orig","related","form","_submitBubble","propertyName","_justChanged","attaches","rinlinejQuery","rnoshimcache","rxhtmlTag","rnoInnerhtml","rchecked","rscriptTypeMasked","rcleanScript","safeFragment","fragmentDiv","manipulationTarget","content","disableScript","restoreScript","cloneCopyEvent","dest","oldData","curData","fixCloneNodeIssues","defaultSelected","domManip","collection","hasScripts","iNoClone","html","_evalUrl","keepData","dataAndEvents","deepDataAndEvents","destElements","srcElements","inPage","forceAcceptData","append","prepend","insertBefore","before","after","replaceWith","replaceChild","appendTo","prependTo","insertAfter","replaceAll","insert","iframe","elemdisplay","HTML","BODY","actualDisplay","display","defaultDisplay","write","close","rmargin","rnumnonpx","swap","old","pixelPositionVal","pixelMarginRightVal","boxSizingReliableVal","reliableHiddenOffsetsVal","reliableMarginRightVal","reliableMarginLeftVal","opacity","cssFloat","backgroundClip","clearCloneStyle","boxSizing","MozBoxSizing","WebkitBoxSizing","reliableHiddenOffsets","computeStyleTests","boxSizingReliable","pixelMarginRight","pixelPosition","reliableMarginRight","reliableMarginLeft","divStyle","getComputedStyle","marginLeft","marginRight","getClientRects","offsetHeight","getStyles","curCSS","rposition","view","opener","computed","minWidth","maxWidth","getPropertyValue","currentStyle","left","rs","rsLeft","runtimeStyle","pixelLeft","addGetHookIf","conditionFn","hookFn","ralpha","ropacity","rdisplayswap","rnumsplit","cssShow","position","visibility","cssNormalTransform","letterSpacing","fontWeight","cssPrefixes","emptyStyle","vendorPropName","capName","showHide","show","hidden","setPositiveNumber","subtract","augmentWidthOrHeight","extra","isBorderBox","styles","getWidthOrHeight","valueIsBorderBox","msFullscreenElement","round","getBoundingClientRect","cssHooks","animationIterationCount","columnCount","fillOpacity","flexGrow","flexShrink","lineHeight","order","orphans","widows","zIndex","cssProps","float","origName","set","isFinite","$1","margin","padding","border","prefix","suffix","expand","expanded","parts","hide","toggle","Tween","easing","propHooks","run","percent","eased","duration","step","fx","linear","p","swing","cos","PI","fxNow","timerId","rfxtypes","rrun","createFxNow","genFx","includeWidth","height","createTween","animation","Animation","tweeners","defaultPrefilter","opts","oldfire","checkDisplay","anim","dataShow","unqueued","overflow","overflowX","overflowY","propFilter","specialEasing","properties","stopped","prefilters","tick","currentTime","startTime","tweens","originalProperties","originalOptions","gotoEnd","rejectWith","timer","complete","*","tweener","prefilter","speed","opt","speeds","fadeTo","to","animate","optall","doAnimation","finish","stopQueue","timers","cssFn","slideDown","slideUp","slideToggle","fadeIn","fadeOut","fadeToggle","interval","setInterval","clearInterval","slow","fast","delay","time","timeout","clearTimeout","getSetAttribute","hrefNormalized","checkOn","optSelected","enctype","optDisabled","radioValue","rreturn","valHooks","optionSet","scrollHeight","nodeHook","boolHook","ruseDefault","getSetInput","removeAttr","nType","attrHooks","propName","attrNames","propFix","getter","setAttributeNode","createAttribute","coords","contenteditable","rfocusable","rclickable","removeProp","tabindex","parseInt","for","class","rclass","getClass","addClass","classes","curValue","clazz","finalValue","removeClass","toggleClass","stateVal","classNames","hasClass","hover","fnOver","fnOut","nonce","rquery","rvalidtokens","JSON","parse","requireNonComma","depth","str","comma","open","Function","parseXML","DOMParser","parseFromString","ActiveXObject","async","loadXML","rhash","rts","rheaders","rlocalProtocol","rnoContent","rprotocol","rurl","transports","allTypes","ajaxLocation","ajaxLocParts","addToPrefiltersOrTransports","structure","dataTypeExpression","dataType","dataTypes","inspectPrefiltersOrTransports","jqXHR","inspected","seekingTransport","inspect","prefilterOrFactory","dataTypeOrTransport","ajaxExtend","flatOptions","ajaxSettings","ajaxHandleResponses","s","responses","firstDataType","ct","finalDataType","mimeType","getResponseHeader","converters","ajaxConvert","response","isSuccess","conv2","current","conv","responseFields","dataFilter","active","lastModified","etag","url","isLocal","processData","contentType","accepts","json","* text","text html","text json","text xml","ajaxSetup","settings","ajaxPrefilter","ajaxTransport","ajax","cacheURL","responseHeadersString","timeoutTimer","fireGlobals","transport","responseHeaders","callbackContext","globalEventContext","completeDeferred","statusCode","requestHeaders","requestHeadersNames","strAbort","getAllResponseHeaders","setRequestHeader","lname","overrideMimeType","code","status","abort","statusText","finalText","success","method","crossDomain","traditional","hasContent","ifModified","headers","beforeSend","send","nativeStatusText","modified","getJSON","getScript","throws","wrapAll","wrapInner","unwrap","getDisplay","filterHidden","visible","r20","rbracket","rCRLF","rsubmitterTypes","rsubmittable","buildParams","v","encodeURIComponent","serialize","serializeArray","xhr","createActiveXHR","documentMode","createStandardXHR","xhrId","xhrCallbacks","xhrSupported","cors","username","xhrFields","isAbort","onreadystatechange","responseText","XMLHttpRequest","script","text script","head","scriptCharset","charset","onload","oldCallbacks","rjsonp","jsonp","jsonpCallback","originalSettings","callbackName","overwritten","responseContainer","jsonProp","createHTMLDocument","implementation","keepScripts","parsed","_load","params","animated","getWindow","offset","setOffset","curPosition","curLeft","curCSSTop","curTop","curOffset","curCSSLeft","calculatePosition","curElem","using","win","box","pageYOffset","pageXOffset","offsetParent","parentOffset","scrollTo","Height","Width","","defaultExtra","funcName","bind","unbind","delegate","undelegate","size","andSelf","define","amd","_jQuery","_$","$","noConflict"],"mappings":"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","file":"jquery.min.js"}
\ No newline at end of file
diff --git js/varien/payment.js js/varien/payment.js
index a43f47e..3c8c0db 100644
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
index 6d8fc71..52998d6 100644
--- skin/frontend/base/default/js/opcheckout.js
+++ skin/frontend/base/default/js/opcheckout.js
@@ -684,7 +684,7 @@ Payment.prototype = {
         }
         var method = null;
         for (var i=0; i<elements.length; i++) {
-            if (elements[i].name=='payment[method]') {
+            if (elements[i].name=='payment[method]' || elements[i].name == 'form_key') {
                 if (elements[i].checked) {
                     method = elements[i].value;
                 }
