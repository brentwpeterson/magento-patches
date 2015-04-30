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


SUPEE-3941 | EE_1.14.0.1 | v1 | d35110621d80be22922611e2b0a502da054a95f0 | Tue Jul 15 11:57:57 2014 +0300 | v1.14.0.1..HEAD

__PATCHFILE_FOLLOWS__
diff --git downloader/Maged/Model/Connect.php downloader/Maged/Model/Connect.php
index 77c971e..d62cabc 100644
--- downloader/Maged/Model/Connect.php
+++ downloader/Maged/Model/Connect.php
@@ -486,6 +486,9 @@ class Maged_Model_Connect extends Maged_Model
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
diff --git downloader/lib/Mage/Connect/Backup.php downloader/lib/Mage/Connect/Backup.php
new file mode 100644
index 0000000..8620225
--- /dev/null
+++ downloader/lib/Mage/Connect/Backup.php
@@ -0,0 +1,169 @@
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
+ * @package     Mage_Connect
+ * @copyright   Copyright (c) 2014 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Class to backup files before extension installation
+ *
+ * @category    Mage
+ * @package     Mage_Connect
+ * @author      Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Connect_Backup
+{
+    /**
+     * Prefix for backuped files
+     *
+     * @var string
+     */
+    protected $_prefix = '_backup_';
+
+    /**
+     * Array of available to overwrite type of files
+     *
+     * @var array
+     */
+    protected $_fileTypes = array();
+
+    /**
+     * List of files to backup files
+     *
+     * @var array
+     */
+    protected $_fileList = array();
+
+    /**
+     * Get available file types for backup
+     *
+     * @return array
+     */
+    public function getFileTypes()
+    {
+        return $this->_fileTypes;
+    }
+
+    /**
+     * Set available file types for backup
+     *
+     * @param array $types
+     */
+    public function setFileTypes(array $types)
+    {
+        foreach ($types as $type) {
+            $this->_fileTypes[] = $type;
+        }
+    }
+
+    /**
+     * Add file to files list for backup
+     *
+     * @param string $file
+     * @param string $rootPath
+     * @return void
+     */
+    public function addFile($file, $rootPath)
+    {
+        $dest = $rootPath . DS . $file;
+        $type = $this->getFileType($file);
+        if (file_exists($dest) && in_array($type, $this->getFileTypes())) {
+            $this->_fileList[] = $file;
+        }
+    }
+
+    /**
+     * Get count of files
+     *
+     * @return int
+     */
+    public function getFilesCount()
+    {
+        return count($this->_fileList);
+    }
+
+    /**
+     * Clear list of files
+     *
+     * @return void
+     */
+    public function unsetAllFiles()
+    {
+        $this->_fileList = array();
+    }
+
+    /**
+     * Get list of files
+     *
+     * @return array
+     */
+    public function getAllFiles()
+    {
+       return $this->_fileList;
+    }
+
+    /**
+     * Run backup process
+     *
+     * @param boolean $cleanUpQueue
+     * @return void
+     */
+    public function run($cleanUpQueue = false)
+    {
+        if ($this->getFilesCount() > 0) {
+            $fileList = $this->getAllFiles();
+            foreach($fileList as $file) {
+                $this->_backupFile($file);
+            }
+            if ($cleanUpQueue) {
+                $this->unsetAllFiles();
+            }
+        }
+    }
+
+    /**
+     * Get File type
+     *
+     * @param string $file
+     * @return string
+     */
+    public function getFileType($file)
+    {
+        return pathinfo($file, PATHINFO_EXTENSION);
+    }
+
+    /**
+     * Backup file
+     *
+     * @param string $file
+     * @return void
+     */
+    private function _backupFile($file)
+    {
+        $type = $this->getFileType($file);
+        if ($type && $type != '') {
+            $newName = $this->_prefix . time() . '.' . $type;
+            @rename($file, str_replace('.' . $type, $newName, $file));
+        }
+    }
+}
diff --git downloader/lib/Mage/Connect/Command.php downloader/lib/Mage/Connect/Command.php
index 6056028..fad7aa0 100644
--- downloader/lib/Mage/Connect/Command.php
+++ downloader/lib/Mage/Connect/Command.php
@@ -64,6 +64,13 @@ class Mage_Connect_Command
     protected static $_validator = null;
 
     /**
+     * Backup instance
+     *
+     * @var Mage_Connect_Backup
+     */
+    protected static $_backup = null;
+
+    /**
      * Rest instance
      *
      * @var Mage_Connect_Rest
@@ -249,6 +256,19 @@ class Mage_Connect_Command
     }
 
     /**
+     * Get backup object
+     *
+     * @return Mage_Connect_Backup
+     */
+    public function backup()
+    {
+        if(is_null(self::$_backup)) {
+            self::$_backup = new Mage_Connect_Backup();
+        }
+        return self::$_backup;
+    }
+
+    /**
      * Get rest object
      *
      * @return Mage_Connect_Rest
@@ -422,8 +442,8 @@ class Mage_Connect_Command
             return;
         }
         if(preg_match("@([a-zA-Z0-9_]+)/([a-zA-Z0-9_]+)@ims", $params[0], $subs)) {
-           $params[0] = $subs[2];
-           array_unshift($params, $subs[1]);
+            $params[0] = $subs[2];
+            array_unshift($params, $subs[1]);
         }
     }
 
diff --git downloader/lib/Mage/Connect/Command/Install.php downloader/lib/Mage/Connect/Command/Install.php
index 549e730..20aa691 100644
--- downloader/lib/Mage/Connect/Command/Install.php
+++ downloader/lib/Mage/Connect/Command/Install.php
@@ -90,15 +90,15 @@ final class Mage_Connect_Command_Install extends Mage_Connect_Command
                 @mkdir($config->magento_root . $dirTmp,0777,true);
                 @mkdir($config->magento_root . $dirMedia,0777,true);
                 $isWritable = is_writable($config->magento_root)
-                              && is_writable($config->magento_root . DIRECTORY_SEPARATOR . $config->downloader_path)
-                              && is_writable($config->magento_root . $dirCache)
-                              && is_writable($config->magento_root . $dirTmp)
-                              && is_writable($config->magento_root . $dirMedia);
+                    && is_writable($config->magento_root . DIRECTORY_SEPARATOR . $config->downloader_path)
+                    && is_writable($config->magento_root . $dirCache)
+                    && is_writable($config->magento_root . $dirTmp)
+                    && is_writable($config->magento_root . $dirMedia);
                 $err = "Please check for sufficient write file permissions.";
             }
             $isWritable = $isWritable && is_writable($config->magento_root . $dirMedia)
-                          && is_writable($config->magento_root . $dirCache)
-                          && is_writable($config->magento_root . $dirTmp);
+                && is_writable($config->magento_root . $dirCache)
+                && is_writable($config->magento_root . $dirTmp);
             if (!$isWritable) {
                 $this->doError($command, $err);
                 throw new Exception(
@@ -316,7 +316,7 @@ final class Mage_Connect_Command_Install extends Mage_Connect_Command
                     if ($ftp) {
                         $cwd=$ftpObj->getcwd();
                         $dir=$cwd . DIRECTORY_SEPARATOR .$config->downloader_path . DIRECTORY_SEPARATOR
-                             . Mage_Connect_Config::DEFAULT_CACHE_PATH . DIRECTORY_SEPARATOR . trim( $pChan, "\\/");
+                            . Mage_Connect_Config::DEFAULT_CACHE_PATH . DIRECTORY_SEPARATOR . trim( $pChan, "\\/");
                         $ftpObj->mkdirRecursive($dir,0777);
                         $ftpObj->chdir($cwd);
                     } else {
@@ -346,11 +346,33 @@ final class Mage_Connect_Command_Install extends Mage_Connect_Command
 
                     $package = new Mage_Connect_Package($file);
                     if ($clearInstallMode && $pInstallState != 'upgrade' && !$installAll) {
-                        $this->validator()->validateContents($package->getContents(), $config);
+                        $contents = $package->getContents();
+                        $this->backup()->setFileTypes(array('csv', 'html'));
+                        $typesToBackup = $this->backup()->getFileTypes();
+                        $this->validator()->validateContents($contents, $config, $typesToBackup);
                         $errors = $this->validator()->getErrors();
                         if (count($errors)) {
                             throw new Exception("Package '{$pName}' is invalid\n" . implode("\n", $errors));
                         }
+
+                        $targetPath = rtrim($config->magento_root, "\\/");
+                        foreach ($contents as $filePath) {
+                            $this->backup()->addFile($filePath, $targetPath);
+                        }
+
+                        if ($this->backup()->getFilesCount() > 0) {
+                            $this->ui()->output('<br/>');
+                            $this->ui()->output('Backup of following files will be created :');
+                            $this->ui()->output('<br/>');
+                            $this->backup()->run();
+                            $this->ui()->output(implode('<br/>', $this->backup()->getAllFiles()));
+                            $this->ui()->output('<br/>');
+                            $this->ui()->output(
+                                $this->backup()->getFilesCount() . ' files was overwritten by installed extension.'
+                            );
+                            $this->ui()->output('<br/>');
+                            $this->backup()->unsetAllFiles();
+                        }
                     }
 
                     $conflicts = $package->checkPhpDependencies();
diff --git downloader/lib/Mage/Connect/Packager.php downloader/lib/Mage/Connect/Packager.php
index 3519324..09ea41b 100644
--- downloader/lib/Mage/Connect/Packager.php
+++ downloader/lib/Mage/Connect/Packager.php
@@ -215,7 +215,7 @@ class Mage_Connect_Packager
      *
      * @param Mage_Connect_Config $cache
      * @param Mage_Connect_Ftp $ftpObj
-     * @return void
+     * @throws RuntimeException
      */
     public function writeToRemoteConfig($cache, $ftpObj)
     {
@@ -240,8 +240,15 @@ class Mage_Connect_Packager
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
@@ -253,7 +260,7 @@ class Mage_Connect_Packager
      * @param string $package
      * @param Mage_Connect_Singleconfig $cacheObj
      * @param Mage_Connect_Config $configObj
-     * @return void
+     * @throws RuntimeException
      */
     public function processUninstallPackage($chanName, $package, $cacheObj, $configObj)
     {
@@ -261,14 +268,21 @@ class Mage_Connect_Packager
         $contents = $package->getContents();
 
         $targetPath = rtrim($configObj->magento_root, "\\/");
+        $failedFiles = array();
         foreach ($contents as $file) {
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
@@ -283,17 +297,26 @@ class Mage_Connect_Packager
      * @param $package
      * @param Mage_Connect_Singleconfig $cacheObj
      * @param Mage_Connect_Ftp $ftp
-     * @return void
+     * @throws RuntimeException
      */
     public function processUninstallPackageFtp($chanName, $package, $cacheObj, $ftp)
     {
         $ftpDir = $ftp->getcwd();
         $package = $cacheObj->getPackageObject($chanName, $package);
         $contents = $package->getContents();
+        $failedFiles = array();
         foreach ($contents as $file) {
             $ftp->delete($file);
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
@@ -362,7 +385,7 @@ class Mage_Connect_Packager
      * @param string $file
      * @param Mage_Connect_Config $configObj
      * @param Mage_Connect_Ftp $ftp
-     * @return void
+     * @throws RuntimeException
      */
     public function processInstallPackageFtp($package, $file, $configObj, $ftp)
     {
@@ -370,10 +393,13 @@ class Mage_Connect_Packager
         $contents = $package->getContents();
         $arc = $this->getArchiver();
         $target = dirname($file) . DS . $package->getReleaseFilename();
-        @mkdir($target, 0777, true);
+        if (!@mkdir($target, 0777, true)) {
+            throw new RuntimeException("Can't create directory ". $target);
+        }
         $tar = $arc->unpack($file, $target);
         $modeFile = $this->_getFileMode($configObj);
         $modeDir = $this->_getDirMode($configObj);
+        $failedFiles = array();
         foreach ($contents as $file) {
             $source = $tar . DS . $file;
             if (file_exists($source) && is_file($source)) {
@@ -382,10 +408,17 @@ class Mage_Connect_Packager
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
@@ -414,11 +447,16 @@ class Mage_Connect_Packager
         $modeFile = $this->_getFileMode($configObj);
         $modeDir = $this->_getDirMode($configObj);
         $targetPath = rtrim($configObj->magento_root, "\\/");
+        $packageXmlDir = $targetPath . DS . Mage_Connect_Package::PACKAGE_XML_DIR;
+        if (!is_dir_writeable($packageXmlDir)) {
+            throw new RuntimeException('Directory ' . $packageXmlDir . ' is not writable. Check permission');
+        }
+        $this->_makeDirectories($contents, $targetPath, $modeDir);
         foreach ($contents as $file) {
             $fileName = basename($file);
             $filePath = dirname($file);
             $source = $tar . DS . $file;
-            @mkdir($targetPath. DS . $filePath, $modeDir, true);
+            $source = $tar . DS . $file;
             $dest = $targetPath . DS . $filePath . DS . $fileName;
             if (is_file($source)) {
                 @copy($source, $dest);
@@ -444,6 +482,36 @@ class Mage_Connect_Packager
     }
 
     /**
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
+
+    /**
      * Get local modified files
      *
      * @param string $chanName
diff --git downloader/lib/Mage/Connect/Rest.php downloader/lib/Mage/Connect/Rest.php
index 981c99a..d7366c3 100644
--- downloader/lib/Mage/Connect/Rest.php
+++ downloader/lib/Mage/Connect/Rest.php
@@ -82,17 +82,14 @@ class Mage_Connect_Rest
      *
      * @param string $protocol
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
index 450c04e..7dfaaf1 100644
--- downloader/lib/Mage/Connect/Singleconfig.php
+++ downloader/lib/Mage/Connect/Singleconfig.php
@@ -136,7 +136,6 @@ class Mage_Connect_Singleconfig
         $uri = rtrim($uri, "/");
         $uri = str_replace("http://", '', $uri);
         $uri = str_replace("https://", '', $uri);
-        $uri = str_replace("ftp://", '', $uri);
         return $uri;
     }
 
diff --git downloader/lib/Mage/Connect/Validator.php downloader/lib/Mage/Connect/Validator.php
index 384274b..fcb4198 100644
--- downloader/lib/Mage/Connect/Validator.php
+++ downloader/lib/Mage/Connect/Validator.php
@@ -459,9 +459,10 @@ class Mage_Connect_Validator
      *
      * @param array $contents
      * @param Mage_Connect_Config $config
+     * @param array $typesToBackup
      * @return bool
      */
-    public function validateContents(array $contents, $config)
+    public function validateContents(array $contents, $config, $typesToBackup = array())
     {
         if (!count($contents)) {
             $this->addError('Empty package contents section');
@@ -471,7 +472,8 @@ class Mage_Connect_Validator
         $targetPath = rtrim($config->magento_root, "\\/");
         foreach ($contents as $file) {
             $dest = $targetPath . DS . $file;
-            if (file_exists($dest)) {
+            $type = pathinfo($file, PATHINFO_EXTENSION);
+            if (file_exists($dest) && !in_array($type, $typesToBackup)) {
                 $this->addError("'{$file}' already exists");
                 return false;
             }
diff --git downloader/lib/Mage/HTTP/Client/Curl.php downloader/lib/Mage/HTTP/Client/Curl.php
index bc3685f..1d0833c 100644
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
index b094d4d..83e3987 100755
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
