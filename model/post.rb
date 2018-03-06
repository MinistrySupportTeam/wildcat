require_relative 'enclosure'

class Post

  attr_reader :permalink
  attr_reader :external_url
  attr_reader :title
  attr_reader :content_html
  attr_reader :pub_date
  attr_reader :enclosure
  attr_reader :attributes
  attr_reader :source_path

  TITLE_KEY = 'title'
  LINK_KEY = 'link'
  PUB_DATE_KEY = 'pubDate'

  def initialize(settings, permalink, file) # file is a WildcatFile
    @source_path = file.path
    @permalink = permalink
    @attributes = file.attributes
    @external_url = @attributes[LINK_KEY]
    @title = @attributes[TITLE_KEY]
    @content_html = file.to_html
    @pub_date = @attributes[PUB_DATE_KEY]

    enclosure_url = @attributes[ENCLOSURE_URL_KEY]
    if !enclosure_url.nil? && !enclosure_url.empty?
      @enclosure = Enclosure(@attributes)
    end
  end

  JSON_FEED_URL_KEY = 'url'
  JSON_FEED_EXTERNAL_URL_KEY = 'external_url'
  JSON_FEED_ID_KEY = 'id'
  JSON_FEED_TITLE_KEY = 'title'
  JSON_FEED_CONTENT_HTML_KEY = 'content_html'
  JSON_FEED_PUB_DATE_KEY = 'date_published'
  JSON_FEED_ATTACHMENTS_KEY = 'attachments'

  def to_json_feed_component

    json = {}
    json[JSON_FEED_ID_KEY] = @permalink
    json[JSON_FEED_URL_KEY] = @permalink
    json[JSON_FEED_CONTENT_HTML_KEY] = @content_html

    date_string = @pub_date.iso8601
    json[JSON_FEED_PUB_DATE_KEY] = date_string

    add_if_not_empty(json, JSON_FEED_EXTERNAL_URL_KEY, @external_url)

    if enclosure
      enclosure_json = enclosure.to_json_feed_component
      json[JSON_FEED_ATTACHMENTS_KEY] = [enclosure_json]
    end

    json
  end

  def to_html(including_link)

    # Render post.
    # If including_link is true, then this is for the home page or other multi-post page.
    # If including_link is false, then this is the single-post-on-a-page version. Where the permalink points to.

    if including_link
      if @rendered_html_including_link then return @rendered_html_including_link end
    else
      if @rendered_html then return @rendered_html
    end

    template_name = template_name(including_link)

    s = render_with_template(template_name)
    if including_link
      @rendered_html_including_link = s
    else
      @rendered_html = s
    end

    s
  end


  private

  def add_if_not_empty(json, key, value)
    json[key] = value unless (!value || value.empty?)
  end

  def template_name(including_link)

    # A post may not have a title. There are four possible templates:
    # post
    # post_including_link
    # post_no_title
    # post_including_link_no_title

    template_name = 'post'

    if including_link then template_name += '_including_link' end
    if @title.nil? || @title.empty? then template_name += '_no_title' end

    template_name
 end

  # These can all be referenced in the post template.
  # They will be substituted at build time.

  PERMALINK_KEY = 'permalink'
  EXTERNAL_URL_KEY = 'external_url'
  LINK_PREFERRING_EXTERNAL_URL_KEY = 'link_preferring_external_url' # Use external_url when present, falling back to permalink.
  TITLE_KEY = 'title'
  CONTENT_HTML_KEY = 'body'
  PUB_DATE_KEY = 'pub_date'
  DISPLAY_DATE_KEY = 'display_date'

  def context

    context = {}

    context[PERMALINK_KEY] = @permalink
    context[EXTERNAL_URL_KEY] = @external_url

    if !@external_url.nil?
      context[LINK_PREFERRING_EXTERNAL_URL_KEY] = @external_url
    else
      context[LINK_PREFERRING_EXTERNAL_URL_KEY] = @permalink
    end

    context[TITLE_KEY] = @title
    context[CONTENT_HTML_KEY] = @content_html
    context[PUB_DATE_KEY] = @pub_date
    context[DISPLAY_DATE_KEY] = @pub_date.strftime("%d %b %Y")

    context
  end

  def render_with_template(template_name)

    renderer = Renderer.new(@settings, template_name, context)
    renderer.to_html
  end
end
