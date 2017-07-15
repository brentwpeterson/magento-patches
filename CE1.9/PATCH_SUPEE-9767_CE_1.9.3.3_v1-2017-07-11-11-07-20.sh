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


PATCH_SUPEE-9767_CE_1.9.3.3_v2 | CE_1.9.3.3 | v2 | 6566db274beaeb9bcdb56a62e02cc2da532e618c | Thu Jun 22 04:30:03 2017 +0300 | v1.14.3.3..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Symlink.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Symlink.php
new file mode 100644
index 0000000..d211255
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Symlink.php
@@ -0,0 +1,44 @@
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
+ * @package     Mage_Adminhtml
+ * @copyright  Copyright (c) 2006-2017 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * System config symlink backend model
+ *
+ * @category Mage
+ * @package  Mage_Adminhtml
+ */
+class Mage_Adminhtml_Model_System_Config_Backend_Symlink extends Mage_Core_Model_Config_Data
+{
+    /**
+     * Save object data
+     *
+     * @return Mage_Core_Model_Abstract
+     */
+    public function save()
+    {
+        return $this;
+    }
+}
diff --git app/code/core/Mage/Checkout/controllers/OnepageController.php app/code/core/Mage/Checkout/controllers/OnepageController.php
index 98bd359..f926b92 100644
--- app/code/core/Mage/Checkout/controllers/OnepageController.php
+++ app/code/core/Mage/Checkout/controllers/OnepageController.php
@@ -350,10 +350,6 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
             return;
         }
 
-        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
-            return;
-        }
-
         if ($this->getRequest()->isPost()) {
             $method = $this->getRequest()->getPost('method');
             $result = $this->getOnepage()->saveCheckoutMethod($method);
diff --git app/code/core/Mage/Core/Model/File/Validator/Image.php app/code/core/Mage/Core/Model/File/Validator/Image.php
index e24f8b9..9d57202 100644
--- app/code/core/Mage/Core/Model/File/Validator/Image.php
+++ app/code/core/Mage/Core/Model/File/Validator/Image.php
@@ -95,9 +95,26 @@ class Mage_Core_Model_File_Validator_Image
                 $image = imagecreatefromstring(file_get_contents($filePath));
                 if ($image !== false) {
                     $img = imagecreatetruecolor($imageWidth, $imageHeight);
+                    imagealphablending($img, false);
                     imagecopyresampled($img, $image, 0, 0, 0, 0, $imageWidth, $imageHeight, $imageWidth, $imageHeight);
+                    imagesavealpha($img, true);
+
                     switch ($fileType) {
                         case IMAGETYPE_GIF:
+                            $transparencyIndex = imagecolortransparent($image);
+                            if ($transparencyIndex >= 0) {
+                                imagecolortransparent($img, $transparencyIndex);
+                                for ($y = 0; $y < $imageHeight; ++$y) {
+                                    for ($x = 0; $x < $imageWidth; ++$x) {
+                                        if (((imagecolorat($img, $x, $y) >> 24) & 0x7F)) {
+                                            imagesetpixel($img, $x, $y, $transparencyIndex);
+                                        }
+                                    }
+                                }
+                            }
+                            if (!imageistruecolor($image)) {
+                                imagetruecolortopalette($img, false, imagecolorstotal($image));
+                            }
                             imagegif($img, $filePath);
                             break;
                         case IMAGETYPE_JPEG:
@@ -107,8 +124,9 @@ class Mage_Core_Model_File_Validator_Image
                             imagepng($img, $filePath);
                             break;
                         default:
-                            return;
+                            break;
                     }
+
                     imagedestroy($img);
                     imagedestroy($image);
                     return null;
diff --git app/code/core/Mage/Core/etc/config.xml app/code/core/Mage/Core/etc/config.xml
index 15114c5..c0ee1a2 100644
--- app/code/core/Mage/Core/etc/config.xml
+++ app/code/core/Mage/Core/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Mage_Core>
-            <version>1.6.0.6</version>
+            <version>1.6.0.6.1.2</version>
         </Mage_Core>
     </modules>
     <global>
diff --git app/code/core/Mage/Core/etc/system.xml app/code/core/Mage/Core/etc/system.xml
index 5dcd7b8..964a806 100644
--- app/code/core/Mage/Core/etc/system.xml
+++ app/code/core/Mage/Core/etc/system.xml
@@ -597,6 +597,27 @@
                         </template_hints_blocks>
                     </fields>
                 </debug>
+                <template translate="label">
+                    <label>Template Settings</label>
+                    <frontend_type>text</frontend_type>
+                    <sort_order>25</sort_order>
+                    <show_in_default>0</show_in_default>
+                    <show_in_website>0</show_in_website>
+                    <show_in_store>0</show_in_store>
+                    <fields>
+                        <allow_symlink translate="label comment">
+                            <label>Allow Symlinks</label>
+                            <frontend_type>select</frontend_type>
+                            <source_model>adminhtml/system_config_source_yesno</source_model>
+                            <backend_model>adminhtml/system_config_backend_symlink</backend_model>
+                            <sort_order>10</sort_order>
+                            <show_in_default>0</show_in_default>
+                            <show_in_website>0</show_in_website>
+                            <show_in_store>0</show_in_store>
+                            <comment>Warning! Enabling this feature is not recommended on production environments because it represents a potential security risk.</comment>
+                        </allow_symlink>
+                    </fields>
+                </template>
                 <translate_inline translate="label">
                     <label>Translate Inline</label>
                     <frontend_type>text</frontend_type>
diff --git app/code/core/Mage/Core/sql/core_setup/upgrade-1.6.0.6.1.1-1.6.0.6.1.2.php app/code/core/Mage/Core/sql/core_setup/upgrade-1.6.0.6.1.1-1.6.0.6.1.2.php
new file mode 100644
index 0000000..c3a50a5
--- /dev/null
+++ app/code/core/Mage/Core/sql/core_setup/upgrade-1.6.0.6.1.1-1.6.0.6.1.2.php
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
+ * @package     Mage_Core
+ * @copyright  Copyright (c) 2006-2017 X.commerce, Inc. and affiliates (http://www.magento.com)
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
+        'like' => 'dev/template/allow_symlink'
+    ))
+);
+
+$installer->endSetup();
diff --git app/design/adminhtml/default/default/layout/main.xml app/design/adminhtml/default/default/layout/main.xml
index 78ba06d..19d95fe 100644
--- app/design/adminhtml/default/default/layout/main.xml
+++ app/design/adminhtml/default/default/layout/main.xml
@@ -119,8 +119,9 @@ Default layout, loads most of the pages
                 <block type="adminhtml/cache_notifications" name="cache_notifications" template="system/cache/notifications.phtml"></block>
                 <block type="adminhtml/notification_survey" name="notification_survey" template="notification/survey.phtml"/>
                 <block type="adminhtml/notification_security" name="notification_security" as="notification_security" template="notification/security.phtml"></block>
-                <block type="adminhtml/checkout_formkey" name="checkout_formkey" as="checkout_formkey" template="notification/formkey.phtml"/></block>
+                <block type="adminhtml/checkout_formkey" name="checkout_formkey" as="checkout_formkey" template="notification/formkey.phtml"/>
                 <block type="adminhtml/notification_symlink" name="notification_symlink" template="notification/symlink.phtml"/>
+            </block>
             <block type="adminhtml/widget_breadcrumbs" name="breadcrumbs" as="breadcrumbs"></block>
 
             <!--<update handle="formkey"/> this won't work, see the try/catch and a jammed exception in Mage_Core_Model_Layout::createBlock() -->
diff --git app/design/adminhtml/default/default/template/oauth/authorize/head-simple.phtml app/design/adminhtml/default/default/template/oauth/authorize/head-simple.phtml
index 9ad6cdff..348ffbf 100644
--- app/design/adminhtml/default/default/template/oauth/authorize/head-simple.phtml
+++ app/design/adminhtml/default/default/template/oauth/authorize/head-simple.phtml
@@ -42,7 +42,7 @@
     var BLANK_URL = '<?php echo $this->getJsUrl() ?>blank.html';
     var BLANK_IMG = '<?php echo $this->getJsUrl() ?>spacer.gif';
     var BASE_URL = '<?php echo $this->getUrl('*') ?>';
-    var SKIN_URL = '<?php echo $this->getSkinUrl() ?>';
+    var SKIN_URL = '<?php echo $this->jsQuoteEscape($this->getSkinUrl()) ?>';
     var FORM_KEY = '<?php echo $this->getFormKey() ?>';
 //]]>
 </script>
diff --git app/design/frontend/base/default/template/checkout/multishipping/addresses.phtml app/design/frontend/base/default/template/checkout/multishipping/addresses.phtml
index 272852e..9a0b59b 100644
--- app/design/frontend/base/default/template/checkout/multishipping/addresses.phtml
+++ app/design/frontend/base/default/template/checkout/multishipping/addresses.phtml
@@ -84,4 +84,5 @@
             <button type="submit" data-action="checkout-continue-shipping" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Continue to Shipping Information')) ?>" class="button<?php if ($this->isContinueDisabled()):?> disabled<?php endif; ?>" onclick="$('can_continue_flag').value=1"<?php if ($this->isContinueDisabled()):?> disabled="disabled"<?php endif; ?>><span><span><?php echo $this->__('Continue to Shipping Information') ?></span></span></button>
         </div>
     </div>
+    <?php echo $this->getBlockHtml("formkey") ?>
 </form>
diff --git app/design/frontend/base/default/template/checkout/onepage/payment.phtml app/design/frontend/base/default/template/checkout/onepage/payment.phtml
index d05c19a..079996f 100644
--- app/design/frontend/base/default/template/checkout/onepage/payment.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/payment.phtml
@@ -36,8 +36,8 @@
 <form action="" id="co-payment-form">
     <fieldset>
         <?php echo $this->getChildHtml('methods') ?>
-        <?php echo $this->getBlockHtml('formkey') ?>
     </fieldset>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </form>
 <div class="tool-tip" id="payment-tool-tip" style="display:none;">
     <div class="btn-close"><a href="#" id="payment-tool-tip-close" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Close')) ?>"><?php echo $this->__('Close') ?></a></div>
diff --git app/design/frontend/rwd/default/template/checkout/onepage/payment.phtml app/design/frontend/rwd/default/template/checkout/onepage/payment.phtml
index b0ed34d..382515f 100644
--- app/design/frontend/rwd/default/template/checkout/onepage/payment.phtml
+++ app/design/frontend/rwd/default/template/checkout/onepage/payment.phtml
@@ -37,8 +37,8 @@
     <div class="fieldset">
         <?php echo $this->getChildChildHtml('methods_additional', '', true, true) ?>
         <?php echo $this->getChildHtml('methods') ?>
-        <?php echo $this->getBlockHtml('formkey') ?>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </form>
 <div class="tool-tip" id="payment-tool-tip" style="display:none;">
     <div class="btn-close"><a href="#" id="payment-tool-tip-close" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Close')) ?>"><?php echo $this->__('Close') ?></a></div>
