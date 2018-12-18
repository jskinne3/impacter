module KnocksHelper

	def demographic_totals(knocks, demographic)
    a = knocks.map{|k| k.send(demographic).to_s.titleize }
    b = Hash.new(0)
    a.each do |v|
      b[v] += 1
    end
    return b.map{|g,n| [(g == '' ? 'Unknown' : g), n]}
  end

  def highlighted_field(knock, field_name)
    if knock.try(:highlight).try(field_name.to_sym)
      return "<b>#{field_name.titleize}:</b> #{knock.highlight.send(field_name.to_sym).join('...')}<br />"
    else
      return ''
    end

  end

end
