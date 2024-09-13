<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:cxf="http://xmlcalabash.com/ns/extensions/fileutils"
  xmlns:cxo="http://xmlcalabash.com/ns/extensions/osutils" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:epub="http://transpect.io/epubtools" 
  xmlns:tr="http://transpect.io"
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:xlink="http://www.w3.org/1999/xlink" 
  version="1.0"
  name="check-links"
  type="tr:check-links" exclude-inline-prefixes="#all">
  
  <p:documentation>
    This step checks whether links are available.
    TO DO: additional report. Perhaps chooseable link attribute names.
  </p:documentation>
  
  <p:input port="source" primary="true">
    <p:documentation>
      An HTML document.
    </p:documentation>
  </p:input>
  
  <p:output port="result">
    <p:documentation>
      An HTML element with error codes on elements with not available links.
    </p:documentation>
  </p:output>
  
  <p:option name="only" select="''">
    <p:documentation>example 'only:spiegel.de|zeit.de',
      'only:http:', or 'never:doi.org'. If something is excluded by 'never:', it cannot be re-included by 'only:'. Matching
      is by substring, not by regex, against the literal href string, it is not percent-encoded before. 
      Instead of '|' as delimiter '~' can be used, especially for parameter delivery via the davomat.</p:documentation>
  </p:option>
  <p:option name="never" select="''">
    <p:documentation>example 'only:spiegel.de|zeit.de|never:.rdf|.xml',
      'only:http:', or 'never:doi.org'. Matching is by substring, not by regex, against the literal href string, it is not percent-encoded before. 
      Instead of '|' as delimiter '~' can be used, especially for parameter delivery via the davomat.</p:documentation>
  </p:option>
  <p:option name="debug-dir-uri" select="'debug-dir-uri'"/>
  <p:option name="status-dir-uri" select="'status'" cx:type="xs:string"/>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.io/xproc-util/simple-progress-msg/xpl/simple-progress-msg.xpl"/>
  <p:import href="http://transpect.io/xproc-util/file-uri/xpl/file-uri.xpl"/>
  
<!--  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>-->
  
  <tr:simple-progress-msg name="linkcheck-start-msg" file="linkcheck-start.txt">
    <p:input port="msgs">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">Starting Link Check</c:message>
          <c:message xml:lang="de">Beginne Link-Check</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>
        
  <p:viewport match="*[@src | @href | @xlink:href | @poster]
                      [some $att in @*[local-name() = ('src', 'href', 'poster')] 
                       satisfies $att[starts-with(., 'http')]]" name="check-hrefs">
    <p:variable name="url" select="/*/(@src | @href | @xlink:href | @poster)"/>
    <p:variable name="actual-link-to-be-checked" select="for $u in $url
                                                                    [if (normalize-space($never))
                                                                    then (every $n in tokenize($never, '(\||~)') 
                                                                    satisfies not(contains(., $n)))
                                                                    else true()]
                                                                    [if (normalize-space($only)) 
                                                                    then (some $o in tokenize($only, '(\||~)') 
                                                                    satisfies contains(., $o))
                                                                    else true()] 
                                                                    return $u">
      <p:pipe port="current" step="check-hrefs"/>
    </p:variable>
    <p:try name="fu2t">
      <p:group>
        <cx:message>
          <!-- to determine which links need especially much time to be resolved -->
          <p:with-option name="message" select="if (not($actual-link-to-be-checked[normalize-space()])) then '- Not ' else '- ', 'Checking URL : [', format-time(current-time(), '[H]:[m]:[s]'), '] ', /*/(@src | @href | @xlink:href | @poster)">
            <p:pipe port="current" step="check-hrefs"/>
          </p:with-option>
        </cx:message>
        
        <p:choose>
          <p:when test="normalize-space($actual-link-to-be-checked)">
            
            <p:string-replace name="link-check-url-msg" match="file">
              <p:with-option name="replace" select="concat('''',  ' URL : [', format-time(current-time(), '[H]:[m]:[s]'), '] ', /*/(@src | @href | @xlink:href | @poster), '''')">
                <p:pipe port="current" step="check-hrefs"/>
              </p:with-option>
              <p:input port="source">
                <p:inline>
                  <c:messages>
                    <c:message xml:lang="en">////////// Check <file/>   \\\\\\\\\\</c:message>
                    <c:message xml:lang="de">////////// Prüfe <file/>   \\\\\\\\\\</c:message>
                  </c:messages>
                </p:inline>
              </p:input>    
            </p:string-replace>
            
            <tr:simple-progress-msg name="check-actual" file="current-link-check.txt">
              <p:input port="msgs">
                <p:pipe port="result" step="link-check-url-msg"/>
              </p:input>
              <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
            </tr:simple-progress-msg>
            
            <tr:file-uri fetch-http="false" check-http="true" name="fu2i" make-unique="false">
              <p:with-option name="filename" select="resolve-uri(escape-html-uri($actual-link-to-be-checked), base-uri())">
                <p:documentation>If it is a relative URI, resolve it wrt the HTML source.</p:documentation>
              </p:with-option>
              <p:input port="resolver">
                <p:document href="http://transpect.io/xslt-util/xslt-based-catalog-resolver/xsl/resolve-uri-by-catalog.xsl"/>
              </p:input>
              <p:input port="catalog">
                <p:document href="http://this.transpect.io/xmlcatalog/catalog.xml"/>
              </p:input>
            </tr:file-uri>    
          </p:when>
          <p:otherwise>
            <p:documentation>For performance reasons, we skip tr:file-uri altogether if no check required.
              Strangely, it took about a second per URL even with fetch-http="false" and check-http="false".
            </p:documentation>
            <p:add-attribute attribute-name="href" match="/*">
              <p:input port="source">
                <p:inline><c:result/></p:inline>
              </p:input>
              <p:with-option name="attribute-value" select="$url"/>
            </p:add-attribute>
          </p:otherwise>
        </p:choose>
      </p:group>
      <p:catch name="catch-fu2">
        <p:insert match="/*" position="first-child">
          <p:input port="source">
            <p:inline>
              <c:result error-status="999"/>
            </p:inline>
          </p:input>
          <p:input port="insertion">
            <p:pipe port="error" step="catch-fu2"/>
          </p:input>
        </p:insert>
        <p:add-attribute attribute-name="href" match="/*">
          <p:with-option name="attribute-value" select="$url"/>
        </p:add-attribute>
        <cx:message>
          <!-- without this message, due to a Calabash bug, no error-status will be attached to the element: -->
          <p:with-option name="message" select="'ERROR: PROBABLY ILLEGAL CHARACTERS IN URL: ', /*/@*"/>
        </cx:message>
      </p:catch>
    </p:try>
    <p:identity name="fu2"/>
    <p:sink/>
    
    <p:identity>
      <p:input port="source">
        <p:pipe port="current" step="check-hrefs"/>  
      </p:input>
    </p:identity>
    <p:choose>
      <p:xpath-context>
        <p:pipe port="result" step="fu2"/>
      </p:xpath-context>
      <p:when test="/*/@error-status">
        <p:add-attribute attribute-name="error-message" match="/*">
          <p:with-option name="attribute-value" select="string(/*)">
            <p:pipe port="result" step="fu2"/>
          </p:with-option>
        </p:add-attribute>
        <p:add-attribute attribute-name="checked-href" match="/*">
          <p:with-option name="attribute-value" select="/*/@href">
            <p:pipe port="result" step="fu2"/>
          </p:with-option>
        </p:add-attribute>
        <p:add-attribute attribute-name="error-status" match="/*">
          <p:with-option name="attribute-value" select="/*/@error-status">
            <p:pipe port="result" step="fu2"/>
          </p:with-option>
        </p:add-attribute>
      </p:when>
      <p:otherwise>
        <p:identity/>
      </p:otherwise>
    </p:choose>
  </p:viewport>
        
  <tr:simple-progress-msg name="linkcheck-end-msg" file="linkcheck-end.txt">
    <p:input port="msgs">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">Finished Link Check</c:message>
          <c:message xml:lang="de">Link-Check abgeschlossen</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>
  
</p:declare-step>