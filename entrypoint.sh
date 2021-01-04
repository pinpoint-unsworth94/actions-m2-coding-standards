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

PHP_FULL_VERSION=$(php -r 'echo phpversion();')

ARGUMENTS="${INPUT_ARGUMENTS}"

if [ -z "$(ls)" ]; then
  echo "No code have been found.  Did you checkout with «actions/checkout» ?"
  exit 1
fi

echo "PHP Version : ${PHP_FULL_VERSION}"

echo "Installing composer..."
php -r "copy('https://getcomposer.org/composer-1.phar', 'composer.phar');"

echo "Running composer install..."
php -d memory_limit=-1 composer.phar global require hirak/prestissimo
php -d memory_limit=-1 composer.phar install

##tempory fix to stop https://github.com/magento/magento2/issues/28961
composer remove magento/magento2-functional-testing-framework

echo "Setting up Magento2 PHPCBF standards..."
./vendor/bin/phpcs --config-set installed_paths ../../magento/magento-coding-standard/

echo "## Running PHPCBF with arguments «${ARGUMENTS}»"

PHPCBF_OUTPUT=$(php -d memory_limit=-1 ./vendor/bin/phpcbf --standard=Magento2 ${ARGUMENTS})

PHPCBF_OUTPUT="${PHPCBF_OUTPUT//'%'/'%25'}"
PHPCBF_OUTPUT="${PHPCBF_OUTPUT//$'\n'/'%0A'}"
PHPCBF_OUTPUT="${PHPCBF_OUTPUT//$'\r'/'%0D'}"

echo "::set-output name=phpcbf_output::$PHPCBF_OUTPUT"
