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


SUPEE-6285 | CE_1.9.1.1 | v1 | 7226d88b1eeb07a5fbc4e62be189a5219457cc14 | Mon Jun 22 16:32:26 2015 +0300 | 202596e441..7226d88b1e

__PATCHFILE_FOLLOWS__
diff --git app/Mage.php app/Mage.php
index cb7dc15..7259b5d 100644
--- app/Mage.php
+++ app/Mage.php
@@ -814,12 +814,12 @@ final class Mage
 
                 if (!is_dir($logDir)) {
                     mkdir($logDir);
-                    chmod($logDir, 0777);
+                    chmod($logDir, 0750);
                 }
 
                 if (!file_exists($logFile)) {
                     file_put_contents($logFile, '');
-                    chmod($logFile, 0777);
+                    chmod($logFile, 0640);
                 }
 
                 $format = '%timestamp% %priorityName% (%priority%): %message%' . PHP_EOL;
diff --git app/code/community/Phoenix/Moneybookers/controllers/MoneybookersController.php app/code/community/Phoenix/Moneybookers/controllers/MoneybookersController.php
index 9be7941..74851ce 100644
--- app/code/community/Phoenix/Moneybookers/controllers/MoneybookersController.php
+++ app/code/community/Phoenix/Moneybookers/controllers/MoneybookersController.php
@@ -84,4 +84,14 @@ class Phoenix_Moneybookers_MoneybookersController extends Mage_Adminhtml_Control
         }
         $this->getResponse()->setBody($response);
     }
+
+    /**
+     * Check is allowed access to action
+     *
+     * @return bool
+     */
+    protected function _isAllowed()
+    {
+        return Mage::getSingleton('admin/session')->isAllowed('system/config/moneybookers');
+    }
 }
diff --git app/code/core/Mage/Adminhtml/Controller/Action.php app/code/core/Mage/Adminhtml/Controller/Action.php
index f7f7c06..f93647e 100644
--- app/code/core/Mage/Adminhtml/Controller/Action.php
+++ app/code/core/Mage/Adminhtml/Controller/Action.php
@@ -71,7 +71,7 @@ class Mage_Adminhtml_Controller_Action extends Mage_Core_Controller_Varien_Actio
 
     protected function _isAllowed()
     {
-        return true;
+        return Mage::getSingleton('admin/session')->isAllowed('admin');
     }
 
     /**
diff --git app/code/core/Mage/Adminhtml/controllers/AjaxController.php app/code/core/Mage/Adminhtml/controllers/AjaxController.php
index e88ffa9..d873280 100644
--- app/code/core/Mage/Adminhtml/controllers/AjaxController.php
+++ app/code/core/Mage/Adminhtml/controllers/AjaxController.php
@@ -52,4 +52,14 @@ class Mage_Adminhtml_AjaxController extends Mage_Adminhtml_Controller_Action
         echo Mage::helper('core/translate')->apply($translation, $area);
         exit();
     }
+
+    /**
+     * Check is allowed access to action
+     *
+     * @return bool
+     */
+    protected function _isAllowed()
+    {
+        return true;
+    }
 }
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/Category/WidgetController.php app/code/core/Mage/Adminhtml/controllers/Catalog/Category/WidgetController.php
index 27bc182..d2ba246 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/Category/WidgetController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/Category/WidgetController.php
@@ -69,4 +69,14 @@ class Mage_Adminhtml_Catalog_Category_WidgetController extends Mage_Adminhtml_Co
             'use_massaction' => $this->getRequest()->getParam('use_massaction', false)
         ));
     }
+
+    /**
+     * Check is allowed access to action
+     *
+     * @return bool
+     */
+    protected function _isAllowed()
+    {
+        return Mage::getSingleton('admin/session')->isAllowed('cms/widget_instance');
+    }
 }
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/Product/DatafeedsController.php app/code/core/Mage/Adminhtml/controllers/Catalog/Product/DatafeedsController.php
index f9a5dae..eda7b6d 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/Product/DatafeedsController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/Product/DatafeedsController.php
@@ -32,4 +32,14 @@ class Mage_Adminhtml_Catalog_DatafeedsController extends Mage_Adminhtml_Controll
     {
         
     }
+
+    /**
+     * Check is allowed access to action
+     *
+     * @return bool
+     */
+    protected function _isAllowed()
+    {
+        return true;
+    }
 }
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/Product/ReviewController.php app/code/core/Mage/Adminhtml/controllers/Catalog/Product/ReviewController.php
index de11c2d..e28f486 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/Product/ReviewController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/Product/ReviewController.php
@@ -367,7 +367,8 @@ class Mage_Adminhtml_Catalog_Product_ReviewController extends Mage_Adminhtml_Con
 
     protected function _isAllowed()
     {
-        switch ($this->getRequest()->getActionName()) {
+        $action = strtolower($this->getRequest()->getActionName());
+        switch ($action) {
             case 'pending':
                 return Mage::getSingleton('admin/session')->isAllowed('catalog/reviews_ratings/reviews/pending');
                 break;
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/Product/WidgetController.php app/code/core/Mage/Adminhtml/controllers/Catalog/Product/WidgetController.php
index 9436d3e..d2efadb 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/Product/WidgetController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/Product/WidgetController.php
@@ -67,4 +67,14 @@ class Mage_Adminhtml_Catalog_Product_WidgetController extends Mage_Adminhtml_Con
 
         $this->getResponse()->setBody($html);
     }
+
+    /**
+     * Check is allowed access to action
+     *
+     * @return bool
+     */
+    protected function _isAllowed()
+    {
+        return Mage::getSingleton('admin/session')->isAllowed('cms/widget_instance');
+    }
 }
diff --git app/code/core/Mage/Adminhtml/controllers/Cms/Block/WidgetController.php app/code/core/Mage/Adminhtml/controllers/Cms/Block/WidgetController.php
index 6686c26..7d45c10 100644
--- app/code/core/Mage/Adminhtml/controllers/Cms/Block/WidgetController.php
+++ app/code/core/Mage/Adminhtml/controllers/Cms/Block/WidgetController.php
@@ -45,4 +45,14 @@ class Mage_Adminhtml_Cms_Block_WidgetController extends Mage_Adminhtml_Controlle
         ));
         $this->getResponse()->setBody($pagesGrid->toHtml());
     }
+
+    /**
+     * Check is allowed access to action
+     *
+     * @return bool
+     */
+    protected function _isAllowed()
+    {
+        return Mage::getSingleton('admin/session')->isAllowed('cms/widget_instance');
+    }
 }
diff --git app/code/core/Mage/Adminhtml/controllers/Cms/Page/WidgetController.php app/code/core/Mage/Adminhtml/controllers/Cms/Page/WidgetController.php
index e6207c6..b217fa8 100644
--- app/code/core/Mage/Adminhtml/controllers/Cms/Page/WidgetController.php
+++ app/code/core/Mage/Adminhtml/controllers/Cms/Page/WidgetController.php
@@ -45,4 +45,15 @@ class Mage_Adminhtml_Cms_Page_WidgetController extends Mage_Adminhtml_Controller
         ));
         $this->getResponse()->setBody($pagesGrid->toHtml());
     }
+
+    /**
+     * Check is allowed access to action
+     *
+     * @return bool
+     */
+    protected function _isAllowed()
+    {
+        return Mage::getSingleton('admin/session')->isAllowed('cms/widget_instance');
+    }
+
 }
diff --git app/code/core/Mage/Adminhtml/controllers/Cms/PageController.php app/code/core/Mage/Adminhtml/controllers/Cms/PageController.php
index b747672..7ff9ec2 100644
--- app/code/core/Mage/Adminhtml/controllers/Cms/PageController.php
+++ app/code/core/Mage/Adminhtml/controllers/Cms/PageController.php
@@ -222,7 +222,8 @@ class Mage_Adminhtml_Cms_PageController extends Mage_Adminhtml_Controller_Action
      */
     protected function _isAllowed()
     {
-        switch ($this->getRequest()->getActionName()) {
+        $action = strtolower($this->getRequest()->getActionName());
+        switch ($action) {
             case 'new':
             case 'save':
                 return Mage::getSingleton('admin/session')->isAllowed('cms/page/save');
diff --git app/code/core/Mage/Adminhtml/controllers/Cms/WysiwygController.php app/code/core/Mage/Adminhtml/controllers/Cms/WysiwygController.php
index 8df9ee5..d18005a 100644
--- app/code/core/Mage/Adminhtml/controllers/Cms/WysiwygController.php
+++ app/code/core/Mage/Adminhtml/controllers/Cms/WysiwygController.php
@@ -63,4 +63,14 @@ class Mage_Adminhtml_Cms_WysiwygController extends Mage_Adminhtml_Controller_Act
             */
         }
     }
+
+    /**
+     * Check the permission to run it
+     *
+     * @return boolean
+     */
+    protected function _isAllowed()
+    {
+        return Mage::getSingleton('admin/session')->isAllowed('cms');
+    }
 }
diff --git app/code/core/Mage/Adminhtml/controllers/Customer/System/Config/ValidatevatController.php app/code/core/Mage/Adminhtml/controllers/Customer/System/Config/ValidatevatController.php
index b36dfe6..a51d484 100644
--- app/code/core/Mage/Adminhtml/controllers/Customer/System/Config/ValidatevatController.php
+++ app/code/core/Mage/Adminhtml/controllers/Customer/System/Config/ValidatevatController.php
@@ -88,4 +88,14 @@ class Mage_Adminhtml_Customer_System_Config_ValidatevatController extends Mage_A
         ));
         $this->getResponse()->setBody($body);
     }
+
+    /**
+     * Check is allowed access to action
+     *
+     * @return bool
+     */
+    protected function _isAllowed()
+    {
+        return Mage::getSingleton('admin/session')->isAllowed('system/config');
+    }
 }
diff --git app/code/core/Mage/Adminhtml/controllers/JsonController.php app/code/core/Mage/Adminhtml/controllers/JsonController.php
index 299d887..26b37f8 100644
--- app/code/core/Mage/Adminhtml/controllers/JsonController.php
+++ app/code/core/Mage/Adminhtml/controllers/JsonController.php
@@ -56,4 +56,14 @@ class Mage_Adminhtml_JsonController extends Mage_Adminhtml_Controller_Action
 
         $this->getResponse()->setBody(Mage::helper('core')->jsonEncode($arrRes));
     }
+
+    /**
+     * Check is allowed access to action
+     *
+     * @return bool
+     */
+    protected function _isAllowed()
+    {
+        return true;
+    }
 }
diff --git app/code/core/Mage/Adminhtml/controllers/NotificationController.php app/code/core/Mage/Adminhtml/controllers/NotificationController.php
index 590799f..ec9bb5c 100644
--- app/code/core/Mage/Adminhtml/controllers/NotificationController.php
+++ app/code/core/Mage/Adminhtml/controllers/NotificationController.php
@@ -160,12 +160,13 @@ class Mage_Adminhtml_NotificationController extends Mage_Adminhtml_Controller_Ac
 
     protected function _isAllowed()
     {
-        switch ($this->getRequest()->getActionName()) {
-            case 'markAsRead':
+        $action = strtolower($this->getRequest()->getActionName());
+        switch ($action) {
+            case 'markasread':
                 $acl = 'system/adminnotification/mark_as_read';
                 break;
 
-            case 'massMarkAsRead':
+            case 'massmarkasread':
                 $acl = 'system/adminnotification/mark_as_read';
                 break;
 
@@ -173,7 +174,7 @@ class Mage_Adminhtml_NotificationController extends Mage_Adminhtml_Controller_Ac
                 $acl = 'system/adminnotification/remove';
                 break;
 
-            case 'massRemove':
+            case 'massremove':
                 $acl = 'system/adminnotification/remove';
                 break;
 
diff --git app/code/core/Mage/Adminhtml/controllers/Report/CustomerController.php app/code/core/Mage/Adminhtml/controllers/Report/CustomerController.php
index 8f075d5..07b154b 100644
--- app/code/core/Mage/Adminhtml/controllers/Report/CustomerController.php
+++ app/code/core/Mage/Adminhtml/controllers/Report/CustomerController.php
@@ -161,7 +161,8 @@ class Mage_Adminhtml_Report_CustomerController extends Mage_Adminhtml_Controller
 
     protected function _isAllowed()
     {
-        switch ($this->getRequest()->getActionName()) {
+        $action = strtolower($this->getRequest()->getActionName());
+        switch ($action) {
             case 'accounts':
                 return Mage::getSingleton('admin/session')->isAllowed('report/customers/accounts');
                 break;
diff --git app/code/core/Mage/Adminhtml/controllers/Report/ProductController.php app/code/core/Mage/Adminhtml/controllers/Report/ProductController.php
index 4ba8a6c..516b68c 100644
--- app/code/core/Mage/Adminhtml/controllers/Report/ProductController.php
+++ app/code/core/Mage/Adminhtml/controllers/Report/ProductController.php
@@ -267,7 +267,8 @@ class Mage_Adminhtml_Report_ProductController extends Mage_Adminhtml_Controller_
      */
     protected function _isAllowed()
     {
-        switch ($this->getRequest()->getActionName()) {
+        $action = strtolower($this->getRequest()->getActionName());
+        switch ($action) {
             case 'viewed':
                 return Mage::getSingleton('admin/session')->isAllowed('report/products/viewed');
                 break;
diff --git app/code/core/Mage/Adminhtml/controllers/Report/ReviewController.php app/code/core/Mage/Adminhtml/controllers/Report/ReviewController.php
index 2c3c93c..3e80579 100644
--- app/code/core/Mage/Adminhtml/controllers/Report/ReviewController.php
+++ app/code/core/Mage/Adminhtml/controllers/Report/ReviewController.php
@@ -160,7 +160,8 @@ class Mage_Adminhtml_Report_ReviewController extends Mage_Adminhtml_Controller_A
 
     protected function _isAllowed()
     {
-        switch ($this->getRequest()->getActionName()) {
+        $action = strtolower($this->getRequest()->getActionName());
+        switch ($action) {
             case 'customer':
                 return Mage::getSingleton('admin/session')->isAllowed('report/review/customer');
                 break;
diff --git app/code/core/Mage/Adminhtml/controllers/Report/SalesController.php app/code/core/Mage/Adminhtml/controllers/Report/SalesController.php
index aa943b2..0a2a05d 100644
--- app/code/core/Mage/Adminhtml/controllers/Report/SalesController.php
+++ app/code/core/Mage/Adminhtml/controllers/Report/SalesController.php
@@ -389,7 +389,8 @@ class Mage_Adminhtml_Report_SalesController extends Mage_Adminhtml_Controller_Re
 
     protected function _isAllowed()
     {
-        switch ($this->getRequest()->getActionName()) {
+        $action = strtolower($this->getRequest()->getActionName());
+        switch ($action) {
             case 'sales':
                 return $this->_getSession()->isAllowed('report/salesroot/sales');
                 break;
diff --git app/code/core/Mage/Adminhtml/controllers/Report/ShopcartController.php app/code/core/Mage/Adminhtml/controllers/Report/ShopcartController.php
index cc33908..f7468e2 100644
--- app/code/core/Mage/Adminhtml/controllers/Report/ShopcartController.php
+++ app/code/core/Mage/Adminhtml/controllers/Report/ShopcartController.php
@@ -155,7 +155,8 @@ class Mage_Adminhtml_Report_ShopcartController extends Mage_Adminhtml_Controller
 
     protected function _isAllowed()
     {
-        switch ($this->getRequest()->getActionName()) {
+        $action = strtolower($this->getRequest()->getActionName());
+        switch ($action) {
             case 'customer':
                 return Mage::getSingleton('admin/session')->isAllowed('report/shopcart/customer');
                 break;
diff --git app/code/core/Mage/Adminhtml/controllers/Report/TagController.php app/code/core/Mage/Adminhtml/controllers/Report/TagController.php
index cb97f61..88e75c0 100644
--- app/code/core/Mage/Adminhtml/controllers/Report/TagController.php
+++ app/code/core/Mage/Adminhtml/controllers/Report/TagController.php
@@ -282,14 +282,15 @@ class Mage_Adminhtml_Report_TagController extends Mage_Adminhtml_Controller_Acti
 
     protected function _isAllowed()
     {
-        switch ($this->getRequest()->getActionName()) {
+        $action = strtolower($this->getRequest()->getActionName());
+        switch ($action) {
             case 'customer':
                 return Mage::getSingleton('admin/session')->isAllowed('report/tags/customer');
                 break;
             case 'product':
                 return Mage::getSingleton('admin/session')->isAllowed('report/tags/product');
                 break;
-            case 'productAll':
+            case 'productall':
                 return Mage::getSingleton('admin/session')->isAllowed('report/tags/product');
                 break;
             case 'popular':
diff --git app/code/core/Mage/Adminhtml/controllers/ReportController.php app/code/core/Mage/Adminhtml/controllers/ReportController.php
index 8c11841..c29d4ad 100644
--- app/code/core/Mage/Adminhtml/controllers/ReportController.php
+++ app/code/core/Mage/Adminhtml/controllers/ReportController.php
@@ -131,7 +131,8 @@ class Mage_Adminhtml_ReportController extends Mage_Adminhtml_Controller_Action
 
     protected function _isAllowed()
     {
-        switch ($this->getRequest()->getActionName()) {
+        $action = strtolower($this->getRequest()->getActionName());
+        switch ($action) {
             case 'search':
                 return Mage::getSingleton('admin/session')->isAllowed('report/search');
                 break;
diff --git app/code/core/Mage/Adminhtml/controllers/Rss/CatalogController.php app/code/core/Mage/Adminhtml/controllers/Rss/CatalogController.php
index 95484fd..df78cd4 100644
--- app/code/core/Mage/Adminhtml/controllers/Rss/CatalogController.php
+++ app/code/core/Mage/Adminhtml/controllers/Rss/CatalogController.php
@@ -34,17 +34,21 @@
 
 class Mage_Adminhtml_Rss_CatalogController extends Mage_Adminhtml_Controller_Action
 {
-    public function preDispatch()
+    /**
+     * Check is allowed access to action
+     *
+     * @return bool
+     */
+    protected function _isAllowed()
     {
         $path = '';
-        if ($this->getRequest()->getActionName() == 'review') {
+        $action = strtolower($this->getRequest()->getActionName());
+        if ($action == 'review') {
             $path = 'catalog/reviews_ratings';
-        } elseif ($this->getRequest()->getActionName() == 'notifystock') {
+        } elseif ($action == 'notifystock') {
             $path = 'catalog/products';
         }
-        Mage::helper('adminhtml/rss')->authAdmin($path);
-        parent::preDispatch();
-        return $this;
+        return Mage::getSingleton('admin/session')->isAllowed($path);
     }
 
     public function notifystockAction()
diff --git app/code/core/Mage/Adminhtml/controllers/Rss/OrderController.php app/code/core/Mage/Adminhtml/controllers/Rss/OrderController.php
index 5fa3a59..b199df1 100644
--- app/code/core/Mage/Adminhtml/controllers/Rss/OrderController.php
+++ app/code/core/Mage/Adminhtml/controllers/Rss/OrderController.php
@@ -34,12 +34,6 @@
 
 class Mage_Adminhtml_Rss_OrderController extends Mage_Adminhtml_Controller_Action
 {
-    public function preDispatch()
-    {
-        Mage::helper('adminhtml/rss')->authAdmin('catalog/reviews_ratings');
-        parent::preDispatch();
-        return $this;
-    }
 
     public function newAction()
     {
@@ -48,4 +42,14 @@ class Mage_Adminhtml_Rss_OrderController extends Mage_Adminhtml_Controller_Actio
         $this->loadLayout(false);
         $this->renderLayout();
     }
+
+    /**
+     * Check is allowed access to action
+     *
+     * @return bool
+     */
+    protected function _isAllowed()
+    {
+        return Mage::getSingleton('admin/session')->isAllowed('sales/order/actions/view');
+    }
 }
diff --git app/code/core/Mage/Adminhtml/controllers/Sales/Billing/AgreementController.php app/code/core/Mage/Adminhtml/controllers/Sales/Billing/AgreementController.php
index 17305f1..9d0e9c6 100644
--- app/code/core/Mage/Adminhtml/controllers/Sales/Billing/AgreementController.php
+++ app/code/core/Mage/Adminhtml/controllers/Sales/Billing/AgreementController.php
@@ -203,7 +203,8 @@ class Mage_Adminhtml_Sales_Billing_AgreementController extends Mage_Adminhtml_Co
      */
     protected function _isAllowed()
     {
-        switch ($this->getRequest()->getActionName()) {
+        $action = strtolower($this->getRequest()->getActionName());
+        switch ($action) {
             case 'index':
             case 'grid' :
             case 'view' :
diff --git app/code/core/Mage/Adminhtml/controllers/Sales/Order/View/GiftmessageController.php app/code/core/Mage/Adminhtml/controllers/Sales/Order/View/GiftmessageController.php
index 313ac8d..6120ecb 100644
--- app/code/core/Mage/Adminhtml/controllers/Sales/Order/View/GiftmessageController.php
+++ app/code/core/Mage/Adminhtml/controllers/Sales/Order/View/GiftmessageController.php
@@ -76,4 +76,14 @@ class Mage_Adminhtml_Sales_Order_View_GiftmessageController extends Mage_Adminht
         return Mage::getSingleton('adminhtml/giftmessage_save');
     }
 
+    /**
+     * Acl check for admin
+     *
+     * @return bool
+     */
+    protected function _isAllowed()
+    {
+        return Mage::getSingleton('admin/session')->isAllowed('sales/order');
+    }
+
 }
diff --git app/code/core/Mage/Adminhtml/controllers/Sales/Recurring/ProfileController.php app/code/core/Mage/Adminhtml/controllers/Sales/Recurring/ProfileController.php
index 57a8b19..4d42ad8 100644
--- app/code/core/Mage/Adminhtml/controllers/Sales/Recurring/ProfileController.php
+++ app/code/core/Mage/Adminhtml/controllers/Sales/Recurring/ProfileController.php
@@ -202,4 +202,14 @@ class Mage_Adminhtml_Sales_Recurring_ProfileController extends Mage_Adminhtml_Co
         Mage::register('current_recurring_profile', $profile);
         return $profile;
     }
+
+    /**
+     * Check is allowed access to action
+     *
+     * @return bool
+     */
+    protected function _isAllowed()
+    {
+        return Mage::getSingleton('admin/session')->isAllowed('sales/recurring_profile');
+    }
 }
diff --git app/code/core/Mage/Adminhtml/controllers/Sales/TransactionsController.php app/code/core/Mage/Adminhtml/controllers/Sales/TransactionsController.php
index e932f03..cd5c0c6 100644
--- app/code/core/Mage/Adminhtml/controllers/Sales/TransactionsController.php
+++ app/code/core/Mage/Adminhtml/controllers/Sales/TransactionsController.php
@@ -130,7 +130,8 @@ class Mage_Adminhtml_Sales_TransactionsController extends Mage_Adminhtml_Control
      */
     protected function _isAllowed()
     {
-        switch ($this->getRequest()->getActionName()) {
+        $action = strtolower($this->getRequest()->getActionName());
+        switch ($action) {
             case 'fetch':
                 return Mage::getSingleton('admin/session')->isAllowed('sales/transactions/fetch');
                 break;
diff --git app/code/core/Mage/Adminhtml/controllers/System/Config/System/StorageController.php app/code/core/Mage/Adminhtml/controllers/System/Config/System/StorageController.php
index eb47712..499d34a 100644
--- app/code/core/Mage/Adminhtml/controllers/System/Config/System/StorageController.php
+++ app/code/core/Mage/Adminhtml/controllers/System/Config/System/StorageController.php
@@ -180,4 +180,14 @@ class Mage_Adminhtml_System_Config_System_StorageController extends Mage_Adminht
         $result = Mage::helper('core')->jsonEncode($result);
         Mage::app()->getResponse()->setBody($result);
     }
+
+    /**
+     * Check is allowed access to action
+     *
+     * @return bool
+     */
+    protected function _isAllowed()
+    {
+        return Mage::getSingleton('admin/session')->isAllowed('system/config');
+    }
 }
diff --git app/code/core/Mage/Adminhtml/controllers/TagController.php app/code/core/Mage/Adminhtml/controllers/TagController.php
index d5410d1..a1422d5 100644
--- app/code/core/Mage/Adminhtml/controllers/TagController.php
+++ app/code/core/Mage/Adminhtml/controllers/TagController.php
@@ -345,7 +345,8 @@ class Mage_Adminhtml_TagController extends Mage_Adminhtml_Controller_Action
      */
     protected function _isAllowed()
     {
-        switch ($this->getRequest()->getActionName()) {
+        $action = strtolower($this->getRequest()->getActionName());
+        switch ($action) {
             case 'pending':
                 return Mage::getSingleton('admin/session')->isAllowed('catalog/tag/pending');
                 break;
diff --git app/code/core/Mage/Adminhtml/controllers/Tax/RateController.php app/code/core/Mage/Adminhtml/controllers/Tax/RateController.php
index b9ae1fa..c7e6d3a 100644
--- app/code/core/Mage/Adminhtml/controllers/Tax/RateController.php
+++ app/code/core/Mage/Adminhtml/controllers/Tax/RateController.php
@@ -466,8 +466,9 @@ class Mage_Adminhtml_Tax_RateController extends Mage_Adminhtml_Controller_Action
     protected function _isAllowed()
     {
 
-        switch ($this->getRequest()->getActionName()) {
-            case 'importExport':
+        $action = strtolower($this->getRequest()->getActionName());
+        switch ($action) {
+            case 'importexport':
                 return Mage::getSingleton('admin/session')->isAllowed('sales/tax/import_export');
                 break;
             case 'index':
diff --git app/code/core/Mage/Adminhtml/controllers/TaxController.php app/code/core/Mage/Adminhtml/controllers/TaxController.php
index b5fcba2..c52dd71 100644
--- app/code/core/Mage/Adminhtml/controllers/TaxController.php
+++ app/code/core/Mage/Adminhtml/controllers/TaxController.php
@@ -50,4 +50,14 @@ class Mage_Adminhtml_TaxController extends Mage_Adminhtml_Controller_Action
         }
         $this->_redirectReferer();
     }
+
+    /**
+     * Check is allowed access to action
+     *
+     * @return bool
+     */
+    protected function _isAllowed()
+    {
+        return true;
+    }
 }
diff --git app/code/core/Mage/Api2/controllers/Adminhtml/Api2/AttributeController.php app/code/core/Mage/Api2/controllers/Adminhtml/Api2/AttributeController.php
index c349204..465b967 100644
--- app/code/core/Mage/Api2/controllers/Adminhtml/Api2/AttributeController.php
+++ app/code/core/Mage/Api2/controllers/Adminhtml/Api2/AttributeController.php
@@ -145,4 +145,14 @@ class Mage_Api2_Adminhtml_Api2_AttributeController extends Mage_Adminhtml_Contro
 
         $this->_redirect('*/*/edit', array('type' => $type));
     }
+
+    /**
+     * Check is allowed access to action
+     *
+     * @return bool
+     */
+    protected function _isAllowed()
+    {
+        return Mage::getSingleton('admin/session')->isAllowed('system/api');
+    }
 }
diff --git app/code/core/Mage/Bundle/controllers/Adminhtml/Bundle/SelectionController.php app/code/core/Mage/Bundle/controllers/Adminhtml/Bundle/SelectionController.php
index 1fd554e..363288c 100644
--- app/code/core/Mage/Bundle/controllers/Adminhtml/Bundle/SelectionController.php
+++ app/code/core/Mage/Bundle/controllers/Adminhtml/Bundle/SelectionController.php
@@ -59,5 +59,13 @@ class Mage_Bundle_Adminhtml_Bundle_SelectionController extends Mage_Adminhtml_Co
                 ->toHtml()
            );
     }
-
+    /**
+     * Check for is allowed
+     *
+     * @return boolean
+     */
+    protected function _isAllowed()
+    {
+        return Mage::getSingleton('admin/session')->isAllowed('catalog/products');
+    }
 }
diff --git app/code/core/Mage/Captcha/controllers/Adminhtml/RefreshController.php app/code/core/Mage/Captcha/controllers/Adminhtml/RefreshController.php
index bd7becc..653d2a8 100644
--- app/code/core/Mage/Captcha/controllers/Adminhtml/RefreshController.php
+++ app/code/core/Mage/Captcha/controllers/Adminhtml/RefreshController.php
@@ -47,4 +47,14 @@ class Mage_Captcha_Adminhtml_RefreshController extends Mage_Adminhtml_Controller
         $this->getResponse()->setBody(json_encode(array('imgSrc' => $captchaModel->getImgSrc())));
         $this->setFlag('', self::FLAG_NO_POST_DISPATCH, true);
     }
+
+    /**
+     * Check is allowed access to action
+     *
+     * @return bool
+     */
+    protected function _isAllowed()
+    {
+        return true;
+    }
 }
diff --git app/code/core/Mage/Centinel/controllers/Adminhtml/Centinel/IndexController.php app/code/core/Mage/Centinel/controllers/Adminhtml/Centinel/IndexController.php
index c559676..a9131ab 100644
--- app/code/core/Mage/Centinel/controllers/Adminhtml/Centinel/IndexController.php
+++ app/code/core/Mage/Centinel/controllers/Adminhtml/Centinel/IndexController.php
@@ -116,5 +116,15 @@ class Mage_Centinel_Adminhtml_Centinel_IndexController extends Mage_Adminhtml_Co
         }
         return false;
     }
+
+    /**
+     * Check is allowed access to action
+     *
+     * @return bool
+     */
+    protected function _isAllowed()
+    {
+        return Mage::getSingleton('admin/session')->isAllowed('sales/order/actions/review_payment');
+    }
 }
 
diff --git app/code/core/Mage/Checkout/controllers/MultishippingController.php app/code/core/Mage/Checkout/controllers/MultishippingController.php
index 51b7b59..096bb67 100644
--- app/code/core/Mage/Checkout/controllers/MultishippingController.php
+++ app/code/core/Mage/Checkout/controllers/MultishippingController.php
@@ -86,7 +86,7 @@ class Mage_Checkout_MultishippingController extends Mage_Checkout_Controller_Act
             return $this;
         }
 
-        $action = $this->getRequest()->getActionName();
+        $action = strtolower($this->getRequest()->getActionName());
 
         $checkoutSessionQuote = $this->_getCheckoutSession()->getQuote();
         /**
diff --git app/code/core/Mage/Connect/controllers/Adminhtml/Extension/LocalController.php app/code/core/Mage/Connect/controllers/Adminhtml/Extension/LocalController.php
index 6dd58a1..d181b20 100644
--- app/code/core/Mage/Connect/controllers/Adminhtml/Extension/LocalController.php
+++ app/code/core/Mage/Connect/controllers/Adminhtml/Extension/LocalController.php
@@ -42,4 +42,14 @@ class Mage_Connect_Adminhtml_Extension_LocalController extends Mage_Adminhtml_Co
         $url = Mage::getBaseUrl('web') . 'downloader/?return=' . urlencode(Mage::getUrl('adminhtml'));
         $this->getResponse()->setRedirect($url);
     }
+
+    /**
+     * Check is allowed access to action
+     *
+     * @return bool
+     */
+    protected function _isAllowed()
+    {
+        return Mage::getSingleton('admin/session')->isAllowed('system/extensions/local');
+    }
 }
diff --git app/code/core/Mage/ImportExport/Model/Abstract.php app/code/core/Mage/ImportExport/Model/Abstract.php
index 45c54d9..5fb7aa3 100644
--- app/code/core/Mage/ImportExport/Model/Abstract.php
+++ app/code/core/Mage/ImportExport/Model/Abstract.php
@@ -95,7 +95,7 @@ abstract class Mage_ImportExport_Model_Abstract extends Varien_Object
             $dirPath = Mage::getBaseDir('var') . DS . self::LOG_DIRECTORY
                 . $dirName;
             if (!is_dir($dirPath)) {
-                mkdir($dirPath, 0777, true);
+                mkdir($dirPath, 0750, true);
             }
             $fileName = substr(strstr(self::LOG_DIRECTORY, DS), 1)
                 . $dirName . $fileName . '.log';
diff --git app/code/core/Mage/Oauth/controllers/Adminhtml/Oauth/AuthorizeController.php app/code/core/Mage/Oauth/controllers/Adminhtml/Oauth/AuthorizeController.php
index 3cdb57d..cba4796 100644
--- app/code/core/Mage/Oauth/controllers/Adminhtml/Oauth/AuthorizeController.php
+++ app/code/core/Mage/Oauth/controllers/Adminhtml/Oauth/AuthorizeController.php
@@ -298,4 +298,14 @@ class Mage_Oauth_Adminhtml_Oauth_AuthorizeController extends Mage_Adminhtml_Cont
     {
         $this->_initRejectPage();
     }
+
+    /**
+     * Check admin permissions for this controller
+     *
+     * @return boolean
+     */
+    protected function _isAllowed()
+    {
+        return true;
+    }
 }
diff --git app/code/core/Mage/Paygate/controllers/Adminhtml/Paygate/Authorizenet/PaymentController.php app/code/core/Mage/Paygate/controllers/Adminhtml/Paygate/Authorizenet/PaymentController.php
index 20ec7bb..0c85db5 100644
--- app/code/core/Mage/Paygate/controllers/Adminhtml/Paygate/Authorizenet/PaymentController.php
+++ app/code/core/Mage/Paygate/controllers/Adminhtml/Paygate/Authorizenet/PaymentController.php
@@ -76,4 +76,14 @@ class Mage_Paygate_Adminhtml_Paygate_Authorizenet_PaymentController extends Mage
         $output = $layout->getOutput();
         return $output;
     }
+
+    /**
+     * Check is allowed access to action
+     *
+     * @return bool
+     */
+    protected function _isAllowed()
+    {
+        return Mage::getSingleton('admin/session')->isAllowed('sales/order/actions/review_payment');
+    }
 }
diff --git app/code/core/Mage/Paypal/controllers/Adminhtml/Paypal/ReportsController.php app/code/core/Mage/Paypal/controllers/Adminhtml/Paypal/ReportsController.php
index 9dc6b46..21abf02 100644
--- app/code/core/Mage/Paypal/controllers/Adminhtml/Paypal/ReportsController.php
+++ app/code/core/Mage/Paypal/controllers/Adminhtml/Paypal/ReportsController.php
@@ -127,7 +127,8 @@ class Mage_Paypal_Adminhtml_Paypal_ReportsController extends Mage_Adminhtml_Cont
      */
     protected function _isAllowed()
     {
-        switch ($this->getRequest()->getActionName()) {
+        $action = strtolower($this->getRequest()->getActionName());
+        switch ($action) {
             case 'index':
             case 'details':
                 return Mage::getSingleton('admin/session')->isAllowed('report/salesroot/paypal_settlement_reports/view');
diff --git app/code/core/Mage/Rss/controllers/CatalogController.php app/code/core/Mage/Rss/controllers/CatalogController.php
index f32b9a6..48d6c80 100644
--- app/code/core/Mage/Rss/controllers/CatalogController.php
+++ app/code/core/Mage/Rss/controllers/CatalogController.php
@@ -118,11 +118,12 @@ class Mage_Rss_CatalogController extends Mage_Core_Controller_Front_Action
      */
     public function preDispatch()
     {
-        if ($this->getRequest()->getActionName() == 'notifystock') {
+        $action = strtolower($this->getRequest()->getActionName());
+        if ($action == 'notifystock') {
             $this->_currentArea = 'adminhtml';
             Mage::helper('rss')->authAdmin('catalog/products');
         }
-        if ($this->getRequest()->getActionName() == 'review') {
+        if ($action == 'review') {
             $this->_currentArea = 'adminhtml';
             Mage::helper('rss')->authAdmin('catalog/reviews_ratings');
         }
diff --git app/code/core/Mage/Rss/controllers/OrderController.php app/code/core/Mage/Rss/controllers/OrderController.php
index be76acb..559f3a5 100644
--- app/code/core/Mage/Rss/controllers/OrderController.php
+++ app/code/core/Mage/Rss/controllers/OrderController.php
@@ -75,7 +75,8 @@ class Mage_Rss_OrderController extends Mage_Core_Controller_Front_Action
      */
     public function preDispatch()
     {
-        if ($this->getRequest()->getActionName() == 'new') {
+        $action = strtolower($this->getRequest()->getActionName());
+        if ($action == 'new') {
             $this->_currentArea = 'adminhtml';
             Mage::helper('rss')->authAdmin('sales/order');
         }
diff --git app/code/core/Mage/Widget/Block/Adminhtml/Widget/Chooser.php app/code/core/Mage/Widget/Block/Adminhtml/Widget/Chooser.php
index b1d2363..0664070 100644
--- app/code/core/Mage/Widget/Block/Adminhtml/Widget/Chooser.php
+++ app/code/core/Mage/Widget/Block/Adminhtml/Widget/Chooser.php
@@ -178,7 +178,8 @@ class Mage_Widget_Block_Adminhtml_Widget_Chooser extends Mage_Adminhtml_Block_Te
         $configJson = Mage::helper('core')->jsonEncode($config->getData());
         return '
             <label class="widget-option-label" id="' . $chooserId . 'label">'
-            . ($this->getLabel() ? $this->getLabel() : Mage::helper('widget')->__('Not Selected')) . '</label>
+            . $this->quoteEscape($this->getLabel() ? $this->getLabel() : Mage::helper('widget')->__('Not Selected'))
+            . '</label>
             <div id="' . $chooserId . 'advice-container" class="hidden"></div>
             <script type="text/javascript">//<![CDATA[
                 (function() {
diff --git app/code/core/Mage/Widget/controllers/Adminhtml/WidgetController.php app/code/core/Mage/Widget/controllers/Adminhtml/WidgetController.php
index 6af435a..0d14e0a 100644
--- app/code/core/Mage/Widget/controllers/Adminhtml/WidgetController.php
+++ app/code/core/Mage/Widget/controllers/Adminhtml/WidgetController.php
@@ -84,4 +84,14 @@ class Mage_Widget_Adminhtml_WidgetController extends Mage_Adminhtml_Controller_A
         $html = Mage::getSingleton('widget/widget')->getWidgetDeclaration($type, $params, $asIs);
         $this->getResponse()->setBody($html);
     }
+
+    /**
+     * Check is allowed access to action
+     *
+     * @return bool
+     */
+    protected function _isAllowed()
+    {
+        return Mage::getSingleton('admin/session')->isAllowed('cms/widget_instance');
+    }
 }
diff --git app/design/frontend/base/default/template/checkout/cart.phtml app/design/frontend/base/default/template/checkout/cart.phtml
index 9deb7a5..3fadd56 100644
--- app/design/frontend/base/default/template/checkout/cart.phtml
+++ app/design/frontend/base/default/template/checkout/cart.phtml
@@ -98,7 +98,7 @@
                     <tr>
                         <td colspan="50" class="a-right">
                             <?php if($this->getContinueShoppingUrl()): ?>
-                                <button type="button" title="<?php echo $this->__('Continue Shopping') ?>" class="button btn-continue" onclick="setLocation('<?php echo $this->getContinueShoppingUrl() ?>')"><span><span><?php echo $this->__('Continue Shopping') ?></span></span></button>
+                                <button type="button" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Continue Shopping')) ?>" class="button btn-continue" onclick="setLocation('<?php echo Mage::helper('core')->quoteEscape($this->getContinueShoppingUrl()) ?>')"><span><span><?php echo $this->__('Continue Shopping') ?></span></span></button>
                             <?php endif; ?>
                             <button type="submit" name="update_cart_action" value="update_qty" title="<?php echo $this->__('Update Shopping Cart'); ?>" class="button btn-update"><span><span><?php echo $this->__('Update Shopping Cart'); ?></span></span></button>
                             <button type="submit" name="update_cart_action" value="empty_cart" title="<?php echo $this->__('Clear Shopping Cart'); ?>" class="button btn-empty" id="empty_cart_button"><span><span><?php echo $this->__('Clear Shopping Cart'); ?></span></span></button>
diff --git app/design/frontend/base/default/template/checkout/cart/noItems.phtml app/design/frontend/base/default/template/checkout/cart/noItems.phtml
index 4a4d0e6..8031e41 100644
--- app/design/frontend/base/default/template/checkout/cart/noItems.phtml
+++ app/design/frontend/base/default/template/checkout/cart/noItems.phtml
@@ -31,6 +31,6 @@
     <?php echo $this->getMessagesBlock()->toHtml() ?>
     <?php echo $this->getChildHtml('checkout_cart_empty_widget'); ?>
     <p><?php echo $this->__('You have no items in your shopping cart.') ?></p>
-    <p><?php echo $this->__('Click <a href="%s">here</a> to continue shopping.', $this->getContinueShoppingUrl()) ?></p>
+    <p><?php echo $this->__('Click <a href="%s">here</a> to continue shopping.', Mage::helper('core')->quoteEscape($this->getContinueShoppingUrl())) ?></p>
     <?php echo $this->getChildHtml('shopping.cart.table.after'); ?>
 </div>
diff --git app/design/frontend/base/default/template/checkout/onepage/failure.phtml app/design/frontend/base/default/template/checkout/onepage/failure.phtml
index b4b7bc7..b84aef2 100644
--- app/design/frontend/base/default/template/checkout/onepage/failure.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/failure.phtml
@@ -29,4 +29,4 @@
 </div>
 <?php if ($this->getRealOrderId()) : ?><p><?php echo $this->__('Order #') . $this->getRealOrderId() ?></p><?php endif ?>
 <?php if ($error = $this->getErrorMessage()) : ?><p><?php echo $error ?></p><?php endif ?>
-<p><?php echo $this->__('Click <a href="%s">here</a> to continue shopping.', $this->getContinueShoppingUrl()) ?></p>
+<p><?php echo $this->__('Click <a href="%s">here</a> to continue shopping.', Mage::helper('core')->quoteEscape($this->getContinueShoppingUrl())) ?></p>
diff --git app/design/frontend/base/default/template/rss/order/details.phtml app/design/frontend/base/default/template/rss/order/details.phtml
index de0e9de..421689b 100644
--- app/design/frontend/base/default/template/rss/order/details.phtml
+++ app/design/frontend/base/default/template/rss/order/details.phtml
@@ -31,8 +31,9 @@ store name = $_order->getStore()->getGroup()->getName()
 ?>
 <?php $_order=$this->getOrder() ?>
 <div>
-<?php echo $this->__('Customer Name: %s', $_order->getCustomerFirstname()?$_order->getCustomerName():$_order->getBillingAddress()->getName()) ?><br />
-<?php echo $this->__('Purchased From: %s', $_order->getStore()->getGroup()->getName()) ?><br />
+<?php $customerName = $_order->getCustomerFirstname() ? $_order->getCustomerName() : $_order->getBillingAddress()->getName(); ?>
+<?php echo $this->__('Customer Name: %s', Mage::helper('core')->escapeHtml($customerName)) ?><br />
+<?php echo $this->__('Purchased From: %s', Mage::helper('core')->escapeHtml($_order->getStore()->getGroup()->getName())) ?><br />
 </div>
 <table cellspacing="0" cellpadding="0" border="0" width="100%" style="border:1px solid #bebcb7; background:#f8f7f5;">
     <thead>
diff --git app/design/frontend/base/default/template/wishlist/email/rss.phtml app/design/frontend/base/default/template/wishlist/email/rss.phtml
index f524d05..f869912 100644
--- app/design/frontend/base/default/template/wishlist/email/rss.phtml
+++ app/design/frontend/base/default/template/wishlist/email/rss.phtml
@@ -25,7 +25,7 @@
  */
 ?>
 <p style="font-size:12px; line-height:16px; margin:0 0 16px;">
-    <?php echo $this->__("RSS link to %s's wishlist",$this->helper('wishlist')->getCustomerName()) ?>
+    <?php echo $this->__("RSS link to %s's wishlist", Mage::helper('core')->escapeHtml($this->helper('wishlist')->getCustomerName())) ?>
     <br />
     <a href="<?php echo $this->helper('wishlist')->getRssUrl($this->getWishlistId()); ?>"><?php echo $this->helper('wishlist')->getRssUrl($this->getWishlistId()); ?></a>
 </p>
diff --git app/design/frontend/default/modern/template/checkout/cart.phtml app/design/frontend/default/modern/template/checkout/cart.phtml
index 43698c2..f4fe5ab 100644
--- app/design/frontend/default/modern/template/checkout/cart.phtml
+++ app/design/frontend/default/modern/template/checkout/cart.phtml
@@ -97,7 +97,7 @@
                     <tr>
                         <td colspan="50" class="a-right">
                             <?php if($this->getContinueShoppingUrl()): ?>
-                                <button type="button" title="<?php echo $this->__('Continue Shopping') ?>" class="button btn-continue" onclick="setLocation('<?php echo $this->getContinueShoppingUrl() ?>')"><span><span><?php echo $this->__('Continue Shopping') ?></span></span></button>
+                                <button type="button" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Continue Shopping')) ?>" class="button btn-continue" onclick="setLocation('<?php echo Mage::helper('core')->quoteEscape($this->getContinueShoppingUrl()) ?>')"><span><span><?php echo $this->__('Continue Shopping') ?></span></span></button>
                             <?php endif; ?>
                             <button type="submit" name="update_cart_action" value="update_qty" title="<?php echo $this->__('Update Shopping Cart'); ?>" class="button btn-update"><span><span><?php echo $this->__('Update Shopping Cart'); ?></span></span></button>
                             <button type="submit" name="update_cart_action" value="empty_cart" title="<?php echo $this->__('Clear Shopping Cart'); ?>" class="button btn-empty" id="empty_cart_button"><span><span><?php echo $this->__('Clear Shopping Cart'); ?></span></span></button>
diff --git downloader/Maged/.htaccess downloader/Maged/.htaccess
new file mode 100644
index 0000000..93169e4
--- /dev/null
+++ downloader/Maged/.htaccess
@@ -0,0 +1,2 @@
+Order deny,allow
+Deny from all
diff --git downloader/Maged/Controller.php downloader/Maged/Controller.php
index aa9d705..32755d7 100644
--- downloader/Maged/Controller.php
+++ downloader/Maged/Controller.php
@@ -320,6 +320,10 @@ final class Maged_Controller
      */
     public function connectPackagesPostAction()
     {
+        if (!$this->_validateFormKey()) {
+            echo "INVALID POST DATA";
+            return;
+        }
         $actions = isset($_POST['actions']) ? $_POST['actions'] : array();
         if (isset($_POST['ignore_local_modification'])) {
             $ignoreLocalModification = $_POST['ignore_local_modification'];
@@ -334,6 +338,10 @@ final class Maged_Controller
      */
     public function connectPreparePackagePostAction()
     {
+        if (!$this->_validateFormKey()) {
+            echo "INVALID POST DATA";
+            return;
+        }
         if (!$_POST) {
             echo "INVALID POST DATA";
             return;
@@ -355,6 +363,10 @@ final class Maged_Controller
      */
     public function connectInstallPackagePostAction()
     {
+        if (!$this->_validateFormKey()) {
+            echo "INVALID POST DATA";
+            return;
+        }
         if (!$_POST) {
             echo "INVALID POST DATA";
             return;
@@ -444,6 +456,11 @@ final class Maged_Controller
      */
     public function settingsPostAction()
     {
+        if (!$this->_validateFormKey()) {
+            $this->session()->addMessage('error', "Unable to save settings");
+            $this->redirect($this->url('settings'));
+            return;
+        }
         if ($_POST) {
             $ftp = $this->getFtpPost($_POST);
 
@@ -1122,10 +1139,7 @@ final class Maged_Controller
      */
     protected function _validateFormKey()
     {
-        if (!($formKey = $_REQUEST['form_key']) || $formKey != $this->session()->getFormKey()) {
-            return false;
-        }
-        return true;
+        return $this->session()->validateFormKey();
     }
 
     /**
diff --git downloader/Maged/Model/Session.php downloader/Maged/Model/Session.php
index 18020eb..7013c94 100644
--- downloader/Maged/Model/Session.php
+++ downloader/Maged/Model/Session.php
@@ -103,6 +103,13 @@ class Maged_Model_Session extends Maged_Model
         }
 
         try {
+            if (isset($_POST['username']) && !$this->validateFormKey()) {
+                $this->controller()
+                    ->redirect(
+                        $this->controller()->url(),
+                        true
+                    );
+            }
             if ( (isset($_POST['username']) && empty($_POST['username']))
                 || (isset($_POST['password']) && empty($_POST['password']))) {
                 $this->addMessage('error', 'Invalid user name or password');
@@ -234,4 +241,17 @@ class Maged_Model_Session extends Maged_Model
         }
         return $this->get('_form_key');
     }
+
+    /**
+     * Validate Form Key
+     *
+     * @return bool
+     */
+    public function validateFormKey()
+    {
+        if (!($formKey = $_REQUEST['form_key']) || $formKey != $this->getFormKey()) {
+            return false;
+        }
+        return true;
+    }
 }
diff --git downloader/lib/.htaccess downloader/lib/.htaccess
new file mode 100644
index 0000000..93169e4
--- /dev/null
+++ downloader/lib/.htaccess
@@ -0,0 +1,2 @@
+Order deny,allow
+Deny from all
diff --git downloader/template/connect/packages.phtml downloader/template/connect/packages.phtml
index 9cca5a6..f42e74e 100644
--- downloader/template/connect/packages.phtml
+++ downloader/template/connect/packages.phtml
@@ -85,7 +85,7 @@ Event.observe(window, 'load', changeAvailableArchiveStatus);
 function connectPrepare(form) {
     new Ajax.Request(form.action, {
       method:'post',
-      parameters: {install_package_id: form.install_package_id.value},
+      parameters: {install_package_id: form.install_package_id.value, form_key: form.form_key.value},
       onCreate: function() {
           $('prepare_package_result').update(
                 '<div class="loading-mask" id="loading_mask_loader">'+
@@ -122,6 +122,7 @@ function connectPrepare(form) {
 //-->
 </script>
 <form action="<?php echo $this->url('connectPreparePackagePost')?>" method="post" onsubmit="return connectPrepare(this)">
+    <input name="form_key" type="hidden" value="<?php echo $this->getFormKey() ?>" />
     <ul class="bare-list">
         <li>
             <span class="step-count">1</span> &nbsp; Search for modules via <a href="http://connect.magentocommerce.com/" target="Magento_Connect">Magento Connect</a>.
@@ -176,6 +177,7 @@ function connectPrepare(form) {
 <?php foreach ($packages as $channel=>$pkgs): ?>
 
 <form id="connect_packages_<?php echo $i ?>" class="connect-packages" action="<?php echo $this->url('connectPackagesPost')?>" method="post" target="connect_iframe">
+    <input name="form_key" type="hidden" value="<?php echo $this->getFormKey() ?>" />
     <div class="no-display">
         <input type="hidden" id="ignore_local_modification" name="ignore_local_modification" value=""/>
         <input type="hidden" name="form_id" value="connect_packages_<?php echo $i ?>"/>
diff --git downloader/template/connect/packages_prepare.phtml downloader/template/connect/packages_prepare.phtml
index f74c3df..86aa51b 100644
--- downloader/template/connect/packages_prepare.phtml
+++ downloader/template/connect/packages_prepare.phtml
@@ -33,6 +33,7 @@
 Extension dependencies
 <form action="<?php
     echo $this->url('connectInstallPackagePost')?>" method="post" target="connect_iframe" onsubmit="onSubmit(this)">
+    <input name="form_key" type="hidden" value="<?php echo $this->getFormKey() ?>" />
     <input type="hidden" name="install_package_id" value="<?php echo $this->escapeHtml($this->get('package_id')); ?>">
     <table cellspacing="0" cellpadding="0" width="100%">
         <col width="150" />
diff --git downloader/template/login.phtml downloader/template/login.phtml
index 6e4cd2c..dbbeda8 100644
--- downloader/template/login.phtml
+++ downloader/template/login.phtml
@@ -30,6 +30,7 @@
 <?php endif ?>
 <div style="width:300px; padding:20px; margin:90px auto !important; background:#f6f6f6;">
 <form method="post" action="#">
+    <input name="form_key" type="hidden" value="<?php echo $this->getFormKey() ?>" />
     <h2 class="page-head">Log In</h2>
     <p><small>Please re-enter your Magento Adminstration Credentials.<br/>Only administrators with full permissions will be able to log in.</small></p>
     <table class="form-list">
diff --git downloader/template/settings.phtml downloader/template/settings.phtml
index 13551ac..47ab411 100644
--- downloader/template/settings.phtml
+++ downloader/template/settings.phtml
@@ -50,6 +50,7 @@ function changeDeploymentType (element)
 <div class="settings-page">
     <h2 class="page-head">Settings</h2>
     <form action="<?php echo $this->url('settingsPost') ?>" method="post">
+        <input name="form_key" type="hidden" value="<?php echo $this->getFormKey() ?>" />
         <fieldset>
             <p>Magento Extensions are available in three different versions.</p>
             <ul class="disc">
diff --git errors/processor.php errors/processor.php
index 817a4d4..5ae49e2 100644
--- errors/processor.php
+++ errors/processor.php
@@ -460,11 +460,11 @@ class Error_Processor
         $this->_setReportData($reportData);
 
         if (!file_exists($this->_reportDir)) {
-            @mkdir($this->_reportDir, 0777, true);
+            @mkdir($this->_reportDir, 0750, true);
         }
 
         @file_put_contents($this->_reportFile, serialize($reportData));
-        @chmod($this->_reportFile, 0777);
+        @chmod($this->_reportFile, 0640);
 
         if (isset($reportData['skin']) && self::DEFAULT_SKIN != $reportData['skin']) {
             $this->_setSkin($reportData['skin']);
