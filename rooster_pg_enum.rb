require 'active_record'
require 'active_support/concern'

# Using postgresql enums? Use this to automatically handle validations and
# retriving the list of valid values of the enum.
#
# Usage:
#
=begin
 class Refund < ActiveRecord::Base
   include Rooster::PgEnum
   # :action_taken is the name of a column in the refunds table that has
   # a type of some enum.
   pg_enum :action_taken
 end
=end
#
# Also, to get a list of valid values for the `action_taken` column, do:
#
#   Refund.enum_values_for(:action_taken)
#
# This will return an array of valid values for the enum.
#
# This also sets up a scope for filtering based off valid enums.
#   Refund.action_taken('other')
# is the same as
#   Refund.where(:action_taken => 'other')
#
# Using an invalid value for the scope will raise an exception.

module Rooster
  module PgEnum
    extend ActiveSupport::Concern
    module ClassMethods
      # Fetch the valid values of the enum, setup the validations.
      def pg_enum enum_name, options={}
        raise_errors = options[:raise_errors] || false

        # If raise_errors set to true, use `validates!`. Otherwise, use `validates`
        validation_method = raise_errors ? "validates!" : "validates"

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

        send validation_method, enum_name, options

        # Define a method that returns the valid enum values.
        # (could be used in select boxes, for example)
        define_singleton_method :enum_values_for do |enum_name|
          valid_items
        end

        scope enum_name, lambda { |value|
          if !valid_items.include?(value)
            raise ArgumentError.new("'#{value}' not a valid enum value (valid ones: #{valid_items.inspect})")
          end
          where(enum_name => value)
        }
      end
    end
  end
end


# From https://github.com/RISCfuture/enum_type/blob/master/lib/enum_type/extensions.rb
# Patches AR to correctly set the default.
class ActiveRecord::ConnectionAdapters::PostgreSQLColumn
  def initialize(name, default, sql_type = nil, null = true)
    super(name, self.class.extract_value_from_default(default, sql_type), sql_type, null)
  end

  def self.extract_value_from_default_with_enum(default, type)
    case default
      when /\A'(.*)'::(?:#{Regexp.escape type})\z/
        $1
      else
        extract_value_from_default_without_enum default
    end
  end

  class << self
    alias_method_chain :extract_value_from_default, :enum
  end
end if ActiveRecord::ConnectionAdapters::PostgreSQLColumn.methods.include?(:extract_value_from_default)
