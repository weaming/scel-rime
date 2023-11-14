#!/bin/bash
source ./config
# Clear the output directory
rm -rf out/rime
rm -rf out/scel/*.txt

# Create necessary directories
mkdir -p out/scel
mkdir -p out/rime

date=$(date +%Y.%m.%d)
master_header="---\nname: ${DICT_PREFIX}.${DICT_MASTER_NAME}\nversion: \"${date}\"\nsort: by_weight\nuse_preset_vocabulary: true\nimport_tables:\n  - luna_pinyin\n"

# Loop over all the dictionaries
i=0
while [ "x${DICT_IDS[i]}" != "x" ]; do
  id=${DICT_IDS[i]}
  name=${DICT_NAMES[i]}
  shortname=${DICT_SHORTS[i]}
  master_header+="  - ${DICT_PREFIX}.${shortname}\n"
  echo "Fetching ${id}: ${name}"
  dest=out/scel/$id.scel
  if [ ! -f $dest ]; then
    url="http://pinyin.sogou.com/d/dict/download_cell.php?id=${id}&name=${name}"
    echo $url
    curl -L $url > $dest
  else
    echo ignore downloading
  fi

  python ./scel2txt.py $dest
  txt=$(cat out/scel/$id.txt)
  header="---\nname: ${DICT_PREFIX}.${shortname}\nversion: \"${date}\"\nsort: by_weight\nuse_preset_vocabulary: true\n...\n\n"
  echo -e "$header${txt}" > out/rime/${DICT_PREFIX}.${shortname}.dict.yaml
  i=$(( $i + 1 ))
done

master_header+="...\n\n"
echo -e "$master_header" > out/rime/${DICT_PREFIX}.${DICT_MASTER_NAME}.dict.yaml

if [[ ! -z "$COPY" ]]; then
  cp out/rime/* "$COPY"
fi

if [[ ! -z "$HOOK_AFTER" ]]; then
  $HOOK_AFTER
fi
