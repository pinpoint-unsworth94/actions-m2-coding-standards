# actions-m2-coding-standards
Github action to run PHPCBF and PHPCS on pull request changes using Magento2 standards and commit changes to pull request.

Example usage:
```yml
- name: Run PHPCBF & PHPCS on Magento 2 repository
  id: phpcbf
  uses: pinpoint-unsworth94/actions-m2-coding-standards@master
  with:
      arguments: ${{ steps.file_filter.outputs.value }}
      php_version: '7.2' #default: 7.2 (7.1, 7.2, 7.3 supported)
- name: Print phpcbf output
  shell: bash
  run: |
    PHPCBF_OUTPUT="${{ steps.phpcbf.outputs.phpcbf_output }}"
    PHPCBF_OUTPUT="${PHPCBF_OUTPUT//'%25'/'%'}"
    PHPCBF_OUTPUT="${PHPCBF_OUTPUT//$'%0A'/'\n'}"å
    PHPCBF_OUTPUT="${PHPCBF_OUTPUT//$'%0D'/'\r'}"
    echo -e $PHPCBF_OUTPUT
```
