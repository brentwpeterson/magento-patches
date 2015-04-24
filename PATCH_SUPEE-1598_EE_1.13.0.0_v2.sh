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


SUPEE-1598 | EE_1.13.0.0 | v1 | 8b1c62c85774aafaf10b3c5d05b564b901fb4f64 | Thu Jun 27 12:21:53 2013 -0700 | v1.13.0.0..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Enterprise/PageCache/Model/Config.php app/code/core/Enterprise/PageCache/Model/Config.php
index dee7fe4..bf94a83 100644
--- app/code/core/Enterprise/PageCache/Model/Config.php
+++ app/code/core/Enterprise/PageCache/Model/Config.php
@@ -117,7 +117,8 @@ class Enterprise_PageCache_Model_Config extends Varien_Simplexml_Config
 
             $placeholder = $placeholderData['code']
                 . ' container="' . $placeholderData['container'] . '"'
-                . ' block="' . get_class($block) . '"';
+                . ' block="' . get_class($block) . '"'
+                . ' cache_lifetime="' . $placeholderData['cache_lifetime'] . '"';
             $placeholder.= ' cache_id="' . $block->getCacheKey() . '"';
 
             if (!empty($placeholderData['cache_lifetime'])) {
diff --git app/code/core/Enterprise/PageCache/Model/Container/Abstract.php app/code/core/Enterprise/PageCache/Model/Container/Abstract.php
index c86d733..524ea11 100644
--- app/code/core/Enterprise/PageCache/Model/Container/Abstract.php
+++ app/code/core/Enterprise/PageCache/Model/Container/Abstract.php
@@ -189,7 +189,7 @@ abstract class Enterprise_PageCache_Model_Container_Abstract
         $tags[] = Enterprise_PageCache_Model_Processor::CACHE_TAG;
         $tags = array_merge($tags, $this->_getPlaceHolderBlock()->getCacheTags());
         if (is_null($lifetime)) {
-            $lifetime = $this->_placeholder->getAttribute('cache_lifetime') ?
+            $lifetime = $this->_placeholder->getAttribute('cache_lifetime') !== null ?
                 $this->_placeholder->getAttribute('cache_lifetime') : false;
         }
         Enterprise_PageCache_Helper_Data::prepareContentPlaceholders($data);
diff --git app/code/core/Enterprise/PageCache/Model/Observer.php app/code/core/Enterprise/PageCache/Model/Observer.php
index b34ccd3..1615330 100755
--- app/code/core/Enterprise/PageCache/Model/Observer.php
+++ app/code/core/Enterprise/PageCache/Model/Observer.php
@@ -38,6 +38,16 @@ class Enterprise_PageCache_Model_Observer
      */
     const XML_PATH_DESIGN_EXCEPTION = 'design/package/ua_regexp';
 
+    /*
+     * Theme types exceptions involved into cache key
+     */
+    protected $_themeExceptionTypes = array(
+        'template',
+        'skin',
+        'layout',
+        'default'
+    );
+
     /**
      * Page Cache Processor
      *
@@ -143,12 +153,25 @@ class Enterprise_PageCache_Model_Observer
         if (!$this->isCacheEnabled()) {
             return $this;
         }
-        $cacheId = Enterprise_PageCache_Model_Processor::DESIGN_EXCEPTION_KEY;
 
-        if (!Enterprise_PageCache_Model_Cache::getCacheInstance()->getFrontend()->test($cacheId)) {
-            $exception = Mage::getStoreConfig(self::XML_PATH_DESIGN_EXCEPTION);
-            Enterprise_PageCache_Model_Cache::getCacheInstance()
-                ->save($exception, $cacheId, array(Enterprise_PageCache_Model_Processor::CACHE_TAG));
+        $cacheId = Enterprise_PageCache_Model_Processor::DESIGN_EXCEPTION_KEY;
+        $storeIdentifier = isset($_COOKIE[Mage_Core_Model_Store::COOKIE_NAME]) ?
+        $_COOKIE[Mage_Core_Model_Store::COOKIE_NAME] :
+        Mage::app()->getRequest()->getHttpHost() . Mage::app()->getRequest()->getBaseUrl();
+
+        $exceptions = Enterprise_PageCache_Model_Cache::getCacheInstance()->load($cacheId);
+        $exceptions = $exceptions === false ? array() : (array)@unserialize($exceptions);
+        if (!isset ($exceptions[$storeIdentifier])) {
+            $exceptions[$storeIdentifier][self::XML_PATH_DESIGN_EXCEPTION] = Mage::getStoreConfig(
+                self::XML_PATH_DESIGN_EXCEPTION
+            );
+            foreach ($this->_themeExceptionTypes as $type) {
+                $configPath = sprintf('design/theme/%s_ua_regexp', $type);
+                $exceptions[$storeIdentifier][$configPath] = Mage::getStoreConfig($configPath);
+            }
+            Enterprise_PageCache_Model_Cache::getCacheInstance()->save(serialize($exceptions), $cacheId,
+                array(Enterprise_PageCache_Model_Processor::CACHE_TAG)
+            );
             $this->_processor->refreshRequestIds();
         }
         return $this;
@@ -687,10 +710,8 @@ class Enterprise_PageCache_Model_Observer
      */
     public function registerDesignExceptionsChange(Varien_Event_Observer $observer)
     {
-        $object = $observer->getDataObject();
         Enterprise_PageCache_Model_Cache::getCacheInstance()
-            ->save($object->getValue(), Enterprise_PageCache_Model_Processor::DESIGN_EXCEPTION_KEY,
-                array(Enterprise_PageCache_Model_Processor::CACHE_TAG));
+            ->remove(Enterprise_PageCache_Model_Processor::DESIGN_EXCEPTION_KEY);
         return $this;
     }
 
diff --git app/code/core/Enterprise/PageCache/Model/Processor.php app/code/core/Enterprise/PageCache/Model/Processor.php
index 411206d..d60e628 100644
--- app/code/core/Enterprise/PageCache/Model/Processor.php
+++ app/code/core/Enterprise/PageCache/Model/Processor.php
@@ -124,8 +124,8 @@ class Enterprise_PageCache_Model_Processor
          * Define COOKIE state
          */
         if ($uri) {
-            if (isset($_COOKIE['store'])) {
-                $uri = $uri.'_'.$_COOKIE['store'];
+            if (isset($_COOKIE[Mage_Core_Model_Store::COOKIE_NAME])) {
+                $uri = $uri.'_'.$_COOKIE[Mage_Core_Model_Store::COOKIE_NAME];
             }
             if (isset($_COOKIE['currency'])) {
                 $uri = $uri.'_'.$_COOKIE['currency'];
@@ -188,11 +188,24 @@ class Enterprise_PageCache_Model_Processor
             return false;
         }
 
-        $rules = @unserialize($exceptions);
-        if (empty($rules)) {
+        $exceptions      = (array)@unserialize($exceptions);
+        $storeIdentifier = isset($_COOKIE[Mage_Core_Model_Store::COOKIE_NAME]) ?
+                            $_COOKIE[Mage_Core_Model_Store::COOKIE_NAME] :
+                            Mage::app()->getRequest()->getHttpHost() . Mage::app()->getRequest()->getBaseUrl();
+        if (!isset($exceptions[$storeIdentifier])) {
             return false;
         }
-        return Mage_Core_Model_Design_Package::getPackageByUserAgent($rules);
+
+        $keys = array();
+        foreach ($exceptions[$storeIdentifier] as $type => $exception) {
+            $rule = (array)@unserialize($exception);
+            if (empty($rule)) {
+                $keys[] = '';
+            } else {
+                $keys[] = Mage_Core_Model_Design_Package::getPackageByUserAgent($rule, $type);
+            }
+        }
+        return implode($keys, "|");
     }
 
     /**
diff --git app/code/core/Mage/Core/etc/system.xml app/code/core/Mage/Core/etc/system.xml
index 9488a64..97169bd 100644
--- app/code/core/Mage/Core/etc/system.xml
+++ app/code/core/Mage/Core/etc/system.xml
@@ -327,7 +327,7 @@
                         <template_ua_regexp translate="comment">
                             <label></label>
                             <frontend_model>adminhtml/system_config_form_field_regexceptions</frontend_model>
-                            <backend_model>adminhtml/system_config_backend_serialized_array</backend_model>
+                            <backend_model>adminhtml/system_config_backend_design_exception</backend_model>
                             <sort_order>25</sort_order>
                             <show_in_default>1</show_in_default>
                             <show_in_website>1</show_in_website>
@@ -345,7 +345,7 @@
                         <skin_ua_regexp translate="comment">
                             <label></label>
                             <frontend_model>adminhtml/system_config_form_field_regexceptions</frontend_model>
-                            <backend_model>adminhtml/system_config_backend_serialized_array</backend_model>
+                            <backend_model>adminhtml/system_config_backend_design_exception</backend_model>
                             <sort_order>35</sort_order>
                             <show_in_default>1</show_in_default>
                             <show_in_website>1</show_in_website>
@@ -362,7 +362,7 @@
                         <layout_ua_regexp translate="comment">
                             <label></label>
                             <frontend_model>adminhtml/system_config_form_field_regexceptions</frontend_model>
-                            <backend_model>adminhtml/system_config_backend_serialized_array</backend_model>
+                            <backend_model>adminhtml/system_config_backend_design_exception</backend_model>
                             <sort_order>55</sort_order>
                             <show_in_default>1</show_in_default>
                             <show_in_website>1</show_in_website>
@@ -379,7 +379,7 @@
                         <default_ua_regexp translate="comment">
                             <label></label>
                             <frontend_model>adminhtml/system_config_form_field_regexceptions</frontend_model>
-                            <backend_model>adminhtml/system_config_backend_serialized_array</backend_model>
+                            <backend_model>adminhtml/system_config_backend_design_exception</backend_model>
                             <sort_order>65</sort_order>
                             <show_in_default>1</show_in_default>
                             <show_in_website>1</show_in_website>
