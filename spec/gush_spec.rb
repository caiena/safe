require 'spec_helper'

describe Gush do
  describe ".gushfile" do
    let(:path) { Pathname("/tmp/Gushfile.rb") }

    context "Gushfile is missing from pwd" do
      it "returns nil" do
        path.delete if path.exist?
        Gush.configuration.gushfile = path

        expect(Gush.gushfile).to eq(nil)
      end
    end

    context "Gushfile exists" do
      it "returns Pathname to it" do
        FileUtils.touch(path)
        Gush.configuration.gushfile = path
        expect(Gush.gushfile).to eq(path.realpath)
        path.delete
      end
    end
  end

  describe ".root" do
    it "returns root directory of Gush" do
      expected = Pathname.new(__FILE__).parent.parent
      expect(Gush.root).to eq(expected)
    end
  end

  describe ".configure" do
    it "runs block with config instance passed" do
      expect { |b| Gush.configure(&b) }.to yield_with_args(Gush.configuration)
    end
  end

end
