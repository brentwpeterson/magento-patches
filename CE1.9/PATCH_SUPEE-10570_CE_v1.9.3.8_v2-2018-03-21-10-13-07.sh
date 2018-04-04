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


SUPEE-10570_CE_v1.9.3.8 | CE_1.9.3.8 | v1 | 9d4a4788d8c8380da1937c223301b4f70e643b57 | Fri Mar 16 13:10:50 2018 +0200 | ce-1.9.3.8-dev

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Adminhtml/controllers/CustomerController.php app/code/core/Mage/Adminhtml/controllers/CustomerController.php
index c7ef678..d490dd6 100644
--- app/code/core/Mage/Adminhtml/controllers/CustomerController.php
+++ app/code/core/Mage/Adminhtml/controllers/CustomerController.php
@@ -333,7 +333,6 @@ class Mage_Adminhtml_CustomerController extends Mage_Adminhtml_Controller_Action
                 // Force new customer confirmation
                 if ($isNewCustomer) {
                     $customer->setPassword($data['account']['password']);
-                    $customer->setPasswordCreatedAt(time());
                     $customer->setForceConfirmed(true);
                     if ($customer->getPassword() == 'auto') {
                         $sendPassToEmail = true;
diff --git app/code/core/Mage/Core/Model/Session/Abstract/Varien.php app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
index 490fcda..b27205e 100644
--- app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
+++ app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
@@ -33,7 +33,6 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
     const VALIDATOR_HTTP_VIA_KEY                = 'http_via';
     const VALIDATOR_REMOTE_ADDR_KEY             = 'remote_addr';
     const VALIDATOR_SESSION_EXPIRE_TIMESTAMP    = 'session_expire_timestamp';
-    const VALIDATOR_PASSWORD_CREATE_TIMESTAMP   = 'password_create_timestamp';
     const SECURE_COOKIE_CHECK_KEY               = '_secure_cookie_check';
 
     /**
@@ -395,16 +394,6 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
     }
 
     /**
-     * Use password creation timestamp in validator key
-     *
-     * @return bool
-     */
-    public function useValidateSessionPasswordTimestamp()
-    {
-        return true;
-    }
-
-    /**
      * Retrieve skip User Agent validation strings (Flash etc)
      *
      * @return array
@@ -481,14 +470,6 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
             $this->_data[self::VALIDATOR_KEY][self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP]
                 = $validatorData[self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP];
         }
-        if ($this->useValidateSessionPasswordTimestamp()
-            && isset($validatorData[self::VALIDATOR_PASSWORD_CREATE_TIMESTAMP])
-            && isset($sessionData[self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP])
-            && $validatorData[self::VALIDATOR_PASSWORD_CREATE_TIMESTAMP]
-            > $sessionData[self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP] - $this->getCookie()->getLifetime()
-        ) {
-            return false;
-        }
 
         return true;
     }
@@ -525,11 +506,6 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
 
         $parts[self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP] = time() + $this->getCookie()->getLifetime();
 
-        if (isset($this->_data['visitor_data']['customer_id'])) {
-            $parts[self::VALIDATOR_PASSWORD_CREATE_TIMESTAMP] =
-                Mage::helper('customer')->getPasswordTimestamp($this->_data['visitor_data']['customer_id']);
-        }
-
         return $parts;
     }
 
diff --git app/code/core/Mage/Customer/Helper/Data.php app/code/core/Mage/Customer/Helper/Data.php
index 1016c6c..436107e 100644
--- app/code/core/Mage/Customer/Helper/Data.php
+++ app/code/core/Mage/Customer/Helper/Data.php
@@ -723,23 +723,6 @@ class Mage_Customer_Helper_Data extends Mage_Core_Helper_Abstract
     }
 
     /**
-     * Get customer password creation timestamp or customer account creation timestamp
-     *
-     * @param $customerId
-     * @return int
-     */
-    public function getPasswordTimestamp($customerId)
-    {
-        /** @var $customer Mage_Customer_Model_Customer */
-        $customer = Mage::getModel('customer/customer')
-            ->setWebsiteId(Mage::app()->getStore()->getWebsiteId())
-            ->load((int)$customerId);
-        $passwordCreatedAt = $customer->getPasswordCreatedAt();
-
-        return is_null($passwordCreatedAt) ? $customer->getCreatedAtTimestamp() : $passwordCreatedAt;
-    }
-
-    /**
      * Create SOAP client based on VAT validation service WSDL
      *
      * @param boolean $trace
diff --git app/code/core/Mage/Customer/Model/Resource/Customer.php app/code/core/Mage/Customer/Model/Resource/Customer.php
index e783dd8..bae08ac 100644
--- app/code/core/Mage/Customer/Model/Resource/Customer.php
+++ app/code/core/Mage/Customer/Model/Resource/Customer.php
@@ -235,9 +235,8 @@ class Mage_Customer_Model_Resource_Customer extends Mage_Eav_Model_Entity_Abstra
      */
     public function changePassword(Mage_Customer_Model_Customer $customer, $newPassword)
     {
-        $customer->setPassword($newPassword)->setPasswordCreatedAt(time());
+        $customer->setPassword($newPassword);
         $this->saveAttribute($customer, 'password_hash');
-        $this->saveAttribute($customer, 'password_created_at');
         return $this;
     }
 
diff --git app/code/core/Mage/Customer/controllers/AccountController.php app/code/core/Mage/Customer/controllers/AccountController.php
index f29b23a..151d3d4 100644
--- app/code/core/Mage/Customer/controllers/AccountController.php
+++ app/code/core/Mage/Customer/controllers/AccountController.php
@@ -298,7 +298,6 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
 
             if (empty($errors)) {
                 $customer->cleanPasswordsValidationData();
-                $customer->setPasswordCreatedAt(time());
                 $customer->save();
                 $this->_dispatchRegisterSuccess($customer);
                 $this->_successProcessRegistration($customer);
@@ -866,7 +865,6 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             $customer->setRpToken(null);
             $customer->setRpTokenCreatedAt(null);
             $customer->cleanPasswordsValidationData();
-            $customer->setPasswordCreatedAt(time());
             $customer->save();
 
             $this->_getSession()->unsetData(self::TOKEN_SESSION_NAME);
@@ -1011,7 +1009,6 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
 
             try {
                 $customer->cleanPasswordsValidationData();
-                $customer->setPasswordCreatedAt(time());
 
                 // Reset all password reset tokens if all data was sufficient and correct on email change
                 if ($customer->getIsChangeEmail()) {
