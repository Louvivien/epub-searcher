EPUBSearcher::App.controllers do

  layout :layout
  get :index do
    @query_words = params[:q]
    @authors = (params[:authors] || []).uniq
    right_query = (@query_words && !@query_words.empty? or !@authors.empty?)
    if right_query
      results = search_from_groonga(@query_words, :authors => @authors)
      @results = results.records
      @drilldowns = results.drilldowns unless results.drilldowns.empty?
      @hits = results.n_hits.to_i
    else
      @drilldowns = author_drilldowns_from_groonga.drilldowns
    end

    render 'index'
  end

  get :books do
    results = books_from_groonga
    @books = results.records
    @drilldowns = results.drilldowns

    render 'books'
  end

end
