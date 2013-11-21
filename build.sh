#!/bin/bash -e

        SCALA_VER="2.11.0-M7"
          XML_VER="1.0.0-RC7"
      PARSERS_VER="1.0.0-RC5"
   SCALACHECK_VER="1.11.1"
      PARTEST_VER="1.0.0-RC8"
PARTEST_IFACE_VER="0.2"

publishTask=publish-signed
buildLocal=true

$buildLocal || (
  echo "NOTE: THIS WIPES OUT ANY LOCAL CHANGES IN ~/git/scala ~/git/scala-partest-interface ~/git/scala-partest ~/git/scalacheck ~/git/scala-parser-combinators ~/git/scala-xml"
  echo "Also, I assume you've cleaned your local ~/.ivy2 and ~/.m2 repos."
  echo "Press the any key to proceed"
  read
)

update() { git pull $1 $2 && git clean -fxd && git --no-pager show ; }

# test and publish to sonatype, assuming you have ~/.sbt/0.13/sonatype.sbt and ~/.sbt/0.13/plugin/gpg.sbt
cd ~/git/scala-xml && ($buildLocal || \
  (update https://github.com/scala/scala-xml.git master && \
   git tag -s "v$XML_VER" -m"Scala Standard XML Library v$XML_VER")) && \
sbt 'set version := "'$XML_VER'"' \
    'set scalaVersion := "'$SCALA_VER'"' \
    clean test $publishTask publishM2

cd ~/git/scala-parser-combinators && ($buildLocal ||\
  (update https://github.com/scala/scala-parser-combinators.git master && \
   git tag -s "v$PARSERS_VER" -m"Scala Standard Parser Combinators Library v$PARSERS_VER")) && \
sbt 'set version := "'$PARSERS_VER'"' \
    'set scalaVersion := "'$SCALA_VER'"' \
    clean test $publishTask publishM2

cd ~/git/scalacheck && ($buildLocal || (update https://github.com/adriaanm/scalacheck.git master)) && \
sbt 'set version := "'$SCALACHECK_VER'"' \
    'set scalaVersion := "'$SCALA_VER'"' \
    'set every scalaBinaryVersion := "'$SCALA_VER'"' \
    'set VersionKeys.scalaParserCombinatorsVersion := "'$PARSERS_VER'"' \
    clean test publish-local publishM2

cd ~/git/scala-partest  && ($buildLocal ||\
  (update https://github.com/scala/scala-partest.git master && git tag -s "v$PARTEST_VER" -m"Scala Partest v$PARTEST_VER")) && \
sbt 'set version :="'$PARTEST_VER'"' \
    'set scalaVersion := "'$SCALA_VER'"' \
    'set VersionKeys.scalaXmlVersion := "'$XML_VER'"' \
    'set VersionKeys.scalaCheckVersion := "'$SCALACHECK_VER'"' \
    clean $publishTask publishM2

cd ~/git/scala-partest-interface  && ($buildLocal ||\
  (update https://github.com/scala/scala-partest-interface.git master && git tag -s "v$PARTEST_IFACE_VER"  -m"Scala Partest Interface v$PARTEST_IFACE_VER")) && \
sbt 'set version :="'$PARTEST_IFACE_VER'"' \
    'set scalaVersion := "'$SCALA_VER'"' \
    clean $publishTask publishM2

# Sanity check: make sure the Scala test suite passes / docs can be generated with these modules.
cd ~/git/scala #&& git checkout "v$SCALA_VER" && git clean -fxd
ant -Dstarr.version=$SCALA_VER -Dstarr.use.released=1\
    -Dlocker.skip=1\
    -Dscala.binary.version=$SCALA_VER\
    -Dpartest.version.number=$PARTEST_VER\
    -Dscala-xml.version.number=$XML_VER\
    -Dscala-parser-combinators.version.number=$PARSERS_VER\
    -Dscalacheck.version.number=$SCALACHECK_VER\
    test-opt docs.done

say "Woo-hoo\!"

# used when testing scalacheck integration with partest, while it's in staging repo before releasing it
#     'set resolvers += "scalacheck staging" at "http://oss.sonatype.org/content/repositories/orgscalacheck-1010/"' \
# in ant: ()
#     -Dextra.repo.url=http://oss.sonatype.org/content/repositories/orgscalacheck-1010/\
