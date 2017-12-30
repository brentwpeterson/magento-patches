# Helpful shortcuts for bin/magento

| CLI Command | Shortcut | Description |
| ----------  | -------- | --- |
| **Available commands:**  | |
| help | h | Displays help for a command |
| list | l | Lists commands |
| **admin**  | |
| admin:user:create | a:u:c | Creates an administrator |
| admin:user:unlock | a:u:u | Unlock Admin Account |
| **app** | |
| app:config:dump | | Create dump of application |
| app:config:import | | Import data from shared configuration files to appropriate data storage |
| **cache** | |
| cache:clean | c:c| Cleans cache type(s) |
| cache:disable | c:d | Disables cache type(s) |
| cache:enable  | c:e | Enables cache type(s) |
| cache:flush | c:f | Flushes cache storage used by cache type(s) |
| cache:status  | c:s | Checks cache status |
| **catalog** | |
| catalog:images:resize | c:i:r | Creates resized product images |
| catalog:product:attributes:cleanup | c:p:a:c | Removes unused product attributes. |
| **config** | |
| config:sensitive:set | |  Set sensitive configuration values |
| config:set  | | Change system configuration |
| config:show | | Shows configuration value for given path. If path is not specified, all saved values will be shown |
| **cron** | |
| cron:install  | | Generates and installs crontab for current user |
| cron:remove | | Removes tasks from crontab |
| cron:run  | c:r | Runs jobs by schedule |
| **customer** | |
| customer:\hash:upgrade | c:h:u | Upgrade customer's hash according to the latest algorithm |
| **deploy** | |
| deploy:mode:set | ``d:m:set`` | Set application mode. |
| deploy:mode:show | ``d:m:sho`` | Displays current application mode. |
| **dev** | |
| dev:di:info | | Provides information on Dependency Injection configuration for the Command. |
| dev:query-log:disable | | Disable DB query logging |
| dev:query-log:enable | |  Enable DB query logging |
| dev:source-theme:deploy | d:s:d | Collects and publishes source files for theme. |
| dev:template-hints:disable | | Disable frontend template hints. A cache flush might be required. |
| dev:template-hints:enable | | Enable frontend template hints. A cache flush might be required. |
| dev:tests:run | d:t:r | Runs tests |
| dev:urn-catalog:generate | d:u:g | Generates the catalog of URNs to \*.xsd mappings for the IDE to highlight xml. |
| dev:xml:convert | d:x:c | Converts XML file using XSL style sheets |
| **i18n**  | |
| i18n:collect-phrases | i1:c |  Discovers phrases in the codebase |
| i18n:pack  | i:p | Saves language package |
| i18n:uninstall | i:u | Uninstalls language packages |
| **indexer** | |
| indexer:info  | i:i | Shows allowed Indexers |
| indexer:reindex | i:rei | Reindexes Data |
| indexer:reset | i:res | Resets indexer status to invalid |
| indexer:set-mode | i:set | Sets index mode type |
| indexer:show-mode | i:sho | Shows Index Mode |
| indexer:status | i:sta | Shows status of Indexer |
| **info** | | 
| info:adminuri | i:a | Displays the Magento Admin URI |
| info:backups:list | i:b:l | Prints list of available backup files |
| info:currency:list | i:c:l | Displays the list of available currencies |
| info:dependencies:show-framework | i:d:show-f | Shows number of dependencies on Magento framework |
| info:dependencies:show-modules | | Shows number of dependencies between modules |
| info:dependencies:show-modules-circular | | Shows number of circular dependencies between modules |
| info:language:list | i:l:l | Displays the list of available language locales |
| info:timezone:list | i:t:l | Displays the list of available timezones |
| **maintenance** |  |
| maintenance:allow-ips | m:a | Sets maintenance mode exempt IPs |
| maintenance:disable | ma:d | Disables maintenance mode |
| maintenance:enable | ma:e | Enables maintenance mode |
| maintenance:status | ma:s | Displays maintenance mode status |
| **module** | |
| module:disable | mo:d | Disables specified modules |
| module:enable | mo:e | Enables specified modules |
| module:status | mo:s | Displays status of modules |
| module:uninstall | m:u | Uninstalls modules installed by composer |
| **sampledata** | |
| sampledata:deploy | sa:d | Deploy sample data modules |
| sampledata:remove | sa:rem | Remove all sample data packages from composer.json |
| sampledata:reset | sa:res | Reset all sample data modules for re-installation |
| **setup** | |
| setup:backup  | s:b | Takes backup of Magento Application code base, media and database |
| setup:config:set | s:c:s | Creates or modifies the deployment configuration |
| setup:cron:run | s:c:r | Runs cron job scheduled for setup application |
| setup:db-data:upgrade | s:db-d:u | Installs and upgrades data in the DB |
| setup:db-schema:upgrade | s:db-s:u | Installs and upgrades the DB schema |
| setup:db:status | s:d:s | Checks if DB schema or data requires upgrade |
| setup:di:compile | s:d:c | Generates DI configuration and all missing classes that can be auto-generated |
| setup:install | s:i | Installs the Magento application |
| setup:performance:generate-fixtures | s:p:g | Generates fixtures |
| setup:rollback | se:r | Rolls back Magento Application codebase, media and database |
| setup:static-content:deploy | s:s:d | Deploys static view files |
| setup:store-config:set | s:s:s |  Installs the store configuration. Deprecated since 2.2.0. Use config:set instead |
| setup:uninstall | s:un | Uninstalls the Magento application |
| setup:upgrade | s:up | Upgrades the Magento application, DB data, and schema |
| **store** | |
| store:list  | | Displays the list of stores |
| store:website:list | | Displays the list of websites |
| **theme** | |
| theme:uninstall | t:u | Uninstalls theme |
| **varnish** | |
| varnish:vcl:ge |
