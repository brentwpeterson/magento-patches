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


SUPEE-11314_EE_11200_REBUILD | EE_1.12.0.0 | v1 | bf3773cc1f0b5486a9534c64b106aaa3bd96b05c | Tue May 5 19:28:53 2020 +0000 | 37d9e0d87ca9eae7227cab9eb95f4258975bbb8b..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Enterprise/Pci/Model/Encryption.php app/code/core/Enterprise/Pci/Model/Encryption.php
index 84194dd72f4..d1524665a2c 100644
--- app/code/core/Enterprise/Pci/Model/Encryption.php
+++ app/code/core/Enterprise/Pci/Model/Encryption.php
@@ -31,15 +31,6 @@
  */
 class Enterprise_Pci_Model_Encryption extends Mage_Core_Model_Encryption
 {
-    const HASH_VERSION_MD5     = 0;
-    const HASH_VERSION_SHA256  = 1;
-    const HASH_VERSION_SHA512  = 2;
-
-    /**
-     * Encryption method bcrypt
-     */
-    const HASH_VERSION_LATEST = 3;
-
     const CIPHER_BLOWFISH     = 0;
     const CIPHER_RIJNDAEL_128 = 1;
     const CIPHER_RIJNDAEL_256 = 2;
@@ -78,23 +69,6 @@ class Enterprise_Pci_Model_Encryption extends Mage_Core_Model_Encryption
         return $version;
     }
 
-    /**
-     * Validate hash against all supported versions.
-     *
-     * Priority is by newer version.
-     *
-     * @param string $password
-     * @param string $hash
-     * @return bool
-     */
-    public function validateHash($password, $hash)
-    {
-        return $this->validateHashByVersion($password, $hash, self::HASH_VERSION_LATEST)
-            || $this->validateHashByVersion($password, $hash, self::HASH_VERSION_SHA512)
-            || $this->validateHashByVersion($password, $hash, self::HASH_VERSION_SHA256)
-            || $this->validateHashByVersion($password, $hash, self::HASH_VERSION_MD5);
-    }
-
     /**
      * Hash a string
      *
diff --git app/code/core/Enterprise/Pci/Model/Observer.php app/code/core/Enterprise/Pci/Model/Observer.php
index 6a18b6feb6a..6a457843fd0 100644
--- app/code/core/Enterprise/Pci/Model/Observer.php
+++ app/code/core/Enterprise/Pci/Model/Observer.php
@@ -112,15 +112,18 @@ class Enterprise_Pci_Model_Observer
             }
         }
 
-        // upgrade admin password
-        if (!Mage::helper('core')->getEncryptor()->validateHashByVersion(
-            $password,
-            $user->getPassword(),
-            Mage::helper('core')->getVersionHash(Mage::helper('core')->getEncryptor()))
+        if (
+            !(bool) $user->getPasswordUpgraded()
+            && !Mage::helper('core')->getEncryptor()->validateHashByVersion(
+                $password,
+                $user->getPassword(),
+                Enterprise_Pci_Model_Encryption::HASH_VERSION_SHA256
+            )
         ) {
             Mage::getModel('admin/user')->load($user->getId())
                 ->setNewPassword($password)->setForceNewPassword(true)
                 ->save();
+            $user->setPasswordUpgraded(true);
         }
     }
 
@@ -152,10 +155,17 @@ class Enterprise_Pci_Model_Observer
     {
         $apiKey = $observer->getEvent()->getApiKey();
         $model  = $observer->getEvent()->getModel();
-        $coreHelper = Mage::helper('core');
-        $currentVersionHash = $coreHelper->getVersionHash($coreHelper->getEncryptor());
-        if (!$coreHelper->getEncryptor()->validateHashByVersion($apiKey, $model->getApiKey(), $currentVersionHash)) {
+        $coreHelper = $this->_getCoreHelper();
+        if (
+            !(bool) $model->getApiPasswordUpgraded()
+            && !$coreHelper->getEncryptor()->validateHashByVersion(
+                $apiKey,
+                $model->getApiKey(),
+                Enterprise_Pci_Model_Encryption::HASH_VERSION_SHA256
+            )
+        ) {
             Mage::getModel('api/user')->load($model->getId())->setNewApiKey($apiKey)->save();
+            $model->setApiPasswordUpgraded(true);
         }
     }
 
@@ -180,7 +190,6 @@ class Enterprise_Pci_Model_Observer
             Enterprise_Pci_Model_Encryption::HASH_VERSION_SHA512,
             Enterprise_Pci_Model_Encryption::HASH_VERSION_LATEST,
         ];
-        $latestVersionHash = $helper->getVersionHash($encryptor);
         $currentVersionHash = null;
         foreach ($hashVersionArray as $hashVersion) {
             if ($encryptor->validateHashByVersion($password, $model->getPasswordHash(), $hashVersion)) {
@@ -188,7 +197,7 @@ class Enterprise_Pci_Model_Observer
                 break;
             }
         }
-        if ($latestVersionHash !== $currentVersionHash) {
+        if (Enterprise_Pci_Model_Encryption::HASH_VERSION_SHA256 !== $currentVersionHash) {
             $model->changePassword($password, false);
         }
     }
diff --git app/code/core/Mage/Admin/Model/Observer.php app/code/core/Mage/Admin/Model/Observer.php
index b9f6b817fc8..98d3b5dea13 100644
--- app/code/core/Mage/Admin/Model/Observer.php
+++ app/code/core/Mage/Admin/Model/Observer.php
@@ -123,4 +123,34 @@ class Mage_Admin_Model_Observer
     public function actionPostDispatchAdmin($event)
     {
     }
+
+    /**
+     * Validate admin password and upgrade hash version
+     *
+     * @param Varien_Event_Observer $observer
+     */
+    public function actionAdminAuthenticate($observer)
+    {
+        $password = $observer->getEvent()->getPassword();
+        $user = $observer->getEvent()->getUser();
+        $authResult = $observer->getEvent()->getResult();
+
+        if (!$authResult) {
+            return;
+        }
+
+        if (
+            !(bool) $user->getPasswordUpgraded()
+            && !Mage::helper('core')->getEncryptor()->validateHashByVersion(
+                $password,
+                $user->getPassword(),
+                Mage_Core_Model_Encryption::HASH_VERSION_SHA256
+            )
+        ) {
+            Mage::getModel('admin/user')->load($user->getId())
+                ->setNewPassword($password)->setForceNewPassword(true)
+                ->save();
+            $user->setPasswordUpgraded(true);
+        }
+    }
 }
diff --git app/code/core/Mage/Admin/Model/Session.php app/code/core/Mage/Admin/Model/Session.php
index dc53ebaa4d3..99166cf6299 100644
--- app/code/core/Mage/Admin/Model/Session.php
+++ app/code/core/Mage/Admin/Model/Session.php
@@ -35,6 +35,13 @@
 class Mage_Admin_Model_Session extends Mage_Core_Model_Session_Abstract
 {
 
+    /**
+     * Session admin SID config path
+     *
+     * @const
+     */
+    const XML_PATH_ALLOW_SID_FOR_ADMIN_AREA = 'web/session/use_admin_sid';
+
     /**
      * Whether it is the first page after successfull login
      *
@@ -107,7 +114,12 @@ class Mage_Admin_Model_Session extends Mage_Core_Model_Session_Abstract
         $user = $this->getUser();
         if ($user) {
             $extraData = $user->getExtra();
-            if (isset($extraData['indirect_login']) && $this->getIndirectLogin()) {
+            if (
+                !is_null(Mage::app()->getRequest()->getParam('SID'))
+                && !$this->allowAdminSid()
+                || isset($extraData['indirect_login'])
+                && $this->getIndirectLogin()
+            ) {
                 $this->unsetData('user');
                 $this->setIndirectLogin(false);
             }
@@ -299,4 +311,14 @@ class Mage_Admin_Model_Session extends Mage_Core_Model_Session_Abstract
             $request->setParam('messageSent', true);
         }
     }
+
+    /**
+     * Check is allowed to use SID for admin area
+     *
+     * @return bool
+     */
+    protected function allowAdminSid()
+    {
+        return (bool) Mage::getStoreConfig(self::XML_PATH_ALLOW_SID_FOR_ADMIN_AREA);
+    }
 }
diff --git app/code/core/Mage/Admin/Model/User.php app/code/core/Mage/Admin/Model/User.php
index b08fb11b7e1..1ebecf86db4 100644
--- app/code/core/Mage/Admin/Model/User.php
+++ app/code/core/Mage/Admin/Model/User.php
@@ -462,7 +462,7 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
      */
     protected function _getEncodedPassword($password)
     {
-        return Mage::helper('core')->getHashPassword($password, self::HASH_SALT_LENGTH);
+        return Mage::helper('core')->getHash($password, self::HASH_SALT_LENGTH);
     }
 
     /**
diff --git app/code/core/Mage/Admin/etc/config.xml app/code/core/Mage/Admin/etc/config.xml
index 42ff8d9fb2a..4b5fcc99a33 100644
--- app/code/core/Mage/Admin/etc/config.xml
+++ app/code/core/Mage/Admin/etc/config.xml
@@ -79,6 +79,16 @@
                 <class>Mage_Admin_Block</class>
             </admin>
         </blocks>
+        <events>
+            <admin_user_authenticate_after>
+                <observers>
+                    <admin_user_login>
+                        <class>Mage_Admin_Model_Observer</class>
+                        <method>actionAdminAuthenticate</method>
+                    </admin_user_login>
+                </observers>
+            </admin_user_authenticate_after>
+        </events>
     </global>
     <default>
         <admin>
diff --git app/code/core/Mage/Api/Model/User.php app/code/core/Mage/Api/Model/User.php
index 199225b1a21..6036af7571a 100644
--- app/code/core/Mage/Api/Model/User.php
+++ app/code/core/Mage/Api/Model/User.php
@@ -248,7 +248,7 @@ class Mage_Api_Model_User extends Mage_Core_Model_Abstract
 
     protected function _getEncodedApiKey($apiKey)
     {
-        return Mage::helper('core')->getHashPassword($apiKey, Mage_Admin_Model_User::HASH_SALT_LENGTH);
+        return Mage::helper('core')->getHash($apiKey, Mage_Admin_Model_User::HASH_SALT_LENGTH);
     }
 
 
diff --git app/code/core/Mage/Api2/Model/Observer.php app/code/core/Mage/Api2/Model/Observer.php
index f3c1b390c54..733608ac459 100644
--- app/code/core/Mage/Api2/Model/Observer.php
+++ app/code/core/Mage/Api2/Model/Observer.php
@@ -83,4 +83,26 @@ class Mage_Api2_Model_Observer
 
         return $this;
     }
+
+    /**
+     * Upgrade API key hash when api user has logged in
+     *
+     * @param Varien_Event_Observer $observer
+     */
+    public function upgradeApiKey($observer)
+    {
+        $apiKey = $observer->getEvent()->getApiKey();
+        $model = $observer->getEvent()->getModel();
+        if (
+            !(bool) $model->getApiPasswordUpgraded()
+            && !Mage::helper('core')->getEncryptor()->validateHashByVersion(
+                $apiKey,
+                $model->getApiKey(),
+                Mage_Core_Model_Encryption::HASH_VERSION_SHA256
+            )
+        ) {
+            Mage::getModel('api/user')->load($model->getId())->setNewApiKey($apiKey)->save();
+            $model->setApiPasswordUpgraded(true);
+        }
+    }
 }
diff --git app/code/core/Mage/Api2/etc/config.xml app/code/core/Mage/Api2/etc/config.xml
index 6880e135623..e5fd803bc0a 100644
--- app/code/core/Mage/Api2/etc/config.xml
+++ app/code/core/Mage/Api2/etc/config.xml
@@ -91,6 +91,14 @@
                     </api2>
                 </observers>
             </admin_user_save_after>
+            <api_user_authenticated>
+                <observers>
+                    <api2_upgrade_key>
+                        <class>Mage_Api2_Model_Observer</class>
+                        <method>upgradeApiKey</method>
+                    </api2_upgrade_key>
+                </observers>
+            </api_user_authenticated>
         </events>
         <api2>
             <auth_adapters>
diff --git app/code/core/Mage/Core/Model/Encryption.php app/code/core/Mage/Core/Model/Encryption.php
index 046dc9bba60..a920f427483 100644
--- app/code/core/Mage/Core/Model/Encryption.php
+++ app/code/core/Mage/Core/Model/Encryption.php
@@ -34,6 +34,7 @@
 class Mage_Core_Model_Encryption
 {
     const HASH_VERSION_MD5    = 0;
+    const HASH_VERSION_SHA256 = 1;
     const HASH_VERSION_SHA512 = 2;
 
     /**
@@ -79,7 +80,9 @@ class Mage_Core_Model_Encryption
         if (is_integer($salt)) {
             $salt = $this->_helper->getRandomString($salt);
         }
-        return $salt === false ? $this->hash($password) : $this->hash($salt . $password) . ':' . $salt;
+        return $salt === false
+            ? $this->hash($password)
+            : $this->hash($salt . $password, self::HASH_VERSION_SHA256) . ':' . $salt;
     }
 
     /**
@@ -110,6 +113,8 @@ class Mage_Core_Model_Encryption
     {
         if (self::HASH_VERSION_LATEST === $version && $version === $this->_helper->getVersionHash($this)) {
             return password_hash($data, PASSWORD_DEFAULT);
+        } elseif (self::HASH_VERSION_SHA256 == $version) {
+            return hash('sha256', $data);
         } elseif (self::HASH_VERSION_SHA512 == $version) {
             return hash('sha512', $data);
         }
@@ -128,6 +133,7 @@ class Mage_Core_Model_Encryption
     {
         return $this->validateHashByVersion($password, $hash, self::HASH_VERSION_LATEST)
             || $this->validateHashByVersion($password, $hash, self::HASH_VERSION_SHA512)
+            || $this->validateHashByVersion($password, $hash, self::HASH_VERSION_SHA256)
             || $this->validateHashByVersion($password, $hash, self::HASH_VERSION_MD5);
     }
 
diff --git app/code/core/Mage/Core/etc/config.xml app/code/core/Mage/Core/etc/config.xml
index 5b02674e30d..37b3cefc922 100644
--- app/code/core/Mage/Core/etc/config.xml
+++ app/code/core/Mage/Core/etc/config.xml
@@ -368,6 +368,7 @@
                 <use_http_x_forwarded_for>0</use_http_x_forwarded_for>
                 <use_http_user_agent>0</use_http_user_agent>
                 <use_frontend_sid>1</use_frontend_sid>
+                <use_admin_sid>0</use_admin_sid>
             </session>
             <browser_capabilities>
                 <cookies>1</cookies>
diff --git app/code/core/Mage/Customer/Model/Customer.php app/code/core/Mage/Customer/Model/Customer.php
index 3a81e4dd4d9..16a05c93890 100644
--- app/code/core/Mage/Customer/Model/Customer.php
+++ app/code/core/Mage/Customer/Model/Customer.php
@@ -386,7 +386,7 @@ class Mage_Customer_Model_Customer extends Mage_Core_Model_Abstract
      */
     public function hashPassword($password, $salt = null)
     {
-        return Mage::helper('core')->getHashPassword(trim($password), (bool) $salt ? $salt : Mage_Admin_Model_User::HASH_SALT_LENGTH);
+        return Mage::helper('core')->getHash(trim($password), (bool) $salt ? $salt : Mage_Admin_Model_User::HASH_SALT_LENGTH);
     }
 
     /**
diff --git app/code/core/Mage/Customer/Model/Observer.php app/code/core/Mage/Customer/Model/Observer.php
index 2480807492e..5cbde58a1b9 100644
--- app/code/core/Mage/Customer/Model/Observer.php
+++ app/code/core/Mage/Customer/Model/Observer.php
@@ -218,4 +218,44 @@ class Mage_Customer_Model_Observer
         );
         $customer->save();
     }
+
+    /**
+     * Clear customer flow password table
+     *
+     */
+    public function deleteCustomerFlowPassword()
+    {
+        $connection = Mage::getSingleton('core/resource')->getConnection('write');
+        $condition  = array('requested_date < ?' => Mage::getModel('core/date')->date(null, '-1 day'));
+        $connection->delete($connection->getTableName('customer_flowpassword'), $condition);
+    }
+
+    /**
+     * Upgrade customer password hash when customer has logged in
+     *
+     * @param Varien_Event_Observer $observer
+     */
+    public function actionUpgradeCustomerPassword($observer)
+    {
+        $password = $observer->getEvent()->getPassword();
+        $model = $observer->getEvent()->getModel();
+
+        $encryptor = Mage::helper('core')->getEncryptor();
+        $hashVersionArray = [
+            Mage_Core_Model_Encryption::HASH_VERSION_MD5,
+            Mage_Core_Model_Encryption::HASH_VERSION_SHA256,
+            Mage_Core_Model_Encryption::HASH_VERSION_SHA512,
+            Mage_Core_Model_Encryption::HASH_VERSION_LATEST,
+        ];
+        $currentVersionHash = null;
+        foreach ($hashVersionArray as $hashVersion) {
+            if ($encryptor->validateHashByVersion($password, $model->getPasswordHash(), $hashVersion)) {
+                $currentVersionHash = $hashVersion;
+                break;
+            }
+        }
+        if (Mage_Core_Model_Encryption::HASH_VERSION_SHA256 !== $currentVersionHash) {
+            $model->changePassword($password, false);
+        }
+    }
 }
diff --git app/code/core/Mage/Customer/etc/config.xml app/code/core/Mage/Customer/etc/config.xml
index e86c48b46bd..c32bb490f86 100644
--- app/code/core/Mage/Customer/etc/config.xml
+++ app/code/core/Mage/Customer/etc/config.xml
@@ -435,6 +435,14 @@
                     </customer_addres_after_save_viv_observer>
                 </observers>
             </customer_address_save_after>
+            <customer_customer_authenticated>
+                <observers>
+                    <customer_upgrade_password>
+                        <class>Mage_Customer_Model_Observer</class>
+                        <method>actionUpgradeCustomerPassword</method>
+                    </customer_upgrade_password>
+                </observers>
+            </customer_customer_authenticated>
         </events>
     </global>
     <adminhtml>
diff --git app/code/core/Mage/Dataflow/Model/Profile.php app/code/core/Mage/Dataflow/Model/Profile.php
index 35aabf57424..9416d1518f1 100644
--- app/code/core/Mage/Dataflow/Model/Profile.php
+++ app/code/core/Mage/Dataflow/Model/Profile.php
@@ -179,7 +179,10 @@ class Mage_Dataflow_Model_Profile extends Mage_Core_Model_Abstract
                     $uploader->save($path);
                     $uploadFile = $uploader->getUploadedFileName();
 
-                    if ($_FILES['file_' . ($index + 1)]['type'] == "text/csv") {
+                    if (
+                        $_FILES['file_' . ($index + 1)]['type'] == "text/csv"
+                        || $_FILES['file_' . ($index + 1)]['type'] == "application/vnd.ms-excel"
+                    ) {
                         $fileData = $csvParser->getData($path . $uploadFile);
                         $fileData = array_shift($fileData);
                     } else {
diff --git app/design/frontend/base/default/template/catalog/product/compare/list.phtml app/design/frontend/base/default/template/catalog/product/compare/list.phtml
index b3975719d1a..d98c87fa798 100644
--- app/design/frontend/base/default/template/catalog/product/compare/list.phtml
+++ app/design/frontend/base/default/template/catalog/product/compare/list.phtml
@@ -29,7 +29,10 @@
     <h1><?php echo $this->__('Compare Products') ?></h1>
     <a href="#" onclick="window.print(); return false;" class="link-print"><?php echo $this->__('Print This Page') ?></a>
 </div>
-<?php $_total=$this->getItems()->getSize() ?>
+<?php
+$_total = $this->getItems()->getSize();
+$_params = $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey())));
+?>
 <?php if($_total): ?>
     <table class="data-table compare-table" id="product_comparison">
     <?php $_i=0 ?>
@@ -65,13 +68,30 @@
                     <?php echo $this->getReviewsSummaryHtml($_item, 'short') ?>
                     <?php echo $this->getPriceHtml($_item, true, '-compare-list-top') ?>
                     <?php if($_item->isSaleable()): ?>
-                        <p><button type="button" title="<?php echo $this->__('Add to Cart') ?>" class="button btn-cart" onclick="setPLocation('<?php echo $this->helper('catalog/product_compare')->getAddToCartUrl($_item) ?>', true)"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button></p>
+                        <button type="button"
+                                title="<?php echo Mage::helper('core')->quoteEscape($this->__('Add to Cart')) ?>"
+                                class="button btn-cart"
+                                onclick="customFormSubmitToParent(
+                                        '<?php echo $this->helper('catalog/product_compare')->getAddToCartUrlCustom($_item, false) ?>',
+                                        '<?php echo $_params ?>',
+                                        'post')">
+                            <span><span><?php echo $this->__('Add to Cart') ?></span></span>
+                        </button>
                     <?php else: ?>
                         <p class="availability out-of-stock"><span><?php echo $this->__('Out of stock') ?></span></p>
                     <?php endif; ?>
                     <?php if ($this->helper('wishlist')->isAllow()) : ?>
                         <ul class="add-to-links">
-                            <li><a href="<?php echo $this->getAddToWishlistUrl($_item) ?>" class="link-wishlist" onclick="setPLocation(this.href, true)"><?php echo $this->__('Add to Wishlist') ?></a></li>
+                            <li>
+                                <a href="#"
+                                   class="link-wishlist"
+                                   onclick="customFormSubmit(
+                                           '<?php echo $this->getAddToWishlistUrlCustom($_item, false) ?>',
+                                           '<?php echo $_params ?>',
+                                           'post')">
+                                    <?php echo $this->__('Add to Wishlist') ?>
+                                </a>
+                            </li>
                         </ul>
                     <?php endif; ?>
                 </td>
@@ -118,13 +138,32 @@
                 <td>
                     <?php echo $this->getPriceHtml($_item, true, '-compare-list-bottom') ?>
                     <?php if($_item->isSaleable()): ?>
-                        <p><button type="button" title="<?php echo $this->__('Add to Cart') ?>" class="button btn-cart" onclick="setPLocation('<?php echo $this->helper('catalog/product_compare')->getAddToCartUrl($_item) ?>', true)"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button></p>
+                        <p>
+                            <button type="button"
+                                    title="<?php echo Mage::helper('core')->quoteEscape($this->__('Add to Cart')) ?>"
+                                    class="button btn-cart"
+                                    onclick="customFormSubmitToParent(
+                                            '<?php echo $this->helper('catalog/product_compare')->getAddToCartUrlCustom($_item, false) ?>',
+                                            '<?php echo $_params ?>',
+                                            'post')">
+                                <span><span><?php echo $this->__('Add to Cart') ?></span></span>
+                            </button>
+                        </p>
                     <?php else: ?>
                         <p class="availability out-of-stock"><span><?php echo $this->__('Out of stock') ?></span></p>
                     <?php endif; ?>
                     <?php if ($this->helper('wishlist')->isAllow()) : ?>
                         <ul class="add-to-links">
-                            <li><a href="<?php echo $this->getAddToWishlistUrl($_item);?>" class="link-wishlist" onclick="setPLocation(this.href, true)"><?php echo $this->__('Add to Wishlist') ?></a></li>
+                            <li>
+                                <a href="#"
+                                   class="link-wishlist"
+                                   onclick="customFormSubmit(
+                                           '<?php echo $this->getAddToWishlistUrlCustom($_item, false) ?>',
+                                           '<?php echo $_params ?>',
+                                           'post')">
+                                    <?php echo $this->__('Add to Wishlist') ?>
+                                </a>
+                            </li>
                         </ul>
                     <?php endif; ?>
                 </td>
diff --git app/design/frontend/base/default/template/catalog/product/list.phtml app/design/frontend/base/default/template/catalog/product/list.phtml
index ee002334524..b11a0f1419f 100644
--- app/design/frontend/base/default/template/catalog/product/list.phtml
+++ app/design/frontend/base/default/template/catalog/product/list.phtml
@@ -59,7 +59,17 @@
                     <?php endif; ?>
                     <?php echo $this->getPriceHtml($_product, true) ?>
                     <?php if($_product->isSaleable()): ?>
-                        <p><button type="button" title="<?php echo $this->__('Add to Cart') ?>" class="button btn-cart" onclick="setLocation('<?php echo $this->getAddToCartUrl($_product) ?>')"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button></p>
+                        <p class="action">
+                            <button type="button"
+                                    title="<?php echo $this->quoteEscape($this->__('Add to Cart')) ?>"
+                                    class="button btn-cart"
+                                    onclick="customFormSubmit(
+                                            '<?php echo $this->getAddToCartUrlCustom($_product, array(), false) ?>',
+                                            '<?php echo $_params ?>',
+                                            'post')">
+                                <span><span><?php echo $this->__('Add to Cart') ?></span></span>
+                            </button>
+                        </p>
                     <?php else: ?>
                         <p class="availability out-of-stock"><span><?php echo $this->__('Out of stock') ?></span></p>
                     <?php endif; ?>
@@ -117,7 +127,15 @@
                 <?php echo $this->getPriceHtml($_product, true) ?>
                 <div class="actions">
                     <?php if($_product->isSaleable()): ?>
-                        <button type="button" title="<?php echo $this->__('Add to Cart') ?>" class="button btn-cart" onclick="setLocation('<?php echo $this->getAddToCartUrl($_product) ?>')"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button>
+                        <button type="button"
+                                title="<?php echo $this->quoteEscape($this->__('Add to Cart')) ?>"
+                                class="button btn-cart"
+                                onclick="customFormSubmit(
+                                        '<?php echo $this->getAddToCartUrlCustom($_product, array(), false) ?>',
+                                        '<?php echo $_params ?>',
+                                        'post')">
+                            <span><span><?php echo $this->__('Add to Cart') ?></span></span>
+                        </button>
                     <?php else: ?>
                         <p class="availability out-of-stock"><span><?php echo $this->__('Out of stock') ?></span></p>
                     <?php endif; ?>
diff --git app/design/frontend/base/default/template/catalog/product/list/related.phtml app/design/frontend/base/default/template/catalog/product/list/related.phtml
index c1ff883c7c5..aad44090eb7 100644
--- app/design/frontend/base/default/template/catalog/product/list/related.phtml
+++ app/design/frontend/base/default/template/catalog/product/list/related.phtml
@@ -45,7 +45,14 @@
                         <p class="product-name"><a href="<?php echo $_item->getProductUrl() ?>"><?php echo $this->htmlEscape($_item->getName()) ?></a></p>
                         <?php echo $this->getPriceHtml($_item, true, '-related') ?>
                         <?php if ($this->helper('wishlist')->isAllow()) : ?>
-                            <a href="<?php echo $this->getAddToWishlistUrl($_item) ?>" class="link-wishlist"><?php echo $this->__('Add to Wishlist') ?></a>
+                            <a href="#"
+                               class="link-wishlist"
+                               onclick="customFormSubmit(
+                                       '<?php echo $this->getAddToWishlistUrlCustom($_item, false) ?>',
+                                       '<?php echo $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey()))) ?>',
+                                       'post')">
+                                <?php echo $this->__('Add to Wishlist') ?>
+                            </a>
                         <?php endif; ?>
                     </div>
                 </div>
diff --git app/design/frontend/base/default/template/catalog/product/view.phtml app/design/frontend/base/default/template/catalog/product/view.phtml
index 4c018c398c4..c33e21ada56 100644
--- app/design/frontend/base/default/template/catalog/product/view.phtml
+++ app/design/frontend/base/default/template/catalog/product/view.phtml
@@ -39,8 +39,11 @@
 <div id="messages_product_view"><?php echo $this->getMessagesBlock()->getGroupedHtml() ?></div>
 <div class="product-view">
     <div class="product-essential">
-    <form action="<?php echo $this->getSubmitUrl($_product) ?>" method="post" id="product_addtocart_form"<?php if($_product->getOptions()): ?> enctype="multipart/form-data"<?php endif; ?>>
-        <?php echo $this->getBlockHtml('formkey') ?>
+        <form action="<?php echo $this->getSubmitUrlCustom($_product, array('_secure' => $this->_isSecure()), false) ?>"
+              method="post"
+              id="product_addtocart_form"
+            <?php if ($_product->getOptions()): ?> enctype="multipart/form-data" <?php endif; ?>>
+            <?php echo $this->getBlockHtml('formkey') ?>
         <div class="no-display">
             <input type="hidden" name="product" value="<?php echo $_product->getId() ?>" />
             <input type="hidden" name="related_product" id="related-products-field" value="" />
diff --git app/design/frontend/base/default/template/catalog/product/view/addto.phtml app/design/frontend/base/default/template/catalog/product/view/addto.phtml
index 2e42b06ce25..a47e50299b4 100644
--- app/design/frontend/base/default/template/catalog/product/view/addto.phtml
+++ app/design/frontend/base/default/template/catalog/product/view/addto.phtml
@@ -26,16 +26,34 @@
 ?>
 
 <?php $_product = $this->getProduct(); ?>
-<?php $_wishlistSubmitUrl = $this->helper('wishlist')->getAddUrl($_product); ?>
 
 <ul class="add-to-links">
 <?php if ($this->helper('wishlist')->isAllow()) : ?>
-    <li><a href="<?php echo $_wishlistSubmitUrl ?>" onclick="productAddToCartForm.submitLight(this, this.href); return false;" class="link-wishlist"><?php echo $this->__('Add to Wishlist') ?></a></li>
+    <li>
+        <a href="#"
+           onclick="customFormSubmit(
+                   '<?php echo $this->helper('wishlist')->getAddUrlWithCustomParams($_product, array(), false) ?>',
+                   '<?php echo $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey()))) ?>',
+                   'post')"
+           class="link-wishlist">
+            <?php echo $this->__('Add to Wishlist') ?>
+        </a>
+    </li>
 <?php endif; ?>
 <?php
-    $_compareUrl = $this->helper('catalog/product_compare')->getAddUrl($_product);
+    $_compareUrl = $this->helper('catalog/product_compare')->getAddUrlCustom($_product, false);
 ?>
 <?php if($_compareUrl) : ?>
-    <li><span class="separator">|</span> <a href="<?php echo $_compareUrl ?>" class="link-compare"><?php echo $this->__('Add to Compare') ?></a></li>
+    <li>
+        <span class="separator">|</span>
+        <a href="#"
+           class="link-compare"
+           onclick="customFormSubmit(
+                   '<?php echo $_compareUrl ?>',
+                   '<?php echo $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey()))) ?>',
+                   'post')">
+            <?php echo $this->__('Add to Compare') ?>
+        </a>
+    </li>
 <?php endif; ?>
 </ul>
diff --git app/design/frontend/base/default/template/catalog/product/widget/new/content/new_grid.phtml app/design/frontend/base/default/template/catalog/product/widget/new/content/new_grid.phtml
index 4ccf2a4b6fc..3da940be24c 100644
--- app/design/frontend/base/default/template/catalog/product/widget/new/content/new_grid.phtml
+++ app/design/frontend/base/default/template/catalog/product/widget/new/content/new_grid.phtml
@@ -25,6 +25,7 @@
  */
 ?>
 <?php if (($_products = $this->getProductCollection()) && $_products->getSize()): ?>
+<?php $_params = $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey()))) ?>
 <div class="widget widget-new-products">
     <div class="widget-title">
         <h2><?php echo $this->__('New Products') ?></h2>
@@ -42,16 +43,43 @@
                 <?php echo $this->getPriceHtml($_product, true, '-widget-new-grid') ?>
                 <div class="actions">
                     <?php if ($_product->isSaleable()): ?>
-                        <button type="button" title="<?php echo $this->__('Add to Cart') ?>" class="button btn-cart" onclick="setLocation('<?php echo $this->getAddToCartUrl($_product) ?>')"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button>
+                        <button type="button"
+                                title="<?php echo Mage::helper('core')->quoteEscape($this->__('Add to Cart')) ?>"
+                                class="button btn-cart"
+                                onclick="customFormSubmit(
+                                        '<?php echo $this->getAddToCartUrlCustom($_product, array(), false) ?>',
+                                        '<?php echo $_params ?>',
+                                        'post')">
+                            <span><span><?php echo $this->__('Add to Cart') ?></span></span>
+                        </button>
                     <?php else: ?>
                         <p class="availability out-of-stock"><span><?php echo $this->__('Out of stock') ?></span></p>
                     <?php endif; ?>
                     <ul class="add-to-links">
                         <?php if ($this->helper('wishlist')->isAllow()) : ?>
-                            <li><a href="<?php echo $this->getAddToWishlistUrl($_product) ?>" class="link-wishlist"><?php echo $this->__('Add to Wishlist') ?></a></li>
+                            <li>
+                                <a href="#"
+                                   class="link-wishlist"
+                                   onclick="customFormSubmit(
+                                           '<?php echo $this->getAddToWishlistUrlCustom($_product, false) ?>',
+                                           '<?php echo $_params ?>',
+                                           'post')">
+                                    <?php echo $this->__('Add to Wishlist') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
-                        <?php if($_compareUrl=$this->getAddToCompareUrl($_product)): ?>
-                            <li><span class="separator">|</span> <a href="<?php echo $_compareUrl ?>" class="link-compare"><?php echo $this->__('Add to Compare') ?></a></li>
+                        <?php if ($_compareUrl = $this->getAddToCompareUrlCustom($_product, false)) : ?>
+                            <li>
+                                <span class="separator">|</span>
+                                <a href="#"
+                                   class="link-compare"
+                                   onclick="customFormSubmit(
+                                           '<?php echo $_compareUrl ?>',
+                                           '<?php echo $_params ?>',
+                                           'post')">
+                                    <?php echo $this->__('Add to Compare') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
                     </ul>
                 </div>
diff --git app/design/frontend/base/default/template/catalog/product/widget/new/content/new_list.phtml app/design/frontend/base/default/template/catalog/product/widget/new/content/new_list.phtml
index 325a32253d6..24417308c91 100644
--- app/design/frontend/base/default/template/catalog/product/widget/new/content/new_list.phtml
+++ app/design/frontend/base/default/template/catalog/product/widget/new/content/new_list.phtml
@@ -25,6 +25,7 @@
  */
 ?>
 <?php if (($_products = $this->getProductCollection()) && $_products->getSize()): ?>
+<?php $_params = $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey()))); ?>
 <div class="widget widget-new-products">
     <div class="widget-title">
         <h2><?php echo $this->__('New Products') ?></h2>
@@ -40,16 +41,43 @@
                         <?php echo $this->getReviewsSummaryHtml($_product, 'short') ?>
                         <?php echo $this->getPriceHtml($_product, true, '-widget-new-list') ?>
                         <?php if ($_product->isSaleable()): ?>
-                            <button type="button" title="<?php echo $this->__('Add to Cart') ?>" class="button btn-cart" onclick="setLocation('<?php echo $this->getAddToCartUrl($_product) ?>')"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button>
+                            <button type="button"
+                                    title="<?php echo Mage::helper('core')->quoteEscape($this->__('Add to Cart')) ?>"
+                                    class="button btn-cart"
+                                    onclick="customFormSubmit(
+                                            '<?php echo $this->getAddToCartUrlCustom($_product, array(), false) ?>',
+                                            '<?php echo $_params ?>',
+                                            'post')">
+                                <span><span><?php echo $this->__('Add to Cart') ?></span></span>
+                            </button>
                         <?php else: ?>
                             <p class="availability out-of-stock"><span><?php echo $this->__('Out of stock') ?></span></p>
                         <?php endif; ?>
                         <ul class="add-to-links">
                             <?php if ($this->helper('wishlist')->isAllow()) : ?>
-                                <li><a href="<?php echo $this->getAddToWishlistUrl($_product) ?>" class="link-wishlist"><?php echo $this->__('Add to Wishlist') ?></a></li>
+                                <li>
+                                    <a href="#"
+                                       class="link-wishlist"
+                                       onclick="customFormSubmit(
+                                               '<?php echo $this->getAddToWishlistUrlCustom($_product, false) ?>',
+                                               '<?php echo $_params ?>',
+                                               'post')">
+                                        <?php echo $this->__('Add to Wishlist') ?>
+                                    </a>
+                                </li>
                             <?php endif; ?>
-                            <?php if($_compareUrl=$this->getAddToCompareUrl($_product)): ?>
-                                <li><span class="separator">|</span> <a href="<?php echo $_compareUrl ?>" class="link-compare"><?php echo $this->__('Add to Compare') ?></a></li>
+                            <?php if ($_compareUrl = $this->getAddToCompareUrlCustom($_product, false)) : ?>
+                                <li>
+                                    <span class="separator">|</span>
+                                    <a href="#"
+                                       class="link-compare"
+                                       onclick="customFormSubmit(
+                                               '<?php echo $_compareUrl ?>',
+                                               '<?php echo $_params ?>',
+                                               'post')">
+                                        <?php echo $this->__('Add to Compare') ?>
+                                    </a>
+                                </li>
                             <?php endif; ?>
                         </ul>
                     </div>
diff --git app/design/frontend/base/default/template/checkout/cart/crosssell.phtml app/design/frontend/base/default/template/checkout/cart/crosssell.phtml
index 7317c879f25..d6e684cbaca 100644
--- app/design/frontend/base/default/template/checkout/cart/crosssell.phtml
+++ app/design/frontend/base/default/template/checkout/cart/crosssell.phtml
@@ -32,6 +32,7 @@
  */
 ?>
 <?php if($this->getItemCount()): ?>
+<?php $_params = $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey()))) ?>
 <div class="crosssell">
     <h2><?php echo $this->__('Based on your selection, you may be interested in the following items:') ?></h2>
     <ul id="crosssell-products-list">
@@ -41,13 +42,40 @@
             <div class="product-details">
                 <h3 class="product-name"><a href="<?php echo $_item->getProductUrl() ?>"><?php echo $this->htmlEscape($_item->getName()) ?></a></h3>
                 <?php echo $this->getPriceHtml($_item, true) ?>
-                <button type="button" title="<?php echo $this->__('Add to Cart') ?>" class="button btn-cart" onclick="setLocation('<?php echo $this->getAddToCartUrl($_item) ?>')"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button>
+                <button type="button"
+                        title="<?php echo Mage::helper('core')->quoteEscape($this->__('Add to Cart')) ?>"
+                        class="button btn-cart"
+                        onclick="customFormSubmit(
+                                '<?php echo $this->getAddToCartUrlCustom($_item, array(), false) ?>',
+                                '<?php echo $_params ?>',
+                                'post')">
+                    <span><span><?php echo $this->__('Add to Cart') ?></span></span>
+                </button>
                 <ul class="add-to-links">
                     <?php if ($this->helper('wishlist')->isAllow()) : ?>
-                        <li><a href="<?php echo $this->getAddToWishlistUrl($_item) ?>" class="link-wishlist"><?php echo $this->__('Add to Wishlist') ?></a></li>
+                        <li>
+                            <a href="#"
+                               class="link-wishlist"
+                               onclick="customFormSubmit(
+                                       '<?php echo $this->getAddToWishlistUrlCustom($_item, false) ?>',
+                                       '<?php echo $_params ?>',
+                                       'post')">
+                                <?php echo $this->__('Add to Wishlist') ?>
+                            </a>
+                        </li>
                     <?php endif; ?>
-                    <?php if($_compareUrl=$this->getAddToCompareUrl($_item)): ?>
-                        <li><span class="separator">|</span> <a href="<?php echo $_compareUrl ?>" class="link-compare"><?php echo $this->__('Add to Compare') ?></a></li>
+                    <?php if ($_compareUrl = $this->getAddToCompareUrlCustom($_item, false)) : ?>
+                        <li>
+                            <span class="separator">|</span>
+                            <a href="#"
+                               class="link-compare"
+                               onclick="customFormSubmit(
+                                       '<?php echo $_compareUrl ?>',
+                                       '<?php echo $_params ?>',
+                                       'post')">
+                                <?php echo $this->__('Add to Compare') ?>
+                            </a>
+                        </li>
                     <?php endif; ?>
                 </ul>
             </div>
diff --git app/design/frontend/base/default/template/checkout/cart/item/default.phtml app/design/frontend/base/default/template/checkout/cart/item/default.phtml
index 573147c4708..03e88c05db3 100644
--- app/design/frontend/base/default/template/checkout/cart/item/default.phtml
+++ app/design/frontend/base/default/template/checkout/cart/item/default.phtml
@@ -28,6 +28,8 @@
 $_item = $this->getItem();
 $isVisibleProduct = $_item->getProduct()->isVisibleInSiteVisibility();
 $canApplyMsrp = Mage::helper('catalog')->canApplyMsrp($_item->getProduct(), Mage_Catalog_Model_Product_Attribute_Source_Msrp_Type::TYPE_BEFORE_ORDER_CONFIRM);
+$_params = $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey())));
+$_deleteUrl = $this->getDeleteUrlCustom(false);
 ?>
 <tr>
     <td><?php if ($this->hasProductUrl()):?><a href="<?php echo $this->getProductUrl() ?>" title="<?php echo $this->htmlEscape($this->getProductName()) ?>" class="product-image"><?php endif;?><img src="<?php echo $this->getProductThumbnail()->resize(75); ?>" width="75" height="75" alt="<?php echo $this->htmlEscape($this->getProductName()) ?>" /><?php if ($this->hasProductUrl()):?></a><?php endif;?></td>
@@ -274,5 +276,12 @@ $canApplyMsrp = Mage::helper('catalog')->canApplyMsrp($_item->getProduct(), Mage
         <?php endif; ?>
     </td>
     <?php endif; ?>
-    <td class="a-center"><a href="<?php echo $this->getDeleteUrl()?>" title="<?php echo $this->__('Remove item')?>" class="btn-remove btn-remove2"><?php echo $this->__('Remove item')?></a></td>
+    <td class="a-center">
+        <a href="#"
+           title="<?php echo Mage::helper('core')->quoteEscape($this->__('Remove Item')) ?>"
+           class="btn-remove btn-remove2"
+           onclick="customFormSubmit('<?php echo $_deleteUrl ?>', '<?php echo $_params ?>', 'post')">
+            <?php echo $this->__('Remove Item') ?>
+        </a>
+    </td>
 </tr>
diff --git app/design/frontend/base/default/template/checkout/cart/shipping.phtml app/design/frontend/base/default/template/checkout/cart/shipping.phtml
index 17708ba9fa7..59e7b941bc6 100644
--- app/design/frontend/base/default/template/checkout/cart/shipping.phtml
+++ app/design/frontend/base/default/template/checkout/cart/shipping.phtml
@@ -79,7 +79,7 @@
         </script>
 
         <?php if (($_shippingRateGroups = $this->getEstimateRates())): ?>
-        <form id="co-shipping-method-form" action="<?php echo $this->getUrl('checkout/cart/estimateUpdatePost') ?>">
+        <form id="co-shipping-method-form" action="<?php echo $this->getUrl('checkout/cart/estimateUpdatePost') ?>" method="post">
             <dl class="sp-methods">
                 <?php foreach ($_shippingRateGroups as $code => $_rates): ?>
                     <dt><?php echo $this->escapeHtml($this->getCarrierName($code)) ?></dt>
diff --git app/design/frontend/base/default/template/checkout/cart/sidebar/default.phtml app/design/frontend/base/default/template/checkout/cart/sidebar/default.phtml
index f6cce5c7513..adc796fa643 100644
--- app/design/frontend/base/default/template/checkout/cart/sidebar/default.phtml
+++ app/design/frontend/base/default/template/checkout/cart/sidebar/default.phtml
@@ -36,7 +36,14 @@
         <span class="product-image"><img src="<?php echo $this->getProductThumbnail()->resize(50, 50)->setWatermarkSize('30x10'); ?>" width="50" height="50" alt="<?php echo $this->htmlEscape($this->getProductName()) ?>" /></span>
     <?php endif; ?>
     <div class="product-details">
-        <a href="<?php echo $this->getDeleteUrl() ?>" title="<?php echo $this->__('Remove This Item') ?>" onclick="return confirm('<?php echo $this->__('Are you sure you would like to remove this item from the shopping cart?') ?>');" class="btn-remove"><?php echo $this->__('Remove This Item') ?></a>
+        <a href="#"
+           title="<?php echo Mage::helper('core')->quoteEscape($this->__('Remove This Item')) ?>"
+           onclick="if (confirm('<?php echo Mage::helper('core')->jsQuoteEscape($this->__('Are you sure you would like to remove this item from the shopping cart?')) ?>')) {
+                   customFormSubmit('<?php echo $this->getDeleteUrlCustom(false) ?>','<?php echo $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey()))) ?>', 'post')
+                   }"
+           class="btn-remove">
+            <?php echo $this->__('Remove This Item') ?>
+        </a>
         <?php if ($isVisibleProduct): ?>
         <a href="<?php echo $this->getConfigureUrl() ?>" title="<?php echo $this->__('Edit item') ?>" class="btn-edit"><?php echo $this->__('Edit item')?></a>
         <?php endif ?>
diff --git app/design/frontend/base/default/template/checkout/onepage/billing.phtml app/design/frontend/base/default/template/checkout/onepage/billing.phtml
index 53383113593..12bcc87bce8 100644
--- app/design/frontend/base/default/template/checkout/onepage/billing.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/billing.phtml
@@ -159,7 +159,15 @@
                     <div class="field">
                         <label for="billing:customer_password" class="required"><em>*</em><?php echo $this->__('Password') ?></label>
                         <div class="input-box">
-                            <input type="password" name="billing[customer_password]" id="billing:customer_password" title="<?php echo $this->__('Password') ?>" class="input-text required-entry validate-password" />
+                            <?php $minPasswordLength = $this->getQuote()->getCustomer()->getMinPasswordLength(); ?>
+                            <input type="password"
+                                   name="billing[customer_password]"
+                                   id="billing:customer_password"
+                                   title="<?php echo Mage::helper('core')->quoteEscape($this->__('Password')) ?>"
+                                   class="input-text required-entry validate-password min-pass-length-<?php echo $minPasswordLength ?>" />
+                            <p class="form-instructions">
+                                <?php echo Mage::helper('customer')->__('The minimum password length is %s', $minPasswordLength) ?>
+                            </p>
                         </div>
                     </div>
                     <div class="field">
diff --git app/design/frontend/base/default/template/checkout/onepage/review/info.phtml app/design/frontend/base/default/template/checkout/onepage/review/info.phtml
index 5cc7170227e..da8ee98a8ca 100644
--- app/design/frontend/base/default/template/checkout/onepage/review/info.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/review/info.phtml
@@ -78,7 +78,7 @@
     </div>
     <script type="text/javascript">
     //<![CDATA[
-        review = new Review('<?php echo $this->getUrl('checkout/onepage/saveOrder', array('form_key' => Mage::getSingleton('core/session')->getFormKey())) ?>', '<?php echo $this->getUrl('checkout/onepage/success') ?>', $('checkout-agreements'));
+        review = new Review('<?php echo $this->getUrl('checkout/onepage/saveOrder') ?>', '<?php echo $this->getUrl('checkout/onepage/success') ?>', $('checkout-agreements'));
     //]]>
     </script>
 </div>
diff --git app/design/frontend/base/default/template/customer/form/changepassword.phtml app/design/frontend/base/default/template/customer/form/changepassword.phtml
index 7a263a17d07..6c8d95f0767 100644
--- app/design/frontend/base/default/template/customer/form/changepassword.phtml
+++ app/design/frontend/base/default/template/customer/form/changepassword.phtml
@@ -42,7 +42,15 @@
             <div class="field">
                 <label for="password" class="required"><em>*</em><?php echo $this->__('New Password') ?></label>
                 <div class="input-box">
-                    <input type="password" title="<?php echo $this->__('New Password') ?>" class="input-text required-entry validate-password" name="password" id="password" />
+                    <?php $minPasswordLength = max((int)$this->getCustomer()->getMinPasswordLength(), Mage_Core_Model_App::ABSOLUTE_MIN_PASSWORD_LENGTH); ?>
+                    <input type="password"
+                           title="<?php echo Mage::helper('core')->quoteEscape($this->__('New Password')) ?>"
+                           class="input-text required-entry validate-password min-pass-length-<?php echo $minPasswordLength ?>"
+                           name="password"
+                           id="password" />
+                    <p class="form-instructions">
+                        <?php echo Mage::helper('customer')->__('The minimum password length is %s', $minPasswordLength) ?>
+                    </p>
                 </div>
             </div>
             <div class="field">
diff --git app/design/frontend/base/default/template/customer/form/edit.phtml app/design/frontend/base/default/template/customer/form/edit.phtml
index 6c0af037397..cbc3a4a8bfe 100644
--- app/design/frontend/base/default/template/customer/form/edit.phtml
+++ app/design/frontend/base/default/template/customer/form/edit.phtml
@@ -71,8 +71,16 @@
             <li class="fields">
                 <div class="field">
                     <label for="password" class="required"><em>*</em><?php echo $this->__('New Password') ?></label>
-                    <div class="input-box">
-                        <input type="password" title="<?php echo $this->__('New Password') ?>" class="input-text validate-password" name="password" id="password" />
+                    <div class="input-box ">
+                        <?php $minPasswordLength = $this->getCustomer()->getMinPasswordLength(); ?>
+                        <input type="password"
+                               title="<?php echo Mage::helper('core')->quoteEscape($this->__('New Password')) ?>"
+                               class="input-text required-entry validate-password min-pass-length-<?php echo $minPasswordLength ?>"
+                               name="password"
+                               id="password" />
+                        <p class="form-instructions">
+                            <?php echo $this->__('The minimum password length is %s', $minPasswordLength) ?>
+                        </p>
                     </div>
                 </div>
                 <div class="field">
diff --git app/design/frontend/base/default/template/customer/form/register.phtml app/design/frontend/base/default/template/customer/form/register.phtml
index db09ecb23f8..01b899584da 100644
--- app/design/frontend/base/default/template/customer/form/register.phtml
+++ app/design/frontend/base/default/template/customer/form/register.phtml
@@ -161,7 +161,15 @@
                     <div class="field">
                         <label for="password" class="required"><em>*</em><?php echo $this->__('Password') ?></label>
                         <div class="input-box">
-                            <input type="password" name="password" id="password" title="<?php echo $this->__('Password') ?>" class="input-text required-entry validate-password" />
+                            <?php $minPasswordLength = $this->getMinPasswordLength(); ?>
+                            <input type="password"
+                                   name="password"
+                                   id="password"
+                                   title="<?php echo Mage::helper('core')->quoteEscape($this->__('Password')) ?>"
+                                   class="input-text required-entry validate-password min-pass-length-<?php echo $minPasswordLength ?>" />
+                            <p class="form-instructions">
+                                <?php echo $this->__('The minimum password length is %s', $minPasswordLength) ?>
+                            </p>
                         </div>
                     </div>
                     <div class="field">
diff --git app/design/frontend/base/default/template/customer/form/resetforgottenpassword.phtml app/design/frontend/base/default/template/customer/form/resetforgottenpassword.phtml
index 1736ff43bdb..a005b8cb056 100644
--- app/design/frontend/base/default/template/customer/form/resetforgottenpassword.phtml
+++ app/design/frontend/base/default/template/customer/form/resetforgottenpassword.phtml
@@ -35,7 +35,14 @@
                 <div class="field">
                     <label for="password" class="required"><em>*</em><?php echo $this->__('New Password'); ?></label>
                     <div class="input-box">
-                        <input type="password" class="input-text required-entry validate-password" name="password" id="password" />
+                        <?php $minPasswordLength = $this->getMinPasswordLength(); ?>
+                        <input type="password"
+                               class="input-text required-entry validate-password min-pass-length-<?php echo $minPasswordLength; ?>"
+                               name="password"
+                               id="password" />
+                        <p class="form-instructions">
+                            <?php echo Mage::helper('customer')->__('The minimum password length is %s', $minPasswordLength); ?>
+                        </p>
                     </div>
                 </div>
                 <div class="field">
diff --git app/design/frontend/base/default/template/downloadable/checkout/cart/item/default.phtml app/design/frontend/base/default/template/downloadable/checkout/cart/item/default.phtml
index 0990eb57dbc..3e8b3edcf6a 100644
--- app/design/frontend/base/default/template/downloadable/checkout/cart/item/default.phtml
+++ app/design/frontend/base/default/template/downloadable/checkout/cart/item/default.phtml
@@ -25,8 +25,10 @@
  */
 ?>
 <?php
-    $_item = $this->getItem();
-    $canApplyMsrp = Mage::helper('catalog')->canApplyMsrp($_item->getProduct(), Mage_Catalog_Model_Product_Attribute_Source_Msrp_Type::TYPE_BEFORE_ORDER_CONFIRM);
+$_item = $this->getItem();
+$canApplyMsrp = Mage::helper('catalog')->canApplyMsrp($_item->getProduct(), Mage_Catalog_Model_Product_Attribute_Source_Msrp_Type::TYPE_BEFORE_ORDER_CONFIRM);
+$_params = $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey())));
+$_deleteUrl = $this->getDeleteUrlCustom(false);
 ?>
 <tr>
     <td><a href="<?php echo $this->getProductUrl() ?>" class="product-image" title="<?php echo $this->htmlEscape($this->getProductName()) ?>"><img src="<?php echo $this->getProductThumbnail()->resize(75); ?>" alt="<?php echo $this->htmlEscape($this->getProductName()) ?>" /></a></td>
@@ -272,6 +274,13 @@
             <?php endif; ?>
         <?php endif; ?>
     </td>
-    <?php endif; ?>
-    <td class="a-center"><a href="<?php echo $this->getDeleteUrl() ?>" title="<?php echo $this->__('Remove Item')?>" class="btn-remove btn-remove2"><?php echo $this->__('Remove Item') ?></a></td>
+<?php endif; ?>
+    <td class="a-center product-cart-remove">
+        <a href="#"
+           title="<?php echo Mage::helper('core')->quoteEscape($this->__('Remove Item')) ?>"
+           class="btn-remove btn-remove2"
+           onclick="customFormSubmit('<?php echo $_deleteUrl ?>', '<?php echo $_params ?>', 'post')">
+            <?php echo $this->__('Remove Item') ?>
+        </a>
+    </td>
 </tr>
diff --git app/design/frontend/base/default/template/persistent/checkout/onepage/billing.phtml app/design/frontend/base/default/template/persistent/checkout/onepage/billing.phtml
index 1b6bdf9cf69..173a698df26 100644
--- app/design/frontend/base/default/template/persistent/checkout/onepage/billing.phtml
+++ app/design/frontend/base/default/template/persistent/checkout/onepage/billing.phtml
@@ -157,7 +157,15 @@
                     <div class="field">
                         <label for="billing:customer_password" class="required"><em>*</em><?php echo $this->__('Password') ?></label>
                         <div class="input-box">
-                            <input type="password" name="billing[customer_password]" id="billing:customer_password" title="<?php echo $this->__('Password') ?>" class="input-text required-entry validate-password" />
+                            <?php $minPasswordLength = $this->getQuote()->getCustomer()->getMinPasswordLength(); ?>
+                            <input type="password"
+                                   name="billing[customer_password]"
+                                   id="billing:customer_password"
+                                   title="<?php echo $this->quoteEscape($this->__('Password')) ?>"
+                                   class="input-text required-entry validate-password min-pass-length-<?php echo $minPasswordLength ?>" />
+                            <p class="form-instructions">
+                                <?php echo Mage::helper('customer')->__('The minimum password length is %s', $minPasswordLength) ?>
+                            </p>
                         </div>
                     </div>
                     <div class="field">
diff --git app/design/frontend/base/default/template/persistent/customer/form/login.phtml app/design/frontend/base/default/template/persistent/customer/form/login.phtml
index 71d4321341c..3b5e6a7529c 100644
--- app/design/frontend/base/default/template/persistent/customer/form/login.phtml
+++ app/design/frontend/base/default/template/persistent/customer/form/login.phtml
@@ -60,7 +60,7 @@
                         <li>
                             <label for="pass" class="required"><em>*</em><?php echo $this->__('Password') ?></label>
                             <div class="input-box">
-                                <input type="password" name="login[password]" class="input-text required-entry validate-password" id="pass" title="<?php echo $this->__('Password') ?>" />
+                                <input type="password" name="login[password]" class="input-text required-entry" id="pass" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Password')) ?>" />
                             </div>
                         </li>
                         <?php echo $this->getChildHtml('form.additional.info'); ?>
diff --git app/design/frontend/base/default/template/persistent/customer/form/register.phtml app/design/frontend/base/default/template/persistent/customer/form/register.phtml
index 56407e8e142..a22702dde92 100644
--- app/design/frontend/base/default/template/persistent/customer/form/register.phtml
+++ app/design/frontend/base/default/template/persistent/customer/form/register.phtml
@@ -158,7 +158,15 @@
                     <div class="field">
                         <label for="password" class="required"><em>*</em><?php echo $this->__('Password') ?></label>
                         <div class="input-box">
-                            <input type="password" name="password" id="password" title="<?php echo $this->__('Password') ?>" class="input-text required-entry validate-password" />
+                            <?php $minPasswordLength = $this->getMinPasswordLength(); ?>
+                            <input type="password"
+                                   name="password"
+                                   id="password"
+                                   title="<?php echo $this->quoteEscape($this->__('Password')) ?>"
+                                   class="input-text required-entry validate-password min-pass-length-<?php echo $minPasswordLength ?>" />
+                            <p class="form-instructions">
+                                <?php echo Mage::helper('customer')->__('The minimum password length is %s', $minPasswordLength) ?>
+                            </p>
                         </div>
                     </div>
                     <div class="field">
diff --git app/design/frontend/base/default/template/reports/widget/compared/content/compared_grid.phtml app/design/frontend/base/default/template/reports/widget/compared/content/compared_grid.phtml
index 82b89893a7e..2aabb2df950 100644
--- app/design/frontend/base/default/template/reports/widget/compared/content/compared_grid.phtml
+++ app/design/frontend/base/default/template/reports/widget/compared/content/compared_grid.phtml
@@ -25,6 +25,7 @@
  */
 ?>
 <?php if ($_products = $this->getRecentlyComparedProducts()): ?>
+<?php $_params = $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey()))); ?>
 <div class="widget widget-compared">
     <div class="widget-title">
         <h2><?php echo $this->__('Recently Compared') ?></h2>
@@ -42,16 +43,43 @@
                 <?php echo $this->getPriceHtml($_product, true, '-widget-compared-grid') ?>
                 <div class="actions">
                     <?php if($_product->isSaleable()): ?>
-                        <button type="button" title="<?php echo $this->__('Add to Cart') ?>" class="button btn-cart" onclick="setLocation('<?php echo $this->getAddToCartUrl($_product) ?>')"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button>
+                        <button type="button"
+                                title="<?php echo Mage::helper('core')->quoteEscape($this->__('Add to Cart')) ?>"
+                                class="button btn-cart"
+                                onclick="customFormSubmit(
+                                        '<?php echo $this->getAddToCartUrlCustom($_product, array(), false) ?>',
+                                        '<?php echo $_params ?>',
+                                        'post')">
+                            <span><span><?php echo $this->__('Add to Cart') ?></span></span>
+                        </button>
                     <?php else: ?>
                             <p class="availability out-of-stock"><span><?php echo $this->__('Out of stock') ?></span></p>
                     <?php endif; ?>
                     <ul class="add-to-links">
                         <?php if ($this->helper('wishlist')->isAllow()) : ?>
-                            <li><a href="<?php echo $this->getAddToWishlistUrl($_product) ?>" class="link-wishlist"><?php echo $this->__('Add to Wishlist') ?></a></li>
+                            <li>
+                                <a href="#"
+                                   class="link-wishlist"
+                                   onclick="customFormSubmit(
+                                           '<?php echo $this->getAddToWishlistUrlCustom($_product, false) ?>',
+                                           '<?php echo $_params ?>',
+                                           'post')">
+                                    <?php echo $this->__('Add to Wishlist') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
-                        <?php if($_compareUrl = $this->getAddToCompareUrl($_product)): ?>
-                            <li><span class="separator">|</span> <a href="<?php echo $_compareUrl ?>" class="link-compare"><?php echo $this->__('Add to Compare') ?></a></li>
+                        <?php if ($_compareUrl = $this->getAddToCompareUrlCustom($_product, false)) : ?>
+                            <li>
+                                <span class="separator">|</span>
+                                <a href="#"
+                                   class="link-compare"
+                                   onclick="customFormSubmit(
+                                           '<?php echo $_compareUrl ?>',
+                                           '<?php echo $_params ?>',
+                                           'post')">
+                                    <?php echo $this->__('Add to Compare') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
                     </ul>
                 </div>
diff --git app/design/frontend/base/default/template/reports/widget/compared/content/compared_list.phtml app/design/frontend/base/default/template/reports/widget/compared/content/compared_list.phtml
index e4e64c1ab37..0c16428fcb4 100644
--- app/design/frontend/base/default/template/reports/widget/compared/content/compared_list.phtml
+++ app/design/frontend/base/default/template/reports/widget/compared/content/compared_list.phtml
@@ -25,6 +25,7 @@
  */
 ?>
 <?php if ($_products = $this->getRecentlyComparedProducts()): ?>
+<?php $_params = $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey()))); ?>
 <div class="widget widget-compared">
     <div class="widget-title">
         <h2><?php echo $this->__('Recently Compared') ?></h2>
@@ -40,16 +41,43 @@
                         <?php echo $this->getReviewsSummaryHtml($_product, 'short') ?>
                         <?php echo $this->getPriceHtml($_product, true, '-widget-compared-list') ?>
                         <?php if($_product->isSaleable()): ?>
-                            <button type="button" title="<?php echo $this->__('Add to Cart') ?>" class="button btn-cart" onclick="setLocation('<?php echo $this->getAddToCartUrl($_product) ?>')"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button>
+                            <button type="button"
+                                    title="<?php echo Mage::helper('core')->quoteEscape($this->__('Add to Cart')) ?>"
+                                    class="button btn-cart"
+                                    onclick="customFormSubmit(
+                                            '<?php echo $this->getAddToCartUrlCustom($_product, array(), false) ?>',
+                                            '<?php echo $_params ?>',
+                                            'post')">
+                                <span><span><?php echo $this->__('Add to Cart') ?></span></span>
+                            </button>
                         <?php else: ?>
                             <p class="availability out-of-stock"><span><?php echo $this->__('Out of stock') ?></span></p>
                         <?php endif; ?>
                         <ul class="add-to-links">
                             <?php if ($this->helper('wishlist')->isAllow()) : ?>
-                                <li><a href="<?php echo $this->getAddToWishlistUrl($_product) ?>" class="link-wishlist"><?php echo $this->__('Add to Wishlist') ?></a></li>
+                                <li>
+                                    <a href="#"
+                                       class="link-wishlist"
+                                       onclick="customFormSubmit(
+                                               '<?php echo $this->getAddToWishlistUrlCustom($_product, false) ?>',
+                                               '<?php echo $_params ?>',
+                                               'post')">
+                                        <?php echo $this->__('Add to Wishlist') ?>
+                                    </a>
+                                </li>
                             <?php endif; ?>
-                            <?php if($_compareUrl = $this->getAddToCompareUrl($_product)): ?>
-                                <li><span class="separator">|</span> <a href="<?php echo $_compareUrl ?>" class="link-compare"><?php echo $this->__('Add to Compare') ?></a></li>
+                            <?php if ($_compareUrl = $this->getAddToCompareUrlCustom($_product, false)) : ?>
+                                <li>
+                                    <span class="separator">|</span>
+                                    <a href="#"
+                                       class="link-compare"
+                                       onclick="customFormSubmit(
+                                               '<?php echo $_compareUrl ?>',
+                                               '<?php echo $_params ?>',
+                                               'post')">
+                                        <?php echo $this->__('Add to Compare') ?>
+                                    </a>
+                                </li>
                             <?php endif; ?>
                         </ul>
                     </div>
diff --git app/design/frontend/base/default/template/reports/widget/viewed/content/viewed_grid.phtml app/design/frontend/base/default/template/reports/widget/viewed/content/viewed_grid.phtml
index c0ac4c6db2d..dc8477d7bd7 100644
--- app/design/frontend/base/default/template/reports/widget/viewed/content/viewed_grid.phtml
+++ app/design/frontend/base/default/template/reports/widget/viewed/content/viewed_grid.phtml
@@ -30,6 +30,7 @@
  */
 ?>
 <?php if ($_products = $this->getRecentlyViewedProducts()): ?>
+<?php $_params = $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey()))) ?>
 <div class="widget widget-viewed">
     <div class="widget-title">
         <h2><?php echo $this->__('Recently Viewed') ?></h2>
@@ -47,16 +48,43 @@
                     <?php echo $this->getPriceHtml($_product, true, '-widget-viewed-grid') ?>
                     <div class="actions">
                         <?php if($_product->isSaleable()): ?>
-                        <button type="button" title="<?php echo $this->__('Add to Cart') ?>" class="button btn-cart" onclick="setLocation('<?php echo $this->getAddToCartUrl($_product) ?>')"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button>
+                            <button type="button"
+                                    title="<?php echo Mage::helper('core')->quoteEscape($this->__('Add to Cart')) ?>"
+                                    class="button btn-cart"
+                                    onclick="customFormSubmit(
+                                            '<?php echo $this->getAddToCartUrlCustom($_product, array(), false) ?>',
+                                            '<?php echo $_params ?>',
+                                            'post')">
+                                <span><span><?php echo $this->__('Add to Cart') ?></span></span>
+                            </button>
                         <?php else: ?>
                                 <p class="availability out-of-stock"><span><?php echo $this->__('Out of stock') ?></span></p>
                         <?php endif; ?>
                         <ul class="add-to-links">
                             <?php if ($this->helper('wishlist')->isAllow()) : ?>
-                                <li><a href="<?php echo $this->getAddToWishlistUrl($_product) ?>" class="link-wishlist"><?php echo $this->__('Add to Wishlist') ?></a></li>
+                                <li>
+                                    <a href="#"
+                                       class="link-wishlist"
+                                       onclick="customFormSubmit(
+                                               '<?php echo $this->getAddToWishlistUrlCustom($_product, false) ?>',
+                                               '<?php echo $_params ?>',
+                                               'post')">
+                                        <?php echo $this->__('Add to Wishlist') ?>
+                                    </a>
+                                </li>
                             <?php endif; ?>
-                            <?php if($_compareUrl = $this->getAddToCompareUrl($_product)): ?>
-                                <li><span class="separator">|</span> <a href="<?php echo $_compareUrl ?>" class="link-compare"><?php echo $this->__('Add to Compare') ?></a></li>
+                            <?php if ($_compareUrl = $this->getAddToCompareUrlCustom($_product, false)) : ?>
+                                <li>
+                                    <span class="separator">|</span>
+                                    <a href="#"
+                                       class="link-compare"
+                                       onclick="customFormSubmit(
+                                               '<?php echo $_compareUrl ?>',
+                                               '<?php echo $_params ?>',
+                                               'post')">
+                                        <?php echo $this->__('Add to Compare') ?>
+                                    </a>
+                                </li>
                             <?php endif; ?>
                         </ul>
                     </div>
diff --git app/design/frontend/base/default/template/reports/widget/viewed/content/viewed_list.phtml app/design/frontend/base/default/template/reports/widget/viewed/content/viewed_list.phtml
index 48029224cb9..8d5efd216ae 100644
--- app/design/frontend/base/default/template/reports/widget/viewed/content/viewed_list.phtml
+++ app/design/frontend/base/default/template/reports/widget/viewed/content/viewed_list.phtml
@@ -30,6 +30,7 @@
  */
 ?>
 <?php if ($_products = $this->getRecentlyViewedProducts()): ?>
+<?php $_params = $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey()))); ?>
 <div class="widget widget-viewed">
     <div class="widget-title">
         <h2><?php echo $this->__('Recently Viewed') ?></h2>
@@ -45,16 +46,43 @@
                         <?php echo $this->getReviewsSummaryHtml($_product, 'short') ?>
                         <?php echo $this->getPriceHtml($_product, true, '-widget-viewed-list') ?>
                         <?php if($_product->isSaleable()): ?>
-                        <button type="button" title="<?php echo $this->__('Add to Cart') ?>" class="button btn-cart" onclick="setLocation('<?php echo $this->getAddToCartUrl($_product) ?>')"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button>
+                            <button type="button"
+                                    title="<?php echo Mage::helper('core')->quoteEscape($this->__('Add to Cart')) ?>"
+                                    class="button btn-cart"
+                                    onclick="customFormSubmit(
+                                            '<?php echo $this->getAddToCartUrlCustom($_product, array(), false) ?>',
+                                            '<?php echo $_params ?>',
+                                            'post')">
+                                <span><span><?php echo $this->__('Add to Cart') ?></span></span>
+                            </button>
                         <?php else: ?>
                                 <p class="availability out-of-stock"><span><?php echo $this->__('Out of stock') ?></span></p>
                         <?php endif; ?>
                         <ul class="add-to-links">
                             <?php if ($this->helper('wishlist')->isAllow()) : ?>
-                                <li><a href="<?php echo $this->getAddToWishlistUrl($_product) ?>" class="link-wishlist"><?php echo $this->__('Add to Wishlist') ?></a></li>
+                                <li>
+                                    <a href="#"
+                                       class="link-wishlist"
+                                       onclick="customFormSubmit(
+                                               '<?php echo $this->getAddToWishlistUrlCustom($_product, false) ?>',
+                                               '<?php echo $_params ?>',
+                                               'post')">
+                                        <?php echo $this->__('Add to Wishlist') ?>
+                                    </a>
+                                </li>
                             <?php endif; ?>
-                            <?php if($_compareUrl = $this->getAddToCompareUrl($_product)): ?>
-                                <li><span class="separator">|</span> <a href="<?php echo $_compareUrl ?>" class="link-compare"><?php echo $this->__('Add to Compare') ?></a></li>
+                            <?php if ($_compareUrl = $this->getAddToCompareUrlCustom($_product, false)) : ?>
+                                <li>
+                                    <span class="separator">|</span>
+                                    <a href="#"
+                                       class="link-compare"
+                                       onclick="customFormSubmit(
+                                               '<?php echo $_compareUrl ?>',
+                                               '<?php echo $_params ?>',
+                                               'post')">
+                                        <?php echo $this->__('Add to Compare') ?>
+                                    </a>
+                                </li>
                             <?php endif; ?>
                         </ul>
                     </div>
diff --git app/design/frontend/base/default/template/wishlist/item/column/cart.phtml app/design/frontend/base/default/template/wishlist/item/column/cart.phtml
index c11ed8cbe57..48dd74dadfe 100644
--- app/design/frontend/base/default/template/wishlist/item/column/cart.phtml
+++ app/design/frontend/base/default/template/wishlist/item/column/cart.phtml
@@ -36,7 +36,12 @@ $product = $item->getProduct();
     <input type="text" class="input-text qty validate-not-negative-number" name="qty[<?php echo $item->getId() ?>]" value="<?php echo $this->getAddToCartQty($item) * 1 ?>" />
 <?php endif; ?>
 <?php if ($product->isSaleable()): ?>
-    <button type="button" title="<?php echo $this->__('Add to Cart') ?>" onclick="addWItemToCart(<?php echo $item->getId()?>);" class="button btn-cart"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button>
+    <button type="button"
+        title="<?php echo Mage::helper('core')->quoteEscape($this->__('Add to Cart')) ?>"
+        onclick="addWItemToCartCustom(<?php echo $item->getId() ?>, false);"
+        class="button btn-cart">
+    <span><span><?php echo $this->__('Add to Cart') ?></span></span>
+    </button>
 <?php else: ?>
     <?php if ($product->getIsSalable()): ?>
         <p class="availability in-stock"><span><?php echo $this->__('In stock') ?></span></p>
diff --git app/design/frontend/base/default/template/wishlist/shared.phtml app/design/frontend/base/default/template/wishlist/shared.phtml
index ef8bedd25eb..938236d2d89 100644
--- app/design/frontend/base/default/template/wishlist/shared.phtml
+++ app/design/frontend/base/default/template/wishlist/shared.phtml
@@ -64,7 +64,16 @@
                             <button type="button" title="<?php echo $this->__('Add to Cart') ?>" onclick="setLocation('<?php echo $this->getSharedItemAddToCartUrl($item) ?>')" class="button btn-cart"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button>
                         <?php endif ?>
                     <?php endif; ?>
-                        <p><a href="<?php echo $this->getAddToWishlistUrl($item) ?>" onclick="setLocation(this.href); return false;" class="link-wishlist"><?php echo $this->__('Add to Wishlist') ?></a></p>
+                        <p>
+                            <a href="#"
+                               onclick="customFormSubmit(
+                                       '<?php echo $this->getAddToWishlistUrlCustom($item, false) ?>',
+                                       '<?php echo $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey()))) ?>',
+                                       'post')"
+                               class="link-wishlist">
+                                <?php echo $this->__('Add to Wishlist') ?>
+                            </a>
+                        </p>
                     </td>
                 </tr>
             <?php endforeach ?>
diff --git app/design/frontend/base/default/template/wishlist/sidebar.phtml app/design/frontend/base/default/template/wishlist/sidebar.phtml
index 22b032f873c..fb629b81b54 100644
--- app/design/frontend/base/default/template/wishlist/sidebar.phtml
+++ app/design/frontend/base/default/template/wishlist/sidebar.phtml
@@ -33,17 +33,29 @@
     <div class="block-content">
     <p class="block-subtitle"><?php echo $this->__('Last Added Items') ?></p>
     <?php if ($this->hasWishlistItems()): ?>
+    <?php $_params = $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey()))); ?>
     <ol class="mini-products-list" id="wishlist-sidebar">
-     <?php foreach ($this->getWishlistItems() as $_item): ?>
+    <?php foreach ($this->getWishlistItems() as $_item): ?>
         <?php $product = $_item->getProduct(); ?>
         <li class="item">
             <a href="<?php echo $this->getProductUrl($_item) ?>" title="<?php echo $this->escapeHtml($product->getName()) ?>" class="product-image"><img src="<?php echo $this->helper('catalog/image')->init($product, 'thumbnail')->resize(50); ?>" width="50" height="50" alt="<?php echo $this->escapeHtml($product->getName()) ?>" /></a>
             <div class="product-details">
-                <a href="<?php echo $this->getItemRemoveUrl($_item) ?>" title="<?php echo $this->__('Remove This Item') ?>" onclick="return confirm('<?php echo $this->__('Are you sure you would like to remove this item from the wishlist?') ?>');" class="btn-remove"><?php echo $this->__('Remove This Item') ?></a>
+                <a href="#"
+                   class="btn-remove"
+                   title="<?php echo $this->quoteEscape($this->__('Remove This Item')) ?>"
+                   onclick="if (confirm('<?php echo $this->jsQuoteEscape($this->__('Are you sure you would like to remove this item from the wishlist?')) ?>')) {
+                        customFormSubmit('<?php echo $this->getItemRemoveUrlCustom($_item, false) ?>', '<?php echo $_params ?>', 'post')
+                    }">
+                    <?php echo $this->__('Remove This Item') ?>
+                </a>
                 <p class="product-name"><a href="<?php echo $this->getProductUrl($_item) ?>"><?php echo $this->escapeHtml($product->getName()) ?></a></p>
                 <?php echo $this->getPriceHtml($product, false, '-wishlist') ?>
                 <?php if ($product->isSaleable() && $product->isVisibleInSiteVisibility()): ?>
-                    <a href="<?php echo $this->getItemAddToCartUrl($_item) ?>" class="link-cart"><?php echo $this->__('Add to Cart') ?></a>
+                    <a href="#"
+                       class="link-cart"
+                       onclick="customFormSubmit('<?php echo $this->getItemAddToCartUrlCustom($_item, false) ?>', '<?php echo $_params ?>', 'post')">
+                        <?php echo $this->__('Add to Cart') ?>
+                    </a>
                 <?php endif; ?>
             </div>
         </li>
diff --git app/design/frontend/enterprise/default/layout/catalog.xml app/design/frontend/enterprise/default/layout/catalog.xml
index 5b30dac8daf..12c005e28f7 100644
--- app/design/frontend/enterprise/default/layout/catalog.xml
+++ app/design/frontend/enterprise/default/layout/catalog.xml
@@ -184,8 +184,9 @@ Product view
         <reference name="head">
             <action method="addJs"><script>varien/product.js</script></action>
             <action method="addJs"><script>varien/configurable.js</script></action>
-            <action method="addItem"><type>skin_js</type><name>js/jqzoom/jquery-1.3.1.min.js</name></action>
-            <action method="addItem"><type>skin_js</type><name>js/jqzoom/jquery.jqzoom1.0.1.js</name></action>
+            <action method="addItem"><type>skin_js</type><name>js/lib/jquery/jquery-1.12.1.min.js</name></action>
+            <action method="addItem"><type>skin_js</type><name>js/lib/jquery/noconflict.js</name></action>
+            <action method="addItem"><type>skin_js</type><name>js/lib/elevatezoom/jquery.elevateZoom-3.0.8.min.js</name></action>
             <action method="addItem"><type>js_css</type><name>calendar/calendar-win2k-1.css</name><params/><!--<if/><condition>can_load_calendar_js</condition>--></action>
             <action method="addItem"><type>js</type><name>calendar/calendar.js</name><!--<params/><if/><condition>can_load_calendar_js</condition>--></action>
             <action method="addItem"><type>js</type><name>calendar/calendar-setup.js</name><!--<params/><if/><condition>can_load_calendar_js</condition>--></action>
diff --git app/design/frontend/enterprise/default/layout/review.xml app/design/frontend/enterprise/default/layout/review.xml
index 96987702b5f..f5457e096da 100644
--- app/design/frontend/enterprise/default/layout/review.xml
+++ app/design/frontend/enterprise/default/layout/review.xml
@@ -71,8 +71,9 @@ Product reviews page
             <action method="setTemplate"><template>page/1column.phtml</template></action>
         </reference>
         <reference name="head">
-            <action method="addItem"><type>skin_js</type><name>js/jqzoom/jquery-1.3.1.min.js</name></action>
-            <action method="addItem"><type>skin_js</type><name>js/jqzoom/jquery.jqzoom1.0.1.js</name></action>
+            <action method="addItem"><type>skin_js</type><name>js/lib/jquery/jquery-1.12.1.min.js</name></action>
+            <action method="addItem"><type>skin_js</type><name>js/lib/jquery/noconflict.js</name></action>
+            <action method="addItem"><type>skin_js</type><name>js/lib/elevatezoom/jquery.elevateZoom-3.0.8.min.js</name></action>
             <action method="addJs"><script>varien/product.js</script></action>
             <action method="addJs"><script>varien/configurable.js</script></action>
         </reference>
diff --git app/design/frontend/enterprise/default/template/catalog/product/view/media.phtml app/design/frontend/enterprise/default/template/catalog/product/view/media.phtml
index 195d24f81d4..c55a7a6cc22 100644
--- app/design/frontend/enterprise/default/template/catalog/product/view/media.phtml
+++ app/design/frontend/enterprise/default/template/catalog/product/view/media.phtml
@@ -42,29 +42,17 @@
     <?php if ($_product->getImage() != 'no_selection' && $_product->getImage()): ?>
         <?php list($_imgWidth, $_imgHeight) = $this->helper('catalog/image')->init($_product, 'image')->getOriginalSizeArray(); ?>
         <?php if ($_imgWidth > 380 || $_imgHeight > 380):?>
-            <a class="product-image image-zoom" id="main-image" title="<?php echo $this->htmlEscape($_product->getImageLabel()); ?>" href="<?php echo $this->helper('catalog/image')->init($_product, 'image'); ?>">
+            <div class="product-image image-zoom" id="main-image">
                 <?php
-                    $_img = '<img src="'.$this->helper('catalog/image')->init($_product, 'image')->resize(370).'" height="370" width="370" alt="'.$this->htmlEscape($_product->getImageLabel()).'" title="'.$this->htmlEscape($_product->getImageLabel()).'" />';
+                    $_img = '<img src="'.$this->helper('catalog/image')->init($_product, 'image').'" alt="'.$this->escapeHtml($_product->getImageLabel()).'" title="'.$this->escapeHtml($_product->getImageLabel()).'" data-zoom-image="'.$this->helper('catalog/image')->init($_product, 'image').'" />';
                     echo $_helper->productAttribute($_product, $_img, 'image');
                 ?>
-            </a>
+            </div>
             <script type="text/javascript">
-            //<![CDATA[
-                jQuery(document).ready(function(){
-                    var options = {
-                            zoomType: 'reverse',//Values: standard, reverse
-                            zoomWidth: 374,
-                            zoomHeight: 327,
-                            xOffset: 0,
-                            yOffset: 50,
-                            imageOpacity: 0.6,
-                            title : false
-                    };
-                    jQuery('#main-image').jqzoom(options);
-                });
-            //]]>
+                //<![CDATA[
+                    jQuery("#main-image img").elevateZoom();
+                //]]>
             </script>
-            <p class="notice"><?php echo $this->__('Click on image to zoom'); ?></p>
         <?php else: ?>
             <p class="product-image">
                 <?php
diff --git app/design/frontend/enterprise/iphone/layout/catalog.xml app/design/frontend/enterprise/iphone/layout/catalog.xml
index 7de48766e71..f1fe2bf75d9 100644
--- app/design/frontend/enterprise/iphone/layout/catalog.xml
+++ app/design/frontend/enterprise/iphone/layout/catalog.xml
@@ -169,8 +169,6 @@ Product view
         <reference name="head">
             <action method="addJs"><script>varien/product.js</script></action>
             <action method="addJs"><script>varien/configurable.js</script></action>
-            <action method="addItem"><type>skin_js</type><name>js/jqzoom/jquery-1.3.1.min.js</name></action>
-            <action method="addItem"><type>skin_js</type><name>js/jqzoom/jquery.jqzoom1.0.1.js</name></action>
             <action method="addItem"><type>js_css</type><name>calendar/calendar-win2k-1.css</name><params/><!--<if/><condition>can_load_calendar_js</condition>--></action>
             <action method="addItem"><type>js</type><name>calendar/calendar.js</name><!--<params/><if/><condition>can_load_calendar_js</condition>--></action>
             <action method="addItem"><type>js</type><name>calendar/calendar-setup.js</name><!--<params/><if/><condition>can_load_calendar_js</condition>--></action>
diff --git js/lib/jquery/jquery-1.12.1.js js/lib/jquery/jquery-1.12.1.js
new file mode 100644
index 00000000000..d0ca1836cc9
--- /dev/null
+++ js/lib/jquery/jquery-1.12.1.js
@@ -0,0 +1,11027 @@
+/*!
+ * jQuery JavaScript Library v1.12.1
+ * http://jquery.com/
+ *
+ * Includes Sizzle.js
+ * http://sizzlejs.com/
+ *
+ * Copyright jQuery Foundation and other contributors
+ * Released under the MIT license
+ * http://jquery.org/license
+ *
+ * Date: 2016-02-22T19:07Z
+ */
+
+(function( global, factory ) {
+
+	if ( typeof module === "object" && typeof module.exports === "object" ) {
+		// For CommonJS and CommonJS-like environments where a proper `window`
+		// is present, execute the factory and get jQuery.
+		// For environments that do not have a `window` with a `document`
+		// (such as Node.js), expose a factory as module.exports.
+		// This accentuates the need for the creation of a real `window`.
+		// e.g. var jQuery = require("jquery")(window);
+		// See ticket #14549 for more info.
+		module.exports = global.document ?
+			factory( global, true ) :
+			function( w ) {
+				if ( !w.document ) {
+					throw new Error( "jQuery requires a window with a document" );
+				}
+				return factory( w );
+			};
+	} else {
+		factory( global );
+	}
+
+// Pass this if window is not defined yet
+}(typeof window !== "undefined" ? window : this, function( window, noGlobal ) {
+
+// Support: Firefox 18+
+// Can't be in strict mode, several libs including ASP.NET trace
+// the stack via arguments.caller.callee and Firefox dies if
+// you try to trace through "use strict" call chains. (#13335)
+//"use strict";
+var deletedIds = [];
+
+var document = window.document;
+
+var slice = deletedIds.slice;
+
+var concat = deletedIds.concat;
+
+var push = deletedIds.push;
+
+var indexOf = deletedIds.indexOf;
+
+var class2type = {};
+
+var toString = class2type.toString;
+
+var hasOwn = class2type.hasOwnProperty;
+
+var support = {};
+
+
+
+var
+	version = "1.12.1",
+
+	// Define a local copy of jQuery
+	jQuery = function( selector, context ) {
+
+		// The jQuery object is actually just the init constructor 'enhanced'
+		// Need init if jQuery is called (just allow error to be thrown if not included)
+		return new jQuery.fn.init( selector, context );
+	},
+
+	// Support: Android<4.1, IE<9
+	// Make sure we trim BOM and NBSP
+	rtrim = /^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g,
+
+	// Matches dashed string for camelizing
+	rmsPrefix = /^-ms-/,
+	rdashAlpha = /-([\da-z])/gi,
+
+	// Used by jQuery.camelCase as callback to replace()
+	fcamelCase = function( all, letter ) {
+		return letter.toUpperCase();
+	};
+
+jQuery.fn = jQuery.prototype = {
+
+	// The current version of jQuery being used
+	jquery: version,
+
+	constructor: jQuery,
+
+	// Start with an empty selector
+	selector: "",
+
+	// The default length of a jQuery object is 0
+	length: 0,
+
+	toArray: function() {
+		return slice.call( this );
+	},
+
+	// Get the Nth element in the matched element set OR
+	// Get the whole matched element set as a clean array
+	get: function( num ) {
+		return num != null ?
+
+			// Return just the one element from the set
+			( num < 0 ? this[ num + this.length ] : this[ num ] ) :
+
+			// Return all the elements in a clean array
+			slice.call( this );
+	},
+
+	// Take an array of elements and push it onto the stack
+	// (returning the new matched element set)
+	pushStack: function( elems ) {
+
+		// Build a new jQuery matched element set
+		var ret = jQuery.merge( this.constructor(), elems );
+
+		// Add the old object onto the stack (as a reference)
+		ret.prevObject = this;
+		ret.context = this.context;
+
+		// Return the newly-formed element set
+		return ret;
+	},
+
+	// Execute a callback for every element in the matched set.
+	each: function( callback ) {
+		return jQuery.each( this, callback );
+	},
+
+	map: function( callback ) {
+		return this.pushStack( jQuery.map( this, function( elem, i ) {
+			return callback.call( elem, i, elem );
+		} ) );
+	},
+
+	slice: function() {
+		return this.pushStack( slice.apply( this, arguments ) );
+	},
+
+	first: function() {
+		return this.eq( 0 );
+	},
+
+	last: function() {
+		return this.eq( -1 );
+	},
+
+	eq: function( i ) {
+		var len = this.length,
+			j = +i + ( i < 0 ? len : 0 );
+		return this.pushStack( j >= 0 && j < len ? [ this[ j ] ] : [] );
+	},
+
+	end: function() {
+		return this.prevObject || this.constructor();
+	},
+
+	// For internal use only.
+	// Behaves like an Array's method, not like a jQuery method.
+	push: push,
+	sort: deletedIds.sort,
+	splice: deletedIds.splice
+};
+
+jQuery.extend = jQuery.fn.extend = function() {
+	var src, copyIsArray, copy, name, options, clone,
+		target = arguments[ 0 ] || {},
+		i = 1,
+		length = arguments.length,
+		deep = false;
+
+	// Handle a deep copy situation
+	if ( typeof target === "boolean" ) {
+		deep = target;
+
+		// skip the boolean and the target
+		target = arguments[ i ] || {};
+		i++;
+	}
+
+	// Handle case when target is a string or something (possible in deep copy)
+	if ( typeof target !== "object" && !jQuery.isFunction( target ) ) {
+		target = {};
+	}
+
+	// extend jQuery itself if only one argument is passed
+	if ( i === length ) {
+		target = this;
+		i--;
+	}
+
+	for ( ; i < length; i++ ) {
+
+		// Only deal with non-null/undefined values
+		if ( ( options = arguments[ i ] ) != null ) {
+
+			// Extend the base object
+			for ( name in options ) {
+				src = target[ name ];
+				copy = options[ name ];
+
+				// Prevent Object.prototype pollution
+				// Prevent never-ending loop
+				if ( name === "__proto__" || target === copy ) {
+					continue;
+				}
+
+				// Recurse if we're merging plain objects or arrays
+				if ( deep && copy && ( jQuery.isPlainObject( copy ) ||
+					( copyIsArray = jQuery.isArray( copy ) ) ) ) {
+
+					if ( copyIsArray ) {
+						copyIsArray = false;
+						clone = src && jQuery.isArray( src ) ? src : [];
+
+					} else {
+						clone = src && jQuery.isPlainObject( src ) ? src : {};
+					}
+
+					// Never move original objects, clone them
+					target[ name ] = jQuery.extend( deep, clone, copy );
+
+				// Don't bring in undefined values
+				} else if ( copy !== undefined ) {
+					target[ name ] = copy;
+				}
+			}
+		}
+	}
+
+	// Return the modified object
+	return target;
+};
+
+jQuery.extend( {
+
+	// Unique for each copy of jQuery on the page
+	expando: "jQuery" + ( version + Math.random() ).replace( /\D/g, "" ),
+
+	// Assume jQuery is ready without the ready module
+	isReady: true,
+
+	error: function( msg ) {
+		throw new Error( msg );
+	},
+
+	noop: function() {},
+
+	// See test/unit/core.js for details concerning isFunction.
+	// Since version 1.3, DOM methods and functions like alert
+	// aren't supported. They return false on IE (#2968).
+	isFunction: function( obj ) {
+		return jQuery.type( obj ) === "function";
+	},
+
+	isArray: Array.isArray || function( obj ) {
+		return jQuery.type( obj ) === "array";
+	},
+
+	isWindow: function( obj ) {
+		/* jshint eqeqeq: false */
+		return obj != null && obj == obj.window;
+	},
+
+	isNumeric: function( obj ) {
+
+		// parseFloat NaNs numeric-cast false positives (null|true|false|"")
+		// ...but misinterprets leading-number strings, particularly hex literals ("0x...")
+		// subtraction forces infinities to NaN
+		// adding 1 corrects loss of precision from parseFloat (#15100)
+		var realStringObj = obj && obj.toString();
+		return !jQuery.isArray( obj ) && ( realStringObj - parseFloat( realStringObj ) + 1 ) >= 0;
+	},
+
+	isEmptyObject: function( obj ) {
+		var name;
+		for ( name in obj ) {
+			return false;
+		}
+		return true;
+	},
+
+	isPlainObject: function( obj ) {
+		var key;
+
+		// Must be an Object.
+		// Because of IE, we also have to check the presence of the constructor property.
+		// Make sure that DOM nodes and window objects don't pass through, as well
+		if ( !obj || jQuery.type( obj ) !== "object" || obj.nodeType || jQuery.isWindow( obj ) ) {
+			return false;
+		}
+
+		try {
+
+			// Not own constructor property must be Object
+			if ( obj.constructor &&
+				!hasOwn.call( obj, "constructor" ) &&
+				!hasOwn.call( obj.constructor.prototype, "isPrototypeOf" ) ) {
+				return false;
+			}
+		} catch ( e ) {
+
+			// IE8,9 Will throw exceptions on certain host objects #9897
+			return false;
+		}
+
+		// Support: IE<9
+		// Handle iteration over inherited properties before own properties.
+		if ( !support.ownFirst ) {
+			for ( key in obj ) {
+				return hasOwn.call( obj, key );
+			}
+		}
+
+		// Own properties are enumerated firstly, so to speed up,
+		// if last one is own, then all properties are own.
+		for ( key in obj ) {}
+
+		return key === undefined || hasOwn.call( obj, key );
+	},
+
+	type: function( obj ) {
+		if ( obj == null ) {
+			return obj + "";
+		}
+		return typeof obj === "object" || typeof obj === "function" ?
+			class2type[ toString.call( obj ) ] || "object" :
+			typeof obj;
+	},
+
+	// Workarounds based on findings by Jim Driscoll
+	// http://weblogs.java.net/blog/driscoll/archive/2009/09/08/eval-javascript-global-context
+	globalEval: function( data ) {
+		if ( data && jQuery.trim( data ) ) {
+
+			// We use execScript on Internet Explorer
+			// We use an anonymous function so that context is window
+			// rather than jQuery in Firefox
+			( window.execScript || function( data ) {
+				window[ "eval" ].call( window, data ); // jscs:ignore requireDotNotation
+			} )( data );
+		}
+	},
+
+	// Convert dashed to camelCase; used by the css and data modules
+	// Microsoft forgot to hump their vendor prefix (#9572)
+	camelCase: function( string ) {
+		return string.replace( rmsPrefix, "ms-" ).replace( rdashAlpha, fcamelCase );
+	},
+
+	nodeName: function( elem, name ) {
+		return elem.nodeName && elem.nodeName.toLowerCase() === name.toLowerCase();
+	},
+
+	each: function( obj, callback ) {
+		var length, i = 0;
+
+		if ( isArrayLike( obj ) ) {
+			length = obj.length;
+			for ( ; i < length; i++ ) {
+				if ( callback.call( obj[ i ], i, obj[ i ] ) === false ) {
+					break;
+				}
+			}
+		} else {
+			for ( i in obj ) {
+				if ( callback.call( obj[ i ], i, obj[ i ] ) === false ) {
+					break;
+				}
+			}
+		}
+
+		return obj;
+	},
+
+	// Support: Android<4.1, IE<9
+	trim: function( text ) {
+		return text == null ?
+			"" :
+			( text + "" ).replace( rtrim, "" );
+	},
+
+	// results is for internal usage only
+	makeArray: function( arr, results ) {
+		var ret = results || [];
+
+		if ( arr != null ) {
+			if ( isArrayLike( Object( arr ) ) ) {
+				jQuery.merge( ret,
+					typeof arr === "string" ?
+					[ arr ] : arr
+				);
+			} else {
+				push.call( ret, arr );
+			}
+		}
+
+		return ret;
+	},
+
+	inArray: function( elem, arr, i ) {
+		var len;
+
+		if ( arr ) {
+			if ( indexOf ) {
+				return indexOf.call( arr, elem, i );
+			}
+
+			len = arr.length;
+			i = i ? i < 0 ? Math.max( 0, len + i ) : i : 0;
+
+			for ( ; i < len; i++ ) {
+
+				// Skip accessing in sparse arrays
+				if ( i in arr && arr[ i ] === elem ) {
+					return i;
+				}
+			}
+		}
+
+		return -1;
+	},
+
+	merge: function( first, second ) {
+		var len = +second.length,
+			j = 0,
+			i = first.length;
+
+		while ( j < len ) {
+			first[ i++ ] = second[ j++ ];
+		}
+
+		// Support: IE<9
+		// Workaround casting of .length to NaN on otherwise arraylike objects (e.g., NodeLists)
+		if ( len !== len ) {
+			while ( second[ j ] !== undefined ) {
+				first[ i++ ] = second[ j++ ];
+			}
+		}
+
+		first.length = i;
+
+		return first;
+	},
+
+	grep: function( elems, callback, invert ) {
+		var callbackInverse,
+			matches = [],
+			i = 0,
+			length = elems.length,
+			callbackExpect = !invert;
+
+		// Go through the array, only saving the items
+		// that pass the validator function
+		for ( ; i < length; i++ ) {
+			callbackInverse = !callback( elems[ i ], i );
+			if ( callbackInverse !== callbackExpect ) {
+				matches.push( elems[ i ] );
+			}
+		}
+
+		return matches;
+	},
+
+	// arg is for internal usage only
+	map: function( elems, callback, arg ) {
+		var length, value,
+			i = 0,
+			ret = [];
+
+		// Go through the array, translating each of the items to their new values
+		if ( isArrayLike( elems ) ) {
+			length = elems.length;
+			for ( ; i < length; i++ ) {
+				value = callback( elems[ i ], i, arg );
+
+				if ( value != null ) {
+					ret.push( value );
+				}
+			}
+
+		// Go through every key on the object,
+		} else {
+			for ( i in elems ) {
+				value = callback( elems[ i ], i, arg );
+
+				if ( value != null ) {
+					ret.push( value );
+				}
+			}
+		}
+
+		// Flatten any nested arrays
+		return concat.apply( [], ret );
+	},
+
+	// A global GUID counter for objects
+	guid: 1,
+
+	// Bind a function to a context, optionally partially applying any
+	// arguments.
+	proxy: function( fn, context ) {
+		var args, proxy, tmp;
+
+		if ( typeof context === "string" ) {
+			tmp = fn[ context ];
+			context = fn;
+			fn = tmp;
+		}
+
+		// Quick check to determine if target is callable, in the spec
+		// this throws a TypeError, but we will just return undefined.
+		if ( !jQuery.isFunction( fn ) ) {
+			return undefined;
+		}
+
+		// Simulated bind
+		args = slice.call( arguments, 2 );
+		proxy = function() {
+			return fn.apply( context || this, args.concat( slice.call( arguments ) ) );
+		};
+
+		// Set the guid of unique handler to the same of original handler, so it can be removed
+		proxy.guid = fn.guid = fn.guid || jQuery.guid++;
+
+		return proxy;
+	},
+
+	now: function() {
+		return +( new Date() );
+	},
+
+	// jQuery.support is not used in Core but other projects attach their
+	// properties to it so it needs to exist.
+	support: support
+} );
+
+// JSHint would error on this code due to the Symbol not being defined in ES5.
+// Defining this global in .jshintrc would create a danger of using the global
+// unguarded in another place, it seems safer to just disable JSHint for these
+// three lines.
+/* jshint ignore: start */
+if ( typeof Symbol === "function" ) {
+	jQuery.fn[ Symbol.iterator ] = deletedIds[ Symbol.iterator ];
+}
+/* jshint ignore: end */
+
+// Populate the class2type map
+jQuery.each( "Boolean Number String Function Array Date RegExp Object Error Symbol".split( " " ),
+function( i, name ) {
+	class2type[ "[object " + name + "]" ] = name.toLowerCase();
+} );
+
+function isArrayLike( obj ) {
+
+	// Support: iOS 8.2 (not reproducible in simulator)
+	// `in` check used to prevent JIT error (gh-2145)
+	// hasOwn isn't used here due to false negatives
+	// regarding Nodelist length in IE
+	var length = !!obj && "length" in obj && obj.length,
+		type = jQuery.type( obj );
+
+	if ( type === "function" || jQuery.isWindow( obj ) ) {
+		return false;
+	}
+
+	return type === "array" || length === 0 ||
+		typeof length === "number" && length > 0 && ( length - 1 ) in obj;
+}
+var Sizzle =
+/*!
+ * Sizzle CSS Selector Engine v2.2.1
+ * http://sizzlejs.com/
+ *
+ * Copyright jQuery Foundation and other contributors
+ * Released under the MIT license
+ * http://jquery.org/license
+ *
+ * Date: 2015-10-17
+ */
+(function( window ) {
+
+var i,
+	support,
+	Expr,
+	getText,
+	isXML,
+	tokenize,
+	compile,
+	select,
+	outermostContext,
+	sortInput,
+	hasDuplicate,
+
+	// Local document vars
+	setDocument,
+	document,
+	docElem,
+	documentIsHTML,
+	rbuggyQSA,
+	rbuggyMatches,
+	matches,
+	contains,
+
+	// Instance-specific data
+	expando = "sizzle" + 1 * new Date(),
+	preferredDoc = window.document,
+	dirruns = 0,
+	done = 0,
+	classCache = createCache(),
+	tokenCache = createCache(),
+	compilerCache = createCache(),
+	sortOrder = function( a, b ) {
+		if ( a === b ) {
+			hasDuplicate = true;
+		}
+		return 0;
+	},
+
+	// General-purpose constants
+	MAX_NEGATIVE = 1 << 31,
+
+	// Instance methods
+	hasOwn = ({}).hasOwnProperty,
+	arr = [],
+	pop = arr.pop,
+	push_native = arr.push,
+	push = arr.push,
+	slice = arr.slice,
+	// Use a stripped-down indexOf as it's faster than native
+	// http://jsperf.com/thor-indexof-vs-for/5
+	indexOf = function( list, elem ) {
+		var i = 0,
+			len = list.length;
+		for ( ; i < len; i++ ) {
+			if ( list[i] === elem ) {
+				return i;
+			}
+		}
+		return -1;
+	},
+
+	booleans = "checked|selected|async|autofocus|autoplay|controls|defer|disabled|hidden|ismap|loop|multiple|open|readonly|required|scoped",
+
+	// Regular expressions
+
+	// http://www.w3.org/TR/css3-selectors/#whitespace
+	whitespace = "[\\x20\\t\\r\\n\\f]",
+
+	// http://www.w3.org/TR/CSS21/syndata.html#value-def-identifier
+	identifier = "(?:\\\\.|[\\w-]|[^\\x00-\\xa0])+",
+
+	// Attribute selectors: http://www.w3.org/TR/selectors/#attribute-selectors
+	attributes = "\\[" + whitespace + "*(" + identifier + ")(?:" + whitespace +
+		// Operator (capture 2)
+		"*([*^$|!~]?=)" + whitespace +
+		// "Attribute values must be CSS identifiers [capture 5] or strings [capture 3 or capture 4]"
+		"*(?:'((?:\\\\.|[^\\\\'])*)'|\"((?:\\\\.|[^\\\\\"])*)\"|(" + identifier + "))|)" + whitespace +
+		"*\\]",
+
+	pseudos = ":(" + identifier + ")(?:\\((" +
+		// To reduce the number of selectors needing tokenize in the preFilter, prefer arguments:
+		// 1. quoted (capture 3; capture 4 or capture 5)
+		"('((?:\\\\.|[^\\\\'])*)'|\"((?:\\\\.|[^\\\\\"])*)\")|" +
+		// 2. simple (capture 6)
+		"((?:\\\\.|[^\\\\()[\\]]|" + attributes + ")*)|" +
+		// 3. anything else (capture 2)
+		".*" +
+		")\\)|)",
+
+	// Leading and non-escaped trailing whitespace, capturing some non-whitespace characters preceding the latter
+	rwhitespace = new RegExp( whitespace + "+", "g" ),
+	rtrim = new RegExp( "^" + whitespace + "+|((?:^|[^\\\\])(?:\\\\.)*)" + whitespace + "+$", "g" ),
+
+	rcomma = new RegExp( "^" + whitespace + "*," + whitespace + "*" ),
+	rcombinators = new RegExp( "^" + whitespace + "*([>+~]|" + whitespace + ")" + whitespace + "*" ),
+
+	rattributeQuotes = new RegExp( "=" + whitespace + "*([^\\]'\"]*?)" + whitespace + "*\\]", "g" ),
+
+	rpseudo = new RegExp( pseudos ),
+	ridentifier = new RegExp( "^" + identifier + "$" ),
+
+	matchExpr = {
+		"ID": new RegExp( "^#(" + identifier + ")" ),
+		"CLASS": new RegExp( "^\\.(" + identifier + ")" ),
+		"TAG": new RegExp( "^(" + identifier + "|[*])" ),
+		"ATTR": new RegExp( "^" + attributes ),
+		"PSEUDO": new RegExp( "^" + pseudos ),
+		"CHILD": new RegExp( "^:(only|first|last|nth|nth-last)-(child|of-type)(?:\\(" + whitespace +
+			"*(even|odd|(([+-]|)(\\d*)n|)" + whitespace + "*(?:([+-]|)" + whitespace +
+			"*(\\d+)|))" + whitespace + "*\\)|)", "i" ),
+		"bool": new RegExp( "^(?:" + booleans + ")$", "i" ),
+		// For use in libraries implementing .is()
+		// We use this for POS matching in `select`
+		"needsContext": new RegExp( "^" + whitespace + "*[>+~]|:(even|odd|eq|gt|lt|nth|first|last)(?:\\(" +
+			whitespace + "*((?:-\\d)?\\d*)" + whitespace + "*\\)|)(?=[^-]|$)", "i" )
+	},
+
+	rinputs = /^(?:input|select|textarea|button)$/i,
+	rheader = /^h\d$/i,
+
+	rnative = /^[^{]+\{\s*\[native \w/,
+
+	// Easily-parseable/retrievable ID or TAG or CLASS selectors
+	rquickExpr = /^(?:#([\w-]+)|(\w+)|\.([\w-]+))$/,
+
+	rsibling = /[+~]/,
+	rescape = /'|\\/g,
+
+	// CSS escapes http://www.w3.org/TR/CSS21/syndata.html#escaped-characters
+	runescape = new RegExp( "\\\\([\\da-f]{1,6}" + whitespace + "?|(" + whitespace + ")|.)", "ig" ),
+	funescape = function( _, escaped, escapedWhitespace ) {
+		var high = "0x" + escaped - 0x10000;
+		// NaN means non-codepoint
+		// Support: Firefox<24
+		// Workaround erroneous numeric interpretation of +"0x"
+		return high !== high || escapedWhitespace ?
+			escaped :
+			high < 0 ?
+				// BMP codepoint
+				String.fromCharCode( high + 0x10000 ) :
+				// Supplemental Plane codepoint (surrogate pair)
+				String.fromCharCode( high >> 10 | 0xD800, high & 0x3FF | 0xDC00 );
+	},
+
+	// Used for iframes
+	// See setDocument()
+	// Removing the function wrapper causes a "Permission Denied"
+	// error in IE
+	unloadHandler = function() {
+		setDocument();
+	};
+
+// Optimize for push.apply( _, NodeList )
+try {
+	push.apply(
+		(arr = slice.call( preferredDoc.childNodes )),
+		preferredDoc.childNodes
+	);
+	// Support: Android<4.0
+	// Detect silently failing push.apply
+	arr[ preferredDoc.childNodes.length ].nodeType;
+} catch ( e ) {
+	push = { apply: arr.length ?
+
+		// Leverage slice if possible
+		function( target, els ) {
+			push_native.apply( target, slice.call(els) );
+		} :
+
+		// Support: IE<9
+		// Otherwise append directly
+		function( target, els ) {
+			var j = target.length,
+				i = 0;
+			// Can't trust NodeList.length
+			while ( (target[j++] = els[i++]) ) {}
+			target.length = j - 1;
+		}
+	};
+}
+
+function Sizzle( selector, context, results, seed ) {
+	var m, i, elem, nid, nidselect, match, groups, newSelector,
+		newContext = context && context.ownerDocument,
+
+		// nodeType defaults to 9, since context defaults to document
+		nodeType = context ? context.nodeType : 9;
+
+	results = results || [];
+
+	// Return early from calls with invalid selector or context
+	if ( typeof selector !== "string" || !selector ||
+		nodeType !== 1 && nodeType !== 9 && nodeType !== 11 ) {
+
+		return results;
+	}
+
+	// Try to shortcut find operations (as opposed to filters) in HTML documents
+	if ( !seed ) {
+
+		if ( ( context ? context.ownerDocument || context : preferredDoc ) !== document ) {
+			setDocument( context );
+		}
+		context = context || document;
+
+		if ( documentIsHTML ) {
+
+			// If the selector is sufficiently simple, try using a "get*By*" DOM method
+			// (excepting DocumentFragment context, where the methods don't exist)
+			if ( nodeType !== 11 && (match = rquickExpr.exec( selector )) ) {
+
+				// ID selector
+				if ( (m = match[1]) ) {
+
+					// Document context
+					if ( nodeType === 9 ) {
+						if ( (elem = context.getElementById( m )) ) {
+
+							// Support: IE, Opera, Webkit
+							// TODO: identify versions
+							// getElementById can match elements by name instead of ID
+							if ( elem.id === m ) {
+								results.push( elem );
+								return results;
+							}
+						} else {
+							return results;
+						}
+
+					// Element context
+					} else {
+
+						// Support: IE, Opera, Webkit
+						// TODO: identify versions
+						// getElementById can match elements by name instead of ID
+						if ( newContext && (elem = newContext.getElementById( m )) &&
+							contains( context, elem ) &&
+							elem.id === m ) {
+
+							results.push( elem );
+							return results;
+						}
+					}
+
+				// Type selector
+				} else if ( match[2] ) {
+					push.apply( results, context.getElementsByTagName( selector ) );
+					return results;
+
+				// Class selector
+				} else if ( (m = match[3]) && support.getElementsByClassName &&
+					context.getElementsByClassName ) {
+
+					push.apply( results, context.getElementsByClassName( m ) );
+					return results;
+				}
+			}
+
+			// Take advantage of querySelectorAll
+			if ( support.qsa &&
+				!compilerCache[ selector + " " ] &&
+				(!rbuggyQSA || !rbuggyQSA.test( selector )) ) {
+
+				if ( nodeType !== 1 ) {
+					newContext = context;
+					newSelector = selector;
+
+				// qSA looks outside Element context, which is not what we want
+				// Thanks to Andrew Dupont for this workaround technique
+				// Support: IE <=8
+				// Exclude object elements
+				} else if ( context.nodeName.toLowerCase() !== "object" ) {
+
+					// Capture the context ID, setting it first if necessary
+					if ( (nid = context.getAttribute( "id" )) ) {
+						nid = nid.replace( rescape, "\\$&" );
+					} else {
+						context.setAttribute( "id", (nid = expando) );
+					}
+
+					// Prefix every selector in the list
+					groups = tokenize( selector );
+					i = groups.length;
+					nidselect = ridentifier.test( nid ) ? "#" + nid : "[id='" + nid + "']";
+					while ( i-- ) {
+						groups[i] = nidselect + " " + toSelector( groups[i] );
+					}
+					newSelector = groups.join( "," );
+
+					// Expand context for sibling selectors
+					newContext = rsibling.test( selector ) && testContext( context.parentNode ) ||
+						context;
+				}
+
+				if ( newSelector ) {
+					try {
+						push.apply( results,
+							newContext.querySelectorAll( newSelector )
+						);
+						return results;
+					} catch ( qsaError ) {
+					} finally {
+						if ( nid === expando ) {
+							context.removeAttribute( "id" );
+						}
+					}
+				}
+			}
+		}
+	}
+
+	// All others
+	return select( selector.replace( rtrim, "$1" ), context, results, seed );
+}
+
+/**
+ * Create key-value caches of limited size
+ * @returns {function(string, object)} Returns the Object data after storing it on itself with
+ *	property name the (space-suffixed) string and (if the cache is larger than Expr.cacheLength)
+ *	deleting the oldest entry
+ */
+function createCache() {
+	var keys = [];
+
+	function cache( key, value ) {
+		// Use (key + " ") to avoid collision with native prototype properties (see Issue #157)
+		if ( keys.push( key + " " ) > Expr.cacheLength ) {
+			// Only keep the most recent entries
+			delete cache[ keys.shift() ];
+		}
+		return (cache[ key + " " ] = value);
+	}
+	return cache;
+}
+
+/**
+ * Mark a function for special use by Sizzle
+ * @param {Function} fn The function to mark
+ */
+function markFunction( fn ) {
+	fn[ expando ] = true;
+	return fn;
+}
+
+/**
+ * Support testing using an element
+ * @param {Function} fn Passed the created div and expects a boolean result
+ */
+function assert( fn ) {
+	var div = document.createElement("div");
+
+	try {
+		return !!fn( div );
+	} catch (e) {
+		return false;
+	} finally {
+		// Remove from its parent by default
+		if ( div.parentNode ) {
+			div.parentNode.removeChild( div );
+		}
+		// release memory in IE
+		div = null;
+	}
+}
+
+/**
+ * Adds the same handler for all of the specified attrs
+ * @param {String} attrs Pipe-separated list of attributes
+ * @param {Function} handler The method that will be applied
+ */
+function addHandle( attrs, handler ) {
+	var arr = attrs.split("|"),
+		i = arr.length;
+
+	while ( i-- ) {
+		Expr.attrHandle[ arr[i] ] = handler;
+	}
+}
+
+/**
+ * Checks document order of two siblings
+ * @param {Element} a
+ * @param {Element} b
+ * @returns {Number} Returns less than 0 if a precedes b, greater than 0 if a follows b
+ */
+function siblingCheck( a, b ) {
+	var cur = b && a,
+		diff = cur && a.nodeType === 1 && b.nodeType === 1 &&
+			( ~b.sourceIndex || MAX_NEGATIVE ) -
+			( ~a.sourceIndex || MAX_NEGATIVE );
+
+	// Use IE sourceIndex if available on both nodes
+	if ( diff ) {
+		return diff;
+	}
+
+	// Check if b follows a
+	if ( cur ) {
+		while ( (cur = cur.nextSibling) ) {
+			if ( cur === b ) {
+				return -1;
+			}
+		}
+	}
+
+	return a ? 1 : -1;
+}
+
+/**
+ * Returns a function to use in pseudos for input types
+ * @param {String} type
+ */
+function createInputPseudo( type ) {
+	return function( elem ) {
+		var name = elem.nodeName.toLowerCase();
+		return name === "input" && elem.type === type;
+	};
+}
+
+/**
+ * Returns a function to use in pseudos for buttons
+ * @param {String} type
+ */
+function createButtonPseudo( type ) {
+	return function( elem ) {
+		var name = elem.nodeName.toLowerCase();
+		return (name === "input" || name === "button") && elem.type === type;
+	};
+}
+
+/**
+ * Returns a function to use in pseudos for positionals
+ * @param {Function} fn
+ */
+function createPositionalPseudo( fn ) {
+	return markFunction(function( argument ) {
+		argument = +argument;
+		return markFunction(function( seed, matches ) {
+			var j,
+				matchIndexes = fn( [], seed.length, argument ),
+				i = matchIndexes.length;
+
+			// Match elements found at the specified indexes
+			while ( i-- ) {
+				if ( seed[ (j = matchIndexes[i]) ] ) {
+					seed[j] = !(matches[j] = seed[j]);
+				}
+			}
+		});
+	});
+}
+
+/**
+ * Checks a node for validity as a Sizzle context
+ * @param {Element|Object=} context
+ * @returns {Element|Object|Boolean} The input node if acceptable, otherwise a falsy value
+ */
+function testContext( context ) {
+	return context && typeof context.getElementsByTagName !== "undefined" && context;
+}
+
+// Expose support vars for convenience
+support = Sizzle.support = {};
+
+/**
+ * Detects XML nodes
+ * @param {Element|Object} elem An element or a document
+ * @returns {Boolean} True iff elem is a non-HTML XML node
+ */
+isXML = Sizzle.isXML = function( elem ) {
+	// documentElement is verified for cases where it doesn't yet exist
+	// (such as loading iframes in IE - #4833)
+	var documentElement = elem && (elem.ownerDocument || elem).documentElement;
+	return documentElement ? documentElement.nodeName !== "HTML" : false;
+};
+
+/**
+ * Sets document-related variables once based on the current document
+ * @param {Element|Object} [doc] An element or document object to use to set the document
+ * @returns {Object} Returns the current document
+ */
+setDocument = Sizzle.setDocument = function( node ) {
+	var hasCompare, parent,
+		doc = node ? node.ownerDocument || node : preferredDoc;
+
+	// Return early if doc is invalid or already selected
+	if ( doc === document || doc.nodeType !== 9 || !doc.documentElement ) {
+		return document;
+	}
+
+	// Update global variables
+	document = doc;
+	docElem = document.documentElement;
+	documentIsHTML = !isXML( document );
+
+	// Support: IE 9-11, Edge
+	// Accessing iframe documents after unload throws "permission denied" errors (jQuery #13936)
+	if ( (parent = document.defaultView) && parent.top !== parent ) {
+		// Support: IE 11
+		if ( parent.addEventListener ) {
+			parent.addEventListener( "unload", unloadHandler, false );
+
+		// Support: IE 9 - 10 only
+		} else if ( parent.attachEvent ) {
+			parent.attachEvent( "onunload", unloadHandler );
+		}
+	}
+
+	/* Attributes
+	---------------------------------------------------------------------- */
+
+	// Support: IE<8
+	// Verify that getAttribute really returns attributes and not properties
+	// (excepting IE8 booleans)
+	support.attributes = assert(function( div ) {
+		div.className = "i";
+		return !div.getAttribute("className");
+	});
+
+	/* getElement(s)By*
+	---------------------------------------------------------------------- */
+
+	// Check if getElementsByTagName("*") returns only elements
+	support.getElementsByTagName = assert(function( div ) {
+		div.appendChild( document.createComment("") );
+		return !div.getElementsByTagName("*").length;
+	});
+
+	// Support: IE<9
+	support.getElementsByClassName = rnative.test( document.getElementsByClassName );
+
+	// Support: IE<10
+	// Check if getElementById returns elements by name
+	// The broken getElementById methods don't pick up programatically-set names,
+	// so use a roundabout getElementsByName test
+	support.getById = assert(function( div ) {
+		docElem.appendChild( div ).id = expando;
+		return !document.getElementsByName || !document.getElementsByName( expando ).length;
+	});
+
+	// ID find and filter
+	if ( support.getById ) {
+		Expr.find["ID"] = function( id, context ) {
+			if ( typeof context.getElementById !== "undefined" && documentIsHTML ) {
+				var m = context.getElementById( id );
+				return m ? [ m ] : [];
+			}
+		};
+		Expr.filter["ID"] = function( id ) {
+			var attrId = id.replace( runescape, funescape );
+			return function( elem ) {
+				return elem.getAttribute("id") === attrId;
+			};
+		};
+	} else {
+		// Support: IE6/7
+		// getElementById is not reliable as a find shortcut
+		delete Expr.find["ID"];
+
+		Expr.filter["ID"] =  function( id ) {
+			var attrId = id.replace( runescape, funescape );
+			return function( elem ) {
+				var node = typeof elem.getAttributeNode !== "undefined" &&
+					elem.getAttributeNode("id");
+				return node && node.value === attrId;
+			};
+		};
+	}
+
+	// Tag
+	Expr.find["TAG"] = support.getElementsByTagName ?
+		function( tag, context ) {
+			if ( typeof context.getElementsByTagName !== "undefined" ) {
+				return context.getElementsByTagName( tag );
+
+			// DocumentFragment nodes don't have gEBTN
+			} else if ( support.qsa ) {
+				return context.querySelectorAll( tag );
+			}
+		} :
+
+		function( tag, context ) {
+			var elem,
+				tmp = [],
+				i = 0,
+				// By happy coincidence, a (broken) gEBTN appears on DocumentFragment nodes too
+				results = context.getElementsByTagName( tag );
+
+			// Filter out possible comments
+			if ( tag === "*" ) {
+				while ( (elem = results[i++]) ) {
+					if ( elem.nodeType === 1 ) {
+						tmp.push( elem );
+					}
+				}
+
+				return tmp;
+			}
+			return results;
+		};
+
+	// Class
+	Expr.find["CLASS"] = support.getElementsByClassName && function( className, context ) {
+		if ( typeof context.getElementsByClassName !== "undefined" && documentIsHTML ) {
+			return context.getElementsByClassName( className );
+		}
+	};
+
+	/* QSA/matchesSelector
+	---------------------------------------------------------------------- */
+
+	// QSA and matchesSelector support
+
+	// matchesSelector(:active) reports false when true (IE9/Opera 11.5)
+	rbuggyMatches = [];
+
+	// qSa(:focus) reports false when true (Chrome 21)
+	// We allow this because of a bug in IE8/9 that throws an error
+	// whenever `document.activeElement` is accessed on an iframe
+	// So, we allow :focus to pass through QSA all the time to avoid the IE error
+	// See http://bugs.jquery.com/ticket/13378
+	rbuggyQSA = [];
+
+	if ( (support.qsa = rnative.test( document.querySelectorAll )) ) {
+		// Build QSA regex
+		// Regex strategy adopted from Diego Perini
+		assert(function( div ) {
+			// Select is set to empty string on purpose
+			// This is to test IE's treatment of not explicitly
+			// setting a boolean content attribute,
+			// since its presence should be enough
+			// http://bugs.jquery.com/ticket/12359
+			docElem.appendChild( div ).innerHTML = "<a id='" + expando + "'></a>" +
+				"<select id='" + expando + "-\r\\' msallowcapture=''>" +
+				"<option selected=''></option></select>";
+
+			// Support: IE8, Opera 11-12.16
+			// Nothing should be selected when empty strings follow ^= or $= or *=
+			// The test attribute must be unknown in Opera but "safe" for WinRT
+			// http://msdn.microsoft.com/en-us/library/ie/hh465388.aspx#attribute_section
+			if ( div.querySelectorAll("[msallowcapture^='']").length ) {
+				rbuggyQSA.push( "[*^$]=" + whitespace + "*(?:''|\"\")" );
+			}
+
+			// Support: IE8
+			// Boolean attributes and "value" are not treated correctly
+			if ( !div.querySelectorAll("[selected]").length ) {
+				rbuggyQSA.push( "\\[" + whitespace + "*(?:value|" + booleans + ")" );
+			}
+
+			// Support: Chrome<29, Android<4.4, Safari<7.0+, iOS<7.0+, PhantomJS<1.9.8+
+			if ( !div.querySelectorAll( "[id~=" + expando + "-]" ).length ) {
+				rbuggyQSA.push("~=");
+			}
+
+			// Webkit/Opera - :checked should return selected option elements
+			// http://www.w3.org/TR/2011/REC-css3-selectors-20110929/#checked
+			// IE8 throws error here and will not see later tests
+			if ( !div.querySelectorAll(":checked").length ) {
+				rbuggyQSA.push(":checked");
+			}
+
+			// Support: Safari 8+, iOS 8+
+			// https://bugs.webkit.org/show_bug.cgi?id=136851
+			// In-page `selector#id sibing-combinator selector` fails
+			if ( !div.querySelectorAll( "a#" + expando + "+*" ).length ) {
+				rbuggyQSA.push(".#.+[+~]");
+			}
+		});
+
+		assert(function( div ) {
+			// Support: Windows 8 Native Apps
+			// The type and name attributes are restricted during .innerHTML assignment
+			var input = document.createElement("input");
+			input.setAttribute( "type", "hidden" );
+			div.appendChild( input ).setAttribute( "name", "D" );
+
+			// Support: IE8
+			// Enforce case-sensitivity of name attribute
+			if ( div.querySelectorAll("[name=d]").length ) {
+				rbuggyQSA.push( "name" + whitespace + "*[*^$|!~]?=" );
+			}
+
+			// FF 3.5 - :enabled/:disabled and hidden elements (hidden elements are still enabled)
+			// IE8 throws error here and will not see later tests
+			if ( !div.querySelectorAll(":enabled").length ) {
+				rbuggyQSA.push( ":enabled", ":disabled" );
+			}
+
+			// Opera 10-11 does not throw on post-comma invalid pseudos
+			div.querySelectorAll("*,:x");
+			rbuggyQSA.push(",.*:");
+		});
+	}
+
+	if ( (support.matchesSelector = rnative.test( (matches = docElem.matches ||
+		docElem.webkitMatchesSelector ||
+		docElem.mozMatchesSelector ||
+		docElem.oMatchesSelector ||
+		docElem.msMatchesSelector) )) ) {
+
+		assert(function( div ) {
+			// Check to see if it's possible to do matchesSelector
+			// on a disconnected node (IE 9)
+			support.disconnectedMatch = matches.call( div, "div" );
+
+			// This should fail with an exception
+			// Gecko does not error, returns false instead
+			matches.call( div, "[s!='']:x" );
+			rbuggyMatches.push( "!=", pseudos );
+		});
+	}
+
+	rbuggyQSA = rbuggyQSA.length && new RegExp( rbuggyQSA.join("|") );
+	rbuggyMatches = rbuggyMatches.length && new RegExp( rbuggyMatches.join("|") );
+
+	/* Contains
+	---------------------------------------------------------------------- */
+	hasCompare = rnative.test( docElem.compareDocumentPosition );
+
+	// Element contains another
+	// Purposefully self-exclusive
+	// As in, an element does not contain itself
+	contains = hasCompare || rnative.test( docElem.contains ) ?
+		function( a, b ) {
+			var adown = a.nodeType === 9 ? a.documentElement : a,
+				bup = b && b.parentNode;
+			return a === bup || !!( bup && bup.nodeType === 1 && (
+				adown.contains ?
+					adown.contains( bup ) :
+					a.compareDocumentPosition && a.compareDocumentPosition( bup ) & 16
+			));
+		} :
+		function( a, b ) {
+			if ( b ) {
+				while ( (b = b.parentNode) ) {
+					if ( b === a ) {
+						return true;
+					}
+				}
+			}
+			return false;
+		};
+
+	/* Sorting
+	---------------------------------------------------------------------- */
+
+	// Document order sorting
+	sortOrder = hasCompare ?
+	function( a, b ) {
+
+		// Flag for duplicate removal
+		if ( a === b ) {
+			hasDuplicate = true;
+			return 0;
+		}
+
+		// Sort on method existence if only one input has compareDocumentPosition
+		var compare = !a.compareDocumentPosition - !b.compareDocumentPosition;
+		if ( compare ) {
+			return compare;
+		}
+
+		// Calculate position if both inputs belong to the same document
+		compare = ( a.ownerDocument || a ) === ( b.ownerDocument || b ) ?
+			a.compareDocumentPosition( b ) :
+
+			// Otherwise we know they are disconnected
+			1;
+
+		// Disconnected nodes
+		if ( compare & 1 ||
+			(!support.sortDetached && b.compareDocumentPosition( a ) === compare) ) {
+
+			// Choose the first element that is related to our preferred document
+			if ( a === document || a.ownerDocument === preferredDoc && contains(preferredDoc, a) ) {
+				return -1;
+			}
+			if ( b === document || b.ownerDocument === preferredDoc && contains(preferredDoc, b) ) {
+				return 1;
+			}
+
+			// Maintain original order
+			return sortInput ?
+				( indexOf( sortInput, a ) - indexOf( sortInput, b ) ) :
+				0;
+		}
+
+		return compare & 4 ? -1 : 1;
+	} :
+	function( a, b ) {
+		// Exit early if the nodes are identical
+		if ( a === b ) {
+			hasDuplicate = true;
+			return 0;
+		}
+
+		var cur,
+			i = 0,
+			aup = a.parentNode,
+			bup = b.parentNode,
+			ap = [ a ],
+			bp = [ b ];
+
+		// Parentless nodes are either documents or disconnected
+		if ( !aup || !bup ) {
+			return a === document ? -1 :
+				b === document ? 1 :
+				aup ? -1 :
+				bup ? 1 :
+				sortInput ?
+				( indexOf( sortInput, a ) - indexOf( sortInput, b ) ) :
+				0;
+
+		// If the nodes are siblings, we can do a quick check
+		} else if ( aup === bup ) {
+			return siblingCheck( a, b );
+		}
+
+		// Otherwise we need full lists of their ancestors for comparison
+		cur = a;
+		while ( (cur = cur.parentNode) ) {
+			ap.unshift( cur );
+		}
+		cur = b;
+		while ( (cur = cur.parentNode) ) {
+			bp.unshift( cur );
+		}
+
+		// Walk down the tree looking for a discrepancy
+		while ( ap[i] === bp[i] ) {
+			i++;
+		}
+
+		return i ?
+			// Do a sibling check if the nodes have a common ancestor
+			siblingCheck( ap[i], bp[i] ) :
+
+			// Otherwise nodes in our document sort first
+			ap[i] === preferredDoc ? -1 :
+			bp[i] === preferredDoc ? 1 :
+			0;
+	};
+
+	return document;
+};
+
+Sizzle.matches = function( expr, elements ) {
+	return Sizzle( expr, null, null, elements );
+};
+
+Sizzle.matchesSelector = function( elem, expr ) {
+	// Set document vars if needed
+	if ( ( elem.ownerDocument || elem ) !== document ) {
+		setDocument( elem );
+	}
+
+	// Make sure that attribute selectors are quoted
+	expr = expr.replace( rattributeQuotes, "='$1']" );
+
+	if ( support.matchesSelector && documentIsHTML &&
+		!compilerCache[ expr + " " ] &&
+		( !rbuggyMatches || !rbuggyMatches.test( expr ) ) &&
+		( !rbuggyQSA     || !rbuggyQSA.test( expr ) ) ) {
+
+		try {
+			var ret = matches.call( elem, expr );
+
+			// IE 9's matchesSelector returns false on disconnected nodes
+			if ( ret || support.disconnectedMatch ||
+					// As well, disconnected nodes are said to be in a document
+					// fragment in IE 9
+					elem.document && elem.document.nodeType !== 11 ) {
+				return ret;
+			}
+		} catch (e) {}
+	}
+
+	return Sizzle( expr, document, null, [ elem ] ).length > 0;
+};
+
+Sizzle.contains = function( context, elem ) {
+	// Set document vars if needed
+	if ( ( context.ownerDocument || context ) !== document ) {
+		setDocument( context );
+	}
+	return contains( context, elem );
+};
+
+Sizzle.attr = function( elem, name ) {
+	// Set document vars if needed
+	if ( ( elem.ownerDocument || elem ) !== document ) {
+		setDocument( elem );
+	}
+
+	var fn = Expr.attrHandle[ name.toLowerCase() ],
+		// Don't get fooled by Object.prototype properties (jQuery #13807)
+		val = fn && hasOwn.call( Expr.attrHandle, name.toLowerCase() ) ?
+			fn( elem, name, !documentIsHTML ) :
+			undefined;
+
+	return val !== undefined ?
+		val :
+		support.attributes || !documentIsHTML ?
+			elem.getAttribute( name ) :
+			(val = elem.getAttributeNode(name)) && val.specified ?
+				val.value :
+				null;
+};
+
+Sizzle.error = function( msg ) {
+	throw new Error( "Syntax error, unrecognized expression: " + msg );
+};
+
+/**
+ * Document sorting and removing duplicates
+ * @param {ArrayLike} results
+ */
+Sizzle.uniqueSort = function( results ) {
+	var elem,
+		duplicates = [],
+		j = 0,
+		i = 0;
+
+	// Unless we *know* we can detect duplicates, assume their presence
+	hasDuplicate = !support.detectDuplicates;
+	sortInput = !support.sortStable && results.slice( 0 );
+	results.sort( sortOrder );
+
+	if ( hasDuplicate ) {
+		while ( (elem = results[i++]) ) {
+			if ( elem === results[ i ] ) {
+				j = duplicates.push( i );
+			}
+		}
+		while ( j-- ) {
+			results.splice( duplicates[ j ], 1 );
+		}
+	}
+
+	// Clear input after sorting to release objects
+	// See https://github.com/jquery/sizzle/pull/225
+	sortInput = null;
+
+	return results;
+};
+
+/**
+ * Utility function for retrieving the text value of an array of DOM nodes
+ * @param {Array|Element} elem
+ */
+getText = Sizzle.getText = function( elem ) {
+	var node,
+		ret = "",
+		i = 0,
+		nodeType = elem.nodeType;
+
+	if ( !nodeType ) {
+		// If no nodeType, this is expected to be an array
+		while ( (node = elem[i++]) ) {
+			// Do not traverse comment nodes
+			ret += getText( node );
+		}
+	} else if ( nodeType === 1 || nodeType === 9 || nodeType === 11 ) {
+		// Use textContent for elements
+		// innerText usage removed for consistency of new lines (jQuery #11153)
+		if ( typeof elem.textContent === "string" ) {
+			return elem.textContent;
+		} else {
+			// Traverse its children
+			for ( elem = elem.firstChild; elem; elem = elem.nextSibling ) {
+				ret += getText( elem );
+			}
+		}
+	} else if ( nodeType === 3 || nodeType === 4 ) {
+		return elem.nodeValue;
+	}
+	// Do not include comment or processing instruction nodes
+
+	return ret;
+};
+
+Expr = Sizzle.selectors = {
+
+	// Can be adjusted by the user
+	cacheLength: 50,
+
+	createPseudo: markFunction,
+
+	match: matchExpr,
+
+	attrHandle: {},
+
+	find: {},
+
+	relative: {
+		">": { dir: "parentNode", first: true },
+		" ": { dir: "parentNode" },
+		"+": { dir: "previousSibling", first: true },
+		"~": { dir: "previousSibling" }
+	},
+
+	preFilter: {
+		"ATTR": function( match ) {
+			match[1] = match[1].replace( runescape, funescape );
+
+			// Move the given value to match[3] whether quoted or unquoted
+			match[3] = ( match[3] || match[4] || match[5] || "" ).replace( runescape, funescape );
+
+			if ( match[2] === "~=" ) {
+				match[3] = " " + match[3] + " ";
+			}
+
+			return match.slice( 0, 4 );
+		},
+
+		"CHILD": function( match ) {
+			/* matches from matchExpr["CHILD"]
+				1 type (only|nth|...)
+				2 what (child|of-type)
+				3 argument (even|odd|\d*|\d*n([+-]\d+)?|...)
+				4 xn-component of xn+y argument ([+-]?\d*n|)
+				5 sign of xn-component
+				6 x of xn-component
+				7 sign of y-component
+				8 y of y-component
+			*/
+			match[1] = match[1].toLowerCase();
+
+			if ( match[1].slice( 0, 3 ) === "nth" ) {
+				// nth-* requires argument
+				if ( !match[3] ) {
+					Sizzle.error( match[0] );
+				}
+
+				// numeric x and y parameters for Expr.filter.CHILD
+				// remember that false/true cast respectively to 0/1
+				match[4] = +( match[4] ? match[5] + (match[6] || 1) : 2 * ( match[3] === "even" || match[3] === "odd" ) );
+				match[5] = +( ( match[7] + match[8] ) || match[3] === "odd" );
+
+			// other types prohibit arguments
+			} else if ( match[3] ) {
+				Sizzle.error( match[0] );
+			}
+
+			return match;
+		},
+
+		"PSEUDO": function( match ) {
+			var excess,
+				unquoted = !match[6] && match[2];
+
+			if ( matchExpr["CHILD"].test( match[0] ) ) {
+				return null;
+			}
+
+			// Accept quoted arguments as-is
+			if ( match[3] ) {
+				match[2] = match[4] || match[5] || "";
+
+			// Strip excess characters from unquoted arguments
+			} else if ( unquoted && rpseudo.test( unquoted ) &&
+				// Get excess from tokenize (recursively)
+				(excess = tokenize( unquoted, true )) &&
+				// advance to the next closing parenthesis
+				(excess = unquoted.indexOf( ")", unquoted.length - excess ) - unquoted.length) ) {
+
+				// excess is a negative index
+				match[0] = match[0].slice( 0, excess );
+				match[2] = unquoted.slice( 0, excess );
+			}
+
+			// Return only captures needed by the pseudo filter method (type and argument)
+			return match.slice( 0, 3 );
+		}
+	},
+
+	filter: {
+
+		"TAG": function( nodeNameSelector ) {
+			var nodeName = nodeNameSelector.replace( runescape, funescape ).toLowerCase();
+			return nodeNameSelector === "*" ?
+				function() { return true; } :
+				function( elem ) {
+					return elem.nodeName && elem.nodeName.toLowerCase() === nodeName;
+				};
+		},
+
+		"CLASS": function( className ) {
+			var pattern = classCache[ className + " " ];
+
+			return pattern ||
+				(pattern = new RegExp( "(^|" + whitespace + ")" + className + "(" + whitespace + "|$)" )) &&
+				classCache( className, function( elem ) {
+					return pattern.test( typeof elem.className === "string" && elem.className || typeof elem.getAttribute !== "undefined" && elem.getAttribute("class") || "" );
+				});
+		},
+
+		"ATTR": function( name, operator, check ) {
+			return function( elem ) {
+				var result = Sizzle.attr( elem, name );
+
+				if ( result == null ) {
+					return operator === "!=";
+				}
+				if ( !operator ) {
+					return true;
+				}
+
+				result += "";
+
+				return operator === "=" ? result === check :
+					operator === "!=" ? result !== check :
+					operator === "^=" ? check && result.indexOf( check ) === 0 :
+					operator === "*=" ? check && result.indexOf( check ) > -1 :
+					operator === "$=" ? check && result.slice( -check.length ) === check :
+					operator === "~=" ? ( " " + result.replace( rwhitespace, " " ) + " " ).indexOf( check ) > -1 :
+					operator === "|=" ? result === check || result.slice( 0, check.length + 1 ) === check + "-" :
+					false;
+			};
+		},
+
+		"CHILD": function( type, what, argument, first, last ) {
+			var simple = type.slice( 0, 3 ) !== "nth",
+				forward = type.slice( -4 ) !== "last",
+				ofType = what === "of-type";
+
+			return first === 1 && last === 0 ?
+
+				// Shortcut for :nth-*(n)
+				function( elem ) {
+					return !!elem.parentNode;
+				} :
+
+				function( elem, context, xml ) {
+					var cache, uniqueCache, outerCache, node, nodeIndex, start,
+						dir = simple !== forward ? "nextSibling" : "previousSibling",
+						parent = elem.parentNode,
+						name = ofType && elem.nodeName.toLowerCase(),
+						useCache = !xml && !ofType,
+						diff = false;
+
+					if ( parent ) {
+
+						// :(first|last|only)-(child|of-type)
+						if ( simple ) {
+							while ( dir ) {
+								node = elem;
+								while ( (node = node[ dir ]) ) {
+									if ( ofType ?
+										node.nodeName.toLowerCase() === name :
+										node.nodeType === 1 ) {
+
+										return false;
+									}
+								}
+								// Reverse direction for :only-* (if we haven't yet done so)
+								start = dir = type === "only" && !start && "nextSibling";
+							}
+							return true;
+						}
+
+						start = [ forward ? parent.firstChild : parent.lastChild ];
+
+						// non-xml :nth-child(...) stores cache data on `parent`
+						if ( forward && useCache ) {
+
+							// Seek `elem` from a previously-cached index
+
+							// ...in a gzip-friendly way
+							node = parent;
+							outerCache = node[ expando ] || (node[ expando ] = {});
+
+							// Support: IE <9 only
+							// Defend against cloned attroperties (jQuery gh-1709)
+							uniqueCache = outerCache[ node.uniqueID ] ||
+								(outerCache[ node.uniqueID ] = {});
+
+							cache = uniqueCache[ type ] || [];
+							nodeIndex = cache[ 0 ] === dirruns && cache[ 1 ];
+							diff = nodeIndex && cache[ 2 ];
+							node = nodeIndex && parent.childNodes[ nodeIndex ];
+
+							while ( (node = ++nodeIndex && node && node[ dir ] ||
+
+								// Fallback to seeking `elem` from the start
+								(diff = nodeIndex = 0) || start.pop()) ) {
+
+								// When found, cache indexes on `parent` and break
+								if ( node.nodeType === 1 && ++diff && node === elem ) {
+									uniqueCache[ type ] = [ dirruns, nodeIndex, diff ];
+									break;
+								}
+							}
+
+						} else {
+							// Use previously-cached element index if available
+							if ( useCache ) {
+								// ...in a gzip-friendly way
+								node = elem;
+								outerCache = node[ expando ] || (node[ expando ] = {});
+
+								// Support: IE <9 only
+								// Defend against cloned attroperties (jQuery gh-1709)
+								uniqueCache = outerCache[ node.uniqueID ] ||
+									(outerCache[ node.uniqueID ] = {});
+
+								cache = uniqueCache[ type ] || [];
+								nodeIndex = cache[ 0 ] === dirruns && cache[ 1 ];
+								diff = nodeIndex;
+							}
+
+							// xml :nth-child(...)
+							// or :nth-last-child(...) or :nth(-last)?-of-type(...)
+							if ( diff === false ) {
+								// Use the same loop as above to seek `elem` from the start
+								while ( (node = ++nodeIndex && node && node[ dir ] ||
+									(diff = nodeIndex = 0) || start.pop()) ) {
+
+									if ( ( ofType ?
+										node.nodeName.toLowerCase() === name :
+										node.nodeType === 1 ) &&
+										++diff ) {
+
+										// Cache the index of each encountered element
+										if ( useCache ) {
+											outerCache = node[ expando ] || (node[ expando ] = {});
+
+											// Support: IE <9 only
+											// Defend against cloned attroperties (jQuery gh-1709)
+											uniqueCache = outerCache[ node.uniqueID ] ||
+												(outerCache[ node.uniqueID ] = {});
+
+											uniqueCache[ type ] = [ dirruns, diff ];
+										}
+
+										if ( node === elem ) {
+											break;
+										}
+									}
+								}
+							}
+						}
+
+						// Incorporate the offset, then check against cycle size
+						diff -= last;
+						return diff === first || ( diff % first === 0 && diff / first >= 0 );
+					}
+				};
+		},
+
+		"PSEUDO": function( pseudo, argument ) {
+			// pseudo-class names are case-insensitive
+			// http://www.w3.org/TR/selectors/#pseudo-classes
+			// Prioritize by case sensitivity in case custom pseudos are added with uppercase letters
+			// Remember that setFilters inherits from pseudos
+			var args,
+				fn = Expr.pseudos[ pseudo ] || Expr.setFilters[ pseudo.toLowerCase() ] ||
+					Sizzle.error( "unsupported pseudo: " + pseudo );
+
+			// The user may use createPseudo to indicate that
+			// arguments are needed to create the filter function
+			// just as Sizzle does
+			if ( fn[ expando ] ) {
+				return fn( argument );
+			}
+
+			// But maintain support for old signatures
+			if ( fn.length > 1 ) {
+				args = [ pseudo, pseudo, "", argument ];
+				return Expr.setFilters.hasOwnProperty( pseudo.toLowerCase() ) ?
+					markFunction(function( seed, matches ) {
+						var idx,
+							matched = fn( seed, argument ),
+							i = matched.length;
+						while ( i-- ) {
+							idx = indexOf( seed, matched[i] );
+							seed[ idx ] = !( matches[ idx ] = matched[i] );
+						}
+					}) :
+					function( elem ) {
+						return fn( elem, 0, args );
+					};
+			}
+
+			return fn;
+		}
+	},
+
+	pseudos: {
+		// Potentially complex pseudos
+		"not": markFunction(function( selector ) {
+			// Trim the selector passed to compile
+			// to avoid treating leading and trailing
+			// spaces as combinators
+			var input = [],
+				results = [],
+				matcher = compile( selector.replace( rtrim, "$1" ) );
+
+			return matcher[ expando ] ?
+				markFunction(function( seed, matches, context, xml ) {
+					var elem,
+						unmatched = matcher( seed, null, xml, [] ),
+						i = seed.length;
+
+					// Match elements unmatched by `matcher`
+					while ( i-- ) {
+						if ( (elem = unmatched[i]) ) {
+							seed[i] = !(matches[i] = elem);
+						}
+					}
+				}) :
+				function( elem, context, xml ) {
+					input[0] = elem;
+					matcher( input, null, xml, results );
+					// Don't keep the element (issue #299)
+					input[0] = null;
+					return !results.pop();
+				};
+		}),
+
+		"has": markFunction(function( selector ) {
+			return function( elem ) {
+				return Sizzle( selector, elem ).length > 0;
+			};
+		}),
+
+		"contains": markFunction(function( text ) {
+			text = text.replace( runescape, funescape );
+			return function( elem ) {
+				return ( elem.textContent || elem.innerText || getText( elem ) ).indexOf( text ) > -1;
+			};
+		}),
+
+		// "Whether an element is represented by a :lang() selector
+		// is based solely on the element's language value
+		// being equal to the identifier C,
+		// or beginning with the identifier C immediately followed by "-".
+		// The matching of C against the element's language value is performed case-insensitively.
+		// The identifier C does not have to be a valid language name."
+		// http://www.w3.org/TR/selectors/#lang-pseudo
+		"lang": markFunction( function( lang ) {
+			// lang value must be a valid identifier
+			if ( !ridentifier.test(lang || "") ) {
+				Sizzle.error( "unsupported lang: " + lang );
+			}
+			lang = lang.replace( runescape, funescape ).toLowerCase();
+			return function( elem ) {
+				var elemLang;
+				do {
+					if ( (elemLang = documentIsHTML ?
+						elem.lang :
+						elem.getAttribute("xml:lang") || elem.getAttribute("lang")) ) {
+
+						elemLang = elemLang.toLowerCase();
+						return elemLang === lang || elemLang.indexOf( lang + "-" ) === 0;
+					}
+				} while ( (elem = elem.parentNode) && elem.nodeType === 1 );
+				return false;
+			};
+		}),
+
+		// Miscellaneous
+		"target": function( elem ) {
+			var hash = window.location && window.location.hash;
+			return hash && hash.slice( 1 ) === elem.id;
+		},
+
+		"root": function( elem ) {
+			return elem === docElem;
+		},
+
+		"focus": function( elem ) {
+			return elem === document.activeElement && (!document.hasFocus || document.hasFocus()) && !!(elem.type || elem.href || ~elem.tabIndex);
+		},
+
+		// Boolean properties
+		"enabled": function( elem ) {
+			return elem.disabled === false;
+		},
+
+		"disabled": function( elem ) {
+			return elem.disabled === true;
+		},
+
+		"checked": function( elem ) {
+			// In CSS3, :checked should return both checked and selected elements
+			// http://www.w3.org/TR/2011/REC-css3-selectors-20110929/#checked
+			var nodeName = elem.nodeName.toLowerCase();
+			return (nodeName === "input" && !!elem.checked) || (nodeName === "option" && !!elem.selected);
+		},
+
+		"selected": function( elem ) {
+			// Accessing this property makes selected-by-default
+			// options in Safari work properly
+			if ( elem.parentNode ) {
+				elem.parentNode.selectedIndex;
+			}
+
+			return elem.selected === true;
+		},
+
+		// Contents
+		"empty": function( elem ) {
+			// http://www.w3.org/TR/selectors/#empty-pseudo
+			// :empty is negated by element (1) or content nodes (text: 3; cdata: 4; entity ref: 5),
+			//   but not by others (comment: 8; processing instruction: 7; etc.)
+			// nodeType < 6 works because attributes (2) do not appear as children
+			for ( elem = elem.firstChild; elem; elem = elem.nextSibling ) {
+				if ( elem.nodeType < 6 ) {
+					return false;
+				}
+			}
+			return true;
+		},
+
+		"parent": function( elem ) {
+			return !Expr.pseudos["empty"]( elem );
+		},
+
+		// Element/input types
+		"header": function( elem ) {
+			return rheader.test( elem.nodeName );
+		},
+
+		"input": function( elem ) {
+			return rinputs.test( elem.nodeName );
+		},
+
+		"button": function( elem ) {
+			var name = elem.nodeName.toLowerCase();
+			return name === "input" && elem.type === "button" || name === "button";
+		},
+
+		"text": function( elem ) {
+			var attr;
+			return elem.nodeName.toLowerCase() === "input" &&
+				elem.type === "text" &&
+
+				// Support: IE<8
+				// New HTML5 attribute values (e.g., "search") appear with elem.type === "text"
+				( (attr = elem.getAttribute("type")) == null || attr.toLowerCase() === "text" );
+		},
+
+		// Position-in-collection
+		"first": createPositionalPseudo(function() {
+			return [ 0 ];
+		}),
+
+		"last": createPositionalPseudo(function( matchIndexes, length ) {
+			return [ length - 1 ];
+		}),
+
+		"eq": createPositionalPseudo(function( matchIndexes, length, argument ) {
+			return [ argument < 0 ? argument + length : argument ];
+		}),
+
+		"even": createPositionalPseudo(function( matchIndexes, length ) {
+			var i = 0;
+			for ( ; i < length; i += 2 ) {
+				matchIndexes.push( i );
+			}
+			return matchIndexes;
+		}),
+
+		"odd": createPositionalPseudo(function( matchIndexes, length ) {
+			var i = 1;
+			for ( ; i < length; i += 2 ) {
+				matchIndexes.push( i );
+			}
+			return matchIndexes;
+		}),
+
+		"lt": createPositionalPseudo(function( matchIndexes, length, argument ) {
+			var i = argument < 0 ? argument + length : argument;
+			for ( ; --i >= 0; ) {
+				matchIndexes.push( i );
+			}
+			return matchIndexes;
+		}),
+
+		"gt": createPositionalPseudo(function( matchIndexes, length, argument ) {
+			var i = argument < 0 ? argument + length : argument;
+			for ( ; ++i < length; ) {
+				matchIndexes.push( i );
+			}
+			return matchIndexes;
+		})
+	}
+};
+
+Expr.pseudos["nth"] = Expr.pseudos["eq"];
+
+// Add button/input type pseudos
+for ( i in { radio: true, checkbox: true, file: true, password: true, image: true } ) {
+	Expr.pseudos[ i ] = createInputPseudo( i );
+}
+for ( i in { submit: true, reset: true } ) {
+	Expr.pseudos[ i ] = createButtonPseudo( i );
+}
+
+// Easy API for creating new setFilters
+function setFilters() {}
+setFilters.prototype = Expr.filters = Expr.pseudos;
+Expr.setFilters = new setFilters();
+
+tokenize = Sizzle.tokenize = function( selector, parseOnly ) {
+	var matched, match, tokens, type,
+		soFar, groups, preFilters,
+		cached = tokenCache[ selector + " " ];
+
+	if ( cached ) {
+		return parseOnly ? 0 : cached.slice( 0 );
+	}
+
+	soFar = selector;
+	groups = [];
+	preFilters = Expr.preFilter;
+
+	while ( soFar ) {
+
+		// Comma and first run
+		if ( !matched || (match = rcomma.exec( soFar )) ) {
+			if ( match ) {
+				// Don't consume trailing commas as valid
+				soFar = soFar.slice( match[0].length ) || soFar;
+			}
+			groups.push( (tokens = []) );
+		}
+
+		matched = false;
+
+		// Combinators
+		if ( (match = rcombinators.exec( soFar )) ) {
+			matched = match.shift();
+			tokens.push({
+				value: matched,
+				// Cast descendant combinators to space
+				type: match[0].replace( rtrim, " " )
+			});
+			soFar = soFar.slice( matched.length );
+		}
+
+		// Filters
+		for ( type in Expr.filter ) {
+			if ( (match = matchExpr[ type ].exec( soFar )) && (!preFilters[ type ] ||
+				(match = preFilters[ type ]( match ))) ) {
+				matched = match.shift();
+				tokens.push({
+					value: matched,
+					type: type,
+					matches: match
+				});
+				soFar = soFar.slice( matched.length );
+			}
+		}
+
+		if ( !matched ) {
+			break;
+		}
+	}
+
+	// Return the length of the invalid excess
+	// if we're just parsing
+	// Otherwise, throw an error or return tokens
+	return parseOnly ?
+		soFar.length :
+		soFar ?
+			Sizzle.error( selector ) :
+			// Cache the tokens
+			tokenCache( selector, groups ).slice( 0 );
+};
+
+function toSelector( tokens ) {
+	var i = 0,
+		len = tokens.length,
+		selector = "";
+	for ( ; i < len; i++ ) {
+		selector += tokens[i].value;
+	}
+	return selector;
+}
+
+function addCombinator( matcher, combinator, base ) {
+	var dir = combinator.dir,
+		checkNonElements = base && dir === "parentNode",
+		doneName = done++;
+
+	return combinator.first ?
+		// Check against closest ancestor/preceding element
+		function( elem, context, xml ) {
+			while ( (elem = elem[ dir ]) ) {
+				if ( elem.nodeType === 1 || checkNonElements ) {
+					return matcher( elem, context, xml );
+				}
+			}
+		} :
+
+		// Check against all ancestor/preceding elements
+		function( elem, context, xml ) {
+			var oldCache, uniqueCache, outerCache,
+				newCache = [ dirruns, doneName ];
+
+			// We can't set arbitrary data on XML nodes, so they don't benefit from combinator caching
+			if ( xml ) {
+				while ( (elem = elem[ dir ]) ) {
+					if ( elem.nodeType === 1 || checkNonElements ) {
+						if ( matcher( elem, context, xml ) ) {
+							return true;
+						}
+					}
+				}
+			} else {
+				while ( (elem = elem[ dir ]) ) {
+					if ( elem.nodeType === 1 || checkNonElements ) {
+						outerCache = elem[ expando ] || (elem[ expando ] = {});
+
+						// Support: IE <9 only
+						// Defend against cloned attroperties (jQuery gh-1709)
+						uniqueCache = outerCache[ elem.uniqueID ] || (outerCache[ elem.uniqueID ] = {});
+
+						if ( (oldCache = uniqueCache[ dir ]) &&
+							oldCache[ 0 ] === dirruns && oldCache[ 1 ] === doneName ) {
+
+							// Assign to newCache so results back-propagate to previous elements
+							return (newCache[ 2 ] = oldCache[ 2 ]);
+						} else {
+							// Reuse newcache so results back-propagate to previous elements
+							uniqueCache[ dir ] = newCache;
+
+							// A match means we're done; a fail means we have to keep checking
+							if ( (newCache[ 2 ] = matcher( elem, context, xml )) ) {
+								return true;
+							}
+						}
+					}
+				}
+			}
+		};
+}
+
+function elementMatcher( matchers ) {
+	return matchers.length > 1 ?
+		function( elem, context, xml ) {
+			var i = matchers.length;
+			while ( i-- ) {
+				if ( !matchers[i]( elem, context, xml ) ) {
+					return false;
+				}
+			}
+			return true;
+		} :
+		matchers[0];
+}
+
+function multipleContexts( selector, contexts, results ) {
+	var i = 0,
+		len = contexts.length;
+	for ( ; i < len; i++ ) {
+		Sizzle( selector, contexts[i], results );
+	}
+	return results;
+}
+
+function condense( unmatched, map, filter, context, xml ) {
+	var elem,
+		newUnmatched = [],
+		i = 0,
+		len = unmatched.length,
+		mapped = map != null;
+
+	for ( ; i < len; i++ ) {
+		if ( (elem = unmatched[i]) ) {
+			if ( !filter || filter( elem, context, xml ) ) {
+				newUnmatched.push( elem );
+				if ( mapped ) {
+					map.push( i );
+				}
+			}
+		}
+	}
+
+	return newUnmatched;
+}
+
+function setMatcher( preFilter, selector, matcher, postFilter, postFinder, postSelector ) {
+	if ( postFilter && !postFilter[ expando ] ) {
+		postFilter = setMatcher( postFilter );
+	}
+	if ( postFinder && !postFinder[ expando ] ) {
+		postFinder = setMatcher( postFinder, postSelector );
+	}
+	return markFunction(function( seed, results, context, xml ) {
+		var temp, i, elem,
+			preMap = [],
+			postMap = [],
+			preexisting = results.length,
+
+			// Get initial elements from seed or context
+			elems = seed || multipleContexts( selector || "*", context.nodeType ? [ context ] : context, [] ),
+
+			// Prefilter to get matcher input, preserving a map for seed-results synchronization
+			matcherIn = preFilter && ( seed || !selector ) ?
+				condense( elems, preMap, preFilter, context, xml ) :
+				elems,
+
+			matcherOut = matcher ?
+				// If we have a postFinder, or filtered seed, or non-seed postFilter or preexisting results,
+				postFinder || ( seed ? preFilter : preexisting || postFilter ) ?
+
+					// ...intermediate processing is necessary
+					[] :
+
+					// ...otherwise use results directly
+					results :
+				matcherIn;
+
+		// Find primary matches
+		if ( matcher ) {
+			matcher( matcherIn, matcherOut, context, xml );
+		}
+
+		// Apply postFilter
+		if ( postFilter ) {
+			temp = condense( matcherOut, postMap );
+			postFilter( temp, [], context, xml );
+
+			// Un-match failing elements by moving them back to matcherIn
+			i = temp.length;
+			while ( i-- ) {
+				if ( (elem = temp[i]) ) {
+					matcherOut[ postMap[i] ] = !(matcherIn[ postMap[i] ] = elem);
+				}
+			}
+		}
+
+		if ( seed ) {
+			if ( postFinder || preFilter ) {
+				if ( postFinder ) {
+					// Get the final matcherOut by condensing this intermediate into postFinder contexts
+					temp = [];
+					i = matcherOut.length;
+					while ( i-- ) {
+						if ( (elem = matcherOut[i]) ) {
+							// Restore matcherIn since elem is not yet a final match
+							temp.push( (matcherIn[i] = elem) );
+						}
+					}
+					postFinder( null, (matcherOut = []), temp, xml );
+				}
+
+				// Move matched elements from seed to results to keep them synchronized
+				i = matcherOut.length;
+				while ( i-- ) {
+					if ( (elem = matcherOut[i]) &&
+						(temp = postFinder ? indexOf( seed, elem ) : preMap[i]) > -1 ) {
+
+						seed[temp] = !(results[temp] = elem);
+					}
+				}
+			}
+
+		// Add elements to results, through postFinder if defined
+		} else {
+			matcherOut = condense(
+				matcherOut === results ?
+					matcherOut.splice( preexisting, matcherOut.length ) :
+					matcherOut
+			);
+			if ( postFinder ) {
+				postFinder( null, results, matcherOut, xml );
+			} else {
+				push.apply( results, matcherOut );
+			}
+		}
+	});
+}
+
+function matcherFromTokens( tokens ) {
+	var checkContext, matcher, j,
+		len = tokens.length,
+		leadingRelative = Expr.relative[ tokens[0].type ],
+		implicitRelative = leadingRelative || Expr.relative[" "],
+		i = leadingRelative ? 1 : 0,
+
+		// The foundational matcher ensures that elements are reachable from top-level context(s)
+		matchContext = addCombinator( function( elem ) {
+			return elem === checkContext;
+		}, implicitRelative, true ),
+		matchAnyContext = addCombinator( function( elem ) {
+			return indexOf( checkContext, elem ) > -1;
+		}, implicitRelative, true ),
+		matchers = [ function( elem, context, xml ) {
+			var ret = ( !leadingRelative && ( xml || context !== outermostContext ) ) || (
+				(checkContext = context).nodeType ?
+					matchContext( elem, context, xml ) :
+					matchAnyContext( elem, context, xml ) );
+			// Avoid hanging onto element (issue #299)
+			checkContext = null;
+			return ret;
+		} ];
+
+	for ( ; i < len; i++ ) {
+		if ( (matcher = Expr.relative[ tokens[i].type ]) ) {
+			matchers = [ addCombinator(elementMatcher( matchers ), matcher) ];
+		} else {
+			matcher = Expr.filter[ tokens[i].type ].apply( null, tokens[i].matches );
+
+			// Return special upon seeing a positional matcher
+			if ( matcher[ expando ] ) {
+				// Find the next relative operator (if any) for proper handling
+				j = ++i;
+				for ( ; j < len; j++ ) {
+					if ( Expr.relative[ tokens[j].type ] ) {
+						break;
+					}
+				}
+				return setMatcher(
+					i > 1 && elementMatcher( matchers ),
+					i > 1 && toSelector(
+						// If the preceding token was a descendant combinator, insert an implicit any-element `*`
+						tokens.slice( 0, i - 1 ).concat({ value: tokens[ i - 2 ].type === " " ? "*" : "" })
+					).replace( rtrim, "$1" ),
+					matcher,
+					i < j && matcherFromTokens( tokens.slice( i, j ) ),
+					j < len && matcherFromTokens( (tokens = tokens.slice( j )) ),
+					j < len && toSelector( tokens )
+				);
+			}
+			matchers.push( matcher );
+		}
+	}
+
+	return elementMatcher( matchers );
+}
+
+function matcherFromGroupMatchers( elementMatchers, setMatchers ) {
+	var bySet = setMatchers.length > 0,
+		byElement = elementMatchers.length > 0,
+		superMatcher = function( seed, context, xml, results, outermost ) {
+			var elem, j, matcher,
+				matchedCount = 0,
+				i = "0",
+				unmatched = seed && [],
+				setMatched = [],
+				contextBackup = outermostContext,
+				// We must always have either seed elements or outermost context
+				elems = seed || byElement && Expr.find["TAG"]( "*", outermost ),
+				// Use integer dirruns iff this is the outermost matcher
+				dirrunsUnique = (dirruns += contextBackup == null ? 1 : Math.random() || 0.1),
+				len = elems.length;
+
+			if ( outermost ) {
+				outermostContext = context === document || context || outermost;
+			}
+
+			// Add elements passing elementMatchers directly to results
+			// Support: IE<9, Safari
+			// Tolerate NodeList properties (IE: "length"; Safari: <number>) matching elements by id
+			for ( ; i !== len && (elem = elems[i]) != null; i++ ) {
+				if ( byElement && elem ) {
+					j = 0;
+					if ( !context && elem.ownerDocument !== document ) {
+						setDocument( elem );
+						xml = !documentIsHTML;
+					}
+					while ( (matcher = elementMatchers[j++]) ) {
+						if ( matcher( elem, context || document, xml) ) {
+							results.push( elem );
+							break;
+						}
+					}
+					if ( outermost ) {
+						dirruns = dirrunsUnique;
+					}
+				}
+
+				// Track unmatched elements for set filters
+				if ( bySet ) {
+					// They will have gone through all possible matchers
+					if ( (elem = !matcher && elem) ) {
+						matchedCount--;
+					}
+
+					// Lengthen the array for every element, matched or not
+					if ( seed ) {
+						unmatched.push( elem );
+					}
+				}
+			}
+
+			// `i` is now the count of elements visited above, and adding it to `matchedCount`
+			// makes the latter nonnegative.
+			matchedCount += i;
+
+			// Apply set filters to unmatched elements
+			// NOTE: This can be skipped if there are no unmatched elements (i.e., `matchedCount`
+			// equals `i`), unless we didn't visit _any_ elements in the above loop because we have
+			// no element matchers and no seed.
+			// Incrementing an initially-string "0" `i` allows `i` to remain a string only in that
+			// case, which will result in a "00" `matchedCount` that differs from `i` but is also
+			// numerically zero.
+			if ( bySet && i !== matchedCount ) {
+				j = 0;
+				while ( (matcher = setMatchers[j++]) ) {
+					matcher( unmatched, setMatched, context, xml );
+				}
+
+				if ( seed ) {
+					// Reintegrate element matches to eliminate the need for sorting
+					if ( matchedCount > 0 ) {
+						while ( i-- ) {
+							if ( !(unmatched[i] || setMatched[i]) ) {
+								setMatched[i] = pop.call( results );
+							}
+						}
+					}
+
+					// Discard index placeholder values to get only actual matches
+					setMatched = condense( setMatched );
+				}
+
+				// Add matches to results
+				push.apply( results, setMatched );
+
+				// Seedless set matches succeeding multiple successful matchers stipulate sorting
+				if ( outermost && !seed && setMatched.length > 0 &&
+					( matchedCount + setMatchers.length ) > 1 ) {
+
+					Sizzle.uniqueSort( results );
+				}
+			}
+
+			// Override manipulation of globals by nested matchers
+			if ( outermost ) {
+				dirruns = dirrunsUnique;
+				outermostContext = contextBackup;
+			}
+
+			return unmatched;
+		};
+
+	return bySet ?
+		markFunction( superMatcher ) :
+		superMatcher;
+}
+
+compile = Sizzle.compile = function( selector, match /* Internal Use Only */ ) {
+	var i,
+		setMatchers = [],
+		elementMatchers = [],
+		cached = compilerCache[ selector + " " ];
+
+	if ( !cached ) {
+		// Generate a function of recursive functions that can be used to check each element
+		if ( !match ) {
+			match = tokenize( selector );
+		}
+		i = match.length;
+		while ( i-- ) {
+			cached = matcherFromTokens( match[i] );
+			if ( cached[ expando ] ) {
+				setMatchers.push( cached );
+			} else {
+				elementMatchers.push( cached );
+			}
+		}
+
+		// Cache the compiled function
+		cached = compilerCache( selector, matcherFromGroupMatchers( elementMatchers, setMatchers ) );
+
+		// Save selector and tokenization
+		cached.selector = selector;
+	}
+	return cached;
+};
+
+/**
+ * A low-level selection function that works with Sizzle's compiled
+ *  selector functions
+ * @param {String|Function} selector A selector or a pre-compiled
+ *  selector function built with Sizzle.compile
+ * @param {Element} context
+ * @param {Array} [results]
+ * @param {Array} [seed] A set of elements to match against
+ */
+select = Sizzle.select = function( selector, context, results, seed ) {
+	var i, tokens, token, type, find,
+		compiled = typeof selector === "function" && selector,
+		match = !seed && tokenize( (selector = compiled.selector || selector) );
+
+	results = results || [];
+
+	// Try to minimize operations if there is only one selector in the list and no seed
+	// (the latter of which guarantees us context)
+	if ( match.length === 1 ) {
+
+		// Reduce context if the leading compound selector is an ID
+		tokens = match[0] = match[0].slice( 0 );
+		if ( tokens.length > 2 && (token = tokens[0]).type === "ID" &&
+				support.getById && context.nodeType === 9 && documentIsHTML &&
+				Expr.relative[ tokens[1].type ] ) {
+
+			context = ( Expr.find["ID"]( token.matches[0].replace(runescape, funescape), context ) || [] )[0];
+			if ( !context ) {
+				return results;
+
+			// Precompiled matchers will still verify ancestry, so step up a level
+			} else if ( compiled ) {
+				context = context.parentNode;
+			}
+
+			selector = selector.slice( tokens.shift().value.length );
+		}
+
+		// Fetch a seed set for right-to-left matching
+		i = matchExpr["needsContext"].test( selector ) ? 0 : tokens.length;
+		while ( i-- ) {
+			token = tokens[i];
+
+			// Abort if we hit a combinator
+			if ( Expr.relative[ (type = token.type) ] ) {
+				break;
+			}
+			if ( (find = Expr.find[ type ]) ) {
+				// Search, expanding context for leading sibling combinators
+				if ( (seed = find(
+					token.matches[0].replace( runescape, funescape ),
+					rsibling.test( tokens[0].type ) && testContext( context.parentNode ) || context
+				)) ) {
+
+					// If seed is empty or no tokens remain, we can return early
+					tokens.splice( i, 1 );
+					selector = seed.length && toSelector( tokens );
+					if ( !selector ) {
+						push.apply( results, seed );
+						return results;
+					}
+
+					break;
+				}
+			}
+		}
+	}
+
+	// Compile and execute a filtering function if one is not provided
+	// Provide `match` to avoid retokenization if we modified the selector above
+	( compiled || compile( selector, match ) )(
+		seed,
+		context,
+		!documentIsHTML,
+		results,
+		!context || rsibling.test( selector ) && testContext( context.parentNode ) || context
+	);
+	return results;
+};
+
+// One-time assignments
+
+// Sort stability
+support.sortStable = expando.split("").sort( sortOrder ).join("") === expando;
+
+// Support: Chrome 14-35+
+// Always assume duplicates if they aren't passed to the comparison function
+support.detectDuplicates = !!hasDuplicate;
+
+// Initialize against the default document
+setDocument();
+
+// Support: Webkit<537.32 - Safari 6.0.3/Chrome 25 (fixed in Chrome 27)
+// Detached nodes confoundingly follow *each other*
+support.sortDetached = assert(function( div1 ) {
+	// Should return 1, but returns 4 (following)
+	return div1.compareDocumentPosition( document.createElement("div") ) & 1;
+});
+
+// Support: IE<8
+// Prevent attribute/property "interpolation"
+// http://msdn.microsoft.com/en-us/library/ms536429%28VS.85%29.aspx
+if ( !assert(function( div ) {
+	div.innerHTML = "<a href='#'></a>";
+	return div.firstChild.getAttribute("href") === "#" ;
+}) ) {
+	addHandle( "type|href|height|width", function( elem, name, isXML ) {
+		if ( !isXML ) {
+			return elem.getAttribute( name, name.toLowerCase() === "type" ? 1 : 2 );
+		}
+	});
+}
+
+// Support: IE<9
+// Use defaultValue in place of getAttribute("value")
+if ( !support.attributes || !assert(function( div ) {
+	div.innerHTML = "<input/>";
+	div.firstChild.setAttribute( "value", "" );
+	return div.firstChild.getAttribute( "value" ) === "";
+}) ) {
+	addHandle( "value", function( elem, name, isXML ) {
+		if ( !isXML && elem.nodeName.toLowerCase() === "input" ) {
+			return elem.defaultValue;
+		}
+	});
+}
+
+// Support: IE<9
+// Use getAttributeNode to fetch booleans when getAttribute lies
+if ( !assert(function( div ) {
+	return div.getAttribute("disabled") == null;
+}) ) {
+	addHandle( booleans, function( elem, name, isXML ) {
+		var val;
+		if ( !isXML ) {
+			return elem[ name ] === true ? name.toLowerCase() :
+					(val = elem.getAttributeNode( name )) && val.specified ?
+					val.value :
+				null;
+		}
+	});
+}
+
+return Sizzle;
+
+})( window );
+
+
+
+jQuery.find = Sizzle;
+jQuery.expr = Sizzle.selectors;
+jQuery.expr[ ":" ] = jQuery.expr.pseudos;
+jQuery.uniqueSort = jQuery.unique = Sizzle.uniqueSort;
+jQuery.text = Sizzle.getText;
+jQuery.isXMLDoc = Sizzle.isXML;
+jQuery.contains = Sizzle.contains;
+
+
+
+var dir = function( elem, dir, until ) {
+	var matched = [],
+		truncate = until !== undefined;
+
+	while ( ( elem = elem[ dir ] ) && elem.nodeType !== 9 ) {
+		if ( elem.nodeType === 1 ) {
+			if ( truncate && jQuery( elem ).is( until ) ) {
+				break;
+			}
+			matched.push( elem );
+		}
+	}
+	return matched;
+};
+
+
+var siblings = function( n, elem ) {
+	var matched = [];
+
+	for ( ; n; n = n.nextSibling ) {
+		if ( n.nodeType === 1 && n !== elem ) {
+			matched.push( n );
+		}
+	}
+
+	return matched;
+};
+
+
+var rneedsContext = jQuery.expr.match.needsContext;
+
+var rsingleTag = ( /^<([\w-]+)\s*\/?>(?:<\/\1>|)$/ );
+
+
+
+var risSimple = /^.[^:#\[\.,]*$/;
+
+// Implement the identical functionality for filter and not
+function winnow( elements, qualifier, not ) {
+	if ( jQuery.isFunction( qualifier ) ) {
+		return jQuery.grep( elements, function( elem, i ) {
+			/* jshint -W018 */
+			return !!qualifier.call( elem, i, elem ) !== not;
+		} );
+
+	}
+
+	if ( qualifier.nodeType ) {
+		return jQuery.grep( elements, function( elem ) {
+			return ( elem === qualifier ) !== not;
+		} );
+
+	}
+
+	if ( typeof qualifier === "string" ) {
+		if ( risSimple.test( qualifier ) ) {
+			return jQuery.filter( qualifier, elements, not );
+		}
+
+		qualifier = jQuery.filter( qualifier, elements );
+	}
+
+	return jQuery.grep( elements, function( elem ) {
+		return ( jQuery.inArray( elem, qualifier ) > -1 ) !== not;
+	} );
+}
+
+jQuery.filter = function( expr, elems, not ) {
+	var elem = elems[ 0 ];
+
+	if ( not ) {
+		expr = ":not(" + expr + ")";
+	}
+
+	return elems.length === 1 && elem.nodeType === 1 ?
+		jQuery.find.matchesSelector( elem, expr ) ? [ elem ] : [] :
+		jQuery.find.matches( expr, jQuery.grep( elems, function( elem ) {
+			return elem.nodeType === 1;
+		} ) );
+};
+
+jQuery.fn.extend( {
+	find: function( selector ) {
+		var i,
+			ret = [],
+			self = this,
+			len = self.length;
+
+		if ( typeof selector !== "string" ) {
+			return this.pushStack( jQuery( selector ).filter( function() {
+				for ( i = 0; i < len; i++ ) {
+					if ( jQuery.contains( self[ i ], this ) ) {
+						return true;
+					}
+				}
+			} ) );
+		}
+
+		for ( i = 0; i < len; i++ ) {
+			jQuery.find( selector, self[ i ], ret );
+		}
+
+		// Needed because $( selector, context ) becomes $( context ).find( selector )
+		ret = this.pushStack( len > 1 ? jQuery.unique( ret ) : ret );
+		ret.selector = this.selector ? this.selector + " " + selector : selector;
+		return ret;
+	},
+	filter: function( selector ) {
+		return this.pushStack( winnow( this, selector || [], false ) );
+	},
+	not: function( selector ) {
+		return this.pushStack( winnow( this, selector || [], true ) );
+	},
+	is: function( selector ) {
+		return !!winnow(
+			this,
+
+			// If this is a positional/relative selector, check membership in the returned set
+			// so $("p:first").is("p:last") won't return true for a doc with two "p".
+			typeof selector === "string" && rneedsContext.test( selector ) ?
+				jQuery( selector ) :
+				selector || [],
+			false
+		).length;
+	}
+} );
+
+
+// Initialize a jQuery object
+
+
+// A central reference to the root jQuery(document)
+var rootjQuery,
+
+	// A simple way to check for HTML strings
+	// Prioritize #id over <tag> to avoid XSS via location.hash (#9521)
+	// Strict HTML recognition (#11290: must start with <)
+	rquickExpr = /^(?:\s*(<[\w\W]+>)[^>]*|#([\w-]*))$/,
+
+	init = jQuery.fn.init = function( selector, context, root ) {
+		var match, elem;
+
+		// HANDLE: $(""), $(null), $(undefined), $(false)
+		if ( !selector ) {
+			return this;
+		}
+
+		// init accepts an alternate rootjQuery
+		// so migrate can support jQuery.sub (gh-2101)
+		root = root || rootjQuery;
+
+		// Handle HTML strings
+		if ( typeof selector === "string" ) {
+			if ( selector.charAt( 0 ) === "<" &&
+				selector.charAt( selector.length - 1 ) === ">" &&
+				selector.length >= 3 ) {
+
+				// Assume that strings that start and end with <> are HTML and skip the regex check
+				match = [ null, selector, null ];
+
+			} else {
+				match = rquickExpr.exec( selector );
+			}
+
+			// Match html or make sure no context is specified for #id
+			if ( match && ( match[ 1 ] || !context ) ) {
+
+				// HANDLE: $(html) -> $(array)
+				if ( match[ 1 ] ) {
+					context = context instanceof jQuery ? context[ 0 ] : context;
+
+					// scripts is true for back-compat
+					// Intentionally let the error be thrown if parseHTML is not present
+					jQuery.merge( this, jQuery.parseHTML(
+						match[ 1 ],
+						context && context.nodeType ? context.ownerDocument || context : document,
+						true
+					) );
+
+					// HANDLE: $(html, props)
+					if ( rsingleTag.test( match[ 1 ] ) && jQuery.isPlainObject( context ) ) {
+						for ( match in context ) {
+
+							// Properties of context are called as methods if possible
+							if ( jQuery.isFunction( this[ match ] ) ) {
+								this[ match ]( context[ match ] );
+
+							// ...and otherwise set as attributes
+							} else {
+								this.attr( match, context[ match ] );
+							}
+						}
+					}
+
+					return this;
+
+				// HANDLE: $(#id)
+				} else {
+					elem = document.getElementById( match[ 2 ] );
+
+					// Check parentNode to catch when Blackberry 4.6 returns
+					// nodes that are no longer in the document #6963
+					if ( elem && elem.parentNode ) {
+
+						// Handle the case where IE and Opera return items
+						// by name instead of ID
+						if ( elem.id !== match[ 2 ] ) {
+							return rootjQuery.find( selector );
+						}
+
+						// Otherwise, we inject the element directly into the jQuery object
+						this.length = 1;
+						this[ 0 ] = elem;
+					}
+
+					this.context = document;
+					this.selector = selector;
+					return this;
+				}
+
+			// HANDLE: $(expr, $(...))
+			} else if ( !context || context.jquery ) {
+				return ( context || root ).find( selector );
+
+			// HANDLE: $(expr, context)
+			// (which is just equivalent to: $(context).find(expr)
+			} else {
+				return this.constructor( context ).find( selector );
+			}
+
+		// HANDLE: $(DOMElement)
+		} else if ( selector.nodeType ) {
+			this.context = this[ 0 ] = selector;
+			this.length = 1;
+			return this;
+
+		// HANDLE: $(function)
+		// Shortcut for document ready
+		} else if ( jQuery.isFunction( selector ) ) {
+			return typeof root.ready !== "undefined" ?
+				root.ready( selector ) :
+
+				// Execute immediately if ready is not present
+				selector( jQuery );
+		}
+
+		if ( selector.selector !== undefined ) {
+			this.selector = selector.selector;
+			this.context = selector.context;
+		}
+
+		return jQuery.makeArray( selector, this );
+	};
+
+// Give the init function the jQuery prototype for later instantiation
+init.prototype = jQuery.fn;
+
+// Initialize central reference
+rootjQuery = jQuery( document );
+
+
+var rparentsprev = /^(?:parents|prev(?:Until|All))/,
+
+	// methods guaranteed to produce a unique set when starting from a unique set
+	guaranteedUnique = {
+		children: true,
+		contents: true,
+		next: true,
+		prev: true
+	};
+
+jQuery.fn.extend( {
+	has: function( target ) {
+		var i,
+			targets = jQuery( target, this ),
+			len = targets.length;
+
+		return this.filter( function() {
+			for ( i = 0; i < len; i++ ) {
+				if ( jQuery.contains( this, targets[ i ] ) ) {
+					return true;
+				}
+			}
+		} );
+	},
+
+	closest: function( selectors, context ) {
+		var cur,
+			i = 0,
+			l = this.length,
+			matched = [],
+			pos = rneedsContext.test( selectors ) || typeof selectors !== "string" ?
+				jQuery( selectors, context || this.context ) :
+				0;
+
+		for ( ; i < l; i++ ) {
+			for ( cur = this[ i ]; cur && cur !== context; cur = cur.parentNode ) {
+
+				// Always skip document fragments
+				if ( cur.nodeType < 11 && ( pos ?
+					pos.index( cur ) > -1 :
+
+					// Don't pass non-elements to Sizzle
+					cur.nodeType === 1 &&
+						jQuery.find.matchesSelector( cur, selectors ) ) ) {
+
+					matched.push( cur );
+					break;
+				}
+			}
+		}
+
+		return this.pushStack( matched.length > 1 ? jQuery.uniqueSort( matched ) : matched );
+	},
+
+	// Determine the position of an element within
+	// the matched set of elements
+	index: function( elem ) {
+
+		// No argument, return index in parent
+		if ( !elem ) {
+			return ( this[ 0 ] && this[ 0 ].parentNode ) ? this.first().prevAll().length : -1;
+		}
+
+		// index in selector
+		if ( typeof elem === "string" ) {
+			return jQuery.inArray( this[ 0 ], jQuery( elem ) );
+		}
+
+		// Locate the position of the desired element
+		return jQuery.inArray(
+
+			// If it receives a jQuery object, the first element is used
+			elem.jquery ? elem[ 0 ] : elem, this );
+	},
+
+	add: function( selector, context ) {
+		return this.pushStack(
+			jQuery.uniqueSort(
+				jQuery.merge( this.get(), jQuery( selector, context ) )
+			)
+		);
+	},
+
+	addBack: function( selector ) {
+		return this.add( selector == null ?
+			this.prevObject : this.prevObject.filter( selector )
+		);
+	}
+} );
+
+function sibling( cur, dir ) {
+	do {
+		cur = cur[ dir ];
+	} while ( cur && cur.nodeType !== 1 );
+
+	return cur;
+}
+
+jQuery.each( {
+	parent: function( elem ) {
+		var parent = elem.parentNode;
+		return parent && parent.nodeType !== 11 ? parent : null;
+	},
+	parents: function( elem ) {
+		return dir( elem, "parentNode" );
+	},
+	parentsUntil: function( elem, i, until ) {
+		return dir( elem, "parentNode", until );
+	},
+	next: function( elem ) {
+		return sibling( elem, "nextSibling" );
+	},
+	prev: function( elem ) {
+		return sibling( elem, "previousSibling" );
+	},
+	nextAll: function( elem ) {
+		return dir( elem, "nextSibling" );
+	},
+	prevAll: function( elem ) {
+		return dir( elem, "previousSibling" );
+	},
+	nextUntil: function( elem, i, until ) {
+		return dir( elem, "nextSibling", until );
+	},
+	prevUntil: function( elem, i, until ) {
+		return dir( elem, "previousSibling", until );
+	},
+	siblings: function( elem ) {
+		return siblings( ( elem.parentNode || {} ).firstChild, elem );
+	},
+	children: function( elem ) {
+		return siblings( elem.firstChild );
+	},
+	contents: function( elem ) {
+		return jQuery.nodeName( elem, "iframe" ) ?
+			elem.contentDocument || elem.contentWindow.document :
+			jQuery.merge( [], elem.childNodes );
+	}
+}, function( name, fn ) {
+	jQuery.fn[ name ] = function( until, selector ) {
+		var ret = jQuery.map( this, fn, until );
+
+		if ( name.slice( -5 ) !== "Until" ) {
+			selector = until;
+		}
+
+		if ( selector && typeof selector === "string" ) {
+			ret = jQuery.filter( selector, ret );
+		}
+
+		if ( this.length > 1 ) {
+
+			// Remove duplicates
+			if ( !guaranteedUnique[ name ] ) {
+				ret = jQuery.uniqueSort( ret );
+			}
+
+			// Reverse order for parents* and prev-derivatives
+			if ( rparentsprev.test( name ) ) {
+				ret = ret.reverse();
+			}
+		}
+
+		return this.pushStack( ret );
+	};
+} );
+var rnotwhite = ( /\S+/g );
+
+
+
+// Convert String-formatted options into Object-formatted ones
+function createOptions( options ) {
+	var object = {};
+	jQuery.each( options.match( rnotwhite ) || [], function( _, flag ) {
+		object[ flag ] = true;
+	} );
+	return object;
+}
+
+/*
+ * Create a callback list using the following parameters:
+ *
+ *	options: an optional list of space-separated options that will change how
+ *			the callback list behaves or a more traditional option object
+ *
+ * By default a callback list will act like an event callback list and can be
+ * "fired" multiple times.
+ *
+ * Possible options:
+ *
+ *	once:			will ensure the callback list can only be fired once (like a Deferred)
+ *
+ *	memory:			will keep track of previous values and will call any callback added
+ *					after the list has been fired right away with the latest "memorized"
+ *					values (like a Deferred)
+ *
+ *	unique:			will ensure a callback can only be added once (no duplicate in the list)
+ *
+ *	stopOnFalse:	interrupt callings when a callback returns false
+ *
+ */
+jQuery.Callbacks = function( options ) {
+
+	// Convert options from String-formatted to Object-formatted if needed
+	// (we check in cache first)
+	options = typeof options === "string" ?
+		createOptions( options ) :
+		jQuery.extend( {}, options );
+
+	var // Flag to know if list is currently firing
+		firing,
+
+		// Last fire value for non-forgettable lists
+		memory,
+
+		// Flag to know if list was already fired
+		fired,
+
+		// Flag to prevent firing
+		locked,
+
+		// Actual callback list
+		list = [],
+
+		// Queue of execution data for repeatable lists
+		queue = [],
+
+		// Index of currently firing callback (modified by add/remove as needed)
+		firingIndex = -1,
+
+		// Fire callbacks
+		fire = function() {
+
+			// Enforce single-firing
+			locked = options.once;
+
+			// Execute callbacks for all pending executions,
+			// respecting firingIndex overrides and runtime changes
+			fired = firing = true;
+			for ( ; queue.length; firingIndex = -1 ) {
+				memory = queue.shift();
+				while ( ++firingIndex < list.length ) {
+
+					// Run callback and check for early termination
+					if ( list[ firingIndex ].apply( memory[ 0 ], memory[ 1 ] ) === false &&
+						options.stopOnFalse ) {
+
+						// Jump to end and forget the data so .add doesn't re-fire
+						firingIndex = list.length;
+						memory = false;
+					}
+				}
+			}
+
+			// Forget the data if we're done with it
+			if ( !options.memory ) {
+				memory = false;
+			}
+
+			firing = false;
+
+			// Clean up if we're done firing for good
+			if ( locked ) {
+
+				// Keep an empty list if we have data for future add calls
+				if ( memory ) {
+					list = [];
+
+				// Otherwise, this object is spent
+				} else {
+					list = "";
+				}
+			}
+		},
+
+		// Actual Callbacks object
+		self = {
+
+			// Add a callback or a collection of callbacks to the list
+			add: function() {
+				if ( list ) {
+
+					// If we have memory from a past run, we should fire after adding
+					if ( memory && !firing ) {
+						firingIndex = list.length - 1;
+						queue.push( memory );
+					}
+
+					( function add( args ) {
+						jQuery.each( args, function( _, arg ) {
+							if ( jQuery.isFunction( arg ) ) {
+								if ( !options.unique || !self.has( arg ) ) {
+									list.push( arg );
+								}
+							} else if ( arg && arg.length && jQuery.type( arg ) !== "string" ) {
+
+								// Inspect recursively
+								add( arg );
+							}
+						} );
+					} )( arguments );
+
+					if ( memory && !firing ) {
+						fire();
+					}
+				}
+				return this;
+			},
+
+			// Remove a callback from the list
+			remove: function() {
+				jQuery.each( arguments, function( _, arg ) {
+					var index;
+					while ( ( index = jQuery.inArray( arg, list, index ) ) > -1 ) {
+						list.splice( index, 1 );
+
+						// Handle firing indexes
+						if ( index <= firingIndex ) {
+							firingIndex--;
+						}
+					}
+				} );
+				return this;
+			},
+
+			// Check if a given callback is in the list.
+			// If no argument is given, return whether or not list has callbacks attached.
+			has: function( fn ) {
+				return fn ?
+					jQuery.inArray( fn, list ) > -1 :
+					list.length > 0;
+			},
+
+			// Remove all callbacks from the list
+			empty: function() {
+				if ( list ) {
+					list = [];
+				}
+				return this;
+			},
+
+			// Disable .fire and .add
+			// Abort any current/pending executions
+			// Clear all callbacks and values
+			disable: function() {
+				locked = queue = [];
+				list = memory = "";
+				return this;
+			},
+			disabled: function() {
+				return !list;
+			},
+
+			// Disable .fire
+			// Also disable .add unless we have memory (since it would have no effect)
+			// Abort any pending executions
+			lock: function() {
+				locked = true;
+				if ( !memory ) {
+					self.disable();
+				}
+				return this;
+			},
+			locked: function() {
+				return !!locked;
+			},
+
+			// Call all callbacks with the given context and arguments
+			fireWith: function( context, args ) {
+				if ( !locked ) {
+					args = args || [];
+					args = [ context, args.slice ? args.slice() : args ];
+					queue.push( args );
+					if ( !firing ) {
+						fire();
+					}
+				}
+				return this;
+			},
+
+			// Call all the callbacks with the given arguments
+			fire: function() {
+				self.fireWith( this, arguments );
+				return this;
+			},
+
+			// To know if the callbacks have already been called at least once
+			fired: function() {
+				return !!fired;
+			}
+		};
+
+	return self;
+};
+
+
+jQuery.extend( {
+
+	Deferred: function( func ) {
+		var tuples = [
+
+				// action, add listener, listener list, final state
+				[ "resolve", "done", jQuery.Callbacks( "once memory" ), "resolved" ],
+				[ "reject", "fail", jQuery.Callbacks( "once memory" ), "rejected" ],
+				[ "notify", "progress", jQuery.Callbacks( "memory" ) ]
+			],
+			state = "pending",
+			promise = {
+				state: function() {
+					return state;
+				},
+				always: function() {
+					deferred.done( arguments ).fail( arguments );
+					return this;
+				},
+				then: function( /* fnDone, fnFail, fnProgress */ ) {
+					var fns = arguments;
+					return jQuery.Deferred( function( newDefer ) {
+						jQuery.each( tuples, function( i, tuple ) {
+							var fn = jQuery.isFunction( fns[ i ] ) && fns[ i ];
+
+							// deferred[ done | fail | progress ] for forwarding actions to newDefer
+							deferred[ tuple[ 1 ] ]( function() {
+								var returned = fn && fn.apply( this, arguments );
+								if ( returned && jQuery.isFunction( returned.promise ) ) {
+									returned.promise()
+										.progress( newDefer.notify )
+										.done( newDefer.resolve )
+										.fail( newDefer.reject );
+								} else {
+									newDefer[ tuple[ 0 ] + "With" ](
+										this === promise ? newDefer.promise() : this,
+										fn ? [ returned ] : arguments
+									);
+								}
+							} );
+						} );
+						fns = null;
+					} ).promise();
+				},
+
+				// Get a promise for this deferred
+				// If obj is provided, the promise aspect is added to the object
+				promise: function( obj ) {
+					return obj != null ? jQuery.extend( obj, promise ) : promise;
+				}
+			},
+			deferred = {};
+
+		// Keep pipe for back-compat
+		promise.pipe = promise.then;
+
+		// Add list-specific methods
+		jQuery.each( tuples, function( i, tuple ) {
+			var list = tuple[ 2 ],
+				stateString = tuple[ 3 ];
+
+			// promise[ done | fail | progress ] = list.add
+			promise[ tuple[ 1 ] ] = list.add;
+
+			// Handle state
+			if ( stateString ) {
+				list.add( function() {
+
+					// state = [ resolved | rejected ]
+					state = stateString;
+
+				// [ reject_list | resolve_list ].disable; progress_list.lock
+				}, tuples[ i ^ 1 ][ 2 ].disable, tuples[ 2 ][ 2 ].lock );
+			}
+
+			// deferred[ resolve | reject | notify ]
+			deferred[ tuple[ 0 ] ] = function() {
+				deferred[ tuple[ 0 ] + "With" ]( this === deferred ? promise : this, arguments );
+				return this;
+			};
+			deferred[ tuple[ 0 ] + "With" ] = list.fireWith;
+		} );
+
+		// Make the deferred a promise
+		promise.promise( deferred );
+
+		// Call given func if any
+		if ( func ) {
+			func.call( deferred, deferred );
+		}
+
+		// All done!
+		return deferred;
+	},
+
+	// Deferred helper
+	when: function( subordinate /* , ..., subordinateN */ ) {
+		var i = 0,
+			resolveValues = slice.call( arguments ),
+			length = resolveValues.length,
+
+			// the count of uncompleted subordinates
+			remaining = length !== 1 ||
+				( subordinate && jQuery.isFunction( subordinate.promise ) ) ? length : 0,
+
+			// the master Deferred.
+			// If resolveValues consist of only a single Deferred, just use that.
+			deferred = remaining === 1 ? subordinate : jQuery.Deferred(),
+
+			// Update function for both resolve and progress values
+			updateFunc = function( i, contexts, values ) {
+				return function( value ) {
+					contexts[ i ] = this;
+					values[ i ] = arguments.length > 1 ? slice.call( arguments ) : value;
+					if ( values === progressValues ) {
+						deferred.notifyWith( contexts, values );
+
+					} else if ( !( --remaining ) ) {
+						deferred.resolveWith( contexts, values );
+					}
+				};
+			},
+
+			progressValues, progressContexts, resolveContexts;
+
+		// add listeners to Deferred subordinates; treat others as resolved
+		if ( length > 1 ) {
+			progressValues = new Array( length );
+			progressContexts = new Array( length );
+			resolveContexts = new Array( length );
+			for ( ; i < length; i++ ) {
+				if ( resolveValues[ i ] && jQuery.isFunction( resolveValues[ i ].promise ) ) {
+					resolveValues[ i ].promise()
+						.progress( updateFunc( i, progressContexts, progressValues ) )
+						.done( updateFunc( i, resolveContexts, resolveValues ) )
+						.fail( deferred.reject );
+				} else {
+					--remaining;
+				}
+			}
+		}
+
+		// if we're not waiting on anything, resolve the master
+		if ( !remaining ) {
+			deferred.resolveWith( resolveContexts, resolveValues );
+		}
+
+		return deferred.promise();
+	}
+} );
+
+
+// The deferred used on DOM ready
+var readyList;
+
+jQuery.fn.ready = function( fn ) {
+
+	// Add the callback
+	jQuery.ready.promise().done( fn );
+
+	return this;
+};
+
+jQuery.extend( {
+
+	// Is the DOM ready to be used? Set to true once it occurs.
+	isReady: false,
+
+	// A counter to track how many items to wait for before
+	// the ready event fires. See #6781
+	readyWait: 1,
+
+	// Hold (or release) the ready event
+	holdReady: function( hold ) {
+		if ( hold ) {
+			jQuery.readyWait++;
+		} else {
+			jQuery.ready( true );
+		}
+	},
+
+	// Handle when the DOM is ready
+	ready: function( wait ) {
+
+		// Abort if there are pending holds or we're already ready
+		if ( wait === true ? --jQuery.readyWait : jQuery.isReady ) {
+			return;
+		}
+
+		// Remember that the DOM is ready
+		jQuery.isReady = true;
+
+		// If a normal DOM Ready event fired, decrement, and wait if need be
+		if ( wait !== true && --jQuery.readyWait > 0 ) {
+			return;
+		}
+
+		// If there are functions bound, to execute
+		readyList.resolveWith( document, [ jQuery ] );
+
+		// Trigger any bound ready events
+		if ( jQuery.fn.triggerHandler ) {
+			jQuery( document ).triggerHandler( "ready" );
+			jQuery( document ).off( "ready" );
+		}
+	}
+} );
+
+/**
+ * Clean-up method for dom ready events
+ */
+function detach() {
+	if ( document.addEventListener ) {
+		document.removeEventListener( "DOMContentLoaded", completed );
+		window.removeEventListener( "load", completed );
+
+	} else {
+		document.detachEvent( "onreadystatechange", completed );
+		window.detachEvent( "onload", completed );
+	}
+}
+
+/**
+ * The ready event handler and self cleanup method
+ */
+function completed() {
+
+	// readyState === "complete" is good enough for us to call the dom ready in oldIE
+	if ( document.addEventListener ||
+		window.event.type === "load" ||
+		document.readyState === "complete" ) {
+
+		detach();
+		jQuery.ready();
+	}
+}
+
+jQuery.ready.promise = function( obj ) {
+	if ( !readyList ) {
+
+		readyList = jQuery.Deferred();
+
+		// Catch cases where $(document).ready() is called
+		// after the browser event has already occurred.
+		// Support: IE6-10
+		// Older IE sometimes signals "interactive" too soon
+		if ( document.readyState === "complete" ||
+			( document.readyState !== "loading" && !document.documentElement.doScroll ) ) {
+
+			// Handle it asynchronously to allow scripts the opportunity to delay ready
+			window.setTimeout( jQuery.ready );
+
+		// Standards-based browsers support DOMContentLoaded
+		} else if ( document.addEventListener ) {
+
+			// Use the handy event callback
+			document.addEventListener( "DOMContentLoaded", completed );
+
+			// A fallback to window.onload, that will always work
+			window.addEventListener( "load", completed );
+
+		// If IE event model is used
+		} else {
+
+			// Ensure firing before onload, maybe late but safe also for iframes
+			document.attachEvent( "onreadystatechange", completed );
+
+			// A fallback to window.onload, that will always work
+			window.attachEvent( "onload", completed );
+
+			// If IE and not a frame
+			// continually check to see if the document is ready
+			var top = false;
+
+			try {
+				top = window.frameElement == null && document.documentElement;
+			} catch ( e ) {}
+
+			if ( top && top.doScroll ) {
+				( function doScrollCheck() {
+					if ( !jQuery.isReady ) {
+
+						try {
+
+							// Use the trick by Diego Perini
+							// http://javascript.nwbox.com/IEContentLoaded/
+							top.doScroll( "left" );
+						} catch ( e ) {
+							return window.setTimeout( doScrollCheck, 50 );
+						}
+
+						// detach all dom ready events
+						detach();
+
+						// and execute any waiting functions
+						jQuery.ready();
+					}
+				} )();
+			}
+		}
+	}
+	return readyList.promise( obj );
+};
+
+// Kick off the DOM ready check even if the user does not
+jQuery.ready.promise();
+
+
+
+
+// Support: IE<9
+// Iteration over object's inherited properties before its own
+var i;
+for ( i in jQuery( support ) ) {
+	break;
+}
+support.ownFirst = i === "0";
+
+// Note: most support tests are defined in their respective modules.
+// false until the test is run
+support.inlineBlockNeedsLayout = false;
+
+// Execute ASAP in case we need to set body.style.zoom
+jQuery( function() {
+
+	// Minified: var a,b,c,d
+	var val, div, body, container;
+
+	body = document.getElementsByTagName( "body" )[ 0 ];
+	if ( !body || !body.style ) {
+
+		// Return for frameset docs that don't have a body
+		return;
+	}
+
+	// Setup
+	div = document.createElement( "div" );
+	container = document.createElement( "div" );
+	container.style.cssText = "position:absolute;border:0;width:0;height:0;top:0;left:-9999px";
+	body.appendChild( container ).appendChild( div );
+
+	if ( typeof div.style.zoom !== "undefined" ) {
+
+		// Support: IE<8
+		// Check if natively block-level elements act like inline-block
+		// elements when setting their display to 'inline' and giving
+		// them layout
+		div.style.cssText = "display:inline;margin:0;border:0;padding:1px;width:1px;zoom:1";
+
+		support.inlineBlockNeedsLayout = val = div.offsetWidth === 3;
+		if ( val ) {
+
+			// Prevent IE 6 from affecting layout for positioned elements #11048
+			// Prevent IE from shrinking the body in IE 7 mode #12869
+			// Support: IE<8
+			body.style.zoom = 1;
+		}
+	}
+
+	body.removeChild( container );
+} );
+
+
+( function() {
+	var div = document.createElement( "div" );
+
+	// Support: IE<9
+	support.deleteExpando = true;
+	try {
+		delete div.test;
+	} catch ( e ) {
+		support.deleteExpando = false;
+	}
+
+	// Null elements to avoid leaks in IE.
+	div = null;
+} )();
+var acceptData = function( elem ) {
+	var noData = jQuery.noData[ ( elem.nodeName + " " ).toLowerCase() ],
+		nodeType = +elem.nodeType || 1;
+
+	// Do not set data on non-element DOM nodes because it will not be cleared (#8335).
+	return nodeType !== 1 && nodeType !== 9 ?
+		false :
+
+		// Nodes accept data unless otherwise specified; rejection can be conditional
+		!noData || noData !== true && elem.getAttribute( "classid" ) === noData;
+};
+
+
+
+
+var rbrace = /^(?:\{[\w\W]*\}|\[[\w\W]*\])$/,
+	rmultiDash = /([A-Z])/g;
+
+function dataAttr( elem, key, data ) {
+
+	// If nothing was found internally, try to fetch any
+	// data from the HTML5 data-* attribute
+	if ( data === undefined && elem.nodeType === 1 ) {
+
+		var name = "data-" + key.replace( rmultiDash, "-$1" ).toLowerCase();
+
+		data = elem.getAttribute( name );
+
+		if ( typeof data === "string" ) {
+			try {
+				data = data === "true" ? true :
+					data === "false" ? false :
+					data === "null" ? null :
+
+					// Only convert to a number if it doesn't change the string
+					+data + "" === data ? +data :
+					rbrace.test( data ) ? jQuery.parseJSON( data ) :
+					data;
+			} catch ( e ) {}
+
+			// Make sure we set the data so it isn't changed later
+			jQuery.data( elem, key, data );
+
+		} else {
+			data = undefined;
+		}
+	}
+
+	return data;
+}
+
+// checks a cache object for emptiness
+function isEmptyDataObject( obj ) {
+	var name;
+	for ( name in obj ) {
+
+		// if the public data object is empty, the private is still empty
+		if ( name === "data" && jQuery.isEmptyObject( obj[ name ] ) ) {
+			continue;
+		}
+		if ( name !== "toJSON" ) {
+			return false;
+		}
+	}
+
+	return true;
+}
+
+function internalData( elem, name, data, pvt /* Internal Use Only */ ) {
+	if ( !acceptData( elem ) ) {
+		return;
+	}
+
+	var ret, thisCache,
+		internalKey = jQuery.expando,
+
+		// We have to handle DOM nodes and JS objects differently because IE6-7
+		// can't GC object references properly across the DOM-JS boundary
+		isNode = elem.nodeType,
+
+		// Only DOM nodes need the global jQuery cache; JS object data is
+		// attached directly to the object so GC can occur automatically
+		cache = isNode ? jQuery.cache : elem,
+
+		// Only defining an ID for JS objects if its cache already exists allows
+		// the code to shortcut on the same path as a DOM node with no cache
+		id = isNode ? elem[ internalKey ] : elem[ internalKey ] && internalKey;
+
+	// Avoid doing any more work than we need to when trying to get data on an
+	// object that has no data at all
+	if ( ( !id || !cache[ id ] || ( !pvt && !cache[ id ].data ) ) &&
+		data === undefined && typeof name === "string" ) {
+		return;
+	}
+
+	if ( !id ) {
+
+		// Only DOM nodes need a new unique ID for each element since their data
+		// ends up in the global cache
+		if ( isNode ) {
+			id = elem[ internalKey ] = deletedIds.pop() || jQuery.guid++;
+		} else {
+			id = internalKey;
+		}
+	}
+
+	if ( !cache[ id ] ) {
+
+		// Avoid exposing jQuery metadata on plain JS objects when the object
+		// is serialized using JSON.stringify
+		cache[ id ] = isNode ? {} : { toJSON: jQuery.noop };
+	}
+
+	// An object can be passed to jQuery.data instead of a key/value pair; this gets
+	// shallow copied over onto the existing cache
+	if ( typeof name === "object" || typeof name === "function" ) {
+		if ( pvt ) {
+			cache[ id ] = jQuery.extend( cache[ id ], name );
+		} else {
+			cache[ id ].data = jQuery.extend( cache[ id ].data, name );
+		}
+	}
+
+	thisCache = cache[ id ];
+
+	// jQuery data() is stored in a separate object inside the object's internal data
+	// cache in order to avoid key collisions between internal data and user-defined
+	// data.
+	if ( !pvt ) {
+		if ( !thisCache.data ) {
+			thisCache.data = {};
+		}
+
+		thisCache = thisCache.data;
+	}
+
+	if ( data !== undefined ) {
+		thisCache[ jQuery.camelCase( name ) ] = data;
+	}
+
+	// Check for both converted-to-camel and non-converted data property names
+	// If a data property was specified
+	if ( typeof name === "string" ) {
+
+		// First Try to find as-is property data
+		ret = thisCache[ name ];
+
+		// Test for null|undefined property data
+		if ( ret == null ) {
+
+			// Try to find the camelCased property
+			ret = thisCache[ jQuery.camelCase( name ) ];
+		}
+	} else {
+		ret = thisCache;
+	}
+
+	return ret;
+}
+
+function internalRemoveData( elem, name, pvt ) {
+	if ( !acceptData( elem ) ) {
+		return;
+	}
+
+	var thisCache, i,
+		isNode = elem.nodeType,
+
+		// See jQuery.data for more information
+		cache = isNode ? jQuery.cache : elem,
+		id = isNode ? elem[ jQuery.expando ] : jQuery.expando;
+
+	// If there is already no cache entry for this object, there is no
+	// purpose in continuing
+	if ( !cache[ id ] ) {
+		return;
+	}
+
+	if ( name ) {
+
+		thisCache = pvt ? cache[ id ] : cache[ id ].data;
+
+		if ( thisCache ) {
+
+			// Support array or space separated string names for data keys
+			if ( !jQuery.isArray( name ) ) {
+
+				// try the string as a key before any manipulation
+				if ( name in thisCache ) {
+					name = [ name ];
+				} else {
+
+					// split the camel cased version by spaces unless a key with the spaces exists
+					name = jQuery.camelCase( name );
+					if ( name in thisCache ) {
+						name = [ name ];
+					} else {
+						name = name.split( " " );
+					}
+				}
+			} else {
+
+				// If "name" is an array of keys...
+				// When data is initially created, via ("key", "val") signature,
+				// keys will be converted to camelCase.
+				// Since there is no way to tell _how_ a key was added, remove
+				// both plain key and camelCase key. #12786
+				// This will only penalize the array argument path.
+				name = name.concat( jQuery.map( name, jQuery.camelCase ) );
+			}
+
+			i = name.length;
+			while ( i-- ) {
+				delete thisCache[ name[ i ] ];
+			}
+
+			// If there is no data left in the cache, we want to continue
+			// and let the cache object itself get destroyed
+			if ( pvt ? !isEmptyDataObject( thisCache ) : !jQuery.isEmptyObject( thisCache ) ) {
+				return;
+			}
+		}
+	}
+
+	// See jQuery.data for more information
+	if ( !pvt ) {
+		delete cache[ id ].data;
+
+		// Don't destroy the parent cache unless the internal data object
+		// had been the only thing left in it
+		if ( !isEmptyDataObject( cache[ id ] ) ) {
+			return;
+		}
+	}
+
+	// Destroy the cache
+	if ( isNode ) {
+		jQuery.cleanData( [ elem ], true );
+
+	// Use delete when supported for expandos or `cache` is not a window per isWindow (#10080)
+	/* jshint eqeqeq: false */
+	} else if ( support.deleteExpando || cache != cache.window ) {
+		/* jshint eqeqeq: true */
+		delete cache[ id ];
+
+	// When all else fails, undefined
+	} else {
+		cache[ id ] = undefined;
+	}
+}
+
+jQuery.extend( {
+	cache: {},
+
+	// The following elements (space-suffixed to avoid Object.prototype collisions)
+	// throw uncatchable exceptions if you attempt to set expando properties
+	noData: {
+		"applet ": true,
+		"embed ": true,
+
+		// ...but Flash objects (which have this classid) *can* handle expandos
+		"object ": "clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"
+	},
+
+	hasData: function( elem ) {
+		elem = elem.nodeType ? jQuery.cache[ elem[ jQuery.expando ] ] : elem[ jQuery.expando ];
+		return !!elem && !isEmptyDataObject( elem );
+	},
+
+	data: function( elem, name, data ) {
+		return internalData( elem, name, data );
+	},
+
+	removeData: function( elem, name ) {
+		return internalRemoveData( elem, name );
+	},
+
+	// For internal use only.
+	_data: function( elem, name, data ) {
+		return internalData( elem, name, data, true );
+	},
+
+	_removeData: function( elem, name ) {
+		return internalRemoveData( elem, name, true );
+	}
+} );
+
+jQuery.fn.extend( {
+	data: function( key, value ) {
+		var i, name, data,
+			elem = this[ 0 ],
+			attrs = elem && elem.attributes;
+
+		// Special expections of .data basically thwart jQuery.access,
+		// so implement the relevant behavior ourselves
+
+		// Gets all values
+		if ( key === undefined ) {
+			if ( this.length ) {
+				data = jQuery.data( elem );
+
+				if ( elem.nodeType === 1 && !jQuery._data( elem, "parsedAttrs" ) ) {
+					i = attrs.length;
+					while ( i-- ) {
+
+						// Support: IE11+
+						// The attrs elements can be null (#14894)
+						if ( attrs[ i ] ) {
+							name = attrs[ i ].name;
+							if ( name.indexOf( "data-" ) === 0 ) {
+								name = jQuery.camelCase( name.slice( 5 ) );
+								dataAttr( elem, name, data[ name ] );
+							}
+						}
+					}
+					jQuery._data( elem, "parsedAttrs", true );
+				}
+			}
+
+			return data;
+		}
+
+		// Sets multiple values
+		if ( typeof key === "object" ) {
+			return this.each( function() {
+				jQuery.data( this, key );
+			} );
+		}
+
+		return arguments.length > 1 ?
+
+			// Sets one value
+			this.each( function() {
+				jQuery.data( this, key, value );
+			} ) :
+
+			// Gets one value
+			// Try to fetch any internally stored data first
+			elem ? dataAttr( elem, key, jQuery.data( elem, key ) ) : undefined;
+	},
+
+	removeData: function( key ) {
+		return this.each( function() {
+			jQuery.removeData( this, key );
+		} );
+	}
+} );
+
+
+jQuery.extend( {
+	queue: function( elem, type, data ) {
+		var queue;
+
+		if ( elem ) {
+			type = ( type || "fx" ) + "queue";
+			queue = jQuery._data( elem, type );
+
+			// Speed up dequeue by getting out quickly if this is just a lookup
+			if ( data ) {
+				if ( !queue || jQuery.isArray( data ) ) {
+					queue = jQuery._data( elem, type, jQuery.makeArray( data ) );
+				} else {
+					queue.push( data );
+				}
+			}
+			return queue || [];
+		}
+	},
+
+	dequeue: function( elem, type ) {
+		type = type || "fx";
+
+		var queue = jQuery.queue( elem, type ),
+			startLength = queue.length,
+			fn = queue.shift(),
+			hooks = jQuery._queueHooks( elem, type ),
+			next = function() {
+				jQuery.dequeue( elem, type );
+			};
+
+		// If the fx queue is dequeued, always remove the progress sentinel
+		if ( fn === "inprogress" ) {
+			fn = queue.shift();
+			startLength--;
+		}
+
+		if ( fn ) {
+
+			// Add a progress sentinel to prevent the fx queue from being
+			// automatically dequeued
+			if ( type === "fx" ) {
+				queue.unshift( "inprogress" );
+			}
+
+			// clear up the last queue stop function
+			delete hooks.stop;
+			fn.call( elem, next, hooks );
+		}
+
+		if ( !startLength && hooks ) {
+			hooks.empty.fire();
+		}
+	},
+
+	// not intended for public consumption - generates a queueHooks object,
+	// or returns the current one
+	_queueHooks: function( elem, type ) {
+		var key = type + "queueHooks";
+		return jQuery._data( elem, key ) || jQuery._data( elem, key, {
+			empty: jQuery.Callbacks( "once memory" ).add( function() {
+				jQuery._removeData( elem, type + "queue" );
+				jQuery._removeData( elem, key );
+			} )
+		} );
+	}
+} );
+
+jQuery.fn.extend( {
+	queue: function( type, data ) {
+		var setter = 2;
+
+		if ( typeof type !== "string" ) {
+			data = type;
+			type = "fx";
+			setter--;
+		}
+
+		if ( arguments.length < setter ) {
+			return jQuery.queue( this[ 0 ], type );
+		}
+
+		return data === undefined ?
+			this :
+			this.each( function() {
+				var queue = jQuery.queue( this, type, data );
+
+				// ensure a hooks for this queue
+				jQuery._queueHooks( this, type );
+
+				if ( type === "fx" && queue[ 0 ] !== "inprogress" ) {
+					jQuery.dequeue( this, type );
+				}
+			} );
+	},
+	dequeue: function( type ) {
+		return this.each( function() {
+			jQuery.dequeue( this, type );
+		} );
+	},
+	clearQueue: function( type ) {
+		return this.queue( type || "fx", [] );
+	},
+
+	// Get a promise resolved when queues of a certain type
+	// are emptied (fx is the type by default)
+	promise: function( type, obj ) {
+		var tmp,
+			count = 1,
+			defer = jQuery.Deferred(),
+			elements = this,
+			i = this.length,
+			resolve = function() {
+				if ( !( --count ) ) {
+					defer.resolveWith( elements, [ elements ] );
+				}
+			};
+
+		if ( typeof type !== "string" ) {
+			obj = type;
+			type = undefined;
+		}
+		type = type || "fx";
+
+		while ( i-- ) {
+			tmp = jQuery._data( elements[ i ], type + "queueHooks" );
+			if ( tmp && tmp.empty ) {
+				count++;
+				tmp.empty.add( resolve );
+			}
+		}
+		resolve();
+		return defer.promise( obj );
+	}
+} );
+
+
+( function() {
+	var shrinkWrapBlocksVal;
+
+	support.shrinkWrapBlocks = function() {
+		if ( shrinkWrapBlocksVal != null ) {
+			return shrinkWrapBlocksVal;
+		}
+
+		// Will be changed later if needed.
+		shrinkWrapBlocksVal = false;
+
+		// Minified: var b,c,d
+		var div, body, container;
+
+		body = document.getElementsByTagName( "body" )[ 0 ];
+		if ( !body || !body.style ) {
+
+			// Test fired too early or in an unsupported environment, exit.
+			return;
+		}
+
+		// Setup
+		div = document.createElement( "div" );
+		container = document.createElement( "div" );
+		container.style.cssText = "position:absolute;border:0;width:0;height:0;top:0;left:-9999px";
+		body.appendChild( container ).appendChild( div );
+
+		// Support: IE6
+		// Check if elements with layout shrink-wrap their children
+		if ( typeof div.style.zoom !== "undefined" ) {
+
+			// Reset CSS: box-sizing; display; margin; border
+			div.style.cssText =
+
+				// Support: Firefox<29, Android 2.3
+				// Vendor-prefix box-sizing
+				"-webkit-box-sizing:content-box;-moz-box-sizing:content-box;" +
+				"box-sizing:content-box;display:block;margin:0;border:0;" +
+				"padding:1px;width:1px;zoom:1";
+			div.appendChild( document.createElement( "div" ) ).style.width = "5px";
+			shrinkWrapBlocksVal = div.offsetWidth !== 3;
+		}
+
+		body.removeChild( container );
+
+		return shrinkWrapBlocksVal;
+	};
+
+} )();
+var pnum = ( /[+-]?(?:\d*\.|)\d+(?:[eE][+-]?\d+|)/ ).source;
+
+var rcssNum = new RegExp( "^(?:([+-])=|)(" + pnum + ")([a-z%]*)$", "i" );
+
+
+var cssExpand = [ "Top", "Right", "Bottom", "Left" ];
+
+var isHidden = function( elem, el ) {
+
+		// isHidden might be called from jQuery#filter function;
+		// in that case, element will be second argument
+		elem = el || elem;
+		return jQuery.css( elem, "display" ) === "none" ||
+			!jQuery.contains( elem.ownerDocument, elem );
+	};
+
+
+
+function adjustCSS( elem, prop, valueParts, tween ) {
+	var adjusted,
+		scale = 1,
+		maxIterations = 20,
+		currentValue = tween ?
+			function() { return tween.cur(); } :
+			function() { return jQuery.css( elem, prop, "" ); },
+		initial = currentValue(),
+		unit = valueParts && valueParts[ 3 ] || ( jQuery.cssNumber[ prop ] ? "" : "px" ),
+
+		// Starting value computation is required for potential unit mismatches
+		initialInUnit = ( jQuery.cssNumber[ prop ] || unit !== "px" && +initial ) &&
+			rcssNum.exec( jQuery.css( elem, prop ) );
+
+	if ( initialInUnit && initialInUnit[ 3 ] !== unit ) {
+
+		// Trust units reported by jQuery.css
+		unit = unit || initialInUnit[ 3 ];
+
+		// Make sure we update the tween properties later on
+		valueParts = valueParts || [];
+
+		// Iteratively approximate from a nonzero starting point
+		initialInUnit = +initial || 1;
+
+		do {
+
+			// If previous iteration zeroed out, double until we get *something*.
+			// Use string for doubling so we don't accidentally see scale as unchanged below
+			scale = scale || ".5";
+
+			// Adjust and apply
+			initialInUnit = initialInUnit / scale;
+			jQuery.style( elem, prop, initialInUnit + unit );
+
+		// Update scale, tolerating zero or NaN from tween.cur()
+		// Break the loop if scale is unchanged or perfect, or if we've just had enough.
+		} while (
+			scale !== ( scale = currentValue() / initial ) && scale !== 1 && --maxIterations
+		);
+	}
+
+	if ( valueParts ) {
+		initialInUnit = +initialInUnit || +initial || 0;
+
+		// Apply relative offset (+=/-=) if specified
+		adjusted = valueParts[ 1 ] ?
+			initialInUnit + ( valueParts[ 1 ] + 1 ) * valueParts[ 2 ] :
+			+valueParts[ 2 ];
+		if ( tween ) {
+			tween.unit = unit;
+			tween.start = initialInUnit;
+			tween.end = adjusted;
+		}
+	}
+	return adjusted;
+}
+
+
+// Multifunctional method to get and set values of a collection
+// The value/s can optionally be executed if it's a function
+var access = function( elems, fn, key, value, chainable, emptyGet, raw ) {
+	var i = 0,
+		length = elems.length,
+		bulk = key == null;
+
+	// Sets many values
+	if ( jQuery.type( key ) === "object" ) {
+		chainable = true;
+		for ( i in key ) {
+			access( elems, fn, i, key[ i ], true, emptyGet, raw );
+		}
+
+	// Sets one value
+	} else if ( value !== undefined ) {
+		chainable = true;
+
+		if ( !jQuery.isFunction( value ) ) {
+			raw = true;
+		}
+
+		if ( bulk ) {
+
+			// Bulk operations run against the entire set
+			if ( raw ) {
+				fn.call( elems, value );
+				fn = null;
+
+			// ...except when executing function values
+			} else {
+				bulk = fn;
+				fn = function( elem, key, value ) {
+					return bulk.call( jQuery( elem ), value );
+				};
+			}
+		}
+
+		if ( fn ) {
+			for ( ; i < length; i++ ) {
+				fn(
+					elems[ i ],
+					key,
+					raw ? value : value.call( elems[ i ], i, fn( elems[ i ], key ) )
+				);
+			}
+		}
+	}
+
+	return chainable ?
+		elems :
+
+		// Gets
+		bulk ?
+			fn.call( elems ) :
+			length ? fn( elems[ 0 ], key ) : emptyGet;
+};
+var rcheckableType = ( /^(?:checkbox|radio)$/i );
+
+var rtagName = ( /<([\w:-]+)/ );
+
+var rscriptType = ( /^$|\/(?:java|ecma)script/i );
+
+var rleadingWhitespace = ( /^\s+/ );
+
+var nodeNames = "abbr|article|aside|audio|bdi|canvas|data|datalist|" +
+		"details|dialog|figcaption|figure|footer|header|hgroup|main|" +
+		"mark|meter|nav|output|picture|progress|section|summary|template|time|video";
+
+
+
+function createSafeFragment( document ) {
+	var list = nodeNames.split( "|" ),
+		safeFrag = document.createDocumentFragment();
+
+	if ( safeFrag.createElement ) {
+		while ( list.length ) {
+			safeFrag.createElement(
+				list.pop()
+			);
+		}
+	}
+	return safeFrag;
+}
+
+
+( function() {
+	var div = document.createElement( "div" ),
+		fragment = document.createDocumentFragment(),
+		input = document.createElement( "input" );
+
+	// Setup
+	div.innerHTML = "  <link/><table></table><a href='/a'>a</a><input type='checkbox'/>";
+
+	// IE strips leading whitespace when .innerHTML is used
+	support.leadingWhitespace = div.firstChild.nodeType === 3;
+
+	// Make sure that tbody elements aren't automatically inserted
+	// IE will insert them into empty tables
+	support.tbody = !div.getElementsByTagName( "tbody" ).length;
+
+	// Make sure that link elements get serialized correctly by innerHTML
+	// This requires a wrapper element in IE
+	support.htmlSerialize = !!div.getElementsByTagName( "link" ).length;
+
+	// Makes sure cloning an html5 element does not cause problems
+	// Where outerHTML is undefined, this still works
+	support.html5Clone =
+		document.createElement( "nav" ).cloneNode( true ).outerHTML !== "<:nav></:nav>";
+
+	// Check if a disconnected checkbox will retain its checked
+	// value of true after appended to the DOM (IE6/7)
+	input.type = "checkbox";
+	input.checked = true;
+	fragment.appendChild( input );
+	support.appendChecked = input.checked;
+
+	// Make sure textarea (and checkbox) defaultValue is properly cloned
+	// Support: IE6-IE11+
+	div.innerHTML = "<textarea>x</textarea>";
+	support.noCloneChecked = !!div.cloneNode( true ).lastChild.defaultValue;
+
+	// #11217 - WebKit loses check when the name is after the checked attribute
+	fragment.appendChild( div );
+
+	// Support: Windows Web Apps (WWA)
+	// `name` and `type` must use .setAttribute for WWA (#14901)
+	input = document.createElement( "input" );
+	input.setAttribute( "type", "radio" );
+	input.setAttribute( "checked", "checked" );
+	input.setAttribute( "name", "t" );
+
+	div.appendChild( input );
+
+	// Support: Safari 5.1, iOS 5.1, Android 4.x, Android 2.3
+	// old WebKit doesn't clone checked state correctly in fragments
+	support.checkClone = div.cloneNode( true ).cloneNode( true ).lastChild.checked;
+
+	// Support: IE<9
+	// Cloned elements keep attachEvent handlers, we use addEventListener on IE9+
+	support.noCloneEvent = !!div.addEventListener;
+
+	// Support: IE<9
+	// Since attributes and properties are the same in IE,
+	// cleanData must set properties to undefined rather than use removeAttribute
+	div[ jQuery.expando ] = 1;
+	support.attributes = !div.getAttribute( jQuery.expando );
+} )();
+
+
+// We have to close these tags to support XHTML (#13200)
+var wrapMap = {
+	option: [ 1, "<select multiple='multiple'>", "</select>" ],
+	legend: [ 1, "<fieldset>", "</fieldset>" ],
+	area: [ 1, "<map>", "</map>" ],
+
+	// Support: IE8
+	param: [ 1, "<object>", "</object>" ],
+	thead: [ 1, "<table>", "</table>" ],
+	tr: [ 2, "<table><tbody>", "</tbody></table>" ],
+	col: [ 2, "<table><tbody></tbody><colgroup>", "</colgroup></table>" ],
+	td: [ 3, "<table><tbody><tr>", "</tr></tbody></table>" ],
+
+	// IE6-8 can't serialize link, script, style, or any html5 (NoScope) tags,
+	// unless wrapped in a div with non-breaking characters in front of it.
+	_default: support.htmlSerialize ? [ 0, "", "" ] : [ 1, "X<div>", "</div>" ]
+};
+
+// Support: IE8-IE9
+wrapMap.optgroup = wrapMap.option;
+
+wrapMap.tbody = wrapMap.tfoot = wrapMap.colgroup = wrapMap.caption = wrapMap.thead;
+wrapMap.th = wrapMap.td;
+
+
+function getAll( context, tag ) {
+	var elems, elem,
+		i = 0,
+		found = typeof context.getElementsByTagName !== "undefined" ?
+			context.getElementsByTagName( tag || "*" ) :
+			typeof context.querySelectorAll !== "undefined" ?
+				context.querySelectorAll( tag || "*" ) :
+				undefined;
+
+	if ( !found ) {
+		for ( found = [], elems = context.childNodes || context;
+			( elem = elems[ i ] ) != null;
+			i++
+		) {
+			if ( !tag || jQuery.nodeName( elem, tag ) ) {
+				found.push( elem );
+			} else {
+				jQuery.merge( found, getAll( elem, tag ) );
+			}
+		}
+	}
+
+	return tag === undefined || tag && jQuery.nodeName( context, tag ) ?
+		jQuery.merge( [ context ], found ) :
+		found;
+}
+
+
+// Mark scripts as having already been evaluated
+function setGlobalEval( elems, refElements ) {
+	var elem,
+		i = 0;
+	for ( ; ( elem = elems[ i ] ) != null; i++ ) {
+		jQuery._data(
+			elem,
+			"globalEval",
+			!refElements || jQuery._data( refElements[ i ], "globalEval" )
+		);
+	}
+}
+
+
+var rhtml = /<|&#?\w+;/,
+	rtbody = /<tbody/i;
+
+function fixDefaultChecked( elem ) {
+	if ( rcheckableType.test( elem.type ) ) {
+		elem.defaultChecked = elem.checked;
+	}
+}
+
+function buildFragment( elems, context, scripts, selection, ignored ) {
+	var j, elem, contains,
+		tmp, tag, tbody, wrap,
+		l = elems.length,
+
+		// Ensure a safe fragment
+		safe = createSafeFragment( context ),
+
+		nodes = [],
+		i = 0;
+
+	for ( ; i < l; i++ ) {
+		elem = elems[ i ];
+
+		if ( elem || elem === 0 ) {
+
+			// Add nodes directly
+			if ( jQuery.type( elem ) === "object" ) {
+				jQuery.merge( nodes, elem.nodeType ? [ elem ] : elem );
+
+			// Convert non-html into a text node
+			} else if ( !rhtml.test( elem ) ) {
+				nodes.push( context.createTextNode( elem ) );
+
+			// Convert html into DOM nodes
+			} else {
+				tmp = tmp || safe.appendChild( context.createElement( "div" ) );
+
+				// Deserialize a standard representation
+				tag = ( rtagName.exec( elem ) || [ "", "" ] )[ 1 ].toLowerCase();
+				wrap = wrapMap[ tag ] || wrapMap._default;
+
+				tmp.innerHTML = wrap[ 1 ] + jQuery.htmlPrefilter( elem ) + wrap[ 2 ];
+
+				// Descend through wrappers to the right content
+				j = wrap[ 0 ];
+				while ( j-- ) {
+					tmp = tmp.lastChild;
+				}
+
+				// Manually add leading whitespace removed by IE
+				if ( !support.leadingWhitespace && rleadingWhitespace.test( elem ) ) {
+					nodes.push( context.createTextNode( rleadingWhitespace.exec( elem )[ 0 ] ) );
+				}
+
+				// Remove IE's autoinserted <tbody> from table fragments
+				if ( !support.tbody ) {
+
+					// String was a <table>, *may* have spurious <tbody>
+					elem = tag === "table" && !rtbody.test( elem ) ?
+						tmp.firstChild :
+
+						// String was a bare <thead> or <tfoot>
+						wrap[ 1 ] === "<table>" && !rtbody.test( elem ) ?
+							tmp :
+							0;
+
+					j = elem && elem.childNodes.length;
+					while ( j-- ) {
+						if ( jQuery.nodeName( ( tbody = elem.childNodes[ j ] ), "tbody" ) &&
+							!tbody.childNodes.length ) {
+
+							elem.removeChild( tbody );
+						}
+					}
+				}
+
+				jQuery.merge( nodes, tmp.childNodes );
+
+				// Fix #12392 for WebKit and IE > 9
+				tmp.textContent = "";
+
+				// Fix #12392 for oldIE
+				while ( tmp.firstChild ) {
+					tmp.removeChild( tmp.firstChild );
+				}
+
+				// Remember the top-level container for proper cleanup
+				tmp = safe.lastChild;
+			}
+		}
+	}
+
+	// Fix #11356: Clear elements from fragment
+	if ( tmp ) {
+		safe.removeChild( tmp );
+	}
+
+	// Reset defaultChecked for any radios and checkboxes
+	// about to be appended to the DOM in IE 6/7 (#8060)
+	if ( !support.appendChecked ) {
+		jQuery.grep( getAll( nodes, "input" ), fixDefaultChecked );
+	}
+
+	i = 0;
+	while ( ( elem = nodes[ i++ ] ) ) {
+
+		// Skip elements already in the context collection (trac-4087)
+		if ( selection && jQuery.inArray( elem, selection ) > -1 ) {
+			if ( ignored ) {
+				ignored.push( elem );
+			}
+
+			continue;
+		}
+
+		contains = jQuery.contains( elem.ownerDocument, elem );
+
+		// Append to fragment
+		tmp = getAll( safe.appendChild( elem ), "script" );
+
+		// Preserve script evaluation history
+		if ( contains ) {
+			setGlobalEval( tmp );
+		}
+
+		// Capture executables
+		if ( scripts ) {
+			j = 0;
+			while ( ( elem = tmp[ j++ ] ) ) {
+				if ( rscriptType.test( elem.type || "" ) ) {
+					scripts.push( elem );
+				}
+			}
+		}
+	}
+
+	tmp = null;
+
+	return safe;
+}
+
+
+( function() {
+	var i, eventName,
+		div = document.createElement( "div" );
+
+	// Support: IE<9 (lack submit/change bubble), Firefox (lack focus(in | out) events)
+	for ( i in { submit: true, change: true, focusin: true } ) {
+		eventName = "on" + i;
+
+		if ( !( support[ i ] = eventName in window ) ) {
+
+			// Beware of CSP restrictions (https://developer.mozilla.org/en/Security/CSP)
+			div.setAttribute( eventName, "t" );
+			support[ i ] = div.attributes[ eventName ].expando === false;
+		}
+	}
+
+	// Null elements to avoid leaks in IE.
+	div = null;
+} )();
+
+
+var rformElems = /^(?:input|select|textarea)$/i,
+	rkeyEvent = /^key/,
+	rmouseEvent = /^(?:mouse|pointer|contextmenu|drag|drop)|click/,
+	rfocusMorph = /^(?:focusinfocus|focusoutblur)$/,
+	rtypenamespace = /^([^.]*)(?:\.(.+)|)/;
+
+function returnTrue() {
+	return true;
+}
+
+function returnFalse() {
+	return false;
+}
+
+// Support: IE9
+// See #13393 for more info
+function safeActiveElement() {
+	try {
+		return document.activeElement;
+	} catch ( err ) { }
+}
+
+function on( elem, types, selector, data, fn, one ) {
+	var origFn, type;
+
+	// Types can be a map of types/handlers
+	if ( typeof types === "object" ) {
+
+		// ( types-Object, selector, data )
+		if ( typeof selector !== "string" ) {
+
+			// ( types-Object, data )
+			data = data || selector;
+			selector = undefined;
+		}
+		for ( type in types ) {
+			on( elem, type, selector, data, types[ type ], one );
+		}
+		return elem;
+	}
+
+	if ( data == null && fn == null ) {
+
+		// ( types, fn )
+		fn = selector;
+		data = selector = undefined;
+	} else if ( fn == null ) {
+		if ( typeof selector === "string" ) {
+
+			// ( types, selector, fn )
+			fn = data;
+			data = undefined;
+		} else {
+
+			// ( types, data, fn )
+			fn = data;
+			data = selector;
+			selector = undefined;
+		}
+	}
+	if ( fn === false ) {
+		fn = returnFalse;
+	} else if ( !fn ) {
+		return elem;
+	}
+
+	if ( one === 1 ) {
+		origFn = fn;
+		fn = function( event ) {
+
+			// Can use an empty set, since event contains the info
+			jQuery().off( event );
+			return origFn.apply( this, arguments );
+		};
+
+		// Use same guid so caller can remove using origFn
+		fn.guid = origFn.guid || ( origFn.guid = jQuery.guid++ );
+	}
+	return elem.each( function() {
+		jQuery.event.add( this, types, fn, data, selector );
+	} );
+}
+
+/*
+ * Helper functions for managing events -- not part of the public interface.
+ * Props to Dean Edwards' addEvent library for many of the ideas.
+ */
+jQuery.event = {
+
+	global: {},
+
+	add: function( elem, types, handler, data, selector ) {
+		var tmp, events, t, handleObjIn,
+			special, eventHandle, handleObj,
+			handlers, type, namespaces, origType,
+			elemData = jQuery._data( elem );
+
+		// Don't attach events to noData or text/comment nodes (but allow plain objects)
+		if ( !elemData ) {
+			return;
+		}
+
+		// Caller can pass in an object of custom data in lieu of the handler
+		if ( handler.handler ) {
+			handleObjIn = handler;
+			handler = handleObjIn.handler;
+			selector = handleObjIn.selector;
+		}
+
+		// Make sure that the handler has a unique ID, used to find/remove it later
+		if ( !handler.guid ) {
+			handler.guid = jQuery.guid++;
+		}
+
+		// Init the element's event structure and main handler, if this is the first
+		if ( !( events = elemData.events ) ) {
+			events = elemData.events = {};
+		}
+		if ( !( eventHandle = elemData.handle ) ) {
+			eventHandle = elemData.handle = function( e ) {
+
+				// Discard the second event of a jQuery.event.trigger() and
+				// when an event is called after a page has unloaded
+				return typeof jQuery !== "undefined" &&
+					( !e || jQuery.event.triggered !== e.type ) ?
+					jQuery.event.dispatch.apply( eventHandle.elem, arguments ) :
+					undefined;
+			};
+
+			// Add elem as a property of the handle fn to prevent a memory leak
+			// with IE non-native events
+			eventHandle.elem = elem;
+		}
+
+		// Handle multiple events separated by a space
+		types = ( types || "" ).match( rnotwhite ) || [ "" ];
+		t = types.length;
+		while ( t-- ) {
+			tmp = rtypenamespace.exec( types[ t ] ) || [];
+			type = origType = tmp[ 1 ];
+			namespaces = ( tmp[ 2 ] || "" ).split( "." ).sort();
+
+			// There *must* be a type, no attaching namespace-only handlers
+			if ( !type ) {
+				continue;
+			}
+
+			// If event changes its type, use the special event handlers for the changed type
+			special = jQuery.event.special[ type ] || {};
+
+			// If selector defined, determine special event api type, otherwise given type
+			type = ( selector ? special.delegateType : special.bindType ) || type;
+
+			// Update special based on newly reset type
+			special = jQuery.event.special[ type ] || {};
+
+			// handleObj is passed to all event handlers
+			handleObj = jQuery.extend( {
+				type: type,
+				origType: origType,
+				data: data,
+				handler: handler,
+				guid: handler.guid,
+				selector: selector,
+				needsContext: selector && jQuery.expr.match.needsContext.test( selector ),
+				namespace: namespaces.join( "." )
+			}, handleObjIn );
+
+			// Init the event handler queue if we're the first
+			if ( !( handlers = events[ type ] ) ) {
+				handlers = events[ type ] = [];
+				handlers.delegateCount = 0;
+
+				// Only use addEventListener/attachEvent if the special events handler returns false
+				if ( !special.setup ||
+					special.setup.call( elem, data, namespaces, eventHandle ) === false ) {
+
+					// Bind the global event handler to the element
+					if ( elem.addEventListener ) {
+						elem.addEventListener( type, eventHandle, false );
+
+					} else if ( elem.attachEvent ) {
+						elem.attachEvent( "on" + type, eventHandle );
+					}
+				}
+			}
+
+			if ( special.add ) {
+				special.add.call( elem, handleObj );
+
+				if ( !handleObj.handler.guid ) {
+					handleObj.handler.guid = handler.guid;
+				}
+			}
+
+			// Add to the element's handler list, delegates in front
+			if ( selector ) {
+				handlers.splice( handlers.delegateCount++, 0, handleObj );
+			} else {
+				handlers.push( handleObj );
+			}
+
+			// Keep track of which events have ever been used, for event optimization
+			jQuery.event.global[ type ] = true;
+		}
+
+		// Nullify elem to prevent memory leaks in IE
+		elem = null;
+	},
+
+	// Detach an event or set of events from an element
+	remove: function( elem, types, handler, selector, mappedTypes ) {
+		var j, handleObj, tmp,
+			origCount, t, events,
+			special, handlers, type,
+			namespaces, origType,
+			elemData = jQuery.hasData( elem ) && jQuery._data( elem );
+
+		if ( !elemData || !( events = elemData.events ) ) {
+			return;
+		}
+
+		// Once for each type.namespace in types; type may be omitted
+		types = ( types || "" ).match( rnotwhite ) || [ "" ];
+		t = types.length;
+		while ( t-- ) {
+			tmp = rtypenamespace.exec( types[ t ] ) || [];
+			type = origType = tmp[ 1 ];
+			namespaces = ( tmp[ 2 ] || "" ).split( "." ).sort();
+
+			// Unbind all events (on this namespace, if provided) for the element
+			if ( !type ) {
+				for ( type in events ) {
+					jQuery.event.remove( elem, type + types[ t ], handler, selector, true );
+				}
+				continue;
+			}
+
+			special = jQuery.event.special[ type ] || {};
+			type = ( selector ? special.delegateType : special.bindType ) || type;
+			handlers = events[ type ] || [];
+			tmp = tmp[ 2 ] &&
+				new RegExp( "(^|\\.)" + namespaces.join( "\\.(?:.*\\.|)" ) + "(\\.|$)" );
+
+			// Remove matching events
+			origCount = j = handlers.length;
+			while ( j-- ) {
+				handleObj = handlers[ j ];
+
+				if ( ( mappedTypes || origType === handleObj.origType ) &&
+					( !handler || handler.guid === handleObj.guid ) &&
+					( !tmp || tmp.test( handleObj.namespace ) ) &&
+					( !selector || selector === handleObj.selector ||
+						selector === "**" && handleObj.selector ) ) {
+					handlers.splice( j, 1 );
+
+					if ( handleObj.selector ) {
+						handlers.delegateCount--;
+					}
+					if ( special.remove ) {
+						special.remove.call( elem, handleObj );
+					}
+				}
+			}
+
+			// Remove generic event handler if we removed something and no more handlers exist
+			// (avoids potential for endless recursion during removal of special event handlers)
+			if ( origCount && !handlers.length ) {
+				if ( !special.teardown ||
+					special.teardown.call( elem, namespaces, elemData.handle ) === false ) {
+
+					jQuery.removeEvent( elem, type, elemData.handle );
+				}
+
+				delete events[ type ];
+			}
+		}
+
+		// Remove the expando if it's no longer used
+		if ( jQuery.isEmptyObject( events ) ) {
+			delete elemData.handle;
+
+			// removeData also checks for emptiness and clears the expando if empty
+			// so use it instead of delete
+			jQuery._removeData( elem, "events" );
+		}
+	},
+
+	trigger: function( event, data, elem, onlyHandlers ) {
+		var handle, ontype, cur,
+			bubbleType, special, tmp, i,
+			eventPath = [ elem || document ],
+			type = hasOwn.call( event, "type" ) ? event.type : event,
+			namespaces = hasOwn.call( event, "namespace" ) ? event.namespace.split( "." ) : [];
+
+		cur = tmp = elem = elem || document;
+
+		// Don't do events on text and comment nodes
+		if ( elem.nodeType === 3 || elem.nodeType === 8 ) {
+			return;
+		}
+
+		// focus/blur morphs to focusin/out; ensure we're not firing them right now
+		if ( rfocusMorph.test( type + jQuery.event.triggered ) ) {
+			return;
+		}
+
+		if ( type.indexOf( "." ) > -1 ) {
+
+			// Namespaced trigger; create a regexp to match event type in handle()
+			namespaces = type.split( "." );
+			type = namespaces.shift();
+			namespaces.sort();
+		}
+		ontype = type.indexOf( ":" ) < 0 && "on" + type;
+
+		// Caller can pass in a jQuery.Event object, Object, or just an event type string
+		event = event[ jQuery.expando ] ?
+			event :
+			new jQuery.Event( type, typeof event === "object" && event );
+
+		// Trigger bitmask: & 1 for native handlers; & 2 for jQuery (always true)
+		event.isTrigger = onlyHandlers ? 2 : 3;
+		event.namespace = namespaces.join( "." );
+		event.rnamespace = event.namespace ?
+			new RegExp( "(^|\\.)" + namespaces.join( "\\.(?:.*\\.|)" ) + "(\\.|$)" ) :
+			null;
+
+		// Clean up the event in case it is being reused
+		event.result = undefined;
+		if ( !event.target ) {
+			event.target = elem;
+		}
+
+		// Clone any incoming data and prepend the event, creating the handler arg list
+		data = data == null ?
+			[ event ] :
+			jQuery.makeArray( data, [ event ] );
+
+		// Allow special events to draw outside the lines
+		special = jQuery.event.special[ type ] || {};
+		if ( !onlyHandlers && special.trigger && special.trigger.apply( elem, data ) === false ) {
+			return;
+		}
+
+		// Determine event propagation path in advance, per W3C events spec (#9951)
+		// Bubble up to document, then to window; watch for a global ownerDocument var (#9724)
+		if ( !onlyHandlers && !special.noBubble && !jQuery.isWindow( elem ) ) {
+
+			bubbleType = special.delegateType || type;
+			if ( !rfocusMorph.test( bubbleType + type ) ) {
+				cur = cur.parentNode;
+			}
+			for ( ; cur; cur = cur.parentNode ) {
+				eventPath.push( cur );
+				tmp = cur;
+			}
+
+			// Only add window if we got to document (e.g., not plain obj or detached DOM)
+			if ( tmp === ( elem.ownerDocument || document ) ) {
+				eventPath.push( tmp.defaultView || tmp.parentWindow || window );
+			}
+		}
+
+		// Fire handlers on the event path
+		i = 0;
+		while ( ( cur = eventPath[ i++ ] ) && !event.isPropagationStopped() ) {
+
+			event.type = i > 1 ?
+				bubbleType :
+				special.bindType || type;
+
+			// jQuery handler
+			handle = ( jQuery._data( cur, "events" ) || {} )[ event.type ] &&
+				jQuery._data( cur, "handle" );
+
+			if ( handle ) {
+				handle.apply( cur, data );
+			}
+
+			// Native handler
+			handle = ontype && cur[ ontype ];
+			if ( handle && handle.apply && acceptData( cur ) ) {
+				event.result = handle.apply( cur, data );
+				if ( event.result === false ) {
+					event.preventDefault();
+				}
+			}
+		}
+		event.type = type;
+
+		// If nobody prevented the default action, do it now
+		if ( !onlyHandlers && !event.isDefaultPrevented() ) {
+
+			if (
+				( !special._default ||
+				 special._default.apply( eventPath.pop(), data ) === false
+				) && acceptData( elem )
+			) {
+
+				// Call a native DOM method on the target with the same name name as the event.
+				// Can't use an .isFunction() check here because IE6/7 fails that test.
+				// Don't do default actions on window, that's where global variables be (#6170)
+				if ( ontype && elem[ type ] && !jQuery.isWindow( elem ) ) {
+
+					// Don't re-trigger an onFOO event when we call its FOO() method
+					tmp = elem[ ontype ];
+
+					if ( tmp ) {
+						elem[ ontype ] = null;
+					}
+
+					// Prevent re-triggering of the same event, since we already bubbled it above
+					jQuery.event.triggered = type;
+					try {
+						elem[ type ]();
+					} catch ( e ) {
+
+						// IE<9 dies on focus/blur to hidden element (#1486,#12518)
+						// only reproducible on winXP IE8 native, not IE9 in IE8 mode
+					}
+					jQuery.event.triggered = undefined;
+
+					if ( tmp ) {
+						elem[ ontype ] = tmp;
+					}
+				}
+			}
+		}
+
+		return event.result;
+	},
+
+	dispatch: function( event ) {
+
+		// Make a writable jQuery.Event from the native event object
+		event = jQuery.event.fix( event );
+
+		var i, j, ret, matched, handleObj,
+			handlerQueue = [],
+			args = slice.call( arguments ),
+			handlers = ( jQuery._data( this, "events" ) || {} )[ event.type ] || [],
+			special = jQuery.event.special[ event.type ] || {};
+
+		// Use the fix-ed jQuery.Event rather than the (read-only) native event
+		args[ 0 ] = event;
+		event.delegateTarget = this;
+
+		// Call the preDispatch hook for the mapped type, and let it bail if desired
+		if ( special.preDispatch && special.preDispatch.call( this, event ) === false ) {
+			return;
+		}
+
+		// Determine handlers
+		handlerQueue = jQuery.event.handlers.call( this, event, handlers );
+
+		// Run delegates first; they may want to stop propagation beneath us
+		i = 0;
+		while ( ( matched = handlerQueue[ i++ ] ) && !event.isPropagationStopped() ) {
+			event.currentTarget = matched.elem;
+
+			j = 0;
+			while ( ( handleObj = matched.handlers[ j++ ] ) &&
+				!event.isImmediatePropagationStopped() ) {
+
+				// Triggered event must either 1) have no namespace, or 2) have namespace(s)
+				// a subset or equal to those in the bound event (both can have no namespace).
+				if ( !event.rnamespace || event.rnamespace.test( handleObj.namespace ) ) {
+
+					event.handleObj = handleObj;
+					event.data = handleObj.data;
+
+					ret = ( ( jQuery.event.special[ handleObj.origType ] || {} ).handle ||
+						handleObj.handler ).apply( matched.elem, args );
+
+					if ( ret !== undefined ) {
+						if ( ( event.result = ret ) === false ) {
+							event.preventDefault();
+							event.stopPropagation();
+						}
+					}
+				}
+			}
+		}
+
+		// Call the postDispatch hook for the mapped type
+		if ( special.postDispatch ) {
+			special.postDispatch.call( this, event );
+		}
+
+		return event.result;
+	},
+
+	handlers: function( event, handlers ) {
+		var i, matches, sel, handleObj,
+			handlerQueue = [],
+			delegateCount = handlers.delegateCount,
+			cur = event.target;
+
+		// Support (at least): Chrome, IE9
+		// Find delegate handlers
+		// Black-hole SVG <use> instance trees (#13180)
+		//
+		// Support: Firefox<=42+
+		// Avoid non-left-click in FF but don't block IE radio events (#3861, gh-2343)
+		if ( delegateCount && cur.nodeType &&
+			( event.type !== "click" || isNaN( event.button ) || event.button < 1 ) ) {
+
+			/* jshint eqeqeq: false */
+			for ( ; cur != this; cur = cur.parentNode || this ) {
+				/* jshint eqeqeq: true */
+
+				// Don't check non-elements (#13208)
+				// Don't process clicks on disabled elements (#6911, #8165, #11382, #11764)
+				if ( cur.nodeType === 1 && ( cur.disabled !== true || event.type !== "click" ) ) {
+					matches = [];
+					for ( i = 0; i < delegateCount; i++ ) {
+						handleObj = handlers[ i ];
+
+						// Don't conflict with Object.prototype properties (#13203)
+						sel = handleObj.selector + " ";
+
+						if ( matches[ sel ] === undefined ) {
+							matches[ sel ] = handleObj.needsContext ?
+								jQuery( sel, this ).index( cur ) > -1 :
+								jQuery.find( sel, this, null, [ cur ] ).length;
+						}
+						if ( matches[ sel ] ) {
+							matches.push( handleObj );
+						}
+					}
+					if ( matches.length ) {
+						handlerQueue.push( { elem: cur, handlers: matches } );
+					}
+				}
+			}
+		}
+
+		// Add the remaining (directly-bound) handlers
+		if ( delegateCount < handlers.length ) {
+			handlerQueue.push( { elem: this, handlers: handlers.slice( delegateCount ) } );
+		}
+
+		return handlerQueue;
+	},
+
+	fix: function( event ) {
+		if ( event[ jQuery.expando ] ) {
+			return event;
+		}
+
+		// Create a writable copy of the event object and normalize some properties
+		var i, prop, copy,
+			type = event.type,
+			originalEvent = event,
+			fixHook = this.fixHooks[ type ];
+
+		if ( !fixHook ) {
+			this.fixHooks[ type ] = fixHook =
+				rmouseEvent.test( type ) ? this.mouseHooks :
+				rkeyEvent.test( type ) ? this.keyHooks :
+				{};
+		}
+		copy = fixHook.props ? this.props.concat( fixHook.props ) : this.props;
+
+		event = new jQuery.Event( originalEvent );
+
+		i = copy.length;
+		while ( i-- ) {
+			prop = copy[ i ];
+			event[ prop ] = originalEvent[ prop ];
+		}
+
+		// Support: IE<9
+		// Fix target property (#1925)
+		if ( !event.target ) {
+			event.target = originalEvent.srcElement || document;
+		}
+
+		// Support: Safari 6-8+
+		// Target should not be a text node (#504, #13143)
+		if ( event.target.nodeType === 3 ) {
+			event.target = event.target.parentNode;
+		}
+
+		// Support: IE<9
+		// For mouse/key events, metaKey==false if it's undefined (#3368, #11328)
+		event.metaKey = !!event.metaKey;
+
+		return fixHook.filter ? fixHook.filter( event, originalEvent ) : event;
+	},
+
+	// Includes some event props shared by KeyEvent and MouseEvent
+	props: ( "altKey bubbles cancelable ctrlKey currentTarget detail eventPhase " +
+		"metaKey relatedTarget shiftKey target timeStamp view which" ).split( " " ),
+
+	fixHooks: {},
+
+	keyHooks: {
+		props: "char charCode key keyCode".split( " " ),
+		filter: function( event, original ) {
+
+			// Add which for key events
+			if ( event.which == null ) {
+				event.which = original.charCode != null ? original.charCode : original.keyCode;
+			}
+
+			return event;
+		}
+	},
+
+	mouseHooks: {
+		props: ( "button buttons clientX clientY fromElement offsetX offsetY " +
+			"pageX pageY screenX screenY toElement" ).split( " " ),
+		filter: function( event, original ) {
+			var body, eventDoc, doc,
+				button = original.button,
+				fromElement = original.fromElement;
+
+			// Calculate pageX/Y if missing and clientX/Y available
+			if ( event.pageX == null && original.clientX != null ) {
+				eventDoc = event.target.ownerDocument || document;
+				doc = eventDoc.documentElement;
+				body = eventDoc.body;
+
+				event.pageX = original.clientX +
+					( doc && doc.scrollLeft || body && body.scrollLeft || 0 ) -
+					( doc && doc.clientLeft || body && body.clientLeft || 0 );
+				event.pageY = original.clientY +
+					( doc && doc.scrollTop  || body && body.scrollTop  || 0 ) -
+					( doc && doc.clientTop  || body && body.clientTop  || 0 );
+			}
+
+			// Add relatedTarget, if necessary
+			if ( !event.relatedTarget && fromElement ) {
+				event.relatedTarget = fromElement === event.target ?
+					original.toElement :
+					fromElement;
+			}
+
+			// Add which for click: 1 === left; 2 === middle; 3 === right
+			// Note: button is not normalized, so don't use it
+			if ( !event.which && button !== undefined ) {
+				event.which = ( button & 1 ? 1 : ( button & 2 ? 3 : ( button & 4 ? 2 : 0 ) ) );
+			}
+
+			return event;
+		}
+	},
+
+	special: {
+		load: {
+
+			// Prevent triggered image.load events from bubbling to window.load
+			noBubble: true
+		},
+		focus: {
+
+			// Fire native event if possible so blur/focus sequence is correct
+			trigger: function() {
+				if ( this !== safeActiveElement() && this.focus ) {
+					try {
+						this.focus();
+						return false;
+					} catch ( e ) {
+
+						// Support: IE<9
+						// If we error on focus to hidden element (#1486, #12518),
+						// let .trigger() run the handlers
+					}
+				}
+			},
+			delegateType: "focusin"
+		},
+		blur: {
+			trigger: function() {
+				if ( this === safeActiveElement() && this.blur ) {
+					this.blur();
+					return false;
+				}
+			},
+			delegateType: "focusout"
+		},
+		click: {
+
+			// For checkbox, fire native event so checked state will be right
+			trigger: function() {
+				if ( jQuery.nodeName( this, "input" ) && this.type === "checkbox" && this.click ) {
+					this.click();
+					return false;
+				}
+			},
+
+			// For cross-browser consistency, don't fire native .click() on links
+			_default: function( event ) {
+				return jQuery.nodeName( event.target, "a" );
+			}
+		},
+
+		beforeunload: {
+			postDispatch: function( event ) {
+
+				// Support: Firefox 20+
+				// Firefox doesn't alert if the returnValue field is not set.
+				if ( event.result !== undefined && event.originalEvent ) {
+					event.originalEvent.returnValue = event.result;
+				}
+			}
+		}
+	},
+
+	// Piggyback on a donor event to simulate a different one
+	simulate: function( type, elem, event ) {
+		var e = jQuery.extend(
+			new jQuery.Event(),
+			event,
+			{
+				type: type,
+				isSimulated: true
+
+				// Previously, `originalEvent: {}` was set here, so stopPropagation call
+				// would not be triggered on donor event, since in our own
+				// jQuery.event.stopPropagation function we had a check for existence of
+				// originalEvent.stopPropagation method, so, consequently it would be a noop.
+				//
+				// Guard for simulated events was moved to jQuery.event.stopPropagation function
+				// since `originalEvent` should point to the original event for the
+				// constancy with other events and for more focused logic
+			}
+		);
+
+		jQuery.event.trigger( e, null, elem );
+
+		if ( e.isDefaultPrevented() ) {
+			event.preventDefault();
+		}
+	}
+};
+
+jQuery.removeEvent = document.removeEventListener ?
+	function( elem, type, handle ) {
+
+		// This "if" is needed for plain objects
+		if ( elem.removeEventListener ) {
+			elem.removeEventListener( type, handle );
+		}
+	} :
+	function( elem, type, handle ) {
+		var name = "on" + type;
+
+		if ( elem.detachEvent ) {
+
+			// #8545, #7054, preventing memory leaks for custom events in IE6-8
+			// detachEvent needed property on element, by name of that event,
+			// to properly expose it to GC
+			if ( typeof elem[ name ] === "undefined" ) {
+				elem[ name ] = null;
+			}
+
+			elem.detachEvent( name, handle );
+		}
+	};
+
+jQuery.Event = function( src, props ) {
+
+	// Allow instantiation without the 'new' keyword
+	if ( !( this instanceof jQuery.Event ) ) {
+		return new jQuery.Event( src, props );
+	}
+
+	// Event object
+	if ( src && src.type ) {
+		this.originalEvent = src;
+		this.type = src.type;
+
+		// Events bubbling up the document may have been marked as prevented
+		// by a handler lower down the tree; reflect the correct value.
+		this.isDefaultPrevented = src.defaultPrevented ||
+				src.defaultPrevented === undefined &&
+
+				// Support: IE < 9, Android < 4.0
+				src.returnValue === false ?
+			returnTrue :
+			returnFalse;
+
+	// Event type
+	} else {
+		this.type = src;
+	}
+
+	// Put explicitly provided properties onto the event object
+	if ( props ) {
+		jQuery.extend( this, props );
+	}
+
+	// Create a timestamp if incoming event doesn't have one
+	this.timeStamp = src && src.timeStamp || jQuery.now();
+
+	// Mark it as fixed
+	this[ jQuery.expando ] = true;
+};
+
+// jQuery.Event is based on DOM3 Events as specified by the ECMAScript Language Binding
+// http://www.w3.org/TR/2003/WD-DOM-Level-3-Events-20030331/ecma-script-binding.html
+jQuery.Event.prototype = {
+	constructor: jQuery.Event,
+	isDefaultPrevented: returnFalse,
+	isPropagationStopped: returnFalse,
+	isImmediatePropagationStopped: returnFalse,
+
+	preventDefault: function() {
+		var e = this.originalEvent;
+
+		this.isDefaultPrevented = returnTrue;
+		if ( !e ) {
+			return;
+		}
+
+		// If preventDefault exists, run it on the original event
+		if ( e.preventDefault ) {
+			e.preventDefault();
+
+		// Support: IE
+		// Otherwise set the returnValue property of the original event to false
+		} else {
+			e.returnValue = false;
+		}
+	},
+	stopPropagation: function() {
+		var e = this.originalEvent;
+
+		this.isPropagationStopped = returnTrue;
+
+		if ( !e || this.isSimulated ) {
+			return;
+		}
+
+		// If stopPropagation exists, run it on the original event
+		if ( e.stopPropagation ) {
+			e.stopPropagation();
+		}
+
+		// Support: IE
+		// Set the cancelBubble property of the original event to true
+		e.cancelBubble = true;
+	},
+	stopImmediatePropagation: function() {
+		var e = this.originalEvent;
+
+		this.isImmediatePropagationStopped = returnTrue;
+
+		if ( e && e.stopImmediatePropagation ) {
+			e.stopImmediatePropagation();
+		}
+
+		this.stopPropagation();
+	}
+};
+
+// Create mouseenter/leave events using mouseover/out and event-time checks
+// so that event delegation works in jQuery.
+// Do the same for pointerenter/pointerleave and pointerover/pointerout
+//
+// Support: Safari 7 only
+// Safari sends mouseenter too often; see:
+// https://code.google.com/p/chromium/issues/detail?id=470258
+// for the description of the bug (it existed in older Chrome versions as well).
+jQuery.each( {
+	mouseenter: "mouseover",
+	mouseleave: "mouseout",
+	pointerenter: "pointerover",
+	pointerleave: "pointerout"
+}, function( orig, fix ) {
+	jQuery.event.special[ orig ] = {
+		delegateType: fix,
+		bindType: fix,
+
+		handle: function( event ) {
+			var ret,
+				target = this,
+				related = event.relatedTarget,
+				handleObj = event.handleObj;
+
+			// For mouseenter/leave call the handler if related is outside the target.
+			// NB: No relatedTarget if the mouse left/entered the browser window
+			if ( !related || ( related !== target && !jQuery.contains( target, related ) ) ) {
+				event.type = handleObj.origType;
+				ret = handleObj.handler.apply( this, arguments );
+				event.type = fix;
+			}
+			return ret;
+		}
+	};
+} );
+
+// IE submit delegation
+if ( !support.submit ) {
+
+	jQuery.event.special.submit = {
+		setup: function() {
+
+			// Only need this for delegated form submit events
+			if ( jQuery.nodeName( this, "form" ) ) {
+				return false;
+			}
+
+			// Lazy-add a submit handler when a descendant form may potentially be submitted
+			jQuery.event.add( this, "click._submit keypress._submit", function( e ) {
+
+				// Node name check avoids a VML-related crash in IE (#9807)
+				var elem = e.target,
+					form = jQuery.nodeName( elem, "input" ) || jQuery.nodeName( elem, "button" ) ?
+
+						// Support: IE <=8
+						// We use jQuery.prop instead of elem.form
+						// to allow fixing the IE8 delegated submit issue (gh-2332)
+						// by 3rd party polyfills/workarounds.
+						jQuery.prop( elem, "form" ) :
+						undefined;
+
+				if ( form && !jQuery._data( form, "submit" ) ) {
+					jQuery.event.add( form, "submit._submit", function( event ) {
+						event._submitBubble = true;
+					} );
+					jQuery._data( form, "submit", true );
+				}
+			} );
+
+			// return undefined since we don't need an event listener
+		},
+
+		postDispatch: function( event ) {
+
+			// If form was submitted by the user, bubble the event up the tree
+			if ( event._submitBubble ) {
+				delete event._submitBubble;
+				if ( this.parentNode && !event.isTrigger ) {
+					jQuery.event.simulate( "submit", this.parentNode, event );
+				}
+			}
+		},
+
+		teardown: function() {
+
+			// Only need this for delegated form submit events
+			if ( jQuery.nodeName( this, "form" ) ) {
+				return false;
+			}
+
+			// Remove delegated handlers; cleanData eventually reaps submit handlers attached above
+			jQuery.event.remove( this, "._submit" );
+		}
+	};
+}
+
+// IE change delegation and checkbox/radio fix
+if ( !support.change ) {
+
+	jQuery.event.special.change = {
+
+		setup: function() {
+
+			if ( rformElems.test( this.nodeName ) ) {
+
+				// IE doesn't fire change on a check/radio until blur; trigger it on click
+				// after a propertychange. Eat the blur-change in special.change.handle.
+				// This still fires onchange a second time for check/radio after blur.
+				if ( this.type === "checkbox" || this.type === "radio" ) {
+					jQuery.event.add( this, "propertychange._change", function( event ) {
+						if ( event.originalEvent.propertyName === "checked" ) {
+							this._justChanged = true;
+						}
+					} );
+					jQuery.event.add( this, "click._change", function( event ) {
+						if ( this._justChanged && !event.isTrigger ) {
+							this._justChanged = false;
+						}
+
+						// Allow triggered, simulated change events (#11500)
+						jQuery.event.simulate( "change", this, event );
+					} );
+				}
+				return false;
+			}
+
+			// Delegated event; lazy-add a change handler on descendant inputs
+			jQuery.event.add( this, "beforeactivate._change", function( e ) {
+				var elem = e.target;
+
+				if ( rformElems.test( elem.nodeName ) && !jQuery._data( elem, "change" ) ) {
+					jQuery.event.add( elem, "change._change", function( event ) {
+						if ( this.parentNode && !event.isSimulated && !event.isTrigger ) {
+							jQuery.event.simulate( "change", this.parentNode, event );
+						}
+					} );
+					jQuery._data( elem, "change", true );
+				}
+			} );
+		},
+
+		handle: function( event ) {
+			var elem = event.target;
+
+			// Swallow native change events from checkbox/radio, we already triggered them above
+			if ( this !== elem || event.isSimulated || event.isTrigger ||
+				( elem.type !== "radio" && elem.type !== "checkbox" ) ) {
+
+				return event.handleObj.handler.apply( this, arguments );
+			}
+		},
+
+		teardown: function() {
+			jQuery.event.remove( this, "._change" );
+
+			return !rformElems.test( this.nodeName );
+		}
+	};
+}
+
+// Support: Firefox
+// Firefox doesn't have focus(in | out) events
+// Related ticket - https://bugzilla.mozilla.org/show_bug.cgi?id=687787
+//
+// Support: Chrome, Safari
+// focus(in | out) events fire after focus & blur events,
+// which is spec violation - http://www.w3.org/TR/DOM-Level-3-Events/#events-focusevent-event-order
+// Related ticket - https://code.google.com/p/chromium/issues/detail?id=449857
+if ( !support.focusin ) {
+	jQuery.each( { focus: "focusin", blur: "focusout" }, function( orig, fix ) {
+
+		// Attach a single capturing handler on the document while someone wants focusin/focusout
+		var handler = function( event ) {
+			jQuery.event.simulate( fix, event.target, jQuery.event.fix( event ) );
+		};
+
+		jQuery.event.special[ fix ] = {
+			setup: function() {
+				var doc = this.ownerDocument || this,
+					attaches = jQuery._data( doc, fix );
+
+				if ( !attaches ) {
+					doc.addEventListener( orig, handler, true );
+				}
+				jQuery._data( doc, fix, ( attaches || 0 ) + 1 );
+			},
+			teardown: function() {
+				var doc = this.ownerDocument || this,
+					attaches = jQuery._data( doc, fix ) - 1;
+
+				if ( !attaches ) {
+					doc.removeEventListener( orig, handler, true );
+					jQuery._removeData( doc, fix );
+				} else {
+					jQuery._data( doc, fix, attaches );
+				}
+			}
+		};
+	} );
+}
+
+jQuery.fn.extend( {
+
+	on: function( types, selector, data, fn ) {
+		return on( this, types, selector, data, fn );
+	},
+	one: function( types, selector, data, fn ) {
+		return on( this, types, selector, data, fn, 1 );
+	},
+	off: function( types, selector, fn ) {
+		var handleObj, type;
+		if ( types && types.preventDefault && types.handleObj ) {
+
+			// ( event )  dispatched jQuery.Event
+			handleObj = types.handleObj;
+			jQuery( types.delegateTarget ).off(
+				handleObj.namespace ?
+					handleObj.origType + "." + handleObj.namespace :
+					handleObj.origType,
+				handleObj.selector,
+				handleObj.handler
+			);
+			return this;
+		}
+		if ( typeof types === "object" ) {
+
+			// ( types-object [, selector] )
+			for ( type in types ) {
+				this.off( type, selector, types[ type ] );
+			}
+			return this;
+		}
+		if ( selector === false || typeof selector === "function" ) {
+
+			// ( types [, fn] )
+			fn = selector;
+			selector = undefined;
+		}
+		if ( fn === false ) {
+			fn = returnFalse;
+		}
+		return this.each( function() {
+			jQuery.event.remove( this, types, fn, selector );
+		} );
+	},
+
+	trigger: function( type, data ) {
+		return this.each( function() {
+			jQuery.event.trigger( type, data, this );
+		} );
+	},
+	triggerHandler: function( type, data ) {
+		var elem = this[ 0 ];
+		if ( elem ) {
+			return jQuery.event.trigger( type, data, elem, true );
+		}
+	}
+} );
+
+
+var rinlinejQuery = / jQuery\d+="(?:null|\d+)"/g,
+	rnoshimcache = new RegExp( "<(?:" + nodeNames + ")[\\s/>]", "i" ),
+	rxhtmlTag = /<(?!area|br|col|embed|hr|img|input|link|meta|param)(([\w:-]+)[^>]*)\/>/gi,
+
+	// Support: IE 10-11, Edge 10240+
+	// In IE/Edge using regex groups here causes severe slowdowns.
+	// See https://connect.microsoft.com/IE/feedback/details/1736512/
+	rnoInnerhtml = /<script|<style|<link/i,
+
+	// checked="checked" or checked
+	rchecked = /checked\s*(?:[^=]|=\s*.checked.)/i,
+	rscriptTypeMasked = /^true\/(.*)/,
+	rcleanScript = /^\s*<!(?:\[CDATA\[|--)|(?:\]\]|--)>\s*$/g,
+	safeFragment = createSafeFragment( document ),
+	fragmentDiv = safeFragment.appendChild( document.createElement( "div" ) );
+
+// Support: IE<8
+// Manipulating tables requires a tbody
+function manipulationTarget( elem, content ) {
+	return jQuery.nodeName( elem, "table" ) &&
+		jQuery.nodeName( content.nodeType !== 11 ? content : content.firstChild, "tr" ) ?
+
+		elem.getElementsByTagName( "tbody" )[ 0 ] ||
+			elem.appendChild( elem.ownerDocument.createElement( "tbody" ) ) :
+		elem;
+}
+
+// Replace/restore the type attribute of script elements for safe DOM manipulation
+function disableScript( elem ) {
+	elem.type = ( jQuery.find.attr( elem, "type" ) !== null ) + "/" + elem.type;
+	return elem;
+}
+function restoreScript( elem ) {
+	var match = rscriptTypeMasked.exec( elem.type );
+	if ( match ) {
+		elem.type = match[ 1 ];
+	} else {
+		elem.removeAttribute( "type" );
+	}
+	return elem;
+}
+
+function cloneCopyEvent( src, dest ) {
+	if ( dest.nodeType !== 1 || !jQuery.hasData( src ) ) {
+		return;
+	}
+
+	var type, i, l,
+		oldData = jQuery._data( src ),
+		curData = jQuery._data( dest, oldData ),
+		events = oldData.events;
+
+	if ( events ) {
+		delete curData.handle;
+		curData.events = {};
+
+		for ( type in events ) {
+			for ( i = 0, l = events[ type ].length; i < l; i++ ) {
+				jQuery.event.add( dest, type, events[ type ][ i ] );
+			}
+		}
+	}
+
+	// make the cloned public data object a copy from the original
+	if ( curData.data ) {
+		curData.data = jQuery.extend( {}, curData.data );
+	}
+}
+
+function fixCloneNodeIssues( src, dest ) {
+	var nodeName, e, data;
+
+	// We do not need to do anything for non-Elements
+	if ( dest.nodeType !== 1 ) {
+		return;
+	}
+
+	nodeName = dest.nodeName.toLowerCase();
+
+	// IE6-8 copies events bound via attachEvent when using cloneNode.
+	if ( !support.noCloneEvent && dest[ jQuery.expando ] ) {
+		data = jQuery._data( dest );
+
+		for ( e in data.events ) {
+			jQuery.removeEvent( dest, e, data.handle );
+		}
+
+		// Event data gets referenced instead of copied if the expando gets copied too
+		dest.removeAttribute( jQuery.expando );
+	}
+
+	// IE blanks contents when cloning scripts, and tries to evaluate newly-set text
+	if ( nodeName === "script" && dest.text !== src.text ) {
+		disableScript( dest ).text = src.text;
+		restoreScript( dest );
+
+	// IE6-10 improperly clones children of object elements using classid.
+	// IE10 throws NoModificationAllowedError if parent is null, #12132.
+	} else if ( nodeName === "object" ) {
+		if ( dest.parentNode ) {
+			dest.outerHTML = src.outerHTML;
+		}
+
+		// This path appears unavoidable for IE9. When cloning an object
+		// element in IE9, the outerHTML strategy above is not sufficient.
+		// If the src has innerHTML and the destination does not,
+		// copy the src.innerHTML into the dest.innerHTML. #10324
+		if ( support.html5Clone && ( src.innerHTML && !jQuery.trim( dest.innerHTML ) ) ) {
+			dest.innerHTML = src.innerHTML;
+		}
+
+	} else if ( nodeName === "input" && rcheckableType.test( src.type ) ) {
+
+		// IE6-8 fails to persist the checked state of a cloned checkbox
+		// or radio button. Worse, IE6-7 fail to give the cloned element
+		// a checked appearance if the defaultChecked value isn't also set
+
+		dest.defaultChecked = dest.checked = src.checked;
+
+		// IE6-7 get confused and end up setting the value of a cloned
+		// checkbox/radio button to an empty string instead of "on"
+		if ( dest.value !== src.value ) {
+			dest.value = src.value;
+		}
+
+	// IE6-8 fails to return the selected option to the default selected
+	// state when cloning options
+	} else if ( nodeName === "option" ) {
+		dest.defaultSelected = dest.selected = src.defaultSelected;
+
+	// IE6-8 fails to set the defaultValue to the correct value when
+	// cloning other types of input fields
+	} else if ( nodeName === "input" || nodeName === "textarea" ) {
+		dest.defaultValue = src.defaultValue;
+	}
+}
+
+function domManip( collection, args, callback, ignored ) {
+
+	// Flatten any nested arrays
+	args = concat.apply( [], args );
+
+	var first, node, hasScripts,
+		scripts, doc, fragment,
+		i = 0,
+		l = collection.length,
+		iNoClone = l - 1,
+		value = args[ 0 ],
+		isFunction = jQuery.isFunction( value );
+
+	// We can't cloneNode fragments that contain checked, in WebKit
+	if ( isFunction ||
+			( l > 1 && typeof value === "string" &&
+				!support.checkClone && rchecked.test( value ) ) ) {
+		return collection.each( function( index ) {
+			var self = collection.eq( index );
+			if ( isFunction ) {
+				args[ 0 ] = value.call( this, index, self.html() );
+			}
+			domManip( self, args, callback, ignored );
+		} );
+	}
+
+	if ( l ) {
+		fragment = buildFragment( args, collection[ 0 ].ownerDocument, false, collection, ignored );
+		first = fragment.firstChild;
+
+		if ( fragment.childNodes.length === 1 ) {
+			fragment = first;
+		}
+
+		// Require either new content or an interest in ignored elements to invoke the callback
+		if ( first || ignored ) {
+			scripts = jQuery.map( getAll( fragment, "script" ), disableScript );
+			hasScripts = scripts.length;
+
+			// Use the original fragment for the last item
+			// instead of the first because it can end up
+			// being emptied incorrectly in certain situations (#8070).
+			for ( ; i < l; i++ ) {
+				node = fragment;
+
+				if ( i !== iNoClone ) {
+					node = jQuery.clone( node, true, true );
+
+					// Keep references to cloned scripts for later restoration
+					if ( hasScripts ) {
+
+						// Support: Android<4.1, PhantomJS<2
+						// push.apply(_, arraylike) throws on ancient WebKit
+						jQuery.merge( scripts, getAll( node, "script" ) );
+					}
+				}
+
+				callback.call( collection[ i ], node, i );
+			}
+
+			if ( hasScripts ) {
+				doc = scripts[ scripts.length - 1 ].ownerDocument;
+
+				// Reenable scripts
+				jQuery.map( scripts, restoreScript );
+
+				// Evaluate executable scripts on first document insertion
+				for ( i = 0; i < hasScripts; i++ ) {
+					node = scripts[ i ];
+					if ( rscriptType.test( node.type || "" ) &&
+						!jQuery._data( node, "globalEval" ) &&
+						jQuery.contains( doc, node ) ) {
+
+						if ( node.src ) {
+
+							// Optional AJAX dependency, but won't run scripts if not present
+							if ( jQuery._evalUrl ) {
+								jQuery._evalUrl( node.src );
+							}
+						} else {
+							jQuery.globalEval(
+								( node.text || node.textContent || node.innerHTML || "" )
+									.replace( rcleanScript, "" )
+							);
+						}
+					}
+				}
+			}
+
+			// Fix #11809: Avoid leaking memory
+			fragment = first = null;
+		}
+	}
+
+	return collection;
+}
+
+function remove( elem, selector, keepData ) {
+	var node,
+		elems = selector ? jQuery.filter( selector, elem ) : elem,
+		i = 0;
+
+	for ( ; ( node = elems[ i ] ) != null; i++ ) {
+
+		if ( !keepData && node.nodeType === 1 ) {
+			jQuery.cleanData( getAll( node ) );
+		}
+
+		if ( node.parentNode ) {
+			if ( keepData && jQuery.contains( node.ownerDocument, node ) ) {
+				setGlobalEval( getAll( node, "script" ) );
+			}
+			node.parentNode.removeChild( node );
+		}
+	}
+
+	return elem;
+}
+
+jQuery.extend( {
+	htmlPrefilter: function( html ) {
+		return html.replace( rxhtmlTag, "<$1></$2>" );
+	},
+
+	clone: function( elem, dataAndEvents, deepDataAndEvents ) {
+		var destElements, node, clone, i, srcElements,
+			inPage = jQuery.contains( elem.ownerDocument, elem );
+
+		if ( support.html5Clone || jQuery.isXMLDoc( elem ) ||
+			!rnoshimcache.test( "<" + elem.nodeName + ">" ) ) {
+
+			clone = elem.cloneNode( true );
+
+		// IE<=8 does not properly clone detached, unknown element nodes
+		} else {
+			fragmentDiv.innerHTML = elem.outerHTML;
+			fragmentDiv.removeChild( clone = fragmentDiv.firstChild );
+		}
+
+		if ( ( !support.noCloneEvent || !support.noCloneChecked ) &&
+				( elem.nodeType === 1 || elem.nodeType === 11 ) && !jQuery.isXMLDoc( elem ) ) {
+
+			// We eschew Sizzle here for performance reasons: http://jsperf.com/getall-vs-sizzle/2
+			destElements = getAll( clone );
+			srcElements = getAll( elem );
+
+			// Fix all IE cloning issues
+			for ( i = 0; ( node = srcElements[ i ] ) != null; ++i ) {
+
+				// Ensure that the destination node is not null; Fixes #9587
+				if ( destElements[ i ] ) {
+					fixCloneNodeIssues( node, destElements[ i ] );
+				}
+			}
+		}
+
+		// Copy the events from the original to the clone
+		if ( dataAndEvents ) {
+			if ( deepDataAndEvents ) {
+				srcElements = srcElements || getAll( elem );
+				destElements = destElements || getAll( clone );
+
+				for ( i = 0; ( node = srcElements[ i ] ) != null; i++ ) {
+					cloneCopyEvent( node, destElements[ i ] );
+				}
+			} else {
+				cloneCopyEvent( elem, clone );
+			}
+		}
+
+		// Preserve script evaluation history
+		destElements = getAll( clone, "script" );
+		if ( destElements.length > 0 ) {
+			setGlobalEval( destElements, !inPage && getAll( elem, "script" ) );
+		}
+
+		destElements = srcElements = node = null;
+
+		// Return the cloned set
+		return clone;
+	},
+
+	cleanData: function( elems, /* internal */ forceAcceptData ) {
+		var elem, type, id, data,
+			i = 0,
+			internalKey = jQuery.expando,
+			cache = jQuery.cache,
+			attributes = support.attributes,
+			special = jQuery.event.special;
+
+		for ( ; ( elem = elems[ i ] ) != null; i++ ) {
+			if ( forceAcceptData || acceptData( elem ) ) {
+
+				id = elem[ internalKey ];
+				data = id && cache[ id ];
+
+				if ( data ) {
+					if ( data.events ) {
+						for ( type in data.events ) {
+							if ( special[ type ] ) {
+								jQuery.event.remove( elem, type );
+
+							// This is a shortcut to avoid jQuery.event.remove's overhead
+							} else {
+								jQuery.removeEvent( elem, type, data.handle );
+							}
+						}
+					}
+
+					// Remove cache only if it was not already removed by jQuery.event.remove
+					if ( cache[ id ] ) {
+
+						delete cache[ id ];
+
+						// Support: IE<9
+						// IE does not allow us to delete expando properties from nodes
+						// IE creates expando attributes along with the property
+						// IE does not have a removeAttribute function on Document nodes
+						if ( !attributes && typeof elem.removeAttribute !== "undefined" ) {
+							elem.removeAttribute( internalKey );
+
+						// Webkit & Blink performance suffers when deleting properties
+						// from DOM nodes, so set to undefined instead
+						// https://code.google.com/p/chromium/issues/detail?id=378607
+						} else {
+							elem[ internalKey ] = undefined;
+						}
+
+						deletedIds.push( id );
+					}
+				}
+			}
+		}
+	}
+} );
+
+jQuery.fn.extend( {
+
+	// Keep domManip exposed until 3.0 (gh-2225)
+	domManip: domManip,
+
+	detach: function( selector ) {
+		return remove( this, selector, true );
+	},
+
+	remove: function( selector ) {
+		return remove( this, selector );
+	},
+
+	text: function( value ) {
+		return access( this, function( value ) {
+			return value === undefined ?
+				jQuery.text( this ) :
+				this.empty().append(
+					( this[ 0 ] && this[ 0 ].ownerDocument || document ).createTextNode( value )
+				);
+		}, null, value, arguments.length );
+	},
+
+	append: function() {
+		return domManip( this, arguments, function( elem ) {
+			if ( this.nodeType === 1 || this.nodeType === 11 || this.nodeType === 9 ) {
+				var target = manipulationTarget( this, elem );
+				target.appendChild( elem );
+			}
+		} );
+	},
+
+	prepend: function() {
+		return domManip( this, arguments, function( elem ) {
+			if ( this.nodeType === 1 || this.nodeType === 11 || this.nodeType === 9 ) {
+				var target = manipulationTarget( this, elem );
+				target.insertBefore( elem, target.firstChild );
+			}
+		} );
+	},
+
+	before: function() {
+		return domManip( this, arguments, function( elem ) {
+			if ( this.parentNode ) {
+				this.parentNode.insertBefore( elem, this );
+			}
+		} );
+	},
+
+	after: function() {
+		return domManip( this, arguments, function( elem ) {
+			if ( this.parentNode ) {
+				this.parentNode.insertBefore( elem, this.nextSibling );
+			}
+		} );
+	},
+
+	empty: function() {
+		var elem,
+			i = 0;
+
+		for ( ; ( elem = this[ i ] ) != null; i++ ) {
+
+			// Remove element nodes and prevent memory leaks
+			if ( elem.nodeType === 1 ) {
+				jQuery.cleanData( getAll( elem, false ) );
+			}
+
+			// Remove any remaining nodes
+			while ( elem.firstChild ) {
+				elem.removeChild( elem.firstChild );
+			}
+
+			// If this is a select, ensure that it displays empty (#12336)
+			// Support: IE<9
+			if ( elem.options && jQuery.nodeName( elem, "select" ) ) {
+				elem.options.length = 0;
+			}
+		}
+
+		return this;
+	},
+
+	clone: function( dataAndEvents, deepDataAndEvents ) {
+		dataAndEvents = dataAndEvents == null ? false : dataAndEvents;
+		deepDataAndEvents = deepDataAndEvents == null ? dataAndEvents : deepDataAndEvents;
+
+		return this.map( function() {
+			return jQuery.clone( this, dataAndEvents, deepDataAndEvents );
+		} );
+	},
+
+	html: function( value ) {
+		return access( this, function( value ) {
+			var elem = this[ 0 ] || {},
+				i = 0,
+				l = this.length;
+
+			if ( value === undefined ) {
+				return elem.nodeType === 1 ?
+					elem.innerHTML.replace( rinlinejQuery, "" ) :
+					undefined;
+			}
+
+			// See if we can take a shortcut and just use innerHTML
+			if ( typeof value === "string" && !rnoInnerhtml.test( value ) &&
+				( support.htmlSerialize || !rnoshimcache.test( value )  ) &&
+				( support.leadingWhitespace || !rleadingWhitespace.test( value ) ) &&
+				!wrapMap[ ( rtagName.exec( value ) || [ "", "" ] )[ 1 ].toLowerCase() ] ) {
+
+				value = jQuery.htmlPrefilter( value );
+
+				try {
+					for ( ; i < l; i++ ) {
+
+						// Remove element nodes and prevent memory leaks
+						elem = this[ i ] || {};
+						if ( elem.nodeType === 1 ) {
+							jQuery.cleanData( getAll( elem, false ) );
+							elem.innerHTML = value;
+						}
+					}
+
+					elem = 0;
+
+				// If using innerHTML throws an exception, use the fallback method
+				} catch ( e ) {}
+			}
+
+			if ( elem ) {
+				this.empty().append( value );
+			}
+		}, null, value, arguments.length );
+	},
+
+	replaceWith: function() {
+		var ignored = [];
+
+		// Make the changes, replacing each non-ignored context element with the new content
+		return domManip( this, arguments, function( elem ) {
+			var parent = this.parentNode;
+
+			if ( jQuery.inArray( this, ignored ) < 0 ) {
+				jQuery.cleanData( getAll( this ) );
+				if ( parent ) {
+					parent.replaceChild( elem, this );
+				}
+			}
+
+		// Force callback invocation
+		}, ignored );
+	}
+} );
+
+jQuery.each( {
+	appendTo: "append",
+	prependTo: "prepend",
+	insertBefore: "before",
+	insertAfter: "after",
+	replaceAll: "replaceWith"
+}, function( name, original ) {
+	jQuery.fn[ name ] = function( selector ) {
+		var elems,
+			i = 0,
+			ret = [],
+			insert = jQuery( selector ),
+			last = insert.length - 1;
+
+		for ( ; i <= last; i++ ) {
+			elems = i === last ? this : this.clone( true );
+			jQuery( insert[ i ] )[ original ]( elems );
+
+			// Modern browsers can apply jQuery collections as arrays, but oldIE needs a .get()
+			push.apply( ret, elems.get() );
+		}
+
+		return this.pushStack( ret );
+	};
+} );
+
+
+var iframe,
+	elemdisplay = {
+
+		// Support: Firefox
+		// We have to pre-define these values for FF (#10227)
+		HTML: "block",
+		BODY: "block"
+	};
+
+/**
+ * Retrieve the actual display of a element
+ * @param {String} name nodeName of the element
+ * @param {Object} doc Document object
+ */
+
+// Called only from within defaultDisplay
+function actualDisplay( name, doc ) {
+	var elem = jQuery( doc.createElement( name ) ).appendTo( doc.body ),
+
+		display = jQuery.css( elem[ 0 ], "display" );
+
+	// We don't have any data stored on the element,
+	// so use "detach" method as fast way to get rid of the element
+	elem.detach();
+
+	return display;
+}
+
+/**
+ * Try to determine the default display value of an element
+ * @param {String} nodeName
+ */
+function defaultDisplay( nodeName ) {
+	var doc = document,
+		display = elemdisplay[ nodeName ];
+
+	if ( !display ) {
+		display = actualDisplay( nodeName, doc );
+
+		// If the simple way fails, read from inside an iframe
+		if ( display === "none" || !display ) {
+
+			// Use the already-created iframe if possible
+			iframe = ( iframe || jQuery( "<iframe frameborder='0' width='0' height='0'/>" ) )
+				.appendTo( doc.documentElement );
+
+			// Always write a new HTML skeleton so Webkit and Firefox don't choke on reuse
+			doc = ( iframe[ 0 ].contentWindow || iframe[ 0 ].contentDocument ).document;
+
+			// Support: IE
+			doc.write();
+			doc.close();
+
+			display = actualDisplay( nodeName, doc );
+			iframe.detach();
+		}
+
+		// Store the correct default display
+		elemdisplay[ nodeName ] = display;
+	}
+
+	return display;
+}
+var rmargin = ( /^margin/ );
+
+var rnumnonpx = new RegExp( "^(" + pnum + ")(?!px)[a-z%]+$", "i" );
+
+var swap = function( elem, options, callback, args ) {
+	var ret, name,
+		old = {};
+
+	// Remember the old values, and insert the new ones
+	for ( name in options ) {
+		old[ name ] = elem.style[ name ];
+		elem.style[ name ] = options[ name ];
+	}
+
+	ret = callback.apply( elem, args || [] );
+
+	// Revert the old values
+	for ( name in options ) {
+		elem.style[ name ] = old[ name ];
+	}
+
+	return ret;
+};
+
+
+var documentElement = document.documentElement;
+
+
+
+( function() {
+	var pixelPositionVal, pixelMarginRightVal, boxSizingReliableVal,
+		reliableHiddenOffsetsVal, reliableMarginRightVal, reliableMarginLeftVal,
+		container = document.createElement( "div" ),
+		div = document.createElement( "div" );
+
+	// Finish early in limited (non-browser) environments
+	if ( !div.style ) {
+		return;
+	}
+
+	div.style.cssText = "float:left;opacity:.5";
+
+	// Support: IE<9
+	// Make sure that element opacity exists (as opposed to filter)
+	support.opacity = div.style.opacity === "0.5";
+
+	// Verify style float existence
+	// (IE uses styleFloat instead of cssFloat)
+	support.cssFloat = !!div.style.cssFloat;
+
+	div.style.backgroundClip = "content-box";
+	div.cloneNode( true ).style.backgroundClip = "";
+	support.clearCloneStyle = div.style.backgroundClip === "content-box";
+
+	container = document.createElement( "div" );
+	container.style.cssText = "border:0;width:8px;height:0;top:0;left:-9999px;" +
+		"padding:0;margin-top:1px;position:absolute";
+	div.innerHTML = "";
+	container.appendChild( div );
+
+	// Support: Firefox<29, Android 2.3
+	// Vendor-prefix box-sizing
+	support.boxSizing = div.style.boxSizing === "" || div.style.MozBoxSizing === "" ||
+		div.style.WebkitBoxSizing === "";
+
+	jQuery.extend( support, {
+		reliableHiddenOffsets: function() {
+			if ( pixelPositionVal == null ) {
+				computeStyleTests();
+			}
+			return reliableHiddenOffsetsVal;
+		},
+
+		boxSizingReliable: function() {
+
+			// We're checking for pixelPositionVal here instead of boxSizingReliableVal
+			// since that compresses better and they're computed together anyway.
+			if ( pixelPositionVal == null ) {
+				computeStyleTests();
+			}
+			return boxSizingReliableVal;
+		},
+
+		pixelMarginRight: function() {
+
+			// Support: Android 4.0-4.3
+			if ( pixelPositionVal == null ) {
+				computeStyleTests();
+			}
+			return pixelMarginRightVal;
+		},
+
+		pixelPosition: function() {
+			if ( pixelPositionVal == null ) {
+				computeStyleTests();
+			}
+			return pixelPositionVal;
+		},
+
+		reliableMarginRight: function() {
+
+			// Support: Android 2.3
+			if ( pixelPositionVal == null ) {
+				computeStyleTests();
+			}
+			return reliableMarginRightVal;
+		},
+
+		reliableMarginLeft: function() {
+
+			// Support: IE <=8 only, Android 4.0 - 4.3 only, Firefox <=3 - 37
+			if ( pixelPositionVal == null ) {
+				computeStyleTests();
+			}
+			return reliableMarginLeftVal;
+		}
+	} );
+
+	function computeStyleTests() {
+		var contents, divStyle,
+			documentElement = document.documentElement;
+
+		// Setup
+		documentElement.appendChild( container );
+
+		div.style.cssText =
+
+			// Support: Android 2.3
+			// Vendor-prefix box-sizing
+			"-webkit-box-sizing:border-box;box-sizing:border-box;" +
+			"position:relative;display:block;" +
+			"margin:auto;border:1px;padding:1px;" +
+			"top:1%;width:50%";
+
+		// Support: IE<9
+		// Assume reasonable values in the absence of getComputedStyle
+		pixelPositionVal = boxSizingReliableVal = reliableMarginLeftVal = false;
+		pixelMarginRightVal = reliableMarginRightVal = true;
+
+		// Check for getComputedStyle so that this code is not run in IE<9.
+		if ( window.getComputedStyle ) {
+			divStyle = window.getComputedStyle( div );
+			pixelPositionVal = ( divStyle || {} ).top !== "1%";
+			reliableMarginLeftVal = ( divStyle || {} ).marginLeft === "2px";
+			boxSizingReliableVal = ( divStyle || { width: "4px" } ).width === "4px";
+
+			// Support: Android 4.0 - 4.3 only
+			// Some styles come back with percentage values, even though they shouldn't
+			div.style.marginRight = "50%";
+			pixelMarginRightVal = ( divStyle || { marginRight: "4px" } ).marginRight === "4px";
+
+			// Support: Android 2.3 only
+			// Div with explicit width and no margin-right incorrectly
+			// gets computed margin-right based on width of container (#3333)
+			// WebKit Bug 13343 - getComputedStyle returns wrong value for margin-right
+			contents = div.appendChild( document.createElement( "div" ) );
+
+			// Reset CSS: box-sizing; display; margin; border; padding
+			contents.style.cssText = div.style.cssText =
+
+				// Support: Android 2.3
+				// Vendor-prefix box-sizing
+				"-webkit-box-sizing:content-box;-moz-box-sizing:content-box;" +
+				"box-sizing:content-box;display:block;margin:0;border:0;padding:0";
+			contents.style.marginRight = contents.style.width = "0";
+			div.style.width = "1px";
+
+			reliableMarginRightVal =
+				!parseFloat( ( window.getComputedStyle( contents ) || {} ).marginRight );
+
+			div.removeChild( contents );
+		}
+
+		// Support: IE6-8
+		// First check that getClientRects works as expected
+		// Check if table cells still have offsetWidth/Height when they are set
+		// to display:none and there are still other visible table cells in a
+		// table row; if so, offsetWidth/Height are not reliable for use when
+		// determining if an element has been hidden directly using
+		// display:none (it is still safe to use offsets if a parent element is
+		// hidden; don safety goggles and see bug #4512 for more information).
+		div.style.display = "none";
+		reliableHiddenOffsetsVal = div.getClientRects().length === 0;
+		if ( reliableHiddenOffsetsVal ) {
+			div.style.display = "";
+			div.innerHTML = "<table><tr><td></td><td>t</td></tr></table>";
+			contents = div.getElementsByTagName( "td" );
+			contents[ 0 ].style.cssText = "margin:0;border:0;padding:0;display:none";
+			reliableHiddenOffsetsVal = contents[ 0 ].offsetHeight === 0;
+			if ( reliableHiddenOffsetsVal ) {
+				contents[ 0 ].style.display = "";
+				contents[ 1 ].style.display = "none";
+				reliableHiddenOffsetsVal = contents[ 0 ].offsetHeight === 0;
+			}
+		}
+
+		// Teardown
+		documentElement.removeChild( container );
+	}
+
+} )();
+
+
+var getStyles, curCSS,
+	rposition = /^(top|right|bottom|left)$/;
+
+if ( window.getComputedStyle ) {
+	getStyles = function( elem ) {
+
+		// Support: IE<=11+, Firefox<=30+ (#15098, #14150)
+		// IE throws on elements created in popups
+		// FF meanwhile throws on frame elements through "defaultView.getComputedStyle"
+		var view = elem.ownerDocument.defaultView;
+
+		if ( !view || !view.opener ) {
+			view = window;
+		}
+
+		return view.getComputedStyle( elem );
+	};
+
+	curCSS = function( elem, name, computed ) {
+		var width, minWidth, maxWidth, ret,
+			style = elem.style;
+
+		computed = computed || getStyles( elem );
+
+		// getPropertyValue is only needed for .css('filter') in IE9, see #12537
+		ret = computed ? computed.getPropertyValue( name ) || computed[ name ] : undefined;
+
+		// Support: Opera 12.1x only
+		// Fall back to style even without computed
+		// computed is undefined for elems on document fragments
+		if ( ( ret === "" || ret === undefined ) && !jQuery.contains( elem.ownerDocument, elem ) ) {
+			ret = jQuery.style( elem, name );
+		}
+
+		if ( computed ) {
+
+			// A tribute to the "awesome hack by Dean Edwards"
+			// Chrome < 17 and Safari 5.0 uses "computed value"
+			// instead of "used value" for margin-right
+			// Safari 5.1.7 (at least) returns percentage for a larger set of values,
+			// but width seems to be reliably pixels
+			// this is against the CSSOM draft spec:
+			// http://dev.w3.org/csswg/cssom/#resolved-values
+			if ( !support.pixelMarginRight() && rnumnonpx.test( ret ) && rmargin.test( name ) ) {
+
+				// Remember the original values
+				width = style.width;
+				minWidth = style.minWidth;
+				maxWidth = style.maxWidth;
+
+				// Put in the new values to get a computed value out
+				style.minWidth = style.maxWidth = style.width = ret;
+				ret = computed.width;
+
+				// Revert the changed values
+				style.width = width;
+				style.minWidth = minWidth;
+				style.maxWidth = maxWidth;
+			}
+		}
+
+		// Support: IE
+		// IE returns zIndex value as an integer.
+		return ret === undefined ?
+			ret :
+			ret + "";
+	};
+} else if ( documentElement.currentStyle ) {
+	getStyles = function( elem ) {
+		return elem.currentStyle;
+	};
+
+	curCSS = function( elem, name, computed ) {
+		var left, rs, rsLeft, ret,
+			style = elem.style;
+
+		computed = computed || getStyles( elem );
+		ret = computed ? computed[ name ] : undefined;
+
+		// Avoid setting ret to empty string here
+		// so we don't default to auto
+		if ( ret == null && style && style[ name ] ) {
+			ret = style[ name ];
+		}
+
+		// From the awesome hack by Dean Edwards
+		// http://erik.eae.net/archives/2007/07/27/18.54.15/#comment-102291
+
+		// If we're not dealing with a regular pixel number
+		// but a number that has a weird ending, we need to convert it to pixels
+		// but not position css attributes, as those are
+		// proportional to the parent element instead
+		// and we can't measure the parent instead because it
+		// might trigger a "stacking dolls" problem
+		if ( rnumnonpx.test( ret ) && !rposition.test( name ) ) {
+
+			// Remember the original values
+			left = style.left;
+			rs = elem.runtimeStyle;
+			rsLeft = rs && rs.left;
+
+			// Put in the new values to get a computed value out
+			if ( rsLeft ) {
+				rs.left = elem.currentStyle.left;
+			}
+			style.left = name === "fontSize" ? "1em" : ret;
+			ret = style.pixelLeft + "px";
+
+			// Revert the changed values
+			style.left = left;
+			if ( rsLeft ) {
+				rs.left = rsLeft;
+			}
+		}
+
+		// Support: IE
+		// IE returns zIndex value as an integer.
+		return ret === undefined ?
+			ret :
+			ret + "" || "auto";
+	};
+}
+
+
+
+
+function addGetHookIf( conditionFn, hookFn ) {
+
+	// Define the hook, we'll check on the first run if it's really needed.
+	return {
+		get: function() {
+			if ( conditionFn() ) {
+
+				// Hook not needed (or it's not possible to use it due
+				// to missing dependency), remove it.
+				delete this.get;
+				return;
+			}
+
+			// Hook needed; redefine it so that the support test is not executed again.
+			return ( this.get = hookFn ).apply( this, arguments );
+		}
+	};
+}
+
+
+var
+
+		ralpha = /alpha\([^)]*\)/i,
+	ropacity = /opacity\s*=\s*([^)]*)/i,
+
+	// swappable if display is none or starts with table except
+	// "table", "table-cell", or "table-caption"
+	// see here for display values:
+	// https://developer.mozilla.org/en-US/docs/CSS/display
+	rdisplayswap = /^(none|table(?!-c[ea]).+)/,
+	rnumsplit = new RegExp( "^(" + pnum + ")(.*)$", "i" ),
+
+	cssShow = { position: "absolute", visibility: "hidden", display: "block" },
+	cssNormalTransform = {
+		letterSpacing: "0",
+		fontWeight: "400"
+	},
+
+	cssPrefixes = [ "Webkit", "O", "Moz", "ms" ],
+	emptyStyle = document.createElement( "div" ).style;
+
+
+// return a css property mapped to a potentially vendor prefixed property
+function vendorPropName( name ) {
+
+	// shortcut for names that are not vendor prefixed
+	if ( name in emptyStyle ) {
+		return name;
+	}
+
+	// check for vendor prefixed names
+	var capName = name.charAt( 0 ).toUpperCase() + name.slice( 1 ),
+		i = cssPrefixes.length;
+
+	while ( i-- ) {
+		name = cssPrefixes[ i ] + capName;
+		if ( name in emptyStyle ) {
+			return name;
+		}
+	}
+}
+
+function showHide( elements, show ) {
+	var display, elem, hidden,
+		values = [],
+		index = 0,
+		length = elements.length;
+
+	for ( ; index < length; index++ ) {
+		elem = elements[ index ];
+		if ( !elem.style ) {
+			continue;
+		}
+
+		values[ index ] = jQuery._data( elem, "olddisplay" );
+		display = elem.style.display;
+		if ( show ) {
+
+			// Reset the inline display of this element to learn if it is
+			// being hidden by cascaded rules or not
+			if ( !values[ index ] && display === "none" ) {
+				elem.style.display = "";
+			}
+
+			// Set elements which have been overridden with display: none
+			// in a stylesheet to whatever the default browser style is
+			// for such an element
+			if ( elem.style.display === "" && isHidden( elem ) ) {
+				values[ index ] =
+					jQuery._data( elem, "olddisplay", defaultDisplay( elem.nodeName ) );
+			}
+		} else {
+			hidden = isHidden( elem );
+
+			if ( display && display !== "none" || !hidden ) {
+				jQuery._data(
+					elem,
+					"olddisplay",
+					hidden ? display : jQuery.css( elem, "display" )
+				);
+			}
+		}
+	}
+
+	// Set the display of most of the elements in a second loop
+	// to avoid the constant reflow
+	for ( index = 0; index < length; index++ ) {
+		elem = elements[ index ];
+		if ( !elem.style ) {
+			continue;
+		}
+		if ( !show || elem.style.display === "none" || elem.style.display === "" ) {
+			elem.style.display = show ? values[ index ] || "" : "none";
+		}
+	}
+
+	return elements;
+}
+
+function setPositiveNumber( elem, value, subtract ) {
+	var matches = rnumsplit.exec( value );
+	return matches ?
+
+		// Guard against undefined "subtract", e.g., when used as in cssHooks
+		Math.max( 0, matches[ 1 ] - ( subtract || 0 ) ) + ( matches[ 2 ] || "px" ) :
+		value;
+}
+
+function augmentWidthOrHeight( elem, name, extra, isBorderBox, styles ) {
+	var i = extra === ( isBorderBox ? "border" : "content" ) ?
+
+		// If we already have the right measurement, avoid augmentation
+		4 :
+
+		// Otherwise initialize for horizontal or vertical properties
+		name === "width" ? 1 : 0,
+
+		val = 0;
+
+	for ( ; i < 4; i += 2 ) {
+
+		// both box models exclude margin, so add it if we want it
+		if ( extra === "margin" ) {
+			val += jQuery.css( elem, extra + cssExpand[ i ], true, styles );
+		}
+
+		if ( isBorderBox ) {
+
+			// border-box includes padding, so remove it if we want content
+			if ( extra === "content" ) {
+				val -= jQuery.css( elem, "padding" + cssExpand[ i ], true, styles );
+			}
+
+			// at this point, extra isn't border nor margin, so remove border
+			if ( extra !== "margin" ) {
+				val -= jQuery.css( elem, "border" + cssExpand[ i ] + "Width", true, styles );
+			}
+		} else {
+
+			// at this point, extra isn't content, so add padding
+			val += jQuery.css( elem, "padding" + cssExpand[ i ], true, styles );
+
+			// at this point, extra isn't content nor padding, so add border
+			if ( extra !== "padding" ) {
+				val += jQuery.css( elem, "border" + cssExpand[ i ] + "Width", true, styles );
+			}
+		}
+	}
+
+	return val;
+}
+
+function getWidthOrHeight( elem, name, extra ) {
+
+	// Start with offset property, which is equivalent to the border-box value
+	var valueIsBorderBox = true,
+		val = name === "width" ? elem.offsetWidth : elem.offsetHeight,
+		styles = getStyles( elem ),
+		isBorderBox = support.boxSizing &&
+			jQuery.css( elem, "boxSizing", false, styles ) === "border-box";
+
+	// Support: IE11 only
+	// In IE 11 fullscreen elements inside of an iframe have
+	// 100x too small dimensions (gh-1764).
+	if ( document.msFullscreenElement && window.top !== window ) {
+
+		// Support: IE11 only
+		// Running getBoundingClientRect on a disconnected node
+		// in IE throws an error.
+		if ( elem.getClientRects().length ) {
+			val = Math.round( elem.getBoundingClientRect()[ name ] * 100 );
+		}
+	}
+
+	// some non-html elements return undefined for offsetWidth, so check for null/undefined
+	// svg - https://bugzilla.mozilla.org/show_bug.cgi?id=649285
+	// MathML - https://bugzilla.mozilla.org/show_bug.cgi?id=491668
+	if ( val <= 0 || val == null ) {
+
+		// Fall back to computed then uncomputed css if necessary
+		val = curCSS( elem, name, styles );
+		if ( val < 0 || val == null ) {
+			val = elem.style[ name ];
+		}
+
+		// Computed unit is not pixels. Stop here and return.
+		if ( rnumnonpx.test( val ) ) {
+			return val;
+		}
+
+		// we need the check for style in case a browser which returns unreliable values
+		// for getComputedStyle silently falls back to the reliable elem.style
+		valueIsBorderBox = isBorderBox &&
+			( support.boxSizingReliable() || val === elem.style[ name ] );
+
+		// Normalize "", auto, and prepare for extra
+		val = parseFloat( val ) || 0;
+	}
+
+	// use the active box-sizing model to add/subtract irrelevant styles
+	return ( val +
+		augmentWidthOrHeight(
+			elem,
+			name,
+			extra || ( isBorderBox ? "border" : "content" ),
+			valueIsBorderBox,
+			styles
+		)
+	) + "px";
+}
+
+jQuery.extend( {
+
+	// Add in style property hooks for overriding the default
+	// behavior of getting and setting a style property
+	cssHooks: {
+		opacity: {
+			get: function( elem, computed ) {
+				if ( computed ) {
+
+					// We should always get a number back from opacity
+					var ret = curCSS( elem, "opacity" );
+					return ret === "" ? "1" : ret;
+				}
+			}
+		}
+	},
+
+	// Don't automatically add "px" to these possibly-unitless properties
+	cssNumber: {
+		"animationIterationCount": true,
+		"columnCount": true,
+		"fillOpacity": true,
+		"flexGrow": true,
+		"flexShrink": true,
+		"fontWeight": true,
+		"lineHeight": true,
+		"opacity": true,
+		"order": true,
+		"orphans": true,
+		"widows": true,
+		"zIndex": true,
+		"zoom": true
+	},
+
+	// Add in properties whose names you wish to fix before
+	// setting or getting the value
+	cssProps: {
+
+		// normalize float css property
+		"float": support.cssFloat ? "cssFloat" : "styleFloat"
+	},
+
+	// Get and set the style property on a DOM Node
+	style: function( elem, name, value, extra ) {
+
+		// Don't set styles on text and comment nodes
+		if ( !elem || elem.nodeType === 3 || elem.nodeType === 8 || !elem.style ) {
+			return;
+		}
+
+		// Make sure that we're working with the right name
+		var ret, type, hooks,
+			origName = jQuery.camelCase( name ),
+			style = elem.style;
+
+		name = jQuery.cssProps[ origName ] ||
+			( jQuery.cssProps[ origName ] = vendorPropName( origName ) || origName );
+
+		// gets hook for the prefixed version
+		// followed by the unprefixed version
+		hooks = jQuery.cssHooks[ name ] || jQuery.cssHooks[ origName ];
+
+		// Check if we're setting a value
+		if ( value !== undefined ) {
+			type = typeof value;
+
+			// Convert "+=" or "-=" to relative numbers (#7345)
+			if ( type === "string" && ( ret = rcssNum.exec( value ) ) && ret[ 1 ] ) {
+				value = adjustCSS( elem, name, ret );
+
+				// Fixes bug #9237
+				type = "number";
+			}
+
+			// Make sure that null and NaN values aren't set. See: #7116
+			if ( value == null || value !== value ) {
+				return;
+			}
+
+			// If a number was passed in, add the unit (except for certain CSS properties)
+			if ( type === "number" ) {
+				value += ret && ret[ 3 ] || ( jQuery.cssNumber[ origName ] ? "" : "px" );
+			}
+
+			// Fixes #8908, it can be done more correctly by specifing setters in cssHooks,
+			// but it would mean to define eight
+			// (for every problematic property) identical functions
+			if ( !support.clearCloneStyle && value === "" && name.indexOf( "background" ) === 0 ) {
+				style[ name ] = "inherit";
+			}
+
+			// If a hook was provided, use that value, otherwise just set the specified value
+			if ( !hooks || !( "set" in hooks ) ||
+				( value = hooks.set( elem, value, extra ) ) !== undefined ) {
+
+				// Support: IE
+				// Swallow errors from 'invalid' CSS values (#5509)
+				try {
+					style[ name ] = value;
+				} catch ( e ) {}
+			}
+
+		} else {
+
+			// If a hook was provided get the non-computed value from there
+			if ( hooks && "get" in hooks &&
+				( ret = hooks.get( elem, false, extra ) ) !== undefined ) {
+
+				return ret;
+			}
+
+			// Otherwise just get the value from the style object
+			return style[ name ];
+		}
+	},
+
+	css: function( elem, name, extra, styles ) {
+		var num, val, hooks,
+			origName = jQuery.camelCase( name );
+
+		// Make sure that we're working with the right name
+		name = jQuery.cssProps[ origName ] ||
+			( jQuery.cssProps[ origName ] = vendorPropName( origName ) || origName );
+
+		// gets hook for the prefixed version
+		// followed by the unprefixed version
+		hooks = jQuery.cssHooks[ name ] || jQuery.cssHooks[ origName ];
+
+		// If a hook was provided get the computed value from there
+		if ( hooks && "get" in hooks ) {
+			val = hooks.get( elem, true, extra );
+		}
+
+		// Otherwise, if a way to get the computed value exists, use that
+		if ( val === undefined ) {
+			val = curCSS( elem, name, styles );
+		}
+
+		//convert "normal" to computed value
+		if ( val === "normal" && name in cssNormalTransform ) {
+			val = cssNormalTransform[ name ];
+		}
+
+		// Return, converting to number if forced or a qualifier was provided and val looks numeric
+		if ( extra === "" || extra ) {
+			num = parseFloat( val );
+			return extra === true || isFinite( num ) ? num || 0 : val;
+		}
+		return val;
+	}
+} );
+
+jQuery.each( [ "height", "width" ], function( i, name ) {
+	jQuery.cssHooks[ name ] = {
+		get: function( elem, computed, extra ) {
+			if ( computed ) {
+
+				// certain elements can have dimension info if we invisibly show them
+				// however, it must have a current display style that would benefit from this
+				return rdisplayswap.test( jQuery.css( elem, "display" ) ) &&
+					elem.offsetWidth === 0 ?
+						swap( elem, cssShow, function() {
+							return getWidthOrHeight( elem, name, extra );
+						} ) :
+						getWidthOrHeight( elem, name, extra );
+			}
+		},
+
+		set: function( elem, value, extra ) {
+			var styles = extra && getStyles( elem );
+			return setPositiveNumber( elem, value, extra ?
+				augmentWidthOrHeight(
+					elem,
+					name,
+					extra,
+					support.boxSizing &&
+						jQuery.css( elem, "boxSizing", false, styles ) === "border-box",
+					styles
+				) : 0
+			);
+		}
+	};
+} );
+
+if ( !support.opacity ) {
+	jQuery.cssHooks.opacity = {
+		get: function( elem, computed ) {
+
+			// IE uses filters for opacity
+			return ropacity.test( ( computed && elem.currentStyle ?
+				elem.currentStyle.filter :
+				elem.style.filter ) || "" ) ?
+					( 0.01 * parseFloat( RegExp.$1 ) ) + "" :
+					computed ? "1" : "";
+		},
+
+		set: function( elem, value ) {
+			var style = elem.style,
+				currentStyle = elem.currentStyle,
+				opacity = jQuery.isNumeric( value ) ? "alpha(opacity=" + value * 100 + ")" : "",
+				filter = currentStyle && currentStyle.filter || style.filter || "";
+
+			// IE has trouble with opacity if it does not have layout
+			// Force it by setting the zoom level
+			style.zoom = 1;
+
+			// if setting opacity to 1, and no other filters exist -
+			// attempt to remove filter attribute #6652
+			// if value === "", then remove inline opacity #12685
+			if ( ( value >= 1 || value === "" ) &&
+					jQuery.trim( filter.replace( ralpha, "" ) ) === "" &&
+					style.removeAttribute ) {
+
+				// Setting style.filter to null, "" & " " still leave "filter:" in the cssText
+				// if "filter:" is present at all, clearType is disabled, we want to avoid this
+				// style.removeAttribute is IE Only, but so apparently is this code path...
+				style.removeAttribute( "filter" );
+
+				// if there is no filter style applied in a css rule
+				// or unset inline opacity, we are done
+				if ( value === "" || currentStyle && !currentStyle.filter ) {
+					return;
+				}
+			}
+
+			// otherwise, set new filter values
+			style.filter = ralpha.test( filter ) ?
+				filter.replace( ralpha, opacity ) :
+				filter + " " + opacity;
+		}
+	};
+}
+
+jQuery.cssHooks.marginRight = addGetHookIf( support.reliableMarginRight,
+	function( elem, computed ) {
+		if ( computed ) {
+			return swap( elem, { "display": "inline-block" },
+				curCSS, [ elem, "marginRight" ] );
+		}
+	}
+);
+
+jQuery.cssHooks.marginLeft = addGetHookIf( support.reliableMarginLeft,
+	function( elem, computed ) {
+		if ( computed ) {
+			return (
+				parseFloat( curCSS( elem, "marginLeft" ) ) ||
+
+				// Support: IE<=11+
+				// Running getBoundingClientRect on a disconnected node in IE throws an error
+				// Support: IE8 only
+				// getClientRects() errors on disconnected elems
+				( jQuery.contains( elem.ownerDocument, elem ) ?
+					elem.getBoundingClientRect().left -
+						swap( elem, { marginLeft: 0 }, function() {
+							return elem.getBoundingClientRect().left;
+						} ) :
+					0
+				)
+			) + "px";
+		}
+	}
+);
+
+// These hooks are used by animate to expand properties
+jQuery.each( {
+	margin: "",
+	padding: "",
+	border: "Width"
+}, function( prefix, suffix ) {
+	jQuery.cssHooks[ prefix + suffix ] = {
+		expand: function( value ) {
+			var i = 0,
+				expanded = {},
+
+				// assumes a single number if not a string
+				parts = typeof value === "string" ? value.split( " " ) : [ value ];
+
+			for ( ; i < 4; i++ ) {
+				expanded[ prefix + cssExpand[ i ] + suffix ] =
+					parts[ i ] || parts[ i - 2 ] || parts[ 0 ];
+			}
+
+			return expanded;
+		}
+	};
+
+	if ( !rmargin.test( prefix ) ) {
+		jQuery.cssHooks[ prefix + suffix ].set = setPositiveNumber;
+	}
+} );
+
+jQuery.fn.extend( {
+	css: function( name, value ) {
+		return access( this, function( elem, name, value ) {
+			var styles, len,
+				map = {},
+				i = 0;
+
+			if ( jQuery.isArray( name ) ) {
+				styles = getStyles( elem );
+				len = name.length;
+
+				for ( ; i < len; i++ ) {
+					map[ name[ i ] ] = jQuery.css( elem, name[ i ], false, styles );
+				}
+
+				return map;
+			}
+
+			return value !== undefined ?
+				jQuery.style( elem, name, value ) :
+				jQuery.css( elem, name );
+		}, name, value, arguments.length > 1 );
+	},
+	show: function() {
+		return showHide( this, true );
+	},
+	hide: function() {
+		return showHide( this );
+	},
+	toggle: function( state ) {
+		if ( typeof state === "boolean" ) {
+			return state ? this.show() : this.hide();
+		}
+
+		return this.each( function() {
+			if ( isHidden( this ) ) {
+				jQuery( this ).show();
+			} else {
+				jQuery( this ).hide();
+			}
+		} );
+	}
+} );
+
+
+function Tween( elem, options, prop, end, easing ) {
+	return new Tween.prototype.init( elem, options, prop, end, easing );
+}
+jQuery.Tween = Tween;
+
+Tween.prototype = {
+	constructor: Tween,
+	init: function( elem, options, prop, end, easing, unit ) {
+		this.elem = elem;
+		this.prop = prop;
+		this.easing = easing || jQuery.easing._default;
+		this.options = options;
+		this.start = this.now = this.cur();
+		this.end = end;
+		this.unit = unit || ( jQuery.cssNumber[ prop ] ? "" : "px" );
+	},
+	cur: function() {
+		var hooks = Tween.propHooks[ this.prop ];
+
+		return hooks && hooks.get ?
+			hooks.get( this ) :
+			Tween.propHooks._default.get( this );
+	},
+	run: function( percent ) {
+		var eased,
+			hooks = Tween.propHooks[ this.prop ];
+
+		if ( this.options.duration ) {
+			this.pos = eased = jQuery.easing[ this.easing ](
+				percent, this.options.duration * percent, 0, 1, this.options.duration
+			);
+		} else {
+			this.pos = eased = percent;
+		}
+		this.now = ( this.end - this.start ) * eased + this.start;
+
+		if ( this.options.step ) {
+			this.options.step.call( this.elem, this.now, this );
+		}
+
+		if ( hooks && hooks.set ) {
+			hooks.set( this );
+		} else {
+			Tween.propHooks._default.set( this );
+		}
+		return this;
+	}
+};
+
+Tween.prototype.init.prototype = Tween.prototype;
+
+Tween.propHooks = {
+	_default: {
+		get: function( tween ) {
+			var result;
+
+			// Use a property on the element directly when it is not a DOM element,
+			// or when there is no matching style property that exists.
+			if ( tween.elem.nodeType !== 1 ||
+				tween.elem[ tween.prop ] != null && tween.elem.style[ tween.prop ] == null ) {
+				return tween.elem[ tween.prop ];
+			}
+
+			// passing an empty string as a 3rd parameter to .css will automatically
+			// attempt a parseFloat and fallback to a string if the parse fails
+			// so, simple values such as "10px" are parsed to Float.
+			// complex values such as "rotate(1rad)" are returned as is.
+			result = jQuery.css( tween.elem, tween.prop, "" );
+
+			// Empty strings, null, undefined and "auto" are converted to 0.
+			return !result || result === "auto" ? 0 : result;
+		},
+		set: function( tween ) {
+
+			// use step hook for back compat - use cssHook if its there - use .style if its
+			// available and use plain properties where available
+			if ( jQuery.fx.step[ tween.prop ] ) {
+				jQuery.fx.step[ tween.prop ]( tween );
+			} else if ( tween.elem.nodeType === 1 &&
+				( tween.elem.style[ jQuery.cssProps[ tween.prop ] ] != null ||
+					jQuery.cssHooks[ tween.prop ] ) ) {
+				jQuery.style( tween.elem, tween.prop, tween.now + tween.unit );
+			} else {
+				tween.elem[ tween.prop ] = tween.now;
+			}
+		}
+	}
+};
+
+// Support: IE <=9
+// Panic based approach to setting things on disconnected nodes
+
+Tween.propHooks.scrollTop = Tween.propHooks.scrollLeft = {
+	set: function( tween ) {
+		if ( tween.elem.nodeType && tween.elem.parentNode ) {
+			tween.elem[ tween.prop ] = tween.now;
+		}
+	}
+};
+
+jQuery.easing = {
+	linear: function( p ) {
+		return p;
+	},
+	swing: function( p ) {
+		return 0.5 - Math.cos( p * Math.PI ) / 2;
+	},
+	_default: "swing"
+};
+
+jQuery.fx = Tween.prototype.init;
+
+// Back Compat <1.8 extension point
+jQuery.fx.step = {};
+
+
+
+
+var
+	fxNow, timerId,
+	rfxtypes = /^(?:toggle|show|hide)$/,
+	rrun = /queueHooks$/;
+
+// Animations created synchronously will run synchronously
+function createFxNow() {
+	window.setTimeout( function() {
+		fxNow = undefined;
+	} );
+	return ( fxNow = jQuery.now() );
+}
+
+// Generate parameters to create a standard animation
+function genFx( type, includeWidth ) {
+	var which,
+		attrs = { height: type },
+		i = 0;
+
+	// if we include width, step value is 1 to do all cssExpand values,
+	// if we don't include width, step value is 2 to skip over Left and Right
+	includeWidth = includeWidth ? 1 : 0;
+	for ( ; i < 4 ; i += 2 - includeWidth ) {
+		which = cssExpand[ i ];
+		attrs[ "margin" + which ] = attrs[ "padding" + which ] = type;
+	}
+
+	if ( includeWidth ) {
+		attrs.opacity = attrs.width = type;
+	}
+
+	return attrs;
+}
+
+function createTween( value, prop, animation ) {
+	var tween,
+		collection = ( Animation.tweeners[ prop ] || [] ).concat( Animation.tweeners[ "*" ] ),
+		index = 0,
+		length = collection.length;
+	for ( ; index < length; index++ ) {
+		if ( ( tween = collection[ index ].call( animation, prop, value ) ) ) {
+
+			// we're done with this property
+			return tween;
+		}
+	}
+}
+
+function defaultPrefilter( elem, props, opts ) {
+	/* jshint validthis: true */
+	var prop, value, toggle, tween, hooks, oldfire, display, checkDisplay,
+		anim = this,
+		orig = {},
+		style = elem.style,
+		hidden = elem.nodeType && isHidden( elem ),
+		dataShow = jQuery._data( elem, "fxshow" );
+
+	// handle queue: false promises
+	if ( !opts.queue ) {
+		hooks = jQuery._queueHooks( elem, "fx" );
+		if ( hooks.unqueued == null ) {
+			hooks.unqueued = 0;
+			oldfire = hooks.empty.fire;
+			hooks.empty.fire = function() {
+				if ( !hooks.unqueued ) {
+					oldfire();
+				}
+			};
+		}
+		hooks.unqueued++;
+
+		anim.always( function() {
+
+			// doing this makes sure that the complete handler will be called
+			// before this completes
+			anim.always( function() {
+				hooks.unqueued--;
+				if ( !jQuery.queue( elem, "fx" ).length ) {
+					hooks.empty.fire();
+				}
+			} );
+		} );
+	}
+
+	// height/width overflow pass
+	if ( elem.nodeType === 1 && ( "height" in props || "width" in props ) ) {
+
+		// Make sure that nothing sneaks out
+		// Record all 3 overflow attributes because IE does not
+		// change the overflow attribute when overflowX and
+		// overflowY are set to the same value
+		opts.overflow = [ style.overflow, style.overflowX, style.overflowY ];
+
+		// Set display property to inline-block for height/width
+		// animations on inline elements that are having width/height animated
+		display = jQuery.css( elem, "display" );
+
+		// Test default display if display is currently "none"
+		checkDisplay = display === "none" ?
+			jQuery._data( elem, "olddisplay" ) || defaultDisplay( elem.nodeName ) : display;
+
+		if ( checkDisplay === "inline" && jQuery.css( elem, "float" ) === "none" ) {
+
+			// inline-level elements accept inline-block;
+			// block-level elements need to be inline with layout
+			if ( !support.inlineBlockNeedsLayout || defaultDisplay( elem.nodeName ) === "inline" ) {
+				style.display = "inline-block";
+			} else {
+				style.zoom = 1;
+			}
+		}
+	}
+
+	if ( opts.overflow ) {
+		style.overflow = "hidden";
+		if ( !support.shrinkWrapBlocks() ) {
+			anim.always( function() {
+				style.overflow = opts.overflow[ 0 ];
+				style.overflowX = opts.overflow[ 1 ];
+				style.overflowY = opts.overflow[ 2 ];
+			} );
+		}
+	}
+
+	// show/hide pass
+	for ( prop in props ) {
+		value = props[ prop ];
+		if ( rfxtypes.exec( value ) ) {
+			delete props[ prop ];
+			toggle = toggle || value === "toggle";
+			if ( value === ( hidden ? "hide" : "show" ) ) {
+
+				// If there is dataShow left over from a stopped hide or show
+				// and we are going to proceed with show, we should pretend to be hidden
+				if ( value === "show" && dataShow && dataShow[ prop ] !== undefined ) {
+					hidden = true;
+				} else {
+					continue;
+				}
+			}
+			orig[ prop ] = dataShow && dataShow[ prop ] || jQuery.style( elem, prop );
+
+		// Any non-fx value stops us from restoring the original display value
+		} else {
+			display = undefined;
+		}
+	}
+
+	if ( !jQuery.isEmptyObject( orig ) ) {
+		if ( dataShow ) {
+			if ( "hidden" in dataShow ) {
+				hidden = dataShow.hidden;
+			}
+		} else {
+			dataShow = jQuery._data( elem, "fxshow", {} );
+		}
+
+		// store state if its toggle - enables .stop().toggle() to "reverse"
+		if ( toggle ) {
+			dataShow.hidden = !hidden;
+		}
+		if ( hidden ) {
+			jQuery( elem ).show();
+		} else {
+			anim.done( function() {
+				jQuery( elem ).hide();
+			} );
+		}
+		anim.done( function() {
+			var prop;
+			jQuery._removeData( elem, "fxshow" );
+			for ( prop in orig ) {
+				jQuery.style( elem, prop, orig[ prop ] );
+			}
+		} );
+		for ( prop in orig ) {
+			tween = createTween( hidden ? dataShow[ prop ] : 0, prop, anim );
+
+			if ( !( prop in dataShow ) ) {
+				dataShow[ prop ] = tween.start;
+				if ( hidden ) {
+					tween.end = tween.start;
+					tween.start = prop === "width" || prop === "height" ? 1 : 0;
+				}
+			}
+		}
+
+	// If this is a noop like .hide().hide(), restore an overwritten display value
+	} else if ( ( display === "none" ? defaultDisplay( elem.nodeName ) : display ) === "inline" ) {
+		style.display = display;
+	}
+}
+
+function propFilter( props, specialEasing ) {
+	var index, name, easing, value, hooks;
+
+	// camelCase, specialEasing and expand cssHook pass
+	for ( index in props ) {
+		name = jQuery.camelCase( index );
+		easing = specialEasing[ name ];
+		value = props[ index ];
+		if ( jQuery.isArray( value ) ) {
+			easing = value[ 1 ];
+			value = props[ index ] = value[ 0 ];
+		}
+
+		if ( index !== name ) {
+			props[ name ] = value;
+			delete props[ index ];
+		}
+
+		hooks = jQuery.cssHooks[ name ];
+		if ( hooks && "expand" in hooks ) {
+			value = hooks.expand( value );
+			delete props[ name ];
+
+			// not quite $.extend, this wont overwrite keys already present.
+			// also - reusing 'index' from above because we have the correct "name"
+			for ( index in value ) {
+				if ( !( index in props ) ) {
+					props[ index ] = value[ index ];
+					specialEasing[ index ] = easing;
+				}
+			}
+		} else {
+			specialEasing[ name ] = easing;
+		}
+	}
+}
+
+function Animation( elem, properties, options ) {
+	var result,
+		stopped,
+		index = 0,
+		length = Animation.prefilters.length,
+		deferred = jQuery.Deferred().always( function() {
+
+			// don't match elem in the :animated selector
+			delete tick.elem;
+		} ),
+		tick = function() {
+			if ( stopped ) {
+				return false;
+			}
+			var currentTime = fxNow || createFxNow(),
+				remaining = Math.max( 0, animation.startTime + animation.duration - currentTime ),
+
+				// Support: Android 2.3
+				// Archaic crash bug won't allow us to use `1 - ( 0.5 || 0 )` (#12497)
+				temp = remaining / animation.duration || 0,
+				percent = 1 - temp,
+				index = 0,
+				length = animation.tweens.length;
+
+			for ( ; index < length ; index++ ) {
+				animation.tweens[ index ].run( percent );
+			}
+
+			deferred.notifyWith( elem, [ animation, percent, remaining ] );
+
+			if ( percent < 1 && length ) {
+				return remaining;
+			} else {
+				deferred.resolveWith( elem, [ animation ] );
+				return false;
+			}
+		},
+		animation = deferred.promise( {
+			elem: elem,
+			props: jQuery.extend( {}, properties ),
+			opts: jQuery.extend( true, {
+				specialEasing: {},
+				easing: jQuery.easing._default
+			}, options ),
+			originalProperties: properties,
+			originalOptions: options,
+			startTime: fxNow || createFxNow(),
+			duration: options.duration,
+			tweens: [],
+			createTween: function( prop, end ) {
+				var tween = jQuery.Tween( elem, animation.opts, prop, end,
+						animation.opts.specialEasing[ prop ] || animation.opts.easing );
+				animation.tweens.push( tween );
+				return tween;
+			},
+			stop: function( gotoEnd ) {
+				var index = 0,
+
+					// if we are going to the end, we want to run all the tweens
+					// otherwise we skip this part
+					length = gotoEnd ? animation.tweens.length : 0;
+				if ( stopped ) {
+					return this;
+				}
+				stopped = true;
+				for ( ; index < length ; index++ ) {
+					animation.tweens[ index ].run( 1 );
+				}
+
+				// resolve when we played the last frame
+				// otherwise, reject
+				if ( gotoEnd ) {
+					deferred.notifyWith( elem, [ animation, 1, 0 ] );
+					deferred.resolveWith( elem, [ animation, gotoEnd ] );
+				} else {
+					deferred.rejectWith( elem, [ animation, gotoEnd ] );
+				}
+				return this;
+			}
+		} ),
+		props = animation.props;
+
+	propFilter( props, animation.opts.specialEasing );
+
+	for ( ; index < length ; index++ ) {
+		result = Animation.prefilters[ index ].call( animation, elem, props, animation.opts );
+		if ( result ) {
+			if ( jQuery.isFunction( result.stop ) ) {
+				jQuery._queueHooks( animation.elem, animation.opts.queue ).stop =
+					jQuery.proxy( result.stop, result );
+			}
+			return result;
+		}
+	}
+
+	jQuery.map( props, createTween, animation );
+
+	if ( jQuery.isFunction( animation.opts.start ) ) {
+		animation.opts.start.call( elem, animation );
+	}
+
+	jQuery.fx.timer(
+		jQuery.extend( tick, {
+			elem: elem,
+			anim: animation,
+			queue: animation.opts.queue
+		} )
+	);
+
+	// attach callbacks from options
+	return animation.progress( animation.opts.progress )
+		.done( animation.opts.done, animation.opts.complete )
+		.fail( animation.opts.fail )
+		.always( animation.opts.always );
+}
+
+jQuery.Animation = jQuery.extend( Animation, {
+
+	tweeners: {
+		"*": [ function( prop, value ) {
+			var tween = this.createTween( prop, value );
+			adjustCSS( tween.elem, prop, rcssNum.exec( value ), tween );
+			return tween;
+		} ]
+	},
+
+	tweener: function( props, callback ) {
+		if ( jQuery.isFunction( props ) ) {
+			callback = props;
+			props = [ "*" ];
+		} else {
+			props = props.match( rnotwhite );
+		}
+
+		var prop,
+			index = 0,
+			length = props.length;
+
+		for ( ; index < length ; index++ ) {
+			prop = props[ index ];
+			Animation.tweeners[ prop ] = Animation.tweeners[ prop ] || [];
+			Animation.tweeners[ prop ].unshift( callback );
+		}
+	},
+
+	prefilters: [ defaultPrefilter ],
+
+	prefilter: function( callback, prepend ) {
+		if ( prepend ) {
+			Animation.prefilters.unshift( callback );
+		} else {
+			Animation.prefilters.push( callback );
+		}
+	}
+} );
+
+jQuery.speed = function( speed, easing, fn ) {
+	var opt = speed && typeof speed === "object" ? jQuery.extend( {}, speed ) : {
+		complete: fn || !fn && easing ||
+			jQuery.isFunction( speed ) && speed,
+		duration: speed,
+		easing: fn && easing || easing && !jQuery.isFunction( easing ) && easing
+	};
+
+	opt.duration = jQuery.fx.off ? 0 : typeof opt.duration === "number" ? opt.duration :
+		opt.duration in jQuery.fx.speeds ?
+			jQuery.fx.speeds[ opt.duration ] : jQuery.fx.speeds._default;
+
+	// normalize opt.queue - true/undefined/null -> "fx"
+	if ( opt.queue == null || opt.queue === true ) {
+		opt.queue = "fx";
+	}
+
+	// Queueing
+	opt.old = opt.complete;
+
+	opt.complete = function() {
+		if ( jQuery.isFunction( opt.old ) ) {
+			opt.old.call( this );
+		}
+
+		if ( opt.queue ) {
+			jQuery.dequeue( this, opt.queue );
+		}
+	};
+
+	return opt;
+};
+
+jQuery.fn.extend( {
+	fadeTo: function( speed, to, easing, callback ) {
+
+		// show any hidden elements after setting opacity to 0
+		return this.filter( isHidden ).css( "opacity", 0 ).show()
+
+			// animate to the value specified
+			.end().animate( { opacity: to }, speed, easing, callback );
+	},
+	animate: function( prop, speed, easing, callback ) {
+		var empty = jQuery.isEmptyObject( prop ),
+			optall = jQuery.speed( speed, easing, callback ),
+			doAnimation = function() {
+
+				// Operate on a copy of prop so per-property easing won't be lost
+				var anim = Animation( this, jQuery.extend( {}, prop ), optall );
+
+				// Empty animations, or finishing resolves immediately
+				if ( empty || jQuery._data( this, "finish" ) ) {
+					anim.stop( true );
+				}
+			};
+			doAnimation.finish = doAnimation;
+
+		return empty || optall.queue === false ?
+			this.each( doAnimation ) :
+			this.queue( optall.queue, doAnimation );
+	},
+	stop: function( type, clearQueue, gotoEnd ) {
+		var stopQueue = function( hooks ) {
+			var stop = hooks.stop;
+			delete hooks.stop;
+			stop( gotoEnd );
+		};
+
+		if ( typeof type !== "string" ) {
+			gotoEnd = clearQueue;
+			clearQueue = type;
+			type = undefined;
+		}
+		if ( clearQueue && type !== false ) {
+			this.queue( type || "fx", [] );
+		}
+
+		return this.each( function() {
+			var dequeue = true,
+				index = type != null && type + "queueHooks",
+				timers = jQuery.timers,
+				data = jQuery._data( this );
+
+			if ( index ) {
+				if ( data[ index ] && data[ index ].stop ) {
+					stopQueue( data[ index ] );
+				}
+			} else {
+				for ( index in data ) {
+					if ( data[ index ] && data[ index ].stop && rrun.test( index ) ) {
+						stopQueue( data[ index ] );
+					}
+				}
+			}
+
+			for ( index = timers.length; index--; ) {
+				if ( timers[ index ].elem === this &&
+					( type == null || timers[ index ].queue === type ) ) {
+
+					timers[ index ].anim.stop( gotoEnd );
+					dequeue = false;
+					timers.splice( index, 1 );
+				}
+			}
+
+			// start the next in the queue if the last step wasn't forced
+			// timers currently will call their complete callbacks, which will dequeue
+			// but only if they were gotoEnd
+			if ( dequeue || !gotoEnd ) {
+				jQuery.dequeue( this, type );
+			}
+		} );
+	},
+	finish: function( type ) {
+		if ( type !== false ) {
+			type = type || "fx";
+		}
+		return this.each( function() {
+			var index,
+				data = jQuery._data( this ),
+				queue = data[ type + "queue" ],
+				hooks = data[ type + "queueHooks" ],
+				timers = jQuery.timers,
+				length = queue ? queue.length : 0;
+
+			// enable finishing flag on private data
+			data.finish = true;
+
+			// empty the queue first
+			jQuery.queue( this, type, [] );
+
+			if ( hooks && hooks.stop ) {
+				hooks.stop.call( this, true );
+			}
+
+			// look for any active animations, and finish them
+			for ( index = timers.length; index--; ) {
+				if ( timers[ index ].elem === this && timers[ index ].queue === type ) {
+					timers[ index ].anim.stop( true );
+					timers.splice( index, 1 );
+				}
+			}
+
+			// look for any animations in the old queue and finish them
+			for ( index = 0; index < length; index++ ) {
+				if ( queue[ index ] && queue[ index ].finish ) {
+					queue[ index ].finish.call( this );
+				}
+			}
+
+			// turn off finishing flag
+			delete data.finish;
+		} );
+	}
+} );
+
+jQuery.each( [ "toggle", "show", "hide" ], function( i, name ) {
+	var cssFn = jQuery.fn[ name ];
+	jQuery.fn[ name ] = function( speed, easing, callback ) {
+		return speed == null || typeof speed === "boolean" ?
+			cssFn.apply( this, arguments ) :
+			this.animate( genFx( name, true ), speed, easing, callback );
+	};
+} );
+
+// Generate shortcuts for custom animations
+jQuery.each( {
+	slideDown: genFx( "show" ),
+	slideUp: genFx( "hide" ),
+	slideToggle: genFx( "toggle" ),
+	fadeIn: { opacity: "show" },
+	fadeOut: { opacity: "hide" },
+	fadeToggle: { opacity: "toggle" }
+}, function( name, props ) {
+	jQuery.fn[ name ] = function( speed, easing, callback ) {
+		return this.animate( props, speed, easing, callback );
+	};
+} );
+
+jQuery.timers = [];
+jQuery.fx.tick = function() {
+	var timer,
+		timers = jQuery.timers,
+		i = 0;
+
+	fxNow = jQuery.now();
+
+	for ( ; i < timers.length; i++ ) {
+		timer = timers[ i ];
+
+		// Checks the timer has not already been removed
+		if ( !timer() && timers[ i ] === timer ) {
+			timers.splice( i--, 1 );
+		}
+	}
+
+	if ( !timers.length ) {
+		jQuery.fx.stop();
+	}
+	fxNow = undefined;
+};
+
+jQuery.fx.timer = function( timer ) {
+	jQuery.timers.push( timer );
+	if ( timer() ) {
+		jQuery.fx.start();
+	} else {
+		jQuery.timers.pop();
+	}
+};
+
+jQuery.fx.interval = 13;
+
+jQuery.fx.start = function() {
+	if ( !timerId ) {
+		timerId = window.setInterval( jQuery.fx.tick, jQuery.fx.interval );
+	}
+};
+
+jQuery.fx.stop = function() {
+	window.clearInterval( timerId );
+	timerId = null;
+};
+
+jQuery.fx.speeds = {
+	slow: 600,
+	fast: 200,
+
+	// Default speed
+	_default: 400
+};
+
+
+// Based off of the plugin by Clint Helfers, with permission.
+// http://web.archive.org/web/20100324014747/http://blindsignals.com/index.php/2009/07/jquery-delay/
+jQuery.fn.delay = function( time, type ) {
+	time = jQuery.fx ? jQuery.fx.speeds[ time ] || time : time;
+	type = type || "fx";
+
+	return this.queue( type, function( next, hooks ) {
+		var timeout = window.setTimeout( next, time );
+		hooks.stop = function() {
+			window.clearTimeout( timeout );
+		};
+	} );
+};
+
+
+( function() {
+	var a,
+		input = document.createElement( "input" ),
+		div = document.createElement( "div" ),
+		select = document.createElement( "select" ),
+		opt = select.appendChild( document.createElement( "option" ) );
+
+	// Setup
+	div = document.createElement( "div" );
+	div.setAttribute( "className", "t" );
+	div.innerHTML = "  <link/><table></table><a href='/a'>a</a><input type='checkbox'/>";
+	a = div.getElementsByTagName( "a" )[ 0 ];
+
+	// Support: Windows Web Apps (WWA)
+	// `type` must use .setAttribute for WWA (#14901)
+	input.setAttribute( "type", "checkbox" );
+	div.appendChild( input );
+
+	a = div.getElementsByTagName( "a" )[ 0 ];
+
+	// First batch of tests.
+	a.style.cssText = "top:1px";
+
+	// Test setAttribute on camelCase class.
+	// If it works, we need attrFixes when doing get/setAttribute (ie6/7)
+	support.getSetAttribute = div.className !== "t";
+
+	// Get the style information from getAttribute
+	// (IE uses .cssText instead)
+	support.style = /top/.test( a.getAttribute( "style" ) );
+
+	// Make sure that URLs aren't manipulated
+	// (IE normalizes it by default)
+	support.hrefNormalized = a.getAttribute( "href" ) === "/a";
+
+	// Check the default checkbox/radio value ("" on WebKit; "on" elsewhere)
+	support.checkOn = !!input.value;
+
+	// Make sure that a selected-by-default option has a working selected property.
+	// (WebKit defaults to false instead of true, IE too, if it's in an optgroup)
+	support.optSelected = opt.selected;
+
+	// Tests for enctype support on a form (#6743)
+	support.enctype = !!document.createElement( "form" ).enctype;
+
+	// Make sure that the options inside disabled selects aren't marked as disabled
+	// (WebKit marks them as disabled)
+	select.disabled = true;
+	support.optDisabled = !opt.disabled;
+
+	// Support: IE8 only
+	// Check if we can trust getAttribute("value")
+	input = document.createElement( "input" );
+	input.setAttribute( "value", "" );
+	support.input = input.getAttribute( "value" ) === "";
+
+	// Check if an input maintains its value after becoming a radio
+	input.value = "t";
+	input.setAttribute( "type", "radio" );
+	support.radioValue = input.value === "t";
+} )();
+
+
+var rreturn = /\r/g;
+
+jQuery.fn.extend( {
+	val: function( value ) {
+		var hooks, ret, isFunction,
+			elem = this[ 0 ];
+
+		if ( !arguments.length ) {
+			if ( elem ) {
+				hooks = jQuery.valHooks[ elem.type ] ||
+					jQuery.valHooks[ elem.nodeName.toLowerCase() ];
+
+				if (
+					hooks &&
+					"get" in hooks &&
+					( ret = hooks.get( elem, "value" ) ) !== undefined
+				) {
+					return ret;
+				}
+
+				ret = elem.value;
+
+				return typeof ret === "string" ?
+
+					// handle most common string cases
+					ret.replace( rreturn, "" ) :
+
+					// handle cases where value is null/undef or number
+					ret == null ? "" : ret;
+			}
+
+			return;
+		}
+
+		isFunction = jQuery.isFunction( value );
+
+		return this.each( function( i ) {
+			var val;
+
+			if ( this.nodeType !== 1 ) {
+				return;
+			}
+
+			if ( isFunction ) {
+				val = value.call( this, i, jQuery( this ).val() );
+			} else {
+				val = value;
+			}
+
+			// Treat null/undefined as ""; convert numbers to string
+			if ( val == null ) {
+				val = "";
+			} else if ( typeof val === "number" ) {
+				val += "";
+			} else if ( jQuery.isArray( val ) ) {
+				val = jQuery.map( val, function( value ) {
+					return value == null ? "" : value + "";
+				} );
+			}
+
+			hooks = jQuery.valHooks[ this.type ] || jQuery.valHooks[ this.nodeName.toLowerCase() ];
+
+			// If set returns undefined, fall back to normal setting
+			if ( !hooks || !( "set" in hooks ) || hooks.set( this, val, "value" ) === undefined ) {
+				this.value = val;
+			}
+		} );
+	}
+} );
+
+jQuery.extend( {
+	valHooks: {
+		option: {
+			get: function( elem ) {
+				var val = jQuery.find.attr( elem, "value" );
+				return val != null ?
+					val :
+
+					// Support: IE10-11+
+					// option.text throws exceptions (#14686, #14858)
+					jQuery.trim( jQuery.text( elem ) );
+			}
+		},
+		select: {
+			get: function( elem ) {
+				var value, option,
+					options = elem.options,
+					index = elem.selectedIndex,
+					one = elem.type === "select-one" || index < 0,
+					values = one ? null : [],
+					max = one ? index + 1 : options.length,
+					i = index < 0 ?
+						max :
+						one ? index : 0;
+
+				// Loop through all the selected options
+				for ( ; i < max; i++ ) {
+					option = options[ i ];
+
+					// oldIE doesn't update selected after form reset (#2551)
+					if ( ( option.selected || i === index ) &&
+
+							// Don't return options that are disabled or in a disabled optgroup
+							( support.optDisabled ?
+								!option.disabled :
+								option.getAttribute( "disabled" ) === null ) &&
+							( !option.parentNode.disabled ||
+								!jQuery.nodeName( option.parentNode, "optgroup" ) ) ) {
+
+						// Get the specific value for the option
+						value = jQuery( option ).val();
+
+						// We don't need an array for one selects
+						if ( one ) {
+							return value;
+						}
+
+						// Multi-Selects return an array
+						values.push( value );
+					}
+				}
+
+				return values;
+			},
+
+			set: function( elem, value ) {
+				var optionSet, option,
+					options = elem.options,
+					values = jQuery.makeArray( value ),
+					i = options.length;
+
+				while ( i-- ) {
+					option = options[ i ];
+
+					if ( jQuery.inArray( jQuery.valHooks.option.get( option ), values ) >= 0 ) {
+
+						// Support: IE6
+						// When new option element is added to select box we need to
+						// force reflow of newly added node in order to workaround delay
+						// of initialization properties
+						try {
+							option.selected = optionSet = true;
+
+						} catch ( _ ) {
+
+							// Will be executed only in IE6
+							option.scrollHeight;
+						}
+
+					} else {
+						option.selected = false;
+					}
+				}
+
+				// Force browsers to behave consistently when non-matching value is set
+				if ( !optionSet ) {
+					elem.selectedIndex = -1;
+				}
+
+				return options;
+			}
+		}
+	}
+} );
+
+// Radios and checkboxes getter/setter
+jQuery.each( [ "radio", "checkbox" ], function() {
+	jQuery.valHooks[ this ] = {
+		set: function( elem, value ) {
+			if ( jQuery.isArray( value ) ) {
+				return ( elem.checked = jQuery.inArray( jQuery( elem ).val(), value ) > -1 );
+			}
+		}
+	};
+	if ( !support.checkOn ) {
+		jQuery.valHooks[ this ].get = function( elem ) {
+			return elem.getAttribute( "value" ) === null ? "on" : elem.value;
+		};
+	}
+} );
+
+
+
+
+var nodeHook, boolHook,
+	attrHandle = jQuery.expr.attrHandle,
+	ruseDefault = /^(?:checked|selected)$/i,
+	getSetAttribute = support.getSetAttribute,
+	getSetInput = support.input;
+
+jQuery.fn.extend( {
+	attr: function( name, value ) {
+		return access( this, jQuery.attr, name, value, arguments.length > 1 );
+	},
+
+	removeAttr: function( name ) {
+		return this.each( function() {
+			jQuery.removeAttr( this, name );
+		} );
+	}
+} );
+
+jQuery.extend( {
+	attr: function( elem, name, value ) {
+		var ret, hooks,
+			nType = elem.nodeType;
+
+		// Don't get/set attributes on text, comment and attribute nodes
+		if ( nType === 3 || nType === 8 || nType === 2 ) {
+			return;
+		}
+
+		// Fallback to prop when attributes are not supported
+		if ( typeof elem.getAttribute === "undefined" ) {
+			return jQuery.prop( elem, name, value );
+		}
+
+		// All attributes are lowercase
+		// Grab necessary hook if one is defined
+		if ( nType !== 1 || !jQuery.isXMLDoc( elem ) ) {
+			name = name.toLowerCase();
+			hooks = jQuery.attrHooks[ name ] ||
+				( jQuery.expr.match.bool.test( name ) ? boolHook : nodeHook );
+		}
+
+		if ( value !== undefined ) {
+			if ( value === null ) {
+				jQuery.removeAttr( elem, name );
+				return;
+			}
+
+			if ( hooks && "set" in hooks &&
+				( ret = hooks.set( elem, value, name ) ) !== undefined ) {
+				return ret;
+			}
+
+			elem.setAttribute( name, value + "" );
+			return value;
+		}
+
+		if ( hooks && "get" in hooks && ( ret = hooks.get( elem, name ) ) !== null ) {
+			return ret;
+		}
+
+		ret = jQuery.find.attr( elem, name );
+
+		// Non-existent attributes return null, we normalize to undefined
+		return ret == null ? undefined : ret;
+	},
+
+	attrHooks: {
+		type: {
+			set: function( elem, value ) {
+				if ( !support.radioValue && value === "radio" &&
+					jQuery.nodeName( elem, "input" ) ) {
+
+					// Setting the type on a radio button after the value resets the value in IE8-9
+					// Reset value to default in case type is set after value during creation
+					var val = elem.value;
+					elem.setAttribute( "type", value );
+					if ( val ) {
+						elem.value = val;
+					}
+					return value;
+				}
+			}
+		}
+	},
+
+	removeAttr: function( elem, value ) {
+		var name, propName,
+			i = 0,
+			attrNames = value && value.match( rnotwhite );
+
+		if ( attrNames && elem.nodeType === 1 ) {
+			while ( ( name = attrNames[ i++ ] ) ) {
+				propName = jQuery.propFix[ name ] || name;
+
+				// Boolean attributes get special treatment (#10870)
+				if ( jQuery.expr.match.bool.test( name ) ) {
+
+					// Set corresponding property to false
+					if ( getSetInput && getSetAttribute || !ruseDefault.test( name ) ) {
+						elem[ propName ] = false;
+
+					// Support: IE<9
+					// Also clear defaultChecked/defaultSelected (if appropriate)
+					} else {
+						elem[ jQuery.camelCase( "default-" + name ) ] =
+							elem[ propName ] = false;
+					}
+
+				// See #9699 for explanation of this approach (setting first, then removal)
+				} else {
+					jQuery.attr( elem, name, "" );
+				}
+
+				elem.removeAttribute( getSetAttribute ? name : propName );
+			}
+		}
+	}
+} );
+
+// Hooks for boolean attributes
+boolHook = {
+	set: function( elem, value, name ) {
+		if ( value === false ) {
+
+			// Remove boolean attributes when set to false
+			jQuery.removeAttr( elem, name );
+		} else if ( getSetInput && getSetAttribute || !ruseDefault.test( name ) ) {
+
+			// IE<8 needs the *property* name
+			elem.setAttribute( !getSetAttribute && jQuery.propFix[ name ] || name, name );
+
+		} else {
+
+			// Support: IE<9
+			// Use defaultChecked and defaultSelected for oldIE
+			elem[ jQuery.camelCase( "default-" + name ) ] = elem[ name ] = true;
+		}
+		return name;
+	}
+};
+
+jQuery.each( jQuery.expr.match.bool.source.match( /\w+/g ), function( i, name ) {
+	var getter = attrHandle[ name ] || jQuery.find.attr;
+
+	if ( getSetInput && getSetAttribute || !ruseDefault.test( name ) ) {
+		attrHandle[ name ] = function( elem, name, isXML ) {
+			var ret, handle;
+			if ( !isXML ) {
+
+				// Avoid an infinite loop by temporarily removing this function from the getter
+				handle = attrHandle[ name ];
+				attrHandle[ name ] = ret;
+				ret = getter( elem, name, isXML ) != null ?
+					name.toLowerCase() :
+					null;
+				attrHandle[ name ] = handle;
+			}
+			return ret;
+		};
+	} else {
+		attrHandle[ name ] = function( elem, name, isXML ) {
+			if ( !isXML ) {
+				return elem[ jQuery.camelCase( "default-" + name ) ] ?
+					name.toLowerCase() :
+					null;
+			}
+		};
+	}
+} );
+
+// fix oldIE attroperties
+if ( !getSetInput || !getSetAttribute ) {
+	jQuery.attrHooks.value = {
+		set: function( elem, value, name ) {
+			if ( jQuery.nodeName( elem, "input" ) ) {
+
+				// Does not return so that setAttribute is also used
+				elem.defaultValue = value;
+			} else {
+
+				// Use nodeHook if defined (#1954); otherwise setAttribute is fine
+				return nodeHook && nodeHook.set( elem, value, name );
+			}
+		}
+	};
+}
+
+// IE6/7 do not support getting/setting some attributes with get/setAttribute
+if ( !getSetAttribute ) {
+
+	// Use this for any attribute in IE6/7
+	// This fixes almost every IE6/7 issue
+	nodeHook = {
+		set: function( elem, value, name ) {
+
+			// Set the existing or create a new attribute node
+			var ret = elem.getAttributeNode( name );
+			if ( !ret ) {
+				elem.setAttributeNode(
+					( ret = elem.ownerDocument.createAttribute( name ) )
+				);
+			}
+
+			ret.value = value += "";
+
+			// Break association with cloned elements by also using setAttribute (#9646)
+			if ( name === "value" || value === elem.getAttribute( name ) ) {
+				return value;
+			}
+		}
+	};
+
+	// Some attributes are constructed with empty-string values when not defined
+	attrHandle.id = attrHandle.name = attrHandle.coords =
+		function( elem, name, isXML ) {
+			var ret;
+			if ( !isXML ) {
+				return ( ret = elem.getAttributeNode( name ) ) && ret.value !== "" ?
+					ret.value :
+					null;
+			}
+		};
+
+	// Fixing value retrieval on a button requires this module
+	jQuery.valHooks.button = {
+		get: function( elem, name ) {
+			var ret = elem.getAttributeNode( name );
+			if ( ret && ret.specified ) {
+				return ret.value;
+			}
+		},
+		set: nodeHook.set
+	};
+
+	// Set contenteditable to false on removals(#10429)
+	// Setting to empty string throws an error as an invalid value
+	jQuery.attrHooks.contenteditable = {
+		set: function( elem, value, name ) {
+			nodeHook.set( elem, value === "" ? false : value, name );
+		}
+	};
+
+	// Set width and height to auto instead of 0 on empty string( Bug #8150 )
+	// This is for removals
+	jQuery.each( [ "width", "height" ], function( i, name ) {
+		jQuery.attrHooks[ name ] = {
+			set: function( elem, value ) {
+				if ( value === "" ) {
+					elem.setAttribute( name, "auto" );
+					return value;
+				}
+			}
+		};
+	} );
+}
+
+if ( !support.style ) {
+	jQuery.attrHooks.style = {
+		get: function( elem ) {
+
+			// Return undefined in the case of empty string
+			// Note: IE uppercases css property names, but if we were to .toLowerCase()
+			// .cssText, that would destroy case sensitivity in URL's, like in "background"
+			return elem.style.cssText || undefined;
+		},
+		set: function( elem, value ) {
+			return ( elem.style.cssText = value + "" );
+		}
+	};
+}
+
+
+
+
+var rfocusable = /^(?:input|select|textarea|button|object)$/i,
+	rclickable = /^(?:a|area)$/i;
+
+jQuery.fn.extend( {
+	prop: function( name, value ) {
+		return access( this, jQuery.prop, name, value, arguments.length > 1 );
+	},
+
+	removeProp: function( name ) {
+		name = jQuery.propFix[ name ] || name;
+		return this.each( function() {
+
+			// try/catch handles cases where IE balks (such as removing a property on window)
+			try {
+				this[ name ] = undefined;
+				delete this[ name ];
+			} catch ( e ) {}
+		} );
+	}
+} );
+
+jQuery.extend( {
+	prop: function( elem, name, value ) {
+		var ret, hooks,
+			nType = elem.nodeType;
+
+		// Don't get/set properties on text, comment and attribute nodes
+		if ( nType === 3 || nType === 8 || nType === 2 ) {
+			return;
+		}
+
+		if ( nType !== 1 || !jQuery.isXMLDoc( elem ) ) {
+
+			// Fix name and attach hooks
+			name = jQuery.propFix[ name ] || name;
+			hooks = jQuery.propHooks[ name ];
+		}
+
+		if ( value !== undefined ) {
+			if ( hooks && "set" in hooks &&
+				( ret = hooks.set( elem, value, name ) ) !== undefined ) {
+				return ret;
+			}
+
+			return ( elem[ name ] = value );
+		}
+
+		if ( hooks && "get" in hooks && ( ret = hooks.get( elem, name ) ) !== null ) {
+			return ret;
+		}
+
+		return elem[ name ];
+	},
+
+	propHooks: {
+		tabIndex: {
+			get: function( elem ) {
+
+				// elem.tabIndex doesn't always return the
+				// correct value when it hasn't been explicitly set
+				// http://fluidproject.org/blog/2008/01/09/getting-setting-and-removing-tabindex-values-with-javascript/
+				// Use proper attribute retrieval(#12072)
+				var tabindex = jQuery.find.attr( elem, "tabindex" );
+
+				return tabindex ?
+					parseInt( tabindex, 10 ) :
+					rfocusable.test( elem.nodeName ) ||
+						rclickable.test( elem.nodeName ) && elem.href ?
+							0 :
+							-1;
+			}
+		}
+	},
+
+	propFix: {
+		"for": "htmlFor",
+		"class": "className"
+	}
+} );
+
+// Some attributes require a special call on IE
+// http://msdn.microsoft.com/en-us/library/ms536429%28VS.85%29.aspx
+if ( !support.hrefNormalized ) {
+
+	// href/src property should get the full normalized URL (#10299/#12915)
+	jQuery.each( [ "href", "src" ], function( i, name ) {
+		jQuery.propHooks[ name ] = {
+			get: function( elem ) {
+				return elem.getAttribute( name, 4 );
+			}
+		};
+	} );
+}
+
+// Support: Safari, IE9+
+// mis-reports the default selected property of an option
+// Accessing the parent's selectedIndex property fixes it
+if ( !support.optSelected ) {
+	jQuery.propHooks.selected = {
+		get: function( elem ) {
+			var parent = elem.parentNode;
+
+			if ( parent ) {
+				parent.selectedIndex;
+
+				// Make sure that it also works with optgroups, see #5701
+				if ( parent.parentNode ) {
+					parent.parentNode.selectedIndex;
+				}
+			}
+			return null;
+		}
+	};
+}
+
+jQuery.each( [
+	"tabIndex",
+	"readOnly",
+	"maxLength",
+	"cellSpacing",
+	"cellPadding",
+	"rowSpan",
+	"colSpan",
+	"useMap",
+	"frameBorder",
+	"contentEditable"
+], function() {
+	jQuery.propFix[ this.toLowerCase() ] = this;
+} );
+
+// IE6/7 call enctype encoding
+if ( !support.enctype ) {
+	jQuery.propFix.enctype = "encoding";
+}
+
+
+
+
+var rclass = /[\t\r\n\f]/g;
+
+function getClass( elem ) {
+	return jQuery.attr( elem, "class" ) || "";
+}
+
+jQuery.fn.extend( {
+	addClass: function( value ) {
+		var classes, elem, cur, curValue, clazz, j, finalValue,
+			i = 0;
+
+		if ( jQuery.isFunction( value ) ) {
+			return this.each( function( j ) {
+				jQuery( this ).addClass( value.call( this, j, getClass( this ) ) );
+			} );
+		}
+
+		if ( typeof value === "string" && value ) {
+			classes = value.match( rnotwhite ) || [];
+
+			while ( ( elem = this[ i++ ] ) ) {
+				curValue = getClass( elem );
+				cur = elem.nodeType === 1 &&
+					( " " + curValue + " " ).replace( rclass, " " );
+
+				if ( cur ) {
+					j = 0;
+					while ( ( clazz = classes[ j++ ] ) ) {
+						if ( cur.indexOf( " " + clazz + " " ) < 0 ) {
+							cur += clazz + " ";
+						}
+					}
+
+					// only assign if different to avoid unneeded rendering.
+					finalValue = jQuery.trim( cur );
+					if ( curValue !== finalValue ) {
+						jQuery.attr( elem, "class", finalValue );
+					}
+				}
+			}
+		}
+
+		return this;
+	},
+
+	removeClass: function( value ) {
+		var classes, elem, cur, curValue, clazz, j, finalValue,
+			i = 0;
+
+		if ( jQuery.isFunction( value ) ) {
+			return this.each( function( j ) {
+				jQuery( this ).removeClass( value.call( this, j, getClass( this ) ) );
+			} );
+		}
+
+		if ( !arguments.length ) {
+			return this.attr( "class", "" );
+		}
+
+		if ( typeof value === "string" && value ) {
+			classes = value.match( rnotwhite ) || [];
+
+			while ( ( elem = this[ i++ ] ) ) {
+				curValue = getClass( elem );
+
+				// This expression is here for better compressibility (see addClass)
+				cur = elem.nodeType === 1 &&
+					( " " + curValue + " " ).replace( rclass, " " );
+
+				if ( cur ) {
+					j = 0;
+					while ( ( clazz = classes[ j++ ] ) ) {
+
+						// Remove *all* instances
+						while ( cur.indexOf( " " + clazz + " " ) > -1 ) {
+							cur = cur.replace( " " + clazz + " ", " " );
+						}
+					}
+
+					// Only assign if different to avoid unneeded rendering.
+					finalValue = jQuery.trim( cur );
+					if ( curValue !== finalValue ) {
+						jQuery.attr( elem, "class", finalValue );
+					}
+				}
+			}
+		}
+
+		return this;
+	},
+
+	toggleClass: function( value, stateVal ) {
+		var type = typeof value;
+
+		if ( typeof stateVal === "boolean" && type === "string" ) {
+			return stateVal ? this.addClass( value ) : this.removeClass( value );
+		}
+
+		if ( jQuery.isFunction( value ) ) {
+			return this.each( function( i ) {
+				jQuery( this ).toggleClass(
+					value.call( this, i, getClass( this ), stateVal ),
+					stateVal
+				);
+			} );
+		}
+
+		return this.each( function() {
+			var className, i, self, classNames;
+
+			if ( type === "string" ) {
+
+				// Toggle individual class names
+				i = 0;
+				self = jQuery( this );
+				classNames = value.match( rnotwhite ) || [];
+
+				while ( ( className = classNames[ i++ ] ) ) {
+
+					// Check each className given, space separated list
+					if ( self.hasClass( className ) ) {
+						self.removeClass( className );
+					} else {
+						self.addClass( className );
+					}
+				}
+
+			// Toggle whole class name
+			} else if ( value === undefined || type === "boolean" ) {
+				className = getClass( this );
+				if ( className ) {
+
+					// store className if set
+					jQuery._data( this, "__className__", className );
+				}
+
+				// If the element has a class name or if we're passed "false",
+				// then remove the whole classname (if there was one, the above saved it).
+				// Otherwise bring back whatever was previously saved (if anything),
+				// falling back to the empty string if nothing was stored.
+				jQuery.attr( this, "class",
+					className || value === false ?
+					"" :
+					jQuery._data( this, "__className__" ) || ""
+				);
+			}
+		} );
+	},
+
+	hasClass: function( selector ) {
+		var className, elem,
+			i = 0;
+
+		className = " " + selector + " ";
+		while ( ( elem = this[ i++ ] ) ) {
+			if ( elem.nodeType === 1 &&
+				( " " + getClass( elem ) + " " ).replace( rclass, " " )
+					.indexOf( className ) > -1
+			) {
+				return true;
+			}
+		}
+
+		return false;
+	}
+} );
+
+
+
+
+// Return jQuery for attributes-only inclusion
+
+
+jQuery.each( ( "blur focus focusin focusout load resize scroll unload click dblclick " +
+	"mousedown mouseup mousemove mouseover mouseout mouseenter mouseleave " +
+	"change select submit keydown keypress keyup error contextmenu" ).split( " " ),
+	function( i, name ) {
+
+	// Handle event binding
+	jQuery.fn[ name ] = function( data, fn ) {
+		return arguments.length > 0 ?
+			this.on( name, null, data, fn ) :
+			this.trigger( name );
+	};
+} );
+
+jQuery.fn.extend( {
+	hover: function( fnOver, fnOut ) {
+		return this.mouseenter( fnOver ).mouseleave( fnOut || fnOver );
+	}
+} );
+
+
+var location = window.location;
+
+var nonce = jQuery.now();
+
+var rquery = ( /\?/ );
+
+
+
+var rvalidtokens = /(,)|(\[|{)|(}|])|"(?:[^"\\\r\n]|\\["\\\/bfnrt]|\\u[\da-fA-F]{4})*"\s*:?|true|false|null|-?(?!0\d)\d+(?:\.\d+|)(?:[eE][+-]?\d+|)/g;
+
+jQuery.parseJSON = function( data ) {
+
+	// Attempt to parse using the native JSON parser first
+	if ( window.JSON && window.JSON.parse ) {
+
+		// Support: Android 2.3
+		// Workaround failure to string-cast null input
+		return window.JSON.parse( data + "" );
+	}
+
+	var requireNonComma,
+		depth = null,
+		str = jQuery.trim( data + "" );
+
+	// Guard against invalid (and possibly dangerous) input by ensuring that nothing remains
+	// after removing valid tokens
+	return str && !jQuery.trim( str.replace( rvalidtokens, function( token, comma, open, close ) {
+
+		// Force termination if we see a misplaced comma
+		if ( requireNonComma && comma ) {
+			depth = 0;
+		}
+
+		// Perform no more replacements after returning to outermost depth
+		if ( depth === 0 ) {
+			return token;
+		}
+
+		// Commas must not follow "[", "{", or ","
+		requireNonComma = open || comma;
+
+		// Determine new depth
+		// array/object open ("[" or "{"): depth += true - false (increment)
+		// array/object close ("]" or "}"): depth += false - true (decrement)
+		// other cases ("," or primitive): depth += true - true (numeric cast)
+		depth += !close - !open;
+
+		// Remove this token
+		return "";
+	} ) ) ?
+		( Function( "return " + str ) )() :
+		jQuery.error( "Invalid JSON: " + data );
+};
+
+
+// Cross-browser xml parsing
+jQuery.parseXML = function( data ) {
+	var xml, tmp;
+	if ( !data || typeof data !== "string" ) {
+		return null;
+	}
+	try {
+		if ( window.DOMParser ) { // Standard
+			tmp = new window.DOMParser();
+			xml = tmp.parseFromString( data, "text/xml" );
+		} else { // IE
+			xml = new window.ActiveXObject( "Microsoft.XMLDOM" );
+			xml.async = "false";
+			xml.loadXML( data );
+		}
+	} catch ( e ) {
+		xml = undefined;
+	}
+	if ( !xml || !xml.documentElement || xml.getElementsByTagName( "parsererror" ).length ) {
+		jQuery.error( "Invalid XML: " + data );
+	}
+	return xml;
+};
+
+
+var
+	rhash = /#.*$/,
+	rts = /([?&])_=[^&]*/,
+
+	// IE leaves an \r character at EOL
+	rheaders = /^(.*?):[ \t]*([^\r\n]*)\r?$/mg,
+
+	// #7653, #8125, #8152: local protocol detection
+	rlocalProtocol = /^(?:about|app|app-storage|.+-extension|file|res|widget):$/,
+	rnoContent = /^(?:GET|HEAD)$/,
+	rprotocol = /^\/\//,
+	rurl = /^([\w.+-]+:)(?:\/\/(?:[^\/?#]*@|)([^\/?#:]*)(?::(\d+)|)|)/,
+
+	/* Prefilters
+	 * 1) They are useful to introduce custom dataTypes (see ajax/jsonp.js for an example)
+	 * 2) These are called:
+	 *    - BEFORE asking for a transport
+	 *    - AFTER param serialization (s.data is a string if s.processData is true)
+	 * 3) key is the dataType
+	 * 4) the catchall symbol "*" can be used
+	 * 5) execution will start with transport dataType and THEN continue down to "*" if needed
+	 */
+	prefilters = {},
+
+	/* Transports bindings
+	 * 1) key is the dataType
+	 * 2) the catchall symbol "*" can be used
+	 * 3) selection will start with transport dataType and THEN go to "*" if needed
+	 */
+	transports = {},
+
+	// Avoid comment-prolog char sequence (#10098); must appease lint and evade compression
+	allTypes = "*/".concat( "*" ),
+
+	// Document location
+	ajaxLocation = location.href,
+
+	// Segment location into parts
+	ajaxLocParts = rurl.exec( ajaxLocation.toLowerCase() ) || [];
+
+// Base "constructor" for jQuery.ajaxPrefilter and jQuery.ajaxTransport
+function addToPrefiltersOrTransports( structure ) {
+
+	// dataTypeExpression is optional and defaults to "*"
+	return function( dataTypeExpression, func ) {
+
+		if ( typeof dataTypeExpression !== "string" ) {
+			func = dataTypeExpression;
+			dataTypeExpression = "*";
+		}
+
+		var dataType,
+			i = 0,
+			dataTypes = dataTypeExpression.toLowerCase().match( rnotwhite ) || [];
+
+		if ( jQuery.isFunction( func ) ) {
+
+			// For each dataType in the dataTypeExpression
+			while ( ( dataType = dataTypes[ i++ ] ) ) {
+
+				// Prepend if requested
+				if ( dataType.charAt( 0 ) === "+" ) {
+					dataType = dataType.slice( 1 ) || "*";
+					( structure[ dataType ] = structure[ dataType ] || [] ).unshift( func );
+
+				// Otherwise append
+				} else {
+					( structure[ dataType ] = structure[ dataType ] || [] ).push( func );
+				}
+			}
+		}
+	};
+}
+
+// Base inspection function for prefilters and transports
+function inspectPrefiltersOrTransports( structure, options, originalOptions, jqXHR ) {
+
+	var inspected = {},
+		seekingTransport = ( structure === transports );
+
+	function inspect( dataType ) {
+		var selected;
+		inspected[ dataType ] = true;
+		jQuery.each( structure[ dataType ] || [], function( _, prefilterOrFactory ) {
+			var dataTypeOrTransport = prefilterOrFactory( options, originalOptions, jqXHR );
+			if ( typeof dataTypeOrTransport === "string" &&
+				!seekingTransport && !inspected[ dataTypeOrTransport ] ) {
+
+				options.dataTypes.unshift( dataTypeOrTransport );
+				inspect( dataTypeOrTransport );
+				return false;
+			} else if ( seekingTransport ) {
+				return !( selected = dataTypeOrTransport );
+			}
+		} );
+		return selected;
+	}
+
+	return inspect( options.dataTypes[ 0 ] ) || !inspected[ "*" ] && inspect( "*" );
+}
+
+// A special extend for ajax options
+// that takes "flat" options (not to be deep extended)
+// Fixes #9887
+function ajaxExtend( target, src ) {
+	var deep, key,
+		flatOptions = jQuery.ajaxSettings.flatOptions || {};
+
+	for ( key in src ) {
+		if ( src[ key ] !== undefined ) {
+			( flatOptions[ key ] ? target : ( deep || ( deep = {} ) ) )[ key ] = src[ key ];
+		}
+	}
+	if ( deep ) {
+		jQuery.extend( true, target, deep );
+	}
+
+	return target;
+}
+
+/* Handles responses to an ajax request:
+ * - finds the right dataType (mediates between content-type and expected dataType)
+ * - returns the corresponding response
+ */
+function ajaxHandleResponses( s, jqXHR, responses ) {
+	var firstDataType, ct, finalDataType, type,
+		contents = s.contents,
+		dataTypes = s.dataTypes;
+
+	// Remove auto dataType and get content-type in the process
+	while ( dataTypes[ 0 ] === "*" ) {
+		dataTypes.shift();
+		if ( ct === undefined ) {
+			ct = s.mimeType || jqXHR.getResponseHeader( "Content-Type" );
+		}
+	}
+
+	// Check if we're dealing with a known content-type
+	if ( ct ) {
+		for ( type in contents ) {
+			if ( contents[ type ] && contents[ type ].test( ct ) ) {
+				dataTypes.unshift( type );
+				break;
+			}
+		}
+	}
+
+	// Check to see if we have a response for the expected dataType
+	if ( dataTypes[ 0 ] in responses ) {
+		finalDataType = dataTypes[ 0 ];
+	} else {
+
+		// Try convertible dataTypes
+		for ( type in responses ) {
+			if ( !dataTypes[ 0 ] || s.converters[ type + " " + dataTypes[ 0 ] ] ) {
+				finalDataType = type;
+				break;
+			}
+			if ( !firstDataType ) {
+				firstDataType = type;
+			}
+		}
+
+		// Or just use first one
+		finalDataType = finalDataType || firstDataType;
+	}
+
+	// If we found a dataType
+	// We add the dataType to the list if needed
+	// and return the corresponding response
+	if ( finalDataType ) {
+		if ( finalDataType !== dataTypes[ 0 ] ) {
+			dataTypes.unshift( finalDataType );
+		}
+		return responses[ finalDataType ];
+	}
+}
+
+/* Chain conversions given the request and the original response
+ * Also sets the responseXXX fields on the jqXHR instance
+ */
+function ajaxConvert( s, response, jqXHR, isSuccess ) {
+	var conv2, current, conv, tmp, prev,
+		converters = {},
+
+		// Work with a copy of dataTypes in case we need to modify it for conversion
+		dataTypes = s.dataTypes.slice();
+
+	// Create converters map with lowercased keys
+	if ( dataTypes[ 1 ] ) {
+		for ( conv in s.converters ) {
+			converters[ conv.toLowerCase() ] = s.converters[ conv ];
+		}
+	}
+
+	current = dataTypes.shift();
+
+	// Convert to each sequential dataType
+	while ( current ) {
+
+		if ( s.responseFields[ current ] ) {
+			jqXHR[ s.responseFields[ current ] ] = response;
+		}
+
+		// Apply the dataFilter if provided
+		if ( !prev && isSuccess && s.dataFilter ) {
+			response = s.dataFilter( response, s.dataType );
+		}
+
+		prev = current;
+		current = dataTypes.shift();
+
+		if ( current ) {
+
+			// There's only work to do if current dataType is non-auto
+			if ( current === "*" ) {
+
+				current = prev;
+
+			// Convert response if prev dataType is non-auto and differs from current
+			} else if ( prev !== "*" && prev !== current ) {
+
+				// Seek a direct converter
+				conv = converters[ prev + " " + current ] || converters[ "* " + current ];
+
+				// If none found, seek a pair
+				if ( !conv ) {
+					for ( conv2 in converters ) {
+
+						// If conv2 outputs current
+						tmp = conv2.split( " " );
+						if ( tmp[ 1 ] === current ) {
+
+							// If prev can be converted to accepted input
+							conv = converters[ prev + " " + tmp[ 0 ] ] ||
+								converters[ "* " + tmp[ 0 ] ];
+							if ( conv ) {
+
+								// Condense equivalence converters
+								if ( conv === true ) {
+									conv = converters[ conv2 ];
+
+								// Otherwise, insert the intermediate dataType
+								} else if ( converters[ conv2 ] !== true ) {
+									current = tmp[ 0 ];
+									dataTypes.unshift( tmp[ 1 ] );
+								}
+								break;
+							}
+						}
+					}
+				}
+
+				// Apply converter (if not an equivalence)
+				if ( conv !== true ) {
+
+					// Unless errors are allowed to bubble, catch and return them
+					if ( conv && s[ "throws" ] ) { // jscs:ignore requireDotNotation
+						response = conv( response );
+					} else {
+						try {
+							response = conv( response );
+						} catch ( e ) {
+							return {
+								state: "parsererror",
+								error: conv ? e : "No conversion from " + prev + " to " + current
+							};
+						}
+					}
+				}
+			}
+		}
+	}
+
+	return { state: "success", data: response };
+}
+
+jQuery.extend( {
+
+	// Counter for holding the number of active queries
+	active: 0,
+
+	// Last-Modified header cache for next request
+	lastModified: {},
+	etag: {},
+
+	ajaxSettings: {
+		url: ajaxLocation,
+		type: "GET",
+		isLocal: rlocalProtocol.test( ajaxLocParts[ 1 ] ),
+		global: true,
+		processData: true,
+		async: true,
+		contentType: "application/x-www-form-urlencoded; charset=UTF-8",
+		/*
+		timeout: 0,
+		data: null,
+		dataType: null,
+		username: null,
+		password: null,
+		cache: null,
+		throws: false,
+		traditional: false,
+		headers: {},
+		*/
+
+		accepts: {
+			"*": allTypes,
+			text: "text/plain",
+			html: "text/html",
+			xml: "application/xml, text/xml",
+			json: "application/json, text/javascript"
+		},
+
+		contents: {
+			xml: /\bxml\b/,
+			html: /\bhtml/,
+			json: /\bjson\b/
+		},
+
+		responseFields: {
+			xml: "responseXML",
+			text: "responseText",
+			json: "responseJSON"
+		},
+
+		// Data converters
+		// Keys separate source (or catchall "*") and destination types with a single space
+		converters: {
+
+			// Convert anything to text
+			"* text": String,
+
+			// Text to html (true = no transformation)
+			"text html": true,
+
+			// Evaluate text as a json expression
+			"text json": jQuery.parseJSON,
+
+			// Parse text as xml
+			"text xml": jQuery.parseXML
+		},
+
+		// For options that shouldn't be deep extended:
+		// you can add your own custom options here if
+		// and when you create one that shouldn't be
+		// deep extended (see ajaxExtend)
+		flatOptions: {
+			url: true,
+			context: true
+		}
+	},
+
+	// Creates a full fledged settings object into target
+	// with both ajaxSettings and settings fields.
+	// If target is omitted, writes into ajaxSettings.
+	ajaxSetup: function( target, settings ) {
+		return settings ?
+
+			// Building a settings object
+			ajaxExtend( ajaxExtend( target, jQuery.ajaxSettings ), settings ) :
+
+			// Extending ajaxSettings
+			ajaxExtend( jQuery.ajaxSettings, target );
+	},
+
+	ajaxPrefilter: addToPrefiltersOrTransports( prefilters ),
+	ajaxTransport: addToPrefiltersOrTransports( transports ),
+
+	// Main method
+	ajax: function( url, options ) {
+
+		// If url is an object, simulate pre-1.5 signature
+		if ( typeof url === "object" ) {
+			options = url;
+			url = undefined;
+		}
+
+		// Force options to be an object
+		options = options || {};
+
+		var
+
+			// Cross-domain detection vars
+			parts,
+
+			// Loop variable
+			i,
+
+			// URL without anti-cache param
+			cacheURL,
+
+			// Response headers as string
+			responseHeadersString,
+
+			// timeout handle
+			timeoutTimer,
+
+			// To know if global events are to be dispatched
+			fireGlobals,
+
+			transport,
+
+			// Response headers
+			responseHeaders,
+
+			// Create the final options object
+			s = jQuery.ajaxSetup( {}, options ),
+
+			// Callbacks context
+			callbackContext = s.context || s,
+
+			// Context for global events is callbackContext if it is a DOM node or jQuery collection
+			globalEventContext = s.context &&
+				( callbackContext.nodeType || callbackContext.jquery ) ?
+					jQuery( callbackContext ) :
+					jQuery.event,
+
+			// Deferreds
+			deferred = jQuery.Deferred(),
+			completeDeferred = jQuery.Callbacks( "once memory" ),
+
+			// Status-dependent callbacks
+			statusCode = s.statusCode || {},
+
+			// Headers (they are sent all at once)
+			requestHeaders = {},
+			requestHeadersNames = {},
+
+			// The jqXHR state
+			state = 0,
+
+			// Default abort message
+			strAbort = "canceled",
+
+			// Fake xhr
+			jqXHR = {
+				readyState: 0,
+
+				// Builds headers hashtable if needed
+				getResponseHeader: function( key ) {
+					var match;
+					if ( state === 2 ) {
+						if ( !responseHeaders ) {
+							responseHeaders = {};
+							while ( ( match = rheaders.exec( responseHeadersString ) ) ) {
+								responseHeaders[ match[ 1 ].toLowerCase() ] = match[ 2 ];
+							}
+						}
+						match = responseHeaders[ key.toLowerCase() ];
+					}
+					return match == null ? null : match;
+				},
+
+				// Raw string
+				getAllResponseHeaders: function() {
+					return state === 2 ? responseHeadersString : null;
+				},
+
+				// Caches the header
+				setRequestHeader: function( name, value ) {
+					var lname = name.toLowerCase();
+					if ( !state ) {
+						name = requestHeadersNames[ lname ] = requestHeadersNames[ lname ] || name;
+						requestHeaders[ name ] = value;
+					}
+					return this;
+				},
+
+				// Overrides response content-type header
+				overrideMimeType: function( type ) {
+					if ( !state ) {
+						s.mimeType = type;
+					}
+					return this;
+				},
+
+				// Status-dependent callbacks
+				statusCode: function( map ) {
+					var code;
+					if ( map ) {
+						if ( state < 2 ) {
+							for ( code in map ) {
+
+								// Lazy-add the new callback in a way that preserves old ones
+								statusCode[ code ] = [ statusCode[ code ], map[ code ] ];
+							}
+						} else {
+
+							// Execute the appropriate callbacks
+							jqXHR.always( map[ jqXHR.status ] );
+						}
+					}
+					return this;
+				},
+
+				// Cancel the request
+				abort: function( statusText ) {
+					var finalText = statusText || strAbort;
+					if ( transport ) {
+						transport.abort( finalText );
+					}
+					done( 0, finalText );
+					return this;
+				}
+			};
+
+		// Attach deferreds
+		deferred.promise( jqXHR ).complete = completeDeferred.add;
+		jqXHR.success = jqXHR.done;
+		jqXHR.error = jqXHR.fail;
+
+		// Remove hash character (#7531: and string promotion)
+		// Add protocol if not provided (#5866: IE7 issue with protocol-less urls)
+		// Handle falsy url in the settings object (#10093: consistency with old signature)
+		// We also use the url parameter if available
+		s.url = ( ( url || s.url || ajaxLocation ) + "" )
+			.replace( rhash, "" )
+			.replace( rprotocol, ajaxLocParts[ 1 ] + "//" );
+
+		// Alias method option to type as per ticket #12004
+		s.type = options.method || options.type || s.method || s.type;
+
+		// Extract dataTypes list
+		s.dataTypes = jQuery.trim( s.dataType || "*" ).toLowerCase().match( rnotwhite ) || [ "" ];
+
+		// A cross-domain request is in order when we have a protocol:host:port mismatch
+		if ( s.crossDomain == null ) {
+			parts = rurl.exec( s.url.toLowerCase() );
+			s.crossDomain = !!( parts &&
+				( parts[ 1 ] !== ajaxLocParts[ 1 ] || parts[ 2 ] !== ajaxLocParts[ 2 ] ||
+					( parts[ 3 ] || ( parts[ 1 ] === "http:" ? "80" : "443" ) ) !==
+						( ajaxLocParts[ 3 ] || ( ajaxLocParts[ 1 ] === "http:" ? "80" : "443" ) ) )
+			);
+		}
+
+		// Convert data if not already a string
+		if ( s.data && s.processData && typeof s.data !== "string" ) {
+			s.data = jQuery.param( s.data, s.traditional );
+		}
+
+		// Apply prefilters
+		inspectPrefiltersOrTransports( prefilters, s, options, jqXHR );
+
+		// If request was aborted inside a prefilter, stop there
+		if ( state === 2 ) {
+			return jqXHR;
+		}
+
+		// We can fire global events as of now if asked to
+		// Don't fire events if jQuery.event is undefined in an AMD-usage scenario (#15118)
+		fireGlobals = jQuery.event && s.global;
+
+		// Watch for a new set of requests
+		if ( fireGlobals && jQuery.active++ === 0 ) {
+			jQuery.event.trigger( "ajaxStart" );
+		}
+
+		// Uppercase the type
+		s.type = s.type.toUpperCase();
+
+		// Determine if request has content
+		s.hasContent = !rnoContent.test( s.type );
+
+		// Save the URL in case we're toying with the If-Modified-Since
+		// and/or If-None-Match header later on
+		cacheURL = s.url;
+
+		// More options handling for requests with no content
+		if ( !s.hasContent ) {
+
+			// If data is available, append data to url
+			if ( s.data ) {
+				cacheURL = ( s.url += ( rquery.test( cacheURL ) ? "&" : "?" ) + s.data );
+
+				// #9682: remove data so that it's not used in an eventual retry
+				delete s.data;
+			}
+
+			// Add anti-cache in url if needed
+			if ( s.cache === false ) {
+				s.url = rts.test( cacheURL ) ?
+
+					// If there is already a '_' parameter, set its value
+					cacheURL.replace( rts, "$1_=" + nonce++ ) :
+
+					// Otherwise add one to the end
+					cacheURL + ( rquery.test( cacheURL ) ? "&" : "?" ) + "_=" + nonce++;
+			}
+		}
+
+		// Set the If-Modified-Since and/or If-None-Match header, if in ifModified mode.
+		if ( s.ifModified ) {
+			if ( jQuery.lastModified[ cacheURL ] ) {
+				jqXHR.setRequestHeader( "If-Modified-Since", jQuery.lastModified[ cacheURL ] );
+			}
+			if ( jQuery.etag[ cacheURL ] ) {
+				jqXHR.setRequestHeader( "If-None-Match", jQuery.etag[ cacheURL ] );
+			}
+		}
+
+		// Set the correct header, if data is being sent
+		if ( s.data && s.hasContent && s.contentType !== false || options.contentType ) {
+			jqXHR.setRequestHeader( "Content-Type", s.contentType );
+		}
+
+		// Set the Accepts header for the server, depending on the dataType
+		jqXHR.setRequestHeader(
+			"Accept",
+			s.dataTypes[ 0 ] && s.accepts[ s.dataTypes[ 0 ] ] ?
+				s.accepts[ s.dataTypes[ 0 ] ] +
+					( s.dataTypes[ 0 ] !== "*" ? ", " + allTypes + "; q=0.01" : "" ) :
+				s.accepts[ "*" ]
+		);
+
+		// Check for headers option
+		for ( i in s.headers ) {
+			jqXHR.setRequestHeader( i, s.headers[ i ] );
+		}
+
+		// Allow custom headers/mimetypes and early abort
+		if ( s.beforeSend &&
+			( s.beforeSend.call( callbackContext, jqXHR, s ) === false || state === 2 ) ) {
+
+			// Abort if not done already and return
+			return jqXHR.abort();
+		}
+
+		// aborting is no longer a cancellation
+		strAbort = "abort";
+
+		// Install callbacks on deferreds
+		for ( i in { success: 1, error: 1, complete: 1 } ) {
+			jqXHR[ i ]( s[ i ] );
+		}
+
+		// Get transport
+		transport = inspectPrefiltersOrTransports( transports, s, options, jqXHR );
+
+		// If no transport, we auto-abort
+		if ( !transport ) {
+			done( -1, "No Transport" );
+		} else {
+			jqXHR.readyState = 1;
+
+			// Send global event
+			if ( fireGlobals ) {
+				globalEventContext.trigger( "ajaxSend", [ jqXHR, s ] );
+			}
+
+			// If request was aborted inside ajaxSend, stop there
+			if ( state === 2 ) {
+				return jqXHR;
+			}
+
+			// Timeout
+			if ( s.async && s.timeout > 0 ) {
+				timeoutTimer = window.setTimeout( function() {
+					jqXHR.abort( "timeout" );
+				}, s.timeout );
+			}
+
+			try {
+				state = 1;
+				transport.send( requestHeaders, done );
+			} catch ( e ) {
+
+				// Propagate exception as error if not done
+				if ( state < 2 ) {
+					done( -1, e );
+
+				// Simply rethrow otherwise
+				} else {
+					throw e;
+				}
+			}
+		}
+
+		// Callback for when everything is done
+		function done( status, nativeStatusText, responses, headers ) {
+			var isSuccess, success, error, response, modified,
+				statusText = nativeStatusText;
+
+			// Called once
+			if ( state === 2 ) {
+				return;
+			}
+
+			// State is "done" now
+			state = 2;
+
+			// Clear timeout if it exists
+			if ( timeoutTimer ) {
+				window.clearTimeout( timeoutTimer );
+			}
+
+			// Dereference transport for early garbage collection
+			// (no matter how long the jqXHR object will be used)
+			transport = undefined;
+
+			// Cache response headers
+			responseHeadersString = headers || "";
+
+			// Set readyState
+			jqXHR.readyState = status > 0 ? 4 : 0;
+
+			// Determine if successful
+			isSuccess = status >= 200 && status < 300 || status === 304;
+
+			// Get response data
+			if ( responses ) {
+				response = ajaxHandleResponses( s, jqXHR, responses );
+			}
+
+			// Convert no matter what (that way responseXXX fields are always set)
+			response = ajaxConvert( s, response, jqXHR, isSuccess );
+
+			// If successful, handle type chaining
+			if ( isSuccess ) {
+
+				// Set the If-Modified-Since and/or If-None-Match header, if in ifModified mode.
+				if ( s.ifModified ) {
+					modified = jqXHR.getResponseHeader( "Last-Modified" );
+					if ( modified ) {
+						jQuery.lastModified[ cacheURL ] = modified;
+					}
+					modified = jqXHR.getResponseHeader( "etag" );
+					if ( modified ) {
+						jQuery.etag[ cacheURL ] = modified;
+					}
+				}
+
+				// if no content
+				if ( status === 204 || s.type === "HEAD" ) {
+					statusText = "nocontent";
+
+				// if not modified
+				} else if ( status === 304 ) {
+					statusText = "notmodified";
+
+				// If we have data, let's convert it
+				} else {
+					statusText = response.state;
+					success = response.data;
+					error = response.error;
+					isSuccess = !error;
+				}
+			} else {
+
+				// We extract error from statusText
+				// then normalize statusText and status for non-aborts
+				error = statusText;
+				if ( status || !statusText ) {
+					statusText = "error";
+					if ( status < 0 ) {
+						status = 0;
+					}
+				}
+			}
+
+			// Set data for the fake xhr object
+			jqXHR.status = status;
+			jqXHR.statusText = ( nativeStatusText || statusText ) + "";
+
+			// Success/Error
+			if ( isSuccess ) {
+				deferred.resolveWith( callbackContext, [ success, statusText, jqXHR ] );
+			} else {
+				deferred.rejectWith( callbackContext, [ jqXHR, statusText, error ] );
+			}
+
+			// Status-dependent callbacks
+			jqXHR.statusCode( statusCode );
+			statusCode = undefined;
+
+			if ( fireGlobals ) {
+				globalEventContext.trigger( isSuccess ? "ajaxSuccess" : "ajaxError",
+					[ jqXHR, s, isSuccess ? success : error ] );
+			}
+
+			// Complete
+			completeDeferred.fireWith( callbackContext, [ jqXHR, statusText ] );
+
+			if ( fireGlobals ) {
+				globalEventContext.trigger( "ajaxComplete", [ jqXHR, s ] );
+
+				// Handle the global AJAX counter
+				if ( !( --jQuery.active ) ) {
+					jQuery.event.trigger( "ajaxStop" );
+				}
+			}
+		}
+
+		return jqXHR;
+	},
+
+	getJSON: function( url, data, callback ) {
+		return jQuery.get( url, data, callback, "json" );
+	},
+
+	getScript: function( url, callback ) {
+		return jQuery.get( url, undefined, callback, "script" );
+	}
+} );
+
+jQuery.each( [ "get", "post" ], function( i, method ) {
+	jQuery[ method ] = function( url, data, callback, type ) {
+
+		// shift arguments if data argument was omitted
+		if ( jQuery.isFunction( data ) ) {
+			type = type || callback;
+			callback = data;
+			data = undefined;
+		}
+
+		// The url can be an options object (which then must have .url)
+		return jQuery.ajax( jQuery.extend( {
+			url: url,
+			type: method,
+			dataType: type,
+			data: data,
+			success: callback
+		}, jQuery.isPlainObject( url ) && url ) );
+	};
+} );
+
+
+jQuery._evalUrl = function( url ) {
+	return jQuery.ajax( {
+		url: url,
+
+		// Make this explicit, since user can override this through ajaxSetup (#11264)
+		type: "GET",
+		dataType: "script",
+		cache: true,
+		async: false,
+		global: false,
+		"throws": true
+	} );
+};
+
+
+jQuery.fn.extend( {
+	wrapAll: function( html ) {
+		if ( jQuery.isFunction( html ) ) {
+			return this.each( function( i ) {
+				jQuery( this ).wrapAll( html.call( this, i ) );
+			} );
+		}
+
+		if ( this[ 0 ] ) {
+
+			// The elements to wrap the target around
+			var wrap = jQuery( html, this[ 0 ].ownerDocument ).eq( 0 ).clone( true );
+
+			if ( this[ 0 ].parentNode ) {
+				wrap.insertBefore( this[ 0 ] );
+			}
+
+			wrap.map( function() {
+				var elem = this;
+
+				while ( elem.firstChild && elem.firstChild.nodeType === 1 ) {
+					elem = elem.firstChild;
+				}
+
+				return elem;
+			} ).append( this );
+		}
+
+		return this;
+	},
+
+	wrapInner: function( html ) {
+		if ( jQuery.isFunction( html ) ) {
+			return this.each( function( i ) {
+				jQuery( this ).wrapInner( html.call( this, i ) );
+			} );
+		}
+
+		return this.each( function() {
+			var self = jQuery( this ),
+				contents = self.contents();
+
+			if ( contents.length ) {
+				contents.wrapAll( html );
+
+			} else {
+				self.append( html );
+			}
+		} );
+	},
+
+	wrap: function( html ) {
+		var isFunction = jQuery.isFunction( html );
+
+		return this.each( function( i ) {
+			jQuery( this ).wrapAll( isFunction ? html.call( this, i ) : html );
+		} );
+	},
+
+	unwrap: function() {
+		return this.parent().each( function() {
+			if ( !jQuery.nodeName( this, "body" ) ) {
+				jQuery( this ).replaceWith( this.childNodes );
+			}
+		} ).end();
+	}
+} );
+
+
+function getDisplay( elem ) {
+	return elem.style && elem.style.display || jQuery.css( elem, "display" );
+}
+
+function filterHidden( elem ) {
+	while ( elem && elem.nodeType === 1 ) {
+		if ( getDisplay( elem ) === "none" || elem.type === "hidden" ) {
+			return true;
+		}
+		elem = elem.parentNode;
+	}
+	return false;
+}
+
+jQuery.expr.filters.hidden = function( elem ) {
+
+	// Support: Opera <= 12.12
+	// Opera reports offsetWidths and offsetHeights less than zero on some elements
+	return support.reliableHiddenOffsets() ?
+		( elem.offsetWidth <= 0 && elem.offsetHeight <= 0 &&
+			!elem.getClientRects().length ) :
+			filterHidden( elem );
+};
+
+jQuery.expr.filters.visible = function( elem ) {
+	return !jQuery.expr.filters.hidden( elem );
+};
+
+
+
+
+var r20 = /%20/g,
+	rbracket = /\[\]$/,
+	rCRLF = /\r?\n/g,
+	rsubmitterTypes = /^(?:submit|button|image|reset|file)$/i,
+	rsubmittable = /^(?:input|select|textarea|keygen)/i;
+
+function buildParams( prefix, obj, traditional, add ) {
+	var name;
+
+	if ( jQuery.isArray( obj ) ) {
+
+		// Serialize array item.
+		jQuery.each( obj, function( i, v ) {
+			if ( traditional || rbracket.test( prefix ) ) {
+
+				// Treat each array item as a scalar.
+				add( prefix, v );
+
+			} else {
+
+				// Item is non-scalar (array or object), encode its numeric index.
+				buildParams(
+					prefix + "[" + ( typeof v === "object" && v != null ? i : "" ) + "]",
+					v,
+					traditional,
+					add
+				);
+			}
+		} );
+
+	} else if ( !traditional && jQuery.type( obj ) === "object" ) {
+
+		// Serialize object item.
+		for ( name in obj ) {
+			buildParams( prefix + "[" + name + "]", obj[ name ], traditional, add );
+		}
+
+	} else {
+
+		// Serialize scalar item.
+		add( prefix, obj );
+	}
+}
+
+// Serialize an array of form elements or a set of
+// key/values into a query string
+jQuery.param = function( a, traditional ) {
+	var prefix,
+		s = [],
+		add = function( key, value ) {
+
+			// If value is a function, invoke it and return its value
+			value = jQuery.isFunction( value ) ? value() : ( value == null ? "" : value );
+			s[ s.length ] = encodeURIComponent( key ) + "=" + encodeURIComponent( value );
+		};
+
+	// Set traditional to true for jQuery <= 1.3.2 behavior.
+	if ( traditional === undefined ) {
+		traditional = jQuery.ajaxSettings && jQuery.ajaxSettings.traditional;
+	}
+
+	// If an array was passed in, assume that it is an array of form elements.
+	if ( jQuery.isArray( a ) || ( a.jquery && !jQuery.isPlainObject( a ) ) ) {
+
+		// Serialize the form elements
+		jQuery.each( a, function() {
+			add( this.name, this.value );
+		} );
+
+	} else {
+
+		// If traditional, encode the "old" way (the way 1.3.2 or older
+		// did it), otherwise encode params recursively.
+		for ( prefix in a ) {
+			buildParams( prefix, a[ prefix ], traditional, add );
+		}
+	}
+
+	// Return the resulting serialization
+	return s.join( "&" ).replace( r20, "+" );
+};
+
+jQuery.fn.extend( {
+	serialize: function() {
+		return jQuery.param( this.serializeArray() );
+	},
+	serializeArray: function() {
+		return this.map( function() {
+
+			// Can add propHook for "elements" to filter or add form elements
+			var elements = jQuery.prop( this, "elements" );
+			return elements ? jQuery.makeArray( elements ) : this;
+		} )
+		.filter( function() {
+			var type = this.type;
+
+			// Use .is(":disabled") so that fieldset[disabled] works
+			return this.name && !jQuery( this ).is( ":disabled" ) &&
+				rsubmittable.test( this.nodeName ) && !rsubmitterTypes.test( type ) &&
+				( this.checked || !rcheckableType.test( type ) );
+		} )
+		.map( function( i, elem ) {
+			var val = jQuery( this ).val();
+
+			return val == null ?
+				null :
+				jQuery.isArray( val ) ?
+					jQuery.map( val, function( val ) {
+						return { name: elem.name, value: val.replace( rCRLF, "\r\n" ) };
+					} ) :
+					{ name: elem.name, value: val.replace( rCRLF, "\r\n" ) };
+		} ).get();
+	}
+} );
+
+
+// Create the request object
+// (This is still attached to ajaxSettings for backward compatibility)
+jQuery.ajaxSettings.xhr = window.ActiveXObject !== undefined ?
+
+	// Support: IE6-IE8
+	function() {
+
+		// XHR cannot access local files, always use ActiveX for that case
+		if ( this.isLocal ) {
+			return createActiveXHR();
+		}
+
+		// Support: IE 9-11
+		// IE seems to error on cross-domain PATCH requests when ActiveX XHR
+		// is used. In IE 9+ always use the native XHR.
+		// Note: this condition won't catch Edge as it doesn't define
+		// document.documentMode but it also doesn't support ActiveX so it won't
+		// reach this code.
+		if ( document.documentMode > 8 ) {
+			return createStandardXHR();
+		}
+
+		// Support: IE<9
+		// oldIE XHR does not support non-RFC2616 methods (#13240)
+		// See http://msdn.microsoft.com/en-us/library/ie/ms536648(v=vs.85).aspx
+		// and http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9
+		// Although this check for six methods instead of eight
+		// since IE also does not support "trace" and "connect"
+		return /^(get|post|head|put|delete|options)$/i.test( this.type ) &&
+			createStandardXHR() || createActiveXHR();
+	} :
+
+	// For all other browsers, use the standard XMLHttpRequest object
+	createStandardXHR;
+
+var xhrId = 0,
+	xhrCallbacks = {},
+	xhrSupported = jQuery.ajaxSettings.xhr();
+
+// Support: IE<10
+// Open requests must be manually aborted on unload (#5280)
+// See https://support.microsoft.com/kb/2856746 for more info
+if ( window.attachEvent ) {
+	window.attachEvent( "onunload", function() {
+		for ( var key in xhrCallbacks ) {
+			xhrCallbacks[ key ]( undefined, true );
+		}
+	} );
+}
+
+// Determine support properties
+support.cors = !!xhrSupported && ( "withCredentials" in xhrSupported );
+xhrSupported = support.ajax = !!xhrSupported;
+
+// Create transport if the browser can provide an xhr
+if ( xhrSupported ) {
+
+	jQuery.ajaxTransport( function( options ) {
+
+		// Cross domain only allowed if supported through XMLHttpRequest
+		if ( !options.crossDomain || support.cors ) {
+
+			var callback;
+
+			return {
+				send: function( headers, complete ) {
+					var i,
+						xhr = options.xhr(),
+						id = ++xhrId;
+
+					// Open the socket
+					xhr.open(
+						options.type,
+						options.url,
+						options.async,
+						options.username,
+						options.password
+					);
+
+					// Apply custom fields if provided
+					if ( options.xhrFields ) {
+						for ( i in options.xhrFields ) {
+							xhr[ i ] = options.xhrFields[ i ];
+						}
+					}
+
+					// Override mime type if needed
+					if ( options.mimeType && xhr.overrideMimeType ) {
+						xhr.overrideMimeType( options.mimeType );
+					}
+
+					// X-Requested-With header
+					// For cross-domain requests, seeing as conditions for a preflight are
+					// akin to a jigsaw puzzle, we simply never set it to be sure.
+					// (it can always be set on a per-request basis or even using ajaxSetup)
+					// For same-domain requests, won't change header if already provided.
+					if ( !options.crossDomain && !headers[ "X-Requested-With" ] ) {
+						headers[ "X-Requested-With" ] = "XMLHttpRequest";
+					}
+
+					// Set headers
+					for ( i in headers ) {
+
+						// Support: IE<9
+						// IE's ActiveXObject throws a 'Type Mismatch' exception when setting
+						// request header to a null-value.
+						//
+						// To keep consistent with other XHR implementations, cast the value
+						// to string and ignore `undefined`.
+						if ( headers[ i ] !== undefined ) {
+							xhr.setRequestHeader( i, headers[ i ] + "" );
+						}
+					}
+
+					// Do send the request
+					// This may raise an exception which is actually
+					// handled in jQuery.ajax (so no try/catch here)
+					xhr.send( ( options.hasContent && options.data ) || null );
+
+					// Listener
+					callback = function( _, isAbort ) {
+						var status, statusText, responses;
+
+						// Was never called and is aborted or complete
+						if ( callback && ( isAbort || xhr.readyState === 4 ) ) {
+
+							// Clean up
+							delete xhrCallbacks[ id ];
+							callback = undefined;
+							xhr.onreadystatechange = jQuery.noop;
+
+							// Abort manually if needed
+							if ( isAbort ) {
+								if ( xhr.readyState !== 4 ) {
+									xhr.abort();
+								}
+							} else {
+								responses = {};
+								status = xhr.status;
+
+								// Support: IE<10
+								// Accessing binary-data responseText throws an exception
+								// (#11426)
+								if ( typeof xhr.responseText === "string" ) {
+									responses.text = xhr.responseText;
+								}
+
+								// Firefox throws an exception when accessing
+								// statusText for faulty cross-domain requests
+								try {
+									statusText = xhr.statusText;
+								} catch ( e ) {
+
+									// We normalize with Webkit giving an empty statusText
+									statusText = "";
+								}
+
+								// Filter status for non standard behaviors
+
+								// If the request is local and we have data: assume a success
+								// (success with no data won't get notified, that's the best we
+								// can do given current implementations)
+								if ( !status && options.isLocal && !options.crossDomain ) {
+									status = responses.text ? 200 : 404;
+
+								// IE - #1450: sometimes returns 1223 when it should be 204
+								} else if ( status === 1223 ) {
+									status = 204;
+								}
+							}
+						}
+
+						// Call complete if needed
+						if ( responses ) {
+							complete( status, statusText, responses, xhr.getAllResponseHeaders() );
+						}
+					};
+
+					// Do send the request
+					// `xhr.send` may raise an exception, but it will be
+					// handled in jQuery.ajax (so no try/catch here)
+					if ( !options.async ) {
+
+						// If we're in sync mode we fire the callback
+						callback();
+					} else if ( xhr.readyState === 4 ) {
+
+						// (IE6 & IE7) if it's in cache and has been
+						// retrieved directly we need to fire the callback
+						window.setTimeout( callback );
+					} else {
+
+						// Register the callback, but delay it in case `xhr.send` throws
+						// Add to the list of active xhr callbacks
+						xhr.onreadystatechange = xhrCallbacks[ id ] = callback;
+					}
+				},
+
+				abort: function() {
+					if ( callback ) {
+						callback( undefined, true );
+					}
+				}
+			};
+		}
+	} );
+}
+
+// Functions to create xhrs
+function createStandardXHR() {
+	try {
+		return new window.XMLHttpRequest();
+	} catch ( e ) {}
+}
+
+function createActiveXHR() {
+	try {
+		return new window.ActiveXObject( "Microsoft.XMLHTTP" );
+	} catch ( e ) {}
+}
+
+
+
+
+// Prevent auto-execution of scripts when no explicit dataType was provided (See gh-2432)
+jQuery.ajaxPrefilter( function( s ) {
+	if ( s.crossDomain ) {
+		s.contents.script = false;
+	}
+} );
+
+// Install script dataType
+jQuery.ajaxSetup( {
+	accepts: {
+		script: "text/javascript, application/javascript, " +
+			"application/ecmascript, application/x-ecmascript"
+	},
+	contents: {
+		script: /\b(?:java|ecma)script\b/
+	},
+	converters: {
+		"text script": function( text ) {
+			jQuery.globalEval( text );
+			return text;
+		}
+	}
+} );
+
+// Handle cache's special case and global
+jQuery.ajaxPrefilter( "script", function( s ) {
+	if ( s.cache === undefined ) {
+		s.cache = false;
+	}
+	if ( s.crossDomain ) {
+		s.type = "GET";
+		s.global = false;
+	}
+} );
+
+// Bind script tag hack transport
+jQuery.ajaxTransport( "script", function( s ) {
+
+	// This transport only deals with cross domain requests
+	if ( s.crossDomain ) {
+
+		var script,
+			head = document.head || jQuery( "head" )[ 0 ] || document.documentElement;
+
+		return {
+
+			send: function( _, callback ) {
+
+				script = document.createElement( "script" );
+
+				script.async = true;
+
+				if ( s.scriptCharset ) {
+					script.charset = s.scriptCharset;
+				}
+
+				script.src = s.url;
+
+				// Attach handlers for all browsers
+				script.onload = script.onreadystatechange = function( _, isAbort ) {
+
+					if ( isAbort || !script.readyState || /loaded|complete/.test( script.readyState ) ) {
+
+						// Handle memory leak in IE
+						script.onload = script.onreadystatechange = null;
+
+						// Remove the script
+						if ( script.parentNode ) {
+							script.parentNode.removeChild( script );
+						}
+
+						// Dereference the script
+						script = null;
+
+						// Callback if not abort
+						if ( !isAbort ) {
+							callback( 200, "success" );
+						}
+					}
+				};
+
+				// Circumvent IE6 bugs with base elements (#2709 and #4378) by prepending
+				// Use native DOM manipulation to avoid our domManip AJAX trickery
+				head.insertBefore( script, head.firstChild );
+			},
+
+			abort: function() {
+				if ( script ) {
+					script.onload( undefined, true );
+				}
+			}
+		};
+	}
+} );
+
+
+
+
+var oldCallbacks = [],
+	rjsonp = /(=)\?(?=&|$)|\?\?/;
+
+// Default jsonp settings
+jQuery.ajaxSetup( {
+	jsonp: "callback",
+	jsonpCallback: function() {
+		var callback = oldCallbacks.pop() || ( jQuery.expando + "_" + ( nonce++ ) );
+		this[ callback ] = true;
+		return callback;
+	}
+} );
+
+// Detect, normalize options and install callbacks for jsonp requests
+jQuery.ajaxPrefilter( "json jsonp", function( s, originalSettings, jqXHR ) {
+
+	var callbackName, overwritten, responseContainer,
+		jsonProp = s.jsonp !== false && ( rjsonp.test( s.url ) ?
+			"url" :
+			typeof s.data === "string" &&
+				( s.contentType || "" )
+					.indexOf( "application/x-www-form-urlencoded" ) === 0 &&
+				rjsonp.test( s.data ) && "data"
+		);
+
+	// Handle iff the expected data type is "jsonp" or we have a parameter to set
+	if ( jsonProp || s.dataTypes[ 0 ] === "jsonp" ) {
+
+		// Get callback name, remembering preexisting value associated with it
+		callbackName = s.jsonpCallback = jQuery.isFunction( s.jsonpCallback ) ?
+			s.jsonpCallback() :
+			s.jsonpCallback;
+
+		// Insert callback into url or form data
+		if ( jsonProp ) {
+			s[ jsonProp ] = s[ jsonProp ].replace( rjsonp, "$1" + callbackName );
+		} else if ( s.jsonp !== false ) {
+			s.url += ( rquery.test( s.url ) ? "&" : "?" ) + s.jsonp + "=" + callbackName;
+		}
+
+		// Use data converter to retrieve json after script execution
+		s.converters[ "script json" ] = function() {
+			if ( !responseContainer ) {
+				jQuery.error( callbackName + " was not called" );
+			}
+			return responseContainer[ 0 ];
+		};
+
+		// force json dataType
+		s.dataTypes[ 0 ] = "json";
+
+		// Install callback
+		overwritten = window[ callbackName ];
+		window[ callbackName ] = function() {
+			responseContainer = arguments;
+		};
+
+		// Clean-up function (fires after converters)
+		jqXHR.always( function() {
+
+			// If previous value didn't exist - remove it
+			if ( overwritten === undefined ) {
+				jQuery( window ).removeProp( callbackName );
+
+			// Otherwise restore preexisting value
+			} else {
+				window[ callbackName ] = overwritten;
+			}
+
+			// Save back as free
+			if ( s[ callbackName ] ) {
+
+				// make sure that re-using the options doesn't screw things around
+				s.jsonpCallback = originalSettings.jsonpCallback;
+
+				// save the callback name for future use
+				oldCallbacks.push( callbackName );
+			}
+
+			// Call if it was a function and we have a response
+			if ( responseContainer && jQuery.isFunction( overwritten ) ) {
+				overwritten( responseContainer[ 0 ] );
+			}
+
+			responseContainer = overwritten = undefined;
+		} );
+
+		// Delegate to script
+		return "script";
+	}
+} );
+
+
+
+
+// Support: Safari 8+
+// In Safari 8 documents created via document.implementation.createHTMLDocument
+// collapse sibling forms: the second one becomes a child of the first one.
+// Because of that, this security measure has to be disabled in Safari 8.
+// https://bugs.webkit.org/show_bug.cgi?id=137337
+support.createHTMLDocument = ( function() {
+	if ( !document.implementation.createHTMLDocument ) {
+		return false;
+	}
+	var doc = document.implementation.createHTMLDocument( "" );
+	doc.body.innerHTML = "<form></form><form></form>";
+	return doc.body.childNodes.length === 2;
+} )();
+
+
+// data: string of html
+// context (optional): If specified, the fragment will be created in this context,
+// defaults to document
+// keepScripts (optional): If true, will include scripts passed in the html string
+jQuery.parseHTML = function( data, context, keepScripts ) {
+	if ( !data || typeof data !== "string" ) {
+		return null;
+	}
+	if ( typeof context === "boolean" ) {
+		keepScripts = context;
+		context = false;
+	}
+
+	// document.implementation stops scripts or inline event handlers from
+	// being executed immediately
+	context = context || ( support.createHTMLDocument ?
+		document.implementation.createHTMLDocument( "" ) :
+		document );
+
+	var parsed = rsingleTag.exec( data ),
+		scripts = !keepScripts && [];
+
+	// Single tag
+	if ( parsed ) {
+		return [ context.createElement( parsed[ 1 ] ) ];
+	}
+
+	parsed = buildFragment( [ data ], context, scripts );
+
+	if ( scripts && scripts.length ) {
+		jQuery( scripts ).remove();
+	}
+
+	return jQuery.merge( [], parsed.childNodes );
+};
+
+
+// Keep a copy of the old load method
+var _load = jQuery.fn.load;
+
+/**
+ * Load a url into a page
+ */
+jQuery.fn.load = function( url, params, callback ) {
+	if ( typeof url !== "string" && _load ) {
+		return _load.apply( this, arguments );
+	}
+
+	var selector, type, response,
+		self = this,
+		off = url.indexOf( " " );
+
+	if ( off > -1 ) {
+		selector = jQuery.trim( url.slice( off, url.length ) );
+		url = url.slice( 0, off );
+	}
+
+	// If it's a function
+	if ( jQuery.isFunction( params ) ) {
+
+		// We assume that it's the callback
+		callback = params;
+		params = undefined;
+
+	// Otherwise, build a param string
+	} else if ( params && typeof params === "object" ) {
+		type = "POST";
+	}
+
+	// If we have elements to modify, make the request
+	if ( self.length > 0 ) {
+		jQuery.ajax( {
+			url: url,
+
+			// If "type" variable is undefined, then "GET" method will be used.
+			// Make value of this field explicit since
+			// user can override it through ajaxSetup method
+			type: type || "GET",
+			dataType: "html",
+			data: params
+		} ).done( function( responseText ) {
+
+			// Save response for use in complete callback
+			response = arguments;
+
+			self.html( selector ?
+
+				// If a selector was specified, locate the right elements in a dummy div
+				// Exclude scripts to avoid IE 'Permission Denied' errors
+				jQuery( "<div>" ).append( jQuery.parseHTML( responseText ) ).find( selector ) :
+
+				// Otherwise use the full result
+				responseText );
+
+		// If the request succeeds, this function gets "data", "status", "jqXHR"
+		// but they are ignored because response was set above.
+		// If it fails, this function gets "jqXHR", "status", "error"
+		} ).always( callback && function( jqXHR, status ) {
+			self.each( function() {
+				callback.apply( self, response || [ jqXHR.responseText, status, jqXHR ] );
+			} );
+		} );
+	}
+
+	return this;
+};
+
+
+
+
+// Attach a bunch of functions for handling common AJAX events
+jQuery.each( [
+	"ajaxStart",
+	"ajaxStop",
+	"ajaxComplete",
+	"ajaxError",
+	"ajaxSuccess",
+	"ajaxSend"
+], function( i, type ) {
+	jQuery.fn[ type ] = function( fn ) {
+		return this.on( type, fn );
+	};
+} );
+
+
+
+
+jQuery.expr.filters.animated = function( elem ) {
+	return jQuery.grep( jQuery.timers, function( fn ) {
+		return elem === fn.elem;
+	} ).length;
+};
+
+
+
+
+
+/**
+ * Gets a window from an element
+ */
+function getWindow( elem ) {
+	return jQuery.isWindow( elem ) ?
+		elem :
+		elem.nodeType === 9 ?
+			elem.defaultView || elem.parentWindow :
+			false;
+}
+
+jQuery.offset = {
+	setOffset: function( elem, options, i ) {
+		var curPosition, curLeft, curCSSTop, curTop, curOffset, curCSSLeft, calculatePosition,
+			position = jQuery.css( elem, "position" ),
+			curElem = jQuery( elem ),
+			props = {};
+
+		// set position first, in-case top/left are set even on static elem
+		if ( position === "static" ) {
+			elem.style.position = "relative";
+		}
+
+		curOffset = curElem.offset();
+		curCSSTop = jQuery.css( elem, "top" );
+		curCSSLeft = jQuery.css( elem, "left" );
+		calculatePosition = ( position === "absolute" || position === "fixed" ) &&
+			jQuery.inArray( "auto", [ curCSSTop, curCSSLeft ] ) > -1;
+
+		// need to be able to calculate position if either top or left
+		// is auto and position is either absolute or fixed
+		if ( calculatePosition ) {
+			curPosition = curElem.position();
+			curTop = curPosition.top;
+			curLeft = curPosition.left;
+		} else {
+			curTop = parseFloat( curCSSTop ) || 0;
+			curLeft = parseFloat( curCSSLeft ) || 0;
+		}
+
+		if ( jQuery.isFunction( options ) ) {
+
+			// Use jQuery.extend here to allow modification of coordinates argument (gh-1848)
+			options = options.call( elem, i, jQuery.extend( {}, curOffset ) );
+		}
+
+		if ( options.top != null ) {
+			props.top = ( options.top - curOffset.top ) + curTop;
+		}
+		if ( options.left != null ) {
+			props.left = ( options.left - curOffset.left ) + curLeft;
+		}
+
+		if ( "using" in options ) {
+			options.using.call( elem, props );
+		} else {
+			curElem.css( props );
+		}
+	}
+};
+
+jQuery.fn.extend( {
+	offset: function( options ) {
+		if ( arguments.length ) {
+			return options === undefined ?
+				this :
+				this.each( function( i ) {
+					jQuery.offset.setOffset( this, options, i );
+				} );
+		}
+
+		var docElem, win,
+			box = { top: 0, left: 0 },
+			elem = this[ 0 ],
+			doc = elem && elem.ownerDocument;
+
+		if ( !doc ) {
+			return;
+		}
+
+		docElem = doc.documentElement;
+
+		// Make sure it's not a disconnected DOM node
+		if ( !jQuery.contains( docElem, elem ) ) {
+			return box;
+		}
+
+		// If we don't have gBCR, just use 0,0 rather than error
+		// BlackBerry 5, iOS 3 (original iPhone)
+		if ( typeof elem.getBoundingClientRect !== "undefined" ) {
+			box = elem.getBoundingClientRect();
+		}
+		win = getWindow( doc );
+		return {
+			top: box.top  + ( win.pageYOffset || docElem.scrollTop )  - ( docElem.clientTop  || 0 ),
+			left: box.left + ( win.pageXOffset || docElem.scrollLeft ) - ( docElem.clientLeft || 0 )
+		};
+	},
+
+	position: function() {
+		if ( !this[ 0 ] ) {
+			return;
+		}
+
+		var offsetParent, offset,
+			parentOffset = { top: 0, left: 0 },
+			elem = this[ 0 ];
+
+		// Fixed elements are offset from window (parentOffset = {top:0, left: 0},
+		// because it is its only offset parent
+		if ( jQuery.css( elem, "position" ) === "fixed" ) {
+
+			// we assume that getBoundingClientRect is available when computed position is fixed
+			offset = elem.getBoundingClientRect();
+		} else {
+
+			// Get *real* offsetParent
+			offsetParent = this.offsetParent();
+
+			// Get correct offsets
+			offset = this.offset();
+			if ( !jQuery.nodeName( offsetParent[ 0 ], "html" ) ) {
+				parentOffset = offsetParent.offset();
+			}
+
+			// Add offsetParent borders
+			parentOffset.top  += jQuery.css( offsetParent[ 0 ], "borderTopWidth", true );
+			parentOffset.left += jQuery.css( offsetParent[ 0 ], "borderLeftWidth", true );
+		}
+
+		// Subtract parent offsets and element margins
+		// note: when an element has margin: auto the offsetLeft and marginLeft
+		// are the same in Safari causing offset.left to incorrectly be 0
+		return {
+			top:  offset.top  - parentOffset.top - jQuery.css( elem, "marginTop", true ),
+			left: offset.left - parentOffset.left - jQuery.css( elem, "marginLeft", true )
+		};
+	},
+
+	offsetParent: function() {
+		return this.map( function() {
+			var offsetParent = this.offsetParent;
+
+			while ( offsetParent && ( !jQuery.nodeName( offsetParent, "html" ) &&
+				jQuery.css( offsetParent, "position" ) === "static" ) ) {
+				offsetParent = offsetParent.offsetParent;
+			}
+			return offsetParent || documentElement;
+		} );
+	}
+} );
+
+// Create scrollLeft and scrollTop methods
+jQuery.each( { scrollLeft: "pageXOffset", scrollTop: "pageYOffset" }, function( method, prop ) {
+	var top = /Y/.test( prop );
+
+	jQuery.fn[ method ] = function( val ) {
+		return access( this, function( elem, method, val ) {
+			var win = getWindow( elem );
+
+			if ( val === undefined ) {
+				return win ? ( prop in win ) ? win[ prop ] :
+					win.document.documentElement[ method ] :
+					elem[ method ];
+			}
+
+			if ( win ) {
+				win.scrollTo(
+					!top ? val : jQuery( win ).scrollLeft(),
+					top ? val : jQuery( win ).scrollTop()
+				);
+
+			} else {
+				elem[ method ] = val;
+			}
+		}, method, val, arguments.length, null );
+	};
+} );
+
+// Support: Safari<7-8+, Chrome<37-44+
+// Add the top/left cssHooks using jQuery.fn.position
+// Webkit bug: https://bugs.webkit.org/show_bug.cgi?id=29084
+// getComputedStyle returns percent when specified for top/left/bottom/right
+// rather than make the css module depend on the offset module, we just check for it here
+jQuery.each( [ "top", "left" ], function( i, prop ) {
+	jQuery.cssHooks[ prop ] = addGetHookIf( support.pixelPosition,
+		function( elem, computed ) {
+			if ( computed ) {
+				computed = curCSS( elem, prop );
+
+				// if curCSS returns percentage, fallback to offset
+				return rnumnonpx.test( computed ) ?
+					jQuery( elem ).position()[ prop ] + "px" :
+					computed;
+			}
+		}
+	);
+} );
+
+
+// Create innerHeight, innerWidth, height, width, outerHeight and outerWidth methods
+jQuery.each( { Height: "height", Width: "width" }, function( name, type ) {
+	jQuery.each( { padding: "inner" + name, content: type, "": "outer" + name },
+	function( defaultExtra, funcName ) {
+
+		// margin is only for outerHeight, outerWidth
+		jQuery.fn[ funcName ] = function( margin, value ) {
+			var chainable = arguments.length && ( defaultExtra || typeof margin !== "boolean" ),
+				extra = defaultExtra || ( margin === true || value === true ? "margin" : "border" );
+
+			return access( this, function( elem, type, value ) {
+				var doc;
+
+				if ( jQuery.isWindow( elem ) ) {
+
+					// As of 5/8/2012 this will yield incorrect results for Mobile Safari, but there
+					// isn't a whole lot we can do. See pull request at this URL for discussion:
+					// https://github.com/jquery/jquery/pull/764
+					return elem.document.documentElement[ "client" + name ];
+				}
+
+				// Get document width or height
+				if ( elem.nodeType === 9 ) {
+					doc = elem.documentElement;
+
+					// Either scroll[Width/Height] or offset[Width/Height] or client[Width/Height],
+					// whichever is greatest
+					// unfortunately, this causes bug #3838 in IE6/8 only,
+					// but there is currently no good, small way to fix it.
+					return Math.max(
+						elem.body[ "scroll" + name ], doc[ "scroll" + name ],
+						elem.body[ "offset" + name ], doc[ "offset" + name ],
+						doc[ "client" + name ]
+					);
+				}
+
+				return value === undefined ?
+
+					// Get width or height on the element, requesting but not forcing parseFloat
+					jQuery.css( elem, type, extra ) :
+
+					// Set width or height on the element
+					jQuery.style( elem, type, value, extra );
+			}, type, chainable ? margin : undefined, chainable, null );
+		};
+	} );
+} );
+
+
+jQuery.fn.extend( {
+
+	bind: function( types, data, fn ) {
+		return this.on( types, null, data, fn );
+	},
+	unbind: function( types, fn ) {
+		return this.off( types, null, fn );
+	},
+
+	delegate: function( selector, types, data, fn ) {
+		return this.on( types, selector, data, fn );
+	},
+	undelegate: function( selector, types, fn ) {
+
+		// ( namespace ) or ( selector, types [, fn] )
+		return arguments.length === 1 ?
+			this.off( selector, "**" ) :
+			this.off( types, selector || "**", fn );
+	}
+} );
+
+// The number of elements contained in the matched element set
+jQuery.fn.size = function() {
+	return this.length;
+};
+
+jQuery.fn.andSelf = jQuery.fn.addBack;
+
+
+
+
+// Register as a named AMD module, since jQuery can be concatenated with other
+// files that may use define, but not via a proper concatenation script that
+// understands anonymous AMD modules. A named AMD is safest and most robust
+// way to register. Lowercase jquery is used because AMD module names are
+// derived from file names, and jQuery is normally delivered in a lowercase
+// file name. Do this after creating the global so that if an AMD module wants
+// to call noConflict to hide this version of jQuery, it will work.
+
+// Note that for maximum portability, libraries that are not jQuery should
+// declare themselves as anonymous modules, and avoid setting a global if an
+// AMD loader is present. jQuery is a special case. For more information, see
+// https://github.com/jrburke/requirejs/wiki/Updating-existing-libraries#wiki-anon
+
+if ( typeof define === "function" && define.amd ) {
+	define( "jquery", [], function() {
+		return jQuery;
+	} );
+}
+
+
+
+var
+
+	// Map over jQuery in case of overwrite
+	_jQuery = window.jQuery,
+
+	// Map over the $ in case of overwrite
+	_$ = window.$;
+
+jQuery.noConflict = function( deep ) {
+	if ( window.$ === jQuery ) {
+		window.$ = _$;
+	}
+
+	if ( deep && window.jQuery === jQuery ) {
+		window.jQuery = _jQuery;
+	}
+
+	return jQuery;
+};
+
+// Expose jQuery and $ identifiers, even in
+// AMD (#7102#comment:10, https://github.com/jquery/jquery/pull/557)
+// and CommonJS for browser emulators (#13566)
+if ( !noGlobal ) {
+	window.jQuery = window.$ = jQuery;
+}
+
+return jQuery;
+}));
diff --git js/lib/jquery/jquery-1.12.1.min.js js/lib/jquery/jquery-1.12.1.min.js
new file mode 100644
index 00000000000..432dc5c9092
--- /dev/null
+++ js/lib/jquery/jquery-1.12.1.min.js
@@ -0,0 +1,2 @@
+!function(e,t){"object"==typeof module&&"object"==typeof module.exports?module.exports=e.document?t(e,!0):function(e){if(!e.document)throw new Error("jQuery requires a window with a document");return t(e)}:t(e)}("undefined"!=typeof window?window:this,function(C,e){function t(e,t){return t.toUpperCase()}var f=[],h=C.document,c=f.slice,m=f.concat,s=f.push,i=f.indexOf,n={},r=n.toString,g=n.hasOwnProperty,v={},o="1.12.1",E=function(e,t){return new E.fn.init(e,t)},a=/^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g,u=/^-ms-/,l=/-([\da-z])/gi;function d(e){var t=!!e&&"length"in e&&e.length,n=E.type(e);return"function"!==n&&!E.isWindow(e)&&("array"===n||0===t||"number"==typeof t&&0<t&&t-1 in e)}E.fn=E.prototype={jquery:o,constructor:E,selector:"",length:0,toArray:function(){return c.call(this)},get:function(e){return null!=e?e<0?this[e+this.length]:this[e]:c.call(this)},pushStack:function(e){var t=E.merge(this.constructor(),e);return t.prevObject=this,t.context=this.context,t},each:function(e){return E.each(this,e)},map:function(n){return this.pushStack(E.map(this,function(e,t){return n.call(e,t,e)}))},slice:function(){return this.pushStack(c.apply(this,arguments))},first:function(){return this.eq(0)},last:function(){return this.eq(-1)},eq:function(e){var t=this.length,n=+e+(e<0?t:0);return this.pushStack(0<=n&&n<t?[this[n]]:[])},end:function(){return this.prevObject||this.constructor()},push:s,sort:f.sort,splice:f.splice},E.extend=E.fn.extend=function(){var e,t,n,r,i,o,a=arguments[0]||{},s=1,u=arguments.length,l=!1;for("boolean"==typeof a&&(l=a,a=arguments[s]||{},s++),"object"==typeof a||E.isFunction(a)||(a={}),s===u&&(a=this,s--);s<u;s++)if(null!=(i=arguments[s]))for(r in i)e=a[r],n=i[r],"__proto__"!==r&&a!==n&&(l&&n&&(E.isPlainObject(n)||(t=E.isArray(n)))?(o=t?(t=!1,e&&E.isArray(e)?e:[]):e&&E.isPlainObject(e)?e:{},a[r]=E.extend(l,o,n)):void 0!==n&&(a[r]=n));return a},E.extend({expando:"jQuery"+(o+Math.random()).replace(/\D/g,""),isReady:!0,error:function(e){throw new Error(e)},noop:function(){},isFunction:function(e){return"function"===E.type(e)},isArray:Array.isArray||function(e){return"array"===E.type(e)},isWindow:function(e){return null!=e&&e==e.window},isNumeric:function(e){var t=e&&e.toString();return!E.isArray(e)&&0<=t-parseFloat(t)+1},isEmptyObject:function(e){var t;for(t in e)return!1;return!0},isPlainObject:function(e){var t;if(!e||"object"!==E.type(e)||e.nodeType||E.isWindow(e))return!1;try{if(e.constructor&&!g.call(e,"constructor")&&!g.call(e.constructor.prototype,"isPrototypeOf"))return!1}catch(e){return!1}if(!v.ownFirst)for(t in e)return g.call(e,t);for(t in e);return void 0===t||g.call(e,t)},type:function(e){return null==e?e+"":"object"==typeof e||"function"==typeof e?n[r.call(e)]||"object":typeof e},globalEval:function(e){e&&E.trim(e)&&(C.execScript||function(e){C.eval.call(C,e)})(e)},camelCase:function(e){return e.replace(u,"ms-").replace(l,t)},nodeName:function(e,t){return e.nodeName&&e.nodeName.toLowerCase()===t.toLowerCase()},each:function(e,t){var n,r=0;if(d(e))for(n=e.length;r<n&&!1!==t.call(e[r],r,e[r]);r++);else for(r in e)if(!1===t.call(e[r],r,e[r]))break;return e},trim:function(e){return null==e?"":(e+"").replace(a,"")},makeArray:function(e,t){var n=t||[];return null!=e&&(d(Object(e))?E.merge(n,"string"==typeof e?[e]:e):s.call(n,e)),n},inArray:function(e,t,n){var r;if(t){if(i)return i.call(t,e,n);for(r=t.length,n=n?n<0?Math.max(0,r+n):n:0;n<r;n++)if(n in t&&t[n]===e)return n}return-1},merge:function(e,t){for(var n=+t.length,r=0,i=e.length;r<n;)e[i++]=t[r++];if(n!=n)for(;void 0!==t[r];)e[i++]=t[r++];return e.length=i,e},grep:function(e,t,n){for(var r=[],i=0,o=e.length,a=!n;i<o;i++)!t(e[i],i)!=a&&r.push(e[i]);return r},map:function(e,t,n){var r,i,o=0,a=[];if(d(e))for(r=e.length;o<r;o++)null!=(i=t(e[o],o,n))&&a.push(i);else for(o in e)null!=(i=t(e[o],o,n))&&a.push(i);return m.apply([],a)},guid:1,proxy:function(e,t){var n,r,i;if("string"==typeof t&&(i=e[t],t=e,e=i),E.isFunction(e))return n=c.call(arguments,2),(r=function(){return e.apply(t||this,n.concat(c.call(arguments)))}).guid=e.guid=e.guid||E.guid++,r},now:function(){return+new Date},support:v}),"function"==typeof Symbol&&(E.fn[Symbol.iterator]=f[Symbol.iterator]),E.each("Boolean Number String Function Array Date RegExp Object Error Symbol".split(" "),function(e,t){n["[object "+t+"]"]=t.toLowerCase()});var p=function(n){function f(e,t,n){var r="0x"+t-65536;return r!=r||n?t:r<0?String.fromCharCode(65536+r):String.fromCharCode(r>>10|55296,1023&r|56320)}function i(){T()}var e,h,b,o,a,m,d,g,w,u,l,T,C,s,E,v,c,p,y,N="sizzle"+ +new Date,x=n.document,k=0,r=0,S=ie(),A=ie(),D=ie(),L=function(e,t){return e===t&&(l=!0),0},j={}.hasOwnProperty,t=[],H=t.pop,q=t.push,_=t.push,M=t.slice,F=function(e,t){for(var n=0,r=e.length;n<r;n++)if(e[n]===t)return n;return-1},O="checked|selected|async|autofocus|autoplay|controls|defer|disabled|hidden|ismap|loop|multiple|open|readonly|required|scoped",R="[\\x20\\t\\r\\n\\f]",P="(?:\\\\.|[\\w-]|[^\\x00-\\xa0])+",B="\\["+R+"*("+P+")(?:"+R+"*([*^$|!~]?=)"+R+"*(?:'((?:\\\\.|[^\\\\'])*)'|\"((?:\\\\.|[^\\\\\"])*)\"|("+P+"))|)"+R+"*\\]",W=":("+P+")(?:\\((('((?:\\\\.|[^\\\\'])*)'|\"((?:\\\\.|[^\\\\\"])*)\")|((?:\\\\.|[^\\\\()[\\]]|"+B+")*)|.*)\\)|)",I=new RegExp(R+"+","g"),$=new RegExp("^"+R+"+|((?:^|[^\\\\])(?:\\\\.)*)"+R+"+$","g"),z=new RegExp("^"+R+"*,"+R+"*"),X=new RegExp("^"+R+"*([>+~]|"+R+")"+R+"*"),U=new RegExp("="+R+"*([^\\]'\"]*?)"+R+"*\\]","g"),V=new RegExp(W),Y=new RegExp("^"+P+"$"),J={ID:new RegExp("^#("+P+")"),CLASS:new RegExp("^\\.("+P+")"),TAG:new RegExp("^("+P+"|[*])"),ATTR:new RegExp("^"+B),PSEUDO:new RegExp("^"+W),CHILD:new RegExp("^:(only|first|last|nth|nth-last)-(child|of-type)(?:\\("+R+"*(even|odd|(([+-]|)(\\d*)n|)"+R+"*(?:([+-]|)"+R+"*(\\d+)|))"+R+"*\\)|)","i"),bool:new RegExp("^(?:"+O+")$","i"),needsContext:new RegExp("^"+R+"*[>+~]|:(even|odd|eq|gt|lt|nth|first|last)(?:\\("+R+"*((?:-\\d)?\\d*)"+R+"*\\)|)(?=[^-]|$)","i")},G=/^(?:input|select|textarea|button)$/i,Q=/^h\d$/i,K=/^[^{]+\{\s*\[native \w/,Z=/^(?:#([\w-]+)|(\w+)|\.([\w-]+))$/,ee=/[+~]/,te=/'|\\/g,ne=new RegExp("\\\\([\\da-f]{1,6}"+R+"?|("+R+")|.)","ig");try{_.apply(t=M.call(x.childNodes),x.childNodes),t[x.childNodes.length].nodeType}catch(e){_={apply:t.length?function(e,t){q.apply(e,M.call(t))}:function(e,t){for(var n=e.length,r=0;e[n++]=t[r++];);e.length=n-1}}}function re(e,t,n,r){var i,o,a,s,u,l,c,f,d=t&&t.ownerDocument,p=t?t.nodeType:9;if(n=n||[],"string"!=typeof e||!e||1!==p&&9!==p&&11!==p)return n;if(!r&&((t?t.ownerDocument||t:x)!==C&&T(t),t=t||C,E)){if(11!==p&&(l=Z.exec(e)))if(i=l[1]){if(9===p){if(!(a=t.getElementById(i)))return n;if(a.id===i)return n.push(a),n}else if(d&&(a=d.getElementById(i))&&y(t,a)&&a.id===i)return n.push(a),n}else{if(l[2])return _.apply(n,t.getElementsByTagName(e)),n;if((i=l[3])&&h.getElementsByClassName&&t.getElementsByClassName)return _.apply(n,t.getElementsByClassName(i)),n}if(h.qsa&&!D[e+" "]&&(!v||!v.test(e))){if(1!==p)d=t,f=e;else if("object"!==t.nodeName.toLowerCase()){for((s=t.getAttribute("id"))?s=s.replace(te,"\\$&"):t.setAttribute("id",s=N),o=(c=m(e)).length,u=Y.test(s)?"#"+s:"[id='"+s+"']";o--;)c[o]=u+" "+he(c[o]);f=c.join(","),d=ee.test(e)&&de(t.parentNode)||t}if(f)try{return _.apply(n,d.querySelectorAll(f)),n}catch(e){}finally{s===N&&t.removeAttribute("id")}}}return g(e.replace($,"$1"),t,n,r)}function ie(){var r=[];return function e(t,n){return r.push(t+" ")>b.cacheLength&&delete e[r.shift()],e[t+" "]=n}}function oe(e){return e[N]=!0,e}function ae(e){var t=C.createElement("div");try{return!!e(t)}catch(e){return!1}finally{t.parentNode&&t.parentNode.removeChild(t),t=null}}function se(e,t){for(var n=e.split("|"),r=n.length;r--;)b.attrHandle[n[r]]=t}function ue(e,t){var n=t&&e,r=n&&1===e.nodeType&&1===t.nodeType&&(~t.sourceIndex||1<<31)-(~e.sourceIndex||1<<31);if(r)return r;if(n)for(;n=n.nextSibling;)if(n===t)return-1;return e?1:-1}function le(t){return function(e){return"input"===e.nodeName.toLowerCase()&&e.type===t}}function ce(n){return function(e){var t=e.nodeName.toLowerCase();return("input"===t||"button"===t)&&e.type===n}}function fe(a){return oe(function(o){return o=+o,oe(function(e,t){for(var n,r=a([],e.length,o),i=r.length;i--;)e[n=r[i]]&&(e[n]=!(t[n]=e[n]))})})}function de(e){return e&&void 0!==e.getElementsByTagName&&e}for(e in h=re.support={},a=re.isXML=function(e){var t=e&&(e.ownerDocument||e).documentElement;return!!t&&"HTML"!==t.nodeName},T=re.setDocument=function(e){var t,n,r=e?e.ownerDocument||e:x;return r!==C&&9===r.nodeType&&r.documentElement&&(s=(C=r).documentElement,E=!a(C),(n=C.defaultView)&&n.top!==n&&(n.addEventListener?n.addEventListener("unload",i,!1):n.attachEvent&&n.attachEvent("onunload",i)),h.attributes=ae(function(e){return e.className="i",!e.getAttribute("className")}),h.getElementsByTagName=ae(function(e){return e.appendChild(C.createComment("")),!e.getElementsByTagName("*").length}),h.getElementsByClassName=K.test(C.getElementsByClassName),h.getById=ae(function(e){return s.appendChild(e).id=N,!C.getElementsByName||!C.getElementsByName(N).length}),h.getById?(b.find.ID=function(e,t){if(void 0!==t.getElementById&&E){var n=t.getElementById(e);return n?[n]:[]}},b.filter.ID=function(e){var t=e.replace(ne,f);return function(e){return e.getAttribute("id")===t}}):(delete b.find.ID,b.filter.ID=function(e){var n=e.replace(ne,f);return function(e){var t=void 0!==e.getAttributeNode&&e.getAttributeNode("id");return t&&t.value===n}}),b.find.TAG=h.getElementsByTagName?function(e,t){return void 0!==t.getElementsByTagName?t.getElementsByTagName(e):h.qsa?t.querySelectorAll(e):void 0}:function(e,t){var n,r=[],i=0,o=t.getElementsByTagName(e);if("*"!==e)return o;for(;n=o[i++];)1===n.nodeType&&r.push(n);return r},b.find.CLASS=h.getElementsByClassName&&function(e,t){if(void 0!==t.getElementsByClassName&&E)return t.getElementsByClassName(e)},c=[],v=[],(h.qsa=K.test(C.querySelectorAll))&&(ae(function(e){s.appendChild(e).innerHTML="<a id='"+N+"'></a><select id='"+N+"-\r\\' msallowcapture=''><option selected=''></option></select>",e.querySelectorAll("[msallowcapture^='']").length&&v.push("[*^$]="+R+"*(?:''|\"\")"),e.querySelectorAll("[selected]").length||v.push("\\["+R+"*(?:value|"+O+")"),e.querySelectorAll("[id~="+N+"-]").length||v.push("~="),e.querySelectorAll(":checked").length||v.push(":checked"),e.querySelectorAll("a#"+N+"+*").length||v.push(".#.+[+~]")}),ae(function(e){var t=C.createElement("input");t.setAttribute("type","hidden"),e.appendChild(t).setAttribute("name","D"),e.querySelectorAll("[name=d]").length&&v.push("name"+R+"*[*^$|!~]?="),e.querySelectorAll(":enabled").length||v.push(":enabled",":disabled"),e.querySelectorAll("*,:x"),v.push(",.*:")})),(h.matchesSelector=K.test(p=s.matches||s.webkitMatchesSelector||s.mozMatchesSelector||s.oMatchesSelector||s.msMatchesSelector))&&ae(function(e){h.disconnectedMatch=p.call(e,"div"),p.call(e,"[s!='']:x"),c.push("!=",W)}),v=v.length&&new RegExp(v.join("|")),c=c.length&&new RegExp(c.join("|")),t=K.test(s.compareDocumentPosition),y=t||K.test(s.contains)?function(e,t){var n=9===e.nodeType?e.documentElement:e,r=t&&t.parentNode;return e===r||!(!r||1!==r.nodeType||!(n.contains?n.contains(r):e.compareDocumentPosition&&16&e.compareDocumentPosition(r)))}:function(e,t){if(t)for(;t=t.parentNode;)if(t===e)return!0;return!1},L=t?function(e,t){if(e===t)return l=!0,0;var n=!e.compareDocumentPosition-!t.compareDocumentPosition;return n||(1&(n=(e.ownerDocument||e)===(t.ownerDocument||t)?e.compareDocumentPosition(t):1)||!h.sortDetached&&t.compareDocumentPosition(e)===n?e===C||e.ownerDocument===x&&y(x,e)?-1:t===C||t.ownerDocument===x&&y(x,t)?1:u?F(u,e)-F(u,t):0:4&n?-1:1)}:function(e,t){if(e===t)return l=!0,0;var n,r=0,i=e.parentNode,o=t.parentNode,a=[e],s=[t];if(!i||!o)return e===C?-1:t===C?1:i?-1:o?1:u?F(u,e)-F(u,t):0;if(i===o)return ue(e,t);for(n=e;n=n.parentNode;)a.unshift(n);for(n=t;n=n.parentNode;)s.unshift(n);for(;a[r]===s[r];)r++;return r?ue(a[r],s[r]):a[r]===x?-1:s[r]===x?1:0}),C},re.matches=function(e,t){return re(e,null,null,t)},re.matchesSelector=function(e,t){if((e.ownerDocument||e)!==C&&T(e),t=t.replace(U,"='$1']"),h.matchesSelector&&E&&!D[t+" "]&&(!c||!c.test(t))&&(!v||!v.test(t)))try{var n=p.call(e,t);if(n||h.disconnectedMatch||e.document&&11!==e.document.nodeType)return n}catch(e){}return 0<re(t,C,null,[e]).length},re.contains=function(e,t){return(e.ownerDocument||e)!==C&&T(e),y(e,t)},re.attr=function(e,t){(e.ownerDocument||e)!==C&&T(e);var n=b.attrHandle[t.toLowerCase()],r=n&&j.call(b.attrHandle,t.toLowerCase())?n(e,t,!E):void 0;return void 0!==r?r:h.attributes||!E?e.getAttribute(t):(r=e.getAttributeNode(t))&&r.specified?r.value:null},re.error=function(e){throw new Error("Syntax error, unrecognized expression: "+e)},re.uniqueSort=function(e){var t,n=[],r=0,i=0;if(l=!h.detectDuplicates,u=!h.sortStable&&e.slice(0),e.sort(L),l){for(;t=e[i++];)t===e[i]&&(r=n.push(i));for(;r--;)e.splice(n[r],1)}return u=null,e},o=re.getText=function(e){var t,n="",r=0,i=e.nodeType;if(i){if(1===i||9===i||11===i){if("string"==typeof e.textContent)return e.textContent;for(e=e.firstChild;e;e=e.nextSibling)n+=o(e)}else if(3===i||4===i)return e.nodeValue}else for(;t=e[r++];)n+=o(t);return n},(b=re.selectors={cacheLength:50,createPseudo:oe,match:J,attrHandle:{},find:{},relative:{">":{dir:"parentNode",first:!0}," ":{dir:"parentNode"},"+":{dir:"previousSibling",first:!0},"~":{dir:"previousSibling"}},preFilter:{ATTR:function(e){return e[1]=e[1].replace(ne,f),e[3]=(e[3]||e[4]||e[5]||"").replace(ne,f),"~="===e[2]&&(e[3]=" "+e[3]+" "),e.slice(0,4)},CHILD:function(e){return e[1]=e[1].toLowerCase(),"nth"===e[1].slice(0,3)?(e[3]||re.error(e[0]),e[4]=+(e[4]?e[5]+(e[6]||1):2*("even"===e[3]||"odd"===e[3])),e[5]=+(e[7]+e[8]||"odd"===e[3])):e[3]&&re.error(e[0]),e},PSEUDO:function(e){var t,n=!e[6]&&e[2];return J.CHILD.test(e[0])?null:(e[3]?e[2]=e[4]||e[5]||"":n&&V.test(n)&&(t=m(n,!0))&&(t=n.indexOf(")",n.length-t)-n.length)&&(e[0]=e[0].slice(0,t),e[2]=n.slice(0,t)),e.slice(0,3))}},filter:{TAG:function(e){var t=e.replace(ne,f).toLowerCase();return"*"===e?function(){return!0}:function(e){return e.nodeName&&e.nodeName.toLowerCase()===t}},CLASS:function(e){var t=S[e+" "];return t||(t=new RegExp("(^|"+R+")"+e+"("+R+"|$)"))&&S(e,function(e){return t.test("string"==typeof e.className&&e.className||void 0!==e.getAttribute&&e.getAttribute("class")||"")})},ATTR:function(n,r,i){return function(e){var t=re.attr(e,n);return null==t?"!="===r:!r||(t+="","="===r?t===i:"!="===r?t!==i:"^="===r?i&&0===t.indexOf(i):"*="===r?i&&-1<t.indexOf(i):"$="===r?i&&t.slice(-i.length)===i:"~="===r?-1<(" "+t.replace(I," ")+" ").indexOf(i):"|="===r&&(t===i||t.slice(0,i.length+1)===i+"-"))}},CHILD:function(h,e,t,m,g){var v="nth"!==h.slice(0,3),y="last"!==h.slice(-4),x="of-type"===e;return 1===m&&0===g?function(e){return!!e.parentNode}:function(e,t,n){var r,i,o,a,s,u,l=v!=y?"nextSibling":"previousSibling",c=e.parentNode,f=x&&e.nodeName.toLowerCase(),d=!n&&!x,p=!1;if(c){if(v){for(;l;){for(a=e;a=a[l];)if(x?a.nodeName.toLowerCase()===f:1===a.nodeType)return!1;u=l="only"===h&&!u&&"nextSibling"}return!0}if(u=[y?c.firstChild:c.lastChild],y&&d){for(p=(s=(r=(i=(o=(a=c)[N]||(a[N]={}))[a.uniqueID]||(o[a.uniqueID]={}))[h]||[])[0]===k&&r[1])&&r[2],a=s&&c.childNodes[s];a=++s&&a&&a[l]||(p=s=0)||u.pop();)if(1===a.nodeType&&++p&&a===e){i[h]=[k,s,p];break}}else if(d&&(p=s=(r=(i=(o=(a=e)[N]||(a[N]={}))[a.uniqueID]||(o[a.uniqueID]={}))[h]||[])[0]===k&&r[1]),!1===p)for(;(a=++s&&a&&a[l]||(p=s=0)||u.pop())&&((x?a.nodeName.toLowerCase()!==f:1!==a.nodeType)||!++p||(d&&((i=(o=a[N]||(a[N]={}))[a.uniqueID]||(o[a.uniqueID]={}))[h]=[k,p]),a!==e)););return(p-=g)===m||p%m==0&&0<=p/m}}},PSEUDO:function(e,o){var t,a=b.pseudos[e]||b.setFilters[e.toLowerCase()]||re.error("unsupported pseudo: "+e);return a[N]?a(o):1<a.length?(t=[e,e,"",o],b.setFilters.hasOwnProperty(e.toLowerCase())?oe(function(e,t){for(var n,r=a(e,o),i=r.length;i--;)e[n=F(e,r[i])]=!(t[n]=r[i])}):function(e){return a(e,0,t)}):a}},pseudos:{not:oe(function(e){var r=[],i=[],s=d(e.replace($,"$1"));return s[N]?oe(function(e,t,n,r){for(var i,o=s(e,null,r,[]),a=e.length;a--;)(i=o[a])&&(e[a]=!(t[a]=i))}):function(e,t,n){return r[0]=e,s(r,null,n,i),r[0]=null,!i.pop()}}),has:oe(function(t){return function(e){return 0<re(t,e).length}}),contains:oe(function(t){return t=t.replace(ne,f),function(e){return-1<(e.textContent||e.innerText||o(e)).indexOf(t)}}),lang:oe(function(n){return Y.test(n||"")||re.error("unsupported lang: "+n),n=n.replace(ne,f).toLowerCase(),function(e){var t;do{if(t=E?e.lang:e.getAttribute("xml:lang")||e.getAttribute("lang"))return(t=t.toLowerCase())===n||0===t.indexOf(n+"-")}while((e=e.parentNode)&&1===e.nodeType);return!1}}),target:function(e){var t=n.location&&n.location.hash;return t&&t.slice(1)===e.id},root:function(e){return e===s},focus:function(e){return e===C.activeElement&&(!C.hasFocus||C.hasFocus())&&!!(e.type||e.href||~e.tabIndex)},enabled:function(e){return!1===e.disabled},disabled:function(e){return!0===e.disabled},checked:function(e){var t=e.nodeName.toLowerCase();return"input"===t&&!!e.checked||"option"===t&&!!e.selected},selected:function(e){return e.parentNode&&e.parentNode.selectedIndex,!0===e.selected},empty:function(e){for(e=e.firstChild;e;e=e.nextSibling)if(e.nodeType<6)return!1;return!0},parent:function(e){return!b.pseudos.empty(e)},header:function(e){return Q.test(e.nodeName)},input:function(e){return G.test(e.nodeName)},button:function(e){var t=e.nodeName.toLowerCase();return"input"===t&&"button"===e.type||"button"===t},text:function(e){var t;return"input"===e.nodeName.toLowerCase()&&"text"===e.type&&(null==(t=e.getAttribute("type"))||"text"===t.toLowerCase())},first:fe(function(){return[0]}),last:fe(function(e,t){return[t-1]}),eq:fe(function(e,t,n){return[n<0?n+t:n]}),even:fe(function(e,t){for(var n=0;n<t;n+=2)e.push(n);return e}),odd:fe(function(e,t){for(var n=1;n<t;n+=2)e.push(n);return e}),lt:fe(function(e,t,n){for(var r=n<0?n+t:n;0<=--r;)e.push(r);return e}),gt:fe(function(e,t,n){for(var r=n<0?n+t:n;++r<t;)e.push(r);return e})}}).pseudos.nth=b.pseudos.eq,{radio:!0,checkbox:!0,file:!0,password:!0,image:!0})b.pseudos[e]=le(e);for(e in{submit:!0,reset:!0})b.pseudos[e]=ce(e);function pe(){}function he(e){for(var t=0,n=e.length,r="";t<n;t++)r+=e[t].value;return r}function me(s,e,t){var u=e.dir,l=t&&"parentNode"===u,c=r++;return e.first?function(e,t,n){for(;e=e[u];)if(1===e.nodeType||l)return s(e,t,n)}:function(e,t,n){var r,i,o,a=[k,c];if(n){for(;e=e[u];)if((1===e.nodeType||l)&&s(e,t,n))return!0}else for(;e=e[u];)if(1===e.nodeType||l){if((r=(i=(o=e[N]||(e[N]={}))[e.uniqueID]||(o[e.uniqueID]={}))[u])&&r[0]===k&&r[1]===c)return a[2]=r[2];if((i[u]=a)[2]=s(e,t,n))return!0}}}function ge(i){return 1<i.length?function(e,t,n){for(var r=i.length;r--;)if(!i[r](e,t,n))return!1;return!0}:i[0]}function ve(e,t,n,r,i){for(var o,a=[],s=0,u=e.length,l=null!=t;s<u;s++)(o=e[s])&&(n&&!n(o,r,i)||(a.push(o),l&&t.push(s)));return a}function ye(p,h,m,g,v,e){return g&&!g[N]&&(g=ye(g)),v&&!v[N]&&(v=ye(v,e)),oe(function(e,t,n,r){var i,o,a,s=[],u=[],l=t.length,c=e||function(e,t,n){for(var r=0,i=t.length;r<i;r++)re(e,t[r],n);return n}(h||"*",n.nodeType?[n]:n,[]),f=!p||!e&&h?c:ve(c,s,p,n,r),d=m?v||(e?p:l||g)?[]:t:f;if(m&&m(f,d,n,r),g)for(i=ve(d,u),g(i,[],n,r),o=i.length;o--;)(a=i[o])&&(d[u[o]]=!(f[u[o]]=a));if(e){if(v||p){if(v){for(i=[],o=d.length;o--;)(a=d[o])&&i.push(f[o]=a);v(null,d=[],i,r)}for(o=d.length;o--;)(a=d[o])&&-1<(i=v?F(e,a):s[o])&&(e[i]=!(t[i]=a))}}else d=ve(d===t?d.splice(l,d.length):d),v?v(null,t,d,r):_.apply(t,d)})}function xe(e){for(var i,t,n,r=e.length,o=b.relative[e[0].type],a=o||b.relative[" "],s=o?1:0,u=me(function(e){return e===i},a,!0),l=me(function(e){return-1<F(i,e)},a,!0),c=[function(e,t,n){var r=!o&&(n||t!==w)||((i=t).nodeType?u:l)(e,t,n);return i=null,r}];s<r;s++)if(t=b.relative[e[s].type])c=[me(ge(c),t)];else{if((t=b.filter[e[s].type].apply(null,e[s].matches))[N]){for(n=++s;n<r&&!b.relative[e[n].type];n++);return ye(1<s&&ge(c),1<s&&he(e.slice(0,s-1).concat({value:" "===e[s-2].type?"*":""})).replace($,"$1"),t,s<n&&xe(e.slice(s,n)),n<r&&xe(e=e.slice(n)),n<r&&he(e))}c.push(t)}return ge(c)}function be(g,v){function e(e,t,n,r,i){var o,a,s,u=0,l="0",c=e&&[],f=[],d=w,p=e||x&&b.find.TAG("*",i),h=k+=null==d?1:Math.random()||.1,m=p.length;for(i&&(w=t===C||t||i);l!==m&&null!=(o=p[l]);l++){if(x&&o){for(a=0,t||o.ownerDocument===C||(T(o),n=!E);s=g[a++];)if(s(o,t||C,n)){r.push(o);break}i&&(k=h)}y&&((o=!s&&o)&&u--,e&&c.push(o))}if(u+=l,y&&l!==u){for(a=0;s=v[a++];)s(c,f,t,n);if(e){if(0<u)for(;l--;)c[l]||f[l]||(f[l]=H.call(r));f=ve(f)}_.apply(r,f),i&&!e&&0<f.length&&1<u+v.length&&re.uniqueSort(r)}return i&&(k=h,w=d),c}var y=0<v.length,x=0<g.length;return y?oe(e):e}return pe.prototype=b.filters=b.pseudos,b.setFilters=new pe,m=re.tokenize=function(e,t){var n,r,i,o,a,s,u,l=A[e+" "];if(l)return t?0:l.slice(0);for(a=e,s=[],u=b.preFilter;a;){for(o in n&&!(r=z.exec(a))||(r&&(a=a.slice(r[0].length)||a),s.push(i=[])),n=!1,(r=X.exec(a))&&(n=r.shift(),i.push({value:n,type:r[0].replace($," ")}),a=a.slice(n.length)),b.filter)!(r=J[o].exec(a))||u[o]&&!(r=u[o](r))||(n=r.shift(),i.push({value:n,type:o,matches:r}),a=a.slice(n.length));if(!n)break}return t?a.length:a?re.error(e):A(e,s).slice(0)},d=re.compile=function(e,t){var n,r=[],i=[],o=D[e+" "];if(!o){for(n=(t=t||m(e)).length;n--;)(o=xe(t[n]))[N]?r.push(o):i.push(o);(o=D(e,be(i,r))).selector=e}return o},g=re.select=function(e,t,n,r){var i,o,a,s,u,l="function"==typeof e&&e,c=!r&&m(e=l.selector||e);if(n=n||[],1===c.length){if(2<(o=c[0]=c[0].slice(0)).length&&"ID"===(a=o[0]).type&&h.getById&&9===t.nodeType&&E&&b.relative[o[1].type]){if(!(t=(b.find.ID(a.matches[0].replace(ne,f),t)||[])[0]))return n;l&&(t=t.parentNode),e=e.slice(o.shift().value.length)}for(i=J.needsContext.test(e)?0:o.length;i--&&(a=o[i],!b.relative[s=a.type]);)if((u=b.find[s])&&(r=u(a.matches[0].replace(ne,f),ee.test(o[0].type)&&de(t.parentNode)||t))){if(o.splice(i,1),!(e=r.length&&he(o)))return _.apply(n,r),n;break}}return(l||d(e,c))(r,t,!E,n,!t||ee.test(e)&&de(t.parentNode)||t),n},h.sortStable=N.split("").sort(L).join("")===N,h.detectDuplicates=!!l,T(),h.sortDetached=ae(function(e){return 1&e.compareDocumentPosition(C.createElement("div"))}),ae(function(e){return e.innerHTML="<a href='#'></a>","#"===e.firstChild.getAttribute("href")})||se("type|href|height|width",function(e,t,n){if(!n)return e.getAttribute(t,"type"===t.toLowerCase()?1:2)}),h.attributes&&ae(function(e){return e.innerHTML="<input/>",e.firstChild.setAttribute("value",""),""===e.firstChild.getAttribute("value")})||se("value",function(e,t,n){if(!n&&"input"===e.nodeName.toLowerCase())return e.defaultValue}),ae(function(e){return null==e.getAttribute("disabled")})||se(O,function(e,t,n){var r;if(!n)return!0===e[t]?t.toLowerCase():(r=e.getAttributeNode(t))&&r.specified?r.value:null}),re}(C);E.find=p,E.expr=p.selectors,E.expr[":"]=E.expr.pseudos,E.uniqueSort=E.unique=p.uniqueSort,E.text=p.getText,E.isXMLDoc=p.isXML,E.contains=p.contains;function y(e,t,n){for(var r=[],i=void 0!==n;(e=e[t])&&9!==e.nodeType;)if(1===e.nodeType){if(i&&E(e).is(n))break;r.push(e)}return r}function x(e,t){for(var n=[];e;e=e.nextSibling)1===e.nodeType&&e!==t&&n.push(e);return n}var b=E.expr.match.needsContext,w=/^<([\w-]+)\s*\/?>(?:<\/\1>|)$/,T=/^.[^:#\[\.,]*$/;function N(e,n,r){if(E.isFunction(n))return E.grep(e,function(e,t){return!!n.call(e,t,e)!==r});if(n.nodeType)return E.grep(e,function(e){return e===n!==r});if("string"==typeof n){if(T.test(n))return E.filter(n,e,r);n=E.filter(n,e)}return E.grep(e,function(e){return-1<E.inArray(e,n)!==r})}E.filter=function(e,t,n){var r=t[0];return n&&(e=":not("+e+")"),1===t.length&&1===r.nodeType?E.find.matchesSelector(r,e)?[r]:[]:E.find.matches(e,E.grep(t,function(e){return 1===e.nodeType}))},E.fn.extend({find:function(e){var t,n=[],r=this,i=r.length;if("string"!=typeof e)return this.pushStack(E(e).filter(function(){for(t=0;t<i;t++)if(E.contains(r[t],this))return!0}));for(t=0;t<i;t++)E.find(e,r[t],n);return(n=this.pushStack(1<i?E.unique(n):n)).selector=this.selector?this.selector+" "+e:e,n},filter:function(e){return this.pushStack(N(this,e||[],!1))},not:function(e){return this.pushStack(N(this,e||[],!0))},is:function(e){return!!N(this,"string"==typeof e&&b.test(e)?E(e):e||[],!1).length}});var k,S=/^(?:\s*(<[\w\W]+>)[^>]*|#([\w-]*))$/;(E.fn.init=function(e,t,n){var r,i;if(!e)return this;if(n=n||k,"string"!=typeof e)return e.nodeType?(this.context=this[0]=e,this.length=1,this):E.isFunction(e)?void 0!==n.ready?n.ready(e):e(E):(void 0!==e.selector&&(this.selector=e.selector,this.context=e.context),E.makeArray(e,this));if(!(r="<"===e.charAt(0)&&">"===e.charAt(e.length-1)&&3<=e.length?[null,e,null]:S.exec(e))||!r[1]&&t)return!t||t.jquery?(t||n).find(e):this.constructor(t).find(e);if(r[1]){if(t=t instanceof E?t[0]:t,E.merge(this,E.parseHTML(r[1],t&&t.nodeType?t.ownerDocument||t:h,!0)),w.test(r[1])&&E.isPlainObject(t))for(r in t)E.isFunction(this[r])?this[r](t[r]):this.attr(r,t[r]);return this}if((i=h.getElementById(r[2]))&&i.parentNode){if(i.id!==r[2])return k.find(e);this.length=1,this[0]=i}return this.context=h,this.selector=e,this}).prototype=E.fn,k=E(h);var A=/^(?:parents|prev(?:Until|All))/,D={children:!0,contents:!0,next:!0,prev:!0};function L(e,t){for(;(e=e[t])&&1!==e.nodeType;);return e}E.fn.extend({has:function(e){var t,n=E(e,this),r=n.length;return this.filter(function(){for(t=0;t<r;t++)if(E.contains(this,n[t]))return!0})},closest:function(e,t){for(var n,r=0,i=this.length,o=[],a=b.test(e)||"string"!=typeof e?E(e,t||this.context):0;r<i;r++)for(n=this[r];n&&n!==t;n=n.parentNode)if(n.nodeType<11&&(a?-1<a.index(n):1===n.nodeType&&E.find.matchesSelector(n,e))){o.push(n);break}return this.pushStack(1<o.length?E.uniqueSort(o):o)},index:function(e){return e?"string"==typeof e?E.inArray(this[0],E(e)):E.inArray(e.jquery?e[0]:e,this):this[0]&&this[0].parentNode?this.first().prevAll().length:-1},add:function(e,t){return this.pushStack(E.uniqueSort(E.merge(this.get(),E(e,t))))},addBack:function(e){return this.add(null==e?this.prevObject:this.prevObject.filter(e))}}),E.each({parent:function(e){var t=e.parentNode;return t&&11!==t.nodeType?t:null},parents:function(e){return y(e,"parentNode")},parentsUntil:function(e,t,n){return y(e,"parentNode",n)},next:function(e){return L(e,"nextSibling")},prev:function(e){return L(e,"previousSibling")},nextAll:function(e){return y(e,"nextSibling")},prevAll:function(e){return y(e,"previousSibling")},nextUntil:function(e,t,n){return y(e,"nextSibling",n)},prevUntil:function(e,t,n){return y(e,"previousSibling",n)},siblings:function(e){return x((e.parentNode||{}).firstChild,e)},children:function(e){return x(e.firstChild)},contents:function(e){return E.nodeName(e,"iframe")?e.contentDocument||e.contentWindow.document:E.merge([],e.childNodes)}},function(r,i){E.fn[r]=function(e,t){var n=E.map(this,i,e);return"Until"!==r.slice(-5)&&(t=e),t&&"string"==typeof t&&(n=E.filter(t,n)),1<this.length&&(D[r]||(n=E.uniqueSort(n)),A.test(r)&&(n=n.reverse())),this.pushStack(n)}});var j,H,q=/\S+/g;function _(){h.addEventListener?(h.removeEventListener("DOMContentLoaded",M),C.removeEventListener("load",M)):(h.detachEvent("onreadystatechange",M),C.detachEvent("onload",M))}function M(){!h.addEventListener&&"load"!==C.event.type&&"complete"!==h.readyState||(_(),E.ready())}for(H in E.Callbacks=function(r){var e,n;r="string"==typeof r?(e=r,n={},E.each(e.match(q)||[],function(e,t){n[t]=!0}),n):E.extend({},r);function i(){for(s=r.once,a=o=!0;l.length;c=-1)for(t=l.shift();++c<u.length;)!1===u[c].apply(t[0],t[1])&&r.stopOnFalse&&(c=u.length,t=!1);r.memory||(t=!1),o=!1,s&&(u=t?[]:"")}var o,t,a,s,u=[],l=[],c=-1,f={add:function(){return u&&(t&&!o&&(c=u.length-1,l.push(t)),function n(e){E.each(e,function(e,t){E.isFunction(t)?r.unique&&f.has(t)||u.push(t):t&&t.length&&"string"!==E.type(t)&&n(t)})}(arguments),t&&!o&&i()),this},remove:function(){return E.each(arguments,function(e,t){for(var n;-1<(n=E.inArray(t,u,n));)u.splice(n,1),n<=c&&c--}),this},has:function(e){return e?-1<E.inArray(e,u):0<u.length},empty:function(){return u=u&&[],this},disable:function(){return s=l=[],u=t="",this},disabled:function(){return!u},lock:function(){return s=!0,t||f.disable(),this},locked:function(){return!!s},fireWith:function(e,t){return s||(t=[e,(t=t||[]).slice?t.slice():t],l.push(t),o||i()),this},fire:function(){return f.fireWith(this,arguments),this},fired:function(){return!!a}};return f},E.extend({Deferred:function(e){var o=[["resolve","done",E.Callbacks("once memory"),"resolved"],["reject","fail",E.Callbacks("once memory"),"rejected"],["notify","progress",E.Callbacks("memory")]],i="pending",a={state:function(){return i},always:function(){return s.done(arguments).fail(arguments),this},then:function(){var i=arguments;return E.Deferred(function(r){E.each(o,function(e,t){var n=E.isFunction(i[e])&&i[e];s[t[1]](function(){var e=n&&n.apply(this,arguments);e&&E.isFunction(e.promise)?e.promise().progress(r.notify).done(r.resolve).fail(r.reject):r[t[0]+"With"](this===a?r.promise():this,n?[e]:arguments)})}),i=null}).promise()},promise:function(e){return null!=e?E.extend(e,a):a}},s={};return a.pipe=a.then,E.each(o,function(e,t){var n=t[2],r=t[3];a[t[1]]=n.add,r&&n.add(function(){i=r},o[1^e][2].disable,o[2][2].lock),s[t[0]]=function(){return s[t[0]+"With"](this===s?a:this,arguments),this},s[t[0]+"With"]=n.fireWith}),a.promise(s),e&&e.call(s,s),s},when:function(e){function t(t,n,r){return function(e){n[t]=this,r[t]=1<arguments.length?c.call(arguments):e,r===i?l.notifyWith(n,r):--u||l.resolveWith(n,r)}}var i,n,r,o=0,a=c.call(arguments),s=a.length,u=1!==s||e&&E.isFunction(e.promise)?s:0,l=1===u?e:E.Deferred();if(1<s)for(i=new Array(s),n=new Array(s),r=new Array(s);o<s;o++)a[o]&&E.isFunction(a[o].promise)?a[o].promise().progress(t(o,n,i)).done(t(o,r,a)).fail(l.reject):--u;return u||l.resolveWith(r,a),l.promise()}}),E.fn.ready=function(e){return E.ready.promise().done(e),this},E.extend({isReady:!1,readyWait:1,holdReady:function(e){e?E.readyWait++:E.ready(!0)},ready:function(e){(!0===e?--E.readyWait:E.isReady)||(E.isReady=!0)!==e&&0<--E.readyWait||(j.resolveWith(h,[E]),E.fn.triggerHandler&&(E(h).triggerHandler("ready"),E(h).off("ready")))}}),E.ready.promise=function(e){if(!j)if(j=E.Deferred(),"complete"===h.readyState||"loading"!==h.readyState&&!h.documentElement.doScroll)C.setTimeout(E.ready);else if(h.addEventListener)h.addEventListener("DOMContentLoaded",M),C.addEventListener("load",M);else{h.attachEvent("onreadystatechange",M),C.attachEvent("onload",M);var n=!1;try{n=null==C.frameElement&&h.documentElement}catch(e){}n&&n.doScroll&&!function t(){if(!E.isReady){try{n.doScroll("left")}catch(e){return C.setTimeout(t,50)}_(),E.ready()}}()}return j.promise(e)},E.ready.promise(),E(v))break;v.ownFirst="0"===H,v.inlineBlockNeedsLayout=!1,E(function(){var e,t,n,r;(n=h.getElementsByTagName("body")[0])&&n.style&&(t=h.createElement("div"),(r=h.createElement("div")).style.cssText="position:absolute;border:0;width:0;height:0;top:0;left:-9999px",n.appendChild(r).appendChild(t),void 0!==t.style.zoom&&(t.style.cssText="display:inline;margin:0;border:0;padding:1px;width:1px;zoom:1",v.inlineBlockNeedsLayout=e=3===t.offsetWidth,e&&(n.style.zoom=1)),n.removeChild(r))}),function(){var e=h.createElement("div");v.deleteExpando=!0;try{delete e.test}catch(e){v.deleteExpando=!1}e=null}();function F(e){var t=E.noData[(e.nodeName+" ").toLowerCase()],n=+e.nodeType||1;return(1===n||9===n)&&(!t||!0!==t&&e.getAttribute("classid")===t)}var O,R=/^(?:\{[\w\W]*\}|\[[\w\W]*\])$/,P=/([A-Z])/g;function B(e,t,n){if(void 0===n&&1===e.nodeType){var r="data-"+t.replace(P,"-$1").toLowerCase();if("string"==typeof(n=e.getAttribute(r))){try{n="true"===n||"false"!==n&&("null"===n?null:+n+""===n?+n:R.test(n)?E.parseJSON(n):n)}catch(e){}E.data(e,t,n)}else n=void 0}return n}function W(e){var t;for(t in e)if(("data"!==t||!E.isEmptyObject(e[t]))&&"toJSON"!==t)return;return 1}function I(e,t,n,r){if(F(e)){var i,o,a=E.expando,s=e.nodeType,u=s?E.cache:e,l=s?e[a]:e[a]&&a;if(l&&u[l]&&(r||u[l].data)||void 0!==n||"string"!=typeof t)return u[l=l||(s?e[a]=f.pop()||E.guid++:a)]||(u[l]=s?{}:{toJSON:E.noop}),"object"!=typeof t&&"function"!=typeof t||(r?u[l]=E.extend(u[l],t):u[l].data=E.extend(u[l].data,t)),o=u[l],r||(o.data||(o.data={}),o=o.data),void 0!==n&&(o[E.camelCase(t)]=n),"string"==typeof t?null==(i=o[t])&&(i=o[E.camelCase(t)]):i=o,i}}function $(e,t,n){if(F(e)){var r,i,o=e.nodeType,a=o?E.cache:e,s=o?e[E.expando]:E.expando;if(a[s]){if(t&&(r=n?a[s]:a[s].data)){i=(t=E.isArray(t)?t.concat(E.map(t,E.camelCase)):t in r||(t=E.camelCase(t))in r?[t]:t.split(" ")).length;for(;i--;)delete r[t[i]];if(n?!W(r):!E.isEmptyObject(r))return}(n||(delete a[s].data,W(a[s])))&&(o?E.cleanData([e],!0):v.deleteExpando||a!=a.window?delete a[s]:a[s]=void 0)}}}E.extend({cache:{},noData:{"applet ":!0,"embed ":!0,"object ":"clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"},hasData:function(e){return!!(e=e.nodeType?E.cache[e[E.expando]]:e[E.expando])&&!W(e)},data:function(e,t,n){return I(e,t,n)},removeData:function(e,t){return $(e,t)},_data:function(e,t,n){return I(e,t,n,!0)},_removeData:function(e,t){return $(e,t,!0)}}),E.fn.extend({data:function(e,t){var n,r,i,o=this[0],a=o&&o.attributes;if(void 0!==e)return"object"==typeof e?this.each(function(){E.data(this,e)}):1<arguments.length?this.each(function(){E.data(this,e,t)}):o?B(o,e,E.data(o,e)):void 0;if(this.length&&(i=E.data(o),1===o.nodeType&&!E._data(o,"parsedAttrs"))){for(n=a.length;n--;)a[n]&&0===(r=a[n].name).indexOf("data-")&&B(o,r=E.camelCase(r.slice(5)),i[r]);E._data(o,"parsedAttrs",!0)}return i},removeData:function(e){return this.each(function(){E.removeData(this,e)})}}),E.extend({queue:function(e,t,n){var r;if(e)return t=(t||"fx")+"queue",r=E._data(e,t),n&&(!r||E.isArray(n)?r=E._data(e,t,E.makeArray(n)):r.push(n)),r||[]},dequeue:function(e,t){t=t||"fx";var n=E.queue(e,t),r=n.length,i=n.shift(),o=E._queueHooks(e,t);"inprogress"===i&&(i=n.shift(),r--),i&&("fx"===t&&n.unshift("inprogress"),delete o.stop,i.call(e,function(){E.dequeue(e,t)},o)),!r&&o&&o.empty.fire()},_queueHooks:function(e,t){var n=t+"queueHooks";return E._data(e,n)||E._data(e,n,{empty:E.Callbacks("once memory").add(function(){E._removeData(e,t+"queue"),E._removeData(e,n)})})}}),E.fn.extend({queue:function(t,n){var e=2;return"string"!=typeof t&&(n=t,t="fx",e--),arguments.length<e?E.queue(this[0],t):void 0===n?this:this.each(function(){var e=E.queue(this,t,n);E._queueHooks(this,t),"fx"===t&&"inprogress"!==e[0]&&E.dequeue(this,t)})},dequeue:function(e){return this.each(function(){E.dequeue(this,e)})},clearQueue:function(e){return this.queue(e||"fx",[])},promise:function(e,t){function n(){--i||o.resolveWith(a,[a])}var r,i=1,o=E.Deferred(),a=this,s=this.length;for("string"!=typeof e&&(t=e,e=void 0),e=e||"fx";s--;)(r=E._data(a[s],e+"queueHooks"))&&r.empty&&(i++,r.empty.add(n));return n(),o.promise(t)}}),v.shrinkWrapBlocks=function(){return null!=O?O:(O=!1,(t=h.getElementsByTagName("body")[0])&&t.style?(e=h.createElement("div"),(n=h.createElement("div")).style.cssText="position:absolute;border:0;width:0;height:0;top:0;left:-9999px",t.appendChild(n).appendChild(e),void 0!==e.style.zoom&&(e.style.cssText="-webkit-box-sizing:content-box;-moz-box-sizing:content-box;box-sizing:content-box;display:block;margin:0;border:0;padding:1px;width:1px;zoom:1",e.appendChild(h.createElement("div")).style.width="5px",O=3!==e.offsetWidth),t.removeChild(n),O):void 0);var e,t,n};function z(e,t){return e=t||e,"none"===E.css(e,"display")||!E.contains(e.ownerDocument,e)}var X=/[+-]?(?:\d*\.|)\d+(?:[eE][+-]?\d+|)/.source,U=new RegExp("^(?:([+-])=|)("+X+")([a-z%]*)$","i"),V=["Top","Right","Bottom","Left"];function Y(e,t,n,r){var i,o=1,a=20,s=r?function(){return r.cur()}:function(){return E.css(e,t,"")},u=s(),l=n&&n[3]||(E.cssNumber[t]?"":"px"),c=(E.cssNumber[t]||"px"!==l&&+u)&&U.exec(E.css(e,t));if(c&&c[3]!==l)for(l=l||c[3],n=n||[],c=+u||1;c/=o=o||".5",E.style(e,t,c+l),o!==(o=s()/u)&&1!==o&&--a;);return n&&(c=+c||+u||0,i=n[1]?c+(n[1]+1)*n[2]:+n[2],r&&(r.unit=l,r.start=c,r.end=i)),i}var J,G,Q,K=function(e,t,n,r,i,o,a){var s=0,u=e.length,l=null==n;if("object"===E.type(n))for(s in i=!0,n)K(e,t,s,n[s],!0,o,a);else if(void 0!==r&&(i=!0,E.isFunction(r)||(a=!0),l&&(t=a?(t.call(e,r),null):(l=t,function(e,t,n){return l.call(E(e),n)})),t))for(;s<u;s++)t(e[s],n,a?r:r.call(e[s],s,t(e[s],n)));return i?e:l?t.call(e):u?t(e[0],n):o},Z=/^(?:checkbox|radio)$/i,ee=/<([\w:-]+)/,te=/^$|\/(?:java|ecma)script/i,ne=/^\s+/,re="abbr|article|aside|audio|bdi|canvas|data|datalist|details|dialog|figcaption|figure|footer|header|hgroup|main|mark|meter|nav|output|picture|progress|section|summary|template|time|video";function ie(e){var t=re.split("|"),n=e.createDocumentFragment();if(n.createElement)for(;t.length;)n.createElement(t.pop());return n}J=h.createElement("div"),G=h.createDocumentFragment(),Q=h.createElement("input"),J.innerHTML="  <link/><table></table><a href='/a'>a</a><input type='checkbox'/>",v.leadingWhitespace=3===J.firstChild.nodeType,v.tbody=!J.getElementsByTagName("tbody").length,v.htmlSerialize=!!J.getElementsByTagName("link").length,v.html5Clone="<:nav></:nav>"!==h.createElement("nav").cloneNode(!0).outerHTML,Q.type="checkbox",Q.checked=!0,G.appendChild(Q),v.appendChecked=Q.checked,J.innerHTML="<textarea>x</textarea>",v.noCloneChecked=!!J.cloneNode(!0).lastChild.defaultValue,G.appendChild(J),(Q=h.createElement("input")).setAttribute("type","radio"),Q.setAttribute("checked","checked"),Q.setAttribute("name","t"),J.appendChild(Q),v.checkClone=J.cloneNode(!0).cloneNode(!0).lastChild.checked,v.noCloneEvent=!!J.addEventListener,J[E.expando]=1,v.attributes=!J.getAttribute(E.expando);var oe={option:[1,"<select multiple='multiple'>","</select>"],legend:[1,"<fieldset>","</fieldset>"],area:[1,"<map>","</map>"],param:[1,"<object>","</object>"],thead:[1,"<table>","</table>"],tr:[2,"<table><tbody>","</tbody></table>"],col:[2,"<table><tbody></tbody><colgroup>","</colgroup></table>"],td:[3,"<table><tbody><tr>","</tr></tbody></table>"],_default:v.htmlSerialize?[0,"",""]:[1,"X<div>","</div>"]};function ae(e,t){var n,r,i=0,o=void 0!==e.getElementsByTagName?e.getElementsByTagName(t||"*"):void 0!==e.querySelectorAll?e.querySelectorAll(t||"*"):void 0;if(!o)for(o=[],n=e.childNodes||e;null!=(r=n[i]);i++)!t||E.nodeName(r,t)?o.push(r):E.merge(o,ae(r,t));return void 0===t||t&&E.nodeName(e,t)?E.merge([e],o):o}function se(e,t){for(var n,r=0;null!=(n=e[r]);r++)E._data(n,"globalEval",!t||E._data(t[r],"globalEval"))}oe.optgroup=oe.option,oe.tbody=oe.tfoot=oe.colgroup=oe.caption=oe.thead,oe.th=oe.td;var ue=/<|&#?\w+;/,le=/<tbody/i;function ce(e){Z.test(e.type)&&(e.defaultChecked=e.checked)}function fe(e,t,n,r,i){for(var o,a,s,u,l,c,f,d=e.length,p=ie(t),h=[],m=0;m<d;m++)if((a=e[m])||0===a)if("object"===E.type(a))E.merge(h,a.nodeType?[a]:a);else if(ue.test(a)){for(u=u||p.appendChild(t.createElement("div")),l=(ee.exec(a)||["",""])[1].toLowerCase(),f=oe[l]||oe._default,u.innerHTML=f[1]+E.htmlPrefilter(a)+f[2],o=f[0];o--;)u=u.lastChild;if(!v.leadingWhitespace&&ne.test(a)&&h.push(t.createTextNode(ne.exec(a)[0])),!v.tbody)for(o=(a="table"!==l||le.test(a)?"<table>"!==f[1]||le.test(a)?0:u:u.firstChild)&&a.childNodes.length;o--;)E.nodeName(c=a.childNodes[o],"tbody")&&!c.childNodes.length&&a.removeChild(c);for(E.merge(h,u.childNodes),u.textContent="";u.firstChild;)u.removeChild(u.firstChild);u=p.lastChild}else h.push(t.createTextNode(a));for(u&&p.removeChild(u),v.appendChecked||E.grep(ae(h,"input"),ce),m=0;a=h[m++];)if(r&&-1<E.inArray(a,r))i&&i.push(a);else if(s=E.contains(a.ownerDocument,a),u=ae(p.appendChild(a),"script"),s&&se(u),n)for(o=0;a=u[o++];)te.test(a.type||"")&&n.push(a);return u=null,p}!function(){var e,t,n=h.createElement("div");for(e in{submit:!0,change:!0,focusin:!0})t="on"+e,(v[e]=t in C)||(n.setAttribute(t,"t"),v[e]=!1===n.attributes[t].expando);n=null}();var de=/^(?:input|select|textarea)$/i,pe=/^key/,he=/^(?:mouse|pointer|contextmenu|drag|drop)|click/,me=/^(?:focusinfocus|focusoutblur)$/,ge=/^([^.]*)(?:\.(.+)|)/;function ve(){return!0}function ye(){return!1}function xe(){try{return h.activeElement}catch(e){}}function be(e,t,n,r,i,o){var a,s;if("object"==typeof t){for(s in"string"!=typeof n&&(r=r||n,n=void 0),t)be(e,s,n,r,t[s],o);return e}if(null==r&&null==i?(i=n,r=n=void 0):null==i&&("string"==typeof n?(i=r,r=void 0):(i=r,r=n,n=void 0)),!1===i)i=ye;else if(!i)return e;return 1===o&&(a=i,(i=function(e){return E().off(e),a.apply(this,arguments)}).guid=a.guid||(a.guid=E.guid++)),e.each(function(){E.event.add(this,t,i,r,n)})}E.event={global:{},add:function(e,t,n,r,i){var o,a,s,u,l,c,f,d,p,h,m,g=E._data(e);if(g){for(n.handler&&(n=(u=n).handler,i=u.selector),n.guid||(n.guid=E.guid++),(a=g.events)||(a=g.events={}),(c=g.handle)||((c=g.handle=function(e){return void 0===E||e&&E.event.triggered===e.type?void 0:E.event.dispatch.apply(c.elem,arguments)}).elem=e),s=(t=(t||"").match(q)||[""]).length;s--;)p=m=(o=ge.exec(t[s])||[])[1],h=(o[2]||"").split(".").sort(),p&&(l=E.event.special[p]||{},p=(i?l.delegateType:l.bindType)||p,l=E.event.special[p]||{},f=E.extend({type:p,origType:m,data:r,handler:n,guid:n.guid,selector:i,needsContext:i&&E.expr.match.needsContext.test(i),namespace:h.join(".")},u),(d=a[p])||((d=a[p]=[]).delegateCount=0,l.setup&&!1!==l.setup.call(e,r,h,c)||(e.addEventListener?e.addEventListener(p,c,!1):e.attachEvent&&e.attachEvent("on"+p,c))),l.add&&(l.add.call(e,f),f.handler.guid||(f.handler.guid=n.guid)),i?d.splice(d.delegateCount++,0,f):d.push(f),E.event.global[p]=!0);e=null}},remove:function(e,t,n,r,i){var o,a,s,u,l,c,f,d,p,h,m,g=E.hasData(e)&&E._data(e);if(g&&(c=g.events)){for(l=(t=(t||"").match(q)||[""]).length;l--;)if(p=m=(s=ge.exec(t[l])||[])[1],h=(s[2]||"").split(".").sort(),p){for(f=E.event.special[p]||{},d=c[p=(r?f.delegateType:f.bindType)||p]||[],s=s[2]&&new RegExp("(^|\\.)"+h.join("\\.(?:.*\\.|)")+"(\\.|$)"),u=o=d.length;o--;)a=d[o],!i&&m!==a.origType||n&&n.guid!==a.guid||s&&!s.test(a.namespace)||r&&r!==a.selector&&("**"!==r||!a.selector)||(d.splice(o,1),a.selector&&d.delegateCount--,f.remove&&f.remove.call(e,a));u&&!d.length&&(f.teardown&&!1!==f.teardown.call(e,h,g.handle)||E.removeEvent(e,p,g.handle),delete c[p])}else for(p in c)E.event.remove(e,p+t[l],n,r,!0);E.isEmptyObject(c)&&(delete g.handle,E._removeData(e,"events"))}},trigger:function(e,t,n,r){var i,o,a,s,u,l,c,f=[n||h],d=g.call(e,"type")?e.type:e,p=g.call(e,"namespace")?e.namespace.split("."):[];if(a=l=n=n||h,3!==n.nodeType&&8!==n.nodeType&&!me.test(d+E.event.triggered)&&(-1<d.indexOf(".")&&(d=(p=d.split(".")).shift(),p.sort()),o=d.indexOf(":")<0&&"on"+d,(e=e[E.expando]?e:new E.Event(d,"object"==typeof e&&e)).isTrigger=r?2:3,e.namespace=p.join("."),e.rnamespace=e.namespace?new RegExp("(^|\\.)"+p.join("\\.(?:.*\\.|)")+"(\\.|$)"):null,e.result=void 0,e.target||(e.target=n),t=null==t?[e]:E.makeArray(t,[e]),u=E.event.special[d]||{},r||!u.trigger||!1!==u.trigger.apply(n,t))){if(!r&&!u.noBubble&&!E.isWindow(n)){for(s=u.delegateType||d,me.test(s+d)||(a=a.parentNode);a;a=a.parentNode)f.push(a),l=a;l===(n.ownerDocument||h)&&f.push(l.defaultView||l.parentWindow||C)}for(c=0;(a=f[c++])&&!e.isPropagationStopped();)e.type=1<c?s:u.bindType||d,(i=(E._data(a,"events")||{})[e.type]&&E._data(a,"handle"))&&i.apply(a,t),(i=o&&a[o])&&i.apply&&F(a)&&(e.result=i.apply(a,t),!1===e.result&&e.preventDefault());if(e.type=d,!r&&!e.isDefaultPrevented()&&(!u._default||!1===u._default.apply(f.pop(),t))&&F(n)&&o&&n[d]&&!E.isWindow(n)){(l=n[o])&&(n[o]=null),E.event.triggered=d;try{n[d]()}catch(e){}E.event.triggered=void 0,l&&(n[o]=l)}return e.result}},dispatch:function(e){e=E.event.fix(e);var t,n,r,i,o,a,s=c.call(arguments),u=(E._data(this,"events")||{})[e.type]||[],l=E.event.special[e.type]||{};if((s[0]=e).delegateTarget=this,!l.preDispatch||!1!==l.preDispatch.call(this,e)){for(a=E.event.handlers.call(this,e,u),t=0;(i=a[t++])&&!e.isPropagationStopped();)for(e.currentTarget=i.elem,n=0;(o=i.handlers[n++])&&!e.isImmediatePropagationStopped();)e.rnamespace&&!e.rnamespace.test(o.namespace)||(e.handleObj=o,e.data=o.data,void 0!==(r=((E.event.special[o.origType]||{}).handle||o.handler).apply(i.elem,s))&&!1===(e.result=r)&&(e.preventDefault(),e.stopPropagation()));return l.postDispatch&&l.postDispatch.call(this,e),e.result}},handlers:function(e,t){var n,r,i,o,a=[],s=t.delegateCount,u=e.target;if(s&&u.nodeType&&("click"!==e.type||isNaN(e.button)||e.button<1))for(;u!=this;u=u.parentNode||this)if(1===u.nodeType&&(!0!==u.disabled||"click"!==e.type)){for(r=[],n=0;n<s;n++)void 0===r[i=(o=t[n]).selector+" "]&&(r[i]=o.needsContext?-1<E(i,this).index(u):E.find(i,this,null,[u]).length),r[i]&&r.push(o);r.length&&a.push({elem:u,handlers:r})}return s<t.length&&a.push({elem:this,handlers:t.slice(s)}),a},fix:function(e){if(e[E.expando])return e;var t,n,r,i=e.type,o=e,a=this.fixHooks[i];for(a||(this.fixHooks[i]=a=he.test(i)?this.mouseHooks:pe.test(i)?this.keyHooks:{}),r=a.props?this.props.concat(a.props):this.props,e=new E.Event(o),t=r.length;t--;)e[n=r[t]]=o[n];return e.target||(e.target=o.srcElement||h),3===e.target.nodeType&&(e.target=e.target.parentNode),e.metaKey=!!e.metaKey,a.filter?a.filter(e,o):e},props:"altKey bubbles cancelable ctrlKey currentTarget detail eventPhase metaKey relatedTarget shiftKey target timeStamp view which".split(" "),fixHooks:{},keyHooks:{props:"char charCode key keyCode".split(" "),filter:function(e,t){return null==e.which&&(e.which=null!=t.charCode?t.charCode:t.keyCode),e}},mouseHooks:{props:"button buttons clientX clientY fromElement offsetX offsetY pageX pageY screenX screenY toElement".split(" "),filter:function(e,t){var n,r,i,o=t.button,a=t.fromElement;return null==e.pageX&&null!=t.clientX&&(i=(r=e.target.ownerDocument||h).documentElement,n=r.body,e.pageX=t.clientX+(i&&i.scrollLeft||n&&n.scrollLeft||0)-(i&&i.clientLeft||n&&n.clientLeft||0),e.pageY=t.clientY+(i&&i.scrollTop||n&&n.scrollTop||0)-(i&&i.clientTop||n&&n.clientTop||0)),!e.relatedTarget&&a&&(e.relatedTarget=a===e.target?t.toElement:a),e.which||void 0===o||(e.which=1&o?1:2&o?3:4&o?2:0),e}},special:{load:{noBubble:!0},focus:{trigger:function(){if(this!==xe()&&this.focus)try{return this.focus(),!1}catch(e){}},delegateType:"focusin"},blur:{trigger:function(){if(this===xe()&&this.blur)return this.blur(),!1},delegateType:"focusout"},click:{trigger:function(){if(E.nodeName(this,"input")&&"checkbox"===this.type&&this.click)return this.click(),!1},_default:function(e){return E.nodeName(e.target,"a")}},beforeunload:{postDispatch:function(e){void 0!==e.result&&e.originalEvent&&(e.originalEvent.returnValue=e.result)}}},simulate:function(e,t,n){var r=E.extend(new E.Event,n,{type:e,isSimulated:!0});E.event.trigger(r,null,t),r.isDefaultPrevented()&&n.preventDefault()}},E.removeEvent=h.removeEventListener?function(e,t,n){e.removeEventListener&&e.removeEventListener(t,n)}:function(e,t,n){var r="on"+t;e.detachEvent&&(void 0===e[r]&&(e[r]=null),e.detachEvent(r,n))},E.Event=function(e,t){if(!(this instanceof E.Event))return new E.Event(e,t);e&&e.type?(this.originalEvent=e,this.type=e.type,this.isDefaultPrevented=e.defaultPrevented||void 0===e.defaultPrevented&&!1===e.returnValue?ve:ye):this.type=e,t&&E.extend(this,t),this.timeStamp=e&&e.timeStamp||E.now(),this[E.expando]=!0},E.Event.prototype={constructor:E.Event,isDefaultPrevented:ye,isPropagationStopped:ye,isImmediatePropagationStopped:ye,preventDefault:function(){var e=this.originalEvent;this.isDefaultPrevented=ve,e&&(e.preventDefault?e.preventDefault():e.returnValue=!1)},stopPropagation:function(){var e=this.originalEvent;this.isPropagationStopped=ve,e&&!this.isSimulated&&(e.stopPropagation&&e.stopPropagation(),e.cancelBubble=!0)},stopImmediatePropagation:function(){var e=this.originalEvent;this.isImmediatePropagationStopped=ve,e&&e.stopImmediatePropagation&&e.stopImmediatePropagation(),this.stopPropagation()}},E.each({mouseenter:"mouseover",mouseleave:"mouseout",pointerenter:"pointerover",pointerleave:"pointerout"},function(e,i){E.event.special[e]={delegateType:i,bindType:i,handle:function(e){var t,n=e.relatedTarget,r=e.handleObj;return n&&(n===this||E.contains(this,n))||(e.type=r.origType,t=r.handler.apply(this,arguments),e.type=i),t}}}),v.submit||(E.event.special.submit={setup:function(){if(E.nodeName(this,"form"))return!1;E.event.add(this,"click._submit keypress._submit",function(e){var t=e.target,n=E.nodeName(t,"input")||E.nodeName(t,"button")?E.prop(t,"form"):void 0;n&&!E._data(n,"submit")&&(E.event.add(n,"submit._submit",function(e){e._submitBubble=!0}),E._data(n,"submit",!0))})},postDispatch:function(e){e._submitBubble&&(delete e._submitBubble,this.parentNode&&!e.isTrigger&&E.event.simulate("submit",this.parentNode,e))},teardown:function(){if(E.nodeName(this,"form"))return!1;E.event.remove(this,"._submit")}}),v.change||(E.event.special.change={setup:function(){if(de.test(this.nodeName))return"checkbox"!==this.type&&"radio"!==this.type||(E.event.add(this,"propertychange._change",function(e){"checked"===e.originalEvent.propertyName&&(this._justChanged=!0)}),E.event.add(this,"click._change",function(e){this._justChanged&&!e.isTrigger&&(this._justChanged=!1),E.event.simulate("change",this,e)})),!1;E.event.add(this,"beforeactivate._change",function(e){var t=e.target;de.test(t.nodeName)&&!E._data(t,"change")&&(E.event.add(t,"change._change",function(e){!this.parentNode||e.isSimulated||e.isTrigger||E.event.simulate("change",this.parentNode,e)}),E._data(t,"change",!0))})},handle:function(e){var t=e.target;if(this!==t||e.isSimulated||e.isTrigger||"radio"!==t.type&&"checkbox"!==t.type)return e.handleObj.handler.apply(this,arguments)},teardown:function(){return E.event.remove(this,"._change"),!de.test(this.nodeName)}}),v.focusin||E.each({focus:"focusin",blur:"focusout"},function(n,r){function i(e){E.event.simulate(r,e.target,E.event.fix(e))}E.event.special[r]={setup:function(){var e=this.ownerDocument||this,t=E._data(e,r);t||e.addEventListener(n,i,!0),E._data(e,r,(t||0)+1)},teardown:function(){var e=this.ownerDocument||this,t=E._data(e,r)-1;t?E._data(e,r,t):(e.removeEventListener(n,i,!0),E._removeData(e,r))}}}),E.fn.extend({on:function(e,t,n,r){return be(this,e,t,n,r)},one:function(e,t,n,r){return be(this,e,t,n,r,1)},off:function(e,t,n){var r,i;if(e&&e.preventDefault&&e.handleObj)return r=e.handleObj,E(e.delegateTarget).off(r.namespace?r.origType+"."+r.namespace:r.origType,r.selector,r.handler),this;if("object"!=typeof e)return!1!==t&&"function"!=typeof t||(n=t,t=void 0),!1===n&&(n=ye),this.each(function(){E.event.remove(this,e,n,t)});for(i in e)this.off(i,t,e[i]);return this},trigger:function(e,t){return this.each(function(){E.event.trigger(e,t,this)})},triggerHandler:function(e,t){var n=this[0];if(n)return E.event.trigger(e,t,n,!0)}});var we=/ jQuery\d+="(?:null|\d+)"/g,Te=new RegExp("<(?:"+re+")[\\s/>]","i"),Ce=/<(?!area|br|col|embed|hr|img|input|link|meta|param)(([\w:-]+)[^>]*)\/>/gi,Ee=/<script|<style|<link/i,Ne=/checked\s*(?:[^=]|=\s*.checked.)/i,ke=/^true\/(.*)/,Se=/^\s*<!(?:\[CDATA\[|--)|(?:\]\]|--)>\s*$/g,Ae=ie(h).appendChild(h.createElement("div"));function De(e,t){return E.nodeName(e,"table")&&E.nodeName(11!==t.nodeType?t:t.firstChild,"tr")?e.getElementsByTagName("tbody")[0]||e.appendChild(e.ownerDocument.createElement("tbody")):e}function Le(e){return e.type=(null!==E.find.attr(e,"type"))+"/"+e.type,e}function je(e){var t=ke.exec(e.type);return t?e.type=t[1]:e.removeAttribute("type"),e}function He(e,t){if(1===t.nodeType&&E.hasData(e)){var n,r,i,o=E._data(e),a=E._data(t,o),s=o.events;if(s)for(n in delete a.handle,a.events={},s)for(r=0,i=s[n].length;r<i;r++)E.event.add(t,n,s[n][r]);a.data&&(a.data=E.extend({},a.data))}}function qe(e,t){var n,r,i;if(1===t.nodeType){if(n=t.nodeName.toLowerCase(),!v.noCloneEvent&&t[E.expando]){for(r in(i=E._data(t)).events)E.removeEvent(t,r,i.handle);t.removeAttribute(E.expando)}"script"===n&&t.text!==e.text?(Le(t).text=e.text,je(t)):"object"===n?(t.parentNode&&(t.outerHTML=e.outerHTML),v.html5Clone&&e.innerHTML&&!E.trim(t.innerHTML)&&(t.innerHTML=e.innerHTML)):"input"===n&&Z.test(e.type)?(t.defaultChecked=t.checked=e.checked,t.value!==e.value&&(t.value=e.value)):"option"===n?t.defaultSelected=t.selected=e.defaultSelected:"input"!==n&&"textarea"!==n||(t.defaultValue=e.defaultValue)}}function _e(n,r,i,o){r=m.apply([],r);var e,t,a,s,u,l,c=0,f=n.length,d=f-1,p=r[0],h=E.isFunction(p);if(h||1<f&&"string"==typeof p&&!v.checkClone&&Ne.test(p))return n.each(function(e){var t=n.eq(e);h&&(r[0]=p.call(this,e,t.html())),_e(t,r,i,o)});if(f&&(e=(l=fe(r,n[0].ownerDocument,!1,n,o)).firstChild,1===l.childNodes.length&&(l=e),e||o)){for(a=(s=E.map(ae(l,"script"),Le)).length;c<f;c++)t=l,c!==d&&(t=E.clone(t,!0,!0),a&&E.merge(s,ae(t,"script"))),i.call(n[c],t,c);if(a)for(u=s[s.length-1].ownerDocument,E.map(s,je),c=0;c<a;c++)t=s[c],te.test(t.type||"")&&!E._data(t,"globalEval")&&E.contains(u,t)&&(t.src?E._evalUrl&&E._evalUrl(t.src):E.globalEval((t.text||t.textContent||t.innerHTML||"").replace(Se,"")));l=e=null}return n}function Me(e,t,n){for(var r,i=t?E.filter(t,e):e,o=0;null!=(r=i[o]);o++)n||1!==r.nodeType||E.cleanData(ae(r)),r.parentNode&&(n&&E.contains(r.ownerDocument,r)&&se(ae(r,"script")),r.parentNode.removeChild(r));return e}E.extend({htmlPrefilter:function(e){return e.replace(Ce,"<$1></$2>")},clone:function(e,t,n){var r,i,o,a,s,u=E.contains(e.ownerDocument,e);if(v.html5Clone||E.isXMLDoc(e)||!Te.test("<"+e.nodeName+">")?o=e.cloneNode(!0):(Ae.innerHTML=e.outerHTML,Ae.removeChild(o=Ae.firstChild)),!(v.noCloneEvent&&v.noCloneChecked||1!==e.nodeType&&11!==e.nodeType||E.isXMLDoc(e)))for(r=ae(o),s=ae(e),a=0;null!=(i=s[a]);++a)r[a]&&qe(i,r[a]);if(t)if(n)for(s=s||ae(e),r=r||ae(o),a=0;null!=(i=s[a]);a++)He(i,r[a]);else He(e,o);return 0<(r=ae(o,"script")).length&&se(r,!u&&ae(e,"script")),r=s=i=null,o},cleanData:function(e,t){for(var n,r,i,o,a=0,s=E.expando,u=E.cache,l=v.attributes,c=E.event.special;null!=(n=e[a]);a++)if((t||F(n))&&(o=(i=n[s])&&u[i])){if(o.events)for(r in o.events)c[r]?E.event.remove(n,r):E.removeEvent(n,r,o.handle);u[i]&&(delete u[i],l||void 0===n.removeAttribute?n[s]=void 0:n.removeAttribute(s),f.push(i))}}}),E.fn.extend({domManip:_e,detach:function(e){return Me(this,e,!0)},remove:function(e){return Me(this,e)},text:function(e){return K(this,function(e){return void 0===e?E.text(this):this.empty().append((this[0]&&this[0].ownerDocument||h).createTextNode(e))},null,e,arguments.length)},append:function(){return _e(this,arguments,function(e){1!==this.nodeType&&11!==this.nodeType&&9!==this.nodeType||De(this,e).appendChild(e)})},prepend:function(){return _e(this,arguments,function(e){if(1===this.nodeType||11===this.nodeType||9===this.nodeType){var t=De(this,e);t.insertBefore(e,t.firstChild)}})},before:function(){return _e(this,arguments,function(e){this.parentNode&&this.parentNode.insertBefore(e,this)})},after:function(){return _e(this,arguments,function(e){this.parentNode&&this.parentNode.insertBefore(e,this.nextSibling)})},empty:function(){for(var e,t=0;null!=(e=this[t]);t++){for(1===e.nodeType&&E.cleanData(ae(e,!1));e.firstChild;)e.removeChild(e.firstChild);e.options&&E.nodeName(e,"select")&&(e.options.length=0)}return this},clone:function(e,t){return e=null!=e&&e,t=null==t?e:t,this.map(function(){return E.clone(this,e,t)})},html:function(e){return K(this,function(e){var t=this[0]||{},n=0,r=this.length;if(void 0===e)return 1===t.nodeType?t.innerHTML.replace(we,""):void 0;if("string"==typeof e&&!Ee.test(e)&&(v.htmlSerialize||!Te.test(e))&&(v.leadingWhitespace||!ne.test(e))&&!oe[(ee.exec(e)||["",""])[1].toLowerCase()]){e=E.htmlPrefilter(e);try{for(;n<r;n++)1===(t=this[n]||{}).nodeType&&(E.cleanData(ae(t,!1)),t.innerHTML=e);t=0}catch(e){}}t&&this.empty().append(e)},null,e,arguments.length)},replaceWith:function(){var n=[];return _e(this,arguments,function(e){var t=this.parentNode;E.inArray(this,n)<0&&(E.cleanData(ae(this)),t&&t.replaceChild(e,this))},n)}}),E.each({appendTo:"append",prependTo:"prepend",insertBefore:"before",insertAfter:"after",replaceAll:"replaceWith"},function(e,a){E.fn[e]=function(e){for(var t,n=0,r=[],i=E(e),o=i.length-1;n<=o;n++)t=n===o?this:this.clone(!0),E(i[n])[a](t),s.apply(r,t.get());return this.pushStack(r)}});var Fe,Oe={HTML:"block",BODY:"block"};function Re(e,t){var n=E(t.createElement(e)).appendTo(t.body),r=E.css(n[0],"display");return n.detach(),r}function Pe(e){var t=h,n=Oe[e];return n||("none"!==(n=Re(e,t))&&n||((t=((Fe=(Fe||E("<iframe frameborder='0' width='0' height='0'/>")).appendTo(t.documentElement))[0].contentWindow||Fe[0].contentDocument).document).write(),t.close(),n=Re(e,t),Fe.detach()),Oe[e]=n),n}function Be(e,t,n,r){var i,o,a={};for(o in t)a[o]=e.style[o],e.style[o]=t[o];for(o in i=n.apply(e,r||[]),t)e.style[o]=a[o];return i}var We,Ie,$e,ze,Xe,Ue,Ve,Ye,Je=/^margin/,Ge=new RegExp("^("+X+")(?!px)[a-z%]+$","i"),Qe=h.documentElement;function Ke(){var e,t,n=h.documentElement;n.appendChild(Ve),Ye.style.cssText="-webkit-box-sizing:border-box;box-sizing:border-box;position:relative;display:block;margin:auto;border:1px;padding:1px;top:1%;width:50%",We=$e=Ue=!1,Ie=Xe=!0,C.getComputedStyle&&(t=C.getComputedStyle(Ye),We="1%"!==(t||{}).top,Ue="2px"===(t||{}).marginLeft,$e="4px"===(t||{width:"4px"}).width,Ye.style.marginRight="50%",Ie="4px"===(t||{marginRight:"4px"}).marginRight,(e=Ye.appendChild(h.createElement("div"))).style.cssText=Ye.style.cssText="-webkit-box-sizing:content-box;-moz-box-sizing:content-box;box-sizing:content-box;display:block;margin:0;border:0;padding:0",e.style.marginRight=e.style.width="0",Ye.style.width="1px",Xe=!parseFloat((C.getComputedStyle(e)||{}).marginRight),Ye.removeChild(e)),Ye.style.display="none",(ze=0===Ye.getClientRects().length)&&(Ye.style.display="",Ye.innerHTML="<table><tr><td></td><td>t</td></tr></table>",(e=Ye.getElementsByTagName("td"))[0].style.cssText="margin:0;border:0;padding:0;display:none",(ze=0===e[0].offsetHeight)&&(e[0].style.display="",e[1].style.display="none",ze=0===e[0].offsetHeight)),n.removeChild(Ve)}Ve=h.createElement("div"),(Ye=h.createElement("div")).style&&(Ye.style.cssText="float:left;opacity:.5",v.opacity="0.5"===Ye.style.opacity,v.cssFloat=!!Ye.style.cssFloat,Ye.style.backgroundClip="content-box",Ye.cloneNode(!0).style.backgroundClip="",v.clearCloneStyle="content-box"===Ye.style.backgroundClip,(Ve=h.createElement("div")).style.cssText="border:0;width:8px;height:0;top:0;left:-9999px;padding:0;margin-top:1px;position:absolute",Ye.innerHTML="",Ve.appendChild(Ye),v.boxSizing=""===Ye.style.boxSizing||""===Ye.style.MozBoxSizing||""===Ye.style.WebkitBoxSizing,E.extend(v,{reliableHiddenOffsets:function(){return null==We&&Ke(),ze},boxSizingReliable:function(){return null==We&&Ke(),$e},pixelMarginRight:function(){return null==We&&Ke(),Ie},pixelPosition:function(){return null==We&&Ke(),We},reliableMarginRight:function(){return null==We&&Ke(),Xe},reliableMarginLeft:function(){return null==We&&Ke(),Ue}}));var Ze,et,tt=/^(top|right|bottom|left)$/;function nt(e,t){return{get:function(){if(!e())return(this.get=t).apply(this,arguments);delete this.get}}}C.getComputedStyle?(Ze=function(e){var t=e.ownerDocument.defaultView;return t&&t.opener||(t=C),t.getComputedStyle(e)},et=function(e,t,n){var r,i,o,a,s=e.style;return""!==(a=(n=n||Ze(e))?n.getPropertyValue(t)||n[t]:void 0)&&void 0!==a||E.contains(e.ownerDocument,e)||(a=E.style(e,t)),n&&!v.pixelMarginRight()&&Ge.test(a)&&Je.test(t)&&(r=s.width,i=s.minWidth,o=s.maxWidth,s.minWidth=s.maxWidth=s.width=a,a=n.width,s.width=r,s.minWidth=i,s.maxWidth=o),void 0===a?a:a+""}):Qe.currentStyle&&(Ze=function(e){return e.currentStyle},et=function(e,t,n){var r,i,o,a,s=e.style;return null==(a=(n=n||Ze(e))?n[t]:void 0)&&s&&s[t]&&(a=s[t]),Ge.test(a)&&!tt.test(t)&&(r=s.left,(o=(i=e.runtimeStyle)&&i.left)&&(i.left=e.currentStyle.left),s.left="fontSize"===t?"1em":a,a=s.pixelLeft+"px",s.left=r,o&&(i.left=o)),void 0===a?a:a+""||"auto"});var rt=/alpha\([^)]*\)/i,it=/opacity\s*=\s*([^)]*)/i,ot=/^(none|table(?!-c[ea]).+)/,at=new RegExp("^("+X+")(.*)$","i"),st={position:"absolute",visibility:"hidden",display:"block"},ut={letterSpacing:"0",fontWeight:"400"},lt=["Webkit","O","Moz","ms"],ct=h.createElement("div").style;function ft(e){if(e in ct)return e;for(var t=e.charAt(0).toUpperCase()+e.slice(1),n=lt.length;n--;)if((e=lt[n]+t)in ct)return e}function dt(e,t){for(var n,r,i,o=[],a=0,s=e.length;a<s;a++)(r=e[a]).style&&(o[a]=E._data(r,"olddisplay"),n=r.style.display,t?(o[a]||"none"!==n||(r.style.display=""),""===r.style.display&&z(r)&&(o[a]=E._data(r,"olddisplay",Pe(r.nodeName)))):(i=z(r),(n&&"none"!==n||!i)&&E._data(r,"olddisplay",i?n:E.css(r,"display"))));for(a=0;a<s;a++)(r=e[a]).style&&(t&&"none"!==r.style.display&&""!==r.style.display||(r.style.display=t?o[a]||"":"none"));return e}function pt(e,t,n){var r=at.exec(t);return r?Math.max(0,r[1]-(n||0))+(r[2]||"px"):t}function ht(e,t,n,r,i){for(var o=n===(r?"border":"content")?4:"width"===t?1:0,a=0;o<4;o+=2)"margin"===n&&(a+=E.css(e,n+V[o],!0,i)),r?("content"===n&&(a-=E.css(e,"padding"+V[o],!0,i)),"margin"!==n&&(a-=E.css(e,"border"+V[o]+"Width",!0,i))):(a+=E.css(e,"padding"+V[o],!0,i),"padding"!==n&&(a+=E.css(e,"border"+V[o]+"Width",!0,i)));return a}function mt(e,t,n){var r=!0,i="width"===t?e.offsetWidth:e.offsetHeight,o=Ze(e),a=v.boxSizing&&"border-box"===E.css(e,"boxSizing",!1,o);if(h.msFullscreenElement&&C.top!==C&&e.getClientRects().length&&(i=Math.round(100*e.getBoundingClientRect()[t])),i<=0||null==i){if(((i=et(e,t,o))<0||null==i)&&(i=e.style[t]),Ge.test(i))return i;r=a&&(v.boxSizingReliable()||i===e.style[t]),i=parseFloat(i)||0}return i+ht(e,t,n||(a?"border":"content"),r,o)+"px"}function gt(e,t,n,r,i){return new gt.prototype.init(e,t,n,r,i)}E.extend({cssHooks:{opacity:{get:function(e,t){if(t){var n=et(e,"opacity");return""===n?"1":n}}}},cssNumber:{animationIterationCount:!0,columnCount:!0,fillOpacity:!0,flexGrow:!0,flexShrink:!0,fontWeight:!0,lineHeight:!0,opacity:!0,order:!0,orphans:!0,widows:!0,zIndex:!0,zoom:!0},cssProps:{float:v.cssFloat?"cssFloat":"styleFloat"},style:function(e,t,n,r){if(e&&3!==e.nodeType&&8!==e.nodeType&&e.style){var i,o,a,s=E.camelCase(t),u=e.style;if(t=E.cssProps[s]||(E.cssProps[s]=ft(s)||s),a=E.cssHooks[t]||E.cssHooks[s],void 0===n)return a&&"get"in a&&void 0!==(i=a.get(e,!1,r))?i:u[t];if("string"===(o=typeof n)&&(i=U.exec(n))&&i[1]&&(n=Y(e,t,i),o="number"),null!=n&&n==n&&("number"===o&&(n+=i&&i[3]||(E.cssNumber[s]?"":"px")),v.clearCloneStyle||""!==n||0!==t.indexOf("background")||(u[t]="inherit"),!(a&&"set"in a&&void 0===(n=a.set(e,n,r)))))try{u[t]=n}catch(e){}}},css:function(e,t,n,r){var i,o,a,s=E.camelCase(t);return t=E.cssProps[s]||(E.cssProps[s]=ft(s)||s),(a=E.cssHooks[t]||E.cssHooks[s])&&"get"in a&&(o=a.get(e,!0,n)),void 0===o&&(o=et(e,t,r)),"normal"===o&&t in ut&&(o=ut[t]),""===n||n?(i=parseFloat(o),!0===n||isFinite(i)?i||0:o):o}}),E.each(["height","width"],function(e,i){E.cssHooks[i]={get:function(e,t,n){if(t)return ot.test(E.css(e,"display"))&&0===e.offsetWidth?Be(e,st,function(){return mt(e,i,n)}):mt(e,i,n)},set:function(e,t,n){var r=n&&Ze(e);return pt(0,t,n?ht(e,i,n,v.boxSizing&&"border-box"===E.css(e,"boxSizing",!1,r),r):0)}}}),v.opacity||(E.cssHooks.opacity={get:function(e,t){return it.test((t&&e.currentStyle?e.currentStyle.filter:e.style.filter)||"")?.01*parseFloat(RegExp.$1)+"":t?"1":""},set:function(e,t){var n=e.style,r=e.currentStyle,i=E.isNumeric(t)?"alpha(opacity="+100*t+")":"",o=r&&r.filter||n.filter||"";((n.zoom=1)<=t||""===t)&&""===E.trim(o.replace(rt,""))&&n.removeAttribute&&(n.removeAttribute("filter"),""===t||r&&!r.filter)||(n.filter=rt.test(o)?o.replace(rt,i):o+" "+i)}}),E.cssHooks.marginRight=nt(v.reliableMarginRight,function(e,t){if(t)return Be(e,{display:"inline-block"},et,[e,"marginRight"])}),E.cssHooks.marginLeft=nt(v.reliableMarginLeft,function(e,t){if(t)return(parseFloat(et(e,"marginLeft"))||(E.contains(e.ownerDocument,e)?e.getBoundingClientRect().left-Be(e,{marginLeft:0},function(){return e.getBoundingClientRect().left}):0))+"px"}),E.each({margin:"",padding:"",border:"Width"},function(i,o){E.cssHooks[i+o]={expand:function(e){for(var t=0,n={},r="string"==typeof e?e.split(" "):[e];t<4;t++)n[i+V[t]+o]=r[t]||r[t-2]||r[0];return n}},Je.test(i)||(E.cssHooks[i+o].set=pt)}),E.fn.extend({css:function(e,t){return K(this,function(e,t,n){var r,i,o={},a=0;if(E.isArray(t)){for(r=Ze(e),i=t.length;a<i;a++)o[t[a]]=E.css(e,t[a],!1,r);return o}return void 0!==n?E.style(e,t,n):E.css(e,t)},e,t,1<arguments.length)},show:function(){return dt(this,!0)},hide:function(){return dt(this)},toggle:function(e){return"boolean"==typeof e?e?this.show():this.hide():this.each(function(){z(this)?E(this).show():E(this).hide()})}}),((E.Tween=gt).prototype={constructor:gt,init:function(e,t,n,r,i,o){this.elem=e,this.prop=n,this.easing=i||E.easing._default,this.options=t,this.start=this.now=this.cur(),this.end=r,this.unit=o||(E.cssNumber[n]?"":"px")},cur:function(){var e=gt.propHooks[this.prop];return e&&e.get?e.get(this):gt.propHooks._default.get(this)},run:function(e){var t,n=gt.propHooks[this.prop];return this.options.duration?this.pos=t=E.easing[this.easing](e,this.options.duration*e,0,1,this.options.duration):this.pos=t=e,this.now=(this.end-this.start)*t+this.start,this.options.step&&this.options.step.call(this.elem,this.now,this),n&&n.set?n.set(this):gt.propHooks._default.set(this),this}}).init.prototype=gt.prototype,(gt.propHooks={_default:{get:function(e){var t;return 1!==e.elem.nodeType||null!=e.elem[e.prop]&&null==e.elem.style[e.prop]?e.elem[e.prop]:(t=E.css(e.elem,e.prop,""))&&"auto"!==t?t:0},set:function(e){E.fx.step[e.prop]?E.fx.step[e.prop](e):1!==e.elem.nodeType||null==e.elem.style[E.cssProps[e.prop]]&&!E.cssHooks[e.prop]?e.elem[e.prop]=e.now:E.style(e.elem,e.prop,e.now+e.unit)}}}).scrollTop=gt.propHooks.scrollLeft={set:function(e){e.elem.nodeType&&e.elem.parentNode&&(e.elem[e.prop]=e.now)}},E.easing={linear:function(e){return e},swing:function(e){return.5-Math.cos(e*Math.PI)/2},_default:"swing"},E.fx=gt.prototype.init,E.fx.step={};var vt,yt,xt,bt,wt,Tt,Ct,Et=/^(?:toggle|show|hide)$/,Nt=/queueHooks$/;function kt(){return C.setTimeout(function(){vt=void 0}),vt=E.now()}function St(e,t){var n,r={height:e},i=0;for(t=t?1:0;i<4;i+=2-t)r["margin"+(n=V[i])]=r["padding"+n]=e;return t&&(r.opacity=r.width=e),r}function At(e,t,n){for(var r,i=(Dt.tweeners[t]||[]).concat(Dt.tweeners["*"]),o=0,a=i.length;o<a;o++)if(r=i[o].call(n,t,e))return r}function Dt(o,e,t){var n,a,r=0,i=Dt.prefilters.length,s=E.Deferred().always(function(){delete u.elem}),u=function(){if(a)return!1;for(var e=vt||kt(),t=Math.max(0,l.startTime+l.duration-e),n=1-(t/l.duration||0),r=0,i=l.tweens.length;r<i;r++)l.tweens[r].run(n);return s.notifyWith(o,[l,n,t]),n<1&&i?t:(s.resolveWith(o,[l]),!1)},l=s.promise({elem:o,props:E.extend({},e),opts:E.extend(!0,{specialEasing:{},easing:E.easing._default},t),originalProperties:e,originalOptions:t,startTime:vt||kt(),duration:t.duration,tweens:[],createTween:function(e,t){var n=E.Tween(o,l.opts,e,t,l.opts.specialEasing[e]||l.opts.easing);return l.tweens.push(n),n},stop:function(e){var t=0,n=e?l.tweens.length:0;if(a)return this;for(a=!0;t<n;t++)l.tweens[t].run(1);return e?(s.notifyWith(o,[l,1,0]),s.resolveWith(o,[l,e])):s.rejectWith(o,[l,e]),this}}),c=l.props;for(!function(e,t){var n,r,i,o,a;for(n in e)if(i=t[r=E.camelCase(n)],o=e[n],E.isArray(o)&&(i=o[1],o=e[n]=o[0]),n!==r&&(e[r]=o,delete e[n]),(a=E.cssHooks[r])&&"expand"in a)for(n in o=a.expand(o),delete e[r],o)n in e||(e[n]=o[n],t[n]=i);else t[r]=i}(c,l.opts.specialEasing);r<i;r++)if(n=Dt.prefilters[r].call(l,o,c,l.opts))return E.isFunction(n.stop)&&(E._queueHooks(l.elem,l.opts.queue).stop=E.proxy(n.stop,n)),n;return E.map(c,At,l),E.isFunction(l.opts.start)&&l.opts.start.call(o,l),E.fx.timer(E.extend(u,{elem:o,anim:l,queue:l.opts.queue})),l.progress(l.opts.progress).done(l.opts.done,l.opts.complete).fail(l.opts.fail).always(l.opts.always)}E.Animation=E.extend(Dt,{tweeners:{"*":[function(e,t){var n=this.createTween(e,t);return Y(n.elem,e,U.exec(t),n),n}]},tweener:function(e,t){for(var n,r=0,i=(e=E.isFunction(e)?(t=e,["*"]):e.match(q)).length;r<i;r++)n=e[r],Dt.tweeners[n]=Dt.tweeners[n]||[],Dt.tweeners[n].unshift(t)},prefilters:[function(t,e,n){var r,i,o,a,s,u,l,c=this,f={},d=t.style,p=t.nodeType&&z(t),h=E._data(t,"fxshow");for(r in n.queue||(null==(s=E._queueHooks(t,"fx")).unqueued&&(s.unqueued=0,u=s.empty.fire,s.empty.fire=function(){s.unqueued||u()}),s.unqueued++,c.always(function(){c.always(function(){s.unqueued--,E.queue(t,"fx").length||s.empty.fire()})})),1===t.nodeType&&("height"in e||"width"in e)&&(n.overflow=[d.overflow,d.overflowX,d.overflowY],"inline"===("none"===(l=E.css(t,"display"))?E._data(t,"olddisplay")||Pe(t.nodeName):l)&&"none"===E.css(t,"float")&&(v.inlineBlockNeedsLayout&&"inline"!==Pe(t.nodeName)?d.zoom=1:d.display="inline-block")),n.overflow&&(d.overflow="hidden",v.shrinkWrapBlocks()||c.always(function(){d.overflow=n.overflow[0],d.overflowX=n.overflow[1],d.overflowY=n.overflow[2]})),e)if(i=e[r],Et.exec(i)){if(delete e[r],o=o||"toggle"===i,i===(p?"hide":"show")){if("show"!==i||!h||void 0===h[r])continue;p=!0}f[r]=h&&h[r]||E.style(t,r)}else l=void 0;if(E.isEmptyObject(f))"inline"===("none"===l?Pe(t.nodeName):l)&&(d.display=l);else for(r in h?"hidden"in h&&(p=h.hidden):h=E._data(t,"fxshow",{}),o&&(h.hidden=!p),p?E(t).show():c.done(function(){E(t).hide()}),c.done(function(){var e;for(e in E._removeData(t,"fxshow"),f)E.style(t,e,f[e])}),f)a=At(p?h[r]:0,r,c),r in h||(h[r]=a.start,p&&(a.end=a.start,a.start="width"===r||"height"===r?1:0))}],prefilter:function(e,t){t?Dt.prefilters.unshift(e):Dt.prefilters.push(e)}}),E.speed=function(e,t,n){var r=e&&"object"==typeof e?E.extend({},e):{complete:n||!n&&t||E.isFunction(e)&&e,duration:e,easing:n&&t||t&&!E.isFunction(t)&&t};return r.duration=E.fx.off?0:"number"==typeof r.duration?r.duration:r.duration in E.fx.speeds?E.fx.speeds[r.duration]:E.fx.speeds._default,null!=r.queue&&!0!==r.queue||(r.queue="fx"),r.old=r.complete,r.complete=function(){E.isFunction(r.old)&&r.old.call(this),r.queue&&E.dequeue(this,r.queue)},r},E.fn.extend({fadeTo:function(e,t,n,r){return this.filter(z).css("opacity",0).show().end().animate({opacity:t},e,n,r)},animate:function(t,e,n,r){function i(){var e=Dt(this,E.extend({},t),a);(o||E._data(this,"finish"))&&e.stop(!0)}var o=E.isEmptyObject(t),a=E.speed(e,n,r);return i.finish=i,o||!1===a.queue?this.each(i):this.queue(a.queue,i)},stop:function(i,e,o){function a(e){var t=e.stop;delete e.stop,t(o)}return"string"!=typeof i&&(o=e,e=i,i=void 0),e&&!1!==i&&this.queue(i||"fx",[]),this.each(function(){var e=!0,t=null!=i&&i+"queueHooks",n=E.timers,r=E._data(this);if(t)r[t]&&r[t].stop&&a(r[t]);else for(t in r)r[t]&&r[t].stop&&Nt.test(t)&&a(r[t]);for(t=n.length;t--;)n[t].elem!==this||null!=i&&n[t].queue!==i||(n[t].anim.stop(o),e=!1,n.splice(t,1));!e&&o||E.dequeue(this,i)})},finish:function(a){return!1!==a&&(a=a||"fx"),this.each(function(){var e,t=E._data(this),n=t[a+"queue"],r=t[a+"queueHooks"],i=E.timers,o=n?n.length:0;for(t.finish=!0,E.queue(this,a,[]),r&&r.stop&&r.stop.call(this,!0),e=i.length;e--;)i[e].elem===this&&i[e].queue===a&&(i[e].anim.stop(!0),i.splice(e,1));for(e=0;e<o;e++)n[e]&&n[e].finish&&n[e].finish.call(this);delete t.finish})}}),E.each(["toggle","show","hide"],function(e,r){var i=E.fn[r];E.fn[r]=function(e,t,n){return null==e||"boolean"==typeof e?i.apply(this,arguments):this.animate(St(r,!0),e,t,n)}}),E.each({slideDown:St("show"),slideUp:St("hide"),slideToggle:St("toggle"),fadeIn:{opacity:"show"},fadeOut:{opacity:"hide"},fadeToggle:{opacity:"toggle"}},function(e,r){E.fn[e]=function(e,t,n){return this.animate(r,e,t,n)}}),E.timers=[],E.fx.tick=function(){var e,t=E.timers,n=0;for(vt=E.now();n<t.length;n++)(e=t[n])()||t[n]!==e||t.splice(n--,1);t.length||E.fx.stop(),vt=void 0},E.fx.timer=function(e){E.timers.push(e),e()?E.fx.start():E.timers.pop()},E.fx.interval=13,E.fx.start=function(){yt=yt||C.setInterval(E.fx.tick,E.fx.interval)},E.fx.stop=function(){C.clearInterval(yt),yt=null},E.fx.speeds={slow:600,fast:200,_default:400},E.fn.delay=function(r,e){return r=E.fx&&E.fx.speeds[r]||r,e=e||"fx",this.queue(e,function(e,t){var n=C.setTimeout(e,r);t.stop=function(){C.clearTimeout(n)}})},bt=h.createElement("input"),wt=h.createElement("div"),Tt=h.createElement("select"),Ct=Tt.appendChild(h.createElement("option")),(wt=h.createElement("div")).setAttribute("className","t"),wt.innerHTML="  <link/><table></table><a href='/a'>a</a><input type='checkbox'/>",xt=wt.getElementsByTagName("a")[0],bt.setAttribute("type","checkbox"),wt.appendChild(bt),(xt=wt.getElementsByTagName("a")[0]).style.cssText="top:1px",v.getSetAttribute="t"!==wt.className,v.style=/top/.test(xt.getAttribute("style")),v.hrefNormalized="/a"===xt.getAttribute("href"),v.checkOn=!!bt.value,v.optSelected=Ct.selected,v.enctype=!!h.createElement("form").enctype,Tt.disabled=!0,v.optDisabled=!Ct.disabled,(bt=h.createElement("input")).setAttribute("value",""),v.input=""===bt.getAttribute("value"),bt.value="t",bt.setAttribute("type","radio"),v.radioValue="t"===bt.value;var Lt=/\r/g;E.fn.extend({val:function(n){var r,e,i,t=this[0];return arguments.length?(i=E.isFunction(n),this.each(function(e){var t;1===this.nodeType&&(null==(t=i?n.call(this,e,E(this).val()):n)?t="":"number"==typeof t?t+="":E.isArray(t)&&(t=E.map(t,function(e){return null==e?"":e+""})),(r=E.valHooks[this.type]||E.valHooks[this.nodeName.toLowerCase()])&&"set"in r&&void 0!==r.set(this,t,"value")||(this.value=t))})):t?(r=E.valHooks[t.type]||E.valHooks[t.nodeName.toLowerCase()])&&"get"in r&&void 0!==(e=r.get(t,"value"))?e:"string"==typeof(e=t.value)?e.replace(Lt,""):null==e?"":e:void 0}}),E.extend({valHooks:{option:{get:function(e){var t=E.find.attr(e,"value");return null!=t?t:E.trim(E.text(e))}},select:{get:function(e){for(var t,n,r=e.options,i=e.selectedIndex,o="select-one"===e.type||i<0,a=o?null:[],s=o?i+1:r.length,u=i<0?s:o?i:0;u<s;u++)if(((n=r[u]).selected||u===i)&&(v.optDisabled?!n.disabled:null===n.getAttribute("disabled"))&&(!n.parentNode.disabled||!E.nodeName(n.parentNode,"optgroup"))){if(t=E(n).val(),o)return t;a.push(t)}return a},set:function(e,t){for(var n,r,i=e.options,o=E.makeArray(t),a=i.length;a--;)if(r=i[a],0<=E.inArray(E.valHooks.option.get(r),o))try{r.selected=n=!0}catch(e){r.scrollHeight}else r.selected=!1;return n||(e.selectedIndex=-1),i}}}}),E.each(["radio","checkbox"],function(){E.valHooks[this]={set:function(e,t){if(E.isArray(t))return e.checked=-1<E.inArray(E(e).val(),t)}},v.checkOn||(E.valHooks[this].get=function(e){return null===e.getAttribute("value")?"on":e.value})});var jt,Ht,qt=E.expr.attrHandle,_t=/^(?:checked|selected)$/i,Mt=v.getSetAttribute,Ft=v.input;E.fn.extend({attr:function(e,t){return K(this,E.attr,e,t,1<arguments.length)},removeAttr:function(e){return this.each(function(){E.removeAttr(this,e)})}}),E.extend({attr:function(e,t,n){var r,i,o=e.nodeType;if(3!==o&&8!==o&&2!==o)return void 0===e.getAttribute?E.prop(e,t,n):(1===o&&E.isXMLDoc(e)||(t=t.toLowerCase(),i=E.attrHooks[t]||(E.expr.match.bool.test(t)?Ht:jt)),void 0!==n?null===n?void E.removeAttr(e,t):i&&"set"in i&&void 0!==(r=i.set(e,n,t))?r:(e.setAttribute(t,n+""),n):i&&"get"in i&&null!==(r=i.get(e,t))?r:null==(r=E.find.attr(e,t))?void 0:r)},attrHooks:{type:{set:function(e,t){if(!v.radioValue&&"radio"===t&&E.nodeName(e,"input")){var n=e.value;return e.setAttribute("type",t),n&&(e.value=n),t}}}},removeAttr:function(e,t){var n,r,i=0,o=t&&t.match(q);if(o&&1===e.nodeType)for(;n=o[i++];)r=E.propFix[n]||n,E.expr.match.bool.test(n)?Ft&&Mt||!_t.test(n)?e[r]=!1:e[E.camelCase("default-"+n)]=e[r]=!1:E.attr(e,n,""),e.removeAttribute(Mt?n:r)}}),Ht={set:function(e,t,n){return!1===t?E.removeAttr(e,n):Ft&&Mt||!_t.test(n)?e.setAttribute(!Mt&&E.propFix[n]||n,n):e[E.camelCase("default-"+n)]=e[n]=!0,n}},E.each(E.expr.match.bool.source.match(/\w+/g),function(e,t){var o=qt[t]||E.find.attr;Ft&&Mt||!_t.test(t)?qt[t]=function(e,t,n){var r,i;return n||(i=qt[t],qt[t]=r,r=null!=o(e,t,n)?t.toLowerCase():null,qt[t]=i),r}:qt[t]=function(e,t,n){if(!n)return e[E.camelCase("default-"+t)]?t.toLowerCase():null}}),Ft&&Mt||(E.attrHooks.value={set:function(e,t,n){if(!E.nodeName(e,"input"))return jt&&jt.set(e,t,n);e.defaultValue=t}}),Mt||(jt={set:function(e,t,n){var r=e.getAttributeNode(n);if(r||e.setAttributeNode(r=e.ownerDocument.createAttribute(n)),r.value=t+="","value"===n||t===e.getAttribute(n))return t}},qt.id=qt.name=qt.coords=function(e,t,n){var r;if(!n)return(r=e.getAttributeNode(t))&&""!==r.value?r.value:null},E.valHooks.button={get:function(e,t){var n=e.getAttributeNode(t);if(n&&n.specified)return n.value},set:jt.set},E.attrHooks.contenteditable={set:function(e,t,n){jt.set(e,""!==t&&t,n)}},E.each(["width","height"],function(e,n){E.attrHooks[n]={set:function(e,t){if(""===t)return e.setAttribute(n,"auto"),t}}})),v.style||(E.attrHooks.style={get:function(e){return e.style.cssText||void 0},set:function(e,t){return e.style.cssText=t+""}});var Ot=/^(?:input|select|textarea|button|object)$/i,Rt=/^(?:a|area)$/i;E.fn.extend({prop:function(e,t){return K(this,E.prop,e,t,1<arguments.length)},removeProp:function(e){return e=E.propFix[e]||e,this.each(function(){try{this[e]=void 0,delete this[e]}catch(e){}})}}),E.extend({prop:function(e,t,n){var r,i,o=e.nodeType;if(3!==o&&8!==o&&2!==o)return 1===o&&E.isXMLDoc(e)||(t=E.propFix[t]||t,i=E.propHooks[t]),void 0!==n?i&&"set"in i&&void 0!==(r=i.set(e,n,t))?r:e[t]=n:i&&"get"in i&&null!==(r=i.get(e,t))?r:e[t]},propHooks:{tabIndex:{get:function(e){var t=E.find.attr(e,"tabindex");return t?parseInt(t,10):Ot.test(e.nodeName)||Rt.test(e.nodeName)&&e.href?0:-1}}},propFix:{for:"htmlFor",class:"className"}}),v.hrefNormalized||E.each(["href","src"],function(e,t){E.propHooks[t]={get:function(e){return e.getAttribute(t,4)}}}),v.optSelected||(E.propHooks.selected={get:function(e){var t=e.parentNode;return t&&(t.selectedIndex,t.parentNode&&t.parentNode.selectedIndex),null}}),E.each(["tabIndex","readOnly","maxLength","cellSpacing","cellPadding","rowSpan","colSpan","useMap","frameBorder","contentEditable"],function(){E.propFix[this.toLowerCase()]=this}),v.enctype||(E.propFix.enctype="encoding");var Pt=/[\t\r\n\f]/g;function Bt(e){return E.attr(e,"class")||""}E.fn.extend({addClass:function(t){var e,n,r,i,o,a,s,u=0;if(E.isFunction(t))return this.each(function(e){E(this).addClass(t.call(this,e,Bt(this)))});if("string"==typeof t&&t)for(e=t.match(q)||[];n=this[u++];)if(i=Bt(n),r=1===n.nodeType&&(" "+i+" ").replace(Pt," ")){for(a=0;o=e[a++];)r.indexOf(" "+o+" ")<0&&(r+=o+" ");i!==(s=E.trim(r))&&E.attr(n,"class",s)}return this},removeClass:function(t){var e,n,r,i,o,a,s,u=0;if(E.isFunction(t))return this.each(function(e){E(this).removeClass(t.call(this,e,Bt(this)))});if(!arguments.length)return this.attr("class","");if("string"==typeof t&&t)for(e=t.match(q)||[];n=this[u++];)if(i=Bt(n),r=1===n.nodeType&&(" "+i+" ").replace(Pt," ")){for(a=0;o=e[a++];)for(;-1<r.indexOf(" "+o+" ");)r=r.replace(" "+o+" "," ");i!==(s=E.trim(r))&&E.attr(n,"class",s)}return this},toggleClass:function(i,t){var o=typeof i;return"boolean"==typeof t&&"string"==o?t?this.addClass(i):this.removeClass(i):E.isFunction(i)?this.each(function(e){E(this).toggleClass(i.call(this,e,Bt(this),t),t)}):this.each(function(){var e,t,n,r;if("string"==o)for(t=0,n=E(this),r=i.match(q)||[];e=r[t++];)n.hasClass(e)?n.removeClass(e):n.addClass(e);else void 0!==i&&"boolean"!=o||((e=Bt(this))&&E._data(this,"__className__",e),E.attr(this,"class",e||!1===i?"":E._data(this,"__className__")||""))})},hasClass:function(e){var t,n,r=0;for(t=" "+e+" ";n=this[r++];)if(1===n.nodeType&&-1<(" "+Bt(n)+" ").replace(Pt," ").indexOf(t))return!0;return!1}}),E.each("blur focus focusin focusout load resize scroll unload click dblclick mousedown mouseup mousemove mouseover mouseout mouseenter mouseleave change select submit keydown keypress keyup error contextmenu".split(" "),function(e,n){E.fn[n]=function(e,t){return 0<arguments.length?this.on(n,null,e,t):this.trigger(n)}}),E.fn.extend({hover:function(e,t){return this.mouseenter(e).mouseleave(t||e)}});var Wt=C.location,It=E.now(),$t=/\?/,zt=/(,)|(\[|{)|(}|])|"(?:[^"\\\r\n]|\\["\\\/bfnrt]|\\u[\da-fA-F]{4})*"\s*:?|true|false|null|-?(?!0\d)\d+(?:\.\d+|)(?:[eE][+-]?\d+|)/g;E.parseJSON=function(e){if(C.JSON&&C.JSON.parse)return C.JSON.parse(e+"");var i,o=null,t=E.trim(e+"");return t&&!E.trim(t.replace(zt,function(e,t,n,r){return i&&t&&(o=0),0===o?e:(i=n||t,o+=!r-!n,"")}))?Function("return "+t)():E.error("Invalid JSON: "+e)},E.parseXML=function(e){var t;if(!e||"string"!=typeof e)return null;try{C.DOMParser?t=(new C.DOMParser).parseFromString(e,"text/xml"):((t=new C.ActiveXObject("Microsoft.XMLDOM")).async="false",t.loadXML(e))}catch(e){t=void 0}return t&&t.documentElement&&!t.getElementsByTagName("parsererror").length||E.error("Invalid XML: "+e),t};var Xt=/#.*$/,Ut=/([?&])_=[^&]*/,Vt=/^(.*?):[ \t]*([^\r\n]*)\r?$/gm,Yt=/^(?:GET|HEAD)$/,Jt=/^\/\//,Gt=/^([\w.+-]+:)(?:\/\/(?:[^\/?#]*@|)([^\/?#:]*)(?::(\d+)|)|)/,Qt={},Kt={},Zt="*/".concat("*"),en=Wt.href,tn=Gt.exec(en.toLowerCase())||[];function nn(o){return function(e,t){"string"!=typeof e&&(t=e,e="*");var n,r=0,i=e.toLowerCase().match(q)||[];if(E.isFunction(t))for(;n=i[r++];)"+"===n.charAt(0)?(n=n.slice(1)||"*",(o[n]=o[n]||[]).unshift(t)):(o[n]=o[n]||[]).push(t)}}function rn(t,i,o,a){var s={},u=t===Kt;function l(e){var r;return s[e]=!0,E.each(t[e]||[],function(e,t){var n=t(i,o,a);return"string"!=typeof n||u||s[n]?u?!(r=n):void 0:(i.dataTypes.unshift(n),l(n),!1)}),r}return l(i.dataTypes[0])||!s["*"]&&l("*")}function on(e,t){var n,r,i=E.ajaxSettings.flatOptions||{};for(r in t)void 0!==t[r]&&((i[r]?e:n=n||{})[r]=t[r]);return n&&E.extend(!0,e,n),e}E.extend({active:0,lastModified:{},etag:{},ajaxSettings:{url:en,type:"GET",isLocal:/^(?:about|app|app-storage|.+-extension|file|res|widget):$/.test(tn[1]),global:!0,processData:!0,async:!0,contentType:"application/x-www-form-urlencoded; charset=UTF-8",accepts:{"*":Zt,text:"text/plain",html:"text/html",xml:"application/xml, text/xml",json:"application/json, text/javascript"},contents:{xml:/\bxml\b/,html:/\bhtml/,json:/\bjson\b/},responseFields:{xml:"responseXML",text:"responseText",json:"responseJSON"},converters:{"* text":String,"text html":!0,"text json":E.parseJSON,"text xml":E.parseXML},flatOptions:{url:!0,context:!0}},ajaxSetup:function(e,t){return t?on(on(e,E.ajaxSettings),t):on(E.ajaxSettings,e)},ajaxPrefilter:nn(Qt),ajaxTransport:nn(Kt),ajax:function(e,t){"object"==typeof e&&(t=e,e=void 0),t=t||{};var n,r,c,f,d,p,h,i,m=E.ajaxSetup({},t),g=m.context||m,v=m.context&&(g.nodeType||g.jquery)?E(g):E.event,y=E.Deferred(),x=E.Callbacks("once memory"),b=m.statusCode||{},o={},a={},w=0,s="canceled",T={readyState:0,getResponseHeader:function(e){var t;if(2===w){if(!i)for(i={};t=Vt.exec(f);)i[t[1].toLowerCase()]=t[2];t=i[e.toLowerCase()]}return null==t?null:t},getAllResponseHeaders:function(){return 2===w?f:null},setRequestHeader:function(e,t){var n=e.toLowerCase();return w||(e=a[n]=a[n]||e,o[e]=t),this},overrideMimeType:function(e){return w||(m.mimeType=e),this},statusCode:function(e){var t;if(e)if(w<2)for(t in e)b[t]=[b[t],e[t]];else T.always(e[T.status]);return this},abort:function(e){var t=e||s;return h&&h.abort(t),u(0,t),this}};if(y.promise(T).complete=x.add,T.success=T.done,T.error=T.fail,m.url=((e||m.url||en)+"").replace(Xt,"").replace(Jt,tn[1]+"//"),m.type=t.method||t.type||m.method||m.type,m.dataTypes=E.trim(m.dataType||"*").toLowerCase().match(q)||[""],null==m.crossDomain&&(n=Gt.exec(m.url.toLowerCase()),m.crossDomain=!(!n||n[1]===tn[1]&&n[2]===tn[2]&&(n[3]||("http:"===n[1]?"80":"443"))===(tn[3]||("http:"===tn[1]?"80":"443")))),m.data&&m.processData&&"string"!=typeof m.data&&(m.data=E.param(m.data,m.traditional)),rn(Qt,m,t,T),2===w)return T;for(r in(p=E.event&&m.global)&&0==E.active++&&E.event.trigger("ajaxStart"),m.type=m.type.toUpperCase(),m.hasContent=!Yt.test(m.type),c=m.url,m.hasContent||(m.data&&(c=m.url+=($t.test(c)?"&":"?")+m.data,delete m.data),!1===m.cache&&(m.url=Ut.test(c)?c.replace(Ut,"$1_="+It++):c+($t.test(c)?"&":"?")+"_="+It++)),m.ifModified&&(E.lastModified[c]&&T.setRequestHeader("If-Modified-Since",E.lastModified[c]),E.etag[c]&&T.setRequestHeader("If-None-Match",E.etag[c])),(m.data&&m.hasContent&&!1!==m.contentType||t.contentType)&&T.setRequestHeader("Content-Type",m.contentType),T.setRequestHeader("Accept",m.dataTypes[0]&&m.accepts[m.dataTypes[0]]?m.accepts[m.dataTypes[0]]+("*"!==m.dataTypes[0]?", "+Zt+"; q=0.01":""):m.accepts["*"]),m.headers)T.setRequestHeader(r,m.headers[r]);if(m.beforeSend&&(!1===m.beforeSend.call(g,T,m)||2===w))return T.abort();for(r in s="abort",{success:1,error:1,complete:1})T[r](m[r]);if(h=rn(Kt,m,t,T)){if(T.readyState=1,p&&v.trigger("ajaxSend",[T,m]),2===w)return T;m.async&&0<m.timeout&&(d=C.setTimeout(function(){T.abort("timeout")},m.timeout));try{w=1,h.send(o,u)}catch(e){if(!(w<2))throw e;u(-1,e)}}else u(-1,"No Transport");function u(e,t,n,r){var i,o,a,s,u,l=t;2!==w&&(w=2,d&&C.clearTimeout(d),h=void 0,f=r||"",T.readyState=0<e?4:0,i=200<=e&&e<300||304===e,n&&(s=function(e,t,n){for(var r,i,o,a,s=e.contents,u=e.dataTypes;"*"===u[0];)u.shift(),void 0===i&&(i=e.mimeType||t.getResponseHeader("Content-Type"));if(i)for(a in s)if(s[a]&&s[a].test(i)){u.unshift(a);break}if(u[0]in n)o=u[0];else{for(a in n){if(!u[0]||e.converters[a+" "+u[0]]){o=a;break}r=r||a}o=o||r}if(o)return o!==u[0]&&u.unshift(o),n[o]}(m,T,n)),s=function(e,t,n,r){var i,o,a,s,u,l={},c=e.dataTypes.slice();if(c[1])for(a in e.converters)l[a.toLowerCase()]=e.converters[a];for(o=c.shift();o;)if(e.responseFields[o]&&(n[e.responseFields[o]]=t),!u&&r&&e.dataFilter&&(t=e.dataFilter(t,e.dataType)),u=o,o=c.shift())if("*"===o)o=u;else if("*"!==u&&u!==o){if(!(a=l[u+" "+o]||l["* "+o]))for(i in l)if((s=i.split(" "))[1]===o&&(a=l[u+" "+s[0]]||l["* "+s[0]])){!0===a?a=l[i]:!0!==l[i]&&(o=s[0],c.unshift(s[1]));break}if(!0!==a)if(a&&e.throws)t=a(t);else try{t=a(t)}catch(e){return{state:"parsererror",error:a?e:"No conversion from "+u+" to "+o}}}return{state:"success",data:t}}(m,s,T,i),i?(m.ifModified&&((u=T.getResponseHeader("Last-Modified"))&&(E.lastModified[c]=u),(u=T.getResponseHeader("etag"))&&(E.etag[c]=u)),204===e||"HEAD"===m.type?l="nocontent":304===e?l="notmodified":(l=s.state,o=s.data,i=!(a=s.error))):(a=l,!e&&l||(l="error",e<0&&(e=0))),T.status=e,T.statusText=(t||l)+"",i?y.resolveWith(g,[o,l,T]):y.rejectWith(g,[T,l,a]),T.statusCode(b),b=void 0,p&&v.trigger(i?"ajaxSuccess":"ajaxError",[T,m,i?o:a]),x.fireWith(g,[T,l]),p&&(v.trigger("ajaxComplete",[T,m]),--E.active||E.event.trigger("ajaxStop")))}return T},getJSON:function(e,t,n){return E.get(e,t,n,"json")},getScript:function(e,t){return E.get(e,void 0,t,"script")}}),E.each(["get","post"],function(e,i){E[i]=function(e,t,n,r){return E.isFunction(t)&&(r=r||n,n=t,t=void 0),E.ajax(E.extend({url:e,type:i,dataType:r,data:t,success:n},E.isPlainObject(e)&&e))}}),E._evalUrl=function(e){return E.ajax({url:e,type:"GET",dataType:"script",cache:!0,async:!1,global:!1,throws:!0})},E.fn.extend({wrapAll:function(t){if(E.isFunction(t))return this.each(function(e){E(this).wrapAll(t.call(this,e))});if(this[0]){var e=E(t,this[0].ownerDocument).eq(0).clone(!0);this[0].parentNode&&e.insertBefore(this[0]),e.map(function(){for(var e=this;e.firstChild&&1===e.firstChild.nodeType;)e=e.firstChild;return e}).append(this)}return this},wrapInner:function(n){return E.isFunction(n)?this.each(function(e){E(this).wrapInner(n.call(this,e))}):this.each(function(){var e=E(this),t=e.contents();t.length?t.wrapAll(n):e.append(n)})},wrap:function(t){var n=E.isFunction(t);return this.each(function(e){E(this).wrapAll(n?t.call(this,e):t)})},unwrap:function(){return this.parent().each(function(){E.nodeName(this,"body")||E(this).replaceWith(this.childNodes)}).end()}}),E.expr.filters.hidden=function(e){return v.reliableHiddenOffsets()?e.offsetWidth<=0&&e.offsetHeight<=0&&!e.getClientRects().length:function(e){for(;e&&1===e.nodeType;){if("none"===((t=e).style&&t.style.display||E.css(t,"display"))||"hidden"===e.type)return!0;e=e.parentNode}var t;return!1}(e)},E.expr.filters.visible=function(e){return!E.expr.filters.hidden(e)};var an=/%20/g,sn=/\[\]$/,un=/\r?\n/g,ln=/^(?:submit|button|image|reset|file)$/i,cn=/^(?:input|select|textarea|keygen)/i;function fn(n,e,r,i){var t;if(E.isArray(e))E.each(e,function(e,t){r||sn.test(n)?i(n,t):fn(n+"["+("object"==typeof t&&null!=t?e:"")+"]",t,r,i)});else if(r||"object"!==E.type(e))i(n,e);else for(t in e)fn(n+"["+t+"]",e[t],r,i)}E.param=function(e,t){function n(e,t){t=E.isFunction(t)?t():null==t?"":t,i[i.length]=encodeURIComponent(e)+"="+encodeURIComponent(t)}var r,i=[];if(void 0===t&&(t=E.ajaxSettings&&E.ajaxSettings.traditional),E.isArray(e)||e.jquery&&!E.isPlainObject(e))E.each(e,function(){n(this.name,this.value)});else for(r in e)fn(r,e[r],t,n);return i.join("&").replace(an,"+")},E.fn.extend({serialize:function(){return E.param(this.serializeArray())},serializeArray:function(){return this.map(function(){var e=E.prop(this,"elements");return e?E.makeArray(e):this}).filter(function(){var e=this.type;return this.name&&!E(this).is(":disabled")&&cn.test(this.nodeName)&&!ln.test(e)&&(this.checked||!Z.test(e))}).map(function(e,t){var n=E(this).val();return null==n?null:E.isArray(n)?E.map(n,function(e){return{name:t.name,value:e.replace(un,"\r\n")}}):{name:t.name,value:n.replace(un,"\r\n")}}).get()}}),E.ajaxSettings.xhr=void 0!==C.ActiveXObject?function(){return this.isLocal?gn():8<h.documentMode?mn():/^(get|post|head|put|delete|options)$/i.test(this.type)&&mn()||gn()}:mn;var dn=0,pn={},hn=E.ajaxSettings.xhr();function mn(){try{return new C.XMLHttpRequest}catch(e){}}function gn(){try{return new C.ActiveXObject("Microsoft.XMLHTTP")}catch(e){}}C.attachEvent&&C.attachEvent("onunload",function(){for(var e in pn)pn[e](void 0,!0)}),v.cors=!!hn&&"withCredentials"in hn,(hn=v.ajax=!!hn)&&E.ajaxTransport(function(u){var l;if(!u.crossDomain||v.cors)return{send:function(e,o){var t,a=u.xhr(),s=++dn;if(a.open(u.type,u.url,u.async,u.username,u.password),u.xhrFields)for(t in u.xhrFields)a[t]=u.xhrFields[t];for(t in u.mimeType&&a.overrideMimeType&&a.overrideMimeType(u.mimeType),u.crossDomain||e["X-Requested-With"]||(e["X-Requested-With"]="XMLHttpRequest"),e)void 0!==e[t]&&a.setRequestHeader(t,e[t]+"");a.send(u.hasContent&&u.data||null),l=function(e,t){var n,r,i;if(l&&(t||4===a.readyState))if(delete pn[s],l=void 0,a.onreadystatechange=E.noop,t)4!==a.readyState&&a.abort();else{i={},n=a.status,"string"==typeof a.responseText&&(i.text=a.responseText);try{r=a.statusText}catch(e){r=""}n||!u.isLocal||u.crossDomain?1223===n&&(n=204):n=i.text?200:404}i&&o(n,r,i,a.getAllResponseHeaders())},u.async?4===a.readyState?C.setTimeout(l):a.onreadystatechange=pn[s]=l:l()},abort:function(){l&&l(void 0,!0)}}}),E.ajaxPrefilter(function(e){e.crossDomain&&(e.contents.script=!1)}),E.ajaxSetup({accepts:{script:"text/javascript, application/javascript, application/ecmascript, application/x-ecmascript"},contents:{script:/\b(?:java|ecma)script\b/},converters:{"text script":function(e){return E.globalEval(e),e}}}),E.ajaxPrefilter("script",function(e){void 0===e.cache&&(e.cache=!1),e.crossDomain&&(e.type="GET",e.global=!1)}),E.ajaxTransport("script",function(t){if(t.crossDomain){var r,i=h.head||E("head")[0]||h.documentElement;return{send:function(e,n){(r=h.createElement("script")).async=!0,t.scriptCharset&&(r.charset=t.scriptCharset),r.src=t.url,r.onload=r.onreadystatechange=function(e,t){!t&&r.readyState&&!/loaded|complete/.test(r.readyState)||(r.onload=r.onreadystatechange=null,r.parentNode&&r.parentNode.removeChild(r),r=null,t||n(200,"success"))},i.insertBefore(r,i.firstChild)},abort:function(){r&&r.onload(void 0,!0)}}}});var vn=[],yn=/(=)\?(?=&|$)|\?\?/;E.ajaxSetup({jsonp:"callback",jsonpCallback:function(){var e=vn.pop()||E.expando+"_"+It++;return this[e]=!0,e}}),E.ajaxPrefilter("json jsonp",function(e,t,n){var r,i,o,a=!1!==e.jsonp&&(yn.test(e.url)?"url":"string"==typeof e.data&&0===(e.contentType||"").indexOf("application/x-www-form-urlencoded")&&yn.test(e.data)&&"data");if(a||"jsonp"===e.dataTypes[0])return r=e.jsonpCallback=E.isFunction(e.jsonpCallback)?e.jsonpCallback():e.jsonpCallback,a?e[a]=e[a].replace(yn,"$1"+r):!1!==e.jsonp&&(e.url+=($t.test(e.url)?"&":"?")+e.jsonp+"="+r),e.converters["script json"]=function(){return o||E.error(r+" was not called"),o[0]},e.dataTypes[0]="json",i=C[r],C[r]=function(){o=arguments},n.always(function(){void 0===i?E(C).removeProp(r):C[r]=i,e[r]&&(e.jsonpCallback=t.jsonpCallback,vn.push(r)),o&&E.isFunction(i)&&i(o[0]),o=i=void 0}),"script"}),v.createHTMLDocument=function(){if(!h.implementation.createHTMLDocument)return!1;var e=h.implementation.createHTMLDocument("");return e.body.innerHTML="<form></form><form></form>",2===e.body.childNodes.length}(),E.parseHTML=function(e,t,n){if(!e||"string"!=typeof e)return null;"boolean"==typeof t&&(n=t,t=!1),t=t||(v.createHTMLDocument?h.implementation.createHTMLDocument(""):h);var r=w.exec(e),i=!n&&[];return r?[t.createElement(r[1])]:(r=fe([e],t,i),i&&i.length&&E(i).remove(),E.merge([],r.childNodes))};var xn=E.fn.load;function bn(e){return E.isWindow(e)?e:9===e.nodeType&&(e.defaultView||e.parentWindow)}E.fn.load=function(e,t,n){if("string"!=typeof e&&xn)return xn.apply(this,arguments);var r,i,o,a=this,s=e.indexOf(" ");return-1<s&&(r=E.trim(e.slice(s,e.length)),e=e.slice(0,s)),E.isFunction(t)?(n=t,t=void 0):t&&"object"==typeof t&&(i="POST"),0<a.length&&E.ajax({url:e,type:i||"GET",dataType:"html",data:t}).done(function(e){o=arguments,a.html(r?E("<div>").append(E.parseHTML(e)).find(r):e)}).always(n&&function(e,t){a.each(function(){n.apply(a,o||[e.responseText,t,e])})}),this},E.each(["ajaxStart","ajaxStop","ajaxComplete","ajaxError","ajaxSuccess","ajaxSend"],function(e,t){E.fn[t]=function(e){return this.on(t,e)}}),E.expr.filters.animated=function(t){return E.grep(E.timers,function(e){return t===e.elem}).length},E.offset={setOffset:function(e,t,n){var r,i,o,a,s,u,l=E.css(e,"position"),c=E(e),f={};"static"===l&&(e.style.position="relative"),s=c.offset(),o=E.css(e,"top"),u=E.css(e,"left"),i=("absolute"===l||"fixed"===l)&&-1<E.inArray("auto",[o,u])?(a=(r=c.position()).top,r.left):(a=parseFloat(o)||0,parseFloat(u)||0),E.isFunction(t)&&(t=t.call(e,n,E.extend({},s))),null!=t.top&&(f.top=t.top-s.top+a),null!=t.left&&(f.left=t.left-s.left+i),"using"in t?t.using.call(e,f):c.css(f)}},E.fn.extend({offset:function(t){if(arguments.length)return void 0===t?this:this.each(function(e){E.offset.setOffset(this,t,e)});var e,n,r={top:0,left:0},i=this[0],o=i&&i.ownerDocument;return o?(e=o.documentElement,E.contains(e,i)?(void 0!==i.getBoundingClientRect&&(r=i.getBoundingClientRect()),n=bn(o),{top:r.top+(n.pageYOffset||e.scrollTop)-(e.clientTop||0),left:r.left+(n.pageXOffset||e.scrollLeft)-(e.clientLeft||0)}):r):void 0},position:function(){if(this[0]){var e,t,n={top:0,left:0},r=this[0];return"fixed"===E.css(r,"position")?t=r.getBoundingClientRect():(e=this.offsetParent(),t=this.offset(),E.nodeName(e[0],"html")||(n=e.offset()),n.top+=E.css(e[0],"borderTopWidth",!0),n.left+=E.css(e[0],"borderLeftWidth",!0)),{top:t.top-n.top-E.css(r,"marginTop",!0),left:t.left-n.left-E.css(r,"marginLeft",!0)}}},offsetParent:function(){return this.map(function(){for(var e=this.offsetParent;e&&!E.nodeName(e,"html")&&"static"===E.css(e,"position");)e=e.offsetParent;return e||Qe})}}),E.each({scrollLeft:"pageXOffset",scrollTop:"pageYOffset"},function(t,i){var o=/Y/.test(i);E.fn[t]=function(e){return K(this,function(e,t,n){var r=bn(e);if(void 0===n)return r?i in r?r[i]:r.document.documentElement[t]:e[t];r?r.scrollTo(o?E(r).scrollLeft():n,o?n:E(r).scrollTop()):e[t]=n},t,e,arguments.length,null)}}),E.each(["top","left"],function(e,n){E.cssHooks[n]=nt(v.pixelPosition,function(e,t){if(t)return t=et(e,n),Ge.test(t)?E(e).position()[n]+"px":t})}),E.each({Height:"height",Width:"width"},function(o,a){E.each({padding:"inner"+o,content:a,"":"outer"+o},function(r,e){E.fn[e]=function(e,t){var n=arguments.length&&(r||"boolean"!=typeof e),i=r||(!0===e||!0===t?"margin":"border");return K(this,function(e,t,n){var r;return E.isWindow(e)?e.document.documentElement["client"+o]:9===e.nodeType?(r=e.documentElement,Math.max(e.body["scroll"+o],r["scroll"+o],e.body["offset"+o],r["offset"+o],r["client"+o])):void 0===n?E.css(e,t,i):E.style(e,t,n,i)},a,n?e:void 0,n,null)}})}),E.fn.extend({bind:function(e,t,n){return this.on(e,null,t,n)},unbind:function(e,t){return this.off(e,null,t)},delegate:function(e,t,n,r){return this.on(t,e,n,r)},undelegate:function(e,t,n){return 1===arguments.length?this.off(e,"**"):this.off(t,e||"**",n)}}),E.fn.size=function(){return this.length},E.fn.andSelf=E.fn.addBack,"function"==typeof define&&define.amd&&define("jquery",[],function(){return E});var wn=C.jQuery,Tn=C.$;return E.noConflict=function(e){return C.$===E&&(C.$=Tn),e&&C.jQuery===E&&(C.jQuery=wn),E},e||(C.jQuery=C.$=E),E});
+//# sourceMappingURL=jquery-1.12.1.min.map
\ No newline at end of file
diff --git js/lib/jquery/jquery-1.12.1.min.map js/lib/jquery/jquery-1.12.1.min.map
new file mode 100644
index 00000000000..061f4525efe
--- /dev/null
+++ js/lib/jquery/jquery-1.12.1.min.map
@@ -0,0 +1 @@
+{"version":3,"sources":["jquery-1.12.1.js"],"names":["global","factory","module","exports","document","w","Error","window","this","noGlobal","fcamelCase","all","letter","toUpperCase","deletedIds","slice","concat","push","indexOf","class2type","toString","hasOwn","hasOwnProperty","support","version","jQuery","selector","context","fn","init","rtrim","rmsPrefix","rdashAlpha","isArrayLike","obj","length","type","isWindow","prototype","jquery","constructor","toArray","call","get","num","pushStack","elems","ret","merge","prevObject","each","callback","map","elem","i","apply","arguments","first","eq","last","len","j","end","sort","splice","extend","src","copyIsArray","copy","name","options","clone","target","deep","isFunction","isPlainObject","isArray","undefined","expando","Math","random","replace","isReady","error","msg","noop","Array","isNumeric","realStringObj","parseFloat","isEmptyObject","key","nodeType","e","ownFirst","globalEval","data","trim","execScript","camelCase","string","nodeName","toLowerCase","text","makeArray","arr","results","Object","inArray","max","second","grep","invert","matches","callbackExpect","arg","value","guid","proxy","args","tmp","now","Date","Symbol","iterator","split","Sizzle","funescape","_","escaped","escapedWhitespace","high","String","fromCharCode","unloadHandler","setDocument","Expr","getText","isXML","tokenize","compile","select","outermostContext","sortInput","hasDuplicate","docElem","documentIsHTML","rbuggyQSA","rbuggyMatches","contains","preferredDoc","dirruns","done","classCache","createCache","tokenCache","compilerCache","sortOrder","a","b","pop","push_native","list","booleans","whitespace","identifier","attributes","pseudos","rwhitespace","RegExp","rcomma","rcombinators","rattributeQuotes","rpseudo","ridentifier","matchExpr","ID","CLASS","TAG","ATTR","PSEUDO","CHILD","bool","needsContext","rinputs","rheader","rnative","rquickExpr","rsibling","rescape","runescape","childNodes","els","seed","m","nid","nidselect","match","groups","newSelector","newContext","ownerDocument","exec","getElementById","id","getElementsByTagName","getElementsByClassName","qsa","test","getAttribute","setAttribute","toSelector","join","testContext","parentNode","querySelectorAll","qsaError","removeAttribute","keys","cache","cacheLength","shift","markFunction","assert","div","createElement","removeChild","addHandle","attrs","handler","attrHandle","siblingCheck","cur","diff","sourceIndex","nextSibling","createInputPseudo","createButtonPseudo","createPositionalPseudo","argument","matchIndexes","documentElement","node","hasCompare","parent","doc","defaultView","top","addEventListener","attachEvent","className","appendChild","createComment","getById","getElementsByName","find","filter","attrId","getAttributeNode","tag","innerHTML","input","matchesSelector","webkitMatchesSelector","mozMatchesSelector","oMatchesSelector","msMatchesSelector","disconnectedMatch","compareDocumentPosition","adown","bup","compare","sortDetached","aup","ap","bp","unshift","expr","elements","attr","val","specified","uniqueSort","duplicates","detectDuplicates","sortStable","textContent","firstChild","nodeValue","selectors","createPseudo","relative",">","dir"," ","+","~","preFilter","excess","unquoted","nodeNameSelector","pattern","operator","check","result","what","simple","forward","ofType","xml","uniqueCache","outerCache","nodeIndex","start","useCache","lastChild","uniqueID","pseudo","setFilters","idx","matched","not","matcher","unmatched","has","innerText","lang","elemLang","hash","location","root","focus","activeElement","hasFocus","href","tabIndex","enabled","disabled","checked","selected","selectedIndex","empty","header","button","even","odd","lt","gt","radio","checkbox","file","password","image","submit","reset","tokens","addCombinator","combinator","base","checkNonElements","doneName","oldCache","newCache","elementMatcher","matchers","condense","newUnmatched","mapped","setMatcher","postFilter","postFinder","postSelector","temp","preMap","postMap","preexisting","contexts","multipleContexts","matcherIn","matcherOut","matcherFromTokens","checkContext","leadingRelative","implicitRelative","matchContext","matchAnyContext","matcherFromGroupMatchers","elementMatchers","setMatchers","superMatcher","outermost","matchedCount","setMatched","contextBackup","byElement","dirrunsUnique","bySet","filters","parseOnly","soFar","preFilters","cached","token","compiled","div1","defaultValue","unique","isXMLDoc","until","truncate","is","siblings","n","rneedsContext","rsingleTag","risSimple","winnow","qualifier","self","rootjQuery","ready","charAt","parseHTML","rparentsprev","guaranteedUnique","children","contents","next","prev","sibling","targets","closest","l","pos","index","prevAll","add","addBack","parents","parentsUntil","nextAll","nextUntil","prevUntil","contentDocument","contentWindow","reverse","readyList","rnotwhite","detach","removeEventListener","completed","detachEvent","event","readyState","Callbacks","object","flag","fire","locked","once","fired","firing","queue","firingIndex","memory","stopOnFalse","remove","disable","lock","fireWith","Deferred","func","tuples","state","promise","always","deferred","fail","then","fns","newDefer","tuple","returned","progress","notify","resolve","reject","pipe","stateString","when","subordinate","updateFunc","values","progressValues","notifyWith","remaining","resolveWith","progressContexts","resolveContexts","resolveValues","readyWait","holdReady","hold","wait","triggerHandler","off","doScroll","setTimeout","frameElement","doScrollCheck","inlineBlockNeedsLayout","body","container","style","cssText","zoom","offsetWidth","deleteExpando","acceptData","noData","shrinkWrapBlocksVal","rbrace","rmultiDash","dataAttr","parseJSON","isEmptyDataObject","internalData","pvt","thisCache","internalKey","isNode","toJSON","internalRemoveData","cleanData","applet ","embed ","object ","hasData","removeData","_data","_removeData","dequeue","startLength","hooks","_queueHooks","stop","setter","clearQueue","count","defer","shrinkWrapBlocks","width","isHidden","el","css","pnum","source","rcssNum","cssExpand","adjustCSS","prop","valueParts","tween","adjusted","scale","maxIterations","currentValue","initial","unit","cssNumber","initialInUnit","fragment","access","chainable","emptyGet","raw","bulk","rcheckableType","rtagName","rscriptType","rleadingWhitespace","nodeNames","createSafeFragment","safeFrag","createDocumentFragment","leadingWhitespace","tbody","htmlSerialize","html5Clone","cloneNode","outerHTML","appendChecked","noCloneChecked","checkClone","noCloneEvent","wrapMap","option","legend","area","param","thead","tr","col","td","_default","getAll","found","setGlobalEval","refElements","optgroup","tfoot","colgroup","caption","th","rhtml","rtbody","fixDefaultChecked","defaultChecked","buildFragment","scripts","selection","ignored","wrap","safe","nodes","htmlPrefilter","createTextNode","eventName","change","focusin","rformElems","rkeyEvent","rmouseEvent","rfocusMorph","rtypenamespace","returnTrue","returnFalse","safeActiveElement","err","on","types","one","origFn","events","t","handleObjIn","special","eventHandle","handleObj","handlers","namespaces","origType","elemData","handle","triggered","dispatch","delegateType","bindType","namespace","delegateCount","setup","mappedTypes","origCount","teardown","removeEvent","trigger","onlyHandlers","ontype","bubbleType","eventPath","Event","isTrigger","rnamespace","noBubble","parentWindow","isPropagationStopped","preventDefault","isDefaultPrevented","fix","handlerQueue","delegateTarget","preDispatch","currentTarget","isImmediatePropagationStopped","stopPropagation","postDispatch","sel","isNaN","originalEvent","fixHook","fixHooks","mouseHooks","keyHooks","props","srcElement","metaKey","original","which","charCode","keyCode","eventDoc","fromElement","pageX","clientX","scrollLeft","clientLeft","pageY","clientY","scrollTop","clientTop","relatedTarget","toElement","load","blur","click","beforeunload","returnValue","simulate","isSimulated","defaultPrevented","timeStamp","cancelBubble","stopImmediatePropagation","mouseenter","mouseleave","pointerenter","pointerleave","orig","related","form","_submitBubble","propertyName","_justChanged","attaches","rinlinejQuery","rnoshimcache","rxhtmlTag","rnoInnerhtml","rchecked","rscriptTypeMasked","rcleanScript","fragmentDiv","manipulationTarget","content","disableScript","restoreScript","cloneCopyEvent","dest","oldData","curData","fixCloneNodeIssues","defaultSelected","domManip","collection","hasScripts","iNoClone","html","_evalUrl","keepData","dataAndEvents","deepDataAndEvents","destElements","srcElements","inPage","forceAcceptData","append","prepend","insertBefore","before","after","replaceWith","replaceChild","appendTo","prependTo","insertAfter","replaceAll","insert","iframe","elemdisplay","HTML","BODY","actualDisplay","display","defaultDisplay","write","close","swap","old","pixelPositionVal","pixelMarginRightVal","boxSizingReliableVal","reliableHiddenOffsetsVal","reliableMarginRightVal","reliableMarginLeftVal","rmargin","rnumnonpx","computeStyleTests","divStyle","getComputedStyle","marginLeft","marginRight","getClientRects","offsetHeight","opacity","cssFloat","backgroundClip","clearCloneStyle","boxSizing","MozBoxSizing","WebkitBoxSizing","reliableHiddenOffsets","boxSizingReliable","pixelMarginRight","pixelPosition","reliableMarginRight","reliableMarginLeft","getStyles","curCSS","rposition","addGetHookIf","conditionFn","hookFn","view","opener","computed","minWidth","maxWidth","getPropertyValue","currentStyle","left","rs","rsLeft","runtimeStyle","pixelLeft","ralpha","ropacity","rdisplayswap","rnumsplit","cssShow","position","visibility","cssNormalTransform","letterSpacing","fontWeight","cssPrefixes","emptyStyle","vendorPropName","capName","showHide","show","hidden","setPositiveNumber","subtract","augmentWidthOrHeight","extra","isBorderBox","styles","getWidthOrHeight","valueIsBorderBox","msFullscreenElement","round","getBoundingClientRect","Tween","easing","cssHooks","animationIterationCount","columnCount","fillOpacity","flexGrow","flexShrink","lineHeight","order","orphans","widows","zIndex","cssProps","float","origName","set","isFinite","$1","margin","padding","border","prefix","suffix","expand","expanded","parts","hide","toggle","propHooks","run","percent","eased","duration","step","fx","linear","p","swing","cos","PI","fxNow","timerId","opt","rfxtypes","rrun","createFxNow","genFx","includeWidth","height","createTween","animation","Animation","tweeners","properties","stopped","prefilters","tick","currentTime","startTime","tweens","opts","specialEasing","originalProperties","originalOptions","gotoEnd","rejectWith","propFilter","timer","anim","complete","*","tweener","oldfire","dataShow","unqueued","overflow","overflowX","overflowY","prefilter","speed","speeds","fadeTo","to","animate","doAnimation","optall","finish","stopQueue","timers","cssFn","slideDown","slideUp","slideToggle","fadeIn","fadeOut","fadeToggle","interval","setInterval","clearInterval","slow","fast","delay","time","timeout","clearTimeout","getSetAttribute","hrefNormalized","checkOn","optSelected","enctype","optDisabled","radioValue","rreturn","valHooks","optionSet","scrollHeight","nodeHook","boolHook","ruseDefault","getSetInput","removeAttr","nType","attrHooks","propName","attrNames","propFix","getter","setAttributeNode","createAttribute","coords","contenteditable","rfocusable","rclickable","removeProp","tabindex","parseInt","for","class","rclass","getClass","addClass","classes","curValue","clazz","finalValue","removeClass","toggleClass","stateVal","classNames","hasClass","hover","fnOver","fnOut","nonce","rquery","rvalidtokens","JSON","parse","requireNonComma","depth","str","comma","open","Function","parseXML","DOMParser","parseFromString","ActiveXObject","async","loadXML","rhash","rts","rheaders","rnoContent","rprotocol","rurl","transports","allTypes","ajaxLocation","ajaxLocParts","addToPrefiltersOrTransports","structure","dataTypeExpression","dataType","dataTypes","inspectPrefiltersOrTransports","jqXHR","inspected","seekingTransport","inspect","prefilterOrFactory","dataTypeOrTransport","ajaxExtend","flatOptions","ajaxSettings","active","lastModified","etag","url","isLocal","processData","contentType","accepts","json","responseFields","converters","* text","text html","text json","text xml","ajaxSetup","settings","ajaxPrefilter","ajaxTransport","ajax","cacheURL","responseHeadersString","timeoutTimer","fireGlobals","transport","responseHeaders","s","callbackContext","globalEventContext","completeDeferred","statusCode","requestHeaders","requestHeadersNames","strAbort","getResponseHeader","getAllResponseHeaders","setRequestHeader","lname","overrideMimeType","mimeType","code","status","abort","statusText","finalText","success","method","crossDomain","traditional","hasContent","ifModified","headers","beforeSend","send","nativeStatusText","responses","isSuccess","response","modified","firstDataType","ct","finalDataType","ajaxHandleResponses","conv2","current","conv","dataFilter","ajaxConvert","getJSON","getScript","throws","wrapAll","wrapInner","unwrap","filterHidden","visible","r20","rbracket","rCRLF","rsubmitterTypes","rsubmittable","buildParams","v","encodeURIComponent","serialize","serializeArray","xhr","createActiveXHR","documentMode","createStandardXHR","xhrId","xhrCallbacks","xhrSupported","XMLHttpRequest","cors","username","xhrFields","isAbort","onreadystatechange","responseText","script","text script","head","scriptCharset","charset","onload","oldCallbacks","rjsonp","jsonp","jsonpCallback","originalSettings","callbackName","overwritten","responseContainer","jsonProp","createHTMLDocument","implementation","keepScripts","parsed","_load","getWindow","params","animated","offset","setOffset","curPosition","curLeft","curCSSTop","curTop","curOffset","curCSSLeft","curElem","using","win","box","pageYOffset","pageXOffset","offsetParent","parentOffset","scrollTo","Height","Width","","defaultExtra","funcName","bind","unbind","delegate","undelegate","size","andSelf","define","amd","_jQuery","_$","$","noConflict"],"mappings":"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","file":"jquery-1.12.1.min.js"}
\ No newline at end of file
diff --git skin/frontend/enterprise/default/css/styles.css skin/frontend/enterprise/default/css/styles.css
index 2d4d1606106..5965910abe8 100644
--- skin/frontend/enterprise/default/css/styles.css
+++ skin/frontend/enterprise/default/css/styles.css
@@ -1066,9 +1066,9 @@ ul.disc li { padding-left:10px; background:url(../images/bkg_bulletsm.gif) no-re
 
 /* Product Images */
 .product-view .product-img-box { float:left; width:370px; padding:26px 46px 26px 45px; }
-.product-view .product-img-box .product-image img { background:#fff; } /*IE8 PNG Fix */
+.product-view .product-img-box .product-image img { background:#fff; vertical-align:middle; max-height:100%; max-width:370px; } /*IE8 PNG Fix */
 .product-view .product-img-box p.notice { text-align:center; padding:5px 0; font-size:11px; }
-.product-view .product-img-box .product-image { position:relative; width:370px; height:370px; overflow:hidden; z-index:3; }
+.product-view .product-img-box .product-image { position:relative; width:370px; height:370px; line-height:370px; overflow:hidden; z-index:3; text-align:center; }
 .product-view .product-img-box .product-image-zoom { position:relative; width:370px; height:370px; overflow:hidden; z-index:3; }
 .product-view .product-img-box .product-image-zoom img { position:absolute; left:0; top:0; cursor:move; }
 .product-view .product-img-box .zoom-notice { text-align:center; }
@@ -1105,6 +1105,9 @@ p.product-image { cursor:default !important; }
 .preload { text-decoration:none; border:1px solid #ccc; padding:8px; text-align:center; background:#fff url(../images/zoomloader.gif) no-repeat 43px 30px; width:90px; height:43px; z-index:10; position:absolute; top:3px; left:3px; -moz-opacity:0.8; opacity:0.8; filter:alpha(opacity=80); }
 .jqZoomWindow { border:1px solid #ccc; background-color:#fff; }
 
+/* ElevateZoom */
+.zoomContainer { z-index:10; }
+
 /* Product Shop */
 .product-view .product-shop { float:right; width:416px; padding:0 30px; }
 .product-view .product-shop .product-main-info { margin:0 -30px 30px; padding:20px 30px 5px; background:#f6f6f6 url(../images/bkg_page-title.gif) repeat-x 0 0; border-bottom:1px solid #cfcfcf; }
diff --git skin/frontend/enterprise/default/js/lib/elevatezoom/jquery.elevateZoom-3.0.8.min.js skin/frontend/enterprise/default/js/lib/elevatezoom/jquery.elevateZoom-3.0.8.min.js
new file mode 100644
index 00000000000..e661087eb7f
--- /dev/null
+++ skin/frontend/enterprise/default/js/lib/elevatezoom/jquery.elevateZoom-3.0.8.min.js
@@ -0,0 +1,66 @@
+/* jQuery elevateZoom 3.0.8 - Demo's and documentation: - www.elevateweb.co.uk/image-zoom - Copyright (c) 2013 Andrew Eades - www.elevateweb.co.uk - Dual licensed under the LGPL licenses. - http://en.wikipedia.org/wiki/MIT_License - http://en.wikipedia.org/wiki/GNU_General_Public_License */
+"function"!==typeof Object.create&&(Object.create=function(d){function h(){}h.prototype=d;return new h});
+(function(d,h,l,m){var k={init:function(b,a){var c=this;c.elem=a;c.$elem=d(a);c.imageSrc=c.$elem.data("zoom-image")?c.$elem.data("zoom-image"):c.$elem.attr("src");c.options=d.extend({},d.fn.elevateZoom.options,b);c.options.tint&&(c.options.lensColour="none",c.options.lensOpacity="1");"inner"==c.options.zoomType&&(c.options.showLens=!1);c.$elem.parent().removeAttr("title").removeAttr("alt");c.zoomImage=c.imageSrc;c.refresh(1);d("#"+c.options.gallery+" a").click(function(a){c.options.galleryActiveClass&&
+(d("#"+c.options.gallery+" a").removeClass(c.options.galleryActiveClass),d(this).addClass(c.options.galleryActiveClass));a.preventDefault();d(this).data("zoom-image")?c.zoomImagePre=d(this).data("zoom-image"):c.zoomImagePre=d(this).data("image");c.swaptheimage(d(this).data("image"),c.zoomImagePre);return!1})},refresh:function(b){var a=this;setTimeout(function(){a.fetch(a.imageSrc)},b||a.options.refresh)},fetch:function(b){var a=this,c=new Image;c.onload=function(){a.largeWidth=c.width;a.largeHeight=
+c.height;a.startZoom();a.currentImage=a.imageSrc;a.options.onZoomedImageLoaded(a.$elem)};c.src=b},startZoom:function(){var b=this;b.nzWidth=b.$elem.width();b.nzHeight=b.$elem.height();b.isWindowActive=!1;b.isLensActive=!1;b.isTintActive=!1;b.overWindow=!1;b.options.imageCrossfade&&(b.zoomWrap=b.$elem.wrap('<div style="height:'+b.nzHeight+"px;width:"+b.nzWidth+'px;" class="zoomWrapper" />'),b.$elem.css("position","absolute"));b.zoomLock=1;b.scrollingLock=!1;b.changeBgSize=!1;b.currentZoomLevel=b.options.zoomLevel;
+b.nzOffset=b.$elem.offset();b.widthRatio=b.largeWidth/b.currentZoomLevel/b.nzWidth;b.heightRatio=b.largeHeight/b.currentZoomLevel/b.nzHeight;"window"==b.options.zoomType&&(b.zoomWindowStyle="overflow: hidden;background-position: 0px 0px;text-align:center;background-color: "+String(b.options.zoomWindowBgColour)+";width: "+String(b.options.zoomWindowWidth)+"px;height: "+String(b.options.zoomWindowHeight)+"px;float: left;background-size: "+b.largeWidth/b.currentZoomLevel+"px "+b.largeHeight/b.currentZoomLevel+
+"px;display: none;z-index:100;border: "+String(b.options.borderSize)+"px solid "+b.options.borderColour+";background-repeat: no-repeat;position: absolute;");if("inner"==b.options.zoomType){var a=b.$elem.css("border-left-width");b.zoomWindowStyle="overflow: hidden;margin-left: "+String(a)+";margin-top: "+String(a)+";background-position: 0px 0px;width: "+String(b.nzWidth)+"px;height: "+String(b.nzHeight)+"px;float: left;display: none;cursor:"+b.options.cursor+";px solid "+b.options.borderColour+";background-repeat: no-repeat;position: absolute;"}"window"==
+b.options.zoomType&&(lensHeight=b.nzHeight<b.options.zoomWindowWidth/b.widthRatio?b.nzHeight:String(b.options.zoomWindowHeight/b.heightRatio),lensWidth=b.largeWidth<b.options.zoomWindowWidth?b.nzWidth:b.options.zoomWindowWidth/b.widthRatio,b.lensStyle="background-position: 0px 0px;width: "+String(b.options.zoomWindowWidth/b.widthRatio)+"px;height: "+String(b.options.zoomWindowHeight/b.heightRatio)+"px;float: right;display: none;overflow: hidden;z-index: 999;-webkit-transform: translateZ(0);opacity:"+
+b.options.lensOpacity+";filter: alpha(opacity = "+100*b.options.lensOpacity+"); zoom:1;width:"+lensWidth+"px;height:"+lensHeight+"px;background-color:"+b.options.lensColour+";cursor:"+b.options.cursor+";border: "+b.options.lensBorderSize+"px solid "+b.options.lensBorderColour+";background-repeat: no-repeat;position: absolute;");b.tintStyle="display: block;position: absolute;background-color: "+b.options.tintColour+";filter:alpha(opacity=0);opacity: 0;width: "+b.nzWidth+"px;height: "+b.nzHeight+"px;";
+b.lensRound="";"lens"==b.options.zoomType&&(b.lensStyle="background-position: 0px 0px;float: left;display: none;border: "+String(b.options.borderSize)+"px solid "+b.options.borderColour+";width:"+String(b.options.lensSize)+"px;height:"+String(b.options.lensSize)+"px;background-repeat: no-repeat;position: absolute;");"round"==b.options.lensShape&&(b.lensRound="border-top-left-radius: "+String(b.options.lensSize/2+b.options.borderSize)+"px;border-top-right-radius: "+String(b.options.lensSize/2+b.options.borderSize)+
+"px;border-bottom-left-radius: "+String(b.options.lensSize/2+b.options.borderSize)+"px;border-bottom-right-radius: "+String(b.options.lensSize/2+b.options.borderSize)+"px;");b.zoomContainer=d('<div class="zoomContainer" style="-webkit-transform: translateZ(0);position:absolute;left:'+b.nzOffset.left+"px;top:"+b.nzOffset.top+"px;height:"+b.nzHeight+"px;width:"+b.nzWidth+'px;"></div>');d("body").append(b.zoomContainer);b.options.containLensZoom&&"lens"==b.options.zoomType&&b.zoomContainer.css("overflow",
+"hidden");"inner"!=b.options.zoomType&&(b.zoomLens=d("<div class='zoomLens' style='"+b.lensStyle+b.lensRound+"'>&nbsp;</div>").appendTo(b.zoomContainer).click(function(){b.$elem.trigger("click")}),b.options.tint&&(b.tintContainer=d("<div/>").addClass("tintContainer"),b.zoomTint=d("<div class='zoomTint' style='"+b.tintStyle+"'></div>"),b.zoomLens.wrap(b.tintContainer),b.zoomTintcss=b.zoomLens.after(b.zoomTint),b.zoomTintImage=d('<img style="position: absolute; left: 0px; top: 0px; max-width: none; width: '+
+b.nzWidth+"px; height: "+b.nzHeight+'px;" src="'+b.imageSrc+'">').appendTo(b.zoomLens).click(function(){b.$elem.trigger("click")})));isNaN(b.options.zoomWindowPosition)?b.zoomWindow=d("<div style='z-index:999;left:"+b.windowOffsetLeft+"px;top:"+b.windowOffsetTop+"px;"+b.zoomWindowStyle+"' class='zoomWindow'>&nbsp;</div>").appendTo("body").click(function(){b.$elem.trigger("click")}):b.zoomWindow=d("<div style='z-index:999;left:"+b.windowOffsetLeft+"px;top:"+b.windowOffsetTop+"px;"+b.zoomWindowStyle+
+"' class='zoomWindow'>&nbsp;</div>").appendTo(b.zoomContainer).click(function(){b.$elem.trigger("click")});b.zoomWindowContainer=d("<div/>").addClass("zoomWindowContainer").css("width",b.options.zoomWindowWidth);b.zoomWindow.wrap(b.zoomWindowContainer);"lens"==b.options.zoomType&&b.zoomLens.css({backgroundImage:"url('"+b.imageSrc+"')"});"window"==b.options.zoomType&&b.zoomWindow.css({backgroundImage:"url('"+b.imageSrc+"')"});"inner"==b.options.zoomType&&b.zoomWindow.css({backgroundImage:"url('"+b.imageSrc+
+"')"});b.$elem.bind("touchmove",function(a){a.preventDefault();b.setPosition(a.originalEvent.touches[0]||a.originalEvent.changedTouches[0])});b.zoomContainer.bind("touchmove",function(a){"inner"==b.options.zoomType&&b.showHideWindow("show");a.preventDefault();b.setPosition(a.originalEvent.touches[0]||a.originalEvent.changedTouches[0])});b.zoomContainer.bind("touchend",function(a){b.showHideWindow("hide");b.options.showLens&&b.showHideLens("hide");b.options.tint&&"inner"!=b.options.zoomType&&b.showHideTint("hide")});
+b.$elem.bind("touchend",function(a){b.showHideWindow("hide");b.options.showLens&&b.showHideLens("hide");b.options.tint&&"inner"!=b.options.zoomType&&b.showHideTint("hide")});b.options.showLens&&(b.zoomLens.bind("touchmove",function(a){a.preventDefault();b.setPosition(a.originalEvent.touches[0]||a.originalEvent.changedTouches[0])}),b.zoomLens.bind("touchend",function(a){b.showHideWindow("hide");b.options.showLens&&b.showHideLens("hide");b.options.tint&&"inner"!=b.options.zoomType&&b.showHideTint("hide")}));
+b.$elem.bind("mousemove",function(a){!1==b.overWindow&&b.setElements("show");if(b.lastX!==a.clientX||b.lastY!==a.clientY)b.setPosition(a),b.currentLoc=a;b.lastX=a.clientX;b.lastY=a.clientY});b.zoomContainer.bind("mousemove",function(a){!1==b.overWindow&&b.setElements("show");if(b.lastX!==a.clientX||b.lastY!==a.clientY)b.setPosition(a),b.currentLoc=a;b.lastX=a.clientX;b.lastY=a.clientY});"inner"!=b.options.zoomType&&b.zoomLens.bind("mousemove",function(a){if(b.lastX!==a.clientX||b.lastY!==a.clientY)b.setPosition(a),
+b.currentLoc=a;b.lastX=a.clientX;b.lastY=a.clientY});b.options.tint&&"inner"!=b.options.zoomType&&b.zoomTint.bind("mousemove",function(a){if(b.lastX!==a.clientX||b.lastY!==a.clientY)b.setPosition(a),b.currentLoc=a;b.lastX=a.clientX;b.lastY=a.clientY});"inner"==b.options.zoomType&&b.zoomWindow.bind("mousemove",function(a){if(b.lastX!==a.clientX||b.lastY!==a.clientY)b.setPosition(a),b.currentLoc=a;b.lastX=a.clientX;b.lastY=a.clientY});b.zoomContainer.add(b.$elem).mouseenter(function(){!1==b.overWindow&&
+b.setElements("show")}).mouseleave(function(){b.scrollLock||b.setElements("hide")});"inner"!=b.options.zoomType&&b.zoomWindow.mouseenter(function(){b.overWindow=!0;b.setElements("hide")}).mouseleave(function(){b.overWindow=!1});b.minZoomLevel=b.options.minZoomLevel?b.options.minZoomLevel:2*b.options.scrollZoomIncrement;b.options.scrollZoom&&b.zoomContainer.add(b.$elem).bind("mousewheel DOMMouseScroll MozMousePixelScroll",function(a){b.scrollLock=!0;clearTimeout(d.data(this,"timer"));d.data(this,"timer",
+setTimeout(function(){b.scrollLock=!1},250));var e=a.originalEvent.wheelDelta||-1*a.originalEvent.detail;a.stopImmediatePropagation();a.stopPropagation();a.preventDefault();0<e/120?b.currentZoomLevel>=b.minZoomLevel&&b.changeZoomLevel(b.currentZoomLevel-b.options.scrollZoomIncrement):b.options.maxZoomLevel?b.currentZoomLevel<=b.options.maxZoomLevel&&b.changeZoomLevel(parseFloat(b.currentZoomLevel)+b.options.scrollZoomIncrement):b.changeZoomLevel(parseFloat(b.currentZoomLevel)+b.options.scrollZoomIncrement);
+return!1})},setElements:function(b){if(!this.options.zoomEnabled)return!1;"show"==b&&this.isWindowSet&&("inner"==this.options.zoomType&&this.showHideWindow("show"),"window"==this.options.zoomType&&this.showHideWindow("show"),this.options.showLens&&this.showHideLens("show"),this.options.tint&&"inner"!=this.options.zoomType&&this.showHideTint("show"));"hide"==b&&("window"==this.options.zoomType&&this.showHideWindow("hide"),this.options.tint||this.showHideWindow("hide"),this.options.showLens&&this.showHideLens("hide"),
+this.options.tint&&this.showHideTint("hide"))},setPosition:function(b){if(!this.options.zoomEnabled)return!1;this.nzHeight=this.$elem.height();this.nzWidth=this.$elem.width();this.nzOffset=this.$elem.offset();this.options.tint&&"inner"!=this.options.zoomType&&(this.zoomTint.css({top:0}),this.zoomTint.css({left:0}));this.options.responsive&&!this.options.scrollZoom&&this.options.showLens&&(lensHeight=this.nzHeight<this.options.zoomWindowWidth/this.widthRatio?this.nzHeight:String(this.options.zoomWindowHeight/
+this.heightRatio),lensWidth=this.largeWidth<this.options.zoomWindowWidth?this.nzWidth:this.options.zoomWindowWidth/this.widthRatio,this.widthRatio=this.largeWidth/this.nzWidth,this.heightRatio=this.largeHeight/this.nzHeight,"lens"!=this.options.zoomType&&(lensHeight=this.nzHeight<this.options.zoomWindowWidth/this.widthRatio?this.nzHeight:String(this.options.zoomWindowHeight/this.heightRatio),lensWidth=this.options.zoomWindowWidth<this.options.zoomWindowWidth?this.nzWidth:this.options.zoomWindowWidth/
+this.widthRatio,this.zoomLens.css("width",lensWidth),this.zoomLens.css("height",lensHeight),this.options.tint&&(this.zoomTintImage.css("width",this.nzWidth),this.zoomTintImage.css("height",this.nzHeight))),"lens"==this.options.zoomType&&this.zoomLens.css({width:String(this.options.lensSize)+"px",height:String(this.options.lensSize)+"px"}));this.zoomContainer.css({top:this.nzOffset.top});this.zoomContainer.css({left:this.nzOffset.left});this.mouseLeft=parseInt(b.pageX-this.nzOffset.left);this.mouseTop=
+parseInt(b.pageY-this.nzOffset.top);"window"==this.options.zoomType&&(this.Etoppos=this.mouseTop<this.zoomLens.height()/2,this.Eboppos=this.mouseTop>this.nzHeight-this.zoomLens.height()/2-2*this.options.lensBorderSize,this.Eloppos=this.mouseLeft<0+this.zoomLens.width()/2,this.Eroppos=this.mouseLeft>this.nzWidth-this.zoomLens.width()/2-2*this.options.lensBorderSize);"inner"==this.options.zoomType&&(this.Etoppos=this.mouseTop<this.nzHeight/2/this.heightRatio,this.Eboppos=this.mouseTop>this.nzHeight-
+this.nzHeight/2/this.heightRatio,this.Eloppos=this.mouseLeft<0+this.nzWidth/2/this.widthRatio,this.Eroppos=this.mouseLeft>this.nzWidth-this.nzWidth/2/this.widthRatio-2*this.options.lensBorderSize);0>=this.mouseLeft||0>this.mouseTop||this.mouseLeft>this.nzWidth||this.mouseTop>this.nzHeight?this.setElements("hide"):(this.options.showLens&&(this.lensLeftPos=String(this.mouseLeft-this.zoomLens.width()/2),this.lensTopPos=String(this.mouseTop-this.zoomLens.height()/2)),this.Etoppos&&(this.lensTopPos=0),
+this.Eloppos&&(this.tintpos=this.lensLeftPos=this.windowLeftPos=0),"window"==this.options.zoomType&&(this.Eboppos&&(this.lensTopPos=Math.max(this.nzHeight-this.zoomLens.height()-2*this.options.lensBorderSize,0)),this.Eroppos&&(this.lensLeftPos=this.nzWidth-this.zoomLens.width()-2*this.options.lensBorderSize)),"inner"==this.options.zoomType&&(this.Eboppos&&(this.lensTopPos=Math.max(this.nzHeight-2*this.options.lensBorderSize,0)),this.Eroppos&&(this.lensLeftPos=this.nzWidth-this.nzWidth-2*this.options.lensBorderSize)),
+"lens"==this.options.zoomType&&(this.windowLeftPos=String(-1*((b.pageX-this.nzOffset.left)*this.widthRatio-this.zoomLens.width()/2)),this.windowTopPos=String(-1*((b.pageY-this.nzOffset.top)*this.heightRatio-this.zoomLens.height()/2)),this.zoomLens.css({backgroundPosition:this.windowLeftPos+"px "+this.windowTopPos+"px"}),this.changeBgSize&&(this.nzHeight>this.nzWidth?("lens"==this.options.zoomType&&this.zoomLens.css({"background-size":this.largeWidth/this.newvalueheight+"px "+this.largeHeight/this.newvalueheight+
+"px"}),this.zoomWindow.css({"background-size":this.largeWidth/this.newvalueheight+"px "+this.largeHeight/this.newvalueheight+"px"})):("lens"==this.options.zoomType&&this.zoomLens.css({"background-size":this.largeWidth/this.newvaluewidth+"px "+this.largeHeight/this.newvaluewidth+"px"}),this.zoomWindow.css({"background-size":this.largeWidth/this.newvaluewidth+"px "+this.largeHeight/this.newvaluewidth+"px"})),this.changeBgSize=!1),this.setWindowPostition(b)),this.options.tint&&"inner"!=this.options.zoomType&&
+this.setTintPosition(b),"window"==this.options.zoomType&&this.setWindowPostition(b),"inner"==this.options.zoomType&&this.setWindowPostition(b),this.options.showLens&&(this.fullwidth&&"lens"!=this.options.zoomType&&(this.lensLeftPos=0),this.zoomLens.css({left:this.lensLeftPos+"px",top:this.lensTopPos+"px"})))},showHideWindow:function(b){"show"!=b||this.isWindowActive||(this.options.zoomWindowFadeIn?this.zoomWindow.stop(!0,!0,!1).fadeIn(this.options.zoomWindowFadeIn):this.zoomWindow.show(),this.isWindowActive=
+!0);"hide"==b&&this.isWindowActive&&(this.options.zoomWindowFadeOut?this.zoomWindow.stop(!0,!0).fadeOut(this.options.zoomWindowFadeOut):this.zoomWindow.hide(),this.isWindowActive=!1)},showHideLens:function(b){"show"!=b||this.isLensActive||(this.options.lensFadeIn?this.zoomLens.stop(!0,!0,!1).fadeIn(this.options.lensFadeIn):this.zoomLens.show(),this.isLensActive=!0);"hide"==b&&this.isLensActive&&(this.options.lensFadeOut?this.zoomLens.stop(!0,!0).fadeOut(this.options.lensFadeOut):this.zoomLens.hide(),
+this.isLensActive=!1)},showHideTint:function(b){"show"!=b||this.isTintActive||(this.options.zoomTintFadeIn?this.zoomTint.css({opacity:this.options.tintOpacity}).animate().stop(!0,!0).fadeIn("slow"):(this.zoomTint.css({opacity:this.options.tintOpacity}).animate(),this.zoomTint.show()),this.isTintActive=!0);"hide"==b&&this.isTintActive&&(this.options.zoomTintFadeOut?this.zoomTint.stop(!0,!0).fadeOut(this.options.zoomTintFadeOut):this.zoomTint.hide(),this.isTintActive=!1)},setLensPostition:function(b){},
+setWindowPostition:function(b){var a=this;if(isNaN(a.options.zoomWindowPosition))a.externalContainer=d("#"+a.options.zoomWindowPosition),a.externalContainerWidth=a.externalContainer.width(),a.externalContainerHeight=a.externalContainer.height(),a.externalContainerOffset=a.externalContainer.offset(),a.windowOffsetTop=a.externalContainerOffset.top,a.windowOffsetLeft=a.externalContainerOffset.left;else switch(a.options.zoomWindowPosition){case 1:a.windowOffsetTop=a.options.zoomWindowOffety;a.windowOffsetLeft=
++a.nzWidth;break;case 2:a.options.zoomWindowHeight>a.nzHeight&&(a.windowOffsetTop=-1*(a.options.zoomWindowHeight/2-a.nzHeight/2),a.windowOffsetLeft=a.nzWidth);break;case 3:a.windowOffsetTop=a.nzHeight-a.zoomWindow.height()-2*a.options.borderSize;a.windowOffsetLeft=a.nzWidth;break;case 4:a.windowOffsetTop=a.nzHeight;a.windowOffsetLeft=a.nzWidth;break;case 5:a.windowOffsetTop=a.nzHeight;a.windowOffsetLeft=a.nzWidth-a.zoomWindow.width()-2*a.options.borderSize;break;case 6:a.options.zoomWindowHeight>
+a.nzHeight&&(a.windowOffsetTop=a.nzHeight,a.windowOffsetLeft=-1*(a.options.zoomWindowWidth/2-a.nzWidth/2+2*a.options.borderSize));break;case 7:a.windowOffsetTop=a.nzHeight;a.windowOffsetLeft=0;break;case 8:a.windowOffsetTop=a.nzHeight;a.windowOffsetLeft=-1*(a.zoomWindow.width()+2*a.options.borderSize);break;case 9:a.windowOffsetTop=a.nzHeight-a.zoomWindow.height()-2*a.options.borderSize;a.windowOffsetLeft=-1*(a.zoomWindow.width()+2*a.options.borderSize);break;case 10:a.options.zoomWindowHeight>a.nzHeight&&
+(a.windowOffsetTop=-1*(a.options.zoomWindowHeight/2-a.nzHeight/2),a.windowOffsetLeft=-1*(a.zoomWindow.width()+2*a.options.borderSize));break;case 11:a.windowOffsetTop=a.options.zoomWindowOffety;a.windowOffsetLeft=-1*(a.zoomWindow.width()+2*a.options.borderSize);break;case 12:a.windowOffsetTop=-1*(a.zoomWindow.height()+2*a.options.borderSize);a.windowOffsetLeft=-1*(a.zoomWindow.width()+2*a.options.borderSize);break;case 13:a.windowOffsetTop=-1*(a.zoomWindow.height()+2*a.options.borderSize);a.windowOffsetLeft=
+0;break;case 14:a.options.zoomWindowHeight>a.nzHeight&&(a.windowOffsetTop=-1*(a.zoomWindow.height()+2*a.options.borderSize),a.windowOffsetLeft=-1*(a.options.zoomWindowWidth/2-a.nzWidth/2+2*a.options.borderSize));break;case 15:a.windowOffsetTop=-1*(a.zoomWindow.height()+2*a.options.borderSize);a.windowOffsetLeft=a.nzWidth-a.zoomWindow.width()-2*a.options.borderSize;break;case 16:a.windowOffsetTop=-1*(a.zoomWindow.height()+2*a.options.borderSize);a.windowOffsetLeft=a.nzWidth;break;default:a.windowOffsetTop=
+a.options.zoomWindowOffety,a.windowOffsetLeft=a.nzWidth}a.isWindowSet=!0;a.windowOffsetTop+=a.options.zoomWindowOffety;a.windowOffsetLeft+=a.options.zoomWindowOffetx;a.zoomWindow.css({top:a.windowOffsetTop});a.zoomWindow.css({left:a.windowOffsetLeft});"inner"==a.options.zoomType&&(a.zoomWindow.css({top:0}),a.zoomWindow.css({left:0}));a.windowLeftPos=String(-1*((b.pageX-a.nzOffset.left)*a.widthRatio-a.zoomWindow.width()/2));a.windowTopPos=String(-1*((b.pageY-a.nzOffset.top)*a.heightRatio-a.zoomWindow.height()/
+2));a.Etoppos&&(a.windowTopPos=0);a.Eloppos&&(a.windowLeftPos=0);a.Eboppos&&(a.windowTopPos=-1*(a.largeHeight/a.currentZoomLevel-a.zoomWindow.height()));a.Eroppos&&(a.windowLeftPos=-1*(a.largeWidth/a.currentZoomLevel-a.zoomWindow.width()));a.fullheight&&(a.windowTopPos=0);a.fullwidth&&(a.windowLeftPos=0);if("window"==a.options.zoomType||"inner"==a.options.zoomType)1==a.zoomLock&&(1>=a.widthRatio&&(a.windowLeftPos=0),1>=a.heightRatio&&(a.windowTopPos=0)),a.largeHeight<a.options.zoomWindowHeight&&(a.windowTopPos=
+0),a.largeWidth<a.options.zoomWindowWidth&&(a.windowLeftPos=0),a.options.easing?(a.xp||(a.xp=0),a.yp||(a.yp=0),a.loop||(a.loop=setInterval(function(){a.xp+=(a.windowLeftPos-a.xp)/a.options.easingAmount;a.yp+=(a.windowTopPos-a.yp)/a.options.easingAmount;a.scrollingLock?(clearInterval(a.loop),a.xp=a.windowLeftPos,a.yp=a.windowTopPos,a.xp=-1*((b.pageX-a.nzOffset.left)*a.widthRatio-a.zoomWindow.width()/2),a.yp=-1*((b.pageY-a.nzOffset.top)*a.heightRatio-a.zoomWindow.height()/2),a.changeBgSize&&(a.nzHeight>
+a.nzWidth?("lens"==a.options.zoomType&&a.zoomLens.css({"background-size":a.largeWidth/a.newvalueheight+"px "+a.largeHeight/a.newvalueheight+"px"}),a.zoomWindow.css({"background-size":a.largeWidth/a.newvalueheight+"px "+a.largeHeight/a.newvalueheight+"px"})):("lens"!=a.options.zoomType&&a.zoomLens.css({"background-size":a.largeWidth/a.newvaluewidth+"px "+a.largeHeight/a.newvalueheight+"px"}),a.zoomWindow.css({"background-size":a.largeWidth/a.newvaluewidth+"px "+a.largeHeight/a.newvaluewidth+"px"})),
+a.changeBgSize=!1),a.zoomWindow.css({backgroundPosition:a.windowLeftPos+"px "+a.windowTopPos+"px"}),a.scrollingLock=!1,a.loop=!1):(a.changeBgSize&&(a.nzHeight>a.nzWidth?("lens"==a.options.zoomType&&a.zoomLens.css({"background-size":a.largeWidth/a.newvalueheight+"px "+a.largeHeight/a.newvalueheight+"px"}),a.zoomWindow.css({"background-size":a.largeWidth/a.newvalueheight+"px "+a.largeHeight/a.newvalueheight+"px"})):("lens"!=a.options.zoomType&&a.zoomLens.css({"background-size":a.largeWidth/a.newvaluewidth+
+"px "+a.largeHeight/a.newvaluewidth+"px"}),a.zoomWindow.css({"background-size":a.largeWidth/a.newvaluewidth+"px "+a.largeHeight/a.newvaluewidth+"px"})),a.changeBgSize=!1),a.zoomWindow.css({backgroundPosition:a.xp+"px "+a.yp+"px"}))},16))):(a.changeBgSize&&(a.nzHeight>a.nzWidth?("lens"==a.options.zoomType&&a.zoomLens.css({"background-size":a.largeWidth/a.newvalueheight+"px "+a.largeHeight/a.newvalueheight+"px"}),a.zoomWindow.css({"background-size":a.largeWidth/a.newvalueheight+"px "+a.largeHeight/
+a.newvalueheight+"px"})):("lens"==a.options.zoomType&&a.zoomLens.css({"background-size":a.largeWidth/a.newvaluewidth+"px "+a.largeHeight/a.newvaluewidth+"px"}),a.largeHeight/a.newvaluewidth<a.options.zoomWindowHeight?a.zoomWindow.css({"background-size":a.largeWidth/a.newvaluewidth+"px "+a.largeHeight/a.newvaluewidth+"px"}):a.zoomWindow.css({"background-size":a.largeWidth/a.newvalueheight+"px "+a.largeHeight/a.newvalueheight+"px"})),a.changeBgSize=!1),a.zoomWindow.css({backgroundPosition:a.windowLeftPos+
+"px "+a.windowTopPos+"px"}))},setTintPosition:function(b){this.nzOffset=this.$elem.offset();this.tintpos=String(-1*(b.pageX-this.nzOffset.left-this.zoomLens.width()/2));this.tintposy=String(-1*(b.pageY-this.nzOffset.top-this.zoomLens.height()/2));this.Etoppos&&(this.tintposy=0);this.Eloppos&&(this.tintpos=0);this.Eboppos&&(this.tintposy=-1*(this.nzHeight-this.zoomLens.height()-2*this.options.lensBorderSize));this.Eroppos&&(this.tintpos=-1*(this.nzWidth-this.zoomLens.width()-2*this.options.lensBorderSize));
+this.options.tint&&(this.fullheight&&(this.tintposy=0),this.fullwidth&&(this.tintpos=0),this.zoomTintImage.css({left:this.tintpos+"px"}),this.zoomTintImage.css({top:this.tintposy+"px"}))},swaptheimage:function(b,a){var c=this,e=new Image;c.options.loadingIcon&&(c.spinner=d("<div style=\"background: url('"+c.options.loadingIcon+"') no-repeat center;height:"+c.nzHeight+"px;width:"+c.nzWidth+'px;z-index: 2000;position: absolute; background-position: center center;"></div>'),c.$elem.after(c.spinner));
+c.options.onImageSwap(c.$elem);e.onload=function(){c.largeWidth=e.width;c.largeHeight=e.height;c.zoomImage=a;c.zoomWindow.css({"background-size":c.largeWidth+"px "+c.largeHeight+"px"});c.zoomWindow.css({"background-size":c.largeWidth+"px "+c.largeHeight+"px"});c.swapAction(b,a)};e.src=a},swapAction:function(b,a){var c=this,e=new Image;e.onload=function(){c.nzHeight=e.height;c.nzWidth=e.width;c.options.onImageSwapComplete(c.$elem);c.doneCallback()};e.src=b;c.currentZoomLevel=c.options.zoomLevel;c.options.maxZoomLevel=
+!1;"lens"==c.options.zoomType&&c.zoomLens.css({backgroundImage:"url('"+a+"')"});"window"==c.options.zoomType&&c.zoomWindow.css({backgroundImage:"url('"+a+"')"});"inner"==c.options.zoomType&&c.zoomWindow.css({backgroundImage:"url('"+a+"')"});c.currentImage=a;if(c.options.imageCrossfade){var f=c.$elem,g=f.clone();c.$elem.attr("src",b);c.$elem.after(g);g.stop(!0).fadeOut(c.options.imageCrossfade,function(){d(this).remove()});c.$elem.width("auto").removeAttr("width");c.$elem.height("auto").removeAttr("height");
+f.fadeIn(c.options.imageCrossfade);c.options.tint&&"inner"!=c.options.zoomType&&(f=c.zoomTintImage,g=f.clone(),c.zoomTintImage.attr("src",a),c.zoomTintImage.after(g),g.stop(!0).fadeOut(c.options.imageCrossfade,function(){d(this).remove()}),f.fadeIn(c.options.imageCrossfade),c.zoomTint.css({height:c.$elem.height()}),c.zoomTint.css({width:c.$elem.width()}));c.zoomContainer.css("height",c.$elem.height());c.zoomContainer.css("width",c.$elem.width());"inner"!=c.options.zoomType||c.options.constrainType||
+(c.zoomWrap.parent().css("height",c.$elem.height()),c.zoomWrap.parent().css("width",c.$elem.width()),c.zoomWindow.css("height",c.$elem.height()),c.zoomWindow.css("width",c.$elem.width()))}else c.$elem.attr("src",b),c.options.tint&&(c.zoomTintImage.attr("src",a),c.zoomTintImage.attr("height",c.$elem.height()),c.zoomTintImage.css({height:c.$elem.height()}),c.zoomTint.css({height:c.$elem.height()})),c.zoomContainer.css("height",c.$elem.height()),c.zoomContainer.css("width",c.$elem.width());c.options.imageCrossfade&&
+(c.zoomWrap.css("height",c.$elem.height()),c.zoomWrap.css("width",c.$elem.width()));c.options.constrainType&&("height"==c.options.constrainType&&(c.zoomContainer.css("height",c.options.constrainSize),c.zoomContainer.css("width","auto"),c.options.imageCrossfade?(c.zoomWrap.css("height",c.options.constrainSize),c.zoomWrap.css("width","auto"),c.constwidth=c.zoomWrap.width()):(c.$elem.css("height",c.options.constrainSize),c.$elem.css("width","auto"),c.constwidth=c.$elem.width()),"inner"==c.options.zoomType&&
+(c.zoomWrap.parent().css("height",c.options.constrainSize),c.zoomWrap.parent().css("width",c.constwidth),c.zoomWindow.css("height",c.options.constrainSize),c.zoomWindow.css("width",c.constwidth)),c.options.tint&&(c.tintContainer.css("height",c.options.constrainSize),c.tintContainer.css("width",c.constwidth),c.zoomTint.css("height",c.options.constrainSize),c.zoomTint.css("width",c.constwidth),c.zoomTintImage.css("height",c.options.constrainSize),c.zoomTintImage.css("width",c.constwidth))),"width"==
+c.options.constrainType&&(c.zoomContainer.css("height","auto"),c.zoomContainer.css("width",c.options.constrainSize),c.options.imageCrossfade?(c.zoomWrap.css("height","auto"),c.zoomWrap.css("width",c.options.constrainSize),c.constheight=c.zoomWrap.height()):(c.$elem.css("height","auto"),c.$elem.css("width",c.options.constrainSize),c.constheight=c.$elem.height()),"inner"==c.options.zoomType&&(c.zoomWrap.parent().css("height",c.constheight),c.zoomWrap.parent().css("width",c.options.constrainSize),c.zoomWindow.css("height",
+c.constheight),c.zoomWindow.css("width",c.options.constrainSize)),c.options.tint&&(c.tintContainer.css("height",c.constheight),c.tintContainer.css("width",c.options.constrainSize),c.zoomTint.css("height",c.constheight),c.zoomTint.css("width",c.options.constrainSize),c.zoomTintImage.css("height",c.constheight),c.zoomTintImage.css("width",c.options.constrainSize))))},doneCallback:function(){this.options.loadingIcon&&this.spinner.hide();this.nzOffset=this.$elem.offset();this.nzWidth=this.$elem.width();
+this.nzHeight=this.$elem.height();this.currentZoomLevel=this.options.zoomLevel;this.widthRatio=this.largeWidth/this.nzWidth;this.heightRatio=this.largeHeight/this.nzHeight;"window"==this.options.zoomType&&(lensHeight=this.nzHeight<this.options.zoomWindowWidth/this.widthRatio?this.nzHeight:String(this.options.zoomWindowHeight/this.heightRatio),lensWidth=this.options.zoomWindowWidth<this.options.zoomWindowWidth?this.nzWidth:this.options.zoomWindowWidth/this.widthRatio,this.zoomLens&&(this.zoomLens.css("width",
+lensWidth),this.zoomLens.css("height",lensHeight)))},getCurrentImage:function(){return this.zoomImage},getGalleryList:function(){var b=this;b.gallerylist=[];b.options.gallery?d("#"+b.options.gallery+" a").each(function(){var a="";d(this).data("zoom-image")?a=d(this).data("zoom-image"):d(this).data("image")&&(a=d(this).data("image"));a==b.zoomImage?b.gallerylist.unshift({href:""+a+"",title:d(this).find("img").attr("title")}):b.gallerylist.push({href:""+a+"",title:d(this).find("img").attr("title")})}):
+b.gallerylist.push({href:""+b.zoomImage+"",title:d(this).find("img").attr("title")});return b.gallerylist},changeZoomLevel:function(b){this.scrollingLock=!0;this.newvalue=parseFloat(b).toFixed(2);newvalue=parseFloat(b).toFixed(2);maxheightnewvalue=this.largeHeight/(this.options.zoomWindowHeight/this.nzHeight*this.nzHeight);maxwidthtnewvalue=this.largeWidth/(this.options.zoomWindowWidth/this.nzWidth*this.nzWidth);"inner"!=this.options.zoomType&&(maxheightnewvalue<=newvalue?(this.heightRatio=this.largeHeight/
+maxheightnewvalue/this.nzHeight,this.newvalueheight=maxheightnewvalue,this.fullheight=!0):(this.heightRatio=this.largeHeight/newvalue/this.nzHeight,this.newvalueheight=newvalue,this.fullheight=!1),maxwidthtnewvalue<=newvalue?(this.widthRatio=this.largeWidth/maxwidthtnewvalue/this.nzWidth,this.newvaluewidth=maxwidthtnewvalue,this.fullwidth=!0):(this.widthRatio=this.largeWidth/newvalue/this.nzWidth,this.newvaluewidth=newvalue,this.fullwidth=!1),"lens"==this.options.zoomType&&(maxheightnewvalue<=newvalue?
+(this.fullwidth=!0,this.newvaluewidth=maxheightnewvalue):(this.widthRatio=this.largeWidth/newvalue/this.nzWidth,this.newvaluewidth=newvalue,this.fullwidth=!1)));"inner"==this.options.zoomType&&(maxheightnewvalue=parseFloat(this.largeHeight/this.nzHeight).toFixed(2),maxwidthtnewvalue=parseFloat(this.largeWidth/this.nzWidth).toFixed(2),newvalue>maxheightnewvalue&&(newvalue=maxheightnewvalue),newvalue>maxwidthtnewvalue&&(newvalue=maxwidthtnewvalue),maxheightnewvalue<=newvalue?(this.heightRatio=this.largeHeight/
+newvalue/this.nzHeight,this.newvalueheight=newvalue>maxheightnewvalue?maxheightnewvalue:newvalue,this.fullheight=!0):(this.heightRatio=this.largeHeight/newvalue/this.nzHeight,this.newvalueheight=newvalue>maxheightnewvalue?maxheightnewvalue:newvalue,this.fullheight=!1),maxwidthtnewvalue<=newvalue?(this.widthRatio=this.largeWidth/newvalue/this.nzWidth,this.newvaluewidth=newvalue>maxwidthtnewvalue?maxwidthtnewvalue:newvalue,this.fullwidth=!0):(this.widthRatio=this.largeWidth/newvalue/this.nzWidth,this.newvaluewidth=
+newvalue,this.fullwidth=!1));scrcontinue=!1;"inner"==this.options.zoomType&&(this.nzWidth>this.nzHeight&&(this.newvaluewidth<=maxwidthtnewvalue?scrcontinue=!0:(scrcontinue=!1,this.fullwidth=this.fullheight=!0)),this.nzHeight>this.nzWidth&&(this.newvaluewidth<=maxwidthtnewvalue?scrcontinue=!0:(scrcontinue=!1,this.fullwidth=this.fullheight=!0)));"inner"!=this.options.zoomType&&(scrcontinue=!0);scrcontinue&&(this.zoomLock=0,this.changeZoom=!0,this.options.zoomWindowHeight/this.heightRatio<=this.nzHeight&&
+(this.currentZoomLevel=this.newvalueheight,"lens"!=this.options.zoomType&&"inner"!=this.options.zoomType&&(this.changeBgSize=!0,this.zoomLens.css({height:String(this.options.zoomWindowHeight/this.heightRatio)+"px"})),"lens"==this.options.zoomType||"inner"==this.options.zoomType)&&(this.changeBgSize=!0),this.options.zoomWindowWidth/this.widthRatio<=this.nzWidth&&("inner"!=this.options.zoomType&&this.newvaluewidth>this.newvalueheight&&(this.currentZoomLevel=this.newvaluewidth),"lens"!=this.options.zoomType&&
+"inner"!=this.options.zoomType&&(this.changeBgSize=!0,this.zoomLens.css({width:String(this.options.zoomWindowWidth/this.widthRatio)+"px"})),"lens"==this.options.zoomType||"inner"==this.options.zoomType)&&(this.changeBgSize=!0),"inner"==this.options.zoomType&&(this.changeBgSize=!0,this.nzWidth>this.nzHeight&&(this.currentZoomLevel=this.newvaluewidth),this.nzHeight>this.nzWidth&&(this.currentZoomLevel=this.newvaluewidth)));this.setPosition(this.currentLoc)},closeAll:function(){self.zoomWindow&&self.zoomWindow.hide();
+self.zoomLens&&self.zoomLens.hide();self.zoomTint&&self.zoomTint.hide()},changeState:function(b){"enable"==b&&(this.options.zoomEnabled=!0);"disable"==b&&(this.options.zoomEnabled=!1)}};d.fn.elevateZoom=function(b){return this.each(function(){var a=Object.create(k);a.init(b,this);d.data(this,"elevateZoom",a)})};d.fn.elevateZoom.options={zoomActivation:"hover",zoomEnabled:!0,preloading:1,zoomLevel:1,scrollZoom:!1,scrollZoomIncrement:0.1,minZoomLevel:!1,maxZoomLevel:!1,easing:!1,easingAmount:12,lensSize:200,
+zoomWindowWidth:400,zoomWindowHeight:400,zoomWindowOffetx:0,zoomWindowOffety:0,zoomWindowPosition:1,zoomWindowBgColour:"#fff",lensFadeIn:!1,lensFadeOut:!1,debug:!1,zoomWindowFadeIn:!1,zoomWindowFadeOut:!1,zoomWindowAlwaysShow:!1,zoomTintFadeIn:!1,zoomTintFadeOut:!1,borderSize:4,showLens:!0,borderColour:"#888",lensBorderSize:1,lensBorderColour:"#000",lensShape:"square",zoomType:"window",containLensZoom:!1,lensColour:"white",lensOpacity:0.4,lenszoom:!1,tint:!1,tintColour:"#333",tintOpacity:0.4,gallery:!1,
+galleryActiveClass:"zoomGalleryActive",imageCrossfade:!1,constrainType:!1,constrainSize:!1,loadingIcon:!1,cursor:"default",responsive:!0,onComplete:d.noop,onZoomedImageLoaded:function(){},onImageSwap:d.noop,onImageSwapComplete:d.noop}})(jQuery,window,document);
diff --git skin/frontend/enterprise/default/js/lib/jquery/jquery-1.12.1.min.js skin/frontend/enterprise/default/js/lib/jquery/jquery-1.12.1.min.js
new file mode 100644
index 00000000000..432dc5c9092
--- /dev/null
+++ skin/frontend/enterprise/default/js/lib/jquery/jquery-1.12.1.min.js
@@ -0,0 +1,2 @@
+!function(e,t){"object"==typeof module&&"object"==typeof module.exports?module.exports=e.document?t(e,!0):function(e){if(!e.document)throw new Error("jQuery requires a window with a document");return t(e)}:t(e)}("undefined"!=typeof window?window:this,function(C,e){function t(e,t){return t.toUpperCase()}var f=[],h=C.document,c=f.slice,m=f.concat,s=f.push,i=f.indexOf,n={},r=n.toString,g=n.hasOwnProperty,v={},o="1.12.1",E=function(e,t){return new E.fn.init(e,t)},a=/^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g,u=/^-ms-/,l=/-([\da-z])/gi;function d(e){var t=!!e&&"length"in e&&e.length,n=E.type(e);return"function"!==n&&!E.isWindow(e)&&("array"===n||0===t||"number"==typeof t&&0<t&&t-1 in e)}E.fn=E.prototype={jquery:o,constructor:E,selector:"",length:0,toArray:function(){return c.call(this)},get:function(e){return null!=e?e<0?this[e+this.length]:this[e]:c.call(this)},pushStack:function(e){var t=E.merge(this.constructor(),e);return t.prevObject=this,t.context=this.context,t},each:function(e){return E.each(this,e)},map:function(n){return this.pushStack(E.map(this,function(e,t){return n.call(e,t,e)}))},slice:function(){return this.pushStack(c.apply(this,arguments))},first:function(){return this.eq(0)},last:function(){return this.eq(-1)},eq:function(e){var t=this.length,n=+e+(e<0?t:0);return this.pushStack(0<=n&&n<t?[this[n]]:[])},end:function(){return this.prevObject||this.constructor()},push:s,sort:f.sort,splice:f.splice},E.extend=E.fn.extend=function(){var e,t,n,r,i,o,a=arguments[0]||{},s=1,u=arguments.length,l=!1;for("boolean"==typeof a&&(l=a,a=arguments[s]||{},s++),"object"==typeof a||E.isFunction(a)||(a={}),s===u&&(a=this,s--);s<u;s++)if(null!=(i=arguments[s]))for(r in i)e=a[r],n=i[r],"__proto__"!==r&&a!==n&&(l&&n&&(E.isPlainObject(n)||(t=E.isArray(n)))?(o=t?(t=!1,e&&E.isArray(e)?e:[]):e&&E.isPlainObject(e)?e:{},a[r]=E.extend(l,o,n)):void 0!==n&&(a[r]=n));return a},E.extend({expando:"jQuery"+(o+Math.random()).replace(/\D/g,""),isReady:!0,error:function(e){throw new Error(e)},noop:function(){},isFunction:function(e){return"function"===E.type(e)},isArray:Array.isArray||function(e){return"array"===E.type(e)},isWindow:function(e){return null!=e&&e==e.window},isNumeric:function(e){var t=e&&e.toString();return!E.isArray(e)&&0<=t-parseFloat(t)+1},isEmptyObject:function(e){var t;for(t in e)return!1;return!0},isPlainObject:function(e){var t;if(!e||"object"!==E.type(e)||e.nodeType||E.isWindow(e))return!1;try{if(e.constructor&&!g.call(e,"constructor")&&!g.call(e.constructor.prototype,"isPrototypeOf"))return!1}catch(e){return!1}if(!v.ownFirst)for(t in e)return g.call(e,t);for(t in e);return void 0===t||g.call(e,t)},type:function(e){return null==e?e+"":"object"==typeof e||"function"==typeof e?n[r.call(e)]||"object":typeof e},globalEval:function(e){e&&E.trim(e)&&(C.execScript||function(e){C.eval.call(C,e)})(e)},camelCase:function(e){return e.replace(u,"ms-").replace(l,t)},nodeName:function(e,t){return e.nodeName&&e.nodeName.toLowerCase()===t.toLowerCase()},each:function(e,t){var n,r=0;if(d(e))for(n=e.length;r<n&&!1!==t.call(e[r],r,e[r]);r++);else for(r in e)if(!1===t.call(e[r],r,e[r]))break;return e},trim:function(e){return null==e?"":(e+"").replace(a,"")},makeArray:function(e,t){var n=t||[];return null!=e&&(d(Object(e))?E.merge(n,"string"==typeof e?[e]:e):s.call(n,e)),n},inArray:function(e,t,n){var r;if(t){if(i)return i.call(t,e,n);for(r=t.length,n=n?n<0?Math.max(0,r+n):n:0;n<r;n++)if(n in t&&t[n]===e)return n}return-1},merge:function(e,t){for(var n=+t.length,r=0,i=e.length;r<n;)e[i++]=t[r++];if(n!=n)for(;void 0!==t[r];)e[i++]=t[r++];return e.length=i,e},grep:function(e,t,n){for(var r=[],i=0,o=e.length,a=!n;i<o;i++)!t(e[i],i)!=a&&r.push(e[i]);return r},map:function(e,t,n){var r,i,o=0,a=[];if(d(e))for(r=e.length;o<r;o++)null!=(i=t(e[o],o,n))&&a.push(i);else for(o in e)null!=(i=t(e[o],o,n))&&a.push(i);return m.apply([],a)},guid:1,proxy:function(e,t){var n,r,i;if("string"==typeof t&&(i=e[t],t=e,e=i),E.isFunction(e))return n=c.call(arguments,2),(r=function(){return e.apply(t||this,n.concat(c.call(arguments)))}).guid=e.guid=e.guid||E.guid++,r},now:function(){return+new Date},support:v}),"function"==typeof Symbol&&(E.fn[Symbol.iterator]=f[Symbol.iterator]),E.each("Boolean Number String Function Array Date RegExp Object Error Symbol".split(" "),function(e,t){n["[object "+t+"]"]=t.toLowerCase()});var p=function(n){function f(e,t,n){var r="0x"+t-65536;return r!=r||n?t:r<0?String.fromCharCode(65536+r):String.fromCharCode(r>>10|55296,1023&r|56320)}function i(){T()}var e,h,b,o,a,m,d,g,w,u,l,T,C,s,E,v,c,p,y,N="sizzle"+ +new Date,x=n.document,k=0,r=0,S=ie(),A=ie(),D=ie(),L=function(e,t){return e===t&&(l=!0),0},j={}.hasOwnProperty,t=[],H=t.pop,q=t.push,_=t.push,M=t.slice,F=function(e,t){for(var n=0,r=e.length;n<r;n++)if(e[n]===t)return n;return-1},O="checked|selected|async|autofocus|autoplay|controls|defer|disabled|hidden|ismap|loop|multiple|open|readonly|required|scoped",R="[\\x20\\t\\r\\n\\f]",P="(?:\\\\.|[\\w-]|[^\\x00-\\xa0])+",B="\\["+R+"*("+P+")(?:"+R+"*([*^$|!~]?=)"+R+"*(?:'((?:\\\\.|[^\\\\'])*)'|\"((?:\\\\.|[^\\\\\"])*)\"|("+P+"))|)"+R+"*\\]",W=":("+P+")(?:\\((('((?:\\\\.|[^\\\\'])*)'|\"((?:\\\\.|[^\\\\\"])*)\")|((?:\\\\.|[^\\\\()[\\]]|"+B+")*)|.*)\\)|)",I=new RegExp(R+"+","g"),$=new RegExp("^"+R+"+|((?:^|[^\\\\])(?:\\\\.)*)"+R+"+$","g"),z=new RegExp("^"+R+"*,"+R+"*"),X=new RegExp("^"+R+"*([>+~]|"+R+")"+R+"*"),U=new RegExp("="+R+"*([^\\]'\"]*?)"+R+"*\\]","g"),V=new RegExp(W),Y=new RegExp("^"+P+"$"),J={ID:new RegExp("^#("+P+")"),CLASS:new RegExp("^\\.("+P+")"),TAG:new RegExp("^("+P+"|[*])"),ATTR:new RegExp("^"+B),PSEUDO:new RegExp("^"+W),CHILD:new RegExp("^:(only|first|last|nth|nth-last)-(child|of-type)(?:\\("+R+"*(even|odd|(([+-]|)(\\d*)n|)"+R+"*(?:([+-]|)"+R+"*(\\d+)|))"+R+"*\\)|)","i"),bool:new RegExp("^(?:"+O+")$","i"),needsContext:new RegExp("^"+R+"*[>+~]|:(even|odd|eq|gt|lt|nth|first|last)(?:\\("+R+"*((?:-\\d)?\\d*)"+R+"*\\)|)(?=[^-]|$)","i")},G=/^(?:input|select|textarea|button)$/i,Q=/^h\d$/i,K=/^[^{]+\{\s*\[native \w/,Z=/^(?:#([\w-]+)|(\w+)|\.([\w-]+))$/,ee=/[+~]/,te=/'|\\/g,ne=new RegExp("\\\\([\\da-f]{1,6}"+R+"?|("+R+")|.)","ig");try{_.apply(t=M.call(x.childNodes),x.childNodes),t[x.childNodes.length].nodeType}catch(e){_={apply:t.length?function(e,t){q.apply(e,M.call(t))}:function(e,t){for(var n=e.length,r=0;e[n++]=t[r++];);e.length=n-1}}}function re(e,t,n,r){var i,o,a,s,u,l,c,f,d=t&&t.ownerDocument,p=t?t.nodeType:9;if(n=n||[],"string"!=typeof e||!e||1!==p&&9!==p&&11!==p)return n;if(!r&&((t?t.ownerDocument||t:x)!==C&&T(t),t=t||C,E)){if(11!==p&&(l=Z.exec(e)))if(i=l[1]){if(9===p){if(!(a=t.getElementById(i)))return n;if(a.id===i)return n.push(a),n}else if(d&&(a=d.getElementById(i))&&y(t,a)&&a.id===i)return n.push(a),n}else{if(l[2])return _.apply(n,t.getElementsByTagName(e)),n;if((i=l[3])&&h.getElementsByClassName&&t.getElementsByClassName)return _.apply(n,t.getElementsByClassName(i)),n}if(h.qsa&&!D[e+" "]&&(!v||!v.test(e))){if(1!==p)d=t,f=e;else if("object"!==t.nodeName.toLowerCase()){for((s=t.getAttribute("id"))?s=s.replace(te,"\\$&"):t.setAttribute("id",s=N),o=(c=m(e)).length,u=Y.test(s)?"#"+s:"[id='"+s+"']";o--;)c[o]=u+" "+he(c[o]);f=c.join(","),d=ee.test(e)&&de(t.parentNode)||t}if(f)try{return _.apply(n,d.querySelectorAll(f)),n}catch(e){}finally{s===N&&t.removeAttribute("id")}}}return g(e.replace($,"$1"),t,n,r)}function ie(){var r=[];return function e(t,n){return r.push(t+" ")>b.cacheLength&&delete e[r.shift()],e[t+" "]=n}}function oe(e){return e[N]=!0,e}function ae(e){var t=C.createElement("div");try{return!!e(t)}catch(e){return!1}finally{t.parentNode&&t.parentNode.removeChild(t),t=null}}function se(e,t){for(var n=e.split("|"),r=n.length;r--;)b.attrHandle[n[r]]=t}function ue(e,t){var n=t&&e,r=n&&1===e.nodeType&&1===t.nodeType&&(~t.sourceIndex||1<<31)-(~e.sourceIndex||1<<31);if(r)return r;if(n)for(;n=n.nextSibling;)if(n===t)return-1;return e?1:-1}function le(t){return function(e){return"input"===e.nodeName.toLowerCase()&&e.type===t}}function ce(n){return function(e){var t=e.nodeName.toLowerCase();return("input"===t||"button"===t)&&e.type===n}}function fe(a){return oe(function(o){return o=+o,oe(function(e,t){for(var n,r=a([],e.length,o),i=r.length;i--;)e[n=r[i]]&&(e[n]=!(t[n]=e[n]))})})}function de(e){return e&&void 0!==e.getElementsByTagName&&e}for(e in h=re.support={},a=re.isXML=function(e){var t=e&&(e.ownerDocument||e).documentElement;return!!t&&"HTML"!==t.nodeName},T=re.setDocument=function(e){var t,n,r=e?e.ownerDocument||e:x;return r!==C&&9===r.nodeType&&r.documentElement&&(s=(C=r).documentElement,E=!a(C),(n=C.defaultView)&&n.top!==n&&(n.addEventListener?n.addEventListener("unload",i,!1):n.attachEvent&&n.attachEvent("onunload",i)),h.attributes=ae(function(e){return e.className="i",!e.getAttribute("className")}),h.getElementsByTagName=ae(function(e){return e.appendChild(C.createComment("")),!e.getElementsByTagName("*").length}),h.getElementsByClassName=K.test(C.getElementsByClassName),h.getById=ae(function(e){return s.appendChild(e).id=N,!C.getElementsByName||!C.getElementsByName(N).length}),h.getById?(b.find.ID=function(e,t){if(void 0!==t.getElementById&&E){var n=t.getElementById(e);return n?[n]:[]}},b.filter.ID=function(e){var t=e.replace(ne,f);return function(e){return e.getAttribute("id")===t}}):(delete b.find.ID,b.filter.ID=function(e){var n=e.replace(ne,f);return function(e){var t=void 0!==e.getAttributeNode&&e.getAttributeNode("id");return t&&t.value===n}}),b.find.TAG=h.getElementsByTagName?function(e,t){return void 0!==t.getElementsByTagName?t.getElementsByTagName(e):h.qsa?t.querySelectorAll(e):void 0}:function(e,t){var n,r=[],i=0,o=t.getElementsByTagName(e);if("*"!==e)return o;for(;n=o[i++];)1===n.nodeType&&r.push(n);return r},b.find.CLASS=h.getElementsByClassName&&function(e,t){if(void 0!==t.getElementsByClassName&&E)return t.getElementsByClassName(e)},c=[],v=[],(h.qsa=K.test(C.querySelectorAll))&&(ae(function(e){s.appendChild(e).innerHTML="<a id='"+N+"'></a><select id='"+N+"-\r\\' msallowcapture=''><option selected=''></option></select>",e.querySelectorAll("[msallowcapture^='']").length&&v.push("[*^$]="+R+"*(?:''|\"\")"),e.querySelectorAll("[selected]").length||v.push("\\["+R+"*(?:value|"+O+")"),e.querySelectorAll("[id~="+N+"-]").length||v.push("~="),e.querySelectorAll(":checked").length||v.push(":checked"),e.querySelectorAll("a#"+N+"+*").length||v.push(".#.+[+~]")}),ae(function(e){var t=C.createElement("input");t.setAttribute("type","hidden"),e.appendChild(t).setAttribute("name","D"),e.querySelectorAll("[name=d]").length&&v.push("name"+R+"*[*^$|!~]?="),e.querySelectorAll(":enabled").length||v.push(":enabled",":disabled"),e.querySelectorAll("*,:x"),v.push(",.*:")})),(h.matchesSelector=K.test(p=s.matches||s.webkitMatchesSelector||s.mozMatchesSelector||s.oMatchesSelector||s.msMatchesSelector))&&ae(function(e){h.disconnectedMatch=p.call(e,"div"),p.call(e,"[s!='']:x"),c.push("!=",W)}),v=v.length&&new RegExp(v.join("|")),c=c.length&&new RegExp(c.join("|")),t=K.test(s.compareDocumentPosition),y=t||K.test(s.contains)?function(e,t){var n=9===e.nodeType?e.documentElement:e,r=t&&t.parentNode;return e===r||!(!r||1!==r.nodeType||!(n.contains?n.contains(r):e.compareDocumentPosition&&16&e.compareDocumentPosition(r)))}:function(e,t){if(t)for(;t=t.parentNode;)if(t===e)return!0;return!1},L=t?function(e,t){if(e===t)return l=!0,0;var n=!e.compareDocumentPosition-!t.compareDocumentPosition;return n||(1&(n=(e.ownerDocument||e)===(t.ownerDocument||t)?e.compareDocumentPosition(t):1)||!h.sortDetached&&t.compareDocumentPosition(e)===n?e===C||e.ownerDocument===x&&y(x,e)?-1:t===C||t.ownerDocument===x&&y(x,t)?1:u?F(u,e)-F(u,t):0:4&n?-1:1)}:function(e,t){if(e===t)return l=!0,0;var n,r=0,i=e.parentNode,o=t.parentNode,a=[e],s=[t];if(!i||!o)return e===C?-1:t===C?1:i?-1:o?1:u?F(u,e)-F(u,t):0;if(i===o)return ue(e,t);for(n=e;n=n.parentNode;)a.unshift(n);for(n=t;n=n.parentNode;)s.unshift(n);for(;a[r]===s[r];)r++;return r?ue(a[r],s[r]):a[r]===x?-1:s[r]===x?1:0}),C},re.matches=function(e,t){return re(e,null,null,t)},re.matchesSelector=function(e,t){if((e.ownerDocument||e)!==C&&T(e),t=t.replace(U,"='$1']"),h.matchesSelector&&E&&!D[t+" "]&&(!c||!c.test(t))&&(!v||!v.test(t)))try{var n=p.call(e,t);if(n||h.disconnectedMatch||e.document&&11!==e.document.nodeType)return n}catch(e){}return 0<re(t,C,null,[e]).length},re.contains=function(e,t){return(e.ownerDocument||e)!==C&&T(e),y(e,t)},re.attr=function(e,t){(e.ownerDocument||e)!==C&&T(e);var n=b.attrHandle[t.toLowerCase()],r=n&&j.call(b.attrHandle,t.toLowerCase())?n(e,t,!E):void 0;return void 0!==r?r:h.attributes||!E?e.getAttribute(t):(r=e.getAttributeNode(t))&&r.specified?r.value:null},re.error=function(e){throw new Error("Syntax error, unrecognized expression: "+e)},re.uniqueSort=function(e){var t,n=[],r=0,i=0;if(l=!h.detectDuplicates,u=!h.sortStable&&e.slice(0),e.sort(L),l){for(;t=e[i++];)t===e[i]&&(r=n.push(i));for(;r--;)e.splice(n[r],1)}return u=null,e},o=re.getText=function(e){var t,n="",r=0,i=e.nodeType;if(i){if(1===i||9===i||11===i){if("string"==typeof e.textContent)return e.textContent;for(e=e.firstChild;e;e=e.nextSibling)n+=o(e)}else if(3===i||4===i)return e.nodeValue}else for(;t=e[r++];)n+=o(t);return n},(b=re.selectors={cacheLength:50,createPseudo:oe,match:J,attrHandle:{},find:{},relative:{">":{dir:"parentNode",first:!0}," ":{dir:"parentNode"},"+":{dir:"previousSibling",first:!0},"~":{dir:"previousSibling"}},preFilter:{ATTR:function(e){return e[1]=e[1].replace(ne,f),e[3]=(e[3]||e[4]||e[5]||"").replace(ne,f),"~="===e[2]&&(e[3]=" "+e[3]+" "),e.slice(0,4)},CHILD:function(e){return e[1]=e[1].toLowerCase(),"nth"===e[1].slice(0,3)?(e[3]||re.error(e[0]),e[4]=+(e[4]?e[5]+(e[6]||1):2*("even"===e[3]||"odd"===e[3])),e[5]=+(e[7]+e[8]||"odd"===e[3])):e[3]&&re.error(e[0]),e},PSEUDO:function(e){var t,n=!e[6]&&e[2];return J.CHILD.test(e[0])?null:(e[3]?e[2]=e[4]||e[5]||"":n&&V.test(n)&&(t=m(n,!0))&&(t=n.indexOf(")",n.length-t)-n.length)&&(e[0]=e[0].slice(0,t),e[2]=n.slice(0,t)),e.slice(0,3))}},filter:{TAG:function(e){var t=e.replace(ne,f).toLowerCase();return"*"===e?function(){return!0}:function(e){return e.nodeName&&e.nodeName.toLowerCase()===t}},CLASS:function(e){var t=S[e+" "];return t||(t=new RegExp("(^|"+R+")"+e+"("+R+"|$)"))&&S(e,function(e){return t.test("string"==typeof e.className&&e.className||void 0!==e.getAttribute&&e.getAttribute("class")||"")})},ATTR:function(n,r,i){return function(e){var t=re.attr(e,n);return null==t?"!="===r:!r||(t+="","="===r?t===i:"!="===r?t!==i:"^="===r?i&&0===t.indexOf(i):"*="===r?i&&-1<t.indexOf(i):"$="===r?i&&t.slice(-i.length)===i:"~="===r?-1<(" "+t.replace(I," ")+" ").indexOf(i):"|="===r&&(t===i||t.slice(0,i.length+1)===i+"-"))}},CHILD:function(h,e,t,m,g){var v="nth"!==h.slice(0,3),y="last"!==h.slice(-4),x="of-type"===e;return 1===m&&0===g?function(e){return!!e.parentNode}:function(e,t,n){var r,i,o,a,s,u,l=v!=y?"nextSibling":"previousSibling",c=e.parentNode,f=x&&e.nodeName.toLowerCase(),d=!n&&!x,p=!1;if(c){if(v){for(;l;){for(a=e;a=a[l];)if(x?a.nodeName.toLowerCase()===f:1===a.nodeType)return!1;u=l="only"===h&&!u&&"nextSibling"}return!0}if(u=[y?c.firstChild:c.lastChild],y&&d){for(p=(s=(r=(i=(o=(a=c)[N]||(a[N]={}))[a.uniqueID]||(o[a.uniqueID]={}))[h]||[])[0]===k&&r[1])&&r[2],a=s&&c.childNodes[s];a=++s&&a&&a[l]||(p=s=0)||u.pop();)if(1===a.nodeType&&++p&&a===e){i[h]=[k,s,p];break}}else if(d&&(p=s=(r=(i=(o=(a=e)[N]||(a[N]={}))[a.uniqueID]||(o[a.uniqueID]={}))[h]||[])[0]===k&&r[1]),!1===p)for(;(a=++s&&a&&a[l]||(p=s=0)||u.pop())&&((x?a.nodeName.toLowerCase()!==f:1!==a.nodeType)||!++p||(d&&((i=(o=a[N]||(a[N]={}))[a.uniqueID]||(o[a.uniqueID]={}))[h]=[k,p]),a!==e)););return(p-=g)===m||p%m==0&&0<=p/m}}},PSEUDO:function(e,o){var t,a=b.pseudos[e]||b.setFilters[e.toLowerCase()]||re.error("unsupported pseudo: "+e);return a[N]?a(o):1<a.length?(t=[e,e,"",o],b.setFilters.hasOwnProperty(e.toLowerCase())?oe(function(e,t){for(var n,r=a(e,o),i=r.length;i--;)e[n=F(e,r[i])]=!(t[n]=r[i])}):function(e){return a(e,0,t)}):a}},pseudos:{not:oe(function(e){var r=[],i=[],s=d(e.replace($,"$1"));return s[N]?oe(function(e,t,n,r){for(var i,o=s(e,null,r,[]),a=e.length;a--;)(i=o[a])&&(e[a]=!(t[a]=i))}):function(e,t,n){return r[0]=e,s(r,null,n,i),r[0]=null,!i.pop()}}),has:oe(function(t){return function(e){return 0<re(t,e).length}}),contains:oe(function(t){return t=t.replace(ne,f),function(e){return-1<(e.textContent||e.innerText||o(e)).indexOf(t)}}),lang:oe(function(n){return Y.test(n||"")||re.error("unsupported lang: "+n),n=n.replace(ne,f).toLowerCase(),function(e){var t;do{if(t=E?e.lang:e.getAttribute("xml:lang")||e.getAttribute("lang"))return(t=t.toLowerCase())===n||0===t.indexOf(n+"-")}while((e=e.parentNode)&&1===e.nodeType);return!1}}),target:function(e){var t=n.location&&n.location.hash;return t&&t.slice(1)===e.id},root:function(e){return e===s},focus:function(e){return e===C.activeElement&&(!C.hasFocus||C.hasFocus())&&!!(e.type||e.href||~e.tabIndex)},enabled:function(e){return!1===e.disabled},disabled:function(e){return!0===e.disabled},checked:function(e){var t=e.nodeName.toLowerCase();return"input"===t&&!!e.checked||"option"===t&&!!e.selected},selected:function(e){return e.parentNode&&e.parentNode.selectedIndex,!0===e.selected},empty:function(e){for(e=e.firstChild;e;e=e.nextSibling)if(e.nodeType<6)return!1;return!0},parent:function(e){return!b.pseudos.empty(e)},header:function(e){return Q.test(e.nodeName)},input:function(e){return G.test(e.nodeName)},button:function(e){var t=e.nodeName.toLowerCase();return"input"===t&&"button"===e.type||"button"===t},text:function(e){var t;return"input"===e.nodeName.toLowerCase()&&"text"===e.type&&(null==(t=e.getAttribute("type"))||"text"===t.toLowerCase())},first:fe(function(){return[0]}),last:fe(function(e,t){return[t-1]}),eq:fe(function(e,t,n){return[n<0?n+t:n]}),even:fe(function(e,t){for(var n=0;n<t;n+=2)e.push(n);return e}),odd:fe(function(e,t){for(var n=1;n<t;n+=2)e.push(n);return e}),lt:fe(function(e,t,n){for(var r=n<0?n+t:n;0<=--r;)e.push(r);return e}),gt:fe(function(e,t,n){for(var r=n<0?n+t:n;++r<t;)e.push(r);return e})}}).pseudos.nth=b.pseudos.eq,{radio:!0,checkbox:!0,file:!0,password:!0,image:!0})b.pseudos[e]=le(e);for(e in{submit:!0,reset:!0})b.pseudos[e]=ce(e);function pe(){}function he(e){for(var t=0,n=e.length,r="";t<n;t++)r+=e[t].value;return r}function me(s,e,t){var u=e.dir,l=t&&"parentNode"===u,c=r++;return e.first?function(e,t,n){for(;e=e[u];)if(1===e.nodeType||l)return s(e,t,n)}:function(e,t,n){var r,i,o,a=[k,c];if(n){for(;e=e[u];)if((1===e.nodeType||l)&&s(e,t,n))return!0}else for(;e=e[u];)if(1===e.nodeType||l){if((r=(i=(o=e[N]||(e[N]={}))[e.uniqueID]||(o[e.uniqueID]={}))[u])&&r[0]===k&&r[1]===c)return a[2]=r[2];if((i[u]=a)[2]=s(e,t,n))return!0}}}function ge(i){return 1<i.length?function(e,t,n){for(var r=i.length;r--;)if(!i[r](e,t,n))return!1;return!0}:i[0]}function ve(e,t,n,r,i){for(var o,a=[],s=0,u=e.length,l=null!=t;s<u;s++)(o=e[s])&&(n&&!n(o,r,i)||(a.push(o),l&&t.push(s)));return a}function ye(p,h,m,g,v,e){return g&&!g[N]&&(g=ye(g)),v&&!v[N]&&(v=ye(v,e)),oe(function(e,t,n,r){var i,o,a,s=[],u=[],l=t.length,c=e||function(e,t,n){for(var r=0,i=t.length;r<i;r++)re(e,t[r],n);return n}(h||"*",n.nodeType?[n]:n,[]),f=!p||!e&&h?c:ve(c,s,p,n,r),d=m?v||(e?p:l||g)?[]:t:f;if(m&&m(f,d,n,r),g)for(i=ve(d,u),g(i,[],n,r),o=i.length;o--;)(a=i[o])&&(d[u[o]]=!(f[u[o]]=a));if(e){if(v||p){if(v){for(i=[],o=d.length;o--;)(a=d[o])&&i.push(f[o]=a);v(null,d=[],i,r)}for(o=d.length;o--;)(a=d[o])&&-1<(i=v?F(e,a):s[o])&&(e[i]=!(t[i]=a))}}else d=ve(d===t?d.splice(l,d.length):d),v?v(null,t,d,r):_.apply(t,d)})}function xe(e){for(var i,t,n,r=e.length,o=b.relative[e[0].type],a=o||b.relative[" "],s=o?1:0,u=me(function(e){return e===i},a,!0),l=me(function(e){return-1<F(i,e)},a,!0),c=[function(e,t,n){var r=!o&&(n||t!==w)||((i=t).nodeType?u:l)(e,t,n);return i=null,r}];s<r;s++)if(t=b.relative[e[s].type])c=[me(ge(c),t)];else{if((t=b.filter[e[s].type].apply(null,e[s].matches))[N]){for(n=++s;n<r&&!b.relative[e[n].type];n++);return ye(1<s&&ge(c),1<s&&he(e.slice(0,s-1).concat({value:" "===e[s-2].type?"*":""})).replace($,"$1"),t,s<n&&xe(e.slice(s,n)),n<r&&xe(e=e.slice(n)),n<r&&he(e))}c.push(t)}return ge(c)}function be(g,v){function e(e,t,n,r,i){var o,a,s,u=0,l="0",c=e&&[],f=[],d=w,p=e||x&&b.find.TAG("*",i),h=k+=null==d?1:Math.random()||.1,m=p.length;for(i&&(w=t===C||t||i);l!==m&&null!=(o=p[l]);l++){if(x&&o){for(a=0,t||o.ownerDocument===C||(T(o),n=!E);s=g[a++];)if(s(o,t||C,n)){r.push(o);break}i&&(k=h)}y&&((o=!s&&o)&&u--,e&&c.push(o))}if(u+=l,y&&l!==u){for(a=0;s=v[a++];)s(c,f,t,n);if(e){if(0<u)for(;l--;)c[l]||f[l]||(f[l]=H.call(r));f=ve(f)}_.apply(r,f),i&&!e&&0<f.length&&1<u+v.length&&re.uniqueSort(r)}return i&&(k=h,w=d),c}var y=0<v.length,x=0<g.length;return y?oe(e):e}return pe.prototype=b.filters=b.pseudos,b.setFilters=new pe,m=re.tokenize=function(e,t){var n,r,i,o,a,s,u,l=A[e+" "];if(l)return t?0:l.slice(0);for(a=e,s=[],u=b.preFilter;a;){for(o in n&&!(r=z.exec(a))||(r&&(a=a.slice(r[0].length)||a),s.push(i=[])),n=!1,(r=X.exec(a))&&(n=r.shift(),i.push({value:n,type:r[0].replace($," ")}),a=a.slice(n.length)),b.filter)!(r=J[o].exec(a))||u[o]&&!(r=u[o](r))||(n=r.shift(),i.push({value:n,type:o,matches:r}),a=a.slice(n.length));if(!n)break}return t?a.length:a?re.error(e):A(e,s).slice(0)},d=re.compile=function(e,t){var n,r=[],i=[],o=D[e+" "];if(!o){for(n=(t=t||m(e)).length;n--;)(o=xe(t[n]))[N]?r.push(o):i.push(o);(o=D(e,be(i,r))).selector=e}return o},g=re.select=function(e,t,n,r){var i,o,a,s,u,l="function"==typeof e&&e,c=!r&&m(e=l.selector||e);if(n=n||[],1===c.length){if(2<(o=c[0]=c[0].slice(0)).length&&"ID"===(a=o[0]).type&&h.getById&&9===t.nodeType&&E&&b.relative[o[1].type]){if(!(t=(b.find.ID(a.matches[0].replace(ne,f),t)||[])[0]))return n;l&&(t=t.parentNode),e=e.slice(o.shift().value.length)}for(i=J.needsContext.test(e)?0:o.length;i--&&(a=o[i],!b.relative[s=a.type]);)if((u=b.find[s])&&(r=u(a.matches[0].replace(ne,f),ee.test(o[0].type)&&de(t.parentNode)||t))){if(o.splice(i,1),!(e=r.length&&he(o)))return _.apply(n,r),n;break}}return(l||d(e,c))(r,t,!E,n,!t||ee.test(e)&&de(t.parentNode)||t),n},h.sortStable=N.split("").sort(L).join("")===N,h.detectDuplicates=!!l,T(),h.sortDetached=ae(function(e){return 1&e.compareDocumentPosition(C.createElement("div"))}),ae(function(e){return e.innerHTML="<a href='#'></a>","#"===e.firstChild.getAttribute("href")})||se("type|href|height|width",function(e,t,n){if(!n)return e.getAttribute(t,"type"===t.toLowerCase()?1:2)}),h.attributes&&ae(function(e){return e.innerHTML="<input/>",e.firstChild.setAttribute("value",""),""===e.firstChild.getAttribute("value")})||se("value",function(e,t,n){if(!n&&"input"===e.nodeName.toLowerCase())return e.defaultValue}),ae(function(e){return null==e.getAttribute("disabled")})||se(O,function(e,t,n){var r;if(!n)return!0===e[t]?t.toLowerCase():(r=e.getAttributeNode(t))&&r.specified?r.value:null}),re}(C);E.find=p,E.expr=p.selectors,E.expr[":"]=E.expr.pseudos,E.uniqueSort=E.unique=p.uniqueSort,E.text=p.getText,E.isXMLDoc=p.isXML,E.contains=p.contains;function y(e,t,n){for(var r=[],i=void 0!==n;(e=e[t])&&9!==e.nodeType;)if(1===e.nodeType){if(i&&E(e).is(n))break;r.push(e)}return r}function x(e,t){for(var n=[];e;e=e.nextSibling)1===e.nodeType&&e!==t&&n.push(e);return n}var b=E.expr.match.needsContext,w=/^<([\w-]+)\s*\/?>(?:<\/\1>|)$/,T=/^.[^:#\[\.,]*$/;function N(e,n,r){if(E.isFunction(n))return E.grep(e,function(e,t){return!!n.call(e,t,e)!==r});if(n.nodeType)return E.grep(e,function(e){return e===n!==r});if("string"==typeof n){if(T.test(n))return E.filter(n,e,r);n=E.filter(n,e)}return E.grep(e,function(e){return-1<E.inArray(e,n)!==r})}E.filter=function(e,t,n){var r=t[0];return n&&(e=":not("+e+")"),1===t.length&&1===r.nodeType?E.find.matchesSelector(r,e)?[r]:[]:E.find.matches(e,E.grep(t,function(e){return 1===e.nodeType}))},E.fn.extend({find:function(e){var t,n=[],r=this,i=r.length;if("string"!=typeof e)return this.pushStack(E(e).filter(function(){for(t=0;t<i;t++)if(E.contains(r[t],this))return!0}));for(t=0;t<i;t++)E.find(e,r[t],n);return(n=this.pushStack(1<i?E.unique(n):n)).selector=this.selector?this.selector+" "+e:e,n},filter:function(e){return this.pushStack(N(this,e||[],!1))},not:function(e){return this.pushStack(N(this,e||[],!0))},is:function(e){return!!N(this,"string"==typeof e&&b.test(e)?E(e):e||[],!1).length}});var k,S=/^(?:\s*(<[\w\W]+>)[^>]*|#([\w-]*))$/;(E.fn.init=function(e,t,n){var r,i;if(!e)return this;if(n=n||k,"string"!=typeof e)return e.nodeType?(this.context=this[0]=e,this.length=1,this):E.isFunction(e)?void 0!==n.ready?n.ready(e):e(E):(void 0!==e.selector&&(this.selector=e.selector,this.context=e.context),E.makeArray(e,this));if(!(r="<"===e.charAt(0)&&">"===e.charAt(e.length-1)&&3<=e.length?[null,e,null]:S.exec(e))||!r[1]&&t)return!t||t.jquery?(t||n).find(e):this.constructor(t).find(e);if(r[1]){if(t=t instanceof E?t[0]:t,E.merge(this,E.parseHTML(r[1],t&&t.nodeType?t.ownerDocument||t:h,!0)),w.test(r[1])&&E.isPlainObject(t))for(r in t)E.isFunction(this[r])?this[r](t[r]):this.attr(r,t[r]);return this}if((i=h.getElementById(r[2]))&&i.parentNode){if(i.id!==r[2])return k.find(e);this.length=1,this[0]=i}return this.context=h,this.selector=e,this}).prototype=E.fn,k=E(h);var A=/^(?:parents|prev(?:Until|All))/,D={children:!0,contents:!0,next:!0,prev:!0};function L(e,t){for(;(e=e[t])&&1!==e.nodeType;);return e}E.fn.extend({has:function(e){var t,n=E(e,this),r=n.length;return this.filter(function(){for(t=0;t<r;t++)if(E.contains(this,n[t]))return!0})},closest:function(e,t){for(var n,r=0,i=this.length,o=[],a=b.test(e)||"string"!=typeof e?E(e,t||this.context):0;r<i;r++)for(n=this[r];n&&n!==t;n=n.parentNode)if(n.nodeType<11&&(a?-1<a.index(n):1===n.nodeType&&E.find.matchesSelector(n,e))){o.push(n);break}return this.pushStack(1<o.length?E.uniqueSort(o):o)},index:function(e){return e?"string"==typeof e?E.inArray(this[0],E(e)):E.inArray(e.jquery?e[0]:e,this):this[0]&&this[0].parentNode?this.first().prevAll().length:-1},add:function(e,t){return this.pushStack(E.uniqueSort(E.merge(this.get(),E(e,t))))},addBack:function(e){return this.add(null==e?this.prevObject:this.prevObject.filter(e))}}),E.each({parent:function(e){var t=e.parentNode;return t&&11!==t.nodeType?t:null},parents:function(e){return y(e,"parentNode")},parentsUntil:function(e,t,n){return y(e,"parentNode",n)},next:function(e){return L(e,"nextSibling")},prev:function(e){return L(e,"previousSibling")},nextAll:function(e){return y(e,"nextSibling")},prevAll:function(e){return y(e,"previousSibling")},nextUntil:function(e,t,n){return y(e,"nextSibling",n)},prevUntil:function(e,t,n){return y(e,"previousSibling",n)},siblings:function(e){return x((e.parentNode||{}).firstChild,e)},children:function(e){return x(e.firstChild)},contents:function(e){return E.nodeName(e,"iframe")?e.contentDocument||e.contentWindow.document:E.merge([],e.childNodes)}},function(r,i){E.fn[r]=function(e,t){var n=E.map(this,i,e);return"Until"!==r.slice(-5)&&(t=e),t&&"string"==typeof t&&(n=E.filter(t,n)),1<this.length&&(D[r]||(n=E.uniqueSort(n)),A.test(r)&&(n=n.reverse())),this.pushStack(n)}});var j,H,q=/\S+/g;function _(){h.addEventListener?(h.removeEventListener("DOMContentLoaded",M),C.removeEventListener("load",M)):(h.detachEvent("onreadystatechange",M),C.detachEvent("onload",M))}function M(){!h.addEventListener&&"load"!==C.event.type&&"complete"!==h.readyState||(_(),E.ready())}for(H in E.Callbacks=function(r){var e,n;r="string"==typeof r?(e=r,n={},E.each(e.match(q)||[],function(e,t){n[t]=!0}),n):E.extend({},r);function i(){for(s=r.once,a=o=!0;l.length;c=-1)for(t=l.shift();++c<u.length;)!1===u[c].apply(t[0],t[1])&&r.stopOnFalse&&(c=u.length,t=!1);r.memory||(t=!1),o=!1,s&&(u=t?[]:"")}var o,t,a,s,u=[],l=[],c=-1,f={add:function(){return u&&(t&&!o&&(c=u.length-1,l.push(t)),function n(e){E.each(e,function(e,t){E.isFunction(t)?r.unique&&f.has(t)||u.push(t):t&&t.length&&"string"!==E.type(t)&&n(t)})}(arguments),t&&!o&&i()),this},remove:function(){return E.each(arguments,function(e,t){for(var n;-1<(n=E.inArray(t,u,n));)u.splice(n,1),n<=c&&c--}),this},has:function(e){return e?-1<E.inArray(e,u):0<u.length},empty:function(){return u=u&&[],this},disable:function(){return s=l=[],u=t="",this},disabled:function(){return!u},lock:function(){return s=!0,t||f.disable(),this},locked:function(){return!!s},fireWith:function(e,t){return s||(t=[e,(t=t||[]).slice?t.slice():t],l.push(t),o||i()),this},fire:function(){return f.fireWith(this,arguments),this},fired:function(){return!!a}};return f},E.extend({Deferred:function(e){var o=[["resolve","done",E.Callbacks("once memory"),"resolved"],["reject","fail",E.Callbacks("once memory"),"rejected"],["notify","progress",E.Callbacks("memory")]],i="pending",a={state:function(){return i},always:function(){return s.done(arguments).fail(arguments),this},then:function(){var i=arguments;return E.Deferred(function(r){E.each(o,function(e,t){var n=E.isFunction(i[e])&&i[e];s[t[1]](function(){var e=n&&n.apply(this,arguments);e&&E.isFunction(e.promise)?e.promise().progress(r.notify).done(r.resolve).fail(r.reject):r[t[0]+"With"](this===a?r.promise():this,n?[e]:arguments)})}),i=null}).promise()},promise:function(e){return null!=e?E.extend(e,a):a}},s={};return a.pipe=a.then,E.each(o,function(e,t){var n=t[2],r=t[3];a[t[1]]=n.add,r&&n.add(function(){i=r},o[1^e][2].disable,o[2][2].lock),s[t[0]]=function(){return s[t[0]+"With"](this===s?a:this,arguments),this},s[t[0]+"With"]=n.fireWith}),a.promise(s),e&&e.call(s,s),s},when:function(e){function t(t,n,r){return function(e){n[t]=this,r[t]=1<arguments.length?c.call(arguments):e,r===i?l.notifyWith(n,r):--u||l.resolveWith(n,r)}}var i,n,r,o=0,a=c.call(arguments),s=a.length,u=1!==s||e&&E.isFunction(e.promise)?s:0,l=1===u?e:E.Deferred();if(1<s)for(i=new Array(s),n=new Array(s),r=new Array(s);o<s;o++)a[o]&&E.isFunction(a[o].promise)?a[o].promise().progress(t(o,n,i)).done(t(o,r,a)).fail(l.reject):--u;return u||l.resolveWith(r,a),l.promise()}}),E.fn.ready=function(e){return E.ready.promise().done(e),this},E.extend({isReady:!1,readyWait:1,holdReady:function(e){e?E.readyWait++:E.ready(!0)},ready:function(e){(!0===e?--E.readyWait:E.isReady)||(E.isReady=!0)!==e&&0<--E.readyWait||(j.resolveWith(h,[E]),E.fn.triggerHandler&&(E(h).triggerHandler("ready"),E(h).off("ready")))}}),E.ready.promise=function(e){if(!j)if(j=E.Deferred(),"complete"===h.readyState||"loading"!==h.readyState&&!h.documentElement.doScroll)C.setTimeout(E.ready);else if(h.addEventListener)h.addEventListener("DOMContentLoaded",M),C.addEventListener("load",M);else{h.attachEvent("onreadystatechange",M),C.attachEvent("onload",M);var n=!1;try{n=null==C.frameElement&&h.documentElement}catch(e){}n&&n.doScroll&&!function t(){if(!E.isReady){try{n.doScroll("left")}catch(e){return C.setTimeout(t,50)}_(),E.ready()}}()}return j.promise(e)},E.ready.promise(),E(v))break;v.ownFirst="0"===H,v.inlineBlockNeedsLayout=!1,E(function(){var e,t,n,r;(n=h.getElementsByTagName("body")[0])&&n.style&&(t=h.createElement("div"),(r=h.createElement("div")).style.cssText="position:absolute;border:0;width:0;height:0;top:0;left:-9999px",n.appendChild(r).appendChild(t),void 0!==t.style.zoom&&(t.style.cssText="display:inline;margin:0;border:0;padding:1px;width:1px;zoom:1",v.inlineBlockNeedsLayout=e=3===t.offsetWidth,e&&(n.style.zoom=1)),n.removeChild(r))}),function(){var e=h.createElement("div");v.deleteExpando=!0;try{delete e.test}catch(e){v.deleteExpando=!1}e=null}();function F(e){var t=E.noData[(e.nodeName+" ").toLowerCase()],n=+e.nodeType||1;return(1===n||9===n)&&(!t||!0!==t&&e.getAttribute("classid")===t)}var O,R=/^(?:\{[\w\W]*\}|\[[\w\W]*\])$/,P=/([A-Z])/g;function B(e,t,n){if(void 0===n&&1===e.nodeType){var r="data-"+t.replace(P,"-$1").toLowerCase();if("string"==typeof(n=e.getAttribute(r))){try{n="true"===n||"false"!==n&&("null"===n?null:+n+""===n?+n:R.test(n)?E.parseJSON(n):n)}catch(e){}E.data(e,t,n)}else n=void 0}return n}function W(e){var t;for(t in e)if(("data"!==t||!E.isEmptyObject(e[t]))&&"toJSON"!==t)return;return 1}function I(e,t,n,r){if(F(e)){var i,o,a=E.expando,s=e.nodeType,u=s?E.cache:e,l=s?e[a]:e[a]&&a;if(l&&u[l]&&(r||u[l].data)||void 0!==n||"string"!=typeof t)return u[l=l||(s?e[a]=f.pop()||E.guid++:a)]||(u[l]=s?{}:{toJSON:E.noop}),"object"!=typeof t&&"function"!=typeof t||(r?u[l]=E.extend(u[l],t):u[l].data=E.extend(u[l].data,t)),o=u[l],r||(o.data||(o.data={}),o=o.data),void 0!==n&&(o[E.camelCase(t)]=n),"string"==typeof t?null==(i=o[t])&&(i=o[E.camelCase(t)]):i=o,i}}function $(e,t,n){if(F(e)){var r,i,o=e.nodeType,a=o?E.cache:e,s=o?e[E.expando]:E.expando;if(a[s]){if(t&&(r=n?a[s]:a[s].data)){i=(t=E.isArray(t)?t.concat(E.map(t,E.camelCase)):t in r||(t=E.camelCase(t))in r?[t]:t.split(" ")).length;for(;i--;)delete r[t[i]];if(n?!W(r):!E.isEmptyObject(r))return}(n||(delete a[s].data,W(a[s])))&&(o?E.cleanData([e],!0):v.deleteExpando||a!=a.window?delete a[s]:a[s]=void 0)}}}E.extend({cache:{},noData:{"applet ":!0,"embed ":!0,"object ":"clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"},hasData:function(e){return!!(e=e.nodeType?E.cache[e[E.expando]]:e[E.expando])&&!W(e)},data:function(e,t,n){return I(e,t,n)},removeData:function(e,t){return $(e,t)},_data:function(e,t,n){return I(e,t,n,!0)},_removeData:function(e,t){return $(e,t,!0)}}),E.fn.extend({data:function(e,t){var n,r,i,o=this[0],a=o&&o.attributes;if(void 0!==e)return"object"==typeof e?this.each(function(){E.data(this,e)}):1<arguments.length?this.each(function(){E.data(this,e,t)}):o?B(o,e,E.data(o,e)):void 0;if(this.length&&(i=E.data(o),1===o.nodeType&&!E._data(o,"parsedAttrs"))){for(n=a.length;n--;)a[n]&&0===(r=a[n].name).indexOf("data-")&&B(o,r=E.camelCase(r.slice(5)),i[r]);E._data(o,"parsedAttrs",!0)}return i},removeData:function(e){return this.each(function(){E.removeData(this,e)})}}),E.extend({queue:function(e,t,n){var r;if(e)return t=(t||"fx")+"queue",r=E._data(e,t),n&&(!r||E.isArray(n)?r=E._data(e,t,E.makeArray(n)):r.push(n)),r||[]},dequeue:function(e,t){t=t||"fx";var n=E.queue(e,t),r=n.length,i=n.shift(),o=E._queueHooks(e,t);"inprogress"===i&&(i=n.shift(),r--),i&&("fx"===t&&n.unshift("inprogress"),delete o.stop,i.call(e,function(){E.dequeue(e,t)},o)),!r&&o&&o.empty.fire()},_queueHooks:function(e,t){var n=t+"queueHooks";return E._data(e,n)||E._data(e,n,{empty:E.Callbacks("once memory").add(function(){E._removeData(e,t+"queue"),E._removeData(e,n)})})}}),E.fn.extend({queue:function(t,n){var e=2;return"string"!=typeof t&&(n=t,t="fx",e--),arguments.length<e?E.queue(this[0],t):void 0===n?this:this.each(function(){var e=E.queue(this,t,n);E._queueHooks(this,t),"fx"===t&&"inprogress"!==e[0]&&E.dequeue(this,t)})},dequeue:function(e){return this.each(function(){E.dequeue(this,e)})},clearQueue:function(e){return this.queue(e||"fx",[])},promise:function(e,t){function n(){--i||o.resolveWith(a,[a])}var r,i=1,o=E.Deferred(),a=this,s=this.length;for("string"!=typeof e&&(t=e,e=void 0),e=e||"fx";s--;)(r=E._data(a[s],e+"queueHooks"))&&r.empty&&(i++,r.empty.add(n));return n(),o.promise(t)}}),v.shrinkWrapBlocks=function(){return null!=O?O:(O=!1,(t=h.getElementsByTagName("body")[0])&&t.style?(e=h.createElement("div"),(n=h.createElement("div")).style.cssText="position:absolute;border:0;width:0;height:0;top:0;left:-9999px",t.appendChild(n).appendChild(e),void 0!==e.style.zoom&&(e.style.cssText="-webkit-box-sizing:content-box;-moz-box-sizing:content-box;box-sizing:content-box;display:block;margin:0;border:0;padding:1px;width:1px;zoom:1",e.appendChild(h.createElement("div")).style.width="5px",O=3!==e.offsetWidth),t.removeChild(n),O):void 0);var e,t,n};function z(e,t){return e=t||e,"none"===E.css(e,"display")||!E.contains(e.ownerDocument,e)}var X=/[+-]?(?:\d*\.|)\d+(?:[eE][+-]?\d+|)/.source,U=new RegExp("^(?:([+-])=|)("+X+")([a-z%]*)$","i"),V=["Top","Right","Bottom","Left"];function Y(e,t,n,r){var i,o=1,a=20,s=r?function(){return r.cur()}:function(){return E.css(e,t,"")},u=s(),l=n&&n[3]||(E.cssNumber[t]?"":"px"),c=(E.cssNumber[t]||"px"!==l&&+u)&&U.exec(E.css(e,t));if(c&&c[3]!==l)for(l=l||c[3],n=n||[],c=+u||1;c/=o=o||".5",E.style(e,t,c+l),o!==(o=s()/u)&&1!==o&&--a;);return n&&(c=+c||+u||0,i=n[1]?c+(n[1]+1)*n[2]:+n[2],r&&(r.unit=l,r.start=c,r.end=i)),i}var J,G,Q,K=function(e,t,n,r,i,o,a){var s=0,u=e.length,l=null==n;if("object"===E.type(n))for(s in i=!0,n)K(e,t,s,n[s],!0,o,a);else if(void 0!==r&&(i=!0,E.isFunction(r)||(a=!0),l&&(t=a?(t.call(e,r),null):(l=t,function(e,t,n){return l.call(E(e),n)})),t))for(;s<u;s++)t(e[s],n,a?r:r.call(e[s],s,t(e[s],n)));return i?e:l?t.call(e):u?t(e[0],n):o},Z=/^(?:checkbox|radio)$/i,ee=/<([\w:-]+)/,te=/^$|\/(?:java|ecma)script/i,ne=/^\s+/,re="abbr|article|aside|audio|bdi|canvas|data|datalist|details|dialog|figcaption|figure|footer|header|hgroup|main|mark|meter|nav|output|picture|progress|section|summary|template|time|video";function ie(e){var t=re.split("|"),n=e.createDocumentFragment();if(n.createElement)for(;t.length;)n.createElement(t.pop());return n}J=h.createElement("div"),G=h.createDocumentFragment(),Q=h.createElement("input"),J.innerHTML="  <link/><table></table><a href='/a'>a</a><input type='checkbox'/>",v.leadingWhitespace=3===J.firstChild.nodeType,v.tbody=!J.getElementsByTagName("tbody").length,v.htmlSerialize=!!J.getElementsByTagName("link").length,v.html5Clone="<:nav></:nav>"!==h.createElement("nav").cloneNode(!0).outerHTML,Q.type="checkbox",Q.checked=!0,G.appendChild(Q),v.appendChecked=Q.checked,J.innerHTML="<textarea>x</textarea>",v.noCloneChecked=!!J.cloneNode(!0).lastChild.defaultValue,G.appendChild(J),(Q=h.createElement("input")).setAttribute("type","radio"),Q.setAttribute("checked","checked"),Q.setAttribute("name","t"),J.appendChild(Q),v.checkClone=J.cloneNode(!0).cloneNode(!0).lastChild.checked,v.noCloneEvent=!!J.addEventListener,J[E.expando]=1,v.attributes=!J.getAttribute(E.expando);var oe={option:[1,"<select multiple='multiple'>","</select>"],legend:[1,"<fieldset>","</fieldset>"],area:[1,"<map>","</map>"],param:[1,"<object>","</object>"],thead:[1,"<table>","</table>"],tr:[2,"<table><tbody>","</tbody></table>"],col:[2,"<table><tbody></tbody><colgroup>","</colgroup></table>"],td:[3,"<table><tbody><tr>","</tr></tbody></table>"],_default:v.htmlSerialize?[0,"",""]:[1,"X<div>","</div>"]};function ae(e,t){var n,r,i=0,o=void 0!==e.getElementsByTagName?e.getElementsByTagName(t||"*"):void 0!==e.querySelectorAll?e.querySelectorAll(t||"*"):void 0;if(!o)for(o=[],n=e.childNodes||e;null!=(r=n[i]);i++)!t||E.nodeName(r,t)?o.push(r):E.merge(o,ae(r,t));return void 0===t||t&&E.nodeName(e,t)?E.merge([e],o):o}function se(e,t){for(var n,r=0;null!=(n=e[r]);r++)E._data(n,"globalEval",!t||E._data(t[r],"globalEval"))}oe.optgroup=oe.option,oe.tbody=oe.tfoot=oe.colgroup=oe.caption=oe.thead,oe.th=oe.td;var ue=/<|&#?\w+;/,le=/<tbody/i;function ce(e){Z.test(e.type)&&(e.defaultChecked=e.checked)}function fe(e,t,n,r,i){for(var o,a,s,u,l,c,f,d=e.length,p=ie(t),h=[],m=0;m<d;m++)if((a=e[m])||0===a)if("object"===E.type(a))E.merge(h,a.nodeType?[a]:a);else if(ue.test(a)){for(u=u||p.appendChild(t.createElement("div")),l=(ee.exec(a)||["",""])[1].toLowerCase(),f=oe[l]||oe._default,u.innerHTML=f[1]+E.htmlPrefilter(a)+f[2],o=f[0];o--;)u=u.lastChild;if(!v.leadingWhitespace&&ne.test(a)&&h.push(t.createTextNode(ne.exec(a)[0])),!v.tbody)for(o=(a="table"!==l||le.test(a)?"<table>"!==f[1]||le.test(a)?0:u:u.firstChild)&&a.childNodes.length;o--;)E.nodeName(c=a.childNodes[o],"tbody")&&!c.childNodes.length&&a.removeChild(c);for(E.merge(h,u.childNodes),u.textContent="";u.firstChild;)u.removeChild(u.firstChild);u=p.lastChild}else h.push(t.createTextNode(a));for(u&&p.removeChild(u),v.appendChecked||E.grep(ae(h,"input"),ce),m=0;a=h[m++];)if(r&&-1<E.inArray(a,r))i&&i.push(a);else if(s=E.contains(a.ownerDocument,a),u=ae(p.appendChild(a),"script"),s&&se(u),n)for(o=0;a=u[o++];)te.test(a.type||"")&&n.push(a);return u=null,p}!function(){var e,t,n=h.createElement("div");for(e in{submit:!0,change:!0,focusin:!0})t="on"+e,(v[e]=t in C)||(n.setAttribute(t,"t"),v[e]=!1===n.attributes[t].expando);n=null}();var de=/^(?:input|select|textarea)$/i,pe=/^key/,he=/^(?:mouse|pointer|contextmenu|drag|drop)|click/,me=/^(?:focusinfocus|focusoutblur)$/,ge=/^([^.]*)(?:\.(.+)|)/;function ve(){return!0}function ye(){return!1}function xe(){try{return h.activeElement}catch(e){}}function be(e,t,n,r,i,o){var a,s;if("object"==typeof t){for(s in"string"!=typeof n&&(r=r||n,n=void 0),t)be(e,s,n,r,t[s],o);return e}if(null==r&&null==i?(i=n,r=n=void 0):null==i&&("string"==typeof n?(i=r,r=void 0):(i=r,r=n,n=void 0)),!1===i)i=ye;else if(!i)return e;return 1===o&&(a=i,(i=function(e){return E().off(e),a.apply(this,arguments)}).guid=a.guid||(a.guid=E.guid++)),e.each(function(){E.event.add(this,t,i,r,n)})}E.event={global:{},add:function(e,t,n,r,i){var o,a,s,u,l,c,f,d,p,h,m,g=E._data(e);if(g){for(n.handler&&(n=(u=n).handler,i=u.selector),n.guid||(n.guid=E.guid++),(a=g.events)||(a=g.events={}),(c=g.handle)||((c=g.handle=function(e){return void 0===E||e&&E.event.triggered===e.type?void 0:E.event.dispatch.apply(c.elem,arguments)}).elem=e),s=(t=(t||"").match(q)||[""]).length;s--;)p=m=(o=ge.exec(t[s])||[])[1],h=(o[2]||"").split(".").sort(),p&&(l=E.event.special[p]||{},p=(i?l.delegateType:l.bindType)||p,l=E.event.special[p]||{},f=E.extend({type:p,origType:m,data:r,handler:n,guid:n.guid,selector:i,needsContext:i&&E.expr.match.needsContext.test(i),namespace:h.join(".")},u),(d=a[p])||((d=a[p]=[]).delegateCount=0,l.setup&&!1!==l.setup.call(e,r,h,c)||(e.addEventListener?e.addEventListener(p,c,!1):e.attachEvent&&e.attachEvent("on"+p,c))),l.add&&(l.add.call(e,f),f.handler.guid||(f.handler.guid=n.guid)),i?d.splice(d.delegateCount++,0,f):d.push(f),E.event.global[p]=!0);e=null}},remove:function(e,t,n,r,i){var o,a,s,u,l,c,f,d,p,h,m,g=E.hasData(e)&&E._data(e);if(g&&(c=g.events)){for(l=(t=(t||"").match(q)||[""]).length;l--;)if(p=m=(s=ge.exec(t[l])||[])[1],h=(s[2]||"").split(".").sort(),p){for(f=E.event.special[p]||{},d=c[p=(r?f.delegateType:f.bindType)||p]||[],s=s[2]&&new RegExp("(^|\\.)"+h.join("\\.(?:.*\\.|)")+"(\\.|$)"),u=o=d.length;o--;)a=d[o],!i&&m!==a.origType||n&&n.guid!==a.guid||s&&!s.test(a.namespace)||r&&r!==a.selector&&("**"!==r||!a.selector)||(d.splice(o,1),a.selector&&d.delegateCount--,f.remove&&f.remove.call(e,a));u&&!d.length&&(f.teardown&&!1!==f.teardown.call(e,h,g.handle)||E.removeEvent(e,p,g.handle),delete c[p])}else for(p in c)E.event.remove(e,p+t[l],n,r,!0);E.isEmptyObject(c)&&(delete g.handle,E._removeData(e,"events"))}},trigger:function(e,t,n,r){var i,o,a,s,u,l,c,f=[n||h],d=g.call(e,"type")?e.type:e,p=g.call(e,"namespace")?e.namespace.split("."):[];if(a=l=n=n||h,3!==n.nodeType&&8!==n.nodeType&&!me.test(d+E.event.triggered)&&(-1<d.indexOf(".")&&(d=(p=d.split(".")).shift(),p.sort()),o=d.indexOf(":")<0&&"on"+d,(e=e[E.expando]?e:new E.Event(d,"object"==typeof e&&e)).isTrigger=r?2:3,e.namespace=p.join("."),e.rnamespace=e.namespace?new RegExp("(^|\\.)"+p.join("\\.(?:.*\\.|)")+"(\\.|$)"):null,e.result=void 0,e.target||(e.target=n),t=null==t?[e]:E.makeArray(t,[e]),u=E.event.special[d]||{},r||!u.trigger||!1!==u.trigger.apply(n,t))){if(!r&&!u.noBubble&&!E.isWindow(n)){for(s=u.delegateType||d,me.test(s+d)||(a=a.parentNode);a;a=a.parentNode)f.push(a),l=a;l===(n.ownerDocument||h)&&f.push(l.defaultView||l.parentWindow||C)}for(c=0;(a=f[c++])&&!e.isPropagationStopped();)e.type=1<c?s:u.bindType||d,(i=(E._data(a,"events")||{})[e.type]&&E._data(a,"handle"))&&i.apply(a,t),(i=o&&a[o])&&i.apply&&F(a)&&(e.result=i.apply(a,t),!1===e.result&&e.preventDefault());if(e.type=d,!r&&!e.isDefaultPrevented()&&(!u._default||!1===u._default.apply(f.pop(),t))&&F(n)&&o&&n[d]&&!E.isWindow(n)){(l=n[o])&&(n[o]=null),E.event.triggered=d;try{n[d]()}catch(e){}E.event.triggered=void 0,l&&(n[o]=l)}return e.result}},dispatch:function(e){e=E.event.fix(e);var t,n,r,i,o,a,s=c.call(arguments),u=(E._data(this,"events")||{})[e.type]||[],l=E.event.special[e.type]||{};if((s[0]=e).delegateTarget=this,!l.preDispatch||!1!==l.preDispatch.call(this,e)){for(a=E.event.handlers.call(this,e,u),t=0;(i=a[t++])&&!e.isPropagationStopped();)for(e.currentTarget=i.elem,n=0;(o=i.handlers[n++])&&!e.isImmediatePropagationStopped();)e.rnamespace&&!e.rnamespace.test(o.namespace)||(e.handleObj=o,e.data=o.data,void 0!==(r=((E.event.special[o.origType]||{}).handle||o.handler).apply(i.elem,s))&&!1===(e.result=r)&&(e.preventDefault(),e.stopPropagation()));return l.postDispatch&&l.postDispatch.call(this,e),e.result}},handlers:function(e,t){var n,r,i,o,a=[],s=t.delegateCount,u=e.target;if(s&&u.nodeType&&("click"!==e.type||isNaN(e.button)||e.button<1))for(;u!=this;u=u.parentNode||this)if(1===u.nodeType&&(!0!==u.disabled||"click"!==e.type)){for(r=[],n=0;n<s;n++)void 0===r[i=(o=t[n]).selector+" "]&&(r[i]=o.needsContext?-1<E(i,this).index(u):E.find(i,this,null,[u]).length),r[i]&&r.push(o);r.length&&a.push({elem:u,handlers:r})}return s<t.length&&a.push({elem:this,handlers:t.slice(s)}),a},fix:function(e){if(e[E.expando])return e;var t,n,r,i=e.type,o=e,a=this.fixHooks[i];for(a||(this.fixHooks[i]=a=he.test(i)?this.mouseHooks:pe.test(i)?this.keyHooks:{}),r=a.props?this.props.concat(a.props):this.props,e=new E.Event(o),t=r.length;t--;)e[n=r[t]]=o[n];return e.target||(e.target=o.srcElement||h),3===e.target.nodeType&&(e.target=e.target.parentNode),e.metaKey=!!e.metaKey,a.filter?a.filter(e,o):e},props:"altKey bubbles cancelable ctrlKey currentTarget detail eventPhase metaKey relatedTarget shiftKey target timeStamp view which".split(" "),fixHooks:{},keyHooks:{props:"char charCode key keyCode".split(" "),filter:function(e,t){return null==e.which&&(e.which=null!=t.charCode?t.charCode:t.keyCode),e}},mouseHooks:{props:"button buttons clientX clientY fromElement offsetX offsetY pageX pageY screenX screenY toElement".split(" "),filter:function(e,t){var n,r,i,o=t.button,a=t.fromElement;return null==e.pageX&&null!=t.clientX&&(i=(r=e.target.ownerDocument||h).documentElement,n=r.body,e.pageX=t.clientX+(i&&i.scrollLeft||n&&n.scrollLeft||0)-(i&&i.clientLeft||n&&n.clientLeft||0),e.pageY=t.clientY+(i&&i.scrollTop||n&&n.scrollTop||0)-(i&&i.clientTop||n&&n.clientTop||0)),!e.relatedTarget&&a&&(e.relatedTarget=a===e.target?t.toElement:a),e.which||void 0===o||(e.which=1&o?1:2&o?3:4&o?2:0),e}},special:{load:{noBubble:!0},focus:{trigger:function(){if(this!==xe()&&this.focus)try{return this.focus(),!1}catch(e){}},delegateType:"focusin"},blur:{trigger:function(){if(this===xe()&&this.blur)return this.blur(),!1},delegateType:"focusout"},click:{trigger:function(){if(E.nodeName(this,"input")&&"checkbox"===this.type&&this.click)return this.click(),!1},_default:function(e){return E.nodeName(e.target,"a")}},beforeunload:{postDispatch:function(e){void 0!==e.result&&e.originalEvent&&(e.originalEvent.returnValue=e.result)}}},simulate:function(e,t,n){var r=E.extend(new E.Event,n,{type:e,isSimulated:!0});E.event.trigger(r,null,t),r.isDefaultPrevented()&&n.preventDefault()}},E.removeEvent=h.removeEventListener?function(e,t,n){e.removeEventListener&&e.removeEventListener(t,n)}:function(e,t,n){var r="on"+t;e.detachEvent&&(void 0===e[r]&&(e[r]=null),e.detachEvent(r,n))},E.Event=function(e,t){if(!(this instanceof E.Event))return new E.Event(e,t);e&&e.type?(this.originalEvent=e,this.type=e.type,this.isDefaultPrevented=e.defaultPrevented||void 0===e.defaultPrevented&&!1===e.returnValue?ve:ye):this.type=e,t&&E.extend(this,t),this.timeStamp=e&&e.timeStamp||E.now(),this[E.expando]=!0},E.Event.prototype={constructor:E.Event,isDefaultPrevented:ye,isPropagationStopped:ye,isImmediatePropagationStopped:ye,preventDefault:function(){var e=this.originalEvent;this.isDefaultPrevented=ve,e&&(e.preventDefault?e.preventDefault():e.returnValue=!1)},stopPropagation:function(){var e=this.originalEvent;this.isPropagationStopped=ve,e&&!this.isSimulated&&(e.stopPropagation&&e.stopPropagation(),e.cancelBubble=!0)},stopImmediatePropagation:function(){var e=this.originalEvent;this.isImmediatePropagationStopped=ve,e&&e.stopImmediatePropagation&&e.stopImmediatePropagation(),this.stopPropagation()}},E.each({mouseenter:"mouseover",mouseleave:"mouseout",pointerenter:"pointerover",pointerleave:"pointerout"},function(e,i){E.event.special[e]={delegateType:i,bindType:i,handle:function(e){var t,n=e.relatedTarget,r=e.handleObj;return n&&(n===this||E.contains(this,n))||(e.type=r.origType,t=r.handler.apply(this,arguments),e.type=i),t}}}),v.submit||(E.event.special.submit={setup:function(){if(E.nodeName(this,"form"))return!1;E.event.add(this,"click._submit keypress._submit",function(e){var t=e.target,n=E.nodeName(t,"input")||E.nodeName(t,"button")?E.prop(t,"form"):void 0;n&&!E._data(n,"submit")&&(E.event.add(n,"submit._submit",function(e){e._submitBubble=!0}),E._data(n,"submit",!0))})},postDispatch:function(e){e._submitBubble&&(delete e._submitBubble,this.parentNode&&!e.isTrigger&&E.event.simulate("submit",this.parentNode,e))},teardown:function(){if(E.nodeName(this,"form"))return!1;E.event.remove(this,"._submit")}}),v.change||(E.event.special.change={setup:function(){if(de.test(this.nodeName))return"checkbox"!==this.type&&"radio"!==this.type||(E.event.add(this,"propertychange._change",function(e){"checked"===e.originalEvent.propertyName&&(this._justChanged=!0)}),E.event.add(this,"click._change",function(e){this._justChanged&&!e.isTrigger&&(this._justChanged=!1),E.event.simulate("change",this,e)})),!1;E.event.add(this,"beforeactivate._change",function(e){var t=e.target;de.test(t.nodeName)&&!E._data(t,"change")&&(E.event.add(t,"change._change",function(e){!this.parentNode||e.isSimulated||e.isTrigger||E.event.simulate("change",this.parentNode,e)}),E._data(t,"change",!0))})},handle:function(e){var t=e.target;if(this!==t||e.isSimulated||e.isTrigger||"radio"!==t.type&&"checkbox"!==t.type)return e.handleObj.handler.apply(this,arguments)},teardown:function(){return E.event.remove(this,"._change"),!de.test(this.nodeName)}}),v.focusin||E.each({focus:"focusin",blur:"focusout"},function(n,r){function i(e){E.event.simulate(r,e.target,E.event.fix(e))}E.event.special[r]={setup:function(){var e=this.ownerDocument||this,t=E._data(e,r);t||e.addEventListener(n,i,!0),E._data(e,r,(t||0)+1)},teardown:function(){var e=this.ownerDocument||this,t=E._data(e,r)-1;t?E._data(e,r,t):(e.removeEventListener(n,i,!0),E._removeData(e,r))}}}),E.fn.extend({on:function(e,t,n,r){return be(this,e,t,n,r)},one:function(e,t,n,r){return be(this,e,t,n,r,1)},off:function(e,t,n){var r,i;if(e&&e.preventDefault&&e.handleObj)return r=e.handleObj,E(e.delegateTarget).off(r.namespace?r.origType+"."+r.namespace:r.origType,r.selector,r.handler),this;if("object"!=typeof e)return!1!==t&&"function"!=typeof t||(n=t,t=void 0),!1===n&&(n=ye),this.each(function(){E.event.remove(this,e,n,t)});for(i in e)this.off(i,t,e[i]);return this},trigger:function(e,t){return this.each(function(){E.event.trigger(e,t,this)})},triggerHandler:function(e,t){var n=this[0];if(n)return E.event.trigger(e,t,n,!0)}});var we=/ jQuery\d+="(?:null|\d+)"/g,Te=new RegExp("<(?:"+re+")[\\s/>]","i"),Ce=/<(?!area|br|col|embed|hr|img|input|link|meta|param)(([\w:-]+)[^>]*)\/>/gi,Ee=/<script|<style|<link/i,Ne=/checked\s*(?:[^=]|=\s*.checked.)/i,ke=/^true\/(.*)/,Se=/^\s*<!(?:\[CDATA\[|--)|(?:\]\]|--)>\s*$/g,Ae=ie(h).appendChild(h.createElement("div"));function De(e,t){return E.nodeName(e,"table")&&E.nodeName(11!==t.nodeType?t:t.firstChild,"tr")?e.getElementsByTagName("tbody")[0]||e.appendChild(e.ownerDocument.createElement("tbody")):e}function Le(e){return e.type=(null!==E.find.attr(e,"type"))+"/"+e.type,e}function je(e){var t=ke.exec(e.type);return t?e.type=t[1]:e.removeAttribute("type"),e}function He(e,t){if(1===t.nodeType&&E.hasData(e)){var n,r,i,o=E._data(e),a=E._data(t,o),s=o.events;if(s)for(n in delete a.handle,a.events={},s)for(r=0,i=s[n].length;r<i;r++)E.event.add(t,n,s[n][r]);a.data&&(a.data=E.extend({},a.data))}}function qe(e,t){var n,r,i;if(1===t.nodeType){if(n=t.nodeName.toLowerCase(),!v.noCloneEvent&&t[E.expando]){for(r in(i=E._data(t)).events)E.removeEvent(t,r,i.handle);t.removeAttribute(E.expando)}"script"===n&&t.text!==e.text?(Le(t).text=e.text,je(t)):"object"===n?(t.parentNode&&(t.outerHTML=e.outerHTML),v.html5Clone&&e.innerHTML&&!E.trim(t.innerHTML)&&(t.innerHTML=e.innerHTML)):"input"===n&&Z.test(e.type)?(t.defaultChecked=t.checked=e.checked,t.value!==e.value&&(t.value=e.value)):"option"===n?t.defaultSelected=t.selected=e.defaultSelected:"input"!==n&&"textarea"!==n||(t.defaultValue=e.defaultValue)}}function _e(n,r,i,o){r=m.apply([],r);var e,t,a,s,u,l,c=0,f=n.length,d=f-1,p=r[0],h=E.isFunction(p);if(h||1<f&&"string"==typeof p&&!v.checkClone&&Ne.test(p))return n.each(function(e){var t=n.eq(e);h&&(r[0]=p.call(this,e,t.html())),_e(t,r,i,o)});if(f&&(e=(l=fe(r,n[0].ownerDocument,!1,n,o)).firstChild,1===l.childNodes.length&&(l=e),e||o)){for(a=(s=E.map(ae(l,"script"),Le)).length;c<f;c++)t=l,c!==d&&(t=E.clone(t,!0,!0),a&&E.merge(s,ae(t,"script"))),i.call(n[c],t,c);if(a)for(u=s[s.length-1].ownerDocument,E.map(s,je),c=0;c<a;c++)t=s[c],te.test(t.type||"")&&!E._data(t,"globalEval")&&E.contains(u,t)&&(t.src?E._evalUrl&&E._evalUrl(t.src):E.globalEval((t.text||t.textContent||t.innerHTML||"").replace(Se,"")));l=e=null}return n}function Me(e,t,n){for(var r,i=t?E.filter(t,e):e,o=0;null!=(r=i[o]);o++)n||1!==r.nodeType||E.cleanData(ae(r)),r.parentNode&&(n&&E.contains(r.ownerDocument,r)&&se(ae(r,"script")),r.parentNode.removeChild(r));return e}E.extend({htmlPrefilter:function(e){return e.replace(Ce,"<$1></$2>")},clone:function(e,t,n){var r,i,o,a,s,u=E.contains(e.ownerDocument,e);if(v.html5Clone||E.isXMLDoc(e)||!Te.test("<"+e.nodeName+">")?o=e.cloneNode(!0):(Ae.innerHTML=e.outerHTML,Ae.removeChild(o=Ae.firstChild)),!(v.noCloneEvent&&v.noCloneChecked||1!==e.nodeType&&11!==e.nodeType||E.isXMLDoc(e)))for(r=ae(o),s=ae(e),a=0;null!=(i=s[a]);++a)r[a]&&qe(i,r[a]);if(t)if(n)for(s=s||ae(e),r=r||ae(o),a=0;null!=(i=s[a]);a++)He(i,r[a]);else He(e,o);return 0<(r=ae(o,"script")).length&&se(r,!u&&ae(e,"script")),r=s=i=null,o},cleanData:function(e,t){for(var n,r,i,o,a=0,s=E.expando,u=E.cache,l=v.attributes,c=E.event.special;null!=(n=e[a]);a++)if((t||F(n))&&(o=(i=n[s])&&u[i])){if(o.events)for(r in o.events)c[r]?E.event.remove(n,r):E.removeEvent(n,r,o.handle);u[i]&&(delete u[i],l||void 0===n.removeAttribute?n[s]=void 0:n.removeAttribute(s),f.push(i))}}}),E.fn.extend({domManip:_e,detach:function(e){return Me(this,e,!0)},remove:function(e){return Me(this,e)},text:function(e){return K(this,function(e){return void 0===e?E.text(this):this.empty().append((this[0]&&this[0].ownerDocument||h).createTextNode(e))},null,e,arguments.length)},append:function(){return _e(this,arguments,function(e){1!==this.nodeType&&11!==this.nodeType&&9!==this.nodeType||De(this,e).appendChild(e)})},prepend:function(){return _e(this,arguments,function(e){if(1===this.nodeType||11===this.nodeType||9===this.nodeType){var t=De(this,e);t.insertBefore(e,t.firstChild)}})},before:function(){return _e(this,arguments,function(e){this.parentNode&&this.parentNode.insertBefore(e,this)})},after:function(){return _e(this,arguments,function(e){this.parentNode&&this.parentNode.insertBefore(e,this.nextSibling)})},empty:function(){for(var e,t=0;null!=(e=this[t]);t++){for(1===e.nodeType&&E.cleanData(ae(e,!1));e.firstChild;)e.removeChild(e.firstChild);e.options&&E.nodeName(e,"select")&&(e.options.length=0)}return this},clone:function(e,t){return e=null!=e&&e,t=null==t?e:t,this.map(function(){return E.clone(this,e,t)})},html:function(e){return K(this,function(e){var t=this[0]||{},n=0,r=this.length;if(void 0===e)return 1===t.nodeType?t.innerHTML.replace(we,""):void 0;if("string"==typeof e&&!Ee.test(e)&&(v.htmlSerialize||!Te.test(e))&&(v.leadingWhitespace||!ne.test(e))&&!oe[(ee.exec(e)||["",""])[1].toLowerCase()]){e=E.htmlPrefilter(e);try{for(;n<r;n++)1===(t=this[n]||{}).nodeType&&(E.cleanData(ae(t,!1)),t.innerHTML=e);t=0}catch(e){}}t&&this.empty().append(e)},null,e,arguments.length)},replaceWith:function(){var n=[];return _e(this,arguments,function(e){var t=this.parentNode;E.inArray(this,n)<0&&(E.cleanData(ae(this)),t&&t.replaceChild(e,this))},n)}}),E.each({appendTo:"append",prependTo:"prepend",insertBefore:"before",insertAfter:"after",replaceAll:"replaceWith"},function(e,a){E.fn[e]=function(e){for(var t,n=0,r=[],i=E(e),o=i.length-1;n<=o;n++)t=n===o?this:this.clone(!0),E(i[n])[a](t),s.apply(r,t.get());return this.pushStack(r)}});var Fe,Oe={HTML:"block",BODY:"block"};function Re(e,t){var n=E(t.createElement(e)).appendTo(t.body),r=E.css(n[0],"display");return n.detach(),r}function Pe(e){var t=h,n=Oe[e];return n||("none"!==(n=Re(e,t))&&n||((t=((Fe=(Fe||E("<iframe frameborder='0' width='0' height='0'/>")).appendTo(t.documentElement))[0].contentWindow||Fe[0].contentDocument).document).write(),t.close(),n=Re(e,t),Fe.detach()),Oe[e]=n),n}function Be(e,t,n,r){var i,o,a={};for(o in t)a[o]=e.style[o],e.style[o]=t[o];for(o in i=n.apply(e,r||[]),t)e.style[o]=a[o];return i}var We,Ie,$e,ze,Xe,Ue,Ve,Ye,Je=/^margin/,Ge=new RegExp("^("+X+")(?!px)[a-z%]+$","i"),Qe=h.documentElement;function Ke(){var e,t,n=h.documentElement;n.appendChild(Ve),Ye.style.cssText="-webkit-box-sizing:border-box;box-sizing:border-box;position:relative;display:block;margin:auto;border:1px;padding:1px;top:1%;width:50%",We=$e=Ue=!1,Ie=Xe=!0,C.getComputedStyle&&(t=C.getComputedStyle(Ye),We="1%"!==(t||{}).top,Ue="2px"===(t||{}).marginLeft,$e="4px"===(t||{width:"4px"}).width,Ye.style.marginRight="50%",Ie="4px"===(t||{marginRight:"4px"}).marginRight,(e=Ye.appendChild(h.createElement("div"))).style.cssText=Ye.style.cssText="-webkit-box-sizing:content-box;-moz-box-sizing:content-box;box-sizing:content-box;display:block;margin:0;border:0;padding:0",e.style.marginRight=e.style.width="0",Ye.style.width="1px",Xe=!parseFloat((C.getComputedStyle(e)||{}).marginRight),Ye.removeChild(e)),Ye.style.display="none",(ze=0===Ye.getClientRects().length)&&(Ye.style.display="",Ye.innerHTML="<table><tr><td></td><td>t</td></tr></table>",(e=Ye.getElementsByTagName("td"))[0].style.cssText="margin:0;border:0;padding:0;display:none",(ze=0===e[0].offsetHeight)&&(e[0].style.display="",e[1].style.display="none",ze=0===e[0].offsetHeight)),n.removeChild(Ve)}Ve=h.createElement("div"),(Ye=h.createElement("div")).style&&(Ye.style.cssText="float:left;opacity:.5",v.opacity="0.5"===Ye.style.opacity,v.cssFloat=!!Ye.style.cssFloat,Ye.style.backgroundClip="content-box",Ye.cloneNode(!0).style.backgroundClip="",v.clearCloneStyle="content-box"===Ye.style.backgroundClip,(Ve=h.createElement("div")).style.cssText="border:0;width:8px;height:0;top:0;left:-9999px;padding:0;margin-top:1px;position:absolute",Ye.innerHTML="",Ve.appendChild(Ye),v.boxSizing=""===Ye.style.boxSizing||""===Ye.style.MozBoxSizing||""===Ye.style.WebkitBoxSizing,E.extend(v,{reliableHiddenOffsets:function(){return null==We&&Ke(),ze},boxSizingReliable:function(){return null==We&&Ke(),$e},pixelMarginRight:function(){return null==We&&Ke(),Ie},pixelPosition:function(){return null==We&&Ke(),We},reliableMarginRight:function(){return null==We&&Ke(),Xe},reliableMarginLeft:function(){return null==We&&Ke(),Ue}}));var Ze,et,tt=/^(top|right|bottom|left)$/;function nt(e,t){return{get:function(){if(!e())return(this.get=t).apply(this,arguments);delete this.get}}}C.getComputedStyle?(Ze=function(e){var t=e.ownerDocument.defaultView;return t&&t.opener||(t=C),t.getComputedStyle(e)},et=function(e,t,n){var r,i,o,a,s=e.style;return""!==(a=(n=n||Ze(e))?n.getPropertyValue(t)||n[t]:void 0)&&void 0!==a||E.contains(e.ownerDocument,e)||(a=E.style(e,t)),n&&!v.pixelMarginRight()&&Ge.test(a)&&Je.test(t)&&(r=s.width,i=s.minWidth,o=s.maxWidth,s.minWidth=s.maxWidth=s.width=a,a=n.width,s.width=r,s.minWidth=i,s.maxWidth=o),void 0===a?a:a+""}):Qe.currentStyle&&(Ze=function(e){return e.currentStyle},et=function(e,t,n){var r,i,o,a,s=e.style;return null==(a=(n=n||Ze(e))?n[t]:void 0)&&s&&s[t]&&(a=s[t]),Ge.test(a)&&!tt.test(t)&&(r=s.left,(o=(i=e.runtimeStyle)&&i.left)&&(i.left=e.currentStyle.left),s.left="fontSize"===t?"1em":a,a=s.pixelLeft+"px",s.left=r,o&&(i.left=o)),void 0===a?a:a+""||"auto"});var rt=/alpha\([^)]*\)/i,it=/opacity\s*=\s*([^)]*)/i,ot=/^(none|table(?!-c[ea]).+)/,at=new RegExp("^("+X+")(.*)$","i"),st={position:"absolute",visibility:"hidden",display:"block"},ut={letterSpacing:"0",fontWeight:"400"},lt=["Webkit","O","Moz","ms"],ct=h.createElement("div").style;function ft(e){if(e in ct)return e;for(var t=e.charAt(0).toUpperCase()+e.slice(1),n=lt.length;n--;)if((e=lt[n]+t)in ct)return e}function dt(e,t){for(var n,r,i,o=[],a=0,s=e.length;a<s;a++)(r=e[a]).style&&(o[a]=E._data(r,"olddisplay"),n=r.style.display,t?(o[a]||"none"!==n||(r.style.display=""),""===r.style.display&&z(r)&&(o[a]=E._data(r,"olddisplay",Pe(r.nodeName)))):(i=z(r),(n&&"none"!==n||!i)&&E._data(r,"olddisplay",i?n:E.css(r,"display"))));for(a=0;a<s;a++)(r=e[a]).style&&(t&&"none"!==r.style.display&&""!==r.style.display||(r.style.display=t?o[a]||"":"none"));return e}function pt(e,t,n){var r=at.exec(t);return r?Math.max(0,r[1]-(n||0))+(r[2]||"px"):t}function ht(e,t,n,r,i){for(var o=n===(r?"border":"content")?4:"width"===t?1:0,a=0;o<4;o+=2)"margin"===n&&(a+=E.css(e,n+V[o],!0,i)),r?("content"===n&&(a-=E.css(e,"padding"+V[o],!0,i)),"margin"!==n&&(a-=E.css(e,"border"+V[o]+"Width",!0,i))):(a+=E.css(e,"padding"+V[o],!0,i),"padding"!==n&&(a+=E.css(e,"border"+V[o]+"Width",!0,i)));return a}function mt(e,t,n){var r=!0,i="width"===t?e.offsetWidth:e.offsetHeight,o=Ze(e),a=v.boxSizing&&"border-box"===E.css(e,"boxSizing",!1,o);if(h.msFullscreenElement&&C.top!==C&&e.getClientRects().length&&(i=Math.round(100*e.getBoundingClientRect()[t])),i<=0||null==i){if(((i=et(e,t,o))<0||null==i)&&(i=e.style[t]),Ge.test(i))return i;r=a&&(v.boxSizingReliable()||i===e.style[t]),i=parseFloat(i)||0}return i+ht(e,t,n||(a?"border":"content"),r,o)+"px"}function gt(e,t,n,r,i){return new gt.prototype.init(e,t,n,r,i)}E.extend({cssHooks:{opacity:{get:function(e,t){if(t){var n=et(e,"opacity");return""===n?"1":n}}}},cssNumber:{animationIterationCount:!0,columnCount:!0,fillOpacity:!0,flexGrow:!0,flexShrink:!0,fontWeight:!0,lineHeight:!0,opacity:!0,order:!0,orphans:!0,widows:!0,zIndex:!0,zoom:!0},cssProps:{float:v.cssFloat?"cssFloat":"styleFloat"},style:function(e,t,n,r){if(e&&3!==e.nodeType&&8!==e.nodeType&&e.style){var i,o,a,s=E.camelCase(t),u=e.style;if(t=E.cssProps[s]||(E.cssProps[s]=ft(s)||s),a=E.cssHooks[t]||E.cssHooks[s],void 0===n)return a&&"get"in a&&void 0!==(i=a.get(e,!1,r))?i:u[t];if("string"===(o=typeof n)&&(i=U.exec(n))&&i[1]&&(n=Y(e,t,i),o="number"),null!=n&&n==n&&("number"===o&&(n+=i&&i[3]||(E.cssNumber[s]?"":"px")),v.clearCloneStyle||""!==n||0!==t.indexOf("background")||(u[t]="inherit"),!(a&&"set"in a&&void 0===(n=a.set(e,n,r)))))try{u[t]=n}catch(e){}}},css:function(e,t,n,r){var i,o,a,s=E.camelCase(t);return t=E.cssProps[s]||(E.cssProps[s]=ft(s)||s),(a=E.cssHooks[t]||E.cssHooks[s])&&"get"in a&&(o=a.get(e,!0,n)),void 0===o&&(o=et(e,t,r)),"normal"===o&&t in ut&&(o=ut[t]),""===n||n?(i=parseFloat(o),!0===n||isFinite(i)?i||0:o):o}}),E.each(["height","width"],function(e,i){E.cssHooks[i]={get:function(e,t,n){if(t)return ot.test(E.css(e,"display"))&&0===e.offsetWidth?Be(e,st,function(){return mt(e,i,n)}):mt(e,i,n)},set:function(e,t,n){var r=n&&Ze(e);return pt(0,t,n?ht(e,i,n,v.boxSizing&&"border-box"===E.css(e,"boxSizing",!1,r),r):0)}}}),v.opacity||(E.cssHooks.opacity={get:function(e,t){return it.test((t&&e.currentStyle?e.currentStyle.filter:e.style.filter)||"")?.01*parseFloat(RegExp.$1)+"":t?"1":""},set:function(e,t){var n=e.style,r=e.currentStyle,i=E.isNumeric(t)?"alpha(opacity="+100*t+")":"",o=r&&r.filter||n.filter||"";((n.zoom=1)<=t||""===t)&&""===E.trim(o.replace(rt,""))&&n.removeAttribute&&(n.removeAttribute("filter"),""===t||r&&!r.filter)||(n.filter=rt.test(o)?o.replace(rt,i):o+" "+i)}}),E.cssHooks.marginRight=nt(v.reliableMarginRight,function(e,t){if(t)return Be(e,{display:"inline-block"},et,[e,"marginRight"])}),E.cssHooks.marginLeft=nt(v.reliableMarginLeft,function(e,t){if(t)return(parseFloat(et(e,"marginLeft"))||(E.contains(e.ownerDocument,e)?e.getBoundingClientRect().left-Be(e,{marginLeft:0},function(){return e.getBoundingClientRect().left}):0))+"px"}),E.each({margin:"",padding:"",border:"Width"},function(i,o){E.cssHooks[i+o]={expand:function(e){for(var t=0,n={},r="string"==typeof e?e.split(" "):[e];t<4;t++)n[i+V[t]+o]=r[t]||r[t-2]||r[0];return n}},Je.test(i)||(E.cssHooks[i+o].set=pt)}),E.fn.extend({css:function(e,t){return K(this,function(e,t,n){var r,i,o={},a=0;if(E.isArray(t)){for(r=Ze(e),i=t.length;a<i;a++)o[t[a]]=E.css(e,t[a],!1,r);return o}return void 0!==n?E.style(e,t,n):E.css(e,t)},e,t,1<arguments.length)},show:function(){return dt(this,!0)},hide:function(){return dt(this)},toggle:function(e){return"boolean"==typeof e?e?this.show():this.hide():this.each(function(){z(this)?E(this).show():E(this).hide()})}}),((E.Tween=gt).prototype={constructor:gt,init:function(e,t,n,r,i,o){this.elem=e,this.prop=n,this.easing=i||E.easing._default,this.options=t,this.start=this.now=this.cur(),this.end=r,this.unit=o||(E.cssNumber[n]?"":"px")},cur:function(){var e=gt.propHooks[this.prop];return e&&e.get?e.get(this):gt.propHooks._default.get(this)},run:function(e){var t,n=gt.propHooks[this.prop];return this.options.duration?this.pos=t=E.easing[this.easing](e,this.options.duration*e,0,1,this.options.duration):this.pos=t=e,this.now=(this.end-this.start)*t+this.start,this.options.step&&this.options.step.call(this.elem,this.now,this),n&&n.set?n.set(this):gt.propHooks._default.set(this),this}}).init.prototype=gt.prototype,(gt.propHooks={_default:{get:function(e){var t;return 1!==e.elem.nodeType||null!=e.elem[e.prop]&&null==e.elem.style[e.prop]?e.elem[e.prop]:(t=E.css(e.elem,e.prop,""))&&"auto"!==t?t:0},set:function(e){E.fx.step[e.prop]?E.fx.step[e.prop](e):1!==e.elem.nodeType||null==e.elem.style[E.cssProps[e.prop]]&&!E.cssHooks[e.prop]?e.elem[e.prop]=e.now:E.style(e.elem,e.prop,e.now+e.unit)}}}).scrollTop=gt.propHooks.scrollLeft={set:function(e){e.elem.nodeType&&e.elem.parentNode&&(e.elem[e.prop]=e.now)}},E.easing={linear:function(e){return e},swing:function(e){return.5-Math.cos(e*Math.PI)/2},_default:"swing"},E.fx=gt.prototype.init,E.fx.step={};var vt,yt,xt,bt,wt,Tt,Ct,Et=/^(?:toggle|show|hide)$/,Nt=/queueHooks$/;function kt(){return C.setTimeout(function(){vt=void 0}),vt=E.now()}function St(e,t){var n,r={height:e},i=0;for(t=t?1:0;i<4;i+=2-t)r["margin"+(n=V[i])]=r["padding"+n]=e;return t&&(r.opacity=r.width=e),r}function At(e,t,n){for(var r,i=(Dt.tweeners[t]||[]).concat(Dt.tweeners["*"]),o=0,a=i.length;o<a;o++)if(r=i[o].call(n,t,e))return r}function Dt(o,e,t){var n,a,r=0,i=Dt.prefilters.length,s=E.Deferred().always(function(){delete u.elem}),u=function(){if(a)return!1;for(var e=vt||kt(),t=Math.max(0,l.startTime+l.duration-e),n=1-(t/l.duration||0),r=0,i=l.tweens.length;r<i;r++)l.tweens[r].run(n);return s.notifyWith(o,[l,n,t]),n<1&&i?t:(s.resolveWith(o,[l]),!1)},l=s.promise({elem:o,props:E.extend({},e),opts:E.extend(!0,{specialEasing:{},easing:E.easing._default},t),originalProperties:e,originalOptions:t,startTime:vt||kt(),duration:t.duration,tweens:[],createTween:function(e,t){var n=E.Tween(o,l.opts,e,t,l.opts.specialEasing[e]||l.opts.easing);return l.tweens.push(n),n},stop:function(e){var t=0,n=e?l.tweens.length:0;if(a)return this;for(a=!0;t<n;t++)l.tweens[t].run(1);return e?(s.notifyWith(o,[l,1,0]),s.resolveWith(o,[l,e])):s.rejectWith(o,[l,e]),this}}),c=l.props;for(!function(e,t){var n,r,i,o,a;for(n in e)if(i=t[r=E.camelCase(n)],o=e[n],E.isArray(o)&&(i=o[1],o=e[n]=o[0]),n!==r&&(e[r]=o,delete e[n]),(a=E.cssHooks[r])&&"expand"in a)for(n in o=a.expand(o),delete e[r],o)n in e||(e[n]=o[n],t[n]=i);else t[r]=i}(c,l.opts.specialEasing);r<i;r++)if(n=Dt.prefilters[r].call(l,o,c,l.opts))return E.isFunction(n.stop)&&(E._queueHooks(l.elem,l.opts.queue).stop=E.proxy(n.stop,n)),n;return E.map(c,At,l),E.isFunction(l.opts.start)&&l.opts.start.call(o,l),E.fx.timer(E.extend(u,{elem:o,anim:l,queue:l.opts.queue})),l.progress(l.opts.progress).done(l.opts.done,l.opts.complete).fail(l.opts.fail).always(l.opts.always)}E.Animation=E.extend(Dt,{tweeners:{"*":[function(e,t){var n=this.createTween(e,t);return Y(n.elem,e,U.exec(t),n),n}]},tweener:function(e,t){for(var n,r=0,i=(e=E.isFunction(e)?(t=e,["*"]):e.match(q)).length;r<i;r++)n=e[r],Dt.tweeners[n]=Dt.tweeners[n]||[],Dt.tweeners[n].unshift(t)},prefilters:[function(t,e,n){var r,i,o,a,s,u,l,c=this,f={},d=t.style,p=t.nodeType&&z(t),h=E._data(t,"fxshow");for(r in n.queue||(null==(s=E._queueHooks(t,"fx")).unqueued&&(s.unqueued=0,u=s.empty.fire,s.empty.fire=function(){s.unqueued||u()}),s.unqueued++,c.always(function(){c.always(function(){s.unqueued--,E.queue(t,"fx").length||s.empty.fire()})})),1===t.nodeType&&("height"in e||"width"in e)&&(n.overflow=[d.overflow,d.overflowX,d.overflowY],"inline"===("none"===(l=E.css(t,"display"))?E._data(t,"olddisplay")||Pe(t.nodeName):l)&&"none"===E.css(t,"float")&&(v.inlineBlockNeedsLayout&&"inline"!==Pe(t.nodeName)?d.zoom=1:d.display="inline-block")),n.overflow&&(d.overflow="hidden",v.shrinkWrapBlocks()||c.always(function(){d.overflow=n.overflow[0],d.overflowX=n.overflow[1],d.overflowY=n.overflow[2]})),e)if(i=e[r],Et.exec(i)){if(delete e[r],o=o||"toggle"===i,i===(p?"hide":"show")){if("show"!==i||!h||void 0===h[r])continue;p=!0}f[r]=h&&h[r]||E.style(t,r)}else l=void 0;if(E.isEmptyObject(f))"inline"===("none"===l?Pe(t.nodeName):l)&&(d.display=l);else for(r in h?"hidden"in h&&(p=h.hidden):h=E._data(t,"fxshow",{}),o&&(h.hidden=!p),p?E(t).show():c.done(function(){E(t).hide()}),c.done(function(){var e;for(e in E._removeData(t,"fxshow"),f)E.style(t,e,f[e])}),f)a=At(p?h[r]:0,r,c),r in h||(h[r]=a.start,p&&(a.end=a.start,a.start="width"===r||"height"===r?1:0))}],prefilter:function(e,t){t?Dt.prefilters.unshift(e):Dt.prefilters.push(e)}}),E.speed=function(e,t,n){var r=e&&"object"==typeof e?E.extend({},e):{complete:n||!n&&t||E.isFunction(e)&&e,duration:e,easing:n&&t||t&&!E.isFunction(t)&&t};return r.duration=E.fx.off?0:"number"==typeof r.duration?r.duration:r.duration in E.fx.speeds?E.fx.speeds[r.duration]:E.fx.speeds._default,null!=r.queue&&!0!==r.queue||(r.queue="fx"),r.old=r.complete,r.complete=function(){E.isFunction(r.old)&&r.old.call(this),r.queue&&E.dequeue(this,r.queue)},r},E.fn.extend({fadeTo:function(e,t,n,r){return this.filter(z).css("opacity",0).show().end().animate({opacity:t},e,n,r)},animate:function(t,e,n,r){function i(){var e=Dt(this,E.extend({},t),a);(o||E._data(this,"finish"))&&e.stop(!0)}var o=E.isEmptyObject(t),a=E.speed(e,n,r);return i.finish=i,o||!1===a.queue?this.each(i):this.queue(a.queue,i)},stop:function(i,e,o){function a(e){var t=e.stop;delete e.stop,t(o)}return"string"!=typeof i&&(o=e,e=i,i=void 0),e&&!1!==i&&this.queue(i||"fx",[]),this.each(function(){var e=!0,t=null!=i&&i+"queueHooks",n=E.timers,r=E._data(this);if(t)r[t]&&r[t].stop&&a(r[t]);else for(t in r)r[t]&&r[t].stop&&Nt.test(t)&&a(r[t]);for(t=n.length;t--;)n[t].elem!==this||null!=i&&n[t].queue!==i||(n[t].anim.stop(o),e=!1,n.splice(t,1));!e&&o||E.dequeue(this,i)})},finish:function(a){return!1!==a&&(a=a||"fx"),this.each(function(){var e,t=E._data(this),n=t[a+"queue"],r=t[a+"queueHooks"],i=E.timers,o=n?n.length:0;for(t.finish=!0,E.queue(this,a,[]),r&&r.stop&&r.stop.call(this,!0),e=i.length;e--;)i[e].elem===this&&i[e].queue===a&&(i[e].anim.stop(!0),i.splice(e,1));for(e=0;e<o;e++)n[e]&&n[e].finish&&n[e].finish.call(this);delete t.finish})}}),E.each(["toggle","show","hide"],function(e,r){var i=E.fn[r];E.fn[r]=function(e,t,n){return null==e||"boolean"==typeof e?i.apply(this,arguments):this.animate(St(r,!0),e,t,n)}}),E.each({slideDown:St("show"),slideUp:St("hide"),slideToggle:St("toggle"),fadeIn:{opacity:"show"},fadeOut:{opacity:"hide"},fadeToggle:{opacity:"toggle"}},function(e,r){E.fn[e]=function(e,t,n){return this.animate(r,e,t,n)}}),E.timers=[],E.fx.tick=function(){var e,t=E.timers,n=0;for(vt=E.now();n<t.length;n++)(e=t[n])()||t[n]!==e||t.splice(n--,1);t.length||E.fx.stop(),vt=void 0},E.fx.timer=function(e){E.timers.push(e),e()?E.fx.start():E.timers.pop()},E.fx.interval=13,E.fx.start=function(){yt=yt||C.setInterval(E.fx.tick,E.fx.interval)},E.fx.stop=function(){C.clearInterval(yt),yt=null},E.fx.speeds={slow:600,fast:200,_default:400},E.fn.delay=function(r,e){return r=E.fx&&E.fx.speeds[r]||r,e=e||"fx",this.queue(e,function(e,t){var n=C.setTimeout(e,r);t.stop=function(){C.clearTimeout(n)}})},bt=h.createElement("input"),wt=h.createElement("div"),Tt=h.createElement("select"),Ct=Tt.appendChild(h.createElement("option")),(wt=h.createElement("div")).setAttribute("className","t"),wt.innerHTML="  <link/><table></table><a href='/a'>a</a><input type='checkbox'/>",xt=wt.getElementsByTagName("a")[0],bt.setAttribute("type","checkbox"),wt.appendChild(bt),(xt=wt.getElementsByTagName("a")[0]).style.cssText="top:1px",v.getSetAttribute="t"!==wt.className,v.style=/top/.test(xt.getAttribute("style")),v.hrefNormalized="/a"===xt.getAttribute("href"),v.checkOn=!!bt.value,v.optSelected=Ct.selected,v.enctype=!!h.createElement("form").enctype,Tt.disabled=!0,v.optDisabled=!Ct.disabled,(bt=h.createElement("input")).setAttribute("value",""),v.input=""===bt.getAttribute("value"),bt.value="t",bt.setAttribute("type","radio"),v.radioValue="t"===bt.value;var Lt=/\r/g;E.fn.extend({val:function(n){var r,e,i,t=this[0];return arguments.length?(i=E.isFunction(n),this.each(function(e){var t;1===this.nodeType&&(null==(t=i?n.call(this,e,E(this).val()):n)?t="":"number"==typeof t?t+="":E.isArray(t)&&(t=E.map(t,function(e){return null==e?"":e+""})),(r=E.valHooks[this.type]||E.valHooks[this.nodeName.toLowerCase()])&&"set"in r&&void 0!==r.set(this,t,"value")||(this.value=t))})):t?(r=E.valHooks[t.type]||E.valHooks[t.nodeName.toLowerCase()])&&"get"in r&&void 0!==(e=r.get(t,"value"))?e:"string"==typeof(e=t.value)?e.replace(Lt,""):null==e?"":e:void 0}}),E.extend({valHooks:{option:{get:function(e){var t=E.find.attr(e,"value");return null!=t?t:E.trim(E.text(e))}},select:{get:function(e){for(var t,n,r=e.options,i=e.selectedIndex,o="select-one"===e.type||i<0,a=o?null:[],s=o?i+1:r.length,u=i<0?s:o?i:0;u<s;u++)if(((n=r[u]).selected||u===i)&&(v.optDisabled?!n.disabled:null===n.getAttribute("disabled"))&&(!n.parentNode.disabled||!E.nodeName(n.parentNode,"optgroup"))){if(t=E(n).val(),o)return t;a.push(t)}return a},set:function(e,t){for(var n,r,i=e.options,o=E.makeArray(t),a=i.length;a--;)if(r=i[a],0<=E.inArray(E.valHooks.option.get(r),o))try{r.selected=n=!0}catch(e){r.scrollHeight}else r.selected=!1;return n||(e.selectedIndex=-1),i}}}}),E.each(["radio","checkbox"],function(){E.valHooks[this]={set:function(e,t){if(E.isArray(t))return e.checked=-1<E.inArray(E(e).val(),t)}},v.checkOn||(E.valHooks[this].get=function(e){return null===e.getAttribute("value")?"on":e.value})});var jt,Ht,qt=E.expr.attrHandle,_t=/^(?:checked|selected)$/i,Mt=v.getSetAttribute,Ft=v.input;E.fn.extend({attr:function(e,t){return K(this,E.attr,e,t,1<arguments.length)},removeAttr:function(e){return this.each(function(){E.removeAttr(this,e)})}}),E.extend({attr:function(e,t,n){var r,i,o=e.nodeType;if(3!==o&&8!==o&&2!==o)return void 0===e.getAttribute?E.prop(e,t,n):(1===o&&E.isXMLDoc(e)||(t=t.toLowerCase(),i=E.attrHooks[t]||(E.expr.match.bool.test(t)?Ht:jt)),void 0!==n?null===n?void E.removeAttr(e,t):i&&"set"in i&&void 0!==(r=i.set(e,n,t))?r:(e.setAttribute(t,n+""),n):i&&"get"in i&&null!==(r=i.get(e,t))?r:null==(r=E.find.attr(e,t))?void 0:r)},attrHooks:{type:{set:function(e,t){if(!v.radioValue&&"radio"===t&&E.nodeName(e,"input")){var n=e.value;return e.setAttribute("type",t),n&&(e.value=n),t}}}},removeAttr:function(e,t){var n,r,i=0,o=t&&t.match(q);if(o&&1===e.nodeType)for(;n=o[i++];)r=E.propFix[n]||n,E.expr.match.bool.test(n)?Ft&&Mt||!_t.test(n)?e[r]=!1:e[E.camelCase("default-"+n)]=e[r]=!1:E.attr(e,n,""),e.removeAttribute(Mt?n:r)}}),Ht={set:function(e,t,n){return!1===t?E.removeAttr(e,n):Ft&&Mt||!_t.test(n)?e.setAttribute(!Mt&&E.propFix[n]||n,n):e[E.camelCase("default-"+n)]=e[n]=!0,n}},E.each(E.expr.match.bool.source.match(/\w+/g),function(e,t){var o=qt[t]||E.find.attr;Ft&&Mt||!_t.test(t)?qt[t]=function(e,t,n){var r,i;return n||(i=qt[t],qt[t]=r,r=null!=o(e,t,n)?t.toLowerCase():null,qt[t]=i),r}:qt[t]=function(e,t,n){if(!n)return e[E.camelCase("default-"+t)]?t.toLowerCase():null}}),Ft&&Mt||(E.attrHooks.value={set:function(e,t,n){if(!E.nodeName(e,"input"))return jt&&jt.set(e,t,n);e.defaultValue=t}}),Mt||(jt={set:function(e,t,n){var r=e.getAttributeNode(n);if(r||e.setAttributeNode(r=e.ownerDocument.createAttribute(n)),r.value=t+="","value"===n||t===e.getAttribute(n))return t}},qt.id=qt.name=qt.coords=function(e,t,n){var r;if(!n)return(r=e.getAttributeNode(t))&&""!==r.value?r.value:null},E.valHooks.button={get:function(e,t){var n=e.getAttributeNode(t);if(n&&n.specified)return n.value},set:jt.set},E.attrHooks.contenteditable={set:function(e,t,n){jt.set(e,""!==t&&t,n)}},E.each(["width","height"],function(e,n){E.attrHooks[n]={set:function(e,t){if(""===t)return e.setAttribute(n,"auto"),t}}})),v.style||(E.attrHooks.style={get:function(e){return e.style.cssText||void 0},set:function(e,t){return e.style.cssText=t+""}});var Ot=/^(?:input|select|textarea|button|object)$/i,Rt=/^(?:a|area)$/i;E.fn.extend({prop:function(e,t){return K(this,E.prop,e,t,1<arguments.length)},removeProp:function(e){return e=E.propFix[e]||e,this.each(function(){try{this[e]=void 0,delete this[e]}catch(e){}})}}),E.extend({prop:function(e,t,n){var r,i,o=e.nodeType;if(3!==o&&8!==o&&2!==o)return 1===o&&E.isXMLDoc(e)||(t=E.propFix[t]||t,i=E.propHooks[t]),void 0!==n?i&&"set"in i&&void 0!==(r=i.set(e,n,t))?r:e[t]=n:i&&"get"in i&&null!==(r=i.get(e,t))?r:e[t]},propHooks:{tabIndex:{get:function(e){var t=E.find.attr(e,"tabindex");return t?parseInt(t,10):Ot.test(e.nodeName)||Rt.test(e.nodeName)&&e.href?0:-1}}},propFix:{for:"htmlFor",class:"className"}}),v.hrefNormalized||E.each(["href","src"],function(e,t){E.propHooks[t]={get:function(e){return e.getAttribute(t,4)}}}),v.optSelected||(E.propHooks.selected={get:function(e){var t=e.parentNode;return t&&(t.selectedIndex,t.parentNode&&t.parentNode.selectedIndex),null}}),E.each(["tabIndex","readOnly","maxLength","cellSpacing","cellPadding","rowSpan","colSpan","useMap","frameBorder","contentEditable"],function(){E.propFix[this.toLowerCase()]=this}),v.enctype||(E.propFix.enctype="encoding");var Pt=/[\t\r\n\f]/g;function Bt(e){return E.attr(e,"class")||""}E.fn.extend({addClass:function(t){var e,n,r,i,o,a,s,u=0;if(E.isFunction(t))return this.each(function(e){E(this).addClass(t.call(this,e,Bt(this)))});if("string"==typeof t&&t)for(e=t.match(q)||[];n=this[u++];)if(i=Bt(n),r=1===n.nodeType&&(" "+i+" ").replace(Pt," ")){for(a=0;o=e[a++];)r.indexOf(" "+o+" ")<0&&(r+=o+" ");i!==(s=E.trim(r))&&E.attr(n,"class",s)}return this},removeClass:function(t){var e,n,r,i,o,a,s,u=0;if(E.isFunction(t))return this.each(function(e){E(this).removeClass(t.call(this,e,Bt(this)))});if(!arguments.length)return this.attr("class","");if("string"==typeof t&&t)for(e=t.match(q)||[];n=this[u++];)if(i=Bt(n),r=1===n.nodeType&&(" "+i+" ").replace(Pt," ")){for(a=0;o=e[a++];)for(;-1<r.indexOf(" "+o+" ");)r=r.replace(" "+o+" "," ");i!==(s=E.trim(r))&&E.attr(n,"class",s)}return this},toggleClass:function(i,t){var o=typeof i;return"boolean"==typeof t&&"string"==o?t?this.addClass(i):this.removeClass(i):E.isFunction(i)?this.each(function(e){E(this).toggleClass(i.call(this,e,Bt(this),t),t)}):this.each(function(){var e,t,n,r;if("string"==o)for(t=0,n=E(this),r=i.match(q)||[];e=r[t++];)n.hasClass(e)?n.removeClass(e):n.addClass(e);else void 0!==i&&"boolean"!=o||((e=Bt(this))&&E._data(this,"__className__",e),E.attr(this,"class",e||!1===i?"":E._data(this,"__className__")||""))})},hasClass:function(e){var t,n,r=0;for(t=" "+e+" ";n=this[r++];)if(1===n.nodeType&&-1<(" "+Bt(n)+" ").replace(Pt," ").indexOf(t))return!0;return!1}}),E.each("blur focus focusin focusout load resize scroll unload click dblclick mousedown mouseup mousemove mouseover mouseout mouseenter mouseleave change select submit keydown keypress keyup error contextmenu".split(" "),function(e,n){E.fn[n]=function(e,t){return 0<arguments.length?this.on(n,null,e,t):this.trigger(n)}}),E.fn.extend({hover:function(e,t){return this.mouseenter(e).mouseleave(t||e)}});var Wt=C.location,It=E.now(),$t=/\?/,zt=/(,)|(\[|{)|(}|])|"(?:[^"\\\r\n]|\\["\\\/bfnrt]|\\u[\da-fA-F]{4})*"\s*:?|true|false|null|-?(?!0\d)\d+(?:\.\d+|)(?:[eE][+-]?\d+|)/g;E.parseJSON=function(e){if(C.JSON&&C.JSON.parse)return C.JSON.parse(e+"");var i,o=null,t=E.trim(e+"");return t&&!E.trim(t.replace(zt,function(e,t,n,r){return i&&t&&(o=0),0===o?e:(i=n||t,o+=!r-!n,"")}))?Function("return "+t)():E.error("Invalid JSON: "+e)},E.parseXML=function(e){var t;if(!e||"string"!=typeof e)return null;try{C.DOMParser?t=(new C.DOMParser).parseFromString(e,"text/xml"):((t=new C.ActiveXObject("Microsoft.XMLDOM")).async="false",t.loadXML(e))}catch(e){t=void 0}return t&&t.documentElement&&!t.getElementsByTagName("parsererror").length||E.error("Invalid XML: "+e),t};var Xt=/#.*$/,Ut=/([?&])_=[^&]*/,Vt=/^(.*?):[ \t]*([^\r\n]*)\r?$/gm,Yt=/^(?:GET|HEAD)$/,Jt=/^\/\//,Gt=/^([\w.+-]+:)(?:\/\/(?:[^\/?#]*@|)([^\/?#:]*)(?::(\d+)|)|)/,Qt={},Kt={},Zt="*/".concat("*"),en=Wt.href,tn=Gt.exec(en.toLowerCase())||[];function nn(o){return function(e,t){"string"!=typeof e&&(t=e,e="*");var n,r=0,i=e.toLowerCase().match(q)||[];if(E.isFunction(t))for(;n=i[r++];)"+"===n.charAt(0)?(n=n.slice(1)||"*",(o[n]=o[n]||[]).unshift(t)):(o[n]=o[n]||[]).push(t)}}function rn(t,i,o,a){var s={},u=t===Kt;function l(e){var r;return s[e]=!0,E.each(t[e]||[],function(e,t){var n=t(i,o,a);return"string"!=typeof n||u||s[n]?u?!(r=n):void 0:(i.dataTypes.unshift(n),l(n),!1)}),r}return l(i.dataTypes[0])||!s["*"]&&l("*")}function on(e,t){var n,r,i=E.ajaxSettings.flatOptions||{};for(r in t)void 0!==t[r]&&((i[r]?e:n=n||{})[r]=t[r]);return n&&E.extend(!0,e,n),e}E.extend({active:0,lastModified:{},etag:{},ajaxSettings:{url:en,type:"GET",isLocal:/^(?:about|app|app-storage|.+-extension|file|res|widget):$/.test(tn[1]),global:!0,processData:!0,async:!0,contentType:"application/x-www-form-urlencoded; charset=UTF-8",accepts:{"*":Zt,text:"text/plain",html:"text/html",xml:"application/xml, text/xml",json:"application/json, text/javascript"},contents:{xml:/\bxml\b/,html:/\bhtml/,json:/\bjson\b/},responseFields:{xml:"responseXML",text:"responseText",json:"responseJSON"},converters:{"* text":String,"text html":!0,"text json":E.parseJSON,"text xml":E.parseXML},flatOptions:{url:!0,context:!0}},ajaxSetup:function(e,t){return t?on(on(e,E.ajaxSettings),t):on(E.ajaxSettings,e)},ajaxPrefilter:nn(Qt),ajaxTransport:nn(Kt),ajax:function(e,t){"object"==typeof e&&(t=e,e=void 0),t=t||{};var n,r,c,f,d,p,h,i,m=E.ajaxSetup({},t),g=m.context||m,v=m.context&&(g.nodeType||g.jquery)?E(g):E.event,y=E.Deferred(),x=E.Callbacks("once memory"),b=m.statusCode||{},o={},a={},w=0,s="canceled",T={readyState:0,getResponseHeader:function(e){var t;if(2===w){if(!i)for(i={};t=Vt.exec(f);)i[t[1].toLowerCase()]=t[2];t=i[e.toLowerCase()]}return null==t?null:t},getAllResponseHeaders:function(){return 2===w?f:null},setRequestHeader:function(e,t){var n=e.toLowerCase();return w||(e=a[n]=a[n]||e,o[e]=t),this},overrideMimeType:function(e){return w||(m.mimeType=e),this},statusCode:function(e){var t;if(e)if(w<2)for(t in e)b[t]=[b[t],e[t]];else T.always(e[T.status]);return this},abort:function(e){var t=e||s;return h&&h.abort(t),u(0,t),this}};if(y.promise(T).complete=x.add,T.success=T.done,T.error=T.fail,m.url=((e||m.url||en)+"").replace(Xt,"").replace(Jt,tn[1]+"//"),m.type=t.method||t.type||m.method||m.type,m.dataTypes=E.trim(m.dataType||"*").toLowerCase().match(q)||[""],null==m.crossDomain&&(n=Gt.exec(m.url.toLowerCase()),m.crossDomain=!(!n||n[1]===tn[1]&&n[2]===tn[2]&&(n[3]||("http:"===n[1]?"80":"443"))===(tn[3]||("http:"===tn[1]?"80":"443")))),m.data&&m.processData&&"string"!=typeof m.data&&(m.data=E.param(m.data,m.traditional)),rn(Qt,m,t,T),2===w)return T;for(r in(p=E.event&&m.global)&&0==E.active++&&E.event.trigger("ajaxStart"),m.type=m.type.toUpperCase(),m.hasContent=!Yt.test(m.type),c=m.url,m.hasContent||(m.data&&(c=m.url+=($t.test(c)?"&":"?")+m.data,delete m.data),!1===m.cache&&(m.url=Ut.test(c)?c.replace(Ut,"$1_="+It++):c+($t.test(c)?"&":"?")+"_="+It++)),m.ifModified&&(E.lastModified[c]&&T.setRequestHeader("If-Modified-Since",E.lastModified[c]),E.etag[c]&&T.setRequestHeader("If-None-Match",E.etag[c])),(m.data&&m.hasContent&&!1!==m.contentType||t.contentType)&&T.setRequestHeader("Content-Type",m.contentType),T.setRequestHeader("Accept",m.dataTypes[0]&&m.accepts[m.dataTypes[0]]?m.accepts[m.dataTypes[0]]+("*"!==m.dataTypes[0]?", "+Zt+"; q=0.01":""):m.accepts["*"]),m.headers)T.setRequestHeader(r,m.headers[r]);if(m.beforeSend&&(!1===m.beforeSend.call(g,T,m)||2===w))return T.abort();for(r in s="abort",{success:1,error:1,complete:1})T[r](m[r]);if(h=rn(Kt,m,t,T)){if(T.readyState=1,p&&v.trigger("ajaxSend",[T,m]),2===w)return T;m.async&&0<m.timeout&&(d=C.setTimeout(function(){T.abort("timeout")},m.timeout));try{w=1,h.send(o,u)}catch(e){if(!(w<2))throw e;u(-1,e)}}else u(-1,"No Transport");function u(e,t,n,r){var i,o,a,s,u,l=t;2!==w&&(w=2,d&&C.clearTimeout(d),h=void 0,f=r||"",T.readyState=0<e?4:0,i=200<=e&&e<300||304===e,n&&(s=function(e,t,n){for(var r,i,o,a,s=e.contents,u=e.dataTypes;"*"===u[0];)u.shift(),void 0===i&&(i=e.mimeType||t.getResponseHeader("Content-Type"));if(i)for(a in s)if(s[a]&&s[a].test(i)){u.unshift(a);break}if(u[0]in n)o=u[0];else{for(a in n){if(!u[0]||e.converters[a+" "+u[0]]){o=a;break}r=r||a}o=o||r}if(o)return o!==u[0]&&u.unshift(o),n[o]}(m,T,n)),s=function(e,t,n,r){var i,o,a,s,u,l={},c=e.dataTypes.slice();if(c[1])for(a in e.converters)l[a.toLowerCase()]=e.converters[a];for(o=c.shift();o;)if(e.responseFields[o]&&(n[e.responseFields[o]]=t),!u&&r&&e.dataFilter&&(t=e.dataFilter(t,e.dataType)),u=o,o=c.shift())if("*"===o)o=u;else if("*"!==u&&u!==o){if(!(a=l[u+" "+o]||l["* "+o]))for(i in l)if((s=i.split(" "))[1]===o&&(a=l[u+" "+s[0]]||l["* "+s[0]])){!0===a?a=l[i]:!0!==l[i]&&(o=s[0],c.unshift(s[1]));break}if(!0!==a)if(a&&e.throws)t=a(t);else try{t=a(t)}catch(e){return{state:"parsererror",error:a?e:"No conversion from "+u+" to "+o}}}return{state:"success",data:t}}(m,s,T,i),i?(m.ifModified&&((u=T.getResponseHeader("Last-Modified"))&&(E.lastModified[c]=u),(u=T.getResponseHeader("etag"))&&(E.etag[c]=u)),204===e||"HEAD"===m.type?l="nocontent":304===e?l="notmodified":(l=s.state,o=s.data,i=!(a=s.error))):(a=l,!e&&l||(l="error",e<0&&(e=0))),T.status=e,T.statusText=(t||l)+"",i?y.resolveWith(g,[o,l,T]):y.rejectWith(g,[T,l,a]),T.statusCode(b),b=void 0,p&&v.trigger(i?"ajaxSuccess":"ajaxError",[T,m,i?o:a]),x.fireWith(g,[T,l]),p&&(v.trigger("ajaxComplete",[T,m]),--E.active||E.event.trigger("ajaxStop")))}return T},getJSON:function(e,t,n){return E.get(e,t,n,"json")},getScript:function(e,t){return E.get(e,void 0,t,"script")}}),E.each(["get","post"],function(e,i){E[i]=function(e,t,n,r){return E.isFunction(t)&&(r=r||n,n=t,t=void 0),E.ajax(E.extend({url:e,type:i,dataType:r,data:t,success:n},E.isPlainObject(e)&&e))}}),E._evalUrl=function(e){return E.ajax({url:e,type:"GET",dataType:"script",cache:!0,async:!1,global:!1,throws:!0})},E.fn.extend({wrapAll:function(t){if(E.isFunction(t))return this.each(function(e){E(this).wrapAll(t.call(this,e))});if(this[0]){var e=E(t,this[0].ownerDocument).eq(0).clone(!0);this[0].parentNode&&e.insertBefore(this[0]),e.map(function(){for(var e=this;e.firstChild&&1===e.firstChild.nodeType;)e=e.firstChild;return e}).append(this)}return this},wrapInner:function(n){return E.isFunction(n)?this.each(function(e){E(this).wrapInner(n.call(this,e))}):this.each(function(){var e=E(this),t=e.contents();t.length?t.wrapAll(n):e.append(n)})},wrap:function(t){var n=E.isFunction(t);return this.each(function(e){E(this).wrapAll(n?t.call(this,e):t)})},unwrap:function(){return this.parent().each(function(){E.nodeName(this,"body")||E(this).replaceWith(this.childNodes)}).end()}}),E.expr.filters.hidden=function(e){return v.reliableHiddenOffsets()?e.offsetWidth<=0&&e.offsetHeight<=0&&!e.getClientRects().length:function(e){for(;e&&1===e.nodeType;){if("none"===((t=e).style&&t.style.display||E.css(t,"display"))||"hidden"===e.type)return!0;e=e.parentNode}var t;return!1}(e)},E.expr.filters.visible=function(e){return!E.expr.filters.hidden(e)};var an=/%20/g,sn=/\[\]$/,un=/\r?\n/g,ln=/^(?:submit|button|image|reset|file)$/i,cn=/^(?:input|select|textarea|keygen)/i;function fn(n,e,r,i){var t;if(E.isArray(e))E.each(e,function(e,t){r||sn.test(n)?i(n,t):fn(n+"["+("object"==typeof t&&null!=t?e:"")+"]",t,r,i)});else if(r||"object"!==E.type(e))i(n,e);else for(t in e)fn(n+"["+t+"]",e[t],r,i)}E.param=function(e,t){function n(e,t){t=E.isFunction(t)?t():null==t?"":t,i[i.length]=encodeURIComponent(e)+"="+encodeURIComponent(t)}var r,i=[];if(void 0===t&&(t=E.ajaxSettings&&E.ajaxSettings.traditional),E.isArray(e)||e.jquery&&!E.isPlainObject(e))E.each(e,function(){n(this.name,this.value)});else for(r in e)fn(r,e[r],t,n);return i.join("&").replace(an,"+")},E.fn.extend({serialize:function(){return E.param(this.serializeArray())},serializeArray:function(){return this.map(function(){var e=E.prop(this,"elements");return e?E.makeArray(e):this}).filter(function(){var e=this.type;return this.name&&!E(this).is(":disabled")&&cn.test(this.nodeName)&&!ln.test(e)&&(this.checked||!Z.test(e))}).map(function(e,t){var n=E(this).val();return null==n?null:E.isArray(n)?E.map(n,function(e){return{name:t.name,value:e.replace(un,"\r\n")}}):{name:t.name,value:n.replace(un,"\r\n")}}).get()}}),E.ajaxSettings.xhr=void 0!==C.ActiveXObject?function(){return this.isLocal?gn():8<h.documentMode?mn():/^(get|post|head|put|delete|options)$/i.test(this.type)&&mn()||gn()}:mn;var dn=0,pn={},hn=E.ajaxSettings.xhr();function mn(){try{return new C.XMLHttpRequest}catch(e){}}function gn(){try{return new C.ActiveXObject("Microsoft.XMLHTTP")}catch(e){}}C.attachEvent&&C.attachEvent("onunload",function(){for(var e in pn)pn[e](void 0,!0)}),v.cors=!!hn&&"withCredentials"in hn,(hn=v.ajax=!!hn)&&E.ajaxTransport(function(u){var l;if(!u.crossDomain||v.cors)return{send:function(e,o){var t,a=u.xhr(),s=++dn;if(a.open(u.type,u.url,u.async,u.username,u.password),u.xhrFields)for(t in u.xhrFields)a[t]=u.xhrFields[t];for(t in u.mimeType&&a.overrideMimeType&&a.overrideMimeType(u.mimeType),u.crossDomain||e["X-Requested-With"]||(e["X-Requested-With"]="XMLHttpRequest"),e)void 0!==e[t]&&a.setRequestHeader(t,e[t]+"");a.send(u.hasContent&&u.data||null),l=function(e,t){var n,r,i;if(l&&(t||4===a.readyState))if(delete pn[s],l=void 0,a.onreadystatechange=E.noop,t)4!==a.readyState&&a.abort();else{i={},n=a.status,"string"==typeof a.responseText&&(i.text=a.responseText);try{r=a.statusText}catch(e){r=""}n||!u.isLocal||u.crossDomain?1223===n&&(n=204):n=i.text?200:404}i&&o(n,r,i,a.getAllResponseHeaders())},u.async?4===a.readyState?C.setTimeout(l):a.onreadystatechange=pn[s]=l:l()},abort:function(){l&&l(void 0,!0)}}}),E.ajaxPrefilter(function(e){e.crossDomain&&(e.contents.script=!1)}),E.ajaxSetup({accepts:{script:"text/javascript, application/javascript, application/ecmascript, application/x-ecmascript"},contents:{script:/\b(?:java|ecma)script\b/},converters:{"text script":function(e){return E.globalEval(e),e}}}),E.ajaxPrefilter("script",function(e){void 0===e.cache&&(e.cache=!1),e.crossDomain&&(e.type="GET",e.global=!1)}),E.ajaxTransport("script",function(t){if(t.crossDomain){var r,i=h.head||E("head")[0]||h.documentElement;return{send:function(e,n){(r=h.createElement("script")).async=!0,t.scriptCharset&&(r.charset=t.scriptCharset),r.src=t.url,r.onload=r.onreadystatechange=function(e,t){!t&&r.readyState&&!/loaded|complete/.test(r.readyState)||(r.onload=r.onreadystatechange=null,r.parentNode&&r.parentNode.removeChild(r),r=null,t||n(200,"success"))},i.insertBefore(r,i.firstChild)},abort:function(){r&&r.onload(void 0,!0)}}}});var vn=[],yn=/(=)\?(?=&|$)|\?\?/;E.ajaxSetup({jsonp:"callback",jsonpCallback:function(){var e=vn.pop()||E.expando+"_"+It++;return this[e]=!0,e}}),E.ajaxPrefilter("json jsonp",function(e,t,n){var r,i,o,a=!1!==e.jsonp&&(yn.test(e.url)?"url":"string"==typeof e.data&&0===(e.contentType||"").indexOf("application/x-www-form-urlencoded")&&yn.test(e.data)&&"data");if(a||"jsonp"===e.dataTypes[0])return r=e.jsonpCallback=E.isFunction(e.jsonpCallback)?e.jsonpCallback():e.jsonpCallback,a?e[a]=e[a].replace(yn,"$1"+r):!1!==e.jsonp&&(e.url+=($t.test(e.url)?"&":"?")+e.jsonp+"="+r),e.converters["script json"]=function(){return o||E.error(r+" was not called"),o[0]},e.dataTypes[0]="json",i=C[r],C[r]=function(){o=arguments},n.always(function(){void 0===i?E(C).removeProp(r):C[r]=i,e[r]&&(e.jsonpCallback=t.jsonpCallback,vn.push(r)),o&&E.isFunction(i)&&i(o[0]),o=i=void 0}),"script"}),v.createHTMLDocument=function(){if(!h.implementation.createHTMLDocument)return!1;var e=h.implementation.createHTMLDocument("");return e.body.innerHTML="<form></form><form></form>",2===e.body.childNodes.length}(),E.parseHTML=function(e,t,n){if(!e||"string"!=typeof e)return null;"boolean"==typeof t&&(n=t,t=!1),t=t||(v.createHTMLDocument?h.implementation.createHTMLDocument(""):h);var r=w.exec(e),i=!n&&[];return r?[t.createElement(r[1])]:(r=fe([e],t,i),i&&i.length&&E(i).remove(),E.merge([],r.childNodes))};var xn=E.fn.load;function bn(e){return E.isWindow(e)?e:9===e.nodeType&&(e.defaultView||e.parentWindow)}E.fn.load=function(e,t,n){if("string"!=typeof e&&xn)return xn.apply(this,arguments);var r,i,o,a=this,s=e.indexOf(" ");return-1<s&&(r=E.trim(e.slice(s,e.length)),e=e.slice(0,s)),E.isFunction(t)?(n=t,t=void 0):t&&"object"==typeof t&&(i="POST"),0<a.length&&E.ajax({url:e,type:i||"GET",dataType:"html",data:t}).done(function(e){o=arguments,a.html(r?E("<div>").append(E.parseHTML(e)).find(r):e)}).always(n&&function(e,t){a.each(function(){n.apply(a,o||[e.responseText,t,e])})}),this},E.each(["ajaxStart","ajaxStop","ajaxComplete","ajaxError","ajaxSuccess","ajaxSend"],function(e,t){E.fn[t]=function(e){return this.on(t,e)}}),E.expr.filters.animated=function(t){return E.grep(E.timers,function(e){return t===e.elem}).length},E.offset={setOffset:function(e,t,n){var r,i,o,a,s,u,l=E.css(e,"position"),c=E(e),f={};"static"===l&&(e.style.position="relative"),s=c.offset(),o=E.css(e,"top"),u=E.css(e,"left"),i=("absolute"===l||"fixed"===l)&&-1<E.inArray("auto",[o,u])?(a=(r=c.position()).top,r.left):(a=parseFloat(o)||0,parseFloat(u)||0),E.isFunction(t)&&(t=t.call(e,n,E.extend({},s))),null!=t.top&&(f.top=t.top-s.top+a),null!=t.left&&(f.left=t.left-s.left+i),"using"in t?t.using.call(e,f):c.css(f)}},E.fn.extend({offset:function(t){if(arguments.length)return void 0===t?this:this.each(function(e){E.offset.setOffset(this,t,e)});var e,n,r={top:0,left:0},i=this[0],o=i&&i.ownerDocument;return o?(e=o.documentElement,E.contains(e,i)?(void 0!==i.getBoundingClientRect&&(r=i.getBoundingClientRect()),n=bn(o),{top:r.top+(n.pageYOffset||e.scrollTop)-(e.clientTop||0),left:r.left+(n.pageXOffset||e.scrollLeft)-(e.clientLeft||0)}):r):void 0},position:function(){if(this[0]){var e,t,n={top:0,left:0},r=this[0];return"fixed"===E.css(r,"position")?t=r.getBoundingClientRect():(e=this.offsetParent(),t=this.offset(),E.nodeName(e[0],"html")||(n=e.offset()),n.top+=E.css(e[0],"borderTopWidth",!0),n.left+=E.css(e[0],"borderLeftWidth",!0)),{top:t.top-n.top-E.css(r,"marginTop",!0),left:t.left-n.left-E.css(r,"marginLeft",!0)}}},offsetParent:function(){return this.map(function(){for(var e=this.offsetParent;e&&!E.nodeName(e,"html")&&"static"===E.css(e,"position");)e=e.offsetParent;return e||Qe})}}),E.each({scrollLeft:"pageXOffset",scrollTop:"pageYOffset"},function(t,i){var o=/Y/.test(i);E.fn[t]=function(e){return K(this,function(e,t,n){var r=bn(e);if(void 0===n)return r?i in r?r[i]:r.document.documentElement[t]:e[t];r?r.scrollTo(o?E(r).scrollLeft():n,o?n:E(r).scrollTop()):e[t]=n},t,e,arguments.length,null)}}),E.each(["top","left"],function(e,n){E.cssHooks[n]=nt(v.pixelPosition,function(e,t){if(t)return t=et(e,n),Ge.test(t)?E(e).position()[n]+"px":t})}),E.each({Height:"height",Width:"width"},function(o,a){E.each({padding:"inner"+o,content:a,"":"outer"+o},function(r,e){E.fn[e]=function(e,t){var n=arguments.length&&(r||"boolean"!=typeof e),i=r||(!0===e||!0===t?"margin":"border");return K(this,function(e,t,n){var r;return E.isWindow(e)?e.document.documentElement["client"+o]:9===e.nodeType?(r=e.documentElement,Math.max(e.body["scroll"+o],r["scroll"+o],e.body["offset"+o],r["offset"+o],r["client"+o])):void 0===n?E.css(e,t,i):E.style(e,t,n,i)},a,n?e:void 0,n,null)}})}),E.fn.extend({bind:function(e,t,n){return this.on(e,null,t,n)},unbind:function(e,t){return this.off(e,null,t)},delegate:function(e,t,n,r){return this.on(t,e,n,r)},undelegate:function(e,t,n){return 1===arguments.length?this.off(e,"**"):this.off(t,e||"**",n)}}),E.fn.size=function(){return this.length},E.fn.andSelf=E.fn.addBack,"function"==typeof define&&define.amd&&define("jquery",[],function(){return E});var wn=C.jQuery,Tn=C.$;return E.noConflict=function(e){return C.$===E&&(C.$=Tn),e&&C.jQuery===E&&(C.jQuery=wn),E},e||(C.jQuery=C.$=E),E});
+//# sourceMappingURL=jquery-1.12.1.min.map
\ No newline at end of file
diff --git skin/frontend/enterprise/default/js/lib/jquery/noconflict.js skin/frontend/enterprise/default/js/lib/jquery/noconflict.js
new file mode 100644
index 00000000000..cbb3a473b84
--- /dev/null
+++ skin/frontend/enterprise/default/js/lib/jquery/noconflict.js
@@ -0,0 +1,27 @@
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition License
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magentocommerce.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    design
+ * @package     enterprise_default
+ * @copyright   Copyright (c) 2006-2020 Magento, Inc. (http://www.magento.com)
+ * @license     http://www.magento.com/license/enterprise-edition
+ */
+
+// Avoid PrototypeJS conflicts, assign jQuery to $j instead of $
+var $j = jQuery.noConflict();
