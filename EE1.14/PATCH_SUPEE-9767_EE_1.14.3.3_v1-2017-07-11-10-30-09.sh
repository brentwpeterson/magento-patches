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


PATCH_SUPEE-9767_EE_1.14.3.3_v1 | EE_1.14.3.3 | v1 | 6566db274beaeb9bcdb56a62e02cc2da532e618c | Thu Jun 22 04:30:03 2017 +0300 | v1.14.3.3..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Symlink.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Symlink.php
new file mode 100644
index 0000000..7ee8cdc
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Symlink.php
@@ -0,0 +1,44 @@
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
+ * @package     Mage_Adminhtml
+ * @copyright Copyright (c) 2006-2017 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
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
index a321607..2d50db3 100644
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
index 717fd4d..04d722d 100644
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
index 7a732f5..de7d987 100644
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
index 8deab15..300bb9d 100644
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
index 0000000..8db7130
--- /dev/null
+++ app/code/core/Mage/Core/sql/core_setup/upgrade-1.6.0.6.1.1-1.6.0.6.1.2.php
@@ -0,0 +1,40 @@
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
+ * @package     Mage_Core
+ * @copyright Copyright (c) 2006-2017 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
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
index 48ae4f0..c673696 100644
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
index e3d03ea..6f7a267 100644
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
index 4094b37..5d4a006 100644
--- app/design/frontend/base/default/template/checkout/multishipping/addresses.phtml
+++ app/design/frontend/base/default/template/checkout/multishipping/addresses.phtml
@@ -84,4 +84,5 @@
             <button type="submit" data-action="checkout-continue-shipping" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Continue to Shipping Information')) ?>" class="button<?php if ($this->isContinueDisabled()):?> disabled<?php endif; ?>" onclick="$('can_continue_flag').value=1"<?php if ($this->isContinueDisabled()):?> disabled="disabled"<?php endif; ?>><span><span><?php echo $this->__('Continue to Shipping Information') ?></span></span></button>
         </div>
     </div>
+    <?php echo $this->getBlockHtml("formkey") ?>
 </form>
diff --git app/design/frontend/base/default/template/checkout/onepage/payment.phtml app/design/frontend/base/default/template/checkout/onepage/payment.phtml
index cfe2910..527f069 100644
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
diff --git app/design/frontend/enterprise/default/template/checkout/onepage/payment.phtml app/design/frontend/enterprise/default/template/checkout/onepage/payment.phtml
index c851e5f..6071dff 100644
--- app/design/frontend/enterprise/default/template/checkout/onepage/payment.phtml
+++ app/design/frontend/enterprise/default/template/checkout/onepage/payment.phtml
@@ -36,8 +36,8 @@
     <fieldset>
         <?php echo $this->getChildChildHtml('methods_additional', '', true, true) ?>
         <?php echo $this->getChildHtml('methods') ?>
-        <?php echo $this->getBlockHtml('formkey') ?>
     </fieldset>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </form>
 <div class="tool-tip" id="payment-tool-tip" style="display:none;">
     <div class="btn-close"><a href="#" id="payment-tool-tip-close"><img src="<?php echo $this->getSkinUrl('images/btn_window_close.gif') ?>" alt="<?php echo Mage::helper('core')->quoteEscape($this->__('Close')) ?>" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Close')) ?>" /></a></div>
diff --git app/design/frontend/enterprise/default/template/checkout/onepage/shipping.phtml app/design/frontend/enterprise/default/template/checkout/onepage/shipping.phtml
index 9bb7099..64c46dc 100644
--- app/design/frontend/enterprise/default/template/checkout/onepage/shipping.phtml
+++ app/design/frontend/enterprise/default/template/checkout/onepage/shipping.phtml
@@ -150,6 +150,7 @@
     <span id="shipping-please-wait" class="please-wait" style="display:none;"><img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="" class="v-middle" /> <?php echo $this->__('Loading next step...') ?></span>
 </div>
 <p class="required"><?php echo $this->__('* Required Fields') ?></p>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </form>
 <script type="text/javascript">
 //<![CDATA[
diff --git app/design/frontend/rwd/default/template/checkout/onepage/payment.phtml app/design/frontend/rwd/default/template/checkout/onepage/payment.phtml
index 35e0211..7b8af2d 100644
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
diff --git skin/frontend/enterprise/default/js/opcheckout.js skin/frontend/enterprise/default/js/opcheckout.js
index 9914dbf..dfd9395 100644
--- skin/frontend/enterprise/default/js/opcheckout.js
+++ skin/frontend/enterprise/default/js/opcheckout.js
@@ -34,7 +34,7 @@ Checkout.prototype = {
         this.saveMethodUrl = urls.saveMethod;
         this.failureUrl = urls.failure;
         this.billingForm = false;
-        this.shippingForm= false;
+        this.shippingForm = false;
         this.syncBillingShipping = false;
         this.method = '';
         this.payment = '';
@@ -56,7 +56,7 @@ Checkout.prototype = {
      * @param event
      */
     _onSectionClick: function(event) {
-        var section = $(Event.element(event).up().up());
+        var section = $(Event.element(event).up('.section'));
         if (section.hasClassName('allow')) {
             Event.stop(event);
             this.gotoSection(section.readAttribute('id').replace('opc-', ''), false);
@@ -65,7 +65,7 @@ Checkout.prototype = {
     },
 
     ajaxFailure: function(){
-        location.href = this.failureUrl;
+        location.href = encodeURI(this.failureUrl);
     },
 
     reloadProgressBlock: function(toStep) {
@@ -87,7 +87,7 @@ Checkout.prototype = {
         });
     },
     reloadReviewBlock: function(){
-        var updater = new Ajax.Updater('checkout-review-load', this.reviewUrl, {method: 'get', onFailure: this.ajaxFailure.bind(this)});
+        new Ajax.Updater('checkout-review-load', this.reviewUrl, {method: 'get', onFailure: this.ajaxFailure.bind(this)});
     },
 
     _disableEnableAll: function(element, isDisabled) {
@@ -99,17 +99,18 @@ Checkout.prototype = {
     },
 
     setLoadWaiting: function(step, keepDisabled) {
+        var container;
         if (step) {
             if (this.loadWaiting) {
                 this.setLoadWaiting(false);
             }
-            var container = $(step+'-buttons-container');
+            container = $(step + '-buttons-container');
             container.setStyle({opacity:.8});
             this._disableEnableAll(container, true);
             Element.show(step+'-please-wait');
         } else {
             if (this.loadWaiting) {
-                var container = $(this.loadWaiting+'-buttons-container');
+                container = $(this.loadWaiting + '-buttons-container');
                 var isDisabled = (keepDisabled ? true : false);
                 if (!isDisabled) {
                     container.setStyle({opacity:1});
@@ -130,13 +131,9 @@ Checkout.prototype = {
             var nextStep = this.steps[i];
             if ($(nextStep + '-progress-opcheckout')) {
                 //Remove the link
-                $(nextStep + '-progress-opcheckout').select('.changelink').each(function (item) {
-                    item.remove();
-                });
+                $(nextStep + '-progress-opcheckout').select('.changelink').item('remove');
                 //Remove the content
-                $(nextStep + '-progress-opcheckout').select('dd.complete').each(function (item) {
-                    item.remove();
-                });
+                $(nextStep + '-progress-opcheckout').select('dd.complete').item('remove');
             }
         }
     },
@@ -163,7 +160,7 @@ Checkout.prototype = {
     setMethod: function(){
         if ($('login:guest') && $('login:guest').checked) {
             this.method = 'guest';
-            var request = new Ajax.Request(
+            new Ajax.Request(
                 this.saveMethodUrl,
                 {method: 'post', onFailure: this.ajaxFailure.bind(this), parameters: {method:'guest'}}
             );
@@ -172,7 +169,7 @@ Checkout.prototype = {
         }
         else if($('login:register') && ($('login:register').checked || $('login:register').type == 'hidden')) {
             this.method = 'register';
-            var request = new Ajax.Request(
+            new Ajax.Request(
                 this.saveMethodUrl,
                 {method: 'post', onFailure: this.ajaxFailure.bind(this), parameters: {method:'register'}}
             );
@@ -275,7 +272,7 @@ Checkout.prototype = {
             return true;
         }
         if (response.redirect) {
-            location.href = response.redirect;
+            location.href = encodeURI(response.redirect);
             return true;
         }
         return false;
@@ -299,7 +296,7 @@ Billing.prototype = {
 
     setAddress: function(addressId){
         if (addressId) {
-            request = new Ajax.Request(
+            new Ajax.Request(
                 this.addressUrl+addressId,
                 {method:'get', onSuccess: this.onAddressLoad, onFailure: checkout.ajaxFailure.bind(checkout)}
             );
@@ -326,25 +323,19 @@ Billing.prototype = {
     },
 
     fillForm: function(transport){
-        var elementValues = {};
-        if (transport && transport.responseText){
-            try{
-                elementValues = eval('(' + transport.responseText + ')');
-            }
-            catch (e) {
-                elementValues = {};
-            }
-        }
-        else{
+        var elementValues = transport.responseJSON || transport.responseText.evalJSON(true) || {};
+        if (!transport && !Object.keys(elementValues).length){
             this.resetSelectedAddress();
         }
-        arrElements = Form.getElements(this.form);
+        var arrElements = Form.getElements(this.form);
         for (var elemIndex in arrElements) {
-            if (arrElements[elemIndex].id) {
-                var fieldName = arrElements[elemIndex].id.replace(/^billing:/, '');
-                arrElements[elemIndex].value = elementValues[fieldName] ? elementValues[fieldName] : '';
-                if (fieldName == 'country_id' && billingForm){
-                    billingForm.elementChildLoad(arrElements[elemIndex]);
+            if (arrElements.hasOwnProperty(elemIndex)) {
+                if (arrElements[elemIndex].id) {
+                    var fieldName = arrElements[elemIndex].id.replace(/^billing:/, '');
+                    arrElements[elemIndex].value = elementValues[fieldName] ? elementValues[fieldName] : '';
+                    if (fieldName == 'country_id' && billingForm){
+                        billingForm.elementChildLoad(arrElements[elemIndex]);
+                    }
                 }
             }
         }
@@ -365,7 +356,7 @@ Billing.prototype = {
 //                $('billing:use_for_shipping').value=1;
 //            }
 
-            var request = new Ajax.Request(
+            new Ajax.Request(
                 this.saveUrl,
                 {
                     method: 'post',
@@ -388,32 +379,30 @@ Billing.prototype = {
         There are 3 options: error, redirect or html with shipping options.
     */
     nextStep: function(transport){
-        if (transport && transport.responseText){
-            try{
-                response = eval('(' + transport.responseText + ')');
-            }
-            catch (e) {
-                response = {};
-            }
-        }
+        var response = transport.responseJSON || transport.responseText.evalJSON(true) || {};
 
         if (response.error){
-            if ((typeof response.message) == 'string') {
-                alert(response.message);
+            if (Object.isString(response.message)) {
+                alert(response.message.stripTags().toString());
             } else {
                 if (window.billingRegionUpdater) {
                     billingRegionUpdater.update();
                 }
 
-                alert(response.message.join("\n"));
+                var msg = response.message;
+                if (Object.isArray(msg)) {
+                    alert(msg.join("\n"));
+                }
+                alert(msg.stripTags().toString());
             }
 
             return false;
         }
 
         checkout.setStepResponse(response);
-
-        payment.initWhatIsCvvListeners();
+        if (payment) {
+            payment.initWhatIsCvvListeners();
+        }
 
         // DELETE
         //alert('error: ' + response.error + ' / redirect: ' + response.redirect + ' / shipping_methods_html: ' + response.shipping_methods_html);
@@ -440,7 +429,7 @@ Shipping.prototype = {
 
     setAddress: function(addressId){
         if (addressId) {
-            request = new Ajax.Request(
+            new Ajax.Request(
                 this.addressUrl+addressId,
                 {method:'get', onSuccess: this.onAddressLoad, onFailure: checkout.ajaxFailure.bind(checkout)}
             );
@@ -468,25 +457,19 @@ Shipping.prototype = {
     },
 
     fillForm: function(transport){
-        var elementValues = {};
-        if (transport && transport.responseText){
-            try{
-                elementValues = eval('(' + transport.responseText + ')');
-            }
-            catch (e) {
-                elementValues = {};
-            }
-        }
-        else{
+        var elementValues = transport.responseJSON || transport.responseText.evalJSON(true) || {};
+        if (!transport && !Object.keys(elementValues).length) {
             this.resetSelectedAddress();
         }
-        arrElements = Form.getElements(this.form);
+        var arrElements = Form.getElements(this.form);
         for (var elemIndex in arrElements) {
-            if (arrElements[elemIndex].id) {
-                var fieldName = arrElements[elemIndex].id.replace(/^shipping:/, '');
-                arrElements[elemIndex].value = elementValues[fieldName] ? elementValues[fieldName] : '';
-                if (fieldName == 'country_id' && shippingForm){
-                    shippingForm.elementChildLoad(arrElements[elemIndex]);
+            if (arrElements.hasOwnProperty(elemIndex)) {
+                if (arrElements[elemIndex].id) {
+                    var fieldName = arrElements[elemIndex].id.replace(/^shipping:/, '');
+                    arrElements[elemIndex].value = elementValues[fieldName] ? elementValues[fieldName] : '';
+                    if (fieldName == 'country_id' && shippingForm){
+                        shippingForm.elementChildLoad(arrElements[elemIndex]);
+                    }
                 }
             }
         }
@@ -533,7 +516,7 @@ Shipping.prototype = {
         var validator = new Validation(this.form);
         if (validator.validate()) {
             checkout.setLoadWaiting('shipping');
-            var request = new Ajax.Request(
+            new Ajax.Request(
                 this.saveUrl,
                 {
                     method:'post',
@@ -546,27 +529,25 @@ Shipping.prototype = {
         }
     },
 
-    resetLoadWaiting: function(transport){
+    resetLoadWaiting: function(){
         checkout.setLoadWaiting(false);
     },
 
     nextStep: function(transport){
-        if (transport && transport.responseText){
-            try{
-                response = eval('(' + transport.responseText + ')');
-            }
-            catch (e) {
-                response = {};
-            }
-        }
+        var response = transport.responseJSON || transport.responseText.evalJSON(true) || {};
+
         if (response.error){
-            if ((typeof response.message) == 'string') {
-                alert(response.message);
+            if (Object.isString(response.message)) {
+                alert(response.message.stripTags().toString());
             } else {
                 if (window.shippingRegionUpdater) {
                     shippingRegionUpdater.update();
                 }
-                alert(response.message.join("\n"));
+                var msg = response.message;
+                if (Object.isArray(msg)) {
+                    alert(msg.join("\n"));
+                }
+                alert(msg.stripTags().toString());
             }
 
             return false;
@@ -624,7 +605,7 @@ ShippingMethod.prototype = {
         if (checkout.loadWaiting!=false) return;
         if (this.validate()) {
             checkout.setLoadWaiting('shipping-method');
-            var request = new Ajax.Request(
+            new Ajax.Request(
                 this.saveUrl,
                 {
                     method:'post',
@@ -642,17 +623,10 @@ ShippingMethod.prototype = {
     },
 
     nextStep: function(transport){
-        if (transport && transport.responseText){
-            try{
-                response = eval('(' + transport.responseText + ')');
-            }
-            catch (e) {
-                response = {};
-            }
-        }
+        var response = transport.responseJSON || transport.responseText.evalJSON(true) || {};
 
         if (response.error) {
-            alert(response.message);
+            alert(response.message.stripTags().toString());
             return false;
         }
 
@@ -832,7 +806,7 @@ Payment.prototype = {
         }
         if (this.validate() && this.validator.validate()) {
             checkout.setLoadWaiting('payment');
-            var request = new Ajax.Request(
+            new Ajax.Request(
                 this.saveUrl,
                 {
                     method:'post',
@@ -850,14 +824,8 @@ Payment.prototype = {
     },
 
     nextStep: function(transport){
-        if (transport && transport.responseText){
-            try{
-                response = eval('(' + transport.responseText + ')');
-            }
-            catch (e) {
-                response = {};
-            }
-        }
+        var response = transport.responseJSON || transport.responseText.evalJSON(true) || {};
+
         /*
         * if there is an error in payment, need to show error message
         */
@@ -872,7 +840,7 @@ Payment.prototype = {
                 }
                 return;
             }
-            alert(response.error);
+            alert(response.error.stripTags().toString());
             return;
         }
 
@@ -906,7 +874,7 @@ Review.prototype = {
             params += '&'+Form.serialize(this.agreementsForm);
         }
         params.save = true;
-        var request = new Ajax.Request(
+        new Ajax.Request(
             this.saveUrl,
             {
                 method:'post',
@@ -923,26 +891,22 @@ Review.prototype = {
     },
 
     nextStep: function(transport){
-        if (transport && transport.responseText) {
-            try{
-                response = eval('(' + transport.responseText + ')');
-            }
-            catch (e) {
-                response = {};
-            }
+        if (transport) {
+            var response = transport.responseJSON || transport.responseText.evalJSON(true) || {};
+
             if (response.redirect) {
                 this.isSuccess = true;
-                location.href = response.redirect;
+                location.href = encodeURI(response.redirect);
                 return;
             }
             if (response.success) {
                 this.isSuccess = true;
-                window.location=this.successUrl;
+                window.location = encodeURI(this.successUrl);
             }
             else{
                 var msg = response.error_messages;
-                if (typeof(msg)=='object') {
-                    msg = msg.join("\n");
+                if (Object.isArray(msg)) {
+                    msg = msg.join("\n").stripTags().toString();
                 }
                 if (msg) {
                     alert(msg);
