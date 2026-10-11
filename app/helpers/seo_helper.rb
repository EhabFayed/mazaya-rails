# JSON-LD structured data (Organization on every page; Product + BreadcrumbList
# on product pages). Values come from SiteData; nothing is invented.
module SeoHelper
  def organization_jsonld
    data = {
      "@context" => "https://schema.org", "@type" => "Organization",
      "name" => t("brand"), "url" => request.base_url, "logo" => "#{request.base_url}/assets/logo.png",
      "foundingDate" => SiteData::FOUNDED.to_s,
      "address" => { "@type" => "PostalAddress", "addressCountry" => "SA" },
      "contactPoint" => [ { "@type" => "ContactPoint", "contactType" => "sales", "telephone" => SiteData::WHATSAPP_DISPLAY, "availableLanguage" => %w[ar en] } ],
      "sameAs" => SiteData::SOCIAL.map { |s| s[:url] }.reject { |u| u == "#" }
    }
    jsonld_tag(data)
  end

  def breadcrumb_jsonld(items)
    jsonld_tag(
      "@context" => "https://schema.org", "@type" => "BreadcrumbList",
      "itemListElement" => items.each_with_index.map { |(name, url), i| { "@type" => "ListItem", "position" => i + 1, "name" => name.to_s, "item" => "#{request.base_url}#{url}" } }
    )
  end

  def product_jsonld(product, category)
    data = {
      "@context" => "https://schema.org", "@type" => "Product",
      "name" => product[:name].to_s, "description" => product[:summary].to_s, "category" => category[:name].to_s,
      "brand" => { "@type" => "Brand", "name" => t("brand") },
      "url" => request.original_url.split("?").first
    }
    data["sku"] = product[:code] if product[:code]
    data["image"] = product[:images].map { |i| "#{request.base_url}#{i[:src]}" } if product[:images].present?
    jsonld_tag(data)
  end

  private

  def jsonld_tag(data)
    content_tag(:script, data.to_json.html_safe, type: "application/ld+json")
  end
end
