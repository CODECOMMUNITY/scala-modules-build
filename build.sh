#!/bin/bash -ex

     MAVEN_SUFFIX="-M8"
        SCALA_VER="2.11.0$MAVEN_SUFFIX"
          XML_VER="1.0.0-RC7"
      PARSERS_VER="1.0.0-RC5"
   SCALACHECK_VER="1.11.1"
      PARTEST_VER="1.0.0-RC8"
PARTEST_IFACE_VER="0.2"

baseDir="/Users/adriaan/git/"

buildLocal=true
publishAnt=publish.local #publish.signed
publishSbt=publish-local #publish-signed

# TODO: clean local repo, or publish to a fresh one

$buildLocal || (
  echo "NOTE: THIS WIPES OUT ANY LOCAL CHANGES IN $baseDir/scala $baseDir/scala-partest-interface $baseDir/scala-partest $baseDir/scalacheck $baseDir/scala-parser-combinators $baseDir/scala-xml"
  echo "Also, I assume you've cleaned your local ~/.ivy2 and ~/.m2 repos."
  echo "Press the any key to proceed"
  read
)

update() {
  $buildLocal && cd $baseDir/$2 && return 0

  repo="https://github.com/$1/$2.git"
  ref=${3-master}

  mkdir -p $baseDir && cd $baseDir
  [[ -d $2 ]] || git clone $repo
  cd $2

  git pull --rebase $repo $ref

  $buildLocal || (git fetch $repo $ref && git reset --hard FETCH_HEAD && git clean -fxd)

  git --no-pager show
}

tag() { $buildLocal || (git tag -s $1 -m$2) ; }

publishModules() {
  publishTask=$1

  # test and publish to sonatype, assuming you have ~/.sbt/0.13/sonatype.sbt and ~/.sbt/0.13/plugin/gpg.sbt
  update scala scala-xml
  tag "v$XML_VER" "Scala Standard XML Library v$XML_VER"
  sbt 'set version := "'$XML_VER'"' \
      'set resolvers += Resolver.mavenLocal'\
      'set scalaVersion := "'$SCALA_VER'"' \
      clean $2 $publishTask publishM2

  update scala scala-parser-combinators
  tag "v$PARSERS_VER" "Scala Standard Parser Combinators Library v$PARSERS_VER"
  sbt 'set version := "'$PARSERS_VER'"' \
      'set resolvers += Resolver.mavenLocal'\
      'set scalaVersion := "'$SCALA_VER'"' \
      clean $2 $publishTask publishM2

  update rickynils scalacheck $SCALACHECK_VER
  sbt 'set version := "'$SCALACHECK_VER'"' \
      'set resolvers += Resolver.mavenLocal'\
      'set scalaVersion := "'$SCALA_VER'"' \
      'set every scalaBinaryVersion := "'$SCALA_VER'"' \
      'set VersionKeys.scalaParserCombinatorsVersion := "'$PARSERS_VER'"' \
      clean $2 publish-local publishM2

  update scala scala-partest
  tag "v$PARTEST_VER" "Scala Partest v$PARTEST_VER"
  sbt 'set version :="'$PARTEST_VER'"' \
      'set resolvers += Resolver.mavenLocal'\
      'set scalaVersion := "'$SCALA_VER'"' \
      'set VersionKeys.scalaXmlVersion := "'$XML_VER'"' \
      'set VersionKeys.scalaCheckVersion := "'$SCALACHECK_VER'"' \
      clean $publishTask publishM2

  update scala scala-partest-interface
  tag "v$PARTEST_IFACE_VER" "Scala Partest Interface v$PARTEST_IFACE_VER"
  sbt 'set version :="'$PARTEST_IFACE_VER'"' \
      'set resolvers += Resolver.mavenLocal'\
      'set scalaVersion := "'$SCALA_VER'"' \
      clean $publishTask publishM2
}

update scala scala

# publish core so that we can build modules with this version of Scala and publish them locally
ant -Dmaven.version.suffix=$MAVEN_SUFFIX\
    -Dscalac.args.optimise=-optimise\
    -Ddocs.skip=1\
    -Dlocker.skip=1\
    publish-core-local

# build, test and publish modules with this core
publishModules publish-local

# Rebuild Scala with these modules so that all binary versions are consistent.
# Update versions.properties to new modules.
# Sanity check: make sure the Scala test suite passes / docs can be generated with these modules.
# don't skip locker (-Dlocker.skip=1\), or stability will fail
cd $baseDir/scala
ant -Dmaven.version.suffix=$MAVEN_SUFFIX\
    -Dscalac.args.optimise=-optimise\
    -Dstarr.version=$SCALA_VER\
    -Dscala.binary.version=$SCALA_VER\
    -Dpartest.version.number=$PARTEST_VER\
    -Dscala-xml.version.number=$XML_VER\
    -Dscala-parser-combinators.version.number=$PARSERS_VER\
    -Dscalacheck.version.number=$SCALACHECK_VER\
    -Dupdate.versions=1\
    test $publishAnt

git commit versions.properties -m"Bump versions.properties for $SCALA_VER."

tag "v$SCALA_VER" "Scala v$SCALA_VER"

# rebuild modules for good measure
publishModules $publishSbt test

say "Woo-hoo\!"

# used when testing scalacheck integration with partest, while it's in staging repo before releasing it
#     'set resolvers += "scalacheck staging" at "http://oss.sonatype.org/content/repositories/orgscalacheck-1010/"' \
# in ant: ()
#     -Dextra.repo.url=http://oss.sonatype.org/content/repositories/orgscalacheck-1010/\
