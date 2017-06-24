<?php
$date = date('Y-m-d');
if(!empty($argv[2])){
    $date = $argv[2];
}

if(empty($argv[1])){
    die('You must supply a title' . PHP_EOL);
}
$file = sprintf(
    'source/_posts/%s-%s.md',
    $date,
    strtolower(
        preg_replace('/[^\w]+/', '-', $argv[1]))
    )
;

$title = ucwords(str_replace('_', ' ', $argv[1]));

if (file_exists($file)) {
    die($file . ' already exists' . PHP_EOL);
}

$data = "---
layout: default
title: {$title}
categories:
    -
tags: 
    -
---

";

file_put_contents($file, $data);

