import unittest
from unittest.mock import patch, mock_open, MagicMock
import inject_json # replace this with the actual name of your module

class TestJsonModifier(unittest.TestCase):

    @patch('os.environ.get', return_value="test_path")
    @patch('argparse.ArgumentParser.parse_args')
    def test_load_args(self, mock_parse_args, mock_get):
        mock_args = MagicMock()
        mock_args.file = "test_file"
        mock_args.modify = [["test_key", "test_value"]]
        mock_parse_args.return_value = mock_args
        args = inject_json.load_args()
        self.assertEqual(args.file, "test_file")
        self.assertEqual(args.modify, [["test_key", "test_value"]])

    @patch('json.load')
    @patch('builtins.open', new_callable=mock_open, read_data='{"test_key": "test_value"}')
    def test_load_json_file(self, mock_file, mock_json_load):
        inject_json.load_json_file("test_file")
        mock_file.assert_called_once_with("test_file", 'r')
        mock_json_load.assert_called_once()

    @patch('json.dump')
    @patch('builtins.open', new_callable=mock_open)
    def test_write_json_file(self, mock_file, mock_json_dump):
        test_data = {"test_key": "test_value"}
        inject_json.write_json_file("test_file", test_data)
        mock_file.assert_called_once_with("test_file", 'w')
        mock_json_dump.assert_called_once_with(test_data, mock_file(), indent='\t')

    def test_check_integer(self):
        self.assertEqual(inject_json.check_integer("123"), 123)
        self.assertEqual(inject_json.check_integer("abc"), "abc")

    @patch('inject_json.check_integer')
    @patch('inject_json.write_json_file')
    def test_inject_json(self, mock_write_json_file, mock_check_integer):
        mock_write_json_file.return_value = True
        mock_check_integer.return_value = "test_value"
        test_injector = inject_json.JSONData("test_file", {"test_key": "test_value"})
        test_injector.loaded_data = {"test_key": "old_value"}
        inject_json.inject_json(test_injector)
        mock_check_integer.assert_called_once_with("test_value")
        mock_write_json_file.assert_called_once_with("test_file", {"test_key": "test_value"})


if __name__ == '__main__':
    unittest.main()
