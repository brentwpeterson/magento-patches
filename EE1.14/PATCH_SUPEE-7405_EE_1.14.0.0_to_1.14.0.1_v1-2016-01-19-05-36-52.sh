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


SUPEE-7405-EE-1-14-0-1 | EE_1.14.0.1 | v1 | 549e64a4236888f2b3ff6187d8351cef44e18d9f | Tue Jan 19 14:33:03 2016 +0200 | e994deb6dc..549e64a423

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Enterprise/Checkout/Block/Adminhtml/Manage/Form/Coupon.php app/code/core/Enterprise/Checkout/Block/Adminhtml/Manage/Form/Coupon.php
index 4460264..d2e11fb 100644
--- app/code/core/Enterprise/Checkout/Block/Adminhtml/Manage/Form/Coupon.php
+++ app/code/core/Enterprise/Checkout/Block/Adminhtml/Manage/Form/Coupon.php
@@ -40,7 +40,7 @@ class Enterprise_Checkout_Block_Adminhtml_Manage_Form_Coupon extends Mage_Adminh
      */
     public function getCouponCode()
     {
-        return $this->_getQuote()->getCouponCode();
+        return $this->escapeHtml($this->_getQuote()->getCouponCode());
     }
 
     /**
diff --git app/code/core/Enterprise/PageCache/etc/config.xml app/code/core/Enterprise/PageCache/etc/config.xml
index 9896aa0..3f48cc9 100644
--- app/code/core/Enterprise/PageCache/etc/config.xml
+++ app/code/core/Enterprise/PageCache/etc/config.xml
@@ -524,14 +524,14 @@
                     </enterprise_pagecache_compare_list_change>
                 </observers>
             </customer_login>
-            <controller_action_postdispatch_customer_account_logoutSuccess>
+            <controller_action_postdispatch_customer_account_logoutsuccess>
                 <observers>
                     <enterprise_pagecache>
                         <class>enterprise_pagecache/observer</class>
                         <method>customerLogout</method>
                     </enterprise_pagecache>
                 </observers>
-            </controller_action_postdispatch_customer_account_logoutSuccess>
+            </controller_action_postdispatch_customer_account_logoutsuccess>
             <sales_quote_save_after>
                 <observers>
                     <enterprise_pagecache>
diff --git app/code/core/Enterprise/Pbridge/etc/config.xml app/code/core/Enterprise/Pbridge/etc/config.xml
index ce08d98..028520e 100644
--- app/code/core/Enterprise/Pbridge/etc/config.xml
+++ app/code/core/Enterprise/Pbridge/etc/config.xml
@@ -112,14 +112,14 @@
                     </pbridge_save_order_after_submit>
                 </observers>
             </checkout_submit_all_after>
-            <controller_action_postdispatch_checkout_onepage_saveOrder>
+            <controller_action_postdispatch_checkout_onepage_saveorder>
                 <observers>
                     <pbridge_save_order_onepage>
                         <class>enterprise_pbridge/observer</class>
                         <method>setResponseAfterSaveOrder</method>
                     </pbridge_save_order_onepage>
                 </observers>
-            </controller_action_postdispatch_checkout_onepage_saveOrder>
+            </controller_action_postdispatch_checkout_onepage_saveorder>
         </events>
     </frontend>
     <adminhtml>
diff --git app/code/core/Enterprise/Pci/Model/Observer.php app/code/core/Enterprise/Pci/Model/Observer.php
index 3d08d8b..0725df2 100644
--- app/code/core/Enterprise/Pci/Model/Observer.php
+++ app/code/core/Enterprise/Pci/Model/Observer.php
@@ -174,16 +174,51 @@ class Enterprise_Pci_Model_Observer
     /**
      * Harden admin password change.
      *
+     * @deprecated
+     *
+     * @param Varien_Event_Observer $observer
+     */
+    public function checkAdminPasswordChange($observer)
+    {
+        $observer->getEvent()->setUser($observer->getEvent()->getObject());
+        $this->validateAdminUser($observer);
+        $errors = $observer->getEvent()->getErrors();
+        if (count($errors) != 0) {
+            foreach ($errors as $errorMessage) {
+                Mage::throwException($errorMessage);
+            }
+        }
+    }
+
+    /**
+     * Harden admin password change.
+     *
      * New password must be minimum 7 chars length and include alphanumeric characters
      * The password is compared to at least last 4 previous passwords to prevent setting them again
      *
      * @param Varien_Event_Observer $observer
-     * @throws Mage_Core_Exception
      */
-    public function checkAdminPasswordChange($observer)
+    public function validateAdminUser($observer)
     {
-        /* @var $user Mage_Admin_Model_User */
-        $user = $observer->getEvent()->getObject();
+        /** @var Varien_Event $event */
+        $event = $observer->getEvent();
+
+        /**
+         * Admin user model.
+         *
+         * @var Mage_Admin_Model_User
+         */
+        $user = $event->getUser();
+        if (is_null($event->getErrors())) {
+            $event->setErrors(new ArrayObject());
+        }
+
+        /**
+         * Errors container object.
+         * 
+         * @var ArrayObject
+         */
+        $errors = $event->getErrors();
 
         if ($user->getNewPassword()) {
             $password = $user->getNewPassword();
@@ -193,19 +228,15 @@ class Enterprise_Pci_Model_Observer
 
         if ($password && !$user->getForceNewPassword() && $user->getId()) {
             if (Mage::helper('core')->validateHash($password, $user->getOrigData('password'))) {
-                Mage::throwException(
-                    Mage::helper('enterprise_pci')->__('This password was used earlier, try another one.')
-                );
+                $errors[] = Mage::helper('enterprise_pci')->__('This password was used earlier, try another one.');
+                return;
             }
 
-            // check whether password was used before
-            $resource     = Mage::getResourceSingleton('enterprise_pci/admin_user');
-            $passwordHash = Mage::helper('core')->getHash($password, false);
+            $resource = Mage::getResourceSingleton('enterprise_pci/admin_user');
             foreach ($resource->getOldPasswords($user) as $oldPasswordHash) {
-                if ($passwordHash === $oldPasswordHash) {
-                    Mage::throwException(
-                        Mage::helper('enterprise_pci')->__('This password was used earlier, try another one.')
-                    );
+                if (Mage::helper('core')->validateHash($password, $oldPasswordHash)) {
+                    $errors[] = Mage::helper('enterprise_pci')->__('This password was used earlier, try another one.');
+                    return;
                 }
             }
         }
diff --git app/code/core/Enterprise/Pci/Model/Resource/Admin/User.php app/code/core/Enterprise/Pci/Model/Resource/Admin/User.php
index 1da60ca..7683480 100755
--- app/code/core/Enterprise/Pci/Model/Resource/Admin/User.php
+++ app/code/core/Enterprise/Pci/Model/Resource/Admin/User.php
@@ -127,7 +127,9 @@ class Enterprise_Pci_Model_Resource_Admin_User extends Mage_Admin_Model_Resource
         return $this->_getReadAdapter()->fetchCol(
             $this->_getReadAdapter()->select()
                 ->from($table, 'password_hash')
-                ->where('user_id = :user_id'),
+                ->where('user_id = :user_id')
+                ->order('password_id ' . Varien_Db_Select::SQL_DESC)
+                ->limit($retainLimit),
             array(':user_id' => $userId)
         );
     }
diff --git app/code/core/Enterprise/Pci/etc/config.xml app/code/core/Enterprise/Pci/etc/config.xml
index 27c1fc2..9680a5f 100644
--- app/code/core/Enterprise/Pci/etc/config.xml
+++ app/code/core/Enterprise/Pci/etc/config.xml
@@ -69,14 +69,14 @@
             </enterprise_pci_setup>
         </resources>
         <events>
-            <admin_user_save_before>
+            <admin_user_validate>
                 <observers>
                     <enterprise_pci>
                         <class>enterprise_pci/observer</class>
-                        <method>checkAdminPasswordChange</method>
+                        <method>validateAdminUser</method>
                     </enterprise_pci>
                 </observers>
-            </admin_user_save_before>
+            </admin_user_validate>
             <admin_user_save_after>
                 <observers>
                     <enterprise_pci>
diff --git app/code/core/Enterprise/Persistent/etc/config.xml app/code/core/Enterprise/Persistent/etc/config.xml
index e4a1801..8dcc578 100644
--- app/code/core/Enterprise/Persistent/etc/config.xml
+++ app/code/core/Enterprise/Persistent/etc/config.xml
@@ -192,14 +192,14 @@
                     </enterprise_persistent>
                 </observers>
             </controller_action_predispatch_wishlist_index_update>
-            <controller_action_predispatch_wishlist_index_updateItemOptions>
+            <controller_action_predispatch_wishlist_index_updateitemoptions>
                 <observers>
                     <enterprise_persistent>
                         <class>enterprise_persistent/observer</class>
                         <method>emulateWishlist</method>
                     </enterprise_persistent>
                 </observers>
-            </controller_action_predispatch_wishlist_index_updateItemOptions>
+            </controller_action_predispatch_wishlist_index_updateitemoptions>
             <controller_action_predispatch_wishlist_index_createwishlist>
                 <observers>
                     <enterprise_persistent>
@@ -264,22 +264,22 @@
                     </enterprise_persistent>
                 </observers>
             </sales_quote_save_before>
-            <controller_action_predispatch_checkout_onepage_saveMethod>
+            <controller_action_predispatch_checkout_onepage_savemethod>
                 <observers>
                     <enterprise_persistent>
                         <class>enterprise_persistent/observer</class>
                         <method>preventSettingQuotePersistent</method>
                     </enterprise_persistent>
                 </observers>
-            </controller_action_predispatch_checkout_onepage_saveMethod>
-            <controller_action_predispatch_checkout_onepage_saveOrder>
+            </controller_action_predispatch_checkout_onepage_savemethod>
+            <controller_action_predispatch_checkout_onepage_saveorder>
                 <observers>
                     <enterprise_persistent>
                         <class>enterprise_persistent/observer</class>
                         <method>preventSettingQuotePersistent</method>
                     </enterprise_persistent>
                 </observers>
-            </controller_action_predispatch_checkout_onepage_saveOrder>
+            </controller_action_predispatch_checkout_onepage_saveorder>
             <render_block>
                 <observers>
                     <enterprise_persistent>
diff --git app/code/core/Enterprise/SalesArchive/etc/config.xml app/code/core/Enterprise/SalesArchive/etc/config.xml
index 113cf33..f041a74 100644
--- app/code/core/Enterprise/SalesArchive/etc/config.xml
+++ app/code/core/Enterprise/SalesArchive/etc/config.xml
@@ -111,14 +111,14 @@
                     </enterprise_salesarchive>
                 </observers>
             </sales_order_creditmemo_resource_update_grid_records>
-            <controller_action_postdispatch_adminhtml_sales_order_shipment_massPrintShippingLabel>
+            <controller_action_postdispatch_adminhtml_sales_order_shipment_massprintshippinglabel>
                 <observers>
                     <enterprise_salesarchive>
                         <class>enterprise_salesarchive/observer</class>
                         <method>replaceSalesOrderRedirect</method>
                     </enterprise_salesarchive>
                 </observers>
-            </controller_action_postdispatch_adminhtml_sales_order_shipment_massPrintShippingLabel>
+            </controller_action_postdispatch_adminhtml_sales_order_shipment_massprintshippinglabel>
             <controller_action_postdispatch_adminhtml_sales_order_pdfshipments>
                 <observers>
                     <enterprise_salesarchive>
@@ -151,30 +151,30 @@
                     </enterprise_salesarchive>
                 </observers>
             </controller_action_postdispatch_adminhtml_sales_order_pdfdocs>
-            <controller_action_postdispatch_adminhtml_sales_order_massHold>
+            <controller_action_postdispatch_adminhtml_sales_order_masshold>
                 <observers>
                     <enterprise_salesarchive>
                         <class>enterprise_salesarchive/observer</class>
                         <method>replaceSalesOrderRedirect</method>
                     </enterprise_salesarchive>
                 </observers>
-            </controller_action_postdispatch_adminhtml_sales_order_massHold>
-            <controller_action_postdispatch_adminhtml_sales_order_massUnhold>
+            </controller_action_postdispatch_adminhtml_sales_order_masshold>
+            <controller_action_postdispatch_adminhtml_sales_order_massunhold>
                 <observers>
                     <enterprise_salesarchive>
                         <class>enterprise_salesarchive/observer</class>
                         <method>replaceSalesOrderRedirect</method>
                     </enterprise_salesarchive>
                 </observers>
-            </controller_action_postdispatch_adminhtml_sales_order_massUnhold>
-            <controller_action_postdispatch_adminhtml_sales_order_massCancel>
+            </controller_action_postdispatch_adminhtml_sales_order_massunhold>
+            <controller_action_postdispatch_adminhtml_sales_order_masscancel>
                 <observers>
                     <enterprise_salesarchive>
                         <class>enterprise_salesarchive/observer</class>
                         <method>replaceSalesOrderRedirect</method>
                     </enterprise_salesarchive>
                 </observers>
-            </controller_action_postdispatch_adminhtml_sales_order_massCancel>
+            </controller_action_postdispatch_adminhtml_sales_order_masscancel>
         </events>
     </global>
     <admin>
diff --git app/code/core/Enterprise/WebsiteRestriction/etc/config.xml app/code/core/Enterprise/WebsiteRestriction/etc/config.xml
index 646e6fa..0cc997c 100644
--- app/code/core/Enterprise/WebsiteRestriction/etc/config.xml
+++ app/code/core/Enterprise/WebsiteRestriction/etc/config.xml
@@ -106,6 +106,7 @@
                         <customer_account_confirmation/>
                         <customer_account_resetpassword/>
                         <customer_account_resetpasswordpost/>
+                        <customer_account_changeforgotten/>
                         <core_index_noCookies/>
                         <paypal_ipn_standard/>
                         <paypal_ipn_express/>
diff --git app/code/core/Mage/Admin/Model/Observer.php app/code/core/Mage/Admin/Model/Observer.php
index 0b6f4b4..819ccad 100644
--- app/code/core/Mage/Admin/Model/Observer.php
+++ app/code/core/Mage/Admin/Model/Observer.php
@@ -34,6 +34,7 @@
 class Mage_Admin_Model_Observer
 {
     const FLAG_NO_LOGIN = 'no-login';
+
     /**
      * Handler for controller_action_predispatch event
      *
@@ -42,16 +43,14 @@ class Mage_Admin_Model_Observer
      */
     public function actionPreDispatchAdmin($observer)
     {
-        $session = Mage::getSingleton('admin/session');
         /** @var $session Mage_Admin_Model_Session */
+        $session = Mage::getSingleton('admin/session');
 
-        /**
-         * @var $request Mage_Core_Controller_Request_Http
-         */
+        /** @var $request Mage_Core_Controller_Request_Http */
         $request = Mage::app()->getRequest();
         $user = $session->getUser();
 
-        $requestedActionName = $request->getActionName();
+        $requestedActionName = strtolower($request->getActionName());
         $openActions = array(
             'forgotpassword',
             'resetpassword',
@@ -67,11 +66,26 @@ class Mage_Admin_Model_Observer
             }
             if (!$user || !$user->getId()) {
                 if ($request->getPost('login')) {
-                    $postLogin  = $request->getPost('login');
-                    $username   = isset($postLogin['username']) ? $postLogin['username'] : '';
-                    $password   = isset($postLogin['password']) ? $postLogin['password'] : '';
-                    $session->login($username, $password, $request);
-                    $request->setPost('login', null);
+
+                    /** @var Mage_Core_Model_Session $coreSession */
+                    $coreSession = Mage::getSingleton('core/session');
+
+                    if ($coreSession->validateFormKey($request->getPost("form_key"))) {
+                        $postLogin = $request->getPost('login');
+                        $username = isset($postLogin['username']) ? $postLogin['username'] : '';
+                        $password = isset($postLogin['password']) ? $postLogin['password'] : '';
+                        $session->login($username, $password, $request);
+                        $request->setPost('login', null);
+                    } else {
+                        if ($request && !$request->getParam('messageSent')) {
+                            Mage::getSingleton('adminhtml/session')->addError(
+                                Mage::helper('adminhtml')->__('Invalid Form Key. Please refresh the page.')
+                            );
+                            $request->setParam('messageSent', true);
+                        }
+                    }
+
+                    $coreSession->renewFormKey();
                 }
                 if (!$request->getInternallyForwarded()) {
                     $request->setInternallyForwarded();
diff --git app/code/core/Mage/Admin/Model/Redirectpolicy.php app/code/core/Mage/Admin/Model/Redirectpolicy.php
index 98855ca..133127f 100644
--- app/code/core/Mage/Admin/Model/Redirectpolicy.php
+++ app/code/core/Mage/Admin/Model/Redirectpolicy.php
@@ -62,7 +62,8 @@ class Mage_Admin_Model_Redirectpolicy
         if (empty($request)) {
             return;
         }
-        $countRequiredParams = $this->_urlModel->useSecretKey() ? 1 : 0;
+        $countRequiredParams = ($this->_urlModel->useSecretKey()
+            && $request->getParam(Mage_Adminhtml_Model_Url::SECRET_KEY_PARAM_NAME)) ? 1 : 0;
         $countGetParams = count($request->getUserParams()) + count($request->getQuery());
 
         return ($countGetParams > $countRequiredParams) ?
diff --git app/code/core/Mage/Admin/Model/Resource/User.php app/code/core/Mage/Admin/Model/Resource/User.php
index a1a3819..6996192 100755
--- app/code/core/Mage/Admin/Model/Resource/User.php
+++ app/code/core/Mage/Admin/Model/Resource/User.php
@@ -177,7 +177,7 @@ class Mage_Admin_Model_Resource_User extends Mage_Core_Model_Resource_Db_Abstrac
      */
     protected function _afterSave(Mage_Core_Model_Abstract $user)
     {
-        $user->setExtra(unserialize($user->getExtra()));
+        $this->_unserializeExtraData($user);
         return $this;
     }
 
@@ -189,10 +189,7 @@ class Mage_Admin_Model_Resource_User extends Mage_Core_Model_Resource_Db_Abstrac
      */
     protected function _afterLoad(Mage_Core_Model_Abstract $user)
     {
-        if (is_string($user->getExtra())) {
-            $user->setExtra(unserialize($user->getExtra()));
-        }
-        return parent::_afterLoad($user);
+        return parent::_afterLoad($this->_unserializeExtraData($user));
     }
 
     /**
@@ -459,4 +456,21 @@ class Mage_Admin_Model_Resource_User extends Mage_Core_Model_Resource_Db_Abstrac
 
         return $this;
     }
+
+    /**
+     * Unserializes user extra data
+     *
+     * @param Mage_Core_Model_Abstract $user
+     * @return Mage_Core_Model_Abstract
+     */
+    protected function _unserializeExtraData(Mage_Core_Model_Abstract $user)
+    {
+        try {
+            $unsterilizedData = Mage::helper('core/unserializeArray')->unserialize($user->getExtra());
+            $user->setExtra($unsterilizedData);
+        } catch (Exception $e) {
+            $user->setExtra(false);
+        }
+        return $user;
+    }
 }
diff --git app/code/core/Mage/Admin/Model/User.php app/code/core/Mage/Admin/Model/User.php
index 53b0411..d42da0e 100644
--- app/code/core/Mage/Admin/Model/User.php
+++ app/code/core/Mage/Admin/Model/User.php
@@ -519,7 +519,7 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
      */
     public function validate()
     {
-        $errors = array();
+        $errors = new ArrayObject();
 
         if (!Zend_Validate::is($this->getUsername(), 'NotEmpty')) {
             $errors[] = Mage::helper('adminhtml')->__('User Name is required field.');
@@ -551,16 +551,21 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
             if ($this->hasPasswordConfirmation() && $this->getNewPassword() != $this->getPasswordConfirmation()) {
                 $errors[] = Mage::helper('adminhtml')->__('Password confirmation must be same as password.');
             }
+
+            Mage::dispatchEvent('admin_user_validate', array(
+                'user' => $this,
+                'errors' => $errors,
+            ));
         }
 
         if ($this->userExists()) {
             $errors[] = Mage::helper('adminhtml')->__('A user with the same user name or email aleady exists.');
         }
 
-        if (empty($errors)) {
+        if (count($errors) === 0) {
             return true;
         }
-        return $errors;
+        return (array)$errors;
     }
 
     /**
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/View/Tab/History.php app/code/core/Mage/Adminhtml/Block/Sales/Order/View/Tab/History.php
index 0601295..bc64724 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/View/Tab/History.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/View/Tab/History.php
@@ -187,8 +187,14 @@ class Mage_Adminhtml_Block_Sales_Order_View_Tab_History
      */
     public function getItemComment(array $item)
     {
-        $allowedTags = array('b','br','strong','i','u');
-        return (isset($item['comment']) ? $this->escapeHtml($item['comment'], $allowedTags) : '');
+        $strItemComment = '';
+        if (isset($item['comment'])) {
+            $allowedTags = array('b', 'br', 'strong', 'i', 'u', 'a');
+            /** @var Mage_Adminhtml_Helper_Sales $salesHelper */
+            $salesHelper = Mage::helper('adminhtml/sales');
+            $strItemComment = $salesHelper->escapeHtmlWithLinks($item['comment'], $allowedTags);
+        }
+        return $strItemComment;
     }
 
     /**
diff --git app/code/core/Mage/Adminhtml/Block/Widget/Grid.php app/code/core/Mage/Adminhtml/Block/Widget/Grid.php
index 4d4d887..f78203b 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Grid.php
@@ -978,7 +978,10 @@ class Mage_Adminhtml_Block_Widget_Grid extends Mage_Adminhtml_Block_Widget
                 $row[] = $column->getRowFieldExport($item);
             }
         }
-        $adapter->streamWriteCsv($row);
+
+        $adapter->streamWriteCsv(
+            Mage::helper("core")->getEscapedCSVData($row)
+        );
     }
 
     /**
@@ -1008,7 +1011,9 @@ class Mage_Adminhtml_Block_Widget_Grid extends Mage_Adminhtml_Block_Widget
         $this->_exportIterateCollection('_exportCsvItem', array($io));
 
         if ($this->getCountTotals()) {
-            $io->streamWriteCsv($this->_getExportTotals());
+            $io->streamWriteCsv(
+                Mage::helper("core")->getEscapedCSVData($this->_getExportTotals())
+            );
         }
 
         $io->streamUnlock();
@@ -1674,5 +1679,4 @@ class Mage_Adminhtml_Block_Widget_Grid extends Mage_Adminhtml_Block_Widget
         $res = parent::getRowUrl($item);
         return ($res ? $res : '#');
     }
-
 }
diff --git app/code/core/Mage/Adminhtml/Helper/Catalog/Product/Edit/Action/Attribute.php app/code/core/Mage/Adminhtml/Helper/Catalog/Product/Edit/Action/Attribute.php
index 47bad53..3f890c5 100644
--- app/code/core/Mage/Adminhtml/Helper/Catalog/Product/Edit/Action/Attribute.php
+++ app/code/core/Mage/Adminhtml/Helper/Catalog/Product/Edit/Action/Attribute.php
@@ -87,7 +87,7 @@ class Mage_Adminhtml_Helper_Catalog_Product_Edit_Action_Attribute extends Mage_C
     {
         $session = Mage::getSingleton('adminhtml/session');
 
-        if ($this->_getRequest()->isPost() && $this->_getRequest()->getActionName() == 'edit') {
+        if ($this->_getRequest()->isPost() && strtolower($this->_getRequest()->getActionName()) == 'edit') {
             $session->setProductIds($this->_getRequest()->getParam('product', null));
         }
 
diff --git app/code/core/Mage/Adminhtml/Helper/Sales.php app/code/core/Mage/Adminhtml/Helper/Sales.php
index 45dcae5..ac170e0 100644
--- app/code/core/Mage/Adminhtml/Helper/Sales.php
+++ app/code/core/Mage/Adminhtml/Helper/Sales.php
@@ -110,4 +110,47 @@ class Mage_Adminhtml_Helper_Sales extends Mage_Core_Helper_Abstract
         }
         return $collection;
     }
+
+    /**
+     * Escape string preserving links
+     *
+     * @param array|string $data
+     * @param null|array $allowedTags
+     * @return string
+     */
+    public function escapeHtmlWithLinks($data, $allowedTags = null)
+    {
+        if (!empty($data) && is_array($allowedTags) && in_array('a', $allowedTags)) {
+            $links = [];
+            $i = 1;
+            $regexp = "/<a\s[^>]*href\s*?=\s*?([\"\']??)([^\" >]*?)\\1[^>]*>(.*)<\/a>/siU";
+            while (preg_match($regexp, $data, $matches)) {
+                //Revert the sprintf escaping
+                $url = str_replace('%%', '%', $matches[2]);
+                $text = str_replace('%%', '%', $matches[3]);
+                //Check for an valid url
+                if ($url) {
+                    $urlScheme = strtolower(parse_url($url, PHP_URL_SCHEME));
+                    if ($urlScheme !== 'http' && $urlScheme !== 'https') {
+                        $url = null;
+                    }
+                }
+                //Use hash tag as fallback
+                if (!$url) {
+                    $url = '#';
+                }
+                //Recreate a minimalistic secure a tag
+                $links[] = sprintf(
+                    '<a href="%s">%s</a>',
+                    htmlspecialchars($url, ENT_QUOTES, 'UTF-8', false),
+                    parent::escapeHtml($text)
+                );
+                $data = str_replace($matches[0], '%' . $i . '$s', $data);
+                ++$i;
+            }
+            $data = parent::escapeHtml($data, $allowedTags);
+            return vsprintf($data, $links);
+        }
+        return parent::escapeHtml($data, $allowedTags);
+    }
 }
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/File.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/File.php
index c58831a..6a7efd1 100644
--- app/code/core/Mage/Adminhtml/Model/System/Config/Backend/File.php
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/File.php
@@ -48,7 +48,7 @@ class Mage_Adminhtml_Model_System_Config_Backend_File extends Mage_Core_Model_Co
     protected function _beforeSave()
     {
         $value = $this->getValue();
-        if ($_FILES['groups']['tmp_name'][$this->getGroupId()]['fields'][$this->getField()]['value']){
+        if ($_FILES['groups']['tmp_name'][$this->getGroupId()]['fields'][$this->getField()]['value']) {
 
             $uploadDir = $this->_getUploadDir();
 
@@ -61,7 +61,7 @@ class Mage_Adminhtml_Model_System_Config_Backend_File extends Mage_Core_Model_Co
                 $uploader = new Mage_Core_Model_File_Uploader($file);
                 $uploader->setAllowedExtensions($this->_getAllowedExtensions());
                 $uploader->setAllowRenameFiles(true);
-                $uploader->addValidateCallback('size', $this, 'validateMaxSize');
+                $this->addValidators( $uploader );
                 $result = $uploader->save($uploadDir);
 
             } catch (Exception $e) {
@@ -202,4 +202,14 @@ class Mage_Adminhtml_Model_System_Config_Backend_File extends Mage_Core_Model_Co
     {
         return array();
     }
+
+    /**
+     * Add validators for uploading
+     *
+     * @param Mage_Core_Model_File_Uploader $uploader
+     */
+    protected function addValidators(Mage_Core_Model_File_Uploader $uploader)
+    {
+        $uploader->addValidateCallback('size', $this, 'validateMaxSize');
+    }
 }
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Image.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Image.php
index 7bb4e34..68e80c1 100644
--- app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Image.php
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Image.php
@@ -43,4 +43,17 @@ class Mage_Adminhtml_Model_System_Config_Backend_Image extends Mage_Adminhtml_Mo
     {
         return array('jpg', 'jpeg', 'gif', 'png');
     }
+
+    /**
+     * Overwritten parent method for adding validators
+     *
+     * @param Mage_Core_Model_File_Uploader $uploader
+     */
+    protected function addValidators(Mage_Core_Model_File_Uploader $uploader)
+    {
+        parent::addValidators($uploader);
+        $validator = new Mage_Core_Model_File_Validator_Image();
+        $validator->setAllowedImageTypes($this->_getAllowedExtensions());
+        $uploader->addValidateCallback(Mage_Core_Model_File_Validator_Image::NAME, $validator, 'validate');
+    }
 }
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Image/Favicon.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Image/Favicon.php
index 8c63ce4..19eb6d3 100644
--- app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Image/Favicon.php
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Image/Favicon.php
@@ -77,7 +77,7 @@ class Mage_Adminhtml_Model_System_Config_Backend_Image_Favicon extends Mage_Admi
      */
     protected function _getAllowedExtensions()
     {
-        return array('ico', 'png', 'gif', 'jpg', 'jpeg', 'apng', 'svg');
+        return array('ico', 'png', 'gif', 'jpg', 'jpeg', 'apng');
     }
 
     /**
@@ -86,7 +86,8 @@ class Mage_Adminhtml_Model_System_Config_Backend_Image_Favicon extends Mage_Admi
      * @param  $token
      * @return string
      */
-    protected function _getUploadRoot($token) {
+    protected function _getUploadRoot($token)
+    {
         return Mage::getBaseDir($token);
     }
 }
diff --git app/code/core/Mage/Adminhtml/controllers/IndexController.php app/code/core/Mage/Adminhtml/controllers/IndexController.php
index 60a4fb1..69b821a 100644
--- app/code/core/Mage/Adminhtml/controllers/IndexController.php
+++ app/code/core/Mage/Adminhtml/controllers/IndexController.php
@@ -224,38 +224,51 @@ class Mage_Adminhtml_IndexController extends Mage_Adminhtml_Controller_Action
      */
     public function forgotpasswordAction()
     {
-        $email = (string) $this->getRequest()->getParam('email');
         $params = $this->getRequest()->getParams();
 
-        if (!empty($email) && !empty($params)) {
-            // Validate received data to be an email address
-            if (Zend_Validate::is($email, 'EmailAddress')) {
-                $collection = Mage::getResourceModel('admin/user_collection');
-                /** @var $collection Mage_Admin_Model_Resource_User_Collection */
-                $collection->addFieldToFilter('email', $email);
-                $collection->load(false);
-
-                if ($collection->getSize() > 0) {
-                    foreach ($collection as $item) {
-                        $user = Mage::getModel('admin/user')->load($item->getId());
-                        if ($user->getId()) {
-                            $newResetPasswordLinkToken = Mage::helper('admin')->generateResetPasswordLinkToken();
-                            $user->changeResetPasswordLinkToken($newResetPasswordLinkToken);
-                            $user->save();
-                            $user->sendPasswordResetConfirmationEmail();
+        if (!(empty($params))) {
+            $email = (string)$this->getRequest()->getParam('email');
+
+            if ($this->_validateFormKey()) {
+                if (!empty($email)) {
+                    // Validate received data to be an email address
+                    if (Zend_Validate::is($email, 'EmailAddress')) {
+                        $collection = Mage::getResourceModel('admin/user_collection');
+                        /** @var $collection Mage_Admin_Model_Resource_User_Collection */
+                        $collection->addFieldToFilter('email', $email);
+                        $collection->load(false);
+
+                        if ($collection->getSize() > 0) {
+                            foreach ($collection as $item) {
+                                /** @var Mage_Admin_Model_User $user */
+                                $user = Mage::getModel('admin/user')->load($item->getId());
+                                if ($user->getId()) {
+                                    $newResetPasswordLinkToken = Mage::helper('admin')->generateResetPasswordLinkToken();
+                                    $user->changeResetPasswordLinkToken($newResetPasswordLinkToken);
+                                    $user->save();
+                                    $user->sendPasswordResetConfirmationEmail();
+                                }
+                                break;
+                            }
                         }
-                        break;
+                        $this->_getSession()
+                            ->addSuccess(
+                                $this->__(
+                                    'If there is an account associated with %s you will receive an email with a link to reset your password.',
+                                    Mage::helper('adminhtml')->escapeHtml($email)
+                                )
+                            );
+                        $this->_redirect('*/*/login');
+                        return;
+                    } else {
+                        $this->_getSession()->addError($this->__('Invalid email address.'));
                     }
+                } else {
+                    $this->_getSession()->addError($this->__('The email address is empty.'));
                 }
-                $this->_getSession()
-                    ->addSuccess(Mage::helper('adminhtml')->__('If there is an account associated with %s you will receive an email with a link to reset your password.', Mage::helper('adminhtml')->escapeHtml($email)));
-                $this->_redirect('*/*/login');
-                return;
             } else {
-                $this->_getSession()->addError($this->__('Invalid email address.'));
+                $this->_getSession()->addError($this->__('Invalid Form Key. Please refresh the page.'));
             }
-        } elseif (!empty($params)) {
-            $this->_getSession()->addError(Mage::helper('adminhtml')->__('The email address is empty.'));
         }
         $this->loadLayout();
         $this->renderLayout();
@@ -290,10 +303,10 @@ class Mage_Adminhtml_IndexController extends Mage_Adminhtml_Controller_Action
      */
     public function resetPasswordPostAction()
     {
-        $resetPasswordLinkToken = (string) $this->getRequest()->getQuery('token');
-        $userId = (int) $this->getRequest()->getQuery('id');
-        $password = (string) $this->getRequest()->getPost('password');
-        $passwordConfirmation = (string) $this->getRequest()->getPost('confirmation');
+        $resetPasswordLinkToken = (string)$this->getRequest()->getQuery('token');
+        $userId = (int)$this->getRequest()->getQuery('id');
+        $password = (string)$this->getRequest()->getPost('password');
+        $passwordConfirmation = (string)$this->getRequest()->getPost('confirmation');
 
         try {
             $this->_validateResetPasswordLinkToken($userId, $resetPasswordLinkToken);
@@ -303,6 +316,12 @@ class Mage_Adminhtml_IndexController extends Mage_Adminhtml_Controller_Action
             return;
         }
 
+        if (!$this->_validateFormKey()) {
+            $this->_getSession()->addError(Mage::helper('adminhtml')->__('Invalid Form Key. Please refresh the page.'));
+            $this->_redirect('*/*/');
+            return;
+        }
+
         $errorMessages = array();
         if (iconv_strlen($password) <= 0) {
             array_push($errorMessages, Mage::helper('adminhtml')->__('New password field cannot be empty.'));
diff --git app/code/core/Mage/Authorizenet/Helper/Admin.php app/code/core/Mage/Authorizenet/Helper/Admin.php
new file mode 100644
index 0000000..fa59caa
--- /dev/null
+++ app/code/core/Mage/Authorizenet/Helper/Admin.php
@@ -0,0 +1,77 @@
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
+ * @package     Mage_Authorizenet
+ * @copyright Copyright (c) 2006-2015 X.commerce, Inc. (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+/**
+ * Authorizenet Admin Data Helper
+ *
+ * @category   Mage
+ * @package    Mage_Authorizenet
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Authorizenet_Helper_Admin extends Mage_Authorizenet_Helper_Data
+{
+
+    /**
+     * Retrieve place order url
+     * @param array $params
+     * @return string
+     */
+    public function getSuccessOrderUrl($params)
+    {
+        $url = parent::getSuccessOrderUrl($params);
+
+        if ($params['controller_action_name'] === 'sales_order_create'
+            or $params['controller_action_name'] === 'sales_order_edit'
+        ) {
+            /** @var Mage_Sales_Model_Order $order */
+            $order = Mage::getModel('sales/order');
+            $order->loadByIncrementId($params['x_invoice_num']);
+
+            $url = $this->getAdminUrl('adminhtml/sales_order/view', array('order_id' => $order->getId()));
+        }
+
+        return $url;
+    }
+
+    /**
+     * Retrieve save order url params
+     *
+     * @param string $controller
+     * @return array
+     */
+    public function getSaveOrderUrlParams($controller)
+    {
+        $route = parent::getSaveOrderUrlParams($controller);
+
+        if ($controller === "sales_order_create" or $controller === "sales_order_edit") {
+            $route['action'] = 'save';
+            $route['controller'] = 'sales_order_create';
+            $route['module'] = 'admin';
+        }
+
+        return $route;
+    }
+}
diff --git app/code/core/Mage/Authorizenet/Helper/Data.php app/code/core/Mage/Authorizenet/Helper/Data.php
index 6c707f1..721fe2d8 100755
--- app/code/core/Mage/Authorizenet/Helper/Data.php
+++ app/code/core/Mage/Authorizenet/Helper/Data.php
@@ -72,51 +72,23 @@ class Mage_Authorizenet_Helper_Data extends Mage_Core_Helper_Abstract
     public function getSaveOrderUrlParams($controller)
     {
         $route = array();
-        switch ($controller) {
-            case 'onepage':
-                $route['action'] = 'saveOrder';
-                $route['controller'] = 'onepage';
-                $route['module'] = 'checkout';
-                break;
-
-            case 'sales_order_create':
-            case 'sales_order_edit':
-                $route['action'] = 'save';
-                $route['controller'] = 'sales_order_create';
-                $route['module'] = 'admin';
-                break;
-
-            default:
-                break;
+        if ($controller === "onepage") {
+            $route['action'] = 'saveOrder';
+            $route['controller'] = 'onepage';
+            $route['module'] = 'checkout';
         }
 
         return $route;
     }
 
     /**
-     * Retrieve redirect ifrmae url
-     *
-     * @param array params
+     * Retrieve redirect iframe url
+     * @param $params
      * @return string
      */
     public function getRedirectIframeUrl($params)
     {
-        switch ($params['controller_action_name']) {
-            case 'onepage':
-                $route = 'authorizenet/directpost_payment/redirect';
-                break;
-
-            case 'sales_order_create':
-            case 'sales_order_edit':
-                $route = 'adminhtml/authorizenet_directpost_payment/redirect';
-                break;
-
-            default:
-                $route = 'authorizenet/directpost_payment/redirect';
-                break;
-        }
-
-        return $this->_getUrl($route, $params);
+        return $this->_getUrl('authorizenet/directpost_payment/redirect', $params);
     }
 
     /**
@@ -148,25 +120,7 @@ class Mage_Authorizenet_Helper_Data extends Mage_Core_Helper_Abstract
      */
     public function getSuccessOrderUrl($params)
     {
-        $param = array();
-        switch ($params['controller_action_name']) {
-            case 'onepage':
-                $route = 'checkout/onepage/success';
-                break;
-
-            case 'sales_order_create':
-            case 'sales_order_edit':
-                $route = 'adminhtml/sales_order/view';
-                $order = Mage::getModel('sales/order')->loadByIncrementId($params['x_invoice_num']);
-                $param['order_id'] = $order->getId();
-                return $this->getAdminUrl($route, $param);
-
-            default :
-                $route = 'checkout/onepage/success';
-                break;
-        }
-
-        return $this->_getUrl($route, $param);
+        return $this->_getUrl('checkout/onepage/success', array());
     }
 
     /**
diff --git app/code/core/Mage/Authorizenet/controllers/Adminhtml/Authorizenet/Directpost/PaymentController.php app/code/core/Mage/Authorizenet/controllers/Adminhtml/Authorizenet/Directpost/PaymentController.php
index e8b5705..5575c6f 100644
--- app/code/core/Mage/Authorizenet/controllers/Adminhtml/Authorizenet/Directpost/PaymentController.php
+++ app/code/core/Mage/Authorizenet/controllers/Adminhtml/Authorizenet/Directpost/PaymentController.php
@@ -86,9 +86,9 @@ class Mage_Authorizenet_Adminhtml_Authorizenet_Directpost_PaymentController
         }
 
         if (isset($paymentParam['method'])) {
-            $saveOrderFlag = Mage::getStoreConfig('payment/'.$paymentParam['method'].'/create_order_before');
+
             $result = array();
-            $params = Mage::helper('authorizenet')->getSaveOrderUrlParams($controller);
+
             //create order partially
             $this->_getOrderCreateModel()->setPaymentData($paymentParam);
             $this->_getOrderCreateModel()->getQuote()->getPayment()->addData($paymentParam);
@@ -170,7 +170,7 @@ class Mage_Authorizenet_Adminhtml_Authorizenet_Directpost_PaymentController
             && isset($redirectParams['x_invoice_num'])
             && isset($redirectParams['controller_action_name'])
         ) {
-            $params['redirect_parent'] = Mage::helper('authorizenet')->getSuccessOrderUrl($redirectParams);
+            $params['redirect_parent'] = Mage::helper('authorizenet/admin')->getSuccessOrderUrl($redirectParams);
             $this->_getDirectPostSession()->unsetData('quote_id');
             //cancel old order
             $oldOrder = $this->_getOrderCreateModel()->getSession()->getOrder();
diff --git app/code/core/Mage/Captcha/etc/config.xml app/code/core/Mage/Captcha/etc/config.xml
index 906927e..010d9e0 100755
--- app/code/core/Mage/Captcha/etc/config.xml
+++ app/code/core/Mage/Captcha/etc/config.xml
@@ -54,14 +54,14 @@
             </captcha_resource>
         </models>
         <events>
-            <controller_action_predispatch_customer_account_loginPost>
+            <controller_action_predispatch_customer_account_loginpost>
                 <observers>
                     <captcha>
                         <class>captcha/observer</class>
                         <method>checkUserLogin</method>
                     </captcha>
                 </observers>
-            </controller_action_predispatch_customer_account_loginPost>
+            </controller_action_predispatch_customer_account_loginpost>
             <controller_action_predispatch_customer_account_forgotpasswordpost>
                 <observers>
                     <captcha>
@@ -94,7 +94,7 @@
                     </captcha>
                 </observers>
             </admin_user_authenticate_before>
-            <controller_action_predispatch_checkout_onepage_saveBilling>
+            <controller_action_predispatch_checkout_onepage_savebilling>
                 <observers>
                     <captcha_guest>
                         <class>captcha/observer</class>
@@ -105,7 +105,7 @@
                         <method>checkRegisterCheckout</method>
                     </captcha_register>
                 </observers>
-            </controller_action_predispatch_checkout_onepage_saveBilling>
+            </controller_action_predispatch_checkout_onepage_savebilling>
             <customer_customer_authenticated>
                 <observers>
                     <captcha_reset_attempt>
diff --git app/code/core/Mage/Catalog/Block/Product/View/Options/Type/Select.php app/code/core/Mage/Catalog/Block/Product/View/Options/Type/Select.php
index e159923..8b22bdc 100644
--- app/code/core/Mage/Catalog/Block/Product/View/Options/Type/Select.php
+++ app/code/core/Mage/Catalog/Block/Product/View/Options/Type/Select.php
@@ -135,7 +135,7 @@ class Mage_Catalog_Block_Product_View_Options_Type_Select
                     . '_' . $count . '" value="' . $htmlValue . '" ' . $checked . ' price="'
                     . $this->helper('core')->currencyByStore($_value->getPrice(true), $store, false) . '" />'
                     . '<span class="label"><label for="options_' . $_option->getId() . '_' . $count . '">'
-                    . $_value->getTitle() . ' ' . $priceStr . '</label></span>';
+                    . $this->escapeHtml($_value->getTitle()) . ' ' . $priceStr . '</label></span>';
                 if ($_option->getIsRequire()) {
                     $selectHtml .= '<script type="text/javascript">' . '$(\'options_' . $_option->getId() . '_'
                     . $count . '\').advaiceContainer = \'options-' . $_option->getId() . '-container\';'
diff --git app/code/core/Mage/Catalog/Model/Category/Attribute/Backend/Image.php app/code/core/Mage/Catalog/Model/Category/Attribute/Backend/Image.php
index d3c41e2..e43c9e9 100644
--- app/code/core/Mage/Catalog/Model/Category/Attribute/Backend/Image.php
+++ app/code/core/Mage/Catalog/Model/Category/Attribute/Backend/Image.php
@@ -57,6 +57,11 @@ class Mage_Catalog_Model_Category_Attribute_Backend_Image extends Mage_Eav_Model
             $uploader = new Mage_Core_Model_File_Uploader($this->getAttribute()->getName());
             $uploader->setAllowedExtensions(array('jpg','jpeg','gif','png'));
             $uploader->setAllowRenameFiles(true);
+            $uploader->addValidateCallback(
+                Mage_Core_Model_File_Validator_Image::NAME,
+                new Mage_Core_Model_File_Validator_Image(),
+                "validate"
+            );
             $result = $uploader->save($path);
 
             $object->setData($this->getAttribute()->getName(), $result['file']);
diff --git app/code/core/Mage/Catalog/Model/Resource/Product/Attribute/Backend/Image.php app/code/core/Mage/Catalog/Model/Resource/Product/Attribute/Backend/Image.php
index 1e00019..245842a 100755
--- app/code/core/Mage/Catalog/Model/Resource/Product/Attribute/Backend/Image.php
+++ app/code/core/Mage/Catalog/Model/Resource/Product/Attribute/Backend/Image.php
@@ -57,17 +57,24 @@ class Mage_Catalog_Model_Resource_Product_Attribute_Backend_Image
             $uploader->setAllowedExtensions(array('jpg', 'jpeg', 'gif', 'png'));
             $uploader->setAllowRenameFiles(true);
             $uploader->setFilesDispersion(true);
-        } catch (Exception $e){
+            $uploader->addValidateCallback(
+                Mage_Core_Model_File_Validator_Image::NAME,
+                new Mage_Core_Model_File_Validator_Image(),
+                "validate"
+            );
+            $uploader->save(Mage::getBaseDir('media') . '/catalog/product');
+
+            $fileName = $uploader->getUploadedFileName();
+            if ($fileName) {
+                $object->setData($this->getAttribute()->getName(), $fileName);
+                $this->getAttribute()->getEntity()
+                    ->saveAttribute($object, $this->getAttribute()->getName());
+            }
+
+        } catch (Exception $e) {
             return $this;
         }
-        $uploader->save(Mage::getBaseDir('media') . '/catalog/product');
 
-        $fileName = $uploader->getUploadedFileName();
-        if ($fileName) {
-            $object->setData($this->getAttribute()->getName(), $fileName);
-            $this->getAttribute()->getEntity()
-                 ->saveAttribute($object, $this->getAttribute()->getName());
-        }
         return $this;
     }
 }
diff --git app/code/core/Mage/CatalogIndex/etc/config.xml app/code/core/Mage/CatalogIndex/etc/config.xml
index 48bb9b1..703c6d0 100644
--- app/code/core/Mage/CatalogIndex/etc/config.xml
+++ app/code/core/Mage/CatalogIndex/etc/config.xml
@@ -87,169 +87,14 @@
             </catalogindex_setup>
         </resources>
         <events>
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-            
-
-
-
-
-
-
-
-
-            
-
-
-
-
-
-
-
-
-            
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
         </events>
     </global>
     <adminhtml>
         <events>
-
-
-
-
-
-
-
-
         </events>
     </adminhtml>
     <crontab>
         <jobs>
-
-
-
-
-
-
-
-
         </jobs>
     </crontab>
 </config>
diff --git app/code/core/Mage/CatalogInventory/Helper/Minsaleqty.php app/code/core/Mage/CatalogInventory/Helper/Minsaleqty.php
index 097383a..4877a0d 100644
--- app/code/core/Mage/CatalogInventory/Helper/Minsaleqty.php
+++ app/code/core/Mage/CatalogInventory/Helper/Minsaleqty.php
@@ -80,7 +80,11 @@ class Mage_CatalogInventory_Helper_Minsaleqty
                 Mage_Customer_Model_Group::CUST_GROUP_ALL => $this->_fixQty($value)
             );
         } else if (is_string($value) && !empty($value)) {
-            return unserialize($value);
+            try {
+                return Mage::helper('core/unserializeArray')->unserialize($value);
+            } catch (Exception $e) {
+                return array();
+            }
         } else {
             return array();
         }
diff --git app/code/core/Mage/Checkout/Block/Cart/Item/Renderer.php app/code/core/Mage/Checkout/Block/Cart/Item/Renderer.php
index 26800bd..adc08e2 100755
--- app/code/core/Mage/Checkout/Block/Cart/Item/Renderer.php
+++ app/code/core/Mage/Checkout/Block/Cart/Item/Renderer.php
@@ -224,6 +224,7 @@ class Mage_Checkout_Block_Cart_Item_Renderer extends Mage_Core_Block_Template
             'checkout/cart/delete',
             array(
                 'id'=>$this->getItem()->getId(),
+                'form_key' => Mage::getSingleton('core/session')->getFormKey(),
                 Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->helper('core/url')->getEncodedUrl()
             )
         );
diff --git app/code/core/Mage/Checkout/controllers/CartController.php app/code/core/Mage/Checkout/controllers/CartController.php
index b2d6032..e51851b 100644
--- app/code/core/Mage/Checkout/controllers/CartController.php
+++ app/code/core/Mage/Checkout/controllers/CartController.php
@@ -89,7 +89,7 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
         ) {
             $this->getResponse()->setRedirect($backUrl);
         } else {
-            if (($this->getRequest()->getActionName() == 'add') && !$this->getRequest()->getParam('in_cart')) {
+            if ((strtolower($this->getRequest()->getActionName()) == 'add') && !$this->getRequest()->getParam('in_cart')) {
                 $this->_getSession()->setContinueShoppingUrl($this->_getRefererUrl());
             }
             $this->_redirect('checkout/cart');
@@ -489,16 +489,21 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
      */
     public function deleteAction()
     {
-        $id = (int) $this->getRequest()->getParam('id');
-        if ($id) {
-            try {
-                $this->_getCart()->removeItem($id)
-                  ->save();
-            } catch (Exception $e) {
-                $this->_getSession()->addError($this->__('Cannot remove the item.'));
-                Mage::logException($e);
+        if ($this->_validateFormKey()) {
+            $id = (int)$this->getRequest()->getParam('id');
+            if ($id) {
+                try {
+                    $this->_getCart()->removeItem($id)
+                        ->save();
+                } catch (Exception $e) {
+                    $this->_getSession()->addError($this->__('Cannot remove the item.'));
+                    Mage::logException($e);
+                }
             }
+        } else {
+            $this->_getSession()->addError($this->__('Cannot remove the item.'));
         }
+
         $this->_redirectReferer(Mage::getUrl('*/*'));
     }
 
diff --git app/code/core/Mage/Checkout/controllers/OnepageController.php app/code/core/Mage/Checkout/controllers/OnepageController.php
index 1ad9476..f4f8c45 100644
--- app/code/core/Mage/Checkout/controllers/OnepageController.php
+++ app/code/core/Mage/Checkout/controllers/OnepageController.php
@@ -102,7 +102,7 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
             $this->_ajaxRedirectResponse();
             return true;
         }
-        $action = $this->getRequest()->getActionName();
+        $action = strtolower($this->getRequest()->getActionName());
         if (Mage::getSingleton('checkout/session')->getCartWasUpdated(true)
             && !in_array($action, array('index', 'progress'))
         ) {
diff --git app/code/core/Mage/Core/Helper/Data.php app/code/core/Mage/Core/Helper/Data.php
index 01d4e57..3cda9dc 100644
--- app/code/core/Mage/Core/Helper/Data.php
+++ app/code/core/Mage/Core/Helper/Data.php
@@ -876,4 +876,49 @@ XML;
 
         return $remainder;
     }
+
+    /**
+     * Escaping CSV-data
+     *
+     * Security enchancement for CSV data processing by Excel-like applications.
+     * @see https://bugzilla.mozilla.org/show_bug.cgi?id=1054702
+     *
+     * @param $data
+     * @return array
+     */
+    public function getEscapedCSVData(array $data)
+    {
+        if (Mage::getStoreConfigFlag(Mage_ImportExport_Model_Export_Adapter_Csv::CONFIG_ESCAPING_FLAG)) {
+            foreach ($data as $key => $value) {
+                $value = (string)$value;
+
+                $firstLetter = substr($value, 0, 1);
+                if ($firstLetter !== false and in_array($firstLetter, array("=", "+", "-"))) {
+                    $data[$key] = ' ' . $value;
+                }
+            }
+        }
+        return $data;
+    }
+
+    /**
+     * UnEscapes CSV data
+     *
+     * @param mixed $data
+     * @return mixed array
+     */
+    public function unEscapeCSVData($data)
+    {
+        if (is_array($data) and Mage::getStoreConfigFlag(Mage_ImportExport_Model_Export_Adapter_Csv::CONFIG_ESCAPING_FLAG)) {
+
+            foreach ($data as $key => $value) {
+                $value = (string)$value;
+
+                if (preg_match("/^ [=\-+]/", $value)) {
+                    $data[$key] = ltrim($value);
+                }
+            }
+        }
+        return $data;
+    }
 }
diff --git app/code/core/Mage/Core/Model/App.php app/code/core/Mage/Core/Model/App.php
index b1426b9..319de66 100644
--- app/code/core/Mage/Core/Model/App.php
+++ app/code/core/Mage/Core/Model/App.php
@@ -1270,6 +1270,7 @@ class Mage_Core_Model_App
 
     public function dispatchEvent($eventName, $args)
     {
+        $eventName = strtolower($eventName);
         foreach ($this->_events as $area=>$events) {
             if (!isset($events[$eventName])) {
                 $eventConfig = $this->getConfig()->getEventConfig($area, $eventName);
diff --git app/code/core/Mage/Core/Model/Config.php app/code/core/Mage/Core/Model/Config.php
index f4b43c6..8904597 100644
--- app/code/core/Mage/Core/Model/Config.php
+++ app/code/core/Mage/Core/Model/Config.php
@@ -956,6 +956,12 @@ class Mage_Core_Model_Config extends Mage_Core_Model_Config_Base
                 foreach ($fileName as $configFile) {
                     $configFile = $this->getModuleDir('etc', $modName).DS.$configFile;
                     if ($mergeModel->loadFile($configFile)) {
+
+                        $this->_makeEventsLowerCase(Mage_Core_Model_App_Area::AREA_GLOBAL, $mergeModel);
+                        $this->_makeEventsLowerCase(Mage_Core_Model_App_Area::AREA_FRONTEND, $mergeModel);
+                        $this->_makeEventsLowerCase(Mage_Core_Model_App_Area::AREA_ADMIN, $mergeModel);
+                        $this->_makeEventsLowerCase(Mage_Core_Model_App_Area::AREA_ADMINHTML, $mergeModel);
+
                         $mergeToObject->extend($mergeModel, true);
                     }
                 }
@@ -1154,7 +1160,7 @@ class Mage_Core_Model_Config extends Mage_Core_Model_Config_Base
         }
 
         foreach ($events as $event) {
-            $eventName = $event->getName();
+            $eventName = strtolower($event->getName());
             $observers = $event->observers->children();
             foreach ($observers as $observer) {
                 switch ((string)$observer->type) {
@@ -1631,4 +1637,42 @@ class Mage_Core_Model_Config extends Mage_Core_Model_Config_Base
         }
         return false;
     }
+
+    /**
+     * Makes all events to lower-case
+     *
+     * @param string $area
+     * @param Mage_Core_Model_Config_Base $mergeModel
+     */
+    protected function _makeEventsLowerCase($area, Mage_Core_Model_Config_Base $mergeModel)
+    {
+        $events = $mergeModel->getNode($area . "/" . Mage_Core_Model_App_Area::PART_EVENTS);
+        if ($events !== false) {
+            $children = clone $events->children();
+            /** @var Mage_Core_Model_Config_Element $event */
+            foreach ($children as $event) {
+                if ($this->_isNodeNameHasUpperCase($event)) {
+                    $oldName = $event->getName();
+                    $newEventName = strtolower($oldName);
+                    if (!isset($events->$newEventName)) {
+                        /** @var Mage_Core_Model_Config_Element $newNode */
+                        $newNode = $events->addChild($newEventName, $event);
+                        $newNode->extend($event);
+                    }
+                    unset($events->$oldName);
+                }
+            }
+        }
+    }
+
+    /**
+     * Checks is event name has upper-case letters
+     *
+     * @param Mage_Core_Model_Config_Element $event
+     * @return bool
+     */
+    protected function _isNodeNameHasUpperCase(Mage_Core_Model_Config_Element $event)
+    {
+        return (strtolower($event->getName()) !== (string)$event->getName());
+    }
 }
diff --git app/code/core/Mage/Core/Model/Email/Template/Filter.php app/code/core/Mage/Core/Model/Email/Template/Filter.php
index 09735da..0a12b28 100644
--- app/code/core/Mage/Core/Model/Email/Template/Filter.php
+++ app/code/core/Mage/Core/Model/Email/Template/Filter.php
@@ -166,11 +166,14 @@ class Mage_Core_Model_Email_Template_Filter extends Varien_Filter_Template
         $skipParams = array('type', 'id', 'output');
         $blockParameters = $this->_getIncludeParameters($construction[2]);
         $layout = Mage::app()->getLayout();
+        $block = null;
 
         if (isset($blockParameters['type'])) {
             if ($this->_permissionBlock->isTypeAllowed($blockParameters['type'])) {
                 $type = $blockParameters['type'];
                 $block = $layout->createBlock($type, null, $blockParameters);
+            } else {
+                Mage::log('Security problem: ' . $blockParameters['type'] . ' has not been whitelisted.');
             }
         } elseif (isset($blockParameters['id'])) {
             $block = $layout->createBlock('cms/block');
@@ -187,11 +190,10 @@ class Mage_Core_Model_Email_Template_Filter extends Varien_Filter_Template
                 }
                 $block->setDataUsingMethod($k, $v);
             }
-        }
-
-        if (!$block) {
+        } else {
             return '';
         }
+
         if (isset($blockParameters['output'])) {
             $method = $blockParameters['output'];
         }
diff --git app/code/core/Mage/Core/Model/File/Validator/Image.php app/code/core/Mage/Core/Model/File/Validator/Image.php
new file mode 100644
index 0000000..554f55d
--- /dev/null
+++ app/code/core/Mage/Core/Model/File/Validator/Image.php
@@ -0,0 +1,109 @@
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
+ * @copyright Copyright (c) 2006-2015 X.commerce, Inc. (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+/**
+ * Validator for check is uploaded file is image
+ *
+ * @category   Mage
+ * @package    Mage_Core
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Core_Model_File_Validator_Image
+{
+    const NAME = "isImage";
+
+    protected $_allowedImageTypes = array(
+        IMAGETYPE_JPEG,
+        IMAGETYPE_GIF,
+        IMAGETYPE_JPEG2000,
+        IMAGETYPE_PNG,
+        IMAGETYPE_ICO,
+        IMAGETYPE_TIFF_II,
+        IMAGETYPE_TIFF_MM
+    );
+
+    /**
+     * Setter for allowed image types
+     *
+     * @param array $imageFileExtensions
+     * @return $this
+     */
+    public function setAllowedImageTypes(array $imageFileExtensions = array())
+    {
+        $map = array(
+            'tif' => array(IMAGETYPE_TIFF_II, IMAGETYPE_TIFF_MM),
+            'tiff' => array(IMAGETYPE_TIFF_II, IMAGETYPE_TIFF_MM),
+            'jpg' => array(IMAGETYPE_JPEG, IMAGETYPE_JPEG2000),
+            'jpe' => array(IMAGETYPE_JPEG, IMAGETYPE_JPEG2000),
+            'jpeg' => array(IMAGETYPE_JPEG, IMAGETYPE_JPEG2000),
+            'gif' => array(IMAGETYPE_GIF),
+            'png' => array(IMAGETYPE_PNG),
+            'ico' => array(IMAGETYPE_ICO),
+            'apng' => array(IMAGETYPE_PNG)
+        );
+
+        $this->_allowedImageTypes = array();
+
+        foreach ($imageFileExtensions as $extension) {
+            if (isset($map[$extension])) {
+                foreach ($map[$extension] as $imageType) {
+                    $this->_allowedImageTypes[$imageType] = $imageType;
+                }
+            }
+        }
+
+        return $this;
+    }
+
+    /**
+     * Validation callback for checking is file is image
+     *
+     * @param  string $filePath Path to temporary uploaded file
+     * @return null
+     * @throws Mage_Core_Exception
+     */
+    public function validate($filePath)
+    {
+        $fileInfo = getimagesize($filePath);
+        if (is_array($fileInfo) and isset($fileInfo[2])) {
+            if ($this->isImageType($fileInfo[2])) {
+                return null;
+            }
+        }
+        throw Mage::exception('Mage_Core', Mage::helper('core')->__('Invalid MIME type.'));
+    }
+
+    /**
+     * Returns is image by image type
+     * @param int $nImageType
+     * @return bool
+     */
+    protected function isImageType($nImageType)
+    {
+        return in_array($nImageType, $this->_allowedImageTypes);
+    }
+
+}
diff --git app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php
index 8f9801a..842e729 100644
--- app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php
+++ app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php
@@ -50,11 +50,11 @@ class Mage_Core_Model_Input_Filter_MaliciousCode implements Zend_Filter_Interfac
         //js in the style attribute
         '/style=[^<]*((expression\s*?\([^<]*?\))|(behavior\s*:))[^<]*(?=\>)/Uis',
         //js attributes
-        '/(ondblclick|onclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|onload|onunload|onerror)=[^<]*(?=\>)/Uis',
+        '/(ondblclick|onclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|onload|onunload|onerror)\s*=[^<]*(?=\>)/Uis',
         //tags
         '/<\/?(script|meta|link|frame|iframe).*>/Uis',
         //base64 usage
-        '/src=[^<]*base64[^<]*(?=\>)/Uis',
+        '/src\s*=[^<]*base64[^<]*(?=\>)/Uis',
     );
 
     /**
diff --git app/code/core/Mage/Core/Model/Session.php app/code/core/Mage/Core/Model/Session.php
index 5ffdb50..e1f08ce 100644
--- app/code/core/Mage/Core/Model/Session.php
+++ app/code/core/Mage/Core/Model/Session.php
@@ -36,7 +36,7 @@
  */
 class Mage_Core_Model_Session extends Mage_Core_Model_Session_Abstract
 {
-    public function __construct($data=array())
+    public function __construct($data = array())
     {
         $name = isset($data['name']) ? $data['name'] : null;
         $this->init('core', $name);
@@ -50,8 +50,27 @@ class Mage_Core_Model_Session extends Mage_Core_Model_Session_Abstract
     public function getFormKey()
     {
         if (!$this->getData('_form_key')) {
-            $this->setData('_form_key', Mage::helper('core')->getRandomString(16));
+            $this->renewFormKey();
         }
         return $this->getData('_form_key');
     }
+
+    /**
+     * Creates new Form key
+     */
+    public function renewFormKey()
+    {
+        $this->setData('_form_key', Mage::helper('core')->getRandomString(16));
+    }
+
+    /**
+     * Validates Form key
+     *
+     * @param string|null $formKey
+     * @return bool
+     */
+    public function validateFormKey($formKey)
+    {
+        return ($formKey === $this->getFormKey());
+    }
 }
diff --git app/code/core/Mage/Customer/controllers/AccountController.php app/code/core/Mage/Customer/controllers/AccountController.php
index 2db7d13..f87f637 100644
--- app/code/core/Mage/Customer/controllers/AccountController.php
+++ app/code/core/Mage/Customer/controllers/AccountController.php
@@ -68,7 +68,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             return;
         }
 
-        $action = $this->getRequest()->getActionName();
+        $action = strtolower($this->getRequest()->getActionName());
         $openActions = array(
             'create',
             'login',
diff --git app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
index b3b211a..943dc59 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
@@ -252,7 +252,7 @@ class Mage_Dataflow_Model_Convert_Parser_Csv extends Mage_Dataflow_Model_Convert
      * Retrieve csv string from array
      *
      * @param array $fields
-     * @return sting
+     * @return string
      */
     public function getCsvString($fields = array()) {
         $delimiter  = $this->getVar('delimiter', ',');
@@ -264,11 +264,10 @@ class Mage_Dataflow_Model_Convert_Parser_Csv extends Mage_Dataflow_Model_Convert
         }
 
         $str = '';
-
         foreach ($fields as $value) {
-            if (substr($value, 0, 1) === '=') {
-                $value = ' ' . $value;
-            }
+
+            $escapedValue = Mage::helper("core")->getEscapedCSVData(array($value));
+            $value = $escapedValue[0];
 
             if (strpos($value, $delimiter) !== false ||
                 empty($enclosure) ||
diff --git app/code/core/Mage/Downloadable/controllers/CustomerController.php app/code/core/Mage/Downloadable/controllers/CustomerController.php
index 4feaa91..78122b8 100644
--- app/code/core/Mage/Downloadable/controllers/CustomerController.php
+++ app/code/core/Mage/Downloadable/controllers/CustomerController.php
@@ -40,7 +40,7 @@ class Mage_Downloadable_CustomerController extends Mage_Core_Controller_Front_Ac
     public function preDispatch()
     {
         parent::preDispatch();
-        $action = $this->getRequest()->getActionName();
+
         $loginUrl = Mage::helper('customer')->getLoginUrl();
 
         if (!Mage::getSingleton('customer/session')->authenticate($this, $loginUrl)) {
diff --git app/code/core/Mage/ImportExport/Model/Export/Adapter/Abstract.php app/code/core/Mage/ImportExport/Model/Export/Adapter/Abstract.php
index 0a2651e..990d945 100644
--- app/code/core/Mage/ImportExport/Model/Export/Adapter/Abstract.php
+++ app/code/core/Mage/ImportExport/Model/Export/Adapter/Abstract.php
@@ -137,6 +137,15 @@ abstract class Mage_ImportExport_Model_Export_Adapter_Abstract
     }
 
     /**
+     * Returns destination path
+     * @return string
+     */
+    public function getDestination()
+    {
+        return $this->_destination;
+    }
+
+    /**
      * Write row data to source file.
      *
      * @param array $rowData
diff --git app/code/core/Mage/ImportExport/Model/Export/Adapter/Csv.php app/code/core/Mage/ImportExport/Model/Export/Adapter/Csv.php
index 419c8d0..a632199 100644
--- app/code/core/Mage/ImportExport/Model/Export/Adapter/Csv.php
+++ app/code/core/Mage/ImportExport/Model/Export/Adapter/Csv.php
@@ -33,6 +33,9 @@
  */
 class Mage_ImportExport_Model_Export_Adapter_Csv extends Mage_ImportExport_Model_Export_Adapter_Abstract
 {
+    /** config string for escaping export */
+    const CONFIG_ESCAPING_FLAG = 'system/export_csv/escaping';
+
     /**
      * Field delimiter.
      *
@@ -115,11 +118,7 @@ class Mage_ImportExport_Model_Export_Adapter_Csv extends Mage_ImportExport_Model
          * @see https://bugzilla.mozilla.org/show_bug.cgi?id=1054702
          */
         $data = array_merge($this->_headerCols, array_intersect_key($rowData, $this->_headerCols));
-        foreach ($data as $key => $value) {
-            if (substr($value, 0, 1) === '=') {
-                $data[$key] = ' ' . $value;
-            }
-        }
+        $data = Mage::helper("core")->getEscapedCSVData($data);
 
         fputcsv(
             $this->_fileHandler,
@@ -130,4 +129,5 @@ class Mage_ImportExport_Model_Export_Adapter_Csv extends Mage_ImportExport_Model
 
         return $this;
     }
+
 }
diff --git app/code/core/Mage/ImportExport/Model/Import/Entity/Abstract.php app/code/core/Mage/ImportExport/Model/Import/Entity/Abstract.php
index 7b7642e..ca5672b 100644
--- app/code/core/Mage/ImportExport/Model/Import/Entity/Abstract.php
+++ app/code/core/Mage/ImportExport/Model/Import/Entity/Abstract.php
@@ -274,6 +274,9 @@ abstract class Mage_ImportExport_Model_Import_Entity_Abstract
         $maxDataSize = Mage::getResourceHelper('importexport')->getMaxDataSize();
         $bunchSize = Mage::helper('importexport')->getBunchSize();
 
+        /** @var Mage_Core_Helper_Data $coreHelper */
+        $coreHelper = Mage::helper("core");
+
         $source->rewind();
         $this->_dataSourceModel->cleanBunches();
 
@@ -290,7 +293,7 @@ abstract class Mage_ImportExport_Model_Import_Entity_Abstract
                 if ($this->_errorsCount >= $this->_errorsLimit) { // errors limit check
                     return;
                 }
-                $rowData = $source->current();
+                $rowData = $coreHelper->unEscapeCSVData($source->current());
 
                 $this->_processedRowsCount++;
 
diff --git app/code/core/Mage/ImportExport/etc/config.xml app/code/core/Mage/ImportExport/etc/config.xml
index 30c30b9..25b7007 100644
--- app/code/core/Mage/ImportExport/etc/config.xml
+++ app/code/core/Mage/ImportExport/etc/config.xml
@@ -135,6 +135,11 @@
         </layout>
     </adminhtml>
     <default>
+        <system>
+            <export_csv>
+                <escaping>1</escaping>
+            </export_csv>
+        </system>
         <general>
             <file>
                 <importexport_local_valid_paths>
diff --git app/code/core/Mage/ImportExport/etc/system.xml app/code/core/Mage/ImportExport/etc/system.xml
new file mode 100644
index 0000000..40e9b97
--- /dev/null
+++ app/code/core/Mage/ImportExport/etc/system.xml
@@ -0,0 +1,54 @@
+<?xml version="1.0"?>
+<!--
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
+ * @package     Mage_ImportExport
+ * @copyright Copyright (c) 2006-2015 X.commerce, Inc. (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+-->
+<config>
+    <sections>
+        <system>
+            <groups>
+                <export_csv translate="label">
+                    <label>Escape CSV fields</label>
+                    <show_in_default>1</show_in_default>
+                    <show_in_website>1</show_in_website>
+                    <show_in_store>1</show_in_store>
+                    <sort_order>500</sort_order>
+                    <fields>
+                        <escaping translate="label">
+                            <label>Escape CSV fields</label>
+                            <frontend_type>select</frontend_type>
+                            <source_model>adminhtml/system_config_source_yesno</source_model>
+                            <sort_order>1</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>0</show_in_website>
+                            <show_in_store>0</show_in_store>
+                            <comment>Disabling this setting can increase security risk.</comment>
+                        </escaping>
+                    </fields>
+                </export_csv>
+            </groups>
+        </system>
+    </sections>
+</config>
diff --git app/code/core/Mage/Newsletter/Model/Observer.php app/code/core/Mage/Newsletter/Model/Observer.php
index d3a0096..6e3ea51 100644
--- app/code/core/Mage/Newsletter/Model/Observer.php
+++ app/code/core/Mage/Newsletter/Model/Observer.php
@@ -61,6 +61,7 @@ class Mage_Newsletter_Model_Observer
         $countOfQueue  = 3;
         $countOfSubscritions = 20;
 
+        /** @var Mage_Newsletter_Model_Resource_Queue_Collection $collection */
         $collection = Mage::getModel('newsletter/queue')->getCollection()
             ->setPageSize($countOfQueue)
             ->setCurPage(1)
diff --git app/code/core/Mage/Newsletter/Model/Queue.php app/code/core/Mage/Newsletter/Model/Queue.php
index 791d398..3f0a2e1 100644
--- app/code/core/Mage/Newsletter/Model/Queue.php
+++ app/code/core/Mage/Newsletter/Model/Queue.php
@@ -186,6 +186,7 @@ class Mage_Newsletter_Model_Queue extends Mage_Core_Model_Template
             return $this;
         }
 
+        /** @var Mage_Newsletter_Model_Resource_Subscriber_Collection $collection */
         $collection = $this->getSubscribersCollection()
             ->useOnlyUnsent()
             ->showCustomerInfo()
@@ -193,7 +194,7 @@ class Mage_Newsletter_Model_Queue extends Mage_Core_Model_Template
             ->setCurPage(1)
             ->load();
 
-        /* @var $sender Mage_Core_Model_Email_Template */
+        /** @var Mage_Core_Model_Email_Template $sender */
         $sender = Mage::getModel('core/email_template');
         $sender->setSenderName($this->getNewsletterSenderName())
             ->setSenderEmail($this->getNewsletterSenderEmail())
diff --git app/code/core/Mage/Page/etc/system.xml app/code/core/Mage/Page/etc/system.xml
index e471ccf..3a8bdd2 100644
--- app/code/core/Mage/Page/etc/system.xml
+++ app/code/core/Mage/Page/etc/system.xml
@@ -39,7 +39,7 @@
                     <fields>
                         <shortcut_icon translate="label comment">
                             <label>Favicon Icon</label>
-                            <comment>Allowed file types: ICO, PNG, GIF, JPG, JPEG, APNG, SVG. Not all browsers support all these formats!</comment>
+                            <comment>Allowed file types: ICO, PNG, GIF, JPG, JPEG, APNG. Not all browsers support all these formats!</comment>
                             <frontend_type>image</frontend_type>
                             <backend_model>adminhtml/system_config_backend_image_favicon</backend_model>
                             <base_url type="media" scope_info="1">favicon</base_url>
diff --git app/code/core/Mage/Paypal/controllers/PayflowController.php app/code/core/Mage/Paypal/controllers/PayflowController.php
index 2f263bf..957e26c 100644
--- app/code/core/Mage/Paypal/controllers/PayflowController.php
+++ app/code/core/Mage/Paypal/controllers/PayflowController.php
@@ -66,7 +66,12 @@ class Mage_Paypal_PayflowController extends Mage_Core_Controller_Front_Action
                     $session->unsLastRealOrderId();
                     $redirectBlock->setGotoSuccessPage(true);
                 } else {
-                    $gotoSection = $this->_cancelPayment(strval($this->getRequest()->getParam('RESPMSG')));
+                    $gotoSection = $this->_cancelPayment(
+                        Mage::helper('core')
+                            ->stripTags(
+                                strval($this->getRequest()->getParam('RESPMSG'))
+                            )
+                    );
                     $redirectBlock->setGotoSection($gotoSection);
                     $redirectBlock->setErrorMsg($this->__('Payment has been declined. Please try again.'));
                 }
diff --git app/code/core/Mage/Paypal/controllers/PayflowadvancedController.php app/code/core/Mage/Paypal/controllers/PayflowadvancedController.php
index 08316eb..03c09ee 100644
--- app/code/core/Mage/Paypal/controllers/PayflowadvancedController.php
+++ app/code/core/Mage/Paypal/controllers/PayflowadvancedController.php
@@ -92,7 +92,12 @@ class Mage_Paypal_PayflowadvancedController extends Mage_Paypal_Controller_Expre
                     $session->unsLastRealOrderId();
                     $redirectBlock->setGotoSuccessPage(true);
                 } else {
-                    $gotoSection = $this->_cancelPayment(strval($this->getRequest()->getParam('RESPMSG')));
+                    $gotoSection = $this->_cancelPayment(
+                        Mage::helper('core')
+                            ->stripTags(
+                                strval($this->getRequest()->getParam('RESPMSG'))
+                            )
+                    );
                     $redirectBlock->setGotoSection($gotoSection);
                     $redirectBlock->setErrorMsg($this->__('Payment has been declined. Please try again.'));
                 }
diff --git app/code/core/Mage/Paypal/etc/config.xml app/code/core/Mage/Paypal/etc/config.xml
index e10b2da..976b2ce 100644
--- app/code/core/Mage/Paypal/etc/config.xml
+++ app/code/core/Mage/Paypal/etc/config.xml
@@ -148,14 +148,14 @@
                     </hss_save_order_after_submit>
                 </observers>
             </checkout_submit_all_after>
-            <controller_action_postdispatch_checkout_onepage_saveOrder>
+            <controller_action_postdispatch_checkout_onepage_saveorder>
                 <observers>
                     <hss_save_order_onepage>
                         <class>paypal/observer</class>
                         <method>setResponseAfterSaveOrder</method>
                     </hss_save_order_onepage>
                 </observers>
-            </controller_action_postdispatch_checkout_onepage_saveOrder>
+            </controller_action_postdispatch_checkout_onepage_saveorder>
         </events>
     </frontend>
     <adminhtml>
diff --git app/code/core/Mage/Persistent/etc/config.xml app/code/core/Mage/Persistent/etc/config.xml
index df00a1b..77e6474 100644
--- app/code/core/Mage/Persistent/etc/config.xml
+++ app/code/core/Mage/Persistent/etc/config.xml
@@ -111,14 +111,14 @@
                     </persistent>
                 </observers>
             </controller_action_layout_load_before>
-            <controller_action_predispatch_customer_account_loginPost>
+            <controller_action_predispatch_customer_account_loginpost>
                 <observers>
                     <persistent>
                         <class>persistent/observer_session</class>
                         <method>setRememberMeCheckedStatus</method>
                     </persistent>
                 </observers>
-            </controller_action_predispatch_customer_account_loginPost>
+            </controller_action_predispatch_customer_account_loginpost>
             <controller_action_predispatch_customer_account_createpost>
                 <observers>
                     <persistent>
@@ -175,22 +175,22 @@
                     </persistent>
                 </observers>
             </customer_customer_authenticated>
-            <controller_action_predispatch_persistent_index_unsetCookie>
+            <controller_action_predispatch_persistent_index_unsetcookie>
                 <observers>
                     <persistent>
                         <class>persistent/observer</class>
                         <method>preventClearCheckoutSession</method>
                     </persistent>
                 </observers>
-            </controller_action_predispatch_persistent_index_unsetCookie>
-            <controller_action_postdispatch_persistent_index_unsetCookie>
+            </controller_action_predispatch_persistent_index_unsetcookie>
+            <controller_action_postdispatch_persistent_index_unsetcookie>
                 <observers>
                     <persistent>
                         <class>persistent/observer</class>
                         <method>makePersistentQuoteGuest</method>
                     </persistent>
                 </observers>
-            </controller_action_postdispatch_persistent_index_unsetCookie>
+            </controller_action_postdispatch_persistent_index_unsetcookie>
             <sales_quote_save_before>
                 <observers>
                     <persistent>
@@ -207,14 +207,14 @@
                     </persistent>
                 </observers>
             </custom_quote_process>
-            <controller_action_postdispatch_checkout_onepage_saveBilling>
+            <controller_action_postdispatch_checkout_onepage_savebilling>
                 <observers>
                     <persistent>
                         <class>persistent/observer_session</class>
                         <method>setRememberMeCheckedStatus</method>
                     </persistent>
                 </observers>
-            </controller_action_postdispatch_checkout_onepage_saveBilling>
+            </controller_action_postdispatch_checkout_onepage_savebilling>
             <customer_register_success>
                 <observers>
                     <persistent>
diff --git app/code/core/Mage/Review/controllers/ProductController.php app/code/core/Mage/Review/controllers/ProductController.php
index 30b83af..c60830a 100644
--- app/code/core/Mage/Review/controllers/ProductController.php
+++ app/code/core/Mage/Review/controllers/ProductController.php
@@ -50,7 +50,7 @@ class Mage_Review_ProductController extends Mage_Core_Controller_Front_Action
             return;
         }
 
-        $action = $this->getRequest()->getActionName();
+        $action = strtolower($this->getRequest()->getActionName());
         if (!$allowGuest && $action == 'post' && $this->getRequest()->isPost()) {
             if (!Mage::getSingleton('customer/session')->isLoggedIn()) {
                 $this->setFlag('', self::FLAG_NO_DISPATCH, true);
@@ -172,9 +172,9 @@ class Mage_Review_ProductController extends Mage_Core_Controller_Front_Action
         }
 
         if (($product = $this->_initProduct()) && !empty($data)) {
-            $session    = Mage::getSingleton('core/session');
+            $session = Mage::getSingleton('core/session');
             /* @var $session Mage_Core_Model_Session */
-            $review     = Mage::getModel('review/review')->setData($data);
+            $review = Mage::getModel('review/review')->setData($this->_cropReviewData($data));
             /* @var $review Mage_Review_Model_Review */
 
             $validate = $review->validate();
@@ -307,4 +307,23 @@ class Mage_Review_ProductController extends Mage_Core_Controller_Front_Action
         $update->addUpdate($product->getCustomLayoutUpdate());
         $this->generateLayoutXml()->generateLayoutBlocks();
     }
+
+    /**
+     * Crops POST values
+     * @param array $reviewData
+     * @return array
+     */
+    protected function _cropReviewData(array $reviewData)
+    {
+        $croppedValues = array();
+        $allowedKeys = array_fill_keys(array('detail', 'title', 'nickname'), true);
+
+        foreach ($reviewData as $key => $value) {
+            if (isset($allowedKeys[$key])) {
+                $croppedValues[$key] = $value;
+            }
+        }
+
+        return $croppedValues;
+    }
 }
diff --git app/code/core/Mage/Rss/Block/Catalog/Salesrule.php app/code/core/Mage/Rss/Block/Catalog/Salesrule.php
index 401af44..da629d7 100644
--- app/code/core/Mage/Rss/Block/Catalog/Salesrule.php
+++ app/code/core/Mage/Rss/Block/Catalog/Salesrule.php
@@ -82,7 +82,7 @@ class Mage_Rss_Block_Catalog_Salesrule extends Mage_Rss_Block_Abstract
             '<td style="text-decoration:none;">'.$sr->getDescription().
             '<br/>Discount Start Date: '.$this->formatDate($sr->getFromDate(), 'medium').
             ( $sr->getToDate() ? ('<br/>Discount End Date: '.$this->formatDate($sr->getToDate(), 'medium')):'').
-            ($sr->getCouponCode() ? '<br/> Coupon Code: '.$sr->getCouponCode().'' : '').
+            ($sr->getCouponCode() ? '<br/> Coupon Code: '. $this->escapeHtml($sr->getCouponCode()).'' : '').
             '</td>'.
             '</tr></table>';
              $data = array(
diff --git app/code/core/Mage/Rss/Helper/Order.php app/code/core/Mage/Rss/Helper/Order.php
index 2d33d7b..47c0227 100644
--- app/code/core/Mage/Rss/Helper/Order.php
+++ app/code/core/Mage/Rss/Helper/Order.php
@@ -89,11 +89,16 @@ class Mage_Rss_Helper_Order extends Mage_Core_Helper_Abstract
             return null;
         }
 
+        $orderId = intval($data['order_id']);
+        $incrementId = intval($data['increment_id']);
+        $customerId = intval($data['customer_id']);
+
         /** @var $order Mage_Sales_Model_Order */
-        $order = Mage::getModel('sales/order')->load($data['order_id']);
-        if ($order->getId()
-            && $order->getIncrementId() == $data['increment_id']
-            && $order->getCustomerId() == $data['customer_id']
+        $order = Mage::getModel('sales/order')->load($orderId);
+
+        if (!is_null($order->getId())
+            && intval($order->getIncrementId()) === $incrementId
+            && intval($order->getCustomerId()) === $customerId
         ) {
             return $order;
         }
diff --git app/code/core/Mage/Sales/Helper/Guest.php app/code/core/Mage/Sales/Helper/Guest.php
index e7b513b..d30195c 100644
--- app/code/core/Mage/Sales/Helper/Guest.php
+++ app/code/core/Mage/Sales/Helper/Guest.php
@@ -50,19 +50,15 @@ class Mage_Sales_Helper_Guest extends Mage_Core_Helper_Data
         }
 
         $post = Mage::app()->getRequest()->getPost();
-
-        $type           = '';
-        $incrementId    = '';
-        $lastName       = '';
-        $email          = '';
-        $zip            = '';
-        $protectCode    = '';
-        $errors         = false;
+        $errors = false;
 
         /** @var $order Mage_Sales_Model_Order */
         $order = Mage::getModel('sales/order');
+        /** @var Mage_Core_Model_Cookie $cookieModel */
+        $cookieModel = Mage::getSingleton('core/cookie');
+        $errorMessage = 'Entered data is incorrect. Please try again.';
 
-        if (empty($post) && !Mage::getSingleton('core/cookie')->get($this->_cookieName)) {
+        if (empty($post) && !$cookieModel->get($this->_cookieName)) {
             Mage::app()->getResponse()->setRedirect(Mage::getUrl('sales/guest/form'));
             return false;
         } elseif (!empty($post) && isset($post['oar_order_id']) && isset($post['oar_type']))  {
@@ -95,21 +91,24 @@ class Mage_Sales_Helper_Guest extends Mage_Core_Helper_Data
                 $errors = true;
             }
 
+            if ($errors === false && !is_null($order->getCustomerId())) {
+                $errorMessage = 'Please log in to view your order details.';
+                $errors = true;
+            }
+
             if (!$errors) {
                 $toCookie = base64_encode($order->getProtectCode() . ':' . $incrementId);
-                Mage::getSingleton('core/cookie')->set($this->_cookieName, $toCookie, $this->_lifeTime, '/');
+                $cookieModel->set($this->_cookieName, $toCookie, $this->_lifeTime, '/');
             }
-        } elseif (Mage::getSingleton('core/cookie')->get($this->_cookieName)) {
-            $fromCookie = Mage::getSingleton('core/cookie')->get($this->_cookieName);
-            $cookieData = explode(':', base64_decode($fromCookie));
-            $protectCode = isset($cookieData[0]) ? $cookieData[0] : null;
-            $incrementId = isset($cookieData[1]) ? $cookieData[1] : null;
-
-            if (!empty($protectCode) && !empty($incrementId)) {
-                $order->loadByIncrementId($incrementId);
-                if ($order->getProtectCode() == $protectCode) {
-                    Mage::getSingleton('core/cookie')->renew($this->_cookieName, $this->_lifeTime, '/');
+        } elseif ($cookieModel->get($this->_cookieName)) {
+            $cookie = $cookieModel->get($this->_cookieName);
+            $cookieOrder = $this->_loadOrderByCookie( $cookie );
+            if( !is_null( $cookieOrder) ){
+                if( is_null( $cookieOrder->getCustomerId() ) ){
+                    $cookieModel->renew($this->_cookieName, $this->_lifeTime, '/');
+                    $order = $cookieOrder;
                 } else {
+                    $errorMessage = 'Please log in to view your order details.';
                     $errors = true;
                 }
             } else {
@@ -122,9 +121,7 @@ class Mage_Sales_Helper_Guest extends Mage_Core_Helper_Data
             return true;
         }
 
-        Mage::getSingleton('core/session')->addError(
-            $this->__('Entered data is incorrect. Please try again.')
-        );
+        Mage::getSingleton('core/session')->addError($this->__($errorMessage));
         Mage::app()->getResponse()->setRedirect(Mage::getUrl('sales/guest/form'));
         return false;
     }
@@ -154,4 +151,40 @@ class Mage_Sales_Helper_Guest extends Mage_Core_Helper_Data
         );
     }
 
+    /**
+     * Try to load order by cookie hash
+     * 
+     * @param string|null $cookie
+     * @return null|Mage_Sales_Model_Order
+     */
+    protected function _loadOrderByCookie($cookie = null)
+    {
+        if (!is_null($cookie)) {
+            $cookieData = explode(':', base64_decode($cookie));
+            $protectCode = isset($cookieData[0]) ? $cookieData[0] : null;
+            $incrementId = isset($cookieData[1]) ? $cookieData[1] : null;
+
+            if (!empty($protectCode) && !empty($incrementId)) {
+                /** @var $order Mage_Sales_Model_Order */
+                $order = Mage::getModel('sales/order');
+                $order->loadByIncrementId($incrementId);
+
+                if ($order->getProtectCode() === $protectCode) {
+                    return $order;
+                }
+            }
+        }
+        return null;
+    }
+
+    /**
+     * Getter for $this->_cookieName
+     *
+     * @return string
+     */
+    public function getCookieName()
+    {
+        return $this->_cookieName;
+    }
+
 }
diff --git app/code/core/Mage/Sales/Model/Quote/Address.php app/code/core/Mage/Sales/Model/Quote/Address.php
index 9928dcb..86d71dc 100644
--- app/code/core/Mage/Sales/Model/Quote/Address.php
+++ app/code/core/Mage/Sales/Model/Quote/Address.php
@@ -1090,7 +1090,12 @@ class Mage_Sales_Model_Quote_Address extends Mage_Customer_Model_Address_Abstrac
      */
     public function getAppliedTaxes()
     {
-        return unserialize($this->getData('applied_taxes'));
+        try {
+            $return = Mage::helper('core/unserializeArray')->unserialize($this->getData('applied_taxes'));
+        } catch (Exception $e) {
+            $return = array();
+        }
+        return $return;
     }
 
     /**
diff --git app/code/core/Mage/Sales/Model/Quote/Item.php app/code/core/Mage/Sales/Model/Quote/Item.php
index dd4dcf1..a750cf9 100644
--- app/code/core/Mage/Sales/Model/Quote/Item.php
+++ app/code/core/Mage/Sales/Model/Quote/Item.php
@@ -494,14 +494,23 @@ class Mage_Sales_Model_Quote_Item extends Mage_Sales_Model_Quote_Item_Abstract
 
                 // dispose of some options params, that can cramp comparing of arrays
                 if (is_string($itemOptionValue) && is_string($optionValue)) {
-                    $_itemOptionValue = @unserialize($itemOptionValue);
-                    $_optionValue = @unserialize($optionValue);
-                    if (is_array($_itemOptionValue) && is_array($_optionValue)) {
-                        $itemOptionValue = $_itemOptionValue;
-                        $optionValue = $_optionValue;
-                        // looks like it does not break bundle selection qty
-                        unset($itemOptionValue['qty'], $itemOptionValue['uenc']);
-                        unset($optionValue['qty'], $optionValue['uenc']);
+                    try {
+                        /** @var Unserialize_Parser $parser */
+                        $parser = Mage::helper('core/unserializeArray');
+
+                        $_itemOptionValue = $parser->unserialize($itemOptionValue);
+                        $_optionValue = $parser->unserialize($optionValue);
+
+                        if (is_array($_itemOptionValue) && is_array($_optionValue)) {
+                            $itemOptionValue = $_itemOptionValue;
+                            $optionValue = $_optionValue;
+                            // looks like it does not break bundle selection qty
+                            unset($itemOptionValue['qty'], $itemOptionValue['uenc']);
+                            unset($optionValue['qty'], $optionValue['uenc']);
+                        }
+
+                    } catch (Exception $e) {
+                        Mage::logException($e);
                     }
                 }
 
diff --git app/code/core/Zend/Xml/Security.php app/code/core/Zend/Xml/Security.php
index a3cdbc8..2509d6c 100644
--- app/code/core/Zend/Xml/Security.php
+++ app/code/core/Zend/Xml/Security.php
@@ -14,16 +14,15 @@
  *
  * @category   Zend
  * @package    Zend_Xml
- * @copyright  Copyright (c) 2005-2014 Zend Technologies USA Inc. (http://www.zend.com)
+ * @copyright  Copyright (c) 2005-2015 Zend Technologies USA Inc. (http://www.zend.com)
  * @license    http://framework.zend.com/license/new-bsd     New BSD License
  * @version    $Id$
  */
 
-
 /**
  * @category   Zend
  * @package    Zend_Xml_SecurityScan
- * @copyright  Copyright (c) 2005-2014 Zend Technologies USA Inc. (http://www.zend.com)
+ * @copyright  Copyright (c) 2005-2015 Zend Technologies USA Inc. (http://www.zend.com)
  * @license    http://framework.zend.com/license/new-bsd     New BSD License
  */
 class Zend_Xml_Security
@@ -108,6 +107,9 @@ class Zend_Xml_Security
             foreach ($dom->childNodes as $child) {
                 if ($child->nodeType === XML_DOCUMENT_TYPE_NODE) {
                     if ($child->entities->length > 0) {
+                        libxml_disable_entity_loader($loadEntities);
+                        libxml_use_internal_errors($useInternalXmlErrors);
+
                         #require_once 'Exception.php';
                         throw new Zend_Xml_Exception(self::ENTITY_DETECT);
                     }
@@ -157,24 +159,11 @@ class Zend_Xml_Security
      * (vs libxml checks) should be made, due to threading issues in libxml;
      * under php-fpm, threading becomes a concern.
      *
-     * However, PHP versions 5.5.22+ and 5.6.6+ contain a patch to the
-     * libxml support in PHP that makes the libxml checks viable; in such
-     * versions, this method will return false to enforce those checks, which
-     * are more strict and accurate than the heuristic checks.
-     *
      * @return boolean
      */
     public static function isPhpFpm()
     {
-        $isVulnerableVersion = (
-            version_compare(PHP_VERSION, '5.5.22', 'lt')
-            || (
-                version_compare(PHP_VERSION, '5.6', 'gte')
-                && version_compare(PHP_VERSION, '5.6.6', 'lt')
-            )
-        );
-
-        if (substr(php_sapi_name(), 0, 3) === 'fpm' && $isVulnerableVersion) {
+        if (substr(php_sapi_name(), 0, 3) === 'fpm') {
             return true;
         }
         return false;
@@ -485,4 +474,4 @@ class Zend_Xml_Security
     {
         return $ascii;
     }
-}
+}
\ No newline at end of file
diff --git app/design/adminhtml/default/default/template/authorizenet/directpost/iframe.phtml app/design/adminhtml/default/default/template/authorizenet/directpost/iframe.phtml
index 132757e..1c63981 100644
--- app/design/adminhtml/default/default/template/authorizenet/directpost/iframe.phtml
+++ app/design/adminhtml/default/default/template/authorizenet/directpost/iframe.phtml
@@ -30,8 +30,8 @@
 ?>
 <?php
 $_params = $this->getParams();
-/* @var $_helper Mage_Authorizenet_Helper_Data  */
-$_helper = $this->helper('authorizenet');
+/* @var $_helper Mage_Authorizenet_Helper_Admin  */
+$_helper = $this->helper('authorizenet/admin');
 ?>
 <html>
 <head>
diff --git app/design/adminhtml/default/default/template/bundle/sales/creditmemo/create/items/renderer.phtml app/design/adminhtml/default/default/template/bundle/sales/creditmemo/create/items/renderer.phtml
index 2ed4401..a92b46f 100644
--- app/design/adminhtml/default/default/template/bundle/sales/creditmemo/create/items/renderer.phtml
+++ app/design/adminhtml/default/default/template/bundle/sales/creditmemo/create/items/renderer.phtml
@@ -376,7 +376,7 @@
             <?php if ($this->getOrderOptions($_item->getOrderItem())): ?>
                 <dl class="item-options">
                 <?php foreach ($this->getOrderOptions($_item->getOrderItem()) as $option): ?>
-                    <dt><?php echo $option['label'] ?></dt>
+                    <dt><?php echo $this->escapeHtml($option['label']) ?></dt>
                     <dd>
                     <?php if (isset($option['custom_view']) && $option['custom_view']): ?>
                         <?php echo $option['value'];?>
diff --git app/design/adminhtml/default/default/template/bundle/sales/creditmemo/view/items/renderer.phtml app/design/adminhtml/default/default/template/bundle/sales/creditmemo/view/items/renderer.phtml
index 56f811b..fbf597f 100644
--- app/design/adminhtml/default/default/template/bundle/sales/creditmemo/view/items/renderer.phtml
+++ app/design/adminhtml/default/default/template/bundle/sales/creditmemo/view/items/renderer.phtml
@@ -310,7 +310,7 @@
             <?php if ($this->getOrderOptions()): ?>
                 <dl class="item-options">
                 <?php foreach ($this->getOrderOptions() as $option): ?>
-                    <dt><?php echo $option['label'] ?></dt>
+                    <dt><?php echo $this->escapeHtml($option['label']) ?></dt>
                     <dd>
                     <?php if (isset($option['custom_view']) && $option['custom_view']): ?>
                         <?php echo $option['value'];?>
diff --git app/design/adminhtml/default/default/template/bundle/sales/invoice/create/items/renderer.phtml app/design/adminhtml/default/default/template/bundle/sales/invoice/create/items/renderer.phtml
index 65b7c49..239675c 100644
--- app/design/adminhtml/default/default/template/bundle/sales/invoice/create/items/renderer.phtml
+++ app/design/adminhtml/default/default/template/bundle/sales/invoice/create/items/renderer.phtml
@@ -364,7 +364,7 @@
             <?php if ($this->getOrderOptions($_item->getOrderItem())): ?>
                 <dl class="item-options">
                 <?php foreach ($this->getOrderOptions($_item->getOrderItem()) as $option): ?>
-                    <dt><?php echo $option['label'] ?></dt>
+                    <dt><?php echo $this->escapeHtml($option['label']) ?></dt>
                     <dd>
                     <?php if (isset($option['custom_view']) && $option['custom_view']): ?>
                         <?php echo $option['value'];?>
diff --git app/design/adminhtml/default/default/template/bundle/sales/invoice/view/items/renderer.phtml app/design/adminhtml/default/default/template/bundle/sales/invoice/view/items/renderer.phtml
index f5e03c5..e0e99ee 100644
--- app/design/adminhtml/default/default/template/bundle/sales/invoice/view/items/renderer.phtml
+++ app/design/adminhtml/default/default/template/bundle/sales/invoice/view/items/renderer.phtml
@@ -309,7 +309,7 @@
             <?php if ($this->getOrderOptions()): ?>
                 <dl class="item-options">
                 <?php foreach ($this->getOrderOptions() as $option): ?>
-                    <dt><?php echo $option['label'] ?></dt>
+                    <dt><?php echo $this->escapeHtml($option['label']) ?></dt>
                     <dd>
                     <?php if (isset($option['custom_view']) && $option['custom_view']): ?>
                         <?php echo $option['value'];?>
diff --git app/design/adminhtml/default/default/template/bundle/sales/order/view/items/renderer.phtml app/design/adminhtml/default/default/template/bundle/sales/order/view/items/renderer.phtml
index bf4cfc4..d2a46a1 100644
--- app/design/adminhtml/default/default/template/bundle/sales/order/view/items/renderer.phtml
+++ app/design/adminhtml/default/default/template/bundle/sales/order/view/items/renderer.phtml
@@ -379,7 +379,7 @@
             <?php if ($this->getOrderOptions()): ?>
                 <dl class="item-options">
                 <?php foreach ($this->getOrderOptions() as $option): ?>
-                    <dt><?php echo $option['label'] ?>:</dt>
+                    <dt><?php echo $this->escapeHtml($option['label']) ?>:</dt>
                     <dd>
                     <?php if (isset($option['custom_view']) && $option['custom_view']): ?>
                         <?php echo $option['value'];?>
diff --git app/design/adminhtml/default/default/template/bundle/sales/shipment/create/items/renderer.phtml app/design/adminhtml/default/default/template/bundle/sales/shipment/create/items/renderer.phtml
index 203bdac..f1f40b7 100644
--- app/design/adminhtml/default/default/template/bundle/sales/shipment/create/items/renderer.phtml
+++ app/design/adminhtml/default/default/template/bundle/sales/shipment/create/items/renderer.phtml
@@ -89,7 +89,7 @@
             <?php if ($this->getOrderOptions($_item->getOrderItem())): ?>
                 <dl class="item-options">
                 <?php foreach ($this->getOrderOptions($_item->getOrderItem()) as $option): ?>
-                    <dt><?php echo $option['label'] ?></dt>
+                    <dt><?php echo $this->escapeHtml($option['label']) ?></dt>
                     <dd>
                     <?php if (isset($option['custom_view']) && $option['custom_view']): ?>
                         <?php echo $option['value'];?>
diff --git app/design/adminhtml/default/default/template/bundle/sales/shipment/view/items/renderer.phtml app/design/adminhtml/default/default/template/bundle/sales/shipment/view/items/renderer.phtml
index 077fafd..eef2895 100644
--- app/design/adminhtml/default/default/template/bundle/sales/shipment/view/items/renderer.phtml
+++ app/design/adminhtml/default/default/template/bundle/sales/shipment/view/items/renderer.phtml
@@ -89,7 +89,7 @@
             <?php if ($this->getOrderOptions($_item->getOrderItem())): ?>
                 <dl class="item-options">
                 <?php foreach ($this->getOrderOptions($_item->getOrderItem()) as $option): ?>
-                    <dt><?php echo $option['label'] ?></dt>
+                    <dt><?php echo $this->escapeHtml($option['label']) ?></dt>
                     <dd>
                     <?php if (isset($option['custom_view']) && $option['custom_view']): ?>
                         <?php echo $option['value'];?>
diff --git app/design/adminhtml/default/default/template/catalog/product/composite/fieldset/options/type/file.phtml app/design/adminhtml/default/default/template/catalog/product/composite/fieldset/options/type/file.phtml
index 0584a5c..089c84b 100644
--- app/design/adminhtml/default/default/template/catalog/product/composite/fieldset/options/type/file.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/composite/fieldset/options/type/file.phtml
@@ -78,7 +78,7 @@
     <?php echo $this->getFormatedPrice() ?></dt>
 <dd<?php if ($_option->decoratedIsLast){?> class="last"<?php }?>>
     <?php if ($_fileExists): ?>
-        <span class="<?php echo $_fileNamed ?>"><?php echo $_fileInfo->getTitle(); ?></span>
+        <span class="<?php echo $_fileNamed ?>"><?php echo $this->escapeHtml($_fileInfo->getTitle()); ?></span>
         <a href="javascript:void(0)" class="label" onclick="opFile<?php echo $_rand; ?>.toggleFileChange($(this).next('.input-box'))">
             <?php echo Mage::helper('catalog')->__('Change') ?>
         </a>&nbsp;
diff --git app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/creditmemo/name.phtml app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/creditmemo/name.phtml
index 2ede9ce..3ccc2d4 100644
--- app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/creditmemo/name.phtml
+++ app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/creditmemo/name.phtml
@@ -31,7 +31,7 @@
     <?php if ($this->getOrderOptions()): ?>
         <dl class="item-options">
         <?php foreach ($this->getOrderOptions() as $_option): ?>
-            <dt><?php echo $_option['label'] ?></dt>
+            <dt><?php echo $this->escapeHtml($_option['label']) ?></dt>
             <dd>
             <?php if (isset($_option['custom_view']) && $_option['custom_view']): ?>
                 <?php echo $_option['value'];?>
diff --git app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/invoice/name.phtml app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/invoice/name.phtml
index 0171bb4..488f2cd 100644
--- app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/invoice/name.phtml
+++ app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/invoice/name.phtml
@@ -31,7 +31,7 @@
     <?php if ($this->getOrderOptions()): ?>
         <dl class="item-options">
         <?php foreach ($this->getOrderOptions() as $_option): ?>
-            <dt><?php echo $_option['label'] ?></dt>
+            <dt><?php echo $this->escapeHtml($_option['label']) ?></dt>
             <dd>
             <?php if (isset($_option['custom_view']) && $_option['custom_view']): ?>
                 <?php echo $_option['value'];?>
diff --git app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/name.phtml app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/name.phtml
index d9d1d42..3201ded 100644
--- app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/name.phtml
+++ app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/name.phtml
@@ -31,7 +31,7 @@
     <?php if ($this->getOrderOptions()): ?>
         <dl class="item-options">
         <?php foreach ($this->getOrderOptions() as $_option): ?>
-            <dt><?php echo $_option['label'] ?></dt>
+            <dt><?php echo $this->escapeHtml($_option['label']) ?></dt>
             <dd>
             <?php if (isset($_option['custom_view']) && $_option['custom_view']): ?>
                 <?php echo $_option['value'];?>
diff --git app/design/adminhtml/default/default/template/enterprise/checkout/form/coupon.phtml app/design/adminhtml/default/default/template/enterprise/checkout/form/coupon.phtml
index 8aab906..7d37b69 100644
--- app/design/adminhtml/default/default/template/enterprise/checkout/form/coupon.phtml
+++ app/design/adminhtml/default/default/template/enterprise/checkout/form/coupon.phtml
@@ -37,9 +37,9 @@
          <div class="content">
             <p><input type="text" class="input-text" id="coupon_code" name="ccode" style="width:200px" /> <?php echo $this->getApplyButtonHtml() ?></p>
             <?php if($this->getCouponCode()): ?>
-                <p id="cc_info"><strong><?php echo $this->getCouponCode(); ?></strong> [<a href="#" onclick="checkoutObj.applyCoupon();return false;" title="<?php echo $this->__('Remove Coupon Code') ?>"><?php echo $this->__('Remove') ?></a>]</p>
+                <p id="cc_info"><strong><?php echo $this->escapeHtml($this->getCouponCode()); ?></strong> [<a href="#" onclick="checkoutObj.applyCoupon();return false;" title="<?php echo Mage::helper('core')->jsQuoteEscape($this->__('Remove Coupon Code')) ?>"><?php echo $this->__('Remove') ?></a>]</p>
             <?php elseif ($invalid = $this->getInvalidCouponCode()): ?>
-                <p id="cc_info"><strong><?php echo $this->helper('enterprise_checkout')->__('Coupon code "%s" is not valid', $invalid) ?></strong></p>
+                <p id="cc_info"><strong><?php echo $this->escapeHtml($this->helper('enterprise_checkout')->__('Coupon code "%s" is not valid', $invalid)); ?></strong></p>
             <?php endif; ?>
         </div>
     </fieldset>
diff --git app/design/adminhtml/default/default/template/sales/items/column/name.phtml app/design/adminhtml/default/default/template/sales/items/column/name.phtml
index 5b197ae..7565cd3 100644
--- app/design/adminhtml/default/default/template/sales/items/column/name.phtml
+++ app/design/adminhtml/default/default/template/sales/items/column/name.phtml
@@ -36,7 +36,7 @@
     <?php if ($this->getOrderOptions()): ?>
         <dl class="item-options">
         <?php foreach ($this->getOrderOptions() as $_option): ?>
-            <dt><?php echo $_option['label'] ?></dt>
+            <dt><?php echo $this->escapeHtml($_option['label']) ?></dt>
             <dd>
             <?php if (isset($_option['custom_view']) && $_option['custom_view']): ?>
                 <?php echo $this->getCustomizedOptionValue($_option); ?>
diff --git app/design/adminhtml/default/default/template/sales/items/renderer/default.phtml app/design/adminhtml/default/default/template/sales/items/renderer/default.phtml
index 5907efe..efb6c85 100644
--- app/design/adminhtml/default/default/template/sales/items/renderer/default.phtml
+++ app/design/adminhtml/default/default/template/sales/items/renderer/default.phtml
@@ -30,7 +30,7 @@
 <?php if ($this->getOrderOptions()): ?>
     <ul class="item-options">
     <?php foreach ($this->getOrderOptions() as $option): ?>
-        <li><strong><?php echo $option['label'] ?>:</strong><br />
+        <li><strong><?php echo $this->escapeHtml($option['label']) ?>:</strong><br />
         <?php if (is_array($option['value'])): ?>
         <?php foreach ($option['value'] as $item): ?>
             <?php echo $this->getValueHtml($item) ?><br />
diff --git app/design/adminhtml/default/default/template/sales/order/totals/discount.phtml app/design/adminhtml/default/default/template/sales/order/totals/discount.phtml
index fee4679..58334bb 100644
--- app/design/adminhtml/default/default/template/sales/order/totals/discount.phtml
+++ app/design/adminhtml/default/default/template/sales/order/totals/discount.phtml
@@ -32,7 +32,7 @@
     <tr>
         <td class="label">
             <?php if ($_order->getCouponCode()): ?>
-                <?php echo Mage::helper('sales')->__('Discount (%s)', $_order->getCouponCode()) ?>
+                <?php echo Mage::helper('sales')->__('Discount (%s)', $this->escapeHtml($_order->getCouponCode())) ?>
             <?php else: ?>
                 <?php echo Mage::helper('sales')->__('Discount') ?>
             <?php endif; ?>
diff --git app/design/adminhtml/default/default/template/sales/order/view/info.phtml app/design/adminhtml/default/default/template/sales/order/view/info.phtml
index 8dc6452..f6cab5e 100644
--- app/design/adminhtml/default/default/template/sales/order/view/info.phtml
+++ app/design/adminhtml/default/default/template/sales/order/view/info.phtml
@@ -84,7 +84,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
             <?php if($_order->getRemoteIp() && $this->shouldDisplayCustomerIp()): ?>
             <tr>
                 <td class="label"><label><?php echo Mage::helper('sales')->__('Placed from IP') ?></label></td>
-                <td class="value"><strong><?php echo $_order->getRemoteIp(); echo ($_order->getXForwardedFor())?' (' . $this->escapeHtml($_order->getXForwardedFor()) . ')':''; ?></strong></td>
+                <td class="value"><strong><?php echo $this->escapeHtml($_order->getRemoteIp()); echo ($_order->getXForwardedFor())?' (' . $this->escapeHtml($_order->getXForwardedFor()) . ')':''; ?></strong></td>
             </tr>
             <?php endif; ?>
             <?php if($_order->getGlobalCurrencyCode() != $_order->getBaseCurrencyCode()): ?>
@@ -125,7 +125,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
                 </tr>
                 <tr>
                     <td class="label"><label><?php echo Mage::helper('sales')->__('Email') ?></label></td>
-                    <td class="value"><a href="mailto:<?php echo $_order->getCustomerEmail() ?>"><strong><?php echo $_order->getCustomerEmail() ?></strong></a></td>
+                    <td class="value"><a href="mailto:<?php echo $this->escapeHtml($_order->getCustomerEmail()) ?>"><strong><?php echo $this->escapeHtml($_order->getCustomerEmail()) ?></strong></a></td>
                 </tr>
                 <?php if ($_groupName = $this->getCustomerGroupName()) : ?>
                 <tr>
diff --git app/design/frontend/base/default/template/catalog/product/view/options/type/file.phtml app/design/frontend/base/default/template/catalog/product/view/options/type/file.phtml
index 01a18a1..746da1e 100644
--- app/design/frontend/base/default/template/catalog/product/view/options/type/file.phtml
+++ app/design/frontend/base/default/template/catalog/product/view/options/type/file.phtml
@@ -78,7 +78,7 @@
     <?php echo $this->getFormatedPrice() ?></dt>
 <dd<?php if ($_option->decoratedIsLast){?> class="last"<?php }?>>
     <?php if ($_fileExists): ?>
-        <span class="<?php echo $_fileNamed ?>"><?php echo $_fileInfo->getTitle(); ?></span>
+        <span class="<?php echo $_fileNamed ?>"><?php echo $this->escapeHtml($_fileInfo->getTitle()); ?></span>
         <a href="javascript:void(0)" class="label" onclick="opFile<?php echo $_rand; ?>.toggleFileChange($(this).next('.input-box'))">
             <?php echo Mage::helper('catalog')->__('Change') ?>
         </a>&nbsp;
diff --git app/design/frontend/base/default/template/rss/order/details.phtml app/design/frontend/base/default/template/rss/order/details.phtml
index 8617a24..a4ae2df 100644
--- app/design/frontend/base/default/template/rss/order/details.phtml
+++ app/design/frontend/base/default/template/rss/order/details.phtml
@@ -78,7 +78,7 @@ store name = $_order->getStore()->getGroup()->getName()
         </tr>
         <?php if ($_order->getDiscountAmount() > 0): ?>
             <tr>
-                <td colspan="2" align="right" style="padding:3px 9px"><?php echo (($_order->getCouponCode())? $this->__('Discount (%s)', $_order->getCouponCode()) : $this->__('Discount')) ?></td>
+                <td colspan="2" align="right" style="padding:3px 9px"><?php echo (($_order->getCouponCode())? $this->__('Discount (%s)', $this->escapeHtml($_order->getCouponCode())) : $this->__('Discount')) ?></td>
                 <td align="right" style="padding:3px 9px"><?php echo $_order->formatPrice(0.00 - $_order->getDiscountAmount()) ?></td>
             </tr>
         <?php endif; ?>
diff --git lib/Varien/File/Uploader.php lib/Varien/File/Uploader.php
index afe76e9..7c92f87 100644
--- lib/Varien/File/Uploader.php
+++ lib/Varien/File/Uploader.php
@@ -125,6 +125,13 @@ class Varien_File_Uploader
     protected $_allowedExtensions = null;
 
     /**
+     * List of valid MIME-Types.
+     *
+     * @var array
+     */
+    protected $_validMimeTypes = array();
+
+    /**
      * Validate callbacks storage
      *
      * @var array
@@ -209,7 +216,7 @@ class Varien_File_Uploader
         $this->_result = $this->_moveFile($this->_file['tmp_name'], $destinationFile);
 
         if ($this->_result) {
-            chmod($destinationFile, 0777);
+            chmod($destinationFile, 0640);
             if ($this->_enableFilesDispersion) {
                 $fileName = str_replace(DIRECTORY_SEPARATOR, '/',
                     self::_addDirSeparator($this->_dispretionPath)) . $fileName;
@@ -253,6 +260,14 @@ class Varien_File_Uploader
         if (!$this->checkAllowedExtension($this->getFileExtension())) {
             throw new Exception('Disallowed file type.');
         }
+
+        /*
+         * Validate MIME-Types.
+         */
+        if (!$this->checkMimeType($this->_validMimeTypes)) {
+            throw new Exception('Invalid MIME type.');
+        }
+
         //run validate callbacks
         foreach ($this->_validateCallbacks as $params) {
             if (is_object($params['object']) && method_exists($params['object'], $params['method'])) {
@@ -350,14 +365,17 @@ class Varien_File_Uploader
      * @access public
      * @return bool
      */
-    public function checkMimeType($validTypes=Array())
+    public function checkMimeType($validTypes = array())
     {
-        if (count($validTypes) > 0) {
-            if (!in_array($this->_getMimeType(), $validTypes)) {
-                return false;
+        try {
+            if (count($validTypes) > 0) {
+                $validator = new Zend_Validate_File_MimeType($validTypes);
+                return $validator->isValid($this->_file['tmp_name']);
             }
+            return true;
+        } catch (Exception $e) {
+            return false;
         }
-        return true;
     }
 
     /**
@@ -431,6 +449,21 @@ class Varien_File_Uploader
     }
 
     /**
+     * Set valid MIME-types.
+     *
+     * @param array $mimeTypes
+     * @return Varien_File_Uploader
+     */
+    public function setValidMimeTypes($mimeTypes = array())
+    {
+        $this->_validMimeTypes = array();
+        foreach ((array) $mimeTypes as $mimeType) {
+            $this->_validMimeTypes[] = $mimeType;
+        }
+        return $this;
+    }
+
+    /**
      * Check if specified extension is allowed
      *
      * @param string $extension
@@ -505,7 +538,7 @@ class Varien_File_Uploader
             $destinationFolder = substr($destinationFolder, 0, -1);
         }
 
-        if (!(@is_dir($destinationFolder) || @mkdir($destinationFolder, 0777, true))) {
+        if (!(@is_dir($destinationFolder) || @mkdir($destinationFolder, 0750, true))) {
             throw new Exception("Unable to create directory '{$destinationFolder}'.");
         }
         return $this;
diff --git lib/Varien/Io/File.php lib/Varien/Io/File.php
index 8a45a2c..34fdf3b 100644
--- lib/Varien/Io/File.php
+++ lib/Varien/Io/File.php
@@ -227,16 +227,6 @@ class Varien_Io_File extends Varien_Io_Abstract
             return false;
         }
 
-        /**
-         * Security enchancement for CSV data processing by Excel-like applications.
-         * @see https://bugzilla.mozilla.org/show_bug.cgi?id=1054702
-         */
-        foreach ($row as $key => $value) {
-            if (substr($value, 0, 1) === '=') {
-                $row[$key] = ' ' . $value;
-            }
-        }
-
         return @fputcsv($this->_streamHandler, $row, $delimiter, $enclosure);
     }
 
