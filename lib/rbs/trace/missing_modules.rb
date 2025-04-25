# frozen_string_literal: true

require "stringio"

module RBS
  class Trace
    class MissingModules
      include Helpers

      def initialize(decls)
        @decls = decls
        @missing_decls = []
      end

      def to_rbs
        extract_namespaces_paths.each do |path|
          collect_missing_modules path
        end

        out = StringIO.new
        writer = Writer.new(out:)
        writer.write(@missing_decls)

        out.string
      end

      # @rbs (String) -> void
      def save_rbs(out_dir, name = "_missing_modules.rbs")
        rbs_path = Pathname(out_dir) / name

        rbs_path.parent.mkpath unless rbs_path.parent.exist?
        rbs_path.write(to_rbs)
      end

      private

      def extract_namespaces_paths = @decls.map { |d| d.name.namespace.path }.uniq

      def collect_missing_modules(path)
        path.each.with_object [] do |name, parents|
          unless defined_modules.include?([*parents, name])
            namespace = RBS::Namespace.new(path: parents.dup, absolute: true)
            @missing_decls << new_module_decl(name: RBS::TypeName.new(namespace:, name:))
          end

          parents << name
        end
      end

      def defined_modules
        @defined_modules ||= @decls.to_set { |d| d.name.to_namespace.path }
      end
    end
  end
end
