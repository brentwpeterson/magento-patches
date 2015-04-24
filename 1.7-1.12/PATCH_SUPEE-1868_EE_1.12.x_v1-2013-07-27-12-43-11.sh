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


SUPEE-1868-1-12-0-2 | EE_1.12.0.2 | v1 | 2148b1b6be28a9bad0bec9a4aecc63ed318dd201 | Fri Jul 26 13:20:27 2013 -0700 | v1.12.0.2..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Paypal/Model/Express/Checkout.php app/code/core/Mage/Paypal/Model/Express/Checkout.php
index f19bc4e..b617998 100644
--- app/code/core/Mage/Paypal/Model/Express/Checkout.php
+++ app/code/core/Mage/Paypal/Model/Express/Checkout.php
@@ -764,7 +764,7 @@ class Mage_Paypal_Model_Express_Checkout
 
                 $options[$i] = new Varien_Object(array(
                     'is_default' => $isDefault,
-                    'name'       => trim("{$rate->getCarrierTitle()} - {$rate->getMethodTitle()}", ' -'),
+                    'name'       => trim("{$rate->getCarrier()} - {$rate->getMethodTitle()}", ' -'),
                     'code'       => $rate->getCode(),
                     'amount'     => $amountExclTax,
                 ));
diff --git app/code/core/Mage/Usa/Helper/Data.php app/code/core/Mage/Usa/Helper/Data.php
index 175fb81..7e6266a 100644
--- app/code/core/Mage/Usa/Helper/Data.php
+++ app/code/core/Mage/Usa/Helper/Data.php
@@ -110,25 +110,25 @@ class Mage_Usa_Helper_Data extends Mage_Core_Helper_Abstract
     public function displayGirthValue($shippingMethod)
     {
         if (in_array($shippingMethod, array(
-            'usps_Priority Mail International',
-            'usps_Priority Mail International Small Flat Rate Box',
-            'usps_Priority Mail International Medium Flat Rate Box',
-            'usps_Priority Mail International Large Flat Rate Box',
-            'usps_Priority Mail International Flat Rate Envelope',
-            'usps_Express Mail International Flat Rate Envelope',
-            'usps_Express Mail Hold For Pickup',
-            'usps_Express Mail International',
-            'usps_First-Class Mail International Package',
-            'usps_First-Class Mail International Parcel',
-            'usps_First-Class Mail International Large Envelope',
-            'usps_First-Class Mail International',
-            'usps_Global Express Guaranteed (GXG)',
-            'usps_USPS GXG Envelopes',
-            'usps_Global Express Guaranteed Non-Document Non-Rectangular',
-            'usps_Media Mail',
-            'usps_Parcel Post',
-            'usps_Express Mail',
-            'usps_Priority Mail'
+            'usps_0_FCLE', //First-Class Mail Large Envelope
+            'usps_1', // Priority Mail
+            'usps_2', // Priority Mail Express Hold For Pickup
+            'usps_3', // Priority Mail Express
+            'usps_4', // Standard Post
+            'usps_6', // Media Mail
+            'usps_INT_1', // Priority Mail Express International
+            'usps_INT_2', // Priority Mail International
+            'usps_INT_4', // Global Express Guaranteed (GXG)
+            'usps_INT_7', // Global Express Guaranteed Non-Document Non-Rectangular
+            'usps_INT_8', // Priority Mail International Flat Rate Envelope
+            'usps_INT_9', // Priority Mail International Medium Flat Rate Box
+            'usps_INT_10', // Priority Mail Express International Flat Rate Envelope
+            'usps_INT_11', // Priority Mail International Large Flat Rate Box
+            'usps_INT_12', // USPS GXG Envelopes
+            'usps_INT_14', // First-Class Mail International Large Envelope
+            'usps_INT_16', // Priority Mail International Small Flat Rate Box
+            'usps_INT_20', // Priority Mail International Small Flat Rate Envelope
+            'usps_INT_26', // Priority Mail Express International Flat Rate Boxes
         ))) {
             return true;
         } else {
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps.php
index 62173e8..7426efa 100644
--- app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps.php
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps.php
@@ -299,7 +299,7 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
 
         $weight = $this->getTotalNumOfBoxes($r->getFreeMethodWeight());
         $r->setWeightPounds(floor($weight));
-        $r->setWeightOunces(round(($weight-floor($weight)) * self::OUNCES_POUND, 1));
+        $r->setWeightOunces(round(($weight - floor($weight)) * self::OUNCES_POUND, 1));
         $r->setService($freeMethod);
     }
 
@@ -314,7 +314,7 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
         $r = $this->_rawRequest;
 
         // The origin address(shipper) must be only in USA
-        if(!$this->_isUSCountry($r->getOrigCountryId())){
+        if (!$this->_isUSCountry($r->getOrigCountryId())){
             $responseBody = '';
             return $this->_parseXmlResponse($responseBody);
         }
@@ -332,7 +332,7 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                 $service = $r->getService();
             }
             if ($r->getContainer() == 'FLAT RATE BOX' || $r->getContainer() == 'FLAT RATE ENVELOPE') {
-                $service = 'PRIORITY';
+                $service = 'Priority';
             }
             $package->addChild('Service', $service);
 
@@ -341,7 +341,7 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                 $package->addChild('FirstClassMailType', 'PARCEL');
             }
             $package->addChild('ZipOrigination', $r->getOrigPostal());
-            //only 5 chars avaialble
+            //only 5 chars available
             $package->addChild('ZipDestination', substr($r->getDestPostal(), 0, 5));
             $package->addChild('Pounds', $r->getWeightPounds());
             $package->addChild('Ounces', $r->getWeightOunces());
@@ -403,7 +403,7 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                 }
                 $client = new Zend_Http_Client();
                 $client->setUri($url);
-                $client->setConfig(array('maxredirects'=>0, 'timeout'=>30));
+                $client->setConfig(array('maxredirects' => 0, 'timeout' => 30));
                 $client->setParameterGet('API', $api);
                 $client->setParameterGet('XML', $request);
                 $response = $client->request();
@@ -444,73 +444,51 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                 $xml = simplexml_load_string($response);
 
                 if (is_object($xml)) {
-                    if (is_object($xml->Number) && is_object($xml->Description) && (string)$xml->Description!='') {
-                        $errorTitle = (string)$xml->Description;
-                    } elseif (is_object($xml->Package)
-                          && is_object($xml->Package->Error)
-                          && is_object($xml->Package->Error->Description)
-                          && (string)$xml->Package->Error->Description!=''
-                    ) {
-                        $errorTitle = (string)$xml->Package->Error->Description;
-                    } else {
-                        $errorTitle = 'Unknown error';
-                    }
                     $r = $this->_rawRequest;
-                    $allowedMethods = explode(",", $this->getConfigData('allowed_methods'));
-                    $allMethods = $this->getCode('method');
-                    $newMethod = false;
+                    $allowedMethods = explode(',', $this->getConfigData('allowed_methods'));
+                    $serviceCodeToActualNameMap = array();
+                    /**
+                     * US Rates
+                     */
                     if ($this->_isUSCountry($r->getDestCountryId())) {
                         if (is_object($xml->Package) && is_object($xml->Package->Postage)) {
                             foreach ($xml->Package->Postage as $postage) {
                                 $serviceName = $this->_filterServiceName((string)$postage->MailService);
-                                $postage->MailService = $serviceName;
-                                if (in_array($serviceName, $allowedMethods)) {
-                                    $costArr[$serviceName] = (string)$postage->Rate;
-                                    $priceArr[$serviceName] = $this->getMethodPrice(
+                                $_serviceCode = $this->getCode('method_to_code', $serviceName);
+                                $serviceCode = $_serviceCode ? $_serviceCode : (string)$postage->attributes()->CLASSID;
+                                $serviceCodeToActualNameMap[$serviceCode] = $serviceName;
+                                if (in_array($serviceCode, $allowedMethods)) {
+                                    $costArr[$serviceCode] = (string)$postage->Rate;
+                                    $priceArr[$serviceCode] = $this->getMethodPrice(
                                         (string)$postage->Rate,
-                                        $serviceName
+                                        $serviceCode
                                     );
-                                } elseif (!in_array($serviceName, $allMethods)) {
-                                    $allMethods[] = $serviceName;
-                                    $newMethod = true;
                                 }
                             }
                             asort($priceArr);
                         }
-                    } else {
-                        /*
-                         * International Rates
-                         */
+                    }
+                    /**
+                     * International Rates
+                     */
+                    else {
                         if (is_object($xml->Package) && is_object($xml->Package->Service)) {
                             foreach ($xml->Package->Service as $service) {
                                 $serviceName = $this->_filterServiceName((string)$service->SvcDescription);
-                                $service->SvcDescription = $serviceName;
-                                if (in_array($serviceName, $allowedMethods)) {
-                                    $costArr[$serviceName] = (string)$service->Postage;
-                                    $priceArr[$serviceName] = $this->getMethodPrice(
+                                $serviceCode = 'INT_' . (string)$service->attributes()->ID;
+                                $serviceCodeToActualNameMap[$serviceCode] = $serviceName;
+                                if (in_array($serviceCode, $allowedMethods)) {
+                                    $costArr[$serviceCode] = (string)$service->Postage;
+                                    $priceArr[$serviceCode] = $this->getMethodPrice(
                                         (string)$service->Postage,
-                                        $serviceName
+                                        $serviceCode
                                     );
-                                } elseif (!in_array($serviceName, $allMethods)) {
-                                    $allMethods[] = $serviceName;
-                                    $newMethod = true;
                                 }
                             }
                             asort($priceArr);
                         }
                     }
-                    /**
-                     * following if statement is obsolete
-                     * we don't have adminhtml/config resoure model
-                     */
-                    if (false && $newMethod) {
-                        sort($allMethods);
-                        $insert['usps']['fields']['methods']['value'] = $allMethods;
-                        Mage::getResourceModel('adminhtml/config')->saveSectionPost('carriers','','',$insert);
-                    }
                 }
-            } else {
-                $errorTitle = 'Response is in the wrong format';
             }
         }
 
@@ -522,12 +500,16 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
             $error->setErrorMessage($this->getConfigData('specificerrmsg'));
             $result->append($error);
         } else {
-            foreach ($priceArr as $method=>$price) {
+            foreach ($priceArr as $method => $price) {
                 $rate = Mage::getModel('shipping/rate_result_method');
                 $rate->setCarrier('usps');
                 $rate->setCarrierTitle($this->getConfigData('title'));
                 $rate->setMethod($method);
-                $rate->setMethodTitle($method);
+                $rate->setMethodTitle(
+                    isset($serviceCodeToActualNameMap[$method])
+                        ? $serviceCodeToActualNameMap[$method]
+                        : $this->getCode('method', $method)
+                );
                 $rate->setCost($costArr[$method]);
                 $rate->setPrice($price);
                 $result->append($rate);
@@ -544,62 +526,110 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
      * @param string $code
      * @return array|bool
      */
-    public function getCode($type, $code='')
+    public function getCode($type, $code = '')
     {
         $codes = array(
+            'method' => array(
+                '0_FCLE' => Mage::helper('usa')->__('First-Class Mail Large Envelope'),
+                '0_FCL'  => Mage::helper('usa')->__('First-Class Mail Letter'),
+                '0_FCP'  => Mage::helper('usa')->__('First-Class Mail Parcel'),
+                '1'      => Mage::helper('usa')->__('Priority Mail'),
+                '2'      => Mage::helper('usa')->__('Priority Mail Express Hold For Pickup'),
+                '3'      => Mage::helper('usa')->__('Priority Mail Express'),
+                '4'      => Mage::helper('usa')->__('Standard Post'),
+                '6'      => Mage::helper('usa')->__('Media Mail'),
+                '7'      => Mage::helper('usa')->__('Library Mail'),
+                '13'     => Mage::helper('usa')->__('Priority Mail Express Flat Rate Envelope'),
+                '16'     => Mage::helper('usa')->__('Priority Mail Flat Rate Envelope'),
+                '17'     => Mage::helper('usa')->__('Priority Mail Medium Flat Rate Box'),
+                '22'     => Mage::helper('usa')->__('Priority Mail Large Flat Rate Box'),
+                '23'     => Mage::helper('usa')->__('Priority Mail Express Sunday/Holiday Delivery'),
+                '25'     => Mage::helper('usa')->__('Priority Mail Express Sunday/Holiday Delivery Flat Rate Envelope'),
+                '27'     => Mage::helper('usa')->__('Priority Mail Express Flat Rate Envelope Hold For Pickup'),
+                '28'     => Mage::helper('usa')->__('Priority Mail Small Flat Rate Box'),
+                '33'     => Mage::helper('usa')->__('Priority Mail Hold For Pickup'),
+                '34'     => Mage::helper('usa')->__('Priority Mail Large Flat Rate Box Hold For Pickup'),
+                '35'     => Mage::helper('usa')->__('Priority Mail Medium Flat Rate Box Hold For Pickup'),
+                '36'     => Mage::helper('usa')->__('Priority Mail Small Flat Rate Box Hold For Pickup'),
+                '37'     => Mage::helper('usa')->__('Priority Mail Flat Rate Envelope Hold For Pickup'),
+                '42'     => Mage::helper('usa')->__('Priority Mail Small Flat Rate Envelope'),
+                '43'     => Mage::helper('usa')->__('Priority Mail Small Flat Rate Envelope Hold For Pickup'),
+                '53'     => Mage::helper('usa')->__('First-Class Package Service Hold For Pickup'),
+                '55'     => Mage::helper('usa')->__('Priority Mail Express Flat Rate Boxes'),
+                '56'     => Mage::helper('usa')->__('Priority Mail Express Flat Rate Boxes Hold For Pickup'),
+                '57'     => Mage::helper('usa')->__('Priority Mail Express Sunday/Holiday Delivery Flat Rate Boxes'),
+                '61'     => Mage::helper('usa')->__('First-Class Package Service'),
+                'INT_1'  => Mage::helper('usa')->__('Priority Mail Express International'),
+                'INT_2'  => Mage::helper('usa')->__('Priority Mail International'),
+                'INT_4'  => Mage::helper('usa')->__('Global Express Guaranteed (GXG)'),
+                'INT_6'  => Mage::helper('usa')->__('Global Express Guaranteed Non-Document Rectangular'),
+                'INT_7'  => Mage::helper('usa')->__('Global Express Guaranteed Non-Document Non-Rectangular'),
+                'INT_8'  => Mage::helper('usa')->__('Priority Mail International Flat Rate Envelope'),
+                'INT_9'  => Mage::helper('usa')->__('Priority Mail International Medium Flat Rate Box'),
+                'INT_10' => Mage::helper('usa')->__('Priority Mail Express International Flat Rate Envelope'),
+                'INT_11' => Mage::helper('usa')->__('Priority Mail International Large Flat Rate Box'),
+                'INT_12' => Mage::helper('usa')->__('USPS GXG Envelopes'),
+                'INT_13' => Mage::helper('usa')->__('First-Class Mail International Letter'),
+                'INT_14' => Mage::helper('usa')->__('First-Class Mail International Large Envelope'),
+                'INT_15' => Mage::helper('usa')->__('First-Class Package International Service'),
+                'INT_16' => Mage::helper('usa')->__('Priority Mail International Small Flat Rate Box'),
+                'INT_20' => Mage::helper('usa')->__('Priority Mail International Small Flat Rate Envelope'),
+                'INT_26' => Mage::helper('usa')->__('Priority Mail Express International Flat Rate Boxes'),
+            ),
 
-            'service'=>array(
-                'FIRST CLASS' => Mage::helper('usa')->__('First-Class'),
-                'PRIORITY'    => Mage::helper('usa')->__('Priority Mail'),
-                'EXPRESS'     => Mage::helper('usa')->__('Express Mail'),
-                'BPM'         => Mage::helper('usa')->__('Bound Printed Matter'),
-                'PARCEL'      => Mage::helper('usa')->__('Parcel Post'),
-                'MEDIA'       => Mage::helper('usa')->__('Media Mail'),
-                'LIBRARY'     => Mage::helper('usa')->__('Library'),
+            'service_to_code' => array(
+                '0_FCLE' => 'First Class',
+                '0_FCL'  => 'First Class',
+                '0_FCP'  => 'First Class',
+                '1'      => 'Priority',
+                '2'      => 'Priority Express',
+                '3'      => 'Priority Express',
+                '4'      => 'Standard Post',
+                '6'      => 'Media',
+                '7'      => 'Library',
+                '13'     => 'Priority Express',
+                '16'     => 'Priority',
+                '17'     => 'Priority',
+                '22'     => 'Priority',
+                '23'     => 'Priority Express',
+                '25'     => 'Priority Express',
+                '27'     => 'Priority Express',
+                '28'     => 'Priority',
+                '33'     => 'Priority',
+                '34'     => 'Priority',
+                '35'     => 'Priority',
+                '36'     => 'Priority',
+                '37'     => 'Priority',
+                '42'     => 'Priority',
+                '43'     => 'Priority',
+                '53'     => 'First Class',
+                '55'     => 'Priority Express',
+                '56'     => 'Priority Express',
+                '57'     => 'Priority Express',
+                '61'     => 'First Class',
+                'INT_1'  => 'Priority Express',
+                'INT_2'  => 'Priority',
+                'INT_4'  => 'Priority Express',
+                'INT_6'  => 'Priority Express',
+                'INT_7'  => 'Priority Express',
+                'INT_8'  => 'Priority',
+                'INT_9'  => 'Priority',
+                'INT_10' => 'Priority Express',
+                'INT_11' => 'Priority',
+                'INT_12' => 'Priority Express',
+                'INT_13' => 'First Class',
+                'INT_14' => 'First Class',
+                'INT_15' => 'First Class',
+                'INT_16' => 'Priority',
+                'INT_20' => 'Priority',
+                'INT_26' => 'Priority Express',
             ),
 
-            'service_to_code'=>array(
-                'First-Class'                                   => 'FIRST CLASS',
-                'First-Class Mail International Large Envelope' => 'FIRST CLASS',
-                'First-Class Mail International Letter'         => 'FIRST CLASS',
-                'First-Class Mail International Package'        => 'FIRST CLASS',
-                'First-Class Mail International Parcel'         => 'FIRST CLASS',
-                'First-Class Mail'                 => 'FIRST CLASS',
-                'First-Class Mail Flat'            => 'FIRST CLASS',
-                'First-Class Mail Large Envelope'  => 'FIRST CLASS',
-                'First-Class Mail International'   => 'FIRST CLASS',
-                'First-Class Mail Letter'          => 'FIRST CLASS',
-                'First-Class Mail Parcel'          => 'FIRST CLASS',
-                'First-Class Mail Package'         => 'FIRST CLASS',
-                'Parcel Post'                      => 'PARCEL',
-                'Bound Printed Matter'             => 'BPM',
-                'Media Mail'                       => 'MEDIA',
-                'Library Mail'                     => 'LIBRARY',
-                'Express Mail'                     => 'EXPRESS',
-                'Express Mail PO to PO'            => 'EXPRESS',
-                'Express Mail Flat Rate Envelope'  => 'EXPRESS',
-                'Express Mail Flat-Rate Envelope Sunday/Holiday Guarantee'  => 'EXPRESS',
-                'Express Mail Sunday/Holiday Guarantee'            => 'EXPRESS',
-                'Express Mail Flat Rate Envelope Hold For Pickup'  => 'EXPRESS',
-                'Express Mail Hold For Pickup'                     => 'EXPRESS',
-                'Global Express Guaranteed (GXG)'                  => 'EXPRESS',
-                'Global Express Guaranteed Non-Document Rectangular'     => 'EXPRESS',
-                'Global Express Guaranteed Non-Document Non-Rectangular' => 'EXPRESS',
-                'USPS GXG Envelopes'                               => 'EXPRESS',
-                'Express Mail International'                       => 'EXPRESS',
-                'Express Mail International Flat Rate Envelope'    => 'EXPRESS',
-                'Priority Mail'                        => 'PRIORITY',
-                'Priority Mail Small Flat Rate Box'    => 'PRIORITY',
-                'Priority Mail Medium Flat Rate Box'   => 'PRIORITY',
-                'Priority Mail Large Flat Rate Box'    => 'PRIORITY',
-                'Priority Mail Flat Rate Box'          => 'PRIORITY',
-                'Priority Mail Flat Rate Envelope'     => 'PRIORITY',
-                'Priority Mail International'                            => 'PRIORITY',
-                'Priority Mail International Flat Rate Envelope'         => 'PRIORITY',
-                'Priority Mail International Small Flat Rate Box'        => 'PRIORITY',
-                'Priority Mail International Medium Flat Rate Box'       => 'PRIORITY',
-                'Priority Mail International Large Flat Rate Box'        => 'PRIORITY',
-                'Priority Mail International Flat Rate Box'              => 'PRIORITY'
+            // Added because USPS has different services but with same CLASSID value, which is "0"
+            'method_to_code' => array(
+                'First-Class Mail Large Envelope' => '0_FCLE',
+                'First-Class Mail Letter'         => '0_FCL',
+                'First-Class Mail Parcel'         => '0_FCP',
             ),
 
             'first_class_mail_type'=>array(
@@ -610,8 +640,8 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
 
             'container'=>array(
                 'VARIABLE'           => Mage::helper('usa')->__('Variable'),
-                'FLAT RATE BOX'      => Mage::helper('usa')->__('Flat-Rate Box'),
                 'FLAT RATE ENVELOPE' => Mage::helper('usa')->__('Flat-Rate Envelope'),
+                'FLAT RATE BOX'      => Mage::helper('usa')->__('Flat-Rate Box'),
                 'RECTANGULAR'        => Mage::helper('usa')->__('Rectangular'),
                 'NONRECTANGULAR'     => Mage::helper('usa')->__('Non-rectangular'),
             ),
@@ -622,33 +652,49 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                     'filters'    => array(
                         'within_us' => array(
                             'method' => array(
-                                'Express Mail Flat Rate Envelope',
-                                'Express Mail Flat Rate Envelope Hold For Pickup',
+                                'Priority Mail Express Flat Rate Envelope',
+                                'Priority Mail Express Flat Rate Envelope Hold For Pickup',
                                 'Priority Mail Flat Rate Envelope',
                                 'Priority Mail Large Flat Rate Box',
                                 'Priority Mail Medium Flat Rate Box',
                                 'Priority Mail Small Flat Rate Box',
-                                'Express Mail',
+                                'Priority Mail Express Hold For Pickup',
+                                'Priority Mail Express',
                                 'Priority Mail',
-                                'Parcel Post',
+                                'Priority Mail Hold For Pickup',
+                                'Priority Mail Large Flat Rate Box Hold For Pickup',
+                                'Priority Mail Medium Flat Rate Box Hold For Pickup',
+                                'Priority Mail Small Flat Rate Box Hold For Pickup',
+                                'Priority Mail Flat Rate Envelope Hold For Pickup',
+                                'Priority Mail Small Flat Rate Envelope',
+                                'Priority Mail Small Flat Rate Envelope Hold For Pickup',
+                                'First-Class Package Service Hold For Pickup',
+                                'Priority Mail Express Flat Rate Boxes',
+                                'Priority Mail Express Flat Rate Boxes Hold For Pickup',
+                                'Standard Post',
                                 'Media Mail',
                                 'First-Class Mail Large Envelope',
+                                'Priority Mail Express Sunday/Holiday Delivery',
+                                'Priority Mail Express Sunday/Holiday Delivery Flat Rate Envelope',
+                                'Priority Mail Express Sunday/Holiday Delivery Flat Rate Boxes',
                             )
                         ),
                         'from_us' => array(
                             'method' => array(
-                                'Express Mail International Flat Rate Envelope',
+                                'Priority Mail Express International Flat Rate Envelope',
                                 'Priority Mail International Flat Rate Envelope',
                                 'Priority Mail International Large Flat Rate Box',
                                 'Priority Mail International Medium Flat Rate Box',
                                 'Priority Mail International Small Flat Rate Box',
+                                'Priority Mail International Small Flat Rate Envelope',
+                                'Priority Mail Express International Flat Rate Boxes',
                                 'Global Express Guaranteed (GXG)',
                                 'USPS GXG Envelopes',
-                                'Express Mail International',
+                                'Priority Mail Express International',
                                 'Priority Mail International',
-                                'First-Class Mail International Package',
+                                'First-Class Mail International Letter',
                                 'First-Class Mail International Large Envelope',
-                                'First-Class Mail International Parcel',
+                                'First-Class Package International Service',
                             )
                         )
                     )
@@ -661,6 +707,10 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                                 'Priority Mail Large Flat Rate Box',
                                 'Priority Mail Medium Flat Rate Box',
                                 'Priority Mail Small Flat Rate Box',
+                                'Priority Mail International Large Flat Rate Box',
+                                'Priority Mail International Medium Flat Rate Box',
+                                'Priority Mail International Small Flat Rate Box',
+                                'Priority Mail Express Sunday/Holiday Delivery Flat Rate Boxes',
                             )
                         ),
                         'from_us' => array(
@@ -677,15 +727,22 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                     'filters'    => array(
                         'within_us' => array(
                             'method' => array(
-                                'Express Mail Flat Rate Envelope',
-                                'Express Mail Flat Rate Envelope Hold For Pickup',
+                                'Priority Mail Express Flat Rate Envelope',
+                                'Priority Mail Express Flat Rate Envelope Hold For Pickup',
                                 'Priority Mail Flat Rate Envelope',
+                                'First-Class Mail Large Envelope',
+                                'Priority Mail Flat Rate Envelope Hold For Pickup',
+                                'Priority Mail Small Flat Rate Envelope',
+                                'Priority Mail Small Flat Rate Envelope Hold For Pickup',
+                                'Priority Mail Express Sunday/Holiday Delivery Flat Rate Envelope',
                             )
                         ),
                         'from_us' => array(
                             'method' => array(
-                                'Express Mail International Flat Rate Envelope',
+                                'Priority Mail Express International Flat Rate Envelope',
                                 'Priority Mail International Flat Rate Envelope',
+                                'First-Class Mail International Large Envelope',
+                                'Priority Mail International Small Flat Rate Envelope',
                             )
                         )
                     )
@@ -695,19 +752,20 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                     'filters'    => array(
                         'within_us' => array(
                             'method' => array(
-                                'Express Mail',
+                                'Priority Mail Express',
                                 'Priority Mail',
-                                'Parcel Post',
+                                'Standard Post',
                                 'Media Mail',
+                                'Library Mail',
+                                'First-Class Package Service'
                             )
                         ),
                         'from_us' => array(
                             'method' => array(
                                 'USPS GXG Envelopes',
-                                'Express Mail International',
+                                'Priority Mail Express International',
                                 'Priority Mail International',
-                                'First-Class Mail International Package',
-                                'First-Class Mail International Parcel',
+                                'First-Class Package International Service',
                             )
                         )
                     )
@@ -717,25 +775,25 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                     'filters'    => array(
                         'within_us' => array(
                             'method' => array(
-                                'Express Mail',
+                                'Priority Mail Express',
                                 'Priority Mail',
-                                'Parcel Post',
+                                'Standard Post',
                                 'Media Mail',
+                                'Library Mail',
+                                'First-Class Package Service'
                             )
                         ),
                         'from_us' => array(
                             'method' => array(
                                 'Global Express Guaranteed (GXG)',
-                                'USPS GXG Envelopes',
-                                'Express Mail International',
+                                'Priority Mail Express International',
                                 'Priority Mail International',
-                                'First-Class Mail International Package',
-                                'First-Class Mail International Parcel',
+                                'First-Class Package International Service',
                             )
                         )
                     )
                 ),
-             ),
+            ),
 
             'size'=>array(
                 'REGULAR'     => Mage::helper('usa')->__('Regular'),
@@ -753,13 +811,6 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
             ),
         );
 
-        $methods = $this->getConfigData('methods');
-        if (!empty($methods)) {
-            $codes['method'] = explode(",", $methods);
-        } else {
-            $codes['method'] = array();
-        }
-
         if (!isset($codes[$type])) {
             return false;
         } elseif (''===$code) {
@@ -776,18 +827,18 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
     /**
      * Get tracking
      *
-     * @param mixed $trackings
+     * @param mixed $trackingData
      * @return mixed
      */
-    public function getTracking($trackings)
+    public function getTracking($trackingData)
     {
-        $this->setTrackingReqeust();
+        $this->setTrackingRequest();
 
-        if (!is_array($trackings)) {
-            $trackings = array($trackings);
+        if (!is_array($trackingData)) {
+            $trackingData = array($trackingData);
         }
 
-        $this->_getXmlTracking($trackings);
+        $this->_getXmlTracking($trackingData);
 
         return $this->_result;
     }
@@ -797,7 +848,7 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
      *
      * @return null
      */
-    protected function setTrackingReqeust()
+    protected function setTrackingRequest()
     {
         $r = new Varien_Object();
 
@@ -810,14 +861,13 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
     /**
      * Send request for tracking
      *
-     * @param array $tracking
-     * @return null
+     * @param array $trackingData
      */
-    protected function _getXmlTracking($trackings)
+    protected function _getXmlTracking($trackingData)
     {
          $r = $this->_rawTrackRequest;
 
-         foreach ($trackings as $tracking) {
+         foreach ($trackingData as $tracking) {
              $xml = new SimpleXMLElement('<?xml version = "1.0" encoding = "UTF-8"?><TrackRequest/>');
              $xml->addAttribute('USERID', $r->getUserId());
 
@@ -855,11 +905,11 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
     /**
      * Parse xml tracking response
      *
-     * @param array $trackingvalue
+     * @param array $trackingValue
      * @param string $response
      * @return null
      */
-    protected function _parseXmlTrackingResponse($trackingvalue, $response)
+    protected function _parseXmlTrackingResponse($trackingValue, $response)
     {
         $errorTitle = Mage::helper('usa')->__('Unable to retrieve tracking');
         $resultArr=array();
@@ -890,20 +940,19 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
         if (!$this->_result) {
             $this->_result = Mage::getModel('shipping/tracking_result');
         }
-        $defaults = $this->getDefaults();
 
         if ($resultArr) {
              $tracking = Mage::getModel('shipping/tracking_result_status');
              $tracking->setCarrier('usps');
              $tracking->setCarrierTitle($this->getConfigData('title'));
-             $tracking->setTracking($trackingvalue);
+             $tracking->setTracking($trackingValue);
              $tracking->setTrackSummary($resultArr['tracksummary']);
              $this->_result->append($tracking);
          } else {
             $error = Mage::getModel('shipping/tracking_result_error');
             $error->setCarrier('usps');
             $error->setCarrierTitle($this->getConfigData('title'));
-            $error->setTracking($trackingvalue);
+            $error->setTracking($trackingValue);
             $error->setErrorMessage($errorTitle);
             $this->_result->append($error);
          }
@@ -918,8 +967,8 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
     {
         $statuses = '';
         if ($this->_result instanceof Mage_Shipping_Model_Tracking_Result) {
-            if ($trackings = $this->_result->getAllTrackings()) {
-                foreach ($trackings as $tracking) {
+            if ($trackingData = $this->_result->getAllTrackings()) {
+                foreach ($trackingData as $tracking) {
                     if($data = $tracking->getAllData()) {
                         if (!empty($data['track_summary'])) {
                             $statuses .= Mage::helper('usa')->__($data['track_summary']);
@@ -946,7 +995,7 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
         $allowed = explode(',', $this->getConfigData('allowed_methods'));
         $arr = array();
         foreach ($allowed as $k) {
-            $arr[$k] = $k;
+            $arr[$k] = $this->getCode('method', $k);
         }
         return $arr;
     }
@@ -1279,24 +1328,34 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
      *
      * @param Varien_Object $request
      * @param string $serviceType
+     *
+     * @throws Exception
+     *
      * @return string
      */
     protected function _formUsSignatureConfirmationShipmentRequest(Varien_Object $request, $serviceType)
     {
         switch ($serviceType) {
             case 'PRIORITY':
+            case 'Priority':
                 $serviceType = 'Priority';
                 break;
             case 'FIRST CLASS':
+            case 'First Class':
                 $serviceType = 'First Class';
                 break;
-            case 'PARCEL':
-                $serviceType = 'Parcel Post';
+            case 'STANDARD':
+            case 'Standard Post':
+                $serviceType = 'Standard Post';
                 break;
             case 'MEDIA':
+            case 'Media Mail':
+            case 'Media':
                 $serviceType = 'Media Mail';
                 break;
             case 'LIBRARY':
+            case 'Library Mail':
+            case 'Library':
                 $serviceType = 'Library Mail';
                 break;
             default:
@@ -1615,7 +1674,7 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
         $service = $this->getCode('service_to_code', $request->getShippingMethod());
         $recipientUSCountry = $this->_isUSCountry($request->getRecipientAddressCountryCode());
 
-        if ($recipientUSCountry && $service == 'EXPRESS') {
+        if ($recipientUSCountry && $service == 'Priority Express') {
             $requestXml = $this->_formUsExpressShipmentRequest($request);
             $api = 'ExpressMailLabel';
         } else if ($recipientUSCountry) {
@@ -1625,10 +1684,10 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
             } else {
                 $api = 'SignatureConfirmationCertifyV3';
             }
-        } else if ($service == 'FIRST CLASS') {
+        } else if ($service == 'First Class') {
             $requestXml = $this->_formIntlShipmentRequest($request);
             $api = 'FirstClassMailIntl';
-        } else if ($service == 'PRIORITY') {
+        } else if ($service == 'Priority') {
             $requestXml = $this->_formIntlShipmentRequest($request);
             $api = 'PriorityMailIntl';
         } else {
@@ -1658,7 +1717,7 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
             $this->_debug($debugData);
             $result->setErrors($debugData['result']['error']);
         } else {
-            if ($recipientUSCountry && $service == 'EXPRESS') {
+            if ($recipientUSCountry && $service == 'Priority Express') {
                 $labelContent = base64_decode((string) $response->EMLabel);
                 $trackingNumber = (string) $response->EMConfirmationNumber;
             } else if ($recipientUSCountry) {
@@ -1796,4 +1855,36 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
 
         return array($zip5, $zip4);
     }
+
+    /**
+     * @deprecated
+     */
+    protected function _methodsMapper($method, $valuesToLabels = true)
+    {
+        return $method;
+    }
+
+    /**
+     * @deprecated
+     */
+    public function getMethodLabel($value)
+    {
+        return $this->_methodsMapper($value, true);
+    }
+
+    /**
+     * @deprecated
+     */
+    public function getMethodValue($label)
+    {
+        return $this->_methodsMapper($label, false);
+    }
+
+    /**
+     * @deprecated
+     */
+    protected function setTrackingReqeust()
+    {
+        $this->setTrackingRequest();
+    }
 }
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps/Source/Method.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps/Source/Method.php
index 3671795..149a473 100644
--- app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps/Source/Method.php
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps/Source/Method.php
@@ -29,10 +29,11 @@ class Mage_Usa_Model_Shipping_Carrier_Usps_Source_Method
 {
     public function toOptionArray()
     {
+        /** @var $usps Mage_Usa_Model_Shipping_Carrier_Usps */
         $usps = Mage::getSingleton('usa/shipping_carrier_usps');
         $arr = array();
-        foreach ($usps->getCode('method') as $v) {
-            $arr[] = array('value'=>$v, 'label'=>$v);
+        foreach ($usps->getCode('method') as $k => $v) {
+            $arr[] = array('value' => $k, 'label' => Mage::helper('usa')->__($v));
         }
         return $arr;
     }
diff --git app/code/core/Mage/Usa/etc/config.xml app/code/core/Mage/Usa/etc/config.xml
index 5eaa96c..ee86fcd 100644
--- app/code/core/Mage/Usa/etc/config.xml
+++ app/code/core/Mage/Usa/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Mage_Usa>
-            <version>1.6.0.1</version>
+            <version>1.6.0.1.1.2</version>
         </Mage_Usa>
     </modules>
     <global>
@@ -185,7 +185,7 @@
             <usps>
                 <active>0</active>
                 <sallowspecific>0</sallowspecific>
-                <allowed_methods>Bound Printed Matter,Express Mail,Express Mail Flat Rate Envelope,Express Mail Flat Rate Envelope Hold For Pickup,Express Mail Flat-Rate Envelope Sunday/Holiday Guarantee,Express Mail Hold For Pickup,Express Mail International,Express Mail International Flat Rate Envelope,Express Mail PO to PO,Express Mail Sunday/Holiday Guarantee,First-Class Mail International Large Envelope,First-Class Mail International Letters,First-Class Mail International Package,First-Class Mail International Parcel,First-Class,First-Class Mail,First-Class Mail Flat,First-Class Mail Large Envelope,First-Class Mail International,First-Class Mail Letter,First-Class Mail Parcel,First-Class Mail Package,Global Express Guaranteed (GXG),Global Express Guaranteed Non-Document Non-Rectangular,Global Express Guaranteed Non-Document Rectangular,Library Mail,Media Mail,Parcel Post,Priority Mail,Priority Mail Small Flat Rate Box,Priority Mail Medium Flat Rate Box,Priority Mail Large Flat Rate Box,Priority Mail Flat Rate Box,Priority Mail Flat Rate Envelope,Priority Mail International,Priority Mail International Flat Rate Box,Priority Mail International Flat Rate Envelope,Priority Mail International Small Flat Rate Box,Priority Mail International Medium Flat Rate Box,Priority Mail International Large Flat Rate Box,USPS GXG Envelopes</allowed_methods>
+                <allowed_methods>0_FCLE,0_FCL,0_FCP,1,2,3,4,6,7,13,16,17,22,23,25,27,28,33,34,35,36,37,42,43,53,55,56,57,61,INT_1,INT_2,INT_4,INT_6,INT_7,INT_8,INT_9,INT_10,INT_11,INT_12,INT_13,INT_14,INT_15,INT_16,INT_20,INT_26</allowed_methods>
                 <container>VARIABLE</container>
                 <cutoff_cost/>
                 <free_method/>
@@ -194,7 +194,6 @@
                 <shipment_requesttype>0</shipment_requesttype>
                 <handling/>
                 <machinable>true</machinable>
-                <methods>Bound Printed Matter,Express Mail,Express Mail Flat Rate Envelope,Express Mail Flat Rate Envelope Hold For Pickup,Express Mail Flat-Rate Envelope Sunday/Holiday Guarantee,Express Mail Hold For Pickup,Express Mail International,Express Mail International Flat Rate Envelope,Express Mail PO to PO,Express Mail Sunday/Holiday Guarantee,First-Class Mail International Large Envelope,First-Class Mail International Letters,First-Class Mail International Package,First-Class Mail International Parcel,First-Class,First-Class Mail,First-Class Mail Flat,First-Class Mail Large Envelope,First-Class Mail International,First-Class Mail Letter,First-Class Mail Parcel,First-Class Mail Package,Global Express Guaranteed (GXG),Global Express Guaranteed Non-Document Non-Rectangular,Global Express Guaranteed Non-Document Rectangular,Library Mail,Media Mail,Parcel Post,Priority Mail,Priority Mail Small Flat Rate Box,Priority Mail Medium Flat Rate Box,Priority Mail Large Flat Rate Box,Priority Mail Flat Rate Box,Priority Mail Flat Rate Envelope,Priority Mail International,Priority Mail International Flat Rate Box,Priority Mail International Flat Rate Envelope,Priority Mail International Small Flat Rate Box,Priority Mail International Medium Flat Rate Box,Priority Mail International Large Flat Rate Box,USPS GXG Envelopes</methods>
                 <model>usa/shipping_carrier_usps</model>
                 <size>REGULAR</size>
                 <title>United States Postal Service</title>
diff --git app/code/core/Mage/Usa/sql/usa_setup/upgrade-1.6.0.1.1.1-1.6.0.1.1.2.php app/code/core/Mage/Usa/sql/usa_setup/upgrade-1.6.0.1.1.1-1.6.0.1.1.2.php
new file mode 100644
index 0000000..d1f3461
--- /dev/null
+++ app/code/core/Mage/Usa/sql/usa_setup/upgrade-1.6.0.1.1.1-1.6.0.1.1.2.php
@@ -0,0 +1,108 @@
+<?php
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
+ * @category    Mage
+ * @package     Mage_Usa
+ * @copyright   Copyright (c) 2013 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://www.magentocommerce.com/license/enterprise-edition
+ */
+
+/* @var $installer Mage_Core_Model_Resource_Setup */
+$installer = $this;
+$configDataTable = $installer->getTable('core/config_data');
+$connection = $installer->getConnection();
+
+$oldToNewMethodCodesMap = array(
+    'First-Class'                                               => '0_FCLE',
+    'First-Class Mail International Large Envelope'             => 'INT_14',
+    'First-Class Mail International Letter'                     => 'INT_13',
+    'First-Class Mail International Letters'                    => 'INT_13',
+    'First-Class Mail International Package'                    => 'INT_15',
+    'First-Class Mail International Parcel'                     => 'INT_13',
+    'First-Class Package International Service'                 => 'INT_15',
+    'First-Class Mail'                                          => '0_FCLE',
+    'First-Class Mail Flat'                                     => '0_FCLE',
+    'First-Class Mail Large Envelope'                           => '0_FCLE',
+    'First-Class Mail International'                            => 'INT_14',
+    'First-Class Mail Letter'                                   => '0_FCL',
+    'First-Class Mail Parcel'                                   => '0_FCP',
+    'First-Class Mail Package'                                  => '0_FCP',
+    'Parcel Post'                                               => '4',
+    'Standard Post'                                             => '4',
+    'Media Mail'                                                => '6',
+    'Library Mail'                                              => '7',
+    'Express Mail'                                              => '3',
+    'Express Mail PO to PO'                                     => '3',
+    'Express Mail Flat Rate Envelope'                           => '13',
+    'Express Mail Flat-Rate Envelope Sunday/Holiday Guarantee'  => '25',
+    'Express Mail Sunday/Holiday Guarantee'                     => '23',
+    'Express Mail Flat Rate Envelope Hold For Pickup'           => '27',
+    'Express Mail Hold For Pickup'                              => '2',
+    'Global Express Guaranteed (GXG)'                           => 'INT_4',
+    'Global Express Guaranteed Non-Document Rectangular'        => 'INT_6',
+    'Global Express Guaranteed Non-Document Non-Rectangular'    => 'INT_7',
+    'USPS GXG Envelopes'                                        => 'INT_12',
+    'Express Mail International'                                => 'INT_1',
+    'Express Mail International Flat Rate Envelope'             => 'INT_10',
+    'Priority Mail'                                             => '1',
+    'Priority Mail Small Flat Rate Box'                         => '28',
+    'Priority Mail Medium Flat Rate Box'                        => '17',
+    'Priority Mail Large Flat Rate Box'                         => '22',
+    'Priority Mail Flat Rate Envelope'                          => '16',
+    'Priority Mail International'                               => 'INT_2',
+    'Priority Mail International Flat Rate Envelope'            => 'INT_8',
+    'Priority Mail International Small Flat Rate Box'           => 'INT_16',
+    'Priority Mail International Medium Flat Rate Box'          => 'INT_9',
+    'Priority Mail International Large Flat Rate Box'           => 'INT_11',
+);
+
+$select = $connection->select()
+        ->from($configDataTable)
+        ->where('path IN (?)',
+                array(
+                    'carriers/usps/free_method',
+                    'carriers/usps/allowed_methods'
+               )
+        );
+$oldConfigValues = $connection->fetchAll($select);
+
+foreach ($oldConfigValues as $oldValue) {
+    $newValue = '';
+    if (stripos($oldValue['path'], 'free_method') && isset($oldToNewMethodCodesMap[$oldValue['value']])) {
+        $newValue = $oldToNewMethodCodesMap[$oldValue['value']];
+    } else if (stripos($oldValue['path'], 'allowed_methods')) {
+        foreach (explode(',', $oldValue['value']) as $shippingMethod) {
+            if (isset($oldToNewMethodCodesMap[$shippingMethod])) {
+                $newValue[] = $oldToNewMethodCodesMap[$shippingMethod];
+            }
+        }
+        $newValue = implode($newValue, ',');
+    } else {
+        continue;
+    }
+
+    if (!empty($newValue) && $newValue != $oldValue['value']) {
+        $whereConfigId = $connection->quoteInto('config_id = ?', $oldValue['config_id']);
+        $connection->update($configDataTable,
+                      array('value' => $newValue),
+                      $whereConfigId
+        );
+    }
+}
