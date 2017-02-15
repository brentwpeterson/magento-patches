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


 | _ |  |  | n/a | SUPEE-3941_EE_1.11.1.0_v1.patch

__PATCHFILE_FOLLOWS__
commit 3acca608e5ac5638f9adaa6e4a961ead62120274
Author: Yaroslav Voronoy <yvoronoy@magento.com>
Date:   Fri Oct 14 22:59:22 2016 +0300

    TMP

diff --git downloader/Maged/Model/Connect.php downloader/Maged/Model/Connect.php
index ec3dcc3..fe2228b 100644
--- downloader/Maged/Model/Connect.php
+++ downloader/Maged/Model/Connect.php
@@ -489,6 +489,9 @@ class Maged_Model_Connect extends Maged_Model
      */
     public function checkExtensionKey($id, &$match)
     {
-        return preg_match('#^([^ ]+)\/([^-]+)(-.+)?$#', $id, $match);
+        if (preg_match('#^(.+)\/(.+)-([\.\d]+)$#', $id, $match)) {
+            return $match;
+        }
+        return preg_match('#^(.+)\/(.+)$#', $id, $match);
     }
 }
diff --git downloader/lib/Mage/Connect/Packager.php downloader/lib/Mage/Connect/Packager.php
index eb7efda..a9db0ec 100644
--- downloader/lib/Mage/Connect/Packager.php
+++ downloader/lib/Mage/Connect/Packager.php
@@ -31,38 +31,52 @@
  * @package     Mage_Connect
  * @author      Magento Core Team <core@magentocommerce.com>
  */
-
 class Mage_Connect_Packager
 {
-    const CONFIG_FILE_NAME='downloader/connect.cfg';
-    const CACHE_FILE_NAME='downloader/cache.cfg';
-
-    protected  $install_states = array(
-                    'install' => 'Ready to install',
-                    'upgrade' => 'Ready to upgrade',
-                    'already_installed' => 'Already installed',
-                    'wrong_version' => 'Wrong version',
-                );
-
     /**
-     * Constructor
-     * @param Mage_connect_Config $config
+     * Default Config File name
      */
-    public function __construct()
-    {
+    const CONFIG_FILE_NAME = 'downloader/connect.cfg';
+    /**
+     * Default Cache Config File name
+     */
+    const CACHE_FILE_NAME = 'downloader/cache.cfg';
 
-    }
+    /**
+     * Install states of package
+     */
+    const INSTALL_STATE_INSTALL = 'install';
+    const INSTALL_STATE_UPGRADE = 'upgrade';
+    const INSTALL_STATE_WRONG_VERSION = 'wrong_version';
+    const INSTALL_STATE_ALREADY_INSTALLED = 'already_installed';
+    const INSTALL_STATE_INCOMPATIBLE = 'incompatible';
 
     /**
+     * Install states messages
      *
+     * @var array
+     */
+    protected  $installStates = array(
+                    self::INSTALL_STATE_INSTALL => 'Ready to install',
+                    self::INSTALL_STATE_UPGRADE => 'Ready to upgrade',
+                    self::INSTALL_STATE_ALREADY_INSTALLED => 'Already installed',
+                    self::INSTALL_STATE_WRONG_VERSION => 'Wrong version',
+                );
+
+    /**
+     * Archiver object
      * @var Mage_Archive
      */
     protected $_archiver = null;
-    protected $_http = null;
-
 
+    /**
+     * HTTP Client (Curl/Socket etc)
+     * @var Mage_HTTP_IClient
+     */
+    protected $_http = null;
 
     /**
+     * Get Archiver object
      *
      * @return Mage_Archive
      */
@@ -74,6 +88,10 @@ class Mage_Connect_Packager
         return $this->_archiver;
     }
 
+    /**
+     * Returns HTTP Client
+     * @return Mage_HTTP_IClient|null
+     */
     public function getDownloader()
     {
         if(is_null($this->_http)) {
@@ -82,7 +100,12 @@ class Mage_Connect_Packager
         return $this->_http;
     }
 
-
+    /**
+     * Get config data and cache config data remotely
+     *
+     * @param string $ftpString
+     * @return array
+     */
     public function getRemoteConf($ftpString)
     {
         $ftpObj = new Mage_Connect_Ftp();
@@ -90,7 +113,6 @@ class Mage_Connect_Packager
         $cfgFile = self::CONFIG_FILE_NAME;
         $cacheFile = self::CACHE_FILE_NAME;
 
-
         $wd = $ftpObj->getcwd();
 
         $remoteConfigExists = $ftpObj->fileExists($cfgFile);
@@ -121,7 +143,12 @@ class Mage_Connect_Packager
         return array($remoteCache, $remoteCfg, $ftpObj);
     }
 
-
+    /**
+     * Get Cache config data remotely
+     *
+     * @param string $ftpString
+     * @return array
+     */
     public function getRemoteCache($ftpString)
     {
 
@@ -141,7 +168,12 @@ class Mage_Connect_Packager
         return array($remoteCfg, $ftpObj);
     }
 
-
+    /**
+     * Get config data remotely
+     *
+     * @param string $ftpString
+     * @return array
+     */
     public function getRemoteConfig($ftpString)
     {
         $ftpObj = new Mage_Connect_Ftp();
@@ -163,6 +195,13 @@ class Mage_Connect_Packager
         return array($remoteCfg, $ftpObj);
     }
 
+    /**
+     * Write Cache config remotely
+     *
+     * @param Mage_Connect_Singleconfig $cache
+     * @param Mage_Connect_Ftp $ftpObj
+     * @return void
+     */
     public function writeToRemoteCache($cache, $ftpObj)
     {
         $wd = $ftpObj->getcwd();
@@ -171,6 +210,13 @@ class Mage_Connect_Packager
         $ftpObj->chdir($wd);
     }
 
+    /**
+     * Write config remotely
+     *
+     * @param Mage_Connect_Config $cache
+     * @param Mage_Connect_Ftp $ftpObj
+     * @throws RuntimeException
+     */
     public function writeToRemoteConfig($cache, $ftpObj)
     {
         $wd = $ftpObj->getcwd();
@@ -181,6 +227,7 @@ class Mage_Connect_Packager
 
     /**
      * Remove empty directories recursively up
+     *
      * @param string $dir
      * @param Mage_Connect_Ftp $ftp
      */
@@ -193,19 +240,27 @@ class Mage_Connect_Packager
                 }
             }
         } else {
-            if (@rmdir($dir)) {
-                $this->removeEmptyDirectory(dirname($dir), $ftp);
+            $content = scandir($dir);
+            if ($content === false) return;
+
+            if (count(array_diff($content, array('.', '..'))) == 0) {
+                if (@rmdir($dir)) {
+                    $this->removeEmptyDirectory(dirname($dir), $ftp);
+                } else {
+                    throw new RuntimeException('Failed to delete dir ' . $dir . "\r\n Check permissions");
+                }
             }
         }
     }
 
     /**
+     * Uninstall Package
      *
-     * @param $chanName
-     * @param $package
+     * @param string $chanName
+     * @param string $package
      * @param Mage_Connect_Singleconfig $cacheObj
      * @param Mage_Connect_Config $configObj
-     * @return unknown_type
+     * @throws RuntimeException
      */
     public function processUninstallPackage($chanName, $package, $cacheObj, $configObj)
     {
@@ -213,14 +268,21 @@ class Mage_Connect_Packager
         $contents = $package->getContents();
 
         $targetPath = rtrim($configObj->magento_root, "\\/");
+        $failedFiles = array();
         foreach($contents as $file) {
             $fileName = basename($file);
             $filePath = dirname($file);
             $dest = $targetPath . DIRECTORY_SEPARATOR . $filePath . DIRECTORY_SEPARATOR . $fileName;
             if(@file_exists($dest)) {
-                @unlink($dest);
-                $this->removeEmptyDirectory(dirname($dest));
+                if (!@unlink($dest)) {
+                    $failedFiles[] = $dest;
+                }
             }
+            $this->removeEmptyDirectory(dirname($dest));
+        }
+        if (!empty($failedFiles)) {
+            $msg = sprintf("Failed to delete files: %s \r\n Check permissions", implode("\r\n", $failedFiles));
+            throw new RuntimeException($msg);
         }
 
         $destDir = $targetPath . DS . Mage_Connect_Package::PACKAGE_XML_DIR;
@@ -229,22 +291,32 @@ class Mage_Connect_Packager
     }
 
     /**
+     * Uninstall Package over FTP
      *
      * @param $chanName
      * @param $package
      * @param Mage_Connect_Singleconfig $cacheObj
      * @param Mage_Connect_Ftp $ftp
-     * @return unknown_type
+     * @throws RuntimeException
      */
     public function processUninstallPackageFtp($chanName, $package, $cacheObj, $ftp)
     {
         $ftpDir = $ftp->getcwd();
         $package = $cacheObj->getPackageObject($chanName, $package);
         $contents = $package->getContents();
+        $failedFiles = array();
         foreach($contents as $file) {
-            $res = $ftp->delete($file);
+            $ftp->delete($file);
+            if ($ftp->fileExists($file)) {
+                $failedFiles[] = $file;
+                continue;
+            }
             $this->removeEmptyDirectory(dirname($file), $ftp);
         }
+        if (!empty($failedFiles)) {
+            $msg = sprintf("Failed to delete files: %s \r\n Check permissions", implode("\r\n", $failedFiles));
+            throw new RuntimeException($msg);
+        }
         $remoteXml = Mage_Connect_Package::PACKAGE_XML_DIR . DS . $package->getReleaseFilename() . '.xml';
         $ftp->delete($remoteXml);
         $ftp->chdir($ftpDir);
@@ -264,8 +336,8 @@ class Mage_Connect_Packager
         }
         return true;
     }
+
     /**
-     *
      * Return correct global dir mode in octal representation
      *
      * @param Maged_Model_Config $config
@@ -306,19 +378,29 @@ class Mage_Connect_Packager
         return str_replace("\\", "/", $str);
     }
 
+    /**
+     * Install package over FTP
+     *
+     * @param Mage_Connect_Package $package
+     * @param string $file
+     * @param Maged_Model_Config $configObj
+     * @param Mage_Connect_Ftp $ftp
+     * @throws RuntimeException
+     */
     public function processInstallPackageFtp($package, $file, $configObj, $ftp)
     {
         $ftpDir = $ftp->getcwd();
         $contents = $package->getContents();
         $arc = $this->getArchiver();
         $target = dirname($file).DS.$package->getReleaseFilename();
-        @mkdir($target, 0777, true);
+        if (!@mkdir($target, 0777, true)) {
+            throw new RuntimeException("Can't create directory ". $target);
+        }
         $tar = $arc->unpack($file, $target);
         $modeFile = $this->_getFileMode($configObj);
         $modeDir = $this->_getDirMode($configObj);
+        $failedFiles = array();
         foreach($contents as $file) {
-            $fileName = basename($file);
-            $filePath = $this->convertFtpPath(dirname($file));
             $source = $tar.DS.$file;
             if (file_exists($source) && is_file($source)) {
                 $args = array(ltrim($file,"/"), $source);
@@ -326,10 +408,17 @@ class Mage_Connect_Packager
                     $args[] = $modeDir;
                     $args[] = $modeFile;
                 }
-                call_user_func_array(array($ftp,'upload'), $args);
+                if (call_user_func_array(array($ftp,'upload'), $args) === false) {
+                    $failedFiles[] = $source;
+                }
             }
         }
 
+        if (!empty($failedFiles)) {
+            $msg = sprintf("Failed to upload files: %s \r\n Check permissions", implode("\r\n", $failedFiles));
+            throw new RuntimeException($msg);
+        }
+
         $localXml = $tar . Mage_Connect_Package_Reader::DEFAULT_NAME_PACKAGE;
         if (is_file($localXml)) {
             $remoteXml = Mage_Connect_Package::PACKAGE_XML_DIR . DS . $package->getReleaseFilename() . '.xml';
@@ -342,6 +431,7 @@ class Mage_Connect_Packager
 
     /**
      * Package installation to FS
+     *
      * @param Mage_Connect_Package $package
      * @param string $file
      * @return void
@@ -356,12 +446,17 @@ class Mage_Connect_Packager
         $tar = $arc->unpack($file, $target);
         $modeFile = $this->_getFileMode($configObj);
         $modeDir = $this->_getDirMode($configObj);
+        $targetPath = rtrim($configObj->magento_root, "\\/");
+        $packageXmlDir = $targetPath . DS . Mage_Connect_Package::PACKAGE_XML_DIR;
+        if (!is_dir_writeable($packageXmlDir)) {
+            throw new RuntimeException('Directory ' . $packageXmlDir . ' is not writable. Check permission');
+        }
+        $this->_makeDirectories($contents, $targetPath, $modeDir);
         foreach($contents as $file) {
             $fileName = basename($file);
             $filePath = dirname($file);
             $source = $tar.DS.$file;
-            $targetPath = rtrim($configObj->magento_root, "\\/");
-            @mkdir($targetPath. DS . $filePath, $modeDir, true);
+            $source = $tar . DS . $file;
             $dest = $targetPath . DS . $filePath . DS . $fileName;
             if (is_file($source)) {
                 @copy($source, $dest);
@@ -386,13 +481,43 @@ class Mage_Connect_Packager
         Mage_System_Dirs::rm(array("-r",$target));
     }
 
+    /**
+     * @param array $content
+     * @param string $targetPath
+     * @param int $modeDir
+     * @throws RuntimeException
+     */
+    protected function _makeDirectories($content, $targetPath, $modeDir)
+    {
+        $failedDirs = array();
+        $createdDirs = array();
+        foreach ($content as $file) {
+            $dirPath = dirname($file);
+            if (is_dir($dirPath) && is_dir_writeable($dirPath)) {
+                continue;
+            }
+            if (!mkdir($targetPath . DS . $dirPath, $modeDir, true)) {
+                $failedDirs[] = $targetPath . DS .  $dirPath;
+            } else {
+                $createdDirs[] = $targetPath . DS . $dirPath;
+            }
+        }
+        if (!empty($failedDirs)) {
+            foreach ($createdDirs as $createdDir) {
+                $this->removeEmptyDirectory($createdDir);
+            }
+            $msg = sprintf("Failed to create directory:\r\n%s\r\n Check permissions", implode("\r\n", $failedDirs));
+            throw new RuntimeException($msg);
+        }
+    }
 
     /**
      * Get local modified files
-     * @param $chanName
-     * @param $package
-     * @param $cacheObj
-     * @param $configObj
+     *
+     * @param string $chanName
+     * @param string $package
+     * @param Mage_Connect_Singleconfig $cacheObj
+     * @param Mage_Connect_Config $configObj
      * @return array
      */
     public function getLocalModifiedFiles($chanName, $package, $cacheObj, $configObj)
@@ -411,9 +536,9 @@ class Mage_Connect_Packager
     /**
      * Get remote modified files
      *
-     * @param $chanName
-     * @param $package
-     * @param $cacheObj
+     * @param string $chanName
+     * @param string $package
+     * @param Mage_Connect_Singleconfig $cacheObj
      * @param Mage_Connect_Ftp $ftp
      * @return array
      */
@@ -436,9 +561,7 @@ class Mage_Connect_Packager
         return $listModified;
     }
 
-
     /**
-     *
      * Get upgrades list
      *
      * @param string/array $channels
@@ -490,7 +613,7 @@ class Mage_Connect_Packager
                 $remoteVersion = $localVersion = trim($localData[Mage_Connect_Singleconfig::K_VER]);
                 foreach($package as $version => $s) {
 
-                    if( $cacheObject->compareStabilities($s, $state) < 0 ) {
+                    if($cacheObject->compareStabilities($s, $state) < 0) {
                         continue;
                     }
 
@@ -520,6 +643,7 @@ class Mage_Connect_Packager
 
     /**
      * Get uninstall list
+     *
      * @param string $chanName
      * @param string $package
      * @param Mage_Connect_Singleconfig $cache
@@ -533,7 +657,6 @@ class Mage_Connect_Packager
         static $hash = array();
 
         $chanName = $cache->chanName($chanName);
-        $keyOuter = $chanName . "/" . $package;
         $level++;
 
         try {
@@ -549,10 +672,8 @@ class Mage_Connect_Packager
             $dependencies = $cache->getPackageDependencies($chanName, $package);
             $data = $cache->getPackage($chanName, $package);
             $version = $data['version'];
-            $keyOuter = $chanName . "/" . $package;
 
-            //print "Processing outer: {$keyOuter} \n";
-            $hash[$keyOuter] = array (
+            $hash[$chanName . "/" . $package] = array (
                         'name' => $package,
                         'channel' => $chanName,
                         'version' => $version,
@@ -560,10 +681,14 @@ class Mage_Connect_Packager
             );
 
             if($withDepsRecursive) {
-                $flds = array('name','channel','min','max');
-                $fldsCount = count($flds);
+                $fields = array('name','channel','min','max');
                 foreach($dependencies as $row) {
-                    foreach($flds as $key) {
+                    /**
+                     * Converts an array to variables
+                     * @var $pChannel string Channel Name
+                     * @var $pName string Package Name
+                     */
+                    foreach($fields as $key) {
                         $varName = "p".ucfirst($key);
                         $$varName = $row[$key];
                     }
@@ -577,13 +702,6 @@ class Mage_Connect_Packager
             }
 
         } catch (Exception $e) {
-//            $this->_failed[] = array(
-//                'name'=>$package,
-//                'channel'=>$chanName,
-//                'max'=>$versionMax,
-//                'min'=>$versionMin,
-//                'reason'=>$e->getMessage()
-//            );
         }
 
         $level--;
@@ -596,6 +714,7 @@ class Mage_Connect_Packager
 
     /**
      * Add data to package dependencies hash array
+     *
      * @param array $hash Package dependencies hash array
      * @param string $name Package name
      * @param string $channel Package chaannel
@@ -603,19 +722,19 @@ class Mage_Connect_Packager
      * @param string $stability Package stability
      * @param string $versionMin Required package minimum version
      * @param string $versionMax Required package maximum version
-     * @param string $install_state Package install state
+     * @param string $installState Package install state
      * @param string $message Package install message
      * @param array $dependencies Package dependencies
+     * @return bool
      */
     private function addHashData(&$hash, $name, $channel, $downloaded_version = '', $stability = '', $versionMin = '',
-            $versionMax = '', $install_state = '', $message = '', $dependencies = '')
+            $versionMax = '', $installState = '', $message = '', $dependencies = '')
     {
             /**
-             * @todo When we are building dependencies tree we should base this calculations not on full key as on a
+             * When we are building dependencies tree we should base this calculations not on full key as on a
              * unique value but check it by parts. First part which should be checked is EXTENSION_NAME also this
              * part should be unique globally not per channel.
              */
-            //$key = $chanName . "/" . $package;
             $key = $name;
             $hash[$key] = array (
                 'name' => $name,
@@ -624,19 +743,17 @@ class Mage_Connect_Packager
                 'stability' => $stability,
                 'min' => $versionMin,
                 'max' => $versionMax,
-                'install_state' => $install_state,
-                'message' => (isset($this->install_states[$install_state]) ?
-                        $this->install_states[$install_state] : '').$message,
+                'install_state' => $installState,
+                'message' => (isset($this->installStates[$installState]) ?
+                        $this->installStates[$installState] : '').$message,
                 'packages' => $dependencies,
             );
-
             return true;
     }
 
     /**
      * Get dependencies list/install order info
      *
-     *
      * @param string $chanName
      * @param string $package
      * @param Mage_Connect_Singleconfig $cache
@@ -651,16 +768,13 @@ class Mage_Connect_Packager
     public function getDependenciesList( $chanName, $package, $cache, $config, $versionMax = false, $versionMin = false,
             $withDepsRecursive = true, $forceRemote = false, $rest = null)
     {
-
         static $level = 0;
         static $_depsHash = array();
         static $_deps = array();
         static $_failed = array();
-        $install_state = 'install';
+        $install_state = self::INSTALL_STATE_INSTALL;
         $version = '';
-        $stability = '';
         $message = '';
-        $dependencies = array();
 
         $level++;
 
@@ -709,31 +823,31 @@ class Mage_Connect_Packager
             $stability = $packageInfo->getStability();
 
             /**
-             * @todo check is package already installed
+             * check is package already installed
              */
             if ($installedPackage = $cache->isPackageInstalled($package)) {
                 if ($chanName == $installedPackage['channel']){
                     /**
-                     * @todo check versions!!!
+                     * check versions
                      */
                     if (version_compare($version, $installedPackage['version'], '>')) {
-                        $install_state = 'upgrade';
+                        $install_state = self::INSTALL_STATE_UPGRADE;
                     } elseif (version_compare($version, $installedPackage['version'], '<')) {
                         $version = $installedPackage['version'];
                         $stability = $installedPackage['stability'];
-                        $install_state = 'wrong_version';
+                        $install_state = self::INSTALL_STATE_WRONG_VERSION;
                     } else {
-                        $install_state = 'already_installed';
+                        $install_state = self::INSTALL_STATE_ALREADY_INSTALLED;
                     }
                 } else {
-                    $install_state = 'incompatible';
+                    $install_state = self::INSTALL_STATE_INCOMPATIBLE;
                 }
             }
 
             $deps_tmp = $packageInfo->getDependencyPackages();
 
             /**
-             * @todo Select distinct packages grouped by name
+             * Select distinct packages grouped by name
              */
             $dependencies = array();
             foreach ($deps_tmp as $row) {
@@ -751,20 +865,25 @@ class Mage_Connect_Packager
             }
 
             /**
-             * @todo When we are building dependencies tree we should base this calculations not on full key as on a
+             * When we are building dependencies tree we should base this calculations not on full key as on a
              * unique value but check it by parts. First part which should be checked is EXTENSION_NAME also this part
              * should be unique globally not per channel.
              */
-            // $keyOuter = $chanName . "/" . $package;
-            $keyOuter = $package;
-
-            $this->addHashData($_depsHash, $package, $chanName, $version, $stability, $versionMin,
-                    $versionMax, $install_state, $message, $dependencies);
+            if (self::INSTALL_STATE_INCOMPATIBLE != $install_state) {
+                $this->addHashData($_depsHash, $package, $chanName, $version, $stability, $versionMin,
+                        $versionMax, $install_state, $message, $dependencies);
+            }
 
-            if ($withDepsRecursive && 'incompatible' != $install_state) {
+            if ($withDepsRecursive && self::INSTALL_STATE_INCOMPATIBLE != $install_state) {
                 $flds = array('name','channel','min','max');
-                $fldsCount = count($flds);
                 foreach($dependencies as $row) {
+                    /**
+                     * Converts an array to variables
+                     * @var $pChannel string Channel Name
+                     * @var $pName string Package Name
+                     * @var $pMax string Maximum version number
+                     * @var $pMin string Minimum version number
+                     */
                     foreach($flds as $key) {
                         $varName = "p".ucfirst($key);
                         $$varName = $row[$key];
@@ -775,7 +894,6 @@ class Mage_Connect_Packager
                      * on a unique value but check it by parts. First part which should be checked is EXTENSION_NAME
                      * also this part should be unique globally not per channel.
                      */
-                    //$keyInner = $pChannel . "/" . $pName;
                     $keyInner = $pName;
                     if(!isset($_depsHash[$keyInner])) {
                         $_deps[] = $row;
@@ -786,12 +904,10 @@ class Mage_Connect_Packager
                         $hasMin = $_depsHash[$keyInner]['min'];
                         $hasMax = $_depsHash[$keyInner]['max'];
                         if($pMin === $hasMin && $pMax === $hasMax) {
-                            //var_dump("Equal requirements, skipping");
                             continue;
                         }
 
                         if($cache->versionInRange($downloaded, $pMin, $pMax)) {
-                            //var_dump("Downloaded package matches new range too");
                             continue;
                         }
 
@@ -822,7 +938,6 @@ class Mage_Connect_Packager
                         $newMinIsGreater = version_compare($pMin, $hasMin, ">");
                         $forceMax = $newMaxIsLess ? $pMax : $hasMax;
                         $forceMin = $newMinIsGreater ? $pMin : $hasMin;
-                        //var_dump("Trying to process {$pName} : max {$forceMax} - min {$forceMin}");
                         $this->$method($pChannel, $pName, $cache, $config,
                         $forceMax, $forceMin, $withDepsRecursive, $forceRemote, $rest);
                     }
@@ -839,7 +954,6 @@ class Mage_Connect_Packager
             );
         }
 
-
         $level--;
         if($level == 0) {
             $out = $this->processDepsHash($_depsHash, false);
@@ -850,13 +964,11 @@ class Mage_Connect_Packager
             $_failed = array();
             return array('deps' => $deps, 'result' => $out, 'failed'=> $failed);
         }
-
     }
 
 
     /**
-     * Process dependencies hash
-     * Makes topological sorting and gives operation order list
+     * Process dependencies hash. Makes topological sorting and gives operation order list
      *
      * @param array $depsHash
      * @param bool $sortReverse
@@ -896,8 +1008,7 @@ class Mage_Connect_Packager
         $result = $graph->topologicalSort();
         $sortReverse ? krsort($result) : ksort($result);
         $out = array();
-        $total = 0;
-        foreach($result as $order=>$nodes) {
+        foreach($result as $nodes) {
             foreach($nodes as $n) {
                 $out[] = $n->getData();
             }
@@ -905,5 +1016,4 @@ class Mage_Connect_Packager
         unset($graph, $nodes);
         return $out;
     }
-
 }
diff --git downloader/lib/Mage/Connect/Rest.php downloader/lib/Mage/Connect/Rest.php
index a702f03..87908a8 100644
--- downloader/lib/Mage/Connect/Rest.php
+++ downloader/lib/Mage/Connect/Rest.php
@@ -71,17 +71,14 @@ class Mage_Connect_Rest
     /**
      * Constructor
      */
-    public function __construct($protocol="http")
+    public function __construct($protocol="https")
     {
         switch ($protocol) {
-            case 'ftp':
-                $this->_protocol = 'ftp';
-                break;
             case 'http':
                 $this->_protocol = 'http';
                 break;
             default:
-                $this->_protocol = 'http';
+                $this->_protocol = 'https';
                 break;
         }
     }
diff --git downloader/lib/Mage/Connect/Singleconfig.php downloader/lib/Mage/Connect/Singleconfig.php
index 61f9677..3c1f215 100644
--- downloader/lib/Mage/Connect/Singleconfig.php
+++ downloader/lib/Mage/Connect/Singleconfig.php
@@ -100,7 +100,6 @@ class Mage_Connect_Singleconfig
         $uri = rtrim($uri, "/");
         $uri = str_replace("http://", '', $uri);
         $uri = str_replace("https://", '', $uri);
-        $uri = str_replace("ftp://", '', $uri);
         return $uri;
     }
 
diff --git downloader/lib/Mage/HTTP/Client/Curl.php downloader/lib/Mage/HTTP/Client/Curl.php
index 32ab99c..2236655 100644
--- downloader/lib/Mage/HTTP/Client/Curl.php
+++ downloader/lib/Mage/HTTP/Client/Curl.php
@@ -361,47 +361,20 @@ implements Mage_HTTP_IClient
 
     /**
      * Make request
+     *
      * @param string $method
      * @param string $uri
      * @param array $params
-     * @return null
+     * @param boolean $isAuthorizationRequired
      */
-    protected function makeRequest($method, $uri, $params = array())
+    protected function makeRequest($method, $uri, $params = array(), $isAuthorizationRequired = true)
     {
-        static $isAuthorizationRequired = 0;
+        $uriModified = $this->getSecureRequest($uri, $isAuthorizationRequired);
         $this->_ch = curl_init();
-
-        // make request via secured layer
-        if ($isAuthorizationRequired && strpos($uri, 'https://') !== 0) {
-            $uri = str_replace('http://', '', $uri);
-            $uri = 'https://' . $uri;
-        }
-
-        $this->curlOption(CURLOPT_URL, $uri);
-        $this->curlOption(CURLOPT_SSL_VERIFYPEER, FALSE);
+        $this->curlOption(CURLOPT_URL, $uriModified);
+        $this->curlOption(CURLOPT_SSL_VERIFYPEER, false);
         $this->curlOption(CURLOPT_SSL_VERIFYHOST, 2);
-
-        // force method to POST if secured
-        if ($isAuthorizationRequired) {
-            $method = 'POST';
-        }
-
-        if($method == 'POST') {
-            $this->curlOption(CURLOPT_POST, 1);
-            $postFields = is_array($params) ? $params : array();
-            if ($isAuthorizationRequired) {
-                $this->curlOption(CURLOPT_COOKIEJAR, self::COOKIE_FILE);
-                $this->curlOption(CURLOPT_COOKIEFILE, self::COOKIE_FILE);
-                $postFields = array_merge($postFields, $this->_auth);
-            }
-            if (!empty($postFields)) {
-                $this->curlOption(CURLOPT_POSTFIELDS, $postFields);
-            }
-        } elseif($method == "GET") {
-            $this->curlOption(CURLOPT_HTTPGET, 1);
-        } else {
-            $this->curlOption(CURLOPT_CUSTOMREQUEST, $method);
-        }
+        $this->getCurlMethodSettings($method, $params, $isAuthorizationRequired);
 
         if(count($this->_headers)) {
             $heads = array();
@@ -444,23 +417,26 @@ implements Mage_HTTP_IClient
             $this->doError(curl_error($this->_ch));
         }
         if(!$this->getStatus()) {
-            return $this->doError("Invalid response headers returned from server.");
+            $this->doError("Invalid response headers returned from server.");
+            return;
         }
+
         curl_close($this->_ch);
+
         if (403 == $this->getStatus()) {
-            if (!$isAuthorizationRequired) {
-                $isAuthorizationRequired++;
-                $this->makeRequest($method, $uri, $params);
-                $isAuthorizationRequired=0;
+            if ($isAuthorizationRequired) {
+                $this->makeRequest($method, $uri, $params, false);
             } else {
-                return $this->doError(sprintf('Access denied for %s@%s', $_SESSION['auth']['login'], $uri));
+                $this->doError(sprintf('Access denied for %s@%s', $_SESSION['auth']['login'], $uriModified));
+                return;
             }
+        } elseif (405 == $this->getStatus()) {
+            $this->doError("HTTP Error 405 Method not allowed");
+            return;
         }
     }
 
     /**
-     * Throw error excpetion
-     * @param $string
      * @throws Exception
      */
     public function isAuthorizationRequired()
@@ -553,4 +529,44 @@ implements Mage_HTTP_IClient
     {
         $this->_curlUserOptions[$name] = $value;
     }
+
+    /**
+     * @param $uri
+     * @param $isAuthorizationRequired
+     * @return string
+     */
+    protected function getSecureRequest($uri, $isAuthorizationRequired = true)
+    {
+        if ($isAuthorizationRequired && strpos($uri, 'https://') !== 0) {
+            $uri = str_replace('http://', '', $uri);
+            $uri = 'https://' . $uri;
+            return $uri;
+        }
+        return $uri;
+    }
+
+    /**
+     * @param $method
+     * @param $params
+     * @param $isAuthorizationRequired
+     */
+    protected function getCurlMethodSettings($method, $params, $isAuthorizationRequired)
+    {
+        if ($method == 'POST') {
+            $this->curlOption(CURLOPT_POST, 1);
+            $postFields = is_array($params) ? $params : array();
+            if ($isAuthorizationRequired) {
+                $this->curlOption(CURLOPT_COOKIEJAR, self::COOKIE_FILE);
+                $this->curlOption(CURLOPT_COOKIEFILE, self::COOKIE_FILE);
+                $postFields = array_merge($postFields, $this->_auth);
+            }
+            if (!empty($postFields)) {
+                $this->curlOption(CURLOPT_POSTFIELDS, $postFields);
+            }
+        } elseif ($method == "GET") {
+            $this->curlOption(CURLOPT_HTTPGET, 1);
+        } else {
+            $this->curlOption(CURLOPT_CUSTOMREQUEST, $method);
+        }
+    }
 }
diff --git downloader/template/settings.phtml downloader/template/settings.phtml
index 648d514..5b236c9 100755
--- downloader/template/settings.phtml
+++ downloader/template/settings.phtml
@@ -63,8 +63,8 @@ function changeDeploymentType (element)
                     <td class="label">Magento Connect Channel Protocol:</td>
                     <td class="value">
                         <select id="protocol" name="protocol">
+                            <option value="https" <?php if ($this->get('protocol')=='https'):?>selected="selected"<?php endif ?>>Https</option>
                             <option value="http" <?php if ($this->get('protocol')=='http'):?>selected="selected"<?php endif ?>>Http</option>
-                            <option value="ftp" <?php if ($this->get('protocol')=='ftp'):?>selected="selected"<?php endif ?>>Ftp</option>
                         </select>
                     </td>
                 </tr>
