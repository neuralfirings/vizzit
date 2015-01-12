console.log "r2"
$(document).ready () ->

  get_subreddit = getUrlParameter("sr")
  get_numthreads = getUrlParameter("nt")
  get_searchstring = getUrlParameter("ss")
  get_limitwords = getUrlParameter("lw")

  LIMIT = 50 # limit chart results

  $(".chart").attr("width", $("#charts-container").width() + "px")

  if get_subreddit and get_numthreads and get_searchstring and get_limitwords
    $("#subreddit").val get_subreddit
    $("#searchstring").val get_searchstring
    $("#limitwords").val get_limitwords
    $("#numthreads").val get_numthreads

    sub = $("#subreddit").val()
    query = $("#searchstring").val()
    max_num_threads = $("#numthreads").val()

    # AJAX PARTY
    $("#ajax_progress_container").show()

    query_url = "https://www.reddit.com/" + sub + "/search.json?q=" + query + "&restrict_sr=on&limit=" + max_num_threads
    $.ajax(query_url).done (data) ->
      search_results = data
      num_threads = search_results.data.children.length
      for thread in search_results.data.children
        thread_url = "https://www.reddit.com/"+ sub + "/comments/" + thread.data.id 
        threads = []
        $.ajax(thread_url + ".json").done (data) ->
          threads.push data

          percentage_done = Math.ceil((threads.length / num_threads) * 100)
          $("#ajax_progress").find(".progress-bar ").attr("aria-valuenow", percentage_done)
            .css("width", percentage_done + "%")
            .html(percentage_done + "%")

          if threads.length == num_threads
            processData(threads)
            setTimeout () -> 
              $("#ajax_progress_container").fadeOut()
            , 750

    data_unweighted = ""
    data_weighted = []

    $.all_comments = {}
    processData = (threads) ->
      for thread in threads
        thread_title = thread[0].data.children[0].data.title
        thread_id = thread[0].data.children[0].data.id
        thread_results = thread[1].data
        thread_url = thread[0].data.children[0].data.url
        for comment in thread_results.children
          data_unweighted += comment.data.body + " "
          if comment.data.replies
            children = comment.data.replies.data.children.length
          else
            children = 0
          comment_url = "https://www.reddit.com/"+ sub + "/comments/" + thread_id + "/vizzit/" + comment.data.id
          
          data_weighted.push [comment.data.score, comment.data.body, children, comment_url, thread_title, thread_url]
            # score, body, replies, comment_url

      # COUNT WORDS
      data_unweighted = data_unweighted.toLowerCase()
      words = data_unweighted.split(/\b/);
      wordCounts = {};
      wordCounts_weighted = {};
      ignore_words = [
        " ", "the", ",", "i", "to", "a", ".", "and", "'", "/", "of", "it", "you", "in", "is", "that", "with", ", ", "for", "my", "be", 
        "this", "have", "but", "://", "com", "are", "on", "s", "would", "http", "if", "-", "can", ".↵↵", "at", "as", "t", "want", "(", 
        "will", "out","not", "m", "an", "get", "about", "what","one", "from", "we", "they", "just", "your", "use", "it", "all", "www", 
        "ve", "do", "!", "more", "so", "like", "good", "make", "has", "me", "or", "=", "](", ")", "if", "here", "was", "0", "some", "am", 
        ": ", "time", "been", " $", ";", "really", "also", "by", "there",  "[", "", "!", ". ", ":", "?", "$", "love",  "something", 
        "could", "now", "people", "amp", ").", "very", "ll", "great", "only", "&", "them","their", "any", "think",  "even", "its", "much", 
        "imgur", "using", "when", "don", "had", "work", "these", "community", "d", "into", "see", "our", "best", "well", "way", "going", "though", 
        "able", "new", "because", "better", "who", "which", "things",  "quality", "few",  "probably", "than", "own", "should", "first", "sure", 
        "looking", "say", "re", "no", "%", "doing", "buy", "https", "products", "tool",  "works", "service", "ever", "board", "user", "told", 
        "free", "try", "lots", "helpful", "paying", "wouldn", "tinkering", "machine", "thing", "budget", "hobby",  "spending", "different", 
        "story", "many", "-$", "price", "output",  "however", "required", "maybe", "worth", "wait", "machines", "come", "still", "aren",  
        "reviews", "yet", "expecting", "over", "models", "let", "begin", "recently", "/)", "happy", "around", "while", "pretty", "support", 
        "why", "seeing", "little",  "talk", "market", "looks", "option", "consider", "everyone", "recommend", "personally", "received", "easy", 
        "access", "pcb", "heated", "bed", "type", "success",  "shop", "black", "assembled", "hate", "believe", "html", "absolutely",  "amazing", 
        "large", "purchase", "imho", "then", "...", "made", "*", "awesome",  "across", "day", "printing", ".(", "getting", "anything", "lot", 
        "money",  "expenses", "although", "camera", "need", "8", "run", "back", "order", "three", "...[", "deleted", "]", "definitely", "casting", 
        "afford", "injection", "molding", "setup", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "q", "w", "e", "r", "t", "y", "u", "i", "o", 
        "p", "a", "s", "d", "f", "g", "h", "j", "k", "l", "z", "x", "c", "v", "b", "n", "m", "he", "co", "en",
        "de", "us", "ht", "hi", "im", "ee", "ge"
      ]


      if $("#limitwords").val() == "" # count all words
        keywords = []
        for word in words
          santized_word = word.replace(/\ /g, "").replace(/(\r\n|\n|\r)/gm,"")
          if $.inArray(santized_word, ignore_words) == -1
            if $.inArray(santized_word, keywords) == -1 
              if santized_word == "x"
                console.log santized_word, word
              keywords.push santized_word
      else # count only limited words
        keywords = $("#limitwords").val().replace(", ", ",").split(",")

      for keyword in keywords
        for comment in data_weighted
          if comment[1].split(keyword).length > 1
            if $.all_comments[keyword] == undefined
              $.all_comments[keyword] = []
            $.all_comments[keyword].push comment
            if comment[0] > 0
              wordCounts_weighted["_" + keyword] = (wordCounts_weighted["_" + keyword] || 0) + comment[0]
            wordCounts["_" + keyword] = (wordCounts["_" + keyword] || 0) + 1
      
      sortable = []
      sortable_weighted = []
      for word of wordCounts
        if wordCounts[word] > 1
          sortable.push [word.replace("_", ""), wordCounts[word]]

      for word of wordCounts_weighted
        if wordCounts_weighted[word] > 1
          sortable_weighted.push [word.replace("_", ""), wordCounts_weighted[word]]

      sortable.sort (a, b) ->
        return b[1] - a[1]
      sortable_weighted.sort (a, b) ->
        return b[1] - a[1]

      data_unweighted_labels = []
      data_unweighted_values = []
      for s in sortable
        data_unweighted_labels.push s[0]
        data_unweighted_values.push s[1]


      data_weighted_labels = []
      data_weighted_values = []
      for s in sortable_weighted
        data_weighted_labels.push s[0]
        data_weighted_values.push s[1]

      # CHART IT

      # WEIGHTED
      if $.chart_weighted != undefined
        $.chart_weighted.destroy();
      ctx_w = $("#chart_weighted").get(0).getContext("2d");
      data_w = {
          labels: data_weighted_labels.slice(0,LIMIT),
          datasets: [
              {
                  label: "Keyword Frequency",
                  fillColor: "rgba(220,180,90,0.5)",
                  strokeColor: "rgba(220,180,90,0.5)",
                  highlightFill: "rgba(220,180,90,0.5)",
                  highlightStroke: "rgba(220,180,90,0.5)",
                  data: data_weighted_values.slice(0,LIMIT)
              }
          ]
      };    
      $.chart_weighted = new Chart(ctx_w).Bar(data_w);

      $("#chart_weighted").click (evt) ->
        bar = $.chart_weighted.getBarsAtEvent(evt)
        kw = bar[0].label
        showComments(kw)
      # UNWEIGHTED
      if $.chart_unweighted != undefined
        $.chart_unweighted.destroy();
      ctx = $("#chart_unweighted").get(0).getContext("2d");
      data = {
          labels: data_unweighted_labels.slice(0,LIMIT),
          datasets: [
              {
                  label: "Keyword Frequency",
                  fillColor: "rgba(220,220,220,0.5)",
                  strokeColor: "rgba(220,220,220,0.8)",
                  highlightFill: "rgba(220,220,220,0.75)",
                  highlightStroke: "rgba(220,220,220,1)",
                  data: data_unweighted_values.slice(0,LIMIT)
              }
          ]
      };    
      $.chart_unweighted = new Chart(ctx).Bar(data);

      $("#chart_unweighted").click (evt) ->
        bar = $.chart_unweighted.getBarsAtEvent(evt)
        kw = bar[0].label
        showComments(kw)


showComments = (kw) ->
  comments = $.all_comments[kw]
  $("#commentviewer").empty()
  for comment in comments
    $("#commentviewer").append "<div class='comment'>" + 
      " <span class='badge'>" + comment[0] + " points</span>&nbsp;" + 
      "<a target='_blank' href='" + comment[5] + "'>" + comment[4] + "</a>" +
      "<br />" +
      comment[1].replace(new RegExp('(^|)(' + kw + ')(|$)','ig'), '$1<span class="search-kw text-danger">$2</span>$3') + "<br />" +
      "<small>[" + comment[2] + " replies | " + 
      " <a target='_blank' href='" + comment[3] + "'>permalink</a>]</small></div><hr />"

getUrlParameter = (sParam) ->
    sPageURL = window.location.search.substring(1);
    sURLVariables = sPageURL.split('&');
    i = 0
    while i < sURLVariables.length
      sParameterName = sURLVariables[i].split('=');
      if sParameterName[0] == sParam
        return decodeURIComponent( sParameterName[1].replace(/\+/g, '%20').replace("/", "") )
      i++

