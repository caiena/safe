require 'spec_helper'

describe SAFE do
  describe ".safefile" do
    let(:path) { Pathname("/tmp/Safefile.rb") }

    context "Safefile is missing from pwd" do
      it "returns nil" do
        path.delete if path.exist?
        SAFE.configuration.safefile = path

        expect(SAFE.safefile).to eq(nil)
      end
    end

    context "Safefile exists" do
      it "returns Pathname to it" do
        FileUtils.touch(path)
        SAFE.configuration.safefile = path
        expect(SAFE.safefile).to eq(path.realpath)
        path.delete
      end
    end
  end

  describe ".root" do
    it "returns root directory of SAFE" do
      expected = Pathname.new(__FILE__).parent.parent
      expect(SAFE.root).to eq(expected)
    end
  end

  describe ".configure" do
    it "runs block with config instance passed" do
      expect { |b| SAFE.configure(&b) }.to yield_with_args(SAFE.configuration)
    end
  end

end
