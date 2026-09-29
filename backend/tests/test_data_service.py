import unittest
from urllib.parse import parse_qs, urlsplit
from unittest.mock import Mock, patch

from app.services import data_service


class MandiPaginationTests(unittest.TestCase):
    def test_official_feed_collects_records_from_later_pages(self):
        first_page = Mock()
        first_page.json.return_value = {
            "total": 3,
            "records": [
                {
                    "commodity": "Wheat",
                    "market": "Large Market",
                    "state": "State",
                    "district": "District",
                    "modal_price": "2400",
                    "arrival_date": "2026-09-28",
                },
                {
                    "commodity": "Wheat",
                    "market": "Second Market",
                    "state": "State",
                    "district": "District",
                    "modal_price": "2500",
                    "arrival_date": "2026-09-28",
                },
            ],
        }
        second_page = Mock()
        second_page.json.return_value = {
            "total": 3,
            "records": [
                {
                    "commodity": "Wheat",
                    "market": "Small Market",
                    "state": "State",
                    "district": "District",
                    "modal_price": "2700",
                    "arrival_date": "2026-09-28",
                },
            ],
        }

        with (
            patch.object(data_service, "MANDI_API_URL", None),
            patch.object(data_service, "MANDI_API_KEY", "test-key"),
            patch.object(data_service, "MANDI_MAX_RECORDS", 10),
            patch.object(data_service, "MANDI_PAGE_SIZE", 2),
            patch.object(
                data_service.requests,
                "get",
                side_effect=[first_page, second_page],
            ) as request,
            patch.object(data_service, "_replace_dataset_in_db") as replace_dataset,
        ):
            data_service._refresh_dataset_from_remote()

        self.assertEqual(request.call_count, 2)
        offsets = [
            parse_qs(urlsplit(call.args[0]).query)["offset"][0]
            for call in request.call_args_list
        ]
        self.assertEqual(offsets, ["0", "2"])

        saved_frame = replace_dataset.call_args.args[0]
        self.assertEqual(len(saved_frame), 3)
        self.assertIn("Small Market", saved_frame["market"].tolist())


if __name__ == "__main__":
    unittest.main()