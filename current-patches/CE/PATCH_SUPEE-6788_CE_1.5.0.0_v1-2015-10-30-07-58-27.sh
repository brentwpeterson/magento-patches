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


SUPEE-6788 | CE_1.5.0.0 | v1 | 080c3712c03f46fc0b15b15e5b638036787609f3 | Fri Oct 30 09:48:30 2015 +0200 | 575c519

__PATCHFILE_FOLLOWS__
diff --git .htaccess .htaccess
index dadffa2..3ba7edf 100644
--- .htaccess
+++ .htaccess
@@ -176,3 +176,28 @@
 ## http://developer.yahoo.com/performance/rules.html#etags
 
     #FileETag none
+
+###########################################
+## Deny access to cron.php
+    <Files cron.php>
+
+############################################
+## uncomment next lines to enable cron access with base HTTP authorization
+## http://httpd.apache.org/docs/2.2/howto/auth.html
+##
+## Warning: .htpasswd file should be placed somewhere not accessible from the web.
+## This is so that folks cannot download the password file.
+## For example, if your documents are served out of /usr/local/apache/htdocs
+## you might want to put the password file(s) in /usr/local/apache/.
+
+        #AuthName "Cron auth"
+        #AuthUserFile ../.htpasswd
+        #AuthType basic
+        #Require valid-user
+
+############################################
+
+        Order allow,deny
+        Deny from all
+
+    </Files>
diff --git .htaccess.sample .htaccess.sample
index 546f18e..3e79c77 100644
--- .htaccess.sample
+++ .htaccess.sample
@@ -177,3 +177,27 @@
 
     #FileETag none
 
+###########################################
+## Deny access to cron.php
+    <Files cron.php>
+
+############################################
+## uncomment next lines to enable cron access with base HTTP authorization
+## http://httpd.apache.org/docs/2.2/howto/auth.html
+##
+## Warning: .htpasswd file should be placed somewhere not accessible from the web.
+## This is so that folks cannot download the password file.
+## For example, if your documents are served out of /usr/local/apache/htdocs
+## you might want to put the password file(s) in /usr/local/apache/.
+
+        #AuthName "Cron auth"
+        #AuthUserFile ../.htpasswd
+        #AuthType basic
+        #Require valid-user
+
+############################################
+
+        Order allow,deny
+        Deny from all
+
+    </Files>
diff --git app/code/core/Mage/Admin/Model/Block.php app/code/core/Mage/Admin/Model/Block.php
new file mode 100644
index 0000000..db89d7b
--- /dev/null
+++ app/code/core/Mage/Admin/Model/Block.php
@@ -0,0 +1,84 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Admin
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Class Mage_Admin_Model_Block
+ *
+ * @category   Mage
+ * @package    Mage_Adminhtml
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Admin_Model_Block extends Mage_Core_Model_Abstract
+{
+    /**
+     * Initialize variable model
+     */
+    protected function _construct()
+    {
+        $this->_init('admin/block');
+    }
+
+    /**
+     * @return array|bool
+     * @throws Exception
+     * @throws Zend_Validate_Exception
+     */
+    public function validate()
+    {
+        $errors = array();
+
+        if (!Zend_Validate::is($this->getBlockName(), 'NotEmpty')) {
+            $errors[] = Mage::helper('admin')->__('Block Name is required field.');
+        }
+        if (!Zend_Validate::is($this->getBlockName(), 'Regex', array('/^[-_a-zA-Z0-9\/]*$/'))) {
+            $errors[] = Mage::helper('admin')->__('Block Name is incorrect.');
+        }
+
+        if (!in_array($this->getIsAllowed(), array('0', '1'))) {
+            $errors[] = Mage::helper('admin')->__('Is Allowed is required field.');
+        }
+
+        if (empty($errors)) {
+            return true;
+        }
+        return $errors;
+    }
+
+    /**
+     * Check is block with such type allowed for parsinf via blockDirective method
+     *
+     * @param $type
+     * @return int
+     */
+    public function isTypeAllowed($type)
+    {
+        /** @var Mage_Admin_Model_Resource_Block_Collection $collection */
+        $collection = Mage::getResourceModel('admin/block_collection');
+        $collection->addFieldToFilter('block_name', array('eq' => $type))
+            ->addFieldToFilter('is_allowed', array('eq' => 1));
+        return $collection->load()->count();
+    }
+}
diff --git app/code/core/Mage/Admin/Model/Mysql4/Block.php app/code/core/Mage/Admin/Model/Mysql4/Block.php
new file mode 100644
index 0000000..ce86a25
--- /dev/null
+++ app/code/core/Mage/Admin/Model/Mysql4/Block.php
@@ -0,0 +1,44 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Admin
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Class Mage_Admin_Model_Resource_Block
+ *
+ * @category   Mage
+ * @package    Mage_Adminhtml
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Admin_Model_Mysql4_Block extends Mage_Core_Model_Mysql4_Abstract
+{
+    /**
+     * Define main table
+     *
+     */
+    protected function _construct()
+    {
+        $this->_init('admin/permission_block', 'block_id');
+    }
+}
diff --git app/code/core/Mage/Admin/Model/Mysql4/Block/Collection.php app/code/core/Mage/Admin/Model/Mysql4/Block/Collection.php
new file mode 100644
index 0000000..7b8cc0c
--- /dev/null
+++ app/code/core/Mage/Admin/Model/Mysql4/Block/Collection.php
@@ -0,0 +1,44 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Admin
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Admin permissions block collection
+ *
+ * @category   Mage
+ * @package    Mage_Adminhtml
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Admin_Model_Mysql4_Block_Collection extends Mage_Core_Model_Mysql4_Collection_Abstract
+{
+    /**
+     * Define resource model
+     *
+     */
+    protected function _construct()
+    {
+        $this->_init('admin/block');
+    }
+}
diff --git app/code/core/Mage/Admin/Model/Mysql4/Variable.php app/code/core/Mage/Admin/Model/Mysql4/Variable.php
new file mode 100644
index 0000000..82b9811
--- /dev/null
+++ app/code/core/Mage/Admin/Model/Mysql4/Variable.php
@@ -0,0 +1,43 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Admin
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Resource model for manipulate system variables
+ *
+ * @category   Mage
+ * @package    Mage_Admin
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Admin_Model_Mysql4_Variable extends Mage_Core_Model_Mysql4_Abstract
+{
+    /**
+     * Define main table
+     */
+    protected function _construct()
+    {
+        $this->_init('admin/permission_variable', 'variable_id');
+    }
+}
diff --git app/code/core/Mage/Admin/Model/Mysql4/Variable/Collection.php app/code/core/Mage/Admin/Model/Mysql4/Variable/Collection.php
new file mode 100644
index 0000000..bf783f3
--- /dev/null
+++ app/code/core/Mage/Admin/Model/Mysql4/Variable/Collection.php
@@ -0,0 +1,44 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Admin
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Admin permissions variable collection
+ *
+ * @category   Mage
+ * @package    Mage_Admin
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Admin_Model_Mysql4_Variable_Collection extends Mage_Core_Model_Mysql4_Collection_Abstract
+{
+    /**
+     * Define resource model
+     *
+     */
+    protected function _construct()
+    {
+        $this->_init('admin/variable');
+    }
+}
diff --git app/code/core/Mage/Admin/Model/Variable.php app/code/core/Mage/Admin/Model/Variable.php
new file mode 100644
index 0000000..9a8f1bd
--- /dev/null
+++ app/code/core/Mage/Admin/Model/Variable.php
@@ -0,0 +1,80 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Admin
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Class Mage_Admin_Model_Variable
+ */
+class Mage_Admin_Model_Variable extends Mage_Core_Model_Abstract
+{
+    /**
+     * Initialize variable model
+     */
+    protected function _construct()
+    {
+        $this->_init('admin/variable');
+    }
+
+    /**
+     * @return array|bool
+     * @throws Exception
+     * @throws Zend_Validate_Exception
+     */
+    public function validate()
+    {
+        $errors = array();
+
+        if (!Zend_Validate::is($this->getVariableName(), 'NotEmpty')) {
+            $errors[] = Mage::helper('admin')->__('Block Name is required field.');
+        }
+        if (!Zend_Validate::is($this->getVariableName(), 'Regex', array('/^[-_a-zA-Z0-9\/]*$/'))) {
+            $errors[] = Mage::helper('admin')->__('Block Name is incorrect.');
+        }
+
+        if (!in_array($this->getIsAllowed(), array('0', '1'))) {
+            $errors[] = Mage::helper('admin')->__('Is Allowed is required field.');
+        }
+
+        if (empty($errors)) {
+            return true;
+        }
+        return $errors;
+    }
+
+    /**
+     * Check is config directive with given path can be parsed via configDirective method
+     *
+     * @param $path string
+     * @return int
+     */
+    public function isPathAllowed($path)
+    {
+        /** @var Mage_Admin_Model_Resource_Variable_Collection $collection */
+        $collection = Mage::getResourceModel('admin/variable_collection');
+        $collection->addFieldToFilter('variable_name', array('eq' => $path))
+            ->addFieldToFilter('is_allowed', array('eq' => 1));
+        return $collection->load()->count();
+    }
+}
diff --git app/code/core/Mage/Admin/etc/config.xml app/code/core/Mage/Admin/etc/config.xml
index f32cec0..2862d53 100644
--- app/code/core/Mage/Admin/etc/config.xml
+++ app/code/core/Mage/Admin/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
    <modules>
       <Mage_Admin>
-         <version>0.7.2</version>
+         <version>0.7.2.1.2</version>
       </Mage_Admin>
    </modules>
 
@@ -44,6 +44,8 @@
                <user><table>admin_user</table></user>
                <role><table>admin_role</table></role>
                <rule><table>admin_rule</table></rule>
+               <permission_variable><table>permission_variable</table></permission_variable>
+               <permission_block><table>permission_block</table></permission_block>
                <assert><table>admin_assert</table></assert>
             </entities>
          </admin_mysql4>
diff --git app/code/core/Mage/Admin/sql/admin_setup/mysql4-upgrade-0.7.2.1.1-0.7.2.1.2.php app/code/core/Mage/Admin/sql/admin_setup/mysql4-upgrade-0.7.2.1.1-0.7.2.1.2.php
new file mode 100644
index 0000000..9eba84d
--- /dev/null
+++ app/code/core/Mage/Admin/sql/admin_setup/mysql4-upgrade-0.7.2.1.1-0.7.2.1.2.php
@@ -0,0 +1,84 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Admin
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/** @var $installer Mage_Core_Model_Resource_Setup */
+$installer = $this;
+$installer->startSetup();
+
+$tablePermissionVariable = $installer->getTable('admin/permission_variable');
+$tablePermissionBlock = $installer->getTable('admin/permission_block');
+
+$installer->run("
+CREATE TABLE `{$tablePermissionVariable}` (
+  `variable_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Variable ID',
+  `variable_name` varchar(255) NOT NULL DEFAULT '' COMMENT 'Config Path',
+  `is_allowed` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Mark that config can be processed by filters',
+  PRIMARY KEY (`variable_id`,`variable_name`),
+  UNIQUE KEY `UNQ_PERMISSION_VARIABLE_VARIABLE_NAME` (`variable_name`)
+) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='System variables that can be processed via content filter';
+");
+
+$installer->run("
+INSERT INTO `{$tablePermissionVariable}`
+  (`variable_name`, `is_allowed`)
+VALUES
+  ('trans_email/ident_support/name', 1),
+  ('trans_email/ident_support/email', 1),
+  ('web/unsecure/base_url', 1),
+  ('web/secure/base_url', 1),
+  ('trans_email/ident_general/name', 1),
+  ('trans_email/ident_general/email', 1),
+  ('trans_email/ident_sales/name', 1),
+  ('trans_email/ident_sales/email', 1),
+  ('trans_email/ident_custom1/name', 1),
+  ('trans_email/ident_custom1/email', 1),
+  ('trans_email/ident_custom2/name', 1),
+  ('trans_email/ident_custom2/email', 1),
+  ('general/store_information/name', 1),
+  ('general/store_information/phone', 1),
+  ('general/store_information/address', 1);
+");
+
+$installer->run("
+CREATE TABLE `{$tablePermissionBlock}` (
+  `block_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Block ID',
+  `block_name` varchar(255) NOT NULL DEFAULT '' COMMENT 'Block Name',
+  `is_allowed` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Mark that block can be processed by filters',
+  PRIMARY KEY (`block_id`),
+  UNIQUE KEY `UNQ_PERMISSION_BLOCK_BLOCK_NAME` (`block_name`)
+) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='System blocks that can be processed via content filter';
+");
+
+$installer->run("
+INSERT INTO `{$tablePermissionBlock}`
+  (`block_name`, `is_allowed`)
+VALUES
+  ('core/template', 1),
+  ('catalog/product_new', 1),
+  ('enterprise_catalogevent/event_lister', 1);
+");
+
+$installer->endSetup();
diff --git app/code/core/Mage/Adminhtml/Block/Permissions/Block.php app/code/core/Mage/Adminhtml/Block/Permissions/Block.php
new file mode 100644
index 0000000..c096cde
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Block/Permissions/Block.php
@@ -0,0 +1,57 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Adminhtml permissions block
+ *
+ * @category   Mage
+ * @package    Mage_Adminhtml
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Adminhtml_Block_Permissions_Block extends Mage_Adminhtml_Block_Widget_Grid_Container
+{
+    /**
+     * Construct
+     */
+    public function __construct()
+    {
+        $this->_controller = 'permissions_block';
+        $this->_headerText = Mage::helper('adminhtml')->__('Blocks');
+        $this->_addButtonLabel = Mage::helper('adminhtml')->__('Add New Block');
+        parent::__construct();
+    }
+
+    /**
+     * Prepare output HTML
+     *
+     * @return string
+     */
+    protected function _toHtml()
+    {
+        Mage::dispatchEvent('permissions_block_html_before', array('block' => $this));
+        return parent::_toHtml();
+    }
+}
diff --git app/code/core/Mage/Adminhtml/Block/Permissions/Block/Edit.php app/code/core/Mage/Adminhtml/Block/Permissions/Block/Edit.php
new file mode 100644
index 0000000..75cc9ef
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Block/Permissions/Block/Edit.php
@@ -0,0 +1,64 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Adminhtml permissions block edit page
+ *
+ * @category   Mage
+ * @package    Mage_Adminhtml
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Adminhtml_Block_Permissions_Block_Edit extends Mage_Adminhtml_Block_Widget_Form_Container
+{
+    /**
+     * Construct
+     */
+    public function __construct()
+    {
+        $this->_objectId = 'block_id';
+        $this->_controller = 'permissions_block';
+
+        parent::__construct();
+
+        $this->_updateButton('save', 'label', Mage::helper('adminhtml')->__('Save Block'));
+        $this->_updateButton('delete', 'label', Mage::helper('adminhtml')->__('Delete Block'));
+    }
+
+    /**
+     * Return text that to be placed to block header
+     *
+     * @return string
+     */
+    public function getHeaderText()
+    {
+        if (Mage::registry('permissions_block')->getId()) {
+            return Mage::helper('adminhtml')->__("Edit Block '%s'", $this->escapeHtml(Mage::registry('permissions_block')->getBlockName()));
+        }
+        else {
+            return Mage::helper('adminhtml')->__('New block');
+        }
+    }
+}
diff --git app/code/core/Mage/Adminhtml/Block/Permissions/Block/Edit/Form.php app/code/core/Mage/Adminhtml/Block/Permissions/Block/Edit/Form.php
new file mode 100644
index 0000000..8d29480
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Block/Permissions/Block/Edit/Form.php
@@ -0,0 +1,84 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Adminhtml permissions user edit form
+ *
+ * @category   Mage
+ * @package    Mage_Adminhtml
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Adminhtml_Block_Permissions_Block_Edit_Form extends Mage_Adminhtml_Block_Widget_Form
+{
+
+    /**
+     * @return Mage_Adminhtml_Block_Widget_Form
+     * @throws Exception
+     */
+    protected function _prepareForm()
+    {
+        $block = Mage::getModel('admin/block')->load((int) $this->getRequest()->getParam('block_id'));
+
+        $form = new Varien_Data_Form(array(
+            'id' => 'edit_form',
+            'action' => $this->getUrl('*/*/save', array('block_id' => (int) $this->getRequest()->getParam('block_id'))),
+            'method' => 'post'
+        ));
+        $fieldset = $form->addFieldset(
+            'block_details', array('legend' => $this->__('Block Details'))
+        );
+
+        $fieldset->addField('block_name', 'text', array(
+            'label' => $this->__('Block Name'),
+            'required' => true,
+            'name' => 'block_name',
+        ));
+
+
+        $yesno = array(
+            array(
+                'value' => 0,
+                'label' => $this->__('No')
+            ),
+            array(
+                'value' => 1,
+                'label' => $this->__('Yes')
+            ));
+
+
+        $fieldset->addField('is_allowed', 'select', array(
+            'name' => 'is_allowed',
+            'label' => $this->__('Is Allowed'),
+            'title' => $this->__('Is Allowed'),
+            'values' => $yesno,
+        ));
+
+        $form->setUseContainer(true);
+        $form->setValues($block->getData());
+        $this->setForm($form);
+        return parent::_prepareForm();
+    }
+}
diff --git app/code/core/Mage/Adminhtml/Block/Permissions/Block/Grid.php app/code/core/Mage/Adminhtml/Block/Permissions/Block/Grid.php
new file mode 100644
index 0000000..426fd38
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Block/Permissions/Block/Grid.php
@@ -0,0 +1,103 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Adminhtml permissions block grid
+ *
+ * @category   Mage
+ * @package    Mage_Adminhtml
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Adminhtml_Block_Permissions_Block_Grid extends Mage_Adminhtml_Block_Widget_Grid
+{
+    /**
+     * Construct
+     */
+    public function __construct()
+    {
+        parent::__construct();
+        $this->setId('permissionsBlockGrid');
+        $this->setDefaultSort('block_id');
+        $this->setDefaultDir('asc');
+        $this->setUseAjax(true);
+    }
+
+    /**
+     * @return Mage_Adminhtml_Block_Widget_Grid
+     */
+    protected function _prepareCollection()
+    {
+        $collection = Mage::getResourceModel('admin/block_collection');
+        $this->setCollection($collection);
+        return parent::_prepareCollection();
+    }
+
+    /**
+     * @return $this
+     * @throws Exception
+     */
+    protected function _prepareColumns()
+    {
+        $this->addColumn('block_id', array(
+            'header'    => Mage::helper('adminhtml')->__('ID'),
+            'width'     => 5,
+            'align'     => 'right',
+            'sortable'  => true,
+            'index'     => 'block_id'
+        ));
+
+        $this->addColumn('block_name', array(
+            'header'    => Mage::helper('adminhtml')->__('Block Name'),
+            'index'     => 'block_name'
+        ));
+
+        $this->addColumn('is_allowed', array(
+            'header'    => Mage::helper('adminhtml')->__('Status'),
+            'index'     => 'is_allowed',
+            'type'      => 'options',
+            'options'   => array('1' => Mage::helper('adminhtml')->__('Allowed'), '0' => Mage::helper('adminhtml')->__('Not allowed')),
+        ));
+
+        return parent::_prepareColumns();
+    }
+
+    /**
+     * @param $row
+     * @return string
+     */
+    public function getRowUrl($row)
+    {
+        return $this->getUrl('*/*/edit', array('block_id' => $row->getId()));
+    }
+
+    /**
+     * @return string
+     */
+    public function getGridUrl()
+    {
+        return $this->getUrl('*/*/blockGrid', array());
+    }
+}
diff --git app/code/core/Mage/Adminhtml/Block/Permissions/Variable.php app/code/core/Mage/Adminhtml/Block/Permissions/Variable.php
new file mode 100644
index 0000000..37cd6e6
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Block/Permissions/Variable.php
@@ -0,0 +1,57 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Variables block
+ *
+ * @category   Mage
+ * @package    Mage_Adminhtml
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Adminhtml_Block_Permissions_Variable extends Mage_Adminhtml_Block_Widget_Grid_Container
+{
+    /**
+     * Construct
+     */
+    public function __construct()
+    {
+        $this->_controller = 'permissions_variable';
+        $this->_headerText = Mage::helper('adminhtml')->__('Variables');
+        $this->_addButtonLabel = Mage::helper('adminhtml')->__('Add new variable');
+        parent::__construct();
+    }
+
+    /**
+     * Prepare output HTML
+     *
+     * @return string
+     */
+    protected function _toHtml()
+    {
+        Mage::dispatchEvent('permissions_variable_html_before', array('block' => $this));
+        return parent::_toHtml();
+    }
+}
diff --git app/code/core/Mage/Adminhtml/Block/Permissions/Variable/Edit.php app/code/core/Mage/Adminhtml/Block/Permissions/Variable/Edit.php
new file mode 100644
index 0000000..0642944
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Block/Permissions/Variable/Edit.php
@@ -0,0 +1,62 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Adminhtml permissions variable edit page
+ *
+ * @category   Mage
+ * @package    Mage_Adminhtml
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Adminhtml_Block_Permissions_Variable_Edit extends Mage_Adminhtml_Block_Widget_Form_Container
+{
+    /**
+     * Construct
+     */
+    public function __construct()
+    {
+        $this->_objectId = 'variable_id';
+        $this->_controller = 'permissions_variable';
+
+        parent::__construct();
+
+        $this->_updateButton('save', 'label', Mage::helper('adminhtml')->__('Save Variable'));
+        $this->_updateButton('delete', 'label', Mage::helper('adminhtml')->__('Delete Variable'));
+    }
+
+    /**
+     * @return string
+     */
+    public function getHeaderText()
+    {
+        if (Mage::registry('permissions_variable')->getId()) {
+            return Mage::helper('adminhtml')->__("Edit Variable '%s'", $this->escapeHtml(Mage::registry('permissions_variable')->getVariableName()));
+        }
+        else {
+            return Mage::helper('adminhtml')->__('New Variable');
+        }
+    }
+}
diff --git app/code/core/Mage/Adminhtml/Block/Permissions/Variable/Edit/Form.php app/code/core/Mage/Adminhtml/Block/Permissions/Variable/Edit/Form.php
new file mode 100644
index 0000000..0b71406
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Block/Permissions/Variable/Edit/Form.php
@@ -0,0 +1,88 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Adminhtml permissions variable edit form
+ *
+ * @category   Mage
+ * @package    Mage_Adminhtml
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Adminhtml_Block_Permissions_Variable_Edit_Form extends Mage_Adminhtml_Block_Widget_Form
+{
+    /**
+     * @return Mage_Adminhtml_Block_Widget_Form
+     * @throws Exception
+     */
+    protected function _prepareForm()
+    {
+        $block = Mage::getModel('admin/variable')->load((int) $this->getRequest()->getParam('variable_id'));
+
+        $form = new Varien_Data_Form(array(
+            'id' => 'edit_form',
+            'action' => $this->getUrl(
+                '*/*/save',
+                array(
+                    'variable_id' => (int) $this->getRequest()->getParam('variable_id')
+                )
+            ),
+            'method' => 'post'
+        ));
+        $fieldset = $form->addFieldset(
+            'variable_details', array('legend' => $this->__('Variable Details'))
+        );
+
+        $fieldset->addField('variable_name', 'text', array(
+            'label' => $this->__('Variable Name'),
+            'required' => true,
+            'name' => 'variable_name',
+        ));
+
+
+        $yesno = array(
+            array(
+                'value' => 0,
+                'label' => $this->__('No')
+            ),
+            array(
+                'value' => 1,
+                'label' => $this->__('Yes')
+            ));
+
+
+        $fieldset->addField('is_allowed', 'select', array(
+            'name' => 'is_allowed',
+            'label' => $this->__('Is Allowed'),
+            'title' => $this->__('Is Allowed'),
+            'values' => $yesno,
+        ));
+
+        $form->setUseContainer(true);
+        $form->setValues($block->getData());
+        $this->setForm($form);
+        return parent::_prepareForm();
+    }
+}
diff --git app/code/core/Mage/Adminhtml/Block/Permissions/Variable/Grid.php app/code/core/Mage/Adminhtml/Block/Permissions/Variable/Grid.php
new file mode 100644
index 0000000..df186e8
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Block/Permissions/Variable/Grid.php
@@ -0,0 +1,104 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Adminhtml permissions variable grid
+ *
+ * @category   Mage
+ * @package    Mage_Adminhtml
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Adminhtml_Block_Permissions_Variable_Grid extends Mage_Adminhtml_Block_Widget_Grid
+{
+    /**
+     * Construct
+     */
+    public function __construct()
+    {
+        parent::__construct();
+        $this->setId('permissionsVariableGrid');
+        $this->setDefaultSort('variable_id');
+        $this->setDefaultDir('asc');
+        $this->setUseAjax(true);
+    }
+
+    /**
+     * @return Mage_Adminhtml_Block_Widget_Grid
+     */
+    protected function _prepareCollection()
+    {
+        /** @var Mage_Admin_Model_Resource_Variable_Collection $collection */
+        $collection = Mage::getResourceModel('admin/variable_collection');
+        $this->setCollection($collection);
+        return parent::_prepareCollection();
+    }
+
+    /**
+     * @throws Exception
+     */
+    protected function _prepareColumns()
+    {
+        $this->addColumn('variable_id', array(
+            'header'    => Mage::helper('adminhtml')->__('ID'),
+            'width'     => 5,
+            'align'     => 'right',
+            'sortable'  => true,
+            'index'     => 'variable_id'
+        ));
+        $this->addColumn('variable_name', array(
+            'header'    => Mage::helper('adminhtml')->__('Variable'),
+            'index'     => 'variable_name'
+        ));
+        $this->addColumn('is_allowed', array(
+            'header'    => Mage::helper('adminhtml')->__('Status'),
+            'index'     => 'is_allowed',
+            'type'      => 'options',
+            'options'   => array(
+                '1' => Mage::helper('adminhtml')->__('Allowed'),
+                '0' => Mage::helper('adminhtml')->__('Not allowed')),
+            )
+        );
+
+        parent::_prepareColumns();
+    }
+
+    /**
+     * @param $row
+     * @return string
+     */
+    public function getRowUrl($row)
+    {
+        return $this->getUrl('*/*/edit', array('variable_id' => $row->getId()));
+    }
+
+    /**
+     * @return string
+     */
+    public function getGridUrl()
+    {
+        return $this->getUrl('*/*/variableGrid', array());
+    }
+}
diff --git app/code/core/Mage/Adminhtml/controllers/Permissions/BlockController.php app/code/core/Mage/Adminhtml/controllers/Permissions/BlockController.php
new file mode 100644
index 0000000..eb91f85
--- /dev/null
+++ app/code/core/Mage/Adminhtml/controllers/Permissions/BlockController.php
@@ -0,0 +1,216 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Class Mage_Adminhtml_Permissions_BlockController
+ *
+ * @category   Mage
+ * @package    Mage_Adminhtml
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Adminhtml_Permissions_BlockController extends Mage_Adminhtml_Controller_Action
+{
+    /**
+     * @return $this
+     */
+    protected function _initAction()
+    {
+        $this->loadLayout()
+            ->_setActiveMenu('system/acl')
+            ->_addBreadcrumb($this->__('System'), $this->__('System'))
+            ->_addBreadcrumb($this->__('Permissions'), $this->__('Permissions'))
+            ->_addBreadcrumb($this->__('Blocks'), $this->__('Blocks'));
+        return $this;
+    }
+
+    /**
+     * Index action
+     */
+    public function indexAction()
+    {
+        $this->_title($this->__('System'))
+            ->_title($this->__('Permissions'))
+            ->_title($this->__('Blocks'));
+
+        /** @var Mage_Adminhtml_Block_Permissions_Block $block */
+        $block = $this->getLayout()->createBlock('adminhtml/permissions_block');
+        $this->_initAction()
+            ->_addContent($block)
+            ->renderLayout();
+    }
+
+    /**
+     * New action
+     */
+    public function newAction()
+    {
+        $this->_forward('edit');
+    }
+
+    /**
+     * Edit action
+     */
+    public function editAction()
+    {
+        $this->_title($this->__('System'))
+            ->_title($this->__('Permissions'))
+            ->_title($this->__('Blocks'));
+
+        $id = (int) $this->getRequest()->getParam('block_id');
+        $model = Mage::getModel('admin/block');
+
+        if ($id) {
+            $model->load($id);
+            if (! $model->getId()) {
+                Mage::getSingleton('adminhtml/session')->addError($this->__('This block no longer exists.'));
+                $this->_redirect('*/*/');
+                return;
+            }
+        }
+
+        $this->_title($model->getId() ? $model->getBlockName() : $this->__('New Block'));
+
+        // Restore previously entered form data from session
+        $data = Mage::getSingleton('adminhtml/session')->getUserData(true);
+        if (!empty($data)) {
+            $model->setData($data);
+        }
+
+        Mage::register('permissions_block', $model);
+
+        if (isset($id)) {
+            $breadcrumb = $this->__('Edit Block');
+        } else {
+            $breadcrumb = $this->__('New Block');
+        }
+        $this->_initAction()
+            ->_addBreadcrumb($breadcrumb, $breadcrumb);
+
+        $this->getLayout()->getBlock('adminhtml.permissions.block.edit')
+            ->setData('action', $this->getUrl('*/permissions_block/save'));
+
+        $this->renderLayout();
+    }
+
+    /**
+     * Save action
+     *
+     * @return $this|void
+     */
+    public function saveAction()
+    {
+        if ($data = $this->getRequest()->getPost()) {
+            $id = (int) $this->getRequest()->getParam('block_id');
+            $model = Mage::getModel('admin/block')->load($id);
+            if (!$model->getId() && $id) {
+                Mage::getSingleton('adminhtml/session')->addError($this->__('This block no longer exists.'));
+                $this->_redirect('*/*/');
+                return;
+            }
+
+            $model->setData($data);
+            if ($id) {
+                $model->setId($id);
+            }
+            $result = $model->validate();
+
+            if (is_array($result)) {
+                Mage::getSingleton('adminhtml/session')->setUserData($data);
+                foreach ($result as $message) {
+                    Mage::getSingleton('adminhtml/session')->addError($message);
+                }
+                $this->_redirect('*/*/edit', array('block_id' => $id));
+                return $this;
+            }
+            try {
+                $model->save();
+                Mage::getSingleton('adminhtml/session')->addSuccess($this->__('The block has been saved.'));
+                // clear previously saved data from session
+                Mage::getSingleton('adminhtml/session')->setFormData(false);
+
+                $this->_redirect('*/*/');
+                return;
+
+            } catch (Exception $e) {
+                // display error message
+                Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
+                // save data in session
+                Mage::getSingleton('adminhtml/session')->setFormData($data);
+                // redirect to edit form
+                $this->_redirect('*/*/edit', array('block_id' => $id));
+                return;
+            }
+        }
+        $this->_redirect('*/*/');
+    }
+
+    /**
+     * Delete action
+     */
+    public function deleteAction()
+    {
+        $id = (int) $this->getRequest()->getParam('block_id');
+        if ($id) {
+            try {
+                $model = Mage::getModel('admin/block');
+                $model->setId($id);
+                $model->delete();
+                Mage::getSingleton('adminhtml/session')->addSuccess($this->__('Block has been deleted.'));
+                $this->_redirect('*/*/');
+                return;
+            }
+            catch (Exception $e) {
+                Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
+                $this->_redirect('*/*/edit', array('block_id' => $id));
+                return;
+            }
+        }
+        Mage::getSingleton('adminhtml/session')->addError($this->__('Unable to find a block to delete.'));
+        $this->_redirect('*/*/');
+    }
+
+    /**
+     * Grid action
+     */
+    public function blockGridAction()
+    {
+        $this->getResponse()
+            ->setBody($this->getLayout()
+                ->createBlock('adminhtml/permissions_block_grid')
+                ->toHtml()
+            );
+    }
+
+    /**
+     * Check permissions before allow edit list of blocks
+     *
+     * @return bool
+     */
+    protected function _isAllowed()
+    {
+        return Mage::getSingleton('admin/session')->isAllowed('system/acl/blocks');
+    }
+}
diff --git app/code/core/Mage/Adminhtml/controllers/Permissions/VariableController.php app/code/core/Mage/Adminhtml/controllers/Permissions/VariableController.php
new file mode 100644
index 0000000..d8f34ac
--- /dev/null
+++ app/code/core/Mage/Adminhtml/controllers/Permissions/VariableController.php
@@ -0,0 +1,215 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Class Mage_Adminhtml_Permissions_VariableController
+ *
+ * @category   Mage
+ * @package    Mage_Adminhtml
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Adminhtml_Permissions_VariableController extends Mage_Adminhtml_Controller_Action
+{
+    /**
+     * @return $this
+     */
+    protected function _initAction()
+    {
+        $this->loadLayout()
+            ->_setActiveMenu('system/acl')
+            ->_addBreadcrumb($this->__('System'), $this->__('System'))
+            ->_addBreadcrumb($this->__('Permissions'), $this->__('Permissions'))
+            ->_addBreadcrumb($this->__('Variables'), $this->__('Variables'));
+        return $this;
+    }
+
+    /**
+     * Index action
+     */
+    public function indexAction()
+    {
+        $this->_title($this->__('System'))
+            ->_title($this->__('Permissions'))
+            ->_title($this->__('Variables'));
+
+        /** @var Mage_Adminhtml_Block_Permissions_Variables $block */
+        $block = $this->getLayout()->createBlock('adminhtml/permissions_variable');
+        $this->_initAction()
+            ->_addContent($block)
+            ->renderLayout();
+    }
+
+    /**
+     * New action
+     */
+    public function newAction()
+    {
+        $this->_forward('edit');
+    }
+
+    /**
+     * Edit action
+     */
+    public function editAction()
+    {
+        $this->_title($this->__('System'))
+            ->_title($this->__('Permissions'))
+            ->_title($this->__('Variables'));
+
+        $id = (int) $this->getRequest()->getParam('variable_id');
+        $model = Mage::getModel('admin/variable');
+
+        if ($id) {
+            $model->load($id);
+            if (!$model->getId()) {
+                Mage::getSingleton('adminhtml/session')->addError($this->__('This variable no longer exists.'));
+                $this->_redirect('*/*/');
+                return;
+            }
+        }
+
+        $this->_title($model->getId() ? $model->getVariableName() : $this->__('New Variable'));
+
+        // Restore previously entered form data from session
+        $data = Mage::getSingleton('adminhtml/session')->getUserData(true);
+        if (!empty($data)) {
+            $model->setData($data);
+        }
+
+        Mage::register('permissions_variable', $model);
+
+        if (isset($id)) {
+            $breadcrumb = $this->__('Edit Variable');
+        } else {
+            $breadcrumb = $this->__('New Variable');
+        }
+        $this->_initAction()
+            ->_addBreadcrumb($breadcrumb, $breadcrumb);
+
+        $this->getLayout()->getBlock('adminhtml.permissions.variable.edit')
+            ->setData('action', $this->getUrl('*/permissions_variable/save'));
+
+        $this->renderLayout();
+    }
+
+    /**
+     * Save action
+     *
+     * @return $this|void
+     */
+    public function saveAction()
+    {
+        if ($data = $this->getRequest()->getPost()) {
+            $id = (int) $this->getRequest()->getParam('variable_id');
+            $model = Mage::getModel('admin/variable')->load($id);
+            if (!$model->getId() && $id) {
+                Mage::getSingleton('adminhtml/session')->addError($this->__('This variable no longer exists.'));
+                $this->_redirect('*/*/');
+                return;
+            }
+
+            $model->setData($data);
+            if ($id) {
+                $model->setId($id);
+            }
+            $result = $model->validate();
+
+            if (is_array($result)) {
+                Mage::getSingleton('adminhtml/session')->setUserData($data);
+                foreach ($result as $message) {
+                    Mage::getSingleton('adminhtml/session')->addError($message);
+                }
+                $this->_redirect('*/*/edit', array('variable_id' => $id));
+                return $this;
+            }
+            try {
+                $model->save();
+                Mage::getSingleton('adminhtml/session')->addSuccess($this->__('The variable has been saved.'));
+                // clear previously saved data from session
+                Mage::getSingleton('adminhtml/session')->setFormData(false);
+
+                $this->_redirect('*/*/');
+                return;
+
+            } catch (Exception $e) {
+                // display error message
+                Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
+                // save data in session
+                Mage::getSingleton('adminhtml/session')->setFormData($data);
+                // redirect to edit form
+                $this->_redirect('*/*/edit', array('variable_id' => $id));
+                return;
+            }
+        }
+        $this->_redirect('*/*/');
+    }
+
+    /**
+     * Delete action
+     */
+    public function deleteAction()
+    {
+        $id = (int) $this->getRequest()->getParam('variable_id');
+        if ($id) {
+            try {
+                $model = Mage::getModel('admin/variable');
+                $model->setId($id);
+                $model->delete();
+                Mage::getSingleton('adminhtml/session')->addSuccess($this->__('Variable has been deleted.'));
+                $this->_redirect('*/*/');
+                return;
+            } catch (Exception $e) {
+                Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
+                $this->_redirect('*/*/edit', array('variable_id' => $id));
+                return;
+            }
+        }
+        Mage::getSingleton('adminhtml/session')->addError($this->__('Unable to find a variable to delete.'));
+        $this->_redirect('*/*/');
+    }
+
+    /**
+     * Grid action
+     */
+    public function variableGridAction()
+    {
+        $this->getResponse()
+            ->setBody($this->getLayout()
+                ->createBlock('adminhtml/permissions_variable_grid')
+                ->toHtml()
+            );
+    }
+
+    /**
+     * Check permissions before allow edit list of config variables
+     *
+     * @return bool
+     */
+    protected function _isAllowed()
+    {
+        return Mage::getSingleton('admin/session')->isAllowed('system/acl/variables');
+    }
+}
diff --git app/code/core/Mage/Adminhtml/etc/adminhtml.xml app/code/core/Mage/Adminhtml/etc/adminhtml.xml
index 80c7045..5e73eb4 100644
--- app/code/core/Mage/Adminhtml/etc/adminhtml.xml
+++ app/code/core/Mage/Adminhtml/etc/adminhtml.xml
@@ -94,6 +94,14 @@
                             <title>Roles</title>
                             <action>adminhtml/permissions_role</action>
                         </roles>
+                        <variables translate="title">
+                            <title>Variables</title>
+                            <action>adminhtml/permissions_variable</action>
+                        </variables>
+                        <blocks translate="title">
+                            <title>Blocks</title>
+                            <action>adminhtml/permissions_block</action>
+                        </blocks>
                     </children>
                 </acl>
                 <cache translate="title">
@@ -142,6 +150,12 @@
                                         <title>Users</title>
                                         <sort_order>20</sort_order>
                                     </users>
+                                    <variables translate="title">
+                                        <title>Variables</title>
+                                    </variables>
+                                    <blocks translate="title">
+                                        <title>Blocks</title>
+                                    </blocks>
                                 </children>
                             </acl>
                             <store translate="title">
diff --git app/code/core/Mage/Catalog/Model/Product/Option/Type/File.php app/code/core/Mage/Catalog/Model/Product/Option/Type/File.php
index 83d6aec..5b120ef 100644
--- app/code/core/Mage/Catalog/Model/Product/Option/Type/File.php
+++ app/code/core/Mage/Catalog/Model/Product/Option/Type/File.php
@@ -123,17 +123,9 @@ class Mage_Catalog_Model_Product_Option_Type_File extends Mage_Catalog_Model_Pro
          * Check whether we receive uploaded file or restore file by: reorder/edit configuration or
          * previous configuration with no newly uploaded file
          */
-        $fileInfo = null;
-        if (isset($values[$option->getId()]) && is_array($values[$option->getId()])) {
-            // Legacy style, file info comes in array with option id index
-            $fileInfo = $values[$option->getId()];
-        } else {
-            /*
-             * New recommended style - file info comes in request processing parameters and we
-             * sure that this file info originates from Magento, not from manually formed POST request
-             */
-            $fileInfo = $this->_getCurrentConfigFileInfo();
-        }
+
+        $fileInfo = $this->_getCurrentConfigFileInfo();
+
         if ($fileInfo !== null) {
             if (is_array($fileInfo) && $this->_validateFile($fileInfo)) {
                 $value = $fileInfo;
@@ -442,6 +434,11 @@ class Mage_Catalog_Model_Product_Option_Type_File extends Mage_Catalog_Model_Pro
             // Save option in request, because we have no $_FILES['options']
             $requestOptions[$this->getOption()->getId()] = $value;
             $result = serialize($value);
+            try {
+                Mage::helper('core/unserializeArray')->unserialize($result);
+            } catch (Exception $e) {
+                Mage::throwException(Mage::helper('catalog')->__("File options format is not valid."));
+            }
         } else {
             /*
              * Clear option info from request, so it won't be stored in our db upon
@@ -472,7 +469,7 @@ class Mage_Catalog_Model_Product_Option_Type_File extends Mage_Catalog_Model_Pro
     {
         if ($this->_formattedOptionValue === null) {
             try {
-                $value = unserialize($optionValue);
+                $value = Mage::helper('core/unserializeArray')->unserialize($optionValue);
 
                 $customOptionUrlParams = $this->getCustomOptionUrlParams()
                     ? $this->getCustomOptionUrlParams()
@@ -502,7 +499,7 @@ class Mage_Catalog_Model_Product_Option_Type_File extends Mage_Catalog_Model_Pro
     protected function _getOptionHtml($optionValue)
     {
         try {
-            $value = unserialize($optionValue);
+            $value = Mage::helper('core/unserializeArray')->unserialize($value);
         } catch (Exception $e) {
             $value = $optionValue;
         }
@@ -542,7 +539,7 @@ class Mage_Catalog_Model_Product_Option_Type_File extends Mage_Catalog_Model_Pro
     public function getEditableOptionValue($optionValue)
     {
         try {
-            $value = unserialize($optionValue);
+            $value = Mage::helper('core/unserializeArray')->unserialize($optionValue);
             return sprintf('%s [%d]',
                 Mage::helper('core')->htmlEscape($value['title']),
                 $this->getConfigurationItemOption()->getId()
@@ -567,7 +564,6 @@ class Mage_Catalog_Model_Product_Option_Type_File extends Mage_Catalog_Model_Pro
             $confItemOptionId = $matches[1];
             $option = Mage::getModel('sales/quote_item_option')->load($confItemOptionId);
             try {
-                unserialize($option->getValue());
                 return $option->getValue();
             } catch (Exception $e) {
                 return null;
@@ -586,7 +582,7 @@ class Mage_Catalog_Model_Product_Option_Type_File extends Mage_Catalog_Model_Pro
     public function prepareOptionValueForRequest($optionValue)
     {
         try {
-            $result = unserialize($optionValue);
+            $result = Mage::helper('core/unserializeArray')->unserialize($optionValue);
             return $result;
         } catch (Exception $e) {
             return null;
@@ -602,7 +598,7 @@ class Mage_Catalog_Model_Product_Option_Type_File extends Mage_Catalog_Model_Pro
     {
         $quoteOption = $this->getQuoteItemOption();
         try {
-            $value = unserialize($quoteOption->getValue());
+            $value = Mage::helper('core/unserializeArray')->unserialize($quoteOption->getValue());
             if (!isset($value['quote_path'])) {
                 throw new Exception();
             }
diff --git app/code/core/Mage/Core/Controller/Request/Http.php app/code/core/Mage/Core/Controller/Request/Http.php
index 8f79787..cd21305 100644
--- app/code/core/Mage/Core/Controller/Request/Http.php
+++ app/code/core/Mage/Core/Controller/Request/Http.php
@@ -292,11 +292,19 @@ class Mage_Core_Controller_Request_Http extends Zend_Controller_Request_Http
         if (!isset($_SERVER['HTTP_HOST'])) {
             return false;
         }
+        $host = $_SERVER['HTTP_HOST'];
         if ($trimPort) {
-            $host = explode(':', $_SERVER['HTTP_HOST']);
-            return $host[0];
+            $hostParts = explode(':', $_SERVER['HTTP_HOST']);
+            $host =  $hostParts[0];
         }
-        return $_SERVER['HTTP_HOST'];
+
+        if (strpos($host, ',') !== false || strpos($host, ';') !== false) {
+            $response = new Zend_Controller_Response_Http();
+            $response->setHttpResponseCode(400)->sendHeaders();
+            exit();
+        }
+
+        return $host;
     }
 
     /**
diff --git app/code/core/Mage/Core/Controller/Varien/Router/Admin.php app/code/core/Mage/Core/Controller/Varien/Router/Admin.php
index 93b3e44..95df6cc 100644
--- app/code/core/Mage/Core/Controller/Varien/Router/Admin.php
+++ app/code/core/Mage/Core/Controller/Varien/Router/Admin.php
@@ -97,6 +97,27 @@ class Mage_Core_Controller_Varien_Router_Admin extends Mage_Core_Controller_Vari
     }
 
     /**
+     * @param string $frontName
+     * @param mixed $moduleName
+     * @param string $routeName
+     * @return $this
+     */
+    public function addModule($frontName, $moduleName, $routeName)
+    {
+        $isExtensionsCompatibilityMode = (bool)(string)Mage::getConfig()->getNode(
+            'default/admin/security/extensions_compatibility_mode'
+        );
+        $configRouterFrontName = (string)Mage::getConfig()->getNode(
+            'admin/routers/adminhtml/args/frontName'
+        );
+        if ($isExtensionsCompatibilityMode || ($frontName == $configRouterFrontName)) {
+            return parent::addModule($frontName, $moduleName, $routeName);
+        } else {
+            return $this;
+        }
+    }
+
+    /**
      * Check if current controller instance is allowed in current router.
      * 
      * @param Mage_Core_Controller_Varien_Action $controllerInstance
diff --git app/code/core/Mage/Core/Helper/UnserializeArray.php app/code/core/Mage/Core/Helper/UnserializeArray.php
new file mode 100644
index 0000000..2e80ab4
--- /dev/null
+++ app/code/core/Mage/Core/Helper/UnserializeArray.php
@@ -0,0 +1,46 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Core
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Core unserialize helper
+ *
+ * @category    Mage
+ * @package     Mage_Core
+ * @author      Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Core_Helper_UnserializeArray
+{
+    /**
+     * @param string $str
+     * @return array
+     * @throws Exception
+     */
+    public function unserialize($str)
+    {
+        $parser = new Unserialize_Parser();
+        return $parser->unserialize($str);
+    }
+}
diff --git app/code/core/Mage/Core/Model/Email/Template/Filter.php app/code/core/Mage/Core/Model/Email/Template/Filter.php
index 214d5eb..ed9e683 100644
--- app/code/core/Mage/Core/Model/Email/Template/Filter.php
+++ app/code/core/Mage/Core/Model/Email/Template/Filter.php
@@ -65,6 +65,12 @@ class Mage_Core_Model_Email_Template_Filter extends Varien_Filter_Template
 
     protected $_plainTemplateMode = false;
 
+    /** @var Mage_Admin_Model_Variable  */
+    protected $_permissionVariable;
+
+    /** @var Mage_Admin_Model_Block  */
+    protected $_permissionBlock;
+
     /**
      * Setup callbacks for filters
      *
@@ -72,6 +78,8 @@ class Mage_Core_Model_Email_Template_Filter extends Varien_Filter_Template
     public function __construct()
     {
         $this->_modifiers['escape'] = array($this, 'modifierEscape');
+        $this->_permissionVariable = Mage::getModel('admin/variable');
+        $this->_permissionBlock = Mage::getModel('admin/block');
     }
 
     /**
@@ -160,8 +168,10 @@ class Mage_Core_Model_Email_Template_Filter extends Varien_Filter_Template
         $layout = Mage::app()->getLayout();
 
         if (isset($blockParameters['type'])) {
-            $type = $blockParameters['type'];
-            $block = $layout->createBlock($type, null, $blockParameters);
+            if ($this->_permissionBlock->isTypeAllowed($blockParameters['type'])) {
+                $type = $blockParameters['type'];
+                $block = $layout->createBlock($type, null, $blockParameters);
+            }
         } elseif (isset($blockParameters['id'])) {
             $block = $layout->createBlock('cms/block');
             if ($block) {
@@ -461,7 +471,7 @@ class Mage_Core_Model_Email_Template_Filter extends Varien_Filter_Template
         $configValue = '';
         $params = $this->_getIncludeParameters($construction[2]);
         $storeId = $this->getStoreId();
-        if (isset($params['path'])) {
+        if (isset($params['path']) && $this->_permissionVariable->isPathAllowed($params['path'])) {
             $configValue = Mage::getStoreConfig($params['path'], $storeId);
         }
         return $configValue;
diff --git app/code/core/Mage/Core/Model/Resource/Setup.php app/code/core/Mage/Core/Model/Resource/Setup.php
index 3f56603..b5e6d7c 100644
--- app/code/core/Mage/Core/Model/Resource/Setup.php
+++ app/code/core/Mage/Core/Model/Resource/Setup.php
@@ -386,7 +386,6 @@ class Mage_Core_Model_Resource_Setup
                         }
                     }
                 } catch (Exception $e){
-                    echo "<pre>".print_r($e,1)."</pre>";
                     throw Mage::exception('Mage_Core', Mage::helper('core')->__('Error in file: "%s" - %s', $sqlFile, $e->getMessage()));
                 }
                 if (method_exists($this->_conn, 'allowDdlCache')) {
diff --git app/code/core/Mage/Core/etc/config.xml app/code/core/Mage/Core/etc/config.xml
index 479cd7b..7033c38 100644
--- app/code/core/Mage/Core/etc/config.xml
+++ app/code/core/Mage/Core/etc/config.xml
@@ -338,6 +338,7 @@
             </url>
             <security>
                 <use_form_key>1</use_form_key>
+                <extensions_compatibility_mode>1</extensions_compatibility_mode>
             </security>
         </admin>
 
diff --git app/code/core/Mage/Core/etc/system.xml app/code/core/Mage/Core/etc/system.xml
index c09e982..ce26e59 100644
--- app/code/core/Mage/Core/etc/system.xml
+++ app/code/core/Mage/Core/etc/system.xml
@@ -997,6 +997,16 @@
                             <show_in_website>0</show_in_website>
                             <show_in_store>0</show_in_store>
                         </session_cookie_lifetime>
+                        <extensions_compatibility_mode translate="label comment">
+                            <label>Admin routing compatibility mode for extensions</label>
+                            <comment>Enabling this setting increases risk of automated attacks against admin functionality.</comment>
+                            <frontend_type>select</frontend_type>
+                            <sort_order>6</sort_order>
+                            <source_model>adminhtml/system_config_source_enabledisable</source_model>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>0</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </extensions_compatibility_mode>
                     </fields>
                 </security>
                 <dashboard translate="label">
diff --git app/code/core/Mage/Customer/controllers/AccountController.php app/code/core/Mage/Customer/controllers/AccountController.php
index 844f75c..5a039df 100644
--- app/code/core/Mage/Customer/controllers/AccountController.php
+++ app/code/core/Mage/Customer/controllers/AccountController.php
@@ -241,12 +241,17 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
      */
     public function createPostAction()
     {
+        if (!$this->_validateFormKey()) {
+            $this->_redirectError(Mage::getUrl('*/*/create', array('_secure' => true)));
+            return;
+        }
+
         $session = $this->_getSession();
         if ($session->isLoggedIn()) {
             $this->_redirect('*/*/');
             return;
         }
-        $session->setEscapeMessages(true); // prevent XSS injection in user input
+
         if ($this->getRequest()->isPost()) {
             $errors = array();
 
@@ -330,7 +335,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                     $session->setCustomerFormData($this->getRequest()->getPost());
                     if (is_array($errors)) {
                         foreach ($errors as $errorMessage) {
-                            $session->addError($errorMessage);
+                            $session->addError(Mage::helper('core')->escapeHtml($errorMessage));
                         }
                     } else {
                         $session->addError($this->__('Invalid customer data'));
@@ -341,9 +346,8 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                 if ($e->getCode() === Mage_Customer_Model_Customer::EXCEPTION_EMAIL_EXISTS) {
                     $url = Mage::getUrl('customer/account/forgotpassword');
                     $message = $this->__('There is already an account with this email address. If you are sure that it is your email address, <a href="%s">click here</a> to get your password and access your account.', $url);
-                    $session->setEscapeMessages(false);
                 } else {
-                    $message = $e->getMessage();
+                    $message = Mage::helper('core')->escapeHtml($e->getMessage());
                 }
                 $session->addError($message);
             } catch (Exception $e) {
diff --git app/code/core/Mage/Downloadable/Model/Product/Type.php app/code/core/Mage/Downloadable/Model/Product/Type.php
index 274d9f8..efbb1f2 100644
--- app/code/core/Mage/Downloadable/Model/Product/Type.php
+++ app/code/core/Mage/Downloadable/Model/Product/Type.php
@@ -178,6 +178,10 @@ class Mage_Downloadable_Model_Product_Type extends Mage_Catalog_Model_Product_Ty
                             unset($sampleItem['file']);
                         }
 
+                        if (isset($sampleItem['sample_url'])) {
+                            $sampleItem['sample_url'] = Mage::helper('core')->escapeUrl($sampleItem['sample_url']);
+                        }
+
                         $sampleModel->setData($sampleItem)
                             ->setSampleType($sampleItem['type'])
                             ->setProductId($product->getId())
@@ -220,6 +224,9 @@ class Mage_Downloadable_Model_Product_Type extends Mage_Catalog_Model_Product_Ty
                             $sample = $linkItem['sample'];
                             unset($linkItem['sample']);
                         }
+                        if (isset($linkItem['link_url'])) {
+                            $linkItem['link_url'] = Mage::helper('core')->escapeUrl($linkItem['link_url']);
+                        }
                         $linkModel = Mage::getModel('downloadable/link')
                             ->setData($linkItem)
                             ->setLinkType($linkItem['type'])
@@ -236,7 +243,7 @@ class Mage_Downloadable_Model_Product_Type extends Mage_Catalog_Model_Product_Ty
                         $sampleFile = array();
                         if ($sample && isset($sample['type'])) {
                             if ($sample['type'] == 'url' && $sample['url'] != '') {
-                                $linkModel->setSampleUrl($sample['url']);
+                                $linkModel->setSampleUrl(Mage::helper('core')->escapeUrl($sample['url']));
                             }
                             $linkModel->setSampleType($sample['type']);
                             $sampleFile = Mage::helper('core')->jsonDecode($sample['file']);
diff --git app/code/core/Mage/Sales/controllers/DownloadController.php app/code/core/Mage/Sales/controllers/DownloadController.php
index 19bd184..34ce059 100644
--- app/code/core/Mage/Sales/controllers/DownloadController.php
+++ app/code/core/Mage/Sales/controllers/DownloadController.php
@@ -48,6 +48,8 @@ class Mage_Sales_DownloadController extends Mage_Core_Controller_Front_Action
                 throw new Exception();
             }
 
+            $this->_validateFilePath($info);
+
             $filePath = Mage::getBaseDir() . $info['order_path'];
             if ((!is_file($filePath) || !is_readable($filePath)) && !$this->_processDatabaseFile($filePath)) {
                 //try get file from quote
@@ -66,6 +68,19 @@ class Mage_Sales_DownloadController extends Mage_Core_Controller_Front_Action
     }
 
     /**
+     * @param array $info
+     * @throws Exception
+     */
+    protected function _validateFilePath($info)
+    {
+        $optionFile = Mage::getModel('catalog/product_option_type_file');
+        $optionStoragePath = $optionFile->getOrderTargetDir(true);
+        if (strpos($info['order_path'], $optionStoragePath) !== 0) {
+            throw new Exception('Unexpected file path');
+        }
+    }
+
+    /**
      * Check file in database storage if needed and place it on file system
      *
      * @param string $filePath
@@ -138,7 +153,7 @@ class Mage_Sales_DownloadController extends Mage_Core_Controller_Front_Action
             $this->_forward('noRoute');
         }
         try {
-            $info = unserialize($option->getValue());
+            $info = Mage::helper('core/unserializeArray')->unserialize($option->getValue());
             $this->_downloadFileAction($info);
         } catch (Exception $e) {
             $this->_forward('noRoute');
diff --git app/code/core/Zend/Soap/Server.php app/code/core/Zend/Soap/Server.php
new file mode 100644
index 0000000..19259c5
--- /dev/null
+++ app/code/core/Zend/Soap/Server.php
@@ -0,0 +1,1022 @@
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
+ * @package    Zend_Soap
+ * @subpackage Server
+ * @copyright  Copyright (c) 2005-2014 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ */
+
+/**
+ * @see Zend_Server_Interface
+ */
+#require_once 'Zend/Server/Interface.php';
+
+/** @see Zend_Xml_Security */
+#require_once 'Zend/Xml/Security.php';
+
+/** @see Zend_Xml_Exception */
+#require_once 'Zend/Xml/Exception.php';
+
+/**
+ * Zend_Soap_Server
+ *
+ * @category   Zend
+ * @package    Zend_Soap
+ * @subpackage Server
+ * @uses       Zend_Server_Interface
+ * @copyright  Copyright (c) 2005-2014 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ * @version    $Id$
+ */
+class Zend_Soap_Server implements Zend_Server_Interface
+{
+    /**
+     * Actor URI
+     * @var string URI
+     */
+    protected $_actor;
+
+    /**
+     * Class registered with this server
+     * @var string
+     */
+    protected $_class;
+
+    /**
+     * Arguments to pass to {@link $_class} constructor
+     * @var array
+     */
+    protected $_classArgs = array();
+
+    /**
+     * Object registered with this server
+     */
+    protected $_object;
+
+    /**
+     * Array of SOAP type => PHP class pairings for handling return/incoming values
+     * @var array
+     */
+    protected $_classmap;
+
+    /**
+     * Encoding
+     * @var string
+     */
+    protected $_encoding;
+
+    /**
+     * SOAP Server Features
+     *
+     * @var int
+     */
+    protected $_features;
+
+    /**
+     * WSDL Caching Options of SOAP Server
+     *
+     * @var mixed
+     */
+    protected $_wsdlCache;
+
+    /**
+     * WS-I compliant
+     * 
+     * @var boolean 
+     */
+    protected $_wsiCompliant;
+    
+    /**
+     * Registered fault exceptions
+     * @var array
+     */
+    protected $_faultExceptions = array();
+
+    /**
+     * Functions registered with this server; may be either an array or the SOAP_FUNCTIONS_ALL
+     * constant
+     * @var array|int
+     */
+    protected $_functions = array();
+
+    /**
+     * Persistence mode; should be one of the SOAP persistence constants
+     * @var int
+     */
+    protected $_persistence;
+
+    /**
+     * Request XML
+     * @var string
+     */
+    protected $_request;
+
+    /**
+     * Response XML
+     * @var string
+     */
+    protected $_response;
+
+    /**
+     * Flag: whether or not {@link handle()} should return a response instead
+     * of automatically emitting it.
+     * @var boolean
+     */
+    protected $_returnResponse = false;
+
+    /**
+     * SOAP version to use; SOAP_1_2 by default, to allow processing of headers
+     * @var int
+     */
+    protected $_soapVersion = SOAP_1_2;
+
+    /**
+     * URI or path to WSDL
+     * @var string
+     */
+    protected $_wsdl;
+
+    /**
+     * URI namespace for SOAP server
+     * @var string URI
+     */
+    protected $_uri;
+
+    /**
+     * Constructor
+     *
+     * Sets display_errors INI setting to off (prevent client errors due to bad
+     * XML in response). Registers {@link handlePhpErrors()} as error handler
+     * for E_USER_ERROR.
+     *
+     * If $wsdl is provided, it is passed on to {@link setWsdl()}; if any
+     * options are specified, they are passed on to {@link setOptions()}.
+     *
+     * @param string $wsdl
+     * @param array $options
+     * @return void
+     */
+    public function __construct($wsdl = null, array $options = null)
+    {
+        if (!extension_loaded('soap')) {
+            #require_once 'Zend/Soap/Server/Exception.php';
+            throw new Zend_Soap_Server_Exception('SOAP extension is not loaded.');
+        }
+
+        if (null !== $wsdl) {
+            $this->setWsdl($wsdl);
+        }
+
+        if (null !== $options) {
+            $this->setOptions($options);
+        }
+    }
+
+    /**
+     * Set Options
+     *
+     * Allows setting options as an associative array of option => value pairs.
+     *
+     * @param  array|Zend_Config $options
+     * @return Zend_Soap_Server
+     */
+    public function setOptions($options)
+    {
+        if($options instanceof Zend_Config) {
+            $options = $options->toArray();
+        }
+
+        foreach ($options as $key => $value) {
+            switch ($key) {
+                case 'actor':
+                    $this->setActor($value);
+                    break;
+                case 'classmap':
+                case 'classMap':
+                    $this->setClassmap($value);
+                    break;
+                case 'encoding':
+                    $this->setEncoding($value);
+                    break;
+                case 'soapVersion':
+                case 'soap_version':
+                    $this->setSoapVersion($value);
+                    break;
+                case 'uri':
+                    $this->setUri($value);
+                    break;
+                case 'wsdl':
+                    $this->setWsdl($value);
+                    break;
+                case 'featues':
+                    trigger_error(__METHOD__ . ': the option "featues" is deprecated as of 1.10.x and will be removed with 2.0.0; use "features" instead', E_USER_NOTICE);
+                case 'features':
+                    $this->setSoapFeatures($value);
+                    break;
+                case 'cache_wsdl':
+                    $this->setWsdlCache($value);
+                    break;
+                case 'wsi_compliant':
+                    $this->setWsiCompliant($value);
+                    break;
+                default:
+                    break;
+            }
+        }
+
+        return $this;
+    }
+
+    /**
+     * Return array of options suitable for using with SoapServer constructor
+     *
+     * @return array
+     */
+    public function getOptions()
+    {
+        $options = array();
+        if (null !== $this->_actor) {
+            $options['actor'] = $this->_actor;
+        }
+
+        if (null !== $this->_classmap) {
+            $options['classmap'] = $this->_classmap;
+        }
+
+        if (null !== $this->_encoding) {
+            $options['encoding'] = $this->_encoding;
+        }
+
+        if (null !== $this->_soapVersion) {
+            $options['soap_version'] = $this->_soapVersion;
+        }
+
+        if (null !== $this->_uri) {
+            $options['uri'] = $this->_uri;
+        }
+
+        if (null !== $this->_features) {
+            $options['features'] = $this->_features;
+        }
+
+        if (null !== $this->_wsdlCache) {
+            $options['cache_wsdl'] = $this->_wsdlCache;
+        }
+
+        if (null !== $this->_wsiCompliant) {
+            $options['wsi_compliant'] = $this->_wsiCompliant;
+        }
+        
+        return $options;
+    }
+    /**
+     * Set WS-I compliant
+     * 
+     * @param  boolean $value
+     * @return Zend_Soap_Server 
+     */
+    public function setWsiCompliant($value)
+    {
+        if (is_bool($value)) {
+            $this->_wsiCompliant = $value;
+        }
+        return $this;
+    }
+    /**
+     * Gt WS-I compliant
+     * 
+     * @return boolean
+     */
+    public function getWsiCompliant() 
+    {
+        return $this->_wsiCompliant;
+    }
+    /**
+     * Set encoding
+     *
+     * @param  string $encoding
+     * @return Zend_Soap_Server
+     * @throws Zend_Soap_Server_Exception with invalid encoding argument
+     */
+    public function setEncoding($encoding)
+    {
+        if (!is_string($encoding)) {
+            #require_once 'Zend/Soap/Server/Exception.php';
+            throw new Zend_Soap_Server_Exception('Invalid encoding specified');
+        }
+
+        $this->_encoding = $encoding;
+        return $this;
+    }
+
+    /**
+     * Get encoding
+     *
+     * @return string
+     */
+    public function getEncoding()
+    {
+        return $this->_encoding;
+    }
+
+    /**
+     * Set SOAP version
+     *
+     * @param  int $version One of the SOAP_1_1 or SOAP_1_2 constants
+     * @return Zend_Soap_Server
+     * @throws Zend_Soap_Server_Exception with invalid soap version argument
+     */
+    public function setSoapVersion($version)
+    {
+        if (!in_array($version, array(SOAP_1_1, SOAP_1_2))) {
+            #require_once 'Zend/Soap/Server/Exception.php';
+            throw new Zend_Soap_Server_Exception('Invalid soap version specified');
+        }
+
+        $this->_soapVersion = $version;
+        return $this;
+    }
+
+    /**
+     * Get SOAP version
+     *
+     * @return int
+     */
+    public function getSoapVersion()
+    {
+        return $this->_soapVersion;
+    }
+
+    /**
+     * Check for valid URN
+     *
+     * @param  string $urn
+     * @return true
+     * @throws Zend_Soap_Server_Exception on invalid URN
+     */
+    public function validateUrn($urn)
+    {
+        $scheme = parse_url($urn, PHP_URL_SCHEME);
+        if ($scheme === false || $scheme === null) {
+            #require_once 'Zend/Soap/Server/Exception.php';
+            throw new Zend_Soap_Server_Exception('Invalid URN');
+        }
+
+        return true;
+    }
+
+    /**
+     * Set actor
+     *
+     * Actor is the actor URI for the server.
+     *
+     * @param  string $actor
+     * @return Zend_Soap_Server
+     */
+    public function setActor($actor)
+    {
+        $this->validateUrn($actor);
+        $this->_actor = $actor;
+        return $this;
+    }
+
+    /**
+     * Retrieve actor
+     *
+     * @return string
+     */
+    public function getActor()
+    {
+        return $this->_actor;
+    }
+
+    /**
+     * Set URI
+     *
+     * URI in SoapServer is actually the target namespace, not a URI; $uri must begin with 'urn:'.
+     *
+     * @param  string $uri
+     * @return Zend_Soap_Server
+     * @throws Zend_Soap_Server_Exception with invalid uri argument
+     */
+    public function setUri($uri)
+    {
+        $this->validateUrn($uri);
+        $this->_uri = $uri;
+        return $this;
+    }
+
+    /**
+     * Retrieve URI
+     *
+     * @return string
+     */
+    public function getUri()
+    {
+        return $this->_uri;
+    }
+
+    /**
+     * Set classmap
+     *
+     * @param  array $classmap
+     * @return Zend_Soap_Server
+     * @throws Zend_Soap_Server_Exception for any invalid class in the class map
+     */
+    public function setClassmap($classmap)
+    {
+        if (!is_array($classmap)) {
+            /**
+             * @see Zend_Soap_Server_Exception
+             */
+            #require_once 'Zend/Soap/Server/Exception.php';
+            throw new Zend_Soap_Server_Exception('Classmap must be an array');
+        }
+        foreach ($classmap as $type => $class) {
+            if (!class_exists($class)) {
+                /**
+                 * @see Zend_Soap_Server_Exception
+                 */
+                #require_once 'Zend/Soap/Server/Exception.php';
+                throw new Zend_Soap_Server_Exception('Invalid class in class map');
+            }
+        }
+
+        $this->_classmap = $classmap;
+        return $this;
+    }
+
+    /**
+     * Retrieve classmap
+     *
+     * @return mixed
+     */
+    public function getClassmap()
+    {
+        return $this->_classmap;
+    }
+
+    /**
+     * Set wsdl
+     *
+     * @param string $wsdl  URI or path to a WSDL
+     * @return Zend_Soap_Server
+     */
+    public function setWsdl($wsdl)
+    {
+        $this->_wsdl = $wsdl;
+        return $this;
+    }
+
+    /**
+     * Retrieve wsdl
+     *
+     * @return string
+     */
+    public function getWsdl()
+    {
+        return $this->_wsdl;
+    }
+
+    /**
+     * Set the SOAP Feature options.
+     *
+     * @param  string|int $feature
+     * @return Zend_Soap_Server
+     */
+    public function setSoapFeatures($feature)
+    {
+        $this->_features = $feature;
+        return $this;
+    }
+
+    /**
+     * Return current SOAP Features options
+     *
+     * @return int
+     */
+    public function getSoapFeatures()
+    {
+        return $this->_features;
+    }
+
+    /**
+     * Set the SOAP Wsdl Caching Options
+     *
+     * @param string|int|boolean $caching
+     * @return Zend_Soap_Server
+     */
+    public function setWsdlCache($options)
+    {
+        $this->_wsdlCache = $options;
+        return $this;
+    }
+
+    /**
+     * Get current SOAP Wsdl Caching option
+     */
+    public function getWsdlCache()
+    {
+        return $this->_wsdlCache;
+    }
+
+    /**
+     * Attach a function as a server method
+     *
+     * @param array|string $function Function name, array of function names to attach,
+     * or SOAP_FUNCTIONS_ALL to attach all functions
+     * @param  string $namespace Ignored
+     * @return Zend_Soap_Server
+     * @throws Zend_Soap_Server_Exception on invalid functions
+     */
+    public function addFunction($function, $namespace = '')
+    {
+        // Bail early if set to SOAP_FUNCTIONS_ALL
+        if ($this->_functions == SOAP_FUNCTIONS_ALL) {
+            return $this;
+        }
+
+        if (is_array($function)) {
+            foreach ($function as $func) {
+                if (is_string($func) && function_exists($func)) {
+                    $this->_functions[] = $func;
+                } else {
+                    #require_once 'Zend/Soap/Server/Exception.php';
+                    throw new Zend_Soap_Server_Exception('One or more invalid functions specified in array');
+                }
+            }
+            $this->_functions = array_merge($this->_functions, $function);
+        } elseif (is_string($function) && function_exists($function)) {
+            $this->_functions[] = $function;
+        } elseif ($function == SOAP_FUNCTIONS_ALL) {
+            $this->_functions = SOAP_FUNCTIONS_ALL;
+        } else {
+            #require_once 'Zend/Soap/Server/Exception.php';
+            throw new Zend_Soap_Server_Exception('Invalid function specified');
+        }
+
+        if (is_array($this->_functions)) {
+            $this->_functions = array_unique($this->_functions);
+        }
+
+        return $this;
+    }
+
+    /**
+     * Attach a class to a server
+     *
+     * Accepts a class name to use when handling requests. Any additional
+     * arguments will be passed to that class' constructor when instantiated.
+     *
+     * See {@link setObject()} to set preconfigured object instances as request handlers.
+     *
+     * @param string $class Class Name which executes SOAP Requests at endpoint.
+     * @return Zend_Soap_Server
+     * @throws Zend_Soap_Server_Exception if called more than once, or if class
+     * does not exist
+     */
+    public function setClass($class, $namespace = '', $argv = null)
+    {
+        if (isset($this->_class)) {
+            #require_once 'Zend/Soap/Server/Exception.php';
+            throw new Zend_Soap_Server_Exception('A class has already been registered with this soap server instance');
+        }
+
+        if (!is_string($class)) {
+            #require_once 'Zend/Soap/Server/Exception.php';
+            throw new Zend_Soap_Server_Exception('Invalid class argument (' . gettype($class) . ')');
+        }
+
+        if (!class_exists($class)) {
+            #require_once 'Zend/Soap/Server/Exception.php';
+            throw new Zend_Soap_Server_Exception('Class "' . $class . '" does not exist');
+        }
+
+        $this->_class = $class;
+        if (1 < func_num_args()) {
+            $argv = func_get_args();
+            array_shift($argv);
+            $this->_classArgs = $argv;
+        }
+
+        return $this;
+    }
+
+    /**
+     * Attach an object to a server
+     *
+     * Accepts an instanciated object to use when handling requests.
+     *
+     * @param object $object
+     * @return Zend_Soap_Server
+     */
+    public function setObject($object)
+    {
+        if(!is_object($object)) {
+            #require_once 'Zend/Soap/Server/Exception.php';
+            throw new Zend_Soap_Server_Exception('Invalid object argument ('.gettype($object).')');
+        }
+
+        if(isset($this->_object)) {
+            #require_once 'Zend/Soap/Server/Exception.php';
+            throw new Zend_Soap_Server_Exception('An object has already been registered with this soap server instance');
+        }
+
+        if ($this->_wsiCompliant) {
+            #require_once 'Zend/Soap/Server/Proxy.php';
+            $this->_object = new Zend_Soap_Server_Proxy($object);
+        } else {
+            $this->_object = $object;
+        }    
+
+        return $this;
+    }
+
+    /**
+     * Return a server definition array
+     *
+     * Returns a list of all functions registered with {@link addFunction()},
+     * merged with all public methods of the class set with {@link setClass()}
+     * (if any).
+     *
+     * @access public
+     * @return array
+     */
+    public function getFunctions()
+    {
+        $functions = array();
+        if (null !== $this->_class) {
+            $functions = get_class_methods($this->_class);
+        } elseif (null !== $this->_object) {
+            $functions = get_class_methods($this->_object);
+        }
+
+        return array_merge((array) $this->_functions, $functions);
+    }
+
+    /**
+     * Unimplemented: Load server definition
+     *
+     * @param array $array
+     * @return void
+     * @throws Zend_Soap_Server_Exception Unimplemented
+     */
+    public function loadFunctions($definition)
+    {
+        #require_once 'Zend/Soap/Server/Exception.php';
+        throw new Zend_Soap_Server_Exception('Unimplemented');
+    }
+
+    /**
+     * Set server persistence
+     *
+     * @param int $mode
+     * @return Zend_Soap_Server
+     */
+    public function setPersistence($mode)
+    {
+        if (!in_array($mode, array(SOAP_PERSISTENCE_SESSION, SOAP_PERSISTENCE_REQUEST))) {
+            #require_once 'Zend/Soap/Server/Exception.php';
+            throw new Zend_Soap_Server_Exception('Invalid persistence mode specified');
+        }
+
+        $this->_persistence = $mode;
+        return $this;
+    }
+
+    /**
+     * Get server persistence
+     *
+     * @return Zend_Soap_Server
+     */
+    public function getPersistence()
+    {
+        return $this->_persistence;
+    }
+
+    /**
+     * Set request
+     *
+     * $request may be any of:
+     * - DOMDocument; if so, then cast to XML
+     * - DOMNode; if so, then grab owner document and cast to XML
+     * - SimpleXMLElement; if so, then cast to XML
+     * - stdClass; if so, calls __toString() and verifies XML
+     * - string; if so, verifies XML
+     *
+     * @param DOMDocument|DOMNode|SimpleXMLElement|stdClass|string $request
+     * @return Zend_Soap_Server
+     */
+    protected function _setRequest($request)
+    {
+        if ($request instanceof DOMDocument) {
+            $xml = $request->saveXML();
+        } elseif ($request instanceof DOMNode) {
+            $xml = $request->ownerDocument->saveXML();
+        } elseif ($request instanceof SimpleXMLElement) {
+            $xml = $request->asXML();
+        } elseif (is_object($request) || is_string($request)) {
+            if (is_object($request)) {
+                $xml = $request->__toString();
+            } else {
+                $xml = $request;
+            }
+
+            $dom = new DOMDocument();
+            try {
+                if(strlen($xml) == 0 || (!$dom = Zend_Xml_Security::scan($xml, $dom))) {
+                    #require_once 'Zend/Soap/Server/Exception.php';
+                    throw new Zend_Soap_Server_Exception('Invalid XML');
+                }
+            } catch (Zend_Xml_Exception $e) {
+                #require_once 'Zend/Soap/Server/Exception.php';
+                throw new Zend_Soap_Server_Exception(
+                    $e->getMessage()
+                );
+            }
+        }
+        $this->_request = $xml;
+        return $this;
+    }
+
+    /**
+     * Retrieve request XML
+     *
+     * @return string
+     */
+    public function getLastRequest()
+    {
+        return $this->_request;
+    }
+
+    /**
+     * Set return response flag
+     *
+     * If true, {@link handle()} will return the response instead of
+     * automatically sending it back to the requesting client.
+     *
+     * The response is always available via {@link getResponse()}.
+     *
+     * @param boolean $flag
+     * @return Zend_Soap_Server
+     */
+    public function setReturnResponse($flag)
+    {
+        $this->_returnResponse = ($flag) ? true : false;
+        return $this;
+    }
+
+    /**
+     * Retrieve return response flag
+     *
+     * @return boolean
+     */
+    public function getReturnResponse()
+    {
+        return $this->_returnResponse;
+    }
+
+    /**
+     * Get response XML
+     *
+     * @return string
+     */
+    public function getLastResponse()
+    {
+        return $this->_response;
+    }
+
+    /**
+     * Get SoapServer object
+     *
+     * Uses {@link $_wsdl} and return value of {@link getOptions()} to instantiate
+     * SoapServer object, and then registers any functions or class with it, as
+     * well as peristence.
+     *
+     * @return SoapServer
+     */
+    protected function _getSoap()
+    {
+        $options = $this->getOptions();
+        $server  = new SoapServer($this->_wsdl, $options);
+
+        if (!empty($this->_functions)) {
+            $server->addFunction($this->_functions);
+        }
+
+        if (!empty($this->_class)) {
+            $args = $this->_classArgs;
+            array_unshift($args, $this->_class);
+            if ($this->_wsiCompliant) {
+                #require_once 'Zend/Soap/Server/Proxy.php';
+                array_unshift($args, 'Zend_Soap_Server_Proxy');
+            } 
+            call_user_func_array(array($server, 'setClass'), $args);
+        }
+
+        if (!empty($this->_object)) {
+            $server->setObject($this->_object);
+        }
+
+        if (null !== $this->_persistence) {
+            $server->setPersistence($this->_persistence);
+        }
+
+        return $server;
+    }
+
+    /**
+     * Handle a request
+     *
+     * Instantiates SoapServer object with options set in object, and
+     * dispatches its handle() method.
+     *
+     * $request may be any of:
+     * - DOMDocument; if so, then cast to XML
+     * - DOMNode; if so, then grab owner document and cast to XML
+     * - SimpleXMLElement; if so, then cast to XML
+     * - stdClass; if so, calls __toString() and verifies XML
+     * - string; if so, verifies XML
+     *
+     * If no request is passed, pulls request using php:://input (for
+     * cross-platform compatability purposes).
+     *
+     * @param DOMDocument|DOMNode|SimpleXMLElement|stdClass|string $request Optional request
+     * @return void|string
+     */
+    public function handle($request = null)
+    {
+        if (null === $request) {
+            $request = file_get_contents('php://input');
+        }
+
+        // Set Zend_Soap_Server error handler
+        $displayErrorsOriginalState = $this->_initializeSoapErrorContext();
+
+        $setRequestException = null;
+        /**
+         * @see Zend_Soap_Server_Exception
+         */
+        #require_once 'Zend/Soap/Server/Exception.php';
+        try {
+            $this->_setRequest($request);
+        } catch (Zend_Soap_Server_Exception $e) {
+            $setRequestException = $e;
+        }
+        
+        $soap = $this->_getSoap();
+
+        $fault = false;
+        ob_start();
+        if ($setRequestException instanceof Exception) {
+            // Create SOAP fault message if we've caught a request exception
+            $fault = $this->fault($setRequestException->getMessage(), 'Sender');
+        } else {
+            try {
+                $soap->handle($this->_request);
+            } catch (Exception $e) {
+                $fault = $this->fault($e);
+            }
+        }
+        $this->_response = ob_get_clean();
+
+        // Restore original error handler
+        restore_error_handler();
+        ini_set('display_errors', $displayErrorsOriginalState);
+
+        // Send a fault, if we have one
+        if ($fault) {
+            $soap->fault($fault->faultcode, $fault->faultstring);
+        }
+
+        if (!$this->_returnResponse) {
+            echo $this->_response;
+            return;
+        }
+
+        return $this->_response;
+    }
+
+    /**
+     * Method initalizes the error context that the SOAPServer enviroment will run in.
+     *
+     * @return boolean display_errors original value
+     */
+    protected function _initializeSoapErrorContext()
+    {
+        $displayErrorsOriginalState = ini_get('display_errors');
+        ini_set('display_errors', false);
+        set_error_handler(array($this, 'handlePhpErrors'), E_USER_ERROR);
+        return $displayErrorsOriginalState;
+    }
+
+    /**
+     * Register a valid fault exception
+     *
+     * @param  string|array $class Exception class or array of exception classes
+     * @return Zend_Soap_Server
+     */
+    public function registerFaultException($class)
+    {
+        $this->_faultExceptions = array_merge($this->_faultExceptions, (array) $class);
+        return $this;
+    }
+
+    /**
+     * Deregister a fault exception from the fault exception stack
+     *
+     * @param  string $class
+     * @return boolean
+     */
+    public function deregisterFaultException($class)
+    {
+        if (in_array($class, $this->_faultExceptions, true)) {
+            $index = array_search($class, $this->_faultExceptions);
+            unset($this->_faultExceptions[$index]);
+            return true;
+        }
+
+        return false;
+    }
+
+    /**
+     * Return fault exceptions list
+     *
+     * @return array
+     */
+    public function getFaultExceptions()
+    {
+        return $this->_faultExceptions;
+    }
+
+    /**
+     * Generate a server fault
+     *
+     * Note that the arguments are reverse to those of SoapFault.
+     *
+     * If an exception is passed as the first argument, its message and code
+     * will be used to create the fault object if it has been registered via
+     * {@Link registerFaultException()}.
+     *
+     * @link   http://www.w3.org/TR/soap12-part1/#faultcodes
+     * @param  string|Exception $fault
+     * @param  string $code SOAP Fault Codes
+     * @return SoapFault
+     */
+    public function fault($fault = null, $code = "Receiver")
+    {
+        if ($fault instanceof Exception) {
+            $class = get_class($fault);
+            if (in_array($class, $this->_faultExceptions)) {
+                $message = $fault->getMessage();
+                $eCode   = $fault->getCode();
+                $code    = empty($eCode) ? $code : $eCode;
+            } else {
+                $message = 'Unknown error';
+            }
+        } elseif(is_string($fault)) {
+            $message = $fault;
+        } else {
+            $message = 'Unknown error';
+        }
+
+        $allowedFaultModes = array(
+            'VersionMismatch', 'MustUnderstand', 'DataEncodingUnknown',
+            'Sender', 'Receiver', 'Server'
+        );
+        if(!in_array($code, $allowedFaultModes)) {
+            $code = "Receiver";
+        }
+
+        return new SoapFault($code, $message);
+    }
+
+    /**
+     * Throw PHP errors as SoapFaults
+     *
+     * @param int $errno
+     * @param string $errstr
+     * @param string $errfile
+     * @param int $errline
+     * @param array $errcontext
+     * @return void
+     * @throws SoapFault
+     */
+    public function handlePhpErrors($errno, $errstr, $errfile = null, $errline = null, array $errcontext = null)
+    {
+        throw $this->fault($errstr, "Receiver");
+    }
+}
diff --git app/code/core/Zend/Xml/Exception.php app/code/core/Zend/Xml/Exception.php
new file mode 100644
index 0000000..3418f35
--- /dev/null
+++ app/code/core/Zend/Xml/Exception.php
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
diff --git app/code/core/Zend/Xml/Security.php app/code/core/Zend/Xml/Security.php
new file mode 100644
index 0000000..a3cdbc8
--- /dev/null
+++ app/code/core/Zend/Xml/Security.php
@@ -0,0 +1,488 @@
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
+     * @throws Zend_Xml_Exception If entity expansion or external entity declaration was discovered.
+     */
+    protected static function heuristicScan($xml)
+    {
+        foreach (self::getEntityComparison($xml) as $compare) {
+            if (strpos($xml, $compare) !== false) {
+                throw new Zend_Xml_Exception(self::ENTITY_DETECT);
+            }
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
+     * This method is mainly used to determine whether or not heuristic checks
+     * (vs libxml checks) should be made, due to threading issues in libxml;
+     * under php-fpm, threading becomes a concern.
+     *
+     * However, PHP versions 5.5.22+ and 5.6.6+ contain a patch to the
+     * libxml support in PHP that makes the libxml checks viable; in such
+     * versions, this method will return false to enforce those checks, which
+     * are more strict and accurate than the heuristic checks.
+     *
+     * @return boolean
+     */
+    public static function isPhpFpm()
+    {
+        $isVulnerableVersion = (
+            version_compare(PHP_VERSION, '5.5.22', 'lt')
+            || (
+                version_compare(PHP_VERSION, '5.6', 'gte')
+                && version_compare(PHP_VERSION, '5.6.6', 'lt')
+            )
+        );
+
+        if (substr(php_sapi_name(), 0, 3) === 'fpm' && $isVulnerableVersion) {
+            return true;
+        }
+        return false;
+    }
+
+    /**
+     * Determine and return the string(s) to use for the <!ENTITY comparison.
+     *
+     * @param string $xml
+     * @return string[]
+     */
+    protected static function getEntityComparison($xml)
+    {
+        $encodingMap = self::getAsciiEncodingMap();
+        return array_map(
+            array(__CLASS__, 'generateEntityComparison'),
+            self::detectXmlEncoding($xml, self::detectStringEncoding($xml))
+        );
+    }
+
+    /**
+     * Determine the string encoding.
+     *
+     * Determines string encoding from either a detected BOM or a
+     * heuristic.
+     *
+     * @param string $xml
+     * @return string File encoding
+     */
+    protected static function detectStringEncoding($xml)
+    {
+        $encoding = self::detectBom($xml);
+        return ($encoding) ? $encoding : self::detectXmlStringEncoding($xml);
+    }
+
+    /**
+     * Attempt to match a known BOM.
+     *
+     * Iterates through the return of getBomMap(), comparing the initial bytes
+     * of the provided string to the BOM of each; if a match is determined,
+     * it returns the encoding.
+     *
+     * @param string $string
+     * @return false|string Returns encoding on success.
+     */
+    protected static function detectBom($string)
+    {
+        foreach (self::getBomMap() as $criteria) {
+            if (0 === strncmp($string, $criteria['bom'], $criteria['length'])) {
+                return $criteria['encoding'];
+            }
+        }
+        return false;
+    }
+
+    /**
+     * Attempt to detect the string encoding of an XML string.
+     *
+     * @param string $xml
+     * @return string Encoding
+     */
+    protected static function detectXmlStringEncoding($xml)
+    {
+        foreach (self::getAsciiEncodingMap() as $encoding => $generator) {
+            $prefix = call_user_func($generator, '<' . '?xml');
+            if (0 === strncmp($xml, $prefix, strlen($prefix))) {
+                return $encoding;
+            }
+        }
+
+        // Fallback
+        return 'UTF-8';
+    }
+
+    /**
+     * Attempt to detect the specified XML encoding.
+     *
+     * Using the file's encoding, determines if an "encoding" attribute is
+     * present and well-formed in the XML declaration; if so, it returns a
+     * list with both the ASCII representation of that declaration and the
+     * original file encoding.
+     *
+     * If not, a list containing only the provided file encoding is returned.
+     *
+     * @param string $xml
+     * @param string $fileEncoding
+     * @return string[] Potential XML encodings
+     */
+    protected static function detectXmlEncoding($xml, $fileEncoding)
+    {
+        $encodingMap = self::getAsciiEncodingMap();
+        $generator   = $encodingMap[$fileEncoding];
+        $encAttr     = call_user_func($generator, 'encoding="');
+        $quote       = call_user_func($generator, '"');
+        $close       = call_user_func($generator, '>');
+
+        $closePos    = strpos($xml, $close);
+        if (false === $closePos) {
+            return array($fileEncoding);
+        }
+
+        $encPos = strpos($xml, $encAttr);
+        if (false === $encPos
+            || $encPos > $closePos
+        ) {
+            return array($fileEncoding);
+        }
+
+        $encPos   += strlen($encAttr);
+        $quotePos = strpos($xml, $quote, $encPos);
+        if (false === $quotePos) {
+            return array($fileEncoding);
+        }
+
+        $encoding = self::substr($xml, $encPos, $quotePos);
+        return array(
+            // Following line works because we're only supporting 8-bit safe encodings at this time.
+            str_replace('\0', '', $encoding), // detected encoding
+            $fileEncoding,                    // file encoding
+        );
+    }
+
+    /**
+     * Return a list of BOM maps.
+     *
+     * Returns a list of common encoding -> BOM maps, along with the character
+     * length to compare against.
+     *
+     * @link https://en.wikipedia.org/wiki/Byte_order_mark
+     * @return array
+     */
+    protected static function getBomMap()
+    {
+        return array(
+            array(
+                'encoding' => 'UTF-32BE',
+                'bom'      => pack('CCCC', 0x00, 0x00, 0xfe, 0xff),
+                'length'   => 4,
+            ),
+            array(
+                'encoding' => 'UTF-32LE',
+                'bom'      => pack('CCCC', 0xff, 0xfe, 0x00, 0x00),
+                'length'   => 4,
+            ),
+            array(
+                'encoding' => 'GB-18030',
+                'bom'      => pack('CCCC', 0x84, 0x31, 0x95, 0x33),
+                'length'   => 4,
+            ),
+            array(
+                'encoding' => 'UTF-16BE',
+                'bom'      => pack('CC', 0xfe, 0xff),
+                'length'   => 2,
+            ),
+            array(
+                'encoding' => 'UTF-16LE',
+                'bom'      => pack('CC', 0xff, 0xfe),
+                'length'   => 2,
+            ),
+            array(
+                'encoding' => 'UTF-8',
+                'bom'      => pack('CCC', 0xef, 0xbb, 0xbf),
+                'length'   => 3,
+            ),
+        );
+    }
+
+    /**
+     * Return a map of encoding => generator pairs.
+     *
+     * Returns a map of encoding => generator pairs, where the generator is a
+     * callable that accepts a string and returns the appropriate byte order
+     * sequence of that string for the encoding.
+     *
+     * @return array
+     */
+    protected static function getAsciiEncodingMap()
+    {
+        return array(
+            'UTF-32BE'   => array(__CLASS__, 'encodeToUTF32BE'),
+            'UTF-32LE'   => array(__CLASS__, 'encodeToUTF32LE'),
+            'UTF-32odd1' => array(__CLASS__, 'encodeToUTF32odd1'),
+            'UTF-32odd2' => array(__CLASS__, 'encodeToUTF32odd2'),
+            'UTF-16BE'   => array(__CLASS__, 'encodeToUTF16BE'),
+            'UTF-16LE'   => array(__CLASS__, 'encodeToUTF16LE'),
+            'UTF-8'      => array(__CLASS__, 'encodeToUTF8'),
+            'GB-18030'   => array(__CLASS__, 'encodeToUTF8'),
+        );
+    }
+
+    /**
+     * Binary-safe substr.
+     *
+     * substr() is not binary-safe; this method loops by character to ensure
+     * multi-byte characters are aggregated correctly.
+     *
+     * @param string $string
+     * @param int $start
+     * @param int $end
+     * @return string
+     */
+    protected static function substr($string, $start, $end)
+    {
+        $substr = '';
+        for ($i = $start; $i < $end; $i += 1) {
+            $substr .= $string[$i];
+        }
+        return $substr;
+    }
+
+    /**
+     * Generate an entity comparison based on the given encoding.
+     *
+     * This patch is internal only, and public only so it can be used as a
+     * callable to pass to array_map.
+     *
+     * @internal
+     * @param string $encoding
+     * @return string
+     */
+    public static function generateEntityComparison($encoding)
+    {
+        $encodingMap = self::getAsciiEncodingMap();
+        $generator   = isset($encodingMap[$encoding]) ? $encodingMap[$encoding] : $encodingMap['UTF-8'];
+        return call_user_func($generator, '<!ENTITY');
+    }
+
+    /**
+     * Encode an ASCII string to UTF-32BE
+     *
+     * @internal
+     * @param string $ascii
+     * @return string
+     */
+    public static function encodeToUTF32BE($ascii)
+    {
+        return preg_replace('/(.)/', "\0\0\0\\1", $ascii);
+    }
+
+    /**
+     * Encode an ASCII string to UTF-32LE
+     *
+     * @internal
+     * @param string $ascii
+     * @return string
+     */
+    public static function encodeToUTF32LE($ascii)
+    {
+        return preg_replace('/(.)/', "\\1\0\0\0", $ascii);
+    }
+
+    /**
+     * Encode an ASCII string to UTF-32odd1
+     *
+     * @internal
+     * @param string $ascii
+     * @return string
+     */
+    public static function encodeToUTF32odd1($ascii)
+    {
+        return preg_replace('/(.)/', "\0\\1\0\0", $ascii);
+    }
+
+    /**
+     * Encode an ASCII string to UTF-32odd2
+     *
+     * @internal
+     * @param string $ascii
+     * @return string
+     */
+    public static function encodeToUTF32odd2($ascii)
+    {
+        return preg_replace('/(.)/', "\0\0\\1\0", $ascii);
+    }
+
+    /**
+     * Encode an ASCII string to UTF-16BE
+     *
+     * @internal
+     * @param string $ascii
+     * @return string
+     */
+    public static function encodeToUTF16BE($ascii)
+    {
+        return preg_replace('/(.)/', "\0\\1", $ascii);
+    }
+
+    /**
+     * Encode an ASCII string to UTF-16LE
+     *
+     * @internal
+     * @param string $ascii
+     * @return string
+     */
+    public static function encodeToUTF16LE($ascii)
+    {
+        return preg_replace('/(.)/', "\\1\0", $ascii);
+    }
+
+    /**
+     * Encode an ASCII string to UTF-8
+     *
+     * @internal
+     * @param string $ascii
+     * @return string
+     */
+    public static function encodeToUTF8($ascii)
+    {
+        return $ascii;
+    }
+}
diff --git app/code/core/Zend/XmlRpc/Request.php app/code/core/Zend/XmlRpc/Request.php
new file mode 100644
index 0000000..17a176e
--- /dev/null
+++ app/code/core/Zend/XmlRpc/Request.php
@@ -0,0 +1,446 @@
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
+ * @package    Zend_Controller
+ * @copyright  Copyright (c) 2005-2010 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ */
+
+/**
+ * Zend_XmlRpc_Value
+ */
+#require_once 'Zend/XmlRpc/Value.php';
+
+/**
+ * Zend_XmlRpc_Fault
+ */
+#require_once 'Zend/XmlRpc/Fault.php';
+
+/** @see Zend_Xml_Security */
+#require_once 'Zend/Xml/Security.php';
+
+/** @see Zend_Xml_Exception */
+#require_once 'Zend/Xml/Exception.php';
+
+
+/**
+ * XmlRpc Request object
+ *
+ * Encapsulates an XmlRpc request, holding the method call and all parameters.
+ * Provides accessors for these, as well as the ability to load from XML and to
+ * create the XML request string.
+ *
+ * Additionally, if errors occur setting the method or parsing XML, a fault is
+ * generated and stored in {@link $_fault}; developers may check for it using
+ * {@link isFault()} and {@link getFault()}.
+ *
+ * @category Zend
+ * @package  Zend_XmlRpc
+ * @copyright  Copyright (c) 2005-2010 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ * @version $Id: Request.php 20208 2010-01-11 22:37:37Z lars $
+ */
+class Zend_XmlRpc_Request
+{
+    /**
+     * Request character encoding
+     * @var string
+     */
+    protected $_encoding = 'UTF-8';
+
+    /**
+     * Method to call
+     * @var string
+     */
+    protected $_method;
+
+    /**
+     * XML request
+     * @var string
+     */
+    protected $_xml;
+
+    /**
+     * Method parameters
+     * @var array
+     */
+    protected $_params = array();
+
+    /**
+     * Fault object, if any
+     * @var Zend_XmlRpc_Fault
+     */
+    protected $_fault = null;
+
+    /**
+     * XML-RPC type for each param
+     * @var array
+     */
+    protected $_types = array();
+
+    /**
+     * XML-RPC request params
+     * @var array
+     */
+    protected $_xmlRpcParams = array();
+
+    /**
+     * Create a new XML-RPC request
+     *
+     * @param string $method (optional)
+     * @param array $params  (optional)
+     */
+    public function __construct($method = null, $params = null)
+    {
+        if ($method !== null) {
+            $this->setMethod($method);
+        }
+
+        if ($params !== null) {
+            $this->setParams($params);
+        }
+    }
+
+
+    /**
+     * Set encoding to use in request
+     *
+     * @param string $encoding
+     * @return Zend_XmlRpc_Request
+     */
+    public function setEncoding($encoding)
+    {
+        $this->_encoding = $encoding;
+        Zend_XmlRpc_Value::setEncoding($encoding);
+        return $this;
+    }
+
+    /**
+     * Retrieve current request encoding
+     *
+     * @return string
+     */
+    public function getEncoding()
+    {
+        return $this->_encoding;
+    }
+
+    /**
+     * Set method to call
+     *
+     * @param string $method
+     * @return boolean Returns true on success, false if method name is invalid
+     */
+    public function setMethod($method)
+    {
+        if (!is_string($method) || !preg_match('/^[a-z0-9_.:\/]+$/i', $method)) {
+            $this->_fault = new Zend_XmlRpc_Fault(634, 'Invalid method name ("' . $method . '")');
+            $this->_fault->setEncoding($this->getEncoding());
+            return false;
+        }
+
+        $this->_method = $method;
+        return true;
+    }
+
+    /**
+     * Retrieve call method
+     *
+     * @return string
+     */
+    public function getMethod()
+    {
+        return $this->_method;
+    }
+
+    /**
+     * Add a parameter to the parameter stack
+     *
+     * Adds a parameter to the parameter stack, associating it with the type
+     * $type if provided
+     *
+     * @param mixed $value
+     * @param string $type Optional; type hinting
+     * @return void
+     */
+    public function addParam($value, $type = null)
+    {
+        $this->_params[] = $value;
+        if (null === $type) {
+            // Detect type if not provided explicitly
+            if ($value instanceof Zend_XmlRpc_Value) {
+                $type = $value->getType();
+            } else {
+                $xmlRpcValue = Zend_XmlRpc_Value::getXmlRpcValue($value);
+                $type        = $xmlRpcValue->getType();
+            }
+        }
+        $this->_types[]  = $type;
+        $this->_xmlRpcParams[] = array('value' => $value, 'type' => $type);
+    }
+
+    /**
+     * Set the parameters array
+     *
+     * If called with a single, array value, that array is used to set the
+     * parameters stack. If called with multiple values or a single non-array
+     * value, the arguments are used to set the parameters stack.
+     *
+     * Best is to call with array of the format, in order to allow type hinting
+     * when creating the XMLRPC values for each parameter:
+     * <code>
+     * $array = array(
+     *     array(
+     *         'value' => $value,
+     *         'type'  => $type
+     *     )[, ... ]
+     * );
+     * </code>
+     *
+     * @access public
+     * @return void
+     */
+    public function setParams()
+    {
+        $argc = func_num_args();
+        $argv = func_get_args();
+        if (0 == $argc) {
+            return;
+        }
+
+        if ((1 == $argc) && is_array($argv[0])) {
+            $params     = array();
+            $types      = array();
+            $wellFormed = true;
+            foreach ($argv[0] as $arg) {
+                if (!is_array($arg) || !isset($arg['value'])) {
+                    $wellFormed = false;
+                    break;
+                }
+                $params[] = $arg['value'];
+
+                if (!isset($arg['type'])) {
+                    $xmlRpcValue = Zend_XmlRpc_Value::getXmlRpcValue($arg['value']);
+                    $arg['type'] = $xmlRpcValue->getType();
+                }
+                $types[] = $arg['type'];
+            }
+            if ($wellFormed) {
+                $this->_xmlRpcParams = $argv[0];
+                $this->_params = $params;
+                $this->_types  = $types;
+            } else {
+                $this->_params = $argv[0];
+                $this->_types  = array();
+                $xmlRpcParams  = array();
+                foreach ($argv[0] as $arg) {
+                    if ($arg instanceof Zend_XmlRpc_Value) {
+                        $type = $arg->getType();
+                    } else {
+                        $xmlRpcValue = Zend_XmlRpc_Value::getXmlRpcValue($arg);
+                        $type        = $xmlRpcValue->getType();
+                    }
+                    $xmlRpcParams[] = array('value' => $arg, 'type' => $type);
+                    $this->_types[] = $type;
+                }
+                $this->_xmlRpcParams = $xmlRpcParams;
+            }
+            return;
+        }
+
+        $this->_params = $argv;
+        $this->_types  = array();
+        $xmlRpcParams  = array();
+        foreach ($argv as $arg) {
+            if ($arg instanceof Zend_XmlRpc_Value) {
+                $type = $arg->getType();
+            } else {
+                $xmlRpcValue = Zend_XmlRpc_Value::getXmlRpcValue($arg);
+                $type        = $xmlRpcValue->getType();
+            }
+            $xmlRpcParams[] = array('value' => $arg, 'type' => $type);
+            $this->_types[] = $type;
+        }
+        $this->_xmlRpcParams = $xmlRpcParams;
+    }
+
+    /**
+     * Retrieve the array of parameters
+     *
+     * @return array
+     */
+    public function getParams()
+    {
+        return $this->_params;
+    }
+
+    /**
+     * Return parameter types
+     *
+     * @return array
+     */
+    public function getTypes()
+    {
+        return $this->_types;
+    }
+
+    /**
+     * Load XML and parse into request components
+     *
+     * @param string $request
+     * @return boolean True on success, false if an error occurred.
+     */
+    public function loadXml($request)
+    {
+        if (!is_string($request)) {
+            $this->_fault = new Zend_XmlRpc_Fault(635);
+            $this->_fault->setEncoding($this->getEncoding());
+            return false;
+        }
+
+        try {
+            $xml = Zend_Xml_Security::scan($request);
+        } catch (Zend_Xml_Exception $e) {
+            // Not valid XML
+            $this->_fault = new Zend_XmlRpc_Fault(631);
+            $this->_fault->setEncoding($this->getEncoding());
+            return false;
+        }
+
+        // Check for method name
+        if (empty($xml->methodName)) {
+            // Missing method name
+            $this->_fault = new Zend_XmlRpc_Fault(632);
+            $this->_fault->setEncoding($this->getEncoding());
+            return false;
+        }
+
+        $this->_method = (string) $xml->methodName;
+
+        // Check for parameters
+        if (!empty($xml->params)) {
+            $types = array();
+            $argv  = array();
+            foreach ($xml->params->children() as $param) {
+                if (!isset($param->value)) {
+                    $this->_fault = new Zend_XmlRpc_Fault(633);
+                    $this->_fault->setEncoding($this->getEncoding());
+                    return false;
+                }
+
+                try {
+                    $param   = Zend_XmlRpc_Value::getXmlRpcValue($param->value, Zend_XmlRpc_Value::XML_STRING);
+                    $types[] = $param->getType();
+                    $argv[]  = $param->getValue();
+                } catch (Exception $e) {
+                    $this->_fault = new Zend_XmlRpc_Fault(636);
+                    $this->_fault->setEncoding($this->getEncoding());
+                    return false;
+                }
+            }
+
+            $this->_types  = $types;
+            $this->_params = $argv;
+        }
+
+        $this->_xml = $request;
+
+        return true;
+    }
+
+    /**
+     * Does the current request contain errors and should it return a fault
+     * response?
+     *
+     * @return boolean
+     */
+    public function isFault()
+    {
+        return $this->_fault instanceof Zend_XmlRpc_Fault;
+    }
+
+    /**
+     * Retrieve the fault response, if any
+     *
+     * @return null|Zend_XmlRpc_Fault
+     */
+    public function getFault()
+    {
+        return $this->_fault;
+    }
+
+    /**
+     * Retrieve method parameters as XMLRPC values
+     *
+     * @return array
+     */
+    protected function _getXmlRpcParams()
+    {
+        $params = array();
+        if (is_array($this->_xmlRpcParams)) {
+            foreach ($this->_xmlRpcParams as $param) {
+                $value = $param['value'];
+                $type  = isset($param['type']) ? $param['type'] : Zend_XmlRpc_Value::AUTO_DETECT_TYPE;
+
+                if (!$value instanceof Zend_XmlRpc_Value) {
+                    $value = Zend_XmlRpc_Value::getXmlRpcValue($value, $type);
+                }
+                $params[] = $value;
+            }
+        }
+
+        return $params;
+    }
+
+    /**
+     * Create XML request
+     *
+     * @return string
+     */
+    public function saveXml()
+    {
+        $args   = $this->_getXmlRpcParams();
+        $method = $this->getMethod();
+
+        $generator = Zend_XmlRpc_Value::getGenerator();
+        $generator->openElement('methodCall')
+                  ->openElement('methodName', $method)
+                  ->closeElement('methodName');
+
+        if (is_array($args) && count($args)) {
+            $generator->openElement('params');
+
+            foreach ($args as $arg) {
+                $generator->openElement('param');
+                $arg->generateXml();
+                $generator->closeElement('param');
+            }
+            $generator->closeElement('params');
+        }
+        $generator->closeElement('methodCall');
+
+        return $generator->flush();
+    }
+
+    /**
+     * Return XML request
+     *
+     * @return string
+     */
+    public function __toString()
+    {
+        return $this->saveXML();
+    }
+}
diff --git app/code/core/Zend/XmlRpc/Response.php app/code/core/Zend/XmlRpc/Response.php
new file mode 100644
index 0000000..7c1c601
--- /dev/null
+++ app/code/core/Zend/XmlRpc/Response.php
@@ -0,0 +1,254 @@
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
+ * @package    Zend_Controller
+ * @copyright  Copyright (c) 2005-2010 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ */
+
+/**
+ * Zend_XmlRpc_Value
+ */
+#require_once 'Zend/XmlRpc/Value.php';
+
+/**
+ * Zend_XmlRpc_Fault
+ */
+#require_once 'Zend/XmlRpc/Fault.php';
+
+/** @see Zend_Xml_Security */
+#require_once 'Zend/Xml/Security.php';
+
+/** @see Zend_Xml_Exception */
+#require_once 'Zend/Xml/Exception.php';
+
+/**
+ * XmlRpc Response
+ *
+ * Container for accessing an XMLRPC return value and creating the XML response.
+ *
+ * @category Zend
+ * @package  Zend_XmlRpc
+ * @copyright  Copyright (c) 2005-2010 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ * @version $Id: Response.php 21359 2010-03-07 00:54:02Z lars $
+ */
+class Zend_XmlRpc_Response
+{
+    /**
+     * Return value
+     * @var mixed
+     */
+    protected $_return;
+
+    /**
+     * Return type
+     * @var string
+     */
+    protected $_type;
+
+    /**
+     * Response character encoding
+     * @var string
+     */
+    protected $_encoding = 'UTF-8';
+
+    /**
+     * Fault, if response is a fault response
+     * @var null|Zend_XmlRpc_Fault
+     */
+    protected $_fault = null;
+
+    /**
+     * Constructor
+     *
+     * Can optionally pass in the return value and type hinting; otherwise, the
+     * return value can be set via {@link setReturnValue()}.
+     *
+     * @param mixed $return
+     * @param string $type
+     * @return void
+     */
+    public function __construct($return = null, $type = null)
+    {
+        $this->setReturnValue($return, $type);
+    }
+
+    /**
+     * Set encoding to use in response
+     *
+     * @param string $encoding
+     * @return Zend_XmlRpc_Response
+     */
+    public function setEncoding($encoding)
+    {
+        $this->_encoding = $encoding;
+        Zend_XmlRpc_Value::setEncoding($encoding);
+        return $this;
+    }
+
+    /**
+     * Retrieve current response encoding
+     *
+     * @return string
+     */
+    public function getEncoding()
+    {
+        return $this->_encoding;
+    }
+
+    /**
+     * Set the return value
+     *
+     * Sets the return value, with optional type hinting if provided.
+     *
+     * @param mixed $value
+     * @param string $type
+     * @return void
+     */
+    public function setReturnValue($value, $type = null)
+    {
+        $this->_return = $value;
+        $this->_type = (string) $type;
+    }
+
+    /**
+     * Retrieve the return value
+     *
+     * @return mixed
+     */
+    public function getReturnValue()
+    {
+        return $this->_return;
+    }
+
+    /**
+     * Retrieve the XMLRPC value for the return value
+     *
+     * @return Zend_XmlRpc_Value
+     */
+    protected function _getXmlRpcReturn()
+    {
+        return Zend_XmlRpc_Value::getXmlRpcValue($this->_return);
+    }
+
+    /**
+     * Is the response a fault response?
+     *
+     * @return boolean
+     */
+    public function isFault()
+    {
+        return $this->_fault instanceof Zend_XmlRpc_Fault;
+    }
+
+    /**
+     * Returns the fault, if any.
+     *
+     * @return null|Zend_XmlRpc_Fault
+     */
+    public function getFault()
+    {
+        return $this->_fault;
+    }
+
+    /**
+     * Load a response from an XML response
+     *
+     * Attempts to load a response from an XMLRPC response, autodetecting if it
+     * is a fault response.
+     *
+     * @param string $response
+     * @return boolean True if a valid XMLRPC response, false if a fault
+     * response or invalid input
+     */
+    public function loadXml($response)
+    {
+        if (!is_string($response)) {
+            $this->_fault = new Zend_XmlRpc_Fault(650);
+            $this->_fault->setEncoding($this->getEncoding());
+            return false;
+        }
+
+        try {
+            $xml = Zend_Xml_Security::scan($response);
+        } catch (Zend_Xml_Exception $e) {
+            // Not valid XML
+            $this->_fault = new Zend_XmlRpc_Fault(651);
+            $this->_fault->setEncoding($this->getEncoding());
+            return false;
+        }
+
+        if (!empty($xml->fault)) {
+            // fault response
+            $this->_fault = new Zend_XmlRpc_Fault();
+            $this->_fault->setEncoding($this->getEncoding());
+            $this->_fault->loadXml($response);
+            return false;
+        }
+
+        if (empty($xml->params)) {
+            // Invalid response
+            $this->_fault = new Zend_XmlRpc_Fault(652);
+            $this->_fault->setEncoding($this->getEncoding());
+            return false;
+        }
+
+        try {
+            if (!isset($xml->params) || !isset($xml->params->param) || !isset($xml->params->param->value)) {
+                throw new Zend_XmlRpc_Value_Exception('Missing XML-RPC value in XML');
+            }
+            $valueXml = $xml->params->param->value->asXML();
+            $value = Zend_XmlRpc_Value::getXmlRpcValue($valueXml, Zend_XmlRpc_Value::XML_STRING);
+        } catch (Zend_XmlRpc_Value_Exception $e) {
+            $this->_fault = new Zend_XmlRpc_Fault(653);
+            $this->_fault->setEncoding($this->getEncoding());
+            return false;
+        }
+
+        $this->setReturnValue($value->getValue());
+        return true;
+    }
+
+    /**
+     * Return response as XML
+     *
+     * @return string
+     */
+    public function saveXml()
+    {
+        $value = $this->_getXmlRpcReturn();
+        $generator = Zend_XmlRpc_Value::getGenerator();
+        $generator->openElement('methodResponse')
+                  ->openElement('params')
+                  ->openElement('param');
+        $value->generateXml();
+        $generator->closeElement('param')
+                  ->closeElement('params')
+                  ->closeElement('methodResponse');
+
+        return $generator->flush();
+    }
+
+    /**
+     * Return XML response
+     *
+     * @return string
+     */
+    public function __toString()
+    {
+        return $this->saveXML();
+    }
+}
diff --git app/design/adminhtml/default/default/layout/admin.xml app/design/adminhtml/default/default/layout/admin.xml
index 1cda171..9196797 100644
--- app/design/adminhtml/default/default/layout/admin.xml
+++ app/design/adminhtml/default/default/layout/admin.xml
@@ -27,6 +27,19 @@
 -->
 
 <layout>
+    <!-- admin permissions block edit page -->
+    <adminhtml_permissions_block_edit>
+        <reference name="content">
+            <block type="adminhtml/permissions_block_edit" name="adminhtml.permissions.block.edit"/>
+        </reference>
+    </adminhtml_permissions_block_edit>
+    <!-- admin permissions variable edit page -->
+    <adminhtml_permissions_variable_edit>
+        <reference name="content">
+            <block type="adminhtml/permissions_variable_edit" name="adminhtml.permissions.variable.edit"/>
+        </reference>
+    </adminhtml_permissions_variable_edit>
+
     <!-- admin acl roles grid page -->
     <adminhtml_permissions_role_index>
         <reference name="content">
diff --git app/design/frontend/base/default/template/customer/form/register.phtml app/design/frontend/base/default/template/customer/form/register.phtml
index 214ebed..839cb38 100644
--- app/design/frontend/base/default/template/customer/form/register.phtml
+++ app/design/frontend/base/default/template/customer/form/register.phtml
@@ -41,6 +41,7 @@
         <div class="fieldset">
             <input type="hidden" name="success_url" value="<?php echo $this->getSuccessUrl() ?>" />
             <input type="hidden" name="error_url" value="<?php echo $this->getErrorUrl() ?>" />
+            <input type="hidden" name="form_key" value="<?php echo Mage::getSingleton('core/session')->getFormKey() ?>" />
             <h2 class="legend"><?php echo $this->__('Personal Information') ?></h2>
             <ul class="form-list">
                 <li class="fields">
diff --git app/design/frontend/base/default/template/page/js/cookie.phtml app/design/frontend/base/default/template/page/js/cookie.phtml
index e62a074..04ea32e 100644
--- app/design/frontend/base/default/template/page/js/cookie.phtml
+++ app/design/frontend/base/default/template/page/js/cookie.phtml
@@ -34,7 +34,7 @@
 
 <script type="text/javascript">
 //<![CDATA[
-Mage.Cookies.path     = '<?php echo $this->getPath()?>';
-Mage.Cookies.domain   = '<?php echo $this->getDomain()?>';
+Mage.Cookies.path     = '<?php echo Mage::helper('core')->jsQuoteEscape($this->getPath()) ?>';
+Mage.Cookies.domain   = '<?php echo Mage::helper('core')->jsQuoteEscape($this->getDomain()) ?>';
 //]]>
 </script>
diff --git errors/processor.php errors/processor.php
index f979347..c7a4ea9 100644
--- errors/processor.php
+++ errors/processor.php
@@ -463,6 +463,7 @@ class Error_Processor
             @mkdir($this->_reportDir, 0750, true);
         }
 
+        $reportData = array_map('strip_tags', $reportData);
         @file_put_contents($this->_reportFile, serialize($reportData));
         @chmod($this->_reportFile, 0640);
 
diff --git lib/Unserialize/Parser.php lib/Unserialize/Parser.php
new file mode 100644
index 0000000..423902a
--- /dev/null
+++ lib/Unserialize/Parser.php
@@ -0,0 +1,61 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Unserialize
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Class Unserialize_Parser
+ */
+class Unserialize_Parser
+{
+    const TYPE_STRING = 's';
+    const TYPE_INT = 'i';
+    const TYPE_DOUBLE = 'd';
+    const TYPE_ARRAY = 'a';
+    const TYPE_BOOL = 'b';
+
+    const SYMBOL_QUOTE = '"';
+    const SYMBOL_SEMICOLON = ';';
+    const SYMBOL_COLON = ':';
+
+    /**
+     * @param $str
+     * @return array|null
+     * @throws Exception
+     */
+    public function unserialize($str)
+    {
+        $reader = new Unserialize_Reader_Arr();
+        $prevChar = null;
+        for ($i = 0; $i < strlen($str); $i++) {
+            $char = $str[$i];
+            $arr = $reader->read($char, $prevChar);
+            if (!is_null($arr)) {
+                return $arr;
+            }
+            $prevChar = $char;
+        }
+        throw new Exception('Error during unserialization');
+    }
+}
diff --git lib/Unserialize/Reader/Arr.php lib/Unserialize/Reader/Arr.php
new file mode 100644
index 0000000..caa979e
--- /dev/null
+++ lib/Unserialize/Reader/Arr.php
@@ -0,0 +1,122 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Unserialize
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Class Unserialize_Reader_Arr
+ */
+class Unserialize_Reader_Arr
+{
+    /**
+     * @var array
+     */
+    protected $_result = null;
+
+    /**
+     * @var string|int
+     */
+    protected $_length = '';
+
+    /**
+     * @var int|null
+     */
+    protected $_status = null;
+
+    /**
+     * @var object
+     */
+    protected $_reader = null;
+
+    const READING_LENGTH = 1;
+    const FINISHED_LENGTH = 2;
+    const READING_KEY = 3;
+    const READING_VALUE = 4;
+    const FINISHED_ARR = 5;
+
+    /**
+     * @param $char
+     * @param $prevChar
+     * @return array|null
+     * @throws Exception
+     */
+    public function read($char, $prevChar)
+    {
+        $this->_result = !is_null($this->_result) ? $this->_result : array();
+
+        if (is_null($this->_status) && $prevChar == Unserialize_Parser::SYMBOL_COLON) {
+            $this->_length .= $char;
+            $this->_status = self::READING_LENGTH;
+            return null;
+        }
+
+        if ($this->_status == self::READING_LENGTH) {
+            if ($char == Unserialize_Parser::SYMBOL_COLON) {
+                $this->_length = (int)$this->_length;
+                if ($this->_length == 0) {
+                    $this->_status = self::FINISHED_ARR;
+                    return null;
+                }
+                $this->_status = self::FINISHED_LENGTH;
+            } else {
+                $this->_length .= $char;
+            }
+        }
+
+        if ($this->_status == self::FINISHED_LENGTH && $prevChar == '{') {
+            $this->_reader = new Unserialize_Reader_ArrKey();
+            $this->_status = self::READING_KEY;
+        }
+
+        if ($this->_status == self::READING_KEY) {
+            $key = $this->_reader->read($char, $prevChar);
+            if (!is_null($key)) {
+                $this->_status = self::READING_VALUE;
+                $this->_reader = new Unserialize_Reader_ArrValue($key);
+                return null;
+            }
+        }
+
+        if ($this->_status == self::READING_VALUE) {
+            $value = $this->_reader->read($char, $prevChar);
+            if (!is_null($value)) {
+                $this->_result[$this->_reader->key] = $value;
+                if (count($this->_result) < $this->_length) {
+                    $this->_reader = new Unserialize_Reader_ArrKey();
+                    $this->_status = self::READING_KEY;
+                    return null;
+                } else {
+                    $this->_status = self::FINISHED_ARR;
+                    return null;
+                }
+            }
+        }
+
+        if ($this->_status == self::FINISHED_ARR) {
+            if ($char == '}') {
+                return $this->_result;
+            }
+        }
+    }
+}
diff --git lib/Unserialize/Reader/ArrKey.php lib/Unserialize/Reader/ArrKey.php
new file mode 100644
index 0000000..830e928
--- /dev/null
+++ lib/Unserialize/Reader/ArrKey.php
@@ -0,0 +1,84 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Unserialize
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Class Unserialize_Reader_ArrKey
+ */
+class Unserialize_Reader_ArrKey
+{
+    /**
+     * @var int
+     */
+    protected $_status;
+
+    /**
+     * @object
+     */
+    protected $_reader;
+
+    const NOT_STARTED = 1;
+    const READING_KEY = 2;
+
+    /**
+     * Construct
+     */
+    public function __construct()
+    {
+        $this->_status = self::NOT_STARTED;
+    }
+
+    /**
+     * @param string $char
+     * @param string $prevChar
+     * @return mixed|null
+     * @throws Exception
+     */
+    public function read($char, $prevChar)
+    {
+        if ($this->_status == self::NOT_STARTED) {
+            switch ($char) {
+                case Unserialize_Parser::TYPE_STRING:
+                    $this->_reader = new Unserialize_Reader_Str();
+                    $this->_status = self::READING_KEY;
+                    break;
+                case Unserialize_Parser::TYPE_INT:
+                    $this->_reader = new Unserialize_Reader_Int();
+                    $this->_status = self::READING_KEY;
+                    break;
+                default:
+                    throw new Exception('Unsupported data type ' . $char);
+            }
+        }
+
+        if ($this->_status == self::READING_KEY) {
+            $key = $this->_reader->read($char, $prevChar);
+            if (!is_null($key)) {
+                return $key;
+            }
+        }
+        return null;
+    }
+}
diff --git lib/Unserialize/Reader/ArrValue.php lib/Unserialize/Reader/ArrValue.php
new file mode 100644
index 0000000..d2a4937
--- /dev/null
+++ lib/Unserialize/Reader/ArrValue.php
@@ -0,0 +1,100 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Unserialize
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Class Unserialize_Reader_ArrValue
+ */
+class Unserialize_Reader_ArrValue
+{
+
+    /**
+     * @var
+     */
+    public $key;
+
+    /**
+     * @var int
+     */
+    protected $_status;
+
+    /**
+     * @object
+     */
+    protected $_reader;
+
+    const NOT_STARTED = 1;
+    const READING_VALUE = 2;
+
+    public function __construct($key)
+    {
+        $this->_status = self::NOT_STARTED;
+        $this->key = $key;
+    }
+
+    /**
+     * @param string $char
+     * @param string $prevChar
+     * @return mixed|null
+     * @throws Exception
+     */
+    public function read($char, $prevChar)
+    {
+        if ($this->_status == self::NOT_STARTED) {
+            switch ($char) {
+                case Unserialize_Parser::TYPE_STRING:
+                    $this->_reader = new Unserialize_Reader_Str();
+                    $this->_status = self::READING_VALUE;
+                    break;
+                case Unserialize_Parser::TYPE_ARRAY:
+                    $this->_reader = new Unserialize_Reader_Arr();
+                    $this->_status = self::READING_VALUE;
+                    break;
+                case Unserialize_Parser::TYPE_INT:
+                    $this->_reader = new Unserialize_Reader_Int();
+                    $this->_status = self::READING_VALUE;
+                    break;
+                case Unserialize_Parser::TYPE_BOOL:
+                    $this->_reader = new Unserialize_Reader_Bool();
+                    $this->_status = self::READING_VALUE;
+                    break;
+                case Unserialize_Parser::TYPE_DOUBLE:
+                    $this->_reader = new Unserialize_Reader_Dbl();
+                    $this->_status = self::READING_VALUE;
+                    break;
+                default:
+                    throw new Exception('Unsupported data type ' . $char);
+            }
+        }
+
+        if ($this->_status == self::READING_VALUE) {
+            $value = $this->_reader->read($char, $prevChar);
+            if (!is_null($value)) {
+                return $value;
+            }
+        }
+        return null;
+    }
+}
diff --git lib/Unserialize/Reader/Bool.php lib/Unserialize/Reader/Bool.php
new file mode 100644
index 0000000..5e1a132
--- /dev/null
+++ lib/Unserialize/Reader/Bool.php
@@ -0,0 +1,66 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Unserialize
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Class Unserialize_Reader_Int
+ */
+class Unserialize_Reader_Bool
+{
+    /**
+     * @var int
+     */
+    protected $_status;
+
+    /**
+     * @var string|int
+     */
+    protected $_value;
+
+    const READING_VALUE = 1;
+
+    /**
+     * @param string $char
+     * @param string $prevChar
+     * @return int|null
+     */
+    public function read($char, $prevChar)
+    {
+        if ($prevChar == Unserialize_Parser::SYMBOL_COLON) {
+            $this->_value .= $char;
+            $this->_status = self::READING_VALUE;
+            return null;
+        }
+
+        if ($this->_status == self::READING_VALUE) {
+            if ($char !== Unserialize_Parser::SYMBOL_SEMICOLON) {
+                $this->_value .= $char;
+            } else {
+                return (bool)$this->_value;
+            }
+        }
+        return null;
+    }
+}
diff --git lib/Unserialize/Reader/Dbl.php lib/Unserialize/Reader/Dbl.php
new file mode 100644
index 0000000..48367c8
--- /dev/null
+++ lib/Unserialize/Reader/Dbl.php
@@ -0,0 +1,66 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Unserialize
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Class Unserialize_Reader_Dbl
+ */
+class Unserialize_Reader_Dbl
+{
+    /**
+     * @var int
+     */
+    protected $_status;
+
+    /**
+     * @var string|int
+     */
+    protected $_value;
+
+    const READING_VALUE = 1;
+
+    /**
+     * @param string $char
+     * @param string $prevChar
+     * @return float|null
+     */
+    public function read($char, $prevChar)
+    {
+        if ($prevChar == Unserialize_Parser::SYMBOL_COLON) {
+            $this->_value .= $char;
+            $this->_status = self::READING_VALUE;
+            return null;
+        }
+
+        if ($this->_status == self::READING_VALUE) {
+            if ($char !== Unserialize_Parser::SYMBOL_SEMICOLON) {
+                $this->_value .= $char;
+            } else {
+                return (float)$this->_value;
+            }
+        }
+        return null;
+    }
+}
diff --git lib/Unserialize/Reader/Int.php lib/Unserialize/Reader/Int.php
new file mode 100644
index 0000000..7bf6c40
--- /dev/null
+++ lib/Unserialize/Reader/Int.php
@@ -0,0 +1,66 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Unserialize
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Class Unserialize_Reader_Int
+ */
+class Unserialize_Reader_Int
+{
+    /**
+     * @var int
+     */
+    protected $_status;
+
+    /**
+     * @var string|int
+     */
+    protected $_value;
+
+    const READING_VALUE = 1;
+
+    /**
+     * @param string $char
+     * @param string $prevChar
+     * @return int|null
+     */
+    public function read($char, $prevChar)
+    {
+        if ($prevChar == Unserialize_Parser::SYMBOL_COLON) {
+            $this->_value .= $char;
+            $this->_status = self::READING_VALUE;
+            return null;
+        }
+
+        if ($this->_status == self::READING_VALUE) {
+            if ($char !== Unserialize_Parser::SYMBOL_SEMICOLON) {
+                $this->_value .= $char;
+            } else {
+                return (int)$this->_value;
+            }
+        }
+        return null;
+    }
+}
diff --git lib/Unserialize/Reader/Str.php lib/Unserialize/Reader/Str.php
new file mode 100644
index 0000000..e62b38f
--- /dev/null
+++ lib/Unserialize/Reader/Str.php
@@ -0,0 +1,93 @@
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
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Unserialize
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Class Unserialize_Reader_Str
+ */
+class Unserialize_Reader_Str
+{
+    /**
+     * @var int|null
+     */
+    protected $_status = null;
+
+    /**
+     * @var int|string
+     */
+    protected $_length;
+
+    /**
+     * @var string
+     */
+    protected $_value;
+
+    const READING_LENGTH = 1;
+    const FINISHED_LENGTH = 2;
+    const READING_VALUE = 3;
+
+    /**
+     * @param string $char
+     * @param string $prevChar
+     * @return null|string
+     */
+    public function read($char, $prevChar)
+    {
+
+        if (is_null($this->_status) && $prevChar == Unserialize_Parser::SYMBOL_COLON) {
+            $this->_status = self::READING_LENGTH;
+        }
+
+        if ($this->_status == self::READING_LENGTH) {
+            if ($char != Unserialize_Parser::SYMBOL_COLON) {
+                $this->_length .= $char;
+            } else {
+                $this->_length = (int)$this->_length;
+                $this->_status = self::FINISHED_LENGTH;
+            }
+        }
+
+        if ($this->_status == self::FINISHED_LENGTH) {
+            if ($char == Unserialize_Parser::SYMBOL_QUOTE) {
+                $this->_status = self::READING_VALUE;
+                return null;
+            }
+        }
+
+        if ($this->_status == self::READING_VALUE) {
+            if (strlen($this->_value) < $this->_length) {
+                $this->_value .= $char;
+                return null;
+            }
+
+            if (strlen($this->_value) == $this->_length) {
+                if ($char == Unserialize_Parser::SYMBOL_SEMICOLON && $prevChar == Unserialize_Parser::SYMBOL_QUOTE) {
+                    return (string)$this->_value;
+                }
+            }
+        }
+        return null;
+    }
+}
diff --git lib/Varien/Data/Collection/Db.php lib/Varien/Data/Collection/Db.php
index 7a5411e..cb4d0ba 100644
--- lib/Varien/Data/Collection/Db.php
+++ lib/Varien/Data/Collection/Db.php
@@ -372,8 +372,14 @@ class Varien_Data_Collection_Db extends Varien_Data_Collection
      */
     public function addFieldToFilter($field, $condition=null)
     {
-        $field = $this->_getMappedField($field);
-        $this->_select->where($this->_getConditionSql($field, $condition), null, Varien_Db_Select::TYPE_CONDITION);
+        $mappedField = $this->_getMappedField($field);
+
+        $quotedField = $mappedField;
+        if ($mappedField === $field) {
+            $quotedField = $this->getConnection()->quoteIdentifier($field);
+        }
+
+        $this->_select->where($this->_getConditionSql($quotedField, $condition), null, Varien_Db_Select::TYPE_CONDITION);
         return $this;
     }
 
@@ -421,7 +427,7 @@ class Varien_Data_Collection_Db extends Varien_Data_Collection
      * If non matched - sequential array is expected and OR conditions
      * will be built using above mentioned structure
      *
-     * @param string|array $fieldName
+     * @param string|array $fieldName Field name must be already escaped with Varien_Db_Adapter_Interface::quoteIdentifier()
      * @param integer|string|array $condition
      * @return string
      */
