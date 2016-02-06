#Magento Patches

The following grid was supplied by John Knowles 

Twitter: @knowj 

The Grid is here (With living Colour)
https://docs.google.com/spreadsheets/d/1MTbU9Bq130zrrsJwLIB9d8qnGfYZnkm4jBlfNaBF19M/edit#gid=0

Blog Post:
http://www.wearejh.com/development/security-our-clients-are-fully-patched-are-you/
# Magento® SUPEE-6788 Developer Toolbox

Magento's SUPEE-6788 patch is a mess for developers. There are a number of breaking changes, affecting 800+ of the most popular extensions and many customizations.

This script attempts to find and automatically resolve major problems from the patch. Details on usage and internals are below, but at a high level:

The `analyze` step goes through all extensions looking for anything using custom admin routers (the major outdated change), and produces a list of every module affected, the bad XML and PHP code, and exactly what should be changed to resolve it. It also looks at every CMS page, static block, and email template for any blocks or configuration that are not known to be on the new whitelist. All of this is purely informational, to inform you of the state of the Magento installation and what will be involved in fixing it.

The `fix` step automatically applies as many of the identified changes as it can. Not every possible module and situation can be resolved automatically, but this should save a vast amount of time for the ones that can.

This is not the end-all/be-all solution to fixing conflicts from the patch. It is intended to minimize the time and risk involved in diagnosing and fix SUPEE-6788 patch conflicts for someone already well-versed in Magento development. The information produced will not be accessible to anyone unfamiliar with Magento routing.

If you need help, let us know. Contact details at the bottom.

**WARNING:** This script is destructive. If you apply the changes, it **WILL** overwrite existing files with the changes noted. Back up your site before applying any changes, and trial it first on a development copy if at all possible.

## Usage
* Backup your website.
* Upload fixSUPEE6788.php to {magento}/shell/fixSUPEE6788.php
* **To analyze:** Run from SSH: `php -f fixSUPEE6788.php -- analyze`
* **To apply changes:** Run from SSH: `php -f fixSUPEE6788.php -- fix`
* **To fix missing whitelist entries only:** Run from SSH: `php -f fixSUPEE6788.php -- fixWhitelists`
* Additional option: `recordAffected` - If given, two files will be written after running: `var/log/fixSUPEE6788-modules.log` containing all modules affected by the patch, and `var/log/fixSUPEE6788-files.log` containing all files the script would/did modify. Use this to grab an archive of modified files (`tar czf modified.tar.gz -T var/log/fixSUPEE6788-files.log`), or weed out any files/modules for the fix whitelist.
* Excluding files and modules: If given, `shell/fixSUPEE6788-whitelist-modules.log` and `shell/fixSUPEE6788-whitelist-files.log` will be loaded, and any files/modules included will be left out of all analysis and fixes. Format should be identical to the files produced by `recordAffected`.
* Command with options: `php -f fixSUPEE6788.php -- analyze recordAffected`

All results are output to screen and to var/log/fixSUPEE6788.log.

