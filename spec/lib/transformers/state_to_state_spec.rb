# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transformers::StateToState do
  let(:manifest) { create :manifest }
  let(:user) { create :user }
  let(:transformer) do
    Transformers::StateToState.new(
      manifest_model: manifest, current_user: user, state:
      { schema: material_schema, content: { structured: {} }, mapping: {} }
    )
  end

  context '#transform' do
    let(:material_schema) do
      { 'properties' => { 'scientific_name' => { 'required' => true }, 'concentration' => { 'required' => false } } }
    end

    before do
      allow(MatconClient::Material).to receive(:schema).and_return(material_schema)
    end
    context 'when file is parsed' do
      it 'returns a valid state' do
        expect(transformer.transform[:content][:structured].nil?).to eq(false)
      end
    end
  end
end
