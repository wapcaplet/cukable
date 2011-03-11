require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Cukable::Converter, "#wikify" do
  it "strips underscores" do
    wikify("name_with_underscore").should == "NameWithUnderscore"
  end

  it "strips spaces" do
    wikify("name with spaces").should == "NameWithSpaces"
  end

  it "strips periods" do
    wikify("name.with.periods").should == "NameWithPeriods"
  end
end


describe Cukable::Converter, "#feature_hierarchy" do
end


describe Cukable::Converter, "#wikify_path" do
  it "appends Dir to directories" do
    wikify_path("features/basic/some.feature").should == "FeaturesDir/BasicDir/SomeFeature"
  end
end


describe Cukable::Converter, "#features_to_wiki" do
  it "converts .feature path names to FitNesse wiki path names" do
    features = [
      'features/guitar/tune.feature',
      'features/guitar/play.feature',
    ]
    wikis = [
      'FeaturesDir/GuitarDir/TuneFeature',
      'FeaturesDir/GuitarDir/PlayFeature',
    ]
    features_to_wiki(features).should == wikis
  end
end


describe Cukable::Converter, "#sanitize" do
  it "escapes CamelCase words with string-literal markup" do
    sanitize("Has a CamelCase word").should == "Has a !-CamelCase-! word"
  end
end
