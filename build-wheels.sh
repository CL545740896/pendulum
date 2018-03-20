#!/bin/bash
PYTHON_VERSIONS="cp27-cp27m cp35-cp35m cp36-cp36m"

POETRY_PYTHON="cp36-cp36m"
POETRY_VENV="/opt/python/poetry"
echo "Create Poetry's virtualenv"
/opt/python/${POETRY_PYTHON}/bin/pip install virtualenv
/opt/python/${POETRY_PYTHON}/bin/virtualenv --python /opt/python/${POETRY_PYTHON}/bin/python ${POETRY_VENV}
${POETRY_VENV}/bin/pip install poetry --pre

RELEASE=$(sed -n "s/VERSION = '\(.*\)'/\1/p" /io/pendulum/version.py)

echo "Compile wheels"
for PYTHON in ${PYTHON_VERSIONS}; do
    cd /io
    /opt/python/${POETRY_PYTHON}/bin/virtualenv --python /opt/python/${PYTHON}/bin/python /opt/python/venv-${PYTHON}
    . /opt/python/venv-${PYTHON}/bin/activate
    ${POETRY_VENV}/bin/poetry install -v
    ${POETRY_VENV}/bin/poetry build -v
    mv dist/*-${RELEASE}-*.whl wheelhouse/
    deactivate
    cd -
done

echo "Bundle external shared libraries into the wheels"
for whl in /io/wheelhouse/pendulum-${RELEASE}-*.whl; do
    auditwheel repair $whl -w /io/wheelhouse/
    rm -f $whl
done

echo "Install packages and test"
for PYTHON in ${PYTHON_VERSIONS}; do
    . /opt/python/venv-${PYTHON}/bin/activate
    pip install pendulum==${RELEASE} --no-index --find-links /io/wheelhouse
    find ./io/tests | grep -E "(__pycache__|\.pyc$)" | xargs rm -rf
    pytest /io/tests
    find ./io/tests | grep -E "(__pycache__|\.pyc$)" | xargs rm -rf
    deactivate
done
