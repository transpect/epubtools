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
  type="epub:create-ops" 
  name="create-ops">

  <p:input port="source" primary="true"/>
  <p:input port="conf" primary="false" sequence="true">
    <p:documentation>/hierarchy – may be included in /epub-config</p:documentation>
  </p:input>
  <p:input port="meta" primary="false">
    <p:documentation>/epub-config</p:documentation>
  </p:input>
  <p:input port="attach-cover-xsl" primary="false">
    <p:documentation>stylesheet for attaching cover</p:documentation>
  </p:input>
  <p:input port="create-svg-cover-xsl" primary="false">
    <p:documentation>stylesheet for dynamic cover creation</p:documentation>
    <p:empty/>
  </p:input>
  <p:input port="cover-svg" primary="false">
    <p:documentation>svg template for dynamic cover creation</p:documentation>
  </p:input>
  <p:output port="result" primary="true">
    <p:pipe port="result" step="html-splitter"/>
  </p:output>
  <p:output port="html">
    <p:pipe port="html" step="copy-resources"/>
  </p:output>
  <p:output port="files" primary="false">
    <p:pipe port="result" step="wrap-file-uris"/>
  </p:output>
  <p:output port="report" primary="false" sequence="true">
    <p:pipe port="report" step="html-splitter"/>
    <p:pipe port="report" step="copy-resources"/>
  </p:output>
  <p:output port="splitting-report" sequence="true">
    <p:pipe port="splitting-report" step="html-splitter"/>
  </p:output>
  
  <p:option name="base-uri" required="true" cx:type="xs:anyURI"/>
  <p:option name="target" select="'EPUB2'" cx:type="xs:string"/>
  <p:option name="css-filename" select="'stylesheet.css'" required="false" cx:type="xs:string"/>
  <p:option name="use-svg" select="'yes'" cx:type="xs:string"/>
  <p:option name="terminate-on-error" required="false" select="'yes'"/>
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="'debug'"/>
  <p:option name="status-dir-uri" select="'status'" cx:type="xs:string"/>
  <p:option name="create-a11y-meta" select="'yes'" cx:type="xs:string">
    <p:documentation>
      In the context of tr:create-ops, this adds to elements with @epub:type 
      attribute a matching ARIA @role attribute.
    </p:documentation>
  </p:option>
  <p:option name="create-font-subset" select="'false'"  cx:type="xs:string" required="false">
    <p:documentation>
      With this option set to 'true', all fonts will be subsetted. Of each font a 
      copy with the suffix '.subset' is created.
    </p:documentation>
  </p:option>
  <p:option name="font-subset-min-file-size" select="0"  cx:type="xs:integer" required="false">
    <p:documentation>
      Minimum file size of a font to be subsetted (in KiloBytes). Even if files are 
      below this threshold, a copy with the suffix '.subset' is created, because the 
      step 'conditionally-change-font-subset-name' simply depends that the fonts are renamed 
      in that order if the font subsetter is active.
    </p:documentation>
  </p:option>
  <p:option name="create-svg-cover" select="'false'"  cx:type="xs:string" required="false"/>
  <p:option name="convert-svg-cover" select="'false'"  cx:type="xs:string" required="false"/>
  
  <p:import href="../../html-splitter/xpl/html-splitter.xpl"/>
  <p:import href="../../fontsubsetter/xpl/fontsubsetter.xpl"/>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.io/calabash-extensions/image-props-extension/image-identify-declaration.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  <p:import href="http://transpect.io/css-tools/xpl/css.xpl"/>
  <p:import href="http://transpect.io/xproc-util/file-uri/xpl/file-uri.xpl"/>
  <p:import href="http://transpect.io/xproc-util/imagemagick/xpl/imagemagick.xpl"/>
  
  <p:group name="copy-resources">
    <p:output port="result" primary="true"/>
    <p:output port="css-xml" primary="false">
      <p:pipe port="result" step="css-parse"/>
    </p:output>
    <p:output port="html" primary="false">
      <p:pipe port="result" step="attach-cover"/>
    </p:output>
    <p:output port="report" primary="false" sequence="true">
      <p:documentation>Usually the CSS parser report should go here. Unfortunately, due to
      an apparent Calabash bug related to dynamic evaluation or p:for-each iterations, other errors
      than the parser errors (in particular, Saxon warnings from other XSLT steps) end up in the report
      when epub creation is embedded in larger transpect pipelines. Therefore, we’ll disable returning
      this report for the time being. No issue has been filed yet with Calabash.</p:documentation>
<!--      <p:empty/>-->
      <p:pipe port="report" step="create-svg-cover"/>
    </p:output>
    <p:output port="meta-with-uri-resolved-cover-href">
      <p:pipe port="meta-with-uri-resolved-cover-href" step="image-info"/>
    </p:output>
    
    <p:variable name="targetdir" select="replace($base-uri, '^(.*[/])+(.*)', '$1')">
      <p:pipe port="source" step="create-ops"/>
    </p:variable>
    <p:variable name="css-handling" select="(/epub-config/@css-handling, 'regenerated-per-split')[1]">
      <p:pipe port="meta" step="create-ops"/>
    </p:variable>
    <p:variable name="css-parser" select="(/epub-config/@css-parser, 'REx')[1]">
      <p:pipe port="meta" step="create-ops"/>
    </p:variable>
    <p:variable name="css-remove-comments" select="if (contains($css-handling, 'remove-comments')) then 'yes' else 'no'">
      <p:pipe port="meta" step="create-ops"/>
    </p:variable>
    <p:variable name="cover-href" select="resolve-uri(/epub-config/cover/@href, base-uri())">
      <p:pipe port="meta" step="create-ops"/>
    </p:variable>
    <p:variable name="link-check" select="(/epub-config/checks/check[@param = 'epub-check-http-resources']/@value, '')[1]">
      <p:pipe port="meta" step="create-ops"/>
      <p:documentation>The value can be 'true', 'false', or something like 'only:spiegel.de|zeit.de|never:.rdf|.xml',
      'only:http:', or 'never:doi.org'. If something is excluded by 'never:', it cannot be re-included by 'only:'. Matching
      is by substring, not by regex, against the literal href string, it is not percent-encoded before. 
      Instead of '|' as delimiter '~' can be used, especially for parameter delivery via the davomat.</p:documentation>
    </p:variable>

    <tr:store-debug pipeline-step="epubtools/hierarchy">
      <p:with-option name="active" select="$debug" />
      <p:with-option name="base-uri" select="$debug-dir-uri" />
      <p:input port="source">
        <p:pipe port="conf" step="create-ops"/>
      </p:input>
    </tr:store-debug>
    
    <p:choose name="css-parser-xsl">
      <p:when test="$css-parser = 'regex'">
        <p:output port="result" primary="true"/>
        <p:identity>
          <p:input port="source">
            <p:documentation>The traditional regex-based parser. Use if there are performance issues 
              with large CSS files.</p:documentation>
            <p:document href="http://transpect.io/css-tools/xsl/css-parser.xsl"/>
          </p:input>
        </p:identity>
      </p:when>
      <p:when test="$css-parser = 'REx-css3'">
        <p:output port="result" primary="true"/>
        <p:identity>
          <p:input port="source">
            <p:document href="http://transpect.io/css-tools/xsl/REx_css-parser.xsl"/>
          </p:input>
        </p:identity>
      </p:when>
      <p:otherwise><!-- default $css-parser='REx' -->
        <p:output port="result" primary="true"/>
        <p:identity>
          <p:input port="source">
            <p:documentation>This stylesheet overwrites certain css:expand templates or variables.
              This is done because CSS3 isn't supported completely. In that stylesheet
              text-decoration and other porperties can be changed to supported values. When CSS3 is
              supported it might be necessary to use this input port dynamically.</p:documentation>
            <p:document href="http://transpect.io/css-tools/xsl/css2-1-parser.xsl"/>
          </p:input>
        </p:identity>
      </p:otherwise>
    </p:choose>
    
    <!-- create svg cover -->
    <p:choose name="create-svg-cover">
      <p:when test="$create-svg-cover='true'">
        <p:output port="result">
          <p:pipe port="result" step="store-svg"/>
        </p:output>
        <p:output port="report">
          <p:pipe port="report" step="convert-svg"/>
        </p:output>
        <cx:message>
          <p:with-option name="message" select="'create svg cover ',$cover-href, 'out dir: ', replace($cover-href,'^(.*[/])+(.*)', '$1')">
            <p:pipe port="meta" step="create-ops"/>
          </p:with-option>
        </cx:message>
        <p:xslt name="generate-svg">
          <p:documentation>Stylesheet to render svg cover image</p:documentation>
          <p:input port="source">
            <p:pipe port="cover-svg" step="create-ops"/>
            <p:pipe port="meta-with-uri-resolved-cover-href" step="image-info"/>
          </p:input>
          <p:input port="stylesheet">
            <p:pipe port="create-svg-cover-xsl" step="create-ops"/>
          </p:input>
          <p:input port="parameters">
            <p:empty/>
          </p:input>
        </p:xslt>
        
        <tr:store-debug pipeline-step="epubtools/cover-creation">
          <p:with-option name="active" select="$debug" />
          <p:with-option name="base-uri" select="$debug-dir-uri" />
        </tr:store-debug>
        <p:store name="store-svg">
          <p:with-option name="href" select="replace($cover-href,'\.[a-z]+$','.svg')">
            <p:pipe port="source" step="create-ops"/>
          </p:with-option>
        </p:store>
        
        <p:choose name="convert-svg">
          <p:when test="$convert-svg-cover='true'">
            <p:output port="result">
              <p:pipe port="result" step="convert-cover"/>
            </p:output>
            <p:output port="report">
              <p:pipe port="report" step="convert-cover"></p:pipe>
            </p:output>
            <tr:imagemagick format="png" name="convert-cover">
              <p:with-option name="href" select="replace($cover-href,'\.[a-z]+$','.svg')"/>
              <p:with-option name="outdir" select="replace($cover-href,'^(.*[/])+(.*)', '$1')"/>
              <p:with-option name="debug" select="$debug"/>
              <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
            </tr:imagemagick>
          </p:when>
          <p:otherwise>
            <p:output port="result">
              <p:pipe port="result" step="ident"></p:pipe>
            </p:output>
            <p:output port="report">
              <p:empty/>
            </p:output>
            <p:identity name="ident" >
              <p:input port="source">
                <p:inline>
                  <c:error>no SVG Cover converted</c:error>      
                </p:inline>
              </p:input>
            </p:identity>
          </p:otherwise>
        </p:choose>
      </p:when>
      <p:otherwise>
         <p:output port="result">
          <p:pipe port="result" step="ident"></p:pipe>
        </p:output>
        <p:output port="report">
          <p:empty/>
        </p:output>
        <p:identity name="ident"  >
          <p:input port="source">
            <p:inline>
              <c:error>no SVG Cover created</c:error>      
            </p:inline>
          </p:input>
        </p:identity>
      </p:otherwise>
    </p:choose>


    <p:choose name="image-info">
      <p:xpath-context>
        <p:pipe port="meta" step="create-ops"/>
      </p:xpath-context>
      <p:when test="/epub-config/cover/@href">
        <p:output port="diagnostics" primary="true" sequence="true">
          <p:pipe step="ii" port="report"/>
        </p:output>
        <p:output port="file-uri">
          <p:pipe port="result" step="fu"/>
        </p:output>
        <p:output port="meta-with-uri-resolved-cover-href">
          <p:pipe port="result" step="replace-with-local"/>
        </p:output>
        <p:variable name="href" select="/epub-config/cover/@href">
          <p:pipe port="meta" step="create-ops"/>
        </p:variable>
        <tr:file-uri fetch-http="true" name="fu" make-unique="false">
          <p:with-option name="filename" select="resolve-uri($href, base-uri())">
            <p:documentation>If it is a relative URI, resolve it wrt the HTML source.</p:documentation>
            <p:pipe port="source" step="create-ops"/>
          </p:with-option>
          <p:input port="resolver">
            <p:document href="http://transpect.io/xslt-util/xslt-based-catalog-resolver/xsl/resolve-uri-by-catalog.xsl"/>
          </p:input>
          <p:input port="catalog">
            <p:document href="http://this.transpect.io/xmlcatalog/catalog.xml"/>
          </p:input>
        </tr:file-uri>
        <p:add-attribute attribute-name="href" match="/epub-config/cover" name="replace-with-local">
          <p:with-option name="attribute-value" select="/*/@local-href"/>
          <p:input port="source">
            <p:pipe port="meta" step="create-ops"/>
          </p:input>
        </p:add-attribute>
        <tr:image-identify name="ii">
          <p:with-option name="href" select="/epub-config/cover/@href"/>
        </tr:image-identify>
        <p:sink name="sink1"/>
      </p:when>
      <p:otherwise>
        <p:output port="diagnostics" primary="true">
          <p:pipe step="i" port="result"/>
        </p:output>
        <p:output port="file-uri">
          <p:pipe step="i" port="result"/>
        </p:output>
        <p:output port="meta-with-uri-resolved-cover-href">
          <p:pipe port="meta" step="create-ops"/>
        </p:output>
        <p:identity name="i">
          <p:input port="source">
            <p:inline>
              <c:error>No /epub-config/cover/@href given</c:error>      
            </p:inline>
          </p:input>
        </p:identity>
        <p:sink name="sink1-5"/>
      </p:otherwise>
    </p:choose>

    <tr:store-debug pipeline-step="epubtools/create-ops/cover-image-info">
      <p:with-option name="active" select="$debug" />
      <p:with-option name="base-uri" select="$debug-dir-uri" />
    </tr:store-debug>
  
    <p:sink name="sink2"/>

    <tr:store-debug pipeline-step="epubtools/epub-config">
      <p:with-option name="active" select="$debug" />
      <p:with-option name="base-uri" select="$debug-dir-uri" />
      <p:input port="source">
        <p:pipe port="meta-with-uri-resolved-cover-href" step="image-info"/>
      </p:input>
    </tr:store-debug>
    
    <p:choose name="optionally-use-alternative-head">
      <p:when test="exists(/epub-config/html:head)">
        <p:replace match="/html:html/html:head">
          <p:input port="source">
            <p:pipe port="source" step="create-ops"/>
          </p:input>
          <p:input port="replacement" select="/epub-config/html:head">
            <p:pipe port="meta-with-uri-resolved-cover-href" step="image-info"/>
          </p:input>
        </p:replace>
      </p:when>
      <p:otherwise>
        <p:identity>
          <p:input port="source">
            <p:pipe port="source" step="create-ops"/>
          </p:input>
        </p:identity>
      </p:otherwise>
    </p:choose>
    
    <p:choose name="optionally-remove-scripts">
      <p:xpath-context>
        <p:pipe port="meta-with-uri-resolved-cover-href" step="image-info"/>
      </p:xpath-context>
      <p:when test="/epub-config/@remove-scripts = 'true'">
        <p:delete match="html:script | @*[starts-with(name(), 'on')]"/>
      </p:when>
      <p:otherwise>
        <p:identity/>
      </p:otherwise>
    </p:choose>
    
    <p:delete match="/html:html/@version | /html:html/html:head/@profile" name="delete-dtd-artifacts">
      <p:documentation>Possible DTD parsing artifacts</p:documentation>
    </p:delete>
    
    <p:choose name="epub-type2aria-role">
      <p:when test="($create-a11y-meta = ('yes', 'true')) and $target eq 'EPUB3'">
        <p:xslt>
          <p:input port="stylesheet">
            <p:inline>
              <xsl:stylesheet version="2.0" xmlns:epub="http://www.idpf.org/2007/ops">
                <xsl:import href="http://transpect.io/epubtools/modules/create-ops/xsl/functions.xsl"/>
                
                <xsl:template match="*[not(@role)]/@epub:type">
                  <xsl:copy-of select="."/>
                  <xsl:sequence select="epub:type2aria(., parent::*)"/>
                </xsl:template>
                
                <xsl:template match="@*|node()">
                  <xsl:copy>
                    <xsl:apply-templates select="@*, node()"/>
                  </xsl:copy>
                </xsl:template>
              </xsl:stylesheet>
            </p:inline>
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
    
    <p:choose name="conditionally-check-hrefs">
      <p:xpath-context>
        <p:pipe port="meta" step="create-ops"/>
      </p:xpath-context>
      <p:when test="normalize-space($link-check) and not($link-check = 'false')">
        <p:output port="result" primary="true"/>
        
        <p:variable name="only" select="if (contains($link-check, 'only:'))
                                          then replace($link-check, '^.*only:(.*?)([\|~]never:.*|$)', '$1')
                                          else ''"/>
        <p:variable name="never" select="if (contains($link-check, 'never:')) 
                                         then replace($link-check, '^.*never:(.*?)([\|~]only:.*|$)', '$1')
                                         else ''"/>
        
        
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
            <p:pipe port="current" step="check-hrefs"></p:pipe>
          </p:variable>
          <p:try name="fu2t">
            <p:group>
              <cx:message>
                <!-- to determine which links need especially much time to be resolved -->
                <p:with-option name="message" select="if (not($actual-link-to-be-checked[normalize-space()])) then '- Not ' else '- ', 'Checking URL : [', format-time(current-time(), '[H]:[m]:[s]'), '] ', /*/(@src | @href | @xlink:href | @poster)">
                  <p:pipe port="current" step="check-hrefs"></p:pipe>
                </p:with-option>
              </cx:message>
              <p:choose>
                <p:when test="normalize-space($actual-link-to-be-checked)">
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
        
      </p:when>
      <p:otherwise>
        <p:output port="result" primary="true"/>
        <p:identity/>
      </p:otherwise>
    </p:choose>

    <p:sink/>

    <p:xslt name="attach-cover">
      <p:documentation>If there is not yet a div with an id 'epub-cover-image-container',
      it will be inserted into the body as a first child.</p:documentation>
      <p:with-param name="targetdir" select="$targetdir"/>
      <p:with-param name="use-svg" select="$use-svg"/>
      <p:with-param name="target" select="$target"/>
      <p:input port="source">
        <p:pipe port="result" step="conditionally-check-hrefs"/>
        <p:pipe port="meta-with-uri-resolved-cover-href" step="image-info"/>
        <p:pipe port="diagnostics" step="image-info"/>
        <p:pipe port="file-uri" step="image-info"/>
<!--        <p:pipe port="cover" step="image-info"/>-->
      </p:input>
      <p:input port="stylesheet">
        <p:pipe port="attach-cover-xsl" step="create-ops"/>
      </p:input>
    </p:xslt>
    
    <tr:store-debug pipeline-step="epubtools/create-ops/cover-attached">
      <p:with-option name="active" select="$debug" />
      <p:with-option name="base-uri" select="$debug-dir-uri" />
    </tr:store-debug>
    
    <css:parse name="css-parse0">
      <p:input port="stylesheet">
        <p:pipe port="result" step="css-parser-xsl"/>
      </p:input>
      <p:with-option name="debug" select="$debug"/>
      <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
      <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
      <p:with-option name="remove-comments" select="$css-remove-comments"/>
    </css:parse>
    
    <p:add-attribute match="/*" attribute-name="xml:base" name="css-parse1">
      <p:with-option name="attribute-value" select="concat( $targetdir, 'epub/OEBPS/styles/', $css-filename)"/>
    </p:add-attribute>

    <p:viewport match="*[@src]" name="resolve-resource-uris">
      <tr:file-uri fetch-http="false" name="resource-file-uri">
        <p:with-option name="filename" select="/*/@src"/>
        <p:input port="resolver">
          <p:document href="http://transpect.io/xslt-util/xslt-based-catalog-resolver/xsl/resolve-uri-by-catalog.xsl"/>
        </p:input>
        <p:input port="catalog">
          <p:document href="http://this.transpect.io/xmlcatalog/catalog.xml"/>
        </p:input>
      </tr:file-uri>
      <p:sink/>
      <p:set-attributes match="/*">
        <p:input port="source">
          <p:pipe port="current" step="resolve-resource-uris"/>
        </p:input>
        <p:input port="attributes">
          <p:pipe port="result" step="resource-file-uri"/>
        </p:input>
      </p:set-attributes>
    </p:viewport>
    
    <tr:store-debug pipeline-step="epubtools/create-ops/resolve-resource-uris">
      <p:with-option name="active" select="$debug" />
      <p:with-option name="base-uri" select="$debug-dir-uri" />
    </tr:store-debug>

    <p:sink name="sink3"/>
    
     <p:choose name="conditionally-create-fontsubset">
      <p:when test="$create-font-subset = 'true'">
        <tr:create-font-subset name="subset">
          <p:input port="source">
            <p:pipe port="source" step="create-ops"/>
          </p:input>
          <p:input port="expand-css">
            <p:pipe port="result" step="resolve-resource-uris"/>
          </p:input>
      	  <p:with-option name="min-file-size-kb" select="$font-subset-min-file-size"/>
          <p:with-option name="debug" select="$debug"/>
          <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
        </tr:create-font-subset>
      </p:when>
      <p:otherwise>
        <p:identity>
          <p:input port="source">
            <p:pipe port="source" step="create-ops"/>
          </p:input>
        </p:identity>
      </p:otherwise>
    </p:choose>
    
    <p:sink/>

    <!-- extract file list from html @src and @poster attributes (and from @xlink:href in case of SVG) 
          Unless the procedures have changed in ../xsl/functions.xsl, catalog-based resolution takes
          place in this XSLT step so that at least canonical http://transpect… URIs that point to the repo’s
          resources do not appear as remote resources in the file list.  -->
    <p:xslt name="generate-filelist">
      <p:with-param name="targetdir" select="$targetdir"/>
      <p:with-param name="css-handling" select="$css-handling"/>
      <p:input port="source">
        <p:pipe port="result" step="attach-cover"/>
        <p:pipe port="result" step="resolve-resource-uris"/>
      </p:input>
      <p:input port="stylesheet">
        <p:document href="../xsl/extract-filerefs.xsl"/>
      </p:input>
    </p:xslt>
    
    <p:choose name="conditionally-change-font-subset-name">
      
      <p:when test="$create-font-subset = 'true'">
          <p:output port="result" primary="true"/>
          <p:string-replace match="/cx:document/c:file[@media-type = ('application/vnd.ms-opentype',
                                                                      'application/vnd.ms-fontobject',
                                                                      'font/ttf',
                                                                      'font/woff'
                                                                      )]/@local-href" 
                            replace="concat(.,'.subset')"/>
      </p:when>
     <p:otherwise>
         <p:output port="result" primary="true"/>
       <p:identity/>
     </p:otherwise>
    </p:choose>
    
    <tr:store-debug pipeline-step="epubtools/create-ops/filelist">
      <p:with-option name="active" select="$debug" />
      <p:with-option name="base-uri" select="$debug-dir-uri" />
    </tr:store-debug>
    
    <p:sink/>
    
    <p:xslt name="css-parse">
      <p:input port="source">
        <p:pipe port="result" step="resolve-resource-uris"/>
        <p:pipe port="result" step="conditionally-change-font-subset-name"/>
      </p:input>
      <p:input port="parameters"><p:empty/></p:input>
      <p:input port="stylesheet">
        <p:document href="../xsl/add-local-resource-paths-to-css.xsl"/>
      </p:input>
    </p:xslt>

    <tr:store-debug pipeline-step="epubtools/create-ops/parse-css">
      <p:with-option name="active" select="$debug" />
      <p:with-option name="base-uri" select="$debug-dir-uri" />
    </tr:store-debug>

    <p:sink/>

    <!-- copy resources -->
    <p:viewport match="c:file" name="file-iteration">
      <p:viewport-source>
        <p:pipe port="result" step="conditionally-change-font-subset-name"/>
      </p:viewport-source>
      <p:output port="result" primary="true">
        <p:pipe port="result" step="http-or-file"/>
      </p:output>
      <p:variable name="uri" select="(/c:file/@href, /c:file/@oebps-name)[1]"/>

      <!-- create target directory -->
      <cxf:mkdir>
        <p:with-option name="href" select="/c:file/@target-dir"/>
      </cxf:mkdir>

      <p:choose name="http-or-file">
        <p:when test="matches($uri, 'https?:')">
          <p:output port="result" primary="true">
            <p:pipe port="result" step="apply-hash"/>
          </p:output>
          
          <!-- construct GET-request -->
          <p:add-attribute match="/c:request" attribute-name="href">
            <p:input port="source">
              <p:inline>
                <c:request method="GET"/>
              </p:inline>
            </p:input>
            <p:with-option name="attribute-value" select="$uri"/>
          </p:add-attribute>
          
          <p:try name="http-request">
            <p:group>
              <p:output port="result" primary="true"/>
              
              <p:http-request/>
              
              <tr:store-debug>
                <p:with-option name="pipeline-step" select="concat('epubtools/create-ops/http-requests/', c:file/@name)">
                  <p:pipe port="current" step="file-iteration"/>
                </p:with-option>
                <p:with-option name="active" select="$debug" />
                <p:with-option name="base-uri" select="$debug-dir-uri" />
              </tr:store-debug>
              
            </p:group>
            <p:catch name="catch">
              <p:output port="result" primary="true"/>
              
              <p:identity>
                <p:input port="source">
                  <p:pipe port="error" step="catch"/>
                </p:input>
              </p:identity>
              
            </p:catch>
          </p:try>
        
          <p:sink  name="sink5"/>
          
          <p:add-attribute attribute-name="query-hash" match="/*" attribute-value="">
            <p:input port="source">
              <p:pipe port="current" step="file-iteration"/>
            </p:input>
          </p:add-attribute>
          
          <p:hash algorithm="crc" match="@query-hash" name="hashing"> 
            <p:with-option name="value" select="/*/@query-string"/> 
            <p:input port="parameters"><p:empty/></p:input> 
          </p:hash>  
          
          <p:sink  name="sink6"/>
             
          <p:xslt name="apply-hash">
            <p:input port="source">
              <p:pipe step="hashing" port="result"/>
              <p:pipe port="result" step="http-request"/>
            </p:input>
            <p:input port="parameters">
              <p:empty/>
            </p:input>
            <p:input port="stylesheet">
              <p:document href="../xsl/apply-hash.xsl"/>
            </p:input>
          </p:xslt>
          
          <tr:store-debug>
            <p:with-option name="pipeline-step" select="concat('epubtools/create-ops/files/', c:file/@name)">
              <p:pipe port="current" step="file-iteration"/>
            </p:with-option>
            <p:with-option name="active" select="$debug" />
            <p:with-option name="base-uri" select="$debug-dir-uri" />
          </tr:store-debug>
          
          <p:store name="store-http-resource" cx:decode="true">
            <p:input port="source">
              <p:pipe port="result" step="http-request"/>
            </p:input>
            <p:with-option name="href" select="c:file/@target-filename">
              <p:pipe port="result" step="apply-hash"/>
            </p:with-option>
          </p:store>
          
          <tr:store-debug>
            <p:input port="source">
              <p:pipe port="result" step="apply-hash"/>
            </p:input>
            <p:with-option name="pipeline-step" select="concat('epubtools/create-ops/filelist-after-patch/', c:file/@name)">
              <p:pipe port="current" step="file-iteration"/>
            </p:with-option>
            <p:with-option name="active" select="$debug" />
            <p:with-option name="base-uri" select="$debug-dir-uri" />
          </tr:store-debug>

          <p:sink/>
          
        </p:when>
        <p:otherwise>
          <p:output port="result" primary="true">
            <p:pipe port="result" step="try-copy"/>
          </p:output>
          
          <p:try name="try-copy">
            <p:group>
              <p:output port="result">
                <p:pipe port="result" step="copy"/>
              </p:output>
              <cxf:info name="file-exists">
                <p:with-option name="href" select="c:file/@local-href">
                  <p:pipe port="current" step="file-iteration"/>
                </p:with-option>
              </cxf:info>

              <p:for-each name="copy">
                <p:output port="result" primary="true">
                  <p:pipe step="file-iteration" port="current"/>
                </p:output>
   
                <cxf:copy name="cp">
                  <p:with-option name="fail-on-error" select="if ($terminate-on-error = 'yes') then 'true' else 'false'"/>
                  <p:with-option name="target" select="c:file/@target-filename">
                    <p:pipe port="current" step="file-iteration"/>
                  </p:with-option>
                  <p:with-option name="href" select="c:file/@local-href">
                  <p:pipe port="current" step="file-iteration"/>
                  </p:with-option>
                </cxf:copy>  

              </p:for-each>

            </p:group>
            
            <p:catch name="catch">
              <p:output port="result">
                <p:pipe port="result" step="is-error"/>
              </p:output>
              <tr:store-debug pipeline-step="epubtools/create-ops/copy-error">
                <p:input port="source"><p:pipe port="error" step="catch"/>
                </p:input>
                <p:with-option name="active" select="$debug" />
                <p:with-option name="base-uri" select="$debug-dir-uri" />
              </tr:store-debug>
              <p:store method="text" name="dummy">
                <p:input port="source">
                  <p:inline><dummy>1</dummy></p:inline>
                </p:input>
                <p:with-option name="href" select="c:file/@target-filename">
                  <p:pipe port="current" step="file-iteration"/>
                </p:with-option>
              </p:store>
              <p:add-attribute name="is-text-file" attribute-name="media-type" attribute-value="text/plain"
                match="/c:file">
                <p:input port="source">
                  <p:pipe port="current" step="file-iteration"/>  
                </p:input>
              </p:add-attribute>
              <p:add-attribute name="is-error" match="/*" attribute-name="error" 
                attribute-value="File not found (or copying failed for another reason)" />
            </p:catch>
          </p:try>
          <p:sink name="sink6-5"/>
        </p:otherwise>
      </p:choose>
    </p:viewport>
   
  </p:group>

  <p:viewport match="c:file[@media-type=('image/jpeg', 'image/png')]" name="ii-content0">
    <p:output port="result" primary="true"/>
    <tr:image-identify name="iiii">
      <p:with-option name="href" select="/*/@target-filename"/>
    </tr:image-identify>
    <p:sink/>
    <cxf:info fail-on-error="false" name="ii-content-info">
      <p:with-option name="href" select="/*/@target-filename">
        <p:pipe port="current" step="ii-content0"/>
      </p:with-option>
    </cxf:info>
    <p:sink/>
    <p:set-attributes match="/*">
      <p:input port="source">
        <p:pipe port="current" step="ii-content0"/>
      </p:input>
      <p:input port="attributes">
        <p:pipe port="result" step="ii-content-info"/>
      </p:input>
    </p:set-attributes>
    <p:insert match="/*" position="last-child">
      <p:input port="insertion">
        <p:pipe port="report" step="iiii"/>
      </p:input>
    </p:insert>
  </p:viewport>

  <tr:store-debug pipeline-step="epubtools/create-ops/image-identify-content" name="ii-content">
    <p:with-option name="active" select="$debug" />
    <p:with-option name="base-uri" select="$debug-dir-uri" />
  </tr:store-debug>

  <p:sink  name="sink7"/>
    
  <p:validate-with-relax-ng name="validate-metadata-conf">
      <p:with-option name="assert-valid" select="'false'"/>
    <p:input port="source">
      <p:pipe port="meta-with-uri-resolved-cover-href" step="copy-resources"/>
    </p:input>
    <p:input port="schema">
      <p:document href="../../../schema/metadata-conf/metadata-conf.rng"/>
    </p:input>
  </p:validate-with-relax-ng>

  <tr:store-debug pipeline-step="epubtools/create-ops/validate-metadata-conf" extension="xml">
    <p:with-option name="active" select="$debug" />
    <p:with-option name="base-uri" select="$debug-dir-uri" />
  </tr:store-debug>

  <p:sink name="sink-valhierarchy"/>
  
  <p:documentation>Hashed file names are patched into the HTML before split</p:documentation>
  <p:xslt name="patch-http-hrefs">
    <p:input port="source">
      <p:pipe port="html" step="copy-resources"/>
      <p:pipe port="result" step="ii-content"/>
    </p:input>
    <p:input port="parameters">
      <p:empty/>
    </p:input>
    <p:input port="stylesheet">
      <p:document href="../xsl/patch-http-hrefs.xsl"/>
    </p:input>
  </p:xslt>
  
  <p:delete match="@error-status | @checked-href">
    <p:documentation>Remove artifacts from link checking</p:documentation>
  </p:delete>

  <tr:store-debug pipeline-step="epubtools/create-ops/pre-split" extension="html">
    <p:with-option name="active" select="$debug" />
    <p:with-option name="base-uri" select="$debug-dir-uri" />
  </tr:store-debug>
  
  <!-- split html and generate toc.ncx -->
  <epub:html-splitter name="html-splitter">
    <p:input port="conf">
      <p:pipe port="conf" step="create-ops"/>
    </p:input>
    <p:input port="meta">
      <p:pipe port="meta-with-uri-resolved-cover-href" step="copy-resources"/>
    </p:input>
    <p:input port="css-xml">
      <p:pipe port="css-xml" step="copy-resources"/>
    </p:input>
    <p:with-option name="base-uri" select="$base-uri"/>
    <p:with-option name="target" select="$target"/>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </epub:html-splitter>

  <p:viewport match="c:file[@media-type='application/xhtml+xml']" name="html-file-size">
    <p:viewport-source>
      <p:pipe port="files" step="html-splitter"/>
    </p:viewport-source>
    <p:output port="result" primary="true"/>
    
    <cxf:info fail-on-error="false" name="html-file-info">
      <p:with-option name="href" select="/*/@target-filename">
        <p:pipe port="current" step="html-file-size"/>
      </p:with-option>
    </cxf:info>
    
    <p:sink/>
    
    <p:set-attributes match="/*">
      <p:input port="source">
        <p:pipe port="current" step="html-file-size"/>
      </p:input>
      <p:input port="attributes">
        <p:pipe port="result" step="html-file-info"/>
      </p:input>
    </p:set-attributes>
    
  </p:viewport>
  
  <p:sink/>
  
  <p:xslt name="prune-filelist">
    <p:documentation>If CSS handling is set to 'regenerate-per-split', the splitter will return a css:css document
    with XML representations of @font-face at rules (and potentially other stuff, such as background images) that
    was detected as being unutilized in any of the split HTML file. We may now remove the local URLs from the file
    list that correspond to //css:resource/@href attributes in the document on the splitter’s unused-css-resources 
    port.</p:documentation>
    <p:input port="source">
      <p:pipe port="result" step="ii-content"/>
      <p:pipe port="unused-css-resources" step="html-splitter"/>
    </p:input>
    <p:input port="parameters">
      <p:empty/>
    </p:input>
    <p:input port="stylesheet">
      <p:inline>
        <xsl:stylesheet version="2.0">
          <xsl:variable name="resource-hrefs" as="xs:string*" select="collection()//css:resource/@href"/>
          <xsl:template match="*|@*">
            <xsl:copy copy-namespaces="no">
              <xsl:apply-templates select="@*, node()"/>
            </xsl:copy>
          </xsl:template>
          <xsl:template match="c:file[@href = $resource-hrefs]"/>
        </xsl:stylesheet>
      </p:inline>
    </p:input>
  </p:xslt>

  <p:wrap-sequence wrapper="cx:document">
    <p:input port="source" select="/cx:document/c:file">
      <p:pipe port="result" step="prune-filelist"/>
      <p:pipe port="result" step="html-file-size"/>
    </p:input>
  </p:wrap-sequence>

  <p:add-attribute match="/*" attribute-name="name" attribute-value="wrap-file-uris"/>

  <tr:store-debug pipeline-step="epubtools/create-ops/wrap-file-uris" name="wrap-file-uris">
    <p:with-option name="active" select="$debug" />
    <p:with-option name="base-uri" select="$debug-dir-uri" />
  </tr:store-debug>
  
  <p:sink name="sink10"/>
  
  <tr:store-debug pipeline-step="epubtools/create-ops/wrap-files">
    <p:input port="source">
      <p:pipe port="result" step="html-splitter"/>
    </p:input>
    <p:with-option name="active" select="$debug" />
    <p:with-option name="base-uri" select="$debug-dir-uri" />
  </tr:store-debug>
  
  <p:sink/>
  
</p:declare-step>
