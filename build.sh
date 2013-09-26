#!/bin/bash

 SCALA_BINARY_VER="2.11.0-M5"
        SCALA_VER="2.11.0-M5"
   SCALACHECK_VER="1.10.1"
          XML_VER="1.0.0-RC5"
      PARSERS_VER="1.0.0-RC3"
      PARTEST_VER="1.0.0-RC6"
PARTEST_IFACE_VER="0.2"


echo "NOTE: THIS WIPES OUT ANY LOCAL CHANGES IN ~/git/scala-partest-interface ~/git/scala-partest ~/git/scalacheck ~/git/scala-parser-combinators ~/git/scala-xml"
echo "Also, I assume you've cleaned your local ~/.ivy2 repo."
echo "Press the any key to proceed"
read

update() { git pull $1 $2 && git clean -fxd && git --no-pager show ; }

set -ex

cd ~/git/scala-xml && update https://github.com/scala/scala-xml.git master
sbt 'set TestKeys.includeTestDependencies := false' \
    'set version := "'$XML_VER'"' \
    'set scalaVersion := "'$SCALA_VER'"' \
    'set scalaBinaryVersion := "'$SCALA_BINARY_VER'"' \
    publish-local

cd ~/git/scala-parser-combinators && update https://github.com/scala/scala-parser-combinators.git master
sbt 'set TestKeys.includeTestDependencies := false' \
    'set version := "'$PARSERS_VER'"' \
    'set scalaVersion := "'$SCALA_VER'"' \
    'set scalaBinaryVersion := "'$SCALA_BINARY_VER'"' \
    publish-local

cd ~/git/scalacheck && update https://github.com/rickynils/scalacheck.git master
sbt 'set version := "'$SCALACHECK_VER'"' \
    'set scalaVersion := "'$SCALA_VER'"' \
    'set every scalaBinaryVersion := "'$SCALA_BINARY_VER'"' \
    publish-local

cd ~/git/scala-partest && update https://github.com/scala/scala-partest.git master
sbt 'set version :="'$PARTEST_VER'"' \
    'set DependencyKeys.scalaXmlVersion := "'$XML_VER'"' \
    'set scalaVersion := "'$SCALA_VER'"' \
    'set scalaBinaryVersion := "'$SCALA_BINARY_VER'"' \
    publish-local


cd ~/git/scala-partest-interface && update https://github.com/scala/scala-partest-interface.git master
sbt 'set version :="'$PARTEST_IFACE_VER'"' \
    'set scalaVersion := "'$SCALA_VER'"' \
    'set scalaBinaryVersion := "'$SCALA_BINARY_VER'"' \
    publish-local

# allow invidual steps to fail (if version was already tagged, assume it was already published)
set +ex

# Now test and publish to sonatype, assuming you have ~/.sbt/0.13/sonatype.sbt and ~/.sbt/0.13/plugin/gpg.sbt
cd ~/git/scala-xml && git tag -s "v$XML_VER"                          -m"Scala Standard XML Library v$XML_VER" && \
sbt 'set version := "'$XML_VER'"' \
    'set TestKeys.partestVersion := "'$PARTEST_VER'"' \
    'set scalaVersion := "'$SCALA_VER'"' \
    'set scalaBinaryVersion := "'$SCALA_BINARY_VER'"' \
    test publish-signed

cd ~/git/scala-parser-combinators && git tag -s "v$PARSERS_VER"       -m"Scala Standard Parser Combinators Library v$PARSERS_VER" && \
sbt 'set version := "'$PARSERS_VER'"' \
    'set TestKeys.partestVersion := "'$PARTEST_VER'"' \
    'set scalaVersion := "'$SCALA_VER'"' \
    'set scalaBinaryVersion := "'$SCALA_BINARY_VER'"' \
    test publish-signed

cd ~/git/scala-partest && git tag -s "v$PARTEST_VER"                  -m"Scala Partest v$PARTEST_VER" && \
sbt 'set version :="'$PARTEST_VER'"' \
    'set scalaVersion := "'$SCALA_VER'"' \
    'set scalaBinaryVersion := "'$SCALA_BINARY_VER'"' \
    publish-signed


cd ~/git/scala-partest-interface && git tag -s "v$PARTEST_IFACE_VER"  -m"Scala Partest Interface v$PARTEST_IFACE_VER" && \
sbt 'set version :="'$PARTEST_IFACE_VER'"' \
    'set scalaVersion := "'$SCALA_VER'"' \
    'set scalaBinaryVersion := "'$SCALA_BINARY_VER'"' \
    publish-signed




# // misc
# 
# set libraryDependencies  ~= { ld => ld collect { case dep if dep.classifier != Some(test) => dep } }
# 
# set libraryDependencies  ~= { ld => ld map { case dep if (dep.organization == "org.scala-lang.modules") => dep cross CrossVersion.fullMapped(_ => "2.11.0-M5") case dep => dep } }
