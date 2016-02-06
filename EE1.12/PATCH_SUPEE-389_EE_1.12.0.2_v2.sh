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


SUPEE-389 | EE_1.12.0.2 | v1 | 53c8ca52583358953b143aaa1a78cf409e8dd846 | Thu Jun 20 10:36:39 2013 +0300 | v1.12.0.2..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Catalog/Model/Url.php app/code/core/Mage/Catalog/Model/Url.php
index fa55fc5..a755b46 100644
--- app/code/core/Mage/Catalog/Model/Url.php
+++ app/code/core/Mage/Catalog/Model/Url.php
@@ -609,6 +609,23 @@ class Mage_Catalog_Model_Url
      */
     public function getUnusedPath($storeId, $requestPath, $idPath)
     {
+        $urlKey = '';
+        return $this->getUnusedPathByUrlkey($storeId, $requestPath, $idPath, $urlKey);
+    }
+
+    /**
+     * Get requestPath that was not used yet.
+     *
+     * Will try to get unique path by adding -1 -2 etc. between url_key and optional url_suffix
+     *
+     * @param int $storeId
+     * @param string $requestPath
+     * @param string $idPath
+     * @param string $urlKey
+     * @return string
+     */
+    public function getUnusedPathByUrlkey($storeId, $requestPath, $idPath, $urlKey = '')
+    {
         if (strpos($idPath, 'product') !== false) {
             $suffix = $this->getProductUrlSuffix($storeId);
         } else {
@@ -645,21 +662,22 @@ class Mage_Catalog_Model_Url
             }
             // match request_url abcdef1234(-12)(.html) pattern
             $match = array();
-            $regularExpression = '#^([0-9a-z/-]+?)(-([0-9]+))?('.preg_quote($suffix).')?$#i';
+            $regularExpression = '#(?P<prefix>(.*/)?' . preg_quote($urlKey) . ')(-(?P<increment>[0-9]+))?(?P<suffix>'
+                . preg_quote($suffix) . ')?$#i';
             if (!preg_match($regularExpression, $requestPath, $match)) {
-                return $this->getUnusedPath($storeId, '-', $idPath);
+                return $this->getUnusedPathByUrlkey($storeId, '-', $idPath, $urlKey);
             }
-            $match[1] = $match[1] . '-';
-            $match[4] = isset($match[4]) ? $match[4] : '';
+            $match['prefix'] = $match['prefix'] . '-';
+            $match['suffix'] = isset($match['suffix']) ? $match['suffix'] : '';
 
             $lastRequestPath = $this->getResource()
-                ->getLastUsedRewriteRequestIncrement($match[1], $match[4], $storeId);
+                ->getLastUsedRewriteRequestIncrement($match['prefix'], $match['suffix'], $storeId);
             if ($lastRequestPath) {
-                $match[3] = $lastRequestPath;
+                $match['increment'] = $lastRequestPath;
             }
-            return $match[1]
-                . (isset($match[3]) ? ($match[3]+1) : '1')
-                . $match[4];
+            return $match['prefix']
+                . (isset($match['increment']) ? ($match['increment']+1) : '1')
+                . $match['suffix'];
         }
         else {
             return $requestPath;
@@ -699,7 +717,7 @@ class Mage_Catalog_Model_Url
     {
         $storeId = $category->getStoreId();
         $idPath  = $this->generatePath('id', null, $category);
-        $suffix  = $this->getCategoryUrlSuffix($storeId);
+        $categoryUrlSuffix = $this->getCategoryUrlSuffix($storeId);
 
         if (isset($this->_rewrites[$idPath])) {
             $this->_rewrite = $this->_rewrites[$idPath];
@@ -713,27 +731,27 @@ class Mage_Catalog_Model_Url
             $urlKey = $this->getCategoryModel()->formatUrlKey($category->getUrlKey());
         }
 
-        $categoryUrlSuffix = $this->getCategoryUrlSuffix($category->getStoreId());
         if (null === $parentPath) {
             $parentPath = $this->getResource()->getCategoryParentPath($category);
         }
         elseif ($parentPath == '/') {
             $parentPath = '';
         }
-        $parentPath = Mage::helper('catalog/category')->getCategoryUrlPath($parentPath,
-                                                                           true, $category->getStoreId());
+        $parentPath = Mage::helper('catalog/category')->getCategoryUrlPath($parentPath, true, $storeId);
 
-        $requestPath = $parentPath . $urlKey . $categoryUrlSuffix;
-        if (isset($existingRequestPath) && $existingRequestPath == $requestPath . $suffix) {
+        $requestPath = $parentPath . $urlKey;
+        $regexp = '/^' . preg_quote($requestPath, '/') . '(\-[0-9]+)?' . preg_quote($categoryUrlSuffix, '/') . '$/i';
+        if (isset($existingRequestPath) && preg_match($regexp, $existingRequestPath)) {
             return $existingRequestPath;
         }
 
-        if ($this->_deleteOldTargetPath($requestPath, $idPath, $storeId)) {
+        $fullPath = $requestPath . $categoryUrlSuffix;
+        if ($this->_deleteOldTargetPath($fullPath, $idPath, $storeId)) {
             return $requestPath;
         }
 
-        return $this->getUnusedPath($category->getStoreId(), $requestPath,
-                                    $this->generatePath('id', null, $category)
+        return $this->getUnusedPathByUrlkey($storeId, $fullPath,
+            $this->generatePath('id', null, $category), $urlKey
         );
     }
 
@@ -798,7 +816,8 @@ class Mage_Catalog_Model_Url
             $this->_rewrite = $this->_rewrites[$idPath];
             $existingRequestPath = $this->_rewrites[$idPath]->getRequestPath();
 
-            if ($existingRequestPath == $requestPath . $suffix) {
+            $regexp = '/^' . preg_quote($requestPath, '/') . '(\-[0-9]+)?' . preg_quote($suffix, '/') . '$/i';
+            if (preg_match($regexp, $existingRequestPath)) {
                 return $existingRequestPath;
             }
 
@@ -836,7 +855,7 @@ class Mage_Catalog_Model_Url
         /**
          * Use unique path generator
          */
-        return $this->getUnusedPath($storeId, $requestPath.$suffix, $idPath);
+        return $this->getUnusedPathByUrlkey($storeId, $requestPath.$suffix, $idPath, $urlKey);
     }
 
     /**
@@ -891,8 +910,8 @@ class Mage_Catalog_Model_Url
                 $parentPath = Mage::helper('catalog/category')->getCategoryUrlPath($parentPath,
                     true, $category->getStoreId());
 
-                return $this->getUnusedPath($category->getStoreId(), $parentPath . $urlKey . $categoryUrlSuffix,
-                    $this->generatePath('id', null, $category)
+                return $this->getUnusedPathByUrlkey($category->getStoreId(), $parentPath . $urlKey . $categoryUrlSuffix,
+                    $this->generatePath('id', null, $category), $urlKey
                 );
             }
 
@@ -913,14 +932,14 @@ class Mage_Catalog_Model_Url
                 $this->_addCategoryUrlPath($category);
                 $categoryUrl = Mage::helper('catalog/category')->getCategoryUrlPath($category->getUrlPath(),
                     false, $category->getStoreId());
-                return $this->getUnusedPath($category->getStoreId(), $categoryUrl . '/' . $urlKey . $productUrlSuffix,
-                    $this->generatePath('id', $product, $category)
+                return $this->getUnusedPathByUrlkey($category->getStoreId(), $categoryUrl . '/' . $urlKey . $productUrlSuffix,
+                    $this->generatePath('id', $product, $category), $urlKey
                 );
             }
 
             // for product only
-            return $this->getUnusedPath($category->getStoreId(), $urlKey . $productUrlSuffix,
-                $this->generatePath('id', $product)
+            return $this->getUnusedPathByUrlkey($category->getStoreId(), $urlKey . $productUrlSuffix,
+                $this->generatePath('id', $product), $urlKey
             );
         }
 
