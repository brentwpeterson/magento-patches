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


SUPEE-11295_CE_1501 | CE_1.5.0.1 | v1 | 145a9809d30a4f6220e3cfd68943e24539cc6829 | Fri Jan 17 20:03:45 2020 +0000 | 1d69b1531f824cdfdbde1148ea5874efe4a081a0..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Adminhtml/Block/Catalog/Product/Helper/Form/Gallery/Content.php app/code/core/Mage/Adminhtml/Block/Catalog/Product/Helper/Form/Gallery/Content.php
index 601b669068e..5044bb93394 100644
--- app/code/core/Mage/Adminhtml/Block/Catalog/Product/Helper/Form/Gallery/Content.php
+++ app/code/core/Mage/Adminhtml/Block/Catalog/Product/Helper/Form/Gallery/Content.php
@@ -48,7 +48,11 @@ class Mage_Adminhtml_Block_Catalog_Product_Helper_Form_Gallery_Content extends M
         );
 
         $this->getUploader()->getConfig()
-            ->setUrl(Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/catalog_product_gallery/upload'))
+            ->setUrl(Mage::getModel('adminhtml/url')->addSessionParam()
+            ->getUrl(
+                '*/catalog_product_gallery/upload',
+                array('_query' => false)
+            ))
             ->setFileField('image')
             ->setFilters(array(
                 'images' => array(
diff --git app/code/core/Mage/Adminhtml/Block/Cms/Wysiwyg/Images/Content/Uploader.php app/code/core/Mage/Adminhtml/Block/Cms/Wysiwyg/Images/Content/Uploader.php
index 27f30a208f5..1606f696f74 100644
--- app/code/core/Mage/Adminhtml/Block/Cms/Wysiwyg/Images/Content/Uploader.php
+++ app/code/core/Mage/Adminhtml/Block/Cms/Wysiwyg/Images/Content/Uploader.php
@@ -46,7 +46,10 @@ class Mage_Adminhtml_Block_Cms_Wysiwyg_Images_Content_Uploader extends Mage_Admi
             $files[] = '*.' . $ext;
         }
         $this->getConfig()
-            ->setUrl(Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/*/upload', array('type' => $type)))
+            ->setUrl(Mage::getModel('adminhtml/url')->addSessionParam()->getUrl(
+                '*/*/upload',
+                array('type' => $type, '_query' => false)
+            ))
             ->setParams($params)
             ->setFileField('image')
             ->setFilters(array(
diff --git app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php
index b3cadd0136e..1d6c97a0d5c 100644
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
index ac3205ded97..ae518670f19 100644
--- app/design/adminhtml/default/default/template/forgotpassword.phtml
+++ app/design/adminhtml/default/default/template/forgotpassword.phtml
@@ -27,6 +27,7 @@
 <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
 <html lang="en">
 <head>
+    <meta name="robots" content="noindex, nofollow" />
     <title><?php echo Mage::helper('adminhtml')->__('Log into Magento Admin Page') ?></title>
     <meta http-equiv="Content-Type" content="text/html; charset=utf-8" ></meta>
     <style type="text/css" media="all">
diff --git app/design/adminhtml/default/default/template/login.phtml app/design/adminhtml/default/default/template/login.phtml
index a0943d4e350..47bda4cde83 100644
--- app/design/adminhtml/default/default/template/login.phtml
+++ app/design/adminhtml/default/default/template/login.phtml
@@ -27,6 +27,7 @@
 <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
 <html lang="en">
 <head>
+    <meta name="robots" content="noindex, nofollow" />
     <title><?php echo Mage::helper('adminhtml')->__('Log into Magento Admin Page') ?></title>
     <meta http-equiv="Content-Type" content="text/html; charset=utf-8" ></meta>
     <link type="text/css" rel="stylesheet" href="<?php echo $this->getSkinUrl('reset.css') ?>" media="all" />
diff --git app/design/adminhtml/default/default/template/page/head.phtml app/design/adminhtml/default/default/template/page/head.phtml
index 3764dcf9410..f5b291f19be 100644
--- app/design/adminhtml/default/default/template/page/head.phtml
+++ app/design/adminhtml/default/default/template/page/head.phtml
@@ -1,5 +1,6 @@
 <title><?php echo htmlspecialchars(html_entity_decode($this->getTitle())) ?></title>
 <meta http-equiv="Content-Type" content="<?php echo $this->getContentType() ?>"/>
+<meta name="robots" content="noindex, nofollow"/>
 
 <link rel="icon" href="<?php echo $this->getSkinUrl('favicon.ico') ?>" type="image/x-icon"/>
 <link rel="shortcut icon" href="<?php echo $this->getSkinUrl('favicon.ico') ?>" type="image/x-icon"/>
