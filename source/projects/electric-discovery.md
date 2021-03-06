---
draft: true
layout: "default"
name: "Electric Land Rover Discovery project"

---

[Component Overview](/projects/electric-discovery/component-overview)


<!--generator: [posts_category_index, pagination]-->
<!--pagination:-->
<!--provider: page.category_posts-->

I'm working on converting my a Land Rover Discovery from diesel to electric.

It's a 1997 300Tdi model.
This model originally had a 100 inch wheelbase but it has been [stretched to ~124 inch]().
Both body and chassis have been [hot dip galvanized]()

One of my examples is the [electric Volvo Amazon](https://www.oudevolvo.nl/ev-combi/) project by [Lars Rengersen](https://twitter.com/larsrengersen)

I'll be using the same (Siemens 1PV5153 4WS-14) 3 phase induction motor as Lars [put it in his Volvo](https://www.oudevolvo.nl/blog/2015/08/13/m400-versnellingsbak-aan-elektromotor-gemaakt-en-ingebouwd/)
with a different controller: the [Sevcon gen 4 size 8](http://www.sevcon.com/products/high-voltage-controllers/gen4-s8/)

The Siemens motor was originally developed for the [electric Ford Transit Connect](https://en.wikipedia.org/wiki/Azure_Transit_Connect_Electric)
but came available to the DIY market after the bankruptcy of [Azure Dynamics](https://en.wikipedia.org/wiki/Azure_Dynamics).

In the Ford Transit Connect the Siemens motor was used in combination with the [DMOC 645](http://store.evtv.me/proddetail.php?prod=dmoc645) controller however
it becomes harder to obtain both the motor and the controller from the Azure Dynamics bankruptcy sales.

Also to get it road legal in the Netherlands you need a certificate which proves the [electromagnetic compatibility](https://en.wikipedia.org/wiki/Electromagnetic_compatibility) of the motor controller combination for the Dutch market.
This reduces both the number of motors/controllers you can use as well as the suplliers you can get them from.

Luckily [New Electric](http://www.newelectric.nl/drive-train/) has already done the necessary EMC tests and they can supply a motor/controller combination with the required certificated.
Furthermore they aquire the motors directly from Siemens rather

The rest of the driveline stay the same and I'll be [keeping the gearbox]() albeit with a few small changes.

<!--{% set year = '0' %}-->
<!--<h2>"{{ page.category }}"</h2>-->
<!--{% for post in page.pagination.items %}-->
<!--{% set this_year %}{{ post.date | date("Y") }}{% endset %}-->
<!--{% if year != this_year %}-->
<!--{% set month = '0' %}-->
<!--{% set year = this_year %}-->
<!--{% endif %}-->
<!--{% set this_month %}{{ post.date | date("F") }}{% endset %}-->
<!--{% if month != this_month %}-->
<!--{% set month = this_month %}-->
<!--<h3>{{ month }} {{ year }}</h3>-->
<!--{% endif %}-->
<!--<article class="block">-->
    <!--<div><a href="{{ site.url }}{{ post.url }}">{{ post.title }}</a></div>-->
    <!--{% if post.meta.tags %}-->
    <!--<p class="tags">-->
        <!--Tags:-->
        <!--{% for tag in post.meta.tags %}-->
        <!--<a href="{{ site.url }}/blog/tags/{{ tag|url_encode(true) }}">{{ tag }}</a>{% if not loop.last %}, {% endif %}-->
        <!--{% endfor %}-->
    <!--</p>-->
    <!--{% endif %}-->
<!--</article>-->
<!--{% endfor %}-->

<!--<div>-->
    <!--{% if page.pagination.previous_page or page.pagination.next_page %}-->
    <!--<nav class="article clearfix">-->
        <!--{% if page.pagination.previous_page %}-->
        <!--<a class="previous" href="{{ site.url }}{{ page.pagination.previous_page.url }}" title="Previous Page"><span class="title">Previous Page</span></a>-->
        <!--{% endif %}-->
        <!--{% if page.pagination.next_page %}-->
        <!--<a class="next" href="{{ site.url }}{{ page.pagination.next_page.url }}" title="Next Page"><span class="title">Next Page</span></a>-->
        <!--{% endif %}-->
    <!--</nav>-->
    <!--{% endif %}-->
<!--</div>-->


Other people using Tesla Model S batteries:
- http://evbimmer325i.blogspot.nl/2017/06/tesla-battery-pack-bus-bar-steel.html?m=1
- http://www.diyelectriccar.com/forums/showthread.php?t=177489
- https://www.oudevolvo.nl/ev-combi/
