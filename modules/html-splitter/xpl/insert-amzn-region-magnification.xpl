<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:tr="http://transpect.io" 
  xmlns:css="http://www.w3.org/1996/css" 
  xmlns:epub="http://transpect.io/epubtools"
  version="1.0" 
  name="insert-amzn-region-magnification"
  type="epub:insert-amzn-region-magnification">
  
  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    If the option <code>amzn-region-magnification</code> has the value <code>true</code>, 
    this option inserts in each HTML file the markup for Amazon's Region Magnification featue. 
    Since
  </p:documentation>
  
  <p:input port="source" sequence="true">
    <p:documentation>
      A sequence of documents with certain base URIs
    </p:documentation>
  </p:input>
  
  <p:output port="result" sequence="true">
    <p:documentation>
      Sequence of HTML chunks, optionally with Amazon region-magnification markup.
    </p:documentation>
  </p:output>
  
  <p:option name="amzn-region-magnification" select="'false'">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      Declare this option in your epubtools configuration file as attribute of the root element.
    <pre><code>&lt;epub-config format="EPUB3" 
  layout="fixed" 
  indent="selective" 
  page-map-xml="false"
  css-handling="unchanged"
  amzn-region-magnification="true">
  &lt;!-- ... -->
  &lt;/epub-config></code></pre>
    </p:documentation>
  </p:option>
  
  <p:option name="debug" select="'no'"/>
  <p:option name="debug-dir-uri" select="'debug'"/>
  
  <p:for-each>
    <p:output port="result" sequence="true"/>
    <p:iteration-source>
      <p:pipe port="source" step="insert-amzn-region-magnification"/>
    </p:iteration-source>
    
    <cx:message>
      <p:with-option name="message" select="'[info] insert Amazon Region Magnification markup to file: ', replace(base-uri(), '^.+/', '')"/>
    </cx:message>
    
    <p:choose>
      <p:when test="$amzn-region-magnification eq 'true' and matches(base-uri(), '\.xhtml$') and not(matches(base-uri(), '(cover|nav)\.xhtml$'))">
        
        <cx:message>
          <p:with-option name="message" select="'[info] insert Amazon Region Magnification markup to file: ', replace(base-uri(), '^.+/', '')"/>
        </cx:message>
        
        <p:xslt>
          <p:input port="stylesheet">
            <p:document href="../xsl/insert-amzn-region-magnification.xsl"/>
          </p:input>
          <p:input port="parameters">
            <p:empty/>
          </p:input>
        </p:xslt>
        
      </p:when>
      <p:otherwise>
        <p:identity/>     
      </p:otherwise>
    </p:choose>
    
  </p:for-each>
  
</p:declare-step>