require 'spec_helper'

describe BuildPack do
  
  it "should not return anything if working directory is not provided" do
    BuildPack.detect(nil, nil).should be_nil
  end
  
  it "should raise an error if working directory is invalid" do
    doing { BuildPack.detect('/nowhere') }.should raise_error(Errno::ENOENT)
  end
  
  it "should be detectable" do
    application_dir = '/workspace/myapp'
    Dir.should_receive(:chdir).with(application_dir).at_least(:once)
    BuildPack::Ruby.should_receive(:use?).once.and_return(true)
    
    BuildPack.detect(application_dir).should be_a BuildPack::Ruby
  end
  
  it "should return nil if build pack doesn't support this project type" do
    application_dir = '/workspace/myapp'
    Dir.should_receive(:chdir).with(application_dir).at_least(:once)
    BuildPack::Ruby.should_receive(:use?).once.and_return(false)
    
    BuildPack.detect(application_dir).should be_nil
  end
end
