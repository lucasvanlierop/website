---
draft: true
title: Running Wordpress in  Docker
categories: 
    software-development
tags: 
    - testing
    - docker
    - docker-festival
    - wordpress
---

Last year I took over maintainance and hosting for my wife's blog [Allihoppa.nl](http://allihoppa.nl) which happens to be a WordPress site.

To have something to hold on to I decided to install and run WordPress the way I was used to with other web applications, namely:
- Install vendor code with [Composer](https://getcomposer.org/) (check [this article](/blog/2017/06/28/running-cli-tools-in-docker-part-1-composer/)
- Run it in a [Immutable Docker Container](/blog/2017/12/31/truly-immutable-deployments-with-docker-or-kubernetes/)
That turned to be a bit different than what most WordPress people in my environment were used to.

Things I ran into:
- Installing WordPress Core/Themes/Plugins with Composer (only after I already resolved many of the problems I ran into I found that [Benjamin Eberlei had similar problems with his wife's blog](https://beberlei.de/2016/02/21/how_i_use_wordpress_with_git_and_composer.html))
- Accessing the website by domain
- Preventing internal CLI calls (cron jobs, Akismet) from using the external domain/port
- Set WP_HOME
- Configuring different environments (using env vars)
- Installing js vendors with Bower (https://github.com/allihoppa/allihoppa.nl/blob/master/docker/js-build/Dockerfile)
- Upgrade db (https://github.com/allihoppa/allihoppa.nl/blob/master/bin/upgrade.php)
- Db migrations (https://github.com/allihoppa/allihoppa.nl/commit/ddc8c00047e25fe39e6de3aac1de542a65f84cc4)
- Test db connection (https://github.com/allihoppa/allihoppa.nl/blob/master/bin/test-db-connection.php)
- WP CLI (https://github.com/allihoppa/allihoppa.nl/blob/master/wp)
- debug mail (https://github.com/allihoppa/allihoppa.nl/commit/2a271899a1eb6eb1e8e1ecb6c47648d0c657a761)
- Wait for db etc: ()https://github.com/allihoppa/allihoppa.nl/blob/master/bin/wait-for-db)
- Testing with selenium chrome and Behat (WordHat?)
- Running MySQL in docker (https://github.com/allihoppa/allihoppa.nl/blob/master/docker/service/mysql/backup)

- Backup (remote rclone)




