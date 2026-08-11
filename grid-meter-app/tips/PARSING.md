
YAML
cat <file>.yml | yq .<major>.<minor>

JSON
cat <file>.json | jq .<major>.<minor>

XML
xmllint --xpath '//*[local-name()="project"]/*[local-name()="properties"]' <file>.xml
