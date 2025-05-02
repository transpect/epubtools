<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:epub="http://transpect.io/epubtools"
  xmlns:tr="http://transpect.io" 
  xmlns:css="http://www.w3.org/1996/css" 
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
  type="epub:html-splitter" 
  name="html-splitter" 
  version="1.0">

  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    <p>Sample invocation (for debugging purposes):</p>
    <pre>calabash/calabash.sh 
    -i source=file:/$(cygpath -ma ../content/output/debug/epubtools/create-ops/pre-split.html) 
    -i meta=file:/$(cygpath -ma a9s/publisher/series/epubtools/heading-conf.xml) 
    -o result=tmp.html -o report=report.xml -o files=files.xml  
    file:/$(cygpath -ma epubtools/modules/html-splitter/xpl/html-splitter.xpl) 
    base-uri=file:/$(cygpath -ma ../content/output/debug/epubtools/create-ops/pre-split.html)
    debug=yes
    debug-dir-uri=file:/$(cygpath -ma ../content/output/debug)</pre>
    <p>Calabash seems to suppress some XSLT errors, for instance when a stylesheet is looping. Therefore it might be
      necessary to replace collection()[…] with document(…) in the XSL (alternative variable declarations are already
      included in the xsl file, commented out) and run saxon from the command line, for example like this:</p>
    <pre>saxon -xsl:epubtools/modules/html-splitter/xsl/html-splitter.xsl -it:main \ 
      collection-uri=file:/path/to/debugdir/epubtools/html-splitter/…/splitter-input.catalog.xml) \ 
      -s:[any.xml] debug=yes debug-dir-uri=file:/other/path/to/debug/dir</pre>
  </p:documentation>

  <p:input port="source" primary="true"/>
  <p:input port="conf" primary="false" sequence="true">
    <p:documentation>/hierarchy – may be included in /epub-config</p:documentation>
  </p:input>
  <p:input port="meta" primary="false">
    <p:documentation>/epub-config</p:documentation>
  </p:input>
  <p:input port="css-xml">
    <p:documentation>XML representation of the parsed CSS</p:documentation>
  </p:input>
  <p:output port="result" primary="true">
    <p:pipe port="result" step="html-splitter-group"/>
  </p:output>
  <p:output port="files" primary="false">
    <p:pipe port="files" step="html-splitter-group"/>
  </p:output>
  <p:output port="report">
    <p:pipe port="result" step="report"/>
  </p:output>
  <p:output port="unused-css-resources" sequence="true">
    <p:pipe port="unused-css-resources" step="html-splitter-group"/>
  </p:output>
  <p:output port="splitting-report" sequence="true">
    <p:pipe port="splitting-report" step="html-splitter-group"/>
  </p:output>

  <p:option name="base-uri" required="true" cx:type="xsd:anyURI"/>
  <p:option name="target" select="'EPUB2'" cx:type="xsd:string"/>
  <p:option name="debug" select="'no'" cx:type="xsd:string"/>
  <p:option name="debug-dir-uri" select="'debug'" cx:type="xsd:string"/>
  <p:option name="pull-up-epub-type-to-body" select="'false'" cx:type="xsd:string" required="false"/>
  
  <p:import href="split-css.xpl"/>
  <p:import href="insert-amzn-region-magnification.xpl"/>

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  <p:import href="http://transpect.io/xproc-util/simple-progress-msg/xpl/simple-progress-msg.xpl"/>

  <p:variable name="css-handling" select="(/epub-config/@css-handling, 'regenerated-per-split')[1]">
    <p:pipe port="meta" step="html-splitter"/>
  </p:variable>

  <p:variable name="html-subdir-name" select="(/epub-config/@html-subdir-name, '')[1]">
    <p:pipe port="meta" step="html-splitter"/>
  </p:variable>
  
  <p:variable name="amzn-region-magnification" select="(/epub-config/metadata/meta[@name eq 'RegionMagnification']/@content, '')[1]">
    <p:pipe port="meta" step="html-splitter"/>
  </p:variable>
  
  <p:variable name="svg-scale-hack" select="(/epub-config/cover/@svg-scale-hack, 'true')[1]">
    <p:pipe port="meta" step="html-splitter"/>
  </p:variable>

  <p:identity name="strip-leading-non-elements">
    <p:documentation>Strip spurious text-only document nodes that sometimes occured before the HTML
      document.</p:documentation>
    <p:input port="source" select="/html:html">
      <p:pipe port="source" step="html-splitter"/>
    </p:input>
  </p:identity>

  <p:try name="html-splitter-group">
    <p:documentation>You might need to comment out this p:try/p:catch and move name="html-splitter-group" to the
      following p:group in order to facilitate debugging if there is an error in the splitter XSLT. In extreme cases, it
      might be necessary to invoke the XSLT directly. For instructions, see the comments after the xsl:param
      instructions in html-splitter.xsl.</p:documentation>
    <p:group>
      <p:output port="files" primary="false">
        <p:pipe port="result" step="wrap-chunk-uris"/>
      </p:output>
      <p:output port="result" primary="true">
        <p:pipe port="result" step="wrap-chunks"/>
      </p:output>
      <p:output port="report">
        <p:inline>
          <c:ok tr:step-name="html-splitter" tr:rule-family="pipeline"/>
        </p:inline>
      </p:output>
      <p:output port="unused-css-resources" sequence="true">
        <p:pipe port="unused-css-resources" step="per-split-css"/>
      </p:output>
      <p:output port="splitting-report" sequence="true">
        <p:pipe port="result" step="splitting-report"/>
      </p:output>

      <p:variable name="workdir" select="replace($base-uri, '^(.*[/])+(.*)', '$1')">
        <p:pipe port="result" step="strip-leading-non-elements"/>
      </p:variable>

      <p:variable name="basename" select="replace($base-uri, '^(.*[/])+(.*?)(\.[\w.]+)$', '$2')">
        <p:pipe port="result" step="strip-leading-non-elements"/>
      </p:variable>

      <p:variable name="indent" select="(/epub-config/@indent, 'true')[1]">
        <p:pipe port="meta" step="html-splitter"/>
      </p:variable>

      <cx:message>
        <p:with-option name="message" select="concat('[INFO] split of input basename=', $basename, ' in workdir: ', $workdir)"/>
      </cx:message>

      <p:identity name="splitter-xsl-source">
        <p:input port="source">
          <p:pipe port="result" step="strip-leading-non-elements"/>
          <p:pipe port="conf" step="html-splitter"/>
          <p:pipe port="meta" step="html-splitter"/>
        </p:input>
      </p:identity>

      <tr:store-debug>
        <p:with-option name="pipeline-step" select="concat('epubtools/html-splitter/', $basename, '/splitter-input')"
          ><p:empty/></p:with-option>
        <p:with-option name="active" select="$debug"><p:empty/></p:with-option>
        <p:with-option name="base-uri" select="$debug-dir-uri"><p:empty/></p:with-option>
      </tr:store-debug>
      
      <p:xslt name="split" template-name="main">
        <p:with-param name="debug" select="$debug"><p:empty/></p:with-param>
        <p:with-param name="debug-dir-uri" select="replace($debug-dir-uri, '^(.+)\?.*$', '$1')"><p:empty/></p:with-param>
        <p:with-param name="final-pub-type" select="$target"><p:empty/></p:with-param>
        <p:with-param name="indent" select="$indent"><p:empty/></p:with-param>
        <p:with-param name="datadir" select="$workdir"><p:empty/></p:with-param>
        <p:with-param name="basename" select="$basename"><p:empty/></p:with-param>
        <p:with-param name="html-subdir-name" select="$html-subdir-name"><p:empty/></p:with-param>
        <p:with-param name="pull-up-epub-type-to-body" select="$pull-up-epub-type-to-body"><p:empty/></p:with-param>
        <p:input port="stylesheet">
          <p:document href="../xsl/html-splitter.xsl"/>
        </p:input>
      </p:xslt>
      
      <!--<cx:message>
          <p:with-option name="message" select="'PRIMARY-SPLIT: ', base-uri(), ' :: ', base-uri(/*)"/>
        </cx:message>-->

      <tr:store-debug>
        <p:with-option name="pipeline-step" select="concat('epubtools/html-splitter/', $basename, '/chunks')"/>
        <p:with-option name="active" select="$debug"/>
        <p:with-option name="base-uri" select="$debug-dir-uri"/>
      </tr:store-debug>

      <p:for-each name="store-debug-try">
        <p:iteration-source select="/*[matches(base-uri(), '/epubtools/html-splitter/')]">
          <p:pipe port="secondary" step="split"/>
        </p:iteration-source>
        <!--<cx:message>
          <p:with-option name="message" select="'SECONDARY-SPLIT: ', base-uri(), ' :: ', base-uri(/*)"/>
        </cx:message>-->
        <p:store>
          <p:with-option name="href" select="base-uri()"/>
        </p:store>
      </p:for-each>

      <p:identity name="splitting-report">
        <p:input port="source" select="/*[matches(base-uri(), '07\.output-file-names\.xhtml$')]//html:body">
          <p:pipe port="secondary" step="split"/>
        </p:input>
      </p:identity>

      <p:sink/>
      
      <epub:split-css name="per-split-css" cx:depends-on="store-debug-try">
        <p:input port="source">
          <p:pipe port="secondary" step="split"/>
        </p:input>
        <p:input port="css-xml">
          <p:pipe port="css-xml" step="html-splitter"/>
        </p:input>
        <p:with-option name="target" select="$target"/>
        <p:with-option name="css-handling" select="$css-handling"/>
        <p:with-option name="svg-scale-hack" select="$svg-scale-hack"/>
        <p:with-option name="basename" select="$basename"/>
        <p:with-option name="html-subdir-name" select="$html-subdir-name"/>
        <p:with-option name="common-source-dir-elimination-regex" select="/*/@common-dir-elimination-regex">
          <p:pipe port="result" step="split"/>
        </p:with-option>
        <p:with-option name="debug" select="$debug"/>
        <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
      </epub:split-css>
      
      <!--<p:for-each>
        <cx:message>
          <p:with-option name="message" select="'PRIMARY-PER-SPLIT-CSS: ', base-uri(), ' :: ', /*/name(), ' :: ', base-uri(/*)"/>
        </cx:message>
      </p:for-each>-->
      
      <p:sink/>
      
      <epub:insert-amzn-region-magnification name="insert-amzn-region-magnification" cx:depends-on="per-split-css">
        <p:input port="source" select="/*">
          <p:pipe port="result" step="per-split-css"/>
        </p:input>
        <p:with-option name="amzn-region-magnification" select="$amzn-region-magnification"/>
        <p:with-option name="debug" select="$debug"/>
        <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
      </epub:insert-amzn-region-magnification>
      
      <!--  *
            * the store-chunks step iterates over the file-uris and store them
            * regarding their file extension and the output target
            * -->
      <p:for-each name="store-chunks" cx:depends-on="insert-amzn-region-magnification">
        <p:output port="files" sequence="true">
          <p:documentation>sequence should be meaningless on a p:for-each output port. However,
          Calabash 1.3.2 for Saxon 10 complains:
[main] ERROR com.xmlcalabash.runtime.XAtomicStep - err:XD0006:Writing to files on store-chunks
[main] ERROR com.xmlcalabash.drivers.Main - If sequence is not specified, or has the value false, then it is a dynamic error unless exactly one document appears on the declared port.
          </p:documentation>
          <p:pipe port="result" step="collect-file-uri"/>
        </p:output>
        <p:output port="result" primary="true">
          <p:pipe port="result" step="patch-xml-base"/>
        </p:output>

        <p:iteration-source>
          <p:pipe port="result" step="insert-amzn-region-magnification"/>
        </p:iteration-source>
        
        <p:variable name="chunk-file-uri" select="replace(
                                                    replace(base-uri(/*), '/(debug|chunks)/new-uri/', '/$1/'), 
                                                    'chunks/', 
                                                    'epub/OEBPS/'
                                                  )">
          <p:documentation>base-uri(/*) instead of base-uri() because we set the base uri of the primary CSS by adding
            an xml:base attribute.</p:documentation>
        </p:variable>

        <p:choose xmlns:epub="http://www.idpf.org/2007/ops">
          <p:when test="$target = 'EPUB3' 
                        and matches(base-uri(), 'nav\.xhtml$') 
                        and (normalize-space($html-subdir-name))">
            <p:documentation>Brute force link correction for the generated landmarks nav that will be 
              stored to OEBPS even when the remainder of the HTML is stored to a subdir. Links to nav.xhtml 
              itself and internal links are excluded.</p:documentation>
            <p:viewport match="html:nav[@epub:type = 'landmarks']//html:a[not(matches(@href, '^(#|nav.xhtml)'))]">
              <p:add-attribute match="html:a" attribute-name="href">
                <p:with-option name="attribute-value" select="concat($html-subdir-name, '/', /*/@href)"/>
              </p:add-attribute>
            </p:viewport>
          </p:when>
          <p:otherwise>
            <p:identity/>
          </p:otherwise>
        </p:choose>

        <p:identity name="postprocessing"/>

        <p:delete match="@srcpath | @source-dir-uri"/>

        <p:choose xmlns:epub="http://www.idpf.org/2007/ops">
          <!--  *
                * store NCX file from virtual documents 
                * -->
          <p:when test="matches($chunk-file-uri, '\.ncx$' )">
            <p:store include-content-type="true" name="store-chunk" omit-xml-declaration="false" indent="true">
              <p:with-option name="href" select="$chunk-file-uri"/>
              <p:with-option name="doctype-public"
                select="if($target eq 'EPUB3') 
                          then '' 
                          else '-//NISO//DTD ncx 2005-1//EN'"/>
              <p:with-option name="doctype-system"
                select="if($target eq 'EPUB3') 
                          then '' 
                          else 'http://www.daisy.org/z3986/2005/ncx-2005-1.dtd'"
              />
            </p:store>
          </p:when>
          <!--  *
                * store plain text files 
                * -->
          <p:when test="matches($chunk-file-uri, '\.(txt|css)$')">
            <p:store method="text" encoding="UTF-8">
              <p:with-option name="href" select="$chunk-file-uri"/>
            </p:store>
          </p:when>
          <!--  *
                * XML
                * -->
          <p:when test="matches($chunk-file-uri, '\.(xml|smil)$')">
            <p:store name="store-chunk" omit-xml-declaration="false" method="xml">
              <p:with-option name="indent" select="if ($indent = 'true') then 'true' else 'false'"/>
              <p:with-option name="href" select="$chunk-file-uri"/>
            </p:store>
          </p:when>
          <!--  *
                * nav document
                * -->
          <p:when test="$target = 'EPUB3' 
                        and matches(base-uri(), 'nav\.xhtml$') 
                        and (normalize-space($html-subdir-name))">
            <p:store include-content-type="false" name="store-chunk" omit-xml-declaration="false" method="xhtml">
              <p:with-option name="indent" select="if ($indent = 'true') then 'true' else 'false'"/>
              <p:with-option name="href" select="$chunk-file-uri"/>
            </p:store>
          </p:when>
          <!--  *
                * store as XHTML5 files for EPUB3 format
                * -->
          <p:when test="$target eq 'EPUB3'">
            <p:delete match="html:meta[@name = 'sequence']"/>
            
              <p:store include-content-type="false" name="store-chunk" omit-xml-declaration="false" method="xhtml">
                <p:with-option name="indent" select="if ($indent = 'true') then 'true' else 'false'"/>
                <p:with-option name="href" select="$chunk-file-uri"/>
              </p:store>            
            
          </p:when>
          <p:when test="$target = ('EPUB2', 'KF8') 
                        and matches(base-uri(), 'nav\.xhtml$')">
            <p:documentation>drop nav.xhtml for EPUB2</p:documentation>
            <p:sink/>
          </p:when>
          <!--  *
                * store as XHTML 1.1 files for EPUB2 format
                * -->
          <p:otherwise>
            
            <p:delete match="html:meta[@name = 'sequence'] | @epub:type | html:nav[@epub:type = 'landmarks']"/>
            
            <p:rename match="html:nav" new-name="div" new-namespace="http://www.w3.org/1999/xhtml"/>
            
            <p:store include-content-type="true" name="store-chunk" omit-xml-declaration="false" method="xhtml"
              doctype-public="-//W3C//DTD XHTML 1.1//EN" doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
              <p:with-option name="indent" select="if ($indent = 'true') then 'true' else 'false'"/>
              <p:with-option name="href" select="$chunk-file-uri"/>
            </p:store>
            
          </p:otherwise>
        </p:choose>

        <p:xslt name="collect-file-uri">
          <p:with-param name="stored-file" select="$chunk-file-uri"/>
          <p:with-param name="debug-dir-uri" select="replace($debug-dir-uri, '^(.+)\?.*$', '$1')"/>
          <p:input port="source">
            <p:pipe port="current" step="store-chunks"/>
          </p:input>
          <p:input port="stylesheet">
            <p:document href="../xsl/collect-file-uri.xsl"/>
          </p:input>
        </p:xslt>
        
        <tr:store-debug>
          <p:with-option name="pipeline-step" select="concat('epubtools/html-splitter/', $basename, '/collect-file-uri')"/>
          <p:with-option name="active" select="$debug"/>
          <p:with-option name="base-uri" select="$debug-dir-uri"/>
        </tr:store-debug>

        <p:sink/>

        <p:add-attribute name="patch-xml-base" attribute-name="xml:base" match="/*">
          <p:input port="source">
            <p:pipe port="result" step="postprocessing"/>
          </p:input>
          <p:with-option name="attribute-value" select="$chunk-file-uri"/>
        </p:add-attribute>

      </p:for-each>

      <p:sink/>

      <p:for-each name="signal-splitting-error">
        <p:documentation>The presence of an orig.txt is an indicator that the split text differs from the original text.
          We’ll raise an error. We don’t do it immediately within the split step because we want to store the results
          first so that you can do forensics.</p:documentation>
        <p:iteration-source select="/*[matches(base-uri(), 'orig.txt$')]">
          <p:pipe port="secondary" step="split"/>
        </p:iteration-source>
        <p:store method="text" name="store-orig-txt">
          <p:with-option name="href" select="base-uri()"/>
        </p:store>
        <p:identity>
          <p:input port="source" select="/*[matches(base-uri(), 'chunks.txt$')]">
            <p:pipe port="secondary" step="split"/>
          </p:input>
        </p:identity>
        <p:store method="text" name="store-chunks-txt" cx:depends-on="store-orig-txt">
          <p:with-option name="href" select="base-uri()"/>
        </p:store>
        <p:for-each name="store-debug" cx:depends-on="store-chunks-txt">
          <p:iteration-source select="/*[matches(base-uri(), '/epubtools/html-splitter/.+\.x(ht)?ml$')]">
            <p:pipe port="secondary" step="split"/>
          </p:iteration-source>
          <p:store>
            <p:with-option name="href" select="base-uri()"/>
          </p:store>
        </p:for-each>
        <p:add-attribute match="/html:p/html:a[1]" name="orig-txt-url" attribute-name="href" cx:depends-on="store-debug">
          <p:with-option name="attribute-value" select="base-uri()"/>
          <p:input port="source">
            <p:inline>
              <p xmlns="http://www.w3.org/1999/xhtml">The after-split text differs from the pre-split text. This
                typically occurs when there is bare text content on the same level as headings. Please check your HTML
                input and/or its generation process. If debugging is switched on, you’ll find two files, <a>orig.txt</a>
                and <a>chunks.txt</a>, that you may diff line by line.</p>
            </p:inline>
          </p:input>
        </p:add-attribute>
        <p:add-attribute match="/html:p/html:a[2]" name="chunks-txt-url" attribute-name="href">
          <p:with-option name="attribute-value" select="replace(base-uri(), 'orig\.txt$', 'chunks.txt')">
            <p:pipe port="current" step="signal-splitting-error"/>
          </p:with-option>
        </p:add-attribute>
        <p:error code="epub:SPLT01" name="splitting-error">
          <p:input port="source">
            <p:pipe port="result" step="chunks-txt-url"/>
          </p:input>
        </p:error>
      </p:for-each>

      <p:wrap-sequence wrapper="document" wrapper-namespace="http://xmlcalabash.com/ns/extensions" wrapper-prefix="cx">
        <p:input port="source">
          <p:pipe port="result" step="store-chunks"/>
        </p:input>
      </p:wrap-sequence>

      <p:add-attribute match="/*" attribute-name="name" attribute-value="wrap-chunks" name="wrap-chunks"/>

      <p:wrap-sequence wrapper="document" wrapper-namespace="http://xmlcalabash.com/ns/extensions" wrapper-prefix="cx">
        <p:input port="source">
          <p:pipe port="files" step="store-chunks"/>
        </p:input>
      </p:wrap-sequence>

      <tr:store-debug name="wrap-chunk-uris">
        <p:with-option name="pipeline-step" select="concat('epubtools/html-splitter/', $basename, '/result')"/>
        <p:with-option name="active" select="$debug"/>
        <p:with-option name="base-uri" select="$debug-dir-uri"/>
      </tr:store-debug>
      
    </p:group>

    <p:catch name="split-failed">
      <p:output port="files" primary="false">
        <p:pipe port="result" step="strip-leading-non-elements"/>
      </p:output>
      <p:output port="result" primary="true">
        <p:pipe port="result" step="strip-leading-non-elements"/>
      </p:output>
      <p:output port="report">
        <p:pipe port="result" step="errors"/>
      </p:output>
      <p:output port="unused-css-resources" sequence="true">
        <p:empty/>
      </p:output>
      <p:output port="splitting-report" sequence="true">
        <p:empty/>
      </p:output>
      
      <p:variable name="basename" select="replace($base-uri, '^(.*[/])+(.*?)(\.[\w.]+)$', '$2')">
        <p:pipe port="result" step="strip-leading-non-elements"/>
      </p:variable>
      
      <tr:propagate-caught-error name="propagate" msg-file="splitter-error.txt" code="epub:SPLT01">
        <p:with-option name="status-dir-uri" select="concat(replace($debug-dir-uri, '^(.+)\?.*$', '$1'), '/status')"/>
        <p:input port="source">
          <p:pipe port="error" step="split-failed"/>
        </p:input>
      </tr:propagate-caught-error>
      
      <tr:store-debug name="store-error-message">
        <p:with-option name="pipeline-step" select="concat('epubtools/html-splitter/', $basename, '/ERROR_split')"/>
        <p:with-option name="active" select="$debug"/>
        <p:with-option name="base-uri" select="$debug-dir-uri"/>
      </tr:store-debug>
      
      <cx:message>
        <p:with-option name="message" select="'[ERROR] split failed with error message: ', ."/>
      </cx:message>
      
      <p:identity name="errors"/>
      
      <p:sink/>
      
    </p:catch>
  </p:try>

  <p:add-attribute match="/*" attribute-name="tr:step-name" attribute-value="html-splitter">
    <p:input port="source">
      <p:pipe port="report" step="html-splitter-group"/>
    </p:input>
  </p:add-attribute>
  <p:add-attribute match="/*" attribute-name="tr:rule-family" attribute-value="html-splitter" name="report"/>

</p:declare-step>