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


SUPEE-2619 | EE_1.13.1.0 | v1 | d0a215a139aa5e75d60e42efa1b2661d84fef2be | Tue Dec 10 17:41:31 2013 +0200 | v1.13.1.0..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Catalog/Model/Product.php app/code/core/Mage/Catalog/Model/Product.php
index 3d538e2..7dcf307 100644
--- app/code/core/Mage/Catalog/Model/Product.php
+++ app/code/core/Mage/Catalog/Model/Product.php
@@ -1940,7 +1940,12 @@ class Mage_Catalog_Model_Product extends Mage_Catalog_Model_Abstract
         /* add product custom options data */
         $customOptions = $buyRequest->getOptions();
         if (is_array($customOptions)) {
-            $options->setOptions(array_diff($buyRequest->getOptions(), array('')));
+            foreach ($customOptions as $key => $value) {
+                if ($value === '') {
+                    unset($customOptions[$key]);
+                }
+            }
+            $options->setOptions($customOptions);
         }
 
         /* add product type selected options data */
diff --git app/code/core/Mage/Core/Controller/Varien/Router/Standard.php app/code/core/Mage/Core/Controller/Varien/Router/Standard.php
index b2ebd4a..4500b24 100644
--- app/code/core/Mage/Core/Controller/Varien/Router/Standard.php
+++ app/code/core/Mage/Core/Controller/Varien/Router/Standard.php
@@ -43,7 +43,7 @@ class Mage_Core_Controller_Varien_Router_Standard extends Mage_Core_Controller_V
                 $modules = array((string)$routerConfig->args->module);
                 if ($routerConfig->args->modules) {
                     foreach ($routerConfig->args->modules->children() as $customModule) {
-                        if ($customModule) {
+                        if ((string)$customModule) {
                             if ($before = $customModule->getAttribute('before')) {
                                 $position = array_search($before, $modules);
                                 if ($position === false) {
diff --git app/code/core/Zend/Pdf/FileParserDataSource.php app/code/core/Zend/Pdf/FileParserDataSource.php
new file mode 100644
index 0000000..df5b2c7
--- /dev/null
+++ app/code/core/Zend/Pdf/FileParserDataSource.php
@@ -0,0 +1,189 @@
+<?php
+/**
+ * Zend Framework
+ *
+ * LICENSE
+ *
+ * This source file is subject to the new BSD license that is bundled
+ * with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://framework.zend.com/license/new-bsd
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@zend.com so we can send you a copy immediately.
+ *
+ * @category   Zend
+ * @package    Zend_Pdf
+ * @subpackage FileParser
+ * @copyright  Copyright (c) 2005-2010 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ * @version    $Id: FileParserDataSource.php 20096 2010-01-06 02:05:09Z bkarwin $
+ */
+
+/**
+ * Abstract helper class for {@link Zend_Pdf_FileParser} that provides the
+ * data source for parsing.
+ *
+ * Concrete subclasses allow for parsing of in-memory, filesystem, and other
+ * sources through a common API. These subclasses also take care of error
+ * handling and other mundane tasks.
+ *
+ * Subclasses must implement at minimum {@link __construct()},
+ * {@link __destruct()}, {@link readBytes()}, and {@link readAllBytes()}.
+ * Subclasses should also override {@link moveToOffset()} and
+ * {@link __toString()} as appropriate.
+ *
+ * @package    Zend_Pdf
+ * @subpackage FileParser
+ * @copyright  Copyright (c) 2005-2010 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ */
+abstract class Zend_Pdf_FileParserDataSource
+{
+  /**** Instance Variables ****/
+
+
+    /**
+     * Total size in bytes of the data source.
+     * @var integer
+     */
+    protected $_size = 0;
+
+    /**
+     * Byte offset of the current read position within the data source.
+     * @var integer
+     */
+    protected $_offset = 0;
+
+
+
+  /**** Public Interface ****/
+
+
+  /* Abstract Methods */
+
+    /**
+     * Object destructor. Closes the data source.
+     *
+     * May also perform cleanup tasks such as deleting temporary files.
+     */
+    abstract public function __destruct();
+
+    /**
+     * Returns the specified number of raw bytes from the data source at the
+     * byte offset of the current read position.
+     *
+     * Must advance the read position by the number of bytes read by updating
+     * $this->_offset.
+     *
+     * Throws an exception if there is insufficient data to completely fulfill
+     * the request or if an error occurs.
+     *
+     * @param integer $byteCount Number of bytes to read.
+     * @return string
+     * @throws Zend_Pdf_Exception
+     */
+    abstract public function readBytes($byteCount);
+
+    /**
+     * Returns the entire contents of the data source as a string.
+     *
+     * This method may be called at any time and so must preserve the byte
+     * offset of the read position, both through $this->_offset and whatever
+     * other additional pointers (such as the seek position of a file pointer)
+     * that might be used.
+     *
+     * @return string
+     */
+    abstract public function readAllBytes();
+
+
+  /* Object Magic Methods */
+
+    /**
+     * Returns a description of the object for debugging purposes.
+     *
+     * Subclasses should override this method to provide a more specific
+     * description of the actual object being represented.
+     *
+     * @return string
+     */
+    public function __toString()
+    {
+        return get_class($this);
+    }
+
+
+  /* Accessors */
+
+    /**
+     * Returns the byte offset of the current read position within the data
+     * source.
+     *
+     * @return integer
+     */
+    public function getOffset()
+    {
+        return $this->_offset;
+    }
+
+    /**
+     * Returns the total size in bytes of the data source.
+     *
+     * @return integer
+     */
+    public function getSize()
+    {
+        return $this->_size;
+    }
+
+
+  /* Primitive Methods */
+
+    /**
+     * Moves the current read position to the specified byte offset.
+     *
+     * Throws an exception you attempt to move before the beginning or beyond
+     * the end of the data source.
+     *
+     * If a subclass needs to perform additional tasks (such as performing a
+     * fseek() on a filesystem source), it should do so after calling this
+     * parent method.
+     *
+     * @param integer $offset Destination byte offset.
+     * @throws Zend_Pdf_Exception
+     */
+    public function moveToOffset($offset)
+    {
+        if ($this->_offset == $offset) {
+            return;    // Not moving; do nothing.
+        }
+        if ($offset < 0) {
+            #require_once 'Zend/Pdf/Exception.php';
+            throw new Zend_Pdf_Exception('Attempt to move before start of data source',
+                                         Zend_Pdf_Exception::MOVE_BEFORE_START_OF_FILE);
+        }
+        if ($offset >= $this->_size) {    // Offsets are zero-based.
+            #require_once 'Zend/Pdf/Exception.php';
+            throw new Zend_Pdf_Exception('Attempt to move beyond end of data source',
+                                         Zend_Pdf_Exception::MOVE_BEYOND_END_OF_FILE);
+        }
+        $this->_offset = $offset;
+    }
+
+    /**
+     * Shifts the current read position within the data source by the specified
+     * number of bytes.
+     *
+     * You may move forward (positive numbers) or backward (negative numbers).
+     * Throws an exception you attempt to move before the beginning or beyond
+     * the end of the data source.
+     *
+     * @param integer $byteCount Number of bytes to skip.
+     * @throws Zend_Pdf_Exception
+     */
+    public function skipBytes($byteCount)
+    {
+        $this->moveToOffset($this->_offset + $byteCount);
+    }
+}
