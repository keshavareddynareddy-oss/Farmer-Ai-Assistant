import os
import unittest
from unittest.mock import patch

from fastapi import HTTPException

from app.api import dataset_routes


class DatasetRefreshRouteTests(unittest.TestCase):
    def test_production_refresh_fails_closed_without_admin_key(self):
        with patch.dict(os.environ, {"APP_ENV": "production"}, clear=True):
            with self.assertRaises(HTTPException) as error:
                dataset_routes.dataset_refresh()

        self.assertEqual(error.exception.status_code, 503)

    def test_production_refresh_rejects_missing_or_invalid_admin_key(self):
        environment = {"APP_ENV": "production", "ADMIN_API_KEY": "secret"}
        with patch.dict(os.environ, environment, clear=True):
            with self.assertRaises(HTTPException) as missing_key_error:
                dataset_routes.dataset_refresh(x_admin_key=None)
            with self.assertRaises(HTTPException) as invalid_key_error:
                dataset_routes.dataset_refresh(x_admin_key="wrong")

        self.assertEqual(missing_key_error.exception.status_code, 401)
        self.assertEqual(invalid_key_error.exception.status_code, 401)

    def test_valid_admin_key_allows_refresh(self):
        environment = {"APP_ENV": "production", "ADMIN_API_KEY": "secret"}
        with (
            patch.dict(os.environ, environment, clear=True),
            patch.object(
                dataset_routes,
                "refresh_dataset_from_remote",
                return_value={"ok": True, "refreshed": True},
            ) as refresh,
        ):
            result = dataset_routes.dataset_refresh(x_admin_key="secret")

        self.assertEqual(result, {"ok": True, "refreshed": True})
        refresh.assert_called_once_with(force=True)


if __name__ == "__main__":
    unittest.main()