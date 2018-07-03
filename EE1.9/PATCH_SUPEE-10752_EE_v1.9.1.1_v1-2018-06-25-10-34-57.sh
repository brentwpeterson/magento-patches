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


SUPEE-10752_EE_v1.9.1.1 | CE_1.4.2.0 | v1 | bdc6ac6016092f7394a3a1bb95e7bedcf964afca | Tue Jun 5 01:02:31 2018 +0300 | ee-1.9.1.1-dev

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Enterprise/CatalogEvent/Block/Adminhtml/Event/Edit/Category.php app/code/core/Enterprise/CatalogEvent/Block/Adminhtml/Event/Edit/Category.php
index e5402da5c70..d8ca5dcd554 100644
--- app/code/core/Enterprise/CatalogEvent/Block/Adminhtml/Event/Edit/Category.php
+++ app/code/core/Enterprise/CatalogEvent/Block/Adminhtml/Event/Edit/Category.php
@@ -91,7 +91,7 @@ class Enterprise_CatalogEvent_Block_Adminhtml_Event_Edit_Category extends Mage_A
 
     /**
      * Convert categories tree to array recursively
-     *
+     * @param $node
      * @return array
      */
     protected function _getNodesArray($node)
diff --git app/code/core/Enterprise/CatalogEvent/Block/Adminhtml/Event/Edit/Form.php app/code/core/Enterprise/CatalogEvent/Block/Adminhtml/Event/Edit/Form.php
index e8972bc4fbe..b348d00c715 100644
--- app/code/core/Enterprise/CatalogEvent/Block/Adminhtml/Event/Edit/Form.php
+++ app/code/core/Enterprise/CatalogEvent/Block/Adminhtml/Event/Edit/Form.php
@@ -157,12 +157,12 @@ class Enterprise_CatalogEvent_Block_Adminhtml_Event_Edit_Form extends Mage_Admin
             $form->getElement('category_name')->setText(
                 '<a href="' . Mage::helper('adminhtml')->getUrl('adminhtml/catalog_category/edit',
                                                             array('clear' => 1, 'id' => $currentCategory->getId()))
-                . '">' . $currentCategory->getName() . '</a>'
+                . '">' . $this->escapeHtml($currentCategory->getName()) . '</a>'
             );
         } else {
             $form->getElement('category_name')->setText(
                 '<a href="' . $this->getParentBlock()->getBackUrl()
-                . '">' . $currentCategory->getName() . '</a>'
+                . '">' . $this->escapeHtml($currentCategory->getName()) . '</a>'
             );
         }
 
diff --git app/code/core/Enterprise/CatalogEvent/Block/Adminhtml/Event/Grid.php app/code/core/Enterprise/CatalogEvent/Block/Adminhtml/Event/Grid.php
index 8e1d06eb82e..d55c16643c5 100644
--- app/code/core/Enterprise/CatalogEvent/Block/Adminhtml/Event/Grid.php
+++ app/code/core/Enterprise/CatalogEvent/Block/Adminhtml/Event/Grid.php
@@ -82,7 +82,8 @@ class Enterprise_CatalogEvent_Block_Adminhtml_Event_Grid extends Mage_Adminhtml_
         $this->addColumn('category', array(
             'header' => Mage::helper('enterprise_catalogevent')->__('Category'),
             'index' => 'category_name',
-            'type'  => 'text'
+            'type'  => 'text',
+            'escape' => true
         ));
 
         $this->addColumn('date_start', array(
diff --git app/code/core/Enterprise/GiftRegistry/Block/Adminhtml/Giftregistry/Edit/Attribute/Attribute.php app/code/core/Enterprise/GiftRegistry/Block/Adminhtml/Giftregistry/Edit/Attribute/Attribute.php
index 311e5c28302..46f6a3cc5eb 100644
--- app/code/core/Enterprise/GiftRegistry/Block/Adminhtml/Giftregistry/Edit/Attribute/Attribute.php
+++ app/code/core/Enterprise/GiftRegistry/Block/Adminhtml/Giftregistry/Edit/Attribute/Attribute.php
@@ -272,6 +272,7 @@ class Enterprise_GiftRegistry_Block_Adminhtml_Giftregistry_Edit_Attribute_Attrib
             $value['code'] = $code;
             $value['id'] = $innerId;
             $value['prefix'] = $this->getFieldPrefix();
+            $value['group'] = $this->escapeHtml($value['group']);
 
             if ($this->getType()->getStoreId() != '0') {
                 $value['checkbox_scope'] = $this->getCheckboxScopeHtml($innerId, 'label', !isset($value['default_label']));
diff --git app/code/core/Enterprise/GiftRegistry/Model/Attribute/Processor.php app/code/core/Enterprise/GiftRegistry/Model/Attribute/Processor.php
index 2782c24e1fc..f64eb615bf6 100644
--- app/code/core/Enterprise/GiftRegistry/Model/Attribute/Processor.php
+++ app/code/core/Enterprise/GiftRegistry/Model/Attribute/Processor.php
@@ -46,14 +46,22 @@ class Enterprise_GiftRegistry_Model_Attribute_Processor extends Mage_Core_Model_
             $typeXml = $xmlObj->addChild(self::XML_PROTOTYPE_NODE);
             if (is_array($data)) {
                 $groups = array();
+                $attribute_groups = Mage::getSingleton('enterprise_giftregistry/attribute_config')
+                    ->getAttributeGroups();
                 foreach ($data as $attributes) {
                     foreach ($attributes as $attribute) {
-                        if ($attribute['group'] == self::XML_REGISTRANT_NODE) {
-                            $group = self::XML_REGISTRANT_NODE;
+                        if (array_key_exists($attribute['group'], $attribute_groups)) {
+                            if ($attribute['group'] == self::XML_REGISTRANT_NODE) {
+                                $group = self::XML_REGISTRANT_NODE;
+                            } else {
+                                $group = self::XML_REGISTRY_NODE;
+                            }
+                            $groups[$group][$attribute['code']] = $attribute;
                         } else {
-                            $group = self::XML_REGISTRY_NODE;
+                            Mage::throwException(
+                                Mage::helper('enterprise_giftregistry')->__('Failed to save gift registry.')
+                            );
                         }
-                        $groups[$group][$attribute['code']] = $attribute;
                     }
                 }
                 foreach ($groups as $group => $attributes) {
diff --git app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/Grid.php app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/Grid.php
index 5b53fe6ebf6..5e0fc12c0db 100644
--- app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/Grid.php
+++ app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/Grid.php
@@ -82,12 +82,14 @@ class Enterprise_Invitation_Block_Adminhtml_Invitation_Grid extends Mage_Adminht
 
         $renderer = (Mage::getSingleton('admin/session')->isAllowed('customer/manage'))
             ? 'enterprise_invitation/adminhtml_invitation_grid_column_invitee' : false;
+        $escape = !$renderer ? true : false;
 
         $this->addColumn('invitee', array(
             'header' => Mage::helper('enterprise_invitation')->__('Invitee'),
             'index'  => 'invitee_email',
             'type'   => 'text',
             'renderer' => $renderer,
+            'escape' => $escape
         ));
 
         $this->addColumn('date', array(
diff --git app/code/core/Enterprise/Logging/Block/Adminhtml/Details/Renderer/Diff.php app/code/core/Enterprise/Logging/Block/Adminhtml/Details/Renderer/Diff.php
index 026e982e0ce..98fd1959ca6 100644
--- app/code/core/Enterprise/Logging/Block/Adminhtml/Details/Renderer/Diff.php
+++ app/code/core/Enterprise/Logging/Block/Adminhtml/Details/Renderer/Diff.php
@@ -64,7 +64,7 @@ class Enterprise_Logging_Block_Adminhtml_Details_Renderer_Diff
                 if (!$specialFlag) {
                     $html = '<dl>';
                     foreach ($dataArray as $key => $value) {
-                        $html .= '<dt>' . $key . '</dt><dd>' . $this->htmlEscape($value) . '</dd>';
+                        $html .= '<dt>' . $this->escapeHtml($key) . '</dt><dd>' . $this->escapeHtml($value) . '</dd>';
                     }
                     $html .= '</dl>';
                 }
diff --git app/code/core/Enterprise/Reward/Block/Adminhtml/Customer/Edit/Tab/Reward/History/Grid/Column/Renderer/Reason.php app/code/core/Enterprise/Reward/Block/Adminhtml/Customer/Edit/Tab/Reward/History/Grid/Column/Renderer/Reason.php
index e2f02b381b9..fd3eb50b613 100644
--- app/code/core/Enterprise/Reward/Block/Adminhtml/Customer/Edit/Tab/Reward/History/Grid/Column/Renderer/Reason.php
+++ app/code/core/Enterprise/Reward/Block/Adminhtml/Customer/Edit/Tab/Reward/History/Grid/Column/Renderer/Reason.php
@@ -43,6 +43,6 @@ class Enterprise_Reward_Block_Adminhtml_Customer_Edit_Tab_Reward_History_Grid_Co
         if ($row->getData('is_duplicate_of') !== null) {
              $expired = '<em>' . Mage::helper('enterprise_reward')->__('Expired reward.') . '</em> ';
         }
-        return $expired . (parent::_getValue($row));
+        return $expired . $this->escapeHtml(parent::_getValue($row));
     }
 }
diff --git app/code/core/Enterprise/TargetRule/Model/Rule.php app/code/core/Enterprise/TargetRule/Model/Rule.php
index ac4203a9c0f..b9735671255 100644
--- app/code/core/Enterprise/TargetRule/Model/Rule.php
+++ app/code/core/Enterprise/TargetRule/Model/Rule.php
@@ -281,8 +281,13 @@ class Enterprise_TargetRule_Model_Rule extends Mage_Rule_Model_Rule
     public function getActionSelectBind()
     {
         $bind = $this->getData('action_select_bind');
-        if (!is_null($bind) && !is_array($bind)) {
-            $bind = unserialize($bind);
+        if ($bind && is_string($bind)) {
+            try {
+                $bind = Mage::helper('core/unserializeArray')->unserialize($bind);
+            } catch (Exception $e) {
+                $bind = array();
+                Mage::logException(new Exception("action_select_bind must be serialized array.", 0));
+            }
         }
 
         return $bind;
diff --git app/code/core/Enterprise/TargetRule/controllers/Adminhtml/TargetruleController.php app/code/core/Enterprise/TargetRule/controllers/Adminhtml/TargetruleController.php
index 2cbd244adde..669ee41a827 100644
--- app/code/core/Enterprise/TargetRule/controllers/Adminhtml/TargetruleController.php
+++ app/code/core/Enterprise/TargetRule/controllers/Adminhtml/TargetruleController.php
@@ -138,6 +138,8 @@ class Enterprise_TargetRule_Adminhtml_TargetRuleController extends Mage_Adminhtm
         $data = $this->getRequest()->getPost();
         $data = $this->_filterDates($data, array('from_date', 'to_date'));
 
+        unset($data['action_select_bind']);
+
         if ($this->getRequest()->isPost() && $data) {
             /* @var $model Enterprise_TargetRule_Model_Rule */
             $model          = Mage::getModel('enterprise_targetrule/rule');
diff --git app/code/core/Mage/Admin/Model/User.php app/code/core/Mage/Admin/Model/User.php
index 4a1fe704943..46aa95e4173 100644
--- app/code/core/Mage/Admin/Model/User.php
+++ app/code/core/Mage/Admin/Model/User.php
@@ -80,6 +80,10 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
 
         if ($this->getNewPassword()) { // change password
             $data['password'] = $this->_getEncodedPassword($this->getNewPassword());
+            $sessionUser = $this->getSession()->getUser();
+            if ($sessionUser && $sessionUser->getId() == $this->getId()) {
+                $this->getSession()->setUserPasswordChanged(true);
+            }
         } elseif ($this->getPassword() && $this->getPassword() != $this->getOrigData('password')) { // new user password
             $data['password'] = $this->_getEncodedPassword($this->getPassword());
         }
@@ -93,6 +97,14 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
         return parent::_beforeSave();
     }
 
+    /**
+     * @return Mage_Admin_Model_Session
+     */
+    protected function getSession()
+    {
+        return  Mage::getSingleton('admin/session');
+    }
+
     /**
      * Save admin user extra data (like configuration sections state)
      *
@@ -278,8 +290,15 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
     public function reload()
     {
         $id = $this->getId();
+        $oldPassword = $this->getPassword();
         $this->setId(null);
         $this->load($id);
+        $isUserPasswordChanged = $this->getSession()->getUserPasswordChanged();
+        if ($this->getPassword() !== $oldPassword && !$isUserPasswordChanged) {
+            $this->setId(null);
+        } elseif ($isUserPasswordChanged) {
+            $this->getSession()->setUserPasswordChanged(false);
+        }
         return $this;
     }
 
diff --git app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Options/Option.php app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Options/Option.php
index 3f38ed0763e..d2420bea7b6 100644
--- app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Options/Option.php
+++ app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Options/Option.php
@@ -247,7 +247,7 @@ class Mage_Adminhtml_Block_Catalog_Product_Edit_Tab_Options_Option extends Mage_
                     $value['price_type'] = $option->getPriceType();
                     $value['sku'] = $this->htmlEscape($option->getSku());
                     $value['max_characters'] = $option->getMaxCharacters();
-                    $value['file_extension'] = $option->getFileExtension();
+                    $value['file_extension'] = $this->escapeHtml($option->getFileExtension());
                     $value['image_size_x'] = $option->getImageSizeX();
                     $value['image_size_y'] = $option->getImageSizeY();
                     if ($this->getProduct()->getStoreId() != '0' && $scope == Mage_Core_Model_Store::PRICE_SCOPE_WEBSITE) {
diff --git app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Datetime.php app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Datetime.php
index 016e0a5a5ab..8a524f4a4c9 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Datetime.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Filter/Datetime.php
@@ -152,10 +152,9 @@ class Mage_Adminhtml_Block_Widget_Grid_Column_Filter_Datetime extends Mage_Admin
             if ($value instanceof Zend_Date) {
                 return $value->toString($this->getLocale()->getDateTimeFormat(Mage_Core_Model_Locale::FORMAT_TYPE_SHORT));
             }
-            return $value;
+            return $this->escapeHtml($value);
         }
 
-        return parent::getEscapedValue($index);
+        return $this->escapeHtml(parent::getEscapedValue($index));
     }
-
 }
diff --git app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
new file mode 100644
index 00000000000..79979b29429
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
@@ -0,0 +1,171 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
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
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @copyright Copyright (c) 2006-2018 Magento, Inc. (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+
+/**
+ * Validator for custom layout update
+ *
+ * Validator checked XML validation and protected expressions
+ *
+ * @category   Mage
+ * @package    Mage_Adminhtml
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
+{
+    const XML_INVALID                             = 'invalidXml';
+    const INVALID_TEMPLATE_PATH                   = 'invalidTemplatePath';
+    const PROTECTED_ATTR_HELPER_IN_TAG_ACTION_VAR = 'protectedAttrHelperInActionVar';
+
+    /**
+     * The Varien SimpleXml object
+     *
+     * @var Varien_Simplexml_Element
+     */
+    protected $_value;
+
+    /**
+     * XPath expression for checking layout update
+     *
+     * @var array
+     */
+    protected $_disallowedXPathExpressions = array(
+        '*//template',
+        '*//@template',
+        '//*[@method=\'setTemplate\']',
+        '//*[@method=\'setDataUsingMethod\']//*[text() = \'template\']/../*'
+    );
+
+    /**
+     * Protected expressions
+     *
+     * @var array
+     */
+    protected $_protectedExpressions = array(
+        self::PROTECTED_ATTR_HELPER_IN_TAG_ACTION_VAR => '//action/*[@helper]',
+    );
+
+    /**
+     * Construct
+     */
+    public function __construct()
+    {
+        $this->_initMessageTemplates();
+    }
+
+    /**
+     * Initialize messages templates with translating
+     *
+     * @return Mage_Adminhtml_Model_LayoutUpdate_Validator
+     */
+    protected function _initMessageTemplates()
+    {
+        if (!$this->_messageTemplates) {
+            $this->_messageTemplates = array(
+                self::PROTECTED_ATTR_HELPER_IN_TAG_ACTION_VAR =>
+                    Mage::helper('adminhtml')->__('Helper attributes should not be used in custom layout updates.'),
+                self::XML_INVALID => Mage::helper('adminhtml')->__('XML data is invalid.'),
+                self::INVALID_TEMPLATE_PATH => Mage::helper('adminhtml')->__(
+                    'Invalid template path used in layout update.'
+                ),
+            );
+        }
+        return $this;
+    }
+
+    /**
+     * Returns true if and only if $value meets the validation requirements
+     *
+     * If $value fails validation, then this method returns false, and
+     * getMessages() will return an array of messages that explain why the
+     * validation failed.
+     *
+     * @throws Exception            Throw exception when xml object is not
+     *                              instance of Varien_Simplexml_Element
+     * @param Varien_Simplexml_Element|string $value
+     * @return bool
+     */
+    public function isValid($value)
+    {
+        if (is_string($value)) {
+            $value = trim($value);
+            try {
+                //wrap XML value in the "config" tag because config cannot
+                //contain multiple root tags
+                $value = new Varien_Simplexml_Element('<config>' . $value . '</config>');
+            } catch (Exception $e) {
+                $this->_error(self::XML_INVALID);
+                return false;
+            }
+        } elseif (!($value instanceof Varien_Simplexml_Element)) {
+            throw new Exception(
+                Mage::helper('adminhtml')->__('XML object is not instance of "Varien_Simplexml_Element".'));
+        }
+
+        // if layout update declare custom templates then validate their paths
+        if ($templatePaths = $value->xpath($this->_getXpathValidationExpression())) {
+            try {
+                $this->_validateTemplatePath($templatePaths);
+            } catch (Exception $e) {
+                $this->_error(self::INVALID_TEMPLATE_PATH);
+                return false;
+            }
+        }
+        $this->_setValue($value);
+
+        foreach ($this->_protectedExpressions as $key => $xpr) {
+            if ($this->_value->xpath($xpr)) {
+                $this->_error($key);
+                return false;
+            }
+        }
+        return true;
+    }
+
+    /**
+     * Returns xPath for validate incorrect path to template
+     *
+     * @return string xPath for validate incorrect path to template
+     */
+    protected function _getXpathValidationExpression() {
+        return implode(" | ", $this->_disallowedXPathExpressions);
+    }
+
+    /**
+     * Validate template path for preventing access to the directory above
+     * If template path value has "../" @throws Exception
+     *
+     * @param $templatePaths | array
+     */
+    protected function _validateTemplatePath(array $templatePaths)
+    {
+        foreach ($templatePaths as $path) {
+            if (strpos($path, '..' . DS) !== false) {
+                throw new Exception();
+            }
+        }
+    }
+}
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/CategoryController.php app/code/core/Mage/Adminhtml/controllers/Catalog/CategoryController.php
index 7147298e150..9739b2c5503 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/CategoryController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/CategoryController.php
@@ -258,6 +258,9 @@ class Mage_Adminhtml_Catalog_CategoryController extends Mage_Adminhtml_Controlle
         $storeId = $this->getRequest()->getParam('store');
         $refreshTree = 'false';
         if ($data = $this->getRequest()->getPost()) {
+            if (isset($data['general']['path'])) {
+                unset($data['general']['path']);
+            }
             $category->addData($data['general']);
             if (!$category->getId()) {
                 $parentId = $this->getRequest()->getParam('parent');
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
index d641f12bf5f..99311a5af23 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
@@ -683,6 +683,7 @@ class Mage_Adminhtml_Catalog_ProductController extends Mage_Adminhtml_Controller
             }
 
             try {
+                $product->validate();
                 $product->save();
                 $productId = $product->getId();
 
diff --git app/code/core/Mage/Adminhtml/controllers/Cms/PageController.php app/code/core/Mage/Adminhtml/controllers/Cms/PageController.php
index 7f0ff030485..9c79de3c8e4 100644
--- app/code/core/Mage/Adminhtml/controllers/Cms/PageController.php
+++ app/code/core/Mage/Adminhtml/controllers/Cms/PageController.php
@@ -133,6 +133,12 @@ class Mage_Adminhtml_Cms_PageController extends Mage_Adminhtml_Controller_Action
 
             Mage::dispatchEvent('cms_page_prepare_save', array('page' => $model, 'request' => $this->getRequest()));
 
+            //validating
+            if (!$this->_validatePostData($data)) {
+                $this->_redirect('*/*/edit', array('page_id' => $model->getId(), '_current' => true));
+                return;
+            }
+
             // try to save it
             try {
                 // save the data
@@ -234,4 +240,30 @@ class Mage_Adminhtml_Cms_PageController extends Mage_Adminhtml_Controller_Action
         $data = $this->_filterDates($data, array('custom_theme_from', 'custom_theme_to'));
         return $data;
     }
+
+    /**
+     * Validate post data
+     *
+     * @param array $data
+     * @return bool     Return FALSE if someone item is invalid
+     */
+    protected function _validatePostData($data)
+    {
+        $errorNo = true;
+        if (!empty($data['layout_update_xml']) || !empty($data['custom_layout_update_xml'])) {
+            /** @var $validatorCustomLayout Mage_Adminhtml_Model_LayoutUpdate_Validator */
+            $validatorCustomLayout = Mage::getModel('adminhtml/layoutUpdate_validator');
+            if (!empty($data['layout_update_xml']) && !$validatorCustomLayout->isValid($data['layout_update_xml'])) {
+                $errorNo = false;
+            }
+            if (!empty($data['custom_layout_update_xml'])
+                && !$validatorCustomLayout->isValid($data['custom_layout_update_xml'])) {
+                $errorNo = false;
+            }
+            foreach ($validatorCustomLayout->getMessages() as $message) {
+                $this->_getSession()->addError($message);
+            }
+        }
+        return $errorNo;
+    }
 }
diff --git app/code/core/Mage/Adminhtml/controllers/Cms/Wysiwyg/ImagesController.php app/code/core/Mage/Adminhtml/controllers/Cms/Wysiwyg/ImagesController.php
index e80004a90f3..aa38af5d288 100644
--- app/code/core/Mage/Adminhtml/controllers/Cms/Wysiwyg/ImagesController.php
+++ app/code/core/Mage/Adminhtml/controllers/Cms/Wysiwyg/ImagesController.php
@@ -174,7 +174,11 @@ class Mage_Adminhtml_Cms_Wysiwyg_ImagesController extends Mage_Adminhtml_Control
         if ($thumb !== false) {
             $image = Varien_Image_Adapter::factory('GD2');
             $image->open($thumb);
+            $this->getResponse()->setHeader('Content-type', $image->getMimeTypeWithOutFileType());
+            ob_start();
             $image->display();
+            $this->getResponse()->setBody(ob_get_contents());
+            ob_end_clean();
         } else {
             // todo: genearte some placeholder
         }
diff --git app/code/core/Mage/Adminhtml/controllers/Cms/WysiwygController.php app/code/core/Mage/Adminhtml/controllers/Cms/WysiwygController.php
index 18ac6aec983..9b322c2082d 100644
--- app/code/core/Mage/Adminhtml/controllers/Cms/WysiwygController.php
+++ app/code/core/Mage/Adminhtml/controllers/Cms/WysiwygController.php
@@ -47,22 +47,15 @@ class Mage_Adminhtml_Cms_WysiwygController extends Mage_Adminhtml_Controller_Act
         try {
             $image = Varien_Image_Adapter::factory('GD2');
             $image->open($url);
-            $image->display();
         } catch (Exception $e) {
             $image = Varien_Image_Adapter::factory('GD2');
             $image->open(Mage::getSingleton('cms/wysiwyg_config')->getSkinImagePlaceholderUrl());
-            $image->display();
-            /*
-            $image = imagecreate(100, 100);
-            $bkgrColor = imagecolorallocate($image,10,10,10);
-            imagefill($image,0,0,$bkgrColor);
-            $textColor = imagecolorallocate($image,255,255,255);
-            imagestring($image, 4, 10, 10, 'Skin image', $textColor);
-            header('Content-type: image/png');
-            imagepng($image);
-            imagedestroy($image);
-            */
         }
+        $this->getResponse()->setHeader('Content-type', $image->getMimeTypeWithOutFileType());
+        ob_start();
+        $image->display();
+        $this->getResponse()->setBody(ob_get_contents());
+        ob_end_clean();
     }
 
     /**
diff --git app/code/core/Mage/Adminhtml/controllers/CustomerController.php app/code/core/Mage/Adminhtml/controllers/CustomerController.php
index 137b1cf3777..87acdb168b7 100644
--- app/code/core/Mage/Adminhtml/controllers/CustomerController.php
+++ app/code/core/Mage/Adminhtml/controllers/CustomerController.php
@@ -298,6 +298,7 @@ class Mage_Adminhtml_CustomerController extends Mage_Adminhtml_Controller_Action
                 // force new customer active
                 if ($isNewCustomer) {
                     $customer->setPassword($data['account']['password']);
+                    $customer->setPasswordCreatedAt(time());
                     $customer->setForceConfirmed(true);
                     if ($customer->getPassword() == 'auto') {
                         $sendPassToEmail = true;
diff --git app/code/core/Mage/Adminhtml/controllers/System/StoreController.php app/code/core/Mage/Adminhtml/controllers/System/StoreController.php
index e21f7b48549..b8f16b1b698 100644
--- app/code/core/Mage/Adminhtml/controllers/System/StoreController.php
+++ app/code/core/Mage/Adminhtml/controllers/System/StoreController.php
@@ -33,6 +33,16 @@
  */
 class Mage_Adminhtml_System_StoreController extends Mage_Adminhtml_Controller_Action
 {
+   /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions(array('deleteWebsitePost', 'deleteGroupPost', 'deleteStorePost'));
+        return parent::preDispatch();
+    }
 
     /**
      * Init actions
diff --git app/code/core/Mage/Bundle/Block/Catalog/Product/View/Type/Bundle/Option.php app/code/core/Mage/Bundle/Block/Catalog/Product/View/Type/Bundle/Option.php
index ac71148bf3d..e209b5bf7f2 100644
--- app/code/core/Mage/Bundle/Block/Catalog/Product/View/Type/Bundle/Option.php
+++ app/code/core/Mage/Bundle/Block/Catalog/Product/View/Type/Bundle/Option.php
@@ -45,7 +45,7 @@ class Mage_Bundle_Block_Catalog_Product_View_Type_Bundle_Option extends Mage_Bun
     public function getSelectionQtyTitlePrice($_selection, $includeContainer = true)
     {
         $price = $this->getProduct()->getPriceModel()->getSelectionPreFinalPrice($this->getProduct(), $_selection);
-        return $_selection->getSelectionQty()*1 . ' x ' . $_selection->getName() . ' &nbsp; ' .
+        return $_selection->getSelectionQty()*1 . ' x ' . $this->escapeHtml($_selection->getName()) . ' &nbsp; ' .
             ($includeContainer ? '<span class="price-notice">':'') . '+' .
             $this->formatPriceString($price, $includeContainer) . ($includeContainer ? '</span>':'');
     }
diff --git app/code/core/Mage/Catalog/Model/Product.php app/code/core/Mage/Catalog/Model/Product.php
index a67d500bbe6..bd320f39519 100644
--- app/code/core/Mage/Catalog/Model/Product.php
+++ app/code/core/Mage/Catalog/Model/Product.php
@@ -422,6 +422,8 @@ class Mage_Catalog_Model_Product extends Mage_Catalog_Model_Abstract
 
     /**
      * Check product options and type options and save them, too
+     *
+     * @throws Mage_Core_Exception
      */
     protected function _beforeSave()
     {
@@ -447,6 +449,12 @@ class Mage_Catalog_Model_Product extends Mage_Catalog_Model_Abstract
                 foreach ($this->getProductOptions() as $option) {
                     $this->getOptionInstance()->addOption($option);
                     if ((!isset($option['is_delete'])) || $option['is_delete'] != '1') {
+                        if (!empty($option['file_extension'])) {
+                            $fileExtension = $option['file_extension'];
+                            if (0 !== strcmp($fileExtension, Mage::helper('core')->removeTags($fileExtension))) {
+                                Mage::throwException(Mage::helper('catalog')->__('Invalid custom option(s).'));
+                            }
+                        }
                         $hasOptions = true;
                     }
                 }
diff --git app/code/core/Mage/Catalog/Model/Resource/Eav/Mysql4/Category/Tree.php app/code/core/Mage/Catalog/Model/Resource/Eav/Mysql4/Category/Tree.php
index de12cede44b..38e61e1328c 100644
--- app/code/core/Mage/Catalog/Model/Resource/Eav/Mysql4/Category/Tree.php
+++ app/code/core/Mage/Catalog/Model/Resource/Eav/Mysql4/Category/Tree.php
@@ -426,6 +426,9 @@ class Mage_Catalog_Model_Resource_Eav_Mysql4_Category_Tree extends Varien_Data_T
             ->where(sprintf('entity_id IN (%s)', implode(', ', $ids)));
         $where = array('`level`=0' => true);
         foreach ($this->_conn->fetchAll($select) as $item) {
+            if (!preg_match("#^[0-9\/]+$#", $item['path'])) {
+                $item['path'] = '';
+            }
             $path  = explode('/', $item['path']);
             $level = (int)$item['level'];
             while ($level > 0) {
diff --git app/code/core/Mage/Checkout/Model/Type/Onepage.php app/code/core/Mage/Checkout/Model/Type/Onepage.php
index e8f92bd1b4f..995b05afc4a 100644
--- app/code/core/Mage/Checkout/Model/Type/Onepage.php
+++ app/code/core/Mage/Checkout/Model/Type/Onepage.php
@@ -633,6 +633,9 @@ class Mage_Checkout_Model_Type_Onepage
         Mage::helper('core')->copyFieldset('checkout_onepage_quote', 'to_customer', $quote, $customer);
         $customer->setPassword($customer->decryptPassword($quote->getPasswordHash()));
         $customer->setPasswordHash($customer->hashPassword($customer->getPassword()));
+        $passwordCreatedTime = $this->_checkoutSession->getData('_session_validator_data')['session_expire_timestamp']
+            - Mage::getSingleton('core/cookie')->getLifetime();
+        $customer->setPasswordCreatedAt($passwordCreatedTime);
         $quote->setCustomer($customer)
             ->setCustomerId(true);
     }
diff --git app/code/core/Mage/Core/Helper/Abstract.php app/code/core/Mage/Core/Helper/Abstract.php
index 9293b450692..e2d76dd7962 100644
--- app/code/core/Mage/Core/Helper/Abstract.php
+++ app/code/core/Mage/Core/Helper/Abstract.php
@@ -227,6 +227,19 @@ abstract class Mage_Core_Helper_Abstract
         return $result;
     }
 
+    /**
+     * Remove html tags, but leave "<" and ">" signs
+     *
+     * @param   string $html
+     * @return  string
+     */
+    public function removeTags($html)
+    {
+        $html = preg_replace("# <(?![/a-z]) | (?<=\s)>(?![a-z]) #exi", "htmlentities('$0')", $html);
+        $html =  strip_tags($html);
+        return htmlspecialchars_decode($html);
+    }
+
     /**
      * Wrapper for standart strip_tags() function with extra functionality for html entities
      *
diff --git app/code/core/Mage/Core/Helper/Http.php app/code/core/Mage/Core/Helper/Http.php
index e4b52bd1362..d574af672d0 100644
--- app/code/core/Mage/Core/Helper/Http.php
+++ app/code/core/Mage/Core/Helper/Http.php
@@ -131,7 +131,7 @@ class Mage_Core_Helper_Http extends Mage_Core_Helper_Abstract
         if (is_null($this->_remoteAddr)) {
             $headers = $this->getRemoteAddrHeaders();
             foreach ($headers as $var) {
-                if ($this->_getRequest()->getServer($var, false)) {
+                if ($var != 'REMOTE_ADDR' && $this->_getRequest()->getServer($var, false)) {
                     $this->_remoteAddr = $_SERVER[$var];
                     break;
                 }
@@ -146,6 +146,11 @@ class Mage_Core_Helper_Http extends Mage_Core_Helper_Abstract
             return false;
         }
 
+        if (strpos($this->_remoteAddr, ',') !== false) {
+            $ipList = explode(',', $this->_remoteAddr);
+            $this->_remoteAddr = trim(reset($ipList));
+        }
+
         return $ipToLong ? ip2long($this->_remoteAddr) : $this->_remoteAddr;
     }
 
diff --git app/code/core/Mage/Core/Model/Session/Abstract/Varien.php app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
index 34d36efd41f..66e17cb1711 100644
--- app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
+++ app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
@@ -33,6 +33,7 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
     const VALIDATOR_HTTP_VIA_KEY                = 'http_via';
     const VALIDATOR_REMOTE_ADDR_KEY             = 'remote_addr';
     const VALIDATOR_SESSION_EXPIRE_TIMESTAMP    = 'session_expire_timestamp';
+    const VALIDATOR_PASSWORD_CREATE_TIMESTAMP   = 'password_create_timestamp';
 
     /**
      * Conigure and start session
@@ -324,6 +325,16 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
         return $this->getCookie()->getLifetime() > 0;
     }
 
+    /**
+     * Use password creation timestamp in validator key
+     *
+     * @return bool
+     */
+    public function useValidateSessionPasswordTimestamp()
+    {
+        return true;
+    }
+
     /**
      * Retrieve skip User Agent validation strings (Flash etc)
      *
@@ -395,6 +406,14 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
             $this->_data[self::VALIDATOR_KEY][self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP]
                 = $validatorData[self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP];
         }
+        if ($this->useValidateSessionPasswordTimestamp()
+            && isset($validatorData[self::VALIDATOR_PASSWORD_CREATE_TIMESTAMP])
+            && isset($sessionData[self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP])
+            && $validatorData[self::VALIDATOR_PASSWORD_CREATE_TIMESTAMP]
+            > $sessionData[self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP] - $this->getCookie()->getLifetime()
+        ) {
+            return false;
+        }
 
         return true;
     }
@@ -431,6 +450,11 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
 
         $parts[self::VALIDATOR_SESSION_EXPIRE_TIMESTAMP] = time() + $this->getCookie()->getLifetime();
 
+        if (isset($this->_data['visitor_data']['customer_id'])) {
+            $parts[self::VALIDATOR_PASSWORD_CREATE_TIMESTAMP] =
+                Mage::helper('customer')->getPasswordTimestamp($this->_data['visitor_data']['customer_id']);
+        }
+
         return $parts;
     }
 
diff --git app/code/core/Mage/Customer/Helper/Data.php app/code/core/Mage/Customer/Helper/Data.php
index e64f7da5953..d99fe64cc12 100644
--- app/code/core/Mage/Customer/Helper/Data.php
+++ app/code/core/Mage/Customer/Helper/Data.php
@@ -257,6 +257,23 @@ class Mage_Customer_Helper_Data extends Mage_Core_Helper_Abstract
         return $this->_getUrl('customer/account/confirmation', array('email' => $email));
     }
 
+    /**
+     * Get customer password creation timestamp or customer account creation timestamp
+     *
+     * @param $customerId
+     * @return int
+     */
+    public function getPasswordTimestamp($customerId)
+    {
+        /** @var $customer Mage_Customer_Model_Customer */
+        $customer = Mage::getModel('customer/customer')
+            ->setWebsiteId(Mage::app()->getStore()->getWebsiteId())
+            ->load((int)$customerId);
+        $passwordCreatedAt = $customer->getPasswordCreatedAt();
+
+        return is_null($passwordCreatedAt) ? $customer->getCreatedAtTimestamp() : $passwordCreatedAt;
+    }
+
     /**
      * Check whether customers registration is allowed
      *
diff --git app/code/core/Mage/Customer/Model/Entity/Customer.php app/code/core/Mage/Customer/Model/Entity/Customer.php
index a7ab13ddf22..d7cde9dbc43 100644
--- app/code/core/Mage/Customer/Model/Entity/Customer.php
+++ app/code/core/Mage/Customer/Model/Entity/Customer.php
@@ -219,8 +219,9 @@ class Mage_Customer_Model_Entity_Customer extends Mage_Eav_Model_Entity_Abstract
      */
     public function changePassword(Mage_Customer_Model_Customer $customer, $newPassword)
     {
-        $customer->setPassword($newPassword);
+        $customer->setPassword($newPassword)->setPasswordCreatedAt(time());
         $this->saveAttribute($customer, 'password_hash');
+        $this->saveAttribute($customer, 'password_created_at');
         return $this;
     }
 
diff --git app/code/core/Mage/Customer/controllers/AccountController.php app/code/core/Mage/Customer/controllers/AccountController.php
index 7ab81641723..fa30ef0277b 100644
--- app/code/core/Mage/Customer/controllers/AccountController.php
+++ app/code/core/Mage/Customer/controllers/AccountController.php
@@ -282,6 +282,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             $errors = $this->_getCustomerErrors($customer);
 
             if (empty($errors)) {
+                $customer->setPasswordCreatedAt(time());
                 $customer->save();
                 $this->_successProcessRegistration($customer);
                 return;
@@ -557,6 +558,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                 // activate customer
                 try {
                     $customer->setConfirmation(null);
+                    $customer->setPasswordCreatedAt(time());
                     $customer->save();
                 }
                 catch (Exception $e) {
@@ -797,6 +799,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
 
             try {
                 $customer->setConfirmation(null);
+                $customer->setPasswordCreatedAt(time());
                 $customer->save();
                 $this->_getSession()->setCustomer($customer)
                     ->addSuccess($this->__('The account information has been saved.'));
diff --git app/code/core/Mage/Log/Model/Visitor.php app/code/core/Mage/Log/Model/Visitor.php
index 269e472914c..fb28569e12e 100644
--- app/code/core/Mage/Log/Model/Visitor.php
+++ app/code/core/Mage/Log/Model/Visitor.php
@@ -185,7 +185,7 @@ class Mage_Log_Model_Visitor extends Mage_Core_Model_Abstract
      */
     public function bindCustomerLogin($observer)
     {
-        if (!$this->getCustomerId() && $customer = $observer->getEvent()->getCustomer()) {
+        if ($customer = $observer->getEvent()->getCustomer()) {
             $this->setDoCustomerLogin(true);
             $this->setCustomerId($customer->getId());
         }
diff --git app/code/core/Mage/Usa/Helper/Data.php app/code/core/Mage/Usa/Helper/Data.php
index 3720eb7a0e5..60be0e5e829 100644
--- app/code/core/Mage/Usa/Helper/Data.php
+++ app/code/core/Mage/Usa/Helper/Data.php
@@ -31,5 +31,22 @@
  */
 class Mage_Usa_Helper_Data extends Mage_Core_Helper_Abstract
 {
-
+    /**
+     * Validate ups type value
+     *
+     * @param $valueForCheck string ups type value for check
+     *
+     * @return bool
+     */
+    public function validateUpsType($valueForCheck) {
+        $result = false;
+        $sourceModel = Mage::getSingleton('usa/shipping_carrier_ups_source_type');
+        foreach ($sourceModel->toOptionArray() as $allowedValue) {
+            if (isset($allowedValue['value']) && $allowedValue['value'] == $valueForCheck) {
+                $result = true;
+                break;
+            }
+        }
+        return $result;
+    }
 }
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Abstract/Backend/Abstract.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Abstract/Backend/Abstract.php
new file mode 100644
index 00000000000..665ac3be6e2
--- /dev/null
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Abstract/Backend/Abstract.php
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
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Usa
+ * @copyright  Copyright (c) 2006-2018 Magento, Inc. (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Backend model for validate shipping carrier ups field
+ *
+ * @category   Mage
+ * @package    Mage_Usa
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+
+abstract class Mage_Usa_Model_Shipping_Carrier_Abstract_Backend_Abstract extends Mage_Core_Model_Config_Data
+{
+    /**
+     * Source model to get allowed values
+     *
+     * @var string
+     */
+    protected $_sourceModel;
+
+    /**
+     * Field name to display in error block
+     *
+     * @var string
+     */
+    protected $_nameErrorField;
+
+    /**
+     * Set source model to get allowed values
+     *
+     * @return void
+     */
+    abstract protected function _setSourceModelData();
+
+    /**
+     * Set field name to display in error block
+     *
+     * @return void
+     */
+    abstract protected function _setNameErrorField();
+
+    /**
+     * Mage_Usa_Model_Shipping_Carrier_Ups_Backend_Abstract constructor.
+     */
+    public function __construct()
+    {
+        parent::__construct();
+        $this->_setSourceModelData();
+        $this->_setNameErrorField();
+    }
+
+    /**
+     * Check for presence in array with allow value.
+     *
+     * @throws Mage_Core_Exception
+     * @return Mage_Usa_Model_Shipping_Carrier_Ups_Backend_FreeShipment
+     */
+    protected function _beforeSave()
+    {
+        $sourceModel = Mage::getSingleton($this->_sourceModel);
+        if (!method_exists($sourceModel, 'toOptionArray')) {
+            Mage::throwException(Mage::helper('usa')->__('Method toOptionArray not found in source model.'));
+        }
+        $hasCorrectValue = false;
+        $value = $this->getValue();
+        foreach ($sourceModel->toOptionArray() as $allowedValue) {
+            if (isset($allowedValue['value']) && $allowedValue['value'] == $value) {
+                $hasCorrectValue = true;
+                break;
+            }
+        }
+        if(!$hasCorrectValue) {
+            Mage::throwException(Mage::helper('usa')->__('Field "%s" has wrong value.', $this->_nameErrorField));
+        }
+        return $this;
+    }
+}
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups/Backend/Freemethod.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups/Backend/Freemethod.php
new file mode 100644
index 00000000000..d844e62713e
--- /dev/null
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups/Backend/Freemethod.php
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
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Usa
+ * @copyright  Copyright (c) 2006-2018 Magento, Inc. (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Backend model for validate free method field
+ *
+ * @category   Mage
+ * @package    Mage_Usa
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+
+class Mage_Usa_Model_Shipping_Carrier_Ups_Backend_Freemethod
+    extends Mage_Usa_Model_Shipping_Carrier_Abstract_Backend_Abstract
+{
+    /**
+     * Set source model to get allowed values
+     *
+     * @return void
+     */
+    protected function _setSourceModelData()
+    {
+        $this->_sourceModel = 'usa/shipping_carrier_ups_source_freemethod';
+    }
+
+    /**
+     * Set field name to display in error block
+     *
+     * @return void
+     */
+    protected function _setNameErrorField()
+    {
+        $this->_nameErrorField = 'Ups Free Method';
+    }
+}
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups/Backend/OriginShipment.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups/Backend/OriginShipment.php
new file mode 100644
index 00000000000..4d7e1c0506f
--- /dev/null
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups/Backend/OriginShipment.php
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
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Usa
+ * @copyright  Copyright (c) 2006-2018 Magento, Inc. (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Backend model for validate origin of the shipment field
+ *
+ * @category   Mage
+ * @package    Mage_Usa
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+
+class Mage_Usa_Model_Shipping_Carrier_Ups_Backend_OriginShipment
+    extends Mage_Usa_Model_Shipping_Carrier_Abstract_Backend_Abstract
+{
+    /**
+     * Set source model to get allowed values
+     *
+     * @return void
+     */
+    protected function _setSourceModelData()
+    {
+        $this->_sourceModel = 'usa/shipping_carrier_ups_source_originShipment';
+    }
+
+    /**
+     * Set field name to display in error block
+     *
+     * @return void
+     */
+    protected function _setNameErrorField()
+    {
+        $this->_nameErrorField = 'Ups origin of the Shipment';
+    }
+}
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups/Backend/Type.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups/Backend/Type.php
new file mode 100644
index 00000000000..fe033622cf6
--- /dev/null
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups/Backend/Type.php
@@ -0,0 +1,56 @@
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
+ * @category    Mage
+ * @package     Mage_Usa
+ * @copyright  Copyright (c) 2006-2018 Magento, Inc. (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Backend model for validate ups type field
+ *
+ * @category   Mage
+ * @package    Mage_Usa
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+
+class Mage_Usa_Model_Shipping_Carrier_Ups_Backend_Type extends Mage_Usa_Model_Shipping_Carrier_Abstract_Backend_Abstract
+{
+    /**
+     * Set source model to get allowed values
+     *
+     * @return void
+     */
+    protected function _setSourceModelData()
+    {
+        $this->_sourceModel = 'usa/shipping_carrier_ups_source_type';
+    }
+
+    /**
+     * Set field name to display in error block
+     *
+     * @return void
+     */
+    protected function _setNameErrorField()
+    {
+        $this->_nameErrorField = 'UPS Type';
+    }
+}
diff --git app/code/core/Mage/Usa/etc/system.xml app/code/core/Mage/Usa/etc/system.xml
index 33f62861c5c..efa3063f617 100644
--- app/code/core/Mage/Usa/etc/system.xml
+++ app/code/core/Mage/Usa/etc/system.xml
@@ -659,6 +659,7 @@
                             <frontend_type>select</frontend_type>
                             <frontend_class>free-method</frontend_class>
                             <source_model>usa/shipping_carrier_ups_source_freemethod</source_model>
+                            <backend_model>usa/shipping_carrier_ups_backend_freemethod</backend_model>
                             <sort_order>20</sort_order>
                             <show_in_default>1</show_in_default>
                             <show_in_website>1</show_in_website>
@@ -735,6 +736,7 @@
                             <label>Origin of the Shipment</label>
                             <frontend_type>select</frontend_type>
                             <source_model>usa/shipping_carrier_ups_source_originShipment</source_model>
+                            <backend_model>usa/shipping_carrier_ups_backend_originShipment</backend_model>
                             <sort_order>3</sort_order>
                             <show_in_default>1</show_in_default>
                             <show_in_website>1</show_in_website>
@@ -786,6 +788,7 @@
                             <label>UPS Type</label>
                             <frontend_type>select</frontend_type>
                             <source_model>usa/shipping_carrier_ups_source_type</source_model>
+                            <backend_model>usa/shipping_carrier_ups_backend_type</backend_model>
                             <sort_order>2</sort_order>
                             <show_in_default>1</show_in_default>
                             <show_in_website>1</show_in_website>
diff --git app/code/core/Zend/Filter/PregReplace.php app/code/core/Zend/Filter/PregReplace.php
new file mode 100644
index 00000000000..586c0fe20a0
--- /dev/null
+++ app/code/core/Zend/Filter/PregReplace.php
@@ -0,0 +1,183 @@
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
+ * @package    Zend_Filter
+ * @copyright  Copyright (c) 2005-2015 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ * @version    $Id$
+ */
+
+/**
+ * This class replaces default Zend_Filter_PregReplace because of problem described in MPERF-10057
+ * The only difference between current class and original one is overwritten implementation of filter method
+ *
+ * @see Zend_Filter_Interface
+ */
+#require_once 'Zend/Filter/Interface.php';
+
+/**
+ * @category   Zend
+ * @package    Zend_Filter
+ * @copyright  Copyright (c) 2005-2015 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ */
+class Zend_Filter_PregReplace implements Zend_Filter_Interface
+{
+    /**
+     * Pattern to match
+     * @var mixed
+     */
+    protected $_matchPattern = null;
+
+    /**
+     * Replacement pattern
+     * @var mixed
+     */
+    protected $_replacement = '';
+
+    /**
+     * Is unicode enabled?
+     *
+     * @var bool
+     */
+    static protected $_unicodeSupportEnabled = null;
+
+    /**
+     * Is Unicode Support Enabled Utility function
+     *
+     * @return bool
+     */
+    static public function isUnicodeSupportEnabled()
+    {
+        if (self::$_unicodeSupportEnabled === null) {
+            self::_determineUnicodeSupport();
+        }
+
+        return self::$_unicodeSupportEnabled;
+    }
+
+    /**
+     * Method to cache the regex needed to determine if unicode support is available
+     *
+     * @return bool
+     */
+    static protected function _determineUnicodeSupport()
+    {
+        self::$_unicodeSupportEnabled = (@preg_match('/\pL/u', 'a')) ? true : false;
+    }
+
+    /**
+     * Constructor
+     * Supported options are
+     *     'match'   => matching pattern
+     *     'replace' => replace with this
+     *
+     * @param  string|array $options
+     * @return void
+     */
+    public function __construct($options = null)
+    {
+        if ($options instanceof Zend_Config) {
+            $options = $options->toArray();
+        } else if (!is_array($options)) {
+            $options = func_get_args();
+            $temp    = array();
+            if (!empty($options)) {
+                $temp['match'] = array_shift($options);
+            }
+
+            if (!empty($options)) {
+                $temp['replace'] = array_shift($options);
+            }
+
+            $options = $temp;
+        }
+
+        if (array_key_exists('match', $options)) {
+            $this->setMatchPattern($options['match']);
+        }
+
+        if (array_key_exists('replace', $options)) {
+            $this->setReplacement($options['replace']);
+        }
+    }
+
+    /**
+     * Set the match pattern for the regex being called within filter()
+     *
+     * @param mixed $match - same as the first argument of preg_replace
+     * @return Zend_Filter_PregReplace
+     */
+    public function setMatchPattern($match)
+    {
+        $this->_matchPattern = $match;
+        return $this;
+    }
+
+    /**
+     * Get currently set match pattern
+     *
+     * @return string
+     */
+    public function getMatchPattern()
+    {
+        return $this->_matchPattern;
+    }
+
+    /**
+     * Set the Replacement pattern/string for the preg_replace called in filter
+     *
+     * @param mixed $replacement - same as the second argument of preg_replace
+     * @return Zend_Filter_PregReplace
+     */
+    public function setReplacement($replacement)
+    {
+        $this->_replacement = $replacement;
+        return $this;
+    }
+
+    /**
+     * Get currently set replacement value
+     *
+     * @return string
+     */
+    public function getReplacement()
+    {
+        return $this->_replacement;
+    }
+
+    /**
+     * Perform regexp replacement as filter
+     *
+     * @param  string $value
+     * @return string
+     */
+    public function filter($value)
+    {
+        if ($this->_matchPattern == null) {
+            #require_once 'Zend/Filter/Exception.php';
+            throw new Zend_Filter_Exception(get_class($this) . ' does not have a valid MatchPattern set.');
+        }
+        $firstDilimeter = substr($this->_matchPattern, 0, 1);
+        $partsOfRegex = explode($firstDilimeter, $this->_matchPattern);
+        $modifiers = array_pop($partsOfRegex);
+        if ($modifiers != str_replace('e', '', $modifiers)) {
+            throw new Zend_Filter_Exception(get_class($this) . ' uses deprecated modifier "/e".');
+        }
+
+        return preg_replace($this->_matchPattern, $this->_replacement, $value);
+    }
+
+}
diff --git app/code/core/Zend/Validate/EmailAddress.php app/code/core/Zend/Validate/EmailAddress.php
new file mode 100644
index 00000000000..95e9bdff7cf
--- /dev/null
+++ app/code/core/Zend/Validate/EmailAddress.php
@@ -0,0 +1,579 @@
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
+ * @package    Zend_Validate
+ * @copyright  Copyright (c) 2005-2015 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ * @version    $Id$
+ */
+
+/**
+ * @see Zend_Validate_Abstract
+ */
+#require_once 'Zend/Validate/Abstract.php';
+
+/**
+ * @see Zend_Validate_Hostname
+ */
+#require_once 'Zend/Validate/Hostname.php';
+
+/**
+ * This class replaces default Zend_Validate_EmailAddress because of issues described in MPERF-9688 and MPERF-9689
+ * The only difference between current class and original one is overwritten implementation of _validateLocalPart method
+ *
+ * @category   Zend
+ * @package    Zend_Validate
+ * @copyright  Copyright (c) 2005-2015 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ */
+class Zend_Validate_EmailAddress extends Zend_Validate_Abstract
+{
+    const INVALID            = 'emailAddressInvalid';
+    const INVALID_FORMAT     = 'emailAddressInvalidFormat';
+    const INVALID_HOSTNAME   = 'emailAddressInvalidHostname';
+    const INVALID_MX_RECORD  = 'emailAddressInvalidMxRecord';
+    const INVALID_SEGMENT    = 'emailAddressInvalidSegment';
+    const DOT_ATOM           = 'emailAddressDotAtom';
+    const QUOTED_STRING      = 'emailAddressQuotedString';
+    const INVALID_LOCAL_PART = 'emailAddressInvalidLocalPart';
+    const LENGTH_EXCEEDED    = 'emailAddressLengthExceeded';
+
+    /**
+     * @var array
+     */
+    protected $_messageTemplates = array(
+        self::INVALID            => "Invalid type given. String expected",
+        self::INVALID_FORMAT     => "'%value%' is not a valid email address in the basic format local-part@hostname",
+        self::INVALID_HOSTNAME   => "'%hostname%' is not a valid hostname for email address '%value%'",
+        self::INVALID_MX_RECORD  => "'%hostname%' does not appear to have a valid MX record for the email address '%value%'",
+        self::INVALID_SEGMENT    => "'%hostname%' is not in a routable network segment. The email address '%value%' should not be resolved from public network",
+        self::DOT_ATOM           => "'%localPart%' can not be matched against dot-atom format",
+        self::QUOTED_STRING      => "'%localPart%' can not be matched against quoted-string format",
+        self::INVALID_LOCAL_PART => "'%localPart%' is not a valid local part for email address '%value%'",
+        self::LENGTH_EXCEEDED    => "'%value%' exceeds the allowed length",
+    );
+
+    /**
+     * As of RFC5753 (JAN 2010), the following blocks are no longer reserved:
+     *   - 128.0.0.0/16
+     *   - 191.255.0.0/16
+     *   - 223.255.255.0/24
+     * @see http://tools.ietf.org/html/rfc5735#page-6
+     *
+     * As of RFC6598 (APR 2012), the following blocks are now reserved:
+     *   - 100.64.0.0/10
+     * @see http://tools.ietf.org/html/rfc6598#section-7
+     *
+     * @see http://en.wikipedia.org/wiki/IPv4
+     * @var array
+     */
+    protected $_invalidIp = array(
+        '0'   => '0.0.0.0/8',
+        '10'  => '10.0.0.0/8',
+        '100' => '100.64.0.0/10',
+        '127' => '127.0.0.0/8',
+        '169' => '169.254.0.0/16',
+        '172' => '172.16.0.0/12',
+        '192' => array(
+            '192.0.0.0/24',
+            '192.0.2.0/24',
+            '192.88.99.0/24',
+            '192.168.0.0/16'
+        ),
+        '198' => '198.18.0.0/15',
+        '224' => '224.0.0.0/4',
+        '240' => '240.0.0.0/4'
+    );
+
+    /**
+     * @var array
+     */
+    protected $_messageVariables = array(
+        'hostname'  => '_hostname',
+        'localPart' => '_localPart'
+    );
+
+    /**
+     * @var string
+     */
+    protected $_hostname;
+
+    /**
+     * @var string
+     */
+    protected $_localPart;
+
+    /**
+     * Internal options array
+     */
+    protected $_options = array(
+        'mx'       => false,
+        'deep'     => false,
+        'domain'   => true,
+        'allow'    => Zend_Validate_Hostname::ALLOW_DNS,
+        'hostname' => null
+    );
+
+    /**
+     * Instantiates hostname validator for local use
+     *
+     * The following option keys are supported:
+     * 'hostname' => A hostname validator, see Zend_Validate_Hostname
+     * 'allow'    => Options for the hostname validator, see Zend_Validate_Hostname::ALLOW_*
+     * 'mx'       => If MX check should be enabled, boolean
+     * 'deep'     => If a deep MX check should be done, boolean
+     *
+     * @param array|string|Zend_Config $options OPTIONAL
+     */
+    public function __construct($options = array())
+    {
+        if ($options instanceof Zend_Config) {
+            $options = $options->toArray();
+        } else if (!is_array($options)) {
+            $options = func_get_args();
+            $temp['allow'] = array_shift($options);
+            if (!empty($options)) {
+                $temp['mx'] = array_shift($options);
+            }
+
+            if (!empty($options)) {
+                $temp['hostname'] = array_shift($options);
+            }
+
+            $options = $temp;
+        }
+
+        $options += $this->_options;
+        $this->setOptions($options);
+    }
+
+    /**
+     * Returns all set Options
+     *
+     * @return array
+     */
+    public function getOptions()
+    {
+        return $this->_options;
+    }
+
+    /**
+     * Set options for the email validator
+     *
+     * @param array $options
+     * @return Zend_Validate_EmailAddress Provides a fluent inteface
+     */
+    public function setOptions(array $options = array())
+    {
+        if (array_key_exists('messages', $options)) {
+            $this->setMessages($options['messages']);
+        }
+
+        if (array_key_exists('hostname', $options)) {
+            if (array_key_exists('allow', $options)) {
+                $this->setHostnameValidator($options['hostname'], $options['allow']);
+            } else {
+                $this->setHostnameValidator($options['hostname']);
+            }
+        } elseif ($this->_options['hostname'] == null) {
+            $this->setHostnameValidator();
+        }
+
+        if (array_key_exists('mx', $options)) {
+            $this->setValidateMx($options['mx']);
+        }
+
+        if (array_key_exists('deep', $options)) {
+            $this->setDeepMxCheck($options['deep']);
+        }
+
+        if (array_key_exists('domain', $options)) {
+            $this->setDomainCheck($options['domain']);
+        }
+
+        return $this;
+    }
+
+    /**
+     * Sets the validation failure message template for a particular key
+     * Adds the ability to set messages to the attached hostname validator
+     *
+     * @param  string $messageString
+     * @param  string $messageKey     OPTIONAL
+     * @return Zend_Validate_Abstract Provides a fluent interface
+     * @throws Zend_Validate_Exception
+     */
+    public function setMessage($messageString, $messageKey = null)
+    {
+        if ($messageKey === null) {
+            $this->_options['hostname']->setMessage($messageString);
+            parent::setMessage($messageString);
+            return $this;
+        }
+
+        if (!isset($this->_messageTemplates[$messageKey])) {
+            $this->_options['hostname']->setMessage($messageString, $messageKey);
+        }
+
+        $this->_messageTemplates[$messageKey] = $messageString;
+        return $this;
+    }
+
+    /**
+     * Returns the set hostname validator
+     *
+     * @return Zend_Validate_Hostname
+     */
+    public function getHostnameValidator()
+    {
+        return $this->_options['hostname'];
+    }
+
+    /**
+     * @param Zend_Validate_Hostname $hostnameValidator OPTIONAL
+     * @param int                    $allow             OPTIONAL
+     * @return $this
+     */
+    public function setHostnameValidator(Zend_Validate_Hostname $hostnameValidator = null, $allow = Zend_Validate_Hostname::ALLOW_DNS)
+    {
+        if (!$hostnameValidator) {
+            $hostnameValidator = new Zend_Validate_Hostname($allow);
+        }
+
+        $this->_options['hostname'] = $hostnameValidator;
+        $this->_options['allow']    = $allow;
+        return $this;
+    }
+
+    /**
+     * Whether MX checking via getmxrr is supported or not
+     *
+     * This currently only works on UNIX systems
+     *
+     * @return boolean
+     */
+    public function validateMxSupported()
+    {
+        return function_exists('getmxrr');
+    }
+
+    /**
+     * Returns the set validateMx option
+     *
+     * @return boolean
+     */
+    public function getValidateMx()
+    {
+        return $this->_options['mx'];
+    }
+
+    /**
+     * Set whether we check for a valid MX record via DNS
+     *
+     * This only applies when DNS hostnames are validated
+     *
+     * @param boolean $mx Set allowed to true to validate for MX records, and false to not validate them
+     * @throws Zend_Validate_Exception
+     * @return Zend_Validate_EmailAddress Provides a fluent inteface
+     */
+    public function setValidateMx($mx)
+    {
+        if ((bool) $mx && !$this->validateMxSupported()) {
+            #require_once 'Zend/Validate/Exception.php';
+            throw new Zend_Validate_Exception('MX checking not available on this system');
+        }
+
+        $this->_options['mx'] = (bool) $mx;
+        return $this;
+    }
+
+    /**
+     * Returns the set deepMxCheck option
+     *
+     * @return boolean
+     */
+    public function getDeepMxCheck()
+    {
+        return $this->_options['deep'];
+    }
+
+    /**
+     * Set whether we check MX record should be a deep validation
+     *
+     * @param boolean $deep Set deep to true to perform a deep validation process for MX records
+     * @return Zend_Validate_EmailAddress Provides a fluent inteface
+     */
+    public function setDeepMxCheck($deep)
+    {
+        $this->_options['deep'] = (bool) $deep;
+        return $this;
+    }
+
+    /**
+     * Returns the set domainCheck option
+     *
+     * @return unknown
+     */
+    public function getDomainCheck()
+    {
+        return $this->_options['domain'];
+    }
+
+    /**
+     * Sets if the domain should also be checked
+     * or only the local part of the email address
+     *
+     * @param boolean $domain
+     * @return Zend_Validate_EmailAddress Provides a fluent inteface
+     */
+    public function setDomainCheck($domain = true)
+    {
+        $this->_options['domain'] = (boolean) $domain;
+        return $this;
+    }
+
+    /**
+     * Returns if the given host is reserved
+     *
+     * @param string $host
+     * @return boolean
+     */
+    private function _isReserved($host){
+        if (!preg_match('/^([0-9]{1,3}\.){3}[0-9]{1,3}$/', $host)) {
+            $host = gethostbyname($host);
+        }
+
+        $octet = explode('.',$host);
+        if ((int)$octet[0] >= 224) {
+            return true;
+        } else if (array_key_exists($octet[0], $this->_invalidIp)) {
+            foreach ((array)$this->_invalidIp[$octet[0]] as $subnetData) {
+                // we skip the first loop as we already know that octet matches
+                for ($i = 1; $i < 4; $i++) {
+                    if (strpos($subnetData, $octet[$i]) !== $i * 4) {
+                        break;
+                    }
+                }
+
+                $host       = explode("/", $subnetData);
+                $binaryHost = "";
+                $tmp        = explode(".", $host[0]);
+                for ($i = 0; $i < 4 ; $i++) {
+                    $binaryHost .= str_pad(decbin($tmp[$i]), 8, "0", STR_PAD_LEFT);
+                }
+
+                $segmentData = array(
+                    'network'   => (int)$this->_toIp(str_pad(substr($binaryHost, 0, $host[1]), 32, 0)),
+                    'broadcast' => (int)$this->_toIp(str_pad(substr($binaryHost, 0, $host[1]), 32, 1))
+                );
+
+                for ($j = $i; $j < 4; $j++) {
+                    if ((int)$octet[$j] < $segmentData['network'][$j] ||
+                        (int)$octet[$j] > $segmentData['broadcast'][$j]) {
+                        return false;
+                    }
+                }
+            }
+
+            return true;
+        } else {
+            return false;
+        }
+    }
+
+    /**
+     * Converts a binary string to an IP address
+     *
+     * @param string $binary
+     * @return mixed
+     */
+    private function _toIp($binary)
+    {
+        $ip  = array();
+        $tmp = explode(".", chunk_split($binary, 8, "."));
+        for ($i = 0; $i < 4 ; $i++) {
+            $ip[$i] = bindec($tmp[$i]);
+        }
+
+        return $ip;
+    }
+
+    /**
+     * Internal method to validate the local part of the email address
+     *
+     * @return boolean
+     */
+    private function _validateLocalPart()
+    {
+        // First try to match the local part on the common dot-atom format
+        $result = false;
+
+        // Dot-atom characters are: 1*atext *("." 1*atext)
+        // atext: ALPHA / DIGIT / and "!", "#", "$", "%", "&", "'", "*",
+        //        "+", "-", "/", "=", "?", "^", "_", "`", "{", "|", "}", "~"
+        $atext = 'a-zA-Z0-9\x21\x23\x24\x25\x26\x27\x2a\x2b\x2d\x2f\x3d\x3f\x5e\x5f\x60\x7b\x7c\x7d\x7e';
+        if (preg_match('/^[' . $atext . ']+(\x2e+[' . $atext . ']+)*$/', $this->_localPart)) {
+            $result = true;
+        } else {
+            // Try quoted string format (RFC 5321 Chapter 4.1.2)
+
+            // Quoted-string characters are: DQUOTE *(qtext/quoted-pair) DQUOTE
+            $qtext      = '\x20-\x21\x23-\x5b\x5d-\x7e'; // %d32-33 / %d35-91 / %d93-126
+            $quotedPair = '\x20-\x7e'; // %d92 %d32-126
+            if ((0 === (strcmp($this->localPart, strip_tags($this->localPart))))
+                && (0 === (strcmp($this->localPart, htmlspecialchars_decode($this->localPart))))
+                && (preg_match('/^"(['. $qtext .']|\x5c[' . $quotedPair . '])*"$/', $this->localPart))) {
+                $result = true;
+            } else {
+                $this->_error(self::DOT_ATOM);
+                $this->_error(self::QUOTED_STRING);
+                $this->_error(self::INVALID_LOCAL_PART);
+            }
+        }
+
+        return $result;
+    }
+
+    /**
+     * Internal method to validate the servers MX records
+     *
+     * @return boolean
+     */
+    private function _validateMXRecords()
+    {
+        $mxHosts = array();
+        $hostname = $this->_hostname;
+
+        //decode IDN domain name if possible
+        if (function_exists('idn_to_ascii')) {
+            $hostname = idn_to_ascii($this->_hostname);
+        }
+
+        $result = getmxrr($hostname, $mxHosts);
+        if (!$result) {
+            $this->_error(self::INVALID_MX_RECORD);
+        } else if ($this->_options['deep'] && function_exists('checkdnsrr')) {
+            $validAddress = false;
+            $reserved     = true;
+            foreach ($mxHosts as $hostname) {
+                $res = $this->_isReserved($hostname);
+                if (!$res) {
+                    $reserved = false;
+                }
+
+                if (!$res
+                    && (checkdnsrr($hostname, "A")
+                    || checkdnsrr($hostname, "AAAA")
+                    || checkdnsrr($hostname, "A6"))) {
+                    $validAddress = true;
+                    break;
+                }
+            }
+
+            if (!$validAddress) {
+                $result = false;
+                if ($reserved) {
+                    $this->_error(self::INVALID_SEGMENT);
+                } else {
+                    $this->_error(self::INVALID_MX_RECORD);
+                }
+            }
+        }
+
+        return $result;
+    }
+
+    /**
+     * Internal method to validate the hostname part of the email address
+     *
+     * @return boolean
+     */
+    private function _validateHostnamePart()
+    {
+        $hostname = $this->_options['hostname']->setTranslator($this->getTranslator())
+                         ->isValid($this->_hostname);
+        if (!$hostname) {
+            $this->_error(self::INVALID_HOSTNAME);
+
+            // Get messages and errors from hostnameValidator
+            foreach ($this->_options['hostname']->getMessages() as $code => $message) {
+                $this->_messages[$code] = $message;
+            }
+
+            foreach ($this->_options['hostname']->getErrors() as $error) {
+                $this->_errors[] = $error;
+            }
+        } else if ($this->_options['mx']) {
+            // MX check on hostname
+            $hostname = $this->_validateMXRecords();
+        }
+
+        return $hostname;
+    }
+
+    /**
+     * Defined by Zend_Validate_Interface
+     *
+     * Returns true if and only if $value is a valid email address
+     * according to RFC2822
+     *
+     * @link   http://www.ietf.org/rfc/rfc2822.txt RFC2822
+     * @link   http://www.columbia.edu/kermit/ascii.html US-ASCII characters
+     * @param  string $value
+     * @return boolean
+     */
+    public function isValid($value)
+    {
+        if (!is_string($value)) {
+            $this->_error(self::INVALID);
+            return false;
+        }
+
+        $matches = array();
+        $length  = true;
+        $this->_setValue($value);
+
+        // Split email address up and disallow '..'
+        if ((strpos($value, '..') !== false) or
+            (!preg_match('/^(.+)@([^@]+)$/', $value, $matches))) {
+            $this->_error(self::INVALID_FORMAT);
+            return false;
+        }
+
+        $this->_localPart = $matches[1];
+        $this->_hostname  = $matches[2];
+
+        if ((strlen($this->_localPart) > 64) || (strlen($this->_hostname) > 255)) {
+            $length = false;
+            $this->_error(self::LENGTH_EXCEEDED);
+        }
+
+        // Match hostname part
+        if ($this->_options['domain']) {
+            $hostname = $this->_validateHostnamePart();
+        }
+
+        $local = $this->_validateLocalPart();
+
+        // If both parts valid, return true
+        if ($local && $length) {
+            if (($this->_options['domain'] && $hostname) || !$this->_options['domain']) {
+                return true;
+            }
+        }
+
+        return false;
+    }
+}
diff --git app/design/adminhtml/default/default/template/bundle/product/edit/bundle/option.phtml app/design/adminhtml/default/default/template/bundle/product/edit/bundle/option.phtml
index db7f7e385dd..7408669f0e0 100644
--- app/design/adminhtml/default/default/template/bundle/product/edit/bundle/option.phtml
+++ app/design/adminhtml/default/default/template/bundle/product/edit/bundle/option.phtml
@@ -212,6 +212,8 @@ bOption = new Bundle.Option(optionTemplate);
 optionIndex = bOption.add(<?php echo $_option->toJson() ?>);
 <?php if ($_option->getSelections()):?>
     <?php foreach ($_option->getSelections() as $_selection): ?>
+    <?php $_selection->setName($this->escapeHtml($_selection->getName())); ?>
+    <?php $_selection->setSku($this->escapeHtml($_selection->getSku())); ?>
 bSelection.addRow(optionIndex, <?php echo $_selection->toJson() ?>);
     <?php endforeach; ?>
 <?php endif; ?>
diff --git app/design/adminhtml/default/default/template/enterprise/cms/page/revision/info.phtml app/design/adminhtml/default/default/template/enterprise/cms/page/revision/info.phtml
index b0be8b949a5..df25ee79267 100644
--- app/design/adminhtml/default/default/template/enterprise/cms/page/revision/info.phtml
+++ app/design/adminhtml/default/default/template/enterprise/cms/page/revision/info.phtml
@@ -44,7 +44,7 @@
         </tr>
         <tr>
             <th><span class="nobr"><?php echo $this->__('Author:') ?></span></th>
-            <td><?php echo $this->getAuthor() ?></td>
+            <td><?php echo $this->escapeHtml($this->getAuthor()); ?></td>
         </tr>
         <tr>
             <th><span class="nobr"><?php echo $this->__('Created:') ?></span></th>
diff --git app/design/adminhtml/default/default/template/page/header.phtml app/design/adminhtml/default/default/template/page/header.phtml
index a83301f791d..a6c857b3238 100644
--- app/design/adminhtml/default/default/template/page/header.phtml
+++ app/design/adminhtml/default/default/template/page/header.phtml
@@ -28,7 +28,7 @@
     <a href="<?php echo $this->getHomeLink() ?>"><img src="<?php echo $this->getSkinUrl($this->__('images/logo.gif')) ?>" alt="<?php echo $this->__('Magento Logo') ?>" class="logo"/></a>
     <div class="header-right">
         <p class="super">
-            <?php echo $this->__("Logged in as %s", $this->getUser()->getUsername()) ?><span class="separator">|</span><?php echo $this->formatDate(null, 'full') ?><span class="separator">|</span><a href="<?php echo $this->getLogoutLink() ?>" class="link-logout"><?php echo $this->__('Log Out') ?></a>
+            <?php echo $this->__("Logged in as %s", $this->escapeHtml($this->getUser()->getUsername())) ?><span class="separator">|</span><?php echo $this->formatDate(null, 'full') ?><span class="separator">|</span><a href="<?php echo $this->getLogoutLink() ?>" class="link-logout"><?php echo $this->__('Log Out') ?></a>
         </p>
         <?php if ( Mage::getSingleton('admin/session')->isAllowed('admin/global_search') ): ?>
         <fieldset>
diff --git app/design/adminhtml/default/default/template/system/shipping/ups.phtml app/design/adminhtml/default/default/template/system/shipping/ups.phtml
index dc48e830391..752415e61ec 100644
--- app/design/adminhtml/default/default/template/system/shipping/ups.phtml
+++ app/design/adminhtml/default/default/template/system/shipping/ups.phtml
@@ -51,6 +51,15 @@ if(!$storeCode && $websiteCode){
     $stroredOriginShipment = Mage::getStoreConfig('carriers/ups/origin_shipment');
     $stroredFreeShipment = Mage::getStoreConfig('carriers/ups/free_method');
 }
+if (!in_array($storedOriginShipment, array_keys($orShipArr))) {
+    $storedOriginShipment = '';
+}
+if ($storedFreeShipment != '' && !in_array($storedFreeShipment, array_keys($defShipArr))) {
+    $storedFreeShipment = '';
+}
+if (!Mage::helper('usa')->validateUpsType($storedUpsType)) {
+    $storedUpsType = '';
+}
 ?>
 <script type="text/javascript">
 //<![CDATA[
diff --git app/design/frontend/base/default/template/downloadable/catalog/product/links.phtml app/design/frontend/base/default/template/downloadable/catalog/product/links.phtml
index f5f074e2b25..27214d76934 100644
--- app/design/frontend/base/default/template/downloadable/catalog/product/links.phtml
+++ app/design/frontend/base/default/template/downloadable/catalog/product/links.phtml
@@ -36,7 +36,7 @@
     <dl>
         <?php $_links = $this->getLinks(); ?>
         <?php $_isRequired = $this->getLinkSelectionRequired(); ?>
-        <dt><label<?php if ($_isRequired) echo ' class="required"' ?>><?php if ($_isRequired) echo '<em>*</em>' ?><?php echo $this->getLinksTitle() ?></label></dt>
+        <dt><label<?php if ($_isRequired) echo ' class="required"' ?>><?php if ($_isRequired) echo '<em>*</em>' ?><?php echo $this->escapeHtml($this->getLinksTitle()); ?></label></dt>
         <dd<?php /* if ($_option->decoratedIsLast){?> class="last"<?php } */ ?>>
             <ul id="downloadable-links-list" class="options-list">
             <?php foreach ($_links as $_link): ?>
diff --git app/design/frontend/base/default/template/downloadable/checkout/cart/item/default.phtml app/design/frontend/base/default/template/downloadable/checkout/cart/item/default.phtml
index 6193051400f..1b5c2d05817 100644
--- app/design/frontend/base/default/template/downloadable/checkout/cart/item/default.phtml
+++ app/design/frontend/base/default/template/downloadable/checkout/cart/item/default.phtml
@@ -50,7 +50,7 @@
         <!-- downloadable -->
         <?php if ($links = $this->getLinks()): ?>
         <dl class="item-options">
-            <dt><?php echo $this->getLinksTitle() ?></dt>
+            <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
             <?php foreach ($links as $link): ?>
                 <dd><?php echo $link->getTitle() ?></dd>
             <?php endforeach; ?>
diff --git app/design/frontend/base/default/template/downloadable/checkout/onepage/review/item.phtml app/design/frontend/base/default/template/downloadable/checkout/onepage/review/item.phtml
index a4f531a6e16..dfdd9ead6d9 100644
--- app/design/frontend/base/default/template/downloadable/checkout/onepage/review/item.phtml
+++ app/design/frontend/base/default/template/downloadable/checkout/onepage/review/item.phtml
@@ -48,7 +48,7 @@
         <?php endif;?>
         <?php if ($links = $this->getLinks()): ?>
         <dl class="item-options">
-            <dt><?php echo $this->getLinksTitle() ?></dt>
+            <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
             <?php foreach ($links as $link): ?>
                 <dd><?php echo $link->getTitle() ?></dd>
             <?php endforeach; ?>
diff --git app/design/frontend/base/default/template/downloadable/sales/order/items/renderer/downloadable.phtml app/design/frontend/base/default/template/downloadable/sales/order/items/renderer/downloadable.phtml
index 4ed4e1c4a52..18350b91751 100644
--- app/design/frontend/base/default/template/downloadable/sales/order/items/renderer/downloadable.phtml
+++ app/design/frontend/base/default/template/downloadable/sales/order/items/renderer/downloadable.phtml
@@ -54,9 +54,9 @@
         <!-- downloadable -->
         <?php if ($links = $this->getLinks()): ?>
             <dl class="item-options">
-                <dt><?php echo $this->getLinksTitle() ?></dt>
+                <dt><?php echo $this->escapeHtml($this->getLinksTitle()) ?></dt>
                 <?php foreach ($links->getPurchasedItems() as $link): ?>
-                    <dd><?php echo $link->getLinkTitle() ?></dd>
+                    <dd><?php echo $this->escapeHtml($link->getLinkTitle()) ?></dd>
                 <?php endforeach; ?>
             </dl>
         <?php endif; ?>
diff --git app/design/frontend/enterprise/default/template/cms/hierarchy/pagination.phtml app/design/frontend/enterprise/default/template/cms/hierarchy/pagination.phtml
index d3e4d0a8761..a658a61dd22 100644
--- app/design/frontend/enterprise/default/template/cms/hierarchy/pagination.phtml
+++ app/design/frontend/enterprise/default/template/cms/hierarchy/pagination.phtml
@@ -47,7 +47,7 @@
             <?php if ($node->getIsCurrent()):?>
                 <li class="current"><?php echo $this->escapeHtml($this->getNodeLabel($node))?></li>
             <?php else: ?>
-                <li><a title="<?php echo $this->htmlEscape($node->getLabel())?>" href="<?php echo $node->getUrl()?>"><?php echo $this->getNodeLabel($node)?></a></li>
+                <li><a title="<?php echo $this->htmlEscape($node->getLabel())?>" href="<?php echo $node->getUrl()?>"><?php echo $this->escapeHtml($this->getNodeLabel($node)); ?></a></li>
             <?php endif; ?>
         <?php endforeach;?>
 
diff --git app/locale/en_US/Mage_Catalog.csv app/locale/en_US/Mage_Catalog.csv
index 788a41b5807..6f90b3ba4e9 100644
--- app/locale/en_US/Mage_Catalog.csv
+++ app/locale/en_US/Mage_Catalog.csv
@@ -293,6 +293,7 @@
 "Invalid attribute option specified for attribute %s (%s), skipping the record.","Invalid attribute option specified for attribute %s (%s), skipping the record."
 "Invalid attribute set specified, skipping the record.","Invalid attribute set specified, skipping the record."
 "Invalid block: %s.","Invalid block: %s."
+"Invalid custom option(s).","Invalid custom option(s)."
 "Invalid category IDs.","Invalid category IDs."
 "Invalid category.","Invalid category."
 "Invalid image file type.","Invalid image file type."
diff --git app/locale/en_US/Mage_Usa.csv app/locale/en_US/Mage_Usa.csv
index 60e7dc32912..69af4010fa7 100644
--- app/locale/en_US/Mage_Usa.csv
+++ app/locale/en_US/Mage_Usa.csv
@@ -113,6 +113,8 @@
 "Non-rectangular","Non-rectangular"
 "Order","Order"
 "Origin of the Shipment","Origin of the Shipment"
+"Field ""%s"" has wrong value.","Field ""%s"" has wrong value."
+"Method toOptionArray not found in source model.","Method toOptionArray not found in source model."
 "Oversize","Oversize"
 "Package","Package"
 "Package Description","Package Description"
diff --git cron.php cron.php
index 19fee44ce80..7e4808f82fe 100644
--- cron.php
+++ cron.php
@@ -36,7 +36,12 @@ if (!Mage::isInstalled()) {
 $_SERVER['SCRIPT_NAME'] = str_replace(basename(__FILE__), 'index.php', $_SERVER['SCRIPT_NAME']);
 $_SERVER['SCRIPT_FILENAME'] = str_replace(basename(__FILE__), 'index.php', $_SERVER['SCRIPT_FILENAME']);
 
-Mage::app('admin')->setUseSessionInUrl(false);
+try {
+    Mage::app('admin')->setUseSessionInUrl(false);
+} catch (Exception $e) {
+    Mage::printException($e);
+    exit;
+}
 
 try {
     Mage::getConfig()->init()->loadEventObservers('crontab');
diff --git js/tiny_mce/plugins/media/.htaccess js/tiny_mce/plugins/media/.htaccess
new file mode 100644
index 00000000000..6950c803402
--- /dev/null
+++ js/tiny_mce/plugins/media/.htaccess
@@ -0,0 +1,7 @@
+<IfModule mod_rewrite.c>
+    <Files moxieplayer.swf>
+        RewriteEngine on
+        RewriteCond %{QUERY_STRING} !^$
+        RewriteRule ^(.*)$ %{REQUEST_URI}? [R=301,L]
+    </Files>
+</IfModule>
diff --git lib/Varien/Image/Adapter/Gd2.php lib/Varien/Image/Adapter/Gd2.php
index df349dd39ef..cd2a4bdce02 100644
--- lib/Varien/Image/Adapter/Gd2.php
+++ lib/Varien/Image/Adapter/Gd2.php
@@ -106,7 +106,7 @@ class Varien_Image_Adapter_Gd2 extends Varien_Image_Adapter_Abstract
 
     public function display()
     {
-        header("Content-type: ".$this->getMimeType());
+        header("Content-type: ".$this->getMimeTypeWithOutFileType());
         call_user_func($this->_getCallback('output'), $this->_imageHandler);
     }
 
@@ -445,4 +445,14 @@ class Varien_Image_Adapter_Gd2 extends Varien_Image_Adapter_Abstract
         imagealphablending($imageHandler, false);
         imagesavealpha($imageHandler, true);
     }
+
+    /**
+     * Gives real mime-type with not considering file type field
+     *
+     * @return string
+     */
+    public function getMimeTypeWithOutFileType()
+    {
+        return $this->_fileMimeType;
+    }
 }
