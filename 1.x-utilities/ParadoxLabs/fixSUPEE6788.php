<?php
/**
 * This script attempts to find and automatically resolve major conflicts resulting
 * from the SUPEE-6788 patch.
 * 
 * WARNING: This script is destructive. When you apply the changes, it WILL overwrite
 * your existing files with those changes. Back up your site first.
 * 
 * We make no guarantee as to the correctness or completeness of this script.
 * We are not liable for any problems that occur as a result of running it.
 * 
 * This is not intended to be the end-all/be-all solution to fixing patch conflicts.
 * It is meant to minimize the time necessary to diagnose and fix patch conflicts
 * for someone already well-versed in Magento development.
 * 
 * If you need help, let us know.
 * 
 * README:  https://github.com/rhoerr/supee-6788-toolbox/blob/master/README.md
 * LICENSE: https://github.com/rhoerr/supee-6788-toolbox/blob/master/LICENSE
 * 
 * 
 * ParadoxLabs, Inc.
 * http://www.paradoxlabs.com
 * Phone:   717-431-3330
 * Email:   sales@paradoxlabs.com
 * Support: http://support.paradoxlabs.com
 */

require_once 'abstract.php';

class Mage_Shell_PatchClass extends Mage_Shell_Abstract
{
	protected $_modules;
	protected $_modifiedFiles		= array();
	protected $_fileReplacePatterns	= array();
	public static $_errors			= array();
	
	protected $_codePools			= array(
		'local',
		'community',
		'core'
	);
	
	protected $_moduleWhitelist		= array(
		'Mage_Adminhtml', // Don't try to fix Mage_Adminhtml
	);
	
	protected $_fileWhitelist		= array();
	
	/**
	 * Apply PHP settings to shell script
	 * 
	 * @return void
	 */
	protected function _applyPhpVariables()
	{
		parent::_applyPhpVariables();
		
		set_time_limit(0);
		error_reporting(E_ALL);
		ini_set( 'memory_limit', '2G' );
		ini_set( 'display_errors', 1 );
	}
	
	/**
	 * Run script: Search for SUPEE-6788 affected files, auto-patch if needed.
	 * 
	 * @return void
	 */
	public function run()
	{
		$dryRun = null;
		
		if( isset( $this->_args['analyze'] ) ) {
			$dryRun = true;
		}
		elseif( isset( $this->_args['fix'] ) ) {
			$dryRun = false;
		}
		
		if( !is_null( $dryRun ) ) {
			static::log('-------------------------------------------------------------------');
			static::log('---- SUPEE-6788 Developer Toolbox by ParadoxLabs ------------------');
			static::log('  https://github.com/rhoerr/supee-6788-toolbox');
			static::log('  Time: ' . date('c'));
			
			static::log('---- Loading whitelists -------------------------------------------');
			$this->_loadWhitelistsFromFile();
			
			$this->_findModules();
			
			static::log('---- Searching config for bad routers -----------------------------');
			
			$configAffectedModules	= $this->_fixBadAdminhtmlRouter( $dryRun );
			
			static::log('---- Moving controllers for bad routers to avoid conflicts --------');
			$this->_moveAdminControllers( $configAffectedModules, $dryRun );
			
			static::log('---- Searching files for bad routes -------------------------------');
			$this->_fixBadAdminRoutes( $dryRun );
			
			static::log('---- Searching for whitelist problems -----------------------------');
			$whitelist = new TemplateVars();
			$whitelist->execute( $dryRun );
			
			sort( $this->_modifiedFiles );
			
			static::log('---- Summary ------------------------------------------------------');
			static::log( sprintf( "Affected Modules:\n  %s", implode( "\n  ", $configAffectedModules ) ) );
			static::log( sprintf( "Affected Files:\n  %s", implode( "\n  ", $this->_modifiedFiles ) ) );
			static::log( sprintf( "Issues:\n  %s", implode( "\n  ", static::$_errors ) ) );
			static::log('See var/log/fixSUPEE6788.log for a record of all results.');
			
			if( isset( $this->_args['recordAffected'] ) ) {
				file_put_contents(
					Mage::getBaseDir('var') . DS . 'log' . DS . 'fixSUPEE6788-modules.log',
					implode( "\n", $configAffectedModules )
				);
				static::log('Wrote affected modules to var/log/fixSUPEE6788-modules.log');
				
				file_put_contents(
					Mage::getBaseDir('var') . DS . 'log' . DS . 'fixSUPEE6788-files.log',
					implode( "\n", $this->_modifiedFiles )
				);
				static::log('Wrote affected files to var/log/fixSUPEE6788-files.log');
			}
		}
		elseif( !is_null( $this->_args['fixWhitelists'] ) ) {
			static::log('-------------------------------------------------------------------');
			static::log('---- SUPEE-6788 Developer Toolbox by ParadoxLabs ------------------');
			static::log('  https://github.com/rhoerr/supee-6788-toolbox');
			static::log('  Time: ' . date('c'));
			
			static::log('---- Searching for whitelist problems -----------------------------');
			$whitelist = new TemplateVars();
			$whitelist->execute( false );
		}
		else {
			echo $this->usageHelp();
		}
	}

	/**
	 * Retrieve Usage Help Message
	 * 
	 * @return void
	 */
	public function usageHelp()
	{
		return <<<USAGE
Usage:  php -f fixSUPEE6788.php -- [options] [recordAffected]
  analyze           Analyze Magento install for SUPEE-6788 conflicts
  fix               Apply the automated fixes as found by analyze
  fixWhitelists     Add any missing whitelist entries, without any other changes. SUPEE-6788 must be applied first.
  
  recordAffected    If given, affected modules/files will be written to var/log/fixSUPEE6788-modules.log and var/log/fixSUPEE6788-files.log for other uses.
  
  For all cases, shell/fixSUPEE6788-whitelist-modules.log and shell/fixSUPEE6788-whitelist-files.log will be loaded and excluded from analysis/changes if they exist. Format same as recordAffected output.

USAGE;
	}
	
	/**
	 * Load whitelisted modules/files in that should not be modified during fixes.
	 * 
	 * @return $this
	 */
	protected function _loadWhitelistsFromFile()
	{
		$path = substr( Mage::getBaseDir('skin'), 0, -4 ) . 'shell' . DS;
		
		// Load shell/fixSUPEE6788-whitelist-modules.log into array
		if( is_file( $path . 'fixSUPEE6788-whitelist-modules.log' ) ) {
			$modules = file_get_contents( $path . 'fixSUPEE6788-whitelist-modules.log' );
			if( $modules !== false ) {
				$modules = explode( "\n", $modules );
				$modules = array_filter( $modules );
				foreach( $modules as $module ) {
					$this->_moduleWhitelist[] = $module;
				}
			}
		}
		
		// Load shell/fixSUPEE6788-whitelist-files.log into array
		if( is_file( $path . 'fixSUPEE6788-whitelist-files.log' ) ) {
			$files = file_get_contents( $path . 'fixSUPEE6788-whitelist-files.log' );
			if( $files !== false ) {
				$files = explode( "\n", $files );
				$files = array_filter( $files );
				foreach( $files as $file ) {
					$this->_fileWhitelist[] = $file;
				}
			}
		}
	}
	
	/**
	 * Find modules/configuration affected by the admin controller issue.
	 *
	 * @param boolean $dryRun If true, find affected only; do not apply changes.
	 * @return array Affected module(s)
	 */
	protected function _fixBadAdminhtmlRouter( $dryRun=true )
	{
		$affected = array();
		
		/**
		 * Go through each module, checking its config.xml for a bad admin router.
		 */
		foreach( $this->_modules as $name => $modulePath ) {
			$configPath = $modulePath . DS . 'etc' . DS . 'config.xml';
			
			// Skip any whitelisted files.
			if( in_array( $configPath, $this->_fileWhitelist ) ) {
				continue;
			}
			
			if( is_file( $configPath ) ) {
				$config		= file_get_contents( $configPath );
				$match		= strpos( $config, '<use>admin</use>' );
				
				if( $match !== false ) {
					static::log( sprintf( 'Found affected module: %s', $name ) );
					
					/**
					 * Attempt to locate the complete route tag for replacement.
					 * String operations are messy, but it would be difficult to cover all possible cases otherwise.
					 */
					
					// Get route starting tag and position
					$routeStartingTag		= strrpos( substr( $config, 0, $match ), '<' );
					$routeStartingTagClose	= strpos( $config, '>', $routeStartingTag );
					
					$routeTag				= substr( $config, $routeStartingTag+1, ($routeStartingTagClose - $routeStartingTag - 1) );
					$affected[ $routeTag ]	= $modulePath;
					
					// Get route ending tag position and the full block
					$routeEndingTag			= strpos( $config, '</' . $routeTag .'>', $routeStartingTag );
					$routeLength			= $routeEndingTag - $routeStartingTag + strlen( $routeTag ) + 3;
					$originalXml			= substr( $config, $routeStartingTag, $routeLength );
					
					// Sanity check: Route XML should be no more than 400 characters. (250 typical) Route tag should not be more than 40.
					if( $routeLength > 400 || strlen( $routeTag ) > 40 ) {
						static::log( sprintf( 'Could not find route tag in %s. The module will have to be fixed manually.', $configPath ), true );
						continue;
					}
					
					static::log( sprintf( "Found route tag '%s'. Original route XML:\n%s", $routeTag, $originalXml ) );
					
					// Get the module value
					$module					= null;
					preg_match( '/<module>(.*)<\/module>/', $originalXml, $module );
					$module					= isset( $module[1] ) ? $module[1] : $name;
					
					// Some modules include _Adminhtml in the module path (???). That's going to throw everything
					// else off, but let's not double up. We will not correct the replacement routes for this case,
					// because that could cause massive conflicts with frontend routes of the same name.
					if( strpos( $module, '_Adminhtml' ) !== false ) {
						$module					= str_replace( '_Adminhtml', '', $module );
						
						static::log( sprintf( '%s module route already includes _Adminhtml. Admin routes for the module will have to be fixed manually.', $module ), true );
					}
					
					// Build the replacement XML
					$date					= date('Y-m-d H:i:s');
					$newRouteXml			= <<<XML
<adminhtml>
				<args>
					<modules>
						<{$routeTag} before="Mage_Adminhtml">{$module}_Adminhtml</{$routeTag}>
					</modules>
				</args>
			</adminhtml>
XML;
					static::log( sprintf( "To be replaced with:\n%s", $newRouteXml ) );
					
					/**
					 * If this is not a dry run, apply the changes and save config.xml.
					 */
					if( $dryRun === false ) {
						$config = substr_replace( $config, $newRouteXml, $routeStartingTag, $routeLength );
						
						if( file_put_contents( $configPath, $config ) !== false ) {
							$this->_modifiedFiles[] = $configPath;
							static::log('...Done.');
						}
						else {
							static::log( sprintf( 'Unable to write new configuration to %s', $configPath ), true );
							continue;
						}
					}
					else {
						$this->_modifiedFiles[] = $configPath;
					}
			
					// Set route replace patterns. We'll change them later if needed.
					$this->_fileReplacePatterns[ '<action>' . $routeTag . '/adminhtml_' ]	= '<action>adminhtml/';
					$this->_fileReplacePatterns[ '<' . $routeTag . '_adminhtml_' ]			= '<adminhtml_';
					$this->_fileReplacePatterns[ '</' . $routeTag . '_adminhtml_' ]			= '</adminhtml_';
					$this->_fileReplacePatterns[ 'getUrl("' . $routeTag . '/adminhtml_' ]	= 'getUrl("adminhtml/';
					$this->_fileReplacePatterns[ "getUrl('" . $routeTag . '/adminhtml_' ]	= "getUrl('adminhtml/";
					$this->_fileReplacePatterns[ 'getUrl( "' . $routeTag . '/adminhtml_' ]	= 'getUrl( "adminhtml/';
					$this->_fileReplacePatterns[ "getUrl( '" . $routeTag . '/adminhtml_' ]	= "getUrl( 'adminhtml/";
				}
				else {
					// If the pattern is not found, module is not affected. Move on.
				}
			}
			else {
				static::log( sprintf( 'Unable to load configuration: %s', $configPath ), true );
			}
		}
		
		return $affected;
	}
	
	/**
	 * Move controllers affected by the router change to avoid route conflicts.
	 *
	 * @param string[] $modulePaths Paths to modules to scan for routes.
	 * @param boolean $dryRun If true, find affected only; do not apply changes.
	 * @return $this
	 */
	protected function _moveAdminControllers( $modulePaths, $dryRun=true )
	{
		foreach( $modulePaths as $route => $modulePath ) {
			$cleanRoute			= strtolower( preg_replace( '/[^a-zA-Z0-9]/', '', $route ) );
			$addedRoute			= ucfirst( $cleanRoute );
			$controllerPath		= $modulePath . DS . 'controllers' . DS . 'Adminhtml';
			$tmpControllerPath	= $modulePath . DS. 'controllers' . DS . 'Adminhtmltmp';
			$newControllerPath	= $controllerPath . DS . $addedRoute;
			
			// Skip any whitelisted files.
			if( in_array( $controllerPath, $this->_fileWhitelist ) ) {
				continue;
			}
			
			if( is_dir( $newControllerPath ) ) {
				static::log( sprintf( '%s already exists! Skipping.', $newControllerPath ) );
				continue;
			}
			
			if( !is_dir( $controllerPath ) ) {
				static::log( sprintf( "%s does not exist! This module's admin routes must be corrected manually.", $controllerPath ), true );
				continue;
			}
			
			if( $dryRun === false ) {
				// First, rename Adminhtml to somthing nonconflicting (Adminhtmltmp)
				// Then create new Adminhtml
				// Then rename Adminhtmltmp to Adminhtml/{$addedRoute}
				if( rename( $controllerPath, $tmpControllerPath ) === true ) {
					if( mkdir( $controllerPath ) === true ) {
						if( rename( $tmpControllerPath, $newControllerPath ) === true ) {
							$this->_modifiedFiles[] = $controllerPath;
							
							static::log( sprintf( 'Moved %s to %s', $controllerPath, $newControllerPath ) );
						}
						else {
							static::log( sprintf( 'Unable to move %s to %s', $tmpControllerPath, $newControllerPath ), true );
							continue;
						}
					}
					else {
						static::log( sprintf( 'Unable to create %s', $controllerPath ), true );
						continue;
					}
				}
				else {
					static::log( sprintf( 'Unable to rename %s', $controllerPath ), true );
					continue;
				}
			}
			else {
				$this->_modifiedFiles[] = $controllerPath;
				
				static::log( sprintf( 'Would move %s to %s', $controllerPath, $newControllerPath ) );
			}
			
			// H'okay. That's done. Now fix all of the class names we just broke, and set up the string replacements.
			// Start by building the class prefix from the folder path. Should pass the module through instead.
			$folders	= explode( DS, $modulePath );
			$moduleName	= array_pop( $folders );
			$vendorName	= array_pop( $folders );
			$oldClassPrefix = $vendorName . '_' . $moduleName . '_Adminhtml_'; // WAS: Vendor_Module_Adminhtml_, route {route}/adminhtml_
			$newClassPrefix = $oldClassPrefix . $addedRoute . '_'; // NOW: Vendor_Module_Adminhtml_Route_, route adminhtml/{route}_
			
			// We're not going to replace these immediately. We'll add them to an array with all other patterns,
			// then scan the entire codebase in one swoop to get everything fixed up. Better for handling dependencies
			// and module files we don't necessarily know the location of.
			$this->_fileReplacePatterns[ 'class ' . $oldClassPrefix ] = 'class ' . $newClassPrefix;
			$this->_fileReplacePatterns[ 'extends ' . $oldClassPrefix ] = 'extends ' . $newClassPrefix;
			
			// Reset route replace patterns with the new controller path.
			$this->_fileReplacePatterns[ '<action>' . $route . '/adminhtml_' ]	= '<action>adminhtml/' . $cleanRoute . '_';
			$this->_fileReplacePatterns[ '<' . $route . '_adminhtml_' ]			= '<adminhtml_' . $cleanRoute . '_';
			$this->_fileReplacePatterns[ '</' . $route . '_adminhtml_' ]		= '</adminhtml_' . $cleanRoute . '_';
			$this->_fileReplacePatterns[ 'getUrl("' . $route . '/adminhtml_' ]	= 'getUrl("adminhtml/' . $cleanRoute . '_';
			$this->_fileReplacePatterns[ "getUrl('" . $route . '/adminhtml_' ]	= "getUrl('adminhtml/" . $cleanRoute . '_';
			$this->_fileReplacePatterns[ 'getUrl( "' . $route . '/adminhtml_' ]	= 'getUrl( "adminhtml/' . $cleanRoute . '_';
			$this->_fileReplacePatterns[ "getUrl( '" . $route . '/adminhtml_' ]	= "getUrl( 'adminhtml/" . $cleanRoute . '_';
		}
		
		return $this;
	}
	
	/**
	 * Attempt to find and fix any admin URLs (routes) affected by the router change.
	 *
	 * @param boolean $dryRun If true, find affected only; do not apply changes.
	 * @return $this
	 */
	protected function _fixBadAdminRoutes( $dryRun=true )
	{
		$scanPaths = array(
			Mage::getBaseDir('code'),
			Mage::getBaseDir('design') . DS . 'adminhtml',
		);
		
		/**
		 * Trudge through the filesystem.
		 */
		foreach( $scanPaths as $scanPath ) {
			/**
			 * For each file within this path...
			 */
			$files = new RecursiveIteratorIterator( new RecursiveDirectoryIterator( $scanPath ) );
			foreach( $files as $file => $object ) {
				// Skip any non-PHP/XML/PHTML files.
				if( strrpos( $file, '.php' ) === false && strrpos( $file, '.xml' ) === false && strrpos( $file, '.phtml' ) === false ) {
					continue;
				}
				
				// Skip any whitelisted files.
				if( in_array( $file, $this->_fileWhitelist ) ) {
					continue;
				}
				
				$fileContents	= file_get_contents( $file );
				$lines			= explode( "\n", $fileContents );
				$changes		= false;
				
				/**
				 * Scan the file line-by-line for each pattern.
				 */
				$oldUrlPath = '';
				$newUrlPath = '';
				$checkLine  = -1;
				foreach( $lines as $key => $line ) {
					foreach( $this->_fileReplacePatterns as $pattern => $replacement ) {
						if( strpos( $line, $pattern ) !== false ) {
							$lines[ $key ] = str_replace( $pattern, $replacement, $line );
						} else if ( $checkLine !== $key && strpos( $pattern, 'getUrl' ) !== false && strpos( $line, 'getUrl' ) !== false ) {
							// Handle multi-line getUrl syntax. cf. https://github.com/rhoerr/supee-6788-toolbox/pull/1
							$oldUrlPath = substr( $pattern, strcspn($pattern, '"\'') + 1 );
							$newUrlPath = substr( $replacement, strcspn($replacement, '"\'') + 1 );
							$checkLine  = ( strlen($oldUrlPath) > 0 && strlen($newUrlPath ) > 0 ) ? $key + 1 : -1;
						}

						if ( $key == $checkLine ) {
							if( strpos( $line, $oldUrlPath ) !== false ) {
								$lines[ $key ] = str_replace( $oldUrlPath, $newUrlPath, $line );
							}
							
							$oldUrlPath     = '';
							$newUrlPath     = '';
							$checkLine      = -1;
						}
					}
					
					/**
					 * Check for APPSEC-1063 - Thanks @timvroom
					 */
					if( preg_match( '/addFieldToFilter\(\s*[\'"]?[\`\(]/i', $line ) ) {
						static::log( sprintf( 'POSSIBLE SQL VULNERABILITY: %s:%s', $file, $key ), true );
						static::log( sprintf( '  CODE:%s', $line ) );
					}
					
					/**
					 * If this line has any changes, record it.
					 */
					if( $line != $lines[ $key ] ) {
						if( $changes === false ) {
							static::log( $file );
							$changes = true;
						}
						
						static::log( sprintf( '  WAS:%s', $line ) );
						static::log( sprintf( '  NOW:%s', $lines[ $key ] ) );
					}
				}
				
				/**
				 * If the file has been modified, record it and save.
				 */
				if( $changes === true ) {
					if( $dryRun === false ) {
						$fileContents = implode( "\n", $lines );
						
						if( file_put_contents( $file, $fileContents ) !== false ) {
							$this->_modifiedFiles[] = $file;
							// Silence!
						}
						else {
							static::log( sprintf( 'Unable to write changes to %s', $file ), true );
						}
					}
					else {
						$this->_modifiedFiles[] = $file;
					}
				}
			}
		}
		
		return $this;
	}
	
	/**
	 * Locate all modules in the system.
	 *
	 * @return void
	 */
	protected function _findModules()
	{
		$this->_modules = array();
		
		$modules = Mage::getConfig()->getNode('modules')->children();
		foreach( $modules as $name => $settings ) {
			$dir = Mage::getModuleDir( '', $name );
			
			// Skip any whitelisted modules.
			if( !in_array( $name, $this->_moduleWhitelist ) && !in_array( $dir, $this->_moduleWhitelist ) ) {
				$this->_modules[ $name ] = $dir;
			}
		}
	}
	
	/**
	 * Write the given message to a log file and to screen.
	 *
	 * @param  mixed $message Message to log
	 * @param  boolean $isError If true, log the error for summary.
	 * @return void
	 */
	public static function log( $message, $isError=false )
	{
		// Record errors to repeat in the summary.
		if( $isError === true ) {
			static::$_errors[] = $message;
			
			$message = 'ERROR: ' . $message;
		}
		
		Mage::log( $message, null, 'fixSUPEE6788.log', true );
		
		if( !is_string( $message ) ) {
			$message = print_r( $message, 1 );
		}
		
		echo $message . "\n";
	}
}

$shell = new Mage_Shell_PatchClass();
$shell->run();



/**
 * TemplateVars adapted from magerun-addons
 * Courtesy of @peterjaap and @timvroom
 * https://github.com/peterjaap/magerun-addons
 */
class TemplateVars
{
	/**
	 * Default whitelist entries. Used if not able to load from DB.
	 *
	 * @var array
	 */
	protected static $varsWhitelist = array(
		'web/unsecure/base_url',
		'web/secure/base_url',
		'trans_email/ident_general/name',
		'trans_email/ident_general/email',
		'trans_email/ident_sales/name',
		'trans_email/ident_sales/email',
		'trans_email/ident_support/name',
		'trans_email/ident_support/email',
		'trans_email/ident_custom1/name',
		'trans_email/ident_custom1/email',
		'trans_email/ident_custom2/name',
		'trans_email/ident_custom2/email',
		'general/store_information/name',
		'general/store_information/phone',
		'general/store_information/address',
	);
	protected static $blocksWhitelist = array(
		'core/template',
		'catalog/product_new',
		'enterprise_catalogevent/event_lister',
	);
	
	protected $_resource;
	protected $_read;
	protected $_write;
	
	protected $_blocksTable;
	protected $_varsTable;
	
	/**
	 * Initialize: Load whitelist entries from the database if possible.
	 */
	public function __construct()
	{
		$this->_resource	= Mage::getSingleton('core/resource');
		$this->_read		= $this->_resource->getConnection('core_read');
		$this->_write		= $this->_resource->getConnection('core_write');
		
		try {
			$this->_blocksTable	= $this->_resource->getTableName('admin/permission_block');
			if( $this->_read->isTableExists( $this->_blocksTable ) )
			{
				self::$blocksWhitelist = array();
				
				$sql				= "SELECT * FROM " . $this->_blocksTable . " WHERE is_allowed=1";
				$permissions		= $this->_read->fetchAll( $sql );
				foreach( $permissions as $permission ) {
					self::$blocksWhitelist[] = $permission['block_name'];
				}
			}
			else {
				$this->_blocksTable	= null;
			}
		}
		catch( Exception $e ) {
			// Exception means the whitelist doesn't exist yet, or we otherwise failed to read it in. That's okay. Move on.
			$this->_blocksTable	= null;
		}
		
		try {
			$this->_varsTable		= $this->_resource->getTableName('admin/permission_variable');
			if( $this->_read->isTableExists( $this->_varsTable ) )
			{
				self::$varsWhitelist = array();
				
				$sql				= "SELECT * FROM " . $this->_varsTable . " WHERE is_allowed=1";
				$permissions		= $this->_read->fetchAll( $sql );
				foreach( $permissions as $permission ) {
					self::$varsWhitelist[] = $permission['variable_name'];
				}
			}
			else {
				$this->_varsTable	= null;
			}
		}
		catch( Exception $e ) {
			// Exception means the whitelist doesn't exist yet, or we otherwise failed to read it in. That's okay. Move on.
			$this->_varsTable	= null;
		}
	}
	
	/**
	 * @return void
	 */
	public function execute( $dryRun=true )
	{
		$cmsBlockTable		= $this->_resource->getTableName('cms/block');
		$cmsPageTable		= $this->_resource->getTableName('cms/page');
		$emailTemplate		= $this->_resource->getTableName('core/email_template');
		
		$sql				= "SELECT %s FROM %s WHERE %s LIKE '%%{{config %%' OR  %s LIKE '%%{{block %%'";
		$list				= array('block' => array(), 'variable' => array());
		$cmsCheck			= sprintf($sql, 'content, concat("cms_block=",identifier) as id', $cmsBlockTable, 'content', 'content');
		$result				= $this->_read->fetchAll($cmsCheck);
		$this->check($result, 'content', $list);
		
		$cmsCheck			= sprintf($sql, 'content, concat("cms_page=",identifier) as id', $cmsPageTable, 'content', 'content');
		$result				= $this->_read->fetchAll($cmsCheck);
		$this->check($result, 'content', $list);
		
		$emailCheck			= sprintf($sql, 'template_text, concat("core_email_template=",template_code) as id', $emailTemplate, 'template_text', 'template_text');
		$result				= $this->_read->fetchAll($emailCheck);
		$this->check($result, 'template_text', $list);
		
		$localeDir			= Mage::getBaseDir('locale');
		$scan				= scandir($localeDir);
		$this->walkDir($scan, $localeDir, $list);
		
		if(count($list['block']) > 0) {
			Mage_Shell_PatchClass::log('Blocks that are not whitelisted:');
			
			$inserts	= array();
			
			foreach ($list['block'] as $key => $blockName) {
				Mage_Shell_PatchClass::log( sprintf( '  %s in %s', $blockName, substr( $key, 0, -1 * strlen($blockName) ) ) );
				
				$inserts[ $blockName ] = array(
					'block_name' => $blockName,
					'is_allowed' => 1,
				);
			}
			
			if( $dryRun === false && !is_null( $this->_blocksTable ) && count( $inserts ) > 0 ) {
				$this->_write->insertMultiple( $this->_blocksTable, array_values( $inserts ) );
				
				Mage_Shell_PatchClass::log('Added missing entries to the whitelist');
			}
		}
		
		if(count($list['variable']) > 0) {
			Mage_Shell_PatchClass::log('Config variables that are not whitelisted:');
			
			$inserts	= array();
			
			foreach ($list['variable'] as $key => $varName) {
				Mage_Shell_PatchClass::log( sprintf( '  %s in %s', $varName, substr( $key, 0, -1 * strlen($varName) ) ) );
				
				$inserts[ $varName ] = array(
					'variable_name' => $varName,
					'is_allowed'    => 1,
				);
			}
			
			if( $dryRun === false && !is_null( $this->_varsTable ) && count( $inserts ) > 0 ) {
				$this->_write->insertMultiple( $this->_varsTable, array_values( $inserts ) );
				
				Mage_Shell_PatchClass::log('Added missing entries to the whitelist');
			}
		}
	}
	
	protected function walkDir(array $dir, $path = '', &$list) {
		foreach ($dir as $subdir) {
			if (strpos($subdir, '.') !== 0) {
				if(is_dir($path . DS . $subdir)) {
					$this->walkDir(scandir($path . DS . $subdir), $path . DS . $subdir, $list);
				} elseif (is_file($path . DS . $subdir) && pathinfo($subdir, PATHINFO_EXTENSION) !== 'csv') {
					$file = array( array(
						'id'		=> $path . DS . $subdir,
						'content'	=> file_get_contents($path . DS . $subdir),
					) );
					$this->check($file, 'content', $list);
				}
			}
		}
	}
	
	protected function check($result, $field = 'content', &$list) {
		if ($result) {
			$blockMatch = '/{{block[^}]*?type=["\'](.*?)["\']/i';
			$varMatch = '/{{config[^}]*?path=["\'](.*?)["\']/i';
			foreach ($result as $res) {
				$target = ($field === null) ? $res: $res[$field];
				if (preg_match_all($blockMatch, $target, $matches)) {
					foreach ($matches[1] as $match) {
						if( !in_array( $match, self::$blocksWhitelist ) ) {
							$list['block'][ $res['id'] . $match ] = $match;
						}
					}
				}
				if (preg_match_all($varMatch, $target, $matches)) {
					foreach ($matches[1] as $match) {
						if( !in_array( $match, self::$varsWhitelist ) ) {
							$list['variable'][ $res['id'] . $match ] = $match;
						}
					}
				}
			}
		}
	}
}
