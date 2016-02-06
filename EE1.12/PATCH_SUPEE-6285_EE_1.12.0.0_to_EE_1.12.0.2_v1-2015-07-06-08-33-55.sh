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


SUPEE-6285 | EE_1.12.0.2 | v1 | 5f5978c8c4d33db3a86410c56919c0a6b6d5299e | Mon Jun 22 08:22:01 2015 +0300 | 2c88948616..5f5978c8c4

__PATCHFILE_FOLLOWS__
diff --git app/Mage.php app/Mage.php
index 0c8c038..8bb7cf8 100644
--- app/Mage.php
+++ app/Mage.php
@@ -813,12 +813,12 @@ final class Mage
 
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
index aef1475..71f594b 100644
--- app/code/core/Enterprise/AdminGws/Model/Controllers.php
+++ app/code/core/Enterprise/AdminGws/Model/Controllers.php
@@ -194,9 +194,9 @@ class Enterprise_AdminGws_Model_Controllers extends Enterprise_AdminGws_Model_Ob
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
@@ -210,7 +210,8 @@ class Enterprise_AdminGws_Model_Controllers extends Enterprise_AdminGws_Model_Ob
     public function validateCatalogCategories($controller)
     {
         $forward = false;
-        switch ($controller->getRequest()->getActionName()) {
+        $actionName = strtolower($controller->getRequest()->getActionName());
+        switch ($actionName) {
             case 'add':
                 /**
                  * adding is not allowed from begining if user has scope specified permissions
@@ -269,7 +270,8 @@ class Enterprise_AdminGws_Model_Controllers extends Enterprise_AdminGws_Model_Ob
     {
         // instead of generic (we are capped by allowed store groups root categories)
         // check whether attempting to create event for wrong category
-        if ('new' === $this->_request->getActionName()) {
+        $actionName = strtolower($this->_request->getActionName());
+        if ('new' === $actionName) {
             $category = Mage::getModel('catalog/category')->load($this->_request->getParam('category_id'));
             if (($this->_request->getParam('category_id') && !$this->_isCategoryAllowed($category)) ||
                 !$this->_role->getIsWebsiteLevel()) {
@@ -339,8 +341,9 @@ class Enterprise_AdminGws_Model_Controllers extends Enterprise_AdminGws_Model_Ob
         if (!is_array($denyActions)) {
             $denyActions = array($denyActions);
         }
-        if ((!$this->_role->getWebsiteIds()) && (in_array($this->_request->getActionName(), $denyActions)
-            || ($saveAction === $this->_request->getActionName() && 0 == $this->_request->getParam($idFieldName)))) {
+        $actionName = strtolower($this->_request->getActionName());
+        if ((!$this->_role->getWebsiteIds()) && (in_array($actionName, $denyActions)
+            || ($saveAction === $actionName && 0 == $this->_request->getParam($idFieldName)))) {
             $this->_forward();
             return false;
         }
@@ -354,17 +357,18 @@ class Enterprise_AdminGws_Model_Controllers extends Enterprise_AdminGws_Model_Ob
      */
     public function validateSystemStore($controller)
     {
+        $actionName = strtolower($this->_request->getActionName());
         // due to design of the original controller, need to run this check only once, on the first dispatch
         if (Mage::registry('enterprise_admingws_system_store_matched')) {
             return;
-        } elseif (in_array($this->_request->getActionName(), array('save', 'newWebsite', 'newGroup', 'newStore',
-            'editWebsite', 'editGroup', 'editStore', 'deleteWebsite', 'deleteWebsitePost', 'deleteGroup',
-            'deleteGroupPost', 'deleteStore', 'deleteStorePost'
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
@@ -377,36 +381,36 @@ class Enterprise_AdminGws_Model_Controllers extends Enterprise_AdminGws_Model_Ob
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
@@ -414,8 +418,8 @@ class Enterprise_AdminGws_Model_Controllers extends Enterprise_AdminGws_Model_Ob
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
@@ -455,8 +459,9 @@ class Enterprise_AdminGws_Model_Controllers extends Enterprise_AdminGws_Model_Ob
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
@@ -975,7 +980,8 @@ class Enterprise_AdminGws_Model_Controllers extends Enterprise_AdminGws_Model_Ob
      */
     public function validateManageCurrencyRates($controller)
     {
-        if (in_array($controller->getRequest()->getActionName(), array('fetchRates', 'saveRates'))) {
+        $actionName = strtolower($controller->getRequest()->getActionName());
+        if (in_array($actionName, array('fetchrates', 'saverates'))) {
             $this->_forward();
             return false;
         }
@@ -992,7 +998,8 @@ class Enterprise_AdminGws_Model_Controllers extends Enterprise_AdminGws_Model_Ob
      */
     public function validateTransactionalEmails($controller)
     {
-        if (in_array($controller->getRequest()->getActionName(), array('delete', 'save', 'new'))) {
+        $actionName = strtolower($controller->getRequest()->getActionName());
+        if (in_array($actionName, array('delete', 'save', 'new'))) {
             $this->_forward();
             return false;
         }
@@ -1053,7 +1060,7 @@ class Enterprise_AdminGws_Model_Controllers extends Enterprise_AdminGws_Model_Ob
      */
     public function validateCustomerAttributeActions($controller)
     {
-        $actionName = $this->_request->getActionName();
+        $actionName = strtolower($this->_request->getActionName());
         $attributeId = $this->_request->getParam('attribute_id');
         $websiteId = $this->_request->getParam('website');
         if (in_array($actionName, array('new', 'delete'))
@@ -1078,7 +1085,7 @@ class Enterprise_AdminGws_Model_Controllers extends Enterprise_AdminGws_Model_Ob
         $denyActions = array('edit', 'new', 'delete', 'save', 'run', 'match');
         $denyChangeDataActions = array('delete', 'save', 'run', 'match');
         $denyCreateDataActions = array('save');
-        $actionName  = $request->getActionName();
+        $actionName  = strtolower($request->getActionName());
 
         // Deny access if role has no allowed website ids and there are considering actions to deny
         if (!$this->_role->getWebsiteIds() && in_array($actionName, $denyActions)) {
diff --git app/code/core/Enterprise/AdminGws/Model/Observer.php app/code/core/Enterprise/AdminGws/Model/Observer.php
index c985abe..7a1b2b2 100644
--- app/code/core/Enterprise/AdminGws/Model/Observer.php
+++ app/code/core/Enterprise/AdminGws/Model/Observer.php
@@ -431,7 +431,7 @@ class Enterprise_AdminGws_Model_Observer extends Enterprise_AdminGws_Model_Obser
         // map request to validator callback
         $request        = Mage::app()->getRequest();
         $routeName      = $request->getRouteName();
-        $controllerName = $request->getControllerName();
+        $controllerName = strtolower($request->getControllerName());
         $actionName     = $request->getActionName();
         $callback       = false;
         if (isset($this->_controllersMap['full'][$routeName])
diff --git app/code/core/Enterprise/Banner/controllers/Adminhtml/Banner/WidgetController.php app/code/core/Enterprise/Banner/controllers/Adminhtml/Banner/WidgetController.php
index 05ee34a..82aa7bd 100644
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
index 86e0007..2f42ea8 100644
--- app/code/core/Enterprise/Cms/Block/Adminhtml/Cms/Page/Edit/Tab/Hierarchy.php
+++ app/code/core/Enterprise/Cms/Block/Adminhtml/Cms/Page/Edit/Tab/Hierarchy.php
@@ -180,7 +180,7 @@ class Enterprise_Cms_Block_Adminhtml_Cms_Page_Edit_Tab_Hierarchy
     public function getCurrentPageJson()
     {
         $data = array(
-            'label' => $this->getPage()->getTitle(),
+            'label' => $this->quoteEscape($this->getPage()->getTitle()),
             'id' => $this->getPage()->getId()
         );
 
diff --git app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/Hierarchy/WidgetController.php app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/Hierarchy/WidgetController.php
index 6ee4ad5..db8f61f 100644
--- app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/Hierarchy/WidgetController.php
+++ app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/Hierarchy/WidgetController.php
@@ -57,4 +57,14 @@ class Enterprise_Cms_Adminhtml_Cms_Hierarchy_WidgetController extends Mage_Admin
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
index 969d1c8..b87d9c7 100644
--- app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/Page/RevisionController.php
+++ app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/Page/RevisionController.php
@@ -390,7 +390,8 @@ class Enterprise_Cms_Adminhtml_Cms_Page_RevisionController extends Enterprise_Cm
      */
     protected function _isAllowed()
     {
-        switch ($this->getRequest()->getActionName()) {
+        $action = strtolower($this->getRequest()->getActionName());
+        switch ($action) {
             case 'save':
                 return Mage::getSingleton('enterprise_cms/config')->canCurrentUserSaveRevision();
                 break;
@@ -413,7 +414,8 @@ class Enterprise_Cms_Adminhtml_Cms_Page_RevisionController extends Enterprise_Cm
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
index cf22184..3858005 100644
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
index 915ccb4..168e5e9 100644
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
diff --git app/code/core/Enterprise/ImportExport/Model/Observer.php app/code/core/Enterprise/ImportExport/Model/Observer.php
index 403bfd3..c4d193f 100644
--- app/code/core/Enterprise/ImportExport/Model/Observer.php
+++ app/code/core/Enterprise/ImportExport/Model/Observer.php
@@ -84,8 +84,10 @@ class Enterprise_ImportExport_Model_Observer
                      . Enterprise_ImportExport_Model_Scheduled_Operation::LOG_DIRECTORY;
 
             if (!file_exists($logPath) || !is_dir($logPath)) {
-                if (!mkdir($logPath, 0777, true)) {
-                    Mage::throwException(Mage::helper('enterprise_importexport')->__('Unable to create directory "%s".', $logPath));
+                if (!mkdir($logPath, 0750, true)) {
+                    Mage::throwException(
+                         Mage::helper('enterprise_importexport')->__('Unable to create directory "%s".', $logPath)
+                     );
                 }
             }
 
diff --git app/code/core/Enterprise/ImportExport/Model/Scheduled/Operation.php app/code/core/Enterprise/ImportExport/Model/Scheduled/Operation.php
index 4e214bc..3185cef 100644
--- app/code/core/Enterprise/ImportExport/Model/Scheduled/Operation.php
+++ app/code/core/Enterprise/ImportExport/Model/Scheduled/Operation.php
@@ -486,7 +486,7 @@ class Enterprise_ImportExport_Model_Scheduled_Operation extends Mage_Core_Model_
         $fs->open(array(
             'path' => dirname($filePath)
         ));
-        if (!$fs->write(basename($filePath), $source)) {
+        if (!$fs->write(basename($filePath), $source, 0640)) {
             Mage::throwException(Mage::helper('enterprise_importexport')->__('Unable to save file history file'));
         }
         return $this;
@@ -503,7 +503,7 @@ class Enterprise_ImportExport_Model_Scheduled_Operation extends Mage_Core_Model_
         $dirPath = basename(Mage::getBaseDir('var')) . DS . self::LOG_DIRECTORY . date('Y' . DS . 'm' . DS . 'd')
                 . DS . self::FILE_HISTORY_DIRECTORY . DS;
         if (!is_dir(Mage::getBaseDir() . DS . $dirPath)) {
-            mkdir(Mage::getBaseDir() . DS . $dirPath, 0777, true);
+            mkdir(Mage::getBaseDir() . DS . $dirPath, 0750, true);
         }
 
         $fileName = $fileName = join('_', array(
diff --git app/code/core/Enterprise/Logging/controllers/Adminhtml/LoggingController.php app/code/core/Enterprise/Logging/controllers/Adminhtml/LoggingController.php
index 6479dd9..251a9f6 100644
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
diff --git app/code/core/Enterprise/PromotionPermissions/Model/Observer.php app/code/core/Enterprise/PromotionPermissions/Model/Observer.php
index 2fe41db..9d9bff0 100644
--- app/code/core/Enterprise/PromotionPermissions/Model/Observer.php
+++ app/code/core/Enterprise/PromotionPermissions/Model/Observer.php
@@ -240,8 +240,8 @@ class Enterprise_PromotionPermissions_Model_Observer
     public function controllerActionPredispatch($observer)
     {
         $controllerAction = $observer->getControllerAction();
-        $controllerActionName = $this->_request->getActionName();
-        $forbiddenActionNames = array('new', 'applyRules', 'save', 'delete', 'run');
+        $controllerActionName = strtolower($this->_request->getActionName());
+        $forbiddenActionNames = array('new', 'applyrules', 'save', 'delete', 'run');
 
         if (in_array($controllerActionName, $forbiddenActionNames)
             && ((!$this->_canEditSalesRules
diff --git app/code/core/Enterprise/SalesArchive/controllers/Adminhtml/Sales/OrderController.php app/code/core/Enterprise/SalesArchive/controllers/Adminhtml/Sales/OrderController.php
index 309b534..4e369ea 100644
--- app/code/core/Enterprise/SalesArchive/controllers/Adminhtml/Sales/OrderController.php
+++ app/code/core/Enterprise/SalesArchive/controllers/Adminhtml/Sales/OrderController.php
@@ -40,7 +40,8 @@ class Enterprise_SalesArchive_Adminhtml_Sales_OrderController extends Mage_Admin
      */
     protected function _isAllowed()
     {
-        if ($this->getRequest()->getActionName() == 'view') {
+        $action = strtolower($this->getRequest()->getActionName());
+        if ($action == 'view') {
             $id = $this->getRequest()->getParam('order_id');
             $archive = Mage::getModel('enterprise_salesarchive/archive');
             $ids = $archive->getIdsInArchive(Enterprise_SalesArchive_Model_Archive::ORDER, $id);
diff --git app/code/core/Enterprise/Search/controllers/Adminhtml/Catalog/SearchController.php app/code/core/Enterprise/Search/controllers/Adminhtml/Catalog/SearchController.php
index 9dc02b9..b015cb3 100644
--- app/code/core/Enterprise/Search/controllers/Adminhtml/Catalog/SearchController.php
+++ app/code/core/Enterprise/Search/controllers/Adminhtml/Catalog/SearchController.php
@@ -61,4 +61,14 @@ class Enterprise_Search_Adminhtml_Catalog_SearchController extends Mage_Adminhtm
         $this->loadLayout();
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
+        return true;
+    }
 }
diff --git app/code/core/Enterprise/Search/controllers/Adminhtml/Search/System/Config/TestconnectionController.php app/code/core/Enterprise/Search/controllers/Adminhtml/Search/System/Config/TestconnectionController.php
index adec6d2..ee9667b 100644
--- app/code/core/Enterprise/Search/controllers/Adminhtml/Search/System/Config/TestconnectionController.php
+++ app/code/core/Enterprise/Search/controllers/Adminhtml/Search/System/Config/TestconnectionController.php
@@ -78,4 +78,14 @@ class Enterprise_Search_Adminhtml_Search_System_Config_TestconnectionController
             echo 0;
         }
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
diff --git app/code/core/Enterprise/Wishlist/controllers/IndexController.php app/code/core/Enterprise/Wishlist/controllers/IndexController.php
index bf09307..eaa3555 100644
--- app/code/core/Enterprise/Wishlist/controllers/IndexController.php
+++ app/code/core/Enterprise/Wishlist/controllers/IndexController.php
@@ -45,7 +45,7 @@ class Enterprise_Wishlist_IndexController extends Mage_Wishlist_IndexController
     {
         parent::preDispatch();
 
-        $action = $this->getRequest()->getActionName();
+        $action = strtolower($this->getRequest()->getActionName());
         $protectedActions = array(
             'createwishlist', 'editwishlist', 'deletewishlist', 'copyitems', 'moveitem', 'moveitems'
         );
diff --git app/code/core/Mage/Adminhtml/Controller/Action.php app/code/core/Mage/Adminhtml/Controller/Action.php
index c5cd609..500b84b 100644
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
index 1044b38..37a797c 100644
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
index 471aeb7..eae4757 100644
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
index 0a7f004..79e7318 100644
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
index 0c3819f..3de9f6a 100644
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
index 92cd569..457850b 100644
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
index b13a9f4..287f5e5 100644
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
index 45dba09..003a612 100644
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
index 4314819..86fd98a 100644
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
index ad55e80..4cfdad6 100644
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
index fd73772..0c29e2e 100644
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
index 0568a07..5c2c9c3 100644
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
index 1fd5eae..2e5aed8 100644
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
index 47bbf74..6c80a05 100644
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
index 113ecd1..66a15ce 100644
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
index 0078dbb..fce344d 100644
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
index e849431..2321170 100644
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
index 23074e2..399985f 100644
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
index 9c9631f..9f8d0b1 100644
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
index 88bbd28..38c0924 100644
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
index 2d43898..44df420 100644
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
index 0d1b0f3..d88b46d 100644
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
index ca906e8..40a6baa 100644
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
index 72487ee..a595e82 100644
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
index 08bf7ae..f1c684d 100644
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
index cd4e62c..221d5a6 100644
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
index bce4f92..70419fe 100644
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
index aeb1ff4..1f1bc6a 100644
--- app/code/core/Mage/Adminhtml/controllers/TagController.php
+++ app/code/core/Mage/Adminhtml/controllers/TagController.php
@@ -346,7 +346,8 @@ class Mage_Adminhtml_TagController extends Mage_Adminhtml_Controller_Action
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
index 181a6fe..45cce12 100644
--- app/code/core/Mage/Adminhtml/controllers/Tax/RateController.php
+++ app/code/core/Mage/Adminhtml/controllers/Tax/RateController.php
@@ -455,8 +455,9 @@ class Mage_Adminhtml_Tax_RateController extends Mage_Adminhtml_Controller_Action
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
diff --git app/code/core/Mage/Api2/controllers/Adminhtml/Api2/AttributeController.php app/code/core/Mage/Api2/controllers/Adminhtml/Api2/AttributeController.php
index f33bbc6..0c3b922 100644
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
index f75a147..5c2fac6 100644
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
index cfae94c..bbd9d3b 100755
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
index ada8e75..468bf6c 100644
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
index 10a0982..b749bad 100644
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
index 87b0345..b2b9989 100644
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
diff --git app/code/core/Mage/Core/Block/Abstract.php app/code/core/Mage/Core/Block/Abstract.php
index ac19b74..93fff12 100644
--- app/code/core/Mage/Core/Block/Abstract.php
+++ app/code/core/Mage/Core/Block/Abstract.php
@@ -1139,6 +1139,19 @@ abstract class Mage_Core_Block_Abstract extends Varien_Object
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
diff --git app/code/core/Mage/ImportExport/Model/Abstract.php app/code/core/Mage/ImportExport/Model/Abstract.php
index 876d707..313c40f 100644
--- app/code/core/Mage/ImportExport/Model/Abstract.php
+++ app/code/core/Mage/ImportExport/Model/Abstract.php
@@ -89,7 +89,7 @@ abstract class Mage_ImportExport_Model_Abstract extends Varien_Object
             $dirPath = Mage::getBaseDir('var') . DS . Mage_ImportExport_Model_Scheduled_Operation::LOG_DIRECTORY
                 . $dirName;
             if (!is_dir($dirPath)) {
-                mkdir($dirPath, 0777, true);
+                mkdir($dirPath, 0750, true);
             }
             $fileName = substr(strstr(Mage_ImportExport_Model_Scheduled_Operation::LOG_DIRECTORY, DS), 1)
                 . $dirName . $fileName . '.log';
diff --git app/code/core/Mage/Oauth/controllers/Adminhtml/Oauth/AuthorizeController.php app/code/core/Mage/Oauth/controllers/Adminhtml/Oauth/AuthorizeController.php
index a7f4655..915c430 100644
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
index 372b66a..845176a 100644
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
index 11c116e..2e2c47a 100644
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
index 55079d4..7528e42 100644
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
index 5ec085c..2f6c22c 100644
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
index 41702d2..2d83fe6 100644
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
index 51b8240..7f55c9a 100644
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
index 0118fc4..a622cbf 100644
--- app/design/frontend/base/default/template/checkout/cart.phtml
+++ app/design/frontend/base/default/template/checkout/cart.phtml
@@ -97,7 +97,7 @@
                     <tr>
                         <td colspan="50" class="a-right">
                             <?php if($this->getContinueShoppingUrl()): ?>
-                                <button type="button" title="<?php echo $this->__('Continue Shopping') ?>" class="button btn-continue" onclick="setLocation('<?php echo $this->getContinueShoppingUrl() ?>')"><span><span><?php echo $this->__('Continue Shopping') ?></span></span></button>
+                                <button type="button" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Continue Shopping')) ?>" class="button btn-continue" onclick="setLocation('<?php echo Mage::helper('core')->quoteEscape($this->getContinueShoppingUrl()) ?>')"><span><span><?php echo $this->__('Continue Shopping') ?></span></span></button>
                             <?php endif; ?>
                             <button type="submit" name="update_cart_action" value="update_qty" title="<?php echo $this->__('Update Shopping Cart'); ?>" class="button btn-update"><span><span><?php echo $this->__('Update Shopping Cart'); ?></span></span></button>
                             <button type="submit" name="update_cart_action" value="empty_cart" title="<?php echo $this->__('Clear Shopping Cart'); ?>" class="button btn-empty" id="empty_cart_button"><span><span><?php echo $this->__('Clear Shopping Cart'); ?></span></span></button>
diff --git app/design/frontend/base/default/template/checkout/cart/noItems.phtml app/design/frontend/base/default/template/checkout/cart/noItems.phtml
index 558deab..ce02dda 100644
--- app/design/frontend/base/default/template/checkout/cart/noItems.phtml
+++ app/design/frontend/base/default/template/checkout/cart/noItems.phtml
@@ -31,6 +31,6 @@
     <?php echo $this->getMessagesBlock()->getGroupedHtml() ?>
     <?php echo $this->getChildHtml('checkout_cart_empty_widget'); ?>
     <p><?php echo $this->__('You have no items in your shopping cart.') ?></p>
-    <p><?php echo $this->__('Click <a href="%s">here</a> to continue shopping.', $this->getContinueShoppingUrl()) ?></p>
+    <p><?php echo $this->__('Click <a href="%s">here</a> to continue shopping.', Mage::helper('core')->quoteEscape($this->getContinueShoppingUrl())) ?></p>
     <?php echo $this->getChildHtml('shopping.cart.table.after'); ?>
 </div>
diff --git app/design/frontend/base/default/template/checkout/onepage/failure.phtml app/design/frontend/base/default/template/checkout/onepage/failure.phtml
index fb2ee41..944a5c4 100644
--- app/design/frontend/base/default/template/checkout/onepage/failure.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/failure.phtml
@@ -29,4 +29,4 @@
 </div>
 <?php if ($this->getRealOrderId()) : ?><p><?php echo $this->__('Order #') . $this->getRealOrderId() ?></p><?php endif ?>
 <?php if ($error = $this->getErrorMessage()) : ?><p><?php echo $error ?></p><?php endif ?>
-<p><?php echo $this->__('Click <a href="%s">here</a> to continue shopping.', $this->getContinueShoppingUrl()) ?></p>
+<p><?php echo $this->__('Click <a href="%s">here</a> to continue shopping.', Mage::helper('core')->quoteEscape($this->getContinueShoppingUrl())) ?></p>
diff --git app/design/frontend/base/default/template/rss/order/details.phtml app/design/frontend/base/default/template/rss/order/details.phtml
index 21cec8d..f17a648 100644
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
index 37b3e70..eab364d 100644
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
diff --git app/design/frontend/enterprise/default/template/checkout/cart.phtml app/design/frontend/enterprise/default/template/checkout/cart.phtml
index 9994cf3..cac1a71 100644
--- app/design/frontend/enterprise/default/template/checkout/cart.phtml
+++ app/design/frontend/enterprise/default/template/checkout/cart.phtml
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
diff --git downloader/lib/.htaccess downloader/lib/.htaccess
new file mode 100644
index 0000000..93169e4
--- /dev/null
+++ downloader/lib/.htaccess
@@ -0,0 +1,2 @@
+Order deny,allow
+Deny from all
diff --git errors/processor.php errors/processor.php
index 6f1f204..3db371e 100644
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
