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


SUPEE-5341 | EE_1.11.0.0 | v1 | f2b879155e454a19b4c22d109139e4af36e20603 | Thu Feb 5 19:29:29 2015 +0200 | v1.11.0.0..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Enterprise/Logging/Block/Adminhtml/Grid/Filter/Ip.php app/code/core/Enterprise/Logging/Block/Adminhtml/Grid/Filter/Ip.php
index b91cb57..386aea0 100644
--- app/code/core/Enterprise/Logging/Block/Adminhtml/Grid/Filter/Ip.php
+++ app/code/core/Enterprise/Logging/Block/Adminhtml/Grid/Filter/Ip.php
@@ -26,6 +26,7 @@
 
 /**
  * Ip-address grid filter
+ * @deprecated since SUPEE-5341. See Replaced with Enterprise_Logging_Block_Adminhtml_Index_Grid::_ipFilterCallback
  */
 class Enterprise_Logging_Block_Adminhtml_Grid_Filter_Ip extends Mage_Adminhtml_Block_Widget_Grid_Column_Filter_Text
 {
diff --git app/code/core/Enterprise/Logging/Block/Adminhtml/Index/Grid.php app/code/core/Enterprise/Logging/Block/Adminhtml/Index/Grid.php
index 4c0c667..aff4d61 100644
--- app/code/core/Enterprise/Logging/Block/Adminhtml/Index/Grid.php
+++ app/code/core/Enterprise/Logging/Block/Adminhtml/Index/Grid.php
@@ -107,10 +107,10 @@ class Enterprise_Logging_Block_Adminhtml_Index_Grid extends Mage_Adminhtml_Block
             'header'    => Mage::helper('enterprise_logging')->__('IP Address'),
             'index'     => 'ip',
             'type'      => 'text',
-            'filter'    => 'enterprise_logging/adminhtml_grid_filter_ip',
             'renderer'  => 'adminhtml/widget_grid_column_renderer_ip',
             'sortable'  => false,
             'width'     => 125,
+            'filter_condition_callback' => array($this, '_ipFilterCallback'),
         ));
 
         $this->addColumn('user', array(
@@ -173,5 +173,16 @@ class Enterprise_Logging_Block_Adminhtml_Index_Grid extends Mage_Adminhtml_Block
         return $this;
     }
 
-
+    /**
+     * Add filter by ip
+     *
+     * @param Enterprise_Logging_Model_Resource_Event_Collection $collection
+     * @param Mage_Adminhtml_Block_Widget_Grid_Column $column
+     */
+    protected function _ipFilterCallback(
+        Enterprise_Logging_Model_Resource_Event_Collection $collection,
+        Mage_Adminhtml_Block_Widget_Grid_Column $column
+    ) {
+        $collection->addIpFilter($column->getFilter()->getValue());
+    }
 }
diff --git app/code/core/Enterprise/Logging/Model/Resource/Event/Collection.php app/code/core/Enterprise/Logging/Model/Resource/Event/Collection.php
index 1471bed..521edb7 100755
--- app/code/core/Enterprise/Logging/Model/Resource/Event/Collection.php
+++ app/code/core/Enterprise/Logging/Model/Resource/Event/Collection.php
@@ -52,4 +52,24 @@ class Enterprise_Logging_Model_Resource_Event_Collection extends Mage_Core_Model
     {
         return parent::getSelectCountSql()->resetJoinLeft();
     }
+
+
+    /**
+     * Add IP filter to collection
+     *
+     * @param string $value
+     * @return Enterprise_Logging_Model_Resource_Event_Collection
+     */
+    public function addIpFilter($value)
+    {
+        if (preg_match('/^(\d+\.){3}\d+$/', $value)) {
+            return $this->addFieldToFilter('ip', ip2long($value));
+        }
+        $condition = $this->getConnection()->prepareSqlCondition(
+            Mage::getResourceHelper('enterprise_logging')->getInetNtoaExpr('ip'),
+            array('like' => Mage::getResourceHelper('core')->addLikeEscape($value, array('position' => 'any')))
+        );
+        $this->getSelect()->where($condition);
+        return $this;
+    }
 }
diff --git app/code/core/Mage/Admin/Model/Observer.php app/code/core/Mage/Admin/Model/Observer.php
index 23e243a..f22eba1 100644
--- app/code/core/Mage/Admin/Model/Observer.php
+++ app/code/core/Mage/Admin/Model/Observer.php
@@ -37,6 +37,10 @@ class Mage_Admin_Model_Observer
     {
         $session  = Mage::getSingleton('admin/session');
         /* @var $session Mage_Admin_Model_Session */
+
+        /**
+         * @var $request Mage_Core_Controller_Request_Http
+         */
         $request = Mage::app()->getRequest();
         $user = $session->getUser();
 
@@ -44,7 +48,7 @@ class Mage_Admin_Model_Observer
             $request->setDispatched(true);
         }
         else {
-            if($user) {
+            if ($user) {
                 $user->reload();
             }
             if (!$user || !$user->getId()) {
@@ -55,14 +59,15 @@ class Mage_Admin_Model_Observer
                     $user = $session->login($username, $password, $request);
                     $request->setPost('login', null);
                 }
-                if (!$request->getParam('forwarded')) {
+                if (!$request->getInternallyForwarded()) {
+                    $request->setInternallyForwarded();
                     if ($request->getParam('isIframe')) {
                         $request->setParam('forwarded', true)
                             ->setControllerName('index')
                             ->setActionName('deniedIframe')
                             ->setDispatched(false);
                     }
-                    elseif($request->getParam('isAjax')) {
+                    elseif ($request->getParam('isAjax')) {
                         $request->setParam('forwarded', true)
                             ->setControllerName('index')
                             ->setActionName('deniedJson')
diff --git app/code/core/Mage/Core/Controller/Request/Http.php app/code/core/Mage/Core/Controller/Request/Http.php
index 368f392..951b8f0 100644
--- app/code/core/Mage/Core/Controller/Request/Http.php
+++ app/code/core/Mage/Core/Controller/Request/Http.php
@@ -76,6 +76,13 @@ class Mage_Core_Controller_Request_Http extends Zend_Controller_Request_Http
     protected $_beforeForwardInfo = array();
 
     /**
+     * Flag for recognizing if request internally forwarded
+     *
+     * @var bool
+     */
+    protected $_internallyForwarded = false;
+
+    /**
      * Returns ORIGINAL_PATH_INFO.
      * This value is calculated instead of reading PATH_INFO
      * directly from $_SERVER due to cross-platform differences.
@@ -530,4 +537,26 @@ class Mage_Core_Controller_Request_Http extends Zend_Controller_Request_Http
         }
         return false;
     }
+
+    /**
+     * Define that request was forwarded internally
+     *
+     * @param boolean $flag
+     * @return Mage_Core_Controller_Request_Http
+     */
+    public function setInternallyForwarded($flag = true)
+    {
+        $this->_internallyForwarded = (bool)$flag;
+        return $this;
+    }
+
+    /**
+     * Checks if request was forwarded internally
+     *
+     * @return bool
+     */
+    public function getInternallyForwarded()
+    {
+        return $this->_internallyForwarded;
+    }
 }
diff --git lib/Varien/Db/Adapter/Pdo/Mysql.php lib/Varien/Db/Adapter/Pdo/Mysql.php
index 0e5d4e6..8f16141 100644
--- lib/Varien/Db/Adapter/Pdo/Mysql.php
+++ lib/Varien/Db/Adapter/Pdo/Mysql.php
@@ -2595,10 +2595,6 @@ class Varien_Db_Adapter_Pdo_Mysql extends Zend_Db_Adapter_Pdo_Mysql implements V
 
         $query = '';
         if (is_array($condition)) {
-            if (isset($condition['field_expr'])) {
-                $fieldName = str_replace('#?', $this->quoteIdentifier($fieldName), $condition['field_expr']);
-                unset($condition['field_expr']);
-            }
             $key = key(array_intersect_key($condition, $conditionKeyMap));
 
             if (isset($condition['from']) || isset($condition['to'])) {
