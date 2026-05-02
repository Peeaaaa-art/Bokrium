# frozen_string_literal: true

# This migration comes from acts_as_taggable_on_engine (originally 7)
class AddTenantToTaggings < ActiveRecord::Migration[6.0]
  def self.up
    add_column :taggings, :tenant, :string, limit: 128
    add_index :taggings, :tenant unless index_exists? :taggings, :tenant
  end

  def self.down
    remove_index :taggings, :tenant
    remove_column :taggings, :tenant
  end
end
