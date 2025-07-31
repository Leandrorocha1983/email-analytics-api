import pytest
from app.utils import is_valid_filename, parse_user_record, paginate_list

class TestValidateFilename:
    def test_valid_filenames(self):
        valid_names = ["input", "data_file", "test-file", "File123"]
        for name in valid_names:
            assert is_valid_filename(name)
    
    def test_invalid_filenames(self):
        invalid_names = ["file.txt", "file with spaces", "file@email.com"]
        for name in invalid_names:
            assert not is_valid_filename(name)

class TestParseUserRecord:
    def test_parse_valid_record(self):
        line = "hgioep@uol.com.br inbox 000000050 size 001003108"
        user = parse_user_record(line)
        
        assert user is not None
        assert user.username == "hgioep@uol.com.br"
        assert user.folder == "inbox"
        assert user.numberMessages == 50
        assert user.size == 1003108

class TestPagination:
    def test_paginate_first_page(self):
        items = list(range(25))
        result = paginate_list(items, 1, 10)
        
        assert result['data'] == list(range(10))
        assert result['page'] == 1
        assert result['page_size'] == 10
        assert result['total_items'] == 25
        assert result['total_pages'] == 3
