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


SUPEE-1868-1-7-0-0 | EE_1.7.0.0 | v1 | 432f6f31be34ae064d78a1c485ff7c61576f8d3d | Sun Jul 28 18:29:31 2013 +0300 | v1.7.0.0..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps.php
index 4b4937d..0aa4711 100644
--- app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps.php
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps.php
@@ -28,7 +28,7 @@
 /**
  * USPS shipping rates estimation
  *
- * @link       http://www.usps.com/webtools/htm/Development-Guide.htm
+ * @link       http://www.usps.com/webtools/htm/Development-Guide-v3-0b.htm
  * @category   Mage
  * @package    Mage_Usa
  * @author      Magento Core Team <core@magentocommerce.com>
@@ -115,20 +115,9 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
 
         $r->setDestCountryId($destCountry);
 
-        /*
-        for GB, we cannot use United Kingdom
-        */
-        if ($destCountry=='GB') {
-           $countryName = 'Great Britain and Northern Ireland';
-        } else {
-             $countries = Mage::getResourceModel('directory/country_collection')
-                            ->addCountryIdFilter($destCountry)
-                            ->load()
-                            ->getItems();
-            $country = array_shift($countries);
-            $countryName = $country->getName();
+        if (!$this->_isUSCountry($destCountry)) {
+            $r->setDestCountryName($this->_getCountryName($destCountry));
         }
-        $r->setDestCountryName($countryName);
 
         if ($request->getDestPostcode()) {
             $r->setDestPostal($request->getDestPostcode());
@@ -136,7 +125,7 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
 
         $weight = $this->getTotalNumOfBoxes($request->getPackageWeight());
         $r->setWeightPounds(floor($weight));
-        $r->setWeightOunces(round(($weight-floor($weight))*16, 1));
+        $r->setWeightOunces(round(($weight-floor($weight)) * 16, 1));
         if ($request->getFreeMethodWeight()!=$request->getPackageWeight()) {
             $r->setFreeMethodWeight($request->getFreeMethodWeight());
         }
@@ -165,18 +154,23 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
 
         $weight = $this->getTotalNumOfBoxes($r->getFreeMethodWeight());
         $r->setWeightPounds(floor($weight));
-        $r->setWeightOunces(round(($weight-floor($weight))*16, 1));
+        $r->setWeightOunces(round(($weight-floor($weight)) * 16, 1));
         $r->setService($freeMethod);
     }
 
+    /**
+     * Build RateV3 request, send it to USPS gateway and retrieve quotes in XML format
+     *
+     * @link http://www.usps.com/webtools/htm/Rate-Calculators-v2-3.htm
+     * @return Mage_Shipping_Model_Rate_Result
+     */
     protected function _getXmlQuotes()
     {
         $r = $this->_rawRequest;
-        if ($r->getDestCountryId() == self::USA_COUNTRY_ID || $r->getDestCountryId() == self::PUERTORICO_COUNTRY_ID) {
+        if ($this->_isUSCountry($r->getDestCountryId())) {
             $xml = new SimpleXMLElement('<?xml version = "1.0" encoding = "UTF-8"?><RateV3Request/>');
 
             $xml->addAttribute('USERID', $r->getUserId());
-
             $package = $xml->addChild('Package');
                 $package->addAttribute('ID', 0);
                 $service = $this->getCode('service_to_code', $r->getService());
@@ -244,173 +238,212 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
         return $this->_parseXmlResponse($responseBody);;
     }
 
+    /**
+     * Parse calculated rates
+     *
+     * @link http://www.usps.com/webtools/htm/Rate-Calculators-v2-3.htm
+     * @param string $response
+     * @return Mage_Shipping_Model_Rate_Result
+     */
     protected function _parseXmlResponse($response)
     {
         $costArr = array();
         $priceArr = array();
-        $errorTitle = 'Unable to retrieve quotes';
-        if (strlen(trim($response))>0) {
-            if (strpos(trim($response), '<?xml')===0) {
+        if (strlen(trim($response)) > 0) {
+            if (strpos(trim($response), '<?xml') === 0) {
                 if (preg_match('#<\?xml version="1.0"\?>#', $response)) {
                     $response = str_replace('<?xml version="1.0"?>', '<?xml version="1.0" encoding="ISO-8859-1"?>', $response);
                 }
 
                 $xml = simplexml_load_string($response);
-                    if (is_object($xml)) {
-                        if (is_object($xml->Number) && is_object($xml->Description) && (string)$xml->Description!='') {
-                            $errorTitle = (string)$xml->Description;
-                        } elseif (is_object($xml->Package) && is_object($xml->Package->Error) && is_object($xml->Package->Error->Description) && (string)$xml->Package->Error->Description!='') {
-                            $errorTitle = (string)$xml->Package->Error->Description;
-                        } else {
-                            $errorTitle = 'Unknown error';
-                        }
-                        $r = $this->_rawRequest;
-                        $allowedMethods = explode(",", $this->getConfigData('allowed_methods'));
-                        $allMethods = $this->getCode('method');
-                        $newMethod = false;
-                        if ($r->getDestCountryId() == self::USA_COUNTRY_ID || $r->getDestCountryId() == self::PUERTORICO_COUNTRY_ID) {
-                            if (is_object($xml->Package) && is_object($xml->Package->Postage)) {
-                                foreach ($xml->Package->Postage as $postage) {
-//                                    if (in_array($this->getCode('service_to_code', (string)$postage->MailService), $allowedMethods) && $this->getCode('service', $this->getCode('service_to_code', (string)$postage->MailService))) {
-                                    if (in_array((string)$postage->MailService, $allowedMethods)) {
-                                        $costArr[(string)$postage->MailService] = (string)$postage->Rate;
-//                                        $priceArr[(string)$postage->MailService] = $this->getMethodPrice((string)$postage->Rate, $this->getCode('service_to_code', (string)$postage->MailService));
-                                        $priceArr[(string)$postage->MailService] = $this->getMethodPrice((string)$postage->Rate, (string)$postage->MailService);
-                                    } elseif (!in_array((string)$postage->MailService, $allMethods)) {
-                                        $allMethods[] = (string)$postage->MailService;
-                                        $newMethod = true;
-                                    }
+                if (is_object($xml)) {
+                    $r = $this->_rawRequest;
+                    $allowedMethods = explode(",", $this->getConfigData('allowed_methods'));
+
+                    $serviceCodeToActualNameMap = array();
+                    /**
+                     * US Rates
+                     */
+                    if ($this->_isUSCountry($r->getDestCountryId())) {
+                        if (is_object($xml->Package) && is_object($xml->Package->Postage)) {
+                            foreach ($xml->Package->Postage as $postage) {
+                                $serviceName = $this->_filterServiceName((string)$postage->MailService);
+                                $_serviceCode = $this->getCode('method_to_code', $serviceName);
+                                $serviceCode = $_serviceCode ? $_serviceCode : (string)$postage->attributes()->CLASSID;
+                                $serviceCodeToActualNameMap[$serviceCode] = $serviceName;
+                                if (in_array($serviceCode, $allowedMethods)) {
+                                    $costArr[$serviceCode] = (string)$postage->Rate;
+                                    $priceArr[$serviceCode] = $this->getMethodPrice(
+                                        (string)$postage->Rate,
+                                        $serviceCode
+                                    );
                                 }
-                                asort($priceArr);
                             }
-                        } else {
-                            if (is_object($xml->Package) && is_object($xml->Package->Service)) {
-                                foreach ($xml->Package->Service as $service) {
-//                                    if (in_array($this->getCode('service_to_code', (string)$service->SvcDescription), $allowedMethods) && $this->getCode('service', $this->getCode('service_to_code', (string)$service->SvcDescription))) {
-                                    if (in_array((string)$service->SvcDescription, $allowedMethods)) {
-                                        $costArr[(string)$service->SvcDescription] = (string)$service->Postage;
-//                                        $priceArr[(string)$service->SvcDescription] = $this->getMethodPrice((string)$service->Postage, $this->getCode('service_to_code', (string)$service->SvcDescription));
-                                        $priceArr[(string)$service->SvcDescription] = $this->getMethodPrice((string)$service->Postage, (string)$service->SvcDescription);
-                                    } elseif (!in_array((string)$service->SvcDescription, $allMethods)) {
-                                        $allMethods[] = (string)$service->SvcDescription;
-                                        $newMethod = true;
-                                    }
+                            asort($priceArr);
+                        }
+                    }
+                    /**
+                     * International Rates
+                     */
+                    else {
+                        if (is_object($xml->Package) && is_object($xml->Package->Service)) {
+                            foreach ($xml->Package->Service as $service) {
+                                $serviceName = $this->_filterServiceName((string)$service->SvcDescription);
+                                $serviceCode = 'INT_' . (string)$service->attributes()->ID;
+                                $serviceCodeToActualNameMap[$serviceCode] = $serviceName;
+                                if (in_array($serviceCode, $allowedMethods)) {
+                                    $costArr[$serviceCode] = (string)$service->Postage;
+                                    $priceArr[$serviceCode] = $this->getMethodPrice(
+                                        (string)$service->Postage,
+                                        $serviceCode
+                                    );
                                 }
-                                asort($priceArr);
                             }
-                        }
-                        /*
-                        * following if statement is obsolete
-                        * we don't have adminhtml/config resoure model
-                        */
-                        if (false && $newMethod) {
-                            sort($allMethods);
-                            $insert['usps']['fields']['methods']['value'] = $allMethods;
-                            Mage::getResourceModel('adminhtml/config')->saveSectionPost('carriers','','',$insert);
+                            asort($priceArr);
                         }
                     }
-            } else {
-                $errorTitle = 'Response is in the wrong format';
+                }
             }
         }
 
         $result = Mage::getModel('shipping/rate_result');
-        $defaults = $this->getDefaults();
         if (empty($priceArr)) {
             $error = Mage::getModel('shipping/rate_result_error');
             $error->setCarrier('usps');
             $error->setCarrierTitle($this->getConfigData('title'));
-            //$error->setErrorMessage($errorTitle);
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
             }
         }
+
         return $result;
     }
 
-    public function getCode($type, $code='')
+    /**
+     * Get configuration data of carrier
+     *
+     * @param string $type
+     * @param string $code
+     * @return array|bool
+     */
+    public function getCode($type, $code = '')
     {
         $codes = array(
-
-            'service'=>array(
-                'FIRST CLASS' => Mage::helper('usa')->__('First-Class'),
-                'PRIORITY'    => Mage::helper('usa')->__('Priority Mail'),
-                'EXPRESS'     => Mage::helper('usa')->__('Express Mail'),
-                'BPM'         => Mage::helper('usa')->__('Bound Printed Matter'),
-                'PARCEL'      => Mage::helper('usa')->__('Parcel Post'),
-                'MEDIA'       => Mage::helper('usa')->__('Media Mail'),
-                'LIBRARY'     => Mage::helper('usa')->__('Library'),
-//                'ALL'         => Mage::helper('usa')->__('All Services'),
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
             ),
 
-/*
-            'method'=>array(
-                'First-Class',
-                'Express Mail',
-                'Express Mail PO to PO',
-                'Priority Mail',
-                'Parcel Post',
-                'Express Mail Flat-Rate Envelope',
-                'Priority Mail Flat-Rate Box',
-                'Bound Printed Matter',
-                'Media Mail',
-                'Library Mail',
-                'Priority Mail Flat-Rate Envelope',
-                'Global Express Guaranteed',
-                'Global Express Guaranteed Non-Document Rectangular',
-                'Global Express Guaranteed Non-Document Non-Rectangular',
-                'Express Mail International (EMS)',
-                'Express Mail International (EMS) Flat Rate Envelope',
-                'Priority Mail International',
-                'Priority Mail International Flat Rate Box',
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
-*/
-
-            'service_to_code'=>array(
-                'First-Class'                                   => 'FIRST CLASS',
-                'First-Class Mail International Large Envelope' => 'FIRST CLASS',
-                'First-Class Mail International Letters'        => 'FIRST CLASS',
-                'First-Class Mail International Package'        => 'FIRST CLASS',
-                'First-Class Mail'                 => 'FIRST CLASS',
-                'First-Class Mail Flat'            => 'FIRST CLASS',
-                'First-Class Mail International'   => 'FIRST CLASS',
-                'First-Class Mail Letter'          => 'FIRST CLASS',
-                'First-Class Mail Parcel'          => 'FIRST CLASS',
-                'Parcel Post'                      => 'PARCEL',
-                'Bound Printed Matter'             => 'BPM',
-                'Media Mail'                       => 'MEDIA',
-                'Library Mail'                     => 'LIBRARY',
-                'Express Mail'                     => 'EXPRESS',
-                'Express Mail PO to PO'            => 'EXPRESS',
-                'Express Mail Flat Rate Envelope'  => 'EXPRESS',
-                'Express Mail Flat Rate Envelope Hold For Pickup'  => 'EXPRESS',
-                'Global Express Guaranteed (GXG)'                  => 'EXPRESS',
-                'Global Express Guaranteed Non-Document Rectangular'     => 'EXPRESS',
-                'Global Express Guaranteed Non-Document Non-Rectangular' => 'EXPRESS',
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
+
+            // Added because USPS has different services but with same CLASSID value, which is "0"
+            'method_to_code' => array(
+                'First-Class Mail Large Envelope' => '0_FCLE',
+                'First-Class Mail Letter'         => '0_FCL',
+                'First-Class Mail Parcel'         => '0_FCP',
             ),
 
             'first_class_mail_type'=>array(
@@ -421,16 +454,164 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
 
             'container'=>array(
                 'VARIABLE'           => Mage::helper('usa')->__('Variable'),
-                'FLAT RATE BOX'      => Mage::helper('usa')->__('Flat-Rate Box'),
                 'FLAT RATE ENVELOPE' => Mage::helper('usa')->__('Flat-Rate Envelope'),
+                'FLAT RATE BOX'      => Mage::helper('usa')->__('Flat-Rate Box'),
                 'RECTANGULAR'        => Mage::helper('usa')->__('Rectangular'),
                 'NONRECTANGULAR'     => Mage::helper('usa')->__('Non-rectangular'),
             ),
 
+            'containers_filter' => array(
+                array(
+                    'containers' => array('VARIABLE'),
+                    'filters'    => array(
+                        'within_us' => array(
+                            'method' => array(
+                                'Priority Mail Express Flat Rate Envelope',
+                                'Priority Mail Express Flat Rate Envelope Hold For Pickup',
+                                'Priority Mail Flat Rate Envelope',
+                                'Priority Mail Large Flat Rate Box',
+                                'Priority Mail Medium Flat Rate Box',
+                                'Priority Mail Small Flat Rate Box',
+                                'Priority Mail Express Hold For Pickup',
+                                'Priority Mail Express',
+                                'Priority Mail',
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
+                                'Media Mail',
+                                'First-Class Mail Large Envelope',
+                                'Priority Mail Express Sunday/Holiday Delivery',
+                                'Priority Mail Express Sunday/Holiday Delivery Flat Rate Envelope',
+                                'Priority Mail Express Sunday/Holiday Delivery Flat Rate Boxes',
+                            )
+                        ),
+                        'from_us' => array(
+                            'method' => array(
+                                'Priority Mail Express International Flat Rate Envelope',
+                                'Priority Mail International Flat Rate Envelope',
+                                'Priority Mail International Large Flat Rate Box',
+                                'Priority Mail International Medium Flat Rate Box',
+                                'Priority Mail International Small Flat Rate Box',
+                                'Priority Mail International Small Flat Rate Envelope',
+                                'Priority Mail Express International Flat Rate Boxes',
+                                'Global Express Guaranteed (GXG)',
+                                'USPS GXG Envelopes',
+                                'Priority Mail Express International',
+                                'Priority Mail International',
+                                'First-Class Mail International Letter',
+                                'First-Class Mail International Large Envelope',
+                                'First-Class Package International Service',
+                            )
+                        )
+                    )
+                ),
+                array(
+                    'containers' => array('FLAT RATE BOX'),
+                    'filters'    => array(
+                        'within_us' => array(
+                            'method' => array(
+                                'Priority Mail Large Flat Rate Box',
+                                'Priority Mail Medium Flat Rate Box',
+                                'Priority Mail Small Flat Rate Box',
+                                'Priority Mail International Large Flat Rate Box',
+                                'Priority Mail International Medium Flat Rate Box',
+                                'Priority Mail International Small Flat Rate Box',
+                                'Priority Mail Express Sunday/Holiday Delivery Flat Rate Boxes',
+                            )
+                        ),
+                        'from_us' => array(
+                            'method' => array(
+                                'Priority Mail International Large Flat Rate Box',
+                                'Priority Mail International Medium Flat Rate Box',
+                                'Priority Mail International Small Flat Rate Box',
+                            )
+                        )
+                    )
+                ),
+                array(
+                    'containers' => array('FLAT RATE ENVELOPE'),
+                    'filters'    => array(
+                        'within_us' => array(
+                            'method' => array(
+                                'Priority Mail Express Flat Rate Envelope',
+                                'Priority Mail Express Flat Rate Envelope Hold For Pickup',
+                                'Priority Mail Flat Rate Envelope',
+                                'First-Class Mail Large Envelope',
+                                'Priority Mail Flat Rate Envelope Hold For Pickup',
+                                'Priority Mail Small Flat Rate Envelope',
+                                'Priority Mail Small Flat Rate Envelope Hold For Pickup',
+                                'Priority Mail Express Sunday/Holiday Delivery Flat Rate Envelope',
+                            )
+                        ),
+                        'from_us' => array(
+                            'method' => array(
+                                'Priority Mail Express International Flat Rate Envelope',
+                                'Priority Mail International Flat Rate Envelope',
+                                'First-Class Mail International Large Envelope',
+                                'Priority Mail International Small Flat Rate Envelope',
+                            )
+                        )
+                    )
+                ),
+                array(
+                    'containers' => array('RECTANGULAR'),
+                    'filters'    => array(
+                        'within_us' => array(
+                            'method' => array(
+                                'Priority Mail Express',
+                                'Priority Mail',
+                                'Standard Post',
+                                'Media Mail',
+                                'Library Mail',
+                                'First-Class Package Service'
+                            )
+                        ),
+                        'from_us' => array(
+                            'method' => array(
+                                'USPS GXG Envelopes',
+                                'Priority Mail Express International',
+                                'Priority Mail International',
+                                'First-Class Package International Service',
+                            )
+                        )
+                    )
+                ),
+                array(
+                    'containers' => array('NONRECTANGULAR'),
+                    'filters'    => array(
+                        'within_us' => array(
+                            'method' => array(
+                                'Priority Mail Express',
+                                'Priority Mail',
+                                'Standard Post',
+                                'Media Mail',
+                                'Library Mail',
+                                'First-Class Package Service'
+                            )
+                        ),
+                        'from_us' => array(
+                            'method' => array(
+                                'Global Express Guaranteed (GXG)',
+                                'Priority Mail Express International',
+                                'Priority Mail International',
+                                'First-Class Package International Service',
+                            )
+                        )
+                    )
+                ),
+            ),
+
             'size'=>array(
                 'REGULAR'     => Mage::helper('usa')->__('Regular'),
                 'LARGE'       => Mage::helper('usa')->__('Large'),
-                'OVERSIZE'    => Mage::helper('usa')->__('Oversize'),
             ),
 
             'machinable'=>array(
@@ -438,24 +619,19 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                 'false'       => Mage::helper('usa')->__('No'),
             ),
 
+            'delivery_confirmation_types' => array(
+                'True' => Mage::helper('usa')->__('Not Required'),
+                'False'  => Mage::helper('usa')->__('Required'),
+            ),
         );
 
-        $methods = $this->getConfigData('methods');
-        if (!empty($methods)) {
-            $codes['method'] = explode(",", $methods);
-        } else {
-            $codes['method'] = array();
-        }
-
         if (!isset($codes[$type])) {
-//            throw Mage::exception('Mage_Shipping', Mage::helper('usa')->__('Invalid USPS XML code type: %s', $type));
             return false;
         } elseif (''===$code) {
             return $codes[$type];
         }
 
         if (!isset($codes[$type][$code])) {
-//            throw Mage::exception('Mage_Shipping', Mage::helper('usa')->__('Invalid USPS XML code for type %s: %s', $type, $code));
             return false;
         } else {
             return $codes[$type][$code];
@@ -490,7 +666,7 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
     {
          $r = $this->_rawTrackRequest;
 
-         foreach ($trackings as $tracking){
+         foreach ($trackings as $tracking) {
              $xml = new SimpleXMLElement('<?xml version = "1.0" encoding = "UTF-8"?><TrackRequest/>');
              $xml->addAttribute('USERID', $r->getUserId());
 
@@ -523,9 +699,9 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
 
     protected function _parseXmlTrackingResponse($trackingvalue, $response)
     {
-        $errorTitle = 'Unable to retrieve tracking';
+        $errorTitle = Mage::helper('usa')->__('Unable to retrieve tracking');
         $resultArr=array();
-        if (strlen(trim($response))>0) {
+        if (strlen(trim($response)) > 0) {
             if (strpos(trim($response), '<?xml')===0) {
                 $xml = simplexml_load_string($response);
                 if (is_object($xml)) {
@@ -534,7 +710,7 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
                     } elseif (isset($xml->TrackInfo) && isset($xml->TrackInfo->Error) && isset($xml->TrackInfo->Error->Description) && (string)$xml->TrackInfo->Error->Description!='') {
                         $errorTitle = (string)$xml->TrackInfo->Error->Description;
                     } else {
-                        $errorTitle = 'Unknown error';
+                        $errorTitle = Mage::helper('usa')->__('Unknown error');
                     }
 
                     if(isset($xml->TrackInfo) && isset($xml->TrackInfo->TrackSummary)){
@@ -545,7 +721,7 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
             }
         }
 
-        if(!$this->_result){
+        if (!$this->_result) {
             $this->_result = Mage::getModel('shipping/tracking_result');
         }
         $defaults = $this->getDefaults();
@@ -570,10 +746,10 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
     public function getResponse()
     {
         $statuses = '';
-        if ($this->_result instanceof Mage_Shipping_Model_Tracking_Result){
+        if ($this->_result instanceof Mage_Shipping_Model_Tracking_Result) {
             if ($trackings = $this->_result->getAllTrackings()) {
-                foreach ($trackings as $tracking){
-                    if($data = $tracking->getAllData()){
+                foreach ($trackings as $tracking) {
+                    if($data = $tracking->getAllData()) {
                         if (!empty($data['track_summary'])) {
                             $statuses .= Mage::helper('usa')->__($data['track_summary']);
                         } else {
@@ -599,9 +775,284 @@ class Mage_Usa_Model_Shipping_Carrier_Usps
         $allowed = explode(',', $this->getConfigData('allowed_methods'));
         $arr = array();
         foreach ($allowed as $k) {
-            $arr[$k] = $k;
+            $arr[$k] = $this->getCode('method', $k);
         }
         return $arr;
     }
 
+    /**
+     * Check is �outry U.S. Possessions and Trust Territories
+     *
+     * @param string $countyId
+     * @return boolean
+     */
+    protected function _isUSCountry($countyId)
+    {
+        switch ($countyId) {
+            case 'AS': // Samoa American
+            case 'GU': // Guam
+            case 'MP': // Northern Mariana Islands
+            case 'PW': // Palau
+            case 'PR': // Puerto Rico
+            case 'VI': // Virgin Islands US
+            case 'US'; // United States
+                return true;
+        }
+
+        return false;
+    }
+
+    /**
+     * Return USPS county name by country ISO 3166-1-alpha-2 code
+     * Return false for unknown countries
+     *
+     * @param string $countryId
+     * @return string|false
+     */
+    protected function _getCountryName($countryId)
+    {
+        $countries = array (
+          'AD' => 'Andorra',
+          'AE' => 'United Arab Emirates',
+          'AF' => 'Afghanistan',
+          'AG' => 'Antigua and Barbuda',
+          'AI' => 'Anguilla',
+          'AL' => 'Albania',
+          'AM' => 'Armenia',
+          'AN' => 'Netherlands Antilles',
+          'AO' => 'Angola',
+          'AR' => 'Argentina',
+          'AT' => 'Austria',
+          'AU' => 'Australia',
+          'AW' => 'Aruba',
+          'AX' => 'Aland Island (Finland)',
+          'AZ' => 'Azerbaijan',
+          'BA' => 'Bosnia-Herzegovina',
+          'BB' => 'Barbados',
+          'BD' => 'Bangladesh',
+          'BE' => 'Belgium',
+          'BF' => 'Burkina Faso',
+          'BG' => 'Bulgaria',
+          'BH' => 'Bahrain',
+          'BI' => 'Burundi',
+          'BJ' => 'Benin',
+          'BM' => 'Bermuda',
+          'BN' => 'Brunei Darussalam',
+          'BO' => 'Bolivia',
+          'BR' => 'Brazil',
+          'BS' => 'Bahamas',
+          'BT' => 'Bhutan',
+          'BW' => 'Botswana',
+          'BY' => 'Belarus',
+          'BZ' => 'Belize',
+          'CA' => 'Canada',
+          'CC' => 'Cocos Island (Australia)',
+          'CD' => 'Congo, Democratic Republic of the',
+          'CF' => 'Central African Republic',
+          'CG' => 'Congo, Republic of the',
+          'CH' => 'Switzerland',
+          'CI' => 'Cote d Ivoire (Ivory Coast)',
+          'CK' => 'Cook Islands (New Zealand)',
+          'CL' => 'Chile',
+          'CM' => 'Cameroon',
+          'CN' => 'China',
+          'CO' => 'Colombia',
+          'CR' => 'Costa Rica',
+          'CU' => 'Cuba',
+          'CV' => 'Cape Verde',
+          'CX' => 'Christmas Island (Australia)',
+          'CY' => 'Cyprus',
+          'CZ' => 'Czech Republic',
+          'DE' => 'Germany',
+          'DJ' => 'Djibouti',
+          'DK' => 'Denmark',
+          'DM' => 'Dominica',
+          'DO' => 'Dominican Republic',
+          'DZ' => 'Algeria',
+          'EC' => 'Ecuador',
+          'EE' => 'Estonia',
+          'EG' => 'Egypt',
+          'ER' => 'Eritrea',
+          'ES' => 'Spain',
+          'ET' => 'Ethiopia',
+          'FI' => 'Finland',
+          'FJ' => 'Fiji',
+          'FK' => 'Falkland Islands',
+          'FM' => 'Micronesia, Federated States of',
+          'FO' => 'Faroe Islands',
+          'FR' => 'France',
+          'GA' => 'Gabon',
+          'GB' => 'Great Britain and Northern Ireland',
+          'GD' => 'Grenada',
+          'GE' => 'Georgia, Republic of',
+          'GF' => 'French Guiana',
+          'GH' => 'Ghana',
+          'GI' => 'Gibraltar',
+          'GL' => 'Greenland',
+          'GM' => 'Gambia',
+          'GN' => 'Guinea',
+          'GP' => 'Guadeloupe',
+          'GQ' => 'Equatorial Guinea',
+          'GR' => 'Greece',
+          'GS' => 'South Georgia (Falkland Islands)',
+          'GT' => 'Guatemala',
+          'GW' => 'Guinea-Bissau',
+          'GY' => 'Guyana',
+          'HK' => 'Hong Kong',
+          'HN' => 'Honduras',
+          'HR' => 'Croatia',
+          'HT' => 'Haiti',
+          'HU' => 'Hungary',
+          'ID' => 'Indonesia',
+          'IE' => 'Ireland',
+          'IL' => 'Israel',
+          'IN' => 'India',
+          'IQ' => 'Iraq',
+          'IR' => 'Iran',
+          'IS' => 'Iceland',
+          'IT' => 'Italy',
+          'JM' => 'Jamaica',
+          'JO' => 'Jordan',
+          'JP' => 'Japan',
+          'KE' => 'Kenya',
+          'KG' => 'Kyrgyzstan',
+          'KH' => 'Cambodia',
+          'KI' => 'Kiribati',
+          'KM' => 'Comoros',
+          'KN' => 'Saint Kitts (St. Christopher and Nevis)',
+          'KP' => 'North Korea (Korea, Democratic People\'s Republic of)',
+          'KR' => 'South Korea (Korea, Republic of)',
+          'KW' => 'Kuwait',
+          'KY' => 'Cayman Islands',
+          'KZ' => 'Kazakhstan',
+          'LA' => 'Laos',
+          'LB' => 'Lebanon',
+          'LC' => 'Saint Lucia',
+          'LI' => 'Liechtenstein',
+          'LK' => 'Sri Lanka',
+          'LR' => 'Liberia',
+          'LS' => 'Lesotho',
+          'LT' => 'Lithuania',
+          'LU' => 'Luxembourg',
+          'LV' => 'Latvia',
+          'LY' => 'Libya',
+          'MA' => 'Morocco',
+          'MC' => 'Monaco (France)',
+          'MD' => 'Moldova',
+          'MG' => 'Madagascar',
+          'MK' => 'Macedonia, Republic of',
+          'ML' => 'Mali',
+          'MM' => 'Burma',
+          'MN' => 'Mongolia',
+          'MO' => 'Macao',
+          'MQ' => 'Martinique',
+          'MR' => 'Mauritania',
+          'MS' => 'Montserrat',
+          'MT' => 'Malta',
+          'MU' => 'Mauritius',
+          'MV' => 'Maldives',
+          'MW' => 'Malawi',
+          'MX' => 'Mexico',
+          'MY' => 'Malaysia',
+          'MZ' => 'Mozambique',
+          'NA' => 'Namibia',
+          'NC' => 'New Caledonia',
+          'NE' => 'Niger',
+          'NG' => 'Nigeria',
+          'NI' => 'Nicaragua',
+          'NL' => 'Netherlands',
+          'NO' => 'Norway',
+          'NP' => 'Nepal',
+          'NR' => 'Nauru',
+          'NZ' => 'New Zealand',
+          'OM' => 'Oman',
+          'PA' => 'Panama',
+          'PE' => 'Peru',
+          'PF' => 'French Polynesia',
+          'PG' => 'Papua New Guinea',
+          'PH' => 'Philippines',
+          'PK' => 'Pakistan',
+          'PL' => 'Poland',
+          'PM' => 'Saint Pierre and Miquelon',
+          'PN' => 'Pitcairn Island',
+          'PT' => 'Portugal',
+          'PY' => 'Paraguay',
+          'QA' => 'Qatar',
+          'RE' => 'Reunion',
+          'RO' => 'Romania',
+          'RS' => 'Serbia',
+          'RU' => 'Russia',
+          'RW' => 'Rwanda',
+          'SA' => 'Saudi Arabia',
+          'SB' => 'Solomon Islands',
+          'SC' => 'Seychelles',
+          'SD' => 'Sudan',
+          'SE' => 'Sweden',
+          'SG' => 'Singapore',
+          'SH' => 'Saint Helena',
+          'SI' => 'Slovenia',
+          'SK' => 'Slovak Republic',
+          'SL' => 'Sierra Leone',
+          'SM' => 'San Marino',
+          'SN' => 'Senegal',
+          'SO' => 'Somalia',
+          'SR' => 'Suriname',
+          'ST' => 'Sao Tome and Principe',
+          'SV' => 'El Salvador',
+          'SY' => 'Syrian Arab Republic',
+          'SZ' => 'Swaziland',
+          'TC' => 'Turks and Caicos Islands',
+          'TD' => 'Chad',
+          'TG' => 'Togo',
+          'TH' => 'Thailand',
+          'TJ' => 'Tajikistan',
+          'TK' => 'Tokelau (Union) Group (Western Samoa)',
+          'TL' => 'East Timor (Indonesia)',
+          'TM' => 'Turkmenistan',
+          'TN' => 'Tunisia',
+          'TO' => 'Tonga',
+          'TR' => 'Turkey',
+          'TT' => 'Trinidad and Tobago',
+          'TV' => 'Tuvalu',
+          'TW' => 'Taiwan',
+          'TZ' => 'Tanzania',
+          'UA' => 'Ukraine',
+          'UG' => 'Uganda',
+          'UY' => 'Uruguay',
+          'UZ' => 'Uzbekistan',
+          'VA' => 'Vatican City',
+          'VC' => 'Saint Vincent and the Grenadines',
+          'VE' => 'Venezuela',
+          'VG' => 'British Virgin Islands',
+          'VN' => 'Vietnam',
+          'VU' => 'Vanuatu',
+          'WF' => 'Wallis and Futuna Islands',
+          'WS' => 'Western Samoa',
+          'YE' => 'Yemen',
+          'YT' => 'Mayotte (France)',
+          'ZA' => 'South Africa',
+          'ZM' => 'Zambia',
+          'ZW' => 'Zimbabwe',
+        );
+
+        if (isset($countries[$countryId])) {
+            return $countries[$countryId];
+        }
+
+        return false;
+    }
+
+    /**
+     * Clean service name from unsupported strings and characters
+     *
+     * @param  string $name
+     * @return string
+     */
+    protected function _filterServiceName($name)
+    {
+        $name = (string)preg_replace(array('~<[^/!][^>]+>.*</[^>]+>~sU', '~\<!--.*--\>~isU', '~<[^>]+>~is'), '', html_entity_decode($name));
+        $name = str_replace('*', '', $name);
+
+        return $name;
+    }
 }
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps/Source/Method.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps/Source/Method.php
index 9ceb7ee..d6e7795 100644
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
index 7c337de..c69b16d 100644
--- app/code/core/Mage/Usa/etc/config.xml
+++ app/code/core/Mage/Usa/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Mage_Usa>
-            <version>0.7.1</version>
+            <version>0.7.1.1.2</version>
         </Mage_Usa>
     </modules>
     <global>
@@ -170,14 +170,13 @@
             <usps>
                 <active>0</active>
                 <sallowspecific>0</sallowspecific>
-                <allowed_methods>Bound Printed Matter,Express Mail,Express Mail Flat Rate Envelope,Express Mail Flat Rate Envelope Hold For Pickup,Express Mail Flat-Rate Envelope Sunday/Holiday Guarantee,Express Mail Hold For Pickup,Express Mail International,Express Mail International Flat Rate Envelope,Express Mail PO to PO,Express Mail Sunday/Holiday Guarantee,First-Class Mail International Large Envelope,First-Class Mail International Letters,First-Class Mail International Package,First-Class,First-Class Mail,First-Class Mail Flat,First-Class Mail International,First-Class Mail Letter,First-Class Mail Parcel,Global Express Guaranteed (GXG),Global Express Guaranteed Non-Document Non-Rectangular,Global Express Guaranteed Non-Document Rectangular,Library Mail,Media Mail,Parcel Post,Priority Mail,Priority Mail Small Flat Rate Box,Priority Mail Medium Flat Rate Box,Priority Mail Large Flat Rate Box,Priority Mail Flat Rate Box,Priority Mail Flat Rate Envelope,Priority Mail International,Priority Mail International Flat Rate Box,Priority Mail International Flat Rate Envelope,Priority Mail International Small Flat Rate Box,Priority Mail International Medium Flat Rate Box,Priority Mail International Large Flat Rate Box,USPS GXG Envelopes</allowed_methods>
+                <allowed_methods>0_FCLE,0_FCL,0_FCP,1,2,3,4,6,7,13,16,17,22,23,25,27,28,33,34,35,36,37,42,43,53,55,56,57,61,INT_1,INT_2,INT_4,INT_6,INT_7,INT_8,INT_9,INT_10,INT_11,INT_12,INT_13,INT_14,INT_15,INT_16,INT_20,INT_26</allowed_methods>
                 <container>VARIABLE</container>
                 <cutoff_cost></cutoff_cost>
                 <free_method></free_method>
                 <gateway_url>http://production.shippingapis.com/ShippingAPI.dll</gateway_url>
                 <handling></handling>
                 <machinable>true</machinable>
-                <methods>Bound Printed Matter,Express Mail,Express Mail Flat Rate Envelope,Express Mail Flat Rate Envelope Hold For Pickup,Express Mail Flat-Rate Envelope Sunday/Holiday Guarantee,Express Mail Hold For Pickup,Express Mail International,Express Mail International Flat Rate Envelope,Express Mail PO to PO,Express Mail Sunday/Holiday Guarantee,First-Class Mail International Large Envelope,First-Class Mail International Letters,First-Class Mail International Package,First-Class,First-Class Mail,First-Class Mail Flat,First-Class Mail International,First-Class Mail Letter,First-Class Mail Parcel,Global Express Guaranteed (GXG),Global Express Guaranteed Non-Document Non-Rectangular,Global Express Guaranteed Non-Document Rectangular,Library Mail,Media Mail,Parcel Post,Priority Mail,Priority Mail Small Flat Rate Box,Priority Mail Medium Flat Rate Box,Priority Mail Large Flat Rate Box,Priority Mail Flat Rate Box,Priority Mail Flat Rate Envelope,Priority Mail International,Priority Mail International Flat Rate Box,Priority Mail International Flat Rate Envelope,Priority Mail International Small Flat Rate Box,Priority Mail International Medium Flat Rate Box,Priority Mail International Large Flat Rate Box,USPS GXG Envelopes</methods>
                 <model>usa/shipping_carrier_usps</model>
                 <size>REGULAR</size>
                 <title>United States Postal Service</title>
diff --git app/code/core/Mage/Usa/sql/usa_setup/mysql4-upgrade-0.7.1.1.1-0.7.1.1.2.php app/code/core/Mage/Usa/sql/usa_setup/mysql4-upgrade-0.7.1.1.1-0.7.1.1.2.php
new file mode 100644
index 0000000..6d26e97
--- /dev/null
+++ app/code/core/Mage/Usa/sql/usa_setup/mysql4-upgrade-0.7.1.1.1-0.7.1.1.2.php
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
+    ->from($configDataTable)
+    ->where('path IN (?)',
+        array(
+            'carriers/usps/free_method',
+            'carriers/usps/allowed_methods'
+        )
+    );
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
+            array('value' => $newValue),
+            $whereConfigId
+        );
+    }
+}
