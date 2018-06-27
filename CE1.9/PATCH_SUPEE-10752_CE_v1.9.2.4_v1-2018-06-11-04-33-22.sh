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


SUPEE-10752_CE_v1.9.2.4 | CE_1.9.2.4 | v1 | 21a859a3088f1c667802d48b1637144c3a040442 | Tue Jun 5 02:11:41 2018 +0300 | ce-1.9.2.4-dev

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Admin/Model/User.php app/code/core/Mage/Admin/Model/User.php
index bbe2b82f1a5..eea1509b035 100644
--- app/code/core/Mage/Admin/Model/User.php
+++ app/code/core/Mage/Admin/Model/User.php
@@ -134,6 +134,10 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
             // Change user password
             $data['password'] = $this->_getEncodedPassword($this->getNewPassword());
             $data['new_password'] = $data['password'];
+            $sessionUser = $this->getSession()->getUser();
+            if ($sessionUser && $sessionUser->getId() == $this->getId()) {
+                $this->getSession()->setUserPasswordChanged(true);
+            }
         } elseif ($this->getPassword() && $this->getPassword() != $this->getOrigData('password')) {
             // New user password
             $data['password'] = $this->_getEncodedPassword($this->getPassword());
@@ -154,6 +158,14 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
         return parent::_beforeSave();
     }
 
+    /**
+     * @return Mage_Admin_Model_Session
+     */
+    protected function getSession()
+    {
+        return  Mage::getSingleton('admin/session');
+    }
+
     /**
      * Save admin user extra data (like configuration sections state)
      *
@@ -400,8 +412,15 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
     public function reload()
     {
         $id = $this->getId();
+        $oldPassword = $this->getPassword();
         $this->setId(null);
         $this->load($id);
+        $isUserPasswordChanged = $this->getSession()->getUserPasswordChanged();
+        if ($this->getPassword() !== $oldPassword && !$isUserPasswordChanged) {
+            $this->setId(null);
+        } elseif ($isUserPasswordChanged) {
+            $this->getSession()->setUserPasswordChanged(false);
+        }
         return $this;
     }
 
diff --git app/code/core/Mage/Adminhtml/Block/Catalog/Product/Composite/Fieldset/Options.php app/code/core/Mage/Adminhtml/Block/Catalog/Product/Composite/Fieldset/Options.php
index 5386407c3ed..5d5644cc973 100644
--- app/code/core/Mage/Adminhtml/Block/Catalog/Product/Composite/Fieldset/Options.php
+++ app/code/core/Mage/Adminhtml/Block/Catalog/Product/Composite/Fieldset/Options.php
@@ -57,6 +57,9 @@ class Mage_Adminhtml_Block_Catalog_Product_Composite_Fieldset_Options extends Ma
      */
     public function getOptionHtml(Mage_Catalog_Model_Product_Option $option)
     {
+        if (!empty($option['file_extension'])) {
+            $option['file_extension'] = $this->escapeHtml($option['file_extension']);
+        }
         $renderer = $this->getOptionRender(
             $this->getGroupOfOption($option->getType())
         );
diff --git app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Options/Option.php app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Options/Option.php
index 20084711e96..a9e0dc683b7 100644
--- app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Options/Option.php
+++ app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Options/Option.php
@@ -286,7 +286,7 @@ class Mage_Adminhtml_Block_Catalog_Product_Edit_Tab_Options_Option extends Mage_
                     $value['price_type'] = $option->getPriceType();
                     $value['sku'] = $this->escapeHtml($option->getSku());
                     $value['max_characters'] = $option->getMaxCharacters();
-                    $value['file_extension'] = $option->getFileExtension();
+                    $value['file_extension'] = $this->escapeHtml($option->getFileExtension());
                     $value['image_size_x'] = $option->getImageSizeX();
                     $value['image_size_y'] = $option->getImageSizeY();
                     if ($this->getProduct()->getStoreId() != '0' &&
diff --git app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Datetime.php app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Datetime.php
index de94f42ef63..c282f620605 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Datetime.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Datetime.php
@@ -169,10 +169,9 @@ class Mage_Adminhtml_Block_Widget_Grid_Column_Filter_Datetime
                     $this->getLocale()->getDateTimeFormat(Mage_Core_Model_Locale::FORMAT_TYPE_SHORT)
                 );
             }
-            return $value;
+            return $this->escapeHtml($value);
         }
 
-        return parent::getEscapedValue($index);
+        return $this->escapeHtml(parent::getEscapedValue($index));
     }
-
 }
diff --git app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
index b989ccc97fb..165a94e8a8a 100644
--- app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
+++ app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
@@ -47,6 +47,18 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
      */
     protected $_value;
 
+    /**
+     * XPath expression for checking layout update
+     *
+     * @var array
+     */
+    protected $_disallowedXPathExpressions = array(
+        '*//template',
+        '*//@template',
+        '//*[@method=\'setTemplate\']',
+        '//*[@method=\'setDataUsingMethod\']//*[text() = \'template\']/../*'
+    );
+
     /**
      * Protected expressions
      *
@@ -114,7 +126,7 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
         }
 
         // if layout update declare custom templates then validate their paths
-        if ($templatePaths = $value->xpath('*//template | *//@template | //*[@method=\'setTemplate\']/*')) {
+        if ($templatePaths = $value->xpath($this->_getXpathValidationExpression())) {
             try {
                 $this->_validateTemplatePath($templatePaths);
             } catch (Exception $e) {
@@ -133,6 +145,15 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
         return true;
     }
 
+    /**
+     * Returns xPath for validate incorrect path to template
+     *
+     * @return string xPath for validate incorrect path to template
+     */
+    protected function _getXpathValidationExpression() {
+        return implode(" | ", $this->_disallowedXPathExpressions);
+    }
+
     /**
      * Validate template path for preventing access to the directory above
      * If template path value has "../" @throws Exception
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/CategoryController.php app/code/core/Mage/Adminhtml/controllers/Catalog/CategoryController.php
index 8798b96c494..2744d7f5800 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/CategoryController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/CategoryController.php
@@ -269,6 +269,9 @@ class Mage_Adminhtml_Catalog_CategoryController extends Mage_Adminhtml_Controlle
         $storeId = $this->getRequest()->getParam('store');
         $refreshTree = 'false';
         if ($data = $this->getRequest()->getPost()) {
+            if (isset($data['general']['path'])) {
+                unset($data['general']['path']);
+            }
             $category->addData($data['general']);
             if (!$category->getId()) {
                 $parentId = $this->getRequest()->getParam('parent');
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
index 7f4fb1e4c1e..2f9f1b2970b 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
@@ -735,6 +735,7 @@ class Mage_Adminhtml_Catalog_ProductController extends Mage_Adminhtml_Controller
             }
 
             try {
+                $product->validate();
                 $product->save();
                 $productId = $product->getId();
 
diff --git app/code/core/Mage/Adminhtml/controllers/Cms/Wysiwyg/ImagesController.php app/code/core/Mage/Adminhtml/controllers/Cms/Wysiwyg/ImagesController.php
index ce531682423..866863c0991 100644
--- app/code/core/Mage/Adminhtml/controllers/Cms/Wysiwyg/ImagesController.php
+++ app/code/core/Mage/Adminhtml/controllers/Cms/Wysiwyg/ImagesController.php
@@ -188,7 +188,11 @@ class Mage_Adminhtml_Cms_Wysiwyg_ImagesController extends Mage_Adminhtml_Control
         if ($thumb !== false) {
             $image = Varien_Image_Adapter::factory('GD2');
             $image->open($thumb);
+            $this->getResponse()->setHeader('Content-type', $image->getMimeTypeWithOutFileType());
+            ob_start();
             $image->display();
+            $this->getResponse()->setBody(ob_get_contents());
+            ob_end_clean();
         } else {
             // todo: genearte some placeholder
         }
diff --git app/code/core/Mage/Adminhtml/controllers/Cms/WysiwygController.php app/code/core/Mage/Adminhtml/controllers/Cms/WysiwygController.php
index 28f87837f35..06bc7fe3ebc 100644
--- app/code/core/Mage/Adminhtml/controllers/Cms/WysiwygController.php
+++ app/code/core/Mage/Adminhtml/controllers/Cms/WysiwygController.php
@@ -46,22 +46,15 @@ class Mage_Adminhtml_Cms_WysiwygController extends Mage_Adminhtml_Controller_Act
         try {
             $image = Varien_Image_Adapter::factory('GD2');
             $image->open($url);
-            $image->display();
         } catch (Exception $e) {
             $image = Varien_Image_Adapter::factory('GD2');
             $image->open(Mage::getSingleton('cms/wysiwyg_config')->getSkinImagePlaceholderPath());
-            $image->display();
-            /*
-            $image = imagecreate(100, 100);
-            $bkgrColor = imagecolorallocate($image,10,10,10);
-            imagefill($image,0,0,$bkgrColor);
-            $textColor = imagecolorallocate($image,255,255,255);
-            imagestring($image, 4, 10, 10, 'Skin image', $textColor);
-            header('Content-type: image/png');
-            imagepng($image);
-            imagedestroy($image);
-            */
         }
+        $this->getResponse()->setHeader('Content-type', $image->getMimeTypeWithOutFileType());
+        ob_start();
+        $image->display();
+        $this->getResponse()->setBody(ob_get_contents());
+        ob_end_clean();
     }
 
     /**
diff --git app/code/core/Mage/Adminhtml/controllers/CustomerController.php app/code/core/Mage/Adminhtml/controllers/CustomerController.php
index 466f5ee59ee..2c8eeb35eec 100644
--- app/code/core/Mage/Adminhtml/controllers/CustomerController.php
+++ app/code/core/Mage/Adminhtml/controllers/CustomerController.php
@@ -333,6 +333,7 @@ class Mage_Adminhtml_CustomerController extends Mage_Adminhtml_Controller_Action
                 // Force new customer confirmation
                 if ($isNewCustomer) {
                     $customer->setPassword($data['account']['password']);
+                    $customer->setPasswordCreatedAt(time());
                     $customer->setForceConfirmed(true);
                     if ($customer->getPassword() == 'auto') {
                         $sendPassToEmail = true;
diff --git app/code/core/Mage/Adminhtml/controllers/System/StoreController.php app/code/core/Mage/Adminhtml/controllers/System/StoreController.php
index e682eee9c19..efab7c06a81 100644
--- app/code/core/Mage/Adminhtml/controllers/System/StoreController.php
+++ app/code/core/Mage/Adminhtml/controllers/System/StoreController.php
@@ -33,6 +33,16 @@
  */
 class Mage_Adminhtml_System_StoreController extends Mage_Adminhtml_Controller_Action
 {
+   /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions(array('deleteWebsitePost', 'deleteGroupPost', 'deleteStorePost'));
+        return parent::preDispatch();
+    }
 
     /**
      * Init actions
diff --git app/code/core/Mage/Catalog/Model/Product.php app/code/core/Mage/Catalog/Model/Product.php
index d52ef8a876b..0c1a5afe942 100644
--- app/code/core/Mage/Catalog/Model/Product.php
+++ app/code/core/Mage/Catalog/Model/Product.php
@@ -460,6 +460,8 @@ class Mage_Catalog_Model_Product extends Mage_Catalog_Model_Abstract
 
     /**
      * Check product options and type options and save them, too
+     *
+     * @throws Mage_Core_Exception
      */
     protected function _beforeSave()
     {
@@ -485,6 +487,12 @@ class Mage_Catalog_Model_Product extends Mage_Catalog_Model_Abstract
                 foreach ($this->getProductOptions() as $option) {
                     $this->getOptionInstance()->addOption($option);
                     if ((!isset($option['is_delete'])) || $option['is_delete'] != '1') {
+                        if (!empty($option['file_extension'])) {
+                            $fileExtension = $option['file_extension'];
+                            if (0 !== strcmp($fileExtension, Mage::helper('core')->removeTags($fileExtension))) {
+                                Mage::throwException(Mage::helper('catalog')->__('Invalid custom option(s).'));
+                            }
+                        }
                         $hasOptions = true;
                     }
                 }
diff --git app/code/core/Mage/Catalog/Model/Resource/Category/Tree.php app/code/core/Mage/Catalog/Model/Resource/Category/Tree.php
index e3c33e8c137..d25abb34f8d 100644
--- app/code/core/Mage/Catalog/Model/Resource/Category/Tree.php
+++ app/code/core/Mage/Catalog/Model/Resource/Category/Tree.php
@@ -482,6 +482,9 @@ class Mage_Catalog_Model_Resource_Category_Tree extends Varien_Data_Tree_Dbp
         $where = array($levelField . '=0' => true);
 
         foreach ($this->_conn->fetchAll($select) as $item) {
+            if (!preg_match("#^[0-9\/]+$#", $item['path'])) {
+                $item['path'] = '';
+            }
             $pathIds  = explode('/', $item['path']);
             $level = (int)$item['level'];
             while ($level > 0) {
diff --git app/code/core/Mage/Checkout/Model/Api/Resource/Customer.php app/code/core/Mage/Checkout/Model/Api/Resource/Customer.php
index b7e85265aa6..a2a9f0fd69c 100644
--- app/code/core/Mage/Checkout/Model/Api/Resource/Customer.php
+++ app/code/core/Mage/Checkout/Model/Api/Resource/Customer.php
@@ -149,6 +149,7 @@ class Mage_Checkout_Model_Api_Resource_Customer extends Mage_Checkout_Model_Api_
 
         Mage::helper('core')->copyFieldset('checkout_onepage_quote', 'to_customer', $quote, $customer);
         $customer->setPassword($customer->decryptPassword($quote->getPasswordHash()));
+        $customer->setPasswordCreatedAt(time());
         $quote->setCustomer($customer)
             ->setCustomerId(true);
 
diff --git app/code/core/Mage/Checkout/Model/Type/Onepage.php app/code/core/Mage/Checkout/Model/Type/Onepage.php
index d673dc0fab5..a13218e1fef 100644
--- app/code/core/Mage/Checkout/Model/Type/Onepage.php
+++ app/code/core/Mage/Checkout/Model/Type/Onepage.php
@@ -726,6 +726,9 @@ class Mage_Checkout_Model_Type_Onepage
 
         Mage::helper('core')->copyFieldset('checkout_onepage_quote', 'to_customer', $quote, $customer);
         $customer->setPassword($customer->decryptPassword($quote->getPasswordHash()));
+        $passwordCreatedTime = $this->_checkoutSession->getData('_session_validator_data')['session_expire_timestamp']
+            - Mage::getSingleton('core/cookie')->getLifetime();
+        $customer->setPasswordCreatedAt($passwordCreatedTime);
         $quote->setCustomer($customer)
             ->setCustomerId(true);
     }
diff --git app/code/core/Mage/Checkout/controllers/CartController.php app/code/core/Mage/Checkout/controllers/CartController.php
index a31ff8b7474..51c3e4dff58 100644
--- app/code/core/Mage/Checkout/controllers/CartController.php
+++ app/code/core/Mage/Checkout/controllers/CartController.php
@@ -340,6 +340,11 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
      */
     public function updateItemOptionsAction()
     {
+        if (!$this->_validateFormKey()) {
+            $this->_redirect('*/*/');
+            return;
+        }
+
         $cart   = $this->_getCart();
         $id = (int) $this->getRequest()->getParam('id');
         $params = $this->getRequest()->getParams();
diff --git app/code/core/Mage/Core/Helper/Http.php app/code/core/Mage/Core/Helper/Http.php
index 65e2927c443..5a64db737bf 100644
--- app/code/core/Mage/Core/Helper/Http.php
+++ app/code/core/Mage/Core/Helper/Http.php
@@ -131,7 +131,7 @@ class Mage_Core_Helper_Http extends Mage_Core_Helper_Abstract
         if (is_null($this->_remoteAddr)) {
             $headers = $this->getRemoteAddrHeaders();
             foreach ($headers as $var) {
-                if ($this->_getRequest()->getServer($var, false)) {
+                if ($var != 'REMOTE_ADDR' && $this->_getRequest()->getServer($var, false)) {
                     $this->_remoteAddr = $_SERVER[$var];
                     break;
                 }
@@ -146,6 +146,11 @@ class Mage_Core_Helper_Http extends Mage_Core_Helper_Abstract
             return false;
         }
 
+        if (strpos($this->_remoteAddr, ',') !== false) {
+            $ipList = explode(',', $this->_remoteAddr);
+            $this->_remoteAddr = trim(reset($ipList));
+        }
+
         return $ipToLong ? inet_pton($this->_remoteAddr) : $this->_remoteAddr;
     }
 
diff --git app/code/core/Mage/Core/Model/Session/Abstract/Varien.php app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
index 3a18cd0a6ef..44a4d857ace 100644
--- app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
+++ app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
@@ -33,6 +33,7 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
     const VALIDATOR_HTTP_VIA_KEY                = 'http_via';
     const VALIDATOR_REMOTE_ADDR_KEY             = 'remote_addr';
     const VALIDATOR_SESSION_EXPIRE_TIMESTAMP    = 'session_expire_timestamp';
+    const VALIDATOR_PASSWORD_CREATE_TIMESTAMP   = 'password_create_timestamp';
     const SECURE_COOKIE_CHECK_KEY               = '_secure_cookie_check';
 
     /**
@@ -393,6 +394,16 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
         return $this->getCookie()->getLifetime() > 0;
     }
 
+    /**
+     * Use password creation timestamp in validator key
+     *
+     * @return bool
+     */
+    public function useValidateSessionPasswordTimestamp()
+    {
+        return true;
+    }
+
     /**
      * Retrieve skip User Agent validation strings (Flash etc)
      *
@@ -470,6 +481,14 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
             $this->_data[self::VALIDATOR_KEY][self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP]
                 = $validatorData[self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP];
         }
+        if ($this->useValidateSessionPasswordTimestamp()
+            && isset($validatorData[self::VALIDATOR_PASSWORD_CREATE_TIMESTAMP])
+            && isset($sessionData[self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP])
+            && $validatorData[self::VALIDATOR_PASSWORD_CREATE_TIMESTAMP]
+            > $sessionData[self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP] - $this->getCookie()->getLifetime()
+        ) {
+            return false;
+        }
 
         return true;
     }
@@ -506,6 +525,11 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
 
         $parts[self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP] = time() + $this->getCookie()->getLifetime();
 
+        if (isset($this->_data['visitor_data']['customer_id'])) {
+            $parts[self::VALIDATOR_PASSWORD_CREATE_TIMESTAMP] =
+                Mage::helper('customer')->getPasswordTimestamp($this->_data['visitor_data']['customer_id']);
+        }
+
         return $parts;
     }
 
diff --git app/code/core/Mage/Customer/Helper/Data.php app/code/core/Mage/Customer/Helper/Data.php
index 002cfe4a263..b42ae48f4ea 100644
--- app/code/core/Mage/Customer/Helper/Data.php
+++ app/code/core/Mage/Customer/Helper/Data.php
@@ -685,6 +685,23 @@ class Mage_Customer_Helper_Data extends Mage_Core_Helper_Abstract
         return $validationMessageEnvelope;
     }
 
+    /**
+     * Get customer password creation timestamp or customer account creation timestamp
+     *
+     * @param $customerId
+     * @return int
+     */
+    public function getPasswordTimestamp($customerId)
+    {
+        /** @var $customer Mage_Customer_Model_Customer */
+        $customer = Mage::getModel('customer/customer')
+            ->setWebsiteId(Mage::app()->getStore()->getWebsiteId())
+            ->load((int)$customerId);
+        $passwordCreatedAt = $customer->getPasswordCreatedAt();
+
+        return is_null($passwordCreatedAt) ? $customer->getCreatedAtTimestamp() : $passwordCreatedAt;
+    }
+
     /**
      * Create SOAP client based on VAT validation service WSDL
      *
diff --git app/code/core/Mage/Customer/Model/Resource/Customer.php app/code/core/Mage/Customer/Model/Resource/Customer.php
index 7232c706fca..45887b586b5 100644
--- app/code/core/Mage/Customer/Model/Resource/Customer.php
+++ app/code/core/Mage/Customer/Model/Resource/Customer.php
@@ -235,8 +235,9 @@ class Mage_Customer_Model_Resource_Customer extends Mage_Eav_Model_Entity_Abstra
      */
     public function changePassword(Mage_Customer_Model_Customer $customer, $newPassword)
     {
-        $customer->setPassword($newPassword);
+        $customer->setPassword($newPassword)->setPasswordCreatedAt(time());
         $this->saveAttribute($customer, 'password_hash');
+        $this->saveAttribute($customer, 'password_created_at');
         return $this;
     }
 
diff --git app/code/core/Mage/Customer/controllers/AccountController.php app/code/core/Mage/Customer/controllers/AccountController.php
index 575c6876de7..e4a8d76df5a 100644
--- app/code/core/Mage/Customer/controllers/AccountController.php
+++ app/code/core/Mage/Customer/controllers/AccountController.php
@@ -298,6 +298,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
 
             if (empty($errors)) {
                 $customer->cleanPasswordsValidationData();
+                $customer->setPasswordCreatedAt(time());
                 $customer->save();
                 $this->_dispatchRegisterSuccess($customer);
                 $this->_successProcessRegistration($customer);
@@ -844,6 +845,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             $customer->setRpToken(null);
             $customer->setRpTokenCreatedAt(null);
             $customer->cleanPasswordsValidationData();
+            $customer->setPasswordCreatedAt(time());
             $customer->save();
 
             $this->_getSession()->unsetData(self::TOKEN_SESSION_NAME);
@@ -990,6 +992,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
 
             try {
                 $customer->cleanPasswordsValidationData();
+                $customer->setPasswordCreatedAt(time());
                 $customer->save();
                 $this->_getSession()->setCustomer($customer)
                     ->addSuccess($this->__('The account information has been saved.'));
diff --git app/code/core/Mage/Log/Model/Visitor.php app/code/core/Mage/Log/Model/Visitor.php
index 4aee3fc98af..50f6a87972c 100644
--- app/code/core/Mage/Log/Model/Visitor.php
+++ app/code/core/Mage/Log/Model/Visitor.php
@@ -252,7 +252,7 @@ class Mage_Log_Model_Visitor extends Mage_Core_Model_Abstract
      */
     public function bindCustomerLogin($observer)
     {
-        if (!$this->getCustomerId() && $customer = $observer->getEvent()->getCustomer()) {
+        if ($customer = $observer->getEvent()->getCustomer()) {
             $this->setDoCustomerLogin(true);
             $this->setCustomerId($customer->getId());
         }
diff --git app/code/core/Mage/Usa/Helper/Data.php app/code/core/Mage/Usa/Helper/Data.php
index fd6ba073764..22fd5bd41ad 100644
--- app/code/core/Mage/Usa/Helper/Data.php
+++ app/code/core/Mage/Usa/Helper/Data.php
@@ -135,4 +135,23 @@ class Mage_Usa_Helper_Data extends Mage_Core_Helper_Abstract
             return false;
         }
     }
+
+    /**
+     * Validate ups type value
+     *
+     * @param $valueForCheck string ups type value for check
+     *
+     * @return bool
+     */
+    public function validateUpsType($valueForCheck) {
+        $result = false;
+        $sourceModel = Mage::getSingleton('usa/shipping_carrier_ups_source_type');
+        foreach ($sourceModel->toOptionArray() as $allowedValue) {
+            if (isset($allowedValue['value']) && $allowedValue['value'] == $valueForCheck) {
+                $result = true;
+                break;
+            }
+        }
+        return $result;
+    }
 }
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Abstract/Backend/Abstract.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Abstract/Backend/Abstract.php
new file mode 100644
index 00000000000..665ac3be6e2
--- /dev/null
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Abstract/Backend/Abstract.php
@@ -0,0 +1,100 @@
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
+ * @package     Mage_Usa
+ * @copyright  Copyright (c) 2006-2018 Magento, Inc. (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Backend model for validate shipping carrier ups field
+ *
+ * @category   Mage
+ * @package    Mage_Usa
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+
+abstract class Mage_Usa_Model_Shipping_Carrier_Abstract_Backend_Abstract extends Mage_Core_Model_Config_Data
+{
+    /**
+     * Source model to get allowed values
+     *
+     * @var string
+     */
+    protected $_sourceModel;
+
+    /**
+     * Field name to display in error block
+     *
+     * @var string
+     */
+    protected $_nameErrorField;
+
+    /**
+     * Set source model to get allowed values
+     *
+     * @return void
+     */
+    abstract protected function _setSourceModelData();
+
+    /**
+     * Set field name to display in error block
+     *
+     * @return void
+     */
+    abstract protected function _setNameErrorField();
+
+    /**
+     * Mage_Usa_Model_Shipping_Carrier_Ups_Backend_Abstract constructor.
+     */
+    public function __construct()
+    {
+        parent::__construct();
+        $this->_setSourceModelData();
+        $this->_setNameErrorField();
+    }
+
+    /**
+     * Check for presence in array with allow value.
+     *
+     * @throws Mage_Core_Exception
+     * @return Mage_Usa_Model_Shipping_Carrier_Ups_Backend_FreeShipment
+     */
+    protected function _beforeSave()
+    {
+        $sourceModel = Mage::getSingleton($this->_sourceModel);
+        if (!method_exists($sourceModel, 'toOptionArray')) {
+            Mage::throwException(Mage::helper('usa')->__('Method toOptionArray not found in source model.'));
+        }
+        $hasCorrectValue = false;
+        $value = $this->getValue();
+        foreach ($sourceModel->toOptionArray() as $allowedValue) {
+            if (isset($allowedValue['value']) && $allowedValue['value'] == $value) {
+                $hasCorrectValue = true;
+                break;
+            }
+        }
+        if(!$hasCorrectValue) {
+            Mage::throwException(Mage::helper('usa')->__('Field "%s" has wrong value.', $this->_nameErrorField));
+        }
+        return $this;
+    }
+}
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups/Backend/Freemethod.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups/Backend/Freemethod.php
new file mode 100644
index 00000000000..d844e62713e
--- /dev/null
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups/Backend/Freemethod.php
@@ -0,0 +1,57 @@
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
+ * @package     Mage_Usa
+ * @copyright  Copyright (c) 2006-2018 Magento, Inc. (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Backend model for validate free method field
+ *
+ * @category   Mage
+ * @package    Mage_Usa
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+
+class Mage_Usa_Model_Shipping_Carrier_Ups_Backend_Freemethod
+    extends Mage_Usa_Model_Shipping_Carrier_Abstract_Backend_Abstract
+{
+    /**
+     * Set source model to get allowed values
+     *
+     * @return void
+     */
+    protected function _setSourceModelData()
+    {
+        $this->_sourceModel = 'usa/shipping_carrier_ups_source_freemethod';
+    }
+
+    /**
+     * Set field name to display in error block
+     *
+     * @return void
+     */
+    protected function _setNameErrorField()
+    {
+        $this->_nameErrorField = 'Ups Free Method';
+    }
+}
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups/Backend/OriginShipment.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups/Backend/OriginShipment.php
new file mode 100644
index 00000000000..4d7e1c0506f
--- /dev/null
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups/Backend/OriginShipment.php
@@ -0,0 +1,57 @@
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
+ * @package     Mage_Usa
+ * @copyright  Copyright (c) 2006-2018 Magento, Inc. (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Backend model for validate origin of the shipment field
+ *
+ * @category   Mage
+ * @package    Mage_Usa
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+
+class Mage_Usa_Model_Shipping_Carrier_Ups_Backend_OriginShipment
+    extends Mage_Usa_Model_Shipping_Carrier_Abstract_Backend_Abstract
+{
+    /**
+     * Set source model to get allowed values
+     *
+     * @return void
+     */
+    protected function _setSourceModelData()
+    {
+        $this->_sourceModel = 'usa/shipping_carrier_ups_source_originShipment';
+    }
+
+    /**
+     * Set field name to display in error block
+     *
+     * @return void
+     */
+    protected function _setNameErrorField()
+    {
+        $this->_nameErrorField = 'Ups origin of the Shipment';
+    }
+}
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups/Backend/Type.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups/Backend/Type.php
new file mode 100644
index 00000000000..fe033622cf6
--- /dev/null
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups/Backend/Type.php
@@ -0,0 +1,56 @@
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
+ * @package     Mage_Usa
+ * @copyright  Copyright (c) 2006-2018 Magento, Inc. (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Backend model for validate ups type field
+ *
+ * @category   Mage
+ * @package    Mage_Usa
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+
+class Mage_Usa_Model_Shipping_Carrier_Ups_Backend_Type extends Mage_Usa_Model_Shipping_Carrier_Abstract_Backend_Abstract
+{
+    /**
+     * Set source model to get allowed values
+     *
+     * @return void
+     */
+    protected function _setSourceModelData()
+    {
+        $this->_sourceModel = 'usa/shipping_carrier_ups_source_type';
+    }
+
+    /**
+     * Set field name to display in error block
+     *
+     * @return void
+     */
+    protected function _setNameErrorField()
+    {
+        $this->_nameErrorField = 'UPS Type';
+    }
+}
diff --git app/code/core/Mage/Usa/etc/system.xml app/code/core/Mage/Usa/etc/system.xml
index 95194137d9c..389cf7165fd 100644
--- app/code/core/Mage/Usa/etc/system.xml
+++ app/code/core/Mage/Usa/etc/system.xml
@@ -740,6 +740,7 @@
                             <frontend_type>select</frontend_type>
                             <frontend_class>free-method</frontend_class>
                             <source_model>usa/shipping_carrier_ups_source_freemethod</source_model>
+                            <backend_model>usa/shipping_carrier_ups_backend_freemethod</backend_model>
                             <sort_order>200</sort_order>
                             <show_in_default>1</show_in_default>
                             <show_in_website>1</show_in_website>
@@ -843,6 +844,7 @@
                             <label>Origin of the Shipment</label>
                             <frontend_type>select</frontend_type>
                             <source_model>usa/shipping_carrier_ups_source_originShipment</source_model>
+                            <backend_model>usa/shipping_carrier_ups_backend_originShipment</backend_model>
                             <sort_order>30</sort_order>
                             <show_in_default>1</show_in_default>
                             <show_in_website>1</show_in_website>
@@ -886,6 +888,7 @@
                             <label>UPS Type</label>
                             <frontend_type>select</frontend_type>
                             <source_model>usa/shipping_carrier_ups_source_type</source_model>
+                            <backend_model>usa/shipping_carrier_ups_backend_type</backend_model>
                             <sort_order>20</sort_order>
                             <show_in_default>1</show_in_default>
                             <show_in_website>1</show_in_website>
diff --git app/code/core/Zend/Filter/PregReplace.php app/code/core/Zend/Filter/PregReplace.php
new file mode 100644
index 00000000000..586c0fe20a0
--- /dev/null
+++ app/code/core/Zend/Filter/PregReplace.php
@@ -0,0 +1,183 @@
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
+ * @package    Zend_Filter
+ * @copyright  Copyright (c) 2005-2015 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ * @version    $Id$
+ */
+
+/**
+ * This class replaces default Zend_Filter_PregReplace because of problem described in MPERF-10057
+ * The only difference between current class and original one is overwritten implementation of filter method
+ *
+ * @see Zend_Filter_Interface
+ */
+#require_once 'Zend/Filter/Interface.php';
+
+/**
+ * @category   Zend
+ * @package    Zend_Filter
+ * @copyright  Copyright (c) 2005-2015 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ */
+class Zend_Filter_PregReplace implements Zend_Filter_Interface
+{
+    /**
+     * Pattern to match
+     * @var mixed
+     */
+    protected $_matchPattern = null;
+
+    /**
+     * Replacement pattern
+     * @var mixed
+     */
+    protected $_replacement = '';
+
+    /**
+     * Is unicode enabled?
+     *
+     * @var bool
+     */
+    static protected $_unicodeSupportEnabled = null;
+
+    /**
+     * Is Unicode Support Enabled Utility function
+     *
+     * @return bool
+     */
+    static public function isUnicodeSupportEnabled()
+    {
+        if (self::$_unicodeSupportEnabled === null) {
+            self::_determineUnicodeSupport();
+        }
+
+        return self::$_unicodeSupportEnabled;
+    }
+
+    /**
+     * Method to cache the regex needed to determine if unicode support is available
+     *
+     * @return bool
+     */
+    static protected function _determineUnicodeSupport()
+    {
+        self::$_unicodeSupportEnabled = (@preg_match('/\pL/u', 'a')) ? true : false;
+    }
+
+    /**
+     * Constructor
+     * Supported options are
+     *     'match'   => matching pattern
+     *     'replace' => replace with this
+     *
+     * @param  string|array $options
+     * @return void
+     */
+    public function __construct($options = null)
+    {
+        if ($options instanceof Zend_Config) {
+            $options = $options->toArray();
+        } else if (!is_array($options)) {
+            $options = func_get_args();
+            $temp    = array();
+            if (!empty($options)) {
+                $temp['match'] = array_shift($options);
+            }
+
+            if (!empty($options)) {
+                $temp['replace'] = array_shift($options);
+            }
+
+            $options = $temp;
+        }
+
+        if (array_key_exists('match', $options)) {
+            $this->setMatchPattern($options['match']);
+        }
+
+        if (array_key_exists('replace', $options)) {
+            $this->setReplacement($options['replace']);
+        }
+    }
+
+    /**
+     * Set the match pattern for the regex being called within filter()
+     *
+     * @param mixed $match - same as the first argument of preg_replace
+     * @return Zend_Filter_PregReplace
+     */
+    public function setMatchPattern($match)
+    {
+        $this->_matchPattern = $match;
+        return $this;
+    }
+
+    /**
+     * Get currently set match pattern
+     *
+     * @return string
+     */
+    public function getMatchPattern()
+    {
+        return $this->_matchPattern;
+    }
+
+    /**
+     * Set the Replacement pattern/string for the preg_replace called in filter
+     *
+     * @param mixed $replacement - same as the second argument of preg_replace
+     * @return Zend_Filter_PregReplace
+     */
+    public function setReplacement($replacement)
+    {
+        $this->_replacement = $replacement;
+        return $this;
+    }
+
+    /**
+     * Get currently set replacement value
+     *
+     * @return string
+     */
+    public function getReplacement()
+    {
+        return $this->_replacement;
+    }
+
+    /**
+     * Perform regexp replacement as filter
+     *
+     * @param  string $value
+     * @return string
+     */
+    public function filter($value)
+    {
+        if ($this->_matchPattern == null) {
+            #require_once 'Zend/Filter/Exception.php';
+            throw new Zend_Filter_Exception(get_class($this) . ' does not have a valid MatchPattern set.');
+        }
+        $firstDilimeter = substr($this->_matchPattern, 0, 1);
+        $partsOfRegex = explode($firstDilimeter, $this->_matchPattern);
+        $modifiers = array_pop($partsOfRegex);
+        if ($modifiers != str_replace('e', '', $modifiers)) {
+            throw new Zend_Filter_Exception(get_class($this) . ' uses deprecated modifier "/e".');
+        }
+
+        return preg_replace($this->_matchPattern, $this->_replacement, $value);
+    }
+
+}
diff --git app/code/core/Zend/Validate/EmailAddress.php app/code/core/Zend/Validate/EmailAddress.php
new file mode 100644
index 00000000000..95e9bdff7cf
--- /dev/null
+++ app/code/core/Zend/Validate/EmailAddress.php
@@ -0,0 +1,579 @@
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
+ * @package    Zend_Validate
+ * @copyright  Copyright (c) 2005-2015 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ * @version    $Id$
+ */
+
+/**
+ * @see Zend_Validate_Abstract
+ */
+#require_once 'Zend/Validate/Abstract.php';
+
+/**
+ * @see Zend_Validate_Hostname
+ */
+#require_once 'Zend/Validate/Hostname.php';
+
+/**
+ * This class replaces default Zend_Validate_EmailAddress because of issues described in MPERF-9688 and MPERF-9689
+ * The only difference between current class and original one is overwritten implementation of _validateLocalPart method
+ *
+ * @category   Zend
+ * @package    Zend_Validate
+ * @copyright  Copyright (c) 2005-2015 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ */
+class Zend_Validate_EmailAddress extends Zend_Validate_Abstract
+{
+    const INVALID            = 'emailAddressInvalid';
+    const INVALID_FORMAT     = 'emailAddressInvalidFormat';
+    const INVALID_HOSTNAME   = 'emailAddressInvalidHostname';
+    const INVALID_MX_RECORD  = 'emailAddressInvalidMxRecord';
+    const INVALID_SEGMENT    = 'emailAddressInvalidSegment';
+    const DOT_ATOM           = 'emailAddressDotAtom';
+    const QUOTED_STRING      = 'emailAddressQuotedString';
+    const INVALID_LOCAL_PART = 'emailAddressInvalidLocalPart';
+    const LENGTH_EXCEEDED    = 'emailAddressLengthExceeded';
+
+    /**
+     * @var array
+     */
+    protected $_messageTemplates = array(
+        self::INVALID            => "Invalid type given. String expected",
+        self::INVALID_FORMAT     => "'%value%' is not a valid email address in the basic format local-part@hostname",
+        self::INVALID_HOSTNAME   => "'%hostname%' is not a valid hostname for email address '%value%'",
+        self::INVALID_MX_RECORD  => "'%hostname%' does not appear to have a valid MX record for the email address '%value%'",
+        self::INVALID_SEGMENT    => "'%hostname%' is not in a routable network segment. The email address '%value%' should not be resolved from public network",
+        self::DOT_ATOM           => "'%localPart%' can not be matched against dot-atom format",
+        self::QUOTED_STRING      => "'%localPart%' can not be matched against quoted-string format",
+        self::INVALID_LOCAL_PART => "'%localPart%' is not a valid local part for email address '%value%'",
+        self::LENGTH_EXCEEDED    => "'%value%' exceeds the allowed length",
+    );
+
+    /**
+     * As of RFC5753 (JAN 2010), the following blocks are no longer reserved:
+     *   - 128.0.0.0/16
+     *   - 191.255.0.0/16
+     *   - 223.255.255.0/24
+     * @see http://tools.ietf.org/html/rfc5735#page-6
+     *
+     * As of RFC6598 (APR 2012), the following blocks are now reserved:
+     *   - 100.64.0.0/10
+     * @see http://tools.ietf.org/html/rfc6598#section-7
+     *
+     * @see http://en.wikipedia.org/wiki/IPv4
+     * @var array
+     */
+    protected $_invalidIp = array(
+        '0'   => '0.0.0.0/8',
+        '10'  => '10.0.0.0/8',
+        '100' => '100.64.0.0/10',
+        '127' => '127.0.0.0/8',
+        '169' => '169.254.0.0/16',
+        '172' => '172.16.0.0/12',
+        '192' => array(
+            '192.0.0.0/24',
+            '192.0.2.0/24',
+            '192.88.99.0/24',
+            '192.168.0.0/16'
+        ),
+        '198' => '198.18.0.0/15',
+        '224' => '224.0.0.0/4',
+        '240' => '240.0.0.0/4'
+    );
+
+    /**
+     * @var array
+     */
+    protected $_messageVariables = array(
+        'hostname'  => '_hostname',
+        'localPart' => '_localPart'
+    );
+
+    /**
+     * @var string
+     */
+    protected $_hostname;
+
+    /**
+     * @var string
+     */
+    protected $_localPart;
+
+    /**
+     * Internal options array
+     */
+    protected $_options = array(
+        'mx'       => false,
+        'deep'     => false,
+        'domain'   => true,
+        'allow'    => Zend_Validate_Hostname::ALLOW_DNS,
+        'hostname' => null
+    );
+
+    /**
+     * Instantiates hostname validator for local use
+     *
+     * The following option keys are supported:
+     * 'hostname' => A hostname validator, see Zend_Validate_Hostname
+     * 'allow'    => Options for the hostname validator, see Zend_Validate_Hostname::ALLOW_*
+     * 'mx'       => If MX check should be enabled, boolean
+     * 'deep'     => If a deep MX check should be done, boolean
+     *
+     * @param array|string|Zend_Config $options OPTIONAL
+     */
+    public function __construct($options = array())
+    {
+        if ($options instanceof Zend_Config) {
+            $options = $options->toArray();
+        } else if (!is_array($options)) {
+            $options = func_get_args();
+            $temp['allow'] = array_shift($options);
+            if (!empty($options)) {
+                $temp['mx'] = array_shift($options);
+            }
+
+            if (!empty($options)) {
+                $temp['hostname'] = array_shift($options);
+            }
+
+            $options = $temp;
+        }
+
+        $options += $this->_options;
+        $this->setOptions($options);
+    }
+
+    /**
+     * Returns all set Options
+     *
+     * @return array
+     */
+    public function getOptions()
+    {
+        return $this->_options;
+    }
+
+    /**
+     * Set options for the email validator
+     *
+     * @param array $options
+     * @return Zend_Validate_EmailAddress Provides a fluent inteface
+     */
+    public function setOptions(array $options = array())
+    {
+        if (array_key_exists('messages', $options)) {
+            $this->setMessages($options['messages']);
+        }
+
+        if (array_key_exists('hostname', $options)) {
+            if (array_key_exists('allow', $options)) {
+                $this->setHostnameValidator($options['hostname'], $options['allow']);
+            } else {
+                $this->setHostnameValidator($options['hostname']);
+            }
+        } elseif ($this->_options['hostname'] == null) {
+            $this->setHostnameValidator();
+        }
+
+        if (array_key_exists('mx', $options)) {
+            $this->setValidateMx($options['mx']);
+        }
+
+        if (array_key_exists('deep', $options)) {
+            $this->setDeepMxCheck($options['deep']);
+        }
+
+        if (array_key_exists('domain', $options)) {
+            $this->setDomainCheck($options['domain']);
+        }
+
+        return $this;
+    }
+
+    /**
+     * Sets the validation failure message template for a particular key
+     * Adds the ability to set messages to the attached hostname validator
+     *
+     * @param  string $messageString
+     * @param  string $messageKey     OPTIONAL
+     * @return Zend_Validate_Abstract Provides a fluent interface
+     * @throws Zend_Validate_Exception
+     */
+    public function setMessage($messageString, $messageKey = null)
+    {
+        if ($messageKey === null) {
+            $this->_options['hostname']->setMessage($messageString);
+            parent::setMessage($messageString);
+            return $this;
+        }
+
+        if (!isset($this->_messageTemplates[$messageKey])) {
+            $this->_options['hostname']->setMessage($messageString, $messageKey);
+        }
+
+        $this->_messageTemplates[$messageKey] = $messageString;
+        return $this;
+    }
+
+    /**
+     * Returns the set hostname validator
+     *
+     * @return Zend_Validate_Hostname
+     */
+    public function getHostnameValidator()
+    {
+        return $this->_options['hostname'];
+    }
+
+    /**
+     * @param Zend_Validate_Hostname $hostnameValidator OPTIONAL
+     * @param int                    $allow             OPTIONAL
+     * @return $this
+     */
+    public function setHostnameValidator(Zend_Validate_Hostname $hostnameValidator = null, $allow = Zend_Validate_Hostname::ALLOW_DNS)
+    {
+        if (!$hostnameValidator) {
+            $hostnameValidator = new Zend_Validate_Hostname($allow);
+        }
+
+        $this->_options['hostname'] = $hostnameValidator;
+        $this->_options['allow']    = $allow;
+        return $this;
+    }
+
+    /**
+     * Whether MX checking via getmxrr is supported or not
+     *
+     * This currently only works on UNIX systems
+     *
+     * @return boolean
+     */
+    public function validateMxSupported()
+    {
+        return function_exists('getmxrr');
+    }
+
+    /**
+     * Returns the set validateMx option
+     *
+     * @return boolean
+     */
+    public function getValidateMx()
+    {
+        return $this->_options['mx'];
+    }
+
+    /**
+     * Set whether we check for a valid MX record via DNS
+     *
+     * This only applies when DNS hostnames are validated
+     *
+     * @param boolean $mx Set allowed to true to validate for MX records, and false to not validate them
+     * @throws Zend_Validate_Exception
+     * @return Zend_Validate_EmailAddress Provides a fluent inteface
+     */
+    public function setValidateMx($mx)
+    {
+        if ((bool) $mx && !$this->validateMxSupported()) {
+            #require_once 'Zend/Validate/Exception.php';
+            throw new Zend_Validate_Exception('MX checking not available on this system');
+        }
+
+        $this->_options['mx'] = (bool) $mx;
+        return $this;
+    }
+
+    /**
+     * Returns the set deepMxCheck option
+     *
+     * @return boolean
+     */
+    public function getDeepMxCheck()
+    {
+        return $this->_options['deep'];
+    }
+
+    /**
+     * Set whether we check MX record should be a deep validation
+     *
+     * @param boolean $deep Set deep to true to perform a deep validation process for MX records
+     * @return Zend_Validate_EmailAddress Provides a fluent inteface
+     */
+    public function setDeepMxCheck($deep)
+    {
+        $this->_options['deep'] = (bool) $deep;
+        return $this;
+    }
+
+    /**
+     * Returns the set domainCheck option
+     *
+     * @return unknown
+     */
+    public function getDomainCheck()
+    {
+        return $this->_options['domain'];
+    }
+
+    /**
+     * Sets if the domain should also be checked
+     * or only the local part of the email address
+     *
+     * @param boolean $domain
+     * @return Zend_Validate_EmailAddress Provides a fluent inteface
+     */
+    public function setDomainCheck($domain = true)
+    {
+        $this->_options['domain'] = (boolean) $domain;
+        return $this;
+    }
+
+    /**
+     * Returns if the given host is reserved
+     *
+     * @param string $host
+     * @return boolean
+     */
+    private function _isReserved($host){
+        if (!preg_match('/^([0-9]{1,3}\.){3}[0-9]{1,3}$/', $host)) {
+            $host = gethostbyname($host);
+        }
+
+        $octet = explode('.',$host);
+        if ((int)$octet[0] >= 224) {
+            return true;
+        } else if (array_key_exists($octet[0], $this->_invalidIp)) {
+            foreach ((array)$this->_invalidIp[$octet[0]] as $subnetData) {
+                // we skip the first loop as we already know that octet matches
+                for ($i = 1; $i < 4; $i++) {
+                    if (strpos($subnetData, $octet[$i]) !== $i * 4) {
+                        break;
+                    }
+                }
+
+                $host       = explode("/", $subnetData);
+                $binaryHost = "";
+                $tmp        = explode(".", $host[0]);
+                for ($i = 0; $i < 4 ; $i++) {
+                    $binaryHost .= str_pad(decbin($tmp[$i]), 8, "0", STR_PAD_LEFT);
+                }
+
+                $segmentData = array(
+                    'network'   => (int)$this->_toIp(str_pad(substr($binaryHost, 0, $host[1]), 32, 0)),
+                    'broadcast' => (int)$this->_toIp(str_pad(substr($binaryHost, 0, $host[1]), 32, 1))
+                );
+
+                for ($j = $i; $j < 4; $j++) {
+                    if ((int)$octet[$j] < $segmentData['network'][$j] ||
+                        (int)$octet[$j] > $segmentData['broadcast'][$j]) {
+                        return false;
+                    }
+                }
+            }
+
+            return true;
+        } else {
+            return false;
+        }
+    }
+
+    /**
+     * Converts a binary string to an IP address
+     *
+     * @param string $binary
+     * @return mixed
+     */
+    private function _toIp($binary)
+    {
+        $ip  = array();
+        $tmp = explode(".", chunk_split($binary, 8, "."));
+        for ($i = 0; $i < 4 ; $i++) {
+            $ip[$i] = bindec($tmp[$i]);
+        }
+
+        return $ip;
+    }
+
+    /**
+     * Internal method to validate the local part of the email address
+     *
+     * @return boolean
+     */
+    private function _validateLocalPart()
+    {
+        // First try to match the local part on the common dot-atom format
+        $result = false;
+
+        // Dot-atom characters are: 1*atext *("." 1*atext)
+        // atext: ALPHA / DIGIT / and "!", "#", "$", "%", "&", "'", "*",
+        //        "+", "-", "/", "=", "?", "^", "_", "`", "{", "|", "}", "~"
+        $atext = 'a-zA-Z0-9\x21\x23\x24\x25\x26\x27\x2a\x2b\x2d\x2f\x3d\x3f\x5e\x5f\x60\x7b\x7c\x7d\x7e';
+        if (preg_match('/^[' . $atext . ']+(\x2e+[' . $atext . ']+)*$/', $this->_localPart)) {
+            $result = true;
+        } else {
+            // Try quoted string format (RFC 5321 Chapter 4.1.2)
+
+            // Quoted-string characters are: DQUOTE *(qtext/quoted-pair) DQUOTE
+            $qtext      = '\x20-\x21\x23-\x5b\x5d-\x7e'; // %d32-33 / %d35-91 / %d93-126
+            $quotedPair = '\x20-\x7e'; // %d92 %d32-126
+            if ((0 === (strcmp($this->localPart, strip_tags($this->localPart))))
+                && (0 === (strcmp($this->localPart, htmlspecialchars_decode($this->localPart))))
+                && (preg_match('/^"(['. $qtext .']|\x5c[' . $quotedPair . '])*"$/', $this->localPart))) {
+                $result = true;
+            } else {
+                $this->_error(self::DOT_ATOM);
+                $this->_error(self::QUOTED_STRING);
+                $this->_error(self::INVALID_LOCAL_PART);
+            }
+        }
+
+        return $result;
+    }
+
+    /**
+     * Internal method to validate the servers MX records
+     *
+     * @return boolean
+     */
+    private function _validateMXRecords()
+    {
+        $mxHosts = array();
+        $hostname = $this->_hostname;
+
+        //decode IDN domain name if possible
+        if (function_exists('idn_to_ascii')) {
+            $hostname = idn_to_ascii($this->_hostname);
+        }
+
+        $result = getmxrr($hostname, $mxHosts);
+        if (!$result) {
+            $this->_error(self::INVALID_MX_RECORD);
+        } else if ($this->_options['deep'] && function_exists('checkdnsrr')) {
+            $validAddress = false;
+            $reserved     = true;
+            foreach ($mxHosts as $hostname) {
+                $res = $this->_isReserved($hostname);
+                if (!$res) {
+                    $reserved = false;
+                }
+
+                if (!$res
+                    && (checkdnsrr($hostname, "A")
+                    || checkdnsrr($hostname, "AAAA")
+                    || checkdnsrr($hostname, "A6"))) {
+                    $validAddress = true;
+                    break;
+                }
+            }
+
+            if (!$validAddress) {
+                $result = false;
+                if ($reserved) {
+                    $this->_error(self::INVALID_SEGMENT);
+                } else {
+                    $this->_error(self::INVALID_MX_RECORD);
+                }
+            }
+        }
+
+        return $result;
+    }
+
+    /**
+     * Internal method to validate the hostname part of the email address
+     *
+     * @return boolean
+     */
+    private function _validateHostnamePart()
+    {
+        $hostname = $this->_options['hostname']->setTranslator($this->getTranslator())
+                         ->isValid($this->_hostname);
+        if (!$hostname) {
+            $this->_error(self::INVALID_HOSTNAME);
+
+            // Get messages and errors from hostnameValidator
+            foreach ($this->_options['hostname']->getMessages() as $code => $message) {
+                $this->_messages[$code] = $message;
+            }
+
+            foreach ($this->_options['hostname']->getErrors() as $error) {
+                $this->_errors[] = $error;
+            }
+        } else if ($this->_options['mx']) {
+            // MX check on hostname
+            $hostname = $this->_validateMXRecords();
+        }
+
+        return $hostname;
+    }
+
+    /**
+     * Defined by Zend_Validate_Interface
+     *
+     * Returns true if and only if $value is a valid email address
+     * according to RFC2822
+     *
+     * @link   http://www.ietf.org/rfc/rfc2822.txt RFC2822
+     * @link   http://www.columbia.edu/kermit/ascii.html US-ASCII characters
+     * @param  string $value
+     * @return boolean
+     */
+    public function isValid($value)
+    {
+        if (!is_string($value)) {
+            $this->_error(self::INVALID);
+            return false;
+        }
+
+        $matches = array();
+        $length  = true;
+        $this->_setValue($value);
+
+        // Split email address up and disallow '..'
+        if ((strpos($value, '..') !== false) or
+            (!preg_match('/^(.+)@([^@]+)$/', $value, $matches))) {
+            $this->_error(self::INVALID_FORMAT);
+            return false;
+        }
+
+        $this->_localPart = $matches[1];
+        $this->_hostname  = $matches[2];
+
+        if ((strlen($this->_localPart) > 64) || (strlen($this->_hostname) > 255)) {
+            $length = false;
+            $this->_error(self::LENGTH_EXCEEDED);
+        }
+
+        // Match hostname part
+        if ($this->_options['domain']) {
+            $hostname = $this->_validateHostnamePart();
+        }
+
+        $local = $this->_validateLocalPart();
+
+        // If both parts valid, return true
+        if ($local && $length) {
+            if (($this->_options['domain'] && $hostname) || !$this->_options['domain']) {
+                return true;
+            }
+        }
+
+        return false;
+    }
+}
diff --git app/design/adminhtml/default/default/template/bundle/product/edit/bundle/option.phtml app/design/adminhtml/default/default/template/bundle/product/edit/bundle/option.phtml
index 503370a3c33..054f72c9c8e 100644
--- app/design/adminhtml/default/default/template/bundle/product/edit/bundle/option.phtml
+++ app/design/adminhtml/default/default/template/bundle/product/edit/bundle/option.phtml
@@ -213,6 +213,7 @@ optionIndex = bOption.add(<?php echo $_option->toJson() ?>);
 <?php if ($_option->getSelections()):?>
     <?php foreach ($_option->getSelections() as $_selection): ?>
     <?php $_selection->setName($this->escapeHtml($_selection->getName())); ?>
+    <?php $_selection->setSku($this->escapeHtml($_selection->getSku())); ?>
 bSelection.addRow(optionIndex, <?php echo $_selection->toJson() ?>);
     <?php endforeach; ?>
 <?php endif; ?>
diff --git app/design/adminhtml/default/default/template/system/shipping/ups.phtml app/design/adminhtml/default/default/template/system/shipping/ups.phtml
index 1aea2a13520..c7140470619 100644
--- app/design/adminhtml/default/default/template/system/shipping/ups.phtml
+++ app/design/adminhtml/default/default/template/system/shipping/ups.phtml
@@ -52,6 +52,15 @@ if (!$storeCode && $websiteCode) {
     $storedFreeShipment   = Mage::getStoreConfig('carriers/ups/free_method');
     $storedUpsType        = Mage::getStoreConfig('carriers/ups/type');
 }
+if (!in_array($storedOriginShipment, array_keys($orShipArr))) {
+    $storedOriginShipment = '';
+}
+if ($storedFreeShipment != '' && !in_array($storedFreeShipment, array_keys($defShipArr))) {
+    $storedFreeShipment = '';
+}
+if (!Mage::helper('usa')->validateUpsType($storedUpsType)) {
+    $storedUpsType = '';
+}
 ?>
 <script type="text/javascript">
 //<![CDATA[
diff --git app/design/frontend/base/default/template/downloadable/catalog/product/links.phtml app/design/frontend/base/default/template/downloadable/catalog/product/links.phtml
index b9c402af077..ae11696d9ff 100644
--- app/design/frontend/base/default/template/downloadable/catalog/product/links.phtml
+++ app/design/frontend/base/default/template/downloadable/catalog/product/links.phtml
@@ -30,7 +30,7 @@
     <dl>
         <?php $_links = $this->getLinks(); ?>
         <?php $_isRequired = $this->getLinkSelectionRequired(); ?>
-        <dt><label<?php if ($_isRequired) echo ' class="required"' ?>><?php if ($_isRequired) echo '<em>*</em>' ?><?php echo $this->getLinksTitle() ?></label></dt>
+        <dt><label<?php if ($_isRequired) echo ' class="required"' ?>><?php if ($_isRequired) echo '<em>*</em>' ?><?php echo $this->escapeHtml($this->getLinksTitle()); ?></label></dt>
         <dd<?php /* if ($_option->decoratedIsLast){?> class="last"<?php } */ ?>>
             <ul id="downloadable-links-list" class="options-list">
             <?php foreach ($_links as $_link): ?>
diff --git app/design/frontend/base/default/template/downloadable/checkout/cart/item/default.phtml app/design/frontend/base/default/template/downloadable/checkout/cart/item/default.phtml
index cebbb31def0..a324fb58595 100644
--- app/design/frontend/base/default/template/downloadable/checkout/cart/item/default.phtml
+++ app/design/frontend/base/default/template/downloadable/checkout/cart/item/default.phtml
@@ -58,7 +58,7 @@ $canApplyMsrp = Mage::helper('catalog')->canApplyMsrp($_item->getProduct(), Mage
     <!-- downloadable -->
     <?php if ($links = $this->getLinks()): ?>
         <dl class="item-options">
-            <dt><?php echo $this->getLinksTitle() ?></dt>
+            <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
             <?php foreach ($links as $link): ?>
                 <dd><?php echo $this->escapeHtml($link->getTitle()); ?></dd>
             <?php endforeach; ?>
diff --git app/design/frontend/base/default/template/downloadable/checkout/onepage/review/item.phtml app/design/frontend/base/default/template/downloadable/checkout/onepage/review/item.phtml
index ac97afc48fb..6af185b145e 100644
--- app/design/frontend/base/default/template/downloadable/checkout/onepage/review/item.phtml
+++ app/design/frontend/base/default/template/downloadable/checkout/onepage/review/item.phtml
@@ -48,7 +48,7 @@
         <?php endif;?>
         <?php if ($links = $this->getLinks()): ?>
         <dl class="item-options">
-            <dt><?php echo $this->getLinksTitle() ?></dt>
+            <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
             <?php foreach ($links as $link): ?>
                 <dd><?php echo $this->escapeHtml($link->getTitle()); ?></dd>
             <?php endforeach; ?>
diff --git app/design/frontend/base/default/template/downloadable/sales/order/items/renderer/downloadable.phtml app/design/frontend/base/default/template/downloadable/sales/order/items/renderer/downloadable.phtml
index b7eb27edca9..5f6c3240806 100644
--- app/design/frontend/base/default/template/downloadable/sales/order/items/renderer/downloadable.phtml
+++ app/design/frontend/base/default/template/downloadable/sales/order/items/renderer/downloadable.phtml
@@ -54,7 +54,7 @@
     <!-- downloadable -->
     <?php if ($links = $this->getLinks()): ?>
         <dl class="item-options">
-            <dt><?php echo $this->getLinksTitle() ?></dt>
+            <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
             <?php foreach ($links->getPurchasedItems() as $link): ?>
                 <dd><?php echo $this->escapeHtml($link->getLinkTitle()); ?></dd>
             <?php endforeach; ?>
diff --git app/design/frontend/default/iphone/template/downloadable/checkout/cart/item/default.phtml app/design/frontend/default/iphone/template/downloadable/checkout/cart/item/default.phtml
index 3c4d711f889..e8b2a93b8fb 100644
--- app/design/frontend/default/iphone/template/downloadable/checkout/cart/item/default.phtml
+++ app/design/frontend/default/iphone/template/downloadable/checkout/cart/item/default.phtml
@@ -269,7 +269,7 @@
         <?php if ($links): ?>
         <div class="downloadable">
             <dl class="item-options">
-                <dt><?php echo $this->getLinksTitle() ?></dt>
+                <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
                 <?php foreach ($links as $link): ?>
                     <dd><?php echo $this->escapeHtml($link->getTitle()); ?></dd>
                 <?php endforeach; ?>
diff --git app/design/frontend/default/iphone/template/downloadable/checkout/onepage/review/item.phtml app/design/frontend/default/iphone/template/downloadable/checkout/onepage/review/item.phtml
index f672a96893f..e80f6a31bfb 100644
--- app/design/frontend/default/iphone/template/downloadable/checkout/onepage/review/item.phtml
+++ app/design/frontend/default/iphone/template/downloadable/checkout/onepage/review/item.phtml
@@ -50,7 +50,7 @@
             <?php endif;?>
             <?php if ($links = $this->getLinks()): ?>
             <dl class="item-options">
-                <dt><?php echo $this->getLinksTitle() ?></dt>
+                <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
                 <?php foreach ($links as $link): ?>
                     <dd><?php echo $this->escapeHtml($link->getTitle()); ?></dd>
                 <?php endforeach; ?>
diff --git app/design/frontend/rwd/default/template/downloadable/checkout/cart/item/default.phtml app/design/frontend/rwd/default/template/downloadable/checkout/cart/item/default.phtml
index 8f3db2ee5e2..dafc0f8ae1a 100644
--- app/design/frontend/rwd/default/template/downloadable/checkout/cart/item/default.phtml
+++ app/design/frontend/rwd/default/template/downloadable/checkout/cart/item/default.phtml
@@ -80,7 +80,7 @@ $canApplyMsrp = Mage::helper('catalog')->canApplyMsrp($_item->getProduct(), Mage
     <!-- downloadable -->
     <?php if ($links = $this->getLinks()): ?>
         <dl class="item-options">
-            <dt><?php echo $this->getLinksTitle() ?></dt>
+            <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
             <?php foreach ($links as $link): ?>
                 <dd><?php echo $this->escapeHtml($link->getTitle()); ?></dd>
             <?php endforeach; ?>
diff --git app/design/frontend/rwd/default/template/downloadable/checkout/onepage/review/item.phtml app/design/frontend/rwd/default/template/downloadable/checkout/onepage/review/item.phtml
index 4d602edfff5..69309d227da 100644
--- app/design/frontend/rwd/default/template/downloadable/checkout/onepage/review/item.phtml
+++ app/design/frontend/rwd/default/template/downloadable/checkout/onepage/review/item.phtml
@@ -48,7 +48,7 @@
         <?php endif;?>
         <?php if ($links = $this->getLinks()): ?>
         <dl class="item-options">
-            <dt><?php echo $this->getLinksTitle() ?></dt>
+            <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
             <?php foreach ($links as $link): ?>
                 <dd><?php echo $this->escapeHtml($link->getTitle()); ?></dd>
             <?php endforeach; ?>
diff --git app/design/frontend/rwd/default/template/downloadable/sales/order/items/renderer/downloadable.phtml app/design/frontend/rwd/default/template/downloadable/sales/order/items/renderer/downloadable.phtml
index 50b7600780b..36a4525921e 100644
--- app/design/frontend/rwd/default/template/downloadable/sales/order/items/renderer/downloadable.phtml
+++ app/design/frontend/rwd/default/template/downloadable/sales/order/items/renderer/downloadable.phtml
@@ -54,7 +54,7 @@
     <!-- downloadable -->
     <?php if ($links = $this->getLinks()): ?>
         <dl class="item-options">
-            <dt><?php echo $this->getLinksTitle() ?></dt>
+            <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
             <?php foreach ($links->getPurchasedItems() as $link): ?>
                 <dd><?php echo $this->escapeHtml($link->getLinkTitle()); ?></dd>
             <?php endforeach; ?>
diff --git app/locale/en_US/Mage_Catalog.csv app/locale/en_US/Mage_Catalog.csv
index fa5167abcbc..ee7bff84c52 100644
--- app/locale/en_US/Mage_Catalog.csv
+++ app/locale/en_US/Mage_Catalog.csv
@@ -355,6 +355,7 @@
 "Invalid attribute option specified for attribute %s (%s), skipping the record.","Invalid attribute option specified for attribute %s (%s), skipping the record."
 "Invalid attribute set specified, skipping the record.","Invalid attribute set specified, skipping the record."
 "Invalid block: %s.","Invalid block: %s."
+"Invalid custom option(s).","Invalid custom option(s)."
 "Invalid category IDs.","Invalid category IDs."
 "Invalid category.","Invalid category."
 "Invalid image file type.","Invalid image file type."
diff --git app/locale/en_US/Mage_Usa.csv app/locale/en_US/Mage_Usa.csv
index 5e8f844a75b..c15d25dcc49 100644
--- app/locale/en_US/Mage_Usa.csv
+++ app/locale/en_US/Mage_Usa.csv
@@ -178,6 +178,8 @@
 "Order","Order"
 "Order #%s","Order #%s"
 "Origin of the Shipment","Origin of the Shipment"
+"Field ""%s"" has wrong value.","Field ""%s"" has wrong value."
+"Method toOptionArray not found in source model.","Method toOptionArray not found in source model."
 "Origin serviceAreaCode is missing","Origin serviceAreaCode is missing"
 "Other","Other"
 "Others","Others"
diff --git cron.php cron.php
index 559ecc92842..506ff27a01c 100644
--- cron.php
+++ cron.php
@@ -40,7 +40,12 @@ if (!Mage::isInstalled()) {
 $_SERVER['SCRIPT_NAME'] = str_replace(basename(__FILE__), 'index.php', $_SERVER['SCRIPT_NAME']);
 $_SERVER['SCRIPT_FILENAME'] = str_replace(basename(__FILE__), 'index.php', $_SERVER['SCRIPT_FILENAME']);
 
-Mage::app('admin')->setUseSessionInUrl(false);
+try {
+    Mage::app('admin')->setUseSessionInUrl(false);
+} catch (Exception $e) {
+    Mage::printException($e);
+    exit;
+}
 
 umask(0);
 
diff --git js/tiny_mce/plugins/media/.htaccess js/tiny_mce/plugins/media/.htaccess
new file mode 100644
index 00000000000..6950c803402
--- /dev/null
+++ js/tiny_mce/plugins/media/.htaccess
@@ -0,0 +1,7 @@
+<IfModule mod_rewrite.c>
+    <Files moxieplayer.swf>
+        RewriteEngine on
+        RewriteCond %{QUERY_STRING} !^$
+        RewriteRule ^(.*)$ %{REQUEST_URI}? [R=301,L]
+    </Files>
+</IfModule>
diff --git lib/Varien/Image/Adapter/Gd2.php lib/Varien/Image/Adapter/Gd2.php
index c4809e84c03..fb1f122ea62 100644
--- lib/Varien/Image/Adapter/Gd2.php
+++ lib/Varien/Image/Adapter/Gd2.php
@@ -212,7 +212,7 @@ class Varien_Image_Adapter_Gd2 extends Varien_Image_Adapter_Abstract
 
     public function display()
     {
-        header("Content-type: ".$this->getMimeType());
+        header("Content-type: ".$this->getMimeTypeWithOutFileType());
         call_user_func($this->_getCallback('output'), $this->_imageHandler);
     }
 
@@ -632,4 +632,14 @@ class Varien_Image_Adapter_Gd2 extends Varien_Image_Adapter_Abstract
         imagealphablending($imageHandler, false);
         imagesavealpha($imageHandler, true);
     }
+
+    /**
+     * Gives real mime-type with not considering file type field
+     *
+     * @return string
+     */
+    public function getMimeTypeWithOutFileType()
+    {
+        return $this->_fileMimeType;
+    }
 }
