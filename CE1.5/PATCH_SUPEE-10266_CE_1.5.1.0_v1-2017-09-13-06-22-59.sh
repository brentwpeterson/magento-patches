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

SUPEE-10266-CE-1.5.1.0 | CE_1.5.1.0 | v1 | e7110b73ad389f7113bc188cf45111cf375b7d17 | Tue Sep 5 13:24:16 2017 +0300 | 791b6e830963b2df210f86bf504709da1d7f9d83..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Admin/Model/Session.php app/code/core/Mage/Admin/Model/Session.php
index 4ef63f7..afd94e3 100644
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
diff --git app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Websites.php app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Websites.php
index d71f534..6f2fbd7 100644
--- app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Websites.php
+++ app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Websites.php
@@ -95,16 +95,19 @@ class Mage_Adminhtml_Block_Catalog_Product_Edit_Tab_Websites extends Mage_Adminh
                 if (!$this->hasWebsite($_website->getId())) {
                     continue;
                 }
-                $this->_storeFromHtml .= '<optgroup label="' . $_website->getName() . '"></optgroup>';
+                $optGroupLabel = $this->escapeHtml($_website->getName());
+                $this->_storeFromHtml .= '<optgroup label="' . $optGroupLabel . '"></optgroup>';
                 foreach ($this->getGroupCollection($_website) as $_group) {
-                    $this->_storeFromHtml .= '<optgroup label="&nbsp;&nbsp;&nbsp;&nbsp;' . $_group->getName() . '">';
+                    $optGroupName = $this->escapeHtml($_group->getName());
+                    $this->_storeFromHtml .= '<optgroup label="&nbsp;&nbsp;&nbsp;&nbsp;' . $optGroupName . '">';
                     foreach ($this->getStoreCollection($_group) as $_store) {
-                        $this->_storeFromHtml .= '<option value="' . $_store->getId() . '">&nbsp;&nbsp;&nbsp;&nbsp;' . $_store->getName() . '</option>';
+                        $this->_storeFromHtml .= '<option value="' . $_store->getId() . '">&nbsp;&nbsp;&nbsp;&nbsp;';
+                        $this->_storeFromHtml .= $this->escapeHtml($_store->getName()) . '</option>';
                     }
                 }
                 $this->_storeFromHtml .= '</optgroup>';
             }
-            $this->_storeFromHtml.= '</select>';
+            $this->_storeFromHtml .= '</select>';
         }
         return str_replace('__store_identifier__', $storeTo->getId(), $this->_storeFromHtml);
     }
diff --git app/code/core/Mage/Adminhtml/Block/Notification/Grid/Renderer/Notice.php app/code/core/Mage/Adminhtml/Block/Notification/Grid/Renderer/Notice.php
index c3c4e97..1d74092 100644
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
diff --git app/code/core/Mage/Adminhtml/Block/Notification/Window.php app/code/core/Mage/Adminhtml/Block/Notification/Window.php
index 1554853..9213db7 100644
--- app/code/core/Mage/Adminhtml/Block/Notification/Window.php
+++ app/code/core/Mage/Adminhtml/Block/Notification/Window.php
@@ -53,17 +53,17 @@ class Mage_Adminhtml_Block_Notification_Window extends Mage_Adminhtml_Block_Noti
     {
         parent::_construct();
 
-        $this->setHeaderText(addslashes($this->__('Incoming Message')));
-        $this->setCloseText(addslashes($this->__('close')));
-        $this->setReadDetailsText(addslashes($this->__('Read details')));
-        $this->setNoticeText(addslashes($this->__('NOTICE')));
-        $this->setMinorText(addslashes($this->__('MINOR')));
-        $this->setMajorText(addslashes($this->__('MAJOR')));
-        $this->setCriticalText(addslashes($this->__('CRITICAL')));
+        $this->setHeaderText($this->escapeHtml($this->__('Incoming Message')));
+        $this->setCloseText($this->escapeHtml($this->__('close')));
+        $this->setReadDetailsText($this->escapeHtml($this->__('Read details')));
+        $this->setNoticeText($this->escapeHtml($this->__('NOTICE')));
+        $this->setMinorText($this->escapeHtml($this->__('MINOR')));
+        $this->setMajorText($this->escapeHtml($this->__('MAJOR')));
+        $this->setCriticalText($this->escapeHtml($this->__('CRITICAL')));
 
 
-        $this->setNoticeMessageText(addslashes($this->getLastNotice()->getTitle()));
-        $this->setNoticeMessageUrl(addslashes($this->getLastNotice()->getUrl()));
+        $this->setNoticeMessageText($this->escapeHtml($this->getLastNotice()->getTitle()));
+        $this->setNoticeMessageUrl($this->escapeUrl($this->getLastNotice()->getUrl()));
 
         switch ($this->getLastNotice()->getSeverity()) {
             default:
diff --git app/code/core/Mage/Adminhtml/Block/Widget/Form/Container.php app/code/core/Mage/Adminhtml/Block/Widget/Form/Container.php
index bb0af66..b9e212c 100644
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
diff --git app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Options.php app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Options.php
index 43fcdf9..4f17753 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Options.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Options.php
@@ -49,16 +49,16 @@ class Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Options extends Mage_Admi
                 $res = array();
                 foreach ($value as $item) {
                     if (isset($options[$item])) {
-                        $res[] = $options[$item];
+                        $res[] = $this->escapeHtml($options[$item]);
                     }
                     elseif ($showMissingOptionValues) {
-                        $res[] = $item;
+                        $res[] = $this->escapeHtml($item);
                     }
                 }
                 return implode(', ', $res);
             }
             elseif (isset($options[$value])) {
-                return $options[$value];
+                return $this->escapeHtml($options[$value]);
             }
             return '';
         }
diff --git app/code/core/Mage/Adminhtml/Controller/Action.php app/code/core/Mage/Adminhtml/Controller/Action.php
index ef9d18d..702db0a 100644
--- app/code/core/Mage/Adminhtml/Controller/Action.php
+++ app/code/core/Mage/Adminhtml/Controller/Action.php
@@ -43,6 +43,13 @@ class Mage_Adminhtml_Controller_Action extends Mage_Core_Controller_Varien_Actio
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
@@ -154,7 +161,7 @@ class Mage_Adminhtml_Controller_Action extends Mage_Core_Controller_Varien_Actio
         $_isValidSecretKey = true;
         $_keyErrorMsg = '';
         if (Mage::getSingleton('admin/session')->isLoggedIn()) {
-            if ($this->getRequest()->isPost()) {
+            if ($this->getRequest()->isPost() || $this->_checkIsForcedFormKeyAction()) {
                 $_isValidFormKey = $this->_validateFormKey();
                 $_keyErrorMsg = Mage::helper('adminhtml')->__('Invalid Form Key. Please refresh the page.');
             } elseif (Mage::getSingleton('adminhtml/url')->useSecretKey()) {
@@ -171,6 +178,9 @@ class Mage_Adminhtml_Controller_Action extends Mage_Core_Controller_Varien_Actio
                     'message' => $_keyErrorMsg
                 )));
             } else {
+                if ($_keyErrorMsg != ''){
+                    Mage::getSingleton('adminhtml/session')->addError($_keyErrorMsg);
+                }
                 $this->_redirect( Mage::getSingleton('admin/session')->getUser()->getStartupPageUrl() );
             }
             return $this;
@@ -372,4 +382,27 @@ class Mage_Adminhtml_Controller_Action extends Mage_Core_Controller_Varien_Actio
         }
         return true;
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
index 986a952..afe468b 100644
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
+            if (strpos($path, '../') !== false) {
+                throw new Exception();
+            }
+        }
+    }
 }
diff --git app/code/core/Mage/Adminhtml/controllers/CustomerController.php app/code/core/Mage/Adminhtml/controllers/CustomerController.php
index 7fcbab9..927fe6e 100644
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
index f755e65..62398b7 100644
--- app/code/core/Mage/Adminhtml/controllers/Newsletter/QueueController.php
+++ app/code/core/Mage/Adminhtml/controllers/Newsletter/QueueController.php
@@ -64,6 +64,10 @@ class Mage_Adminhtml_Newsletter_QueueController extends Mage_Adminhtml_Controlle
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
index 6da6cd7..40abed6 100644
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
diff --git app/code/core/Mage/Checkout/controllers/CartController.php app/code/core/Mage/Checkout/controllers/CartController.php
index 51659ee..a1066ee 100644
--- app/code/core/Mage/Checkout/controllers/CartController.php
+++ app/code/core/Mage/Checkout/controllers/CartController.php
@@ -236,17 +236,19 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
     public function addgroupAction()
     {
         $orderItemIds = $this->getRequest()->getParam('order_items', array());
+        $customerId   = $this->_getCustomerSession()->getCustomerId();
 
-        if (!is_array($orderItemIds) || !$this->_validateFormKey()) {
+        if (!is_array($orderItemIds) || !$this->_validateFormKey() || !$customerId) {
             $this->_goBack();
             return;
         }
 
+        /* @var $itemsCollection Mage_Sales_Model_Mysql4_Order_Item_Collection */
         $itemsCollection = Mage::getModel('sales/order_item')
             ->getCollection()
+            ->addFilterByCustomerId($customerId)
             ->addIdFilter($orderItemIds)
             ->load();
-        /* @var $itemsCollection Mage_Sales_Model_Mysql4_Order_Item_Collection */
         $cart = $this->_getCart();
         foreach ($itemsCollection as $item) {
             try {
@@ -530,4 +532,14 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
 
         $this->_goBack();
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
diff --git app/code/core/Mage/Core/Model/File/Validator/Image.php app/code/core/Mage/Core/Model/File/Validator/Image.php
index d01b9b4..1b4e3e4 100644
--- app/code/core/Mage/Core/Model/File/Validator/Image.php
+++ app/code/core/Mage/Core/Model/File/Validator/Image.php
@@ -90,6 +90,13 @@ class Mage_Core_Model_File_Validator_Image
         list($imageWidth, $imageHeight, $fileType) = getimagesize($filePath);
         if ($fileType) {
             if ($this->isImageType($fileType)) {
+                /**
+                 * if 'general/reprocess_images/active' false then skip image reprocessing.
+                 * NOTE: If you turn off images reprocessing, then your upload images process may cause security risks.
+                 */
+                if (!Mage::getStoreConfigFlag('general/reprocess_images/active')) {
+                    return null;
+                }
                 //replace tmp image with re-sampled copy to exclude images with malicious data
                 $image = imagecreatefromstring(file_get_contents($filePath));
                 if ($image !== false) {
diff --git app/code/core/Mage/Core/etc/config.xml app/code/core/Mage/Core/etc/config.xml
index d451473..4dee3bc 100644
--- app/code/core/Mage/Core/etc/config.xml
+++ app/code/core/Mage/Core/etc/config.xml
@@ -388,6 +388,9 @@
                     </protected>
                 </public_files_valid_paths>
             </file>
+            <reprocess_images>
+                <active>1</active>
+            </reprocess_images>
         </general>
     </default>
     <stores> <!-- declare routers for installation process -->
diff --git app/code/core/Mage/Rss/Helper/Data.php app/code/core/Mage/Rss/Helper/Data.php
index 881f804..9550716 100644
--- app/code/core/Mage/Rss/Helper/Data.php
+++ app/code/core/Mage/Rss/Helper/Data.php
@@ -34,14 +34,25 @@
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
      * Authenticate customer on frontend
      *
      */
     public function authFrontend()
     {
-        $session = Mage::getSingleton('rss/session');
-        if ($session->isCustomerLoggedIn()) {
+        if ($this->_rssSession->isCustomerLoggedIn()) {
             return;
         }
         list($username, $password) = $this->authValidate();
@@ -60,17 +71,24 @@ class Mage_Rss_Helper_Data extends Mage_Core_Helper_Abstract
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
-        if($user && $user->getId() && $user->getIsActive() == '1' && $adminSession->isAllowed($path)){
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
diff --git app/code/core/Mage/Sales/Model/Mysql4/Order/Item/Collection.php app/code/core/Mage/Sales/Model/Mysql4/Order/Item/Collection.php
index 081c073..8450840 100644
--- app/code/core/Mage/Sales/Model/Mysql4/Order/Item/Collection.php
+++ app/code/core/Mage/Sales/Model/Mysql4/Order/Item/Collection.php
@@ -121,4 +121,20 @@ class Mage_Sales_Model_Mysql4_Order_Item_Collection extends Mage_Sales_Model_Mys
         }
         return $this;
     }
+
+    /**
+     * Filter by customerId
+     *
+     * @param int|array $customerId
+     * @return Mage_Sales_Model_Mysql4_Order_Item_Collection
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
diff --git app/design/adminhtml/default/default/template/catalog/product/edit/options/type/file.phtml app/design/adminhtml/default/default/template/catalog/product/edit/options/type/file.phtml
index 606d5552..45cd073 100644
--- app/design/adminhtml/default/default/template/catalog/product/edit/options/type/file.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/edit/options/type/file.phtml
@@ -31,14 +31,14 @@ OptionTemplateFile = '<table class="border" cellpadding="0" cellspacing="0">'+
             '<th class="type-price"><?php echo Mage::helper('catalog')->__('Price') ?></th>'+
             '<th class="type-type"><?php echo Mage::helper('catalog')->__('Price Type') ?></th>'+
             '<th class="type-sku"><?php echo Mage::helper('catalog')->__('SKU') ?></th>'+
-            '<th class="type-title"><?php echo Mage::helper('catalog')->__('Allowed File Extensions') ?></th>'+
+            '<th class="type-title"><?php echo Mage::helper('catalog')->__('Allowed File Extensions'); ?> <span class="required">*</span></th>'+
             '<th class="last"><?php echo Mage::helper('catalog')->__('Maximum Image Size') ?></th>'+
         '</tr>'+
         '<tr>'+
             '<td><input class="input-text type="text" name="product[options][{{option_id}}][price]" value="{{price}}"></td>'+
             '<td><?php echo $this->getPriceTypeSelectHtml() ?></td>'+
             '<td><input type="text" class="input-text" name="product[options][{{option_id}}][sku]" value="{{sku}}"></td>'+
-            '<td><input class="input-text" type="text" name="product[options][{{option_id}}][file_extension]" value="{{file_extension}}"></td>'+
+    '<td><input class="input-text required-entry" type="text" name="product[options][{{option_id}}][file_extension]" value="{{file_extension}}"></td>' +
             '<td class="type-last last" nowrap><input class="input-text" type="text" name="product[options][{{option_id}}][image_size_x]" value="{{image_size_x}}"> <?php echo Mage::helper('catalog')->__('x') ?> <input class="input-text" type="text" name="product[options][{{option_id}}][image_size_y]" value="{{image_size_y}}"> <?php echo Mage::helper('catalog')->__('px.') ?><br/><?php echo Mage::helper('catalog')->__('leave blank if its not an image') ?></td>'+
         '</tr>'+
     '</table>';
diff --git app/design/adminhtml/default/default/template/customer/tab/view.phtml app/design/adminhtml/default/default/template/customer/tab/view.phtml
index 731e159..b405e39 100644
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
index 18f0b59..520ff83 100644
--- app/design/adminhtml/default/default/template/login.phtml
+++ app/design/adminhtml/default/default/template/login.phtml
@@ -56,7 +56,9 @@
                     <div class="input-box input-left"><label for="username"><?php echo Mage::helper('adminhtml')->__('User Name:') ?></label><br/>
                         <input type="text" id="username" name="login[username]" value="" class="required-entry input-text" /></div>
                     <div class="input-box input-right"><label for="login"><?php echo Mage::helper('adminhtml')->__('Password:') ?></label><br />
-                        <input type="password" id="login" name="login[password]" class="required-entry input-text" value="" /></div>
+                        <!-- This is a dummy hidden field to trick firefox from auto filling the password -->
+                        <input type="password" class="input-text no-display" name="dummy" id="dummy" />
+                        <input type="password" id="login" name="login[password]" class="required-entry input-text" value="" autocomplete="new-password" /></div>
                     <div class="clear"></div>
                     <div class="form-buttons">
                         <a class="left" href="<?php echo Mage::helper('adminhtml')->getUrl('adminhtml/index/forgotpassword', array('_nosecret' => true)) ?>"><?php echo Mage::helper('adminhtml')->__('Forgot your password?') ?></a>
diff --git app/design/adminhtml/default/default/template/notification/toolbar.phtml app/design/adminhtml/default/default/template/notification/toolbar.phtml
index 7e34ff2..612f613 100644
--- app/design/adminhtml/default/default/template/notification/toolbar.phtml
+++ app/design/adminhtml/default/default/template/notification/toolbar.phtml
@@ -83,7 +83,7 @@
         <strong class="label">
     <?php endif; ?>
 
-    <?php echo $this->__('Latest Message:') ?></strong> <?php echo $this->getLatestNotice() ?>
+    <?php echo $this->__('Latest Message:') ?></strong> <?php echo $this->escapeHtml($this->getLatestNotice()); ?>
     <?php if (!empty($latestNoticeUrl)): ?>
         <a href="<?php echo $latestNoticeUrl ?>" onclick="this.target='_blank';"><?php echo $this->__('Read details') ?></a>
     <?php endif; ?>
diff --git app/design/adminhtml/default/default/template/sales/order/view/history.phtml app/design/adminhtml/default/default/template/sales/order/view/history.phtml
index 930f468..d3f4abe 100644
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
index 46fdda0..16ca210 100644
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
diff --git app/design/install/default/default/template/install/create_admin.phtml app/design/install/default/default/template/install/create_admin.phtml
index fca1792..0826e53 100644
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
index 6710b9b..305bd5b 100644
--- app/locale/en_US/Mage_Adminhtml.csv
+++ app/locale/en_US/Mage_Adminhtml.csv
@@ -26,6 +26,7 @@
 "- or click and drag for faster selection.","- or click and drag for faster selection."
 "-- Not Selected --","-- Not Selected --"
 "-- Please Select --","-- Please Select --"
+"Invalid template path used in layout update.","Invalid template path used in layout update."
 "-- Please Select Billing Agreement--","-- Please Select Billing Agreement--"
 "-- Please Select a Category --","-- Please Select a Category --"
 "-- Please select --","-- Please select --"
diff --git downloader/template/login.phtml downloader/template/login.phtml
index dcf62b1..f88f9ad 100755
--- downloader/template/login.phtml
+++ downloader/template/login.phtml
@@ -34,7 +34,9 @@
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
