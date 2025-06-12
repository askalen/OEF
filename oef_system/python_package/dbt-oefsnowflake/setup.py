#!/usr/bin/env python
from setuptools import find_namespace_packages, setup

package_name = "dbt-oefsnowflake"
# make sure this always matches dbt/adapters/{adapter}/__version__.py
package_version = "1.0.0"
description = """The OEFSnowflake adapter plugin for dbt"""

setup(
    name=package_name,
    version=package_version,
    description=description,
    long_description=description,
    author="Adam Skalenakis",
    author_email="adamskalenakis@gmail.com",
    url="If you have already made a github repo to tie the project to place it here, otherwise update in setup.py later.",
    packages=find_namespace_packages(include=["dbt", "dbt.*"]),
    include_package_data=True,
    install_requires=[
        "dbt-core~=1.9.0",
        "dbt-common<2.0"
    ],
)
