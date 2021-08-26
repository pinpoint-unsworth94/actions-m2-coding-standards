<?php
namespace Deployer;

require 'recipe/common.php';

use \Symfony\Component\Console\Input\InputOption;

option('path', null, InputOption::VALUE_OPTIONAL, 'Path to run linting on');

task('install', function () {
    $phpVersion = phpversion();
    $phpPath = $_SERVER['_'] . " -dmemory_limit=-1";

    if (!test("[ -d {$phpVersion}/ ]")) {
      run('mkdir ' . $phpVersion);
    }

    cd($phpVersion);

    if (!test('[ -f "composer.phar" ]')) {
        run("wget https://getcomposer.org/composer-1.phar");
        run("mv composer-1.phar composer.phar");
        run($phpPath . " composer.phar require magento/magento-coding-standard --quiet");
        run($phpPath . " composer.phar require slevomat/coding-standard --quiet");
    }

    run($phpPath . " ./vendor/bin/phpcs --config-set installed_paths ../../magento/magento-coding-standard/,../../slevomat/coding-standard/");

    if (!test('[ -f "./vendor/squizlabs/php_codesniffer/src/Standards/Squiz/Sniffs/Operators/ComparisonOperatorUsageSniff.php" ]')) {
        run("cp -R ../Sniffs/Custom ./vendor/magento/magento-coding-standard/Magento2/Sniffs/");
    }

});


task('phpcbf', function () {
    invoke('install');

    writeln('Running PHPCBF...');
    $phpPath = $_SERVER['_'] . " -dmemory_limit=-1";
    $phpVersion = phpversion();

    $output = run($phpPath . " ./" . $phpVersion . "/vendor/bin/phpcbf --runtime-set ignore_errors_on_exit 1 --standard=phpcs.xml " . input()->getOption("path") . "; if [ $? -eq 1 ]; then exit 0; fi");
    writeln($output);
});

task('phpcs', function () {
    invoke('install');

    writeln('Running PHPCS...');
    $phpPath = $_SERVER['_'] . " -dmemory_limit=-1";
    $phpVersion = phpversion();

    $output = run($phpPath . " ./" . $phpVersion . "/vendor/bin/phpcs --runtime-set ignore_errors_on_exit 1 --runtime-set ignore_warnings_on_exit 1 --standard=phpcs.xml " . input()->getOption("path") . "");
    writeln($output);
});
