<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:css="http://www.w3.org/1996/css" 
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:epub="http://www.idpf.org/2007/ops"
  xmlns:svg="http://www.w3.org/2000/svg"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="#all"
  version="2.0">

  <xsl:param name="restore-original-css-filenames" select="'true'"/>
  <xsl:param name="common-source-dir-elimination-regex" as="xs:string?"/>
  <xsl:param name="html-subdir-name" as="xs:string"/>
  <xsl:variable name="html-prefix" select="if (normalize-space($html-subdir-name)) then concat($html-subdir-name, '/') else ''"/>
  <xsl:variable name="relative-prefix" as="xs:string" select="if (normalize-space($html-prefix)) then '../' else ''"/>
  <xsl:param name="debug" select="'no'"/>
  <xsl:param name="final-pub-type" select="'EPUB3'"/>

  <xsl:key name="ruleset-by-id" match="css:ruleset[some $rs in css:selector/@raw-selector satisfies (matches($rs, '^(\i[-a-z\d]*)?#\i\c*'))]"
    use="for $rs in css:selector/@raw-selector[matches(., '^(\i[-a-z\d]*)?#\i\c*')] return replace($rs, '^(\i[-a-z\d]*)?#(\i\c*).*$', '$2')"/>

  <xsl:variable name="css:first-class-selector-regex" as="xs:string" select="'^(\i[-a-z\d]*)?\.(\i[-_a-zA-Z0-9]*).*$'"></xsl:variable>
  <xsl:variable name="css:first-element-selector-regex" as="xs:string" select="'^(\i[-a-z\d]*).*$'"></xsl:variable>

  <xsl:variable name="new-base-uri" as="xs:string"
    select="replace(base-uri(collection()[matches(base-uri(/*), '/chunks/')][1]), '^(.+/).+$', '$1')"/>

  <xsl:template match="/"><!-- /css:css containing css:ruleset elements -->
    <xsl:variable name="all-css" as="document-node(element(css:css))" select="."/>
    <xsl:variable name="per-split-rulesets" as="element(*)*">
      <xsl:for-each select="collection()[matches(base-uri(/*), '/chunks/')] except collection()[1]">
        <xsl:variable name="ids" as="xs:string*" select=".//@id"/>
        <xsl:if test="exists($ids) and (matches(base-uri(/*), '^file:/'))">
          <xsl:variable name="rulesets" as="element(css:ruleset)*" select="key('ruleset-by-id', $ids, $all-css)"/>
          <xsl:if test="count($rulesets) gt 0
                        or
                        (.//@epub:type[not(ancestor::html:nav)] = 'cover' and contains($final-pub-type, 'EPUB3') and exists(.//svg:svg))">
            <css:css id-based-rules="true">
              <xsl:attribute name="xml:base" select="replace(base-uri(/*), concat('^(.+/)', $html-prefix, '(.+)\.xhtml$'), '$1styles/$2.css')"/>
              <xsl:attribute name="relative-name" select="replace(base-uri(/*), '^(.+/)(.+)\.xhtml$', concat($relative-prefix, 'styles/$2.css'))"/>
              <xsl:if test="$debug = 'yes'">
                <comment xmlns="http://www.w3.org/1996/css">
                  <xsl:text>/* Original location: diverse (specifically extracted for </xsl:text>
                  <xsl:value-of select="base-uri(/*)"/>
                  <xsl:text>) */</xsl:text>
                </comment>
              </xsl:if>
              <xsl:if test=".//@epub:type[not(ancestor::html:nav)] = 'cover' and contains($final-pub-type, 'EPUB3') and exists(.//svg:svg)">
                <comment xmlns="http://www.w3.org/1996/css">
                  <xsl:text>/* Original location: diverse (specifically extracted for </xsl:text>
                  <xsl:value-of select="base-uri(/*)"/>
                  <xsl:text>) */</xsl:text>
                </comment>
              </xsl:if>
              <xsl:sequence select="$rulesets"/>
            </css:css>
          </xsl:if>
          <!-- this is just for recording the rulesets that are actually used: -->
          <xsl:sequence select="$rulesets"/>
        </xsl:if>
        <classes>
          <xsl:sequence select="string-join(distinct-values(for $class in .//@class return tokenize($class, '\s+')), ' ')"/>
        </classes>
        <elements>
          <xsl:sequence select="string-join(distinct-values(descendant-or-self::*/name()), ' ')"/>
        </elements>
      </xsl:for-each>
    </xsl:variable>
    <xsl:for-each select="$per-split-rulesets/self::css:css">
      <xsl:result-document href="{@xml:base}">
        <xsl:copy-of select="."/>
      </xsl:result-document>
    </xsl:for-each>
    <xsl:for-each select="css:css">
      <xsl:variable name="classes" as="xs:string*" select="distinct-values(for $local-classes in $per-split-rulesets/self::classes return tokenize($local-classes, ' '))"/>
      <xsl:variable name="class-selectors" as="element(css:selector)*"
        select="css:ruleset/css:selector[@raw-selector][matches((@raw-selector, '')[1], $css:first-class-selector-regex)]"/>
      <xsl:variable name="elements" as="xs:string*" select="distinct-values(for $local-elements in $per-split-rulesets/self::elements return tokenize($local-elements, ' '))"/>
      <xsl:variable name="element-selectors" as="element(css:selector)*"
        select="css:ruleset/css:selector[@raw-selector][matches((@raw-selector, '')[1], $css:first-element-selector-regex)]"/>
      <!-- unused selectors: we analyze only the first class that appears in a selector. p.foo.bar → foo, .foo p.bar → foo.
        Only this first class will be compared to the (whitespace-tokenized) class attributes in the HTML documents -->
      <xsl:variable name="unused-selectors" as="element(css:selector)*"
        select="$class-selectors 
                           [not(
                              replace(
                                (@raw-selector, '')[1], 
                                $css:first-class-selector-regex, 
                                '$2'
                              ) 
                              = $classes
                           )]
                union
                $element-selectors 
                           [not(
                              replace(
                                (@raw-selector, '')[1], 
                                $css:first-element-selector-regex, 
                                '$1'
                              ) 
                              = $elements
                           )]
                           "/>
      <xsl:variable name="rulesets-with-unused-stuff-removed" as="element(css:ruleset)*"
        select="css:ruleset[some $s in css:selector satisfies empty($s intersect $unused-selectors)]"/>
      <xsl:variable name="remaining-font-families" as="xs:string*" 
        select="for $val in $rulesets-with-unused-stuff-removed/css:declaration[@property = 'font-family']/@value return tokenize($val, '\s*,\s*')"/>
      <xsl:variable name="unused-font-atrules" as="element(css:atrule)*" 
        select="css:atrule[@type = 'font-face']
                          [not(css:declaration[@property = 'font-family']/@value = $remaining-font-families)]"/>
      <!-- The predicate will filter away all ID selectors that could not be found in any one of the split files. -->
      <xsl:variable name="remaining-rules" as="element(*)*"
        select="(
                 ( 
                   $rulesets-with-unused-stuff-removed 
                   union 
                   (css:atrule except $unused-font-atrules) 
                   union 
                   css:comment
                 )
                 except 
                 $per-split-rulesets/self::css:ruleset
                )[not(matches((css:selector/@raw-selector, '')[1], '^([a-z]+)?#\i\c*'))]"/>
      <xsl:for-each-group select="$remaining-rules union css:comment" group-by="css:relative-result-filename(@origin, $common-source-dir-elimination-regex)">
        <xsl:result-document href="{$new-base-uri}{current-grouping-key()}">
          <css xmlns="http://www.w3.org/1996/css" relative-name="{current-grouping-key()}" common="true">
            <!--<xsl:apply-templates select="current-group()/self::css:atrule[@type = 'charset']"/>-->
            <!-- Everything will be serialized as UTF-8 ayway, so no need to retain the initial declaration.
            Neither do we have to declare it explicitly provided the including HTML file is also UTF-8. -->
            <xsl:variable name="css:utf8-charset" as="element(css:atrule)">
              <atrule xmlns="http://www.w3.org/1996/css" type="charset">
                <raw-css>@charset "UTF-8"; </raw-css>
              </atrule>
            </xsl:variable>
            <xsl:variable name="orig-loc-comment" as="element(css:comment)">
              <comment xmlns="http://www.w3.org/1996/css">
                <xsl:text>/* Original location: </xsl:text>
                <xsl:value-of select="@origin"/>
                <xsl:text> */</xsl:text>
              </comment>
            </xsl:variable>
            <xsl:apply-templates select="$css:utf8-charset"/>
            <xsl:if test="$debug = 'yes'">
              <xsl:apply-templates select="$orig-loc-comment"/>
            </xsl:if>
            <xsl:apply-templates select="current-group()[not(self::css:atrule[@type = 'charset'])]">
              <xsl:with-param name="unused-selectors" select="$unused-selectors" tunnel="yes"/>
            </xsl:apply-templates>
          </css>
        </xsl:result-document>
      </xsl:for-each-group>
      <xsl:result-document href="unused-css-resources.xml">
        <css xmlns="http://www.w3.org/1996/css" common="true">
          <xsl:sequence select="$unused-font-atrules"/>
        </css>
      </xsl:result-document>
    </xsl:for-each>
    <nothing/>
  </xsl:template>

  <xsl:function name="css:relative-result-filename" as="xs:string">
    <xsl:param name="origin" as="attribute(origin)"/>
    <xsl:param name="common-path" as="xs:string"/>
    <xsl:variable name="prelim" as="xs:string" 
      select="if (matches($origin, '^(file://)internal$'))
              then concat('styles/internal-', $origin/../css:selector/@position ,'.css')
              else replace($origin, $common-path, '')"/>
    <!-- This is not tested for production where the common path (the epub packing directory)
         is identical with the CSS file location. 
         Previously, the name was generated by sum(string-to-codepoints($origin)), cf svn history. -->
    <xsl:sequence select="if (matches($prelim, '^(file|https?):'))
                          then concat('styles/', replace($prelim, '^.+/', '')) 
                          else $prelim"/>
  </xsl:function>

  <xsl:template match="* | @*">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- CSS files are copied to the same directory, for example 'styles'. 
       In case of css files with relative paths, starting with '../' we 
       strip the full path -->
  
  <xsl:template match="css:atrule[@type eq 'import'][matches(css:raw-css, '@import.+?(\.\./)+.+?\.css')]/css:raw-css/text()">
    <xsl:value-of select="replace(., '(@import\s+url\([''&quot;]?).+/', '$1')"/>
  </xsl:template>
  
  <xsl:template match="css:selector">
    <xsl:param name="unused-selectors" as="element(css:selector)*" tunnel="yes"/>
    <xsl:if test="not(. intersect $unused-selectors)">
      <xsl:next-match/>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
