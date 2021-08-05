<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:tr="http://transpect.io" 
  xmlns:epub="http://transpect.io/epubtools"
  version="1.0" name="insert-amzn-region-magnification" type="epub:insert-amzn-region-magnification">

  <p:documentation xmlns="http://www.w3.org/1999/xhtml"> This pipeline adds Amazon's Region Magnification markup to each
    <code>div</code> which includes the <code>magnification</code> class:
    <pre><code>&lt;div class="magnification">
  &lt;p id="p-1-02">A quick brown fox jumps over a lazy dog.&lt;/p>
&lt;/div></code></pre>
    <p>The script adds Region Magnification markup according to <a href="https://kindlegen.s3.amazonaws.com/AmazonKindlePublishingGuidelines.pdf" target="_blank">Amazon's Kindle Publishing Guidelines</a>.
    </p>
    <pre><code>&lt;div id="amzn-id-myBook-1-txt" class="source-mag">&lt;a class="app-amzn-magnify" data-app-amzn-magnify="{&#34;targetId&#34;:&#34;magTarget-amzn-id-myBook\
      _000019-1&#34;,&#34;sourceId&#34;:&#34;magSource-amzn-id-myBook-1&#34;,&#34;ordinal&#34;:1}">
  &lt;p id="p-1-02">A quick brown fox jumps over a lazy dog.&lt;/p>
&lt;/a>&lt;/div>&lt;div id="amzn-id-myBook-1-magTarget" class="target-mag">
  &lt;p>A quick brown fox jumps over a lazy dog.&lt;/p>
&lt;/div></code></pre>
    <p>Please note that you later need to execute a bash script which escapes the quotes. The script can be found here: <code>scripts/escape-for-amzn-region-magnification.sh</code></p>
  </p:documentation>

  <p:input port="source" sequence="true">
    <p:documentation> A sequence of documents with certain base URIs </p:documentation>
  </p:input>

  <p:output port="result" sequence="true">
    <p:documentation> Sequence of HTML chunks, optionally with Amazon region-magnification markup. </p:documentation>
  </p:output>

  <p:option name="amzn-region-magnification" select="'false'">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml"> Declare this meta tag in your epubtools configuration file
      to apply Region Magnification Markup.
      <pre><code>&lt;metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf"> 
  &lt;meta name="RegionMagnification" content="true"/>
  &lt;!-- ... -->
&lt;/metadata></code></pre>
    </p:documentation>
  </p:option>

  <p:option name="debug" select="'no'"/>
  <p:option name="debug-dir-uri" select="'debug'"/>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />

  <p:for-each name="file-iteration">
    
    <p:iteration-source>
      <p:pipe port="source" step="insert-amzn-region-magnification"/>
    </p:iteration-source>

    <p:choose name="choose">
      <p:when test="$amzn-region-magnification eq 'true' and not(contains(base-uri(), replace($debug-dir-uri, '^(.+)\?.*$', '$1')))">
        <p:output port="result" sequence="true" primary="true">
          <p:pipe port="result" step="xslt"/>
          <p:pipe port="secondary" step="xslt"/>
        </p:output>

        <cx:message>
          <p:with-option name="message"
            select="'[info] add Region Magnification markup to file: ', replace(base-uri(), '^.+/', '')"/>
        </cx:message>

        <p:xslt name="xslt">
          <p:input port="stylesheet">
            <p:document href="../xsl/insert-amzn-region-magnification.xsl"/>
          </p:input>
          <p:input port="parameters">
            <p:empty/>
          </p:input>
        </p:xslt>

      </p:when>
      <p:otherwise>
        <p:output port="result" sequence="true" primary="true"/>

        <p:identity/>

      </p:otherwise>
    </p:choose>

  </p:for-each>

</p:declare-step>
