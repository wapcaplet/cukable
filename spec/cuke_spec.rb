require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Cukable::Cuke do
  before(:each) do
    @cuke = Cukable::Cuke.new
  end

  context "#clean_filename" do
    it "should convert path separators to underscores" do
      @cuke.clean_filename('some/path/name', '', '').should == 'some_path_name'
    end

    it "should remove prefix and suffix" do
      @cuke.clean_filename('abc/some/path/xyz', 'abc', 'xyz').should == 'some_path'
    end
  end


  context "#remove_cruft" do
    it "should remove anchor tags and keep the content" do
      string = 'Go to <a href="SomePage">this page</a>'
      expect = 'Go to this page'
      @cuke.remove_cruft(string).should == expect
    end

    it "should remove [?] content" do
      string = 'See SomePage<a href="SomePage">[?]</a>'
      expect = 'See SomePage'
      @cuke.remove_cruft(string).should == expect
    end
  end


  context "#table_digest" do
    it "should return the same digest for identical input" do
      table1 = [
        ["Name", "Quest"],
        ["Arthur", "Holy Grail"],
        ["Bevedere", "Holy Grail"],
      ]
      table2 = [
        ["Name", "Quest"],
        ["Arthur", "Holy Grail"],
        ["Bevedere", "Holy Grail"],
      ]
      @cuke.table_digest(table1).should == @cuke.table_digest(table2)
    end

    it "should return different digest for different input" do
      table1 = [
        ["Name", "Quest"],
        ["Arthur", "Holy Grail"],
        ["Bevedere", "Holy Grail"],
      ]
      table2 = [
        ["Name", "Quest"],
        ["Arthur", "Holy Grail"],
        ["Lancelot", "Holy Grail"],
      ]
      @cuke.table_digest(table1).should_not == @cuke.table_digest(table2)
    end
  end

end
