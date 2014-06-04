/*globals $*/
(function (globals) {
    'use strict';
    
    var template_producer = $("#template-producer"),
        template_post = $("#template-post"),
        producer_section = $("#producer"),
        producers_section = $("#producers");
    
    function processPosts(req, posts) {
        var post,
            newpost;
        for (post in posts) {
            if (posts.hasOwnProperty(post)) {
                newpost = template_post.clone();
                newpost.attr("id", "post_" + post.userpost.time);
                newpost.text(post.userpost.msg);
            }
        }
    }
    
    function goToPageProducer(event) {
        producers_section.remove();
        $("body").prepend(producer_section);
        globals.getposts(event.data.value, processPosts);
    }
    
    function arrangeProducers(args, v, rawJson) {
        var producer_article,
            user,
            i;
        
        for (i = 0; i < v.length; i += 1) {
            producer_article = template_producer.clone();
            producer_article.attr("id", "articolo_" + v[i]);
            producer_article.appendTo("#producers");
            producer_article.children(".author").text(v[i]);
            producer_article.click({value: v[i]}, goToPageProducer);
        }
    }
    
    producer_section.remove();
    template_producer.remove();
    template_post.remove();
    globals.dhtget("utente1", "home", "s", arrangeProducers);
}(this));