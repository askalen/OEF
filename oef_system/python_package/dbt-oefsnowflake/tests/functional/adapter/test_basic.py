import pytest

from dbt.tests.adapter.basic.test_base import BaseSimpleMaterializations
from dbt.tests.adapter.basic.test_singular_tests import BaseSingularTests
from dbt.tests.adapter.basic.test_singular_tests_ephemeral import (
    BaseSingularTestsEphemeral
)
from dbt.tests.adapter.basic.test_empty import BaseEmpty
from dbt.tests.adapter.basic.test_ephemeral import BaseEphemeral
from dbt.tests.adapter.basic.test_incremental import BaseIncremental
from dbt.tests.adapter.basic.test_generic_tests import BaseGenericTests
from dbt.tests.adapter.basic.test_snapshot_check_cols import BaseSnapshotCheckCols
from dbt.tests.adapter.basic.test_snapshot_timestamp import BaseSnapshotTimestamp
from dbt.tests.adapter.basic.test_adapter_methods import BaseAdapterMethod


class TestSimpleMaterializationsOEFSnowflake(BaseSimpleMaterializations):
    pass


class TestSingularTestsOEFSnowflake(BaseSingularTests):
    pass


class TestSingularTestsEphemeralOEFSnowflake(BaseSingularTestsEphemeral):
    pass


class TestEmptyOEFSnowflake(BaseEmpty):
    pass


class TestEphemeralOEFSnowflake(BaseEphemeral):
    pass


class TestIncrementalOEFSnowflake(BaseIncremental):
    pass


class TestGenericTestsOEFSnowflake(BaseGenericTests):
    pass


class TestSnapshotCheckColsOEFSnowflake(BaseSnapshotCheckCols):
    pass


class TestSnapshotTimestampOEFSnowflake(BaseSnapshotTimestamp):
    pass


class TestBaseAdapterMethodOEFSnowflake(BaseAdapterMethod):
    pass
