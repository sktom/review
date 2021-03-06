# encoding: utf-8

require 'test_helper'
require 'review/compiler'
require 'review/book'
require 'review/htmlbuilder'

class HTMLBuidlerTest < Test::Unit::TestCase
  include ReVIEW

  def setup
    @builder = HTMLBuilder.new()
    @param = {
      "secnolevel" => 2,    # for IDGXMLBuilder, HTMLBuilder
      "inencoding" => "UTF-8",
      "outencoding" => "UTF-8",
      "subdirmode" => nil,
      "stylesheet" => nil,  # for HTMLBuilder
    }
    ReVIEW.book.param = @param
    @compiler = ReVIEW::Compiler.new(@builder)
    @chapter = Book::Chapter.new(nil, 1, '-', nil, StringIO.new)
    location = Location.new(nil, nil)
    @builder.bind(@compiler, @chapter, location)
  end

  def test_headline_level1
    @builder.headline(1,"test","this is test.")
    assert_equal %Q|<h1 id="test"><a id="h1" />第1章　this is test.</h1>\n|, @builder.raw_result
  end

  def test_headline_level1_without_secno
    @param["secnolevel"] = 0
    @builder.headline(1,"test","this is test.")
    assert_equal %Q|<h1 id="test"><a id="h1" />this is test.</h1>\n|, @builder.raw_result
  end

  def test_headline_level1_with_inlinetag
    @builder.headline(1,"test","this @<b>{is} test.<&\">")
    assert_equal %Q|<h1 id="test"><a id="h1" />第1章　this <b>is</b> test.&lt;&amp;&quot;&gt;</h1>\n|, @builder.raw_result
  end

  def test_headline_level2
    @builder.headline(2,"test","this is test.")
    assert_equal %Q|\n<h2 id="test"><a id="h1-1" />1.1　this is test.</h2>\n|, @builder.raw_result
  end

  def test_headline_level3
    @builder.headline(3,"test","this is test.")
    assert_equal %Q|\n<h3 id="test"><a id="h1-0-1" />this is test.</h3>\n|, @builder.raw_result
  end

  def test_headline_level3_with_secno
    @param["secnolevel"] = 3
    @builder.headline(3,"test","this is test.")
    assert_equal %Q|\n<h3 id="test"><a id="h1-0-1" />1.0.1　this is test.</h3>\n|, @builder.raw_result
  end

  def test_label
    @builder.label("label_test")
    assert_equal %Q|<a id="label_test" />\n|, @builder.raw_result
  end

  def test_href
    ret = @builder.compile_href("http://github.com", "GitHub")
    assert_equal %Q|<a href="http://github.com" class="link">GitHub</a>|, ret
  end

  def test_href_without_label
    ret = @builder.compile_href("http://github.com",nil)
    assert_equal %Q|<a href="http://github.com" class="link">http://github.com</a>|, ret
  end

  def test_inline_href
    ret = @builder.inline_href("http://github.com, Git\\,Hub")
    assert_equal %Q|<a href="http://github.com" class="link">Git,Hub</a>|, ret
  end

  def test_inline_href_without_label
    ret = @builder.inline_href("http://github.com")
    assert_equal %Q|<a href="http://github.com" class="link">http://github.com</a>|, ret
  end

  def test_inline_raw
    ret = @builder.inline_raw("@<tt>{inline}")
    assert_equal %Q|@<tt>{inline}|, ret
  end

  def test_inline_in_table
    ret = @builder.table(["<b>1</b>\t<i>2</i>", "------------", "<b>3</b>\t<i>4</i>&lt;&gt;&amp;"])
    assert_equal %Q|<div class="table">\n<table>\n<tr><th><b>1</b></th><th><i>2</i></th></tr>\n<tr><td><b>3</b></td><td><i>4</i>&lt;&gt;&amp;</td></tr>\n</table>\n</div>\n|, @builder.raw_result
  end

  def test_inline_br
    ret = @builder.inline_br("")
    assert_equal %Q|<br />|, ret
  end

  def test_inline_i
    ret = @builder.compile_inline("test @<i>{inline test} test2")
    assert_equal %Q|test <i>inline test</i> test2|, ret
  end

  def test_inline_i_and_escape
    ret = @builder.compile_inline("test @<i>{inline<&;\\ test} test2")
    assert_equal %Q|test <i>inline&lt;&amp;;\\ test</i> test2|, ret
  end

  def test_inline_b
    ret = @builder.compile_inline("test @<b>{inline test} test2")
    assert_equal %Q|test <b>inline test</b> test2|, ret
  end

  def test_inline_b_and_escape
    ret = @builder.compile_inline("test @<b>{inline<&;\\ test} test2")
    assert_equal %Q|test <b>inline&lt;&amp;;\\ test</b> test2|, ret
  end

  def test_inline_tt
    ret = @builder.compile_inline("test @<tt>{inline test} test2")
    assert_equal %Q|test <tt>inline test</tt> test2|, ret
  end

  def test_inline_tti
    ret = @builder.compile_inline("test @<tti>{inline test} test2")
    assert_equal %Q|test <tt><i>inline test</i></tt> test2|, ret
  end

  def test_inline_ttb
    ret = @builder.compile_inline("test @<ttb>{inline test} test2")
    assert_equal %Q|test <tt><b>inline test</b></tt> test2|, ret
  end

  def test_inline_hd_chap
    def @chapter.headline_index
      items = [Book::HeadlineIndex::Item.new("chap1|test", [1, 1], "te_st")]
      Book::HeadlineIndex.new(items, self)
    end

    ret = @builder.compile_inline("test @<hd>{chap1|test} test2")
    assert_equal %Q|test 「1.1.1 te_st」 test2|, ret
  end

  def test_inline_uchar
    ret = @builder.compile_inline("test @<uchar>{2460} test2")
    assert_equal %Q|test &#x2460; test2|, ret
  end

  def test_inline_ruby
    ret = @builder.compile_inline("@<ruby>{粗雑,クルード}と思われているなら@<ruby>{繊細,テクニカル}にやり、繊細と思われているなら粗雑にやる。")
    assert_equal "<ruby><rb>粗雑</rb><rp>（</rp><rt>クルード</rt><rp>）</rp></ruby>と思われているなら<ruby><rb>繊細</rb><rp>（</rp><rt>テクニカル</rt><rp>）</rp></ruby>にやり、繊細と思われているなら粗雑にやる。", ret
  end

  def test_inline_ref
    ret = @builder.compile_inline("@<ref>{外部参照<>&}")
    assert_equal %Q|<a target='外部参照&lt;&gt;&amp;'>「●●　外部参照&lt;&gt;&amp;」</a>|, ret
  end

  def test_quote
    lines = ["foo", "bar", "","buz"]
    @builder.quote(lines)
    assert_equal %Q|<blockquote><p>foobar</p>\n<p>buz</p></blockquote>\n|, @builder.raw_result
  end

  def test_memo
    @builder.memo(["test1", "", "test<i>2</i>"], "this is @<b>{test}<&>_")
    assert_equal %Q|<div class="memo">\n<p class="caption">this is <b>test</b>&lt;&amp;&gt;_</p>\n<p>test1</p>\n<p>test<i>2</i></p>\n</div>\n|, @builder.raw_result
  end

  def test_noindent
    @builder.noindent
    @builder.paragraph(["foo", "bar"])
    @builder.paragraph(["foo2", "bar2"])
    assert_equal %Q|<p class="noindent">foobar</p>\n<p>foo2bar2</p>\n|, @builder.raw_result
  end

  def test_flushright
    @builder.flushright(["foo", "bar", "", "buz"])
    assert_equal %Q|<p class="flushright">foobar</p>\n<p class="flushright">buz</p>\n|, @builder.raw_result
  end

  def test_centering
    @builder.centering(["foo", "bar", "", "buz"])
    assert_equal %Q|<p class="center">foobar</p>\n<p class="center">buz</p>\n|, @builder.raw_result
  end

  def test_image
    def @chapter.image(id)
      item = Book::ImageIndex::Item.new("sampleimg",1)
      item.instance_eval{@pathes=["./images/chap1-sampleimg.png"]}
      item
    end

    @builder.image_image("sampleimg","sample photo",nil)
    assert_equal %Q|<div class="image">\n<img src="images/chap1-sampleimg.png" alt="sample photo" />\n<p class="caption">\n図1.1: sample photo\n</p>\n</div>\n|, @builder.raw_result
  end

  def test_image_with_metric
    def @chapter.image(id)
      item = Book::ImageIndex::Item.new("sampleimg",1)
      item.instance_eval{@pathes=["./images/chap1-sampleimg.png"]}
      item
    end

    @builder.image_image("sampleimg","sample photo","scale=1.2")
    assert_equal %Q|<div class="image">\n<img src="images/chap1-sampleimg.png" alt="sample photo" width="120%" />\n<p class="caption">\n図1.1: sample photo\n</p>\n</div>\n|, @builder.raw_result
  end

  def test_image_with_metric2
    def @chapter.image(id)
      item = Book::ImageIndex::Item.new("sampleimg",1)
      item.instance_eval{@pathes=["./images/chap1-sampleimg.png"]}
      item
    end
    @builder.image_image("sampleimg","sample photo","scale=1.2,html::class=sample,latex::ignore=params")
    assert_equal %Q|<div class="image">\n<img src="images/chap1-sampleimg.png" alt="sample photo" width="120%" class="sample" />\n<p class="caption">\n図1.1: sample photo\n</p>\n</div>\n|, @builder.raw_result
  end

  def test_indepimage
    def @chapter.image(id)
      item = Book::ImageIndex::Item.new("sampleimg",1)
      item.instance_eval{@pathes=["./images/chap1-sampleimg.png"]}
      item
    end

    @builder.indepimage("sampleimg","sample photo",nil)
    assert_equal %Q|<div class="image">\n<img src="images/chap1-sampleimg.png" alt="sample photo" />\n<p class="caption">\n図: sample photo\n</p>\n</div>\n|, @builder.raw_result
  end

  def test_indepimage_without_caption
    def @chapter.image(id)
      item = Book::ImageIndex::Item.new("sampleimg",1)
      item.instance_eval{@pathes=["./images/chap1-sampleimg.png"]}
      item
    end

    @builder.indepimage("sampleimg",nil,nil)
    assert_equal %Q|<div class="image">\n<img src="images/chap1-sampleimg.png" alt="" />\n</div>\n|, @builder.raw_result
  end

  def test_indepimage_with_metric
    def @chapter.image(id)
      item = Book::ImageIndex::Item.new("sampleimg",1)
      item.instance_eval{@pathes=["./images/chap1-sampleimg.png"]}
      item
    end

    @builder.indepimage("sampleimg","sample photo","scale=1.2")
    assert_equal %Q|<div class="image">\n<img src="images/chap1-sampleimg.png" alt="sample photo" width="120%" />\n<p class="caption">\n図: sample photo\n</p>\n</div>\n|, @builder.raw_result
  end

  def test_indepimage_with_metric2
    def @chapter.image(id)
      item = Book::ImageIndex::Item.new("sampleimg",1)
      item.instance_eval{@pathes=["./images/chap1-sampleimg.png"]}
      item
    end

    @builder.indepimage("sampleimg","sample photo","scale=1.2, html::class=\"sample\",latex::ignore=params")
    assert_equal %Q|<div class="image">\n<img src="images/chap1-sampleimg.png" alt="sample photo" width="120%" class="sample" />\n<p class="caption">\n図: sample photo\n</p>\n</div>\n|, @builder.raw_result
  end

  def test_indepimage_without_caption_but_with_metric
    def @chapter.image(id)
      item = Book::ImageIndex::Item.new("sampleimg",1)
      item.instance_eval{@pathes=["./images/chap1-sampleimg.png"]}
      item
    end

    @builder.indepimage("sampleimg",nil,"scale=1.2")
    assert_equal %Q|<div class="image">\n<img src="images/chap1-sampleimg.png" alt="" width="120%" />\n</div>\n|, @builder.raw_result
  end

  def test_emlist
    @builder.emlist(["lineA","lineB"])
    assert_equal %Q|<div class="emlist-code">\n<pre class="emlist">lineA\nlineB\n</pre>\n</div>\n|, @builder.raw_result
  end

  def test_emlist_caption
    @builder.emlist(["lineA","lineB"],"cap1")
    assert_equal %Q|<div class="emlist-code">\n<p class="caption">cap1</p>\n<pre class="emlist">lineA\nlineB\n</pre>\n</div>\n|, @builder.raw_result
  end

  def test_emlist_with_tab
    @builder.emlist(["\tlineA","\t\tlineB","\tlineC"])
    assert_equal %Q|<div class="emlist-code">\n<pre class="emlist">        lineA\n                lineB\n        lineC\n</pre>\n</div>\n|, @builder.raw_result
  end

  def test_emlist_with_4tab
    @builder.instance_eval{@tabwidth=4}
    @builder.emlist(["\tlineA","\t\tlineB","\tlineC"])
    assert_equal %Q|<div class="emlist-code">\n<pre class="emlist">    lineA\n        lineB\n    lineC\n</pre>\n</div>\n|, @builder.raw_result
  end

  def test_cmd
    @builder.cmd(["lineA","lineB"])
    assert_equal %Q|<div class="cmd-code">\n<pre class="cmd">lineA\nlineB\n</pre>\n</div>\n|, @builder.raw_result
  end

  def test_cmd_caption
    @builder.cmd(["lineA","lineB"], "cap1")
    assert_equal %Q|<div class="cmd-code">\n<p class="caption">cap1</p>\n<pre class="cmd">lineA\nlineB\n</pre>\n</div>\n|, @builder.raw_result
  end

  def test_bib
    def @chapter.bibpaper(id)
      Book::BibpaperIndex::Item.new("samplebib",1,"sample bib")
    end

    assert_equal %Q|<a href="./bib.html#bib-samplebib">[1]</a>|, @builder.inline_bib("samplebib")
  end

  def test_bibpaper
    def @chapter.bibpaper(id)
      Book::BibpaperIndex::Item.new("samplebib",1,"sample bib")
    end

    @builder.bibpaper(["a", "b"], "samplebib", "sample bib @<b>{bold}")
    assert_equal %Q|<div>\n<a id=\"bib-samplebib\">\n[1] sample bib <b>bold</b>\n</a>\n<p>\na\nb\n</p>\n</div>\n|, @builder.raw_result
  end

  def column_helper(review)
    chap_singleton = class << @chapter; self; end
    chap_singleton.send(:define_method, :content) { review }
    @compiler.compile(@chapter).match(/<body>\n(.+)<\/body>/m)[1]
  end

  def test_column_1
    review =<<-EOS
===[column] prev column

inside prev column

===[column] test

inside column

===[/column]
EOS
    expect =<<-EOS
<div class="column">

<h3><a id="h1-0-1" />prev column</h3>
<p>inside prev column</p>
</div>
<div class="column">

<h3><a id="h1-0-2" />test</h3>
<p>inside column</p>
</div>
EOS
    assert_equal expect, column_helper(review)
  end

  def test_column_2
    review =<<-EOS
===[column] test

inside column

=== next level
EOS
    expect =<<-EOS
<div class="column">

<h3><a id="h1-0-1" />test</h3>
<p>inside column</p>
</div>

<h3><a id="h1-0-2" />next level</h3>
EOS

    assert_equal expect, column_helper(review)
  end

  def test_column_3
    review =<<-EOS
===[column] test

inside column

===[/column_dummy]
EOS
    assert_raise(ReVIEW::CompileError) do
      column_helper(review)
    end
  end

  def test_ul
    src =<<-EOS
  * AAA
  * BBB
EOS
    expect = "<ul>\n<li>AAA</li>\n<li>BBB</li>\n</ul>\n"
    ul_helper(src, expect)
  end

  def test_ul_cont
    src =<<-EOS
  * AAA
    -AA
  * BBB
    -BB
EOS
    expect = "<ul>\n<li>AAA-AA</li>\n<li>BBB-BB</li>\n</ul>\n"
    ul_helper(src, expect)
  end

  def test_ul_nest1
    src =<<-EOS
  * AAA
  ** AA
EOS

    expect =<<-EOS
<ul>
<li>AAA<ul>
<li>AA</li>
</ul>
</li>
</ul>
EOS
    ul_helper(src, expect)
  end

  def test_ul_nest2
    src =<<-EOS
  * AAA
  ** AA
  * BBB
  ** BB
EOS

    expect =<<-EOS
<ul>
<li>AAA<ul>
<li>AA</li>
</ul>
</li>
<li>BBB<ul>
<li>BB</li>
</ul>
</li>
</ul>
EOS
    ul_helper(src, expect)
  end

  def test_ul_nest3
    src =<<-EOS
  ** AAA
  * AA
  * BBB
  ** BB
EOS

    expect =<<-EOS
<ul>
<li><ul>
<li>AAA</li>
</ul>
</li>
<li>AA</li>
<li>BBB<ul>
<li>BB</li>
</ul>
</li>
</ul>
EOS
    ul_helper(src, expect)
  end

  def test_inline_raw0
    assert_equal "normal", @builder.inline_raw("normal")
  end

  def test_inline_raw1
    assert_equal "body", @builder.inline_raw("|html|body")
  end

  def test_inline_raw2
    assert_equal "body", @builder.inline_raw("|html, latex|body")
  end

  def test_inline_raw3
    assert_equal "", @builder.inline_raw("|idgxml, latex|body")
  end

  def test_inline_raw4
    assert_equal "|html body", @builder.inline_raw("|html body")
  end

  def test_inline_raw5
    assert_equal "nor\nmal", @builder.inline_raw("|html|nor\\nmal")
  end

  def test_block_raw0
    @builder.raw("<>!\"\\n& ")
    expect =<<-EOS
<>!"
& 
EOS
    assert_equal expect.chomp, @builder.raw_result
  end

  def test_block_raw1
    @builder.raw("|html|<>!\"\\n& ")
    expect =<<-EOS
<>!"
& 
EOS
    assert_equal expect.chomp, @builder.raw_result
  end

  def test_block_raw2
    @builder.raw("|html, latex|<>!\"\\n& ")
    expect =<<-EOS
<>!\"
& 
EOS
    assert_equal expect.chomp, @builder.raw_result
  end

  def test_block_raw3
    @builder.raw("|latex, idgxml|<>!\"\\n& ")
    expect =<<-EOS
EOS
    assert_equal expect.chomp, @builder.raw_result
  end

  def test_block_raw4
    @builder.raw("|html <>!\"\\n& ")
    expect =<<-EOS
|html <>!\"
& 
EOS
    assert_equal expect.chomp, @builder.raw_result
  end

  def test_inline_fn
    fn = Book::FootnoteIndex.parse(['//footnote[foo][bar\\a\\$buz]'])
    @chapter.instance_eval{@footnote_index=fn}
    @builder.footnote("foo",'bar\\a\\$buz')
    expect =<<-'EOS'
<div class="footnote"><p class="footnote">[<a id="fn-foo">*1</a>] bar\a\$buz</p></div>
EOS
    assert_equal expect, @builder.raw_result
  end
end
