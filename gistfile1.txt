# Using postgresql enums? Use this to automatically handle validations and
# retriving the list of valid values of the enum.
# Usage:
=begin
 class Refund < ActiveRecord::Base
   include Rooster::PgEnum
   # :action_taken is the name of a column in the refunds table that has
   # a type of some enum.
   pg_enum :action_taken
 end
=end
# Also, to get a list of valid values for the `action_taken` column, do:
#   refund.enum_values_for(:action_taken)
# This will return an array of valid values for the enum.
module Rooster
  module PgEnum
    extend ActiveSupport::Concern
    module ClassMethods
      # Fetch the valid values of the enum, setup the validations.
      def pg_enum enum_name
        column = columns.find { |c| c.name == enum_name.to_s }
        sql_type = column.sql_type
        # TODO worry about quoting
        sql = "
        select e.enumlabel::text
        from pg_type t
           join pg_enum e on t.oid = e.enumtypid
           join pg_catalog.pg_namespace n ON n.oid = t.typnamespace
        where t.typname = '#{sql_type}'
        "
        valid_items = connection.query(sql).flatten
        options = { :inclusion => valid_items }

        if column.null
          options[:allow_nil] = true
        end

        validates! enum_name, options

        # Define a method that returns the valid enum values.
        # (could be used in select boxes, for example)
        define_method :enum_values_for do |enum_name|
          valid_items
        end
      end
    end
  end
end