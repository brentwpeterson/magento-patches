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


PATCH_SUPEE-9767_EE_1.10.0.2_v1.sh | EE_1.10.0.2 | v1 | 226caf7 | Mon Feb 20 17:33:39 2017 +0200 | 2321b14

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Enterprise/CatalogEvent/controllers/Adminhtml/Catalog/EventController.php app/code/core/Enterprise/CatalogEvent/controllers/Adminhtml/Catalog/EventController.php
index 431c8d1..7887d96 100644
--- app/code/core/Enterprise/CatalogEvent/controllers/Adminhtml/Catalog/EventController.php
+++ app/code/core/Enterprise/CatalogEvent/controllers/Adminhtml/Catalog/EventController.php
@@ -168,6 +168,11 @@ class Enterprise_CatalogEvent_Adminhtml_Catalog_EventController extends Mage_Adm
             $uploader->setAllowRenameFiles(true);
             $uploader->setAllowCreateFolders(true);
             $uploader->setFilesDispersion(false);
+            $uploader->addValidateCallback(
+                Mage_Core_Model_File_Validator_Image::NAME,
+                Mage::getModel('core/file_validator_image'),
+                'validate'
+            );
         } catch (Exception $e) {
             $isUploaded = false;
         }
diff --git app/code/core/Enterprise/GiftWrapping/Model/Wrapping.php app/code/core/Enterprise/GiftWrapping/Model/Wrapping.php
index b33683b..fc602f8 100644
--- app/code/core/Enterprise/GiftWrapping/Model/Wrapping.php
+++ app/code/core/Enterprise/GiftWrapping/Model/Wrapping.php
@@ -171,6 +171,11 @@ class Enterprise_GiftWrapping_Model_Wrapping extends Mage_Core_Model_Abstract
             $uploader->setAllowRenameFiles(true);
             $uploader->setAllowCreateFolders(true);
             $uploader->setFilesDispersion(false);
+            $uploader->addValidateCallback(
+                Mage_Core_Model_File_Validator_Image::NAME,
+                Mage::getModel('core/file_validator_image'),
+                'validate'
+            );
         } catch (Exception $e) {
             $isUploaded = false;
         }
diff --git app/code/core/Enterprise/Invitation/Model/Config.php app/code/core/Enterprise/Invitation/Model/Config.php
index d86395a..8745b93 100644
--- app/code/core/Enterprise/Invitation/Model/Config.php
+++ app/code/core/Enterprise/Invitation/Model/Config.php
@@ -88,7 +88,7 @@ class Enterprise_Invitation_Model_Config
 
     /**
      * Retrieve configuration for availability of invitations
-     * on global level. Also will disallowe any functionality in admin.
+     * on global level. Also will disallow any functionality in admin.
      *
      * @param int $storeId
      * @return boolean
diff --git app/code/core/Enterprise/Invitation/Model/Invitation.php app/code/core/Enterprise/Invitation/Model/Invitation.php
index 9aa5a41..8047e34 100644
--- app/code/core/Enterprise/Invitation/Model/Invitation.php
+++ app/code/core/Enterprise/Invitation/Model/Invitation.php
@@ -399,5 +399,4 @@ class Enterprise_Invitation_Model_Invitation extends Mage_Core_Model_Abstract
 
         return true;
     }
-
 }
diff --git app/code/core/Enterprise/Invitation/controllers/IndexController.php app/code/core/Enterprise/Invitation/controllers/IndexController.php
index 091e985..9c911fc 100644
--- app/code/core/Enterprise/Invitation/controllers/IndexController.php
+++ app/code/core/Enterprise/Invitation/controllers/IndexController.php
@@ -60,53 +60,63 @@ class Enterprise_Invitation_IndexController extends Mage_Core_Controller_Front_A
     {
         $data = $this->getRequest()->getPost();
         if ($data) {
-            $customer = Mage::getSingleton('customer/session')->getCustomer();
+            if (!$this->_validateFormKey()) {
+                return $this->_redirect('*/*/');
+            }
+            $customer       = Mage::getSingleton('customer/session')->getCustomer();
             $invPerSend = Mage::getSingleton('enterprise_invitation/config')->getMaxInvitationsPerSend();
-            $attempts = 0;
-            $sent     = 0;
+            $attempts       = 0;
+            $sent           = 0;
             $customerExists = 0;
             foreach ($data['email'] as $email) {
                 $attempts++;
-                if (!Zend_Validate::is($email, 'EmailAddress')) {
+
+                if ($attempts > $invPerSend) {
                     continue;
                 }
-                if ($attempts > $invPerSend) {
+
+                if (!Zend_Validate::is($email, 'EmailAddress')) {
                     continue;
                 }
+
                 try {
                     $invitation = Mage::getModel('enterprise_invitation/invitation')->setData(array(
                         'email'    => $email,
                         'customer' => $customer,
-                        'message'  => (isset($data['message']) ? $data['message'] : ''),
+                        'message'  => (isset($data['message'])
+                            ? Mage::helper('core')->escapeHtml($data['message'])
+                            : ''
+                        ),
                     ))->save();
                     if ($invitation->sendInvitationEmail()) {
                         Mage::getSingleton('customer/session')->addSuccess(
-                            Mage::helper('enterprise_invitation')->__('Invitation for %s has been sent.', Mage::helper('core')->escapeHtml($email))
+                            Mage::helper('enterprise_invitation')
+                                ->__('Invitation for %s has been sent.', Mage::helper('core')->escapeHtml($email))
                         );
                         $sent++;
-                    }
-                    else {
+                    } else {
                         throw new Exception(''); // not Mage_Core_Exception intentionally
                     }
 
-                }
-                catch (Mage_Core_Exception $e) {
+                } catch (Mage_Core_Exception $e) {
                     if (Enterprise_Invitation_Model_Invitation::ERROR_CUSTOMER_EXISTS === $e->getCode()) {
                         $customerExists++;
-                    }
-                    else {
+                    } else {
                         Mage::getSingleton('customer/session')->addError($e->getMessage());
                     }
-                }
-                catch (Exception $e) {
+                } catch (Exception $e) {
                     Mage::getSingleton('customer/session')->addError(
-                        Mage::helper('enterprise_invitation')->__('Failed to send email to %s.', Mage::helper('core')->escapeHtml($email))
+                        Mage::helper('enterprise_invitation')
+                            ->__('Failed to send email to %s.', Mage::helper('core')->escapeHtml($email))
                     );
                 }
             }
             if ($customerExists) {
                 Mage::getSingleton('customer/session')->addNotice(
-                    Mage::helper('enterprise_invitation')->__('%d invitation(s) were not sent, because customer accounts already exist for specified email addresses.', $customerExists)
+                    Mage::helper('enterprise_invitation')
+                        ->__('%d invitation(s) were not sent, because customer accounts already exist for specified email addresses.',
+                            $customerExists
+                    )
                 );
             }
             $this->_redirect('*/*/');
diff --git app/code/core/Enterprise/PageCache/Helper/Form/Key.php app/code/core/Enterprise/PageCache/Helper/Form/Key.php
index 58983d6..a82c1ca 100644
--- app/code/core/Enterprise/PageCache/Helper/Form/Key.php
+++ app/code/core/Enterprise/PageCache/Helper/Form/Key.php
@@ -76,4 +76,46 @@ class Enterprise_PageCache_Helper_Form_Key extends Mage_Core_Helper_Abstract
         $content = str_replace(self::_getFormKeyMarker(), $formKey, $content, $replacementCount);
         return ($replacementCount > 0);
     }
+
+    /**
+     * Get form key cache id
+     *
+     * @param boolean $renew
+     * @return boolean
+     */
+    public static function getFormKeyCacheId($renew = false)
+    {
+        $formKeyId = Enterprise_PageCache_Model_Cookie::getFormKeyCookieValue();
+        if ($renew && $formKeyId) {
+            Enterprise_PageCache_Model_Cache::getCacheInstance()->remove(self::getFormKeyCacheId());
+            $formKeyId = false;
+            Mage::unregister('cached_form_key_id');
+        }
+        if (!$formKeyId) {
+            if (!$formKeyId = Mage::registry('cached_form_key_id')) {
+                $formKeyId = Enterprise_PageCache_Helper_Data::getRandomString(16);
+                Enterprise_PageCache_Model_Cookie::setFormKeyCookieValue($formKeyId);
+                Mage::register('cached_form_key_id', $formKeyId);
+            }
+        }
+        return $formKeyId;
+    }
+
+    /**
+     * Get cached form key
+     *
+     * @param boolean $renew
+     * @return string
+     */
+    public static function getFormKey($renew = false)
+    {
+        $formKeyId = self::getFormKeyCacheId($renew);
+        $formKey = Enterprise_PageCache_Model_Cache::getCacheInstance()->load($formKeyId);
+        if ($renew) {
+            $formKey = Enterprise_PageCache_Helper_Data::getRandomString(16);
+            Enterprise_PageCache_Model_Cache::getCacheInstance()
+                ->save($formKey, $formKeyId, array(Enterprise_PageCache_Model_Processor::CACHE_TAG));
+        }
+        return $formKey;
+    }
 }
diff --git app/code/core/Enterprise/PageCache/Model/Observer.php app/code/core/Enterprise/PageCache/Model/Observer.php
index 0262c52..797e026 100644
--- app/code/core/Enterprise/PageCache/Model/Observer.php
+++ app/code/core/Enterprise/PageCache/Model/Observer.php
@@ -20,17 +20,38 @@
  *
  * @category    Enterprise
  * @package     Enterprise_PageCache
- * @copyright   Copyright (c) 2010 Magento Inc. (http://www.magentocommerce.com)
+ * @copyright   Copyright (c) 2012 Magento Inc. (http://www.magentocommerce.com)
  * @license     http://www.magentocommerce.com/license/enterprise-edition
  */
 
+/**
+ * Full page cache observer
+ *
+ * @category   Enterprise
+ * @package    Enterprise_PageCache
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
 class Enterprise_PageCache_Model_Observer
 {
     /**
+     * Page Cache Processor
+     *
      * @var Enterprise_PageCache_Model_Processor
      */
     protected $_processor;
+
+    /**
+     * Page Cache Config
+     *
+     * @var Enterprise_PageCache_Model_Config
+     */
     protected $_config;
+
+    /**
+     * Is Enabled Full Page Cache
+     *
+     * @var bool
+     */
     protected $_isEnabled;
 
     /**
@@ -45,6 +66,7 @@ class Enterprise_PageCache_Model_Observer
 
     /**
      * Check if full page cache is enabled
+     *
      * @return bool
      */
     public function isCacheEnabled()
@@ -73,7 +95,8 @@ class Enterprise_PageCache_Model_Observer
     /**
      * Check when cache should be disabled
      *
-     * @param $observer
+     * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function processPreDispatch(Varien_Event_Observer $observer)
     {
@@ -93,9 +116,15 @@ class Enterprise_PageCache_Model_Observer
         }
         /**
          * Check if request will be cached
+         * canProcessRequest checks is theoretically possible to cache page
+         * getRequestProcessor check is page have full page cache processor
+         * isStraight works for partially cached pages where getRequestProcessor doesn't work
+         * (not all holes are filled by content)
          */
-        if ($this->_processor->canProcessRequest($request)) {
-            Mage::app()->getCacheInstance()->banUse(Mage_Core_Block_Abstract::CACHE_GROUP); // disable blocks cache
+        if ($this->_processor->canProcessRequest($request)
+            && ($request->isStraight() || $this->_processor->getRequestProcessor($request))
+        ) {
+            Mage::app()->getCacheInstance()->banUse(Mage_Core_Block_Abstract::CACHE_GROUP);
         }
         $this->_getCookie()->updateCustomerCookies();
         return $this;
@@ -104,13 +133,15 @@ class Enterprise_PageCache_Model_Observer
     /**
      * model_load_after event processor. Collect tags of all loaded entities
      *
-     * @param $observer
+     * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function registerModelTag(Varien_Event_Observer $observer)
     {
         if (!$this->isCacheEnabled()) {
             return $this;
         }
+        /** @var $object Mage_Core_Model_Abstract */
         $object = $observer->getEvent()->getObject();
         if ($object && $object->getId()) {
             $tags = $object->getCacheIdTags();
@@ -118,12 +149,14 @@ class Enterprise_PageCache_Model_Observer
                 $this->_processor->addRequestTag($tags);
             }
         }
+        return $this;
     }
 
     /**
      * Check category state on post dispatch to allow category page be cached
      *
      * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function checkCategoryState(Varien_Event_Observer $observer)
     {
@@ -145,6 +178,7 @@ class Enterprise_PageCache_Model_Observer
      * Check product state on post dispatch to allow product page be cached
      *
      * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function checkProductState(Varien_Event_Observer $observer)
     {
@@ -166,6 +200,7 @@ class Enterprise_PageCache_Model_Observer
      * Check if data changes duering object save affect cached pages
      *
      * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function validateDataChanges(Varien_Event_Observer $observer)
     {
@@ -173,13 +208,15 @@ class Enterprise_PageCache_Model_Observer
             return $this;
         }
         $object = $observer->getEvent()->getObject();
-        $object = Mage::getModel('enterprise_pagecache/validator')->checkDataChange($object);
+        Mage::getModel('enterprise_pagecache/validator')->checkDataChange($object);
+        return $this;
     }
 
     /**
      * Check if data delete affect cached pages
      *
      * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function validateDataDelete(Varien_Event_Observer $observer)
     {
@@ -187,11 +224,14 @@ class Enterprise_PageCache_Model_Observer
             return $this;
         }
         $object = $observer->getEvent()->getObject();
-        $object = Mage::getModel('enterprise_pagecache/validator')->checkDataDelete($object);
+        Mage::getModel('enterprise_pagecache/validator')->checkDataDelete($object);
+        return $this;
     }
 
     /**
      * Clean full page cache
+     *
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function cleanCache()
     {
@@ -201,6 +241,7 @@ class Enterprise_PageCache_Model_Observer
 
     /**
      * Invalidate full page cache
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function invalidateCache()
     {
@@ -212,6 +253,7 @@ class Enterprise_PageCache_Model_Observer
      * Render placeholder tags around the block if needed
      *
      * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function renderBlockPlaceholder(Varien_Event_Observer $observer)
     {
@@ -221,6 +263,7 @@ class Enterprise_PageCache_Model_Observer
         $block = $observer->getEvent()->getBlock();
         $transport = $observer->getEvent()->getTransport();
         $placeholder = $this->_config->getBlockPlaceholder($block);
+
         if ($transport && $placeholder) {
             $blockHtml = $transport->getHtml();
             $blockHtml = $placeholder->getStartTag() . $blockHtml . $placeholder->getEndTag();
@@ -234,6 +277,7 @@ class Enterprise_PageCache_Model_Observer
      *
      * @param Varien_Event_Observer $observer
      * @deprecated after 1.8
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function blockCreateAfter(Varien_Event_Observer $observer)
     {
@@ -252,6 +296,7 @@ class Enterprise_PageCache_Model_Observer
      * Set cart hash in cookie on quote change
      *
      * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function registerQuoteChange(Varien_Event_Observer $observer)
     {
@@ -275,6 +320,7 @@ class Enterprise_PageCache_Model_Observer
      * Set compare list in cookie on list change. Also modify recently compared cookie.
      *
      * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function registerCompareListChange(Varien_Event_Observer $observer)
     {
@@ -320,6 +366,7 @@ class Enterprise_PageCache_Model_Observer
      * Set new message cookie on adding messsage to session.
      *
      * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function processNewMessage(Varien_Event_Observer $observer)
     {
@@ -331,18 +378,12 @@ class Enterprise_PageCache_Model_Observer
     }
 
     /**
-     * Set cookie for logged in customer
+     * Update customer viewed products index and renew customer viewed product ids cookie
      *
-     * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
-    public function customerLogin(Varien_Event_Observer $observer)
+    public function updateCustomerProductIndex()
     {
-        if (!$this->isCacheEnabled()) {
-            return $this;
-        }
-        $this->_getCookie()->updateCustomerCookies();
-
-        // update customer viewed products index
         try {
             $productIds = $this->_getCookie()->get(Enterprise_PageCache_Model_Container_Viewedproducts::COOKIE_NAME);
             if ($productIds) {
@@ -363,16 +404,32 @@ class Enterprise_PageCache_Model_Observer
         Mage::getSingleton('catalog/product_visibility')->addVisibleInSiteFilterToCollection($collection);
         $productIds = $collection->load()->getLoadedIds();
         $productIds = implode(',', $productIds);
-        Enterprise_PageCache_Model_Cookie::registerViewedProducts($productIds, $countLimit, false);
-
+        $this->_getCookie()->registerViewedProducts($productIds, $countLimit, false);
         return $this;
+    }
 
+    /**
+     * Set cookie for logged in customer
+     *
+     * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
+     */
+    public function customerLogin(Varien_Event_Observer $observer)
+    {
+        if (!$this->isCacheEnabled()) {
+            return $this;
+        }
+        $this->_getCookie()->updateCustomerCookies();
+        $this->updateCustomerProductIndex();
+        $this->updateFormKeyCookie();
+        return $this;
     }
 
     /**
      * Remove customer cookie
      *
      * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function customerLogout(Varien_Event_Observer $observer)
     {
@@ -380,6 +437,14 @@ class Enterprise_PageCache_Model_Observer
             return $this;
         }
         $this->_getCookie()->updateCustomerCookies();
+
+        if (!$this->_getCookie()->get(Enterprise_PageCache_Model_Cookie::COOKIE_CUSTOMER)) {
+            $this->_getCookie()->delete(Enterprise_PageCache_Model_Cookie::COOKIE_RECENTLY_COMPARED);
+            $this->_getCookie()->delete(Enterprise_PageCache_Model_Cookie::COOKIE_COMPARE_LIST);
+            Enterprise_PageCache_Model_Cookie::registerViewedProducts(array(), 0, false);
+        }
+
+        $this->updateFormKeyCookie();
         return $this;
     }
 
@@ -387,6 +452,7 @@ class Enterprise_PageCache_Model_Observer
      * Set wishlist hash in cookie on wishlist change
      *
      * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function registerWishlistChange(Varien_Event_Observer $observer)
     {
@@ -413,6 +479,7 @@ class Enterprise_PageCache_Model_Observer
      * Clean order sidebar cache
      *
      * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function registerNewOrder(Varien_Event_Observer $observer)
     {
@@ -432,6 +499,7 @@ class Enterprise_PageCache_Model_Observer
      * Remove new message cookie on clearing session messages.
      *
      * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function processMessageClearing(Varien_Event_Observer $observer)
     {
@@ -446,6 +514,7 @@ class Enterprise_PageCache_Model_Observer
      * Resave exception rules to cache storage
      *
      * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function registerDesignExceptionsChange(Varien_Event_Observer $observer)
     {
@@ -501,8 +570,19 @@ class Enterprise_PageCache_Model_Observer
         /** @var $session Mage_Core_Model_Session  */
         $session = Mage::getSingleton('core/session');
         $cachedFrontFormKey = Enterprise_PageCache_Model_Cookie::getFormKeyCookieValue();
-        if ($cachedFrontFormKey) {
+        if ($cachedFrontFormKey && !$session->getData('_form_key')) {
             $session->setData('_form_key', $cachedFrontFormKey);
         }
     }
+
+    /**
+     * Updates form key cookie with hash from session
+     */
+    public function updateFormKeyCookie()
+    {
+        /** @var $session Mage_Core_Model_Session  */
+        $session = Mage::getSingleton('core/session');
+        $session->renewFormKey();
+        Enterprise_PageCache_Model_Cookie::setFormKeyCookieValue($session->getFormKey());
+    }
 }
diff --git app/code/core/Enterprise/Pci/Model/Observer.php app/code/core/Enterprise/Pci/Model/Observer.php
index 7f3b651..fb47466 100644
--- app/code/core/Enterprise/Pci/Model/Observer.php
+++ app/code/core/Enterprise/Pci/Model/Observer.php
@@ -139,7 +139,7 @@ class Enterprise_Pci_Model_Observer
     {
         $password = $observer->getEvent()->getPassword();
         $model    = $observer->getEvent()->getModel();
-        if (!Mage::helper('core')->getEncryptor()->validateHashByVersion($password, $model->getPassword())) {
+        if (!Mage::helper('core')->getEncryptor()->validateHashByVersion($password, $model->getPasswordHash())) {
             $model->changePassword($password, false);
         }
     }
diff --git app/code/core/Mage/Admin/Model/Session.php app/code/core/Mage/Admin/Model/Session.php
index 1e15dc6..d536ba1 100644
--- app/code/core/Mage/Admin/Model/Session.php
+++ app/code/core/Mage/Admin/Model/Session.php
@@ -20,7 +20,7 @@
  *
  * @category    Mage
  * @package     Mage_Admin
- * @copyright   Copyright (c) 2010 Magento Inc. (http://www.magentocommerce.com)
+ * @copyright   Copyright (c) 2011 Magento Inc. (http://www.magentocommerce.com)
  * @license     http://www.magentocommerce.com/license/enterprise-edition
  */
 
@@ -117,6 +117,7 @@ class Mage_Admin_Model_Session extends Mage_Core_Model_Session_Abstract
             $user = $this->_factory->getModel('admin/user');
             $user->login($username, $password);
             if ($user->getId()) {
+                $this->renewSession();
 
                 if (Mage::getSingleton('adminhtml/url')->useSecretKey()) {
                     Mage::getSingleton('adminhtml/url')->renewSecretUrls();
@@ -138,7 +139,11 @@ class Mage_Admin_Model_Session extends Mage_Core_Model_Session_Abstract
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
@@ -154,7 +159,7 @@ class Mage_Admin_Model_Session extends Mage_Core_Model_Session_Abstract
      * @param  Mage_Admin_Model_User $user
      * @return Mage_Admin_Model_Session
      */
-    public function refreshAcl($user=null)
+    public function refreshAcl($user = null)
     {
         if (is_null($user)) {
             $user = $this->getUser();
@@ -182,14 +187,14 @@ class Mage_Admin_Model_Session extends Mage_Core_Model_Session_Abstract
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
index 0000000..ebb57a4
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Block/Checkout/Formkey.php
@@ -0,0 +1,52 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition License
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magentocommerce.com/license/enterprise-edition
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
+ * @license     http://www.magentocommerce.com/license/enterprise-edition
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
index 0000000..51c9a1b
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Block/Notification/Symlink.php
@@ -0,0 +1,36 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition License
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magentocommerce.com/license/enterprise-edition
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
+ * @license     http://www.magentocommerce.com/license/enterprise-edition
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
index 54f9052..51e68fc 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Date.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Date.php
@@ -137,11 +137,11 @@ class Mage_Adminhtml_Block_Widget_Grid_Column_Filter_Date extends Mage_Adminhtml
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
index e5d7fd3..a0a98b2 100644
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
index 48375f5..c3894c4 100644
--- app/code/core/Mage/Adminhtml/Model/Config/Data.php
+++ app/code/core/Mage/Adminhtml/Model/Config/Data.php
@@ -153,6 +153,9 @@ class Mage_Adminhtml_Model_Config_Data extends Varien_Object
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
index 8038e90..5cb9d27 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/Product/GalleryController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/Product/GalleryController.php
@@ -46,6 +46,11 @@ class Mage_Adminhtml_Catalog_Product_GalleryController extends Mage_Adminhtml_Co
             $uploader->addValidateCallback('catalog_product_image', Mage::helper('catalog/image'), 'validateUploadFile');
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
diff --git app/code/core/Mage/Adminhtml/controllers/IndexController.php app/code/core/Mage/Adminhtml/controllers/IndexController.php
index 2663473..3f5cae4 100644
--- app/code/core/Mage/Adminhtml/controllers/IndexController.php
+++ app/code/core/Mage/Adminhtml/controllers/IndexController.php
@@ -75,6 +75,7 @@ class Mage_Adminhtml_IndexController extends Mage_Adminhtml_Controller_Action
     {
         $adminSession = Mage::getSingleton('admin/session');
         $adminSession->unsetAll();
+        $adminSession->getCookie()->delete($adminSession->getSessionName());
         $adminSession->addSuccess(Mage::helper('adminhtml')->__('You have logged out.'));
 
         $this->_redirect('*');
diff --git app/code/core/Mage/Checkout/controllers/MultishippingController.php app/code/core/Mage/Checkout/controllers/MultishippingController.php
index d56a58f..9818db2 100644
--- app/code/core/Mage/Checkout/controllers/MultishippingController.php
+++ app/code/core/Mage/Checkout/controllers/MultishippingController.php
@@ -227,6 +227,12 @@ class Mage_Checkout_MultishippingController extends Mage_Checkout_Controller_Act
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
@@ -333,6 +339,11 @@ class Mage_Checkout_MultishippingController extends Mage_Checkout_Controller_Act
 
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
@@ -436,6 +447,11 @@ class Mage_Checkout_MultishippingController extends Mage_Checkout_Controller_Act
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
index 861450a..60b9b37 100644
--- app/code/core/Mage/Checkout/controllers/OnepageController.php
+++ app/code/core/Mage/Checkout/controllers/OnepageController.php
@@ -310,6 +310,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
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
@@ -325,6 +330,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
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
@@ -370,6 +380,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
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
@@ -394,6 +409,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
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
@@ -424,6 +444,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
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
index f784a4a..6ee9deb 100644
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
index 3866b2c..441aece 100644
--- app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
+++ app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
@@ -276,6 +276,11 @@ class Mage_Cms_Model_Wysiwyg_Images_Storage extends Varien_Object
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
index 2244690..dfb702a 100644
--- app/code/core/Mage/Core/Controller/Front/Action.php
+++ app/code/core/Mage/Core/Controller/Front/Action.php
@@ -20,7 +20,7 @@
  *
  * @category    Mage
  * @package     Mage_Core
- * @copyright   Copyright (c) 2010 Magento Inc. (http://www.magentocommerce.com)
+ * @copyright   Copyright (c) 2012 Magento Inc. (http://www.magentocommerce.com)
  * @license     http://www.magentocommerce.com/license/enterprise-edition
  */
 
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
@@ -86,4 +96,96 @@ class Mage_Core_Controller_Front_Action extends Mage_Core_Controller_Varien_Acti
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
index 246e702..a01e93e 100644
--- app/code/core/Mage/Core/Controller/Request/Http.php
+++ app/code/core/Mage/Core/Controller/Request/Http.php
@@ -146,7 +146,10 @@ class Mage_Core_Controller_Request_Http extends Zend_Controller_Request_Http
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
index 4dc5975..6f36d9e 100644
--- app/code/core/Mage/Core/Controller/Varien/Action.php
+++ app/code/core/Mage/Core/Controller/Varien/Action.php
@@ -147,7 +147,6 @@ abstract class Mage_Core_Controller_Varien_Action
 
     protected function _construct()
     {
-
     }
 
     public function hasAction($action)
@@ -243,8 +242,8 @@ abstract class Mage_Core_Controller_Varien_Action
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
@@ -450,14 +449,21 @@ abstract class Mage_Core_Controller_Varien_Action
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
@@ -485,12 +491,32 @@ abstract class Mage_Core_Controller_Varien_Action
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
 
-        if ($this->getFlag('', self::FLAG_NO_COOKIES_REDIRECT) && Mage::getStoreConfig('web/browser_capabilities/cookies')) {
+        if ($this->getFlag('', self::FLAG_NO_COOKIES_REDIRECT)
+            && Mage::getStoreConfig('web/browser_capabilities/cookies')
+        ) {
             $this->_forward('noCookies', 'index', 'core');
             return;
         }
@@ -499,6 +525,8 @@ abstract class Mage_Core_Controller_Varien_Action
             return;
         }
 
+        Varien_Autoload::registerScope($this->getRequest()->getRouteName());
+
         Mage::dispatchEvent('controller_action_predispatch', array('controller_action'=>$this));
         Mage::dispatchEvent(
             'controller_action_predispatch_'.$this->getRequest()->getRouteName(),
@@ -545,7 +573,6 @@ abstract class Mage_Core_Controller_Varien_Action
             $this->renderLayout();
         } else {
             $status->setForwarded(true);
-            #$this->_forward('cmsNoRoute', 'index', 'cms');
             $this->_forward(
                 $status->getForwardAction(),
                 $status->getForwardController(),
@@ -608,7 +635,7 @@ abstract class Mage_Core_Controller_Varien_Action
     }
 
     /**
-     * Inits layout messages by message storage(s), loading and adding messages to layout messages block
+     * Initializing layout messages by message storage(s), loading and adding messages to layout messages block
      *
      * @param string|array $messagesStorage
      * @return Mage_Core_Controller_Varien_Action
@@ -635,7 +662,7 @@ abstract class Mage_Core_Controller_Varien_Action
     }
 
     /**
-     * Inits layout messages by message storage(s), loading and adding messages to layout messages block
+     * Initializing layout messages by message storage(s), loading and adding messages to layout messages block
      *
      * @param string|array $messagesStorage
      * @return Mage_Core_Controller_Varien_Action
@@ -663,8 +690,30 @@ abstract class Mage_Core_Controller_Varien_Action
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
index 015f66faf..68b7594 100644
--- app/code/core/Mage/Core/Controller/Varien/Front.php
+++ app/code/core/Mage/Core/Controller/Varien/Front.php
@@ -324,4 +324,43 @@ class Mage_Core_Controller_Varien_Front extends Varien_Object
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
diff --git app/code/core/Mage/Core/Helper/Url.php app/code/core/Mage/Core/Helper/Url.php
index 1f85c91..8f447ed 100644
--- app/code/core/Mage/Core/Helper/Url.php
+++ app/code/core/Mage/Core/Helper/Url.php
@@ -97,6 +97,28 @@ class Mage_Core_Helper_Url extends Mage_Core_Helper_Abstract
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
index 554f55d..2abaab9 100644
--- app/code/core/Mage/Core/Model/File/Validator/Image.php
+++ app/code/core/Mage/Core/Model/File/Validator/Image.php
@@ -87,10 +87,33 @@ class Mage_Core_Model_File_Validator_Image
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
@@ -105,5 +128,4 @@ class Mage_Core_Model_File_Validator_Image
     {
         return in_array($nImageType, $this->_allowedImageTypes);
     }
-
 }
diff --git app/code/core/Mage/Core/Model/Session/Abstract.php app/code/core/Mage/Core/Model/Session/Abstract.php
index 501e1ac..2605882 100644
--- app/code/core/Mage/Core/Model/Session/Abstract.php
+++ app/code/core/Mage/Core/Model/Session/Abstract.php
@@ -500,4 +500,17 @@ class Mage_Core_Model_Session_Abstract extends Mage_Core_Model_Session_Abstract_
         }
         return parent::getSessionSavePath();
     }
+
+    /**
+     * Renew session id and update session cookie
+     *
+     * @return Mage_Core_Model_Session_Abstract
+     */
+    public function renewSession()
+    {
+        $this->getCookie()->delete($this->getSessionName());
+        $this->regenerateSessionId();
+
+        return $this;
+    }
 }
diff --git app/code/core/Mage/Core/Model/Session/Abstract/Varien.php app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
index 26fd4d4..80ec9ce 100644
--- app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
+++ app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
@@ -405,4 +405,15 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
 
         return $parts;
     }
+
+    /**
+     * Regenerate session Id
+     *
+     * @return Mage_Core_Model_Session_Abstract_Varien
+     */
+    public function regenerateSessionId()
+    {
+        session_regenerate_id(true);
+        return $this;
+    }
 }
diff --git app/code/core/Mage/Core/Model/Session/Abstract/Zend.php app/code/core/Mage/Core/Model/Session/Abstract/Zend.php
index 8435c17..375ed45 100644
--- app/code/core/Mage/Core/Model/Session/Abstract/Zend.php
+++ app/code/core/Mage/Core/Model/Session/Abstract/Zend.php
@@ -162,4 +162,15 @@ abstract class Mage_Core_Model_Session_Abstract_Zend extends Varien_Object
         }
         return $this;
     }
+
+    /**
+     * Regenerate session Id
+     *
+     * @return Mage_Core_Model_Session_Abstract_Zend
+     */
+    public function regenerateSessionId()
+    {
+        Zend_Session::regenerateId();
+        return $this;
+    }
 }
diff --git app/code/core/Mage/Core/Model/Url.php app/code/core/Mage/Core/Model/Url.php
index 1bf6b10..feb9fe3 100644
--- app/code/core/Mage/Core/Model/Url.php
+++ app/code/core/Mage/Core/Model/Url.php
@@ -911,6 +911,38 @@ class Mage_Core_Model_Url extends Varien_Object
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
index ff6d3a2..d9acd63 100644
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
index 1c2b8a7..58267d5 100644
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
@@ -748,6 +771,25 @@
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
index e64f7da..2ce2ede 100644
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
@@ -125,21 +135,30 @@ class Mage_Customer_Helper_Data extends Mage_Core_Helper_Abstract
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
-                $referer = Mage::getUrl('*/*/*', array('_current' => true));
-                $referer = Mage::helper('core')->urlEncode($referer);
-            }
+        if (!$referer && !Mage::getStoreConfigFlag(self::XML_PATH_CUSTOMER_STARTUP_REDIRECT_TO_DASHBOARD)
+            && !Mage::getSingleton('customer/session')->getNoReferer()
+        ) {
+            $referer = Mage::getUrl('*/*/*', array('_current' => true));
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
index 0c618e4..95d242c 100644
--- app/code/core/Mage/Customer/Model/Session.php
+++ app/code/core/Mage/Customer/Model/Session.php
@@ -20,7 +20,7 @@
  *
  * @category    Mage
  * @package     Mage_Customer
- * @copyright   Copyright (c) 2010 Magento Inc. (http://www.magentocommerce.com)
+ * @copyright   Copyright (c) 2011 Magento Inc. (http://www.magentocommerce.com)
  * @license     http://www.magentocommerce.com/license/enterprise-edition
  */
 
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
@@ -79,9 +86,7 @@ class Mage_Customer_Model_Session extends Mage_Core_Model_Session_Abstract
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
@@ -116,12 +121,27 @@ class Mage_Customer_Model_Session extends Mage_Core_Model_Session_Abstract
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
@@ -129,18 +149,32 @@ class Mage_Customer_Model_Session extends Mage_Core_Model_Session_Abstract
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
@@ -189,6 +223,8 @@ class Mage_Customer_Model_Session extends Mage_Core_Model_Session_Abstract
     public function setCustomerAsLoggedIn($customer)
     {
         $this->setCustomer($customer);
+        $this->renewSession();
+        Mage::getSingleton('core/session')->renewFormKey();
         Mage::dispatchEvent('customer_login', array('customer'=>$customer));
         return $this;
     }
@@ -218,8 +254,7 @@ class Mage_Customer_Model_Session extends Mage_Core_Model_Session_Abstract
     {
         if ($this->isLoggedIn()) {
             Mage::dispatchEvent('customer_logout', array('customer' => $this->getCustomer()) );
-            $this->setId(null);
-            $this->getCookie()->delete($this->getSessionName());
+            $this->_logout();
         }
         return $this;
     }
@@ -228,18 +263,93 @@ class Mage_Customer_Model_Session extends Mage_Core_Model_Session_Abstract
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
index 00688df..8eca565 100644
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
index 1dd8edc..b44e832 100644
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
index 15f8fb9..fc211a5 100644
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
 
         if (!is_callable(array($adapter, $adapterMethod))) {
-            $message = Mage::helper('dataflow')->__('Method "%s" not defined in adapter %s.', $adapterMethod, $adapterName);
+            $message = Mage::helper('dataflow')
+                ->__('Method "%s" not defined in adapter %s.', $adapterMethod, $adapterName);
             $this->addException($message, Mage_Dataflow_Model_Convert_Exception::FATAL);
             return $this;
         }
diff --git app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php
index ed67a2a..98ee5d5 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php
@@ -69,7 +69,8 @@ class Mage_Dataflow_Model_Convert_Parser_Xml_Excel extends Mage_Dataflow_Model_C
         }
 
         if (!is_callable(array($adapter, $adapterMethod))) {
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
 
diff --git app/code/core/Mage/Sales/Model/Quote/Item.php app/code/core/Mage/Sales/Model/Quote/Item.php
index 5c7e787..6bdda4a 100644
--- app/code/core/Mage/Sales/Model/Quote/Item.php
+++ app/code/core/Mage/Sales/Model/Quote/Item.php
@@ -381,8 +381,9 @@ class Mage_Sales_Model_Quote_Item extends Mage_Sales_Model_Quote_Item_Abstract
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
index 2d7b51e..0f2c78f 100644
--- app/code/core/Mage/Widget/Model/Widget/Instance.php
+++ app/code/core/Mage/Widget/Model/Widget/Instance.php
@@ -318,7 +318,11 @@ class Mage_Widget_Model_Widget_Instance extends Mage_Core_Model_Abstract
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
index df20394..a09c9be 100644
--- app/code/core/Mage/XmlConnect/Helper/Image.php
+++ app/code/core/Mage/XmlConnect/Helper/Image.php
@@ -81,6 +81,11 @@ class Mage_XmlConnect_Helper_Image extends Mage_Core_Helper_Abstract
             $uploader = new Varien_File_Uploader($field);
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
index c57c994..19ca1d7 100644
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
index 0000000..b9782e8
--- /dev/null
+++ app/design/adminhtml/default/default/template/notification/formkey.phtml
@@ -0,0 +1,38 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition License
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magentocommerce.com/license/enterprise-edition
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
+ * @license     http://www.magentocommerce.com/license/enterprise-edition
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
index 0000000..95f1eb8
--- /dev/null
+++ app/design/adminhtml/default/default/template/notification/symlink.phtml
@@ -0,0 +1,34 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition License
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magentocommerce.com/license/enterprise-edition
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
+ * @license     http://www.magentocommerce.com/license/enterprise-edition
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
index 744adf3..3764dcf 100644
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
index 77af444..c5acf5e 100644
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
index e98e131..df084f5 100644
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
index 825a72c..13fac10 100644
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
index 8a95340..7191387 100644
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
index 81accb8..0b91f59 100644
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
index 2ea630a..c8b7226 100644
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
index a151042..ccf6943 100644
--- app/design/frontend/base/default/template/checkout/onepage/shipping_method.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/shipping_method.phtml
@@ -43,4 +43,5 @@
             <img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="<?php echo $this->__('Loading next step...') ?>" title="<?php echo $this->__('Loading next step...') ?>" class="v-middle" /> <?php echo $this->__('Loading next step...') ?>
         </span>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </form>
diff --git app/design/frontend/enterprise/default/template/checkout/cart/shipping.phtml app/design/frontend/enterprise/default/template/checkout/cart/shipping.phtml
index c973789..683e31a 100644
--- app/design/frontend/enterprise/default/template/checkout/cart/shipping.phtml
+++ app/design/frontend/enterprise/default/template/checkout/cart/shipping.phtml
@@ -107,6 +107,7 @@
         <div class="buttons-set">
             <button type="submit" class="button" name="do" value="<?php echo $this->__('Update Total') ?>"><span><span><?php echo $this->__('Update Total') ?></span></span></button>
         </div>
+        <?php echo $this->getBlockHtml('formkey') ?>
     </fieldset>
 </form>
 <?php endif; ?>
diff --git app/design/frontend/enterprise/default/template/checkout/multishipping/addresses.phtml app/design/frontend/enterprise/default/template/checkout/multishipping/addresses.phtml
index 080c4ac..2a7e8fd 100644
--- app/design/frontend/enterprise/default/template/checkout/multishipping/addresses.phtml
+++ app/design/frontend/enterprise/default/template/checkout/multishipping/addresses.phtml
@@ -77,5 +77,6 @@
         <p class="back-link"><a href="<?php echo $this->getBackUrl() ?>"><small>&laquo; </small><?php echo $this->__('Back to Shopping Cart') ?></a></p>
         <button type="submit" class="button<?php if ($this->isContinueDisabled()):?> disabled<?php endif; ?>" onclick="$('can_continue_flag').value=1"<?php if ($this->isContinueDisabled()):?> disabled="disabled"<?php endif; ?>><span><span><?php echo $this->__('Continue to Shipping Information') ?></span></span></button>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </fieldset>
 </form>
diff --git app/design/frontend/enterprise/default/template/checkout/multishipping/billing.phtml app/design/frontend/enterprise/default/template/checkout/multishipping/billing.phtml
index d9026d4..e016c62 100644
--- app/design/frontend/enterprise/default/template/checkout/multishipping/billing.phtml
+++ app/design/frontend/enterprise/default/template/checkout/multishipping/billing.phtml
@@ -92,6 +92,7 @@
     <p class="back-link"><a href="<?php echo $this->getBackUrl() ?>"><small>&laquo; </small><?php echo $this->__('Back to Shipping Information') ?></a></p>
     <button type="submit" class="button"><span><span><?php echo $this->__('Continue to Review Your Order') ?></span></span></button>
 </div>
+<?php echo $this->getBlockHtml('formkey') ?>
 </form>
 </div>
 <script type="text/javascript">
diff --git app/design/frontend/enterprise/default/template/checkout/multishipping/shipping.phtml app/design/frontend/enterprise/default/template/checkout/multishipping/shipping.phtml
index fb892d9..dd8c4eb 100644
--- app/design/frontend/enterprise/default/template/checkout/multishipping/shipping.phtml
+++ app/design/frontend/enterprise/default/template/checkout/multishipping/shipping.phtml
@@ -116,5 +116,6 @@
         <p class="back-link"><a href="<?php echo $this->getBackUrl() ?>"><small>&laquo; </small><?php echo $this->__('Back to Select Addresses') ?></a></p>
         <button  class="button" type="submit"><span><span><?php echo $this->__('Continue to Billing Information') ?></span></span></button>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </fieldset>
 </form>
diff --git app/design/frontend/enterprise/default/template/checkout/onepage/billing.phtml app/design/frontend/enterprise/default/template/checkout/onepage/billing.phtml
index 61f2e38..6626087 100644
--- app/design/frontend/enterprise/default/template/checkout/onepage/billing.phtml
+++ app/design/frontend/enterprise/default/template/checkout/onepage/billing.phtml
@@ -211,6 +211,7 @@
     </span>
 </div>
 <p class="required"><?php echo $this->__('* Required Fields') ?></p>
+<?php echo $this->getBlockHtml('formkey') ?>
 </form>
 <script type="text/javascript">
 //<![CDATA[
diff --git app/design/frontend/enterprise/default/template/checkout/onepage/payment.phtml app/design/frontend/enterprise/default/template/checkout/onepage/payment.phtml
index 8c1490d..e1afd3a 100644
--- app/design/frontend/enterprise/default/template/checkout/onepage/payment.phtml
+++ app/design/frontend/enterprise/default/template/checkout/onepage/payment.phtml
@@ -36,6 +36,7 @@
     <fieldset>
         <?php echo $this->getChildChildHtml('methods_additional', '', true, true) ?>
         <?php echo $this->getChildHtml('methods') ?>
+        <?php echo $this->getBlockHtml('formkey') ?>
     </fieldset>
 </form>
 <div class="tool-tip" id="payment-tool-tip" style="display:none;">
diff --git app/design/frontend/enterprise/default/template/customerbalance/checkout/onepage/payment/additional.phtml app/design/frontend/enterprise/default/template/customerbalance/checkout/onepage/payment/additional.phtml
index 8d756f5..e0780fa 100644
--- app/design/frontend/enterprise/default/template/customerbalance/checkout/onepage/payment/additional.phtml
+++ app/design/frontend/enterprise/default/template/customerbalance/checkout/onepage/payment/additional.phtml
@@ -88,7 +88,7 @@
         } else {
             var elements = Form.getElements(this.form);
             for (var i=0; i<elements.length; i++) {
-                if (elements[i].name == 'payment[method]') {
+                if (elements[i].name == 'payment[method]' || elements[i].name == 'form_key') {
                     elements[i].disabled = false;
                 }
             }
diff --git app/design/frontend/enterprise/default/template/giftcardaccount/multishipping/payment.phtml app/design/frontend/enterprise/default/template/giftcardaccount/multishipping/payment.phtml
index 304ab26..9ec624d 100644
--- app/design/frontend/enterprise/default/template/giftcardaccount/multishipping/payment.phtml
+++ app/design/frontend/enterprise/default/template/giftcardaccount/multishipping/payment.phtml
@@ -38,7 +38,7 @@
         <script type="text/javascript">
         //<![CDATA[
             Form.getElements('multishipping-billing-form').each(function(elem){
-                if (elem.name == 'payment[method]' && elem.value == 'free') {
+                if ((elem.name == 'payment[method]' && elem.value == 'free') || elements[i].name == 'form_key') {
                     elem.checked = true;
                     elem.disabled = false;
                     elem.parentNode.show();
diff --git app/design/frontend/enterprise/default/template/giftcardaccount/onepage/payment/scripts.phtml app/design/frontend/enterprise/default/template/giftcardaccount/onepage/payment/scripts.phtml
index 5906ebe..67c56c0 100644
--- app/design/frontend/enterprise/default/template/giftcardaccount/onepage/payment/scripts.phtml
+++ app/design/frontend/enterprise/default/template/giftcardaccount/onepage/payment/scripts.phtml
@@ -24,19 +24,35 @@
  * @license     http://www.magentocommerce.com/license/enterprise-edition
  */
 ?>
+quoteBaseGrandTotal = <?php echo (float)$this->_getQuote()->getBaseGrandTotal(); ?>;
 var isGiftCardApplied = <?php if($this->isFullyPaidAfterApplication()): ?>true<?php else: ?>false<?php endif; ?>;
-if (quoteBaseGrandTotal < 0.0001 && isGiftCardApplied) {
+var epsilon = 0.0001;
+function enablePaymentMethods(free) {
     Payment.prototype.init = function () {
         var elements = Form.getElements(this.form);
-        var method = null;
         for (var i=0; i < elements.length; i++) {
-            if (elements[i].name == 'payment[method]' && elements[i].value == 'free') {
-                elements[i].checked = true;
-                method = 'free';
+            if (elements[i].name == 'payment[method]'
+                || elements[i].name == 'payment[use_customer_balance]'
+                || elements[i].name == 'payment[use_reward_points]'
+                || elements[i].name == 'form_key'
+            ) {
+                if ((free && elements[i].value == 'free') || (!free && elements[i].value != 'free')) {
+                    $((elements[i]).parentNode).show();
+                    if (free) {
+                        elements[i].checked = true;
+                        this.switchMethod('free');
+                    }
+                } else {
+                    $((elements[i]).parentNode).hide();
+                }
             } else {
-                $((elements[i]).parentNode).hide();
+                elements[i].disabled = true;
             }
         }
-        if (method) this.switchMethod(method);
     };
 }
+if (quoteBaseGrandTotal < epsilon && isGiftCardApplied) {
+    enablePaymentMethods(true);
+} else if (quoteBaseGrandTotal >= epsilon) {
+    enablePaymentMethods(false);
+}
diff --git app/design/frontend/enterprise/default/template/invitation/form.phtml app/design/frontend/enterprise/default/template/invitation/form.phtml
index ed712e2..31d0847 100644
--- app/design/frontend/enterprise/default/template/invitation/form.phtml
+++ app/design/frontend/enterprise/default/template/invitation/form.phtml
@@ -36,6 +36,7 @@
 <?php echo $this->getChildHtml('form_before')?>
 <?php if ($maxPerSend = (int)Mage::helper('enterprise_invitation')->getMaxInvitationsPerSend()): ?>
 <form id="invitationForm" action="" method="post">
+    <?php echo $this->getBlockHtml('formkey'); ?>
     <div class="fieldset">
     <h2 class="legend"><?php echo Mage::helper('enterprise_invitation')->__('Invite your friends by entering their email addresses below'); ?></h2>
         <ul class="form-list">
diff --git app/etc/config.xml app/etc/config.xml
index 988ce6a..a5f1e26 100644
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
index 205f6dd..ec32dda 100644
--- app/locale/en_US/Mage_Adminhtml.csv
+++ app/locale/en_US/Mage_Adminhtml.csv
@@ -1190,3 +1190,5 @@
 "to","to"
 "website(%s) scope","website(%s) scope"
 "{{base_url}} is not recommended to use in a production environment to declare the Base Unsecure URL / Base Secure URL. It is highly recommended to change this value in your Magento <a href=""%s"">configuration</a>.","{{base_url}} is not recommended to use in a production environment to declare the Base Unsecure URL / Base Secure URL. It is highly recommended to change this value in your Magento <a href=""%s"">configuration</a>."
+"Symlinks are enabled. This may expose security risks. We strongly recommend to disable them.","Symlinks are enabled. This may expose security risks. We strongly recommend to disable them."
+"You did not sign in correctly or your account is temporarily disabled.","You did not sign in correctly or your account is temporarily disabled."
diff --git app/locale/en_US/Mage_Core.csv app/locale/en_US/Mage_Core.csv
index 324469c..7895fe4 100644
--- app/locale/en_US/Mage_Core.csv
+++ app/locale/en_US/Mage_Core.csv
@@ -350,3 +350,4 @@
 "Your order cannot be completed at this time as there is no shipping methods available for it. Please make necessary changes in your shipping address.","Your order cannot be completed at this time as there is no shipping methods available for it. Please make necessary changes in your shipping address."
 "Your session has been expired, you will be relogged in now.","Your session has been expired, you will be relogged in now."
 "database ""%s""","database ""%s"""
+"Invalid image.","Invalid image."
diff --git app/locale/en_US/Mage_Dataflow.csv app/locale/en_US/Mage_Dataflow.csv
index 1de3305..0e4ba0f 100644
--- app/locale/en_US/Mage_Dataflow.csv
+++ app/locale/en_US/Mage_Dataflow.csv
@@ -30,3 +30,4 @@
 "hours","hours"
 "minute","minute"
 "minutes","minutes"
+"Backend name "Static" not supported.","Backend name "Static" not supported."
diff --git downloader/Maged/Connect.php downloader/Maged/Connect.php
index 1739355..05a193b 100644
--- downloader/Maged/Connect.php
+++ downloader/Maged/Connect.php
@@ -143,7 +143,11 @@ class Maged_Connect
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
@@ -217,13 +221,13 @@ class Maged_Connect
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
@@ -257,7 +261,13 @@ class Maged_Connect
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
@@ -267,6 +277,7 @@ class Maged_Connect
     }
 
     /**
+     * Show Errors
      *
      * @param array $errors Error messages
      * @return Maged_Connect
@@ -277,7 +288,7 @@ class Maged_Connect
         $run = new Maged_Model_Connect_Request();
         if ($callback = $run->get('failure_callback')) {
             if (is_array($callback)) {
-                call_user_func_array($callback, array($result));
+                call_user_func_array($callback, array($errors));
             } else {
                 echo $callback;
             }
@@ -290,8 +301,9 @@ class Maged_Connect
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
index 0a6875c..724a4bc 100755
--- downloader/Maged/Controller.php
+++ downloader/Maged/Controller.php
@@ -20,7 +20,7 @@
  *
  * @category    Mage
  * @package     Mage_Connect
- * @copyright   Copyright (c) 2010 Magento Inc. (http://www.magentocommerce.com)
+ * @copyright   Copyright (c) 2011 Magento Inc. (http://www.magentocommerce.com)
  * @license     http://www.magentocommerce.com/license/enterprise-edition
  */
 
@@ -32,7 +32,6 @@
 * @copyright  Copyright (c) 2009 Irubin Consulting Inc. DBA Varien (http://www.varien.com)
 * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
 */
-
 final class Maged_Controller
 {
     /**
@@ -90,9 +89,9 @@ final class Maged_Controller
     private $_view;
 
     /**
-     * Config instance
+     * Connect config instance
      *
-     * @var Maged_Model_Config
+     * @var Mage_Connect_Config
      */
     private $_config;
 
@@ -155,7 +154,7 @@ final class Maged_Controller
         $ftp = 'ftp://';
         $post['ftp_proto'] = 'ftp://';
 
-        if (!empty($post['ftp_path']) && strlen(trim($post['ftp_path'], '\\/'))>0) {
+        if (!empty($post['ftp_path']) && strlen(trim($post['ftp_path'], '\\/')) > 0) {
             $post['ftp_path'] = '/' . trim($post['ftp_path'], '\\/') . '/';
         } else {
             $post['ftp_path'] = '/';
@@ -164,30 +163,32 @@ final class Maged_Controller
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
@@ -198,7 +199,6 @@ final class Maged_Controller
 
     /**
      * NoRoute
-     *
      */
     public function norouteAction()
     {
@@ -208,7 +208,6 @@ final class Maged_Controller
 
     /**
      * Login
-     *
      */
     public function loginAction()
     {
@@ -218,7 +217,6 @@ final class Maged_Controller
 
     /**
      * Logout
-     *
      */
     public function logoutAction()
     {
@@ -228,14 +226,18 @@ final class Maged_Controller
 
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
@@ -252,21 +254,21 @@ final class Maged_Controller
 
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
@@ -294,7 +296,6 @@ final class Maged_Controller
 
     /**
      * Connect packages
-     *
      */
     public function connectPackagesAction()
     {
@@ -310,24 +311,26 @@ final class Maged_Controller
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
@@ -337,8 +340,8 @@ final class Maged_Controller
         }
         $prepareResult = $this->model('connect', true)->prepareToInstall($_POST['install_package_id']);
 
-        $packages = isset($prepareResult['data'])? $prepareResult['data']:array();
-        $errors = isset($prepareResult['errors'])? $prepareResult['errors']:array();
+        $packages   = isset($prepareResult['data']) ? $prepareResult['data'] : array();
+        $errors     = isset($prepareResult['errors']) ? $prepareResult['errors'] : array();
 
         $this->view()->set('packages', $packages);
         $this->view()->set('errors', $errors);
@@ -349,7 +352,6 @@ final class Maged_Controller
 
     /**
      * Install package
-     *
      */
     public function connectInstallPackagePostAction()
     {
@@ -362,7 +364,6 @@ final class Maged_Controller
 
     /**
      * Install uploaded package
-     *
      */
     public function connectInstallPackageUploadAction()
     {
@@ -388,7 +389,7 @@ final class Maged_Controller
             return;
         }
 
-        $target = $this->_mageDir . DS . "var/".uniqid().$info['name'];
+        $target = $this->_mageDir . DS . "var/" . uniqid() . $info['name'];
         $res = move_uploaded_file($info['tmp_name'], $target);
         if(false === $res) {
             echo "Error moving uploaded file";
@@ -400,8 +401,16 @@ final class Maged_Controller
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
@@ -415,14 +424,14 @@ final class Maged_Controller
 
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
@@ -432,12 +441,16 @@ final class Maged_Controller
 
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
@@ -447,9 +460,9 @@ final class Maged_Controller
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
@@ -457,9 +470,8 @@ final class Maged_Controller
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
@@ -469,7 +481,6 @@ final class Maged_Controller
 
     /**
      * Constructor
-     *
      */
     public function __construct()
     {
@@ -479,7 +490,6 @@ final class Maged_Controller
 
     /**
      * Run
-     *
      */
     public static function run()
     {
@@ -502,7 +512,7 @@ final class Maged_Controller
             self::$_instance = new self;
 
             if (self::$_instance->isDownloaded() && self::$_instance->isInstalled()) {
-                Mage::app();
+                Mage::app('', 'store', array('global_ban_use_cache'=>true));
                 Mage::getSingleton('adminhtml/url')->turnOffSecretKey();
             }
         }
@@ -704,10 +714,10 @@ final class Maged_Controller
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
@@ -735,7 +745,7 @@ final class Maged_Controller
      */
     public function getActionMethod($action = null)
     {
-        $method = (!is_null($action) ? $action : $this->_action).'Action';
+        $method = (!is_null($action) ? $action : $this->_action) . 'Action';
         return $method;
     }
 
@@ -758,7 +768,6 @@ final class Maged_Controller
 
     /**
      * Dispatch process
-     *
      */
     public function dispatch()
     {
@@ -767,7 +776,7 @@ final class Maged_Controller
         $this->setAction();
 
         if (!$this->isInstalled()) {
-            if (!in_array($this->getAction(), array('index', 'connectInstallAll', 'empty'))) {
+            if (!in_array($this->getAction(), array('index', 'connectInstallAll', 'empty', 'cleanCache'))) {
                 $this->setAction('index');
             }
         } else {
@@ -778,7 +787,6 @@ final class Maged_Controller
             $this->_isDispatched = true;
 
             $method = $this->getActionMethod();
-            //echo($method);exit();
             $this->$method();
         }
 
@@ -796,7 +804,6 @@ final class Maged_Controller
             $this->_writable = is_writable($this->getMageDir() . DIRECTORY_SEPARATOR)
                 && is_writable($this->filepath())
                 && (!file_exists($this->filepath('config.ini') || is_writable($this->filepath('config.ini'))));
-
         }
         return $this->_writable;
     }
@@ -860,21 +867,20 @@ final class Maged_Controller
 
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
@@ -882,38 +888,67 @@ final class Maged_Controller
 
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
@@ -925,7 +960,12 @@ final class Maged_Controller
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
index a48ba0c..84fc5fe 100644
--- downloader/Maged/Model/Session.php
+++ downloader/Maged/Model/Session.php
@@ -20,7 +20,7 @@
  *
  * @category    Mage
  * @package     Mage_Connect
- * @copyright   Copyright (c) 2010 Magento Inc. (http://www.magentocommerce.com)
+ * @copyright   Copyright (c) 2011 Magento Inc. (http://www.magentocommerce.com)
  * @license     http://www.magentocommerce.com/license/enterprise-edition
  */
 
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
@@ -60,22 +59,22 @@ class Maged_Model_Session extends Maged_Model
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
@@ -83,8 +82,22 @@ class Maged_Model_Session extends Maged_Model
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
@@ -95,7 +108,7 @@ class Maged_Model_Session extends Maged_Model
             $this->set('return_url', $_GET['return']);
         }
 
-        if ($this->getUserId()) {
+        if ($this->_checkUserAccess()) {
             return $this;
         }
 
@@ -104,40 +117,58 @@ class Maged_Model_Session extends Maged_Model
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
@@ -148,36 +179,40 @@ class Maged_Model_Session extends Maged_Model
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
@@ -189,10 +224,10 @@ class Maged_Model_Session extends Maged_Model
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
@@ -213,4 +248,24 @@ class Maged_Model_Session extends Maged_Model
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
index 185ac40..59e3ad2 100644
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
index 5818446..a34f9a6 100644
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
diff --git skin/frontend/enterprise/default/js/opcheckout.js skin/frontend/enterprise/default/js/opcheckout.js
index b090c4a..862ed41 100644
--- skin/frontend/enterprise/default/js/opcheckout.js
+++ skin/frontend/enterprise/default/js/opcheckout.js
@@ -636,7 +636,7 @@ Payment.prototype = {
         var elements = Form.getElements(this.form);
         var method = null;
         for (var i=0; i<elements.length; i++) {
-            if (elements[i].name=='payment[method]') {
+            if (elements[i].name=='payment[method]' || elements[i].name=='form_key') {
                 if (elements[i].checked) {
                     method = elements[i].value;
                 }
