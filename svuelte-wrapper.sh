#!/bin/bash

# svuelte-wrapper.sh
# author milahu@gmail.com
# license CC-0

# input package - at least change this config
vue_pkg='vue-golden-layout'



npm_exe='pnpm'
#npm_exe='npm'

svuelte_pkg='https://github.com/sahrizvi/svuelte.git'
svuelte_exe='./node_modules/svuelte/index.js'

# regex patterns of file paths to ignore
skip_copy_files=(
  '^package.json$'
  '^.gitignore$'
  '^.npmignore$'
  '^node_modules/'
  '^dist/'
  '^bin/'
)

# babel plugins required by the vue component
# you must activate plugins in svuelte/index.js: babel_parser_config
install_pkgs=(
  #'@babel/preset-typescript'
  #'@babel/preset-flow'
  #'babel-plugin-transform-decorators'
  #'babel-plugin-transform-decorators-legacy'
  #'babel-plugin-transform-class-properties'
)

do_install='true' # is set to false if output dir exists
do_convert='true'
do_copy='true'
do_debug='false'



# guess output package
svelte_pkg="svelte-${vue_pkg#vue-}"

if [[ "$1" != "-f" && -d "$svelte_pkg" ]]
then
  echo "error: output directory exists: $svelte_pkg"
  echo "run '$0 -f' to force"
  exit 1
fi

if [[ -d "$svelte_pkg" ]]
then
  # skip install if output dir exists
  do_install='false'
fi

mkdir -v "$svelte_pkg"
cd "$svelte_pkg"

if $do_install
then
  echo install packages ....

  $npm_exe init -y

  $npm_exe i \
    "$svuelte_pkg" \
    "$vue_pkg" \
    "${install_pkgs[@]}"

fi

f_vue_root="node_modules/$vue_pkg"
f_svelte_root='' # current dir = $svelte_pkg

[[ "$f_svelte_root" != "" ]] && mkdir -p "$f_svelte_root"



if $do_convert
then
  echo 'convert vue files ....'
  find -L "$f_vue_root" -iname '*.vue' | while read f_vue
  do

    echo '--------------------------------------'

    # sample values:
    # f_vue = node_modules/vue-plugin/src/component.vue

    f_vue_rel="${f_vue#${f_vue_root}/}" # src/component.vue
    f_vue_rel_base="${f_vue_rel%.*}" # src/component
    f_vue_rel_dir="${f_vue_rel%/*}" # src
    [[ "$f_vue_rel" == "$f_vue_rel_dir" ]] && f_vue_rel_dir=''

    f_svelte_rel_dir="${f_svelte_root}${f_vue_rel_dir}" # src
    f_svelte="${f_svelte_root}${f_vue_rel_base}.svelte" # src/component.svelte

    # debug
    $do_debug && cat <<EOF
f_vue = $f_vue
f_vue_rel = $f_vue_rel
f_vue_rel_base = $f_vue_rel_base
f_vue_rel_dir = $f_vue_rel_dir
f_svelte_rel_dir = $f_svelte_rel_dir
f_svelte = $f_svelte

EOF

    echo "in  $f_vue"
    echo "out $f_svelte"

    [[ "$f_svelte_rel_dir" != "" ]] && mkdir -p "$f_svelte_rel_dir"
    "$svuelte_exe" "$f_vue" "$f_svelte"

  done
fi



if $do_copy
then

  echo 'copy other files ....'
  find -L "$f_vue_root" -type f -not -iname '*.vue' | while read f_vue
  do

    # sample values:
    # f_vue = node_modules/vue-plugin/src/util/helper.js

    f_vue_rel="${f_vue#${f_vue_root}/}" # src/util/helper.js

    skip_file='false'
    for pattern in "${skip_copy_files[@]}"
    do
      if (echo "$f_vue_rel" | grep -E "$pattern" >/dev/null)
      then
        echo "skip: $f_vue_rel"
        skip_file='true'
        break
      fi
    done
    $skip_file && continue

    #f_vue_rel_base="${f_vue_rel%.*}" # src/util/helper
    f_vue_rel_dir="${f_vue_rel%/*}" # src/util
    [[ "$f_vue_rel" == "$f_vue_rel_dir" ]] && f_vue_rel_dir=''

    f_svelte_rel_dir="${f_svelte_root}${f_vue_rel_dir}" # src/util

    f_svelte="${f_svelte_root}${f_vue_rel}" # src/util/helper.js

    # debug
    $do_debug && cat <<EOF
f_vue = $f_vue
f_vue_rel = $f_vue_rel
f_vue_rel_dir = $f_vue_rel_dir
f_svelte_rel_dir = $f_svelte_rel_dir
f_svelte = $f_svelte

EOF

    echo "copy: $f_vue_rel"
    [[ "$f_svelte_rel_dir" != "" ]] && mkdir -p "$f_svelte_rel_dir"
    cp "$f_vue" "$f_svelte"

  done
fi
