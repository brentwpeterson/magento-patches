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


SUPEE-7405-CE-1-4-1-1 | CE_1.4.1.1 | v1 | 5c5b0ca6a982a3ee72760dc420018e0ef93762ec | Sat Jan 16 12:06:26 2016 +0200 | 6b4879f6a5..5c5b0ca6a9

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Admin/Model/Mysql4/User.php app/code/core/Mage/Admin/Model/Mysql4/User.php
index 386d7eb..a46566e 100644
--- app/code/core/Mage/Admin/Model/Mysql4/User.php
+++ app/code/core/Mage/Admin/Model/Mysql4/User.php
@@ -121,16 +121,13 @@ class Mage_Admin_Model_Mysql4_User extends Mage_Core_Model_Mysql4_Abstract
 
     protected function _afterSave(Mage_Core_Model_Abstract $user)
     {
-        $user->setExtra(unserialize($user->getExtra()));
+        $this->_unserializeExtraData($user);
         return $this;
     }
 
     protected function _afterLoad(Mage_Core_Model_Abstract $user)
     {
-        if (is_string($user->getExtra())) {
-            $user->setExtra(unserialize($user->getExtra()));
-        }
-        return parent::_afterLoad($user);
+        return parent::_afterLoad($this->_unserializeExtraData($user));
     }
 
     public function load(Mage_Core_Model_Abstract $user, $value, $field=null)
@@ -287,4 +284,21 @@ class Mage_Admin_Model_Mysql4_User extends Mage_Core_Model_Mysql4_Abstract
         }
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
diff --git app/code/core/Mage/Admin/Model/Observer.php app/code/core/Mage/Admin/Model/Observer.php
index 5807834..7552b8e 100644
--- app/code/core/Mage/Admin/Model/Observer.php
+++ app/code/core/Mage/Admin/Model/Observer.php
@@ -33,31 +33,47 @@
  */
 class Mage_Admin_Model_Observer
 {
-    public function actionPreDispatchAdmin($event)
+    public function actionPreDispatchAdmin($observer)
     {
-        $session  = Mage::getSingleton('admin/session');
-        /* @var $session Mage_Admin_Model_Session */
+        /** @var $session Mage_Admin_Model_Session */
+        $session = Mage::getSingleton('admin/session');
 
-        /**
-         * @var $request Mage_Core_Controller_Request_Http
-         */
+        /** @var $request Mage_Core_Controller_Request_Http */
         $request = Mage::app()->getRequest();
         $user = $session->getUser();
 
-        if ($request->getActionName() == 'forgotpassword' || $request->getActionName() == 'logout') {
+        $requestedActionName = strtolower($request->getActionName());
+        $openActions = array(
+            'forgotpassword',
+        );
+        if (in_array($requestedActionName, $openActions)) {
             $request->setDispatched(true);
-        }
-        else {
+        } else {
             if ($user) {
                 $user->reload();
             }
             if (!$user || !$user->getId()) {
                 if ($request->getPost('login')) {
-                    $postLogin  = $request->getPost('login');
-                    $username   = isset($postLogin['username']) ? $postLogin['username'] : '';
-                    $password   = isset($postLogin['password']) ? $postLogin['password'] : '';
-                    $user = $session->login($username, $password, $request);
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
@@ -66,8 +82,7 @@ class Mage_Admin_Model_Observer
                             ->setControllerName('index')
                             ->setActionName('deniedIframe')
                             ->setDispatched(false);
-                    }
-                    elseif ($request->getParam('isAjax')) {
+                    } elseif ($request->getParam('isAjax')) {
                         $request->setParam('forwarded', true)
                             ->setControllerName('index')
                             ->setActionName('deniedJson')
diff --git app/code/core/Mage/Admin/Model/Redirectpolicy.php app/code/core/Mage/Admin/Model/Redirectpolicy.php
new file mode 100644
index 0000000..b31ac91
--- /dev/null
+++ app/code/core/Mage/Admin/Model/Redirectpolicy.php
@@ -0,0 +1,72 @@
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
+ * @package     Mage_Admin
+ * @copyright   Copyright (c) 2014 Magento Inc. (http://www.magentocommerce.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Admin redirect policy model, guard admin from direct link to store/category/product deletion
+ *
+ * @category    Mage
+ * @package     Mage_Admin
+ * @author      Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Admin_Model_Redirectpolicy
+{
+    /**
+     * @var Mage_Adminhtml_Model_Url
+     */
+    protected $_urlModel;
+
+    /**
+     * @param array $parameters array('urlModel' => object)
+     */
+    public function __construct($parameters = array())
+    {
+        /** @var Mage_Adminhtml_Model_Url _urlModel */
+        $this->_urlModel = (!empty($parameters['urlModel'])) ?
+            $parameters['urlModel'] : Mage::getModel('adminhtml/url');
+    }
+
+    /**
+     * Redirect to startup page after logging in if request contains any params (except security key)
+     *
+     * @param Mage_Admin_Model_User $user
+     * @param Zend_Controller_Request_Http $request
+     * @param string|null $alternativeUrl
+     * @return null|string
+     */
+    public function getRedirectUrl(Mage_Admin_Model_User $user, Zend_Controller_Request_Http $request = null,
+                                $alternativeUrl = null)
+    {
+        if (empty($request)) {
+            return;
+        }
+        $countRequiredParams = ($this->_urlModel->useSecretKey()
+            && $request->getParam(Mage_Adminhtml_Model_Url::SECRET_KEY_PARAM_NAME)) ? 1 : 0;
+        $countGetParams = count($request->getUserParams()) + count($request->getQuery());
+
+        return ($countGetParams > $countRequiredParams) ?
+            $this->_urlModel->getUrl($user->getStartupPageUrl()) : $alternativeUrl;
+    }
+}
diff --git app/code/core/Mage/Admin/Model/Session.php app/code/core/Mage/Admin/Model/Session.php
index 7cbebe1..f094990 100644
--- app/code/core/Mage/Admin/Model/Session.php
+++ app/code/core/Mage/Admin/Model/Session.php
@@ -43,11 +43,38 @@ class Mage_Admin_Model_Session extends Mage_Core_Model_Session_Abstract
     protected $_isFirstPageAfterLogin;
 
     /**
+     * @var Mage_Admin_Model_Redirectpolicy
+     */
+    protected $_urlPolicy;
+
+    /**
+     * @var Mage_Core_Controller_Response_Http
+     */
+    protected $_response;
+
+    /**
+     * @var Mage_Core_Model_Factory
+     */
+    protected $_factory;
+
+    /**
      * Class constructor
      *
      */
-    public function __construct()
+    public function __construct($parameters = array())
     {
+        /** @var Mage_Admin_Model_Redirectpolicy _urlPolicy */
+        $this->_urlPolicy = (!empty($parameters['redirectPolicy'])) ?
+            $parameters['redirectPolicy'] : Mage::getModel('admin/redirectpolicy');
+
+        /** @var Mage_Core_Controller_Response_Http _response */
+        $this->_response = (!empty($parameters['response'])) ?
+            $parameters['response'] : new Mage_Core_Controller_Response_Http();
+
+        /** @var $user Mage_Core_Model_Factory */
+        $this->_factory = (!empty($parameters['factory'])) ?
+            $parameters['factory'] : Mage::getModel('core/factory');
+
         $this->init('admin');
     }
 
@@ -87,7 +114,7 @@ class Mage_Admin_Model_Session extends Mage_Core_Model_Session_Abstract
 
         try {
             /* @var $user Mage_Admin_Model_User */
-            $user = Mage::getModel('admin/user');
+            $user = $this->_factory->getModel('admin/user');
             $user->login($username, $password);
             if ($user->getId()) {
 
@@ -97,14 +124,17 @@ class Mage_Admin_Model_Session extends Mage_Core_Model_Session_Abstract
                 $this->setIsFirstPageAfterLogin(true);
                 $this->setUser($user);
                 $this->setAcl(Mage::getResourceModel('admin/acl')->loadAcl());
-                if ($requestUri = $this->_getRequestUri($request)) {
-                    Mage::dispatchEvent('admin_session_user_login_success', array('user'=>$user));
-                    header('Location: ' . $requestUri);
-                    exit;
+
+                $alternativeUrl = $this->_getRequestUri($request);
+                $redirectUrl = $this->_urlPolicy->getRedirectUrl($user, $request, $alternativeUrl);
+                if ($redirectUrl) {
+                    Mage::dispatchEvent('admin_session_user_login_success', array('user' => $user));
+                    $this->_response->clearHeaders()
+                        ->setRedirect($redirectUrl)
+                        ->sendHeadersAndExit();
                 }
-            }
-            else {
-                Mage::throwException(Mage::helper('adminhtml')->__('Invalid Username or Password.'));
+            } else {
+                Mage::throwException(Mage::helper('adminhtml')->__('Invalid User Name or Password.'));
             }
         }
         catch (Mage_Core_Exception $e) {
diff --git app/code/core/Mage/Admin/Model/User.php app/code/core/Mage/Admin/Model/User.php
index 6eecf22..e46d955 100644
--- app/code/core/Mage/Admin/Model/User.php
+++ app/code/core/Mage/Admin/Model/User.php
@@ -375,7 +375,7 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
      */
     public function validate()
     {
-        $errors = array();
+        $errors = new ArrayObject();
 
         if (!Zend_Validate::is($this->getUsername(), 'NotEmpty')) {
             $errors[] = Mage::helper('adminhtml')->__('User Name is required field.');
@@ -405,16 +405,21 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
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
 
 }
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/View/Tab/History.php app/code/core/Mage/Adminhtml/Block/Sales/Order/View/Tab/History.php
index efa07d0..f61422c 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/View/Tab/History.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/View/Tab/History.php
@@ -162,8 +162,14 @@ class Mage_Adminhtml_Block_Sales_Order_View_Tab_History
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
index 98824b0..915d16b 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Grid.php
@@ -1571,4 +1571,5 @@ class Mage_Adminhtml_Block_Widget_Grid extends Mage_Adminhtml_Block_Widget
         $this->_emptyCellLabel = $label;
         return $this;
     }
+
 }
diff --git app/code/core/Mage/Adminhtml/Helper/Catalog/Product/Edit/Action/Attribute.php app/code/core/Mage/Adminhtml/Helper/Catalog/Product/Edit/Action/Attribute.php
index a28c264..baef6df 100644
--- app/code/core/Mage/Adminhtml/Helper/Catalog/Product/Edit/Action/Attribute.php
+++ app/code/core/Mage/Adminhtml/Helper/Catalog/Product/Edit/Action/Attribute.php
@@ -96,7 +96,7 @@ class Mage_Adminhtml_Helper_Catalog_Product_Edit_Action_Attribute extends Mage_C
     {
         $session = Mage::getSingleton('adminhtml/session');
 
-        if ($this->_getRequest()->isPost() && $this->_getRequest()->getActionName()=='edit') {
+        if ($this->_getRequest()->isPost() && strtolower($this->_getRequest()->getActionName()) == 'edit') {
             $session->setProductIds($this->_getRequest()->getParam('product', null));
         }
 
diff --git app/code/core/Mage/Adminhtml/Helper/Sales.php app/code/core/Mage/Adminhtml/Helper/Sales.php
index b1d7dc6..56bd9f5 100644
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
diff --git app/code/core/Mage/Adminhtml/controllers/IndexController.php app/code/core/Mage/Adminhtml/controllers/IndexController.php
index 0ee8cde..b2a071a 100644
--- app/code/core/Mage/Adminhtml/controllers/IndexController.php
+++ app/code/core/Mage/Adminhtml/controllers/IndexController.php
@@ -170,36 +170,43 @@ class Mage_Adminhtml_IndexController extends Mage_Adminhtml_Controller_Action
 
     public function forgotpasswordAction ()
     {
-        $email = $this->getRequest()->getParam('email');
+        $email = '';
         $params = $this->getRequest()->getParams();
-        if (!empty($email) && !empty($params)) {
-            $collection = Mage::getResourceModel('admin/user_collection');
-            /* @var $collection Mage_Admin_Model_Mysql4_User_Collection */
-            $collection->addFieldToFilter('email', $email);
-            $collection->load(false);
-
-            if ($collection->getSize() > 0) {
-                foreach ($collection as $item) {
-                    $user = Mage::getModel('admin/user')->load($item->getId());
-                    if ($user->getId()) {
-                        $pass = substr(md5(uniqid(rand(), true)), 0, 7);
-                        $user->setPassword($pass);
-                        $user->save();
-                        $user->setPlainPassword($pass);
-                        $user->sendNewPasswordEmail();
-                        Mage::getSingleton('adminhtml/session')->addSuccess(Mage::helper('adminhtml')->__('A new password was sent to your email address. Please check your email and click Back to Login.'));
-                        $email = '';
+        if (!empty($params)) {
+            $email = (string)$this->getRequest()->getParam('email');
+
+            if ($this->_validateFormKey()) {
+                if (!empty($email)) {
+                    $collection = Mage::getResourceModel('admin/user_collection');
+                    /* @var $collection Mage_Admin_Model_Mysql4_User_Collection */
+                    $collection->addFieldToFilter('email', $email);
+                    $collection->load(false);
+
+                    if ($collection->getSize() > 0) {
+                        foreach ($collection as $item) {
+                            $user = Mage::getModel('admin/user')->load($item->getId());
+                            if ($user->getId()) {
+                                $pass = Mage::helper('core')->getRandomString(7);
+                                $user->setPassword($pass);
+                                $user->save();
+                                $user->setPlainPassword($pass);
+                                $user->sendNewPasswordEmail();
+                                Mage::getSingleton('adminhtml/session')->addSuccess(Mage::helper('adminhtml')->__('A new password was sent to your email address. Please check your email and click Back to Login.'));
+                                $email = '';
+                            }
+                            break;
+                        }
+                    } else {
+                        Mage::getSingleton('adminhtml/session')->addError(Mage::helper('adminhtml')->__('Cannot find the email address.'));
                     }
-                    break;
+                } else {
+                    $this->_getSession()->addError($this->__('Invalid email address.'));
                 }
             } else {
-                Mage::getSingleton('adminhtml/session')->addError(Mage::helper('adminhtml')->__('Cannot find the email address.'));
+                $this->_getSession()->addError($this->__('Invalid Form Key. Please refresh the page.'));
             }
-        } elseif (!empty($params)) {
-            Mage::getSingleton('adminhtml/session')->addError(Mage::helper('adminhtml')->__('The email address is empty.'));
         }
 
-
         $data = array(
             'email' => $email
         );
diff --git app/code/core/Mage/Catalog/Block/Product/View/Options/Type/Select.php app/code/core/Mage/Catalog/Block/Product/View/Options/Type/Select.php
index 382103a..5841141 100644
--- app/code/core/Mage/Catalog/Block/Product/View/Options/Type/Select.php
+++ app/code/core/Mage/Catalog/Block/Product/View/Options/Type/Select.php
@@ -103,7 +103,7 @@ class Mage_Catalog_Block_Product_View_Options_Type_Select
                 ));
                 $selectHtml .= '<li>' .
                                '<input type="'.$type.'" class="'.$class.' '.$require.' product-custom-option" onclick="opConfig.reloadPrice()" name="options['.$_option->getId().']'.$arraySign.'" id="options_'.$_option->getId().'_'.$count.'" value="'.$_value->getOptionTypeId().'" />' .
-                               '<span class="label"><label for="options_'.$_option->getId().'_'.$count.'">'.$_value->getTitle().' '.$priceStr.'</label></span>';
+                               '<span class="label"><label for="options_'.$_option->getId().'_'.$count.'">' . $this->escapeHtml($_value->getTitle()) . ' '.$priceStr.'</label></span>';
                 if ($_option->getIsRequire()) {
                     $selectHtml .= '<script type="text/javascript">' .
                                     '$(\'options_'.$_option->getId().'_'.$count.'\').advaiceContainer = \'options-'.$_option->getId().'-container\';' .
diff --git app/code/core/Mage/Checkout/Block/Cart/Item/Renderer.php app/code/core/Mage/Checkout/Block/Cart/Item/Renderer.php
index 7540749..609aac8 100644
--- app/code/core/Mage/Checkout/Block/Cart/Item/Renderer.php
+++ app/code/core/Mage/Checkout/Block/Cart/Item/Renderer.php
@@ -216,6 +216,7 @@ class Mage_Checkout_Block_Cart_Item_Renderer extends Mage_Core_Block_Template
             'checkout/cart/delete',
             array(
                 'id'=>$this->getItem()->getId(),
+                'form_key' => Mage::getSingleton('core/session')->getFormKey(),
                 Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->helper('core/url')->getEncodedUrl()
             )
         );
diff --git app/code/core/Mage/Checkout/controllers/CartController.php app/code/core/Mage/Checkout/controllers/CartController.php
index 23a5b0f..3dc4fc4 100644
--- app/code/core/Mage/Checkout/controllers/CartController.php
+++ app/code/core/Mage/Checkout/controllers/CartController.php
@@ -85,7 +85,7 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
 
             $this->getResponse()->setRedirect($backUrl);
         } else {
-            if (($this->getRequest()->getActionName() == 'add') && !$this->getRequest()->getParam('in_cart')) {
+            if ((strtolower($this->getRequest()->getActionName()) == 'add') && !$this->getRequest()->getParam('in_cart')) {
                 $this->_getSession()->setContinueShoppingUrl($this->_getRefererUrl());
             }
             $this->_redirect('checkout/cart');
@@ -294,15 +294,21 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
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
index 2ce1b12..859d255 100644
--- app/code/core/Mage/Checkout/controllers/OnepageController.php
+++ app/code/core/Mage/Checkout/controllers/OnepageController.php
@@ -65,7 +65,7 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
             $this->_ajaxRedirectResponse();
             return true;
         }
-        $action = $this->getRequest()->getActionName();
+        $action = strtolower($this->getRequest()->getActionName());
         if (Mage::getSingleton('checkout/session')->getCartWasUpdated(true)
             && !in_array($action, array('index', 'progress'))) {
             $this->_ajaxRedirectResponse();
diff --git app/code/core/Mage/Core/Controller/Response/Http.php app/code/core/Mage/Core/Controller/Response/Http.php
index e871cf3..47fa0ea 100644
--- app/code/core/Mage/Core/Controller/Response/Http.php
+++ app/code/core/Mage/Core/Controller/Response/Http.php
@@ -74,4 +74,13 @@ class Mage_Core_Controller_Response_Http extends Zend_Controller_Response_Http
         Mage::dispatchEvent('http_response_send_before', array('response'=>$this));
         return parent::sendResponse();
     }
+
+    /**
+     * Method send already collected headers and exit from script
+     */
+    public function sendHeadersAndExit()
+    {
+        $this->sendHeaders();
+        exit;
+    }
 }
diff --git app/code/core/Mage/Core/Model/App.php app/code/core/Mage/Core/Model/App.php
index 9907a4c..58a884b 100644
--- app/code/core/Mage/Core/Model/App.php
+++ app/code/core/Mage/Core/Model/App.php
@@ -1163,6 +1163,7 @@ class Mage_Core_Model_App
 
     public function dispatchEvent($eventName, $args)
     {
+        $eventName = strtolower($eventName);
         foreach ($this->_events as $area=>$events) {
             if (!isset($events[$eventName])) {
                 $eventConfig = $this->getConfig()->getEventConfig($area, $eventName);
diff --git app/code/core/Mage/Core/Model/Config.php app/code/core/Mage/Core/Model/Config.php
index e1ad6d1..7cfd36d 100644
--- app/code/core/Mage/Core/Model/Config.php
+++ app/code/core/Mage/Core/Model/Config.php
@@ -858,6 +858,10 @@ class Mage_Core_Model_Config extends Mage_Core_Model_Config_Base
                 }
                 $configFile = $this->getModuleDir('etc', $modName).DS.$fileName;
                 if ($mergeModel->loadFile($configFile)) {
+                    $this->_makeEventsLowerCase(Mage_Core_Model_App_Area::AREA_GLOBAL, $mergeModel);
+                    $this->_makeEventsLowerCase(Mage_Core_Model_App_Area::AREA_FRONTEND, $mergeModel);
+                    $this->_makeEventsLowerCase(Mage_Core_Model_App_Area::AREA_ADMIN, $mergeModel);
+
                     $mergeToObject->extend($mergeModel, true);
                 }
             }
@@ -1051,7 +1055,7 @@ class Mage_Core_Model_Config extends Mage_Core_Model_Config_Base
         }
 
         foreach ($events as $event) {
-            $eventName = $event->getName();
+            $eventName = strtolower($event->getName());
             $observers = $event->observers->children();
             foreach ($observers as $observer) {
                 switch ((string)$observer->type) {
@@ -1471,4 +1475,42 @@ class Mage_Core_Model_Config extends Mage_Core_Model_Config_Base
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
index ed9e683..04534cb 100644
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
diff --git app/code/core/Mage/Core/Model/Factory.php app/code/core/Mage/Core/Model/Factory.php
new file mode 100644
index 0000000..e5073f2
--- /dev/null
+++ app/code/core/Mage/Core/Model/Factory.php
@@ -0,0 +1,144 @@
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
+ * @package     Mage_Core
+ * @copyright Copyright (c) 2006-2015 X.commerce, Inc. (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Factory class
+ *
+ * @category    Mage
+ * @package     Mage_Core
+ * @author      Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Core_Model_Factory
+{
+    /**
+     * Xml path to url rewrite model class alias
+     */
+    const XML_PATH_URL_REWRITE_MODEL = 'global/url_rewrite/model';
+
+    const XML_PATH_INDEX_INDEX_MODEL = 'global/index/index_model';
+
+    /**
+     * Config instance
+     *
+     * @var Mage_Core_Model_Config
+     */
+    protected $_config;
+
+    /**
+     * Initialize factory
+     *
+     * @param array $arguments
+     */
+    public function __construct(array $arguments = array())
+    {
+        $this->_config = !empty($arguments['config']) ? $arguments['config'] : Mage::getConfig();
+    }
+
+    /**
+     * Retrieve model object
+     *
+     * @param string $modelClass
+     * @param array|object $arguments
+     * @return bool|Mage_Core_Model_Abstract
+     */
+    public function getModel($modelClass = '', $arguments = array())
+    {
+        return Mage::getModel($modelClass, $arguments);
+    }
+
+    /**
+     * Retrieve model object singleton
+     *
+     * @param string $modelClass
+     * @param array $arguments
+     * @return Mage_Core_Model_Abstract
+     */
+    public function getSingleton($modelClass = '', array $arguments = array())
+    {
+        return Mage::getSingleton($modelClass, $arguments);
+    }
+
+    /**
+     * Retrieve object of resource model
+     *
+     * @param string $modelClass
+     * @param array $arguments
+     * @return Object
+     */
+    public function getResourceModel($modelClass, $arguments = array())
+    {
+        return Mage::getResourceModel($modelClass, $arguments);
+    }
+
+    /**
+     * Retrieve helper instance
+     *
+     * @param string $helperClass
+     * @return Mage_Core_Helper_Abstract
+     */
+    public function getHelper($helperClass)
+    {
+        return Mage::helper($helperClass);
+    }
+
+    /**
+     * Get config instance
+     *
+     * @return Mage_Core_Model_Config
+     */
+    public function getConfig()
+    {
+        return $this->_config;
+    }
+
+    /**
+     * Retrieve url_rewrite instance
+     *
+     * @return Mage_Core_Model_Url_Rewrite
+     */
+    public function getUrlRewriteInstance()
+    {
+        return $this->getModel($this->getUrlRewriteClassAlias());
+    }
+
+    /**
+     * Retrieve alias for url_rewrite model
+     *
+     * @return string
+     */
+    public function getUrlRewriteClassAlias()
+    {
+        return (string)$this->_config->getNode(self::XML_PATH_URL_REWRITE_MODEL);
+    }
+
+    /**
+     * @return string
+     */
+    public function getIndexClassAlias()
+    {
+        return (string)$this->_config->getNode(self::XML_PATH_INDEX_INDEX_MODEL);
+    }
+}
diff --git app/code/core/Mage/Core/Model/Session.php app/code/core/Mage/Core/Model/Session.php
index 3f708da..c047b1a 100644
--- app/code/core/Mage/Core/Model/Session.php
+++ app/code/core/Mage/Core/Model/Session.php
@@ -33,7 +33,7 @@
  */
 class Mage_Core_Model_Session extends Mage_Core_Model_Session_Abstract
 {
-    public function __construct($data=array())
+    public function __construct($data = array())
     {
         $name = isset($data['name']) ? $data['name'] : null;
         $this->init('core', $name);
@@ -47,8 +47,27 @@ class Mage_Core_Model_Session extends Mage_Core_Model_Session_Abstract
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
index 5f8cc6e..ae91bdf 100644
--- app/code/core/Mage/Customer/controllers/AccountController.php
+++ app/code/core/Mage/Customer/controllers/AccountController.php
@@ -65,8 +65,19 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             return;
         }
 
-        $action = $this->getRequest()->getActionName();
-        if (!preg_match('/^(create|login|logoutSuccess|forgotpassword|forgotpasswordpost|confirm|confirmation)/i', $action)) {
+        $action = strtolower($this->getRequest()->getActionName());
+        $openActions = array(
+            'create',
+            'login',
+            'logoutsuccess',
+            'forgotpassword',
+            'forgotpasswordpost',
+            'confirm',
+            'confirmation'
+        );
+        $pattern = '/^(' . implode('|', $openActions) . ')/i';
+
+        if (!preg_match($pattern, $action)) {
             if (!$this->_getSession()->authenticate($this)) {
                 $this->setFlag('', 'no-dispatch', true);
             }
diff --git app/code/core/Mage/Downloadable/controllers/CustomerController.php app/code/core/Mage/Downloadable/controllers/CustomerController.php
index 652e703..3467888 100644
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
diff --git app/code/core/Mage/Newsletter/Model/Observer.php app/code/core/Mage/Newsletter/Model/Observer.php
index 139324e..8ee86eb 100644
--- app/code/core/Mage/Newsletter/Model/Observer.php
+++ app/code/core/Mage/Newsletter/Model/Observer.php
@@ -61,6 +61,7 @@ class Mage_Newsletter_Model_Observer
         $countOfQueue  = 3;
         $countOfSubscritions = 20;
 
+        /** @var Mage_Newsletter_Model_Resource_Queue_Collection $collection */
         $collection = Mage::getModel('newsletter/queue')->getCollection()
             ->setPageSize($countOfQueue)
             ->setCurPage(1)
diff --git app/code/core/Mage/Review/controllers/ProductController.php app/code/core/Mage/Review/controllers/ProductController.php
index 922542e..ae7f4b3 100644
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
@@ -160,9 +160,9 @@ class Mage_Review_ProductController extends Mage_Core_Controller_Front_Action
         }
 
         if (($product = $this->_initProduct()) && !empty($data)) {
-            $session    = Mage::getSingleton('core/session');
+            $session = Mage::getSingleton('core/session');
             /* @var $session Mage_Core_Model_Session */
-            $review     = Mage::getModel('review/review')->setData($data);
+            $review = Mage::getModel('review/review')->setData($this->_cropReviewData($data));
             /* @var $review Mage_Review_Model_Review */
 
             $validate = $review->validate();
@@ -290,5 +290,24 @@ class Mage_Review_ProductController extends Mage_Core_Controller_Front_Action
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
index aebe251..e774c91 100644
--- app/code/core/Mage/Rss/Block/Catalog/Salesrule.php
+++ app/code/core/Mage/Rss/Block/Catalog/Salesrule.php
@@ -83,7 +83,7 @@ class Mage_Rss_Block_Catalog_Salesrule extends Mage_Rss_Block_Abstract
             '<td style="text-decoration:none;">'.$sr->getDescription().
             '<br/>Discount Start Date: '.$this->formatDate($sr->getFromDate(), 'medium').
             ( $sr->getToDate() ? ('<br/>Discount End Date: '.$this->formatDate($sr->getToDate(), 'medium')):'').
-            ($sr->getCouponCode() ? '<br/> Coupon Code: '.$sr->getCouponCode().'' : '').
+            ($sr->getCouponCode() ? '<br/> Coupon Code: '. $this->escapeHtml($sr->getCouponCode()).'' : '').
             '</td>'.
             '</tr></table>';
              $data = array(
diff --git app/code/core/Mage/Sales/Model/Quote/Address.php app/code/core/Mage/Sales/Model/Quote/Address.php
index 876a634..ab58a61 100644
--- app/code/core/Mage/Sales/Model/Quote/Address.php
+++ app/code/core/Mage/Sales/Model/Quote/Address.php
@@ -867,7 +867,12 @@ class Mage_Sales_Model_Quote_Address extends Mage_Customer_Model_Address_Abstrac
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
index c8d0d4e..748a9f8 100644
--- app/code/core/Mage/Sales/Model/Quote/Item.php
+++ app/code/core/Mage/Sales/Model/Quote/Item.php
@@ -362,25 +362,34 @@ class Mage_Sales_Model_Quote_Item extends Mage_Sales_Model_Quote_Item_Abstract
             }
             if ($itemOption = $item->getOptionByCode($option->getCode())) {
                 $itemOptionValue = $itemOption->getValue();
-                $optionValue     = $option->getValue();
+                $optionValue = $option->getValue();
 
                 // dispose of some options params, that can cramp comparing of arrays
                 if (is_string($itemOptionValue) && is_string($optionValue)) {
-                    $_itemOptionValue = @unserialize($itemOptionValue);
-                    $_optionValue     = @unserialize($optionValue);
-                    if (is_array($_itemOptionValue) && is_array($_optionValue)) {
-                        $itemOptionValue = $_itemOptionValue;
-                        $optionValue     = $_optionValue;
-                        // looks like it does not break bundle selection qty
-                        unset($itemOptionValue['qty'], $itemOptionValue['uenc'], $optionValue['qty'], $optionValue['uenc']);
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
 
                 if ($itemOptionValue != $optionValue) {
                     return false;
                 }
-            }
-            else {
+            } else {
                 return false;
             }
         }
diff --git app/code/core/Zend/Xml/Security.php app/code/core/Zend/Xml/Security.php
index a3cdbc8..8b697b9 100644
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
diff --git app/design/adminhtml/default/default/template/bundle/sales/creditmemo/create/items/renderer.phtml app/design/adminhtml/default/default/template/bundle/sales/creditmemo/create/items/renderer.phtml
index a6a5091..1c70560 100644
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
index 5b2a1d9..b512732 100644
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
index df18c2c..736fdbc 100644
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
index b878710..04f1506 100644
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
index dadde15..ed5e7a9 100644
--- app/design/adminhtml/default/default/template/bundle/sales/order/view/items/renderer.phtml
+++ app/design/adminhtml/default/default/template/bundle/sales/order/view/items/renderer.phtml
@@ -378,7 +378,7 @@
             <?php if ($this->getOrderOptions()): ?>
                 <dl class="item-options">
                 <?php foreach ($this->getOrderOptions() as $option): ?>
-                    <dt><?php echo $option['label'] ?>:</dt>
+                    <dt><?php echo $this->escapeHtml($option['label']) ?>:</dt>
                     <dd>
                     <?php if (isset($option['custom_view']) && $option['custom_view']): ?>
                         <?php echo $option['value'];?>
diff --git app/design/adminhtml/default/default/template/bundle/sales/shipment/create/items/renderer.phtml app/design/adminhtml/default/default/template/bundle/sales/shipment/create/items/renderer.phtml
index 8bf03a6..9330872 100644
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
index 45f62d5..9c90572 100644
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
diff --git app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/creditmemo/name.phtml app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/creditmemo/name.phtml
index 6f04c73..f1924d8 100644
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
index be285e3..b83ca27 100644
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
index 09c53b5..b494aff 100644
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
diff --git app/design/adminhtml/default/default/template/sales/items/column/name.phtml app/design/adminhtml/default/default/template/sales/items/column/name.phtml
index 3f4d584..978a3a6 100644
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
index a8a0235..2533fe1 100644
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
index 4e92f43..23dd674 100644
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
index 8b3f33a..84dbe94 100644
--- app/design/adminhtml/default/default/template/sales/order/view/info.phtml
+++ app/design/adminhtml/default/default/template/sales/order/view/info.phtml
@@ -84,7 +84,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
             <?php if($_order->getRemoteIp()): ?>
             <tr>
                 <td class="label"><label><?php echo Mage::helper('sales')->__('Placed from IP') ?></label></td>
-                <td><strong><?php echo $_order->getRemoteIp(); echo ($_order->getXForwardedFor())?' (' . $_order->getXForwardedFor() . ')':''; ?></strong></td>
+                <td><strong><?php echo $this->escapeHtml($_order->getRemoteIp()); echo ($_order->getXForwardedFor())?' (' . $this->escapeHtml($_order->getXForwardedFor()) . ')':''; ?></strong></td>
             </tr>
             <?php endif; ?>
             <?php if($_order->getGlobalCurrencyCode() != $_order->getBaseCurrencyCode()): ?>
@@ -124,7 +124,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
                 </tr>
                 <tr>
                     <td class="label"><label><?php echo Mage::helper('sales')->__('Email') ?></label></td>
-                    <td><a href="mailto:<?php echo $_order->getCustomerEmail() ?>"><strong><?php echo $_order->getCustomerEmail() ?></strong></a></td>
+                    <td><a href="mailto:<?php echo $this->escapeHtml($_order->getCustomerEmail()) ?>"><strong><?php echo $this->escapeHtml($_order->getCustomerEmail()) ?></strong></a></td>
                 </tr>
                 <?php if ($_groupName=$this->getCustomerGroupName()) : ?>
                 <tr>
diff --git app/design/frontend/base/default/template/rss/order/details.phtml app/design/frontend/base/default/template/rss/order/details.phtml
index a21b4c3..78797e0 100644
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
