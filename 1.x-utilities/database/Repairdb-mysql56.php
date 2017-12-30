<?php
/**
 * Magento
 *
 * NOTICE OF LICENSE
 *
 * This source file is subject to the Open Software License (OSL 3.0)
 * that is bundled with this package in the file LICENSE.txt.
 * It is also available through the world-wide-web at this URL:
 * http://opensource.org/licenses/osl-3.0.php
 * If you did not receive a copy of the license and are unable to
 * obtain it through the world-wide-web, please send an email
 * to license@magentocommerce.com so we can send you a copy immediately.
 *
 * DISCLAIMER
 *
 * Do not edit or add to this file if you wish to upgrade Magento to newer
 * versions in the future. If you wish to customize Magento for your
 * needs please refer to http://www.magentocommerce.com for more information.
 *
 * @category   Mage
 * @package    tools
 * @copyright  Copyright (c) 2009 Irubin Consulting Inc. DBA Varien (http://www.varien.com)
 * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
 */

class Tools_Db_Repair_Mysql4
{
    const TYPE_CORRUPTED    = 'corrupted';
    const TYPE_REFERENCE    = 'reference';

    /**
     * Corrupted Database resource
     *
     * @var resource
     */
    protected $_corrupted;

    /**
     * Reference Database resource
     *
     * @var resource
     */
    protected $_reference;

    /**
     * Config
     *
     * @var array
     */
    protected $_config = array();

    /**
     * Set connection
     *
     * @param array $config
     * @param string $type
     * @return Tools_Db_Repair
     */
    public function setConnection(array $config, $type)
    {
        if ($type == self::TYPE_CORRUPTED) {
            $connection = &$this->_corrupted;
        }
        elseif ($type == self::TYPE_REFERENCE) {
            $connection = &$this->_reference;
        }
        else {
            throw new Exception('Unknown connection type');
        }

        $required = array('hostname', 'username', 'password', 'database', 'prefix');
        foreach ($required as $field) {
            if (!array_key_exists($field, $config)) {
                throw new Exception(sprintf('Please specify %s for %s database connection', $field, $type));
            }
        }

        if (!$connection = @mysql_connect($config['hostname'], $config['username'], $config['password'], true)) {
            throw new Exception(sprintf('%s database connection error: #%d %s', ucfirst($type), mysql_errno(), mysql_error()));
        }
        if (!@mysql_select_db($config['database'], $connection)) {
            throw new Exception(sprintf('Cannot select %s database (%s): #%d, %s', $type, $config['database'], mysql_errno(), mysql_error()));
        }
        mysql_query('SET NAMES utf8', $connection);

        $this->_config[$type] = $config;

        return $this;
    }

    /**
     * Check exists connections
     *
     * @return bool
     */
    protected function _checkConnection()
    {
        if (is_null($this->_corrupted)) {
            throw new Exception(sprintf('Invalid %s database connection', self::TYPE_CORRUPTED));
        }
        if (is_null($this->_reference)) {
            throw new Exception(sprintf('Invalid %s database connection', self::TYPE_REFERENCE));
        }
        return true;
    }

    /**
     * Retrieve table name
     *
     * @param string $table
     * @param string $type
     * @return string
     */
    public function getTable($table, $type)
    {
        $prefix = $this->_config[$type]['prefix'];
        return $prefix . $table;
    }

    /**
     * Retrieve connection resource
     *
     * @param string $type
     * @return resource
     */
    protected function _getConnection($type)
    {
        if ($type == self::TYPE_CORRUPTED) {
            return $this->_corrupted;
        }
        elseif ($type == self::TYPE_REFERENCE) {
            return $this->_reference;
        }
        else {
            throw new Exception(sprintf('Unknown connection type "%s"', $type));
        }
    }

    /**
     * Check connection type
     *
     * @param string $type
     * @return bool
     *
     * @throws Exception
     */
    protected function _checkType($type)
    {
        if ($type == self::TYPE_CORRUPTED || $type == self::TYPE_REFERENCE) {
            return true;
        } else {
            throw new Exception(sprintf('Unknown connection type "%s"', $type));
        }
    }

    /**
     * Check exists table
     *
     * @param string $table
     * @param string $type
     * @return bool
     */
    public function tableExists($table, $type)
    {
        $this->_checkConnection();
        $this->_checkType($type);

        $sql = $this->_quote("SHOW TABLES LIKE ?", $this->getTable($table, $type));
        $res = mysql_query($sql, $this->_getConnection($type));
        if (!mysql_fetch_row($res)) {
            return false;
        }
        return true;
    }

    /**
     * Simple quote SQL statement
     * supported ? or %[type] sprintf format
     *
     * @param string $statement
     * @param array $bind
     * @return string
     */
    protected function _quote($statement, $bind = array())
    {
        $statement = str_replace('?', '%s', $statement);
        if (!is_array($bind)) {
            $bind = array($bind);
        }
        foreach ($bind as $k => $v) {
            if (is_numeric($v)) {
                $bind[$k] = $v;
            }
            elseif (is_null($v)) {
                $bind[$k] = 'NULL';
            }
            else {
                $bind[$k] = "'" . mysql_escape_string($v) . "'";
            }
        }
        return vsprintf($statement, $bind);
    }

    /**
     * Compare core_resource version
     *
     * @return array
     */
    public function compareResource()
    {
        if (!$this->tableExists('core_resource', self::TYPE_CORRUPTED)) {
            throw new Exception(sprintf('%s DB doesn\'t seem to be a valid Magento database', self::TYPE_CORRUPTED));
        }
        if (!$this->tableExists('core_resource', self::TYPE_REFERENCE)) {
            throw new Exception(sprintf('%s DB doesn\'t seem to be a valid Magento database', self::TYPE_REFERENCE));
        }

        $corrupted = $reference = array();

        $sql = "SELECT * FROM `{$this->getTable('core_resource', self::TYPE_CORRUPTED)}`";
        $res = mysql_query($sql, $this->_getConnection(self::TYPE_CORRUPTED));
        while ($row = mysql_fetch_assoc($res)) {
            $corrupted[$row['code']] = $row['version'];
        }

        $sql = "SELECT * FROM `{$this->getTable('core_resource', self::TYPE_REFERENCE)}`";
        $res = mysql_query($sql, $this->_getConnection(self::TYPE_REFERENCE));
        while ($row = mysql_fetch_assoc($res)) {
            $reference[$row['code']] = $row['version'];
        }

        $compare = array();
        foreach ($reference as $k => $v) {
            if (!isset($corrupted[$k])) {
                $compare[] = sprintf('Module "%s" is not installed in corrupted DB', $k);
            }
            elseif ($corrupted[$k] != $v) {
                $compare[] = sprintf('Module "%s" has wrong version %s in corrupted DB (reference DB contains "%s" ver. %s)', $k, $corrupted[$k], $k, $v);
            }
        }

        return $compare;
    }

    /**
     * Check db support of InnoDb Engine
     *
     * @param string $type
     * @return bool
     */
    public function checkInnodbSupport($type)
    {
        $res = $this->sqlQuery('SELECT VERSION()', $type);
        $version = mysql_fetch_row($res);
        if (version_compare($version[0], '5.6.0') >= 0) {
            $res = $this->sqlQuery('SHOW ENGINES', $type);
            while ($row = mysql_fetch_assoc($res)) {
                if ($row['Engine'] == 'InnoDB' && strtoupper($row['Transactions']) == 'YES') {
                    return true;
                }
            }
            return false;
        }

        $sql = $this->_quote("SHOW VARIABLES LIKE ?", 'have_innodb');
        $res = $this->sqlQuery($sql, $type);
        $row = mysql_fetch_assoc($res);
        if ($row && strtoupper($row['Value']) == 'YES') {
            return true;
        }
        return false;
    }

    /**
     * Apply to Database needed settings
     *
     * @param string $type
     * @return Tools_Db_Repair_Mysql4_Mysql4
     */
    public function start($type)
    {
        $this->sqlQuery('/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */', $type);
        $this->sqlQuery('/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */', $type);
        $this->sqlQuery('/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */', $type);
        $this->sqlQuery('/*!40101 SET NAMES utf8 */', $type);
        $this->sqlQuery('/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */', $type);
        $this->sqlQuery('/*!40103 SET TIME_ZONE=\'+00:00\' */', $type);
        $this->sqlQuery('/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */', $type);
        $this->sqlQuery('/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */', $type);
        $this->sqlQuery('/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE=\'NO_AUTO_VALUE_ON_ZERO\' */', $type);
        $this->sqlQuery('/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */', $type);

        return $this;
    }

    /**
     * Return old settings to database (applied in start method)
     *
     * @param string $type
     * @return Tools_Db_Repair_Mysql4
     */
    public function finish($type)
    {
        $this->sqlQuery('/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */', $type);
        $this->sqlQuery('/*!40101 SET SQL_MODE=@OLD_SQL_MODE */', $type);
        $this->sqlQuery('/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */', $type);
        $this->sqlQuery('/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */', $type);
        $this->sqlQuery('/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */', $type);
        $this->sqlQuery('/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */', $type);
        $this->sqlQuery('/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */', $type);
        $this->sqlQuery('/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */', $type);

        return $this;
    }

    /**
     * Begin transaction
     *
     * @param string $type
     * @return Tools_Db_Repair_Mysql4
     */
    public function begin($type)
    {
        $this->sqlQuery('START TRANSACTION', $type);
        return $this;
    }

    /**
     * Commit transaction
     *
     * @param string $type
     * @return Tools_Db_Repair_Mysql4
     */
    public function commit($type)
    {
        $this->sqlQuery('COMMIT', $type);
        return $this;
    }

    /**
     * Rollback transaction
     *
     * @param string $type
     * @return Tools_Db_Repair_Mysql4
     */
    public function rollback($type)
    {
        $this->sqlQuery('ROLLBACK', $type);
        return $this;
    }

    /**
     * Retrieve table properties as array
     * fields, keys, constraints, engine, charset, create
     *
     * @param string $table
     * @param string $type
     * @return array
     */
    public function getTableProperties($table, $type)
    {
        $this->_checkConnection();
        $this->_checkType($type);

        if (!$this->tableExists($table, $type)) {
            return false;
        }

        $tableName = $this->getTable($table, $type);
        $prefix    = $this->_config[$type]['prefix'];
        $tableProp = array(
            'fields'      => array(),
            'keys'        => array(),
            'constraints' => array(),
            'engine'      => 'MYISAM',
            'charset'     => 'utf8',
            'collate'     => null,
            'create_sql'  => null,
            'triggers'    => array()
        );

        // collect fields
        $sql = "SHOW FULL COLUMNS FROM `{$tableName}`";
        $res = mysql_query($sql, $this->_getConnection($type));
        while($row = mysql_fetch_row($res)) {
            $tableProp['fields'][$row[0]] = array(
                'type'      => $row[1],
                'is_null'   => strtoupper($row[3]) == 'YES' ? true : false,
                'default'   => $row[5],
                'extra'     => $row[6],
                'collation' => $row[2],
            );
        }

        // create sql
        $sql = "SHOW CREATE TABLE `{$tableName}`";
        $res = mysql_query($sql, $this->_getConnection($type));
        $row = mysql_fetch_row($res);

        $tableProp['create_sql'] = $row[1];

        // collect keys
        $regExp  = '#(PRIMARY|UNIQUE|FULLTEXT|FOREIGN)?\s+KEY\s+(`[^`]+` )?(\([^\)]+\))#';
        $matches = array();
        preg_match_all($regExp, $tableProp['create_sql'], $matches, PREG_SET_ORDER);
        foreach ($matches as $match) {
            if (isset($match[1]) && $match[1] == 'PRIMARY') {
                $keyName = 'PRIMARY';
            }
            elseif (isset($match[1]) && $match[1] == 'FOREIGN') {
                continue;
            }
            else {
                $keyName = substr($match[2], 1, -2);
            }
            $fields = $fieldsMatches = array();
            preg_match_all("#`([^`]+)`#", $match[3], $fieldsMatches, PREG_SET_ORDER);
            foreach ($fieldsMatches as $field) {
                $fields[] = $field[1];
            }

            $tableProp['keys'][strtoupper($keyName)] = array(
                'type'   => !empty($match[1]) ? $match[1] : 'INDEX',
                'name'   => $keyName,
                'fields' => $fields
            );
        }

        // collect CONSTRAINT
        $regExp  = '#,\s+CONSTRAINT `([^`]*)` FOREIGN KEY \(`([^`]*)`\) '
            . 'REFERENCES (`[^`]*\.)?`([^`]*)` \(`([^`]*)`\)'
            . '( ON DELETE (RESTRICT|CASCADE|SET NULL|NO ACTION))?'
            . '( ON UPDATE (RESTRICT|CASCADE|SET NULL|NO ACTION))?#';
        $matches = array();
        preg_match_all($regExp, $tableProp['create_sql'], $matches, PREG_SET_ORDER);
        foreach ($matches as $match) {
            $tableProp['constraints'][strtoupper($match[1])] = array(
                'fk_name'   => strtoupper($match[1]),
                'ref_db'    => isset($match[3]) ? $match[3] : null,
                'pri_table' => $table,
                'pri_field' => $match[2],
                'ref_table' => substr($match[4], strlen($prefix)),
                'ref_field' => $match[5],
                'on_delete' => isset($match[6]) ? $match[7] : '',
                'on_update' => isset($match[8]) ? $match[9] : ''
            );
        }

        // engine
        $regExp = "#(ENGINE|TYPE)="
            . "(MEMORY|HEAP|INNODB|MYISAM|ISAM|BLACKHOLE|BDB|BERKELEYDB|MRG_MYISAM|ARCHIVE|CSV|EXAMPLE)"
            . "#i";
        $match  = array();
        if (preg_match($regExp, $tableProp['create_sql'], $match)) {
            $tableProp['engine'] = strtoupper($match[2]);
        }

        //charset
        $regExp = "#DEFAULT CHARSET=([a-z0-9]+)( COLLATE=([a-z0-9_]+))?#i";
        $match  = array();
        if (preg_match($regExp, $tableProp['create_sql'], $match)) {
            $tableProp['charset'] = strtolower($match[1]);
            if (isset($match[3])) {
                $tableProp['collate'] = $match[3];
            }
        }

        $sql = "SHOW TRIGGERS LIKE '${tableName}'";
        $res = mysql_query($sql, $this->_getConnection($type));
        while($row = mysql_fetch_assoc($res)) {
            $triggerName = strtolower($row["Trigger"]);
            $tableProp['triggers'][$triggerName] = $row;
        }

        return $tableProp;
    }

    public function getTables($type)
    {
        $this->_checkConnection();
        $this->_checkType($type);
        $prefix = $this->_config[$type]['prefix'];

        $tables = array();

        $sql = 'SHOW TABLES';
        $res = mysql_query($sql, $this->_getConnection($type));
        while ($row = mysql_fetch_row($res)) {
            $tableName = substr($row[0], strlen($prefix));
            $tables[$tableName] = $this->getTableProperties($tableName, $type);
        }

        return $tables;
    }

    /**
     * Add constraint
     *
     * @param array $config
     * @param string $type
     * @return Tools_Db_Repair_Mysql4
     */
    public function addConstraint(array $config, $type)
    {
        $this->_checkConnection();
        $this->_checkType($type);

        $required = array('fk_name', 'pri_table', 'pri_field', 'ref_table', 'ref_field', 'on_update', 'on_delete');
        foreach ($required as $field) {
            if (!array_key_exists($field, $config)) {
                throw new Exception(sprintf('Cannot create CONSTRAINT: invalid required config parameter "%s"', $field));
            }
        }

        if ($config['on_delete'] == '' || strtoupper($config['on_delete']) == 'CASCADE'
            || strtoupper($config['on_delete']) == 'RESTRICT') {
            $sql = "DELETE `p`.* FROM `{$this->getTable($config['pri_table'], $type)}` AS `p`"
                . " LEFT JOIN `{$this->getTable($config['ref_table'], $type)}` AS `r`"
                . " ON `p`.`{$config['pri_field']}` = `r`.`{$config['ref_field']}`"
                . " WHERE `p`.`{$config['pri_field']}` IS NOT NULL"
                . " AND `r`.`{$config['ref_field']}` IS NULL";
            $this->sqlQuery($sql, $type);
        }
        elseif (strtoupper($config['on_delete']) == 'SET NULL') {
            $sql = "UPDATE `{$this->getTable($config['pri_table'], $type)}` AS `p`"
                . " LEFT JOIN `{$this->getTable($config['ref_table'], $type)}` AS `r`"
                . " ON `p`.`{$config['pri_field']}` = `r`.`{$config['ref_field']}`"
                . " SET `p`.`{$config['pri_field']}`=NULL"
                . " WHERE `p`.`{$config['pri_field']}` IS NOT NULL"
                . " AND `r`.`{$config['ref_field']}` IS NULL";
            $this->sqlQuery($sql, $type);
        }

        $sql = "ALTER TABLE `{$this->getTable($config['pri_table'], $type)}`"
            . " ADD CONSTRAINT `{$config['fk_name']}`"
            . " FOREIGN KEY (`{$config['pri_field']}`)"
            . " REFERENCES `{$this->getTable($config['ref_table'], $type)}`"
            . "  (`{$config['ref_field']}`)";
        if (!empty($config['on_delete'])) {
            $sql .= ' ON DELETE ' . strtoupper($config['on_delete']);
        }
        if (!empty($config['on_update'])) {
            $sql .= ' ON UPDATE ' . strtoupper($config['on_update']);
        }

        $this->sqlQuery($sql, $type);

        return $this;
    }

    /**
     * Drop Foreign Key from table
     *
     * @param string $table
     * @param string $foreignKey
     * @param string $type
     */
    public function dropConstraint($table, $foreignKey, $type)
    {
        $this->_checkConnection();
        $this->_checkType($type);

        $sql = "ALTER TABLE `{$table}` DROP FOREIGN KEY `{$foreignKey}`";
        $this->sqlQuery($sql, $type);

        return $this;
    }

    /**
     * Add column to table
     * @param string $table
     * @param string $column
     * @param array $config
     * @param string $type
     * @param string|false|null $after
     */
    public function addColumn($table, $column, array $config, $type, $after = null)
    {
        $this->_checkConnection();
        $this->_checkType($type);

        if (!$this->tableExists($table, $type)) {
            return $this;
        }

        $required = array('type', 'is_null', 'default');
        foreach ($required as $field) {
            if (!array_key_exists($field, $config)) {
                throw new Exception(sprintf('Cannot create COLUMN: invalid required config parameter "%s"', $field));
            }
        }

        $sql = "ALTER TABLE `{$this->getTable($table, $type)}` ADD COLUMN `{$column}`"
            . " {$config['type']}"
            . ($config['is_null'] ? "" : " NOT NULL")
            . ($config['default'] ? " DEFAULT '{$config['default']}'" : "")
            . (!empty($config['extra']) ? " {$config['extra']}" : "");
        if ($after === false) {
            $sql .= " FIRST";
        }
        elseif (!is_null($after)) {
            $sql .= " AFTER `{$after}`";
        }

        $this->sqlQuery($sql, $type);

        return $this;
    }

    /**
     * Add primary|unique|fulltext|index to table
     *
     * @param string $table
     * @param array $config
     * @param string $type
     * @return Tools_Db_Repair_Mysql4
     */
    public function addKey($table, array $config, $type)
    {
        $this->_checkConnection();
        $this->_checkType($type);

        if (!$this->tableExists($table, $type)) {
            return $this;
        }

        $required = array('type', 'name', 'fields');
        foreach ($required as $field) {
            if (!array_key_exists($field, $config)) {
                throw new Exception(sprintf('Cannot create KEY: invalid required config parameter "%s"', $field));
            }
        }

        switch (strtolower($config['type'])) {
            case 'primary':
                $condition = "PRIMARY KEY";
                break;
            case 'unique':
                $condition = "UNIQUE `{$config['name']}`";
                break;
            case 'fulltext':
                $condition = "FULLTEXT `{$config['name']}`";
                break;
            default:
                $condition = "INDEX `{$config['name']}`";
                break;
        }
        if (!is_array($config['fields'])) {
            $config['fields'] = array($config['fields']);
        }

        $sql = "ALTER TABLE `{$this->getTable($table, $type)}` ADD {$condition}"
            . " (`" . join("`,`", $config['fields']) . "`)";
        $this->sqlQuery($sql, $type);

        return $this;
    }

    /**
     * Change table storage engine
     *
     * @param string $table
     * @param string $engine
     * @param string $type
     * @return Tools_Db_Repair_Mysql4
     */
    public function changeTableEngine($table, $type, $engine)
    {
        $this->_checkConnection();
        $this->_checkType($type);

        $sql = "ALTER TABLE `{$this->getTable($table, $type)}` ENGINE={$engine}";
        $this->sqlQuery($sql, $type);

        return $this;
    }

    /**
     * Change table storage engine
     *
     * @param string $table
     * @param string $charset
     * @param string $type
     * @return Tools_Db_Repair_Mysql4
     */
    public function changeTableCharset($table, $type, $charset, $collate = null)
    {
        $this->_checkConnection();
        $this->_checkType($type);

        $sql = "ALTER TABLE `{$this->getTable($table, $type)}` DEFAULT CHARACTER SET={$charset}";
        if ($collate) {
            $sql .= " COLLATE {$collate}";
        }
        $this->sqlQuery($sql, $type);

        return $this;
    }

    /**
     * Run SQL query
     *
     * @param string $sql
     * @param string $type
     * @return resource
     */
    public function sqlQuery($sql, $type)
    {
        $this->_checkConnection();
        $this->_checkType($type);

        if (!$res = @mysql_query($sql, $this->_getConnection($type))) {
            throw new Exception(sprintf("Error #%d: %s on SQL: %s",
                mysql_errno($this->_getConnection($type)),
                mysql_error($this->_getConnection($type)),
                $sql
            ));
        }
        return $res;
    }

    /**
     * Retrieve previous key from array by key
     *
     * @param array $array
     * @param mixed $key
     * @return mixed
     */
    public function arrayPrevKey(array $array, $key)
    {
        $prev = false;
        foreach ($array as $k => $v) {
            if ($k == $key) {
                return $prev;
            }
            $prev = $k;
        }
    }

    /**
     * Retrieve next key from array by key
     *
     * @param array $array
     * @param mixed $key
     * @return mixed
     */
    public function arrayNextKey(array $array, $key)
    {
        $next = false;
        foreach ($array as $k => $v) {
            if ($next === true) {
                return $k;
            }
            if ($k == $key) {
                $next = true;
            }
        }
        return false;
    }
}

class Tools_Db_Repair_Helper
{
    protected $_images      = array(
        'error.gif'     => array(
            'base64'    => 'R0lGODlhEAAQAPeAAOxwW+psWe5zXPN8YOtuWvu9qednV/B4X+92XfWCY+JfU+hpWPF6X/N+Yfi0oOZlVvaJa+ViVfbZ0vrJvvKpn/Omkfrd1vSAYuWOg9yXiN19b8JKMeWzqPLUzvWwo9RkUsNMM+ySf/aKcvKKcs5dTPSZhPGon+qNe+yLf+OEdfGTgul9aNVfRup1XOmllva0pM1hS+FdUvq5qfCXg+y6r+BzYPrZ0+yYifTDuOa0qfjb1Pq8qOlvX+NmW+NhVOx/Z/GdkPm5puVxWOeRhfiiidFhUPPVzvWDafGlmfSMdORnXN1uVsxfSfHTzO6DbveFa8VONeuJfe2SifSsofGXhOFyWu2fleaIePLBtvmRee6qm9FhScxVO8ZaQ+dsXd1wXfezpMZVPt6Zi/ihiPCfjsNSO/ijiviGbPi1pfmMdOqHffOvpuGdjtBYQOh/Z/KAZe6gld18b/i2ofWBYvSmku16YPGom+yBbNhtVuySiOeQhPi1pu68sfezoPSEZ/////rr5wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAIAALAAAAAAQABAAAAjSAAEJHEiwYEELMrI8OZLkhQ6DgCakcULHgYMKK37gKDjhDJUCZiBAILIjhBAsAy2ImFEgQYI/fxoMCHKiigSBe+60nHMBJoMDCNB8cSFwRIUxF2TCRCAAgIobeATWkeNnwE+YAAgE4GGnjcAWfd4AFWDjT4AFBrwg4SLQDZkSTQkAWWPgQYQoQ2AI1FIDjNYFMCP4UEChiBiBEpZc8VBXSh4FMShoCNNhIB8WKaagUNJDjYk4G3IUpLHlgx44VjCQKMMBohE2TKCA6JKhCcTbBQMCADs=',
            'type'      => 'image/gif'
        ),
        'success.gif'   => array(
            'base64'    => 'R0lGODlhEAAQAPeeAJDOf67cpYPOd7HLr53YknLIaPz9+7fhr7XhrnrMbW/CYW23V67Xoa/XoLTaprTZpb/juG7EYqnbl0yXPd3q2jN7MJfMhXO6XK/cpm7EYTR/MW+1WHC/V2vDSnPHZmSwTGnCSLLUsFSyNIXFdbXWsL7jtnnBZHTDZE6bQbXbqNvl2pzOjNrn2ZrUjZ3Oi/3+/VG2LSmPJCaDI5/Skb3esbnasH7BaXG5W7fhsCh5JCZ+IyZyJGbESJnNimq5UHXIaF6pSLPZpVy0PY68i2/GZK3em5bNiGy2VpbHg9bu0nDBY6fYk0iwJ+3364nEdsbnunS3WzSOMUKgMkOgMj6MOrTfrH+4aXC4WePw3pbLhqHWlVzCPKPXlnDHZW61WI24in/KcD6KOnbKavH58HbJaXy6ZHe8YLHdp9rk2Y61i/T68t7r2ovIeLTdqtns1JrHh1KgQnK5W6HXlZrKh37Hb4DMcnHEY3S3XHG+X6vTm6vSm+Px3m+1WbLbqH28ZrXfrOHu23nJayh2JD6YO5vXkX23ZnTCWVzAOsDkuYDKczuhJpjLhnTIaH2+Z1q+N4fJeYO+bZnRi2nHScfnuj6EOpDEi27FY5nQjJjMh3HJVOb044fCcm/DYf////j39wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAJ4ALAAAAAAQABAAAAjdAD0JHEiwYME9RTIdcgRiCSCDniZJMsQlQAAtPkTQKPhkC4ADBAQIIICAjaIaA7HwAIAggZgCjH4EquJECgWBEjgcSFCgi6UIdkrQ+QOkksAOcgiRIZKBkwJEnTRFcjFIIIwzdTzgSKIEQicDl2wwkCGQCQYwicZ0avLVyI1GDXQIFDKjxYlHajq9yLIgjoU3YQSu+NDGBJ4Rbnoc8XLHAYovAtdM2dTHzIUrfDZACWJFg4qBJGJASoHJT5lFDwrtGFAwRBQ4c/LoQTKhAmuDLIZQySGIUho0EIMXDAgAOw==',
            'type'      => 'image/gif'
        ),
        'note.gif'   => array(
            'base64'    => 'R0lGODlhEAAQAPefAP787/bhdPbhc/bgcv/++ffnv9eBLPHSlP765fPTpvLSk+7GfqOVev342+rq6/PUpf351OyjTPjly/7520ZGRfz2zf32z/jjtP320v334eq5ae27a/777Pbgcffv1+Wqb/vv0v351vz0yf3lQf354NzTvvft1OzAfN58FuaoT+qZL/vDUe+xYNiJMuuhOOiyZ/z0x++1aPTkx/e+S/CuZfXcWfj14lhELvLKkPbkau+0Y/fv2szMzf788PTesfjw2P3230JCQJiKOlBNRVtXTurAgru8vO/KhJiZnfzz1/HOrO/DnN2VPvPbruWxdPvxyouGd/744vbdpu7Fff/97ffiy/776/787uymTPjkt/z1yPvxuPz00/763Oqza+Gvbp+ho/DIfvzw2P754PvxtP3mR2BZUOiRFvfhd+adRvzwxPvxqPjlhv31wPjqlouPlPLdvPnpyfXiXffjfPbhdfXhsWxlV6KlpvDMhdeDLP331v766/fkgvr56ffmv/vyuv353/blu/7+3HZuYNqOOdOIPO/Ii/XeaPflcvjx1uPcyJeDZpSNf/331frrw/zyz/787P354uaGCfPVRunizv304v765Pr56uvk0frrivjftvvsx6KiqPr35ox/Nfr67AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAJ8ALAAAAAAQABAAAAjbAD8J/JQokJQDeMIc8TFwYCc/WTYlyRBFjKYNGn4M7FPHUSQSjSyIgBFiD44UNgQWuICggaUeBAgAwECGipciAhWAmACIwxUAAKyM2bJGAhOBC4BoqaCHy6Mnav64QVSphcApcSDMYcMihg4sfGpkqkJIYBNDkNCooBPgkABJkwR9cCLw0okHXVwEyCFnwJk2SvLsGOjhRQIaAQQM6BBhiQE4DT+Z+JJmRpkRK1AUkhFZIKVFDIR4GnQDU+eBUO5wQvLGzOmBjIw44AHGzmuBiohQCDKkxO3fAgMCADs=',
            'type'      => 'image/gif'
        ),
        'logo.gif'   => array(
            'base64'    => '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',
            'type'      => 'image/gif'
        ),
        'bkg_header.jpg'   => array(
            'base64'       => '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444444444444444444444444444444444444444/3SfL8g1/1+N0+X5Br/r984444444444444445IcckSHJEhxxxxxxxxxx/gdPl+Qa/wCvxGwwwyDIRQihFKEEoQShDGhDGhrxoa8aGvGiGrCiGrCiGrD6UNOH0oacPpQT+H/LBP8AH+iGvGhrxoa8aIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaIasaJ8BePiFhhhhhlGUZRlIqRWxFbEcrdkcrdkMrdkMrdkMrdkM7dkM7dkM7dmvO3Zrzt2J/hnH/wCdkcrdkcrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrdkMrd/AXj43T5fkGvy/EmGGGGGGGGGGGGGGGGG+xhhhhhhhhhhhhhhhhhhhhv31xPl+w/486DoOg6DoOg6DoOg6DoOg6DoOg6DoOg6DoOg6DoOg6DoOg6DoOg6DoOg6DoOg6DoOg6DoOg6DoOg6DoOg6DoOg6DoOg6DoOg6DoOg6DoOg6DoL/ADRh0HQdB0PT4D9T1PU9T1PU9T1PU9T1PU9T1PU9T1PU9T1PX7fU9f3fx+Qa/L8Nf9px/unHH/bcccccccccccccccccccccccccccf7HHH+1x/tf7pPl8BMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMML/JIkUoRShBKEMaEMaEMaEMaEMaGvGhrxoa8aGvGhrxoQxoQxoQxoQShBKEEoRQihFCK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JJJJJJJJJJJJJJJJJJJJJJJJJLCTADJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJL/8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A7cCgst4ftfb9bfeAAyViSAFyWj5tyWECSSSSSSSSSSSSSSSSSSSSSSSSSSSSwkwAySSSSSSSSSSSSSSSSSSSSSSSSSSSSSStttttttttttttttttttttttttttttttJWMDLXhG2Xf/tpgkCSwyTWeAS2GkkgGSSSSSSSSSSSSSSSSSSAdzgI3jxIUsrCXckkkkkkkkkkkkkkkkkkkkkkkkkkkkkkbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbefDoLN4miSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS8De7yWSfUXcGnCqxW43ROW3bbbbbbbbbbbbbbbbbaSSSSSSSSSSSSbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbwJift+QKSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS9pFwcEEUslspMglvPDEr0oltttttttttttttttttAAAAAAAAAAAAASSSSSSSSSSSSSSSSSSSSSSSSSSSSSSWkmmKX/tttrSxtttKTbY2ySUkgBHaZJJf/2SQq2bbb77f9IEl7f2H3JKgB/QQEyZmAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA222222222222222222222222222222TzYalD5HAkjeAAEVtv2z2SwCQgCkn/wSZJr/EzU222222222Wwmw/8ARC/tIHgkcGNttttttttttttttttttttttttttttttm222222222222222222222222222223Ds99+AjX/wDrdtttJL/a2SE3klbTAl/+20k9tJbWySSS2222gSSjZ9n3/pBPu7FCHpJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJtttttttttttttttt/wD/AP8A/wD/AP8A/wD/AP8A/wD6xqc83EXxWWyW2X5GyWSW2SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSwkwAySSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSWW22222222222222ZMLzyMY2WkE6yyomSS5Jb3lpJPfkQEiSSSSSSSSSSSSSSSSSSSSSSSSSSSSwkwA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hcLw+I+I+I444www5HI5HPoxj9F/CF/vr+sl/WS/rJf1kv6yX9ZL+sl/WS/rJf1kv6yX9ZL+sl/WS/rJf1kv6yX9ZL+sl/WS/rJf1kv6yX9ZL+sl/WS/rJf1kv6yX9ZL+sl/WS/rJf1kv6yX9ZL+sl/WS/rJf1kv6yX9ZL+sl/WS/rJf1kv6yX9ZL+sl/WS/rJf1kv6yX9ZL+sl/WS/rJf1kv6yX9ZL+sl3WS5PWSMT7L0iPmepfak4k6lzWS9PUieMjYyNiMOSJ9In/ACSQSR/zcf8ABqRSKRSKRSKRSKRSKRSKRSKRSKRSKRSKRSKRSKRSKRSKRSKRSKRSKRSKRSKRSKRSKRSKRSKRSKRSKRSKRSKRSKRSKRSKRCEL/INhvQpFIp9RSL0KRCkUikUikUikUi9EIQhCEIQhCEIQhCF6L/gY/wDA4IJJ9J9Z9I/+4n0+P9yhCCCCCERFwLXoWCwWvst/ZZ+yMDWSzrJGHrO5b17kYP3uOe32Wix9lj7IwSyWSyWSyWSyWSyWSyWSyWSyWSyWSyWSyWSyWSyWSyWSyWSyWSyWSyWSyWSyWSyWSyWSyWSyWSyWSyWSyWSyWSyWSyWSz/voJEIX+ByMf+HicR/xx9eJxOPoxjGMY/R+j9H/AKORjIkkYxnD+nA4HGI4xExExExFxLxeLhcLhegvwXS7BGPBfgvFyC5BaEYT01kSJ9y+Xy+XS99l77L32XvsvfZe+y99l77L32XvsvfZe+y99l77L32XvsvfZe+y99l77L32XvsvfZe+y99l77L32XvsvfZe+y99l77L32XvsvfZc+y59lz7Ln2XPsufZc+y59lz7Ln2XPsufZc+y59lz7Ln2XPsufZc+y59lz7Ln2XPsufZc+y59iCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCf3AggnoY/V/8ACT/gn+59I/mSCf5g+f5n39Z9PZ6R6QMYxjGMYxjGMYxjGMYxjGMYxjGMYxj/AOdn/ecDgcDgcDgcDgcCEcDgcDgcDgcDgKDh6nAUCgmAggggsYsddBY66ExjmuQsddCIx10FjmuQsddBYq6FyuhOLNci7NchY5rkXZrkLFNci5Nci5Nci5Nci5Nci5Nci7Nci7Nci7Nci7Nci7Nci7Nci7Nci7NciMSa5Cx10FjroLFNchY5rkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkXZrkf/2Q==',
            'type'      => 'image/jpeg'
        ),
        'bkg_middle.gif'   => array(
            'base64'       => 'R0lGODlhwgONAveVAPv69vr59fn49Pj38/b18ff28vX08PDv7PHw7erp5tLRz+/u6/r69vLx7u3s6PTz8Ovq5+no5cjHxcnIxuTj4PPy7uHg3ebl4uXk4fX08cjIxvTz79PS0MrKyODf3Ojn5O/u6tbV0+zr6PPy7+Lh3tPT0O7t6e7t6vLx7fDv69ra18nIx/Hw7M3Myvb18ufm49HRzt3d2uzr59fW1N/e3N7d29bW0+Hh3vb28vT08M3Ny9XU0t3c2ePi39va2MrJx8vLycvKyM/PzdXV0t/e29TT0drZ19LS0Ovr58fHxdLSz9nY1d/f3N7d2tDPzeDf3enp5evq5u7u6tfX1M7Oy9jX1dzb2dvb2ODg3ff38+Li39jY1fDw7MnJx9nY1s7OzNzc2ePi4OXl4tPT0ejn49XU0dnZ1urq5u3s6drZ1fj39Obm4+Lh3/f28+/v6+3t6ePj4M7Ny+bl4dzb2OHg3tjX1Obl48/OzOzs6PHx7d/f2+jo5eLh3d3d2efn5NHQztbW1N3c2ubm4uXl4d7e29jY1NHQzd7d2eDg3Orp5dvb1/Pz79DQzvr59uTj3+jo5NLRzufn4+Pi3uXk4Nva1/v69gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAJUALAAAAADCA40CAAj/AAsswGDESZJKCBMqXMiwocOHECNKnEixosWLGDNq3Mixo8ePIEOKHEmypMmTKFOqXMmypcuXMGMqTOLECIYFBQReUGFQps+fQIMKHUq0qNGjSJMqXcq0qdOFNFVcwFngwAVKjA4+3cq1q9evYMOKHUu2rNmuSRhRunCgQJYDL3xkPUu3rt27ePPq3cu3r9i0Pl4cyDIAQaQ5f7T6Xcy4sePHkCNLnhwzyZ85kRAMGJDng5XElEOLHk26tOnTqIdatvIhz2YUjz4rTk27tu3buHPrvrv6EYoBAhpE4AFj9u7jyJMrX868OcUkMHhEaCBAQIXhxZ1r3869u/fveqFL/69QvUIC4sbBq1/Pvr379yLFJyAvYMR5GBLg69/Pv7//7hJEl8AI1dlHXH7/Jajgggw2yFiAPAxY4H0IOmjhhRhmqCFREEoowAYUbijiiCSWaOJFHW5QHYgHnujiizDGyGCKK4Yo44045qgjczR+mEAM+O0o5JBEFjlZgDEkoKKPMShQoZFQRinllF9JoECSS4LY5JNUdunll2C+ZCWWNW4Z5plopqmmRmMqWd0DPzq55px01qlmmw+8GSeXdvbp55854qmnmYAWauihIwoqAJyEIuroo5DypyijckZq6aWYbidoAJTymemnoIZqGp4BcLqnqKimqipkpJra6Kqwxv8qa1mtdjrrrbjm2lStp+rq66/AxlQrBE1UGuyxyCYLkpVNQPBAqTkQa6yy1FZr7UPMQpADtNJ6eu234Aab7bYBRFvDtOGmqy6uVtagLbfnervuvPR+2u675UIQb7389pvpveRGSwO6/hZssJ9W0oCvwAQf7PDDZya8MAQDywvxxRgXKXHAFDec8ccg47gxtxWHbPLJMo6cb8kot+yyiCozbPHLNNesX8wdz2zzzjx7h/PAGvQs9NDgaaCAwhwDTfTSTDNnNNIkKxB001RXfdvT+BrQ8dRWd+31aFgbUKrWSn9t9tmPhT321mi37fZeagegNRNSv2333WYZzQQEYsv/DQHdXOMt+OBP6c332EgwoUTghDfueFEaKMEEEn0bkPjij2euOVCRT1755YxvLvroJ3VOOeKKh0766qx3ZPrnqbcu++wavY465rTnrjtEtssN+u7AB49Q75YzwYHqwidPugYceI64B8crL33rzHtwuu/QIz/99oRXf73l2XMvfube952BCOGPr/7g1YuQQannp7/+/G+3/34A8UdP//5o2w8/+vrjnwC75j/8AVB7A0wgzwqYPwQq8IEvY+ABIUjBnhWQABOsoAZp1j4ClAqDTwjgBkdoMuY9QQQeDAAIRUjCFmLMhCj8oAhCOAEX2hBjE+DACVO4whre8IcHy+EO/2VIQyAa0V9CjKEKZ8gBHx7xietKIg+Z6EQoWvFbUiRiE6/IxWtlcYlPKEEVu0jGYE2gBENcogXEWMY2mrEEFlAiBtc4RjfaUVZnjCMPHUDHO/pxVnl0wB77+MdCqiqQg2SjIRcZKkR+kI+KZKQkL+VIFUKyjpPMpKEqSYBLavKTiOKkJ0FJyj+JkpClTCWdThlJVboSTazE5CtnOaVY0vKWXrIlLncZJU6aAJW8DKaQ8mgCHv6ylcJM5o2IaUxgKvOZL2LmB48pS2hac0PSVCE1r8nNEmWTANvspjg19E0T3GAM1RynOv0zgTHcoJgfPME507nOesKnnTc4AQ/lif9Oe/rzP/jUZzzn+c+C7ieg+ySoQRfaHoSWygX8pCdDJ7qcgLrgoRGlqEa7Y1GM3qAIK9ioSJ2zgiLk86IBgOhHQzrSlianpCf1KEhdStPdwPQEKFXpTGvKU9vcNKfy3GlPh3qan8qUpURN6miMmtKgIlWpUJUMUwvg1KhaNTI3LUCpqEoCoV71q34pKQlOoNUAFAAEXX0qWNeaF7GCoKxnJcEO1MrWutJlBTsgwVu3ita52vWvdcGrXuHaV7oC9rBfEexezVpYxDo2LIolrFwN+9jKLiWyfCXBEChr2c4aZQVDGGxmN+vZ0ioFtKJlrGY5a9rWygS1i40raV1L26D/wFays62tbmNy260uQLNd2K1wX9KF0OLEt5IYQnCHy1yVFFcSxzXrAnqg3OZa9yTF7UF0BULd5V73uyHJ7nanW13wmtcj4oUreb173vZiJL2+7UEI2Ove+k6kCyHQrnrhEIIf2Pe/E/lBCOAwXv76F8AIdoiACQxXNxg4wRBeyILd0OAHR/jCE65wfy+M4QFTeKtuoMCGOQxhAVPgw2YN8YhJjGATo7gqIj4wiwFs4rZs9QAxnnGLQ0ABG5sVxyvWcX1rXNYBAFnGQnZvjQdQKiPnOMlD5vEBmAwAJwcZyuZdMgCqjGMbIBnL4P2BDXo8gC072QYdAHN7OzDmKZu5/8tpVrN52UzmN1MAzXKec5vLzOU7xznP16Wzm/uMZ0AHes9vxkChDd1cNmNg0EZW9J8ZPVxHQ/oAkqZ0o23waD5HetGa3q2lPY1pUIe6tqNOtKlP7dpUcznTrNatqyM9g0nHurUdmEGnE13rW6Na15BmAQZ67etW65oFnhY2sYtt2lxjANlmVratmW1ZZ0O7ytKmdrOP7WkEDHva2nasszVjZm8vO9yVHXe3v43uzqq73Oxud7p1Te4qI0AM55b3YXMthnoXBt/g1ndd+e3ve+db4HYleLcBjnDEKrzcYphCwBv+1Q5Mod8Ln0IQKA7YIFy84BHfOMft6nGMl/sCGv8fOcmncIGCo1zkKl+rx1ve7ZfHnK0zd3nKbw7WnNd85zy/qs9PXgWYBz2qQagCzYlu9KMrNelLrzIKLlB0p1sV6r8x89SrbnWoYt3TW29613v69S0LIOxjf7rSUSAAs6M97UTFetsBEByqAwHuRAWC0qlj9gZcYAt3x3tPgbCFC/Cd7n4HvOAHX/jD113xi68p4Q0/98cHPvIunbzjE395zI9U85XnvOcz3/jQrwHyoxcp4dew+TUsofOppygQlsD6ylfgBa+PveqX8ALymP32ude9Rmffe9vjHvbCNyjxfU934CM/+f9cvvGDD/2FSv/3ZEhDC6rP0BakgQzMt07/9rfPfYN6H/y2H3/5zf/98FdA/ev/5/ndD//423P+6de+/f2Jf+wbgfz7t04tYATo93sf8H8BWE8D+AHu9wEqAIAJKE4toAIMaHsOCIERyE0TWIFmtwEXmIHjtIEq0oEfCILdJIKV54EPaIInSIEjSHcqiIEsqEwo2IERsIIzaE0TGAEv+CE3KIM5GEw72IMb8INBCE1DmIJGeIQ0qAI8qIQ4yITClIQ2GIVSyEtUCIM3qANXKEw64IREuIVdGExf+IQ26ANcOIa7pAM+YIZaiIZquIZtGIZwGIe3xIZuKAAGEAF1aIezhIcGUHl72Id+6EqAKIhQQIiFmEpsCAWB/2h2BpCIabiIqtSIj0h3kaiIlAhKloiImriJmtSJkCiJoMiIPuCInjiJpfhJooiJpLiKnHiKj1gJeviKsBiKsigACFGLV6CKtyhJOnAFqLiLBpAAVxAHv6hJcXAFCRCIxGiMyJiMk7SMzaiLtFiMxyiN08iMzniN0KiNkkSN3Sg33wiOiySOAYAQ5HgFVGCOi0QF3JiOlbCO7eiOhQSPzSiP5GgF9WiPfkQFVpCP6liM/OiPfwSQAjmPBNmPBulGCCk26pgBCVCQDWlHCPk+EXkGFFmRbQSQZ4CR85gBGsmQHNlFHgmS+HMGYPAFJdlGXwAGH6mPBKCSLNmSZPSSZ//gQeo4kytpkzcJkzo5jzPZBzXpk1f0BX2QkzIJAURplFyElBAQlCrElEXplE8ElVJJABBwCFVplUb0BYcQlUt5CHfglVB0B2GZlcRSlmZ5RHfQLGrZBGzZlkD0lmK5kzIgl3RpRG8pA1mZl0Kwl0AkBE3glzIJmIL5Q4RpmDspAk0QmIlpQ4QZQ41ZA5AZmS0kBDVAmUIpApaJmS6kmZy5RJ8JmiQkmlnpmZdpmhqEmjKpmqw5Qq65kw5QmrFZQZopSDLpAISwmrf5QEJACLpJm735m7gpnFnpAETgm8Y5QEJABMMplMrJnM3JP88ZnQGAA9NZncAJnTigj9pJBE7/wJ0K5ATeCZ7KOZ7kOUDm6QDfqY7hqZ7ryT/t+Z7zGJ/zKUD1iZ7imZ/0eZ7wiQb96Z/0Y55oYJ/ZiQY0IJ8Eqj5OQAMHCp4KaggNOj+GAKEIigMmQAMUWqHqc6EmkKEbCgMeqj4wQAMhqo8FYAIeQKIlKj4w4AEmoFXquKIt+qIwKqM0Oo826qI4Oj0xOqMqyqI++qPKE6Q7alYncKNGKj0xSlYquqRF2qTB86RJSlVMSqXCY6UqKgUeAAlamjyQ4AFScKVeqgBhKjwKQKZm6gFomqbAs6Zl2qVuCqdxyqZ0+qZ2mjtyaqZYoKd7OjsKgAVzWqMg8KeByqdYsFc1/7oAiJqogooFx9WojwqprTOok8qjjgqolko6mHqljqoEndo6SiCpoGoBojqqq6MEFpCpAdAGC4CqqrqqrdoG+jgAsXoEs0o6R9CqTKaOuMoHurqronMEfLAAvzqPwTqsxKo5xoqst7oAwtqsm/OsyRoAA5ACJMCs1Oo4R0ACKXCt2bqt3Zo53xqut6qt3Fqug3Ou4qqu7Oqt4Pqu5BqvhOOu6Vqv9io4+AqsKcAG67qvb3MEbICu/qoFHCCwgsMBWmCwynoACKuweMOwU3arEJuwEms3FCuuF5uxGqsFFQusHeuxbrOxFhuxJNs2JiuyKJuyZ7OyD9sDJeCyaFMCPf8QsjE7szRrNjaLs9h6ADK7szx7s+LKAmFQBEL7NUUQBsh2q0ZbBknrNWXAtEUbBlAbtVYztU0LrE+LtVlLtfLIAAPQtV5LNVo7AAyAEGJLtmXLNGebtpUgtghgtW3bNFOrGXArtxSwA3XLNDtAAXirtoWxt327NH8buHE7uHxbuENzuGgruAhAuIwrNI6bt4o7uZQLuI+buJG7uJi7M5WrtgLQuZ/LM4crAHkrAHkguaVbM3+bB6gruqvrua37Mq8bu3Gruqxbuy5zu6nbALvLuyjzt9TxuxQwBML7MkNAAcUrug2AAcibvC0zBBjQvLn7vCEgvS0TAtWLuwwQHBj/kL3aezLca73fi73jS77d+7vhm74mU77eC77i674fA7+/KwfzS78YEwJyYL7Bgb/6W7/9G78NAMABvL8DfL/5e8AOw7/+63cLzMAGEwKU97sXEMES7C8U/MAXYAMZ/DA2UMHO28Ef7DAh/MCC4MElbDA2IAj+WwEpvMIsLAjkkboVsAaAIMMFAwhrUMOie8M5rMP9wsM+nLtALMRD3MPxe8MzgMT8MgNKbMMv0MROTC8zUHypOwJTXMVW/AIEksVbzMXrcsVfLLpaXAdivC514MW4S3dnnMbqssYEAgAI4cYvgMZwHC5y3HZ1XB93nMd6zMZ0XAl2jMeAfC17PMhu//wBhXDI31IIHzDHfTwCjOzI1wLJkkzI9fEBS2DJ1rIEkczHmkzJnezJ1ALKmbzIpWzKyYLKoqzKrKwsrqzIm+wFsZwsXhDKtOyBtnzLx5LLI9jHvOzLv/wBwazJG7AHvUzMv+IFe3DMMKjMzAwszgzNPrjM05wrXmCGwhwB2JzNt7LN1vwAEWAG4KwrZhABeULL5GzO54wr6bzOfdzO7wzP6vzKi1LO9Xwr8YzP9LzPstLP7KzPAB0rAj3PEWAEBR0rRnDPA63QC70qDS3PmkzOEB3RqTLRr8wpCY3RqjLRAaDIHH3RHh0qIC3SFl3SqHLSdUyOJK3SmWIE+SjSxf/40jB9KTItNjSdACpw06CiAjPd0sXY0z6dKUCt00LN00Vt1EFNyORI1EttKUcd0kkN1VENKVO901Z91Y6S1UIdBYrA1ZGiCFGA1E5tAGAt1pBC1mYNAHITBXOg1o8yB2VN1WcNAXEt14gyB4dD03it13vd10L914BtKHzd1vgjA2BQ2IYCBjLwPiKdAYrN2IXi2JDd0gQw2ZT9J47tQSKd2Yu92X7S2Xbt1pnNA6LtJzxgmJ8tA6id2nay2p6N2a4N27HN2rT92rY9J7Jd2ipU27vN27jt1ASAB7od3GnCA3gw28SNB4GA3GsSCMvt25303NCdJoGgm5/tANZ93Wf/kt3MbdoOEAPejSYxoN2YPd7lfSbnHd6WRN7rDSbtTd3qHd9fMt+fjQY1YN9fUgNo4N4EoN/87SX+DeACPuBUUuDU/Qb7jeBTUgNv4N4uwOAO/uBvcFEiPeENXuFQAuEY3tIazuFR4uG+HeIibiQkLtIruuEnPiQ1IKQqfgJE0OJFQgRQGuMzTuNDYuNaheM6vuM33tJUleM/riM87ttUpQdFviN6EOROfVZKvuQ5ogd7peIgEOVSfiNU3uNCfuVZjiNbjuQg4AFffiMeUOVdTuZlHiNnzuVPPuZrzuZo/uQLoOZx7iIecFwqvgCIcOcvggh6LuR87ucuAuhu7tYC/4EFhH4ipurbsKroi14ikmqrIg2rFhDpJVKrdj2Plo7pJKLpCvGqserpIwLqCREAWZACl07qG2IBKZAF8qiOqb7qrJ4hrg7roT7rta4htx7r8/gWtL7rFmIBg+HrqH4AwS7sDULsuH7qb0EHyn4hdFDsuX4A0B7tDjLtzS6y147tDDLtycrt3t4g4G7sRtbt454g5a4QjTAAXHAD6b4gN8AFA9AIClFl7x7vCjLvZXbv7k4C+p4gJEDvg1zH/x7w/zHw/Z4Q+A7wCN8fCl/whHzwD88fEe/vXODwFa8fF8/whcEGG78fbEBu/o4AIB/y8DHyC2/wJo/yKU/yHt/yLv/vHiov8fbWAzPvHj0A8yyP8znPHju/8hOPAD7/8+oR9DZfGEVv9N+B9PeuBkTP9EePAGpg81C/9FLPHTtf9U+PAo6Q9d/hCCjA9QyvBihAAWDvHRQw9lZ/9mnfHWtP9nVs9mj/9tsR9zZ/dnVv986x9qLcx27P933PdnnfAJMg+M4xCXx37+CL+M3RvYWPAY7PHJDP+M87+ctR+Qzf+JifHJrfx5ff+cjx+ZrcAIMg+sgxCIu/+aaP+seh+n9f+nLg+rsxwIV/AbSvG5R3+7mfG7vP+BWA+71/Gxfge8Av/MNfG8Uf+82H/MmfGsuf9xVgB89fG3Zg/Js//dVPG9f/z/zWQf3bjxrdL/3gH/6mMf7A/wLmfxrFl/davP6mIciM//7wTxryv/n0X/+icf+TDBAvKg0kWNDgQYQJFS5k2NDhQ4gRJU6kWNHiRYwZNW7k2NHjR5AhRY4kWdLkSZQpVa5kWfDFCAEACgIQMEJgS5w5de7k2dPnT6BBhQ4lWtToUaQuYcokSHOEn6RRpU6lWtXqVaxZtW7lStXP0pk1oXYlW9bsWbRp1a5l2/bq15hhn7qlW9fuXbx59e7lixMu04E0F33oW9jwYcSJFS9m3PPDorhNBQxuXNnyZcyZNW9W+zhyYAEPCHMmXdr0adSpVUv88OBzJZqiV8+mXdv2/23cnV0Dhh16dG7gwYUPJ14cZOvXsX8bZ97c+XPos5HzVh7d+nXs2bXbnR5W9nbw4cWPJ/+zu+Tv5dWvZ9/ePcTzoB/seV/f/n382ffs9h4h/38AAxRQtQj4Q8+/ARNUcEEG9yowudAQbHBCCiu00KoHqYvwQg479PBDnDLsD0QSSzTxxIpElMwACVF08UUYSYzAAAgNSCRGHHPUccFEaNTQxh2DFHJI9npMLgADEiBySSabhC4BAwKgLoAMlHTySiyzpC2BDKSciUortRRzTDIr49LLpsAsc00228zrzCmrdHNOOuskC84vM4jCTj779POoKLqMc88/CzX0UJYCRf8zMCoJRfRRSCPdSNFBJbX0UkwbojRPRzP19FNJN01TT1BLNdVQURnNAIJTW3V1TggEzZPVV2u1NctYF4WNSlpv9fXXIHONs1dgizX2RGHzlOFYZpv1UAZZR13WWWqrXRBaXQEIgIBprfX22/tkICDbbbsF91x0yROXXG7Tdfdd7dadsl1467WXOXm/JACPe/v1Nzc8xp3SBX7/Nfhg1PBwgVwXHED4YYgzc2DhgR2O+GKMEZuYYYsz9vjjuzauGGSSS15L5C8bNnlllrlCOU2VW5Z5ZqleZhSHjmnWeWegHMCBXJx5FnponXwGOmeik1Z6JKOnxMGEpaOW2iMTfnb/Guqps9aaoqqBxnprsMNWqOspC/habLTRNqEAcs1O+22x1277bLjrjlrusum2e++h8f7Sbb4D75vtvAU3fGe/0yxAisMbl1kKwv9m3HHKS4a87ckr1zzjy8sGYXPQLwYhcsU/D/30g0dv23TUW79X9SkHYN112t0FYQByZa9993Rvz3123oOn1vfYgRf+eGOJ/3KABZB3/tgFcI+9+eer9zX63Km3fntXsZ+ee/BP9X557cM3H9Px02T+fPYvTZ/R9duX/9H3d41/fvz/rF/b+/P3v879BaB//yMgmwI4wAImUEwHLJ8CHYglBj5QghCUHvkmeEEmHTAFGOSgkFJQ/0H1bbCDI8TRB3MnQhKmEEUmjB0KVfhCELFweS6EYQ0vJMMQ2lCHNwQh/Gi4QyAmCIc+DGIRFTRE+/3QiEu0DxL5p0QmRpE9ThTgAaR4xfccoIf2syIWvageLeaui18kY3jCGLsxllGN2Dnj8tK4Rjg+p43qe2Mc7VicOcKvjnfkI3DyyMU+BlI4f+TfHgV5SNUQsoqIZCRtFDkAQzZSkpp5ZCQnecnKPJIFmOSkZliwRf5tspOjrMwncydKUqYyMaaMHSpV+cq+sHImABiAK2F5S7x8EgDUoaUtcflLt+iSl7UEZjHpIsxZEtOYy1QLMpvSS2ZG8yzODAw0pXlNrqpQEza0RAA2vZkVBAxgl8ns5jfNSZVwjvOZAyjnOd2JlHQOs53vpOdQ4knOeuZTKPdc5zz1+U+d8LOa7ARoQQMqTnkaVKEsEeg2CbpQiJ6kobt8aEQtKpKJ0hIFF+UoSFCA0GRutKMj3chH1TlQkZJUpRYx6TBTulKYRqSlIY1pTSEy03W+1KY7RQhOqykAnfJUqANBQUx4CdShJpUgRT3pNpGq1KQylSkBAQA7',
            'type'      => 'image/gif'
        ),
        'bkg_middle2.gif'   => array(
            'base64'       => 'R0lGODlhAQCBAdUAAPb4+eLp6/7+/eHp6/f5+v39/fn6+/z9/Pj6+vv8/Pr7++Pq7OTr7fP29+Lp7O3y8/T3+O7y9Oft7/X4+Oju8PL19u3x8/H19uLq7OXs7vD09erw8e/z9ebs7uvx8uzx8u/z9Ovw8urv8enu8OPq7ePp7Ofu7+Pp6+nv8eTq7OTq7eXr7uju7+bt7uvw8env8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAAAAAAALAAAAAABAIEBAAaZQEZqUVo4TgFHYMkcBJzQ5mBKpT6XzqVSiXEsMNpAd0Euq0iMtJqxyrg7rU5HQpewTJT8iIJ6iUQbgSEhLh4eHx8PDxaMig8RkBEgIByVGpcXmRWbFQ2enw0QohATpRMAqKmqq6ytrq+wsbKztLW2qAS5uru8BAi/wMEIBsTFxgYKycrLCc3OzwfR0tMHBdbX2NgC29zd3ttBADs=',
            'type'      => 'image/gif'
        ),
        'favicon.ico'   => array(
            'base64'       => 'AAABAAEAEBAAAAEAIABoBAAAFgAAACgAAAAQAAAAIAAAAAEAIAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAD///8A////AP///wD///8A////ANDa+kqEk/WXLUPv/zpY8f+Rp/au2eD7PP///wD///8A////AP///wD///8A////AP///wD///8A+/z9IqW2+IFBYPD/Kj7v/1d49P9IafL/JSzu/1x78+rl7Ptl+vv9DP///wD///8A////AP///wD///8Ax8/6Rv7+/b2ov/n/JBzt/z9e8f/r8v//tsv8/yQc7f8pOu//n7n6/9Tg+5Pb3/sq////AP///wD///8Ai5T1iUli8eX/////mrX6/yQe7f9AX/H/7vT//7PJ+/8kHO3/LkPv/6a++/+uxPv9Wmnyxamv92T///8A////ACg47v8yTfD//////5q1+v8kHu3/P17x/+rx//+xx/v/JBzt/y5D7/+nv/v/rcP77Sc27v9MWfDT////AP///wApOe79M07w//////+atfr/JB7t/z9e8f/q8f//scf7/yQc7f8uQ+//pr77/6/F+/ApO+//VGDxyf///wD///8AKTnu/TNO8P//////mrX6/yQe7f8/XvH/6vH//7HH+/8kHO3/LkPv/6a++/+wxvv1Kj3v/1Zi8cf///8A////ACk57v0zTvD//////5q1+v8kHO3/PFvx/+zy//+yx/v/JBzt/y1C7/+mvvv/ssf79ys/7/9WYvHH////AP///wApOe79M07w//////+Ys/n/Jiru/1Vy8//u8///vM78/y457/8wRu//n7n6/7PJ+/gsQe//WGLxxf///wD///8AKTnu/TJM8P//////rMH7/zVG7/9dePP/7vT//8DS/P80Qu//RmHx/7/R/P+yx/v6LUPv/1hi8cX///8A////ACg47v05VPD/6O/+//n7//+iufr/bYn1/+Ts/v+6zfz/VnHz/8fW/f//////pbz6/S0/7/9VX/HH////AP///wA+V/H/SGHx/2F99P+rwPv//////+fu/v/4+f//8PX//+bt/v/09///jqf4/1Rv8/9FXfH/ZHfyyf///wD///8Awsr5VGR48ttIYfH/UWzy/3GN9v/O3f3///////////+0yPv/Yn70/0tk8v9IYfH/don0wtfc+zP///8A////APz8/QHt7/wYoK33hUli8f9KYvH/WHPz/36Z9/9+mff/TGXy/0li8f9bcfLlu8T5XvL0/Q////8A////AP///wD///8A////APn6/Qbc4Pswf5D0tUpi8f9MZfL/TGXy/01l8fiZp/aO6+78Gfz8/QH///8A////AP///wD///8A////AP///wD///8A////APb3/Qq/yPlXYHXy4GyA88/W2/s4+/v9A////wD///8A////AP///wD///8A/D8AAPAfAADgBwAAgAMAAIABAACAAQAAgAEAAIABAACAAQAAgAEAAIABAACAAQAAwAMAAOAPAAD4HwAA/n8AAA==',
            'type'      => 'image/icon'
        )
    );

    /**
     * Print Header HTML
     *
     * @param string $title
     */
    public function printHtmlHeader()
    {
        echo <<<HEADER
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Magento Database Repair Tool</title>
<link rel="icon" href="{$this->getimagesrc('favicon.ico')}" type="image/x-icon" />
<link rel="shortcut icon" href="{$this->getimagesrc('favicon.ico')}" type="image/x-icon" />
<style type="text/css">
* { margin:0; padding:0; }
body { background:#496778; font:12px/1.5 Arial, Helvetica, sans-serif; color:#2f2f2f; }

a { color:#1e7ec8; text-decoration:underline; }
a:hover { color:#1e7ec8; text-decoration:underline; }
:focus { outline:0; }

img { border:0; }

h1,h2,h3,h4,h5,h6 { fort-size:1em; font-weight:normal; line-height:1.25; margin-bottom:.45em; color:#0a263c; }
.page-head { margin:0 0 25px 0; border-bottom:1px solid #ccc; }
.page-head h2 { margin:0; font-size:1.75em; }

form { display:inline; }
fieldset { border:none; }
legend { display:none; }
label { color:#666; font-weight:bold; }
input,select,textarea,button { vertical-align:middle; font:12px Arial, Helvetica, sans-serif; }
input.input-text,select,textarea { display:block; margin-top:3px; width:382px; border:1px solid #b6b6b6; font:12px Arial, Helvetica, sans-serif; }
input.input-text,textarea { padding:2px; }
select { padding:1px; }
button::-moz-focus-inner { padding:0; border:0; }
button.button { display:inline-block; border:0; _height:1%; overflow:visible; background:transparent; cursor:pointer; }
button.button span { float:left; border:1px solid #de5400; background:#f18200; padding:3px 8px; font-weight:bold; color:#fff; text-align:center; white-space:nowrap; position:relative; }
.input-box { margin-bottom:10px; }
.validation-failed { border:1px dashed #EB340A !important; background:#faebe7 !important; }
.button-set { clear:both; border-top:1px solid #e4e4e4; margin-top:4em; padding-top:8px; text-align:right; }
.required { color:#eb340a; }
p.required { margin-bottom:10px; }

.messages { width:100%; overflow:hidden; margin-bottom:10px; }
.msg_error { list-style:none; border:1px solid #f16048; padding:5px; padding-left:8px; background:#faebe7; }
.msg_error li { color:#df280a; font-weight:bold; padding:5px; background:url({$this->getimagesrc('error.gif')}) 0 50% no-repeat; padding-left:24px; }
.msg_success { list-style:none; border:1px solid #3d6611; padding:5px; padding-left:8px; background:#eff5ea; }
.msg_success li { color:#3d6611; font-weight:bold; padding:5px; background:url( {$this->getimagesrc('success.gif')} ) 0 50% no-repeat; padding-left:24px; }
.msg-note { color:#3d6611 !important; font-weight:bold; padding:10px 10px 10px 29px !important; border:1px solid #fcd344 !important; background:#fafaec url( {$this->getimagesrc('note.gif')} ) 5px 50% no-repeat; }

.header-container { border-bottom:1px solid #415966; background:url( {$this->getimagesrc('bkg_header.jpg')} ) 50% 0 repeat-x; }
.header { width:910px; margin:0 auto; padding:15px 10px 25px; text-align:left; }
.header h1 { font-size:0; line-height:0; }

.middle-container { background:#fbfaf6 url( {$this->getimagesrc('bkg_middle.gif')} ) 50% 0 no-repeat; }
.middle { width:900px; height:400px; margin:0 auto; background:#fffffe url( {$this->getimagesrc('bkg_middle2.gif')} ) 0 0 repeat-x; padding:25px 25px 80px 25px; text-align:left;}
.middle[class] { height:auto; min-height:400px; }

.fieldset { background:#fbfaf6; border:1px solid #bbafa0; margin:28px 0; padding:22px 25px 12px; }
.fieldset .legend { background:#f9f3e3; border:1px solid #f19900; color:#e76200; float:left; font-size:1.1em; font-weight:bold; margin-top:-33px; padding:0 8px; position:relative; }
.corrupted { float:left; }
.reference { float:right; }
.corrupted,
.reference { width:440px; }
.corrupted .fieldset .legend {  border-color:#f16048; background:#faebe7; color:#df280a; }
.reference .fieldset .legend { border-color:#3d6611; background:#eff5ea; color:#3d6611; }

.footer-container { border-top:15px solid #b6d1e2; }
.footer { width:930px; margin:0 auto; padding:10px 10px 4em; }
.footer .legality { padding:13px 0; color:#ecf3f6; text-align:center; }
.footer .legality a,
.footer .legality a:hover { color:#ecf3f6; }
</style>
</head>
<body>
<div class="header-container">
    <div class="header">
        <h1 title="Magento Database Repair Tool"><img src="{$this->getImageSrc('logo.gif')}" alt="Magento Database Repair Tool" /></h1>
    </div>
</div>
HEADER;
    }

    /**
     * Print Footer HTML
     */
    public function printHtmlFooter()
    {
        $date = gmdate('Y');
        echo <<<FOOTER
<div class="footer-container">
    <div class="footer">
        <p class="legality">Magento is a trademark of Irubin Consulting Inc. DBA Varien. Copyright © {$date} Irubin Consulting Inc.</p>
    </div>
</div>
</body>
</html>
FOOTER;
    }

    /**
     * Print HTML form header
     * @param string $action
     */
    public function printHtmlFormHead()
    {
        echo <<<FORM
<form action="{$_SERVER['PHP_SELF']}" method="post" enctype="multipart/form-data" name="frm_db_repair" id="frm_db_repair">
FORM;
    }

    /**
     * Print HTML form footer
     */
    public function printHtmlFormFoot()
    {
        echo <<<FORM
</form>
FORM;
    }

    /**
     * Print javascript fragment on configuration step
     */
    public function printJsConfiguration()
    {
        echo <<<JAVASCRIPT
<script type="text/javascript">
//<![CDATA[
var classTools = {
    has: function(objElement, strClass){
        if (objElement.className) {
            var arrList = objElement.className.split(' ');
            var strClassUpper = strClass.toUpperCase();
            for (var i=0; i<arrList.length; i++) {
                if (arrList[i].toUpperCase() == strClassUpper) {
                    return true;
                }
            }
        }
        return false;
    },
    add: function(objElement, strClass)
    {
        if (objElement.className) {
            var arrList = objElement.className.split(' ');
            var strClassUpper = strClass.toUpperCase();
            for (var i=0; i<arrList.length; i++) {
                if (arrList[i].toUpperCase() == strClassUpper) {
                    arrList.splice(i, 1);
                    i--;
                }
            }
            arrList[arrList.length] = strClass;
            objElement.className = arrList.join(' ');
        }
        else {
            objElement.className = strClass;
        }
    },
    remove: function(objElement, strClass) {
        if (objElement.className) {
            var arrList = objElement.className.split(' ');
            var strClassUpper = strClass.toUpperCase();
            for (var i=0; i<arrList.length; i++) {
                if (arrList[i].toUpperCase() == strClassUpper) {
                    arrList.splice(i, 1);
                    i--;
                }
            }
            objElement.className = arrList.join(' ');
        }
    }
};
function repairContinue()
{
    var isErrors = false;
    var inputs = document.getElementsByTagName('input');
    for(var i=0; i<inputs.length; i++) {
        if (classTools.has(inputs[i], 'check_required')) {
            if (inputs[i].value.length > 0) {
                classTools.remove(inputs[i], 'validation-failed');
                // ex remove tooltip with error if exists
            } else {
                classTools.add(inputs[i], 'validation-failed');
                // ex add tooltip with error
                isErrors = true;
            }
        }
    }
    if (!isErrors) {
        document.getElementById('button-continue').disabled = true;
        document.getElementById('frm_db_repair').submit();
        return false;
    }
    return false;
}
//]]>
</script>
JAVASCRIPT;
    }

    /**
     * Print HTML container header fragment
     */
    public function printHtmlContainerHead()
    {
        echo <<<HTML
<div class="middle-container">
    <div class="middle">
HTML;
    }

    /**
     * Print HTML container footer fragment
     */
    public function printHtmlContainerFoot()
    {
        echo <<<HTML
    </div>
</div>
HTML;
    }

    /**
     * Print javascript fragment on confirmation step
     */
    public function printJsConfirmation()
    {
        echo <<<JAVASCRIPT
<script type="text/javascript">
function repairContinue()
{
    document.getElementById('button-continue').disabled = true;
    document.getElementById('frm_db_repair').submit();
    return false;
}
</script>
JAVASCRIPT;
    }

    /**
     * Print messages block
     *
     * @param array|string $messages
     * @param string $type
     */
    public function printHtmlMessage($messages, $type = 'error')
    {
        if (!is_array($messages)) {
            $messages = array($messages);
        }
        echo <<<HTML
<div class="messages">
    <ul class="msg_{$type}">
HTML;
        foreach ($messages as $message) {
            $message = htmlspecialchars($message);
            echo <<<HTML
        <li>{$message}</li>
HTML;
        }
        echo <<<HTML
    </ul>
</div>
HTML;
    }

    /**
     * Print Page head block
     *
     * @param string $title
     */
    public function printHtmlPageHead($title)
    {
        $title = htmlspecialchars($title);
        echo <<<HTML
<div class="page-head">
    <h2>{$title}</h2>
</div>
HTML;
    }

    /**
     * Print configuration block
     */
    public function printHtmlConfigurationBlock()
    {
        echo <<<HTML
<div class="corrupted">
    <fieldset class="fieldset">
        <legend>Corrupted Database Connection</legend>
        <div class="legend">Corrupted Database Connection</div>
        <div class="input-box">
            <label for="corrupted_hostname">Host <span class="required">*</span></label><br />
            <input value="{$this->getPost('corrupted/hostname')}" type="text" name="corrupted[hostname]" id="corrupted_hostname" class="check_required input-text" />
        </div>
        <div class="input-box">
            <label for="corrupted_database">Database Name <span class="required">*</span></label><br />
            <input value="{$this->getPost('corrupted/database')}" type="text" name="corrupted[database]" id="corrupted_database" class="check_required input-text" />
        </div>
        <div class="input-box">
            <label for="corrupted_username">User Name<span class="required">*</span></label><br />
            <input value="{$this->getPost('corrupted/username')}" type="text" name="corrupted[username]" id="corrupted_username" class="check_required input-text" />
        </div>
        <div class="input-box">
            <label for="corrupted_password">User Password </label><br />
            <input value="{$this->getPost('corrupted/password')}" type="password" name="corrupted[password]" id="corrupted_password" class="input-text" />
        </div>
        <div class="input-box">
            <label for="corrupted_prefix">Tables Prefix</label><br />
            <input value="{$this->getPost('corrupted/prefix')}" type="text" name="corrupted[prefix]" id="corrupted_prefix" class="input-text" />
        </div>
    </fieldset>
</div>
<div class="reference">
    <fieldset class="fieldset">
        <legend>Reference Database Connection</legend>
        <div class="legend">Reference Database Connection</div>

        <div class="input-box">
            <label for="reference_hostname">Host <span class="required">*</span></label><br />
            <input value="{$this->getPost('reference/hostname')}" type="text" name="reference[hostname]" id="reference_hostname" class="check_required input-text" />
        </div>
        <div class="input-box">
            <label for="reference_database">Database Name <span class="required">*</span></label><br />
            <input value="{$this->getPost('reference/database')}" type="text" name="reference[database]" id="reference_database" class="check_required input-text" />
        </div>
        <div class="input-box">
            <label for="reference_username">User Name<span class="required">*</span></label><br />
            <input value="{$this->getPost('reference/username')}" type="text" name="reference[username]" id="reference_username" class="check_required input-text" />
        </div>
        <div class="input-box">
            <label for="reference_password">User Password </label><br />
            <input value="{$this->getPost('reference/password')}" type="password" name="reference[password]" id="reference_password" class="input-text input-text" />
        </div>
        <div class="msg-note">
            <p>Reference database should contain tables prefix same as on the corrupted database</p>
        </div>
    </fieldset>
</div>
HTML;
    }

    public function printHtmlButtonSet($withRequired = false)
    {
        echo <<<HTML
<div class="button-set">
HTML;
        if ($withRequired) {
            echo <<<HTML
    <p class="required">* Required Fields</p>
HTML;
        }
        echo <<<HTML
    <button id="button-continue" class="button" type="submit" onclick="return repairContinue();"><span>Continue</span></button>
</div>
HTML;
    }

    /**
     * Print HTML Fieldset header fragment
     *
     * @param string $legend
     */
    public function printHtmlFieldsetHead($legend)
    {
        $legend = htmlspecialchars($legend);
        echo <<<HTML
<fieldset class="fieldset">
    <legend>{$legend}</legend>
    <div class="legend">{$legend}</div>
HTML;
    }

    /**
     * Print HTML Fieldset footer fragment
     */
    public function printHtmlFieldsetFoot()
    {
        echo <<<HTML
</fieldset>
HTML;
    }

    /**
     * Print HTML list of events
     *
     * @param array $list
     * @param string $class the class for ul
     */
    public function printHtmlList(array $list, $class = null)
    {
        $classFragment = null;
        if ($class) {
            $classFragment = " class=\"{$class}\"";
        }
        echo "<ul{$classFragment}>";
        foreach ($list as $li) {
            $li = htmlspecialchars($li);
            echo "<li>{$li}</li>";
        }
        echo "</ul>";
    }

    /**
     * Print note
     *
     * @param string $text
     */
    public function printHtmlNote($text)
    {
        $text = str_replace("\n", "<br />", htmlspecialchars($text));
        echo <<<HTML
<p class="msg-note">{$text}</p>
HTML;
    }

    /**
     * Print hidden form field
     */
    public function printHtmlFormHidden()
    {
        echo <<<HTML
        <input type="hidden" name="post_form" value="true" />
HTML;
    }

    /**
     * Retrieve POST data
     *
     * @param string $key
     * @param mixed $default
     * @return mixed
     */
    public function getPost($key = null, $default = null)
    {
        if (is_null($key)) {
            return $_POST;
        }
        if (strpos($key, '/') !== false) {
            $keyArr = explode('/', $key);
            $data = $_POST;
            foreach ($keyArr as $i => $k) {
                if ($k === '') {
                    return $default;
                }
                if (is_array($data)) {
                    if (!isset($data[$k])) {
                        return $default;
                    }
                    $data = $data[$k];
                } else {
                    return $default;
                }
            }
            return $data;
        }
        if (isset($_POST[$key])) {
            return $_POST[$key];
        }
        return $default;
    }

    /**
     * Check if form is submitted
     *
     * @return bool
     */
    public function isPost()
    {
        return $this->getPost('post_form') !== null;
    }

    /**
     * Print image content
     *
     * @param string $img
     */
    public function printImageContent($img)
    {
        if (isset($this->_images[$img])) {
            $imgProp = $this->_images[$img];
            header('Content-Type: ' . $imgProp['type']);
            echo base64_decode($imgProp['base64']);
        }
        else {
            header('HTTP/1.0 404 Not Found');
        }
    }

    /**
     * Retrieve Image URL for SRC
     *
     * @param string $image
     * @return string
     */
    public function getImageSrc($image)
    {
        return "{$_SERVER['PHP_SELF']}?img={$image}";
    }
}

class Tools_Db_Repair_Action
{
    /**
     * Helper object
     *
     * @var Tools_Db_Repair_Helper
     */
    protected $_helper;

    /**
     * Repair Database Tool object
     *
     * @var Tools_Db_Repair_Mysql4
     */
    protected $_resource;

    /**
     * Session array
     *
     * @var array
     */
    protected $_session;

    /**
     * Init class
     */
    public function __construct()
    {
        session_name('mage_db_repair');
        session_start();

        $this->_helper   = new Tools_Db_Repair_Helper();
        $this->_resource = new Tools_Db_Repair_Mysql4();
        $this->_session = &$_SESSION;

        if (!isset($this->_session['step'])) {
            $this->_session['step'] = 1;
        }
    }

    /**
     * Show Configuration Page
     *
     * @return Tools_Db_Repair_Action
     */
    public function configAction()
    {
        $this->_helper->printHtmlHeader();
        $this->_helper->printHtmlFormHead();
        $this->_helper->printHtmlFormHidden();
        $this->_helper->printJsConfiguration();
        $this->_helper->printHtmlContainerHead();
        $this->_helper->printHtmlPageHead('Configuration');

        if (isset($this->_session['errors'])) {
            $this->_helper->printHtmlMessage($this->_session['errors'], 'error');
            unset($this->_session['errors']);
        }

        $this->_helper->printHtmlConfigurationBlock();
        $this->_helper->printHtmlButtonSet(true);

        $this->_helper->printHtmlContainerFoot();
        $this->_helper->printHtmlFormFoot();
        $this->_helper->printHtmlFooter();

        return $this;
    }

    /**
     * Show Confirmation Page
     *
     * @return Tools_Db_Repair_Action
     */
    public function confirmAction($compare = array())
    {
        if (!$compare) {
            $compare = $this->_resource->compareResource();
        }

        $this->_helper->printHtmlHeader();
        $this->_helper->printHtmlFormHead();
        $this->_helper->printHtmlFormHidden();
        $this->_helper->printJsConfirmation();

        $this->_helper->printHtmlContainerHead();
        $this->_helper->printHtmlPageHead('Confirmation');
        $this->_helper->printHtmlNote('Some modules have different versions in corrupted and reference databases. Are you sure you want to continue?');
        $this->_helper->printHtmlFieldsetHead('Module versions differences');
        $this->_helper->printHtmlList($compare);
        $this->_helper->printHtmlFieldsetFoot();
        $this->_helper->printHtmlButtonSet(false);
        $this->_helper->printHtmlContainerFoot();

        $this->_helper->printHtmlFormFoot();
        $this->_helper->printHtmlFooter();

        return $this;
    }

    /**
     * Show Repair Database Page
     *
     * @return Tools_Db_Repair_Action
     */
    public function repairAction()
    {
        $actionList = array(
            'charset'    => array(),
            'engine'     => array(),
            'column'     => array(),
            'index'      => array(),
            'table'      => array(),
            'invalid_fk' => array(),
            'constraint' => array()
        );

        $referenceTables = $this->_resource->getTables(Tools_Db_Repair_Mysql4::TYPE_REFERENCE);
        $corruptedTables = $this->_resource->getTables(Tools_Db_Repair_Mysql4::TYPE_CORRUPTED);

        // collect action list
        foreach ($referenceTables as $table => $tableProp) {
            if (!isset($corruptedTables[$table])) {
                $actionList['table'][] = array(
                    'msg'   => sprintf('Add missing table "%s"', $table),
                    'sql'   => $tableProp['create_sql']
                );
            }
            else {
                // check charset
                if ($tableProp['charset'] != $corruptedTables[$table]['charset']) {
                    $actionList['charset'][] = array(
                        'msg'     => sprintf('Change charset on table "%s" from %s to %s',
                            $table,
                            $corruptedTables[$table]['charset'],
                            $tableProp['charset']
                        ),
                        'table'   => $table,
                        'charset' => $tableProp['charset'],
                        'collate' => $tableProp['collate']
                    );
                }

                // check storage
                if ($tableProp['engine'] != $corruptedTables[$table]['engine']) {
                    $actionList['engine'][] = array(
                        'msg'    => sprintf('Change storage engine type on table "%s" from %s to %s',
                            $table,
                            $corruptedTables[$table]['engine'],
                            $tableProp['engine']
                        ),
                        'table'  => $table,
                        'engine' => $tableProp['engine']
                    );
                }

                // validate columns
                $fieldList = array_diff_key($tableProp['fields'], $corruptedTables[$table]['fields']);
                if ($fieldList) {
                    $fieldActionList = array();
                    foreach ($fieldList as $fieldKey => $fieldProp) {
                        $afterField = $this->_resource->arrayPrevKey($tableProp['fields'], $fieldKey);
                        $fieldActionList[] = array(
                            'column'    => $fieldKey,
                            'config'    => $fieldProp,
                            'after'     => $afterField
                        );
                    }

                    $actionList['column'][] = array(
                        'msg'    => sprintf('Add missing field(s) "%s" to table "%s"',
                            join(', ', array_keys($fieldList)),
                            $table
                        ),
                        'table'  => $table,
                        'action' => $fieldActionList
                    );
                }

                //validate indexes
                $keyList = array_diff_key($tableProp['keys'], $corruptedTables[$table]['keys']);
                if ($keyList) {
                    $keyActionList = array();
                    foreach ($keyList as $keyProp) {
                        $keyActionList[] = array(
                            'config' => $keyProp
                        );
                    }

                    $actionList['index'][] = array(
                        'msg'    => sprintf('Add missing index(es) "%s" to table "%s"',
                            join(', ', array_keys($keyList)),
                            $table
                        ),
                        'table'  => $table,
                        'action' => $keyActionList
                    );
                }

                foreach ($corruptedTables[$table]['constraints'] as $fk => $fkProp) {
                    if ($fkProp['ref_db']) {
                        $actionList['invalid_fk'][] = array(
                            'msg'    => sprintf('Remove invalid foreign key(s) "%s" from table "%s"',
                                join(', ', array_keys($constraintList)),
                                $table
                            ),
                            'table'      => $table,
                            'constraint' => $fkProp['fk_name']
                        );
                        unset($corruptedTables[$table]['constraints'][$fk]);
                    }
                }

                // validate foreign keys
                $constraintList = array_diff_key($tableProp['constraints'], $corruptedTables[$table]['constraints']);
                if ($constraintList) {
                    $constraintActionList = array();
                    foreach ($constraintList as $constraintConfig) {
                        $constraintActionList[] = array(
                            'config'    => $constraintConfig
                        );
                    }

                    $actionList['constraint'][] = array(
                        'msg'    => sprintf('Add missing foreign key(s) "%s" to table "%s"',
                            join(', ', array_keys($constraintList)),
                            $table
                        ),
                        'table'  => $table,
                        'action' => $constraintActionList
                    );
                }

                // validate triggers
                $triggersList = array_diff_key($tableProp['triggers'], $corruptedTables[$table]['triggers']);
                if ($triggersList) {
                    $triggerActionList = array();
                    foreach ($triggersList as $triggerConfig) {
                        $triggerActionList[] = array(
                            'config' => $triggerConfig
                        );
                    }

                    $actionList['trigger'][] = array(
                        'msg'    => sprintf('You have missed trigger(s) "%s" to table "%s"',
                            join(', ', array_keys($triggersList)),
                            $table
                        ),
                        'table'  => $table,
                        'action' => $triggerActionList
                    );
                }
            }
        }

        $error   = array();
        $success = array();

        $type = Tools_Db_Repair_Mysql4::TYPE_CORRUPTED;

        $this->_resource->start($type);

        foreach ($actionList['charset'] as $actionProp) {
            $this->_resource->begin($type);
            try {
                $this->_resource->changeTableCharset($actionProp['table'], $type, $actionProp['charset'], $actionProp['collate']);
                $this->_resource->commit($type);
                $success[] = $actionProp['msg'];
            }
            catch (Exception $e) {
                $this->_resource->rollback($type);
                $error[] = $e->getMessage();
            }
        }
        foreach ($actionList['engine'] as $actionProp) {
            $this->_resource->begin($type);
            try {
                $this->_resource->changeTableEngine($actionProp['table'], $type, $actionProp['engine']);
                $this->_resource->commit($type);
                $success[] = $actionProp['msg'];
            }
            catch (Exception $e) {
                $this->_resource->rollback($type);
                $error[] = $e->getMessage();
            }
        }

        foreach ($actionList['column'] as $actionProp) {
            $this->_resource->begin($type);
            try {
                foreach ($actionProp['action'] as $action) {
                    $this->_resource->addColumn($actionProp['table'], $action['column'], $action['config'], $type, $action['after']);
                }
                $this->_resource->commit($type);
                $success[] = $actionProp['msg'];
            }
            catch (Exception $e) {
                $this->_resource->rollback($type);
                $error[] = $e->getMessage();
            }
        }

        foreach ($actionList['index'] as $actionProp) {
            $this->_resource->begin($type);
            try {
                foreach ($actionProp['action'] as $action) {
                    $this->_resource->addKey($actionProp['table'], $action['config'], $type);
                }
                $this->_resource->commit($type);
                $success[] = $actionProp['msg'];
            }
            catch (Exception $e) {
                $this->_resource->rollback($type);
                $error[] = $e->getMessage();
            }
        }

        foreach ($actionList['table'] as $actionProp) {
            $this->_resource->begin($type);
            try {
                $this->_resource->sqlQuery($actionProp['sql'], $type);
                $this->_resource->commit($type);
                $success[] = $actionProp['msg'];
            }
            catch (Exception $e) {
                $this->_resource->rollback($type);
                $error[] = $e->getMessage();
            }
        }

        foreach ($actionList['invalid_fk'] as $actionProp) {
            $this->_resource->begin($type);
            try {
                $this->_resource->dropConstraint($actionProp['table'], $actionProp['constraint'], $type);
                $this->_resource->commit($type);
                $success[] = $actionProp['msg'];
            }
            catch (Exception $e) {
                $this->_resource->rollback($type);
                $error[] = $e->getMessage();
            }
        }

        foreach ($actionList['constraint'] as $actionProp) {
            $this->_resource->begin($type);
            try {
                foreach ($actionProp['action'] as $action) {
                    $this->_resource->addConstraint($action['config'], $type);
                }
                $this->_resource->commit($type);
                $success[] = $actionProp['msg'];
            }
            catch (Exception $e) {
                $this->_resource->rollback($type);
                $error[] = $e->getMessage();
            }
        }

        foreach ($actionList['trigger'] as $actionProp) {
            $error[] = $actionProp['msg'];
        }

        $this->_resource->finish($type);

        $this->_helper->printHtmlHeader();

        $this->_helper->printHtmlContainerHead();
        $this->_helper->printHtmlPageHead('Repair Corrupted Database');
        if (!$error) {
            $this->_helper->printHtmlMessage('Database repair finished successfully', 'success');
        } else {
            $this->_helper->printHtmlMessage($error, 'error');
        }
        if ($success) {
            $this->_helper->printHtmlFieldsetHead('Repair Log');
            $this->_helper->printHtmlList($success);
            $this->_helper->printHtmlFieldsetFoot();
        }
        elseif (!$error) {
            $this->_helper->printHtmlNote('Corrupted Database doesn\'t require any changes');
        }
        $this->_helper->printHtmlContainerFoot();

        $this->_helper->printHtmlFooter();

        $this->_session = array();

        return $this;
    }

    /**
     * Images
     *
     * @return Tools_Db_Repair_Action
     */
    public function imageAction()
    {
        $this->_helper->printImageContent($_GET['img']);

        return $this;
    }

    /**
     * Run action
     *
     * @return Tools_Db_Repair_Action
     */
    public function run()
    {
        if (isset($_GET['img'])) {
            return $this->imageAction();
        }

        if ($this->_session['step'] == 1) {
            if ($this->_helper->isPost()) {
                try {
                    $dbConfigurations = $this->_getConfig();
                    $this->_resource->setConnection($dbConfigurations['corrupted'], Tools_Db_Repair_Mysql4::TYPE_CORRUPTED);
                    $this->_resource->setConnection($dbConfigurations['reference'], Tools_Db_Repair_Mysql4::TYPE_REFERENCE);
                    if (!$this->_resource->checkInnodbSupport(Tools_Db_Repair_Mysql4::TYPE_CORRUPTED)) {
                        throw new Exception('Corrupted database doesn\'t support InnoDB storage engine');
                    }

                    $this->_session['db_config_corrupted'] = $dbConfigurations['corrupted'];
                    $this->_session['db_config_reference'] = $dbConfigurations['reference'];

                    $compare = $this->_resource->compareResource();

                    if ($compare) {
                        $this->_session['step'] = 2;
                        return $this->confirmAction();
                    }
                    else {
                        $this->_session['step'] = 3;
                        header('Location: ' . $_SERVER['PHP_SELF']);
                        return $this;
                    }
                }
                catch (Exception $e) {
                    $this->_session['errors'] = array($e->getMessage());
                    $this->configAction();
                    return $this;
                }
            }
            return $this->configAction();
        }
        elseif ($this->_session['step'] == 2) {
            try {
                $this->_resource->setConnection($this->_session['db_config_corrupted'], Tools_Db_Repair_Mysql4::TYPE_CORRUPTED);
                $this->_resource->setConnection($this->_session['db_config_reference'], Tools_Db_Repair_Mysql4::TYPE_REFERENCE);
            }
            catch (Exception $e) {
                $this->_session['step'] = 1;
                header('Location: ' . $_SERVER['PHP_SELF']);
                return $this;
            }
            if ($this->_helper->isPost()) {
                $this->_session['step'] = 3;
                header('Location: ' . $_SERVER['PHP_SELF']);
                return $this;
            }
            else {
                return $this->confirmAction();
            }
        }
        elseif ($this->_session['step'] == 3) {
            try {
                $this->_resource->setConnection($this->_session['db_config_corrupted'], Tools_Db_Repair_Mysql4::TYPE_CORRUPTED);
                $this->_resource->setConnection($this->_session['db_config_reference'], Tools_Db_Repair_Mysql4::TYPE_REFERENCE);
            }
            catch (Exception $e) {
                $this->_session['step'] = 1;
                header('Location: ' . $_SERVER['PHP_SELF']);
                return $this;
            }
            return $this->repairAction();
        }
        return $this;
    }

    /**
     * Return database configuration
     *
     * @return array
     */
    protected function _getConfig()
    {
        $config['corrupted'] = $this->_helper->getPost('corrupted', array());
        $config['reference'] = $this->_helper->getPost('reference', array());
        if (isset($config['corrupted']['prefix'])) {
            $config['reference']['prefix'] = $config['corrupted']['prefix'];
        }

        return $config;
    }
}

@set_time_limit(0);

$repairDb = new Tools_Db_Repair_Action();
$repairDb->run();
