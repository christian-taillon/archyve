# tests shouldn't be hitting a real server and waiting for responses; flakey and slow
# flakiness example:
#   expected " The sky looks blue because tiny bits of things called dust and gas reflect a special type of light called blue light back to our eyes." to include "scatter"
RSpec.describe LlmClients::Ollama::Client, :skip do
  subject { described_class.new(endpoint:, api_key:, embedding_model:, model:, temperature:) }

  let(:endpoint) { 'http://localhost:11434' }
  let(:api_key) { 'fake-api-key' }
  let(:embedding_model) { 'nomic-embed-text' }
  let(:model) { 'mistral:instruct' }
  let(:temperature) { 0.1 }
  let(:content) { 'Any old content' }

  describe "#embed" do
    let(:result) { subject.embed(content) }

    it "returns an embedding" do
      expect(result['embedding']).to be_a(Array)
    end
  end

  describe "#complete" do
    completion = nil # what is this line doing?
    let(:result) { completion } # lazy
    let(:content) { 'General relativity was conceived by' }

    before do
      subject.complete(content) do |str|
        completion = str
      end
    end

    it "yields a string" do
      expect(result).to be_a(String)
    end

    it "identifies 'Einstein' within completion" do
      expect(result).to include("Einstein")
    end
  end

  describe "#chat" do
    response = nil # what is this line doing?
    let(:result) { response } # lazy
    let(:content) { 'Please explain why the sky is blue in a single sentence suitable for a child who is five years old.' }

    let(:conversation) { create(:conversation, messages: []) }

    before do
      msg = create(:message, content:, conversation:)
      response = ""
      subject.chat(msg) do |str|
        response << str
      end
    end

    it "yields a non-empty string" do
      expect(response.size).to be > 0
    end

    it "identifies 'scatter' in the answer" do
      expect(result).to include("scatter")
    end
  end
end
