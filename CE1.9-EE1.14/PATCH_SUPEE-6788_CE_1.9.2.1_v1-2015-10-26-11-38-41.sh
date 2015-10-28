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


SUPEE-6788 | CE_1.9.2.1 | v1 | 5045e6c2debec59bc5c451aa2bb2d7873c07ffd1 | Fri Oct 23 20:32:44 2015 +0300 | f0e6aebd290b6ac312637058a11ae7b49ad13438..5045e6c2debec59bc5c451aa2bb2d7873c07ffd1

__PATCHFILE_FOLLOWS__
diff --git .htaccess .htaccess
index 60e1795..aca7f55 100644
--- .htaccess
+++ .htaccess
@@ -207,3 +207,28 @@
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
index b8821af..383313a 100644
--- .htaccess.sample
+++ .htaccess.sample
@@ -176,3 +176,27 @@
 
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
index 0000000..b33db1b
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
+            $errors[] = Mage::helper('adminhtml')->__('Block Name is required field.');
+        }
+        if (!Zend_Validate::is($this->getBlockName(), 'Regex', array('/^[-_a-zA-Z0-9\/]*$/'))) {
+            $errors[] = Mage::helper('adminhtml')->__('Block Name is incorrect.');
+        }
+
+        if (!in_array($this->getIsAllowed(), array('0', '1'))) {
+            $errors[] = Mage::helper('adminhtml')->__('Is Allowed is required field.');
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
diff --git app/code/core/Mage/Admin/Model/Resource/Block.php app/code/core/Mage/Admin/Model/Resource/Block.php
new file mode 100644
index 0000000..99b1c33
--- /dev/null
+++ app/code/core/Mage/Admin/Model/Resource/Block.php
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
+class Mage_Admin_Model_Resource_Block extends Mage_Core_Model_Resource_Db_Abstract
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
diff --git app/code/core/Mage/Admin/Model/Resource/Block/Collection.php app/code/core/Mage/Admin/Model/Resource/Block/Collection.php
new file mode 100644
index 0000000..4b64825
--- /dev/null
+++ app/code/core/Mage/Admin/Model/Resource/Block/Collection.php
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
+class Mage_Admin_Model_Resource_Block_Collection extends Mage_Core_Model_Resource_Db_Collection_Abstract
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
diff --git app/code/core/Mage/Admin/Model/Resource/Variable.php app/code/core/Mage/Admin/Model/Resource/Variable.php
new file mode 100644
index 0000000..b742097
--- /dev/null
+++ app/code/core/Mage/Admin/Model/Resource/Variable.php
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
+class Mage_Admin_Model_Resource_Variable extends Mage_Core_Model_Resource_Db_Abstract
+{
+    /**
+     * Define main table
+     */
+    protected function _construct()
+    {
+        $this->_init('admin/permission_variable', 'variable_id');
+    }
+}
diff --git app/code/core/Mage/Admin/Model/Resource/Variable/Collection.php app/code/core/Mage/Admin/Model/Resource/Variable/Collection.php
new file mode 100644
index 0000000..54ab1e5
--- /dev/null
+++ app/code/core/Mage/Admin/Model/Resource/Variable/Collection.php
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
+class Mage_Admin_Model_Resource_Variable_Collection extends Mage_Core_Model_Resource_Db_Collection_Abstract
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
index 0000000..e353a2c
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
+            $errors[] = Mage::helper('adminhtml')->__('Variable Name is required field.');
+        }
+        if (!Zend_Validate::is($this->getVariableName(), 'Regex', array('/^[-_a-zA-Z0-9\/]*$/'))) {
+            $errors[] = Mage::helper('adminhtml')->__('Variable Name is incorrect.');
+        }
+
+        if (!in_array($this->getIsAllowed(), array('0', '1'))) {
+            $errors[] = Mage::helper('adminhtml')->__('Is Allowed is required field.');
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
index 7136e9c..774b17b 100644
--- app/code/core/Mage/Admin/etc/config.xml
+++ app/code/core/Mage/Admin/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Mage_Admin>
-            <version>1.6.1.1</version>
+            <version>1.6.1.2</version>
         </Mage_Admin>
     </modules>
     <global>
@@ -50,6 +50,12 @@
                     <rule>
                         <table>admin_rule</table>
                     </rule>
+                    <permission_variable>
+                        <table>permission_variable</table>
+                    </permission_variable>
+                    <permission_block>
+                        <table>permission_block</table>
+                    </permission_block>
                     <assert>
                         <table>admin_assert</table>
                     </assert>
diff --git app/code/core/Mage/Admin/sql/admin_setup/upgrade-1.6.1.1-1.6.1.2.php app/code/core/Mage/Admin/sql/admin_setup/upgrade-1.6.1.1-1.6.1.2.php
new file mode 100644
index 0000000..1846958
--- /dev/null
+++ app/code/core/Mage/Admin/sql/admin_setup/upgrade-1.6.1.1-1.6.1.2.php
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
+ * @package     Mage_Admin
+ * @copyright   Copyright (c) 2015 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/** @var $installer Mage_Core_Model_Resource_Setup */
+$installer = $this;
+$installer->startSetup();
+
+$table = $installer->getConnection()
+    ->newTable($installer->getTable('admin/permission_variable'))
+    ->addColumn('variable_id', Varien_Db_Ddl_Table::TYPE_INTEGER, null, array(
+        'identity'  => true,
+        'unsigned'  => true,
+        'nullable'  => false,
+        'primary'   => true,
+    ), 'Variable ID')
+    ->addColumn('variable_name', Varien_Db_Ddl_Table::TYPE_VARCHAR, 255, array(
+        'primary'   => true,
+        'nullable'  => false,
+        'default'   => "",
+        ), 'Config Path')
+    ->addColumn('is_allowed', Varien_Db_Ddl_Table::TYPE_BOOLEAN, null, array(
+        'nullable'  => false,
+        'default'   => 0,
+        ), 'Mark that config can be processed by filters')
+    ->addIndex($installer->getIdxName('admin/permission_variable', array('variable_name'), Varien_Db_Adapter_Interface::INDEX_TYPE_UNIQUE),
+        array('variable_name'), array('type' => Varien_Db_Adapter_Interface::INDEX_TYPE_UNIQUE))
+    ->setComment('System variables that can be processed via content filter');
+$installer->getConnection()->createTable($table);
+
+$installer->getConnection()->insertMultiple(
+    $installer->getTable('admin/permission_variable'),
+    array(
+        array('variable_name' => 'trans_email/ident_support/name', 'is_allowed' => 1),
+        array('variable_name' => 'trans_email/ident_support/email','is_allowed' =>  1),
+        array('variable_name' => 'web/unsecure/base_url','is_allowed' =>  1),
+        array('variable_name' => 'web/secure/base_url','is_allowed' =>  1),
+        array('variable_name' => 'trans_email/ident_general/name','is_allowed' =>  1),
+        array('variable_name' => 'trans_email/ident_general/email', 'is_allowed' => 1),
+        array('variable_name' => 'trans_email/ident_sales/name','is_allowed' =>  1),
+        array('variable_name' => 'trans_email/ident_sales/email','is_allowed' =>  1),
+        array('variable_name' => 'trans_email/ident_custom1/name','is_allowed' =>  1),
+        array('variable_name' => 'trans_email/ident_custom1/email','is_allowed' =>  1),
+        array('variable_name' => 'trans_email/ident_custom2/name','is_allowed' =>  1),
+        array('variable_name' => 'trans_email/ident_custom2/email','is_allowed' =>  1),
+        array('variable_name' => 'general/store_information/name', 'is_allowed' => 1),
+        array('variable_name' => 'general/store_information/phone','is_allowed'  => 1),
+        array('variable_name' => 'general/store_information/address', 'is_allowed' => 1),
+    )
+);
+
+$table = $installer->getConnection()
+    ->newTable($installer->getTable('admin/permission_block'))
+    ->addColumn('block_id', Varien_Db_Ddl_Table::TYPE_INTEGER, null, array(
+        'identity'  => true,
+        'unsigned'  => true,
+        'nullable'  => false,
+        'primary'   => true,
+        ), 'Block ID')
+    ->addColumn('block_name', Varien_Db_Ddl_Table::TYPE_VARCHAR, 255, array(
+        'nullable'  => false,
+        'default'   => "",
+        ), 'Block Name')
+    ->addColumn('is_allowed', Varien_Db_Ddl_Table::TYPE_BOOLEAN, null, array(
+        'nullable'  => false,
+        'default'   => 0,
+        ), 'Mark that block can be processed by filters')
+    ->addIndex($installer->getIdxName('admin/permission_block', array('block_name'), Varien_Db_Adapter_Interface::INDEX_TYPE_UNIQUE),
+        array('block_name'), array('type' => Varien_Db_Adapter_Interface::INDEX_TYPE_UNIQUE))
+    ->setComment('System blocks that can be processed via content filter');
+$installer->getConnection()->createTable($table);
+
+$installer->getConnection()->insertMultiple(
+    $installer->getTable('admin/permission_block'),
+    array(
+        array('block_name' => 'core/template', 'is_allowed' => 1),
+        array('block_name' => 'catalog/product_new', 'is_allowed' => 1),
+    )
+);
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
index 9c44731..82ddb0b 100644
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
index 65c4ec9..db7fb2b 100644
--- app/code/core/Mage/Catalog/Model/Product/Option/Type/File.php
+++ app/code/core/Mage/Catalog/Model/Product/Option/Type/File.php
@@ -126,17 +126,9 @@ class Mage_Catalog_Model_Product_Option_Type_File extends Mage_Catalog_Model_Pro
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
@@ -448,6 +440,11 @@ class Mage_Catalog_Model_Product_Option_Type_File extends Mage_Catalog_Model_Pro
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
@@ -478,7 +475,7 @@ class Mage_Catalog_Model_Product_Option_Type_File extends Mage_Catalog_Model_Pro
     {
         if ($this->_formattedOptionValue === null) {
             try {
-                $value = unserialize($optionValue);
+                $value = Mage::helper('core/unserializeArray')->unserialize($optionValue);
 
                 $customOptionUrlParams = $this->getCustomOptionUrlParams()
                     ? $this->getCustomOptionUrlParams()
@@ -542,7 +539,7 @@ class Mage_Catalog_Model_Product_Option_Type_File extends Mage_Catalog_Model_Pro
         if (is_array($value)) {
             return $value;
         } elseif (is_string($value) && !empty($value)) {
-            return unserialize($value);
+            return Mage::helper('core/unserializeArray')->unserialize($value);
         } else {
             return array();
         }
@@ -568,7 +565,7 @@ class Mage_Catalog_Model_Product_Option_Type_File extends Mage_Catalog_Model_Pro
     public function getEditableOptionValue($optionValue)
     {
         try {
-            $value = unserialize($optionValue);
+            $value = Mage::helper('core/unserializeArray')->unserialize($optionValue);
             return sprintf('%s [%d]',
                 Mage::helper('core')->escapeHtml($value['title']),
                 $this->getConfigurationItemOption()->getId()
@@ -593,7 +590,6 @@ class Mage_Catalog_Model_Product_Option_Type_File extends Mage_Catalog_Model_Pro
             $confItemOptionId = $matches[1];
             $option = Mage::getModel('sales/quote_item_option')->load($confItemOptionId);
             try {
-                unserialize($option->getValue());
                 return $option->getValue();
             } catch (Exception $e) {
                 return null;
@@ -612,7 +608,7 @@ class Mage_Catalog_Model_Product_Option_Type_File extends Mage_Catalog_Model_Pro
     public function prepareOptionValueForRequest($optionValue)
     {
         try {
-            $result = unserialize($optionValue);
+            $result = Mage::helper('core/unserializeArray')->unserialize($optionValue);
             return $result;
         } catch (Exception $e) {
             return null;
@@ -628,7 +624,7 @@ class Mage_Catalog_Model_Product_Option_Type_File extends Mage_Catalog_Model_Pro
     {
         $quoteOption = $this->getQuoteItemOption();
         try {
-            $value = unserialize($quoteOption->getValue());
+            $value = Mage::helper('core/unserializeArray')->unserialize($quoteOption->getValue());
             if (!isset($value['quote_path'])) {
                 throw new Exception();
             }
diff --git app/code/core/Mage/Core/Controller/Front/Action.php app/code/core/Mage/Core/Controller/Front/Action.php
index 6dab88b..f310cc1 100644
--- app/code/core/Mage/Core/Controller/Front/Action.php
+++ app/code/core/Mage/Core/Controller/Front/Action.php
@@ -173,9 +173,19 @@ class Mage_Core_Controller_Front_Action extends Mage_Core_Controller_Varien_Acti
     protected function _validateFormKey()
     {
         $validated = true;
-        if (Mage::getStoreConfigFlag(self::XML_CSRF_USE_FLAG_CONFIG_PATH)) {
+        if ($this->_isFormKeyEnabled()) {
             $validated = parent::_validateFormKey();
         }
         return $validated;
     }
+
+    /**
+     * Check if form key validation is enabled.
+     *
+     * @return bool
+     */
+    protected function _isFormKeyEnabled()
+    {
+        return Mage::getStoreConfigFlag(self::XML_CSRF_USE_FLAG_CONFIG_PATH);
+    }
 }
diff --git app/code/core/Mage/Core/Controller/Varien/Router/Admin.php app/code/core/Mage/Core/Controller/Varien/Router/Admin.php
index 0dd89ff..b19aaa1 100644
--- app/code/core/Mage/Core/Controller/Varien/Router/Admin.php
+++ app/code/core/Mage/Core/Controller/Varien/Router/Admin.php
@@ -131,6 +131,29 @@ class Mage_Core_Controller_Varien_Router_Admin extends Mage_Core_Controller_Vari
     }
 
     /**
+     * Add module definition to routes.
+     *
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
+            Mage_Adminhtml_Helper_Data::XML_PATH_ADMINHTML_ROUTER_FRONTNAME
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
index 8b42400..12afbc4 100644
--- app/code/core/Mage/Core/Model/Email/Template/Filter.php
+++ app/code/core/Mage/Core/Model/Email/Template/Filter.php
@@ -70,6 +70,12 @@ class Mage_Core_Model_Email_Template_Filter extends Varien_Filter_Template
      */
     protected $_inlineCssFile = false;
 
+    /** @var Mage_Admin_Model_Variable  */
+    protected $_permissionVariable;
+
+    /** @var Mage_Admin_Model_Block  */
+    protected $_permissionBlock;
+
     /**
      * Setup callbacks for filters
      *
@@ -77,6 +83,8 @@ class Mage_Core_Model_Email_Template_Filter extends Varien_Filter_Template
     public function __construct()
     {
         $this->_modifiers['escape'] = array($this, 'modifierEscape');
+        $this->_permissionVariable = Mage::getModel('admin/variable');
+        $this->_permissionBlock = Mage::getModel('admin/block');
     }
 
     /**
@@ -165,8 +173,10 @@ class Mage_Core_Model_Email_Template_Filter extends Varien_Filter_Template
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
@@ -466,7 +476,7 @@ class Mage_Core_Model_Email_Template_Filter extends Varien_Filter_Template
         $configValue = '';
         $params = $this->_getIncludeParameters($construction[2]);
         $storeId = $this->getStoreId();
-        if (isset($params['path'])) {
+        if (isset($params['path']) && $this->_permissionVariable->isPathAllowed($params['path'])) {
             $configValue = Mage::getStoreConfig($params['path'], $storeId);
         }
         return $configValue;
diff --git app/code/core/Mage/Core/Model/Resource/Setup.php app/code/core/Mage/Core/Model/Resource/Setup.php
index d675029..a24d888 100644
--- app/code/core/Mage/Core/Model/Resource/Setup.php
+++ app/code/core/Mage/Core/Model/Resource/Setup.php
@@ -641,7 +641,6 @@ class Mage_Core_Model_Resource_Setup
                     $this->_setResourceVersion($actionType, $file['toVersion']);
                 }
             } catch (Exception $e) {
-                printf('<pre>%s</pre>', print_r($e, true));
                 throw Mage::exception('Mage_Core', Mage::helper('core')->__('Error in file: "%s" - %s', $fileName, $e->getMessage()));
             }
             $version = $file['toVersion'];
diff --git app/code/core/Mage/Core/etc/config.xml app/code/core/Mage/Core/etc/config.xml
index 444f830..1c6a70e 100644
--- app/code/core/Mage/Core/etc/config.xml
+++ app/code/core/Mage/Core/etc/config.xml
@@ -415,6 +415,7 @@
                 <use_form_key>1</use_form_key>
                 <domain_policy_backend>2</domain_policy_backend>
                 <domain_policy_frontend>2</domain_policy_frontend>
+                <extensions_compatibility_mode>1</extensions_compatibility_mode>
             </security>
         </admin>
         <general>
diff --git app/code/core/Mage/Core/etc/system.xml app/code/core/Mage/Core/etc/system.xml
index c9715cd..1943649 100644
--- app/code/core/Mage/Core/etc/system.xml
+++ app/code/core/Mage/Core/etc/system.xml
@@ -1188,7 +1188,7 @@
                             <show_in_website>0</show_in_website>
                             <show_in_store>0</show_in_store>
                         </session_cookie_lifetime>
-                        <domain_policy_backend translate="label">
+                        <domain_policy_backend translate="label comment">
                             <label>Allow Magento Backend to run in frame</label>
                             <frontend_type>select</frontend_type>
                             <comment>Enabling ability to run Magento in a frame is not recommended for security reasons.</comment>
@@ -1198,7 +1198,7 @@
                             <show_in_website>0</show_in_website>
                             <show_in_store>0</show_in_store>
                         </domain_policy_backend>
-                        <domain_policy_frontend translate="label">
+                        <domain_policy_frontend translate="label comment">
                             <label>Allow Magento Frontend to run in frame</label>
                             <comment>Enabling ability to run Magento in a frame is not recommended for security reasons.</comment>
                             <frontend_type>select</frontend_type>
@@ -1208,6 +1208,16 @@
                             <show_in_website>0</show_in_website>
                             <show_in_store>0</show_in_store>
                         </domain_policy_frontend>
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
diff --git app/code/core/Mage/Customer/Block/Account/Changeforgotten.php app/code/core/Mage/Customer/Block/Account/Changeforgotten.php
new file mode 100644
index 0000000..9c08a7d
--- /dev/null
+++ app/code/core/Mage/Customer/Block/Account/Changeforgotten.php
@@ -0,0 +1,38 @@
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
+ * @package     Mage_Customer
+ * @copyright   Copyright (c) 2014 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Customer reset password form
+ *
+ * @category    Mage
+ * @package     Mage_Customer
+ * @author      Magento Core Team <core@magentocommerce.com>
+ */
+
+class Mage_Customer_Block_Account_Changeforgotten extends Mage_Core_Block_Template
+{
+
+}
diff --git app/code/core/Mage/Customer/Block/Account/Resetpassword.php app/code/core/Mage/Customer/Block/Account/Resetpassword.php
index f4229ec..2ad31b7 100644
--- app/code/core/Mage/Customer/Block/Account/Resetpassword.php
+++ app/code/core/Mage/Customer/Block/Account/Resetpassword.php
@@ -32,6 +32,9 @@
  * @author      Magento Core Team <core@magentocommerce.com>
  */
 
+/**
+ * @deprecated
+ */
 class Mage_Customer_Block_Account_Resetpassword extends Mage_Core_Block_Template
 {
 
diff --git app/code/core/Mage/Customer/controllers/AccountController.php app/code/core/Mage/Customer/controllers/AccountController.php
index 27cdb95..19543f7 100644
--- app/code/core/Mage/Customer/controllers/AccountController.php
+++ app/code/core/Mage/Customer/controllers/AccountController.php
@@ -33,6 +33,9 @@
  */
 class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
 {
+    const CUSTOMER_ID_SESSION_NAME = "customerId";
+    const TOKEN_SESSION_NAME = "token";
+
     /**
      * Action list where need check enabled cookie
      *
@@ -72,6 +75,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             'logoutsuccess',
             'forgotpassword',
             'forgotpasswordpost',
+            'changeforgotten',
             'resetpassword',
             'resetpasswordpost',
             'confirm',
@@ -268,15 +272,21 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
      */
     public function createPostAction()
     {
+        $errUrl = $this->_getUrl('*/*/create', array('_secure' => true));
+
+        if (!$this->_validateFormKey()) {
+            $this->_redirectError($errUrl);
+            return;
+        }
+
         /** @var $session Mage_Customer_Model_Session */
         $session = $this->_getSession();
         if ($session->isLoggedIn()) {
             $this->_redirect('*/*/');
             return;
         }
-        $session->setEscapeMessages(true); // prevent XSS injection in user input
+
         if (!$this->getRequest()->isPost()) {
-            $errUrl = $this->_getUrl('*/*/create', array('_secure' => true));
             $this->_redirectError($errUrl);
             return;
         }
@@ -300,16 +310,15 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             if ($e->getCode() === Mage_Customer_Model_Customer::EXCEPTION_EMAIL_EXISTS) {
                 $url = $this->_getUrl('customer/account/forgotpassword');
                 $message = $this->__('There is already an account with this email address. If you are sure that it is your email address, <a href="%s">click here</a> to get your password and access your account.', $url);
-                $session->setEscapeMessages(false);
             } else {
-                $message = $e->getMessage();
+                $message = $this->_escapeHtml($e->getMessage());
             }
             $session->addError($message);
         } catch (Exception $e) {
-            $session->setCustomerFormData($this->getRequest()->getPost())
-                ->addException($e, $this->__('Cannot save the customer.'));
+            $session->setCustomerFormData($this->getRequest()->getPost());
+            $session->addException($e, $this->__('Cannot save the customer.'));
         }
-        $errUrl = $this->_getUrl('*/*/create', array('_secure' => true));
+
         $this->_redirectError($errUrl);
     }
 
@@ -377,7 +386,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
         $session->setCustomerFormData($this->getRequest()->getPost());
         if (is_array($errors)) {
             foreach ($errors as $errorMessage) {
-                $session->addError($errorMessage);
+                $session->addError($this->_escapeHtml($errorMessage));
             }
         } else {
             $session->addError($this->__('Invalid customer data'));
@@ -385,6 +394,17 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
     }
 
     /**
+     * Escape message text HTML.
+     *
+     * @param string $text
+     * @return string
+     */
+    protected function _escapeHtml($text)
+    {
+        return Mage::helper('core')->escapeHtml($text);
+    }
+
+    /**
      * Validate customer data and return errors if they are
      *
      * @param Mage_Customer_Model_Customer $customer
@@ -741,23 +761,39 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
     /**
      * Display reset forgotten password form
      *
-     * User is redirected on this action when he clicks on the corresponding link in password reset confirmation email
-     *
      */
-    public function resetPasswordAction()
+    public function changeForgottenAction()
     {
-        $resetPasswordLinkToken = (string) $this->getRequest()->getQuery('token');
-        $customerId = (int) $this->getRequest()->getQuery('id');
         try {
+            list($customerId, $resetPasswordLinkToken) = $this->_getRestorePasswordParameters($this->_getSession());
             $this->_validateResetPasswordLinkToken($customerId, $resetPasswordLinkToken);
             $this->loadLayout();
-            // Pass received parameters to the reset forgotten password form
-            $this->getLayout()->getBlock('resetPassword')
-                ->setCustomerId($customerId)
-                ->setResetPasswordLinkToken($resetPasswordLinkToken);
             $this->renderLayout();
+
         } catch (Exception $exception) {
-            $this->_getSession()->addError( $this->_getHelper('customer')->__('Your password reset link has expired.'));
+            $this->_getSession()->addError($this->_getHelper('customer')->__('Your password reset link has expired.'));
+            $this->_redirect('*/*/forgotpassword');
+        }
+    }
+
+    /**
+     * Checks reset forgotten password token
+     *
+     * User is redirected on this action when he clicks on the corresponding link in password reset confirmation email.
+     *
+     */
+    public function resetPasswordAction()
+    {
+        try {
+            $customerId = (int)$this->getRequest()->getQuery("id");
+            $resetPasswordLinkToken = (string)$this->getRequest()->getQuery('token');
+
+            $this->_validateResetPasswordLinkToken($customerId, $resetPasswordLinkToken);
+            $this->_saveRestorePasswordParameters($customerId, $resetPasswordLinkToken)
+                ->_redirect('*/*/changeforgotten');
+
+        } catch (Exception $exception) {
+            $this->_getSession()->addError($this->_getHelper('customer')->__('Your password reset link has expired.'));
             $this->_redirect('*/*/forgotpassword');
         }
     }
@@ -768,15 +804,14 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
      */
     public function resetPasswordPostAction()
     {
-        $resetPasswordLinkToken = (string) $this->getRequest()->getQuery('token');
-        $customerId = (int) $this->getRequest()->getQuery('id');
-        $password = (string) $this->getRequest()->getPost('password');
-        $passwordConfirmation = (string) $this->getRequest()->getPost('confirmation');
+        list($customerId, $resetPasswordLinkToken) = $this->_getRestorePasswordParameters($this->_getSession());
+        $password = (string)$this->getRequest()->getPost('password');
+        $passwordConfirmation = (string)$this->getRequest()->getPost('confirmation');
 
         try {
             $this->_validateResetPasswordLinkToken($customerId, $resetPasswordLinkToken);
         } catch (Exception $exception) {
-            $this->_getSession()->addError( $this->_getHelper('customer')->__('Your password reset link has expired.'));
+            $this->_getSession()->addError($this->_getHelper('customer')->__('Your password reset link has expired.'));
             $this->_redirect('*/*/');
             return;
         }
@@ -800,10 +835,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             foreach ($errorMessages as $errorMessage) {
                 $this->_getSession()->addError($errorMessage);
             }
-            $this->_redirect('*/*/resetpassword', array(
-                'id' => $customerId,
-                'token' => $resetPasswordLinkToken
-            ));
+            $this->_redirect('*/*/changeforgotten');
             return;
         }
 
@@ -813,14 +845,15 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             $customer->setRpTokenCreatedAt(null);
             $customer->cleanPasswordsValidationData();
             $customer->save();
-            $this->_getSession()->addSuccess( $this->_getHelper('customer')->__('Your password has been updated.'));
+
+            $this->_getSession()->unsetData(self::TOKEN_SESSION_NAME);
+            $this->_getSession()->unsetData(self::CUSTOMER_ID_SESSION_NAME);
+
+            $this->_getSession()->addSuccess($this->_getHelper('customer')->__('Your password has been updated.'));
             $this->_redirect('*/*/login');
         } catch (Exception $exception) {
             $this->_getSession()->addException($exception, $this->__('Cannot save a new password.'));
-            $this->_redirect('*/*/resetpassword', array(
-                'id' => $customerId,
-                'token' => $resetPasswordLinkToken
-            ));
+            $this->_redirect('*/*/changeforgotten');
             return;
         }
     }
@@ -997,4 +1030,34 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
     {
         return  $this->_getHelper('customer/address')->isVatValidationEnabled($store);
     }
+
+    /**
+     * Get restore password params.
+     *
+     * @param Mage_Customer_Model_Session $session
+     * @return array array ($customerId, $resetPasswordToken)
+     */
+    protected function _getRestorePasswordParameters(Mage_Customer_Model_Session $session)
+    {
+        return array(
+            (int) $session->getData(self::CUSTOMER_ID_SESSION_NAME),
+            (string) $session->getData(self::TOKEN_SESSION_NAME)
+        );
+    }
+
+    /**
+     * Save restore password params to session.
+     *
+     * @param int $customerId
+     * @param  string $resetPasswordLinkToken
+     * @return $this
+     */
+    protected function _saveRestorePasswordParameters($customerId, $resetPasswordLinkToken)
+    {
+        $this->_getSession()
+            ->setData(self::CUSTOMER_ID_SESSION_NAME, $customerId)
+            ->setData(self::TOKEN_SESSION_NAME, $resetPasswordLinkToken);
+
+        return $this;
+    }
 }
diff --git app/code/core/Mage/Downloadable/Model/Product/Type.php app/code/core/Mage/Downloadable/Model/Product/Type.php
index 77b7792..c091970 100644
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
diff --git app/code/core/Mage/Eav/Model/Resource/Attribute/Collection.php app/code/core/Mage/Eav/Model/Resource/Attribute/Collection.php
index 42f9c8f..c412834 100644
--- app/code/core/Mage/Eav/Model/Resource/Attribute/Collection.php
+++ app/code/core/Mage/Eav/Model/Resource/Attribute/Collection.php
@@ -216,7 +216,9 @@ abstract class Mage_Eav_Model_Resource_Attribute_Collection
     public function addSystemHiddenFilter()
     {
         $field = '(CASE WHEN additional_table.is_system = 1 AND additional_table.is_visible = 0 THEN 1 ELSE 0 END)';
-        return $this->addFieldToFilter($field, 0);
+        $resultCondition = $this->_getConditionSql($field, 0);
+        $this->_select->where($resultCondition);
+        return $this;
     }
 
     /**
@@ -228,7 +230,8 @@ abstract class Mage_Eav_Model_Resource_Attribute_Collection
     {
         $field = '(CASE WHEN additional_table.is_system = 1 AND additional_table.is_visible = 0
             AND main_table.attribute_code != "' . self::EAV_CODE_PASSWORD_HASH . '" THEN 1 ELSE 0 END)';
-        $this->addFieldToFilter($field, 0);
+        $resultCondition = $this->_getConditionSql($field, 0);
+        $this->_select->where($resultCondition);
         return $this;
     }
 
diff --git app/code/core/Mage/Sales/Model/Resource/Order/Item/Collection.php app/code/core/Mage/Sales/Model/Resource/Order/Item/Collection.php
index 89ab719..0f8dfba 100644
--- app/code/core/Mage/Sales/Model/Resource/Order/Item/Collection.php
+++ app/code/core/Mage/Sales/Model/Resource/Order/Item/Collection.php
@@ -139,4 +139,17 @@ class Mage_Sales_Model_Resource_Order_Item_Collection extends Mage_Sales_Model_R
         }
         return $this;
     }
+
+    /**
+     * Filter only available items.
+     *
+     * @return Mage_Sales_Model_Resource_Order_Item_Collection
+     */
+    public function addAvailableFilter()
+    {
+        $fieldExpression = '(qty_shipped - qty_returned)';
+        $resultCondition = $this->_getConditionSql($fieldExpression, array("gt" => 0));
+        $this->getSelect()->where($resultCondition);
+        return $this;
+    }
 }
diff --git app/code/core/Mage/Sales/controllers/DownloadController.php app/code/core/Mage/Sales/controllers/DownloadController.php
index 6c50071..c76ed63 100644
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
@@ -176,7 +191,7 @@ class Mage_Sales_DownloadController extends Mage_Core_Controller_Front_Action
         }
 
         try {
-            $info = unserialize($option->getValue());
+            $info = Mage::helper('core/unserializeArray')->unserialize($option->getValue());
             $this->_downloadFileAction($info);
         } catch (Exception $e) {
             $this->_forward('noRoute');
diff --git app/code/core/Mage/SalesRule/Model/Resource/Coupon/Collection.php app/code/core/Mage/SalesRule/Model/Resource/Coupon/Collection.php
index e392fba..583c368 100644
--- app/code/core/Mage/SalesRule/Model/Resource/Coupon/Collection.php
+++ app/code/core/Mage/SalesRule/Model/Resource/Coupon/Collection.php
@@ -97,9 +97,9 @@ class Mage_SalesRule_Model_Resource_Coupon_Collection extends Mage_Core_Model_Re
     public function addIsUsedFilterCallback($collection, $column)
     {
         $filterValue = $column->getFilter()->getCondition();
-        $collection->addFieldToFilter(
-            $this->getConnection()->getCheckSql('main_table.times_used > 0', 1, 0),
-            array('eq' => $filterValue)
-        );
+
+        $fieldExpression = $this->getConnection()->getCheckSql('main_table.times_used > 0', 1, 0);
+        $resultCondition = $this->_getConditionSql($fieldExpression, array('eq' => $filterValue));
+        $collection->getSelect()->where($resultCondition);
     }
 }
diff --git app/design/adminhtml/default/default/layout/admin.xml app/design/adminhtml/default/default/layout/admin.xml
index 5813b7d..f3a195e 100644
--- app/design/adminhtml/default/default/layout/admin.xml
+++ app/design/adminhtml/default/default/layout/admin.xml
@@ -39,7 +39,18 @@
             <block type="adminhtml/template" name="adminhtml.permissions.user.roles.grid.js" template="permissions/user_roles_grid_js.phtml"/>
         </reference>
     </adminhtml_permissions_user_edit>
-
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
     <!-- admin acl roles grid page -->
     <adminhtml_permissions_role_index>
         <reference name="content">
diff --git app/design/frontend/base/default/layout/customer.xml app/design/frontend/base/default/layout/customer.xml
index 0b82186..8a85469 100644
--- app/design/frontend/base/default/layout/customer.xml
+++ app/design/frontend/base/default/layout/customer.xml
@@ -153,7 +153,7 @@ New customer registration
         </reference>
     </customer_account_forgotpassword>
 
-    <customer_account_resetpassword translate="label">
+    <customer_account_changeforgotten translate="label">
         <label>Reset a Password</label>
         <remove name="right"/>
         <remove name="left"/>
@@ -172,9 +172,9 @@ New customer registration
             </action>
         </reference>
         <reference name="content">
-            <block type="customer/account_resetpassword" name="resetPassword" template="customer/form/resetforgottenpassword.phtml"/>
+            <block type="customer/account_changeforgotten" name="changeForgottenPassword" template="customer/form/resetforgottenpassword.phtml"/>
         </reference>
-    </customer_account_resetpassword>
+    </customer_account_changeforgotten>
 
     <customer_account_confirmation>
         <remove name="right"/>
diff --git app/design/frontend/base/default/template/customer/form/register.phtml app/design/frontend/base/default/template/customer/form/register.phtml
index bd4e44a..ec20429 100644
--- app/design/frontend/base/default/template/customer/form/register.phtml
+++ app/design/frontend/base/default/template/customer/form/register.phtml
@@ -43,6 +43,7 @@
         <div class="fieldset">
             <input type="hidden" name="success_url" value="<?php echo $this->getSuccessUrl() ?>" />
             <input type="hidden" name="error_url" value="<?php echo $this->getErrorUrl() ?>" />
+            <input type="hidden" name="form_key" value="<?php echo Mage::getSingleton('core/session')->getFormKey() ?>" />
             <h2 class="legend"><?php echo $this->__('Personal Information') ?></h2>
             <ul class="form-list">
                 <li class="fields">
diff --git app/design/frontend/base/default/template/customer/form/resetforgottenpassword.phtml app/design/frontend/base/default/template/customer/form/resetforgottenpassword.phtml
index 3611957..691a96d 100644
--- app/design/frontend/base/default/template/customer/form/resetforgottenpassword.phtml
+++ app/design/frontend/base/default/template/customer/form/resetforgottenpassword.phtml
@@ -28,7 +28,7 @@
     <h1><?php echo $this->__('Reset a Password'); ?></h1>
 </div>
 <?php echo $this->getMessagesBlock()->toHtml(); ?>
-<form action="<?php echo $this->getUrl('*/*/resetpasswordpost', array('_query' => array('id' => $this->getCustomerId(), 'token' => $this->getResetPasswordLinkToken()))); ?>" method="post" id="form-validate">
+<form action="<?php echo $this->getUrl('*/*/resetpasswordpost'); ?>" method="post" id="form-validate">
     <div class="fieldset" style="margin-top: 70px;">
         <ul class="form-list">
             <li class="fields">
diff --git app/design/frontend/base/default/template/persistent/customer/form/register.phtml app/design/frontend/base/default/template/persistent/customer/form/register.phtml
index 275f4d2..ccd1ea1 100644
--- app/design/frontend/base/default/template/persistent/customer/form/register.phtml
+++ app/design/frontend/base/default/template/persistent/customer/form/register.phtml
@@ -42,6 +42,7 @@
         <div class="fieldset">
             <input type="hidden" name="success_url" value="<?php echo $this->getSuccessUrl() ?>" />
             <input type="hidden" name="error_url" value="<?php echo $this->getErrorUrl() ?>" />
+            <input type="hidden" name="form_key" value="<?php echo Mage::getSingleton('core/session')->getFormKey() ?>" />
             <h2 class="legend"><?php echo $this->__('Personal Information') ?></h2>
             <ul class="form-list">
                 <li class="fields">
diff --git app/design/frontend/default/iphone/layout/customer.xml app/design/frontend/default/iphone/layout/customer.xml
index dd384fc..2da07a4 100644
--- app/design/frontend/default/iphone/layout/customer.xml
+++ app/design/frontend/default/iphone/layout/customer.xml
@@ -141,7 +141,7 @@ New customer registration
         </reference>
     </customer_account_forgotpassword>
 
-    <customer_account_resetpassword translate="label">
+    <customer_account_changeforgotten translate="label">
         <label>Reset a Password</label>
         <remove name="right"/>
         <remove name="left"/>
@@ -160,9 +160,9 @@ New customer registration
             </action>
         </reference>
         <reference name="content">
-            <block type="customer/account_resetpassword" name="resetPassword" template="customer/form/resetforgottenpassword.phtml"/>
+            <block type="customer/account_changeforgotten" name="changeForgottenPassword" template="customer/form/resetforgottenpassword.phtml"/>
         </reference>
-    </customer_account_resetpassword>
+    </customer_account_changeforgotten>
 
     <customer_account_confirmation>
         <remove name="right"/>
diff --git app/design/frontend/default/modern/layout/customer.xml app/design/frontend/default/modern/layout/customer.xml
index fb94b09..42a6574 100644
--- app/design/frontend/default/modern/layout/customer.xml
+++ app/design/frontend/default/modern/layout/customer.xml
@@ -156,7 +156,7 @@ New customer registration
         </reference>
     </customer_account_forgotpassword>
 
-    <customer_account_resetpassword translate="label">
+    <customer_account_changeforgotten translate="label">
         <label>Reset a Password</label>
         <remove name="right"/>
         <remove name="left"/>
@@ -175,9 +175,9 @@ New customer registration
             </action>
         </reference>
         <reference name="content">
-            <block type="customer/account_resetpassword" name="resetPassword" template="customer/form/resetforgottenpassword.phtml"/>
+            <block type="customer/account_changeforgotten" name="changeForgottenPassword" template="customer/form/resetforgottenpassword.phtml"/>
         </reference>
-    </customer_account_resetpassword>
+    </customer_account_changeforgotten>
 
     <customer_account_confirmation>
         <remove name="right"/>
diff --git app/design/frontend/rwd/default/layout/customer.xml app/design/frontend/rwd/default/layout/customer.xml
index 271fc88..60deace 100644
--- app/design/frontend/rwd/default/layout/customer.xml
+++ app/design/frontend/rwd/default/layout/customer.xml
@@ -158,7 +158,7 @@ New customer registration
         </reference>
     </customer_account_forgotpassword>
 
-    <customer_account_resetpassword translate="label">
+    <customer_account_changeforgotten translate="label">
         <label>Reset a Password</label>
         <remove name="right"/>
         <remove name="left"/>
@@ -177,9 +177,9 @@ New customer registration
             </action>
         </reference>
         <reference name="content">
-            <block type="customer/account_resetpassword" name="resetPassword" template="customer/form/resetforgottenpassword.phtml"/>
+            <block type="customer/account_changeforgotten" name="changeForgottenPassword" template="customer/form/resetforgottenpassword.phtml"/>
         </reference>
-    </customer_account_resetpassword>
+    </customer_account_changeforgotten>
 
     <customer_account_confirmation>
         <remove name="right"/>
diff --git app/design/frontend/rwd/default/template/customer/form/resetforgottenpassword.phtml app/design/frontend/rwd/default/template/customer/form/resetforgottenpassword.phtml
index e7c05d9..79c186e 100644
--- app/design/frontend/rwd/default/template/customer/form/resetforgottenpassword.phtml
+++ app/design/frontend/rwd/default/template/customer/form/resetforgottenpassword.phtml
@@ -28,7 +28,7 @@
     <h1><?php echo $this->__('Reset a Password'); ?></h1>
 </div>
 <?php echo $this->getMessagesBlock()->toHtml(); ?>
-<form action="<?php echo $this->getUrl('*/*/resetpasswordpost', array('_query' => array('id' => $this->getCustomerId(), 'token' => $this->getResetPasswordLinkToken()))); ?>" method="post" id="form-validate" class="scaffold-form">
+<form action="<?php echo $this->getUrl('*/*/resetpasswordpost'); ?>" method="post" id="form-validate" class="scaffold-form">
     <div class="fieldset" style="margin-top: 70px;">
         <p class="required"><?php echo $this->__('* Required Fields'); ?></p>
         <ul class="form-list">
diff --git app/design/frontend/rwd/default/template/persistent/customer/form/register.phtml app/design/frontend/rwd/default/template/persistent/customer/form/register.phtml
index 8557051..04df755 100644
--- app/design/frontend/rwd/default/template/persistent/customer/form/register.phtml
+++ app/design/frontend/rwd/default/template/persistent/customer/form/register.phtml
@@ -42,6 +42,7 @@
         <div class="fieldset">
             <input type="hidden" name="success_url" value="<?php echo $this->getSuccessUrl() ?>" />
             <input type="hidden" name="error_url" value="<?php echo $this->getErrorUrl() ?>" />
+            <input type="hidden" name="form_key" value="<?php echo Mage::getSingleton('core/session')->getFormKey() ?>" />
             <p class="form-instructions"><?php echo $this->__('Please enter the following information to create your account.') ?></p>
             <p class="required"><?php echo $this->__('* Required Fields') ?></p>
             <ul class="form-list">
diff --git cron.php cron.php
index e191694..1e9ef3b 100644
--- cron.php
+++ cron.php
@@ -60,10 +60,11 @@ try {
                 Mage::throwException('Unrecognized cron mode was defined');
             }
         } else if (!$isShellDisabled) {
-            $fileName = basename(__FILE__);
-            $baseDir = dirname(__FILE__);
-            shell_exec("/bin/sh $baseDir/cron.sh $fileName -mdefault 1 > /dev/null 2>&1 &");
-            shell_exec("/bin/sh $baseDir/cron.sh $fileName -malways 1 > /dev/null 2>&1 &");
+            $fileName = escapeshellarg(basename(__FILE__));
+            $cronPath = escapeshellarg(dirname(__FILE__) . '/cron.sh');
+
+            shell_exec(escapeshellcmd("/bin/sh $cronPath $fileName -mdefault 1 > /dev/null 2>&1 &"));
+            shell_exec(escapeshellcmd("/bin/sh $cronPath $fileName -malways 1 > /dev/null 2>&1 &"));
             exit;
         }
     }
diff --git dev/tests/functional/.htaccess dev/tests/functional/.htaccess
deleted file mode 100644
index 0a28bda..0000000
--- dev/tests/functional/.htaccess
+++ /dev/null
@@ -1,194 +0,0 @@
-############################################
-## uncomment these lines for CGI mode
-## make sure to specify the correct cgi php binary file name
-## it might be /cgi-bin/php-cgi
-
-#    Action php5-cgi /cgi-bin/php5-cgi
-#    AddHandler php5-cgi .php
-
-############################################
-## GoDaddy specific options
-
-#   Options -MultiViews
-
-## you might also need to add this line to php.ini
-##     cgi.fix_pathinfo = 1
-## if it still doesn't work, rename php.ini to php5.ini
-
-############################################
-## this line is specific for 1and1 hosting
-
-    #AddType x-mapp-php5 .php
-    #AddHandler x-mapp-php5 .php
-
-############################################
-## default index file
-
-    DirectoryIndex index.php
-
-<IfModule mod_php5.c>
-
-############################################
-## adjust memory limit
-
-#    php_value memory_limit 64M
-    php_value memory_limit 256M
-    php_value max_execution_time 18000
-
-############################################
-## disable magic quotes for php request vars
-
-    php_flag magic_quotes_gpc off
-
-############################################
-## disable automatic session start
-## before autoload was initialized
-
-    php_flag session.auto_start off
-
-############################################
-## enable resulting html compression
-
-    #php_flag zlib.output_compression on
-
-###########################################
-# disable user agent verification to not break multiple image upload
-
-    php_flag suhosin.session.cryptua off
-
-###########################################
-# turn off compatibility with PHP4 when dealing with objects
-
-    php_flag zend.ze1_compatibility_mode Off
-
-</IfModule>
-
-<IfModule mod_security.c>
-###########################################
-# disable POST processing to not break multiple image upload
-
-    SecFilterEngine Off
-    SecFilterScanPOST Off
-</IfModule>
-
-<IfModule mod_deflate.c>
-
-############################################
-## enable apache served files compression
-## http://developer.yahoo.com/performance/rules.html#gzip
-
-    # Insert filter on all content
-    ###SetOutputFilter DEFLATE
-    # Insert filter on selected content types only
-    #AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript
-
-    # Netscape 4.x has some problems...
-    #BrowserMatch ^Mozilla/4 gzip-only-text/html
-
-    # Netscape 4.06-4.08 have some more problems
-    #BrowserMatch ^Mozilla/4\.0[678] no-gzip
-
-    # MSIE masquerades as Netscape, but it is fine
-    #BrowserMatch \bMSIE !no-gzip !gzip-only-text/html
-
-    # Don't compress images
-    #SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary
-
-    # Make sure proxies don't deliver the wrong content
-    #Header append Vary User-Agent env=!dont-vary
-
-</IfModule>
-
-<IfModule mod_ssl.c>
-
-############################################
-## make HTTPS env vars available for CGI mode
-
-    SSLOptions StdEnvVars
-
-</IfModule>
-
-<IfModule mod_rewrite.c>
-
-############################################
-## enable rewrites
-
-    Options +FollowSymLinks
-    RewriteEngine on
-
-############################################
-## you can put here your magento root folder
-## path relative to web root
-
-    #RewriteBase /magento/
-
-############################################
-## workaround for HTTP authorization
-## in CGI environment
-
-    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
-
-############################################
-## TRACE and TRACK HTTP methods disabled to prevent XSS attacks
-
-    RewriteCond %{REQUEST_METHOD} ^TRAC[EK]
-    RewriteRule .* - [L,R=405]
-
-############################################
-## redirect for mobile user agents
-
-    #RewriteCond %{REQUEST_URI} !^/mobiledirectoryhere/.*$
-    #RewriteCond %{HTTP_USER_AGENT} "android|blackberry|ipad|iphone|ipod|iemobile|opera mobile|palmos|webos|googlebot-mobile" [NC]
-    #RewriteRule ^(.*)$ /mobiledirectoryhere/ [L,R=302]
-
-############################################
-## never rewrite for existing files, directories and links
-
-    RewriteCond %{REQUEST_FILENAME} !-f
-    RewriteCond %{REQUEST_FILENAME} !-d
-    RewriteCond %{REQUEST_FILENAME} !-l
-
-############################################
-## rewrite everything else to index.php
-
-    RewriteRule .* index.php [L]
-
-</IfModule>
-
-
-############################################
-## Prevent character encoding issues from server overrides
-## If you still have problems, use the second line instead
-
-    AddDefaultCharset Off
-    #AddDefaultCharset UTF-8
-
-<IfModule mod_expires.c>
-
-############################################
-## Add default Expires header
-## http://developer.yahoo.com/performance/rules.html#expires
-
-    ExpiresDefault "access plus 1 year"
-
-</IfModule>
-
-############################################
-## By default allow all access
-
-    Order allow,deny
-    Allow from all
-
-###########################################
-## Deny access to release notes to prevent disclosure of the installed Magento version
-
-    <Files RELEASE_NOTES.txt>
-        order allow,deny
-        deny from all
-    </Files>
-
-############################################
-## If running in cluster environment, uncomment this
-## http://developer.yahoo.com/performance/rules.html#etags
-
-    #FileETag none
diff --git errors/processor.php errors/processor.php
index 5ae49e2..450bc68 100644
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
index fcd4d8d..6bb52e7 100644
--- lib/Varien/Data/Collection/Db.php
+++ lib/Varien/Data/Collection/Db.php
@@ -410,8 +410,14 @@ class Varien_Data_Collection_Db extends Varien_Data_Collection
      */
     protected function _translateCondition($field, $condition)
     {
-        $field = $this->_getMappedField($field);
-        return $this->_getConditionSql($field, $condition);
+        $mappedField = $this->_getMappedField($field);
+
+        $quotedField = $mappedField;
+        if ($mappedField === $field) {
+            $quotedField = $this->getConnection()->quoteIdentifier($field);
+        }
+
+        return $this->_getConditionSql($quotedField, $condition);
     }
 
     /**
@@ -474,7 +480,7 @@ class Varien_Data_Collection_Db extends Varien_Data_Collection
      * If non matched - sequential array is expected and OR conditions
      * will be built using above mentioned structure
      *
-     * @param string $fieldName
+     * @param string $fieldName Field name must be already escaped with Varien_Db_Adapter_Interface::quoteIdentifier()
      * @param integer|string|array $condition
      * @return string
      */
diff --git lib/Zend/Xml/Security.php lib/Zend/Xml/Security.php
index 29e55ca..dbcf1ec 100644
--- lib/Zend/Xml/Security.php
+++ lib/Zend/Xml/Security.php
@@ -34,13 +34,14 @@ class Zend_Xml_Security
      * Heuristic scan to detect entity in XML
      *
      * @param  string $xml
-     * @throws Zend_Xml_Exception
+     * @throws Zend_Xml_Exception If entity expansion or external entity declaration was discovered.
      */
     protected static function heuristicScan($xml)
     {
-        if (strpos($xml, '<!ENTITY') !== false) {
-            #require_once 'Exception.php';
-            throw new Zend_Xml_Exception(self::ENTITY_DETECT);
+        foreach (self::getEntityComparison($xml) as $compare) {
+            if (strpos($xml, $compare) !== false) {
+                throw new Zend_Xml_Exception(self::ENTITY_DETECT);
+            }
         }
     }
 
@@ -93,13 +94,12 @@ class Zend_Xml_Security
         $result = $dom->loadXml($xml, LIBXML_NONET);
         restore_error_handler();
 
-        // Entity load to previous setting
-        if (!self::isPhpFpm()) {
-            libxml_disable_entity_loader($loadEntities);
-            libxml_use_internal_errors($useInternalXmlErrors);
-        }
-
         if (!$result) {
+            // Entity load to previous setting
+            if (!self::isPhpFpm()) {
+                libxml_disable_entity_loader($loadEntities);
+                libxml_use_internal_errors($useInternalXmlErrors);
+            }
             return false;
         }
 
@@ -115,6 +115,12 @@ class Zend_Xml_Security
             }
         }
 
+        // Entity load to previous setting
+        if (!self::isPhpFpm()) {
+            libxml_disable_entity_loader($loadEntities);
+            libxml_use_internal_errors($useInternalXmlErrors);
+        }
+
         if (isset($simpleXml)) {
             $result = simplexml_import_dom($dom);
             if (!$result instanceof SimpleXMLElement) {
@@ -147,13 +153,336 @@ class Zend_Xml_Security
     /**
      * Return true if PHP is running with PHP-FPM
      *
+     * This method is mainly used to determine whether or not heuristic checks
+     * (vs libxml checks) should be made, due to threading issues in libxml;
+     * under php-fpm, threading becomes a concern.
+     *
+     * However, PHP versions 5.5.22+ and 5.6.6+ contain a patch to the
+     * libxml support in PHP that makes the libxml checks viable; in such
+     * versions, this method will return false to enforce those checks, which
+     * are more strict and accurate than the heuristic checks.
+     *
      * @return boolean
      */
     public static function isPhpFpm()
     {
-        if (substr(php_sapi_name(), 0, 3) === 'fpm') {
+        $isVulnerableVersion = (
+            version_compare(PHP_VERSION, '5.5.22', 'lt')
+            || (
+                version_compare(PHP_VERSION, '5.6', 'gte')
+                && version_compare(PHP_VERSION, '5.6.6', 'lt')
+            )
+        );
+
+        if (substr(php_sapi_name(), 0, 3) === 'fpm' && $isVulnerableVersion) {
             return true;
         }
         return false;
     }
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
 }
