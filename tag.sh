#!/bin/bash -ex

   SCALA_VER_BASE=${SCALA_VER_BASE-"2.11.0"}
 SCALA_VER_SUFFIX=${SCALA_VER_SUFFIX-"-RC1"}
          XML_VER=${XML_VER-"1.0.0"}
      PARSERS_VER=${PARSERS_VER-"1.0.0"}
CONTINUATIONS_VER=${CONTINUATIONS_VER-"1.0.0"}
        SWING_VER=${SWING_VER-"1.0.0"}
      PARTEST_VER=${PARTEST_VER-"1.0.0"}
PARTEST_IFACE_VER=${PARTEST_IFACE_VER-"0.2"}
   SCALACHECK_VER=${SCALACHECK_VER-"1.11.3"}

        SCALA_REF=${SCALA_REF-"master"}
          XML_REF=${XML_REF-"v$XML_VER"}
      PARSERS_REF=${PARSERS_REF-"v$PARSERS_VER"}
CONTINUATIONS_REF=${CONTINUATIONS_REF-"v$CONTINUATIONS_VER"}
        SWING_REF=${SWING_REF-"v$SWING_VER"}
      PARTEST_REF=${PARTEST_REF-"v$PARTEST_VER"}
PARTEST_IFACE_REF=${PARTEST_IFACE_REF-"v$PARTEST_IFACE_VER"}
   SCALACHECK_REF=${SCALACHECK_REF-"$SCALACHECK_VER"}

baseDir=${baseDir-`pwd`}

SCALA_VER="$SCALA_VER_BASE$SCALA_VER_SUFFIX"

function getOrUpdate(){
    if [ ! -d $1 ]; then
        git clone --depth 1 $2
    fi
    pushd $1

    git fetch $2 $3

    git checkout -q FETCH_HEAD

    git reset --hard FETCH_HEAD

    git clean -fxd

    git log --oneline -1

    git status

    popd
}

update() {
  [[ -d $baseDir ]] || mkdir -p $baseDir
  cd $baseDir
  getOrUpdate $baseDir/$2 "https://github.com/$1/$2.git" $3
  cd $2
}

# no-op if tag exists
tag() {
  [[ -n $(g tag -l $1) ]] || git tag -s $1 -m"$2"
}

update scala scala $SCALA_REF
tag "v$SCALA_VER" "Scala v$SCALA_VER"

update scala scala-continuations $CONTINUATIONS_REF
tag "v$CONTINUATIONS_VER" "Scala Delimited Continuations Library and Compiler Plugin v$CONTINUATIONS_VER"

update scala scala-parser-combinators "$PARSERS_REF"
tag "v$PARSERS_VER" "Scala Standard Parser Combinators Library v$PARSERS_VER"

update scala scala-partest "$PARTEST_REF"
tag "v$PARTEST_VER" "Scala Partest v$PARTEST_VER"

update scala scala-partest-interface "$PARTEST_IFACE_REF"
tag "v$PARTEST_IFACE_VER" "Scala Partest Interface v$PARTEST_IFACE_VER"

update scala scala-swing "$SWING_REF"
tag "v$SWING_VER" "Scala Standard Swing Library v$SWING_VER"

update scala scala-xml "$XML_REF"
tag "v$XML_VER" "Scala Standard XML Library v$XML_VER"
