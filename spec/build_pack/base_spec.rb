require 'spec_helper'

describe BuildPack::Base do
  let(:application_path) { '/workspace/myapp' }
  let(:cache_path) { '/workspace/myapp/cache' }
  let(:buildpack) { 
    Dir.should_receive(:chdir).with(application_path).once
    BuildPack::Base.new(application_path, cache_path) 
  }
  
  it "should set application path from first arg" do
    Dir.should_receive(:chdir).with(application_path).once
    BuildPack::Base.new(application_path).build_path.should == application_path
  end
  
  it "should set cache path from second arg" do
    Dir.should_receive(:chdir).with(application_path).once
    BuildPack::Base.new(application_path, cache_path).cache_path.should == cache_path
  end
  
  describe "#name" do
    it "should require it to be subclassed" do
      doing { buildpack.name }.should raise_error(NotImplementedError)
    end
  end
  
  describe "#default_config_vars" do
    it "should require it to be subclassed" do
      doing { buildpack.default_config_vars }.should raise_error(NotImplementedError)
    end
  end
  
  describe ".===" do
    it "should require it to be subclassed" do
      doing { BuildPack::Base === BuildPack::Base }.should raise_error(NotImplementedError)
    end
  end
  
  describe "#compile" do
    it "should require it to be subclassed" do
      doing { buildpack.compile }.should raise_error(NotImplementedError)
    end
  end
  
  describe "cache" do
    it "should return a standard Pathname object for cache path" do
      buildpack.send(:cache_base).should be_a Pathname
    end
  end
  
end