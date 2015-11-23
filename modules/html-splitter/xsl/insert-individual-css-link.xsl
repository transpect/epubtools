<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:css="http://www.w3.org/1996/css" 
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:tr="http://transpect.io"
  xmlns:ncx="http://www.daisy.org/z3986/2005/ncx/"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:svg="http://www.w3.org/2000/svg"
  xmlns:xlink="http://www.w3.org/1999/xlink" 
  xmlns="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="#all"
  version="2.0">

  <xsl:param name="target" as="xs:string"/>
  <xsl:param name="html-subdir-name" select="''" as="xs:string"/>
  <xsl:variable name="html-prefix" select="if (normalize-space($html-subdir-name)) then concat($html-subdir-name, '/') else ''"/>
  <!-- hack; need to generalize for arbitrary paths: -->
  <xsl:variable name="relative-prefix" as="xs:string" select="if (normalize-space($html-prefix)) then '../' else ''"/>

  <xsl:template match="* | @*">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- This is a side effect for making sure that xmlns:xlink is on svg:svg and not
    on svg:image, since iBooks chokes on the latter -->
  <xsl:template match="svg:svg">
    <xsl:copy>
      <xsl:namespace name="xlink">http://www.w3.org/1999/xlink</xsl:namespace>
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:variable name="affected-files" select="for $u in collection()/base-uri()[ends-with(., 'css')]
                                              return replace($u, '/styles/(.+)\.css$', concat('/', $html-prefix, '$1.xhtml'))" as="xs:string*"/>
  
  <xsl:template name="main">
    <xsl:apply-templates select="collection()/(html:html[matches(base-uri(), '/(debug|chunks)/')] | ncx:ncx)"/>
  </xsl:template>
  
  <xsl:template match="html:html | ncx:ncx" priority="2">
    <!-- gotta alter the output uri in a non-problematic way because it must be different -->
    <xsl:result-document href="{replace(base-uri(), '/(debug|chunks)/', '//$1/')}">
      <xsl:next-match/>
    </xsl:result-document>
  </xsl:template>

  <xsl:template match="ncx:ncx">
    <xsl:sequence select="."/>
  </xsl:template>
    
  <xsl:template match="html:head[base-uri() = $affected-files]">
    <xsl:copy>
      <xsl:call-template name="common-stylesheet-links"/>
      <link href="{replace(base-uri(), '^(.+/)(.+)\.xhtml$', concat($relative-prefix, 'styles/$2.css'))}" type="text/css" rel="stylesheet"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="html:head[not(base-uri() = $affected-files)]">
    <xsl:copy>
      <xsl:call-template name="common-stylesheet-links"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:function name="tr:contains-token" as="xs:boolean">
    <xsl:param name="string" as="xs:string?"/>
    <xsl:param name="tokens" as="xs:string*"/>
    <xsl:sequence select="if ($string) then tokenize($string, '\s+') = $tokens else false()"/>
  </xsl:function>
  
  <!-- This is to circumvent a kindlegen bug. 
    Scenario: #mydiv h1 { display: none; }
    Kindlegen will regard the complete #mydiv as display:none. Any link into #mydiv
    will be regarded as an E24010, making the whole conversion fail. -->
  <xsl:template match="html:*[tr:contains-token(@class, '_hidden')][@id]">
    <a id="{@id}"></a>
    <xsl:apply-templates select="." mode="rm-id"/>
  </xsl:template>
  
  <xsl:template match="* | @*" mode="rm-id">
    <xsl:copy>
      <xsl:apply-templates select="@* except @id, node()" mode="#default"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template name="common-stylesheet-links">
    <xsl:copy-of select="@*, node() except (html:link union html:style)"/>
    <xsl:variable name="html-base-uri" select="string(base-uri())" as="xs:string"/>
    <xsl:for-each select="collection()[ends-with(base-uri(), 'css')]/css:css[@common = 'true']/@relative-name">
      <xsl:text>&#xa;    </xsl:text>
      <xsl:choose>
        <xsl:when test="ends-with($html-base-uri, '/chunks/nav.xhtml')">
          <link href="{replace(., '^../', '')}" type="text/css" rel="stylesheet"/>
        </xsl:when>
        <xsl:when test="normalize-space($html-prefix)">
          <link href="{concat($relative-prefix, .)}" type="text/css" rel="stylesheet"/>
        </xsl:when>
        <xsl:otherwise>
          <link href="{.}" type="text/css" rel="stylesheet"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>
  
</xsl:stylesheet>