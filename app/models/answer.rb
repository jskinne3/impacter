require 'elasticsearch/model'

class Answer < ApplicationRecord
  belongs_to :knock
  belongs_to :question

  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  settings index: { number_of_shards: 1 } do
    mappings dynamic: 'false' do
      indexes :short_answer, analyzer: 'english'
      indexes :notes, analyzer: 'english'
    end
  end

  def self.search(query)
    __elasticsearch__.search(
      {
        query: {
          multi_match: {
            query: query,
            fields: ['short_answer', 'notes']
          }
        },
        size: 100,
        highlight: {
          fragment_size: 500,
          pre_tags: ['<em>'],
          post_tags: ['</em>'],
          fields: {
          	short_answer: {},
            notes: {}
          }
        }
      }
    )
  end

  # Delete the previous index in Elasticsearch
  Answer.__elasticsearch__.client.indices.delete index: Answer.index_name rescue nil

  # Create the new index with the new mapping
  Answer.__elasticsearch__.client.indices.create \
  index: Answer.index_name,
  body: { settings: Answer.settings.to_hash, mappings: Answer.mappings.to_hash }

  # Index all records from the DB to Elasticsearch
  Answer.import
end
