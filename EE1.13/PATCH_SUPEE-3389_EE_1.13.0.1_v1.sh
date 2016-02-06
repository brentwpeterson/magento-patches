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


SUPEE-3389 | EE_1.13.0.1 | v1 | 89010ebb93c001c093e5812f036db5b8ecb20dda | Fri Apr 18 17:20:06 2014 -0700 | v1.13.0.1..HEAD

__PATCHFILE_FOLLOWS__
diff --git lib/Varien/Cache/Backend/Database.php lib/Varien/Cache/Backend/Database.php
index b8719f5..2127abf 100644
--- lib/Varien/Cache/Backend/Database.php
+++ lib/Varien/Cache/Backend/Database.php
@@ -137,18 +137,19 @@ class Varien_Cache_Backend_Database extends Zend_Cache_Backend implements Zend_C
      */
     public function load($id, $doNotTestCacheValidity = false)
     {
-        if ($this->_options['store_data']) {
-            $select = $this->_getAdapter()->select()
-                ->from($this->_getDataTable(), 'data')
-                ->where('id=:cache_id');
-
-            if (!$doNotTestCacheValidity) {
-                $select->where('expire_time=0 OR expire_time>?', time());
-            }
-            return $this->_getAdapter()->fetchOne($select, array('cache_id'=>$id));
-        } else {
+        if (!$this->_options['store_data']) {
             return false;
         }
+
+        $select = $this->_getAdapter()->select()
+            ->from($this->_getDataTable(), 'data')
+            ->where('id=:cache_id');
+
+        if (!$doNotTestCacheValidity) {
+            $select->where('expire_time = 0 OR expire_time > ?', time());
+        }
+
+        return $this->_getAdapter()->fetchOne($select, array('cache_id' => $id));
     }
 
     /**
@@ -159,31 +160,34 @@ class Varien_Cache_Backend_Database extends Zend_Cache_Backend implements Zend_C
      */
     public function test($id)
     {
-        if ($this->_options['store_data']) {
-            $select = $this->_getAdapter()->select()
-                ->from($this->_getDataTable(), 'update_time')
-                ->where('id=:cache_id')
-                ->where('expire_time=0 OR expire_time>?', time());
-            return $this->_getAdapter()->fetchOne($select, array('cache_id'=>$id));
-        } else {
+        if (!$this->_options['store_data']) {
             return false;
         }
+
+        $select = $this->_getAdapter()->select()
+            ->from($this->_getDataTable(), 'update_time')
+            ->where('id=:cache_id')
+            ->where('expire_time = 0 OR expire_time > ?', time());
+        return $this->_getAdapter()->fetchOne($select, array('cache_id' => $id));
     }
 
     /**
-     * Save some string datas into a cache record
+     * Save data into a cache storage
      *
      * Note : $data is always "string" (serialization is done by the
      * core not by the backend)
      *
-     * @param  string $data            Datas to cache
-     * @param  string $id              Cache id
-     * @param  array $tags             Array of strings, the cache record will be tagged by each string entry
-     * @param  int   $specificLifetime If != false, set a specific lifetime for this cache record (null => infinite lifetime)
-     * @return boolean true if no problem
+     * @param  string $data Data to cache
+     * @param  string $id Cache id
+     * @param  array $tags Array of strings, the cache record will be tagged by each string entry
+     * @param  int|bool|null $specificLifetime If != false, set a specific lifetime for this cache record
+     *                                    (null => infinite lifetime)
+     *
+     * @return bool true if no problem
      */
     public function save($data, $id, $tags = array(), $specificLifetime = false)
     {
+        $result = true;
         if ($this->_options['store_data']) {
             $adapter    = $this->_getAdapter();
             $dataTable  = $this->_getDataTable();
@@ -209,8 +213,8 @@ class Varien_Cache_Backend_Database extends Zend_Cache_Backend implements Zend_C
                 return false;
             }
         }
-        $tagRes = $this->_saveTags($id, $tags);
-        return $tagRes;
+
+        return $result && $this->_saveTags($id, $tags);
     }
 
     /**
@@ -221,13 +225,13 @@ class Varien_Cache_Backend_Database extends Zend_Cache_Backend implements Zend_C
      */
     public function remove($id)
     {
+        $adapter = $this->_getAdapter();
+        $result = true;
         if ($this->_options['store_data']) {
-            $adapter = $this->_getAdapter();
-            $result = $adapter->delete($this->_getDataTable(), array('id=?'=>$id));
-            return $result;
-        } else {
-            return false;
+            $result = $adapter->delete($this->_getDataTable(), array('id = ?' => $id));
         }
+
+        return $result && $adapter->delete($this->_getTagsTable(), array('cache_id = ?' => $id));
     }
 
     /**
@@ -250,23 +254,18 @@ class Varien_Cache_Backend_Database extends Zend_Cache_Backend implements Zend_C
     public function clean($mode = Zend_Cache::CLEANING_MODE_ALL, $tags = array())
     {
         $adapter = $this->_getAdapter();
+        $result = true;
+
         switch($mode) {
             case Zend_Cache::CLEANING_MODE_ALL:
                 if ($this->_options['store_data']) {
-                    $result = $adapter->query('TRUNCATE TABLE '.$this->_getDataTable());
-                } else {
-                    $result = true;
+                    $result = $adapter->query('TRUNCATE TABLE ' . $this->_getDataTable());
                 }
-                $result = $result && $adapter->query('TRUNCATE TABLE '.$this->_getTagsTable());
+                $result = $result && $adapter->query('TRUNCATE TABLE ' . $this->_getTagsTable());
                 break;
             case Zend_Cache::CLEANING_MODE_OLD:
                 if ($this->_options['store_data']) {
-                    $result = $adapter->delete($this->_getDataTable(), array(
-                        'expire_time> ?' => 0,
-                        'expire_time<= ?' => time()
-                    ));
-                } else {
-                    $result = true;
+                    $result = $this->_cleanOldCache();
                 }
                 break;
             case Zend_Cache::CLEANING_MODE_MATCHING_TAG:
@@ -283,6 +282,52 @@ class Varien_Cache_Backend_Database extends Zend_Cache_Backend implements Zend_C
     }
 
     /**
+     * Clean old cache data and related cache tag data
+     *
+     * @return bool
+     */
+    protected function _cleanOldCache()
+    {
+        $time = time();
+        $adapter = $this->_getAdapter();
+
+        $select = $adapter->select()
+            ->from($this->_getDataTable(), 'id')
+            ->where('expire_time > ?', 0)
+            ->where('expire_time <= ?', $time);
+        $statement = $adapter->query($select);
+
+        $cacheIdsToRemove = array();
+        $counter = 0;
+        $result = true;
+        while (($row = $statement->fetch()) == true) {
+            $cacheIdsToRemove[] = $row['id'];
+            $counter++;
+            if ($counter > 100) {
+                $result = $result && $adapter->delete(
+                    $this->_getTagsTable(),
+                    array('cache_id IN (?)' => $cacheIdsToRemove)
+                );
+                $cacheIdsToRemove = array();
+                $counter = 0;
+            }
+        }
+        if (!empty($cacheIdsToRemove)) {
+            $result = $result && $adapter->delete(
+                $this->_getTagsTable(),
+                array('cache_id IN (?)' => $cacheIdsToRemove)
+            );
+        }
+
+        $result = $result && $adapter->delete($this->_getDataTable(), array(
+            'expire_time > ?' => 0,
+            'expire_time <= ?' => $time
+        ));
+
+        return $result;
+    }
+
+    /**
      * Return an array of stored cache ids
      *
      * @return array array of stored cache ids (string)
@@ -412,15 +457,15 @@ class Varien_Cache_Backend_Database extends Zend_Cache_Backend implements Zend_C
      */
     public function touch($id, $extraLifetime)
     {
-        if ($this->_options['store_data']) {
-            return $this->_getAdapter()->update(
-                $this->_getDataTable(),
-                array('expire_time'=>new Zend_Db_Expr('expire_time+'.$extraLifetime)),
-                array('id=?'=>$id, 'expire_time = 0 OR expire_time>'=>time())
-            );
-        } else {
+        if (!$this->_options['store_data']) {
             return true;
         }
+
+        return $this->_getAdapter()->update(
+            $this->_getDataTable(),
+            array('expire_time' => new Zend_Db_Expr('expire_time + ' . $extraLifetime)),
+            array('id = ?' => $id, 'expire_time = 0 OR expire_time > ? ' => time())
+        );
     }
 
     /**
@@ -472,6 +517,7 @@ class Varien_Cache_Backend_Database extends Zend_Cache_Backend implements Zend_C
             ->where('cache_id=?', $id)
             ->where('tag IN(?)', $tags);
 
+        $result = true;
         $existingTags = $adapter->fetchCol($select);
         $insertTags = array_diff($tags, $existingTags);
         if (!empty($insertTags)) {
@@ -483,10 +529,10 @@ class Varien_Cache_Backend_Database extends Zend_Cache_Backend implements Zend_C
                 $bind[] = $tag;
                 $bind[] = $id;
             }
-            $query.= implode(',', $lines);
-            $adapter->query($query, $bind);
+            $query .= implode(',', $lines);
+            $result = $adapter->query($query, $bind);
         }
-        $result = true;
+
         return $result;
     }
 
@@ -499,46 +545,58 @@ class Varien_Cache_Backend_Database extends Zend_Cache_Backend implements Zend_C
      */
     protected function _cleanByTags($mode, $tags)
     {
-        if ($this->_options['store_data']) {
-            $adapter = $this->_getAdapter();
-            $select = $adapter->select()
-                ->from($this->_getTagsTable(), 'cache_id');
-            switch ($mode) {
-                case Zend_Cache::CLEANING_MODE_MATCHING_TAG:
-                    $select->where('tag IN (?)', $tags)
-                        ->group('cache_id')
-                        ->having('COUNT(cache_id)='.count($tags));
+        $adapter = $this->_getAdapter();
+        $result = true;
+        $select = $adapter->select()
+            ->from($this->_getTagsTable(), 'cache_id');
+        switch ($mode) {
+            case Zend_Cache::CLEANING_MODE_MATCHING_TAG:
+                $select->where('tag IN (?)', $tags)
+                    ->group('cache_id')
+                    ->having('COUNT(cache_id) = ' . count($tags));
                 break;
-                case Zend_Cache::CLEANING_MODE_NOT_MATCHING_TAG:
-                    $select->where('tag NOT IN (?)', $tags);
+            case Zend_Cache::CLEANING_MODE_NOT_MATCHING_TAG:
+                $select->where('tag NOT IN (?)', $tags);
                 break;
-                case Zend_Cache::CLEANING_MODE_MATCHING_ANY_TAG:
-                    $select->where('tag IN (?)', $tags);
+            case Zend_Cache::CLEANING_MODE_MATCHING_ANY_TAG:
+                $select->where('tag IN (?)', $tags);
                 break;
-                default:
-                    Zend_Cache::throwException('Invalid mode for _cleanByTags() method');
+            default:
+                Zend_Cache::throwException('Invalid mode for _cleanByTags() method');
                 break;
-            }
+        }
 
-            $result = true;
-            $ids = array();
-            $counter = 0;
-            $stmt = $adapter->query($select);
-            while ($row = $stmt->fetch()) {
-                $ids[] = $row['cache_id'];
-                $counter++;
-                if ($counter>100) {
-                    $result = $result && $adapter->delete($this->_getDataTable(), array('id IN (?)' => $ids));
-                    $ids = array();
-                    $counter = 0;
+        $cacheIdsToRemove = array();
+        $counter = 0;
+        $statement = $adapter->query($select);
+        while (($row = $statement->fetch()) == true) {
+            $cacheIdsToRemove[] = $row['cache_id'];
+            $counter++;
+            if ($counter > 100) {
+                if ($this->_options['store_data']) {
+                    $result = $result && $adapter->delete(
+                        $this->_getDataTable(),
+                        array('id IN (?)' => $cacheIdsToRemove)
+                    );
                 }
+                $result = $result && $adapter->delete(
+                    $this->_getTagsTable(),
+                    array('cache_id IN (?)' => $cacheIdsToRemove)
+                );
+                $cacheIdsToRemove = array();
+                $counter = 0;
             }
-            if (!empty($ids)) {
-                $result = $result && $adapter->delete($this->_getDataTable(), array('id IN (?)' => $ids));
+        }
+        if (!empty($cacheIdsToRemove)) {
+            if ($this->_options['store_data']) {
+                $result = $result && $adapter->delete(
+                    $this->_getDataTable(), array('id IN (?)' => $cacheIdsToRemove)
+                );
             }
-            return $result;
-        } else {
-            return true;
+            $result = $result && $adapter->delete(
+                $this->_getTagsTable(), array('cache_id IN (?)' => $cacheIdsToRemove)
+            );
         }
+        return $result;
     }
 }
