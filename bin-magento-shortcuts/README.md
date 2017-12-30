# Helpful shortcuts for bin/magento

| CLI Command | Shortcut | Description |
| ----------  | -------- | --- |
vailable commands:  | |
| help | | Displays help for a command |
| list | | Lists commands |
| # admin | |
| admin:user:create | | Creates an administrator |
| admin:user:unlock | | Unlock Admin Account |
| # app | |
| app:config:dump | | Create dump of application |
| app:config:import | | Import data from shared configuration files to appropriate data storage |
| # cache | |
| cache:clean | | Cleans cache type(s) |
| cache:disable | | Disables cache type(s) |
| cache:enable  | | Enables cache type(s) |
| cache:flush | | Flushes cache storage used by cache type(s) |
| cache:status  | | Checks cache status |
| # catalog | |
| catalog:images:resize | | Creates resized product images |
| catalog:product:attributes:cleanup       Removes unused product attributes. |
| # config |
| config:sensitive:set | |  Set sensitive configuration values |
| config:set  | | Change system configuration |
| config:show | | Shows configuration value for given path. If path is not specified, all saved values will be shown |
| # cron |
| cron:install  | | Generates and installs crontab for current user |
| cron:remove | | Removes tasks from crontab |
| cron:run  | | Runs jobs by schedule |
| customer |
| customer:hash:upgrade | | Upgrade customer's hash according to the latest algorithm |
| # deploy |
| deploy:mode:set | | Set application mode. |
| deploy:mode:show | | Displays current application mode. |
| # dev |
| dev:di:info | | Provides information on Dependency Injection configuration for the Command. |
| dev:query-log:disable | | Disable DB query logging |
| dev:query-log:enable | |  Enable DB query logging |
| dev:source-theme:deploy | | Collects and publishes source files for theme. |
| dev:template-hints:disable | | Disable frontend template hints. A cache flush might be required. |
| dev:template-hints:enable | | Enable frontend template hints. A cache flush might be required. |
| dev:tests:run | | Runs tests |
| dev:urn-catalog:generate | | Generates the catalog of URNs to *.xsd mappings for the IDE to highlight xml. |
| dev:xml:convert | | Converts XML file using XSL style sheets |
| # i18n |
| i18n:collect-phrases | |  Discovers phrases in the codebase |
| i18n:pack  | | Saves language package |
| i18n:uninstall | | Uninstalls language packages |
| # indexer |
| indexer:info  | | Shows allowed Indexers |
| indexer:reindex | | Reindexes Data |
| indexer:reset | | Resets indexer status to invalid |
| indexer:set-mode | | Sets index mode type |
| indexer:show-mode | | Shows Index Mode |
| indexer:status | | Shows status of Indexer |
| # info |
| info:adminuri | | Displays the Magento Admin URI |
| info:backups:list | | Prints list of available backup files |
| info:currency:list | | Displays the list of available currencies |
| info:dependencies:show-framework | | Shows number of dependencies on Magento framework |
| info:dependencies:show-modules | | Shows number of dependencies between modules |
| info:dependencies:show-modules-circular  Shows number of circular dependencies between modules |
| info:language:list | | Displays the list of available language locales |
| info:timezone:list | | Displays the list of available timezones |
| # maintenance |
| maintenance:allow-ips | | Sets maintenance mode exempt IPs |
| maintenance:disable |Disables maintenance mode |
| maintenance:enable | | Enables maintenance mode |
| maintenance:status | | Displays maintenance mode status |
| # module |
| module:disable | | Disables specified modules |
| module:enable | | Enables specified modules |
| module:status | | Displays status of modules |
| module:uninstall | | Uninstalls modules installed by composer |
| # sampledata |
| sampledata:deploy | | Deploy sample data modules |
| sampledata:remove | | Remove all sample data packages from composer.json |
| sampledata:reset | | Reset all sample data modules for re-installation |
| # setup |
| setup:backup  | | Takes backup of Magento Application code base, media and database |
| setup:config:set | | Creates or modifies the deployment configuration |
| setup:cron:run | | Runs cron job scheduled for setup application |
| setup:db-data:upgrade | | Installs and upgrades data in the DB |
| setup:db-schema:upgrade | | Installs and upgrades the DB schema |
| setup:db:status | | Checks if DB schema or data requires upgrade |
| setup:di:compile | | Generates DI configuration and all missing classes that can be auto-generated |
| setup:install | | Installs the Magento application |
| setup:performance:generate-fixtures      Generates fixtures |
| setup:rollback | | Rolls back Magento Application codebase, media and database |
| setup:static-content:deploy | | Deploys static view files |
| setup:store-config:set | |  Installs the store configuration. Deprecated since 2.2.0. Use config:set instead |
| setup:uninstall | | Uninstalls the Magento application |
| setup:upgrade | | Upgrades the Magento application, DB data, and schema |
| # store |
| store:list  | | Displays the list of stores |
| store:website:list | | Displays the list of websites |
| # theme |
| theme:uninstall | | Uninstalls theme |
| # varnish |
| varnish:vcl:ge |
