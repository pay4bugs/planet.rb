require 'yaml'
require 'planet/version'
require 'planet/blog'
require 'planet/importer'
require 'onename'

class Planet

  attr_accessor :config, :blogs, :whitelisted_tags, :onename_authors

  def initialize(config_file_path)
    config_file = read_config_file(config_file_path)
    self.config = config_file[:planet]
    self.blogs  = config_file[:blogs]
    self.whitelisted_tags  = self.config['whitelisted_tags']
  end

  def posts
    self.blogs.map { |b| b.posts }.flatten
  end

  def aggregate
    self.blogs.each do |blog|
      puts "=> Parsing #{ blog.feed }"
      blog.fetch
    end
  end

  def write_posts
    Importer.import(self)
  end

  private

  def read_config_file(config_file_path)
    config = YAML.load_file(config_file_path)
    planet = config.fetch('planet', {})
    onename_authors = {}
    
    # load author data from OneName
    blogs = config.fetch('blogs', [])
    
    for blog in blogs
      if(blog['onename'])
        user = Onename.get(blog['onename'])
        onename_authors[user.onename] = user        
      end
    end
    
    blogs = config.fetch('blogs', []).map do |blog|
      author = onename_authors[blog['onename']]
      Blog.new(
        feed:    blog['feed'],
        url:     blog['url'],
        author:  author.nil? ? blog['author'] : author.onename,
        image:   author.nil? ?  blog['image'] : author.avatar_url,
        posts:   [],
        planet:  self,
        twitter: author.nil? ?  blog['image'] : author.twitter_username,
        onename: author
      )
    end

    { planet: planet, blogs: blogs }
  end
end
