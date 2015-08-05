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


SUPEE-6482_EE_1.11.0.2 | EE_1.11.0.2 | v2 | 00da8ee6ce854b2040525574e9be6e9160bc36f7 | Tue Jul 28 14:23:59 2015 +0300 | v1.11.0.2..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Enterprise/PageCache/Model/Processor.php app/code/core/Enterprise/PageCache/Model/Processor.php
index cc5d9de..f64fad0 100644
--- app/code/core/Enterprise/PageCache/Model/Processor.php
+++ app/code/core/Enterprise/PageCache/Model/Processor.php
@@ -608,6 +608,11 @@ class Enterprise_PageCache_Model_Processor
          * Define server HTTP HOST
          */
         if (isset($_SERVER['HTTP_HOST'])) {
+            if (strpos($_SERVER['HTTP_HOST'], ',') !== false || strpos($_SERVER['HTTP_HOST'], ';') !== false) {
+                $response = new Zend_Controller_Response_Http();
+                $response->setHttpResponseCode(400)->sendHeaders();
+                exit();
+            }
             $uri = $_SERVER['HTTP_HOST'];
         } elseif (isset($_SERVER['SERVER_NAME'])) {
             $uri = $_SERVER['SERVER_NAME'];
diff --git app/code/core/Mage/Api/Model/Server/Adapter/Soap.php app/code/core/Mage/Api/Model/Server/Adapter/Soap.php
index 79ad9f7..51e21b5 100644
--- app/code/core/Mage/Api/Model/Server/Adapter/Soap.php
+++ app/code/core/Mage/Api/Model/Server/Adapter/Soap.php
@@ -201,12 +201,14 @@ class Mage_Api_Model_Server_Adapter_Soap
 
         $wsdlUrl = ($params !== null)? $urlModel->getUrl('*/*/*', $params) : $urlModel->getUrl('*/*/*');
 
-        if( $withAuth ) {
-            $phpAuthUser = $this->getController()->getRequest()->getServer('PHP_AUTH_USER', false);
-            $phpAuthPw = $this->getController()->getRequest()->getServer('PHP_AUTH_PW', false);
+         if ( $withAuth ) {
+             $phpAuthUser = rawurlencode($this->getController()->getRequest()->getServer('PHP_AUTH_USER', false));
+             $phpAuthPw = rawurlencode($this->getController()->getRequest()->getServer('PHP_AUTH_PW', false));
+             $scheme = rawurlencode($this->getController()->getRequest()->getScheme());
 
             if ($phpAuthUser && $phpAuthPw) {
-                $wsdlUrl = sprintf("http://%s:%s@%s", $phpAuthUser, $phpAuthPw, str_replace('http://', '', $wsdlUrl ) );
+                 $wsdlUrl = sprintf("%s://%s:%s@%s", $scheme, $phpAuthUser, $phpAuthPw,
+                     str_replace($scheme . '://', '', $wsdlUrl));
             }
         }
 
diff --git app/code/core/Mage/Catalog/Model/Product/Api/V2.php app/code/core/Mage/Catalog/Model/Product/Api/V2.php
index 8144a36..32b3cee 100644
--- app/code/core/Mage/Catalog/Model/Product/Api/V2.php
+++ app/code/core/Mage/Catalog/Model/Product/Api/V2.php
@@ -165,7 +165,7 @@ class Mage_Catalog_Model_Product_Api_V2 extends Mage_Catalog_Model_Product_Api
      */
     public function create($type, $set, $sku, $productData, $store = null)
     {
-        if (!$type || !$set || !$sku) {
+        if (!$type || !$set || !$sku || !is_object($productData)) {
             $this->_fault('data_invalid');
         }
 
@@ -293,6 +293,9 @@ class Mage_Catalog_Model_Product_Api_V2 extends Mage_Catalog_Model_Product_Api
      */
     protected function _prepareDataForSave ($product, $productData)
     {
+        if (!is_object($productData)) {
+            $this->_fault('data_invalid');
+        }
         if (property_exists($productData, 'categories') && is_array($productData->categories)) {
             $product->setCategoryIds($productData->categories);
         }
diff --git app/code/core/Mage/Core/Controller/Request/Http.php app/code/core/Mage/Core/Controller/Request/Http.php
index 368f392..3e2c466 100644
--- app/code/core/Mage/Core/Controller/Request/Http.php
+++ app/code/core/Mage/Core/Controller/Request/Http.php
@@ -287,11 +287,19 @@ class Mage_Core_Controller_Request_Http extends Zend_Controller_Request_Http
         if (!isset($_SERVER['HTTP_HOST'])) {
             return false;
         }
+        $host = $_SERVER['HTTP_HOST'];
         if ($trimPort) {
-            $host = explode(':', $_SERVER['HTTP_HOST']);
-            return $host[0];
+            $hostParts = explode(':', $_SERVER['HTTP_HOST']);
+            $host =  $hostParts[0];
         }
-        return $_SERVER['HTTP_HOST'];
+
+        if (strpos($host, ',') !== false || strpos($host, ';') !== false) {
+            $response = new Zend_Controller_Response_Http();
+            $response->setHttpResponseCode(400)->sendHeaders();
+            exit();
+        }
+
+        return $host;
     }
 
     /**
diff --git app/design/frontend/base/default/template/page/js/cookie.phtml app/design/frontend/base/default/template/page/js/cookie.phtml
index c2b0720..4a62543 100644
--- app/design/frontend/base/default/template/page/js/cookie.phtml
+++ app/design/frontend/base/default/template/page/js/cookie.phtml
@@ -34,7 +34,7 @@
 
 <script type="text/javascript">
 //<![CDATA[
-Mage.Cookies.path     = '<?php echo $this->getPath()?>';
-Mage.Cookies.domain   = '<?php echo $this->getDomain()?>';
+Mage.Cookies.path     = '<?php echo Mage::helper('core')->jsQuoteEscape($this->getPath()) ?>';
+Mage.Cookies.domain   = '<?php echo Mage::helper('core')->jsQuoteEscape($this->getDomain()) ?>';
 //]]>
 </script>
diff --git app/design/frontend/enterprise/default/template/giftregistry/search/form.phtml app/design/frontend/enterprise/default/template/giftregistry/search/form.phtml
index 7fadaf9..aab78f1 100644
--- app/design/frontend/enterprise/default/template/giftregistry/search/form.phtml
+++ app/design/frontend/enterprise/default/template/giftregistry/search/form.phtml
@@ -138,7 +138,7 @@ $('params_type_id').observe('change', advancedFormUpdate);
 
 <?php if ($this->getFormData('type_id')): ?>
     $A($('params_type_id').options).each(function(option){
-        if (option.value==<?php echo $this->getFormData('type_id') ?>) option.selected = true;
+        if (option.value==<?php echo (int)$this->getFormData('type_id') ?>) option.selected = true;
     });
     advancedFormUpdate();
 <?php endif; ?>
