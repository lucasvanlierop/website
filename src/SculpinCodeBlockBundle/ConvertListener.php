<?php
namespace App\SculpinCodeBlockBundle;

use DOMDocument;
use DOMElement;
use DOMNode;
use DOMXPath;
use Sculpin\Bundle\MarkdownBundle\SculpinMarkdownBundle;
use Sculpin\Bundle\TwigBundle\SculpinTwigBundle;
use Sculpin\Core\Event\ConvertEvent;
use Sculpin\Core\Sculpin;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;

/**
 * Converts html <code> tags to Twig {% codeblock %} tags so they can be
 * highlighted by the TwigCodeBlockBundle
 */
class ConvertListener implements EventSubscriberInterface
{
    /**
     * {@inheritdoc}
     */
    public static function getSubscribedEvents()
    {
        return array(
            Sculpin::EVENT_AFTER_CONVERT => 'afterConvert',
        );
    }

    public function afterConvert(ConvertEvent $convertEvent)
    {
        if ($this->isMarkdownEvent($convertEvent) === false) {
            return;
        }

        $convertEvent
            ->source()
            ->setContent(
                $this->convertHtmlCodeElementsToTwigCodeBlocks(
                    $convertEvent->source()->content()
                )
            );
    }

    /**
     *
     */
    private function convertHtmlCodeElementsToTwigCodeBlocks(string $html): string
    {
        $document = new DOMDocument(5, 'utf-8');

        if (@$document->loadHTML('<?xml encoding="utf-8" ?>' . $html) === false) {
            echo sprintf(
                "Could not parse html '%s', error was '%s'",
                $html,
                error_get_last()
            );
            return $html;
        }

        $xpath = new DOMXPath($document);
        /**
         * Note that replacing elements in document does not work in a foreach loop
         */
        while ($codeBlock = $xpath->query('//pre/code')[0]) {
            $this->replaceHtmlCodeBlockWithTwigCodeBlock($codeBlock, $document);
        }

        $a =  preg_replace(
            [
                '#<body>#',
                '#</body>#'
            ],
            '',
            $document->saveHTML($document->getElementsByTagName('body')[0])
        );

        return $a;
    }

    private function isMarkdownEvent(ConvertEvent $convertEvent): bool
    {
        return $convertEvent->isHandledBy(
            SculpinMarkdownBundle::CONVERTER_NAME,
            SculpinTwigBundle::FORMATTER_NAME
        );
    }

    private function replaceHtmlCodeBlockWithTwigCodeBlock(DOMElement $codeBlock, DOMDocument $document): void
    {
        $language = $codeBlock->attributes->getNamedItem('class')->nodeValue;

        // Cannot be empty
        if ($language === null) {
            $language = '';
        }

        $preNode = $codeBlock->parentNode;

        $newNode = $document->createElement(
            'div',
            <<<"CODE"
{% codeblock lang:$language %}
$codeBlock->nodeValue
{% endcodeblock %}
CODE
        );

        $preNode->parentNode->replaceChild(
            $newNode,
            $preNode
        );
    }
}
