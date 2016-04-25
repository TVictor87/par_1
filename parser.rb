require 'mechanize'
require 'json'

class Parser
  def self.parse_open_uri
    require 'open-uri'
    require 'nokogiri'

    url = 'http://www.cubecinema.com/programme'
    html = open(url)

    doc = Nokogiri::HTML(html)

    showings = []
    doc.css('.showing').each do |showing|
      showing_id = showing['id'].split('_').last.to_i
      tags = showing.css('.tags a').map { |tag| tag.text.strip }
      title = showing.at_css('h3').text.strip
      dates = showing.at_css('.start_and_pricing').inner_html.strip
      dates = dates.split('<br>').map(&:strip).map { |d| DateTime.parse(d).strftime("%b %d, %Y %H:%M:%S") }
      description = showing.at_css('.copy').text.gsub('[more...]', '').strip
      showings.push(
          id: showing_id,
          title: title,
          tags: tags,
          dates: dates,
          description: description
      )
    end

    puts JSON.pretty_generate(showings[0])
  end

  def self.save_products_in_file(f_name, products)
    File.open(f_name, 'w') do |f|
      f.puts JSON.pretty_generate(products)
    end
  end

  attr_accessor :agent

  def self.parse_mechanize
    s_time = Time.now
    my_parser = Parser.new
    products = my_parser.parse_page 'http://colgoty-chylki.com.ua/home/category/22-kolgotki-gatta.html'
    save_products_in_file("results/gatta_person.txt", products)
    printf("Time spent: #{Time.now - s_time}".colorize(color: :red, background: :yellow) + "\n")
  end

  def initialize
    @agent = Mechanize.new
  end

  def parse_page(url = 'http://google.com/')
    @page = @agent.get(url)

    products = []
    @page.parser.css("#product_list .browseProductContainer").each do |product|
      name = product.at_css('h2').text.gsub('Женские колготки Gatta', '').strip
      price = product.at_css('.productPrice').text.to_f
      tags = product.css('div')[1].text
      link = product.at_css('h2 a').attr('href')

      product_deatils = parse_product_page link

      product_deatils.merge!(name: name, tags: tags, price: price, link: link)

      products.push product_deatils
    end
    products
  end

  def parse_product_page(url)
    product_deatils = {}
    product_page = @agent.get(url)

    product_page = product_page.parser.css("#vmMainPage")
    product_deatils[:full_image_href] = product_page.css('a')[1].attr('href')
    product_deatils[:description] = product_page.css('tr')[3].text.strip
    product_deatils[:sizes] = product_page.css('#размер_field option').map { |size| size.text.strip }
    product_deatils[:colors] = product_page.css('#цвет_field option').map { |size| size.text.strip }
    product_deatils[:data_changed] = product_page.css(".small").text

    product_deatils
  end
end