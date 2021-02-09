#!/bin/bash
# set -e

JENKINS_FILE=$(ls -1 _build/jenkins/ | head -1)
JENKINS_PHP=$(cat "_build/jenkins/${JENKINS_FILE}" | awk -v FS="(php|-sp)" '{print $2}' | grep '[0-9]' | head -1)

echo "Found PHP version ${JENKINS_PHP} from jenkins file..."

if [ -z "$JENKINS_PHP" ]
then
  update-alternatives --set php /usr/bin/php${INPUT_PHP_VERSION}
else
  update-alternatives --set php /usr/bin/php${JENKINS_PHP}
fi

ARGUMENTS=$(echo ${INPUT_ARGUMENTS} | sed 's/m2\/app/app/g' | sed 's/  */ /g') #change paths from m2/app... to app...
if [[ $INPUT_FULL_SCAN == 'false' ]]
then
  echo "Removing none org namespace (${INPUT_ORG_NAMESPACE}) changes..."
  ARGUMENTS=$(echo $ARGUMENTS | sed 's/[\ ]/\n/g' | sed "/\/code\/${INPUT_ORG_NAMESPACE}\//!s/.*/ /" | tr '\n' ' ')
fi

if [ -z "$(ls)" ]; then
  echo "No code have been found.  Did you checkout with «actions/checkout» ?"
  exit 1
fi

PHP_FULL_VERSION=$(php -r 'echo phpversion();')
echo "PHP Version : ${PHP_FULL_VERSION}"

echo "Finding magento root path..."
BIN_MAGENTO_PATH=$(find . -name 'magento' -maxdepth 3 | grep -m1 'bin/magento')
MAGENTO_ROOT_PATH="$(dirname $BIN_MAGENTO_PATH)/../"

echo "Changing dir to magento root path ${MAGENTO_ROOT_PATH}"
cd $MAGENTO_ROOT_PATH

echo "Installing composer..."
php -r "copy('https://getcomposer.org/composer-1.phar', 'composer.phar');"

echo "Running composer install..."
php -d memory_limit=-1 composer.phar global require hirak/prestissimo --quiet

HAS_MAGENTO_COMPOSER_KEYS=$(cat ./auth.json | grep "repo.magento.com")
if [[ -z $HAS_MAGENTO_COMPOSER_KEYS ]]
then
  echo "No repo.magento.com creds found in auth.json."
  php -d memory_limit=-1 composer.phar config http-basic.repo.magento.com $INPUT_MAGENTO_COMPOSER_USERNAME $INPUT_MAGENTO_COMPOSER_PASSWORD
fi

# php -d memory_limit=-1 composer.phar install --quiet
echo "Temporarily killing composer as not needed..."
mv composer.json composer.json.bk
mv composer.lock composer.lock.bk

# HAS_CODING_STANDARDS_INSTALLED=$(grep "magento/magento-coding-standard" ./composer.json)
# if [[ -z $HAS_CODING_STANDARDS_INSTALLED ]]
# then
  echo "Magento coding standards package not installed. Installing magento/magento-coding-standard..."
  php -d memory_limit=-1 composer.phar require magento/magento-coding-standard:* --quiet --ignore-platform-reqs
# fi

##tempory fix to stop https://github.com/magento/magento2/issues/28961
echo "Patching Magento/FunctionalTestingFramework/_bootstrap.php incase xdebug_disable doesnt exist..."
# php -d memory_limit=-1 composer.phar remove magento/magento2-functional-testing-framework --quiet
sed -i 's/xdebug_disable();/if (function_exists("xdebug_disable")) xdebug_disable();/g' vendor/magento/magento2-functional-testing-framework/src/Magento/FunctionalTestingFramework/_bootstrap.php

echo "Setting up Magento2 PHPCBF standards..."
./vendor/bin/phpcs --config-set installed_paths ../../magento/magento-coding-standard/

echo "## Running PHPCBF with arguments «${ARGUMENTS}»"
PHPCBF_OUTPUT=$(php -d memory_limit=-1 ./vendor/bin/phpcbf --standard=Magento2 ${ARGUMENTS})
PHPCBF_FIXED_CHECK=$(echo $PHPCBF_OUTPUT | grep "No fixable errors were found")
PHPCBF_OUTPUT="${PHPCBF_OUTPUT//'%'/'%25'}"
PHPCBF_OUTPUT="${PHPCBF_OUTPUT//$'\n'/'%0A'}"
PHPCBF_OUTPUT="${PHPCBF_OUTPUT//$'\r'/'%0D'}"
echo "::set-output name=phpcbf_output::$PHPCBF_OUTPUT"

FILE_CHECKED=$(echo ${INPUT_ARGUMENTS} | sed 's/  */ /g')
echo "::set-output name=files_checked::$FILE_CHECKED"

if [[ "$PHPCBF_FIXED_CHECK" == *"No fixable errors were found"* ]]
then
  echo "::set-output name=phpcbf_fixed_anything::false"
else
  echo "::set-output name=phpcbf_fixed_anything::true"
fi

echo "## Running PHPCS with arguments «${ARGUMENTS}»"
PHPCS_OUTPUT=$(php -d memory_limit=-1 ./vendor/bin/phpcs --standard=Magento2 ${ARGUMENTS})
PHPCS_OUTPUT="${PHPCS_OUTPUT//'%'/'%25'}"
PHPCS_OUTPUT="${PHPCS_OUTPUT//$'\n'/'%0A'}"
PHPCS_OUTPUT="${PHPCS_OUTPUT//$'\r'/'%0D'}"
echo "::set-output name=phpcs_output::$PHPCS_OUTPUT"
PHPCS_ERROR_COUNT=$(echo $PHPCS_OUTPUT | awk -v FS="(FOUND|ERRORS)" '{print $2}' | grep '[0-9]' | sed 's/ //g')
PHPCS_WARNING_COUNT=$(echo $PHPCS_OUTPUT | awk -v FS="(AND|WARNINGS)" '{print $2}' | grep '[0-9]' | sed 's/ //g')

if [[ "$PHPCS_ERROR_COUNT" == "0" ]]
then
  echo "::set-output name=phpcs_has_errors::false"
else
  echo "::set-output name=phpcs_has_errors::true"
fi

if [[ "$PHPCS_WARNING_COUNT" == "0" ]]
then
  echo "::set-output name=phpcs_has_warnings::false"
else
  echo "::set-output name=phpcs_has_warnings::true"
fi

#annotatate files in PR
cp /problem-matcher.json .
echo "::add-matcher::$(pwd)/problem-matcher.json"
php -d memory_limit=-1 ./vendor/bin/phpcs --report=checkstyle --standard=Magento2 ${ARGUMENTS}

echo "Reverting the killing of composer as not needed..."
mv composer.json.bk composer.json
mv composer.lock.bk composer.lock
