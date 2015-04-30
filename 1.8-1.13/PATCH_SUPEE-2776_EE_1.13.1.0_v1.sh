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



SUPEE-2776 | EE_1.13.1.0 | v1 | e8239951fd511395d9e6c8c20898341762540495 | Tue Jan 21 16:32:08 2014 -0800 | v1.13.1.0..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Wishlist/Controller/Abstract.php app/code/core/Mage/Wishlist/Controller/Abstract.php
index f6dcb5c..79f0b9c 100644
--- app/code/core/Mage/Wishlist/Controller/Abstract.php
+++ app/code/core/Mage/Wishlist/Controller/Abstract.php
@@ -73,11 +73,6 @@ abstract class Mage_Wishlist_Controller_Abstract extends Mage_Core_Controller_Fr
      */
     public function allcartAction()
     {
-        if (!$this->_validateFormKey()) {
-            $this->_forward('noRoute');
-            return;
-        }
-
         $wishlist   = $this->_getWishlist();
         if (!$wishlist) {
             $this->_forward('noRoute');
@@ -95,7 +90,9 @@ abstract class Mage_Wishlist_Controller_Abstract extends Mage_Core_Controller_Fr
                 ->setVisibilityFilter();
 
         $qtysString = $this->getRequest()->getParam('qty');
-        $qtys =  array_filter(json_decode($qtysString), 'strlen');
+        if (isset($qtysString)) {
+            $qtys =  array_filter(json_decode($qtysString), 'strlen');
+        }
 
         foreach ($collection as $item) {
             /** @var Mage_Wishlist_Model_Item */
diff --git app/design/frontend/base/default/template/wishlist/email/items.phtml app/design/frontend/base/default/template/wishlist/email/items.phtml
index a5e1dd2..7d02f5f 100644
--- app/design/frontend/base/default/template/wishlist/email/items.phtml
+++ app/design/frontend/base/default/template/wishlist/email/items.phtml
@@ -38,7 +38,7 @@
             <p align="center" style="font-size:12px;"><a href="<?php echo $this->getProductUrl($_product) ?>" style="color:#203548;"><strong><?php echo $this->escapeHtml($_product->getName()) ?></strong></a></p>
             <?php if($this->hasDescription($item)): ?><p align="center" style="font-size:12px;"><?php echo $this->__('Comment') ?>:<br /><?php echo $this->getEscapedDescription($item) ?></p><?php endif; ?>
             <p align="center" style="font-size:12px;"><a href="<?php echo $this->getProductUrl($_product) ?>" style="color:#1E7EC8;"><?php echo $this->__('View Product') ?></a> <small>
-            <?php if ($_product->getIsSalable()): ?>|</small> <a href="<?php echo $this->getAddToCartUrl($_product) ?>" style="color:#1E7EC8;"><strong><?php echo $this->__('Add to Cart') ?></strong></a><?php endif;?>
+            <?php if ($_product->getIsSalable()): ?>|</small> <a href="<?php echo $this->_getHelper()->getSharedAddToCartUrl($item) ?>" style="color:#1E7EC8;"><strong><?php echo $this->__('Add to Cart') ?></strong></a><?php endif;?>
             </p></td>
         <?php if ($i%3!=0): ?>
             <td width="2%"></td>
