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


SUPEE-3762 | EE_1.14.0.1 | v1 | 3608d69d73a826b371f9893b49ddcb347c9b3f37 | Thu Jun 12 11:08:43 2014 -0700 | v1.14.0.1..HEAD

__PATCHFILE_FOLLOWS__
diff --git lib/Zend/Soap/Server.php lib/Zend/Soap/Server.php
index 046cf23..8458836 100644
--- lib/Zend/Soap/Server.php
+++ lib/Zend/Soap/Server.php
@@ -24,6 +24,12 @@
  */
 #require_once 'Zend/Server/Interface.php';
 
+/** @see Zend_Xml_Security */
+#require_once 'Zend/Xml/Security.php';
+
+/** @see Zend_Xml_Exception */
+#require_once 'Zend/Xml/Exception.php';
+
 /**
  * Zend_Soap_Server
  *
@@ -729,21 +735,18 @@ class Zend_Soap_Server implements Zend_Server_Interface
                 $xml = $request;
             }
 
-            libxml_disable_entity_loader(true);
             $dom = new DOMDocument();
-            if(strlen($xml) == 0 || !$dom->loadXML($xml)) {
-                #require_once 'Zend/Soap/Server/Exception.php';
-                throw new Zend_Soap_Server_Exception('Invalid XML');
-            }
-            foreach ($dom->childNodes as $child) {
-                if ($child->nodeType === XML_DOCUMENT_TYPE_NODE) {
+            try {
+                if(strlen($xml) == 0 || (!$dom = Zend_Xml_Security::scan($xml, $dom))) {
                     #require_once 'Zend/Soap/Server/Exception.php';
-                    throw new Zend_Soap_Server_Exception(
-                        'Invalid XML: Detected use of illegal DOCTYPE'
-                    );
+                    throw new Zend_Soap_Server_Exception('Invalid XML');
                 }
+            } catch (Zend_Xml_Exception $e) {
+                #require_once 'Zend/Soap/Server/Exception.php';
+                throw new Zend_Soap_Server_Exception(
+                    $e->getMessage()
+                );
             }
-            libxml_disable_entity_loader(false);
         }
         $this->_request = $xml;
         return $this;
diff --git lib/Zend/Xml/Exception.php lib/Zend/Xml/Exception.php
new file mode 100644
index 0000000..3418f35
--- /dev/null
+++ lib/Zend/Xml/Exception.php
@@ -0,0 +1,36 @@
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
+ * @package    Zend_Xml
+ * @copyright  Copyright (c) 2005-2014 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ * @version    $Id$
+ */
+
+
+/**
+ * @see Zend_Exception
+ */
+#require_once 'Zend/Exception.php';
+
+
+/**
+ * @category   Zend
+ * @package    Zend_Xml
+ * @copyright  Copyright (c) 2005-2014 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ */
+class Zend_Xml_Exception extends Zend_Exception
+{}
diff --git lib/Zend/Xml/Security.php lib/Zend/Xml/Security.php
new file mode 100644
index 0000000..2c09c73
--- /dev/null
+++ lib/Zend/Xml/Security.php
@@ -0,0 +1,164 @@
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
+ * @package    Zend_Xml
+ * @copyright  Copyright (c) 2005-2014 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ * @version    $Id$
+ */
+
+ 
+/**
+ * @category   Zend
+ * @package    Zend_Xml_SecurityScan
+ * @copyright  Copyright (c) 2005-2014 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ */
+class Zend_Xml_Security
+{
+    const ENTITY_DETECT = 'Detected use of ENTITY in XML, disabled to prevent XXE/XEE attacks';
+
+    /**
+     * Heuristic scan to detect entity in XML
+     *
+     * @param  string $xml
+     * @throws Zend_Xml_Exception
+     */
+    protected static function heuristicScan($xml)
+    {
+        if (strpos($xml, '<!ENTITY') !== false) {
+            #require_once 'Exception.php';
+            throw new Zend_Xml_Exception(self::ENTITY_DETECT);
+        }
+    }
+
+    /**
+     * @param integer $errno
+     * @param string $errstr
+     * @param string $errfile
+     * @param integer $errline
+     * @return bool
+     */
+    public static function loadXmlErrorHandler($errno, $errstr, $errfile, $errline)
+    {
+        if (substr_count($errstr, 'DOMDocument::loadXML()') > 0) {
+            return true;
+        }
+        return false;
+    }
+
+    /**
+     * Scan XML string for potential XXE and XEE attacks
+     *
+     * @param   string $xml
+     * @param   DomDocument $dom
+     * @throws  Zend_Xml_Exception
+     * @return  SimpleXMLElement|DomDocument|boolean
+     */
+    public static function scan($xml, DOMDocument $dom = null)
+    {
+        // If running with PHP-FPM we perform an heuristic scan
+        // We cannot use libxml_disable_entity_loader because of this bug
+        // @see https://bugs.php.net/bug.php?id=64938
+        if (self::isPhpFpm()) {
+            self::heuristicScan($xml);
+        }
+
+        if (null === $dom) {
+            $simpleXml = true;
+            $dom = new DOMDocument();
+        }
+
+        if (!self::isPhpFpm()) {
+            $loadEntities = libxml_disable_entity_loader(true);
+            $useInternalXmlErrors = libxml_use_internal_errors(true);
+        }
+
+        // Load XML with network access disabled (LIBXML_NONET)
+        // error disabled with @ for PHP-FPM scenario
+        set_error_handler(array('Zend_Xml_Security', 'loadXmlErrorHandler'), E_WARNING);
+
+        $result = $dom->loadXml($xml, LIBXML_NONET);
+        restore_error_handler();
+
+        if (!$result) {
+            // Entity load to previous setting
+            if (!self::isPhpFpm()) {
+                libxml_disable_entity_loader($loadEntities);
+                libxml_use_internal_errors($useInternalXmlErrors);
+            }
+            return false;
+        }
+
+        // Scan for potential XEE attacks using ENTITY, if not PHP-FPM
+        if (!self::isPhpFpm()) {
+            foreach ($dom->childNodes as $child) {
+                if ($child->nodeType === XML_DOCUMENT_TYPE_NODE) {
+                    if ($child->entities->length > 0) {
+                        #require_once 'Exception.php';
+                        throw new Zend_Xml_Exception(self::ENTITY_DETECT);
+                    }
+                }
+            }
+        }
+
+        // Entity load to previous setting
+        if (!self::isPhpFpm()) {
+            libxml_disable_entity_loader($loadEntities);
+            libxml_use_internal_errors($useInternalXmlErrors);
+        }
+
+        if (isset($simpleXml)) {
+            $result = simplexml_import_dom($dom);
+            if (!$result instanceof SimpleXMLElement) {
+                return false;
+            }
+            return $result;
+        }
+        return $dom;
+    }
+
+    /**
+     * Scan XML file for potential XXE/XEE attacks
+     *
+     * @param  string $file
+     * @param  DOMDocument $dom
+     * @throws Zend_Xml_Exception
+     * @return SimpleXMLElement|DomDocument
+     */
+    public static function scanFile($file, DOMDocument $dom = null)
+    {
+        if (!file_exists($file)) {
+            #require_once 'Exception.php';
+            throw new Zend_Xml_Exception(
+                "The file $file specified doesn't exist"
+            );
+        }
+        return self::scan(file_get_contents($file), $dom);
+    }
+
+    /**
+     * Return true if PHP is running with PHP-FPM
+     *
+     * @return boolean
+     */
+    public static function isPhpFpm()
+    {
+        if (substr(php_sapi_name(), 0, 3) === 'fpm') {
+            return true;
+        }
+        return false;
+    }
+}
