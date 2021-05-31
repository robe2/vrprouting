#!/bin/sh.exe
# CHANGE THESE TO SUIT YOUR PROJECT
#all these get passed in by jenkins
#export OS_BUILD=64
#export PG_VER=9.2
#export PGHOST=localhost
#export PGPORT=8442
#export VRPROUTING_VER=2.0
#export VRPROUTING_MICRO_VER=0dev
#export GIT_COMMIT=whatever

#This line is commented out on build file
#strip *.dll

export PGUSER=postgres

#this should be setup as a mapping in msys/etc/fstab to where you keep your projects
export PROJECTS=/projects
export PATHOLD=$PATH

#export PATHOLD=".:/bin:/include:/mingw/bin:/mingw/include:/c/Windows/system32:/c/Windows:/usr/local/bin:/c/ming64/Silksvn/bin:/c/Program Files (x86)/Git/bin"

export PATHOLD=".:/bin:/include:/mingw/bin:/mingw/include:/c/Windows/system32:/c/Windows:/usr/local/bin"
export PGWINVER=${PG_VER}edb
export PostgreSQL_ROOT=${PROJECTS}/postgresql/rel/pg${PG_VER}w${OS_BUILD}${GCC_TYPE}
export PATH="${PATHOLD}:${PostgreSQL_ROOT}/bin:${PostgreSQL_ROOT}/lib"
if [[ "${GCC_TYPE}" == *gcc48* ]] ; then
	GMP_VER=5.1.2
	MPFR_VER=3.1.2
	CGAL_VER=4.6.1
	BOOST_VER=1.59.0
	BOOST_VER_WU=1_59_0
	BOOST_VER_WUM=1_59
    echo "$BOOST_VER_WU"
    echo "$BOOST_VER_WUM"
else
  GMP_VER=5.1.2
	MPFR_VER=3.1.2
	CGAL_VER=3.9
	BOOST_VER=1.46.1
    echo "$GMP_VER"
    echo "$MPFR_VER"
fi;

#cd ${PROJECTS}/VRPROUTING/branches/${VRPROUTING_VER}/build/lib
cd "${PROJECTS}/VRPROUTING/build${VRPROUTING_VER}w${OS_BUILD}${GCC_TYPE}" || exit 1

export REL_PGVER=${PG_VER//./} #strip the period

if [[ "$VRPROUTING_MICRO_VER"  == *SVN* || "$VRPROUTING_MICRO_VER"  == *dev* ]] ; then
  export RELDIR=${PROJECTS}/VRPROUTING/builds/${VRPROUTING_VER}
  export RELVERDIR=VRPROUTING-pg${REL_PGVER}-binaries-${VRPROUTING_VER}.${VRPROUTING_MICRO_VER}w${OS_BUILD}${GCC_TYPE}
else
	#tagged version -- official release
	export RELDIR=${PROJECTS}/VRPROUTING/builds/${VRPROUTING_VER}
	export RELVERDIR=VRPROUTING-pg${REL_PGVER}-binaries-${VRPROUTING_VER}w${OS_BUILD}${GCC_TYPE}
fi;


outdir="${RELDIR}/${RELVERDIR}"
package="${RELDIR}/${RELVERDIR}.zip"
verfile="${RELDIR}/${RELVERDIR}/version.txt"

rm -rf "${outdir}"
rm "${package}"
mkdir -p "${outdir}"
mkdir -p "${outdir}/share/extension"
mkdir "${outdir}/bin"
mkdir "${outdir}/lib"

cd "${PROJECTS}/VRPROUTING/build${VRPROUTING_VER}w${OS_BUILD}${GCC_TYPE}/sql" || exit 1
cp ./*.sql "${outdir}/share/extension"
cp "${PostgreSQL_ROOT}/share/extension/vrprouting.control" "${outdir}/share/extension"

cd "${PROJECTS}/VRPROUTING/build${VRPROUTING_VER}w${OS_BUILD}${GCC_TYPE}/lib" || exit 1
strip ./*.dll

cp -r ./*.dll "${outdir}/lib"
#newer gcc for some reason CGAL is not statically linked
# so need to distribute
if [[ "${GCC_TYPE}" == *gcc48* ]] ; then
	cp "${PROJECTS}/CGAL/rel-cgal-${CGAL_VER}w${OS_BUILD}${GCC_TYPE}/bin/libCGAL.dll" "${outdir}/bin"
fi
#cp extensions/postgis_topology/sql/* ${RELDIR}/${RELVERDIR}/share/extension
#cp extensions/postgis_topology/*.control ${RELDIR}/${RELVERDIR}/share/extension
cp -r "${RELDIR}/packaging_notes/*" "${RELDIR}/${RELVERDIR}/"

echo "The git commit is ${GIT_COMMIT}"
echo "VRPROUTING http://pgrouting.org : ${VRPROUTING_VER}.${VRPROUTING_MICRO_VER} ${GIT_COMMIT}" > "${verfile}"
{
    echo "PostgreSQL http://www.postgresql.org : ${PG_VER} ${OS_BUILD} ${GCC_TYPE}"
    echo "CGAL http://www.cgal.org : ${CGAL_VER}"
    echo "BOOST http://www.boost.org : ${BOOST_VER}"
    date_built=$(eval date +%Y%m%d)
    echo "Built: ${date_built}"
} >> "${verfile}"

cd "${RELDIR}" || exit 1
zip -r "${package}" "${RELVERDIR}"

cp "${package}" "${PROJECTS}/postgis/win_web/download/windows/pg${REL_PGVER}/buildbot"
