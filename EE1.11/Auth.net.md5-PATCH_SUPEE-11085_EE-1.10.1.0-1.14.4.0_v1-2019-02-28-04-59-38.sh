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


SUPEE-11085 | EE_1.14.4.0 | v1 | 66a7f527682b49c83c7fe133bbf07a0acdd3e00b | Wed Feb 27 20:10:36 2019 +0000 | a3013c00db8dffad73f38d3b8701bf725920bb0a..66a7f527682b49c83c7fe133bbf07a0acdd3e00b

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Authorizenet/Model/Directpost.php app/code/core/Mage/Authorizenet/Model/Directpost.php
index 71c51759b7a..9f3626b7e2f 100644
--- app/code/core/Mage/Authorizenet/Model/Directpost.php
+++ app/code/core/Mage/Authorizenet/Model/Directpost.php
@@ -389,9 +389,11 @@ class Mage_Authorizenet_Model_Directpost extends Mage_Paygate_Model_Authorizenet
     public function validateResponse()
     {
         $response = $this->getResponse();
-        //md5 check
-        if (!$this->getConfigData('trans_md5') || !$this->getConfigData('login') ||
-            !$response->isValidHash($this->getConfigData('trans_md5'), $this->getConfigData('login'))
+        $hashConfigKey = !empty($response->getData('x_SHA2_Hash')) ? 'signature_key' : 'trans_md5';
+
+        //hash check
+        if (!$this->getConfigData($hashConfigKey)
+            || !$response->isValidHash($this->getConfigData($hashConfigKey), $this->getConfigData('login'))
         ) {
             Mage::throwException(
                 Mage::helper('authorizenet')->__('Response hash validation failed. Transaction declined.')
diff --git app/code/core/Mage/Authorizenet/Model/Directpost/Request.php app/code/core/Mage/Authorizenet/Model/Directpost/Request.php
index f5162247e18..c2c0a717bc4 100644
--- app/code/core/Mage/Authorizenet/Model/Directpost/Request.php
+++ app/code/core/Mage/Authorizenet/Model/Directpost/Request.php
@@ -36,8 +36,15 @@ class Mage_Authorizenet_Model_Directpost_Request extends Varien_Object
     protected $_transKey = null;
 
     /**
+     * Hexadecimal signature key.
+     *
+     * @var string
+     */
+    protected $_signatureKey = '';
+
+    /**
      * Return merchant transaction key.
-     * Needed to generate sign.
+     * Needed to generate MD5 sign.
      *
      * @return string
      */
@@ -48,7 +55,7 @@ class Mage_Authorizenet_Model_Directpost_Request extends Varien_Object
 
     /**
      * Set merchant transaction key.
-     * Needed to generate sign.
+     * Needed to generate MD5 sign.
      *
      * @param string $transKey
      * @return Mage_Authorizenet_Model_Directpost_Request
@@ -60,7 +67,7 @@ class Mage_Authorizenet_Model_Directpost_Request extends Varien_Object
     }
 
     /**
-     * Generates the fingerprint for request.
+     * Generates the MD5 fingerprint for request.
      *
      * @param string $merchantApiLoginId
      * @param string $merchantTransactionKey
@@ -73,19 +80,19 @@ class Mage_Authorizenet_Model_Directpost_Request extends Varien_Object
     {
         if (phpversion() >= '5.1.2') {
             return hash_hmac("md5",
-                $merchantApiLoginId . "^" .
-                $fpSequence . "^" .
-                $fpTimestamp . "^" .
-                $amount . "^" .
+                $merchantApiLoginId . '^' .
+                $fpSequence . '^' .
+                $fpTimestamp . '^' .
+                $amount . '^' .
                 $currencyCode, $merchantTransactionKey
             );
         }
 
         return bin2hex(mhash(MHASH_MD5,
-            $merchantApiLoginId . "^" .
-            $fpSequence . "^" .
-            $fpTimestamp . "^" .
-            $amount . "^" .
+            $merchantApiLoginId . '^' .
+            $fpSequence . '^' .
+            $fpTimestamp . '^' .
+            $amount . '^' .
             $currencyCode, $merchantTransactionKey
         ));
     }
@@ -110,6 +117,7 @@ class Mage_Authorizenet_Model_Directpost_Request extends Varien_Object
             ->setXRelayUrl($paymentMethod->getRelayUrl());
 
         $this->_setTransactionKey($paymentMethod->getConfigData('trans_key'));
+        $this->_setSignatureKey($paymentMethod->getConfigData('signature_key'));
         return $this;
     }
 
@@ -178,16 +186,78 @@ class Mage_Authorizenet_Model_Directpost_Request extends Varien_Object
     public function signRequestData()
     {
         $fpTimestamp = time();
-        $hash = $this->generateRequestSign(
-            $this->getXLogin(),
-            $this->_getTransactionKey(),
-            $this->getXAmount(),
-            $this->getXCurrencyCode(),
-            $this->getXFpSequence(),
-            $fpTimestamp
-        );
+
+        if (!empty($this->_getSignatureKey())) {
+            $hash = $this->_generateSha2RequestSign(
+                $this->getXLogin(),
+                $this->_getSignatureKey(),
+                $this->getXAmount(),
+                $this->getXCurrencyCode(),
+                $this->getXFpSequence(),
+                $fpTimestamp
+            );
+        } else {
+            $hash = $this->generateRequestSign(
+                $this->getXLogin(),
+                $this->_getTransactionKey(),
+                $this->getXAmount(),
+                $this->getXCurrencyCode(),
+                $this->getXFpSequence(),
+                $fpTimestamp
+            );
+        }
+
         $this->setXFpTimestamp($fpTimestamp);
         $this->setXFpHash($hash);
         return $this;
     }
+
+    /**
+     * Generates the SHA2 fingerprint for request.
+     *
+     * @param string $merchantApiLoginId
+     * @param string $merchantSignatureKey
+     * @param string $amount
+     * @param string $currencyCode
+     * @param string $fpSequence An invoice number or random number.
+     * @param string $fpTimestamp
+     * @return string The fingerprint.
+     */
+    protected function _generateSha2RequestSign(
+        $merchantApiLoginId,
+        $merchantSignatureKey,
+        $amount,
+        $currencyCode,
+        $fpSequence,
+        $fpTimestamp
+    ) {
+        $message = $merchantApiLoginId . '^' . $fpSequence . '^' . $fpTimestamp . '^' . $amount . '^' . $currencyCode;
+
+        return strtoupper(hash_hmac('sha512', $message, pack('H*', $merchantSignatureKey)));
+    }
+
+    /**
+     * Return merchant hexadecimal signature key.
+     *
+     * Needed to generate SHA2 sign.
+     *
+     * @return string
+     */
+    protected function _getSignatureKey()
+    {
+        return $this->_signatureKey;
+    }
+
+    /**
+     * Set merchant hexadecimal signature key.
+     *
+     * Needed to generate SHA2 sign.
+     *
+     * @param string $signatureKey
+     * @return void
+     */
+    protected function _setSignatureKey($signatureKey)
+    {
+        $this->_signatureKey = $signatureKey;
+    }
 }
diff --git app/code/core/Mage/Authorizenet/Model/Directpost/Response.php app/code/core/Mage/Authorizenet/Model/Directpost/Response.php
index 0024764fc42..2094f9b5199 100644
--- app/code/core/Mage/Authorizenet/Model/Directpost/Response.php
+++ app/code/core/Mage/Authorizenet/Model/Directpost/Response.php
@@ -44,23 +44,31 @@ class Mage_Authorizenet_Model_Directpost_Response extends Varien_Object
      */
     public function generateHash($merchantMd5, $merchantApiLogin, $amount, $transactionId)
     {
-        if (!$amount) {
-            $amount = '0.00';
-        }
         return strtoupper(md5($merchantMd5 . $merchantApiLogin . $transactionId . $amount));
     }
 
     /**
      * Return if is valid order id.
      *
-     * @param string $merchantMd5
+     * @param string $storedHash
      * @param string $merchantApiLogin
      * @return bool
      */
-    public function isValidHash($merchantMd5, $merchantApiLogin)
+    public function isValidHash($storedHash, $merchantApiLogin)
     {
-        return $this->generateHash($merchantMd5, $merchantApiLogin, $this->getXAmount(), $this->getXTransId())
-            == $this->getData('x_MD5_Hash');
+        if (empty($this->getData('x_amount'))) {
+            $this->setData('x_amount', '0.00');
+        }
+
+        if (!empty($this->getData('x_SHA2_Hash'))) {
+            $hash = $this->generateSha2Hash($storedHash);
+            return $hash == $this->getData('x_SHA2_Hash');
+        } elseif (!empty($this->getData('x_MD5_Hash'))) {
+            $hash = $this->generateHash($storedHash, $merchantApiLogin, $this->getXAmount(), $this->getXTransId());
+            return $hash == $this->getData('x_MD5_Hash');
+        }
+
+        return false;
     }
 
     /**
@@ -72,4 +80,54 @@ class Mage_Authorizenet_Model_Directpost_Response extends Varien_Object
     {
         return $this->getXResponseCode() == Mage_Authorizenet_Model_Directpost::RESPONSE_CODE_APPROVED;
     }
+
+    /**
+     * Generates an SHA2 hash to compare against AuthNet's.
+     *
+     * @param string $signatureKey
+     * @return string
+     * @see https://support.authorize.net/s/article/MD5-Hash-End-of-Life-Signature-Key-Replacement
+     */
+    public function generateSha2Hash($signatureKey)
+    {
+        $hashFields = [
+            'x_trans_id',
+            'x_test_request',
+            'x_response_code',
+            'x_auth_code',
+            'x_cvv2_resp_code',
+            'x_cavv_response',
+            'x_avs_code',
+            'x_method',
+            'x_account_number',
+            'x_amount',
+            'x_company',
+            'x_first_name',
+            'x_last_name',
+            'x_address',
+            'x_city',
+            'x_state',
+            'x_zip',
+            'x_country',
+            'x_phone',
+            'x_fax',
+            'x_email',
+            'x_ship_to_company',
+            'x_ship_to_first_name',
+            'x_ship_to_last_name',
+            'x_ship_to_address',
+            'x_ship_to_city',
+            'x_ship_to_state',
+            'x_ship_to_zip',
+            'x_ship_to_country',
+            'x_invoice_num',
+        ];
+
+        $message = '^';
+        foreach ($hashFields as $field) {
+            $message .= ($this->getData($field) ? $this->getData($field) : '') . '^';
+        }
+
+        return strtoupper(hash_hmac('sha512', $message, pack('H*', $signatureKey)));
+    }
 }
diff --git app/code/core/Mage/Authorizenet/etc/config.xml app/code/core/Mage/Authorizenet/etc/config.xml
index 3d8cb93dc92..07d6b98fc72 100644
--- app/code/core/Mage/Authorizenet/etc/config.xml
+++ app/code/core/Mage/Authorizenet/etc/config.xml
@@ -150,6 +150,7 @@
                 <test>1</test>
                 <title>Credit Card Direct Post (Authorize.net)</title>
                 <trans_key backend_model="adminhtml/system_config_backend_encrypted"/>
+                <signature_key backend_model="adminhtml/system_config_backend_encrypted"/>
                 <trans_md5 backend_model="adminhtml/system_config_backend_encrypted"/>
                 <allowspecific>0</allowspecific>
                 <currency>USD</currency>
diff --git app/code/core/Mage/Authorizenet/etc/system.xml app/code/core/Mage/Authorizenet/etc/system.xml
index a77de3463b4..d21ddb51044 100644
--- app/code/core/Mage/Authorizenet/etc/system.xml
+++ app/code/core/Mage/Authorizenet/etc/system.xml
@@ -81,6 +81,15 @@
                             <show_in_website>1</show_in_website>
                             <show_in_store>0</show_in_store>
                         </trans_key>
+                        <signature_key translate="label">
+                            <label>Signature Key</label>
+                            <frontend_type>obscure</frontend_type>
+                            <backend_model>adminhtml/system_config_backend_encrypted</backend_model>
+                            <sort_order>55</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>1</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </signature_key>
                         <trans_md5 translate="label">
                             <label>Merchant MD5</label>
                             <frontend_type>obscure</frontend_type>
