require 'cucumber/formatter/html'

require 'fileutils'
require 'nokogiri'
require 'uri'
require 'open-uri'
require 'net/ftp'   # For Net::FTPPermError

module Butternut
  class Formatter < Cucumber::Formatter::Html

    def initialize(step_mother, io, options)
      # find the format options
      format = options[:formats].detect { |(name, _)| name == "Butternut::Formatter" }
      if !format || !format[1].is_a?(String)
        raise "Butternut::Formatter cannot output to STDOUT"
      end
      out = format[1]

      super
      if File.directory?(out)
        #@assets_dir = out
        #@assets_url = "."
      else
        basename = File.basename(out).sub(/\..*$/, "")
        @assets_dir = File.join(File.dirname(out), basename)
        @assets_url = basename
        if !File.exist?(@assets_dir)
          FileUtils.mkdir(@assets_dir)
        end
      end
    end

    def before_feature_element(feature_element)
      super
      @feature_element = feature_element
    end

    def after_step_result(keyword, step_match, multiline_arg, status, exception, source_indent, background)
      return if @hide_this_step
      # print snippet for undefined steps
      if status == :undefined
        step_multiline_class = @step.multiline_arg ? @step.multiline_arg.class : nil
        @builder.pre do |pre|
          pre << @step_mother.snippet_text(@step.actual_keyword,step_match.instance_variable_get("@name") || '',step_multiline_class)
        end
      end
      add_page_source_link(@builder)
      @builder << '</li>'
    end

    private
      def add_page_source_link(builder)
        if !@feature_element.respond_to?(:last_page_source) || @feature_element.last_page_source.nil?
          # don't add a link of we haven't interacted with a webpage
          return
        end

        page_source = @feature_element.last_page_source
        page_url = @feature_element.last_page_url
        @feature_element.last_page_source = nil
        @feature_element.last_page_url = nil

        page_source = transform_page_source(page_source, page_url)
        path = source_file_name
        File.open(path, "w") { |f| f.print(page_source) }

        builder.a({:target => "_blank", :href => "#{@assets_url}/#{File.basename(path)}"}) do
          builder << "Source"
        end
      end

      def source_file_name
        t = Time.now.strftime("%Y%m%d")
        path = nil
        while path.nil?
          path = File.join(@assets_dir, "butternut#{t}-#{$$}-#{rand(0x100000000).to_s(36)}.html")
          path = nil if File.exist?(path)
        end
        path
      end

      def transform_page_source(page_source, page_url)
        base_uri = URI.parse(page_url)
        base_uri.query = nil
        @already_collected = []

        doc = Nokogiri.HTML(page_source)
        { :image      => ['img', 'src'],
          :stylesheet => ['link[rel=stylesheet]', 'href']
        }.each_pair do |type, (selector, attr)|
          doc.css(selector).each do |elt|
            elt_url = elt[attr]
            next  if elt_url.nil? || elt_url.empty?

            result = save_remote_file(base_uri, type, elt_url)
            elt[attr] = result  if result
          end
        end

        # disable links
        doc.css('a').each { |link| link['href'] = "#" }

        # turn off scripts
        doc.css('script').each { |s| s.unlink }

        # disable form elements
        doc.css('input, select, textarea').each { |x| x['disabled'] = 'disabled' }

        doc.to_s
      end

      def transform_stylesheet(stylesheet_uri, content)
        content.gsub(%r{url\(([^\)]+)\)}) do |_|
          result = save_remote_file(stylesheet_uri, :image, $1)
          "url(#{result || $1})"
        end
      end

      def save_remote_file(base_uri, type, url)
        # FIXME: two different files could have the same basename :)
        begin
          uri = URI.parse(url)
        rescue URI::InvalidURIError
          return nil
        end
        remote_uri = uri.absolute? ? uri : base_uri.merge(uri)
        basename   = File.basename(uri.path)

        unless @already_collected.include?(remote_uri)
          begin
            content = open(remote_uri.to_s).read
            content = transform_stylesheet(remote_uri, content) if type == :stylesheet
            local_path = File.join(@assets_dir, basename)
            File.open(local_path, "w") { |f| f.write(content) }
            @already_collected << remote_uri
          rescue IOError, Errno::ENOENT, OpenURI::HTTPError, Net::FTPPermError
            return nil
          end
        end
        basename
      end
  end
end
