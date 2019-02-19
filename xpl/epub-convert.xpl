<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:cxf="http://xmlcalabash.com/ns/extensions/fileutils"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:epub="http://transpect.io/epubtools" 
  xmlns:tr="http://transpect.io"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:opf="http://www.idpf.org/2007/opf" 
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:ops="http://www.idpf.org/2007/ops" 
  version="1.0"
  type="epub:convert"
  name="epub-convert">

  <p:documentation xmlns="http://www.w3.org/1999/xhtml"> 
    <p>This step takes a HTML file as input and converts it to an epub file. You need a configuration for the HTML splitting and
      the OPF metadata. Examples can be found in the sample directory. Invoke this step on the command line with:</p>
    <pre><code>calabash/calabash.sh -i source=sample/b978-3-646-92351-3.xhtml 
  -i conf=sample/hierarchy.xml -i meta=sample/epub-config.xml epub-convert.xpl </code></pre>
    <p>Note that it’s advisable to make all file inputs absolute URIs, by using <code>cygpath</code> on Cygwin or <code>readlink -f</code>
    on Unixy systems. For bash, this is, e.g., <code>source=file:/$(cygpath -ma sample/b978-3-646-92351-3.xhtml)</code> </p>
  </p:documentation>

  <p:serialization port="result" method="xml" encoding="UTF-8" indent="true" omit-xml-declaration="false"/>
  <p:serialization port="chunks" method="xml" encoding="UTF-8" indent="true" omit-xml-declaration="false"/>
  <p:serialization port="opf" method="xml" encoding="UTF-8" indent="true" omit-xml-declaration="false"/>
  <p:serialization port="files" method="xml" encoding="UTF-8" indent="true" omit-xml-declaration="false"/>

  <p:input port="source" primary="true">
    <p:documentation>An XHTML file (Version number irrelevant; will be output as 1.1), either loaded from a physical location on
      disk or, alternatively, with its base URI set in an /*/@xml:base attribute. It is important that the source document have
      a base URI because the locations of all referenced files (CSS, images) will be determined relative to this base
      URI.</p:documentation>
  </p:input>
  <p:input port="conf" primary="false" sequence="true">
    <p:documentation>/hierarchy, config file for HTML splitter (see sample/hierarchy.xml).
      May be included in meta port doc as /epub-config/hierarchy so
      you don’t have to submit an extra document to this port</p:documentation>
    <p:empty/>
  </p:input>
  <p:input port="meta" primary="false">
    <p:documentation>/epub-config – an EPUB file’s metadata and other configuration settings (see sample/epub-config.xml for an example).
    Please note that the name “meta” is misleading since the file contains more than just metadata.</p:documentation>
  </p:input>
  <p:input port="schematron">
    <p:document href="../schematron/epub.sch.xml"/>
    <p:documentation>You can disable checks by supplying empty Schematron patterns with the same IDs on the custom-schematron 
      port.</p:documentation>
  </p:input>
  <p:input port="attach-cover-xsl">
    <p:document href="../modules/create-ops/xsl/attach-cover.xsl"/>
    <p:documentation>specific stylesheet for attaching cover</p:documentation>
  </p:input>
  <p:input port="custom-schematron" sequence="true">
    <p:empty/>
    <p:documentation>Additional Schematron checks. See debug/epubtools/input-for-schematron.xml for an example of 
      the input format (after running this once with debug=yes). The Schematron files should have a /*/@tr:rule-family
    attribute that identifies the schema’s rule set for the purpose of report generation.</p:documentation>
  </p:input>
  <p:input port="cover-svg">
    <p:documentation>svg template for dynamic cover creation</p:documentation>
    <p:empty/>
  </p:input>
  <p:input port="create-svg-cover-xsl" primary="false">
    <p:documentation>stylesheet for dynamic cover creation</p:documentation>
    <p:empty/>
  </p:input>
  
  <p:output port="result" primary="true">
    <p:pipe port="result" step="output-file-name"/>
  </p:output>
  <p:output port="chunks" primary="false">
    <p:pipe port="result" step="create-ops"/>
  </p:output>
  <p:output port="opf" primary="false">
    <p:pipe port="result" step="create-opf"/>
  </p:output>
  <p:output port="files" primary="false">
    <p:pipe port="files" step="zip-package"/>
  </p:output>
  <p:output port="report" primary="false" sequence="true">
    <p:pipe port="report" step="create-ops"/>
    <p:pipe port="report" step="schematrons"/>
  </p:output>
  <p:output port="html">
    <p:pipe port="html" step="create-ops"/>
  </p:output>
  <p:output port="baseuri" primary="false">
    <p:pipe port="result" step="base-uri"/>
  </p:output>
  <p:output port="input-for-schematron" primary="false">
    <p:pipe port="result" step="wrap-for-schematron"/>
  </p:output>

  <p:option name="target" select="''" cx:type="xs:string"/>
  <!-- EPUB2 | EPUB3 | KF8 // DEFAULT: EPUB2 -->
  <p:option name="terminate-on-error" select="'yes'" cx:type="xs:string"/>
  <p:option name="clean-target-dir" select="'no'" cx:type="xs:string">
    <p:documentation>Whether to erase the target directory prior to splitting etc. Otherwise,
    files from previous conversions might be included in the resulting zip file.</p:documentation>
  </p:option>
  <p:option name="debug" select="'no'" cx:type="xs:string"/>
  <p:option name="use-svg" select="''" cx:type="xs:string" required="false"/>
  <p:option name="debug-dir-uri" select="'debug'" cx:type="xs:string"/>
  <p:option name="status-dir-uri" select="'status'" cx:type="xs:string"/>
  <p:option name="id-in-report-heading" select="'false'">
    <p:documentation>Whether to adorn the reports’ tr:rule-family with the first dc:identifier found in the OPF.</p:documentation>
  </p:option>
  <p:option name="create-font-subset" cx:type="xs:string" required="false" select="'false'">
    <p:documentation>Whether to create a subset of used fonts. If the attribute @font-subset
    exists in the epub-config (see sample/epub-config.xml), it will generally override this option.</p:documentation>
  </p:option>
  <p:option name="create-svg-cover" select="'false'"  cx:type="xs:string" required="false"/>
  <p:option name="convert-svg-cover" select="'false'"  cx:type="xs:string" required="false"/>
  
  <!-- URIs are resolved by XML catalogs, which are located as default in xmlcatalog/catalog.xml -->
  
  <p:import href="../modules/create-ocf/xpl/create-ocf.xpl"/>
  <p:import href="../modules/create-ops/xpl/create-ops.xpl"/>
  <p:import href="../modules/create-opf/xpl/create-opf.xpl"/>
  <p:import href="../modules/zip-package/xpl/zip-package.xpl"/>
  <p:import href="../modules/fontsubsetter/xpl/fontsubsetter.xpl"/>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.io/schematron/xpl/oxy-schematron.xpl"/>
  <p:import href="http://transpect.io/xproc-util/simple-progress-msg/xpl/simple-progress-msg.xpl"/>
  <p:import href="http://transpect.io/xproc-util/file-uri/xpl/file-uri.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  
  
  <p:variable name="wrap-cover-in-svg" select="($use-svg[not(. = '')], /epub-config/cover/@svg, 'true')[1]">
    <p:pipe port="meta" step="epub-convert"/>
  </p:variable>
  <p:variable name="target-format" select="($target[not(. = '')], /epub-config/@format, 'EPUB3')[1]">
    <p:pipe port="meta" step="epub-convert"/>
  </p:variable>
  
  <tr:simple-progress-msg name="start-msg" file="epub-convert-start.txt">
    <p:input port="msgs">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">Starting EPUB generation</c:message>
          <c:message xml:lang="de">Beginne EPUB-Erzeugung</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>
	
  <tr:file-uri name="base-uri">
    <p:documentation>
      The output files are stored relative to the base-uri of the document on the primary input port.
    </p:documentation>
    <p:with-option name="filename" select="(base-uri(/*), static-base-uri())[1]"/>
  </tr:file-uri>	

  <epub:create-ocf name="create-ocf">
    <p:with-option name="base-uri" select="/c:result/@local-href">
      <p:pipe port="result" step="base-uri"/>
    </p:with-option>
    <p:with-option name="debug" select="$debug"><p:empty/></p:with-option>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"><p:empty/></p:with-option>
    <p:input port="meta">
      <p:pipe port="meta" step="epub-convert"/>
    </p:input>
  </epub:create-ocf>

  <p:sink/>
  
  <!--<p:label-elements attribute="xml:base" match="/html:html" replace="false" label="base-uri(/*)">
    <p:documentation>Make base uri explicit if it isn’t already.</p:documentation>
  </p:label-elements>-->
  
  <p:label-elements attribute="srcpath" replace="false" name="srcpaths"
    match="*[local-name() = ( 'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
                              'div', 'nav', 'section', 'main',
                              'ol', 'ul', 'li', 'dd', 'dt', 
                              'td', 'th', 
                              'em', 'span', 'b', 'i', 'strong', 
                              'code', 'pre',
                              'a', 'img')]">
    <p:documentation>For the epubtools Schematron checks, we need to add srcpaths on elements that don’t have them yet.</p:documentation>
    <p:input port="source">
      <p:pipe port="source" step="epub-convert"/>
    </p:input>
  </p:label-elements>
  
  <tr:store-debug pipeline-step="epubtools/add-srcpaths-to-input" extension="xhtml">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>  
  
  <epub:create-ops name="create-ops">
    <p:input port="conf">
      <p:pipe port="conf" step="epub-convert"/>
    </p:input>
    <p:input port="meta">
      <p:pipe port="meta" step="epub-convert"/>
    </p:input>
   <p:input port="attach-cover-xsl">
      <p:pipe port="attach-cover-xsl" step="epub-convert"/>
    </p:input>
    <p:input port="create-svg-cover-xsl">
      <p:pipe port="create-svg-cover-xsl" step="epub-convert"/>
    </p:input>
   <p:input port="cover-svg">
      <p:pipe port="cover-svg" step="epub-convert"/>
    </p:input>
    <p:with-option name="base-uri" select="/c:result/@local-href">
      <p:pipe port="result" step="base-uri"/>
    </p:with-option>
    <p:with-option name="target" select="$target-format"/>
    <p:with-option name="use-svg" select="$wrap-cover-in-svg"/>
    <p:with-option name="terminate-on-error" select="$terminate-on-error"/>
    <p:with-option name="debug" select="$debug"><p:empty/></p:with-option>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"><p:empty/></p:with-option>
    <p:with-option name="create-font-subset" select="(/epub-config/@font-subset, 'false')[1]">
      <p:pipe port="meta" step="epub-convert"/>
    </p:with-option>
    <p:with-option name="create-svg-cover" select="$create-svg-cover"/>
    <p:with-option name="convert-svg-cover" select="$convert-svg-cover"/>
  </epub:create-ops>

  <epub:create-opf name="create-opf">
    <p:input port="source">
      <p:pipe port="files" step="create-ops"/>
      <p:pipe port="result" step="create-ops"/>
    </p:input>
    <p:input port="meta">
      <p:pipe port="meta" step="epub-convert"/>
    </p:input>
    <p:with-option name="base-uri" select="/c:result/@local-href">
      <p:pipe port="result" step="base-uri"/>
    </p:with-option>
    <p:with-option name="target" select="$target-format"/>
    <p:with-option name="terminate-on-error" select="$terminate-on-error"/>
    <p:with-option name="use-svg" select="$wrap-cover-in-svg"/>
    <p:with-option name="debug" select="$debug"><p:empty/></p:with-option>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"><p:empty/></p:with-option>
  </epub:create-opf>

  <p:sink/>
  
  <p:choose name="conditionally-remove-nav-from-filelist-if-epub2">
    <p:when test="$target-format = ('EPUB2', 'KF8')">
      <p:output port="result" primary="true"/>
      <p:delete name="discard-epub2-nav-html" match="/*/c:file[matches(@name, 'nav\.xhtml$')]">
        <p:documentation>nav.xhtml is only carried along for creating the guide element in EPUB2</p:documentation>
        <p:input port="source">
          <p:pipe port="files" step="create-ops"/>
        </p:input>
      </p:delete>
    </p:when>
    <p:otherwise>
      <p:output port="result" primary="true"/>
      <p:identity>
        <p:input port="source">
          <p:pipe port="files" step="create-ops"/>
        </p:input>
      </p:identity>
    </p:otherwise>
  </p:choose>

  <p:sink/>
  
  <p:choose name="conditionally-remove-nav-from-chunks-if-epub2">
    <p:when test="$target-format = 'EPUB2'">
      <p:output port="result" primary="true"/>
      <p:delete name="discard-epub2-nav" match="/*/html:html[matches(@xml:base, 'nav\.xhtml$')]">
        <p:documentation>nav.xhtml is only carried along for creating the guide element in EPUB2</p:documentation>
        <p:input port="source">
          <p:pipe port="result" step="create-ops"/>
        </p:input>
      </p:delete>
    </p:when>
    <p:otherwise>
      <p:output port="result" primary="true"/>
      <p:identity>
        <p:input port="source">
          <p:pipe port="result" step="create-ops"/>
        </p:input>
      </p:identity>
    </p:otherwise>
  </p:choose>
  
  <p:sink/>
  
  <epub:zip-package name="zip-package">
    <p:input port="ocf-filerefs">
      <p:pipe port="files" step="create-ocf"/>
    </p:input>
    <p:input port="ops-filerefs">
      <p:pipe port="result" step="conditionally-remove-nav-from-filelist-if-epub2"/>
    </p:input>
    <p:input port="opf-fileref">
      <p:pipe port="files" step="create-opf"/>
    </p:input>
    <p:input port="meta">
      <p:pipe port="meta" step="epub-convert"/>
    </p:input>
    <p:with-option name="base-uri" select="/c:result/@local-href">
      <p:pipe port="result" step="base-uri"/>
    </p:with-option>
    <p:with-option name="debug" select="$debug"><p:empty/></p:with-option>
    <p:with-option name="debug-dir-uri" select="replace($debug-dir-uri, '^(.+)\?.*$', '$1')"><p:empty/></p:with-option>
  </epub:zip-package>
  
  <cxf:info name="zip-info">
    <p:with-option name="href" select="/c:zipfile/@href"/>
  </cxf:info>

  <p:set-attributes match="/*" name="insert-zip-info">
    <p:input port="source">
      <p:pipe port="result" step="zip-package"/>
    </p:input>
    <p:input port="attributes">
      <p:pipe port="result" step="zip-info"/>
    </p:input>
  </p:set-attributes>

  <tr:file-uri name="output-file-name">
    <p:with-option name="filename" select="/c:zipfile/@href">
      <p:pipe port="result" step="zip-package"/>
    </p:with-option>
  </tr:file-uri>

  <p:sink/>

  <p:wrap-sequence name="wrap-for-schematron" wrapper="c:wrap">
    <p:input port="source">
      <p:pipe port="meta" step="epub-convert">
        <p:documentation>conf file (epub-config)</p:documentation>
      </p:pipe>
      <p:pipe port="result" step="create-opf"/>
      <!--<p:pipe port="result" step="image-infos">
        <p:documentation>opf enhanced with image analysis (opf:package)</p:documentation>
      </p:pipe>-->
      <p:pipe port="result" step="conditionally-remove-nav-from-filelist-if-epub2">
        <p:documentation>ops file list (cx:document)</p:documentation>
      </p:pipe>
      <p:pipe port="html" step="create-ops">
        <p:documentation>HTML input (html:html)</p:documentation>
      </p:pipe>
      <p:pipe port="splitting-report" step="create-ops">
        <p:documentation>Custom HTML markup indicating the unconditional and conditional splitting points (html:body)</p:documentation>
      </p:pipe>
      <p:pipe port="result" step="conditionally-remove-nav-from-chunks-if-epub2">
        <p:documentation>HTML input (cx:document[@name = 'wrap-chunks'], with html:html chunks, c:data for css, ncx:ncx)</p:documentation>
      </p:pipe>
      <p:pipe port="result" step="insert-zip-info">
        <p:documentation>c:zipfile</p:documentation>
      </p:pipe>
    </p:input>
  </p:wrap-sequence>
  
  <tr:store-debug pipeline-step="epubtools/input-for-schematron">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <p:sink/>
  
  <p:xslt name="filter-default-schematron">
    <p:documentation>Remove pattern with IDs that match pattern IDs in the custom-schematron documents.
    The purpose is to be able to disable default checks.
    The most specific patterns will win. Input custom schematron in ascending specificity.</p:documentation>
    <p:input port="source">
      <p:pipe port="schematron" step="epub-convert"/>
      <p:pipe port="custom-schematron" step="epub-convert"/>
    </p:input>
    <p:input port="parameters">
      <p:empty/>
    </p:input>
    <p:input port="stylesheet">
      <p:inline>
        <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
          <xsl:template match="* | @*">
            <xsl:copy>
              <xsl:apply-templates select="@*, node()"/>
            </xsl:copy>
          </xsl:template>

          <xsl:template match="/">
            <xsl:for-each select="collection()">
              <xsl:variable name="pos" select="position()" as="xs:integer"/>
              <xsl:result-document href="{base-uri()}.new">
                <xsl:apply-templates>
                  <xsl:with-param name="more-specific-patterns" as="xs:string*" tunnel="yes"
                    select="collection()[position() gt $pos]//*:pattern/@id"/>
                </xsl:apply-templates>
              </xsl:result-document>
            </xsl:for-each>
            <noout/>
          </xsl:template>

          <xsl:template match="*:pattern">
            <xsl:param name="more-specific-patterns" as="xs:string*" tunnel="yes"/>
            <xsl:choose>
              <xsl:when test="$more-specific-patterns = (@id, @is-a)"/>
              <xsl:otherwise>
                <xsl:next-match/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:template>
        </xsl:stylesheet>
      </p:inline>
    </p:input>
  </p:xslt>
  
  <p:sink/>

  <p:for-each name="schematrons">
    <p:iteration-source>
      <p:pipe port="secondary" step="filter-default-schematron"/>
    </p:iteration-source>
    <p:output port="report" primary="true"/>
    <p:variable name="identifier" select="/opf:package/opf:metadata/dc:identifier[1]">
      <p:pipe port="result" step="create-opf"/>
    </p:variable>
    
    <tr:oxy-validate-with-schematron name="sch0">
      <p:input port="source">
        <p:pipe port="result" step="wrap-for-schematron"/>
      </p:input>
      <p:input port="schema">
        <p:pipe port="current" step="schematrons"/>
      </p:input>
      <p:with-param name="allow-foreign" select="'true'"/>
      <p:input port="parameters">
        <p:empty/>
      </p:input>
    </tr:oxy-validate-with-schematron>

    <p:sink/>

    <p:add-attribute match="/*" attribute-name="tr:rule-family">
      <p:with-option name="attribute-value" select="(/*/@tr:rule-family, 'epubtools-custom')[1]">
        <p:pipe port="current" step="schematrons"/>
      </p:with-option>
      <p:input port="source">
        <p:pipe port="report" step="sch0"/>
      </p:input>
    </p:add-attribute>
    <p:add-attribute name="sch1" match="/*" attribute-name="tr:step-name">
      <p:with-option name="attribute-value" 
        select="string-join(
                  (
                    'epubtools',
                    (
                      /opf:package/opf:metadata/dc:identifier[@id = ../@unique-identifier],
                      /opf:package/opf:metadata/dc:identifier,
                      /opf:package/opf:metadata/dc:title
                    )[1]
                  ),
                  ' '
                )">
        <p:pipe port="result" step="create-opf"/>
      </p:with-option>
    </p:add-attribute>
    <p:choose>
      <p:when test="$id-in-report-heading = 'true'">
        <p:add-attribute name="sch" match="/*" attribute-name="tr:rule-family">
          <p:with-option name="attribute-value" 
            select="string-join(
                      (
                        /*/@tr:rule-family,
                        $identifier
                      ),
                      '-'
                    )"/>
        </p:add-attribute>    
      </p:when>
      <p:otherwise>
        <p:identity/>
      </p:otherwise>
    </p:choose>
  </p:for-each>

  <p:sink/>

  <tr:simple-progress-msg name="success-msg" file="epub-convert-success.txt" cx:depends-on="schematrons">
    <p:input port="msgs">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">EPUB generation finished (see the HTML report though – errors will be reported there)</c:message>
          <c:message xml:lang="de">EPUB-Erzeugung abgeschlossen (bitte im HTML-Report nachsehen, ob fehlerfrei)</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>
  
  <p:sink/>
  
</p:declare-step>
