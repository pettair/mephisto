class CommentSweeper < ArticleSweeper
  observe Comment

  def after_save(record)
    @event.update_attributes :title => record.article.title, :body => record.body, 
      :article => record.article, :author => record.author, :comment => record if record.approved?
    expire_overview_feed! if record.approved?

    return if controller.nil?
    pages = CachedPage.find_by_reference(record.article)
    controller.class.benchmark "Expired pages referenced by #{record.class} ##{record.id}" do
      pages.each { |p| controller.class.expire_page(p.url) }
      CachedPage.expire_pages(pages)
    end if pages.any?
  end

  undef :after_create
end