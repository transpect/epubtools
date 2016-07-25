<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:tr="http://transpect.io"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:svg="http://www.w3.org/2000/svg" 
  xmlns:m="http://www.w3.org/1998/Math/MathML/"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:epub="http://www.idpf.org/2007/ops"
  xmlns="http://www.w3.org/ns/xproc-step"
  exclude-result-prefixes="#all"
  version="2.0">
  
  <xsl:import href="http://transpect.io/xslt-util/mime-type/xsl/mime-type.xsl"/>

  <xsl:param name="stored-file"/>
  <xsl:param name="debug-dir-uri"/>

  <xsl:variable name="html-form-elements" select="('form', 'input', 'button', 'option', 'select', 'textarea')" as="xs:string+"/>

  <xsl:template match="/">
    <xsl:variable name="file-extension" select="replace($stored-file , '.*\.(.*)$', '$1')"/>
    <xsl:variable name="media-type" select="tr:fileext-to-mime-type($file-extension)"/>
    <!-- exclude debug files from html-splitter.xsl which are 
         submitted over the same output port as regular html files -->
    <xsl:if test="not(contains($stored-file, $debug-dir-uri)) or contains($stored-file, 'epub/OEBPS')">
      <xsl:if test="contains($stored-file, $debug-dir-uri) and contains($stored-file, 'epub/OEBPS')">
        <xsl:message select="'[WARNING]: adding the following debug and output file to epub container:', $stored-file"/>
      </xsl:if>
      <c:file target-filename="{$stored-file}"
              oebps-name="{replace($stored-file, '.*epub/(OEBPS/.*)$', '$1')}" 
              name="{replace($stored-file, '.*epub/OEBPS/(.*)$', '$1')}" 
              media-type="{$media-type}">
        <xsl:apply-templates select="*" mode="props"/>
      </c:file>  
    </xsl:if>
  </xsl:template>

  <xsl:template match="*[ancestor::html:iframe]" mode="props" priority="2"/>

  <xsl:template match="*" mode="props">
    <xsl:apply-templates select="*" mode="#current"/>
  </xsl:template>

  <xsl:template match="html:html/html:head/html:meta[@name = ('linear', 'spine', 'sequence')]" mode="props">
    <xsl:attribute name="{@name}" select="@content"/>
  </xsl:template>

  <xsl:template match="html:*[name() = $html-form-elements]" mode="props">
    <xsl:attribute name="form" select="'true'"/>
  </xsl:template>

  <xsl:template match="epub:switch | svg:svg | html:script" mode="props">
    <xsl:attribute name="{local-name()}" select="'true'"/>
  </xsl:template>
  
  <!-- normally we would only accept html:nav[@epub:type = 'toc'], but if the nav property is missing in the OPF,
    ADE 4.5 might get stuck while reading the EPUB -->
  <xsl:template match="*[@epub:type = 'toc']" mode="props">
    <xsl:attribute name="nav" select="'true'"/>
  </xsl:template>

  <xsl:template match="m:math" mode="props">
    <xsl:attribute name="mathml" select="'true'"/>
  </xsl:template>

  <xsl:template match="html:*[(@epub:type, @class) = 'toc']" mode="props" priority="2">
    <!-- for the deprecated guide element -->
    <xsl:attribute name="toc" select="'true'"/>
    <xsl:next-match/>
  </xsl:template>

</xsl:stylesheet>