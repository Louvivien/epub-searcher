# -*- coding: utf-8 -*-

require 'fileutils'

require 'test-unit'
require 'mocha/setup'

require 'epub/parser'
require 'epub-searcher/epub-document'

class TestEPUBDocument < Test::Unit::TestCase

  def assert_equal_unique_identifier(expected, document)
    assert_equal(expected, document.extract_unique_identifier)
  end

  def assert_equal_modified(expected, document)
    assert_equal(expected, document.extract_modified)
  end

  def assert_equal_contributors(expected, document)
    assert_equal(expected, document.extract_contributors)
  end

  def assert_equal_creators(expected, document)
    assert_equal(expected, document.extract_creators)
  end

  def assert_equal_file_path(expected, document)
    assert_equal(expected, document.file_path)
  end

  def assert_equal_title(expected, document)
    assert_equal(expected, document.extract_title)
  end

  def assert_equal_main_text(expected_file, document)
    expected_text = File.read(fixture_path(expected_file))
    main_text = document.extract_main_text
    assert_equal(normalize_newline(expected_text),
                 normalize_newline(main_text))
  end

  def assert_equal_xhtml_spine(expected, document)
    assert_equal(expected, document.extract_xhtml_spine)
  end

  class TestContributors < self
    def test_empty
      epub_book = EPUB::Parser.parse(fixture_path('empty_contributors_single_spine.epub'))
      @document = EPUBSearcher::EPUBDocument.new(epub_book)
      assert_equal_contributors([], @document)
    end

    def test_single
      epub_book = EPUB::Parser.parse(fixture_path('single_contributors_multi_spine.epub'))
      @document = EPUBSearcher::EPUBDocument.new(epub_book)
      assert_equal_contributors(['groongaコミュニティ'], @document)
    end

    def test_multiple
      epub_book = EPUB::Parser.parse(fixture_path('multi_contributors_multi_spine.epub'))
      @document = EPUBSearcher::EPUBDocument.new(epub_book)
      assert_equal_contributors(['groongaコミュニティ A', 'groongaコミュニティ B', 'groongaコミュニティ C'], @document)
    end
  end

  class TestSpine < self
    def test_single
      epub_book = EPUB::Parser.parse(fixture_path('empty_contributors_single_spine.epub'))
      document = EPUBSearcher::EPUBDocument.new(epub_book)

      assert_equal_xhtml_spine(['OEBPS/item0001.xhtml'], document)
      assert_equal_main_text('empty_contributors_single_spine_main_text_expected.txt', document)
    end

    def test_multiple
      epub_book = EPUB::Parser.parse(fixture_path('single_contributors_multi_spine.epub'))
      document = EPUBSearcher::EPUBDocument.new(epub_book)

      assert_equal_main_text('single_contributors_multi_spine_main_text_expected.txt', document)
      assert_equal_xhtml_spine(['item0001.xhtml', 'item0002.xhtml'], document)
    end
  end

  class TestExtracts < self
    def setup
      epub_book = EPUB::Parser.parse(fixture_path('empty_contributors_single_spine.epub'))
      @document = EPUBSearcher::EPUBDocument.new(epub_book)
    end

    def test_unique_identifier
      assert_equal_unique_identifier('00004257', @document)
    end

    def test_modified
      epub_book = EPUB::Parser.parse(fixture_path('multi_contributors_multi_spine.epub'))
      document = EPUBSearcher::EPUBDocument.new(epub_book)
      expected_time = Time.parse('2013-06-20T02:44:04Z')
      assert_equal_modified(expected_time.to_f, document)
    end

    def test_creators
      assert_equal_creators(['groonga'], @document)
    end

    def test_file_path
      assert_equal_file_path(fixture_path('empty_contributors_single_spine.epub'), @document)
    end

    def test_title
      assert_equal_title('groongaについて', @document)
    end
  end

  class TestConstructor < self
    def test_epub_book_object
      epub_book = EPUB::Parser.parse(fixture_path('empty_contributors_single_spine.epub'))
      @document = EPUBSearcher::EPUBDocument.new(epub_book)
      assert_equal(EPUB::Book, @document.epub_book.class)
    end

    def test_local_path
      epub_path = fixture_path('empty_contributors_single_spine.epub')
      @document = EPUBSearcher::EPUBDocument.open(epub_path)
      assert_equal(EPUB::Book, @document.epub_book.class)
    end
  end

  class TestRemoteFile < self
    def setup
      @url = 'http://localhost/test.epub'

      EPUBSearcher::EPUBFile.any_instance
        .expects(:download_remote_file).with(@url)
        .returns(File.read(fixture_path('empty_contributors_single_spine.epub')))

      remove_temporary_directory
      EPUBSearcher::EPUBFile.temporary_local_dir = temporary_dir_path
      @document = EPUBSearcher::EPUBDocument.open(@url)

      FileUtils.touch File.join(temporary_dir_path, '日本語.epub')
    end

    def teardown
      super
      remove_temporary_directory
    end

    def remove_temporary_directory
      FileUtils.rm_rf(temporary_dir_path)
    end

    def test_file_path
      expected_path = File.join(temporary_dir_path, File.basename(@url))
      assert_equal_file_path(expected_path, @document)
    end

    def test_file_path_with_japanese_characters
      path = File.join(temporary_dir_path, '日本語.epub')
      expected_path = path
      assert_nothing_raised do
        EPUBSearcher::EPUBFile.new(path)
      end
    end

    def test_remote_file
      assert_equal(EPUB::Book, @document.epub_book.class)
      assert_equal_main_text('empty_contributors_single_spine_main_text_expected.txt', @document)
    end
  end

  private
  def fixture_path(basename)
    File.join(__dir__, 'fixtures', basename)
  end

  def temporary_dir_path
    File.join(__dir__, 'tmp')
  end

end

