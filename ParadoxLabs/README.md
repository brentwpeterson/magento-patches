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

We recommend patching your site in two phases: First, apply the SUPEE-6788 patch and immediately run this script with the `fixWhitelists` flag to fix any functionality broken by the whitelist changes. (Verify that all entries added should in fact be there.) Then, run this script with `analyze` and/or `fix` to correct controller conflicts. Verify all is well, then disable the admin controller compatibility mode.

After patching, scan with [MageReport.com](https://www.magereport.com/) to confirm your site is up to date.

## Technical Details
For a rundown of conflicting changes from the SUPEE-6788 patch, see the [technical details brief](http://magento.com/security/patches/supee-6788-technical-details) and discussion on [Magento StackExchange](http://magento.stackexchange.com/questions/87214/how-to-check-which-modules-are-affected-by-security-patch-supee-6788/).

There are four points of interest outlined.

1. **APPSEC-1034**, bypassing custom admin URL: This script addresses this by identifying any affected modules (containing `<use>admin</use>`), and outlines the exact code changes necessary to fix each one. It can apply all of those changes for you if desired.  
2. **APPSEC-1063**, possible SQL injection: This script attempts to identify any such cases by checking all modules and templates for a specific REGEX pattern. Any instances found must be analyzed (and if needed, fixed) manually. (Thanks @timvroom) NOTE: There is no guarantee that all possible instances will be found, nor that all instances found will be affected.  
3. **APPSEC-1057**, information exposure: The patch adds a whitelist of specific blocks and settings accessible in CMS pages, static blocks, and email templates. This script scans all affected content looking for any entries not on the whitelist. It can add all missing entries to the whitelist if desired.  
4. **APPSEC-1079**, potential exploit with PHP opjects in product custom options: This script does not address this change. Any custom code dealing with custom options must be evaluated manually for impact.

## Caveats
* Script assumes admin controllers are all located within {module}/controllers/Adminhtml. This is convention, but not always true.
* Script will not handle multiple admin routes in a single module.
* The script may not catch all possible route formats. The automated changes may result in broken admin pages that must be corrected manually.

## Who we are
This script is provided as a courtesy from ParadoxLabs. We created it to help with applying our own patches, and we're sharing it so you can benefit too. We are a Magento Silver Solution Partner, based out of Lancaster, Pennsylvania USA.

Contributions are welcome. If you have fixes or additional functionality you would like to add, we're happy to accept pull requests. But please realize support will be limited. This script is provided as-is, without warranty or liability. We make no guarantee as to its correctness or completeness, and by using it we assume you know what you're getting into.

The TemplateVars portion of this script was adapted from magerun-addons, courtesy of @peterjaap and @timvroom. Many thanks to their groundwork. https://github.com/peterjaap/magerun-addons

### [ParadoxLabs, Inc.](http://www.paradoxlabs.com)
* **Web:** http://www.paradoxlabs.com
* **Phone:**   [717-431-3330](tel:7174313330)
* **Email:**   sales@paradoxlabs.com
* **Support:** http://support.paradoxlabs.com
