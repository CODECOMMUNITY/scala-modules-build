#!/bin/bash -ex
# needs SONA_USER_TOKEN and ~/.m2/settings.xml with credentials for sonatype

     MAVEN_SUFFIX="-M8-local"
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

stApi="https://oss.sonatype.org/service/local/"

function st_curl(){
  curl -H "accept: application/json" --user $SONA_USER_TOKEN -s -o - $@
}

function st_stagingRepo() {
 st_curl "$stApi/staging/profile_repositories" | jq '.data[] | select(.profileName == "org.scala-lang") | .repositoryURI'
}


update() {
  $buildLocal && cd $baseDir/$2 && return 0

  repo="https://github.com/$1/$2.git"
  ref=${3-master}

  mkdir -p $baseDir && cd $baseDir
  [[ -d $2 ]] || git clone $repo
  cd $2

#  git pull --rebase $repo $ref

  $buildLocal || (git fetch $repo $ref && git reset --hard FETCH_HEAD && git clean -fxd)

  git --no-pager show
}

tag() { $buildLocal || (git tag -s $1 -m$2) ; }

publishModules() {
  publishTask=$1
  sonaStaging=$2

  # test and publish to sonatype, assuming you have ~/.sbt/0.13/sonatype.sbt and ~/.sbt/0.13/plugin/gpg.sbt
  update scala scala-xml
  tag "v$XML_VER" "Scala Standard XML Library v$XML_VER"
  sbt 'set version := "'$XML_VER'"' \
      'set resolvers += "staging" at "'$sonaStaging'"'\
      'set scalaVersion := "'$SCALA_VER'"' \
      clean test $publishTask publishM2

  update scala scala-parser-combinators
  tag "v$PARSERS_VER" "Scala Standard Parser Combinators Library v$PARSERS_VER"
  sbt 'set version := "'$PARSERS_VER'"' \
      'set resolvers += "'$sonaStaging'"'\
      'set scalaVersion := "'$SCALA_VER'"' \
      clean test $publishTask publishM2

  update rickynils scalacheck $SCALACHECK_VER
  sbt 'set version := "'$SCALACHECK_VER'"' \
      'set resolvers += "'$sonaStaging'"'\
      'set scalaVersion := "'$SCALA_VER'"' \
      'set every scalaBinaryVersion := "'$SCALA_VER'"' \
      'set VersionKeys.scalaParserCombinatorsVersion := "'$PARSERS_VER'"' \
      clean test publish-local publishM2

  update scala scala-partest
  tag "v$PARTEST_VER" "Scala Partest v$PARTEST_VER"
  sbt 'set version :="'$PARTEST_VER'"' \
      'set resolvers += "'$sonaStaging'"'\
      'set scalaVersion := "'$SCALA_VER'"' \
      'set VersionKeys.scalaXmlVersion := "'$XML_VER'"' \
      'set VersionKeys.scalaCheckVersion := "'$SCALACHECK_VER'"' \
      clean $publishTask publishM2

  update scala scala-partest-interface
  tag "v$PARTEST_IFACE_VER" "Scala Partest Interface v$PARTEST_IFACE_VER"
  sbt 'set version :="'$PARTEST_IFACE_VER'"' \
      'set resolvers += "'$sonaStaging'"'\
      'set scalaVersion := "'$SCALA_VER'"' \
      clean $publishTask publishM2
}

update scala scala

# publish core so that we can build modules with this version of Scala and publish them locally
# must publish under $SCALA_VER so that the modules will depend on this (binary) version of Scala
# publish more than just core: partest needs scalap
ant -Dmaven.version.number=$SCALA_VER\
    -Dscalac.args.optimise=-optimise\
    -Ddocs.skip=1\
    -Dlocker.skip=1\
    publish

stagingRepo=$(st_stagingRepo)
echo "Scala core published to $stagingRepo"

# build, test and publish modules with this core
publishModules publish-local $stagingRepo

# Rebuild Scala with these modules so that all binary versions are consistent.
# Update versions.properties to new modules.
# Sanity check: make sure the Scala test suite passes / docs can be generated with these modules.
# don't skip locker (-Dlocker.skip=1\), or stability will fail
cd $baseDir/scala
ant -Dstarr.version=$SCALA_VER\
    -Dextra.repo.url=$stagingRepo\
    -Dmaven.version.suffix=$MAVEN_SUFFIX\
    -Dscala.binary.version=$SCALA_VER\
    -Dpartest.version.number=$PARTEST_VER\
    -Dscala-xml.version.number=$XML_VER\
    -Dscala-parser-combinators.version.number=$PARSERS_VER\
    -Dscalacheck.version.number=$SCALACHECK_VER\
    -Dupdate.versions=1\
    -Dscalac.args.optimise=-optimise\
    $publishAnt #test

git commit versions.properties -m"Bump versions.properties for $SCALA_VER."

tag "v$SCALA_VER" "Scala v$SCALA_VER"

# rebuild modules for good measure
publishModules test

say "Woo-hoo\!"

# used when testing scalacheck integration with partest, while it's in staging repo before releasing it
#     'set resolvers += "scalacheck staging" at "http://oss.sonatype.org/content/repositories/orgscalacheck-1010/"' \
# in ant: ()
#     -Dextra.repo.url=http://oss.sonatype.org/content/repositories/orgscalacheck-1010/\
