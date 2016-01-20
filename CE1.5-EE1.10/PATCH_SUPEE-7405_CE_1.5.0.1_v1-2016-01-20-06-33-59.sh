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


SUPEE-7405-CE-1-5-0-1 | CE_1.5.0.1 | v1 | 14e161286acde4589ada31bf4df0ccb1827806ca | Tue Jan 19 16:18:54 2016 +0200 | 4bcf2cc30a..14e161286a

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
index 0000000..2dad8af
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
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
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
index faea3ad..6411ca2 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Grid.php
@@ -950,7 +950,10 @@ class Mage_Adminhtml_Block_Widget_Grid extends Mage_Adminhtml_Block_Widget
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
@@ -980,7 +983,9 @@ class Mage_Adminhtml_Block_Widget_Grid extends Mage_Adminhtml_Block_Widget
         $this->_exportIterateCollection('_exportCsvItem', array($io));
 
         if ($this->getCountTotals()) {
-            $io->streamWriteCsv($this->_getExportTotals());
+            $io->streamWriteCsv(
+                Mage::helper("core")->getEscapedCSVData($this->_getExportTotals())
+            );
         }
 
         $io->streamUnlock();
@@ -1622,5 +1627,4 @@ class Mage_Adminhtml_Block_Widget_Grid extends Mage_Adminhtml_Block_Widget
         $res = parent::getRowUrl($item);
         return ($res ? $res : '#');
     }
-
 }
diff --git app/code/core/Mage/Adminhtml/Helper/Catalog/Product/Edit/Action/Attribute.php app/code/core/Mage/Adminhtml/Helper/Catalog/Product/Edit/Action/Attribute.php
index 8907d55..0a0ca9a 100644
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
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/File.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/File.php
index 304e85b..d78323b 100644
--- app/code/core/Mage/Adminhtml/Model/System/Config/Backend/File.php
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/File.php
@@ -47,7 +47,7 @@ class Mage_Adminhtml_Model_System_Config_Backend_File extends Mage_Core_Model_Co
             $this->setValue('');
         }
 
-        if ($_FILES['groups']['tmp_name'][$this->getGroupId()]['fields'][$this->getField()]['value']){
+        if ($_FILES['groups']['tmp_name'][$this->getGroupId()]['fields'][$this->getField()]['value']) {
 
             $uploadDir = $this->_getUploadDir();
 
@@ -63,6 +63,7 @@ class Mage_Adminhtml_Model_System_Config_Backend_File extends Mage_Core_Model_Co
                 $uploader = new Varien_File_Uploader($file);
                 $uploader->setAllowedExtensions($this->_getAllowedExtensions());
                 $uploader->setAllowRenameFiles(true);
+                $this->addValidators( $uploader );
                 $result = $uploader->save($uploadDir);
 
                 $result['file'] = Mage::helper('core/file_storage_database')->saveUploadedFile($result);
@@ -188,4 +189,14 @@ class Mage_Adminhtml_Model_System_Config_Backend_File extends Mage_Core_Model_Co
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
index d741344..4bc8a341 100644
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
index 9ce363b..3f0d204 100644
--- app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Image/Favicon.php
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Image/Favicon.php
@@ -44,7 +44,7 @@ class Mage_Adminhtml_Model_System_Config_Backend_Image_Favicon extends Mage_Admi
      * Token for the root part of directory path for uploading
      * 
      */
-    const UPLOAD_ROOT = 'system/filesystem/media';
+    const UPLOAD_ROOT = 'media';
 
     /**
      * Return path to directory for upload file
@@ -77,6 +77,17 @@ class Mage_Adminhtml_Model_System_Config_Backend_Image_Favicon extends Mage_Admi
      */
     protected function _getAllowedExtensions()
     {
-        return array('ico', 'png', 'gif', 'jpeg', 'apng', 'svg');
+        return array('ico', 'png', 'gif', 'jpg', 'jpeg', 'apng');
+    }
+
+    /**
+     * Get real media dir path
+     *
+     * @param  $token
+     * @return string
+     */
+    protected function _getUploadRoot($token)
+    {
+        return Mage::getBaseDir($token);
     }
 }
diff --git app/code/core/Mage/Adminhtml/controllers/IndexController.php app/code/core/Mage/Adminhtml/controllers/IndexController.php
index 7472170..6821794 100644
--- app/code/core/Mage/Adminhtml/controllers/IndexController.php
+++ app/code/core/Mage/Adminhtml/controllers/IndexController.php
@@ -178,36 +178,43 @@ class Mage_Adminhtml_IndexController extends Mage_Adminhtml_Controller_Action
 
     public function forgotpasswordAction()
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
diff --git app/code/core/Mage/Authorizenet/Helper/Admin.php app/code/core/Mage/Authorizenet/Helper/Admin.php
new file mode 100644
index 0000000..d808ff2
--- /dev/null
+++ app/code/core/Mage/Authorizenet/Helper/Admin.php
@@ -0,0 +1,77 @@
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
+ * @package     Mage_Authorizenet
+ * @copyright   Copyright (c) 2006-2015 X.commerce, Inc. (http://www.magento.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
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
index aacbb22..54c3a3a 100755
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
@@ -147,25 +119,7 @@ class Mage_Authorizenet_Helper_Data extends Mage_Core_Helper_Abstract
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
index 9c35b15..d44f3b4 100644
--- app/code/core/Mage/Authorizenet/controllers/Adminhtml/Authorizenet/Directpost/PaymentController.php
+++ app/code/core/Mage/Authorizenet/controllers/Adminhtml/Authorizenet/Directpost/PaymentController.php
@@ -85,9 +85,9 @@ class Mage_Authorizenet_Adminhtml_Authorizenet_Directpost_PaymentController exte
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
@@ -167,7 +167,7 @@ class Mage_Authorizenet_Adminhtml_Authorizenet_Directpost_PaymentController exte
             && isset($redirectParams['x_invoice_num'])
             && isset($redirectParams['controller_action_name'])
         ) {
-            $params['redirect_parent'] = Mage::helper('authorizenet')->getSuccessOrderUrl($redirectParams);
+            $params['redirect_parent'] = Mage::helper('authorizenet/admin')->getSuccessOrderUrl($redirectParams);
             $this->_getDirectPostSession()->unsetData('quote_id');
             //cancel old order
             $oldOrder = $this->_getOrderCreateModel()->getSession()->getOrder();
diff --git app/code/core/Mage/Catalog/Block/Product/View/Options/Type/Select.php app/code/core/Mage/Catalog/Block/Product/View/Options/Type/Select.php
index a10549c..abad7f8 100644
--- app/code/core/Mage/Catalog/Block/Product/View/Options/Type/Select.php
+++ app/code/core/Mage/Catalog/Block/Product/View/Options/Type/Select.php
@@ -126,7 +126,7 @@ class Mage_Catalog_Block_Product_View_Options_Type_Select
 
                 $selectHtml .= '<li>' .
                                '<input type="'.$type.'" class="'.$class.' '.$require.' product-custom-option"' . ($this->getSkipJsReloadPrice() ? '' : ' onclick="opConfig.reloadPrice()"') . ' name="options['.$_option->getId().']'.$arraySign.'" id="options_'.$_option->getId().'_'.$count.'" value="' . $htmlValue . '" ' . $checked . ' price="' . $this->helper('core')->currencyByStore($_value->getPrice(true), $store, false) . '" />' .
-                               '<span class="label"><label for="options_'.$_option->getId().'_'.$count.'">'.$_value->getTitle().' '.$priceStr.'</label></span>';
+                               '<span class="label"><label for="options_'.$_option->getId().'_'.$count.'">'. $this->escapeHtml($_value->getTitle()) . ' '.$priceStr.'</label></span>';
                 if ($_option->getIsRequire()) {
                     $selectHtml .= '<script type="text/javascript">' .
                                     '$(\'options_'.$_option->getId().'_'.$count.'\').advaiceContainer = \'options-'.$_option->getId().'-container\';' .
diff --git app/code/core/Mage/Catalog/Model/Category/Attribute/Backend/Image.php app/code/core/Mage/Catalog/Model/Category/Attribute/Backend/Image.php
index d30e3aa..db61811 100644
--- app/code/core/Mage/Catalog/Model/Category/Attribute/Backend/Image.php
+++ app/code/core/Mage/Catalog/Model/Category/Attribute/Backend/Image.php
@@ -57,6 +57,11 @@ class Mage_Catalog_Model_Category_Attribute_Backend_Image extends Mage_Eav_Model
             $uploader = new Varien_File_Uploader($this->getAttribute()->getName());
             $uploader->setAllowedExtensions(array('jpg','jpeg','gif','png'));
             $uploader->setAllowRenameFiles(true);
+            $uploader->addValidateCallback(
+                Mage_Core_Model_File_Validator_Image::NAME,
+                new Mage_Core_Model_File_Validator_Image(),
+                "validate"
+            );
             $result = $uploader->save($path);
             $result['file'] = Mage::helper('core/file_storage_database')->saveUploadedFile($result);
 
diff --git app/code/core/Mage/Catalog/Model/Resource/Eav/Mysql4/Product/Attribute/Backend/Image.php app/code/core/Mage/Catalog/Model/Resource/Eav/Mysql4/Product/Attribute/Backend/Image.php
index 66b16ed..65b06b1 100644
--- app/code/core/Mage/Catalog/Model/Resource/Eav/Mysql4/Product/Attribute/Backend/Image.php
+++ app/code/core/Mage/Catalog/Model/Resource/Eav/Mysql4/Product/Attribute/Backend/Image.php
@@ -50,18 +50,24 @@ class Mage_Catalog_Model_Resource_Eav_Mysql4_Product_Attribute_Backend_Image ext
             $uploader->setAllowedExtensions(array('jpg','jpeg','gif','png'));
             $uploader->setAllowRenameFiles(true);
             $uploader->setFilesDispersion(true);
-        }
-        catch (Exception $e){
-            return $this;
-        }
-        $uploader->save(Mage::getStoreConfig('system/filesystem/media').'/catalog/product');
+            $uploader->addValidateCallback(
+                Mage_Core_Model_File_Validator_Image::NAME,
+                new Mage_Core_Model_File_Validator_Image(),
+                "validate"
+            );
+            $uploader->save(Mage::getStoreConfig('system/filesystem/media').'/catalog/product');
 
-        if ($fileName = $uploader->getUploadedFileName()) {
-            $object->setData($this->getAttribute()->getName(), $fileName);
-            $this->getAttribute()->getEntity()
-                ->saveAttribute($object, $this->getAttribute()->getName());
+            if ($fileName = $uploader->getUploadedFileName()) {
+                $object->setData($this->getAttribute()->getName(), $fileName);
+                $this->getAttribute()->getEntity()
+                    ->saveAttribute($object, $this->getAttribute()->getName());
+
+            }
 
+        } catch (Exception $e){
+            return $this;
         }
+        
         return $this;
     }
 }
diff --git app/code/core/Mage/CatalogInventory/Helper/Minsaleqty.php app/code/core/Mage/CatalogInventory/Helper/Minsaleqty.php
index bea9b52..d301c27 100644
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
index 62ae265..2b4d8d7 100644
--- app/code/core/Mage/Checkout/Block/Cart/Item/Renderer.php
+++ app/code/core/Mage/Checkout/Block/Cart/Item/Renderer.php
@@ -207,6 +207,7 @@ class Mage_Checkout_Block_Cart_Item_Renderer extends Mage_Core_Block_Template
             'checkout/cart/delete',
             array(
                 'id'=>$this->getItem()->getId(),
+                'form_key' => Mage::getSingleton('core/session')->getFormKey(),
                 Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->helper('core/url')->getEncodedUrl()
             )
         );
diff --git app/code/core/Mage/Checkout/controllers/CartController.php app/code/core/Mage/Checkout/controllers/CartController.php
index a3abaaf..4a78966 100644
--- app/code/core/Mage/Checkout/controllers/CartController.php
+++ app/code/core/Mage/Checkout/controllers/CartController.php
@@ -86,7 +86,7 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
         ) {
             $this->getResponse()->setRedirect($backUrl);
         } else {
-            if (($this->getRequest()->getActionName() == 'add') && !$this->getRequest()->getParam('in_cart')) {
+            if ((strtolower($this->getRequest()->getActionName()) == 'add') && !$this->getRequest()->getParam('in_cart')) {
                 $this->_getSession()->setContinueShoppingUrl($this->_getRefererUrl());
             }
             $this->_redirect('checkout/cart');
@@ -401,16 +401,21 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
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
index 7783698..94cd5e3 100644
--- app/code/core/Mage/Checkout/controllers/OnepageController.php
+++ app/code/core/Mage/Checkout/controllers/OnepageController.php
@@ -72,7 +72,7 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
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
diff --git app/code/core/Mage/Core/Helper/Data.php app/code/core/Mage/Core/Helper/Data.php
index cf949d6..7cacc11 100644
--- app/code/core/Mage/Core/Helper/Data.php
+++ app/code/core/Mage/Core/Helper/Data.php
@@ -729,4 +729,49 @@ XML;
     {
         return Mage::getStoreConfig(self::XML_PATH_DEFAULT_COUNTRY, $store);
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
index c996950..6436233 100644
--- app/code/core/Mage/Core/Model/App.php
+++ app/code/core/Mage/Core/Model/App.php
@@ -1200,6 +1200,7 @@ class Mage_Core_Model_App
 
     public function dispatchEvent($eventName, $args)
     {
+        $eventName = strtolower($eventName);
         foreach ($this->_events as $area=>$events) {
             if (!isset($events[$eventName])) {
                 $eventConfig = $this->getConfig()->getEventConfig($area, $eventName);
diff --git app/code/core/Mage/Core/Model/Config.php app/code/core/Mage/Core/Model/Config.php
index f8c4b60..55700aa 100644
--- app/code/core/Mage/Core/Model/Config.php
+++ app/code/core/Mage/Core/Model/Config.php
@@ -906,6 +906,11 @@ class Mage_Core_Model_Config extends Mage_Core_Model_Config_Base
                 }
                 $configFile = $this->getModuleDir('etc', $modName).DS.$fileName;
                 if ($mergeModel->loadFile($configFile)) {
+                    $this->_makeEventsLowerCase(Mage_Core_Model_App_Area::AREA_GLOBAL, $mergeModel);
+                    $this->_makeEventsLowerCase(Mage_Core_Model_App_Area::AREA_FRONTEND, $mergeModel);
+                    $this->_makeEventsLowerCase(Mage_Core_Model_App_Area::AREA_ADMIN, $mergeModel);
+                    $this->_makeEventsLowerCase(Mage_Core_Model_App_Area::AREA_ADMINHTML, $mergeModel);
+
                     $mergeToObject->extend($mergeModel, true);
                 }
             }
@@ -1099,7 +1104,7 @@ class Mage_Core_Model_Config extends Mage_Core_Model_Config_Base
         }
 
         foreach ($events as $event) {
-            $eventName = $event->getName();
+            $eventName = strtolower($event->getName());
             $observers = $event->observers->children();
             foreach ($observers as $observer) {
                 switch ((string)$observer->type) {
@@ -1519,4 +1524,42 @@ class Mage_Core_Model_Config extends Mage_Core_Model_Config_Base
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
index 0000000..139e653
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
+ * @copyright   Copyright (c) 2006-2015 X.commerce, Inc. (http://www.magento.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
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
diff --git app/code/core/Mage/Core/Model/File/Validator/Image.php app/code/core/Mage/Core/Model/File/Validator/Image.php
new file mode 100644
index 0000000..136760b
--- /dev/null
+++ app/code/core/Mage/Core/Model/File/Validator/Image.php
@@ -0,0 +1,109 @@
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
+ * @copyright   Copyright (c) 2006-2015 X.commerce, Inc. (http://www.magento.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
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
index 5a039df..545d148 100644
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
diff --git app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
index a475194..83d30a6 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
@@ -251,7 +251,7 @@ class Mage_Dataflow_Model_Convert_Parser_Csv extends Mage_Dataflow_Model_Convert
      * Retrieve csv string from array
      *
      * @param array $fields
-     * @return sting
+     * @return string
      */
     public function getCsvString($fields = array()) {
         $delimiter  = $this->getVar('delimiter', ',');
@@ -263,11 +263,10 @@ class Mage_Dataflow_Model_Convert_Parser_Csv extends Mage_Dataflow_Model_Convert
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
index 3135b09..7c4e3a4 100644
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
index 58ff265..93fd2db 100644
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
index b733de6..a29daac 100644
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
index 80cab19..e793a87 100644
--- app/code/core/Mage/ImportExport/Model/Import/Entity/Abstract.php
+++ app/code/core/Mage/ImportExport/Model/Import/Entity/Abstract.php
@@ -260,6 +260,9 @@ abstract class Mage_ImportExport_Model_Import_Entity_Abstract
         $coefficient     = self::DB_MAX_PACKET_COEFFICIENT / self::DB_MAX_PACKET_DATA;
         $maxPacket       = $coefficient * $maxPacket;
 
+        /** @var Mage_Core_Helper_Data $coreHelper */
+        $coreHelper = Mage::helper("core");
+
         $source->rewind();
         $this->_dataSourceModel->cleanBunches();
 
@@ -276,7 +279,7 @@ abstract class Mage_ImportExport_Model_Import_Entity_Abstract
                 if ($this->_errorsCount >= $this->_errorsLimit) { // errors limit check
                     return;
                 }
-                $rowData = $source->current();
+                $rowData = $coreHelper->unEscapeCSVData($source->current());
 
                 $this->_processedRowsCount++;
 
diff --git app/code/core/Mage/ImportExport/etc/config.xml app/code/core/Mage/ImportExport/etc/config.xml
index ff69ec4..826c7a5 100644
--- app/code/core/Mage/ImportExport/etc/config.xml
+++ app/code/core/Mage/ImportExport/etc/config.xml
@@ -125,4 +125,11 @@
             </updates>
         </layout>
     </adminhtml>
+    <default>
+        <system>
+            <export_csv>
+                <escaping>1</escaping>
+            </export_csv>
+        </system>
+    </default>
 </config>
diff --git app/code/core/Mage/ImportExport/etc/system.xml app/code/core/Mage/ImportExport/etc/system.xml
new file mode 100644
index 0000000..028b305
--- /dev/null
+++ app/code/core/Mage/ImportExport/etc/system.xml
@@ -0,0 +1,54 @@
+<?xml version="1.0"?>
+<!--
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
+ * @package     Mage_ImportExport
+ * @copyright   Copyright (c) 2006-2015 X.commerce, Inc. (http://www.magento.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
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
diff --git app/code/core/Mage/Newsletter/Model/Queue.php app/code/core/Mage/Newsletter/Model/Queue.php
index 84cb0d4..82ae680 100644
--- app/code/core/Mage/Newsletter/Model/Queue.php
+++ app/code/core/Mage/Newsletter/Model/Queue.php
@@ -160,6 +160,7 @@ class Mage_Newsletter_Model_Queue extends Mage_Core_Model_Template
             return $this;
         }
 
+        /** @var Mage_Newsletter_Model_Resource_Subscriber_Collection $collection */
         $collection = $this->getSubscribersCollection()
             ->useOnlyUnsent()
             ->showCustomerInfo()
@@ -167,7 +168,7 @@ class Mage_Newsletter_Model_Queue extends Mage_Core_Model_Template
             ->setCurPage(1)
             ->load();
 
-        /* @var $sender Mage_Core_Model_Email_Template */
+        /** @var Mage_Core_Model_Email_Template $sender */
         $sender = Mage::getModel('core/email_template');
         $sender->setSenderName($this->getNewsletterSenderName())
             ->setSenderEmail($this->getNewsletterSenderEmail())
diff --git app/code/core/Mage/Page/etc/system.xml app/code/core/Mage/Page/etc/system.xml
index cbb7e14..4eae676 100644
--- app/code/core/Mage/Page/etc/system.xml
+++ app/code/core/Mage/Page/etc/system.xml
@@ -39,7 +39,7 @@
                     <fields>
                         <shortcut_icon translate="label comment">
                             <label>Favicon Icon</label>
-                            <comment>Allowed file types: ICO, PNG, GIF, JPEG, APNG, SVG. Not all browsers support all these formats!</comment>
+                            <comment>Allowed file types: ICO, PNG, GIF, JPG, JPEG, APNG. Not all browsers support all these formats!</comment>
                             <frontend_type>image</frontend_type>
                             <backend_model>adminhtml/system_config_backend_image_favicon</backend_model>
                             <base_url type="media" scope_info="1">favicon</base_url>
diff --git app/code/core/Mage/Paypal/controllers/PayflowController.php app/code/core/Mage/Paypal/controllers/PayflowController.php
index 0dff413..05f8e0c 100644
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
diff --git app/code/core/Mage/Paypal/etc/config.xml app/code/core/Mage/Paypal/etc/config.xml
index 6301bef..eca316d 100644
--- app/code/core/Mage/Paypal/etc/config.xml
+++ app/code/core/Mage/Paypal/etc/config.xml
@@ -130,14 +130,14 @@
                     </payflowlink_save_order_after_submit>
                 </observers>
             </checkout_submit_all_after>
-            <controller_action_postdispatch_checkout_onepage_saveOrder>
+            <controller_action_postdispatch_checkout_onepage_saveorder>
                 <observers>
                     <payflowlink_save_order_onepage>
                         <class>paypal/observer</class>
                         <method>setResponseAfterSaveOrder</method>
                     </payflowlink_save_order_onepage>
                 </observers>
-            </controller_action_postdispatch_checkout_onepage_saveOrder>
+            </controller_action_postdispatch_checkout_onepage_saveorder>
         </events>
     </frontend>
     <adminhtml>
diff --git app/code/core/Mage/Review/controllers/ProductController.php app/code/core/Mage/Review/controllers/ProductController.php
index 9cbdd43..2ca524a 100644
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
@@ -295,5 +295,24 @@ class Mage_Review_ProductController extends Mage_Core_Controller_Front_Action
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
index 367f4f4..675a16a 100644
--- app/code/core/Mage/Sales/Model/Quote/Address.php
+++ app/code/core/Mage/Sales/Model/Quote/Address.php
@@ -891,7 +891,12 @@ class Mage_Sales_Model_Quote_Address extends Mage_Customer_Model_Address_Abstrac
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
index aefb7ac..af52c6a 100644
--- app/code/core/Mage/Sales/Model/Quote/Item.php
+++ app/code/core/Mage/Sales/Model/Quote/Item.php
@@ -373,25 +373,34 @@ class Mage_Sales_Model_Quote_Item extends Mage_Sales_Model_Quote_Item_Abstract
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
diff --git app/design/adminhtml/default/default/template/authorizenet/directpost/iframe.phtml app/design/adminhtml/default/default/template/authorizenet/directpost/iframe.phtml
index b548da0..ce64559 100644
--- app/design/adminhtml/default/default/template/authorizenet/directpost/iframe.phtml
+++ app/design/adminhtml/default/default/template/authorizenet/directpost/iframe.phtml
@@ -30,7 +30,8 @@
 ?>
 <?php
 $_params = $this->getParams();
-$_helper = $this->helper('authorizenet');
+/* @var $_helper Mage_Authorizenet_Helper_Admin  */
+$_helper = $this->helper('authorizenet/admin');
 ?>
 <html>
 <head>
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
index c48646d..651c26d 100644
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
diff --git app/design/adminhtml/default/default/template/catalog/product/composite/fieldset/options/type/file.phtml app/design/adminhtml/default/default/template/catalog/product/composite/fieldset/options/type/file.phtml
index 87b6f51..b547eea 100644
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
index f2f4b27..9e81948 100644
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
index 611af6a..46fdda0 100644
--- app/design/adminhtml/default/default/template/sales/order/view/info.phtml
+++ app/design/adminhtml/default/default/template/sales/order/view/info.phtml
@@ -84,7 +84,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
             <?php if($_order->getRemoteIp()): ?>
             <tr>
                 <td class="label"><label><?php echo Mage::helper('sales')->__('Placed from IP') ?></label></td>
-                <td class="value"><strong><?php echo $_order->getRemoteIp(); echo ($_order->getXForwardedFor())?' (' . $_order->getXForwardedFor() . ')':''; ?></strong></td>
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
index 07b0b68..45427af 100644
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
diff --git lib/Varien/File/Uploader.php lib/Varien/File/Uploader.php
index 102bed0..e6bd883 100644
--- lib/Varien/File/Uploader.php
+++ lib/Varien/File/Uploader.php
@@ -122,6 +122,13 @@ class Varien_File_Uploader
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
@@ -196,10 +203,11 @@ class Varien_File_Uploader
 
         $result = move_uploaded_file($this->_file['tmp_name'], $destFile);
 
-        if( $result ) {
-            chmod($destFile, 0777);
-            if ( $this->_enableFilesDispersion ) {
-                $fileName = str_replace(DIRECTORY_SEPARATOR, '/', self::_addDirSeparator($this->_dispretionPath)) . $fileName;
+        if ($result) {
+            chmod($destFile, 0640);
+            if ($this->_enableFilesDispersion) {
+                $fileName = str_replace(DIRECTORY_SEPARATOR, '/',
+                    self::_addDirSeparator($this->_dispretionPath)) . $fileName;
             }
             $this->_uploadedFileName = $fileName;
             $this->_uploadedFileDir = $destinationFolder;
@@ -232,6 +240,14 @@ class Varien_File_Uploader
         if( !$this->chechAllowedExtension($fileExtension) ) {
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
         foreach ($this->_validateCallbacks as $params)
         {
@@ -320,14 +336,17 @@ class Varien_File_Uploader
      * @access public
      * @return bool
      */
-    public function checkMimeType($validTypes=Array())
+    public function checkMimeType($validTypes = array())
     {
-        if( count($validTypes) > 0 ) {
-            if( !in_array($this->_getMimeType(), $validTypes) ) {
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
@@ -399,6 +418,21 @@ class Varien_File_Uploader
         }
         return $this;
     }
+    
+    /**
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
 
     public function chechAllowedExtension($extension)
     {
@@ -460,7 +494,7 @@ class Varien_File_Uploader
             $destinationFolder = substr($destinationFolder, 0, -1);
         }
 
-        if (!(@is_dir($destinationFolder) || @mkdir($destinationFolder, 0777, true))) {
+        if (!(@is_dir($destinationFolder) || @mkdir($destinationFolder, 0750, true))) {
             throw new Exception("Unable to create directory '{$destinationFolder}'.");
         }
         return $this;
diff --git lib/Varien/Io/File.php lib/Varien/Io/File.php
index 3bcf94f..a72109a 100644
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
 
