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


SUPEE-10975_CE_v1.6.2.0 | CE_1.6.2.0 | v1 | 4858112f5f08d7b906b38c344e355f09ad204bbe | Sat Nov 24 02:29:32 2018 +0200 | ce-1.6.2.0-dev

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Adminhtml/Block/Customer/Group/Edit.php app/code/core/Mage/Adminhtml/Block/Customer/Group/Edit.php
index 237c262b5fa..cc94481e41c 100644
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
index 50205e187fd..2e17fd17fb3 100644
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
index 4c99d0fb4db..780c82a810b 100644
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
index ac24e8edfc1..a14731867af 100644
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
index d5c435020da..00955be71b8 100644
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
index 976de5ca7bd..3cfa65dd051 100644
--- app/code/core/Mage/Adminhtml/controllers/System/BackupController.php
+++ app/code/core/Mage/Adminhtml/controllers/System/BackupController.php
@@ -149,7 +149,9 @@ class Mage_Adminhtml_System_BackupController extends Mage_Adminhtml_Controller_A
 
     protected function _isAllowed()
     {
-        return Mage::getSingleton('admin/session')->isAllowed('system/tools/backup');
+        return Mage::getSingleton('admin/session')->isAllowed('system/tools/backup')
+            && Mage::helper('core')->isModuleEnabled('Mage_Backup')
+            && !Mage::getStoreConfigFlag('advanced/modules_disable_output/Mage_Backup');
     }
 
     /**
diff --git app/code/core/Mage/Catalog/Model/Product/Attribute/Media/Api.php app/code/core/Mage/Catalog/Model/Product/Attribute/Media/Api.php
index 01311b39222..e540a7daeee 100644
--- app/code/core/Mage/Catalog/Model/Product/Attribute/Media/Api.php
+++ app/code/core/Mage/Catalog/Model/Product/Attribute/Media/Api.php
@@ -153,6 +153,17 @@ class Mage_Catalog_Model_Product_Attribute_Media_Api extends Mage_Catalog_Model_
             $ioAdapter->write($fileName, $fileContent, 0666);
             unset($fileContent);
 
+            // try to create Image object - it fails with Exception if image is not supported
+            try {
+                $filePath = $tmpDirectory . DS . $fileName;
+                new Varien_Image($filePath);
+                Mage::getModel('core/file_validator_image')->validate($filePath);
+            } catch (Exception $e) {
+                // Remove temporary directory
+                $ioAdapter->rmdir($tmpDirectory, true);
+                throw new Mage_Core_Exception($e->getMessage());
+            }
+
             // Adding image to gallery
             $file = $gallery->getBackend()->addImage(
                 $product,
diff --git app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
index 8554473d51b..7347c4f19fa 100644
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
index 753ab3fb000..c852392ec7c 100644
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
@@ -374,8 +374,13 @@
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
@@ -393,6 +398,7 @@
                     <!-- BOF HTML file extensions -->
                     <htm>htm</htm>
                     <html>html</html>
+                    <pht>pht</pht>
                     <phtml>phtml</phtml>
                     <shtml>shtml</shtml>
                     <!-- EOF HTML file extensions -->
diff --git app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
index b3375eb7dff..a9152dda051 100644
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
index 9fe5f6ce572..2245578cc1a 100644
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
index b264f0d4ac8..6e634eadec7 100644
--- app/code/core/Mage/ImportExport/Model/Import/Entity/Customer/Address.php
+++ app/code/core/Mage/ImportExport/Model/Import/Entity/Customer/Address.php
@@ -260,7 +260,9 @@ class Mage_ImportExport_Model_Import_Entity_Customer_Address extends Mage_Import
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
index 27e207e9b27..e5c301bbc72 100644
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
@@ -150,15 +153,6 @@
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
index 977c4d7063f..e62f1b7086e 100644
--- app/code/core/Mage/Payment/etc/system.xml
+++ app/code/core/Mage/Payment/etc/system.xml
@@ -36,139 +36,6 @@
             <show_in_website>1</show_in_website>
             <show_in_store>1</show_in_store>
             <groups>
-                <ccsave translate="label">
-                    <label>Saved CC</label>
-                    <frontend_type>text</frontend_type>
-                    <sort_order>1</sort_order>
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
diff --git app/code/core/Mage/Wishlist/controllers/IndexController.php app/code/core/Mage/Wishlist/controllers/IndexController.php
index 396527b3b70..1c0cd6ccfa1 100644
--- app/code/core/Mage/Wishlist/controllers/IndexController.php
+++ app/code/core/Mage/Wishlist/controllers/IndexController.php
@@ -540,6 +540,9 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
         if (empty($emails)) {
             $error = $this->__('Email address can\'t be empty.');
         }
+        elseif (count($emails) > 5) {
+            $error = $this->__('Please enter no more than 5 email addresses.');
+        }
         else {
             foreach ($emails as $index => $email) {
                 $email = trim($email);
diff --git app/design/adminhtml/default/default/template/cms/browser/content/files.phtml app/design/adminhtml/default/default/template/cms/browser/content/files.phtml
index c101e3545a3..c10b830d826 100644
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
diff --git app/design/frontend/base/default/template/wishlist/sharing.phtml app/design/frontend/base/default/template/wishlist/sharing.phtml
index 72a72d1580a..7008fb9c314 100644
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
index f724a779214..55507c844c8 100644
--- app/etc/modules/Mage_All.xml
+++ app/etc/modules/Mage_All.xml
@@ -233,7 +233,7 @@
             </depends>
         </Mage_Log>
         <Mage_Backup>
-            <active>true</active>
+            <active>false</active>
             <codePool>core</codePool>
             <depends>
                 <Mage_Core/>
diff --git app/locale/en_US/Mage_Wishlist.csv app/locale/en_US/Mage_Wishlist.csv
index b9cc90cafb4..fea870e7292 100644
--- app/locale/en_US/Mage_Wishlist.csv
+++ app/locale/en_US/Mage_Wishlist.csv
@@ -60,6 +60,7 @@
 "Options Details","Options Details"
 "Out of stock","Out of stock"
 "Please enter a valid email addresses, separated by commas. For example johndoe@domain.com, johnsmith@domain.com.","Please enter a valid email addresses, separated by commas. For example johndoe@domain.com, johnsmith@domain.com."
+"Please enter no more than 5 email addresses.","Please enter no more than 5 email addresses."
 "Please input a valid email address.","Please input a valid email address."
 "Please, enter your comments...","Please, enter your comments..."
 "Product","Product"
@@ -75,6 +76,7 @@
 "Sharing Information","Sharing Information"
 "This product(s) is currently out of stock","This product(s) is currently out of stock"
 "Unable to add the following product(s) to shopping cart: %s.","Unable to add the following product(s) to shopping cart: %s."
+"Up to 5 email addresses, separated by commas","Up to 5 email addresses, separated by commas"
 "Update Wishlist","Update Wishlist"
 "User description","User description"
 "View Details","View Details"
