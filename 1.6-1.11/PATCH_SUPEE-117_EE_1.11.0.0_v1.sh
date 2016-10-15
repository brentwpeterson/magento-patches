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


SUPEE-117 | EE_1.11.0.0 | v1 | _ | n/a | SUPEE-117_EE_1.11.0.0_v1.patch

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/CategoryController.php
index 83723ba..c57e8fa 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/CategoryController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/CategoryController.php
@@ -295,9 +295,9 @@ class Mage_Adminhtml_Catalog_CategoryController extends Mage_Adminhtml_Controlle
             $category->setAttributeSetId($category->getDefaultAttributeSetId());
 
             if (isset($data['category_products']) &&
-                !$category->getProductsReadonly()) {
-                $products = array();
-                parse_str($data['category_products'], $products);
+                !$category->getProductsReadonly()
+            ) {
+                $products = Mage::helper('core/string')->parseQueryStr($data['category_products']);
                 $category->setPostedProducts($products);
             }
 
diff --git app/code/core/Mage/Core/Helper/Array.php app/code/core/Mage/Core/Helper/Array.php
new file mode 100644
index 0000000..1b66e6e
--- /dev/null
+++ app/code/core/Mage/Core/Helper/Array.php
@@ -0,0 +1,58 @@
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
+ * @package     Mage_Core
+ * @copyright   Copyright (c) 2011 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://www.magentocommerce.com/license/enterprise-edition
+ */
+
+class Mage_Core_Helper_Array extends Mage_Core_Helper_Abstract
+{
+    /**
+     * Merge array recursive without overwrite keys.
+     * PHP function array_merge_recursive merge array
+     * with overwrite num keys
+     *
+     * @param array $baseArray
+     * @param array $mergeArray
+     * @return array
+     */
+    public function mergeRecursiveWithoutOverwriteNumKeys(array $baseArray, array $mergeArray)
+    {
+        foreach ($mergeArray as $key => $value) {
+            if (is_array($value)) {
+                if (array_key_exists($key, $baseArray)) {
+                    $baseArray[$key] = $this->mergeRecursiveWithoutOverwriteNumKeys($baseArray[$key], $value);
+                } else {
+                    $baseArray[$key] = $value;
+                }
+            } else {
+                if ($key) {
+                    $baseArray[$key] = $value;
+                } else {
+                    $baseArray[] = $value;
+                }
+            }
+        }
+
+        return $baseArray;
+    }
+}
diff --git app/code/core/Mage/Core/Helper/String.php app/code/core/Mage/Core/Helper/String.php
index 987ef63..e5be1ba 100644
--- app/code/core/Mage/Core/Helper/String.php
+++ app/code/core/Mage/Core/Helper/String.php
@@ -34,6 +34,11 @@ class Mage_Core_Helper_String extends Mage_Core_Helper_Abstract
     const ICONV_CHARSET = 'UTF-8';
 
     /**
+     * @var Mage_Core_Helper_Array
+     */
+    protected $_arrayHelper;
+
+    /**
      * Truncate a string to a certain length if necessary, appending the $etc string.
      * $remainder will contain the string that has been replaced with $etc.
      *
@@ -299,4 +304,172 @@ class Mage_Core_Helper_String extends Mage_Core_Helper_Abstract
         return $sort;
     }
 
+    /**
+     * Parse query string to array
+     *
+     * @param string $str
+     * @return array
+     */
+    public function parseQueryStr($str)
+    {
+        $argSeparator = '&';
+        $result = array();
+        $partsQueryStr = explode($argSeparator, $str);
+
+        foreach ($partsQueryStr as $partQueryStr) {
+            if ($this->_validateQueryStr($partQueryStr)) {
+                $param = $this->_explodeAndDecodeParam($partQueryStr);
+                $param = $this->_handleRecursiveParamForQueryStr($param);
+                $result = $this->_appendParam($result, $param);
+            }
+        }
+        return $result;
+    }
+
+    /**
+     * Validate query pair string
+     *
+     * @param string $str
+     * @return bool
+     */
+    protected function _validateQueryStr($str)
+    {
+        if (!$str || (strpos($str, '=') === false)) {
+            return false;
+        }
+        return true;
+    }
+
+    /**
+     * Prepare param
+     *
+     * @param string $str
+     * @return array
+     */
+    protected function _explodeAndDecodeParam($str)
+    {
+        $preparedParam = array();
+        $param = explode('=', $str);
+        $preparedParam['key'] = urldecode(array_shift($param));
+        $preparedParam['value'] = urldecode(array_shift($param));
+
+        return $preparedParam;
+    }
+
+    /**
+     * Append param to general result
+     *
+     * @param array $result
+     * @param array $param
+     * @return array
+     */
+    protected function _appendParam(array $result, array $param)
+    {
+        $key   = $param['key'];
+        $value = $param['value'];
+
+        if ($key) {
+            if (is_array($value) && array_key_exists($key, $result)) {
+                $helper = $this->getArrayHelper();
+                $result[$key] = $helper->mergeRecursiveWithoutOverwriteNumKeys($result[$key], $value);
+            } else {
+                $result[$key] = $value;
+            }
+        }
+
+        return $result;
+    }
+
+    /**
+     * Handle param recursively
+     *
+     * @param array $param
+     * @return array
+     */
+    protected function _handleRecursiveParamForQueryStr(array $param)
+    {
+        $value = $param['value'];
+        $key = $param['key'];
+
+        $subKeyBrackets = $this->_getLastSubkey($key);
+        $subKey = $this->_getLastSubkey($key, false);
+        if ($subKeyBrackets) {
+            if ($subKey) {
+                $param['value'] = array($subKey => $value);
+            } else {
+                $param['value'] = array($value);
+            }
+            $param['key'] = $this->_removeSubkeyPartFromKey($key, $subKeyBrackets);
+            $param = $this->_handleRecursiveParamForQueryStr($param);
+        }
+
+        return $param;
+    }
+
+    /**
+     * Remove subkey part from key
+     *
+     * @param string $key
+     * @param string $subKeyBrackets
+     * @return string
+     */
+    protected function _removeSubkeyPartFromKey($key, $subKeyBrackets)
+    {
+        return substr($key, 0, strrpos($key, $subKeyBrackets));
+    }
+
+    /**
+     * Get last part key from query array
+     *
+     * @param string $key
+     * @param bool $withBrackets
+     * @return string
+     */
+    protected function _getLastSubkey($key, $withBrackets = true)
+    {
+        $subKey = '';
+        $leftBracketSymbol  = '[';
+        $rightBracketSymbol = ']';
+
+        $firstPos = strrpos($key, $leftBracketSymbol);
+        $lastPos  = strrpos($key, $rightBracketSymbol);
+
+        if (($firstPos !== false || $lastPos !== false)
+            && $firstPos < $lastPos
+        ) {
+            $keyLenght = $lastPos - $firstPos + 1;
+            $subKey = substr($key, $firstPos, $keyLenght);
+            if (!$withBrackets) {
+                $subKey = ltrim($subKey, $leftBracketSymbol);
+                $subKey = rtrim($subKey, $rightBracketSymbol);
+            }
+        }
+        return $subKey;
+    }
+
+    /**
+     * Set array helper
+     *
+     * @param Mage_Core_Helper_Abstract $helper
+     * @return Mage_Core_Helper_String
+     */
+    public function setArrayHelper(Mage_Core_Helper_Abstract $helper)
+    {
+        $this->_arrayHelper = $helper;
+        return $this;
+    }
+
+    /**
+     * Get Array Helper
+     *
+     * @return Mage_Core_Helper_Array
+     */
+    public function getArrayHelper()
+    {
+        if (!$this->_arrayHelper) {
+            $this->_arrayHelper = Mage::helper('core/array');
+        }
+        return $this->_arrayHelper;
+    }
+
 }
