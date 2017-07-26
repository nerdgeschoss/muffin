module Muffin
  module Sync
    private

    def update_nested!(relation, entities = [self])
      entities = Array.wrap(entities)

      # load all (available) records upfront to avoid fetching them one by one in the loop
      records = (relation.is_a?(ActiveRecord::Base) ? relation.class : relation)
        .where(id: entities.map(&:id).compact)
        .each_with_object({}) { |record, hash| hash[record.id] = record }

      entities.each do |entity|
        association_attributes = {}
        model_attributes = {}
        record = nil

        entity.attributes.except(:_destroy).each do |k, v|
          if Array.wrap(v).any? { |e| e.is_a?(Muffin::NestedAttribute) }
            association_attributes[k] = v
          else
            model_attributes[k] = v
          end
        end

        if entity.try(:id).presence
          record = records[entity.id]

          if entity.try(:_destroy).presence
            record.destroy
          else
            record.assign_attributes(model_attributes)
            record.save! if record.changed?
          end
        else
          record = relation.create!(model_attributes)
        end

        association_attributes.each do |k, v|
          update_nested!(record.send(k), v)
        end
      end

      relation.reload # avoid caching effects like "stale" attributes after updates
    end
  end
end
