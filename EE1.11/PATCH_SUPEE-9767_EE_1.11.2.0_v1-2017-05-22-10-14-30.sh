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


PATCH_SUPEE-9767_EE_1.11.2.0_v1.sh | EE_1.11.2.0 | v1 | 226caf7 | Mon Feb 20 17:33:39 2017 +0200 | 2321b14

__PATCHFILE_FOLLOWS__
diff --git app/Mage.php app/Mage.php
index 82f51e8..2931e53 100644
--- app/Mage.php
+++ app/Mage.php
@@ -343,6 +343,7 @@ final class Mage
      * Get base URL path by type
      *
      * @param string $type
+     * @param null|bool $secure
      * @return string
      */
     public static function getBaseUrl($type = Mage_Core_Model_Store::URL_TYPE_LINK, $secure = null)
diff --git app/code/core/Enterprise/CatalogEvent/controllers/Adminhtml/Catalog/EventController.php app/code/core/Enterprise/CatalogEvent/controllers/Adminhtml/Catalog/EventController.php
index e0b1fec..0c660e6 100644
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
index 94e1673..5cd9920 100644
--- app/code/core/Enterprise/GiftWrapping/Model/Wrapping.php
+++ app/code/core/Enterprise/GiftWrapping/Model/Wrapping.php
@@ -173,6 +173,11 @@ class Enterprise_GiftWrapping_Model_Wrapping extends Mage_Core_Model_Abstract
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
index afd6509..f339cd4 100644
--- app/code/core/Enterprise/Invitation/Model/Config.php
+++ app/code/core/Enterprise/Invitation/Model/Config.php
@@ -41,6 +41,8 @@ class Enterprise_Invitation_Model_Config
     const XML_PATH_REGISTRATION_REQUIRED_INVITATION = 'enterprise_invitation/general/registration_required_invitation';
     const XML_PATH_REGISTRATION_USE_INVITER_GROUP = 'enterprise_invitation/general/registration_use_inviter_group';
 
+    const XML_PATH_INTERVAL = 'enterprise_invitation/general/interval';
+
     /**
      * Return max Invitation amount per send by config
      *
@@ -88,7 +90,7 @@ class Enterprise_Invitation_Model_Config
 
     /**
      * Retrieve configuration for availability of invitations
-     * on global level. Also will disallowe any functionality in admin.
+     * on global level. Also will disallow any functionality in admin.
      *
      * @param int $storeId
      * @return boolean
@@ -113,4 +115,14 @@ class Enterprise_Invitation_Model_Config
 
         return false;
     }
+
+    /**
+     * Retrieve configuration for the minimum interval between invitations
+     * @param int $storeId
+     * @return mixed
+     */
+    public function getMinInvitationPeriod($storeId = null)
+    {
+        return Mage::getStoreConfig(self::XML_PATH_INTERVAL, $storeId);
+    }
 }
diff --git app/code/core/Enterprise/Invitation/Model/Invitation.php app/code/core/Enterprise/Invitation/Model/Invitation.php
index b22c2a1..c538531 100644
--- app/code/core/Enterprise/Invitation/Model/Invitation.php
+++ app/code/core/Enterprise/Invitation/Model/Invitation.php
@@ -429,4 +429,23 @@ class Enterprise_Invitation_Model_Invitation extends Mage_Core_Model_Abstract
         return true;
     }
 
+    /**
+     * Checks if customer invitations limit exceeded
+     * if no - returns the allowed limit
+     * @param $customerId
+     * @return int
+     */
+    public function isSendingLimitExceeded($customerId)
+    {
+        $config = Mage::getSingleton('enterprise_invitation/config');
+        $sendInterval = $config->getMinInvitationPeriod();
+        $collection = $this->getCollection()
+            ->addFilter('customer_id', $customerId)
+            ->addFieldToFilter('invitation_date', array(
+                'from' => $this->getResource()->formatDate(strtotime("-{$sendInterval} minutes"))
+            ));
+        return count($collection) < $config->getMaxInvitationsPerSend()
+            ? $config->getMaxInvitationsPerSend() - count($collection)
+            : 0;
+    }
 }
diff --git app/code/core/Enterprise/Invitation/controllers/IndexController.php app/code/core/Enterprise/Invitation/controllers/IndexController.php
index a7580ed..d599ad8 100644
--- app/code/core/Enterprise/Invitation/controllers/IndexController.php
+++ app/code/core/Enterprise/Invitation/controllers/IndexController.php
@@ -60,53 +60,72 @@ class Enterprise_Invitation_IndexController extends Mage_Core_Controller_Front_A
     {
         $data = $this->getRequest()->getPost();
         if ($data) {
-            $customer = Mage::getSingleton('customer/session')->getCustomer();
-            $invPerSend = Mage::getSingleton('enterprise_invitation/config')->getMaxInvitationsPerSend();
-            $attempts = 0;
-            $sent     = 0;
+            if (!$this->_validateFormKey()) {
+                return $this->_redirect('*/*/');
+            }
+            $customer       = Mage::getSingleton('customer/session')->getCustomer();
+            $attempts       = 0;
+            $sent           = 0;
             $customerExists = 0;
+            $leftAttempts   = Mage::getModel('enterprise_invitation/invitation')
+                ->isSendingLimitExceeded($customer->getId());
+
+            if (!$leftAttempts) {
+                Mage::getSingleton('customer/session')->addError(
+                    Mage::helper('enterprise_invitation')->__('Invitations limit exceeded. Please try again later.')
+                );
+                $this->_redirect('*/*/*');
+                return;
+            }
             foreach ($data['email'] as $email) {
                 $attempts++;
-                if (!Zend_Validate::is($email, 'EmailAddress')) {
+
+                if ($attempts > $leftAttempts) {
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
diff --git app/code/core/Enterprise/Invitation/etc/config.xml app/code/core/Enterprise/Invitation/etc/config.xml
index c350e81..0158e9e 100644
--- app/code/core/Enterprise/Invitation/etc/config.xml
+++ app/code/core/Enterprise/Invitation/etc/config.xml
@@ -172,6 +172,7 @@
                 <registration_required_invitation>0</registration_required_invitation>
                 <max_invitation_amount_per_send>5</max_invitation_amount_per_send>
                 <allow_customer_message>1</allow_customer_message>
+                <interval>10</interval>
             </general>
         </enterprise_invitation>
     </default>
diff --git app/code/core/Enterprise/Invitation/etc/system.xml app/code/core/Enterprise/Invitation/etc/system.xml
index 741fec7..23fb5a9 100644
--- app/code/core/Enterprise/Invitation/etc/system.xml
+++ app/code/core/Enterprise/Invitation/etc/system.xml
@@ -128,6 +128,14 @@
                             <show_in_website>1</show_in_website>
                             <show_in_store>1</show_in_store>
                         </max_invitation_amount_per_send>
+                        <interval translate="label comment">
+                            <label>Minimum Interval between invites(minutes)</label>
+                            <validate>validate-digits</validate>
+                            <sort_order>30</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>1</show_in_website>
+                            <show_in_store>1</show_in_store>
+                        </interval>
                     </fields>
                 </general>
             </groups>
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
diff --git app/code/core/Enterprise/PageCache/Model/Container/Orders.php app/code/core/Enterprise/PageCache/Model/Container/Orders.php
index 2678c1c..92d96dc 100644
--- app/code/core/Enterprise/PageCache/Model/Container/Orders.php
+++ app/code/core/Enterprise/PageCache/Model/Container/Orders.php
@@ -52,6 +52,16 @@ class Enterprise_PageCache_Model_Container_Orders extends Enterprise_PageCache_M
     }
 
     /**
+     * Get cache identifier
+     *
+     * @return string
+     */
+    public function getCacheId()
+    {
+        return $this->_getCacheId();
+    }
+
+    /**
      * Get container individual additional cache id
      *
      * @return string | false
diff --git app/code/core/Enterprise/PageCache/Model/Container/Wishlist.php app/code/core/Enterprise/PageCache/Model/Container/Wishlist.php
index fbf443a..eec357f 100644
--- app/code/core/Enterprise/PageCache/Model/Container/Wishlist.php
+++ app/code/core/Enterprise/PageCache/Model/Container/Wishlist.php
@@ -51,6 +51,16 @@ class Enterprise_PageCache_Model_Container_Wishlist extends Enterprise_PageCache
     }
 
     /**
+     * Get cache identifier
+     *
+     * @return string
+     */
+    public function getCacheId()
+    {
+        return $this->_getCacheId();
+    }
+
+    /**
      * Render block content
      *
      * @return string
diff --git app/code/core/Enterprise/PageCache/Model/Observer.php app/code/core/Enterprise/PageCache/Model/Observer.php
index d685f01..9722ad1 100644
--- app/code/core/Enterprise/PageCache/Model/Observer.php
+++ app/code/core/Enterprise/PageCache/Model/Observer.php
@@ -20,10 +20,17 @@
  *
  * @category    Enterprise
  * @package     Enterprise_PageCache
- * @copyright   Copyright (c) 2011 Magento Inc. (http://www.magentocommerce.com)
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
     /*
@@ -32,24 +39,51 @@ class Enterprise_PageCache_Model_Observer
     const XML_PATH_DESIGN_EXCEPTION = 'design/package/ua_regexp';
 
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
+     * Cache instance
+     *
+     * @var Mage_Core_Model_Cache
+     */
+    protected $_cacheInstance;
+
+    /**
      * Class constructor
      */
     public function __construct()
     {
-        $this->_processor = Mage::getSingleton('enterprise_pagecache/processor');
-        $this->_config    = Mage::getSingleton('enterprise_pagecache/config');
-        $this->_isEnabled = Mage::app()->useCache('full_page');
+        $this->_processor = isset($args['processor'])
+            ? $args['processor']
+            : Mage::getSingleton('enterprise_pagecache/processor');
+        $this->_config = isset($args['config']) ? $args['config'] : Mage::getSingleton('enterprise_pagecache/config');
+        $this->_isEnabled = isset($args['enabled']) ? $args['enabled'] : Mage::app()->useCache('full_page');
+        $this->_cacheInstance = isset($args['cacheInstance'])
+            ? $args['cacheInstance']
+            : Enterprise_PageCache_Model_Cache::getCacheInstance();
     }
 
     /**
      * Check if full page cache is enabled
+     *
      * @return bool
      */
     public function isCacheEnabled()
@@ -79,7 +113,8 @@ class Enterprise_PageCache_Model_Observer
     /**
      * Check when cache should be disabled
      *
-     * @param $observer
+     * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function processPreDispatch(Varien_Event_Observer $observer)
     {
@@ -99,9 +134,15 @@ class Enterprise_PageCache_Model_Observer
         }
         /**
          * Check if request will be cached
+         * canProcessRequest checks is theoretically possible to cache page
+         * getRequestProcessor check is page have full page cache processor
+         * isStraight works for partially cached pages where getRequestProcessor doesn't work
+         * (not all holes are filled by content)
          */
-        if ($this->_processor->canProcessRequest($request) && $this->_processor->getRequestProcessor($request)) {
-            Mage::app()->getCacheInstance()->banUse(Mage_Core_Block_Abstract::CACHE_GROUP); // disable blocks cache
+        if ($this->_processor->canProcessRequest($request)
+            && ($request->isStraight() || $this->_processor->getRequestProcessor($request))
+        ) {
+            Mage::app()->getCacheInstance()->banUse(Mage_Core_Block_Abstract::CACHE_GROUP);
         }
         $this->_getCookie()->updateCustomerCookies();
         return $this;
@@ -132,13 +173,15 @@ class Enterprise_PageCache_Model_Observer
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
@@ -146,12 +189,14 @@ class Enterprise_PageCache_Model_Observer
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
@@ -173,6 +218,7 @@ class Enterprise_PageCache_Model_Observer
      * Check product state on post dispatch to allow product page be cached
      *
      * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function checkProductState(Varien_Event_Observer $observer)
     {
@@ -194,6 +240,7 @@ class Enterprise_PageCache_Model_Observer
      * Check if data changes duering object save affect cached pages
      *
      * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function validateDataChanges(Varien_Event_Observer $observer)
     {
@@ -201,13 +248,15 @@ class Enterprise_PageCache_Model_Observer
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
@@ -215,20 +264,45 @@ class Enterprise_PageCache_Model_Observer
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
-        Enterprise_PageCache_Model_Cache::getCacheInstance()->clean(Enterprise_PageCache_Model_Processor::CACHE_TAG);
+        $this->_cacheInstance->clean(Enterprise_PageCache_Model_Processor::CACHE_TAG);
+        return $this;
+    }
+
+    /**
+     * Flush full page cache
+     *
+     * @return Enterprise_PageCache_Model_Observer
+     */
+    public function flushCache()
+    {
+        $this->_cacheInstance->flush();
+        return $this;
+    }
+
+    /**
+     * Clean expired entities in full page cache
+     * @return Enterprise_PageCache_Model_Observer
+     */
+    public function cleanExpiredCache()
+    {
+        $this->_cacheInstance->getFrontend()->clean(Zend_Cache::CLEANING_MODE_OLD);
         return $this;
     }
 
     /**
      * Invalidate full page cache
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function invalidateCache()
     {
@@ -240,6 +314,7 @@ class Enterprise_PageCache_Model_Observer
      * Render placeholder tags around the block if needed
      *
      * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function renderBlockPlaceholder(Varien_Event_Observer $observer)
     {
@@ -249,6 +324,7 @@ class Enterprise_PageCache_Model_Observer
         $block = $observer->getEvent()->getBlock();
         $transport = $observer->getEvent()->getTransport();
         $placeholder = $this->_config->getBlockPlaceholder($block);
+
         if ($transport && $placeholder) {
             $blockHtml = $transport->getHtml();
             $blockHtml = $placeholder->getStartTag() . $blockHtml . $placeholder->getEndTag();
@@ -262,6 +338,7 @@ class Enterprise_PageCache_Model_Observer
      *
      * @param Varien_Event_Observer $observer
      * @deprecated after 1.8
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function blockCreateAfter(Varien_Event_Observer $observer)
     {
@@ -280,6 +357,7 @@ class Enterprise_PageCache_Model_Observer
      * Set cart hash in cookie on quote change
      *
      * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function registerQuoteChange(Varien_Event_Observer $observer)
     {
@@ -295,7 +373,7 @@ class Enterprise_PageCache_Model_Observer
             . $this->_getCookie()->get(Enterprise_PageCache_Model_Cookie::COOKIE_CART)
             . $this->_getCookie()->get(Enterprise_PageCache_Model_Cookie::COOKIE_CUSTOMER));
 
-        Enterprise_PageCache_Model_Cache::getCacheInstance()->remove($cacheId);
+        $this->_cacheInstance->remove($cacheId);
 
         return $this;
     }
@@ -304,6 +382,7 @@ class Enterprise_PageCache_Model_Observer
      * Set compare list in cookie on list change. Also modify recently compared cookie.
      *
      * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function registerCompareListChange(Varien_Event_Observer $observer)
     {
@@ -349,6 +428,7 @@ class Enterprise_PageCache_Model_Observer
      * Set new message cookie on adding messsage to session.
      *
      * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function processNewMessage(Varien_Event_Observer $observer)
     {
@@ -360,18 +440,12 @@ class Enterprise_PageCache_Model_Observer
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
@@ -392,16 +466,47 @@ class Enterprise_PageCache_Model_Observer
         Mage::getSingleton('catalog/product_visibility')->addVisibleInSiteFilterToCollection($collection);
         $productIds = $collection->load()->getLoadedIds();
         $productIds = implode(',', $productIds);
-        Enterprise_PageCache_Model_Cookie::registerViewedProducts($productIds, $countLimit, false);
+        $this->_getCookie()->registerViewedProducts($productIds, $countLimit, false);
+        return $this;
+    }
 
+    /**
+     * Update customer rates cookie after address update
+     *
+     * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
+     */
+    public function customerAddressUpdate(Varien_Event_Observer $observer)
+    {
+        if (!$this->isCacheEnabled()) {
+            return $this;
+        }
+        $this->_getCookie()->updateCustomerCookies();
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
@@ -416,6 +521,7 @@ class Enterprise_PageCache_Model_Observer
             Enterprise_PageCache_Model_Cookie::registerViewedProducts(array(), 0, false);
         }
 
+        $this->updateFormKeyCookie();
         return $this;
     }
 
@@ -423,6 +529,7 @@ class Enterprise_PageCache_Model_Observer
      * Set wishlist hash in cookie on wishlist change
      *
      * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function registerWishlistChange(Varien_Event_Observer $observer)
     {
@@ -446,9 +553,29 @@ class Enterprise_PageCache_Model_Observer
     }
 
     /**
+     * Clear wishlist list
+     *
+     * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
+     */
+    public function registerWishlistListChange(Varien_Event_Observer $observer)
+    {
+        if (!$this->isCacheEnabled()) {
+            return $this;
+        }
+
+        /** @var Enterprise_PageCache_Model_Container_Wishlist $blockContainer */
+        $blockContainer = Mage::getModel('enterprise_pagecache/container_wishlists');
+        $this->_cacheInstance->remove($blockContainer->getCacheId());
+
+        return $this;
+    }
+
+    /**
      * Set poll hash in cookie on poll vote
      *
      * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function registerPollChange(Varien_Event_Observer $observer)
     {
@@ -466,6 +593,7 @@ class Enterprise_PageCache_Model_Observer
      * Clean order sidebar cache
      *
      * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function registerNewOrder(Varien_Event_Observer $observer)
     {
@@ -475,7 +603,7 @@ class Enterprise_PageCache_Model_Observer
 
         // Customer order sidebar tag
         $cacheId = md5($this->_getCookie()->get(Enterprise_PageCache_Model_Cookie::COOKIE_CUSTOMER));
-        Enterprise_PageCache_Model_Cache::getCacheInstance()->remove($cacheId);
+        $this->_cacheInstance->remove($cacheId);
         return $this;
     }
 
@@ -483,6 +611,7 @@ class Enterprise_PageCache_Model_Observer
      * Remove new message cookie on clearing session messages.
      *
      * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function processMessageClearing(Varien_Event_Observer $observer)
     {
@@ -497,12 +626,14 @@ class Enterprise_PageCache_Model_Observer
      * Resave exception rules to cache storage
      *
      * @param Varien_Event_Observer $observer
+     * @return Enterprise_PageCache_Model_Observer
      */
     public function registerDesignExceptionsChange(Varien_Event_Observer $observer)
     {
         $object = $observer->getDataObject();
-        Enterprise_PageCache_Model_Cache::getCacheInstance()
-            ->save($object->getValue(), Enterprise_PageCache_Model_Processor::DESIGN_EXCEPTION_KEY);
+        $this->_cacheInstance
+            ->save($object->getValue(), Enterprise_PageCache_Model_Processor::DESIGN_EXCEPTION_KEY,
+                array(Enterprise_PageCache_Model_Processor::CACHE_TAG));
         return $this;
     }
 
@@ -546,6 +677,10 @@ class Enterprise_PageCache_Model_Observer
      */
     public function updateProductInfo(Varien_Event_Observer $observer)
     {
+        if (!$this->isCacheEnabled()) {
+            return $this;
+        }
+
         $paramsObject = $observer->getEvent()->getParams();
         if ($paramsObject instanceof Varien_Object) {
             if (array_key_exists(Enterprise_PageCache_Model_Cookie::COOKIE_CATEGORY_ID, $_COOKIE)) {
@@ -580,6 +715,22 @@ class Enterprise_PageCache_Model_Observer
     }
 
     /**
+     * Observer on changed Customer SegmentIds
+     *
+     * @param Varien_Event_Observer $observer
+     * @return void
+     */
+    public function changedCustomerSegmentIds(Varien_Event_Observer $observer)
+    {
+        if (!$this->isCacheEnabled()) {
+            return;
+        }
+        $segmentIds = is_array($observer->getSegmentIds()) ? $observer->getSegmentIds() : array();
+        $segmentsIdsString= implode(',', $segmentIds);
+        $this->_getCookie()->set(Enterprise_PageCache_Model_Cookie::CUSTOMER_SEGMENT_IDS, $segmentsIdsString);
+    }
+
+    /**
      * Register form key in session from cookie value
      *
      * @param Varien_Event_Observer $observer
@@ -593,8 +744,19 @@ class Enterprise_PageCache_Model_Observer
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
index d8e2fc9..ad9ed7c 100644
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
index 977287e..d536ba1 100644
--- app/code/core/Mage/Admin/Model/Session.php
+++ app/code/core/Mage/Admin/Model/Session.php
@@ -139,6 +139,9 @@ class Mage_Admin_Model_Session extends Mage_Core_Model_Session_Abstract
             }
         }
         catch (Mage_Core_Exception $e) {
+            $e->setMessage(
+                Mage::helper('adminhtml')->__('You did not sign in correctly or your account is temporarily disabled.')
+            );
             Mage::dispatchEvent('admin_session_user_login_failed',
                     array('user_name' => $username, 'exception' => $e));
             if ($request && !$request->getParam('messageSent')) {
diff --git app/code/core/Mage/Adminhtml/Block/Checkout/Formkey.php app/code/core/Mage/Adminhtml/Block/Checkout/Formkey.php
new file mode 100644
index 0000000..6c173d2
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
+ * @package     Mage_Admin
+ * @copyright   Copyright (c) 2011 Magento Inc. (http://www.magentocommerce.com)
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
index 0000000..a397cce
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
+ * @package     Mage_Admin
+ * @copyright   Copyright (c) 2011 Magento Inc. (http://www.magentocommerce.com)
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
index 9545483..864a8f2 100644
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
diff --git app/code/core/Mage/Adminhtml/Model/Config/Data.php app/code/core/Mage/Adminhtml/Model/Config/Data.php
index 6507602..82833c9 100644
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
index 6baf4de..dd9d662 100644
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
index 530d70d..751537c 100644
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
@@ -339,6 +345,11 @@ class Mage_Checkout_MultishippingController extends Mage_Checkout_Controller_Act
 
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
@@ -442,6 +453,11 @@ class Mage_Checkout_MultishippingController extends Mage_Checkout_Controller_Act
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
index e6dd510..70eccb2 100644
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
@@ -428,6 +448,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
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
index 9c0dedd..ccf79cf 100644
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
index 715fe4c..e645600 100644
--- app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
+++ app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
@@ -282,6 +282,11 @@ class Mage_Cms_Model_Wysiwyg_Images_Storage extends Varien_Object
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
index e24a38e..dfb702a 100644
--- app/code/core/Mage/Core/Controller/Front/Action.php
+++ app/code/core/Mage/Core/Controller/Front/Action.php
@@ -20,7 +20,7 @@
  *
  * @category    Mage
  * @package     Mage_Core
- * @copyright   Copyright (c) 2011 Magento Inc. (http://www.magentocommerce.com)
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
@@ -88,7 +98,7 @@ class Mage_Core_Controller_Front_Action extends Mage_Core_Controller_Varien_Acti
     }
 
     /**
-     * Declare headers and content file in responce for file download
+     * Declare headers and content file in response for file download
      *
      * @param string $fileName
      * @param string|array $content set to null to avoid starting output, $contentLength should be set explicitly in
@@ -146,10 +156,36 @@ class Mage_Core_Controller_Front_Action extends Mage_Core_Controller_Varien_Acti
                 if (!empty($content['rm'])) {
                     $ioAdapter->rm($file);
                 }
+
+                exit(0);
             } else {
                 $this->getResponse()->setBody($content);
             }
         }
         return $this;
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
index 8750b05..007f941 100644
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
@@ -312,7 +315,7 @@ class Mage_Core_Controller_Request_Http extends Zend_Controller_Request_Http
     /**
      * Set a member of the $_POST superglobal
      *
-     * @param striing|array $key
+     * @param string|array $key
      * @param mixed $value
      *
      * @return Mage_Core_Controller_Request_Http
diff --git app/code/core/Mage/Core/Controller/Varien/Action.php app/code/core/Mage/Core/Controller/Varien/Action.php
index 1326a08..32a50d9 100644
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
@@ -452,14 +451,21 @@ abstract class Mage_Core_Controller_Varien_Action
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
@@ -487,13 +493,32 @@ abstract class Mage_Core_Controller_Varien_Action
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
@@ -502,6 +527,8 @@ abstract class Mage_Core_Controller_Varien_Action
             return;
         }
 
+        Varien_Autoload::registerScope($this->getRequest()->getRouteName());
+
         Mage::dispatchEvent('controller_action_predispatch', array('controller_action'=>$this));
         Mage::dispatchEvent(
             'controller_action_predispatch_'.$this->getRequest()->getRouteName(),
@@ -548,7 +575,6 @@ abstract class Mage_Core_Controller_Varien_Action
             $this->renderLayout();
         } else {
             $status->setForwarded(true);
-            #$this->_forward('cmsNoRoute', 'index', 'cms');
             $this->_forward(
                 $status->getForwardAction(),
                 $status->getForwardController(),
@@ -585,7 +611,7 @@ abstract class Mage_Core_Controller_Varien_Action
      * @param string $action
      * @param string|null $controller
      * @param string|null $module
-     * @param string|null $params
+     * @param array|null $params
      */
     protected function _forward($action, $controller = null, $module = null, array $params = null)
     {
@@ -593,15 +619,15 @@ abstract class Mage_Core_Controller_Varien_Action
 
         $request->initForward();
 
-        if (!is_null($params)) {
+        if (isset($params)) {
             $request->setParams($params);
         }
 
-        if (!is_null($controller)) {
+        if (isset($controller)) {
             $request->setControllerName($controller);
 
             // Module should only be reset if controller has been specified
-            if (!is_null($module)) {
+            if (isset($module)) {
                 $request->setModuleName($module);
             }
         }
@@ -611,7 +637,7 @@ abstract class Mage_Core_Controller_Varien_Action
     }
 
     /**
-     * Inits layout messages by message storage(s), loading and adding messages to layout messages block
+     * Initializing layout messages by message storage(s), loading and adding messages to layout messages block
      *
      * @param string|array $messagesStorage
      * @return Mage_Core_Controller_Varien_Action
@@ -639,7 +665,7 @@ abstract class Mage_Core_Controller_Varien_Action
     }
 
     /**
-     * Inits layout messages by message storage(s), loading and adding messages to layout messages block
+     * Initializing layout messages by message storage(s), loading and adding messages to layout messages block
      *
      * @param string|array $messagesStorage
      * @return Mage_Core_Controller_Varien_Action
@@ -666,9 +692,32 @@ abstract class Mage_Core_Controller_Varien_Action
      *
      * @param   string $path
      * @param   array $arguments
+     * @return  Mage_Core_Controller_Varien_Action
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
@@ -677,6 +726,7 @@ abstract class Mage_Core_Controller_Varien_Action
      * Redirect to success page
      *
      * @param string $defaultUrl
+     * @return Mage_Core_Controller_Varien_Action
      */
     protected function _redirectSuccess($defaultUrl)
     {
@@ -695,6 +745,7 @@ abstract class Mage_Core_Controller_Varien_Action
      * Redirect to error page
      *
      * @param string $defaultUrl
+     * @return  Mage_Core_Controller_Varien_Action
      */
     protected function _redirectError($defaultUrl)
     {
@@ -710,7 +761,7 @@ abstract class Mage_Core_Controller_Varien_Action
     }
 
     /**
-     * Set referer url for redirect in responce
+     * Set referer url for redirect in response
      *
      * @param   string $defaultUrl
      * @return  Mage_Core_Controller_Varien_Action
@@ -880,6 +931,7 @@ abstract class Mage_Core_Controller_Varien_Action
      *
      * @see self::_renderTitles()
      * @param string|false|-1|null $text
+     * @param bool $resetIfExists
      * @return Mage_Core_Controller_Varien_Action
      */
     protected function _title($text = null, $resetIfExists = true)
@@ -985,7 +1037,7 @@ abstract class Mage_Core_Controller_Varien_Action
     }
 
     /**
-     * Declare headers and content file in responce for file download
+     * Declare headers and content file in response for file download
      *
      * @param string $fileName
      * @param string|array $content set to null to avoid starting output, $contentLength should be set explicitly in
diff --git app/code/core/Mage/Core/Controller/Varien/Front.php app/code/core/Mage/Core/Controller/Varien/Front.php
index f48dccb..3cc6633 100644
--- app/code/core/Mage/Core/Controller/Varien/Front.php
+++ app/code/core/Mage/Core/Controller/Varien/Front.php
@@ -296,8 +296,12 @@ class Mage_Core_Controller_Varien_Front extends Varien_Object
         if (!Mage::isInstalled() || $request->getPost()) {
             return;
         }
-        if (!Mage::getStoreConfig('web/url/redirect_to_base')) {
+
+        $redirectCode = Mage::getStoreConfig('web/url/redirect_to_base');
+        if (!$redirectCode) {
             return;
+        } elseif ($redirectCode != 301) {
+            $redirectCode = 302;
         }
 
         $adminPath = (string)Mage::getConfig()->getNode(Mage_Adminhtml_Helper_Data::XML_PATH_CUSTOM_ADMIN_PATH);
@@ -310,23 +314,19 @@ class Mage_Core_Controller_Varien_Front extends Varien_Object
             return;
         }
 
-        $baseUrl = Mage::getBaseUrl(Mage_Core_Model_Store::URL_TYPE_WEB, Mage::app()->getStore()->isCurrentlySecure());
-
+        $baseUrl = Mage::getBaseUrl(Mage_Core_Model_Store::URL_TYPE_WEB,
+            Mage::getConfig()->shouldUrlBeSecure($request->getPathInfo())
+        );
         if (!$baseUrl) {
             return;
         }
 
-        $redirectCode = 302;
-        if (Mage::getStoreConfig('web/url/redirect_to_base') == 301) {
-            $redirectCode = 301;
-        }
-
-        $uri  = @parse_url($baseUrl);
-        $host = isset($uri['host']) ? $uri['host'] : '';
-        $path = isset($uri['path']) ? $uri['path'] : '';
-
+        $uri = @parse_url($baseUrl);
         $requestUri = $request->getRequestUri() ? $request->getRequestUri() : '/';
-        if ($host && $host != $request->getHttpHost() || $path && strpos($requestUri, $path) === false) {
+        if (isset($uri['scheme']) && $uri['scheme'] != $request->getScheme()
+            || isset($uri['host']) && $uri['host'] != $request->getHttpHost()
+            || isset($uri['path']) && strpos($requestUri, $uri['path']) === false
+        ) {
             Mage::app()->getFrontController()->getResponse()
                 ->setRedirect($baseUrl, $redirectCode)
                 ->sendResponse();
diff --git app/code/core/Mage/Core/Controller/Varien/Router/Standard.php app/code/core/Mage/Core/Controller/Varien/Router/Standard.php
index 9bad469..cdc4871 100644
--- app/code/core/Mage/Core/Controller/Varien/Router/Standard.php
+++ app/code/core/Mage/Core/Controller/Varien/Router/Standard.php
@@ -426,7 +426,7 @@ class Mage_Core_Controller_Varien_Router_Standard extends Mage_Core_Controller_V
                 $p[2] = trim((string)$action);
             }
         }
-#echo "<pre>".print_r($p,1)."</pre>";
+
         return $p;
     }
 
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
diff --git app/code/core/Mage/Core/Model/Session.php app/code/core/Mage/Core/Model/Session.php
index aa6b9d5..31e51a6 100644
--- app/code/core/Mage/Core/Model/Session.php
+++ app/code/core/Mage/Core/Model/Session.php
@@ -30,6 +30,9 @@
  *
  * @todo extend from Mage_Core_Model_Session_Abstract
  *
+ * @method null|bool getCookieShouldBeReceived()
+ * @method Mage_Core_Model_Session setCookieShouldBeReceived(bool $flag)
+ * @method Mage_Core_Model_Session unsCookieShouldBeReceived()
  */
 class Mage_Core_Model_Session extends Mage_Core_Model_Session_Abstract
 {
diff --git app/code/core/Mage/Core/Model/Url.php app/code/core/Mage/Core/Model/Url.php
index 41cef58..68bf4ee 100644
--- app/code/core/Mage/Core/Model/Url.php
+++ app/code/core/Mage/Core/Model/Url.php
@@ -1054,6 +1054,38 @@ class Mage_Core_Model_Url extends Varien_Object
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
index fe8e964..9294ff3 100644
--- app/code/core/Mage/Core/etc/config.xml
+++ app/code/core/Mage/Core/etc/config.xml
@@ -261,6 +261,9 @@
             </js>
         </dev>
         <system>
+            <csrf>
+                <use_form_key>1</use_form_key>
+            </csrf>
             <smtp>
                 <disable>0</disable>
                 <host>localhost</host>
diff --git app/code/core/Mage/Core/etc/system.xml app/code/core/Mage/Core/etc/system.xml
index bd580eb..3fc75a4 100644
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
@@ -760,6 +763,25 @@
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
index 81e981f..0c73b2e 100644
--- app/code/core/Mage/Customer/Helper/Data.php
+++ app/code/core/Mage/Customer/Helper/Data.php
@@ -40,6 +40,11 @@ class Mage_Customer_Helper_Data extends Mage_Core_Helper_Abstract
     const REFERER_QUERY_PARAM_NAME = 'referer';
 
     /**
+     * Route for customer account login page
+     */
+    const ROUTE_ACCOUNT_LOGIN = 'customer/account/login';
+
+    /**
      * Config name for Redirect Customer to Account Dashboard after Logging in setting
      */
     const XML_PATH_CUSTOMER_STARTUP_REDIRECT_TO_DASHBOARD = 'customer/startup/redirect_dashboard';
@@ -96,7 +101,7 @@ class Mage_Customer_Helper_Data extends Mage_Core_Helper_Abstract
     }
 
     /**
-     * Retrieve current (loggined) customer object
+     * Retrieve current (logged in) customer object
      *
      * @return Mage_Customer_Model_Customer
      */
@@ -136,21 +141,32 @@ class Mage_Customer_Helper_Data extends Mage_Core_Helper_Abstract
      */
     public function getLoginUrl()
     {
+        return $this->_getUrl(self::ROUTE_ACCOUNT_LOGIN, $this->getLoginUrlParams());
+    }
+
+    /**
+     * Retrieve parameters of customer login url
+     *
+     * @return array
+     */
+    public function getLoginUrlParams()
+    {
         $params = array();
 
         $referer = $this->_getRequest()->getParam(self::REFERER_QUERY_PARAM_NAME);
 
-        if (!$referer && !Mage::getStoreConfigFlag(self::XML_PATH_CUSTOMER_STARTUP_REDIRECT_TO_DASHBOARD)) {
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
+
         if ($referer) {
             $params = array(self::REFERER_QUERY_PARAM_NAME => $referer);
         }
 
-        return $this->_getUrl('customer/account/login', $params);
+        return $params;
     }
 
     /**
diff --git app/code/core/Mage/Customer/Model/Session.php app/code/core/Mage/Customer/Model/Session.php
index b3998bc..f82da92 100644
--- app/code/core/Mage/Customer/Model/Session.php
+++ app/code/core/Mage/Customer/Model/Session.php
@@ -86,9 +86,7 @@ class Mage_Customer_Model_Session extends Mage_Core_Model_Session_Abstract
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
@@ -102,7 +100,7 @@ class Mage_Customer_Model_Session extends Mage_Core_Model_Session_Abstract
     }
 
     /**
-     * Retrieve costomer model object
+     * Retrieve customer model object
      *
      * @return Mage_Customer_Model_Customer
      */
@@ -170,11 +168,14 @@ class Mage_Customer_Model_Session extends Mage_Core_Model_Session_Abstract
         if ($this->getData('customer_group_id')) {
             return $this->getData('customer_group_id');
         }
-        return ($this->isLoggedIn()) ? $this->getCustomer()->getGroupId() : Mage_Customer_Model_Group::NOT_LOGGED_IN_ID;
+        if ($this->isLoggedIn() && $this->getCustomer()) {
+            return $this->getCustomer()->getGroupId();
+        }
+        return Mage_Customer_Model_Group::NOT_LOGGED_IN_ID;
     }
 
     /**
-     * Checking custommer loggin status
+     * Checking customer login status
      *
      * @return bool
      */
@@ -221,6 +222,8 @@ class Mage_Customer_Model_Session extends Mage_Core_Model_Session_Abstract
     public function setCustomerAsLoggedIn($customer)
     {
         $this->setCustomer($customer);
+        $this->renewSession();
+        Mage::getSingleton('core/session')->renewFormKey();
         Mage::dispatchEvent('customer_login', array('customer'=>$customer));
         return $this;
     }
@@ -250,8 +253,7 @@ class Mage_Customer_Model_Session extends Mage_Core_Model_Session_Abstract
     {
         if ($this->isLoggedIn()) {
             Mage::dispatchEvent('customer_logout', array('customer' => $this->getCustomer()) );
-            $this->setId(null);
-            $this->getCookie()->delete($this->getSessionName());
+            $this->_logout();
         }
         return $this;
     }
@@ -260,19 +262,25 @@ class Mage_Customer_Model_Session extends Mage_Core_Model_Session_Abstract
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
     }
 
     /**
@@ -286,10 +294,26 @@ class Mage_Customer_Model_Session extends Mage_Core_Model_Session_Abstract
     {
         $url = Mage::helper('core/url')
             ->removeRequestParam($url, Mage::getSingleton('core/session')->getSessionIdQueryParam());
+        // Add correct session ID to URL if needed
+        $url = Mage::getModel('core/url')->getRebuiltUrl($url);
         return $this->setData($key, $url);
     }
 
     /**
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
      * Set Before auth url
      *
      * @param string $url
@@ -310,4 +334,17 @@ class Mage_Customer_Model_Session extends Mage_Core_Model_Session_Abstract
     {
         return $this->_setAuthUrl('after_auth_url', $url);
     }
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
+    }
 }
diff --git app/code/core/Mage/Dataflow/Model/Convert/Adapter/Zend/Cache.php app/code/core/Mage/Dataflow/Model/Convert/Adapter/Zend/Cache.php
index 066f3ba..35888d3 100644
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
index e266f65..652c646 100644
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
index b8ec2eb..d0e6e6c 100644
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
index f93732d..8d84473 100644
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
 
diff --git app/code/core/Mage/ImportExport/Model/Import/Uploader.php app/code/core/Mage/ImportExport/Model/Import/Uploader.php
index 0dd27de..d789eb1 100644
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
index 910c0ec..2a5b6c0 100644
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
index b45ae6c..b54fce0 100644
--- app/code/core/Mage/Widget/Model/Widget/Instance.php
+++ app/code/core/Mage/Widget/Model/Widget/Instance.php
@@ -340,7 +340,11 @@ class Mage_Widget_Model_Widget_Instance extends Mage_Core_Model_Abstract
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
index 83f221d..bd3eb91 100644
--- app/code/core/Mage/XmlConnect/Helper/Image.php
+++ app/code/core/Mage/XmlConnect/Helper/Image.php
@@ -92,6 +92,11 @@ class Mage_XmlConnect_Helper_Image extends Mage_Core_Helper_Abstract
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
index 437ad75..4535935 100644
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
index 0000000..c68a710
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
+ * @package     Mage_Admin
+ * @copyright   Copyright (c) 2011 Magento Inc. (http://www.magentocommerce.com)
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
index 0000000..4dea98a
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
+ * @package     Mage_Admin
+ * @copyright   Copyright (c) 2011 Magento Inc. (http://www.magentocommerce.com)
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
index 8f8b5ba..312a707 100644
--- app/design/adminhtml/default/default/template/page/head.phtml
+++ app/design/adminhtml/default/default/template/page/head.phtml
@@ -10,7 +10,7 @@
     var BLANK_URL = '<?php echo $this->getJsUrl() ?>blank.html';
     var BLANK_IMG = '<?php echo $this->getJsUrl() ?>spacer.gif';
     var BASE_URL = '<?php echo $this->getUrl('*') ?>';
-    var SKIN_URL = '<?php echo $this->getSkinUrl() ?>';
+    var SKIN_URL = '<?php echo $this->jsQuoteEscape($this->getSkinUrl()) ?>';
     var FORM_KEY = '<?php echo $this->getFormKey() ?>';
 </script>
 
diff --git app/design/frontend/base/default/template/checkout/cart/shipping.phtml app/design/frontend/base/default/template/checkout/cart/shipping.phtml
index a85bf2f..13a7efc 100644
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
index d76843c..5d248ee 100644
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
index 287c1c8..e5a77d9 100644
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
index 3395836..f04f147 100644
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
index 3c738ab..3013455 100644
--- app/design/frontend/base/default/template/checkout/onepage/payment.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/payment.phtml
@@ -35,6 +35,7 @@
 <form action="" id="co-payment-form">
     <fieldset>
         <?php echo $this->getChildHtml('methods') ?>
+        <?php echo $this->getBlockHtml('formkey') ?>
     </fieldset>
 </form>
 <div class="tool-tip" id="payment-tool-tip" style="display:none;">
diff --git app/design/frontend/base/default/template/checkout/onepage/shipping.phtml app/design/frontend/base/default/template/checkout/onepage/shipping.phtml
index 0d61013..65137c0 100644
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
index 036bbba..e273c59 100644
--- app/design/frontend/base/default/template/checkout/onepage/shipping_method.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/shipping_method.phtml
@@ -43,4 +43,5 @@
             <img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="<?php echo $this->__('Loading next step...') ?>" title="<?php echo $this->__('Loading next step...') ?>" class="v-middle" /> <?php echo $this->__('Loading next step...') ?>
         </span>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </form>
diff --git app/design/frontend/base/default/template/persistent/checkout/onepage/billing.phtml app/design/frontend/base/default/template/persistent/checkout/onepage/billing.phtml
index 1f82be3..1a44adc 100644
--- app/design/frontend/base/default/template/persistent/checkout/onepage/billing.phtml
+++ app/design/frontend/base/default/template/persistent/checkout/onepage/billing.phtml
@@ -188,6 +188,7 @@
             <img src="<?php echo $this->getSkinUrl('images/opc-ajax-loader.gif') ?>" alt="<?php echo $this->__('Loading next step...') ?>" title="<?php echo $this->__('Loading next step...') ?>" class="v-middle" /> <?php echo $this->__('Loading next step...') ?>
         </span>
     </div>
+    <?php echo $this->getBlockHtml('formkey') ?>
 </fieldset>
 </form>
 <script type="text/javascript">
diff --git app/design/frontend/enterprise/default/template/checkout/cart/shipping.phtml app/design/frontend/enterprise/default/template/checkout/cart/shipping.phtml
index af24414..fe3c66f 100644
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
index 73c7276..caf978d 100644
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
index b0abbd2..41210ce 100644
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
index a4e6dbd..8f96e09 100644
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
index f3c16be..6776db3 100644
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
index becc3e8..8c156cf 100644
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
index 9f330cb..47dcfa2 100644
--- app/design/frontend/enterprise/default/template/customerbalance/checkout/onepage/payment/additional.phtml
+++ app/design/frontend/enterprise/default/template/customerbalance/checkout/onepage/payment/additional.phtml
@@ -92,7 +92,7 @@
         } else {
             var elements = Form.getElements(this.form);
             for (var i=0; i<elements.length; i++) {
-                if (elements[i].name == 'payment[method]') {
+                if (elements[i].name == 'payment[method]' || elements[i].name == 'form_key') {
                     elements[i].disabled = false;
                 }
             }
diff --git app/design/frontend/enterprise/default/template/giftcardaccount/multishipping/payment.phtml app/design/frontend/enterprise/default/template/giftcardaccount/multishipping/payment.phtml
index 3787a93..0eb5eda 100644
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
index 74a12be..9857588 100644
--- app/design/frontend/enterprise/default/template/giftcardaccount/onepage/payment/scripts.phtml
+++ app/design/frontend/enterprise/default/template/giftcardaccount/onepage/payment/scripts.phtml
@@ -34,6 +34,7 @@ function enablePaymentMethods(free) {
             if (elements[i].name == 'payment[method]'
                 || elements[i].name == 'payment[use_customer_balance]'
                 || elements[i].name == 'payment[use_reward_points]'
+                || elements[i].name == 'form_key'
             ) {
                 if ((free && elements[i].value == 'free') || (!free && elements[i].value != 'free')) {
                     $((elements[i]).parentNode).show();
diff --git app/design/frontend/enterprise/default/template/invitation/form.phtml app/design/frontend/enterprise/default/template/invitation/form.phtml
index 3d540c2..9c54887 100644
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
diff --git app/design/frontend/enterprise/default/template/persistent/checkout/onepage/billing.phtml app/design/frontend/enterprise/default/template/persistent/checkout/onepage/billing.phtml
index 03787f0..4302fda 100644
--- app/design/frontend/enterprise/default/template/persistent/checkout/onepage/billing.phtml
+++ app/design/frontend/enterprise/default/template/persistent/checkout/onepage/billing.phtml
@@ -214,6 +214,7 @@
     </span>
 </div>
 <p class="required"><?php echo $this->__('* Required Fields') ?></p>
+<?php echo $this->getBlockHtml('formkey') ?>
 </form>
 <script type="text/javascript">
 //<![CDATA[
diff --git app/etc/config.xml app/etc/config.xml
index a623240..75bb34b 100644
--- app/etc/config.xml
+++ app/etc/config.xml
@@ -140,6 +140,11 @@
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
diff --git app/locale/en_US/Enterprise_Invitation.csv app/locale/en_US/Enterprise_Invitation.csv
index c56a084..2b31b7f 100644
--- app/locale/en_US/Enterprise_Invitation.csv
+++ app/locale/en_US/Enterprise_Invitation.csv
@@ -120,3 +120,5 @@
 "You cannot send more invitations","You cannot send more invitations"
 "Your invitation is not valid. Please contact us at %s.","Your invitation is not valid. Please contact us at %s."
 "Your invitation is not valid. Please create an account.","Your invitation is not valid. Please create an account."
+"Invitations limit exceeded. Please try again later.","Invitations limit exceeded. Please try again later."
+"Minimum Interval between invites(minutes)","Minimum Interval between invites(minutes)"
diff --git app/locale/en_US/Mage_Adminhtml.csv app/locale/en_US/Mage_Adminhtml.csv
index 25d1157e..6993433 100644
--- app/locale/en_US/Mage_Adminhtml.csv
+++ app/locale/en_US/Mage_Adminhtml.csv
@@ -1115,3 +1115,5 @@
 "to","to"
 "website(%s) scope","website(%s) scope"
 "{{base_url}} is not recommended to use in a production environment to declare the Base Unsecure URL / Base Secure URL. It is highly recommended to change this value in your Magento <a href=""%s"">configuration</a>.","{{base_url}} is not recommended to use in a production environment to declare the Base Unsecure URL / Base Secure URL. It is highly recommended to change this value in your Magento <a href=""%s"">configuration</a>."
+"Symlinks are enabled. This may expose security risks. We strongly recommend to disable them.","Symlinks are enabled. This may expose security risks. We strongly recommend to disable them."
+"You did not sign in correctly or your account is temporarily disabled.","You did not sign in correctly or your account is temporarily disabled."
diff --git app/locale/en_US/Mage_Core.csv app/locale/en_US/Mage_Core.csv
index 663ea1a..258a5f5 100644
--- app/locale/en_US/Mage_Core.csv
+++ app/locale/en_US/Mage_Core.csv
@@ -375,3 +375,4 @@
 "Your order cannot be completed at this time as there is no shipping methods available for it. Please make necessary changes in your shipping address.","Your order cannot be completed at this time as there is no shipping methods available for it. Please make necessary changes in your shipping address."
 "Your session has been expired, you will be relogged in now.","Your session has been expired, you will be relogged in now."
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
diff --git downloader/Maged/Connect.php downloader/Maged/Connect.php
index 9c61a3c..3fff234 100644
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
      * Run Mage_Connect_Command with html output console style
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
index 5652e8f..5e162ef 100755
--- downloader/Maged/Controller.php
+++ downloader/Maged/Controller.php
@@ -405,7 +405,7 @@ final class Maged_Controller
      */
     public function cleanCacheAction()
     {
-        $result = $this->cleanCache();
+        $result = $this->cleanCache(true);
         echo json_encode($result);
     }
 
@@ -904,25 +904,36 @@ final class Maged_Controller
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
index cfaf598..84fc5fe 100644
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
      */
     public function authenticate()
@@ -234,4 +248,24 @@ class Maged_Model_Session extends Maged_Model
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
index bc64d67..13a20f0 100644
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
index 97fb186..05de01e 100644
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
index b84f793..99bab85 100644
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
