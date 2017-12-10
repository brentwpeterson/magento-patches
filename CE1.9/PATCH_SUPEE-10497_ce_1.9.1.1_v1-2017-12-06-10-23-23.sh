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


SUPEE-10497 | CE_1.9.1.1 | v1 | bbbbd119ad2c3ce824964d2dbd4308755062f725 | Fri Dec 1 00:50:33 2017 +0200 | 433c0da2b7930c28..bbbbd119ad2c3ce8

__PATCHFILE_FOLLOWS__
diff --git app/Mage.php app/Mage.php
index 7259b5d..8b496a6 100644
--- app/Mage.php
+++ app/Mage.php
@@ -805,7 +805,12 @@ final class Mage
         static $loggers = array();
 
         $level  = is_null($level) ? Zend_Log::DEBUG : $level;
-        $file = empty($file) ? 'system.log' : $file;
+        $file = empty($file) ? 'system.log' : basename($file);
+
+        // Validate file extension before save. Allowed file extensions: log, txt, html, csv
+        if (!self::helper('log')->isLogFileExtensionValid($file)) {
+            return;
+        }
 
         try {
             if (!isset($loggers[$file])) {
diff --git app/code/core/Mage/Admin/Model/Session.php app/code/core/Mage/Admin/Model/Session.php
index d2dfa2a..bf9de73 100644
--- app/code/core/Mage/Admin/Model/Session.php
+++ app/code/core/Mage/Admin/Model/Session.php
@@ -76,6 +76,7 @@ class Mage_Admin_Model_Session extends Mage_Core_Model_Session_Abstract
             $parameters['factory'] : Mage::getModel('core/factory');
 
         $this->init('admin');
+        $this->logoutIndirect();
     }
 
     /**
@@ -99,6 +100,21 @@ class Mage_Admin_Model_Session extends Mage_Core_Model_Session_Abstract
     }
 
     /**
+     * Logout user if was logged not from admin
+     */
+    protected function logoutIndirect()
+    {
+        $user = $this->getUser();
+        if ($user) {
+            $extraData = $user->getExtra();
+            if (isset($extraData['indirect_login']) && $this->getIndirectLogin()) {
+                $this->unsetData('user');
+                $this->setIndirectLogin(false);
+            }
+        }
+    }
+
+    /**
      * Try to login user in admin
      *
      * @param  string $username
diff --git app/code/core/Mage/Adminhtml/Block/Notification/Grid/Renderer/Notice.php app/code/core/Mage/Adminhtml/Block/Notification/Grid/Renderer/Notice.php
index e2dd165..2b645171 100644
--- app/code/core/Mage/Adminhtml/Block/Notification/Grid/Renderer/Notice.php
+++ app/code/core/Mage/Adminhtml/Block/Notification/Grid/Renderer/Notice.php
@@ -43,7 +43,7 @@ class Mage_Adminhtml_Block_Notification_Grid_Renderer_Notice
      */
     public function render(Varien_Object $row)
     {
-        return '<span class="grid-row-title">' . $row->getTitle() . '</span>'
-            . ($row->getDescription() ? '<br />' . $row->getDescription() : '');
+        return '<span class="grid-row-title">' . $this->escapeHtml($row->getTitle()) . '</span>'
+            . ($row->getDescription() ? '<br />' . $this->escapeHtml($row->getDescription()) : '');
     }
 }
diff --git app/code/core/Mage/Adminhtml/Block/Report/Review/Detail.php app/code/core/Mage/Adminhtml/Block/Report/Review/Detail.php
index 95715a1..25012e6 100644
--- app/code/core/Mage/Adminhtml/Block/Report/Review/Detail.php
+++ app/code/core/Mage/Adminhtml/Block/Report/Review/Detail.php
@@ -40,7 +40,7 @@ class Mage_Adminhtml_Block_Report_Review_Detail extends Mage_Adminhtml_Block_Wid
         $this->_controller = 'report_review_detail';
 
         $product = Mage::getModel('catalog/product')->load($this->getRequest()->getParam('id'));
-        $this->_headerText = Mage::helper('reports')->__('Reviews for %s', $product->getName());
+        $this->_headerText = Mage::helper('reports')->__('Reviews for %s', $this->escapeHtml($product->getName()));
 
         parent::__construct();
         $this->_removeButton('add');
diff --git app/code/core/Mage/Adminhtml/Block/Report/Tag/Product/Detail.php app/code/core/Mage/Adminhtml/Block/Report/Tag/Product/Detail.php
index a01898c..c6e2261 100644
--- app/code/core/Mage/Adminhtml/Block/Report/Tag/Product/Detail.php
+++ app/code/core/Mage/Adminhtml/Block/Report/Tag/Product/Detail.php
@@ -41,7 +41,7 @@ class Mage_Adminhtml_Block_Report_Tag_Product_Detail extends Mage_Adminhtml_Bloc
 
         $product = Mage::getModel('catalog/product')->load($this->getRequest()->getParam('id'));
 
-        $this->_headerText = Mage::helper('reports')->__('Tags submitted to %s', $product->getName());
+        $this->_headerText = Mage::helper('reports')->__('Tags submitted to %s', $this->escapeHtml($product->getName()));
         parent::__construct();
         $this->_removeButton('add');
         $this->setBackUrl($this->getUrl('*/report_tag/product/'));
diff --git app/code/core/Mage/Adminhtml/Block/Review/Add.php app/code/core/Mage/Adminhtml/Block/Review/Add.php
index a730991..cb8c296 100644
--- app/code/core/Mage/Adminhtml/Block/Review/Add.php
+++ app/code/core/Mage/Adminhtml/Block/Review/Add.php
@@ -99,7 +99,7 @@ class Mage_Adminhtml_Block_Review_Add extends Mage_Adminhtml_Block_Widget_Form_C
                         } else if( response.id ){
                             $("product_id").value = response.id;
 
-                            $("product_name").innerHTML = \'<a href="' . $this->getUrl('*/catalog_product/edit') . 'id/\' + response.id + \'" target="_blank">\' + response.name + \'</a>\';
+                            $("product_name").innerHTML = \'<a href="' . $this->getUrl('*/catalog_product/edit') . 'id/\' + response.id + \'" target="_blank">\' + response.name.escapeHTML() + \'</a>\';
                         } else if( response.message ) {
                             alert(response.message);
                         }
diff --git app/code/core/Mage/Adminhtml/Block/Review/Edit/Form.php app/code/core/Mage/Adminhtml/Block/Review/Edit/Form.php
index fba3b75..2ea9dcb 100644
--- app/code/core/Mage/Adminhtml/Block/Review/Edit/Form.php
+++ app/code/core/Mage/Adminhtml/Block/Review/Edit/Form.php
@@ -50,9 +50,10 @@ class Mage_Adminhtml_Block_Review_Edit_Form extends Mage_Adminhtml_Block_Widget_
 
         $fieldset->addField('product_name', 'note', array(
             'label'     => Mage::helper('review')->__('Product'),
-            'text'      => '<a href="' . $this->getUrl('*/catalog_product/edit', array('id' => $product->getId())) . '" onclick="this.target=\'blank\'">' . $product->getName() . '</a>'
+            'text'      => '<a href="' . $this->getUrl('*/catalog_product/edit', array('id' => $product->getId())) . '" onclick="this.target=\'blank\'">' . $this->escapeHtml($product->getName()) . '</a>'
         ));
 
+        $customerText = '';
         if ($customer->getId()) {
             $customerText = Mage::helper('review')->__('<a href="%1$s" onclick="this.target=\'blank\'">%2$s %3$s</a> <a href="mailto:%4$s">(%4$s)</a>', $this->getUrl('*/customer/edit', array('id' => $customer->getId(), 'active_tab'=>'review')), $this->escapeHtml($customer->getFirstname()), $this->escapeHtml($customer->getLastname()), $this->escapeHtml($customer->getEmail()));
         } else {
diff --git app/code/core/Mage/Adminhtml/Block/Widget/Form/Container.php app/code/core/Mage/Adminhtml/Block/Widget/Form/Container.php
index 4c5bd3d..6262f47 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Form/Container.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Form/Container.php
@@ -96,7 +96,10 @@ class Mage_Adminhtml_Block_Widget_Form_Container extends Mage_Adminhtml_Block_Wi
 
     public function getDeleteUrl()
     {
-        return $this->getUrl('*/*/delete', array($this->_objectId => $this->getRequest()->getParam($this->_objectId)));
+        return $this->getUrl('*/*/delete', array(
+            $this->_objectId => $this->getRequest()->getParam($this->_objectId),
+            Mage_Core_Model_Url::FORM_KEY => $this->getFormKey()
+        ));
     }
 
     /**
diff --git app/code/core/Mage/Adminhtml/Controller/Action.php app/code/core/Mage/Adminhtml/Controller/Action.php
index f93647e..627cba0 100644
--- app/code/core/Mage/Adminhtml/Controller/Action.php
+++ app/code/core/Mage/Adminhtml/Controller/Action.php
@@ -51,6 +51,13 @@ class Mage_Adminhtml_Controller_Action extends Mage_Core_Controller_Varien_Actio
     protected $_publicActions = array();
 
     /**
+     *Array of actions which can't be processed without form key validation
+     *
+     * @var array
+     */
+    protected $_forcedFormKeyActions = array();
+
+    /**
      * Used module name in current adminhtml controller
      */
     protected $_usedModuleName = 'adminhtml';
@@ -162,7 +169,7 @@ class Mage_Adminhtml_Controller_Action extends Mage_Core_Controller_Varien_Actio
         $_isValidSecretKey = true;
         $_keyErrorMsg = '';
         if (Mage::getSingleton('admin/session')->isLoggedIn()) {
-            if ($this->getRequest()->isPost()) {
+            if ($this->getRequest()->isPost() || $this->_checkIsForcedFormKeyAction()) {
                 $_isValidFormKey = $this->_validateFormKey();
                 $_keyErrorMsg = Mage::helper('adminhtml')->__('Invalid Form Key. Please refresh the page.');
             } elseif (Mage::getSingleton('adminhtml/url')->useSecretKey()) {
@@ -179,6 +186,9 @@ class Mage_Adminhtml_Controller_Action extends Mage_Core_Controller_Varien_Actio
                     'message' => $_keyErrorMsg
                 )));
             } else {
+                if (!$_isValidFormKey){
+                    Mage::getSingleton('adminhtml/session')->addError($_keyErrorMsg);
+                }
                 $this->_redirect( Mage::getSingleton('admin/session')->getUser()->getStartupPageUrl() );
             }
             return $this;
@@ -397,4 +407,27 @@ class Mage_Adminhtml_Controller_Action extends Mage_Core_Controller_Varien_Actio
         $user = Mage::getSingleton('admin/session')->getUser();
         return $user->validateCurrentPassword($password);
     }
+
+    /**
+     * Check forced use form key for action
+     *
+     *  @return bool
+     */
+    protected function _checkIsForcedFormKeyAction()
+    {
+        return in_array($this->getRequest()->getActionName(), $this->_forcedFormKeyActions);
+    }
+
+    /**
+     * Set actions name for forced use form key
+     *
+     * @param array | string $actionNames - action names for forced use form key
+     */
+    protected function _setForcedFormKeyActions($actionNames)
+    {
+        $actionNames = (is_array($actionNames)) ? $actionNames: (array)$actionNames;
+        $actionNames = array_merge($this->_forcedFormKeyActions, $actionNames);
+        $actionNames = array_unique($actionNames);
+        $this->_forcedFormKeyActions = $actionNames;
+    }
 }
diff --git app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
index 42c9e73..c089ea5 100644
--- app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
+++ app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
@@ -37,6 +37,7 @@
 class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
 {
     const XML_INVALID                             = 'invalidXml';
+    const INVALID_TEMPLATE_PATH                   = 'invalidTemplatePath';
     const PROTECTED_ATTR_HELPER_IN_TAG_ACTION_VAR = 'protectedAttrHelperInActionVar';
 
     /**
@@ -75,6 +76,9 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
                 self::PROTECTED_ATTR_HELPER_IN_TAG_ACTION_VAR =>
                     Mage::helper('adminhtml')->__('Helper attributes should not be used in custom layout updates.'),
                 self::XML_INVALID => Mage::helper('adminhtml')->__('XML data is invalid.'),
+                self::INVALID_TEMPLATE_PATH => Mage::helper('adminhtml')->__(
+                    'Invalid template path used in layout update.'
+                ),
             );
         }
         return $this;
@@ -109,6 +113,15 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
                 Mage::helper('adminhtml')->__('XML object is not instance of "Varien_Simplexml_Element".'));
         }
 
+        // if layout update declare custom templates then validate their paths
+        if ($templatePaths = $value->xpath('*//template | *//@template | //*[@method=\'setTemplate\']/*')) {
+            try {
+                $this->_validateTemplatePath($templatePaths);
+            } catch (Exception $e) {
+                $this->_error(self::INVALID_TEMPLATE_PATH);
+                return false;
+            }
+        }
         $this->_setValue($value);
 
         foreach ($this->_protectedExpressions as $key => $xpr) {
@@ -119,4 +132,19 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
         }
         return true;
     }
+
+    /**
+     * Validate template path for preventing access to the directory above
+     * If template path value has "../" @throws Exception
+     *
+     * @param $templatePaths | array
+     */
+    protected function _validateTemplatePath(array $templatePaths)
+    {
+        foreach ($templatePaths as $path) {
+            if (strpos($path, '..' . DS) !== false) {
+                throw new Exception();
+            }
+        }
+    }
 }
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Filename.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Filename.php
index 5bf255c..cc838f8 100644
--- app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Filename.php
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Filename.php
@@ -27,10 +27,37 @@
 
 class Mage_Adminhtml_Model_System_Config_Backend_Filename extends Mage_Core_Model_Config_Data
 {
+
+    /**
+     * Config path for system log file.
+     */
+    const DEV_LOG_FILE_PATH = 'dev/log/file';
+
+    /**
+     * Config path for exception log file.
+     */
+    const DEV_LOG_EXCEPTION_FILE_PATH = 'dev/log/exception_file';
+
+    /**
+     * Processing object before save data
+     *
+     * @return Mage_Adminhtml_Model_System_Config_Backend_Filename
+     * @throws Mage_Core_Exception
+     */
     protected function _beforeSave()
     {
-        $value = $this->getValue();
-        $value = basename($value);
+        $value      = $this->getValue();
+        $configPath = $this->getPath();
+        $value      = basename($value);
+
+        // if dev/log setting, validate log file extension.
+        if ($configPath == self::DEV_LOG_FILE_PATH || $configPath == self::DEV_LOG_EXCEPTION_FILE_PATH) {
+            if (!Mage::helper('log')->isLogFileExtensionValid($value)) {
+                throw Mage::exception('Mage_Core', Mage::helper('adminhtml')->__
+                ('Invalid file extension used for log file. Allowed file extensions: log, txt, html, csv'));
+            }
+        }
+
         $this->setValue($value);
         return $this;
     }
diff --git app/code/core/Mage/Adminhtml/controllers/CustomerController.php app/code/core/Mage/Adminhtml/controllers/CustomerController.php
index 7d8cf43..a160585 100644
--- app/code/core/Mage/Adminhtml/controllers/CustomerController.php
+++ app/code/core/Mage/Adminhtml/controllers/CustomerController.php
@@ -33,6 +33,16 @@
  */
 class Mage_Adminhtml_CustomerController extends Mage_Adminhtml_Controller_Action
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
 
     protected function _initCustomer($idFieldName = 'id')
     {
diff --git app/code/core/Mage/Adminhtml/controllers/Newsletter/QueueController.php app/code/core/Mage/Adminhtml/controllers/Newsletter/QueueController.php
index ef34088..1f0535e 100644
--- app/code/core/Mage/Adminhtml/controllers/Newsletter/QueueController.php
+++ app/code/core/Mage/Adminhtml/controllers/Newsletter/QueueController.php
@@ -63,6 +63,10 @@ class Mage_Adminhtml_Newsletter_QueueController extends Mage_Adminhtml_Controlle
      */
     public function dropAction ()
     {
+        $request = $this->getRequest();
+        if ($request->getParam('text') && !$request->getPost('text')) {
+            $this->getResponse()->setRedirect($this->getUrl('*/newsletter_queue'));
+        }
         $this->loadLayout('newsletter_queue_preview');
         $this->renderLayout();
     }
diff --git app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
index d0e5394..22a893a 100644
--- app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
+++ app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
@@ -142,6 +142,10 @@ class Mage_Adminhtml_Newsletter_TemplateController extends Mage_Adminhtml_Contro
      */
     public function dropAction ()
     {
+        $request = $this->getRequest();
+        if ($request->getParam('text') && !$request->getPost('text')) {
+             $this->getResponse()->setRedirect($this->getUrl('*/newsletter_template'));
+        }
         $this->loadLayout('newsletter_template_preview');
         $this->renderLayout();
     }
diff --git app/code/core/Mage/Api/Helper/Data.php app/code/core/Mage/Api/Helper/Data.php
index 9d7a07e..ff3b821 100644
--- app/code/core/Mage/Api/Helper/Data.php
+++ app/code/core/Mage/Api/Helper/Data.php
@@ -346,4 +346,47 @@ class Mage_Api_Helper_Data extends Mage_Core_Helper_Abstract
             $conditionValue = explode($delimiter, $conditionValue);
         }
     }
+
+    /**
+     * Get wsdl cache id
+     *
+     * @return string
+     */
+    public function getCacheId()
+    {
+        return 'wsdl_config_global_' . md5($this->getServiceUrl('*/*/*'));
+    }
+
+    /**
+     * Get service url
+     *
+     * @param string|null $routePath
+     * @param array|null $routeParams
+     * @param bool $htmlSpecialChars
+     * @return string
+     * @throws Zend_Uri_Exception
+     */
+    public function getServiceUrl($routePath = null, $routeParams = null, $htmlSpecialChars = false)
+    {
+        $request = Mage::app()->getRequest();
+
+        if (is_null($routeParams)) {
+            $routeParams = array();
+        }
+
+        $routeParams['_nosid'] = true;
+
+        /** @var Mage_Core_Model_Url $urlModel */
+        $urlModel = Mage::getSingleton('core/url');
+        $url = $urlModel->getUrl($routePath, $routeParams);
+        $uri = Zend_Uri_Http::fromString($url);
+        $uri->setHost($request->getHttpHost());
+        if (!$urlModel->getRouteFrontName()) {
+            $uri->setPath('/' . trim($request->getBasePath() . '/api.php', '/'));
+        } else {
+            $uri->setPath($request->getBaseUrl() . $request->getPathInfo());
+        }
+
+        return $htmlSpecialChars === true ? htmlspecialchars($uri) : (string)$uri;
+    }
 }
diff --git app/code/core/Mage/Api/Model/Server/Adapter/Soap.php app/code/core/Mage/Api/Model/Server/Adapter/Soap.php
index 52ca06f..1e6e2eb 100644
--- app/code/core/Mage/Api/Model/Server/Adapter/Soap.php
+++ app/code/core/Mage/Api/Model/Server/Adapter/Soap.php
@@ -120,7 +120,9 @@ class Mage_Api_Model_Server_Adapter_Soap
                 unset($queryParams['wsdl']);
             }
 
-            $wsdlConfig->setUrl(htmlspecialchars(Mage::getUrl('*/*/*', array('_query'=>$queryParams))));
+            $wsdlConfig->setUrl(
+                Mage::helper('api')->getServiceUrl('*/*/*', array('_query' => $queryParams), true)
+            );
             $wsdlConfig->setName('Magento');
             $wsdlConfig->setHandler($this->getHandler());
 
@@ -205,8 +207,8 @@ class Mage_Api_Model_Server_Adapter_Soap
             ->setUseSession(false);
 
         $wsdlUrl = $params !== null
-            ? $urlModel->getUrl('*/*/*', array('_current' => true, '_query' => $params))
-            : $urlModel->getUrl('*/*/*');
+            ? Mage::helper('api')->getServiceUrl('*/*/*', array('_current' => true, '_query' => $params))
+            : Mage::helper('api')->getServiceUrl('*/*/*');
 
         if ( $withAuth ) {
             $phpAuthUser = rawurlencode($this->getController()->getRequest()->getServer('PHP_AUTH_USER', false));
diff --git app/code/core/Mage/Api/Model/Wsdl/Config.php app/code/core/Mage/Api/Model/Wsdl/Config.php
index a94ba25..58ab7c7 100644
--- app/code/core/Mage/Api/Model/Wsdl/Config.php
+++ app/code/core/Mage/Api/Model/Wsdl/Config.php
@@ -37,7 +37,7 @@ class Mage_Api_Model_Wsdl_Config extends Mage_Api_Model_Wsdl_Config_Base
 
     public function __construct($sourceData=null)
     {
-        $this->setCacheId('wsdl_config_global');
+        $this->setCacheId(Mage::helper('api')->getCacheId());
         parent::__construct($sourceData);
     }
 
diff --git app/code/core/Mage/Api/Model/Wsdl/Config/Base.php app/code/core/Mage/Api/Model/Wsdl/Config/Base.php
index 7dbfdfa..dbbe83f 100644
--- app/code/core/Mage/Api/Model/Wsdl/Config/Base.php
+++ app/code/core/Mage/Api/Model/Wsdl/Config/Base.php
@@ -54,7 +54,7 @@ class Mage_Api_Model_Wsdl_Config_Base extends Varien_Simplexml_Config
         $this->_wsdlVariables = new Varien_Object(
             array(
                 'name' => 'Magento',
-                'url'  => htmlspecialchars(Mage::getUrl('*/*/*', array('_query' => $queryParams)))
+                'url'  => Mage::helper('api')->getServiceUrl('*/*/*', array('_query' => $queryParams), true)
             )
         );
         parent::__construct($sourceData);
diff --git app/code/core/Mage/Checkout/controllers/CartController.php app/code/core/Mage/Checkout/controllers/CartController.php
index 90d3965..7b5d4ec 100644
--- app/code/core/Mage/Checkout/controllers/CartController.php
+++ app/code/core/Mage/Checkout/controllers/CartController.php
@@ -267,14 +267,16 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
     public function addgroupAction()
     {
         $orderItemIds = $this->getRequest()->getParam('order_items', array());
+        $customerId   = $this->_getCustomerSession()->getCustomerId();
 
-        if (!is_array($orderItemIds) || !$this->_validateFormKey()) {
+        if (!is_array($orderItemIds) || !$this->_validateFormKey() || !$customerId) {
             $this->_goBack();
             return;
         }
 
         $itemsCollection = Mage::getModel('sales/order_item')
             ->getCollection()
+            ->addFilterByCustomerId($customerId)
             ->addIdFilter($orderItemIds)
             ->load();
         /* @var $itemsCollection Mage_Sales_Model_Mysql4_Order_Item_Collection */
@@ -683,4 +685,14 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
         $this->getResponse()->setHeader('Content-type', 'application/json');
         $this->getResponse()->setBody(Mage::helper('core')->jsonEncode($result));
     }
+
+    /**
+     * Get customer session model
+     *
+     * @return Mage_Customer_Model_Session
+     */
+    protected function _getCustomerSession()
+    {
+        return Mage::getSingleton('customer/session');
+    }
 }
diff --git app/code/core/Mage/Core/Helper/String.php app/code/core/Mage/Core/Helper/String.php
index 41dccdc..f5c7046 100644
--- app/code/core/Mage/Core/Helper/String.php
+++ app/code/core/Mage/Core/Helper/String.php
@@ -76,6 +76,26 @@ class Mage_Core_Helper_String extends Mage_Core_Helper_Abstract
     }
 
     /**
+     * UnSerialize string
+     * @param $str
+     * @return mixed|null
+     * @throws Exception
+     */
+    public function unserialize($str)
+    {
+        $reader = new Unserialize_Reader_ArrValue('data');
+        $prevChar = null;
+        for ($i = 0; $i < strlen($str); $i++) {
+            $char = $str[$i];
+            $result = $reader->read($char, $prevChar);
+            if (!is_null($result)) {
+                return $result;
+            }
+            $prevChar = $char;
+        }
+    }
+
+    /**
      * Retrieve string length using default charset
      *
      * @param string $string
diff --git app/code/core/Mage/Core/Model/Email/Template/Abstract.php app/code/core/Mage/Core/Model/Email/Template/Abstract.php
index 51fbe09..f39cbee 100644
--- app/code/core/Mage/Core/Model/Email/Template/Abstract.php
+++ app/code/core/Mage/Core/Model/Email/Template/Abstract.php
@@ -251,8 +251,11 @@ abstract class Mage_Core_Model_Email_Template_Abstract extends Mage_Core_Model_T
                 '_theme' => $theme,
             )
         );
+        $filePath = realpath($filePath);
+        $positionSkinDirectory = strpos($filePath, Mage::getBaseDir('skin'));
+        $validator = new Zend_Validate_File_Extension('css');
 
-        if (is_readable($filePath)) {
+        if ($validator->isValid($filePath) && $positionSkinDirectory !== false && is_readable($filePath)) {
             return (string) file_get_contents($filePath);
         }
 
diff --git app/code/core/Mage/Core/Model/File/Validator/Image.php app/code/core/Mage/Core/Model/File/Validator/Image.php
index 8618bca..9c21a22 100644
--- app/code/core/Mage/Core/Model/File/Validator/Image.php
+++ app/code/core/Mage/Core/Model/File/Validator/Image.php
@@ -90,6 +90,10 @@ class Mage_Core_Model_File_Validator_Image
         list($imageWidth, $imageHeight, $fileType) = getimagesize($filePath);
         if ($fileType) {
             if ($this->isImageType($fileType)) {
+                /** if 'general/reprocess_images/active' false then skip image reprocessing. */
+                if (!Mage::getStoreConfigFlag('general/reprocess_images/active')) {
+                    return null;
+                }
                 //replace tmp image with re-sampled copy to exclude images with malicious data
                 $image = imagecreatefromstring(file_get_contents($filePath));
                 if ($image !== false) {
diff --git app/code/core/Mage/Core/Model/Session/Abstract/Varien.php app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
index 5b90f51..c5832ab 100644
--- app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
+++ app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
@@ -135,19 +135,24 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
         if (Mage::app()->getFrontController()->getRequest()->isSecure() && empty($cookieParams['secure'])) {
             // secure cookie check to prevent MITM attack
             $secureCookieName = $sessionName . '_cid';
-            if (isset($_SESSION[self::SECURE_COOKIE_CHECK_KEY])
-                && $_SESSION[self::SECURE_COOKIE_CHECK_KEY] !== md5($cookie->get($secureCookieName))
-            ) {
-                session_regenerate_id(false);
-                $sessionHosts = $this->getSessionHosts();
-                $currentCookieDomain = $cookie->getDomain();
-                foreach (array_keys($sessionHosts) as $host) {
-                    // Delete cookies with the same name for parent domains
-                    if (strpos($currentCookieDomain, $host) > 0) {
-                        $cookie->delete($this->getSessionName(), null, $host);
+            if (isset($_SESSION[self::SECURE_COOKIE_CHECK_KEY])) {
+                if ($_SESSION[self::SECURE_COOKIE_CHECK_KEY] !== md5($cookie->get($secureCookieName))) {
+                    session_regenerate_id(false);
+                    $sessionHosts = $this->getSessionHosts();
+                    $currentCookieDomain = $cookie->getDomain();
+                    foreach (array_keys($sessionHosts) as $host) {
+                        // Delete cookies with the same name for parent domains
+                        if (strpos($currentCookieDomain, $host) > 0) {
+                            $cookie->delete($this->getSessionName(), null, $host);
+                        }
                     }
+                    $_SESSION = array();
+                } else {
+                    /**
+                     * Renew secure cookie expiration time if secure id did not change
+                     */
+                    $cookie->renew($secureCookieName, null, null, null, true, null);
                 }
-                $_SESSION = array();
             }
             if (!isset($_SESSION[self::SECURE_COOKIE_CHECK_KEY])) {
                 $checkId = Mage::helper('core')->getRandomString(16);
@@ -157,8 +162,8 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
         }
 
         /**
-        * Renew cookie expiration time if session id did not change
-        */
+         * Renew cookie expiration time if session id did not change
+         */
         if ($cookie->get(session_name()) == $this->getSessionId()) {
             $cookie->renew(session_name());
         }
diff --git app/code/core/Mage/Core/etc/config.xml app/code/core/Mage/Core/etc/config.xml
index 13f497c..73b8038 100644
--- app/code/core/Mage/Core/etc/config.xml
+++ app/code/core/Mage/Core/etc/config.xml
@@ -456,6 +456,10 @@
                     </protected>
                 </public_files_valid_paths>
             </file>
+            <!-- NOTE: If you turn off images reprocessing, then your upload images process may cause security risks. -->
+            <reprocess_images>
+                <active>1</active>
+            </reprocess_images>
         </general>
     </default>
     <stores>
diff --git app/code/core/Mage/Core/etc/system.xml app/code/core/Mage/Core/etc/system.xml
index 16c838b..c843985 100644
--- app/code/core/Mage/Core/etc/system.xml
+++ app/code/core/Mage/Core/etc/system.xml
@@ -651,7 +651,7 @@
                             <show_in_default>1</show_in_default>
                             <show_in_website>1</show_in_website>
                             <show_in_store>1</show_in_store>
-                            <comment>Logging from Mage::log(). File is located in {{base_dir}}/var/log</comment>
+                            <comment>Logging from Mage::log(). File is located in {{base_dir}}/var/log. Allowed file extensions: log, txt, html, csv</comment>
                         </file>
                         <exception_file translate="label comment">
                             <label>Exceptions Log File Name</label>
@@ -661,7 +661,7 @@
                             <show_in_default>1</show_in_default>
                             <show_in_website>1</show_in_website>
                             <show_in_store>1</show_in_store>
-                            <comment>Logging from Mage::logException(). File is located in {{base_dir}}/var/log</comment>
+                            <comment>Logging from Mage::logException(). File is located in {{base_dir}}/var/log. Allowed file extensions: log, txt, html, csv</comment>
                         </exception_file>
                     </fields>
                 </log>
diff --git app/code/core/Mage/Customer/Model/Customer.php app/code/core/Mage/Customer/Model/Customer.php
index 4ee0fa2..26a0008 100644
--- app/code/core/Mage/Customer/Model/Customer.php
+++ app/code/core/Mage/Customer/Model/Customer.php
@@ -48,6 +48,11 @@ class Mage_Customer_Model_Customer extends Mage_Core_Model_Abstract
     const XML_PATH_GENERATE_HUMAN_FRIENDLY_ID   = 'customer/create_account/generate_human_friendly_id';
     /**#@-*/
 
+    /**
+     * Maximum Password Length
+     */
+    const MAXIMUM_PASSWORD_LENGTH = 256;
+
     /**#@+
      * Codes of exceptions related to customer model
      */
@@ -841,6 +846,10 @@ class Mage_Customer_Model_Customer extends Mage_Core_Model_Abstract
         if (strlen($password) && !Zend_Validate::is($password, 'StringLength', array(6))) {
             $errors[] = Mage::helper('customer')->__('The minimum password length is %s', 6);
         }
+        if (strlen($password) && !Zend_Validate::is($password, 'StringLength', array('max' => self::MAXIMUM_PASSWORD_LENGTH))) {
+            $errors[] = Mage::helper('customer')
+                ->__('Please enter a password with at most %s characters.', self::MAXIMUM_PASSWORD_LENGTH);
+        }
         $confirmation = $this->getPasswordConfirmation();
         if ($password != $confirmation) {
             $errors[] = Mage::helper('customer')->__('Please make sure your passwords match.');
diff --git app/code/core/Mage/Eav/Model/Entity/Attribute/Backend/Serialized.php app/code/core/Mage/Eav/Model/Entity/Attribute/Backend/Serialized.php
index 238b7c4..8652fe0 100644
--- app/code/core/Mage/Eav/Model/Entity/Attribute/Backend/Serialized.php
+++ app/code/core/Mage/Eav/Model/Entity/Attribute/Backend/Serialized.php
@@ -83,7 +83,8 @@ class Mage_Eav_Model_Entity_Attribute_Backend_Serialized extends Mage_Eav_Model_
         $attrCode = $this->getAttribute()->getAttributeCode();
         if ($object->getData($attrCode)) {
             try {
-                $unserialized = unserialize($object->getData($attrCode));
+                $unserialized = Mage::helper('core/string')
+                    ->unserialize($object->getData($attrCode));
                 $object->setData($attrCode, $unserialized);
             } catch (Exception $e) {
                 $object->unsetData($attrCode);
diff --git app/code/core/Mage/Log/Helper/Data.php app/code/core/Mage/Log/Helper/Data.php
index 6e1a7e2..a156967 100644
--- app/code/core/Mage/Log/Helper/Data.php
+++ app/code/core/Mage/Log/Helper/Data.php
@@ -29,5 +29,25 @@
  */
 class Mage_Log_Helper_Data extends Mage_Core_Helper_Abstract
 {
+    /**
+     * Allowed extensions that can be used to create a log file
+     */
+    private $_allowedFileExtensions = array('log', 'txt', 'html', 'csv');
 
+    /**
+     * Checking if file extensions is allowed. If passed then return true.
+     *
+     * @param $file
+     * @return bool
+     */
+    public function isLogFileExtensionValid($file)
+    {
+        $result = false;
+        $validatedFileExtension = pathinfo($file, PATHINFO_EXTENSION);
+        if ($validatedFileExtension && in_array($validatedFileExtension, $this->_allowedFileExtensions)) {
+            $result = true;
+        }
+
+        return $result;
+    }
 }
diff --git app/code/core/Mage/Rss/Helper/Data.php app/code/core/Mage/Rss/Helper/Data.php
index 14bc252..8356fb0 100644
--- app/code/core/Mage/Rss/Helper/Data.php
+++ app/code/core/Mage/Rss/Helper/Data.php
@@ -34,6 +34,18 @@
  */
 class Mage_Rss_Helper_Data extends Mage_Core_Helper_Abstract
 {
+    /** @var Mage_Rss_Model_Session  */
+    private $_rssSession;
+
+    /** @var Mage_Admin_Model_Session  */
+    private $_adminSession;
+
+    public function __construct()
+    {
+        $this->_rssSession = Mage::getSingleton('rss/session');
+        $this->_adminSession = Mage::getSingleton('admin/session');;
+    }
+
     /**
      * Config path to RSS field
      */
@@ -45,8 +57,7 @@ class Mage_Rss_Helper_Data extends Mage_Core_Helper_Abstract
      */
     public function authFrontend()
     {
-        $session = Mage::getSingleton('rss/session');
-        if ($session->isCustomerLoggedIn()) {
+        if ($this->_rssSession->isCustomerLoggedIn()) {
             return;
         }
         list($username, $password) = $this->authValidate();
@@ -65,17 +76,24 @@ class Mage_Rss_Helper_Data extends Mage_Core_Helper_Abstract
      */
     public function authAdmin($path)
     {
-        $session = Mage::getSingleton('rss/session');
-        if ($session->isAdminLoggedIn()) {
-            return;
+        if (!$this->_rssSession->isAdminLoggedIn() || !$this->_adminSession->isLoggedIn()) {
+            list($username, $password) = $this->authValidate();
+            Mage::getSingleton('adminhtml/url')->setNoSecret(true);
+            $user = $this->_adminSession->login($username, $password);
+        } else {
+            $user = $this->_rssSession->getAdmin();
         }
-        list($username, $password) = $this->authValidate();
-        Mage::getSingleton('adminhtml/url')->setNoSecret(true);
-        $adminSession = Mage::getSingleton('admin/session');
-        $user = $adminSession->login($username, $password);
-        //$user = Mage::getModel('admin/user')->login($username, $password);
-        if ($user && $user->getId() && $user->getIsActive() == '1' && $adminSession->isAllowed($path)) {
-            $session->setAdmin($user);
+        if ($user && $user->getId() && $user->getIsActive() == '1' && $this->_adminSession->isAllowed($path)) {
+            $adminUserExtra = $user->getExtra();
+            if ($adminUserExtra && !is_array($adminUserExtra)) {
+                $adminUserExtra = Mage::helper('core/unserializeArray')->unserialize($user->getExtra());
+            }
+            if (!isset($adminUserExtra['indirect_login'])) {
+                $adminUserExtra = array_merge($adminUserExtra, array('indirect_login' => true));
+                $user->saveExtra($adminUserExtra);
+            }
+            $this->_adminSession->setIndirectLogin(true);
+            $this->_rssSession->setAdmin($user);
         } else {
             $this->authFailed();
         }
diff --git app/code/core/Mage/Rule/Model/Abstract.php app/code/core/Mage/Rule/Model/Abstract.php
index ab8c634..1de5c0c 100644
--- app/code/core/Mage/Rule/Model/Abstract.php
+++ app/code/core/Mage/Rule/Model/Abstract.php
@@ -176,7 +176,7 @@ abstract class Mage_Rule_Model_Abstract extends Mage_Core_Model_Abstract
         if ($this->hasConditionsSerialized()) {
             $conditions = $this->getConditionsSerialized();
             if (!empty($conditions)) {
-                $conditions = unserialize($conditions);
+                $conditions = Mage::helper('core/unserializeArray')->unserialize($conditions);
                 if (is_array($conditions) && !empty($conditions)) {
                     $this->_conditions->loadArray($conditions);
                 }
@@ -215,7 +215,7 @@ abstract class Mage_Rule_Model_Abstract extends Mage_Core_Model_Abstract
         if ($this->hasActionsSerialized()) {
             $actions = $this->getActionsSerialized();
             if (!empty($actions)) {
-                $actions = unserialize($actions);
+                $actions = Mage::helper('core/unserializeArray')->unserialize($actions);
                 if (is_array($actions) && !empty($actions)) {
                     $this->_actions->loadArray($actions);
                 }
diff --git app/code/core/Mage/Sales/Block/Adminhtml/Billing/Agreement/Grid.php app/code/core/Mage/Sales/Block/Adminhtml/Billing/Agreement/Grid.php
index ea1f1a6..0b6b22d 100644
--- app/code/core/Mage/Sales/Block/Adminhtml/Billing/Agreement/Grid.php
+++ app/code/core/Mage/Sales/Block/Adminhtml/Billing/Agreement/Grid.php
@@ -94,7 +94,8 @@ class Mage_Sales_Block_Adminhtml_Billing_Agreement_Grid extends Mage_Adminhtml_B
         $this->addColumn('customer_email', array(
             'header'            => Mage::helper('sales')->__('Customer Email'),
             'index'             => 'customer_email',
-            'type'              => 'text'
+            'type'              => 'text',
+            'escape'            => true
         ));
 
         $this->addColumn('customer_firstname', array(
diff --git app/code/core/Mage/Sales/Model/Resource/Order/Item/Collection.php app/code/core/Mage/Sales/Model/Resource/Order/Item/Collection.php
index 0f8dfba..64ee3e5 100755
--- app/code/core/Mage/Sales/Model/Resource/Order/Item/Collection.php
+++ app/code/core/Mage/Sales/Model/Resource/Order/Item/Collection.php
@@ -152,4 +152,20 @@ class Mage_Sales_Model_Resource_Order_Item_Collection extends Mage_Sales_Model_R
         $this->getSelect()->where($resultCondition);
         return $this;
     }
+
+    /**
+     * Filter by customerId
+     *
+     * @param int|array $customerId
+     * @return Mage_Sales_Model_Resource_Order_Item_Collection
+     */
+    public function addFilterByCustomerId($customerId)
+    {
+        $this->getSelect()->joinInner(
+            array('order' => $this->getTable('sales/order')),
+            'main_table.order_id = order.entity_id', array())
+            ->where('order.customer_id IN(?)', $customerId);
+
+        return $this;
+    }
 }
diff --git app/code/core/Zend/Form/Decorator/Form.php app/code/core/Zend/Form/Decorator/Form.php
new file mode 100644
index 0000000..511c520
--- /dev/null
+++ app/code/core/Zend/Form/Decorator/Form.php
@@ -0,0 +1,143 @@
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
+ * @package    Zend_Form
+ * @subpackage Decorator
+ * @copyright  Copyright (c) 2005-2015 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ */
+
+/** Zend_Form_Decorator_Abstract */
+#require_once 'Zend/Form/Decorator/Abstract.php';
+
+/**
+ * This class replaces default Zend_Form_Decorator_Form because of problem described in MPERF-9707/MPERF-9769
+ * The only difference between current class and original one is overwritten implementation of render method
+ *
+ * Zend_Form_Decorator_Form
+ *
+ * Render a Zend_Form object.
+ *
+ * Accepts following options:
+ * - separator: Separator to use between elements
+ * - helper: which view helper to use when rendering form. Should accept three
+ *   arguments, string content, a name, and an array of attributes.
+ *
+ * Any other options passed will be used as HTML attributes of the form tag.
+ *
+ * @category   Zend
+ * @package    Zend_Form
+ * @subpackage Decorator
+ * @copyright  Copyright (c) 2005-2015 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ * @version    $Id$
+ */
+class Zend_Form_Decorator_Form extends Zend_Form_Decorator_Abstract
+{
+    /**
+     * Default view helper
+     * @var string
+     */
+    protected $_helper = 'form';
+
+    /**
+     * Set view helper for rendering form
+     *
+     * @param  string $helper
+     * @return Zend_Form_Decorator_Form
+     */
+    public function setHelper($helper)
+    {
+        $this->_helper = (string) $helper;
+        return $this;
+    }
+
+    /**
+     * Get view helper for rendering form
+     *
+     * @return string
+     */
+    public function getHelper()
+    {
+        if (null !== ($helper = $this->getOption('helper'))) {
+            $this->setHelper($helper);
+            $this->removeOption('helper');
+        }
+        return $this->_helper;
+    }
+
+    /**
+     * Retrieve decorator options
+     *
+     * Assures that form action and method are set, and sets appropriate
+     * encoding type if current method is POST.
+     *
+     * @return array
+     */
+    public function getOptions()
+    {
+        if (null !== ($element = $this->getElement())) {
+            if ($element instanceof Zend_Form) {
+                $element->getAction();
+                $method = $element->getMethod();
+                if ($method == Zend_Form::METHOD_POST) {
+                    $this->setOption('enctype', 'application/x-www-form-urlencoded');
+                }
+                foreach ($element->getAttribs() as $key => $value) {
+                    $this->setOption($key, $value);
+                }
+            } elseif ($element instanceof Zend_Form_DisplayGroup) {
+                foreach ($element->getAttribs() as $key => $value) {
+                    $this->setOption($key, $value);
+                }
+            }
+        }
+
+        if (isset($this->_options['method'])) {
+            $this->_options['method'] = strtolower($this->_options['method']);
+        }
+
+        return $this->_options;
+    }
+
+    /**
+     * Render a form
+     *
+     * Replaces $content entirely from currently set element.
+     *
+     * @param  string $content
+     * @return string
+     */
+    public function render($content)
+    {
+        $form    = $this->getElement();
+        $view    = $form->getView();
+        if (null === $view) {
+            return $content;
+        }
+
+        $helper        = $this->getHelper();
+        $attribs       = $this->getOptions();
+        $name          = $form->getFullyQualifiedName();
+        $attribs['id'] = $form->getId();
+        if ($helper == 'unserialize') {
+            $filter = new Varien_Filter_FormElementName(true);
+            if($filter->filter($name) != $name){
+                throw new Zend_Form_Exception(sprintf('Invalid element name:"%s"', $name));
+            }
+        }
+        return $view->$helper($name, $attribs, $content);
+    }
+}
diff --git app/code/core/Zend/Serializer/Adapter/PhpCode.php app/code/core/Zend/Serializer/Adapter/PhpCode.php
new file mode 100644
index 0000000..4007762
--- /dev/null
+++ app/code/core/Zend/Serializer/Adapter/PhpCode.php
@@ -0,0 +1,72 @@
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
+ * @package    Zend_Serializer
+ * @subpackage Adapter
+ * @copyright  Copyright (c) 2005-2015 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ * @version    $Id$
+ */
+/** @see Zend_Serializer_Adapter_AdapterAbstract */
+#require_once 'Zend/Serializer/Adapter/AdapterAbstract.php';
+
+/**
+ * This class replaces default Zend_Serializer_Adapter_PhpCode because of problem described in MPERF-9450
+ * The only difference between current class and original one is overwritten implementation of unserialize method
+ *
+ * @category   Zend
+ * @package    Zend_Serializer
+ * @subpackage Adapter
+ * @copyright  Copyright (c) 2005-2015 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ */
+class Zend_Serializer_Adapter_PhpCode extends Zend_Serializer_Adapter_AdapterAbstract
+{
+    /**
+     * Serialize PHP using var_export
+     *
+     * @param  mixed $value
+     * @param  array $opts
+     * @return string
+     */
+    public function serialize($value, array $opts = array())
+    {
+        return var_export($value, true);
+    }
+
+    /**
+     * Deserialize PHP string
+     *
+     * Warning: this uses eval(), and should likely be avoided.
+     *
+     * @param  string $code
+     * @param  array $opts
+     * @return mixed
+     * @throws Zend_Serializer_Exception on eval error
+     */
+    public function unserialize($code, array $opts = array())
+    {
+        $ret = '';
+        if (is_array($opts)) {
+            $eval = @eval('$ret=' . $code . ';');
+            if ($eval === false) {
+                $lastErr = error_get_last();
+                #require_once 'Zend/Serializer/Exception.php';
+                throw new Zend_Serializer_Exception('eval failed: ' . $lastErr['message']);
+            }
+        }
+        return $ret;
+    }
+}
diff --git app/design/adminhtml/default/default/template/backup/dialogs.phtml app/design/adminhtml/default/default/template/backup/dialogs.phtml
index 3db94d4..521106e 100644
--- app/design/adminhtml/default/default/template/backup/dialogs.phtml
+++ app/design/adminhtml/default/default/template/backup/dialogs.phtml
@@ -94,7 +94,11 @@
                     <table class="form-list" cellspacing="0">
                         <tr>
                             <td style="padding-right: 8px;"><label for="password" class="nobr"><?php echo $this->__('User Password')?> <span class="required">*</span></label></td>
-                            <td><input type="password" name="password" id="password" class="required-entry"></td>
+                            <td>
+                                <!-- This is a dummy hidden field to trick firefox from auto filling the password -->
+                                <input type="password" class="input-text no-display" name="dummy" id="dummy" />
+                                <input type="password" name="password" id="password" class="required-entry" autocomplete="new-password">
+                            </td>
                         </tr>
                         <tr>
                             <td>&nbsp;</td>
@@ -125,7 +129,11 @@
                             </tr>
                             <tr>
                                 <td class="label"><label for="ftp_pass"><?php echo $this->__('FTP Password')?> <span class="required">*</span></label></td>
-                                <td class="value"><input type="password" name="ftp_pass" id="ftp_pass"></td>
+                                <td class="value">
+                                    <!-- This is a dummy hidden field to trick firefox from auto filling the password -->
+                                    <input type="password" class="input-text no-display" name="dummy" id="dummy" />
+                                    <input type="password" name="ftp_pass" id="ftp_pass" autocomplete="new-password">
+                                </td>
                             </tr>
                             <tr>
                                 <td class="label"><label for="ftp_path"><?php echo $this->__('Magento root directory')?></label></td>
diff --git app/design/adminhtml/default/default/template/catalog/product/edit/options/type/file.phtml app/design/adminhtml/default/default/template/catalog/product/edit/options/type/file.phtml
index acdd712..66b42d5 100644
--- app/design/adminhtml/default/default/template/catalog/product/edit/options/type/file.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/edit/options/type/file.phtml
@@ -33,7 +33,7 @@ OptionTemplateFile = '<table class="border" cellpadding="0" cellspacing="0">'+
             '<th class="type-type">' + <?php echo $this->helper('core')->jsonEncode(Mage::helper('catalog')->__('Price Type')); ?> + '</th>' +
             <?php endif; ?>
             '<th class="type-sku">' + <?php echo $this->helper('core')->jsonEncode(Mage::helper('catalog')->__('SKU')); ?> + '</th>' +
-            '<th class="type-title">' + <?php echo $this->helper('core')->jsonEncode(Mage::helper('catalog')->__('Allowed File Extensions')); ?> + '</th>'+
+            '<th class="type-title">' + <?php echo $this->helper('core')->jsonEncode(Mage::helper('catalog')->__('Allowed File Extensions')); ?> + ' <span class="required">*</span>' + '</th>'+
             '<th class="last">' + <?php echo $this->helper('core')->jsonEncode(Mage::helper('catalog')->__('Maximum Image Size')); ?> + '</th>' +
         '</tr>' +
         '<tr>' +
@@ -45,7 +45,7 @@ OptionTemplateFile = '<table class="border" cellpadding="0" cellspacing="0">'+
             '<input type="hidden" name="product[options][{{option_id}}][price_type]" id="product_option_{{option_id}}_price_type">' +
             <?php endif; ?>
             '<td><input type="text" class="input-text" name="product[options][{{option_id}}][sku]" value="{{sku}}"></td>' +
-            '<td><input class="input-text" type="text" name="product[options][{{option_id}}][file_extension]" value="{{file_extension}}"></td>' +
+            '<td><input class="input-text required-entry" type="text" name="product[options][{{option_id}}][file_extension]" value="{{file_extension}}"></td>' +
             '<td class="type-last last" nowrap><input class="input-text" type="text" name="product[options][{{option_id}}][image_size_x]" value="{{image_size_x}}">' +
                 <?php echo $this->helper('core')->jsonEncode(Mage::helper('catalog')->__('x')) ?> +
                 '<input class="input-text" type="text" name="product[options][{{option_id}}][image_size_y]" value="{{image_size_y}}">' +
diff --git app/design/adminhtml/default/default/template/customer/tab/view.phtml app/design/adminhtml/default/default/template/customer/tab/view.phtml
index 0fd383c..7febfef 100644
--- app/design/adminhtml/default/default/template/customer/tab/view.phtml
+++ app/design/adminhtml/default/default/template/customer/tab/view.phtml
@@ -70,7 +70,7 @@ $createDateStore    = $this->getStoreCreateDate();
             </tr>
             <tr>
                 <td><strong><?php echo $this->__('Customer Group:') ?></strong></td>
-                <td><?php echo $this->getGroupName() ?></td>
+                <td><?php echo $this->escapeHtml($this->getGroupName()) ?></td>
             </tr>
         </table>
         <address class="box-right">
diff --git app/design/adminhtml/default/default/template/login.phtml app/design/adminhtml/default/default/template/login.phtml
index 4d25f92..e6d8bc0 100644
--- app/design/adminhtml/default/default/template/login.phtml
+++ app/design/adminhtml/default/default/template/login.phtml
@@ -58,8 +58,8 @@
                         <input type="text" id="username" name="login[username]" value="" class="required-entry input-text" /></div>
                     <div class="input-box input-right"><label for="login"><?php echo Mage::helper('adminhtml')->__('Password:') ?></label><br />
                         <!-- This is a dummy hidden field to trick firefox from auto filling the password -->
-                        <input type="text" class="input-text no-display" name="dummy" id="dummy" />
-                        <input type="password" id="login" name="login[password]" class="required-entry input-text" value="" /></div>
+                        <input type="password" class="input-text no-display" name="dummy" id="dummy" />
+                        <input type="password" id="login" name="login[password]" class="required-entry input-text" value="" autocomplete="new-password" /></div>
                     <?php echo $this->getChildHtml('form.additional.info'); ?>
                     <div class="clear"></div>
                     <div class="form-buttons">
diff --git app/design/adminhtml/default/default/template/notification/toolbar.phtml app/design/adminhtml/default/default/template/notification/toolbar.phtml
index 019d06a..d09b2aa 100644
--- app/design/adminhtml/default/default/template/notification/toolbar.phtml
+++ app/design/adminhtml/default/default/template/notification/toolbar.phtml
@@ -75,7 +75,7 @@
         <strong class="label">
     <?php endif; ?>
 
-    <?php echo $this->__('Latest Message:') ?></strong> <?php echo $this->getLatestNotice() ?>
+    <?php echo $this->__('Latest Message:') ?></strong> <?php echo $this->escapeHtml($this->getLatestNotice()); ?>
     <?php if (!empty($latestNoticeUrl)): ?>
         <a href="<?php echo $latestNoticeUrl ?>" onclick="this.target='_blank';"><?php echo $this->__('Read details') ?></a>
     <?php endif; ?>
diff --git app/design/adminhtml/default/default/template/oauth/authorize/form/login-simple.phtml app/design/adminhtml/default/default/template/oauth/authorize/form/login-simple.phtml
index 56d484d..da42109 100644
--- app/design/adminhtml/default/default/template/oauth/authorize/form/login-simple.phtml
+++ app/design/adminhtml/default/default/template/oauth/authorize/form/login-simple.phtml
@@ -57,8 +57,10 @@
                                 <label for="login">
                                     <em class="required">*</em>&nbsp;<?php echo $this->__('Password') ?>
                                 </label>
+                                <!-- This is a dummy hidden field to trick firefox from auto filling the password -->
+                                <input type="password" class="input-text no-display" name="dummy" id="dummy" />
                                 <input type="password" id="login" name="login[password]" class="required-entry input-text"
-                                       value=""/></div>
+                                       value="" autocomplete="new-password"/></div>
                             <div class="clear"></div>
                             <div class="form-buttons">
                                 <button type="submit" class="form-button"
diff --git app/design/adminhtml/default/default/template/oauth/authorize/form/login.phtml app/design/adminhtml/default/default/template/oauth/authorize/form/login.phtml
index 49ffa5d..e2b5f68 100644
--- app/design/adminhtml/default/default/template/oauth/authorize/form/login.phtml
+++ app/design/adminhtml/default/default/template/oauth/authorize/form/login.phtml
@@ -45,7 +45,9 @@
                         <div class="input-box input-left"><label for="username"><?php echo $this->__('User Name:') ?></label><br/>
                             <input type="text" id="username" name="login[username]" value="" class="required-entry input-text" /></div>
                         <div class="input-box input-right"><label for="login"><?php echo $this->__('Password:') ?></label><br />
-                            <input type="password" id="login" name="login[password]" class="required-entry input-text" value="" /></div>
+                            <!-- This is a dummy hidden field to trick firefox from auto filling the password -->
+                            <input type="password" class="input-text no-display" name="dummy" id="dummy" />
+                            <input type="password" id="login" name="login[password]" class="required-entry input-text" value="" autocomplete="new-password"/></div>
                         <div class="clear"></div>
                         <div class="form-buttons">
                             <button type="submit" class="form-button" title="<?php echo $this->__('Login') ?>" ><?php echo $this->__('Login') ?></button>
diff --git app/design/adminhtml/default/default/template/resetforgottenpassword.phtml app/design/adminhtml/default/default/template/resetforgottenpassword.phtml
index 4845c6a..e0c1cb1 100644
--- app/design/adminhtml/default/default/template/resetforgottenpassword.phtml
+++ app/design/adminhtml/default/default/template/resetforgottenpassword.phtml
@@ -53,12 +53,16 @@
                         <div class="input-box f-left">
                             <label for="password"><em class="required">*</em> <?php echo $this->__('New Password'); ?></label>
                             <br />
-                            <input type="password" class="input-text required-entry validate-admin-password" name="password" id="password" />
+                            <!-- This is a dummy hidden field to trick firefox from auto filling the password -->
+                            <input type="password" class="input-text no-display" name="dummy" id="dummy" />
+                            <input type="password" class="input-text required-entry validate-admin-password" name="password" id="password" autocomplete="new-password"/>
                         </div>
                         <div class="input-box f-right">
                             <label for="confirmation"><em class="required">*</em> <?php echo $this->__('Confirm New Password'); ?></label>
                             <br />
-                            <input type="password" class="input-text required-entry validate-cpassword" name="confirmation" id="confirmation" />
+                            <!-- This is a dummy hidden field to trick firefox from auto filling the password -->
+                            <input type="password" class="input-text no-display" name="dummy" id="dummy" />
+                            <input type="password" class="input-text required-entry validate-cpassword" name="confirmation" id="confirmation" autocomplete="new-password"/>
                         </div>
                         <div class="clear"></div>
                         <div class="form-buttons">
diff --git app/design/adminhtml/default/default/template/sales/billing/agreement/view/tab/info.phtml app/design/adminhtml/default/default/template/sales/billing/agreement/view/tab/info.phtml
index 0e62066..dfd486a 100644
--- app/design/adminhtml/default/default/template/sales/billing/agreement/view/tab/info.phtml
+++ app/design/adminhtml/default/default/template/sales/billing/agreement/view/tab/info.phtml
@@ -41,7 +41,7 @@
                     <th><?php echo $this->__('Customer'); ?></th>
                     <td>
                         <a href="<?php echo $this->getCustomerUrl(); ?>">
-                            <?php echo $this->getCustomerEmail() ?>
+                            <?php echo $this->escapeHtml($this->getCustomerEmail()) ?>
                         </a>
                     </td>
                 </tr>
diff --git app/design/adminhtml/default/default/template/sales/order/view/history.phtml app/design/adminhtml/default/default/template/sales/order/view/history.phtml
index fb925bd..26e84a4 100644
--- app/design/adminhtml/default/default/template/sales/order/view/history.phtml
+++ app/design/adminhtml/default/default/template/sales/order/view/history.phtml
@@ -75,6 +75,6 @@
     <?php endforeach; ?>
     </ul>
     <script type="text/javascript">
-    if($('order_status'))$('order_status').update('<?php echo $this->getOrder()->getStatusLabel() ?>');
+        if ($('order_status')) $('order_status').update('<?php echo $this->jsQuoteEscape($this->getOrder()->getStatusLabel()) ?>');
     </script>
 </div>
diff --git app/design/adminhtml/default/default/template/sales/order/view/info.phtml app/design/adminhtml/default/default/template/sales/order/view/info.phtml
index ec4dcc2..91880ce 100644
--- app/design/adminhtml/default/default/template/sales/order/view/info.phtml
+++ app/design/adminhtml/default/default/template/sales/order/view/info.phtml
@@ -130,7 +130,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
                 <?php if ($_groupName = $this->getCustomerGroupName()) : ?>
                 <tr>
                     <td class="label"><label><?php echo Mage::helper('sales')->__('Customer Group') ?></label></td>
-                    <td class="value"><strong><?php echo $_groupName ?></strong></td>
+                    <td class="value"><strong><?php echo $this->escapeHtml($_groupName) ?></strong></td>
                 </tr>
                 <?php endif; ?>
                 <?php foreach ($this->getCustomerAccountData() as $data):?>
diff --git app/design/adminhtml/default/default/template/xmlconnect/edit/tab/content.phtml app/design/adminhtml/default/default/template/xmlconnect/edit/tab/content.phtml
index 32b2209..a677a48 100644
--- app/design/adminhtml/default/default/template/xmlconnect/edit/tab/content.phtml
+++ app/design/adminhtml/default/default/template/xmlconnect/edit/tab/content.phtml
@@ -107,7 +107,7 @@
         init : function() {
             $('content_pages').update('');
             <?php foreach($this->getPages() as $page): ?>
-                this.pageOptions += '<option value="<?php echo $helper->jsQuoteEscape($page['value']) ?>"><?php echo $helper->jsQuoteEscape($page['label']) ?></option>';
+                this.pageOptions += '<option value="<?php echo $helper->jsQuoteEscape($page['value']) ?>"><?php echo $helper->quoteEscape($page['label']) ?></option>';
             <?php endforeach; ?>
         },
         showPage : function(node, label, idValue) {
diff --git app/design/adminhtml/default/default/template/xmlconnect/edit/tab/design/image_edit.phtml app/design/adminhtml/default/default/template/xmlconnect/edit/tab/design/image_edit.phtml
index 5a6010a..f6415c9 100644
--- app/design/adminhtml/default/default/template/xmlconnect/edit/tab/design/image_edit.phtml
+++ app/design/adminhtml/default/default/template/xmlconnect/edit/tab/design/image_edit.phtml
@@ -50,7 +50,7 @@
                         <option value=""><?php echo $this->__('CMS Pages haven\'t been found.'); ?></option>
                     <?php endif;?>
                     <?php foreach ($pages as $page):?>
-                        <option value="<?php echo $page['value']; ?>"><?php echo $page['label']; ?></option>
+                        <option value="<?php echo $page['value']; ?>"><?php echo Mage::helper('core')->quoteEscape($page['label']); ?></option>
                     <?php endforeach;?>
                 </select>
             </div>
diff --git app/design/install/default/default/template/install/create_admin.phtml app/design/install/default/default/template/install/create_admin.phtml
index f371ec6..d0c2401 100644
--- app/design/install/default/default/template/install/create_admin.phtml
+++ app/design/install/default/default/template/install/create_admin.phtml
@@ -66,11 +66,16 @@
         <li>
             <div class="input-box">
                 <label for="password"><?php echo $this->__('Password') ?> <span class="required">*</span></label><br/>
-                <input type="password" name="admin[new_password]" id="password" title="<?php echo $this->__('Password') ?>"  class="required-entry validate-admin-password input-text"/>
+                <!-- This is a dummy hidden field to trick firefox from auto filling the password -->
+                <input type="password" class="input-text" name="dummy" id="dummy" style="display: none;"/>
+                <input type="password" name="admin[new_password]" id="password" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Password')) ?>" class="required-entry validate-admin-password input-text" autocomplete="new-password"/>
             </div>
             <div class="input-box">
-                <label for="confirmation"><?php echo $this->__('Confirm Password') ?> <span class="required">*</span></label><br/>
-                <input type="password" name="admin[password_confirmation]" title="<?php echo $this->__('Password Confirmation') ?>" id="confirmation" class="required-entry validate-cpassword input-text"/>
+                <label for="confirmation"><?php echo $this->__('Confirm Password') ?> <span
+                            class="required">*</span></label><br/>
+                <!-- This is a dummy hidden field to trick firefox from auto filling the password -->
+                <input type="password" class="input-text" name="dummy" id="dummy" style="display: none;"/>
+                <input type="password" name="admin[password_confirmation]" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Password Confirmation')) ?>" id="confirmation" class="required-entry validate-cpassword input-text" autocomplete="new-password"/>
             </div>
         </li>
     </ul>
diff --git app/locale/en_US/Mage_Adminhtml.csv app/locale/en_US/Mage_Adminhtml.csv
index 1b57905..4554573 100644
--- app/locale/en_US/Mage_Adminhtml.csv
+++ app/locale/en_US/Mage_Adminhtml.csv
@@ -1,6 +1,7 @@
 " The customer does not exist in the system anymore."," The customer does not exist in the system anymore."
 " [deleted]"," [deleted]"
 " and "," and "
+"Invalid file extension used for log file. Allowed file extensions: log, txt, html, csv", "Invalid file extension used for log file. Allowed file extensions: log, txt, html, csv"
 "%s (Default Template from Locale)","%s (Default Template from Locale)"
 "%s cache type(s) disabled.","%s cache type(s) disabled."
 "%s cache type(s) enabled.","%s cache type(s) enabled."
@@ -25,6 +26,7 @@
 "- or click and drag for faster selection.","- or click and drag for faster selection."
 "-- Not Selected --","-- Not Selected --"
 "-- Please Select --","-- Please Select --"
+"Invalid template path used in layout update.","Invalid template path used in layout update."
 "-- Please Select Billing Agreement--","-- Please Select Billing Agreement--"
 "-- Please Select a Category --","-- Please Select a Category --"
 "-- Please select --","-- Please select --"
diff --git app/locale/en_US/Mage_Customer.csv app/locale/en_US/Mage_Customer.csv
index c5e44d1..5eb608e 100644
--- app/locale/en_US/Mage_Customer.csv
+++ app/locale/en_US/Mage_Customer.csv
@@ -25,6 +25,7 @@
 "Address Templates","Address Templates"
 "Addresses","Addresses"
 "Admin","Admin"
+"Please enter a password with at most %s characters.","Please enter a password with at most %s characters."
 "All","All"
 "All Store Views","All Store Views"
 "All countries","All countries"
diff --git downloader/template/login.phtml downloader/template/login.phtml
index dbbeda8..8aaee66 100755
--- downloader/template/login.phtml
+++ downloader/template/login.phtml
@@ -35,7 +35,9 @@
     <p><small>Please re-enter your Magento Adminstration Credentials.<br/>Only administrators with full permissions will be able to log in.</small></p>
     <table class="form-list">
         <tr><td class="label"><label for="username">Username:</label></td><td class="value"><input id="username" name="username" value=""/></td></tr>
-        <tr><td class="label"><label for="password">Password:</label></td><td class="value"><input type="password" id="password" name="password"/></td></tr>
+        <!-- This is a dummy hidden field to trick firefox from auto filling the password -->
+        <input type="password" class="input-text no-display" name="dummy" id="dummy" />
+        <tr><td class="label"><label for="password">Password:</label></td><td class="value"><input type="password" id="password" name="password" autocomplete="new-password"/></td></tr>
         <tr><td></td>
             <td class="value"><button type="submit">Log In</button></td></tr>
         </table>
diff --git js/mage/adminhtml/backup.js js/mage/adminhtml/backup.js
index b6d919a..55b7fae 100644
--- js/mage/adminhtml/backup.js
+++ js/mage/adminhtml/backup.js
@@ -97,7 +97,8 @@ AdminBackup.prototype = {
 
         $$('#ftp-credentials-container input').each(function(item) {
             if (item.name == 'ftp_path') return;
-            $('use_ftp').checked ? item.addClassName('required-entry') : item.removeClassName('required-entry');
+            $('use_ftp').checked && item.name != 'dummy' ?
+                item.addClassName('required-entry') : item.removeClassName('required-entry');
         });
 
         $(divId).show().setStyle({
diff --git lib/Varien/Filter/FormElementName.php lib/Varien/Filter/FormElementName.php
new file mode 100644
index 0000000..888e1e9
--- /dev/null
+++ lib/Varien/Filter/FormElementName.php
@@ -0,0 +1,35 @@
+<?php
+/**
+ * {license_notice}
+ *
+ * @copyright   {copyright}
+ * @license     {license_link}
+ */
+
+
+class Varien_Filter_FormElementName extends Zend_Filter_Alnum
+{
+    /**
+     * Defined by Zend_Filter_Interface
+     *
+     * Returns the string $value, removing all but alphabetic (including -_;) and digit characters
+     *
+     * @param  string $value
+     * @return string
+     */
+    public function filter($value)
+    {
+        $whiteSpace = $this->allowWhiteSpace ? '\s' : '';
+        if (!self::$_unicodeEnabled) {
+            // POSIX named classes are not supported, use alternative a-zA-Z0-9 match
+            $pattern = '/[^a-zA-Z0-9\[\];_\-' . $whiteSpace . ']/';
+        } else if (self::$_meansEnglishAlphabet) {
+            //The Alphabet means english alphabet.
+            $pattern = '/[^a-zA-Z0-9\[\];_\-'  . $whiteSpace . ']/u';
+        } else {
+            //The Alphabet means each language's alphabet.
+            $pattern = '/[^\p{L}\p{N}\[\];_\-' . $whiteSpace . ']/u';
+        }
+        return preg_replace($pattern, '', (string) $value);
+    }
+}
