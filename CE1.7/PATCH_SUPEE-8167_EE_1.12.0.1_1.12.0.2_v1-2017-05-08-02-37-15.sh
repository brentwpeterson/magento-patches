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


SUPEE-8167 | EE_1.12.0.2 | v1 | b1be28f9cd8c2ecba2aa403e59ad9e3d2855eb95 | Thu May 4 13:52:13 2017 +0300 | 8d12ea6fe564b6dc9ed1affb6de990f81aca3796..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Paypal/Model/Ipn.php app/code/core/Mage/Paypal/Model/Ipn.php
index 730d09b1c0f..3c30874d0a4 100644
--- app/code/core/Mage/Paypal/Model/Ipn.php
+++ app/code/core/Mage/Paypal/Model/Ipn.php
@@ -36,6 +36,20 @@ class Mage_Paypal_Model_Ipn
      */
     const DEFAULT_LOG_FILE = 'paypal_unknown_ipn.log';
 
+    /**
+     * Default postback endpoint URL.
+     *
+     * @var string
+     */
+    const DEFAULT_POSTBACK_URL = 'https://ipnpb.paypal.com/cgi-bin/webscr';
+
+    /**
+     * Sandbox postback endpoint URL.
+     *
+     * @var string
+     */
+    const SANDBOX_POSTBACK_URL = 'https://ipnpb.sandbox.paypal.com/cgi-bin/webscr';
+
     /*
      * @param Mage_Sales_Model_Order
      */
@@ -130,6 +144,8 @@ class Mage_Paypal_Model_Ipn
      */
     protected function _postBack(Zend_Http_Client_Adapter_Interface $httpAdapter)
     {
+            $url = $this->_getPostbackUrl();
+
             $sReq = '';
             foreach ($this->_request as $k => $v) {
                 $sReq .= '&'.$k.'='.urlencode($v);
@@ -137,10 +153,10 @@ class Mage_Paypal_Model_Ipn
             $sReq .= "&cmd=_notify-validate";
             $sReq = substr($sReq, 1);
             $this->_debugData['postback'] = $sReq;
-            $this->_debugData['postback_to'] = $this->_config->getPaypalUrl();
+            $this->_debugData['postback_to'] = $url;
 
             $httpAdapter->setConfig(array('verifypeer' => $this->_config->verifyPeer));
-            $httpAdapter->write(Zend_Http_Client::POST, $this->_config->getPaypalUrl(), '1.1', array(), $sReq);
+            $httpAdapter->write(Zend_Http_Client::POST, $url, '1.1', array(), $sReq);
             try {
                 $response = $httpAdapter->read();
             } catch (Exception $e) {
@@ -158,6 +174,16 @@ class Mage_Paypal_Model_Ipn
     }
 
     /**
+     * Get postback endpoint URL.
+     *
+     * @return string
+     */
+    protected function _getPostbackUrl()
+    {
+        return $this->_config->sandboxFlag ? self::SANDBOX_POSTBACK_URL : self::DEFAULT_POSTBACK_URL;
+    }
+
+    /**
      * Load and validate order, instantiate proper configuration
      *
      *
