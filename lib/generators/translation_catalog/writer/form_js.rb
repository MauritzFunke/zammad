# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Generators::TranslationCatalog::Writer::FormJs < Generators::TranslationCatalog::Writer::Base

  def write_catalog(strings, references)

    # Only execute for Zammad, not for addons.
    return if options['addon_path']

    # Do not run in CI.
    return if options['check']

    content = serialized(translation_map(strings, references))
    write_file('public/assets/form/form.js', content)
  end

  private

  def write_file(file, content)
    target_file = Rails.root.join(file)
    before = target_file.read
    puts "Writing form asset file #{target_file}." # rubocop:disable Rails/Output
    after = before.sub(%r{(// ZAMMAD_TRANSLATIONS_START\n).*(    // ZAMMAD_TRANSLATIONS_END)}m) do |_match|
      $1 + content + $2
    end
    target_file.write(after)
  end

  def serialized(map)
    string = ''
    map.keys.sort.each do |locale|
      string += "      '#{locale}': {\n"
      map[locale].keys.sort.each do |source|
        string += "        '#{escape_for_js(source)}': '#{escape_for_js(map[locale][source])}',\n"
      end
      string += "      },\n"
    end
    string
  end

  def translation_map(_strings, references)
    sources = source_strings(references)
    map = {}
    Locale.all.each do |locale|
      next if locale.locale.start_with?('en')

      trans = translations(sources, locale.locale)

      map[locale.alias.presence || locale.locale] = trans if trans.present?
    end
    map
  end

  def source_strings(references)
    references.select do |_k, v|
      v.count { |f| f.include?('public/assets/form/') }.positive?
    end.keys.sort
  end

  def translations(sources, locale)
    string_map = Translation.strings_for_locale(locale).select do |source, _entry|
      sources.include?(source)
    end.transform_values(&:translation)

    # Add strings that might be missing from translation file.
    (sources - string_map.keys).each do |missing_source|
      string_map[missing_source] = ''
    end

    return if string_map.values.any?(&:blank?)

    string_map
  end
end
