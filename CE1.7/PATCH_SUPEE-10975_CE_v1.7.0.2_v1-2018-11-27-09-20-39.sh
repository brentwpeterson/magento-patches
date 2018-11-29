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


SUPEE-10975_CE_v1.7.0.2 | CE_1.7.0.2 | v1 | 25ef90c0dc24dd62d56e84e231571a66054556a6 | Fri Nov 16 11:09:12 2018 +0200 | ce-1.7.0.2-dev

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Adminhtml/Block/Customer/Group/Edit.php app/code/core/Mage/Adminhtml/Block/Customer/Group/Edit.php
index a6dba63d579..2e12fbe3baf 100644
--- app/code/core/Mage/Adminhtml/Block/Customer/Group/Edit.php
+++ app/code/core/Mage/Adminhtml/Block/Customer/Group/Edit.php
@@ -49,6 +49,18 @@ class Mage_Adminhtml_Block_Customer_Group_Edit extends Mage_Adminhtml_Block_Widg
         }
     }
 
+    public function getDeleteUrl()
+    {
+        if (!Mage::getSingleton('adminhtml/url')->useSecretKey()) {
+            return $this->getUrl('*/*/delete', array(
+                $this->_objectId => $this->getRequest()->getParam($this->_objectId),
+                'form_key' => Mage::getSingleton('core/session')->getFormKey()
+            ));
+        } else {
+            parent::getDeleteUrl();
+        }
+    }
+
     public function getHeaderText()
     {
         if(!is_null(Mage::registry('current_group')->getId())) {
diff --git app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Edit.php app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Edit.php
index e8b2bf662ec..94c42774d0e 100644
--- app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Edit.php
+++ app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Edit.php
@@ -275,7 +275,7 @@ class Mage_Adminhtml_Block_Newsletter_Template_Edit extends Mage_Adminhtml_Block
      */
     public function getJsTemplateName()
     {
-        return addcslashes($this->getModel()->getTemplateCode(), "\"\r\n\\");
+        return addcslashes($this->escapeHtml($this->getModel()->getTemplateCode()), "\"\r\n\\");
     }
 
     /**
diff --git app/code/core/Mage/Adminhtml/controllers/Cms/BlockController.php app/code/core/Mage/Adminhtml/controllers/Cms/BlockController.php
index 8098daace90..1394ec9fb1a 100644
--- app/code/core/Mage/Adminhtml/controllers/Cms/BlockController.php
+++ app/code/core/Mage/Adminhtml/controllers/Cms/BlockController.php
@@ -34,6 +34,17 @@
  */
 class Mage_Adminhtml_Cms_BlockController extends Mage_Adminhtml_Controller_Action
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
     /**
      * Init actions
      *
diff --git app/code/core/Mage/Adminhtml/controllers/Customer/GroupController.php app/code/core/Mage/Adminhtml/controllers/Customer/GroupController.php
index 2b0716ab129..b69f50b0022 100644
--- app/code/core/Mage/Adminhtml/controllers/Customer/GroupController.php
+++ app/code/core/Mage/Adminhtml/controllers/Customer/GroupController.php
@@ -33,6 +33,17 @@
  */
 class Mage_Adminhtml_Customer_GroupController extends Mage_Adminhtml_Controller_Action
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
     protected function _initGroup()
     {
         $this->_title($this->__('Customers'))->_title($this->__('Customer Groups'));
diff --git app/code/core/Mage/Adminhtml/controllers/SitemapController.php app/code/core/Mage/Adminhtml/controllers/SitemapController.php
index 0426ad9ea8a..4f5c381c57e 100644
--- app/code/core/Mage/Adminhtml/controllers/SitemapController.php
+++ app/code/core/Mage/Adminhtml/controllers/SitemapController.php
@@ -33,6 +33,17 @@
  */
 class Mage_Adminhtml_SitemapController extends  Mage_Adminhtml_Controller_Action
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
     /**
      * Init actions
      *
diff --git app/code/core/Mage/Adminhtml/controllers/System/BackupController.php app/code/core/Mage/Adminhtml/controllers/System/BackupController.php
index bf8fa3d3f3e..44ed6ad09dc 100644
--- app/code/core/Mage/Adminhtml/controllers/System/BackupController.php
+++ app/code/core/Mage/Adminhtml/controllers/System/BackupController.php
@@ -369,7 +369,9 @@ class Mage_Adminhtml_System_BackupController extends Mage_Adminhtml_Controller_A
      */
     protected function _isAllowed()
     {
-        return Mage::getSingleton('admin/session')->isAllowed('system/tools/backup' );
+        return Mage::getSingleton('admin/session')->isAllowed('system/tools/backup')
+            && Mage::helper('core')->isModuleEnabled('Mage_Backup')
+            && !Mage::getStoreConfigFlag('advanced/modules_disable_output/Mage_Backup');
     }
 
     /**
diff --git app/code/core/Mage/Captcha/Model/Observer.php app/code/core/Mage/Captcha/Model/Observer.php
index af5c45b33ec..287aa3aea65 100755
--- app/code/core/Mage/Captcha/Model/Observer.php
+++ app/code/core/Mage/Captcha/Model/Observer.php
@@ -289,4 +289,29 @@ class Mage_Captcha_Model_Observer
         $captchaParams = $request->getPost(Mage_Captcha_Helper_Data::INPUT_NAME_FIELD_VALUE);
         return $captchaParams[$formId];
     }
+
+    /**
+     * Check Captcha On Share Wishlist Page
+     *
+     * @param Varien_Event_Observer $observer
+     * @return Mage_Captcha_Model_Observer
+     */
+    public function checkWishlistSharing($observer)
+    {
+        $formId = 'wishlist_sharing';
+        $captchaModel = Mage::helper('captcha')->getCaptcha($formId);
+        if ($captchaModel->isRequired()) {
+            $controller = $observer->getControllerAction();
+            $request = $controller->getRequest();
+            if (!$captchaModel->isCorrect($this->_getCaptchaString($request, $formId))) {
+                Mage::getSingleton('wishlist/session')->addError(Mage::helper('captcha')->__('Incorrect CAPTCHA.'));
+                $controller->setFlag('', Mage_Core_Controller_Varien_Action::FLAG_NO_DISPATCH, true);
+                Mage::getSingleton('wishlist/session')->setSharingForm($request->getPost());
+                $wishlistId = (int)$request->getParam('wishlist_id');
+                $controller->getResponse()
+                    ->setRedirect(Mage::getUrl('wishlist/index/share/wishlist_id/' . $wishlistId));
+            }
+        }
+        return $this;
+    }
 }
diff --git app/code/core/Mage/Captcha/Model/Zend.php app/code/core/Mage/Captcha/Model/Zend.php
index be7d4ee64b2..b2ff06d2510 100755
--- app/code/core/Mage/Captcha/Model/Zend.php
+++ app/code/core/Mage/Captcha/Model/Zend.php
@@ -190,6 +190,9 @@ class Mage_Captcha_Model_Zend extends Zend_Captcha_Image implements Mage_Captcha
      */
     protected function _isUserAuth()
     {
+        if ($this->_formId == 'wishlist_sharing') {
+            return false;
+        }
         return Mage::app()->getStore()->isAdmin()
             ? Mage::getSingleton('admin/session')->isLoggedIn()
             : Mage::getSingleton('customer/session')->isLoggedIn();
diff --git app/code/core/Mage/Captcha/etc/config.xml app/code/core/Mage/Captcha/etc/config.xml
index 817e6f66ad2..47e648694a2 100755
--- app/code/core/Mage/Captcha/etc/config.xml
+++ app/code/core/Mage/Captcha/etc/config.xml
@@ -78,6 +78,14 @@
                     </captcha>
                 </observers>
             </controller_action_predispatch_customer_account_createpost>
+            <controller_action_predispatch_wishlist_index_send>
+                <observers>
+                    <captcha>
+                        <class>captcha/observer</class>
+                        <method>checkWishlistSharing</method>
+                    </captcha>
+                </observers>
+            </controller_action_predispatch_wishlist_index_send>
             <controller_action_predispatch_adminhtml_index_forgotpassword>
                 <observers>
                     <captcha>
@@ -206,6 +214,7 @@
                     <user_forgotpassword>1</user_forgotpassword>
                     <guest_checkout>1</guest_checkout>
                     <register_during_checkout>1</register_during_checkout>
+                    <wishlist_sharing>1</wishlist_sharing>
                 </always_for>
             </captcha>
         </customer>
@@ -233,6 +242,9 @@
                     <register_during_checkout>
                         <label>Register during Checkout</label>
                     </register_during_checkout>
+                    <wishlist_sharing>
+                        <label>Share Wishlist</label>
+                    </wishlist_sharing>
                 </areas>
             </frontend>
             <backend>
diff --git app/code/core/Mage/Catalog/Model/Api2/Product/Image/Rest/Admin/V1.php app/code/core/Mage/Catalog/Model/Api2/Product/Image/Rest/Admin/V1.php
index 9109796eba0..d60dda4c227 100644
--- app/code/core/Mage/Catalog/Model/Api2/Product/Image/Rest/Admin/V1.php
+++ app/code/core/Mage/Catalog/Model/Api2/Product/Image/Rest/Admin/V1.php
@@ -69,7 +69,9 @@ class Mage_Catalog_Model_Api2_Product_Image_Rest_Admin_V1 extends Mage_Catalog_M
 
             // try to create Image object to check if image data is valid
             try {
-                new Varien_Image($apiTempDir . DS . $imageFileName);
+                $filePath = $apiTempDir . DS . $imageFileName;
+                new Varien_Image($filePath);
+                Mage::getModel('core/file_validator_image')->validate($filePath);
             } catch (Exception $e) {
                 $ioAdapter->rmdir($apiTempDir, true);
                 $this->_critical($e->getMessage(), Mage_Api2_Model_Server::HTTP_INTERNAL_ERROR);
diff --git app/code/core/Mage/Catalog/Model/Product/Attribute/Media/Api.php app/code/core/Mage/Catalog/Model/Product/Attribute/Media/Api.php
index 33a56d21995..f4c99f0afe5 100644
--- app/code/core/Mage/Catalog/Model/Product/Attribute/Media/Api.php
+++ app/code/core/Mage/Catalog/Model/Product/Attribute/Media/Api.php
@@ -155,7 +155,9 @@ class Mage_Catalog_Model_Product_Attribute_Media_Api extends Mage_Catalog_Model_
 
             // try to create Image object - it fails with Exception if image is not supported
             try {
-                new Varien_Image($tmpDirectory . DS . $fileName);
+                $filePath = $tmpDirectory . DS . $fileName;
+                new Varien_Image($filePath);
+                Mage::getModel('core/file_validator_image')->validate($filePath);
             } catch (Exception $e) {
                 // Remove temporary directory
                 $ioAdapter->rmdir($tmpDirectory, true);
diff --git app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
index 66efae0af57..e81f460c7a3 100644
--- app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
+++ app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
@@ -137,7 +137,9 @@ class Mage_Cms_Model_Wysiwyg_Images_Storage extends Varien_Object
             $item->setUrl($helper->getCurrentUrl() . $item->getBasename());
 
             if ($this->isImage($item->getBasename())) {
-                $thumbUrl = $this->getThumbnailUrl($item->getFilename(), true);
+                $thumbUrl = $this->getThumbnailUrl(
+                    Mage_Core_Model_File_Uploader::getCorrectFileName($item->getFilename()),
+                    true);
                 // generate thumbnail "on the fly" if it does not exists
                 if(! $thumbUrl) {
                     $thumbUrl = Mage::getSingleton('adminhtml/url')->getUrl('*/*/thumbnail', array('file' => $item->getId()));
@@ -382,7 +384,9 @@ class Mage_Cms_Model_Wysiwyg_Images_Storage extends Varien_Object
         $height = $this->getConfigData('resize_height');
         $image->keepAspectRatio($keepRation);
         $image->resize($width, $height);
-        $dest = $targetDir . DS . pathinfo($source, PATHINFO_BASENAME);
+        $dest = $targetDir
+            . DS
+            . Mage_Core_Model_File_Uploader::getCorrectFileName(pathinfo($source, PATHINFO_BASENAME));
         $image->save($dest);
         if (is_file($dest)) {
             return $dest;
diff --git app/code/core/Mage/Core/etc/config.xml app/code/core/Mage/Core/etc/config.xml
index 718e672ac7d..1caf0e92dbd 100644
--- app/code/core/Mage/Core/etc/config.xml
+++ app/code/core/Mage/Core/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Mage_Core>
-            <version>1.6.0.2.1.2</version>
+            <version>1.6.0.2.1.3</version>
         </Mage_Core>
     </modules>
     <global>
@@ -379,8 +379,13 @@
             </locale>
             <file>
                 <protected_extensions>
-                    <!-- PHP script file extension -->
+                    <!-- BOF PHP script file extensions -->
                     <php>php</php>
+                    <php3>php3</php3>
+                    <php4>php4</php4>
+                    <php5>php5</php5>
+                    <php7>php7</php7>
+                    <!-- EOF PHP script file extensions -->
                     <!-- File extension of configuration of an Apache Web server -->
                     <htaccess>htaccess</htaccess>
                     <!-- Java script file extension -->
@@ -398,6 +403,7 @@
                     <!-- BOF HTML file extensions -->
                     <htm>htm</htm>
                     <html>html</html>
+                    <pht>pht</pht>
                     <phtml>phtml</phtml>
                     <shtml>shtml</shtml>
                     <!-- EOF HTML file extensions -->
diff --git app/code/core/Mage/Core/sql/core_setup/upgrade-1.6.0.2.1.2-1.6.0.2.1.3.php app/code/core/Mage/Core/sql/core_setup/upgrade-1.6.0.2.1.2-1.6.0.2.1.3.php
new file mode 100644
index 00000000000..f9da012fca0
--- /dev/null
+++ app/code/core/Mage/Core/sql/core_setup/upgrade-1.6.0.2.1.2-1.6.0.2.1.3.php
@@ -0,0 +1,41 @@
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
+ * @package     Mage_Core
+ * @copyright  Copyright (c) 2006-2018 Magento, Inc. (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/* @var $installer Mage_Core_Model_Resource_Setup */
+$installer = $this;
+
+$installer->startSetup();
+$connection = $installer->getConnection();
+
+$connection->delete(
+    $this->getTable('core_config_data'),
+    $connection->prepareSqlCondition('path', array(
+        'like' => 'system/backup/enabled'
+    ))
+);
+$installer->setConfigData('advanced/modules_disable_output/Mage_Backup', 1);
+
+$installer->endSetup();
diff --git app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
index 7fc8e869bdb..741e01fc3eb 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
@@ -55,7 +55,8 @@ abstract class Mage_Dataflow_Model_Convert_Container_Abstract
      */
     protected function isSerialized($data)
     {
-        $pattern = '/^a:\d+:\{(i:\d+;|s:\d+:\".+\";|N;|O:\d+:\"\w+\":\d+:\{\w:\d+:)+|^O:\d+:\"\w+\":\d+:\{s:\d+:\"/';
+        $pattern =
+            '/^a:\d+:\{(i:\d+;|s:\d+:\".+\";|N;|O:\d+:\"\w+\":\d+:\{\w:\d+:)+|^O:\d+:\"\w+\":\d+:\{(s:\d+:\"|i:\d+;)/';
         return (is_string($data) && preg_match($pattern, $data));
     }
 
@@ -140,7 +141,7 @@ abstract class Mage_Dataflow_Model_Convert_Container_Abstract
         $result = true;
         if ($this->isSerialized($data)) {
             try {
-                $dataArray = Mage::helper('core/unserializeArray')->unserialize($data);
+                Mage::helper('core/unserializeArray')->unserialize($data);
             } catch (Exception $e) {
                 $result = false;
                 $this->addException(
diff --git app/code/core/Mage/ImportExport/Model/Import/Entity/Customer.php app/code/core/Mage/ImportExport/Model/Import/Entity/Customer.php
index d6509eb403c..3b279653f90 100644
--- app/code/core/Mage/ImportExport/Model/Import/Entity/Customer.php
+++ app/code/core/Mage/ImportExport/Model/Import/Entity/Customer.php
@@ -280,7 +280,9 @@ class Mage_ImportExport_Model_Import_Entity_Customer extends Mage_ImportExport_M
                 'id'          => $attribute->getId(),
                 'is_required' => $attribute->getIsRequired(),
                 'is_static'   => $attribute->isStatic(),
-                'rules'       => $attribute->getValidateRules() ? unserialize($attribute->getValidateRules()) : null,
+                'rules'       => $attribute->getValidateRules()
+                    ? Mage::helper('core/unserializeArray')->unserialize($attribute->getValidateRules())
+                    : null,
                 'type'        => Mage_ImportExport_Model_Import::getAttributeType($attribute),
                 'options'     => $this->getAttributeOptions($attribute)
             );
diff --git app/code/core/Mage/ImportExport/Model/Import/Entity/Customer/Address.php app/code/core/Mage/ImportExport/Model/Import/Entity/Customer/Address.php
index bf496a3bf23..e3b9659a772 100644
--- app/code/core/Mage/ImportExport/Model/Import/Entity/Customer/Address.php
+++ app/code/core/Mage/ImportExport/Model/Import/Entity/Customer/Address.php
@@ -281,7 +281,9 @@ class Mage_ImportExport_Model_Import_Entity_Customer_Address extends Mage_Import
                 'code'        => $attribute->getAttributeCode(),
                 'table'       => $attribute->getBackend()->getTable(),
                 'is_required' => $attribute->getIsRequired(),
-                'rules'       => $attribute->getValidateRules() ? unserialize($attribute->getValidateRules()) : null,
+                'rules'       => $attribute->getValidateRules()
+                    ? Mage::helper('core/unserializeArray')->unserialize($attribute->getValidateRules())
+                    : null,
                 'type'        => Mage_ImportExport_Model_Import::getAttributeType($attribute),
                 'options'     => $this->getAttributeOptions($attribute)
             );
diff --git app/code/core/Mage/Payment/etc/config.xml app/code/core/Mage/Payment/etc/config.xml
index 6d27a94de6f..1b527f5d7ac 100644
--- app/code/core/Mage/Payment/etc/config.xml
+++ app/code/core/Mage/Payment/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Mage_Payment>
-            <version>1.6.0.0</version>
+            <version>1.6.0.0.1.2</version>
         </Mage_Payment>
     </modules>
     <global>
@@ -36,6 +36,9 @@
             <payment>
                 <class>Mage_Payment_Model</class>
             </payment>
+            <payment_resource>
+                <class>Mage_Core_Model_Resource</class>
+            </payment_resource>
         </models>
         <resources>
             <payment_setup>
@@ -158,15 +161,6 @@
     </adminhtml>
     <default>
         <payment>
-            <ccsave>
-                <active>1</active>
-                <cctypes>AE,VI,MC,DI</cctypes>
-                <model>payment/method_ccsave</model>
-                <order_status>pending</order_status>
-                <title>Credit Card (saved)</title>
-                <allowspecific>0</allowspecific>
-                <group>offline</group>
-            </ccsave>
             <checkmo>
                 <active>1</active>
                 <model>payment/method_checkmo</model>
diff --git app/code/core/Mage/Payment/etc/system.xml app/code/core/Mage/Payment/etc/system.xml
index dff8ca0cd62..ff4fd316591 100644
--- app/code/core/Mage/Payment/etc/system.xml
+++ app/code/core/Mage/Payment/etc/system.xml
@@ -36,140 +36,6 @@
             <show_in_website>1</show_in_website>
             <show_in_store>1</show_in_store>
             <groups>
-                <ccsave translate="label">
-                    <label>Saved CC</label>
-                    <frontend_type>text</frontend_type>
-                    <sort_order>27</sort_order>
-                    <show_in_default>1</show_in_default>
-                    <show_in_website>1</show_in_website>
-                    <show_in_store>1</show_in_store>
-                    <fields>
-                        <active translate="label">
-                            <label>Enabled</label>
-                            <frontend_type>select</frontend_type>
-                            <source_model>adminhtml/system_config_source_yesno</source_model>
-                            <sort_order>1</sort_order>
-                            <show_in_default>1</show_in_default>
-                            <show_in_website>1</show_in_website>
-                            <show_in_store>0</show_in_store>
-                        </active>
-                        <cctypes translate="label">
-                            <label>Credit Card Types</label>
-                            <frontend_type>multiselect</frontend_type>
-                            <source_model>adminhtml/system_config_source_payment_cctype</source_model>
-                            <sort_order>4</sort_order>
-                            <show_in_default>1</show_in_default>
-                            <show_in_website>1</show_in_website>
-                            <show_in_store>0</show_in_store>
-                            <can_be_empty>1</can_be_empty>
-                        </cctypes>
-                        <order_status translate="label">
-                            <label>New Order Status</label>
-                            <frontend_type>select</frontend_type>
-                            <source_model>adminhtml/system_config_source_order_status_new</source_model>
-                            <sort_order>2</sort_order>
-                            <show_in_default>1</show_in_default>
-                            <show_in_website>1</show_in_website>
-                            <show_in_store>0</show_in_store>
-                        </order_status>
-                        <sort_order translate="label">
-                            <label>Sort Order</label>
-                            <frontend_type>text</frontend_type>
-                            <sort_order>100</sort_order>
-                            <show_in_default>1</show_in_default>
-                            <show_in_website>1</show_in_website>
-                            <show_in_store>0</show_in_store>
-                            <frontend_class>validate-number</frontend_class>
-                        </sort_order>
-                        <title translate="label">
-                            <label>Title</label>
-                            <frontend_type>text</frontend_type>
-                            <sort_order>1</sort_order>
-                            <show_in_default>1</show_in_default>
-                            <show_in_website>1</show_in_website>
-                            <show_in_store>1</show_in_store>
-                        </title>
-                        <useccv translate="label">
-                            <label>Request Card Security Code</label>
-                            <frontend_type>select</frontend_type>
-                            <source_model>adminhtml/system_config_source_yesno</source_model>
-                            <sort_order>5</sort_order>
-                            <show_in_default>1</show_in_default>
-                            <show_in_website>1</show_in_website>
-                            <show_in_store>0</show_in_store>
-                        </useccv>
-
-                        <centinel translate="label">
-                            <label>3D Secure Card Validation</label>
-                            <frontend_type>select</frontend_type>
-                            <source_model>adminhtml/system_config_source_yesno</source_model>
-                            <sort_order>20</sort_order>
-                            <show_in_default>1</show_in_default>
-                            <show_in_website>1</show_in_website>
-                            <show_in_store>0</show_in_store>
-                        </centinel>
-                        <centinel_is_mode_strict translate="label comment">
-                            <label>Severe 3D Secure Card Validation</label>
-                            <comment>Severe validation removes chargeback liability on merchant.</comment>
-                            <frontend_type>select</frontend_type>
-                            <source_model>adminhtml/system_config_source_yesno</source_model>
-                            <sort_order>25</sort_order>
-                            <show_in_default>1</show_in_default>
-                            <show_in_website>1</show_in_website>
-                            <show_in_store>0</show_in_store>
-                            <depends><centinel>1</centinel></depends>
-                        </centinel_is_mode_strict>
-                        <centinel_api_url translate="label comment">
-                            <label>Centinel API URL</label>
-                            <comment>A value is required for live mode. Refer to your CardinalCommerce agreement.</comment>
-                            <frontend_type>text</frontend_type>
-                            <source_model>adminhtml/system_config_source_yesno</source_model>
-                            <sort_order>30</sort_order>
-                            <show_in_default>1</show_in_default>
-                            <show_in_website>1</show_in_website>
-                            <show_in_store>0</show_in_store>
-                            <depends><centinel>1</centinel></depends>
-                        </centinel_api_url>
-
-                         <allowspecific translate="label">
-                            <label>Payment from Applicable Countries</label>
-                            <frontend_type>allowspecific</frontend_type>
-                            <sort_order>50</sort_order>
-                            <source_model>adminhtml/system_config_source_payment_allspecificcountries</source_model>
-                            <show_in_default>1</show_in_default>
-                            <show_in_website>1</show_in_website>
-                            <show_in_store>0</show_in_store>
-                        </allowspecific>
-                        <specificcountry translate="label">
-                            <label>Payment from Specific Countries</label>
-                            <frontend_type>multiselect</frontend_type>
-                            <sort_order>51</sort_order>
-                            <source_model>adminhtml/system_config_source_country</source_model>
-                            <show_in_default>1</show_in_default>
-                            <show_in_website>1</show_in_website>
-                            <show_in_store>0</show_in_store>
-                            <can_be_empty>1</can_be_empty>
-                        </specificcountry>
-                        <min_order_total translate="label">
-                            <label>Minimum Order Total</label>
-                            <frontend_type>text</frontend_type>
-                            <sort_order>98</sort_order>
-                            <show_in_default>1</show_in_default>
-                            <show_in_website>1</show_in_website>
-                            <show_in_store>0</show_in_store>
-                        </min_order_total>
-                        <max_order_total translate="label">
-                            <label>Maximum Order Total</label>
-                            <frontend_type>text</frontend_type>
-                            <sort_order>99</sort_order>
-                            <show_in_default>1</show_in_default>
-                            <show_in_website>1</show_in_website>
-                            <show_in_store>0</show_in_store>
-                        </max_order_total>
-                        <model>
-                        </model>
-                    </fields>
-                </ccsave>
                 <checkmo translate="label">
                     <label>Check / Money Order</label>
                     <frontend_type>text</frontend_type>
diff --git app/code/core/Mage/Payment/sql/payment_setup/upgrade-1.6.0.0.1.1-1.6.0.0.1.2.php app/code/core/Mage/Payment/sql/payment_setup/upgrade-1.6.0.0.1.1-1.6.0.0.1.2.php
new file mode 100644
index 00000000000..37eaac62016
--- /dev/null
+++ app/code/core/Mage/Payment/sql/payment_setup/upgrade-1.6.0.0.1.1-1.6.0.0.1.2.php
@@ -0,0 +1,40 @@
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
+ * @package     Mage_Payment
+ * @copyright  Copyright (c) 2006-2018 Magento, Inc. (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/* @var $installer Mage_Core_Model_Resource_Setup */
+$installer = $this;
+
+$installer->startSetup();
+$connection = $installer->getConnection();
+
+$connection->delete(
+    $this->getTable('core_config_data'),
+    $connection->prepareSqlCondition('path', array(
+        'like' => 'payment/ccsave/active'
+    ))
+);
+
+$installer->endSetup();
diff --git app/code/core/Mage/Wishlist/controllers/IndexController.php app/code/core/Mage/Wishlist/controllers/IndexController.php
index 46c9355644c..bacc0676ad7 100644
--- app/code/core/Mage/Wishlist/controllers/IndexController.php
+++ app/code/core/Mage/Wishlist/controllers/IndexController.php
@@ -627,6 +627,9 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
         if (empty($emails)) {
             $error = $this->__('Email address can\'t be empty.');
         }
+        elseif (count($emails) > 5) {
+            $error = $this->__('Please enter no more than 5 email addresses.');
+        }
         else {
             foreach ($emails as $index => $email) {
                 $email = trim($email);
diff --git app/code/core/Zend/Controller/Request/Http.php app/code/core/Zend/Controller/Request/Http.php
new file mode 100644
index 00000000000..ac4eae6a604
--- /dev/null
+++ app/code/core/Zend/Controller/Request/Http.php
@@ -0,0 +1,1088 @@
+<?php
+/**
+ * Zend Framework
+ *
+ * LICENSE
+ *
+ * This source file is subject to the new BSD license that is bundled
+ * with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://framework.zend.com/license/new-bsd
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@zend.com so we can send you a copy immediately.
+ *
+ * @category   Zend
+ * @package    Zend_Controller
+ * @copyright  Copyright (c) 2005-2015 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ * @version    $Id$
+ */
+
+/** @see Zend_Controller_Request_Abstract */
+#require_once 'Zend/Controller/Request/Abstract.php';
+
+/** @see Zend_Uri */
+#require_once 'Zend/Uri.php';
+
+/**
+ * Zend_Controller_Request_Http
+ *
+ * HTTP request object for use with Zend_Controller family.
+ *
+ * @uses Zend_Controller_Request_Abstract
+ * @package Zend_Controller
+ * @subpackage Request
+ */
+class Zend_Controller_Request_Http extends Zend_Controller_Request_Abstract
+{
+    /**
+     * Scheme for http
+     *
+     */
+    const SCHEME_HTTP  = 'http';
+
+    /**
+     * Scheme for https
+     *
+     */
+    const SCHEME_HTTPS = 'https';
+
+    /**
+     * Allowed parameter sources
+     * @var array
+     */
+    protected $_paramSources = array('_GET', '_POST');
+
+    /**
+     * REQUEST_URI
+     * @var string;
+     */
+    protected $_requestUri;
+
+    /**
+     * Base URL of request
+     * @var string
+     */
+    protected $_baseUrl = null;
+
+    /**
+     * Base path of request
+     * @var string
+     */
+    protected $_basePath = null;
+
+    /**
+     * PATH_INFO
+     * @var string
+     */
+    protected $_pathInfo = '';
+
+    /**
+     * Instance parameters
+     * @var array
+     */
+    protected $_params = array();
+
+    /**
+     * Raw request body
+     * @var string|false
+     */
+    protected $_rawBody;
+
+    /**
+     * Alias keys for request parameters
+     * @var array
+     */
+    protected $_aliases = array();
+
+    /**
+     * Constructor
+     *
+     * If a $uri is passed, the object will attempt to populate itself using
+     * that information.
+     *
+     * @param string|Zend_Uri $uri
+     * @return void
+     * @throws Zend_Controller_Request_Exception when invalid URI passed
+     */
+    public function __construct($uri = null)
+    {
+        if (null !== $uri) {
+            if (!$uri instanceof Zend_Uri) {
+                $uri = Zend_Uri::factory($uri);
+            }
+            if ($uri->valid()) {
+                $path  = $uri->getPath();
+                $query = $uri->getQuery();
+                if (!empty($query)) {
+                    $path .= '?' . $query;
+                }
+
+                $this->setRequestUri($path);
+            } else {
+                #require_once 'Zend/Controller/Request/Exception.php';
+                throw new Zend_Controller_Request_Exception('Invalid URI provided to constructor');
+            }
+        } else {
+            $this->setRequestUri();
+        }
+    }
+
+    /**
+     * Access values contained in the superglobals as public members
+     * Order of precedence: 1. GET, 2. POST, 3. COOKIE, 4. SERVER, 5. ENV
+     *
+     * @see http://msdn.microsoft.com/en-us/library/system.web.httprequest.item.aspx
+     * @param string $key
+     * @return mixed
+     */
+    public function __get($key)
+    {
+        switch (true) {
+            case isset($this->_params[$key]):
+                return $this->_params[$key];
+            case isset($_GET[$key]):
+                return $_GET[$key];
+            case isset($_POST[$key]):
+                return $_POST[$key];
+            case isset($_COOKIE[$key]):
+                return $_COOKIE[$key];
+            case ($key == 'REQUEST_URI'):
+                return $this->getRequestUri();
+            case ($key == 'PATH_INFO'):
+                return $this->getPathInfo();
+            case isset($_SERVER[$key]):
+                return $_SERVER[$key];
+            case isset($_ENV[$key]):
+                return $_ENV[$key];
+            default:
+                return null;
+        }
+    }
+
+    /**
+     * Alias to __get
+     *
+     * @param string $key
+     * @return mixed
+     */
+    public function get($key)
+    {
+        return $this->__get($key);
+    }
+
+    /**
+     * Set values
+     *
+     * In order to follow {@link __get()}, which operates on a number of
+     * superglobals, setting values through overloading is not allowed and will
+     * raise an exception. Use setParam() instead.
+     *
+     * @param string $key
+     * @param mixed $value
+     * @return void
+     * @throws Zend_Controller_Request_Exception
+     */
+    public function __set($key, $value)
+    {
+        #require_once 'Zend/Controller/Request/Exception.php';
+        throw new Zend_Controller_Request_Exception('Setting values in superglobals not allowed; please use setParam()');
+    }
+
+    /**
+     * Alias to __set()
+     *
+     * @param string $key
+     * @param mixed $value
+     * @return void
+     */
+    public function set($key, $value)
+    {
+        return $this->__set($key, $value);
+    }
+
+    /**
+     * Check to see if a property is set
+     *
+     * @param string $key
+     * @return boolean
+     */
+    public function __isset($key)
+    {
+        switch (true) {
+            case isset($this->_params[$key]):
+                return true;
+            case isset($_GET[$key]):
+                return true;
+            case isset($_POST[$key]):
+                return true;
+            case isset($_COOKIE[$key]):
+                return true;
+            case isset($_SERVER[$key]):
+                return true;
+            case isset($_ENV[$key]):
+                return true;
+            default:
+                return false;
+        }
+    }
+
+    /**
+     * Alias to __isset()
+     *
+     * @param string $key
+     * @return boolean
+     */
+    public function has($key)
+    {
+        return $this->__isset($key);
+    }
+
+    /**
+     * Set GET values
+     *
+     * @param  string|array $spec
+     * @param  null|mixed $value
+     * @return Zend_Controller_Request_Http
+     */
+    public function setQuery($spec, $value = null)
+    {
+        if ((null === $value) && !is_array($spec)) {
+            #require_once 'Zend/Controller/Exception.php';
+            throw new Zend_Controller_Exception('Invalid value passed to setQuery(); must be either array of values or key/value pair');
+        }
+        if ((null === $value) && is_array($spec)) {
+            foreach ($spec as $key => $value) {
+                $this->setQuery($key, $value);
+            }
+            return $this;
+        }
+        $_GET[(string) $spec] = $value;
+        return $this;
+    }
+
+    /**
+     * Retrieve a member of the $_GET superglobal
+     *
+     * If no $key is passed, returns the entire $_GET array.
+     *
+     * @todo How to retrieve from nested arrays
+     * @param string $key
+     * @param mixed $default Default value to use if key not found
+     * @return mixed Returns null if key does not exist
+     */
+    public function getQuery($key = null, $default = null)
+    {
+        if (null === $key) {
+            return $_GET;
+        }
+
+        return (isset($_GET[$key])) ? $_GET[$key] : $default;
+    }
+
+    /**
+     * Set POST values
+     *
+     * @param  string|array $spec
+     * @param  null|mixed $value
+     * @return Zend_Controller_Request_Http
+     */
+    public function setPost($spec, $value = null)
+    {
+        if ((null === $value) && !is_array($spec)) {
+            #require_once 'Zend/Controller/Exception.php';
+            throw new Zend_Controller_Exception('Invalid value passed to setPost(); must be either array of values or key/value pair');
+        }
+        if ((null === $value) && is_array($spec)) {
+            foreach ($spec as $key => $value) {
+                $this->setPost($key, $value);
+            }
+            return $this;
+        }
+        $_POST[(string) $spec] = $value;
+        return $this;
+    }
+
+    /**
+     * Retrieve a member of the $_POST superglobal
+     *
+     * If no $key is passed, returns the entire $_POST array.
+     *
+     * @todo How to retrieve from nested arrays
+     * @param string $key
+     * @param mixed $default Default value to use if key not found
+     * @return mixed Returns null if key does not exist
+     */
+    public function getPost($key = null, $default = null)
+    {
+        if (null === $key) {
+            return $_POST;
+        }
+
+        return (isset($_POST[$key])) ? $_POST[$key] : $default;
+    }
+
+    /**
+     * Retrieve a member of the $_COOKIE superglobal
+     *
+     * If no $key is passed, returns the entire $_COOKIE array.
+     *
+     * @todo How to retrieve from nested arrays
+     * @param string $key
+     * @param mixed $default Default value to use if key not found
+     * @return mixed Returns null if key does not exist
+     */
+    public function getCookie($key = null, $default = null)
+    {
+        if (null === $key) {
+            return $_COOKIE;
+        }
+
+        return (isset($_COOKIE[$key])) ? $_COOKIE[$key] : $default;
+    }
+
+    /**
+     * Retrieve a member of the $_SERVER superglobal
+     *
+     * If no $key is passed, returns the entire $_SERVER array.
+     *
+     * @param string $key
+     * @param mixed $default Default value to use if key not found
+     * @return mixed Returns null if key does not exist
+     */
+    public function getServer($key = null, $default = null)
+    {
+        if (null === $key) {
+            return $_SERVER;
+        }
+
+        return (isset($_SERVER[$key])) ? $_SERVER[$key] : $default;
+    }
+
+    /**
+     * Retrieve a member of the $_ENV superglobal
+     *
+     * If no $key is passed, returns the entire $_ENV array.
+     *
+     * @param string $key
+     * @param mixed $default Default value to use if key not found
+     * @return mixed Returns null if key does not exist
+     */
+    public function getEnv($key = null, $default = null)
+    {
+        if (null === $key) {
+            return $_ENV;
+        }
+
+        return (isset($_ENV[$key])) ? $_ENV[$key] : $default;
+    }
+
+    /**
+     * Set the REQUEST_URI on which the instance operates
+     *
+     * If no request URI is passed, uses the value in $_SERVER['REQUEST_URI'],
+     * $_SERVER['HTTP_X_REWRITE_URL'], or $_SERVER['ORIG_PATH_INFO'] + $_SERVER['QUERY_STRING'].
+     *
+     * @param string $requestUri
+     * @return Zend_Controller_Request_Http
+     */
+    public function setRequestUri($requestUri = null)
+    {
+        if ($requestUri === null) {
+            if (
+                // IIS7 with URL Rewrite: make sure we get the unencoded url (double slash problem)
+                isset($_SERVER['IIS_WasUrlRewritten'])
+                && $_SERVER['IIS_WasUrlRewritten'] == '1'
+                && isset($_SERVER['UNENCODED_URL'])
+                && $_SERVER['UNENCODED_URL'] != ''
+            ) {
+                $requestUri = $_SERVER['UNENCODED_URL'];
+            } elseif (isset($_SERVER['REQUEST_URI'])) {
+                $requestUri = $_SERVER['REQUEST_URI'];
+                // Http proxy reqs setup request uri with scheme and host [and port] + the url path, only use url path
+                $schemeAndHttpHost = $this->getScheme() . '://' . $this->getHttpHost();
+                if (strpos($requestUri, $schemeAndHttpHost) === 0) {
+                    $requestUri = substr($requestUri, strlen($schemeAndHttpHost));
+                }
+            } elseif (isset($_SERVER['ORIG_PATH_INFO'])) { // IIS 5.0, PHP as CGI
+                $requestUri = $_SERVER['ORIG_PATH_INFO'];
+                if (!empty($_SERVER['QUERY_STRING'])) {
+                    $requestUri .= '?' . $_SERVER['QUERY_STRING'];
+                }
+            } else {
+                return $this;
+            }
+        } elseif (!is_string($requestUri)) {
+            return $this;
+        } else {
+            // Set GET items, if available
+            if (false !== ($pos = strpos($requestUri, '?'))) {
+                // Get key => value pairs and set $_GET
+                $query = substr($requestUri, $pos + 1);
+                parse_str($query, $vars);
+                $this->setQuery($vars);
+            }
+        }
+
+        $this->_requestUri = $requestUri;
+        return $this;
+    }
+
+    /**
+     * Returns the REQUEST_URI taking into account
+     * platform differences between Apache and IIS
+     *
+     * @return string
+     */
+    public function getRequestUri()
+    {
+        if (empty($this->_requestUri)) {
+            $this->setRequestUri();
+        }
+
+        return $this->_requestUri;
+    }
+
+    /**
+     * Set the base URL of the request; i.e., the segment leading to the script name
+     *
+     * E.g.:
+     * - /admin
+     * - /myapp
+     * - /subdir/index.php
+     *
+     * Do not use the full URI when providing the base. The following are
+     * examples of what not to use:
+     * - http://example.com/admin (should be just /admin)
+     * - http://example.com/subdir/index.php (should be just /subdir/index.php)
+     *
+     * If no $baseUrl is provided, attempts to determine the base URL from the
+     * environment, using SCRIPT_FILENAME, SCRIPT_NAME, PHP_SELF, and
+     * ORIG_SCRIPT_NAME in its determination.
+     *
+     * @param mixed $baseUrl
+     * @return Zend_Controller_Request_Http
+     */
+    public function setBaseUrl($baseUrl = null)
+    {
+        if ((null !== $baseUrl) && !is_string($baseUrl)) {
+            return $this;
+        }
+
+        if ($baseUrl === null) {
+            $filename = (isset($_SERVER['SCRIPT_FILENAME'])) ? basename($_SERVER['SCRIPT_FILENAME']) : '';
+
+            if (isset($_SERVER['SCRIPT_NAME']) && basename($_SERVER['SCRIPT_NAME']) === $filename) {
+                $baseUrl = $_SERVER['SCRIPT_NAME'];
+            } elseif (isset($_SERVER['PHP_SELF']) && basename($_SERVER['PHP_SELF']) === $filename) {
+                $baseUrl = $_SERVER['PHP_SELF'];
+            } elseif (isset($_SERVER['ORIG_SCRIPT_NAME']) && basename($_SERVER['ORIG_SCRIPT_NAME']) === $filename) {
+                $baseUrl = $_SERVER['ORIG_SCRIPT_NAME']; // 1and1 shared hosting compatibility
+            } else {
+                // Backtrack up the script_filename to find the portion matching
+                // php_self
+                $path    = isset($_SERVER['PHP_SELF']) ? $_SERVER['PHP_SELF'] : '';
+                $file    = isset($_SERVER['SCRIPT_FILENAME']) ? $_SERVER['SCRIPT_FILENAME'] : '';
+                $segs    = explode('/', trim($file, '/'));
+                $segs    = array_reverse($segs);
+                $index   = 0;
+                $last    = count($segs);
+                $baseUrl = '';
+                do {
+                    $seg     = $segs[$index];
+                    $baseUrl = '/' . $seg . $baseUrl;
+                    ++$index;
+                } while (($last > $index) && (false !== ($pos = strpos($path, $baseUrl))) && (0 != $pos));
+            }
+
+            // Does the baseUrl have anything in common with the request_uri?
+            $requestUri = $this->getRequestUri();
+
+            if (0 === strpos($requestUri, $baseUrl)) {
+                // full $baseUrl matches
+                $this->_baseUrl = $baseUrl;
+                return $this;
+            }
+
+            if (0 === strpos($requestUri, dirname($baseUrl))) {
+                // directory portion of $baseUrl matches
+                $this->_baseUrl = rtrim(dirname($baseUrl), '/');
+                return $this;
+            }
+
+            $truncatedRequestUri = $requestUri;
+            if (($pos = strpos($requestUri, '?')) !== false) {
+                $truncatedRequestUri = substr($requestUri, 0, $pos);
+            }
+
+            $basename = basename($baseUrl);
+            if (empty($basename) || !strpos($truncatedRequestUri, $basename)) {
+                // no match whatsoever; set it blank
+                $this->_baseUrl = '';
+                return $this;
+            }
+
+            // If using mod_rewrite or ISAPI_Rewrite strip the script filename
+            // out of baseUrl. $pos !== 0 makes sure it is not matching a value
+            // from PATH_INFO or QUERY_STRING
+            if ((strlen($requestUri) >= strlen($baseUrl))
+                && ((false !== ($pos = strpos($requestUri, $baseUrl))) && ($pos !== 0)))
+            {
+                $baseUrl = substr($requestUri, 0, $pos + strlen($baseUrl));
+            }
+        }
+
+        $this->_baseUrl = rtrim($baseUrl, '/');
+        return $this;
+    }
+
+    /**
+     * Everything in REQUEST_URI before PATH_INFO
+     * <form action="<?=$baseUrl?>/news/submit" method="POST"/>
+     *
+     * @return string
+     */
+    public function getBaseUrl($raw = false)
+    {
+        if (null === $this->_baseUrl) {
+            $this->setBaseUrl();
+        }
+
+        return (($raw == false) ? urldecode($this->_baseUrl) : $this->_baseUrl);
+    }
+
+    /**
+     * Set the base path for the URL
+     *
+     * @param string|null $basePath
+     * @return Zend_Controller_Request_Http
+     */
+    public function setBasePath($basePath = null)
+    {
+        if ($basePath === null) {
+            $filename = (isset($_SERVER['SCRIPT_FILENAME']))
+                      ? basename($_SERVER['SCRIPT_FILENAME'])
+                      : '';
+
+            $baseUrl = $this->getBaseUrl();
+            if (empty($baseUrl)) {
+                $this->_basePath = '';
+                return $this;
+            }
+
+            if (basename($baseUrl) === $filename) {
+                $basePath = dirname($baseUrl);
+            } else {
+                $basePath = $baseUrl;
+            }
+        }
+
+        if (substr(PHP_OS, 0, 3) === 'WIN') {
+            $basePath = str_replace('\\', '/', $basePath);
+        }
+
+        $this->_basePath = rtrim($basePath, '/');
+        return $this;
+    }
+
+    /**
+     * Everything in REQUEST_URI before PATH_INFO not including the filename
+     * <img src="<?=$basePath?>/images/zend.png"/>
+     *
+     * @return string
+     */
+    public function getBasePath()
+    {
+        if (null === $this->_basePath) {
+            $this->setBasePath();
+        }
+
+        return $this->_basePath;
+    }
+
+    /**
+     * Set the PATH_INFO string
+     *
+     * @param string|null $pathInfo
+     * @return Zend_Controller_Request_Http
+     */
+    public function setPathInfo($pathInfo = null)
+    {
+        if ($pathInfo === null) {
+            $baseUrl = $this->getBaseUrl(); // this actually calls setBaseUrl() & setRequestUri()
+            $baseUrlRaw = $this->getBaseUrl(false);
+            $baseUrlEncoded = urlencode($baseUrlRaw);
+        
+            if (null === ($requestUri = $this->getRequestUri())) {
+                return $this;
+            }
+        
+            // Remove the query string from REQUEST_URI
+            if ($pos = strpos($requestUri, '?')) {
+                $requestUri = substr($requestUri, 0, $pos);
+            }
+            
+            if (!empty($baseUrl) || !empty($baseUrlRaw)) {
+                if (strpos($requestUri, $baseUrl) === 0) {
+                    $pathInfo = substr($requestUri, strlen($baseUrl));
+                } elseif (strpos($requestUri, $baseUrlRaw) === 0) {
+                    $pathInfo = substr($requestUri, strlen($baseUrlRaw));
+                } elseif (strpos($requestUri, $baseUrlEncoded) === 0) {
+                    $pathInfo = substr($requestUri, strlen($baseUrlEncoded));
+                } else {
+                    $pathInfo = $requestUri;
+                }
+            } else {
+                $pathInfo = $requestUri;
+            }
+        
+        }
+
+        $this->_pathInfo = (string) $pathInfo;
+        return $this;
+    }
+
+    /**
+     * Returns everything between the BaseUrl and QueryString.
+     * This value is calculated instead of reading PATH_INFO
+     * directly from $_SERVER due to cross-platform differences.
+     *
+     * @return string
+     */
+    public function getPathInfo()
+    {
+        if (empty($this->_pathInfo)) {
+            $this->setPathInfo();
+        }
+
+        return $this->_pathInfo;
+    }
+
+    /**
+     * Set allowed parameter sources
+     *
+     * Can be empty array, or contain one or more of '_GET' or '_POST'.
+     *
+     * @param  array $paramSoures
+     * @return Zend_Controller_Request_Http
+     */
+    public function setParamSources(array $paramSources = array())
+    {
+        $this->_paramSources = $paramSources;
+        return $this;
+    }
+
+    /**
+     * Get list of allowed parameter sources
+     *
+     * @return array
+     */
+    public function getParamSources()
+    {
+        return $this->_paramSources;
+    }
+
+    /**
+     * Set a userland parameter
+     *
+     * Uses $key to set a userland parameter. If $key is an alias, the actual
+     * key will be retrieved and used to set the parameter.
+     *
+     * @param mixed $key
+     * @param mixed $value
+     * @return Zend_Controller_Request_Http
+     */
+    public function setParam($key, $value)
+    {
+        $key = (null !== ($alias = $this->getAlias($key))) ? $alias : $key;
+        parent::setParam($key, $value);
+        return $this;
+    }
+
+    /**
+     * Retrieve a parameter
+     *
+     * Retrieves a parameter from the instance. Priority is in the order of
+     * userland parameters (see {@link setParam()}), $_GET, $_POST. If a
+     * parameter matching the $key is not found, null is returned.
+     *
+     * If the $key is an alias, the actual key aliased will be used.
+     *
+     * @param mixed $key
+     * @param mixed $default Default value to use if key not found
+     * @return mixed
+     */
+    public function getParam($key, $default = null)
+    {
+        $keyName = (null !== ($alias = $this->getAlias($key))) ? $alias : $key;
+
+        $paramSources = $this->getParamSources();
+        if (isset($this->_params[$keyName])) {
+            return $this->_params[$keyName];
+        } elseif (in_array('_GET', $paramSources) && (isset($_GET[$keyName]))) {
+            return $_GET[$keyName];
+        } elseif (in_array('_POST', $paramSources) && (isset($_POST[$keyName]))) {
+            return $_POST[$keyName];
+        }
+
+        return $default;
+    }
+
+    /**
+     * Retrieve an array of parameters
+     *
+     * Retrieves a merged array of parameters, with precedence of userland
+     * params (see {@link setParam()}), $_GET, $_POST (i.e., values in the
+     * userland params will take precedence over all others).
+     *
+     * @return array
+     */
+    public function getParams()
+    {
+        $return       = $this->_params;
+        $paramSources = $this->getParamSources();
+        if (in_array('_GET', $paramSources)
+            && isset($_GET)
+            && is_array($_GET)
+        ) {
+            $return += $_GET;
+        }
+        if (in_array('_POST', $paramSources)
+            && isset($_POST)
+            && is_array($_POST)
+        ) {
+            $return += $_POST;
+        }
+        return $return;
+    }
+
+    /**
+     * Set parameters
+     *
+     * Set one or more parameters. Parameters are set as userland parameters,
+     * using the keys specified in the array.
+     *
+     * @param array $params
+     * @return Zend_Controller_Request_Http
+     */
+    public function setParams(array $params)
+    {
+        foreach ($params as $key => $value) {
+            $this->setParam($key, $value);
+        }
+        return $this;
+    }
+
+    /**
+     * Set a key alias
+     *
+     * Set an alias used for key lookups. $name specifies the alias, $target
+     * specifies the actual key to use.
+     *
+     * @param string $name
+     * @param string $target
+     * @return Zend_Controller_Request_Http
+     */
+    public function setAlias($name, $target)
+    {
+        $this->_aliases[$name] = $target;
+        return $this;
+    }
+
+    /**
+     * Retrieve an alias
+     *
+     * Retrieve the actual key represented by the alias $name.
+     *
+     * @param string $name
+     * @return string|null Returns null when no alias exists
+     */
+    public function getAlias($name)
+    {
+        if (isset($this->_aliases[$name])) {
+            return $this->_aliases[$name];
+        }
+
+        return null;
+    }
+
+    /**
+     * Retrieve the list of all aliases
+     *
+     * @return array
+     */
+    public function getAliases()
+    {
+        return $this->_aliases;
+    }
+
+    /**
+     * Return the method by which the request was made
+     *
+     * @return string
+     */
+    public function getMethod()
+    {
+        return $this->getServer('REQUEST_METHOD');
+    }
+
+    /**
+     * Was the request made by POST?
+     *
+     * @return boolean
+     */
+    public function isPost()
+    {
+        if ('POST' == $this->getMethod()) {
+            return true;
+        }
+
+        return false;
+    }
+
+    /**
+     * Was the request made by GET?
+     *
+     * @return boolean
+     */
+    public function isGet()
+    {
+        if ('GET' == $this->getMethod()) {
+            return true;
+        }
+
+        return false;
+    }
+
+    /**
+     * Was the request made by PUT?
+     *
+     * @return boolean
+     */
+    public function isPut()
+    {
+        if ('PUT' == $this->getMethod()) {
+            return true;
+        }
+
+        return false;
+    }
+
+    /**
+     * Was the request made by DELETE?
+     *
+     * @return boolean
+     */
+    public function isDelete()
+    {
+        if ('DELETE' == $this->getMethod()) {
+            return true;
+        }
+
+        return false;
+    }
+
+    /**
+     * Was the request made by HEAD?
+     *
+     * @return boolean
+     */
+    public function isHead()
+    {
+        if ('HEAD' == $this->getMethod()) {
+            return true;
+        }
+
+        return false;
+    }
+
+    /**
+     * Was the request made by OPTIONS?
+     *
+     * @return boolean
+     */
+    public function isOptions()
+    {
+        if ('OPTIONS' == $this->getMethod()) {
+            return true;
+        }
+
+        return false;
+    }
+
+    /**
+     * Was the request made by PATCH?
+     *
+     * @return boolean
+     */
+    public function isPatch()
+    {
+        if ('PATCH' == $this->getMethod()) {
+            return true;
+        }
+
+        return false;
+    }
+
+    /**
+     * Is the request a Javascript XMLHttpRequest?
+     *
+     * Should work with Prototype/Script.aculo.us, possibly others.
+     *
+     * @return boolean
+     */
+    public function isXmlHttpRequest()
+    {
+        return ($this->getHeader('X_REQUESTED_WITH') == 'XMLHttpRequest');
+    }
+
+    /**
+     * Is this a Flash request?
+     *
+     * @return boolean
+     */
+    public function isFlashRequest()
+    {
+        $header = strtolower($this->getHeader('USER_AGENT'));
+        return (strstr($header, ' flash')) ? true : false;
+    }
+
+    /**
+     * Is https secure request
+     *
+     * @return boolean
+     */
+    public function isSecure()
+    {
+        return ($this->getScheme() === self::SCHEME_HTTPS);
+    }
+
+    /**
+     * Return the raw body of the request, if present
+     *
+     * @return string|false Raw body, or false if not present
+     */
+    public function getRawBody()
+    {
+        if (null === $this->_rawBody) {
+            $body = file_get_contents('php://input');
+
+            if (strlen(trim($body)) > 0) {
+                $this->_rawBody = $body;
+            } else {
+                $this->_rawBody = false;
+            }
+        }
+        return $this->_rawBody;
+    }
+
+    /**
+     * Return the value of the given HTTP header. Pass the header name as the
+     * plain, HTTP-specified header name. Ex.: Ask for 'Accept' to get the
+     * Accept header, 'Accept-Encoding' to get the Accept-Encoding header.
+     *
+     * @param string $header HTTP header name
+     * @return string|false HTTP header value, or false if not found
+     * @throws Zend_Controller_Request_Exception
+     */
+    public function getHeader($header)
+    {
+        if (empty($header)) {
+            #require_once 'Zend/Controller/Request/Exception.php';
+            throw new Zend_Controller_Request_Exception('An HTTP header name is required');
+        }
+
+        // Try to get it from the $_SERVER array first
+        $temp = strtoupper(str_replace('-', '_', $header));
+        if (isset($_SERVER['HTTP_' . $temp])) {
+            return $_SERVER['HTTP_' . $temp];
+        }
+
+        /*
+         * Try to get it from the $_SERVER array on POST request or CGI environment
+         * @see https://www.ietf.org/rfc/rfc3875 (4.1.2. and 4.1.3.)
+         */
+        if (isset($_SERVER[$temp])
+            && in_array($temp, array('CONTENT_TYPE', 'CONTENT_LENGTH'))
+        ) {
+            return $_SERVER[$temp];
+        }
+
+        // This seems to be the only way to get the Authorization header on
+        // Apache
+        if (function_exists('apache_request_headers')) {
+            $headers = apache_request_headers();
+            if (isset($headers[$header])) {
+                return $headers[$header];
+            }
+            $header = strtolower($header);
+            foreach ($headers as $key => $value) {
+                if (strtolower($key) == $header) {
+                    return $value;
+                }
+            }
+        }
+
+        return false;
+    }
+
+    /**
+     * Get the request URI scheme
+     *
+     * @return string
+     */
+    public function getScheme()
+    {
+        return ($this->getServer('HTTPS') == 'on') ? self::SCHEME_HTTPS : self::SCHEME_HTTP;
+    }
+
+    /**
+     * Get the HTTP host.
+     *
+     * "Host" ":" host [ ":" port ] ; Section 3.2.2
+     * Note the HTTP Host header is not the same as the URI host.
+     * It includes the port while the URI host doesn't.
+     *
+     * @return string
+     */
+    public function getHttpHost()
+    {
+        $host = $this->getServer('HTTP_HOST');
+        if (!empty($host)) {
+            return $host;
+        }
+
+        $scheme = $this->getScheme();
+        $name   = $this->getServer('SERVER_NAME');
+        $port   = $this->getServer('SERVER_PORT');
+
+        if(null === $name) {
+            return '';
+        }
+        elseif (($scheme == self::SCHEME_HTTP && $port == 80) || ($scheme == self::SCHEME_HTTPS && $port == 443)) {
+            return $name;
+        } else {
+            return $name . ':' . $port;
+        }
+    }
+
+    /**
+     * Get the client's IP addres
+     *
+     * @param  boolean $checkProxy
+     * @return string
+     */
+    public function getClientIp($checkProxy = true)
+    {
+        if ($checkProxy && $this->getServer('HTTP_CLIENT_IP') != null) {
+            $ip = $this->getServer('HTTP_CLIENT_IP');
+        } else if ($checkProxy && $this->getServer('HTTP_X_FORWARDED_FOR') != null) {
+            $ip = $this->getServer('HTTP_X_FORWARDED_FOR');
+        } else {
+            $ip = $this->getServer('REMOTE_ADDR');
+        }
+
+        return $ip;
+    }
+}
diff --git app/design/adminhtml/default/default/template/cms/browser/content/files.phtml app/design/adminhtml/default/default/template/cms/browser/content/files.phtml
index 28bc51adaba..677bb5e804c 100644
--- app/design/adminhtml/default/default/template/cms/browser/content/files.phtml
+++ app/design/adminhtml/default/default/template/cms/browser/content/files.phtml
@@ -40,7 +40,7 @@ $_height = $this->getImagesHeight();
     <div class="filecnt" id="<?php echo $this->getFileId($file) ?>">
         <p class="nm" style="height:<?php echo $_height ?>px;width:<?php echo $_width ?>px;">
         <?php if($this->getFileThumbUrl($file)):?>
-            <img src="<?php echo $this->getFileThumbUrl($file) ?>" alt="<?php echo $this->getFileName($file) ?>"/>
+            <img src="<?php echo $this->getFileThumbUrl($file) ?>" alt="<?php echo $this->escapeHtml($this->getFileName($file)) ?>"/>
         <?php endif; ?>
         </p>
         <?php if($this->getFileWidth($file)): ?>
diff --git app/design/frontend/base/default/layout/captcha.xml app/design/frontend/base/default/layout/captcha.xml
index 25aaf030b2a..4e2ef4222d0 100755
--- app/design/frontend/base/default/layout/captcha.xml
+++ app/design/frontend/base/default/layout/captcha.xml
@@ -103,4 +103,18 @@
             </block>
         </reference>
     </checkout_onepage_index>
+    <wishlist_index_share>
+        <reference name="wishlist.sharing">
+            <block type="core/text_list" name="wishlist.sharing.form.additional.info">
+                <block type="captcha/captcha" name="captcha">
+                    <reference name="head">
+                        <action method="addJs"><file>mage/captcha.js</file></action>
+                    </reference>
+                    <action method="setFormId"><formId>wishlist_sharing</formId></action>
+                    <action method="setImgWidth"><width>230</width></action>
+                    <action method="setImgHeight"><width>50</width></action>
+                </block>
+            </block>
+        </reference>
+    </wishlist_index_share>
 </layout>
diff --git app/design/frontend/base/default/template/wishlist/sharing.phtml app/design/frontend/base/default/template/wishlist/sharing.phtml
index 62e9c460a6f..ad10356dd95 100644
--- app/design/frontend/base/default/template/wishlist/sharing.phtml
+++ app/design/frontend/base/default/template/wishlist/sharing.phtml
@@ -34,7 +34,7 @@
         <h2 class="legend"><?php echo $this->__('Sharing Information') ?></h2>
         <ul class="form-list">
             <li class="wide">
-                <label for="email_address" class="required"><em>*</em><?php echo $this->__('Email addresses, separated by commas') ?></label>
+                <label for="email_address" class="required"><em>*</em><?php echo $this->__('Up to 5 email addresses, separated by commas') ?></label>
                 <div class="input-box">
                     <textarea name="emails" cols="60" rows="5" id="email_address" class="validate-emails required-entry"><?php echo $this->getEnteredData('emails') ?></textarea>
                 </div>
@@ -42,7 +42,7 @@
             <li class="wide">
                 <label for="message"><?php echo $this->__('Message') ?></label>
                 <div class="input-box">
-                    <textarea id="message" name="message" cols="60" rows="5"><?php echo $this->getEnteredData('message') ?></textarea>
+                    <textarea id="message" name="message" cols="60" rows="3"><?php echo $this->getEnteredData('message') ?></textarea>
                 </div>
             </li>
             <?php if($this->helper('wishlist')->isRssAllow()): ?>
@@ -53,6 +53,7 @@
                 <label for="rss_url"><?php echo $this->__('Check this checkbox if you want to add a link to an rss feed to your wishlist.') ?></label>
             </li>
             <?php endif; ?>
+            <?php echo $this->getChildHtml('wishlist.sharing.form.additional.info'); ?>
         </ul>
     </div>
     <div class="buttons-set form-buttons">
diff --git app/etc/modules/Mage_All.xml app/etc/modules/Mage_All.xml
index 7a47a0c45cf..e16499f23a5 100644
--- app/etc/modules/Mage_All.xml
+++ app/etc/modules/Mage_All.xml
@@ -234,7 +234,7 @@
             </depends>
         </Mage_Log>
         <Mage_Backup>
-            <active>true</active>
+            <active>false</active>
             <codePool>core</codePool>
             <depends>
                 <Mage_Core/>
diff --git app/etc/modules/Mage_Captcha.xml app/etc/modules/Mage_Captcha.xml
index ef84e715540..9a0ae249ec7 100755
--- app/etc/modules/Mage_Captcha.xml
+++ app/etc/modules/Mage_Captcha.xml
@@ -33,6 +33,7 @@
             <depends>
                 <Mage_Customer />
                 <Mage_Adminhtml />
+                <Mage_Wishlist />
             </depends>
         </Mage_Captcha>
     </modules>
diff --git app/locale/en_US/Mage_Wishlist.csv app/locale/en_US/Mage_Wishlist.csv
index 598b2d67909..03316dc76ca 100644
--- app/locale/en_US/Mage_Wishlist.csv
+++ app/locale/en_US/Mage_Wishlist.csv
@@ -63,6 +63,7 @@
 "Options Details","Options Details"
 "Out of stock","Out of stock"
 "Please enter a valid email addresses, separated by commas. For example johndoe@domain.com, johnsmith@domain.com.","Please enter a valid email addresses, separated by commas. For example johndoe@domain.com, johnsmith@domain.com."
+"Please enter no more than 5 email addresses.","Please enter no more than 5 email addresses."
 "Please input a valid email address.","Please input a valid email address."
 "Please, enter your comments...","Please, enter your comments..."
 "Product","Product"
@@ -82,6 +83,7 @@
 "This Wishlist has no Items","This Wishlist has no Items"
 "This product(s) is currently out of stock","This product(s) is currently out of stock"
 "Unable to add the following product(s) to shopping cart: %s.","Unable to add the following product(s) to shopping cart: %s."
+"Up to 5 email addresses, separated by commas","Up to 5 email addresses, separated by commas"
 "Update Wishlist","Update Wishlist"
 "User description","User description"
 "View Details","View Details"
