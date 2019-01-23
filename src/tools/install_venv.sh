#!/bin/bash

virtualenv .venv
./tools/with_venv.sh pip install --upgrade -r tools/pip-requires
