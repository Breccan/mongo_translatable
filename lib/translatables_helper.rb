module TranslatablesHelper
  def available_in_locales_for(translatable, options = {})
    return if TranslationsHelper.available_locales.size < 2

    html = "<ul style='list-style:none; margin:0; padding:0;'>"
    html += "<li style='float:left;'>#{I18n.t('translations.helpers.available_in')}</li>"

    translatable.available_in_these_locales.each_with_index do |locale, index|
      styles = "float: left; padding: 0 5px; #{'border-left: 1px solid #000' unless index == 0}"
      onclick = 'update_translation_box(this); return false' if options[:lightbox]
      html += content_tag(:li, :style => styles) do
        link_to_unless_current(TranslationsHelper::available_locales[locale],
          url_for(:locale => locale, :to_locale => (params[:to_locale] if defined?(params))),
          { :onclick => onclick })
      end
    end

    manage_link = link_to(I18n.t('translations.helpers.manage'), {
      :controller => :translations, :action => :index,
      translatable_key_from(translatable) => translatable
    })

    html += "<li style='float:left; padding-left: 25px;'>(#{manage_link})</li>"
    html += '</ul>'
    html += "<div style='clear:both;'></div>"

    translatable_lightbox_js_and_css if options[:lightbox]
    google_auto_translatable_js

    html
  end

  def needed_in_locales_for(translatable, options = {})
    return if TranslationsHelper.available_locales.size < 2

    html = "<ul style='list-style:none; margin:0; padding:0;'>"
    html += "<li style='float:left;'>#{I18n.t('translations.helpers.needs_translating_to')}</li>"

    needed_locales = translatable.needed_in_these_locales
    return unless needed_locales.any?

    needed_locales.each_with_index do |locale, index|
      styles = "float: left; padding: 0 10px; #{'border-left: 1px solid #000' unless index == 0}"
      onclick = 'update_translation_box(this); return false' if options[:lightbox]
      html += content_tag(:li, :style => styles) do
        link_to(TranslationsHelper::available_locales[locale],
                { :action => :new,
                :controller => :translations,
                translatable_key_from(translatable) => translatable,
                :to_locale => locale }, { :onclick => onclick })
      end
    end

    html += '</ul>'
    html += "<div style='clear:both;'></div>"

    translatable_lightbox_js_and_css if options[:lightbox]
    google_auto_translatable_js

    html
  end

  def translatable_key_from(translatable)
    translatable.class.name.tableize.singularize + '_id'
  end

  def translatable_lightbox_js_and_css
    return if @translatable_lightbox_js_and_css_inserted

    js = javascript_tag("
    function close_open_translation_box() {
      if ($('translate_outer_box')) { $('translate_outer_box').remove(); }
      if ($('translate_inner_box')) { $('translate_inner_box').remove(); }
    }

    function update_translation_box(element) {
      new Ajax.Request(element.href, {
        method: 'get',
        onComplete: function(transport) {
          var outer_dimensions = document.body.getDimensions();
          var outer_box = new Element('div', { 'id': 'translate_outer_box' }).setOpacity(0.8).setStyle({ width: outer_dimensions['width'] + 'px', height: outer_dimensions['height'] + 'px' });
          var close_link = '<a href=\\'\\' name=\\'top\\' title=\\'Close\\' onclick=\\'close_open_translation_box(); return false;\\'>#{I18n.t('translations.helpers.close_box')}</a>';
          var close_box = '<div id=\\'translate_close_box\\'>' + close_link + '</div>';
          var inner_box = new Element('div', { 'id': 'translate_inner_box' }).update(close_box + transport.responseText);
          close_open_translation_box();
          document.body.appendChild(outer_box);
          document.body.appendChild(inner_box);
          window.location.hash = 'top'; // send us to the top of the translation box
          window.onresize = function() {
            var dimensions = document.body.getDimensions();
            $('translate_outer_box').setStyle({ width: dimensions['width'] + 'px', height: dimensions['height'] + 'px' });
          }
        }
      });
    }
    ")

    css = content_tag("style", :type => "text/css") do
      <<-CSS
      #translate_outer_box { position: absolute; top: 0; left: 0; width: 100%; height: 500px; background-color: #000; }
      #translate_inner_box { position: absolute; top: 0; left: 0; margin: 50px 20%; padding: 20px; background-color: #fff;
                             -moz-border-radius: 1em; -webkit-border-radius: 1em; }
      #translate_close_box { float: right; margin-top: -45px; margin-right: -15px; }
      #translate_close_box a { color: #fff; }
      CSS
    end

    @translatable_lightbox_js_and_css_inserted = true
    content_for(:add_on_scripts_and_links) { js + css }
  end

  def google_auto_translatable_js
    return if @google_auto_translatable_js_inserted

    js = javascript_include_tag("http://www.google.com/jsapi?format=")
    js += javascript_tag("
    google.load('language', '1');
    function getGoogleTranslation(field_id, text, from_language, to_language) {
      google.language.translate(text, from_language, to_language, function(result) {
        if (!result.error) { Form.Element.setValue(field_id, result.translation); }
      });
    }
    ")

    @google_auto_translatable_js_inserted = true
    content_for(:add_on_scripts_and_links) { js }
  end
end
