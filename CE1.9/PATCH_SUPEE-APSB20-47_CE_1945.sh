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


SUPEE-APSB20-47_CE_1945 | CE_1.9.4.5 | v1 | 487ca1733e3f6e18b3e6244390875ea6d165c369 | Wed Aug 19 17:04:11 2020 +0000 | 62622ef08f2a4f51c8c1ecc3c435cbe7db4a6a5e..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Adminhtml/Controller/Action.php app/code/core/Mage/Adminhtml/Controller/Action.php
index 0e26a8a47d..cc16673282 100644
--- app/code/core/Mage/Adminhtml/Controller/Action.php
+++ app/code/core/Mage/Adminhtml/Controller/Action.php
@@ -388,8 +388,8 @@ protected function _validateSecretKey()
             return true;
         }
 
-        if (!($secretKey = $this->getRequest()->getParam(Mage_Adminhtml_Model_Url::SECRET_KEY_PARAM_NAME, null))
-            || $secretKey != Mage::getSingleton('adminhtml/url')->getSecretKey()) {
+        $secretKey = $this->getRequest()->getParam(Mage_Adminhtml_Model_Url::SECRET_KEY_PARAM_NAME, null);
+        if (!$secretKey || !Mage_Core_Helper_Security::compareStrings(Mage::getSingleton('adminhtml/url')->getSecretKey(), $secretKey)) {
             return false;
         }
         return true;
diff --git app/code/core/Mage/Core/Helper/Security.php app/code/core/Mage/Core/Helper/Security.php
new file mode 100644
index 0000000000..25da188c03
--- /dev/null
+++ app/code/core/Mage/Core/Helper/Security.php
@@ -0,0 +1,45 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category   Mage
+ * @package    Mage_Core
+ * @copyright  Copyright (c) 2020 openmage (https://www.openmage.org/)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Security Helper
+ *
+ * @author      Frank Rochlitzer <f.rochlitzer@b3-it.de>
+ */
+class Mage_Core_Helper_Security
+{
+    /**
+     * Compare two strings in a secure way that avoids string length guessing based on duration of calculation
+     *
+     * @param  string $expected
+     * @param  string $actual
+     * @return bool
+     */
+    public static function compareStrings($expected, $actual)
+    {
+        return Zend_Crypt_Utils::compareStrings($expected, $actual);
+    }
+}
\ No newline at end of file
diff --git app/code/core/Zend/Crypt/Utils.php app/code/core/Zend/Crypt/Utils.php
new file mode 100644
index 0000000000..5565ea7d5f
--- /dev/null
+++ app/code/core/Zend/Crypt/Utils.php
@@ -0,0 +1,68 @@
+<?php
+
+
+/**
+ * @see       https://github.com/laminas/laminas-crypt for the canonical source repository
+ * @copyright https://github.com/laminas/laminas-crypt/blob/master/COPYRIGHT.md
+ * @license   https://github.com/laminas/laminas-crypt/blob/master/LICENSE.md New BSD License
+ *
+ *
+ *
+ * Copyright (c) 2020 Laminas Project a Series of LF Projects, LLC.
+ *
+ * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
+ *
+ * - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
+ * - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
+ * - Neither the name of Laminas Foundation nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
+ *
+ * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
+ * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
+ * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
+ * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
+ * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
+ * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
+ * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
+ */
+
+/**
+ * Tools for cryptography
+ */
+class Zend_Crypt_Utils
+{
+    /**
+     * Compare two strings to avoid timing attacks
+     *
+     * C function memcmp() internally used by PHP, exits as soon as a difference
+     * is found in the two buffers. That makes possible of leaking
+     * timing information useful to an attacker attempting to iteratively guess
+     * the unknown string (e.g. password).
+     * The length will leak.
+     *
+     * @param string $expected
+     * @param string $actual
+     *
+     * @return bool
+     */
+    public static function compareStrings($expected, $actual)
+    {
+        $expected = (string)$expected;
+        $actual = (string)$actual;
+
+        if (function_exists('hash_equals')) {
+            return hash_equals($expected, $actual);
+        }
+
+        $lenExpected = mb_strlen($expected, '8bit');
+        $lenActual = mb_strlen($actual, '8bit');
+        $len = min($lenExpected, $lenActual);
+
+        $result = 0;
+        for ($i = 0; $i < $len; $i++) {
+            $result |= ord($expected[$i]) ^ ord($actual[$i]);
+        }
+        $result |= $lenExpected ^ $lenActual;
+
+        return ($result === 0);
+    }
+}

