<?php
use App\SculpinCodeBlockBundle\SculpinCodeBlockBundle;
use Sculpin\Bundle\SculpinBundle\HttpKernel\AbstractKernel;

class SculpinKernel extends AbstractKernel
{
    protected function getAdditionalSculpinBundles()
    {
        return [
            SculpinCodeBlockBundle::class
        ];
    }
}
