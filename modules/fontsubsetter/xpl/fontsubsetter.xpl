<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:cxf="http://xmlcalabash.com/ns/extensions/fileutils"
  xmlns:pos="http://exproc.org/proposed/steps/os"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:s="http://purl.oclc.org/dsdl/schematron"
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:dbk="http://docbook.org/ns/docbook"
  xmlns:tr="http://transpect.io"
  version="1.0"
  name="create-font-subset"
  type="tr:create-font-subset">
  
  <p:documentation>This pipeline creates fontsubsets. The characters used 
    in each font will be displayed in a character set. The subset is created 
    using the pyftsubset python script from fonttools https://github.com/fonttools.
  </p:documentation>
  
  <p:option name="script-path" select="'../../../scripts/pyftsubset.sh'"/>
  <p:option name="min-file-size-kb" select="0">
    <p:documentation>If the file size of the font is below this limit, the font is not
      subsetted. This option can prove useful if you just want to subset the usually
      bigger CJK fonts but leave your standard fonts untouched. 
    </p:documentation>
  </p:option>
  <p:option name="debug" required="false" select="'yes'"/>
  <p:option name="debug-dir-uri" select="'debug'"/>
  
  <!--<p:option name="font-name" required="false"/>
  <p:option name="font-style" required="false" select="'normal'"/>
  <p:option name="font-weight" required="false" select="'normal'"/> -->

  <p:input port="source" primary="true">
    <p:documentation>HTML document with linked CSS stylesheet</p:documentation>
  </p:input>
  <p:input port="expand-css" >
    <p:documentation>Already parsed and resolved CSS stylesheet</p:documentation>
  </p:input>
  
  <p:output port="result" primary="true" sequence="true">
    <p:documentation>Output is a character set displaying all characters used inside a font</p:documentation>
    <p:pipe port="result" step="viewport-chars-identity"/>
  </p:output>
  <p:serialization port="result" omit-xml-declaration="false" indent="true"/>
 
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />
  <p:import href="http://transpect.io/css-tools/xpl/css.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  <p:import href="http://transpect.io/xproc-util/file-uri/xpl/file-uri.xpl"/>
  
  <p:sink/>
  
  <pos:info name="os-info"/>
  
  <tr:store-debug pipeline-step="epubtools/fontsubset/00_os-info">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <tr:file-uri name="script-path">
    <p:with-option name="filename" select="resolve-uri($script-path)"/>
  </tr:file-uri>

  <tr:store-debug pipeline-step="epubtools/fontsubset/00_path-info">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <p:sink/>

  <css:expand name="expand">
    <p:input port="source">
      <p:pipe port="source" step="create-font-subset"/>
    </p:input>
    <p:input port="stylesheet">
      <p:document href="http://transpect.io/css-tools/xsl/css-parser.xsl"/>
    </p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </css:expand> 
  
    
   <tr:store-debug name="store2" pipeline-step="epubtools/fontsubset/02_expanded-html" extension="xhtml">
      <p:with-option name="active" select="$debug"/>
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </tr:store-debug>
  
  <p:sink/>
  
  <p:xslt name="font-characters">
    <p:input port="parameters">
      <p:empty/>
    </p:input>
    <p:input port="source">
      <p:pipe port="result" step="expand"/>
      <p:pipe port="expand-css" step="create-font-subset"/>
    </p:input>
    <p:input port="stylesheet">
      <p:inline>
        <xsl:stylesheet version="2.0"  
          xmlns:css="http://www.w3.org/1996/css" 
          xmlns:tr="http://transpect.io"
          xmlns:html="http://www.w3.org/1999/xhtml"
          exclude-result-prefixes="#all">
          
          <xsl:param name="font-family"/>
          <xsl:param name="font-weight"/>
          <xsl:param name="font-style"/>
          <xsl:param name="base-uri" select="base-uri(/*)" as="xs:string" />
          
          <xsl:variable name="css" select="collection()[2]"/>
          <xsl:variable name="fonts" select="$css//*:atrule[@type='font-face']"/>
          
          <xsl:function name="tr:int-to-hex" as="xs:string">
            <xsl:param name="in" as="xs:integer"/>
            <xsl:sequence select="if ($in eq 0)
                                  then '0'
                                  else
                                    concat(if ($in ge 16)
                                            then tr:int-to-hex($in idiv 16)
                                            else '',
                                          substring('0123456789ABCDEF',
                                          ($in mod 16) + 1, 1))"/>
           </xsl:function>
          
          <xsl:template match="/">
            <tr:charset>
            <xsl:variable name="context" select="."/>
              <xsl:for-each select="$fonts">
                <xsl:variable name="font-family" select="replace(current()/*:declaration[@property='font-family']/@value,'(&#34;|'')','')"/>
                <xsl:variable name="font-weight" select="if (current()/*:declaration[@property='font-weight']/@value) 
                                                         then current()/*:declaration[@property='font-weight']/@value
                                                         else 'normal'"/>
                <xsl:variable name="font-style" select="if (current()/*:declaration[@property='font-style']/@value)
                                                        then current()/*:declaration[@property='font-style']/@value
                                                        else 'normal'"/>
                
                
                <xsl:variable name="font-weight-regex" select="if (matches($font-weight,'normal')) then '^$' else $font-weight"/>
                <xsl:variable name="font-style-regex" select="if (matches($font-style,'normal')) then '^$' else $font-style"/>
                
<!--            <xsl:message select="'########4: ', $font-family, ':&#xa;', $font-weight, $font-style"></xsl:message>-->

                <xsl:variable name="elements" select="(collection()[1]//*[@css:font-family[matches(.,$font-family)]])" as="element(*)*"/>
<!--/descendant-or-self::*[matches(@css:font-weight,$font-weight-regex) 
                                                                                        and matches(@css:font-style,$font-style-regex)]-->
              <tr:chars>
<!--               resolve catalog font url-->
                <xsl:attribute name="font-url" select="current()/*:declaration[@property='src']/*:resource[1][not(@format='woff')]/@local-href"/>
                <xsl:attribute name="font-family" select="$font-family"/>
                <xsl:attribute name="font-weight" select="$font-weight"/>
                <xsl:attribute name="font-style" select="$font-style"/>
<!--                <xsl:message select="'~~~~~~5: ', count($elements)(:, current()/*:declaration[@property='src']/*:resource[1][not(@format='woff')]/@local-href:)"/>-->
                <xsl:variable name="chars"  select="distinct-values(string-to-codepoints(string-join($elements/descendant::text(),'')))"/>
                <xsl:for-each select="$chars">
                  <xsl:sequence select="tr:int-to-hex(xs:integer(.))"/><xsl:text>,</xsl:text>
                </xsl:for-each>
              </tr:chars>
              </xsl:for-each>
            </tr:charset>
          </xsl:template>
        
        </xsl:stylesheet>
      </p:inline>
    </p:input>
  </p:xslt>

  <tr:store-debug name="store3" pipeline-step="epubtools/fontsubset/04_charset" extension="xml">
   <p:with-option name="active" select="$debug"/>
   <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>

  <p:viewport match="tr:chars" name="viewport-chars">
    
    <cxf:info name="font-file-info" fail-on-error="false">
      <p:with-option name="href" select="tr:chars/@font-url"/>
    </cxf:info>

    <p:add-attribute match="tr:chars" attribute-name="size-kb">
      <p:input port="source">
        <p:pipe port="current" step="viewport-chars"/>
      </p:input>
      <p:with-option name="attribute-value" select="if (c:file) then c:file/@size idiv 1000 else 0">
        <p:pipe port="result" step="font-file-info"/>
      </p:with-option>
    </p:add-attribute>

    <p:add-attribute match="tr:chars" attribute-name="create-subset">
      <p:with-option name="attribute-value"
		     select="if (xs:integer(tr:chars/@size-kb) gt xs:integer($min-file-size-kb)
                     and
                     tr:chars[normalize-space()]
                    ) 
      			     then 'true' 
      			     else 'false'">
      </p:with-option>
    </p:add-attribute>
    
  </p:viewport>
  
  <p:identity name="viewport-chars-identity"/>
  
  <tr:store-debug name="store4" pipeline-step="epubtools/fontsubset/06_charset-filtered" extension="xml">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <p:for-each name="chars">
    <p:iteration-source select="//tr:chars[xs:integer(@size-kb) gt 0 (:avoid error with non existing fonts:)]"/>
    <p:variable name="script-path" select="/c:result/@os-path">
      <p:pipe port="result" step="script-path"/>
    </p:variable>
    
    <p:choose>
      <p:when test="tr:chars/@create-subset eq 'true'">
        <p:exec name="subset" command="bash" arg-separator=";" result-is-xml="false" errors-is-xml="false" cwd="." >
          <p:with-option name="args" 
                         select="concat($script-path,
                                        ';-g', 
                                        ., 
                                        ';',
                                        replace(tr:chars/@font-url,'file:///?',''))">
          </p:with-option>
        </p:exec>
        <cx:message>
          <p:with-option name="message" select="concat('[fontsubsetter] ', .)">
            <p:pipe port="result" step="subset"/>
          </p:with-option>
        </cx:message>
        
      </p:when>
      <p:otherwise>
        <!-- nonetheless, create copy with .subset suffix since step entitled
             "conditionally-change-font-subset-name" in create-ops.xpl depends 
             that all fonts need to have this suffix -->
        
        <cxf:copy name="copy" fail-on-error="false">
          <p:with-option name="href" select="tr:chars/@font-url"/>
          <p:with-option name="target" select="concat(tr:chars/@font-url, '.subset')"/>
        </cxf:copy>
        
        <p:identity>
          <p:input port="source">
            <p:pipe port="current" step="chars"/>
          </p:input>
        </p:identity>
        
        <cx:message>
          <p:with-option name="message" select="'[fontsubsetter] copy: ', tr:chars/@font-url, ' => ', concat(tr:chars/@font-url, '.subset')"/>
        </cx:message>
        
      </p:otherwise>
    </p:choose>

  </p:for-each>
  
  <p:sink/>

</p:declare-step>
