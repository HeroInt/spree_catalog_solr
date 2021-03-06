module SpreeCatalogSolr
  module Indexable
    def self.included(base)
      base.class_eval do
        extend MakeItIndexable
        include SpreeCatalogSolr::Methods
      end
    end

    module MakeItIndexable
      def make_me_indexable
        searchable(auto_index: false, auto_remove: false) do
          integer :id, stored: true
          integer :taxon_ids, stored: true, multiple: true do
            taxons.map(&:id)
          end

          double :price, stored: true

          text :name, stored: true
          string :name_sort, stored: true do
            name.downcase
          end
          text :description, stored: true
          string :slug, stored: true
          string :state, stored: true
          text :meta_description, stored: true
          string :primary_image, stored: true do
            images.first.attachment.url(:large) if images.any?
          end
          string :primary_image_thumb, stored: true do
            images.first.attachment.url(:small) if images.any?
          end
          string :taxons, stored: true, multiple: true do
            taxons.map(&:permalink)
          end
          string :taxons_with_parent, stored: true, multiple: true do
            Spree::Taxon
                .select('distinct spree_taxons.*')
                .joins('inner join spree_taxons parent on parent.lft between spree_taxons.lft and spree_taxons.rgt')
                .where('parent.id in (?)', taxons.map(&:id)).collect {|taxon| taxon.permalink.split('/').last(2).join('-')}
          end


          string :similar_products_ids, stored: true do
            related_products_ids(:similar).to_json
          end

          string :master, stored: true do
            SpreeCatalogSolr::Utils.build_variant_hash(master).to_json
          end

          string :variants, stored: true, multiple: true do
            variants_and_option_values.collect do |v|
              SpreeCatalogSolr::Utils.build_variant_hash(v).to_json
            end
          end

          string :option_types, stored: true do
            option_types.includes(:option_values).collect do |option_type|
              {
                  id: option_type.id,
                  name: option_type.name,
                  presentation: option_type.presentation,
                  position: option_type.position,
                  option_values: option_type.option_values
              }
            end.to_json
          end

          string :product_properties, stored: true do
            product_properties.collect do |property|
              {
                  id: property.id,
                  name: property.property.name,
                  value: property.value
              }
            end.to_json
          end

          SpreeCatalogSolr::Config[:extra_fields].each do |field|
            send field[:type], field[:name], stored: true
          end

        end
      end
    end
  end
end
