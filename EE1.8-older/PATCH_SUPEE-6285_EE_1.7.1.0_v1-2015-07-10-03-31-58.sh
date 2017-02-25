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


SUPEE-6285 | EE_1.7.1.0 | v1 | c5e638e5fee126b01c9fa0357b25068aa4af7299 | Fri Jul 10 17:18:49 2015 +0300 | v1.7.1.0..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/Mage.php app/Mage.php
index 4ad7c2f..8a84f0a 100644
--- app/Mage.php
+++ app/Mage.php
@@ -686,15 +686,17 @@ final class Mage
 
         try {
             if (!isset($loggers[$file])) {
-                $logFile = self::getBaseDir('var') . DS . 'log' . DS . $file;
+                $logDir  = self::getBaseDir('var') . DS . 'log';
+                $logFile = $logDir . DS . $file;
 
-                if (!is_dir(self::getBaseDir('var').DS.'log')) {
-                    mkdir(self::getBaseDir('var').DS.'log', 0777);
+                if (!is_dir($logDir)) {
+                    mkdir($logDir);
+                    chmod($logDir, 0750);
                 }
 
                 if (!file_exists($logFile)) {
                     file_put_contents($logFile, '');
-                    chmod($logFile, 0777);
+                    chmod($logFile, 0640);
                 }
 
                 $format = '%timestamp% %priorityName% (%priority%): %message%' . PHP_EOL;
diff --git app/code/community/Phoenix/Moneybookers/controllers/MoneybookersController.php app/code/community/Phoenix/Moneybookers/controllers/MoneybookersController.php
index c54c2ce..e7aba7d 100644
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
diff --git app/code/core/Enterprise/AdminGws/Model/Controllers.php app/code/core/Enterprise/AdminGws/Model/Controllers.php
index 093c5af..b426902 100644
--- app/code/core/Enterprise/AdminGws/Model/Controllers.php
+++ app/code/core/Enterprise/AdminGws/Model/Controllers.php
@@ -152,9 +152,9 @@ class Enterprise_AdminGws_Model_Controllers extends Enterprise_AdminGws_Model_Ob
     {
         $controller->setShowCodePoolStatusMessage(false);
         if (!$this->_role->getIsWebsiteLevel()) {
-            $action = $controller->getRequest()->getActionName();
-            if (in_array($action, array('new', 'generate'))
-                || $action == 'edit' && !$controller->getRequest()->getParam('id')) {
+            $actionName = strtolower($controller->getRequest()->getActionName());
+            if (in_array($actionName, array('new', 'generate'))
+                || $actionName == 'edit' && !$controller->getRequest()->getParam('id')) {
                 return $this->_forward();
             }
         }
@@ -211,7 +211,8 @@ class Enterprise_AdminGws_Model_Controllers extends Enterprise_AdminGws_Model_Ob
     public function validateCatalogCategories($controller)
     {
         $forward = false;
-        switch ($controller->getRequest()->getActionName()) {
+        $actionName = strtolower($controller->getRequest()->getActionName());
+        switch ($actionName) {
             case 'add':
                 /**
                  * adding is not allowed from begining if user has scope specified permissions
@@ -270,7 +271,8 @@ class Enterprise_AdminGws_Model_Controllers extends Enterprise_AdminGws_Model_Ob
     {
         // instead of generic (we are capped by allowed store groups root categories)
         // check whether attempting to create event for wrong category
-        if ('new' === $this->_request->getActionName()) {
+        $actionName = strtolower($this->_request->getActionName());
+        if ('new' === $actionName) {
             $category = Mage::getModel('catalog/category')->load($this->_request->getParam('category_id'));
             if (($this->_request->getParam('category_id') && !$this->_isCategoryAllowed($category)) ||
                 !$this->_role->getIsWebsiteLevel()) {
@@ -333,10 +335,11 @@ class Enterprise_AdminGws_Model_Controllers extends Enterprise_AdminGws_Model_Ob
     public function validateNoWebsiteGeneric($controller = null, $denyActions = array('new', 'delete'), $saveAction = 'save', $idFieldName = 'id')
     {
         if (!is_array($denyActions)) {
-            $denyActions = array($denyActions);
+             $denyActions = array($denyActions);
         }
-        if ((!$this->_role->getWebsiteIds()) && (in_array($this->_request->getActionName(), $denyActions)
-                || ($saveAction === $this->_request->getActionName() && 0 == $this->_request->getParam($idFieldName)))) {
+        $actionName = strtolower($this->_request->getActionName());
+        if ((!$this->_role->getWebsiteIds()) && (in_array($actionName, $denyActions)
+            || ($saveAction === $actionName && 0 == $this->_request->getParam($idFieldName)))) {
             $this->_forward();
             return false;
         }
@@ -350,17 +353,18 @@ class Enterprise_AdminGws_Model_Controllers extends Enterprise_AdminGws_Model_Ob
      */
     public function validateSystemStore($controller)
     {
+        $actionName = strtolower($this->_request->getActionName());
         // due to design of the original controller, need to run this check only once, on the first dispatch
         if (Mage::registry('enterprise_admingws_system_store_matched')) {
             return;
-        }
-        elseif (in_array($this->_request->getActionName(), array('save', 'newWebsite', 'newGroup', 'newStore', 'editWebsite', 'editGroup', 'editStore',
-            'deleteWebsite', 'deleteWebsitePost', 'deleteGroup', 'deleteGroupPost', 'deleteStore', 'deleteStorePost'
+        } elseif (in_array($actionName, array('save', 'newwebsite', 'newgroup', 'newstore',
+            'editwebsite', 'editgroup', 'editstore', 'deletewebsite', 'deletewebsitepost', 'deletegroup',
+            'deletegrouppost', 'deletestore', 'deletestorepost'
             ))) {
             Mage::register('enterprise_admingws_system_store_matched', true, true);
         }
 
-        switch ($this->_request->getActionName()) {
+        switch ($actionName) {
             case 'save':
                 $params = $this->_request->getParams();
                 if (isset($params['website'])) {
@@ -373,36 +377,36 @@ class Enterprise_AdminGws_Model_Controllers extends Enterprise_AdminGws_Model_Ob
                     // preventing saving stores/groups for wrong website is handled by their models
                 }
                 break;
-            case 'newWebsite':
+            case 'newwebsite':
                 return $this->_forward();
                 break;
-            case 'newGroup': // break intentionally omitted
-            case 'newStore':
+            case 'newgroup': // break intentionally omitted
+            case 'newstore':
                 if (!$this->_role->getWebsiteIds()) {
                     return $this->_forward();
                 }
                 break;
-            case 'editWebsite':
+            case 'editwebsite':
                 if (!$this->_role->hasWebsiteAccess($this->_request->getParam('website_id'))) {
                     return $this->_forward();
                 }
                 break;
-            case 'editGroup':
+            case 'editgroup':
                 if (!$this->_role->hasStoreGroupAccess($this->_request->getParam('group_id'))) {
                     return $this->_forward();
                 }
                 break;
-            case 'editStore':
+            case 'editstore':
                 if (!$this->_role->hasStoreAccess($this->_request->getParam('store_id'))) {
                     return $this->_forward();
                 }
                 break;
-            case 'deleteWebsite': // break intentionally omitted
-            case 'deleteWebsitePost':
+            case 'deletewebsite': // break intentionally omitted
+            case 'deletewebsitepost':
                 return $this->_forward();
                 break;
-            case 'deleteGroup': // break intentionally omitted
-            case 'deleteGroupPost':
+            case 'deletegroup': // break intentionally omitted
+            case 'deletegrouppost':
                 if ($group = $this->_role->getGroup($this->_request->getParam('item_id'))) {
                     if ($this->_role->hasWebsiteAccess($group->getWebsiteId(), true)) {
                         return;
@@ -410,8 +414,8 @@ class Enterprise_AdminGws_Model_Controllers extends Enterprise_AdminGws_Model_Ob
                 }
                 return $this->_forward();
                 break;
-            case 'deleteStore': // break intentionally omitted
-            case 'deleteStorePost':
+            case 'deletestore': // break intentionally omitted
+            case 'deletestorepost':
                 if ($store = Mage::app()->getStore($this->_request->getParam('item_id'))) {
                     if ($this->_role->hasWebsiteAccess($store->getWebsiteId(), true)) {
                         return;
@@ -451,8 +455,9 @@ class Enterprise_AdminGws_Model_Controllers extends Enterprise_AdminGws_Model_Ob
      */
     protected function _forward($action = 'denied', $module = null, $controller = null)
     {
+        $actionName = strtolower($this->_request->getActionName());
         // avoid cycling
-        if ($this->_request->getActionName() === $action
+        if ($actionName === $action
             && (null === $module || $this->_request->getModuleName() === $module)
             && (null === $controller || $this->_request->getControllerName() === $controller)) {
             return;
@@ -941,7 +946,8 @@ class Enterprise_AdminGws_Model_Controllers extends Enterprise_AdminGws_Model_Ob
      */
     public function validateManageCurrencyRates($controller)
     {
-        if (in_array($controller->getRequest()->getActionName(), array('fetchRates', 'saveRates'))) {
+        $actionName = strtolower($controller->getRequest()->getActionName());
+        if (in_array($actionName, array('fetchrates', 'saverates'))) {
             $this->_forward();
             return false;
         }
@@ -954,7 +960,8 @@ class Enterprise_AdminGws_Model_Controllers extends Enterprise_AdminGws_Model_Ob
      */
     public function validateTransactionalEmails($controller)
     {
-        if (in_array($controller->getRequest()->getActionName(), array('delete', 'save', 'new'))) {
+        $actionName = strtolower($controller->getRequest()->getActionName());
+        if (in_array($actionName, array('delete', 'save', 'new'))) {
             $this->_forward();
             return false;
         }
diff --git app/code/core/Enterprise/AdminGws/Model/Observer.php app/code/core/Enterprise/AdminGws/Model/Observer.php
index d1c4085..57ed408 100644
--- app/code/core/Enterprise/AdminGws/Model/Observer.php
+++ app/code/core/Enterprise/AdminGws/Model/Observer.php
@@ -393,7 +393,7 @@ class Enterprise_AdminGws_Model_Observer extends Enterprise_AdminGws_Model_Obser
         // map request to validator callback
         $request        = Mage::app()->getRequest();
         $routeName      = $request->getRouteName();
-        $controllerName = $request->getControllerName();
+        $controllerName = strtolower($request->getControllerName());
         $actionName     = $request->getActionName();
         $callback       = false;
         if (isset($this->_controllersMap['full'][$routeName])
diff --git app/code/core/Enterprise/Banner/controllers/Adminhtml/Banner/WidgetController.php app/code/core/Enterprise/Banner/controllers/Adminhtml/Banner/WidgetController.php
index 0f31444..19ad59c 100644
--- app/code/core/Enterprise/Banner/controllers/Adminhtml/Banner/WidgetController.php
+++ app/code/core/Enterprise/Banner/controllers/Adminhtml/Banner/WidgetController.php
@@ -47,4 +47,14 @@ class Enterprise_Banner_Adminhtml_Banner_WidgetController extends Mage_Adminhtml
 
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
diff --git app/code/core/Enterprise/Cms/Block/Adminhtml/Cms/Page/Edit/Tab/Hierarchy.php app/code/core/Enterprise/Cms/Block/Adminhtml/Cms/Page/Edit/Tab/Hierarchy.php
index f6b3715..d329b1f 100644
--- app/code/core/Enterprise/Cms/Block/Adminhtml/Cms/Page/Edit/Tab/Hierarchy.php
+++ app/code/core/Enterprise/Cms/Block/Adminhtml/Cms/Page/Edit/Tab/Hierarchy.php
@@ -173,7 +173,7 @@ class Enterprise_Cms_Block_Adminhtml_Cms_Page_Edit_Tab_Hierarchy
     public function getCurrentPageJson()
     {
         $data = array(
-            'label' => $this->getPage()->getTitle(),
+            'label' => $this->quoteEscape($this->getPage()->getTitle()),
             'id' => $this->getPage()->getId()
         );
 
diff --git app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/Hierarchy/WidgetController.php app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/Hierarchy/WidgetController.php
index 8600f62..bbab22d 100644
--- app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/Hierarchy/WidgetController.php
+++ app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/Hierarchy/WidgetController.php
@@ -52,4 +52,14 @@ class Enterprise_Cms_Adminhtml_Cms_Hierarchy_WidgetController extends Mage_Admin
             'id' => $this->getRequest()->getParam('uniq_id')
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
diff --git app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/Page/RevisionController.php app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/Page/RevisionController.php
index b21d768..4cbdc80 100644
--- app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/Page/RevisionController.php
+++ app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/Page/RevisionController.php
@@ -381,7 +381,8 @@ class Enterprise_Cms_Adminhtml_Cms_Page_RevisionController extends Enterprise_Cm
      */
     protected function _isAllowed()
     {
-        switch ($this->getRequest()->getActionName()) {
+        $action = strtolower($this->getRequest()->getActionName());
+        switch ($action) {
             case 'save':
                 return Mage::getSingleton('enterprise_cms/config')->canCurrentUserSaveRevision();
                 break;
@@ -404,7 +405,8 @@ class Enterprise_Cms_Adminhtml_Cms_Page_RevisionController extends Enterprise_Cm
      */
     public function preDispatch()
     {
-        if ($this->getRequest()->getActionName() == 'drop') {
+        $action = strtolower($this->getRequest()->getActionName());
+        if ($action == 'drop') {
             $this->_currentArea = 'frontend';
         }
         parent::preDispatch();
diff --git app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/Page/VersionController.php app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/Page/VersionController.php
index 7c71bbb..4591553 100644
--- app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/Page/VersionController.php
+++ app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/Page/VersionController.php
@@ -336,7 +336,8 @@ class Enterprise_Cms_Adminhtml_Cms_Page_VersionController extends Enterprise_Cms
      */
     protected function _isAllowed()
     {
-        switch ($this->getRequest()->getActionName()) {
+        $action = strtolower($this->getRequest()->getActionName());
+        switch ($action) {
             case 'new':
             case 'save':
                 return Mage::getSingleton('enterprise_cms/config')->canCurrentUserSaveVersion();
@@ -344,7 +345,7 @@ class Enterprise_Cms_Adminhtml_Cms_Page_VersionController extends Enterprise_Cms
             case 'delete':
                 return Mage::getSingleton('enterprise_cms/config')->canCurrentUserDeleteVersion();
                 break;
-            case 'massDeleteRevisions':
+            case 'massdeleterevisions':
                 return Mage::getSingleton('enterprise_cms/config')->canCurrentUserDeleteRevision();
                 break;
             default:
diff --git app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/PageController.php app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/PageController.php
index 96aee2e..b13449a 100644
--- app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/PageController.php
+++ app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/PageController.php
@@ -183,8 +183,9 @@ class Enterprise_Cms_Adminhtml_Cms_PageController extends Mage_Adminhtml_Cms_Pag
      */
     protected function _isAllowed()
     {
-        switch ($this->getRequest()->getActionName()) {
-            case 'massDeleteVersions':
+        $action = strtolower($this->getRequest()->getActionName());
+        switch ($action) {
+            case 'massdeleteversions':
                 return Mage::getSingleton('enterprise_cms/config')->canCurrentUserDeleteVersion();
                 break;
             default:
diff --git app/code/core/Enterprise/Logging/controllers/Adminhtml/LoggingController.php app/code/core/Enterprise/Logging/controllers/Adminhtml/LoggingController.php
index 1ebaee4..0bc6997 100644
--- app/code/core/Enterprise/Logging/controllers/Adminhtml/LoggingController.php
+++ app/code/core/Enterprise/Logging/controllers/Adminhtml/LoggingController.php
@@ -137,15 +137,16 @@ class Enterprise_Logging_Adminhtml_LoggingController extends Mage_Adminhtml_Cont
      */
     protected function _isAllowed()
     {
-        switch ($this->getRequest()->getActionName()) {
+        $action = strtolower($this->getRequest()->getActionName());
+        switch ($action) {
             case 'archive':
             case 'download':
-            case 'archiveGrid':
+            case 'archivegrid':
                 return Mage::getSingleton('admin/session')->isAllowed('admin/system/enterprise_logging/backups');
                 break;
             case 'grid':
-            case 'exportCsv':
-            case 'exportXml':
+            case 'exportcsv':
+            case 'exportxml':
             case 'details':
             case 'index':
                 return Mage::getSingleton('admin/session')->isAllowed('admin/system/enterprise_logging/events');
diff --git app/code/core/Mage/Adminhtml/Controller/Action.php app/code/core/Mage/Adminhtml/Controller/Action.php
index 65a357a..0f00d2f 100644
--- app/code/core/Mage/Adminhtml/Controller/Action.php
+++ app/code/core/Mage/Adminhtml/Controller/Action.php
@@ -63,7 +63,7 @@ class Mage_Adminhtml_Controller_Action extends Mage_Core_Controller_Varien_Actio
 
     protected function _isAllowed()
     {
-        return true;
+        return Mage::getSingleton('admin/session')->isAllowed('admin');
     }
 
     /**
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/Category/WidgetController.php app/code/core/Mage/Adminhtml/controllers/Catalog/Category/WidgetController.php
index a81b717..0b3bc98 100644
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
index b54d890..b79675a 100644
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
index dbedf7a..0ff57e9 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/Product/ReviewController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/Product/ReviewController.php
@@ -352,7 +352,8 @@ class Mage_Adminhtml_Catalog_Product_ReviewController extends Mage_Adminhtml_Con
 
     protected function _isAllowed()
     {
-        switch ($this->getRequest()->getActionName()) {
+        $action = strtolower($this->getRequest()->getActionName());
+        switch ($action) {
             case 'pending':
                 return Mage::getSingleton('admin/session')->isAllowed('catalog/reviews_ratings/reviews/pending');
                 break;
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/Product/WidgetController.php app/code/core/Mage/Adminhtml/controllers/Catalog/Product/WidgetController.php
index fa251df..724926c 100644
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
index 8bac205..a668d95 100644
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
index 14952fa..d890e0e 100644
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
index 840a5fb..85a98b7 100644
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
index 7f46dd3..9a375a8 100644
--- app/code/core/Mage/Adminhtml/controllers/Cms/WysiwygController.php
+++ app/code/core/Mage/Adminhtml/controllers/Cms/WysiwygController.php
@@ -59,4 +59,14 @@ class Mage_Adminhtml_Cms_WysiwygController extends Mage_Adminhtml_Controller_Act
             imagedestroy($image);
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
diff --git app/code/core/Mage/Adminhtml/controllers/JsonController.php app/code/core/Mage/Adminhtml/controllers/JsonController.php
index f5818ed..bd74bdb 100644
--- app/code/core/Mage/Adminhtml/controllers/JsonController.php
+++ app/code/core/Mage/Adminhtml/controllers/JsonController.php
@@ -49,4 +49,14 @@ class Mage_Adminhtml_JsonController extends Mage_Adminhtml_Controller_Action
 
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
index ddef9cc..1e2880a 100644
--- app/code/core/Mage/Adminhtml/controllers/NotificationController.php
+++ app/code/core/Mage/Adminhtml/controllers/NotificationController.php
@@ -169,12 +169,13 @@ class Mage_Adminhtml_NotificationController extends Mage_Adminhtml_Controller_Ac
 
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
 
@@ -182,7 +183,7 @@ class Mage_Adminhtml_NotificationController extends Mage_Adminhtml_Controller_Ac
                 $acl = 'system/adminnotification/remove';
                 break;
 
-            case 'massRemove':
+            case 'massremove':
                 $acl = 'system/adminnotification/remove';
                 break;
 
diff --git app/code/core/Mage/Adminhtml/controllers/Report/CustomerController.php app/code/core/Mage/Adminhtml/controllers/Report/CustomerController.php
index 48c75e0..c9dff9b 100644
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
index f9a1f3d..99d5b7b 100644
--- app/code/core/Mage/Adminhtml/controllers/Report/ProductController.php
+++ app/code/core/Mage/Adminhtml/controllers/Report/ProductController.php
@@ -278,7 +278,8 @@ class Mage_Adminhtml_Report_ProductController extends Mage_Adminhtml_Controller_
      */
     protected function _isAllowed()
     {
-        switch ($this->getRequest()->getActionName()) {
+        $action = strtolower($this->getRequest()->getActionName());
+        switch ($action) {
             case 'ordered':
                 return Mage::getSingleton('admin/session')->isAllowed('report/products/ordered');
                 break;
diff --git app/code/core/Mage/Adminhtml/controllers/Report/ReviewController.php app/code/core/Mage/Adminhtml/controllers/Report/ReviewController.php
index 486d9da..597bb27 100644
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
index d27ac65..49942b4 100644
--- app/code/core/Mage/Adminhtml/controllers/Report/SalesController.php
+++ app/code/core/Mage/Adminhtml/controllers/Report/SalesController.php
@@ -425,7 +425,8 @@ class Mage_Adminhtml_Report_SalesController extends Mage_Adminhtml_Controller_Ac
 
     protected function _isAllowed()
     {
-        switch ($this->getRequest()->getActionName()) {
+        $action = strtolower($this->getRequest()->getActionName());
+        switch ($action) {
             case 'sales':
                 return Mage::getSingleton('admin/session')->isAllowed('report/salesroot/sales');
                 break;
diff --git app/code/core/Mage/Adminhtml/controllers/Report/ShopcartController.php app/code/core/Mage/Adminhtml/controllers/Report/ShopcartController.php
index 8cbe47a..2b07887 100644
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
index 1c2540e..f5003b9 100644
--- app/code/core/Mage/Adminhtml/controllers/Report/TagController.php
+++ app/code/core/Mage/Adminhtml/controllers/Report/TagController.php
@@ -261,14 +261,15 @@ class Mage_Adminhtml_Report_TagController extends Mage_Adminhtml_Controller_Acti
 
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
index 008fdc9..5b6adb1 100644
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
index 2f81fa0..ecb2791 100644
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
index c2d0b09..626e1ef 100644
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
diff --git app/code/core/Mage/Adminhtml/controllers/Sales/Order/View/GiftmessageController.php app/code/core/Mage/Adminhtml/controllers/Sales/Order/View/GiftmessageController.php
index 7399db7..62155be 100644
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
diff --git app/code/core/Mage/Adminhtml/controllers/TagController.php app/code/core/Mage/Adminhtml/controllers/TagController.php
index d705891..92611d9 100644
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
index 6b63c4b..b9f45b7 100644
--- app/code/core/Mage/Adminhtml/controllers/Tax/RateController.php
+++ app/code/core/Mage/Adminhtml/controllers/Tax/RateController.php
@@ -437,8 +437,9 @@ class Mage_Adminhtml_Tax_RateController extends Mage_Adminhtml_Controller_Action
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
diff --git app/code/core/Mage/Centinel/controllers/Adminhtml/Centinel/IndexController.php app/code/core/Mage/Centinel/controllers/Adminhtml/Centinel/IndexController.php
index c179f92..3531cfe 100644
--- app/code/core/Mage/Centinel/controllers/Adminhtml/Centinel/IndexController.php
+++ app/code/core/Mage/Centinel/controllers/Adminhtml/Centinel/IndexController.php
@@ -112,5 +112,15 @@ class Mage_Centinel_Adminhtml_Centinel_IndexController extends Mage_Adminhtml_Co
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
index a5d701a..cf38c86 100644
--- app/code/core/Mage/Checkout/controllers/MultishippingController.php
+++ app/code/core/Mage/Checkout/controllers/MultishippingController.php
@@ -72,7 +72,7 @@ class Mage_Checkout_MultishippingController extends Mage_Checkout_Controller_Act
     {
         parent::preDispatch();
 
-        $action = $this->getRequest()->getActionName();
+        $action = strtolower($this->getRequest()->getActionName());
         if (!preg_match('#^(login|register)#', $action)) {
             if (!Mage::getSingleton('customer/session')->authenticate($this, $this->_getHelper()->getMSLoginUrl())) {
                 $this->setFlag('', self::FLAG_NO_DISPATCH, true);
diff --git app/code/core/Mage/Core/Block/Abstract.php app/code/core/Mage/Core/Block/Abstract.php
index 7ac8bb6..dbd6ac2 100644
--- app/code/core/Mage/Core/Block/Abstract.php
+++ app/code/core/Mage/Core/Block/Abstract.php
@@ -988,6 +988,19 @@ abstract class Mage_Core_Block_Abstract extends Varien_Object
     }
 
     /**
+     * Escape quotes inside html attributes
+     * Use $addSlashes = false for escaping js that inside html attribute (onClick, onSubmit etc)
+     *
+     * @param  string $data
+     * @param  bool $addSlashes
+     * @return string
+     */
+    public function quoteEscape($data, $addSlashes = false)
+    {
+        return $this->helper('core')->quoteEscape($data, $addSlashes);
+    }
+
+    /**
      * Escape quotes in java scripts
      *
      * @param mixed $data
diff --git app/code/core/Mage/Core/Helper/Abstract.php app/code/core/Mage/Core/Helper/Abstract.php
index b108b05..6e15182 100644
--- app/code/core/Mage/Core/Helper/Abstract.php
+++ app/code/core/Mage/Core/Helper/Abstract.php
@@ -190,6 +190,14 @@ abstract class Mage_Core_Helper_Abstract
         }
         return $result;
     }
+    
+    /*
+     * @see self::htmlEscape
+     */
+    public function escapeHtml($data, $allowedTags = null)
+    {
+        return $this->htmlEscape($data, $allowedTags = null);
+    }
 
     /**
      * Escape html entities in url
@@ -222,6 +230,22 @@ abstract class Mage_Core_Helper_Abstract
     }
 
     /**
+     * Escape quotes inside html attributes
+     * Use $addSlashes = false for escaping js that inside html attribute (onClick, onSubmit etc)
+     *
+     * @param string $data
+     * @param bool $addSlashes
+     * @return string
+     */
+    public function quoteEscape($data, $addSlashes = false)
+    {
+        if ($addSlashes === true) {
+            $data = addslashes($data);
+        }
+        return htmlspecialchars($data, ENT_QUOTES, null, false);
+    }
+
+    /**
      * Retrieve url
      *
      * @param   string $route
diff --git app/code/core/Mage/Rss/controllers/CatalogController.php app/code/core/Mage/Rss/controllers/CatalogController.php
index bbedc27..c0c933b 100644
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
index 5136ea6..cd4b0ed 100644
--- app/code/core/Mage/Rss/controllers/OrderController.php
+++ app/code/core/Mage/Rss/controllers/OrderController.php
@@ -77,7 +77,8 @@ class Mage_Rss_OrderController extends Mage_Core_Controller_Front_Action
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
index 4660144..c76bf69 100644
--- app/code/core/Mage/Widget/Block/Adminhtml/Widget/Chooser.php
+++ app/code/core/Mage/Widget/Block/Adminhtml/Widget/Chooser.php
@@ -176,7 +176,9 @@ class Mage_Widget_Block_Adminhtml_Widget_Chooser extends Mage_Adminhtml_Block_Te
             <script type="text/javascript">
                 '.$chooserId.' = new WysiwygWidget.chooser("'.$chooserId.'", "'.$this->getSourceUrl().'", '.$configJson.');
             </script>
-            <label class="widget-option-label" id="'.$chooserId . 'label">'.($this->getLabel() ? $this->getLabel() : Mage::helper('widget')->__('Not Selected')).'</label>
+            <label class="widget-option-label" id="' . $chooserId . 'label">'
+            . $this->quoteEscape($this->getLabel() ? $this->getLabel() : Mage::helper('widget')->__('Not Selected'))
+            . '</label>
         ';
     }
 }
diff --git app/code/core/Mage/Widget/controllers/Adminhtml/WidgetController.php app/code/core/Mage/Widget/controllers/Adminhtml/WidgetController.php
index 4114c5d..c0950d2 100644
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
index 805490e..a0a8b207 100644
--- app/design/frontend/base/default/template/checkout/cart.phtml
+++ app/design/frontend/base/default/template/checkout/cart.phtml
@@ -91,7 +91,7 @@
                     <tr>
                         <td colspan="50" class="a-right">
                             <?php if($this->getContinueShoppingUrl()): ?>
-                                <button type="button" title="<?php echo $this->__('Continue Shopping') ?>" class="button btn-continue" onclick="setLocation('<?php echo $this->getContinueShoppingUrl() ?>')"><span><span><?php echo $this->__('Continue Shopping') ?></span></span></button>
+                                <button type="button" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Continue Shopping')) ?>" class="button btn-continue" onclick="setLocation('<?php echo Mage::helper('core')->quoteEscape($this->getContinueShoppingUrl()) ?>')"><span><span><?php echo $this->__('Continue Shopping') ?></span></span></button>
                             <?php endif; ?>
                             <button type="submit" title="<?php echo $this->__('Update Shopping Cart') ?>" class="button btn-update"><span><span><?php echo $this->__('Update Shopping Cart') ?></span></span></button>
                         </td>
diff --git app/design/frontend/base/default/template/checkout/cart/noItems.phtml app/design/frontend/base/default/template/checkout/cart/noItems.phtml
index 61400a9..2fabf34 100644
--- app/design/frontend/base/default/template/checkout/cart/noItems.phtml
+++ app/design/frontend/base/default/template/checkout/cart/noItems.phtml
@@ -29,4 +29,4 @@
 </div>
 <?php echo $this->getMessagesBlock()->getGroupedHtml() ?>
 <p><?php echo $this->__('You have no items in your shopping cart.') ?></p>
-<p><?php echo $this->__('Please <a href="%s">continue shopping</a>.', $this->getContinueShoppingUrl()) ?></p>
+<p><?php echo $this->__('Please <a href="%s">continue shopping</a>.', Mage::helper('core')->quoteEscape($this->getContinueShoppingUrl())) ?></p>
diff --git app/design/frontend/base/default/template/checkout/onepage/failure.phtml app/design/frontend/base/default/template/checkout/onepage/failure.phtml
index 1562454..5a9bca3 100644
--- app/design/frontend/base/default/template/checkout/onepage/failure.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/failure.phtml
@@ -29,4 +29,4 @@
 </div>
 <?php if ($this->getRealOrderId()) : ?><p><?php echo $this->__('Order #') . $this->getRealOrderId() ?></p><?php endif ?>
 <?php if ($error = $this->getErrorMessage()) : ?><p><?php echo $error ?></p><?php endif ?>
-<p><?php echo $this->__('Please <a href="%s">continue shopping</a>.', $this->getContinueShoppingUrl()) ?></p>
+<p><?php echo $this->__('Please <a href="%s">continue shopping</a>.', Mage::helper('core')->quoteEscape($this->getContinueShoppingUrl())) ?></p>
diff --git app/design/frontend/base/default/template/eway/secure/failure.phtml app/design/frontend/base/default/template/eway/secure/failure.phtml
index 455afbf..21ddcb2 100644
--- app/design/frontend/base/default/template/eway/secure/failure.phtml
+++ app/design/frontend/base/default/template/eway/secure/failure.phtml
@@ -28,4 +28,4 @@
     <h1><?php echo $this->__('Error occured') ?></h1>
 </div>
 <p><?php echo $this->getErrorMessage() ?>.</p>
-<p><?php echo $this->__('Please <a href="%s">continue shopping</a>.', $this->getContinueShoppingUrl()) ?></p>
+<p><?php echo $this->__('Please <a href="%s">continue shopping</a>.', Mage::helper('core')->quoteEscape($this->getContinueShoppingUrl())) ?></p>
diff --git app/design/frontend/base/default/template/eway/shared/failure.phtml app/design/frontend/base/default/template/eway/shared/failure.phtml
index 455afbf..21ddcb2 100644
--- app/design/frontend/base/default/template/eway/shared/failure.phtml
+++ app/design/frontend/base/default/template/eway/shared/failure.phtml
@@ -28,4 +28,4 @@
     <h1><?php echo $this->__('Error occured') ?></h1>
 </div>
 <p><?php echo $this->getErrorMessage() ?>.</p>
-<p><?php echo $this->__('Please <a href="%s">continue shopping</a>.', $this->getContinueShoppingUrl()) ?></p>
+<p><?php echo $this->__('Please <a href="%s">continue shopping</a>.', Mage::helper('core')->quoteEscape($this->getContinueShoppingUrl())) ?></p>
diff --git app/design/frontend/base/default/template/ideal/advanced/failure.phtml app/design/frontend/base/default/template/ideal/advanced/failure.phtml
index 14d9779..8dd00f4 100644
--- app/design/frontend/base/default/template/ideal/advanced/failure.phtml
+++ app/design/frontend/base/default/template/ideal/advanced/failure.phtml
@@ -28,4 +28,4 @@
     <h1><?php echo $this->__('Error occured') ?></h1>
 </div>
 <p><?php echo $this->getErrorMessage() ?></p>
-<p><?php echo $this->__('Please <a href="%s">continue shopping</a>.', $this->getContinueShoppingUrl()) ?></p>
+<p><?php echo $this->__('Please <a href="%s">continue shopping</a>.', Mage::helper('core')->quoteEscape($this->getContinueShoppingUrl())) ?></p>
diff --git app/design/frontend/base/default/template/ideal/basic/failure.phtml app/design/frontend/base/default/template/ideal/basic/failure.phtml
index 14d9779..8dd00f4 100644
--- app/design/frontend/base/default/template/ideal/basic/failure.phtml
+++ app/design/frontend/base/default/template/ideal/basic/failure.phtml
@@ -28,4 +28,4 @@
     <h1><?php echo $this->__('Error occured') ?></h1>
 </div>
 <p><?php echo $this->getErrorMessage() ?></p>
-<p><?php echo $this->__('Please <a href="%s">continue shopping</a>.', $this->getContinueShoppingUrl()) ?></p>
+<p><?php echo $this->__('Please <a href="%s">continue shopping</a>.', Mage::helper('core')->quoteEscape($this->getContinueShoppingUrl())) ?></p>
diff --git app/design/frontend/base/default/template/paybox/system/error.phtml app/design/frontend/base/default/template/paybox/system/error.phtml
index 455afbf..21ddcb2 100644
--- app/design/frontend/base/default/template/paybox/system/error.phtml
+++ app/design/frontend/base/default/template/paybox/system/error.phtml
@@ -28,4 +28,4 @@
     <h1><?php echo $this->__('Error occured') ?></h1>
 </div>
 <p><?php echo $this->getErrorMessage() ?>.</p>
-<p><?php echo $this->__('Please <a href="%s">continue shopping</a>.', $this->getContinueShoppingUrl()) ?></p>
+<p><?php echo $this->__('Please <a href="%s">continue shopping</a>.', Mage::helper('core')->quoteEscape($this->getContinueShoppingUrl())) ?></p>
diff --git app/design/frontend/base/default/template/protx/standard/failure.phtml app/design/frontend/base/default/template/protx/standard/failure.phtml
index 455afbf..21ddcb2 100644
--- app/design/frontend/base/default/template/protx/standard/failure.phtml
+++ app/design/frontend/base/default/template/protx/standard/failure.phtml
@@ -28,4 +28,4 @@
     <h1><?php echo $this->__('Error occured') ?></h1>
 </div>
 <p><?php echo $this->getErrorMessage() ?>.</p>
-<p><?php echo $this->__('Please <a href="%s">continue shopping</a>.', $this->getContinueShoppingUrl()) ?></p>
+<p><?php echo $this->__('Please <a href="%s">continue shopping</a>.', Mage::helper('core')->quoteEscape($this->getContinueShoppingUrl())) ?></p>
diff --git app/design/frontend/base/default/template/rss/order/details.phtml app/design/frontend/base/default/template/rss/order/details.phtml
index 0709da8..c0b6698 100644
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
index ddca44e..b078448 100644
--- app/design/frontend/base/default/template/wishlist/email/rss.phtml
+++ app/design/frontend/base/default/template/wishlist/email/rss.phtml
@@ -25,7 +25,7 @@
  */
 ?>
 <div>
-    <?php echo $this->__("RSS link to %s's wishlist",$this->helper('wishlist')->getCustomerName()) ?>
+    <?php echo $this->__("RSS link to %s's wishlist", Mage::helper('core')->escapeHtml($this->helper('wishlist')->getCustomerName())) ?>
     <br />
     <a href="<?php echo $this->helper('wishlist')->getRssUrl(); ?>"><?php echo $this->helper('wishlist')->getRssUrl(); ?></a>
 </div>
diff --git app/design/frontend/enterprise/default/template/checkout/cart.phtml app/design/frontend/enterprise/default/template/checkout/cart.phtml
index 01d36cb..2e7210b 100644
--- app/design/frontend/enterprise/default/template/checkout/cart.phtml
+++ app/design/frontend/enterprise/default/template/checkout/cart.phtml
@@ -91,7 +91,7 @@
                     <tr>
                         <td colspan="50" class="a-right">
                             <?php if($this->getContinueShoppingUrl()): ?>
-                                <button type="button" class="button btn-continue" onclick="setLocation('<?php echo $this->getContinueShoppingUrl() ?>')"><span><span><?php echo $this->__('Continue Shopping') ?></span></span></button>
+                                <button type="button" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Continue Shopping')) ?>" class="button btn-continue" onclick="setLocation('<?php echo Mage::helper('core')->quoteEscape($this->getContinueShoppingUrl()) ?>')"><span><span><?php echo $this->__('Continue Shopping') ?></span></span></button>
                             <?php endif; ?>
                             <button type="submit" class="button btn-update"><span><span><?php echo $this->__('Update Shopping Cart') ?></span></span></button>
                         </td>
diff --git app/design/frontend/enterprise/default/template/checkout/cart/noItems.phtml app/design/frontend/enterprise/default/template/checkout/cart/noItems.phtml
index 0d9ae6a..4fd8c9a 100644
--- app/design/frontend/enterprise/default/template/checkout/cart/noItems.phtml
+++ app/design/frontend/enterprise/default/template/checkout/cart/noItems.phtml
@@ -30,5 +30,5 @@
 <div class="cart-empty">
 <?php echo $this->getMessagesBlock()->getGroupedHtml() ?>
 <p><?php echo $this->__('You have no items in your shopping cart.') ?></p>
-<p><?php echo $this->__('Please <a href="%s">continue shopping</a>.', $this->getContinueShoppingUrl()) ?></p>
+<p><?php echo $this->__('Please <a href="%s">continue shopping</a>.', Mage::helper('core')->quoteEscape($this->getContinueShoppingUrl())) ?></p>
 </div>
diff --git app/design/frontend/enterprise/default/template/checkout/onepage/failure.phtml app/design/frontend/enterprise/default/template/checkout/onepage/failure.phtml
index e7d29b4..3acea6f 100644
--- app/design/frontend/enterprise/default/template/checkout/onepage/failure.phtml
+++ app/design/frontend/enterprise/default/template/checkout/onepage/failure.phtml
@@ -29,4 +29,4 @@
 </div>
 <?php if ($this->getRealOrderId()) : ?><p><?php echo $this->__('Order #') . $this->getRealOrderId() ?></p><?php endif ?>
 <?php if ($error = $this->getErrorMessage()) : ?><p><?php echo $error ?></p><?php endif ?>
-<p><?php echo $this->__('Please <a href="%s">continue shopping</a>.', $this->getContinueShoppingUrl()) ?></p>
+<p><?php echo $this->__('Please <a href="%s">continue shopping</a>.', Mage::helper('core')->quoteEscape($this->getContinueShoppingUrl())) ?></p>
diff --git app/design/frontend/enterprise/default/template/rss/order/details.phtml app/design/frontend/enterprise/default/template/rss/order/details.phtml
index 17efd47..fe3acae 100644
--- app/design/frontend/enterprise/default/template/rss/order/details.phtml
+++ app/design/frontend/enterprise/default/template/rss/order/details.phtml
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
diff --git app/design/frontend/enterprise/default/template/wishlist/email/rss.phtml app/design/frontend/enterprise/default/template/wishlist/email/rss.phtml
index 66cb42f..75c9419 100644
--- app/design/frontend/enterprise/default/template/wishlist/email/rss.phtml
+++ app/design/frontend/enterprise/default/template/wishlist/email/rss.phtml
@@ -25,7 +25,8 @@
  */
 ?>
 <div>
-    <?php echo $this->__("RSS link to %s's wishlist",$this->helper('wishlist')->getCustomerName()) ?>
+    <?php $customerName = $this->helper('wishlist')->getCustomerName();?>
+    <?php echo $this->__("RSS link to %s's wishlist", Mage::helper('core')->quoteEscape($customerName)) ?>
     <br />
     <a href="<?php echo $this->helper('wishlist')->getRssUrl(); ?>"><?php echo $this->helper('wishlist')->getRssUrl(); ?></a>
 </div>
diff --git errors/processor.php errors/processor.php
index 56d2b2a..8eca30f 100644
--- errors/processor.php
+++ errors/processor.php
@@ -443,11 +443,11 @@ class Error_Processor
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
