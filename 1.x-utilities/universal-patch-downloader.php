<?php
## from Fabian Blechschmidt
#
class PatchDownloader
{
    /**
 *      * @var string
 *           */
    private $infoUrl = "https://MAGEID:TOKEN@www.magentocommerce.com/products/downloads/info/filter/version/";
    /**
 *      * @var string
 *           */
    private $downloadUrl = "https://MAGEID:TOKEN@www.magentocommerce.com/products/downloads/file/";

    /**
 *      * Cache for patches
 *           *
 *                * @var string[]
 *                     */
    private $patchCache = [];

    /**
 *      * @var string[]
 *           */
    private $versions = array(
        '1.2.0.1',
        '1.2.0.2',
        '1.2.0.3',
        '1.2.1.1',
        '1.2.1.2',
        '1.3.1.1',
        '1.3.2.1',
        '1.3.2.2',
        '1.3.2.3',
        '1.3.2.4',
        '1.3.3.0',
        '1.4.0.0',
        '1.4.0.1',
        '1.4.1.0',
        '1.4.1.1',
        '1.4.2.0',
        '1.5.0.1',
        '1.5.1.0',
        '1.6.0.0',
        '1.6.1.0',
        '1.6.2.0',
        '1.7.0.0',
        '1.7.0.1',
        '1.7.0.2',
        '1.8.0.0',
        '1.8.1.0',
        '1.9.0.0',
        '1.9.0.1',
        '1.9.1.0',
        '1.9.1.1',
        '1.9.2.0',
        '1.9.2.1',
        '1.9.2.2',
        '1.9.1.0',
        '1.9.1.0',
        '1.9.2.2',
    );

    public function __construct($mageId, $token)
    {
        $replace           = [
            'MAGEID' => $mageId,
            'TOKEN'  => $token
        ];
        $this->downloadUrl = strtr($this->downloadUrl, $replace);
        $this->infoUrl     = strtr($this->infoUrl, $replace);
    }


    public function downloadPatches()
    {
        foreach ($this->versions as $version) {
            $this->createDirectoryForVersion($version);
            $this->downloadPatchForVersion($version);
        }
    }

    private function downloadPatchForVersion($version)
    {
        $response = file_get_contents($this->infoUrl . $version);
        if (strpos($response, 'No results found.') !== false ||
            strpos($response, 'Community Edition - Patch') === false
        ) {
            $this->cliNotice('No patches found for ' . $version);

            return;
        }
        strtok($response, "\n");
        while ($line = strtok("\n")) {
            if (!preg_match("#(SUPEE-.*?) *?Community Edition - Patch *?$version *?(.*)#", $line, $matches)) {
                continue;
            }
            $matches = array_map('trim', $matches);
            list(, $name, $file) = $matches;
            $name           = str_replace(' ', '_', $name);
            $filenameOnDisk = "$version/$name.sh";
            if (file_exists($filenameOnDisk)) {
                continue;
            }

            $this->downloadPatchIfNeeded($file);
            $this->savePatchToVersionDirectory($version, $filenameOnDisk, $file);
        }
    }

    private function cliError($msg)
    {
        echo "\033[0;31m" . $msg . "\033[0m" . PHP_EOL;
    }

    private function cliNotice($msg)
    {
        echo "\033[0;33m" . $msg . "\033[0m" . PHP_EOL;
    }

    private function cliSuccess($msg)
    {
        echo "\033[0;32m" . $msg . "\033[0m" . PHP_EOL;
    }

    private function createDirectoryForVersion($version)
    {
        if (!is_dir($version)) {
            $directory = __DIR__ . '/' . $version;
            mkdir($directory);
            $this->cliSuccess('Created directory ' . $version);
        }
    }

    /**
 *      * @param $file
 *           */
    private function downloadPatchIfNeeded($file)
    {
        if (!isset($this->patchCache[$file])) {
            $this->patchCache[$file] = file_get_contents($this->downloadUrl . $file);
            $this->cliSuccess('Downloaded and cached patch: ' . $file);
        }
    }

    /**
 *      * @param $version
 *           * @param $filenameOnDisk
 *                * @param $file
 *                     */
    private function savePatchToVersionDirectory($version, $filenameOnDisk, $file)
    {
        file_put_contents($filenameOnDisk, $this->patchCache[$file]);
        $this->cliSuccess(sprintf('Saved %s for version %s', $file, $version));
    }
}

$downloader = new PatchDownloader($mageid, $downloadToken);
$downloader->downloadPatches();
