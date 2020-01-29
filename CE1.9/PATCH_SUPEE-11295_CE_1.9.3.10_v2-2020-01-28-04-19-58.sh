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


SUPEE-11295_CE_19310 | CE_1.9.3.10 | v1 | b34f8957d64c3537b918e43b1158d4e3dc31a5d7 | Fri Jan 17 20:03:45 2020 +0000 | 8206c9a2084ec970141d558a75a3e9e2d8b68735..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Adminhtml/Block/Catalog/Product/Helper/Form/Gallery/Content.php app/code/core/Mage/Adminhtml/Block/Catalog/Product/Helper/Form/Gallery/Content.php
index 90b04614f5d..0a8eac5ed66 100644
--- app/code/core/Mage/Adminhtml/Block/Catalog/Product/Helper/Form/Gallery/Content.php
+++ app/code/core/Mage/Adminhtml/Block/Catalog/Product/Helper/Form/Gallery/Content.php
@@ -55,7 +55,10 @@ class Mage_Adminhtml_Block_Catalog_Product_Helper_Form_Gallery_Content extends M
 
         $this->getUploader()->getUploaderConfig()
             ->setFileParameterName('image')
-            ->setTarget(Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/catalog_product_gallery/upload'));
+            ->setTarget(Mage::getModel('adminhtml/url')->addSessionParam()->getUrl(
+                '*/catalog_product_gallery/upload',
+                array('_query' => false)
+            ));
 
         $browseConfig = $this->getUploader()->getButtonConfig();
         $browseConfig
diff --git app/code/core/Mage/Adminhtml/Block/Cms/Wysiwyg/Images/Content/Uploader.php app/code/core/Mage/Adminhtml/Block/Cms/Wysiwyg/Images/Content/Uploader.php
index 15c7f76131b..2a4fd06290d 100644
--- app/code/core/Mage/Adminhtml/Block/Cms/Wysiwyg/Images/Content/Uploader.php
+++ app/code/core/Mage/Adminhtml/Block/Cms/Wysiwyg/Images/Content/Uploader.php
@@ -44,7 +44,10 @@ class Mage_Adminhtml_Block_Cms_Wysiwyg_Images_Content_Uploader extends Mage_Uplo
         $this->getUploaderConfig()
             ->setFileParameterName('image')
             ->setTarget(
-                Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/*/upload', array('type' => $type))
+                Mage::getModel('adminhtml/url')->addSessionParam()->getUrl(
+                    '*/*/upload',
+                    array('type' => $type, '_query' => false)
+                )
             );
         $this->getButtonConfig()
             ->setAttributes(array(
diff --git app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php
index 51e6ecd37b8..78dd30425ce 100644
--- app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php
+++ app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php
@@ -50,9 +50,9 @@ class Mage_Core_Model_Input_Filter_MaliciousCode implements Zend_Filter_Interfac
         //js in the style attribute
         '/style=[^<]*((expression\s*?\([^<]*?\))|(behavior\s*:))[^<]*(?=\>)/Uis',
         //js attributes
-        '/(ondblclick|onclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|onload|onunload|onerror|onanimationstart)\s*=[^>]*(?=\>)/Uis',
+        '/(ondblclick|onclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|onload|onunload|onerror|onanimationstart|onfocus|onloadstart|ontoggle)\s*=[^>]*(?=\>)/Uis',
         //tags
-        '/<\/?(script|meta|link|frame|iframe).*>/Uis',
+        '/<\/?(script|meta|link|frame|iframe|object).*>/Uis',
         //base64 usage
         '/src\s*=[^<]*base64[^<]*(?=\>)/Uis',
         //data attribute
diff --git app/design/adminhtml/default/default/template/forgotpassword.phtml app/design/adminhtml/default/default/template/forgotpassword.phtml
index 7404de736d1..cd13d04f3b3 100644
--- app/design/adminhtml/default/default/template/forgotpassword.phtml
+++ app/design/adminhtml/default/default/template/forgotpassword.phtml
@@ -28,6 +28,7 @@
 <html lang="en">
 <head>
     <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
+    <meta name="robots" content="noindex, nofollow" />
     <title><?php echo Mage::helper('adminhtml')->__('Log into Magento Admin Page'); ?></title>
     <link type="text/css" rel="stylesheet" href="<?php echo $this->getSkinUrl('reset.css'); ?>" media="all" />
     <link type="text/css" rel="stylesheet" href="<?php echo $this->getSkinUrl('boxes.css'); ?>" media="all" />
diff --git app/design/adminhtml/default/default/template/login.phtml app/design/adminhtml/default/default/template/login.phtml
index 86618069509..a6c69d339b8 100644
--- app/design/adminhtml/default/default/template/login.phtml
+++ app/design/adminhtml/default/default/template/login.phtml
@@ -28,6 +28,7 @@
 <html xmlns="http://www.w3.org/1999/xhtml" lang="en">
 <head>
     <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
+    <meta name="robots" content="noindex, nofollow" />
     <title><?php echo Mage::helper('adminhtml')->__('Log into Magento Admin Page') ?></title>
     <link type="text/css" rel="stylesheet" href="<?php echo $this->getSkinUrl('reset.css') ?>" media="all" />
     <link type="text/css" rel="stylesheet" href="<?php echo $this->getSkinUrl('boxes.css') ?>" media="all" />
diff --git app/design/adminhtml/default/default/template/page/head.phtml app/design/adminhtml/default/default/template/page/head.phtml
index 6ce27573e6e..1f74a4919f3 100644
--- app/design/adminhtml/default/default/template/page/head.phtml
+++ app/design/adminhtml/default/default/template/page/head.phtml
@@ -25,6 +25,7 @@
  */
 ?>
 <meta http-equiv="Content-Type" content="<?php echo $this->getContentType() ?>"/>
+<meta name="robots" content="noindex, nofollow"/>
 <title><?php echo htmlspecialchars(html_entity_decode($this->getTitle())) ?></title>
 <link rel="icon" href="<?php echo $this->getSkinUrl('favicon.ico') ?>" type="image/x-icon"/>
 <link rel="shortcut icon" href="<?php echo $this->getSkinUrl('favicon.ico') ?>" type="image/x-icon"/>
diff --git app/design/adminhtml/default/default/template/resetforgottenpassword.phtml app/design/adminhtml/default/default/template/resetforgottenpassword.phtml
index 9ead6b42aa5..9f5536bbd7f 100644
--- app/design/adminhtml/default/default/template/resetforgottenpassword.phtml
+++ app/design/adminhtml/default/default/template/resetforgottenpassword.phtml
@@ -28,6 +28,7 @@
 <html lang="en">
     <head>
         <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
+        <meta name="robots" content="noindex, nofollow" />
         <title><?php echo Mage::helper('adminhtml')->__('Reset a Password'); ?></title>
         <link type="text/css" rel="stylesheet" href="<?php echo $this->getSkinUrl('reset.css'); ?>" media="all" />
         <link type="text/css" rel="stylesheet" href="<?php echo $this->getSkinUrl('boxes.css'); ?>" media="all" />
