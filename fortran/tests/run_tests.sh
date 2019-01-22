set -e

python --version
python setup.py install
python -c "import camb; print(camb.__version__)"
python setup.py test
pip uninstall -y camb
rm -Rf dist/*
rm -Rf build/*
rm -f camb/*.so

if [[ $TRAVIS_REPO_SLUG == "cmbant/CAMB" && $CHANNEL == "defaults" && "$TRAVIS_PULL_REQUEST" == "false" ]]
then
 case "$TRAVIS_BRANCH" in
 devel*) export CAMB_PACKAGE_NAME=camb_devel ;;
    *) export CAMB_PACKAGE_NAME=camb
 esac
 python setup.py sdist
 pip install twine
 twine upload -r pypitest --repository-url https://test.pypi.org/legacy/ dist/*
#too much delay on test.pypi to reliably immediately test install
# mkdir -p test_dir
# pushd test_dir
# pip install --index-url https://test.pypi.org/simple/ $CAMB_PACKAGE_NAME
# python -c "import camb; print(camb.__version__)"
# python -m unittest camb_tests.camb_test
# pip uninstall -y $CAMB_PACKAGE_NAME
# popd
fi

case "$TRAVIS_BRANCH" in
 devel*)
       BRANCH="devel_newstate"
       ;;
    *)
       BRANCH="master"
       ;;
esac

pushd fortran

make clean
make

mkdir testfiles
python tests/CAMB_test_files.py testfiles --make_ini

pushd testfiles
echo "cloning test output branch:" $BRANCH
git clone -b $BRANCH --depth=1 https://github.com/cmbant/CAMB_test_outputs.git
popd

python tests/CAMB_test_files.py testfiles --diff_to CAMB_test_outputs/test_outputs --verbose

rm -Rf testfiles/CAMB_test_outputs

popd