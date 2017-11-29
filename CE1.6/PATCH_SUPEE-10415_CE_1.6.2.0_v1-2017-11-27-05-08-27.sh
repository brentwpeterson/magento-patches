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

SUPEE-10415-ce-1.6.2.0 | CE_1.6.2.0 | v1 | 475b0b5a7b77d569eac35650ca267c6c3b0efc7f | Thu Nov 9 14:13:18 2017 +0200 | 7d14fc541cb46f5121ab1efee7c1968c4122a7b4..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/Mage.php app/Mage.php
index 4922234..82f84fb 100644
--- app/Mage.php
+++ app/Mage.php
@@ -727,7 +727,12 @@ final class Mage
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
diff --git app/code/core/Mage/Adminhtml/Block/Report/Review/Detail.php app/code/core/Mage/Adminhtml/Block/Report/Review/Detail.php
index f624385..c34ff9e 100644
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
index d6fbe73..fa6f86e 100644
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
index f13f2b4..57678f2 100644
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
index 40df93c..d37461f 100644
--- app/code/core/Mage/Adminhtml/Block/Review/Edit/Form.php
+++ app/code/core/Mage/Adminhtml/Block/Review/Edit/Form.php
@@ -54,9 +54,10 @@ class Mage_Adminhtml_Block_Review_Edit_Form extends Mage_Adminhtml_Block_Widget_
 
         $fieldset->addField('product_name', 'note', array(
             'label'     => Mage::helper('review')->__('Product'),
-            'text'      => '<a href="' . $this->getUrl('*/catalog_product/edit', array('id' => $product->getId())) . '" onclick="this.target=\'blank\'">' . $product->getName() . '</a>'
+            'text'      => '<a href="' . $this->getUrl('*/catalog_product/edit', array('id' => $product->getId())) . '" onclick="this.target=\'blank\'">' . $this->escapeHtml($product->getName()) . '</a>'
         ));
 
+        $customerText = '';
         if ($customer->getId()) {
             $customerText = Mage::helper('review')->__('<a href="%1$s" onclick="this.target=\'blank\'">%2$s %3$s</a> <a href="mailto:%4$s">(%4$s)</a>',
                 $this->getUrl('*/customer/edit', array('id' => $customer->getId(), 'active_tab'=>'review')),
diff --git app/code/core/Mage/Adminhtml/Controller/Action.php app/code/core/Mage/Adminhtml/Controller/Action.php
index d384c0e..aaf508e 100644
--- app/code/core/Mage/Adminhtml/Controller/Action.php
+++ app/code/core/Mage/Adminhtml/Controller/Action.php
@@ -178,7 +178,7 @@ class Mage_Adminhtml_Controller_Action extends Mage_Core_Controller_Varien_Actio
                     'message' => $_keyErrorMsg
                 )));
             } else {
-                if ($_keyErrorMsg != ''){
+                if (!$_isValidFormKey){
                     Mage::getSingleton('adminhtml/session')->addError($_keyErrorMsg);
                 }
                 $this->_redirect( Mage::getSingleton('admin/session')->getUser()->getStartupPageUrl() );
diff --git app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
index 5f64882..2b4cf07 100644
--- app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
+++ app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
@@ -142,7 +142,7 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
     protected function _validateTemplatePath(array $templatePaths)
     {
         foreach ($templatePaths as $path) {
-            if (strpos($path, '../') !== false) {
+            if (strpos($path, '..' . DS) !== false) {
                 throw new Exception();
             }
         }
diff --git app/code/core/Mage/Api/Helper/Data.php app/code/core/Mage/Api/Helper/Data.php
index 0ededf8..ccdc1d9 100644
--- app/code/core/Mage/Api/Helper/Data.php
+++ app/code/core/Mage/Api/Helper/Data.php
@@ -36,6 +36,49 @@ class Mage_Api_Helper_Data extends Mage_Core_Helper_Abstract
     const XML_PATH_API_WSI = 'api/config/compliance_wsi';
 
     /**
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
+
+    /**
      * @return boolean
      */
     public function isComplianceWSI()
diff --git app/code/core/Mage/Api/Model/Server/Adapter/Soap.php app/code/core/Mage/Api/Model/Server/Adapter/Soap.php
index 70b0ad8..32bce7b 100644
--- app/code/core/Mage/Api/Model/Server/Adapter/Soap.php
+++ app/code/core/Mage/Api/Model/Server/Adapter/Soap.php
@@ -113,7 +113,7 @@ class Mage_Api_Model_Server_Adapter_Soap
             }
 
             $wsdlConfig->setUrl(
-                htmlspecialchars(Mage::getUrl('*/*/*', array('_query'=>$queryParams) ))
+                Mage::helper('api')->getServiceUrl('*/*/*', array('_query' => $queryParams), true)
             );
             $wsdlConfig->setName('Magento');
             $wsdlConfig->setHandler($this->getHandler());
@@ -196,10 +196,9 @@ class Mage_Api_Model_Server_Adapter_Soap
      */
     protected function getWsdlUrl($params = null, $withAuth = true)
     {
-        $urlModel = Mage::getModel('core/url')
-                ->setUseSession(false);
-
-        $wsdlUrl = ($params !== null)? $urlModel->getUrl('*/*/*', $params) : $urlModel->getUrl('*/*/*');
+        $wsdlUrl = $params !== null
+            ? Mage::helper('api')->getServiceUrl('*/*/*', array('_current' => true, '_query' => $params))
+            : Mage::helper('api')->getServiceUrl('*/*/*');
 
         if ( $withAuth ) {
             $phpAuthUser = rawurlencode($this->getController()->getRequest()->getServer('PHP_AUTH_USER', false));
diff --git app/code/core/Mage/Api/Model/Wsdl/Config.php app/code/core/Mage/Api/Model/Wsdl/Config.php
index b7921a6..596d94f 100644
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
index a4dc792..fb2d649 100644
--- app/code/core/Mage/Api/Model/Wsdl/Config/Base.php
+++ app/code/core/Mage/Api/Model/Wsdl/Config/Base.php
@@ -81,8 +81,15 @@ class Mage_Api_Model_Wsdl_Config_Base extends Varien_Simplexml_Config
         $template = Mage::getModel('core/email_template_filter');
 
         if (null === $this->_wsdlVariables) {
+            $queryParams = Mage::app()->getRequest()->getQuery();
+            if (isset($queryParams['wsdl'])) {
+                unset($queryParams['wsdl']);
+            }
+
             $this->_wsdlVariables = new Varien_Object();
-            $this->_wsdlVariables->setUrl(Mage::getUrl('*/*/*'));
+            $this->_wsdlVariables->setUrl(
+                Mage::helper('api')->getServiceUrl('*/*/*', array('_query' => $queryParams), true)
+            );
             $this->_wsdlVariables->setName('Magento');
             $this->_wsdlVariables->setHandler($this->getHandler());
         }
diff --git app/code/core/Mage/Core/Helper/String.php app/code/core/Mage/Core/Helper/String.php
index 6e9d49b..042f149 100644
--- app/code/core/Mage/Core/Helper/String.php
+++ app/code/core/Mage/Core/Helper/String.php
@@ -71,6 +71,26 @@ class Mage_Core_Helper_String extends Mage_Core_Helper_Abstract
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
diff --git app/code/core/Mage/Core/Model/File/Validator/Image.php app/code/core/Mage/Core/Model/File/Validator/Image.php
index c786906..09347af 100644
--- app/code/core/Mage/Core/Model/File/Validator/Image.php
+++ app/code/core/Mage/Core/Model/File/Validator/Image.php
@@ -90,10 +90,7 @@ class Mage_Core_Model_File_Validator_Image
         list($imageWidth, $imageHeight, $fileType) = getimagesize($filePath);
         if ($fileType) {
             if ($this->isImageType($fileType)) {
-                /**
-                 * if 'general/reprocess_images/active' false then skip image reprocessing.
-                 * NOTE: If you turn off images reprocessing, then your upload images process may cause security risks.
-                 */
+                /** if 'general/reprocess_images/active' false then skip image reprocessing. */
                 if (!Mage::getStoreConfigFlag('general/reprocess_images/active')) {
                     return null;
                 }
diff --git app/code/core/Mage/Core/etc/config.xml app/code/core/Mage/Core/etc/config.xml
index 678ec56..9c67991 100644
--- app/code/core/Mage/Core/etc/config.xml
+++ app/code/core/Mage/Core/etc/config.xml
@@ -405,6 +405,7 @@
                     </protected>
                 </public_files_valid_paths>
             </file>
+            <!-- NOTE: If you turn off images reprocessing, then your upload images process may cause security risks. -->
             <reprocess_images>
                 <active>1</active>
             </reprocess_images>
diff --git app/code/core/Mage/Core/etc/system.xml app/code/core/Mage/Core/etc/system.xml
index 5e31988..b6f576d 100644
--- app/code/core/Mage/Core/etc/system.xml
+++ app/code/core/Mage/Core/etc/system.xml
@@ -599,7 +599,7 @@
                             <show_in_default>1</show_in_default>
                             <show_in_website>1</show_in_website>
                             <show_in_store>1</show_in_store>
-                            <comment>Logging from Mage::log(). File is located in {{base_dir}}/var/log</comment>
+                            <comment>Logging from Mage::log(). File is located in {{base_dir}}/var/log. Allowed file extensions: log, txt, html, csv</comment>
                         </file>
                         <exception_file translate="label comment">
                             <label>Exceptions Log File Name</label>
@@ -608,7 +608,7 @@
                             <show_in_default>1</show_in_default>
                             <show_in_website>1</show_in_website>
                             <show_in_store>1</show_in_store>
-                            <comment>Logging from Mage::logException(). File is located in {{base_dir}}/var/log</comment>
+                            <comment>Logging from Mage::logException(). File is located in {{base_dir}}/var/log. Allowed file extensions: log, txt, html, csv</comment>
                         </exception_file>
                     </fields>
                 </log>
diff --git app/code/core/Mage/Customer/Model/Customer.php app/code/core/Mage/Customer/Model/Customer.php
index 55aa9a4..4604d56 100644
--- app/code/core/Mage/Customer/Model/Customer.php
+++ app/code/core/Mage/Customer/Model/Customer.php
@@ -49,6 +49,11 @@ class Mage_Customer_Model_Customer extends Mage_Core_Model_Abstract
     const XML_PATH_GENERATE_HUMAN_FRIENDLY_ID   = 'customer/create_account/generate_human_friendly_id';
 
     /**
+     * Maximum Password Length
+     */
+    const MAXIMUM_PASSWORD_LENGTH = 256;
+
+    /**
      * Codes of exceptions related to customer model
      */
     const EXCEPTION_EMAIL_NOT_CONFIRMED       = 1;
@@ -811,6 +816,10 @@ class Mage_Customer_Model_Customer extends Mage_Core_Model_Abstract
         if (strlen($password) && !Zend_Validate::is($password, 'StringLength', array(6))) {
             $errors[] = $customerHelper->__('The minimum password length is %s', 6);
         }
+        if (strlen($password) && !Zend_Validate::is($password, 'StringLength', array('max' => self::MAXIMUM_PASSWORD_LENGTH))) {
+            $errors[] = Mage::helper('customer')
+                ->__('Please enter a password with at most %s characters.', self::MAXIMUM_PASSWORD_LENGTH);
+        }
         $confirmation = $this->getConfirmation();
         if ($password != $confirmation) {
             $errors[] = $customerHelper->__('Please make sure your passwords match.');
diff --git app/code/core/Mage/Eav/Model/Entity/Attribute/Backend/Serialized.php app/code/core/Mage/Eav/Model/Entity/Attribute/Backend/Serialized.php
index 2d8474c..cb701d8 100644
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
index 3e37303..d197568 100644
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
diff --git app/code/core/Mage/Rule/Model/Rule.php app/code/core/Mage/Rule/Model/Rule.php
index c3671a3..8736f45 100644
--- app/code/core/Mage/Rule/Model/Rule.php
+++ app/code/core/Mage/Rule/Model/Rule.php
@@ -245,14 +245,24 @@ class Mage_Rule_Model_Rule extends Mage_Core_Model_Abstract
     protected function _afterLoad()
     {
         parent::_afterLoad();
-        $conditionsArr = unserialize($this->getConditionsSerialized());
-        if (!empty($conditionsArr) && is_array($conditionsArr)) {
-            $this->getConditions()->loadArray($conditionsArr);
+        if ($this->hasConditionsSerialized()) {
+            $conditionsArr = $this->getConditionsSerialized();
+            if (!empty($conditionsArr)) {
+                $conditionsArr = Mage::helper('core/unserializeArray')->unserialize($conditionsArr);
+                if (is_array($conditionsArr) && !empty($conditionsArr)) {
+                    $this->getConditions()->loadArray($conditionsArr);
+                }
+            }
         }
 
-        $actionsArr = unserialize($this->getActionsSerialized());
-        if (!empty($actionsArr) && is_array($actionsArr)) {
-            $this->getActions()->loadArray($actionsArr);
+        if ($this->hasActionsSerialized()) {
+            $actionsArr = $this->getActionsSerialized();
+            if (!empty($actionsArr)) {
+                $actionsArr = Mage::helper('core/unserializeArray')->unserialize($actionsArr);
+                if (is_array($actionsArr) && !empty($actionsArr)) {
+                    $this->getActions()->loadArray($actionsArr);
+                }
+            }
         }
 
         $websiteIds = $this->_getData('website_ids');
diff --git app/code/core/Mage/Sales/Block/Adminhtml/Billing/Agreement/Grid.php app/code/core/Mage/Sales/Block/Adminhtml/Billing/Agreement/Grid.php
index 7819615..b74733c 100644
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
diff --git app/design/adminhtml/default/default/template/sales/billing/agreement/view/tab/info.phtml app/design/adminhtml/default/default/template/sales/billing/agreement/view/tab/info.phtml
index 105cd64..62f8fb3 100644
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
diff --git app/locale/en_US/Mage_Adminhtml.csv app/locale/en_US/Mage_Adminhtml.csv
index 2f698c7..e74d1af 100644
--- app/locale/en_US/Mage_Adminhtml.csv
+++ app/locale/en_US/Mage_Adminhtml.csv
@@ -2,6 +2,7 @@
 " You will need to navigate to your "," You will need to navigate to your "
 " [deleted]"," [deleted]"
 " and "," and "
+"Invalid file extension used for log file. Allowed file extensions: log, txt, html, csv", "Invalid file extension used for log file. Allowed file extensions: log, txt, html, csv"
 " and go to the "," and go to the "
 " sections for your Hosted Checkout Pages."," sections for your Hosted Checkout Pages."
 "%s (Default Template from Locale)","%s (Default Template from Locale)"
diff --git app/locale/en_US/Mage_Customer.csv app/locale/en_US/Mage_Customer.csv
index d1fa77d..0a83f77 100644
--- app/locale/en_US/Mage_Customer.csv
+++ app/locale/en_US/Mage_Customer.csv
@@ -26,6 +26,7 @@
 "Address Templates","Address Templates"
 "Addresses","Addresses"
 "Admin","Admin"
+"Please enter a password with at most %s characters.","Please enter a password with at most %s characters."
 "All","All"
 "All Store Views","All Store Views"
 "All countries","All countries"
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
